// The procedure performs document posting
//
Procedure Posting(Cancel, Mode)
		
	DocDate = BegOfDay(Date) + 60*60*10;
	
	PostingCostBeforeAdj = 0;
	PostingCostAfterAdj = 0;
		
	If NOT ParentPurchaseOrder.IsEmpty() Then
		RegisterRecords.ReceivedInvoiced.Write = True;
		For Each CurRowLineItems In LineItems Do
			If CurRowLineItems.Product.Type = Enums.InventoryTypes.Inventory Then
				Record = RegisterRecords.ReceivedInvoiced.Add();
				Record.RecordType = AccumulationRecordType.Receipt;
				Record.Period = Date;
				Record.OrderDocument = ParentPurchaseOrder;
				Record.Product = CurRowLineItems.Product;
				If ParentGoodsReceipt.IsEmpty() Then
					Record.Whse = CurRowLineItems.Quantity;
				EndIf;	
				Record.Invoiced = CurRowLineItems.Quantity;
			EndIf;	
		EndDo;
	EndIf;

	
	If ParentGoodsReceipt.IsEmpty() Then		
		
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
		
	EndIf;
		
	If NOT ParentGoodsReceipt.IsEmpty() Then
				
		RegisterRecords.GeneralJournal.Write = True;
		
		PostingDatasetVAT = New ValueTable();
		PostingDatasetVAT.Columns.Add("VATAccount");
		PostingDatasetVAT.Columns.Add("AmountRC");

		PostingVATTotal = 0;
		
		For Each CurRowLineItems in ParentGoodsReceipt.GetObject().LineItems Do		

			If CurRowLineItems.VAT > 0 Then
				
				PostingLineVAT = PostingDatasetVAT.Add();
				PostingLineVAT.VATAccount = VAT_FL.VATAccount(CurRowLineItems.VATCode, "Purchase");
				PostingLineVAT.AmountRC = CurRowLineItems.VAT * ParentGoodsReceipt.GetObject().ExchangeRate;
				
				PostingVATTotal = PostingVATTotal + CurRowLineItems.VAT;
				
			EndIf;
			
		EndDo;

		PostingDatasetVAT.GroupBy("VATAccount", "AmountRC");
		NoOfPostingRows = PostingDatasetVAT.Count();
		For i = 0 To NoOfPostingRows - 1 Do
			Record = RegisterRecords.GeneralJournal.AddDebit();
			Record.Account = PostingDatasetVAT[i][0];
			Record.Period = Date;
			Record.AmountRC = PostingDatasetVAT[i][1];	
		EndDo;	
		
		Record = RegisterRecords.GeneralJournal.AddDebit();
		Record.Account = AccruedPurchasesAccount;
		Record.Period = Date;
		//Record.Amount = DocumentTotal - PostingVATTotal;
		//Record.Currency = Currency;
		Record.AmountRC = (DocumentTotal - PostingVATTotal) * ExchangeRate;
		
		Record = RegisterRecords.GeneralJournal.AddCredit();
		Record.Account = APAccount;
		Record.Period = Date;
		Record.Amount = DocumentTotal;
		Record.Currency = Currency;
		Record.AmountRC = DocumentTotal * ExchangeRate;
	    Record.ExtDimensions[ChartsOfCharacteristicTypes.Dimensions.Company] = Company;
		Record.ExtDimensions[ChartsOfCharacteristicTypes.Dimensions.Document] = Ref;
		
	EndIf;
	
	If ParentGoodsReceipt.IsEmpty() Then
		
		// fill in the account posting value table with amounts
		
		PostingDatasetVAT = New ValueTable();
		PostingDatasetVAT.Columns.Add("VATAccount");
		PostingDatasetVAT.Columns.Add("AmountRC");
		
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
			If PriceIncludesVAT Then
				PostingLine.AmountRC = (CurRowLineItems.LineTotal - CurRowLineItems.VAT) * ExchangeRate;
			Else
				PostingLine.AmountRC = CurRowLineItems.LineTotal * ExchangeRate;
			EndIf;

			//PostingLine.AmountRC = CurRowLineItems.Price * ExchangeRate * CurRowLineItems.Quantity;			
			
			If CurRowLineItems.VAT > 0 Then
				
				PostingLineVAT = PostingDatasetVAT.Add();
				PostingLineVAT.VATAccount = VAT_FL.VATAccount(CurRowLineItems.VATCode, "Purchase");
				PostingLineVAT.AmountRC = CurRowLineItems.VAT * ExchangeRate;
								
			EndIf;
			
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
		Record.Account = APAccount;
		Record.Period = Date;
		Record.Amount = DocumentTotal;
		Record.Currency = Currency;
		Record.AmountRC = DocumentTotal * ExchangeRate;
		Record.ExtDimensions[ChartsOfCharacteristicTypes.Dimensions.Company] = Company;
		Record.ExtDimensions[ChartsOfCharacteristicTypes.Dimensions.Document] = Ref;
		
		PostingDatasetVAT.GroupBy("VATAccount", "AmountRC");
		NoOfPostingRows = PostingDatasetVAT.Count();
		For i = 0 To NoOfPostingRows - 1 Do
			Record = RegisterRecords.GeneralJournal.AddDebit();
			Record.Account = PostingDatasetVAT[i][0];
			Record.Period = Date;
			Record.AmountRC = PostingDatasetVAT[i][1];	
		EndDo;	
		
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
		
	EndIf;
	
