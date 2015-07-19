
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
		Record.AmountRC = CashPayment;
	EndIf;	
	
	RegisterRecords.OrderTransactions.Write = True;
	If SalesOrder <> Documents.SalesOrder.EmptyRef() Then			
		Record = RegisterRecords.OrderTransactions.Add();
		Record.RecordType = AccumulationRecordType.Expense;
		Record.Period = Date;
		Record.Order = SalesOrder;
		Record.Amount = CashPayment;
	EndIf;


	
	// Write records to General Journal
	RegisterRecords.GeneralJournal.Write = True;
	Payments = 0;

	
	TodayRate = GeneralFunctions.GetExchangeRate(Date, Company.DefaultCurrency);
	ExchangeGainLoss = 0;
	
	//ExchangeGainAccount = Constants.ExchangeGain.Get();
	ExchangeLossAccount = Constants.ExchangeLoss.Get();
	
	RegisterRecords.CashFlowData.Write = True;
	
	For Each DocumentLine In LineItems Do
		
		// writing CashFlowData
		
		DocumentObject = DocumentLine.Document.GetObject(); 	
		
		//--------------------------------------------------------------------------------------------------------------------------
		If TypeOf(DocumentObject.Ref) = Type("DocumentRef.SalesInvoice") Then
			
			SumDoc           = 0;
			DocObjTotal      = DocumentObject.DocumentTotal;
			BalancePaymentRC = Round(DocumentLine.Payment * ExchangeRate, 2);
			
			IncomeAccount          = Constants.IncomeAccount.Get();
			ExpenseAccount         = Constants.ExpenseAccount.Get();
			ShippingExpenseAccount = Constants.ShippingExpenseAccount.Get();
			TaxPayableAccount      = Constants.TaxPayableAccount.Get();
			DiscountsAccount       = Constants.DiscountsAccount.Get();
			
			//Income
			For Each Item In DocumentObject.LineItems Do
				
				SumDoc = SumDoc + Item.LineTotal;
				CurrentPaymentRC = ?(SumDoc = DocObjTotal, BalancePaymentRC, Round((Item.LineTotal * DocumentLine.Payment / DocObjTotal) * ExchangeRate, 2));
				BalancePaymentRC = BalancePaymentRC - CurrentPaymentRC;
				
				If CurrentPaymentRC <> 0 Then 
					Record = RegisterRecords.CashFlowData.Add();
					Record.RecordType  = AccumulationRecordType.Receipt;
					Record.Period      = Date;
					Record.Company     = Company;
					Record.Document    = DocumentObject.Ref;
					Record.Account     = Item.Product.IncomeAccount;
					Record.SalesPerson = DocumentObject.SalesPerson;
					Record.AmountRC    = CurrentPaymentRC;
				EndIf;
				
			EndDo;
			
			//Shipping
			SumDoc = SumDoc + DocumentObject.Shipping;
			CurrentPaymentRC = ?(SumDoc = DocObjTotal, BalancePaymentRC, Round((DocumentObject.Shipping * DocumentLine.Payment / DocObjTotal) * ExchangeRate, 2));
			BalancePaymentRC = BalancePaymentRC - CurrentPaymentRC;
			
			If CurrentPaymentRC <> 0 Then 
				Record = RegisterRecords.CashFlowData.Add();
				Record.RecordType  = AccumulationRecordType.Receipt;
				Record.Period      = Date;
				Record.Company     = Company;
				Record.Document    = DocumentObject.Ref;
				Record.Account     = ?(ShippingExpenseAccount = ChartsOfAccounts.ChartOfAccounts.EmptyRef(), IncomeAccount, ShippingExpenseAccount);
				Record.SalesPerson = DocumentObject.SalesPerson;			
				Record.AmountRC    = CurrentPaymentRC;
			EndIf;
			
			//Sales tax
			SumDoc = SumDoc + DocumentObject.SalesTax;
			CurrentPaymentRC = ?(SumDoc = DocObjTotal, BalancePaymentRC, Round((DocumentObject.SalesTax * DocumentLine.Payment / DocObjTotal) * ExchangeRate, 2));
			BalancePaymentRC = BalancePaymentRC - CurrentPaymentRC;
			
			If CurrentPaymentRC <> 0 Then 
				Record = RegisterRecords.CashFlowData.Add();
				Record.RecordType  = AccumulationRecordType.Receipt;
				Record.Period      = Date;
				Record.Company     = Company;
				Record.Document    = DocumentObject.Ref;
				Record.Account     = ?(TaxPayableAccount = ChartsOfAccounts.ChartOfAccounts.EmptyRef(), IncomeAccount, TaxPayableAccount);
				Record.SalesPerson = DocumentObject.SalesPerson;
				Record.AmountRC    = CurrentPaymentRC;
			EndIf;
			
			//Discount
			SumDoc = SumDoc + DocumentObject.Discount;
			CurrentPaymentRC = ?(SumDoc = DocObjTotal, BalancePaymentRC, Round((DocumentObject.Discount * DocumentLine.Payment / DocObjTotal) * ExchangeRate, 2));
			BalancePaymentRC = BalancePaymentRC - CurrentPaymentRC;
			
			If CurrentPaymentRC <> 0 Then 
				Record = RegisterRecords.CashFlowData.Add();
				Record.RecordType  = AccumulationRecordType.Receipt;
				Record.Period      = Date;
				Record.Company     = Company;
				Record.Document    = DocumentObject.Ref;
				Record.Account     = ?(DiscountsAccount = ChartsOfAccounts.ChartOfAccounts.EmptyRef(), ExpenseAccount, DiscountsAccount);
				Record.SalesPerson = DocumentObject.SalesPerson;
				Record.AmountRC    = CurrentPaymentRC;
			EndIf;		
		
		EndIf;
		//--------------------------------------------------------------------------------------------------------------------------
		
		If TypeOf(DocumentObject.Ref) = Type("DocumentRef.PurchaseReturn") Then
			
			For Each Item In DocumentObject.LineItems Do
			
				Record = RegisterRecords.CashFlowData.Add();
				Record.RecordType = AccumulationRecordType.Expense;
				Record.Period = Date;
				Record.Company = Company;
				Record.Document = DocumentObject.Ref;
				If Item.Product.Type = Enums.InventoryTypes.Inventory Then
					Record.Account = Item.Product.COGSAccount;
				Else
					Record.Account = Item.Product.InventoryOrExpenseAccount;
				EndIf;
				//Record.CashFlowSection = Item.Product.InventoryOrExpenseAccount.CashFlowSection;
				//Record.PaymentMethod = PaymentMethod;
				Record.AmountRC = -1 * ((Item.LineTotal * ExchangeRate) * DocumentLine.Payment) / DocumentObject.DocumentTotalRC;
			
			EndDo;

			
		EndIf;
		
		// end writing CashFlowData
		
		DocumentObject = DocumentLine.Document.GetObject();		
		
		If TypeOf(DocumentObject.Ref) = Type("DocumentRef.SalesInvoice") Then
			DocumentObjectAccount = DocumentObject.ARAccount;
			
		ElsIf TypeOf(DocumentObject.Ref) = Type("DocumentRef.PurchaseReturn") Then
			DocumentObjectAccount = DocumentObject.APAccount;			
		EndIf;

		Payments = Payments + DocumentLine.Payment;
		
		Record = RegisterRecords.GeneralJournal.AddCredit();
		Record.Period =   Date;
		Record.Account =  DocumentObjectAccount;
		Record.Currency = Currency;//DocumentLine.Currency; 
		Record.Amount =   DocumentLine.Payment;
		ExchangeDifference = Round(DocumentLine.Payment * ExchangeRate,2) - Round(DocumentLine.Payment * DocumentLine.Document.ExchangeRate,2);
		Record.AmountRC = DocumentLine.Payment * ExchangeRate - ExchangeDifference; 
		Record.ExtDimensions[ChartsOfCharacteristicTypes.Dimensions.Company] =  Company;
		Record.ExtDimensions[ChartsOfCharacteristicTypes.Dimensions.Document] = DocumentObject.Ref;
		
		If ExchangeDifference > 0 Then
			Record = RegisterRecords.GeneralJournal.AddCredit();
			Record.Account = ExchangeLossAccount;
			Record.Period = Date;
			Record.AmountRC = ExchangeDifference;
						
		ElsIf ExchangeDifference < 0 Then
			Record = RegisterRecords.GeneralJournal.AddDebit();
			Record.Account = ExchangeLossAccount;
			Record.Period = Date;
			Record.AmountRC = - ExchangeDifference;
		EndIf;
	
	EndDo;
	
	DefaultCurrency = GeneralFunctionsReusable.DefaultCurrency();
	CompanyCurrency = Company.DefaultCurrency;
	Rate = GeneralFunctions.GetExchangeRate(Date, CompanyCurrency);	
		
	Credits = 0;
	
	For Each CreditLine In CreditMemos Do
		
		DocumentObject = CreditLine.Document.GetObject();		
		
		If TypeOf(DocumentObject.Ref) = Type("DocumentRef.SalesReturn") Then
			
			DocumentObjectAccount = DocumentObject.ARAccount;
			
			//--------------------------------------------------------------------------------------------------------------------------
			SumDoc           = 0;
			DocObjTotal      = DocumentObject.DocumentTotal;
			BalancePaymentRC = Round(CreditLine.Payment * ExchangeRate, 2);
			
			IncomeAccount          = Constants.IncomeAccount.Get();
			ExpenseAccount         = Constants.ExpenseAccount.Get();
			ShippingExpenseAccount = Constants.ShippingExpenseAccount.Get();
			TaxPayableAccount      = Constants.TaxPayableAccount.Get();
			DiscountsAccount       = Constants.DiscountsAccount.Get();
			
			//Income
			For Each Item In DocumentObject.LineItems Do
				
				SumDoc = SumDoc + Item.LineTotal;
				CurrentPaymentRC = ?(SumDoc = DocObjTotal, BalancePaymentRC, Round((Item.LineTotal * CreditLine.Payment / DocObjTotal) * ExchangeRate, 2));
				BalancePaymentRC = BalancePaymentRC - CurrentPaymentRC;
				
				If CurrentPaymentRC <> 0 Then 
					Record = RegisterRecords.CashFlowData.Add();
					Record.RecordType  = AccumulationRecordType.Receipt;
					Record.Period      = Date;
					Record.Company     = Company;
					Record.Document    = DocumentObject.Ref;
					Record.Account     = Item.Product.IncomeAccount;
					Record.SalesPerson = DocumentObject.SalesPerson;
					Record.AmountRC    = -CurrentPaymentRC;
				EndIf;
				
			EndDo;
			
			//Shipping
			SumDoc = SumDoc + DocumentObject.Shipping;
			CurrentPaymentRC = ?(SumDoc = DocObjTotal, BalancePaymentRC, Round((DocumentObject.Shipping * CreditLine.Payment / DocObjTotal) * ExchangeRate, 2));
			BalancePaymentRC = BalancePaymentRC - CurrentPaymentRC;
			
			If CurrentPaymentRC <> 0 Then 
				Record = RegisterRecords.CashFlowData.Add();
				Record.RecordType  = AccumulationRecordType.Receipt;
				Record.Period      = Date;
				Record.Company     = Company;
				Record.Document    = DocumentObject.Ref;
				Record.Account     = ?(ShippingExpenseAccount = ChartsOfAccounts.ChartOfAccounts.EmptyRef(), IncomeAccount, ShippingExpenseAccount);
				Record.SalesPerson = DocumentObject.SalesPerson;			
				Record.AmountRC    = -CurrentPaymentRC;
			EndIf;
			
			//Sales tax
			SumDoc = SumDoc + DocumentObject.SalesTax;
			CurrentPaymentRC = ?(SumDoc = DocObjTotal, BalancePaymentRC, Round((DocumentObject.SalesTax * CreditLine.Payment / DocObjTotal) * ExchangeRate, 2));
			BalancePaymentRC = BalancePaymentRC - CurrentPaymentRC;
			
			If CurrentPaymentRC <> 0 Then 
				Record = RegisterRecords.CashFlowData.Add();
				Record.RecordType  = AccumulationRecordType.Receipt;
				Record.Period      = Date;
				Record.Company     = Company;
				Record.Document    = DocumentObject.Ref;
				Record.Account     = ?(TaxPayableAccount = ChartsOfAccounts.ChartOfAccounts.EmptyRef(), IncomeAccount, TaxPayableAccount);
				Record.SalesPerson = DocumentObject.SalesPerson;
				Record.AmountRC    = -CurrentPaymentRC;
			EndIf;
			
			//Discount
			SumDoc = SumDoc + DocumentObject.Discount;
			CurrentPaymentRC = ?(SumDoc = DocObjTotal, BalancePaymentRC, Round((DocumentObject.Discount * CreditLine.Payment / DocObjTotal) * ExchangeRate, 2));
			BalancePaymentRC = BalancePaymentRC - CurrentPaymentRC;
			
			If CurrentPaymentRC <> 0 Then 
				Record = RegisterRecords.CashFlowData.Add();
				Record.RecordType  = AccumulationRecordType.Receipt;
				Record.Period      = Date;
				Record.Company     = Company;
				Record.Document    = DocumentObject.Ref;
				Record.Account     = ?(DiscountsAccount = ChartsOfAccounts.ChartOfAccounts.EmptyRef(), ExpenseAccount, DiscountsAccount);
				Record.SalesPerson = DocumentObject.SalesPerson;
				Record.AmountRC    = -CurrentPaymentRC;
			EndIf;		
			//--------------------------------------------------------------------------------------------------------------------------

			
		ElsIf TypeOf(DocumentObject.Ref) = Type("DocumentRef.CashReceipt") Then
			
			DocumentObjectAccount = DocumentObject.ARAccount;	
			
			//----------------------------------------------------------------------------
			Record = RegisterRecords.CashFlowData.Add();
			Record.RecordType = AccumulationRecordType.Receipt;
			Record.Period = Date;
			Record.Company = Company;
			Record.Document = Ref;
			Record.AmountRC = -CreditLine.Payment * Rate;
			//----------------------------------------------------------------------------
			
		EndIf;

		DocumentObjectAmount =   CreditLine.Payment;
		DocumentObjectAmountRC = CreditLine.Payment;
		Credits = Credits + CreditLine.Payment;
		
		Record = RegisterRecords.GeneralJournal.AddDebit();
		Record.Period =   Date;
		Record.Account =  DocumentObjectAccount;
		Record.Currency = Currency;
		Record.Amount =   CreditLine.Payment;
		ExchangeDifference = Round(CreditLine.Payment * ExchangeRate,2) - Round(CreditLine.Payment * CreditLine.Document.ExchangeRate,2);
		Record.AmountRC = CreditLine.Payment * ExchangeRate - ExchangeDifference;
		Record.ExtDimensions[ChartsOfCharacteristicTypes.Dimensions.Company] = Company;
		Record.ExtDimensions[ChartsOfCharacteristicTypes.Dimensions.Document] = DocumentObject.Ref;
		
		If ExchangeDifference < 0 Then
			Record = RegisterRecords.GeneralJournal.AddCredit();
			Record.Account = ExchangeLossAccount;
			Record.Period = Date;
			Record.AmountRC = - ExchangeDifference;
						
		ElsIf ExchangeDifference > 0 Then
			Record = RegisterRecords.GeneralJournal.AddDebit();
			Record.Account = ExchangeLossAccount;
			Record.Period = Date;
			Record.AmountRC = ExchangeDifference;
		EndIf;
		
		RegisterRecords.OrderTransactions.Write = True;
		If TypeOf(DocumentObject) = Type("DocumentRef.CashReceipt") Then
			If DocumentObject.Ref.SalesOrder <> Documents.SalesOrder.EmptyRef() Then			
				Record = RegisterRecords.OrderTransactions.Add();
				Record.RecordType = AccumulationRecordType.Receipt;
				Record.Period = Date;
				Record.Order = DocumentObject.Ref.SalesOrder;
				Record.Amount = CreditLine.Payment;
			EndIf
		EndIf;
			
	EndDo;
	
	PayTotal = 0;
	For Each LineItem In LineItems Do
				PayTotal =  PayTotal + LineItem.Payment;
	EndDo;
			
	If PayTotal = 0 And UnappliedPayment = 0 Then
		Message("No payment is being made.");
		Cancel = True;
		Return;
	EndIf;
			
	DocumentTotalRC = PayTotal*Rate;
	DocumentTotal = PayTotal;	
		
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
		//-- MisA 11/17/2014
		
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
		
	EndIf;
	
	// Writing bank reconciliation data 
	
	If DepositType = "2" Then
		
		ReconciledDocumentsServerCall.AddDocumentForReconciliation(RegisterRecords, Ref, BankAccount, Date, CashPayment);
	
	EndIf;
	

	If UnappliedPayment > 0  Then
		
		//----------------------------------------------------------------------------
		Record = RegisterRecords.CashFlowData.Add();
		Record.RecordType = AccumulationRecordType.Receipt;
		Record.Period = Date;
		Record.Company = Company;
		Record.Document = Ref;
		Record.AmountRC = UnappliedPayment * ExchangeRate; // MisA 11/19/2014, changed rate to pre-defined customer rate
		//----------------------------------------------------------------------------
		
		DefaultCurrency = GeneralFunctionsReusable.DefaultCurrency();
		Record = RegisterRecords.GeneralJournal.AddCredit();
		Record.Period =   Date;
		Record.Account =  ARAccount;
		Record.Currency = Company.DefaultCurrency;
		Record.Amount = UnappliedPayment;                  // MisA 11/19/2014 Amount in same currency as the customer default
		Record.AmountRC = UnappliedPayment * ExchangeRate; // MisA 11/19/2014, changed rate to pre-defined customer rate
		Record.ExtDimensions[ChartsOfCharacteristicTypes.Dimensions.Company] = Company;
		Record.ExtDimensions[ChartsOfCharacteristicTypes.Dimensions.Document] = Ref;
		
	EndIf;
	
	// Sales tax
	RegisterRecords.SalesTaxOwed.Write = True;
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
	                    |	AccruedSalesTax.BalanceFCY,
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
			
	receipt_url = Constants.cash_receipts_webhook.Get();
	
	If NOT receipt_url = "" Then
		
		WebhookMap = Webhooks.ReturnCashReceiptMap(Ref);
		WebhookMap.Insert("resource","cashreceipts");
		If NewObject = True Then
			WebhookMap.Insert("action","create");
		Else
			WebhookMap.Insert("action","update");
		EndIf;
		WebhookMap.Insert("apisecretkey",Constants.APISecretKey.Get());
		
		WebhookParams = New Array();
		WebhookParams.Add(receipt_url);
		WebhookParams.Add(WebhookMap);
		LongActions.ExecuteInBackground("GeneralFunctions.SendWebhook", WebhookParams);
	
	EndIf;
	
	//email_receipt_webhook = Constants.receipt_webhook_email.Get();
	//
	//If NOT email_receipt_webhook = "" Then
	////If true then			
	//	WebhookMap2 = Webhooks.ReturnCashReceiptMap(Ref);
	//	WebhookMap2.Insert("resource","cashreceipts");
	//	If NewObject = True Then
	//		WebhookMap2.Insert("action","create");
	//	Else
	//		WebhookMap2.Insert("action","update");
	//	EndIf;
	//	WebhookMap2.Insert("apisecretkey",Constants.APISecretKey.Get());
	//	
	//	WebhookParams2 = New Array();
	//	WebhookParams2.Add(email_receipt_webhook);
	//	WebhookParams2.Add(WebhookMap2);
	//	LongActions.ExecuteInBackground("GeneralFunctions.EmailWebhook", WebhookParams2);
	//	
	//EndIf;


	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	// for webhooks
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


