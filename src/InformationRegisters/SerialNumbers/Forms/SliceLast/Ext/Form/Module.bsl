
////////////////////////////////////////////////////////////////////////////////
// Serial numbers: Slice last form
//------------------------------------------------------------------------------
// Available on:
// - Client (managed application)
// - Server
//

////////////////////////////////////////////////////////////////////////////////
#Region EVENTS_HANDLERS

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Set product filter parameter.
	List.Parameters.SetParameterValue("Product", Parameters.Filter.Product);
	
EndProcedure

#EndRegion
