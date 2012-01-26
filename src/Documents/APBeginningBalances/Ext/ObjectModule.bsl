// The procedure performs document posting
//
Procedure Posting(Cancel, PostingMode)
	
	NewDocum = Documents.PurchaseInvoice.CreateDocument();
	NewDocum.Company = Company;
	If GetFunctionalOption("MultiCurrency") Then
		NewDocum.DocumentTotal = Amount;
	Else
		NewDocum.DocumentTotal = AmountRC;
	EndIf;
	NewDocum.DocumentTotalRC = AmountRC;
	// NewDocum.Currency = Constants.DefaultCurrency.Get();
	NewDocum.Currency = Company.DefaultCurrency;
	If GetFunctionalOption("MultiCurrency") Then
		NewDocum.ExchangeRate = AmountRC / Amount;
	Else
		NewDocum.ExchangeRate = 1;
	EndIf;
	NewDocum.Date = Constants.BeginningBalancesDate.Get();
	NewDocum.DueDate = DueDate;
	NewDocum.APAccount = Company.DefaultCurrency.DefaultAPAccount;
	NewDocum.Posted = True;
	NewDocum.DocPosted = True;
	NewDocum.APBegBal = Ref;
	NewDocum.Write();
	
	Reg = AccountingRegisters.GeneralJournal.CreateRecordSet();
	Reg.Filter.Recorder.Set(NewDocum.Ref);
	Reg.Clear();
	RegLine = Reg.AddCredit();
	//RegLine.Account = Constants.APAccount.Get();
	RegLine.Account = Company.DefaultCurrency.DefaultAPAccount;
	RegLine.Period = Constants.BeginningBalancesDate.Get();
	If GetFunctionalOption("MultiCurrency") Then
		RegLine.Amount = Amount;
	Else
		RegLine.Amount = AmountRC;
	EndIf;
	RegLine.AmountRC = AmountRC;
	//RegLine.Currency = Constants.DefaultCurrency.Get();
	RegLine.Currency = Company.DefaultCurrency;
	RegLine.ExtDimensions[ChartsOfCharacteristicTypes.Dimensions.Company] = Company;
	RegLine.ExtDimensions[ChartsOfCharacteristicTypes.Dimensions.Document] = NewDocum.Ref;
	Reg.Write(False);

EndProcedure

// The procedure prevents re-posting if a purchase invoice created based on this beginning balance exists.
//
Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If Posted Then
		
		Query = New Query("SELECT
						  |	PurchaseInvoice.Ref
						  |FROM
						  |	Document.PurchaseInvoice AS PurchaseInvoice
						  |WHERE
						  |	PurchaseInvoice.APBegBal = &Ref");
						  
		Query.SetParameter("Ref", Ref);
		
		QueryResult = Query.Execute();

		If QueryResult.IsEmpty() Then	
		Else
			Dataset = QueryResult.Unload();
			Message = New UserMessage();
			PurchaseInvoice = String(Dataset[0][0]);		
			Message.Text = ("Delete first this Purchase Invoice: " + PurchaseInvoice + " and unpost the beginning balance");
			Message.Message();
			Cancel = True;
			Return;
		EndIf;						  
	
    EndIf;

EndProcedure

