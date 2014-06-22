// The procedure posts interest earned and bank service charge transactions.
// Also posting cleared transactions on BankReconciliation register
Procedure Posting(Cancel, Mode)
	If ServiceCharge > 0 Then
		
		If BankServiceChargeAccount.AccountType = Enums.AccountTypes.CostOfSales OR
		   BankServiceChargeAccount.AccountType = Enums.AccountTypes.Expense OR
		   BankServiceChargeAccount.AccountType = Enums.AccountTypes.OtherExpense OR
		   BankServiceChargeAccount.AccountType = Enums.AccountTypes.IncomeTaxExpense Then
		   
		   		Record = RegisterRecords.CashFlowData.Add();
				Record.RecordType = AccumulationRecordType.Receipt;
				Record.Period = Date;
				Record.Document = Ref;
				Record.Account = BankServiceChargeAccount;
				Record.AmountRC = ServiceCharge;
				
				Record = RegisterRecords.CashFlowData.Add();
				Record.RecordType = AccumulationRecordType.Expense;
				Record.Period = Date;
				Record.Document = Ref;
				Record.Account = BankServiceChargeAccount;
				Record.AmountRC = ServiceCharge;
		   
		EndIf;

		
	EndIf;
	
	If InterestEarned > 0 Then
		
		If BankInterestEarnedAccount.AccountType = Enums.AccountTypes.Income OR
		   BankInterestEarnedAccount.AccountType = Enums.AccountTypes.OtherIncome Then
		   
		   		Record = RegisterRecords.CashFlowData.Add();
				Record.RecordType = AccumulationRecordType.Expense;
				Record.Period = Date;
				Record.Document = Ref;
				Record.Account = BankInterestEarnedAccount;
				Record.AmountRC = InterestEarned;
				
				Record = RegisterRecords.CashFlowData.Add();
				Record.RecordType = AccumulationRecordType.Receipt;
				Record.Period = Date;
				Record.Document = Ref;
				Record.Account = BankInterestEarnedAccount;
				Record.AmountRC = InterestEarned;
	   
		EndIf;

	EndIf;
	
	RegisterRecords.GeneralJournal.Write = True;
	
	If (InterestEarned <> 0) Then
		Record = RegisterRecords.GeneralJournal.AddDebit();
		Record.Account = BankAccount;
		Record.Period = InterestEarnedDate;
		Record.AmountRC = InterestEarned;

		Record = RegisterRecords.GeneralJournal.AddCredit();
		Record.Account = BankInterestEarnedAccount;
		Record.Period = InterestEarnedDate;
		Record.AmountRC = InterestEarned;
	EndIf;
	
	If (ServiceCharge <> 0) Then
		Record = RegisterRecords.GeneralJournal.AddCredit();
		Record.Account = BankAccount;
		Record.Period = ServiceChargeDate;
		Record.AmountRC = ServiceCharge;

		Record = RegisterRecords.GeneralJournal.AddDebit();
		Record.Account = BankServiceChargeAccount;
		Record.Period = ServiceChargeDate;
		Record.AmountRC = ServiceCharge;
	EndIf;
	
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
		Message.Text=NStr("en = 'Current amount " + Format(Result.Amount, "NFD=2; NZ=") + " exceeds the amount, available for reconciliation " + Format(Result.AvailableAmount, "NFD=2; NZ=") + "." + Chars.LF + "Please, use the Refresh button to update the tabular section!'");
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


