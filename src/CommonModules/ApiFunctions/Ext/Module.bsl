
Function CompanyPostinout(jsonin)
		
	ParsedJSON = InternetConnectionClientServer.DecodeJSON(jsonin);
		
	NewCompany = Catalogs.Companies.CreateItem();
	
	NewCompany.Description = ParsedJSON.company_name;
	NewCompany.Customer = True;
	NewCompany.DefaultCurrency = Constants.DefaultCurrency.Get();
	NewCompany.Terms = Catalogs.PaymentTerms.Net30;
	
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


	NewCompany.Write();
	
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

	Except
		
			AddressLine = Catalogs.Addresses.CreateItem();
			AddressLine.Owner = NewCompany.Ref;
			AddressLine.DefaultBilling = True;
			AddressLine.DefaultShipping = True;
			AddressLine.Description = "Primary";
			AddressLine.Write();

		
	EndTry;
		
	
	///
	
	//Query = New Query("SELECT
	//				  | Addresses.Ref,
	//				  |	Addresses.Description,
	//				  |	Addresses.FirstName,
	//				  |	Addresses.LastName,
	//				  |	Addresses.DefaultBilling,
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
	//Query.SetParameter("Company", NewCompany.Ref);
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
	//	Address.Insert("state", Result.State.Code);
	//	Address.Insert("zip", Result.ZIP);
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
	//CompanyData.Insert("api_code", String(NewCompany.Ref.UUID()));
	//CompanyData.Insert("company_name", NewCompany.Description);
	//CompanyData.Insert("company_code", NewCompany.Code);
	//CompanyData.Insert("company_type", "customer");
	//CompanyData.Insert("lines", DataAddresses);
	//
	//jsonout = InternetConnectionClientServer.EncodeJSON(CompanyData);
	//
	//Return jsonout;
	
	Return InternetConnectionClientServer.EncodeJSON(GeneralFunctions.ReturnCompanyObjectMap(NewCompany));
	
EndFunction

