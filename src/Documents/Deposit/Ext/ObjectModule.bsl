// The procedure posts deposit transactions
//
Procedure Posting(Cancel, Mode)
	
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
	EndDo;
	
	// Writing bank reconciliation data
	
	//Records = InformationRegisters.TransactionReconciliation.CreateRecordSet();
	//Records.Filter.Document.Set(Ref);
	//Records.Filter.Account.Set(BankAccount);
	//Record = Records.Add();
	//Record.Document = Ref;
	//Record.Account = BankAccount;
	//Record.Reconciled = False;
	//Record.Amount = DocumentTotalRC;
	//Records.Write();
	
	Records = InformationRegisters.TransactionReconciliation.CreateRecordSet();
	Records.Filter.Document.Set(Ref);
	Records.Read();
	If Records.Count() = 0 Then
		Record = Records.Add();
		Record.Document = Ref;
		Record.Account = BankAccount;
		Record.Reconciled = False;
		Record.Amount = DocumentTotalRC;		
	Else
		Records[0].Account = BankAccount;
		Records[0].Amount = DocumentTotalRC;
	EndIf;
	Records.Write();

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



