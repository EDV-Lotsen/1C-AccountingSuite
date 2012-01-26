// The procedure posts interest earned and bank service charge transactions.
//
Procedure Posting(Cancel, Mode)
	
	RegisterRecords.GeneralJournal.Write = True;
	    
	Record = RegisterRecords.GeneralJournal.AddDebit();
	Record.Account = BankAccount;
	Record.Period = InterestEarnedDate;
	Record.AmountRC = InterestEarned;

	Record = RegisterRecords.GeneralJournal.AddCredit();
	Record.Account = Constants.BankInterestEarnedAccount.Get();
	Record.Period = InterestEarnedDate;
	Record.AmountRC = InterestEarned;
	
	Record = RegisterRecords.GeneralJournal.AddCredit();
	Record.Account = BankAccount;
	Record.Period = ServiceChargeDate;
	Record.AmountRC = ServiceCharge;

	Record = RegisterRecords.GeneralJournal.AddDebit();
	Record.Account = Constants.BankServiceChargeAccount.Get();
	Record.Period = ServiceChargeDate;
	Record.AmountRC = ServiceCharge;

EndProcedure