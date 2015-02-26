
////////////////////////////////////////////////////////////////////////////////
// Assembly: Choice form
//------------------------------------------------------------------------------
// Available on:
// - Client (managed application)
// - Server
//

////////////////////////////////////////////////////////////////////////////////
#Region EVENTS_HANDLERS

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Set custom controls presentation.
	Items.Quantity.Format = GeneralFunctionsReusable.DefaultQuantityFormat();
	
EndProcedure

#EndRegion
