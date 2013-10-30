
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Items.QtyAfter.EditFormat = "NFD=" + Constants.QtyPrecision.Get();
	Items.QtyAfter.Format = "NFD=" + Constants.QtyPrecision.Get();
	Items.QtyBefore.EditFormat = "NFD=" + Constants.QtyPrecision.Get();
	Items.QtyBefore.Format = "NFD=" + Constants.QtyPrecision.Get();
	Items.Quantity.EditFormat = "NFD=" + Constants.QtyPrecision.Get();
	Items.Quantity.Format = "NFD=" + Constants.QtyPrecision.Get();
	
	//Title = "Inv. beg. bal. " + Object.Number;
	
	If GeneralFunctionsReusable.FunctionalOptionValue("MultiLocation") Then
	Else
		If Object.Location.IsEmpty() Then			
			Object.Location = Catalogs.Locations.MainWarehouse;
		EndIf;
	EndIf;
	
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

&AtClient
Procedure ProductOnChange(Item)
	RecalcForm();
EndProcedure

&AtClient
Procedure LocationOnChange(Item)
	RecalcForm();
EndProcedure

Function CalculateQty(Product, Location)
	
	Query = New Query("SELECT
	                  |	InventoryJrnlBalance.QtyBalance
	                  |FROM
	                  |	AccumulationRegister.InventoryJrnl.Balance AS InventoryJrnlBalance
	                  |WHERE
	                  |	InventoryJrnlBalance.Product = &Product
	                  |	AND InventoryJrnlBalance.Location = &Location");
					  
	Query.Parameters.Insert("Product", Product);
	Query.Parameters.Insert("Location", Location);

	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Return 0;	
	Else
		DataSet = QueryResult.Unload();
		Return Dataset[0][0];
	EndIf;					  
					  
EndFunction

&AtClient
Procedure QuantityOnChange(Item)
	RecalcForm();
EndProcedure

&AtClient
Procedure RecalcForm()
	
	Balance = CalculateQty(Object.Product, Object.Location);
	QtyBefore = Balance;
	QtyAfter = Balance + Object.Quantity;
	
EndProcedure
