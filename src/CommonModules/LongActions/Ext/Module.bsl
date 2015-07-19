
////////////////////////////////////////////////////////////////////////////////
// Base functionality subsystem.
//------------------------------------------------------------------------------
// Support of long server actions at the web client.
//

////////////////////////////////////////////////////////////////////////////////
#Region PUBLIC_INTERFACE

// Executes procedures interactively from a form in a background job.
// The function returns a storage address, where an execution result will be placed.
// The function must be defined using the special parameters structure, defining
// the final storage address ID.
//
// Parameters:
// FormID - UUID - form ID, the long action is executed from this form.
// ExportProcedureName - String - export procedure name for execute in background job.
// Parameters - Structure - parameters of ExportProcedureName function.
// JobDescription - String - background job description.
//   If JobDescription is not specified it will be equal to ExportProcedureName.
// UseAdditionalTemporaryStorage - Boolean - Use additional temporary storage
//   to put the data from background job into parent session.
//
// Returns:
// Structure - returns following properties: 
// - StorageAddress - Temporary storage address where a job result will be put.
// - JobID - executing background job UUID;
// - JobCompleted - True if job completed successfully.
//
Function ExecuteActionInBackground(Val FormID, Val ExportProcedureName,
	Val Parameters, Val JobDescription = "", UseAdditionalTemporaryStorage = False) Export
	
	StorageAddress = PutToTempStorage(Undefined, FormID);
	
	Result = New Structure;
	Result.Insert("StorageAddress" , StorageAddress);
	Result.Insert("JobCompleted" , False);
	Result.Insert("JobID",Undefined);
	
	If Not ValueIsFilled(JobDescription) Then
		JobDescription = ExportProcedureName;
	EndIf;
	
	ExportProcedureParameters = New Array;
	ExportProcedureParameters.Add(Parameters);
	ExportProcedureParameters.Add(StorageAddress);
	
	If UseAdditionalTemporaryStorage Then
		StorageAddressAdd = PutToTempStorage(Undefined, FormID);
		ExportProcedureParameters.Add(StorageAddressAdd);
	EndIf;
	
	JobParameters = New Array;
	JobParameters.Add(ExportProcedureName);
	//JobParameters.Add(ExportProcedureParameters);
	JobParameters.Add(Parameters);
	JobParameters.Add(Undefined); // Data area, where job must be executed
	
	If GetClientConnectionSpeed() = ClientConnectionSpeed.Low Then
		Timeout = 4;
	Else
		Timeout = 2;
	EndIf;
	
	Job = BackgroundJobs.Execute("CommonUse.ExecuteSafely", JobParameters,, JobDescription);
	Try
		Job.WaitForCompletion(Timeout);
	Except
		// There is no need to process an exception. Mostly the exception was raised by the timeout.
	EndTry;
	Result.JobCompleted = JobCompleted(Job.UUID);
	Result.JobID = Job.UUID;
	
	If UseAdditionalTemporaryStorage Then
		Result.Insert("StorageAddressAdd", StorageAddressAdd);
	EndIf;
	
	Return Result;
	
EndFunction

// Executes procedures in a background job without the result checking.
// The function does not provide an ability to check execution result.
// Any server function can be called, no special processing in the function required.
//
// Parameters:
// ProcedureName - String - export procedure name for execute in background job.
// ProcedureParameters - Structure - parameters of ExportProcedureName function.
// JobDescription - String - background job description.
//   If JobDescription is not specified it will be equal to ExportProcedureName.
//
// Returns:
//  JobID - executing background job UUID;
//
Function ExecuteInBackground(Val ProcedureName, Val ProcedureParameters,
	Val JobDescription = "") Export
	
	If Not ValueIsFilled(JobDescription) Then
		JobDescription = ProcedureName;
	EndIf;
	
	JobParameters = New Array;
	JobParameters.Add(ProcedureName);
	JobParameters.Add(ProcedureParameters);
	JobParameters.Add(Undefined); // Data area, where job must be executed
	Job = BackgroundJobs.Execute("CommonUse.ExecuteSafely", JobParameters,, JobDescription);
	
	Return Job.UUID;
	
EndFunction

// Cancels background job execution by the passed ID.
// 
// Parameters:
// JobID - UUID - background job ID.
// 
Procedure CancelJobExecution(Val JobID) Export
	
	If Not ValueIsFilled(JobID) Then
		Return;
	EndIf;
	
	Job = FindJobByID(JobID);
	If Job = Undefined
		Or Job.State <> BackgroundJobState.Active Then
		
		Return;
	EndIf;
	
	Try
		Job.Undo();
	Except
		// Perhaps job finished just at this moment and there is no error.
		WriteLogEvent(NStr("en = 'Long actions. Background job canceled'"),
			EventLogLevel.Error,,,
			DetailErrorDescription(ErrorInfo()));
	EndTry;
	
EndProcedure

