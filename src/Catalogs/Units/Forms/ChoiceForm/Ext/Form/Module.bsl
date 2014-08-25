
////////////////////////////////////////////////////////////////////////////////
// Units: Choice form
//------------------------------------------------------------------------------
// Available on:
// - Client (managed application)
// - Server
//

////////////////////////////////////////////////////////////////////////////////
#Region EVENTS_HANDLERS

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Check opening by owner.
	OwnerFiltered = Parameters.Property("Filter") And Parameters.Filter.Property("Owner")
	                And ValueIsFilled(Parameters.Filter.Owner);
	Items.Owner.Visible = Not OwnerFiltered;
	
	// Update quantities presentation.
	QuantityFormat = GeneralFunctionsReusable.DefaultQuantityFormat();
	Items.Factor.Format = QuantityFormat;
	
EndProcedure

#EndRegion
