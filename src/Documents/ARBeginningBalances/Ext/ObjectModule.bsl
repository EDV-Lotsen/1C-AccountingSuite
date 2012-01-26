// The procedure performs document posting
//
Procedure Posting(Cancel, PostingMode)
	
	NewDocum = Documents.SalesInvoice.CreateDocument();
	NewDocum.Company = Company;
	If GetFunctionalOption("MultiCurrency") Then
		NewDocum.DocumentTotal = Amount;
	Else
		NewDocum.DocumentTotal = AmountRC;
	EndIf;
	NewDocum.DocumentTotalRC = AmountRC;
	//NewDocum.Currency = Constants.DefaultCurrency.Get();
	NewDocum.Currency = Company.DefaultCurrency;
	If GetFunctionalOption("MultiCurrency") Then
		NewDocum.ExchangeRate = AmountRC / Amount;
	Else
		NewDocum.ExchangeRate = 1;
	EndIf;
	NewDocum.Date = Constants.BeginningBalancesDate.Get();
	NewDocum.DueDate = DueDate; 
	NewDocum.ARAccount = Company.DefaultCurrency.DefaultARAccount;
	NewDocum.Posted = True;
	NewDocum.DocPosted = True;
	NewDocum.ARBegBal = Ref;
	NewDocum.Write();
	
	Reg = AccountingRegisters.GeneralJournal.CreateRecordSet();
	Reg.Filter.Recorder.Set(NewDocum.Ref);
	Reg.Clear();
	RegLine = Reg.AddDebit();
	//RegLine.Account = Constants.ARAccount.Get();
	RegLine.Account = Company.DefaultCurrency.DefaultARAccount;
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
						  |	SalesInvoice.Ref
						  |FROM
						  |	Document.SalesInvoice AS SalesInvoice
						  |WHERE
						  |	SalesInvoice.ARBegBal = &Ref");
						  
		Query.SetParameter("Ref", Ref);
		
		QueryResult = Query.Execute();

		If QueryResult.IsEmpty() Then	
		Else
			Dataset = QueryResult.Unload();
			Message = New UserMessage();
			SalesInvoice = String(Dataset[0][0]);		
			Message.Text = ("Delete first this Sales Invoice: " + SalesInvoice + " and unpost the beginning balance");
			Message.Message();
			Cancel = True;
			Return;
		EndIf;						  
	
    EndIf;


EndProcedure

