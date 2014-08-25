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
			
	ReconciledDocumentsServerCall.AddDocumentForReconciliation(RegisterRecords, Ref, BankAccount, Date, -1 * DocumentTotalRC);
	
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

