
Function inout(jsonin)
		
	ParsedJSON = InternetConnectionClientServer.DecodeJSON(jsonin);
		
	NewProduct = Catalogs.Products.CreateItem();
	
	NewProduct.Code = ParsedJSON.item_code;
	NewProduct.Description = ParsedJSON.item_description;
	
	Try
		If ParsedJSON.item_type = "inventory" Then
			NewProduct.Type = Enums.InventoryTypes.Inventory;
			NewProduct.CostingMethod = Enums.InventoryCosting.WeightedAverage;
			NewProduct.InventoryOrExpenseAccount = Constants.InventoryAccount.Get();
		ElsIf ParsedJSON.item_type = "non-inventory" Then
			NewProduct.Type = Enums.InventoryTypes.NonInventory;
		Else
			NewProduct.Type = Enums.InventoryTypes.NonInventory;
		EndIf;
	Except
		NewProduct.Type = Enums.InventoryTypes.NonInventory;
	EndTry;
	
	NewProduct.IncomeAccount = Constants.IncomeAccount.Get();
	
	
	Try
		If ParsedJSON.item_type = "inventory" Then
			NewProduct.COGSAccount = Constants.COGSAccount.Get();
		Else
		EndIf;
	Except
	EndTry;
	NewProduct.PurchaseVATCode = Constants.DefaultPurchaseVAT.Get();
	NewProduct.SalesVATCode = Constants.DefaultSalesVAT.Get();
	NewProduct.api_code = GeneralFunctions.NextProductNumber();

	NewProduct.Write();
		
	///
		
	ProductData = New Map();
	ProductData.Insert("item_code", NewProduct.Code);
	ProductData.Insert("api_code", GeneralFunctions.LeadingZeros(NewProduct.api_code));
	ProductData.Insert("item_description", NewProduct.Description);
	If NewProduct.Type = Enums.InventoryTypes.Inventory Then
		ProductData.Insert("item_type", "inventory");
	ElsIf NewProduct.Type = Enums.InventoryTypes.NonInventory Then
		ProductData.Insert("item_type", "non-inventory");	
	EndIf;
	
	jsonout = InternetConnectionClientServer.EncodeJSON(ProductData,,True,True);	                    
	
	Return jsonout;
	
EndFunction

