
//1. Upload this configuration using filter "Show objects available only in the file";
//2. Add a new update module in a procedure "MakeChanges()";
//3. Rename (in 2 places) "NAME OF ACTION" to a new name of action; 

&AtServer
Procedure CB_Update() Export
	
	If Constants.CB_Update.Get() Then
		Return;
	EndIf;
	
	Cancel = False; 
	
	MakeChanges(Cancel);
	
	If Cancel Then
		WriteNotification("ERROR");
	Else
		WriteNotification("5. Done");
	EndIf;
	
	Constants.CB_Update.Set(True);
	
EndProcedure

&AtServer
Procedure WriteNotification(NotificationText)
	
	CatalogObject = Catalogs.CB_Update.CreateItem();
	CatalogObject.Notice = NotificationText;
	CatalogObject.Time   = CurrentSessionDate();
	CatalogObject.Write();
	
EndProcedure

&AtServer
Procedure MakeChanges(Cancel)
	
	Try
		BeginTransaction(DataLockControlMode.Managed);
		
		//--------------------------------------------------
		//--------------------------------------------------
		//--------------------------------------------------
		UpdateRegisters();
		//--------------------------------------------------
		//--------------------------------------------------
		//--------------------------------------------------
		
		WriteLogEvent(
		"Infobase.UpdatingInfobase",
		EventLogLevel.Information,
		,
		,
		"Update an dimension ""Company"" for registers (GeneralJournalAnalyticsDimensions and CashFlowData): succeeded.");//--//
		
	Except
		
		Cancel = True;
		
		ErrorDescription = ErrorDescription();
		If TransactionActive() Then
			RollbackTransaction();
		EndIf;
		
		WriteLogEvent(
		"Infobase.UpdatingInfobase",
		EventLogLevel.Error,
		,
		,
		"Update an dimension ""Company"" for registers (GeneralJournalAnalyticsDimensions and CashFlowData) - during the update an error occured: " + ErrorDescription);//--//
		
		Return;
		
	EndTry;
	
	CommitTransaction();
	
EndProcedure

