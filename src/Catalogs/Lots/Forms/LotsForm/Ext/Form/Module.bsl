
////////////////////////////////////////////////////////////////////////////////
// Lots: List form
//------------------------------------------------------------------------------
// Available on:
// - Client (managed application)
// - Server
//

////////////////////////////////////////////////////////////////////////////////
#Region EVENTS_HANDLERS

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	Var Owner, Product;
	
	// Set filter parameters.
	If  Parameters.Filter.Property("Product", Product)
	And Parameters.Filter.Property("Owner",   Owner)
	Then
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
			EndIf;
		EndIf;
	Else
		// The form can be opened only with product/owner filter.
		Cancel = True;
		Return;
	EndIf;
	
	// Update quantities presentation.
	QuantityFormat    = GeneralFunctionsReusable.DefaultQuantityFormat();
	Items.Balance.EditFormat  = QuantityFormat;
	Items.Balance.Format      = QuantityFormat;
	
	// Set current date parameter.
	List.Parameters.SetParameterValue("CurrentDate", BegOfDay(CurrentSessionDate()));
	List.Parameters.SetParameterValue("Product",     Product);
	List.Parameters.SetParameterValue("Owner",       Owner);
	
EndProcedure

#EndRegion
