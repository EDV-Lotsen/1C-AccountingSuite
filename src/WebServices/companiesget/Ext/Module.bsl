
Function inout(jsonin)
		
	Query = New Query("SELECT
	                  |	Companies.Code,
	                  |	Companies.Description
	                  |FROM
	                  |	Catalog.Companies AS Companies
	                  |WHERE
	                  |	Companies.Customer = TRUE");
	Result = Query.Execute().Choose();
	
	Companies = New Array();
	
	While Result.Next() Do
		
		Company = New Map();
		Company.Insert("company_code", Result.Code);
		Company.Insert("company_name", Result.Description);
		Company.Insert("company_type", "customer");
		
		Companies.Add(Company);
		
	EndDo;
	
	CompanyList = New Map();
	CompanyList.Insert("companies", Companies);
	
	jsonout = InternetConnectionClientServer.EncodeJSON(CompanyList,,True,True);                    
	
	Return jsonout;

EndFunction
