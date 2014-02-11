
Function inout(jsonin,account_id)
		
	NewCompany = Catalogs.Companies.CreateItem();
	
	NewCompany.Description = jsonin;
	NewCompany.Customer = True;
	NewCompany.CF1String = account_id;
	NewCompany.DefaultCurrency = Constants.DefaultCurrency.Get();
	NewCompany.Terms = Catalogs.PaymentTerms.Net30;

	NewCompany.Write();
		
	AddressLine = Catalogs.Addresses.CreateItem();
	AddressLine.Owner = NewCompany.Ref;
	AddressLine.Description = "Primary";
	AddressLine.Write();

	Return "success";

EndFunction
