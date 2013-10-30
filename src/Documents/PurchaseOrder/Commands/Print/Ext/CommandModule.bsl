&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	//{{_PRINT_WIZARD(Print)
	Spreadsheet = New SpreadsheetDocument;
	Print(Spreadsheet, CommandParameter);

	Spreadsheet.ShowGrid = False;
	Spreadsheet.Protection = False;
	Spreadsheet.ReadOnly = False;
	Spreadsheet.FitToPage = True;
	Spreadsheet.ShowHeaders = False;
	Spreadsheet.Show("Purchase order");
	//}}
EndProcedure

&AtServer
Procedure Print(Spreadsheet, CommandParameter)
	Documents.PurchaseOrder.Print(Spreadsheet, CommandParameter);
EndProcedure
