
////////////////////////////////////////////////////////////////////////////////
// Purchase return: Object module
//------------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
#Region EVENT_HANDLERS

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	// Document date adjustment patch (tunes the date of drafts like for the new documents).
	If  WriteMode = DocumentWriteMode.Posting And Not Posted // Posting of new or draft (saved but unposted) document.
	And BegOfDay(Date) = BegOfDay(CurrentSessionDate()) Then // Operational posting (by the current date).
		// Shift document time to the time of posting.
		Date = CurrentSessionDate();
	EndIf;
	
	// Save document parameters before posting the document.
	If WriteMode = DocumentWriteMode.Posting
	Or WriteMode = DocumentWriteMode.UndoPosting Then
		
		// Common filling of parameters.
		DocumentParameters = New Structure("Ref, Date, IsNew,   Posted, ManualAdjustment, Metadata",
		                                    Ref, Date, IsNew(), Posted, ManualAdjustment, Metadata());
		DocumentPosting.PrepareDataStructuresBeforeWrite(AdditionalProperties, DocumentParameters, Cancel, WriteMode, PostingMode);
	EndIf;
	
	// Precheck of register balances to complete filling of document posting.
	If WriteMode = DocumentWriteMode.Posting Then
		
		// Precheck of document data, calculation of temporary data, required for document posting.
		If (Not ManualAdjustment) Then
			DocumentParameters = New Structure("Ref, PointInTime,   Company, Location, LineItems",
			                                    Ref, PointInTime(), Company, Location, LineItems.Unload(, "Product, Quantity"));
			Documents.PurchaseReturn.PrepareDataBeforeWrite(AdditionalProperties, DocumentParameters, Cancel);
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	// Forced assign the new document number.
	If ThisObject.IsNew() Then ThisObject.SetNewNumber(); EndIf;
	
	// Filling new document or filling on the base of another document.
	If FillingData = Undefined Then
		// Filling of the new created document with default values.
		Currency         = Constants.DefaultCurrency.Get();
		ExchangeRate     = GeneralFunctions.GetExchangeRate(Date, Currency);
		Location         = Catalogs.Locations.MainWarehouse;
		
	Else
		// Generate on the base of purchase invoice document.
		If (TypeOf(FillingData) = Type("DocumentRef.PurchaseInvoice")) Then
			
			// -> CODE REVIEW
			ParentDocument  = FillingData.Ref;
			Company         = FillingData.Company;
			Currency        = FillingData.Currency;
			ExchangeRate    = FillingData.ExchangeRate;
			Location        = FillingData.LocationActual;
			APAccount       = FillingData.APAccount;
			DocumentTotal   = FillingData.DocumentTotal;
			DocumentTotalRC = FillingData.DocumentTotalRC;
			
			For Each CurRowLineItems In FillingData.LineItems Do
				NewRow = LineItems.Add();
				NewRow.Product   = CurRowLineItems.Product;
				NewRow.ProductDescription = CurRowLineItems.ProductDescription;
				NewRow.Quantity  = CurRowLineItems.Quantity;
				NewRow.Price     = CurRowLineItems.Price;
				NewRow.LineTotal = CurRowLineItems.LineTotal;
			EndDo;
			// <- CODE REVIEW
			
		EndIf;
	EndIf;
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	// Clear manual adjustment attribute.
	ManualAdjustment = False;
	
EndProcedure

