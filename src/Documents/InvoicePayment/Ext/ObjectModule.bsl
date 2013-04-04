// The procedure posts a payment document. Also an FX gain or loss is calculated and posted.
//
Procedure Posting(Cancel, Mode)
	
	// preventing posting if already included in a bank rec
	
	Query = New Query("SELECT
					  |	TransactionReconciliation.Document
					  |FROM
					  |	InformationRegister.TransactionReconciliation AS TransactionReconciliation
					  |WHERE
					  |	TransactionReconciliation.Document = &Ref
					  |	AND TransactionReconciliation.Reconciled = TRUE");
	Query.SetParameter("Ref", Ref);
	Selection = Query.Execute();
	
	If NOT Selection.IsEmpty() Then
		
		Message = New UserMessage();
		Message.Text=NStr("en='This document is already included in a bank reconciliation. Please remove it from the bank rec first.'");
		Message.Message();
		Cancel = True;
		Return;
		
	EndIf;

	// end preventing posting if already included in a bank rec
	
	For Each DocumentLine In LineItems Do
	
		DocumentObject = DocumentLine.Document.GetObject();
		 	 
		ExchangeRate = GeneralFunctions.GetExchangeRate(Date, DocumentObject.Currency);
		 
		RegisterRecords.GeneralJournal.Write = True;
		
		If TypeOf(DocumentObject.Ref) = Type("DocumentRef.PurchaseInvoice") Then
		
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
	
	// preventing posting if already included in a bank rec
	
	Query = New Query("SELECT
					  |	TransactionReconciliation.Document
					  |FROM
					  |	InformationRegister.TransactionReconciliation AS TransactionReconciliation
					  |WHERE
					  |	TransactionReconciliation.Document = &Ref
					  |	AND TransactionReconciliation.Reconciled = TRUE");
	Query.SetParameter("Ref", Ref);
	Selection = Query.Execute();
	
	If NOT Selection.IsEmpty() Then
		
		Message = New UserMessage();
		Message.Text=NStr("en='This document is already included in a bank reconciliation. Please remove it from the bank rec first.'");
		Message.Message();
		Cancel = True;
		Return;
		
	EndIf;

	// end preventing posting if already included in a bank rec
	
	// Deleting bank reconciliation data
	
	Records = InformationRegisters.TransactionReconciliation.CreateRecordManager();
	Records.Document = Ref;
	Records.Account = BankAccount;
	Records.Read();
	Records.Delete();

EndProcedure

