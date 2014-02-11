
Function inout(jsonin, product_id)
	
	NewProduct = Catalogs.Products.CreateItem();
	
	item_type = "inventory";
	NewProduct.CF5String = product_id;
	NewProduct.Code = jsonin;
	NewProduct.Description = jsonin;
	
	Try
		If item_type = "inventory" Then
			NewProduct.Type = Enums.InventoryTypes.Inventory;
			NewProduct.CostingMethod = Enums.InventoryCosting.WeightedAverage;
			NewProduct.InventoryOrExpenseAccount = Constants.InventoryAccount.Get();
		ElsIf item_type = "non-inventory" Then
			NewProduct.Type = Enums.InventoryTypes.NonInventory;
			NewProduct.InventoryOrExpenseAccount = Constants.ExpenseAccount.Get();
		Else
			NewProduct.Type = Enums.InventoryTypes.NonInventory;
			NewProduct.InventoryOrExpenseAccount = Constants.ExpenseAccount.Get();
		EndIf;
	Except
		NewProduct.Type = Enums.InventoryTypes.NonInventory;
	EndTry;
	
	NewProduct.IncomeAccount = Constants.IncomeAccount.Get();
	
	
	//Try
	//	If ParsedJSON.item_type = "inventory" Then
	//		NewProduct.COGSAccount = Constants.COGSAccount.Get();
	//	Else
	//	EndIf;
	//Except
	//EndTry;
	//NewProduct.PurchaseVATCode = Constants.DefaultPurchaseVAT.Get();
	//NewProduct.SalesVATCode = Constants.DefaultSalesVAT.Get();
	//NewProduct.api_code = GeneralFunctions.NextProductNumber();

	NewProduct.Write();

	Return "success";

EndFunction
