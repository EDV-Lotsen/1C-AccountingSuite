//////////////////////////////////////////////////////////////////////////////// 
// THIS MODULE CONTAINS GENERAL FUNCTIONS AND PROCEDURES
// THAT RETURN RESULTS THAT DON'T CHANGE FREQUENTLY, AND ARE
// REUSABLE IN A SESSION TO MINIMIZE SERVER CALLS
// 

Function DisableAuditLogValue() Export
	
	Return Constants.DisableAuditLog.Get();
	
EndFunction


Function DisplayAPICodesSetting() Export
	
	Return Constants.display_api_codes.Get();
	
EndFunction

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

// Returns the Inventory account type
// 
// Returned value:
// Enum.AccountTypes
//
Function InventoryAccountType() Export
	
	Return Enums.AccountTypes.Inventory;
	
EndFunction

// Returns the A/R account type
// 
// Returned value:
// Enum.AccountTypes
//
Function ARAccountType() Export
	
	Return Enums.AccountTypes.AccountsReceivable;
	
EndFunction

// Returns the Other Current Asset account type
// 
// Returned value:
// Enum.AccountTypes
//
Function OtherCurrentAssetAccountType() Export
	
	Return Enums.AccountTypes.OtherCurrentAsset;
	
EndFunction

// Returns the Fixed Asset account type
// 
// Returned value:
// Enum.AccountTypes
//
Function FixedAssetAccountType() Export
	
	Return Enums.AccountTypes.FixedAsset;
	
EndFunction

// Returns the Accumulated Depreciation account type
// 
// Returned value:
// Enum.AccountTypes
//
Function AccumulatedDepreciationAccountType() Export
	
	Return Enums.AccountTypes.AccumulatedDepreciation;
	
EndFunction

// Returns the Other Non Current Asset account type
// 
// Returned value:
// Enum.AccountTypes
//
Function OtherNonCurrentAssetAccountType() Export
	
	Return Enums.AccountTypes.OtherNonCurrentAsset;
	
EndFunction

// Returns the A/P account type
// 
// Returned value:
// Enum.AccountTypes
//
Function APAccountType() Export
	
	Return Enums.AccountTypes.AccountsPayable;
	
EndFunction

// Returns the Other Current Liability account type
// 
// Returned value:
// Enum.AccountTypes
//
Function OtherCurrentLiabilityAccountType() Export
	
	Return Enums.AccountTypes.OtherCurrentLiability;
	
EndFunction

// Returns the Long Term Liability account type
// 
// Returned value:
// Enum.AccountTypes
//
Function LongTermLiabilityAccountType() Export
	
	Return Enums.AccountTypes.LongTermLiability;
	
EndFunction

// Returns the Equity account type
// 
// Returned value:
// Enum.AccountTypes
//
Function EquityAccountType() Export
	
	Return Enums.AccountTypes.Equity;
	
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

Function CashFlowOperatingSection() Export
	
	Return Enums.CashFlowSections.Operating;
	
EndFunction

Function CashFlowInvestingSection() Export
	
	Return Enums.CashFlowSections.Investing;
	
EndFunction

Function CashFlowFinancingSection() Export
	
	Return Enums.CashFlowSections.Financing;
	
EndFunction

// Returns typical format string for quantities.
//
// Returns:
//  String - Format string for quantities.
//
Function DefaultQuantityFormat() Export
	
	// Define format string.
	Return "NFD=" + DefaultQuantityPrecision() + "; NZ=";
	
EndFunction

// Returns typical precision for quantities.
//
// Returns:
//  Number - Quantity precision.
//
Function DefaultQuantityPrecision() Export
	
	// Define quantity precision.
	Return Format(Constants.QtyPrecision.Get(), "NFD=0; NZ=0; NG=0");
	
EndFunction

// Returns typical format string for amounts.
//
// Returns:
//  String - Format string for amounts.
//
Function DefaultAmountFormat() Export
	
	// Define format string.
	Return "NFD=2; NZ=";
	
EndFunction

// Returns typical format string for price.
//
// Returns:
// String - Format string for price.
//
Function DefaultPriceFormat() Export
	
	// Define format string.
	Return "NFD=" + DefaultPricePrecision();
	
EndFunction

// Returns typical precision for price.
//
// Returns:
// Number - Price precision.
//
Function DefaultPricePrecision() Export
	
	// Define price precision.
	PricePrecision = 2;
	
	If Constants.UsePricePrecision.Get() Then
		
		Precision = Constants.PricePrecision.Get(); 
		
		If Precision > 2 Then 
			PricePrecision = Precision;	
		EndIf;
		
	EndIf;
	
	Return Format(PricePrecision, "NFD=0; NZ=0; NG=0");
	
EndFunction

// Returns typical format string for price item.
//
// Parameter:
// Item - .
//
// Returns:
// String - Format string for price.
//
Function PriceFormatForOneItem(Item) Export
	
	// Define format string.
	Return "NFD=" + PricePrecisionForOneItem(Item);
	
EndFunction

// Returns typical precision for price item.
//
// Parameter:
// Item - .
//
// Returns:
// Number - Price precision.
//
Function PricePrecisionForOneItem(Item) Export
	
	// Define price precision.
	PricePrecision = 2;
	
	If Item.PricePrecision > 2 Then
		PricePrecision = Item.PricePrecision; 	
	EndIf;
	
	Return Format(PricePrecision, "NFD=0; NZ=0; NG=0");
	
EndFunction

