// for when a product in zoho is created and a webhook gets sent to ACS
Function zoho_product(jsonin)
	ParsedJSON = InternetConnectionClientServer.DecodeJSON(jsonin);

	//Create a product in ACS
	NewProduct = Catalogs.Products.CreateItem();
	Try
		NewProduct.Code = ParsedJSON.product_code;
	Except
		Return "Fail: No product_code";
	EndTry;
	Try
		NewProduct.Description = ParsedJSON.product_name;
	Except
		Return "Fail: No product_name";
	EndTry;
	
	//make type product and follow it up with needed product settings
	NewProduct.Type = Enums.InventoryTypes.Inventory;
	NewProduct.CostingMethod = Enums.InventoryCosting.WeightedAverage;
	NewProduct.InventoryOrExpenseAccount = Constants.InventoryAccount.Get();
	
	//Start of optional fields
	Try // check for product category
		If ParsedJSON.product_category <> "" Then
			CatQuery = new Query("SELECT
			                     |	ProductCategories.Ref
			                     |FROM
			                     |	Catalog.ProductCategories AS ProductCategories
			                     |WHERE
			                     |	ProductCategories.Description = &Description");
							   
			CatQuery.SetParameter("Description", ParsedJSON.product_category);
			CatResult = CatQuery.Execute();
			If CatResult.IsEmpty() Then
				// Category is new
				NewCategory = Catalogs.ProductCategories.CreateItem();
				NewCategory.Description = ParsedJSON.product_category;
				NewCategory.Write();
				NewProduct.Category = NewCategory.Ref;
			Else
				// category exists
				item_cat = CatResult.Unload();
				NewProduct.Category = item_cat[0].Ref;
			EndIf;
		EndIf;
	Except
	EndTry;
		
	Try // check for taxable field
		If ParsedJSON.taxable = "false" Then
			NewProduct.Taxable = False;
		Else
			NewProduct.Taxable = True;
		EndIf;
	Except
	EndTry;
	
	Try // add unit price as object.price
		If ParsedJSON.unit_price <> "0.0" Then
			NewProduct.Price = Number(ParsedJSON.unit_price);
		EndIf;
	Except
	EndTry;
	
	Try 
		If ParsedJSON.usage_unit <> "" Then
			UoMRef = Catalogs.UnitSets.FindByDescription(ParsedJSON.usage_unit);
			If UoMRef.Ref <> Catalogs.UnitSets.EmptyRef() Then
				// already exists
				NewProduct.UnitSet = UoMRef.Ref;
			Else
				//create new uom
				newUoM = Catalogs.UnitSets.CreateItem();
				newUoM.Description = ParsedJSON.usage_unit;
				newUoM.Write();
				NewProduct.UnitSet = newUoM.Ref;
				newUnit = Catalogs.Units.CreateItem();
				newUnit.Owner       = newUoM.Ref;   // Set name
				newUnit.Code        = Left(ParsedJSON.usage_unit,5);// Abbreviation
				newUnit.Description = ParsedJSON.usage_unit;        // Unit name
				newUnit.BaseUnit    = True;                // Base ref of set
				newUnit.Factor      = 1;
				newUnit.Write();
				newUoM.DefaultReportUnit = newUnit.Ref;
				If  newUoM.DefaultSaleUnit.IsEmpty() Then
					newUoM.DefaultSaleUnit = newUnit.Ref;
				EndIf;
				If  newUoM.DefaultPurchaseUnit.IsEmpty() Then
					newUoM.DefaultPurchaseUnit = newUnit.Ref;
				EndIf;
				newUoM.Write();
			EndIf;

		Else
			NewProduct.UnitSet = Constants.DefaultUoMSet.Get();
		EndIf;
		
	Except
		NewProduct.UnitSet = Constants.DefaultUoMSet.Get();
	EndTry;

	NewProduct.IncomeAccount = Constants.IncomeAccount.Get();
	NewProduct.COGSAccount = GeneralFunctions.GetDefaultCOGSAcct();
		
	newProduct.Write();
	
	//create a record of the acs_apicode to zoho id mapping
	newRecord = Catalogs.zoho_productCodeMap.CreateItem();
	newRecord.product_ref = newProduct.Ref;
	Try 
		newRecord.zoho_id = ParsedJSON.product_id;
		
	Except
		Return "Fail: No zoho id";
	EndTry;
	newRecord.Write();
	
	Return "Success";
		
EndFunction

// for when a product in zoho gets updated
Function zoho_product_update(jsonin)
	
	ParsedJSON = InternetConnectionClientServer.DecodeJSON(jsonin);
	
	//get item uuid to update in acs
	apiQuery = new Query("SELECT
	                     |	zoho_productCodeMap.product_ref
	                     |FROM
	                     |	Catalog.zoho_productCodeMap AS zoho_productCodeMap
	                     |WHERE
	                     |	zoho_productCodeMap.zoho_id = &zoho_id");
					   
	apiQuery.SetParameter("zoho_id", ParsedJSON.product_id);
	queryResult = apiQuery.Execute();
	
	If NOT queryResult.IsEmpty() Then
		queryResultobj = queryResult.Unload();
		UpdatedProduct = queryResultobj[0].product_ref;
		UpdatedProductObj = UpdatedProduct.GetObject();
		Try  // possible might break because of uniqueness problems or no update fields passed
			Try UpdatedProductObj.Code = ParsedJSON.product_code; Except EndTry;
			Try UpdatedProductObj.Description = ParsedJSON.product_name; Except EndTry; 
		Except
			Return "Failed to update";
		EndTry;
		//Start of optional fields
		Try // check for product category
			If ParsedJSON.product_category <> "" Then
				CatQuery = new Query("SELECT
				                     |	ProductCategories.Ref
				                     |FROM
				                     |	Catalog.ProductCategories AS ProductCategories
				                     |WHERE
				                     |	ProductCategories.Description = &Description");
								   
				CatQuery.SetParameter("Description", ParsedJSON.product_category);
				CatResult = CatQuery.Execute();
				If CatResult.IsEmpty() Then
					// Category is new
					NewCategory = Catalogs.ProductCategories.CreateItem();
					NewCategory.Description = ParsedJSON.product_category;
					NewCategory.Write();
					UpdatedProductObj.Category = NewCategory.Ref;
				Else
					// category exists
					item_cat = CatResult.Unload();
					UpdatedProductObj.Category = item_cat[0].Ref;
				EndIf;
			Else
				UpdatedProductObj.Category = Catalogs.ProductCategories.EmptyRef();
			EndIf;
		Except
		EndTry;
		
		Try // check for taxable field
			If ParsedJSON.taxable = "false" Then
				UpdatedProductObj.Taxable = False;
			Else
				UpdatedProductObj.Taxable = True;
			EndIf;
		
		Except
		EndTry;
	
		Try // add unit price as object.price
			If ParsedJSON.unit_price <> "0.0" Then
				UpdatedProductObj.Price = Number(ParsedJSON.unit_price);
			EndIf;
		Except
		EndTry;
		
		Try 
			If ParsedJSON.usage_unit <> "" Then
				UoMRef = Catalogs.UnitSets.FindByDescription(ParsedJSON.usage_unit);
				If UoMRef.Ref <> Catalogs.UnitSets.EmptyRef() Then
					// already exists
					UpdatedProductObj.UnitSet = UoMRef.Ref;
				Else
					//create new uom
					newUoM = Catalogs.UnitSets.CreateItem();
					newUoM.Description = ParsedJSON.usage_unit;
					newUoM.Write();
					UpdatedProductObj.UnitSet = newUoM.Ref;
					newUnit = Catalogs.Units.CreateItem();
					newUnit.Owner       = newUoM.Ref;   // Set name
					newUnit.Code        = Left(ParsedJSON.usage_unit,5);// Abbreviation
					newUnit.Description = ParsedJSON.usage_unit;        // Unit name
					newUnit.BaseUnit    = True;                // Base ref of set
					newUnit.Factor      = 1;
					newUnit.Write();
					newUoM.DefaultReportUnit = newUnit.Ref;
					If  newUoM.DefaultSaleUnit.IsEmpty() Then
						newUoM.DefaultSaleUnit = newUnit.Ref;
					EndIf;
					If  newUoM.DefaultPurchaseUnit.IsEmpty() Then
						newUoM.DefaultPurchaseUnit = newUnit.Ref;
					EndIf;
					newUoM.Write();
				EndIf;

			Else
				//UpdatedProductObj.UnitSet = Constants.DefaultUoMSet.Get();
				//dont update
			EndIf;
		
		Except
			//UpdatedProductObj.UnitSet = Constants.DefaultUoMSet.Get();
			//dont update
		EndTry;
		
	Else
		Try 
			zoho_product(jsonin);
			return "added!";
		Except
			Return "couldnt find item to update.";
		EndTry;
	EndIf;
	
	UpdatedProductObj.Write();
	Return "Success";

EndFunction

Function zoho_pricebook(jsonin)
	
	ParsedJSON = InternetConnectionClientServer.DecodeJSON(jsonin);

	//Create a product in ACS
	NewPriceLevel = Catalogs.PriceLevels.CreateItem();
	Try
		NewPriceLevel.Description = ParsedJSON.pricebook_name;
	Except
		Return "Fail: No pricebook_name";
	EndTry;
		
	NewPriceLevel.Write();
	
	//create a record of the acs_apicode to zoho id mapping
	newRecord = Catalogs.zoho_pricebookCodeMap.CreateItem();
	newRecord.pricelevel_ref = NewPriceLevel.Ref;
	Try 
		newRecord.zoho_id = ParsedJSON.pricebook_id;
		
	Except
		Return "Fail: No zoho id";
	EndTry;
	newRecord.Write();
	
	Return "Success";
	
EndFunction

Function zoho_pricebook_update(jsonin)
	
	ParsedJSON = InternetConnectionClientServer.DecodeJSON(jsonin);
	
	//get account uuid to update in acs
	apiQuery = new Query("SELECT
	                     |	zoho_pricebookCodeMap.pricelevel_ref
	                     |FROM
	                     |	Catalog.zoho_pricebookCodeMap AS zoho_pricebookCodeMap
	                     |WHERE
	                     |	zoho_pricebookCodeMap.zoho_id = &zoho_id");
					   
	apiQuery.SetParameter("zoho_id", ParsedJSON.pricebook_id);
	queryResult = apiQuery.Execute();
	
	If NOT queryResult.IsEmpty() Then
		queryResultobj = queryResult.Unload();
		Updatedpricelevel = queryResultobj[0].pricelevel_ref;
		UpdatedPLObj = Updatedpricelevel.GetObject();
		Try
			UpdatedPLObj.Description = ParsedJSON.pricebook_name;
		Except
			Return "Fail: no pricebook_name";
		EndTry;
				
		UpdatedPLObj.Write();	
	
	Else
		Try 
			zoho_pricebook(jsonin);
			return "added";
		Except
			return "no pricebook to update";
		EndTry;

	EndIf;
	
	Return "Success";	
EndFunction

Function zoho_account(jsonin)
	ParsedJSON = InternetConnectionClientServer.DecodeJSON(jsonin);

	//Create an account in ACS
	NewCompany = Catalogs.Companies.CreateItem();
	Try
		NewCompany.Description = ParsedJSON.account_name;
	Except
		Return "Fail: No account_name";
	EndTry;
	Try
		If ParsedJSON.account_number <> "" AND ParsedJSON.acount_number <> "0" Then
			NewCompany.Code = ParsedJSON.account_number;
		EndIf;
		//autogenerate the numbering if not passed
	Except
		//autogenerate the numbering
	EndTry;
	
	NewCompany.Customer = True;   // only gets called when its a customer
		
	//Start of optional fields
	Try NewCompany.Notes = ParsedJSON.description; Except EndTry;
	Try NewCompany.Website = ParsedJSON.website; Except EndTry;
	
	Try // check for sales person
		If ParsedJSON.account_owner <> "" Then
			SPQuery = new Query("SELECT
			                    |	SalesPeople.Ref
			                    |FROM
			                    |	Catalog.SalesPeople AS SalesPeople
			                    |WHERE
			                    |	SalesPeople.Description = &Description");
							   
			SPQuery.SetParameter("Description", ParsedJSON.account_owner);
			SPResult = SPQuery.Execute();
			If SPResult.IsEmpty() Then
				// salesperson is new
				NewSP = Catalogs.SalesPeople.CreateItem();
				NewSP.Description = ParsedJSON.account_owner;
				NewSP.Write();
				NewCompany.SalesPerson = NewSP.Ref;
			Else
				//sales person exists
				salesPerson = SPResult.Unload();
				NewCompany.SalesPerson = salesPerson[0].Ref;
			EndIf;
		EndIf;
	Except
	EndTry;
	
	newCompany.Terms = Catalogs.PaymentTerms.Net30;
	newCompany.DefaultCurrency = Catalogs.Currencies.USD;
	
	newCompany.Write();
	
	//create a record of the acs_apicode to zoho id mapping
	newRecord = Catalogs.zoho_accountCodeMap.CreateItem();
	newRecord.company_ref = newCompany.Ref;
	Try 
		newRecord.zoho_id = ParsedJSON.account_id;
		
	Except
		Return "Fail: No zoho id";
	EndTry;
	newRecord.Write();
	
	// return back the account number/code
	PathDef = "crm.zoho.com/crm/private/xml/Accounts/";
					
	AccountXML = "<Accounts>"
				+ "<row no=""1"">"
				+ "<FL val=""Account Number"">" + zoho_Functions.Zoho_XMLEncoding(newCompany.Code) + "</FL>"
				+ "</row>"
				+ "</Accounts>";

	AuthHeader = "authtoken=" + Constants.zoho_auth_token.Get() + "&scope=crmapi" + "&id=" + ParsedJSON.account_id;
		
	URLstring = PathDef + "updateRecords?" + AuthHeader + "&xmlData=" + AccountXML;
	
	HeadersMap = New Map();			
	HTTPRequest = New HTTPRequest("", HeadersMap);	
	SSLConnection = New OpenSSLSecureConnection();
	HTTPConnection = New HTTPConnection(URLstring,,,,,,SSLConnection);
	Result = HTTPConnection.Post(HTTPRequest);
	
	//copy the default addresses into acs addresses
	ParsedAddress = InternetConnectionClientServer.DecodeJSON(ParsedJSON.default_addresses);
	
	If BillingShippingSame(ParsedAddress) Then 
		//Create primary address with zoho default billing and shipping
		AddressLine = Catalogs.Addresses.CreateItem();
		AddressLine.Owner = newCompany.Ref;
		AddressLine.Description = "Primary";
		AddressLine.DefaultBilling = True;
		AddressLine.DefaultShipping = True;
		Try AddressLine.AddressLine1 = ParsedAddress.billing_street; Except EndTry;
		Try AddressLine.AddressLine2 = ParsedAddress.cust_billing_street2; Except EndTry;// ferguson custom
		Try AddressLine.AddressLine3 = ParsedAddress.cust_billing_street3; Except EndTry; // ferguson custom

		Try AddressLine.City = ParsedAddress.billing_city; Except EndTry;
		
		Try // get state
			If ParsedAddress.billing_state <> "" Then
				
				StateQuery = new Query("SELECT
				                       |	States.Ref
				                       |FROM
				                       |	Catalog.States AS States
				                       |WHERE
				                       |	States.Code = &Code
				                       |	OR States.Description = &Description");
								   
				StateQuery.SetParameter("Code", Upper(ParsedAddress.billing_state));
				StateQuery.SetParameter("Description", Title(ParsedAddress.billing_state));
				StateResult = StateQuery.Execute().Unload();
				AddressLine.State = StateResult[0].Ref;
			EndIf;
		Except
		EndTry;
		
		Try // ferguson custom   state
			If ParsedAddress.cust_billing_state <> "" Then
				
				StateQuery = new Query("SELECT
				                       |	States.Ref
				                       |FROM
				                       |	Catalog.States AS States
				                       |WHERE
				                       |	States.Code = &Code
				                       |	OR States.Description = &Description");
								   
				StateQuery.SetParameter("Code", Upper(ParsedAddress.cust_billing_state));
				StateQuery.SetParameter("Description", Title(ParsedAddress.cust_billing_state));
				StateResult = StateQuery.Execute().Unload();
				AddressLine.State = StateResult[0].Ref;
			EndIf;
		Except
		EndTry;
		
		Try AddressLine.ZIP = ParsedAddress.billing_zip; Except EndTry;
		
		Try // get country
			If ParsedAddress.billing_country <> "" Then
				
				CountryQuery = new Query("SELECT
				                         |	Countries.Ref
				                         |FROM
				                         |	Catalog.Countries AS Countries
				                         |WHERE
				                         |	Countries.Description = &Description
				                         |	OR Countries.Code = &Code");
								   
				CountryQuery.SetParameter("Code", Upper(ParsedAddress.billing_country));
				CountryQuery.SetParameter("Description", Title(ParsedAddress.billing_country));
				CountryResult = CountryQuery.Execute().Unload();
				AddressLine.Country = CountryResult[0].Ref;
			EndIf;
		Except
		EndTry;
		
		Try // ferguson custom    country
			If ParsedAddress.cust_billing_country <> "" Then
				
				CountryQuery = new Query("SELECT
				                         |	Countries.Ref
				                         |FROM
				                         |	Catalog.Countries AS Countries
				                         |WHERE
				                         |	Countries.Description = &Description
				                         |	OR Countries.Code = &Code");
								   
				CountryQuery.SetParameter("Code", Upper(ParsedAddress.cust_billing_country));
				CountryQuery.SetParameter("Description", Title(ParsedAddress.cust_billing_country));
				CountryResult = CountryQuery.Execute().Unload();
				AddressLine.Country = CountryResult[0].Ref;
			EndIf;
		Except
		EndTry;
		
		Try // check for sales person
			If ParsedJSON.account_owner <> "" Then
				SPQuery = new Query("SELECT
									|	SalesPeople.Ref
									|FROM
									|	Catalog.SalesPeople AS SalesPeople
									|WHERE
									|	SalesPeople.Description = &Description");
								   
				SPQuery.SetParameter("Description", ParsedJSON.account_owner);
				SPResult = SPQuery.Execute();
				If SPResult.IsEmpty() Then
					// salesperson is new
					NewSP = Catalogs.SalesPeople.CreateItem();
					NewSP.Description = ParsedJSON.account_owner;
					NewSP.Write();
					AddressLine.SalesPerson = NewSP.Ref;
				Else
					//sales person exists
					salesPerson = SPResult.Unload();
					AddressLine.SalesPerson = salesPerson[0].Ref;
				EndIf;
			EndIf;
		Except
		EndTry;
		
		AddressLine.Write();
	Else
		//Create addresses with zoho default billing and shipping seperately 
		AddressLine = Catalogs.Addresses.CreateItem();
		AddressLine.Owner = newCompany.Ref;
		AddressLine.Description = "Default Billing";
		AddressLine.DefaultBilling = True;
		AddressLine.DefaultShipping = False;
		Try AddressLine.AddressLine1 = ParsedAddress.billing_street; Except EndTry;
		Try AddressLine.AddressLine2 = ParsedAddress.cust_billing_street2; Except EndTry;// ferguson custom
		Try AddressLine.AddressLine3 = ParsedAddress.cust_billing_street3; Except EndTry; // ferguson custom
		Try AddressLine.City = ParsedAddress.billing_city; Except EndTry;
		
		Try // get state
			If ParsedAddress.billing_state <> "" Then
				
				StateQuery = new Query("SELECT
				                       |	States.Ref
				                       |FROM
				                       |	Catalog.States AS States
				                       |WHERE
				                       |	States.Code = &Code
				                       |	OR States.Description = &Description");
								   
				StateQuery.SetParameter("Code", Upper(ParsedAddress.billing_state));
				StateQuery.SetParameter("Description", Title(ParsedAddress.billing_state));
				StateResult = StateQuery.Execute().Unload();
				AddressLine.State = StateResult[0].Ref;
			EndIf;
		Except
		EndTry;
		
		Try // ferguson custom   state
			If ParsedAddress.cust_billing_state <> "" Then
				
				StateQuery = new Query("SELECT
				                       |	States.Ref
				                       |FROM
				                       |	Catalog.States AS States
				                       |WHERE
				                       |	States.Code = &Code
				                       |	OR States.Description = &Description");
								   
				StateQuery.SetParameter("Code", Upper(ParsedAddress.cust_billing_state));
				StateQuery.SetParameter("Description", Title(ParsedAddress.cust_billing_state));
				StateResult = StateQuery.Execute().Unload();
				AddressLine.State = StateResult[0].Ref;
			EndIf;
		Except
		EndTry;
		
		Try AddressLine.ZIP = ParsedAddress.billing_zip; Except EndTry;
		
		Try // get country
			If ParsedAddress.billing_country <> "" Then
				
				CountryQuery = new Query("SELECT
				                         |	Countries.Ref
				                         |FROM
				                         |	Catalog.Countries AS Countries
				                         |WHERE
				                         |	Countries.Description = &Description
				                         |	OR Countries.Code = &Code");
								   
				CountryQuery.SetParameter("Code", Upper(ParsedAddress.billing_country));
				CountryQuery.SetParameter("Description", Title(ParsedAddress.billing_country));
				CountryResult = CountryQuery.Execute().Unload();
				AddressLine.Country = CountryResult[0].Ref;
			EndIf;
		Except
		EndTry;
		
		Try // ferguson custom    country
			If ParsedAddress.cust_billing_country <> "" Then
				
				CountryQuery = new Query("SELECT
				                         |	Countries.Ref
				                         |FROM
				                         |	Catalog.Countries AS Countries
				                         |WHERE
				                         |	Countries.Description = &Description
				                         |	OR Countries.Code = &Code");
								   
				CountryQuery.SetParameter("Code", Upper(ParsedAddress.cust_billing_country));
				CountryQuery.SetParameter("Description", Title(ParsedAddress.cust_billing_country));
				CountryResult = CountryQuery.Execute().Unload();
				AddressLine.Country = CountryResult[0].Ref;
			EndIf;
		Except
		EndTry;
		
		Try // check for sales person
			If ParsedJSON.account_owner <> "" Then
				SPQuery = new Query("SELECT
									|	SalesPeople.Ref
									|FROM
									|	Catalog.SalesPeople AS SalesPeople
									|WHERE
									|	SalesPeople.Description = &Description");
								   
				SPQuery.SetParameter("Description", ParsedJSON.account_owner);
				SPResult = SPQuery.Execute();
				If SPResult.IsEmpty() Then
					// salesperson is new
					NewSP = Catalogs.SalesPeople.CreateItem();
					NewSP.Description = ParsedJSON.account_owner;
					NewSP.Write();
					AddressLine.SalesPerson = NewSP.Ref;
				Else
					//sales person exists
					salesPerson = SPResult.Unload();
					AddressLine.SalesPerson = salesPerson[0].Ref;
				EndIf;
			EndIf;
		Except
		EndTry;
		
		AddressLine.Write();
		
		AddressLine = Catalogs.Addresses.CreateItem();
		AddressLine.Owner = newCompany.Ref;
		AddressLine.Description = "Default Shipping";
		AddressLine.DefaultBilling = False;
		AddressLine.DefaultShipping = True;
		Try AddressLine.AddressLine1 = ParsedAddress.shipping_street; Except EndTry;
		Try AddressLine.AddressLine2 = ParsedAddress.cust_shipping_street2; Except EndTry;// ferguson custom
		Try AddressLine.AddressLine3 = ParsedAddress.cust_shipping_street3; Except EndTry; // ferguson custom
		Try AddressLine.City = ParsedAddress.shipping_city; Except EndTry;
		
		Try // get state
			If ParsedAddress.shipping_state <> "" Then
				
				StateQuery = new Query("SELECT
				                       |	States.Ref
				                       |FROM
				                       |	Catalog.States AS States
				                       |WHERE
				                       |	States.Code = &Code
				                       |	OR States.Description = &Description");
								   
				StateQuery.SetParameter("Code", Upper(ParsedAddress.shipping_state));
				StateQuery.SetParameter("Description", Title(ParsedAddress.shipping_state));
				StateResult = StateQuery.Execute().Unload();
				AddressLine.State = StateResult[0].Ref;
			EndIf;
		Except
		EndTry;
		
		Try // ferguson custom   state
			If ParsedAddress.cust_shipping_state <> "" Then
				
				StateQuery = new Query("SELECT
				                       |	States.Ref
				                       |FROM
				                       |	Catalog.States AS States
				                       |WHERE
				                       |	States.Code = &Code
				                       |	OR States.Description = &Description");
								   
				StateQuery.SetParameter("Code", Upper(ParsedAddress.cust_shipping_state));
				StateQuery.SetParameter("Description", Title(ParsedAddress.cust_shipping_state));
				StateResult = StateQuery.Execute().Unload();
				AddressLine.State = StateResult[0].Ref;
			EndIf;
		Except
		EndTry;
		
		Try AddressLine.ZIP = ParsedAddress.shipping_zip; Except EndTry;
		
		Try // get country
			If ParsedAddress.shipping_country <> "" Then
				
				CountryQuery = new Query("SELECT
				                         |	Countries.Ref
				                         |FROM
				                         |	Catalog.Countries AS Countries
				                         |WHERE
				                         |	Countries.Description = &Description
				                         |	OR Countries.Code = &Code");
								   
				CountryQuery.SetParameter("Code", Upper(ParsedAddress.shipping_country));
				CountryQuery.SetParameter("Description", Title(ParsedAddress.shipping_country));
				CountryResult = CountryQuery.Execute().Unload();
				AddressLine.Country = CountryResult[0].Ref;
			EndIf;
		Except
		EndTry;
		
		Try // ferguson custom    country
			If ParsedAddress.cust_shipping_country <> "" Then
				
				CountryQuery = new Query("SELECT
				                         |	Countries.Ref
				                         |FROM
				                         |	Catalog.Countries AS Countries
				                         |WHERE
				                         |	Countries.Description = &Description
				                         |	OR Countries.Code = &Code");
								   
				CountryQuery.SetParameter("Code", Upper(ParsedAddress.cust_shipping_country));
				CountryQuery.SetParameter("Description", Title(ParsedAddress.cust_shipping_country));
				CountryResult = CountryQuery.Execute().Unload();
				AddressLine.Country = CountryResult[0].Ref;
			EndIf;
		Except
		EndTry;
		
		Try // check for sales person
			If ParsedJSON.account_owner <> "" Then
				SPQuery = new Query("SELECT
									|	SalesPeople.Ref
									|FROM
									|	Catalog.SalesPeople AS SalesPeople
									|WHERE
									|	SalesPeople.Description = &Description");
								   
				SPQuery.SetParameter("Description", ParsedJSON.account_owner);
				SPResult = SPQuery.Execute();
				If SPResult.IsEmpty() Then
					// salesperson is new
					NewSP = Catalogs.SalesPeople.CreateItem();
					NewSP.Description = ParsedJSON.account_owner;
					NewSP.Write();
					AddressLine.SalesPerson = NewSP.Ref;
				Else
					//sales person exists
					salesPerson = SPResult.Unload();
					AddressLine.SalesPerson = salesPerson[0].Ref;
				EndIf;
			EndIf;
		Except
		EndTry;
		
		AddressLine.Write();
	EndIf;
		
	Return "Success";
EndFunction

Function zoho_account_update(jsonin)
		
	ParsedJSON = InternetConnectionClientServer.DecodeJSON(jsonin);
	
	//get account uuid to update in acs
	apiQuery = new Query("SELECT
	                     |	zoho_accountCodeMap.company_ref
	                     |FROM
	                     |	Catalog.zoho_accountCodeMap AS zoho_accountCodeMap
	                     |WHERE
	                     |	zoho_accountCodeMap.zoho_id = &zoho_id");
					   
	apiQuery.SetParameter("zoho_id", ParsedJSON.account_id);
	queryResult = apiQuery.Execute();
	
	If NOT queryResult.IsEmpty() Then
		queryResultobj = queryResult.Unload();
		UpdatedAccount = queryResultobj[0].company_ref;
		UpdatedAccountObj = UpdatedAccount.GetObject();
		Try  // possible might break because of uniqueness problems or no update fields passed
			Try UpdatedAccountObj.Description = ParsedJSON.account_name; Except EndTry; 
		Except
			Return "Failed to update";
		EndTry;
		
		//Start of optional fields
		Try UpdatedAccountObj.Notes = ParsedJSON.description; Except EndTry;
		Try UpdatedAccountObj.Website = ParsedJSON.website; Except EndTry;
		
		Try // check for sales person
			If ParsedJSON.account_owner <> "" Then
				SPQuery = new Query("SELECT
				                    |	SalesPeople.Ref
				                    |FROM
				                    |	Catalog.SalesPeople AS SalesPeople
				                    |WHERE
				                    |	SalesPeople.Description = &Description");
								   
				SPQuery.SetParameter("Description", ParsedJSON.account_owner);
				SPResult = SPQuery.Execute();
				If SPResult.IsEmpty() Then
					// salesperson is new
					NewSP = Catalogs.SalesPeople.CreateItem();
					NewSP.Description = ParsedJSON.account_owner;
					NewSP.Write();
					UpdatedAccountObj.SalesPerson = NewSP.Ref;
				Else
					//sales person exists
					salesPerson = SPResult.Unload();
					UpdatedAccountObj.SalesPerson = salesPerson[0].Ref;
				EndIf;
			Else
				UpdatedAccountObj.SalesPerson = Catalogs.SalesPeople.EmptyRef();
			EndIf;
		Except
		EndTry;
		
		UpdatedAccountObj.DefaultCurrency = Catalogs.Currencies.USD;
		UpdatedAccountObj.Write();
	
	Else
		zoho_account(jsonin);
		Try // check if theres a contact related to it
			PathDef = "crm.zoho.com/crm/private/json/Contacts/";
					
			AuthHeader = "authtoken=" + Constants.zoho_auth_token.Get() + "&scope=crmapi&parentModule=Accounts" + "&id=" + ParsedJSON.account_id;
				
			URLstring = PathDef + "getRelatedRecords?" + AuthHeader;
			
			HeadersMap = New Map();			
			HTTPRequest = New HTTPRequest("", HeadersMap);	
			SSLConnection = New OpenSSLSecureConnection();
			HTTPConnection = New HTTPConnection(URLstring,,,,,,SSLConnection);
			Result = HTTPConnection.Post(HTTPRequest);
			ResultBody = Result.GetBodyAsString();
			ResultBodyJSON = InternetConnectionClientServer.DecodeJSON(ResultBody);
			
			ContactData = zoho_Functions.ZohoJSONParser(ResultBodyJSON.response.result.Contacts.row.FL);
			contactMap = New Map();
			Try contactMap.Insert("contact_id", ContactData.Get("CONTACTID")); Except Endtry; 
			Try contactMap.Insert("contact_owner", ContactData.Get("Contact Owner")); Except Endtry;
			Try contactMap.Insert("description", ContactData.Get("Description")); Except Endtry;
			Try contactMap.Insert("email", ContactData.Get("Email")); Except Endtry;
			Try contactMap.Insert("fax", ContactData.Get("Fax")); Except Endtry;
			Try contactMap.Insert("phone", ContactData.Get("Phone")); Except Endtry;
			Try contactMap.Insert("mobile", ContactData.Get("Mobile")); Except Endtry;
			Try contactMap.Insert("title", ContactData.Get("Title")); Except Endtry;
			Try contactMap.Insert("account_id", ContactData.Get("ACCOUNTID")); Except Endtry;
			Try contactMap.Insert("last_name", ContactData.Get("Last Name")); Except Endtry;
			
			mailingMap = New Map();
			Try mailingMap.Insert("first_name", ContactData.Get("First Name")); Except Endtry; 
			Try mailingMap.Insert("last_name", ContactData.Get("Last Name")); Except Endtry;
			Try mailingMap.Insert("mailing_street", ContactData.Get("Mailing Street")); Except Endtry;
			Try mailingMap.Insert("mailing_city", ContactData.Get("Mailing City")); Except Endtry;
			Try mailingMap.Insert("mailing_state", ContactData.Get("Mailing State")); Except Endtry;
			Try mailingMap.Insert("mailing_zip", ContactData.Get("Mailing Zip")); Except Endtry;
			Try mailingMap.Insert("mailing_country", ContactData.Get("Mailing Country")); Except Endtry;
			Try mailingMap.Insert("salutation", ContactData.Get("Salutation")); Except Endtry;
			Try mailingMap.Insert("department", ContactData.Get("Department")); Except Endtry;
			Try mailingMap.Insert("cust_mailing_street2", ContactData.Get("Mailing Street 2")); Except Endtry;
			Try mailingMap.Insert("cust_mailing_street3", ContactData.Get("Mailing Street3")); Except Endtry;
			Try mailingMap.Insert("cust_mailing_state", ContactData.Get("MailingState")); Except Endtry;
			Try mailingMap.Insert("cust_mailing_country", ContactData.Get("MailingCountry")); Except Endtry;
			
			contactMap.Insert("mailing_address", InternetConnectionClientServer.EncodeJSON(mailingMap));
					
			contactJSON = InternetConnectionClientServer.EncodeJSON(contactMap);
			zoho_contact(contactJSON);
			Return "couldnt find account to update so created a new record with its contacts";
		Except
			// no contact needed
			Return "couldnt find account to update so created a new record";
		EndTry;
	EndIf;
	
	//grab the default shiping and billing and update those.
	ParsedAddress = InternetConnectionClientServer.DecodeJSON(ParsedJSON.default_addresses);
	
	BillingQuery = New Query("SELECT
	                                |	Addresses.Ref
	                                |FROM
	                                |	Catalog.Addresses AS Addresses
	                                |WHERE
	                                |	Addresses.Owner = &Owner
	                                |	AND Addresses.DefaultBilling = TRUE");
	BillingQuery.SetParameter("Owner", UpdatedAccountObj.Ref);
	BillingResult = BillingQuery.Execute().Unload();
	addrResult = BillingResult[0].Ref;
	AddressLine = addrResult.GetObject();
	
	ShippingQuery = New Query("SELECT
	                          |	Addresses.Ref
	                          |FROM
	                          |	Catalog.Addresses AS Addresses
	                          |WHERE
	                          |	Addresses.Owner = &Owner
	                          |	AND Addresses.DefaultShipping = TRUE");
	ShippingQuery.SetParameter("Owner", UpdatedAccountObj.Ref);
	ShippingResult = ShippingQuery.Execute().Unload();
	shipping2 = ShippingResult[0].Ref;
	AddressLine2 = shipping2.GetObject();
	
	If AddressLine.Ref = AddressLine2.Ref AND (NOT BillingShippingSame(ParsedAddress)) Then
		//default shipping and billing are one address but updating to become 2 different addresses
		
		// make primary the default billing
		AddressLine.Description = "Default Billing";
		
		//uniqueness problems
		defaultbillQuery = New Query("SELECT
		                             |	Addresses.Ref
		                             |FROM
		                             |	Catalog.Addresses AS Addresses
		                             |WHERE
		                             |	Addresses.Description = &Description
		                             |	AND Addresses.Owner = &Owner");
		defaultbillQuery.SetParameter("Description", "Default Billing");
		defaultbillQuery.SetParameter("Owner", UpdatedAccountObj.Ref);
		dbResult = defaultbillQuery.Execute();
		dbref = dbResult.Unload();
		If NOT dbResult.IsEmpty() Then
			AddressLine.Description = "Default Billing" + string(dbref.Count() + 1);
		EndIf;
			
		AddressLine.DefaultShipping = False;
		Try AddressLine.AddressLine1 = ParsedAddress.billing_street; Except EndTry;
		Try AddressLine.AddressLine2 = ParsedAddress.cust_billing_street2; Except EndTry;// ferguson custom
		Try AddressLine.AddressLine3 = ParsedAddress.cust_billing_street3; Except EndTry; // ferguson custom
		Try AddressLine.City = ParsedAddress.billing_city; Except EndTry;
		
		Try // get state
			If ParsedAddress.billing_state <> "" Then
				
				StateQuery = new Query("SELECT
				                       |	States.Ref
				                       |FROM
				                       |	Catalog.States AS States
				                       |WHERE
				                       |	States.Code = &Code
				                       |	OR States.Description = &Description");
								   
				StateQuery.SetParameter("Code", Upper(ParsedAddress.billing_state));
				StateQuery.SetParameter("Description", Title(ParsedAddress.billing_state));
				StateResult = StateQuery.Execute().Unload();
				AddressLine.State = StateResult[0].Ref;
			Else
				AddressLine.State = Catalogs.States.EmptyRef();
			EndIf;
		Except
		EndTry;
		
		Try // ferguson custom state
			If ParsedAddress.cust_billing_state <> "" Then
				
				StateQuery = new Query("SELECT
				                       |	States.Ref
				                       |FROM
				                       |	Catalog.States AS States
				                       |WHERE
				                       |	States.Code = &Code
				                       |	OR States.Description = &Description");
								   
				StateQuery.SetParameter("Code", Upper(ParsedAddress.cust_billing_state));
				StateQuery.SetParameter("Description", Title(ParsedAddress.cust_billing_state));
				StateResult = StateQuery.Execute().Unload();
				AddressLine.State = StateResult[0].Ref;
			Else
				AddressLine.State = Catalogs.States.EmptyRef();
			EndIf;
		Except
		EndTry;
		
		
		Try AddressLine.ZIP = ParsedAddress.billing_zip; Except EndTry;
		
		Try // get country
			If ParsedAddress.billing_country <> "" Then
				
				CountryQuery = new Query("SELECT
				                         |	Countries.Ref
				                         |FROM
				                         |	Catalog.Countries AS Countries
				                         |WHERE
				                         |	Countries.Description = &Description
				                         |	OR Countries.Code = &Code");
								   
				CountryQuery.SetParameter("Code", Upper(ParsedAddress.billing_Country));
				CountryQuery.SetParameter("Description", Title(ParsedAddress.billing_Country));
				CountryResult = CountryQuery.Execute().Unload();
				AddressLine.Country = CountryResult[0].Ref;
			Else
				AddressLine.Country = Catalogs.Countries.EmptyRef();
			EndIf;
		Except
		EndTry;
		
		Try // ferguson safety country
			If ParsedAddress.cust_billing_country <> "" Then
				
				CountryQuery = new Query("SELECT
				                         |	Countries.Ref
				                         |FROM
				                         |	Catalog.Countries AS Countries
				                         |WHERE
				                         |	Countries.Description = &Description
				                         |	OR Countries.Code = &Code");
								   
				CountryQuery.SetParameter("Code", Upper(ParsedAddress.cust_billing_Country));
				CountryQuery.SetParameter("Description", Title(ParsedAddress.cust_billing_Country));
				CountryResult = CountryQuery.Execute().Unload();
				AddressLine.Country = CountryResult[0].Ref;
			Else
				AddressLine.Country = Catalogs.Countries.EmptyRef();
			EndIf;
		Except
		EndTry;
		
		Try AddressLine.Write(); Except Return "writing of default billing failed"; EndTry;
		
		//now make the new default shipping
		AddressLine3 = Catalogs.Addresses.CreateItem();
		AddressLine3.Owner = UpdatedAccountObj.Ref;
		AddressLine3.Description = "Default Shipping";
		
		//uniqueness problems
		defaultshipQuery = New Query("SELECT
		                             |	Addresses.Ref
		                             |FROM
		                             |	Catalog.Addresses AS Addresses
		                             |WHERE
		                             |	Addresses.Description = &Description
		                             |	AND Addresses.Owner = &Owner");
		defaultshipQuery.SetParameter("Description", "Default Shipping");
		defaultshipQuery.SetParameter("Owner", UpdatedAccountObj.Ref);
		dbResult1 = defaultshipQuery.Execute();
		dbref1 = dbResult1.Unload();
		If NOT dbResult1.IsEmpty() Then
			AddressLine3.Description = "Default Shipping" + string(dbref1.Count() + 1);
		EndIf;
		
		AddressLine3.DefaultBilling = False;
		AddressLine3.DefaultShipping = True;
		Try AddressLine3.AddressLine1 = ParsedAddress.shipping_street; Except EndTry;
		Try AddressLine3.City = ParsedAddress.shipping_city; Except EndTry;
		
		Try // get state
			If ParsedAddress.shipping_state <> "" Then
				
				StateQuery = new Query("SELECT
				                       |	States.Ref
				                       |FROM
				                       |	Catalog.States AS States
				                       |WHERE
				                       |	States.Code = &Code
				                       |	OR States.Description = &Description");
								   
				StateQuery.SetParameter("Code", Upper(ParsedAddress.shipping_state));
				StateQuery.SetParameter("Description", Title(ParsedAddress.shipping_state));
				StateResult = StateQuery.Execute().Unload();
				AddressLine3.State = StateResult[0].Ref;
			EndIf;
		Except
		EndTry;
		
		Try // ferguson custom state
			If ParsedAddress.cust_shipping_state <> "" Then
				
				StateQuery = new Query("SELECT
				                       |	States.Ref
				                       |FROM
				                       |	Catalog.States AS States
				                       |WHERE
				                       |	States.Code = &Code
				                       |	OR States.Description = &Description");
								   
				StateQuery.SetParameter("Code", Upper(ParsedAddress.cust_shipping_state));
				StateQuery.SetParameter("Description", Title(ParsedAddress.cust_shipping_state));
				StateResult = StateQuery.Execute().Unload();
				AddressLine3.State = StateResult[0].Ref;
			EndIf;
		Except
		EndTry;
		
		Try AddressLine3.ZIP = ParsedAddress.shipping_zip; Except EndTry;
		
		Try // get country
			If ParsedAddress.shipping_country <> "" Then
				
				CountryQuery = new Query("SELECT
				                         |	Countries.Ref
				                         |FROM
				                         |	Catalog.Countries AS Countries
				                         |WHERE
				                         |	Countries.Description = &Description
				                         |	OR Countries.Code = &Code");
								   
				CountryQuery.SetParameter("Code", Upper(ParsedAddress.shipping_country));
				CountryQuery.SetParameter("Description", Title(ParsedAddress.shipping_country));
				CountryResult = CountryQuery.Execute().Unload();
				AddressLine3.Country = CountryResult[0].Ref;
			EndIf;
		Except
		EndTry;
		
		Try // ferguson custom country
			If ParsedAddress.cust_shipping_country <> "" Then
				
				CountryQuery = new Query("SELECT
				                         |	Countries.Ref
				                         |FROM
				                         |	Catalog.Countries AS Countries
				                         |WHERE
				                         |	Countries.Description = &Description
				                         |	OR Countries.Code = &Code");
								   
				CountryQuery.SetParameter("Code", Upper(ParsedAddress.cust_shipping_country));
				CountryQuery.SetParameter("Description", Title(ParsedAddress.cust_shipping_country));
				CountryResult = CountryQuery.Execute().Unload();
				AddressLine3.Country = CountryResult[0].Ref;
			EndIf;
		Except
		EndTry;
		
		AddressLine3.Write();
		
		Return "Success";
		
	EndIf;
	
	// billing and shipping are seperate
	Try AddressLine.AddressLine1 = ParsedAddress.billing_street; Except EndTry;
	Try AddressLine.AddressLine2 = ParsedAddress.cust_billing_street2; Except EndTry;// ferguson custom
	Try AddressLine.AddressLine3 = ParsedAddress.cust_billing_street3; Except EndTry; // ferguson custom
	Try AddressLine.City = ParsedAddress.billing_city; Except EndTry;
	
	Try // get state
		If ParsedAddress.billing_state <> "" Then
			
			StateQuery = new Query("SELECT
			                       |	States.Ref
			                       |FROM
			                       |	Catalog.States AS States
			                       |WHERE
			                       |	States.Code = &Code
			                       |	OR States.Description = &Description");
							   
			StateQuery.SetParameter("Code", Upper(ParsedAddress.billing_state));
			StateQuery.SetParameter("Description", Title(ParsedAddress.billing_state));
			StateResult = StateQuery.Execute().Unload();
			AddressLine.State = StateResult[0].Ref;
		Else
			AddressLine.State = Catalogs.States.EmptyRef();
		EndIf;
	Except
	EndTry;
	
	Try // ferguson custom state
		If ParsedAddress.cust_billing_state <> "" Then
			
			StateQuery = new Query("SELECT
			                       |	States.Ref
			                       |FROM
			                       |	Catalog.States AS States
			                       |WHERE
			                       |	States.Code = &Code
			                       |	OR States.Description = &Description");
							   
			StateQuery.SetParameter("Code", Upper(ParsedAddress.cust_billing_state));
			StateQuery.SetParameter("Description", Title(ParsedAddress.cust_billing_state));
			StateResult = StateQuery.Execute().Unload();
			AddressLine.State = StateResult[0].Ref;
		Else
			AddressLine.State = Catalogs.States.EmptyRef();
		EndIf;
	Except
	EndTry;
	
	Try AddressLine.ZIP = ParsedAddress.billing_zip; Except EndTry;
	
	Try // get country
		If ParsedAddress.billing_country <> "" Then
			
			CountryQuery = new Query("SELECT
			                         |	Countries.Ref
			                         |FROM
			                         |	Catalog.Countries AS Countries
			                         |WHERE
			                         |	Countries.Description = &Description
			                         |	OR Countries.Code = &Code");
							   
			CountryQuery.SetParameter("Code", Upper(ParsedAddress.billing_country));
			CountryQuery.SetParameter("Description", Title(ParsedAddress.billing_country));
			CountryResult = CountryQuery.Execute().Unload();
			AddressLine.Country = CountryResult[0].Ref;
		Else
			AddressLine.Country = Catalogs.Countries.EmptyRef();
		EndIf;
	Except
	EndTry;
	
	Try // ferguson custom country
		If ParsedAddress.cust_billing_country <> "" Then
			
			CountryQuery = new Query("SELECT
			                         |	Countries.Ref
			                         |FROM
			                         |	Catalog.Countries AS Countries
			                         |WHERE
			                         |	Countries.Description = &Description
			                         |	OR Countries.Code = &Code");
							   
			CountryQuery.SetParameter("Code", Upper(ParsedAddress.cust_billing_country));
			CountryQuery.SetParameter("Description", Title(ParsedAddress.cust_billing_country));
			CountryResult = CountryQuery.Execute().Unload();
			AddressLine.Country = CountryResult[0].Ref;
		Else
			AddressLine.Country = Catalogs.Countries.EmptyRef();
		EndIf;
	Except
	EndTry;
	
	Try AddressLine.Write(); Except Return "writing of default billing failed"; EndTry;
	
	//ShippingQuery = New Query("SELECT
	//						  |	Addresses.Ref
	//						  |FROM
	//						  |	Catalog.Addresses AS Addresses
	//						  |WHERE
	//						  |	Addresses.Owner = &Owner
	//						  |	AND Addresses.DefaultShipping = TRUE");
	//ShippingQuery.SetParameter("Owner", UpdatedAccountObj.Ref);
	//ShippingResult = ShippingQuery.Execute().Unload();
	//shipping2 = ShippingResult[0].Ref;
	//AddressLine2 = shipping2.GetObject();
	
	Try AddressLine2.AddressLine1 = ParsedAddress.shipping_street; Except EndTry;
	Try AddressLine2.AddressLine2 = ParsedAddress.cust_shipping_street2; Except EndTry; // ferguson custom
	Try AddressLine2.AddressLine3 = ParsedAddress.cust_shipping_street3; Except EndTry; // ferguson custom
	Try AddressLine2.City = ParsedAddress.shipping_city; Except EndTry;
		
	Try // get state
		If ParsedAddress.shipping_state <> "" Then
			
			StateQuery = new Query("SELECT
			                       |	States.Ref
			                       |FROM
			                       |	Catalog.States AS States
			                       |WHERE
			                       |	States.Code = &Code
			                       |	OR States.Description = &Description");
							   
			StateQuery.SetParameter("Code", Upper(ParsedAddress.shipping_state));
			StateQuery.SetParameter("Description", Title(ParsedAddress.shipping_state));
			StateResult = StateQuery.Execute().Unload();
			AddressLine2.State = StateResult[0].Ref;
		Else
			AddressLine2.State = Catalogs.States.EmptyRef();
			
		EndIf;
	Except
	EndTry;
	
	Try //ferguson custom state
		If ParsedAddress.cust_shipping_state <> "" Then
			
			StateQuery = new Query("SELECT
			                       |	States.Ref
			                       |FROM
			                       |	Catalog.States AS States
			                       |WHERE
			                       |	States.Code = &Code
			                       |	OR States.Description = &Description");
							   
			StateQuery.SetParameter("Code", Upper(ParsedAddress.cust_shipping_state));
			StateQuery.SetParameter("Description", Title(ParsedAddress.cust_shipping_state));
			StateResult = StateQuery.Execute().Unload();
			AddressLine2.State = StateResult[0].Ref;
		Else
			AddressLine2.State = Catalogs.States.EmptyRef();
			
		EndIf;
	Except
	EndTry;
	
	Try AddressLine2.ZIP = ParsedAddress.shipping_zip; Except EndTry;
	
	Try // get country
		If ParsedAddress.shipping_country <> "" Then
			
			CountryQuery = new Query("SELECT
			                         |	Countries.Ref
			                         |FROM
			                         |	Catalog.Countries AS Countries
			                         |WHERE
			                         |	Countries.Description = &Description
			                         |	OR Countries.Code = &Code");
							   
			CountryQuery.SetParameter("Code", Upper(ParsedAddress.shipping_country));
			CountryQuery.SetParameter("Description", Title(ParsedAddress.shipping_country));
			CountryResult = CountryQuery.Execute().Unload();
			AddressLine2.Country = CountryResult[0].Ref;
		Else
			AddressLine2.Country = Catalogs.Countries.EmptyRef();
		EndIf;
	Except
	EndTry;
	
	Try // ferguson custom country
		If ParsedAddress.cust_shipping_country <> "" Then
			
			CountryQuery = new Query("SELECT
			                         |	Countries.Ref
			                         |FROM
			                         |	Catalog.Countries AS Countries
			                         |WHERE
			                         |	Countries.Description = &Description
			                         |	OR Countries.Code = &Code");
							   
			CountryQuery.SetParameter("Code", Upper(ParsedAddress.cust_shipping_country));
			CountryQuery.SetParameter("Description", Title(ParsedAddress.cust_shipping_country));
			CountryResult = CountryQuery.Execute().Unload();
			AddressLine2.Country = CountryResult[0].Ref;
		Else
			AddressLine2.Country = Catalogs.Countries.EmptyRef();
		EndIf;
	Except
	EndTry;
	
	Try AddressLine2.Write(); Except Return "writing shipping default failed"; EndTry;
	
	Return "Success";
EndFunction

Function zoho_contact(jsonin)
		
	ParsedJSON = InternetConnectionClientServer.DecodeJSON(jsonin);
	
	//check if account exist or else we cannot create an addresses. cant have address with no owner in acs.
	apiQuery = new Query("SELECT
	                     |	zoho_accountCodeMap.company_ref
	                     |FROM
	                     |	Catalog.zoho_accountCodeMap AS zoho_accountCodeMap
	                     |WHERE
	                     |	zoho_accountCodeMap.zoho_id = &zoho_id");
					   
	apiQuery.SetParameter("zoho_id", ParsedJSON.account_id);
	queryResult = apiQuery.Execute();
	If queryResult.IsEmpty() Then
		Return "account does not exist in accountingsuite";
	Else
		queryResultobj = queryResult.Unload();
		companyRef = queryResultobj[0].company_ref;
		companyObj = companyRef.GetObject();
	EndIf;

	//Create a contact in ACS
	NewContact = Catalogs.Addresses.CreateItem();
	NewContact.Owner = companyObj.Ref;
	
	Try
		NewContact.Description = ParsedJSON.last_name;
	Except
		Return "Fail: contactID/last_name";
	EndTry;
	
	//start of optional fields
	Try NewContact.Email = ParsedJSON.email; Except EndTry;
	Try NewContact.Notes = ParsedJSON.description; Except EndTry;
	Try NewContact.Fax = ParsedJSON.fax; Except EndTry;
	Try NewContact.Phone = ParsedJSON.phone; Except EndTry;
	Try NewContact.Cell = ParsedJSON.mobile; Except EndTry;
	Try NewContact.JobTitle = ParsedJSON.title; Except EndTry;
	//Try NewContact.CF1String = ParsedJSON.department; Except EndTry; //ferguson department
	
	Try // check for sales person
		If ParsedJSON.contact_owner <> "" Then
			SPQuery = new Query("SELECT
			                    |	SalesPeople.Ref
			                    |FROM
			                    |	Catalog.SalesPeople AS SalesPeople
			                    |WHERE
			                    |	SalesPeople.Description = &Description");
							   
			SPQuery.SetParameter("Description", ParsedJSON.contact_owner);
			SPResult = SPQuery.Execute();
			If SPResult.IsEmpty() Then
				// salesperson is new
				NewSP = Catalogs.SalesPeople.CreateItem();
				NewSP.Description = ParsedJSON.account_owner;
				NewSP.Write();
				NewContact.SalesPerson = NewSP.Ref;
			Else
				//sales person exists
				salesPerson = SPResult.Unload();
				NewContact.SalesPerson = salesPerson[0].Ref;
			EndIf;
		EndIf;
	Except
	EndTry;
	
	
	NewContact.DefaultBilling = False;
	NewContact.DefaultShipping = False;
	
	//grab the mailing address.
	ParsedAddress = InternetConnectionClientServer.DecodeJSON(ParsedJSON.mailing_address);
	
	Try NewContact.CF1String = ParsedAddress.department; Except EndTry; //ferguson department
	
	Try newContact.FirstName = ParsedAddress.first_name; Except EndTry;
	Try newContact.LastName = ParsedAddress.last_name; Except EndTry;
	Try newContact.Salutation = ParsedAddress.salutation; Except EndTry;
	
	
	Try newContact.AddressLine1 = ParsedAddress.mailing_street; Except EndTry;
	Try newContact.AddressLine2 = ParsedAddress.cust_mailing_street2; Except EndTry; // ferguson custom
	Try newContact.AddressLine3 = ParsedAddress.cust_mailing_street3; Except EndTry; // ferguson custom
	Try newContact.City = ParsedAddress.mailing_city; Except EndTry;
	
	Try // get state
		If ParsedAddress.mailing_state <> "" Then
			
			StateQuery = new Query("SELECT
			                       |	States.Ref
			                       |FROM
			                       |	Catalog.States AS States
			                       |WHERE
			                       |	States.Code = &Code
			                       |	OR States.Description = &Description");
							   
			StateQuery.SetParameter("Code", Upper(ParsedAddress.mailing_state));
			StateQuery.SetParameter("Description", Title(ParsedAddress.mailing_state));
			StateResult = StateQuery.Execute().Unload();
			newContact.State = StateResult[0].Ref;
		EndIf;
	Except
	EndTry;
	
	Try // ferguson custom state
		If ParsedAddress.cust_mailing_state <> "" Then
			
			StateQuery = new Query("SELECT
			                       |	States.Ref
			                       |FROM
			                       |	Catalog.States AS States
			                       |WHERE
			                       |	States.Code = &Code
			                       |	OR States.Description = &Description");
							   
			StateQuery.SetParameter("Code", Upper(ParsedAddress.cust_mailing_state));
			StateQuery.SetParameter("Description", Title(ParsedAddress.cust_mailing_state));
			StateResult = StateQuery.Execute().Unload();
			newContact.State = StateResult[0].Ref;
		EndIf;
	Except
	EndTry;
	
	Try newContact.ZIP = ParsedAddress.mailing_zip; Except EndTry;
	
	Try // get country
		If ParsedAddress.mailing_country <> "" Then
			
			CountryQuery = new Query("SELECT
			                         |	Countries.Ref
			                         |FROM
			                         |	Catalog.Countries AS Countries
			                         |WHERE
			                         |	Countries.Description = &Description
			                         |	OR Countries.Code = &Code");
							   
			CountryQuery.SetParameter("Code", Upper(ParsedAddress.mailing_Country));
			CountryQuery.SetParameter("Description", Title(ParsedAddress.mailing_Country));
			CountryResult = CountryQuery.Execute().Unload();
			newContact.Country = CountryResult[0].Ref;
		EndIf;
	Except
	EndTry;
	
	Try // ferguson custom country
		If ParsedAddress.cust_mailing_country <> "" Then
			
			CountryQuery = new Query("SELECT
			                         |	Countries.Ref
			                         |FROM
			                         |	Catalog.Countries AS Countries
			                         |WHERE
			                         |	Countries.Description = &Description
			                         |	OR Countries.Code = &Code");
							   
			CountryQuery.SetParameter("Code", Upper(ParsedAddress.cust_mailing_Country));
			CountryQuery.SetParameter("Description", Title(ParsedAddress.cust_mailing_Country));
			CountryResult = CountryQuery.Execute().Unload();
			newContact.Country = CountryResult[0].Ref;
		EndIf;
	Except
	EndTry;
	
	NewContact.Write();
	
	//create a record of the acs_apicode to zoho id mapping
	newRecord = Catalogs.zoho_contactCodeMap.CreateItem();
	newRecord.address_ref = newContact.Ref;
	Try 
		newRecord.zoho_id = ParsedJSON.contact_id;	
	Except
		Return "Fail: No zoho id";
	EndTry;
	newRecord.Write();
	
	Return "Success";
EndFunction

Function zoho_contact_update(jsonin)
	
	ParsedJSON = InternetConnectionClientServer.DecodeJSON(jsonin);
	
	//get account uuid to update in acs
	apiQuery = new Query("SELECT
	                     |	zoho_contactCodeMap.address_ref
	                     |FROM
	                     |	Catalog.zoho_contactCodeMap AS zoho_contactCodeMap
	                     |WHERE
	                     |	zoho_contactCodeMap.zoho_id = &zoho_id");
					   
	apiQuery.SetParameter("zoho_id", ParsedJSON.contact_id);
	queryResult = apiQuery.Execute();
	
	If NOT queryResult.IsEmpty() Then
		queryResultobj = queryResult.Unload();
		UpdatedContact = queryResultobj[0].address_ref;
		UpdatedContactObj = UpdatedContact.GetObject();
		
		//check if account exist or else we cannot create an addresses. cant have address with no owner in acs.
		apiQuery = new Query("SELECT
		                     |	zoho_accountCodeMap.company_ref
		                     |FROM
		                     |	Catalog.zoho_accountCodeMap AS zoho_accountCodeMap
		                     |WHERE
		                     |	zoho_accountCodeMap.zoho_id = &zoho_id");
						   
		apiQuery.SetParameter("zoho_id", ParsedJSON.account_id);
		queryResult = apiQuery.Execute();
		If queryResult.IsEmpty() Then
			Return "account does not exist in accountingsuite";
		Else
			queryResultobj = queryResult.Unload();
			companyRef = queryResultobj[0].company_ref;
			companyObj = companyRef.GetObject();
		EndIf;
		
		UpdatedContactObj.Owner = companyObj.Ref;
		
		//start of optional fields
		Try UpdatedContactObj.Email = ParsedJSON.email; Except EndTry;
		Try UpdatedContactObj.Notes = ParsedJSON.description; Except EndTry;
		Try UpdatedContactObj.Fax = ParsedJSON.fax; Except EndTry;
		Try UpdatedContactObj.Phone = ParsedJSON.phone; Except EndTry;
		Try UpdatedContactObj.Cell = ParsedJSON.mobile; Except EndTry;
		Try UpdatedContactObj.JobTitle = ParsedJSON.title; Except EndTry;
		
		Try // check for sales person
			If ParsedJSON.contact_owner <> "" Then
				SPQuery = new Query("SELECT
				                    |	SalesPeople.Ref
				                    |FROM
				                    |	Catalog.SalesPeople AS SalesPeople
				                    |WHERE
				                    |	SalesPeople.Description = &Description");
								   
				SPQuery.SetParameter("Description", ParsedJSON.contact_owner);
				SPResult = SPQuery.Execute();
				If SPResult.IsEmpty() Then
					// salesperson is new
					NewSP = Catalogs.SalesPeople.CreateItem();
					NewSP.Description = ParsedJSON.account_owner;
					NewSP.Write();
					UpdatedContactObj.SalesPerson = NewSP.Ref;
				Else
					//sales person exists
					salesPerson = SPResult.Unload();
					UpdatedContactObj.SalesPerson = salesPerson[0].Ref;
				EndIf;
			EndIf;
		Except
		EndTry;
		
		//grab the mailing address.
		ParsedAddress = InternetConnectionClientServer.DecodeJSON(ParsedJSON.mailing_address);
		
		Try UpdatedContactObj.CF1String = ParsedAddress.department; Except EndTry; //ferguson department
		
		Try UpdatedContactObj.FirstName = ParsedAddress.first_name; Except EndTry;
		Try UpdatedContactObj.LastName = ParsedAddress.last_name; Except EndTry;
		Try UpdatedContactObj.Salutation = ParsedAddress.salutation; Except EndTry;
		
		Try UpdatedContactObj.AddressLine1 = ParsedAddress.mailing_street; Except EndTry;
		Try UpdatedContactObj.AddressLine2 = ParsedAddress.cust_mailing_street2; Except EndTry; // ferguson custom
		Try UpdatedContactObj.AddressLine3 = ParsedAddress.cust_mailing_street3; Except EndTry; // ferguson custom
		Try UpdatedContactObj.City = ParsedAddress.mailing_city; Except EndTry;
		
		Try // get state
			If ParsedAddress.mailing_state <> "" Then
				
				StateQuery = new Query("SELECT
				                       |	States.Ref
				                       |FROM
				                       |	Catalog.States AS States
				                       |WHERE
				                       |	States.Code = &Code
				                       |	OR States.Description = &Description");
								   
				StateQuery.SetParameter("Code", Upper(ParsedAddress.mailing_state));
				StateQuery.SetParameter("Description", Title(ParsedAddress.mailing_state));
				StateResult = StateQuery.Execute().Unload();
				UpdatedContactObj.State = StateResult[0].Ref;
			Else
				UpdatedContactObj.State = Catalogs.States.EmptyRef();
			EndIf;
		Except
		EndTry;
		
		Try // ferguson custom state
			If ParsedAddress.cust_mailing_state <> "" Then
				
				StateQuery = new Query("SELECT
				                       |	States.Ref
				                       |FROM
				                       |	Catalog.States AS States
				                       |WHERE
				                       |	States.Code = &Code
				                       |	OR States.Description = &Description");
								   
				StateQuery.SetParameter("Code", Upper(ParsedAddress.cust_mailing_state));
				StateQuery.SetParameter("Description", Title(ParsedAddress.cust_mailing_state));
				StateResult = StateQuery.Execute().Unload();
				UpdatedContactObj.State = StateResult[0].Ref;
			Else
				UpdatedContactObj.State = Catalogs.States.EmptyRef();
			EndIf;
		Except
		EndTry;
		
		Try UpdatedContactObj.ZIP = ParsedAddress.mailing_zip; Except EndTry;
		
		Try // get country
			If ParsedAddress.mailing_country <> "" Then
				
				CountryQuery = new Query("SELECT
				                         |	Countries.Ref
				                         |FROM
				                         |	Catalog.Countries AS Countries
				                         |WHERE
				                         |	Countries.Description = &Description
				                         |	OR Countries.Code = &Code");
								   
				CountryQuery.SetParameter("Code", Upper(ParsedAddress.mailing_Country));
				CountryQuery.SetParameter("Description", Title(ParsedAddress.mailing_Country));
				CountryResult = CountryQuery.Execute().Unload();
				UpdatedContactObj.Country = CountryResult[0].Ref;
			Else
				UpdatedContactObj.Country = Catalogs.Countries.EmptyRef();
			EndIf;
		Except
		EndTry;
		
		Try // ferguson custom country
			If ParsedAddress.cust_mailing_country <> "" Then
				
				CountryQuery = new Query("SELECT
				                         |	Countries.Ref
				                         |FROM
				                         |	Catalog.Countries AS Countries
				                         |WHERE
				                         |	Countries.Description = &Description
				                         |	OR Countries.Code = &Code");
								   
				CountryQuery.SetParameter("Code", Upper(ParsedAddress.cust_mailing_Country));
				CountryQuery.SetParameter("Description", Title(ParsedAddress.cust_mailing_Country));
				CountryResult = CountryQuery.Execute().Unload();
				UpdatedContactObj.Country = CountryResult[0].Ref;
			Else
				UpdatedContactObj.Country = Catalogs.Countries.EmptyRef();
			EndIf;
		Except
		EndTry;
		
		UpdatedContactObj.Write();	
	
	Else
		//check if no record of this contact but now wants the owner to be an existing account
		//only create if the account name exists
		apiQuery = new Query("SELECT
							 |	zoho_accountCodeMap.company_ref
							 |FROM
							 |	Catalog.zoho_accountCodeMap AS zoho_accountCodeMap
							 |WHERE
							 |	zoho_accountCodeMap.zoho_id = &zoho_id");
						   
		apiQuery.SetParameter("zoho_id", ParsedJSON.account_id);
		queryResult = apiQuery.Execute();
		If queryResult.IsEmpty() Then
			Return "couldnt find contact to update.";
		Else
			zoho_contact(jsonin);
		EndIf;
		return "asudfoouo";
	EndIf;
	
	Return "Success877h";
EndFunction

Function BillingShippingSame(ParsedAddress)	
	If ParsedAddress.billing_street <>  ParsedAddress.shipping_street Then
		Return False;
	EndIf;
	If ParsedAddress.billing_city <>  ParsedAddress.shipping_city Then
		Return False;
	EndIf;
	If ParsedAddress.billing_state <>  ParsedAddress.shipping_state Then
		Return False;
	EndIf;
	If ParsedAddress.billing_zip <>  ParsedAddress.shipping_zip Then
		Return False;
	EndIf;
	If ParsedAddress.billing_country <>  ParsedAddress.shipping_country Then
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

Function zoho_salesorder(jsonin)
	ParsedJSON = InternetConnectionClientServer.DecodeJSON(jsonin);
	
	apiQuery = new Query("SELECT
	                     |	zoho_SOCodeMap.salesorder_ref
	                     |FROM
	                     |	Catalog.zoho_SOCodeMap AS zoho_SOCodeMap
	                     |WHERE
	                     |	zoho_SOCodeMap.zoho_id = &zoho_id");
					   
	apiQuery.SetParameter("zoho_id", ParsedJSON.salesorder_id);
	queryResult = apiQuery.Execute();
	queryResultunload = queryResult.Unload();
	
	If queryResult.IsEmpty() Then
		////need to create SO
		PathDef = "crm.zoho.com/crm/private/json/SalesOrders/";
				
		AuthHeader = "authtoken=" + Constants.zoho_auth_token.Get() + "&scope=crmapi" + "&id=" + ParsedJSON.salesorder_id;
			
		URLstring = PathDef + "getRecordById?" + AuthHeader;
		
		HeadersMap = New Map();			
		HTTPRequest = New HTTPRequest("", HeadersMap);	
		SSLConnection = New OpenSSLSecureConnection();
		HTTPConnection = New HTTPConnection(URLstring,,,,,,SSLConnection);
		Result = HTTPConnection.Post(HTTPRequest);
		ResultBody = Result.GetBodyAsString();
		ResultBodyJSON = InternetConnectionClientServer.DecodeJSON(ResultBody);
		
		SOData = zoho_Functions.ZohoJSONParser(ResultBodyJSON.response.result.SalesOrders.row.FL);
		NewSO = documents.SalesOrder.CreateDocument();
		
		//get customer
		idQuery = new Query("SELECT
		                    |	zoho_accountCodeMap.company_ref
		                    |FROM
		                    |	Catalog.zoho_accountCodeMap AS zoho_accountCodeMap
		                    |WHERE
		                    |	zoho_accountCodeMap.zoho_id = &zoho_id");
					   
		idQuery.SetParameter("zoho_id", SOData.Get("ACCOUNTID")); // zoho account id
		idAccountResult = idQuery.Execute().Unload();
		
		Try NewSO.Company = idAccountResult[0].company_ref;
		Except
			return "zoho account id does not exist";
		EndTry;
		
		//get contact
		contactid = SOData.Get("CONTACTID");
		If contactid <> Undefined Then
			Try 
				idQuery = new Query("SELECT
				                    |	zoho_contactCodeMap.address_ref
				                    |FROM
				                    |	Catalog.zoho_contactCodeMap AS zoho_contactCodeMap
				                    |WHERE
				                    |	zoho_contactCodeMap.zoho_id = &zoho_id");
							   
				idQuery.SetParameter("zoho_id", contactid); // zoho contact id
				idContactResult = idQuery.Execute().Unload();
				
				contactobj = idContactResult[0].address_ref;
				// if contact belongs to company then its a ship to, if it doesnt its a dropship
				If contactobj.Owner.Ref = NewSO.Company.Ref Then
					NewSO.ShipTo = contactobj.Ref;
				Else
					NewSO.DropshipCompany = contactobj.Owner.Ref;
					NewSO.DropshipShipTo = contactobj.Ref;
					//use dropship, and just load default shipping
					shipQuery = New Query("SELECT
										  |	Addresses.Ref
										  |FROM
										  |	Catalog.Addresses AS Addresses
										  |WHERE
										  |	Addresses.DefaultShipping = TRUE
										  |	AND Addresses.Owner.Ref = &Ref");
					   
					shipQuery.SetParameter("Ref", NewSO.Company.Ref);
					shipResult = shipQuery.Execute().Unload();
					NewSO.ShipTo = shipResult[0].Ref;
				EndIf;
			Except
				Return "zoho contact id does not exist";	
			EndTry;
		Else
			//no contact, load default
			shipQuery = New Query("SELECT
									  |	Addresses.Ref
									  |FROM
									  |	Catalog.Addresses AS Addresses
									  |WHERE
									  |	Addresses.DefaultShipping = TRUE
									  |	AND Addresses.Owner.Ref = &Ref");
				   
			shipQuery.SetParameter("Ref", NewSO.Company.Ref);
			shipResult = shipQuery.Execute().Unload();
			NewSO.ShipTo = shipResult[0].Ref;
		EndIf;
				
		NewSO.Number = Right(SOData.Get("SO Number"), 6);
		
		Try
			//check if created from a quote in acs
			quoteQuery = new Query("SELECT
			                       |	zoho_quoteCodeMap.quote_ref
			                       |FROM
			                       |	Catalog.zoho_QuoteCodeMap AS zoho_quoteCodeMap
			                       |WHERE
			                       |	zoho_quoteCodeMap.zoho_id = &zoho_id");
						   
			quoteQuery.SetParameter("zoho_id", SOData.Get("QUOTEID"));
			quotecheck = quoteQuery.Execute().Unload();
			NewSO.BaseDocument = quotecheck[0].quote_ref;
		Except
			// no quote
		EndTry;
		
		Try NewSO.Memo = SOData.Get("Description"); Except Endtry;
		Try NewSO.EmailNote = SOData.Get("Terms and Conditions"); Except Endtry;
		Try NewSO.RefNum = SOData.Get("Purchase Order"); Except Endtry;
		Try NewSO.DeliveryDate = Date(SOData.Get("Due Date")); Except Endtry;
		
		NewSO.Date = CurrentSessionDate();
		NewSO.Currency = GeneralFunctionsReusable.DefaultCurrency();
		NewSO.Location = GeneralFunctions.GetDefaultLocation();//Catalogs.Locations.MainWarehouse;
		NewSO.CreatedFromZoho = True;
		
		TotalDiscount = 0;
		TotalTax = 0;
		taxablesubtotal = 0;
		LineItemsTotal = 0;
		For Each lineitem in SOData.Get("Product Details") Do
			newLineItem = NewSO.LineItems.Add();
			
			//get product
			idQuery = new Query("SELECT
			                    |	zoho_productCodeMap.product_ref
			                    |FROM
			                    |	Catalog.zoho_productCodeMap AS zoho_productCodeMap
			                    |WHERE
			                    |	zoho_productCodeMap.zoho_id = &zoho_id");
						   
			idQuery.SetParameter("zoho_id", lineitem.Get("Product Id")); // zoho product id
			idProductResult = idQuery.Execute().Unload();
			
			Try newLineItem.Product = idProductResult[0].product_ref;
			Except
				return "zoho product id doesnt exist";
			EndTry;
			
			newLineItem.ProductDescription = newLineItem.Product.Description;
			newLineItem.Unit = newLineItem.Product.UnitSet.DefaultSaleUnit;
			newLineItem.Location = NewSO.Location;
			newLineItem.DeliveryDate = NewSO.DeliveryDate;
			
			newLineItem.PriceUnits = Number(lineitem.Get("List Price")); // zoho list price
			newLineitem.QtyUnits = Number(lineitem.Get("Quantity")); // zoho quantity
			//newLineitem.LineTotal =  Number(lineitem.Get("Total After Discount")); // zoho total ignoring tax
			newLineitem.LineTotal =  newLineItem.PriceUnits * newLineitem.QtyUnits; // zoho total ignoring tax

			LineItemsTotal = LineItemsTotal + newLineitem.LineTotal;
			TotalDiscount = TotalDiscount + Number(lineitem.Get("Discount")); // zoho line discount
			If Number(lineitem.Get("Tax")) = 0 AND Number(SOData.Get("Tax")) = 0 Then
				newLineitem.Taxable = False;
			Else
				newLineitem.Taxable = True;
				TotalTax = TotalTax + Number(lineitem.Get("Tax")); // zoho line tax
				taxablesubtotal = taxablesubtotal + newLineitem.LineTotal;
			EndIf;
			
		EndDo;
		NewSO.LineSubtotal = LineItemsTotal;  
		NewSO.Shipping = SOData.Get("Adjustment");
		NewSO.Discount = (- Number(TotalDiscount + SOData.Get("Discount"))); // zoho overall discount
		NewSO.DiscountPercent = -(NewSO.Discount/NewSO.LineSubtotal) * 100;
		NewSO.SalesTax = TotalTax + SOData.Get("Tax");
		NewSO.DocumentTotal = SOData.Get("Grand Total");
		NewSO.TaxableSubtotal = taxablesubtotal;
		
		NewSO.SubTotal = LineItemsTotal + NewSO.Discount;
		NewSO.DocumentTotalRC = NewSO.DocumentTotal;
		NewSO.ExchangeRate = 1;
		
		billQuery = New Query("SELECT
		                      |	Addresses.Ref
		                      |FROM
		                      |	Catalog.Addresses AS Addresses
		                      |WHERE
		                      |	Addresses.DefaultBilling = TRUE
		                      |	AND Addresses.Owner.Ref = &Ref");
	       
		billQuery.SetParameter("Ref", NewSO.Company.Ref);
		billResult = billQuery.Execute().Unload();
		NewSO.BillTo = billResult[0].Ref;
				
		NewSO.Write(DocumentWriteMode.Posting);
		//NewSO.Write();
		
		//create a record of the acs_apicode to zoho id mapping
		newRecord = Catalogs.zoho_SOCodeMap.CreateItem(); 
		newRecord.salesorder_ref = NewSO.Ref;
		Try 
			newRecord.zoho_id = SOData.Get("SALESORDERID");
			
		Except
			Return "Fail: No zoho id";
		EndTry;
		newRecord.Write();
		
	Else
		////updating a SO
		PathDef = "crm.zoho.com/crm/private/json/SalesOrders/";
				
		AuthHeader = "authtoken=" + Constants.zoho_auth_token.Get() + "&scope=crmapi" + "&id=" + ParsedJSON.salesorder_id;
			
		URLstring = PathDef + "getRecordById?" + AuthHeader;
		
		HeadersMap = New Map();			
		HTTPRequest = New HTTPRequest("", HeadersMap);	
		SSLConnection = New OpenSSLSecureConnection();
		HTTPConnection = New HTTPConnection(URLstring,,,,,,SSLConnection);
		Result = HTTPConnection.Post(HTTPRequest);
		ResultBody = Result.GetBodyAsString();
		ResultBodyJSON = InternetConnectionClientServer.DecodeJSON(ResultBody);
		SOData = zoho_Functions.ZohoJSONParser(ResultBodyJSON.response.result.SalesOrders.row.FL);

		upSO = queryResultunload[0].salesorder_ref;
		UpdatedSO = upSO.GetObject();
		
		//get customer
		idQuery = new Query("SELECT
		                    |	zoho_accountCodeMap.company_ref
		                    |FROM
		                    |	Catalog.zoho_accountCodeMap AS zoho_accountCodeMap
		                    |WHERE
		                    |	zoho_accountCodeMap.zoho_id = &zoho_id");
					   
		idQuery.SetParameter("zoho_id", SOData.Get("ACCOUNTID")); // zoho account id
		idAccountResult = idQuery.Execute().Unload();
		
		Try UpdatedSO.Company = idAccountResult[0].company_ref;
		Except
			return "zoho account id does not exist";
		EndTry;
		
		//get contact
		contactid = SOData.Get("CONTACTID");
		If contactid <> Undefined Then
			Try 
				idQuery = new Query("SELECT
				                    |	zoho_contactCodeMap.address_ref
				                    |FROM
				                    |	Catalog.zoho_contactCodeMap AS zoho_contactCodeMap
				                    |WHERE
				                    |	zoho_contactCodeMap.zoho_id = &zoho_id");
							   
				idQuery.SetParameter("zoho_id", contactid); // zoho contact id
				idContactResult = idQuery.Execute().Unload();
				
				contactobj = idContactResult[0].address_ref;
				// if contact belongs to company then its a ship to, if it doesnt its a dropship
				If contactobj.Owner.Ref = UpdatedSO.Company.Ref Then
					UpdatedSO.ShipTo = contactobj.Ref;
				Else
					UpdatedSO.DropshipCompany = contactobj.Owner.Ref;
					UpdatedSO.DropshipShipTo = contactobj.Ref;
					//use dropship, and just load default shipping
					shipQuery = New Query("SELECT
										  |	Addresses.Ref
										  |FROM
										  |	Catalog.Addresses AS Addresses
										  |WHERE
										  |	Addresses.DefaultShipping = TRUE
										  |	AND Addresses.Owner.Ref = &Ref");
					   
					shipQuery.SetParameter("Ref", UpdatedSO.Company.Ref);
					shipResult = shipQuery.Execute().Unload();
					UpdatedSO.ShipTo = shipResult[0].Ref;
				EndIf;
			Except
				Return "zoho contact id does not exist";	
			EndTry;
		Else
			//no contact, load default
			shipQuery = New Query("SELECT
									  |	Addresses.Ref
									  |FROM
									  |	Catalog.Addresses AS Addresses
									  |WHERE
									  |	Addresses.DefaultShipping = TRUE
									  |	AND Addresses.Owner.Ref = &Ref");
				   
			shipQuery.SetParameter("Ref", UpdatedSO.Company.Ref);
			shipResult = shipQuery.Execute().Unload();
			UpdatedSO.ShipTo = shipResult[0].Ref;
		EndIf;
		
		UpdatedSO.Number = Right(SOData.Get("SO Number"),6); 
		
		Try UpdatedSO.Memo = SOData.Get("Description"); Except Endtry;
		Try UpdatedSO.EmailNote = SOData.Get("Terms and Conditions"); Except Endtry;
		Try UpdatedSO.RefNum = SOData.Get("Purchase Order"); Except Endtry;
		Try UpdatedSO.DeliveryDate = Date(SOData.Get("Due Date")); Except Endtry;
		
		//get rid of line items before rewriting them
		UpdatedSO.LineItems.Clear();
		
		TotalDiscount = 0;
		TotalTax = 0;
		taxablesubtotal = 0;
		LineItemsTotal = 0;
		For Each lineitem in SOData.Get("Product Details") Do
			newLineItem = UpdatedSO.LineItems.Add();
			
			//get product
			idQuery = new Query("SELECT
			                    |	zoho_productCodeMap.product_ref
			                    |FROM
			                    |	Catalog.zoho_productCodeMap AS zoho_productCodeMap
			                    |WHERE
			                    |	zoho_productCodeMap.zoho_id = &zoho_id");
						   
			idQuery.SetParameter("zoho_id", lineitem.Get("Product Id")); // zoho product id
			idProductResult = idQuery.Execute().Unload();
			
			Try newLineItem.Product = idProductResult[0].product_ref;
			Except
				return "product id does not exist";
			EndTry;
			
			newLineItem.ProductDescription = newLineItem.Product.Description;
			newLineItem.Unit = newLineItem.Product.UnitSet.DefaultSaleUnit;
			newLineItem.Location = UpdatedSO.Location;
			newLineItem.DeliveryDate = UpdatedSO.DeliveryDate;
			
			newLineItem.PriceUnits = Number(lineitem.Get("List Price")); // zoho list price
			newLineitem.QtyUnits = Number(lineitem.Get("Quantity")); // zoho quantity
			//newLineitem.LineTotal =  Number(lineitem.Get("Net Total")); // zoho net total
			newLineitem.LineTotal =  newLineItem.PriceUnits * newLineitem.QtyUnits; // zoho total ignoring tax
			
			LineItemsTotal = LineItemsTotal + newLineitem.LineTotal;
			TotalDiscount = TotalDiscount + Number(lineitem.Get("Discount")); // zoho line discount
			If Number(lineitem.Get("Tax")) = 0 AND Number(SOData.Get("Tax")) = 0 Then
				newLineitem.Taxable = False;
			Else
				newLineitem.Taxable = True;
				TotalTax = TotalTax + Number(lineitem.Get("Tax")); // zoho line tax
				taxablesubtotal = taxablesubtotal + newLineitem.LineTotal;
			EndIf;
			
		EndDo;
		UpdatedSO.LineSubtotal = LineItemsTotal;
		UpdatedSO.Shipping = SOData.Get("Adjustment");
		UpdatedSO.Discount = (- Number(TotalDiscount + SOData.Get("Discount"))); // zoho overall discount
		UpdatedSO.DiscountPercent = -(UpdatedSO.Discount/UpdatedSO.LineSubtotal) * 100;
		UpdatedSO.SalesTax = TotalTax + SOData.Get("Tax");
		UpdatedSO.DocumentTotal = SOData.Get("Grand Total");
		UpdatedSO.TaxableSubtotal = taxablesubtotal;
		
		UpdatedSO.SubTotal = LineItemsTotal + UpdatedSO.Discount;
		UpdatedSO.DocumentTotalRC = UpdatedSO.DocumentTotal;
		
		billQuery = New Query("SELECT
		                      |	Addresses.Ref
		                      |FROM
		                      |	Catalog.Addresses AS Addresses
		                      |WHERE
		                      |	Addresses.DefaultBilling = TRUE
		                      |	AND Addresses.Owner.Ref = &Ref");
	       
		billQuery.SetParameter("Ref", UpdatedSO.Company.Ref);
		billResult = billQuery.Execute().Unload();
		UpdatedSO.BillTo = billResult[0].Ref;
		
		UpdatedSO.Write(DocumentWriteMode.Posting);
		
	EndIf;
	
	
	Return "Success";
EndFunction

Function zoho_quote(jsonin)
	ParsedJSON = InternetConnectionClientServer.DecodeJSON(jsonin);
	
	apiQuery = new Query("SELECT
	                     |	zoho_QuoteCodeMap.quote_ref
	                     |FROM
	                     |	Catalog.zoho_QuoteCodeMap AS zoho_QuoteCodeMap
	                     |WHERE
	                     |	zoho_QuoteCodeMap.zoho_id = &zoho_id");
					   
	apiQuery.SetParameter("zoho_id", ParsedJSON.quote_id);
	queryResult = apiQuery.Execute();
	queryResultunload = queryResult.Unload();
	
	If queryResult.IsEmpty() Then
		////need to create quote
		PathDef = "crm.zoho.com/crm/private/json/Quotes/";
				
		AuthHeader = "authtoken=" + Constants.zoho_auth_token.Get() + "&scope=crmapi" + "&id=" + ParsedJSON.quote_id;
			
		URLstring = PathDef + "getRecordById?" + AuthHeader;
		
		HeadersMap = New Map();			
		HTTPRequest = New HTTPRequest("", HeadersMap);	
		SSLConnection = New OpenSSLSecureConnection();
		HTTPConnection = New HTTPConnection(URLstring,,,,,,SSLConnection);
		Result = HTTPConnection.Post(HTTPRequest);
		ResultBody = Result.GetBodyAsString();
		ResultBodyJSON = InternetConnectionClientServer.DecodeJSON(ResultBody);
		
		QuoteData = zoho_Functions.ZohoJSONParser(ResultBodyJSON.response.result.Quotes.row.FL);
		NewQuote = Documents.Quote.CreateDocument();
		
		//get customer
		idQuery = new Query("SELECT
		                    |	zoho_accountCodeMap.company_ref
		                    |FROM
		                    |	Catalog.zoho_accountCodeMap AS zoho_accountCodeMap
		                    |WHERE
		                    |	zoho_accountCodeMap.zoho_id = &zoho_id");
					   
		idQuery.SetParameter("zoho_id", QuoteData.Get("ACCOUNTID")); // zoho account id
		idAccountResult = idQuery.Execute().Unload();
		
		Try NewQuote.Company = idAccountResult[0].company_ref;
		Except
			return "zoho account id does not exist";
		EndTry;
		
		//get contact
		contactid = QuoteData.Get("CONTACTID");
		If contactid <> Undefined Then
			Try 
				idQuery = new Query("SELECT
				                    |	zoho_contactCodeMap.address_ref
				                    |FROM
				                    |	Catalog.zoho_contactCodeMap AS zoho_contactCodeMap
				                    |WHERE
				                    |	zoho_contactCodeMap.zoho_id = &zoho_id");
							   
				idQuery.SetParameter("zoho_id", contactid); // zoho contact id
				idContactResult = idQuery.Execute().Unload();
				
				contactobj = idContactResult[0].address_ref;
				// if contact belongs to company then its a ship to, if it doesnt its a dropship
				If contactobj.Owner.Ref = NewQuote.Company.Ref Then
					NewQuote.ShipTo = contactobj.Ref;
				Else
					NewQuote.DropshipCompany = contactobj.Owner.Ref;
					NewQuote.DropshipShipTo = contactobj.Ref;
					//use dropship, and just load default shipping
					shipQuery = New Query("SELECT
										  |	Addresses.Ref
										  |FROM
										  |	Catalog.Addresses AS Addresses
										  |WHERE
										  |	Addresses.DefaultShipping = TRUE
										  |	AND Addresses.Owner.Ref = &Ref");
					   
					shipQuery.SetParameter("Ref", NewQuote.Company.Ref);
					shipResult = shipQuery.Execute().Unload();
					NewQuote.ShipTo = shipResult[0].Ref;
				EndIf;
			Except
				Return "zoho contact id does not exist";	
			EndTry;
		Else
			//no contact, load default
			shipQuery = New Query("SELECT
									  |	Addresses.Ref
									  |FROM
									  |	Catalog.Addresses AS Addresses
									  |WHERE
									  |	Addresses.DefaultShipping = TRUE
									  |	AND Addresses.Owner.Ref = &Ref");
				   
			shipQuery.SetParameter("Ref", NewQuote.Company.Ref);
			shipResult = shipQuery.Execute().Unload();
			NewQuote.ShipTo = shipResult[0].Ref;
		EndIf;
		
		NewQuote.Number = Right(QuoteData.Get("Quote Number"), 6);
		
		Try NewQuote.Memo = QuoteData.Get("Description"); Except Endtry;
		Try NewQuote.EmailNote = QuoteData.Get("Terms and Conditions"); Except Endtry;
		Try NewQuote.ExpirationDate = Date(QuoteData.Get("Valid Till")); Except Endtry;
		
		NewQuote.Date = CurrentSessionDate();
		NewQuote.Currency = GeneralFunctionsReusable.DefaultCurrency();
		NewQuote.Location = GeneralFunctions.GetDefaultLocation();
		//NewQuote.Location = Catalogs.Locations.MainWarehouse;
		NewQuote.CreatedFromZoho = True;
		
		TotalDiscount = 0;
		TotalTax = 0;
		taxablesubtotal = 0;
		LineItemsTotal = 0;
		For Each lineitem in QuoteData.Get("Product Details") Do
			newLineItem = NewQuote.LineItems.Add();
			
			//get product
			idQuery = new Query("SELECT
			                    |	zoho_productCodeMap.product_ref
			                    |FROM
			                    |	Catalog.zoho_productCodeMap AS zoho_productCodeMap
			                    |WHERE
			                    |	zoho_productCodeMap.zoho_id = &zoho_id");
						   
			idQuery.SetParameter("zoho_id", lineitem.Get("Product Id")); // zoho product id
			idProductResult = idQuery.Execute().Unload();
			
			Try newLineItem.Product = idProductResult[0].product_ref;
			Except
				return "zoho product id doesnt exist";
			EndTry;
			
			newLineItem.ProductDescription = newLineItem.Product.Description;
			newLineItem.Unit = newLineItem.Product.UnitSet.DefaultSaleUnit;
			newLineItem.Location = NewQuote.Location;
			newLineItem.DeliveryDate = NewQuote.DeliveryDate;
			
			newLineItem.PriceUnits = Number(lineitem.Get("List Price")); // zoho list price
			newLineitem.QtyUnits = Number(lineitem.Get("Quantity")); // zoho quantity
			newLineitem.LineTotal =  newLineItem.PriceUnits * newLineitem.QtyUnits; // zoho total ignoring tax

			LineItemsTotal = LineItemsTotal + newLineitem.LineTotal;
			TotalDiscount = TotalDiscount + Number(lineitem.Get("Discount")); // zoho line discount
			If Number(lineitem.Get("Tax")) = 0 AND Number(QuoteData.Get("Tax")) = 0 Then
				newLineitem.Taxable = False;
			Else
				newLineitem.Taxable = True;
				TotalTax = TotalTax + Number(lineitem.Get("Tax")); // zoho line tax
				taxablesubtotal = taxablesubtotal + newLineitem.LineTotal;
			EndIf;
			
		EndDo;
		NewQuote.LineSubtotal = LineItemsTotal;  
		NewQuote.Shipping = QuoteData.Get("Adjustment");
		NewQuote.Discount = (- Number(TotalDiscount + QuoteData.Get("Discount"))); // zoho overall discount
		NewQuote.DiscountPercent = -(NewQuote.Discount/NewQuote.LineSubtotal) * 100;
		NewQuote.SalesTax = TotalTax + QuoteData.Get("Tax");
		NewQuote.DocumentTotal = QuoteData.Get("Grand Total");
		NewQuote.TaxableSubtotal = taxablesubtotal;
		
		NewQuote.SubTotal = LineItemsTotal + NewQuote.Discount;
		NewQuote.DocumentTotalRC = NewQuote.DocumentTotal;
		NewQuote.ExchangeRate = 1;

		
		billQuery = New Query("SELECT
		                      |	Addresses.Ref
		                      |FROM
		                      |	Catalog.Addresses AS Addresses
		                      |WHERE
		                      |	Addresses.DefaultBilling = TRUE
		                      |	AND Addresses.Owner.Ref = &Ref");
	       
		billQuery.SetParameter("Ref", NewQuote.Company.Ref);
		billResult = billQuery.Execute().Unload();
		NewQuote.BillTo = billResult[0].Ref;
		
		NewQuote.Write();
		
		//create a record of the acs_apicode to zoho id mapping
		newRecord = Catalogs.zoho_QuoteCodeMap.CreateItem();
		newRecord.quote_ref = NewQuote.Ref;
		Try 
			newRecord.zoho_id = QuoteData.Get("QUOTEID");
			
		Except
			Return "Fail: No zoho id";
		EndTry;
		newRecord.Write();
		
	Else
		////updating a quote
		PathDef = "crm.zoho.com/crm/private/json/Quotes/";
				
		AuthHeader = "authtoken=" + Constants.zoho_auth_token.Get() + "&scope=crmapi" + "&id=" + ParsedJSON.quote_id;
			
		URLstring = PathDef + "getRecordById?" + AuthHeader;
		
		HeadersMap = New Map();			
		HTTPRequest = New HTTPRequest("", HeadersMap);	
		SSLConnection = New OpenSSLSecureConnection();
		HTTPConnection = New HTTPConnection(URLstring,,,,,,SSLConnection);
		Result = HTTPConnection.Post(HTTPRequest);
		ResultBody = Result.GetBodyAsString();
		ResultBodyJSON = InternetConnectionClientServer.DecodeJSON(ResultBody);
		QuoteData = zoho_Functions.ZohoJSONParser(ResultBodyJSON.response.result.Quotes.row.FL);

		upQuote = queryResultunload[0].quote_ref;
		UpdatedQuote = upQuote.GetObject();
		
		//get customer
		idQuery = new Query("SELECT
							|	zoho_accountCodeMap.company_ref
							|FROM
							|	Catalog.zoho_accountCodeMap AS zoho_accountCodeMap
							|WHERE
							|	zoho_accountCodeMap.zoho_id = &zoho_id");
					   
		idQuery.SetParameter("zoho_id", QuoteData.Get("ACCOUNTID")); // zoho account id
		idAccountResult = idQuery.Execute().Unload();
		
		Try UpdatedQuote.Company = idAccountResult[0].company_ref;
		Except
			return "zoho account id does not exist";
		EndTry;
		
		//get contact
		contactid = QuoteData.Get("CONTACTID");
		If contactid <> Undefined Then
			Try 
				idQuery = new Query("SELECT
				                    |	zoho_contactCodeMap.address_ref
				                    |FROM
				                    |	Catalog.zoho_contactCodeMap AS zoho_contactCodeMap
				                    |WHERE
				                    |	zoho_contactCodeMap.zoho_id = &zoho_id");
							   
				idQuery.SetParameter("zoho_id", contactid); // zoho contact id
				idContactResult = idQuery.Execute().Unload();
				
				contactobj = idContactResult[0].address_ref;
				// if contact belongs to company then its a ship to, if it doesnt its a dropship
				If contactobj.Owner.Ref = UpdatedQuote.Company.Ref Then
					UpdatedQuote.ShipTo = contactobj.Ref;
				Else
					UpdatedQuote.DropshipCompany = contactobj.Owner.Ref;
					UpdatedQuote.DropshipShipTo = contactobj.Ref;
					//use dropship, and just load default shipping
					shipQuery = New Query("SELECT
										  |	Addresses.Ref
										  |FROM
										  |	Catalog.Addresses AS Addresses
										  |WHERE
										  |	Addresses.DefaultShipping = TRUE
										  |	AND Addresses.Owner.Ref = &Ref");
					   
					shipQuery.SetParameter("Ref", UpdatedQuote.Company.Ref);
					shipResult = shipQuery.Execute().Unload();
					UpdatedQuote.ShipTo = shipResult[0].Ref;
				EndIf;
			Except
				Return "zoho contact id does not exist";	
			EndTry;
		Else
			//no contact, load default
			shipQuery = New Query("SELECT
									  |	Addresses.Ref
									  |FROM
									  |	Catalog.Addresses AS Addresses
									  |WHERE
									  |	Addresses.DefaultShipping = TRUE
									  |	AND Addresses.Owner.Ref = &Ref");
				   
			shipQuery.SetParameter("Ref", NewQuote.Company.Ref);
			shipResult = shipQuery.Execute().Unload();
			UpdatedQuote.ShipTo = shipResult[0].Ref;
		EndIf; 
		
		UpdatedQuote.Number = Right(QuoteData.Get("Quote Number"), 6);
		
		Try UpdatedQuote.Memo = QuoteData.Get("Description"); Except Endtry;
		Try UpdatedQuote.EmailNote = QuoteData.Get("Terms and Conditions"); Except Endtry;
		Try UpdatedQuote.ExpirationDate = Date(QuoteData.Get("Valid Till")); Except Endtry;
		
		//get rid of line items before rewriting them
		UpdatedQuote.LineItems.Clear();
		
		TotalDiscount = 0;
		TotalTax = 0;
		taxablesubtotal = 0;
		LineItemsTotal = 0;
		For Each lineitem in QuoteData.Get("Product Details") Do
			newLineItem = UpdatedQuote.LineItems.Add();
			
			//get product
			idQuery = new Query("SELECT
			                    |	zoho_productCodeMap.product_ref
			                    |FROM
			                    |	Catalog.zoho_productCodeMap AS zoho_productCodeMap
			                    |WHERE
			                    |	zoho_productCodeMap.zoho_id = &zoho_id");
						   
			idQuery.SetParameter("zoho_id", lineitem.Get("Product Id")); // zoho product id
			idProductResult = idQuery.Execute().Unload();
			
			Try newLineItem.Product = idProductResult[0].product_ref;
			Except
				return "product id does not exist";
			EndTry;
			
			newLineItem.ProductDescription = newLineItem.Product.Description;
			newLineItem.Unit = newLineItem.Product.UnitSet.DefaultSaleUnit;
			newLineItem.Location = UpdatedQuote.Location;
			newLineItem.DeliveryDate = UpdatedQuote.DeliveryDate;

			newLineItem.PriceUnits = Number(lineitem.Get("List Price")); // zoho list price
			newLineitem.QtyUnits = Number(lineitem.Get("Quantity")); // zoho quantity
			newLineitem.LineTotal =  newLineItem.PriceUnits * newLineitem.QtyUnits; // zoho total ignoring tax
			
						
			LineItemsTotal = LineItemsTotal + newLineitem.LineTotal;
			TotalDiscount = TotalDiscount + Number(lineitem.Get("Discount")); // zoho line discount
			If Number(lineitem.Get("Tax")) = 0 AND Number(QuoteData.Get("Tax")) = 0 Then
				newLineitem.Taxable = False;
			Else
				newLineitem.Taxable = True;
				TotalTax = TotalTax + Number(lineitem.Get("Tax")); // zoho line tax
				taxablesubtotal = taxablesubtotal + newLineitem.LineTotal;
			EndIf;
			
		EndDo;
		UpdatedQuote.LineSubtotal = LineItemsTotal;
		UpdatedQuote.Shipping = QuoteData.Get("Adjustment");
		UpdatedQuote.Discount = (- Number(TotalDiscount + QuoteData.Get("Discount"))); // zoho overall discount
		UpdatedQuote.DiscountPercent = -(UpdatedQuote.Discount/UpdatedQuote.LineSubtotal) * 100;
		UpdatedQuote.SalesTax = TotalTax + QuoteData.Get("Tax");
		UpdatedQuote.DocumentTotal = QuoteData.Get("Grand Total");
		UpdatedQuote.TaxableSubtotal = taxablesubtotal;
		
		UpdatedQuote.SubTotal = LineItemsTotal + UpdatedQuote.Discount;
		UpdatedQuote.DocumentTotalRC = UpdatedQuote.DocumentTotal;
		
		billQuery = New Query("SELECT
							  |	Addresses.Ref
							  |FROM
							  |	Catalog.Addresses AS Addresses
							  |WHERE
							  |	Addresses.DefaultBilling = TRUE
							  |	AND Addresses.Owner.Ref = &Ref");
		   
		billQuery.SetParameter("Ref", UpdatedQuote.Company.Ref);
		billResult = billQuery.Execute().Unload();
		UpdatedQuote.BillTo = billResult[0].Ref;
		
		UpdatedQuote.Write();
		
	EndIf;
		
	Return "Success";
EndFunction

Function zoho_salesinvoice(jsonin)
	ParsedJSON = InternetConnectionClientServer.DecodeJSON(jsonin);
	
	apiQuery = new Query("SELECT
	                     |	zoho_SICodeMap.invoice_ref
	                     |FROM
	                     |	Catalog.zoho_SICodeMap AS zoho_SICodeMap
	                     |WHERE
	                     |	zoho_SICodeMap.zoho_id = &zoho_id");
					   
	apiQuery.SetParameter("zoho_id", ParsedJSON.salesinvoice_id);
	queryResult = apiQuery.Execute();
	queryResultunload = queryResult.Unload();
	
	If queryResult.IsEmpty() Then
		////need to create SI
		PathDef = "crm.zoho.com/crm/private/json/Invoices/";
				
		AuthHeader = "authtoken=" + Constants.zoho_auth_token.Get() + "&scope=crmapi" + "&id=" + ParsedJSON.salesinvoice_id;
			
		URLstring = PathDef + "getRecordById?" + AuthHeader;
		
		HeadersMap = New Map();			
		HTTPRequest = New HTTPRequest("", HeadersMap);	
		SSLConnection = New OpenSSLSecureConnection();
		HTTPConnection = New HTTPConnection(URLstring,,,,,,SSLConnection);
		Result = HTTPConnection.Post(HTTPRequest);
		ResultBody = Result.GetBodyAsString();
		ResultBodyJSON = InternetConnectionClientServer.DecodeJSON(ResultBody);
		
		SIData = zoho_Functions.ZohoJSONParser(ResultBodyJSON.response.result.Invoices.row.FL);
		NewSI = documents.SalesInvoice.CreateDocument();
		
		//get customer
		idQuery = new Query("SELECT
		                    |	zoho_accountCodeMap.company_ref
		                    |FROM
		                    |	Catalog.zoho_accountCodeMap AS zoho_accountCodeMap
		                    |WHERE
		                    |	zoho_accountCodeMap.zoho_id = &zoho_id");
					   
		idQuery.SetParameter("zoho_id", SIData.Get("ACCOUNTID")); // zoho account id
		idAccountResult = idQuery.Execute().Unload();
		
		Try NewSI.Company = idAccountResult[0].company_ref;
		Except
			return "zoho account id does not exist";
		EndTry;
		
		//get contact
		contactid = SIData.Get("CONTACTID");
		If contactid <> Undefined Then
			Try 
				idQuery = new Query("SELECT
				                    |	zoho_contactCodeMap.address_ref
				                    |FROM
				                    |	Catalog.zoho_contactCodeMap AS zoho_contactCodeMap
				                    |WHERE
				                    |	zoho_contactCodeMap.zoho_id = &zoho_id");
							   
				idQuery.SetParameter("zoho_id", contactid); // zoho contact id
				idContactResult = idQuery.Execute().Unload();
				
				contactobj = idContactResult[0].address_ref;
				// if contact belongs to company then its a ship to, if it doesnt its a dropship
				If contactobj.Owner.Ref = NewSI.Company.Ref Then
					NewSI.ShipTo = contactobj.Ref;
				Else
					NewSI.DropshipCompany = contactobj.Owner.Ref;
					NewSI.DropshipShipTo = contactobj.Ref;
					//use dropship, and just load default shipping
					shipQuery = New Query("SELECT
										  |	Addresses.Ref
										  |FROM
										  |	Catalog.Addresses AS Addresses
										  |WHERE
										  |	Addresses.DefaultShipping = TRUE
										  |	AND Addresses.Owner.Ref = &Ref");
					   
					shipQuery.SetParameter("Ref", NewSI.Company.Ref);
					shipResult = shipQuery.Execute().Unload();
					NewSI.ShipTo = shipResult[0].Ref;
				EndIf;
			Except
				Return "zoho contact id does not exist";	
			EndTry;
		Else
			//no contact, load default
			shipQuery = New Query("SELECT
									  |	Addresses.Ref
									  |FROM
									  |	Catalog.Addresses AS Addresses
									  |WHERE
									  |	Addresses.DefaultShipping = TRUE
									  |	AND Addresses.Owner.Ref = &Ref");
				   
			shipQuery.SetParameter("Ref", NewSI.Company.Ref);
			shipResult = shipQuery.Execute().Unload();
			NewSI.ShipTo = shipResult[0].Ref;
		EndIf;
				
		NewSI.Number = Right(SIData.Get("Invoice Number"), 6);	
		
		Try NewSI.Memo = SIData.Get("Description"); Except Endtry;
		Try NewSI.EmailNote = SIData.Get("Terms and Conditions"); Except Endtry;
		Try NewSI.RefNum = SIData.Get("Purchase Order"); Except Endtry;
		Try NewSI.Date = Date(SIData.Get("Invoice Date")); Except Endtry;
		
		NewSI.Date = CurrentSessionDate();
		NewSI.Currency = GeneralFunctionsReusable.DefaultCurrency();
		NewSI.LocationActual = GeneralFunctions.GetDefaultLocation();//Catalogs.Locations.MainWarehouse; 
		NewSI.CreatedFromZoho = True;
		
		Try 
			NewSI.DeliveryDate = Date(SIData.Get("Due Date")); 
		Except 
			// default terms and due date
			NewSI.Terms = NewSI.Company.Terms;
			BlankDate = '00010101';
			NewSI.DueDate = ?(Not NewSI.Terms.IsEmpty(), NewSI.Date + NewSI.Terms.Days * 60*60*24, BlankDate);
		Endtry;
		
		Try //check if created from a SO in acs
			soQuery = new Query("SELECT
			                    |	zoho_SOCodeMap.salesorder_ref
			                    |FROM
			                    |	Catalog.zoho_SOCodeMap AS zoho_SOCodeMap
			                    |WHERE
			                    |	zoho_SOCodeMap.zoho_id = &zoho_id");
						   
			soQuery.SetParameter("zoho_id", SIData.Get("SALESORDERID"));
			socheck = soQuery.Execute().Unload();
			SOlinkage = socheck[0].salesorder_ref;
		Except
			// no SO
			SOlinkage = undefined;
		EndTry;
		
		TotalDiscount = 0;
		TotalTax = 0;
		taxablesubtotal = 0;
		LineItemsTotal = 0;
		For Each lineitem in SIData.Get("Product Details") Do
			newLineItem = NewSI.LineItems.Add();
			
			//get product
			idQuery = new Query("SELECT
			                    |	zoho_productCodeMap.product_ref
			                    |FROM
			                    |	Catalog.zoho_productCodeMap AS zoho_productCodeMap
			                    |WHERE
			                    |	zoho_productCodeMap.zoho_id = &zoho_id");
						   
			idQuery.SetParameter("zoho_id", lineitem.Get("Product Id")); // zoho product id
			idProductResult = idQuery.Execute().Unload();
			
			Try newLineItem.Product = idProductResult[0].product_ref;
			Except
				return "zoho product id doesnt exist";
			EndTry;
			
			newLineItem.Order = SOlinkage;
			
			newLineItem.ProductDescription = newLineItem.Product.Description;
			newLineItem.Unit = newLineItem.Product.UnitSet.DefaultSaleUnit;
			newLineItem.LocationActual = NewSI.LocationActual;
			newLineItem.DeliveryDateActual = NewSI.DeliveryDateActual;
			
			newLineItem.PriceUnits = Number(lineitem.Get("List Price")); // zoho list price
			newLineitem.QtyUnits = Number(lineitem.Get("Quantity")); // zoho quantity
			newLineitem.LineTotal =  newLineItem.PriceUnits * newLineitem.QtyUnits; // zoho total ignoring tax

			LineItemsTotal = LineItemsTotal + newLineitem.LineTotal;
			TotalDiscount = TotalDiscount + Number(lineitem.Get("Discount")); // zoho line discount
			If Number(lineitem.Get("Tax")) = 0 AND Number(SIData.Get("Tax")) = 0 Then
				newLineitem.Taxable = False;
			Else
				newLineitem.Taxable = True;
				TotalTax = TotalTax + Number(lineitem.Get("Tax")); // zoho line tax
				taxablesubtotal = taxablesubtotal + newLineitem.LineTotal;
			EndIf;
			
		EndDo;
		NewSI.LineSubtotal = LineItemsTotal;  
		NewSI.Shipping = SIData.Get("Adjustment");
		NewSI.Discount = (- Number(TotalDiscount + SIData.Get("Discount"))); // zoho overall discount
		NewSI.DiscountPercent = -(NewSI.Discount/NewSI.LineSubtotal) * 100;
		NewSI.SalesTax = TotalTax + SIData.Get("Tax");
		NewSI.DocumentTotal = SIData.Get("Grand Total");
		NewSI.TaxableSubtotal = taxablesubtotal;
		
		NewSI.SubTotal = LineItemsTotal + NewSI.Discount;
		NewSI.DocumentTotalRC = NewSI.DocumentTotal;
		NewSI.ExchangeRate = 1;
		
		billQuery = New Query("SELECT
		                      |	Addresses.Ref
		                      |FROM
		                      |	Catalog.Addresses AS Addresses
		                      |WHERE
		                      |	Addresses.DefaultBilling = TRUE
		                      |	AND Addresses.Owner.Ref = &Ref");
	       
		billQuery.SetParameter("Ref", NewSI.Company.Ref);
		billResult = billQuery.Execute().Unload();
		NewSI.BillTo = billResult[0].Ref;
		
		If NewSI.Company.ARAccount <> ChartsofAccounts.ChartOfAccounts.EmptyRef() Then
			NewSI.ARAccount = NewSI.Company.ARAccount;
		Else
			
			DefaultCurrency = GeneralFunctionsReusable.DefaultCurrency();
			NewSI.ARAccount = DefaultCurrency.DefaultARAccount;
		EndIf;
		
		NewSI.Write(DocumentWriteMode.Posting);
		
		//create a record of the acs_apicode to zoho id mapping
		newRecord = Catalogs.zoho_SICodeMap.CreateItem(); 
		newRecord.invoice_ref = NewSI.Ref;
		Try 
			newRecord.zoho_id = SIData.Get("INVOICEID");
			
		Except
			Return "Fail: No zoho id";
		EndTry;
		newRecord.Write();
		
	Else
		////updating a SI
		PathDef = "crm.zoho.com/crm/private/json/Invoices/";
				
		AuthHeader = "authtoken=" + Constants.zoho_auth_token.Get() + "&scope=crmapi" + "&id=" + ParsedJSON.salesinvoice_id;
			
		URLstring = PathDef + "getRecordById?" + AuthHeader;
		
		HeadersMap = New Map();			
		HTTPRequest = New HTTPRequest("", HeadersMap);	
		SSLConnection = New OpenSSLSecureConnection();
		HTTPConnection = New HTTPConnection(URLstring,,,,,,SSLConnection);
		Result = HTTPConnection.Post(HTTPRequest);
		ResultBody = Result.GetBodyAsString();
		ResultBodyJSON = InternetConnectionClientServer.DecodeJSON(ResultBody);
		SIData = zoho_Functions.ZohoJSONParser(ResultBodyJSON.response.result.Invoices.row.FL);

		upSI = queryResultunload[0].invoice_ref;
		UpdatedSI = upSI.GetObject();
				
		//get customer
		idQuery = new Query("SELECT
		                    |	zoho_accountCodeMap.company_ref
							|FROM
		                    |	Catalog.zoho_accountCodeMap AS zoho_accountCodeMap
		                    |WHERE
		                    |	zoho_accountCodeMap.zoho_id = &zoho_id");
					   
		idQuery.SetParameter("zoho_id", SIData.Get("ACCOUNTID")); // zoho account id
		idAccountResult = idQuery.Execute().Unload();
		
		Try UpdatedSI.Company = idAccountResult[0].company_ref;
		Except
			return "zoho account id does not exist";
		EndTry;
		
		//get contact
		contactid = SIData.Get("CONTACTID");
		If contactid <> Undefined Then
			Try 
				idQuery = new Query("SELECT
				                    |	zoho_contactCodeMap.address_ref
				                    |FROM
				                    |	Catalog.zoho_contactCodeMap AS zoho_contactCodeMap
				                    |WHERE
				                    |	zoho_contactCodeMap.zoho_id = &zoho_id");
							   
				idQuery.SetParameter("zoho_id", contactid); // zoho contact id
				idContactResult = idQuery.Execute().Unload();
				
				contactobj = idContactResult[0].address_ref;
				// if contact belongs to company then its a ship to, if it doesnt its a dropship
				If contactobj.Owner.Ref = UpdatedSI.Company.Ref Then
					UpdatedSI.ShipTo = contactobj.Ref;
				Else
					UpdatedSI.DropshipCompany = contactobj.Owner.Ref;
					UpdatedSI.DropshipShipTo = contactobj.Ref;
					//use dropship, and just load default shipping
					shipQuery = New Query("SELECT
										  |	Addresses.Ref
										  |FROM
										  |	Catalog.Addresses AS Addresses
										  |WHERE
										  |	Addresses.DefaultShipping = TRUE
										  |	AND Addresses.Owner.Ref = &Ref");
					   
					shipQuery.SetParameter("Ref", UpdatedSI.Company.Ref);
					shipResult = shipQuery.Execute().Unload();
					UpdatedSI.ShipTo = shipResult[0].Ref;
				EndIf;
			Except
				Return "zoho contact id does not exist";	
			EndTry;
		Else
			//no contact, load default
			shipQuery = New Query("SELECT
									  |	Addresses.Ref
									  |FROM
									  |	Catalog.Addresses AS Addresses
									  |WHERE
									  |	Addresses.DefaultShipping = TRUE
									  |	AND Addresses.Owner.Ref = &Ref");
				   
			shipQuery.SetParameter("Ref", UpdatedSI.Company.Ref);
			shipResult = shipQuery.Execute().Unload();
			UpdatedSI.ShipTo = shipResult[0].Ref;
		EndIf;
		
		UpdatedSI.Number = Right(SIData.Get("Invoice Number"),6); 
		
		Try UpdatedSI.Memo = SIData.Get("Description"); Except Endtry;
		Try UpdatedSI.EmailNote = SIData.Get("Terms and Conditions"); Except Endtry;
		Try UpdatedSI.RefNum = SIData.Get("Purchase Order"); Except Endtry;
		Try UpdatedSI.DeliveryDate = Date(SIData.Get("Due Date")); Except Endtry;
		Try UpdatedSI.Date = Date(SIData.Get("Invoice Date")); Except Endtry;
		
		//get rid of line items before rewriting them
		UpdatedSI.LineItems.Clear();
		
		TotalDiscount = 0;
		TotalTax = 0;
		taxablesubtotal = 0;
		LineItemsTotal = 0;
		For Each lineitem in SIData.Get("Product Details") Do
			newLineItem = UpdatedSI.LineItems.Add();
			
			//get product
			idQuery = new Query("SELECT
			                    |	zoho_productCodeMap.product_ref
			                    |FROM
			                    |	Catalog.zoho_productCodeMap AS zoho_productCodeMap
			                    |WHERE
			                    |	zoho_productCodeMap.zoho_id = &zoho_id");
						   
			idQuery.SetParameter("zoho_id", lineitem.Get("Product Id")); // zoho product id
			idProductResult = idQuery.Execute().Unload();
			
			Try newLineItem.Product = idProductResult[0].product_ref;
			Except
				return "product id does not exist";
			EndTry;
			
			newLineItem.ProductDescription = newLineItem.Product.Description;
			newLineItem.Unit = newLineItem.Product.UnitSet.DefaultSaleUnit;
			newLineItem.LocationActual = UpdatedSI.LocationActual;
			newLineItem.DeliveryDateActual = UpdatedSI.DeliveryDateActual;
			
			newLineItem.PriceUnits = Number(lineitem.Get("List Price")); // zoho list price
			newLineitem.QtyUnits = Number(lineitem.Get("Quantity")); // zoho quantity
			//newLineitem.LineTotal =  Number(lineitem.Get("Net Total")); // zoho net total
			newLineitem.LineTotal =  newLineItem.PriceUnits * newLineitem.QtyUnits; // zoho total ignoring tax
			
			LineItemsTotal = LineItemsTotal + newLineitem.LineTotal;
			TotalDiscount = TotalDiscount + Number(lineitem.Get("Discount")); // zoho line discount
			If Number(lineitem.Get("Tax")) = 0 AND Number(SIData.Get("Tax")) = 0 Then
				newLineitem.Taxable = False;
			Else
				newLineitem.Taxable = True;
				TotalTax = TotalTax + Number(lineitem.Get("Tax")); // zoho line tax
				taxablesubtotal = taxablesubtotal + newLineitem.LineTotal;
			EndIf;
			
		EndDo;
		UpdatedSI.LineSubtotal = LineItemsTotal;
		UpdatedSI.Shipping = SIData.Get("Adjustment");
		UpdatedSI.Discount = (- Number(TotalDiscount + SIData.Get("Discount"))); // zoho overall discount
		UpdatedSI.DiscountPercent = -(UpdatedSI.Discount/UpdatedSI.LineSubtotal) * 100;
		UpdatedSI.SalesTax = TotalTax + SIData.Get("Tax");
		UpdatedSI.DocumentTotal = SIData.Get("Grand Total");
		UpdatedSI.TaxableSubtotal = taxablesubtotal;
		
		UpdatedSI.SubTotal = LineItemsTotal + UpdatedSI.Discount;
		UpdatedSI.DocumentTotalRC = UpdatedSI.DocumentTotal;
			
		billQuery = New Query("SELECT
		                      |	Addresses.Ref
		                      |FROM
		                      |	Catalog.Addresses AS Addresses
		                      |WHERE
		                      |	Addresses.DefaultBilling = TRUE
		                      |	AND Addresses.Owner.Ref = &Ref");
	       
		billQuery.SetParameter("Ref", UpdatedSI.Company.Ref);
		billResult = billQuery.Execute().Unload();
		UpdatedSI.BillTo = billResult[0].Ref;
		
		UpdatedSI.Write(DocumentWriteMode.Posting);
		
	EndIf;
	
	
	Return "Success";

EndFunction
