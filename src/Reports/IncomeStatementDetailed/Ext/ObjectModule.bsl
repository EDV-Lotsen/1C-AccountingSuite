Function IncomeStatement(StartDate, EndDate) Export
	
	StartD = StartDate;
	EndD = EndDate;
	
	If StartDate =  Date(1,1,1) Then
		WhereCase = "AND GeneralJournal.Period <= &EndDate";
		PeriodLabel = "- " + Format(EndD, "DLF=D");
	EndIf;
	
	If EndDate =  Date(1,1,1) Then
		WhereCase = "AND GeneralJournal.Period >= &StartDate";
		PeriodLabel = Format(StartD, "DLF=D") + " -";
	EndIf;
	
	If StartDate = Date(1,1,1) AND EndDate = Date(1,1,1) Then
		WhereCase = "";
		PeriodLabel = "All dates";
	EndIf;
	
	If NOT StartDate = Date(1,1,1) AND NOT EndDate = Date(1,1,1) Then
		WhereCase = "AND GeneralJournal.Period >= &StartDate AND GeneralJournal.Period <= &EndDate";
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
	                  |	GeneralJournal.Period AS Period,
	                  |	GeneralJournal.Recorder,
	                  |	GeneralJournal.RecordType,
	                  |	GeneralJournal.Account,
	                  |	GeneralJournal.AmountRC
	                  |FROM
	                  |	AccountingRegister.GeneralJournal AS GeneralJournal
	                  |WHERE
	                  |	(GeneralJournal.Account.AccountType = VALUE(Enum.AccountTypes.Income)
	                  |			OR GeneralJournal.Account.AccountType = VALUE(Enum.AccountTypes.Expense)
	                  |			OR GeneralJournal.Account.AccountType = VALUE(Enum.AccountTypes.OtherExpense)
	                  |			OR GeneralJournal.Account.AccountType = VALUE(Enum.AccountTypes.OtherIncome)
	                  |			OR GeneralJournal.Account.AccountType = VALUE(Enum.AccountTypes.CostOfSales))
					  | " + WhereCase + "
	                  |
	                  |ORDER BY
	                  |	Period");
					  
					  // ADD OTHER ACCOUNT TYPES
					  
	Query.Parameters.Insert("StartDate", StartDate);
	Query.Parameters.Insert("EndDate", EndDate);
	Selection = Query.Execute().Choose();
	
	IncomeHeader = Template.GetArea("IncomeHeader");
	SpreadsheetDocument.Put(IncomeHeader);
	
	Income = Template.GetArea("Income");
	
	TotalDebit = 0;
	TotalCredit = 0;
	
	While Selection.Next() Do
		Income.Parameters.Date = Selection.Period;
		Income.Parameters.Account = Selection.Account;
		Income.Parameters.Description = Selection.Account.Description;
		Income.Parameters.Document = Selection.Recorder.Metadata().Synonym;
		Income.Parameters.Company = CompanyName(Selection.Recorder);
		If Selection.RecordType = AccountingRecordType.Debit Then
			Income.Parameters.Debit = Selection.AmountRC;
			Income.Parameters.Credit = "";
			TotalDebit = TotalDebit + Selection.AmountRC;
		Else
			Income.Parameters.Credit = Selection.AmountRC;
			Income.Parameters.Debit = "";
			TotalCredit = TotalCredit + Selection.AmountRC; 
		EndIf;	
		SpreadsheetDocument.Put(Income);
	EndDo;

	IncomeFooter = Template.GetArea("IncomeFooter");
	IncomeFooter.Parameters.TotalDebit = TotalDebit;
	IncomeFooter.Parameters.TotalCredit = TotalCredit;
	SpreadsheetDocument.Put(IncomeFooter);
	
	// Return result
	
	Return SpreadSheetDocument;
	
EndFunction

Function CompanyName(DocRef)
	
	DocType = DocRef.Metadata().Name;
	
	If DocType = "CashSale" OR DocType = "SalesReturn" OR DocType = "GoodsIssue" OR DocType = "SalesInvoice"
		OR DocType = "CashPurchase" OR DocType = "CashPurchase" OR DocType = "GoodsReceipt" OR DocType = "PurchaseInvoice"
		OR DocType = "Check" OR DocType = "Payment" Then
		Return DocRef.Company;	
	Else
		Return "";
	EndIf;

	
EndFunction