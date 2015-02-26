
Procedure CreateCustomerVendorCSV(ItemDataSet) Export
	
	// add transactions 1-500
	Counter = 0;
	Counter10 = 0;
	MaxCount = ItemDataSet.count();
	For Each DataLine In ItemDataSet Do
		
		Counter = Counter + 1;
		Progress = Int((Counter/MaxCount)*10); 
		If Counter10 <> Progress then
			Counter10 = Progress;
			LongActions.InformActionProgres(Counter10*10,"Current progress: "+(Counter10*10) +"%");
		EndIf;	
		
		Try

	 	CreatingNewCompany = False;
		CompanyFound = Catalogs.Companies.FindByDescription(DataLine.CustomerDescription,True);
		If CompanyFound = Catalogs.Companies.EmptyRef() OR DataLine.UpdateAll = True Then
			
			If CompanyFound = Catalogs.Companies.EmptyRef() Then 
				CreatingNewCompany = True;
				
				NewCompany = Catalogs.Companies.CreateItem();
				NewCompany.Code = DataLine.CustomerCode;
				
				If TrimAll(NewCompany.Code) = "" Then
					NewCompany.SetNewCode();
				EndIf;
				
				NewCompany.Description = DataLine.CustomerDescription;
				NewCompany.FullName = DataLine.CustomerFullName;
			Else 
				NewCompany = CompanyFound.GetObject();
			EndIf;	
			
			If DataLine.CustomerType = 0 Then
				NewCompany.Customer = True;
			ElsIf DataLine.CustomerType = 1 Then
				NewCompany.Vendor = True;
			ElsIf DataLine.CustomerType = 2 Then
				NewCompany.Customer = True;
				NewCompany.Vendor = True;
			Else
				NewCompany.Customer = True;
			EndIf;
			
			NewCompany.Vendor1099 = DataLine.CustomerVendor1099;
			
			NewCompany.Employee = DataLine.CustomerEmployee;
			
			If DataLine.CustomerEIN_SSN <> Enums.FederalIDType.EmptyRef() Then
				NewCompany.FederalIDType = DataLine.CustomerEIN_SSN;
			EndIf;
			
			If DataLine.CustomerIncomeAccount <> ChartsOfAccounts.ChartOfAccounts.EmptyRef() Then
				NewCompany.IncomeAccount = DataLine.CustomerIncomeAccount;
			EndIf;
			
			If DataLine.CustomerExpenseAccount <> ChartsOfAccounts.ChartOfAccounts.EmptyRef() Then
				NewCompany.ExpenseAccount = DataLine.CustomerExpenseAccount;
			EndIf;
			
			NewCompany.DefaultCurrency = Constants.DefaultCurrency.Get();
			If DataLine.CustomerTerms <> Catalogs.PaymentTerms.EmptyRef() Then
				NewCompany.Terms = DataLine.CustomerTerms;
			Else
				NewCompany.Terms = Catalogs.PaymentTerms.Net30;
			EndIf;
			NewCompany.Notes = DataLine.CustomerNotes;
			NewCompany.USTaxID = DataLine.CustomerVendorTaxID;
			If ValueIsFilled(NewCompany.USTaxID) and NewCompany.FederalIDType.IsEmpty() Then 
				IDSeparator = Find(NewCompany.USTaxID,"-");
				If IDSeparator = 4 Then  
					NewCompany.FederalIDType = Enums.FederalIDType.SSN;
				Else 
					NewCompany.FederalIDType = Enums.FederalIDType.EIN;
				EndIf;	
			EndIf;	
			If DataLine.CustomerCF1String <> "" Then 
				NewCompany.CF1String = DataLine.CustomerCF1String;
			EndIf;
			NewCompany.CF1Num = DataLine.CustomerCF1Num;
			
			If DataLine.CustomerCF2String <> "" Then 
				NewCompany.CF2String = DataLine.CustomerCF2String;
			EndIf;
			NewCompany.CF2Num = DataLine.CustomerCF2Num;
			
			If DataLine.CustomerCF3String <> "" Then 
				NewCompany.CF3String = DataLine.CustomerCF3String;
			EndIf;
			NewCompany.CF3Num = DataLine.CustomerCF3Num;
			
			If DataLine.CustomerCF4String <> "" Then 
				NewCompany.CF4String = DataLine.CustomerCF4String;
			EndIf;
			NewCompany.CF4Num = DataLine.CustomerCF4Num;
			
			If DataLine.CustomerCF5String <> "" Then 
				NewCompany.CF5String = DataLine.CustomerCF5String;
			EndIf;
			NewCompany.CF5Num = DataLine.CustomerCF5Num;
			
			If DataLine.CustomerSalesPerson <> Catalogs.SalesPeople.EmptyRef() Then
				NewCompany.SalesPerson = DataLine.CustomerSalesPerson;
			Else
			EndIf;
			
			If DataLine.CustomerWebsite <> "" Then 
				NewCompany.Website = DataLine.CustomerWebsite;
			EndIf;
			NewCompany.CF4Num = DataLine.CustomerCF4Num;
			
			If DataLine.CustomerPriceLevel <> Catalogs.PriceLevels.EmptyRef() Then
				NewCompany.PriceLevel = DataLine.CustomerPriceLevel;
			Else
			EndIf;
			
			NewCompany.Taxable = DataLine.STaxable;
			NewCompany.SalesTaxRate = DataLine.STaxRate;
			
			NewCompany.Write();
			
		Else 
			NewCompany = CompanyFound;
		EndIf;
		
		ShipAddresName = "PrimaryShipping";
		If DataLine.CustomerAddressID = "" Then
			BillAddresName = "PrimaryBilling";
		Else
			BillAddresName = DataLine.CustomerAddressID;
		EndIf;
		
		CreateUpdateAddres(DataLine, NewCompany.Ref, BillAddresName, DataLine.DefaultBillingAddress,      );
		CreateUpdateAddres(DataLine, NewCompany.Ref, ShipAddresName,     ,DataLine.DefaultShippingAddress, True );
		
		Except
			ErrorText = "Document Line: "+Counter+ Chars.LF+ ErrorDescription();
			Raise ErrorText;
		EndTry;
				
	EndDo;
	

EndProcedure

Procedure CreateUpdateAddres(DataLine, Owner,  Name, DefaultBilling = False, DefaultShipping = False, UpdateExistingAddress = False) 
	
	SettingMap = New Structure;
	
	SettingMap.Insert("SalesPerson", 	DataLine.AddressSalesPerson);
	SettingMap.Insert("Salutation", 	DataLine.AddressSalutation);
	SettingMap.Insert("FirstName", 		DataLine.CustomerFirstName);
	SettingMap.Insert("LastName",		DataLine.CustomerLastName);
	SettingMap.Insert("MiddleName", 	DataLine.CustomerMiddleName);
	SettingMap.Insert("Suffix", 		DataLine.AddressSuffix);
	SettingMap.Insert("JobTitle",		DataLine.AddressJobTitle);
	
	SettingMap.Insert("AddressLine1", 	DataLine.CustomerAddressLine1);
	SettingMap.Insert("AddressLine2", 	DataLine.CustomerAddressLine2);
	SettingMap.Insert("AddressLine3", 	DataLine.CustomerAddressLine3);
	SettingMap.Insert("City",			DataLine.CustomerCity);
	SettingMap.Insert("State", 			DataLine.CustomerState);
	SettingMap.Insert("Country", 		DataLine.CustomerCountry);
	SettingMap.Insert("ZIP", 			DataLine.CustomerZIP);
	
	SettingMap.Insert("Phone", 			DataLine.CustomerPhone);
	SettingMap.Insert("Email", 			DataLine.CustomerEmail);
	SettingMap.Insert("Fax", 			DataLine.CustomerFax);
	SettingMap.Insert("Cell", 			DataLine.CustomerCell);
	                            	
	SettingMap.Insert("CF1String", 		DataLine.AddressCF1String);
	SettingMap.Insert("CF2String", 		DataLine.AddressCF2String);
	SettingMap.Insert("CF3String", 		DataLine.AddressCF3String);
	SettingMap.Insert("CF4String",	 	DataLine.AddressCF4String);
	SettingMap.Insert("CF5String",	 	DataLine.AddressCF5String);
	
	SettingMap.Insert("Notes", 			DataLine.CustomerAddressNotes);
	
	AllFieldsIsEmpty = True;
	For Each Setting in SettingMap Do
		If ValueIsFilled(Setting.Value) Then 
			AllFieldsIsEmpty = False;
		EndIf;	
	EndDo;	
	
	If AllFieldsIsEmpty Then 
		Return;
	EndIf;	
	
	SettingMap.Insert("Owner", 			Owner);
	SettingMap.Insert("DefaultBilling", DefaultBilling);
	SettingMap.Insert("DefaultShipping",DefaultShipping);
	
	If ((Not DefaultBilling) and (Not  DefaultShipping)) Then
		UpdateExistingAddress = True;
		Name = StrReplace(Name, "Primary", "");
	EndIf;	

	If UpdateExistingAddress Then
		
		Query = New Query;
		Query.Text = 
		"SELECT
		|	Addresses.Ref,
		|	Addresses.DefaultBilling,
		|	Addresses.DefaultShipping
		|FROM
		|	Catalog.Addresses AS Addresses
		|WHERE
		|	Addresses.Owner = &Owner
		|	AND Addresses.FirstName = &FirstName
		|	AND Addresses.MiddleName = &MiddleName
		|	AND Addresses.LastName = &LastName
		|	AND Addresses.Salutation = &Salutation
		|	AND Addresses.Phone = &Phone
		|	AND Addresses.Cell = &Cell
		|	AND Addresses.Fax = &Fax
		|	AND Addresses.Email = &Email
		|	AND Addresses.AddressLine1 = &AddressLine1
		|	AND Addresses.AddressLine2 = &AddressLine2
		|	AND Addresses.AddressLine3 = &AddressLine3
		|	AND Addresses.City = &City
		|	AND Addresses.State = &State
		|	AND Addresses.Country = &Country
		|	AND Addresses.ZIP = &ZIP
		|	AND Addresses.Notes LIKE &Notes
		|	AND Addresses.Suffix LIKE &Suffix
		|	AND Addresses.JobTitle LIKE &JobTitle
		|	AND Addresses.CF1String = &CF1String
		|	AND Addresses.CF2String = &CF2String
		|	AND Addresses.CF3String = &CF3String
		|	AND Addresses.CF4String = &CF4String
		|	AND Addresses.CF5String = &CF5String
		|	AND Addresses.SalesPerson = &SalesPerson
		|	";
		
		For Each Setting in SettingMap Do
			Query.SetParameter(Setting.Key, Setting.Value);
		EndDo;	
		
		QueryResult = Query.Execute();
		SelectionDetailRecords = QueryResult.Select();
		
		
		If SelectionDetailRecords.Count() > 1 Then 
			DefBillingMark = DefaultBilling;
			DefShippingMark = DefaultShipping;
			AddressRef = Undefined;
			While SelectionDetailRecords.Next() Do
				DefBillingMark =  DefBillingMark OR SelectionDetailRecords.DefaultBilling;
				DefShippingMark =  DefShippingMark OR SelectionDetailRecords.DefaultShipping;
				AddressRef = SelectionDetailRecords.Ref;
				AddressLine = AddressRef.GetObject();
				// Mark all as non default address, and mark as deleted
				AddressLine.DefaultBilling = False;
				AddressLine.DefaultShipping = False;
				AddressLine.DeletionMark = True;
				AddressLine.Write();
			EndDo;	
			// Unmark last one, and set all marks to one object
			AddressLine.DeletionMark = False;
			AddressLine.DefaultBilling = DefBillingMark;
			AddressLine.DefaultShipping = DefShippingMark;
		Else 
			If SelectionDetailRecords.Next() Then 
				AddressRef = SelectionDetailRecords.Ref;
				AddressLine = AddressRef.GetObject();	
			Else 
				AddressLine = Catalogs.Addresses.CreateItem();	
			EndIf;
		EndIf;
		
		
	Else	
		Query = New Query;
		Query.Text = 
		"SELECT Top 1
		|	Addresses.Ref
		|FROM
		|	Catalog.Addresses AS Addresses
		|WHERE
		|	Addresses.Owner = &Owner
		|	AND( 
		|	(Addresses.DefaultBilling AND &DefaultBilling)
		|	OR 
		|	(Addresses.DefaultShipping AND &DefaultShipping)
		|	)";
		
		Query.SetParameter("DefaultBilling", DefaultBilling);
		Query.SetParameter("DefaultShipping", DefaultShipping);
		Query.SetParameter("Owner", Owner);
		QueryResult = Query.Execute();
		
		SelectionDetailRecords = QueryResult.Select();
		If SelectionDetailRecords.Next() Then 
			AddressRef = SelectionDetailRecords.Ref;
			AddressLine = AddressRef.GetObject();	
		Else 
			AddressLine = Catalogs.Addresses.CreateItem();	
		EndIf;
		
	EndIf;	
	
	
	AddressLine.Owner = Owner;
	AddressLine.Description = Name;
	
	If DataLine.AddressSalesPerson <> Catalogs.SalesPeople.EmptyRef() Then
		AddressLine.SalesPerson = DataLine.AddressSalesPerson;
	EndIf;
	AddressLine.Salutation = DataLine.AddressSalutation;
	AddressLine.FirstName = DataLine.CustomerFirstName;
	AddressLine.MiddleName = DataLine.CustomerMiddleName;
	AddressLine.LastName = DataLine.CustomerLastName;
	AddressLine.Suffix = DataLine.AddressSuffix;
	AddressLine.JobTitle = DataLine.AddressJobTitle;
	
	AddressLine.Phone = DataLine.CustomerPhone;
	AddressLine.Cell = DataLine.CustomerCell;
	AddressLine.Fax = DataLine.CustomerFax;
	AddressLine.Email = DataLine.CustomerEmail;
	
	AddressLine.AddressLine1 = DataLine.CustomerAddressLine1;
	AddressLine.AddressLine2 = DataLine.CustomerAddressLine2;
	AddressLine.AddressLine3 = DataLine.CustomerAddressLine3;
	AddressLine.City = DataLine.CustomerCity;
	AddressLine.State = DataLine.CustomerState;
	AddressLine.Country = DataLine.CustomerCountry;
	AddressLine.ZIP = DataLine.CustomerZIP;
	AddressLine.Notes = DataLine.CustomerAddressNotes;
	
	AddressLine.CF1String = DataLine.AddressCF1String;
	AddressLine.CF2String = DataLine.AddressCF2String;
	AddressLine.CF3String = DataLine.AddressCF3String;
	AddressLine.CF4String = DataLine.AddressCF4String;
	AddressLine.CF5String = DataLine.AddressCF5String;
	
	AddressLine.DefaultShipping = AddressLine.DefaultShipping Or DefaultShipping;
	AddressLine.DefaultBilling = AddressLine.DefaultBilling Or DefaultBilling;
	
	IF AddressLine.DefaultShipping And AddressLine.DefaultBilling Then
		AddressLine.Description = StrReplace(StrReplace(AddressLine.Description, "Shipping",""), "Billing", "");
	EndIf;	
	
	If TrimAll(AddressLine.Description) = "" Then
		AddressLine.Description = "Primary";
	EndIf;	
	
	AddressLine.Write();

	
EndProcedure

