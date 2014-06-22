
////////////////////////////////////////////////////////////////////////////////
// General Journal Entry: Object module
//------------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
#Region EVENT_HANDLERS

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	// Document date adjustment patch (tunes the date of drafts like for the new documents).
	If  WriteMode = DocumentWriteMode.Posting And Not Posted // Posting of new or draft (saved but unposted) document.
	And BegOfDay(Date) = BegOfDay(CurrentSessionDate()) Then // Operational posting (by the current date).
		// Shift document time to the time of posting.
		Date = CurrentSessionDate();
	EndIf;
	
EndProcedure

Procedure Posting(Cancel, Mode)
	
	RegisterRecords.CashFlowData.Write = True;
	For Each CurRowLineItems In LineItems Do
		
		If CurRowLineItems.Account.AccountType = Enums.AccountTypes.Income OR
		   CurRowLineItems.Account.AccountType = Enums.AccountTypes.OtherIncome Then
		
				Record = RegisterRecords.CashFlowData.Add();
				Record.RecordType = AccumulationRecordType.Expense;
				Record.Period = Date;
				Record.Document = Ref;
				Record.Account = CurRowLineItems.Account;
				If CurRowLineItems.AmountCr > 0 Then
					Record.AmountRC = CurRowLineItems.AmountCr * ExchangeRate;
				ElsIf CurRowLineItems.AmountDr > 0 Then
					Record.AmountRC = CurRowLineItems.AmountDr * ExchangeRate * -1;
				EndIf;
				
				Record = RegisterRecords.CashFlowData.Add();
				Record.RecordType = AccumulationRecordType.Receipt;
				Record.Period = Date;
				Record.Document = Ref;
				Record.Account = CurRowLineItems.Account;
				If CurRowLineItems.AmountCr > 0 Then
					Record.AmountRC = CurRowLineItems.AmountCr * ExchangeRate;
				ElsIf CurRowLineItems.AmountDr > 0 Then
					Record.AmountRC = CurRowLineItems.AmountDr * ExchangeRate * -1;
				EndIf;
				
			EndIf;
			
		If CurRowLineItems.Account.AccountType = Enums.AccountTypes.CostOfSales OR
		   CurRowLineItems.Account.AccountType = Enums.AccountTypes.Expense OR
		   CurRowLineItems.Account.AccountType = Enums.AccountTypes.OtherExpense OR
		   CurRowLineItems.Account.AccountType = Enums.AccountTypes.IncomeTaxExpense Then
		   
		   		Record = RegisterRecords.CashFlowData.Add();
				Record.RecordType = AccumulationRecordType.Receipt;
				Record.Period = Date;
				Record.Document = Ref;
				Record.Account = CurRowLineItems.Account;
				If CurRowLineItems.AmountDr > 0 Then
					Record.AmountRC = CurRowLineItems.AmountDr * ExchangeRate;
				ElsIf CurRowLineItems.AmountCr > 0 Then
					Record.AmountRC = CurRowLineItems.AmountCr * ExchangeRate * -1;
				EndIf;
				
				Record = RegisterRecords.CashFlowData.Add();
				Record.RecordType = AccumulationRecordType.Expense;
				Record.Period = Date;
				Record.Document = Ref;
				Record.Account = CurRowLineItems.Account;
				If CurRowLineItems.AmountDr > 0 Then
					Record.AmountRC = CurRowLineItems.AmountDr * ExchangeRate;
				ElsIf CurRowLineItems.AmountCr > 0 Then
					Record.AmountRC = CurRowLineItems.AmountCr * ExchangeRate * -1;
				EndIf;

		   
		EndIf;

	EndDo;

	
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
	
	//Posting classes and projects
	RegisterRecords.ClassData.Write = True;
	RegisterRecords.ProjectData.Write = True;
		
	For Each CurRowLineItems In LineItems Do
		If ((CurRowLineItems.Account.AccountType = Enums.AccountTypes.Expense) OR
			(CurRowLineItems.Account.AccountType = Enums.AccountTypes.OtherExpense) OR
			(CurRowLineItems.Account.AccountType = Enums.AccountTypes.CostOfSales) OR
			(CurRowLineItems.Account.AccountType = Enums.AccountTypes.IncomeTaxExpense)) Then
			//Due increasing  - in Debit
			RecordType = ?(CurRowLineItems.AmountDr > 0, AccumulationRecordType.Expense, AccumulationRecordType.Receipt);		
			CurAmount = ?(CurRowLineItems.AmountDr > 0, CurRowLineItems.AmountDr, CurRowLineItems.AmountCr);
		ElsIf
			((CurRowLineItems.Account.AccountType = Enums.AccountTypes.Income) OR
			(CurRowLineItems.Account.AccountType = Enums.AccountTypes.OtherIncome)) Then
			//Income increase - in Credit
			RecordType = ?(CurRowLineItems.AmountDr > 0, AccumulationRecordType.Expense, AccumulationRecordType.Receipt);		
			CurAmount = ?(CurRowLineItems.AmountDr > 0, CurRowLineItems.AmountDr, CurRowLineItems.AmountCr);
		Else
			Continue;
		EndIf;
		
		//Classes
		Record = RegisterRecords.ClassData.Add();
		Record.RecordType = RecordType;
		Record.Period = Date;
		Record.Account = CurRowLineItems.Account;
		Record.Class = CurRowLineItems.Class;
		Record.Amount = CurAmount;
		
		//Projects
		Record = RegisterRecords.ProjectData.Add();
		Record.RecordType = RecordType;
		Record.Period = Date;
		Record.Account = CurRowLineItems.Account;
		Record.Project = CurRowLineItems.Project;
		Record.Amount = CurAmount;
		
	EndDo;

EndProcedure

#EndIf

#EndRegion
