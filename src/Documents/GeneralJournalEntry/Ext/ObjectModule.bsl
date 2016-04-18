
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
				
	//Posting General journal
	RegisterRecords.GeneralJournal.Write = True;

	For Each CurRowLineItems In LineItems Do
		
		Amount = 0;
		
		If CurRowLineItems.AmountDr > 0 Then
			Record = RegisterRecords.GeneralJournal.AddDebit();
			Amount = CurRowLineItems.AmountDr;
		Else
			Record = RegisterRecords.GeneralJournal.AddCredit();
			Amount = CurRowLineItems.AmountCr;
		EndIf;
		
		Record.Period   = Date;
		Record.Account  = CurRowLineItems.Account;
		Record.AmountRC = Amount * ExchangeRate;
		Record.Memo     = CurRowLineItems.Memo;
		
		If Record.Account.AccountType = Enums.AccountTypes.Bank
			OR Record.Account.AccountType = Enums.AccountTypes.AccountsPayable
			OR Record.Account.AccountType = Enums.AccountTypes.AccountsReceivable Then
			
			Record.Currency = Record.Account.Currency;
			Record.Amount   = Amount;
			
		EndIf;	
		
		If Record.Account.AccountType = Enums.AccountTypes.AccountsPayable
			OR Record.Account.AccountType = Enums.AccountTypes.AccountsReceivable Then
			
			Record.ExtDimensions[ChartsOfCharacteristicTypes.Dimensions.Company]      = CurRowLineItems.Company;
			
			//If entry is used for voiding, take the lineitem's voided document
			If VoidingEntry <> Undefined Then
				Record.ExtDimensions[ChartsOfCharacteristicTypes.Dimensions.Document] = CurRowLineItems.VoidedEntry;
			Else
				Record.ExtDimensions[ChartsOfCharacteristicTypes.Dimensions.Document] = Ref;
			EndIf;
			
		EndIf;
		
		//--//GJ++
		CurrentCompany = ?(ValueIsFilled(VoidingEntry), VoidingEntry.Company, CurRowLineItems.Company);
		ReconciledDocumentsServerCall.AddRecordForGeneralJournalAnalyticsDimensions(RegisterRecords, Record, CurRowLineItems.Class, CurRowLineItems.Project, CurrentCompany);
		//--//GJ--
		
	EndDo;
	
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
	
	
	//CASH BASIS--------------------------------------------------------------------------------------------------
	//------------------------------------------------------------------------------------------------------------
	RegisterRecords.CashFlowData.Write = True;
	
	//1.
	If ValueIsFilled(VoidingEntry) Then
		For Each CurrentRow In LineItems Do
			
			DocRef             = CurrentRow.VoidedEntry;
			CurrentRowAmountRC = Round(?(CurrentRow.AmountCr <> 0, CurrentRow.AmountCr, CurrentRow.AmountDr) * DocRef.ExchangeRate, 2);
			
			If ValueIsFilled(DocRef) Then
				
				//PurchaseInvoice-----------------------------------------------------------------------------------------
				//--------------------------------------------------------------------------------------------------------
				If TypeOf(DocRef) = Type("DocumentRef.PurchaseInvoice")
					And CurrentRow.Account.AccountType = Enums.AccountTypes.AccountsPayable Then
					
					//1.
					SumFirstTrans = 0;
					
					RecordSet =  AccumulationRegisters.GeneralJournalAnalyticsDimensions.CreateRecordSet();
					RecordSet.Filter.Recorder.Set(DocRef);
					RecordSet.Read();
					
					For Each CurrentTrans In RecordSet Do
						If CurrentTrans.RecordType = AccumulationRecordType.Receipt
							AND CurrentTrans.Account.AccountType <> Enums.AccountTypes.AccountsReceivable 
							AND CurrentTrans.Account.AccountType <> Enums.AccountTypes.AccountsPayable Then
							SumFirstTrans  = SumFirstTrans + ?(CurrentTrans.RecordType = AccumulationRecordType.Receipt, CurrentTrans.AmountRC, CurrentTrans.AmountRC * -1);
						EndIf;
					EndDo;
					
					//2.
					FirstFullPaymentAmountRC  = CurrentRowAmountRC;
					FirstBalancePaymentRC     = FirstFullPaymentAmountRC;
					
					ActualSumFirstTrans       = 0;
					APAmount                  = 0;
					
					For Each CurrentTrans In RecordSet Do
						If CurrentTrans.RecordType = AccumulationRecordType.Receipt
							AND (CurrentTrans.Account.AccountType = Enums.AccountTypes.Income
							OR CurrentTrans.Account.AccountType = Enums.AccountTypes.CostOfSales
							OR CurrentTrans.Account.AccountType = Enums.AccountTypes.Expense
							OR CurrentTrans.Account.AccountType = Enums.AccountTypes.OtherIncome
							OR CurrentTrans.Account.AccountType = Enums.AccountTypes.OtherExpense
							OR CurrentTrans.Account.AccountType = Enums.AccountTypes.IncomeTaxExpense) Then
							
							PaymentRC        = 0;
							CurrentPaymentRC = 0;
							
							ActualSumFirstTrans    = ActualSumFirstTrans + CurrentTrans.AmountRC;
							PaymentRC              = ?(SumFirstTrans = 0, 0, Round(CurrentTrans.AmountRC * FirstFullPaymentAmountRC / SumFirstTrans, 2));
							CurrentPaymentRC       = ?(ActualSumFirstTrans = SumFirstTrans, FirstBalancePaymentRC, PaymentRC);
							FirstBalancePaymentRC  = FirstBalancePaymentRC - CurrentPaymentRC; 
							
							If CurrentPaymentRC <> 0 Then 
								Record = RegisterRecords.CashFlowData.Add();
								Record.RecordType    = ?(CurrentTrans.RecordType = AccumulationRecordType.Receipt, AccumulationRecordType.Expense, AccumulationRecordType.Receipt);
								Record.Period        = Date;
								Record.Account       = CurrentTrans.Account;
								Record.Company       = VoidingEntry.Company;
								Record.Document      = DocRef;
								Record.SalesPerson   = Null;
								Record.Class         = CurrentTrans.Class;
								Record.Project       = CurrentTrans.Project;
								Record.AmountRC      = CurrentPaymentRC;
								Record.PaymentMethod = VoidingEntry.PaymentMethod;
								
								APAmount = APAmount + ?(Record.RecordType = AccumulationRecordType.Receipt, Record.AmountRC * -1, Record.AmountRC); 
							EndIf;
							
						EndIf;
					EndDo;
					
					If APAmount <> 0 Then
						Record = RegisterRecords.CashFlowData.Add();
						Record.RecordType    = ?(APAmount > 0, AccumulationRecordType.Receipt, AccumulationRecordType.Expense);
						Record.Period        = Date;
						Record.Account       = DocRef.APAccount;
						Record.Company       = VoidingEntry.Company;
						Record.Document      = DocRef;
						Record.SalesPerson   = Null;
						Record.Class         = Null;
						Record.Project       = Null;
						Record.AmountRC      = ?(APAmount > 0, APAmount, APAmount * -1);
						Record.PaymentMethod = VoidingEntry.PaymentMethod;
					EndIf;
					
				//SalesReturn---------------------------------------------------------------------------------------------
				//--------------------------------------------------------------------------------------------------------
				ElsIf TypeOf(DocRef) = Type("DocumentRef.SalesReturn")
					And CurrentRow.Account.AccountType = Enums.AccountTypes.AccountsReceivable Then
					
					//1.
					SumFirstTrans  = 0;
					SumSecondTrans = 0;
					
					RecordSet =  AccumulationRegisters.GeneralJournalAnalyticsDimensions.CreateRecordSet();
					RecordSet.Filter.Recorder.Set(DocRef);
					RecordSet.Read();
					
					For Each CurrentTrans In RecordSet Do
						If CurrentTrans.JournalEntryIntNum = 1 And CurrentTrans.JournalEntryMainRec Then
							SumFirstTrans  = SumFirstTrans + ?(CurrentTrans.RecordType = AccumulationRecordType.Expense, CurrentTrans.AmountRC, CurrentTrans.AmountRC * -1);
						ElsIf  CurrentTrans.JournalEntryIntNum = 2 And CurrentTrans.JournalEntryMainRec Then 
							SumSecondTrans = SumSecondTrans + ?(CurrentTrans.RecordType = AccumulationRecordType.Expense, CurrentTrans.AmountRC, CurrentTrans.AmountRC * -1);
						EndIf;
					EndDo;
					
					//2.
					FirstFullPaymentAmountRC  = CurrentRowAmountRC;
					FirstBalancePaymentRC     = FirstFullPaymentAmountRC;
					
					SecondFullPaymentAmountRC = ?(SumFirstTrans = 0, 0, Round(SumSecondTrans * FirstFullPaymentAmountRC / SumFirstTrans, 2));
					SecondBalancePaymentRC    = SecondFullPaymentAmountRC;
					
					ActualSumFirstTrans       = 0;
					ActualSumSecondTrans      = 0;
					
					ARAmount                  = 0;
					
					For Each CurrentTrans In RecordSet Do
						If CurrentTrans.Account.AccountType = Enums.AccountTypes.Income
							OR CurrentTrans.Account.AccountType = Enums.AccountTypes.CostOfSales
							OR CurrentTrans.Account.AccountType = Enums.AccountTypes.Expense
							OR CurrentTrans.Account.AccountType = Enums.AccountTypes.OtherIncome
							OR CurrentTrans.Account.AccountType = Enums.AccountTypes.OtherExpense
							OR CurrentTrans.Account.AccountType = Enums.AccountTypes.IncomeTaxExpense
							OR CurrentTrans.Account = Constants.TaxPayableAccount.Get() Then
							
							PaymentRC        = 0;
							CurrentPaymentRC = 0;
							
							If CurrentTrans.JournalEntryIntNum = 1 Then
								
								ActualSumFirstTrans    = ActualSumFirstTrans + CurrentTrans.AmountRC;
								PaymentRC              = ?(SumFirstTrans = 0, 0, Round(CurrentTrans.AmountRC * FirstFullPaymentAmountRC / SumFirstTrans, 2));
								CurrentPaymentRC       = ?(ActualSumFirstTrans = SumFirstTrans, FirstBalancePaymentRC, PaymentRC);
								FirstBalancePaymentRC  = FirstBalancePaymentRC - CurrentPaymentRC; 
								
							ElsIf CurrentTrans.JournalEntryIntNum = 2 Then 
								
								ActualSumSecondTrans   = ActualSumSecondTrans + CurrentTrans.AmountRC;
								PaymentRC              = ?(SumSecondTrans = 0, 0, Round(CurrentTrans.AmountRC * SecondFullPaymentAmountRC / SumSecondTrans, 2));
								CurrentPaymentRC       = ?(ActualSumSecondTrans = SumSecondTrans, SecondBalancePaymentRC, PaymentRC);
								SecondBalancePaymentRC = SecondBalancePaymentRC - CurrentPaymentRC; 
								
							EndIf;
							
							If CurrentPaymentRC <> 0 Then 
								Record = RegisterRecords.CashFlowData.Add();
								Record.RecordType    = ?(CurrentTrans.RecordType = AccumulationRecordType.Receipt, AccumulationRecordType.Expense, AccumulationRecordType.Receipt);
								Record.Period        = Date;
								Record.Account       = CurrentTrans.Account;
								Record.Company       = VoidingEntry.Company;
								Record.Document      = DocRef;
								Record.SalesPerson   = DocRef.SalesPerson;
								Record.Class         = CurrentTrans.Class;
								Record.Project       = CurrentTrans.Project;
								Record.AmountRC      = CurrentPaymentRC;
								Record.PaymentMethod = Null;
								
								ARAmount = ARAmount + ?(Record.RecordType = AccumulationRecordType.Receipt, Record.AmountRC * -1, Record.AmountRC); 
							EndIf;
							
						EndIf;
					EndDo;
					
					If ARAmount <> 0 Then
						Record = RegisterRecords.CashFlowData.Add();
						Record.RecordType    = ?(ARAmount > 0, AccumulationRecordType.Receipt, AccumulationRecordType.Expense);
						Record.Period        = Date;
						Record.Account       = DocRef.ARAccount;
						Record.Company       = VoidingEntry.Company;
						Record.Document      = DocRef;
						Record.SalesPerson   = DocRef.SalesPerson;
						Record.Class         = Null;
						Record.Project       = Null;
						Record.AmountRC      = ?(ARAmount > 0, ARAmount, ARAmount * -1);
						Record.PaymentMethod = Null;
					EndIf;
					
				EndIf;
				
			EndIf;
			
		EndDo;
	EndIf;

	//2.
	For Each CurrentTrans In RegisterRecords.GeneralJournalAnalyticsDimensions Do
		
		Record = RegisterRecords.CashFlowData.Add();
		Record.RecordType    = CurrentTrans.RecordType;
		Record.Period        = CurrentTrans.Period;
		Record.Account       = CurrentTrans.Account;
		Record.Company       = CurrentTrans.Company;
		Record.Document      = ?(ValueIsFilled(VoidingEntry), VoidingEntry.Ref, Ref);
		Record.SalesPerson   = Null;
		Record.Class         = CurrentTrans.Class;
		Record.Project       = CurrentTrans.Project;
		Record.AmountRC      = CurrentTrans.AmountRC;
		Record.PaymentMethod = ?(ValueIsFilled(VoidingEntry), VoidingEntry.PaymentMethod, Null);
		
	EndDo;
	//------------------------------------------------------------------------------------------------------------
	//CASH BASIS (end)--------------------------------------------------------------------------------------------

	
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
	If Not DoNotReconcile Then
		LineItemsGroupped = LineItems.Unload(, "Account, AmountDr, AmountCr");
		LineItemsGroupped.GroupBy("Account", "AmountDr, AmountCr");
		For Each BankRow In LineItemsGroupped Do
			If (BankRow.Account.AccountType = Enums.AccountTypes.Bank)
				OR (BankRow.Account.AccountType = Enums.AccountTypes.OtherCurrentLiability And BankRow.Account.CreditCard = True) Then
				ReconciledDocumentsServerCall.AddDocumentForReconciliation(RegisterRecords, Ref, BankRow.Account, Date, BankRow.AmountDr-BankRow.AmountCr);
			EndIf;
		EndDo;
	EndIf;

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
