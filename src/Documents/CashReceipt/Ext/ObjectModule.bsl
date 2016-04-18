
// The procedure posts a cash receipt document. Different transactions are creating depending whether the deposit type is
// 1 for an undeposited funds account, and 2 for a bank account, also an FX gain or loss is calculated and posted.
//
Procedure Posting(Cancel, PostingMode)
	
	//Clear register records
	For Each RecordSet In RegisterRecords Do
		RecordSet.Read();
		If RecordSet.Count() > 0 Then
			RecordSet.Write = True;
			RecordSet.Clear();
			RecordSet.Write();
		EndIf;
	EndDo;
	
	If DepositType = "1" Then //Undeposited
		RegisterRecords.UndepositedDocuments.Write = True;
	
		Record = RegisterRecords.UndepositedDocuments.AddReceipt();
		Record.Period 	= Date;
		Record.Recorder = Ref;
		Record.Document = Ref;
		Record.Amount 	= CashPayment;
		Record.AmountRC = CashPayment*?(ExchangeRate=0,1,ExchangeRate);
	EndIf;
	
	RegisterRecords.OrderTransactions.Write = True;
	If SalesOrder <> Documents.SalesOrder.EmptyRef() Then
		Record = RegisterRecords.OrderTransactions.Add();
		Record.RecordType = AccumulationRecordType.Expense;
		Record.Period = Date;
		Try // temporary bugfix, untill in produstion will not be transfered "company" in accumulation register
			Record.Company = Company;
		Except
		EndTry;	
		Record.Order = SalesOrder;
		Record.Amount = CashPayment;
	EndIf;
	
	// Write records to General Journal and CashFlowData
	RegisterRecords.GeneralJournal.Write = True;
	RegisterRecords.CashFlowData.Write   = True;
	
	Payments         = 0;
	ExchangeGainLoss = 0;
	TodayRate        = GeneralFunctions.GetExchangeRate(Date, Company.DefaultCurrency);
	
	ExchangeLossAccount = Constants.ExchangeLoss.Get();
	
	
	//------------------------------------------------------------------------------------------------------------
	//TABULAR SECTION INVOICES------------------------------------------------------------------------------------
	//------------------------------------------------------------------------------------------------------------
	For Each DocumentLine In LineItems Do
		
		Payments = Payments + DocumentLine.Payment;
		DocRef   = DocumentLine.Document.Ref; 	
		
		//SalesInvoice--------------------------------------------------------------------------------------------
		//--------------------------------------------------------------------------------------------------------
		If TypeOf(DocRef) = Type("DocumentRef.SalesInvoice") Then
			
			//1.
			SumFirstTrans  = 0;
			SumSecondTrans = 0;
			
			RecordSet =  AccumulationRegisters.GeneralJournalAnalyticsDimensions.CreateRecordSet();
			RecordSet.Filter.Recorder.Set(DocRef);
			RecordSet.Read();
			
			For Each CurrentTrans In RecordSet Do
				If CurrentTrans.JournalEntryIntNum = 1 And CurrentTrans.JournalEntryMainRec Then
					SumFirstTrans  = SumFirstTrans + ?(CurrentTrans.RecordType = AccumulationRecordType.Receipt, CurrentTrans.AmountRC, CurrentTrans.AmountRC * -1);
				ElsIf  CurrentTrans.JournalEntryIntNum = 2 And CurrentTrans.JournalEntryMainRec Then 
					SumSecondTrans = SumSecondTrans + ?(CurrentTrans.RecordType = AccumulationRecordType.Receipt, CurrentTrans.AmountRC, CurrentTrans.AmountRC * -1);
				EndIf;
			EndDo;
			
			//2.
			FirstFullPaymentAmountRC  = Round(DocumentLine.Payment * DocRef.ExchangeRate, 2) + Round(DocumentLine.Discount * DocRef.ExchangeRate, 2);
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
						Record.RecordType    = CurrentTrans.RecordType;
						Record.Period        = Date;
						Record.Account       = CurrentTrans.Account;
						Record.Company       = Company;
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
				Record.Company       = Company;
				Record.Document      = DocRef;
				Record.SalesPerson   = DocRef.SalesPerson;
				Record.Class         = Null;
				Record.Project       = Null;
				Record.AmountRC      = ?(ARAmount > 0, ARAmount, ARAmount * -1);
				Record.PaymentMethod = Null;
			EndIf;
			
		//PurchaseReturn------------------------------------------------------------------------------------------
		//--------------------------------------------------------------------------------------------------------
		ElsIf TypeOf(DocRef) = Type("DocumentRef.PurchaseReturn") Then
			
			//1.
			SumFirstTrans = 0;
			
			RecordSet =  AccumulationRegisters.GeneralJournalAnalyticsDimensions.CreateRecordSet();
			RecordSet.Filter.Recorder.Set(DocRef);
			RecordSet.Read();
			
			For Each CurrentTrans In RecordSet Do
				If CurrentTrans.RecordType = AccumulationRecordType.Expense
					AND CurrentTrans.Account.AccountType <> Enums.AccountTypes.AccountsReceivable 
					AND CurrentTrans.Account.AccountType <> Enums.AccountTypes.AccountsPayable Then
					SumFirstTrans  = SumFirstTrans + ?(CurrentTrans.RecordType = AccumulationRecordType.Expense, CurrentTrans.AmountRC, CurrentTrans.AmountRC * -1);
				EndIf;
			EndDo;
			
			//2.
			FirstFullPaymentAmountRC  = Round(DocumentLine.Payment * DocRef.ExchangeRate, 2) + Round(DocumentLine.Discount * DocRef.ExchangeRate, 2);
			FirstBalancePaymentRC     = FirstFullPaymentAmountRC;
			
			ActualSumFirstTrans       = 0;
			APAmount                  = 0;
			
			For Each CurrentTrans In RecordSet Do
				If CurrentTrans.RecordType = AccumulationRecordType.Expense
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
						Record.RecordType    = CurrentTrans.RecordType;
						Record.Period        = Date;
						Record.Account       = CurrentTrans.Account;
						Record.Company       = Company;
						Record.Document      = DocRef;
						Record.SalesPerson   = Null;
						Record.Class         = CurrentTrans.Class;
						Record.Project       = CurrentTrans.Project;
						Record.AmountRC      = CurrentPaymentRC;
						Record.PaymentMethod = Null;
						
						APAmount = APAmount + ?(Record.RecordType = AccumulationRecordType.Receipt, Record.AmountRC * -1, Record.AmountRC); 
					EndIf;
					
				EndIf;
			EndDo;
			
			If APAmount <> 0 Then
				Record = RegisterRecords.CashFlowData.Add();
				Record.RecordType    = ?(APAmount > 0, AccumulationRecordType.Receipt, AccumulationRecordType.Expense);
				Record.Period        = Date;
				Record.Account       = DocRef.APAccount;
				Record.Company       = Company;
				Record.Document      = DocRef;
				Record.SalesPerson   = Null;
				Record.Class         = Null;
				Record.Project       = Null;
				Record.AmountRC      = ?(APAmount > 0, APAmount, APAmount * -1);
				Record.PaymentMethod = Null;
			EndIf;
			
		EndIf;
		
		//--------------------------------------------------------------------------------------------------------------------------
		DocumentObject = DocumentLine.Document.GetObject();		
		
		If TypeOf(DocumentObject.Ref) = Type("DocumentRef.SalesInvoice") Then
			DocumentObjectAccount = DocumentObject.ARAccount;
		ElsIf TypeOf(DocumentObject.Ref) = Type("DocumentRef.Check") Then
			DocumentObjectAccount = ARAccount;				
		ElsIf TypeOf(DocumentObject.Ref) = Type("DocumentRef.PurchaseReturn") Then
			DocumentObjectAccount = DocumentObject.APAccount;			
		ElsIf TypeOf(DocumentObject.Ref) = Type("DocumentRef.GeneralJournalEntry") Then
			DocumentObjectAccount = ARAccount;				
		EndIf;
		
		Record = RegisterRecords.GeneralJournal.AddCredit();
		Record.Period      = Date;
		Record.Account     = DocumentObjectAccount;
		Record.Currency    = Currency;
		Record.Amount      = DocumentLine.Payment + DocumentLine.Discount;
		ExchangeDifference = Round(DocumentLine.Payment * ExchangeRate, 2) - Round(DocumentLine.Payment * DocumentLine.Document.ExchangeRate, 2)
								+ Round(DocumentLine.Discount * ExchangeRate, 2) - Round(DocumentLine.Discount * DocumentLine.Document.ExchangeRate, 2);
		Record.AmountRC    = Round(DocumentLine.Payment * ExchangeRate, 2) + Round(DocumentLine.Discount * ExchangeRate, 2) - ExchangeDifference; 
		Record.ExtDimensions[ChartsOfCharacteristicTypes.Dimensions.Company]  = Company;
		Record.ExtDimensions[ChartsOfCharacteristicTypes.Dimensions.Document] = DocumentObject.Ref;
		
		//--//GJ++
		ReconciledDocumentsServerCall.AddRecordForGeneralJournalAnalyticsDimensions(RegisterRecords, Record, Null, Null, Company);
		//--//GJ--
	
		If ExchangeDifference > 0 Then // New amount smaller - increase Ct
			Record = RegisterRecords.GeneralJournal.AddCredit();
			Record.Account  = ExchangeLossAccount;
			Record.Period   = Date;
			Record.AmountRC = ExchangeDifference;
			
			//--//GJ++
			ReconciledDocumentsServerCall.AddRecordForGeneralJournalAnalyticsDimensions(RegisterRecords, Record, Null, Null, Company);
			//--//GJ--
						
		ElsIf ExchangeDifference < 0 Then // new amount bigger - increase Dt
			Record = RegisterRecords.GeneralJournal.AddDebit();
			Record.Account  = ExchangeLossAccount;
			Record.Period   = Date;
			Record.AmountRC = -ExchangeDifference;
			
			//--//GJ++
			ReconciledDocumentsServerCall.AddRecordForGeneralJournalAnalyticsDimensions(RegisterRecords, Record, Null, Null, Company);
			//--//GJ--
			
		EndIf;
	
	EndDo;
	//------------------------------------------------------------------------------------------------------------
	//TABULAR SECTION INVOICES (end)------------------------------------------------------------------------------
	//------------------------------------------------------------------------------------------------------------
	
	
	DefaultCurrency = GeneralFunctionsReusable.DefaultCurrency();
	CompanyCurrency = Company.DefaultCurrency;
		
	Credits = 0;
	
	
	//------------------------------------------------------------------------------------------------------------
	//TABULAR SECTION CREDITS-------------------------------------------------------------------------------------
	//------------------------------------------------------------------------------------------------------------
	For Each CreditLine In CreditMemos Do
		
		DocumentObject = CreditLine.Document.GetObject();	
		DocRef         = CreditLine.Document.Ref; 	
		
		//SalesReturn---------------------------------------------------------------------------------------------
		//--------------------------------------------------------------------------------------------------------
		If TypeOf(DocRef) = Type("DocumentRef.SalesReturn") Then
			
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
			FirstFullPaymentAmountRC  = Round(CreditLine.Payment * DocRef.ExchangeRate, 2);
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
						Record.RecordType    = CurrentTrans.RecordType;
						Record.Period        = Date;
						Record.Account       = CurrentTrans.Account;
						Record.Company       = Company;
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
				Record.Company       = Company;
				Record.Document      = DocRef;
				Record.SalesPerson   = DocRef.SalesPerson;
				Record.Class         = Null;
				Record.Project       = Null;
				Record.AmountRC      = ?(ARAmount > 0, ARAmount, ARAmount * -1);
				Record.PaymentMethod = Null;
			EndIf;

		//CashReceipt---------------------------------------------------------------------------------------------
		//--------------------------------------------------------------------------------------------------------
		ElsIf TypeOf(DocumentObject.Ref) = Type("DocumentRef.CashReceipt") Then
			
			DocumentObjectAccount = DocumentObject.ARAccount;	
						
		//Deposit-------------------------------------------------------------------------------------------------
		//--------------------------------------------------------------------------------------------------------
		ElsIf TypeOf(DocumentObject.Ref) = Type("DocumentRef.Deposit") Then
			
			DocumentObjectAccount = ARAccount;	
			
		//GeneralJournalEntry-------------------------------------------------------------------------------------
		//--------------------------------------------------------------------------------------------------------
		ElsIf TypeOf(DocumentObject.Ref) = Type("DocumentRef.GeneralJournalEntry") Then
			
			DocumentObjectAccount = ARAccount;		
			
		EndIf;

		DocumentObjectAmount   = CreditLine.Payment;
		DocumentObjectAmountRC = CreditLine.Payment;
		Credits = Credits + CreditLine.Payment;
		
		Record = RegisterRecords.GeneralJournal.AddDebit();
		Record.Period   = Date;
		Record.Account  = DocumentObjectAccount;
		Record.Currency = Currency;
		Record.Amount   = CreditLine.Payment;
		If TypeOf(CreditLine.Document) = Type("DocumentRef.Deposit") Then
			ExchangeDifference = Round(CreditLine.Payment * ExchangeRate,2) - Round(CreditLine.Payment * 1,2);
		Else	
			ExchangeDifference = Round(CreditLine.Payment * ExchangeRate,2) - Round(CreditLine.Payment * CreditLine.Document.ExchangeRate,2);
		EndIf;	
		Record.AmountRC = CreditLine.Payment * ExchangeRate - ExchangeDifference;
		Record.ExtDimensions[ChartsOfCharacteristicTypes.Dimensions.Company]  = Company;
		Record.ExtDimensions[ChartsOfCharacteristicTypes.Dimensions.Document] = DocumentObject.Ref;
		
		//--//GJ++
		ReconciledDocumentsServerCall.AddRecordForGeneralJournalAnalyticsDimensions(RegisterRecords, Record, Null, Null, Company);
		//--//GJ--
		
		If ExchangeDifference < 0 Then
			Record = RegisterRecords.GeneralJournal.AddCredit();
			Record.Account = ExchangeLossAccount;
			Record.Period = Date;
			Record.AmountRC = - ExchangeDifference;
			
			//--//GJ++
			ReconciledDocumentsServerCall.AddRecordForGeneralJournalAnalyticsDimensions(RegisterRecords, Record, Null, Null, Company);
			//--//GJ--
						
		ElsIf ExchangeDifference > 0 Then
			Record = RegisterRecords.GeneralJournal.AddDebit();
			Record.Account = ExchangeLossAccount;
			Record.Period = Date;
			Record.AmountRC = ExchangeDifference;
			
			//--//GJ++
			ReconciledDocumentsServerCall.AddRecordForGeneralJournalAnalyticsDimensions(RegisterRecords, Record, Null, Null, Company);
			//--//GJ--
			
		EndIf;
		
		RegisterRecords.OrderTransactions.Write = True;
		If TypeOf(DocumentObject) = Type("DocumentRef.CashReceipt") Then
			If DocumentObject.Ref.SalesOrder <> Documents.SalesOrder.EmptyRef() Then			
				Record = RegisterRecords.OrderTransactions.Add();
				Record.RecordType = AccumulationRecordType.Receipt;
				Record.Period = Date;
				Try // temporary bugfix, untill in produstion will not be transfered "company" in accumulation register
					Record.Company = DocumentObject.Ref.Company;
				Except
				EndTry;	
				Record.Order = DocumentObject.Ref.SalesOrder;
				Record.Amount = CreditLine.Payment;
			EndIf
		EndIf;
		
	EndDo;
	//------------------------------------------------------------------------------------------------------------
	//TABULAR SECTION CREDITS (end)-------------------------------------------------------------------------------
	//------------------------------------------------------------------------------------------------------------
	
	
	PayTotal = 0;
	For Each LineItem In LineItems Do
		PayTotal =  PayTotal + LineItem.Payment;
	EndDo;
	
	If PayTotal = 0 And UnappliedPayment = 0 Then
		Message("No payment is being made.");
		Cancel = True;
		Return;
	EndIf;
	
	
	//BANK AMOUNT-------------------------------------------------------------------------------------------------
	//------------------------------------------------------------------------------------------------------------
	If DepositType = "1" Then 
		
		Record = RegisterRecords.GeneralJournal.AddDebit();
		Record.Period = Date;
		//++ MisA 11/17/2014
		Record.Account = BankAccount;
		If GeneralFunctionsReusable.CurrencyUsedAccountType(BankAccount.AccountType) Then 
			BankAccountCurency = BankAccount.Currency;
		Else 	
			BankAccountCurency = DefaultCurrency;
		EndIf;
		Record.Currency = BankAccountCurency;
		
		If BankAccountCurency = DefaultCurrency Then 
			Record.Amount = (Payments*ExchangeRate) + (UnappliedPayment*ExchangeRate) - (Credits*ExchangeRate);  //MisA RC amount correct
		ElsIf BankAccountCurency = Company.DefaultCurrency Then 
			Record.Amount =  Payments - Credits + UnappliedPayment; // amount stays same
		Else // Need to calc cross-rate
			Rate1 = ExchangeRate; // base rate
			Rate2 = GeneralFunctions.GetExchangeRate(Date, BankAccountCurency); // Account Rate
			CrossRate = (Rate1/Rate2); // Rate2 Can't be 0, because of function GetExchangeRate. 
			Record.Amount = (Payments*CrossRate) + (UnappliedPayment*CrossRate) - (Credits*CrossRate);  //MisA Cross-Rate
		EndIf;
		
		Record.AmountRC = (Payments*ExchangeRate) + (UnappliedPayment*ExchangeRate) - (Credits*ExchangeRate);  //MisA RC amount correct
		
		//--//GJ++
		ReconciledDocumentsServerCall.AddRecordForGeneralJournalAnalyticsDimensions(RegisterRecords, Record, Null, Null, Company);
		//--//GJ--
		
	ElsIf DepositType = "2" Then 
		
		Record = RegisterRecords.GeneralJournal.AddDebit();
		Record.Period = Date;
		Record.Account = BankAccount;
		//++ MisA 11/19/2014
		Record.Currency = BankAccount.Currency; 
		BankAccountCurency = BankAccount.Currency;
		
		If BankAccountCurency = DefaultCurrency Then 
			Record.Amount = (Payments*ExchangeRate) + (UnappliedPayment*ExchangeRate) - (Credits*ExchangeRate);  //MisA RC amount correct
		ElsIf BankAccountCurency = Company.DefaultCurrency Then 
			Record.Amount =  Payments - Credits + UnappliedPayment; // amount stays same
		Else // Need to calc cross-rate
			Rate1 = ExchangeRate; // base rate
			Rate2 = GeneralFunctions.GetExchangeRate(Date, BankAccountCurency); // Account Rate
			CrossRate = (Rate1/Rate2); // Rate2 Can't be 0, because of function GetExchangeRate. 
			Record.Amount = (Payments*CrossRate) + (UnappliedPayment*CrossRate) - (Credits*CrossRate);  //MisA Cross-Rate
		EndIf;
		
		Record.AmountRC = (Payments*ExchangeRate) + (UnappliedPayment*ExchangeRate) - (Credits*ExchangeRate);
		//-- MisA 11/19/2014
		
		//--//GJ++
		ReconciledDocumentsServerCall.AddRecordForGeneralJournalAnalyticsDimensions(RegisterRecords, Record, Null, Null, Company);
		//--//GJ--
		
	EndIf;
	//------------------------------------------------------------------------------------------------------------
	//BANK AMOUNT (end)-------------------------------------------------------------------------------------------
	
	
	// Writing bank reconciliation data 
	If DepositType = "2" Then
		ReconciledDocumentsServerCall.AddDocumentForReconciliation(RegisterRecords, Ref, BankAccount, Date, CashPayment);
	EndIf;
	
	
	//UNAPPLIED PAYMENTS------------------------------------------------------------------------------------------
	//------------------------------------------------------------------------------------------------------------
	If UnappliedPayment > 0  Then
		
		DefaultCurrency = GeneralFunctionsReusable.DefaultCurrency();
		Record = RegisterRecords.GeneralJournal.AddCredit();
		Record.Period   = Date;
		Record.Account  = ARAccount;
		Record.Currency = Company.DefaultCurrency;
		Record.Amount   = UnappliedPayment;                // MisA 11/19/2014 Amount in same currency as the customer default
		Record.AmountRC = UnappliedPayment * ExchangeRate; // MisA 11/19/2014, changed rate to pre-defined customer rate
		Record.ExtDimensions[ChartsOfCharacteristicTypes.Dimensions.Company]  = Company;
		Record.ExtDimensions[ChartsOfCharacteristicTypes.Dimensions.Document] = Ref;
		
		//--//GJ++
		ReconciledDocumentsServerCall.AddRecordForGeneralJournalAnalyticsDimensions(RegisterRecords, Record, Null, Null, Company);
		//--//GJ--		
		
	EndIf;
	//------------------------------------------------------------------------------------------------------------
	//UNAPPLIED PAYMENTS (end)------------------------------------------------------------------------------------
	
	
	//DISCOUNTS---------------------------------------------------------------------------------------------------
	//------------------------------------------------------------------------------------------------------------
	If DiscountAmount > 0  Then
		
		DefaultDiscountAccount = Constants.DiscountsAccount.Get();
		Record = RegisterRecords.GeneralJournal.AddDebit();
		Record.Period   = Date;
		Record.Account  = DefaultDiscountAccount;
		Record.Amount   = DiscountAmount;                  
		Record.AmountRC = DiscountAmount * ExchangeRate; 
		
		//--//GJ++
		ReconciledDocumentsServerCall.AddRecordForGeneralJournalAnalyticsDimensions(RegisterRecords, Record, Null, Null, Company);
		//--//GJ--		
		
	EndIf;
	//------------------------------------------------------------------------------------------------------------
	//DISCOUNTS (end)---------------------------------------------------------------------------------------------
	
	
	//SALES TAX---------------------------------------------------------------------------------------------------
	//------------------------------------------------------------------------------------------------------------
	RegisterRecords.SalesTaxOwed.Write        = True;
	RegisterRecords.SalesTaxOwedDetails.Write = True;
	// Create new managed data lock.
	DataLocks = New DataLock;
	
	// Set data lock parameters.
	SalesTaxOwedLock = DataLocks.Add("AccumulationRegister.SalesTaxOwed");
	SalesTaxOwedLock.Mode = DataLockMode.Exclusive;
	SalesTaxOwedDetailsLock = DataLocks.Add("InformationRegister.SalesTaxOwedDetails");
	SalesTaxOwedDetailsLock.Mode = DataLockMode.Exclusive;
	DataLocks.Lock();

	
	// Sales tax. Request data on how much sales tax was 
	// 1. charged/reversed for the accrual method
	// 2. charged/reversed for the cash method
	// for both LineItems and Credit Memos
	
	Request = New Query("SELECT
						|	GeneralJournalBalance.AmountBalance AS BalanceFCY,
						|	GeneralJournalBalance.ExtDimension2.Ref AS Document1,
						|	CashReceiptLineItems.Document AS Document,
						|	CashReceiptLineItems.Payment,
						|	CashReceiptLineItems.LineNumber,
						|	""LineItems"" AS TabularSection
						|INTO CashReceiptDocuments
						|FROM
						|	Document.CashReceipt.LineItems AS CashReceiptLineItems
						|		LEFT JOIN InformationRegister.ExchangeRates.SliceLast(&Date, ) AS ExchangeRates
						|		ON CashReceiptLineItems.Ref.Currency = ExchangeRates.Currency
						|		LEFT JOIN AccountingRegister.GeneralJournal.Balance(
						|				,
						|				Account IN
						|					(SELECT
						|						Document.SalesInvoice.ARAccount
						|					FROM
						|						Document.SalesInvoice
						|				
						|					UNION
						|				
						|					SELECT
						|						Document.PurchaseReturn.APAccount
						|					FROM
						|						Document.PurchaseReturn
						|					WHERE
						|						Document.PurchaseReturn.Company = &Company),
						|				,
						|				ExtDimension1 = &Company
						|					AND (ExtDimension2 REFS Document.SalesInvoice
						|						OR ExtDimension2 REFS Document.PurchaseReturn)) AS GeneralJournalBalance
						|		ON CashReceiptLineItems.Document = GeneralJournalBalance.ExtDimension2
						|WHERE
						|	CashReceiptLineItems.Ref = &CurrentDocument
						|
						|UNION ALL
						|
						|SELECT
						|	-GeneralJournalBalance.AmountBalance AS BalanceFCY2,
						|	GeneralJournalBalance.ExtDimension2.Ref AS Document1,
						|	CashReceiptCreditMemos.Document AS Document2,
						|	CashReceiptCreditMemos.Payment,
						|	CashReceiptCreditMemos.LineNumber,
						|	""CreditMemos"" AS TabularSection
						|FROM
						|  Document.CashReceipt.CreditMemos As CashReceiptCreditMemos
						|		LEFT JOIN InformationRegister.ExchangeRates.SliceLast(&Date, ) AS ExchangeRates
						|		ON CashReceiptCreditMemos.Ref.Currency = ExchangeRates.Currency
						|		LEFT JOIN AccountingRegister.GeneralJournal.Balance(
						|			,
						|			Account IN
						|				(SELECT
						|					Document.SalesReturn.ARAccount
						|				FROM
						|					Document.SalesReturn
						|				WHERE
						|					Document.SalesReturn.Company = &Company
						|					AND Document.SalesReturn.ReturnType = VALUE(Enum.ReturnTypes.CreditMemo)
						|			
						|				UNION
						|			
						|				SELECT
						|					Document.CashReceipt.ARAccount
						|				FROM
						|					Document.CashReceipt
						|				WHERE
						|					Document.CashReceipt.Company = &Company),
						|			,
						|			ExtDimension1 = &Company
						|				AND (ExtDimension2 REFS Document.SalesReturn
						|						AND ExtDimension2.ReturnType = VALUE(Enum.ReturnTypes.CreditMemo)
						|					OR ExtDimension2 REFS Document.CashReceipt)) AS GeneralJournalBalance
						|		ON CashReceiptCreditMemos.Document = GeneralJournalBalance.ExtDimension2
						|WHERE
						|	CashReceiptCreditMemos.Ref = &CurrentDocument;
	                    |
	                    |////////////////////////////////////////////////////////////////////////////////
	                    |SELECT
	                    |	CashReceiptDocuments.Document,
	                    |	CashReceiptDocuments.Payment,
	                    |	CashReceiptDocuments.BalanceFCY,
	                    |	CashReceiptDocuments.TabularSection,
	                    |	SalesTaxOwed.Agency,
	                    |	SalesTaxOwed.TaxRate,
	                    |	SalesTaxOwed.SalesTaxComponent,
	                    |	SUM(SalesTaxOwed.GrossSale) AS GrossSale,
	                    |	SUM(SalesTaxOwed.TaxableSale) AS TaxableSale,
	                    |	SUM(SalesTaxOwed.TaxPayable) AS TaxPayable
	                    |INTO AccruedSalesTax
	                    |FROM
	                    |	CashReceiptDocuments AS CashReceiptDocuments
	                    |		INNER JOIN AccumulationRegister.SalesTaxOwed AS SalesTaxOwed
	                    |		ON CashReceiptDocuments.Document = SalesTaxOwed.Recorder
	                    |			AND (SalesTaxOwed.ChargeType = VALUE(Enum.AccountingMethod.Accrual))
	                    |			AND (SalesTaxOwed.RecordType = VALUE(AccumulationRecordType.Receipt))
	                    |
	                    |GROUP BY
	                    |	CashReceiptDocuments.Document,
	                    |	CashReceiptDocuments.Payment,
	                    |	CashReceiptDocuments.TabularSection,
	                    |	SalesTaxOwed.Agency,
	                    |	SalesTaxOwed.TaxRate,
	                    |	CashReceiptDocuments.BalanceFCY,
	                    |	SalesTaxOwed.SalesTaxComponent
	                    |;
	                    |
	                    |////////////////////////////////////////////////////////////////////////////////
	                    |SELECT
	                    |	CashReceiptDocuments.Document,
	                    |	CashReceiptDocuments.Payment,
	                    |	CashReceiptDocuments.TabularSection,
	                    |	SalesTaxOwedDetails.Agency,
	                    |	SalesTaxOwedDetails.TaxRate,
	                    |	SalesTaxOwedDetails.SalesTaxComponent,
	                    |	SUM(SalesTaxOwedDetails.GrossSale) AS GrossSale,
	                    |	SUM(SalesTaxOwedDetails.TaxableSale) AS TaxableSale,
	                    |	SUM(SalesTaxOwedDetails.TaxPayable) AS TaxPayable
	                    |INTO CashedSalesTax
	                    |FROM
	                    |	CashReceiptDocuments AS CashReceiptDocuments
	                    |		LEFT JOIN InformationRegister.SalesTaxOwedDetails AS SalesTaxOwedDetails
	                    |		ON CashReceiptDocuments.Document = SalesTaxOwedDetails.ChargeDocument
	                    |
	                    |GROUP BY
	                    |	CashReceiptDocuments.Document,
	                    |	CashReceiptDocuments.Payment,
	                    |	CashReceiptDocuments.TabularSection,
	                    |	SalesTaxOwedDetails.Agency,
	                    |	SalesTaxOwedDetails.TaxRate,
	                    |	SalesTaxOwedDetails.SalesTaxComponent
	                    |;
	                    |
	                    |////////////////////////////////////////////////////////////////////////////////
	                    |SELECT
	                    |	AccruedSalesTax.Document,
	                    |	AccruedSalesTax.TabularSection,
	                    |	SUM(AccruedSalesTax.TaxPayable) AS TotalTaxPayable
	                    |INTO TotalTaxPayableTable
	                    |FROM
	                    |	AccruedSalesTax AS AccruedSalesTax
	                    |
	                    |GROUP BY
	                    |	AccruedSalesTax.Document,
	                    |	AccruedSalesTax.TabularSection
	                    |;
	                    |
	                    |////////////////////////////////////////////////////////////////////////////////
	                    |SELECT
	                    |	AccruedSalesTax.Document,
	                    |	REFPRESENTATION(AccruedSalesTax.Document),
	                    |	AccruedSalesTax.Payment,
	                    |	ISNULL(AccruedSalesTax.BalanceFCY, 0) AS BalanceFCY,
	                    |	AccruedSalesTax.TabularSection,
	                    |	AccruedSalesTax.Agency,
	                    |	AccruedSalesTax.TaxRate,
	                    |	AccruedSalesTax.SalesTaxComponent,
	                    |	AccruedSalesTax.GrossSale - ISNULL(CashedSalesTax.GrossSale, 0) AS GrossSaleNotCashed,
	                    |	AccruedSalesTax.TaxableSale - ISNULL(CashedSalesTax.TaxableSale, 0) AS TaxableSaleNotCashed,
	                    |	AccruedSalesTax.TaxPayable - ISNULL(CashedSalesTax.TaxPayable, 0) AS TaxPayableNotCashed,
	                    |	AccruedSalesTax.GrossSale AS GrossSale,
	                    |	AccruedSalesTax.TaxableSale AS TaxableSale,
	                    |	AccruedSalesTax.TaxPayable AS TaxPayable,
	                    |	ISNULL(TotalTaxPayableTable.TotalTaxPayable, 0) AS TotalTaxPayable
	                    |FROM
	                    |	AccruedSalesTax AS AccruedSalesTax
	                    |		LEFT JOIN CashedSalesTax AS CashedSalesTax
	                    |		ON AccruedSalesTax.Document = CashedSalesTax.Document
	                    |			AND AccruedSalesTax.TabularSection = CashedSalesTax.TabularSection
	                    |			AND AccruedSalesTax.Agency = CashedSalesTax.Agency
	                    |			AND AccruedSalesTax.TaxRate = CashedSalesTax.TaxRate
	                    |			AND AccruedSalesTax.SalesTaxComponent = CashedSalesTax.SalesTaxComponent
	                    |		LEFT JOIN TotalTaxPayableTable AS TotalTaxPayableTable
	                    |		ON AccruedSalesTax.TabularSection = TotalTaxPayableTable.TabularSection
	                    |			AND AccruedSalesTax.Document = TotalTaxPayableTable.Document");
	Request.SetParameter("CurrentDocument", ThisObject.Ref);
	Request.SetParameter("Date",  ?(ValueIsFilled(ThisObject.Ref), ThisObject.Date, CurrentSessionDate()));			 
	Request.SetParameter("Company", ThisObject.Company);
	
	CashBasedSalesTax = Request.Execute().Unload();
	
	//Posting CreditMemos tabular section
	CreditMemosRows = CashBasedSalesTax.FindRows(New Structure("TabularSection", "CreditMemos"));	
	For Each CreditMemosRow In CreditMemosRows Do
		//If no sales tax then continue
		If (CreditMemosRow.Payment = 0) Or (CreditMemosRow.GrossSale = 0) Or (CreditMemosRow.TotalTaxPayable = 0) Then 
			Continue;
		EndIf;
		
		If CreditMemosRow.BalanceFCY - CreditMemosRow.Payment > 0 Then //Proportional sales tax charging
			ProportionalSalesTaxRate 	= CreditMemosRow.TotalTaxPayable / (CreditMemosRow.GrossSale + CreditMemosRow.TotalTaxPayable);
			CombinedSalesTaxRate		= CreditMemosRow.TotalTaxPayable / CreditMemosRow.TaxableSale;
			TotalTaxPayable 	= Round(CreditMemosRow.Payment * ProportionalSalesTaxRate, 2);
			GrossSale 	= CreditMemosRow.Payment - TotalTaxPayable;
			TaxableSale = Round(TotalTaxPayable/CombinedSalesTaxRate, 2);
			TaxPayable 	= TaxableSale * CreditMemosRow.TaxRate / 100;						
		Else  //Charging sales tax left
			GrossSale 	= CreditMemosRow.GrossSaleNotCashed;
			TaxableSale = CreditMemosRow.TaxableSaleNotCashed;
			TaxPayable 	= CreditMemosRow.TaxPayableNotCashed; 
		EndIf;
		
		//SalesTaxOwed
		NewRecord					= RegisterRecords.SalesTaxOwed.AddReceipt();
		NewRecord.Period			= Date;
		NewRecord.ChargeType		= Enums.AccountingMethod.Cash;
		NewRecord.Agency			= CreditMemosRow.Agency;
		NewRecord.TaxRate			= CreditMemosRow.TaxRate;
		NewRecord.SalesTaxComponent	= CreditMemosRow.SalesTaxComponent;
		NewRecord.GrossSale			= GrossSale;
		NewRecord.TaxableSale		= TaxableSale;
		NewRecord.TaxPayable		= TaxPayable;
		NewRecord.Reason			= CreditMemosRow.DocumentPresentation;
		//SalesTaxOwedDetails
		NewRecord 					= RegisterRecords.SalesTaxOwedDetails.Add();	
		NewRecord.Active 			= True;
		NewRecord.RecorderDocument	= ThisObject.Ref;
		NewRecord.ChargeDocument 	= CreditMemosRow.Document;
		NewRecord.Agency			= CreditMemosRow.Agency;
		NewRecord.TaxRate 			= CreditMemosRow.TaxRate;
		NewRecord.SalesTaxComponent	= CreditMemosRow.SalesTaxComponent;
		NewRecord.GrossSale 		= GrossSale;
		NewRecord.TaxableSale		= TaxableSale;
		NewRecord.TaxPayable		= TaxPayable;
	EndDo;
	
	//Posting LineItems tabular section
	LineItemsRows = CashBasedSalesTax.FindRows(New Structure("TabularSection", "LineItems"));	
	For Each LineItemsRow In LineItemsRows Do
		//If no sales tax then continue
		If (LineItemsRow.Payment = 0) Or (LineItemsRow.GrossSale = 0) Or (LineItemsRow.TotalTaxPayable = 0) Then 
			Continue;
		EndIf;
		
		If LineItemsRow.BalanceFCY - LineItemsRow.Payment > 0 Then //Proportional sales tax charging
			ProportionalSalesTaxRate 	= LineItemsRow.TotalTaxPayable / (LineItemsRow.GrossSale + LineItemsRow.TotalTaxPayable);
			CombinedSalesTaxRate		= LineItemsRow.TotalTaxPayable / LineItemsRow.TaxableSale;
			TotalTaxPayable 	= Round(LineItemsRow.Payment * ProportionalSalesTaxRate, 2);
			GrossSale 	= LineItemsRow.Payment - TotalTaxPayable;
			TaxableSale = Round(TotalTaxPayable/CombinedSalesTaxRate, 2);
			TaxPayable 	= TaxableSale * LineItemsRow.TaxRate / 100;						
		Else  //Charging sales tax left
			GrossSale 	= LineItemsRow.GrossSaleNotCashed;
			TaxableSale = LineItemsRow.TaxableSaleNotCashed;
			TaxPayable 	= LineItemsRow.TaxPayableNotCashed; 
		EndIf;
		
		//SalesTaxOwed
		NewRecord					= RegisterRecords.SalesTaxOwed.AddReceipt();
		NewRecord.Period			= Date;
		NewRecord.ChargeType		= Enums.AccountingMethod.Cash;
		NewRecord.Agency			= LineItemsRow.Agency;
		NewRecord.TaxRate			= LineItemsRow.TaxRate;
		NewRecord.SalesTaxComponent	= LineItemsRow.SalesTaxComponent;
		NewRecord.GrossSale			= GrossSale;
		NewRecord.TaxableSale		= TaxableSale;
		NewRecord.TaxPayable		= TaxPayable;
		NewRecord.Reason			= LineItemsRow.DocumentPresentation;
		//SalesTaxOwedDetails
		NewRecord 					= RegisterRecords.SalesTaxOwedDetails.Add();	
		NewRecord.Active 			= True;
		NewRecord.RecorderDocument	= ThisObject.Ref;
		NewRecord.ChargeDocument 	= LineItemsRow.Document;
		NewRecord.Agency			= LineItemsRow.Agency;
		NewRecord.TaxRate 			= LineItemsRow.TaxRate;
		NewRecord.SalesTaxComponent	= LineItemsRow.SalesTaxComponent;
		NewRecord.GrossSale 		= GrossSale;
		NewRecord.TaxableSale		= TaxableSale;
		NewRecord.TaxPayable		= TaxPayable;
	EndDo;
	//------------------------------------------------------------------------------------------------------------
	//SALES TAX (end)---------------------------------------------------------------------------------------------
	
	
	//CASH BASIS--------------------------------------------------------------------------------------------------
	//------------------------------------------------------------------------------------------------------------
	For Each CurrentTrans In RegisterRecords.GeneralJournalAnalyticsDimensions Do
		
		Record = RegisterRecords.CashFlowData.Add();
		Record.RecordType    = CurrentTrans.RecordType;
		Record.Period        = CurrentTrans.Period;
		Record.Account       = CurrentTrans.Account;
		Record.Company       = CurrentTrans.Company;
		Record.Document      = Ref;
		Record.SalesPerson   = Null;
		Record.Class         = CurrentTrans.Class;
		Record.Project       = CurrentTrans.Project;
		Record.AmountRC      = CurrentTrans.AmountRC;
		Record.PaymentMethod = Null;
		
	EndDo;
	//------------------------------------------------------------------------------------------------------------
	//CASH BASIS (end)--------------------------------------------------------------------------------------------
	
	
	//If Constants.MultiCurrency.Get() Then 
	If (Not Currency.IsEmpty()) And (Currency <> Constants.DefaultCurrency.Get()) Then 
		DocumentPosting.FixUnbalancedRegister(ThisObject,Cancel,ExchangeLossAccount);
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
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If NewObject = True Then
		NewObject = False;
	Else
		If Ref = Documents.CashReceipt.EmptyRef() Then
			NewObject = True;
		EndIf;
	EndIf;
	
	If ExchangeRate = 0 Then    
 		ExchangeRate = GeneralFunctions.GetExchangeRate(Date, Company.DefaultCurrency);  
 	EndIf;

	
	// Document date adjustment patch (tunes the date of drafts like for the new documents).
	If  WriteMode = DocumentWriteMode.Posting And Not Posted // Posting of new or draft (saved but unposted) document.
	And BegOfDay(Date) = BegOfDay(CurrentSessionDate()) Then // Operational posting (by the current date).
		// Shift document time to the time of posting.
		Date = CurrentSessionDate();
	EndIf;
	
	//Check whether the document is deposited or not (for the undeposited type only)
	
	// Create new managed data lock.
	DataLock = New DataLock;

	// Set data lock parameters.
	LockItem = DataLock.Add("AccumulationRegister.UndepositedDocuments");
	LockItem.Mode = DataLockMode.Exclusive;
	LockItem.SetValue("Document", Ref);
	// Set lock on the object.
	DataLock.Lock();

	If Posted Then
		Request = New Query("SELECT
		                    |	UndepositedDocuments.Amount,
		                    |	UndepositedDocuments.AmountRC,
		                    |	UndepositedDocuments.Recorder.Presentation,
		                    |	CashReceipt.Date,
		                    |	CashReceipt.DepositType
		                    |FROM
		                    |	AccumulationRegister.UndepositedDocuments AS UndepositedDocuments
		                    |		LEFT JOIN Document.CashReceipt AS CashReceipt
		                    |		ON UndepositedDocuments.Document = CashReceipt.Ref
		                    |WHERE
		                    |	UndepositedDocuments.Document = &CurrentDocument
		                    |	AND UndepositedDocuments.RecordType = VALUE(AccumulationRecordType.Expense)");
		Request.SetParameter("CurrentDocument", Ref);
		Sel = Request.Execute().Select();
		If Sel.Next() Then
			If Sel.Amount <> CashPayment Then
				CommonUseClientServer.MessageToUser("The document is deposited. Cash payment amount (" + Format(CashPayment, "NFD=2; NZ=") + ") differs from the deposited amount (" + Format(Sel.Amount, "NFD=2; NZ=") + "). Unpost the Deposit document " + Sel.RecorderPresentation + " first.", ThisObject,, "Object.CashPayment", Cancel); 
			ElsIf Sel.Date <> Date Or Sel.DepositType <> DepositType Then
				CommonUseClientServer.MessageToUser("The document is deposited. Unpost the Deposit document " + Sel.RecorderPresentation + " first.", ThisObject,,, Cancel); 	
			EndIf;
		EndIf;
	EndIf;
		
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	// Set the doc's number if it's new (Rupasov)
	If ThisObject.IsNew() Then ThisObject.SetNewNumber() EndIf;
	
	// Filling new document or filling on the base of another document.
	If FillingData = Undefined Then
		// Filling of the new created document with default values.
		//ExchangeRate     = GeneralFunctions.GetExchangeRate(Date, Currency);
		//Location         = Catalogs.Locations.MainWarehouse;
		Currency = Constants.DefaultCurrency.Get();
		
	Else
		// Generate on the base of another document.
	EndIf;


EndProcedure