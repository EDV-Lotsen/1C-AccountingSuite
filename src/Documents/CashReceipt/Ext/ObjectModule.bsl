
// The procedure posts a cash receipt document. Different transactions are creating depending whether the deposit type is
// 1 for an undeposited funds account, and 2 for a bank account, also an FX gain or loss is calculated and posted.
//
Procedure Posting(Cancel, PostingMode)

	RegisterRecords.OrderTransactions.Write = True;
	If SalesOrder <> Documents.SalesOrder.EmptyRef() Then			
		Record = RegisterRecords.OrderTransactions.Add();
		Record.RecordType = AccumulationRecordType.Expense;
		Record.Period = Date;
		Record.Order = SalesOrder;
		Record.Amount = UnappliedPayment;
	EndIf;

	
	// Write records to General Journal
	RegisterRecords.GeneralJournal.Write = True;
	Payments = 0;

	
	TodayRate = GeneralFunctions.GetExchangeRate(Date, Company.DefaultCurrency);
	ExchangeGainLoss = 0;
	
	ExchangeGainAccount = Constants.ExchangeGain.Get();
	ExchangeLossAccount = Constants.ExchangeLoss.Get();
	
	For Each DocumentLine In LineItems Do
		
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
		
	EndDo;
	
	Credits = 0;
	
	For Each CreditLine In CreditMemos Do
		
		DocumentObject = CreditLine.Document.GetObject();		
		
		If TypeOf(DocumentObject.Ref) = Type("DocumentRef.SalesReturn") Then
			DocumentObjectAccount = DocumentObject.ARAccount;
			
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
		
		Rate2 = GeneralFunctions.GetExchangeRate(DocumentLine.Document.Date, Company.DefaultCurrency);
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
	
	EndIf;
	

	If UnappliedPayment > 0  Then 
				
			
			DefaultCurrency = GeneralFunctionsReusable.DefaultCurrency();
			Record = RegisterRecords.GeneralJournal.AddCredit();
			Record.Period =   Date;
			Record.Account =  DefaultCurrency.DefaultARAccount;
			Record.Currency = Company.DefaultCurrency;
			Rate = GeneralFunctions.GetExchangeRate(Date,Company.DefaultCurrency);
			Record.Amount =   UnappliedPayment;
			Record.AmountRC = UnappliedPayment * Rate;
			Record.ExtDimensions[ChartsOfCharacteristicTypes.Dimensions.Company] = Company;
			Record.ExtDimensions[ChartsOfCharacteristicTypes.Dimensions.Document] = Ref;


		
		// Write and post unapplied payment in the same transaction.
		//UnappliedPaymentCreditMemo.GetObject().Write(DocumentWriteMode.Posting, DocumentPostingMode.Regular);
	EndIf;
	
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

EndProcedure


Procedure OnWrite(Cancel)
	
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
		If NewObject = True Then
			WebhookMap.Insert("action","create");
		Else
			WebhookMap.Insert("action","update");
		EndIf;
		WebhookMap.Insert("api_code",String(Ref.UUID()));
		
		WebhookParams = New Array();
		WebhookParams.Add(Constants.cash_receipts_webhook.Get());
		WebhookParams.Add(WebhookMap);
		LongActions.ExecuteInBackground("GeneralFunctions.SendWebhook", WebhookParams);
	
	EndIf;

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

EndProcedure