Procedure CreatePurchaseOrderCSV(Date, Date2, ItemDataSet) Export
	
	Counter = 0;
	Counter10 = 0;
	MaxCount = ItemDataSet.count();
	
	PrevNumber = Undefined;
	DocObject = Undefined;
	DocPost = False;
	
	QuantityPrecision = GeneralFunctionsReusable.DefaultQuantityPrecision();
	
	For Each DataLine In ItemDataSet Do
		
		Counter = Counter + 1;
		Progress = Int((Counter/MaxCount)*10); 
		If Counter10 <> Progress then
			Counter10 = Progress;
			LongActions.InformActionProgres(Counter10*10,"Current progress: "+(Counter10*10) +"%");
		EndIf;	
		
		Try
			If PrevNumber <> DataLine.Number  Then
				PrevNumber = DataLine.Number;
								
				// Writing previous document
				If DocObject <> Undefined Then
					
					// Calculate document totals.
					DocObject.DocumentTotal   = DocObject.LineItems.Total("LineTotal");
					DocObject.DocumentTotalRC = Round(DocObject.DocumentTotal * DocObject.ExchangeRate, 2);
					
					DocObject.Write(?(DocPost,DocumentWriteMode.Posting,DocumentWriteMode.Write));
				EndIf;	
				
				// First row, need to fill up document, Lines will be filled later
				ExistingDoc = Documents.PurchaseOrder.FindByNumber(DataLine.Number,DataLine.DocDate);
				If ValueIsFilled(ExistingDoc) Then 
					DocObject = ExistingDoc.GetObject();
					DocObject.LineItems.Clear();
				Else
					DocObject = Documents.PurchaseOrder.CreateDocument();
					DocObject.Number = DataLine.Number;
				EndIf;
				// Filling document attributes
				DocObject.Date = DataLine.DocDate;
				DocObject.Company = DataLine.Company;
				
				If ValueIsFilled(DataLine.Currency) Then 
					DocObject.Currency = DataLine.Currency;
				Else 
					DocObject.Currency = Constants.DefaultCurrency.Get()
				EndIf;
				
				DocObject.ExchangeRate = GeneralFunctions.GetExchangeRate(DocObject.Date, DocObject.Currency);
				
				If ValueIsFilled(DataLine.DSCompany) Then 
					DocObject.DropshipCompany = DataLine.DSCompany;
				EndIf;
				
				If ValueIsFilled(DataLine.CompanyAddres) Then 
					DocObject.CompanyAddress = DataLine.CompanyAddres;
				Else 
					Query = New Query;
					Query.Text = 
					"SELECT
					|	Addresses.Ref
					|FROM
					|	Catalog.Addresses AS Addresses
					|WHERE
					|	Addresses.DefaultBilling = &DefaultBilling
					|	AND Addresses.Owner = &Owner";
					
					Query.SetParameter("DefaultBilling", True);
					Query.SetParameter("Owner", DocObject.Company);
					
					QueryResult = Query.Execute();
					
					SelectionDetailRecords = QueryResult.Select();
					While SelectionDetailRecords.Next() Do
						DocObject.CompanyAddress = SelectionDetailRecords.Ref;
					EndDo;
				EndIf;
				
				If ValueIsFilled(DataLine.DSShipTo) Then 
					DocObject.DropshipShipTo = DataLine.DSShipTo;
				EndIf;
				
				If ValueIsFilled(DataLine.DSConfirmTo) Then 
					DocObject.DropshipConfirmTo = DataLine.DSConfirmTo;
				EndIf;
				
				If ValueIsFilled(DataLine.DSRefN) Then 
					DocObject.DropshipRefNum = DataLine.DSRefN;
				EndIf;
				
				If ValueIsFilled(DataLine.SalesPerson) Then 
					DocObject.SalesPerson = DataLine.SalesPerson;
				EndIf;
				
				If ValueIsFilled(DataLine.Location) Then 
					DocObject.Location = DataLine.Location;
				EndIf;
				
				//If ValueIsFilled(DataLine.DeliveryDate) Then 
					DocObject.DeliveryDate = DataLine.DeliveryDate;
				//EndIf;
				
				If ValueIsFilled(DataLine.Project) Then 
					DocObject.Project = DataLine.Project;
				EndIf;
				
				If ValueIsFilled(DataLine.Class) Then 
					DocObject.Class = DataLine.Class;
				EndIf;
				
				If ValueIsFilled(DataLine.Memo) Then 
					DocObject.Memo = DataLine.Memo;
				EndIf;
				
				//If ValueIsFilled(DataLine.DocTotalRC) Then 
				//	DocObject.DocumentTotal = DataLine.DocTotalRC;
				//EndIf;
				
				DocObject.DocumentTotal = DataLine.DocTotal;
				If ValueIsFilled(DataLine.DocTotalRC) Then 
					DocObject.DocumentTotalRC = DataLine.DocTotalRC;
				Else 
					DocObject.DocumentTotalRC = DataLine.DocTotal;
				EndIf;	
				
				DocPost = (DataLine.ToPost = True);
				
				// ++ Automatically filled fields
				DocObject.Location 	= GeneralFunctions.GetDefaultLocation();
				//DocObject.UseIR		= Constants.EnhancedInventoryReceiving.Get();
				DocObject.UseIR		= False;
				// -- Automatically filled fields
				
			EndIf;
			
			DocLineItem = DocObject.LineItems.Add();
			
			FillPropertyValues(DocLineItem, DocObject, "Location, DeliveryDate, Project, Class");
			
			
			If ValueIsFilled(DataLine.Product) Then 
				DocLineItem.Product = DataLine.Product;
				ProductProperties = CommonUse.GetAttributeValues(DocLineItem.Product,   New Structure("Description, UnitSet"));
				UnitSetProperties = CommonUse.GetAttributeValues(ProductProperties.UnitSet, New Structure("DefaultPurchaseUnit"));
				DocLineItem.ProductDescription	= ProductProperties.Description;
				DocLineItem.UnitSet				= ProductProperties.UnitSet;
				DocLineItem.Unit				= UnitSetProperties.DefaultPurchaseUnit;
			Else 
				DocLineItem.Product = Catalogs.Products.FindByCode("comment",True);
			EndIf;
			
			If ValueIsFilled(DataLine.Description) Then 
				DocLineItem.ProductDescription = DataLine.Description;
			EndIf;
			
			If ValueIsFilled(DataLine.Price) Then 
				DocLineItem.PriceUnits = DataLine.Price;
			EndIf;
			
			If ValueIsFilled(DataLine.LineQuantity) Then 
				DocLineItem.QtyUnits	= DataLine.LineQuantity;
				DocLineItem.QtyUM		= Round(Round(DocLineItem.QtyUnits, QuantityPrecision) *
	                             ?(DocLineItem.Unit.Factor > 0, DocLineItem.Unit.Factor, 1), QuantityPrecision);
			EndIf;
			
			If ValueIsFilled(DataLine.LineTotal) Then 
				DocLineItem.LineTotal = DataLine.LineTotal;
			EndIf;
			
			If ValueIsFilled(DataLine.LineProject) Then 
				DocLineItem.Project = DataLine.LineProject;
			EndIf;
			
			If ValueIsFilled(DataLine.LineClass) Then 
				DocLineItem.Class = DataLine.LineClass;
			EndIf;
			
		Except
			ErrorText = "Document Line: "+Counter+ Chars.LF+ ErrorDescription();
			Raise ErrorText;
		EndTry;
		
	EndDo;
	
	Try
		If DocObject <> Undefined Then
			// Calculate document totals.
			DocObject.DocumentTotal   = DocObject.LineItems.Total("LineTotal");
			DocObject.DocumentTotalRC = Round(DocObject.DocumentTotal * DocObject.ExchangeRate, 2);
			
			DocObject.Write(?(DocPost,DocumentWriteMode.Posting,DocumentWriteMode.Write));
		EndIf;	
	Except
		ErrorText = "Document Line: "+Counter+ Chars.LF+ ErrorDescription();
		Raise ErrorText;
	EndTry;	

	
	
EndProcedure

Procedure CreatePurchaseInvoiceCSV(Date, Date2, ItemDataSet) Export
	
	Counter = 0;
	Counter10 = 0;
	MaxCount = ItemDataSet.count();
	
	PrevNumber = Undefined;
	DocObject = Undefined;
	DocPost = False;
	
	QuantityPrecision = GeneralFunctionsReusable.DefaultQuantityPrecision();
	
	For Each DataLine In ItemDataSet Do
		
		Counter = Counter + 1;
		Progress = Int((Counter/MaxCount)*10); 
		If Counter10 <> Progress then
			Counter10 = Progress;
			LongActions.InformActionProgres(Counter10*10,"Current progress: "+(Counter10*10) +"%");
		EndIf;	
		
		Try
			If PrevNumber <> DataLine.Number  Then
				PrevNumber = DataLine.Number;
								
				// Writing previous document
				If DocObject <> Undefined Then
					
					// Calculate document totals.
					DocObject.DocumentTotal   = DocObject.LineItems.Total("LineTotal") + DocObject.Accounts.Total("Amount");
					DocObject.DocumentTotalRC = Round(DocObject.DocumentTotal * DocObject.ExchangeRate, 2);
					
					DocObject.Write(?(DocPost,DocumentWriteMode.Posting,DocumentWriteMode.Write));
				EndIf;	
				
				// First row, need to fill up document, Lines will be filled later
				ExistingDoc = Documents.PurchaseInvoice.FindByNumber(DataLine.Number,DataLine.DocDate);
				If ValueIsFilled(ExistingDoc) Then 
					DocObject = ExistingDoc.GetObject();
					DocObject.LineItems.Clear();
					DocObject.Accounts.Clear();
				Else
					DocObject = Documents.PurchaseInvoice.CreateDocument();
					DocObject.Number = DataLine.Number;
				EndIf;
				// Filling document attributes
				DocObject.Date = Date(DataLine.DocDate)+1;
				DocObject.Company = DataLine.Company;
				
				If ValueIsFilled(DataLine.Currency) Then 
					DocObject.Currency = DataLine.Currency;
				Else 
					DocObject.Currency = Constants.DefaultCurrency.Get()
				EndIf;
				
				DocObject.ExchangeRate = GeneralFunctions.GetExchangeRate(DocObject.Date, DocObject.Currency);
				
				If ValueIsFilled(DataLine.CompanyAddres) Then 
					DocObject.CompanyAddress = DataLine.CompanyAddres;
				Else 
					Query = New Query;
					Query.Text = 
					"SELECT
					|	Addresses.Ref
					|FROM
					|	Catalog.Addresses AS Addresses
					|WHERE
					|	Addresses.DefaultBilling = &DefaultBilling
					|	AND Addresses.Owner = &Owner";
					
					Query.SetParameter("DefaultBilling", True);
					Query.SetParameter("Owner", DocObject.Company);
					
					QueryResult = Query.Execute();
					
					SelectionDetailRecords = QueryResult.Select();
					While SelectionDetailRecords.Next() Do
						DocObject.CompanyAddress = SelectionDetailRecords.Ref;
					EndDo;
				EndIf;
				
				If ValueIsFilled(DataLine.APAccount) Then 
					DocObject.APAccount = DataLine.APAccount;
				Else 
					DocObject.APAccount = DocObject.Company.APAccount;
				EndIf;
				
				If ValueIsFilled(DataLine.DueDate) Then 
					DocObject.DueDate = DataLine.DueDate;
				EndIf;
				
				If ValueIsFilled(DataLine.SalesPerson) Then 
					DocObject.SalesPerson = DataLine.SalesPerson;
				EndIf;
				
				If ValueIsFilled(DataLine.Location) Then 
					DocObject.LocationActual = DataLine.Location;
				EndIf;
				
				//If ValueIsFilled(DataLine.DeliveryDate) Then 
					DocObject.DeliveryDateActual = DataLine.DeliveryDate;
				//EndIf;
				
				If ValueIsFilled(DataLine.Project) Then 
					DocObject.Project = DataLine.Project;
				EndIf;
				
				If ValueIsFilled(DataLine.Class) Then 
					DocObject.Class = DataLine.Class;
				EndIf;
				
				If ValueIsFilled(DataLine.Terms) Then 
					DocObject.Terms = DataLine.Terms;
				EndIf;
				
				If ValueIsFilled(DataLine.Memo) Then 
					DocObject.Memo = DataLine.Memo;
				EndIf;
				
				
				DocPost = (DataLine.ToPost = True);
				DocObject.LocationActual 	= GeneralFunctions.GetDefaultLocation();
				
				If TrimAll(DataLine.TableType) = "0" Then 
					Continue;
				EndIf;
				
			EndIf;
			
			If TrimAll(DataLine.TableType) = "1" Then  
				DocLineItem = DocObject.LineItems.Add();
				FillPropertyValues(DocLineItem, DocObject, "LocationActual, DeliveryDateActual, Project, Class");
				
				DocLineItem.Location = DocLineItem.LocationActual;
				DocLineItem.DeliveryDate = DocLineItem.DeliveryDateActual;
				
				If ValueIsFilled(DataLine.Product) Then 
					DocLineItem.Product = DataLine.Product;
					ProductProperties = CommonUse.GetAttributeValues(DocLineItem.Product,   New Structure("Description, UnitSet"));
					UnitSetProperties = CommonUse.GetAttributeValues(ProductProperties.UnitSet, New Structure("DefaultPurchaseUnit"));
					DocLineItem.ProductDescription	= ProductProperties.Description;
					DocLineItem.UnitSet				= ProductProperties.UnitSet;
					DocLineItem.Unit				= UnitSetProperties.DefaultPurchaseUnit;
				Else 
					DocLineItem.Product = Catalogs.Products.FindByCode("comment",True);
				EndIf;
				
				If ValueIsFilled(DataLine.Description) Then 
					DocLineItem.ProductDescription = DataLine.Description;
				EndIf;
				
				If ValueIsFilled(DataLine.Price) Then 
					DocLineItem.PriceUnits = DataLine.Price;
				EndIf;
				
				If ValueIsFilled(DataLine.LineQuantity) Then 
					DocLineItem.QtyUnits	= DataLine.LineQuantity;
					DocLineItem.QtyUM		= Round(Round(DocLineItem.QtyUnits, QuantityPrecision) *
					?(DocLineItem.Unit.Factor > 0, DocLineItem.Unit.Factor, 1), QuantityPrecision);
				EndIf;
				
				If ValueIsFilled(DataLine.LineTotal) Then 
					DocLineItem.LineTotal = DataLine.LineTotal;
				EndIf;
				
				If ValueIsFilled(DataLine.LinePO) Then 
					DocLineItem.Order = DataLine.LinePO;
				Else 
					Query = New Query;
					Query.Text = 
					"SELECT
					|	PurchaseOrderLineItems.Ref
					|FROM
					|	Document.PurchaseOrder.LineItems AS PurchaseOrderLineItems
					|WHERE
					|	PurchaseOrderLineItems.Product = &Product
					|	AND PurchaseOrderLineItems.Ref.Date >= &Date
					|	AND PurchaseOrderLineItems.Ref.Company = &Company
					|	AND PurchaseOrderLineItems.Ref.Location = &Location
					|	AND PurchaseOrderLineItems.Ref.Class = &Class
					|	AND PurchaseOrderLineItems.LineTotal = &LineTotal";
					
					Query.SetParameter("Class", DocLineItem.Class);
					Query.SetParameter("Company", DataLine.Company);
					Query.SetParameter("Date", DataLine.DocDate);
					Query.SetParameter("LineTotal", DocLineItem.LineTotal);
					Query.SetParameter("Location", DocLineItem.Location);
					Query.SetParameter("Product", DocLineItem.Product);
					
					QueryResult = Query.Execute();
					
					SelectionDetailRecords = QueryResult.Select();
					
					If SelectionDetailRecords.Count() > 1 Then
						//Error
						//WriteLogEvent("error",EventLogLevel.Error,,,"More than 1 record: "+SelectionDetailRecords.Count());
					ElsIf SelectionDetailRecords.Next() Then 
						DocLineItem.Order = SelectionDetailRecords.Ref;
					Else 
						//No PO
					EndIf;
				EndIf;
				
				If ValueIsFilled(DocLineItem.Order) Then 
					//If Not ValueIsFilled(DocObject.DeliveryDateActual) Then 
						DocObject.DeliveryDateActual = DocLineItem.Order.DeliveryDate;
					//EndIf;	
					//If Not ValueIsFilled(DocLineItem.DeliveryDateActual) Then 
						DocLineItem.DeliveryDateActual = DocLineItem.Order.DeliveryDate;
					//EndIf;	
					//If Not ValueIsFilled(DocLineItem.DeliveryDate) Then 
						DocLineItem.DeliveryDate = DocLineItem.Order.DeliveryDate;
					//EndIf;	
					
					If Not ValueIsFilled(DocObject.DueDate) Then 
						DocObject.DueDate = DataLine.DueDate;
					EndIf;	
					
					
				EndIf;	
				
				If ValueIsFilled(DataLine.LineClass) Then 
					DocLineItem.Class = DataLine.LineClass;
					
					If ValueIsFilled(DocLineItem.Order) Then 
						POObject = DocLineItem.Order.GetObject();
						SavePO = False;
						For Each ItemPOLine In POObject.LineItems Do 
							If 	ItemPOLine.Product = DocLineItem.Product And
								ItemPOLine.LineTotal = DocLineItem.LineTotal And
								ItemPOLine.ProductDescription = DocLineItem.ProductDescription And
								ItemPOLine.QtyUnits = DocLineItem.QtyUnits And
								ItemPOLine.Location = DocLineItem.Location And 
								ItemPOLine.Class.IsEmpty() Then 
								ItemPOLine.Class = DocLineItem.Class;
								SavePO = True;
								Break;
							EndIf;	
						EndDo;
						If SavePO Then 
							If Not DocObject.Ref.IsEmpty() and DocObject.Posted Then
								DocObject.Write(DocumentWriteMode.UndoPosting);
							EndIf;	
							POObject.Write(DocumentWriteMode.Posting);
						EndIf;	
					EndIf;
				EndIf;
				
			ElsIf TrimAll(DataLine.TableType) = "2" Then 
				DocLineExpenses = DocObject.Accounts.Add();
				FillPropertyValues(DocLineExpenses, DocObject, "Project, Class");
				
				If ValueIsFilled(DataLine.LineAccount) Then 
					DocLineExpenses.Account = DataLine.LineAccount;
				EndIf;
				
				If ValueIsFilled(DataLine.LineTotal) Then 
					DocLineExpenses.Amount = DataLine.LineTotal;
				EndIf;
				
				If ValueIsFilled(DataLine.LineMemo) Then 
					DocLineExpenses.Memo = DataLine.LineMemo;
				EndIf;
				
				//If ValueIsFilled(DataLine.LineProject) Then 
				//	DocLineExpenses.Project = DataLine.LineProject;
				//EndIf;
				
				If ValueIsFilled(DataLine.LineClass) Then 
					DocLineExpenses.Class = DataLine.LineClass;
				EndIf;
				
			EndIf;
			
		Except
			ErrorText = "Document Line: "+Counter+ Chars.LF+ ErrorDescription();
			Raise ErrorText;
		EndTry;
		
	EndDo;
	
	Try
		If DocObject <> Undefined Then
			// Calculate document totals.
			DocObject.DocumentTotal   = DocObject.LineItems.Total("LineTotal") + DocObject.Accounts.Total("Amount");
			DocObject.DocumentTotalRC = Round(DocObject.DocumentTotal * DocObject.ExchangeRate, 2);
			
			DocObject.Write(?(DocPost,DocumentWriteMode.Posting,DocumentWriteMode.Write));
		EndIf;	
	Except
		ErrorText = "Document Line: "+Counter+ Chars.LF+ ErrorDescription();
		Raise ErrorText;
	EndTry;	

	
	
