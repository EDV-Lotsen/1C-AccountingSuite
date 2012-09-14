// The procedure performs document posting
//
Procedure Posting(Cancel, Mode)
		
	DocDate = BegOfDay(Date) + 60*60*10;
	
	PostingCost = 0;
	PostingCostBeforeAdj = 0;
	PostingCostAfterAdj = 0;

	// create a value table for posting amounts
	
	PostingDatasetIncome = New ValueTable();
	PostingDatasetIncome.Columns.Add("IncomeAccount");
	PostingDatasetIncome.Columns.Add("AmountRC");
	
	PostingDatasetCOGS = New ValueTable();
	PostingDatasetCOGS.Columns.Add("COGSAccount");
	PostingDatasetCOGS.Columns.Add("AmountRC");	
	
	PostingDatasetInvOrExp = New ValueTable();
	PostingDatasetInvOrExp.Columns.Add("InvOrExpAccount");
    PostingDatasetInvOrExp.Columns.Add("AmountRC");		
	
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
		
		AdjustmentCosts = InventoryCosting.PurchaseDocumentsProcessing(CurRowLineItems, InvDatasetProduct, Location, DocDate, ExchangeRate, Ref);
		
		PostingCostBeforeAdj = PostingCostBeforeAdj + AdjustmentCosts[0][0];
		PostingCostAfterAdj = PostingCostAfterAdj + AdjustmentCosts[0][1];
        PostingCost = PostingCost + AdjustmentCosts[0][2];
		
		// fill in the account posting value table with amounts
		
		PostingLineIncome = PostingDatasetIncome.Add();
		If CurRowLineItems.Product.Code = "" Then
			PostingLineIncome.IncomeAccount = Company.IncomeAccount;	
		Else	
			PostingLineIncome.IncomeAccount = CurRowLineItems.Product.IncomeAccount;
		EndIf;
		PostingLineIncome.AmountRC = CurRowLineItems.Price * ExchangeRate * CurRowLineItems.Quantity;
		
		If CurRowLineItems.Product.Type = Enums.InventoryTypes.Inventory Then 
			PostingLineCOGS = PostingDatasetCOGS.Add();
			PostingLineCOGS.COGSAccount = CurRowLineItems.Product.COGSAccount;
			PostingLineCOGS.AmountRC = PostingCost;
			
			PostingLineInvOrExp = PostingDatasetInvOrExp.Add();
			PostingLineInvOrExp.InvOrExpAccount = CurRowLineItems.Product.InventoryOrExpenseAccount;
			PostingLineInvOrExp.AmountRC = PostingCost;
		EndIf;
		
		PostingCost = 0;
		
	EndDo;

	// GL posting
	
	RegisterRecords.GeneralJournal.Write = True;	
		
	Record = RegisterRecords.GeneralJournal.AddCredit();
	Record.Account = ARAccount;
	Record.Period = Date;
	Record.Currency = Currency;
	Record.Amount = DocumentTotal;
	Record.AmountRC = DocumentTotal * ExchangeRate;
	Record.ExtDimensions[ChartsOfCharacteristicTypes.Dimensions.Company] = Company;
	Record.ExtDimensions[ChartsOfCharacteristicTypes.Dimensions.Document] = Ref;

	
	PostingDatasetIncome.GroupBy("IncomeAccount", "AmountRC");
	NoOfPostingRows = PostingDatasetIncome.Count();
	For i = 0 To NoOfPostingRows - 1 Do			
		Record = RegisterRecords.GeneralJournal.AddDebit();
		Record.Account = PostingDatasetIncome[i][0];
		Record.Period = Date;
		Record.AmountRC = PostingDatasetIncome[i][1];				
	EndDo;

	PostingDatasetCOGS.GroupBy("COGSAccount", "AmountRC");
	NoOfPostingRows = PostingDatasetCOGS.Count();
	For i = 0 To NoOfPostingRows - 1 Do			
		Record = RegisterRecords.GeneralJournal.AddCredit();
		Record.Account = PostingDatasetCOGS[i][0];
		Record.Period = Date;
		Record.AmountRC = PostingDatasetCOGS[i][1];				
	EndDo;

	PostingDatasetInvOrExp.GroupBy("InvOrExpAccount", "AmountRC");
	NoOfPostingRows = PostingDatasetInvOrExp.Count();
	For i = 0 To NoOfPostingRows - 1 Do			
		Record = RegisterRecords.GeneralJournal.AddDebit();
		Record.Account = PostingDatasetInvOrExp[i][0];
		Record.Period = Date;
		Record.AmountRC = PostingDatasetInvOrExp[i][1];				
	EndDo;
			
	If SalesTax > 0 Then
		Record = RegisterRecords.GeneralJournal.AddDebit();
		Record.Account = Constants.SalesTaxPayableAccount.Get();
		Record.Period = Date;
		Record.AmountRC = SalesTax * ExchangeRate;
	EndIf;		
	
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



