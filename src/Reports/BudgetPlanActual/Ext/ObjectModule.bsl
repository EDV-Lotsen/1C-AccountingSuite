Function IncomeStatement(Year) Export
	
	StartDate = Date(Year + "0101");
	EndDate = Date(Year + "1231");
	
	WhereCase = "AND GeneralJournalTurnovers.Period >= &StartDate AND GeneralJournalTurnovers.Period <= &EndDate";
	
	
	//StartD = StartDate;
	//EndD = EndDate;
	
	//If StartDate =  Date(1,1,1) Then
	//	WhereCase = "AND GeneralJournalTurnovers.Period <= &EndDate";
	//	PeriodLabel = "- " + Format(EndDate, "DLF=D");
	//EndIf;
	//
	//If EndDate =  Date(1,1,1) Then
	//	WhereCase = "AND GeneralJournalTurnovers.Period >= &StartDate";
	//	PeriodLabel = Format(StartDate, "DLF=D") + " -";
	//EndIf;
	//
	//If StartDate = Date(1,1,1) AND EndDate = Date(1,1,1) Then
	//	WhereCase = "";
	//	PeriodLabel = "All dates";
	//EndIf;
	//
	//If NOT StartDate = Date(1,1,1) AND NOT EndDate = Date(1,1,1) Then
	//	WhereCase = "AND GeneralJournalTurnovers.Period >= &StartDate AND GeneralJournalTurnovers.Period <= &EndDate";
	//	PeriodLabel = Format(StartDate, "DLF=D") + " - " + Format(EndDate, "DLF=D");
	//EndIf;
	
	//OurCompany = Constants.SystemTitle.Get();
	
	SpreadsheetDocument = New SpreadsheetDocument;
	Template = GetTemplate("Template");
	
	Header = Template.GetArea("Header");
	
	//Header.Parameters.PeriodLabel = PeriodLabel;
	//BudgetDoc = Documents.Budget.FindByAttribute("Year",Year);
	//Header.Parameters.BudgetDescrip = BudgetDoc.Descrip; 
	
	Header.Parameters.Company = Constants.SystemTitle.Get();
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
	
	TotalIncomeBudget = 0;
	TotalIncome = 0;
	While Selection.Next() Do
		
		BudgetDoc = Documents.Budget.FindByAttribute("Year",Year);
		ParametersFilter = New Structure;
		ParametersFilter.Insert("Account", Selection.Account); // ???
		
		FoundLines = BudgetDoc.LineItem.FindRows(ParametersFilter);				
		TotalIncome = TotalIncome + Selection.AmountTurnover;
		Income.Parameters.Fill(Selection);
		If FoundLines.Count() > 0 Then
			AccountBudget = FoundLines[0].Total;
			TotalIncomeBudget = TotalIncomeBudget + AccountBudget;
			Income.Parameters.Budget = AccountBudget;
			Income.Parameters.Percent = "(" + Format((Selection.AmountTurnover / AccountBudget) * 100,"NFD=1; NZ=0.00") + "%)";
			Income.Parameters.OverBudget = Selection.AmountTurnover - AccountBudget;
		Else
			Income.Parameters.Budget = 0;
			Income.Parameters.OverBudget = 0;
		Endif;
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
	
	TotalCOGSBudget = 0;
	TotalCOGS = 0;
	While Selection.Next() Do
		//TotalCOGS = TotalCOGS + Selection.AmountTurnover;
		//
		BudgetDoc = Documents.Budget.FindByAttribute("Year",Year);
		ParametersFilter = New Structure;
		ParametersFilter.Insert("Account", Selection.Account);
		
		FoundLines = BudgetDoc.LineItem.FindRows(ParametersFilter);		
		TotalCOGS = TotalCOGS + Selection.AmountTurnover;
		COGS.Parameters.Fill(Selection);
		If FoundLines.Count() > 0 Then
			AccountBudget = FoundLines[0].Total;
			COGS.Parameters.Budget = AccountBudget;
			TotalCOGSBudget = TotalCOGSBudget + TotalCOGSBudget;
			COGS.Parameters.Percent = "(" + Format((Selection.AmountTurnover / AccountBudget) * 100,"NFD=1; NZ=0.00") + "%)";
			COGS.Parameters.OverBudget = Selection.AmountTurnover - AccountBudget;
		Else
			COGS.Parameters.Budget = 0;
			COGS.Parameters.OverBudget = 0;

		Endif;
		//
		//COGS.Parameters.Fill(Selection);
		SpreadsheetDocument.Put(COGS);
	EndDo;

	COGSFooter = Template.GetArea("COGSFooter");
	COGSFooter.Parameters.TotalCOGS = TotalCOGS;
	SpreadsheetDocument.Put(COGSFooter);

	// Gross profit section
	
	GrossProfit = Template.GetArea("GrossProfit");
	GrossProfit.Parameters.GrossProfit = TotalIncome - TotalCOGS;
	GrossProfitBudget = TotalIncomeBudget - TotalCOGSBudget;
	GrossProfit.Parameters.Budget = GrossProfitBudget;
	If GrossProfitBudget > 0 Then
		GrossProfit.Parameters.Percent = "(" + Format(((TotalIncome - TotalCOGS) / (GrossProfitBudget)) * 100,"NFD=1; NZ=0.00") + "%)";
	Endif;
	GrossProfit.Parameters.OverBudget = (TotalIncome - TotalCOGS) - (TotalIncomeBudget - TotalCOGSBudget);
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
	
	TotalExpensesBudget = 0;
	TotalExpenses = 0;
	While Selection.Next() Do
		//TotalExpenses = TotalExpenses + Selection.AmountTurnover;
		//Expenses.Parameters.Fill(Selection);
		
		BudgetDoc = Documents.Budget.FindByAttribute("Year",Year);
		ParametersFilter = New Structure;
		ParametersFilter.Insert("Account", Selection.Account);
		
		FoundLines = BudgetDoc.LineItem.FindRows(ParametersFilter);		
		TotalExpenses = TotalExpenses + Selection.AmountTurnover;
		Expenses.Parameters.Fill(Selection);
		If FoundLines.Count() > 0 Then
			AccountBudget = FoundLines[0].Total;
			Expenses.Parameters.Budget = AccountBudget;
			TotalExpensesBudget = TotalExpensesBudget + AccountBudget;
			Expenses.Parameters.Percent = "(" + Format((Selection.AmountTurnover / AccountBudget) * 100,"NFD=1; NZ=0.00") + "%)";
			Expenses.Parameters.OverBudget = Selection.AmountTurnover - AccountBudget;
		Else
			Expenses.Parameters.Budget = 0;
			Expenses.Parameters.OverBudget = 0;

		Endif;

		SpreadsheetDocument.Put(Expenses);
		
	EndDo;

	ExpensesFooter = Template.GetArea("ExpensesFooter");
	ExpensesFooter.Parameters.TotalExpenses = TotalExpenses;
	SpreadsheetDocument.Put(ExpensesFooter);
	
	// Operating income section
	
	OperatingIncome = Template.GetArea("OperatingIncome");
	OperatingIncome.Parameters.OperatingIncome = TotalIncome - TotalCOGS - TotalExpenses;
	OperatingBudget = GrossProfitBudget - TotalExpensesBudget;
	If OperatingBudget > 0 Then
		If (TotalIncome - TotalCOGS - TotalExpenses) < 0 Then
			OperatingIncome.Parameters.OverBudget = "NA";
		Else
			OperatingIncome.Parameters.Percent = "(" + Format(((TotalIncome - TotalCOGS - TotalExpenses) / (GrossProfitBudget - TotalExpensesBudget)) * 100,"NFD=1; NZ=0.00") + "%)";
			OperatingIncome.Parameters.OverBudget = (TotalIncome - TotalCOGS - TotalExpenses) - (GrossProfitBudget - TotalExpensesBudget);
		Endif;
	Endif;
	OperatingIncome.Parameters.Budget = OperatingBudget;
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
	
	TotalOtherIncomeBudget = 0;
	TotalOtherIncome = 0;
	While Selection.Next() Do
		//TotalOtherIncome = TotalOtherIncome + Selection.AmountTurnover;
		//OtherIncome.Parameters.Fill(Selection);
		
		BudgetDoc = Documents.Budget.FindByAttribute("Year",Year);
		ParametersFilter = New Structure;
		ParametersFilter.Insert("Account", Selection.Account);
		
		FoundLines = BudgetDoc.LineItem.FindRows(ParametersFilter);		
		TotalOtherIncome = TotalOtherIncome + Selection.AmountTurnover;
		OtherIncome.Parameters.Fill(Selection);
		If FoundLines.Count() > 0 Then
			AccountBudget = FoundLines[0].Total;
			OtherIncome.Parameters.Budget = AccountBudget;
			TotalOtherIncomeBudget = TotalOtherIncomeBudget + AccountBudget;
			OtherIncome.Parameters.Percent = "(" + Format((Selection.AmountTurnover / AccountBudget) * 100,"NFD=1; NZ=0.00") + "%)";
			OtherIncome.Parameters.OverBudget = Selection.AmountTurnover - AccountBudget;
		Else
			OtherIncome.Parameters.Budget = 0;
			OtherIncome.Parameters.OverBudget = 0;

		Endif;

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
	
	TotalOtherExpensesBudget = 0;
	TotalOtherExpenses = 0;
	While Selection.Next() Do
		//TotalOtherExpenses = TotalOtherExpenses + Selection.AmountTurnover;
		//OtherExpenses.Parameters.Fill(Selection);
		
		BudgetDoc = Documents.Budget.FindByAttribute("Year",Year);
		ParametersFilter = New Structure;
		ParametersFilter.Insert("Account", Selection.Account);
		
		FoundLines = BudgetDoc.LineItem.FindRows(ParametersFilter);		
		TotalOtherExpenses = TotalOtherExpenses + Selection.AmountTurnover;
		OtherExpenses.Parameters.Fill(Selection);
		If FoundLines.Count() > 0 Then
			AccountBudget = FoundLines[0].Total;
			OtherExpenses.Parameters.Budget = AccountBudget;
			TotalOtherExpensesBudget = TotalOtherExpensesBudget + AccountBudget;
			OtherExpenses.Parameters.Percent = "(" + Format((Selection.AmountTurnover / AccountBudget) * 100,"NFD=1; NZ=0.00") + "%)";
			OtherExpenses.Parameters.OverBudget = Selection.AmountTurnover - AccountBudget;
		Else
			OtherExpenses.Parameters.Budget = 0;
			OtherExpenses.Parameters.OverBudget = 0;

		Endif;

		SpreadsheetDocument.Put(OtherExpenses);
	EndDo;

	OtherExpensesFooter = Template.GetArea("OtherExpensesFooter");
	OtherExpensesFooter.Parameters.TotalOtherExpenses = TotalOtherExpenses;
	SpreadsheetDocument.Put(OtherExpensesFooter);

	// Net income before tax section
	
	NetIncomeBeforeTax = Template.GetArea("NetIncomeBeforeTax");
	TotalNetIncomeBeforeTax = TotalIncome - TotalCOGS - TotalExpenses + TotalOtherIncome - TotalOtherExpenses;
	NetIncomeBeforeTax.Parameters.NetIncomeBeforeTax = TotalNetIncomeBeforeTax; 
	NIBTBudget = OperatingBudget + TotalOtherIncomeBudget - TotalOtherExpensesBudget;
	NetIncomeBeforeTax.Parameters.Budget = NIBTBudget;
	If NIBTBudget > 0 Then
		If TotalNetIncomeBeforeTax < 0 Then
			NetIncomeBeforeTax.Parameters.OverBudget = "NA";
		Else
			NetIncomeBeforeTax.Parameters.Percent = "(" + Format((TotalNetIncomeBeforeTax / NIBTBudget) * 100,"NFD=1; NZ=0.00") + "%)";
			NetIncomeBeforeTax.Parameters.OverBudget = TotalNetIncomeBeforeTax - TotalNetIncomeBeforeTax;
		Endif;
	Endif;

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
			
	TotalIncomeTaxBudget = 0;
	TotalIncomeTax = 0;
	IncomeTax = Template.GetArea("IncomeTax");

	While Selection.Next() Do
		
		BudgetDoc = Documents.Budget.FindByAttribute("Year",Year);
		ParametersFilter = New Structure;
		ParametersFilter.Insert("Account", Selection.Account);
		
		FoundLines = BudgetDoc.LineItem.FindRows(ParametersFilter);		

		TotalIncomeTax = TotalIncomeTax + Selection.AmountTurnover;
		
		OtherExpenses.Parameters.Fill(Selection);
		If FoundLines.Count() > 0 Then
			AccountBudget = FoundLines[0].Total;
			IncomeTax.Parameters.Budget = AccountBudget;
			TotalIncomeTaxBudget = TotalIncomeTaxBudget + AccountBudget;
			IncomeTax.Parameters.Percent = "(" + Format((Selection.AmountTurnover / AccountBudget) * 100,"NFD=1; NZ=0.00") + "%)";
			IncomeTax.Parameters.OverBudget = Selection.AmountTurnover - AccountBudget;
		Else
			IncomeTax.Parameters.Budget = 0;
			IncomeTax.Parameters.OverBudget = 0;

		Endif;

	EndDo;

	IncomeTax.Parameters.IncomeTax = TotalIncomeTax;
	SpreadsheetDocument.Put(IncomeTax);

	// Net income section
	
	NetIncome = Template.GetArea("NetIncome");
	TotalNetIncome = TotalNetIncomeBeforeTax - TotalIncomeTax;
	NetIncome.Parameters.NetIncome = TotalNetIncome;
	NetIncomeBudget = NIBTBudget - TotalIncomeTaxBudget;
	NetIncome.Parameters.Budget = NetIncomeBudget;
	If NetIncomeBudget > 0 Then
		If TotalNetIncome < 0 Then
			OperatingIncome.Parameters.OverBudget = "NA";
		Else
			OperatingIncome.Parameters.Percent = "(" + Format((TotalNetIncome / NetIncomeBudget) * 100,"NFD=1; NZ=0.00") + "%)";
			OperatingIncome.Parameters.OverBudget = TotalNetIncome - NetIncomeBudget;
		Endif;
	Endif;

	SpreadsheetDocument.Put(NetIncome);
	
	// Return result
	
	Return SpreadSheetDocument;
	
EndFunction