EndProcedure

Procedure CreateItemReceiptCSV(Date, Date2, ItemDataSet) Export
	
	Counter = 0;
	Counter10 = 0;
	MaxCount = ItemDataSet.count();
	
	PrevNumber = Undefined;
	DocObject = Undefined;
	DocPost = False;
	
	QuantityPrecision = GeneralFunctionsReusable.DefaultQuantityPrecision();
	
	For Each DataLine In ItemDataSet Do
		
		Counter = Counter + 1;
		Progress = Int((Counter/MaxCount)*10); 
		If Counter10 <> Progress then
			Counter10 = Progress;
			LongActions.InformActionProgres(Counter10*10,"Current progress: "+(Counter10*10) +"%");
		EndIf;	
		
		Try
			If PrevNumber <> DataLine.Number  Then
				PrevNumber = DataLine.Number;
								
				// Writing previous document
				If DocObject <> Undefined Then
					
					// Calculate document totals.
					DocObject.DocumentTotal   = DocObject.LineItems.Total("LineTotal");
					DocObject.DocumentTotalRC = Round(DocObject.DocumentTotal * DocObject.ExchangeRate, 2);
					
					DocObject.Write(?(DocPost,DocumentWriteMode.Posting,DocumentWriteMode.Write));
				EndIf;	
				
				// First row, need to fill up document, Lines will be filled later
				ExistingDoc = Documents.ItemReceipt.FindByNumber(DataLine.Number,DataLine.DocDate);
				
				If ValueIsFilled(ExistingDoc) Then 
					DocObject = ExistingDoc.GetObject();
					DocObject.LineItems.Clear();
				Else
					DocObject = Documents.ItemReceipt.CreateDocument();
					DocObject.Number = DataLine.Number;
				EndIf;
				
								
				// Filling document attributes
				DocObject.Date = Date(DataLine.DocDate)+1;
				DocObject.Company = DataLine.Company;
				
				If ValueIsFilled(DataLine.Currency) Then 
					DocObject.Currency = DataLine.Currency;
				Else 
					DocObject.Currency = Constants.DefaultCurrency.Get()
				EndIf;
				
				DocObject.ExchangeRate = GeneralFunctions.GetExchangeRate(DocObject.Date, DocObject.Currency);
				
				If ValueIsFilled(DataLine.CompanyAddres) Then 
					DocObject.CompanyAddress = DataLine.CompanyAddres;
				Else 
					Query = New Query;
					Query.Text = 
					"SELECT
					|	Addresses.Ref
					|FROM
					|	Catalog.Addresses AS Addresses
					|WHERE
					|	Addresses.DefaultBilling = &DefaultBilling
					|	AND Addresses.Owner = &Owner";
					
					Query.SetParameter("DefaultBilling", True);
					Query.SetParameter("Owner", DocObject.Company);
					
					QueryResult = Query.Execute();
					
					SelectionDetailRecords = QueryResult.Select();
					While SelectionDetailRecords.Next() Do
						DocObject.CompanyAddress = SelectionDetailRecords.Ref;
					EndDo;
				EndIf;
				
				If ValueIsFilled(DataLine.DueDate) Then 
					DocObject.DueDate = DataLine.DueDate;
				EndIf;
				
				If ValueIsFilled(DataLine.Location) Then 
					DocObject.LocationActual = DataLine.Location;
				EndIf;
				
				//If ValueIsFilled(DataLine.DeliveryDate) Then 
					DocObject.DeliveryDateActual = DataLine.DeliveryDate;
				//EndIf;
				
				If ValueIsFilled(DataLine.Project) Then 
					DocObject.Project = DataLine.Project;
				EndIf;
				
				If ValueIsFilled(DataLine.Class) Then 
					DocObject.Class = DataLine.Class;
				EndIf;
				
				If ValueIsFilled(DataLine.Memo) Then 
					DocObject.Memo = DataLine.Memo;
				EndIf;
				
				DocPost = (DataLine.ToPost = True);
				
				DocObject.Location 	= GeneralFunctions.GetDefaultLocation();
				
			EndIf;
			
			DocLineItem = DocObject.LineItems.Add();
			FillPropertyValues(DocLineItem, DocObject, "Location, DeliveryDate, Project, Class");
			
			DocLineItem.LocationOrder = DocLineItem.Location;
			DocLineItem.DeliveryDateOrder = DocLineItem.DeliveryDate;
			
			If ValueIsFilled(DataLine.Product) Then 
				DocLineItem.Product = DataLine.Product;
				ProductProperties = CommonUse.GetAttributeValues(DocLineItem.Product,   New Structure("Description, UnitSet"));
				UnitSetProperties = CommonUse.GetAttributeValues(ProductProperties.UnitSet, New Structure("DefaultPurchaseUnit"));
				DocLineItem.ProductDescription	= ProductProperties.Description;
				DocLineItem.UnitSet				= ProductProperties.UnitSet;
				DocLineItem.Unit				= UnitSetProperties.DefaultPurchaseUnit;
				If ValueIsFilled(DataLine.UoM) Then 
					DocLineItem.Unit = DataLine.UoM;
				EndIf;	
			Else 
				DocLineItem.Product = Catalogs.Products.FindByCode("comment",True);
			EndIf;
			
			If ValueIsFilled(DataLine.Description) Then 
				DocLineItem.ProductDescription = DataLine.Description;
			EndIf;
			
			If ValueIsFilled(DataLine.Price) Then 
				DocLineItem.PriceUnits = DataLine.Price;
			EndIf;
			
			If ValueIsFilled(DataLine.LineQuantity) Then 
				DocLineItem.QtyUnits	= DataLine.LineQuantity;
				DocLineItem.QtyUM		= Round(Round(DocLineItem.QtyUnits, QuantityPrecision) *
				?(DocLineItem.Unit.Factor > 0, DocLineItem.Unit.Factor, 1), QuantityPrecision);
			EndIf;
			
			If ValueIsFilled(DataLine.LineTotal) Then 
				DocLineItem.LineTotal = DataLine.LineTotal;
			EndIf;
			
			If ValueIsFilled(DataLine.LinePO) Then 
					DocLineItem.Order = DataLine.LinePO;
				Else 
					Query = New Query;
					Query.Text = 
					"SELECT
					|	PurchaseOrderLineItems.Ref
					|FROM
					|	Document.PurchaseOrder.LineItems AS PurchaseOrderLineItems
					|WHERE
					|	PurchaseOrderLineItems.Product = &Product
					|	AND PurchaseOrderLineItems.Ref.Date >= &Date
					|	AND PurchaseOrderLineItems.Ref.Company = &Company
					|	AND PurchaseOrderLineItems.Ref.Location = &Location
					|	AND PurchaseOrderLineItems.Ref.Class = &Class
					|	AND PurchaseOrderLineItems.LineTotal = &LineTotal";
					
					Query.SetParameter("Class", DocLineItem.Class);
					Query.SetParameter("Company", DataLine.Company);
					Query.SetParameter("Date", DataLine.DocDate);
					Query.SetParameter("LineTotal", DocLineItem.LineTotal);
					Query.SetParameter("Location", DocLineItem.Location);
					Query.SetParameter("Product", DocLineItem.Product);
					
					QueryResult = Query.Execute();
					
					SelectionDetailRecords = QueryResult.Select();
					
					If SelectionDetailRecords.Count() > 1 Then
						//Error
						//WriteLogEvent("error",EventLogLevel.Error,,,"More than 1 record: "+SelectionDetailRecords.Count());
					ElsIf SelectionDetailRecords.Next() Then 
						DocLineItem.Order = SelectionDetailRecords.Ref;
					Else 
						//No PO
					EndIf;
				EndIf;
			
			If ValueIsFilled(DataLine.LineClass) Then 
				DocLineItem.Class = DataLine.LineClass;
			EndIf;
			
		Except
			ErrorText = "Document Line: "+Counter+ Chars.LF+ ErrorDescription();
			Raise ErrorText;
		EndTry;
		
	EndDo;
	
	Try
		If DocObject <> Undefined Then
			// Calculate document totals.
			DocObject.DocumentTotal   = DocObject.LineItems.Total("LineTotal");
			DocObject.DocumentTotalRC = Round(DocObject.DocumentTotal * DocObject.ExchangeRate, 2);
			
			DocObject.Write(?(DocPost,DocumentWriteMode.Posting,DocumentWriteMode.Write));
		EndIf;	
	Except
		ErrorText = "Document Line: "+Counter+ Chars.LF+ ErrorDescription();
		Raise ErrorText;
	EndTry;	

	
	
EndProcedure

