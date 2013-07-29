
&AtClient
Procedure Run(Command)
	
	VendorAttribute = CommonUse.GetAttributeValue(Report.Vendor, "Ref");
	
	If VendorAttribute = Undefined Then
		Message("Select a vendor");
	Else
		CreateReportOnServer();
	EndIf;
		
EndProcedure

&AtServer
Procedure CreateReportOnServer()
	
	ReportObject = FormAttributeToValue("Report");
	CreatedReport = ReportObject.Form1099(Period.StartDate, Period.EndDate);
	
	SDocument.Clear();
	SDocument.Put(CreatedReport);
	
EndProcedure