// Checks background job state by the passed ID.
// 
// Parameters:
// JobID - UUID - background job ID. 
//
// Returns:
// Boolean - returns True, if the job completed successfully;
// False - if the job is still executing. In other cases an exception is raised.
//
Function JobCompleted(Val JobID) Export
	
	Job = FindJobByID(JobID);
	
	If Job <> Undefined
		And Job.State = BackgroundJobState.Active Then
		Return False;
	EndIf;
	
	ActionNotExecuted = True;
	ShowFullErrorText = False;
	
	If Job = Undefined Then
		WriteLogEvent(NStr("en = 'Long actions. Background job is not found'"),
			EventLogLevel.Error,,, String(JobID));
			
	Else
		If Job.State = BackgroundJobState.Failed Then
			JobError = Job.ErrorInfo;
			If JobError <> Undefined Then
				WriteLogEvent(NStr("en = 'Long actions. Background job failed'"),
					EventLogLevel.Error,,,
					DetailErrorDescription(Job.ErrorInfo));
				ShowFullErrorText = True;	
			Else
				WriteLogEvent(NStr("en = 'Long actions. Background job failed'"),
					EventLogLevel.Error,,,
					NStr("en = 'The job finished with an unknown error.'"));
			EndIf;
			
		ElsIf Job.State = BackgroundJobState.Canceled Then
			WriteLogEvent(NStr("en = 'Long actions. Administrator canceled background job'"),
				EventLogLevel.Error,,,
				NStr("en = 'The job was canceled.'"));
				
		Else
			Return True;
		EndIf;
	EndIf;
	
	If ShowFullErrorText Then
		ErrorText = BriefErrorDescription(GetErrorInfo(Job.ErrorInfo));
		Raise ErrorText;
		
	ElsIf ActionNotExecuted Then
		Raise(NStr("en = 'This job cannot be executed. 
		                 |See details in the Event log.'"));
	EndIf;
	
EndFunction

// Writes in messages information about job running state
// Further possible to read this information by function GetActionProgress()
//
// Parameters:
//  Progress - Number  - percentage of execution.
//  Text - String -  Additional info about job state.
//  AdditionalParameters - Any additional info for Client must be simple (must be serialized to XML string) 
//
Procedure InformActionProgres(Val Progress = Undefined, Val Text = Undefined, Val AdditionalParameters = Undefined) Export 
	
	ReturningValue = New Structure;
	If Progress <> Undefined Then 
		ReturningValue.Insert("Progress", Progress);
	EndIf;
	If Text <> Undefined Then
		ReturningValue.Insert("Text", Text);
	EndIf;
	If AdditionalParameters <> Undefined Then
		ReturningValue.Insert("AdditionalParameters", AdditionalParameters);
	EndIf;
	
	ResultText = CommonUse.ValueToXMLString(ReturningValue);
	Text = "{CommonSubsystems.LongActions}" + ResultText;
	CommonUseClientServer.MessageToUser(Text);
	
	GetUserMessages(Истина); // Удаление предыдущих сообщений.
	
EndProcedure

//Gets Background job by Job ID, and reads running status through job messages
// Return:
//   Structure - Background job execution status.
//       Names and values according mapping in procedure "InformActionProgres()"
Function GetActionProgress(Val JobUID) Export 
	
	Var Result;
	
	CurrentJob = LongActions.FindJobByID(JobUID);
	If CurrentJob = Undefined Then 
		Return CurrentJob;
	EndIf;
	
	MessagesArray = CurrentJob.GetUserMessages(True);
	If MessagesArray = Undefined Тогда
		Return Result;
	EndIf;;
	
	Quantity = MessagesArray.Count();
	
	For Counter = 1 To Quantity Do
		CoutBack = Quantity - Counter;
		CurMessage = MessagesArray[CoutBack];
		
		If Left(CurMessage.Text, 1) = "{" Then
			Position = Find(CurMessage.Text, "}");
			If Position > 2 Then
				IDCodeUnit = Mid(CurMessage.Text, 2, Position - 2);
				If IDCodeUnit = "CommonSubsystems.LongActions" Then
					ResultText = Mid(CurMessage.Text, Position + 1);
					Result = CommonUse.ValueFromXMLString(ResultText);
					Break;
				EndIf;;
			EndIf;
		EndIf;
	EndDo;
	
	Return Result;
EndFunction

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region PRIVATE_IMPLEMENTATION

Function FindJobByID(Val JobID) Export
	
	Job = BackgroundJobs.FindByUUID(JobID);
	
	Return Job;
	
EndFunction

Function GetErrorInfo(ErrorInfo)
	
	Result = ErrorInfo;
	If ErrorInfo.Cause <> Undefined Then
		If ErrorInfo.Cause <> Undefined Then		
			Result = GetErrorInfo(ErrorInfo.Cause);
		EndIf;
	EndIf;
	
	Return Result;
	
EndFunction


#EndRegion
