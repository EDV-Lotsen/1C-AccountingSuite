
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
	
	If Object.BaseUnit Then
		Items.UnitFactor.Visible = False;
	Else
		Items.BaseUnit.Title = GeneralFunctions.GetBaseUnit(Object.Owner).Code;
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// Update unit factor if it wasn't set.
	If Object.Factor = 0 Then Object.Factor = 1 EndIf;
	
EndProcedure

#EndRegion
