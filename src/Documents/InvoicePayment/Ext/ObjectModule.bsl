
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
			
			For Each Item In DocumentObject.LineItems Do
				Record = RegisterRecords.CashFlowData.Add();
				Record.RecordType = AccumulationRecordType.Receipt;
				Record.Period = Date;
				Record.Company = Company;
				Record.Document = DocumentObject.Ref;
				Record.Account = Item.Product.IncomeAccount;
				//Record.Account = CurRowLineItems.Product.InventoryOrExpenseAccount;
				//Record.CashFlowSection = CurRowLineItems.Product.InventoryOrExpenseAccount.CashFlowSection;
				//Record.AmountRC = Item.LineTotal * ExchangeRate * -1;
				Record.AmountRC = -1 * ((Item.LineTotal * ExchangeRate) * DocumentLine.Payment)/DocumentObject.DocumentTotalRC
				//Record.PaymentMethod = PaymentMethod;
			EndDo

			
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
			
			DataLine.Document = Result.Ref;
			DataLine.Currency = Result.Ref.Currency;
			Dataline.BalanceFCY = Result.AmountBalance;
			Dataline.Balance = Result.AmountRCBalance;
			DataLine.Payment = 0;
			
		EndIf;
		
	EndDo;	
	
EndProcedure

#EndRegion

