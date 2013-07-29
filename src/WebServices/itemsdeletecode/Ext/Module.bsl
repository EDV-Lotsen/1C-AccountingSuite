
Function inout(jsonin)
	
	ParsedJSON = InternetConnectionClientServer.DecodeJSON(jsonin);
	ProductCode = ParsedJSON.object_code;
	ProductCode = Number(ProductCode);
	
	Product = Catalogs.Products.FindByAttribute("api_code", ProductCode);
	
	ProductObj = Product.GetObject();
	ProductObj.DeletionMark = True;
	
	Output = New Map();	
	
	Try
		ProductObj.Write();
		Output.Insert("status", "success");
	Except
		//ErrorMessage = DetailErrorDescription(ErrorInfo());
		Output.Insert("error", "item can not be deleted");
	EndTry;
	
	jsonout = InternetConnectionClientServer.EncodeJSON(Output,,True,True);                    
	
	Return jsonout;

EndFunction
