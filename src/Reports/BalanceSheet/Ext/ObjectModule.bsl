Function BalanceSheet(Date) Export
		
	If Date = Date(1,1,1) Then
		Date = CurrentDate();		
	EndIf;
	
	PeriodLabel = Format(Date, "DLF=D");
	
	ReportDate = BegOfDay(Date) + 60 * 60 * 24;
	
	OurCompany = Catalogs.Companies.OurCompany;
	
	SpreadsheetDocument = New SpreadsheetDocument;
	Template = GetTemplate("Template");
	
	Header = Template.GetArea("Header");
	Header.Parameters.PeriodLabel = PeriodLabel;
	Header.Parameters.Company = GeneralFunctions.GetAttributeValue(OurCompany, "Name");
	SpreadsheetDocument.Put(Header);
	
	Reg = AccountingRegisters.GeneralJournal;
	
	// Creating the OCI transactions value table
	
	OCITransactions = New ValueTable();
	OCITransactions.Columns.Add("Account");
	OCITransactions.Columns.Add("AmountRC");
		
	// Assets header section
	
	AssetsHeader = Template.GetArea("AssetsHeader");
	SpreadsheetDocument.Put(AssetsHeader);
	
	// Accumulating other comprehensive income
	
	TotalOCI = 0;
	
	// Bank section	
	
	BankBalance = 0;
	
	Bank = Template.GetArea("Bank");
	
	Query = New Query("SELECT
	                  |	ChartOfAccounts.Ref
	                  |FROM
	                  |	ChartOfAccounts.ChartOfAccounts AS ChartOfAccounts
	                  |WHERE
	                  |	ChartOfAccounts.AccountType = VALUE(Enum.AccountTypes.Bank)
	                  |
	                  |ORDER BY
	                  |	ChartOfAccounts.Code");	
	
	QueryResult = Query.Execute();

	If QueryResult.IsEmpty() Then
	Else
		RecorderDataset = QueryResult.Choose();
		While RecorderDataset.Next() Do
			
			Filter = New Structure("Account", RecorderDataset.Ref);	
			RecordSelection = Reg.Balance(ReportDate,,Filter);
			
			NoOfRows = RecordSelection.Count();
			If NoOfRows = 0 Then
			Else
				
				AccountCurrency = RecorderDataset.Ref.Currency;
				ExchangeRate = GeneralFunctions.GetExchangeRate(Date, GeneralFunctionsReusable.DefaultCurrency(), AccountCurrency);

				BalanceClosingRate = 0;
				BalanceClosingRate = (RecordSelection.Total("AmountBalanceDr") - RecordSelection.Total("AmountBalanceCr")) * ExchangeRate; 
				
				Balance = 0;				
				Balance = RecordSelection.Total("AmountRCBalanceDr") - RecordSelection.Total("AmountRCBalanceCr");
				
				BankBalance = BankBalance + BalanceClosingRate;				
				
				AccountOCI = 0;
				AccountOCI = BalanceClosingRate - Balance;
				TotalOCI = TotalOCI + AccountOCI;
				
				If AccountOCI <> 0 Then						
					OCITransactionsRow = OCITransactions.Add();
					OCITransactionsRow.Account = RecorderDataset.Ref;
					OCITransactionsRow.AmountRC = AccountOCI;
				EndIf;
				
				Selection = New Structure("Account, Balance");
				Selection.Insert("Account", RecorderDataset.Ref.Description);
				Selection.Insert("Balance", BalanceClosingRate);
				
				Bank.Parameters.Fill(Selection);
				SpreadsheetDocument.Put(Bank);				 
			EndIf;			
		EndDo;
	EndIf;
	
	// Inventory section
	
	InventoryBalance = 0;
	
	Inventory = Template.GetArea("Inventory");
	
	Query = New Query("SELECT
	                  |	ChartOfAccounts.Ref
	                  |FROM
	                  |	ChartOfAccounts.ChartOfAccounts AS ChartOfAccounts
	                  |WHERE
	                  |	ChartOfAccounts.AccountType = VALUE(Enum.AccountTypes.Inventory)
	                  |
	                  |ORDER BY
	                  |	ChartOfAccounts.Code");	
	
	QueryResult = Query.Execute();

	If QueryResult.IsEmpty() Then
	Else
		RecorderDataset = QueryResult.Choose();
		While RecorderDataset.Next() Do
			
			Filter = New Structure("Account", RecorderDataset.Ref);	
			RecordSelection = Reg.Balance(ReportDate,,Filter);
			
			NoOfRows = RecordSelection.Count();
			If NoOfRows = 0 Then
			Else
				Balance = 0;
				Balance = RecordSelection.Total("AmountRCBalanceDr") - RecordSelection.Total("AmountRCBalanceCr");
				InventoryBalance = InventoryBalance + Balance;
				
				Selection = New Structure("Account, Balance");
				Selection.Insert("Account", RecorderDataset.Ref.Description);
				Selection.Insert("Balance", Balance);
				
				Inventory.Parameters.Fill(Selection);
				SpreadsheetDocument.Put(Inventory);				 
			EndIf;			
		EndDo;
	EndIf;
	
	// AR
	
	ARBalance = 0;
	
	AR = Template.GetArea("AR");
	
	Query = New Query("SELECT
	                  |	ChartOfAccounts.Ref
	                  |FROM
	                  |	ChartOfAccounts.ChartOfAccounts AS ChartOfAccounts
	                  |WHERE
	                  |	ChartOfAccounts.AccountType = VALUE(Enum.AccountTypes.AccountsReceivable)
	                  |
	                  |ORDER BY
	                  |	ChartOfAccounts.Code");	
	
	QueryResult = Query.Execute();

	If QueryResult.IsEmpty() Then
	Else
		RecorderDataset = QueryResult.Choose();
		While RecorderDataset.Next() Do
			
			Filter = New Structure("Account", RecorderDataset.Ref);	
			RecordSelection = Reg.Balance(ReportDate,,Filter);
			
			NoOfRows = RecordSelection.Count();
			If NoOfRows = 0 Then
			Else
								
				AccountCurrency = RecorderDataset.Ref.Currency;
				ExchangeRate = GeneralFunctions.GetExchangeRate(Date, GeneralFunctionsReusable.DefaultCurrency(), AccountCurrency);

				BalanceClosingRate = 0;
				BalanceClosingRate = (RecordSelection.Total("AmountBalanceDr") - RecordSelection.Total("AmountBalanceCr")) * ExchangeRate; 
				
				Balance = 0;
				Balance = RecordSelection.Total("AmountRCBalanceDr") - RecordSelection.Total("AmountRCBalanceCr");
				
				ARBalance = ARBalance + BalanceClosingRate;
				
				AccountOCI = 0;
				AccountOCI = BalanceClosingRate - Balance;
				TotalOCI = TotalOCI + AccountOCI;
				
				If AccountOCI <> 0 Then						
					OCITransactionsRow = OCITransactions.Add();
					OCITransactionsRow.Account = RecorderDataset.Ref;
					OCITransactionsRow.AmountRC = AccountOCI;
				EndIf;
				
				Selection = New Structure("Account, Balance");
				Selection.Insert("Account", RecorderDataset.Ref.Description);
				Selection.Insert("Balance", BalanceClosingRate);
				
				AR.Parameters.Fill(Selection);
				SpreadsheetDocument.Put(AR);				 
			EndIf;			
		EndDo;
	EndIf;

	// Other current assets section
	
	OtherCurrentAssetsBalance = 0;
	
	OtherCurrentAssets = Template.GetArea("OtherCurrentAssets");
	
	Query = New Query("SELECT
	                  |	ChartOfAccounts.Ref
	                  |FROM
	                  |	ChartOfAccounts.ChartOfAccounts AS ChartOfAccounts
	                  |WHERE
	                  |	ChartOfAccounts.AccountType = VALUE(Enum.AccountTypes.OtherCurrentAsset)
	                  |
	                  |ORDER BY
	                  |	ChartOfAccounts.Code");	
	
	QueryResult = Query.Execute();

	If QueryResult.IsEmpty() Then
	Else
		RecorderDataset = QueryResult.Choose();
		While RecorderDataset.Next() Do
			
			Filter = New Structure("Account", RecorderDataset.Ref);	
			RecordSelection = Reg.Balance(ReportDate,,Filter);
			
			NoOfRows = RecordSelection.Count();
			If NoOfRows = 0 Then
			Else
				Balance = 0;
				Balance = RecordSelection.Total("AmountRCBalanceDr") - RecordSelection.Total("AmountRCBalanceCr");
				OtherCurrentAssetsBalance = OtherCurrentAssetsBalance + Balance;
				
				Selection = New Structure("Account, Balance");
				Selection.Insert("Account", RecorderDataset.Ref.Description);
				Selection.Insert("Balance", Balance);
				
				OtherCurrentAssets.Parameters.Fill(Selection);
				SpreadsheetDocument.Put(OtherCurrentAssets);				 
			EndIf;			
		EndDo;
	EndIf;

	// Total current assets section
	
	TotalCurrentAssetsBalance = BankBalance + InventoryBalance + ARBalance + OtherCurrentAssetsBalance;
	
	TotalCurrentAssets = Template.GetArea("TotalCurrentAssets");
	TotalCurrentAssets.Parameters.TotalCurrentAssets = TotalCurrentAssetsBalance;
	SpreadsheetDocument.Put(TotalCurrentAssets);

	// Noncurrent assets header section
	
	NoncurrentAssetsHeader = Template.GetArea("NoncurrentAssetsHeader");
	SpreadsheetDocument.Put(NoncurrentAssetsHeader);
	
	// Fixed assets section
	
	FixedAssetsBalance = 0;
	
	FixedAssets = Template.GetArea("FixedAssets");
	
	Query = New Query("SELECT
	                  |	ChartOfAccounts.Ref
	                  |FROM
	                  |	ChartOfAccounts.ChartOfAccounts AS ChartOfAccounts
	                  |WHERE
	                  |	ChartOfAccounts.AccountType = VALUE(Enum.AccountTypes.FixedAsset)
	                  |
	                  |ORDER BY
	                  |	ChartOfAccounts.Code");	
	
	QueryResult = Query.Execute();

	If QueryResult.IsEmpty() Then
	Else
		RecorderDataset = QueryResult.Choose();
		While RecorderDataset.Next() Do
			
			Filter = New Structure("Account", RecorderDataset.Ref);	
			RecordSelection = Reg.Balance(ReportDate,,Filter);
			
			NoOfRows = RecordSelection.Count();
			If NoOfRows = 0 Then
			Else
				Balance = 0;
				Balance = RecordSelection.Total("AmountRCBalanceDr") - RecordSelection.Total("AmountRCBalanceCr");
				FixedAssetsBalance = FixedAssetsBalance + Balance;
				
				Selection = New Structure("Account, Balance");
				Selection.Insert("Account", RecorderDataset.Ref.Description);
				Selection.Insert("Balance", Balance);
				
				FixedAssets.Parameters.Fill(Selection);
				SpreadsheetDocument.Put(FixedAssets);				 
			EndIf;			
		EndDo;
	EndIf;
	
	// Depreciation
	
	DepreciationBalance = 0;
	
	Depreciation = Template.GetArea("Depreciation");
	
	Query = New Query("SELECT
	                  |	ChartOfAccounts.Ref
	                  |FROM
	                  |	ChartOfAccounts.ChartOfAccounts AS ChartOfAccounts
	                  |WHERE
	                  |	ChartOfAccounts.AccountType = VALUE(Enum.AccountTypes.AccumulatedDepreciation)
	                  |
	                  |ORDER BY
	                  |	ChartOfAccounts.Code");	
	
	QueryResult = Query.Execute();

	If QueryResult.IsEmpty() Then
	Else
		RecorderDataset = QueryResult.Choose();
		While RecorderDataset.Next() Do
			
			Filter = New Structure("Account", RecorderDataset.Ref);	
			RecordSelection = Reg.Balance(ReportDate,,Filter);
			
			NoOfRows = RecordSelection.Count();
			If NoOfRows = 0 Then
			Else
				Balance = 0;
				Balance = RecordSelection.Total("AmountRCBalanceDr") - RecordSelection.Total("AmountRCBalanceCr");
				DepreciationBalance = DepreciationBalance + Balance;
				
				Selection = New Structure("Account, Balance");
				Selection.Insert("Account", RecorderDataset.Ref.Description);
				Selection.Insert("Balance", Balance);
				
				Depreciation.Parameters.Fill(Selection);
				SpreadsheetDocument.Put(Depreciation);				 
			EndIf;			
		EndDo;
	EndIf;

	// Other noncurrent assets section
	
	OtherNoncurrentAssetsBalance = 0;
	
	OtherNoncurrentAssets = Template.GetArea("OtherNoncurrentAssets");
	
	Query = New Query("SELECT
	                  |	ChartOfAccounts.Ref
	                  |FROM
	                  |	ChartOfAccounts.ChartOfAccounts AS ChartOfAccounts
	                  |WHERE
	                  |	ChartOfAccounts.AccountType = VALUE(Enum.AccountTypes.OtherNoncurrentAsset)
	                  |
	                  |ORDER BY
	                  |	ChartOfAccounts.Code");	
	
	QueryResult = Query.Execute();

	If QueryResult.IsEmpty() Then
	Else
		RecorderDataset = QueryResult.Choose();
		While RecorderDataset.Next() Do
			
			Filter = New Structure("Account", RecorderDataset.Ref);	
			RecordSelection = Reg.Balance(ReportDate,,Filter);
			
			NoOfRows = RecordSelection.Count();
			If NoOfRows = 0 Then
			Else
				Balance = 0;
				Balance = RecordSelection.Total("AmountRCBalanceDr") - RecordSelection.Total("AmountRCBalanceCr");
				OtherNoncurrentAssetsBalance = OtherNoncurrentAssetsBalance + Balance;
				
				Selection = New Structure("Account, Balance");
				Selection.Insert("Account", RecorderDataset.Ref.Description);
				Selection.Insert("Balance", Balance);
				
				OtherNoncurrentAssets.Parameters.Fill(Selection);
				SpreadsheetDocument.Put(OtherNoncurrentAssets);				 
			EndIf;			
		EndDo;
	EndIf;
	
	// Total noncurrent assets section
	
	TotalNoncurrentAssetsBalance = FixedAssetsBalance + DepreciationBalance + OtherNoncurrentAssetsBalance;
	
	TotalNoncurrentAssets = Template.GetArea("TotalNoncurrentAssets");
	TotalNoncurrentAssets.Parameters.TotalNoncurrentAssets = TotalNoncurrentAssetsBalance;
	SpreadsheetDocument.Put(TotalNoncurrentAssets);
	
	// Total assets section
	
	TotalAssetsBalance = TotalCurrentAssetsBalance + TotalNoncurrentAssetsBalance;
	
	TotalAssets = Template.GetArea("TotalAssets");
	TotalAssets.Parameters.TotalAssets = TotalAssetsBalance;
	SpreadsheetDocument.Put(TotalAssets);
	
	// Liabilities and stockholder equity header section
	
	LiabilitiesEquityHeader = Template.GetArea("LiabilitiesEquityHeader");
	SpreadsheetDocument.Put(LiabilitiesEquityHeader);

	// AP section
	
	APBalance = 0;
	
	AP = Template.GetArea("AP");
	
	Query = New Query("SELECT
	                  |	ChartOfAccounts.Ref
	                  |FROM
	                  |	ChartOfAccounts.ChartOfAccounts AS ChartOfAccounts
	                  |WHERE
	                  |	ChartOfAccounts.AccountType = VALUE(Enum.AccountTypes.AccountsPayable)
	                  |
	                  |ORDER BY
	                  |	ChartOfAccounts.Code");	
	
	QueryResult = Query.Execute();

	If QueryResult.IsEmpty() Then
	Else
		RecorderDataset = QueryResult.Choose();
		While RecorderDataset.Next() Do
			
			Filter = New Structure("Account", RecorderDataset.Ref);	
			RecordSelection = Reg.Balance(ReportDate,,Filter);
			
			NoOfRows = RecordSelection.Count();
			If NoOfRows = 0 Then
			Else
				
				AccountCurrency = RecorderDataset.Ref.Currency;
				ExchangeRate = GeneralFunctions.GetExchangeRate(Date, GeneralFunctionsReusable.DefaultCurrency(), AccountCurrency);

				BalanceClosingRate = 0;
				BalanceClosingRate = -1 * (RecordSelection.Total("AmountBalanceDr") - RecordSelection.Total("AmountBalanceCr")) * ExchangeRate; 

				Balance = 0;
				Balance = -1 * (RecordSelection.Total("AmountRCBalanceDr") - RecordSelection.Total("AmountRCBalanceCr"));
				
				APBalance = APBalance + BalanceClosingRate;
				
				AccountOCI = 0;
				AccountOCI = Balance - BalanceClosingRate; // reversed direction
				TotalOCI = TotalOCI + AccountOCI;
				
				If AccountOCI <> 0 Then						
					OCITransactionsRow = OCITransactions.Add();
					OCITransactionsRow.Account = RecorderDataset.Ref;
					OCITransactionsRow.AmountRC = AccountOCI;
				EndIf;
				
				Selection = New Structure("Account, Balance");
				Selection.Insert("Account", RecorderDataset.Ref.Description);
				Selection.Insert("Balance", BalanceClosingRate);
				
				AP.Parameters.Fill(Selection);
				SpreadsheetDocument.Put(AP);				 
			EndIf;			
		EndDo;
	EndIf;
	
	// Other current liabilities section
	
	OtherCurrentLiabilitiesBalance = 0;
	
	OtherCurrentLiabilities = Template.GetArea("OtherCurrentLiabilities");
	
	Query = New Query("SELECT
	                  |	ChartOfAccounts.Ref
	                  |FROM
	                  |	ChartOfAccounts.ChartOfAccounts AS ChartOfAccounts
	                  |WHERE
	                  |	ChartOfAccounts.AccountType = VALUE(Enum.AccountTypes.OtherCurrentLiability)
	                  |
	                  |ORDER BY
	                  |	ChartOfAccounts.Code");	
	
	QueryResult = Query.Execute();

	If QueryResult.IsEmpty() Then
	Else
		RecorderDataset = QueryResult.Choose();
		While RecorderDataset.Next() Do
			
			Filter = New Structure("Account", RecorderDataset.Ref);	
			RecordSelection = Reg.Balance(ReportDate,,Filter);
			
			NoOfRows = RecordSelection.Count();
			If NoOfRows = 0 Then
			Else
				Balance = 0;
				Balance = -1 * (RecordSelection.Total("AmountRCBalanceDr") - RecordSelection.Total("AmountRCBalanceCr"));
				OtherCurrentLiabilitiesBalance = OtherCurrentLiabilitiesBalance + Balance;
				
				Selection = New Structure("Account, Balance");
				Selection.Insert("Account", RecorderDataset.Ref.Description);
				Selection.Insert("Balance", Balance);
				
				OtherCurrentLiabilities.Parameters.Fill(Selection);
				SpreadsheetDocument.Put(OtherCurrentLiabilities);				 
			EndIf;			
		EndDo;
	EndIf;

	// Total current liabilities section
	
	TotalCurrentLiabilitiesBalance = APBalance + OtherCurrentLiabilitiesBalance;
	
	TotalCurrentLiabilities = Template.GetArea("TotalCurrentLiabilities");
	TotalCurrentLiabilities.Parameters.TotalCurrentLiabilities = TotalCurrentLiabilitiesBalance;
	SpreadsheetDocument.Put(TotalCurrentLiabilities);
	
	// Long term liabilities header section
	
	LongTermLiabilitiesHeader = Template.GetArea("LongTermLiabilitiesHeader");
	SpreadsheetDocument.Put(LongTermLiabilitiesHeader);
	
	// Long term liabilities section
	
	LongTermLiabilitiesBalance = 0;
	
	LongTermLiabilities = Template.GetArea("LongTermLiabilities");
	
	Query = New Query("SELECT
	                  |	ChartOfAccounts.Ref
	                  |FROM
	                  |	ChartOfAccounts.ChartOfAccounts AS ChartOfAccounts
	                  |WHERE
	                  |	ChartOfAccounts.AccountType = VALUE(Enum.AccountTypes.LongTermLiability)
	                  |
	                  |ORDER BY
	                  |	ChartOfAccounts.Code");	
	
	QueryResult = Query.Execute();

	If QueryResult.IsEmpty() Then
	Else
		RecorderDataset = QueryResult.Choose();
		While RecorderDataset.Next() Do
			
			Filter = New Structure("Account", RecorderDataset.Ref);	
			RecordSelection = Reg.Balance(ReportDate,,Filter);
			
			NoOfRows = RecordSelection.Count();
			If NoOfRows = 0 Then
			Else
				Balance = 0;
				Balance = -1 * (RecordSelection.Total("AmountRCBalanceDr") - RecordSelection.Total("AmountRCBalanceCr"));
				LongTermLiabilitiesBalance = LongTermLiabilitiesBalance + Balance;
				
				Selection = New Structure("Account, Balance");
				Selection.Insert("Account", RecorderDataset.Ref.Description);
				Selection.Insert("Balance", Balance);
				
				LongTermLiabilities.Parameters.Fill(Selection);
				SpreadsheetDocument.Put(LongTermLiabilities);				 
			EndIf;			
		EndDo;
	EndIf;
	
	// Total long term liabilities section
		
	TotalLongTermLiabilities = Template.GetArea("TotalLongTermLiabilities");
	TotalLongTermLiabilities.Parameters.TotalLongTermLiabilities = LongTermLiabilitiesBalance;
	SpreadsheetDocument.Put(TotalLongTermLiabilities);

	// Stockholder equity header section
	
	EquitySection = Template.GetArea("EquitySection");
	SpreadsheetDocument.Put(EquitySection);

	// Equity section
		
	EquityBalance = 0;
	
	Equity = Template.GetArea("Equity");
	
	Query = New Query("SELECT
	                  |	ChartOfAccounts.Ref
	                  |FROM
	                  |	ChartOfAccounts.ChartOfAccounts AS ChartOfAccounts
	                  |WHERE
	                  |	ChartOfAccounts.AccountType = VALUE(Enum.AccountTypes.Equity)
	                  |
	                  |ORDER BY
	                  |	ChartOfAccounts.Code");	
	
	QueryResult = Query.Execute();

	If QueryResult.IsEmpty() Then
	Else
		RecorderDataset = QueryResult.Choose();
		While RecorderDataset.Next() Do
			
			Filter = New Structure("Account", RecorderDataset.Ref);	
			RecordSelection = Reg.Balance(ReportDate,,Filter);
			
			NoOfRows = RecordSelection.Count();
			If NoOfRows = 0 Then
			Else
				Balance = 0;
				Balance = -1 * (RecordSelection.Total("AmountRCBalanceDr") - RecordSelection.Total("AmountRCBalanceCr"));
				EquityBalance = EquityBalance + Balance;
				
				Selection = New Structure("Account, Balance");
				Selection.Insert("Account", RecorderDataset.Ref.Description);
				Selection.Insert("Balance", Balance);
				
				Equity.Parameters.Fill(Selection);
				SpreadsheetDocument.Put(Equity);				 
			EndIf;			
		EndDo;
	EndIf;

	If TotalOCI <> 0 Then
		
		Selection = New Structure("Account, Balance");
		Selection.Insert("Account", "Other comprehensive income");
		Selection.Insert("Balance", TotalOCI);
		
		Equity.Parameters.Fill(Selection);
		SpreadsheetDocument.Put(Equity);				 

		EquityBalance = EquityBalance + TotalOCI;
		
	EndIf;
	
	// Retained earnings section
	
	IncomeBalance = 0;
		
	Query = New Query("SELECT
	                  |	ChartOfAccounts.Ref
	                  |FROM
	                  |	ChartOfAccounts.ChartOfAccounts AS ChartOfAccounts
	                  |WHERE
	                  |	ChartOfAccounts.AccountType = VALUE(Enum.AccountTypes.Income)
	                  |
	                  |ORDER BY
	                  |	ChartOfAccounts.Code");	
	
	QueryResult = Query.Execute();

	If QueryResult.IsEmpty() Then
	Else
		RecorderDataset = QueryResult.Choose();
		While RecorderDataset.Next() Do
			
			Filter = New Structure("Account", RecorderDataset.Ref);	
			RecordSelection = Reg.Balance(ReportDate,,Filter);
			
			NoOfRows = RecordSelection.Count();
			If NoOfRows = 0 Then
			Else
				Balance = 0;
				Balance = -1 * (RecordSelection.Total("AmountRCBalanceDr") - RecordSelection.Total("AmountRCBalanceCr"));
				IncomeBalance = IncomeBalance + Balance;
				
			EndIf;			
		EndDo;
	EndIf;

	CostOfSalesBalance = 0;
		
	Query = New Query("SELECT
	                  |	ChartOfAccounts.Ref
	                  |FROM
	                  |	ChartOfAccounts.ChartOfAccounts AS ChartOfAccounts
	                  |WHERE
	                  |	ChartOfAccounts.AccountType = VALUE(Enum.AccountTypes.CostOfSales)
	                  |
	                  |ORDER BY
	                  |	ChartOfAccounts.Code");	
	
	QueryResult = Query.Execute();

	If QueryResult.IsEmpty() Then
	Else
		RecorderDataset = QueryResult.Choose();
		While RecorderDataset.Next() Do
			
			Filter = New Structure("Account", RecorderDataset.Ref);	
			RecordSelection = Reg.Balance(ReportDate,,Filter);
			
			NoOfRows = RecordSelection.Count();
			If NoOfRows = 0 Then
			Else
				Balance = 0;
				Balance = RecordSelection.Total("AmountRCBalanceDr") - RecordSelection.Total("AmountRCBalanceCr");
				CostOfSalesBalance = CostOfSalesBalance + Balance;
				
			EndIf;			
		EndDo;
	EndIf;

	
	ExpensesBalance = 0;
		
	Query = New Query("SELECT
	                  |	ChartOfAccounts.Ref
	                  |FROM
	                  |	ChartOfAccounts.ChartOfAccounts AS ChartOfAccounts
	                  |WHERE
	                  |	ChartOfAccounts.AccountType = VALUE(Enum.AccountTypes.Expense)
	                  |
	                  |ORDER BY
	                  |	ChartOfAccounts.Code");	
	
	QueryResult = Query.Execute();

	If QueryResult.IsEmpty() Then
	Else
		RecorderDataset = QueryResult.Choose();
		While RecorderDataset.Next() Do
			
			Filter = New Structure("Account", RecorderDataset.Ref);	
			RecordSelection = Reg.Balance(ReportDate,,Filter);
			
			NoOfRows = RecordSelection.Count();
			If NoOfRows = 0 Then
			Else
				Balance = 0;
				Balance = RecordSelection.Total("AmountRCBalanceDr") - RecordSelection.Total("AmountRCBalanceCr");
				ExpensesBalance = ExpensesBalance + Balance;
				
			EndIf;			
		EndDo;
	EndIf;

	OtherIncomeBalance = 0;
		
	Query = New Query("SELECT
	                  |	ChartOfAccounts.Ref
	                  |FROM
	                  |	ChartOfAccounts.ChartOfAccounts AS ChartOfAccounts
	                  |WHERE
	                  |	ChartOfAccounts.AccountType = VALUE(Enum.AccountTypes.OtherIncome)
	                  |
	                  |ORDER BY
	                  |	ChartOfAccounts.Code");	
	
	QueryResult = Query.Execute();

	If QueryResult.IsEmpty() Then
	Else
		RecorderDataset = QueryResult.Choose();
		While RecorderDataset.Next() Do
			
			Filter = New Structure("Account", RecorderDataset.Ref);	
			RecordSelection = Reg.Balance(ReportDate,,Filter);
			
			NoOfRows = RecordSelection.Count();
			If NoOfRows = 0 Then
			Else
				Balance = 0;
				Balance = -1 * (RecordSelection.Total("AmountRCBalanceDr") - RecordSelection.Total("AmountRCBalanceCr"));
				OtherIncomeBalance = OtherIncomeBalance + Balance;
				
			EndIf;			
		EndDo;
	EndIf;

	OtherExpensesBalance = 0;
		
	Query = New Query("SELECT
	                  |	ChartOfAccounts.Ref
	                  |FROM
	                  |	ChartOfAccounts.ChartOfAccounts AS ChartOfAccounts
	                  |WHERE
	                  |	ChartOfAccounts.AccountType = VALUE(Enum.AccountTypes.OtherExpense)
	                  |
	                  |ORDER BY
	                  |	ChartOfAccounts.Code");	
	
	QueryResult = Query.Execute();

	If QueryResult.IsEmpty() Then
	Else
		RecorderDataset = QueryResult.Choose();
		While RecorderDataset.Next() Do
			
			Filter = New Structure("Account", RecorderDataset.Ref);	
			RecordSelection = Reg.Balance(ReportDate,,Filter);
			
			NoOfRows = RecordSelection.Count();
			If NoOfRows = 0 Then
			Else
				Balance = 0;
				Balance = RecordSelection.Total("AmountRCBalanceDr") - RecordSelection.Total("AmountRCBalanceCr");
				OtherExpensesBalance = OtherExpensesBalance + Balance;
				
			EndIf;			
		EndDo;
	EndIf;

	RetainedEarningsBalance = IncomeBalance - CostOfSalesBalance - ExpensesBalance + OtherIncomeBalance - OtherExpensesBalance;
	
	RetainedEarnings = Template.GetArea("RetainedEarnings");
	RetainedEarnings.Parameters.RetainedEarnings = RetainedEarningsBalance;
	SpreadsheetDocument.Put(RetainedEarnings);

	// Total equity section
		
	TotalEquity = Template.GetArea("TotalEquity");
	TotalEquity.Parameters.TotalEquity = EquityBalance + RetainedEarningsBalance;
	SpreadsheetDocument.Put(TotalEquity);

	// Total liabilities and equity section
		
	TotalLiabilitiesEquity = Template.GetArea("TotalLiabilitiesEquity");
	TotalLiabilitiesEquity.Parameters.TotalLiabilitiesEquity = TotalCurrentLiabilitiesBalance + LongTermLiabilitiesBalance + EquityBalance + RetainedEarningsBalance;
	SpreadsheetDocument.Put(TotalLiabilitiesEquity);

	// Creating OCI transactions
	
	If OCITransactions.Count() > 0 Then
	
		NewDocum = Documents.GeneralJournalEntry.CreateDocument();
		NewDocum.Currency = Constants.DefaultCurrency.Get();
		NewDocum.ExchangeRate = 1;
		NewDocum.Date = Date;
		NewDocum.Posted = False;
		NewDocum.DontWriteFCY = True;
		NewDocum.Memo = "Autogenerated by Balance Sheet";
		
		AccumulatedOCIAccount = Constants.AccumulatedOCIAccount.Get();
		
		AmountRC = 0;
		
		For i = 0 To OCITransactions.Count() - 1 Do
			
			LineItem = NewDocum.LineItems.Add();
			LineItem.Account = OCITransactions[i].Account;
			LineItem.AccountDescription = OCITransactions[i].Account.Description;
			
			LineItemAmount = OCITransactions[i].AmountRC;
			
			AmountRC = AmountRC + SQRT(POW((LineItemAmount),2));
			
			If OCITransactions[i].AmountRC > 0 Then
				LineItem.AmountDr = LineItemAmount;
				Corresponding = "Cr";
			Else
				LineItem.AmountCr = LineItemAmount * -1;
				Corresponding = "Dr";
			EndIf;
			
			LineItem = NewDocum.LineItems.Add();
			LineItem.Account = AccumulatedOCIAccount;
			LineItem.AccountDescription = AccumulatedOCIAccount.Description;
			If Corresponding = "Cr" Then
				LineItem.AmountCr = LineItemAmount;
			Else
				LineItem.AmountDr = LineItemAmount * -1;	
			EndIf;
			
		EndDo;
		
		NewDocum.DocumentTotal = AmountRC;
		NewDocum.DocumentTotalRC = AmountRC;	
		
		NewDocum.Write();

	EndIf;
	
	// Return result
	
	Return SpreadSheetDocument;
	
EndFunction