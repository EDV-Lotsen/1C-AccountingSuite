
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	Spreadsheet = New SpreadsheetDocument;
	PrintCheck(Spreadsheet, CommandParameter);
	Spreadsheet.ShowGrid = False;
	Spreadsheet.Protection = False;
	Spreadsheet.ReadOnly = False;
	Spreadsheet.FitToPage = True;
	Spreadsheet.ShowHeaders = False;
	SpreadsheetTitle = NStr("en = 'Check'");
	FormParameters = New Structure("SpreadsheetDocument, TitleOfForm, PrintFormID", Spreadsheet, SpreadsheetTitle, CommandParameter[0]);
	OpenForm("CommonForm.PrintForm", FormParameters);
	
EndProcedure

&AtServer
Procedure PrintCheck(Spreadsheet, CommandParameter)
	
	Documents.Check.PrintCheck(Spreadsheet, CommandParameter);
	
EndProcedure