Procedure CreateItemCSV(Date, Date2, ItemDataSet) Export
	
	
	// add transactions 1-500
	Counter = 0;
	Counter10 = 0;
	MaxCount = ItemDataSet.count();
	For Each DataLine In ItemDataSet Do
		
		Counter = Counter + 1;
		Progress = Int((Counter/MaxCount)*10); 
		If Counter10 <> Progress then
			Counter10 = Progress;
			LongActions.InformActionProgres(Counter10*10,"Current progress: "+(Counter10*10) +"%");
		EndIf;	
		
		Try
			UpdatedProduct = DataLine.ProductUpdate;
			If ValueIsFilled(UpdatedProduct) Then 
				NewProduct = UpdatedProduct.GetObject();
			Else	
				NewProduct = Catalogs.Products.CreateItem();
			EndIf;	
			NewProduct.Type = DataLine.ProductType;
			NewProduct.Code = DataLine.ProductCode;
			If ValueIsFilled(DataLine.ProductDescription) Then
				NewProduct.Description = DataLine.ProductDescription;
			Else
				NewProduct.Description = DataLine.ProductCode;
			EndIf;	
			
			If ValueIsFilled(DataLine.PurchaseDescription) Then
				NewProduct.vendor_description = DataLine.PurchaseDescription;
			//Else
			//	NewProduct.Description = DataLine.ProductCode;
			EndIf;	
			
			NewProduct.IncomeAccount = DataLine.ProductIncomeAcct;
			NewProduct.InventoryOrExpenseAccount = DataLine.ProductInvOrExpenseAcct;
			NewProduct.COGSAccount = DataLine.ProductCOGSAcct;
			//NewProduct.PurchaseVATCode = Constants.DefaultPurchaseVAT.Get();
			//NewProduct.SalesVATCode = Constants.DefaultSalesVAT.Get();
			//NewProduct.api_code = GeneralFunctions.NextProductNumber();
			
			NewProduct.UnitSet = Constants.DefaultUoMSet.Get();
			
			NewProduct.Category = DataLine.ProductCategory;
			NewProduct.Price = DataLine.ProductPrice;
			NewProduct.Cost = DataLine.ProductCost;
			
			NewProduct.vendor_code = DataLine.ProductVendorCode;
			NewProduct.PreferredVendor = DataLine.ProductPreferedVendor;
			
			If ValueIsFilled(DataLine.ProductParent) Then 
				NewProduct.Parent = DataLine.ProductParent;
			Else 
				NewProduct.Parent = Catalogs.Products.EmptyRef();
			EndIf;	
			
			If DataLine.ProductCF1String <> "" Then 
				NewProduct.CF1String = DataLine.ProductCF1String;
			EndIf;
			NewProduct.CF1Num = DataLine.ProductCF1Num;
			
			If DataLine.ProductCF2String <> "" Then 
				NewProduct.CF2String = DataLine.ProductCF2String;
			EndIf;
			NewProduct.CF2Num = DataLine.ProductCF2Num;
			
			If DataLine.ProductCF3String <> "" Then 
				NewProduct.CF3String = DataLine.ProductCF3String;
			EndIf;
			NewProduct.CF3Num = DataLine.ProductCF3Num;
			
			If DataLine.ProductCF4String <> "" Then 
				NewProduct.CF4String = DataLine.ProductCF4String;
			EndIf;
			NewProduct.CF4Num = DataLine.ProductCF4Num;
			
			If DataLine.ProductCF5String <> "" Then 
				NewProduct.CF5String = DataLine.ProductCF5String;
			EndIf;
			NewProduct.CF5Num = DataLine.ProductCF5Num;
			
			If NewProduct.Type = Enums.InventoryTypes.Inventory Then
				NewProduct.CostingMethod = Enums.InventoryCosting.WeightedAverage;
			EndIf;
			NewProduct.Taxable = DataLine.ProductTaxable;
			NewProduct.Write();
			
			If DataLine.ProductPrice <> 0 Then
				RecordSet = InformationRegisters.PriceList.CreateRecordSet();
				RecordSet.Filter.Product.Set(NewProduct.Ref);
				RecordSet.Filter.Period.Set(Date);
				NewRecord = RecordSet.Add();
				NewRecord.Period = Date;
				NewRecord.Product = NewProduct.Ref;
				NewRecord.Price = DataLine.ProductPrice;
				RecordSet.Write();
			EndIf;
			
			If DataLine.ProductQty <> 0 Then
				IBB = Documents.ItemAdjustment.CreateDocument();
				IBB.Product = NewProduct.Ref;
				IBB.Location = Catalogs.Locations.MainWarehouse;
				IBB.Quantity = DataLine.ProductQty;
				IBB.Value = Dataline.ProductValue;
				IBB.Date = Date2;
				IBB.Write(DocumentWriteMode.Posting);
			EndIf;
			
			
			
		Except
			ErrorText = "Document Line: "+Counter+ Chars.LF+ ErrorDescription();
			Raise ErrorText;
		EndTry;

		
	EndDo;

	
EndProcedure

Procedure CreateBillPaymentCSV(Date, Date2, ItemDataSet) Export
	
	Counter = 0;
	Counter10 = 0;
	MaxCount = ItemDataSet.count();
	
	PrevNumber = Undefined;
	DocObject = Undefined;
	DocPost = False;
	
	QuantityPrecision = GeneralFunctionsReusable.DefaultQuantityPrecision();
	DefaultCurrency = GeneralFunctionsReusable.DefaultCurrency();
	
	For Each DataLine In ItemDataSet Do
		
		Counter = Counter + 1;
		Progress = Int((Counter/MaxCount)*10); 
		If Counter10 <> Progress then
			Counter10 = Progress;
			LongActions.InformActionProgres(Counter10*10,"Current progress: "+(Counter10*10) +"%");
		EndIf;	
		
		Try
			If PrevNumber <> DataLine.Number  Then
				PrevNumber = DataLine.Number;
								
				// Writing previous document
				If DocObject <> Undefined Then
					
					// Calculate document totals.
					DocObject.DocumentTotal   = DocObject.LineItems.Total("Payment");
					
					DocumentTotalRC = 0;
					For Each Row In DocObject.LineItems Do
						If Row.Currency = DefaultCurrency Then
							DocumentTotalRC = DocumentTotalRC + Row.Payment;
						Else
							ExchangeRate = GeneralFunctions.GetExchangeRate(DocObject.Date, Row.Currency);
							DocumentTotalRC = DocumentTotalRC + Round(Row.Payment * ExchangeRate, 2);
						EndIf;
					EndDo;

					
					
					DocObject.DocumentTotalRC = DocumentTotalRC;
					
					DocObject.Write(?(DocPost,DocumentWriteMode.Posting,DocumentWriteMode.Write));
				EndIf;	
				
				// First row, need to fill up document, Lines will be filled later
				ExistingDoc = Documents.InvoicePayment.FindByNumber(DataLine.Number,DataLine.DocDate);
				If ValueIsFilled(ExistingDoc) Then 
					DocObject = ExistingDoc.GetObject();
					DocObject.LineItems.Clear();
				Else
					DocObject = Documents.InvoicePayment.CreateDocument();
					DocObject.Number = DataLine.Number;
				EndIf;
				// Filling document attributes
				
				DocObject.Date = Date(DataLine.DocDate)+1;
				DocObject.Company = DataLine.Company;
				
				If ValueIsFilled(DataLine.Currency) Then 
					DocObject.Currency = DataLine.Currency;
				Else 
					DocObject.Currency = Constants.DefaultCurrency.Get()
				EndIf;
				
				If ValueIsFilled(DataLine.BankAccount) Then 
					DocObject.BankAccount = DataLine.BankAccount;
				Else 
					DocObject.BankAccount = Constants.BankAccount.Get();
				EndIf;
				
				If ValueIsFilled(DataLine.PaymentMethod) Then 
					DocObject.PaymentMethod = DataLine.PaymentMethod;
				Else 
					DocObject.PaymentMethod = Catalogs.PaymentMethods.Check;
				EndIf;
				
				DocObject.PhysicalCheckNum = DocObject.Number;
				
				
				If ValueIsFilled(DataLine.Memo) Then 
					DocObject.Memo = DataLine.Memo;
				EndIf;
				
				
				DocPost = (DataLine.ToPost = True);
				
			EndIf;
			
			DocLineItem = DocObject.LineItems.Add();
			
			If ValueIsFilled(DataLine.Bill) Then 
				DocLineItem.Document = DataLine.Bill;
			EndIf;
			
			If ValueIsFilled(DataLine.Currency) Then 
				DocLineItem.Currency = DataLine.Currency;
			Else 
				DocLineItem.Currency = DocObject.Currency;
			EndIf;

			
			If ValueIsFilled(DataLine.Payment) Then 
				DocLineItem.Payment = DataLine.Payment;
			EndIf;
			
			//If ValueIsFilled(DataLine.Check) Then 
				DocLineItem.Check = True;
			//EndIf;
			
		Except
			ErrorText = "Document Line: "+Counter+ Chars.LF+ ErrorDescription();
			Raise ErrorText;
		EndTry;
		
	EndDo;
	
	Try
		If DocObject <> Undefined Then
			// Calculate document totals.
			DocObject.DocumentTotal   = DocObject.LineItems.Total("Payment");
			
			DocumentTotalRC = 0;
			For Each Row In DocObject.LineItems Do
				If Row.Currency = DefaultCurrency Then
					DocumentTotalRC = DocumentTotalRC + Row.Payment;
				Else
					ExchangeRate = GeneralFunctions.GetExchangeRate(DocObject.Date, Row.Currency);
					DocumentTotalRC = DocumentTotalRC + Round(Row.Payment * ExchangeRate, 2);
				EndIf;
			EndDo;
			DocObject.DocumentTotalRC = DocumentTotalRC;
			
			DocObject.Write(?(DocPost,DocumentWriteMode.Posting,DocumentWriteMode.Write));
		EndIf;	
	Except
		ErrorText = "Document Line: "+Counter+ Chars.LF+ ErrorDescription();
		Raise ErrorText;
	EndTry;	

	
	
EndProcedure

Procedure CreateSalesInvoiceCSV(Date, Date2, ItemDataSet) Export
	
	Counter = 0;
	Counter10 = 0;
	MaxCount = ItemDataSet.count();
	
	PrevNumber = Undefined;
	DocObject = Undefined;
	DocPost = False;
	
	QuantityPrecision = GeneralFunctionsReusable.DefaultQuantityPrecision();
	
	For Each DataLine In ItemDataSet Do
		
		Counter = Counter + 1;
		Progress = Int((Counter/MaxCount)*10); 
		If Counter10 <> Progress then
			Counter10 = Progress;
			LongActions.InformActionProgres(Counter10*10,"Current progress: "+(Counter10*10) +"%");
		EndIf;	
		
		Try
			If PrevNumber <> DataLine.Number  Then
				PrevNumber = DataLine.Number;
								
				// Writing previous document
				If DocObject <> Undefined Then
					
					SalesInvoiceRecalculateTotals(DocObject);
					
					DocObject.Write(?(DocPost,DocumentWriteMode.Posting,DocumentWriteMode.Write));
				EndIf;	
				
				// First row, need to fill up document, Lines will be filled later
				ExistingDoc = Documents.SalesInvoice.FindByNumber(DataLine.Number,DataLine.DocDate);
				If ValueIsFilled(ExistingDoc) Then 
					DocObject = ExistingDoc.GetObject();
					DocObject.LineItems.Clear();
					DocObject.SerialNumbers.Clear();
					DocObject.SalesTaxAcrossAgencies.Clear();
				Else
					DocObject = Documents.SalesInvoice.CreateDocument();
					DocObject.Number = DataLine.Number;
				EndIf;
				// Filling document attributes
				DocObject.Date = Date(DataLine.DocDate)+1;
				
				If ValueIsFilled(DataLine.RefNum) Then 
					DocObject.RefNum = DataLine.RefNum;
				EndIf;
				
				DocObject.Company = DataLine.Company;
				
				SalesInvoiceCompanyOnChangeAtServer(DocObject);
				
				If ValueIsFilled(DataLine.Currency) Then 
					DocObject.Currency = DataLine.Currency;
					DocObject.ExchangeRate = GeneralFunctions.GetExchangeRate(DocObject.Date, DocObject.Currency);
				EndIf;
				
				If ValueIsFilled(DataLine.ARAccount) Then 
					DocObject.ARAccount = DataLine.ARAccount;
				EndIf;
				
				If ValueIsFilled(DataLine.DueDate) Then 
					DocObject.DueDate = DataLine.DueDate;
				EndIf;
				
				If ValueIsFilled(DataLine.SalesPerson) Then 
					DocObject.SalesPerson = DataLine.SalesPerson;
				EndIf;
				
				If ValueIsFilled(DataLine.Location) Then 
					DocObject.LocationActual 	= DataLine.Location;
				Else 	
					DocObject.LocationActual 	= GeneralFunctions.GetDefaultLocation();
				EndIf;
				
				If ValueIsFilled(DataLine.DeliveryDate) Then 
					DocObject.DeliveryDateActual = DataLine.DeliveryDate;
				EndIf;
				
				If ValueIsFilled(DataLine.Project) Then 
					DocObject.Project = DataLine.Project;
				EndIf;
				
				If ValueIsFilled(DataLine.Class) Then 
					DocObject.Class = DataLine.Class;
				EndIf;
				
				If ValueIsFilled(DataLine.Terms) Then 
					DocObject.Terms = DataLine.Terms;
				EndIf;
				
				If ValueIsFilled(DataLine.Memo) Then 
					DocObject.Memo = DataLine.Memo;
				EndIf;
				
				DocPost = (DataLine.ToPost = True);
				
			EndIf;
			
			DocLineItem = DocObject.LineItems.Add();
			FillPropertyValues(DocLineItem, DocObject, "LocationActual, DeliveryDateActual, Project, Class");
			
			//DocLineItem.Location = DocLineItem.LocationActual;
			//DocLineItem.DeliveryDate = DocLineItem.DeliveryDateActual;
			
			If ValueIsFilled(DataLine.Product) Then 
				DocLineItem.Product = DataLine.Product;
				TableSectionRow = New Structure("LineNumber, LineID, Product, ProductDescription, UseLotsSerials, LotOwner, Lot, SerialNumbers, UnitSet, QtyUnits, Unit, QtyUM, UM, Ordered, Backorder, Shipped, Invoiced, PriceUnits, LineTotal, Taxable, TaxableAmount, Order, Shipment, Location, LocationActual, DeliveryDate, DeliveryDateActual, Project, Class, AvataxTaxCode, DiscountIsTaxable");
				FillPropertyValues(TableSectionRow, DocLineItem);
				
				SalesInvoiceLineItemsProductOnChangeAtServer(TableSectionRow,DocObject);
				FillPropertyValues(DocLineItem, TableSectionRow);
			Else 
				DocLineItem.Product = Catalogs.Products.FindByCode("comment",True);
			EndIf;
			
			DocLineItem.Location = DocLineItem.LocationActual;
			DocLineItem.DeliveryDate = DocLineItem.DeliveryDateActual;
			                                                          			
			If ValueIsFilled(DataLine.Taxable) Then 
				DocLineItem.Taxable = DataLine.Taxable;
			EndIf;
			
			If ValueIsFilled(DataLine.TaxableAmount) Then 
				DocLineItem.TaxableAmount = DataLine.TaxableAmount;
			EndIf;
			
			If ValueIsFilled(DataLine.Description) Then 
				DocLineItem.ProductDescription = DataLine.Description;
			EndIf;
			
			If ValueIsFilled(DataLine.Price) Then 
				DocLineItem.PriceUnits = DataLine.Price;
			EndIf;
			
			If ValueIsFilled(DataLine.LineQuantity) Then 
				DocLineItem.QtyUnits	= DataLine.LineQuantity;
				DocLineItem.QtyUM		= Round(Round(DocLineItem.QtyUnits, QuantityPrecision) *
				?(DocLineItem.Unit.Factor > 0, DocLineItem.Unit.Factor, 1), QuantityPrecision);
			EndIf;
			
			If ValueIsFilled(DataLine.LineTotal) Then 
				DocLineItem.LineTotal = DataLine.LineTotal;
			EndIf;
			
			If ValueIsFilled(DataLine.Order) Then 
				DocLineItem.Order = DataLine.Order;
			EndIf;
			
			If ValueIsFilled(DataLine.LineClass) Then 
				DocLineItem.Class = DataLine.LineClass;
			EndIf;
			
			If ValueIsFilled(DataLine.Taxable) Then 
				DocLineItem.Taxable = DataLine.Taxable;
				SalesInvoiceLineItemsTaxableOnChangeAtServer(DocLineItem,DocObject);
			EndIf;
			
			
		Except
			ErrorText = "Document Line: "+Counter+ Chars.LF+ ErrorDescription();
			Raise ErrorText;
		EndTry;
		
	EndDo;
	
	Try
		If DocObject <> Undefined Then
			SalesInvoiceRecalculateTotals(DocObject);
			DocObject.Write(?(DocPost,DocumentWriteMode.Posting,DocumentWriteMode.Write));
		EndIf;	
	Except
		ErrorText = "Document Line: "+Counter+ Chars.LF+ ErrorDescription();
		Raise ErrorText;
	EndTry;	

	
	
EndProcedure

