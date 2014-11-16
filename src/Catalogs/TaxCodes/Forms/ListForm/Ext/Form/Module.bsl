
&AtClient
Procedure AddAvataxSystemTaxCode(Command)
	
	OpenForm("Catalog.TaxCodesPredefined.ChoiceForm", New Structure("ChoiceMode, CloseOnChoice", True, False), ThisForm,,,,, FormWindowOpeningMode.LockOwnerWindow); 
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(SelectedValue, ChoiceSource)
	
	If AddNewTaxCode(SelectedValue) Then
		NotifyChanged(Type("CatalogRef.TaxCodes"));
		ShowUserNotification("New AvaTax system tax code was added successfully." ,, SelectedValue);
	EndIf;	
	
EndProcedure

&AtServer
Function AddNewTaxCode(SelectedValue)
	
	return AvataxServer.AddNewTaxCode(SelectedValue);
	
EndFunction



