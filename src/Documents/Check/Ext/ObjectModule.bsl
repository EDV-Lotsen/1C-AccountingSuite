
//Procedure Filling(FillingData, StandardProcessing)
//	
//	// preventing posting if already included in a bank rec
//	
//	Query = New Query("SELECT
//					  |	TransactionReconciliation.Document
//					  |FROM
//					  |	InformationRegister.TransactionReconciliation AS TransactionReconciliation
//					  |WHERE
//					  |	TransactionReconciliation.Document = &Ref
//					  |	AND TransactionReconciliation.Reconciled = TRUE");
//	Query.SetParameter("Ref", Ref);
//	Selection = Query.Execute();
//	
//	If NOT Selection.IsEmpty() Then
//		
//		Message = New UserMessage();
//		Message.Text=NStr("en='This document is already included in a bank reconciliation. Please remove it from the bank rec first.'");
//		Message.Message();
//		Cancel = True;
//		Return;
//		
//	EndIf;

//	// end preventing posting if already included in a bank rec

//	
//	If TypeOf(FillingData) = Type("DocumentRef.InvoicePayment") Then
//		
//		// Check if a Check is already created. If found - cancel.
//		
//		Query = New Query("SELECT
//						  |	Check.Ref
//						  |FROM
//						  |	Document.Check AS Check
//						  |WHERE
//						  |	Check.ParentDocument = &Ref");
//		Query.SetParameter("Ref", FillingData.Ref);
//		QueryResult = Query.Execute();
//		If NOT QueryResult.IsEmpty() Then
//			Message = New UserMessage();
//			Message.Text=NStr("en='Check is already created based on this Invoice Payment'");
//			Message.Message();
//			DontCreate = True;
//			Return;
//		EndIf;
//		
//		Company = FillingData.Company;
//		Memo = FillingData.Memo;
//		BankAccount = FillingData.BankAccount;
//		ParentDocument = FillingData.Ref;
//		DocumentTotal = FillingData.DocumentTotal;
//		DocumentTotalRC = FillingData.DocumentTotalRC;
//		
//		AccountCurrency = CommonUse.GetAttributeValue(BankAccount, "Currency");
//		ExchangeRate = GeneralFunctions.GetExchangeRate(CurrentDate(), AccountCurrency);
//		
//		Number = GeneralFunctions.NextCheckNumber(BankAccount);	
//		
//	EndIf;
//	
//	If TypeOf(FillingData) = Type("DocumentRef.CashPurchase") Then
//		
//		// Check if a Check is already created. If found - cancel.
//		
//		Query = New Query("SELECT
//						  |	Check.Ref
//						  |FROM
//						  |	Document.Check AS Check
//						  |WHERE
//						  |	Check.ParentDocument = &Ref");
//		Query.SetParameter("Ref", FillingData.Ref);
//		QueryResult = Query.Execute();
//		If NOT QueryResult.IsEmpty() Then
//			Message = New UserMessage();
//			Message.Text=NStr("en='Check is already created based on this Cash Purchase'");
//			Message.Message();
//			DontCreate = True;
//			Return;
//		EndIf;
//		
//		Company = FillingData.Company;
//		Memo = FillingData.Memo;
//		BankAccount = FillingData.BankAccount;
//		ParentDocument = FillingData.Ref;
//		DocumentTotal = FillingData.DocumentTotal;
//		DocumentTotalRC = FillingData.DocumentTotalRC;
//		
//		AccountCurrency = CommonUse.GetAttributeValue(BankAccount, "Currency");
//		ExchangeRate = GeneralFunctions.GetExchangeRate(CurrentDate(), AccountCurrency);
//		
//		Number = GeneralFunctions.NextCheckNumber(BankAccount);	
//		
//	EndIf;
//	
//	
//		  					  
//EndProcedure

