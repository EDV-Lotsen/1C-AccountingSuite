
////////////////////////////////////////////////////////////////////////////////
// Quote: List form
//------------------------------------------------------------------------------
// Available on:
// - Client (managed application)
// - Server
//

////////////////////////////////////////////////////////////////////////////////
#Region EVENTS_HANDLERS

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Set proper company field presentation.
	CustomerName = GeneralFunctionsReusable.GetCustomerName();
	Items.Company.Title           = CustomerName;
	Items.Company.ToolTip         = StringFunctionsClientServer.SubstituteParametersInString(NStr("en = '%1 name'"), CustomerName);
	Items.DropshipCompany.Title   = StringFunctionsClientServer.SubstituteParametersInString(NStr("en = 'Dropship %1'"), Lower(CustomerName));
	Items.DropshipCompany.ToolTip = StringFunctionsClientServer.SubstituteParametersInString(NStr("en = 'Dropship %1 name'"), Lower(CustomerName));
	
EndProcedure

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region COMMANDS_HANDLERS

&AtClient
Procedure CancelQuote(Command)
	
	If Items.List.SelectedRows <> Undefined Then
		
		CancelQuoteAtServer();
		Items.List.Refresh();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure CancelQuoteAtServer()
	
	For Each DocumentsRef In Items.List.SelectedRows Do
		
		If Documents.Quote.IsOpen(DocumentsRef) Then
			
			DocumentObject = DocumentsRef.GetObject();
			DocumentObject.Cancelled = True;
			DocumentObject.Write();
			
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion
