
////////////////////////////////////////////////////////////////////////////////
// Sales return: Object module
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
			Documents.SalesReturn.PrepareDataBeforeWrite(AdditionalProperties, DocumentParameters, Cancel);
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
		// Generate on the base of sales invoice document.
		If (TypeOf(FillingData) = Type("DocumentRef.SalesInvoice")) Then
			
			// -> CODE REVIEW
			ParentDocument = FillingData.Ref;
			Company = FillingData.Company;
			DocumentTotal = FillingData.DocumentTotal;
			DocumentTotalRC = FillingData.DocumentTotalRC;
			SalesTaxRC = FillingData.SalesTaxRC;
			Currency = FillingData.Currency;
			ExchangeRate = FillingData.ExchangeRate;
			ARAccount = FillingData.ARAccount;
			Location = FillingData.LocationActual;
			ARAccount = FillingData.ARAccount;
			LineSubtotalRC = FillingData.LineSubtotal;
			SalesTaxRate = FillingData.SalesTaxRate;
			
			For Each CurRowLineItems In FillingData.LineItems Do
				NewRow = LineItems.Add();
				NewRow.LineTotal = CurRowLineItems.LineTotal;
				NewRow.Price = CurRowLineItems.Price;
				NewRow.Product = CurRowLineItems.Product;
				NewRow.ProductDescription = CurRowLineItems.ProductDescription;
				NewRow.Quantity = CurRowLineItems.Quantity;
				NewRow.Taxable = CurRowLineItems.Taxable;
			EndDo;
			
			For Each SalesTaxAA In FillingData.SalesTaxAcrossAgencies Do
				NewSTAA = SalesTaxAcrossAgencies.Add();
				FillPropertyValues(NewSTAA, SalesTaxAA);
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
	
	RegisterRecords.CashFlowData.Write = True;
	
	// 1. Common postings clearing / reactivate manual ajusted postings.
	DocumentPosting.PrepareRecordSetsForPosting(AdditionalProperties, RegisterRecords);
	
	// 2. Skip manually adjusted documents.
	If ManualAdjustment Then
		Return;
	EndIf;
	
	// 3. Create structures with document data to pass it on the server.
	DocumentPosting.PrepareDataStructuresBeforePosting(AdditionalProperties);
	
	// 4. Collect document data, available for posing, and fill created structure.
	Documents.SalesReturn.PrepareDataStructuresForPosting(Ref, AdditionalProperties, RegisterRecords);
	
	// 5. Fill register records with document's postings.
	DocumentPosting.FillRecordSets(AdditionalProperties, RegisterRecords, Cancel);
	
	// 6. Write document postings to register.
	DocumentPosting.WriteRecordSets(AdditionalProperties, RegisterRecords);
	
	// 7. Check register blanaces according to document's changes.
	DocumentPosting.CheckPostingResults(AdditionalProperties, RegisterRecords, Cancel);
	
	// 8. Clear used temporary document data.
	DocumentPosting.ClearDataStructuresAfterPosting(AdditionalProperties);
	
	
	// -> CODE REVIEW
		
	// Create a value table for posting amounts.
	PostingDatasetIncome = New ValueTable();
	PostingDatasetIncome.Columns.Add("IncomeAccount");
	PostingDatasetIncome.Columns.Add("AmountRC");
	
	PostingDatasetCOGS = New ValueTable();
	PostingDatasetCOGS.Columns.Add("COGSAccount");
	PostingDatasetCOGS.Columns.Add("AmountRC");
	
	PostingDatasetInvOrExp = New ValueTable();
	PostingDatasetInvOrExp.Columns.Add("InvOrExpAccount");
	PostingDatasetInvOrExp.Columns.Add("AmountRC");
	
	For Each CurRowLineItems In LineItems Do
		
		If Ref.ReturnType = Enums.ReturnTypes.Refund Then
			RegisterRecords.CashFlowData.Write = True;
			Record = RegisterRecords.CashFlowData.Add();
			Record.RecordType = AccumulationRecordType.Expense;
			Record.Period = Date;
			Record.Company = Company;
			Record.Document = Ref;
			Record.Account = CurRowLineItems.Product.IncomeAccount;
			//Record.Account = CurRowLineItems.Product.InventoryOrExpenseAccount;
			//Record.CashFlowSection = CurRowLineItems.Product.InventoryOrExpenseAccount.CashFlowSection;
			Record.AmountRC = CurRowLineItems.LineTotal * ExchangeRate * -1;
			//Record.PaymentMethod = PaymentMethod;
		EndIf;
		
		If CurRowLineItems.Product.Type = Enums.InventoryTypes.Inventory Then
			
			// Inventory journal update and costing procedure.
			
			LastCost = 0;
			
			If CurRowLineItems.Product.CostingMethod = Enums.InventoryCosting.WeightedAverage Then
				
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
					LastCost = QueryResult[0].AmountBalance / QueryResult[0].QuantityBalance;
				EndIf;
			EndIf;
			
			If CurRowLineItems.Product.CostingMethod = Enums.InventoryCosting.FIFO Then
				
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
				Selection = Query.Execute().Unload();
				
				Try
					LastCost = Selection[0].AmountBalance / Selection[0].QuantityBalance; 
				Except
				EndTry;
				
			EndIf;
			
			// Adding to posting datasets.
			PostingLineCOGS = PostingDatasetCOGS.Add();
			PostingLineCOGS.COGSAccount = CurRowLineItems.Product.COGSAccount;
			PostingLineCOGS.AmountRC = CurRowLineItems.Quantity * LastCost;
			
			PostingLineInvOrExp = PostingDatasetInvOrExp.Add();
			PostingLineInvOrExp.InvOrExpAccount = CurRowLineItems.Product.InventoryOrExpenseAccount;
			PostingLineInvOrExp.AmountRC = CurRowLineItems.Quantity * LastCost;
			
		EndIf;
		
		PostingLineIncome = PostingDatasetIncome.Add();
		PostingLineIncome.IncomeAccount = CurRowLineItems.Product.IncomeAccount;
		PostingLineIncome.AmountRC = CurRowLineItems.LineTotal * ExchangeRate;
		
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
	
	Record = RegisterRecords.GeneralJournal.AddDebit();
	Record.Account = Constants.TaxPayableAccount.Get();
	Record.Period = Date;
	Record.AmountRC = SalesTaxRC * ExchangeRate;
	
	If Discount <> 0 Then
		Record = RegisterRecords.GeneralJournal.AddCredit();
		DiscountsAccount = Constants.DiscountsAccount.Get();
		If DiscountsAccount = ChartsOfAccounts.ChartOfAccounts.EmptyRef() Then
			Record.Account = Constants.ExpenseAccount.Get();
		Else
			Record.Account = DiscountsAccount;
		EndIf;
		Record.Period = Date;
		Record.AmountRC = Discount * -1 * ExchangeRate;
		
		If Ref.ReturnType = Enums.ReturnTypes.Refund Then
			RegisterRecords.CashFlowData.Write = True;
			Record = RegisterRecords.CashFlowData.Add();
			Record.RecordType = AccumulationRecordType.Expense;
			Record.Period = Date;
			Record.Company = Company;
			Record.Document = Ref;
			If DiscountsAccount = ChartsOfAccounts.ChartOfAccounts.EmptyRef() Then
				Record.Account = Constants.ExpenseAccount.Get();
			Else
				Record.Account = DiscountsAccount;
			EndIf;
			Record.AmountRC = (Discount * -1 * ExchangeRate);
		EndIf;
	EndIf;
		
	If Shipping <> 0 Then
		Record = RegisterRecords.GeneralJournal.AddDebit();
		ShippingExpenseAccount = Constants.ShippingExpenseAccount.Get();
		If ShippingExpenseAccount = ChartsOfAccounts.ChartOfAccounts.EmptyRef() Then
			Record.Account = Constants.IncomeAccount.Get();
		Else
			Record.Account = ShippingExpenseAccount;
		EndIf;
		Record.Period = Date;
		Record.AmountRC = Shipping * ExchangeRate;
		
		If Ref.ReturnType = Enums.ReturnTypes.Refund Then
			RegisterRecords.CashFlowData.Write = True;
			Record = RegisterRecords.CashFlowData.Add();
			Record.RecordType = AccumulationRecordType.Expense;
			Record.Period = Date;
			Record.Company = Company;
			Record.Document = Ref;
			ShippingExpenseAccount = Constants.ShippingExpenseAccount.Get();
			If ShippingExpenseAccount = ChartsOfAccounts.ChartOfAccounts.EmptyRef() Then
				Record.Account = Constants.IncomeAccount.Get();
			Else
				Record.Account = ShippingExpenseAccount;
			EndIf;
			Record.AmountRC = Shipping * ExchangeRate * -1;
		EndIf;

	EndIf;
	
	// <- CODE REVIEW
	
EndProcedure

Procedure UndoPosting(Cancel)	
	
	// 1. Common posting clearing / deactivate manual ajusted postings
	DocumentPosting.PrepareRecordSetsForPostingClearing(AdditionalProperties, RegisterRecords);
	
	// 2. Skip manually adjusted documents
	If ManualAdjustment Then
		Return;
	EndIf;
	
	// 3. Create structures with document data to pass it on the server
	DocumentPosting.PrepareDataStructuresBeforePosting(AdditionalProperties);
	
	// 4. Collect document data, required for posing clearing, and fill created structure 
	Documents.SalesReturn.PrepareDataStructuresForPostingClearing(Ref, AdditionalProperties, RegisterRecords);
	
	// 5. Write document postings to register
	DocumentPosting.WriteRecordSets(AdditionalProperties, RegisterRecords);
	
	// 6. Check register blanaces according to document's changes
	DocumentPosting.CheckPostingResults(AdditionalProperties, RegisterRecords, Cancel);
	
	// 7. Clear used temporary document data
	DocumentPosting.ClearDataStructuresAfterPosting(AdditionalProperties);
	
	
EndProcedure

#EndIf

#EndRegion