Procedure CreateCashReceipCSV(Date, Date2, ItemDataSet) Export
	
	Counter = 0;
	Counter10 = 0;
	MaxCount = ItemDataSet.count();
	
	PrevNumber = Undefined;
	DocObject = Undefined;
	DocPost = False;
	
	QuantityPrecision = GeneralFunctionsReusable.DefaultQuantityPrecision();
	
	For Each DataLine In ItemDataSet Do
		
		Counter = Counter + 1;
		Progress = Int((Counter/MaxCount)*10); 
		If Counter10 <> Progress then
			Counter10 = Progress;
			LongActions.InformActionProgres(Counter10*10,"Current progress: "+(Counter10*10) +"%");
		EndIf;	
		
		Try
			If PrevNumber <> DataLine.Number  Then
				PrevNumber = DataLine.Number;
								
				// Writing previous document
				If DocObject <> Undefined Then
					
					//DocumentTotal and DocumentTotalRC will calculater during posting
					DocObject.Write(?(DocPost,DocumentWriteMode.Posting,DocumentWriteMode.Write));
				EndIf;	
				
				// First row, need to fill up document, Lines will be filled later
				ExistingDoc = Documents.CashReceipt.FindByNumber(DataLine.Number,DataLine.DocDate);
				If ValueIsFilled(ExistingDoc) Then 
					DocObject = ExistingDoc.GetObject();
					DocObject.LineItems.Clear();
					DocObject.CreditMemos.Clear();
					DocObject.CashPayment = 0;
				Else
					DocObject = Documents.CashReceipt.CreateDocument();
					DocObject.Number = DataLine.Number;
				EndIf;
				// Filling document attributes
				DocObject.Date = Date(DataLine.DocDate)+1;
				DocObject.Company = DataLine.Company;
				
				CashReceiptCompanyOnChange(DocObject);
				
				If ValueIsFilled(DataLine.RefNum) Then 
					DocObject.RefNum = DataLine.RefNum;
				EndIf;
				
				If ValueIsFilled(DataLine.Currency) Then 
					DocObject.Currency = DataLine.Currency;
					DocObject.ExchangeRate = GeneralFunctions.GetExchangeRate(DocObject.Date, DocObject.Currency);
				EndIf;
				
				If ValueIsFilled(DataLine.ARAccount) Then 
					DocObject.ARAccount = DataLine.ARAccount;
				EndIf;
				
				If ValueIsFilled(DataLine.BankAccount) Then 
					DocObject.BankAccount = DataLine.BankAccount;
				EndIf;
				
				If ValueIsFilled(DataLine.Memo) Then 
					DocObject.Memo = DataLine.Memo;
				EndIf;
				
				If ValueIsFilled(DataLine.PaymentMethod) Then 
					DocObject.PaymentMethod = DataLine.PaymentMethod;
				EndIf;
				
				If ValueIsFilled(DataLine.DepositType) Then 
					DocObject.DepositType = DataLine.DepositType;
				EndIf;
				
				If ValueIsFilled(DataLine.SalesOrder) Then 
					DocObject.SalesOrder = DataLine.SalesOrder;
				EndIf;
				
				DocPost = (DataLine.ToPost = True);
				
			EndIf;
			If DataLine.TableType = "1" then
				DocLineItem = DocObject.LineItems.Add();
				
				If ValueIsFilled(DataLine.DocumentNum) Then 
					If DataLine.DocumentType = "Invoice" Then 
						DocLineItem.Document = Documents.SalesInvoice.FindByNumber(DataLine.DocumentNum);
					Else 
						DocLineItem.Document = Documents.PurchaseReturn.FindByNumber(DataLine.DocumentNum);
					EndIf;	
				EndIf;
				
			Else 
				DocLineItem = DocObject.CreditMemos.Add();
				
				If ValueIsFilled(DataLine.DocumentNum) Then 
					If Find(DataLine.DocumentType,"Receipt") > 0 Then 
						DocLineItem.Document = Documents.CashReceipt.FindByNumber(DataLine.DocumentNum);
					Else 
						DocLineItem.Document = Documents.SalesReturn.FindByNumber(DataLine.DocumentNum);
					EndIf;	
				EndIf;
				
			EndIf;	
				
			DocLineItem.Payment = DataLine.Payment;
			DocObject.CashPayment = DocObject.CashPayment + DocLineItem.Payment;
			
		Except
			ErrorText = "Document Line: "+Counter+ Chars.LF+ ErrorDescription();
			Raise ErrorText;
		EndTry;
		
	EndDo;
	
	Try
		If DocObject <> Undefined Then
			//DocumentTotal and DocumentTotalRC will calculater during posting
			DocObject.Write(?(DocPost,DocumentWriteMode.Posting,DocumentWriteMode.Write));
		EndIf;	
	Except
		ErrorText = "Document Line: "+Counter+ Chars.LF+ ErrorDescription();
		Raise ErrorText;
	EndTry;	

	
	
EndProcedure

Procedure CreateSalesOrderCSV(Date, Date2, ItemDataSet) Export
	
	Counter = 0;
	Counter10 = 0;
	MaxCount = ItemDataSet.count();
	
	PrevNumber = Undefined;
	DocObject = Undefined;
	DocPost = False;
	
	QuantityPrecision = GeneralFunctionsReusable.DefaultQuantityPrecision();
	
	For Each DataLine In ItemDataSet Do
		
		Counter = Counter + 1;
		Progress = Int((Counter/MaxCount)*10); 
		If Counter10 <> Progress then
			Counter10 = Progress;
			LongActions.InformActionProgres(Counter10*10,"Current progress: "+(Counter10*10) +"%");
		EndIf;	
		
		Try
			If PrevNumber <> DataLine.Number  Then
				PrevNumber = DataLine.Number;
								
				// Writing previous document
				If DocObject <> Undefined Then
					
					SalesOrderRecalculateTotals(DocObject);
					
					DocObject.Write(?(DocPost,DocumentWriteMode.Posting,DocumentWriteMode.Write));
				EndIf;	
				
				// First row, need to fill up document, Lines will be filled later
				ExistingDoc = Documents.SalesOrder.FindByNumber(DataLine.Number,DataLine.DocDate);
				If ValueIsFilled(ExistingDoc) Then 
					DocObject = ExistingDoc.GetObject();
					DocObject.LineItems.Clear();
					DocObject.SalesTaxAcrossAgencies.Clear();
				Else
					DocObject = Documents.SalesOrder.CreateDocument();
					DocObject.Number = DataLine.Number;
				EndIf;
				// Filling document attributes
				DocObject.Date = Date(DataLine.DocDate)+1;
				DocObject.Company = DataLine.Company;
				
				SalesOrderCompanyOnChangeAtServer(DocObject);
				
				//If ValueIsFilled(DataLine.Currency) Then 
				//	DocObject.Currency = DataLine.Currency;
				//	DocObject.ExchangeRate = GeneralFunctions.GetExchangeRate(DocObject.Date, DocObject.Currency);
				//EndIf;
				
				If ValueIsFilled(DataLine.RefNum) Then 
					DocObject.RefNum = DataLine.RefNum;
				EndIf;
				
				If ValueIsFilled(DataLine.SalesPerson) Then 
					DocObject.SalesPerson = DataLine.SalesPerson;
				EndIf;
				
				DocObject.Location 	= GeneralFunctions.GetDefaultLocation();
				
				If ValueIsFilled(DataLine.DeliveryDate) Then 
					DocObject.DeliveryDateActual = DataLine.DeliveryDate;
				EndIf;
				
				If ValueIsFilled(DataLine.Project) Then 
					DocObject.Project = DataLine.Project;
				EndIf;
				
				If ValueIsFilled(DataLine.Class) Then 
					DocObject.Class = DataLine.Class;
				EndIf;
				
				If ValueIsFilled(DataLine.Memo) Then 
					DocObject.Memo = DataLine.Memo;
				EndIf;
				
				DocPost = (DataLine.ToPost = True);
				
			EndIf;
			
			DocLineItem = DocObject.LineItems.Add();
			FillPropertyValues(DocLineItem, DocObject, "Location, DeliveryDate, Project, Class");
			
			//DocLineItem.Location = DocLineItem.LocationActual;
			//DocLineItem.DeliveryDate = DocLineItem.DeliveryDateActual;
			
			If ValueIsFilled(DataLine.Product) Then 
				DocLineItem.Product = DataLine.Product;
				
				DocLineItem.Product = DataLine.Product;
				ProductProperties = CommonUse.GetAttributeValues(DocLineItem.Product,   New Structure("Description, UnitSet"));
				UnitSetProperties = CommonUse.GetAttributeValues(ProductProperties.UnitSet, New Structure("DefaultPurchaseUnit"));
				DocLineItem.ProductDescription	= ProductProperties.Description;
				DocLineItem.UnitSet				= ProductProperties.UnitSet;
				DocLineItem.Unit				= UnitSetProperties.DefaultPurchaseUnit;
					
				//TableSectionRow = New Structure("LineNumber, LineID, Product, ProductDescription, UseLotsSerials, LotOwner, Lot, SerialNumbers, UnitSet, QtyUnits, Unit, QtyUM, UM, Ordered, Backorder, Shipped, Invoiced, PriceUnits, LineTotal, Taxable, TaxableAmount, Order, Shipment, Location, LocationActual, DeliveryDate, DeliveryDateActual, Project, Class, AvataxTaxCode, DiscountIsTaxable");
				//FillPropertyValues(TableSectionRow, DocLineItem);
				//
				//SalesInvoiceLineItemsProductOnChangeAtServer(TableSectionRow,DocObject);
				//FillPropertyValues(DocLineItem, TableSectionRow);
			Else 
				DocLineItem.Product = Catalogs.Products.FindByCode("comment",True);
			EndIf;
						
			If ValueIsFilled(DataLine.Description) Then 
				DocLineItem.ProductDescription = DataLine.Description;
			EndIf;
			
			If ValueIsFilled(DataLine.Price) Then 
				DocLineItem.PriceUnits = DataLine.Price;
			EndIf;
			
			If ValueIsFilled(DataLine.LineQuantity) Then 
				DocLineItem.QtyUnits	= DataLine.LineQuantity;
				DocLineItem.QtyUM		= Round(Round(DocLineItem.QtyUnits, QuantityPrecision) *
				?(DocLineItem.Unit.Factor > 0, DocLineItem.Unit.Factor, 1), QuantityPrecision);
			EndIf;
			
			If ValueIsFilled(DataLine.LineTotal) Then 
				DocLineItem.LineTotal = DataLine.LineTotal;
			EndIf;
			
			If ValueIsFilled(DataLine.LineClass) Then 
				DocLineItem.Class = DataLine.LineClass;
			EndIf;
			
			If ValueIsFilled(DataLine.Taxable) Then 
				DocLineItem.Taxable = DataLine.Taxable;
				//SalesInvoiceLineItemsTaxableOnChangeAtServer(DocLineItem,DocObject);
			EndIf;
			
			
		Except
			ErrorText = "Document Line: "+Counter+ Chars.LF+ ErrorDescription();
			Raise ErrorText;
		EndTry;
		
	EndDo;
	
	Try
		If DocObject <> Undefined Then
			SalesOrderRecalculateTotals(DocObject);
			DocObject.Write(?(DocPost,DocumentWriteMode.Posting,DocumentWriteMode.Write));
		EndIf;	
	Except
		ErrorText = "Document Line: "+Counter+ Chars.LF+ ErrorDescription();
		Raise ErrorText;
	EndTry;	

	
	
EndProcedure

Procedure CreateCreditMemoCSV(Date, Date2, ItemDataSet) Export
	
	Counter = 0;
	Counter10 = 0;
	MaxCount = ItemDataSet.count();
	
	PrevNumber = Undefined;
	DocObject = Undefined;
	DocPost = False;
	
	QuantityPrecision = GeneralFunctionsReusable.DefaultQuantityPrecision();
	
	For Each DataLine In ItemDataSet Do
		
		Counter = Counter + 1;
		Progress = Int((Counter/MaxCount)*10); 
		If Counter10 <> Progress then
			Counter10 = Progress;
			LongActions.InformActionProgres(Counter10*10,"Current progress: "+(Counter10*10) +"%");
		EndIf;	
		
		Try
			If PrevNumber <> DataLine.Number  Then
				PrevNumber = DataLine.Number;
								
				// Writing previous document
				If DocObject <> Undefined Then
					
					SalesReturnRecalculateTotals(DocObject);
					DocObject.Write(?(DocPost,DocumentWriteMode.Posting,DocumentWriteMode.Write));
					
				EndIf;	
				
				// First row, need to fill up document, Lines will be filled later
				ExistingDoc = Documents.SalesReturn.FindByNumber(DataLine.Number,DataLine.DocDate);
				If ValueIsFilled(ExistingDoc) Then 
					DocObject = ExistingDoc.GetObject();
					DocObject.LineItems.Clear();
					DocObject.SalesTaxAcrossAgencies.Clear();
				Else
					DocObject = Documents.SalesReturn.CreateDocument();
					DocObject.Number = DataLine.Number;
				EndIf;
				// Filling document attributes
				DocObject.Date = Date(DataLine.DocDate)+1;
				
				If ValueIsFilled(DataLine.RefNum) Then 
					DocObject.RefNum = DataLine.RefNum;
				EndIf;
				
				If ValueIsFilled(DataLine.ParentInvoice) Then 
					DocObject.ParentDocument = DataLine.ParentInvoice;
				EndIf;
				
				If ValueIsFilled(DocObject.ParentDocument) Then 
					DocObject.ShipFrom = DocObject.ParentDocument.ShipTo;
				Else 	
				EndIf;	
				
				//If ValueIsFilled(DocObject.ParentDocument) Then 
				//	DocObject.ShipFrom = DocObject.ParentDocument.ShipTo;
				//EndIf; 				
							
				DocObject.Company = DataLine.Company;
				
				If ValueIsFilled(DataLine.ShipFromAddr) Then 
					DocObject.ShipFrom = Catalogs.Addresses.FindByDescription(DataLine.ShipFromAddr,,,DocObject.Company);
				EndIf;
				
				SalesReturnCompanyOnChangeAtServer(DocObject);
				
				If ValueIsFilled(DataLine.Currency) Then 
					DocObject.Currency = DataLine.Currency;
					DocObject.ExchangeRate = GeneralFunctions.GetExchangeRate(DocObject.Date, DocObject.Currency);
				EndIf;
				
				If ValueIsFilled(DataLine.ARAccount) Then 
					DocObject.ARAccount = DataLine.ARAccount;
				EndIf;
				
				If ValueIsFilled(DataLine.DueDate) Then 
					DocObject.DueDate = DataLine.DueDate;
				EndIf;
				
				If ValueIsFilled(DataLine.SalesPerson) Then 
					DocObject.SalesPerson = DataLine.SalesPerson;
				EndIf;
				
				If ValueIsFilled(DataLine.Location) Then 
					DocObject.Location 	= DataLine.Location;
				Else 	
					DocObject.Location 	= GeneralFunctions.GetDefaultLocation();
				EndIf;
				
				If ValueIsFilled(DataLine.SalesTaxRate) Then 
					DocObject.SalesTaxRate = DataLine.SalesTaxRate;
				EndIf;
				
				If Find (TrimAll(DataLine.ReturnType),"Refund") > 0 Then 
					DocObject.ReturnType = Enums.ReturnTypes.Refund;
				ElsIf Find (TrimAll(DataLine.ReturnType),"Return") > 0 Then 	
					DocObject.ReturnType = Enums.ReturnTypes.Refund;
				Else
					DocObject.ReturnType = Enums.ReturnTypes.CreditMemo;	
				EndIf;
								
				If ValueIsFilled(DataLine.Memo) Then 
					DocObject.Memo = DataLine.Memo;
				EndIf;
				
				DocPost = (DataLine.ToPost = True);
				
			EndIf;
			
			DocLineItem = DocObject.LineItems.Add();
			
			If ValueIsFilled(DataLine.Product) Then 
				DocLineItem.Product = DataLine.Product;
				TableSectionRow = New Structure("LineNumber, Product, ProductDescription, UnitSet, QtyUnits, Unit, QtyUM, UM, PriceUnits, LineTotal, Taxable, Project, Class, AvataxTaxCode, DiscountIsTaxable");
				FillPropertyValues(TableSectionRow, DocLineItem);
				
				SalesReturnLineItemsProductOnChangeAtServer(TableSectionRow,DocObject);
				FillPropertyValues(DocLineItem, TableSectionRow);
			Else 
				DocLineItem.Product = Catalogs.Products.FindByCode("comment",True);
			EndIf;
			
			If ValueIsFilled(DataLine.Description) Then 
				DocLineItem.ProductDescription = DataLine.Description;
			EndIf;
			
			If ValueIsFilled(DataLine.Price) Then 
				DocLineItem.PriceUnits = DataLine.Price;
			EndIf;
			
			If ValueIsFilled(DataLine.LineQuantity) Then 
				DocLineItem.QtyUnits	= DataLine.LineQuantity;
				DocLineItem.QtyUM		= Round(Round(DocLineItem.QtyUnits, QuantityPrecision) *
				?(DocLineItem.Unit.Factor > 0, DocLineItem.Unit.Factor, 1), QuantityPrecision);
			EndIf;
			
			If ValueIsFilled(DataLine.LineTotal) Then 
				DocLineItem.LineTotal = DataLine.LineTotal;
			EndIf;
			
			If ValueIsFilled(DataLine.LineClass) Then 
				DocLineItem.Class = DataLine.LineClass;
			EndIf;
			
			If ValueIsFilled(DataLine.LineProject) Then 
				DocLineItem.Project = DataLine.LineProject;
			EndIf;
			
			If ValueIsFilled(DataLine.Taxable) Then 
				DocLineItem.Taxable = DataLine.Taxable;
				//SalesInvoiceLineItemsTaxableOnChangeAtServer(DocLineItem,DocObject);
			EndIf;
			
			
		Except
			ErrorText = "Document Line: "+Counter+ Chars.LF+ ErrorDescription();
			Raise ErrorText;
		EndTry;
		
	EndDo;
	
	Try
		If DocObject <> Undefined Then
			SalesReturnRecalculateTotals(DocObject);
			DocObject.Write(?(DocPost,DocumentWriteMode.Posting,DocumentWriteMode.Write));
		EndIf;	
	Except
		ErrorText = "Document Line: "+Counter+ Chars.LF+ ErrorDescription();
		Raise ErrorText;
	EndTry;	

