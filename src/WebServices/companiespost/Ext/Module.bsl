
Function inout(jsonin)
		
	ParsedJSON = InternetConnectionClientServer.DecodeJSON(jsonin);
		
	NewCompany = Catalogs.Companies.CreateItem();
	
	NewCompany.Description = ParsedJSON.company_name;
	NewCompany.Customer = True;
	NewCompany.DefaultCurrency = Constants.DefaultCurrency.Get();
	NewCompany.Terms = Catalogs.PaymentTerms.Net30;

	NewCompany.Write();
	
	DataAddresses = ParsedJSON.lines.addresses;
	
	ArrayLines = DataAddresses.Count();
	For i = 0 To ArrayLines -1 Do
		
		AddressLine = Catalogs.Addresses.CreateItem();
		AddressLine.Owner = NewCompany.Ref;

		Try
			AddressLine.Description = DataAddresses[i].address_id;
		Except
			AddressLine.Description = "Primary";
		EndTry;
		
		Try
			FirstName = DataAddresses[i].first_name;
			AddressLine.FirstName = FirstName;
		Except
		EndTry;
		
		Try
			MiddleName = DataAddresses[i].middle_name;
			AddressLine.MiddleName = MiddleName;
		Except
		EndTry;
		
		Try
			LastName = DataAddresses[i].last_name;
			AddressLine.LastName = LastName;
		Except
		EndTry;
			
		Try
			Phone = DataAddresses[i].phone;
			AddressLine.Phone = Phone;
		Except
		EndTry;
		
		Try
			Email = DataAddresses[i].email;
			AddressLine.Email = Email;
		Except
		EndTry;
		
		Try
			AddressLine1 = DataAddresses[i].address_line1;
			AddressLine.AddressLine1 = AddressLine1;
		Except
		EndTry;
		
		Try
			AddressLine2 = DataAddresses[i].address_line2;
			AddressLine.AddressLine2 = AddressLine2;
		Except
		EndTry;
		
		Try
			City = DataAddresses[i].city;
			AddressLine.City = City;
		Except
		EndTry;

		Try
			State = DataAddresses[i].state;
			AddressLine.State = Catalogs.States.FindByCode(State);
		Except
		EndTry;
		
		Try
			Country = DataAddresses[i].country;
			AddressLine.Country = Catalogs.Countries.FindByCode(Country);
		Except
		EndTry;
		
		Try
			ZIP = DataAddresses[i].zip;
			AddressLine.ZIP = ZIP;
		Except
		EndTry;
		
		Try
			DefaultBilling = DataAddresses[i].default_billing;
			AddressLine.DefaultBilling = DefaultBilling;
		Except
		EndTry;	
		
		Try
			DefaultShipping = DataAddresses[i].default_shipping;
			AddressLine.DefaultShipping = DefaultShipping;
		Except
		EndTry;
		
		AddressLine.Write();
		
	EndDo;
	
	///
	
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
	Query.SetParameter("Company", NewCompany.Ref);
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
		Address.Insert("state", Result.State.Code);
		Address.Insert("zip", Result.ZIP);
		Address.Insert("country", Result.Country.Description);
		Address.Insert("default_billing", Result.DefaultBilling);
		Address.Insert("default_shipping", Result.DefaultShipping);
		
		Addresses.Add(Address);
		
	EndDo;
	
	DataAddresses = New Map();
	DataAddresses.Insert("addresses", Addresses);
	
	CompanyData = New Map();
	CompanyData.Insert("company_name", NewCompany.Description);
	CompanyData.Insert("company_code", NewCompany.Code);
	CompanyData.Insert("company_type", "customer");
	CompanyData.Insert("lines", DataAddresses);
	
	jsonout = InternetConnectionClientServer.EncodeJSON(CompanyData,,True,True);                    
	
	Return jsonout;
	
EndFunction
