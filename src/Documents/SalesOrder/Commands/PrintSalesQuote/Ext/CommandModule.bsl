&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	//{{_PRINT_WIZARD(Print)
	Spreadsheet = New SpreadsheetDocument;
	Print(Spreadsheet, CommandParameter);

	Spreadsheet.ShowGrid = False;
	Spreadsheet.Protection = False;
	Spreadsheet.FitToPage = True;
	Spreadsheet.ReadOnly = False;
	Spreadsheet.ShowHeaders = False;
	Spreadsheet.Show();
	//}}
EndProcedure

&AtServer
Procedure Print(Spreadsheet, CommandParameter)
	Documents.SalesOrder.PrintQuote(Spreadsheet, CommandParameter);
EndProcedure
