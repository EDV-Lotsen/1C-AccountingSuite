
Function inout(jsonin)
	
	ParsedJSON = InternetConnectionClientServer.DecodeJSON(jsonin);

	CompanyCode = ParsedJSON.object_code;
	
	Company = Catalogs.Companies.FindByCode(CompanyCode);
	
	CompanyObj = Company.GetObject();
	CompanyObj.DeletionMark = True;
	
	Output = New Map();	
	
	Try
		CompanyObj.Write();
		Output.Insert("status", "success");
	Except
		//ErrorMessage = DetailErrorDescription(ErrorInfo());
		Output.Insert("error", "company can not be deleted");
	EndTry;
	
	jsonout = InternetConnectionClientServer.EncodeJSON(Output,,True,True);                    
	
	Return jsonout;

EndFunction
