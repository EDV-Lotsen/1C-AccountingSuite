
Function inout(jsonin, object_code)
	
	CompanyCodeJSON = InternetConnectionClientServer.DecodeJSON(object_code);
	CompanyCode = CompanyCodeJSON.object_code;
	
	ParsedJSON = InternetConnectionClientServer.DecodeJSON(jsonin);
	
	UpdatedCompany = Catalogs.Companies.FindByCode(CompanyCode);
	UpdatedCompanyObj = UpdatedCompany.GetObject();
	UpdatedCompanyObj.Description = ParsedJSON.company_name;
	UpdatedCompanyObj.Write();
	
	Output = New Map();
	Output.Insert("status", "success");
	
	jsonout = InternetConnectionClientServer.EncodeJSON(Output,,True,True);                    
	
	Return jsonout;

EndFunction
