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
	
	Record = RegisterRecords.GeneralJournal.AddCredit();
	Record.Account = Constants.UndepositedFundsAccount.Get();
	Record.Period = Date;
	Record.AmountRC = DocumentTotalRC;
	
EndProcedure

// The procedure prevents re-posting if the Allow Voiding functional option is disabled.
//
Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If Posted Then
		
		For Each DocumentLine in LineItems Do
			
			GeneralFunctions.ClearDepositData(DocumentLine.Document);
			
		EndDo;	

	EndIf;	

EndProcedure

// Clears the DocPosted attribute on document copying
//
Procedure OnCopy(CopiedObject)
	DocPosted = False;
EndProcedure

