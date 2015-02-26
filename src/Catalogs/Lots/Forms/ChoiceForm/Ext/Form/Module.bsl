
////////////////////////////////////////////////////////////////////////////////
// Lots: Choice form
//------------------------------------------------------------------------------
// Available on:
// - Client (managed application)
// - Server
//

////////////////////////////////////////////////////////////////////////////////
#Region EVENTS_HANDLERS

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	Var Owner;
	
	// By default expiration filter is disabled.
	SetExpirationFilter = False;
	
	// Hide owner if already specified.
	If Parameters.Filter.Property("Owner", Owner) Then
		// Hide owner columns.
		Items.OwnerCode.Visible = False;
		Items.OwnerDescription.Visible = False;
		
		// Update lot column header.
		If TypeOf(Owner) = Type("CatalogRef.Characteristics") Then
			Items.Ref.Title = NStr("en = 'Value'");
		ElsIf TypeOf(Owner) = Type("CatalogRef.Products") Then
			If Owner.UseLotsType = 0 Then
				Items.Ref.Title = NStr("en = 'Lot No'");
			ElsIf Owner.UseLotsType = 2 Then
				If Owner.UseLotsByExpiration = 0 Then
					Items.Ref.Title = NStr("en = 'Expiration date'");
				ElsIf Owner.UseLotsByExpiration = 1 Then
					Items.Ref.Title = NStr("en = 'Production date'");
				EndIf;
				Items.Valid.Visible = True;
				SetExpirationFilter = True;
			EndIf;
		EndIf;
	EndIf;
	
	// Find expiration date filter.
	ValidFilter = Undefined;
	For Each Row In List.SettingsComposer.Settings.Filter.Items Do
		If Row.UserSettingPresentation = "Show only valid items" Then
			ValidFilter = Row;
			Break;
		EndIf;
	EndDo;
	
	// Set expiration quick filter availability.
	If ValidFilter <> Undefined Then
		ValidFilter.Use      = SetExpirationFilter;
		ValidFilter.ViewMode = ?(SetExpirationFilter, DataCompositionSettingsItemViewMode.QuickAccess,
		                                              DataCompositionSettingsItemViewMode.Inaccessible);
	EndIf;
	
	// Set current date parameter.
	List.Parameters.SetParameterValue("CurrentDate", BegOfDay(CurrentSessionDate()));
	
EndProcedure

#EndRegion
