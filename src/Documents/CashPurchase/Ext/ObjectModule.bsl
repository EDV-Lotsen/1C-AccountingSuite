// The procedure performs document posting
//
Procedure Posting(Cancel, Mode)
		
	DocDate = BegOfDay(Date) + 60*60*10;
	
	PostingCostBeforeAdj = 0;
	PostingCostAfterAdj = 0;
	
	// create an Inventory Journal dataset
	
	InvDataset = InventoryCosting.PurchaseDocumentsDataset(Ref, DocDate);
	
	// update location balances

	RegisterRecords.LocationBalances.Write = True;
	For Each CurRowLineItems In LineItems Do
		If CurRowLineItems.Product.Type = Enums.InventoryTypes.Inventory Then
			Record = RegisterRecords.LocationBalances.Add();
			Record.RecordType = AccumulationRecordType.Receipt;
			Record.Period = Date;
			Record.Product = CurRowLineItems.Product;
			Record.Location = Location;
			Record.QtyOnHand = CurRowLineItems.Quantity;
		EndIf;	
	EndDo;

	For Each CurRowLineItems In LineItems Do	
				
		// select a subset of the Inventory Journal dataset and call the inventory costing procedure
		
		Filter = New Structure();
		Filter.Insert("Product", CurRowLineItems.Product); 
		InvDataset.Sort("Date, Row");
		InvDatasetProduct = InvDataset.FindRows(Filter);
		
		AdjustmentCosts = InventoryCosting.PurchaseDocumentsProcessing(CurRowLineItems, InvDatasetProduct, Location, DocDate, ExchangeRate, Ref, PriceIncludesVAT);
		
		PostingCostBeforeAdj = PostingCostBeforeAdj + AdjustmentCosts[0][0];
		PostingCostAfterAdj = PostingCostAfterAdj + AdjustmentCosts[0][1];

		
	EndDo;
	
	// fill in the account posting value table with amounts
	
	PostingDataset = New ValueTable();
	PostingDataset.Columns.Add("Account");
	PostingDataset.Columns.Add("AmountRC");	
	For Each CurRowLineItems in LineItems Do		
		PostingLine = PostingDataset.Add();       
		If CurRowLineItems.Product.Code = "" Then
			PostingLine.Account = Company.ExpenseAccount;
		Else
			PostingLine.Account = CurRowLineItems.Product.InventoryOrExpenseAccount;
		EndIf;
		PostingLine.AmountRC = CurRowLineItems.Price * ExchangeRate * CurRowLineItems.Quantity;			
    EndDo;
	
	PostingDataset.GroupBy("Account", "AmountRC");
	
	NoOfPostingRows = PostingDataset.Count();
	
	// GL posting
	
	RegisterRecords.GeneralJournal.Write = True;	
	
	For i = 0 To NoOfPostingRows - 1 Do
		
		Record = RegisterRecords.GeneralJournal.AddDebit();
		Record.Account = PostingDataset[i][0];
		Record.Period = Date;
		Record.AmountRC = PostingDataset[i][1];
			
	EndDo;

	Record = RegisterRecords.GeneralJournal.AddCredit();
	Record.Account = BankAccount;
	Record.Currency = BankAccount.Currency;
	Record.Period = Date;
	If Currency = BankAccount.Currency Then
		Record.Amount = DocumentTotal;
	Else
		Record.Amount = DocumentTotal * ExchangeRate;
	EndIf;
	Record.AmountRC = DocumentTotal * ExchangeRate;
	
	If VATTotal > 0 Then
		Record = RegisterRecords.GeneralJournal.AddDebit();
		Record.Account = Constants.VATAccount.Get();
		Record.Period = Date;
		Record.AmountRC = VATTotal;
	EndIf;

	
	// Actual (adjusted) cost higher
	If (PostingCostAfterAdj - PostingCostBeforeAdj) > 0 Then
		
		Record = RegisterRecords.GeneralJournal.AddDebit();
		Record.Account = Constants.COGSAccount.Get();
		Record.Period = Date;	
		Record.AmountRC = PostingCostAfterAdj - PostingCostBeforeAdj;
		
		Record = RegisterRecords.GeneralJournal.AddCredit();
		Record.Account = Constants.InventoryAccount.Get();
		Record.Period = Date;	
		Record.AmountRC = PostingCostAfterAdj - PostingCostBeforeAdj;
		
	Else
	EndIf;		
	
	// Actual (adjusted) cost lower
	If (PostingCostAfterAdj - PostingCostBeforeAdj) < 0 Then
		
		Record = RegisterRecords.GeneralJournal.AddCredit();
		Record.Account = Constants.COGSAccount.Get(); 
		Record.Period = Date;		
		Record.AmountRC = SQRT(POW((PostingCostAfterAdj - PostingCostBeforeAdj),2));
		
		Record = RegisterRecords.GeneralJournal.AddDebit();
		Record.Account = Constants.InventoryAccount.Get();
		Record.Period = Date;	
		Record.AmountRC = SQRT(POW((PostingCostAfterAdj - PostingCostBeforeAdj),2));
		
	Else
	EndIf;	
	
EndProcedure

// The procedure prevents voiding if the Allow Voiding functional option is disabled.
//
Procedure UndoPosting(Cancel)

	If InventoryCosting.InventoryPresent(Ref) Then
	
		If NOT GetFunctionalOption("AllowVoiding") Then
			
			Message = New UserMessage();
			Message.Text = NStr("en='You cannot void a posted document with inventory items'");
			Message.Message();
			Cancel = True;
			Return;
			
		EndIf;

	EndIf;	
	
EndProcedure

// The procedure prevents re-posting if the Allow Voiding functional option is disabled.
//
Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
		
	If InventoryCosting.InventoryPresent(Ref) Then
		
		If NOT GetFunctionalOption("AllowVoiding") Then
			
			If WriteMode = DocumentWriteMode.Posting Then
				
				If DocPosted Then
			       Message = New UserMessage();
			       Message.Text = NStr("en='You cannot re-post a posted document with inventory items'");
			       Message.Message();
			       Cancel = True;
			       Return;
			    Else
			       DocPosted = True;
			   EndIf;
			   
		   EndIf;
		
		EndIf;
		
	EndIf;	

EndProcedure

// Clears the DocPosted attribute on document copying
//
Procedure OnCopy(CopiedObject)
	DocPosted = False;
EndProcedure