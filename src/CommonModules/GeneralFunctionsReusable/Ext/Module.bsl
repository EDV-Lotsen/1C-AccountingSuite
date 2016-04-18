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

// Returns the system title constant
//
// Returned value:
// String.
//
Function GetSystemTitle() Export
	
	Return Constants.SystemTitle.Get();	
	
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

Function DisableAuditLogValue() Export
	
	Return Constants.DisableAuditLog.Get();
	
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
	
	NumPrecision = DefaultPricePrecision();
	NumLength    = 13 + NumPrecision;
	
	// Define format string.
	Return "ND=" + NumLength + "; NFD=" + NumPrecision;
	
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
	
	NumPrecision = PricePrecisionForOneItem(Item);
	NumLength    = 13 + NumPrecision;
	// Define format string.
	Return "ND=" + NumLength + "; NFD=" + NumPrecision;
	
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

//++ MisA 11/14/2014 ... 11/17/2014

// Return list of types, allowed for change to.
// Param 
//   SourceType - account type, mainly in reference
// Return
//   List of allowed for changes types 
Function GetAcceptableAccountTypesForChange (SourceType) Export
	
	// hot fix - use mapping table
	// beter to use register or smthg similar to easy maintaining
		
	MainTableOfAcceptableTypes = New ValueTable;
	TypeArray = New Array;
	TypeArray.Add(Type("EnumRef.AccountTypes"));
	AccountTypesDescription = New TypeDescription(TypeArray);
	MainTableOfAcceptableTypes.Columns.Add("Source",AccountTypesDescription);
	MainTableOfAcceptableTypes.Columns.Add("Acceptable",AccountTypesDescription);
	
	// Expense 			<-> Cost of sales,	
	// Expense 			->  Other Expense,  
	// Cost of sales  	->  Other Expense
	
	NewRow = MainTableOfAcceptableTypes.Add();
	NewRow.Source =  Enums.AccountTypes.CostOfSales;
	NewRow.Acceptable =  Enums.AccountTypes.OtherExpense;
	
	NewRow = MainTableOfAcceptableTypes.Add();
	NewRow.Source =  Enums.AccountTypes.CostOfSales;
	NewRow.Acceptable =  Enums.AccountTypes.Expense;
	
	NewRow = MainTableOfAcceptableTypes.Add();
	NewRow.Source =  Enums.AccountTypes.Expense;
	NewRow.Acceptable =  Enums.AccountTypes.OtherExpense;
	
	NewRow = MainTableOfAcceptableTypes.Add();
	NewRow.Source =  Enums.AccountTypes.Expense;
	NewRow.Acceptable =  Enums.AccountTypes.CostOfSales;
	
	// OtherExpense 	-> Expense 
	// OtherExpense 	-> CostOfSales 
	// OtherExpense 	-> OtherCurrentAsset
	// OtherExpense 	-> FixedAsset
	// OtherExpense 	-> AccumulatedDepreciation 
	// OtherExpense 	-> OtherNonCurrentAsset 
	// OtherExpense 	-> OtherCurrentLiability
	// OtherExpense 	-> LongTermLiability
	// OtherExpense 	-> Equity
	
	NewRow = MainTableOfAcceptableTypes.Add();
	NewRow.Source =  Enums.AccountTypes.OtherExpense;
	NewRow.Acceptable =  Enums.AccountTypes.Expense;
	
	NewRow = MainTableOfAcceptableTypes.Add();
	NewRow.Source =  Enums.AccountTypes.OtherExpense;
	NewRow.Acceptable =  Enums.AccountTypes.CostOfSales;
		
	//ACS-2071/ACS-2205 {{
	//NewRow = MainTableOfAcceptableTypes.Add();
	//NewRow.Source =  Enums.AccountTypes.OtherExpense;
	//NewRow.Acceptable =  Enums.AccountTypes.OtherCurrentAsset;
	
	//NewRow = MainTableOfAcceptableTypes.Add();
	//NewRow.Source =  Enums.AccountTypes.OtherExpense;
	//NewRow.Acceptable =  Enums.AccountTypes.FixedAsset;
	
	//NewRow = MainTableOfAcceptableTypes.Add();
	//NewRow.Source =  Enums.AccountTypes.OtherExpense;
	//NewRow.Acceptable =  Enums.AccountTypes.AccumulatedDepreciation;
	
	//NewRow = MainTableOfAcceptableTypes.Add();
	//NewRow.Source =  Enums.AccountTypes.OtherExpense;
	//NewRow.Acceptable =  Enums.AccountTypes.OtherNonCurrentAsset;
	
	//NewRow = MainTableOfAcceptableTypes.Add();
	//NewRow.Source =  Enums.AccountTypes.OtherExpense;
	//NewRow.Acceptable =  Enums.AccountTypes.OtherCurrentLiability;
	
	//NewRow = MainTableOfAcceptableTypes.Add();
	//NewRow.Source =  Enums.AccountTypes.OtherExpense;
	//NewRow.Acceptable =  Enums.AccountTypes.LongTermLiability;
	
	//NewRow = MainTableOfAcceptableTypes.Add();
	//NewRow.Source =  Enums.AccountTypes.OtherExpense;
	//NewRow.Acceptable =  Enums.AccountTypes.Equity;
	//}}ACS-2071/ACS-2205
	
	
	// FixedAsset <-> OtherCurrentAsset <-> AccumulatedDepreciation
	
	NewRow = MainTableOfAcceptableTypes.Add();
	NewRow.Source =  Enums.AccountTypes.FixedAsset;
	NewRow.Acceptable =  Enums.AccountTypes.OtherCurrentAsset;
	
	NewRow = MainTableOfAcceptableTypes.Add();
	NewRow.Source =  Enums.AccountTypes.FixedAsset;
	NewRow.Acceptable =  Enums.AccountTypes.AccumulatedDepreciation;
	
	NewRow = MainTableOfAcceptableTypes.Add();
	NewRow.Source =  Enums.AccountTypes.AccumulatedDepreciation;
	NewRow.Acceptable =  Enums.AccountTypes.OtherCurrentAsset;
	
	NewRow = MainTableOfAcceptableTypes.Add();
	NewRow.Source =  Enums.AccountTypes.AccumulatedDepreciation;
	NewRow.Acceptable =  Enums.AccountTypes.FixedAsset;
	
	NewRow = MainTableOfAcceptableTypes.Add();
	NewRow.Source =  Enums.AccountTypes.OtherCurrentAsset;
	NewRow.Acceptable =  Enums.AccountTypes.AccumulatedDepreciation;
	
	NewRow = MainTableOfAcceptableTypes.Add();
	NewRow.Source =  Enums.AccountTypes.OtherCurrentAsset;
	NewRow.Acceptable =  Enums.AccountTypes.FixedAsset;
	
	// Income <-> Other Income
	
	NewRow = MainTableOfAcceptableTypes.Add();
	NewRow.Source =  Enums.AccountTypes.Income;
	NewRow.Acceptable =  Enums.AccountTypes.OtherIncome;
	
	NewRow = MainTableOfAcceptableTypes.Add();
	NewRow.Source =  Enums.AccountTypes.OtherIncome;
	NewRow.Acceptable =  Enums.AccountTypes.Income;
	
	// OtherCurrentAsset 		-> Bank, 
	// FixedAsset 				-> Bank, 
	// AccumulatedDepreciation 	-> Bank
	// OtherExpense 			-> Bank
	
	NewRow = MainTableOfAcceptableTypes.Add();
	NewRow.Source =  Enums.AccountTypes.OtherCurrentAsset;
	NewRow.Acceptable =  Enums.AccountTypes.Bank;
	
	NewRow = MainTableOfAcceptableTypes.Add();
	NewRow.Source =  Enums.AccountTypes.FixedAsset;
	NewRow.Acceptable =  Enums.AccountTypes.Bank;
	
	NewRow = MainTableOfAcceptableTypes.Add();
	NewRow.Source =  Enums.AccountTypes.AccumulatedDepreciation;
	NewRow.Acceptable =  Enums.AccountTypes.Bank;
	
	//// In case if will make adjustable matching list - just change source from table to other source.
	Query = New Query;
	Query.TempTablesManager =  New TempTablesManager;
	Query.SetParameter("SourceTable", MainTableOfAcceptableTypes);
	Query.SetParameter("SourceType", SourceType);
		
	Query.Text =
	"SELECT ALLOWED 
	|	SourceTable.Source,
	|	SourceTable.Acceptable
	|INTO 
	|	MatchingTable
	|FROM  
	|	&SourceTable as SourceTable
	|INDEX BY  
	|	SourceTable.Source
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MatchingTable.Acceptable
	|FROM
	|	MatchingTable as MatchingTable
	|WHERE
	|		MatchingTable.source = &SourceType
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|DROP MatchingTable;
	|";
	
	Result = Query.Execute().Unload().UnloadColumn("Acceptable");
	Result.Add(SourceType);
	
	Return Result;
	
EndFunction

// Return wheather acount type is currency related, like "Bank" etc.
// Param 
//   SourceType - account type, mainly in reference
// Return
//   true or false 
Function CurrencyUsedAccountType(SourceType) Export
	
	If SourceType = Enums.AccountTypes.Bank 
		 or SourceType = Enums.AccountTypes.AccountsPayable
		 or SourceType = Enums.AccountTypes.AccountsReceivable  Then 
		Return True;
	Else
		Return False
	EndIf;		
	
EndFunction

//-- MisA 11/14/2014 ... 11/17/2014