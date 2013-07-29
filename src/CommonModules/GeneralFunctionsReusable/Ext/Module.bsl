//////////////////////////////////////////////////////////////////////////////// 
// THIS MODULE CONTAINS GENERAL FUNCTIONS AND PROCEDURES
// THAT RETURN RESULTS THAT DON'T CHANGE FREQUENTLY, AND ARE
// REUSABLE IN A SESSION TO MINIMIZE SERVER CALLS
// 


// Returns a value of a functional option. Used for the following functional options
// that are desired to be reusable - units of measure, multi-location, multi-currency,
// SA financial localization, and US financial localization.
//
// Parameter:
// FOption - functional option name.
//
// Returned value:
// Boolean.
// 1 - the functional option is set, 0 - the functional option is not set.
//
Function FunctionalOptionValue(FOption) Export
	
	Return GetFunctionalOption(FOption);
	
EndFunction

// Returns the system's default currency.
//
// Returned value:
// Catalog.Currency.
//
Function DefaultCurrency() Export
	
	Return Constants.DefaultCurrency.Get();
	
EndFunction

// Returns the system's default currency symbol (e.g. "$").
//
// Returned value:
// String.
//
Function DefaultCurrencySymbol() Export

	DefaultCurrency = Constants.DefaultCurrency.Get();
	
	Return DefaultCurrency.Symbol; 

EndFunction

// Determines a name of the Customer constant for dynamic substitution in the documents,
// for example customers can be called Patients.
// 
Function GetCustomerName() Export
	
	Return Constants.CustomerName.Get();
	
EndFunction

// Determines a name of the Vendor constant for dynamic substitution in the documents,
// for example vendors can be called Suppliers.
//
Function GetVendorName() Export
	
	Return Constants.VendorName.Get();
	
EndFunction

// Returns the Bank account type
// 
// Returned value:
// Enum.AccountTypes
//
Function BankAccountType() Export
	
	Return Enums.AccountTypes.Bank;
	
EndFunction

// Returns the A/R account type
// 
// Returned value:
// Enum.AccountTypes
//
Function ARAccountType() Export
	
	Return Enums.AccountTypes.AccountsReceivable;
	
EndFunction

// Returns the A/P account type
// 
// Returned value:
// Enum.AccountTypes
//
Function APAccountType() Export
	
	Return Enums.AccountTypes.AccountsPayable;
	
EndFunction

// Returns the PriceIncludesVAT constant value
// 
// Returned value:
// Boolean
//
Function PriceIncludesVAT() Export
	
	Return Constants.PriceIncludesVAT.Get();

EndFunction


// Returns a Currency catalog empty value
//
// Returned value:
// Catalog.Currencies
//
Function CurrencyEmptyRef() Export
	
	Return Catalogs.Currencies.EmptyRef();
	
EndFunction

Function WeightedAverage() Export
	
	Return Enums.InventoryCosting.WeightedAverage;
	
EndFunction