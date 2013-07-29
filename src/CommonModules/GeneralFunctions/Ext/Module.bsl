//////////////////////////////////////////////////////////////////////////////// 
// THIS MODULE CONTAINS GENERAL PURPOSE FUNCTIONS AND PROCEDURES
// 

Function GetUserName() Export
	
	Return SessionParameters.ACSUser;
	
EndFunction

Function GetSystemTitle() Export
	
	Return Constants.SystemTitle.Get();	
	
EndFunction

Function GetCustomTemplate(ObjectName, TemplateName) Export
	
	Query = New Query;
	
	Query.Text = "Select Template AS Template
					|FROM
					|	InformationRegister.CustomPrintForms
					|WHERE
					|	ObjectName=&ObjectName
					|	AND	TemplateName=&TemplateName";
	
	Query.Parameters.Insert("ObjectName", ObjectName);
	Query.Parameters.Insert("TemplateName", TemplateName);
		
	Cursor = Query.Execute().Choose();
	
	Result = Undefined;
	
	If Cursor.Next() Then
		Result = Cursor.Template.Get(); //.Получить();
	Else
	EndIf;
	
	If TypeOf(Result) = Type("BinaryData") Then
		Return BinaryToSpreadsheetDocument(Result);
	Else
		Return Result;
	EndIf;
	
EndFunction

Function BinaryToSpreadsheetDocument(BinaryData) Export
	
	TempFileName = GetTempFileName();
	BinaryData.Write(TempFileName);
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.Read(TempFileName);
	If Not SafeMode() Then
		DeleteFiles(TempFileName);
	EndIf;
	
	Return SpreadsheetDocument;
	
EndFunction

Function GetLogo() Export
	
	Query = New Query;
	
	Query.Text = "Select Template AS Template
					|FROM
					|	InformationRegister.CustomPrintForms
					|WHERE
					|	ObjectName=&ObjectName
					|	AND	TemplateName=&TemplateName";
	
	Query.Parameters.Insert("ObjectName", "logo");
	Query.Parameters.Insert("TemplateName", "logo");
		
	Cursor = Query.Execute().Choose();
	
	Result = Undefined;
	
	If Cursor.Next() Then
		Result = Cursor.Template.Get();
	Else
	EndIf;
	
	Return Result;
	
EndFunction


// Selects item's price from a price-list.
//
// Parameters:
// Date - date of the price in the price-list.
// Catalog.Items - price-list item.
// Catalog.Customers - price list customer (used if Advanced Pricing is enabled).
//
// Returned value:
// Number - item's price.
//
Function RetailPrice(ActualDate, Product, Customer) Export
		
	PriceLevel = Customer.PriceLevel;
	ProductCategory = Product.Category;
	
	SelectParameters = New Structure;
	If PriceLevel = Catalogs.PriceLevels.EmptyRef() AND ProductCategory = Catalogs.ProductCategories.EmptyRef() Then
		SelectParameters.Insert("Product", Product);
	Else
		SelectParameters.Insert("PriceLevel", PriceLevel);
		SelectParameters.Insert("ProductCategory", ProductCategory);
	EndIf;
	ResourceValue = InformationRegisters.PriceList.GetLast(ActualDate, SelectParameters);
	Return ResourceValue.Price;
		
EndFunction

// Marks the document (cash receipt, cash sale) as "deposited" (included) by a deposit document.
//
// Parameters:
// DocumentLine - document Ref for which the procedure sets the "deposited" attribute.
//
Procedure WriteDepositData(DocumentLine) Export
	
	Document = DocumentLine.GetObject();
	Document.Deposited = True;
	Document.Write();

EndProcedure

// Clears the "deposited" (included) by a deposit document value from the document (cash receipt,
// cash sale)
//
// Parameters:
// DocumentLine - document Ref for which the procedure sets the "deposited" attribute.
//
Procedure ClearDepositData(DocumentLine) Export
	
	Document = DocumentLine.GetObject();
	Document.Deposited = False;
	Document.Write();

EndProcedure

// Determines a currency of a line item document.
// Used in invoice payment and cash receipt documents to calculate exchange rate for each line item.
//
// Parameter:
// Document - a document Ref for which the function selects its currency.
//
// Returned value:
// Enumeration.Currencies.
//
Function GetSpecDocumentCurrency(Document) Export
	
	Doc = Document.GetObject();
	Return Doc.Currency;

EndFunction

// Returns a value of a functional option.
//
// Parameter:
// String - functional option name.
//
// Returned value:
// Boolean - 1 - the functional option is set, 0 - the functional option is not set.
//
Function FunctionalOptionValue(FOption) Export
	
	Return GetFunctionalOption(FOption);
	
EndFunction

// Determines a currency exchange rate.
// 
// Parameters:
// Date - conversion date.
// Catalog.Currencies - conversion currency.
//
// Returned value:
// Number - an exchange rate.
// 
Function GetExchangeRate(Date, Currency) Export
		
	SelectParameters = New Structure;
	SelectParameters.Insert("Currency", Currency);
	
	ResourceValue = InformationRegisters.ExchangeRates.GetLast(Date, SelectParameters);
	
	If ResourceValue.Rate = 0 Then
		Return 1;	
	Else
		Return ResourceValue.Rate;
	EndIf;
	
EndFunction

// Returns a default inventory/expense account depending on an
// item type (inventory or non-inventory)
//
// Parameters:
// Enumeration.InventoryTypes - item type (inventory, non-inventory).
//
// Returned value:
// ChartsOfAccounts.ChartOfAccounts.
//
Function InventoryAcct(ProductType) Export
	
	If ProductType = Enums.InventoryTypes.Inventory Then
		Return Constants.InventoryAccount.Get(); 
	Else
		Return Constants.ExpenseAccount.Get();
	EndIf;
		
EndFunction

Function GetDefaultCOGSAcct() Export
	
	Return Constants.COGSAccount.Get();
	
EndFunction

Function GetEmptyAcct() Export
	
	Return ChartsOfAccounts.ChartOfAccounts.EmptyRef();

EndFunction


// Returns an item type (inventory or non-inventory)
//
// Parameters:
// Enumeration.InventoryType
//
// Returned value:
// Boolean
//
Function InventoryType(Type) Export
	
	If Type = Enums.InventoryTypes.Inventory Then
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

// Returns an account description.
//
// Parameters:
// String - account code.
//
// Returned value:
// String - account description
//
Function AccountName(StringCode) Export
	
	Account = ChartsOfAccounts.ChartOfAccounts.FindByCode(StringCode);
	Return Account.Description;
	
