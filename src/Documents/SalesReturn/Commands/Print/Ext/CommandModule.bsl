
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	Spreadsheet = New SpreadsheetDocument;
	
	Print(Spreadsheet, CommandParameter);

	Spreadsheet.ShowGrid = False;
	Spreadsheet.FitToPage = True;
	Spreadsheet.Protection = False;
	Spreadsheet.ReadOnly = False;
	Spreadsheet.ShowHeaders = False;
	Spreadsheet.Show("Credit memo");
	
EndProcedure

&AtServer
Procedure Print(Spreadsheet, CommandParameter)
	Documents.SalesReturn.Print(Spreadsheet, CommandParameter);
EndProcedure


