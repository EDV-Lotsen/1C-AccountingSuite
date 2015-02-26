
////////////////////////////////////////////////////////////////////////////////
// Lots: Item form
//------------------------------------------------------------------------------
// Available on:
// - Client (managed application)
// - Server
//

////////////////////////////////////////////////////////////////////////////////
#Region EVENTS_HANDLERS

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Hide owner if already specified.
	If ValueIsFilled(Object.Owner) Then
		Items.Owner.Visible = False;
		Items.OwnerDate.Visible = False;
	EndIf;
	
	// Update fields presentation.
	OwnerOnChangeAtServer();
	
	// Fill date value of code.
	If TypeOf(Object.Owner) = Type("CatalogRef.Products") And Object.Owner.UseLotsType = 2 Then
		// Fill lot date.
		CodeDate = Items.CodeDate.TypeRestriction.AdjustValue(Object.Code);
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// Fill date value of code.
	If TypeOf(CurrentObject.Owner) = Type("CatalogRef.Products") And CurrentObject.Owner.UseLotsType = 2 Then
		
		// Fill code by the product date.
		CurrentObject.Code = Format(CodeDate, "DF=yyyyMMdd");
	EndIf;
	
EndProcedure

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region CONTROLS_EVENTS_HANDLERS

&AtClient
Procedure OwnerOnChange(Item)
	
	// Request server operation.
	OwnerOnChangeAtServer();
	
EndProcedure

&AtServer
Procedure OwnerOnChangeAtServer()
	
	// Update fields presentation.
	If TypeOf(Object.Owner) = Type("CatalogRef.Products") Then
		
		// Set current page by lots type.
		Items.UseLotsType.CurrentPage = Items.UseLotsType.ChildItems[?(Object.Owner.UseLotsType = 2, 1, 0)];
		
		// Set value page titles.
		Items.Owner.Title = "Item";
		Items.Code.Title  = "Lot No";
		
		// Set date page titles.
		If Object.Owner.UseLotsType = 2 Then
			If Object.Owner.UseLotsByExpiration = 0 Then
				Items.CodeDate.Title  = "Expiration date";
			Else
				Items.CodeDate.Title  = "Production date";
			EndIf;
		EndIf;
		
	ElsIf TypeOf(Object.Owner) = Type("CatalogRef.Characteristics") Then
		
		// Set current page by lots type.
		Items.UseLotsType.CurrentPage = Items.UseLotsType.ChildItems[0];
		
		// Set value page titles.
		Items.Owner.Title = "Characteristic";
		Items.Code.Title  = "Value";
	EndIf;
	
EndProcedure

#EndRegion