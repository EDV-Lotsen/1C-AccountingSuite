
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
		
	Records = InformationRegisters.TransactionReconciliation.CreateRecordSet();
	Records.Filter.Document.Set(Ref);
	Records.Read();
	If Records.Count() = 0 Then		
		Record = Records.Add();
		Record.Document = Ref;
		Record.Account = AccountFrom;
		Record.Reconciled = False;
		Record.Amount = -1 * Amount;
		
		Record = Records.Add();
		Record.Document = Ref;
		Record.Account = AccountTo;
		Record.Reconciled = False;
		Record.Amount = Amount;		
	Else
		Records[0].Account = AccountFrom;
		Records[0].Amount = -1 * Amount;
		Records[1].Account = AccountTo;
		Records[1].Amount = Amount;
	EndIf;
	Records.Write();
	
	//Records = InformationRegisters.TransactionReconciliation.CreateRecordSet();
	//Records.Filter.Document.Set(Ref);
	//Records.Filter.Account.Set(AccountFrom);
	//Record = Records.Add();
	//Record.Document = Ref;
	//Record.Account = AccountFrom;
	//Record.Reconciled = False;
	//Record.Amount = -1 * Amount;
	//Records.Write();
	//
	//Records = InformationRegisters.TransactionReconciliation.CreateRecordSet();
	//Records.Filter.Document.Set(Ref);
	//Records.Filter.Account.Set(AccountTo);
	//Record = Records.Add();
	//Record.Document = Ref;
	//Record.Account = AccountTo;
	//Record.Reconciled = False;
	//Record.Amount = Amount;
	//Records.Write();

EndProcedure

Procedure UndoPosting(Cancel)
	
	// Deleting bank reconciliation data
	
	Records = InformationRegisters.TransactionReconciliation.CreateRecordManager();
	Records.Document = Ref;
	Records.Account = AccountFrom;
	Records.Read();
	Records.Delete();
	
	Records = InformationRegisters.TransactionReconciliation.CreateRecordManager();
	Records.Document = Ref;
	Records.Account = AccountTo;
	Records.Read();
	Records.Delete();

EndProcedure

