Function IncomeStatement(StartDate, EndDate) Export
	
	StartD = StartDate;
	EndD = EndDate;
	
	If StartDate =  Date(1,1,1) Then
		WhereCase = "AND GeneralJournalTurnovers.Period <= &EndDate";
		PeriodLabel = "- " + Format(EndD, "DLF=D");
	EndIf;
	
	If EndDate =  Date(1,1,1) Then
		WhereCase = "AND GeneralJournalTurnovers.Period >= &StartDate";
		PeriodLabel = Format(StartD, "DLF=D") + " -";
	EndIf;
	
	If StartDate = Date(1,1,1) AND EndDate = Date(1,1,1) Then
		WhereCase = "";
		PeriodLabel = "All dates";
	EndIf;
	
	If NOT StartDate = Date(1,1,1) AND NOT EndDate = Date(1,1,1) Then
		WhereCase = "AND GeneralJournalTurnovers.Period >= &StartDate AND GeneralJournalTurnovers.Period <= &EndDate";
		PeriodLabel = Format(StartD, "DLF=D") + " - " + Format(EndD, "DLF=D");
	EndIf;
	
	OurCompany = Catalogs.Companies.OurCompany;
	
	SpreadsheetDocument = New SpreadsheetDocument;
	Template = GetTemplate("Template");
	
	Header = Template.GetArea("Header");
	Header.Parameters.PeriodLabel = PeriodLabel;
	Header.Parameters.Company = GeneralFunctions.GetAttributeValue(OurCompany, "Name");
	SpreadsheetDocument.Put(Header);
	
	// Income section
	
	Query = New Query("SELECT
	                  |	GeneralJournalTurnovers.Account,
	                  |	SUM(GeneralJournalTurnovers.AmountRCTurnover * -1) AS AmountTurnover,
	                  |	ChartOfAccounts.Description,
	                  |	ChartOfAccounts.AccountType
	                  |FROM
	                  |	AccountingRegister.GeneralJournal.Turnovers(, , Day, , ) AS GeneralJournalTurnovers
	                  |		LEFT JOIN ChartOfAccounts.ChartOfAccounts AS ChartOfAccounts
	                  |		ON GeneralJournalTurnovers.Account = ChartOfAccounts.Ref
	                  |WHERE
	                  |	ChartOfAccounts.AccountType = VALUE(Enum.AccountTypes.Income) AND
					  | ChartOfAccounts.IncomeTaxAccount = FALSE AND
					  | ChartOfAccounts.OtherComprehensiveIncome = FALSE
	                  |	" + WhereCase + "
	                  |
	                  |GROUP BY
	                  |	GeneralJournalTurnovers.Account,
	                  |	ChartOfAccounts.Description,
	                  |	ChartOfAccounts.AccountType");
	Query.Parameters.Insert("StartDate", StartDate);
	Query.Parameters.Insert("EndDate", EndDate);
	Selection = Query.Execute().Choose();
	
	IncomeHeader = Template.GetArea("IncomeHeader");
	SpreadsheetDocument.Put(IncomeHeader);
	
	Income = Template.GetArea("Income");
	
	TotalIncome = 0;
	While Selection.Next() Do
		TotalIncome = TotalIncome + Selection.AmountTurnover;
		Income.Parameters.Fill(Selection);
		SpreadsheetDocument.Put(Income);
	EndDo;

	IncomeFooter = Template.GetArea("IncomeFooter");
	IncomeFooter.Parameters.TotalIncome = TotalIncome;
	SpreadsheetDocument.Put(IncomeFooter);

	// COGS section
	
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
	                  |	ChartOfAccounts.AccountType = VALUE(Enum.AccountTypes.CostOfSales) AND
					  | ChartOfAccounts.IncomeTaxAccount = FALSE AND
					  | ChartOfAccounts.OtherComprehensiveIncome = FALSE
					  |	" + WhereCase + "
	                  |
	                  |GROUP BY
	                  |	GeneralJournalTurnovers.Account,
	                  |	ChartOfAccounts.Description,
	                  |	ChartOfAccounts.AccountType");
	Query.Parameters.Insert("StartDate", StartDate);
	Query.Parameters.Insert("EndDate", EndDate);
	Selection = Query.Execute().Choose();
	
	COGSHeader = Template.GetArea("COGSHeader");
	SpreadsheetDocument.Put(COGSHeader);
	
	COGS = Template.GetArea("COGS");
	
	TotalCOGS = 0;
	While Selection.Next() Do
		TotalCOGS = TotalCOGS + Selection.AmountTurnover;
		COGS.Parameters.Fill(Selection);
		SpreadsheetDocument.Put(COGS);
	EndDo;

	COGSFooter = Template.GetArea("COGSFooter");
	COGSFooter.Parameters.TotalCOGS = TotalCOGS;
	SpreadsheetDocument.Put(COGSFooter);

	// Gross profit section
	
	GrossProfit = Template.GetArea("GrossProfit");
	GrossProfit.Parameters.GrossProfit = TotalIncome - TotalCOGS;
	SpreadsheetDocument.Put(GrossProfit);
	
	// Expenses section
	
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
	                  |	ChartOfAccounts.AccountType = VALUE(Enum.AccountTypes.Expense) AND
					  | ChartOfAccounts.IncomeTaxAccount = FALSE AND
					  | ChartOfAccounts.OtherComprehensiveIncome = FALSE
					  |	" + WhereCase + "
	                  |
	                  |GROUP BY
	                  |	GeneralJournalTurnovers.Account,
	                  |	ChartOfAccounts.Description,
	                  |	ChartOfAccounts.AccountType");
	Query.Parameters.Insert("StartDate", StartDate);
	Query.Parameters.Insert("EndDate", EndDate);
	Selection = Query.Execute().Choose();
	
	ExpensesHeader = Template.GetArea("ExpensesHeader");
	SpreadsheetDocument.Put(ExpensesHeader);
	
	Expenses = Template.GetArea("Expenses");
	
	TotalExpenses = 0;
	While Selection.Next() Do
		TotalExpenses = TotalExpenses + Selection.AmountTurnover;
		Expenses.Parameters.Fill(Selection);
		SpreadsheetDocument.Put(Expenses);
	EndDo;

	ExpensesFooter = Template.GetArea("ExpensesFooter");
	ExpensesFooter.Parameters.TotalExpenses = TotalExpenses;
	SpreadsheetDocument.Put(ExpensesFooter);
	
	// Operating income section
	
	OperatingIncome = Template.GetArea("OperatingIncome");
	OperatingIncome.Parameters.OperatingIncome = TotalIncome - TotalCOGS - TotalExpenses;
	SpreadsheetDocument.Put(OperatingIncome);
	
	// Other income section
	
	Query = New Query("SELECT
	                  |	GeneralJournalTurnovers.Account,
	                  |	SUM(GeneralJournalTurnovers.AmountRCTurnover * -1) AS AmountTurnover,
	                  |	ChartOfAccounts.Description,
	                  |	ChartOfAccounts.AccountType
	                  |FROM
	                  |	AccountingRegister.GeneralJournal.Turnovers(, , Day, , ) AS GeneralJournalTurnovers
	                  |		LEFT JOIN ChartOfAccounts.ChartOfAccounts AS ChartOfAccounts
	                  |		ON GeneralJournalTurnovers.Account = ChartOfAccounts.Ref
	                  |WHERE
	                  |	ChartOfAccounts.AccountType = VALUE(Enum.AccountTypes.OtherIncome) AND
					  | ChartOfAccounts.IncomeTaxAccount = FALSE AND
					  | ChartOfAccounts.OtherComprehensiveIncome = FALSE
					  |	" + WhereCase + "
	                  |
	                  |GROUP BY
	                  |	GeneralJournalTurnovers.Account,
	                  |	ChartOfAccounts.Description,
	                  |	ChartOfAccounts.AccountType");
	Query.Parameters.Insert("StartDate", StartDate);
	Query.Parameters.Insert("EndDate", EndDate);
	Selection = Query.Execute().Choose();
	
	OtherIncomeHeader = Template.GetArea("OtherIncomeHeader");
	SpreadsheetDocument.Put(OtherIncomeHeader);
	
	OtherIncome = Template.GetArea("OtherIncome");
	
	TotalOtherIncome = 0;
	While Selection.Next() Do
		TotalOtherIncome = TotalOtherIncome + Selection.AmountTurnover;
		OtherIncome.Parameters.Fill(Selection);
		SpreadsheetDocument.Put(OtherIncome);
	EndDo;

	OtherIncomeFooter = Template.GetArea("OtherIncomeFooter");
	OtherIncomeFooter.Parameters.TotalOtherIncome = TotalOtherIncome;
	SpreadsheetDocument.Put(OtherIncomeFooter);
	
	// Other expenses section
	
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
	                  |	ChartOfAccounts.AccountType = VALUE(Enum.AccountTypes.OtherExpense) AND
					  | ChartOfAccounts.IncomeTaxAccount = FALSE AND
					  | ChartOfAccounts.OtherComprehensiveIncome = FALSE
					  |	" + WhereCase + "
	                  |
	                  |GROUP BY
	                  |	GeneralJournalTurnovers.Account,
	                  |	ChartOfAccounts.Description,
	                  |	ChartOfAccounts.AccountType");
	Query.Parameters.Insert("StartDate", StartDate);
	Query.Parameters.Insert("EndDate", EndDate);
	Selection = Query.Execute().Choose();
	
	OtherExpensesHeader = Template.GetArea("OtherExpensesHeader");
	SpreadsheetDocument.Put(OtherExpensesHeader);
	
	OtherExpenses = Template.GetArea("OtherExpenses");
	
	TotalOtherExpenses = 0;
	While Selection.Next() Do
		TotalOtherExpenses = TotalOtherExpenses + Selection.AmountTurnover;
		OtherExpenses.Parameters.Fill(Selection);
		SpreadsheetDocument.Put(OtherExpenses);
	EndDo;

	OtherExpensesFooter = Template.GetArea("OtherExpensesFooter");
	OtherExpensesFooter.Parameters.TotalOtherExpenses = TotalOtherExpenses;
	SpreadsheetDocument.Put(OtherExpensesFooter);

	// Net income before tax section
	
	NetIncomeBeforeTax = Template.GetArea("NetIncomeBeforeTax");
	TotalNetIncomeBeforeTax = TotalIncome - TotalCOGS - TotalExpenses + TotalOtherIncome - TotalOtherExpenses;
	NetIncomeBeforeTax.Parameters.NetIncomeBeforeTax = TotalNetIncomeBeforeTax; 
	SpreadsheetDocument.Put(NetIncomeBeforeTax);
	
	// Income tax section
	
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
	                  |	ChartOfAccounts.IncomeTaxAccount = TRUE AND
					  | ChartOfAccounts.OtherComprehensiveIncome = FALSE
					  |	" + WhereCase + "
	                  |
	                  |GROUP BY
	                  |	GeneralJournalTurnovers.Account,
	                  |	ChartOfAccounts.Description,
	                  |	ChartOfAccounts.AccountType");
	Query.Parameters.Insert("StartDate", StartDate);
	Query.Parameters.Insert("EndDate", EndDate);
	Selection = Query.Execute().Choose();
			
	TotalIncomeTax = 0;
	While Selection.Next() Do
		TotalIncomeTax = TotalIncomeTax + Selection.AmountTurnover;
	EndDo;

	IncomeTax = Template.GetArea("IncomeTax");
	IncomeTax.Parameters.IncomeTax = TotalIncomeTax;
	SpreadsheetDocument.Put(IncomeTax);

	// Net income section
	
	NetIncome = Template.GetArea("NetIncome");
	TotalNetIncome = TotalNetIncomeBeforeTax - TotalIncomeTax;
	NetIncome.Parameters.NetIncome = TotalNetIncome; 
	SpreadsheetDocument.Put(NetIncome);
	
	// Return result
	
	Return SpreadSheetDocument;
	
EndFunction