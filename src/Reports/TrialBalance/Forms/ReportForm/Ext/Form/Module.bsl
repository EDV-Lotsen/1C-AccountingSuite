
&AtClient
Procedure Run(Command)
	
	CreateReportOnServer();
	
EndProcedure

&AtServer
Procedure CreateReportOnServer()
	
	ReportObject = FormAttributeToValue("Report");
	CreatedReport = ReportObject.TrialBalance(Date);
	
	SDocument.Clear();
	SDocument.Put(CreatedReport);
	
EndProcedure
