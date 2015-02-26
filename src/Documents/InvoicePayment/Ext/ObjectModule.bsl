
#Region EVENT_HANDLERS

// The procedure posts a payment document. Also an FX gain or loss is calculated and posted.
//
Procedure Posting(Cancel, Mode)
	
	For Each DocumentLine In LineItems Do
	
		DocumentObject = DocumentLine.Document.GetObject();
		 	 
		ExchangeRate = GeneralFunctions.GetExchangeRate(Date, DocumentObject.Currency);
		 
		RegisterRecords.GeneralJournal.Write = True;
		RegisterRecords.CashFlowData.Write = True;
		
		If TypeOf(DocumentObject.Ref) = Type("DocumentRef.PurchaseInvoice") Then
			
			For Each Acc In DocumentObject.Accounts Do
				Record = RegisterRecords.CashFlowData.Add();
				Record.RecordType = AccumulationRecordType.Expense;
				Record.Period = Date;
				Record.Company = Company;
				Record.Document = DocumentObject.Ref;
				Record.Account = Acc.Account;
				//Record.CashFlowSection = Acc.Account.CashFlowSection;
				Record.PaymentMethod = PaymentMethod;
				Record.AmountRC = ((Acc.Amount * ExchangeRate) * DocumentLine.Payment)/DocumentObject.DocumentTotalRC;
			EndDo;
			
			For Each Item In DocumentObject.LineItems Do
				Record = RegisterRecords.CashFlowData.Add();
				Record.RecordType = AccumulationRecordType.Expense;
				Record.Period = Date;
				Record.Company = Company;
				Record.Document = DocumentObject.Ref;
				Record.Account = Item.Product.InventoryOrExpenseAccount;
				If Item.Product.Type = Enums.InventoryTypes.Inventory Then
					Record.Account = Item.Product.COGSAccount;
				Else
					Record.Account = Item.Product.InventoryOrExpenseAccount;
				EndIf;
				//Record.CashFlowSection = Item.Product.InventoryOrExpenseAccount.CashFlowSection;
				Record.PaymentMethod = PaymentMethod;
				Record.AmountRC = ((Item.LineTotal * ExchangeRate) * DocumentLine.Payment)/DocumentObject.DocumentTotalRC;
			EndDo;


		
			Record = RegisterRecords.GeneralJournal.AddDebit();
			Record.Account = DocumentObject.APAccount;
			Record.Period = Date;
			Record.Amount = DocumentLine.Payment;
			Record.AmountRC = DocumentLine.Payment * DocumentObject.ExchangeRate;
			Record.Currency = DocumentObject.Currency;
			Record.ExtDimensions[ChartsOfCharacteristicTypes.Dimensions.Company] = Company;
			Record.ExtDimensions[ChartsOfCharacteristicTypes.Dimensions.Document] = DocumentObject.Ref;			 			
				
			Record = RegisterRecords.GeneralJournal.AddCredit();
			Record.Account = BankAccount;
			Record.Currency = BankAccount.Currency;
			Record.Period = Date;
			If DocumentObject.Currency = BankAccount.Currency Then
				Record.Amount = DocumentLine.Payment;
			Else
				Record.Amount = DocumentLine.Payment * ExchangeRate;
			EndIf;
			Record.AmountRC = DocumentLine.Payment * ExchangeRate;
		
		EndIf;
		
		If TypeOf(DocumentObject.Ref) = Type("DocumentRef.SalesReturn") Then
		
			Record = RegisterRecords.GeneralJournal.AddDebit();
			Record.Account = DocumentObject.ARAccount;
			Record.Period = Date;
			Record.Amount = DocumentLine.Payment;
			Record.AmountRC = DocumentLine.Payment * DocumentObject.ExchangeRate;
			Record.Currency = DocumentObject.Currency;
			Record.ExtDimensions[ChartsOfCharacteristicTypes.Dimensions.Company] = Company;
			Record.ExtDimensions[ChartsOfCharacteristicTypes.Dimensions.Document] = DocumentObject.Ref;
			
			Record = RegisterRecords.GeneralJournal.AddCredit();
			Record.Account = BankAccount;
			Record.Currency = BankAccount.Currency;
			Record.Period = Date;
			If DocumentObject.Currency = BankAccount.Currency Then
				Record.Amount = DocumentLine.Payment;
			Else
				Record.Amount = DocumentLine.Payment * ExchangeRate;
			EndIf;
			Record.AmountRC = DocumentLine.Payment * ExchangeRate;
			
			//--------------------------------------------------------------------------------------------------------------------------
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
					Record.AmountRC    = -CurrentPaymentRC;
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
				Record.AmountRC    = -CurrentPaymentRC;
			EndIf;
			
			//Sales tax
			SumDoc = SumDoc + DocumentObject.SalesTaxRC;
			CurrentPaymentRC = ?(SumDoc = DocObjTotal, BalancePaymentRC, Round((DocumentObject.SalesTaxRC * DocumentLine.Payment / DocObjTotal) * ExchangeRate, 2));
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
				Record.AmountRC    = -CurrentPaymentRC;
			EndIf;		
			//--------------------------------------------------------------------------------------------------------------------------
			
		EndIf;
				
		FXGainLoss = (DocumentObject.ExchangeRate - ExchangeRate) * DocumentLine.Payment;
		
	    If FXGainLoss > 0 Then
			
			Record = RegisterRecords.GeneralJournal.AddCredit();
	    	Record.Account = Constants.ExchangeLoss.Get();
	    	Record.Period = Date;
	    	Record.AmountRC = FXGainLoss;
	    	
			
	  	Else
			If FXGainLoss < 0 Then
				
	    		Record = RegisterRecords.GeneralJournal.AddDebit();
	    		Record.Account = Constants.ExchangeLoss.Get();
	    		Record.Period = Date;
	    		Record.AmountRC = FXGainLoss * -1;
	    						
	    	Else
	    	EndIf;
	    EndIf;
			 
	EndDo;
	
	// Writing bank reconciliation data
			
	ReconciledDocumentsServerCall.AddDocumentForReconciliation(RegisterRecords, Ref, BankAccount, Date, -1 * DocumentTotalRC);
		
