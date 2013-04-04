

////////////////////////////////////////////////////////////////////////////////
// FORM EVENT HANDLERS
//

&AtServer
Procedure OnCreateAtServer(Cancellation, StandardProcessing)

	If NOT CommonUse.FileInformationBase() Then
		Cancellation = True;
	EndIf;
	
	Settings = ScheduledJobsServer.GetScheduledJobsProcessingSettings();
	FillPropertyValues(ThisForm, Settings);
	
	If NOT AccessRight("Administration", Metadata) Then
		Items.ScheduledJobsProcessingLock.Visible = False;
	EndIf;
	
	Items.OpenSeparateSessionOfScheduledJobsProcessing.Visible = NOT Parameters.HideCommandOfSeparateSessionOpening;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancellation, StandardProcessing)
	
	If Modified Then
		ReturnCode = DoQueryBox(NStr("en = 'Write changes?'"), QuestionDialogMode.YesNoCancel);
		If ReturnCode = DialogReturnCode.Yes Then
			WriteChanges();
		ElsIf ReturnCode = DialogReturnCode.Cancel Then
			Cancellation = True;
		EndIf;
	EndIf;
	
EndProcedure


&AtClient
Procedure OpenSeparateSessionOfScheduledJobsProcessingExecute()
	
	AttachIdleHandler("OpenSeparateSessionOfScheduledJobsProcessingViaIdleHandler", 1, True);
	
EndProcedure

&AtClient
Procedure WriteAndCloseExecute()
	
	WriteChanges();
	Close();
	
EndProcedure

&AtClient
Procedure Write(Command)
	
	WriteChanges();
	
EndProcedure

&AtClient
Procedure NotificationPeriodAboutStatusProcessingRegulatoryJobsOnChange(Item)
	
	If NotificationPeriodAboutStatusProcessingRegulatoryJobs <= 0 Then
		NotificationPeriodAboutStatusProcessingRegulatoryJobs = 1;
	EndIf;
	
EndProcedure


////////////////////////////////////////////////////////////////////////////////
// Auxiliary form procedures and functions
//

&AtClient
Procedure WriteChanges()
	
	WriteChangesAtServer();
	Modified = False;
	ScheduledJobsClient.DisableGlobalIdleHandler("NotifyAboutFailureInScheduledJobsProcessingStatus");
	If NotifyAboutFailureInScheduledJobsProcessingStatus Then
		ScheduledJobsClient.AttachGlobalIdleHandler("NotifyAboutFailureInScheduledJobsProcessingStatus",
		                                                                 NotificationPeriodAboutStatusProcessingRegulatoryJobs * 60,
		                                                                 True);
	EndIf;
	
EndProcedure

&AtServer
Procedure WriteChangesAtServer()
	
	Settings = ScheduledJobsServer.GetScheduledJobsProcessingSettings();
	FillPropertyValues(Settings, ThisForm);
	ScheduledJobsServer.SetScheduledJobsProcessingSettings(Settings);
	FillPropertyValues(ThisForm, Settings);
	
EndProcedure

