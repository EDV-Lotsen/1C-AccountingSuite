
////////////////////////////////////////////////////////////////////////////////
// Purchase order: Choice form
//------------------------------------------------------------------------------
// Available on:
// - Client (managed application)
// - Server
//

////////////////////////////////////////////////////////////////////////////////
#Region EVENTS_HANDLERS

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Set proper Company field presentation.
	Items.Company.Title = GeneralFunctionsReusable.GetVendorName();
	
EndProcedure

#EndRegion
