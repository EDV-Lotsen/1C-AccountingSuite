
// Handler of events of form "OnCreateAtServer".
// Performs initialization of period attributes.
//
&AtServer
Procedure OnCreateAtServer(Cancellation, StandardProcessing)
	
	SelectionPeriodEnding = CurrentDate();
	SelectionPeriodBegin  = SelectionPeriodEnding - 86400;
	RefreshReportOnForm();
	ScheduledJobID = ScheduledJobs.FindPredefined(Metadata.ScheduledJobs.EventLog).Uuid;
	
EndProcedure

// Handler of click on button "Refresh"
//
&AtClient
Procedure RefreshReportOnFormExecute()
	
	ClearMessages();
	CreateReport = True;
	If Not ValueIsFilled(SelectionPeriodBegin) Then
		CommonUseClientServer.MessageToUser(
					NStr("en = 'Date/time of the beginning of selection has not been filled in'"), ,
						 "SelectionPeriodBegin");
		CreateReport = False;
	EndIf;
	
	If Not ValueIsFilled(SelectionPeriodEnding) Then
		CommonUseClientServer.MessageToUser(
		              NStr("en = 'Date/time of the end of selection has not been filled in'"), ,
		              	   "SelectionPeriodEnding");
		CreateReport = False;
	EndIf;
	If CreateReport Then
		RefreshReportOnForm();
	EndIf;
	
EndProcedure

// Gets error data from eventlog and generates
// report. Report is put to the form.
//
&AtServer
Procedure RefreshReportOnForm()
	
	// based on data received generate report and write it on disk
	ReportResult =
	   DataProcessors.EventLogMonitor.GenerateReport(
	                         SelectionPeriodBegin,
	                         SelectionPeriodEnding);
	
	Report = ReportResult.Report;
	
EndProcedure

// Handler of click event on button "Report recipients".
//
&AtClient
Procedure SpecifyReportRecipientsExecute()
	
	OpenForm("DataProcessor.EventLogMonitor.Form.MailingAddressesSetupForReportSending");
	
EndProcedure

// Handler of command "Scheduled job schedule".
//
&AtClient
Procedure ConfigureScheduledJobScheduleExecute()
	
	Dialog = New ScheduledJobDialog(ScheduledJobsServer.GetScheduledJobSchedule(ScheduledJobID));
	If Dialog.DoModal() Then
		ScheduledJobsServer.SetScheduledJobSchedule(ScheduledJobID, Dialog.Schedule);
	EndIf;
		
EndProcedure

