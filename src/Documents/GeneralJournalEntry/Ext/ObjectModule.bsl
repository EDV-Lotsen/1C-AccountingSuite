// The procedure creates a GL entry transaction
//
Procedure Posting(Cancel, Mode)
	
	RegisterRecords.GeneralJournal.Write = True;
	
	For Each CurRowLineItems In LineItems Do
		
		If CurRowLineItems.AmountDr > 0 Then
		
		 	Record = RegisterRecords.GeneralJournal.AddDebit();
			Record.Account = CurRowLineItems.Account;
			If NOT DontWriteFCY Then
				If Record.Account.AccountType = Enums.AccountTypes.Bank OR Record.Account.AccountType = Enums.AccountTypes.AccountsPayable OR Record.Account.AccountType = Enums.AccountTypes.AccountsReceivable Then
					Record.Currency = Record.Account.Currency;
				EndIf;
			EndIF;	
			Record.Period = Date;
			If NOT DontWriteFCY Then
				If Record.Account.AccountType = Enums.AccountTypes.Bank OR Record.Account.AccountType = Enums.AccountTypes.AccountsPayable OR Record.Account.AccountType = Enums.AccountTypes.AccountsReceivable Then
					Record.Amount = CurRowLineItems.AmountDr;
				EndIf;
			EndIf;	
			Record.AmountRC = CurRowLineItems.AmountDr * ExchangeRate;
			
		Else
		
			Record = RegisterRecords.GeneralJournal.AddCredit();
			Record.Account = CurRowLineItems.Account;
			If NOT DontWriteFCY Then
				If Record.Account.AccountType = Enums.AccountTypes.Bank OR Record.Account.AccountType = Enums.AccountTypes.AccountsPayable OR Record.Account.AccountType = Enums.AccountTypes.AccountsReceivable Then
					Record.Currency = Record.Account.Currency;
				EndIf;
			EndIf;	
			Record.Period = Date;
			If NOT DontWriteFCY Then
				If Record.Account.AccountType = Enums.AccountTypes.Bank OR Record.Account.AccountType = Enums.AccountTypes.AccountsPayable OR Record.Account.AccountType = Enums.AccountTypes.AccountsReceivable Then
					Record.Amount = CurRowLineItems.AmountCr;
				EndIf;
			EndIf;	
			Record.AmountRC = CurRowLineItems.AmountCr * ExchangeRate;
	
        EndIf;
		
	EndDo;

EndProcedure