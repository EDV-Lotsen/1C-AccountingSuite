
Procedure Posting(Cancel, PostingMode)
	
	RegisterRecords.GeneralJournal.Write = True;
	
	DefaultCurrency = GeneralFunctionsReusable.DefaultCurrency();
	If GeneralFunctionsReusable.FunctionalOptionValue("MultiCurrency") Then	
		TodayDefaultRate = GeneralFunctions.GetExchangeRate(Date, Currency);
		If ExchangeRate = 0 Then 
			// In case of empty exchrates from prev Periods
			ExchangeRate = 1
		EndIf;	
		CurrencyTo = AccountTo.Currency;
		If CurrencyTo = Currency And Currency = DefaultCurrency Then 
			TodayDefaultRate = 1;
		ElsIf Currency = DefaultCurrency Then 
			TodayDefaultRate = 1
		ElsIf CurrencyTo = DefaultCurrency Then 
			TodayDefaultRate = ExchangeRate;
		EndIf;;	
		
	Else 
		TodayDefaultRate = 1;
		ExchangeRate = 1;
		CurrencyTo = DefaultCurrency;
		AmountTo = Amount;
	EndIf;
	
	Record = RegisterRecords.GeneralJournal.AddDebit();
	Record.Account = AccountTo;
	Record.Period = Date;
	Record.Currency = CurrencyTo;
	Record.Amount = AmountTo;
	Record.AmountRC = Amount*TodayDefaultRate;
	
	//--//GJ++
	ReconciledDocumentsServerCall.AddRecordForGeneralJournalAnalyticsDimensions(RegisterRecords, Record, Null, Null, Null);
	//--//GJ--
	
	Record = RegisterRecords.GeneralJournal.AddCredit();
	Record.Account = AccountFrom;
	Record.Period = Date;
	Record.Currency = Currency;
	Record.Amount = Amount;
	Record.AmountRC = Amount*TodayDefaultRate;
	
	//--//GJ++
	ReconciledDocumentsServerCall.AddRecordForGeneralJournalAnalyticsDimensions(RegisterRecords, Record, Null, Null, Null);
	//--//GJ--
	
	//CASH BASIS--------------------------------------------------------------------------------------------------
	//------------------------------------------------------------------------------------------------------------
	RegisterRecords.CashFlowData.Write = True;
	
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
		Record.PaymentMethod = Null;;
		
	EndDo;
	//------------------------------------------------------------------------------------------------------------
	//CASH BASIS (end)--------------------------------------------------------------------------------------------
	
	// Writing bank reconciliation data
		
	ReconciledDocumentsServerCall.AddDocumentForReconciliation(RegisterRecords, Ref, AccountFrom, Date, -1 * Amount*TodayDefaultRate);
	ReconciledDocumentsServerCall.AddDocumentForReconciliation(RegisterRecords, Ref, AccountTo, Date, Amount*TodayDefaultRate);
	
EndProcedure

