// The procedure posts interest earned and bank service charge transactions.
// Also posting cleared transactions on BankReconciliation register
Procedure Posting(Cancel, Mode)
	
	//RegisterRecords.GeneralJournal.Write = True;
	//
	//If (InterestEarned <> 0) Then
	//	Record = RegisterRecords.GeneralJournal.AddDebit();
	//	Record.Account = BankAccount;
	//	Record.Period = InterestEarnedDate;
	//	Record.AmountRC = InterestEarned;

	//	Record = RegisterRecords.GeneralJournal.AddCredit();
	//	Record.Account = BankInterestEarnedAccount;
	//	Record.Period = InterestEarnedDate;
	//	Record.AmountRC = InterestEarned;
	//EndIf;
	//
	//If (ServiceCharge <> 0) Then
	//	Record = RegisterRecords.GeneralJournal.AddCredit();
	//	Record.Account = BankAccount;
	//	Record.Period = ServiceChargeDate;
	//	Record.AmountRC = ServiceCharge;

	//	Record = RegisterRecords.GeneralJournal.AddDebit();
	//	Record.Account = BankServiceChargeAccount;
	//	Record.Period = ServiceChargeDate;
	//	Record.AmountRC = ServiceCharge;
	//EndIf;
	
	//Bank reconciliation data
	//Apply data lock
	DataLocks = New DataLock;
	
	// Set data lock parameters.
	LockItem = DataLocks.Add("AccumulationRegister.BankReconciliation");
	LockItem.Mode = DataLockMode.Exclusive;
	LockItem.SetValue("Account", BankAccount);
	LockItem.DataSource = LineItems;
	LockItem.UseFromDataSource("Document", "Transaction");
	DataLocks.Lock();
	
	//Perform data check
	Query = New Query("SELECT
	                  |	TransactionsForReconciliation.Ref AS Ref,
	                  |	TransactionsForReconciliation.Date AS Date,
	                  |	TransactionsForReconciliation.Company,
	                  |	TransactionsForReconciliation.Number,
	                  |	SUM(TransactionsForReconciliation.Amount) AS Amount
	                  |INTO UnreconciledTransactions
	                  |FROM
	                  |	(SELECT
	                  |		BankReconciliationBalance.Document AS Ref,
	                  |		BankReconciliationBalance.Document.Date AS Date,
	                  |		BankReconciliationBalance.Document.Company AS Company,
	                  |		BankReconciliationBalance.Document.Number AS Number,
	                  |		BankReconciliationBalance.AmountBalance AS Amount
	                  |	FROM
	                  |		AccumulationRegister.BankReconciliation.Balance(, Account = &BankAccount) AS BankReconciliationBalance
	                  |	WHERE
	                  |		BankReconciliationBalance.Document.Date <= &EndOfStatementDate
	                  |	
	                  |	UNION ALL
	                  |	
	                  |	SELECT
	                  |		BankReconciliation.Document,
	                  |		BankReconciliation.Document.Date,
	                  |		BankReconciliation.Document.Company,
	                  |		BankReconciliation.Document.Number,
	                  |		BankReconciliation.Amount
	                  |	FROM
	                  |		AccumulationRegister.BankReconciliation AS BankReconciliation
	                  |	WHERE
	                  |		BankReconciliation.Recorder = &ThisDocument
	                  |		AND BankReconciliation.Active = TRUE
	                  |		AND BankReconciliation.Document.Date <= &EndOfStatementDate
	                  |		AND BankReconciliation.Account = &BankAccount) AS TransactionsForReconciliation
	                  |
	                  |GROUP BY
	                  |	TransactionsForReconciliation.Ref,
	                  |	TransactionsForReconciliation.Date,
	                  |	TransactionsForReconciliation.Company,
	                  |	TransactionsForReconciliation.Number
	                  |
	                  |INDEX BY
	                  |	Ref,
	                  |	Date
	                  |;
	                  |
	                  |////////////////////////////////////////////////////////////////////////////////
	                  |SELECT
	                  |	LineItems.LineNumber,
	                  |	LineItems.Document,
	                  |	LineItems.Document.Presentation,
	                  |	LineItems.Amount,
	                  |	CASE
	                  |		WHEN LineItems.Amount >= 0
	                  |			THEN CASE
	                  |					WHEN LineItems.Amount <= ISNULL(UnreconciledTransactions.Amount, 0)
	                  |						THEN TRUE
	                  |					ELSE FALSE
	                  |				END
	                  |		ELSE CASE
	                  |				WHEN LineItems.Amount >= ISNULL(UnreconciledTransactions.Amount, 0)
	                  |					THEN TRUE
	                  |				ELSE FALSE
	                  |			END
	                  |	END AS AmountCheck,
	                  |	ISNULL(UnreconciledTransactions.Amount, 0) AS AvailableAmount
	                  |FROM
	                  |	(SELECT
	                  |		BankReconciliationLineItems.Transaction AS Document,
	                  |		SUM(BankReconciliationLineItems.TransactionAmount) AS Amount,
	                  |		MIN(BankReconciliationLineItems.LineNumber) AS LineNumber
	                  |	FROM
	                  |		Document.BankReconciliation.LineItems AS BankReconciliationLineItems
	                  |	WHERE
	                  |		BankReconciliationLineItems.Cleared = TRUE
	                  |		AND BankReconciliationLineItems.Ref = &ThisDocument
	                  |	
	                  |	GROUP BY
	                  |		BankReconciliationLineItems.Transaction) AS LineItems
	                  |		LEFT JOIN UnreconciledTransactions AS UnreconciledTransactions
	                  |		ON LineItems.Document = UnreconciledTransactions.Ref
	                  |			AND (UnreconciledTransactions.Date <= &EndOfStatementDate)
	                  |WHERE
	                  |	(UnreconciledTransactions.Amount IS NULL 
	                  |			OR CASE
	                  |				WHEN LineItems.Amount >= 0
	                  |					THEN CASE
	                  |							WHEN LineItems.Amount <= ISNULL(UnreconciledTransactions.Amount, 0)
	                  |								THEN TRUE
	                  |							ELSE FALSE
	                  |						END
	                  |				ELSE CASE
	                  |						WHEN LineItems.Amount >= ISNULL(UnreconciledTransactions.Amount, 0)
	                  |							THEN TRUE
	                  |						ELSE FALSE
	                  |					END
	                  |			END = FALSE)");
						  
	Query.SetParameter("BoundaryEndOfStatementDate", New Boundary(EndOfDay(Date), BoundaryType.Including));
	Query.SetParameter("EndOfStatementDate", EndOfDay(Date));
	Query.SetParameter("BankAccount", BankAccount);
	Query.SetParameter("ThisDocument", Ref);
	
	Result = Query.Execute().Select();
	While Result.Next() Do
		//Data check failed. Cancel posting.
		Cancel = True;
		//Show message to the user
		RowNumber = Result.LineNumber;
		Message = New UserMessage();
		Message.Text=NStr("en = '" + Result.DocumentPresentation + ". Current amount " + Format(Result.Amount, "NFD=2; NZ=") + " exceeds the amount, available for reconciliation " + Format(Result.AvailableAmount, "NFD=2; NZ=") + "." + Chars.LF + "Please, use the Refresh button to update the tabular section!'");
		If (Result.Amount < 0) Then
			Message.Field = "LineItems[" + String(RowNumber-1) + "].Payment";
		Else
			Message.Field = "LineItems[" + String(RowNumber-1) + "].Deposit";
		EndIf;
		Message.Message();

	EndDo;
	If Cancel Then
		return;
	EndIf;
	
	//Generating bank reconciliation register records
	RegisterRecords.BankReconciliation.Write = True;
	For Each LineItem In LineItems Do
		If Not LineItem.Cleared Then
			Continue;
		EndIf;
		Record = RegisterRecords.BankReconciliation.AddExpense();
		Record.Period 	= EndOfDay(Date);
		Record.Account 	= BankAccount;
		Record.Document = LineItem.Transaction;
		Record.Amount 	= LineItem.TransactionAmount;
	EndDo;

EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		return;
	EndIf;
	
	//Shouldn't allow creating multiple bank reconciliation documents for the same account in the same period
	//Apply data lock
	DataLocks = New DataLock;

	// Set data lock parameters.
	LockItem = DataLocks.Add("Document.BankReconciliation");
	LockItem.Mode = DataLockMode.Exclusive;
	DataLocks.Lock();
	
	Request = new Query("SELECT
	                    |	BankReconciliation.Ref
	                    |FROM
	                    |	Document.BankReconciliation AS BankReconciliation
	                    |WHERE
	                    |	BankReconciliation.Date >= BEGINOFPERIOD(&Date, MONTH)
	                    |	AND BankReconciliation.Date <= ENDOFPERIOD(&Date, MONTH)
	                    |	AND BankReconciliation.BankAccount = &BankAccount
	                    |	AND BankReconciliation.Ref <> &Ref");
	Request.SetParameter("BankAccount", BankAccount);
	Request.SetParameter("Date", Date);
	Request.SetParameter("Ref", Ref);
	Res = Request.Execute();
	If Not Res.IsEmpty() Then
		Cancel = True;
		MessageText = NStr("en = 'Document can not be written. Another bank reconciliation document is found in the database for the bank account: " + String(BankAccount) + " and period: " + Format(Date, "DF='MMMM, yyyy'") + ".'");
		CommonUseClientServer.MessageToUser(MessageText);
	EndIf;

EndProcedure

Procedure BeforeDelete(Cancel)
	
	//Allow deletion only if there are no documents in Process Month for the period
	//If IsInRole("BankAccounting") Then
	//	Request = New Query("SELECT ALLOWED
	//	                    |	GeneralJournalBalanceAndTurnovers.Recorder AS Recorder,
	//	                    |	GeneralJournalBalanceAndTurnovers.Period AS Period,
	//	                    |	GeneralJournalBalanceAndTurnovers.AmountRCClosingBalance,
	//	                    |	GeneralJournalBalanceAndTurnovers.Recorder.PointInTime AS RecorderPointInTime,
	//	                    |	GeneralJournalBalanceAndTurnovers.AmountRCOpeningBalance
	//	                    |FROM
	//	                    |	AccountingRegister.GeneralJournal.BalanceAndTurnovers(&DateStart, &DateEnd, Recorder, , Account = &Account, , ) AS GeneralJournalBalanceAndTurnovers
	//	                    |WHERE
	//	                    |	NOT GeneralJournalBalanceAndTurnovers.Recorder IS NULL 
	//	                    |	AND GeneralJournalBalanceAndTurnovers.Recorder <> UNDEFINED
	//	                    |	AND NOT GeneralJournalBalanceAndTurnovers.Recorder REFS Document.GeneralJournalEntry");
	//	DateStart 	= BegOfMonth(Date);
	//	DateEnd		= EndOfMonth(Date);
	//	Request.SetParameter("Account", BankAccount);
	//	Request.SetParameter("DateStart", New Boundary(DateStart, BoundaryType.Including));
	//	Request.SetParameter("DateEnd", New Boundary(EndOfDay(DateEnd), BoundaryType.Including));
	//	Res = Request.Execute();
	//	If Not Res.IsEmpty() Then
	//		Cancel = True;
	//		MessageText = NStr("en='" + String(Ref) + ": document is not empty and is used in Process Month. Document deletion cancelled.'");
	//		CommonUseClientServer.MessageToUser(MessageText);
	//	EndIf;
	//EndIf;
	
EndProcedure


