
#Region EVENT_HANDLERS

// The procedure posts a payment document. Also an FX gain or loss is calculated and posted.
//
Procedure Posting(Cancel, Mode)
	
	RegisterRecords.GeneralJournal.Write = True;
	RegisterRecords.CashFlowData.Write   = True;
	
	BankAmount  = 0;
	BankAmoutRC = 0;
	
	LineQuery = New Query;
	LineQuery.Text = Documents.InvoicePayment.GetLineItemsAccountsQuery() +
	";
	|SELECT
	|	InvoicePaymentLineItems.Payment,
	|	InvoicePaymentLineItems.Discount,
	|	InvoicePaymentLineItems.Document,
	|	InvoicePaymentLineItems.Document.Date As Date,
	|	InvoicePaymentLineItems.Currency,
	|	ISNULL(InvoicePaymentLineItems.Document.ExchangeRate, 0) AS ExchangeRate,
	|	CASE WHEN InvoicePaymentLineItems.Document REFS Document.PurchaseInvoice
	|		Then InvoicePaymentLineItems.Document.APAccount
	|	WHEN InvoicePaymentLineItems.Document REFS Document.SalesReturn
	|		Then InvoicePaymentLineItems.Document.ARAccount
	|	WHEN InvoicePaymentLineItems.Document REFS Document.Deposit
	|		Then GeneralJournalTurnovers.Account
	|	WHEN InvoicePaymentLineItems.Document REFS Document.GeneralJournalEntry
	|		Then GeneralJournalTurnovers.Account
	|	END AS Account
	|FROM
	|	Document.InvoicePayment.LineItems AS InvoicePaymentLineItems
	|		LEFT JOIN AccountingRegister.GeneralJournal.Turnovers(, , Recorder, Account IN (SELECT APAccount FROM TmpAccnts as TmpAccnts),, 
	//|		LEFT JOIN AccountingRegister.GeneralJournal.Turnovers(, , Recorder, Account IN (&Tst),, 
	|			ExtDimension1 = &Company AND
	|          (ExtDimension2 REFS Document.PurchaseInvoice 
	|			OR ExtDimension2 REFS Document.GeneralJournalEntry
	|			OR ExtDimension2 REFS Document.Deposit
	|			OR ExtDimension2 REFS Document.SalesReturn)
	|			) AS GeneralJournalTurnovers
	|		ON InvoicePaymentLineItems.Document = GeneralJournalTurnovers.Recorder
	|			AND InvoicePaymentLineItems.Currency = GeneralJournalTurnovers.Currency
	|WHERE
	|	InvoicePaymentLineItems.Ref = &Ref
	|	AND InvoicePaymentLineItems.Check
	|	AND InvoicePaymentLineItems.Currency = &Currency";
	
	
	LineQuery.SetParameter("Company", Company);
	LineQuery.SetParameter("Ref", Ref);
	LineQuery.SetParameter("Currency", Currency);
	LineResult = LineQuery.Execute().Unload();
	
	ExchangeRate = GeneralFunctions.GetExchangeRate(Date, Currency);
	
	
	//------------------------------------------------------------------------------------------------------------
	//TABULAR SECTION BILLS---------------------------------------------------------------------------------------
	//------------------------------------------------------------------------------------------------------------
	For Each DocumentLine In LineResult Do
	
		ExchangeRate    = GeneralFunctions.GetExchangeRate(Date, DocumentLine.Currency);
		DocExchangeRate = DocumentLine.ExchangeRate;
		DocRef          = DocumentLine.Document;
		
		//PurchaseInvoice-----------------------------------------------------------------------------------------
		//--------------------------------------------------------------------------------------------------------
		If TypeOf(DocRef) = Type("DocumentRef.PurchaseInvoice") Then
			
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
			FirstFullPaymentAmountRC  = Round(DocumentLine.Payment * DocExchangeRate, 2) + Round(DocumentLine.Discount * DocExchangeRate, 2);
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
						Record.RecordType    = CurrentTrans.RecordType;
						Record.Period        = Date;
						Record.Account       = CurrentTrans.Account;
						Record.Company       = Company;
						Record.Document      = DocRef;
						Record.SalesPerson   = Null;
						Record.Class         = CurrentTrans.Class;
						Record.Project       = CurrentTrans.Project;
						Record.AmountRC      = CurrentPaymentRC;
						Record.PaymentMethod = PaymentMethod;
						
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
				Record.PaymentMethod = PaymentMethod;
			EndIf;
			
		//Deposit-------------------------------------------------------------------------------------------------
		//--------------------------------------------------------------------------------------------------------
		ElsIf TypeOf(DocRef) = Type("DocumentRef.Deposit") Then
			
						
		//GeneralJournalEntry-------------------------------------------------------------------------------------
		//--------------------------------------------------------------------------------------------------------
		ElsIf TypeOf(DocRef) = Type("DocumentRef.GeneralJournalEntry") Then
			
						
		//SalesReturn---------------------------------------------------------------------------------------------
		//--------------------------------------------------------------------------------------------------------
		ElsIf TypeOf(DocRef) = Type("DocumentRef.SalesReturn") Then
			
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
			FirstFullPaymentAmountRC  = Round(DocumentLine.Payment * DocExchangeRate, 2) + Round(DocumentLine.Discount * DocExchangeRate, 2);
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
			
		EndIf;
				
		//Account Payable/Receivable------------------------------------------------------------------------------
		//--------------------------------------------------------------------------------------------------------
		Record = RegisterRecords.GeneralJournal.AddDebit();
		Record.Account  = DocumentLine.Account;
		Record.Period   = Date;
		Record.Amount   = DocumentLine.Payment;
		Record.AmountRC = DocumentLine.Payment * DocExchangeRate;
		Record.Currency = DocumentLine.Currency;
		Record.ExtDimensions[ChartsOfCharacteristicTypes.Dimensions.Company]  = Company;
		Record.ExtDimensions[ChartsOfCharacteristicTypes.Dimensions.Document] = DocRef;	
		
		//--//GJ++
		ReconciledDocumentsServerCall.AddRecordForGeneralJournalAnalyticsDimensions(RegisterRecords, Record, Null, Null, Company);
		//--//GJ--
		
		BankAmount = BankAmount+Round(DocumentLine.Payment,2);
		If DocumentLine.Currency = BankAccount.Currency Then
			BankAmoutRC = BankAmoutRC + Round(DocumentLine.Payment,2);
		Else
			BankAmoutRC = BankAmoutRC + Round(DocumentLine.Payment * ExchangeRate,2);
		EndIf;	
		
		//FXGainLoss----------------------------------------------------------------------------------------------
		//--------------------------------------------------------------------------------------------------------
		ExchangeLossAccount = Constants.ExchangeLoss.Get();
		FXGainLoss          = Round(DocExchangeRate * DocumentLine.Payment, 2) - Round(ExchangeRate * DocumentLine.Payment, 2);
		
		If FXGainLoss > 0 Then
			
			Record = RegisterRecords.GeneralJournal.AddCredit();
			Record.Account  = ExchangeLossAccount;
			Record.Period   = Date;
			Record.AmountRC = FXGainLoss;
			
			//--//GJ++
			ReconciledDocumentsServerCall.AddRecordForGeneralJournalAnalyticsDimensions(RegisterRecords, Record, Null, Null, Company);
			//--//GJ--
			
		ElsIf FXGainLoss < 0 Then
			
			Record = RegisterRecords.GeneralJournal.AddDebit();
			Record.Account  = ExchangeLossAccount;
			Record.Period   = Date;
			Record.AmountRC = FXGainLoss * -1;
			
			//--//GJ++
			ReconciledDocumentsServerCall.AddRecordForGeneralJournalAnalyticsDimensions(RegisterRecords, Record, Null, Null, Company);
			//--//GJ--
			
		EndIf;
		
		//Discount------------------------------------------------------------------------------------------------
		//--------------------------------------------------------------------------------------------------------
		If DocumentLine.Discount <> 0 Then 
			
			Record = RegisterRecords.GeneralJournal.AddDebit();
			Record.Period   = Date;
			Record.Account  = DocumentLine.Account;
			Record.Currency = DocumentLine.Currency;
			Record.Amount   = DocumentLine.Discount;
			ExchangeDifference = Round(DocumentLine.Discount * ExchangeRate, 2) - Round(DocumentLine.Discount * DocExchangeRate, 2); // Rounding errors
			Record.AmountRC = DocumentLine.Discount * ExchangeRate - ExchangeDifference; 
			Record.ExtDimensions[ChartsOfCharacteristicTypes.Dimensions.Company]  = Company;
			Record.ExtDimensions[ChartsOfCharacteristicTypes.Dimensions.Document] = DocRef;
			
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
				
			EndIf
			
		EndIf;
			 
	EndDo;
	//------------------------------------------------------------------------------------------------------------
	//TABULAR SECTION BILLS (end)---------------------------------------------------------------------------------
	//------------------------------------------------------------------------------------------------------------
	
	
	CreditQuery = New Query;
	CreditQuery.Text = Documents.InvoicePayment.GetCreditsAccountsQuery() + " ; "+
	"SELECT
	|	InvoicePaymentCredits.Payment,
	|	InvoicePaymentCredits.Document,
	|	InvoicePaymentCredits.Document.Date As Date,
	|	ISNULL(InvoicePaymentCredits.Document.Currency, GeneralJournalTurnovers.Currency) AS Currency,
	|	ISNULL(InvoicePaymentCredits.Document.ExchangeRate, 0) AS ExchangeRate,
	|	CASE WHEN InvoicePaymentCredits.Document REFS Document.PurchaseReturn
	|		Then InvoicePaymentCredits.Document.APAccount
	|	WHEN InvoicePaymentCredits.Document REFS Document.InvoicePayment
	|		Then GeneralJournalTurnovers.Account
	|	WHEN InvoicePaymentCredits.Document REFS Document.Check
	|		Then GeneralJournalTurnovers.Account
	|	WHEN InvoicePaymentCredits.Document REFS Document.GeneralJournalEntry
	|		Then GeneralJournalTurnovers.Account
	|	END AS Account
	|FROM
	|	Document.InvoicePayment.Credits AS InvoicePaymentCredits
	|		LEFT JOIN AccountingRegister.GeneralJournal.Turnovers(, , Recorder, Account IN (SELECT APAccount FROM TmpAccnts as TmpAccnts),, 
	//|		LEFT JOIN AccountingRegister.GeneralJournal.Turnovers(, , Recorder, Account IN (&TestAccnt),, 
	|			ExtDimension1 = &Company AND
	|          (ExtDimension2 REFS Document.PurchaseReturn 
	|			OR ExtDimension2 REFS Document.GeneralJournalEntry
	|			OR ExtDimension2 REFS Document.Check
	|			OR ExtDimension2 REFS Document.InvoicePayment)
	|			) AS GeneralJournalTurnovers
	|		ON InvoicePaymentCredits.Document = GeneralJournalTurnovers.Recorder
	|			AND GeneralJournalTurnovers.Currency = &Currency
	|WHERE
	|	InvoicePaymentCredits.Ref = &Ref
	|	AND ISNULL(InvoicePaymentCredits.Document.Currency, GeneralJournalTurnovers.Currency) = &Currency";
	
	
	CreditQuery.SetParameter("Company", Company);
	CreditQuery.SetParameter("Ref", Ref);
	CreditQuery.SetParameter("Currency", Currency);
	CreditResult = CreditQuery.Execute().Unload();
	
	
	//------------------------------------------------------------------------------------------------------------
	//TABULAR SECTION CREDITS-------------------------------------------------------------------------------------
	//------------------------------------------------------------------------------------------------------------
	For Each CreditLine In CreditResult Do
	
		DocRef          = CreditLine.Document;
		
		ExchangeRate    = GeneralFunctions.GetExchangeRate(Date, CreditLine.Currency);
		DocExchangeRate = CreditLine.ExchangeRate;
		
		If DocExchangeRate = 0 Then 
			DocExchangeRate = GeneralFunctions.GetExchangeRate(CreditLine.Date, CreditLine.Currency);
		EndIf;	
		
		//PurchaseReturn------------------------------------------------------------------------------------------
		//--------------------------------------------------------------------------------------------------------
		If TypeOf(DocRef) = Type("DocumentRef.PurchaseReturn") Then
			
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
			FirstFullPaymentAmountRC  = Round(CreditLine.Payment * DocExchangeRate, 2);
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
						Record.PaymentMethod = PaymentMethod;
						
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
				Record.PaymentMethod = PaymentMethod;
			EndIf;
					
		//GeneralJournalEntry-------------------------------------------------------------------------------------
		//--------------------------------------------------------------------------------------------------------
		ElsIf TypeOf(DocRef) = Type("DocumentRef.GeneralJournalEntry") Then
			
						
		//Check---------------------------------------------------------------------------------------------------
		//--------------------------------------------------------------------------------------------------------
		ElsIf TypeOf(DocRef) = Type("DocumentRef.Check") Then
			
					
		//InvoicePayment------------------------------------------------------------------------------------------
		//--------------------------------------------------------------------------------------------------------
		ElsIf TypeOf(DocRef) = Type("DocumentRef.InvoicePayment") Then
			
						
		EndIf;
		
		//Account Payable/Receivable------------------------------------------------------------------------------
		//--------------------------------------------------------------------------------------------------------
		Record = RegisterRecords.GeneralJournal.AddCredit();
		Record.Account  = CreditLine.Account;
		Record.Period   = Date;
		Record.Amount   = CreditLine.Payment;
		Record.AmountRC = CreditLine.Payment * DocExchangeRate;
		Record.Currency = CreditLine.Currency;
		Record.ExtDimensions[ChartsOfCharacteristicTypes.Dimensions.Company]  = Company;
		Record.ExtDimensions[ChartsOfCharacteristicTypes.Dimensions.Document] = DocRef;			 			
		
		//--//GJ++
		ReconciledDocumentsServerCall.AddRecordForGeneralJournalAnalyticsDimensions(RegisterRecords, Record, Null, Null, Company);
		//--//GJ--
		
		BankAmount = BankAmount - Round(CreditLine.Payment,2);
		If CreditLine.Currency = BankAccount.Currency Then
			BankAmoutRC = BankAmoutRC - Round(CreditLine.Payment,2);
		Else
			BankAmoutRC = BankAmoutRC - Round(CreditLine.Payment * ExchangeRate,2);
		EndIf;	
		
		//FXGainLoss----------------------------------------------------------------------------------------------
		//--------------------------------------------------------------------------------------------------------
		ExchangeLossAccount = Constants.ExchangeLoss.Get();
		FXGainLoss          = Round(DocExchangeRate * CreditLine.Payment, 2) - Round(ExchangeRate * CreditLine.Payment, 2);
		
		If FXGainLoss > 0 Then
			
			Record = RegisterRecords.GeneralJournal.AddDebit();
			Record.Account  = ExchangeLossAccount;
			Record.Period   = Date;
			Record.AmountRC = FXGainLoss;
			
			//--//GJ++
			ReconciledDocumentsServerCall.AddRecordForGeneralJournalAnalyticsDimensions(RegisterRecords, Record, Null, Null, Company);
			//--//GJ--
			
		ElsIf FXGainLoss < 0 Then
			
			Record = RegisterRecords.GeneralJournal.AddCredit();
			Record.Account  = ExchangeLossAccount;
			Record.Period   = Date;
			Record.AmountRC = FXGainLoss * -1;
			
			//--//GJ++
			ReconciledDocumentsServerCall.AddRecordForGeneralJournalAnalyticsDimensions(RegisterRecords, Record, Null, Null, Company);
			//--//GJ--
			
		EndIf;
		
	EndDo;
	//------------------------------------------------------------------------------------------------------------
	//TABULAR SECTION CREDITS (end)-------------------------------------------------------------------------------
	//------------------------------------------------------------------------------------------------------------
	
	
	//BANK AMOUNT-------------------------------------------------------------------------------------------------
	//------------------------------------------------------------------------------------------------------------
	BankAmount = BankAmount + UnappliedPayment;
	BankAmoutRC = BankAmoutRC + UnappliedPayment*ExchangeRate;
	
	If BankAmount > 0 Then 
		
		Record = RegisterRecords.GeneralJournal.AddCredit();
		Record.Account  = BankAccount;
		Record.Currency = BankAccount.Currency;
		Record.Period   = Date;
		Record.Amount   = BankAmount;
		Record.AmountRC = BankAmoutRC;
		
		//--//GJ++
		ReconciledDocumentsServerCall.AddRecordForGeneralJournalAnalyticsDimensions(RegisterRecords, Record, Null, Null, Company);
		//--//GJ--
		
	ElsIf BankAmount < 0 Then 
		
		Record = RegisterRecords.GeneralJournal.AddDebit();
		Record.Account  = BankAccount;
		Record.Currency = BankAccount.Currency;
		Record.Period   = Date;
		Record.Amount   = BankAmount;
		Record.AmountRC = BankAmoutRC;
		
		//--//GJ++
		ReconciledDocumentsServerCall.AddRecordForGeneralJournalAnalyticsDimensions(RegisterRecords, Record, Null, Null, Company);
		//--//GJ--
		
	EndIf;
	//------------------------------------------------------------------------------------------------------------
	//BANK AMOUNT (end)-------------------------------------------------------------------------------------------
	
	
	//UNAPPLIED PAYMENTS------------------------------------------------------------------------------------------
	//------------------------------------------------------------------------------------------------------------
	If UnappliedPayment > 0  Then
		
		DefaultCurrency = GeneralFunctionsReusable.DefaultCurrency();
		Record = RegisterRecords.GeneralJournal.AddDebit();
		Record.Period   = Date;
		Record.Account  = ?(Company.APAccount.IsEmpty(), Currency.DefaultAPAccount, Company.APAccount);
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
		
		DefaultDiscountAccount = Constants.DiscountsReceived.Get();
		Record = RegisterRecords.GeneralJournal.AddCredit();
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
		Record.PaymentMethod = PaymentMethod;
		
	EndDo;
	//------------------------------------------------------------------------------------------------------------
	//CASH BASIS (end)--------------------------------------------------------------------------------------------
	
	
	//DocumentPosting.FixUnbalancedRegister(ThisObject, Cancel, Constants.ExchangeLoss.Get());
	CheckedValueTable = RegisterRecords.GeneralJournal.Unload();
	UnbalancedAmount = 0;
	If Not DocumentPosting.IsValueTableBalanced(CheckedValueTable, UnbalancedAmount) Then 
		Cancel = True;
		// Generate error message.
		MessageText = NStr("en = 'The document %1 cannot be posted, because it''s transaction is unbalanced.'");
		MessageText = StringFunctionsClientServer.SubstituteParametersInString(MessageText, Ref);
		CommonUseClientServer.MessageToUser(MessageText, Ref,,, Cancel);
	EndIf;	
	
	
	// Writing bank reconciliation data
	ReconciledDocumentsServerCall.AddDocumentForReconciliation(RegisterRecords, Ref, BankAccount, Date, -1 * DocumentTotalRC);
		
