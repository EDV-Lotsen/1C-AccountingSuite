
&AtClient
Procedure Run(Command)
	
	CreateReportOnServer();
	
EndProcedure

&AtServer
Procedure CreateReportOnServer()
	
	ReportObject = FormAttributeToValue("Report");
	CreatedReport = ReportObject.IncomeStatement(Period.StartDate, Period.EndDate);
	
	SDocument.Clear();
	SDocument.Put(CreatedReport);
	
EndProcedure