EndProcedure

Procedure CreateDepositCSV(ItemDataSet) Export
	
	Counter = 0;
	Counter10 = 0;
	MaxCount = ItemDataSet.count();
	
	PrevNumber = Undefined;
	DocObject = Undefined;
	DocPost = False;
	
	QuantityPrecision = GeneralFunctionsReusable.DefaultQuantityPrecision();
	DefaultCurrency = GeneralFunctionsReusable.DefaultCurrency();
	
	For Each DataLine In ItemDataSet Do
		
		Counter = Counter + 1;
		Progress = Int((Counter/MaxCount)*10); 
		If Counter10 <> Progress then
			Counter10 = Progress;
			LongActions.InformActionProgres(Counter10*10,"Current progress: "+(Counter10*10) +"%");
		EndIf;	
		
		Try
			If PrevNumber <> DataLine.Number  Then
				
				//PrevNumber = DataLine.Number;
				
				//If ValueIsFilled(DataLine.Number) Then 
				//	DocObject.PaymentMethod = DataLine.PaymentMethod;
				//Else 
				//	DocObject.PaymentMethod = Catalogs.PaymentMethods.Check;
				//EndIf;
				//
				
				// Writing previous document
				If DocObject <> Undefined Then
					
					DocObject.TotalDeposits = DocObject.LineItems.Total("DocumentTotal");
					DocObject.TotalDepositsRC = DocObject.LineItems.Total("DocumentTotalRC");
					
					DocObject.DocumentTotal = DocObject.TotalDeposits + DocObject.Accounts.Total("Amount");
					DocObject.DocumentTotalRC = DocObject.TotalDepositsRC + DocObject.Accounts.Total("Amount");

					DocObject.Write(?(DocPost,DocumentWriteMode.Posting,DocumentWriteMode.Write));
				EndIf;	
				
				If ValueIsFilled(DataLine.Number) Then 
					ExistingDoc = Documents.Deposit.FindByNumber(DataLine.Number,DataLine.DepositDate);
					If ValueIsFilled(ExistingDoc) Then 
						DocObject = ExistingDoc.GetObject();
						DocObject.LineItems.Clear();
						DocObject.Accounts.Clear();
					Else
						DocObject = Documents.Deposit.CreateDocument();
						DocObject.Number = DataLine.Number;
					EndIf;
				Else 
					DocObject = Documents.Deposit.CreateDocument();
					DocObject.SetNewNumber();
					
				EndIf;
				
				//
				//NewDeposit = Documents.Deposit.CreateDocument();
				//NewDeposit.Date = DataLine.DepositDate;
				//NewDeposit.BankAccount = DataLine.DepositBankAccount;
				//NewDeposit.Memo = DataLine.DepositMemo;
				//NewDeposit.DocumentTotalRC = DataLine.DepositLineAmount;
				//NewDeposit.DocumentTotal = DataLine.DepositLineAmount;
				
				
				DocObject.Date = Date(DataLine.DepositDate)+1;
				
				If ValueIsFilled(DataLine.DepositBankAccount) Then 
					DocObject.BankAccount = DataLine.DepositBankAccount;
				Else 
					DocObject.BankAccount = Constants.BankAccount.Get();
				EndIf;
				
				If ValueIsFilled(DataLine.DepositMemo) Then 
					DocObject.Memo = DataLine.DepositMemo;
				EndIf;
				
				DocPost = (DataLine.ToPost = True);
				
				PrevNumber = DocObject.Number;
				
			EndIf;
			
			DocLineItem = DocObject.Accounts.Add();
			
			//NewLine = NewDeposit.Accounts.Add();
			//NewLine.Company = DataLine.DepositLineCompany;
			//NewLine.Account = DataLine.DepositLineAccount;
			//NewLine.Class = DataLine.DepositLineClass;
			//NewLine.Amount = DataLine.DepositLineAmount;
			//NewLine.Memo = DataLine.DepositLineMemo;
				
			
			If ValueIsFilled(DataLine.DepositLineCompany) Then 
				DocLineItem.Company = DataLine.DepositLineCompany;
			EndIf;
			
			If ValueIsFilled(DataLine.DepositLineAccount) Then 
				DocLineItem.Account = DataLine.DepositLineAccount;
			EndIf;
			
			If ValueIsFilled(DataLine.DepositLineClass) Then 
				DocLineItem.Class = DataLine.DepositLineClass;
			EndIf;

			If ValueIsFilled(DataLine.DepositLineMemo) Then 
				DocLineItem.Memo = DataLine.DepositLineMemo;
			EndIf;
			
			If ValueIsFilled(DataLine.DepositLineAmount) Then 
				DocLineItem.Amount = DataLine.DepositLineAmount;
			EndIf;
			
		Except
			ErrorText = "Document Line: "+Counter+ Chars.LF+ ErrorDescription();
			Raise ErrorText;
		EndTry;
		
	EndDo;
	
	Try
		If DocObject <> Undefined Then
			
			DocObject.TotalDeposits = DocObject.LineItems.Total("DocumentTotal");
			DocObject.TotalDepositsRC = DocObject.LineItems.Total("DocumentTotalRC");
			
			DocObject.DocumentTotal = DocObject.TotalDeposits + DocObject.Accounts.Total("Amount");
			DocObject.DocumentTotalRC = DocObject.TotalDepositsRC + DocObject.Accounts.Total("Amount");
			
			
			DocObject.Write(?(DocPost,DocumentWriteMode.Posting,DocumentWriteMode.Write));
		EndIf;	
	Except
		ErrorText = "Document Line: "+Counter+ Chars.LF+ ErrorDescription();
		Raise ErrorText;
	EndTry;	

	
	
EndProcedure

Procedure CreateCheckCSV(ItemDataSet) Export
	
	Counter = 0;
	Counter10 = 0;
	MaxCount = ItemDataSet.count();
	
	PrevNumber = Undefined;
	DocObject = Undefined;
	DocPost = False;
	
	QuantityPrecision = GeneralFunctionsReusable.DefaultQuantityPrecision();
	DefaultCurrency = GeneralFunctionsReusable.DefaultCurrency();
	
	For Each DataLine In ItemDataSet Do
		
		Counter = Counter + 1;
		Progress = Int((Counter/MaxCount)*10); 
		If Counter10 <> Progress then
			Counter10 = Progress;
			LongActions.InformActionProgres(Counter10*10,"Current progress: "+(Counter10*10) +"%");
		EndIf;	
		
		Try
			If PrevNumber <> DataLine.CheckNumber  Then
				
				If DocObject <> Undefined Then
					
					DocObject.DocumentTotal = DocObject.LineItems.Total("Amount");
					DocObject.DocumentTotalRC = DocObject.LineItems.Total("Amount") * DocObject.ExchangeRate;

					DocObject.Write(?(DocPost,DocumentWriteMode.Posting,DocumentWriteMode.Write));
				EndIf;	
				
				If ValueIsFilled(DataLine.CheckNumber) Then 
					ExistingDoc = Documents.Check.FindByNumber(DataLine.CheckNumber,DataLine.CheckDate);
					If ValueIsFilled(ExistingDoc) Then 
						DocObject = ExistingDoc.GetObject();
						DocObject.LineItems.Clear();
					Else
						DocObject = Documents.Check.CreateDocument();
						DocObject.Number = DataLine.CheckNumber;
					EndIf;
				Else 
					DocObject = Documents.Check.CreateDocument();
					DocObject.SetNewNumber();
					
				EndIf;
				
				DocObject.Date = Date(DataLine.CheckDate)+1;
				
				If ValueIsFilled(DataLine.CheckBankAccount) Then 
					DocObject.BankAccount = DataLine.CheckBankAccount;
				Else 
					DocObject.BankAccount = Constants.BankAccount.Get();
				EndIf;
				
				
				
				AccountCurrency = CommonUse.GetAttributeValue(DocObject.BankAccount, "Currency");
				DocObject.ExchangeRate = GeneralFunctions.GetExchangeRate(DocObject.Date, AccountCurrency);
				DocObject.PaymentMethod = Catalogs.PaymentMethods.Check;
				
				If ValueIsFilled(DataLine.CheckVendor) Then 
					DocObject.Company = DataLine.CheckVendor;
				EndIf;
				
				If ValueIsFilled(DataLine.CheckMemo) Then 
					DocObject.Memo = DataLine.CheckMemo;
				EndIf;
				
				DocPost = (DataLine.ToPost = True);
				
				PrevNumber = DocObject.Number;
				
			EndIf;
			
			DocLineItem = DocObject.LineItems.Add();
			
			If ValueIsFilled(DataLine.CheckLineAccount) Then 
				DocLineItem.Account = DataLine.CheckLineAccount;
			EndIf;
			
			If ValueIsFilled(DataLine.CheckLineAmount) Then 
				DocLineItem.Amount = DataLine.CheckLineAmount;
			EndIf;
			
			If ValueIsFilled(DataLine.CheckLineClass) Then 
				DocLineItem.Class = DataLine.CheckLineClass;
			EndIf;

			If ValueIsFilled(DataLine.CheckLineMemo) Then 
				DocLineItem.Memo = DataLine.CheckLineMemo;
			EndIf;
			
		Except
			ErrorText = "Document Line: "+Counter+ Chars.LF+ ErrorDescription();
			Raise ErrorText;
		EndTry;
		
	EndDo;
	
	Try
		If DocObject <> Undefined Then
			
			DocObject.DocumentTotal = DocObject.LineItems.Total("Amount");
			DocObject.DocumentTotalRC = DocObject.LineItems.Total("Amount") * DocObject.ExchangeRate;
			
			DocObject.Write(?(DocPost,DocumentWriteMode.Posting,DocumentWriteMode.Write));
		EndIf;	
	Except
		ErrorText = "Document Line: "+Counter+ Chars.LF+ ErrorDescription();
		Raise ErrorText;
	EndTry;	

	
	
EndProcedure

Procedure CreateCheckCSVOld(ItemDataSet) Export
	
	
	For Each DataLine In ItemDataSet Do
				
		
		NewCheck = Documents.Check.CreateDocument();
		NewCheck.Date = DataLine.CheckDate;
		NewCheck.Number = DataLine.CheckNumber;
		NewCheck.BankAccount = DataLine.CheckBankAccount;
		NewCheck.Memo = DataLine.CheckMemo;
		NewCheck.Company = DataLine.CheckVendor;
		NewCheck.DocumentTotalRC = DataLine.CheckLineAmount;
		NewCheck.DocumentTotal = DataLine.CheckLineAmount;
		NewCheck.ExchangeRate = 1;
		NewCheck.PaymentMethod = Catalogs.PaymentMethods.DebitCard;
		NewLine = NewCheck.LineItems.Add();
		NewLine.Account = DataLine.CheckLineAccount;
		NewLine.Amount = DataLine.CheckLineAmount;
		NewLine.Memo = DataLine.CheckLineMemo;
		NewLine.Class = DataLine.CheckLineClass;
		NewCheck.Write();

		
	EndDo;

	
EndProcedure

