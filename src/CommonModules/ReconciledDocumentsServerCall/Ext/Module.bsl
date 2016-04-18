
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
	
	//Do not check Bank Reconciliation document
	If DocumentName = "BankReconciliation" Then
		return;
	EndIf;
	
	If DocumentRequiresExcludingFromBankReconciliation(Source, WriteMode) Then
		MessageText = String(Source.Ref) + ": " + NStr("en='This document is already included in a bank reconciliation. Please remove it from the bank rec first.'");
		CommonUseClientServer.MessageToUser(MessageText,,,,Cancel);
	EndIf;
	
EndProcedure

// Returns value table containing reconciliation data, depending on the document type
// 
// Parameters:
//  Object - DocumentObject - Document being checked
// Returns:
//  ValueTable
//    BankAccount 	- ChartOfAccountsRef.ChartOfAccounts
//    Date			- Date
//    Amount 		- Number(17,2)
//
Function GetDataForReconciliation(Object) Export
	
	If TypeOf(Object) = Type("FormDataStructure") Then
		DocumentName = Object.Ref.Metadata().Name;
	Else
		DocumentName = Object.Metadata().Name;
	EndIf;
	
	DataForReconciliation 	= new ValueTable();
	AmountQualifier			= new NumberQualifiers(17,2);
	DataForReconciliation.Columns.Add("BankAccount", New TypeDescription("ChartOfAccountsRef.ChartOfAccounts"));
	DataForReconciliation.Columns.Add("Date", New TypeDescription("Date"));
	DataForReconciliation.Columns.Add("Amount", New TypeDescription("Number", AmountQualifier));

	If DocumentName = "BankTransfer" Then
		NewRow = DataForReconciliation.Add();
		NewRow.BankAccount 	= Object.AccountTo;
		NewRow.Date 		= Object.Date;
		NewRow.Amount 		= Object.Amount;
		NewRow = DataForReconciliation.Add();
		NewRow.BankAccount 	= Object.AccountFrom;
		NewRow.Date 		= Object.Date;
		NewRow.Amount 		= -1 * Object.Amount;
	ElsIf DocumentName = "CashReceipt" Then
		NewRow = DataForReconciliation.Add();
		NewRow.BankAccount 	= Object.BankAccount;
		NewRow.Date 		= Object.Date;
		NewRow.Amount 		= Object.CashPayment;
	ElsIf DocumentName = "CashSale" Then
		NewRow = DataForReconciliation.Add();
		NewRow.BankAccount 	= Object.BankAccount;
		NewRow.Date 		= Object.Date;
		NewRow.Amount 		= Object.DocumentTotalRC;
	ElsIf DocumentName = "Check" Then
		NewRow = DataForReconciliation.Add();
		NewRow.BankAccount 	= Object.BankAccount;
		NewRow.Date 		= Object.Date;
		NewRow.Amount 		= -1 * Object.DocumentTotalRC;
		
		//Add line items
		LineItemsGroupped = Object.LineItems.Unload(, "Account, Amount");
		LineItemsGroupped.GroupBy("Account", "Amount");
		For Each Row In LineItemsGroupped Do
			If (Row.Account.AccountType = Enums.AccountTypes.Bank) 
				OR (Row.Account.AccountType = Enums.AccountTypes.OtherCurrentLiability And Row.Account.CreditCard = True) Then
				NewRow = DataForReconciliation.Add();
				NewRow.BankAccount 	= Row.Account;
				NewRow.Date 		= Object.Date;
				NewRow.Amount 		= Row.Amount;
			EndIf;
		EndDo;

	ElsIf DocumentName = "Deposit" Then
		NewRow = DataForReconciliation.Add();
		NewRow.BankAccount 	= Object.BankAccount;
		NewRow.Date 		= Object.Date;
		NewRow.Amount 		= Object.DocumentTotalRC;
		
		//Add line items
		LineItemsGroupped = Object.Accounts.Unload(, "Account, Amount");
		LineItemsGroupped.GroupBy("Account", "Amount");
		For Each Row In LineItemsGroupped Do
			If (Row.Account.AccountType = Enums.AccountTypes.Bank) 
				OR (Row.Account.AccountType = Enums.AccountTypes.OtherCurrentLiability And Row.Account.CreditCard = True) Then
				NewRow = DataForReconciliation.Add();
				NewRow.BankAccount 	= Row.Account;
				NewRow.Date 		= Object.Date;
				NewRow.Amount 		= -1 * Row.Amount;
			EndIf;
		EndDo;

	ElsIf DocumentName = "InvoicePayment" Then
		NewRow = DataForReconciliation.Add();
		NewRow.BankAccount 	= Object.BankAccount;
		NewRow.Date 		= Object.Date;
		NewRow.Amount 		= -1 * Object.DocumentTotalRC;
	ElsIf DocumentName = "GeneralJournalEntry" Then
		LineItemsGroupped = Object.LineItems.Unload(, "Account, AmountDr, AmountCr");
		LineItemsGroupped.GroupBy("Account", "AmountDr, AmountCr");
		For Each BankRow In LineItemsGroupped Do
			If (BankRow.Account.AccountType = Enums.AccountTypes.Bank)
				OR (BankRow.Account.AccountType = Enums.AccountTypes.OtherCurrentLiability And BankRow.Account.CreditCard = True) Then
				NewRow = DataForReconciliation.Add();
				NewRow.BankAccount 	= BankRow.Account;
				NewRow.Date 		= Object.Date;
				NewRow.Amount 		= BankRow.AmountDr-BankRow.AmountCr;
			EndIf;
		EndDo; 
	EndIf;
	
	return DataForReconciliation;

