
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
	Spreadsheet = New SpreadsheetDocument;
	
	// Output the documents to spreadsheet.
	PickList(Spreadsheet, CommandParameter);

	// Set the proper options and open the preview.
	Spreadsheet.ShowGrid    = False;
	Spreadsheet.ShowHeaders = False;
	Spreadsheet.FitToPage   = True;
	Spreadsheet.ReadOnly    = False;
	Spreadsheet.Protection  = False;
	Spreadsheet.Show(NStr("en = 'Print preview: Pick list'"));
	
EndProcedure

&AtServer
Procedure PickList(Spreadsheet, CommandParameter)
	
	// Call document module to print the document.
	Documents.SalesOrder.PickList(Spreadsheet, CommandParameter);
	
EndProcedure

#EndRegion

