
//Printing Reconciliation report
// Result - spreadsheet document
// Comand parameter array, 0 item has to be DocumentRef.BankReconciliation
Procedure PrintReconciliationReport(Result, CommandParameter) Export 
	
	Query = New Query("SELECT
	|	BankReconciliationLineItems.Transaction,
	|	BankReconciliationLineItems.TransactionAmount,
	|	BankReconciliationLineItems.Cleared
	|INTO TabularSection
	|FROM
	|	Document.BankReconciliation.LineItems AS BankReconciliationLineItems
	|WHERE
	|	BankReconciliationLineItems.Ref = &Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TransactionsForReconciliation.Ref,
	|	TransactionsForReconciliation.Date,
	|	TransactionsForReconciliation.Company,
	|	TransactionsForReconciliation.Number,
	|	SUM(TransactionsForReconciliation.Amount) AS Amount,
	|	TransactionsForReconciliation.Cleared AS Cleared
	|INTO UnreconciledTransactions
	|FROM
	|	(SELECT
	|		BankReconciliationBalance.Document AS Ref,
	|		BankReconciliationBalance.Document.Date AS Date,
	|		BankReconciliationBalance.Document.Company AS Company,
	|		BankReconciliationBalance.Document.Number AS Number,
	|		BankReconciliationBalance.AmountBalance AS Amount,
	|		FALSE AS Cleared
	|	FROM
	|		AccumulationRegister.BankReconciliation.Balance(&BoundaryEndOfStatementDate, Account = &BankAccount) AS BankReconciliationBalance
	|	WHERE
	|		BankReconciliationBalance.Document.Date <= &EndOfStatementDate
	|	
	|	UNION ALL
	|	
	|	
	|	SELECT
	|		BankReconciliation.Document,
	|		BankReconciliation.Document.Date,
	|		BankReconciliation.Document.Company,
	|		BankReconciliation.Document.Number,
	|		BankReconciliation.Amount,
	|		TRUE
	|	FROM
	|		AccumulationRegister.BankReconciliation AS BankReconciliation
	|	WHERE
	|		BankReconciliation.Recorder = &ThisDocument
	|		AND BankReconciliation.Active = TRUE) AS TransactionsForReconciliation
	|
	|GROUP BY
	|	TransactionsForReconciliation.Ref,
	|	TransactionsForReconciliation.Date,
	|	TransactionsForReconciliation.Company,
	|	TransactionsForReconciliation.Number,
	|	TransactionsForReconciliation.Cleared
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AllTransactions.Transaction,
	|	AllTransactions.DocType,
	|	AllTransactions.Date,
	|	AllTransactions.Company,
	|	AllTransactions.DocNumber,
	|	AllTransactions.TransactionAmount As Amount,
	|	AllTransactions.Cleared,
	|	AllTransactions.GroupLabel,
	|	AllTransactions.BankTransactionDate,
	|	AllTransactions.BankTransactionDescription,
	|	AllTransactions.BankTransactionAmount,
	|	AllTransactions.BankTransactionCategory
	|FROM
	|(SELECT
	|	VALUETYPE(UnreconciledTransactions.Ref) AS DocType,
	|	UnreconciledTransactions.Ref AS Transaction,
	|	UnreconciledTransactions.Date,
	|	UnreconciledTransactions.Company,
	|	UnreconciledTransactions.Number AS DocNumber,
	|	UnreconciledTransactions.Amount AS TransactionAmount,
	|	UnreconciledTransactions.Cleared AS Cleared,
	|	CASE
	|		WHEN (UnreconciledTransactions.Amount < 0) AND UnreconciledTransactions.Cleared 
	|			THEN 1
	|		WHEN (UnreconciledTransactions.Amount > 0) AND UnreconciledTransactions.Cleared 
	|			THEN 2
	|		WHEN (UnreconciledTransactions.Amount < 0) AND (NOT UnreconciledTransactions.Cleared) 
	|			THEN 3
	|		WHEN (UnreconciledTransactions.Amount > 0) AND (NOT UnreconciledTransactions.Cleared)
	|			THEN 4
	|		ELSE 9
	|	END AS GroupLabel,
	|	ISNULL(BankTransactions.TransactionDate, DATETIME(1, 1, 1)) AS BankTransactionDate,
	|	ISNULL(BankTransactions.Description, """") AS BankTransactionDescription,
	|	ISNULL(BankTransactions.Amount, 0) AS BankTransactionAmount,
	|	ISNULL(BankTransactions.Category, VALUE(Catalog.BankTransactionCategories.EmptyRef)) AS BankTransactionCategory
	|FROM
	|	UnreconciledTransactions AS UnreconciledTransactions
	|		LEFT JOIN InformationRegister.BankTransactions AS BankTransactions
	|		ON UnreconciledTransactions.Ref = BankTransactions.Document
	|			AND (BankTransactions.BankAccount.AccountingAccount = &BankAccount)
	|			 )AS AllTransactions
	|
	|ORDER BY
	|	AllTransactions.GroupLabel, AllTransactions.Date
	|	TOTALS SUM(Amount) BY AllTransactions.GroupLabel
	|	");
	
	Doc = CommandParameter[0].Ref;
	Query.SetParameter("Ref",Doc);
	Query.SetParameter("BoundaryEndOfStatementDate", New Boundary(EndOfDay(Doc.Date), BoundaryType.Including));
	Query.SetParameter("BoundaryEndOfStatementDateExcluded", New Boundary(EndOfDay(Doc.Date), BoundaryType.Excluding));
	Query.SetParameter("EndOfStatementDate", EndOfDay(Doc.Date));
	Query.SetParameter("BankAccount", Doc.BankAccount);
	Query.SetParameter("ThisDocument", Doc.Ref);
	
	QResult = Query.Execute().Unload(QueryResultIteration.ByGroups);	
	
    Template = GetTemplate("ReconciliationReport"); 
	
	Header = Template.GetArea("Header");
	CnPClearedHeader = Template.GetArea("CnPClearedHeader");
	DnCrClearedHeader = Template.GetArea("DnCrClearedHeader");
	CnPUnclearedHeaderOn = Template.GetArea("CnPUnclearedHeaderOn");
	DnCrUnclearedHeaderOn = Template.GetArea("DnCrUnclearedHeaderOn");
	
	DetailHeader = Template.GetArea("DetailHeader");
	DetailString = Template.GetArea("DetailString");
	DetailTotal = Template.GetArea("Total");
	UnclearedBefore = 0;
	BalanceBefore = 0;
	UnclearedAfter = 0;
	BalanceAfter = 0;
	CheckAndPayments = 0;
	DepositsAndCredits = 0;
	For Each TabRow In QResult.Rows Do 
		If TabRow.GroupLabel = 1 Then 
			CheckAndPayments = TabRow.Amount;
		ElsIf TabRow.GroupLabel = 2 Then 
			DepositsAndCredits = TabRow.Amount;
		ElsIf TabRow.GroupLabel = 3 Then 
			UnclearedBefore = UnclearedBefore + TabRow.Amount;
		ElsIf TabRow.GroupLabel = 4 Then 	
			UnclearedBefore = UnclearedBefore + TabRow.Amount;
		EndIf;
	EndDo;	
	
	Header.Parameters.CompanyName = Constants.SystemTitle.Get();
	Header.Parameters.AccountName = Doc.BankAccount;
	Header.Parameters.Date = Format(Doc.Date, "DF=MM/dd/yyyy");
	Header.Parameters.BeginBalance = Format(Doc.BeginningBalance, "NFD=2; NZ=0");
	Header.Parameters.EndingBalance = Format(Doc.EndingBalance, "NFD=2; NZ=0");
	Header.Parameters.CheckAndPayments =CheckAndPayments;
	Header.Parameters.DepositsAndCredits = DepositsAndCredits;
	Header.Parameters.UnclearedBefore = UnclearedBefore;
	
	Result.Join(Header);	
	For Each TabRow In QResult.Rows Do 
		If TabRow.GroupLabel = 1 Then 
			Result.Join(CnPClearedHeader);
		ElsIf TabRow.GroupLabel = 2 Then 
			Result.Join(DnCrClearedHeader);
		ElsIf TabRow.GroupLabel = 3 Then 
			CnPUnclearedHeaderOn.Parameters.date = Format(Doc.Date, "DF=MM/dd/yyyy");
			Result.Join(CnPUnclearedHeaderOn);
		ElsIf TabRow.GroupLabel = 4 Then 	
			DnCrUnclearedHeaderOn.Parameters.date = Format(Doc.Date, "DF=MM/dd/yyyy");
			Result.Join(DnCrUnclearedHeaderOn);
		Else
			
		EndIf;	
		Result.Join(DetailHeader);
		For Each DetailRow in TabRow.Rows Do 
			DetailString.Parameters.DateDoc = Format(DetailRow.Date, "DF=MM/dd/yyyy"); 
			DetailString.Parameters.Type = DetailRow.DocType;
			DetailString.Parameters.Num = DetailRow.DocNumber;
			DetailString.Parameters.Name = DetailRow.Company;
			DetailString.Parameters.Sum = DetailRow.Amount;
			Result.Join(DetailString);
		EndDo;
		DetailTotal.Parameters.sum = TabRow.Amount;
		Result.Join(DetailTotal);
	EndDo;	
	
EndProcedure

