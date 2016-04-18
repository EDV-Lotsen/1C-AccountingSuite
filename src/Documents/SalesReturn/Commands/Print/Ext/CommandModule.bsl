
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	// Create a new spreadsheet.
	Spreadsheet      = New SpreadsheetDocument;
	SpreadsheetTitle = "";
	
	// Output the documents to spreadsheet.
	Print(Spreadsheet, SpreadsheetTitle, CommandParameter);
	
	// Set the proper options and open the preview.
	Spreadsheet.ShowGrid    = False;
	Spreadsheet.ShowHeaders = False;
	Spreadsheet.FitToPage   = True;
	Spreadsheet.ReadOnly    = False;
	Spreadsheet.Protection  = False;
	FormParameters = New Structure("SpreadsheetDocument, TitleOfForm, PrintFormID", Spreadsheet, SpreadsheetTitle, CommandParameter[0]);
	OpenForm("CommonForm.PrintForm", FormParameters);
	
EndProcedure

&AtServer
Procedure Print(Spreadsheet, SpreadsheetTitle, CommandParameter)
	
	// Call document module to print the document.
	Documents.SalesReturn.Print(Spreadsheet, SpreadsheetTitle, CommandParameter);
	
EndProcedure
