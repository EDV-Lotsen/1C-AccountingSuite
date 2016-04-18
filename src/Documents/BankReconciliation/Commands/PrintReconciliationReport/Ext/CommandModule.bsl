
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	Spreadsheet = New SpreadsheetDocument;
	PrintReconciliationReport(Spreadsheet, CommandParameter);
	Spreadsheet.ShowGrid = False;
	Spreadsheet.Protection = False;
	Spreadsheet.ReadOnly = False;
	Spreadsheet.FitToPage = True;
	Spreadsheet.ShowHeaders = False;
	SpreadsheetTitle	= "Reconciliation Report";
	FormParameters = New Structure("SpreadsheetDocument, TitleOfForm, PrintFormID", Spreadsheet, SpreadsheetTitle, CommandParameter[0]);
	OpenForm("CommonForm.PrintForm", FormParameters);
	
EndProcedure

&AtServer
Procedure PrintReconciliationReport(Spreadsheet, CommandParameter)
	
	//Documents.InvoicePayment.PrintCheck(Spreadsheet, CommandParameter);
	Documents.BankReconciliation.PrintReconciliationReport(Spreadsheet, CommandParameter);
	
EndProcedure