&AtServer
Procedure UpdateRegisters()
	
	//1. GeneralJournalAnalyticsDimensions
	Query = New Query;
	Query.Text = 
	"SELECT DISTINCT
	|	GJAD.Recorder AS Recorder
	|FROM
	|	AccumulationRegister.GeneralJournalAnalyticsDimensions AS GJAD
	|WHERE
	|	(GJAD.Recorder REFS Document.CashReceipt
	|			OR GJAD.Recorder REFS Document.CashSale
	|			OR GJAD.Recorder REFS Document.Check
	|			OR GJAD.Recorder REFS Document.InvoicePayment
	|			OR GJAD.Recorder REFS Document.ItemReceipt
	|			OR GJAD.Recorder REFS Document.PurchaseInvoice
	|			OR GJAD.Recorder REFS Document.PurchaseReturn
	|			OR GJAD.Recorder REFS Document.SalesInvoice
	|			OR GJAD.Recorder REFS Document.SalesReturn
	|			OR GJAD.Recorder REFS Document.Shipment)";
	
	QueryResult = Query.Execute();
	
	SDR = QueryResult.Select();
	
	While SDR.Next() Do
		
		//Message("" + SDR.Recorder);
		
		RecordSet =  AccumulationRegisters.GeneralJournalAnalyticsDimensions.CreateRecordSet();
		RecordSet.Filter.Recorder.Set(SDR.Recorder);
		RecordSet.Read();
		
		NewVT = RecordSet.Unload(); 
		
		For Each CurrentRow In NewVT Do
			CurrentRow.Company = CurrentRow.Recorder.Company;	
		EndDo;
		
		RecordSet.Load(NewVT);
		RecordSet.Write(True);
		
	EndDo;
	
	WriteNotification("1. Done");
	
	//2. CashFlowData
	Query = New Query;
	Query.Text = 
	"SELECT DISTINCT
	|	CFD.Recorder AS Recorder,
	|	CFD.Document AS Document
	|FROM
	|	AccumulationRegister.CashFlowData AS CFD
	|WHERE
	|	(CFD.Document REFS Document.CashReceipt
	|			OR CFD.Document REFS Document.CashSale
	|			OR CFD.Document REFS Document.Check
	|			OR CFD.Document REFS Document.InvoicePayment
	|			OR CFD.Document REFS Document.ItemReceipt
	|			OR CFD.Document REFS Document.PurchaseInvoice
	|			OR CFD.Document REFS Document.PurchaseReturn
	|			OR CFD.Document REFS Document.SalesInvoice
	|			OR CFD.Document REFS Document.SalesReturn
	|			OR CFD.Document REFS Document.Shipment)";
	
	QueryResult = Query.Execute();
	
	SDR = QueryResult.Select();
	
	While SDR.Next() Do
		
		//Message("" + SDR.Recorder);
		
		RecordSet =  AccumulationRegisters.CashFlowData.CreateRecordSet();
		RecordSet.Filter.Recorder.Set(SDR.Recorder);
		RecordSet.Read();
		
		NewVT = RecordSet.Unload(); 
		
		For Each CurrentRow In NewVT Do
			CurrentRow.Company = CurrentRow.Document.Company;	
		EndDo;
		
		RecordSet.Load(NewVT);
		RecordSet.Write(True);
		
	EndDo;
	
	WriteNotification("2. Done");
	
	//3. Deposit
	Query = New Query;
	Query.Text = 
	"SELECT DISTINCT
	|	GJAD.Recorder AS Recorder
	|FROM
	|	AccumulationRegister.GeneralJournalAnalyticsDimensions AS GJAD
	|WHERE
	|	GJAD.Recorder REFS Document.Deposit";
	
	QueryResult = Query.Execute();
	
	SDR = QueryResult.Select();
	
	While SDR.Next() Do
		
		//Message("" + SDR.Recorder);
		
		RecordSetGJAD =  AccumulationRegisters.GeneralJournalAnalyticsDimensions.CreateRecordSet();
		RecordSetGJAD.Filter.Recorder.Set(SDR.Recorder);
		NewVT_GJAD = RecordSetGJAD.Unload(); 
		
		RecordSetCFD =  AccumulationRegisters.CashFlowData.CreateRecordSet();
		RecordSetCFD.Filter.Recorder.Set(SDR.Recorder);
		NewVT_CFD = RecordSetCFD.Unload(); 
		
		DocDeposit(SDR.Recorder, NewVT_GJAD, NewVT_CFD);
		
		RecordSetGJAD.Load(NewVT_GJAD);
		RecordSetGJAD.Write(True);
		
		RecordSetCFD.Load(NewVT_CFD);
		RecordSetCFD.Write(True);
		
	EndDo;
	
	WriteNotification("3. Done");
	
	//4. GeneralJournalEntry
	Query = New Query;
	Query.Text = 
	"SELECT DISTINCT
	|	GJAD.Recorder AS Recorder
	|FROM
	|	AccumulationRegister.GeneralJournalAnalyticsDimensions AS GJAD
	|WHERE
	|	GJAD.Recorder REFS Document.GeneralJournalEntry";
	
	QueryResult = Query.Execute();
	
	SDR = QueryResult.Select();
	
	While SDR.Next() Do
		
		//Message("" + SDR.Recorder);
		
		RecordSetGJAD =  AccumulationRegisters.GeneralJournalAnalyticsDimensions.CreateRecordSet();
		RecordSetGJAD.Filter.Recorder.Set(SDR.Recorder);
		NewVT_GJAD = RecordSetGJAD.Unload(); 
		
		RecordSetCFD =  AccumulationRegisters.CashFlowData.CreateRecordSet();
		RecordSetCFD.Filter.Recorder.Set(SDR.Recorder);
		NewVT_CFD = RecordSetCFD.Unload(); 
		
		DocGeneralJournalEntry(SDR.Recorder, NewVT_GJAD, NewVT_CFD);
		
		RecordSetGJAD.Load(NewVT_GJAD);
		RecordSetGJAD.Write(True);
		
		RecordSetCFD.Load(NewVT_CFD);
		RecordSetCFD.Write(True);
		
	EndDo;
	
	WriteNotification("4. Done");
	
