

////////////////////////////////////////////////////////////////////////////////
// COMMON USE PROCEDURES

// Procedure CallExceptionIfNoAdminPrivileges calls exception,
// if does not have administration rights.
//
Procedure CallExceptionIfNoAdminPrivileges()

	RunningProcedureHandleScheduledJobs = CommonSettingsStorage.Load("RunningProcedureHandleScheduledJobs");
	If TypeOf(RunningProcedureHandleScheduledJobs) <> Type("Boolean") Then
		RunningProcedureHandleScheduledJobs = False;
	EndIf;
	
	If NOT RunningProcedureHandleScheduledJobs And
	     NOT AccessRight("Administration", Metadata) Then
		
		Raise(NStr("en = 'User does not have administrative rights!'"));
	EndIf;
	
EndProcedure // CallExceptionIfNoAdminPrivileges()

// Procedure AddUsernamesToValueList adds
// user names to the List, as they are specified in designer.
//
// Parameters:
//  List       - ValueList - usually ChoiceList of InputField.
//
Procedure AddUsernamesToValueList(List) Export
	
	CallExceptionIfNoAdminPrivileges();
	
	// Fill the list of infobase users for choice
	UsersArray = InfobaseUsers.GetUsers();
	For each User In UsersArray Do
		List.Add(User.Name);
	EndDo;

EndProcedure // AddUsernamesToValueList()

