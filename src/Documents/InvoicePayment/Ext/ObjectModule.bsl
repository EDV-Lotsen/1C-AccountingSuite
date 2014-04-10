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
	    	Record.Account = Constants.ExchangeGain.Get();
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
	
	Records = InformationRegisters.TransactionReconciliation.CreateRecordSet();
	Records.Filter.Document.Set(Ref);
	Records.Read();
	If Records.Count() = 0 Then
		Record = Records.Add();
		Record.Document = Ref;
		Record.Account = BankAccount;
		Record.Reconciled = False;
		Record.Amount = -1 * DocumentTotalRC;		
	Else
		Records[0].Account = BankAccount;
		Records[0].Amount = -1 * DocumentTotalRC;
	EndIf;
	Records.Write();
	
	//Records = InformationRegisters.TransactionReconciliation.CreateRecordSet();
	//Records.Filter.Document.Set(Ref);
	//Records.Filter.Account.Set(BankAccount);
	//Record = Records.Add();
	//Record.Document = Ref;
	//Record.Account = BankAccount;
	//Record.Reconciled = False;
	//Record.Amount = -1 * DocumentTotalRC;
	//Records.Write();
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	//Remove physical num for checking
	PhysicalCheckNum = 0;
	
	// Deleting bank reconciliation data
	
	Records = InformationRegisters.TransactionReconciliation.CreateRecordManager();
	Records.Document = Ref;
	Records.Account = BankAccount;
	Records.Read();
	Records.Delete();
		

EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
		
	If WriteMode = DocumentWriteMode.Write AND PaymentMethod = Catalogs.PaymentMethods.Check Then
		Number = "DRAFT";
	EndIf;

EndProcedure

Procedure BeforeDelete(Cancel)
	
	TRRecordset = InformationRegisters.TransactionReconciliation.CreateRecordSet();
	TRRecordset.Filter.Document.Set(ThisObject.Ref);
	TRRecordset.Write(True);

EndProcedure