
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	Spreadsheet = New SpreadsheetDocument;
	PrintCheck(Spreadsheet, CommandParameter);
	Spreadsheet.ShowGrid = False;
	Spreadsheet.Protection = False;
	Spreadsheet.ReadOnly = False;
	Spreadsheet.FitToPage = True;
	Spreadsheet.ShowHeaders = False;
	Spreadsheet.Show("Invoice payment (Check)");
	
EndProcedure

&AtServer
Procedure PrintCheck(Spreadsheet, CommandParameter)
	
	Documents.InvoicePayment.PrintCheck(Spreadsheet, CommandParameter);
	
EndProcedure
