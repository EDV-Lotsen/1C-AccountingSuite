&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	//{{_PRINT_WIZARD(Print)
	Spreadsheet = New SpreadsheetDocument;
	
	Print(Spreadsheet, CommandParameter);

	Spreadsheet.ShowGrid = False;
	Spreadsheet.FitToPage = True;
	Spreadsheet.Protection = False;
	Spreadsheet.ReadOnly = False;
	Spreadsheet.ShowHeaders = False;
	Spreadsheet.Show("Invoice");
	//}}
EndProcedure

&AtServer
Procedure Print(Spreadsheet, CommandParameter)
	Documents.SalesInvoice.Print(Spreadsheet, CommandParameter);
EndProcedure
