// The procedure posts interest earned and bank service charge transactions.
//
Procedure Posting(Cancel, Mode)
	
	RegisterRecords.GeneralJournal.Write = True;
	
	If (InterestEarned <> 0) Then
		Record = RegisterRecords.GeneralJournal.AddDebit();
		Record.Account = BankAccount;
		Record.Period = InterestEarnedDate;
		Record.AmountRC = InterestEarned;

		Record = RegisterRecords.GeneralJournal.AddCredit();
		Record.Account = BankInterestEarnedAccount;
		Record.Period = InterestEarnedDate;
		Record.AmountRC = InterestEarned;
	EndIf;
	
	If (ServiceCharge <> 0) Then
		Record = RegisterRecords.GeneralJournal.AddCredit();
		Record.Account = BankAccount;
		Record.Period = ServiceChargeDate;
		Record.AmountRC = ServiceCharge;

		Record = RegisterRecords.GeneralJournal.AddDebit();
		Record.Account = BankServiceChargeAccount;
		Record.Period = ServiceChargeDate;
		Record.AmountRC = ServiceCharge;
	EndIf;
		
	For Each CurRowLineItems In LineItems Do
		
		If CurRowLineItems.Cleared = True Then
		
			Records = InformationRegisters.TransactionReconciliation.CreateRecordSet();
			Records.Filter.Document.Set(CurRowLineItems.Transaction);
			Records.Filter.Account.Set(BankAccount);
			Records.Read();
			Records[0].Reconciled = True;
			Records.Write();			
			
		EndIf;
		
		If CurRowLineItems.Cleared = False Then
		
			Records = InformationRegisters.TransactionReconciliation.CreateRecordSet();
			Records.Filter.Document.Set(CurRowLineItems.Transaction);
			Records.Filter.Account.Set(BankAccount);
			Records.Read();
			Records[0].Reconciled = False;
			Records.Write();			
			
		EndIf;


	EndDo;


EndProcedure


Procedure UndoPosting(Cancel)
	
	For Each CurRowLineItems In LineItems Do
		
		If CurRowLineItems.Cleared = True Then
		
			Records = InformationRegisters.TransactionReconciliation.CreateRecordSet();
			Records.Filter.Document.Set(CurRowLineItems.Transaction);
			Records.Filter.Account.Set(BankAccount);
			Records.Read();
			Records[0].Reconciled = False;
			Records.Write();
			
		EndIf;

	EndDo;

EndProcedure

Procedure BeforeDelete(Cancel)
	
	For Each CurRowLineItems In LineItems Do
		
		If CurRowLineItems.Cleared = True Then
		
			Records = InformationRegisters.TransactionReconciliation.CreateRecordSet();
			Records.Filter.Document.Set(CurRowLineItems.Transaction);
			Records.Filter.Account.Set(BankAccount);
			Records.Read();
			Records[0].Reconciled = False;
			Records.Write();
			
		EndIf;

	EndDo;

EndProcedure