// ++ Copied and modified from SI form module
&AtServer
Procedure SalesInvoiceRecalculateTotals(Object) Export 
	
	// Calculate document totals.
	LineSubtotal 	= 0;
	TaxableSubtotal = 0;
	Discount		= 0;
	TotalDiscount	= -1 * Object.Discount;
	DiscountLeft	= TotalDiscount;
	For Each Row In Object.LineItems Do
		LineSubtotal 	= LineSubtotal  + Row.LineTotal;
		If Object.DiscountType = PredefinedValue("Enum.DiscountType.FixedAmount") Then
			RowDiscount = ?(Row.LineTotal = 0, 0, Round(Row.LineTotal/Object.LineItems.Total("LineTotal") * TotalDiscount, 2));
			RowDiscount = ?(RowDiscount>DiscountLeft, DiscountLeft, RowDiscount);
			DiscountLeft = DiscountLeft - RowDiscount;
			RowTaxableAmount = 0;
			If Row.Taxable Then
				If Object.DiscountTaxability = PredefinedValue("Enum.DiscountTaxability.NonTaxable") Then
					RowTaxableAmount = Row.LineTotal - RowDiscount;
				ElsIf Object.DiscountTaxability = PredefinedValue("Enum.DiscountTaxability.Taxable") Then
					RowTaxableAmount = Row.LineTotal;
				Else
					RowTaxableAmount = Row.LineTotal - ?(Row.DiscountIsTaxable, 0, RowDiscount);
				EndIf;
			Else
				RowTaxableAmount = 0;
			EndIf;
		Else //By percent
			Discount 		= Discount + Round(-1 * Row.LineTotal * Object.DiscountPercent/100, 2);
			// Calculate taxable amount by line total.
			RowTaxableAmount = 0;
			If Row.Taxable Then
				If Object.DiscountTaxability = PredefinedValue("Enum.DiscountTaxability.NonTaxable") Then
					RowTaxableAmount = Row.LineTotal - Round(Row.LineTotal * Object.DiscountPercent/100, 2);
				ElsIf Object.DiscountTaxability = PredefinedValue("Enum.DiscountTaxability.Taxable") Then
					RowTaxableAmount = Row.LineTotal;
				Else
					RowTaxableAmount = Row.LineTotal - ?(Row.DiscountIsTaxable, 0, Round(Row.LineTotal * Object.DiscountPercent/100, 2));
				EndIf;
			Else
				RowTaxableAmount = 0;
			EndIf;
		EndIf;

		TaxableSubtotal = TaxableSubtotal + RowTaxableAmount;
	EndDo;
	
	// Assign totals to the object fields.
	Object.LineSubtotal = LineSubtotal;
	// Recalculate the discount and it's percent.
	If Object.DiscountType <> PredefinedValue("Enum.DiscountType.FixedAmount") Then
		Object.Discount		= Discount;
	Else
		Object.DiscountPercent = Round(-1 * 100 * Object.Discount / Object.LineSubtotal, 2);
	EndIf;
	If Object.Discount < -Object.LineSubtotal Then
		Object.Discount = -Object.LineSubtotal;
	EndIf;
		
	//Calculate sales tax
	If Not Object.UseAvatax Then //Recalculate sales tax only if using AccountingSuite sales tax engine
		//If Object.DiscountIsTaxable Then
		Object.TaxableSubtotal = TaxableSubtotal;
		//Else
			//Object.TaxableSubtotal = TaxableSubtotal + Round(-1 * TaxableSubtotal * Object.DiscountPercent/100, 2);
		//	Object.TaxableSubtotal = TaxableSubtotal + Object.Discount;
		//EndIf;
		CurrentAgenciesRates = Undefined;
		If Object.SalesTaxAcrossAgencies.Count() > 0 Then
			CurrentAgenciesRates = New Array();
			For Each AgencyRate In Object.SalesTaxAcrossAgencies Do
				CurrentAgenciesRates.Add(New Structure("Agency, Rate, SalesTaxRate, SalesTaxComponent", AgencyRate.Agency, AgencyRate.Rate, AgencyRate.SalesTaxRate, AgencyRate.SalesTaxComponent));
			EndDo;
		EndIf;
		#If Client Then
		SalesTaxAcrossAgencies = SalesTaxClient.CalculateSalesTax(Object.TaxableSubtotal, Object.SalesTaxRate, CurrentAgenciesRates);
		#EndIf
		#If Server Then
		SalesTaxAcrossAgencies = SalesTax.CalculateSalesTax(Object.TaxableSubtotal, Object.SalesTaxRate, CurrentAgenciesRates);
		#EndIf
		Object.SalesTaxAcrossAgencies.Clear();
		For Each STAcrossAgencies In SalesTaxAcrossAgencies Do 
			NewRow = Object.SalesTaxAcrossAgencies.Add();
			FillPropertyValues(NewRow, STAcrossAgencies);
		EndDo;
	EndIf;
	Object.SalesTax = Object.SalesTaxAcrossAgencies.Total("Amount");
	
	// Calculate the rest of the totals.
	Object.SubTotal         = LineSubtotal + Object.Discount;
	Object.DocumentTotal    = Object.SubTotal + Object.Shipping + Object.SalesTax;
	
	Object.SalesTaxRC       = Round(Object.SalesTax * Object.ExchangeRate, 2);
	SubTotalRC				= Round(Object.SubTotal * Object.ExchangeRate, 2);
	ShippingRC				= Round(Object.Shipping * Object.ExchangeRate, 2);
	//Object.DocumentTotalRC  = Round(Object.DocumentTotal * Object.ExchangeRate, 2);
	Object.DocumentTotalRC	= SubTotalRC + ShippingRC + Object.SalesTaxRC;

EndProcedure

&AtServer
Procedure SalesInvoiceCompanyOnChangeAtServer(Object)
	
	// Reset company adresses (if company was changed).
	SalesInvoiceFillCompanyAddressesAtServer(Object.Company, Object.ShipTo, Object.BillTo, Object.ConfirmTo);
	ConfirmToEmail = CommonUse.GetAttributeValue(Object.ConfirmTo, "Email");
	ShipToEmail    = CommonUse.GetAttributeValue(Object.ShipTo, "Email");
	Object.EmailTo = ?(ValueIsFilled(Object.ConfirmTo), ConfirmToEmail, ShipToEmail);
	
	// Request company default settings.
	Object.Currency        = Object.Company.DefaultCurrency;
	Object.Terms           = Object.Company.Terms;
	Object.SalesPerson     = Object.Company.SalesPerson;
	
	// Check company orders for further orders selection.
	Object.ExchangeRate            = GeneralFunctions.GetExchangeRate(Object.Date, Object.Currency);
	Object.ARAccount               = Object.Currency.DefaultARAccount;
	SalesInvoiceRecalculateTotals(Object);
	// Define empty date.
	EmptyDate = '00010101';
	// Update due date basing on the currently selected terms.
	Object.DueDate = ?(Not Object.Terms.IsEmpty(), Object.Date + Object.Terms.Days * 60*60*24, EmptyDate);
	
	
	// Tax settings
	SalesTaxRate 		= SalesTax.GetDefaultSalesTaxRate(Object.Company);
	If GeneralFunctionsReusable.FunctionalOptionValue("AvataxEnabled") Then
		Object.UseAvatax	= Object.Company.UseAvatax;
	Else
		Object.UseAvatax	= False;
	EndIf;
	If (Not Object.UseAvatax) Then
		TaxEngine = 1; //Use AccountingSuite
		If SalesTaxRate <> Object.SalesTaxRate Then
			Object.SalesTaxRate = SalesTaxRate;
		EndIf;
	Else
		TaxEngine = 2;
	EndIf;
	Object.SalesTaxAcrossAgencies.Clear();
	
	If Object.UseAvatax Then
		AvataxServer.RestoreCalculatedSalesTax(Object);
	EndIf;	
	
	SalesInvoiceRecalculateTotals(Object);
	//DisplaySalesTaxRate(ThisForm);
	
	//newALAN
	If Object.Company.ARAccount <> ChartsofAccounts.ChartOfAccounts.EmptyRef() Then
		Object.ARAccount = Object.Company.ARAccount;
	Else
		DefaultCurrency = GeneralFunctionsReusable.DefaultCurrency();
		Object.ARAccount = DefaultCurrency.DefaultARAccount;
	EndIf;
	
	//Items.DecorationBillTo.Visible = True;
	//Items.DecorationShipTo.Visible = True;
	//Items.DecorationShipTo.Title = GeneralFunctions.ShowAddressDecoration(Object.ShipTo);
	//Items.DecorationBillTo.Title = GeneralFunctions.ShowAddressDecoration(Object.BillTo);
	
EndProcedure

&AtServer
Procedure SalesInvoiceFillCompanyAddressesAtServer(Company, ShipTo, BillTo = Undefined, ConfirmTo = Undefined);
	
	// Check if company changed and addresses are required to be refilled.
	If Not ValueIsFilled(BillTo)    Or BillTo.Owner    <> Company
	Or Not ValueIsFilled(ShipTo)    Or ShipTo.Owner    <> Company
	Or Not ValueIsFilled(ConfirmTo) Or ConfirmTo.Owner <> Company Then
		
		// Create new query
		Query = New Query;
		Query.SetParameter("Ref", Company);
		
		Query.Text =
		"SELECT
		|	Addresses.Ref,
		|	Addresses.DefaultBilling,
		|	Addresses.DefaultShipping
		|FROM
		|	Catalog.Addresses AS Addresses
		|WHERE
		|	Addresses.Owner = &Ref
		|	AND (Addresses.DefaultBilling
		|	  OR Addresses.DefaultShipping)";
		Selection = Query.Execute().Select();
		
		// Assign default addresses.
		While Selection.Next() Do
			If Selection.DefaultBilling Then
				BillTo = Selection.Ref;
			EndIf;
			If Selection.DefaultShipping Then
				ShipTo = Selection.Ref;
			EndIf;
		EndDo;
		ConfirmTo = Catalogs.Addresses.EmptyRef();
	EndIf;
	
EndProcedure

&AtServer
Procedure SalesInvoiceLineItemsProductOnChangeAtServer(TableSectionRow, Object)
	
	// Request product properties.
	ProductProperties = CommonUse.GetAttributeValues(TableSectionRow.Product,   New Structure("Ref, Description, UnitSet, HasLotsSerialNumbers, UseLots, UseLotsType, Characteristic, UseSerialNumbersOnShipment, Taxable, TaxCode, DiscountIsTaxable"));
	UnitSetProperties = CommonUse.GetAttributeValues(ProductProperties.UnitSet, New Structure("DefaultSaleUnit"));
	TableSectionRow.ProductDescription  = ProductProperties.Description;
	TableSectionRow.UnitSet             = ProductProperties.UnitSet;
	TableSectionRow.Unit                = UnitSetProperties.DefaultSaleUnit;
	//TableSectionRow.UM                = UnitSetProperties.UM;
	TableSectionRow.Taxable             = ProductProperties.Taxable;
	TableSectionRow.DiscountIsTaxable   = ProductProperties.DiscountIsTaxable;
	If Object.UseAvatax Then
		TableSectionRow.AvataxTaxCode   = ProductProperties.TaxCode;
	EndIf;
	TableSectionRow.PriceUnits          = Round(GeneralFunctions.RetailPrice(Object.Date, TableSectionRow.Product, Object.Company) /
	                                     // The price is returned for default sales unit factor.
	                                     ?(Object.ExchangeRate > 0, Object.ExchangeRate, 1), GeneralFunctionsReusable.PricePrecisionForOneItem(TableSectionRow.Product));
	
	// Make lots & serial numbers columns visible.
	//LotsSerialNumbers.UpdateLotsSerialNumbersVisibility(ProductProperties, Items, 1, TableSectionRow.UseLotsSerials);
	
	// Fill lot owner.
	LotsSerialNumbers.FillLotOwner(ProductProperties, TableSectionRow.LotOwner);
	
	// Clear serial numbers.
	TableSectionRow.SerialNumbers = "";
	//LineItemsSerialNumbersOnChangeAtServer(TableSectionRow);
	
	// Clear up order data.
	TableSectionRow.Order              = Documents.SalesOrder.EmptyRef();
	TableSectionRow.DeliveryDate       = '00010101';
	TableSectionRow.Location           = Catalogs.Locations.EmptyRef();
	
	// Reset default values.
	TableSectionRow.DeliveryDateActual = Object.DeliveryDateActual;
	TableSectionRow.LocationActual     = Object.LocationActual;
	TableSectionRow.Project            = Object.Project;
	TableSectionRow.Class              = Object.Class;
	
	// Assign default quantities.
	TableSectionRow.QtyUnits  = 0;
	TableSectionRow.QtyUM     = 0;
	TableSectionRow.Ordered   = 0;
	TableSectionRow.Backorder = 0;
	TableSectionRow.Shipped   = 0;
	TableSectionRow.Invoiced  = 0;
	
	// Calculate totals by line.
	TableSectionRow.LineTotal  		= 0;
	TableSectionRow.TaxableAmount 	= 0;
	
	SalesInvoiceUpdateInformationCurrentRow(TableSectionRow, Object);
	
EndProcedure

&AtServer
Procedure SalesInvoiceUpdateInformationCurrentRow(CurrentRow,Object)
	
	InformationCurrentRow = "";
	
	If CurrentRow.Product <> Undefined And CurrentRow.Product <> PredefinedValue("Catalog.Products.EmptyRef") Then
		
		LineItems = Object.LineItems.Unload(, "LineNumber, Product, QtyUM, LineTotal");
		
		LineItem = LineItems.Find(CurrentRow.LineNumber, "LineNumber");
		LineItem.Product   = CurrentRow.Product;
		LineItem.QtyUM     = CurrentRow.QtyUM;
		LineItem.LineTotal = CurrentRow.LineTotal;
		
		InformationCurrentRow = GeneralFunctions.GetMarginInformation(CurrentRow.Product, CurrentRow.LocationActual, CurrentRow.QtyUM, CurrentRow.LineTotal,
																	  Object.Currency, Object.ExchangeRate, Object.DiscountPercent, LineItems); 
		InformationCurrentRow = "" + InformationCurrentRow;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure SalesInvoiceLineItemsTaxableOnChangeAtServer(TableSectionRow,Object)
	
	//// Calculate sales tax by line total.
	If TableSectionRow.Taxable Then
		If Object.DiscountTaxability = Enums.DiscountTaxability.NonTaxable Then
			TableSectionRow.TaxableAmount = TableSectionRow.LineTotal - Round(TableSectionRow.LineTotal * Object.DiscountPercent/100, 2);
		ElsIf Object.DiscountTaxability = Enums.DiscountTaxability.Taxable Then
			TableSectionRow.TaxableAmount = TableSectionRow.LineTotal;
		Else
			TableSectionRow.TaxableAmount = TableSectionRow.LineTotal - ?(TableSectionRow.DiscountIsTaxable, 0, Round(TableSectionRow.LineTotal * Object.DiscountPercent/100, 2));
		EndIf;
	Else
		TableSectionRow.TaxableAmount = 0;
	EndIf;
	//RecalculateTotals(Object);
	//
	//UpdateInformationCurrentRow(TableSectionRow);
	
EndProcedure

// -- Copied and modified from SI form module