EndProcedure

// The procedure prepopulates a purchase invoice when created from a purchase order, or goods receipt.
//
Procedure Filling(FillingData, StandardProcessing)
	
	If TypeOf(FillingData) = Type("DocumentRef.PurchaseOrder") Then
		
		// Check if Goods Receipts exist. If found - cancel.
		Query = New Query("SELECT
		                  |	GoodsReceipt.Ref
		                  |FROM
		                  |	Document.GoodsReceipt AS GoodsReceipt
		                  |WHERE
		                  |	GoodsReceipt.ParentPurchaseOrder = &Ref");
		Query.SetParameter("Ref", FillingData.Ref);
		QueryResult = Query.Execute();
		If NOT QueryResult.IsEmpty() Then
			Message = New UserMessage();
			Message.Text=NStr("en='Goods Receipts are created based on this Purchase Order. Create Vendor Invoices based on Goods Receipts.'");
			Message.Message();
			DontCreate = True;
			Return;
		EndIf;
		
		DocumentTotal = FillingData.DocumentTotal;
		DocumentTotalRC = FillingData.DocumentTotalRC;
		Company = FillingData.Company;
		ParentPurchaseOrder = FillingData.Ref;
		Currency = FillingData.Currency;
		ExchangeRate = FillingData.ExchangeRate;
		Location = FillingData.Location;
		VATTotal = FillingData.VATTotal;
		APAccount = FillingData.Company.DefaultCurrency.DefaultAPAccount;
		PriceIncludesVAT = FillingData.PriceIncludesVAT;
		
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

	If TypeOf(FillingData) = Type("DocumentRef.GoodsReceipt") Then
		DocumentTotal = FillingData.DocumentTotal;
		DocumentTotalRC = FillingData.DocumentTotalRC;
		Company = FillingData.Company;
		ParentPurchaseOrder = FillingData.ParentPurchaseOrder;
		Currency = FillingData.Currency;
		ExchangeRate = FillingData.ExchangeRate;
		Location = FillingData.Location;
		ParentGoodsReceipt = FillingData.Ref;
		VATTotal = FillingData.VATTotal;
		AccruedPurchasesAccount = FillingData.AccruedPurchasesAccount;
		APAccount = FillingData.Currency.DefaultAPAccount;
		PriceIncludesVAT = FillingData.PriceIncludesVAT;
		
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
	
	If InventoryCosting.InventoryPresent(Ref) AND ParentGoodsReceipt.IsEmpty() Then
	
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
		
		If NOT GetFunctionalOption("AllowVoiding") AND ParentGoodsReceipt.IsEmpty() Then
			
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

