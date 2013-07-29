
Function inout(jsonin)
		
	Query = New Query("SELECT
	                  |	Products.Code,
	                  |	Products.Description,
	                  |	Products.Type,
	                  |	Products.api_code
	                  |FROM
	                  |	Catalog.Products AS Products");
	Result = Query.Execute().Choose();
	
	Products = New Array();
	
	While Result.Next() Do
		
		Product = New Map();
		Product.Insert("item_code", Result.Code);
		Product.Insert("api_code", GeneralFunctions.LeadingZeros(Result.api_code));
		Product.Insert("item_description", Result.Description);
		If Result.Type = Enums.InventoryTypes.Inventory Then
			Product.Insert("item_type", "inventory");
		ElsIf Result.Type = Enums.InventoryTypes.NonInventory Then
			Product.Insert("item_type", "non-inventory");
		EndIf;
		
		Products.Add(Product);
		
	EndDo;
	
	ProductList = New Map();
	ProductList.Insert("items", Products);
	
	jsonout = InternetConnectionClientServer.EncodeJSON(ProductList,,True,True);	                    
	
	Return jsonout;

EndFunction
