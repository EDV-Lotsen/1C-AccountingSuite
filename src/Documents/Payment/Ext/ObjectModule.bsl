// The procedure posts a payment document. Also an FX gain or loss is calculated and posted.
//
Procedure Posting(Cancel, Mode)
		
	For Each DocumentLine In LineItems Do
	
		DocumentObject = DocumentLine.Document.GetObject();
		 	 
		ExchangeRate = GeneralFunctions.GetExchangeRate(Date, GeneralFunctionsReusable.DefaultCurrency(), DocumentObject.Currency);
		 
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
	
	
EndProcedure