
Procedure Posting(Cancel, PostingMode)
	
	RegisterRecords.GeneralJournal.Write = True;
	    
	Record = RegisterRecords.GeneralJournal.AddDebit();
	Record.Account = AccountTo;
	Record.Period = Date;
	Record.Currency = GeneralFunctionsReusable.DefaultCurrency();
	Record.Amount = Amount;
	Record.AmountRC = Amount;
	
	Record = RegisterRecords.GeneralJournal.AddCredit();
	Record.Account = AccountFrom;
	Record.Period = Date;
	Record.Currency = GeneralFunctionsReusable.DefaultCurrency();
	Record.Amount = Amount;
	Record.AmountRC = Amount;
	
	// Writing bank reconciliation data
		
	ReconciledDocumentsServerCall.AddDocumentForReconciliation(RegisterRecords, Ref, AccountFrom, Date, -1 * Amount);
	ReconciledDocumentsServerCall.AddDocumentForReconciliation(RegisterRecords, Ref, AccountTo, Date, Amount);
	
EndProcedure

