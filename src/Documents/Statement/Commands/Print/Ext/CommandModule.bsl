
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	Spreadsheet = New SpreadsheetDocument;
	Print(Spreadsheet, CommandParameter);

	Spreadsheet.ShowGrid = False;
	Spreadsheet.Protection = False;
	Spreadsheet.ReadOnly = False;
	Spreadsheet.ShowHeaders = False;
	Spreadsheet.Show("Statement", "Statement");
	
EndProcedure

&AtServer
Procedure Print(Spreadsheet, CommandParameter)
	Documents.Statement.Print(Spreadsheet, CommandParameter);
EndProcedure
