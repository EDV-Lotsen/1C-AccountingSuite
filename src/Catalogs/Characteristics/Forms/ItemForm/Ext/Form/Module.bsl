
////////////////////////////////////////////////////////////////////////////////
// Characteristics: Item form
//------------------------------------------------------------------------------
// Available on:
// - Client (managed application)
// - Server
//

////////////////////////////////////////////////////////////////////////////////
#Region EVENTS_HANDLERS

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Set filter for units in set.
	CommonUseClientServer.SetFilterItem(Lots.Filter, "Owner", Object.Ref, DataCompositionComparisonType.Equal, "Owner", True, DataCompositionSettingsItemViewMode.Auto);
	
	// Update owned items accessibility.
	ObjSaved = Not Object.Ref.IsEmpty();
	Items.LotsList.Enabled = ObjSaved;
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// Add new object flag.
	WriteParameters.Insert("IsNew", CurrentObject.IsNew());
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	// Create new unit and assign it as default unit for the set.
	If WriteParameters.IsNew Then
		
		// Update units list filter.
		CommonUseClientServer.SetFilterItem(Lots.Filter, "Owner", CurrentObject.Ref, DataCompositionComparisonType.Equal, "Owner", True, DataCompositionSettingsItemViewMode.Auto);
		
		// Update owned items accessibility.
		Items.LotsList.Enabled = True;
	EndIf;
	
EndProcedure

#EndRegion
