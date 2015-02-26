
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
	
	//If IsInRole("BankAccounting") Then
	//	If Source.AdditionalProperties.Property("CFO_ProcessMonth_AllowWrite") Then
	//		return;
	//	EndIf;
	//	If DocumentName = "BankReconciliation" Then
	//		If Source.Ref.IsEmpty() Then
	//			MessageText = NStr("en='Bank Reconciliation document is not intended to be created by a user. Document is not written.'");
	//		Else
	//			MessageText = String(Source.Ref) + ": " + NStr("en='This document is not intended to be changed by a user. Document is not written.'");
	//		EndIf;
	//		CommonUseClientServer.MessageToUser(MessageText,,,,Cancel);  
	//	Else //For all other document types
	//		//If TransactionIsAccepted(Source.Ref) Then
	//		If Source.Ref.IsEmpty() Then
	//			MessageText = NStr("en='" + Source.Metadata().Synonym + " document is intended to be changed from the Process Month interface. Document is not written.'");
	//		Else
	//			MessageText = String(Source.Ref) + ": " + NStr("en='This document is intended to be changed from the Process Month interface. Document is not written.'");
	//		EndIf;
	//		CommonUseClientServer.MessageToUser(MessageText,,,,Cancel);  
	//		//EndIf;
	//	EndIf;
	//EndIf;
	
	//Do not check Bank Reconciliation document
	If DocumentName = "BankReconciliation" Then
		return;
	EndIf;
	
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
		                  |	BankReconciliation.Document,
		                  |	MIN(BankReconciliation.Account) AS Account,
		                  |	SUM(BankReconciliation.Amount) AS Amount,
		                  |	MIN(BankReconciliation.Period) AS StatementToDate
		                  |INTO ReconciledValues
		                  |FROM
		                  |	AccumulationRegister.BankReconciliation AS BankReconciliation
		                  |WHERE
		                  |	BankReconciliation.Document = &Ref
		                  |	AND BankReconciliation.RecordType = VALUE(AccumulationRecordType.Expense)
		                  |	AND BankReconciliation.Active = TRUE
		                  |
		                  |GROUP BY
		                  |	BankReconciliation.Document
		                  |;
		                  |
		                  |////////////////////////////////////////////////////////////////////////////////
		                  |SELECT
		                  |	ReconciledValues.Document,
		                  |	ReconciledValues.Account,
		                  |	ReconciledValues.Amount,
		                  |	ReconciledValues.StatementToDate,
		                  |	CASE
		                  |		WHEN ReconciledValues.Amount <> &NewAmount
		                  |				OR ENDOFPERIOD(ReconciledValues.StatementToDate, DAY) < &NewDate
		                  |				OR ReconciledValues.Account <> &NewAccount
		                  |			THEN TRUE
		                  |		ELSE FALSE
		                  |	END AS RequiresExcluding
		                  |FROM
		                  |	ReconciledValues AS ReconciledValues");
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
		                  |	BankReconciliation.Document
		                  |FROM
		                  |	AccumulationRegister.BankReconciliation AS BankReconciliation
		                  |WHERE
		                  |	BankReconciliation.Document = &Ref
		                  |	AND BankReconciliation.RecordType = VALUE(AccumulationRecordType.Expense)
		                  |	AND BankReconciliation.Active = TRUE");
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

// Posts the document to the Bank Reconciliation accumulation register
// Parameters:
//  RegisterRecords - RegisterRecordsCollection - Document postings list, containing BankReconciliation register records.
//  DocumentRef     - DocumentRef - Reference of the document being posted
//  Account         - ChartOfAccountsRef.ChartOfAccounts - G/L bank account 
//  Amount          - Amount, being posted to the reconciliation register. Influences G/L bank account balance
Procedure AddDocumentForReconciliation(RegisterRecords, DocumentRef, Account, Date, Amount) Export
	If Not RegisterRecords.BankReconciliation.Write Then
		RegisterRecords.BankReconciliation.Write = True;
	EndIf;
	Record = RegisterRecords.BankReconciliation.AddReceipt();
	Record.Period 	= Date;
	Record.Recorder = DocumentRef;
	Record.Account 	= Account;
	Record.Document = DocumentRef;
	Record.Amount 	= Amount;
EndProcedure
