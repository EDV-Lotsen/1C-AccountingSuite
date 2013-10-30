&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	//{{_PRINT_WIZARD(Print)
	Spreadsheet = New SpreadsheetDocument;
	PrintPackingList(Spreadsheet, CommandParameter);

	Spreadsheet.ShowGrid = False;
	Spreadsheet.FitToPage = True;
	Spreadsheet.Protection = False;
	Spreadsheet.ReadOnly = False;
	Spreadsheet.ShowHeaders = False;
	Spreadsheet.Show("Packing list");
	//}}
EndProcedure

&AtServer
Procedure PrintPackingList(Spreadsheet, CommandParameter)
	Documents.SalesInvoice.PrintPackingList(Spreadsheet, CommandParameter);
EndProcedure
