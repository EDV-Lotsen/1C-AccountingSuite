// The procedure performs document posting
//
Procedure Posting(Cancel, PostingMode)
	
	// If Payment create a Vendor Invoice, if Refund create a Sales Invoice
	
	If Type = "1" Then 
		NewDocum = Documents.PurchaseInvoice.CreateDocument();
		NewDocum.Company = Agency;
	Else
		NewDocum = Documents.SalesInvoice.CreateDocument();
		NewDocum.Company = Agency;
	EndIf;
		
	NewDocum.DocumentTotal = AmountRC;
	NewDocum.DocumentTotalRC = AmountRC;
	NewDocum.Currency = Constants.DefaultCurrency.Get();
	NewDocum.ExchangeRate = 1;

	NewDocum.Date = Date;
	NewDocum.DueDate = DueDate; 
	NewDocum.Posted = True;
	NewDocum.DocPosted = True;
	NewDocum.Write();
	
	// GL posting
	
	RegisterRecords.GeneralJournal.Write = True;	
	
	If Type = "1" Then
					
		Record = RegisterRecords.GeneralJournal.AddDebit();
		Record.Account = Constants.VATAccount.Get();
		Record.Period = Date;
		Record.AmountRC = AmountRC;

		Record = RegisterRecords.GeneralJournal.AddCredit();
		Record.Account = Constants.APAccount.Get();
		Record.Period = Date;
		Record.Currency = Constants.DefaultCurrency.Get();
		Record.AmountRC = AmountRC;
		Record.Amount = AmountRC;
		Record.ExtDimensions[ChartsOfCharacteristicTypes.Dimensions.Company] = Agency;
		Record.ExtDimensions[ChartsOfCharacteristicTypes.Dimensions.Document] = NewDocum.Ref;
		
    EndIf;
	
	If Type = "2" Then
		
		Record = RegisterRecords.GeneralJournal.AddCredit();
		Record.Account = Constants.VATAccount.Get();
		Record.Period = Date;
		Record.AmountRC = AmountRC;

		Record = RegisterRecords.GeneralJournal.AddDebit();
		Record.Account = Constants.ARAccount.Get();
		Record.Period = Date;
		Record.Currency = Constants.DefaultCurrency.Get();
		Record.AmountRC = AmountRC;
		Record.Amount = AmountRC;
		Record.ExtDimensions[ChartsOfCharacteristicTypes.Dimensions.Company] = Agency;
		Record.ExtDimensions[ChartsOfCharacteristicTypes.Dimensions.Document] = NewDocum.Ref;
		
		
    EndIf;

EndProcedure

// The procedure prevents voiding if the Allow Voiding functional option is disabled.
//
Procedure UndoPosting(Cancel)
	
	If NOT GetFunctionalOption("AllowVoiding") Then
		Message = New UserMessage();
		Message.Text = NStr("en='You cannot void a posted document'");
		Message.Message();
		Cancel = True;
		Return;
	EndIf;

EndProcedure

// The procedure prevents re-posting if the Allow Voiding functional option is disabled.
//
Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If NOT GetFunctionalOption("AllowVoiding") Then
		
		If WriteMode = DocumentWriteMode.Posting Then
			
			If DocPosted Then
		       Message = New UserMessage();
		       Message.Text = NStr("en='You cannot re-post a posted document'");
		       Message.Message();
		       Cancel = True;
		       Return;
		    Else
		       DocPosted = True;
		   EndIf;
		   
	   EndIf;
	
	EndIf;

EndProcedure

// Clears the DocPosted attribute on document copying
//
Procedure OnCopy(CopiedObject)
	DocPosted = False;
EndProcedure






