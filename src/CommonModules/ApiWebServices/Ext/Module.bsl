Function inoutCompaniesCreate(jsonin) Export
		
	ParsedJSON = InternetConnectionClientServer.DecodeJSON(jsonin);
	
	alreadyExists = True;
	
	Try
		Query = New Query("SELECT
		                  |	Companies.Ref
		                  |FROM
		                  |	Catalog.Companies AS Companies
		                  |WHERE
		                  |	Companies.Description = &desc");
		Query.SetParameter("desc", ParsedJSON.company_name);
		QueryResult = Query.Execute();
	
		If QueryResult.IsEmpty() Then
			alreadyExists = False;
		EndIf;
	Except
		errorMessage = New Map();
		strMessage = " [company_name] : This is a required field ";
		errorMessage.Insert("message", strMessage);
		errorMessage.Insert("status", "error"); 
		errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
		return errorJSON;
	EndTry;
	
	If alreadyExists = False Then
		
		NewCompany = Catalogs.Companies.CreateItem();
	
		NewCompany.Description = ParsedJSON.company_name;
		
		Try companyCode = ParsedJSON.company_code Except companyCode = Undefined EndTry;
		If NOT companyCode = Undefined Then
			errorMessage = New Map();
			strMessage = " [company_code] : Cannot manually specify this. Accounting Suite automatically generates it ";
			errorMessage.Insert("message", strMessage);
			errorMessage.Insert("status", "error"); 
			errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
			return errorJSON;
		EndIf;
		
		Try companyType = ParsedJSON.company_type Except companyType = Undefined EndTry;
		If NOT companyType = Undefined Then
			If companyType = "customer" Then
				NewCompany.Customer = True;
			ElsIf companyType = "vendor" Then
				NewCompany.Vendor = True;
			ElsIf companyType = "customer+vendor" Then
				NewCompany.Customer = True;
				NewCompany.Vendor = True;
			Else
				errorMessage = New Map();
				strMessage = " [company_type] : Please enter customer, vendor, or customer+vendor ";
				errorMessage.Insert("message", strMessage);
				errorMessage.Insert("status", "error"); 
				errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
				return errorJSON;
			EndIf;
		Else
			errorMessage = New Map();
			strMessage = " [company_type] : This is a required field ";
			errorMessage.Insert("message", strMessage);
			errorMessage.Insert("status", "error"); 
			errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
			return errorJSON;
		EndIf;
		//NewCompany.Customer = True;
		
		NewCompany.DefaultCurrency = Constants.DefaultCurrency.Get();
		NewCompany.Terms = Catalogs.PaymentTerms.Net30;
		
		Try NewCompany.Website = ParsedJSON.website; Except EndTry;
		//Try NewCompany.PriceLevel = ParsedJSON.price_level; Except EndTry;
		Try NewCompany.Notes  = ParsedJSON.notes; Except EndTry;
		
		Try pl = ParsedJSON.price_level Except pl = Undefined EndTry;
		If NOT pl = Undefined Then
			plQuery = New Query("SELECT
			                    |	PriceLevels.Ref
			                    |FROM
			                    |	Catalog.PriceLevels AS PriceLevels
			                    |WHERE
			                    |	PriceLevels.Description = &plCode");
			plQuery.SetParameter("plCode", pl );
			plQueryResult = plQuery.Execute();
			If plQueryResult.IsEmpty() Then
				errorMessage = New Map();
				strMessage = " [price_level] : This does not exist. You must create the price level first. ";
				errorMessage.Insert("message", strMessage);
				errorMessage.Insert("status", "error"); 
				errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
				return errorJSON;
			EndIf;
			pl_result = plQueryResult.Unload();
			NewCompany.PriceLevel = pl_result[0].Ref;
		EndIf;

		
		Try NewCompany.CF1String = ParsedJSON.cf1_string; Except EndTry;
		Try NewCompany.CF2String = ParsedJSON.cf2_string; Except EndTry;
		Try NewCompany.CF3String = ParsedJSON.cf3_string; Except EndTry;
		Try NewCompany.CF4String = ParsedJSON.cf4_string; Except EndTry;
		Try NewCompany.CF5String = ParsedJSON.cf5_string; Except EndTry;
		Try NewCompany.CF1Num = ParsedJSON.cf1_num; Except EndTry;
		Try NewCompany.CF2Num = ParsedJSON.cf2_num; Except EndTry;
		Try NewCompany.CF3Num = ParsedJSON.cf3_num; Except EndTry;
		Try NewCompany.CF4Num = ParsedJSON.cf4_num; Except EndTry;
		Try NewCompany.CF5Num = ParsedJSON.cf5_num; Except EndTry;
		
		Try
		
			DataAddresses = ParsedJSON.lines.addresses;
			
			ArrayLines = DataAddresses.Count();
			
			For i = 0 To ArrayLines -1 Do
				Try
					If i > 0 Then
						For j = 0 to i-1 Do
							If DataAddresses[j].address_id = DataAddresses[i].address_id Then
								errorMessage = New Map();
								strMessage = " [address_id(" + (i+1) +  ")] : Address ID must be unique. Cannot enter identical address IDs. ";
								errorMessage.Insert("message", strMessage);
								errorMessage.Insert("status", "error"); 
								errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
								return errorJSON;
							EndIf;
						EndDo;
					EndIf;
				Except
				EndTry;
				
				Try
					If i > 0 Then
						For j = 0 to i-1 Do
							If DataAddresses[i].default_billing = TRUE AND DataAddresses[j].default_billing = TRUE Then
								errorMessage = New Map();
								strMessage = " [default_billing(" + (i+1) +  ")] : Cannot have multiple addresses be set to default billing.";
								errorMessage.Insert("message", strMessage);
								errorMessage.Insert("status", "error"); 
								errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
								return errorJSON;
							EndIf;
						EndDo;
					EndIf;
				Except
				EndTry;	
				
				Try
					If i > 0 Then
						For j = 0 to i-1 Do
							If DataAddresses[i].default_shipping = TRUE AND DataAddresses[j].default_shipping = TRUE Then
								errorMessage = New Map();
								strMessage = " [default_shipping(" + (i+1) +  ")] : Cannot have multiple addresses be set to default shipping.";
								errorMessage.Insert("message", strMessage);
								errorMessage.Insert("status", "error"); 
								errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
								return errorJSON;
							EndIf;
						EndDo;
					EndIf;
				Except
				EndTry;
				
			EndDo;
			
		Except
		EndTry;
		
		NewCompany.Write();
	
	Else
		
		CompanyData = New Map();
		CompanyData.Insert("message", " [company_name] : The company already exists");
		CompanyData.Insert("status", "error");
		existingCompany = QueryResult.Unload();
		CompanyData.Insert("api_code", String(existingCompany[0].Ref.UUID()));
		
		jsonout = InternetConnectionClientServer.EncodeJSON(CompanyData);
		return jsonout;
		
	EndIf;
	
	Try
	
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
				If i = 0 Then
					AddressLine.DefaultBilling = True;
				Else
					Try DefaultBilling = DataAddresses[i].default_billing; 
					AddressLine.DefaultBilling = DefaultBilling; Except EndTry;
					If DefaultBilling = True Then
						addrQuery = New Query("SELECT
						                      |	Addresses.Ref
						                      |FROM
						                      |	Catalog.Addresses AS Addresses
						                      |WHERE
						                      |	Addresses.Owner = &Ref");
						addrQuery.SetParameter("Ref", NewCompany.Ref);
						allAddr = addrQuery.Execute().Unload();
						For each addr in allAddr Do
							addrObj = addr.Ref.GetObject();
							addrObj.DefaultBilling = False;
							addrObj.Write();
						EndDo;
					EndIf;
				EndIf;
			Except
			EndTry;	
			
			Try
				If i = 0 Then
					AddressLine.DefaultShipping = True;
				Else
					Try DefaultShipping = DataAddresses[i].default_shipping; 
					AddressLine.DefaultShipping = DefaultShipping; Except EndTry;
					If DefaultShipping = True Then
						addrQuery = New Query("SELECT
						                      |	Addresses.Ref
						                      |FROM
						                      |	Catalog.Addresses AS Addresses
						                      |WHERE
						                      |	Addresses.Owner = &Ref");
						addrQuery.SetParameter("Ref", NewCompany.Ref);
						allAddr = addrQuery.Execute().Unload();
						For each addr in allAddr Do
							addrObj = addr.Ref.GetObject();
							addrObj.DefaultShipping = False;
							addrObj.Write();
						EndDo;
					EndIf;
				EndIf;
				
			Except
			EndTry;
						
			AddressLine.Write();
			
		EndDo;

	Except
		
			AddressLine = Catalogs.Addresses.CreateItem();
			AddressLine.Owner = NewCompany.Ref;
			AddressLine.DefaultBilling = True;
			AddressLine.DefaultShipping = True;
			AddressLine.Description = "Primary";
			AddressLine.Write();

		
	EndTry;
			
	Return InternetConnectionClientServer.EncodeJSON(GeneralFunctions.ReturnCompanyObjectMap(NewCompany));
	
	
EndFunction

Function inoutCompaniesUpdate(jsonin, object_code) Export
	
	CompanyCodeJSON = InternetConnectionClientServer.DecodeJSON(object_code);
	//api_code = CompanyCodeJSON.object_code;
	Try api_code = CompanyCodeJSON.object_code Except api_code = Undefined EndTry;
	If api_code = Undefined OR api_code = "" Then
		errorMessage = New Map();
		strMessage = " [api_code] : Missing the company ID# ";
		errorMessage.Insert("message", strMessage);
		errorMessage.Insert("status", "error"); 
		errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
		return errorJSON;
	EndIf;
	
	ParsedJSON = InternetConnectionClientServer.DecodeJSON(jsonin);
	
	//UpdatedCompany = Catalogs.Companies.FindByCode(CompanyCode);
	//UpdatedCompany = Catalogs.Companies.GetRef(New UUID(api_code));
	Try	
		UpdatedCompany = Catalogs.Companies.getref(New UUID(api_code));
	Except
		errorMessage = New Map();
		strMessage = " [api_code] : The company does not exist. Double check that the ID# is correct. ";
		errorMessage.Insert("message", strMessage);
		errorMessage.Insert("status", "error"); 
		errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
		return errorJSON;
	EndTry;
	
	companyQuery = New Query("SELECT
	                         |	Companies.Ref AS Ref1
	                         |FROM
	                         |	Catalog.Companies AS Companies
	                         |WHERE
	                         |	Companies.Ref = &com");
	companyQuery.SetParameter("com", UpdatedCompany);
	companyresult = companyQuery.Execute();
	If companyresult.IsEmpty() Then
			errorMessage = New Map();
			strMessage = " [api_code] : The item does not exist. Double check that the ID# is correct. ";
			errorMessage.Insert("message", strMessage);
			errorMessage.Insert("status", "error"); 
			errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
			return errorJSON;
	EndIf;
		
	UpdatedCompanyObj = UpdatedCompany.GetObject();
	
	Try companyCode = ParsedJSON.company_code Except companyCode = Undefined EndTry;
		If NOT companyCode = Undefined Then
			errorMessage = New Map();
			strMessage = " [company_code] : Cannot manually specify this. Accounting Suite automatically generates it ";
			errorMessage.Insert("message", strMessage);
			errorMessage.Insert("status", "error"); 
			errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
			return errorJSON;
		EndIf;
		
	////////////////////////////////////
	Try
        companyName = ParsedJSON.company_name;
		Query = New Query("SELECT
		                  |	Companies.Ref
		                  |FROM
		                  |	Catalog.Companies AS Companies
		                  |WHERE
		                  |	Companies.Description = &desc");
		Query.SetParameter("desc", companyName);
		QueryResult = Query.Execute();
	
		If QueryResult.IsEmpty() Then
			UpdatedCompanyObj.Description = companyName;
		Else
			CompanyData = New Map();
			CompanyData.Insert("message", " [company_name] : The company already exists");
			CompanyData.Insert("status", "error");
			existingCompany = QueryResult.Unload();
			CompanyData.Insert("api_code", String(existingCompany[0].Ref.UUID()));
		
			jsonout = InternetConnectionClientServer.EncodeJSON(CompanyData);
			return jsonout;
		EndIf;
	Except
	EndTry;
	/////////////////
	
	//////////////
	Try
		companyType = ParsedJSON.company_type;
	Except
		companyType = Undefined;
	EndTry;
	If NOT companyType = Undefined Then
		If companyType = "customer+vendor" Then
			UpdatedCompanyObj.Customer = TRUE;
			UpdatedCompanyObj.Vendor = TRUE;
		ElsIf companyType = "vendor" AND UpdatedCompanyObj.Customer = TRUE Then
			UpdatedCompanyObj.Vendor = TRUE;
		ElsIf companyType = "customer" AND UpdatedCompanyObj.Vendor = TRUE Then
			UpdatedCompanyObj.Customer = TRUE;
		Else
			//CompanyData = New Map();
			//CompanyData.Insert("message", " [company_type] : This cannot be changed once the company is created. Only allowed to add a type");
			//CompanyData.Insert("status", "error");
			//jsonout = InternetConnectionClientServer.EncodeJSON(CompanyData);
			//return jsonout;
		EndIf;
	EndIf;
	//////////////////	
	
	Try UpdatedCompanyObj.Website = ParsedJSON.website; Except EndTry;
	
	Try 
		PriceLevel = catalogs.PriceLevels.FindByDescription(ParsedJSON.price_level);
	Except 
	EndTry;
	Try 
	If NOT PriceLevel.isEmpty() Then
		UpdatedCompanyObj.PriceLevel = PriceLevel;
	Else
		errorMessage = New Map();
		strMessage = " [price_level] : The price level does not exist. Must create it first. ";
		errorMessage.Insert("message", strMessage);
		errorMessage.Insert("status", "error"); 
		errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
		return errorJSON;
	EndIf;
	Except
	Endtry;
	
	//should check if its num or string, maybe disallow writing to both for same CF
	Try UpdatedCompanyObj.Notes = ParsedJSON.notes; Except EndTry;
	Try UpdatedCompanyObj.CF1String = ParsedJSON.cf1_string; Except EndTry;
	Try UpdatedCompanyObj.CF2String = ParsedJSON.cf2_string; Except EndTry;
	Try UpdatedCompanyObj.CF3String = ParsedJSON.cf3_string; Except EndTry;
	Try UpdatedCompanyObj.CF4String = ParsedJSON.cf4_string; Except EndTry;
	Try UpdatedCompanyObj.CF5String = ParsedJSON.cf5_string; Except EndTry;

	Try UpdatedCompanyObj.CF1Num = ParsedJSON.cf1_num; Except EndTry;
	Try UpdatedCompanyObj.CF2Num = ParsedJSON.cf2_num; Except EndTry;
	Try UpdatedCompanyObj.CF3Num = ParsedJSON.cf3_num; Except EndTry;
	Try UpdatedCompanyObj.CF4Num = ParsedJSON.cf4_num; Except EndTry;
	Try UpdatedCompanyObj.CF5Num = ParsedJSON.cf5_num; Except EndTry;
		
	Try
		
			DataAddresses = ParsedJSON.lines.addresses;
			
			ArrayLines = DataAddresses.Count();
			
			For i = 0 To ArrayLines -1 Do
				Try
					If i > 0 Then
						For j = 0 to i-1 Do
							If DataAddresses[j].address_id = DataAddresses[i].address_id Then
								errorMessage = New Map();
								strMessage = " [address_id(" + (i+1) +  ")] : Address ID must be unique. Cannot enter identical address IDs. ";
								errorMessage.Insert("message", strMessage);
								errorMessage.Insert("status", "error"); 
								errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
								return errorJSON;
							EndIf;
						EndDo;
					EndIf;
				Except
				EndTry;
				
				Try
					If i > 0 Then
						For j = 0 to i-1 Do
							If DataAddresses[i].default_billing = TRUE AND DataAddresses[j].default_billing = TRUE Then
								errorMessage = New Map();
								strMessage = " [default_billing(" + (i+1) +  ")] : Cannot have multiple addresses be set to default billing.";
								errorMessage.Insert("message", strMessage);
								errorMessage.Insert("status", "error"); 
								errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
								return errorJSON;
							EndIf;
						EndDo;
					EndIf;
				Except
				EndTry;	
				
				Try
					If i > 0 Then
						For j = 0 to i-1 Do
							If DataAddresses[i].default_shipping = TRUE AND DataAddresses[j].default_shipping = TRUE Then
								errorMessage = New Map();
								strMessage = " [default_shipping(" + (i+1) +  ")] : Cannot have multiple addresses be set to default shipping.";
								errorMessage.Insert("message", strMessage);
								errorMessage.Insert("status", "error"); 
								errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
								return errorJSON;
							EndIf;
						EndDo;
					EndIf;
				Except
				EndTry;
				
			EndDo;
			
		Except
		EndTry;



	UpdatedCompanyObj.Write();

	Try
		If ParsedJSON.lines.addresses.count() > 0 Then

			For Each Address In ParsedJSON.lines.addresses Do
				
				Try aac = Address.api_code; Except aac = Undefined; EndTry;
				If NOT aac = Undefined Then
					Try CurAddress = Catalogs.Addresses.GetRef(New UUID(aac));
						//CurAddress = Catalogs.Addresses.GetRef(aac);
						aQuery = New Query("SELECT
						                  |		Addresses.Ref
						                  |FROM
						                  |		Catalog.Addresses AS Addresses
						                  |WHERE
						                  |		Addresses.Ref = &apicode");
						aQuery.SetParameter("apicode", CurAddress);
						aQueryResult = aQuery.Execute();
					Except 
						errorMessage = New Map();
						strMessage = " [address.api_code] : The address does not exist. ";
						errorMessage.Insert("message", strMessage);
						errorMessage.Insert("status", "error"); 
						errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
						return errorJSON;
					EndTry;

					If Not aQueryResult.IsEmpty() Then // <> Catalogs.Addresses.EmptyRef() Then
						CurAddress = Catalogs.Addresses.GetRef(aac);
						AddrObj = CurAddress.GetObject();

						Try  
							desc = Address.address_id;
							AddrObj.Description = desc; 
						Except 
	
						EndTry;
						
						Try AddrObj.FirstName = Address.first_name; Except EndTry;
						Try AddrObj.MiddleName = Address.middle_name; Except EndTry;
						Try AddrObj.LastName = Address.last_name; Except EndTry;
						Try AddrObj.AddressLine1 = Address.address_line1; Except EndTry;
						Try AddrObj.AddressLine2 = Address.address_line2; Except EndTry;
						Try AddrObj.City = Address.city; Except EndTry;
						Try 
							AddrState = Catalogs.States.FindByDescription(Address.state);
							AddrObj.State = AddrState; 
						Except 
						EndTry;
						Try AddrObj.ZIP = Address.zip; Except EndTry;
						Try 
							AddrCountry = Catalogs.Countries.FindByDescription(Address.country);
							AddrObj.Country = AddrCountry; 
						Except 
						EndTry;
						Try AddrObj.Phone = Address.phone; Except EndTry;
						Try AddrObj.Cell = Address.cell; Except EndTry;
						Try AddrObj.Email = Address.email; Except EndTry;
						Try 
							AddrSaleTaxCode = Catalogs.SalesTaxCodes.FindByDescription(Address.sales_tax_code);
							AddrObj.Phone = AddrSaleTaxCode; 
						Except 
						EndTry;
						Try AddrObj.Notes = Address.notes; Except EndTry;
						
						Try
								Try DefaultBilling = Address.default_billing; 
								AddrObj.DefaultBilling = DefaultBilling; Except EndTry;
								If DefaultBilling = True Then
									addrQuery = New Query("SELECT
									                      |	Addresses.Ref
									                      |FROM
									                      |	Catalog.Addresses AS Addresses
									                      |WHERE
									                      |	Addresses.Owner = &Ref
									                      |	AND Addresses.Description <> &Description");
									addrQuery.SetParameter("Ref", UpdatedCompanyObj.Ref);
									CurAddress = Catalogs.Addresses.GetRef(aac);
									thisAddr = CurAddress.GetObject();
									addrQuery.SetParameter("Description", thisAddr.Description);
									allAddr = addrQuery.Execute().Unload();
									For each addr in allAddr Do
										oldAddr = addr.Ref.GetObject();
										oldAddr.DefaultBilling = False;
										oldAddr.Write();
									EndDo;
								EndIf;
						Except
						EndTry;
						
						Try
							Try DefaultShipping = Address.default_shipping; 
								AddrObj.DefaultShipping = DefaultShipping; Except EndTry;
								If DefaultShipping = True Then
									addrQuery = New Query("SELECT
									                      |	Addresses.Ref
									                      |FROM
									                      |	Catalog.Addresses AS Addresses
									                      |WHERE
									                      |	Addresses.Owner = &Ref
									                      |	AND Addresses.Description <> &Description");
									addrQuery.SetParameter("Ref", UpdatedCompanyObj.Ref);
									CurAddress = Catalogs.Addresses.GetRef(aac);
									thisAddr = CurAddress.GetObject();
									addrQuery.SetParameter("Description", thisAddr.Description);
									allAddr = addrQuery.Execute().Unload();
									For each addr in allAddr Do
										oldAddr = addr.Ref.GetObject();
										oldAddr.DefaultShipping = False;
										oldAddr.Write();
									EndDo;
								EndIf;
						Except
						EndTry;

						AddrObj.Write();
					Else
						errorMessage = New Map();
						strMessage = " [address.api_code] : The address does not exist. ";
						errorMessage.Insert("message", strMessage);
						errorMessage.Insert("status", "error"); 
						errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
						return errorJSON;
					EndIf;
				Else
					//add new address
					Try
						AddrObj = Catalogs.Addresses.CreateItem();
						AddrObj.Owner = UpdatedCompanyObj.Ref;
						
						Try AddrObj.Description = Address.address_id; 
						Except 
							errorMessage = New Map();
							strMessage = " [address.address_id] : This is required to create a new address. ";
							strMessage2 = " [address.api_code] : This is required to update an existing address. ";
							errorMessage.Insert("message1", strMessage);
							errorMessage.Insert("message2", strMessage2);
							errorMessage.Insert("status", "error"); 
							errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
							return errorJSON;
						EndTry;
						
						Try AddrObj.FirstName = Address.first_name; Except EndTry;
						Try AddrObj.MiddleName = Address.middle_name; Except EndTry;
						Try AddrObj.LastName = Address.last_name; Except EndTry;
						Try AddrObj.AddressLine1 = Address.address_line1; Except EndTry;
						Try AddrObj.AddressLine2 = Address.address_line2; Except EndTry;
						Try AddrObj.City = Address.city; Except EndTry;
						Try 
							AddrState = Catalogs.States.FindByDescription(Address.state);
							AddrObj.State = AddrState; 
						Except 
						EndTry;
						Try AddrObj.ZIP = Address.zip; Except EndTry;
						Try 
							AddrCountry = Catalogs.Countries.FindByDescription(Address.country);
							AddrObj.Country = AddrCountry; 
						Except 
						EndTry;
						Try AddrObj.Phone = Address.phone; Except EndTry;
						Try AddrObj.Cell = Address.cell; Except EndTry;
						Try AddrObj.Email = Address.email; Except EndTry;
						Try 
							AddrSaleTaxCode = Catalogs.SalesTaxCodes.FindByDescription(Address.sales_tax_code);
							AddrObj.Phone = AddrSaleTaxCode; 
						Except 
						EndTry;
						Try AddrObj.Notes = Address.notes; Except EndTry;
						
						
						Try
								Try DefaultBilling = Address.default_billing; 
								AddrObj.DefaultBilling = DefaultBilling; Except EndTry;
								If DefaultBilling = True Then
									addrQuery = New Query("SELECT
									                      |	Addresses.Ref
									                      |FROM
									                      |	Catalog.Addresses AS Addresses
									                      |WHERE
									                      |	Addresses.Owner = &Ref");
									addrQuery.SetParameter("Ref", UpdatedCompanyObj.Ref);
									allAddr = addrQuery.Execute().Unload();
									For each addr in allAddr Do
										oldAddr = addr.Ref.GetObject();
										oldAddr.DefaultBilling = False;
										oldAddr.Write();
									EndDo;
								EndIf;
						Except
						EndTry;
						
						Try
							Try DefaultShipping = Address.default_shipping; 
								AddrObj.DefaultShipping = DefaultShipping; Except EndTry;
								If DefaultShipping = True Then
									addrQuery = New Query("SELECT
									                      |	Addresses.Ref
									                      |FROM
									                      |	Catalog.Addresses AS Addresses
									                      |WHERE
									                      |	Addresses.Owner = &Ref");
									addrQuery.SetParameter("Ref", UpdatedCompanyObj.Ref);
									allAddr = addrQuery.Execute().Unload();
									For each addr in allAddr Do
										oldAddr = addr.Ref.GetObject();
										oldAddr.DefaultShipping = False;
										oldAddr.Write();
									EndDo;
								EndIf;
						Except
						EndTry;

												

						AddrObj.Write();
					Except
							errorMessage = New Map();
							strMessage = " [address.address_id] : The address id already exists. It must be unique. ";
							errorMessage.Insert("message", strMessage);
							errorMessage.Insert("status", "error"); 
							errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
							return errorJSON;
						
					EndTry;
					
				EndIf;
				
				EndDo;

			EndIf;
	
	Except
		Try
		If ParsedJSON.lines.addresses.count() > 0 Then 	
			errorMessage = New Map();
			strMessage = " [address.address_id] : The address id already exists. It must be unique. ";
			errorMessage.Insert("message", strMessage);
			errorMessage.Insert("status", "error"); 
			errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
			return errorJSON;
		EndIf;
		Except; EndTry;
	EndTry;

	 //UpdatedCompanyObj.Write();

	//Output = New Map();
	//Output.Insert("status", "success");
	
	
	
	
	//jsonout = InternetConnectionClientServer.EncodeJSON(Output);
	jsonout = InternetConnectionClientServer.EncodeJSON(GeneralFunctions.ReturnCompanyObjectMap(UpdatedCompanyObj));

	
	Return jsonout;


EndFunction  

Function inoutCompaniesGet(jsonin) Export

	ParsedJSON = InternetConnectionClientServer.DecodeJSON(jsonin);
	
	//Company = Catalogs.Companies.FindByCode(ParsedJSON.object_code);
	Try
		Company = Catalogs.Companies.GetRef(New UUID(ParsedJSON.object_code));
	Except
		errorMessage = New Map();
		strMessage = " [api_code] : The company does not exist. Double check that the ID# is correct. ";
		errorMessage.Insert("message", strMessage);
		errorMessage.Insert("status", "error"); 
		errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
		return errorJSON;
	EndTry;
	
	companyQuery = New Query("SELECT
							 |	Companies.Ref AS Ref1
							 |FROM
							 |	Catalog.Companies AS Companies
							 |WHERE
							 |	Companies.Ref = &com");
	companyQuery.SetParameter("com", Company);
	companyresult = companyQuery.Execute();
	If companyresult.IsEmpty() Then
			errorMessage = New Map();
			strMessage = " [api_code] : The item does not exist. Double check that the ID# is correct. ";
			errorMessage.Insert("message", strMessage);
			errorMessage.Insert("status", "error"); 
			errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
			return errorJSON;
	EndIf;
	
	//Query = New Query("SELECT
	//				  | Addresses.Ref,
	//				  |	Addresses.Description,
	//				  |	Addresses.FirstName,
	//				  |	Addresses.LastName,
	//				  |	Addresses.Defau,
	//				  |	Addresses.DefaultShipping,
	//				  |	Addresses.Code,
	//				  |	Addresses.MiddleName,
	//				  |	Addresses.Phone,
	//				  |	Addresses.Email,
	//				  |	Addresses.AddressLine1,
	//				  |	Addresses.AddressLine2,
	//				  |	Addresses.City,
	//				  |	Addresses.State,
	//				  |	Addresses.Country,
	//				  |	Addresses.ZIP
	//				  |FROM
	//				  |	Catalog.Addresses AS Addresses
	//				  |WHERE
	//				  |	Addresses.Owner = &Company");
	//Query.SetParameter("Company", Company);
	//Result = Query.Execute().Choose();
	//
	//Addresses = New Array();
	//
	//While Result.Next() Do
	//	
	//	Address = New Map();
	//	Address.Insert("api_code", String(Result.Ref.UUID()));
	//	Address.Insert("address_id", Result.Description);
	//	Address.Insert("address_code", Result.Code);
	//	Address.Insert("first_name", Result.FirstName);
	//	Address.Insert("middle_name", Result.MiddleName);
	//	Address.Insert("last_name", Result.LastName);
	//	Address.Insert("phone", Result.Phone);
	//	Address.Insert("email", Result.Email);
	//	Address.Insert("address_line1", Result.AddressLine1);
	//	Address.Insert("address_line2", Result.AddressLine2);
	//	Address.Insert("city", Result.City);
	//	Address.Insert("zip", Result.ZIP);
	//	Address.Insert("state", Result.State.Code);
	//	Address.Insert("country", Result.Country.Description);
	//	Address.Insert("default_billing", Result.DefaultBilling);
	//	Address.Insert("default_shipping", Result.DefaultShipping);
	//	
	//	Addresses.Add(Address);
	//	
	//EndDo;
	//
	//DataAddresses = New Map();
	//DataAddresses.Insert("addresses", Addresses);
	//
	//CompanyData = New Map();
	//CompanyData.Insert("api_code", String(Company.Ref.UUID()));
	//CompanyData.Insert("company_name", Company.Description);
	//CompanyData.Insert("company_code", Company.Code);
	//CompanyData.Insert("company_type", "customer");
	//CompanyData.Insert("lines", DataAddresses);
	
	//jsonout = InternetConnectionClientServer.EncodeJSON(CompanyData);
	
	//Return jsonout;
	
	companyObj = Company.GetObject(); 
	jsonout = InternetConnectionClientServer.EncodeJSON(GeneralFunctions.ReturnCompanyObjectMap(companyObj));

	Return jsonout;



EndFunction  

Function inoutCompaniesDelete(jsonin) Export
	
	ParsedJSON = InternetConnectionClientServer.DecodeJSON(jsonin);

	api_code = ParsedJSON.object_code;
	
	//Company = Catalogs.Companies.FindByCode(CompanyCode);
	Company = Catalogs.Companies.GetRef(New UUID(api_code));
	
	CompanyObj = Company.GetObject();
	
	company_name = CompanyObj.Description;
	
	SetPrivilegedMode(True);
	Try 
		CompanyObj.Delete(); //.DeletionMark = True;
	Except
		errorMessage = New Map();
		strMessage = "Failed to delete. There are linked objects to this company.";
		errorMessage.Insert("message", strMessage);
		errorMessage.Insert("company_name", company_name);
		errorMessage.Insert("status", "error"); 
		errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
		return errorJSON;
	EndTry;
	SetPrivilegedMode(False);
	
	Output = New Map();	
	
	//Try
	//	CompanyObj.Write();
		Output.Insert("status", "success");
		//Output.Insert("company_name", company_name);
		strMessage = company_name + " has been deleted.";
		Output.Insert("message", strMessage);
	//Except
	//	//ErrorMessage = DetailErrorDescription(ErrorInfo());
	//	Output.Insert("error", "company can not be deleted");
	//EndTry;
	
	jsonout = InternetConnectionClientServer.EncodeJSON(Output);
	
	Return jsonout;

EndFunction

Function inoutCompaniesListAll(jsonin) Export
		
	Query = New Query("SELECT
	                  |	Companies.Ref
	                  |FROM
	                  |	Catalog.Companies AS Companies");
	                  //|WHERE
	                  //|	Companies.Customer = TRUE");
	Result = Query.Execute().Choose();
	
	Companies = New Array();
	
	While Result.Next() Do
		
		//Company = New Map();
		//Company.Insert("api_code", String(Result.Ref.UUID()));
		//Company.Insert("company_code", Result.Code);
		//Company.Insert("company_name", Result.Description);
		//If Result.Customer = TRUE AND Result.Vendor = TRUE Then
		//	Company.Insert("company_type", "customer+vendor");
		//Elsif Result.Customer = TRUE AND Result.Vendor = FALSE Then
		//	Company.Insert("company_type", "customer");
		//Else
		//	Company.Insert("company_type", "vendor");
		//Endif;
			
		
		Companies.Add(GeneralFunctions.ReturnCompanyObjectMap(Result.Ref));
		
	EndDo;
	
	CompanyList = New Map();
	CompanyList.Insert("companies", Companies);
	
	jsonout = InternetConnectionClientServer.EncodeJSON(CompanyList);
	
	Return jsonout;

EndFunction


Function inoutItemsCreate(jsonin) Export
		
	ParsedJSON = InternetConnectionClientServer.DecodeJSON(jsonin);
	
	// check if an item already exists
	
	ProductExists = True;
	
	Try
	
		Query = New Query("SELECT
		                  |	Products.Ref
		                  |FROM
		                  |	Catalog.Products AS Products
		                  |WHERE
		                  |	Products.Code = &Code");
		Query.SetParameter("Code", ParsedJSON.item_code);
		QueryResult = Query.Execute();
		
		If QueryResult.IsEmpty() Then
			ProductExists = False;
		Else
		EndIf;
		
	Except
		
		errorMessage = New Map();
		strMessage = " [item_code] : This is a required field ";
		errorMessage.Insert("message", strMessage);
		errorMessage.Insert("status", "error"); 
		errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
		return errorJSON;
	
	EndTry;
	
	
	// end check if product exists

	If ProductExists = False Then
	
		NewProduct = Catalogs.Products.CreateItem();
		
		NewProduct.Code = ParsedJSON.item_code;
		
		//NewProduct.Description = ParsedJSON.item_description;
		
		Try desc = ParsedJSON.item_description Except desc = Undefined EndTry;
		If desc = Undefined Then
			errorMessage = New Map();
			strMessage = " [item_description] : This is a required field ";
			errorMessage.Insert("message", strMessage);
			errorMessage.Insert("status", "error"); 
			errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
			return errorJSON;
		EndIf;
		NewProduct.Description = desc;
		
		//Try
		//	If ParsedJSON.item_type = "product" Then
		//		NewProduct.Type = Enums.InventoryTypes.Inventory;
		//		NewProduct.CostingMethod = Enums.InventoryCosting.WeightedAverage;
		//		NewProduct.InventoryOrExpenseAccount = Constants.InventoryAccount.Get();
		//	ElsIf ParsedJSON.item_type = "service" Then
		//		NewProduct.Type = Enums.InventoryTypes.NonInventory;
		//		NewProduct.InventoryOrExpenseAccount = Constants.ExpenseAccount.Get();
		//	Else
		//		NewProduct.Type = Enums.InventoryTypes.NonInventory;
		//		NewProduct.InventoryOrExpenseAccount = Constants.ExpenseAccount.Get();
		//	EndIf;
		//Except
		//	NewProduct.Type = Enums.InventoryTypes.NonInventory;
		//EndTry;
		
		Try itemType = ParsedJSON.item_type Except itemType = Undefined EndTry;
		If itemType = "product" Then
			NewProduct.Type = Enums.InventoryTypes.Inventory;
			NewProduct.CostingMethod = Enums.InventoryCosting.WeightedAverage;
			NewProduct.InventoryOrExpenseAccount = Constants.InventoryAccount.Get();
		ElsIf itemType = "service" Then
			NewProduct.Type = Enums.InventoryTypes.NonInventory;
			NewProduct.InventoryOrExpenseAccount = Constants.ExpenseAccount.Get();
		Else
			errorMessage = New Map();
			strMessage = " [item_type] : This is a required field. Must be either product or service ";
			errorMessage.Insert("message", strMessage);
			errorMessage.Insert("status", "error"); 
			errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
			return errorJSON;
		EndIf;
		
		NewProduct.IncomeAccount = Constants.IncomeAccount.Get();
		
		
		Try
			If ParsedJSON.item_type = "product" Then
				NewProduct.COGSAccount = Constants.COGSAccount.Get();
			Else
			EndIf;
		Except
		EndTry;
		//NewProduct.PurchaseVATCode = Constants.DefaultPurchaseVAT.Get();
		//NewProduct.SalesVATCode = Constants.DefaultSalesVAT.Get();
		//NewProduct.api_code = GeneralFunctions.NextProductNumber();
		
		Try itemCategory = ParsedJSON.item_category Except itemCategory = Undefined EndTry;
		If NOT itemCategory = Undefined Then
			cQuery = New Query("SELECT
			                   |	ProductCategories.Ref
			                   |FROM
			                   |	Catalog.ProductCategories AS ProductCategories
			                   |WHERE
			                   |	ProductCategories.Description = &cat");
			cQuery.SetParameter("cat", itemCategory );
			cQueryResult = cQuery.Execute();
			If cQueryResult.IsEmpty() Then
				errorMessage = New Map();
				strMessage = " [item_category] : The category does not exist. You must create the item category first. ";
				errorMessage.Insert("message", strMessage);
				errorMessage.Insert("status", "error"); 
				errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
				return errorJSON;
			EndIf;
			cat_result = cQueryResult.Unload();
			NewProduct.Category = cat_result[0].Ref;
		EndIf;
		
		Try uom = ParsedJSON.unit_of_measure Except uom = Undefined EndTry;
		If NOT uom = Undefined Then
			uomQuery = New Query("SELECT
			                     |	UM.Ref
			                     |FROM
			                     |	Catalog.UM AS UM
			                     |WHERE
			                     |	UM.Description = &uomCode");
			uomQuery.SetParameter("uomCode", uom );
			uomQueryResult = uomQuery.Execute();
			If uomQueryResult.IsEmpty() Then
				errorMessage = New Map();
				strMessage = " [unit_of_measure] : This does not exist. You must create the unit of measure first. ";
				errorMessage.Insert("message", strMessage);
				errorMessage.Insert("status", "error"); 
				errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
				return errorJSON;
			EndIf;
			uom_result = uomQueryResult.Unload();
			NewProduct.UM = uom_result[0].Ref;
		EndIf;
		
		Try NewProduct.CF1String = ParsedJSON.cf1_string; Except EndTry;
		Try NewProduct.CF2String = ParsedJSON.cf2_string; Except EndTry;
		Try NewProduct.CF3String = ParsedJSON.cf3_string; Except EndTry;
		Try NewProduct.CF4String = ParsedJSON.cf4_string; Except EndTry;
		Try NewProduct.CF5String = ParsedJSON.cf5_string; Except EndTry;
		Try NewProduct.CF1Num = ParsedJSON.cf1_num; Except EndTry;
		Try NewProduct.CF2Num = ParsedJSON.cf2_num; Except EndTry;
		Try NewProduct.CF3Num = ParsedJSON.cf3_num; Except EndTry;
		Try NewProduct.CF4Num = ParsedJSON.cf4_num; Except EndTry;
		Try NewProduct.CF5Num = ParsedJSON.cf5_num; Except EndTry;


		NewProduct.Write();
			
		///
		
		ProductData = GeneralFunctions.ReturnProductObjectMap(NewProduct);
			
		//ProductData = New Map();
		//ProductData.Insert("item_code", NewProduct.Code);
		//ProductData.Insert("api_code", String(NewProduct.Ref.UUID()));
		//ProductData.Insert("item_description", NewProduct.Description);
		//If NewProduct.Type = Enums.InventoryTypes.Inventory Then
		//	ProductData.Insert("item_type", "product");
		//ElsIf NewProduct.Type = Enums.InventoryTypes.NonInventory Then
		//	ProductData.Insert("item_type", "service");	
		//EndIf;
		
		jsonout = InternetConnectionClientServer.EncodeJSON(ProductData);
		
	Else
		
		ProductData = New Map();
		//ProductData.Insert("Error", "Item code is not unique");
		ProductData.Insert("message", " [item_code] : The item already exists. Not a unique item code.");
		ProductData.Insert("status", "error");

		existingItem = QueryResult.Unload();
  		ProductData.Insert("api_code", String(existingItem[0].Ref.UUID()));

		
		jsonout = InternetConnectionClientServer.EncodeJSON(ProductData);
		
	EndIf;
	
	Return jsonout;
	
EndFunction

Function inoutItemsUpdate(jsonin, object_code) Export
	
	//
	//ProductCodeJSON = InternetConnectionClientServer.DecodeJSON(object_code);
	//api_code = ProductCodeJSON.object_code;
	////ProductCode = Number(ProductCode);
	//
	//ParsedJSON = InternetConnectionClientServer.DecodeJSON(jsonin);
	//
	//UpdatedProduct = Catalogs.Products.getref(New UUID(api_code));
	//UpdatedProductObj = UpdatedProduct.GetObject();
	//UpdatedProductObj.Code = ParsedJSON.item_code;
	//UpdatedProductObj.Description = ParsedJSON.item_description;
	//UpdatedProductObj.Write();
	
	ProductCodeJSON = InternetConnectionClientServer.DecodeJSON(object_code);
	//api_code = ProductCodeJSON.object_code;
	//ProductCode = Number(ProductCode);
	
	Try api_code = ProductCodeJSON.object_code Except api_code = Undefined EndTry;
	If api_code = Undefined OR api_code = "" Then
		errorMessage = New Map();
		strMessage = " [api_code] : Missing the item ID# ";
		errorMessage.Insert("message", strMessage);
		errorMessage.Insert("status", "error"); 
		errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
		return errorJSON;
	EndIf;
		
	ParsedJSON = InternetConnectionClientServer.DecodeJSON(jsonin);
	
	Try	
		UpdatedProduct = Catalogs.Products.getref(New UUID(api_code));
	Except
		errorMessage = New Map();
		strMessage = " [api_code] : The item does not exist. Double check that the ID# is correct. ";
		errorMessage.Insert("message", strMessage);
		errorMessage.Insert("status", "error"); 
		errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
		return errorJSON;
	EndTry;
	
	itemQuery = New Query("SELECT
	                      |	Products.Ref
	                      |FROM
	                      |	Catalog.Products AS Products
	                      |WHERE
	                      |	Products.Ref = &item");
	itemQuery.SetParameter("item", UpdatedProduct);
	itemresult = itemQuery.Execute();
	If itemresult.IsEmpty() Then
			errorMessage = New Map();
			strMessage = " [api_code] : The item does not exist. Double check that the ID# is correct. ";
			errorMessage.Insert("message", strMessage);
			errorMessage.Insert("status", "error"); 
			errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
			return errorJSON;
	EndIf;
	
	UpdatedProductObj = UpdatedProduct.GetObject();
	
	Try 
		itemCode = ParsedJSON.item_code;
		Query = New Query("SELECT
		                  |	Products.Ref
		                  |FROM
		                  |	Catalog.Products AS Products
		                  |WHERE
		                  |	Products.Code = &Code");
		Query.SetParameter("Code", itemCode);
		QueryResult = Query.Execute();
		
		If QueryResult.IsEmpty() Then
			UpdatedProductObj.Code = itemCode; 
		Else
			ProductData = New Map();
			ProductData.Insert("message", " [item_code] : The item already exists. Not a unique item code.");
			ProductData.Insert("status", "error");
			existingItem = QueryResult.Unload();
	  		ProductData.Insert("api_code", String(existingItem[0].Ref.UUID()));
			jsonout = InternetConnectionClientServer.EncodeJSON(ProductData);
			return jsonout;
		EndIf;
	Except 
	EndTry;
	
	Try UpdatedProductObj.Description = ParsedJSON.item_description; Except EndTry;
	
	//Try UpdatedProductObj.Category = ParsedJSON.item_category; Except EndTry;
	Try itemCategory = ParsedJSON.item_category Except itemCategory = Undefined EndTry;
	If NOT itemCategory = Undefined Then
		cQuery = New Query("SELECT
		                   |	ProductCategories.Ref
		                   |FROM
		                   |	Catalog.ProductCategories AS ProductCategories
		                   |WHERE
		                   |	ProductCategories.Description = &cat");
		cQuery.SetParameter("cat", itemCategory );
		cQueryResult = cQuery.Execute();
		If cQueryResult.IsEmpty() Then
			errorMessage = New Map();
			strMessage = " [item_category] : The category does not exist. You must create the item category first. ";
			errorMessage.Insert("message", strMessage);
			errorMessage.Insert("status", "error"); 
			errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
			return errorJSON;
		EndIf;
		cat_result = cQueryResult.Unload();
		UpdatedProductObj.Category = cat_result[0].Ref;
	EndIf;
	
	//Try UpdatedProductObj.UM = ParsedJSON.unit_of_measure; Except EndTry;
	Try uom = ParsedJSON.unit_of_measure Except uom = Undefined EndTry;
	If NOT uom = Undefined Then
		uomQuery = New Query("SELECT
		                     |	UM.Ref
		                     |FROM
		                     |	Catalog.UM AS UM
		                     |WHERE
		                     |	UM.Description = &uomCode");
		uomQuery.SetParameter("uomCode", uom );
		uomQueryResult = uomQuery.Execute();
		If uomQueryResult.IsEmpty() Then
			errorMessage = New Map();
			strMessage = " [unit_of_measure] : This does not exist. You must create the unit of measure first. ";
			errorMessage.Insert("message", strMessage);
			errorMessage.Insert("status", "error"); 
			errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
			return errorJSON;
		EndIf;
		uom_result = uomQueryResult.Unload();
		UpdatedProductObj.UM = uom_result[0].Ref;
	EndIf;
	
	Try checkItemType = ParsedJSON.item_type; Except checkItemType = Undefined EndTry;
	If NOT checkItemType = Undefined Then
		errorMessage = New Map();
		strMessage = " [item_type] : Cannot change the item type ";
		errorMessage.Insert("message", strMessage);
		errorMessage.Insert("status", "error"); 
		errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
		return errorJSON;
	EndIf;
	
	Try UpdatedProductObj.CF1String = ParsedJSON.cf1_string; Except EndTry;
	Try UpdatedProductObj.CF2String = ParsedJSON.cf2_string; Except EndTry;
	Try UpdatedProductObj.CF3String = ParsedJSON.cf3_string; Except EndTry;
	Try UpdatedProductObj.CF4String = ParsedJSON.cf4_string; Except EndTry;
	Try UpdatedProductObj.CF5String = ParsedJSON.cf5_string; Except EndTry;
	Try UpdatedProductObj.CF1Num = ParsedJSON.cf1_num; Except EndTry;
	Try UpdatedProductObj.CF2Num = ParsedJSON.cf2_num; Except EndTry;
	Try UpdatedProductObj.CF3Num = ParsedJSON.cf3_num; Except EndTry;
	Try UpdatedProductObj.CF4Num = ParsedJSON.cf4_num; Except EndTry;
	Try UpdatedProductObj.CF5Num = ParsedJSON.cf5_num; Except EndTry;
	
		
	UpdatedProductObj.Write();
	
	//////////////////////////////////////////////
	//Output = New Map();
	//Output.Insert("status", "success");
	
	ProductData = GeneralFunctions.ReturnProductObjectMap(UpdatedProductObj);
	jsonout = InternetConnectionClientServer.EncodeJSON(ProductData);
	
	Return jsonout;
	/////////////////////////////////////////////////


EndFunction

Function inoutItemsGet(jsonin) Export
	
	ParsedJSON = InternetConnectionClientServer.DecodeJSON(jsonin);
	
	api_code = ParsedJSON.object_code;
	//Object_code = Number(Object_code);
	//Product = Catalogs.Products.FindByAttribute("api_code", Object_code);
	//Product = Catalogs.Products.GetRef(New UUID(api_code));
	
	Try	
		Product = Catalogs.Products.GetRef(New UUID(api_code));
	Except
		errorMessage = New Map();
		strMessage = " [api_code] : The item does not exist. Double check that the ID# is correct. ";
		errorMessage.Insert("message", strMessage);
		errorMessage.Insert("status", "error"); 
		errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
		return errorJSON;
	EndTry;
	
	itemQuery = New Query("SELECT
	                      |	Products.Ref
	                      |FROM
	                      |	Catalog.Products AS Products
	                      |WHERE
	                      |	Products.Ref = &item");
	itemQuery.SetParameter("item", Product);
	itemresult = itemQuery.Execute();
	If itemresult.IsEmpty() Then
			errorMessage = New Map();
			strMessage = " [api_code] : The item does not exist. Double check that the ID# is correct. ";
			errorMessage.Insert("message", strMessage);
			errorMessage.Insert("status", "error"); 
			errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
			return errorJSON;
	EndIf;
		
	//ProductData = New Map();
	//ProductData.Insert("api_code", String(Product.Ref.UUID()));
	//ProductData.Insert("item_code", Product.Code);
	//ProductData.Insert("item_description", Product.Description);
	//If Product.Type = Enums.InventoryTypes.Inventory Then
	//	ProductData.Insert("item_type", "product");
	//ElsIf Product.Type = Enums.InventoryTypes.NonInventory Then
	//	ProductData.Insert("item_type", "service");	
	//EndIf;
	
	
	
	//jsonout = InternetConnectionClientServer.EncodeJSON(ProductData);
	jsonout = InternetConnectionClientServer.EncodeJSON(GeneralFunctions.ReturnProductObjectMap(Product));
	
	Return jsonout;


EndFunction

Function inoutItemsDelete(jsonin) Export
	
	ParsedJSON = InternetConnectionClientServer.DecodeJSON(jsonin);
	api_code = ParsedJSON.object_code;
	//ProductCode = Number(ProductCode);
	
	Product = Catalogs.Products.GetRef(New UUID(api_code));
	
	ProductObj = Product.GetObject();
	ic = ProductObj.Code;
	SetPrivilegedMode(True);
	Try
		ProductObj.Delete(); //.DeletionMark = True;
	Except
		errorMessage = New Map();
		strMessage = "Failed to delete. There are linked objects to this item.";
		errorMessage.Insert("message", strMessage);
		errorMessage.Insert("item_code",ic);
		errorMessage.Insert("status", "error"); 
		errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
		return errorJSON;
	EndTry;
	SetPrivilegedMode(False);
	
	Output = New Map();	
	
	//Try
	//	ProductObj.Write();
		Output.Insert("status", "success");
		strMessage = ic + " has been deleted.";
		Output.Insert("message", strMessage);
	//Except
		//ErrorMessage = DetailErrorDescription(ErrorInfo());
		//Output.Insert("error", "item can not be deleted");
	//EndTry;
	
	jsonout = InternetConnectionClientServer.EncodeJSON(Output);
	
	Return jsonout;

EndFunction

Function inoutItemsListAll(jsonin) Export
		
	Query = New Query("SELECT
					  | Products.Ref,
					  | Products.Code,
					  | Products.Description,
					  | Products.Type
					  |FROM
					  |	Catalog.Products AS Products");
	Result = Query.Execute().Choose();
	
	Products = New Array();
	
	While Result.Next() Do
		
		//Product = New Map();
		//Product.Insert("item_code", Result.Code);
		//Product.Insert("api_code", String(Result.Ref.UUID()));
		//Product.Insert("item_description", Result.Description);
		//If Result.Type = Enums.InventoryTypes.Inventory Then
		//	Product.Insert("item_type", "product");
		//ElsIf Result.Type = Enums.InventoryTypes.NonInventory Then
		//	Product.Insert("item_type", "service");
		//EndIf;
		//
		//Products.Add(Product);
		Products.Add(GeneralFunctions.ReturnProductObjectMap(Result.Ref));
		
	EndDo;
	
	ProductList = New Map();
	ProductList.Insert("items", Products);
	
	jsonout = InternetConnectionClientServer.EncodeJSON(ProductList);
	
	//Query = New Query("SELECT
	//				  | Products.Ref,
	//				  | Products.Code,
	//				  | Products.Description,
	//				  | Products.Type
	//				  |FROM
	//				  |	Catalog.Products AS Products");

	//Result = Query.Execute().Unload();
	//
	//Products = New Array();
	//
	//For Each ResultObj In Result Do
	//	
	//	Product = GeneralFunctions.ReturnProductObjectMap(ResultObj.Ref);		
	//	Products.Add(Product);
	//	
	//EndDo;

	//
	//ProductList = New Map();
	//ProductList.Insert("orders", Products);
	//
	//jsonout = InternetConnectionClientServer.EncodeJSON(ProductList);

	
	Return jsonout;

EndFunction


Function inoutCashSalesCreate(jsonin) Export
		
	ParsedJSON = InternetConnectionClientServer.DecodeJSON(jsonin);
		
	NewCashSale = Documents.CashSale.CreateDocument();
	//CompanyCode = ParsedJSON.company_code;
	customer_api_code = ParsedJSON.customer_api_code;
	NewCashSale.Company = Catalogs.Companies.GetRef(New UUID(customer_api_code));
	//ShipToAddressCode = ParsedJSON.ship_to_address_code;
	ship_to_api_code = ParsedJSON.ship_to_api_code;
	// check if address belongs to company
	NewCashSale.ShipTo = Catalogs.Addresses.GetRef(New UUID(ship_to_api_code));
	// select the company's default shipping address
	
	NewCashSale.Date = ParsedJSON.date;
	
	//PaymentMethod = ParsedJSON.Get("payment_method");
	// support all payment methods
	NewCashSale.PaymentMethod = Catalogs.PaymentMethods.Cash;
	Try
		NewCashSale.RefNum = ParsedJSON.ref_num;
	Except
	EndTry;
	Try
		NewCashSale.Memo = ParsedJSON.memo;
	Except
	EndTry;
	// tax rate - calculate from address?
	Try
		SalesTax = ParsedJSON.sales_tax_total; 
		NewCashSale.SalesTaxRC = ParsedJSON.sales_tax_total;		
	Except
		NewCashSale.SalesTaxRC = 0;
	EndTry;
	NewCashSale.DocumentTotal = ParsedJSON.doc_total;
	NewCashSale.DocumentTotalRC = ParsedJSON.doc_total;
    NewCashSale.DepositType = "2";
	NewCashSale.Currency = Constants.DefaultCurrency.Get();
	NewCashSale.BankAccount = Constants.BankAccount.Get();
	NewCashSale.ExchangeRate = 1;
	NewCashSale.Location = Catalogs.Locations.MainWarehouse;
	
	Try NewCashSale.LineSubtotalRC = ParsedJSON.line_subtotal; Except EndTry;
	Try NewCashSale.DiscountRC = ParsedJSON.discount; Except EndTry;
	Try NewCashSale.DiscountPercent = ParsedJSON.discount_percent; Except EndTry;
	Try NewCashSale.SubTotalRC = ParsedJSON.subtotal; Except EndTry;
	Try NewCashSale.ShippingRC = ParsedJSON.shipping; Except EndTry;
	
	DataLineItems = ParsedJSON.lines.line_items;
	
	LineItemsRows = DataLineItems.Count();
	For i = 0 To LineItemsRows -1 Do
		
		NewLine = NewCashSale.LineItems.Add();
		
		//ProductCode = Number(DataLineItems[i].api_code);
		Product = Catalogs.Products.GetRef(New UUID(DataLineItems[i].api_code));
		NewLine.Product = Product;
		NewLine.ProductDescription = Product.Description;
		//NewLine.VATCode = CommonUse.GetAttributeValue(Product, "SalesVATCode");
		//NewLine.VAT = 0;
		
		NewLine.Price = DataLineItems[i].price;
		NewLine.Quantity = DataLineItems[i].quantity;
		//Try NewLine.Taxable = DataLineItems[i].taxable; Except EndTry;
		// get taxable from JSON
		//Try
		//	TaxableType = DataLineItems[i].taxable_type;
		//	If TaxableType = "taxable" Then
		//		NewLine.SalesTaxType = Enums.SalesTaxTypes.Taxable;
		//	ElsIf TaxableType = "non-taxable" Then
		//		NewLine.SalesTaxType = Enums.SalesTaxTypes.NonTaxable;
		//	Else
		//		NewLine.SalesTaxType = Enums.SalesTaxTypes.NonTaxable;
		//	EndIf;
		//Except
		//	NewLine.SalesTaxType = Enums.SalesTaxTypes.NonTaxable;	
		//EndTry;
		
		NewLine.LineTotal = DataLineItems[i].line_total;
		//Try
		//	TaxableAmount = DataLineItems[i].taxable_amount;
		//	NewLine.TaxableAmount = TaxableAmount				
		//Except
		//	NewLine.TaxableAmount = 0;
		//EndTry;
				
	EndDo;
	
	NewCashSale.Write();
		
	///
	
	
	CashSaleData = New Map();	
	CashSaleData.Insert("api_code", String(NewCashSale.Ref.UUID()));
	CashSaleData.Insert("customer_api_code", String(NewCashSale.Company.Ref.UUID()));
	CashSaleData.Insert("company_name", NewCashSale.Company.Description);
	CashSaleData.Insert("company_code", NewCashSale.Company.Code);
	CashSaleData.Insert("ship_to_api_code", String(NewCashSale.ShipTo.Ref.UUID()));
	CashSaleData.Insert("ship_to_address_code", NewCashSale.ShipTo.Code);
	CashSaleData.Insert("ship_to_address_id", NewCashSale.ShipTo.Description);
	// date - convert into the same format as input
	CashSaleData.Insert("cash_sale_number", NewCashSale.Number);
	// payment method - same as input
	CashSaleData.Insert("payment_method", NewCashSale.PaymentMethod.Description);
	CashSaleData.Insert("date", NewCashSale.Date);
	CashSaleData.Insert("ref_num", NewCashSale.RefNum);
	CashSaleData.Insert("memo", NewCashSale.Memo);
	CashSaleData.Insert("sales_tax_total", NewCashSale.SalesTaxRC);
	CashSaleData.Insert("doc_total", NewCashSale.DocumentTotalRC);
	
	CashSaleData.Insert("line_subtotal", NewCashSale.LineSubtotalRC);
	CashSaleData.Insert("discount", NewCashSale.DiscountRC);
	CashSaleData.Insert("discount_percent", NewCashSale.DiscountPercent);
	CashSaleData.Insert("subtotal", NewCashSale.SubTotalRC);
	CashSaleData.Insert("shipping", NewCashSale.ShippingRC);


	Query = New Query("SELECT
	                  |	CashSaleLineItems.Product,
	                  |	CashSaleLineItems.Price,
	                  |	CashSaleLineItems.Quantity,
	                  |	CashSaleLineItems.LineTotal
	                  |FROM
	                  |	Document.CashSale.LineItems AS CashSaleLineItems
	                  |WHERE
	                  |	CashSaleLineItems.Ref = &CashSale");
	Query.SetParameter("CashSale", NewCashSale.Ref);
	Result = Query.Execute().Choose();
	
	LineItems = New Array();
	
	While Result.Next() Do
		
		LineItem = New Map();
		LineItem.Insert("api_code", String(Result.Product.Ref.UUID()));
		LineItem.Insert("item_code", Result.Product.Code);
		LineItem.Insert("item_description", Result.Product.Description);
		LineItem.Insert("price", Result.Price);
		LineItem.Insert("quantity", Result.Quantity);
		//LineItem.Insert("taxable_amount", Result.TaxableAmount);
		LineItem.Insert("line_total", Result.LineTotal);
		//LineItem.Insert("taxable", Result.Taxable);
		//If Result.SalesTaxType = Enums.SalesTaxTypes.Taxable Then
		//	LineItem.Insert("taxable_type", "taxable");
		//ElsIf Result.SalesTaxType = Enums.SalesTaxTypes.NonTaxable Then
		//	LineItem.Insert("taxable_type", "non-taxable");
		//EndIf;
		LineItems.Add(LineItem);
		
	EndDo;
	
	LineItemsData = New Map();
	LineItemsData.Insert("line_items", LineItems);
	
	CashSaleData.Insert("lines", LineItemsData);
	
	jsonout = InternetConnectionClientServer.EncodeJSON(CashSaleData);
	
	Return jsonout;

	
EndFunction

Function inoutCashSalesUpdate(jsonin, object_code) Export
	
	CashSaleNumberJSON = InternetConnectionClientServer.DecodeJSON(object_code);
	api_code = CashSaleNumberJSON.object_code;
	
	ParsedJSON = InternetConnectionClientServer.DecodeJSON(jsonin);
	
	UpdatedCashSale = Documents.CashSale.GetRef(New UUID(api_code));	
	UpdatedCashSaleObj = UpdatedCashSale.GetObject();
	UpdatedCashSaleObj.LineItems.Clear();
	
	///
	
	customer_api_code = ParsedJSON.customer_api_code;
	//CompanyCode = ParsedJSON.company_code;
	UpdatedCashSaleObj.Company = Catalogs.Companies.GetRef(New UUID(customer_api_code));
	ship_to_api_code = ParsedJSON.ship_to_api_code;
	//ShipToAddressCode = ParsedJSON.ship_to_address_code;
	// check if address belongs to company
	UpdatedCashSaleObj.ShipTo = Catalogs.Addresses.GetRef(New UUID(ship_to_api_code));
	// select the company's default shipping address
	
	UpdatedCashSaleObj.Date = ParsedJSON.date;
	
	//PaymentMethod = ParsedJSON.Get("payment_method");
	// support all payment methods
	UpdatedCashSaleObj.PaymentMethod = Catalogs.PaymentMethods.Cash;
	Try
		UpdatedCashSaleObj.RefNum = ParsedJSON.ref_num;
	Except
	EndTry;
	Try
		UpdatedCashSaleObj.Memo = ParsedJSON.memo;
	Except
	EndTry;
	// tax rate - calculate from address?
	
	Try
		SalesTax = ParsedJSON.sales_tax_total; 
		UpdatedCashSaleObj.SalesTaxRC = ParsedJSON.sales_tax_total;		
	Except
		UpdatedCashSaleObj.SalesTaxRC = 0;
	EndTry;

	UpdatedCashSaleObj.DocumentTotal = ParsedJSON.doc_total;
	UpdatedCashSaleObj.DocumentTotalRC = ParsedJSON.doc_total;
    UpdatedCashSaleObj.DepositType = "2";
	UpdatedCashSaleObj.Currency = Constants.DefaultCurrency.Get();
	UpdatedCashSaleObj.BankAccount = Constants.BankAccount.Get();
	UpdatedCashSaleObj.ExchangeRate = 1;
	UpdatedCashSaleObj.Location = Catalogs.Locations.MainWarehouse;
	
	Try UpdatedCashSaleObj.LineSubtotalRC = ParsedJSON.line_subtotal; Except EndTry;
	Try UpdatedCashSaleObj.DiscountRC = ParsedJSON.discount; Except EndTry;
	Try UpdatedCashSaleObj.DiscountPercent = ParsedJSON.discount_percent; Except EndTry;
	Try UpdatedCashSaleObj.SubTotalRC = ParsedJSON.subtotal; Except EndTry;
	Try UpdatedCashSaleObj.ShippingRC = ParsedJSON.shipping; Except EndTry;
	
	DataLineItems = ParsedJSON.lines.line_items;
	
	LineItemsRows = DataLineItems.Count();
	For i = 0 To LineItemsRows -1 Do
		
		NewLine = UpdatedCashSaleObj.LineItems.Add();
		
		//product_api_code = DataLineItems[i].api_code;
		Product = Catalogs.Products.GetRef(New UUID(DataLineItems[i].api_code));
		//Product = Catalogs.Products.GetRef(New UUID(product_api_code));
		NewLine.Product = Product;
		NewLine.ProductDescription = Product.Description;
		//NewLine.VATCode = CommonUse.GetAttributeValue(Product, "SalesVATCode");
		//NewLine.VAT = 0;
		
		NewLine.Price = DataLineItems[i].price;
		NewLine.Quantity = DataLineItems[i].quantity;
		//Try NewLine.Taxable = DataLineItems[i].taxable; Except EndTry;
		// get taxable from JSON
		//Try
		//	TaxableType = DataLineItems[i].taxable_type;
		//	If TaxableType = "taxable" Then
		//		NewLine.SalesTaxType = Enums.SalesTaxTypes.Taxable;
		//	ElsIf TaxableType = "non-taxable" Then
		//		NewLine.SalesTaxType = Enums.SalesTaxTypes.NonTaxable;
		//	Else
		//		NewLine.SalesTaxType = Enums.SalesTaxTypes.NonTaxable;
		//	EndIf;
		//Except
		//	NewLine.SalesTaxType = Enums.SalesTaxTypes.NonTaxable;	
		//EndTry;

		NewLine.LineTotal = DataLineItems[i].line_total;
		//Try
		//	TaxableAmount = DataLineItems[i].taxable_amount;
		//	NewLine.TaxableAmount = TaxableAmount				
		//Except
		//	NewLine.TaxableAmount = 0;
		//EndTry;
				
	EndDo;
	
	UpdatedCashSaleObj.Write();

	
	///
	
	NewCashSale = UpdatedCashSaleObj; // code below is copied from CashSalesPost
	
	CashSaleData = New Map();	
	CashSaleData.Insert("api_code", String(NewCashSale.Ref.UUID()));
	CashSaleData.Insert("customer_api_code", String(NewCashSale.Company.Ref.UUID()));
	CashSaleData.Insert("company_name", NewCashSale.Company.Description);
	CashSaleData.Insert("company_code", NewCashSale.Company.Code);
	CashSaleData.Insert("ship_to_api_code", String(NewCashSale.ShipTo.Ref.UUID()));
	CashSaleData.Insert("ship_to_address_code", NewCashSale.ShipTo.Code);
	CashSaleData.Insert("ship_to_address_id", NewCashSale.ShipTo.Description);
	// date - convert into the same format as input
	CashSaleData.Insert("cash_sale_number", NewCashSale.Number);
	// payment method - same as input
	CashSaleData.Insert("payment_method", NewCashSale.PaymentMethod.Description);
	CashSaleData.Insert("date", NewCashSale.Date);
	CashSaleData.Insert("ref_num", NewCashSale.RefNum);
	CashSaleData.Insert("memo", NewCashSale.Memo);
	CashSaleData.Insert("sales_tax_total", NewCashSale.SalesTaxRC);
	CashSaleData.Insert("doc_total", NewCashSale.DocumentTotalRC);
	CashSaleData.Insert("line_subtotal", NewCashSale.LineSubtotalRC);
	CashSaleData.Insert("discount", NewCashSale.DiscountRC);
	CashSaleData.Insert("discount_percent", NewCashSale.DiscountPercent);
	CashSaleData.Insert("subtotal", NewCashSale.SubTotalRC);
	CashSaleData.Insert("shipping", NewCashSale.ShippingRC);

	Query = New Query("SELECT
	                  |	CashSaleLineItems.Product,
	                  |	CashSaleLineItems.Price,
	                  |	CashSaleLineItems.Quantity,
	                  |	CashSaleLineItems.LineTotal
	                  |FROM
	                  |	Document.CashSale.LineItems AS CashSaleLineItems
	                  |WHERE
	                  |	CashSaleLineItems.Ref = &CashSale");
	Query.SetParameter("CashSale", NewCashSale.Ref);
	Result = Query.Execute().Choose();
	
	LineItems = New Array();
	
	While Result.Next() Do
		
		LineItem = New Map();
		LineItem.Insert("api_code", String(Result.Product.Ref.UUID()));
		LineItem.Insert("item_code", Result.Product.Code);
		LineItem.Insert("item_description", Result.Product.Description);
		LineItem.Insert("price", Result.Price);
		LineItem.Insert("quantity", Result.Quantity);
		//LineItem.Insert("taxable_amount", Result.TaxableAmount);
		LineItem.Insert("line_total", Result.LineTotal);
		//LineItem.Insert("taxable", Result.Taxable);
		//If Result.SalesTaxType = Enums.SalesTaxTypes.Taxable Then
		//	LineItem.Insert("taxable_type", "taxable");
		//ElsIf Result.SalesTaxType = Enums.SalesTaxTypes.NonTaxable Then
		//	LineItem.Insert("taxable_type", "non-taxable");
		//EndIf;
		LineItems.Add(LineItem);
		
	EndDo;
	
	LineItemsData = New Map();
	LineItemsData.Insert("line_items", LineItems);
	
	CashSaleData.Insert("lines", LineItemsData);
	
	jsonout = InternetConnectionClientServer.EncodeJSON(CashSaleData);
	
	Return jsonout;

EndFunction

Function inoutCashSalesGet(jsonin) Export
	
	ParsedJSON = InternetConnectionClientServer.DecodeJSON(jsonin);
	api_code = ParsedJSON.object_code;
	
	Try
		CashSale = Documents.CashSale.GetRef(New UUID(api_code));
	Except
		errorMessage = New Map();
		strMessage = " [api_code] : The cash sale does not exist. Double check that the ID# is correct. ";
		errorMessage.Insert("message", strMessage);
		errorMessage.Insert("status", "error"); 
		errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
		return errorJSON;
	EndTry;
	
	SIQuery = New Query("SELECT
	                    |	CashSale.Ref
	                    |FROM
	                    |	Document.CashSale AS CashSale
	                    |WHERE
	                    |	CashSale.Ref = &Ref");
	SIQuery.SetParameter("Ref", CashSale);
	SIresult = SIQuery.Execute();
	If SIresult.IsEmpty() Then
			errorMessage = New Map();
			strMessage = " [api_code] : The sales order does not exist. Double check that the ID# is correct. ";
			errorMessage.Insert("message", strMessage);
			errorMessage.Insert("status", "error"); 
			errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
			return errorJSON;
	EndIf;
	
	NewCashSale = CashSale; // code below is copied from CashSalesPost
	
	CashSaleData = New Map();
	CashSaleData.Insert("api_code", String(NewCashSale.Ref.UUID()));
	CashSaleData.Insert("customer_api_code", String(NewCashSale.Company.Ref.UUID()));
	CashSaleData.Insert("company_name", NewCashSale.Company.Description);
	CashSaleData.Insert("company_code", NewCashSale.Company.Code);
	CashSaleData.Insert("ship_to_api_code", String(NewCashSale.ShipTo.Ref.UUID()));
	CashSaleData.Insert("ship_to_address_code", NewCashSale.ShipTo.Code);
	CashSaleData.Insert("ship_to_address_id", NewCashSale.ShipTo.Description);
	// date - convert into the same format as input
	CashSaleData.Insert("cash_sale_number", NewCashSale.Number);
	// payment method - same as input
	CashSaleData.Insert("payment_method", NewCashSale.PaymentMethod.Description);
	CashSaleData.Insert("date", NewCashSale.Date);
	CashSaleData.Insert("ref_num", NewCashSale.RefNum);
	CashSaleData.Insert("memo", NewCashSale.Memo);
	CashSaleData.Insert("sales_tax_total", NewCashSale.SalesTaxRC);
	CashSaleData.Insert("doc_total", NewCashSale.DocumentTotalRC);
	CashSaleData.Insert("line_subtotal", NewCashSale.LineSubtotalRC);
	CashSaleData.Insert("discount", NewCashSale.DiscountRC);
	CashSaleData.Insert("discount_percent", NewCashSale.DiscountPercent);	
	CashSaleData.Insert("subtotal", NewCashSale.SubTotalRC);
	CashSaleData.Insert("shipping", NewCashSale.ShippingRC);

	Query = New Query("SELECT
	                  |	CashSaleLineItems.Product,
	                  |	CashSaleLineItems.Price,
	                  |	CashSaleLineItems.Quantity,
	                  |	CashSaleLineItems.LineTotal
	                  |FROM
	                  |	Document.CashSale.LineItems AS CashSaleLineItems
	                  |WHERE
	                  |	CashSaleLineItems.Ref = &CashSale");
	Query.SetParameter("CashSale", NewCashSale.Ref);
	Result = Query.Execute().Choose();
	
	LineItems = New Array();
	
	While Result.Next() Do
		
		LineItem = New Map();
		LineItem.Insert("item_code", Result.Product.Code);
		LineItem.Insert("api_code", String(Result.Product.Ref.UUID()));
		LineItem.Insert("item_description", Result.Product.Description);
		LineItem.Insert("price", Result.Price);
		LineItem.Insert("quantity", Result.Quantity);
		//LineItem.Insert("taxable_amount", Result.TaxableAmount);
		LineItem.Insert("line_total", Result.LineTotal);
		//LineItem.Insert("taxable", Result.Taxable);
		//If Result.SalesTaxType = Enums.SalesTaxTypes.Taxable Then
		//	LineItem.Insert("taxable_type", "taxable");
		//ElsIf Result.SalesTaxType = Enums.SalesTaxTypes.NonTaxable Then
		//	LineItem.Insert("taxable_type", "non-taxable");
		//EndIf;
		LineItems.Add(LineItem);
		
	EndDo;
	
	LineItemsData = New Map();
	LineItemsData.Insert("line_items", LineItems);
	
	CashSaleData.Insert("lines", LineItemsData);
	
	jsonout = InternetConnectionClientServer.EncodeJSON(CashSaleData);
	
	Return jsonout;


EndFunction

Function inoutCashSalesDelete(jsonin) Export
	ParsedJSON = InternetConnectionClientServer.DecodeJSON(jsonin);
	api_code = ParsedJSON.object_code;
	
	CashSale = Documents.CashSale.GetRef(New UUID(api_code));
	
	CashSaleObj = CashSale.GetObject();
	saleNum = CashSaleObj.Number;
	date = CashSaleObj.Date;
	SetPrivilegedMode(True);
	Try
		CashSaleObj.Delete();//DeletionMark = True;
	Except
		errorMessage = New Map();
		strMessage = "Failed to delete. Cash Sale must be unposted before deletion and/or other objects are linked to this cash sale.";
		errorMessage.Insert("message", strMessage);
		errorMessage.Insert("cash_sale_number",saleNum);
		errorMessage.Insert("date", date);
		errorMessage.Insert("status", "error"); 
		errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
		return errorJSON;
	EndTry;
	SetPrivilegedMode(False);
	
	Output = New Map();	
	
	//Try
		//CashSaleObj.Write(DocumentWriteMode.UndoPosting);
		Output.Insert("status", "success");
		strMessage = "Cash Sale # " + saleNum + " from " + date + " has been deleted.";
		Output.Insert("message", strMessage);
	//Except
		//ErrorMessage = DetailErrorDescription(ErrorInfo());
		//Output.Insert("error", "cash sale can not be deleted");
	//EndTry;
	
	jsonout = InternetConnectionClientServer.EncodeJSON(Output);
	
	Return jsonout;


EndFunction

Function inoutCashSalesListAll(jsonin) Export
		
	Query = New Query("SELECT
	                  |	CashSale.Ref,
	                  |	CashSale.DataVersion,
	                  |	CashSale.DeletionMark,
	                  |	CashSale.Number,
	                  |	CashSale.Date,
	                  |	CashSale.Posted,
	                  |	CashSale.Company,
	                  |	CashSale.RefNum,
	                  |	CashSale.Memo,
	                  |	CashSale.DepositType,
	                  |	CashSale.Deposited,
	                  |	CashSale.Currency,
	                  |	CashSale.ExchangeRate,
	                  |	CashSale.Location,
	                  |	CashSale.BankAccount,
	                  |	CashSale.PaymentMethod,
	                  |	CashSale.ShipTo,
	                  |	CashSale.Project,
	                  |	CashSale.StripeID,
	                  |	CashSale.StripeCardName,
	                  |	CashSale.StripeAmount,
	                  |	CashSale.StripeCreated,
	                  |	CashSale.StripeCardType,
	                  |	CashSale.StripeLast4,
	                  |	CashSale.NewObject,
	                  |	CashSale.EmailTo,
	                  |	CashSale.EmailNote,
	                  |	CashSale.EmailCC,
	                  |	CashSale.LastEmail,
	                  |	CashSale.LineSubtotalRC,
	                  |	CashSale.DiscountRC,
	                  |	CashSale.SubtotalRC,
	                  |	CashSale.ShippingRC,
	                  |	CashSale.SalesTaxRC,
	                  |	CashSale.DocumentTotal,
	                  |	CashSale.DocumentTotalRC,
	                  |	CashSale.BillTo,
	                  |	CashSale.DiscountPercent,
	                  |	CashSale.LineItems.(
	                  |		Ref,
	                  |		LineNumber,
	                  |		Product,
	                  |		Price,
	                  |		Quantity,
	                  |		LineTotal,
	                  |		ProductDescription,
	                  |		Project
	                  |	)
	                  |FROM
	                  |	Document.CashSale AS CashSale");
	Result = Query.Execute().Choose();
	
	CashSales = New Array();
	
	While Result.Next() Do
		
		CashSale = New Map();
		CashSale.Insert("api_code", String(Result.Ref.UUID()));
		CashSale.Insert("customer_api_code", String(Result.Company.Ref.UUID()));
		CashSale.Insert("company_name", Result.Company.Description);
		CashSale.Insert("company_code", Result.Company.Code);
		CashSale.Insert("ship_to_api_code", String(Result.ShipTo.Ref.UUID()));
		CashSale.Insert("ship_to_address_code", Result.ShipTo.Code);
		CashSale.Insert("ship_to_address_id", Result.ShipTo.Description);
		// date - convert into the same format as input
		CashSale.Insert("cash_sale_number", Result.Number);
		// payment method - same format as input
		CashSale.Insert("payment_method", Result.PaymentMethod.Description);
		// date - convert to input format
		CashSale.Insert("date", Result.Date);
		CashSale.Insert("ref_num", Result.RefNum);
		CashSale.Insert("memo", Result.Memo);
		CashSale.Insert("sales_tax_total", Result.SalesTaxRC);
		CashSale.Insert("doc_total", Result.DocumentTotalRC);
		CashSale.Insert("line_subtotal", Result.LineSubtotalRC);
		CashSale.Insert("discount", Result.DiscountRC);
		CashSale.Insert("discount_percent", Result.DiscountPercent);
		CashSale.Insert("subtotal", Result.SubTotalRC);
		CashSale.Insert("shipping", Result.ShippingRC);
		
		CashSales.Add(CashSale);
		
	EndDo;
	
	CashSalesList = New Map();
	CashSalesList.Insert("cash_sales", CashSales);
	
	jsonout = InternetConnectionClientServer.EncodeJSON(CashSalesList);
	
	Return jsonout;


EndFunction


Function inoutInvoicesCreate(jsonin) Export
		
	ParsedJSON = InternetConnectionClientServer.DecodeJSON(jsonin);
		
	NewInvoice = Documents.SalesInvoice.CreateDocument();
	customer_api_code = ParsedJSON.customer_api_code;
	//CompanyCode = ParsedJSON.company_code;
	NewInvoice.Company = Catalogs.Companies.GetRef(New UUID(customer_api_code));
	ship_to_api_code = ParsedJSON.ship_to_api_code;
	//ShipToAddressCode = ParsedJSON.ship_to_address_code;
	// check if address belongs to company
	NewInvoice.ShipTo = Catalogs.Addresses.GetRef(New UUID(ship_to_api_code));
	// select the company's default shipping address
	
	NewInvoice.Date = ParsedJSON.date;
	NewInvoice.DueDate = ParsedJSON.due_date;
	NewInvoice.Terms = Catalogs.PaymentTerms.DueOnReceipt;
	
	//PaymentMethod = ParsedJSON.Get("payment_method");
	// support all payment methods
	//NewCashSale.PaymentMethod = Catalogs.PaymentMethods.Cash;
	Try
		NewInvoice.RefNum = ParsedJSON.ref_num;
	Except
	EndTry;
	Try
		NewInvoice.Memo = ParsedJSON.memo;
	Except
	EndTry;
	// tax rate - calculate from address?
	Try
		SalesTax = ParsedJSON.sales_tax_total; 
		NewInvoice.SalesTaxRC = ParsedJSON.sales_tax_total;		
	Except
		NewInvoice.SalesTaxRC = 0;
	EndTry;
	NewInvoice.DocumentTotal = ParsedJSON.doc_total;
	NewInvoice.DocumentTotalRC = ParsedJSON.doc_total;
    //NewCashSale.DepositType = "2";
	DefaultCurrency = Constants.DefaultCurrency.Get();
	NewInvoice.Currency = DefaultCurrency;
	NewInvoice.ARAccount = DefaultCurrency.DefaultARAccount;
	//NewCashSale.BankAccount = Constants.BankAccount.Get();
	NewInvoice.ExchangeRate = 1;
	NewInvoice.Location = Catalogs.Locations.MainWarehouse;
	
	Try NewInvoice.LineSubtotalRC = ParsedJSON.line_subtotal; Except EndTry;
	Try NewInvoice.DiscountRC = ParsedJSON.discount; Except EndTry;
	Try NewInvoice.DiscountPercent = ParsedJSON.discount_percent; Except EndTry;
	Try NewInvoice.SubTotalRC = ParsedJSON.subtotal; Except EndTry;
	Try NewInvoice.ShippingRC = ParsedJSON.shipping; Except EndTry;
	
	DataLineItems = ParsedJSON.lines.line_items;
	
	LineItemsRows = DataLineItems.Count();
	For i = 0 To LineItemsRows -1 Do
		
		NewLine = NewInvoice.LineItems.Add();
		
		Product = Catalogs.Products.GetRef(New UUID(DataLineItems[i].api_code));
		NewLine.Product = Product;
		NewLine.ProductDescription = Product.Description;
		//NewLine.VATCode = CommonUse.GetAttributeValue(Product, "SalesVATCode");
		//NewLine.VAT = 0;
		
		NewLine.Price = DataLineItems[i].price;
		NewLine.Quantity = DataLineItems[i].quantity;
		//Try NewLine.Taxable = DataLineItems[i].taxable; Except EndTry;
		// get taxable from JSON
		//Try
		//	TaxableType = DataLineItems[i].taxable_type;
		//	If TaxableType = "taxable" Then
		//		NewLine.SalesTaxType = Enums.SalesTaxTypes.Taxable;
		//	ElsIf TaxableType = "non-taxable" Then
		//		NewLine.SalesTaxType = Enums.SalesTaxTypes.NonTaxable;
		//	Else
		//		NewLine.SalesTaxType = Enums.SalesTaxTypes.NonTaxable;
		//	EndIf;
		//Except
		//	NewLine.SalesTaxType = Enums.SalesTaxTypes.NonTaxable;	
		//EndTry;
		
		NewLine.LineTotal = DataLineItems[i].line_total;
		//Try
		//	TaxableAmount = DataLineItems[i].taxable_amount;
		//	NewLine.TaxableAmount = TaxableAmount				
		//Except
		//	NewLine.TaxableAmount = 0;
		//EndTry;
				
	EndDo;
	
	NewInvoice.Write();
		
	///
	
	
	InvoiceData = New Map();
	InvoiceData.Insert("api_code", String(NewInvoice.Ref.UUID()));
	InvoiceData.Insert("customer_api_code", String(NewInvoice.Company.Ref.UUID()));
	InvoiceData.Insert("company_name", NewInvoice.Company.Description);
	InvoiceData.Insert("company_code", NewInvoice.Company.Code);
	InvoiceData.Insert("ship_to_api_code", String(NewInvoice.ShipTo.Ref.UUID()));
	InvoiceData.Insert("ship_to_address_id", NewInvoice.ShipTo.Description);
	// date - convert into the same format as input
	InvoiceData.Insert("invoice_number", NewInvoice.Number);
	// payment method - same as input
	//CashSaleData.Insert("payment_method", NewInvoice.PaymentMethod.Description);
	InvoiceData.Insert("date", NewInvoice.Date);
	InvoiceData.Insert("due_date", NewInvoice.DueDate);
	InvoiceData.Insert("ref_num", NewInvoice.RefNum);
	InvoiceData.Insert("memo", NewInvoice.Memo);
	InvoiceData.Insert("sales_tax_total", NewInvoice.SalesTaxRC);
	InvoiceData.Insert("doc_total", NewInvoice.DocumentTotalRC);
	InvoiceData.Insert("line_subtotal", NewInvoice.LineSubtotalRC);
	InvoiceData.Insert("discount", NewInvoice.DiscountRC);
	InvoiceData.Insert("discount_percent", NewInvoice.DiscountPercent);
	InvoiceData.Insert("subtotal", NewInvoice.SubTotalRC);
	InvoiceData.Insert("shipping", NewInvoice.ShippingRC);

	Query = New Query("SELECT
	                  |	InvoiceLineItems.Product,
	                  |	InvoiceLineItems.Price,
	                  |	InvoiceLineItems.Quantity,
	                  |	InvoiceLineItems.LineTotal
	                  |FROM
	                  |	Document.SalesInvoice.LineItems AS InvoiceLineItems
	                  |WHERE
	                  |	InvoiceLineItems.Ref = &Invoice");
	Query.SetParameter("Invoice", NewInvoice.Ref);
	Result = Query.Execute().Choose();
	
	LineItems = New Array();
	
	While Result.Next() Do
		
		LineItem = New Map();
		LineItem.Insert("item_code", Result.Product.Code);
		LineItem.Insert("api_code", String(Result.Product.Ref.UUID()));
		LineItem.Insert("item_description", Result.Product.Description);
		LineItem.Insert("price", Result.Price);
		LineItem.Insert("quantity", Result.Quantity);
		//LineItem.Insert("taxable_amount", Result.TaxableAmount);
		LineItem.Insert("line_total", Result.LineTotal);
		//LineItem.Insert("taxable", Result.Taxable);
		//If Result.SalesTaxType = Enums.SalesTaxTypes.Taxable Then
		//	LineItem.Insert("taxable_type", "taxable");
		//ElsIf Result.SalesTaxType = Enums.SalesTaxTypes.NonTaxable Then
		//	LineItem.Insert("taxable_type", "non-taxable");
		//EndIf;
		LineItems.Add(LineItem);
		
	EndDo;
	
	LineItemsData = New Map();
	LineItemsData.Insert("line_items", LineItems);
	
	InvoiceData.Insert("lines", LineItemsData);
	
	jsonout = InternetConnectionClientServer.EncodeJSON(InvoiceData);
	
	Return jsonout;

	
EndFunction

Function inoutInvoicesUpdate(jsonin, object_code) Export
	
	SalesInvoiceNumberJSON = InternetConnectionClientServer.DecodeJSON(object_code);
	api_code = SalesInvoiceNumberJSON.object_code;
		
	XInvoice = Documents.SalesInvoice.GetRef(New UUID(api_code));	
	NewInvoice = XInvoice.GetObject();
	NewInvoice.LineItems.Clear();
	
	///
	
	ParsedJSON = InternetConnectionClientServer.DecodeJSON(jsonin);
		
	customer_api_code = ParsedJSON.customer_api_code;
	//CompanyCode = ParsedJSON.company_code;
	NewInvoice.Company = Catalogs.Companies.GetRef(New UUID(customer_api_code));
	ship_to_api_code = ParsedJSON.ship_to_api_code;
	//ShipToAddressCode = ParsedJSON.ship_to_address_code;
	// check if address belongs to company
	NewInvoice.ShipTo = Catalogs.Addresses.GetRef(New UUID(ship_to_api_code));
	// select the company's default shipping address
	
	NewInvoice.Date = ParsedJSON.date;
	NewInvoice.DueDate = ParsedJSON.due_date;
	NewInvoice.Terms = Catalogs.PaymentTerms.DueOnReceipt;
	
	//PaymentMethod = ParsedJSON.Get("payment_method");
	// support all payment methods
	//NewCashSale.PaymentMethod = Catalogs.PaymentMethods.Cash;
	Try
		NewInvoice.RefNum = ParsedJSON.ref_num;
	Except
	EndTry;
	Try
		NewInvoice.Memo = ParsedJSON.memo;
	Except
	EndTry;
	// tax rate - calculate from address?
	Try
		SalesTax = ParsedJSON.sales_tax_total; 
		NewInvoice.SalesTaxRC = ParsedJSON.sales_tax_total;		
	Except
		NewInvoice.SalesTaxRC = 0;
	EndTry;
	NewInvoice.DocumentTotal = ParsedJSON.doc_total;
	NewInvoice.DocumentTotalRC = ParsedJSON.doc_total;
    //NewCashSale.DepositType = "2";
	DefaultCurrency = Constants.DefaultCurrency.Get();
	NewInvoice.Currency = DefaultCurrency;
	NewInvoice.ARAccount = DefaultCurrency.DefaultARAccount;
	//NewCashSale.BankAccount = Constants.BankAccount.Get();
	NewInvoice.ExchangeRate = 1;
	NewInvoice.Location = Catalogs.Locations.MainWarehouse;
	Try NewInvoice.LineSubtotalRC = ParsedJSON.line_subtotal; Except EndTry;
	Try NewInvoice.DiscountRC = ParsedJSON.discount; Except EndTry;
	Try NewInvoice.DiscountPercent = ParsedJSON.discount_percent; Except EndTry;
	Try NewInvoice.SubTotalRC = ParsedJSON.subtotal; Except EndTry;
	Try NewInvoice.ShippingRC = ParsedJSON.shipping; Except EndTry;

	
	DataLineItems = ParsedJSON.lines.line_items;
	
	LineItemsRows = DataLineItems.Count();
	For i = 0 To LineItemsRows -1 Do
		
		NewLine = NewInvoice.LineItems.Add();
		
		Product = Catalogs.Products.GetRef(New UUID(DataLineItems[i].api_code));
		NewLine.Product = Product;
		NewLine.ProductDescription = Product.Description;
		//NewLine.VATCode = CommonUse.GetAttributeValue(Product, "SalesVATCode");
		//NewLine.VAT = 0;
		
		NewLine.Price = DataLineItems[i].price;
		NewLine.Quantity = DataLineItems[i].quantity;
		//Try NewLine.Taxable = DataLineItems[i].taxable; Except EndTry;
		// get taxable from JSON
		//Try
		//	TaxableType = DataLineItems[i].taxable_type;
		//	If TaxableType = "taxable" Then
		//		NewLine.SalesTaxType = Enums.SalesTaxTypes.Taxable;
		//	ElsIf TaxableType = "non-taxable" Then
		//		NewLine.SalesTaxType = Enums.SalesTaxTypes.NonTaxable;
		//	Else
		//		NewLine.SalesTaxType = Enums.SalesTaxTypes.NonTaxable;
		//	EndIf;
		//Except
		//	NewLine.SalesTaxType = Enums.SalesTaxTypes.NonTaxable;	
		//EndTry;
		
		NewLine.LineTotal = DataLineItems[i].line_total;
		//Try
		//	TaxableAmount = DataLineItems[i].taxable_amount;
		//	NewLine.TaxableAmount = TaxableAmount				
		//Except
		//	NewLine.TaxableAmount = 0;
		//EndTry;
				
	EndDo;
	
	NewInvoice.Write();
		
	///
	
	
	InvoiceData = New Map();
	InvoiceData.Insert("api_code", String(NewInvoice.Ref.UUID()));
	InvoiceData.Insert("customer_api_code", String(NewInvoice.Company.Ref.UUID()));
	InvoiceData.Insert("company_name", NewInvoice.Company.Description);
	InvoiceData.Insert("company_code", NewInvoice.Company.Code);
	InvoiceData.Insert("ship_to_api_code", String(NewInvoice.ShipTo.Ref.UUID()));
	InvoiceData.Insert("ship_to_address_id", NewInvoice.ShipTo.Description);
	// date - convert into the same format as input
	InvoiceData.Insert("invoice_number", NewInvoice.Number);
	// payment method - same as input
	//CashSaleData.Insert("payment_method", NewInvoice.PaymentMethod.Description);
	InvoiceData.Insert("date", NewInvoice.Date);
	InvoiceData.Insert("due_date", NewInvoice.DueDate);
	InvoiceData.Insert("ref_num", NewInvoice.RefNum);
	InvoiceData.Insert("memo", NewInvoice.Memo);
	InvoiceData.Insert("sales_tax_total", NewInvoice.SalesTaxRC);
	InvoiceData.Insert("doc_total", NewInvoice.DocumentTotalRC);
	InvoiceData.Insert("line_subtotal", NewInvoice.LineSubtotalRC);
	InvoiceData.Insert("discount", NewInvoice.DiscountRC);
	InvoiceData.Insert("discount_percent", NewInvoice.DiscountPercent);
	InvoiceData.Insert("subtotal", NewInvoice.SubTotalRC);
	InvoiceData.Insert("shipping", NewInvoice.ShippingRC);

	Query = New Query("SELECT
	                  |	InvoiceLineItems.Product,
	                  |	InvoiceLineItems.Price,
	                  |	InvoiceLineItems.Quantity,
	                  |	InvoiceLineItems.LineTotal
	                  |FROM
	                  |	Document.SalesInvoice.LineItems AS InvoiceLineItems
	                  |WHERE
	                  |	InvoiceLineItems.Ref = &Invoice");
	Query.SetParameter("Invoice", NewInvoice.Ref);
	Result = Query.Execute().Choose();
	
	LineItems = New Array();
	
	While Result.Next() Do
		
		LineItem = New Map();
		LineItem.Insert("item_code", Result.Product.Code);
		LineItem.Insert("api_code", String(Result.Product.Ref.UUID()));
		LineItem.Insert("item_description", Result.Product.Description);
		LineItem.Insert("price", Result.Price);
		LineItem.Insert("quantity", Result.Quantity);
		//LineItem.Insert("taxable_amount", Result.TaxableAmount);
		LineItem.Insert("line_total", Result.LineTotal);
		//LineItem.Insert("taxable", Result.Taxable);
		//If Result.SalesTaxType = Enums.SalesTaxTypes.Taxable Then
		//	LineItem.Insert("taxable_type", "taxable");
		//ElsIf Result.SalesTaxType = Enums.SalesTaxTypes.NonTaxable Then
		//	LineItem.Insert("taxable_type", "non-taxable");
		//EndIf;
		LineItems.Add(LineItem);
		
	EndDo;
	
	LineItemsData = New Map();
	LineItemsData.Insert("line_items", LineItems);
	
	InvoiceData.Insert("lines", LineItemsData);
	
	jsonout = InternetConnectionClientServer.EncodeJSON(InvoiceData);
	
	Return jsonout;


EndFunction

Function inoutInvoicesGet(jsonin) Export
	
	ParsedJSON = InternetConnectionClientServer.DecodeJSON(jsonin);
	api_code = ParsedJSON.object_code;
	
	Try
		NewInvoice = Documents.SalesInvoice.GetRef(New UUID(api_code));
	Except
		errorMessage = New Map();
		strMessage = " [api_code] : The sales invoice does not exist. Double check that the ID# is correct. ";
		errorMessage.Insert("message", strMessage);
		errorMessage.Insert("status", "error"); 
		errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
		return errorJSON;
	EndTry;
	
	SIQuery = New Query("SELECT
	                    |	SalesInvoice.Ref
	                    |FROM
	                    |	Document.SalesInvoice AS SalesInvoice
	                    |WHERE
	                    |	SalesInvoice.Ref = &Ref");
	SIQuery.SetParameter("Ref", NewInvoice);
	SIresult = SIQuery.Execute();
	If SIresult.IsEmpty() Then
			errorMessage = New Map();
			strMessage = " [api_code] : The sales order does not exist. Double check that the ID# is correct. ";
			errorMessage.Insert("message", strMessage);
			errorMessage.Insert("status", "error"); 
			errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
			return errorJSON;
	EndIf;
		
	InvoiceData = New Map();
	InvoiceData.Insert("api_code", String(NewInvoice.Ref.UUID()));
	InvoiceData.Insert("customer_api_code", String(NewInvoice.Company.Ref.UUID()));
	InvoiceData.Insert("company_name", NewInvoice.Company.Description);
	InvoiceData.Insert("company_code", NewInvoice.Company.Code);
	InvoiceData.Insert("ship_to_api_code", String(NewInvoice.ShipTo.Ref.UUID()));
	InvoiceData.Insert("ship_to_address_id", NewInvoice.ShipTo.Description);
	// date - convert into the same format as input
	InvoiceData.Insert("invoice_number", NewInvoice.Number);
	// payment method - same as input
	//CashSaleData.Insert("payment_method", NewInvoice.PaymentMethod.Description);
	InvoiceData.Insert("date", NewInvoice.Date);
	InvoiceData.Insert("due_date", NewInvoice.DueDate);
	InvoiceData.Insert("ref_num", NewInvoice.RefNum);
	InvoiceData.Insert("memo", NewInvoice.Memo);
	InvoiceData.Insert("sales_tax_total", NewInvoice.SalesTaxRC);
	InvoiceData.Insert("doc_total", NewInvoice.DocumentTotalRC);
	InvoiceData.Insert("line_subtotal", NewInvoice.LineSubtotalRC);
	InvoiceData.Insert("discount", NewInvoice.DiscountRC);
	InvoiceData.Insert("discount_percent", NewInvoice.DiscountPercent);
	InvoiceData.Insert("subtotal", NewInvoice.SubTotalRC);
	InvoiceData.Insert("shipping", NewInvoice.ShippingRC);

	Query = New Query("SELECT
	                  |	InvoiceLineItems.Product,
	                  |	InvoiceLineItems.Price,
	                  |	InvoiceLineItems.Quantity,
	                  |	InvoiceLineItems.LineTotal
	                  |FROM
	                  |	Document.SalesInvoice.LineItems AS InvoiceLineItems
	                  |WHERE
	                  |	InvoiceLineItems.Ref = &Invoice");
	Query.SetParameter("Invoice", NewInvoice.Ref);
	Result = Query.Execute().Choose();
	
	LineItems = New Array();
	
	While Result.Next() Do
		
		LineItem = New Map();
		LineItem.Insert("item_code", Result.Product.Code);
		LineItem.Insert("api_code", String(Result.Product.Ref.UUID()));
		LineItem.Insert("item_description", Result.Product.Description);
		LineItem.Insert("price", Result.Price);
		LineItem.Insert("quantity", Result.Quantity);
		//LineItem.Insert("taxable", Result.Taxable);
		//LineItem.Insert("taxable_amount", Result.TaxableAmount);
		LineItem.Insert("line_total", Result.LineTotal);
		//If Result.SalesTaxType = Enums.SalesTaxTypes.Taxable Then
		//	LineItem.Insert("taxable_type", "taxable");
		//ElsIf Result.SalesTaxType = Enums.SalesTaxTypes.NonTaxable Then
		//	LineItem.Insert("taxable_type", "non-taxable");
		//EndIf;
		LineItems.Add(LineItem);
		
	EndDo;
	
	LineItemsData = New Map();
	LineItemsData.Insert("line_items", LineItems);
	
	InvoiceData.Insert("lines", LineItemsData);
	
	jsonout = InternetConnectionClientServer.EncodeJSON(InvoiceData);
	
	Return jsonout;



EndFunction

Function inoutInvoicesDelete(jsonin) Export
	
	ParsedJSON = InternetConnectionClientServer.DecodeJSON(jsonin);
	api_code = ParsedJSON.object_code;
	
	SalesInvoice = Documents.SalesInvoice.GetRef(New UUID(api_code));
	
	SalesInvoiceObj = SalesInvoice.GetObject();
	invoiceNum = SalesInvoiceObj.Number;
	date = SalesInvoiceObj.Date;
	SetPrivilegedMode(True);
	Try
		SalesInvoiceObj.Delete();//.DeletionMark = True;
	Except
		errorMessage = New Map();
		strMessage = "Failed to delete. Invoice must be unposted before deletion and/or other objects are linked to this sales invoice.";
		errorMessage.Insert("message", strMessage);
		errorMessage.Insert("sales_invoice_number",invoiceNum);
		errorMessage.Insert("date", date);
		errorMessage.Insert("status", "error"); 
		errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
		return errorJSON;
	EndTry;
	SetPrivilegedMode(False);
	
	Output = New Map();	
	
	//Try
	//	SalesInvoiceObj.Write(DocumentWriteMode.UndoPosting);
		Output.Insert("status", "success");
		strMessage = "Invoice # " + invoiceNum + " from " + date + " has been deleted.";
		Output.Insert("message", strMessage);
	//Except
		//ErrorMessage = DetailErrorDescription(ErrorInfo());
	//	Output.Insert("error", "sales invoice can not be deleted");
	//EndTry;
	
	jsonout = InternetConnectionClientServer.EncodeJSON(Output);
	
	Return jsonout;

EndFunction

Function inoutInvoicesListAll(jsonin) Export
		
	Query = New Query("SELECT
	                  |	SalesInvoice.Ref,
	                  |	SalesInvoice.DataVersion,
	                  |	SalesInvoice.DeletionMark,
	                  |	SalesInvoice.Number,
	                  |	SalesInvoice.Date,
	                  |	SalesInvoice.Posted,
	                  |	SalesInvoice.Company,
	                  |	SalesInvoice.Currency,
	                  |	SalesInvoice.ExchangeRate,
	                  |	SalesInvoice.Location,
	                  |	SalesInvoice.DeliveryDate,
	                  |	SalesInvoice.DueDate,
	                  |	SalesInvoice.Terms,
	                  |	SalesInvoice.Memo,
	                  |	SalesInvoice.ARAccount,
	                  |	SalesInvoice.ShipTo,
	                  |	SalesInvoice.RefNum,
	                  |	SalesInvoice.BegBal,
	                  |	SalesInvoice.ManualAdjustment,
	                  |	SalesInvoice.Project,
	                  |	SalesInvoice.NewObject,
	                  |	SalesInvoice.LastEmail,
	                  |	SalesInvoice.Paid,
	                  |	SalesInvoice.EmailTo,
	                  |	SalesInvoice.EmailNote,
	                  |	SalesInvoice.PayHTML,
	                  |	SalesInvoice.EmailCC,
	                  |	SalesInvoice.PaidInvoice,
	                  |	SalesInvoice.BillTo,
	                  |	SalesInvoice.SalesPerson,
	                  |	SalesInvoice.CF1String,
	                  |	SalesInvoice.LineSubtotalRC,
	                  |	SalesInvoice.DiscountRC,
	                  |	SalesInvoice.SubTotalRC,
	                  |	SalesInvoice.ShippingRC,
	                  |	SalesInvoice.SalesTaxRC,
	                  |	SalesInvoice.DocumentTotal,
	                  |	SalesInvoice.DocumentTotalRC,
	                  |	SalesInvoice.DiscountPercent,
	                  |	SalesInvoice.FOB,
	                  |	SalesInvoice.Carrier,
	                  |	SalesInvoice.TrackingNumber,
	                  |	SalesInvoice.LineItems.(
	                  |		Ref,
	                  |		LineNumber,
	                  |		Product,
	                  |		ProductDescription,
	                  |		Price,
	                  |		Quantity,
	                  |		LineTotal,
	                  |		LineItems.Order,
	                  |		Project
	                  |	)
	                  |FROM
	                  |	Document.SalesInvoice AS SalesInvoice");
	Result = Query.Execute().Choose();
	
	Invoices = New Array();
	
	While Result.Next() Do
		
		Invoice = New Map();
		Invoice.Insert("api_code", String(Result.Ref.UUID()));
		Invoice.Insert("company_name", Result.Company.Description);
		Invoice.Insert("company_code", Result.Company.Code);
		Invoice.Insert("ship_to_address_code", Result.ShipTo.Code);
		Invoice.Insert("ship_to_address_id", Result.ShipTo.Description);
		// date - convert into the same format as input
		Invoice.Insert("invoice_number", Result.Number);
		// payment method - same format as input
		//CashSale.Insert("payment_method", Result.PaymentMethod.Description);
		// date - convert to input format
		Invoice.Insert("date", Result.Date);
		Invoice.Insert("due_date", Result.DueDate);
		Invoice.Insert("ref_num", Result.RefNum);
		Invoice.Insert("memo", Result.Memo);
		Invoice.Insert("sales_tax_total", Result.SalesTaxRC);
		Invoice.Insert("doc_total", Result.DocumentTotalRC);
		Invoice.Insert("line_subtotal", Result.LineSubtotalRC);
		Invoice.Insert("discount", Result.DiscountRC);
		Invoice.Insert("discount_percent", Result.DiscountPercent);
		Invoice.Insert("subtotal", Result.SubTotalRC);
		Invoice.Insert("shipping", Result.ShippingRC);
		
		Invoices.Add(Invoice);
		
	EndDo;
	
	InvoicesList = New Map();
	InvoicesList.Insert("invoices", Invoices);
	
	jsonout = InternetConnectionClientServer.EncodeJSON(InvoicesList);
	
	Return jsonout;


EndFunction


Function inoutSalesOrdersCreate(jsonin) Export
		
	ParsedJSON = InternetConnectionClientServer.DecodeJSON(jsonin);
		
	NewSO = Documents.SalesOrder.CreateDocument();
	//customer_api_code = ParsedJSON.customer_api_code;
	//NewSO.Company = Catalogs.Companies.GetRef(New UUID(customer_api_code));
	Try customer_api_code = ParsedJSON.customer_api_code Except customer_api_code = Undefined EndTry;
	If NOT customer_api_code = Undefined Then
		
		Try
		cust = Catalogs.Companies.GetRef(New UUID(customer_api_code));
		Except
			errorMessage = New Map();
			strMessage = " [customer_api_code] : The customer does not exist ";
			errorMessage.Insert("message", strMessage);
			errorMessage.Insert("status", "error"); 
			errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
			return errorJSON;
		EndTry;

	   // check if customer api code is valid
	   custQuery = New Query("SELECT
	   						 |	Companies.Ref
							 |FROM
							 |	Catalog.Companies AS Companies
							 |WHERE
							 |	Companies.Ref = &custCode");
		custQuery.SetParameter("custCode", cust);
		custResult = custQuery.Execute();
		If custResult.IsEmpty() Then
			errorMessage = New Map();
			strMessage = " [customer_api_code] : The customer does not exist ";
			errorMessage.Insert("status", "error"); 
			errorMessage.Insert("message", strMessage);
			errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
			return errorJSON;
		EndIf;					 
		NewSO.Company = cust;
	Else
		errorMessage = New Map();
		strMessage = " [customer_api_code] : This field is required ";
		errorMessage.Insert("status", "error"); 
		errorMessage.Insert("message", strMessage);
		errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
		return errorJSON;
		
		//customer_api_code = ParsedJSON.customer_api_code;
		//NewSO.Company = Catalogs.Companies.GetRef(New UUID(customer_api_code));

	EndIf;
	// SHIP TO ADDRESS SECTION
	
	//Try ship_to_api_code = ParsedJSON.ship_to_api_code Except ship_to_api_code = Undefined EndTry;
	//If NOT ship_to_api_code = Undefined Then
	//	// todo - check if address belongs to company
	//	NewSO.ShipTo = Catalogs.Addresses.GetRef(New UUID(ship_to_api_code));
	Try ship_to_api_code = ParsedJSON.ship_to_api_code Except ship_to_api_code = Undefined EndTry;
	If NOT ship_to_api_code = Undefined Then
	 
		//NewSO.ShipTo = Catalogs.Addresses.GetRef(New UUID(ship_to_api_code));

		Try addr = Catalogs.Addresses.GetRef(New UUID(ship_to_api_code)) Except addr = Undefined EndTry;
		
		newQuery = New Query("SELECT
		                     |	Addresses.Ref
		                     |FROM
		                     |	Catalog.Addresses AS Addresses
		                     |WHERE
		                     |	Addresses.Owner = &Customer
		                     |	AND Addresses.Ref = &addrCode");
							 
		newQuery.SetParameter("Customer", NewSO.Company);
		newQuery.SetParameter("addrCode", addr);
		addrResult = newQuery.Execute();
		If addrResult.IsEmpty() Then
			errorMessage = New Map();
			strMessage = " [ship_to_api_code] : Shipping Address does not belong to the Company ";
			errorMessage.Insert("status", "error"); 
			errorMessage.Insert("message", strMessage);
			errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
			return errorJSON;
		EndIf;
		NewSO.ShipTO = addr;
		
	Else
		
		Query = New Query("SELECT
		                  |	Addresses.Ref
		                  |FROM
		                  |	Catalog.Addresses AS Addresses
		                  |WHERE
		                  |	Addresses.Owner = &Customer
		                  |	AND Addresses.AddressLine1 = &AddressLine1
		                  |	AND Addresses.AddressLine2 = &AddressLine2
		                  |	AND Addresses.City = &City
		                  |	AND Addresses.State = &State
		                  |	AND Addresses.ZIP = &ZIP
		                  |	AND Addresses.Country = &Country");
		Query.SetParameter("Customer", NewSO.Company);
		
		Try ship_to_address_line1 = ParsedJSON.ship_to_address_line1 Except ship_to_address_line1 = Undefined EndTry;
		If NOT ship_to_address_line1 = Undefined Then
			Query.SetParameter("AddressLine1", ship_to_address_line1);
		Else
			Query.SetParameter("AddressLine1", "");
		EndIf;
		
		Try ship_to_address_line2 = ParsedJSON.ship_to_address_line2 Except ship_to_address_line2 = Undefined EndTry;
		If NOT ship_to_address_line2 = Undefined Then
			Query.SetParameter("AddressLine2", ship_to_address_line2);
		Else
			Query.SetParameter("AddressLine2", "");
		EndIf;
		
		Try ship_to_city = ParsedJSON.ship_to_city Except ship_to_city = Undefined EndTry;
		If NOT ship_to_city = Undefined Then
			Query.SetParameter("City", ship_to_city);
		Else
			Query.SetParameter("City", "");
		EndIf;
		
		Try ship_to_zip = ParsedJSON.ship_to_zip Except ship_to_zip = Undefined EndTry;
		If NOT ship_to_zip = Undefined Then
			Query.SetParameter("ZIP", ship_to_zip);
		Else
			Query.SetParameter("ZIP", "");
		EndIf;
		
		Try ship_to_state = ParsedJSON.ship_to_state Except ship_to_state = Undefined EndTry;
		If NOT ship_to_state = Undefined Then
			Query.SetParameter("State", Catalogs.States.FindByCode(ship_to_state));
		Else
			Query.SetParameter("State", Catalogs.States.EmptyRef());
		EndIf;
		
		Try ship_to_country = ParsedJSON.ship_to_country Except ship_to_country = Undefined EndTry;
		If NOT ship_to_country = Undefined Then
			Query.SetParameter("Country", Catalogs.Countries.FindByCode(ship_to_country));
		Else
			Query.SetParameter("Country", Catalogs.Countries.EmptyRef());
		EndIf;
		
		QueryResult = Query.Execute();
		
		If QueryResult.IsEmpty() Then
			// create new address		
			AddressLine = Catalogs.Addresses.CreateItem();
			AddressLine.Owner = NewSO.Company;

			Try
				AddressLine.Description = ParsedJSON.ship_to_address_id;
			Except
				// generate "ShipTo_" + five random characters address ID

				PasswordLength = 5;
				SymbolString = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"; //62
				RandomChars5 = "";
				RNG = New RandomNumberGenerator;	
				For i = 0 to PasswordLength-1 Do
					RN = RNG.RandomNumber(1, 62);
					RandomChars5 = RandomChars5 + Mid(SymbolString,RN,1);
				EndDo;

				AddressLine.Description = "ShipTo_" + RandomChars5;
			EndTry;
			
			Try	AddressLine.FirstName = ParsedJSON.ship_to_first_name; Except EndTry;			
			Try AddressLine.MiddleName = ParsedJSON.ship_to_middle_name; Except EndTry;			
			Try AddressLine.LastName = ParsedJSON.ship_to_last_name; Except EndTry;				
			Try AddressLine.Phone = ParsedJSON.ship_to_phone; Except EndTry;			
			Try AddressLine.Cell = ParsedJSON.ship_to_cell; Except EndTry;			
			Try AddressLine.Email = ParsedJSON.ship_to_email; Except EndTry;			
			Try AddressLine.AddressLine1 = ParsedJSON.ship_to_address_line1; Except EndTry;			
			Try	AddressLine.AddressLine2 = ParsedJSON.ship_to_address_line2; Except EndTry;			
			Try	AddressLine.City = ParsedJSON.ship_to_city; Except EndTry;
			Try AddressLine.State = Catalogs.States.FindByCode(ParsedJSON.ship_to_state); Except EndTry;			
			Try AddressLine.Country = Catalogs.Countries.FindByCode(ParsedJSON.ship_to_country); Except EndTry;			
			Try AddressLine.ZIP = ParsedJSON.ship_to_zip; Except EndTry;
			Try	AddressLine.Notes = ParsedJSON.ship_to_notes; Except EndTry;			
			Try AddressLine.SalesTaxCode = Catalogs.SalesTaxCodes.FindByCode(ParsedJSON.ship_to_sales_tax_code); Except EndTry;			
			
			AddressLine.Write();
			NewSO.ShipTo = AddressLine.Ref;
			
		Else
			// select first address in the dataset
			Dataset = QueryResult.Unload();
			NewSO.ShipTo = Dataset[0].Ref; 
		EndIf

	EndIf;
	
	// BILL TO ADDRESS SECTION
	
	Try bill_to_api_code = ParsedJSON.bill_to_api_code Except bill_to_api_code = Undefined EndTry;
	If NOT bill_to_api_code = Undefined Then
		// todo - check if address belongs to company
		//NewSO.BillTo = Catalogs.Addresses.GetRef(New UUID(bill_to_api_code));
		Try addrBill = Catalogs.Addresses.GetRef(New UUID(bill_to_api_code)) Except addrBill = Undefined EndTry;
		
		newQuery = New Query("SELECT
		                     |	Addresses.Ref
		                     |FROM
		                     |	Catalog.Addresses AS Addresses
		                     |WHERE
		                     |	Addresses.Owner = &Customer
		                     |	AND Addresses.Ref = &addrCode");
							 
		newQuery.SetParameter("Customer", NewSO.Company);
		newQuery.SetParameter("addrCode", addrBill);
		billResult = newQuery.Execute();
		If billResult.IsEmpty() Then
			errorMessage = New Map();
			strMessage = " [bill_to_api_code] : Billing Address does not belong to the Company " ;
			errorMessage.Insert("status", "error");
			errorMessage.Insert("message", strMessage );
			errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
			return errorJSON;
		EndIf;
		NewSO.BillTo = addrBill;
		
	Else
		
		Query = New Query("SELECT
		                  |	Addresses.Ref
		                  |FROM
		                  |	Catalog.Addresses AS Addresses
		                  |WHERE
		                  |	Addresses.Owner = &Customer
		                  |	AND Addresses.AddressLine1 = &AddressLine1
		                  |	AND Addresses.AddressLine2 = &AddressLine2
		                  |	AND Addresses.City = &City
		                  |	AND Addresses.State = &State
		                  |	AND Addresses.ZIP = &ZIP
		                  |	AND Addresses.Country = &Country");
		Query.SetParameter("Customer", NewSO.Company);
		
		Try bill_to_address_line1 = ParsedJSON.bill_to_address_line1 Except bill_to_address_line1 = Undefined EndTry;
		If NOT bill_to_address_line1 = Undefined Then
			Query.SetParameter("AddressLine1", bill_to_address_line1);
		Else
			Query.SetParameter("AddressLine1", "");
		EndIf;
		
		Try bill_to_address_line2 = ParsedJSON.bill_to_address_line2 Except bill_to_address_line2 = Undefined EndTry;
		If NOT bill_to_address_line2 = Undefined Then
			Query.SetParameter("AddressLine2", bill_to_address_line2);
		Else
			Query.SetParameter("AddressLine2", "");
		EndIf;
		
		Try bill_to_city = ParsedJSON.bill_to_city Except bill_to_city = Undefined EndTry;
		If NOT bill_to_city = Undefined Then
			Query.SetParameter("City", bill_to_city);
		Else
			Query.SetParameter("City", "");
		EndIf;
		
		Try bill_to_zip = ParsedJSON.bill_to_zip Except bill_to_zip = Undefined EndTry;
		If NOT bill_to_zip = Undefined Then
			Query.SetParameter("ZIP", bill_to_zip);
		Else
			Query.SetParameter("ZIP", "");
		EndIf;
		
		Try bill_to_state = ParsedJSON.bill_to_state Except bill_to_state = Undefined EndTry;
		If NOT bill_to_state = Undefined Then
			Query.SetParameter("State", Catalogs.States.FindByCode(bill_to_state));
		Else
			Query.SetParameter("State", Catalogs.States.EmptyRef());
		EndIf;
		
		Try bill_to_country = ParsedJSON.bill_to_country Except bill_to_country = Undefined EndTry;
		If NOT bill_to_country = Undefined Then
			Query.SetParameter("Country", Catalogs.Countries.FindByCode(bill_to_country));
		Else
			Query.SetParameter("Country", Catalogs.Countries.EmptyRef());
		EndIf;
		
		QueryResult = Query.Execute();
		
		If QueryResult.IsEmpty() Then
			// create new address		
			AddressLine = Catalogs.Addresses.CreateItem();
			AddressLine.Owner = NewSO.Company;

			Try
				AddressLine.Description = ParsedJSON.bill_to_address_id;
			Except
				// generate "BillTo_" + five random characters address ID

				PasswordLength = 5;
				SymbolString = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"; //62
				RandomChars5 = "";
				RNG = New RandomNumberGenerator;	
				For i = 0 to PasswordLength-1 Do
					RN = RNG.RandomNumber(1, 62);
					RandomChars5 = RandomChars5 + Mid(SymbolString,RN,1);
				EndDo;

				AddressLine.Description = "BillTo_" + RandomChars5;
			EndTry;
			
			Try	AddressLine.FirstName = ParsedJSON.bill_to_first_name; Except EndTry;			
			Try AddressLine.MiddleName = ParsedJSON.bill_to_middle_name; Except EndTry;			
			Try AddressLine.LastName = ParsedJSON.bill_to_last_name; Except EndTry;				
			Try AddressLine.Phone = ParsedJSON.bill_to_phone; Except EndTry;			
			Try AddressLine.Cell = ParsedJSON.bill_to_cell; Except EndTry;			
			Try AddressLine.Email = ParsedJSON.bill_to_email; Except EndTry;			
			Try AddressLine.AddressLine1 = ParsedJSON.bill_to_address_line1; Except EndTry;			
			Try	AddressLine.AddressLine2 = ParsedJSON.bill_to_address_line2; Except EndTry;			
			Try	AddressLine.City = ParsedJSON.bill_to_city; Except EndTry;
			Try AddressLine.State = Catalogs.States.FindByCode(ParsedJSON.bill_to_state); Except EndTry;			
			Try AddressLine.Country = Catalogs.Countries.FindByCode(ParsedJSON.bill_to_country); Except EndTry;			
			Try AddressLine.ZIP = ParsedJSON.bill_to_zip; Except EndTry;
			Try	AddressLine.Notes = ParsedJSON.bill_to_notes; Except EndTry;			
			Try AddressLine.SalesTaxCode = Catalogs.SalesTaxCodes.FindByCode(ParsedJSON.bill_to_sales_tax_code); Except EndTry;			
			
			AddressLine.Write();
			NewSO.BillTo = AddressLine.Ref;
			
		Else
			// select first address in the dataset
			Dataset = QueryResult.Unload();
			NewSO.BillTo = Dataset[0].Ref;
		EndIf

	EndIf;
	
	// END BILL TO ADDRESS SECTION
	
	Try date = ParsedJSON.date Except date = Undefined EndTry;
	If date = Undefined Then
		errorMessage = New Map();
		strMessage = " [date] : This field is required ";
		errorMessage.Insert("message", strMessage);
		errorMessage.Insert("status", "error"); 
		errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
		return errorJSON;
	EndIf;
	NewSO.Date = "01/22/2013"; // creating a failed date
	wrongDate = NewSO.Date;
	NewSO.Date = ParsedJSON.date;
	If NewSO.Date = wrongDate Then
		errorMessage = New Map();
		strMessage = " [date] : Date must be in the format of YYYY-MM-DD ";
		errorMessage.Insert("message", strMessage);
		errorMessage.Insert("status", "error"); 
		errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
		return errorJSON;
	EndIf;
	
	NewSO.Date = ParsedJSON.date;
	//NewSO.DueDate = ParsedJSON.due_date;
	//NewSO.Terms = Catalogs.PaymentTerms.DueOnReceipt;
	
	//PaymentMethod = ParsedJSON.Get("payment_method");
	// support all payment methods
	//NewCashSale.PaymentMethod = Catalogs.PaymentMethods.Cash;
	Try
		NewSO.RefNum = ParsedJSON.ref_num;
	Except
	EndTry;
	
	Try
		NewSO.CF1String = ParsedJSON.cf1_string;
	Except
	EndTry;	
	
	Try
		NewSO.Memo = ParsedJSON.memo;
	Except
	EndTry;
	// tax rate - calculate from address?
	Try
		SalesTax = ParsedJSON.sales_tax_total; 
		NewSO.SalesTaxRC = ParsedJSON.sales_tax_total;		
	Except
		NewSO.SalesTaxRC = 0;
	EndTry;
	
	Try doc_total = ParsedJSON.doc_total Except doc_total = Undefined EndTry;
	If doc_total = Undefined Then
		errorMessage = New Map();
		strMessage = " [doc_total] : This field is required " ;
		errorMessage.Insert("status", "error");
		errorMessage.Insert("message", strMessage );
		errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
		return errorJSON;
	EndIf;
	NewSO.DocumentTotal = doc_total;
	NewSO.DocumentTotalRC = doc_total;
	
	//NewCashSale.DepositType = "2";
	DefaultCurrency = Constants.DefaultCurrency.Get();
	NewSO.Currency = DefaultCurrency;
	//NewSO.ARAccount = DefaultCurrency.DefaultARAccount;
	//NewCashSale.BankAccount = Constants.BankAccount.Get();
	NewSO.ExchangeRate = 1;
	NewSO.Location = Catalogs.Locations.MainWarehouse;
	
	Try NewSO.LineSubtotalRC = ParsedJSON.line_subtotal; Except EndTry;
	Try NewSO.DiscountRC = ParsedJSON.discount; Except EndTry;
	Try NewSO.DiscountPercent = ParsedJSON.discount_percent; Except EndTry;
	Try NewSO.SubTotalRC = ParsedJSON.subtotal; Except EndTry;
	Try NewSO.ShippingRC = ParsedJSON.shipping; Except EndTry;
	
	//DataLineItems = ParsedJSON.lines.line_items;
	
	Try DataLineItems = ParsedJSON.lines.line_items Except DataLineItems = Undefined EndTry;
	If DataLineItems = Undefined Then
		errorMessage = New Map();
		strMessage = " [lines] : Must enter at least one line with correct line items " ;
		errorMessage.Insert("status", "error");
		errorMessage.Insert("message", strMessage );
		errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
		return errorJSON;
	EndIf;
	
	doc_total_test = 0;
	
	LineItemsRows = DataLineItems.Count();
	For i = 0 To LineItemsRows -1 Do
		
		NewLine = NewSO.LineItems.Add();
		
		//Product = Catalogs.Products.GetRef(New UUID(DataLineItems[i].api_code));
		//NewLine.Product = Product;
		
		Try Product = Catalogs.Products.GetRef(New UUID(DataLineItems[i].api_code)) Except Product = Undefined EndTry;
			Try apiCode = DataLineItems[i].api_code Except apiCode = Undefined EndTry;
		If NOT Product = Undefined Or NOT apiCode = Undefined Then
		    itemsQuery = New Query("SELECT
		                         	|	Products.Ref
		                         	|FROM
								 	|	Catalog.Products AS Products
			                     	|WHERE
			                     	|	Products.Ref = &items");
			itemsQuery.SetParameter("items", Product);
			itemsResult = itemsQuery.Execute();
			If itemsResult.IsEmpty() Then
				errorMessage = New Map();
				strMessage = " [line_items(" + string(i+1) + ").api_code] : Item does not exist" ;
				errorMessage.Insert("status", "error");
				errorMessage.Insert("message", strMessage );
				errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
				return errorJSON;
			EndIf;	
			NewLine.Product = Product;
		Else
			errorMessage = New Map();
			strMessage = " [line_items(" + string(i+1) + ").api_code] : Item code is missing. This is a required field for lines " ;
			errorMessage.Insert("status", "error");
			errorMessage.Insert("message", strMessage );
			errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
			return errorJSON;
		EndIf;
		
		NewLine.ProductDescription = Product.Description;
		//NewLine.VATCode = CommonUse.GetAttributeValue(Product, "SalesVATCode");
		//NewLine.VAT = 0;
		
		//NewLine.Price = DataLineItems[i].price;
		Try price = DataLineItems[i].price Except price = Undefined EndTry;
		If NOT price = Undefined Then
			NewLine.Price = price;
		Else
			errorMessage = New Map();
			strMessage = " [line_items(" + string(i+1) + ").price] : This is a required field for lines " ;
			errorMessage.Insert("status", "error");
			errorMessage.Insert("message", strMessage );
			errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
			return errorJSON;
		EndIf;
		
		//NewLine.Quantity = DataLineItems[i].quantity;
		Try quantity = DataLineItems[i].quantity Except quantity = Undefined EndTry;
		If NOT quantity = Undefined Then
			NewLine.Quantity = quantity;
		Else
			errorMessage = New Map();
			strMessage = " [line_items(" + string(i+1) + ").quantity] : This is a required field for lines " ;
			errorMessage.Insert("status", "error");
			errorMessage.Insert("message", strMessage );
			errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
			return errorJSON;
		EndIf;
		
		//Try NewLine.Taxable = DataLineItems[i].taxable Except EndTry;
		
		// get taxable from JSON
		//Try
		//	TaxableType = DataLineItems[i].taxable_type;
		//	If TaxableType = "taxable" Then
		//		NewLine.SalesTaxType = Enums.SalesTaxTypes.Taxable;
		//	ElsIf TaxableType = "non-taxable" Then
		//		NewLine.SalesTaxType = Enums.SalesTaxTypes.NonTaxable;
		//	Else
		//		NewLine.SalesTaxType = Enums.SalesTaxTypes.NonTaxable;
		//	EndIf;
		//Except
		//	NewLine.SalesTaxType = Enums.SalesTaxTypes.NonTaxable;	
		//EndTry;
		
		//NewLine.LineTotal = DataLineItems[i].line_total;
		Try linetotal = DataLineItems[i].line_total Except linetotal = Undefined EndTry;
		If NOT quantity = Undefined Then
			NewLine.LineTotal = linetotal;
		Else
			errorMessage = New Map();
			strMessage = " [line_items(" + string(i+1) + ").line_total] : This is a required field for lines " ;
			errorMessage.Insert("status", "error");
			errorMessage.Insert("message", strMessage );
			errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
			return errorJSON;
		EndIf;
		
		If NewLine.LineTotal <> (NewLine.Quantity * NewLine.Price) Then
			errorMessage = New Map();
			strMessage = " [line_items(" + string(i+1) + ").line_total] : Line item's total does not match quantity * price " ;
			errorMessage.Insert("status", "error");
			errorMessage.Insert("message", strMessage );
			errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
			return errorJSON;
		EndIf;
		
		doc_total_test = doc_total_test + NewLine.LineTotal;
		
		//Try
		//	TaxableAmount = DataLineItems[i].taxable_amount;
		//	NewLine.TaxableAmount = TaxableAmount				
		//Except
		//	NewLine.TaxableAmount = 0;
		//EndTry;
				
	EndDo;
	
	// leaving out this test because of the added discounts and shipping attributes
	//If doc_total_test <> NewSO.DocumentTotal Then
	//	errorMessage = New Map();
	//	strMessage = " [doc_total] : The document total and sum of lineitem totals are not equal " ;
	//	errorMessage.Insert("status", "error");
	//	errorMessage.Insert("message", strMessage );
	//	errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
	//	return errorJSON;
	//EndIf;
	
	NewSO.Write(DocumentWriteMode.Posting);
	
	///
	
	
	//SOData = New Map();
	//SOData.Insert("api_code", String(NewSO.Ref.UUID()));
	//SOData.Insert("customer_api_code", String(NewSO.Company.Ref.UUID()));
	//SOData.Insert("customer_name", NewSO.Company.Description);
	//SOData.Insert("customer_code", NewSO.Company.Code);
	//SOData.Insert("ship_to_api_code", String(NewSO.ShipTo.Ref.UUID()));
	////SOData.Insert("ship_to_address_code", NewSO.ShipTo.Code);
	//SOData.Insert("ship_to_address_id", NewSO.ShipTo.Description);
	//// date - convert into the same format as input
	//SOData.Insert("so_number", NewSO.Number);
	//SOData.Insert("cf1_string", NewSO.CF1String);
	//// payment method - same as input
	////CashSaleData.Insert("payment_method", NewInvoice.PaymentMethod.Description);
	//SOData.Insert("date", NewSO.Date);
	////SOData.Insert("due_date", NewSO.DueDate);
	//SOData.Insert("ref_num", NewSO.RefNum);
	//SOData.Insert("memo", NewSO.Memo);
	//SOData.Insert("sales_tax_total", NewSO.SalesTax);
	//SOData.Insert("doc_total", NewSO.DocumentTotalRC);

	//Query = New Query("SELECT
	//				  |	SOLineItems.Product,
	//				  |	SOLineItems.Price,
	//				  |	SOLineItems.Quantity,
	//				  |	SOLineItems.LineTotal,
	//				  |	SOLineItems.SalesTaxType,
	//				  |	SOLineItems.TaxableAmount
	//				  |FROM
	//				  |	Document.SalesOrder.LineItems AS SOLineItems
	//				  |WHERE
	//				  |	SOLineItems.Ref = &SO");
	//Query.SetParameter("SO", NewSO.Ref);
	//Result = Query.Execute().Choose();
	//
	//LineItems = New Array();
	//
	//While Result.Next() Do
	//	
	//	LineItem = New Map();
	//	LineItem.Insert("item_code", Result.Product.Code);
	//	LineItem.Insert("api_code", String(Result.Product.Ref.UUID()));
	//	LineItem.Insert("item_description", Result.Product.Description);
	//	LineItem.Insert("price", Result.Price);
	//	LineItem.Insert("quantity", Result.Quantity);
	//	LineItem.Insert("taxable_amount", Result.TaxableAmount);
	//	LineItem.Insert("line_total", Result.LineTotal);
	//	If Result.SalesTaxType = Enums.SalesTaxTypes.Taxable Then
	//		LineItem.Insert("taxable_type", "taxable");
	//	ElsIf Result.SalesTaxType = Enums.SalesTaxTypes.NonTaxable Then
	//		LineItem.Insert("taxable_type", "non-taxable");
	//	EndIf;
	//	LineItems.Add(LineItem);
	//	
	//EndDo;
	//
	//LineItemsData = New Map();
	//LineItemsData.Insert("line_items", LineItems);
	//
	//SOData.Insert("lines", LineItemsData);
	
	
	jsonout = InternetConnectionClientServer.EncodeJSON(GeneralFunctions.ReturnSaleOrderMap(NewSO.Ref));
	
	Return jsonout;
	
EndFunction

Function inoutSalesOrdersUpdate(jsonin, object_code) Export
	
	SONumberJSON = InternetConnectionClientServer.DecodeJSON(object_code);
	//api_code = SONumberJSON.object_code;
		
	Try api_code = SONumberJSON.object_code Except api_code = Undefined EndTry;
	If api_code = Undefined  OR api_code = "" Then
		errorMessage = New Map();
		strMessage = " [api_code] : Missing sales order ID# ";
		errorMessage.Insert("message", strMessage);
		errorMessage.Insert("status", "error"); 
		errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
		return errorJSON;
	EndIf;
	
	Try
		XSO = Documents.SalesOrder.GetRef(New UUID(api_code));
	Except
		errorMessage = New Map();
		strMessage = " [api_code] : The sales order does not exist. Double check that the ID# is correct. ";
		errorMessage.Insert("message", strMessage);
		errorMessage.Insert("status", "error"); 
		errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
		return errorJSON;
	EndTry;

		
	
	SOQuery = New Query("SELECT
	                    |	SalesOrder.Ref
	                    |FROM
	                    |	Document.SalesOrder AS SalesOrder
	                    |WHERE
	                    |	SalesOrder.Ref = &so");
	SOQuery.SetParameter("so", XSO);
	SOresult = SOQuery.Execute();
	If SOresult.IsEmpty() Then
			errorMessage = New Map();
			strMessage = " [api_code] : The sales order does not exist. Double check that the ID# is correct. ";
			errorMessage.Insert("message", strMessage);
			errorMessage.Insert("status", "error"); 
			errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
			return errorJSON;
	EndIf;


	
	NewSO = XSO.GetObject();
	NewSO.LineItems.Clear();
	
	//
	
	ParsedJSON = InternetConnectionClientServer.DecodeJSON(jsonin);
	
	Try customer_api_code = ParsedJSON.customer_api_code Except customer_api_code = Undefined EndTry;
	If NOT customer_api_code = Undefined Then
		
		Try
		cust = Catalogs.Companies.GetRef(New UUID(customer_api_code));
		Except
			errorMessage = New Map();
			strMessage = " [customer_api_code] : The customer does not exist ";
			errorMessage.Insert("message", strMessage);
			errorMessage.Insert("status", "error"); 
			errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
			return errorJSON;
		EndTry;

	   // check if customer api code is valid
	   custQuery = New Query("SELECT
	   						 |	Companies.Ref
							 |FROM
							 |	Catalog.Companies AS Companies
							 |WHERE
							 |	Companies.Ref = &custCode");
		custQuery.SetParameter("custCode", cust);
		custResult = custQuery.Execute();
		If custResult.IsEmpty() Then
			errorMessage = New Map();
			strMessage = " [customer_api_code] : The customer does not exist ";
			errorMessage.Insert("status", "error"); 
			errorMessage.Insert("message", strMessage);
			errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
			return errorJSON;
		EndIf;					 
		NewSO.Company = cust;
	Else
		errorMessage = New Map();
		strMessage = " [customer_api_code] : This field is required ";
		errorMessage.Insert("status", "error"); 
		errorMessage.Insert("message", strMessage);
		errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
		return errorJSON;
		
		//customer_api_code = ParsedJSON.customer_api_code;
		//NewSO.Company = Catalogs.Companies.GetRef(New UUID(customer_api_code));

	EndIf;
		
	////NewSO = Documents.SalesOrder.CreateDocument();
	//customer_api_code = ParsedJSON.customer_api_code;
	//NewSO.Company = Catalogs.Companies.GetRef(New UUID(customer_api_code));
	
	// SHIP TO ADDRESS SECTION
	
	//Try ship_to_api_code = ParsedJSON.ship_to_api_code Except ship_to_api_code = Undefined EndTry;
	//If NOT ship_to_api_code = Undefined Then
	//	// todo - check if address belongs to company
	//	NewSO.ShipTo = Catalogs.Addresses.GetRef(New UUID(ship_to_api_code));
	//Else
	
	Try ship_to_api_code = ParsedJSON.ship_to_api_code Except ship_to_api_code = Undefined EndTry;
	If NOT ship_to_api_code = Undefined Then
	 
		//NewSO.ShipTo = Catalogs.Addresses.GetRef(New UUID(ship_to_api_code));

		Try addr = Catalogs.Addresses.GetRef(New UUID(ship_to_api_code)) Except addr = Undefined EndTry;
		
		newQuery = New Query("SELECT
		                     |	Addresses.Ref
		                     |FROM
		                     |	Catalog.Addresses AS Addresses
		                     |WHERE
		                     |	Addresses.Owner = &Customer
		                     |	AND Addresses.Ref = &addrCode");
							 
		newQuery.SetParameter("Customer", NewSO.Company);
		newQuery.SetParameter("addrCode", addr);
		addrResult = newQuery.Execute();
		If addrResult.IsEmpty() Then
			errorMessage = New Map();
			strMessage = " [ship_to_api_code] : Shipping Address does not belong to the Company ";
			errorMessage.Insert("status", "error"); 
			errorMessage.Insert("message", strMessage);
			errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
			return errorJSON;
		EndIf;
		NewSO.ShipTO = addr;
		
	Else
		
		Query = New Query("SELECT
		                  |	Addresses.Ref
		                  |FROM
		                  |	Catalog.Addresses AS Addresses
		                  |WHERE
		                  |	Addresses.Owner = &Customer
		                  |	AND Addresses.AddressLine1 = &AddressLine1
		                  |	AND Addresses.AddressLine2 = &AddressLine2
		                  |	AND Addresses.City = &City
		                  |	AND Addresses.State = &State
		                  |	AND Addresses.ZIP = &ZIP
		                  |	AND Addresses.Country = &Country");
		Query.SetParameter("Customer", NewSO.Company);
		
		Try ship_to_address_line1 = ParsedJSON.ship_to_address_line1 Except ship_to_address_line1 = Undefined EndTry;
		If NOT ship_to_address_line1 = Undefined Then
			Query.SetParameter("AddressLine1", ship_to_address_line1);
		Else
			Query.SetParameter("AddressLine1", "");
		EndIf;
		
		Try ship_to_address_line2 = ParsedJSON.ship_to_address_line2 Except ship_to_address_line2 = Undefined EndTry;
		If NOT ship_to_address_line2 = Undefined Then
			Query.SetParameter("AddressLine2", ship_to_address_line2);
		Else
			Query.SetParameter("AddressLine2", "");
		EndIf;
		
		Try ship_to_city = ParsedJSON.ship_to_city Except ship_to_city = Undefined EndTry;
		If NOT ship_to_city = Undefined Then
			Query.SetParameter("City", ship_to_city);
		Else
			Query.SetParameter("City", "");
		EndIf;
		
		Try ship_to_zip = ParsedJSON.ship_to_zip Except ship_to_zip = Undefined EndTry;
		If NOT ship_to_zip = Undefined Then
			Query.SetParameter("ZIP", ship_to_zip);
		Else
			Query.SetParameter("ZIP", "");
		EndIf;
		
		Try ship_to_state = ParsedJSON.ship_to_state Except ship_to_state = Undefined EndTry;
		If NOT ship_to_state = Undefined Then
			Query.SetParameter("State", Catalogs.States.FindByCode(ship_to_state));
		Else
			Query.SetParameter("State", Catalogs.States.EmptyRef());
		EndIf;
		
		Try ship_to_country = ParsedJSON.ship_to_country Except ship_to_country = Undefined EndTry;
		If NOT ship_to_country = Undefined Then
			Query.SetParameter("Country", Catalogs.Countries.FindByCode(ship_to_country));
		Else
			Query.SetParameter("Country", Catalogs.Countries.EmptyRef());
		EndIf;
		
		QueryResult = Query.Execute();
		
		If QueryResult.IsEmpty() Then
			// create new address		
			AddressLine = Catalogs.Addresses.CreateItem();
			AddressLine.Owner = NewSO.Company;

			Try
				AddressLine.Description = ParsedJSON.ship_to_address_id;
			Except
				// generate "ShipTo_" + five random characters address ID

				PasswordLength = 5;
				SymbolString = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"; //62
				RandomChars5 = "";
				RNG = New RandomNumberGenerator;	
				For i = 0 to PasswordLength-1 Do
					RN = RNG.RandomNumber(1, 62);
					RandomChars5 = RandomChars5 + Mid(SymbolString,RN,1);
				EndDo;

				AddressLine.Description = "ShipTo_" + RandomChars5;
			EndTry;
			
			Try	AddressLine.FirstName = ParsedJSON.ship_to_first_name; Except EndTry;			
			Try AddressLine.MiddleName = ParsedJSON.ship_to_middle_name; Except EndTry;			
			Try AddressLine.LastName = ParsedJSON.ship_to_last_name; Except EndTry;				
			Try AddressLine.Phone = ParsedJSON.ship_to_phone; Except EndTry;			
			Try AddressLine.Cell = ParsedJSON.ship_to_cell; Except EndTry;			
			Try AddressLine.Email = ParsedJSON.ship_to_email; Except EndTry;			
			Try AddressLine.AddressLine1 = ParsedJSON.ship_to_address_line1; Except EndTry;			
			Try	AddressLine.AddressLine2 = ParsedJSON.ship_to_address_line2; Except EndTry;			
			Try	AddressLine.City = ParsedJSON.ship_to_city; Except EndTry;
			Try AddressLine.State = Catalogs.States.FindByCode(ParsedJSON.ship_to_state); Except EndTry;			
			Try AddressLine.Country = Catalogs.Countries.FindByCode(ParsedJSON.ship_to_country); Except EndTry;			
			Try AddressLine.ZIP = ParsedJSON.ship_to_zip; Except EndTry;
			Try	AddressLine.Notes = ParsedJSON.ship_to_notes; Except EndTry;			
			Try AddressLine.SalesTaxCode = Catalogs.SalesTaxCodes.FindByCode(ParsedJSON.ship_to_sales_tax_code); Except EndTry;			
			
			AddressLine.Write();
			NewSO.ShipTo = AddressLine.Ref;
			
		Else
			// select first address in the dataset
			Dataset = QueryResult.Unload();
			NewSO.ShipTo = Dataset[0].Ref; 
		EndIf

	EndIf;
	
	// BILL TO ADDRESS SECTION
	
	//Try bill_to_api_code = ParsedJSON.bill_to_api_code Except bill_to_api_code = Undefined EndTry;
	//If NOT bill_to_api_code = Undefined Then
	//	// todo - check if address belongs to company
	//	NewSO.BillTo = Catalogs.Addresses.GetRef(New UUID(bill_to_api_code));
	//Else
	
	Try bill_to_api_code = ParsedJSON.bill_to_api_code Except bill_to_api_code = Undefined EndTry;
	If NOT bill_to_api_code = Undefined Then

		Try addrBill = Catalogs.Addresses.GetRef(New UUID(bill_to_api_code)) Except addrBill = Undefined EndTry;
		
		newQuery = New Query("SELECT
		                     |	Addresses.Ref
		                     |FROM
		                     |	Catalog.Addresses AS Addresses
		                     |WHERE
		                     |	Addresses.Owner = &Customer
		                     |	AND Addresses.Ref = &addrCode");
							 
		newQuery.SetParameter("Customer", NewSO.Company);
		newQuery.SetParameter("addrCode", addrBill);
		billResult = newQuery.Execute();
		If billResult.IsEmpty() Then
			errorMessage = New Map();
			strMessage = " [bill_to_api_code] : Billing Address does not belong to the Company " ;
			errorMessage.Insert("status", "error");
			errorMessage.Insert("message", strMessage );
			errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
			return errorJSON;
		EndIf;
		NewSO.BillTo = addrBill;
		
	Else
		
		Query = New Query("SELECT
		                  |	Addresses.Ref
		                  |FROM
		                  |	Catalog.Addresses AS Addresses
		                  |WHERE
		                  |	Addresses.Owner = &Customer
		                  |	AND Addresses.AddressLine1 = &AddressLine1
		                  |	AND Addresses.AddressLine2 = &AddressLine2
		                  |	AND Addresses.City = &City
		                  |	AND Addresses.State = &State
		                  |	AND Addresses.ZIP = &ZIP
		                  |	AND Addresses.Country = &Country");
		Query.SetParameter("Customer", NewSO.Company);
		
		Try bill_to_address_line1 = ParsedJSON.bill_to_address_line1 Except bill_to_address_line1 = Undefined EndTry;
		If NOT bill_to_address_line1 = Undefined Then
			Query.SetParameter("AddressLine1", bill_to_address_line1);
		Else
			Query.SetParameter("AddressLine1", "");
		EndIf;
		
		Try bill_to_address_line2 = ParsedJSON.bill_to_address_line2 Except bill_to_address_line2 = Undefined EndTry;
		If NOT bill_to_address_line2 = Undefined Then
			Query.SetParameter("AddressLine2", bill_to_address_line2);
		Else
			Query.SetParameter("AddressLine2", "");
		EndIf;
		
		Try bill_to_city = ParsedJSON.bill_to_city Except bill_to_city = Undefined EndTry;
		If NOT bill_to_city = Undefined Then
			Query.SetParameter("City", bill_to_city);
		Else
			Query.SetParameter("City", "");
		EndIf;
		
		Try bill_to_zip = ParsedJSON.bill_to_zip Except bill_to_zip = Undefined EndTry;
		If NOT bill_to_zip = Undefined Then
			Query.SetParameter("ZIP", bill_to_zip);
		Else
			Query.SetParameter("ZIP", "");
		EndIf;
		
		Try bill_to_state = ParsedJSON.bill_to_state Except bill_to_state = Undefined EndTry;
		If NOT bill_to_state = Undefined Then
			Query.SetParameter("State", Catalogs.States.FindByCode(bill_to_state));
		Else
			Query.SetParameter("State", Catalogs.States.EmptyRef());
		EndIf;
		
		Try bill_to_country = ParsedJSON.bill_to_country Except bill_to_country = Undefined EndTry;
		If NOT bill_to_country = Undefined Then
			Query.SetParameter("Country", Catalogs.Countries.FindByCode(bill_to_country));
		Else
			Query.SetParameter("Country", Catalogs.Countries.EmptyRef());
		EndIf;
		
		QueryResult = Query.Execute();
		
		If QueryResult.IsEmpty() Then
			// create new address		
			AddressLine = Catalogs.Addresses.CreateItem();
			AddressLine.Owner = NewSO.Company;

			Try
				AddressLine.Description = ParsedJSON.bill_to_address_id;
			Except
				// generate "BillTo_" + five random characters address ID

				PasswordLength = 5;
				SymbolString = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"; //62
				RandomChars5 = "";
				RNG = New RandomNumberGenerator;	
				For i = 0 to PasswordLength-1 Do
					RN = RNG.RandomNumber(1, 62);
					RandomChars5 = RandomChars5 + Mid(SymbolString,RN,1);
				EndDo;

				AddressLine.Description = "BillTo_" + RandomChars5;
			EndTry;
			
			Try	AddressLine.FirstName = ParsedJSON.bill_to_first_name; Except EndTry;			
			Try AddressLine.MiddleName = ParsedJSON.bill_to_middle_name; Except EndTry;			
			Try AddressLine.LastName = ParsedJSON.bill_to_last_name; Except EndTry;				
			Try AddressLine.Phone = ParsedJSON.bill_to_phone; Except EndTry;			
			Try AddressLine.Cell = ParsedJSON.bill_to_cell; Except EndTry;			
			Try AddressLine.Email = ParsedJSON.bill_to_email; Except EndTry;			
			Try AddressLine.AddressLine1 = ParsedJSON.bill_to_address_line1; Except EndTry;			
			Try	AddressLine.AddressLine2 = ParsedJSON.bill_to_address_line2; Except EndTry;			
			Try	AddressLine.City = ParsedJSON.bill_to_city; Except EndTry;
			Try AddressLine.State = Catalogs.States.FindByCode(ParsedJSON.bill_to_state); Except EndTry;			
			Try AddressLine.Country = Catalogs.Countries.FindByCode(ParsedJSON.bill_to_country); Except EndTry;			
			Try AddressLine.ZIP = ParsedJSON.bill_to_zip; Except EndTry;
			Try	AddressLine.Notes = ParsedJSON.bill_to_notes; Except EndTry;			
			Try AddressLine.SalesTaxCode = Catalogs.SalesTaxCodes.FindByCode(ParsedJSON.bill_to_sales_tax_code); Except EndTry;			
			
			AddressLine.Write();
			NewSO.BillTo = AddressLine.Ref;
			
		Else
			// select first address in the dataset
			Dataset = QueryResult.Unload();
			NewSO.BillTo = Dataset[0].Ref;
		EndIf

	EndIf;
	
	// END BILL TO ADDRESS SECTION
	
	Try date = ParsedJSON.date Except date = Undefined EndTry;
	If date = Undefined Then
		errorMessage = New Map();
		strMessage = " [date] : This field is required ";
		errorMessage.Insert("message", strMessage);
		errorMessage.Insert("status", "error"); 
		errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
		return errorJSON;
	EndIf;
	NewSO.Date = "01/22/2013"; // creating a failed date
	wrongDate = NewSO.Date;
	NewSO.Date = ParsedJSON.date;
	If NewSO.Date = wrongDate Then
		errorMessage = New Map();
		strMessage = " [date] : Date must be in the format of YYYY-MM-DD ";
		errorMessage.Insert("message", strMessage);
		errorMessage.Insert("status", "error"); 
		errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
		return errorJSON;
	EndIf;
	
	
	NewSO.Date = ParsedJSON.date;
	//NewSO.DueDate = ParsedJSON.due_date;
	//NewSO.Terms = Catalogs.PaymentTerms.DueOnReceipt;
	
	//PaymentMethod = ParsedJSON.Get("payment_method");
	// support all payment methods
	//NewCashSale.PaymentMethod = Catalogs.PaymentMethods.Cash;
	Try
		NewSO.RefNum = ParsedJSON.ref_num;
	Except
	EndTry;
	
	Try
		NewSO.CF1String = ParsedJSON.cf1_string;
	Except
	EndTry;	
	
	Try
		NewSO.Memo = ParsedJSON.memo;
	Except
	EndTry;
	// tax rate - calculate from address?
	Try
		SalesTax = ParsedJSON.sales_tax_total; 
		NewSO.SalesTaxRC = ParsedJSON.sales_tax_total;		
	Except
		NewSO.SalesTaxRC = 0;
	EndTry;
	
	Try doc_total = ParsedJSON.doc_total Except doc_total = Undefined EndTry;
	If doc_total = Undefined Then
		errorMessage = New Map();
		strMessage = " [doc_total] : This field is required " ;
		errorMessage.Insert("status", "error");
		errorMessage.Insert("message", strMessage );
		errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
		return errorJSON;
	EndIf;			
	NewSO.DocumentTotal = doc_total;
	NewSO.DocumentTotalRC = doc_total;
	
	//NewSO.DocumentTotal = ParsedJSON.doc_total;
	//NewSO.DocumentTotalRC = ParsedJSON.doc_total;
	
	//NewCashSale.DepositType = "2";
	DefaultCurrency = Constants.DefaultCurrency.Get();
	NewSO.Currency = DefaultCurrency;
	//NewSO.ARAccount = DefaultCurrency.DefaultARAccount;
	//NewCashSale.BankAccount = Constants.BankAccount.Get();
	NewSO.ExchangeRate = 1;
	NewSO.Location = Catalogs.Locations.MainWarehouse;
	
	Try NewSO.LineSubtotalRC = ParsedJSON.line_subtotal; Except EndTry;
	Try NewSO.DiscountRC = ParsedJSON.discount; Except EndTry;
	Try NewSO.DiscountPercent = ParsedJSON.discount_percent; Except EndTry;
	Try NewSO.SubTotalRC = ParsedJSON.subtotal; Except EndTry;
	Try NewSO.ShippingRC = ParsedJSON.shipping; Except EndTry;
	
	//DataLineItems = ParsedJSON.lines.line_items;
	
	Try DataLineItems = ParsedJSON.lines.line_items Except DataLineItems = Undefined EndTry;
	If DataLineItems = Undefined Then
		errorMessage = New Map();
		strMessage = " [lines] : Must enter at least one line with correct line items " ;
		errorMessage.Insert("status", "error");
		errorMessage.Insert("message", strMessage );
		errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
		return errorJSON;
	EndIf;

	
	doc_total_test = 0;
	
	LineItemsRows = DataLineItems.Count();
	For i = 0 To LineItemsRows -1 Do
		
		NewLine = NewSO.LineItems.Add();
		
		//Product = Catalogs.Products.GetRef(New UUID(DataLineItems[i].api_code));
		//NewLine.Product = Product;
		
		Try Product = Catalogs.Products.GetRef(New UUID(DataLineItems[i].api_code)) Except Product = Undefined EndTry;
			Try apiCode = DataLineItems[i].api_code Except apiCode = Undefined EndTry;
		If NOT Product = Undefined Or NOT apiCode = Undefined Then
		    itemsQuery = New Query("SELECT
		                         	|	Products.Ref
		                         	|FROM
								 	|	Catalog.Products AS Products
			                     	|WHERE
			                     	|	Products.Ref = &items");
			itemsQuery.SetParameter("items", Product);
			itemsResult = itemsQuery.Execute();
			If itemsResult.IsEmpty() Then
				errorMessage = New Map();
				strMessage = " [line_items(" + string(i+1) + ").api_code] : Item does not exist" ;
				errorMessage.Insert("status", "error");
				errorMessage.Insert("message", strMessage );
				errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
				return errorJSON;
			EndIf;	
			NewLine.Product = Product;
		Else
			errorMessage = New Map();
			strMessage = " [line_items(" + string(i+1) + ").api_code] : Item code is missing. This is a required field for lines " ;
			errorMessage.Insert("status", "error");
			errorMessage.Insert("message", strMessage );
			errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
			return errorJSON;
		EndIf;

		NewLine.ProductDescription = Product.Description;
		//NewLine.VATCode = CommonUse.GetAttributeValue(Product, "SalesVATCode");
		//NewLine.VAT = 0;
		
		//NewLine.Price = DataLineItems[i].price;
		Try price = DataLineItems[i].price Except price = Undefined EndTry;
		If NOT price = Undefined Then
			NewLine.Price = price;
		Else
			errorMessage = New Map();
			strMessage = " [line_items(" + string(i+1) + ").price] : This is a required field for lines " ;
			errorMessage.Insert("status", "error");
			errorMessage.Insert("message", strMessage );
			errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
			return errorJSON;
		EndIf;


		
		//NewLine.Quantity = DataLineItems[i].quantity;
		Try quantity = DataLineItems[i].quantity Except quantity = Undefined EndTry;
		If NOT quantity = Undefined Then
			NewLine.Quantity = quantity;
		Else
			errorMessage = New Map();
			strMessage = " [line_items(" + string(i+1) + ").quantity] : This is a required field for lines " ;
			errorMessage.Insert("status", "error");
			errorMessage.Insert("message", strMessage );
			errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
			return errorJSON;
		EndIf;
		
		// get taxable from JSON
		//Try
		//	TaxableType = DataLineItems[i].taxable_type;
		//	If TaxableType = "taxable" Then
		//		NewLine.SalesTaxType = Enums.SalesTaxTypes.Taxable;
		//	ElsIf TaxableType = "non-taxable" Then
		//		NewLine.SalesTaxType = Enums.SalesTaxTypes.NonTaxable;
		//	Else
		//		NewLine.SalesTaxType = Enums.SalesTaxTypes.NonTaxable;
		//	EndIf;
		//Except
		//	NewLine.SalesTaxType = Enums.SalesTaxTypes.NonTaxable;	
		//EndTry;
		
		//NewLine.LineTotal = DataLineItems[i].line_total;
		Try linetotal = DataLineItems[i].line_total Except linetotal = Undefined EndTry;
		If NOT quantity = Undefined Then
			NewLine.LineTotal = linetotal;
		Else
			errorMessage = New Map();
			strMessage = " [line_items(" + string(i+1) + ").line_total] : This is a required field for lines " ;
			errorMessage.Insert("status", "error");
			errorMessage.Insert("message", strMessage );
			errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
			return errorJSON;
		EndIf;
		
		If NewLine.LineTotal <> (NewLine.Quantity * NewLine.Price) Then
			errorMessage = New Map();
			strMessage = " [line_items(" + string(i+1) + ").line_total] : Line item's total does not match quantity * price " ;
			errorMessage.Insert("status", "error");
			errorMessage.Insert("message", strMessage );
			errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
			return errorJSON;
		EndIf;


		
		
		doc_total_test = doc_total_test + NewLine.LineTotal;
		
		//Try
		//	TaxableAmount = DataLineItems[i].taxable_amount;
		//	NewLine.TaxableAmount = TaxableAmount				
		//Except
		//	NewLine.TaxableAmount = 0;
		//EndTry;
				
	EndDo;
	
	If doc_total_test <> NewSO.DocumentTotal Then
		errorMessage = New Map();
		strMessage = " [doc_total] : The document total and sum of lineitem totals are not equal " ;
		errorMessage.Insert("status", "error");
		errorMessage.Insert("message", strMessage );
		errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
		return errorJSON;
	EndIf;

	
	NewSO.Write(DocumentWriteMode.Posting);
	
	///
	
	
	//SOData = New Map();
	//SOData.Insert("api_code", String(NewSO.Ref.UUID()));
	//SOData.Insert("customer_api_code", String(NewSO.Company.Ref.UUID()));
	//SOData.Insert("customer_name", NewSO.Company.Description);
	//SOData.Insert("customer_code", NewSO.Company.Code);
	//SOData.Insert("ship_to_api_code", String(NewSO.ShipTo.Ref.UUID()));
	////SOData.Insert("ship_to_address_code", NewSO.ShipTo.Code);
	//SOData.Insert("ship_to_address_id", NewSO.ShipTo.Description);
	//// date - convert into the same format as input
	//SOData.Insert("so_number", NewSO.Number);
	//SOData.Insert("cf1_string", NewSO.CF1String);
	//// payment method - same as input
	////CashSaleData.Insert("payment_method", NewInvoice.PaymentMethod.Description);
	//SOData.Insert("date", NewSO.Date);
	////SOData.Insert("due_date", NewSO.DueDate);
	//SOData.Insert("ref_num", NewSO.RefNum);
	//SOData.Insert("memo", NewSO.Memo);
	//SOData.Insert("sales_tax_total", NewSO.SalesTax);
	//SOData.Insert("doc_total", NewSO.DocumentTotalRC);

	//Query = New Query("SELECT
	//				  |	SOLineItems.Product,
	//				  |	SOLineItems.Price,
	//				  |	SOLineItems.Quantity,
	//				  |	SOLineItems.LineTotal,
	//				  |	SOLineItems.SalesTaxType,
	//				  |	SOLineItems.TaxableAmount
	//				  |FROM
	//				  |	Document.SalesOrder.LineItems AS SOLineItems
	//				  |WHERE
	//				  |	SOLineItems.Ref = &SO");
	//Query.SetParameter("SO", NewSO.Ref);
	//Result = Query.Execute().Choose();
	//
	//LineItems = New Array();
	//
	//While Result.Next() Do
	//	
	//	LineItem = New Map();
	//	LineItem.Insert("item_code", Result.Product.Code);
	//	LineItem.Insert("api_code", String(Result.Product.Ref.UUID()));
	//	LineItem.Insert("item_description", Result.Product.Description);
	//	LineItem.Insert("price", Result.Price);
	//	LineItem.Insert("quantity", Result.Quantity);
	//	LineItem.Insert("taxable_amount", Result.TaxableAmount);
	//	LineItem.Insert("line_total", Result.LineTotal);
	//	If Result.SalesTaxType = Enums.SalesTaxTypes.Taxable Then
	//		LineItem.Insert("taxable_type", "taxable");
	//	ElsIf Result.SalesTaxType = Enums.SalesTaxTypes.NonTaxable Then
	//		LineItem.Insert("taxable_type", "non-taxable");
	//	EndIf;
	//	LineItems.Add(LineItem);
	//	
	//EndDo;
	//
	//LineItemsData = New Map();
	//LineItemsData.Insert("line_items", LineItems);
	//
	//SOData.Insert("lines", LineItemsData);

	
	jsonout = InternetConnectionClientServer.EncodeJSON(GeneralFunctions.ReturnSaleOrderMap(NewSO.Ref));
	
	Return jsonout;
	

EndFunction

Function inoutSalesOrdersGet(jsonin) Export
	ParsedJSON = InternetConnectionClientServer.DecodeJSON(jsonin);
	api_code = ParsedJSON.object_code;
	
	Try
		SO = Documents.SalesOrder.GetRef(New UUID(api_code));
	Except
		errorMessage = New Map();
		strMessage = " [api_code] : The sales order does not exist. Double check that the ID# is correct. ";
		errorMessage.Insert("message", strMessage);
		errorMessage.Insert("status", "error"); 
		errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
		return errorJSON;
	EndTry;
	
	SOQuery = New Query("SELECT
	                    |	SalesOrder.Ref
	                    |FROM
	                    |	Document.SalesOrder AS SalesOrder
	                    |WHERE
	                    |	SalesOrder.Ref = &Ref");
	SOQuery.SetParameter("Ref", SO);
	SOresult = SOQuery.Execute();
	If SOresult.IsEmpty() Then
			errorMessage = New Map();
			strMessage = " [api_code] : The sales order does not exist. Double check that the ID# is correct. ";
			errorMessage.Insert("message", strMessage);
			errorMessage.Insert("status", "error"); 
			errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
			return errorJSON;
	EndIf;
		
	
	jsonout = InternetConnectionClientServer.EncodeJSON(GeneralFunctions.ReturnSaleOrderMap(SO));
	
	Return jsonout;
EndFunction

Function inoutSalesOrdersDelete(jsonin) Export
	
	ParsedJSON = InternetConnectionClientServer.DecodeJSON(jsonin);
	api_code = ParsedJSON.object_code;
	
	SO = Documents.SalesOrder.GetRef(New UUID(api_code));
	
	SO_Obj = SO.GetObject();
	SO_Num = SO_Obj.Number;
	date = SO_Obj.Date;
	SetPrivilegedMode(True);
	Try
		SO_Obj.Delete();//.DeletionMark = True;
	Except
		errorMessage = New Map();
		strMessage = "Failed to delete. Sales Orders must be unposted before deletion and/or other objects are linked to this sales order.";
		errorMessage.Insert("message", strMessage);
		errorMessage.Insert("so_number",SO_Num);
		errorMessage.Insert("date", date);
		errorMessage.Insert("status", "error"); 
		errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
		return errorJSON;
	EndTry;
	SetPrivilegedMode(False);
	
	Output = New Map();	
	
	//Try
	//	SalesInvoiceObj.Write(DocumentWriteMode.UndoPosting);
		Output.Insert("status", "success");
		strMessage = "Sales Order # " + SO_Num + " from " + date + " has been deleted.";
		Output.Insert("message", strMessage);
	//Except
		//ErrorMessage = DetailErrorDescription(ErrorInfo());
	//	Output.Insert("error", "sales invoice can not be deleted");
	//EndTry;
	
	jsonout = InternetConnectionClientServer.EncodeJSON(Output);
	
	Return jsonout;	
EndFunction

Function inoutSalesOrdersListAll(jsonin) Export
	Query = New Query("SELECT
	                  |	SalesOrder.Ref
	                  |FROM
	                  |	Document.SalesOrder AS SalesOrder");
					  
	Result = Query.Execute().Choose();
	
	SO = New Array();
	
	While Result.Next() Do
				
		SO.Add(GeneralFunctions.ReturnSaleOrderMap(Result.Ref));
		
	EndDo;
	
	soList = New Map();
	soList.Insert("Sales Orders", SO);
	
	jsonout = InternetConnectionClientServer.EncodeJSON(soList);
	
	Return jsonout;
EndFunction


Function inoutPurchaseOrdersCreate(jsonin) Export
		
	ParsedJSON = InternetConnectionClientServer.DecodeJSON(jsonin);
		
	NewPO = Documents.PurchaseOrder.CreateDocument();

	Try customer_api_code = ParsedJSON.customer_api_code Except customer_api_code = Undefined EndTry;
	If NOT customer_api_code = Undefined Then
		
		Try
		cust = Catalogs.Companies.GetRef(New UUID(customer_api_code));
		Except
			errorMessage = New Map();
			strMessage = "[customer_api_code] : The customer does not exist.";
			errorMessage.Insert("message", strMessage);
			errorMessage.Insert("status", "error"); 
			errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
			return errorJSON;
		EndTry;

	   // check if customer api code is valid
	   custQuery = New Query("SELECT
	   						 |	Companies.Ref
							 |FROM
							 |	Catalog.Companies AS Companies
							 |WHERE
							 |	Companies.Ref = &custCode");
		custQuery.SetParameter("custCode", cust);
		custResult = custQuery.Execute();
		If custResult.IsEmpty() Then
			errorMessage = New Map();
			strMessage = "[customer_api_code] : The customer does not exist.";
			errorMessage.Insert("status", "error"); 
			errorMessage.Insert("message", strMessage);
			errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
			return errorJSON;
		EndIf;					 
		NewPO.Company = cust;
	Else
		errorMessage = New Map();
		strMessage = "[customer_api_code] : This field is required.";
		errorMessage.Insert("status", "error"); 
		errorMessage.Insert("message", strMessage);
		errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
		return errorJSON;
		
	EndIf;
	// purchase ADDRESS SECTION
	
	Try address_api_code = ParsedJSON.address_api_code Except address_api_code = Undefined EndTry;
	If NOT address_api_code = Undefined Then

		Try addr = Catalogs.Addresses.GetRef(New UUID(address_api_code)) Except addr = Undefined EndTry;
		
		newQuery = New Query("SELECT
		                     |	Addresses.Ref
		                     |FROM
		                     |	Catalog.Addresses AS Addresses
		                     |WHERE
		                     |	Addresses.Owner = &Customer
		                     |	AND Addresses.Ref = &addrCode");
							 
		newQuery.SetParameter("Customer", NewPO.Company);
		newQuery.SetParameter("addrCode", addr);
		addrResult = newQuery.Execute();
		If addrResult.IsEmpty() Then
			errorMessage = New Map();
			strMessage = " [address_api_code] : Purchase Address does not belong to the Company ";
			errorMessage.Insert("status", "error"); 
			errorMessage.Insert("message", strMessage);
			errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
			return errorJSON;
		EndIf;
		NewPO.PurchaseAddress = addr;
		
	Else
		
		Query = New Query("SELECT
		                  |	Addresses.Ref
		                  |FROM
		                  |	Catalog.Addresses AS Addresses
		                  |WHERE
		                  |	Addresses.Owner = &Customer
		                  |	AND Addresses.AddressLine1 = &AddressLine1
		                  |	AND Addresses.AddressLine2 = &AddressLine2
		                  |	AND Addresses.City = &City
		                  |	AND Addresses.State = &State
		                  |	AND Addresses.ZIP = &ZIP
		                  |	AND Addresses.Country = &Country");
		Query.SetParameter("Customer", NewPO.Company);
		
		Try purchase_address_line1 = ParsedJSON.purchase_address_line1 Except purchase_address_line1 = Undefined EndTry;
		If NOT purchase_address_line1 = Undefined Then
			Query.SetParameter("AddressLine1", purchase_address_line1);
		Else
			Query.SetParameter("AddressLine1", "");
		EndIf;
		
		Try purchase_address_line2 = ParsedJSON.purchase_address_line2 Except purchase_address_line2 = Undefined EndTry;
		If NOT purchase_address_line2 = Undefined Then
			Query.SetParameter("AddressLine2", purchase_address_line2);
		Else
			Query.SetParameter("AddressLine2", "");
		EndIf;
		
		Try purchase_city = ParsedJSON.purchase_city Except purchase_city = Undefined EndTry;
		If NOT purchase_city = Undefined Then
			Query.SetParameter("City", purchase_city);
		Else
			Query.SetParameter("City", "");
		EndIf;
		
		Try purchase_zip = ParsedJSON.purchase_zip Except purchase_zip = Undefined EndTry;
		If NOT purchase_zip = Undefined Then
			Query.SetParameter("ZIP", purchase_zip);
		Else
			Query.SetParameter("ZIP", "");
		EndIf;
		
		Try purchase_state = ParsedJSON.purchase_state Except purchase_state = Undefined EndTry;
		If NOT purchase_state = Undefined Then
			Query.SetParameter("State", Catalogs.States.FindByCode(purchase_state));
		Else
			Query.SetParameter("State", Catalogs.States.EmptyRef());
		EndIf;
		
		Try purchase_country = ParsedJSON.purchase_country Except purchase_country = Undefined EndTry;
		If NOT purchase_country = Undefined Then
			Query.SetParameter("Country", Catalogs.Countries.FindByCode(purchase_country));
		Else
			Query.SetParameter("Country", Catalogs.Countries.EmptyRef());
		EndIf;
		
		QueryResult = Query.Execute();
		
		If QueryResult.IsEmpty() Then
			// create new address		
			AddressLine = Catalogs.Addresses.CreateItem();
			AddressLine.Owner = NewPO.Company;

			Try
				AddressLine.Description = ParsedJSON.purchase_address_id;
			Except
				// generate "ShipTo_" + five random characters address ID

				PasswordLength = 5;
				SymbolString = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"; //62
				RandomChars5 = "";
				RNG = New RandomNumberGenerator;	
				For i = 0 to PasswordLength-1 Do
					RN = RNG.RandomNumber(1, 62);
					RandomChars5 = RandomChars5 + Mid(SymbolString,RN,1);
				EndDo;

				AddressLine.Description = "purchase_address_" + RandomChars5;
			EndTry;
			
			Try	AddressLine.FirstName = ParsedJSON.purchase_first_name; Except EndTry;			
			Try AddressLine.MiddleName = ParsedJSON.purchase_middle_name; Except EndTry;			
			Try AddressLine.LastName = ParsedJSON.purchase_last_name; Except EndTry;				
			Try AddressLine.Phone = ParsedJSON.purchase_phone; Except EndTry;			
			Try AddressLine.Cell = ParsedJSON.purchase_cell; Except EndTry;			
			Try AddressLine.Email = ParsedJSON.purchase_email; Except EndTry;			
			Try AddressLine.AddressLine1 = ParsedJSON.purchase_address_line1; Except EndTry;			
			Try	AddressLine.AddressLine2 = ParsedJSON.purchase_address_line2; Except EndTry;			
			Try	AddressLine.City = ParsedJSON.purchase_city; Except EndTry;
			Try AddressLine.State = Catalogs.States.FindByCode(ParsedJSON.purchase_state); Except EndTry;			
			Try AddressLine.Country = Catalogs.Countries.FindByCode(ParsedJSON.purchase_country); Except EndTry;			
			Try AddressLine.ZIP = ParsedJSON.purchase_zip; Except EndTry;
			Try	AddressLine.Notes = ParsedJSON.purchase_notes; Except EndTry;			
			Try AddressLine.SalesTaxCode = Catalogs.SalesTaxCodes.FindByCode(ParsedJSON.purchase_sales_tax_code); Except EndTry;			
			
			AddressLine.Write();
			NewPO.PurchaseAddress = AddressLine.Ref;
			
		Else
			// select first address in the dataset
			Dataset = QueryResult.Unload();
			NewPO.PurchaseAddress = Dataset[0].Ref; 
		EndIf

	EndIf;
	
	// Dropship stuff
	//
	Try ds_customer_api_code = ParsedJSON.ds_customer_api_code Except ds_customer_api_code = Undefined EndTry;
	If NOT ds_customer_api_code = Undefined Then
		
		Try
		cust = Catalogs.Companies.GetRef(New UUID(ds_customer_api_code));
		Except
			errorMessage = New Map();
			strMessage = "[ds_customer_api_code] : The customer does not exist.";
			errorMessage.Insert("message", strMessage);
			errorMessage.Insert("status", "error"); 
			errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
			return errorJSON;
		EndTry;

	   // check if customer api code is valid
	   custQuery = New Query("SELECT
	   						 |	Companies.Ref
							 |FROM
							 |	Catalog.Companies AS Companies
							 |WHERE
							 |	Companies.Ref = &custCode");
		custQuery.SetParameter("custCode", cust);
		custResult = custQuery.Execute();
		If custResult.IsEmpty() Then
			errorMessage = New Map();
			strMessage = "[ds_customer_api_code] : The customer does not exist.";
			errorMessage.Insert("status", "error"); 
			errorMessage.Insert("message", strMessage);
			errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
			return errorJSON;
		EndIf;					 
		NewPO.DropshipCustomer = cust;
		
	EndIf;
	
	Try ds_address_api_code = ParsedJSON.ds_address_api_code Except ds_address_api_code = Undefined EndTry;
	If NOT ds_address_api_code = Undefined Then
		// todo - check if address belongs to company
		NewPO.DropshipAddress = Catalogs.Addresses.GetRef(New UUID(ds_address_api_code));
		Try addrDrop = Catalogs.Addresses.GetRef(New UUID(ds_address_api_code)) Except addrDrop = Undefined EndTry;
		
		newQuery = New Query("SELECT
							 |	Addresses.Ref
							 |FROM
							 |	Catalog.Addresses AS Addresses
							 |WHERE
							 |	Addresses.Owner = &Customer
							 |	AND Addresses.Ref = &addrCode");
							 
		newQuery.SetParameter("Customer", NewPO.DropshipCustomer);
		newQuery.SetParameter("addrCode", addrDrop);
		DropResult = newQuery.Execute();
		If DropResult.IsEmpty() Then
			errorMessage = New Map();
			strMessage = " [ds_address_api_code] : Dropship Address does not belong to the Company " ;
			errorMessage.Insert("status", "error");
			errorMessage.Insert("message", strMessage );
			errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
			return errorJSON;
		EndIf;
		NewPO.DropshipAddress = addrDrop;
		
	EndIf;
		
	Try po_date = ParsedJSON.po_date Except po_date = Undefined EndTry;
	If po_date = Undefined Then
		errorMessage = New Map();
		strMessage = " [po_date] : This field is required ";
		errorMessage.Insert("message", strMessage);
		errorMessage.Insert("status", "error"); 
		errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
		return errorJSON;
	EndIf;
	NewPO.Date = "01/22/2013"; // creating a failed date
	wrongDate = NewPO.Date;
	NewPO.Date = ParsedJSON.po_date;
	If NewPO.Date = wrongDate Then
		errorMessage = New Map();
		strMessage = " [po_date] : Date must be in the format of YYYY-MM-DD ";
		errorMessage.Insert("message", strMessage);
		errorMessage.Insert("status", "error"); 
		errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
		return errorJSON;
	EndIf;
	
	NewPO.Date = ParsedJSON.po_date;
	
	Try 
		delivery_date = ParsedJSON.delivery_date; 

		NewPO.DeliveryDate = "01/22/2013"; // creating a failed date
		wrongDate = NewPO.DeliveryDate;
		NewPO.DeliveryDate = ParsedJSON.delivery_date;
		If NewPO.DeliveryDate = wrongDate Then
			errorMessage = New Map();
			strMessage = " [delivery_date] : Date must be in the format of YYYY-MM-DD ";
			errorMessage.Insert("message", strMessage);
			errorMessage.Insert("status", "error"); 
			errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
			return errorJSON;
		EndIf;
		
		NewPO.DeliveryDate = ParsedJSON.delivery_date;
	Except
	EndTry;	
	
	Try
		NewPO.Memo = ParsedJSON.memo;
	Except
	EndTry;
		
	Try doc_total = ParsedJSON.doc_total Except doc_total = Undefined EndTry;
	If doc_total = Undefined Then
		errorMessage = New Map();
		strMessage = " [doc_total] : This field is required " ;
		errorMessage.Insert("status", "error");
		errorMessage.Insert("message", strMessage );
		errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
		return errorJSON;
	EndIf;
	NewPO.DocumentTotalRC = doc_total;
	
	//NewPO.Location = Catalogs.Locations.MainWarehouse;
	
	Try project = ParsedJSON.project;
		newQuery = New Query("SELECT
		                     |	Projects.Ref
		                     |FROM
		                     |	Catalog.Projects AS Projects
		                     |WHERE
		                     |	Projects.Description = &Description");
							 
		newQuery.SetParameter("Description", project);
		projResult = newQuery.Execute();
		If projResult.IsEmpty() Then
			errorMessage = New Map();
			strMessage = "[project] : The project does not exist." ;
			errorMessage.Insert("status", "error");
			errorMessage.Insert("message", strMessage );
			errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
			return errorJSON;
		EndIf; 
		projUnload = projResult.Unload();
		NewPO.Project = projUnload[0].Ref;
	Except
	EndTry;
	
	Try class = ParsedJSON.class;
		newQuery = New Query("SELECT
		                     |	Classes.Ref
		                     |FROM
		                     |	Catalog.Classes AS Classes
		                     |WHERE
		                     |	Classes.Description = &Description");
							 
		newQuery.SetParameter("Description", class);
		classResult = newQuery.Execute();
		If classResult.IsEmpty() Then
			errorMessage = New Map();
			strMessage = "[class] : The class does not exist." ;
			errorMessage.Insert("status", "error");
			errorMessage.Insert("message", strMessage );
			errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
			return errorJSON;
		EndIf; 
		classUnload = classResult.Unload();
		NewPO.Class = classUnload[0].Ref;
	Except
	EndTry;
	
		
	Try DataLineItems = ParsedJSON.lines.line_items Except DataLineItems = Undefined EndTry;
	If DataLineItems = Undefined Then
		errorMessage = New Map();
		strMessage = " [lines] : Must enter at least one line with correct line items " ;
		errorMessage.Insert("status", "error");
		errorMessage.Insert("message", strMessage );
		errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
		return errorJSON;
	EndIf;
	
	doc_total_test = 0;
	
	LineItemsRows = DataLineItems.Count();
	For i = 0 To LineItemsRows -1 Do
		
		NewLine = NewPO.LineItems.Add();
				
		Try Product = Catalogs.Products.GetRef(New UUID(DataLineItems[i].api_code)) Except Product = Undefined EndTry;
			Try apiCode = DataLineItems[i].api_code Except apiCode = Undefined EndTry;
		If NOT Product = Undefined Or NOT apiCode = Undefined Then
		    itemsQuery = New Query("SELECT
		                         	|	Products.Ref
		                         	|FROM
								 	|	Catalog.Products AS Products
			                     	|WHERE
			                     	|	Products.Ref = &items");
			itemsQuery.SetParameter("items", Product);
			itemsResult = itemsQuery.Execute();
			If itemsResult.IsEmpty() Then
				errorMessage = New Map();
				strMessage = " [line_items(" + string(i+1) + ").api_code] : Item does not exist" ;
				errorMessage.Insert("status", "error");
				errorMessage.Insert("message", strMessage );
				errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
				return errorJSON;
			EndIf;	
			NewLine.Product = Product;
		Else
			errorMessage = New Map();
			strMessage = " [line_items(" + string(i+1) + ").api_code] : Item code is missing. This is a required field for lines " ;
			errorMessage.Insert("status", "error");
			errorMessage.Insert("message", strMessage );
			errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
			return errorJSON;
		EndIf;
		
		NewLine.ProductDescription = Product.Description;
				
		Try price = DataLineItems[i].price Except price = Undefined EndTry;
		If NOT price = Undefined Then
			NewLine.Price = price;
		Else
			errorMessage = New Map();
			strMessage = " [line_items(" + string(i+1) + ").price] : This is a required field for lines " ;
			errorMessage.Insert("status", "error");
			errorMessage.Insert("message", strMessage );
			errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
			return errorJSON;
		EndIf;
		
		Try quantity = DataLineItems[i].quantity Except quantity = Undefined EndTry;
		If NOT quantity = Undefined Then
			NewLine.Quantity = quantity;
		Else
			errorMessage = New Map();
			strMessage = " [line_items(" + string(i+1) + ").quantity] : This is a required field for lines " ;
			errorMessage.Insert("status", "error");
			errorMessage.Insert("message", strMessage );
			errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
			return errorJSON;
		EndIf;
		
		Try linetotal = DataLineItems[i].line_total Except linetotal = Undefined EndTry;
		If NOT quantity = Undefined Then
			NewLine.LineTotal = linetotal;
		Else
			errorMessage = New Map();
			strMessage = " [line_items(" + string(i+1) + ").line_total] : This is a required field for lines " ;
			errorMessage.Insert("status", "error");
			errorMessage.Insert("message", strMessage );
			errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
			return errorJSON;
		EndIf;
		
		If NewLine.LineTotal <> (NewLine.Quantity * NewLine.Price) Then
			errorMessage = New Map();
			strMessage = " [line_items(" + string(i+1) + ").line_total] : Line item's total does not match quantity * price " ;
			errorMessage.Insert("status", "error");
			errorMessage.Insert("message", strMessage );
			errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
			return errorJSON;
		EndIf;
		
		doc_total_test = doc_total_test + NewLine.LineTotal;
		
		Try NewLine.Location = Catalogs.Locations.MainWarehouse; Except EndTry;
		
		Try 
			um = DataLineItems[i].unit_of_measure;
			newQuery = New Query("SELECT
			                     |	UM.Ref
			                     |FROM
			                     |	Catalog.UM AS UM
			                     |WHERE
			                     |	UM.Description = &Description");
								 
			newQuery.SetParameter("Description", um);
			umResult = newQuery.Execute();
			If umResult.IsEmpty() Then
				errorMessage = New Map();
				strMessage = "[unit_of_measure] : The unit of measure does not exist." ;
				errorMessage.Insert("status", "error");
				errorMessage.Insert("message", strMessage );
				errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
				return errorJSON;
			EndIf; 
			umUnload = umResult.Unload();
			NewLine.UM = umUnload[0].Ref;
		Except
		EndTry;
		
		Try 
			proj = DataLineItems[i].project;
			newQuery = New Query("SELECT
			                     |	Projects.Ref
			                     |FROM
			                     |	Catalog.Projects AS Projects
			                     |WHERE
			                     |	Projects.Description = &Description");
								 
			newQuery.SetParameter("Description", proj);
			projResult = newQuery.Execute();
			If projResult.IsEmpty() Then
				errorMessage = New Map();
				strMessage = "[project] : The project does not exist." ;
				errorMessage.Insert("status", "error");
				errorMessage.Insert("message", strMessage );
				errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
				return errorJSON;
			EndIf; 
			projUnload = projResult.Unload();
			NewLine.Project = projUnload[0].Ref;
		Except
		EndTry;
		
		Try 
			class = DataLineItems[i].class;
			newQuery = New Query("SELECT
			                     |	Classes.Ref
			                     |FROM
			                     |	Catalog.Classes AS Classes
			                     |WHERE
			                     |	Classes.Description = &Description");
								 
			newQuery.SetParameter("Description", class);
			classResult = newQuery.Execute();
			If classResult.IsEmpty() Then
				errorMessage = New Map();
				strMessage = "[class] : The class does not exist." ;
				errorMessage.Insert("status", "error");
				errorMessage.Insert("message", strMessage );
				errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
				return errorJSON;
			EndIf; 
			classUnload = classResult.Unload();
			NewLine.Class = classUnload[0].Ref;
		Except
		EndTry;
			
				
	EndDo;
	
	NewPO.Write(DocumentWriteMode.Posting);
		
	jsonout = InternetConnectionClientServer.EncodeJSON(Webhooks.ReturnPurchaseOrderMap(NewPO.Ref));
	
	Return jsonout;
EndFunction
