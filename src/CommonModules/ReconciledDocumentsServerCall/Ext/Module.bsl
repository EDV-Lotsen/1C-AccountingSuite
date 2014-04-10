
// Event subscribtion handler. Preventing posting if already included in a bank reconciliation document
// Parameters:
//  Source - DocumentObject - Document being posted
//  Cancel - boolean - cancel write 
//  WriteMode - DocumentWriteMode enumeration - current write mode
//  PostingMode - DocumentPostingMode enumeration - current posting mode
//
Procedure ReconciledDocumentBeforeWrite(Source, Cancel, WriteMode, PostingMode) Export
	// allow posting if key fields has not been changed
	If Source.DataExchange.Load Then
		return;
	EndIf;
	DocumentName = Source.Metadata().Name;
	If DocumentName = "BankTransfer" Then
		Amount = Source.Amount;
		Date = Source.Date;
		BankAccount = Source.AccountTo;
	ElsIf DocumentName = "CashReceipt" Then
		Amount = Source.CashPayment;
		Date = Source.Date;
		BankAccount = Source.BankAccount;
	ElsIf DocumentName = "CashSale" Then
		Amount = Source.DocumentTotalRC;
		Date = Source.Date;
		BankAccount = Source.BankAccount;
	ElsIf DocumentName = "Check" Then
		Amount = -1*Source.DocumentTotalRC;
		Date = Source.Date;
		BankAccount = Source.BankAccount;
	ElsIf DocumentName = "Deposit" Then
		Amount = Source.DocumentTotalRC;
		Date = Source.Date;
		BankAccount = Source.BankAccount;
	ElsIf DocumentName = "InvoicePayment" Then
		Amount = -1*Source.DocumentTotalRC;
		Date = Source.Date;
		BankAccount = Source.BankAccount;
	Else
		return;
	EndIf;
	If RequiresExcludingFromBankReconciliation(Source.Ref, Amount, Date, BankAccount, WriteMode) Then
		MessageText = String(Source.Ref) + ": " + NStr("en='This document is already included in a bank reconciliation. Please remove it from the bank rec first.'");
		CommonUseClientServer.MessageToUser(MessageText,,,,Cancel);
	EndIf;
EndProcedure

// Defines whether the document is required to be excluded from bank rec. document
// Should be excluded in the following cases:
//  1. amount differs from what is in the database
//  2. bank account differs from what is in the database
//  3. date exceeds the period of bank reconciliation document
// Parameters:
//  Ref - DocumentRef - Document being checked
//  NewAmount - Number - new amount of the document. 
//  NewDate - Date - new date of the document
//  NewAccount - CatalogRef.BankAccounts - new bank account of the document
//  WriteMode - DocumentWriteMode - current write mode
//
Function RequiresExcludingFromBankReconciliation(Val Ref, Val NewAmount, Val NewDate, Val NewAccount, Val WriteMode) Export
	If WriteMode = DocumentWriteMode.Posting Then
		SetPrivilegedMode(True);
		Query = New Query("SELECT
		                  |	TransactionReconciliation.Document,
		                  |	TransactionReconciliation.Amount,
		                  |	TransactionReconciliation.Account
		                  |INTO ReconciledValues
		                  |FROM
		                  |	InformationRegister.TransactionReconciliation AS TransactionReconciliation
		                  |WHERE
		                  |	TransactionReconciliation.Document = &Ref
		                  |	AND TransactionReconciliation.Reconciled = TRUE
		                  |;
		                  |
		                  |////////////////////////////////////////////////////////////////////////////////
		                  |SELECT
		                  |	ReconciledValues.Document,
		                  |	ReconciledValues.Amount,
		                  |	BankReconciliationLineItems.Ref.StatementToDate,
		                  |	ReconciledValues.Account,
		                  |	CASE
		                  |		WHEN ReconciledValues.Amount <> &NewAmount
		                  |				OR ENDOFPERIOD(BankReconciliationLineItems.Ref.StatementToDate, DAY) < &NewDate
		                  |				OR ReconciledValues.Account <> &NewAccount
		                  |			THEN TRUE
		                  |		ELSE FALSE
		                  |	END AS RequiresExcluding
		                  |FROM
		                  |	ReconciledValues AS ReconciledValues
		                  |		INNER JOIN Document.BankReconciliation.LineItems AS BankReconciliationLineItems
		                  |		ON ReconciledValues.Document = BankReconciliationLineItems.Transaction
		                  |			AND (BankReconciliationLineItems.Cleared = TRUE)
		                  |			AND (BankReconciliationLineItems.Ref.Posted = TRUE)
		                  |			AND (BankReconciliationLineItems.Ref.DeletionMark = FALSE)");
		Query.SetParameter("Ref", Ref);
		Query.SetParameter("NewAmount", NewAmount);
		Query.SetParameter("NewDate", NewDate);
		Query.SetParameter("NewAccount", NewAccount);
		
	    Selection = Query.Execute();
	
		SetPrivilegedMode(False);
	
		If NOT Selection.IsEmpty() Then
			Sel = Selection.Select();
			Sel.Next();
			return Sel.RequiresExcluding;
		Else
			return False;
		EndIf;	
	ElsIf WriteMode = DocumentWriteMode.UndoPosting Then
		SetPrivilegedMode(True);
		
		Query = New Query("SELECT
					  |	TransactionReconciliation.Document
					  |FROM
					  |	InformationRegister.TransactionReconciliation AS TransactionReconciliation
					  |WHERE
					  |	TransactionReconciliation.Document = &Ref
					  |	AND TransactionReconciliation.Reconciled = TRUE");
		Query.SetParameter("Ref", Ref);
		
		Selection = Query.Execute();
		
		SetPrivilegedMode(False);
		
		If NOT Selection.IsEmpty() Then
			return True;
		Else
			return False;
		EndIf;
	Else
		return False;		
	EndIf;
EndFunction