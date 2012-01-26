Function TrialBalance(Date) Export
		
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
	
	TotalDr = 0;
	TotalCr = 0;
	
	// Main section
	
	AccountBalances = Template.GetArea("AccountBalances");
	
	Query = New Query("SELECT
	                  |	ChartOfAccounts.Ref,
	                  |	ChartOfAccounts.AccountType
	                  |FROM
	                  |	ChartOfAccounts.ChartOfAccounts AS ChartOfAccounts
	                  |
	                  |ORDER BY
	                  |	ChartOfAccounts.Code");	
	
	QueryResult = Query.Execute();

	If QueryResult.IsEmpty() Then
	Else
		Dataset = QueryResult.Choose();
		While Dataset.Next() Do
			
			Filter = New Structure("Account", Dataset.Ref);	
			AccBalance = Reg.Balance(ReportDate,,Filter);
			
			If Dataset.AccountType = Enums.AccountTypes.AccountsReceivable OR
			Dataset.AccountType = Enums.AccountTypes.AccumulatedDepreciation OR
		    Dataset.AccountType = Enums.AccountTypes.Bank OR
			Dataset.AccountType = Enums.AccountTypes.CostOfSales OR
			Dataset.AccountType = Enums.AccountTypes.Expense OR
			Dataset.AccountType = Enums.AccountTypes.FixedAsset OR
			Dataset.AccountType = Enums.AccountTypes.Inventory OR
			Dataset.AccountType = Enums.AccountTypes.OtherCurrentAsset OR
			Dataset.AccountType = Enums.AccountTypes.OtherExpense OR
			Dataset.AccountType = Enums.AccountTypes.OtherNonCurrentAsset Then				
				Debit = AccBalance.Total("AmountRCBalanceDr") - AccBalance.Total("AmountRCBalanceCr");
				Credit = 0;
			Else
				Debit = 0;
				Credit = -1 * (AccBalance.Total("AmountRCBalanceDr") - AccBalance.Total("AmountRCBalanceCr"));
			EndIf;
			
			TotalDr = TotalDr + Debit;
			TotalCr = TotalCr + Credit;
			
			Selection = New Structure("Account, Debit, Credit");
			Selection.Insert("Account", Dataset.Ref.Description);
			Selection.Insert("Debit", Debit);
			Selection.Insert("Credit", Credit);
			
			AccountBalances.Parameters.Fill(Selection);
			SpreadsheetDocument.Put(AccountBalances);				 
		EndDo;
	EndIf;
	
	// Totals
	
	Totals = Template.GetArea("Totals");
	Totals.Parameters.TotalDebit = TotalDr;
	Totals.Parameters.TotalCredit = TotalCr;
	SpreadsheetDocument.Put(Totals);
	
	// Return result
	
	Return SpreadSheetDocument;
	
EndFunction