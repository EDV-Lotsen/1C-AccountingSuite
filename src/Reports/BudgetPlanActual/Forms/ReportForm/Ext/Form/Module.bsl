
&AtClient
Procedure Run(Command)
	
	CreateReportOnServer();
	
EndProcedure

&AtServer
Procedure CreateReportOnServer()
	
	ReportObject = FormAttributeToValue("Report");
	CreatedReport = ReportObject.IncomeStatement(Year);
	
	SDocument.Clear();
	SDocument.Put(CreatedReport);
	
EndProcedure
