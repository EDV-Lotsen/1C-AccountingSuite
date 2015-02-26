
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	Spreadsheet = New SpreadsheetDocument;
	PrintReconciliationReport(Spreadsheet, CommandParameter);
	Spreadsheet.ShowGrid = False;
	Spreadsheet.Protection = False;
	Spreadsheet.ReadOnly = False;
	Spreadsheet.FitToPage = True;
	Spreadsheet.ShowHeaders = False;
	Spreadsheet.Show(NStr("en = 'Print preview'") + ": Reconciliation Report");
EndProcedure

&AtServer
Procedure PrintReconciliationReport(Spreadsheet, CommandParameter)
	
	//Documents.InvoicePayment.PrintCheck(Spreadsheet, CommandParameter);
	Documents.BankReconciliation.PrintReconciliationReport(Spreadsheet, CommandParameter);
	
EndProcedure