Function CompaniesGetinout(jsonin)
		
	Query = New Query("SELECT
	                  | Companies.Ref,
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
		Company.Insert("api_code", String(Result.Ref.UUID()));
		Company.Insert("company_code", Result.Code);
		Company.Insert("company_name", Result.Description);
		Company.Insert("company_type", "customer");
		
		Companies.Add(Company);
		
	EndDo;
	
	CompanyList = New Map();
	CompanyList.Insert("companies", Companies);
	
	jsonout = InternetConnectionClientServer.EncodeJSON(CompanyList);
	
	Return jsonout;

EndFunction

Function CompanyPutCodeinout(jsonin, object_code)
	
	CompanyCodeJSON = InternetConnectionClientServer.DecodeJSON(object_code);
	api_code = CompanyCodeJSON.object_code;
	
	ParsedJSON = InternetConnectionClientServer.DecodeJSON(jsonin);
	
	//UpdatedCompany = Catalogs.Companies.FindByCode(CompanyCode);
	UpdatedCompany = Catalogs.Companies.GetRef(New UUID(api_code));
	UpdatedCompanyObj = UpdatedCompany.GetObject();
	Try UpdatedCompanyObj.Description = ParsedJSON.company_name; Except EndTry;

	Try
		If ParsedJSON.company_type = "customer" Then
			UpdatedCompany.Customer = True;
		EndIf;
		If ParsedJSON.company_type = "vendor" Then
			UpdatedCompany.Vendor = True;
		EndIf;
		If ParsedJSON.company_type = "customer+vendor" Then
			UpdatedCompany.Customer = True;
			UpdatedCompany.Vendor = True;
		EndIf;
	Except
	EndTry;
	
	Try UpdatedCompanyObj.Website = ParsedJSON.website; Except EndTry;
	Try 
		PriceLevel = catalogs.PriceLevels.FindByDescription(ParsedJSON.price_level);
		UpdatedCompanyObj.PriceLevel = PriceLevel; 
	Except 
	EndTry;
	
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



	UpdatedCompanyObj.Write();

	Try
		If ParsedJSON.lines.addresses.count() > 0 Then

			For Each Address In ParsedJSON.lines.addresses Do
				
				CurAddress = Catalogs.Addresses.FindByCode(Address.api_code);

				If CurAddress <> Catalogs.Addresses.EmptyRef() Then

					AddrObj = CurAddress.GetObject();

					Try AddrObj.Description = Address.address_id; Except EndTry;
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

					AddrObj.Write();


				EndIf;

		EndDo;

	EndIf;
	
	Except
	EndTry;

	
	//Output = New Map();
	//Output.Insert("status", "success");
	
	
	
	
	//jsonout = InternetConnectionClientServer.EncodeJSON(Output);
	jsonout = InternetConnectionClientServer.EncodeJSON(GeneralFunctions.ReturnCompanyObjectMap(UpdatedCompanyObj));

	
	Return jsonout;

EndFunction

Function CompanyDeleteCodeinout(jsonin)
	
	ParsedJSON = InternetConnectionClientServer.DecodeJSON(jsonin);

	api_code = ParsedJSON.object_code;
	
	//Company = Catalogs.Companies.FindByCode(CompanyCode);
	Company = Catalogs.Companies.GetRef(New UUID(api_code));
	
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
	
	jsonout = InternetConnectionClientServer.EncodeJSON(Output);
	
	Return jsonout;

EndFunction

Function CompanyGetCodeinout(jsonin)
	
	ParsedJSON = InternetConnectionClientServer.DecodeJSON(jsonin);
	
	//Company = Catalogs.Companies.FindByCode(ParsedJSON.object_code);
	Company = Catalogs.Companies.GetRef(New UUID(ParsedJSON.object_code));
	
	Query = New Query("SELECT
					  | Addresses.Ref,
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
		Address.Insert("api_code", String(Result.Ref.UUID()));
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
	CompanyData.Insert("api_code", String(Company.Ref.UUID()));
	CompanyData.Insert("company_name", Company.Description);
	CompanyData.Insert("company_code", Company.Code);
	CompanyData.Insert("company_type", "customer");
	CompanyData.Insert("lines", DataAddresses);
	
	jsonout = InternetConnectionClientServer.EncodeJSON(CompanyData);
	
	Return jsonout;

EndFunction

Function ItemPostinout(jsonin)
		
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
		NewProduct.PurchaseVATCode = Constants.DefaultPurchaseVAT.Get();
		NewProduct.SalesVATCode = Constants.DefaultSalesVAT.Get();
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


		
		jsonout = InternetConnectionClientServer.EncodeJSON(ProductData);
		
	EndIf;
	
	Return jsonout;
	
EndFunction

Function ItemsGetinout(jsonin)
		
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
		
		Product = New Map();
		Product.Insert("item_code", Result.Code);
		Product.Insert("api_code", String(Result.Ref.UUID()));
		Product.Insert("item_description", Result.Description);
		If Result.Type = Enums.InventoryTypes.Inventory Then
			Product.Insert("item_type", "product");
		ElsIf Result.Type = Enums.InventoryTypes.NonInventory Then
			Product.Insert("item_type", "service");
		EndIf;
		
		Products.Add(Product);
		//Products.Add(GeneralFunctions.ReturnProductObjectMap(Result.Ref));
		
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

Function ItemPutCodeinout(jsonin, object_code)
	
	ProductCodeJSON = InternetConnectionClientServer.DecodeJSON(object_code);
	api_code = ProductCodeJSON.object_code;
	//ProductCode = Number(ProductCode);
	
	ParsedJSON = InternetConnectionClientServer.DecodeJSON(jsonin);
	
	UpdatedProduct = Catalogs.Products.getref(New UUID(api_code));
	UpdatedProductObj = UpdatedProduct.GetObject();
	Try UpdatedProductObj.Code = ParsedJSON.item_code; Except EndTry;
	Try UpdatedProductObj.Description = ParsedJSON.item_description; Except EndTry;

	//item_type shouldnt be updatable

	Try
		ItemCat = Catalogs.ProductCategories.FindByDescription(ParsedJSON.item_category);
		UpdatedProductObj.Category = ItemCat;
	Except
	EndTry;

	Try
		ItemUM = Catalogs.UM.FindByDescription(ParsedJSON.unit_of_measure);
		UpdatedProductObj.UM = ItemUM;
	Except
	EndTry;

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
	
	jsonout = InternetConnectionClientServer.EncodeJSON(GeneralFunctions.ReturnProductObjectMap(UpdatedProductObj));
	
	Return jsonout;

EndFunction

Function ItemDeleteCodeinout(jsonin)
	
	ParsedJSON = InternetConnectionClientServer.DecodeJSON(jsonin);
	api_code = ParsedJSON.object_code;
	//ProductCode = Number(ProductCode);
	
	Product = Catalogs.Products.GetRef(New UUID(api_code));
	
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
	
	jsonout = InternetConnectionClientServer.EncodeJSON(Output);
	
	Return jsonout;

EndFunction

Function ItemGetCodeinout(jsonin)
	
	ParsedJSON = InternetConnectionClientServer.DecodeJSON(jsonin);
	
	api_code = ParsedJSON.object_code;
	//Object_code = Number(Object_code);
	//Product = Catalogs.Products.FindByAttribute("api_code", Object_code);
	Product = Catalogs.Products.GetRef(New UUID(api_code));
	
	ProductData = New Map();
	ProductData.Insert("api_code", String(Product.Ref.UUID()));
	ProductData.Insert("item_code", Product.Code);
	ProductData.Insert("item_description", Product.Description);
	If Product.Type = Enums.InventoryTypes.Inventory Then
		ProductData.Insert("item_type", "product");
	ElsIf Product.Type = Enums.InventoryTypes.NonInventory Then
		ProductData.Insert("item_type", "service");	
	EndIf;
	
	//jsonout = InternetConnectionClientServer.EncodeJSON(ProductData);
	jsonout = InternetConnectionClientServer.EncodeJSON(GeneralFunctions.ReturnProductObjectMap(Product));
	
	Return jsonout;

EndFunction

Function CashSalePostinout(jsonin)
		
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
		NewCashSale.SalesTax = ParsedJSON.sales_tax_total;		
	Except
		NewCashSale.SalesTax = 0;
	EndTry;
	NewCashSale.DocumentTotal = ParsedJSON.doc_total;
	NewCashSale.DocumentTotalRC = ParsedJSON.doc_total;
    NewCashSale.DepositType = "2";
	NewCashSale.Currency = Constants.DefaultCurrency.Get();
	NewCashSale.BankAccount = Constants.BankAccount.Get();
	NewCashSale.ExchangeRate = 1;
	NewCashSale.Location = Catalogs.Locations.MainWarehouse;
	
	DataLineItems = ParsedJSON.lines.line_items;
	
	LineItemsRows = DataLineItems.Count();
	For i = 0 To LineItemsRows -1 Do
		
		NewLine = NewCashSale.LineItems.Add();
		
		//ProductCode = Number(DataLineItems[i].api_code);
		Product = Catalogs.Products.GetRef(New UUID(DataLineItems[i].api_code));
		NewLine.Product = Product;
		NewLine.ProductDescription = Product.Description;
		NewLine.VATCode = CommonUse.GetAttributeValue(Product, "SalesVATCode");
		NewLine.VAT = 0;
		
		NewLine.Price = DataLineItems[i].price;
		NewLine.Quantity = DataLineItems[i].quantity;
		// get taxable from JSON
		Try
			TaxableType = DataLineItems[i].taxable_type;
			If TaxableType = "taxable" Then
				NewLine.SalesTaxType = Enums.SalesTaxTypes.Taxable;
			ElsIf TaxableType = "non-taxable" Then
				NewLine.SalesTaxType = Enums.SalesTaxTypes.NonTaxable;
			Else
				NewLine.SalesTaxType = Enums.SalesTaxTypes.NonTaxable;
			EndIf;
		Except
			NewLine.SalesTaxType = Enums.SalesTaxTypes.NonTaxable;	
		EndTry;
		
		NewLine.LineTotal = DataLineItems[i].line_total;
		Try
			TaxableAmount = DataLineItems[i].taxable_amount;
			NewLine.TaxableAmount = TaxableAmount				
		Except
			NewLine.TaxableAmount = 0;
		EndTry;
				
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
	CashSaleData.Insert("sales_tax_total", NewCashSale.SalesTax);
	CashSaleData.Insert("doc_total", NewCashSale.DocumentTotalRC);

	Query = New Query("SELECT
	                  |	CashSaleLineItems.Product,
	                  |	CashSaleLineItems.Price,
	                  |	CashSaleLineItems.Quantity,
	                  |	CashSaleLineItems.LineTotal,
	                  |	CashSaleLineItems.SalesTaxType,
	                  |	CashSaleLineItems.TaxableAmount
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
		LineItem.Insert("taxable_amount", Result.TaxableAmount);
		LineItem.Insert("line_total", Result.LineTotal);
		If Result.SalesTaxType = Enums.SalesTaxTypes.Taxable Then
			LineItem.Insert("taxable_type", "taxable");
		ElsIf Result.SalesTaxType = Enums.SalesTaxTypes.NonTaxable Then
			LineItem.Insert("taxable_type", "non-taxable");
		EndIf;
		LineItems.Add(LineItem);
		
	EndDo;
	
	LineItemsData = New Map();
	LineItemsData.Insert("line_items", LineItems);
	
	CashSaleData.Insert("lines", LineItemsData);
	
	jsonout = InternetConnectionClientServer.EncodeJSON(CashSaleData);
	
	Return jsonout;
	
EndFunction

Function CashSalesGetinout(jsonin)
		
	Query = New Query("SELECT
					  | CashSale.Ref,
	                  |	CashSale.Number,
	                  |	CashSale.Date,
	                  |	CashSale.Company,
	                  |	CashSale.SalesTax,
	                  |	CashSale.RefNum,
	                  |	CashSale.Memo,
	                  |	CashSale.DocumentTotalRC,
	                  |	CashSale.PaymentMethod,
	                  |	CashSale.ShipTo
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
		CashSale.Insert("sales_tax_total", Result.SalesTax);
		CashSale.Insert("doc_total", Result.DocumentTotalRC);
		
		CashSales.Add(CashSale);
		
	EndDo;
	
	CashSalesList = New Map();
	CashSalesList.Insert("cash_sales", CashSales);
	
	jsonout = InternetConnectionClientServer.EncodeJSON(CashSalesList);
	
	Return jsonout;

EndFunction

Function CashSalePutCodeinout(jsonin, object_code)
	
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
		UpdatedCashSaleObj.SalesTax = ParsedJSON.sales_tax_total;		
	Except
		UpdatedCashSaleObj.SalesTax = 0;
	EndTry;

	UpdatedCashSaleObj.DocumentTotal = ParsedJSON.doc_total;
	UpdatedCashSaleObj.DocumentTotalRC = ParsedJSON.doc_total;
    UpdatedCashSaleObj.DepositType = "2";
	UpdatedCashSaleObj.Currency = Constants.DefaultCurrency.Get();
	UpdatedCashSaleObj.BankAccount = Constants.BankAccount.Get();
	UpdatedCashSaleObj.ExchangeRate = 1;
	UpdatedCashSaleObj.Location = Catalogs.Locations.MainWarehouse;
	
	DataLineItems = ParsedJSON.lines.line_items;
	
	LineItemsRows = DataLineItems.Count();
	For i = 0 To LineItemsRows -1 Do
		
		NewLine = UpdatedCashSaleObj.LineItems.Add();
		
		//product_api_code = DataLineItems[i].api_code;
		Product = Catalogs.Products.GetRef(New UUID(DataLineItems[i].api_code));
		//Product = Catalogs.Products.GetRef(New UUID(product_api_code));
		NewLine.Product = Product;
		NewLine.ProductDescription = Product.Description;
		NewLine.VATCode = CommonUse.GetAttributeValue(Product, "SalesVATCode");
		NewLine.VAT = 0;
		
		NewLine.Price = DataLineItems[i].price;
		NewLine.Quantity = DataLineItems[i].quantity;
		// get taxable from JSON
		Try
			TaxableType = DataLineItems[i].taxable_type;
			If TaxableType = "taxable" Then
				NewLine.SalesTaxType = Enums.SalesTaxTypes.Taxable;
			ElsIf TaxableType = "non-taxable" Then
				NewLine.SalesTaxType = Enums.SalesTaxTypes.NonTaxable;
			Else
				NewLine.SalesTaxType = Enums.SalesTaxTypes.NonTaxable;
			EndIf;
		Except
			NewLine.SalesTaxType = Enums.SalesTaxTypes.NonTaxable;	
		EndTry;

		NewLine.LineTotal = DataLineItems[i].line_total;
		Try
			TaxableAmount = DataLineItems[i].taxable_amount;
			NewLine.TaxableAmount = TaxableAmount				
		Except
			NewLine.TaxableAmount = 0;
		EndTry;
				
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
	CashSaleData.Insert("sales_tax_total", NewCashSale.SalesTax);
	CashSaleData.Insert("doc_total", NewCashSale.DocumentTotalRC);

	Query = New Query("SELECT
	                  |	CashSaleLineItems.Product,
	                  |	CashSaleLineItems.Price,
	                  |	CashSaleLineItems.Quantity,
	                  |	CashSaleLineItems.LineTotal,
	                  |	CashSaleLineItems.SalesTaxType,
	                  |	CashSaleLineItems.TaxableAmount
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
		LineItem.Insert("taxable_amount", Result.TaxableAmount);
		LineItem.Insert("line_total", Result.LineTotal);
		If Result.SalesTaxType = Enums.SalesTaxTypes.Taxable Then
			LineItem.Insert("taxable_type", "taxable");
		ElsIf Result.SalesTaxType = Enums.SalesTaxTypes.NonTaxable Then
			LineItem.Insert("taxable_type", "non-taxable");
		EndIf;
		LineItems.Add(LineItem);
		
	EndDo;
	
	LineItemsData = New Map();
	LineItemsData.Insert("line_items", LineItems);
	
	CashSaleData.Insert("lines", LineItemsData);
	
	jsonout = InternetConnectionClientServer.EncodeJSON(CashSaleData);
	
	Return jsonout;

EndFunction

Function CashSaleDeleteCodeinout(jsonin)
	
	ParsedJSON = InternetConnectionClientServer.DecodeJSON(jsonin);
	api_code = ParsedJSON.object_code;
	
	CashSale = Documents.CashSale.GetRef(New UUID(api_code));
	
	CashSaleObj = CashSale.GetObject();
	CashSaleObj.DeletionMark = True;
	
	Output = New Map();	
	
	Try
		CashSaleObj.Write(DocumentWriteMode.UndoPosting);
		Output.Insert("status", "success");
	Except
		//ErrorMessage = DetailErrorDescription(ErrorInfo());
		Output.Insert("error", "cash sale can not be deleted");
	EndTry;
	
	jsonout = InternetConnectionClientServer.EncodeJSON(Output);
	
	Return jsonout;

EndFunction

Function CashSaleGetCodeinout(jsonin)
	
	ParsedJSON = InternetConnectionClientServer.DecodeJSON(jsonin);
	api_code = ParsedJSON.object_code;
	
	CashSale = Documents.CashSale.GetRef(New UUID(api_code));
	
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
	CashSaleData.Insert("sales_tax_total", NewCashSale.SalesTax);
	CashSaleData.Insert("doc_total", NewCashSale.DocumentTotalRC);

	Query = New Query("SELECT
	                  |	CashSaleLineItems.Product,
	                  |	CashSaleLineItems.Price,
	                  |	CashSaleLineItems.Quantity,
	                  |	CashSaleLineItems.LineTotal,
	                  |	CashSaleLineItems.SalesTaxType,
	                  |	CashSaleLineItems.TaxableAmount
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
		LineItem.Insert("taxable_amount", Result.TaxableAmount);
		LineItem.Insert("line_total", Result.LineTotal);
		If Result.SalesTaxType = Enums.SalesTaxTypes.Taxable Then
			LineItem.Insert("taxable_type", "taxable");
		ElsIf Result.SalesTaxType = Enums.SalesTaxTypes.NonTaxable Then
			LineItem.Insert("taxable_type", "non-taxable");
		EndIf;
		LineItems.Add(LineItem);
		
	EndDo;
	
	LineItemsData = New Map();
	LineItemsData.Insert("line_items", LineItems);
	
	CashSaleData.Insert("lines", LineItemsData);
	
	jsonout = InternetConnectionClientServer.EncodeJSON(CashSaleData);
	
	Return jsonout;

EndFunction

Function CashReceiptPostinout(jsonin)
		
	ParsedJSON = InternetConnectionClientServer.DecodeJSON(jsonin);
		
	NCR = Documents.CashReceipt.CreateDocument();
	NCR.Date = CurrentDate(); // ParsedJSON.date; convert from seconds to normal date
	NCR.Memo = ParsedJSON.memo;
	
	Customer = Catalogs.Companies.FindByDescription(ParsedJSON.company_name);
	
	If Customer = Catalogs.Companies.EmptyRef() Then
		
		NewCompany = Catalogs.Companies.CreateItem();
		
		NewCompany.Description = ParsedJSON.company_name;
		NewCompany.Customer = True;
		NewCompany.DefaultCurrency = Constants.DefaultCurrency.Get();
		NewCompany.Terms = Catalogs.PaymentTerms.Net30;

		NewCompany.Write();
			
		AddressLine = Catalogs.Addresses.CreateItem();
		AddressLine.Owner = NewCompany.Ref;
		AddressLine.Description = "Primary";
		AddressLine.Write();
		
		Customer = NewCompany.Ref;
		
	Else	
	EndIf;
		
	NCR.Company = Customer;
	NCR.CompanyCode = Customer.Code;
	NCR.RefNum = ParsedJSON.ref_num;
	NCR.DepositType = "1";   
	
	NCR.CashPayment = Number(ParsedJSON.amount);
	NCR.UnappliedPayment = Number(ParsedJSON.amount);
	NCR.DocumentTotal = Number(ParsedJSON.amount);
	NCR.DocumentTotalRC = Number(ParsedJSON.amount);
	NCR.PaymentMethod = Catalogs.PaymentMethods.DebitCard;
	NCR.Currency = Constants.DefaultCurrency.Get();
	NCR.ARAccount = NCR.Currency.DefaultARAccount;
	
	NCR.Write(DocumentWriteMode.Posting);
	
	///
	
	//Query = New Query("SELECT
	//				  |	Addresses.Description,
	//				  |	Addresses.FirstName,
	//				  |	Addresses.LastName,
	//				  |	Addresses.DefaultBilling,
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
	//Query.SetParameter("Company", NewCompany.Ref);
	//Result = Query.Execute().Choose();
	//
	//Addresses = New Array();
	//
	//While Result.Next() Do
	//	
	//	Address = New Map();
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
	//	Address.Insert("state", Result.State.Code);
	//	Address.Insert("zip", Result.ZIP);
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
	//CompanyData.Insert("company_name", NewCompany.Description);
	//CompanyData.Insert("company_code", NewCompany.Code);
	//CompanyData.Insert("company_type", "customer");
	//CompanyData.Insert("lines", DataAddresses);
	//
	//jsonout = InternetConnectionClientServer.EncodeJSON(CompanyData);
	
	//Return jsonout;
	
EndFunction

Function InvoicePostinout(jsonin)
		
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
		NewInvoice.SalesTax = ParsedJSON.sales_tax_total;		
	Except
		NewInvoice.SalesTax = 0;
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
	
	DataLineItems = ParsedJSON.lines.line_items;
	
	LineItemsRows = DataLineItems.Count();
	For i = 0 To LineItemsRows -1 Do
		
		NewLine = NewInvoice.LineItems.Add();
		
		Product = Catalogs.Products.GetRef(New UUID(DataLineItems[i].api_code));
		NewLine.Product = Product;
		NewLine.ProductDescription = Product.Description;
		NewLine.VATCode = CommonUse.GetAttributeValue(Product, "SalesVATCode");
		NewLine.VAT = 0;
		
		NewLine.Price = DataLineItems[i].price;
		NewLine.Quantity = DataLineItems[i].quantity;
		// get taxable from JSON
		Try
			TaxableType = DataLineItems[i].taxable_type;
			If TaxableType = "taxable" Then
				NewLine.SalesTaxType = Enums.SalesTaxTypes.Taxable;
			ElsIf TaxableType = "non-taxable" Then
				NewLine.SalesTaxType = Enums.SalesTaxTypes.NonTaxable;
			Else
				NewLine.SalesTaxType = Enums.SalesTaxTypes.NonTaxable;
			EndIf;
		Except
			NewLine.SalesTaxType = Enums.SalesTaxTypes.NonTaxable;	
		EndTry;
		
		NewLine.LineTotal = DataLineItems[i].line_total;
		Try
			TaxableAmount = DataLineItems[i].taxable_amount;
			NewLine.TaxableAmount = TaxableAmount				
		Except
			NewLine.TaxableAmount = 0;
		EndTry;
				
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
	InvoiceData.Insert("sales_tax_total", NewInvoice.SalesTax);
	InvoiceData.Insert("doc_total", NewInvoice.DocumentTotalRC);

	Query = New Query("SELECT
	                  |	InvoiceLineItems.Product,
	                  |	InvoiceLineItems.Price,
	                  |	InvoiceLineItems.Quantity,
	                  |	InvoiceLineItems.LineTotal,
	                  |	InvoiceLineItems.SalesTaxType,
	                  |	InvoiceLineItems.TaxableAmount
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
		LineItem.Insert("taxable_amount", Result.TaxableAmount);
		LineItem.Insert("line_total", Result.LineTotal);
		If Result.SalesTaxType = Enums.SalesTaxTypes.Taxable Then
			LineItem.Insert("taxable_type", "taxable");
		ElsIf Result.SalesTaxType = Enums.SalesTaxTypes.NonTaxable Then
			LineItem.Insert("taxable_type", "non-taxable");
		EndIf;
		LineItems.Add(LineItem);
		
	EndDo;
	
	LineItemsData = New Map();
	LineItemsData.Insert("line_items", LineItems);
	
	InvoiceData.Insert("lines", LineItemsData);
	
	jsonout = InternetConnectionClientServer.EncodeJSON(InvoiceData);
	
	Return jsonout;
	
EndFunction

Function InvoicesGetinout(jsonin)
		
	Query = New Query("SELECT
					  | SalesInvoice.Ref,
	                  |	SalesInvoice.Number,
	                  |	SalesInvoice.Date,
					  | SalesInvoice.DueDate,
	                  |	SalesInvoice.Company,
	                  |	SalesInvoice.SalesTax,
	                  |	SalesInvoice.RefNum,
	                  |	SalesInvoice.Memo,
	                  |	SalesInvoice.DocumentTotalRC,
	                  |	SalesInvoice.ShipTo
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
		Invoice.Insert("sales_tax_total", Result.SalesTax);
		Invoice.Insert("doc_total", Result.DocumentTotalRC);
		
		Invoices.Add(Invoice);
		
	EndDo;
	
	InvoicesList = New Map();
	InvoicesList.Insert("invoices", Invoices);
	
	jsonout = InternetConnectionClientServer.EncodeJSON(InvoicesList);
	
	Return jsonout;

EndFunction

Function InvoicePutCodeinout(jsonin, object_code)
	
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
		NewInvoice.SalesTax = ParsedJSON.sales_tax_total;		
	Except
		NewInvoice.SalesTax = 0;
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
	
	DataLineItems = ParsedJSON.lines.line_items;
	
	LineItemsRows = DataLineItems.Count();
	For i = 0 To LineItemsRows -1 Do
		
		NewLine = NewInvoice.LineItems.Add();
		
		Product = Catalogs.Products.GetRef(New UUID(DataLineItems[i].api_code));
		NewLine.Product = Product;
		NewLine.ProductDescription = Product.Description;
		NewLine.VATCode = CommonUse.GetAttributeValue(Product, "SalesVATCode");
		NewLine.VAT = 0;
		
		NewLine.Price = DataLineItems[i].price;
		NewLine.Quantity = DataLineItems[i].quantity;
		// get taxable from JSON
		Try
			TaxableType = DataLineItems[i].taxable_type;
			If TaxableType = "taxable" Then
				NewLine.SalesTaxType = Enums.SalesTaxTypes.Taxable;
			ElsIf TaxableType = "non-taxable" Then
				NewLine.SalesTaxType = Enums.SalesTaxTypes.NonTaxable;
			Else
				NewLine.SalesTaxType = Enums.SalesTaxTypes.NonTaxable;
			EndIf;
		Except
			NewLine.SalesTaxType = Enums.SalesTaxTypes.NonTaxable;	
		EndTry;
		
		NewLine.LineTotal = DataLineItems[i].line_total;
		Try
			TaxableAmount = DataLineItems[i].taxable_amount;
			NewLine.TaxableAmount = TaxableAmount				
		Except
			NewLine.TaxableAmount = 0;
		EndTry;
				
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
	InvoiceData.Insert("sales_tax_total", NewInvoice.SalesTax);
	InvoiceData.Insert("doc_total", NewInvoice.DocumentTotalRC);

	Query = New Query("SELECT
	                  |	InvoiceLineItems.Product,
	                  |	InvoiceLineItems.Price,
	                  |	InvoiceLineItems.Quantity,
	                  |	InvoiceLineItems.LineTotal,
	                  |	InvoiceLineItems.SalesTaxType,
	                  |	InvoiceLineItems.TaxableAmount
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
		LineItem.Insert("taxable_amount", Result.TaxableAmount);
		LineItem.Insert("line_total", Result.LineTotal);
		If Result.SalesTaxType = Enums.SalesTaxTypes.Taxable Then
			LineItem.Insert("taxable_type", "taxable");
		ElsIf Result.SalesTaxType = Enums.SalesTaxTypes.NonTaxable Then
			LineItem.Insert("taxable_type", "non-taxable");
		EndIf;
		LineItems.Add(LineItem);
		
	EndDo;
	
	LineItemsData = New Map();
	LineItemsData.Insert("line_items", LineItems);
	
	InvoiceData.Insert("lines", LineItemsData);
	
	jsonout = InternetConnectionClientServer.EncodeJSON(InvoiceData);
	
	Return jsonout;

EndFunction

Function InvoiceDeleteCodeinout(jsonin)
	
	ParsedJSON = InternetConnectionClientServer.DecodeJSON(jsonin);
	api_code = ParsedJSON.object_code;
	
	SalesInvoice = Documents.SalesInvoice.GetRef(New UUID(api_code));
	
	SalesInvoiceObj = SalesInvoice.GetObject();
	SalesInvoiceObj.DeletionMark = True;
	
	Output = New Map();	
	
	Try
		SalesInvoiceObj.Write(DocumentWriteMode.UndoPosting);
		Output.Insert("status", "success");
	Except
		//ErrorMessage = DetailErrorDescription(ErrorInfo());
		Output.Insert("error", "sales invoice can not be deleted");
	EndTry;
	
	jsonout = InternetConnectionClientServer.EncodeJSON(Output);
	
	Return jsonout;

EndFunction

Function InvoiceGetCodeinout(jsonin)
	
	ParsedJSON = InternetConnectionClientServer.DecodeJSON(jsonin);
	api_code = ParsedJSON.object_code;
	
	NewInvoice = Documents.SalesInvoice.GetRef(New UUID(api_code));
		
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
	InvoiceData.Insert("sales_tax_total", NewInvoice.SalesTax);
	InvoiceData.Insert("doc_total", NewInvoice.DocumentTotalRC);

	Query = New Query("SELECT
	                  |	InvoiceLineItems.Product,
	                  |	InvoiceLineItems.Price,
	                  |	InvoiceLineItems.Quantity,
	                  |	InvoiceLineItems.LineTotal,
	                  |	InvoiceLineItems.SalesTaxType,
	                  |	InvoiceLineItems.TaxableAmount
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
		LineItem.Insert("taxable_amount", Result.TaxableAmount);
		LineItem.Insert("line_total", Result.LineTotal);
		If Result.SalesTaxType = Enums.SalesTaxTypes.Taxable Then
			LineItem.Insert("taxable_type", "taxable");
		ElsIf Result.SalesTaxType = Enums.SalesTaxTypes.NonTaxable Then
			LineItem.Insert("taxable_type", "non-taxable");
		EndIf;
		LineItems.Add(LineItem);
		
	EndDo;
	
	LineItemsData = New Map();
	LineItemsData.Insert("line_items", LineItems);
	
	InvoiceData.Insert("lines", LineItemsData);
	
	jsonout = InternetConnectionClientServer.EncodeJSON(InvoiceData);
	
	Return jsonout;


EndFunction


Function SaleOrderPostinout(jsonin)
		
	ParsedJSON = InternetConnectionClientServer.DecodeJSON(jsonin);
		
	NewSO = Documents.SalesOrder.CreateDocument();
	customer_api_code = ParsedJSON.customer_api_code;
	NewSO.Company = Catalogs.Companies.GetRef(New UUID(customer_api_code));
	
	// SHIP TO ADDRESS SECTION
	
	Try ship_to_api_code = ParsedJSON.ship_to_api_code Except ship_to_api_code = Undefined EndTry;
	If NOT ship_to_api_code = Undefined Then
		// todo - check if address belongs to company
		NewSO.ShipTo = Catalogs.Addresses.GetRef(New UUID(ship_to_api_code));
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
		NewSO.BillTo = Catalogs.Addresses.GetRef(New UUID(bill_to_api_code));
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
		NewSO.SalesTax = ParsedJSON.sales_tax_total;		
	Except
		NewSO.SalesTax = 0;
	EndTry;
	NewSO.DocumentTotal = ParsedJSON.doc_total;
	NewSO.DocumentTotalRC = ParsedJSON.doc_total;
	
	//NewCashSale.DepositType = "2";
	DefaultCurrency = Constants.DefaultCurrency.Get();
	NewSO.Currency = DefaultCurrency;
	//NewSO.ARAccount = DefaultCurrency.DefaultARAccount;
	//NewCashSale.BankAccount = Constants.BankAccount.Get();
	NewSO.ExchangeRate = 1;
	NewSO.Location = Catalogs.Locations.MainWarehouse;
	
	DataLineItems = ParsedJSON.lines.line_items;
	
	LineItemsRows = DataLineItems.Count();
	For i = 0 To LineItemsRows -1 Do
		
		NewLine = NewSO.LineItems.Add();
		
		Product = Catalogs.Products.GetRef(New UUID(DataLineItems[i].api_code));
		NewLine.Product = Product;
		NewLine.ProductDescription = Product.Description;
		NewLine.VATCode = CommonUse.GetAttributeValue(Product, "SalesVATCode");
		NewLine.VAT = 0;
		
		NewLine.Price = DataLineItems[i].price;
		NewLine.Quantity = DataLineItems[i].quantity;
		// get taxable from JSON
		Try
			TaxableType = DataLineItems[i].taxable_type;
			If TaxableType = "taxable" Then
				NewLine.SalesTaxType = Enums.SalesTaxTypes.Taxable;
			ElsIf TaxableType = "non-taxable" Then
				NewLine.SalesTaxType = Enums.SalesTaxTypes.NonTaxable;
			Else
				NewLine.SalesTaxType = Enums.SalesTaxTypes.NonTaxable;
			EndIf;
		Except
			NewLine.SalesTaxType = Enums.SalesTaxTypes.NonTaxable;	
		EndTry;
		
		NewLine.LineTotal = DataLineItems[i].line_total;
		Try
			TaxableAmount = DataLineItems[i].taxable_amount;
			NewLine.TaxableAmount = TaxableAmount				
		Except
			NewLine.TaxableAmount = 0;
		EndTry;
				
	EndDo;
	
	
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

Function SaleOrderPutCodeinout(jsonin, object_code)
	
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
		NewSO.SalesTax = ParsedJSON.sales_tax_total;		
	Except
		NewSO.SalesTax = 0;
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
		NewLine.VATCode = CommonUse.GetAttributeValue(Product, "SalesVATCode");
		NewLine.VAT = 0;
		
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
		Try
			TaxableType = DataLineItems[i].taxable_type;
			If TaxableType = "taxable" Then
				NewLine.SalesTaxType = Enums.SalesTaxTypes.Taxable;
			ElsIf TaxableType = "non-taxable" Then
				NewLine.SalesTaxType = Enums.SalesTaxTypes.NonTaxable;
			Else
				NewLine.SalesTaxType = Enums.SalesTaxTypes.NonTaxable;
			EndIf;
		Except
			NewLine.SalesTaxType = Enums.SalesTaxTypes.NonTaxable;	
		EndTry;
		
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
		
		Try
			TaxableAmount = DataLineItems[i].taxable_amount;
			NewLine.TaxableAmount = TaxableAmount				
		Except
			NewLine.TaxableAmount = 0;
		EndTry;
				
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















