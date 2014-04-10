Function OtherComprehensiveIncome(StartDate, EndDate) Export
	
	If StartDate =  Date(1,1,1) Then
		WhereCase = "AND GeneralJournalTurnovers.Period <= &EndDate";
		PeriodLabel = "- " + Format(EndDate, "DLF=D");
	EndIf;
	
	If EndDate =  Date(1,1,1) Then
		WhereCase = "AND GeneralJournalTurnovers.Period >= &StartDate";
		PeriodLabel = Format(StartDate, "DLF=D") + " -";
	EndIf;
	
	If StartDate = Date(1,1,1) AND EndDate = Date(1,1,1) Then
		WhereCase = "";
		PeriodLabel = "All dates";
	EndIf;
	
	If NOT StartDate = Date(1,1,1) AND NOT EndDate = Date(1,1,1) Then
		WhereCase = "AND GeneralJournalTurnovers.Period >= &StartDate AND GeneralJournalTurnovers.Period <= &EndDate";
		PeriodLabel = Format(StartDate, "DLF=D") + " - " + Format(EndDate, "DLF=D");
	EndIf;
	
	SpreadsheetDocument = New SpreadsheetDocument;
	Template = GetTemplate("Template");
	
	Header = Template.GetArea("Header");
	Header.Parameters.PeriodLabel = PeriodLabel;
	Header.Parameters.Company = Constants.SystemTitle.Get();
	SpreadsheetDocument.Put(Header);
	
	// Main section
	
	Query = New Query("SELECT
	                  |	GeneralJournalTurnovers.Account,
	                  |	SUM(GeneralJournalTurnovers.AmountRCTurnover) AS AmountTurnover,
	                  |	ChartOfAccounts.Description,
	                  |	ChartOfAccounts.AccountType
	                  |FROM
	                  |	AccountingRegister.GeneralJournal.Turnovers(, , Day, , ) AS GeneralJournalTurnovers
	                  |		LEFT JOIN ChartOfAccounts.ChartOfAccounts AS ChartOfAccounts
	                  |		ON GeneralJournalTurnovers.Account = ChartOfAccounts.Ref
	                  |WHERE
					  | ChartOfAccounts.OtherComprehensiveIncome = TRUE
	                  |	" + WhereCase + "
	                  |
	                  |GROUP BY
	                  |	GeneralJournalTurnovers.Account,
	                  |	ChartOfAccounts.Description,
	                  |	ChartOfAccounts.AccountType");
	Query.Parameters.Insert("StartDate", StartDate);
	Query.Parameters.Insert("EndDate", EndDate);
	Selection = Query.Execute().Select();
	
	MainSection = Template.GetArea("MainSection");
	
	TotalIncome = 0;
	
	While Selection.Next() Do
		
		MainSection.Parameters.Description = Selection.Description;
		
		If Selection.AccountType = Enums.AccountTypes.AccountsReceivable OR
		Selection.AccountType = Enums.AccountTypes.AccumulatedDepreciation OR
	    Selection.AccountType = Enums.AccountTypes.Bank OR
		Selection.AccountType = Enums.AccountTypes.CostOfSales OR
		Selection.AccountType = Enums.AccountTypes.Expense OR
		Selection.AccountType = Enums.AccountTypes.FixedAsset OR
		Selection.AccountType = Enums.AccountTypes.Inventory OR
		Selection.AccountType = Enums.AccountTypes.OtherCurrentAsset OR
		Selection.AccountType = Enums.AccountTypes.OtherExpense OR
		Selection.AccountType = Enums.AccountTypes.OtherNonCurrentAsset Then				
			IncomeAmount = Selection.AmountTurnover;
		Else
			IncomeAmount = Selection.AmountTurnover * -1;
		EndIf;

		
		MainSection.Parameters.AmountTurnover = IncomeAmount;
		SpreadsheetDocument.Put(MainSection);
		TotalIncome = TotalIncome + IncomeAmount;
		
	EndDo;

	MainSectionFooter = Template.GetArea("MainSectionFooter");
	MainSectionFooter.Parameters.TotalIncome = TotalIncome;
	SpreadsheetDocument.Put(MainSectionFooter);
	
	// Return result
	
	Return SpreadSheetDocument;
	
EndFunction