EndFunction

// Defines whether the document is required to be excluded from bank rec. document
// Should be excluded in the following cases:
//  1. amount differs from what is in the database
//  2. bank account differs from what is in the database
//  3. date exceeds the period of bank reconciliation document
// Parameters:
//  Object - DocumentObject - Document being checked
//  WriteMode - DocumentWriteMode - current write mode
//
Function DocumentRequiresExcludingFromBankReconciliation(Val Object, Val WriteMode) Export
	
	If WriteMode = DocumentWriteMode.Posting Then
		DataForReconciliation = GetDataForReconciliation(Object);
		SetPrivilegedMode(True);
		Query = New Query("SELECT
		                  |	DocumentData.BankAccount,
		                  |	DocumentData.Date,
		                  |	DocumentData.Amount
		                  |INTO DocumentData
		                  |FROM
		                  |	&DocumentData AS DocumentData
		                  |;
		                  |
		                  |////////////////////////////////////////////////////////////////////////////////
		                  |SELECT
		                  |	BankReconciliation.Document,
		                  |	BankReconciliation.Document.Date,
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
		                  |	ReconciledValues.StatementToDate
		                  |FROM
		                  |	ReconciledValues AS ReconciledValues
		                  |		LEFT JOIN DocumentData AS DocumentData
		                  |		ON ReconciledValues.Account = DocumentData.BankAccount
		                  |			AND ReconciledValues.Amount = DocumentData.Amount
		                  |			AND (ENDOFPERIOD(ReconciledValues.StatementToDate, DAY) >= ENDOFPERIOD(DocumentData.Date, DAY))
		                  |			AND (BEGINOFPERIOD(ReconciledValues.DocumentDate, MONTH) = BEGINOFPERIOD(DocumentData.Date, MONTH))
		                  |WHERE
		                  |	DocumentData.BankAccount IS NULL ");
		Query.SetParameter("Ref", Object.Ref);
		Query.SetParameter("DocumentData", DataForReconciliation);
				
	    Selection = Query.Execute();
	
		SetPrivilegedMode(False);
	
		If NOT Selection.IsEmpty() Then
			return True;
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
		Query.SetParameter("Ref", Object.Ref);
		
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

// Posts the document to the General journal analytics (dimensions) accumulation register
// Parameters:
//  RegisterRecords                 - RegisterRecordsCollection - Document postings list, containing GeneralJournalAnalyticsDimensions register records
//  CurrentAccountingRegisterRecord - AccountingRegisterRecord - Current General journal record
//  Class                           - CatalogRef.Classes - Class of record
//  Project                         - CatalogRef.Projects - Project of record 
Procedure AddRecordForGeneralJournalAnalyticsDimensions(RegisterRecords, CurrentAccountingRegisterRecord, Class, Project, Company) Export
	
	If Not RegisterRecords.GeneralJournalAnalyticsDimensions.Write Then
		RegisterRecords.GeneralJournalAnalyticsDimensions.Write = True;
	EndIf;
	
	If CurrentAccountingRegisterRecord.RecordType = AccountingRecordType.Debit Then
		Record = RegisterRecords.GeneralJournalAnalyticsDimensions.AddReceipt();
	Else
		Record = RegisterRecords.GeneralJournalAnalyticsDimensions.AddExpense();
	EndIf;
	
	Record.Account  = CurrentAccountingRegisterRecord.Account;
	Record.Company  = Company;
	Record.Period   = CurrentAccountingRegisterRecord.Period;
	Record.Class    = Class;
	Record.Project	= Project;
	Record.AmountRC = CurrentAccountingRegisterRecord.AmountRC;
		
EndProcedure
