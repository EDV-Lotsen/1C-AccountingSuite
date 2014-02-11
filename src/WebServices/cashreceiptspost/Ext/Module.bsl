
Function inout(jsonin)
		
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
	//NCR.CompanyCode = Customer.Code;
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
