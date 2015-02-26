&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	TRUE AS UseAccount,
		|	ChartOfAccounts.Ref AS Account,
		|	DATETIME(1, 1, 1) AS BeginningDate,
		|	0 AS BeginningBalance,
		|	FALSE AS Used
		|FROM
		|	ChartOfAccounts.ChartOfAccounts AS ChartOfAccounts
		|WHERE
		|	(ChartOfAccounts.AccountType = VALUE(Enum.AccountTypes.Bank)
		|			OR ChartOfAccounts.AccountType = VALUE(Enum.AccountTypes.OtherCurrentLiability)
		|				AND ChartOfAccounts.CreditCard = TRUE)";

	ValueToFormData(Query.Execute().Unload(), Accounts);
	
EndProcedure

&AtClient
Procedure Reconciliation(Command)
	
	ReconciliationAtServer();
	Message("Ok!");
	
EndProcedure

&AtServer
Procedure ReconciliationAtServer()
	
	//
	Query = New Query;
    TTM = New TempTablesManager;
    Query.TempTablesManager = TTM;
	
	Query.Text = "SELECT
	             |	Accounts.Account AS Account,
	             |	Accounts.BeginningDate AS BeginningDate
	             |INTO Accounts
	             |FROM
	             |	&Accounts AS Accounts
	             |WHERE
	             |	Accounts.UseAccount = TRUE
	             |;
	             |
	             |////////////////////////////////////////////////////////////////////////////////
	             |SELECT
	             |	BankReconciliationBalance.Account AS Account,
	             |	BankReconciliationBalance.Document AS Document,
	             |	BEGINOFPERIOD(BankReconciliationBalance.Document.Date, MONTH) AS DocumentMonth,
	             |	BankReconciliationBalance.AmountBalance AS AmountBalance
	             |INTO BankReconciliationBalance
	             |FROM
	             |	AccumulationRegister.BankReconciliation.Balance(
	             |			,
	             |			Account IN
	             |					(SELECT
	             |						Accounts.Account
	             |					FROM
	             |						Accounts AS Accounts)
	             |				AND (Account.AccountType = VALUE(Enum.AccountTypes.Bank)
	             |					OR Account.AccountType = VALUE(Enum.AccountTypes.OtherCurrentLiability)
	             |						AND Account.CreditCard = TRUE)
	             |				AND CASE
	             |					WHEN Document REFS Document.GeneralJournalEntry
	             |							AND Document.Adjusting = TRUE
	             |						THEN FALSE
	             |					ELSE TRUE
	             |				END) AS BankReconciliationBalance
	             |;
	             |
	             |////////////////////////////////////////////////////////////////////////////////
	             |SELECT
	             |	BankReconciliationBalance.Account AS Account,
	             |	BankReconciliationBalance.Document,
	             |	BankReconciliationBalance.DocumentMonth AS DocumentMonth,
	             |	BankReconciliationBalance.AmountBalance
	             |FROM
	             |	Accounts AS Accounts
	             |		INNER JOIN BankReconciliationBalance AS BankReconciliationBalance
	             |		ON Accounts.Account = BankReconciliationBalance.Account
	             |			AND Accounts.BeginningDate <= BankReconciliationBalance.DocumentMonth
	             |
	             |ORDER BY
	             |	Account,
	             |	DocumentMonth";

	//			 
	Query.SetParameter("Accounts", Accounts.Unload());
	
	QueryResult = Query.Execute();
	
	SDR = QueryResult.Select();
	
	FirstRow       = True;
	NewDoc         = Undefined;
	CurrentAccount = Undefined;
	CurrentMonth   = Undefined;
	
	While SDR.Next() Do
		
		If SDR.Account <> CurrentAccount OR SDR.DocumentMonth <> CurrentMonth Then
			
			//
			If Not FirstRow Then
				
				NewDoc.ClearedAmount  = NewDoc.LineItems.Total("TransactionAmount");
				NewDoc.ClearedBalance = NewDoc.BeginningBalance + NewDoc.ClearedAmount;
				NewDoc.Difference     = 0;
				NewDoc.EndingBalance  = NewDoc.ClearedBalance;
				NewDoc.Memo           = "<auto>";
				
				NewDoc.Write(DocumentWriteMode.Posting);
				
			EndIf;
			
			//
			CurrentAccount = SDR.Account;
			CurrentMonth   = SDR.DocumentMonth;
			
			//
			NewDoc = Documents.BankReconciliation.CreateDocument();
			NewDoc.Date             = EndOfMonth(CurrentMonth);
			NewDoc.BankAccount      = CurrentAccount;
			NewDoc.BeginningBalance = GetBeginningBalance(NewDoc);
			
			NewRow = NewDoc.LineItems.Add();
			NewRow.Transaction       = SDR.Document;
			NewRow.TransactionAmount = SDR.AmountBalance;
			NewRow.Cleared           = True;
			
			FirstRow = False
			
		Else
			
			//
			NewRow = NewDoc.LineItems.Add();
			NewRow.Transaction       = SDR.Document;
			NewRow.TransactionAmount = SDR.AmountBalance;
			NewRow.Cleared           = True;
			
		EndIf;
		
	EndDo;
	
	//
	If Not FirstRow Then
		
		NewDoc.ClearedAmount  = NewDoc.LineItems.Total("TransactionAmount");
		NewDoc.ClearedBalance = NewDoc.BeginningBalance + NewDoc.ClearedAmount;
		NewDoc.Difference     = 0;
		NewDoc.EndingBalance  = NewDoc.ClearedBalance;
		NewDoc.Memo           = "<auto>";
		
		NewDoc.Write(DocumentWriteMode.Posting);
		
	EndIf;
	
EndProcedure

&AtServer
Function GetBeginningBalance(Doc)
	
	BeginningBalance = 0;	
	
	Array = Accounts.FindRows(New Structure("Account, Used", Doc.BankAccount, False));
	
	For Each ArrayRow In Array Do
		
		ArrayRow.Used = True;
		
		BeginningBalance =  ArrayRow.BeginningBalance;
		
		Return BeginningBalance;
		
	EndDo;
	
	Request = New Query("SELECT TOP 1
	                    |	BankReconciliation.Date AS Date,
	                    |	BankReconciliation.EndingBalance
	                    |FROM
	                    |	Document.BankReconciliation AS BankReconciliation
	                    |WHERE
	                    |	BankReconciliation.DeletionMark = FALSE
	                    |	AND BankReconciliation.Posted = TRUE
	                    |	AND BankReconciliation.BankAccount = &BankAccount
	                    |	AND BankReconciliation.Date <= &Date
	                    |	AND BankReconciliation.Ref <> &Ref
	                    |
	                    |ORDER BY
	                    |	BankReconciliation.PointInTime DESC");
	
	Request.SetParameter("BankAccount", Doc.BankAccount);
	Request.SetParameter("Date", Doc.Date);
	Request.SetParameter("Ref", Doc.Ref);
	
	SDR = Request.Execute().Select();
	While SDR.Next() Do
		BeginningBalance = SDR.EndingBalance;
	EndDo;
	
	Return BeginningBalance;
	
EndFunction
