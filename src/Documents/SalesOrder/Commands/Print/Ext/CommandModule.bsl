
////////////////////////////////////////////////////////////////////////////////
// Sales order: Print command
//------------------------------------------------------------------------------
// Available on:
// - Client (managed application)
// - Server
//

////////////////////////////////////////////////////////////////////////////////
#Region COMMANDS_HANDLERS

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
	Spreadsheet.Show(NStr("en = 'Print preview'") + ?(Not IsBlankString(SpreadsheetTitle), ": " + SpreadsheetTitle, ""));
	
EndProcedure

&AtServer
Procedure Print(Spreadsheet, SpreadsheetTitle, CommandParameter)
	
	// Call document module to print the document.
	Documents.SalesOrder.Print(Spreadsheet, SpreadsheetTitle, CommandParameter);
	
EndProcedure

#EndRegion
