	// The procedure creates a GJ entry transaction
//
Procedure Posting(Cancel, Mode)
		   
	CompaniesPresent = False;
	For Each CurRowLineItems In LineItems Do
		If CurRowLineItems.Company <> Catalogs.Companies.EmptyRef() Then
			CompaniesPresent = True;	
		EndIf;
	EndDo;
	
	OneARorAPLine = False;
	If CompaniesPresent = True Then
		For Each CurRowLineItems In LineItems Do
			If (CurRowLineItems.Account.AccountType <> Enums.AccountTypes.AccountsPayable AND
				CurRowLineItems.Account.AccountType <> Enums.AccountTypes.AccountsReceivable) AND
					CurRowLineItems.Company <> Catalogs.Companies.EmptyRef() Then
			OneARorAPLine = True;	
			EndIf;
		EndDo;
	EndIf;
	
	RegisterRecords.GeneralJournal.Write = True;
	
	// scenario 1 - Companies present, one or more A/R, A/P lines, one other line
	If CompaniesPresent = True AND OneARorAPLine = False Then
		
		For Each CurRowLineItems In LineItems Do
			
			If CurRowLineItems.AmountDr > 0 Then
			
			 	Record = RegisterRecords.GeneralJournal.AddDebit();
				Record.Account = CurRowLineItems.Account;
				If Record.Account.AccountType = Enums.AccountTypes.Bank OR Record.Account.AccountType = Enums.AccountTypes.AccountsPayable OR Record.Account.AccountType = Enums.AccountTypes.AccountsReceivable Then
					Record.Currency = Record.Account.Currency;
				EndIf;	
				Record.Period = Date;
				If Record.Account.AccountType = Enums.AccountTypes.Bank OR Record.Account.AccountType = Enums.AccountTypes.AccountsPayable OR Record.Account.AccountType = Enums.AccountTypes.AccountsReceivable Then
					Record.Amount = CurRowLineItems.AmountDr;
				EndIf;
				Record.AmountRC = CurRowLineItems.AmountDr * ExchangeRate;
				Record.Memo = CurRowLineItems.Memo;
				
				If CurRowLineItems.Company <> Catalogs.Companies.EmptyRef() Then
					Record.ExtDimensions[ChartsOfCharacteristicTypes.Dimensions.Company] = CurRowLineItems.Company;
					Record.ExtDimensions[ChartsOfCharacteristicTypes.Dimensions.Document] = Ref;
				EndIf;

			Else
			
				Record = RegisterRecords.GeneralJournal.AddCredit();
				Record.Account = CurRowLineItems.Account;
				If Record.Account.AccountType = Enums.AccountTypes.Bank OR Record.Account.AccountType = Enums.AccountTypes.AccountsPayable OR Record.Account.AccountType = Enums.AccountTypes.AccountsReceivable Then
					Record.Currency = Record.Account.Currency;
				EndIf;	
				Record.Period = Date;
				If Record.Account.AccountType = Enums.AccountTypes.Bank OR Record.Account.AccountType = Enums.AccountTypes.AccountsPayable OR Record.Account.AccountType = Enums.AccountTypes.AccountsReceivable Then
					Record.Amount = CurRowLineItems.AmountCr;
				EndIf;
				Record.AmountRC = CurRowLineItems.AmountCr * ExchangeRate;
				Record.Memo = CurRowLineItems.Memo;
				
				If CurRowLineItems.Company <> Catalogs.Companies.EmptyRef() Then
					Record.ExtDimensions[ChartsOfCharacteristicTypes.Dimensions.Company] = CurRowLineItems.Company;
					Record.ExtDimensions[ChartsOfCharacteristicTypes.Dimensions.Document] = Ref;
				EndIf;
			
			EndIf;
			
		EndDo;
	EndIf;
	
	// scenario 2 - Companies present, one A/R or A/P line, multiple other lines
	
	TransactionARorAPAccount = ChartsOfAccounts.ChartOfAccounts.EmptyRef();
	For Each CurRowLineItems In LineItems Do
		If CurRowLineItems.Account.AccountType = Enums.AccountTypes.AccountsPayable OR
			CurRowLineItems.Account.AccountType = Enums.AccountTypes.AccountsReceivable Then
				TransactionARorAPAccount = CurRowLineItems.Account;	
		EndIf;
	EndDo;
	
	If CompaniesPresent = True AND OneARorAPLine = True Then
		
		For Each CurRowLineItems In LineItems Do
			
			If CurRowLineItems.Account.AccountType <> Enums.AccountTypes.AccountsPayable AND
				CurRowLineItems.Account.AccountType <> Enums.AccountTypes.AccountsReceivable Then
			
				If CurRowLineItems.AmountDr > 0 Then
				
				 	Record = RegisterRecords.GeneralJournal.AddDebit();
					Record.Account = CurRowLineItems.Account;
					If Record.Account.AccountType = Enums.AccountTypes.Bank OR Record.Account.AccountType = Enums.AccountTypes.AccountsPayable OR Record.Account.AccountType = Enums.AccountTypes.AccountsReceivable Then
						Record.Currency = Record.Account.Currency;
					EndIf;	
					Record.Period = Date;
					If Record.Account.AccountType = Enums.AccountTypes.Bank OR Record.Account.AccountType = Enums.AccountTypes.AccountsPayable OR Record.Account.AccountType = Enums.AccountTypes.AccountsReceivable Then
						Record.Amount = CurRowLineItems.AmountDr;
					EndIf;
					Record.AmountRC = CurRowLineItems.AmountDr * ExchangeRate;
					Record.Memo = CurRowLineItems.Memo;
					
					Record = RegisterRecords.GeneralJournal.AddCredit();
					Record.Account = TransactionARorAPAccount;
					If Record.Account.AccountType = Enums.AccountTypes.Bank OR Record.Account.AccountType = Enums.AccountTypes.AccountsPayable OR Record.Account.AccountType = Enums.AccountTypes.AccountsReceivable Then
						Record.Currency = Record.Account.Currency;
					EndIf;	
					Record.Period = Date;
					If Record.Account.AccountType = Enums.AccountTypes.Bank OR Record.Account.AccountType = Enums.AccountTypes.AccountsPayable OR Record.Account.AccountType = Enums.AccountTypes.AccountsReceivable Then
						Record.Amount = CurRowLineItems.AmountDr;
					EndIf;
					Record.AmountRC = CurRowLineItems.AmountDr * ExchangeRate;
					Record.Memo = CurRowLineItems.Memo;
					
					Record.ExtDimensions[ChartsOfCharacteristicTypes.Dimensions.Company] = CurRowLineItems.Company;
					Record.ExtDimensions[ChartsOfCharacteristicTypes.Dimensions.Document] = Ref;

				Else
				
					Record = RegisterRecords.GeneralJournal.AddCredit();
					Record.Account = CurRowLineItems.Account;
					If Record.Account.AccountType = Enums.AccountTypes.Bank OR Record.Account.AccountType = Enums.AccountTypes.AccountsPayable OR Record.Account.AccountType = Enums.AccountTypes.AccountsReceivable Then
						Record.Currency = Record.Account.Currency;
					EndIf;	
					Record.Period = Date;
					If Record.Account.AccountType = Enums.AccountTypes.Bank OR Record.Account.AccountType = Enums.AccountTypes.AccountsPayable OR Record.Account.AccountType = Enums.AccountTypes.AccountsReceivable Then
						Record.Amount = CurRowLineItems.AmountCr;
					EndIf;
					Record.AmountRC = CurRowLineItems.AmountCr * ExchangeRate;
					Record.Memo = CurRowLineItems.Memo;
					
					Record = RegisterRecords.GeneralJournal.AddDebit();
					Record.Account = TransactionARorAPAccount;
					If Record.Account.AccountType = Enums.AccountTypes.Bank OR Record.Account.AccountType = Enums.AccountTypes.AccountsPayable OR Record.Account.AccountType = Enums.AccountTypes.AccountsReceivable Then
						Record.Currency = Record.Account.Currency;
					EndIf;	
					Record.Period = Date;
					If Record.Account.AccountType = Enums.AccountTypes.Bank OR Record.Account.AccountType = Enums.AccountTypes.AccountsPayable OR Record.Account.AccountType = Enums.AccountTypes.AccountsReceivable Then
						Record.Amount = CurRowLineItems.AmountDr;
					EndIf;
					Record.AmountRC = CurRowLineItems.AmountCr * ExchangeRate;
					Record.Memo = CurRowLineItems.Memo;

					Record.ExtDimensions[ChartsOfCharacteristicTypes.Dimensions.Company] = CurRowLineItems.Company;
					Record.ExtDimensions[ChartsOfCharacteristicTypes.Dimensions.Document] = Ref;
				
				EndIf;
				
			EndIf;
			
		EndDo;
	EndIf;

	
	// scenario 3 - basic transaction, no Companies present
	If CompaniesPresent = False Then 
	
		For Each CurRowLineItems In LineItems Do
			
			If CurRowLineItems.AmountDr > 0 Then
			
			 	Record = RegisterRecords.GeneralJournal.AddDebit();
				Record.Account = CurRowLineItems.Account;
				If Record.Account.AccountType = Enums.AccountTypes.Bank OR Record.Account.AccountType = Enums.AccountTypes.AccountsPayable OR Record.Account.AccountType = Enums.AccountTypes.AccountsReceivable Then
					Record.Currency = Record.Account.Currency;
				EndIf;	
				Record.Period = Date;
				If Record.Account.AccountType = Enums.AccountTypes.Bank OR Record.Account.AccountType = Enums.AccountTypes.AccountsPayable OR Record.Account.AccountType = Enums.AccountTypes.AccountsReceivable Then
					Record.Amount = CurRowLineItems.AmountDr;
				EndIf;
				Record.AmountRC = CurRowLineItems.AmountDr * ExchangeRate;
				Record.Memo = CurRowLineItems.Memo;

			Else
			
				Record = RegisterRecords.GeneralJournal.AddCredit();
				Record.Account = CurRowLineItems.Account;
				If Record.Account.AccountType = Enums.AccountTypes.Bank OR Record.Account.AccountType = Enums.AccountTypes.AccountsPayable OR Record.Account.AccountType = Enums.AccountTypes.AccountsReceivable Then
					Record.Currency = Record.Account.Currency;
				EndIf;	
				Record.Period = Date;
				If Record.Account.AccountType = Enums.AccountTypes.Bank OR Record.Account.AccountType = Enums.AccountTypes.AccountsPayable OR Record.Account.AccountType = Enums.AccountTypes.AccountsReceivable Then
					Record.Amount = CurRowLineItems.AmountCr;
				EndIf;
				Record.AmountRC = CurRowLineItems.AmountCr * ExchangeRate;
				Record.Memo = CurRowLineItems.Memo;
			
			EndIf;
			
		EndDo;
		
	EndIf;

EndProcedure