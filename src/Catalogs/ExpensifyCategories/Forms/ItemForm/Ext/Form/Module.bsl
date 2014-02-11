
&AtClient
Procedure AccountOnChange(Item)
	
	Object.AccountDescription = CommonUse.GetAttributeValue
		(Object.Account, "Description");

EndProcedure