// ++ Copied and modified from SO form module
&AtServer
Procedure SalesOrderRecalculateTotals(Object)
	
	// Calculate document totals.
	LineSubtotal 	= 0;
	TaxableSubtotal = 0;
	Discount		= 0;
	TotalDiscount	= -1 * Object.Discount;
	DiscountLeft	= TotalDiscount;
	For Each Row In Object.LineItems Do
		LineSubtotal 	= LineSubtotal  + Row.LineTotal;
		If Object.DiscountType = PredefinedValue("Enum.DiscountType.FixedAmount") Then
			RowDiscount = ?(Row.LineTotal = 0, 0, Round(Row.LineTotal/Object.LineItems.Total("LineTotal") * TotalDiscount, 2));
			RowDiscount = ?(RowDiscount>DiscountLeft, DiscountLeft, RowDiscount);
			DiscountLeft = DiscountLeft - RowDiscount;
			RowTaxableAmount = 0;
			If Row.Taxable Then
				If Object.DiscountTaxability = PredefinedValue("Enum.DiscountTaxability.NonTaxable") Then
					RowTaxableAmount = Row.LineTotal - RowDiscount;
				ElsIf Object.DiscountTaxability = PredefinedValue("Enum.DiscountTaxability.Taxable") Then
					RowTaxableAmount = Row.LineTotal;
				Else
					RowTaxableAmount = Row.LineTotal - ?(Row.DiscountIsTaxable, 0, RowDiscount);
				EndIf;
			Else
				RowTaxableAmount = 0;
			EndIf;
		Else //By percent
			Discount 		= Discount + Round(-1 * Row.LineTotal * Object.DiscountPercent/100, 2);
			// Calculate taxable amount by line total.
			RowTaxableAmount = 0;
			If Row.Taxable Then
				If Object.DiscountTaxability = PredefinedValue("Enum.DiscountTaxability.NonTaxable") Then
					RowTaxableAmount = Row.LineTotal - Round(Row.LineTotal * Object.DiscountPercent/100, 2);
				ElsIf Object.DiscountTaxability = PredefinedValue("Enum.DiscountTaxability.Taxable") Then
					RowTaxableAmount = Row.LineTotal;
				Else
					RowTaxableAmount = Row.LineTotal - ?(Row.DiscountIsTaxable, 0, Round(Row.LineTotal * Object.DiscountPercent/100, 2));
				EndIf;
			Else
				RowTaxableAmount = 0;
			EndIf;
		EndIf;

		TaxableSubtotal = TaxableSubtotal + RowTaxableAmount;
	EndDo;
	
	// Assign totals to the object fields.
	Object.LineSubtotal = LineSubtotal;
	// Recalculate the discount and it's percent.
	If Object.DiscountType <> PredefinedValue("Enum.DiscountType.FixedAmount") Then
		Object.Discount		= Discount;
	Else
		Object.DiscountPercent = ?(Object.LineSubtotal <> 0, Round(-1 * 100 * Object.Discount / Object.LineSubtotal, 2), 0);
	EndIf;
	If Object.Discount < -Object.LineSubtotal Then
		Object.Discount = -Object.LineSubtotal;
	EndIf;
		
	//Calculate sales tax
	If Not Object.UseAvatax Then //Recalculate sales tax only if using AccountingSuite sales tax engine
		Object.TaxableSubtotal = TaxableSubtotal;
		CurrentAgenciesRates = Undefined;
		If Object.SalesTaxAcrossAgencies.Count() > 0 Then
			CurrentAgenciesRates = New Array();
			For Each AgencyRate In Object.SalesTaxAcrossAgencies Do
				CurrentAgenciesRates.Add(New Structure("Agency, Rate, SalesTaxRate, SalesTaxComponent", AgencyRate.Agency, AgencyRate.Rate, AgencyRate.SalesTaxRate, AgencyRate.SalesTaxComponent));
			EndDo;
		EndIf;
		#If Client Then
		SalesTaxAcrossAgencies = SalesTaxClient.CalculateSalesTax(Object.TaxableSubtotal, Object.SalesTaxRate, CurrentAgenciesRates);
		#EndIf
		#If Server Then
		SalesTaxAcrossAgencies = SalesTax.CalculateSalesTax(Object.TaxableSubtotal, Object.SalesTaxRate, CurrentAgenciesRates);
		#EndIf
		Object.SalesTaxAcrossAgencies.Clear();
		For Each STAcrossAgencies In SalesTaxAcrossAgencies Do 
			NewRow = Object.SalesTaxAcrossAgencies.Add();
			FillPropertyValues(NewRow, STAcrossAgencies);
		EndDo;
	EndIf;
	Object.SalesTax = Object.SalesTaxAcrossAgencies.Total("Amount");
	
	// Calculate the rest of the totals.
	Object.SubTotal         = LineSubtotal + Object.Discount;
	Object.DocumentTotal    = Object.SubTotal + Object.Shipping + Object.SalesTax;
	
	Object.SalesTaxRC       = Round(Object.SalesTax * Object.ExchangeRate, 2);
	SubTotalRC				= Round(Object.SubTotal * Object.ExchangeRate, 2);
	ShippingRC				= Round(Object.Shipping * Object.ExchangeRate, 2);
	Object.DocumentTotalRC	= SubTotalRC + ShippingRC + Object.SalesTaxRC;

EndProcedure

&AtServer
Procedure SalesOrderCompanyOnChangeAtServer(Object)
	
	// Reset company adresses (if company was changed).
	SalesOrderFillCompanyAddressesAtServer(Object.Company, Object.ShipTo, Object.BillTo, Object.ConfirmTo);
	
	// Request company default settings.
	Object.Currency    = Object.Company.DefaultCurrency;
	Object.SalesPerson = Object.Company.SalesPerson;
	
	// Process settings changes.
	//CurrencyOnChangeAtServer();
	Object.ExchangeRate = GeneralFunctions.GetExchangeRate(Object.Date, Object.Currency);
	SalesTaxRate 		= SalesTax.GetDefaultSalesTaxRate(Object.Company);
	If GeneralFunctionsReusable.FunctionalOptionValue("AvataxEnabled") Then
		Object.UseAvatax	= Object.Company.UseAvatax;
	Else
		Object.UseAvatax	= False;
	EndIf;
	If (Not Object.UseAvatax) Then
		TaxEngine = 1; //Use AccountingSuite
		If SalesTaxRate <> Object.SalesTaxRate Then
			Object.SalesTaxRate = SalesTaxRate;
		EndIf;
	Else
		TaxEngine = 2;
	EndIf;
	Object.SalesTaxAcrossAgencies.Clear();
	//ApplySalesTaxEngineSettings();
	If Object.UseAvatax Then
		AvataxServer.RestoreCalculatedSalesTax(Object);
	EndIf;	
	
	SalesOrderRecalculateTotals(Object);
		
EndProcedure

&AtServer
Procedure SalesOrderFillCompanyAddressesAtServer(Company, ShipTo, BillTo = Undefined, ConfirmTo = Undefined);
	
	// Check if company changed and addresses are required to be refilled.
	If Not ValueIsFilled(BillTo)    Or BillTo.Owner    <> Company
	Or Not ValueIsFilled(ShipTo)    Or ShipTo.Owner    <> Company
	Or Not ValueIsFilled(ConfirmTo) Or ConfirmTo.Owner <> Company Then
		
		// Create new query
		Query = New Query;
		Query.SetParameter("Ref", Company);
		
		Query.Text =
		"SELECT
		|	Addresses.Ref,
		|	Addresses.DefaultBilling,
		|	Addresses.DefaultShipping
		|FROM
		|	Catalog.Addresses AS Addresses
		|WHERE
		|	Addresses.Owner = &Ref
		|	AND (Addresses.DefaultBilling
		|	  OR Addresses.DefaultShipping)";
		Selection = Query.Execute().Select();
		
		// Assign default addresses.
		While Selection.Next() Do
			If Selection.DefaultBilling Then
				BillTo = Selection.Ref;
			EndIf;
			If Selection.DefaultShipping Then
				ShipTo = Selection.Ref;
			EndIf;
		EndDo;
		ConfirmTo = Catalogs.Addresses.EmptyRef();
	EndIf;
	
EndProcedure
// -- Copied and modified from SO form module

// ++ Copied and modified from CR form module
&AtServer
Procedure CashReceiptCompanyOnChange(Object)
	
	Query = New Query("SELECT
		                  |	Addresses.FirstName,
		                  |	Addresses.MiddleName,
		                  |	Addresses.LastName,
		                  |	Addresses.Phone,
		                  |	Addresses.Fax,
		                  |	Addresses.Email,
		                  |	Addresses.AddressLine1,
		                  |	Addresses.AddressLine2,
		                  |	Addresses.City,
		                  |	Addresses.State.Code AS State,
		                  |	Addresses.Country,
		                  |	Addresses.ZIP,
		                  |	Addresses.RemitTo
		                  |FROM
		                  |	Catalog.Addresses AS Addresses
		                  |WHERE
		                  |	Addresses.Owner = &Company
		                  |	AND Addresses.DefaultBilling = TRUE");
	Query.SetParameter("Company", object.company);
		QueryResult = Query.Execute();	
	Dataset = QueryResult.Unload();
		
	If Dataset.Count() > 0 Then
		Object.EmailTo = Dataset[0].Email;
	EndIf;

	Object.Currency = CommonUse.GetAttributeValue(Object.Company, "DefaultCurrency");
	Object.ExchangeRate = GeneralFunctions.GetExchangeRate(Object.Date, Object.Currency);
	
	If Object.Company.ARAccount <> ChartsofAccounts.ChartOfAccounts.EmptyRef() Then
		Object.ARAccount = Object.Company.ARAccount;
	Else
		DefaultCurrency = GeneralFunctionsReusable.DefaultCurrency();
		Object.ARAccount = DefaultCurrency.DefaultARAccount;
	EndIf;
	
	//CashReceiptMethods.FillDocumentList(Object.Company,Object);
	//CashReceiptMethods.FillCreditMemos(Object.Company,Object);
	
EndProcedure

// -- Copied and modified from CR form module


//++
Procedure SalesReturnRecalculateTotals(Object)
	
	// Calculate document totals.
	LineSubtotal 	= 0;
	TaxableSubtotal = 0;
	Discount		= 0;
	For Each Row In Object.LineItems Do
		LineSubtotal 	= LineSubtotal  + Row.LineTotal;
		Discount 		= Discount + Round(-1 * Row.LineTotal * Object.DiscountPercent/100, 2);
		// Calculate taxable amount by line total.
		RowTaxableAmount = 0;
		If Row.Taxable Then
			If Object.DiscountTaxability = PredefinedValue("Enum.DiscountTaxability.NonTaxable") Then
				RowTaxableAmount = Row.LineTotal - Round(Row.LineTotal * Object.DiscountPercent/100, 2);
			ElsIf Object.DiscountTaxability = PredefinedValue("Enum.DiscountTaxability.Taxable") Then
				RowTaxableAmount = Row.LineTotal;
			Else
				RowTaxableAmount = Row.LineTotal - ?(Row.DiscountIsTaxable, 0, Round(Row.LineTotal * Object.DiscountPercent/100, 2));
			EndIf;
		Else
			RowTaxableAmount = 0;
		EndIf;

		TaxableSubtotal = TaxableSubtotal + RowTaxableAmount;
	EndDo;
	
	// Assign totals to the object fields.
	Object.LineSubtotal = LineSubtotal;
	// Recalculate the discount and it's percent.
	Object.Discount		= Discount;
	If Object.Discount < -Object.LineSubtotal Then
		Object.Discount = -Object.LineSubtotal;
	EndIf;
		
	//Calculate sales tax
	If Not Object.UseAvatax Then //Recalculate sales tax only if using AccountingSuite sales tax engine
		Object.TaxableSubtotal = TaxableSubtotal;
		CurrentAgenciesRates = Undefined;
		If Object.SalesTaxAcrossAgencies.Count() > 0 Then
			CurrentAgenciesRates = New Array();
			For Each AgencyRate In Object.SalesTaxAcrossAgencies Do
				CurrentAgenciesRates.Add(New Structure("Agency, Rate, SalesTaxRate, SalesTaxComponent", AgencyRate.Agency, AgencyRate.Rate, AgencyRate.SalesTaxRate, AgencyRate.SalesTaxComponent));
			EndDo;
		EndIf;
		#If Client Then
		SalesTaxAcrossAgencies = SalesTaxClient.CalculateSalesTax(Object.TaxableSubtotal, Object.SalesTaxRate, CurrentAgenciesRates);
		#EndIf
		#If Server Then
		SalesTaxAcrossAgencies = SalesTax.CalculateSalesTax(Object.TaxableSubtotal, Object.SalesTaxRate, CurrentAgenciesRates);
		#EndIf
		Object.SalesTaxAcrossAgencies.Clear();
		For Each STAcrossAgencies In SalesTaxAcrossAgencies Do 
			NewRow = Object.SalesTaxAcrossAgencies.Add();
			FillPropertyValues(NewRow, STAcrossAgencies);
		EndDo;
	EndIf;
	Object.SalesTax = Object.SalesTaxAcrossAgencies.Total("Amount");
	
	// Calculate the rest of the totals.
	Object.SubTotal         = LineSubtotal + Object.Discount;
	Object.DocumentTotal    = Object.SubTotal + Object.Shipping + Object.SalesTax;
	
	SalesTaxRC       		= Round(Object.SalesTax * Object.ExchangeRate, 2);
	SubTotalRC				= Round(Object.SubTotal * Object.ExchangeRate, 2);
	ShippingRC				= Round(Object.Shipping * Object.ExchangeRate, 2);
	Object.DocumentTotalRC	= SubTotalRC + ShippingRC + SalesTaxRC;

EndProcedure


Procedure SalesReturnCompanyOnChangeAtServer(Object)
	
	Object.Currency = CommonUse.GetAttributeValue(Object.Company, "DefaultCurrency");
	Object.ARAccount = CommonUse.GetAttributeValue(Object.Currency, "DefaultARAccount");
	Object.ExchangeRate = GeneralFunctions.GetExchangeRate(Object.Date, Object.Currency);
	
	If Not ValueIsFilled(Object.ParentDocument) Then
		SalesTaxRate = SalesTax.GetDefaultSalesTaxRate(Object.Company);
		
		If GeneralFunctionsReusable.FunctionalOptionValue("AvataxEnabled") Then
			Object.UseAvatax	= Object.Company.UseAvatax;
		Else
			Object.UseAvatax	= False;
		EndIf;
		If (Not Object.UseAvatax) Then
			TaxEngine = 1; //Use AccountingSuite
			If SalesTaxRate <> Object.SalesTaxRate Then
				Object.SalesTaxRate = SalesTaxRate;
			EndIf;
		Else
			TaxEngine = 2;
		EndIf;
		Object.SalesTaxAcrossAgencies.Clear();
		
		If Object.UseAvatax Then
			If Object.Ref.IsEmpty() Then
				Object.AvataxShippingTaxCode = Constants.AvataxDefaultShippingTaxCode.Get();
			EndIf;
			AvataxServer.RestoreCalculatedSalesTax(Object);
		EndIf;	
	EndIf;
	
	If Object.Company.ARAccount <> ChartsofAccounts.ChartOfAccounts.EmptyRef() Then
		Object.ARAccount = Object.Company.ARAccount;
	Else
		DefaultCurrency = GeneralFunctionsReusable.DefaultCurrency();
		Object.ARAccount = DefaultCurrency.DefaultARAccount;
	EndIf;
	
EndProcedure


Procedure SalesReturnLineItemsProductOnChangeAtServer(TableSectionRow,Object)
	
	// Request product properties.
	ProductProperties = CommonUse.GetAttributeValues(TableSectionRow.Product,   New Structure("Description, UnitSet, Taxable, TaxCode, DiscountIsTaxable"));
	UnitSetProperties = CommonUse.GetAttributeValues(ProductProperties.UnitSet, New Structure("DefaultSaleUnit"));
	TableSectionRow.ProductDescription = ProductProperties.Description;
	TableSectionRow.UnitSet            = ProductProperties.UnitSet;
	TableSectionRow.Unit               = UnitSetProperties.DefaultSaleUnit;
	TableSectionRow.Taxable            = ProductProperties.Taxable;
	TableSectionRow.DiscountIsTaxable	= ProductProperties.DiscountIsTaxable;
	If Object.UseAvatax Then
		TableSectionRow.AvataxTaxCode 	= ProductProperties.TaxCode;
	EndIf;
	TableSectionRow.PriceUnits         = Round(GeneralFunctions.RetailPrice(Object.Date, TableSectionRow.Product, Object.Company) /
	                                     // The price is returned for default sales unit factor.
	                                     ?(Object.ExchangeRate > 0, Object.ExchangeRate, 1), GeneralFunctionsReusable.PricePrecisionForOneItem(TableSectionRow.Product));
										 
	// Assign default quantities.
	TableSectionRow.QtyUnits  = 0;
	TableSectionRow.QtyUM     = 0;
	
	// Calculate totals by line.
	TableSectionRow.LineTotal     = 0;
	
EndProcedure



//--