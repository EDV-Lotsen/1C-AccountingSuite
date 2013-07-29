
Function inout(jsonin, object_code)
	
	ProductCodeJSON = InternetConnectionClientServer.DecodeJSON(object_code);
	ProductCode = ProductCodeJSON.object_code;
	ProductCode = Number(ProductCode);
	
	ParsedJSON = InternetConnectionClientServer.DecodeJSON(jsonin);
	
	UpdatedProduct = Catalogs.Products.FindByAttribute("api_code", ProductCode);
	UpdatedProductObj = UpdatedProduct.GetObject();
	UpdatedProductObj.Code = ParsedJSON.item_code;
	UpdatedProductObj.Description = ParsedJSON.item_description;
	UpdatedProductObj.Write();
	
	Output = New Map();
	Output.Insert("status", "success");
	
	jsonout = InternetConnectionClientServer.EncodeJSON(Output,,True,True);                    
	
	Return jsonout;

EndFunction
