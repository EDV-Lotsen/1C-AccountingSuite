
Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then // Skip some check ups.
		Return;
	EndIf;
	  
	If Not Catalogs.Addresses.CheckDuplicateByAttribute(Ref, Owner, "Description", Description) Then
		Message("The address ID already exists.");
		Cancel = True;  
	EndIf;
	
	If DefaultBilling And Not Catalogs.Addresses.CheckDuplicateByAttribute(Ref, Owner, "DefaultBilling", True) Then
		Message("Another address is already set as the default billing address.");
		Cancel = True;  
	EndIf;
	
	If DefaultShipping And Not Catalogs.Addresses.CheckDuplicateByAttribute(Ref, Owner, "DefaultShipping", True) Then
		Message("Another address is already set as the default shipping address.");
		Cancel = True;  
	EndIf;
	
	If DefaultRemitTo And Not Catalogs.Addresses.CheckDuplicateByAttribute(Ref, Owner, "DefaultRemitTo", True) Then
		Message("Another address is already set as the default ""remit to"" address.");
		Cancel = True;  
	EndIf;
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	// Remove default flags, because there cannot be two addresses with them.
	ThisObject.DefaultBilling  = False;
	ThisObject.DefaultShipping = False;
	ThisObject.DefaultRemitTo  = False;
	
EndProcedure
