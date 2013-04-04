
////////////////////////////////////////////////////////////////////////////////
// SCHEDULED JOB HANDLER

// Procedure - scheduled job ControlOfErrorsInEventlog handler
//
Procedure ScheduledJobProcessing_EventLogErrorsMonitoring() Export
	
	WriteLogEvent(EventLogMessage(),
		EventLogLevel.Information, , ,
		NStr("en = 'The scheduled event log errors and warnings monitoring started'"));
	
	Try
		DataProcessors.EventLogMonitor.GenerateErrorReportAndSendReport();
		WriteLogEvent(EventLogMessage(),
			EventLogLevel.Information, , ,
			NStr("en = 'The scheduled event log errors and warnings monitoring completed'"));
	Except
		WriteLogEvent(EventLogMessage(),
			EventLogLevel.Error, , ,
			StringFunctionsClientServer.SubstitureParametersInString(
			NStr("en = 'Unknown error occurred during the scheduled event log errors and warnings monitoring: %1'"), ErrorDescription()));
	EndTry;
	
EndProcedure

Function GetReportReceiptRecipientsByEventLog() Export
	
	SetPrivilegedMode(True);
	
	Return Constants.EventLogReportRecipients.Get();
	
EndFunction

Procedure SetReportRecipientsByEventlog(ELRecipients) Export
	
	SetPrivilegedMode(True);
	
	Constants.EventLogReportRecipients.Set(ELRecipients);
	
EndProcedure

Function EventLogMessage()
	
	Return "Event Log Monitoring";
	
EndFunction	

