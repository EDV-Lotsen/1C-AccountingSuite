
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
	
	ReconciledDocumentsServerCall.AddDocumentForReconciliation(RegisterRecords, Ref, BankAccount, Date, -1 * DocumentTotalRC);
	
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
	RegisterRecords.ClassData.Write = True;
	For Each CurRowLineItems In LineItems Do
		Record = RegisterRecords.ProjectData.Add();
		Record.RecordType = AccumulationRecordType.Expense;
		Record.Period = Date;
		Record.Account = CurRowLineItems.Account;
		Record.Project = CurRowLineItems.Project;
		Record.Amount = CurRowLineItems.Amount;
		
		Record = RegisterRecords.ClassData.Add();
		Record.RecordType = AccumulationRecordType.Expense;
		Record.Period = Date;
		Record.Account = CurRowLineItems.Account;
		Record.Class = CurRowLineItems.Class;
		Record.Amount = CurRowLineItems.Amount;
	EndDo;
	
	RegisterRecords.CashFlowData.Write = True;
	For Each CurRowLineItems In LineItems Do			
		
		Record = RegisterRecords.CashFlowData.Add();
		Record.RecordType = AccumulationRecordType.Receipt;
		Record.Period = Date;
		Record.Company = Company;
		Record.Document = Ref;
		Record.Account = CurRowLineItems.Account;
		//Record.CashFlowSection = CurRowLineItems.Account.CashFlowSection;
		Record.AmountRC = CurRowLineItems.Amount * ExchangeRate;
		//Record.PaymentMethod = PaymentMethod;

		
		Record = RegisterRecords.CashFlowData.Add();
		Record.RecordType = AccumulationRecordType.Expense;
		Record.Period = Date;
		Record.Company = Company;
		Record.Document = Ref;
		Record.Account = CurRowLineItems.Account;
		//Record.CashFlowSection = CurRowLineItems.Account.CashFlowSection;
		Record.AmountRC = CurRowLineItems.Amount * ExchangeRate;
		//Record.PaymentMethod = PaymentMethod;
	EndDo;
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	//Remove physical num for checking
	PhysicalCheckNum = 0;

	
	// Deleting bank reconciliation data
	
	Records = InformationRegisters.TransactionReconciliation.CreateRecordManager();
	Records.Document = Ref;
	Records.Account = BankAccount;
	Records.Read();
	Records.Delete();

EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	// Document date adjustment patch (tunes the date of drafts like for the new documents).
	If  WriteMode = DocumentWriteMode.Posting And Not Posted // Posting of new or draft (saved but unposted) document.
	And BegOfDay(Date) = BegOfDay(CurrentSessionDate()) Then // Operational posting (by the current date).
		// Shift document time to the time of posting.
		Date = CurrentSessionDate();
	EndIf;
	
	If WriteMode = DocumentWriteMode.Posting Then
		
		If PaymentMethod = Catalogs.PaymentMethods.Check Then
			
			If ExistCheck(Number) = False Then
				
				//	StrNextNum = StrReplace(String(GeneralFunctions.LastCheckNumber(BankAccount)+ 1),",","");
				//	test = Ref.IsEmpty();
				//	If PhysicalCheckNum = 0 And Number = StrNextNum Then
				//	
				//		LastNumber = GeneralFunctions.LastCheckNumber(BankAccount);
				//		
				//		LastNumberString = "";
				//		If LastNumber < 10000 Then
				//			LastNumberString = Left(String(LastNumber+1),1) + Right(String(LastNumber+1),3)
				//		Else
				//			LastNumberString = Left(String(LastNumber+1),2) + Right(String(LastNumber+1),3)
				//		EndIf;
				//		
				//		Number = LastNumberString;
				//		PhysicalCheckNum = LastNumber + 1;
				//					
				//	Else
				//		Try
				//			PhysicalCheckNum = Number(Number);
				//		Except
				//		EndTry;
				//
				//	EndIf;
				
				PhysicalCheckNum = Number;
					
			Else
				Message("Check number already exists for this bank account");
				Cancel = True;
			EndIf;
		Endif;
		
	EndIf;
	
EndProcedure

Procedure BeforeDelete(Cancel)
	
	TRRecordset = InformationRegisters.TransactionReconciliation.CreateRecordSet();
	TRRecordset.Filter.Document.Set(ThisObject.Ref);
	TRRecordset.Write(True);

EndProcedure

Function ExistCheck(Num)
	
	Try
	    CheckNum = Number(Number);
		Query = New Query("SELECT
		                  |	Check.PhysicalCheckNum AS Number,
		                  |	Check.Ref
		                  |FROM
		                  |	Document.Check AS Check
		                  |WHERE
		                  |	Check.BankAccount = &BankAccount
		                  |	AND Check.PaymentMethod = VALUE(Catalog.PaymentMethods.Check)
		                  |	AND Check.PhysicalCheckNum = &CheckNum
		                  |
		                  |UNION ALL
		                  |
		                  |SELECT
		                  |	InvoicePayment.PhysicalCheckNum,
		                  |	InvoicePayment.Ref
		                  |FROM
		                  |	Document.InvoicePayment AS InvoicePayment
		                  |WHERE
		                  |	InvoicePayment.BankAccount = &BankAccount
		                  |	AND InvoicePayment.PaymentMethod = VALUE(Catalog.PaymentMethods.Check)
		                  |	AND InvoicePayment.PhysicalCheckNum = &CheckNum
		                  |
		                  |ORDER BY
		                  |	Number DESC");
		Query.SetParameter("BankAccount", BankAccount);
		Query.SetParameter("CheckNum", CheckNum);
		//Query.SetParameter("Number", Object.Number);
		QueryResult = Query.Execute().Unload();
		If QueryResult.Count() = 0 Then
			Return False;
		ElsIf QueryResult.Count() = 1 And QueryResult[0].Ref = Ref Then
			Return False;
		Else	

			Return True;
		EndIf;
	Except
		Return False
	EndTry;
		
	
EndFunction

