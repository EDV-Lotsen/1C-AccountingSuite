
&AtClient
Procedure Run(Command)
	
	CreateReportOnServer();
	
EndProcedure

&AtServer
Procedure CreateReportOnServer()
	
	ReportObject = FormAttributeToValue("Report");
	CreatedReport = ReportObject.BalanceSheet(Date);
	
	SDocument.Clear();
	SDocument.Put(CreatedReport);
	
EndProcedure
