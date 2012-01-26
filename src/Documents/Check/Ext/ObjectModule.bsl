
Procedure Filling(FillingData, StandardProcessing)
	
	If TypeOf(FillingData) = Type("DocumentRef.Payment") Then
		
		// Check if a Check is already created. If found - cancel.
		
		Query = New Query("SELECT
		                  |	Check.Ref
		                  |FROM
		                  |	Document.Check AS Check
		                  |WHERE
		                  |	Check.ParentDocument = &Ref");
		Query.SetParameter("Ref", FillingData.Ref);
		QueryResult = Query.Execute();
		If NOT QueryResult.IsEmpty() Then
			Message = New UserMessage();
			Message.Text=NStr("en='Check is already created based on this Payment'");
			Message.Message();
			DontCreate = True;
			Return;
		EndIf;
		
		Company = FillingData.Company;
		Memo = FillingData.Memo;
		BankAccount = FillingData.BankAccount;
		ParentDocument = FillingData.Ref;
		DocumentTotal = FillingData.DocumentTotal;
		DocumentTotalRC = FillingData.DocumentTotalRC;
		
		AccountCurrency = GeneralFunctions.GetAttributeValue(BankAccount, "Currency");
		ExchangeRate = GeneralFunctions.GetExchangeRate(CurrentDate(), GeneralFunctionsReusable.DefaultCurrency(), AccountCurrency);
		
		Number = GeneralFunctions.NextCheckNumber(BankAccount);	
		
	EndIf;
	
	If TypeOf(FillingData) = Type("DocumentRef.CashPurchase") Then
		
		// Check if a Check is already created. If found - cancel.
		
		Query = New Query("SELECT
		                  |	Check.Ref
		                  |FROM
		                  |	Document.Check AS Check
		                  |WHERE
		                  |	Check.ParentDocument = &Ref");
		Query.SetParameter("Ref", FillingData.Ref);
		QueryResult = Query.Execute();
		If NOT QueryResult.IsEmpty() Then
			Message = New UserMessage();
			Message.Text=NStr("en='Check is already created based on this Cash Purchase'");
			Message.Message();
			DontCreate = True;
			Return;
		EndIf;
		
		Company = FillingData.Company;
		Memo = FillingData.Memo;
		BankAccount = FillingData.BankAccount;
		ParentDocument = FillingData.Ref;
		DocumentTotal = FillingData.DocumentTotal;
		DocumentTotalRC = FillingData.DocumentTotalRC;
		
		AccountCurrency = GeneralFunctions.GetAttributeValue(BankAccount, "Currency");
		ExchangeRate = GeneralFunctions.GetExchangeRate(CurrentDate(), GeneralFunctionsReusable.DefaultCurrency(), AccountCurrency);
		
		Number = GeneralFunctions.NextCheckNumber(BankAccount);	
		
	EndIf;
		  					  
EndProcedure

// Performs document posting
//
Procedure Posting(Cancel, PostingMode)
	
	If ParentDocument = Undefined Then
	
		RegisterRecords.GeneralJournal.Write = True;	
		
		For Each CurRowLineItems In LineItems Do			
								
			Record = RegisterRecords.GeneralJournal.AddDebit();
			Record.Account = CurRowLineItems.Account;
			Record.Period = Date;
			Record.AmountRC = CurRowLineItems.Amount * ExchangeRate;
			
		EndDo;
		
		Record = RegisterRecords.GeneralJournal.AddCredit();
		Record.Account = BankAccount;
		Record.Currency = BankAccount.Currency;
		Record.Period = Date;
		Record.Amount = DocumentTotal;
		Record.AmountRC = DocumentTotalRC;
	
	EndIf;
	
EndProcedure