// Performs document posting
//
Procedure Posting(Cancel, PostingMode)
	
	// preventing posting if already included in a bank rec
	
	Query = New Query("SELECT
					  |	TransactionReconciliation.Document
					  |FROM
					  |	InformationRegister.TransactionReconciliation AS TransactionReconciliation
					  |WHERE
					  |	TransactionReconciliation.Document = &Ref
					  |	AND TransactionReconciliation.Reconciled = TRUE");
	Query.SetParameter("Ref", Ref);
	Selection = Query.Execute();
	
	If NOT Selection.IsEmpty() Then
		
		Message = New UserMessage();
		Message.Text=NStr("en='This document is already included in a bank reconciliation. Please remove it from the bank rec first.'");
		Message.Message();
		Cancel = True;
		Return;
		
	EndIf;

	// end preventing posting if already included in a bank rec

	
	RegisterRecords.GeneralJournal.Write = True;	
	
	VarDocumentTotal = 0;
	VarDocumentTotalRC = 0;
	For Each CurRowLineItems In LineItems Do			
		
		If CurRowLineItems.Amount >= 0 Then
			Record = RegisterRecords.GeneralJournal.AddDebit();
		Else
			Record = RegisterRecords.GeneralJournal.AddCredit();
		EndIf;
		Record.Account = CurRowLineItems.Account;
		Record.Period = Date;
		Record.Memo = CurRowLineItems.Memo;
		Record.AmountRC = SQRT(POW((CurRowLineItems.Amount * ExchangeRate),2));
		VarDocumentTotal = VarDocumentTotal + CurRowLineItems.Amount;
		VarDocumentTotalRC = VarDocumentTotalRC + CurRowLineItems.Amount * ExchangeRate;
		
	EndDo;
	
	Record = RegisterRecords.GeneralJournal.AddCredit();
	Record.Account = BankAccount;
	Record.Memo = Memo;
	Record.Currency = BankAccount.Currency;
	Record.Period = Date;
	Record.Amount = VarDocumentTotal;
	Record.AmountRC = VarDocumentTotalRC;
	
	// Writing bank reconciliation data
	
	Records = InformationRegisters.TransactionReconciliation.CreateRecordSet();
	Records.Filter.Document.Set(Ref);
	Records.Read();
	If Records.Count() = 0 Then
		Record = Records.Add();
		Record.Document = Ref;
		Record.Account = BankAccount;
		Record.Reconciled = False;
		Record.Amount = -1 * DocumentTotalRC;		
	Else
		Records[0].Account = BankAccount;
		Records[0].Amount = -1 * DocumentTotalRC;
	EndIf;
	Records.Write();
	
	//Records = InformationRegisters.TransactionReconciliation.CreateRecordSet();
	//Records.Filter.Document.Set(Ref);
	//Records.Filter.Account.Set(BankAccount);
	//Record = Records.Add();
	//Record.Document = Ref;
	//Record.Account = BankAccount;
	//Record.Reconciled = False;
	//Record.Amount = -1 * DocumentTotalRC;
	//Records.Write();
	
	RegisterRecords.ProjectData.Write = True;	
	For Each CurRowLineItems In LineItems Do
		If NOT CurRowLineItems.Project.IsEmpty() Then
			Record = RegisterRecords.ProjectData.Add();
			Record.RecordType = AccumulationRecordType.Expense;
			Record.Period = Date;
			Record.Project = CurRowLineItems.Project;
			Record.Amount = CurRowLineItems.Amount;
		Endif;
	EndDo;

	
EndProcedure

Procedure UndoPosting(Cancel)
	
	// preventing posting if already included in a bank rec
	
	Query = New Query("SELECT
					  |	TransactionReconciliation.Document
					  |FROM
					  |	InformationRegister.TransactionReconciliation AS TransactionReconciliation
					  |WHERE
					  |	TransactionReconciliation.Document = &Ref
					  |	AND TransactionReconciliation.Reconciled = TRUE");
	Query.SetParameter("Ref", Ref);
	Selection = Query.Execute();
	
	If NOT Selection.IsEmpty() Then
		
		Message = New UserMessage();
		Message.Text=NStr("en='This document is already included in a bank reconciliation. Please remove it from the bank rec first.'");
		Message.Message();
		Cancel = True;
		Return;
		
	EndIf;

	// end preventing posting if already included in a bank rec
	
	// Deleting bank reconciliation data
	
	Records = InformationRegisters.TransactionReconciliation.CreateRecordManager();
	Records.Document = Ref;
	Records.Account = BankAccount;
	Records.Read();
	Records.Delete();

EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	Test = PostingMode;
	If WriteMode = DocumentWriteMode.Posting Then
		
		If PaymentMethod = Catalogs.PaymentMethods.Check Then
			
			test = Ref.IsEmpty();
			If PhysicalCheckNum = 0 Then
			
				LastNumber = GeneralFunctions.LastCheckNumber(BankAccount);
				
				LastNumberString = "";
				If LastNumber < 10000 Then
					LastNumberString = Left(String(LastNumber+1),1) + Right(String(LastNumber+1),3)
				Else
					LastNumberString = Left(String(LastNumber+1),2) + Right(String(LastNumber+1),3)
				EndIf;
				
				Number = LastNumberString;
				PhysicalCheckNum = LastNumber + 1;
							
			Else
				//PhysicalCheckNum = Number(Number);		
			EndIf;
		Endif;
		
	EndIf;
	
	If WriteMode = DocumentWriteMode.Write Then
		Number = "DRAFT";
	EndIf;

EndProcedure