EndFunction

// Calculates the next check number for a selected bank account.
//
// Parameters:
// ChartOfAccounts.ChartOfAccounts.
//
// Returned value:
// Number
//
Function LastCheckNumber(BankAccount) Export
	
		LastNumber = 0;
	//Checks check and invoice payment numbers where payment method is check and same bank account	
		Query = New Query("SELECT
		                  |	Check.PhysicalCheckNum AS Number
		                  |FROM
		                  |	Document.Check AS Check
		                  |WHERE
		                  |	Check.BankAccount = &BankAccount
		                  |	AND Check.PaymentMethod = VALUE(Catalog.PaymentMethods.Check)
		                  |
		                  |UNION ALL
		                  |
		                  |SELECT
		                  |	InvoicePayment.PhysicalCheckNum
		                  |FROM
		                  |	Document.InvoicePayment AS InvoicePayment
		                  |WHERE
		                  |	InvoicePayment.BankAccount = &BankAccount
		                  |	AND InvoicePayment.PaymentMethod = VALUE(Catalog.PaymentMethods.Check)
		                  |
		                  |ORDER BY
		                  |	Number DESC");
		Query.SetParameter("BankAccount", BankAccount);
		//Query.SetParameter("Number", Object.Number);
		QueryResult = Query.Execute();
		If QueryResult.IsEmpty() Then
			LastNumber = 999;
			//Object.PhysicalCheckNum = 1000;
		ElsIf
			QueryResult.Unload()[0][0] = 0 Then
			LastNumber = 999;
		Else
			LastNumber = QueryResult.Unload()[0][0];
		EndIf;

		Return LastNumber;
	
EndFunction

Function NextProductNumber() Export
	
	Query = New Query("SELECT
	                  |	Products.api_code AS api_code
	                  |FROM
	                  |	Catalog.Products AS Products
	                  |
	                  |ORDER BY
	                  |	api_code DESC");
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Return 1;
	Else
		Dataset = QueryResult.Unload();
		LastNumber = Dataset[0][0];
		Return LastNumber + 1;
	EndIf;
	
EndFunction


Function SearchCompanyByCode(CompanyCode) Export
	
	Query = New Query("SELECT
	                  |	Companies.Ref
	                  |FROM
	                  |	Catalog.Companies AS Companies
	                  |WHERE
	                  |	Companies.Code = &CompanyCode");
	
	Query.SetParameter("CompanyCode", CompanyCode);	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Return Catalogs.Companies.EmptyRef();
	Else
		Dataset = QueryResult.Unload();
		Return Dataset[0][0];
	EndIf;
	
EndFunction

Function GetShipToAddress(Company) Export
	
	Query = New Query("SELECT
	                  |	Addresses.Ref
	                  |FROM
	                  |	Catalog.Addresses AS Addresses
	                  |WHERE
	                  |	Addresses.Owner = &Company
	                  |	AND Addresses.DefaultShipping = TRUE");
	Query.SetParameter("Company", Company);				  
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Return Catalogs.Addresses.EmptyRef();
	Else
		Dataset = QueryResult.Unload();
		Return Dataset[0][0];
	EndIf;
	
EndFunction

Function ProductLastCost(Product) Export
	
	Query = New Query("SELECT
	                  |	ItemLastCost.Cost
	                  |FROM
	                  |	InformationRegister.ItemLastCost AS ItemLastCost
	                  |WHERE
	                  |	ItemLastCost.Product = &Product");
	Query.SetParameter("Product", Product);
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Return 0;
	Else
		Dataset = QueryResult.Unload();
		Return Dataset[0][0];
	EndIf;
	
EndFunction

// Check documents table parts to ensure, that products are unique
Procedure CheckDoubleItems(Ref, LineItems, Columns, Cancel) Export
	
	// Dump table part
	TableLineItems = LineItems.Unload(, Columns);
	TableLineItems.Sort(Columns);
	
	// Define subsets of data to check
	EmptyItems   = New Structure(Columns);
	CurrentItems = New Structure(Columns);
	DoubledItems = New Structure(Columns);
	CompareItems = StrReplace(Columns, "LineNumber", "");
	DisplayCodes = FunctionalOptionValue("DisplayCodes");
	DoublesCount = 0;
	Doubles      = ""; 
	
	// Check table part for doubles
	For Each LineItem In TableLineItems Do
		// Check for double
		If ComparePropertyValues(CurrentItems, LineItem, CompareItems) Then
			// Double found
			If Not ComparePropertyValues(DoubledItems, CurrentItems, CompareItems) Then
				// New double found
				FillPropertyValues(DoubledItems, CurrentItems, Columns);
				Doubles = Format(CurrentItems.LineNumber, "NFD=0; NG=0") + ", " + Format(LineItem.LineNumber, "NFD=0; NG=0"); 
			Else
				// Multiple double
				Doubles = Doubles + ", " + Format(LineItem.LineNumber, "NFD=0; NG=0"); 
			EndIf;
		Else
			// If Double found
			If FilledPropertyValues(DoubledItems, CompareItems) Then
				
				// Increment doubles counter
				DoublesCount = DoublesCount + 1;
				If DoublesCount <= 10 Then // 10 messages enough to demonstrate that check failed
					
					// Publish previously found double
					DoublesText = "";
					For Each Double In DoubledItems Do
						// Convert value to it's presentation
						Value = Double.Value;
						If Double.Key = "LineNumber" Then
							Continue; // Skip line number
							
						ElsIf TypeOf(Value) = Type("CatalogRef.Companies") Then
							Presentation = ?(DisplayCodes, TrimAll(Value.Code) + " ", "") + TrimAll(Value.Description);
							
						ElsIf TypeOf(Value) = Type("CatalogRef.Products") Then
							Presentation = TrimAll(Value.Code) + " " + TrimAll(Value.Description);
							
						Else
							Presentation = TrimAll(Value);
						EndIf;
						
						// Generate doubled items text
						DoublesText = DoublesText + ?(IsBlankString(DoublesText), "", ", ") + Double.Key + " """ + Presentation + """";
					EndDo;
					
					// Generate message to user
					MessageText = NStr("en = '%1
					                         |doubled in lines: %2'");
					MessageText = StringFunctionsClientServer.SubstituteParametersInString(MessageText, DoublesText, Doubles); 
					CommonUseClientServer.MessageToUser(MessageText, Ref,,, Cancel);
				EndIf;
				
				// Clear found double
				FillPropertyValues(DoubledItems, EmptyItems, Columns);
				Doubles = "";
			EndIf;
		EndIf;
		
		// Save current state for the next loop
		FillPropertyValues(CurrentItems, LineItem, Columns);
	EndDo;
	
	// Publish last found double
	If FilledPropertyValues(DoubledItems, CompareItems)
	And DoublesCount < 10 Then // Display 10-th message
		
		// Publish previously found double
		DoublesText = "";
		For Each Double In DoubledItems Do
			
			// Convert value to it's presentation
			Value = Double.Value;
			If Double.Key = "LineNumber" Then
				Continue; // Skip line number
				
			ElsIf TypeOf(Value) = Type("CatalogRef.Companies") Then
				Presentation = ?(DisplayCodes, TrimAll(Value.Code) + " ", "") + TrimAll(Value.Description);
				
			ElsIf TypeOf(Value) = Type("CatalogRef.Products") Then
				Presentation = TrimAll(Value.Code) + " " + TrimAll(Value.Description);
				
			Else
				Presentation = TrimAll(Value);
			EndIf;
			
			DoublesText = DoublesText + ?(IsBlankString(DoublesText), "", ", ") + Double.Key + " """ + Presentation + """";
		EndDo;
		
		// Generate message to user
		MessageText = NStr("en = '%1
		                         |doubled in lines: %2'");
		MessageText = StringFunctionsClientServer.SubstituteParametersInString(MessageText, DoublesText, Doubles); 
		CommonUseClientServer.MessageToUser(MessageText, Ref,,, Cancel);
		
	Else
		RemainingDoubles = DoublesCount + Number(FilledPropertyValues(DoubledItems, CompareItems)) - 10; // Quantity of errors, which are not displayed to user
		If RemainingDoubles > 0 Then
			// Generate message to user
			MessageText = NStr("en = 'There are also %1 error(s) found'");
			MessageText = StringFunctionsClientServer.SubstituteParametersInString(MessageText, Format(RemainingDoubles, "NFD=0; NG=0")); 
			CommonUseClientServer.MessageToUser(MessageText, Ref,,, Cancel);
		EndIf;
	EndIf;

EndProcedure

// Normalizes passed array removing empty values and duplicates
// 
// Parameters:
// 	Array - Array of items to be normalized (Arbitrary items)
//
Procedure NormalizeArray(Array) Export
	
	i = 0;
	While i < Array.Count() Do
		
		// Check current item
		If (Array[i] = Undefined) Or (Not ValueIsFilled(Array[i])) Then
			Array.Delete(i);	// Delete empty values
			
		ElsIf Array.Find(Array[i]) <> i Then
			Array.Delete(i);	// Delete duplicate
			
		Else
			i = i + 1;			// Next item
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Compares two passed objects by their properties (as analogue to FillPropertyValues)
// Compares Source property values with values of properties of the Receiver. Matching is done by property names.
// If some of the properties are absent in Source or Destination objects, they will be omitted.
// If objects don't have same properties, they will be assumed as different, because they having nothing in common.
//
// Parameters:
// 	Receiver - Reference (Arbitrary), properties of which will be compared with properties of Source. 
//  Source   - Reference (Arbitrary), properties of which will be used to compare with Receiver.
//  ListOfProperties - String of comma-separated property names that will be used in compare.
//
// Return value:
// 	Boolean - Objects are equal by the set of their properties
//
Function ComparePropertyValues(Receiver, Source, ListOfProperties) Export
	Var DstItemValue;
	
	// Create structures to compare
	SrcStruct = New Structure(ListOfProperties);
	DstStruct = New Structure(ListOfProperties);
		
	// Copy arbitrary values to comparable structures
	FillPropertyValues(SrcStruct, Source);   // Only properties, existing in Source   and defined in ListOfProperties are copied
	FillPropertyValues(DstStruct, Receiver); // Only properties, existing in Receiver and defined in ListOfProperties are copied
	
	// Flag of having similar properties
	FoundSameProperty = False;
	
	// Compare properties of structures
	For Each SrcItem In SrcStruct Do
		
		If DstStruct.Property(SrcItem.Key, DstItemValue) Then
			// Set flag of found same properties in both structures
			If Not FoundSameProperty Then FoundSameProperty = True; EndIf;
			
			// Compare values of properties
			If SrcItem.Value <> DstItemValue Then
				// Compare failed
				Return False;
			EndIf;
		Else
		    // Skip property absent in DstStruct
		EndIf;
		
	EndDo;
	
	// The structures contain the same compareble properties, or nothing in common
	Return FoundSameProperty;
			
EndFunction

// Check filling of passed object by it's properties (as analogue to FillPropertyValues)
// If some of the properties mentioned in ListOfProperties are absent in object, they will be omitted.
// If objects hasn't selected properties, it will be assumed as empty, because it hsn't any.
//
// Parameters:
//  Source   - Reference (Arbitrary), properties of which will be used to check their filling.
//  ListOfProperties - String of comma-separated property names that will be used in check.
//
// Return value:
// 	Boolean - Sre objects equal by the set of their properties
//
Function FilledPropertyValues(Source, ListOfProperties) Export
	
	// Create structures to check filling of properties
	SrcStruct = New Structure(ListOfProperties);
	FillPropertyValues(SrcStruct, Source); // Only properties, existing in Source and defined in ListOfProperties are copied
	
	// Compare properties of structures
	For Each SrcItem In SrcStruct Do
		If SrcItem.Value <> Undefined Then
			// Object has filled properties
			Return True;
		EndIf;
	EndDo;
	
	// None of properties are filled
	Return False;
	
EndFunction

// converts a number into a 5 character string by adding leading zeros.
// for example 15 -> "00015"
// 
Function LeadingZeros(Number) Export

	StringNumber = String(Number);
	ZerosNeeded = 5 - StrLen(StringNumber);
	NumberWithZeros = "";
	For i = 1 to ZerosNeeded Do
		NumberWithZeros = NumberWithZeros + "0";
	EndDo;
	
	Return NumberWithZeros + StringNumber;
	
EndFunction

// Moved from InfobaseUpdateOverridable

// Procedure fills empty IB.
//
Procedure FirstLaunch() Export
	
	// mt_change
	If Constants.FirstLaunch.Get() = False Then
	
	BeginTransaction();
	
		// Adding account types to predefined accounts and
		// assigning default posting accounts.
		
		Account = ChartsOfAccounts.ChartOfAccounts.BankAccount.GetObject();
		Account.AccountType = Enums.AccountTypes.Bank;
		Account.Currency = Catalogs.Currencies.USD;
		Account.CashFlowSection = Enums.CashFlowSections.Operating;
		Account.Order = Account.Code;
		Account.Write();
		Constants.BankAccount.Set(Account.Ref);
		
		Account = ChartsOfAccounts.ChartOfAccounts.UndepositedFunds.GetObject();
		Account.AccountType = Enums.AccountTypes.OtherCurrentAsset;
		Account.Currency = Catalogs.Currencies.USD;
		Account.CashFlowSection = Enums.CashFlowSections.Operating;
		Account.Order = Account.Code;
		Account.Write();
		Constants.UndepositedFundsAccount.Set(Account.Ref);
		
		Account = ChartsOfAccounts.ChartOfAccounts.AccountsReceivable.GetObject();
		Account.AccountType = Enums.AccountTypes.AccountsReceivable;
		Account.Currency = Catalogs.Currencies.USD;
		Account.CashFlowSection = Enums.CashFlowSections.Operating;
		Account.Order = Account.Code;
		Account.Write();
		
		USDCurrency = Catalogs.Currencies.USD.GetObject();
		USDCurrency.DefaultARAccount = Account.Ref;
		
		Account = ChartsOfAccounts.ChartOfAccounts.Inventory.GetObject();
		Account.AccountType = Enums.AccountTypes.Inventory;
		Account.Currency = Catalogs.Currencies.USD;
		Account.CashFlowSection = Enums.CashFlowSections.Operating;
		Account.Order = Account.Code;
		Account.Write();
		Constants.InventoryAccount.Set(Account.Ref);
		
		Account = ChartsOfAccounts.ChartOfAccounts.AccountsPayable.GetObject();
		Account.AccountType = Enums.AccountTypes.AccountsPayable;
		Account.Currency = Catalogs.Currencies.USD;
		Account.CashFlowSection = Enums.CashFlowSections.Operating;
		Account.Order = Account.Code;
		Account.Write();
		
		USDCurrency.DefaultAPAccount = Account.Ref;
		USDCurrency.Write();
		
		Account = ChartsOfAccounts.ChartOfAccounts.TaxPayable.GetObject();
		Account.AccountType = Enums.AccountTypes.OtherCurrentLiability;
		Account.Currency = Catalogs.Currencies.USD;
		Account.CashFlowSection = Enums.CashFlowSections.Operating;
		Account.Order = Account.Code;
		Account.Write();
		Constants.TaxPayableAccount.Set(Account.Ref);
				
		Account = ChartsOfAccounts.ChartOfAccounts.Income.GetObject();
		Account.AccountType = Enums.AccountTypes.Income;
		Account.Currency = Catalogs.Currencies.USD;
		Account.CashFlowSection = Enums.CashFlowSections.Operating;
		Account.Order = Account.Code;
		Account.Write();
		Constants.IncomeAccount.Set(Account.Ref);
		
		Account = ChartsOfAccounts.ChartOfAccounts.COGS.GetObject();
		Account.AccountType = Enums.AccountTypes.CostOfSales;
		Account.Currency = Catalogs.Currencies.USD;
		Account.CashFlowSection = Enums.CashFlowSections.Operating;
		Account.Order = Account.Code;
		Account.Write();
		Constants.COGSAccount.Set(Account.Ref);
		
		Account = ChartsOfAccounts.ChartOfAccounts.Equity.GetObject();
		Account.AccountType = Enums.AccountTypes.Equity;
		Account.Currency = Catalogs.Currencies.USD;
		Account.CashFlowSection = Enums.CashFlowSections.Operating;
		Account.Order = Account.Code;
		Account.Write();
		
		Account = ChartsOfAccounts.ChartOfAccounts.RetainedEarnings.GetObject();
		Account.AccountType = Enums.AccountTypes.Equity;
		Account.Currency = Catalogs.Currencies.USD;
		Account.CashFlowSection = Enums.CashFlowSections.Operating;
		Account.Order = Account.Code;
		Account.Write();

		Account = ChartsOfAccounts.ChartOfAccounts.BankServiceCharge.GetObject();
		Account.AccountType = Enums.AccountTypes.OtherExpense;
		Account.Currency = Catalogs.Currencies.USD;
		Account.CashFlowSection = Enums.CashFlowSections.Operating;
		Account.Order = Account.Code;
		Account.Write();
		Constants.BankServiceChargeAccount.Set(Account.Ref);
		
		Account = ChartsOfAccounts.ChartOfAccounts.BankInterestEarned.GetObject();
		Account.AccountType = Enums.AccountTypes.OtherIncome;
		Account.Currency = Catalogs.Currencies.USD;
		Account.CashFlowSection = Enums.CashFlowSections.Operating;
		Account.Order = Account.Code;
		Account.Write();
		Constants.BankInterestEarnedAccount.Set(Account.Ref);
		
		Account = ChartsOfAccounts.ChartOfAccounts.ExchangeGain.GetObject();
		Account.AccountType = Enums.AccountTypes.OtherIncome;
		Account.Currency = Catalogs.Currencies.USD;
		Account.CashFlowSection = Enums.CashFlowSections.Operating;
		Account.Order = Account.Code;
		Account.Write();
		Constants.ExchangeGain.Set(Account.Ref);
		
		Account = ChartsOfAccounts.ChartOfAccounts.ExchangeLoss.GetObject();
		Account.AccountType = Enums.AccountTypes.OtherExpense;
		Account.Currency = Catalogs.Currencies.USD;
		Account.CashFlowSection = Enums.CashFlowSections.Operating;
		Account.Order = Account.Code;
		Account.Write();
		Constants.ExchangeLoss.Set(Account.Ref);
		
		Account = ChartsOfAccounts.ChartOfAccounts.Expense.GetObject();
		Account.AccountType = Enums.AccountTypes.Expense;
		Account.Currency = Catalogs.Currencies.USD;
		Account.CashFlowSection = Enums.CashFlowSections.Operating;
		Account.Order = Account.Code;
		Account.Write();
		Constants.ExpenseAccount.Set(Account.Ref);
					
		// Adding OurCompany's full name
		
		//OC = Catalogs.Companies.OurCompany.GetObject();
		//OC.Description = "Our company full name";
		//OC.Terms = Catalogs.PaymentTerms.Net30;
		//OC.Write();
		//
		//AddressLine = Catalogs.Addresses.CreateItem();
		//AddressLine.Owner = Catalogs.Companies.OurCompany;
		//AddressLine.Description = "Primary";
		//AddressLine.DefaultShipping = True;
		//AddressLine.DefaultBilling = True;
		//AddressLine.Write();
		
		// Setting default location, currency, and beginning balances date
		
		Constants.DefaultCurrency.Set(Catalogs.Currencies.USD);
		
		// Adding days to predefined payment terms and setting
		// a default payment term
				
		PT = Catalogs.PaymentTerms.Net30.GetObject();
		PT.Days = 30;
		PT.Write();
		
		PT = Catalogs.PaymentTerms.Consignment.GetObject();
		PT.Days = 0;
		PT.Write();

		PT = Catalogs.PaymentTerms.DueOnReceipt.GetObject();
		PT.Days = 0;
		PT.Write();

		
		PT = Catalogs.PaymentTerms.Net15.GetObject();
		PT.Days = 15;
		PT.Write();
				
		// Turning on the US Financial Localization
		
		Constants.USFinLocalization.Set(True);
		
		// Setting 1099 thresholds
		
		Cat1099 = Catalogs.USTaxCategories1099.Box1.GetObject();
		Cat1099.Threshold = 600;
		Cat1099.Write();
		
		Cat1099 = Catalogs.USTaxCategories1099.Box2.GetObject();
		Cat1099.Threshold = 10;
		Cat1099.Write();
		
		Cat1099 = Catalogs.USTaxCategories1099.Box7.GetObject();
		Cat1099.Threshold = 600;
		Cat1099.Write();
		
		Cat1099 = Catalogs.USTaxCategories1099.Box8.GetObject();
		Cat1099.Threshold = 10;
		Cat1099.Write();
		
		Cat1099 = Catalogs.USTaxCategories1099.Box9.GetObject();
		Cat1099.Threshold = 5000;
		Cat1099.Write();
		
		// Creating a user with full rights
		
		// mt_change
		
		//NewUser = InfoBaseUsers.CreateUser();
		//NewUser.Name = "Administrator";
		//Role = Metadata.Roles.Find("FullAccess");
		//NewUser.Roles.Add(Role);
		//NewUser.Write();
				
		// Assigning currency symbols
				
		Currency = Catalogs.Currencies.USD.GetObject();
		Currency.Symbol = "$";
		Currency.Write();
						
		// Setting the Disable LIFO constant
		
		Constants.DisableLIFO.Set(False);
		
		// Setting Customer Name and Vendor Name constants
		
		Constants.CustomerName.Set("Customer");
		Constants.VendorName.Set("Vendor");
		
		// US186 - unapplied payment
		
		// Setting unaplied payment item
		//UnappliedPaymentItem                           = Catalogs.Products.CreateItem();
		//UnappliedPaymentItem.Code                      = "Unapplied payment";
		//UnappliedPaymentItem.Description               = "Unapplied payment";
		//UnappliedPaymentItem.Type                      = Enums.InventoryTypes.NonInventory;
		//UnappliedPaymentItem.UM                        = Catalogs.UM.each;
		//UnappliedPaymentItem.IncomeAccount             = ChartsOfAccounts.ChartOfAccounts.Income;
		//UnappliedPaymentItem.InventoryOrExpenseAccount = ChartsOfAccounts.ChartOfAccounts.Expense;
		//UnappliedPaymentItem.Write();
		
		// US186 - unapplied payment
		
		// Adding US States
		
		// 1 - 10
		
		NewState = Catalogs.States.CreateItem();
		NewState.Code = "AL";
		NewState.Description = "Alabama";
		NewState.Write();
		
		NewState = Catalogs.States.CreateItem();
		NewState.Code = "AK";
		NewState.Description = "Alaska";
		NewState.Write();
		
		NewState = Catalogs.States.CreateItem();
		NewState.Code = "AZ";
		NewState.Description = "Arizona";
		NewState.Write();
		
		NewState = Catalogs.States.CreateItem();
		NewState.Code = "AR";
		NewState.Description = "Arkansas";
		NewState.Write();

		NewState = Catalogs.States.CreateItem();
		NewState.Code = "CA";
		NewState.Description = "California";
		NewState.Write();

		NewState = Catalogs.States.CreateItem();
		NewState.Code = "CO";
		NewState.Description = "Colorado";
		NewState.Write();

		NewState = Catalogs.States.CreateItem();
		NewState.Code = "CT";
		NewState.Description = "Connecticut";
		NewState.Write();
		
		NewState = Catalogs.States.CreateItem();
		NewState.Code = "DE";
		NewState.Description = "Delaware";
		NewState.Write();

        NewState = Catalogs.States.CreateItem();
		NewState.Code = "FL";
		NewState.Description = "Florida";
		NewState.Write();
		
		NewState = Catalogs.States.CreateItem();
		NewState.Code = "GA";
		NewState.Description = "Georgia";
		NewState.Write();

		// 11 - 20
		
        NewState = Catalogs.States.CreateItem();
		NewState.Code = "HI";
		NewState.Description = "Hawaii";
		NewState.Write();

		NewState = Catalogs.States.CreateItem();
		NewState.Code = "ID";
		NewState.Description = "Idaho";
		NewState.Write();

	    NewState = Catalogs.States.CreateItem();
		NewState.Code = "IL";
		NewState.Description = "Illinois";
		NewState.Write();

	    NewState = Catalogs.States.CreateItem();
		NewState.Code = "IN";
		NewState.Description = "Indiana";
		NewState.Write();
		
	    NewState = Catalogs.States.CreateItem();
		NewState.Code = "IA";
		NewState.Description = "Iowa";
		NewState.Write();
		
	    NewState = Catalogs.States.CreateItem();
		NewState.Code = "KS";
		NewState.Description = "Kansas";
		NewState.Write();
		
	 	NewState = Catalogs.States.CreateItem();
		NewState.Code = "KY";
		NewState.Description = "Kentucky";
		NewState.Write();

		NewState = Catalogs.States.CreateItem();
		NewState.Code = "LA";
		NewState.Description = "Louisiana";
		NewState.Write();

	    NewState = Catalogs.States.CreateItem();
		NewState.Code = "ME";
		NewState.Description = "Maine";
		NewState.Write();
		
	    NewState = Catalogs.States.CreateItem();
		NewState.Code = "MD";
		NewState.Description = "Maryland";
		NewState.Write();
		
		// 21 - 30
		
	    NewState = Catalogs.States.CreateItem();
		NewState.Code = "MA";
		NewState.Description = "Massachusetts";
		NewState.Write();
		
	    NewState = Catalogs.States.CreateItem();
		NewState.Code = "MI";
		NewState.Description = "Michigan";
		NewState.Write();

	    NewState = Catalogs.States.CreateItem();
		NewState.Code = "MN";
		NewState.Description = "Minnesota";
		NewState.Write();
		
	    NewState = Catalogs.States.CreateItem();
		NewState.Code = "MS";
		NewState.Description = "Mississippi";
		NewState.Write();
		
	    NewState = Catalogs.States.CreateItem();
		NewState.Code = "MO";
		NewState.Description = "Missouri";
		NewState.Write();
		
	    NewState = Catalogs.States.CreateItem();
		NewState.Code = "MT";
		NewState.Description = "Montana";
		NewState.Write();
		
		NewState = Catalogs.States.CreateItem();
		NewState.Code = "NE";
		NewState.Description = "Nebraska";
		NewState.Write();

	    NewState = Catalogs.States.CreateItem();
		NewState.Code = "NV";
		NewState.Description = "Nevada";
		NewState.Write();
		
	    NewState = Catalogs.States.CreateItem();
		NewState.Code = "NH";
		NewState.Description = "New Hampshire";
		NewState.Write();
		
	    NewState = Catalogs.States.CreateItem();
		NewState.Code = "NJ";
		NewState.Description = "New Jersey";
		NewState.Write();
		
		// 31 - 40
		
	    NewState = Catalogs.States.CreateItem();
		NewState.Code = "NM";
		NewState.Description = "New Mexico";
		NewState.Write();
		
	    NewState = Catalogs.States.CreateItem();
		NewState.Code = "NY";
		NewState.Description = "New York";
		NewState.Write();
		
	    NewState = Catalogs.States.CreateItem();
		NewState.Code = "NC";
		NewState.Description = "North Carolina";
		NewState.Write();
		
	    NewState = Catalogs.States.CreateItem();
		NewState.Code = "ND";
		NewState.Description = "North Dakota";
		NewState.Write();
		
	    NewState = Catalogs.States.CreateItem();
		NewState.Code = "OH";
		NewState.Description = "Ohio";
		NewState.Write();
		
	    NewState = Catalogs.States.CreateItem();
		NewState.Code = "OK";
		NewState.Description = "Oklahoma";
		NewState.Write();
		
	    NewState = Catalogs.States.CreateItem();
		NewState.Code = "OR";
		NewState.Description = "Oregon";
		NewState.Write();
		
	    NewState = Catalogs.States.CreateItem();
		NewState.Code = "PA";
		NewState.Description = "Pennsylvania";
		NewState.Write();
		
	    NewState = Catalogs.States.CreateItem();
		NewState.Code = "RI";
		NewState.Description = "Rhode Island";
		NewState.Write();
		
	    NewState = Catalogs.States.CreateItem();
		NewState.Code = "SC";
		NewState.Description = "South Carolina";
		NewState.Write();
		
		// 41 - 50 
		
	    NewState = Catalogs.States.CreateItem();
		NewState.Code = "SD";
		NewState.Description = "South Dakota";
		NewState.Write();
		
	    NewState = Catalogs.States.CreateItem();
		NewState.Code = "TN";
		NewState.Description = "Tennessee";
		NewState.Write();
		
	    NewState = Catalogs.States.CreateItem();
		NewState.Code = "TX";
		NewState.Description = "Texas";
		NewState.Write();
		
	    NewState = Catalogs.States.CreateItem();
		NewState.Code = "UT";
		NewState.Description = "Utah";
		NewState.Write();
		
	    NewState = Catalogs.States.CreateItem();
		NewState.Code = "VT";
		NewState.Description = "Vermont";
		NewState.Write();
		
	    NewState = Catalogs.States.CreateItem();
		NewState.Code = "VA";
		NewState.Description = "Virginia";
		NewState.Write();
		
	    NewState = Catalogs.States.CreateItem();
		NewState.Code = "WA";
		NewState.Description = "Washington";
		NewState.Write();
		
	    NewState = Catalogs.States.CreateItem();
		NewState.Code = "WV";
		NewState.Description = "West Virginia";
		NewState.Write();
		
	    NewState = Catalogs.States.CreateItem();
		NewState.Code = "WI";
		NewState.Description = "Wisconsin";
		NewState.Write();
		
	    NewState = Catalogs.States.CreateItem();
		NewState.Code = "WY";
		NewState.Description = "Wyoming";
		NewState.Write();
		
		// Countries
		
NewCountry = Catalogs.Countries.CreateItem();		
NewCountry.Description = "Afghanistan";
NewCountry.Code = "AF";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Åland Islands";
NewCountry.Code = "AX";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Albania";
NewCountry.Code = "AL";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Algeria";
NewCountry.Code = "DZ";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "American Samoa";
NewCountry.Code = "AS";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Andorra";
NewCountry.Code = "AD";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Angola";
NewCountry.Code = "AO";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Anguilla";
NewCountry.Code = "AI";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Antarctica";
NewCountry.Code = "AQ";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Antigua and Barbuda";
NewCountry.Code = "AG";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Argentina";
NewCountry.Code = "AR";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Armenia";
NewCountry.Code = "AM";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Aruba";
NewCountry.Code = "AW";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Australia";
NewCountry.Code = "AU";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Austria";
NewCountry.Code = "AT";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Azerbaijan";
NewCountry.Code = "AZ";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Bahamas";
NewCountry.Code = "BS";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Bahrain";
NewCountry.Code = "BH";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Bangladesh";
NewCountry.Code = "BD";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Barbados";
NewCountry.Code = "BB";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Belarus";
NewCountry.Code = "BY";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Belgium";
NewCountry.Code = "BE";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Belize";
NewCountry.Code = "BZ";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Benin";
NewCountry.Code = "BJ";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Bermuda";
NewCountry.Code = "BM";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Bhutan";
NewCountry.Code = "BT";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Bolivia, Plurinational State of";
NewCountry.Code = "BO";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Bonaire, Sint Eustatius and Saba";
NewCountry.Code = "BQ";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Bosnia and Herzegovina";
NewCountry.Code = "BA";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Botswana";
NewCountry.Code = "BW";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Bouvet Island";
NewCountry.Code = "BV";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Brazil";
NewCountry.Code = "BR";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "British Indian Ocean Territory";
NewCountry.Code = "IO";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Brunei Darussalam";
NewCountry.Code = "BN";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Bulgaria";
NewCountry.Code = "BG";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Burkina Faso";
NewCountry.Code = "BF";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Burundi";
NewCountry.Code = "BI";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Cambodia";
NewCountry.Code = "KH";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Cameroon";
NewCountry.Code = "CM";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Canada";
NewCountry.Code = "CA";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Cape Verde";
NewCountry.Code = "CV";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Cayman Islands";
NewCountry.Code = "KY";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Central African Republic";
NewCountry.Code = "CF";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Chad";
NewCountry.Code = "TD";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Chile";
NewCountry.Code = "CL";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "China";
NewCountry.Code = "CN";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Christmas Island";
NewCountry.Code = "CX";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Cocos (Keeling) Islands";
NewCountry.Code = "CC";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Colombia";
NewCountry.Code = "CO";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Comoros";
NewCountry.Code = "KM";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Congo";
NewCountry.Code = "CG";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Congo, the Democratic Republic of the";
NewCountry.Code = "CD";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Cook Islands";
NewCountry.Code = "CK";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Costa Rica";
NewCountry.Code = "CR";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Côte d'Ivoire";
NewCountry.Code = "CI";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Croatia";
NewCountry.Code = "HR";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Cuba";
NewCountry.Code = "CU";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Curaçao";
NewCountry.Code = "CW";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Cyprus";
NewCountry.Code = "CY";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Czech Republic";
NewCountry.Code = "CZ";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Denmark";
NewCountry.Code = "DK";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Djibouti";
NewCountry.Code = "DJ";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Dominica";
NewCountry.Code = "DM";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Dominican Republic";
NewCountry.Code = "DO";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Ecuador";
NewCountry.Code = "EC";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Egypt";
NewCountry.Code = "EG";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "El Salvador";
NewCountry.Code = "SV";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Equatorial Guinea";
NewCountry.Code = "GQ";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Eritrea";
NewCountry.Code = "ER";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Estonia";
NewCountry.Code = "EE";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Ethiopia";
NewCountry.Code = "ET";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Falkland Islands (Malvinas)";
NewCountry.Code = "FK";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Faroe Islands";
NewCountry.Code = "FO";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Fiji";
NewCountry.Code = "FJ";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Finland";
NewCountry.Code = "FI";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "France";
NewCountry.Code = "FR";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "French Guiana";
NewCountry.Code = "GF";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "French Polynesia";
NewCountry.Code = "PF";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "French Southern Territories";
NewCountry.Code = "TF";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Gabon";
NewCountry.Code = "GA";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Gambia";
NewCountry.Code = "GM";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Georgia";
NewCountry.Code = "GE";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Germany";
NewCountry.Code = "DE";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Ghana";
NewCountry.Code = "GH";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Gibraltar";
NewCountry.Code = "GI";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Greece";
NewCountry.Code = "GR";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Greenland";
NewCountry.Code = "GL";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Grenada";
NewCountry.Code = "GD";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Guadeloupe";
NewCountry.Code = "GP";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Guam";
NewCountry.Code = "GU";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Guatemala";
NewCountry.Code = "GT";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Guernsey";
NewCountry.Code = "GG";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Guinea";
NewCountry.Code = "GN";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Guinea-Bissau";
NewCountry.Code = "GW";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Guyana";
NewCountry.Code = "GY";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Haiti";
NewCountry.Code = "HT";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Heard Island and McDonald Islands";
NewCountry.Code = "HM";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Holy See (Vatican City State)";
NewCountry.Code = "VA";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Honduras";
NewCountry.Code = "HN";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Hong Kong";
NewCountry.Code = "HK";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Hungary";
NewCountry.Code = "HU";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Iceland";
NewCountry.Code = "IS";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "India";
NewCountry.Code = "IN";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Indonesia";
NewCountry.Code = "ID";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Iran, Islamic Republic of";
NewCountry.Code = "IR";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Iraq";
NewCountry.Code = "IQ";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Ireland";
NewCountry.Code = "IE";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Isle of Man";
NewCountry.Code = "IM";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Israel";
NewCountry.Code = "IL";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Italy";
NewCountry.Code = "IT";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Jamaica";
NewCountry.Code = "JM";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Japan";
NewCountry.Code = "JP";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Jersey";
NewCountry.Code = "JE";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Jordan";
NewCountry.Code = "JO";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Kazakhstan";
NewCountry.Code = "KZ";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Kenya";
NewCountry.Code = "KE";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Kiribati";
NewCountry.Code = "KI";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Korea, Democratic People's Republic of";
NewCountry.Code = "KP";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Korea, Republic of";
NewCountry.Code = "KR";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Kuwait";
NewCountry.Code = "KW";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Kyrgyzstan";
NewCountry.Code = "KG";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Lao People's Democratic Republic";
NewCountry.Code = "LA";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Latvia";
NewCountry.Code = "LV";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Lebanon";
NewCountry.Code = "LB";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Lesotho";
NewCountry.Code = "LS";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Liberia";
NewCountry.Code = "LR";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Libya";
NewCountry.Code = "LY";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Liechtenstein";
NewCountry.Code = "LI";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Lithuania";
NewCountry.Code = "LT";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Luxembourg";
NewCountry.Code = "LU";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Macao";
NewCountry.Code = "MO";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Macedonia, The Former Yugoslav Republic of";
NewCountry.Code = "MK";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Madagascar";
NewCountry.Code = "MG";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Malawi";
NewCountry.Code = "MW";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Malaysia";
NewCountry.Code = "MY";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Maldives";
NewCountry.Code = "MV";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Mali";
NewCountry.Code = "ML";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Malta";
NewCountry.Code = "MT";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Marshall Islands";
NewCountry.Code = "MH";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Martinique";
NewCountry.Code = "MQ";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Mauritania";
NewCountry.Code = "MR";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Mauritius";
NewCountry.Code = "MU";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Mayotte";
NewCountry.Code = "YT";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Mexico";
NewCountry.Code = "MX";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Micronesia, Federated States of";
NewCountry.Code = "FM";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Moldova, Republic of";
NewCountry.Code = "MD";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Monaco";
NewCountry.Code = "MC";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Mongolia";
NewCountry.Code = "MN";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Montenegro";
NewCountry.Code = "ME";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Montserrat";
NewCountry.Code = "MS";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Morocco";
NewCountry.Code = "MA";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Mozambique";
NewCountry.Code = "MZ";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Myanmar";
NewCountry.Code = "MM";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Namibia";
NewCountry.Code = "NA";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Nauru";
NewCountry.Code = "NR";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Nepal";
NewCountry.Code = "NP";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Netherlands";
NewCountry.Code = "NL";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "New Caledonia";
NewCountry.Code = "NC";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "New Zealand";
NewCountry.Code = "NZ";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Nicaragua";
NewCountry.Code = "NI";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Niger";
NewCountry.Code = "NE";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Nigeria";
NewCountry.Code = "NG";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Niue";
NewCountry.Code = "NU";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Norfolk Island";
NewCountry.Code = "NF";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Northern Mariana Islands";
NewCountry.Code = "MP";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Norway";
NewCountry.Code = "NO";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Oman";
NewCountry.Code = "OM";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Pakistan";
NewCountry.Code = "PK";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Palau";
NewCountry.Code = "PW";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Palestine, State of";
NewCountry.Code = "PS";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Panama";
NewCountry.Code = "PA";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Papua New Guinea";
NewCountry.Code = "PG";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Paraguay";
NewCountry.Code = "PY";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Peru";
NewCountry.Code = "PE";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Philippines";
NewCountry.Code = "PH";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Pitcairn";
NewCountry.Code = "PN";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Poland";
NewCountry.Code = "PL";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Portugal";
NewCountry.Code = "PT";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Puerto Rico";
NewCountry.Code = "PR";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Qatar";
NewCountry.Code = "QA";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Réunion";
NewCountry.Code = "RE";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Romania";
NewCountry.Code = "RO";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Russian Federation";
NewCountry.Code = "RU";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Rwanda";
NewCountry.Code = "RW";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Saint Barthélemy";
NewCountry.Code = "BL";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Saint Helena, Ascension and Tristan da Cunha";
NewCountry.Code = "SH";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Saint Kitts and Nevis";
NewCountry.Code = "KN";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Saint Lucia";
NewCountry.Code = "LC";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Saint Martin (French part)";
NewCountry.Code = "MF";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Saint Pierre and Miquelon";
NewCountry.Code = "PM";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Saint Vincent and the Grenadines";
NewCountry.Code = "VC";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Samoa";
NewCountry.Code = "WS";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "San Marino";
NewCountry.Code = "SM";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Sao Tome and Principe";
NewCountry.Code = "ST";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Saudi Arabia";
NewCountry.Code = "SA";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Senegal";
NewCountry.Code = "SN";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Serbia";
NewCountry.Code = "RS";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Seychelles";
NewCountry.Code = "SC";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Sierra Leone";
NewCountry.Code = "SL";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Singapore";
NewCountry.Code = "SG";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Sint Maarten (Dutch part)";
NewCountry.Code = "SX";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Slovakia";
NewCountry.Code = "SK";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Slovenia";
NewCountry.Code = "SI";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Solomon Islands";
NewCountry.Code = "SB";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Somalia";
NewCountry.Code = "SO";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "South Africa";
NewCountry.Code = "ZA";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "South Georgia and the South Sandwich Islands";
NewCountry.Code = "GS";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "South Sudan";
NewCountry.Code = "SS";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Spain";
NewCountry.Code = "ES";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Sri Lanka";
NewCountry.Code = "LK";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Sudan";
NewCountry.Code = "SD";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Suriname";
NewCountry.Code = "SR";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Svalbard and Jan Mayen";
NewCountry.Code = "SJ";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Swaziland";
NewCountry.Code = "SZ";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Sweden";
NewCountry.Code = "SE";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Switzerland";
NewCountry.Code = "CH";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Syrian Arab Republic";
NewCountry.Code = "SY";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Taiwan, Province of China";
NewCountry.Code = "TW";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Tajikistan";
NewCountry.Code = "TJ";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Tanzania, United Republic of";
NewCountry.Code = "TZ";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Thailand";
NewCountry.Code = "TH";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Timor-Leste";
NewCountry.Code = "TL";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Togo";
NewCountry.Code = "TG";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Tokelau";
NewCountry.Code = "TK";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Tonga";
NewCountry.Code = "TO";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Trinidad and Tobago";
NewCountry.Code = "TT";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Tunisia";
NewCountry.Code = "TN";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Turkey";
NewCountry.Code = "TR";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Turkmenistan";
NewCountry.Code = "TM";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Turks and Caicos Islands";
NewCountry.Code = "TC";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Tuvalu";
NewCountry.Code = "TV";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Uganda";
NewCountry.Code = "UG";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Ukraine";
NewCountry.Code = "UA";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "United Arab Emirates";
NewCountry.Code = "AE";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "United Kingdom";
NewCountry.Code = "GB";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "United States";
NewCountry.Code = "US";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "United States Minor Outlying Islands";
NewCountry.Code = "UM";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Uruguay";
NewCountry.Code = "UY";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Uzbekistan";
NewCountry.Code = "UZ";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Vanuatu";
NewCountry.Code = "VU";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Venezuela, Bolivarian Republic of";
NewCountry.Code = "VE";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Viet Nam";
NewCountry.Code = "VN";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Virgin Islands, British";
NewCountry.Code = "VG";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Virgin Islands, U.S.";
NewCountry.Code = "VI";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Wallis and Futuna";
NewCountry.Code = "WF";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Western Sahara";
NewCountry.Code = "EH";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Yemen";
NewCountry.Code = "YE";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Zambia";
NewCountry.Code = "ZM";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Zimbabwe";
NewCountry.Code = "ZW";
NewCountry.Write();
		
		// VAT Setup
		
		Constants.DefaultPurchaseVAT.Set(Catalogs.VATCodes.S);
		Constants.DefaultSalesVAT.Set(Catalogs.VATCodes.S);
		Constants.PriceIncludesVAT.Set(True);
		
		VATCode = Catalogs.VATCodes.S.GetObject();
		VATCode.Description = "Zero-rated (0%)";
		VATCode.SalesInclRate = 0;
		VATCode.SalesExclRate = 0;
		VATCode.SalesAccount = ChartsOfAccounts.ChartOfAccounts.TaxPayable;
		VATCode.PurchaseInclRate = 0;
		VATCode.PurchaseExclRate = 0;
		VATCode.PurchaseAccount = ChartsOfAccounts.ChartOfAccounts.TaxPayable;		
		VATCode.Write();
		
		//
		
		Constants.CF1Type.Set("None");
		Constants.CF2Type.Set("None");
		Constants.CF3Type.Set("None");
		
		// Turning on the Projects functionality
		
		//Constants.Projects.Set(True);
		
		// mt_change	
	
		
	CommitTransaction();
	
	Constants.FirstLaunch.Set(True);
	
EndIf;
	
EndProcedure // FirstLaunch()


