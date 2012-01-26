
&AtClient
Procedure Run(Command)
	
	CreateReportOnServer();
	
EndProcedure

&AtServer
Procedure CreateReportOnServer()
	
	ReportObject = FormAttributeToValue("Report");
	CreatedReport = ReportObject.Summary1099(Period.StartDate, Period.EndDate);
	
	SDocument.Clear();
	SDocument.Put(CreatedReport);
	
EndProcedure
