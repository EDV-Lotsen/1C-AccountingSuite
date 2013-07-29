
Function inout(jsonin)
	
	ParsedJSON = InternetConnectionClientServer.DecodeJSON(jsonin);
	
	Company = Catalogs.Companies.FindByCode(ParsedJSON.object_code);
	
	Query = New Query("SELECT
	                  |	Addresses.Description,
	                  |	Addresses.FirstName,
	                  |	Addresses.LastName,
	                  |	Addresses.DefaultBilling,
	                  |	Addresses.DefaultShipping,
	                  |	Addresses.Code,
	                  |	Addresses.MiddleName,
	                  |	Addresses.Phone,
	                  |	Addresses.Email,
	                  |	Addresses.AddressLine1,
	                  |	Addresses.AddressLine2,
	                  |	Addresses.City,
	                  |	Addresses.State,
	                  |	Addresses.Country,
	                  |	Addresses.ZIP
	                  |FROM
	                  |	Catalog.Addresses AS Addresses
	                  |WHERE
	                  |	Addresses.Owner = &Company");
	Query.SetParameter("Company", Company);
	Result = Query.Execute().Choose();
	
	Addresses = New Array();
	
	While Result.Next() Do
		
		Address = New Map();
		Address.Insert("address_id", Result.Description);
		Address.Insert("address_code", Result.Code);
		Address.Insert("first_name", Result.FirstName);
		Address.Insert("middle_name", Result.MiddleName);
		Address.Insert("last_name", Result.LastName);
		Address.Insert("phone", Result.Phone);
		Address.Insert("email", Result.Email);
		Address.Insert("address_line1", Result.AddressLine1);
		Address.Insert("address_line2", Result.AddressLine2);
		Address.Insert("city", Result.City);
		Address.Insert("zip", Result.ZIP);
		Address.Insert("state", Result.State.Code);
		Address.Insert("country", Result.Country.Description);
		Address.Insert("default_billing", Result.DefaultBilling);
		Address.Insert("default_shipping", Result.DefaultShipping);
		
		Addresses.Add(Address);
		
	EndDo;
	
	DataAddresses = New Map();
	DataAddresses.Insert("addresses", Addresses);
	
	CompanyData = New Map();
	CompanyData.Insert("company_name", Company.Description);
	CompanyData.Insert("company_code", Company.Code);
	CompanyData.Insert("company_type", "customer");
	CompanyData.Insert("lines", DataAddresses);
	
	jsonout = InternetConnectionClientServer.EncodeJSON(CompanyData,,True,True);                    
	
	Return jsonout;

EndFunction
