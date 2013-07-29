
Function inout(jsonin)
	
	ParsedJSON = InternetConnectionClientServer.DecodeJSON(jsonin);
	
	Object_code = ParsedJSON.object_code;
	Object_code = Number(Object_code);
	Product = Catalogs.Products.FindByAttribute("api_code", Object_code);
	
	ProductData = New Map();
	ProductData.Insert("item_code", Product.Code);
	ProductData.Insert("api_code", GeneralFunctions.LeadingZeros(Product.api_code));
	ProductData.Insert("item_description", Product.Description);
	If Product.Type = Enums.InventoryTypes.Inventory Then
		ProductData.Insert("item_type", "inventory");
	ElsIf Product.Type = Enums.InventoryTypes.NonInventory Then
		ProductData.Insert("item_type", "non-inventory");	
	EndIf;
	
	jsonout = InternetConnectionClientServer.EncodeJSON(ProductData,,True,True);                    
	
	Return jsonout;

EndFunction