EndProcedure

Procedure UndoPosting(Cancel)
	
	//Remove physical num for checking
	PhysicalCheckNum = 0;
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then // Skip some check ups.
		Return;
	EndIf;
	
	// Document date adjustment patch (tunes the date of drafts like for the new documents).
	If  WriteMode = DocumentWriteMode.Posting And Not Posted // Posting of new or draft (saved but unposted) document.
	And BegOfDay(Date) = BegOfDay(CurrentSessionDate()) Then // Operational posting (by the current date).
		// Shift document time to the time of posting.
		Date = CurrentSessionDate();
	EndIf;
	
	If (PaymentMethod = Catalogs.PaymentMethods.Check) And (WriteMode <> DocumentWriteMode.UndoPosting) Then
		PhysicalCheckNum = Number;
		If ThisObject.AdditionalProperties.Property("AllowCheckNumber") Then
			If Not ThisObject.AdditionalProperties.AllowCheckNumber Then
				Cancel = True;
				//If Constants.DisableAuditLog.Get() = False Then
					Message("Check number already exists for this bank account");
				//EndIf;			
			EndIf;
		Else
			CheckNumberResult = CommonUseServerCall.CheckNumberAllowed(ThisObject.Number, ThisObject.Ref, ThisObject.BankAccount);
			If CheckNumberResult.DuplicatesFound Then
				If Not CheckNumberResult.Allow Then
					Cancel = True;
					//If Constants.DisableAuditLog.Get() = False Then
						Message("Check number already exists for this bank account");
					//EndIf;								
				Else
					Cancel = True;
					//If Constants.DisableAuditLog.Get() = False Then
						Message("Check number already exists for this bank account. Perform the operation interactively!");
					//EndIf;								
				EndIf;			
			Endif;
		EndIf;		
	EndIf;
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	If FillingData <> Undefined And TypeOf(FillingData) = Type("DocumentRef.PurchaseInvoice") Then
		// processing was moved to the form module.
	EndIf;
	
EndProcedure

#EndRegion
