
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
	
	ExchangeGainAccount = Constants.ExchangeGain.Get();
	ExchangeLossAccount = Constants.ExchangeLoss.Get();
	
	RegisterRecords.CashFlowData.Write = True;
	
	//Alan - need payment total before writing into cash flow
	paymentTotal = 0;
	For Each line In LineItems Do
		paymentTotal = paymentTotal + line.Payment;
	EndDo;
	
	// need total of credit memo payment
	cmPayment = 0;
	For Each line In CreditMemos Do
		lineObject = line.Document.GetObject();
		If TypeOf(lineObject.Ref) = Type("DocumentRef.SalesReturn") Then
			cmPayment = cmPayment + line.Payment;
		EndIf;
	EndDo;
	//end_Alan
	
	For Each DocumentLine In LineItems Do
		
		// writing CashFlowData
		
		DocumentObject = DocumentLine.Document.GetObject(); 	 
		ExchangeRate = GeneralFunctions.GetExchangeRate(Date, DocumentObject.Currency);

		If TypeOf(DocumentObject.Ref) = Type("DocumentRef.SalesInvoice") Then
			
			If DocumentObject.Discount <> 0 Then
				Record = RegisterRecords.CashFlowData.Add();
				Record.RecordType = AccumulationRecordType.Receipt;
				Record.Period = Date;
				Record.Company = Company;
				Record.Document = DocumentObject.Ref;
				DiscountsAccount = Constants.DiscountsAccount.Get();
				If DiscountsAccount = ChartsOfAccounts.ChartOfAccounts.EmptyRef() Then
					Record.Account = Constants.ExpenseAccount.Get();
				Else
					Record.Account = DiscountsAccount;
				EndIf;
				//Record.Account = CurRowLineItems.Product.InventoryOrExpenseAccount;
				//Record.CashFlowSection = CurRowLineItems.Product.InventoryOrExpenseAccount.CashFlowSection;
				//Alan - changed old AmountRC to be multiplied by the payment ratio				
				tempAmount = ((DocumentObject.Discount * -1 * ExchangeRate) * -1) * DocumentLine.Payment / DocumentObject.DocumentTotalRC;
				//Record.PaymentMethod = PaymentMethod;
				Record.AmountRC = tempAmount * ((paymentTotal-cmPayment)/paymentTotal);
				//End_alan
				Record.SalesPerson = DocumentObject.SalesPerson;
			EndIf;
			
			If DocumentObject.Shipping <> 0 Then
							
				Record = RegisterRecords.CashFlowData.Add();
				Record.RecordType = AccumulationRecordType.Receipt;
				Record.Period = Date;
				Record.Company = Company;
				Record.Document = DocumentObject.Ref;
				ShippingExpenseAccount = Constants.ShippingExpenseAccount.Get();
				If ShippingExpenseAccount = ChartsOfAccounts.ChartOfAccounts.EmptyRef() Then
					Record.Account = Constants.IncomeAccount.Get();
				Else
					Record.Account = ShippingExpenseAccount;
				EndIf;
				tempAmount = (DocumentObject.Shipping * ExchangeRate) * DocumentLine.Payment / DocumentObject.DocumentTotalRC;
				Record.AmountRC = tempAmount * ((paymentTotal-cmPayment)/paymentTotal);
				Record.SalesPerson = DocumentObject.SalesPerson;
			
			EndIf;

			
			For Each Item In DocumentObject.LineItems Do
			
				Record = RegisterRecords.CashFlowData.Add();
				Record.RecordType = AccumulationRecordType.Receipt;
				Record.Period = Date;
				Record.Company = Company;
				Record.Document = DocumentObject.Ref;
				Record.Account = Item.Product.IncomeAccount;
				//Record.CashFlowSection = Item.Product.InventoryOrExpenseAccount.CashFlowSection;
				//Record.PaymentMethod = PaymentMethod;
				//Alan - changed old AmountRC to be multiplied by the payment ratiov				
				tempAmount = ((Item.LineTotal * ExchangeRate) * DocumentLine.Payment)/DocumentObject.DocumentTotalRC;
				Record.AmountRC = tempAmount * ((paymentTotal-cmPayment)/paymentTotal);   
				//End_Alan
				Record.SalesPerson = DocumentObject.SalesPerson;
			
			EndDo;
			
		EndIf;
		
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
		Record.Currency = DocumentLine.Currency; 
		Record.Amount =   DocumentLine.Payment;
		Record.AmountRC = DocumentLine.Payment * DocumentObject.ExchangeRate; 
		ExchangeGainLoss = ExchangeGainLoss + (DocumentLine.Payment * DocumentObject.ExchangeRate - DocumentLine.Payment * TodayRate);
		Record.ExtDimensions[ChartsOfCharacteristicTypes.Dimensions.Company] =  Company;
		Record.ExtDimensions[ChartsOfCharacteristicTypes.Dimensions.Document] = DocumentObject.Ref;
		
		//RegisterRecords.OrderTransactions.Write = True;
		//If TypeOf(DocumentObject) = Type("DocumentRef.CashReceipt") Then
			//If SalesOrder <> Documents.SalesOrder.EmptyRef() Then			
				//Record = RegisterRecords.OrderTransactions.Add();
				//Record.RecordType = AccumulationRecordType.Receipt;
				//Record.Period = Date;
				//Record.Order = SalesOrder;
				//Record.Amount = CashPayment;
			//EndIf
		//EndIf;

		
	EndDo;
	
	Credits = 0;
	
	For Each CreditLine In CreditMemos Do
		
		DocumentObject = CreditLine.Document.GetObject();		
		
		If TypeOf(DocumentObject.Ref) = Type("DocumentRef.SalesReturn") Then
			DocumentObjectAccount = DocumentObject.ARAccount;
			
			//Alan - write into cashflow for credit memo when its being applied
			For Each Item In DocumentObject.LineItems Do
				
				Record = RegisterRecords.CashFlowData.Add();
				Record.RecordType = AccumulationRecordType.Receipt;
				Record.Period = Date;
				Record.Company = Company;
				Record.Document = DocumentObject.Ref;
				
				Record.Account = Item.Product.IncomeAccount;
				//Record.CashFlowSection = Item.Product.InventoryOrExpenseAccount.CashFlowSection;
				//Record.PaymentMethod = PaymentMethod;
				Record.AmountRC = CreditLine.Payment;
				
				Record = RegisterRecords.CashFlowData.Add();
				Record.RecordType = AccumulationRecordType.Receipt;
				Record.Period = Date;
				Record.Company = Company;
				Record.Document = DocumentObject.Ref;
				
				Record.Account = Item.Product.IncomeAccount;
				//Record.CashFlowSection = Item.Product.InventoryOrExpenseAccount.CashFlowSection;
				//Record.PaymentMethod = PaymentMethod;
				Record.AmountRC = CreditLine.Payment*-1;
			
			EndDo;
				
			//end_alan

			
		ElsIf TypeOf(DocumentObject.Ref) = Type("DocumentRef.CashReceipt") Then
			DocumentObjectAccount = DocumentObject.ARAccount;			
		EndIf;

		DocumentObjectAmount =   CreditLine.Payment;
		DocumentObjectAmountRC = CreditLine.Payment;
		Credits = Credits + CreditLine.Payment;
		
		Record = RegisterRecords.GeneralJournal.AddDebit();
		Record.Period =   Date;
		Record.Account =  DocumentObjectAccount;
		Record.Currency = CreditLine.Currency;
		Record.Amount =   CreditLine.Payment;
		Rate = GeneralFunctions.GetExchangeRate(Date,Company.DefaultCurrency);
		Record.AmountRC = CreditLine.Payment * Rate;
		Record.ExtDimensions[ChartsOfCharacteristicTypes.Dimensions.Company] = Company;
		Record.ExtDimensions[ChartsOfCharacteristicTypes.Dimensions.Document] = DocumentObject.Ref;
		
		Rate2 = GeneralFunctions.GetExchangeRate(CreditLine.Document.Date, Company.DefaultCurrency);
		FXGainLoss = (CreditLine.Payment * Rate2) - (CreditLine.Payment * Rate);
		
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
			
		
			If DepositType = "1" Then 
				Record = RegisterRecords.GeneralJournal.AddDebit();
				Record.Period = Date;
				Record.Account = Constants.UndepositedFundsAccount.Get();
				Record.Currency = GeneralFunctionsReusable.DefaultCurrency();				
				Rate = GeneralFunctions.GetExchangeRate(Date, Currency);
				Record.Amount =  Payments - Credits + UnappliedPayment;
				Rate2 = GeneralFunctions.GetExchangeRate(Date, Company.DefaultCurrency);
				Record.AmountRC = (Payments*Rate2) + (UnappliedPayment*Rate2) - (Credits*Rate2);
			
			ElsIf DepositType = "2" Then 
				Record = RegisterRecords.GeneralJournal.AddDebit();
				Record.Period = Date;
				Record.Account = BankAccount;
				Record.Currency = GeneralFunctionsReusable.DefaultCurrency();
				Rate = GeneralFunctions.GetExchangeRate(Date, Currency);
				Record.Amount =  (Payments + UnappliedPayment - Credits);
				Rate2 = GeneralFunctions.GetExchangeRate(Date, Company.DefaultCurrency);
				Record.AmountRC = (Payments*Rate2) + (UnappliedPayment*Rate2) - (Credits*Rate2);

			EndIf;
	
	// Writing bank reconciliation data 
	
	If DepositType = "2" Then
		
		Records = InformationRegisters.TransactionReconciliation.CreateRecordSet();
		Records.Filter.Document.Set(Ref);
		Records.Read();
		If Records.Count() = 0 Then
			Record = Records.Add();
			Record.Document = Ref;
			Record.Account = BankAccount;
			Record.Reconciled = False;
			Record.Amount = CashPayment;	
		Else
			Records[0].Account = BankAccount;
			Records[0].Amount = CashPayment;
		EndIf;
		Records.Write();
		
		ReconciledDocumentsServerCall.AddDocumentForReconciliation(RegisterRecords, Ref, BankAccount, Date, CashPayment);
	
	EndIf;
	

	If UnappliedPayment > 0  Then
		
			Record = RegisterRecords.CashFlowData.Add();
			Record.RecordType = AccumulationRecordType.Receipt;
			Record.Period = Date;
			Record.Company = Company;
			Record.Document = Ref;
			//Record.Account = Constants.ExpenseAccount.Get();
			//Record.Account = CurRowLineItems.Product.InventoryOrExpenseAccount;
			//Record.CashFlowSection = CurRowLineItems.Product.InventoryOrExpenseAccount.CashFlowSection;
			Record.AmountRC = UnappliedPayment * Rate;
			//Record.PaymentMethod = PaymentMethod;


							
			DefaultCurrency = GeneralFunctionsReusable.DefaultCurrency();
			Record = RegisterRecords.GeneralJournal.AddCredit();
			Record.Period =   Date;
			Record.Account =  ARAccount;
			Record.Currency = Company.DefaultCurrency;
			Rate = GeneralFunctions.GetExchangeRate(Date,Company.DefaultCurrency);
			Record.Amount =   UnappliedPayment;
			Record.AmountRC = UnappliedPayment * Rate;
			Record.ExtDimensions[ChartsOfCharacteristicTypes.Dimensions.Company] = Company;
			Record.ExtDimensions[ChartsOfCharacteristicTypes.Dimensions.Document] = Ref;


		
		// Write and post unapplied payment in the same transaction.
		//UnappliedPaymentCreditMemo.GetObject().Write(DocumentWriteMode.Posting, DocumentPostingMode.Regular);
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
	                    |	CashReceiptCreditMemos.Document,
	                    |	CashReceiptCreditMemos.Payment,
	                    |	CashReceiptCreditMemos.BalanceFCY,
	                    |	""CreditMemos"" AS TabularSection
	                    |INTO CashReceiptDocuments
	                    |FROM
	                    |	Document.CashReceipt.CreditMemos AS CashReceiptCreditMemos
	                    |WHERE
	                    |	CashReceiptCreditMemos.Ref = &CurrentDocument
	                    |
	                    |UNION ALL
	                    |
	                    |SELECT
	                    |	CashReceiptLineItems.Document,
	                    |	CashReceiptLineItems.Payment,
	                    |	CashReceiptLineItems.BalanceFCY,
	                    |	""LineItems""
	                    |FROM
	                    |	Document.CashReceipt.LineItems AS CashReceiptLineItems
	                    |WHERE
	                    |	CashReceiptLineItems.Ref = &CurrentDocument
	                    |;
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
		
	If ExchangeGainLoss < 0 Then
		Record = RegisterRecords.GeneralJournal.AddCredit();
		Record.Account = ExchangeGainAccount;
		Record.Period = Date;
		Record.AmountRC = -ExchangeGainLoss;
					
	ElsIf ExchangeGainLoss > 0 Then
		Record = RegisterRecords.GeneralJournal.AddDebit();
		Record.Account = ExchangeLossAccount;
		Record.Period = Date;
		Record.AmountRC = ExchangeGainLoss;
	EndIf;
	
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
	
	email_receipt_webhook = Constants.receipt_webhook_email.Get();
	
	If NOT email_receipt_webhook = "" Then
	//If true then			
		WebhookMap2 = Webhooks.ReturnCashReceiptMap(Ref);
		WebhookMap2.Insert("resource","cashreceipts");
		If NewObject = True Then
			WebhookMap2.Insert("action","create");
		Else
			WebhookMap2.Insert("action","update");
		EndIf;
		WebhookMap2.Insert("apisecretkey",Constants.APISecretKey.Get());
		
		WebhookParams2 = New Array();
		WebhookParams2.Add(email_receipt_webhook);
		WebhookParams2.Add(WebhookMap2);
		LongActions.ExecuteInBackground("GeneralFunctions.EmailWebhook", WebhookParams2);
		
	EndIf;


	
EndProcedure

Procedure UndoPosting(Cancel)
			
	// Deleting bank reconciliation data
	
	Records = InformationRegisters.TransactionReconciliation.CreateRecordManager();
	Records.Document = Ref;
	Records.Account = BankAccount;
	Records.Read();
	Records.Delete();

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
	
	// Document date adjustment patch (tunes the date of drafts like for the new documents).
	If  WriteMode = DocumentWriteMode.Posting And Not Posted // Posting of new or draft (saved but unposted) document.
	And BegOfDay(Date) = BegOfDay(CurrentSessionDate()) Then // Operational posting (by the current date).
		// Shift document time to the time of posting.
		Date = CurrentSessionDate();
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
		
	TRRecordset = InformationRegisters.TransactionReconciliation.CreateRecordSet();
	TRRecordset.Filter.Document.Set(ThisObject.Ref);
	TRRecordset.Write(True);

EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	// Set the doc's number if it's new (Rupasov)
	If ThisObject.IsNew() Then ThisObject.SetNewNumber() EndIf;

EndProcedure