Procedure Posting(Cancel, Mode)
	
	// 1. Common postings clearing / reactivate manual ajusted postings.
	DocumentPosting.PrepareRecordSetsForPosting(AdditionalProperties, RegisterRecords);
	
	// 2. Skip manually adjusted documents.
	If ManualAdjustment Then
		Return;
	EndIf;
	
	// 3. Create structures with document data to pass it on the server.
	DocumentPosting.PrepareDataStructuresBeforePosting(AdditionalProperties);
	
	// 4. Collect document data, available for posing, and fill created structure.
	Documents.PurchaseReturn.PrepareDataStructuresForPosting(Ref, AdditionalProperties, RegisterRecords);
	
	// 5. Fill register records with document's postings.
	DocumentPosting.FillRecordSets(AdditionalProperties, RegisterRecords, Cancel);
	
	// 6. Write document postings to register.
	DocumentPosting.WriteRecordSets(AdditionalProperties, RegisterRecords);
	
	// 7. Check register blanaces according to document's changes.
	DocumentPosting.CheckPostingResults(AdditionalProperties, RegisterRecords, Cancel);
	
	// 8. Clear used temporary document data.
	DocumentPosting.ClearDataStructuresAfterPosting(AdditionalProperties);
	
	
	// -> CODE REVIEW	
	
	PostingDatasetInvOrExp = New ValueTable();
	PostingDatasetInvOrExp.Columns.Add("InvOrExpAccount");
	PostingDatasetInvOrExp.Columns.Add("AmountRC");
	
	RegisterRecords.CashFlowData.Write = True;

	
	For Each CurRowLineItems In LineItems Do
		
		Record = RegisterRecords.CashFlowData.Add();
		Record.RecordType = AccumulationRecordType.Receipt;
		Record.Period = Date;
		Record.Company = Company;
		Record.Document = Ref;
		If CurRowLineItems.Product.Type = Enums.InventoryTypes.Inventory Then
			Record.Account = CurRowLineItems.Product.COGSAccount;
		Else
			Record.Account = CurRowLineItems.Product.InventoryOrExpenseAccount;
		EndIf;
		//Record.Account = CurRowLineItems.Product.InventoryOrExpenseAccount;
		//Record.CashFlowSection = CurRowLineItems.Product.InventoryOrExpenseAccount.CashFlowSection;
		Record.AmountRC = CurRowLineItems.LineTotal * ExchangeRate * -1;
		//Record.PaymentMethod = PaymentMethod;

		
		If CurRowLineItems.Product.Type = Enums.InventoryTypes.Inventory Then
			
			// Inventory journal update and costing procedure.
			
			ItemCost = 0;
			
			If CurRowLineItems.Product.CostingMethod = Enums.InventoryCosting.WeightedAverage Then
				
				AverageCost = 0;
				
				Query = New Query("SELECT
				                  |	InventoryJournalBalance.QuantityBalance AS QuantityBalance,
				                  |	InventoryJournalBalance.AmountBalance   AS AmountBalance
				                  |FROM
				                  |	AccumulationRegister.InventoryJournal.Balance(, Product = &Product) AS InventoryJournalBalance");
				Query.SetParameter("Product", CurRowLineItems.Product);
				QueryResult = Query.Execute().Unload();
				If  QueryResult.Count() > 0
				And (Not QueryResult[0].QuantityBalance = Null)
				And (Not QueryResult[0].AmountBalance = Null)
				And QueryResult[0].QuantityBalance > 0
				Then
					AverageCost = QueryResult[0].AmountBalance / QueryResult[0].QuantityBalance;
				EndIf;
				
				ItemCost = CurRowLineItems.Quantity * AverageCost;
				
			EndIf;
			
			If CurRowLineItems.Product.CostingMethod = Enums.InventoryCosting.FIFO Then
				
				ItemQuantity = CurRowLineItems.Quantity;
				
				Query = New Query("SELECT
				                  |	InventoryJournalBalance.QuantityBalance,
				                  |	InventoryJournalBalance.AmountBalance,
				                  |	InventoryJournalBalance.Layer,
				                  |	InventoryJournalBalance.Layer.Date AS LayerDate
				                  |FROM
				                  |	AccumulationRegister.InventoryJournal.Balance(, Product = &Product AND Location = &Location) AS InventoryJournalBalance
				                  |ORDER BY
				                  |	LayerDate ASC");
				Query.SetParameter("Product", CurRowLineItems.Product);
				Query.SetParameter("Location", Location);
				Selection = Query.Execute().Select();
				
				While Selection.Next() Do
					If ItemQuantity > 0 Then
						If ItemQuantity >= Selection.QuantityBalance Then
							ItemCost = ItemCost + Selection.AmountBalance;
							ItemQuantity = ItemQuantity - Selection.QuantityBalance;
						Else
							ItemCost = ItemCost + ItemQuantity * (Selection.AmountBalance / Selection.QuantityBalance);
							ItemQuantity = 0;
						EndIf;
					EndIf;
				EndDo;
				
			EndIf;
			
			// Adding to the posting dataset.
			PostingLineInvOrExp = PostingDatasetInvOrExp.Add();
			PostingLineInvOrExp.InvOrExpAccount = CurRowLineItems.Product.InventoryOrExpenseAccount;
			PostingLineInvOrExp.AmountRC = ItemCost;
			
		EndIf;
	EndDo;
	
	// Fill in the account posting value table with amounts.
	
	PostingDataset = New ValueTable();
	PostingDataset.Columns.Add("Account");
	PostingDataset.Columns.Add("AmountRC");
	
	For Each CurRowLineItems in LineItems Do
		
		If CurRowLineItems.Product.Type = Enums.InventoryTypes.NonInventory Then
			
			PostingLine = PostingDataset.Add();
			PostingLine.Account = CurRowLineItems.Product.InventoryOrExpenseAccount;
			LineAmount = CurRowLineItems.LineTotal * ExchangeRate; 
			PostingLine.AmountRC = LineAmount;
			
		EndIf;
		
	EndDo;
	
	// GL posting
	
	RegisterRecords.GeneralJournal.Write = True;
	
	TotalCredit = 0; 
	
	PostingDatasetInvOrExp.GroupBy("InvOrExpAccount", "AmountRC");
	NoOfPostingRows = PostingDatasetInvOrExp.Count();
	For i = 0 To NoOfPostingRows - 1 Do
		Record = RegisterRecords.GeneralJournal.AddCredit();
		Record.Account = PostingDatasetInvOrExp[i][0];
		Record.Period = Date;
		Record.AmountRC = PostingDatasetInvOrExp[i][1];
		TotalCredit = TotalCredit + PostingDatasetInvOrExp[i][1];
	EndDo;
	
	PostingDataset.GroupBy("Account", "AmountRC");
	NoOfPostingRows = PostingDataset.Count();
	For i = 0 To NoOfPostingRows - 1 Do
		Record = RegisterRecords.GeneralJournal.AddCredit();
		Record.Account = PostingDataset[i][0];
		Record.Period = Date;
		Record.AmountRC = PostingDataset[i][1];
		TotalCredit = TotalCredit + PostingDataset[i][1];
	EndDo;
	
	Record = RegisterRecords.GeneralJournal.AddDebit();
	Record.Account = APAccount;
	Record.Period = Date;
	Record.Amount = DocumentTotal;
	Record.Currency = Currency;
	Record.AmountRC = DocumentTotal * ExchangeRate;
	Record.ExtDimensions[ChartsOfCharacteristicTypes.Dimensions.Company] = Company;
	Record.ExtDimensions[ChartsOfCharacteristicTypes.Dimensions.Document] = Ref;
	
	VarianceAmount = 0;
	VarianceAmount = DocumentTotal * ExchangeRate - TotalCredit;
	
	If VarianceAmount > 0 Then
		Record = RegisterRecords.GeneralJournal.AddCredit();
		Record.Account = Constants.ExpenseAccount.Get();
		Record.Period = Date;
		Record.AmountRC = VarianceAmount;
		Record.Memo = "Purchase Return variance";
	ElsIf VarianceAmount < 0 Then
		Record = RegisterRecords.GeneralJournal.AddDebit();
		Record.Account = Constants.ExpenseAccount.Get();
		Record.Period = Date;
		Record.AmountRC = VarianceAmount;
		Record.Memo = "Purchase Return variance";
	EndIf;
	
	// <- CODE REVIEW
	
EndProcedure

Procedure UndoPosting(Cancel)	
	
	// 1. Common posting clearing / deactivate manual ajusted postings.
	DocumentPosting.PrepareRecordSetsForPostingClearing(AdditionalProperties, RegisterRecords);
	
	// 2. Skip manually adjusted documents.
	If ManualAdjustment Then
		Return;
	EndIf;
	
	// 3. Create structures with document data to pass it on the server.
	DocumentPosting.PrepareDataStructuresBeforePosting(AdditionalProperties);
	
	// 4. Collect document data, required for posing clearing, and fill created structure.
	Documents.PurchaseReturn.PrepareDataStructuresForPostingClearing(Ref, AdditionalProperties, RegisterRecords);
	
	// 5. Write document postings to register.
	DocumentPosting.WriteRecordSets(AdditionalProperties, RegisterRecords);
	
	// 6. Check register blanaces according to document's changes.
	DocumentPosting.CheckPostingResults(AdditionalProperties, RegisterRecords, Cancel);
	
	// 7. Clear used temporary document data.
	DocumentPosting.ClearDataStructuresAfterPosting(AdditionalProperties);
	
EndProcedure

#EndIf

#EndRegion
