
#Region PUBLIC_INTERFACE

//Categorization mechanism

//Updates transaction categorization library
//Used in scheduled background job
Procedure UpdateTransactionCategorizationLibrary() Export
	//Select all accepted (falling in 2-monthes interval) but not yet processed transactions
	
	TransactionsRequest = New Query("SELECT
	                                |	AcceptedTransactions.BankAccount,
	                                |	AcceptedTransactions.ID,
	                                |	AcceptedTransactions.Description,
	                                |	AcceptedTransactions.Company,
	                                |	AcceptedTransactions.Category,
	                                |	AcceptedTransactions.CategoryID,
	                                |	AcceptedTransactions.TransactionDate
	                                |INTO NewlyAcceptedTransactions
	                                |FROM
	                                |	(SELECT
	                                |		BankTransactions.BankAccount AS BankAccount,
	                                |		BankTransactions.ID AS ID,
	                                |		BankTransactions.Description AS Description,
	                                |		BankTransactions.Company AS Company,
	                                |		BankTransactions.Category AS Category,
	                                |		BankTransactions.CategoryID AS CategoryID,
	                                |		BankTransactions.TransactionDate AS TransactionDate
	                                |	FROM
	                                |		InformationRegister.BankTransactions AS BankTransactions
	                                |	WHERE
	                                |		BankTransactions.TransactionDate >= &RelevancePeriod
	                                |		AND BankTransactions.Accepted = TRUE) AS AcceptedTransactions
	                                |		LEFT JOIN InformationRegister.BankTransactionCategorization AS BankTransactionCategorization
	                                |		ON AcceptedTransactions.ID = BankTransactionCategorization.TransactionID
	                                |			AND AcceptedTransactions.Company = BankTransactionCategorization.Customer
	                                |			AND AcceptedTransactions.Category = BankTransactionCategorization.Category
	                                |WHERE
	                                |	BankTransactionCategorization.TransactionID IS NULL 
	                                |;
	                                |
	                                |////////////////////////////////////////////////////////////////////////////////
	                                |SELECT
	                                |	NewlyAcceptedTransactions.BankAccount,
	                                |	NewlyAcceptedTransactions.ID,
	                                |	NewlyAcceptedTransactions.Description,
	                                |	NewlyAcceptedTransactions.Company,
	                                |	NewlyAcceptedTransactions.Category,
	                                |	ISNULL(BankTransactionCategories.Account, VALUE(Catalog.BankTransactionCategories.EmptyRef)) AS YodleeCategory,
	                                |	NewlyAcceptedTransactions.TransactionDate AS TransactionDate
	                                |FROM
	                                |	NewlyAcceptedTransactions AS NewlyAcceptedTransactions
	                                |		LEFT JOIN Catalog.BankTransactionCategories AS BankTransactionCategories
	                                |		ON NewlyAcceptedTransactions.CategoryID = BankTransactionCategories.Code
	                                |
	                                |ORDER BY
	                                |	TransactionDate");
									
	RelevancePeriod = AddMonth(CurrentDate(), -6);
	RelevancePeriod = BegOfDay(RelevancePeriod);
	TransactionsRequest.SetParameter("RelevancePeriod", RelevancePeriod);
	Res = TransactionsRequest.Execute();
	Tab = Res.Unload();
	For Each TabRow In Tab Do
		ProcessTransactionForCategorization(TabRow);
	EndDo;
	
	//Delete old and cancelled records
	TransactionsRequest = New Query("SELECT DISTINCT
	                                |	TransactionsToDelete.ID
	                                |FROM
	                                |	(SELECT
	                                |		UnacceptedTransactions.ID AS ID
	                                |	FROM
	                                |		(SELECT
	                                |			BankTransactions.ID AS ID
	                                |		FROM
	                                |			InformationRegister.BankTransactions AS BankTransactions
	                                |		WHERE
	                                |			BankTransactions.Accepted = FALSE) AS UnacceptedTransactions
	                                |			INNER JOIN InformationRegister.BankTransactionCategorization AS BankTransactionCategorization
	                                |			ON UnacceptedTransactions.ID = BankTransactionCategorization.TransactionID
	                                |	
	                                |	UNION ALL
	                                |	
	                                |	SELECT
	                                |		BankTransactionCategorization.TransactionID
	                                |	FROM
	                                |		InformationRegister.BankTransactionCategorization AS BankTransactionCategorization
	                                |			INNER JOIN InformationRegister.BankTransactions AS BankTransactions
	                                |			ON BankTransactionCategorization.TransactionID = BankTransactions.ID
	                                |				AND (BankTransactions.TransactionDate < &RelevancePeriod)) AS TransactionsToDelete");
	TransactionsRequest.SetParameter("RelevancePeriod", RelevancePeriod);
	Tab = TransactionsRequest.Execute().Unload();
	RecordSet = InformationRegisters.BankTransactionCategorization.CreateRecordSet();
	IDFilter = RecordSet.Filter.TransactionID;
	IDFilter.Use = True;
	IDFilter.ComparisonType = ComparisonType.Equal;
	For Each TabRow In Tab Do
		IDFilter.Value = TabRow.ID;
		RecordSet.Write(True);
	EndDo;

EndProcedure

//Function categorizes transactions
// 
//Parameters:
//Transactions - Array of structures - transactions to be processed
// Description - String - Transaction description
// ID - UUID - Transaction ID
//Result:
//Transactions - Array of structures - transactions processed with the results
// Description - String - Transaction description
// ID - UUID - Transaction ID
// Company - CatalogRef.Companies
// Category - ChartOfAccountsRef.ChartOfAccounts
//
Function CategorizeTransactions(Transactions) Export
	
	UpdateTransactionCategorizationLibrary();
	
	//Convert an array into a Value Table
	TranTab = New ValueTable;
	QS = New StringQualifiers(50);
	TypeDescriptionString = New TypeDescription("String",,QS);
	TypeID = New TypeDescription("Number");
	TypeBankAccount = New TypeDescription("CatalogRef.BankAccounts");
	TranTab.Columns.Add("BankAccount", TypeBankAccount);
	TranTab.Columns.Add("lexem", TypeDescriptionString); 
	TranTab.Columns.Add("TranID", TypeID);
	IDCounter = 0;
	While IDCounter < Transactions.Count() Do
		Transaction = Transactions[IDCounter];
		Transaction.Insert("TranID", IDCounter + 1);
		Description = Transaction.Description;
		lexemes = StringFunctionsClientServer.SplitStringIntoSubstringArray(Description, " ");
		lexemes.Add(Description);
		//delete 1- to 2- letter words
		i = 0;
		While i < lexemes.Count() Do
			If StrLen(lexemes[i]) < 3 Then
				lexemes.Delete(i);
			Else
				i = i + 1;
			EndIf;
		EndDo;
		For Each lexem In lexemes Do
			NewRow = TranTab.Add();
			NewRow.BankAccount = Transaction.BankAccount;
			NewRow.lexem = lexem;
			NewRow.TranID = Transaction.TranID;
		EndDo;
		IDCounter = IDCounter + 1;		
	EndDo;
	Request = New Query("SELECT
	                    |	NewTransactions.BankAccount AS BankAccount,
	                    |	NewTransactions.lexem AS lexem,
	                    |	NewTransactions.TranID AS TranID
	                    |INTO NewTransactions
	                    |FROM
	                    |	&NewTransactions AS NewTransactions
	                    |
	                    |INDEX BY
	                    |	BankAccount,
	                    |	lexem
	                    |;
	                    |
	                    |////////////////////////////////////////////////////////////////////////////////
	                    |SELECT
	                    |	NewTransactions.BankAccount,
	                    |	NewTransactions.TranID,
	                    |	NewTransactions.lexem,
	                    |	BankTransactionCategorization.Customer,
	                    |	BankTransactionCategorization.Category,
	                    |	BankTransactionCategorization.FullDescription
	                    |INTO FoundCoincidents
	                    |FROM
	                    |	NewTransactions AS NewTransactions
	                    |		INNER JOIN InformationRegister.BankTransactionCategorization AS BankTransactionCategorization
	                    |		ON NewTransactions.BankAccount = BankTransactionCategorization.BankAccount
	                    |			AND NewTransactions.lexem = BankTransactionCategorization.Lexem
	                    |;
	                    |
	                    |////////////////////////////////////////////////////////////////////////////////
	                    |SELECT DISTINCT
	                    |	FoundCoincidents.TranID,
	                    |	FoundCoincidents.Customer,
	                    |	FoundCoincidents.Category,
	                    |	1000000 AS Priority
	                    |INTO FullCoincidents
	                    |FROM
	                    |	FoundCoincidents AS FoundCoincidents
	                    |WHERE
	                    |	FoundCoincidents.FullDescription = TRUE
	                    |;
	                    |
	                    |////////////////////////////////////////////////////////////////////////////////
	                    |SELECT DISTINCT
	                    |	FoundCoincidents.BankAccount,
	                    |	FoundCoincidents.lexem
	                    |INTO UsedLexems
	                    |FROM
	                    |	FoundCoincidents AS FoundCoincidents
	                    |;
	                    |
	                    |////////////////////////////////////////////////////////////////////////////////
	                    |SELECT DISTINCT
	                    |	UsedLexems.lexem,
	                    |	UsedLexems.BankAccount,
	                    |	BankTransactionCategorization.Customer,
	                    |	BankTransactionCategorization.Category
	                    |INTO CustomersAndCategoriesForLexem
	                    |FROM
	                    |	UsedLexems AS UsedLexems
	                    |		INNER JOIN InformationRegister.BankTransactionCategorization AS BankTransactionCategorization
	                    |		ON UsedLexems.lexem = BankTransactionCategorization.Lexem
	                    |			AND UsedLexems.BankAccount = BankTransactionCategorization.BankAccount
	                    |;
	                    |
	                    |////////////////////////////////////////////////////////////////////////////////
	                    |SELECT
	                    |	CustomersAndCategoriesForLexem.BankAccount,
	                    |	CustomersAndCategoriesForLexem.lexem,
	                    |	COUNT(DISTINCT CustomersAndCategoriesForLexem.Customer) AS Priority
	                    |INTO LexemPriorityForCustomer
	                    |FROM
	                    |	CustomersAndCategoriesForLexem AS CustomersAndCategoriesForLexem
	                    |
	                    |GROUP BY
	                    |	CustomersAndCategoriesForLexem.lexem,
	                    |	CustomersAndCategoriesForLexem.BankAccount
	                    |;
	                    |
	                    |////////////////////////////////////////////////////////////////////////////////
	                    |SELECT
	                    |	CustomersAndCategoriesForLexem.BankAccount,
	                    |	CustomersAndCategoriesForLexem.lexem,
	                    |	COUNT(DISTINCT CustomersAndCategoriesForLexem.Category) AS Priority
	                    |INTO LexemPriorityForCategory
	                    |FROM
	                    |	CustomersAndCategoriesForLexem AS CustomersAndCategoriesForLexem
	                    |
	                    |GROUP BY
	                    |	CustomersAndCategoriesForLexem.BankAccount,
	                    |	CustomersAndCategoriesForLexem.lexem
	                    |;
	                    |
	                    |////////////////////////////////////////////////////////////////////////////////
	                    |SELECT DISTINCT
	                    |	FoundCoincidents.TranID,
	                    |	FoundCoincidents.lexem,
	                    |	FoundCoincidents.Customer,
	                    |	10000 / LexemPriorityForCustomer.Priority / LexemPriorityForCustomer.Priority AS Priority
	                    |INTO LexemsCustomers
	                    |FROM
	                    |	FoundCoincidents AS FoundCoincidents
	                    |		INNER JOIN LexemPriorityForCustomer AS LexemPriorityForCustomer
	                    |		ON FoundCoincidents.BankAccount = LexemPriorityForCustomer.BankAccount
	                    |			AND FoundCoincidents.lexem = LexemPriorityForCustomer.lexem
	                    |;
	                    |
	                    |////////////////////////////////////////////////////////////////////////////////
	                    |SELECT DISTINCT
	                    |	FoundCoincidents.TranID,
	                    |	FoundCoincidents.lexem,
	                    |	FoundCoincidents.Category,
	                    |	10000 / LexemPriorityForCategory.Priority / LexemPriorityForCategory.Priority AS Priority
	                    |INTO LexemsCategories
	                    |FROM
	                    |	FoundCoincidents AS FoundCoincidents
	                    |		INNER JOIN LexemPriorityForCategory AS LexemPriorityForCategory
	                    |		ON FoundCoincidents.BankAccount = LexemPriorityForCategory.BankAccount
	                    |			AND FoundCoincidents.lexem = LexemPriorityForCategory.lexem
	                    |;
	                    |
	                    |////////////////////////////////////////////////////////////////////////////////
	                    |SELECT
	                    |	LexemsCustomers.TranID,
	                    |	LexemsCustomers.Customer,
	                    |	SUM(LexemsCustomers.Priority) AS Priority
	                    |INTO CustomerPriorityByNumberOfLexems
	                    |FROM
	                    |	LexemsCustomers AS LexemsCustomers
	                    |
	                    |GROUP BY
	                    |	LexemsCustomers.TranID,
	                    |	LexemsCustomers.Customer
	                    |;
	                    |
	                    |////////////////////////////////////////////////////////////////////////////////
	                    |SELECT
	                    |	LexemsCategories.TranID,
	                    |	LexemsCategories.Category,
	                    |	SUM(LexemsCategories.Priority) AS Priority
	                    |INTO CategoryPriorityByNumberOfLexems
	                    |FROM
	                    |	LexemsCategories AS LexemsCategories
	                    |
	                    |GROUP BY
	                    |	LexemsCategories.TranID,
	                    |	LexemsCategories.Category
	                    |;
	                    |
	                    |////////////////////////////////////////////////////////////////////////////////
	                    |SELECT
	                    |	FoundCoincidents.TranID,
	                    |	FoundCoincidents.Customer,
	                    |	SUM(50 / LexemPriorityForCustomer.Priority) AS Priority
	                    |INTO CustomerPriorityByNumberofCoincidents
	                    |FROM
	                    |	FoundCoincidents AS FoundCoincidents
	                    |		INNER JOIN LexemPriorityForCustomer AS LexemPriorityForCustomer
	                    |		ON FoundCoincidents.BankAccount = LexemPriorityForCustomer.BankAccount
	                    |			AND FoundCoincidents.lexem = LexemPriorityForCustomer.lexem
	                    |
	                    |GROUP BY
	                    |	FoundCoincidents.TranID,
	                    |	FoundCoincidents.Customer
	                    |;
	                    |
	                    |////////////////////////////////////////////////////////////////////////////////
	                    |SELECT
	                    |	FoundCoincidents.TranID,
	                    |	FoundCoincidents.Category,
	                    |	SUM(50 / LexemPriorityForCategory.Priority) AS Priority
	                    |INTO CategoryPriorityByNumberOfCoincidents
	                    |FROM
	                    |	FoundCoincidents AS FoundCoincidents
	                    |		INNER JOIN LexemPriorityForCategory AS LexemPriorityForCategory
	                    |		ON FoundCoincidents.BankAccount = LexemPriorityForCategory.BankAccount
	                    |			AND FoundCoincidents.lexem = LexemPriorityForCategory.lexem
	                    |
	                    |GROUP BY
	                    |	FoundCoincidents.TranID,
	                    |	FoundCoincidents.Category
	                    |;
	                    |
	                    |////////////////////////////////////////////////////////////////////////////////
	                    |SELECT
	                    |	NestedSelect.TranID,
	                    |	NestedSelect.Customer,
	                    |	SUM(NestedSelect.Priority) AS Priority
	                    |INTO Customers_Semifinal
	                    |FROM
	                    |	(SELECT
	                    |		FullCoincidents.TranID AS TranID,
	                    |		FullCoincidents.Customer AS Customer,
	                    |		FullCoincidents.Priority AS Priority
	                    |	FROM
	                    |		FullCoincidents AS FullCoincidents
	                    |	
	                    |	UNION ALL
	                    |	
	                    |	SELECT
	                    |		CustomerPriorityByNumberOfLexems.TranID,
	                    |		CustomerPriorityByNumberOfLexems.Customer,
	                    |		CustomerPriorityByNumberOfLexems.Priority
	                    |	FROM
	                    |		CustomerPriorityByNumberOfLexems AS CustomerPriorityByNumberOfLexems
	                    |	
	                    |	UNION ALL
	                    |	
	                    |	SELECT
	                    |		CustomerPriorityByNumberofCoincidents.TranID,
	                    |		CustomerPriorityByNumberofCoincidents.Customer,
	                    |		CustomerPriorityByNumberofCoincidents.Priority
	                    |	FROM
	                    |		CustomerPriorityByNumberofCoincidents AS CustomerPriorityByNumberofCoincidents) AS NestedSelect
	                    |
	                    |GROUP BY
	                    |	NestedSelect.TranID,
	                    |	NestedSelect.Customer
	                    |;
	                    |
	                    |////////////////////////////////////////////////////////////////////////////////
	                    |SELECT
	                    |	NestedSelect.TranID,
	                    |	NestedSelect.Category,
	                    |	SUM(NestedSelect.Priority) AS Priority
	                    |INTO Categories_Semifinal
	                    |FROM
	                    |	(SELECT
	                    |		FullCoincidents.TranID AS TranID,
	                    |		FullCoincidents.Category AS Category,
	                    |		FullCoincidents.Priority AS Priority
	                    |	FROM
	                    |		FullCoincidents AS FullCoincidents
	                    |	
	                    |	UNION ALL
	                    |	
	                    |	SELECT
	                    |		CategoryPriorityByNumberOfLexems.TranID,
	                    |		CategoryPriorityByNumberOfLexems.Category,
	                    |		CategoryPriorityByNumberOfLexems.Priority
	                    |	FROM
	                    |		CategoryPriorityByNumberOfLexems AS CategoryPriorityByNumberOfLexems
	                    |	
	                    |	UNION ALL
	                    |	
	                    |	SELECT
	                    |		CategoryPriorityByNumberOfCoincidents.TranID,
	                    |		CategoryPriorityByNumberOfCoincidents.Category,
	                    |		CategoryPriorityByNumberOfCoincidents.Priority
	                    |	FROM
	                    |		CategoryPriorityByNumberOfCoincidents AS CategoryPriorityByNumberOfCoincidents) AS NestedSelect
	                    |
	                    |GROUP BY
	                    |	NestedSelect.TranID,
	                    |	NestedSelect.Category
	                    |;
	                    |
	                    |////////////////////////////////////////////////////////////////////////////////
	                    |SELECT
	                    |	ISNULL(CustomerResult.TranID, CategoryResult.TranID) AS TranID,
	                    |	ISNULL(CustomerResult.Priority, 0) AS CustomerPriority,
	                    |	ISNULL(CustomerResult.Customer, VALUE(Catalog.Companies.EmptyRef)) AS Customer,
	                    |	ISNULL(CategoryResult.Priority, 0) AS CategoryPriority,
	                    |	ISNULL(CategoryResult.Category, VALUE(Catalog.BankTransactionCategories.EmptyRef)) AS Category
	                    |FROM
	                    |	(SELECT
	                    |		CustomerMaxPriority.TranID AS TranID,
	                    |		CustomerMaxPriority.Priority AS Priority,
	                    |		Customers_Semifinal.Customer AS Customer
	                    |	FROM
	                    |		(SELECT
	                    |			Customers_Semifinal.TranID AS TranID,
	                    |			MAX(Customers_Semifinal.Priority) AS Priority
	                    |		FROM
	                    |			Customers_Semifinal AS Customers_Semifinal
	                    |		
	                    |		GROUP BY
	                    |			Customers_Semifinal.TranID) AS CustomerMaxPriority
	                    |			INNER JOIN Customers_Semifinal AS Customers_Semifinal
	                    |			ON CustomerMaxPriority.TranID = Customers_Semifinal.TranID
	                    |				AND CustomerMaxPriority.Priority = Customers_Semifinal.Priority) AS CustomerResult
	                    |		FULL JOIN (SELECT
	                    |			CategoryMaxPriority.TranID AS TranID,
	                    |			CategoryMaxPriority.Priority AS Priority,
	                    |			Categories_Semifinal.Category AS Category
	                    |		FROM
	                    |			(SELECT
	                    |				Categories_Semifinal.TranID AS TranID,
	                    |				MAX(Categories_Semifinal.Priority) AS Priority
	                    |			FROM
	                    |				Categories_Semifinal AS Categories_Semifinal
	                    |			
	                    |			GROUP BY
	                    |				Categories_Semifinal.TranID) AS CategoryMaxPriority
	                    |				INNER JOIN Categories_Semifinal AS Categories_Semifinal
	                    |				ON CategoryMaxPriority.TranID = Categories_Semifinal.TranID
	                    |					AND CategoryMaxPriority.Priority = Categories_Semifinal.Priority) AS CategoryResult
	                    |		ON CustomerResult.TranID = CategoryResult.TranID
	                    |
	                    |ORDER BY
	                    |	TranID,
	                    |	CustomerPriority DESC,
	                    |	CategoryPriority DESC");
	Request.SetParameter("NewTransactions", TranTab);
	CategorizedTrans = Request.Execute().Unload();
	
	TransIDs = CategorizedTrans.Copy();
	ResultTable = CategorizedTrans.CopyColumns();
	TransIDs.GroupBy("TranID");
	For Each TranID IN TransIDs Do
		//Process the current transaction
		//Define if there are several options for customer or category
		//Ignore results with several options
		CompanyForFilling = Catalogs.Companies.EmptyRef();
		CategoryForFilling = ChartsOfAccounts.ChartOfAccounts.EmptyRef();
		//If Priorities < 10000, then ignore the result
		PriorityForCompany = 0;
		PriorityForCategory = 0;
		
		FoundRows = CategorizedTrans.FindRows(New Structure("TranID", TranID.TranID));
		If FoundRows.Count() > 1 Then
			TableForIDCustomer = CategorizedTrans.Copy(FoundRows);
			TableForIDCategory = TableForIDCustomer.Copy();
			TableForIDCustomer.GroupBy("Customer, CustomerPriority");
			If TableForIDCustomer.Count() = 1 Then
				CompanyForFilling = TableForIDCustomer[0]["Customer"];
				PriorityForCompany = TableForIDCustomer[0]["CustomerPriority"];
			EndIf;
			TableForIDCategory.GroupBy("Category, CategoryPriority");
			If TableForIDCategory.Count() = 1 Then
				CategoryForFilling = TableForIDCategory[0]["Category"];
				PriorityForCategory = TableForIDCategory[0]["CategoryPriority"];
			EndIf;
		Else
			CompanyForFilling = FoundRows[0].Customer;
			PriorityForCompany = FoundRows[0].CustomerPriority;
			CategoryForFilling = FoundRows[0].Category;
			PriorityForCategory = FoundRows[0].CategoryPriority;
		EndIf;
		
		If (PriorityForCompany < 10100) And (PriorityForCategory < 10100) Then
			Continue;
		EndIf;
				
		NewResultRow = ResultTable.Add();
		FillPropertyValues(NewResultRow, FoundRows[0]);
		NewResultRow.Customer = ?(PriorityForCompany >= 10100, CompanyForFilling, Catalogs.Companies.EmptyRef());
		NewResultRow.Category = ?(PriorityForCategory >= 10100, CategoryForFilling, ChartsOfAccounts.ChartOfAccounts.EmptyRef());
	EndDo;		

	ReturnArray = New Array();
	For Each CategorizedTran In ResultTable Do
		ReturnArray.Add(New Structure("BankAccount, Description, ID, RowID, CustomerPriority, Customer, CategoryPriority, Category", Transactions[CategorizedTran.TranID-1].BankAccount,
		Transactions[CategorizedTran.TranID-1].Description, Transactions[CategorizedTran.TranID-1].ID, Transactions[CategorizedTran.TranID-1].RowID, CategorizedTran.CustomerPriority, CategorizedTran.Customer,
		CategorizedTran.CategoryPriority, CategorizedTran.Category));
	EndDo;
	return ReturnArray;
EndFunction

Procedure CategorizeTransactionsAtServer(BankAccount, TempStorageAddress = Undefined) Export
	Try
		SetPrivilegedMode(True);
		BeginTransaction(DataLockControlMode.Managed);
		//Select all required transactions
		Request = New Query("SELECT
		                    |	BankTransactions.TransactionDate,
		                    |	BankTransactions.BankAccount,
		                    |	BankTransactions.Company,
		                    |	BankTransactions.ID,
		                    |	BankTransactions.Description,
		                    |	BankTransactions.Amount,
		                    |	BankTransactions.Category,
		                    |	BankTransactions.Document,
		                    |	BankTransactions.Accepted,
		                    |	BankTransactions.Hidden,
		                    |	BankTransactions.OriginalID,
		                    |	BankTransactions.YodleeTransactionID,
		                    |	BankTransactions.PostDate,
		                    |	BankTransactions.Price,
		                    |	BankTransactions.Quantity,
		                    |	BankTransactions.RunningBalance,
		                    |	BankTransactions.CurrencyCode,
		                    |	BankTransactions.CategoryID,
		                    |	BankTransactions.Type,
		                    |	BankTransactions.CategorizedCompanyNotAccepted,
		                    |	BankTransactions.CategorizedCategoryNotAccepted,
		                    |	ISNULL(BankTransactionCategories.Account, VALUE(ChartOfAccounts.ChartOfAccounts.EmptyRef)) AS CategoryAccount
		                    |FROM
		                    |	InformationRegister.BankTransactions AS BankTransactions
		                    |		LEFT JOIN Catalog.BankTransactionCategories AS BankTransactionCategories
		                    |		ON BankTransactions.CategoryID = BankTransactionCategories.Code
		                    |WHERE
		                    |	BankTransactions.BankAccount = &BankAccount
		                    |	AND BankTransactions.Accepted = FALSE
		                    |	AND BankTransactions.Hidden = FALSE");
		Request.SetParameter("BankAccount", BankAccount);
		UnacceptedTransactions = Request.Execute().Unload();
		//Lock records being processed
		DataLock = New DataLock();
		BT_DataLock = DataLock.Add("InformationRegister.BankTransactions");
		BT_DataLock.Mode = DataLockMode.Exclusive;
		BT_DataLock.DataSource = UnacceptedTransactions;
		BT_DataLock.UseFromDataSource("ID", "ID");
		DataLock.Lock();
		
		Transactions = UnacceptedTransactions.Copy(, "BankAccount, ID, Description");
		Transactions.Columns.Add("RowID", New TypeDescription("Number"));
		i = 0;
		ArrayOfTransactions = New Array();
		While i < Transactions.Count() Do
			Transactions[i].RowID = i;
			ArrayOfTransactions.Add(New Structure("BankAccount, ID, Description, RowID", Transactions[i].BankAccount, Transactions[i].ID, Transactions[i].Description, Transactions[i].RowID));
			i = i + 1;
		EndDo;
		ReturnArray = CategorizeTransactions(ArrayOfTransactions);
		AffectedRows = New Array();
		
		ProcessedArray = New Array();
		For Each CategorizedTran IN ReturnArray Do
			CompanyFilled = False;
			CategoryFilled = False;
			ProcessedArray.Add(CategorizedTran.RowID);
			BTUnaccepted = UnacceptedTransactions[CategorizedTran.RowID];
			//Apply categorized company if it is not filled
			If (Not ValueIsFilled(BTUnaccepted.Company)) Or (BTUnaccepted.CategorizedCompanyNotAccepted) Then 
				BTUnaccepted.Company = CategorizedTran.Customer;
				BTUnaccepted.CategorizedCompanyNotAccepted = True;
				CompanyFilled = True;
			EndIf;
			If (Not ValueIsFilled(BTUnaccepted.Category)) Or (BTUnaccepted.CategorizedCategoryNotAccepted) Then 
				If (BTUnaccepted.CategoryAccount <> CategorizedTran.Category) Then
					BTUnaccepted.Category = CategorizedTran.Category;
					BTUnaccepted.CategorizedCategoryNotAccepted = True;
					CategoryFilled = True;
				EndIf;
			EndIf;
			If CompanyFilled OR CategoryFilled Then
				RecordTransactionToTheDatabase(BTUnaccepted);
				NewAffectedRow = New Structure("ID, Company, CategorizedCompanyNotAccepted, Category, CategorizedCategoryNotAccepted");
				FillPropertyValues(NewAffectedRow, BTUnaccepted);
				AffectedRows.Add(NewAffectedRow);
			EndIf;
		EndDo;
		//Clear previously categorized transactions, which are absent this time
		i = 0;
		EmptyCompany = Catalogs.Companies.EmptyRef();
		EmptyCategory = ChartsOfAccounts.ChartOfAccounts.EmptyRef();
		While i < UnacceptedTransactions.Count() Do
			If ProcessedArray.Find(i) <> Undefined Then
				i = i + 1;
				Continue;
			EndIf;
			CompanyWasCleared = False;
			CategoryWasCleared = False;
			BTUnaccepted = UnacceptedTransactions[i];
			If (ValueIsFilled(BTUnaccepted.Company)) And (BTUnaccepted.CategorizedCompanyNotAccepted) Then
				BTUnaccepted.Company = EmptyCompany;
				BTUnaccepted.CategorizedCompanyNotAccepted = False;
				CompanyWasCleared =True;
			EndIf;
			If (ValueIsFilled(BTUnaccepted.Category)) And (BTUnaccepted.CategorizedCategoryNotAccepted) Then
				BTUnaccepted.Category = EmptyCategory;
				BTUnaccepted.CategorizedCategoryNotAccepted = False;
				CategoryWasCleared = True;
			EndIf;
			i = i + 1;
			If CompanyWasCleared OR CategoryWasCleared Then
				RecordTransactionToTheDatabase(BTUnaccepted);
				NewAffectedRow = New Structure("ID, Company, CategorizedCompanyNotAccepted, Category, CategorizedCategoryNotAccepted");
				FillPropertyValues(NewAffectedRow, BTUnaccepted);
				AffectedRows.Add(NewAffectedRow);
			EndIf;
		EndDo;
		CommitTransaction();
		If TempStorageAddress <> Undefined Then
			PutToTempStorage(New Structure("CurrentStatus, ErrorDescription, AffectedRows", True, "", AffectedRows), TempStorageAddress);
		EndIf;
	Except
		ErrorDescription = ErrorDescription();
		If TempStorageAddress <> Undefined Then
			PutToTempStorage(New Structure("CurrentStatus, ErrorDescription", False, ErrorDescription), TempStorageAddress);
		EndIf;
		WriteLogEvent("DownloadedTransactions.TransactionCategorization", EventLogLevel.Error,,, ErrorDescription());	
		RollbackTransaction();
	EndTry;			
	
EndProcedure

// Document matching
Procedure MatchTransferDocuments(AccountInBank, AccountingAccount, TempStorageAddress = Undefined) Export
	
Try
	SetPrivilegedMode(True);	
	BeginTransaction(DataLockControlMode.Managed);
	
	// Create new managed data lock
	DataLock = New DataLock;

	// Set data lock parameters
	// Set shared lock to get consisitent data
	BA_LockItem = DataLock.Add("InformationRegister.BankTransactions");
	BA_LockItem.Mode = DataLockMode.Exclusive;
	BA_LockItem.SetValue("BankAccount", AccountInBank);
	DataLock.Lock();
	
	Request = New Query("SELECT ALLOWED
	                    |	BankTransfer.Ref,
	                    |	BankTransfer.AccountFrom,
	                    |	BankTransfer.AccountTo,
	                    |	BankTransfer.Amount,
	                    |	BankTransfer.Date
	                    |INTO Transfers
	                    |FROM
	                    |	Document.BankTransfer AS BankTransfer
	                    |WHERE
	                    |	(BankTransfer.AccountFrom = &AccountingAccount
	                    |			OR BankTransfer.AccountTo = &AccountingAccount)
	                    |	AND BankTransfer.Posted = TRUE
	                    |	AND BankTransfer.DeletionMark = FALSE
	                    |;
	                    |
	                    |////////////////////////////////////////////////////////////////////////////////
	                    |SELECT
	                    |	BankTransactions.TransactionDate,
	                    |	BankTransactions.BankAccount,
	                    |	BankTransactions.ID,
	                    |	BankTransactions.BankAccount.AccountingAccount,
	                    |	BankTransactions.Amount,
	                    |	BankTransactions.Document,
	                    |	CASE
	                    |		WHEN BankTransactions.Amount < 0
	                    |			THEN -1 * BankTransactions.Amount
	                    |		ELSE BankTransactions.Amount
	                    |	END AS AbsoluteAmount
	                    |INTO AvailableTransactions
	                    |FROM
	                    |	InformationRegister.BankTransactions AS BankTransactions
	                    |WHERE
	                    |	BankTransactions.BankAccount = &AccountInBank
	                    |	AND BankTransactions.Accepted = FALSE
	                    |	AND (BankTransactions.Document = UNDEFINED
	                    |			OR BankTransactions.Document = VALUE(Document.BankTransfer.EmptyRef))
	                    |	AND BankTransactions.Description LIKE ""%transfer%""
	                    |;
	                    |
	                    |////////////////////////////////////////////////////////////////////////////////
	                    |SELECT
	                    |	Transfers.Ref,
	                    |	Transfers.AccountFrom,
	                    |	Transfers.AccountTo,
	                    |	Transfers.Amount,
	                    |	Transfers.Date,
	                    |	CASE
	                    |		WHEN Transfers.Amount < 0
	                    |			THEN -1 * Transfers.Amount
	                    |		ELSE Transfers.Amount
	                    |	END AS AbsoluteAmount
	                    |INTO AvailableTransfers
	                    |FROM
	                    |	Transfers AS Transfers
	                    |		LEFT JOIN InformationRegister.BankTransactions AS BankTransactions
	                    |		ON Transfers.Ref = BankTransactions.Document
	                    |			AND (BankTransactions.BankAccount = &AccountInBank)
	                    |WHERE
	                    |	BankTransactions.Document IS NULL 
	                    |;
	                    |
	                    |////////////////////////////////////////////////////////////////////////////////
	                    |SELECT
	                    |	AvailableTransactions.TransactionDate,
	                    |	AvailableTransactions.ID,
	                    |	AvailableTransactions.Amount AS TransactionAmount,
	                    |	AvailableTransfers.Ref,
	                    |	AvailableTransfers.Date,
	                    |	CASE
	                    |		WHEN DATEDIFF(AvailableTransactions.TransactionDate, AvailableTransfers.Date, DAY) < 0
	                    |			THEN -1 * DATEDIFF(AvailableTransactions.TransactionDate, AvailableTransfers.Date, DAY)
	                    |		ELSE DATEDIFF(AvailableTransactions.TransactionDate, AvailableTransfers.Date, DAY)
	                    |	END AS AbsoluteDayDiff
	                    |INTO AllMatched
	                    |FROM
	                    |	AvailableTransactions AS AvailableTransactions
	                    |		INNER JOIN AvailableTransfers AS AvailableTransfers
	                    |		ON AvailableTransactions.AbsoluteAmount = AvailableTransfers.AbsoluteAmount
	                    |			AND (CASE
	                    |				WHEN AvailableTransactions.Amount < 0
	                    |					THEN AvailableTransactions.TransactionDate <= AvailableTransfers.Date
	                    |							AND AvailableTransactions.TransactionDate >= DATEADD(AvailableTransfers.Date, DAY, -3)
	                    |				ELSE AvailableTransactions.TransactionDate >= AvailableTransfers.Date
	                    |						AND AvailableTransactions.TransactionDate <= DATEADD(AvailableTransfers.Date, DAY, 3)
	                    |			END)
	                    |;
	                    |
	                    |////////////////////////////////////////////////////////////////////////////////
	                    |SELECT
	                    |	AllMatched.TransactionDate,
	                    |	AllMatched.ID AS TransactionID,
	                    |	AllMatched.TransactionAmount,
	                    |	AllMatched.Ref AS FoundDocument,
	                    |	AllMatched.AbsoluteDayDiff AS AbsoluteDayDiff,
	                    |	AllMatched.Ref.Presentation AS FoundDocumentPresentation
	                    |FROM
	                    |	AllMatched AS AllMatched
	                    |
	                    |ORDER BY
	                    |	AbsoluteDayDiff
	                    |TOTALS BY
	                    |	TransactionID");
	Request.SetParameter("AccountingAccount", AccountingAccount);
	Request.SetParameter("AccountInBank", AccountInBank);
			
	Res = Request.Execute();
	
	If Res.IsEmpty() Then
		If TempStorageAddress <> Undefined Then
			PutToTempStorage(New Structure("CurrentStatus, ErrorDescription, AffectedRows", True, "", New Array()), TempStorageAddress);
		EndIf;
		RollbackTransaction();
		return;
	EndIf;
	TransactionSelect = Res.Select(QueryResultIteration.ByGroups);
	UsedDocuments = New Array();
	ReturnArray = New Array();
	While TransactionSelect.Next() Do
		DocumentsSelect = TransactionSelect.Select();
		DocumentFound = False;
		BankTransferDocument = Documents.BankTransfer.EmptyRef();
		While (Not DocumentFound) And (DocumentsSelect.Next()) Do
			BankTransferDocument = DocumentsSelect.FoundDocument;
			If UsedDocuments.Find(BankTransferDocument) = Undefined Then
				DocumentFound = True;
				UsedDocuments.Add(BankTransferDocument);
				Break;
			Else
				Continue;	
			EndIf;
		EndDo;
		If DocumentFound Then
			ReturnStructure = New Structure("TransactionID, FoundDocument, FoundDocumentPresentation");
			ReturnStructure.TransactionID = TransactionSelect.TransactionID;
			ReturnStructure.FoundDocument = BankTransferDocument;
			ReturnStructure.FoundDocumentPresentation = DocumentsSelect.FoundDocumentPresentation;
			ReturnArray.Add(ReturnStructure);	
			//Record result into database
			RS = InformationRegisters.BankTransactions.CreateRecordSet();
			IDFilter = RS.Filter.ID;
			IDFilter.Use = True;
			IDFilter.ComparisonType = ComparisonType.Equal;
			IDFilter.Value = TransactionSelect.TransactionID;
			RS.Read();
			For Each Rec In RS Do
				Rec.Document = BankTransferDocument;
			EndDo;
			RS.Write(True);
		EndIf;
	EndDo;
	
	CommitTransaction();
	If TempStorageAddress <> Undefined Then
		PutToTempStorage(New Structure("CurrentStatus, ErrorDescription, AffectedRows", True, "", ReturnArray), TempStorageAddress);
	EndIf;
Except
	ErrorDescription = ErrorDescription();
	If TempStorageAddress <> Undefined Then
		PutToTempStorage(New Structure("CurrentStatus, ErrorDescription", False, ErrorDescription), TempStorageAddress);
	EndIf;
	WriteLogEvent("DownloadedTransactions.DocumentMatching", EventLogLevel.Error,,, ErrorDescription());	
	RollbackTransaction();
EndTry;			

EndProcedure

Procedure MatchChecks(AccountInBank, AccountingAccount, TempStorageAddress = Undefined) Export
	
Try
	SetPrivilegedMode(True);	
	BeginTransaction(DataLockControlMode.Managed);
	
	// Create new managed data lock
	DataLock = New DataLock;

	// Set data lock parameters
	// Set shared lock to get consisitent data
	BA_LockItem = DataLock.Add("InformationRegister.BankTransactions");
	BA_LockItem.Mode = DataLockMode.Shared;
	BA_LockItem.SetValue("BankAccount", AccountInBank);
	
	//Obtain a list of transactions containing "Check" in the description
	Request = New Query("SELECT ALLOWED
	                    |	BankTransactions.TransactionDate,
	                    |	BankTransactions.ID,
	                    |	BankTransactions.Amount,
	                    |	BankTransactions.Description
	                    |FROM
	                    |	InformationRegister.BankTransactions AS BankTransactions
	                    |WHERE
	                    |	BankTransactions.BankAccount = &BankAccount
	                    |	AND BankTransactions.Document = UNDEFINED
	                    |	AND BankTransactions.Accepted = FALSE
	                    |	AND BankTransactions.Description LIKE ""%check%""");
	Request.SetParameter("BankAccount", AccountInBank);
	VT = Request.Execute().Unload();

	
	// Set exclusive lock on potentially modifiable records 
	BA_LockItem = DataLock.Add("InformationRegister.BankTransactions");
	BA_LockItem.Mode = DataLockMode.Exclusive;
	BA_LockItem.SetValue("BankAccount", AccountInBank);	
	BA_LockItem.DataSource = VT;
	BA_LockItem.UseFromDataSource("ID", "ID");
	// Set lock on the object
	DataLock.Lock();

	Request = New Query("SELECT ALLOWED
	                    |	BankTransactions.TransactionDate,
	                    |	BankTransactions.ID,
	                    |	BankTransactions.Amount,
	                    |	BankTransactions.Description
	                    |INTO UnacceptedTransactionsWithoutDocuments
	                    |FROM
	                    |	InformationRegister.BankTransactions AS BankTransactions
	                    |WHERE
	                    |	BankTransactions.BankAccount = &BankAccount
	                    |	AND BankTransactions.Document = UNDEFINED
	                    |	AND BankTransactions.Accepted = FALSE
	                    |	AND BankTransactions.Description LIKE ""%check%""
	                    |;
	                    |
	                    |////////////////////////////////////////////////////////////////////////////////
	                    |SELECT ALLOWED
	                    |	Check.Ref,
	                    |	Check.Date,
	                    |	Check.DocumentTotalRC,
	                    |	Check.PointInTime
	                    |INTO AvailableCheckDocuments
	                    |FROM
	                    |	Document.Check AS Check
	                    |		LEFT JOIN InformationRegister.BankTransactions AS BankTransactions
	                    |		ON Check.Ref = BankTransactions.Document
	                    |WHERE
	                    |	BankTransactions.Document IS NULL 
	                    |	AND Check.BankAccount = &AccountingAccount
	                    |
	                    |UNION ALL
	                    |
	                    |SELECT
	                    |	InvoicePayment.Ref,
	                    |	InvoicePayment.Date,
	                    |	InvoicePayment.DocumentTotalRC,
	                    |	InvoicePayment.PointInTime
	                    |FROM
	                    |	Document.InvoicePayment AS InvoicePayment
	                    |		LEFT JOIN InformationRegister.BankTransactions AS BankTransactions
	                    |		ON InvoicePayment.Ref = BankTransactions.Document
	                    |WHERE
	                    |	BankTransactions.Document IS NULL 
	                    |	AND InvoicePayment.BankAccount = &AccountingAccount
	                    |;
	                    |
	                    |////////////////////////////////////////////////////////////////////////////////
	                    |SELECT ALLOWED
	                    |	Deposit.Ref,
	                    |	Deposit.Date,
	                    |	Deposit.DocumentTotalRC,
	                    |	Deposit.PointInTime
	                    |INTO AvailableDepositDocuments
	                    |FROM
	                    |	Document.Deposit AS Deposit
	                    |		LEFT JOIN InformationRegister.BankTransactions AS BankTransactions
	                    |		ON Deposit.Ref = BankTransactions.Document
	                    |WHERE
	                    |	BankTransactions.Document IS NULL 
	                    |	AND Deposit.BankAccount = &AccountingAccount
	                    |;
	                    |
	                    |////////////////////////////////////////////////////////////////////////////////
	                    |SELECT ALLOWED
	                    |	UnacceptedTransactionsWithoutDocuments.TransactionDate,
	                    |	UnacceptedTransactionsWithoutDocuments.ID,
	                    |	UnacceptedTransactionsWithoutDocuments.Amount,
	                    |	UnacceptedTransactionsWithoutDocuments.Description,
	                    |	AvailableCheckDocuments.Ref AS FoundDocument,
	                    |	AvailableCheckDocuments.Date AS DocumentDate,
	                    |	AvailableCheckDocuments.PointInTime AS DocumentPointInTime
	                    |INTO FoundDocuments
	                    |FROM
	                    |	UnacceptedTransactionsWithoutDocuments AS UnacceptedTransactionsWithoutDocuments
	                    |		INNER JOIN AvailableCheckDocuments AS AvailableCheckDocuments
	                    |		ON (-1 * UnacceptedTransactionsWithoutDocuments.Amount = AvailableCheckDocuments.DocumentTotalRC)
	                    |			AND (UnacceptedTransactionsWithoutDocuments.Amount < 0)
						|			AND (AvailableCheckDocuments.Date < DATEADD(UnacceptedTransactionsWithoutDocuments.TransactionDate, DAY, 90))
						|			AND (AvailableCheckDocuments.Date > DATEADD(UnacceptedTransactionsWithoutDocuments.TransactionDate, DAY, -90))
	                    |
	                    |UNION ALL
	                    |
	                    |SELECT
	                    |	UnacceptedTransactionsWithoutDocuments.TransactionDate,
	                    |	UnacceptedTransactionsWithoutDocuments.ID,
	                    |	UnacceptedTransactionsWithoutDocuments.Amount,
	                    |	UnacceptedTransactionsWithoutDocuments.Description,
	                    |	AvailableDepositDocuments.Ref,
	                    |	AvailableDepositDocuments.Date,
	                    |	AvailableDepositDocuments.PointInTime
	                    |FROM
	                    |	UnacceptedTransactionsWithoutDocuments AS UnacceptedTransactionsWithoutDocuments
	                    |		INNER JOIN AvailableDepositDocuments AS AvailableDepositDocuments
	                    |		ON UnacceptedTransactionsWithoutDocuments.Amount = AvailableDepositDocuments.DocumentTotalRC
	                    |			AND (UnacceptedTransactionsWithoutDocuments.Amount > 0)
						|			AND (AvailableDepositDocuments.Date < DATEADD(UnacceptedTransactionsWithoutDocuments.TransactionDate, DAY, 90))
	                    |			AND (AvailableDepositDocuments.Date > DATEADD(UnacceptedTransactionsWithoutDocuments.TransactionDate, DAY, -90))
	                    |;
	                    |
	                    |////////////////////////////////////////////////////////////////////////////////
	                    |SELECT ALLOWED
	                    |	FoundDocuments.TransactionDate AS TransactionDate,
	                    |	FoundDocuments.ID AS TransactionID,
	                    |	FoundDocuments.Description AS TransactionDescription,
	                    |	FoundDocuments.FoundDocument,
	                    |	FoundDocuments.DocumentPointInTime AS DocumentPointInTime,
	                    |	FoundDocuments.FoundDocument.Number AS DocumentNumber,
	                    |	FoundDocuments.FoundDocument.Presentation
	                    |FROM
	                    |	FoundDocuments AS FoundDocuments
	                    |
	                    |ORDER BY
	                    |	TransactionDate,
	                    |	FoundDocuments.ID,
	                    |	DocumentPointInTime
	                    |TOTALS BY
	                    |	TransactionID");
	Request.SetParameter("BankAccount", AccountInBank);
	Request.SetParameter("AccountingAccount", AccountingAccount);
	Res = Request.Execute();
	
	If Res.IsEmpty() Then
		If TempStorageAddress <> Undefined Then
			PutToTempStorage(New Structure("CurrentStatus, ErrorDescription, AffectedRows", True, "", New Array()), TempStorageAddress);
		EndIf;
		RollbackTransaction();
		return;
	EndIf;
	TransactionSelect = Res.Select(QueryResultIteration.ByGroups);
	UsedDocuments = New Array();
	ReturnArray = New Array();
	While TransactionSelect.Next() Do
		DocumentsSelect = TransactionSelect.Select();
		DocumentFound = False;
		CheckDocument = Undefined;
		While (Not DocumentFound) And (DocumentsSelect.Next()) Do
			CheckDocument = DocumentsSelect.FoundDocument;
			CheckNumberFound = (Find(Upper(DocumentsSelect.TransactionDescription), Upper(DocumentsSelect.DocumentNumber))>0);
			If CheckNumberFound And (UsedDocuments.Find(CheckDocument) = Undefined) Then
				DocumentFound = True;
				UsedDocuments.Add(CheckDocument);
				Break;
			Else
				Continue;	
			EndIf;
		EndDo;
		If DocumentFound Then
			ReturnStructure = New Structure("TransactionID, FoundDocument, FoundDocumentPresentation");
			ReturnStructure.TransactionID = TransactionSelect.TransactionID;
			ReturnStructure.FoundDocument = CheckDocument;
			ReturnStructure.FoundDocumentPresentation = DocumentsSelect.FoundDocumentPresentation;
			ReturnArray.Add(ReturnStructure);	
			//Record result into database
			RS = InformationRegisters.BankTransactions.CreateRecordSet();
			IDFilter = RS.Filter.ID;
			IDFilter.Use = True;
			IDFilter.ComparisonType = ComparisonType.Equal;
			IDFilter.Value = TransactionSelect.TransactionID;
			RS.Read();
			For Each Rec In RS Do
				Rec.Document = CheckDocument;
			EndDo;
			RS.Write(True);
		EndIf;
	EndDo;
	CommitTransaction();
	If TempStorageAddress <> Undefined Then
		PutToTempStorage(New Structure("CurrentStatus, ErrorDescription, AffectedRows", True, "", ReturnArray), TempStorageAddress);
	EndIf;
Except
	ErrorDescription = ErrorDescription();
	If TempStorageAddress <> Undefined Then
		PutToTempStorage(New Structure("CurrentStatus, ErrorDescription", False, ErrorDescription), TempStorageAddress);
	EndIf;
	WriteLogEvent("DownloadedTransactions.DocumentMatching", EventLogLevel.Error,,, ErrorDescription());	
	RollbackTransaction();
EndTry;			

EndProcedure

Procedure MatchDepositDocuments(AccountInBank, AccountingAccount, TempStorageAddress = Undefined) Export
	
Try
	BeginTransaction(DataLockControlMode.Managed);
	
	// Create new managed data lock
	DataLock = New DataLock;

	// Set data lock parameters
	// Set shared lock to get consisitent data
	BA_LockItem = DataLock.Add("InformationRegister.BankTransactions");
	BA_LockItem.Mode = DataLockMode.Shared;
	BA_LockItem.SetValue("BankAccount", AccountInBank);
	
	//Obtain a list of deposit transactions (with positive amounts)
	Request = New Query("SELECT ALLOWED
	                    |	BankTransactions.TransactionDate,
	                    |	BankTransactions.ID,
	                    |	BankTransactions.Amount,
	                    |	BankTransactions.Description
	                    |FROM
	                    |	InformationRegister.BankTransactions AS BankTransactions
	                    |WHERE
	                    |	BankTransactions.BankAccount = &BankAccount
	                    |	AND BankTransactions.Document = UNDEFINED
	                    |	AND BankTransactions.Accepted = FALSE
	                    |	AND BankTransactions.Amount > 0");
	Request.SetParameter("BankAccount", AccountInBank);
	VT = Request.Execute().Unload();
	
	// Set exclusive lock on potentially modifiable records 
	BA_LockItem = DataLock.Add("InformationRegister.BankTransactions");
	BA_LockItem.Mode = DataLockMode.Exclusive;
	BA_LockItem.SetValue("BankAccount", AccountInBank);	
	BA_LockItem.DataSource = VT;
	BA_LockItem.UseFromDataSource("ID", "ID");
	// Set lock on the object
	DataLock.Lock();

	Request = New Query("SELECT ALLOWED
	                    |	BankTransactions.TransactionDate,
	                    |	BankTransactions.ID,
	                    |	BankTransactions.Amount
	                    |INTO UnacceptedTransactionsWithoutDocuments
	                    |FROM
	                    |	InformationRegister.BankTransactions AS BankTransactions
	                    |WHERE
	                    |	BankTransactions.BankAccount = &BankAccount
	                    |	AND BankTransactions.Document = UNDEFINED
	                    |	AND BankTransactions.Accepted = FALSE
	                    |	AND BankTransactions.Amount > 0
	                    |;
	                    |
	                    |////////////////////////////////////////////////////////////////////////////////
	                    |SELECT ALLOWED
	                    |	Deposit.Ref,
	                    |	Deposit.Date,
	                    |	Deposit.DocumentTotalRC,
	                    |	Deposit.PointInTime
	                    |INTO AvailableDepositDocuments
	                    |FROM
	                    |	Document.Deposit AS Deposit
	                    |		LEFT JOIN InformationRegister.BankTransactions AS BankTransactions
	                    |		ON Deposit.Ref = BankTransactions.Document
	                    |WHERE
	                    |	BankTransactions.Document IS NULL 
	                    |	AND Deposit.BankAccount = &AccountingAccount
	                    |;
	                    |
	                    |////////////////////////////////////////////////////////////////////////////////
	                    |SELECT ALLOWED
	                    |	UnacceptedTransactionsWithoutDocuments.TransactionDate,
	                    |	UnacceptedTransactionsWithoutDocuments.ID,
	                    |	UnacceptedTransactionsWithoutDocuments.Amount,
	                    |	AvailableDepositDocuments.Ref AS FoundDocument,
	                    |	AvailableDepositDocuments.Date AS DocumentDate,
	                    |	AvailableDepositDocuments.PointInTime AS DocumentPointInTime
	                    |INTO FoundDocuments
	                    |FROM
	                    |	UnacceptedTransactionsWithoutDocuments AS UnacceptedTransactionsWithoutDocuments
	                    |		INNER JOIN AvailableDepositDocuments AS AvailableDepositDocuments
	                    |		ON UnacceptedTransactionsWithoutDocuments.Amount = AvailableDepositDocuments.DocumentTotalRC
	                    |			AND (AvailableDepositDocuments.Date < DATEADD(UnacceptedTransactionsWithoutDocuments.TransactionDate, DAY, 7))
	                    |			AND (AvailableDepositDocuments.Date > DATEADD(UnacceptedTransactionsWithoutDocuments.TransactionDate, DAY, -7))
	                    |;
	                    |
	                    |////////////////////////////////////////////////////////////////////////////////
	                    |SELECT ALLOWED
	                    |	FoundDocuments.TransactionDate AS TransactionDate,
	                    |	FoundDocuments.ID AS TransactionID,
	                    |	FoundDocuments.FoundDocument,
	                    |	FoundDocuments.DocumentPointInTime AS DocumentPointInTime,
	                    |	FoundDocuments.FoundDocument.Presentation
	                    |FROM
	                    |	FoundDocuments AS FoundDocuments
	                    |
	                    |ORDER BY
	                    |	TransactionDate,
	                    |	FoundDocuments.ID,
	                    |	DocumentPointInTime
	                    |TOTALS BY
	                    |	TransactionID");
	Request.SetParameter("BankAccount", AccountInBank);
	Request.SetParameter("AccountingAccount", AccountingAccount);
	Res = Request.Execute();
	
	If Res.IsEmpty() Then
		If TempStorageAddress <> Undefined Then
			PutToTempStorage(New Structure("CurrentStatus, ErrorDescription, AffectedRows", True, "", New Array()), TempStorageAddress);
		EndIf;
		RollbackTransaction();
		return;
	EndIf;
	TransactionSelect = Res.Select(QueryResultIteration.ByGroups);
	UsedDocuments = New Array();
	ReturnArray = New Array();
	While TransactionSelect.Next() Do
		DocumentsSelect = TransactionSelect.Select();
		DocumentFound = False;
		DepositDocument = Documents.Deposit.EmptyRef();
		While (Not DocumentFound) And (DocumentsSelect.Next()) Do
			DepositDocument = DocumentsSelect.FoundDocument;
			If UsedDocuments.Find(DepositDocument) = Undefined Then
				DocumentFound = True;
				UsedDocuments.Add(DepositDocument);
				Break;
			Else
				Continue;	
			EndIf;
		EndDo;
		If DocumentFound Then
			ReturnStructure = New Structure("TransactionID, FoundDocument, FoundDocumentPresentation");
			ReturnStructure.TransactionID 	= TransactionSelect.TransactionID;
			ReturnStructure.FoundDocument 	= DepositDocument;
			ReturnStructure.FoundDocumentPresentation = DocumentsSelect.FoundDocumentPresentation;
			ReturnArray.Add(ReturnStructure);	
			//Record result into database
			RS = InformationRegisters.BankTransactions.CreateRecordSet();
			IDFilter = RS.Filter.ID;
			IDFilter.Use = True;
			IDFilter.ComparisonType = ComparisonType.Equal;
			IDFilter.Value = TransactionSelect.TransactionID;
			RS.Read();
			For Each Rec In RS Do
				Rec.Document = DepositDocument;
			EndDo;
			RS.Write(True);
		EndIf;
	EndDo;
	CommitTransaction();
	If TempStorageAddress <> Undefined Then
		PutToTempStorage(New Structure("CurrentStatus, ErrorDescription, AffectedRows", True, "", ReturnArray), TempStorageAddress);
	EndIf;
Except
	ErrorDescription = ErrorDescription();
	If TempStorageAddress <> Undefined Then
		PutToTempStorage(New Structure("CurrentStatus, ErrorDescription", False, ErrorDescription), TempStorageAddress);
	EndIf;
	WriteLogEvent("DownloadedTransactions.DocumentMatching", EventLogLevel.Error,,, ErrorDescription());	
	RollbackTransaction();
EndTry;			

EndProcedure

Procedure MatchCheckDocuments(AccountInBank, AccountingAccount, TempStorageAddress = Undefined) Export
	
Try	
	BeginTransaction(DataLockControlMode.Managed);
	
	// Create new managed data lock
	DataLock = New DataLock;

	// Set data lock parameters
	// Set shared lock to get consisitent data
	BA_LockItem = DataLock.Add("InformationRegister.BankTransactions");
	BA_LockItem.Mode = DataLockMode.Shared;
	BA_LockItem.SetValue("BankAccount", AccountInBank);
	
	//Obtain a list of deposit transactions (with positive amounts)
	Request = New Query("SELECT ALLOWED
	                    |	BankTransactions.TransactionDate,
	                    |	BankTransactions.ID,
	                    |	BankTransactions.Amount,
	                    |	BankTransactions.Description
	                    |FROM
	                    |	InformationRegister.BankTransactions AS BankTransactions
	                    |WHERE
	                    |	BankTransactions.BankAccount = &BankAccount
	                    |	AND BankTransactions.Document = UNDEFINED
	                    |	AND BankTransactions.Accepted = FALSE
	                    |	AND BankTransactions.Amount < 0");
	Request.SetParameter("BankAccount", AccountInBank);
	VT = Request.Execute().Unload();
	
	// Set exclusive lock on potentially modifiable records 
	BA_LockItem = DataLock.Add("InformationRegister.BankTransactions");
	BA_LockItem.Mode = DataLockMode.Exclusive;
	BA_LockItem.SetValue("BankAccount", AccountInBank);	
	BA_LockItem.DataSource = VT;
	BA_LockItem.UseFromDataSource("ID", "ID");
	// Set lock on the object
	DataLock.Lock();

	Request = New Query("SELECT ALLOWED
	                    |	BankTransactions.TransactionDate,
	                    |	BankTransactions.ID,
	                    |	BankTransactions.Amount
	                    |INTO UnacceptedTransactionsWithoutDocuments
	                    |FROM
	                    |	InformationRegister.BankTransactions AS BankTransactions
	                    |WHERE
	                    |	BankTransactions.BankAccount = &BankAccount
	                    |	AND BankTransactions.Document = UNDEFINED
	                    |	AND BankTransactions.Accepted = FALSE
	                    |	AND BankTransactions.Amount < 0
	                    |;
	                    |
	                    |////////////////////////////////////////////////////////////////////////////////
	                    |SELECT ALLOWED
	                    |	Check.Ref,
	                    |	Check.Date,
	                    |	Check.DocumentTotalRC,
	                    |	Check.PointInTime
	                    |INTO AvailableCheckDocuments
	                    |FROM
	                    |	Document.Check AS Check
	                    |		LEFT JOIN InformationRegister.BankTransactions AS BankTransactions
	                    |		ON Check.Ref = BankTransactions.Document
	                    |WHERE
	                    |	BankTransactions.Document IS NULL 
	                    |	AND Check.BankAccount = &AccountingAccount
	                    |
	                    |UNION ALL
	                    |
	                    |SELECT
	                    |	InvoicePayment.Ref,
	                    |	InvoicePayment.Date,
	                    |	InvoicePayment.DocumentTotalRC,
	                    |	InvoicePayment.PointInTime
	                    |FROM
	                    |	Document.InvoicePayment AS InvoicePayment
	                    |		LEFT JOIN InformationRegister.BankTransactions AS BankTransactions
	                    |		ON InvoicePayment.Ref = BankTransactions.Document
	                    |WHERE
	                    |	BankTransactions.Document IS NULL 
	                    |	AND InvoicePayment.BankAccount = &AccountingAccount
	                    |;
	                    |
	                    |////////////////////////////////////////////////////////////////////////////////
	                    |SELECT ALLOWED
	                    |	UnacceptedTransactionsWithoutDocuments.TransactionDate,
	                    |	UnacceptedTransactionsWithoutDocuments.ID,
	                    |	UnacceptedTransactionsWithoutDocuments.Amount,
	                    |	AvailableCheckDocuments.Ref AS FoundDocument,
	                    |	AvailableCheckDocuments.Date AS DocumentDate,
	                    |	AvailableCheckDocuments.PointInTime AS DocumentPointInTime
	                    |INTO FoundDocuments
	                    |FROM
	                    |	UnacceptedTransactionsWithoutDocuments AS UnacceptedTransactionsWithoutDocuments
	                    |		INNER JOIN AvailableCheckDocuments AS AvailableCheckDocuments
	                    |		ON (-1 * UnacceptedTransactionsWithoutDocuments.Amount = AvailableCheckDocuments.DocumentTotalRC)
	                    |			AND (AvailableCheckDocuments.Date < DATEADD(UnacceptedTransactionsWithoutDocuments.TransactionDate, DAY, 7))
	                    |			AND (AvailableCheckDocuments.Date > DATEADD(UnacceptedTransactionsWithoutDocuments.TransactionDate, DAY, -7))
	                    |;
	                    |
	                    |////////////////////////////////////////////////////////////////////////////////
	                    |SELECT ALLOWED
	                    |	FoundDocuments.TransactionDate AS TransactionDate,
	                    |	FoundDocuments.ID AS TransactionID,
	                    |	FoundDocuments.FoundDocument,
	                    |	FoundDocuments.DocumentPointInTime AS DocumentPointInTime,
	                    |	FoundDocuments.FoundDocument.Presentation
	                    |FROM
	                    |	FoundDocuments AS FoundDocuments
	                    |
	                    |ORDER BY
	                    |	TransactionDate,
	                    |	FoundDocuments.ID,
	                    |	DocumentPointInTime
	                    |TOTALS BY
	                    |	TransactionID");
	Request.SetParameter("BankAccount", AccountInBank);
	Request.SetParameter("AccountingAccount", AccountingAccount);
	Res = Request.Execute();
	
	If Res.IsEmpty() Then
		If TempStorageAddress <> Undefined Then
			PutToTempStorage(New Structure("CurrentStatus, ErrorDescription, AffectedRows", True, "", New Array()), TempStorageAddress);
		EndIf;
		RollbackTransaction();
		return;
	EndIf;
	TransactionSelect = Res.Select(QueryResultIteration.ByGroups);
	UsedDocuments = New Array();
	ReturnArray = New Array();
	While TransactionSelect.Next() Do
		DocumentsSelect = TransactionSelect.Select();
		DocumentFound = False;
		CheckDocument = Documents.Check.EmptyRef();
		While (Not DocumentFound) And (DocumentsSelect.Next()) Do
			CheckDocument = DocumentsSelect.FoundDocument;
			If UsedDocuments.Find(CheckDocument) = Undefined Then
				DocumentFound = True;
				UsedDocuments.Add(CheckDocument);
				Break;
			Else
				Continue;	
			EndIf;
		EndDo;
		If DocumentFound Then
			ReturnStructure = New Structure("TransactionID, FoundDocument, FoundDocumentPresentation");
			ReturnStructure.TransactionID = TransactionSelect.TransactionID;
			ReturnStructure.FoundDocument = CheckDocument;
			ReturnStructure.FoundDocumentPresentation = DocumentsSelect.FoundDocumentPresentation;
			ReturnArray.Add(ReturnStructure);	
			//Record result into database
			RS = InformationRegisters.BankTransactions.CreateRecordSet();
			IDFilter = RS.Filter.ID;
			IDFilter.Use = True;
			IDFilter.ComparisonType = ComparisonType.Equal;
			IDFilter.Value = TransactionSelect.TransactionID;
			RS.Read();
			For Each Rec In RS Do
				Rec.Document = CheckDocument;
			EndDo;
			RS.Write(True);
		EndIf;
	EndDo;
	CommitTransaction();
	If TempStorageAddress <> Undefined Then
		PutToTempStorage(New Structure("CurrentStatus, ErrorDescription, AffectedRows", True, "", ReturnArray), TempStorageAddress);
	EndIf;
Except
	ErrorDescription = ErrorDescription();
	If TempStorageAddress <> Undefined Then
		PutToTempStorage(New Structure("CurrentStatus, ErrorDescription", False, ErrorDescription), TempStorageAddress);
	EndIf;
	WriteLogEvent("DownloadedTransactions.DocumentMatching", EventLogLevel.Error,,, ErrorDescription());	
	RollbackTransaction();
EndTry;	

EndProcedure

Procedure AcceptTransactionsAtServer(ListOfTransactions, ListOfCategories, AccountingAccount, TempStorageAddress = Undefined) Export
	
	Try
	BeginTransaction();
	i = 0;
	BTRecordset = InformationRegisters.BankTransactions.CreateRecordSet();
	While i < ListOfTransactions.Count() Do
		TranID 		= ListOfTransactions[i].Value;
		Category 	= ListOfCategories[i].Value;
		
		BTRecordset.Clear();
		BTRecordSet.Filter.Reset();
		BTRecordset.Filter.ID.Set(TranID);
		BTRecordset.Read();
		If BTRecordset.Count() > 0 Then
			If BTRecordset[0].Accepted Then
				i = i + 1;
				Continue;
			Else
				Trans = BTRecordset.Unload();
				Tran = Trans[0];
				Tran.Category = Category;
			EndIf;
		Else
			i = i + 1;
			Continue;
		EndIf;
		
		If TypeOf(Tran.Document) = Type("DocumentRef.BankTransfer") Then //Create Bank Transfer
			Tran.Document				= Create_DocumentBankTransfer(Tran);
		ElsIf TypeOf(Tran.Document) = Type("DocumentRef.SalesInvoice") Then
			Tran.Document				= Create_DocumentCashReceipt(Tran, AccountingAccount);
		ElsIf TypeOf(Tran.Document) = Type("DocumentRef.PurchaseInvoice") Then
			Tran.Document				= Create_DocumentInvoicePayment(Tran, AccountingAccount);
		ElsIf Tran.Amount < 0 Then //Create Check
			Tran.Document				= Create_DocumentCheck(Tran);
		Else //Create Deposit
			Tran.Document				= Create_DocumentDeposit(Tran);
		EndIf;
		
		BTRecordset.Clear();
		BTRecordset.Filter.TransactionDate.Set(Tran.TransactionDate);
		BTRecordset.Filter.BankAccount.Set(Tran.BankAccount);
		BTRecordset.Filter.Company.Set(Tran.Company);
		BTRecordset.Filter.ID.Set(Tran.ID);
		NewRecord = BTRecordset.Add();
		FillPropertyValues(NewRecord, Tran);
		NewRecord.Accepted = True;
		BTRecordset.Write(True);
		
		i = i + 1;
	EndDo;
	
	CommitTransaction();
	
	ReturnArray = ListOfTransactions.UnloadValues();
	AccountingBalance = GetAccountingSuiteAccountBalance(AccountingAccount);
	
	If TempStorageAddress <> Undefined Then
		PutToTempStorage(New Structure("CurrentStatus, ErrorDescription, AffectedRows, AccountingBalance", True, "", ReturnArray, AccountingBalance), TempStorageAddress);
	EndIf;

		
Except
	
	ErrorDescription = ErrorDescription();
	If TransactionActive() Then
		RollbackTransaction();
	EndIf;
	If TempStorageAddress <> Undefined Then
		PutToTempStorage(New Structure("CurrentStatus, ErrorDescription", False, ErrorDescription), TempStorageAddress);
	Else
		CommonUseClientServer.MessageToUser(ErrorDescription);
	EndIf;
	WriteLogEvent("DownloadedTransactions.AcceptingTransactions", EventLogLevel.Error,,, ErrorDescription());	

EndTry;		
		
EndProcedure

#EndRegion

#Region PRIVATE_IMPLEMENTATION

//Processes accepted transaction
//Fills categorization library
//
//Parameters:
// TabRow - row of value table
// Columns:
// ID - the UUID of the transaction
// Description - String - the description of the transaction
// Company - CatalogRef.Companies - assigned company
// Category - ChartOfAccountsRef.ChartOfAccounts - assigned category
// YodleeCategory - ChartOfAccountsRef.ChartOfAccounts - assigned category by Yodlee
// TransactionDate - Date - the date of the transaction

Procedure ProcessTransactionForCategorization(TabRow)
	Description = TabRow.Description;
	lexemes = StringFunctionsClientServer.SplitStringIntoSubstringArray(Description, " ");
	//delete 1- to 2- letter words
	i = 0;
	While i < lexemes.Count() Do
		If StrLen(lexemes[i]) < 3 Then
			lexemes.Delete(i);
		Else
			i = i + 1;
		EndIf;
	EndDo;
	LexemNumber = 0;
	RecordSet = InformationRegisters.BankTransactionCategorization.CreateRecordSet();
	IDFilter = RecordSet.Filter.TransactionID;
	IDFilter.Use = True;
	IDFilter.ComparisonType = ComparisonType.Equal;
	IDFilter.Value 			= TabRow.ID;
	
	For Each lexem In lexemes Do
		NewRecord = RecordSet.Add();
		NewRecord.BankAccount 	= TabRow.BankAccount;
		NewRecord.Lexem 	= lexem;
		NewRecord.TransactionID = TabRow.ID;
		NewRecord.LexemNumber	= LexemNumber; 
		NewRecord.Customer 	= TabRow.Company;
		NewRecord.Category 	= ?(TabRow.Category = TabRow.YodleeCategory, ChartsOfAccounts.ChartOfAccounts.EmptyRef(), TabRow.Category);
		LexemNumber			= LexemNumber + 1;
	EndDo;	
	//Add the record with the full description
	NewRecord = RecordSet.Add();
	NewRecord.BankAccount = TabRow.BankAccount;
	NewRecord.Lexem = Description;
	NewRecord.TransactionID = TabRow.ID;
	NewRecord.LexemNumber	= LexemNumber;
	NewRecord.Customer = TabRow.Company;
	NewRecord.Category = TabRow.Category;
	NewRecord.FullDescription = True;
	RecordSet.Write(True);	
EndProcedure

Function RecordTransactionToTheDatabase(Tran)
	Try
		BeginTransaction();
		BTRecordset = InformationRegisters.BankTransactions.CreateRecordSet();
		//Add (save) current row to a information register
		If NOT ValueIsFilled(Tran.ID) then
			Tran.ID = New UUID();
		EndIf;
		BTRecordset.Filter.ID.Set(Tran.ID);
		BTRecordset.Write(True);

		BTRecordset.Clear();
		BTRecordset.Filter.TransactionDate.Set(Tran.TransactionDate);
		BTRecordset.Filter.BankAccount.Set(Tran.BankAccount);
		BTRecordset.Filter.Company.Set(Tran.Company);
		BTRecordset.Filter.ID.Set(Tran.ID);
		NewRecord = BTRecordset.Add();
		FillPropertyValues(NewRecord, Tran);
		BTRecordset.Write(True);
		CommitTransaction();
	Except
		ErrDesc = ErrorDescription();
		If TransactionActive() Then
			RollbackTransaction();
		EndIf;
		Raise ErrDesc;
	EndTry;
EndFunction

Function Create_DocumentInvoicePayment(Tran, BankAccount)
	PurchaseInvoice = Tran.Document;
	
	NewInvoicePayment 				= Documents.InvoicePayment.CreateDocument();	                                                             
	NewInvoicePayment.Date 			= Tran.TransactionDate;
	NewInvoicePayment.Company 			= PurchaseInvoice.Company;
	NewInvoicePayment.DocumentTotal 	= -1 * Tran.Amount;
	NewInvoicePayment.DocumentTotalRC 	= -1 * Tran.Amount;
	NewInvoicePayment.BankAccount		= BankAccount;
	NewInvoicePayment.Currency			= Catalogs.Currencies.USD;
	NewInvoicePayment.PaymentMethod		= Catalogs.PaymentMethods.DebitCard;
	NewInvoicePayment.Memo 				= Tran.Description;
	NewInvoicePayment.AutoGenerated		= True;
	
	LineItem = NewInvoicePayment.LineItems.Add();
	LineItem.Document 	= PurchaseInvoice;
	LineItem.Payment 	= -1 * Tran.Amount;
	LineItem.Check 		= True;
	LineItem.Currency	= Catalogs.Currencies.USD;
	
	NewInvoicePayment.Write(DocumentWriteMode.Posting);
	
	Return NewInvoicePayment.Ref;
EndFunction

Function Create_DocumentCashReceipt(Tran, BankAccount)
	SalesInvoice = Tran.Document;
	
	NewCashReceipt 		= Documents.CashReceipt.CreateDocument();	                                                             
	NewCashReceipt.Date 			= Tran.TransactionDate;
	NewCashReceipt.Company 			= SalesInvoice.Company;
	NewCashReceipt.DocumentTotal 	= Tran.Amount;
	NewCashReceipt.CashPayment 		= Tran.Amount;
	NewCashReceipt.DepositType		= "2";
	NewCashReceipt.DocumentTotalRC 	= Tran.Amount;
	NewCashReceipt.BankAccount		= BankAccount;
	NewCashReceipt.Currency			= Catalogs.Currencies.USD;
	NewCashReceipt.ExchangeRate     = 1;
	NewCashReceipt.ARAccount		= SalesInvoice.ARAccount;
	NewCashReceipt.Memo 	        = Tran.Description;
	NewCashReceipt.AutoGenerated	= True;
	
	LineItem = NewCashReceipt.LineItems.Add();
	LineItem.Document 	= SalesInvoice;
	LineItem.Payment 	= Tran.Amount;
	//LineItem.Currency	= Catalogs.Currencies.USD;
	
	NewCashReceipt.Write(DocumentWriteMode.Posting);
	
	Return NewCashReceipt.Ref;
EndFunction

Function Create_DocumentBankTransfer(Tran)
	If ValueIsFilled(Tran.Document) then
		return Tran.Document;
	Else
		NewBankTransfer 		= Documents.BankTransfer.CreateDocument();
	EndIf;
	                                                             
	NewBankTransfer.Date 		= Tran.TransactionDate;
	If Tran.Amount < 0 Then
		NewBankTransfer.AccountFrom = Tran.BankAccount.AccountingAccount;
		NewBankTransfer.AccountTo 	= Tran.Category;
		NewBankTransfer.Amount		= -1 * Tran.Amount;
	Else
		NewBankTransfer.AccountFrom = Tran.Category;
		NewBankTransfer.AccountTo 	= Tran.BankAccount.AccountingAccount;
		NewBankTransfer.Amount 		= Tran.Amount;
	EndIf;
	NewBankTransfer.Memo 				= Tran.Description;
	NewBankTransfer.AutoGenerated		= True;
	
	NewBankTransfer.Write(DocumentWriteMode.Posting);
	
	Return NewBankTransfer.Ref;
EndFunction

Function Create_DocumentCheck(Tran)	
	If ValueIsFilled(Tran.Document) then
		If TypeOf(Tran.Document) = Type("DocumentRef.InvoicePayment") Then
			return Tran.Document;
		EndIf;
		If Not DocumentIsAutoGenerated(Tran.Document) Then
			return Tran.Document;
		EndIf;
		
		//Refill only auto-generated documents
		NewCheck		= Tran.Document.GetObject();
	Else
		NewCheck 		= Documents.Check.CreateDocument();
	EndIf;
	NewCheck.Date 	= Tran.TransactionDate;
	NewCheck.BankAccount 		= Tran.BankAccount.AccountingAccount;
	NewCheck.Memo 				= Tran.Description;
	NewCheck.Company 			= Tran.Company;
	NewCheck.DocumentTotal 		= -1*Tran.Amount;
	NewCheck.DocumentTotalRC 	= -1*Tran.Amount;
	NewCheck.ExchangeRate 		= 1;
	//If the description contains "Check" and some number between 100 and 99999999 then use Check payment method
	If Not IsBlankString(Tran.CheckNumber) Then
		NewCheck.PaymentMethod		= Catalogs.PaymentMethods.Check;
		NewCheck.Number				= TrimAll(Tran.CheckNumber);
	ElsIf Find(Upper(Tran.Description), "CHECK") > 0 Then
		lexemes = StringFunctionsClientServer.SplitStringIntoSubstringArray(Tran.Description, " ");
		//Try to find the exact match with "Check"
		ExactMatchFound = False;
		For Each lexem In lexemes Do
			If Upper(TrimAll(lexem)) = "CHECK" Then
				ExactMatchFound = True;
			EndIf;
		EndDo;
		If ExactMatchFound Then
			i = 0;
			While i < lexemes.Count() Do
				lexemes[i] = StrReplace(lexemes[i], "#", "");
				lexemes[i] = StrReplace(lexemes[i], "№", "");
				If IsBlankString(lexemes[i]) Then
					lexemes.Delete(i);
				Else
					i = i + 1;
				EndIf;
			EndDo;
			PotentialNumber = 0;
			For Each lexem In lexemes Do
				i = 0;
				ThisIsNumber = True;
				For i = 1 To StrLen(lexem) Do
					If Find("0123456789", Mid(lexem, i, 1)) = 0 Then
						ThisIsNumber = False;
						Break;
					EndIf;
				EndDo;
				If ThisIsNumber Then
					PotentialNumber = Number(lexem);
					Break;
				EndIf;
			EndDo;		
			If PotentialNumber <> 0 Then
				NewCheck.PaymentMethod		= Catalogs.PaymentMethods.Check;
				NewCheck.Number				= Format(PotentialNumber, "NFD=; NG=0");
			Else
				NewCheck.PaymentMethod		= Catalogs.PaymentMethods.DebitCard;	
			EndIf;
		Else
			NewCheck.PaymentMethod		= Catalogs.PaymentMethods.DebitCard;	
		EndIf;
	Else
		NewCheck.PaymentMethod		= Catalogs.PaymentMethods.DebitCard;
	EndIf;
	NewCheck.Project			= Tran.Project;
	NewCheck.AutoGenerated		= True;
	
	NewCheck.LineItems.Clear();
	NewLine = NewCheck.LineItems.Add();
	NewLine.Account 			= Tran.Category;
	NewLine.Amount 				= -1*Tran.Amount;
	NewLine.Memo 				= Tran.Description;
	NewLine.Class				= Tran.Class;
	NewLine.Project 			= Tran.Project;
	//Deletion mark
	If NewCheck.DeletionMark Then
		NewCheck.DeletionMark	= False;	
	EndIf;
	NewCheck.Write(DocumentWriteMode.Posting);
	
	Return NewCheck.Ref;
EndFunction

Function Create_DocumentDeposit(Tran)
	If ValueIsFilled(Tran.Document) then
		If TypeOf(Tran.Document) = Type("DocumentRef.CashReceipt") Then
			return Tran.Document;
		EndIf;
		If Not DocumentIsAutoGenerated(Tran.Document) Then
			return Tran.Document;
		EndIf;
		
		//Refill only auto-generated documents
		NewDeposit		= Tran.Document.GetObject();
	Else
		NewDeposit 		= Documents.Deposit.CreateDocument();
	EndIf;
	NewDeposit.Date 			= Tran.TransactionDate;
	NewDeposit.BankAccount 		= Tran.BankAccount.AccountingAccount;
	NewDeposit.Memo 			= Tran.Description;
	NewDeposit.DocumentTotal 	= Tran.Amount;
	NewDeposit.DocumentTotalRC 	= Tran.Amount;
	NewDeposit.TotalDeposits	= 0;
	NewDeposit.TotalDepositsRC	= 0;
	NewDeposit.AutoGenerated	= True;
		
	NewDeposit.Accounts.Clear();
	NewLine = NewDeposit.Accounts.Add();
	NewLine.Account 			= Tran.Category;
	NewLine.Memo 				= Tran.Description;
	NewLine.Company				= Tran.Company;
	NewLine.Amount 				= Tran.Amount;
	NewLine.Class 				= Tran.Class;
	NewLine.Project 			= Tran.Project;
	//Deletion mark
	If NewDeposit.DeletionMark Then
		NewDeposit.DeletionMark	= False;	
	EndIf;
	NewDeposit.Write(DocumentWriteMode.Posting);
	
	Return NewDeposit.Ref;
EndFunction

Function DocumentIsAutoGenerated(Document)
	If (TypeOf(Document) = Type("DocumentRef.Deposit")) 
		Or (TypeOf(Document) = Type("DocumentRef.Check"))
		Or (TypeOf(Document) = Type("DocumentRef.BankTransfer"))
		Or (TypeOf(Document) = Type("DocumentRef.CashReceipt")) 
		Or (TypeOf(Document) = Type("DocumentRef.InvoicePayment")) Then
		return Document.AutoGenerated;
	Else
		return False;
	EndIf;
EndFunction

Function GetAccountingSuiteAccountBalance(AccountingAccount)
	Request = New Query("SELECT
	                    |	GeneralJournalBalance.AmountBalance
	                    |FROM
	                    |	AccountingRegister.GeneralJournal.Balance(, Account = &Account, , ) AS GeneralJournalBalance");
	Request.SetParameter("Account", AccountingAccount);
	Res = Request.Execute().Select();
	If Res.Next() Then
		return Res.AmountBalance;
	Else
		return 0;
	EndIf;
EndFunction

#EndRegion
