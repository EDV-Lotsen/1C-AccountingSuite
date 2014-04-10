
Procedure BeforeDelete(Cancel)
	// If the current SalesTaxRate is a component of the combined tax rate then
	// refresh the rate of the combined sales tax rate item.
	If ValueIsFilled(ThisObject.Parent) Then
		ParentObject = ThisObject.Parent.GetObject();
		ParentObject.Rate = ParentObject.Rate - ThisObject.Rate;
		ParentObject.Write();
	EndIf;
EndProcedure