// Function CurrentSessionHandlesTasks determines, that current session handles jobs,
// if this is wrong and it's specified to make current session handle jobs, then the attempt
// to assign current session to handle the jobs is performed.
//
// Parameters:
//  TasksAreProcessingOK - Boolean - True, if there are no problems in jobs processing.
//  SetCurrentSessionAsScheduledJobsRunSession - Boolean - True, if it's required to make
//               current session, processing jobs, if attempt to make ot handling jobs failed,
//               then function will return False.
//  ErrorDescription 	 - String - If NOT TasksAreProcessingOK, then problem description:
//               either processing is not starting for a long time, or is running too long.
//
// Value returned:
//  Boolean.
//
Function CurrentSessionHandlesTasks(TasksAreProcessingOK = Undefined,
                                        Val SetCurrentSessionAsScheduledJobsRunSession = False,
                                        ErrorDescription = "") Export
	
	If NOT CommonUse.FileInformationBase() Then
		TasksAreProcessingOK = True;
		ErrorDescription = NStr("en = 'The tasks are being processed at the server!'");
		Return False;
	EndIf;
	
	SetPrivilegedMode(True);
	
	BeginTransaction();
	Try
		State 	 					= GetScheduledJobsProcessingStatus(True);
		Sessions 					= GetInfobaseSessions();
		SessionRunningTasksFound 	= False;
		CurrentSessionHandlesTasks  = False;
		TasksAreProcessingOK  		= True;
		
		// Find jobs handling session, assigned in constant ScheduledJobsProcessingStatus,
		// among the active sessions, and the current session (current session start may be needed
		// for Structure initialization).
		For each SessionNumber In Sessions Do
			If SessionNumber.SessionNumber = InfobaseSessionNumber() Then
				CurrentSession = SessionNumber;
			EndIf;
			If SessionNumber.SessionNumber 	= State.SessionNumber
			   And SessionNumber.SessionStarted 	= State.SessionStarted Then
			   	SessionFound 				= SessionNumber;
				SessionRunningTasksFound 	= True;
				CurrentSessionHandlesTasks  = (SessionNumber.SessionNumber = InfobaseSessionNumber());
			EndIf;
		EndDo;
		If NOT SessionRunningTasksFound And SetCurrentSessionAsScheduledJobsRunSession Then
			CurrentTimeMoment                           = CurrentDate();
			State.SessionNumber                         = CurrentSession.SessionNumber;
			State.SessionStarted                        = CurrentSession.SessionStarted;
			State.ComputerName                          = ComputerName();
			State.ApplicationName                       = CurrentSession.ApplicationName;
			State.UserName                      		= UserName();
			State.IDNextTasks        					= Undefined;
			State.NextTaskProcessingBegin      			= CurrentTimeMoment;
			State.OneMoreTaskProcessingEnding   		= CurrentTimeMoment;
			RefreshScheduledJobsProcessingStatus(State);
			SessionRunningTasksFound 					= True;
			CurrentSessionHandlesTasks  				= True;
			CommitTransaction();
		Else
			RollbackTransaction();
		EndIf;
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	If NOT SessionRunningTasksFound Then
		ErrorDescription = NStr("en = 'No session processing scheduled jobs!'");
		TasksAreProcessingOK = False;
	ElsIf State.Settings.ScheduledJobsProcessingLock Then
		ErrorDescription = NStr("en = 'Completion of the scheduled jobs has been locked!'");
		TasksAreProcessingOK = False;
	ElsIf NOT ValueIsFilled(State.OneMoreTaskProcessingEnding) Then
		// If after the end of the next job more than 1 hour has passed, then this is a start delay.
		If CurrentDate() - 360 > State.OneMoreTaskProcessingEnding Then
			ErrorDescription = StringFunctionsClientServer.SubstitureParametersInString(
					NStr("en = 'Scheduled job processing run delayed more than 1 hour!
                          |Error checking and session restart might be required.
                          |Run is expected at the computer: %1,
                          |At the application: %2,
                          |By user name: %3,
                          |At session No: %4.'"),
					String(State.ComputerName),
					String(State.ApplicationName),
					String(State.UserName),
					String(State.SessionNumber) );
			TasksAreProcessingOK = False;
		EndIf;
	
	Else
		// If processing is running more than 1 hour, then it working too long.
		If CurrentDate() - 360 > State.NextTaskProcessingBegin Then
			ErrorDescription = StringFunctionsClientServer.SubstitureParametersInString(
					NStr("en = 'Scheduled job processing run delayed more than 1 hour!
                          |Error checking and session restart might be required.
                          |Run is expected at the computer : %1,
                          |at the application: %2,
                          |by user name: %3,
                          |at session No: %4.'"),
					String(State.ComputerName),
					String(State.ApplicationName),
					String(State.UserName),
					String(State.SessionNumber));
			TasksAreProcessingOK = False;
		EndIf;
	EndIf;
	Return CurrentSessionHandlesTasks;
	
EndFunction // CurrentSessionHandlesTasks()

// Function ParentSessionSetAndCompleted checks,
// that session that opened this additional session
// for scheduled jobs processing is completed, if specified.
//
// Parameters:
//  LaunchParameter  - String  - value of the global property LaunchParameter,
//                 has to be specified, because property is not available at server.
//  ParentSessionSet - Boolean - returns True, if parent session is specified,
//                 else returns False.
//
// Value returned:
//  Boolean.
//
Function ParentSessionSetAndCompleted(Val LaunchParameter) Export

	ParentSessionSet = False;
	If Find(LaunchParameter, "DoScheduledJobs") <> 0 Then
		SessionNoIndex = Find(LaunchParameter, "SessionNumber=");
		SessionBeginIndex = Find(LaunchParameter, "SessionStarted=");
		If SessionNoIndex <> 0 And
		     SessionBeginIndex <> 0 And
		     SessionNoIndex < SessionBeginIndex Then
			ParentSessionSet = True;
		    Sessions = GetInfobaseSessions();
			For each SessionNumber In Sessions Do
				If Find(LaunchParameter, "SessionNumber="  + SessionNumber.SessionNumber)  <> 0 And
				     Find(LaunchParameter, "SessionStarted=" + SessionNumber.SessionStarted) <> 0 Then
					Return False;
				EndIf;
			EndDo;
			Return True;
		EndIf;
	EndIf;
	Return False;

EndFunction // ParentSessionSetAndCompleted()

////////////////////////////////////////////////////////////////////////////////
// EXPORT METHODS OF THE SCHEDULED JOBS MANAGER EXTENSION
//

// Procedure ProcessScheduledJobs() emulates in thin client
// system procedure ProcessJobs(), but can be used
// aslo in thick client.
//
//  Storage of the instances of the background jobs - TemporaryStorage.
// Storage time of instances - until the closing of client session, running the processing.
// Maximum number of simultaneously stored background jobs: 1000.
//
//  SessionNumber id, that handles the processing is stored in the constant
// ScheduledJobsProcessingStatus (ValueStorage), containing the structure
// with properties:
// SessionNumber, SessionStarted, IDNextTasks,
// NextTaskProcessingBegin, OneMoreTaskProcessingEnding and other.
//  Logics of verification for the executing of scheduled jobs in current session:
// If <SessionNumber> and  <SessionStarted> match current session,
// Then execute, if none, then check if session exists in the list of all sessions,
// if it does not exist, then execute, if exists then doesn't execute, but check
// period of execution/idle. If "running"/"idles" longer
// than 1 hour notify user (error with the description).
//  Jobs execution order. Jobs run sequentially,
// last started job is registered. During next check, job that we check
// will be the job following the running job.
//  Schedule check logics. If error has occured then use emergency
// schedule, else - main.
//
// Parameters:
//  ProcessingTime - Number(10.0) - Time in seconds of the processing of next
//                 portion of the jobs. If time is not specified, just one processing
//                 cycle will be done (till the completion of one background job
//                 or processing of all scheduled jobs).
//
// Value returned:
//  Boolean       - NOT Cancellation.
//
Procedure ProcessScheduledJobs(ProcessingTime = 0, NotifyUser = False) Export
	
	If NOT CommonUse.FileInformationBase() Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	If NOT CurrentSessionHandlesTasks() Then
		Return;
	EndIf;
	
	State = GetScheduledJobsProcessingStatus();
	If State.Settings.ScheduledJobsProcessingLock Then
		Return;
	EndIf;

	// Allow calls of privileged functions for the time of execution of this procedure.
	CommonSettingsStorage.Save("RunningProcedureHandleScheduledJobs", , True);
	
	ProcessingTime 				= ?(TypeOf(ProcessingTime) = Type("Number"), ProcessingTime, 0);

	Tasks1                       	 	= ScheduledJobs.GetScheduledJobs();
	ProcessingCompleted             	= False; // Determines, that ProcessingTime has elapsed, or
	// all possible jobs have been processed.
	ProcessingBegin                		= CurrentDate();
	NumberOfProcessedJobs  				= 0;
	BackgroundJobWasRunning      		= False;
	LastTaskID = State.IDNextTasks;

	// Number of jobs will be checked every time on data processor start,
	// because they could be deleted in other session, and in this case looping will happen.
	While NOT ProcessingCompleted And Tasks1.Count() > 0 Do
		FirstJobFound           = (LastTaskID = Undefined);
		NextJobFound        = False;
		For each SchJob IN Tasks1 Do
			// Finish processing, if:
			// a) time is specified and it has elapsed;
			// b) time is not specified and at least one background job has completed;
			// in) time is not specified and all scheduled jobs have been processed by quantity.
			If ( ProcessingTime = 0 And
			       ( BackgroundJobWasRunning OR
			         NumberOfProcessedJobs >= Tasks1.Count() ) ) OR
			     ( ProcessingTime <> 0 And
			       ProcessingBegin + ProcessingTime <= CurrentDate() ) Then
				ProcessingCompleted = True;
				Break;
			EndIf;
			If NOT FirstJobFound Then
				If String(SchJob.UUID) = LastTaskID Then
				   // Last processed job is found, thus next one
				   // should be checked for the necessity of processing.
				   FirstJobFound = True;
				EndIf;
				// If first job, that needs to be checked for the necessity of start
				// has not been found so far, then skip current job.
				Continue;
			EndIf;
			NextJobFound 						= True;
			NumberOfProcessedJobs 				= NumberOfProcessedJobs + 1;
			State.IDNextTasks      				= String(SchJob.UUID);
			State.NextTaskProcessingBegin   	= CurrentDate();
			State.OneMoreTaskProcessingEnding 	= '00010101';
			RefreshScheduledJobsProcessingStatus(State,
			                                              "IDNextTasks,
			                                              |NextTaskProcessingBegin,
			                                              |OneMoreTaskProcessingEnding");
			If SchJob.Use Then
				ProcessScheduledJob = False;
				LastBackgroundJobProperties = GetLastBackgroundJobPropertiesOfScheduledJobDataProcessor(SchJob);
				
				If LastBackgroundJobProperties <> Undefined And
				     LastBackgroundJobProperties.State = BackgroundJobState.Failed Then
					// Check emergency schedule.
					If LastBackgroundJobProperties.LaunchTry <= SchJob.RestartCountOnFailure Then
						If LastBackgroundJobProperties.End + SchJob.RestartIntervalOnFailure <= CurrentDate() Then
						    // Restart background job by scheduled job.
						    ProcessScheduledJob = True;
						EndIf;
					EndIf;
				Else
					// Check standard schedule.
					ProcessScheduledJob = SchJob.Schedule.ExecutionRequired(
						CurrentDate(),
						?(LastBackgroundJobProperties = Undefined, '00010101', LastBackgroundJobProperties.Begin),
						?(LastBackgroundJobProperties = Undefined, '00010101', LastBackgroundJobProperties.End ));
				EndIf;
				If ProcessScheduledJob Then
					ProcessScheduledJob(SchJob);
					BackgroundJobWasRunning = True;
				EndIf;
			EndIf;
			State.OneMoreTaskProcessingEnding = CurrentDate();
			RefreshScheduledJobsProcessingStatus(State, "OneMoreTaskProcessingEnding");
		EndDo;
		// If last executed job has not been found, then
		// reset its Id, to start verification of scheduled jobs startting the first one.
		LastTaskID = Undefined;
	EndDo;
	
	// Prohibit calls of privileged functions after completion of the current procedure.
	CommonSettingsStorage.Save("RunningProcedureHandleScheduledJobs", , False);
	
EndProcedure // ProcessScheduledJobs()

// Procedure SetScheduledJobsProcessingSettings defines
// settings for the file mode of scheduled jobs processing.
//
// Parameters:
//  Settings - Structure.
//
Procedure SetScheduledJobsProcessingSettings(Settings) Export
	
	SetPrivilegedMode(True);
	
	Settings = UpdateSettings(Settings);
	
	BeginTransaction();
	Try
		State = GetScheduledJobsProcessingStatus(True);
		If State.Settings.ScheduledJobsProcessingLock <> Settings.ScheduledJobsProcessingLock Then
			CallExceptionIfNoAdminPrivileges();
		EndIf;
		State.Settings = Settings;
		RefreshScheduledJobsProcessingStatus(State);
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure // SetScheduledJobsProcessingSettings()

// Procedure GetScheduledJobsProcessingSettings gets settings
// for the file mode of scheduled jobs processing.
//
// Value returned:
//  Settings - Structure.
//
Function GetScheduledJobsProcessingSettings() Export
	
	SetPrivilegedMode(True);
	
	Return GetScheduledJobsProcessingStatus().Settings;
	
EndFunction // GetScheduledJobsProcessingSettings()

// Function returns presentation of the scheduled job,
// this is in order of exception of unfilled attributes:
// Description, Metadata.Synonym, Metadata.Name.
//
// Parameters:
//  SchJob      - ScheduledJob, String - if string, then UUID as string.
//
// Value returned:
//  String.
//
Function ScheduledJobPresentation(Val SchJob) Export
	
	CallExceptionIfNoAdminPrivileges();
	
	If TypeOf(SchJob) = Type("ScheduledJob") Then
		ScheduledJob = SchJob;
	Else
		ScheduledJob = ScheduledJobs.FindByUUID(New UUID(SchJob));
	EndIf;
	
	If ScheduledJob <> Undefined Then
		Presentation = ScheduledJob.Description;
		If IsBlankString(ScheduledJob.Description) Then
			// Apply synonym instead of description
			Presentation = ScheduledJob.Metadata.Synonym;
			If IsBlankString(Presentation) Then
				// Apply name instead of synonym
				Presentation = ScheduledJob.Metadata.Name;
			EndIf
		EndIf;
	Else
		Presentation = TextUndefined();
	EndIf;
	
	Return Presentation;
	
EndFunction // ScheduledJobPresentation()

// Service function, returning text "<undefined>" with localization.
// Used for localization purposes
//
Function TextUndefined() Export
	
	Return NStr("en = '<not defined>'");
	
EndFunction

// Function GetScheduledJob gets ScheduledJob from the infobase
// using string of unique id.
//
// Parameters:
//  Id - String of the unique id of the ScheduledJob.
//
// Value returned:
//  ScheduledJob.
//
Function GetScheduledJob(Val Id) Export

	CallExceptionIfNoAdminPrivileges();
	
	ScheduledJob = ScheduledJobs.FindByUUID(New UUID(Id));
	
	If ScheduledJob = Undefined Then
		Raise( NStr("en = 'The task is not found in the list! It might be deleted by another user!'") );
	EndIf;
	
	Return ScheduledJob;
	
EndFunction // GetScheduledJob()

// Procedure ProcessScheduledJobManually is used for
// "manual" immediate execution of the scheduled job
// either in client session (in file IB), or in background job at server (in server IB).
// Can be used in any connection mode.
// "Manual" running mode doesn not affect execution of scheduled job in emergency
// and main schedules, because ref to the scheduled job is not specified for the background job.
// Type BackgroundJob does not allow to assign such reference, therefor for the file mode the same rule
// is applied.
//
// Parameters:
//  SchJob      	 - ScheduledJob, String of the unique id of the ScheduledJob.
//  StartMoment 	 - Undefined, Date(date and time). For the file IB defines passed
//                 moment, as start moment. For the server IB - returns actual start moment
//                 of the background job.
//  BackgroundTaskID - String - id of the started background job.
//
//
Procedure ProcessScheduledJobManually(Val SchJob,
                                               StartMoment = Undefined,
                                               BackgroundTaskID = "") Export

	CallExceptionIfNoAdminPrivileges();
	
	SchJob = ?(TypeOf(SchJob) = Type("ScheduledJob"), SchJob, GetScheduledJob(SchJob));
	
	If CommonUse.FileInformationBase() Then
		ProcessScheduledJob(SchJob, True, StartMoment, BackgroundTaskID);
	// Status update has already been done in the called procedure.
	Else
		BeginTransaction();
		Try
			State 						= GetScheduledJobsProcessingStatus(True);
			BackgroundTaskDescription 	= StringFunctionsClientServer.SubstitureParametersInString(NStr("en = 'Run manually: %1'"), ScheduledJobPresentation(SchJob));
			BackgroundJob 				= BackgroundJobs.Execute(SchJob.Metadata.MethodName, SchJob.Parameters, SchJob.Key, BackgroundTaskDescription);
			BackgroundTaskID 			= String(BackgroundJob.UUID);
			State.Map_BJID_SJID_StartedAtServerManually.Insert( BackgroundTaskID, String(SchJob.UUID) );
			StartMoment 				= BackgroundJobs.FindByUUID(BackgroundJob.UUID).Begin;
			RefreshScheduledJobsProcessingStatus(State);
			CommitTransaction();
		Except
			RollbackTransaction();
			Raise;
		EndTry;
	EndIf;
	
EndProcedure // ProcessScheduledJobManually()

// Function NeedToNotifyAboutIncorrectStatusDataOfScheduledJobsProcessing returns
// value of the flag of setting of scheduled jobs processing.
//
// Value returned:
//  Boolean.
//
Function NeedToNotifyAboutIncorrectStatusDataOfScheduledJobsProcessing(PeriodNotifications) Export
	
	SetPrivilegedMode(True);
	
	NotifyAboutIncorrectStatus = False;
	
	If CommonUse.FileInformationBase() Then
		State 				= GetScheduledJobsProcessingStatus();
		PeriodNotifications = State.Settings.NotificationPeriodAboutStatusProcessingRegulatoryJobs;
		PeriodNotifications = ?(PeriodNotifications <= 0, 1, PeriodNotifications);
		NotifyAboutIncorrectStatus = State.Settings.NotifyAboutFailureInScheduledJobsProcessingStatus;
	Else
		PeriodNotifications = 1;
	EndIf;
	
	Return NotifyAboutIncorrectStatus;
	
EndFunction // NeedToNotifyAboutIncorrectStatusDataOfScheduledJobsProcessing()

// Function MessagesAndDescriptionsOfScheduledJobErrors returns
// multiline String containing Messages and DetailsOfInformationAboutError,
// last background job has found by scheduled job id
// and there are some messages/errors.
//
// Parameters:
//  SchJob      - ScheduledJob, String - UUID
//                 of ScheduledJob as string.
//
// Value returned:
//  String.
//
Function MessagesAndDescriptionsOfScheduledJobErrors(Val SchJob) Export
	
	CallExceptionIfNoAdminPrivileges();

	ScheduledJobID = ?(TypeOf(SchJob) = Type("ScheduledJob"), String(SchJob.UUID), SchJob);
	LastBackgroundJobProperties = GetLastBackgroundJobPropertiesOfScheduledJobDataProcessor(ScheduledJobID);
	Return ?(LastBackgroundJobProperties = Undefined,
	          "",
	          MessagesAndDescriptionsOfBackgroundJobErrors(LastBackgroundJobProperties.Id) );
	
EndFunction // MessagesAndDescriptionsOfScheduledJobErrors()

// Returns opening parameters of the session processing scheduled jobs.
//
// Parameters:
//  ByAutoOpenSettings - Boolean - open session, if it's configured to execute
//                 automatic opening and it's not server IB and not Web-client and
//                 session has not been already opened. In other cases Cancellation being assigned.
//
// Value returned:
//  Structure -    RequiredToOpenSeparateSession             	- Boolean - True.
//                 AdditionalParametersOfCommandLine     		- String - additional parameters of command line for
//                                                              		opening the session processing scheduled jobs.
//                 ExecutedOpenAttempt                   		- Boolean - False, for use in calling procedure.
//                 NotifyAboutProcessingIncorrectStatus  		- Boolean.
//                 PeriodNotifications                          - Number.
//                 Cancellation                                 - Boolean.
//                 ErrorDescription                             - String.
//
Function OpenParametersOfScheduledJobsProcessingSession(Val ByAutoOpenSettings = False) Export
	
	SetPrivilegedMode(True);
	
	Result = New Structure;
	Result.Insert("RequiredToOpenSeparateSession", 			False);
	Result.Insert("ExecutedOpenAttempt", 					False);
	Result.Insert("AdditionalParametersOfCommandLine", 		"");
	Result.Insert("NotifyAboutProcessingIncorrectStatus", 	False);
	Result.Insert("PeriodNotifications", 					Undefined);
	Result.Insert("Cancellation", 							False);
	Result.Insert("ErrorDescription", 						"");
	
	If ByAutoOpenSettings Then
		Result.Insert("CurrentUserAdministrator", AccessRight("Administration", Metadata, InfobaseUsers.CurrentUser()));
	EndIf;
	
	Result.NotifyAboutProcessingIncorrectStatus = NeedToNotifyAboutIncorrectStatusDataOfScheduledJobsProcessing(Result.PeriodNotifications);
	
	State = GetScheduledJobsProcessingStatus();
	
	If ByAutoOpenSettings And NOT State.Settings.AutomaticallyOpenSeparateSessionOfScheduledJobsProcessing Then
		Return Result;
	EndIf;
	
	If NOT CommonUse.FileInformationBase() Then
		If ByAutoOpenSettings Then
			Return Result;
		Else
			Result.Cancellation = True;
			Result.ErrorDescription = NStr("en = 'Scheduled jobs are processed on the server! '");
			Return Result;
		EndIf;
	EndIf;

	TasksAreProcessingOK = Undefined;
	CurrentSessionHandlesTasks(TasksAreProcessingOK);
	If TasksAreProcessingOK Then
		If ByAutoOpenSettings Then
			Return Result;
		Else
			Result.Cancellation = True;
			Result.ErrorDescription = NStr("en = 'Scheduled jobs executing session is already open!'");
			Return Result;
		EndIf;
	EndIf;
	
	CurrentSessionNumber = InfobaseSessionNumber();
	// Determine current session start date.
	CurrentSessionBegin = '00010101';
	Sessions = GetInfobaseSessions();
	For each SessionNumber In Sessions Do
		If SessionNumber.SessionNumber = CurrentSessionNumber Then
			CurrentSessionBegin = SessionNumber.SessionStarted;
			Break;
		EndIf;
	EndDo;
	Result.AdditionalParametersOfCommandLine = """"
		+ " /C""DoScheduledJobs SkipMessageBox AloneIBSession "
		+ "SessionNumber=" + CurrentSessionNumber + " SessionStarted=" + CurrentSessionBegin + """";
	
	Result.RequiredToOpenSeparateSession = True;
	
	Return Result;
	
EndFunction // OpenParametersOfScheduledJobsProcessingSession()

Function GetScheduledJobSchedule(Val Id) Export
	
	CallExceptionIfNoAdminPrivileges();
	
	Return GetScheduledJob(Id).Schedule;
	
EndFunction

Procedure SetScheduledJobSchedule(Val Id, Val Schedule) Export
	
	SetPrivilegedMode(True);
	
	SchJob = GetScheduledJob(Id);
	SchJob.Schedule = Schedule;
	SchJob.Write();
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// EXPORT METHODS OF THE GENERALIZED BACKGROUND JOBS MANAGER
//
// Generalized manager of the background jobs works both in file, and in server mode
// of the infobase.

// Function GetBackgroundJobsPropertiesTable() "emulates" function
// BackgroundJobs.GetBackgroundJobs() for any connection mode.
//  Table structure see in function CheckBackgroundJobsTable().
//
// Parameters:
//  Filter    - Structure - available fields:
//                 UUID, Key, State, Begin, End,
//                 Description, MethodName, ScheduledJob.
//  TotalJobs - Number 	  - returns total number of jobs without the filter.
//  ReadState - Undefined, only for internal use.
//
// Value returned:
//  ValueTable  - table after filtation is returned.
//
Function GetBackgroundJobsPropertiesTable(Filter = Undefined, TotalJobs = 0, Val ReadState = Undefined) Export

	CallExceptionIfNoAdminPrivileges();

	If ReadState = Undefined Then
		BeginTransaction();
	EndIf;
	Try
		If ReadState = Undefined Then
			State = GetScheduledJobsProcessingStatus(True);
		Else
			State = ReadState;
		EndIf;
		TableUpdated = NOT CheckBackgroundJobsTable(State.BackgroundJobsTable);
		Table = State.BackgroundJobsTable;
		If NOT CommonUse.FileInformationBase() Then
			// Complement table of the background jobs.
			// 1. Define start moment to complement.
			//    Find first active job, running at server.
			//    If there is no such job, then find last job running at server.
			//    Period start will be equal to the job execution start date.
			RowsOfActive = Table.FindRows(New Structure("AtServer, State", True, BackgroundJobState.Active));
			Begin = Undefined;
			If RowsOfActive.Count() <> 0 Then
				// Fill earliest start date.
				Begin = RowsOfActive[0].Begin;
				For each String In RowsOfActive Do
					Begin = ?(String.Begin < Begin, String.Begin, Begin);
				EndDo;
			Else
				LastString = Table.Find(True, "AtServer");
				If LastString <> Undefined Then
					Begin = LastString.Begin;
				EndIf;
			EndIf;
			If Begin = Undefined Then
				CurrentBackgroundJobs = BackgroundJobs.GetBackgroundJobs();
			Else
				CurrentBackgroundJobs = BackgroundJobs.GetBackgroundJobs(New Structure("Begin", Begin));
			EndIf;
			
			// 2. Refresh identical jobs and insert new background jobs.
			//    Consider, that jobs list is sorted descending by columns Begin.
			// 2.1. Check in cycle that, that all jobs in table with status Active have been obtained from server.
			//      If they are missing at server for some reason, then assign status: Completed.
			ActiveTasks = Table.FindRows(New Structure("State", BackgroundJobState.Active));
			TaskNumber = CurrentBackgroundJobs.Count() - 1;
			While TaskNumber >= 0 Do
				SchJob = CurrentBackgroundJobs[TaskNumber];
				RowsFound = Table.FindRows(New Structure("Id, Begin", String(SchJob.UUID), SchJob.Begin));
				If RowsFound.Count() = 0 Then
					String = Table.Insert(0);
					TableUpdated = True;
				Else
					String = RowsFound[0];
					If String.State <> BackgroundJobState.Active Then
						// There is no sense to update those inactive jobs, that are
						// already present in the table. They are in list iteratively.
						TaskNumber = TaskNumber - 1;
						Continue;
					EndIf;
					TableUpdated = True;
					// Check active tasks in table of tasks, deleted at server, by deleting the found ones from the list.
					ActiveTasks.Delete(ActiveTasks.Find(String));
				EndIf;
				FillPropertyValues(String, SchJob);
				String.AtServer = True;
				String.Id = SchJob.UUID;
				String.ScheduledJobID = ?(SchJob.ScheduledJob = Undefined,
															 // May already be assigned, if manual processing has been performed.
															 String.ScheduledJobID,
															 SchJob.ScheduledJob.UUID);
				String.DetailsOfInformationAboutError = ?(SchJob.ErrorInfo = Undefined, "", DetailErrorDescription(SchJob.ErrorInfo));
				TaskNumber = TaskNumber - 1;
			EndDo;
			// 2.3. Reset status Active for the active jobs in table, but not found at server.
			TableUpdated = TableUpdated OR ActiveTasks.Count() > 0;
			For each LostActiveJob In ActiveTasks Do
				LostActiveJob.State = BackgroundJobState.Completed;
			EndDo;
			
			// 3. Assign ids of scheduled jobs to those background jobs, which were executed manually.
			//    And delete dead (expired) mappings.
			RunningManually = State.Map_BJID_SJID_StartedAtServerManually;
			TableUpdated = TableUpdated OR RunningManually.Count() > 0;
			
			KeysArrayDelete = New Array;
			For each KeyAndValue in RunningManually Do
				String = Table.Find(KeyAndValue.Key, "Id");
				If String = Undefined Then
					KeysArrayDelete.Add(KeyAndValue.Key);
				Else
					String.ScheduledJobID = KeyAndValue.Value;
				EndIf;
			EndDo;
			For each Key In KeysArrayDelete Do
				RunningManually.Delete(Key);
			EndDo;

		EndIf;
		// Clear extra jobs (greater than 1000).
		TaskNumber = Table.Count()-1;
		While TaskNumber >= 1000 Do
			Table.Delete(TaskNumber);
			TaskNumber = TaskNumber - 1;
		EndDo;
		If ReadState = Undefined Then
			If TableUpdated Then
				RefreshScheduledJobsProcessingStatus(State);
				CommitTransaction();
			Else
				RollbackTransaction();
			EndIf;
		Else
			Table = Table.Copy();
		EndIf;
		TotalJobs = Table.Count();
	Except
		If ReadState = Undefined Then
			RollbackTransaction();
		EndIf;
		Raise;
	EndTry;
	
	// Filter background jobs.
	If Filter <> Undefined Then
		Begin 	  	= Undefined;
		End 	  	= Undefined;
		State 		= Undefined;
		If Filter.Property("Begin") Then
			Begin = ?(ValueIsFilled(Filter.Begin), Filter.Begin, Undefined);
			Filter.Delete("Begin");
		EndIf;
		If Filter.Property("End") Then
			End = ?(ValueIsFilled(Filter.End), Filter.End, Undefined);
			Filter.Delete("End");
		EndIf;
		If Filter.Property("State") Then
			If TypeOf(Filter.State) = Type("Array") Then
				State = Filter.State;
				Filter.Delete("State");
			EndIf;
		EndIf;
		If Filter.Count() <> 0 Then
			Rows = Table.FindRows(Filter);
		Else
			Rows = Table;
		EndIf;
		// Apply additional filter by period and state (if filter is defined).
		ItemNumber = Rows.Count() - 1;
		While ItemNumber >= 0 Do
			If Begin     <> Undefined And Begin > Rows[ItemNumber].Begin OR
				 End     <> Undefined And End  < ?(ValueIsFilled(Rows[ItemNumber].End), Rows[ItemNumber].End, CurrentDate()) OR
				 State 	 <> Undefined And State.Find(Rows[ItemNumber].State) = Undefined Then
				Rows.Delete(ItemNumber);
			EndIf;
			ItemNumber = ItemNumber - 1;
		EndDo;
		// Delete extra rows from the table.
		If TypeOf(Rows) = Type("Array") Then
			LineNumber = TotalJobs - 1;
			While LineNumber >= 0 Do
				If Rows.Find(Table[LineNumber]) = Undefined Then
					Table.Delete(Table[LineNumber]);
				EndIf;
				LineNumber = LineNumber - 1;
			EndDo;
		EndIf;
	EndIf;
	
	Return Table;
	
EndFunction // GetBackgroundJobsPropertiesTable()

// Function returns properties of the BackgroundJob using unique id string.
//
// Parameters:
//  Id 				- String - of the unique BackgroundJob id.
//  PropertyNames  	- String, if filled, structure with specified properties is returned.
//  ReadState 		- Undefined, only for internal use.
//            	
// Value returned:
//  ValueTableRow, Structure - properties of the BackgroundJob.
//
Function GetBackgroundJobProperties(Id, PropertyNames = "", ReadState = Undefined) Export
	
	CallExceptionIfNoAdminPrivileges();
	
	Filter = New Structure("Id", Id);
	BackgroundJobsPropertiesTable = GetBackgroundJobsPropertiesTable(Filter,, ReadState);
	
	If BackgroundJobsPropertiesTable.Count() = 0 Then
		Raise( NStr("en = 'Background job was not found!'") );
	EndIf;
	
	If ValueIsFilled(PropertyNames) Then
		Result = New Structure(PropertyNames);
		FillPropertyValues(Result, BackgroundJobsPropertiesTable[0]);
	Else
		Result = BackgroundJobsPropertiesTable[0];
	EndIf;
	
	Return Result;
	
EndFunction // GetBackgroundJobProperties()

// Function GetLastBackgroundJobPropertiesOfScheduledJobDataProcessor returns
// properties of the last background job executed by scheduled job, if it is present.
// Procedure works, both in file-server, and in client-server modes.
//
// Parameters:
//  ScheduledJob - ScheduledJob, String - ScheduledJob unique id string.
//  ReadState 	 - Undefined, only for internal use.
//
// Value returned:
//  ValueTableRow, Undefined.
//
Function GetLastBackgroundJobPropertiesOfScheduledJobDataProcessor(ScheduledJob, ReadState = Undefined) Export
	
	CallExceptionIfNoAdminPrivileges();
	
	ScheduledJobID = ?(TypeOf(ScheduledJob) = Type("ScheduledJob"), String(ScheduledJob.UUID), ScheduledJob);
	BackgroundJobsPropertiesTable = GetBackgroundJobsPropertiesTable(New Structure("ScheduledJobID", ScheduledJobID),, ReadState);
	BackgroundJobsPropertiesTable.Sort("End Asc");
	
	If BackgroundJobsPropertiesTable.Count() = 0 Then
		BackgroundJobProperties = Undefined;
	ElsIf NOT ValueIsFilled(BackgroundJobsPropertiesTable[0].End) Then
		BackgroundJobProperties = BackgroundJobsPropertiesTable[0];
	Else
		BackgroundJobProperties = BackgroundJobsPropertiesTable[BackgroundJobsPropertiesTable.Count()-1];
	EndIf;
	
	Return BackgroundJobProperties;
	
EndFunction // GetLastBackgroundJobPropertiesOfScheduledJobDataProcessor()

// Procedure CancelBackgroundJob cancels background job, if
// it is possible, i.e, if it is running at server, and is active.
//
// Parameters:
//  Id  - BackgroundJob unique id String.
//
// Value returned:
//  Boolean       - NOT Cancellation.
//
Procedure CancelBackgroundJob(Id) Export
	
	CallExceptionIfNoAdminPrivileges();
	
	If GetBackgroundJobProperties(Id, "State").State  <> BackgroundJobState.Active Then
		Raise( NStr("en = 'The task is not being performed, it cant be cancelled!'") );
		
	ElsIf CommonUse.FileInformationBase() Then
		Raise( NStr("en = 'The action is only possible for a server database!""You cannot cancel a background task running in the file database session!""""If the background task takes too long and it must be stopped, close  session which processes routine tasks""""If you can not close session and the application does not respond, you can end it forcibly, but there is a risk of losing changes made in the background task!'") );
	EndIf;
	
	Filter = New Structure("UUID", New UUID(Id));
	BackgroundJobsArray = BackgroundJobs.GetBackgroundJobs(Filter);
	If BackgroundJobsArray.Count() = 1 Then
		BackgroundJobsArray[0].Cancel();
	Else
		Raise( NStr("en = 'Background job was not found on server!'") );
	EndIf;
	
EndProcedure // CancelBackgroundJob()

// Function MessagesAndDescriptionsOfBackgroundJobErrors returns
// multiline String containing Messages and DetailsOfInformationAboutError,
// if background job was found by id and there are some messages/errors.
//
// Parameters:
//  SchJob      - String - BackgroundJob UUID as string.
//
// Value returned:
//  String.
//
Function MessagesAndDescriptionsOfBackgroundJobErrors(Id) Export
	
	CallExceptionIfNoAdminPrivileges();
	
	BackgroundJobProperties = GetBackgroundJobProperties(Id);
	String = "";
	For each Message In BackgroundJobProperties.MessagesToUser Do
		String = String + ?(String = "",
		                    Message,
		                    "
		                    |
		                    |" + Message);
	EndDo;
	If ValueIsFilled(BackgroundJobProperties.DetailsOfInformationAboutError) Then
		String = String + ?(String = "",
		                    BackgroundJobProperties.DetailsOfInformationAboutError,
		                    "
		                    |
		                    |" + BackgroundJobProperties.DetailsOfInformationAboutError);
	EndIf;
	
	Return String;
	
EndFunction // MessagesAndDescriptionsOfBackgroundJobErrors()

// Procedure ClearBackgroundJobsHistory clears table
// of completed and running (for server mode) background jobs.
//
Procedure ClearBackgroundJobsHistory() Export

	CallExceptionIfNoAdminPrivileges();

	BeginTransaction();
	Try
		State = GetScheduledJobsProcessingStatus(True);
		If CommonUse.FileInformationBase() Then
			State.BackgroundJobsTable = Undefined;
		Else
			CurrentBackgroundJobs = BackgroundJobs.GetBackgroundJobs();
			IDs = New Map;
			For each BackgroundJob In CurrentBackgroundJobs Do
				IDs.Insert(String(BackgroundJob.UUID), 1);
			EndDo;
			IndexOf = State.BackgroundJobsTable.Count()-1;
			While IndexOf >=0 Do
				If IDs.Get(State.BackgroundJobsTable[IndexOf].Id) <> 1 Then
					State.BackgroundJobsTable.Delete(IndexOf);
				EndIf;
				IndexOf = IndexOf - 1;
			EndDo;
		EndIf;
		CheckBackgroundJobsTable(State.BackgroundJobsTable);
		RefreshScheduledJobsProcessingStatus(State);
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// SERVICE METHODS OF THE GENERALIZED MANAGER OF BACKGROUND JOBS

// Function CheckBackgroundJobsTable checks structure of the ValueTable
// for storage of the completed/running background jobs,
// and creates empty table, if there are any differences.
//
// Parameters:
//  Table       - ValueTable - table whose structure will be verified.
//
// Value returned:
//  Boolean 	- when True structure is correct.
//
Function CheckBackgroundJobsTable(Table)
	
	NewTable = New ValueTable;
	NewTable.Columns.Add("AtServer", 								New TypeDescription("Boolean"));
	NewTable.Columns.Add("Id", 										New TypeDescription("String"));
	NewTable.Columns.Add("Description", 							New TypeDescription("String"));
	NewTable.Columns.Add("Key",	 									New TypeDescription("String"));
	NewTable.Columns.Add("Begin", 									New TypeDescription("Date"));
	NewTable.Columns.Add("End", 									New TypeDescription("Date"));
	NewTable.Columns.Add("ScheduledJobID", 							New TypeDescription("String"));
	NewTable.Columns.Add("State", 									New TypeDescription("BackgroundJobState"));
	NewTable.Columns.Add("MethodName", 								New TypeDescription("String"));
	NewTable.Columns.Add("Location", 								New TypeDescription("String"));
	NewTable.Columns.Add("DetailsOfInformationAboutError", 	New TypeDescription("String"));
	NewTable.Columns.Add("LaunchTry", 								New TypeDescription("Number"));
	NewTable.Columns.Add("MessagesToUser", 							New TypeDescription("Array"));
	NewTable.Indexes.Add("Id, Begin");
	CorrectStructure = True;
	If TypeOf(Table) = Type("ValueTable") Then
		For each Column In NewTable.Columns Do
			// Only column names will be checked (without types).
			If Table.Columns.Find(Column.Name) = Undefined Then
				CorrectStructure = False;
			EndIf;
		EndDo;
	Else
		CorrectStructure = False;
	EndIf;
	
	If NOT CorrectStructure Then
		Table = NewTable;
	EndIf;
	
	Return CorrectStructure;
	
EndFunction // CheckBackgroundJobsTable()

// Function UpdateSettings is used for filling/restore of structure of settings
// properties, stored in structure "State" of the property Settings.
//
// Parameters:
//  Settings  - Undefined, Structure.
//
// Value returned:
//  Structure - Updated settings.
//
Function UpdateSettings(Val Settings = Undefined)
	
	NewSettingsStructure = New Structure();
	NewSettingsStructure.Insert("ScheduledJobsProcessingLock",                           	 False);
	// If it's needed and possible, then on start of the client application, scheduled jobs processing session should be automatically started.
	NewSettingsStructure.Insert("AutomaticallyOpenSeparateSessionOfScheduledJobsProcessing", False);
	// Notify user, if tasks are not being processed or data processor is "stuck".
	NewSettingsStructure.Insert("NotifyAboutFailureInScheduledJobsProcessingStatus",     	 False);
	//  Period, minutes.
	NewSettingsStructure.Insert("NotificationPeriodAboutStatusProcessingRegulatoryJobs",          15);
	
	// Copy existing properties.
	If TypeOf(Settings) = Type("Structure") Then
		For each KeyAndValue In NewSettingsStructure Do
			If Settings.Property(KeyAndValue.Key) Then
				If TypeOf(NewSettingsStructure[KeyAndValue.Key]) = TypeOf(Settings[KeyAndValue.Key]) Then
					NewSettingsStructure[KeyAndValue.Key] = Settings[KeyAndValue.Key];
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	
	If NOT (NewSettingsStructure.NotificationPeriodAboutStatusProcessingRegulatoryJobs >= 1 And
	         NewSettingsStructure.NotificationPeriodAboutStatusProcessingRegulatoryJobs <= 99 ) Then
	
		NewSettingsStructure.NotificationPeriodAboutStatusProcessingRegulatoryJobs = 15;
	EndIf;
	
	Return NewSettingsStructure;
	
EndFunction

// Function GetScheduledJobsProcessingStatus returns
// structure, describing status of scheduled jobs processing.
//
Function GetScheduledJobsProcessingStatus(Lock = False)
	
	// Prepare data for the verification or initialization of the properties of initial state.
	NewStructure = New Structure();
	NewStructure.Insert("Settings", New Structure);
	//  Map of the background job ids to the scheduled job ids,
	//  of those background jobs, that were started manually at server.
	NewStructure.Insert("Map_BJID_SJID_StartedAtServerManually", New Map());
	// Store history of the background jobs execution.
	NewStructure.Insert("BackgroundJobsTable",          New ValueTable);
	NewStructure.Insert("SessionNumber",                0);
	NewStructure.Insert("SessionStarted",               '00010101');
	NewStructure.Insert("ComputerName",                 "");
	NewStructure.Insert("ApplicationName",              "");
	NewStructure.Insert("UserName",                     "");
	NewStructure.Insert("IDNextTasks",      			"");
	NewStructure.Insert("NextTaskProcessingBegin",     '00010101');
	NewStructure.Insert("OneMoreTaskProcessingEnding", '00010101');
	
	If Lock Then
		Block 	  = New DataLock;
		Item      = Block.Add("Constant.ScheduledJobsProcessingStatus");
		Item.Mode = DataLockMode.Exclusive;
		Block.Lock();
	EndIf;
	
	State = Constants.ScheduledJobsProcessingStatus.Get().Get();
	
	// Copy existing properties.
	If TypeOf(State) = Type(NewStructure) Then
		For each KeyAndValue In NewStructure Do
			If State.Property(KeyAndValue.Key) Then
				If TypeOf(NewStructure[KeyAndValue.Key]) = TypeOf(State[KeyAndValue.Key]) Then
					NewStructure[KeyAndValue.Key] = State[KeyAndValue.Key];
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	
	NewStructure.Settings = UpdateSettings(NewStructure.Settings);
	
	CheckBackgroundJobsTable(NewStructure.BackgroundJobsTable);
	
	Return NewStructure;
	
EndFunction

// Procedure RefreshScheduledJobsProcessingStatus() saves
// passed state in the constant ScheduledJobsProcessingStatus.
//
// Parameters:
//  State 				- Structure - modified function value
//                				 GetScheduledJobsProcessingStatus().
//  ModifiedProperties 	- Undefined, String;
//                       Undefined 		- need to write the state (there is an outer transaction);
//                       String       	- the list of property names, separated by commas,
//                                      which have to be updated in separate transaction.
//
Procedure RefreshScheduledJobsProcessingStatus(State, Val ModifiedProperties = Undefined)
	
	If ModifiedProperties = Undefined Then
		Constants.ScheduledJobsProcessingStatus.Set(New ValueStorage(State));
	Else
		BeginTransaction();
		Try
			CurrentStatus = GetScheduledJobsProcessingStatus(True);
			FillPropertyValues(CurrentStatus, State, ModifiedProperties);
			State = CurrentStatus;
			Constants.ScheduledJobsProcessingStatus.Set(New ValueStorage(State));
			CommitTransaction();
		Except
			RollbackTransaction();
			Raise;
		EndTry;
	EndIf;
	
EndProcedure // RefreshScheduledJobsProcessingStatus()

// Procedure ProcessScheduledJob is used
// only in "file-server" mode, is used in procedure
// ProcessScheduledJobs()
//
// Parameters:
//  State    		 - Structure.
//  SchJob     	 - ScheduledJob.
//  RunManually 	 - Boolean.
//  StartMoment 	 - Undefined, Date(date and time). Assignes value, on start moment.
//  BackgroundTaskID - String - id of the started background job.
//
Procedure ProcessScheduledJob(Val SchJob,
                                        Val RunManually = False,
                                        Val StartMoment = Undefined,
                                        BackgroundTaskID = "")

	BeginTransaction();
	Try
		State = GetScheduledJobsProcessingStatus(True);
		LastBackgroundJobProperties = GetLastBackgroundJobPropertiesOfScheduledJobDataProcessor(SchJob, State);

		MethodName = SchJob.Metadata.MethodName;
		BackgroundTaskDescription = ?(RunManually,
		                                StringFunctionsClientServer.SubstitureParametersInString(NStr("en = 'Run manually: %1'"),
		                                                                                        ScheduledJobPresentation(SchJob)),
		                                "");

		StartMoment = ?(TypeOf(StartMoment) <> Type("Date") OR NOT ValueIsFilled(StartMoment),
		                  CurrentDate(),
		                  StartMoment);
		Table = State.BackgroundJobsTable;
		// Create new background job in table.
		BackgroundJobProperties = Table.Insert(0);
		BackgroundJobProperties.Id  = String(New UUID());
		BackgroundTaskID = BackgroundJobProperties.Id;
		BackgroundJobProperties.LaunchTry = ?(LastBackgroundJobProperties <> Undefined And
		                                           LastBackgroundJobProperties.State = BackgroundJobState.Failed,
		                                           LastBackgroundJobProperties.LaunchTry + 1,
		                                  1);
		BackgroundJobProperties.Description   = BackgroundTaskDescription;
		BackgroundJobProperties.ScheduledJobID
		                                       = String(SchJob.UUID);
		BackgroundJobProperties.Location = "\\" + ComputerName();
		BackgroundJobProperties.MethodName    = MethodName;
		BackgroundJobProperties.State    = BackgroundJobState.Active;
		BackgroundJobProperties.Begin       = StartMoment;
		// Prepare command to execute method instead of the background job.
		StringOfParameters = "";
		IndexOf = SchJob.Parameters.Count()-1;
		While IndexOf >= 0 Do
			If NOT IsBlankString(StringOfParameters) Then
				StringOfParameters = StringOfParameters + ", ";
			EndIf;
			StringOfParameters = StringOfParameters + "SchJob.Parameters[" + IndexOf + "]";
			IndexOf = IndexOf - 1;
		EndDo;
		//
		RefreshScheduledJobsProcessingStatus(State);
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	GetUserMessages(True);
	Try
		Execute("" + MethodName + "(" + StringOfParameters + ");");
		BackgroundJobProperties.State = BackgroundJobState.Completed;
	Except
		BackgroundJobProperties.State = BackgroundJobState.Failed;
		BackgroundJobProperties.DetailsOfInformationAboutError = DetailErrorDescription(ErrorInfo());
	EndTry;
	// Reflect method execution ending.
	BackgroundJobProperties.End = CurrentDate();
	BackgroundJobProperties.MessagesToUser = GetUserMessages(True);
	
	// Update state properties.
	BeginTransaction();
	Try
		State = GetScheduledJobsProcessingStatus(True);
		BackgroundJobCurrentProperties = State.BackgroundJobsTable.Find(BackgroundJobProperties.Id, "Id");
		If BackgroundJobCurrentProperties <> Undefined Then
			FillPropertyValues(BackgroundJobCurrentProperties,
			                         BackgroundJobProperties,
			                         "State,
			                         |DetailsOfInformationAboutError,
			                         |End,
			                         |MessagesToUser");
			RefreshScheduledJobsProcessingStatus(State);
			CommitTransaction();
		Else
			// State update is not required, if background jobs table has been cleared in the execution process.
			RollbackTransaction();
		EndIf;
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	
EndProcedure // ProcessScheduledJob()