EndProcedure

&AtServer
Procedure DocDeposit(Ref, NewVT_GJAD, NewVT_CFD)
	
	AccountCurrency = CommonUse.GetAttributeValue(Ref.BankAccount, "Currency");
	ExchangeRate    = GeneralFunctions.GetExchangeRate(Ref.Date, AccountCurrency);	
	
	Record = NewVT_GJAD.Add();
	
	Record.RecordType = AccumulationRecordType.Receipt;
	Record.Account    = Ref.BankAccount;
	Record.Period     = Ref.Date;
	Record.AmountRC   = Ref.DocumentTotalRC;
	Record.Class      = Null;
	Record.Project    = Null;
	Record.Company	  = Null;
	Record.Active     = True;
	
	If NOT Ref.TotalDepositsRC = 0 Then
		
		Record = NewVT_GJAD.Add();
		
		Record.RecordType = AccumulationRecordType.Expense;
		Record.Account    = Constants.UndepositedFundsAccount.Get();
		Record.Period     = Ref.Date;
		Record.AmountRC   = Ref.TotalDepositsRC;
		Record.Class      = Null;
		Record.Project    = Null;
		Record.Company	  = Null;
		Record.Active     = True;
		
	EndIf;
	
	For Each AccountLine in Ref.Accounts Do
		
		If AccountLine.Amount > 0 Then
			
			Record = NewVT_GJAD.Add();
			
			Record.RecordType = AccumulationRecordType.Expense; 
			Record.Account    = AccountLine.Account;
			Record.Period     = Ref.Date;
			Record.AmountRC   = AccountLine.Amount * ExchangeRate;
			Record.Class      = AccountLine.Class;
			Record.Project    = AccountLine.Project;
			Record.Company	  = AccountLine.Company;
			Record.Active     = True;
			
		ElsIf AccountLine.Amount < 0 Then
			
			Record = NewVT_GJAD.Add();
			
			Record.RecordType = AccumulationRecordType.Receipt; 
			Record.Account    = AccountLine.Account;
			Record.Period     = Ref.Date;
			Record.AmountRC   = AccountLine.Amount * -ExchangeRate;
			Record.Class      = AccountLine.Class;
			Record.Project    = AccountLine.Project;
			Record.Company	  = AccountLine.Company;
			Record.Active     = True;
			
		EndIf;
		
	EndDo;
	
	//CASH BASIS--------------------------------------------------------------------------------------------------
	//------------------------------------------------------------------------------------------------------------
	For Each CurrentTrans In NewVT_GJAD Do
		
		Record = NewVT_CFD.Add();
		Record.RecordType    = CurrentTrans.RecordType;
		Record.Period        = CurrentTrans.Period;
		Record.Account       = CurrentTrans.Account;
		Record.Company       = CurrentTrans.Company;
		Record.Document      = Ref;
		Record.SalesPerson   = Null;
		Record.Class         = CurrentTrans.Class;
		Record.Project       = CurrentTrans.Project;
		Record.AmountRC      = CurrentTrans.AmountRC;
		Record.PaymentMethod = Null;
		Record.Active        = CurrentTrans.Active;
		
	EndDo;
	//------------------------------------------------------------------------------------------------------------
	//CASH BASIS (end)--------------------------------------------------------------------------------------------
		
EndProcedure

