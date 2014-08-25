// The procedure posts deposit transactions
//
Procedure Posting(Cancel, Mode)
	
	For Each DocumentLine in LineItems Do
		
		GeneralFunctions.WriteDepositData(DocumentLine.Document);
		
	EndDo;	
	
	RegisterRecords.GeneralJournal.Write = True;
	
	Record = RegisterRecords.GeneralJournal.AddDebit();
	Record.Account = BankAccount;
	Record.Currency = BankAccount.Currency;
	Record.Period = Date;
	Record.Amount = DocumentTotal;
	Record.AmountRC = DocumentTotalRC;
	
	If NOT TotalDepositsRC = 0 Then
		Record = RegisterRecords.GeneralJournal.AddCredit();
		Record.Account = Constants.UndepositedFundsAccount.Get();
		Record.Period = Date;
		Record.AmountRC = TotalDepositsRC;
	EndIf;
	
	RegisterRecords.ProjectData.Write = True;	
	RegisterRecords.ClassData.Write = True;
	For Each AccountLine in Accounts Do
		If AccountLine.Amount > 0 Then
			Record = RegisterRecords.GeneralJournal.AddCredit();
			Record.Account = AccountLine.Account;
			Record.Period = Date;
			Record.AmountRC = AccountLine.Amount;
		ElsIf AccountLine.Amount < 0 Then
			Record = RegisterRecords.GeneralJournal.AddDebit();
			Record.Account = AccountLine.Account;
			Record.Period = Date;
			Record.AmountRC = AccountLine.Amount * -1;
		EndIf;
		
		//Posting projects and classes
		Record = RegisterRecords.ProjectData.Add();
		Record.RecordType = AccumulationRecordType.Receipt;
		Record.Period = Date;
		Record.Account = AccountLine.Account;
		Record.Project = AccountLine.Project;
		Record.Amount = AccountLine.Amount;
			
		Record = RegisterRecords.ClassData.Add();
		Record.RecordType = AccumulationRecordType.Receipt;
		Record.Period = Date;
		Record.Account = AccountLine.Account;
		Record.Class = AccountLine.Class;
		Record.Amount = AccountLine.Amount;

	EndDo;
	
	// Writing bank reconciliation data
			
	ReconciledDocumentsServerCall.AddDocumentForReconciliation(RegisterRecords, Ref, BankAccount, Date, DocumentTotalRC);

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
	
	If Posted Then
		
		For Each DocumentLine in LineItems Do
			
			GeneralFunctions.ClearDepositData(DocumentLine.Document);
			
		EndDo;
		
	EndIf;
	
EndProcedure


