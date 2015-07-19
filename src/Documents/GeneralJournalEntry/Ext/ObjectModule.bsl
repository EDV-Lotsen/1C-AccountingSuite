
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
		
		//for Journal Entries that void Bill Payments
		If CurRowLineItems.Account.AccountType = Enums.AccountTypes.AccountsPayable Then
			If ValueIsFilled(VoidingEntry) Then
				
				//ExchangeRate = GeneralFunctions.GetExchangeRate(Date, DocumentObject.Currency);
				ExchangeRate = 1;
				
				RegisterRecords.CashFlowData.Write = True;
		
				If TypeOf(CurRowLineItems.VoidedEntry) = Type("DocumentRef.PurchaseInvoice") Then
					
					For Each Acc In CurRowLineItems.VoidedEntry.Accounts Do
						Record = RegisterRecords.CashFlowData.Add();
						Record.RecordType = AccumulationRecordType.Receipt;
						Record.Period = Date;
						Record.Company = CurRowLineItems.VoidedEntry.Company;
						Record.Document = CurRowLineItems.VoidedEntry;
						Record.Account = Acc.Account;
						//Record.CashFlowSection = Acc.Account.CashFlowSection;
						Record.PaymentMethod = VoidingEntry.PaymentMethod;
						Record.AmountRC = ((Acc.Amount * ExchangeRate) * CurRowLineItems.AmountCr)/CurRowLineItems.VoidedEntry.DocumentTotalRC;
					EndDo;
					
					For Each Item In CurRowLineItems.VoidedEntry.LineItems Do
						Record = RegisterRecords.CashFlowData.Add();
						Record.RecordType = AccumulationRecordType.Receipt;
						Record.Period = Date;
						Record.Company = CurRowLineItems.VoidedEntry.Company;
						Record.Document = CurRowLineItems.VoidedEntry;
						Record.Account = Item.Product.InventoryOrExpenseAccount;
						If Item.Product.Type = Enums.InventoryTypes.Inventory Then
							Record.Account = Item.Product.COGSAccount;
						Else
							Record.Account = Item.Product.InventoryOrExpenseAccount;
						EndIf;
						//Record.CashFlowSection = Item.Product.InventoryOrExpenseAccount.CashFlowSection;
						Record.PaymentMethod = VoidingEntry.PaymentMethod;
						Record.AmountRC = ((Item.LineTotal * ExchangeRate) * CurRowLineItems.AmountCr)/CurRowLineItems.VoidedEntry.DocumentTotalRC;
					EndDo;
					
				EndIf;

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
					
					//If entry is used for voiding, take the lineitem's voided document
					If VoidingEntry <> Undefined Then
						Record.ExtDimensions[ChartsOfCharacteristicTypes.Dimensions.Document] = CurRowLineItems.VoidedEntry;
					Else
						Record.ExtDimensions[ChartsOfCharacteristicTypes.Dimensions.Document] = Ref;
					EndIf;
					
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
	
	
	TotalDr = LineItems.Total("AmountDr");
	TotalCr = LineItems.Total("AmountCr"); 
	If TotalDr <> TotalCr Then
		Message = New UserMessage();
		Message.Text = NStr("en='Balance The Transaction'");
		Message.Message();
		Cancel = True;
        Return;
	//ElsIf Constants.MultiCurrency.Get() Then 
	ElsIf (Not Currency.IsEmpty()) And (Currency <> Constants.DefaultCurrency.Get()) Then 	
		DocumentPosting.FixUnbalancedRegister(ThisObject,Cancel,Constants.ExchangeLoss.Get());
	Else 
		CheckedValueTable = RegisterRecords.GeneralJournal.Unload();
		UnbalancedAmount = 0;
		If Not DocumentPosting.IsValueTableBalanced(CheckedValueTable, UnbalancedAmount) Then 
			Cancel = True;
			// Generate error message.
			MessageText = NStr("en = 'The document %1 cannot be posted, because it''s transaction is unbalanced.'");
			MessageText = StringFunctionsClientServer.SubstituteParametersInString(MessageText, Ref);
			CommonUseClientServer.MessageToUser(MessageText, Ref,,, Cancel);
		EndIf;		
	EndIf;
	
	//Writing bank reconciliation data
	LineItemsGroupped = LineItems.Unload(, "Account, AmountDr, AmountCr");
	LineItemsGroupped.Columns.Add("AccountType", New TypeDescription("EnumRef.AccountTypes"));
	For Each LineItem In LineItemsGroupped Do
		LineItem.AccountType = LineItem.Account.AccountType;
	EndDo;
	LineItemsGroupped.GroupBy("AccountType, Account", "AmountDr, AmountCr");
	For Each BankRow In LineItemsGroupped Do
		If (BankRow.AccountType = Enums.AccountTypes.Bank) OR (BankRow.AccountType = Enums.AccountTypes.OtherCurrentAsset)
			OR (BankRow.AccountType = Enums.AccountTypes.OtherCurrentLiability) Then
			ReconciledDocumentsServerCall.AddDocumentForReconciliation(RegisterRecords, Ref, BankRow.Account, Date, BankRow.AmountDr-BankRow.AmountCr);
		EndIf;
	EndDo;
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	// Forced assign the new document number.
	If ThisObject.IsNew() And Not ValueIsFilled(ThisObject.Number) Then ThisObject.SetNewNumber(); EndIf;
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	// Forced assign the new document number.
	If ThisObject.IsNew() Then ThisObject.SetNewNumber(); EndIf;
	
EndProcedure

Procedure OnSetNewNumber(StandardProcessing, Prefix)
	
	StandardProcessing = False;
	
	Numerator = Catalogs.DocumentNumbering.JournalEntry;
	NextNumber = GeneralFunctions.Increment(Numerator.Number);
	
	While Documents.GeneralJournalEntry.FindByNumber(NextNumber) <> Documents.GeneralJournalEntry.EmptyRef() And NextNumber <> "" Do
		ObjectNumerator = Numerator.GetObject();
		ObjectNumerator.Number = NextNumber;
		ObjectNumerator.Write();
		
		NextNumber = GeneralFunctions.Increment(NextNumber);
	EndDo;
	
	ThisObject.Number = NextNumber; 

EndProcedure

#EndIf

#EndRegion