// The procedure prepopulates a sales invoice when created from a sales order, goods issue, or
// sales invoice
//
Procedure Filling(FillingData, StandardProcessing)

	If TypeOf(FillingData) = Type("DocumentRef.SalesOrder") Then
		Company = FillingData.Company;
		DocumentTotal = FillingData.DocumentTotal;
		DocumentTotalRC = FillingData.DocumentTotalRC;
		ParentSalesOrder = FillingData.Ref;
		SalesTax = FillingData.SalesTax;
		Currency = FillingData.Currency;
		ExchangeRate = FillingData.ExchangeRate;
		Location = FillingData.Location;
		VATTotal = FillingData.VATTotal;
		ARAccount = FillingData.Company.DefaultCurrency.DefaultARAccount;
		
		For Each CurRowLineItems In FillingData.LineItems Do
			NewRow = LineItems.Add();
			NewRow.LineTotal = CurRowLineItems.LineTotal;
			NewRow.Price = CurRowLineItems.Price;
			NewRow.Product = CurRowLineItems.Product;
			NewRow.Descr = CurRowLineItems.Descr;
			NewRow.Quantity = CurRowLineItems.Quantity;
			NewRow.QuantityUM = CurRowLineItems.QuantityUM;
			NewRow.UM = CurRowLineItems.UM;
			NewRow.SalesTaxType = CurRowLineItems.SalesTaxType;
			NewRow.TaxableAmount = CurRowLineItems.TaxableAmount;
			NewRow.VAT = CurRowLineItems.VAT;
			NewRow.VATCode = CurRowLineItems.VATCode; 
		EndDo;
		
	EndIf;
	
	If TypeOf(FillingData) = Type("DocumentRef.GoodsIssue") Then
		Company = FillingData.Company;
		DocumentTotal = FillingData.DocumentTotal;
		DocumentTotalRC = FillingData.DocumentTotalRC;
		ParentSalesOrder = FillingData.Ref;
		SalesTax = FillingData.SalesTax;
		Currency = FillingData.Currency;
		ExchangeRate = FillingData.ExchangeRate;
		Location = FillingData.Location;
		VATTotal = FillingData.VATTotal;
		ARAccount = FillingData.ARAccount;
		
		For Each CurRowLineItems In FillingData.LineItems Do
			NewRow = LineItems.Add();
			NewRow.LineTotal = CurRowLineItems.LineTotal;
			NewRow.Price = CurRowLineItems.Price;
			NewRow.Product = CurRowLineItems.Product;
			NewRow.Descr = CurRowLineItems.Descr;
			NewRow.Quantity = CurRowLineItems.Quantity;
			NewRow.QuantityUM = CurRowLineItems.QuantityUM;
			NewRow.UM = CurRowLineItems.UM;
			NewRow.SalesTaxType = CurRowLineItems.SalesTaxType;
			NewRow.TaxableAmount = CurRowLineItems.TaxableAmount;
			NewRow.VAT = CurRowLineItems.VAT;
			NewRow.VATCode = CurRowLineItems.VATCode;	
		EndDo;
		
	EndIf;

	If TypeOf(FillingData) = Type("DocumentRef.SalesInvoice") Then
		Company = FillingData.Company;
		DocumentTotal = FillingData.DocumentTotal;
		DocumentTotalRC = FillingData.DocumentTotalRC;
		ParentSalesOrder = FillingData.Ref;
		SalesTax = FillingData.SalesTax;
		Currency = FillingData.Currency;
		ExchangeRate = FillingData.ExchangeRate;
		ARAccount = FillingData.ARAccount;
		Location = FillingData.Location;
		VATTotal = FillingData.VATTotal;
		ARAccount = FillingData.ARAccount;
		
		For Each CurRowLineItems In FillingData.LineItems Do
			NewRow = LineItems.Add();
			NewRow.LineTotal = CurRowLineItems.LineTotal;
			NewRow.Price = CurRowLineItems.Price;
			NewRow.Product = CurRowLineItems.Product;
			NewRow.Descr = CurRowLineItems.Descr;
			NewRow.Quantity = CurRowLineItems.Quantity;
			NewRow.QuantityUM = CurRowLineItems.QuantityUM;
			NewRow.UM = CurRowLineItems.UM;
			NewRow.SalesTaxType = CurRowLineItems.SalesTaxType;
			NewRow.TaxableAmount = CurRowLineItems.TaxableAmount;
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

