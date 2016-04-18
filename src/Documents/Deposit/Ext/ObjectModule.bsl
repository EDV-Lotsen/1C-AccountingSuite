

// The procedure posts deposit transactions
//
Procedure Posting(Cancel, Mode)
	
	//For Each DocumentLine in LineItems Do
	//	
	//	GeneralFunctions.WriteDepositData(DocumentLine.Document);
	//	
	//EndDo;	
	
	AccountCurrency = CommonUse.GetAttributeValue(BankAccount, "Currency");
	ExchangeRate = GeneralFunctions.GetExchangeRate(Date, AccountCurrency);	
	
	//Clear register records
	For Each RecordSet In RegisterRecords Do
		RecordSet.Read();
		If RecordSet.Count() > 0 Then
			RecordSet.Write = True;
			RecordSet.Clear();
			RecordSet.Write();
		EndIf;
	EndDo;

	//Check whether the amount of payment equals to the amount of the document
	// Create new managed data lock.
	DataLock = New DataLock;
	
	// Set data lock parameters.
	LockItem = DataLock.Add("AccumulationRegister.UndepositedDocuments");
	LockItem.Mode = DataLockMode.Exclusive;
	LockItem.DataSource = LineItems;
	LockItem.UseFromDataSource("Document", "Document"); 		
	// Set lock on the object.
	DataLock.Lock();
	
	Request = New Query("SELECT
	                    |	DepositLineItems.Document AS PaidDocument,
	                    |	DepositLineItems.Document.Presentation,
	                    |	DepositLineItems.LineNumber,
	                    |	DepositLineItems.DocumentTotal AS Payment,
	                    |	DepositLineItems.Payment AS PaymentFlag,
	                    |	UndepositedDocumentsBalance.Document,
	                    |	ISNULL(UndepositedDocumentsBalance.AmountBalance, 0) AS AmountBalance
	                    |FROM
	                    |	Document.Deposit.LineItems AS DepositLineItems
	                    |		LEFT JOIN AccumulationRegister.UndepositedDocuments.Balance(
	                    |				,
	                    |				Document IN
	                    |					(SELECT
	                    |						Doc.Document
	                    |					FROM
	                    |						Document.Deposit.LineItems AS Doc
	                    |					WHERE
	                    |						Doc.Ref = &CurrentDocument)) AS UndepositedDocumentsBalance
	                    |		ON DepositLineItems.Document = UndepositedDocumentsBalance.Document
	                    |WHERE
	                    |	ISNULL(UndepositedDocumentsBalance.AmountBalance, 0) <> DepositLineItems.DocumentTotalRC
	                    |	AND DepositLineItems.Payment = TRUE
	                    |	AND DepositLineItems.Ref = &CurrentDocument");
	Request.SetParameter("CurrentDocument", Ref);
	Res = Request.Execute();
	If Not Res.IsEmpty() Then
		Sel = Res.Select();
		While Sel.Next() Do
			CommonUseClientServer.MessageToUser("Amount to pay (" + Format(Sel.AmountBalance, "NFD=2; NZ=") + ") for the document " + Sel.DocumentPresentation + 
			" does not match the payment amount (" + Format(Sel.Payment, "NFD=2; NZ=") + ")", ThisObject,, "Object.LineItems[" + Format(Sel.LineNumber-1, "NFD=; NZ=") + "].DocumentTotalRC", Cancel); 
		EndDo;
		
	Else //Mark paid documents as Deposited
		
		RegisterRecords.UndepositedDocuments.Write = True;
		
		For Each DocumentLine in LineItems Do
		
			Record = RegisterRecords.UndepositedDocuments.AddExpense();
			Record.Period 	= Date;
			Record.Recorder = Ref;
			Record.Document = DocumentLine.Document;
			Record.Amount 	= DocumentLine.DocumentTotal;
			Record.AmountRC	= DocumentLine.DocumentTotalRC;
			
		EndDo;			
	EndIf;
	
	RegisterRecords.GeneralJournal.Write = True;
	
	Record = RegisterRecords.GeneralJournal.AddDebit();
	Record.Account  = BankAccount;
	Record.Currency = BankAccount.Currency;
	Record.Period   = Date;
	Record.Amount   = DocumentTotal;
	Record.AmountRC = DocumentTotalRC;
	
	//--//GJ++
	ReconciledDocumentsServerCall.AddRecordForGeneralJournalAnalyticsDimensions(RegisterRecords, Record, Null, Null, Null);
	//--//GJ--
	
	//--//CB++
	AddRecordForCashFlowData(RegisterRecords, Record, Null, Null, Null, Null);
	//--//CB--
	
	If NOT TotalDepositsRC = 0 Then
		Record = RegisterRecords.GeneralJournal.AddCredit();
		Record.Account  = Constants.UndepositedFundsAccount.Get();
		Record.Period   = Date;
		Record.AmountRC = TotalDepositsRC;
		
		//--//GJ++
		ReconciledDocumentsServerCall.AddRecordForGeneralJournalAnalyticsDimensions(RegisterRecords, Record, Null, Null, Null);
		//--//GJ--	
		
		//--//CB++
		AddRecordForCashFlowData(RegisterRecords, Record, Null, Null, Null, Null);
		//--//CB--
	EndIf;
	
	RegisterRecords.ProjectData.Write  = True;	
	RegisterRecords.ClassData.Write    = True;
	
	For Each AccountLine in Accounts Do
		
		If AccountLine.Amount > 0 Then
			Record = RegisterRecords.GeneralJournal.AddCredit();
			Record.Account  = AccountLine.Account;
			Record.Period   = Date;
			Record.AmountRC = AccountLine.Amount * ExchangeRate;
			
			//--//GJ++
			ReconciledDocumentsServerCall.AddRecordForGeneralJournalAnalyticsDimensions(RegisterRecords, Record, AccountLine.Class, AccountLine.Project, AccountLine.Company);
			//--//GJ--	
			
			//--//CB++
			AddRecordForCashFlowData(RegisterRecords, Record, AccountLine.Class, AccountLine.Project, AccountLine.Company, AccountLine.PaymentMethod);
			//--//CB--
		ElsIf AccountLine.Amount < 0 Then
			Record = RegisterRecords.GeneralJournal.AddDebit();
			Record.Account  = AccountLine.Account;
			Record.Period   = Date;
			Record.AmountRC = AccountLine.Amount * -ExchangeRate;
			
			//--//GJ++
			ReconciledDocumentsServerCall.AddRecordForGeneralJournalAnalyticsDimensions(RegisterRecords, Record, AccountLine.Class, AccountLine.Project, AccountLine.Company);
			//--//GJ--	
			
			//--//CB++
			AddRecordForCashFlowData(RegisterRecords, Record, AccountLine.Class, AccountLine.Project, AccountLine.Company, AccountLine.PaymentMethod);
			//--//CB--
		EndIf;
		
		
		If AccountLine.Account.AccountType = Enums.AccountTypes.AccountsPayable Then
			Record.ExtDimensions[ChartsOfCharacteristicTypes.Dimensions.Company] = AccountLine.Company;
			Record.ExtDimensions[ChartsOfCharacteristicTypes.Dimensions.Document] = Ref;
			Record.Currency = AccountLine.Account.Currency;
			Record.Amount = AccountLine.Amount;
		ElsIf AccountLine.Account.AccountType = Enums.AccountTypes.AccountsReceivable Then
			Record.ExtDimensions[ChartsOfCharacteristicTypes.Dimensions.Company] = AccountLine.Company;
			Record.ExtDimensions[ChartsOfCharacteristicTypes.Dimensions.Document] = Ref;
			Record.Currency = AccountLine.Account.Currency;
			Record.Amount = AccountLine.Amount;
		ElsIf AccountLine.Account.AccountType = Enums.AccountTypes.Bank Then
			Record.Currency = AccountLine.Account.Currency;
			Record.Amount = AccountLine.Amount;	
		EndIf;
		
		
		//Posting projects and classes
		Record = RegisterRecords.ProjectData.Add();
		Record.RecordType = AccumulationRecordType.Receipt;
		Record.Period = Date;
		Record.Account = AccountLine.Account;
		Record.Project = AccountLine.Project;
		Record.Amount = AccountLine.Amount*ExchangeRate;
			
		Record = RegisterRecords.ClassData.Add();
		Record.RecordType = AccumulationRecordType.Receipt;
		Record.Period = Date;
		Record.Account = AccountLine.Account;
		Record.Class = AccountLine.Class;
		Record.Amount = AccountLine.Amount*ExchangeRate;
		
	EndDo;
	
	
	// Writing bank reconciliation data
	ReconciledDocumentsServerCall.AddDocumentForReconciliation(RegisterRecords, Ref, BankAccount, Date, DocumentTotalRC);
	LineItemsGroupped = Accounts.Unload(, "Account, Amount");
	LineItemsGroupped.GroupBy("Account", "Amount");
	For Each DepositRow In LineItemsGroupped Do
		If (DepositRow.Account.AccountType = Enums.AccountTypes.Bank) 
			OR (DepositRow.Account.AccountType = Enums.AccountTypes.OtherCurrentLiability And DepositRow.Account.CreditCard = True) Then
			ReconciledDocumentsServerCall.AddDocumentForReconciliation(RegisterRecords, Ref, DepositRow.Account, Date, -1 * DepositRow.Amount);
		EndIf;
	EndDo;
	
	CheckedValueTable = RegisterRecords.GeneralJournal.Unload();
	UnbalancedAmount = 0;
	If Not DocumentPosting.IsValueTableBalanced(CheckedValueTable, UnbalancedAmount) Then 
		Cancel = True;
		// Generate error message.
		MessageText = NStr("en = 'The document %1 cannot be posted, because it''s transaction is unbalanced.'");
		MessageText = StringFunctionsClientServer.SubstituteParametersInString(MessageText, Ref);
		CommonUseClientServer.MessageToUser(MessageText, Ref,,, Cancel);
	EndIf;		

EndProcedure

// Posts the document to the Cash flow data accumulation register
// Parameters:
//  RegisterRecords                 - RegisterRecordsCollection - Document postings list, containing CashFlowData register records
//  CurrentAccountingRegisterRecord - AccountingRegisterRecord - Current General journal record
//  Class                           - CatalogRef.Classes - Class of record
//  Project                         - CatalogRef.Projects - Project of record 
//  Company                         - CatalogRef.Companies - Company of record
//  PaymentMethod                   - CatalogRef.PaymentMethods - Payment method of record
Procedure AddRecordForCashFlowData(RegisterRecords, CurrentAccountingRegisterRecord, Class, Project, Company, PaymentMethod)
	
	If Not RegisterRecords.CashFlowData.Write Then
		RegisterRecords.CashFlowData.Write = True;
	EndIf;
	
	If CurrentAccountingRegisterRecord.RecordType = AccountingRecordType.Debit Then
		Record = RegisterRecords.CashFlowData.AddReceipt();
	Else
		Record = RegisterRecords.CashFlowData.AddExpense();
	EndIf;
	
	Record.Period        = CurrentAccountingRegisterRecord.Period;
	Record.Account       = CurrentAccountingRegisterRecord.Account;
	Record.AmountRC      = CurrentAccountingRegisterRecord.AmountRC;
	Record.Company       = Company;
	Record.Class         = Class;
	Record.Project	     = Project;
	Record.PaymentMethod = PaymentMethod;	
	Record.Document      = Ref;
	Record.SalesPerson   = Null;
		
EndProcedure


// The procedure prevents re-posting if the Allow Voiding functional option is disabled.
//
Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	// Document date adjustment patch (tunes the date of drafts like for the new documents).
	If  WriteMode = DocumentWriteMode.Posting And Not Posted // Posting of new or draft (saved but unposted) document.
	And BegOfDay(Date) = BegOfDay(CurrentSessionDate()) Then // Operational posting (by the current date).
		// Shift document time to the time of posting.
		Date = CurrentSessionDate();
	EndIf;
	
	//If Posted Then
	//	
	//	For Each DocumentLine in LineItems Do
	//		
	//		GeneralFunctions.ClearDepositData(DocumentLine.Document);
	//		
	//	EndDo;
	//	
	//EndIf;
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	// Forced assign the new document number.
	If ThisObject.IsNew() And Not ValueIsFilled(ThisObject.Number) Then ThisObject.SetNewNumber(); EndIf;
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	If ThisObject.IsNew() Then ThisObject.SetNewNumber(); EndIf;
	
EndProcedure


Procedure OnSetNewNumber(StandardProcessing, Prefix)
	
	StandardProcessing = False;
	
	Numerator = Catalogs.DocumentNumbering.Deposit;
	NextNumber = GeneralFunctions.Increment(Numerator.Number);
	
	While Documents.Deposit.FindByNumber(NextNumber) <> Documents.Deposit.EmptyRef() And NextNumber <> "" Do
		ObjectNumerator = Numerator.GetObject();
		ObjectNumerator.Number = NextNumber;
		ObjectNumerator.Write();
		
		NextNumber = GeneralFunctions.Increment(NextNumber);
	EndDo;
	
	ThisObject.Number = NextNumber; 

EndProcedure