Procedure OnWrite(Cancel)
	
	//companies_webhook = Constants.cash_receipts_webhook.Get();
	//
	//If NOT companies_webhook = "" Then
	//	
	//	//double_slash = Find(companies_webhook, "//");
	//	//
	//	//companies_webhook = Right(companies_webhook,StrLen(companies_webhook) - double_slash - 1);
	//	//
	//	//first_slash = Find(companies_webhook, "/");
	//	//webhook_address = Left(companies_webhook,first_slash - 1);
	//	//webhook_resource = Right(companies_webhook,StrLen(companies_webhook) - first_slash + 1); 		
	//	
	//	WebhookMap = New Map(); 
	//	WebhookMap.Insert("apisecretkey",Constants.APISecretKey.Get());
	//	WebhookMap.Insert("resource","cashreceipts");
	//	If NewObject = True Then
	//		WebhookMap.Insert("action","create");
	//	Else
	//		WebhookMap.Insert("action","update");
	//	EndIf;
	//	WebhookMap.Insert("api_code",String(Ref.UUID()));
	//	
	//	WebhookParams = New Array();
	//	WebhookParams.Add(Constants.cash_receipts_webhook.Get());
	//	WebhookParams.Add(WebhookMap);
	//	LongActions.ExecuteInBackground("GeneralFunctions.SendWebhook", WebhookParams);
	//
	//EndIf;

EndProcedure

Procedure BeforeDelete(Cancel)
	
	companies_webhook = Constants.cash_receipts_webhook.Get();
	
	If NOT companies_webhook = "" Then
		
		//double_slash = Find(companies_webhook, "//");
		//
		//companies_webhook = Right(companies_webhook,StrLen(companies_webhook) - double_slash - 1);
		//
		//first_slash = Find(companies_webhook, "/");
		//webhook_address = Left(companies_webhook,first_slash - 1);
		//webhook_resource = Right(companies_webhook,StrLen(companies_webhook) - first_slash + 1); 		
		
		WebhookMap = New Map(); 
		WebhookMap.Insert("apisecretkey",Constants.APISecretKey.Get());
		WebhookMap.Insert("resource","cashreceipts");
		WebhookMap.Insert("action","delete");
		WebhookMap.Insert("api_code",String(Ref.UUID()));
		
		WebhookParams = New Array();
		WebhookParams.Add(Constants.cash_receipts_webhook.Get());
		WebhookParams.Add(WebhookMap);
		LongActions.ExecuteInBackground("GeneralFunctions.SendWebhook", WebhookParams);
	
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



