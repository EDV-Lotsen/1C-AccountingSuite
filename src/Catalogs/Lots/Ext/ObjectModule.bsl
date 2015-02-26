
////////////////////////////////////////////////////////////////////////////////
// Unit sets: Object module
//------------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
#Region EVENT_HANDLERS

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

Procedure BeforeWrite(Cancel)
	
	// Calculate lot expiration date.
	If TypeOf(Owner) = Type("CatalogRef.Products") And Owner.UseLotsType = 2 Then
		If Owner.UseLotsByExpiration = 0 Then
			ExpirationDate = Date(Code);
		ElsIf Owner.UseLotsByExpiration = 1 Then
			If Owner.ShelfLifeUnit = 1 Then    // Month
				ExpirationDate = AddMonth(Date(Code), Owner.ShelfLife);
			ElsIf Owner.ShelfLifeUnit = 2 Then // Year
				ExpirationDate = AddMonth(Date(Code), Owner.ShelfLife * 12);
			Else                               // Days
				ExpirationDate = Date(Code) + Owner.ShelfLife * 24 * 60 * 60;
			EndIf;
		EndIf;
	Else
		ExpirationDate = '00010101'; // Empty date
	EndIf;
	
EndProcedure

#EndIf

#EndRegion
