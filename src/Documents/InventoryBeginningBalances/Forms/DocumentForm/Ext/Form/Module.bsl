
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	//Title = "Inv. beg. bal. " + Object.Number;
	
	If GeneralFunctionsReusable.FunctionalOptionValue("MultiLocation") Then
	Else
		If Object.Location.IsEmpty() Then			
			Object.Location = Catalogs.Locations.MainWarehouse;
		EndIf;
	EndIf;

	// AdditionalReportsAndDataProcessors
	AdditionalReportsAndDataProcessors.OnCreateAtServer(ThisForm);
	// End AdditionalReportsAndDataProcessors
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	If Object.Product.Type = Enums.InventoryTypes.NonInventory Then
		
		Message = New UserMessage();
		Message.Text=NStr("en='Select an inventory item';de='Wählen Sie einen Artikel, der Lagerbeständen zugeordnet wird'");
		Message.Message();
		Cancel = True;
		Return;
		
	EndIf;

EndProcedure
