

////////////////////////////////////////////////////////////////////////////////
#Region EVENTS_HANDLERS

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Items.GroupExecuteBackgroundJob.Visible = True;
	Items.GroupStopJob.Visible              = False;
	Items.GroupDecorationLongAction.Visible = False;
	Items.GroupDecorationDone.Visible       = False;
	Items.GroupGetResult.Visible            = False;
		
EndProcedure

#EndRegion


////////////////////////////////////////////////////////////////////////////////
#Region COMMANDS_HANDLERS

&AtClient
Procedure ExecuteBackgroundJob(Command)
	
	//0.
	JobStatus = "...";
	
	//1.
	RunJob();
	
	//2.
	Items.GroupExecuteBackgroundJob.Visible = False;
	Items.GroupStopJob.Visible              = True;
	Items.GroupDecorationLongAction.Visible = True;
	Items.GroupDecorationDone.Visible       = False;
	Items.GroupGetResult.Visible            = False;
	
	//3.
	AttachIdleHandler("CheckJobStatus", 1, True);
		
EndProcedure

&AtClient
Procedure StopJob(Command)
	
	StopJobAtServer();
	
EndProcedure

&AtServer
Procedure StopJobAtServer()
	
	Job = BackgroundJobs.FindByUUID(JobUUID);
	Job.Cancel();
	
EndProcedure

&AtClient
Procedure GetResult(Command)
	
	GetFile(JobResponseAddress, GetFileName(), True);
	
EndProcedure

#EndRegion


////////////////////////////////////////////////////////////////////////////////
#Region PRIVATE_IMPLEMENTATION

&AtServer
Procedure RunJob()
	
	//1.1 Create storage address for response
	JobResponseAddress = PutToTempStorage("", ThisForm.UUID);
	
	//1.2 Create long action.
	JobParameters = New Array(); 
	JobParameters.Add(JobResponseAddress);
	JobParameters.Add(FormAttributeToValue("Object").GetTemplate("Template"));
	
	Job = BackgroundJobs.Execute("CommonUse.UnloadDatabase", JobParameters,, NStr("en = 'Long action'"));
	JobUUID = Job.UUID;
		
EndProcedure

&AtClient
Procedure CheckJobStatus()
	
	AttachNextIdleHandler = CheckJobStatusAtServer();
	
	If AttachNextIdleHandler Then
		AttachIdleHandler("CheckJobStatus", 1, True);
	EndIf;
	
EndProcedure

&AtServer
Function CheckJobStatusAtServer(); 

	AttachNextIdleHandler = False;
	
	Job = BackgroundJobs.FindByUUID(JobUUID);
	
	If Job = Undefined Then
		
		Items.GroupExecuteBackgroundJob.Visible = True;
		Items.GroupStopJob.Visible              = False;
		Items.GroupDecorationLongAction.Visible = False;
		Items.GroupDecorationDone.Visible       = False;
		Items.GroupGetResult.Visible            = False;
		
		JobStatus = NStr("en = 'Error!'");
		
	ElsIf Job.State = BackgroundJobState.Canceled Or Job.State = BackgroundJobState.Failed Then
		
		Items.GroupExecuteBackgroundJob.Visible = True;
		Items.GroupStopJob.Visible              = False;
		Items.GroupDecorationLongAction.Visible = False;
		Items.GroupDecorationDone.Visible       = False;
		Items.GroupGetResult.Visible            = False;
		
		JobStatus = NStr("en = 'Canceled or Failed!'");
		
	ElsIf Job.State = BackgroundJobState.Active Then
		
		UserMessages = Job.GetUserMessages(True);
		UBound       = UserMessages.UBound();
		
		If UBound >= 0 Then 
			JobMessage = UserMessages.Get(UBound).Text;
			JobStatus  = "" + JobMessage;
		EndIf;
	
		AttachNextIdleHandler = True;
		
	ElsIf Job.State = BackgroundJobState.Completed Then
		
		Items.GroupExecuteBackgroundJob.Visible = False;
		Items.GroupStopJob.Visible              = False;
		Items.GroupDecorationLongAction.Visible = False;
		Items.GroupDecorationDone.Visible       = True;
		Items.GroupGetResult.Visible            = True;
		
		JobStatus = NStr("en = 'Done!'");
		
	EndIf;
	
	Return AttachNextIdleHandler;
		
EndFunction

&AtServerNoContext
Function GetFileName() 
	Return "database_backup_" + Format(CurrentSessionDate(), "DF=MMddyy_hhmmsstt") + ".zip";
EndFunction

#EndRegion