EndProcedure

Procedure UndoPosting(Cancel)
	
	//Remove physical num for checking
	PhysicalCheckNum = 0;
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	// Document date adjustment patch (tunes the date of drafts like for the new documents).
	If  WriteMode = DocumentWriteMode.Posting And Not Posted // Posting of new or draft (saved but unposted) document.
	And BegOfDay(Date) = BegOfDay(CurrentSessionDate()) Then // Operational posting (by the current date).
		// Shift document time to the time of posting.
		Date = CurrentSessionDate();
	EndIf;
	
	If PaymentMethod = Catalogs.PaymentMethods.Check Then
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
		
		Company = FillingData.Company;
		
		FillDocumentList(FillingData);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region PRIVATE_IMPLEMENTATION

// The procedure selects all vendor invoices and customer returns having an unpaid balance
// and fills in line items of an invoice payment.
//
Procedure FillDocumentList(BaseDocument)
		
	LineItems.Clear();
	
	Query = New Query;
	Query.Text = "SELECT
	             |	GeneralJournalBalance.AmountBalance * -1 AS AmountBalance,
	             |	GeneralJournalBalance.AmountRCBalance * -1 AS AmountRCBalance,
	             |	GeneralJournalBalance.ExtDimension2.Ref AS Ref,
				 |  GeneralJournalBalance.ExtDimension2.Date
	             |FROM
	             |	AccountingRegister.GeneralJournal.Balance AS GeneralJournalBalance
	             |WHERE
	             |	GeneralJournalBalance.AmountBalance <> 0
	             |	AND (GeneralJournalBalance.ExtDimension2 REFS Document.PurchaseInvoice OR
	             |       GeneralJournalBalance.ExtDimension2 REFS Document.SalesReturn)
	             |	AND GeneralJournalBalance.ExtDimension1 = &Company
				 |ORDER BY
				 |	GeneralJournalBalance.ExtDimension2.Date";
				 
	Query.SetParameter("Company", Company);
	
	Result = Query.Execute().Select();
	
	While Result.Next() Do
		
		If Result.Ref = BaseDocument Then
			
			DataLine = LineItems.Add();
			
			DataLine.Check      = True;
			DataLine.Document   = Result.Ref;
			DataLine.Currency   = Result.Ref.Currency;
			Dataline.BalanceFCY = Result.AmountBalance;
			DataLine.Payment    = Result.AmountBalance;
			Dataline.Balance    = Result.AmountRCBalance;
			
		EndIf;
		
	EndDo;	
	
	ExchangeRate = GeneralFunctions.GetExchangeRate(CurrentSessionDate(), Currency);
	DocumentTotal = LineItems.Total("Payment");
	If Constants.MultiCurrency.Get() Then
		DocumentTotalRC = LineItems.Total("Payment") * ExchangeRate;
	Else
		DocumentTotalRC = LineItems.Total("Payment");
	EndIf;
	
