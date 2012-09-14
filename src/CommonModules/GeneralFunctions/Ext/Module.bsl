//////////////////////////////////////////////////////////////////////////////// 
// THIS MODULE CONTAINS GENERAL PURPOSE FUNCTIONS AND PROCEDURES
// 

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
Function RetailPrice(ActualDate, Product, Company, Currency) Export
		
	If GetFunctionalOption("AdvancedPricing") Then
		SelectParameters = New Structure;
		SelectParameters.Insert("Product", Product);
		SelectParameters.Insert("Company", Company);
		SelectParameters.Insert("Currency", Currency);
		ResourceValue = InformationRegisters.PriceList.GetLast(ActualDate, SelectParameters);
		Return ResourceValue.Price;
	Else
		SelectParameters = New Structure;
		SelectParameters.Insert("Product", Product);
		ResourceValue = InformationRegisters.PriceList.GetLast(ActualDate, SelectParameters);
		Return ResourceValue.Price;
	EndIf;	
		
EndFunction

// Determines an item's default sales unit of measure (U/M).
//
// Parameter:
// Catalog.Item - item for which the function selects its default U/M.
//
// Returned value:
// Catalog.UnitsOfMeasure - item's default U/M.
//
Function GetDefaultSalesUMForProduct(Product) Export
	
	Query = New Query("SELECT
	                  |	ProductsUnitsOfMeasure.UM
	                  |FROM
	                  |	Catalog.Products.UnitsOfMeasure AS ProductsUnitsOfMeasure
	                  |WHERE
	                  |	ProductsUnitsOfMeasure.Ref = &Product
	                  |	AND ProductsUnitsOfMeasure.DefaultSalesUM = TRUE");
		
	Query.SetParameter("Product", Product);
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Return Catalogs.UnitsOfMeasure.EmptyRef();
	Else
		Dataset = QueryResult.Unload();
		Return Dataset[0][0];
	EndIf;
				
EndFunction

// Determines an item's default purchase unit of measure (U/M).
//
// Parameter:
// Catalog.Items - item for which the function selects its default U/M.
//
// Returned value:
// Catalog.UnitsOfMeasure - item's default U/M.
//
Function GetDefaultPurchaseUMForProduct(Product) Export
	
	Query = New Query("SELECT
	                  |	ProductsUnitsOfMeasure.UM
	                  |FROM
	                  |	Catalog.Products.UnitsOfMeasure AS ProductsUnitsOfMeasure
	                  |WHERE
	                  |	ProductsUnitsOfMeasure.Ref = &Product
	                  |	AND ProductsUnitsOfMeasure.DefaultPurchaseUM = TRUE");
		
	Query.SetParameter("Product", Product);
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Return Catalogs.UnitsOfMeasure.EmptyRef()
	Else
		Dataset = QueryResult.Unload();
		Return Dataset[0][0];
	EndIf;
				
EndFunction


// Marks the document (receipt, sales receipt) as "deposited" (included) by a deposit document.
//
// Parameters:
// DocumentLine - document Ref for which the procedure sets the "deposited" attribute.
//
Procedure WriteDepositData(DocumentLine) Export
	
	Document = DocumentLine.GetObject();
	Document.Deposited = True;
	Document.Write();

EndProcedure

// Clears the "deposited" (included) by a deposit document value from the document (receipt,
// sales receipt)
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
// Used in payment and receipt documents to calculate exchange rate for each line item.
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

// Returns a conversion ratio between a U/M and its parent U/M.
//
// Parameter:
// Catalog.UnitsOfMeasure - unit of measure.
//
// Returned value:
// Number - conversion ration or 0 if no conversion ration found.
//
Function GetUMRatio(UM) Export
	
	If UM = Catalogs.UnitsOfMeasure.EmptyRef() Then
		Return 1;
	Else
		Return UM.ConversionRatio;
	EndIf;
	
EndFunction


// A universal function extensively used to retrieve object attributes.
//
// Parameter:
// Ref - Object reference (any configuration object).
// AttributeNames - list of attribute names.
//
// Returned value:
// Structure.
// A one-dimensional array with attribute values.
// For example the following function call GeneralFunctions.GetAttributeValues(Company,
// "Country, Employees")
// will select values of the Country and Employees attributes of the Company from the Companies
// catalog.
//
Function GetAttributeValues(Ref, AttributeNames) Export
 
	Query = New Query;
	Query.Text =
	"SELECT
	| " + AttributeNames + "
	|FROM
	| " + Ref.Metadata().FullName() + " AS Table
	|WHERE
	| Table.Ref = &Ref";
	Query.SetParameter("Ref", Ref);
	
	QueryDataset = Query.Execute().Choose();
	QueryDataset.Next();
	Result = New Structure(AttributeNames);
	FillPropertyValues(Result, QueryDataset);
	
	Return Result;
 
EndFunction

// A universal function extensively used to retrieve an object attribute.
// A subset of the GetAttributeValues
// function, returning one attribute rather then several.
//
// Parameter:
// Ref - Object reference (any configuration object).
// AttributeName - an attribute names.
//
// Returned value:
// Value of any requested type.
// For example the following function call GeneralFunctions.GetAttributeValues(Company, "Country")
// will select a value of the Country attribute of the Company from the Companies catalog.
//
Function GetAttributeValue(Ref, AttributeName) Export
 
	Result = GetAttributeValues(Ref, AttributeName);
	Return Result[AttributeName];
 
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
Function GetExchangeRate(Date, Currency, CrossCurrency) Export
		
	SelectParameters = New Structure;
	SelectParameters.Insert("Currency", Currency);
	SelectParameters.Insert("CrossCurrency", CrossCurrency);
	
	ResourceValue = InformationRegisters.ExchangeRates.GetLast(Date, SelectParameters);
	
	If ResourceValue.ExchangeRate = 0 Then
		Return 1;	
	Else
		Return ResourceValue.ExchangeRate;
	EndIf;
	
EndFunction

// Returns OurCompany.
// 
// Returned value:
// Catalog.Companies.
// 
Function GetOurCompany() Export
	
	Return Catalogs.Companies.OurCompany;
	
EndFunction

// Retrieves a value of the End Customer field on the Vendor Quote
//
// Parameters:
// Document.PurchaseQuote.
//
// Returned value:
// Catalog.Companies.
//
Function GetCustomerFromPurchaseQuote(Document) Export
	
	PurchaseQuote = Document.GetObject();	
	Return PurchaseQuote.EndCustomer;
	
EndFunction

Function GetBankFromPurchaseQuote(Document) Export
	
	PurchaseQuote = Document.GetObject();	
	Bank = GeneralFunctions.GetAttributeValue(PurchaseQuote.Company, "Bank");	
	Return Bank;
	
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

// A procedure that is run on the first start of the system
// pre-filling the database with default values.
//
Procedure FirstStart() Export
	
	If Constants.FirstStartCompleted.Get() = False Then
		
		// Adding account types to predefined accounts and
		// assigning default posting accounts.
		
		// Also assigning currency to the default bank account
		
		Account = ChartsOfAccounts.ChartOfAccounts.BankAccount.GetObject();
		Account.AccountType = Enums.AccountTypes.Bank;
		Account.Currency = Catalogs.Currencies.USD;
		Account.Write();
		Constants.BankAccount.Set(Account.Ref);
		
		Account = ChartsOfAccounts.ChartOfAccounts.UndepositedFunds.GetObject();
		Account.AccountType = Enums.AccountTypes.OtherCurrentAsset;
		Account.Write();
		Constants.UndepositedFundsAccount.Set(Account.Ref);
		
		Account = ChartsOfAccounts.ChartOfAccounts.AccountsReceivable.GetObject();
		Account.AccountType = Enums.AccountTypes.AccountsReceivable;
		Account.Currency = Catalogs.Currencies.USD;
		Account.CashFlowSection = Enums.CashFlowSections.Operating;
		Account.Write();
		
		USDCurrency = Catalogs.Currencies.USD.GetObject();
		USDCurrency.DefaultARAccount = Account.Ref;
		USDCurrency.Write();
				
		Account = ChartsOfAccounts.ChartOfAccounts.Inventory.GetObject();
		Account.AccountType = Enums.AccountTypes.Inventory;
		Account.CashFlowSection = Enums.CashFlowSections.Operating;
		Account.Write();
		Constants.InventoryAccount.Set(Account.Ref);
		
		Account = ChartsOfAccounts.ChartOfAccounts.AccountsPayable.GetObject();
		Account.AccountType = Enums.AccountTypes.AccountsPayable;
		Account.Currency = Catalogs.Currencies.USD;
		Account.CashFlowSection = Enums.CashFlowSections.Operating;
		Account.Write();
		
		USDCurrency = Catalogs.Currencies.USD.GetObject();
		USDCurrency.DefaultAPAccount = Account.Ref;
		USDCurrency.Write();
		
		Account = ChartsOfAccounts.ChartOfAccounts.SalesTaxPayable.GetObject();
		Account.AccountType = Enums.AccountTypes.OtherCurrentLiability;
		Account.CashFlowSection = Enums.CashFlowSections.Operating;
		Account.Write();
		Constants.SalesTaxPayableAccount.Set(Account.Ref);
				
		Account = ChartsOfAccounts.ChartOfAccounts.Income.GetObject();
		Account.AccountType = Enums.AccountTypes.Income;
		Account.CashFlowSection = Enums.CashFlowSections.Operating;
		Account.Write();
		Constants.IncomeAccount.Set(Account.Ref);
		
		Account = ChartsOfAccounts.ChartOfAccounts.COGS.GetObject();
		Account.AccountType = Enums.AccountTypes.CostOfSales;
		Account.CashFlowSection = Enums.CashFlowSections.Operating;
		Account.Write();
		Constants.COGSAccount.Set(Account.Ref);
		
		Account = ChartsOfAccounts.ChartOfAccounts.BankServiceCharge.GetObject();
		Account.AccountType = Enums.AccountTypes.OtherExpense;
		Account.CashFlowSection = Enums.CashFlowSections.Operating;
		Account.Write();
		Constants.BankServiceChargeAccount.Set(Account.Ref);
		
		Account = ChartsOfAccounts.ChartOfAccounts.BankInterestEarned.GetObject();
		Account.AccountType = Enums.AccountTypes.OtherIncome;
		Account.CashFlowSection = Enums.CashFlowSections.Operating;
		Account.Write();
		Constants.BankInterestEarnedAccount.Set(Account.Ref);
		
		Account = ChartsOfAccounts.ChartOfAccounts.ExchangeGain.GetObject();
		Account.AccountType = Enums.AccountTypes.OtherIncome;
		Account.CashFlowSection = Enums.CashFlowSections.Operating;
		Account.Write();
		Constants.ExchangeGain.Set(Account.Ref);
		
		Account = ChartsOfAccounts.ChartOfAccounts.ExchangeLoss.GetObject();
		Account.AccountType = Enums.AccountTypes.OtherExpense;
		Account.CashFlowSection = Enums.CashFlowSections.Operating;
		Account.Write();
		Constants.ExchangeLoss.Set(Account.Ref);
		
		Account = ChartsOfAccounts.ChartOfAccounts.Expense.GetObject();
		Account.AccountType = Enums.AccountTypes.Expense;
		Account.CashFlowSection = Enums.CashFlowSections.Operating;
		Account.Write();
		Constants.ExpenseAccount.Set(Account.Ref);
		
		Account = ChartsOfAccounts.ChartOfAccounts.AccumulatedOCI.GetObject();
		Account.AccountType = Enums.AccountTypes.Equity;
		Account.CashFlowSection = Enums.CashFlowSections.Operating;
		Account.Write();
		Constants.AccumulatedOCIAccount.Set(Account.Ref);
			
		// Adding OurCompany's full name
		
		OC = Catalogs.Companies.OurCompany.GetObject();
		OC.Name = "Our company full name";
		OC.Write();
				
		// Setting default location, currency, and beginning balances date
		
		Constants.DefaultLocation.Set(Catalogs.Locations.MainWarehouse);
		
		Constants.DefaultCurrency.Set(Catalogs.Currencies.USD);
		
		YearBeginning = BegOfYear(CurrentDate()); 
		Constants.BeginningBalancesDate.Set(YearBeginning);
		
		// Adding days to predefined payment terms and setting
		// a default payment term
		
		PT = Catalogs.PaymentTerms.DueOnReceipt.GetObject();
		PT.Days = 0;
		PT.Write();
		
		PT = Catalogs.PaymentTerms.Net5.GetObject();
		PT.Days = 5;
		PT.Write();
		
		PT = Catalogs.PaymentTerms.Net10.GetObject();
		PT.Days = 10;
		PT.Write();
		
		PT = Catalogs.PaymentTerms.Net15.GetObject();
		PT.Days = 15;
		PT.Write();
		
		PT = Catalogs.PaymentTerms.Net30.GetObject();
		PT.Days = 30;
		PT.Write();
		
		PT = Catalogs.PaymentTerms.Net60.GetObject();
		PT.Days = 60;
		PT.Write();
		
		Constants.PaymentTermsDefault.Set(Catalogs.PaymentTerms.Net30);
		
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
		
		NewUser = InfoBaseUsers.CreateUser();
		NewUser.Name = "User";
		Role = Metadata.Roles.Find("FullRights");
		NewUser.Roles.Add(Role);
		NewUser.Write();
		
		// Setting the Brazil ICMS default tax constant
		
		Constants.BrazilICMSTaxDefault.Set(18);
		
		// Assigning currency symbols
				
		Currency = Catalogs.Currencies.USD.GetObject();
		Currency.Symbol = "$";
		Currency.Write();
						
		// Setting the Disable LIFO constant
		
		Constants.DisableLIFO.Set(False);
		
		// Setting Customer Name and Vendor Name constants
		
		Constants.CustomerName.Set("Customer");
		Constants.VendorName.Set("Vendor");
				
		// Setting the First Start Completed constant to prevent
		// this procedure from running on subsequent system starts
		
		Constants.FirstStartCompleted.Set(True);
		
	EndIf;	
	
EndProcedure

// The procedure is launched when the South Africa financial localization is turned on in Settings
// and prefills the database with default values and settings for VAT.
//
Procedure VATSetup() Export
	
	If Constants.VATSetupCompleted.Get() = False Then
				
		Constants.DefaultPurchaseVAT.Set(Catalogs.VATCodes.S);
		Constants.DefaultSalesVAT.Set(Catalogs.VATCodes.S);
		
		VATAccount = ChartsOfAccounts.ChartOfAccounts.CreateAccount();
		VATAccount.Description = "VAT payable";
		VATAccount.Code = 320;
		VATAccount.AccountType = Enums.AccountTypes.OtherCurrentLiability;
		VATAccount.CashFlowSection = Enums.CashFlowSections.Operating;
		VATAccount.Write();
		Constants.VATAccount.Set(VATAccount.Ref);		
		
		VATAgency = Catalogs.Companies.CreateItem();
		VATAgency.ExpenseAccount = Constants.ExpenseAccount.Get();
		VATAgency.IncomeAccount = Constants.IncomeAccount.Get();
		VATAgency.Name = "VAT Agency";
		VATAgency.Description = "VAT Agency";
		VATAgency.Customer = True;
		VATAgency.Vendor = True;
		VATAgency.Write();
		
		VATCode = Catalogs.VATCodes.S.GetObject();
		VATCode.Taxable = True;
		VATCode.VATDescription = "Standard (14%)";
		
		VATSales = VATCode.SalesItems.Add();
		VATSales.Name = "Sales";
		VATSales.Rate = 14;
		VATSales.ReturnBox = Catalogs.VATReturnFormBoxes.Box1;
		VATSales.Agency = VATAgency.Ref;
		
		VATPurchase = VATCode.PurchaseItems.Add();
		VATPurchase.Name = "Purchase";
		VATPurchase.Rate = 14;
		VATPurchase.ReturnBox = Catalogs.VATReturnFormBoxes.Box14;
		VATPurchase.Agency = VATAgency.Ref;
		
		VATCode.Write();
		
		Constants.VATSetupCompleted.Set(True);
		
	EndIf;
		
EndProcedure

// Calculates the next check number for a selected bank account.
//
// Parameters:
// ChartOfAccounts.ChartOfAccounts.
//
// Returned value:
// Number
//
Function NextCheckNumber(BankAccount) Export
	
	Query = New Query("SELECT
	                  |	Check.Number AS Number
	                  |FROM
	                  |	Document.Check AS Check
	                  |WHERE
	                  |	Check.BankAccount = &BankAccount
	                  |
	                  |ORDER BY
	                  |	Number DESC");
	Query.SetParameter("BankAccount", BankAccount);	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then		
		Return 1;
	Else
		Dataset = QueryResult.Unload();
		LastNumber = Dataset[0][0];
		Return LastNumber + 1;
	EndIf;			
	
EndFunction
