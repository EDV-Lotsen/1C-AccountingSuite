
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	Spreadsheet = New SpreadsheetDocument;
	PrintCheck(Spreadsheet, CommandParameter);
	Spreadsheet.ShowGrid = False;
	Spreadsheet.Protection = False;
	Spreadsheet.ReadOnly = False;
	Spreadsheet.FitToPage = True;
	Spreadsheet.ShowHeaders = False;
	//Spreadsheet.Show();
	FormParameters = New Structure("SpreadsheetDocument, TitleOfForm", Spreadsheet, NStr("en = 'Check'"));
	OpenForm("CommonForm.PrintForm", FormParameters);
	
EndProcedure

&AtServer
Procedure PrintCheck(Spreadsheet, CommandParameter)
	
	Documents.Check.PrintCheck(Spreadsheet, CommandParameter);
	
EndProcedure