EndProcedure

//Function CheckNumberAllowed(Num)
//	
//	Try
//		CheckNum = Number(Number);
//	Except
//		Return True;
//	EndTry;

//	AllowDuplicateCheckNumbers = Constants.AllowDuplicateCheckNumbers.Get();
//	If AllowDuplicateCheckNumbers Then
//		return True;
//	EndIf;
//	Query = New Query("SELECT TOP 1
//	                  |	ChecksWithNumber.Number,
//	                  |	ChecksWithNumber.Ref
//	                  |FROM
//	                  |	(SELECT
//	                  |		Check.PhysicalCheckNum AS Number,
//	                  |		Check.Ref AS Ref
//	                  |	FROM
//	                  |		Document.Check AS Check
//	                  |	WHERE
//	                  |		Check.BankAccount = &BankAccount
//	                  |		AND Check.PaymentMethod = VALUE(Catalog.PaymentMethods.Check)
//	                  |		AND Check.PhysicalCheckNum = &CheckNum
//	                  |	
//	                  |	UNION ALL
//	                  |	
//	                  |	SELECT
//	                  |		InvoicePayment.PhysicalCheckNum,
//	                  |		InvoicePayment.Ref
//	                  |	FROM
//	                  |		Document.InvoicePayment AS InvoicePayment
//	                  |	WHERE
//	                  |		InvoicePayment.BankAccount = &BankAccount
//	                  |		AND InvoicePayment.PaymentMethod = VALUE(Catalog.PaymentMethods.Check)
//	                  |		AND InvoicePayment.PhysicalCheckNum = &CheckNum) AS ChecksWithNumber
//	                  |WHERE
//	                  |	ChecksWithNumber.Ref <> &CurrentRef");
//	Query.SetParameter("BankAccount", BankAccount);
//	Query.SetParameter("CheckNum", CheckNum);
//	Query.SetParameter("CurrentRef", Ref);
//	QueryResult = Query.Execute();
//	If QueryResult.IsEmpty() Then
//		Return True;
//	Else	
//		Return False;
//	EndIf;

//	//Try
//	//	CheckNum = Number(Object.Number);
//	//	Query = New Query("SELECT
//	//					  |	Check.PhysicalCheckNum AS Number,
//	//					  |	Check.Ref
//	//					  |FROM
//	//					  |	Document.Check AS Check
//	//					  |WHERE
//	//					  |	Check.BankAccount = &BankAccount
//	//					  |	AND Check.PaymentMethod = VALUE(Catalog.PaymentMethods.Check)
//	//					  |	AND Check.PhysicalCheckNum = &CheckNum
//	//					  |
//	//					  |UNION ALL
//	//					  |
//	//					  |SELECT
//	//					  |	InvoicePayment.PhysicalCheckNum,
//	//					  |	InvoicePayment.Ref
//	//					  |FROM
//	//					  |	Document.InvoicePayment AS InvoicePayment
//	//					  |WHERE
//	//					  |	InvoicePayment.BankAccount = &BankAccount
//	//					  |	AND InvoicePayment.PaymentMethod = VALUE(Catalog.PaymentMethods.Check)
//	//					  |	AND InvoicePayment.PhysicalCheckNum = &CheckNum
//	//					  |
//	//					  |ORDER BY
//	//					  |	Number DESC");
//	//	Query.SetParameter("BankAccount", Object.BankAccount);
//	//	Query.SetParameter("CheckNum", CheckNum);
//	//	//Query.SetParameter("Number", Object.Number);
//	//	QueryResult = Query.Execute().Unload();
//	//	If QueryResult.Count() = 0 Then
//	//		Return False;
//	//	ElsIf QueryResult.Count() = 1 And QueryResult[0].Ref = Object.Ref Then
//	//		Return False;
//	//	Else	

//	//		Return True;
//	//	EndIf;
//	//Except
//	//	Return False
//	//EndTry;
//		
//	
//EndFunction

#EndRegion

