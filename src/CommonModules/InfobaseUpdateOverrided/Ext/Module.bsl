
///////////////////////////////////////////////////////////////////////////////
// INTERFACE PART OF THE OVERRIDED MODULE

// Returns list of IB update handler-procedures for all supported IB versions.
//
// Example of adding of handler-procedure to the list:
//    Handler			 = Handlers.Add();
//    Handler.Version	 = "1.0.0.0";
//    Handler.Procedure  = "IBUpdate.GoToVersion_1_0_0_0";
//
// Called before IB data update start.
//
Function UpdateHandlers() Export
	
	Handlers = InfobaseUpdate.NewUpdateHandlersTable();
	
	// Connecting procedures-handlers of configuration update
	Handler			 	= Handlers.Add();
	Handler.Version 	= "1.0.0.0";
	Handler.Procedure 	= "InfobaseUpdateOverrided.FirstLaunch";
	
	Return Handlers;
	
EndFunction // UpdateHandlers()

// Called after completion of infobase data update.
//
// Parameters:
//   PreviousInfobaseVersion     	 - String 	 - IB version before update. "0.0.0.0" for "empty" IB.
//   CurrentInfobaseVersion        - String  	 - IB version after update.
//   ExecutedHandlers 		 - ValueTree - list of executed update handler-procedures,
//                                             grouped by version number.
//  Iteration over the executed handlers:
//		For Each Version In ExecutedHandlers.Rows Do
//
//			If Version.Version = "*" Then
//				group of handlers, that are always executed
//			Else
//				group of handlers, executed for the specific version
//			EndIf;
//
//			For Each Handler In Version.Rows Do
//				...
//			EndDo;
//
//		EndDo;
//
//   OutputUpdatesDetails - Boolean -	if True, then show form with description
//											of the updates.
//
Procedure AfterUpdate(Val PreviousInfobaseVersion, Val CurrentInfobaseVersion, 
	Val ExecutedHandlers, OutputUpdatesDetails) Export
	
	// This handler can be used to apply special changes of standard subsystems
	// after update of infobase
	
EndProcedure

///////////////////////////////////////////////////////////////////////////////
// PROCEDURES AND FUNCTIONS OF INFOBASE UPDATE

// Procedure fills empty IB.
//
Procedure FirstLaunch() Export
	
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
		
		OC = Catalogs.Companies.OurCompany.GetObject();
		OC.Description = "Our company full name";
		OC.Terms = Catalogs.PaymentTerms.Net30;
		OC.Write();
		
		AddressLine = Catalogs.Addresses.CreateItem();
		AddressLine.Owner = Catalogs.Companies.OurCompany;
		AddressLine.Description = "Primary";
		AddressLine.DefaultShipping = True;
		AddressLine.DefaultBilling = True;
		AddressLine.Write();
		
		// Setting default location, currency, and beginning balances date
		
		Constants.DefaultCurrency.Set(Catalogs.Currencies.USD);
		
		// Adding days to predefined payment terms and setting
		// a default payment term
				
		PT = Catalogs.PaymentTerms.Net30.GetObject();
		PT.Days = 30;
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
		
		NewUser = InfoBaseUsers.CreateUser();
		NewUser.Name = "Administrator";
		Role = Metadata.Roles.Find("FullAccess");
		NewUser.Roles.Add(Role);
		NewUser.Write();
				
		// Assigning currency symbols
				
		Currency = Catalogs.Currencies.USD.GetObject();
		Currency.Symbol = "$";
		Currency.Write();
						
		// Setting the Disable LIFO constant
		
		Constants.DisableLIFO.Set(False);
		
		// Setting Customer Name and Vendor Name constants
		
		Constants.CustomerName.Set("Customer");
		Constants.VendorName.Set("Vendor");
		
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
		
		// Turning on the Projects functionality
		
		//Constants.Projects.Set(True);
		
	CommitTransaction();
	
EndProcedure // FirstLaunch()