&AtServer
Procedure DocGeneralJournalEntry(Ref, NewVT_GJAD, NewVT_CFD)
	
	For Each CurRowLineItems In Ref.LineItems Do
		
		Amount = 0;
		
		If CurRowLineItems.AmountDr > 0 Then
			Record = NewVT_GJAD.Add();
			Record.RecordType = AccumulationRecordType.Receipt;	
			Amount = CurRowLineItems.AmountDr;
		Else
			Record = NewVT_GJAD.Add();
			Record.RecordType = AccumulationRecordType.Expense;	
			Amount = CurRowLineItems.AmountCr;
		EndIf;
		
		Record.Period   = Ref.Date;
		Record.Account  = CurRowLineItems.Account;
		Record.AmountRC = Amount * Ref.ExchangeRate;
		
		Record.Class    = CurRowLineItems.Class;
		Record.Project  = CurRowLineItems.Project;
		Record.Company	= ?(ValueIsFilled(Ref.VoidingEntry), Ref.VoidingEntry.Company, CurRowLineItems.Company);
		Record.Active   = True;
	
	EndDo;	
	
	//CASH BASIS--------------------------------------------------------------------------------------------------
	//------------------------------------------------------------------------------------------------------------
	
	//1.
	If ValueIsFilled(Ref.VoidingEntry) Then
		For Each CurrentRow In Ref.LineItems Do
			
			DocRef             = CurrentRow.VoidedEntry;
			CurrentRowAmountRC = Round(?(CurrentRow.AmountCr <> 0, CurrentRow.AmountCr, CurrentRow.AmountDr) * DocRef.ExchangeRate, 2);
			
			If ValueIsFilled(DocRef) Then
				
				//PurchaseInvoice-----------------------------------------------------------------------------------------
				//--------------------------------------------------------------------------------------------------------
				If TypeOf(DocRef) = Type("DocumentRef.PurchaseInvoice")
					And CurrentRow.Account.AccountType = Enums.AccountTypes.AccountsPayable Then
					
					//1.
					SumFirstTrans = 0;
					
					RecordSet =  AccumulationRegisters.GeneralJournalAnalyticsDimensions.CreateRecordSet();
					RecordSet.Filter.Recorder.Set(DocRef);
					RecordSet.Read();
					
					For Each CurrentTrans In RecordSet Do
						If CurrentTrans.RecordType = AccumulationRecordType.Receipt
							AND CurrentTrans.Account.AccountType <> Enums.AccountTypes.AccountsReceivable 
							AND CurrentTrans.Account.AccountType <> Enums.AccountTypes.AccountsPayable Then
							SumFirstTrans  = SumFirstTrans + ?(CurrentTrans.RecordType = AccumulationRecordType.Receipt, CurrentTrans.AmountRC, CurrentTrans.AmountRC * -1);
						EndIf;
					EndDo;
					
					//2.
					FirstFullPaymentAmountRC  = CurrentRowAmountRC;
					FirstBalancePaymentRC     = FirstFullPaymentAmountRC;
					
					ActualSumFirstTrans       = 0;
					APAmount                  = 0;
					
					For Each CurrentTrans In RecordSet Do
						If CurrentTrans.RecordType = AccumulationRecordType.Receipt
							AND (CurrentTrans.Account.AccountType = Enums.AccountTypes.Income
							OR CurrentTrans.Account.AccountType = Enums.AccountTypes.CostOfSales
							OR CurrentTrans.Account.AccountType = Enums.AccountTypes.Expense
							OR CurrentTrans.Account.AccountType = Enums.AccountTypes.OtherIncome
							OR CurrentTrans.Account.AccountType = Enums.AccountTypes.OtherExpense
							OR CurrentTrans.Account.AccountType = Enums.AccountTypes.IncomeTaxExpense) Then
							
							PaymentRC        = 0;
							CurrentPaymentRC = 0;
							
							ActualSumFirstTrans    = ActualSumFirstTrans + CurrentTrans.AmountRC;
							PaymentRC              = ?(SumFirstTrans = 0, 0, Round(CurrentTrans.AmountRC * FirstFullPaymentAmountRC / SumFirstTrans, 2));
							CurrentPaymentRC       = ?(ActualSumFirstTrans = SumFirstTrans, FirstBalancePaymentRC, PaymentRC);
							FirstBalancePaymentRC  = FirstBalancePaymentRC - CurrentPaymentRC; 
							
							If CurrentPaymentRC <> 0 Then 
								Record = NewVT_CFD.Add();
								Record.RecordType    = ?(CurrentTrans.RecordType = AccumulationRecordType.Receipt, AccumulationRecordType.Expense, AccumulationRecordType.Receipt);
								Record.Period        = Ref.Date;
								Record.Account       = CurrentTrans.Account;
								Record.Company       = Ref.VoidingEntry.Company;
								Record.Document      = DocRef;
								Record.SalesPerson   = Null;
								Record.Class         = CurrentTrans.Class;
								Record.Project       = CurrentTrans.Project;
								Record.AmountRC      = CurrentPaymentRC;
								Record.PaymentMethod = Ref.VoidingEntry.PaymentMethod;
								Record.Active        = True;	
								
								APAmount = APAmount + ?(Record.RecordType = AccumulationRecordType.Receipt, Record.AmountRC * -1, Record.AmountRC); 
							EndIf;
							
						EndIf;
					EndDo;
					
					If APAmount <> 0 Then
						Record = NewVT_CFD.Add();
						Record.RecordType    = ?(APAmount > 0, AccumulationRecordType.Receipt, AccumulationRecordType.Expense);
						Record.Period        = Ref.Date;
						Record.Account       = DocRef.APAccount;
						Record.Company       = Ref.VoidingEntry.Company;
						Record.Document      = DocRef;
						Record.SalesPerson   = Null;
						Record.Class         = Null;
						Record.Project       = Null;
						Record.AmountRC      = ?(APAmount > 0, APAmount, APAmount * -1);
						Record.PaymentMethod = Ref.VoidingEntry.PaymentMethod;
						Record.Active        = True;
					EndIf;
					
				//SalesReturn---------------------------------------------------------------------------------------------
				//--------------------------------------------------------------------------------------------------------
				ElsIf TypeOf(DocRef) = Type("DocumentRef.SalesReturn")
					And CurrentRow.Account.AccountType = Enums.AccountTypes.AccountsReceivable Then
					
					//1.
					SumFirstTrans  = 0;
					SumSecondTrans = 0;
					
					RecordSet =  AccumulationRegisters.GeneralJournalAnalyticsDimensions.CreateRecordSet();
					RecordSet.Filter.Recorder.Set(DocRef);
					RecordSet.Read();
					
					For Each CurrentTrans In RecordSet Do
						If CurrentTrans.JournalEntryIntNum = 1 And CurrentTrans.JournalEntryMainRec Then
							SumFirstTrans  = SumFirstTrans + ?(CurrentTrans.RecordType = AccumulationRecordType.Expense, CurrentTrans.AmountRC, CurrentTrans.AmountRC * -1);
						ElsIf  CurrentTrans.JournalEntryIntNum = 2 And CurrentTrans.JournalEntryMainRec Then 
							SumSecondTrans = SumSecondTrans + ?(CurrentTrans.RecordType = AccumulationRecordType.Expense, CurrentTrans.AmountRC, CurrentTrans.AmountRC * -1);
						EndIf;
					EndDo;
					
					//2.
					FirstFullPaymentAmountRC  = CurrentRowAmountRC;
					FirstBalancePaymentRC     = FirstFullPaymentAmountRC;
					
					SecondFullPaymentAmountRC = ?(SumFirstTrans = 0, 0, Round(SumSecondTrans * FirstFullPaymentAmountRC / SumFirstTrans, 2));
					SecondBalancePaymentRC    = SecondFullPaymentAmountRC;
					
					ActualSumFirstTrans       = 0;
					ActualSumSecondTrans      = 0;
					
					ARAmount                  = 0;
					
					For Each CurrentTrans In RecordSet Do
						If CurrentTrans.Account.AccountType = Enums.AccountTypes.Income
							OR CurrentTrans.Account.AccountType = Enums.AccountTypes.CostOfSales
							OR CurrentTrans.Account.AccountType = Enums.AccountTypes.Expense
							OR CurrentTrans.Account.AccountType = Enums.AccountTypes.OtherIncome
							OR CurrentTrans.Account.AccountType = Enums.AccountTypes.OtherExpense
							OR CurrentTrans.Account.AccountType = Enums.AccountTypes.IncomeTaxExpense
							OR CurrentTrans.Account = Constants.TaxPayableAccount.Get() Then
							
							PaymentRC        = 0;
							CurrentPaymentRC = 0;
							
							If CurrentTrans.JournalEntryIntNum = 1 Then
								
								ActualSumFirstTrans    = ActualSumFirstTrans + CurrentTrans.AmountRC;
								PaymentRC              = ?(SumFirstTrans = 0, 0, Round(CurrentTrans.AmountRC * FirstFullPaymentAmountRC / SumFirstTrans, 2));
								CurrentPaymentRC       = ?(ActualSumFirstTrans = SumFirstTrans, FirstBalancePaymentRC, PaymentRC);
								FirstBalancePaymentRC  = FirstBalancePaymentRC - CurrentPaymentRC; 
								
							ElsIf CurrentTrans.JournalEntryIntNum = 2 Then 
								
								ActualSumSecondTrans   = ActualSumSecondTrans + CurrentTrans.AmountRC;
								PaymentRC              = ?(SumSecondTrans = 0, 0, Round(CurrentTrans.AmountRC * SecondFullPaymentAmountRC / SumSecondTrans, 2));
								CurrentPaymentRC       = ?(ActualSumSecondTrans = SumSecondTrans, SecondBalancePaymentRC, PaymentRC);
								SecondBalancePaymentRC = SecondBalancePaymentRC - CurrentPaymentRC; 
								
							EndIf;
							
							If CurrentPaymentRC <> 0 Then 
								Record = NewVT_CFD.Add();
								Record.RecordType    = ?(CurrentTrans.RecordType = AccumulationRecordType.Receipt, AccumulationRecordType.Expense, AccumulationRecordType.Receipt);
								Record.Period        = Ref.Date;
								Record.Account       = CurrentTrans.Account;
								Record.Company       = Ref.VoidingEntry.Company;
								Record.Document      = DocRef;
								Record.SalesPerson   = DocRef.SalesPerson;
								Record.Class         = CurrentTrans.Class;
								Record.Project       = CurrentTrans.Project;
								Record.AmountRC      = CurrentPaymentRC;
								Record.PaymentMethod = Null;
								Record.Active        = True;
								
								ARAmount = ARAmount + ?(Record.RecordType = AccumulationRecordType.Receipt, Record.AmountRC * -1, Record.AmountRC); 
							EndIf;
							
						EndIf;
					EndDo;
					
					If ARAmount <> 0 Then
						Record = NewVT_CFD.Add();
						Record.RecordType    = ?(ARAmount > 0, AccumulationRecordType.Receipt, AccumulationRecordType.Expense);
						Record.Period        = Ref.Date;
						Record.Account       = DocRef.ARAccount;
						Record.Company       = Ref.VoidingEntry.Company;
						Record.Document      = DocRef;
						Record.SalesPerson   = DocRef.SalesPerson;
						Record.Class         = Null;
						Record.Project       = Null;
						Record.AmountRC      = ?(ARAmount > 0, ARAmount, ARAmount * -1);
						Record.PaymentMethod = Null;
						Record.Active        = True;
					EndIf;
					
				EndIf;
				
			EndIf;
			
		EndDo;
	EndIf;

	//2.
	For Each CurrentTrans In NewVT_GJAD Do
		
		Record = NewVT_CFD.Add();
		Record.RecordType    = CurrentTrans.RecordType;
		Record.Period        = CurrentTrans.Period;
		Record.Account       = CurrentTrans.Account;
		Record.Company       = CurrentTrans.Company;
		Record.Document      = ?(ValueIsFilled(Ref.VoidingEntry), Ref.VoidingEntry.Ref, Ref);
		Record.SalesPerson   = Null;
		Record.Class         = CurrentTrans.Class;
		Record.Project       = CurrentTrans.Project;
		Record.AmountRC      = CurrentTrans.AmountRC;
		Record.PaymentMethod = ?(ValueIsFilled(Ref.VoidingEntry), Ref.VoidingEntry.PaymentMethod, Null);
		Record.Active        = CurrentTrans.Active;
		
	EndDo;
	//------------------------------------------------------------------------------------------------------------
	//CASH BASIS (end)--------------------------------------------------------------------------------------------
	
EndProcedure
