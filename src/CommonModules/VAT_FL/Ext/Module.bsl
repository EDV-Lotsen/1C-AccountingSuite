//////////////////////////////////////////////////////////////////////////////// 
// THIS MODULE CONTAINS FUNCTIONS AND PROCEDURES USED BY
// THE VAT LOCALIZATION FUNCTIONALITY
// 


// Returns a VAT amount for a document line.
//
// Parameters:
// Number.
// Catalog.VATCode.
// String - "Purchase" or "Sales".
//
// Returned value:
// Number.
//
Function VATLine(LineTotal, VATCode, Direction, PriceIncludesVAT) Export
	
	VATRate = 0;
	If Direction = "Sales" AND PriceIncludesVAT = True Then
		VATRate = VATCode.SalesInclRate;
	ElsIf Direction = "Sales" AND PriceIncludesVAT = False Then
		VATRate = VATCode.SalesExclRate;
	ElsIf Direction = "Purchase" AND PriceIncludesVAT = True Then
		VATRate = VATCode.PurchaseInclRate;
	ElsIf Direction = "Purchase" AND PriceIncludesVAT = False Then
		VATRate = VATCode.PurchaseExclRate;
	EndIf;
	
	VATAmount = LineTotal * VATRate / 100;		
    Return VATAmount;	
	
EndFunction


Function VATAccount(VATCode, Direction) Export
	
	If Direction = "Sales" Then
		Return VATCode.SalesAccount;
	ElsIf Direction = "Purchase" Then
		Return VATCode.PurchaseAccount;
	EndIf;
	
EndFunction


