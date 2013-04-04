
////////////////////////////////////////////////////////////////////////////////
// PROCEDURES HANDLING SYSTEM EVENTS

// Procedure NotifyAboutFailureInScheduledJobsProcessingStatus notifies
// users of not processing of scheduled jobs and "freezing" of background jobs.
//  Procedure functions only if infobase is of file type. For the server IB
// responsibility for scheduled jobs processing lays on 1C server administrator.
//  Attaches in procedure ScheduledJobsClient.OnStart().
//
Procedure NotifyAboutFailureInScheduledJobsProcessingStatus() Export

	PeriodNotifications = Undefined; // Minutes.
	If ScheduledJobsServer.NeedToNotifyAboutIncorrectStatusDataOfScheduledJobsProcessing(PeriodNotifications) Then
		ErrorDescription = "";
		TasksAreProcessingOK = Undefined;
		ScheduledJobsServer.CurrentSessionHandlesTasks(TasksAreProcessingOK, , ErrorDescription);
		If NOT TasksAreProcessingOK Then
			ScheduledJobsClient.OnScheduledJobsProcessingError(ErrorDescription);
		EndIf;
		AttachIdleHandler("NotifyAboutFailureInScheduledJobsProcessingStatus", PeriodNotifications * 60, True);
	EndIf;

EndProcedure // NotifyAboutFailureInScheduledJobsProcessingStatus()

// Procedure ScheduledJobsProcessingInMainSession() called
// by idle handler, that is being attached in
// ScheduledJobsClient.OnStart().
//  For processing in separate session form
// DataProcessors.ScheduledAndBackgroundJobs.Form.ScheduledJobsProcessing is used.
//
Procedure ScheduledJobsProcessingInMainSession() Export

	If ScheduledJobsServer.CurrentSessionHandlesTasks() Then
		ScheduledJobsServer.ProcessScheduledJobs(, True);
		AttachIdleHandler("ScheduledJobsProcessingInMainSession", 60, True);
	EndIf;
	
EndProcedure // ScheduledJobsProcessingInMainSession()

Procedure OpenSeparateSessionOfScheduledJobsProcessingViaIdleHandler() Export
	
	Result = ScheduledJobsClient.OpenSeparateSessionOfScheduledJobsProcessing();
	
	If Result.Cancellation  Then
		DoMessageBox(Result.ErrorDescription);
		
	ElsIf Result.ExecutedOpenAttempt Then
		
		AttachIdleHandler("ActivateMainWindowOfCurrentSessionAfterLaunchSeparateSessionOfScheduledJobsProcessing", 2, True);
	EndIf;
	
EndProcedure

Procedure ActivateMainWindowOfCurrentSessionAfterLaunchSeparateSessionOfScheduledJobsProcessing() Export
	
	MainWindow = ScheduledJobsClient.MainWindow();
	If MainWindow <> Undefined Then
		MainWindow.Activate();
	EndIf;
	
EndProcedure

