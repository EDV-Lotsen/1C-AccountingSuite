// The procedure calculates inventory cost, updates inventory balances, and posts a transaction
//
Procedure Posting(Cancel, Mode)
	
	// create an Inventory Journal dataset
	
	InvDataset = InventoryCosting.SalesDocumentsDataset(Ref, Location);	
	
	// update location balances
	
	RegisterRecords.LocationBalances.Write = True;
	For Each CurRowLineItems In LineItems Do
		If CurRowLineItems.Product.Type = Enums.InventoryTypes.Inventory Then
			Record = RegisterRecords.LocationBalances.Add();
			Record.RecordType = AccumulationRecordType.Expense;
			Record.Period = Date;
			Record.Product = CurRowLineItems.Product;
			Record.Location = Location;
			Record.QtyOnHand = CurRowLineItems.Quantity;
		EndIf;	
	EndDo;
	
	For Each CurRowLineItems In LineItems Do
				
		If CurRowLineItems.Product.Type = Enums.InventoryTypes.Inventory Then
						
			// check inventory balances and cancel if not sufficient
			
			CurrentBalance = InventoryCosting.LocationBalance(CurRowLineItems.Product, Location);
			
			If CurRowLineItems.Quantity > CurrentBalance Then					
				Message = New UserMessage();
				Message.Text=NStr("en='Insufficient balance'");
				Message.Message();
				Cancel = True;
				Return;
			EndIf;
				
		EndIf;	
		
		// select a subset of the Inventory Journal dataset and call the inventory costing procedure
		
		Filter = New Structure();
		Filter.Insert("Product", CurRowLineItems.Product); 
		InvDataset.Sort("Date, Row");
		InvDatasetProduct = InvDataset.FindRows(Filter);

		PostingCost = InventoryCosting.SalesDocumentProcessing(CurRowLineItems, InvDatasetProduct, Location);
				
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
		
		Record = RegisterRecords.GeneralJournal.AddCredit();
		Record.Account = PostingDataset[i][0];
		Record.Period = Date;
		Record.AmountRC = PostingDataset[i][1];
			
	EndDo;

	If VATTotal > 0 Then
		Record = RegisterRecords.GeneralJournal.AddCredit();
		Record.Account = Constants.VATAccount.Get();
		Record.Period = Date;
		Record.AmountRC = VATTotal;
	EndIf;

	
	Record = RegisterRecords.GeneralJournal.AddDebit();
	Record.Account = APAccount;
	Record.Period = Date;
	Record.Amount = DocumentTotal;
	Record.Currency = Currency;
	Record.AmountRC = DocumentTotal * ExchangeRate;
	Record.ExtDimensions[ChartsOfCharacteristicTypes.Dimensions.Company] = Company;
	Record.ExtDimensions[ChartsOfCharacteristicTypes.Dimensions.Document] = Ref;
	
EndProcedure


// The procedure prepopulates a sales invoice when created from a goods receipt,
// vendor invoice, or purchase order.
//
Procedure Filling(FillingData, StandardProcessing)

	If TypeOf(FillingData) = Type("DocumentRef.GoodsReceipt") Then
		Company = FillingData.Company;
		DocumentTotal = FillingData.DocumentTotal;
		DocumentTotalRC = FillingData.DocumentTotalRC;
		ParentPurchaseOrder = FillingData.Ref;
		Currency = FillingData.Currency;
		ExchangeRate = FillingData.ExchangeRate;
		Location = FillingData.Location;
		VATTotal = FillingData.VATTotal;
		APAccount = FillingData.APAccount;
		
		For Each CurRowLineItems In FillingData.LineItems Do
			NewRow = LineItems.Add();
			NewRow.LineTotal = CurRowLineItems.LineTotal;
			NewRow.Price = CurRowLineItems.Price;
			NewRow.Product = CurRowLineItems.Product;
			NewRow.Descr = CurRowLineItems.Descr;
			NewRow.Quantity = CurRowLineItems.Quantity;
			NewRow.QuantityUM = CurRowLineItems.QuantityUM;
			NewRow.UM = CurRowLineItems.UM;
			NewRow.VAT = CurRowLineItems.VAT;
			NewRow.VATCode = CurRowLineItems.VATCode;
		EndDo;
		
	EndIf;
	
	If TypeOf(FillingData) = Type("DocumentRef.PurchaseInvoice") Then
		Company = FillingData.Company;
		DocumentTotal = FillingData.DocumentTotal;
		DocumentTotalRC = FillingData.DocumentTotalRC;
		ParentPurchaseOrder = FillingData.Ref;
		Currency = FillingData.Currency;
		ExchangeRate = FillingData.ExchangeRate;
		Location = FillingData.Location;
		VATTotal = FillingData.VATTotal;
		APAccount = FillingData.APAccount;
		
		For Each CurRowLineItems In FillingData.LineItems Do
			NewRow = LineItems.Add();
			NewRow.LineTotal = CurRowLineItems.LineTotal;
			NewRow.Price = CurRowLineItems.Price;
			NewRow.Product = CurRowLineItems.Product;
			NewRow.Descr = CurRowLineItems.Descr;
			NewRow.Quantity = CurRowLineItems.Quantity;
			NewRow.QuantityUM = CurRowLineItems.QuantityUM;
			NewRow.UM = CurRowLineItems.UM;
			NewRow.VAT = CurRowLineItems.VAT;
			NewRow.VATCode = CurRowLineItems.VATCode;	
		EndDo;
		
	EndIf;
	
	If TypeOf(FillingData) = Type("DocumentRef.PurchaseOrder") Then
		Company = FillingData.Company;
		DocumentTotal = FillingData.DocumentTotal;
		DocumentTotalRC = FillingData.DocumentTotalRC;
		ParentPurchaseOrder = FillingData.Ref;
		Currency = FillingData.Currency;
		ExchangeRate = FillingData.ExchangeRate;
		Location = FillingData.Location;
		VATTotal = FillingData.VATTotal;
		APAccount = FillingData.Company.DefaultCurrency.DefaultAPAccount;
		
		For Each CurRowLineItems In FillingData.LineItems Do
			NewRow = LineItems.Add();
			NewRow.LineTotal = CurRowLineItems.LineTotal;
			NewRow.Price = CurRowLineItems.Price;
			NewRow.Product = CurRowLineItems.Product;
			NewRow.Descr = CurRowLineItems.Descr;
			NewRow.Quantity = CurRowLineItems.Quantity;
			NewRow.QuantityUM = CurRowLineItems.QuantityUM;
			NewRow.UM = CurRowLineItems.UM;
			NewRow.VAT = CurRowLineItems.VAT;
			NewRow.VATCode = CurRowLineItems.VATCode;	
		EndDo;
		
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

