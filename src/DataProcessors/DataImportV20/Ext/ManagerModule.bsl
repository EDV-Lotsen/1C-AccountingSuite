
Procedure CreateCustomerVendorCSV(ItemDataSet, AdParams) Export
	
	LongActions.InformActionProgres(0,"Current progress: 0%");
	
	UpdateOption = AdParams.UpdateOption;
	ErrorProcessing = AdParams.ErrorProcessing;
	ErrorMessagesArray = "";
	ErrorCounter = 0;
	
	
	Counter = 0;
	Counter10 = 0;
	MaxCount = ItemDataSet.count();
	ToRefill = (UpdateOption = "AllFields");
		
	If MaxCount > 1000 then 
		ReportStep = 100;
	Else 
		ReportStep = MaxCount/100;
	EndIf;
	
	For Each DataLine In ItemDataSet Do
		
		Progress = (Counter/MaxCount); 
		If INT(Counter/ReportStep)*ReportStep = Counter then
			Counter10 = Int(Progress*100);
			If TrimAll(ErrorProcessing) = "SkipErrors" and  ErrorMessagesArray <> "" Then
				AdNotificationParams = New Structure;
				AdNotificationParams.Insert("Error",ErrorMessagesArray);
				LongActions.InformActionProgres(Counter,"Current progress: "+(Counter10) +"%", AdNotificationParams);
			Else 	
				LongActions.InformActionProgres(Counter,"Current progress: "+(Counter10) +"%");
			EndIf;	
		EndIf;		
		
		Counter = Counter + 1;
		LastLineNumber = DataLine.LineNumber;
		
		Try

	 	CreatingNewCompany = False;
		CompanyFound = Catalogs.Companies.FindByDescription(DataLine.CustomerDescription,True);
			
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
		
		If UpdateFieldValue(DataLine.CustomerVendor1099,UpdateOption) Then
			NewCompany.Vendor1099 = (TrimAll(DataLine.CustomerVendor1099) = "T");
		EndIf;	
		
		If UpdateFieldValue(DataLine.CustomerEmployee,UpdateOption) Then
			NewCompany.Employee = (TrimAll(DataLine.CustomerEmployee) = "T");
		EndIf;
		
		If UpdateFieldValue(DataLine.CustomerEIN_SSN,UpdateOption) Then
			NewCompany.FederalIDType = DataLine.CustomerEIN_SSN;
		EndIf;
		
		If UpdateFieldValue(DataLine.CustomerIncomeAccount,UpdateOption) Then
			NewCompany.IncomeAccount = DataLine.CustomerIncomeAccount;
		EndIf;
		
		If UpdateFieldValue(DataLine.CustomerExpenseAccount,UpdateOption) Then
			NewCompany.ExpenseAccount = DataLine.CustomerExpenseAccount;
		EndIf;
		
		If ToRefill Or NewCompany.DefaultCurrency.IsEmpty() Then 
			NewCompany.DefaultCurrency = Constants.DefaultCurrency.Get();
		EndIf;	
		
		If UpdateFieldValue(DataLine.CustomerTerms,UpdateOption) Then
			NewCompany.Terms = DataLine.CustomerTerms;
		ElsIf ToRefill Then 
			NewCompany.Terms = Catalogs.PaymentTerms.Net30;
		EndIf;
		
		If UpdateFieldValue(DataLine.CustomerNotes,UpdateOption) Then
			NewCompany.Notes = DataLine.CustomerNotes;
		EndIf;
		If UpdateFieldValue(DataLine.CustomerVendorTaxID,UpdateOption) Then
			NewCompany.USTaxID = DataLine.CustomerVendorTaxID;
		EndIf;
		
		If UpdateFieldValue(DataLine.CustomerVendorTaxID,UpdateOption) and NewCompany.FederalIDType.IsEmpty() Then 
			IDSeparator = Find(NewCompany.USTaxID,"-");
			If IDSeparator = 4 Then  
				NewCompany.FederalIDType = Enums.FederalIDType.SSN;
			Else 
				NewCompany.FederalIDType = Enums.FederalIDType.EIN;
			EndIf;	
		EndIf;	
		
		If UpdateFieldValue(DataLine.CustomerCF1String,UpdateOption) Then
			NewCompany.CF1String = DataLine.CustomerCF1String;
		EndIf;
		If UpdateFieldValue(DataLine.CustomerCF1Num,UpdateOption) Then
			NewCompany.CF1Num = DataLine.CustomerCF1Num;
		EndIf;	
		
		If UpdateFieldValue(DataLine.CustomerCF2String,UpdateOption) Then
			NewCompany.CF2String = DataLine.CustomerCF2String;
		EndIf;
		If UpdateFieldValue(DataLine.CustomerCF2Num,UpdateOption) Then
			NewCompany.CF2Num = DataLine.CustomerCF2Num;
		EndIf;	
		
		If UpdateFieldValue(DataLine.CustomerCF3String,UpdateOption) Then
			NewCompany.CF3String = DataLine.CustomerCF3String;
		EndIf;
		If UpdateFieldValue(DataLine.CustomerCF3Num,UpdateOption) Then
			NewCompany.CF3Num = DataLine.CustomerCF3Num;
		EndIf;	
		
		If UpdateFieldValue(DataLine.CustomerCF4String,UpdateOption) Then
			NewCompany.CF4String = DataLine.CustomerCF4String;
		EndIf;
		If UpdateFieldValue(DataLine.CustomerCF4Num,UpdateOption) Then
			NewCompany.CF4Num = DataLine.CustomerCF4Num;
		EndIf;	
		
		If UpdateFieldValue(DataLine.CustomerCF5String,UpdateOption) Then
			NewCompany.CF5String = DataLine.CustomerCF5String;
		EndIf;
		If UpdateFieldValue(DataLine.CustomerCF5Num,UpdateOption) Then
			NewCompany.CF5Num = DataLine.CustomerCF5Num;
		EndIf;	
		
		If UpdateFieldValue(DataLine.CustomerSalesPerson,UpdateOption) Then
			NewCompany.SalesPerson = DataLine.CustomerSalesPerson;
		EndIf;
		
		If UpdateFieldValue(DataLine.CustomerWebsite,UpdateOption) Then
			NewCompany.Website = DataLine.CustomerWebsite;
		EndIf;
		
		If UpdateFieldValue(DataLine.CustomerPriceLevel,UpdateOption) Then
			NewCompany.PriceLevel = DataLine.CustomerPriceLevel;
		EndIf;
		
		If UpdateFieldValue(DataLine.STaxable,UpdateOption) Then
			NewCompany.Taxable = (TrimAll(DataLine.STaxable) = "T");
		EndIf;	
		If UpdateFieldValue(DataLine.STaxRate,UpdateOption) Then
			NewCompany.SalesTaxRate = DataLine.STaxRate;
		EndIf;
		NewCompany.Write();
			
		CreateUpdateAddresses(DataLine,  NewCompany.Ref , ToRefill); 
		
		Query = New Query("SELECT
		|	Addresses.Ref
		|FROM
		|	Catalog.Addresses AS Addresses
		|WHERE
		|	Addresses.Owner = &Ref");
		
		Query.SetParameter("Ref", NewCompany.Ref);
		QueryResult = Query.Execute();
		If QueryResult.IsEmpty() Then
			AddressLine = Catalogs.Addresses.CreateItem();
			AddressLine.Owner = NewCompany.Ref;
			AddressLine.Description = "Primary";
			AddressLine.DefaultShipping = True;
			AddressLine.DefaultBilling = True;
			AddressLine.Write();
		EndIf;
		
		Except
			StrErrorDescription = "Document Line: "+LastLineNumber+ Chars.LF+ ErrorDescription();
			If TrimAll(ErrorProcessing) = "StopOnError" Then 
				ErrorText = "ERROR" + Chars.LF + StrErrorDescription;
				LongActions.InformActionProgres(Counter-1,ErrorText);
				Return;
			ElsIf TrimAll(ErrorProcessing) = "SkipErrors" Then 
				ErrorMessagesArray = ErrorMessagesArray + ?(ErrorMessagesArray = "","",Chars.LF)+StrErrorDescription;
				ErrorCounter = ErrorCounter + 1;
			EndIf;	
		EndTry;
				
	EndDo;
	
	If ErrorMessagesArray <> "" Then 
		ErrorText = "ERROR" + Chars.LF + ErrorMessagesArray;
		LongActions.InformActionProgres(Counter - ErrorCounter,ErrorText);
	Else 
		LongActions.InformActionProgres(Counter - ErrorCounter,"");	
	EndIf;	
	

EndProcedure

Function UpdateFieldValue(Value, UpdateOption, AdditionalParemeters = Undefined) Export 
	If ValueIsFilled(Value) Then 
		If UpdateOption = "AllFields" Then
			Return True;
		ElsIf UpdateOption = "OnlyFilled" Then 	
			Return True;
		EndIf;
	ElsIf UpdateOption = "AllFields" Then 
		Return True;
	ElsIf UpdateOption = "OnlyFilled" Then 	
		Return False;
	EndIf;	
EndFunction	

Procedure CreateUpdateAddresses(DataLine, Owner, ToRefil = True) 
	
	If Not ValueIsFilled(Owner) Then 
		Return;
	EndIf;	
	
	TheSameDataInBothAdresses = False;
	
	SettingMap = New Structure;
	SettingMapShip = New Structure;
	
	DefaultBilling = (TrimAll(DataLine.DefaultBillingAddress) = "T");
	DefaultShipping = (TrimAll(DataLine.DefaultShippingAddress) = "T");
	
	//======================= Checking wheather addresses are equal ============================
	SettingMap.Insert("AddressLine1", 	DataLine.CustomerAddressLine1);
	SettingMap.Insert("AddressLine2", 	DataLine.CustomerAddressLine2);
	SettingMap.Insert("AddressLine3", 	DataLine.CustomerAddressLine3);
	SettingMap.Insert("City",			DataLine.CustomerCity);
	SettingMap.Insert("State", 			DataLine.CustomerState);
	SettingMap.Insert("Country", 		DataLine.CustomerCountry);
	SettingMap.Insert("ZIP", 			DataLine.CustomerZIP);
	
	SettingMapShip.Insert("AddressLine1", 	DataLine.CustomerShippingAddressLine1);
	SettingMapShip.Insert("AddressLine2", 	DataLine.CustomerShippingAddressLine2);
	SettingMapShip.Insert("AddressLine3", 	DataLine.CustomerShippingAddressLine3);
	SettingMapShip.Insert("City",			DataLine.CustomerShippingCity);
	SettingMapShip.Insert("State",	 		DataLine.CustomerShippingState);
	SettingMapShip.Insert("Country", 		DataLine.CustomerShippingCountry);
	SettingMapShip.Insert("ZIP", 			DataLine.CustomerShippingZIP);
	
	SameAddresses = True;
	EmptyBillingAddress = True;
	EmptyShippingAddress = True;
	For Each AddrStr In  SettingMapShip Do 
		If TrimAll(SettingMap[AddrStr.Key]) <> TrimAll(AddrStr.Value) Then 
			SameAddresses = False;
		EndIf;
		If TrimAll(SettingMap[AddrStr.Key]) <> "" Then 
			EmptyBillingAddress = False;
		EndIf;
		If TrimAll(AddrStr.Value) <> "" Then 
			EmptyShippingAddress = False;
		EndIf;
	EndDo;
	
	If SameAddresses Or EmptyBillingAddress Or EmptyShippingAddress Then 
		SameAddresses = True;
		// will put all fields into bill addr
		If EmptyBillingAddress Then
			For Each AddrStr In SettingMapShip Do 
				SettingMap[AddrStr.Key] = AddrStr.Value;
			EndDo;		
		EndIf;
	EndIf;	
	
	//======================= Checking for empty addresses ============================
	
	SettingMap.Insert("SalesPerson", 	DataLine.AddressSalesPerson);
	SettingMap.Insert("Salutation", 	DataLine.AddressSalutation);
	SettingMap.Insert("FirstName", 		DataLine.CustomerFirstName);
	SettingMap.Insert("LastName",		DataLine.CustomerLastName);
	SettingMap.Insert("MiddleName", 	DataLine.CustomerMiddleName);
	SettingMap.Insert("Suffix", 		DataLine.AddressSuffix);
	SettingMap.Insert("JobTitle",		DataLine.AddressJobTitle);
	
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
	
	If SameAddresses Then 
		Query = New Query;
		Query.Text = 
		"SELECT
		|	Addresses.Ref
		|FROM
		|	Catalog.Addresses AS Addresses
		|WHERE
		|	Addresses.Owner = &Owner
		|	AND (&DefaultBilling OR &DefaultShipping)";
		Query.SetParameter("Owner", Owner);
		If DefaultBilling Then 
			Query.SetParameter("DefaultBilling", DefaultBilling);
		Else 
			Query.Text = StrReplace(Query.Text,"(&DefaultBilling OR", "(FALSE OR");
		EndIf;	
		
		If DefaultShipping Then 
			Query.SetParameter("DefaultShipping", DefaultShipping);
		Else 
			Query.Text = StrReplace(Query.Text,"&DefaultShipping)", "FALSE)");
		EndIf;	
		
		QueryResult = Query.Execute();
		SelectionDetailRecords = QueryResult.Select();
		While SelectionDetailRecords.Next() Do
			AddressRef = SelectionDetailRecords.Ref;
			AddressLine = AddressRef.GetObject();
			If DefaultBilling Then 
				AddressLine.DefaultBilling = False;
			EndIf;
			If DefaultShipping Then 
				AddressLine.DefaultShipping = False;
			EndIf;
			AddressLine.Write();
		EndDo;
		
		Query.Text = 
		"SELECT
		|	Addresses.Ref,
		|	Addresses.DefaultBilling,
		|	Addresses.DefaultShipping,
		|	CASE
		|		WHEN Addresses.DefaultBilling
		|			THEN 0
		|		WHEN Addresses.DefaultShipping
		|			THEN 1
		|		ELSE 2
		|	END AS PriorityAddr
		|FROM
		|	Catalog.Addresses AS Addresses
		|WHERE
		|	Addresses.Owner = &Owner
		|	AND Addresses.FirstName LIKE &FirstName
		|	AND Addresses.MiddleName LIKE &MiddleName
		|	AND Addresses.LastName LIKE &LastName
		|	AND Addresses.Phone LIKE &Phone
		|	AND Addresses.Cell LIKE &Cell
		|	AND Addresses.Fax LIKE &Fax
		|	AND Addresses.Email LIKE &Email
		|	AND Addresses.AddressLine1 LIKE &AddressLine1
		|	AND Addresses.AddressLine2 LIKE &AddressLine2
		|	AND Addresses.AddressLine3 LIKE &AddressLine3
		|	AND Addresses.City = &City
		|	AND Addresses.State = &State
		|	AND Addresses.Country = &Country
		|	AND Addresses.ZIP LIKE &ZIP
		|
		|ORDER BY
		|	PriorityAddr";
		
		Query.SetParameter("City", SettingMap.City);
		Query.SetParameter("State", SettingMap.State);
		Query.SetParameter("Country", SettingMap.Country);
		Query.SetParameter("ZIP", SettingMap.ZIP);
		Query.SetParameter("AddressLine1", SettingMap.AddressLine1);
		Query.SetParameter("AddressLine2", SettingMap.AddressLine2);
		Query.SetParameter("AddressLine3", SettingMap.AddressLine3);
		Query.SetParameter("FirstName", SettingMap.FirstName);
		Query.SetParameter("LastName", SettingMap.LastName);
		Query.SetParameter("MiddleName", SettingMap.MiddleName);
		Query.SetParameter("Phone", SettingMap.Phone);
		Query.SetParameter("Email", SettingMap.Email);
		Query.SetParameter("Fax", SettingMap.Fax);
		Query.SetParameter("Cell", SettingMap.Cell);
		Query.SetParameter("Owner", Owner);
		
		QueryResult = Query.Execute();
		If QueryResult.IsEmpty() Then 
			AddressLine = Catalogs.Addresses.CreateItem();	
		Else 	
			SelectionDetailRecords = QueryResult.Select();
			SelectionDetailRecords.Next();
			AddressRef = SelectionDetailRecords.Ref;
			AddressLine = AddressRef.GetObject();
		EndIf;
		
		If TrimAll(DataLine.CustomerAddressID) <> "" Then
			AddressLine.Description = DataLine.CustomerAddressID;
		ElsIF DefaultShipping And DefaultBilling Then
			AddressLine.Description = "Primary";
		ElsIf DefaultShipping Then 
			AddressLine.Description = "Primary Shipping";
		ElsIf DefaultBilling Then 
			AddressLine.Description = "Primary Billing";	
		Else
			AddressLine.Description = "Address";
		EndIf;			
		AddressLine.DefaultBilling = DefaultBilling or AddressLine.DefaultBilling;
		AddressLine.DefaultShipping = DefaultShipping OR AddressLine.DefaultShipping;
		//EndIf;
		
		//========================== Filling other attributes ================================
		AddressLine.Owner = Owner;
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
		
		AddressLine.AddressLine1 = SettingMap.AddressLine1;
		AddressLine.AddressLine2 = SettingMap.AddressLine2;
		AddressLine.AddressLine3 = SettingMap.AddressLine3;
		AddressLine.City = SettingMap.City;
		AddressLine.State = SettingMap.State;
		AddressLine.Country = SettingMap.Country;
		AddressLine.ZIP = SettingMap.ZIP;
		
		AddressLine.Notes = DataLine.CustomerAddressNotes;
		
		AddressLine.CF1String = DataLine.AddressCF1String;
		AddressLine.CF2String = DataLine.AddressCF2String;
		AddressLine.CF3String = DataLine.AddressCF3String;
		AddressLine.CF4String = DataLine.AddressCF4String;
		AddressLine.CF5String = DataLine.AddressCF5String;
		
		CheckSimilarAddressNames(Owner,AddressLine.Description, AddressLine.Ref);
		
		AddressLine.Write();
		
	Else 
		//============================== Billing Addr ================================
		Query = New Query;
		Query.Text = 
		"SELECT
		|	Addresses.Ref,
		|	Addresses.DefaultBilling,
		|	Addresses.DefaultShipping,
		|	CASE
		|		WHEN Addresses.DefaultBilling
		|			THEN 0
		|		ELSE 2
		|	END AS PriorityAddr
		|FROM
		|	Catalog.Addresses AS Addresses
		|WHERE
		|	Addresses.Owner = &Owner
		|	AND Addresses.FirstName LIKE &FirstName
		|	AND Addresses.MiddleName LIKE &MiddleName
		|	AND Addresses.LastName LIKE &LastName
		|	AND Addresses.Phone LIKE &Phone
		|	AND Addresses.Cell LIKE &Cell
		|	AND Addresses.Fax LIKE &Fax
		|	AND Addresses.Email LIKE &Email
		|	AND Addresses.AddressLine1 LIKE &AddressLine1
		|	AND Addresses.AddressLine2 LIKE &AddressLine2
		|	AND Addresses.AddressLine3 LIKE &AddressLine3
		|	AND Addresses.City = &City
		|	AND Addresses.State = &State
		|	AND Addresses.Country = &Country
		|	AND Addresses.ZIP LIKE &ZIP
		|
		|ORDER BY
		|	PriorityAddr";
		
		Query.SetParameter("City", SettingMap.City);
		Query.SetParameter("State", SettingMap.State);
		Query.SetParameter("Country", SettingMap.Country);
		Query.SetParameter("ZIP", SettingMap.ZIP);
		Query.SetParameter("AddressLine1", SettingMap.AddressLine1);
		Query.SetParameter("AddressLine2", SettingMap.AddressLine2);
		Query.SetParameter("AddressLine3", SettingMap.AddressLine3);
		Query.SetParameter("FirstName", SettingMap.FirstName);
		Query.SetParameter("LastName", SettingMap.LastName);
		Query.SetParameter("MiddleName", SettingMap.MiddleName);
		Query.SetParameter("Phone", SettingMap.Phone);
		Query.SetParameter("Email", SettingMap.Email);
		Query.SetParameter("Fax", SettingMap.Fax);
		Query.SetParameter("Cell", SettingMap.Cell);
		Query.SetParameter("Owner", Owner);
		
		QueryResult = Query.Execute();
		If QueryResult.IsEmpty() Then 
			AddressLine = Catalogs.Addresses.CreateItem();	
		Else 	
			SelectionDetailRecords = QueryResult.Select();
			SelectionDetailRecords.Next();
			AddressRef = SelectionDetailRecords.Ref;
			AddressLine = AddressRef.GetObject();
		EndIf;
		
		AddressLine.DefaultBilling = DefaultBilling or AddressLine.DefaultBilling;
		
		If TrimAll(DataLine.CustomerAddressID) <> "" Then
			AddressLine.Description = DataLine.CustomerAddressID;
		ElsIF DefaultBilling Then
			AddressLine.Description = "Primary Billing";
		Else
			AddressLine.Description = "Billing";
		EndIf;			
		AddressLine.DefaultShipping = False;
		AddressLine.DefaultBilling = DefaultBilling;
		
		//============================== Shipping Addr ================================
		Query.Text = 
		"SELECT
		|	Addresses.Ref,
		|	Addresses.DefaultBilling,
		|	Addresses.DefaultShipping,
		|	CASE
		|		WHEN Addresses.DefaultBilling
		|			THEN 0
		|		ELSE 2
		|	END AS PriorityAddr
		|FROM
		|	Catalog.Addresses AS Addresses
		|WHERE
		|	Addresses.Owner = &Owner
		|	AND Addresses.FirstName LIKE &FirstName
		|	AND Addresses.MiddleName LIKE &MiddleName
		|	AND Addresses.LastName LIKE &LastName
		|	AND Addresses.Phone LIKE &Phone
		|	AND Addresses.Cell LIKE &Cell
		|	AND Addresses.Fax LIKE &Fax
		|	AND Addresses.Email LIKE &Email
		|	AND Addresses.AddressLine1 LIKE &AddressLine1
		|	AND Addresses.AddressLine2 LIKE &AddressLine2
		|	AND Addresses.AddressLine3 LIKE &AddressLine3
		|	AND Addresses.City = &City
		|	AND Addresses.State = &State
		|	AND Addresses.Country = &Country
		|	AND Addresses.ZIP LIKE &ZIP
		|
		|ORDER BY
		|	PriorityAddr";
		
		Query.SetParameter("City", SettingMapShip.City);
		Query.SetParameter("State", SettingMapShip.State);
		Query.SetParameter("Country", SettingMapShip.Country);
		Query.SetParameter("ZIP", SettingMapShip.ZIP);
		Query.SetParameter("AddressLine1", SettingMapShip.AddressLine1);
		Query.SetParameter("AddressLine2", SettingMapShip.AddressLine2);
		Query.SetParameter("AddressLine3", SettingMapShip.AddressLine3);
		Query.SetParameter("FirstName", SettingMap.FirstName);
		Query.SetParameter("LastName", SettingMap.LastName);
		Query.SetParameter("MiddleName", SettingMap.MiddleName);
		Query.SetParameter("Phone", SettingMap.Phone);
		Query.SetParameter("Email", SettingMap.Email);
		Query.SetParameter("Fax", SettingMap.Fax);
		Query.SetParameter("Cell", SettingMap.Cell);
		Query.SetParameter("Owner", Owner);
		
		QueryResult = Query.Execute();
		If QueryResult.IsEmpty() Then 
			AddressLineSh = Catalogs.Addresses.CreateItem();	
		Else 	
			SelectionDetailRecords = QueryResult.Select();
			SelectionDetailRecords.Next();
			AddressRef = SelectionDetailRecords.Ref;
			AddressLineSh = AddressRef.GetObject();
		EndIf;
		
		AddressLineSh.DefaultShipping = DefaultShipping OR AddressLine.DefaultShipping;
		
		IF DefaultShipping Then
			AddressLineSh.Description = "Primary Shipping";
		Else
			AddressLineSh.Description = "Shipping";
		EndIf;			
		AddressLineSh.DefaultBilling = False;
		AddressLineSh.DefaultShipping = DefaultShipping;
		
		//========================== Filling other attributes ================================
		//================ BILLING ADDR ================
		AddressLine.Owner = Owner;
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
		
		AddressLine.Notes = DataLine.CustomerAddressNotes;
		
		AddressLine.CF1String = DataLine.AddressCF1String;
		AddressLine.CF2String = DataLine.AddressCF2String;
		AddressLine.CF3String = DataLine.AddressCF3String;
		AddressLine.CF4String = DataLine.AddressCF4String;
		AddressLine.CF5String = DataLine.AddressCF5String;
		
		AddressLine.AddressLine1 = SettingMap.AddressLine1;
		AddressLine.AddressLine2 = SettingMap.AddressLine2;
		AddressLine.AddressLine3 = SettingMap.AddressLine3;
		AddressLine.City = SettingMap.City;
		AddressLine.State = SettingMap.State;
		AddressLine.Country = SettingMap.Country;
		AddressLine.ZIP = SettingMap.ZIP;
		
		CheckSimilarAddressNames(Owner,AddressLine.Description, AddressLine.Ref);
		AddressLine.Write();
		
		//================== SHIPPING ADDR ================
		AddressLineSh.Owner = Owner;
		If DataLine.AddressSalesPerson <> Catalogs.SalesPeople.EmptyRef() Then
			AddressLineSh.SalesPerson = DataLine.AddressSalesPerson;
		EndIf;
		
		AddressLineSh.Salutation = DataLine.AddressSalutation;
		AddressLineSh.FirstName = DataLine.CustomerFirstName;
		AddressLineSh.MiddleName = DataLine.CustomerMiddleName;
		AddressLineSh.LastName = DataLine.CustomerLastName;
		AddressLineSh.Suffix = DataLine.AddressSuffix;
		AddressLineSh.JobTitle = DataLine.AddressJobTitle;
		
		AddressLineSh.Phone = DataLine.CustomerPhone;
		AddressLineSh.Cell = DataLine.CustomerCell;
		AddressLineSh.Fax = DataLine.CustomerFax;
		AddressLineSh.Email = DataLine.CustomerEmail;
		
		
		AddressLineSh.Notes = DataLine.CustomerAddressNotes;
		
		AddressLineSh.CF1String = DataLine.AddressCF1String;
		AddressLineSh.CF2String = DataLine.AddressCF2String;
		AddressLineSh.CF3String = DataLine.AddressCF3String;
		AddressLineSh.CF4String = DataLine.AddressCF4String;
		AddressLineSh.CF5String = DataLine.AddressCF5String;
		
		AddressLineSh.AddressLine1 = SettingMapShip.AddressLine1;
		AddressLineSh.AddressLine2 = SettingMapShip.AddressLine2;
		AddressLineSh.AddressLine3 = SettingMapShip.AddressLine3;
		AddressLineSh.City = SettingMapShip.City;
		AddressLineSh.State = SettingMapShip.State;
		AddressLineSh.Country = SettingMapShip.Country;
		AddressLineSh.ZIP = SettingMapShip.ZIP;
		
		CheckSimilarAddressNames(Owner,AddressLineSh.Description, AddressLineSh.Ref);
		AddressLineSh.Write();

	EndIf;
	
EndProcedure

Procedure CheckSimilarAddressNames(Owner, Name, Ref) 
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	Addresses.Ref
	|FROM
	|	Catalog.Addresses AS Addresses
	|WHERE
	|	Addresses.Ref <> &Ref
	|	AND Addresses.Owner = &Owner
	|	AND Addresses.Description LIKE &Description";
	
	Query.SetParameter("Description", Name);
	Query.SetParameter("Owner", Owner);
	Query.SetParameter("Ref", Ref);
	
	QueryResult = Query.Execute();
	SelectionDetailRecords = QueryResult.Select();
	
	While SelectionDetailRecords.Next() Do
		Obj = SelectionDetailRecords.Ref.GetObject();
		Obj.Description = Obj.Description +"_" +Obj.Code;
		Obj.Write();
	EndDo;

EndProcedure	

Procedure CreatePurchaseOrderCSV(Date, Date2, ItemDataSet, AdParams) Export
	
	LongActions.InformActionProgres(0,"Current progress: 0%");
	
	UpdateOption = AdParams.UpdateOption;
	ErrorProcessing = AdParams.ErrorProcessing;
	ErrorMessagesArray = "";
	ErrorCounter = 0;
	
	Counter = 0;
	Counter10 = 0;
	MaxCount = ItemDataSet.count();
	
	PrevNumber = Undefined;
	DocObject = Undefined;
	DocPost = False;
	
	QuantityPrecision = GeneralFunctionsReusable.DefaultQuantityPrecision();
	
	If MaxCount > 1000 then 
		ReportStep = 100;
	Else 
		ReportStep = MaxCount/100;
	EndIf;	
	For Each DataLine In ItemDataSet Do
		
		Progress = (Counter/MaxCount); 
		If INT(Counter/ReportStep)*ReportStep = Counter then
			Counter10 = Int(Progress*100);
			If TrimAll(ErrorProcessing) = "SkipErrors" and  ErrorMessagesArray <> "" Then
				AdNotificationParams = New Structure;
				AdNotificationParams.Insert("Error",ErrorMessagesArray);
				LongActions.InformActionProgres(Counter,"Current progress: "+(Counter10) +"%", AdNotificationParams);
			Else 	
				LongActions.InformActionProgres(Counter,"Current progress: "+(Counter10) +"%");
			EndIf;	
		EndIf;
		Counter = Counter + 1;
		LastLineNumber = DataLine.LineNumber;
		
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
			StrErrorDescription = "Document Line: "+LastLineNumber+ Chars.LF+ ErrorDescription();
			If TrimAll(ErrorProcessing) = "StopOnError" Then 
				ErrorText = "ERROR" + Chars.LF + StrErrorDescription;
				LongActions.InformActionProgres(Counter-1,ErrorText);
				Return;
			ElsIf TrimAll(ErrorProcessing) = "SkipErrors" Then 
				ErrorMessagesArray = ErrorMessagesArray + ?(ErrorMessagesArray = "","",Chars.LF)+StrErrorDescription;
				ErrorCounter = ErrorCounter + 1;
			EndIf;
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
		StrErrorDescription = "Document Line: "+LastLineNumber+ Chars.LF+ ErrorDescription();
		If TrimAll(ErrorProcessing) = "StopOnError" Then 
			ErrorText = "ERROR" + Chars.LF + StrErrorDescription;
			LongActions.InformActionProgres(Counter-1,ErrorText);
			Return;
		ElsIf TrimAll(ErrorProcessing) = "SkipErrors" Then 
			ErrorMessagesArray = ErrorMessagesArray + ?(ErrorMessagesArray = "","",Chars.LF)+StrErrorDescription;
			ErrorCounter = ErrorCounter + 1;
		EndIf;
	EndTry;	
	
	If ErrorMessagesArray <> "" Then 
		ErrorText = "ERROR" + Chars.LF + ErrorMessagesArray;
		LongActions.InformActionProgres(Counter - ErrorCounter,ErrorText);
	Else 
		LongActions.InformActionProgres(Counter - ErrorCounter,"");	
	EndIf;	

	
	
EndProcedure

Procedure CreatePurchaseInvoiceCSV(Date, Date2, ItemDataSet, AdParams) Export
	
	LongActions.InformActionProgres(0,"Current progress: 0%");
	
	UpdateOption = AdParams.UpdateOption;
	ErrorProcessing = AdParams.ErrorProcessing;
	ErrorMessagesArray = "";
	ErrorCounter = 0;
	
	Counter = 0;
	Counter10 = 0;
	MaxCount = ItemDataSet.count();
	
	PrevNumber = Undefined;
	DocObject = Undefined;
	DocPost = False;
	
	QuantityPrecision = GeneralFunctionsReusable.DefaultQuantityPrecision();
	
	If MaxCount > 1000 then 
		ReportStep = 100;
	Else 
		ReportStep = MaxCount/100;
	EndIf;	
	For Each DataLine In ItemDataSet Do
		
		Progress = (Counter/MaxCount); 
		If INT(Counter/ReportStep)*ReportStep = Counter then
			Counter10 = Int(Progress*100);
			If TrimAll(ErrorProcessing) = "SkipErrors" and  ErrorMessagesArray <> "" Then
				AdNotificationParams = New Structure;
				AdNotificationParams.Insert("Error",ErrorMessagesArray);
				LongActions.InformActionProgres(Counter,"Current progress: "+(Counter10) +"%", AdNotificationParams);
			Else 	
				LongActions.InformActionProgres(Counter,"Current progress: "+(Counter10) +"%");
			EndIf;	
		EndIf;		
		Counter = Counter + 1;
		LastLineNumber = DataLine.LineNumber;
		
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
				
				If ValueIsFilled(DataLine.LineProject) Then 
					DocLineItem.Project = DataLine.LineProject;
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
						
					ElsIf SelectionDetailRecords.Next() Then 
						DocLineItem.Order = SelectionDetailRecords.Ref;
					Else 
						//No PO
					EndIf;
				EndIf;
				
				If ValueIsFilled(DocLineItem.Order) Then 
					DocObject.DeliveryDateActual = DocLineItem.Order.DeliveryDate;
					DocLineItem.DeliveryDateActual = DocLineItem.Order.DeliveryDate;
					DocLineItem.DeliveryDate = DocLineItem.Order.DeliveryDate;
					
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
				
				If ValueIsFilled(DataLine.LineProject) Then 
					DocLineExpenses.Project = DataLine.LineProject;
				EndIf;
				
				If ValueIsFilled(DataLine.LineClass) Then 
					DocLineExpenses.Class = DataLine.LineClass;
				EndIf;
				
			EndIf;
			
		Except
			StrErrorDescription = "Document Line: "+LastLineNumber+ Chars.LF+ ErrorDescription();
			If TrimAll(ErrorProcessing) = "StopOnError" Then 
				ErrorText = "ERROR" + Chars.LF + StrErrorDescription;
				LongActions.InformActionProgres(Counter-1,ErrorText);
				Return;
			ElsIf TrimAll(ErrorProcessing) = "SkipErrors" Then 
				ErrorMessagesArray = ErrorMessagesArray + ?(ErrorMessagesArray = "","",Chars.LF)+StrErrorDescription;
				ErrorCounter = ErrorCounter + 1;
			EndIf;
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
		StrErrorDescription = "Document Line: "+LastLineNumber+ Chars.LF+ ErrorDescription();
		If TrimAll(ErrorProcessing) = "StopOnError" Then 
			ErrorText = "ERROR" + Chars.LF + StrErrorDescription;
			LongActions.InformActionProgres(Counter-1,ErrorText);
			Return;
		ElsIf TrimAll(ErrorProcessing) = "SkipErrors" Then 
			ErrorMessagesArray = ErrorMessagesArray + ?(ErrorMessagesArray = "","",Chars.LF)+StrErrorDescription;
			ErrorCounter = ErrorCounter + 1;
		EndIf;
	EndTry;	
	
	If ErrorMessagesArray <> "" Then 
		ErrorText = "ERROR" + Chars.LF + ErrorMessagesArray;
		LongActions.InformActionProgres(Counter - ErrorCounter,ErrorText);
	Else 
		LongActions.InformActionProgres(Counter - ErrorCounter,"");	
	EndIf;	
	
EndProcedure

Procedure CreateItemReceiptCSV(Date, Date2, ItemDataSet, AdParams) Export
	
	LongActions.InformActionProgres(0,"Current progress: 0%");
	
	UpdateOption = AdParams.UpdateOption;
	ErrorProcessing = AdParams.ErrorProcessing;
	ErrorMessagesArray = "";
	ErrorCounter = 0;
	
	Counter = 0;
	Counter10 = 0;
	MaxCount = ItemDataSet.count();
	
	PrevNumber = Undefined;
	DocObject = Undefined;
	DocPost = False;
	
	QuantityPrecision = GeneralFunctionsReusable.DefaultQuantityPrecision();
	
	If MaxCount > 1000 then 
		ReportStep = 100;
	Else 
		ReportStep = MaxCount/100;
	EndIf;	
	For Each DataLine In ItemDataSet Do
		
		Progress = (Counter/MaxCount); 
		If INT(Counter/ReportStep)*ReportStep = Counter then
			Counter10 = Int(Progress*100);
			If TrimAll(ErrorProcessing) = "SkipErrors" and  ErrorMessagesArray <> "" Then
				AdNotificationParams = New Structure;
				AdNotificationParams.Insert("Error",ErrorMessagesArray);
				LongActions.InformActionProgres(Counter,"Current progress: "+(Counter10) +"%", AdNotificationParams);
			Else 	
				LongActions.InformActionProgres(Counter,"Current progress: "+(Counter10) +"%");
			EndIf;	
		EndIf;	
		Counter = Counter + 1;
		LastLineNumber = DataLine.LineNumber;
		
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
			StrErrorDescription = "Document Line: "+LastLineNumber+ Chars.LF+ ErrorDescription();
			If TrimAll(ErrorProcessing) = "StopOnError" Then 
				ErrorText = "ERROR" + Chars.LF + StrErrorDescription;
				LongActions.InformActionProgres(Counter-1,ErrorText);
				Return;
			ElsIf TrimAll(ErrorProcessing) = "SkipErrors" Then 
				ErrorMessagesArray = ErrorMessagesArray + ?(ErrorMessagesArray = "","",Chars.LF)+StrErrorDescription;
				ErrorCounter = ErrorCounter + 1;
			EndIf;
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
		StrErrorDescription = "Document Line: "+LastLineNumber+ Chars.LF+ ErrorDescription();
		If TrimAll(ErrorProcessing) = "StopOnError" Then 
			ErrorText = "ERROR" + Chars.LF + StrErrorDescription;
			LongActions.InformActionProgres(Counter-1,ErrorText);
			Return;
		ElsIf TrimAll(ErrorProcessing) = "SkipErrors" Then 
			ErrorMessagesArray = ErrorMessagesArray + ?(ErrorMessagesArray = "","",Chars.LF)+StrErrorDescription;
			ErrorCounter = ErrorCounter + 1;
		EndIf;
	EndTry;	

	If ErrorMessagesArray <> "" Then 
		ErrorText = "ERROR" + Chars.LF + ErrorMessagesArray;
		LongActions.InformActionProgres(Counter - ErrorCounter,ErrorText);
	Else 
		LongActions.InformActionProgres(Counter - ErrorCounter,"");	
	EndIf;		
	
EndProcedure

Procedure CreateItemCSV(Date, Date2, ItemDataSet, AdParams) Export
	
	LongActions.InformActionProgres(0,"Current progress: 0%");
	
	UpdateOption = AdParams.UpdateOption;
	ErrorProcessing = AdParams.ErrorProcessing;
	ErrorMessagesArray = "";
	ErrorCounter = 0;
	
	// add transactions 1-500
	Counter = 0;
	Counter10 = 0;
	MaxCount = ItemDataSet.count();
	If MaxCount > 1000 then 
		ReportStep = 100;
	Else 
		ReportStep = MaxCount/100;
	EndIf;	
	For Each DataLine In ItemDataSet Do
		
		Progress = (Counter/MaxCount); 
		If INT(Counter/ReportStep)*ReportStep = Counter then
			Counter10 = Int(Progress*100);
			If TrimAll(ErrorProcessing) = "SkipErrors" and  ErrorMessagesArray <> "" Then
				AdNotificationParams = New Structure;
				AdNotificationParams.Insert("Error",ErrorMessagesArray);
				LongActions.InformActionProgres(Counter,"Current progress: "+(Counter10) +"%", AdNotificationParams);
			Else 	
				LongActions.InformActionProgres(Counter,"Current progress: "+(Counter10) +"%");
			EndIf;	
		EndIf;	
		
		Counter = Counter + 1;
		LastLineNumber = DataLine.LineNumber;
		
		Try
			UpdatedProduct = DataLine.ProductUpdate;
			ToRefill = (UpdateOption = "AllFields");
			
			If ValueIsFilled(UpdatedProduct) Then 
				NewProduct = UpdatedProduct.GetObject();
			Else	
				NewProduct = Catalogs.Products.CreateItem();
			EndIf;	
			
			If ValueIsFilled(DataLine.ProductType) Then 
				NewProduct.Type = DataLine.ProductType;
			EndIf;	
			
			If UpdateFieldValue(DataLine.ProductCode,UpdateOption) Then
				NewProduct.Code = DataLine.ProductCode;
			EndIf;	

			If UpdateFieldValue(DataLine.ProductDescription,UpdateOption) Then
				NewProduct.Description = DataLine.ProductDescription;
			ElsIf UpdateFieldValue(DataLine.ProductCode,UpdateOption) Then 
				NewProduct.Description = DataLine.ProductCode;
			EndIf;	
			
			If UpdateFieldValue(DataLine.PurchaseDescription,UpdateOption) Then
				NewProduct.vendor_description = DataLine.PurchaseDescription;
			EndIf;	
			
			If UpdateFieldValue(DataLine.ProductIncomeAcct,UpdateOption) Then
				NewProduct.IncomeAccount = DataLine.ProductIncomeAcct;
			EndIf;	
			If UpdateFieldValue(DataLine.ProductInvOrExpenseAcct,UpdateOption) Then
				NewProduct.InventoryOrExpenseAccount = DataLine.ProductInvOrExpenseAcct;
			EndIf;	
			If UpdateFieldValue(DataLine.ProductCOGSAcct,UpdateOption) Then
				NewProduct.COGSAccount = DataLine.ProductCOGSAcct;
			EndIf;	
			
			If UpdateFieldValue(DataLine.UoM,UpdateOption) Then
				NewProduct.UnitSet = DataLine.UoM;
			Elsif ToRefill Then  
				NewProduct.UnitSet = Constants.DefaultUoMSet.Get();
			EndIf;	
			
			If UpdateFieldValue(DataLine.ProductCategory,UpdateOption) Then
				NewProduct.Category = DataLine.ProductCategory;
			EndIf;	
			If UpdateFieldValue(DataLine.ProductPrice,UpdateOption) Then
				NewProduct.Price = DataLine.ProductPrice;
			EndIf;	
			If UpdateFieldValue(DataLine.ProductCost,UpdateOption) Then
				NewProduct.Cost = DataLine.ProductCost;
			EndIf;
			
			If UpdateFieldValue(DataLine.UPCCode,UpdateOption) Then
				NewProduct.UPC = DataLine.UPCCode;
			EndIf;	
			If UpdateFieldValue(DataLine.ReorderPoint,UpdateOption) Then
				NewProduct.ReorderQty = DataLine.ReorderPoint;
			EndIf;	
			
			If UpdateFieldValue(DataLine.ProductVendorCode,UpdateOption) Then
				NewProduct.vendor_code = DataLine.ProductVendorCode;
			EndIf;	
			If UpdateFieldValue(DataLine.ProductPreferedVendor,UpdateOption) Then
				NewProduct.PreferredVendor = DataLine.ProductPreferedVendor;
			EndIf;	
			
			If UpdateFieldValue(DataLine.ProductParent,UpdateOption) Then
				NewProduct.Parent = DataLine.ProductParent;
			Elsif ToRefill then
				NewProduct.Parent = Catalogs.Products.EmptyRef();
			EndIf;	
			
			If UpdateFieldValue(DataLine.ProductCF1String,UpdateOption) Then
				NewProduct.CF1String = DataLine.ProductCF1String;
			EndIf;
			If UpdateFieldValue(DataLine.ProductCF1Num,UpdateOption) Then
				NewProduct.CF1Num = DataLine.ProductCF1Num;
			EndIf;
			
			If UpdateFieldValue(DataLine.ProductCF2String,UpdateOption) Then
				NewProduct.CF2String = DataLine.ProductCF2String;
			EndIf;
			If UpdateFieldValue(DataLine.ProductCF2Num,UpdateOption) Then
				NewProduct.CF2Num = DataLine.ProductCF2Num;
			EndIf;
			
			If UpdateFieldValue(DataLine.ProductCF3String,UpdateOption) Then
				NewProduct.CF3String = DataLine.ProductCF3String;
			EndIf;
			If UpdateFieldValue(DataLine.ProductCF3Num,UpdateOption) Then
				NewProduct.CF3Num = DataLine.ProductCF3Num;
			EndIf;
			
			If UpdateFieldValue(DataLine.ProductCF4String,UpdateOption) Then
				NewProduct.CF4String = DataLine.ProductCF4String;
			EndIf;
			If UpdateFieldValue(DataLine.ProductCF4Num,UpdateOption) Then
				NewProduct.CF4Num = DataLine.ProductCF4Num;
			EndIf;
			
			If UpdateFieldValue(DataLine.ProductCF5String,UpdateOption) Then
				NewProduct.CF5String = DataLine.ProductCF5String;
			EndIf;
			If UpdateFieldValue(DataLine.ProductCF5Num,UpdateOption) Then
				NewProduct.CF5Num = DataLine.ProductCF5Num;
			EndIf;
			
			If NewProduct.Type = Enums.InventoryTypes.Inventory Then
				If ValueIsFilled(DataLine.CostingMethod) Then 
					NewProduct.CostingMethod = DataLine.CostingMethod;
				Else 	
					NewProduct.CostingMethod = Enums.InventoryCosting.WeightedAverage;
				EndIf;	
			EndIf;
			
			If UpdateFieldValue(DataLine.ProductTaxable,UpdateOption) Then
				NewProduct.Taxable = DataLine.ProductTaxable;
			EndIf;
			
			NewProduct.Write();
			
			//If UpdateFieldValue(DataLine.ProductPrice,UpdateOption) Then
			//	RecordSet = InformationRegisters.PriceList.CreateRecordSet();
			//	RecordSet.Filter.Product.Set(NewProduct.Ref);
			//	RecordSet.Filter.Period.Set(Date);
			//	NewRecord = RecordSet.Add();
			//	NewRecord.Period = Date;
			//	NewRecord.Product = NewProduct.Ref;
			//	NewRecord.Price = DataLine.ProductPrice;
			//	RecordSet.Write();
			//EndIf;
			
			If ValueIsFilled(DataLine.ProductQty) Then // make adjustment only for non-zero quantities
				IBB = Documents.ItemAdjustment.CreateDocument();
				IBB.SetNewNumber();
				IBB.Date = Date2;
				IBB.Product = NewProduct.Ref;
				IBB.Location = Catalogs.Locations.MainWarehouse;
				IBB.Quantity = DataLine.ProductQty;
				IBB.Amount = Dataline.ProductValue;
				IBB.IncomeExpenseAccount = NewProduct.COGSAccount;
				If IBB.IncomeExpenseAccount.IsEmpty() Then 
					If NewProduct.Type = Enums.InventoryTypes.Inventory Then	
						Ibb.IncomeExpenseAccount = GeneralFunctions.InventoryAcct(Enums.InventoryTypes.Inventory);	
					ElsIf NewProduct.Type = Enums.InventoryTypes.NonInventory Then		
						Ibb.IncomeExpenseAccount = GeneralFunctions.InventoryAcct(Enums.InventoryTypes.NonInventory);
					EndIf;
				EndIf;
				
				IBB.Write(DocumentWriteMode.Posting);
			EndIf;
			
		Except
			StrErrorDescription = "Document Line: "+LastLineNumber+ Chars.LF+ ErrorDescription();
			If TrimAll(ErrorProcessing) = "StopOnError" Then 
				ErrorText = "ERROR" + Chars.LF + StrErrorDescription;
				LongActions.InformActionProgres(Counter-1,ErrorText);
				Return;
			ElsIf TrimAll(ErrorProcessing) = "SkipErrors" Then 
				ErrorMessagesArray = ErrorMessagesArray + ?(ErrorMessagesArray = "","",Chars.LF)+StrErrorDescription;
				ErrorCounter = ErrorCounter + 1;
			EndIf;		
		EndTry;
		
	EndDo;

	If ErrorMessagesArray <> "" Then 
		ErrorText = "ERROR" + Chars.LF + ErrorMessagesArray;
		LongActions.InformActionProgres(Counter - ErrorCounter,ErrorText);
	Else 
		LongActions.InformActionProgres(Counter - ErrorCounter,"");
	EndIf;	
	
EndProcedure

Procedure CreateProjectsCSV(ItemDataSet, AdParams) Export
	
	LongActions.InformActionProgres(0,"Current progress: 0%");
	
	UpdateOption = AdParams.UpdateOption;
	ErrorProcessing = AdParams.ErrorProcessing;
	ErrorMessagesArray = "";
	ErrorCounter = 0;
	
	Counter = 0;
	Counter10 = 0;
	MaxCount = ItemDataSet.count();
	If MaxCount > 1000 then 
		ReportStep = 100;
	Else 
		ReportStep = MaxCount/100;
	EndIf;	
	For Each DataLine In ItemDataSet Do
		
		Progress = (Counter/MaxCount); 
		If INT(Counter/ReportStep)*ReportStep = Counter then
			Counter10 = Int(Progress*100);
			If TrimAll(ErrorProcessing) = "SkipErrors" and  ErrorMessagesArray <> "" Then
				AdNotificationParams = New Structure;
				AdNotificationParams.Insert("Error",ErrorMessagesArray);
				LongActions.InformActionProgres(Counter,"Current progress: "+(Counter10) +"%", AdNotificationParams);
			Else 	
				LongActions.InformActionProgres(Counter,"Current progress: "+(Counter10) +"%");
			EndIf;	
		EndIf;	
		Counter = Counter + 1;
		LastLineNumber = DataLine.LineNumber;
		
		Try
			UpdatedProject = FindObjectByAttribute("Catalog.Projects","Description",DataLine.Description);
			ToRefill = (UpdateOption = "AllFields");
			
			If ValueIsFilled(UpdatedProject) Then 
				NewProduct = UpdatedProject.GetObject();
			Else	
				NewProduct = Catalogs.Projects.CreateItem();
				NewProduct.Description = DataLine.Description;
			EndIf;	
			
			If UpdateFieldValue(DataLine.Customer,UpdateOption) Then 
				NewProduct.Customer = DataLine.Customer;
			EndIf;
			
			If UpdateFieldValue(DataLine.ExpenseBudget,UpdateOption) Then 
				NewProduct.ExpenseBudget = DataLine.ExpenseBudget;
			EndIf;
			If UpdateFieldValue(DataLine.ReceiptsBudget,UpdateOption) Then 
				NewProduct.ReceiptsBudget = DataLine.ReceiptsBudget;
			EndIf;
			If UpdateFieldValue(DataLine.HoursBudget,UpdateOption) Then 
				NewProduct.HoursBudget = DataLine.HoursBudget;
			EndIf;
			If UpdateFieldValue(DataLine.Status,UpdateOption) Then 
				If Find(Upper(DataLine.Status), "OPEN") > 0 Then 
					CurStatus = Enums.ProjectStatus.Open;
				ElsIf Find(Upper(DataLine.Status), "CLOSED") > 0 Then
					CurStatus = Enums.ProjectStatus.Closed;
				Else 
					CurStatus = Enums.ProjectStatus.EmptyRef();
				EndIf;
				NewProduct.Status = CurStatus;
			EndIf;
			If UpdateFieldValue(DataLine.Type,UpdateOption) Then 
				
				If Find(Upper(DataLine.Type), "FIXED") > 0 Then 
					CurType = Enums.ProjectType.Fixed;
				ElsIf Find(Upper(DataLine.Type), "TNM") > 0 Then
					CurType = Enums.ProjectType.TnM;
				ElsIf Find(Upper(DataLine.Type), "T&M") > 0 Then
					CurType = Enums.ProjectType.TnM;					
				Else 
					CurType = Enums.ProjectType.EmptyRef();
				EndIf;
				
				NewProduct.Type = CurType;
			EndIf;
			
			NewProduct.Write();
			
		Except
			StrErrorDescription = "Document Line: "+LastLineNumber+ Chars.LF+ ErrorDescription();
			If TrimAll(ErrorProcessing) = "StopOnError" Then 
				ErrorText = "ERROR" + Chars.LF + StrErrorDescription;
				LongActions.InformActionProgres(Counter-1,ErrorText);
				Return;
			ElsIf TrimAll(ErrorProcessing) = "SkipErrors" Then 
				ErrorMessagesArray = ErrorMessagesArray + ?(ErrorMessagesArray = "","",Chars.LF)+StrErrorDescription;
				ErrorCounter = ErrorCounter + 1;
			EndIf;	
		EndTry;
	EndDo;
	
	If ErrorMessagesArray <> "" Then 
		ErrorText = "ERROR" + Chars.LF + ErrorMessagesArray;
		LongActions.InformActionProgres(Counter - ErrorCounter,ErrorText);
	Else 
		LongActions.InformActionProgres(Counter - ErrorCounter,"");	
	EndIf;	

	
EndProcedure

Procedure CreateBillPaymentCSV(Date, Date2, ItemDataSet, AdParams) Export
	
	LongActions.InformActionProgres(0,"Current progress: 0%");
	
	UpdateOption = AdParams.UpdateOption;
	ErrorProcessing = AdParams.ErrorProcessing;
	ErrorMessagesArray = "";
	ErrorCounter = 0;
	
	Counter = 0;
	Counter10 = 0;
	MaxCount = ItemDataSet.count();
	
	PrevNumber = Undefined;
	DocObject = Undefined;
	DocPost = False;
	
	QuantityPrecision = GeneralFunctionsReusable.DefaultQuantityPrecision();
	DefaultCurrency = GeneralFunctionsReusable.DefaultCurrency();
	
	If MaxCount > 1000 then 
		ReportStep = 100;
	Else 
		ReportStep = MaxCount/100;
	EndIf;	
	For Each DataLine In ItemDataSet Do
		
		Progress = (Counter/MaxCount); 
		If INT(Counter/ReportStep)*ReportStep = Counter then
			Counter10 = Int(Progress*100);
			If TrimAll(ErrorProcessing) = "SkipErrors" and  ErrorMessagesArray <> "" Then
				AdNotificationParams = New Structure;
				AdNotificationParams.Insert("Error",ErrorMessagesArray);
				LongActions.InformActionProgres(Counter,"Current progress: "+(Counter10) +"%", AdNotificationParams);
			Else 	
				LongActions.InformActionProgres(Counter,"Current progress: "+(Counter10) +"%");
			EndIf;	
		EndIf;	
		Counter = Counter + 1;
		LastLineNumber = DataLine.LineNumber;
		
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
			StrErrorDescription = "Document Line: "+LastLineNumber+ Chars.LF+ ErrorDescription();
			If TrimAll(ErrorProcessing) = "StopOnError" Then 
				ErrorText = "ERROR" + Chars.LF + StrErrorDescription;
				LongActions.InformActionProgres(Counter-1,ErrorText);
				Return;
			ElsIf TrimAll(ErrorProcessing) = "SkipErrors" Then 
				ErrorMessagesArray = ErrorMessagesArray + ?(ErrorMessagesArray = "","",Chars.LF)+StrErrorDescription;
				ErrorCounter = ErrorCounter + 1;
			EndIf;
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
		StrErrorDescription = "Document Line: "+LastLineNumber+ Chars.LF+ ErrorDescription();
		If TrimAll(ErrorProcessing) = "StopOnError" Then 
			ErrorText = "ERROR" + Chars.LF + StrErrorDescription;
			LongActions.InformActionProgres(Counter-1,ErrorText);
			Return;
		ElsIf TrimAll(ErrorProcessing) = "SkipErrors" Then 
			ErrorMessagesArray = ErrorMessagesArray + ?(ErrorMessagesArray = "","",Chars.LF)+StrErrorDescription;
			ErrorCounter = ErrorCounter + 1;
		EndIf;
	EndTry;	

	If ErrorMessagesArray <> "" Then 
		ErrorText = "ERROR" + Chars.LF + ErrorMessagesArray;
		LongActions.InformActionProgres(Counter - ErrorCounter,ErrorText);
	Else 
		LongActions.InformActionProgres(Counter - ErrorCounter,"");	
	EndIf;	
	
EndProcedure

Procedure CreateSalesInvoiceCSV(Date, Date2, ItemDataSet, AdParams) Export
	
	LongActions.InformActionProgres(0,"Current progress: 0%");
	
	UpdateOption = AdParams.UpdateOption;
	ErrorProcessing = AdParams.ErrorProcessing;
	ErrorMessagesArray = "";
	ErrorCounter = 0;
	
	Counter = 0;
	Counter10 = 0;
	MaxCount = ItemDataSet.count();
	
	PrevNumber = Undefined;
	DocObject = Undefined;
	DocPost = False;
	
	QuantityPrecision = GeneralFunctionsReusable.DefaultQuantityPrecision();
	
	If MaxCount > 1000 then 
		ReportStep = 100;
	Else 
		ReportStep = MaxCount/100;
	EndIf;	
	For Each DataLine In ItemDataSet Do
		
		Progress = (Counter/MaxCount); 
		If INT(Counter/ReportStep)*ReportStep = Counter then
			Counter10 = Int(Progress*100);
			If TrimAll(ErrorProcessing) = "SkipErrors" and  ErrorMessagesArray <> "" Then
				AdNotificationParams = New Structure;
				AdNotificationParams.Insert("Error",ErrorMessagesArray);
				LongActions.InformActionProgres(Counter,"Current progress: "+(Counter10) +"%", AdNotificationParams);
			Else 	
				LongActions.InformActionProgres(Counter,"Current progress: "+(Counter10) +"%");
			EndIf;	
		EndIf;
		Counter = Counter + 1;
		LastLineNumber = DataLine.LineNumber;
		
		Try
			If PrevNumber <> DataLine.Number  Then
				PrevNumber = DataLine.Number;
								
				// Writing previous document
				If DocObject <> Undefined Then
					
					SalesInvoiceRecalculateTotals(DocObject);
					//DocFillingPreCheck = SalesInvoiceCheckOrders(DocObject,AdParams);
					DocFillingPreCheck = SalesInvoiceCheckOrders(DocObject);
					If DocFillingPreCheck <> "" Then 
						If DocPost Then 
							Raise DocFillingPreCheck; 
						Else 
							CommonUseClientServer.MessageToUser("Non fatal error, Document Line: "+LastLineNumber+ Chars.LF+ DocFillingPreCheck);
						EndIf;	
					EndIf;	
					
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
				ElsIf DocObject.Currency.IsEmpty() Then 
					If Not DocObject.Company.DefaultCurrency.IsEmpty() Then 
						DocObject.Currency = DocObject.Company.DefaultCurrency;
					Else
						DocObject.Currency = Constants.DefaultCurrency.Get();
					EndIf;
					DocObject.ExchangeRate = GeneralFunctions.GetExchangeRate(DocObject.Date, DocObject.Currency);
				EndIf;
				
				
				If ValueIsFilled(DataLine.ARAccount) Then 
					DocObject.ARAccount = DataLine.ARAccount;
				Elsif DocObject.ARAccount.IsEmpty() Then 
					If Not DocObject.Currency.DefaultARAccount.IsEmpty() Then 
						DocObject.ARAccount = DocObject.Currency.DefaultARAccount;
					ElsIf Not DocObject.Company.ARAccount.IsEmpty() Then 
						DocObject.ARAccount = DocObject.Company.ARAccount;
					Else 	
						DocObject.ARAccount = Constants.DefaultCurrency.Get().DefaultARAccount;
					EndIf;
				EndIf;
				
				If ValueIsFilled(DataLine.DueDate) Then 
					DocObject.DueDate = DataLine.DueDate;
				EndIf;
				
				If ValueIsFilled(DataLine.SalesPerson) Then 
					DocObject.SalesPerson = DataLine.SalesPerson;
				EndIf;
				
				If ValueIsFilled(DataLine.Location) Then 
					DocObject[AdParams.LocationAttributeName]	= DataLine.Location;
				Else 	
					DocObject[AdParams.LocationAttributeName]	= GeneralFunctions.GetDefaultLocation();
				EndIf;
				
				If ValueIsFilled(DataLine.DeliveryDate) Then 
					DocObject[AdParams.DeliveryDateActualAttributeName] = DataLine.DeliveryDate;
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
				
				If ValueIsFilled(DataLine.Shipping) Then 
					DocObject.Shipping = DataLine.Shipping;
				EndIf;
				
				DocPost = (DataLine.ToPost = True);
				
			EndIf;
			
			DocLineItem = DocObject.LineItems.Add();
			FillPropertyValues(DocLineItem, DocObject, ""+AdParams.LocationAttributeName+", "+ AdParams.DeliveryDateActualAttributeName+", Project, Class");
			
			If ValueIsFilled(DataLine.Product) Then 
				DocLineItem.Product = DataLine.Product;
				TableSectionRow = New Structure("LineNumber, LineID, Product, ProductDescription, UseLotsSerials, LotOwner, Lot, SerialNumbers, UnitSet, QtyUnits, Unit, QtyUM, UM, Ordered, Backorder, Shipped, Invoiced, PriceUnits, LineTotal, Taxable, TaxableAmount, Order, Shipment, Location, LocationActual, DeliveryDate, DeliveryDateActual, Project, Class, AvataxTaxCode, DiscountIsTaxable");
				FillPropertyValues(TableSectionRow, DocLineItem);
				
				SalesInvoiceLineItemsProductOnChangeAtServer(TableSectionRow,DocObject);
				FillPropertyValues(DocLineItem, TableSectionRow);
			Else 
				DocLineItem.Product = Catalogs.Products.FindByCode("comment",True);
			EndIf;
			
			Try
				DocLineItem.Location = DocLineItem.LocationActual;
				DocLineItem.DeliveryDate = DocLineItem.DeliveryDateActual;
			Except
			EndTry;	
			                                                          			
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
			
			//TableSectionRow.PriceUnits = Round(TableSectionRow.PriceUnits, GeneralFunctionsReusable.PricePrecisionForOneItem(TableSectionRow.Product));
	 		DocLineItem.LineTotal = Round(Round(DocLineItem.QtyUnits, QuantityPrecision) * DocLineItem.PriceUnits, 2);
			
			If ValueIsFilled(DataLine.LineClass) Then 
				DocLineItem.Class = DataLine.LineClass;
			EndIf;
			
			If ValueIsFilled(DataLine.LineOrder) Then 
				DocLineItem.Order = DataLine.LineOrder;
				SalesInvoiceFillEmptyLineAttributesFromOrder(DocLineItem);				
			EndIf;		
			
			If ValueIsFilled(DataLine.Taxable) Then 
				DocLineItem.Taxable = DataLine.Taxable;
				SalesInvoiceLineItemsTaxableOnChangeAtServer(DocLineItem,DocObject);
			EndIf;
			
			
		Except
			StrErrorDescription = "Document Line: "+LastLineNumber+ Chars.LF+ ErrorDescription();
			If TrimAll(ErrorProcessing) = "StopOnError" Then 
				ErrorText = "ERROR" + Chars.LF + StrErrorDescription;
				LongActions.InformActionProgres(Counter-1,ErrorText);
				Return;
			ElsIf TrimAll(ErrorProcessing) = "SkipErrors" Then 
				ErrorMessagesArray = ErrorMessagesArray + ?(ErrorMessagesArray = "","",Chars.LF)+StrErrorDescription;
				ErrorCounter = ErrorCounter + 1;
			EndIf;
		EndTry;
		
	EndDo;
	
	Try
		If DocObject <> Undefined Then
			SalesInvoiceRecalculateTotals(DocObject);
			//DocFillingPreCheck = SalesInvoiceCheckOrders(DocObject,AdParams);
			DocFillingPreCheck = SalesInvoiceCheckOrders(DocObject);
			If DocFillingPreCheck <> "" Then 
				If DocPost Then 
					Raise DocFillingPreCheck; 
				Else 
					CommonUseClientServer.MessageToUser("Non fatal error, Document Line: "+LastLineNumber+ Chars.LF+ DocFillingPreCheck);
				EndIf;	
			EndIf;	
			DocObject.Write(?(DocPost,DocumentWriteMode.Posting,DocumentWriteMode.Write));
		EndIf;	
	Except
		StrErrorDescription = "Document Line: "+LastLineNumber+ Chars.LF+ ErrorDescription();
		If TrimAll(ErrorProcessing) = "StopOnError" Then 
			ErrorText = "ERROR" + Chars.LF + StrErrorDescription;
			LongActions.InformActionProgres(Counter-1,ErrorText);
			Return;
		ElsIf TrimAll(ErrorProcessing) = "SkipErrors" Then 
			ErrorMessagesArray = ErrorMessagesArray + ?(ErrorMessagesArray = "","",Chars.LF)+StrErrorDescription;
			ErrorCounter = ErrorCounter + 1;
		EndIf;
	EndTry;	

	If ErrorMessagesArray <> "" Then 
		ErrorText = "ERROR" + Chars.LF + ErrorMessagesArray;
		LongActions.InformActionProgres(Counter - ErrorCounter,ErrorText);
	Else 
		LongActions.InformActionProgres(Counter - ErrorCounter,"");	
	EndIf;	
	
EndProcedure

Procedure CreateCashReceiptCSV(Date, Date2, ItemDataSet, AdParams) Export
	
	LongActions.InformActionProgres(0,"Current progress: 0%");
	
	UpdateOption = AdParams.UpdateOption;
	ErrorProcessing = AdParams.ErrorProcessing;
	ErrorMessagesArray = "";
	ErrorCounter = 0;
	
	Counter = 0;
	Counter10 = 0;
	MaxCount = ItemDataSet.count();
	
	PrevSearchBase = New Structure("Number,DocDate,Company,RefNum");
	DocObject = Undefined;
	DocPost = False;
	
	QuantityPrecision = GeneralFunctionsReusable.DefaultQuantityPrecision();
	
	If MaxCount > 1000 then 
		ReportStep = 100;
	Else 
		ReportStep = MaxCount/100;
	EndIf;	
	For Each DataLine In ItemDataSet Do
		
		Progress = (Counter/MaxCount); 
		If INT(Counter/ReportStep)*ReportStep = Counter then
			Counter10 = Int(Progress*100);
			If TrimAll(ErrorProcessing) = "SkipErrors" and  ErrorMessagesArray <> "" Then
				AdNotificationParams = New Structure;
				AdNotificationParams.Insert("Error",ErrorMessagesArray);
				LongActions.InformActionProgres(Counter,"Current progress: "+(Counter10) +"%", AdNotificationParams);
			Else 	
				LongActions.InformActionProgres(Counter,"Current progress: "+(Counter10) +"%");
			EndIf;	
		EndIf;	
		Counter = Counter + 1;
		LastLineNumber = DataLine.LineNumber;
		
		Try
			MarkOfNewDoc = False;
			For Each StructItem in PrevSearchBase Do
				If StructItem.Value <> DataLine[StructItem.Key] Then 
					MarkOfNewDoc = True
				EndIf;	
			EndDo;	
			
			If MarkOfNewDoc Then 
				FillPropertyValues(PrevSearchBase,DataLine);
								
				// Writing previous document
				If DocObject <> Undefined Then
					CashReceipRecalculateTotals(DocObject);
					DocObject.Write(?(DocPost,DocumentWriteMode.Posting,DocumentWriteMode.Write));
				EndIf;	
				
				// First row, need to fill up document, Lines will be filled later
				ExistingDoc = FindDocumentByAttributes("CashReceipt",DataLine.Number, Date(DataLine.DocDate), DataLine.Company, DataLine.RefNum);
				If ValueIsFilled(ExistingDoc) Then 
					DocObject = ExistingDoc.GetObject();
					DocObject.LineItems.Clear();
					DocObject.CreditMemos.Clear();
					DocObject.CashPayment = 0;
				Else
					DocObject = Documents.CashReceipt.CreateDocument();
					DocObject.Number = DataLine.Number;
					If Not ValueIsFilled(DocObject.Number) Then 
						DocObject.SetNewNumber();
					EndIf;	
				EndIf;
				// Filling document attributes
				DocObject.Date = Date(DataLine.DocDate);
				DocObject.Company = DataLine.Company;
				
				CashReceiptCompanyOnChange(DocObject);
				
				If ValueIsFilled(DataLine.RefNum) Then 
					DocObject.RefNum = DataLine.RefNum;
				EndIf;
				
				If ValueIsFilled(DataLine.Currency) Then 
					DocObject.Currency = DataLine.Currency;
					DocObject.ExchangeRate = GeneralFunctions.GetExchangeRate(DocObject.Date, DocObject.Currency);
				ElsIf DocObject.Currency.IsEmpty() Then 
					If Not DocObject.Company.DefaultCurrency.IsEmpty() Then 
						DocObject.Currency = DocObject.Company.DefaultCurrency;
					Else
						DocObject.Currency = Constants.DefaultCurrency.Get();
					EndIf;
					DocObject.ExchangeRate = GeneralFunctions.GetExchangeRate(DocObject.Date, DocObject.Currency);
				EndIf;
				
				
				If ValueIsFilled(DataLine.ARAccount) Then 
					DocObject.ARAccount = DataLine.ARAccount;
				Elsif DocObject.ARAccount.IsEmpty() Then 
					If Not DocObject.Currency.DefaultARAccount.IsEmpty() Then 
						DocObject.ARAccount = DocObject.Currency.DefaultARAccount;
					ElsIf Not DocObject.Company.ARAccount.IsEmpty() Then 
						DocObject.ARAccount = DocObject.Company.ARAccount;
					Else 	
						DocObject.ARAccount = Constants.DefaultCurrency.Get().DefaultARAccount;
					EndIf;
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
				
				If ValueIsFilled(DataLine.Overpayment) Then 
					// Overpayment can be only the same for whole document
					DocObject.UnappliedPayment = DataLine.Overpayment;
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
				
			ElsIf DataLine.TableType = "0" then
				DocLineItem = New Structure("Payment");  // hot fix
				
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
			
		Except
			StrErrorDescription = "Document Line: "+LastLineNumber+ Chars.LF+ ErrorDescription();
			If TrimAll(ErrorProcessing) = "StopOnError" Then 
				ErrorText = "ERROR" + Chars.LF + StrErrorDescription;
				LongActions.InformActionProgres(Counter-1,ErrorText);
				Return;
			ElsIf TrimAll(ErrorProcessing) = "SkipErrors" Then 
				ErrorMessagesArray = ErrorMessagesArray + ?(ErrorMessagesArray = "","",Chars.LF)+StrErrorDescription;
				ErrorCounter = ErrorCounter + 1;
			EndIf;
		EndTry;
		
	EndDo;
	
	Try
		If DocObject <> Undefined Then
			CashReceipRecalculateTotals(DocObject);
			DocObject.Write(?(DocPost,DocumentWriteMode.Posting,DocumentWriteMode.Write));
		EndIf;	
	Except
		StrErrorDescription = "Document Line: "+LastLineNumber+ Chars.LF+ ErrorDescription();
		If TrimAll(ErrorProcessing) = "StopOnError" Then 
			ErrorText = "ERROR" + Chars.LF + StrErrorDescription;
			LongActions.InformActionProgres(Counter-1,ErrorText);
			Return;
		ElsIf TrimAll(ErrorProcessing) = "SkipErrors" Then 
			ErrorMessagesArray = ErrorMessagesArray + ?(ErrorMessagesArray = "","",Chars.LF)+StrErrorDescription;
			ErrorCounter = ErrorCounter + 1;
		EndIf;
	EndTry;	

	If ErrorMessagesArray <> "" Then 
		ErrorText = "ERROR" + Chars.LF + ErrorMessagesArray;
		LongActions.InformActionProgres(Counter - ErrorCounter,ErrorText);
	Else 
		LongActions.InformActionProgres(Counter - ErrorCounter,"");	
	EndIf;	
	
EndProcedure

Procedure CreateSalesOrderCSV(Date, Date2, ItemDataSet, AdParams) Export
	
	LongActions.InformActionProgres(0,"Current progress: 0%");
	
	UpdateOption = AdParams.UpdateOption;
	ErrorProcessing = AdParams.ErrorProcessing;
	ErrorMessagesArray = "";
	ErrorCounter = 0;
	
	Counter = 0;
	Counter10 = 0;
	MaxCount = ItemDataSet.count();
	
	PrevNumber = Undefined;
	DocObject = Undefined;
	DocPost = False;
	
	QuantityPrecision = GeneralFunctionsReusable.DefaultQuantityPrecision();
	
	If MaxCount > 1000 then 
		ReportStep = 100;
	Else 
		ReportStep = MaxCount/100;
	EndIf;	
	For Each DataLine In ItemDataSet Do
		
		Progress = (Counter/MaxCount); 
		If INT(Counter/ReportStep)*ReportStep = Counter then
			Counter10 = Int(Progress*100);
			If TrimAll(ErrorProcessing) = "SkipErrors" and  ErrorMessagesArray <> "" Then
				AdNotificationParams = New Structure;
				AdNotificationParams.Insert("Error",ErrorMessagesArray);
				LongActions.InformActionProgres(Counter,"Current progress: "+(Counter10) +"%", AdNotificationParams);
			Else 	
				LongActions.InformActionProgres(Counter,"Current progress: "+(Counter10) +"%");
			EndIf;	
		EndIf;	
		Counter = Counter + 1;
		LastLineNumber = DataLine.LineNumber;
		
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
				
				If DocObject.Currency.IsEmpty() Then 
					If Not DocObject.Company.DefaultCurrency.IsEmpty() Then 
						DocObject.Currency = DocObject.Company.DefaultCurrency;
					Else
						DocObject.Currency = Constants.DefaultCurrency.Get();
					EndIf;
					DocObject.ExchangeRate = GeneralFunctions.GetExchangeRate(DocObject.Date, DocObject.Currency);
				EndIf;
								
				If ValueIsFilled(DataLine.RefNum) Then 
					DocObject.RefNum = DataLine.RefNum;
				EndIf;
				
				If ValueIsFilled(DataLine.SalesPerson) Then 
					DocObject.SalesPerson = DataLine.SalesPerson;
				EndIf;
				
				DocObject.Location 	= GeneralFunctions.GetDefaultLocation();
				
				If ValueIsFilled(DataLine.DeliveryDate) Then 
					DocObject.DeliveryDate = DataLine.DeliveryDate;
				EndIf;
				
				If ValueIsFilled(DataLine.ShippingCost) Then 
					DocObject.Shipping = Number(DataLine.ShippingCost);
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
			
			If ValueIsFilled(DataLine.Product) Then 
				DocLineItem.Product = DataLine.Product;
				
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
			
			If ValueIsFilled(DataLine.LineClass) Then 
				DocLineItem.Class = DataLine.LineClass;
			EndIf;
			
			If ValueIsFilled(DataLine.Taxable) Then 
				DocLineItem.Taxable = DataLine.Taxable;
			EndIf;
			
			
		Except
			StrErrorDescription = "Document Line: "+LastLineNumber+ Chars.LF+ ErrorDescription();
			If TrimAll(ErrorProcessing) = "StopOnError" Then 
				ErrorText = "ERROR" + Chars.LF + StrErrorDescription;
				LongActions.InformActionProgres(Counter-1,ErrorText);
				Return;
			ElsIf TrimAll(ErrorProcessing) = "SkipErrors" Then 
				ErrorMessagesArray = ErrorMessagesArray + ?(ErrorMessagesArray = "","",Chars.LF)+StrErrorDescription;
				ErrorCounter = ErrorCounter + 1;
			EndIf;
		EndTry;
		
	EndDo;
	
	Try
		If DocObject <> Undefined Then
			SalesOrderRecalculateTotals(DocObject);
			DocObject.Write(?(DocPost,DocumentWriteMode.Posting,DocumentWriteMode.Write));
		EndIf;	
	Except
		StrErrorDescription = "Document Line: "+LastLineNumber+ Chars.LF+ ErrorDescription();
		If TrimAll(ErrorProcessing) = "StopOnError" Then 
			ErrorText = "ERROR" + Chars.LF + StrErrorDescription;
			LongActions.InformActionProgres(Counter-1,ErrorText);
			Return;
		ElsIf TrimAll(ErrorProcessing) = "SkipErrors" Then 
			ErrorMessagesArray = ErrorMessagesArray + ?(ErrorMessagesArray = "","",Chars.LF)+StrErrorDescription;
			ErrorCounter = ErrorCounter + 1;
		EndIf;
	EndTry;	

	If ErrorMessagesArray <> "" Then 
		ErrorText = "ERROR" + Chars.LF + ErrorMessagesArray;
		LongActions.InformActionProgres(Counter - ErrorCounter,ErrorText);
	Else 
		LongActions.InformActionProgres(Counter - ErrorCounter,"");	
	EndIf;	
	
EndProcedure

Procedure CreateCreditMemoCSV(Date, Date2, ItemDataSet, AdParams) Export
	
	LongActions.InformActionProgres(0,"Current progress: 0%");
	
	UpdateOption = AdParams.UpdateOption;
	ErrorProcessing = AdParams.ErrorProcessing;
	ErrorMessagesArray = "";
	ErrorCounter = 0;
	
	Counter = 0;
	Counter10 = 0;
	MaxCount = ItemDataSet.count();
	
	PrevNumber = Undefined;
	DocObject = Undefined;
	DocPost = False;
	
	QuantityPrecision = GeneralFunctionsReusable.DefaultQuantityPrecision();
	
	If MaxCount > 1000 then 
		ReportStep = 100;
	Else 
		ReportStep = MaxCount/100;
	EndIf;	
	For Each DataLine In ItemDataSet Do
		
		Progress = (Counter/MaxCount); 
		If INT(Counter/ReportStep)*ReportStep = Counter then
			Counter10 = Int(Progress*100);
			If TrimAll(ErrorProcessing) = "SkipErrors" and  ErrorMessagesArray <> "" Then
				AdNotificationParams = New Structure;
				AdNotificationParams.Insert("Error",ErrorMessagesArray);
				LongActions.InformActionProgres(Counter,"Current progress: "+(Counter10) +"%", AdNotificationParams);
			Else 	
				LongActions.InformActionProgres(Counter,"Current progress: "+(Counter10) +"%");
			EndIf;	
		EndIf;
		Counter = Counter + 1;
		LastLineNumber = DataLine.LineNumber;
		
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
				
				DocObject.Company = DataLine.Company;
				
				If ValueIsFilled(DataLine.ShipFromAddr) Then 
					DocObject.ShipFrom = Catalogs.Addresses.FindByDescription(DataLine.ShipFromAddr,,,DocObject.Company);
				EndIf;
				
				SalesReturnCompanyOnChangeAtServer(DocObject);
				
				
				If ValueIsFilled(DataLine.Currency) Then 
					DocObject.Currency = DataLine.Currency;
					DocObject.ExchangeRate = GeneralFunctions.GetExchangeRate(DocObject.Date, DocObject.Currency);
				ElsIf DocObject.Currency.IsEmpty() Then 
					If Not DocObject.Company.DefaultCurrency.IsEmpty() Then 
						DocObject.Currency = DocObject.Company.DefaultCurrency;
					Else
						DocObject.Currency = Constants.DefaultCurrency.Get();
					EndIf;
					DocObject.ExchangeRate = GeneralFunctions.GetExchangeRate(DocObject.Date, DocObject.Currency);
				EndIf;
				
				
				If ValueIsFilled(DataLine.ARAccount) Then 
					DocObject.ARAccount = DataLine.ARAccount;
				Elsif DocObject.ARAccount.IsEmpty() Then 
					If Not DocObject.Currency.DefaultARAccount.IsEmpty() Then 
						DocObject.ARAccount = DocObject.Currency.DefaultARAccount;
					ElsIf Not DocObject.Company.ARAccount.IsEmpty() Then 
						DocObject.ARAccount = DocObject.Company.ARAccount;
					Else 	
						DocObject.ARAccount = Constants.DefaultCurrency.Get().DefaultARAccount;
					EndIf;
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
			EndIf;
			
			
		Except
			StrErrorDescription = "Document Line: "+LastLineNumber+ Chars.LF+ ErrorDescription();
			If TrimAll(ErrorProcessing) = "StopOnError" Then 
				ErrorText = "ERROR" + Chars.LF + StrErrorDescription;
				LongActions.InformActionProgres(Counter-1,ErrorText);
				Return;
			ElsIf TrimAll(ErrorProcessing) = "SkipErrors" Then 
				ErrorMessagesArray = ErrorMessagesArray + ?(ErrorMessagesArray = "","",Chars.LF)+StrErrorDescription;
				ErrorCounter = ErrorCounter + 1;
			EndIf;
		EndTry;
		
	EndDo;
	
	Try
		If DocObject <> Undefined Then
			SalesReturnRecalculateTotals(DocObject);
			DocObject.Write(?(DocPost,DocumentWriteMode.Posting,DocumentWriteMode.Write));
		EndIf;	
	Except
		StrErrorDescription = "Document Line: "+LastLineNumber+ Chars.LF+ ErrorDescription();
		If TrimAll(ErrorProcessing) = "StopOnError" Then 
			ErrorText = "ERROR" + Chars.LF + StrErrorDescription;
			LongActions.InformActionProgres(Counter-1,ErrorText);
			Return;
		ElsIf TrimAll(ErrorProcessing) = "SkipErrors" Then 
			ErrorMessagesArray = ErrorMessagesArray + ?(ErrorMessagesArray = "","",Chars.LF)+StrErrorDescription;
			ErrorCounter = ErrorCounter + 1;
		EndIf;
	EndTry;	
	
	If ErrorMessagesArray <> "" Then 
		ErrorText = "ERROR" + Chars.LF + ErrorMessagesArray;
		LongActions.InformActionProgres(Counter - ErrorCounter,ErrorText);
	Else 
		LongActions.InformActionProgres(Counter - ErrorCounter,"");	
	EndIf;	

EndProcedure

Procedure CreateDepositCSV(ItemDataSet, AdParams) Export
	
	LongActions.InformActionProgres(0,"Current progress: 0%");
	
	UpdateOption = AdParams.UpdateOption;
	ErrorProcessing = AdParams.ErrorProcessing;
	ErrorMessagesArray = "";
	ErrorCounter = 0;
	
	Counter = 0;
	Counter10 = 0;
	MaxCount = ItemDataSet.count();
	
	PrevSearchBase = New Structure("Number,DepositDate,DepositBankAccount");
	DocObject = Undefined;
	DocPost = False;
	
	QuantityPrecision = GeneralFunctionsReusable.DefaultQuantityPrecision();
	DefaultCurrency = GeneralFunctionsReusable.DefaultCurrency();
	
	If MaxCount > 1000 then 
		ReportStep = 100;
	Else 
		ReportStep = MaxCount/100;
	EndIf;	
	For Each DataLine In ItemDataSet Do
		
		Progress = (Counter/MaxCount); 
		If INT(Counter/ReportStep)*ReportStep = Counter then
			Counter10 = Int(Progress*100);
			If TrimAll(ErrorProcessing) = "SkipErrors" and  ErrorMessagesArray <> "" Then
				AdNotificationParams = New Structure;
				AdNotificationParams.Insert("Error",ErrorMessagesArray);
				LongActions.InformActionProgres(Counter,"Current progress: "+(Counter10) +"%", AdNotificationParams);
			Else 	
				LongActions.InformActionProgres(Counter,"Current progress: "+(Counter10) +"%");
			EndIf;	
		EndIf;
		Counter = Counter + 1;
		LastLineNumber = DataLine.LineNumber;
		
		Try
			
			MarkOfNewDoc = False;
			For Each StructItem in PrevSearchBase Do
				If StructItem.Value <> DataLine[StructItem.Key] Then 
					MarkOfNewDoc = True
				EndIf;	
			EndDo;	
			
			If MarkOfNewDoc Then 
				If DocObject <> Undefined Then
					DocObject.TotalDeposits = DocObject.LineItems.Total("DocumentTotal");
					DocObject.TotalDepositsRC = DocObject.LineItems.Total("DocumentTotalRC");
					DocObject.DocumentTotal = DocObject.TotalDeposits + DocObject.Accounts.Total("Amount");
					DocObject.DocumentTotalRC = DocObject.TotalDepositsRC + DocObject.Accounts.Total("Amount");
					DocObject.Write(?(DocPost,DocumentWriteMode.Posting,DocumentWriteMode.Write));
				EndIf;	
				
				FillPropertyValues(PrevSearchBase,DataLine);
				ExistingDoc = FindDocumentByAttributes("Deposit",DataLine.Number,Date(DataLine.DepositDate)+1,,,DataLine.DepositBankAccount);
				
				If ValueIsFilled(ExistingDoc) Then 
					DocObject = ExistingDoc.GetObject();
					DocObject.LineItems.Clear();
					DocObject.Accounts.Clear();
				Else
					DocObject = Documents.Deposit.CreateDocument();
					DocObject.Number = DataLine.Number;
					If Not ValueIsFilled(DocObject.Number) Then 
						DocObject.SetNewNumber();
					EndIf;	
				EndIf;
				
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
				
			EndIf;
			
			///////////////////////////////////////////////////////////////////
			
			If ValueIsFilled(DataLine.LineAccount) Then 
				
				DocLineItem = DocObject.Accounts.Add();
				
				If ValueIsFilled(DataLine.LineCompany) Then 
					DocLineItem.Company = DataLine.LineCompany;
				EndIf;
				
				If ValueIsFilled(DataLine.LineAccount) Then 
					DocLineItem.Account = DataLine.LineAccount;
				EndIf;
				
				If ValueIsFilled(DataLine.LineClass) Then 
					DocLineItem.Class = DataLine.LineClass;
				EndIf;
				
				If ValueIsFilled(DataLine.LineProject) Then 
					DocLineItem.Project = DataLine.LineProject;
				EndIf;
				
				If ValueIsFilled(DataLine.LineMemo) Then 
					DocLineItem.Memo = DataLine.LineMemo;
				EndIf;
				
				If ValueIsFilled(DataLine.LineAmount) Then 
					DocLineItem.Amount = DataLine.LineAmount;
				EndIf;
				
			ElsIf ValueIsFilled(DataLine.LineDocNumber) Then 
				
				DocLineItem = DocObject.LineItems.Add();
				
				If ValueIsFilled(DataLine.LineDocType) Then 
					If ValueIsFilled(DataLine.LineDocNumber) Then 
						If Find(Upper(DataLine.LineDocType),"RECEIPT") > 0 Then 
							DocLineItem.Document = Documents.CashReceipt.FindByNumber(TrimAll(DataLine.LineDocNumber));
						ElsIf Find(Upper(DataLine.LineDocType),"SALE") > 0 Then 	
							DocLineItem.Document = Documents.CashSale.FindByNumber(TrimAll(DataLine.LineDocNumber));
						EndIf;	
					EndIf;	
				EndIf;
				
				If ValueIsFilled(DataLine.LineCompany) Then 
					DocLineItem.Customer = DataLine.LineCompany;
				EndIf;
				
				If ValueIsFilled(DataLine.LineCurrency) Then 
					DocLineItem.Currency = DataLine.LineCurrency;
				EndIf;
				
				If ValueIsFilled(DataLine.LineAmount) Then 
					DocLineItem.Payment = True;
					DocLineItem.DocumentTotal = DataLine.LineAmount;
					DocLineItem.DocumentTotalRC = DataLine.LineAmount;
				ElsIf ValueIsFilled(DocLineItem.Document) Then 
					DocLineItem.Payment = True;
					DocLineItem.DocumentTotal = DocLineItem.Document.DocumentTotal;
					DocLineItem.DocumentTotalRC = DocLineItem.Document.DocumentTotalRC;
				EndIf;
			EndIf;
			
		Except
			StrErrorDescription = "Document Line: "+LastLineNumber+ Chars.LF+ ErrorDescription();
			If TrimAll(ErrorProcessing) = "StopOnError" Then 
				ErrorText = "ERROR" + Chars.LF + StrErrorDescription;
				LongActions.InformActionProgres(Counter-1,ErrorText);
				Return;
			ElsIf TrimAll(ErrorProcessing) = "SkipErrors" Then 
				ErrorMessagesArray = ErrorMessagesArray + ?(ErrorMessagesArray = "","",Chars.LF)+StrErrorDescription;
				ErrorCounter = ErrorCounter + 1;
			EndIf;
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
		StrErrorDescription = "Document Line: "+LastLineNumber+ Chars.LF+ ErrorDescription();
		If TrimAll(ErrorProcessing) = "StopOnError" Then 
			ErrorText = "ERROR" + Chars.LF + StrErrorDescription;
			LongActions.InformActionProgres(Counter-1,ErrorText);
			Return;
		ElsIf TrimAll(ErrorProcessing) = "SkipErrors" Then 
			ErrorMessagesArray = ErrorMessagesArray + ?(ErrorMessagesArray = "","",Chars.LF)+StrErrorDescription;
			ErrorCounter = ErrorCounter + 1;
		EndIf;
	EndTry;	

	If ErrorMessagesArray <> "" Then 
		ErrorText = "ERROR" + Chars.LF + ErrorMessagesArray;
		LongActions.InformActionProgres(Counter - ErrorCounter,ErrorText);
	Else 
		LongActions.InformActionProgres(Counter - ErrorCounter,"");	
	EndIf;	
	
EndProcedure

Procedure CreateBankTransferCSV(ItemDataSet, AdParams) Export
	
	LongActions.InformActionProgres(0,"Current progress: 0%");
	
	UpdateOption = AdParams.UpdateOption;
	ErrorProcessing = AdParams.ErrorProcessing;
	ErrorMessagesArray = "";
	ErrorCounter = 0;
	
	Counter = 0;
	Counter10 = 0;
	MaxCount = ItemDataSet.count();
	
	DocObject = Undefined;
	DocPost = False;
	
	QuantityPrecision = GeneralFunctionsReusable.DefaultQuantityPrecision();
	DefaultCurrency = GeneralFunctionsReusable.DefaultCurrency();
	
	If MaxCount > 1000 then 
		ReportStep = 100;
	Else 
		ReportStep = MaxCount/100;
	EndIf;	
	For Each DataLine In ItemDataSet Do
		
		Progress = (Counter/MaxCount); 
		If INT(Counter/ReportStep)*ReportStep = Counter then
			Counter10 = Int(Progress*100);
			If TrimAll(ErrorProcessing) = "SkipErrors" and  ErrorMessagesArray <> "" Then
				AdNotificationParams = New Structure;
				AdNotificationParams.Insert("Error",ErrorMessagesArray);
				LongActions.InformActionProgres(Counter,"Current progress: "+(Counter10) +"%", AdNotificationParams);
			Else 	
				LongActions.InformActionProgres(Counter,"Current progress: "+(Counter10) +"%");
			EndIf;	
		EndIf;
		Counter = Counter + 1;
		LastLineNumber = DataLine.LineNumber;
		
		Try
			
			DocObject = Documents.BankTransfer.CreateDocument();
			DocObject.Number = DataLine.Number;
			If Not ValueIsFilled(DocObject.Number) Then 
				DocObject.SetNewNumber();
			EndIf;	
			
			DocObject.Date = Date(DataLine.DocDate);
			
			DocObject.AccountFrom = DataLine.AccountFrom;
			DocObject.AccountTo = DataLine.AccountTo;
			DocObject.Amount = DataLine.Amount;
			DocObject.Memo = DataLine.Memo;
			DocObject.Currency = DocObject.AccountFrom.Currency;
			If DocObject.Currency.IsEmpty() Then 
				DocObject.Currency = Constants.DefaultCurrency.Get();
				DocObject.ExchangeRate = 1;
				DocObject.AmountTo = DocObject.Amount;
			Else 
				BankTransferRecalculateExchangeRate(DocObject);
			EndIf;	
			
			DocPost = True;
			DocObject.Write(?(DocPost,DocumentWriteMode.Posting,DocumentWriteMode.Write));
			
		Except
			StrErrorDescription = "Document Line: "+LastLineNumber+ Chars.LF+ ErrorDescription();
			If TrimAll(ErrorProcessing) = "StopOnError" Then 
				ErrorText = "ERROR" + Chars.LF + StrErrorDescription;
				LongActions.InformActionProgres(Counter-1,ErrorText);
				Return;
			ElsIf TrimAll(ErrorProcessing) = "SkipErrors" Then 
				ErrorMessagesArray = ErrorMessagesArray + ?(ErrorMessagesArray = "","",Chars.LF)+StrErrorDescription;
				ErrorCounter = ErrorCounter + 1;
			EndIf;
		EndTry;
		
	EndDo;
	
	If ErrorMessagesArray <> "" Then 
		ErrorText = "ERROR" + Chars.LF + ErrorMessagesArray;
		LongActions.InformActionProgres(Counter - ErrorCounter,ErrorText);
	Else 
		LongActions.InformActionProgres(Counter - ErrorCounter,"");	
	EndIf;	
	
EndProcedure

Procedure CreateCheckCSV(ItemDataSet, AdParams) Export
	
	LongActions.InformActionProgres(0,"Current progress: 0%");
	
	UpdateOption = AdParams.UpdateOption;
	ErrorProcessing = AdParams.ErrorProcessing;
	ErrorMessagesArray = "";
	ErrorCounter = 0;
	
	Counter = 0;
	Counter10 = 0;
	MaxCount = ItemDataSet.count();
	
	PrevNumber = Undefined;
	DocObject = Undefined;
	DocPost = False;
	
	QuantityPrecision = GeneralFunctionsReusable.DefaultQuantityPrecision();
	DefaultCurrency = GeneralFunctionsReusable.DefaultCurrency();
	
	If MaxCount > 1000 then 
		ReportStep = 100;
	Else 
		ReportStep = MaxCount/100;
	EndIf;	
	For Each DataLine In ItemDataSet Do
		
		Progress = (Counter/MaxCount); 
		If INT(Counter/ReportStep)*ReportStep = Counter then
			Counter10 = Int(Progress*100);
			If TrimAll(ErrorProcessing) = "SkipErrors" and  ErrorMessagesArray <> "" Then
				AdNotificationParams = New Structure;
				AdNotificationParams.Insert("Error",ErrorMessagesArray);
				LongActions.InformActionProgres(Counter,"Current progress: "+(Counter10) +"%", AdNotificationParams);
			Else 	
				LongActions.InformActionProgres(Counter,"Current progress: "+(Counter10) +"%");
			EndIf;	
		EndIf;	
		Counter = Counter + 1;
		LastLineNumber = DataLine.LineNumber;
		
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
			StrErrorDescription = "Document Line: "+LastLineNumber+ Chars.LF+ ErrorDescription();
			If TrimAll(ErrorProcessing) = "StopOnError" Then 
				ErrorText = "ERROR" + Chars.LF + StrErrorDescription;
				LongActions.InformActionProgres(Counter-1,ErrorText);
				Return;
			ElsIf TrimAll(ErrorProcessing) = "SkipErrors" Then 
				ErrorMessagesArray = ErrorMessagesArray + ?(ErrorMessagesArray = "","",Chars.LF)+StrErrorDescription;
				ErrorCounter = ErrorCounter + 1;
			EndIf;
		EndTry;
		
	EndDo;
	
	Try
		If DocObject <> Undefined Then
			DocObject.DocumentTotal = DocObject.LineItems.Total("Amount");
			DocObject.DocumentTotalRC = DocObject.LineItems.Total("Amount") * DocObject.ExchangeRate;
			DocObject.Write(?(DocPost,DocumentWriteMode.Posting,DocumentWriteMode.Write));
		EndIf;	
	Except
		StrErrorDescription = "Document Line: "+LastLineNumber+ Chars.LF+ ErrorDescription();
		If TrimAll(ErrorProcessing) = "StopOnError" Then 
			ErrorText = "ERROR" + Chars.LF + StrErrorDescription;
			LongActions.InformActionProgres(Counter-1,ErrorText);
			Return;
		ElsIf TrimAll(ErrorProcessing) = "SkipErrors" Then 
			ErrorMessagesArray = ErrorMessagesArray + ?(ErrorMessagesArray = "","",Chars.LF)+StrErrorDescription;
			ErrorCounter = ErrorCounter + 1;
		EndIf;
	EndTry;	

	If ErrorMessagesArray <> "" Then 
		ErrorText = "ERROR" + Chars.LF + ErrorMessagesArray;
		LongActions.InformActionProgres(Counter - ErrorCounter,ErrorText);
	Else 
		LongActions.InformActionProgres(Counter - ErrorCounter,"");	
	EndIf;	
	
EndProcedure

Function FindDocumentByAttributes(Val DocType, Val DocNum, Val DocDate, Val DocCompany = Undefined, Val DocRefNumber = "", Val Account1 = Undefined,  Val Account2 = Undefined) Export
	
	DocMetaManager = Documents[DocType];
	If False then DocMetaManager = Documents.SalesInvoice; EndIf;
	
	If ValueIsFilled(DocNum) Then 
		// Number is set - looking only by code
		DocReference = DocMetaManager.FindByNumber(DocNum,DocDate);
		Return DocReference;
		
	Else 
		// If no doc number
		Query = New Query;
		Query.Text = 
		"SELECT
		|	"+DocType+".Ref
		|FROM
		|	Document."+DocType+" AS "+DocType+"
		|WHERE TRUE
		| AND "+DocType+".RefNum LIKE &RefNum
		| AND "+DocType+".Company = &Company
		| AND "+DocType+".Date = &DocDate";
		
		Query.SetParameter("RefNum", DocRefNumber);
		Query.SetParameter("Company", DocCompany);
		Query.SetParameter("DocDate", DocDate);
		Query.SetParameter("Account1", Account1);
		Query.SetParameter("Account2", Account2);
		
		If DocType = "Check" Then 
			Query.Text = StrReplace(Query.Text,"AND "+DocType+".RefNum LIKE &RefNum", "AND "+DocType+".PhysicalCheckNum LIKE &RefNum");
		ElsIf DocType = "BankTransfer" Then 	
			Query.Text = StrReplace(Query.Text,"AND "+DocType+".RefNum LIKE &RefNum", "AND "+DocType+".AccountFrom = &Account1");
			Query.Text = StrReplace(Query.Text,"AND "+DocType+".Company = &Company", "AND "+DocType+".AccountTo = &Account2");
			// No refNums for this doc types
		ElsIf DocType = "Deposit" Then 	
			Query.Text = StrReplace(Query.Text,"AND "+DocType+".RefNum LIKE &RefNum", "AND "+DocType+".BankAccount = &Account1");
			Query.Text = StrReplace(Query.Text,"AND "+DocType+".Company = &Company", " ");			
			// No refNums for this doc types
		EndIf;	
		
		If TrimAll(DocRefNumber) <> "" Then 
			QueryResult = Query.Execute();
			If Not QueryResult.IsEmpty() Then  
				SelectionDetailRecords = QueryResult.Select();
				While SelectionDetailRecords.Next() Do
					DocReference = SelectionDetailRecords.Ref;
					Return DocReference;
				EndDo;	
			Else 	
				If DocType <> "Check" Then 
					Query.Text = StrReplace(Query.Text,"AND "+DocType+".RefNum LIKE &RefNum", " ");
				Else 
					Query.Text = StrReplace(Query.Text,"AND "+DocType+".PhysicalCheckNum LIKE &RefNum", " ");
				EndIf;	
				QueryResult = Query.Execute();
				If Not QueryResult.IsEmpty() Then  
					SelectionDetailRecords = QueryResult.Select();
					While SelectionDetailRecords.Next() Do
						DocReference = SelectionDetailRecords.Ref;
						Return DocReference;
					EndDo;	
				Else 	
					Return DocMetaManager.EmptyRef();
				EndIf;	
			EndIf;	
		Else
			//
			// will work for deposits and Bank transfers with no changes
			Query.Text = StrReplace(Query.Text,"AND "+DocType+".RefNum LIKE &RefNum", " ");
			QueryResult = Query.Execute();
			If Not QueryResult.IsEmpty() Then  
				SelectionDetailRecords = QueryResult.Select();
				While SelectionDetailRecords.Next() Do
					DocReference = SelectionDetailRecords.Ref;
					Return DocReference;
				EndDo;	
			Else 	
				Return DocMetaManager.EmptyRef();
			EndIf;
		EndIf;
		
		
		
		
	EndIf;
	
	
EndFunction	

Function FindObjectByAttribute(ObjectMetaName, AttributeName, AttributeValue, NotString = False)
	
	If ValueIsFilled(AttributeValue) = False Then 
		Return Undefined;
	EndIf;	
	
	Query = New Query;
	Query.Text = 
	"SELECT 
	|	Table.Ref
	|FROM
	|	[TableName] AS Table
	|WHERE
	|	Table.[AtrName] LIKE &Value";
	Query.Text = StrReplace(Query.Text,"[TableName]",ObjectMetaName);
	Query.Text = StrReplace(Query.Text,"[AtrName]",TrimAll(AttributeName));
	If NotString Then 
		Query.Text = StrReplace(Query.Text,"LIKE"," = ");
	EndIf;	
	Query.SetParameter("Value", AttributeValue);
	
	QueryResult = Query.Execute();
	
	SelectionDetailRecords = QueryResult.Select();
	
	If SelectionDetailRecords.Next() Then 
		Return SelectionDetailRecords.Ref;
	Else
		Return Undefined;
	EndIf;
		
EndFunction	

// ++ Copied and modified from SI form module
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
		SalesTaxAcrossAgencies = SalesTax.CalculateSalesTax(Object.TaxableSubtotal, Object.SalesTaxRate, CurrentAgenciesRates);
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

	Object.UseAvatax	= False;
	If (Not Object.UseAvatax) Then
		TaxEngine = 1; //Use AccountingSuite
		If SalesTaxRate <> Object.SalesTaxRate Then
			Object.SalesTaxRate = SalesTaxRate;
		EndIf;
	Else
		TaxEngine = 2;
	EndIf;
	Object.SalesTaxAcrossAgencies.Clear();
	
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
	Try
		TableSectionRow.DeliveryDateActual = Object.DeliveryDateActual;
		TableSectionRow.LocationActual     = Object.LocationActual;
	Except
		TableSectionRow.DeliveryDate = Object.DeliveryDate;
		TableSectionRow.Location     = Object.Location;
	EndTry;	
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
	
	//SalesInvoiceUpdateInformationCurrentRow(TableSectionRow, Object);
	
EndProcedure


Procedure SalesInvoiceFillEmptyLineAttributesFromOrder(DataLine) 
	
	If False Then 
		DataLine = Documents.SalesInvoice.CreateDocument().LineItems[0];
	EndIf;
	
	Order = DataLine.Order;
	OrderLine = Undefined;
	For Each Line in Order.LineItems Do 
		If Line.Product = DataLine.Product 
		And Line.Unit = DataLine.Unit Then 
			OrderLine = Line;		
		EndIf;	
	EndDo;
	
	If OrderLine = Undefined Then 
		Return;
	EndIf;	
	
	If DataLine.Project.IsEmpty() Then 
		DataLine.Project = OrderLine.Project;
	EndIf;
	
	If DataLine.Location.IsEmpty() Then 
		DataLine.Location = OrderLine.Location;
	EndIf;
	
	If DataLine.DeliveryDate = '00010101' Then 
		DataLine.DeliveryDate = OrderLine.DeliveryDate;
	EndIf;
	
	If DataLine.Class.IsEmpty() Then 
		DataLine.Class = OrderLine.Class;
	EndIf;
	
EndProcedure	

//
//Procedure SalesInvoiceUpdateInformationCurrentRow(CurrentRow,Object)
//	
//	InformationCurrentRow = "";
//	
//	If CurrentRow.Product <> Undefined And CurrentRow.Product <> PredefinedValue("Catalog.Products.EmptyRef") Then
//		
//		LineItems = Object.LineItems.Unload(, "LineNumber, Product, QtyUM, LineTotal");
//		
//		LineItem = LineItems.Find(CurrentRow.LineNumber, "LineNumber");
//		LineItem.Product   = CurrentRow.Product;
//		LineItem.QtyUM     = CurrentRow.QtyUM;
//		LineItem.LineTotal = CurrentRow.LineTotal;
//		
//		InformationCurrentRow = GeneralFunctions.GetMarginInformation(CurrentRow.Product, CurrentRow.LocationActual, CurrentRow.QtyUM, CurrentRow.LineTotal,
//																	  Object.Currency, Object.ExchangeRate, Object.DiscountPercent, LineItems); 
//		InformationCurrentRow = "" + InformationCurrentRow;
//		
//	EndIf;
//	
//EndProcedure


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

//Function SalesInvoiceCheckOrders(Object, AdParams)
Function SalesInvoiceCheckOrders(Object)	
	ErrorsCount = 0;
	MessageText = "";
	
	
	If False Then 
		Object = Documents.SalesInvoice.CreateDocument();
	EndIf;	
	
	//InvoiceLineItems = Object.LineItems.Unload(,"LineNumber, Order, Shipment, Product, Unit, "+AdParams.LocationAttributeName+", "+ AdParams.DeliveryDateActualAttributeName+", Project, Class, QtyUnits");
	InvoiceLineItems = Object.LineItems.Unload(,"LineNumber, Order, Shipment, Product, Unit, Location, DeliveryDate, Project, Class, QtyUnits");
	
	ListOfEmptyOrders = New Array;
	For Each DocLine in InvoiceLineItems Do 
		If Not ValueIsFilled(DocLine.Order) Then 
			ListOfEmptyOrders.Add(DocLine.Order);
		EndIf;	
	EndDo;	
	
	For Each RowToDelete in ListOfEmptyOrders Do 
		InvoiceLineItems.Delete(RowToDelete);	
	EndDo;	
	
	If InvoiceLineItems.Count() = 0 Then 
		Return "";
	EndIf;	
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Date", Object.Date);
	
	InvoiceLineItems.Columns.Insert(1, "Company", New TypeDescription("CatalogRef.Companies"), "", 20);
	InvoiceLineItems.FillValues(Object.Company, "Company");
	DocumentPosting.PutTemporaryTable(InvoiceLineItems, "InvoiceLineItems", Query.TempTablesManager);
	
	// 3. Request uninvoiced items for each line item.
	Query.Text = "
		|SELECT
		|	LineItems.LineNumber          AS LineNumber,
		|	LineItems.Order               AS Order,
		|	LineItems.Shipment            AS Shipment,
		|	LineItems.Product.Code        AS ProductCode,
		|	LineItems.Product.Description AS ProductDescription,
		|	CASE 
		|       WHEN LineItems.Shipment <> VALUE(Document.Shipment.EmptyRef) 
		|		    THEN OrdersRegisteredBalance.ShippedShipmentBalance - OrdersRegisteredBalance.InvoicedBalance - LineItems.QtyUnits 
		|		ELSE OrdersRegisteredBalance.QuantityBalance - OrdersRegisteredBalance.InvoicedBalance - LineItems.QtyUnits
		|   END                           AS UninvoicedQuantity	
		|FROM
		|	InvoiceLineItems AS LineItems
		|	LEFT JOIN AccumulationRegister.OrdersRegistered.Balance(&Date, (Company, Order, Shipment, Product, Unit, Location, DeliveryDate, Project, Class)
		|		      IN (SELECT Company, Order, Shipment, Product, Unit, Location, DeliveryDate, Project, Class FROM InvoiceLineItems)) AS OrdersRegisteredBalance
		|		ON  LineItems.Company      = OrdersRegisteredBalance.Company
		|		AND LineItems.Order        = OrdersRegisteredBalance.Order
		|		AND LineItems.Shipment     = OrdersRegisteredBalance.Shipment
		|		AND LineItems.Product      = OrdersRegisteredBalance.Product
		|		AND LineItems.Unit         = OrdersRegisteredBalance.Unit
		|		AND LineItems.Location	   = OrdersRegisteredBalance.Location
		|		AND LineItems.DeliveryDate = OrdersRegisteredBalance.DeliveryDate
		|		AND LineItems.Project      = OrdersRegisteredBalance.Project
		|		AND LineItems.Class        = OrdersRegisteredBalance.Class
		|ORDER BY
		|	LineItems.LineNumber";
	UninvoicedItems = Query.Execute().Unload();
	sel = Query.Execute().Select();
	While sel.Next() Do 
		dddd= sel.UninvoicedQuantity;
	EndDo;	
		
	// 4. Process status of line items and create diagnostic message.
	For Each Row In UninvoicedItems Do
		If Row.UninvoicedQuantity = Null Then
			ErrorsCount = ErrorsCount + 1;
			If ErrorsCount <= 10 Then
				MessageText = MessageText + ?(Not IsBlankString(MessageText), Chars.LF, "") +
				                            StringFunctionsClientServer.SubstituteParametersInString(
				                            NStr("en = 'The product %1 in line %2 was not declared in %3.'"), TrimAll(Row.ProductCode) + " " + TrimAll(Row.ProductDescription), Row.LineNumber, ?(ValueIsFilled(Row.Shipment), Row.Shipment, Row.Order));
			EndIf;
			
		ElsIf Row.UninvoicedQuantity < 0 Then
			ErrorsCount = ErrorsCount + 1;
			If ErrorsCount <= 10 Then
				MessageText = MessageText + ?(Not IsBlankString(MessageText), Chars.LF, "") +
				                            StringFunctionsClientServer.SubstituteParametersInString(
				                            NStr("en = 'The invoiced quantity of product %1 in line %2 exceeds ordered quantity in %3.'"), TrimAll(Row.ProductCode) + " " + TrimAll(Row.ProductDescription), Row.LineNumber, ?(ValueIsFilled(Row.Shipment), Row.Shipment, Row.Order));
			EndIf;
		EndIf;
	EndDo;
	If ErrorsCount > 10 Then
		MessageText = MessageText + Chars.LF + StringFunctionsClientServer.SubstituteParametersInString(
		                                       NStr("en = 'There are also %1 error(s) found'"), Format(ErrorsCount - 10, "NFD=0; NG=0"));
	EndIf;
	
	// 5. Notify user if failed items found.
	If ErrorsCount > 0 Then
		Return MessageText;
	EndIf;
	
	Return "";
	
EndFunction

// -- Copied and modified from SI form module


// ++ Copied and modified from SO form module

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
		SalesTaxAcrossAgencies = SalesTax.CalculateSalesTax(Object.TaxableSubtotal, Object.SalesTaxRate, CurrentAgenciesRates);
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
	Object.UseAvatax	= False;

	If (Not Object.UseAvatax) Then
		TaxEngine = 1; //Use AccountingSuite
		If SalesTaxRate <> Object.SalesTaxRate Then
			Object.SalesTaxRate = SalesTaxRate;
		EndIf;
	Else
		TaxEngine = 2;
	EndIf;
	Object.SalesTaxAcrossAgencies.Clear();
	
	SalesOrderRecalculateTotals(Object);
		
EndProcedure


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

Procedure CashReceipRecalculateTotals(Object)
	
	TotalLinePayment = Object.LineItems.Total("Payment");
	TotalCredit = Object.CreditMemos.Total("Payment");
	Try
		TotalDiscount = Object.LineItems.Total("Discount");
	Except
		TotalDiscount = 0;
	EndTry;	
	
	// Calculation based on Unapplied Payment
	
	If TotalCredit <= TotalLinePayment Then 
		Object.CashPayment = Object.UnappliedPayment + TotalLinePayment - TotalCredit; //
	ElsIf TotalCredit - TotalLinePayment <= Object.UnappliedPayment Then 
		Object.CashPayment = Object.UnappliedPayment + TotalLinePayment - TotalCredit;
	ElsIf TotalCredit - TotalLinePayment > Object.UnappliedPayment Then // This is error, probbably forget to show overpayment
		Object.CashPayment = 0;
		Object.UnappliedPayment = TotalCredit - TotalLinePayment;
	Else 
		Object.CashPayment = 0;
		Object.UnappliedPayment = TotalCredit - TotalLinePayment;
	EndIf;	
	//EndIf;	

	DefaultCurrency = GeneralFunctionsReusable.DefaultCurrency();
	
	Object.DocumentTotalRC = (Object.CashPayment * Object.ExchangeRate) + (TotalCredit * Object.ExchangeRate) + (TotalDiscount * Object.ExchangeRate);
	Object.DocumentTotal = Object.CashPayment + TotalCredit + TotalDiscount;
	Try
		Object.DiscountAmount = TotalDiscount;
	Except	
	EndTry;	
	
EndProcedure	

// -- Copied and modified from CR form module

                                    
// ++ Copied and modified from BankTransfer
Procedure BankTransferRecalculateExchangeRate(Object)
	If GeneralFunctionsReusable.FunctionalOptionValue("MultiCurrency") Then	
		AccountFromCurrency = Object.Currency;
		AccountToCurrency = Object.AccountTo.Currency;
		DefaultCurrency = GeneralFunctionsReusable.DefaultCurrency();
		// Using Default currency to recalc rate
		
		If AccountFromCurrency = DefaultCurrency Then 
			TodayRate = GeneralFunctions.GetExchangeRate(Object.Date, AccountToCurrency);
			Object.ExchangeRate = 1/TodayRate;
		ElsIf AccountToCurrency = AccountFromCurrency Then 
			Object.ExchangeRate = 1;
		Else // Need to calc cross-rate
			TodayRateFrom = GeneralFunctions.GetExchangeRate(Object.Date, AccountFromCurrency);
			TodayRateTo = GeneralFunctions.GetExchangeRate(Object.Date, AccountToCurrency);
			CrossRate = (TodayRateFrom/TodayRateTo);
			Object.ExchangeRate = CrossRate;
		EndIf;
		
		If Object.ExchangeRate = 0 Then 
			Object.ExchangeRate = 1;
		EndIf;	
		Object.AmountTo = Object.Amount * Object.ExchangeRate;
		
	Else 
		Object.ExchangeRate = 1;
		Object.AmountTo = Object.Amount;
	EndIf;	
	
EndProcedure

// -- Copied and modified from BankTransfer


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
		SalesTaxAcrossAgencies = SalesTax.CalculateSalesTax(Object.TaxableSubtotal, Object.SalesTaxRate, CurrentAgenciesRates);
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
		
		Object.UseAvatax	= False;
		
		If (Not Object.UseAvatax) Then
			TaxEngine = 1; //Use AccountingSuite
			If SalesTaxRate <> Object.SalesTaxRate Then
				Object.SalesTaxRate = SalesTaxRate;
			EndIf;
		Else
			TaxEngine = 2;
		EndIf;
		Object.SalesTaxAcrossAgencies.Clear();
		
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