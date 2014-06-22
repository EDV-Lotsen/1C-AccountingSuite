
////////////////////////////////////////////////////////////////////////////////
// Units: Item form
//------------------------------------------------------------------------------
// Available on:
// - Client (managed application)
// - Server
//

////////////////////////////////////////////////////////////////////////////////
#Region EVENTS_HANDLERS

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Update quantities presentation.
	QuantityFormat = GeneralFunctionsReusable.DefaultQuantityFormat();
	Items.Factor.Format     = QuantityFormat;
	Items.Factor.EditFormat = QuantityFormat;
	
EndProcedure

#EndRegion
