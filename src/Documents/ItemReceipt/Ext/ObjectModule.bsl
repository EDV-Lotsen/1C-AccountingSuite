
////////////////////////////////////////////////////////////////////////////////
// Item Receipt: Object module
//------------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
#Region EVENT_HANDLERS

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	// Save document parameters before posting the document
	If WriteMode = DocumentWriteMode.Posting
	Or WriteMode = DocumentWriteMode.UndoPosting Then
		
		// Common filling of parameters
		DocumentParameters = New Structure("Ref, Date, IsNew,   Posted, ManualAdjustment, Metadata",
		                                    Ref, Date, IsNew(), Posted, ManualAdjustment, Metadata());
		DocumentPosting.PrepareDataStructuresBeforeWrite(AdditionalProperties, DocumentParameters, Cancel, WriteMode, PostingMode);
		
	EndIf;
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	// 1. Common postings clearing / reactivate manual ajusted postings
	DocumentPosting.PrepareRecordSetsForPosting(AdditionalProperties, RegisterRecords);
	
	// 2. Skip manually adjusted documents
	If ManualAdjustment Then
		Return;
	EndIf;
	
	// 3. Create structures with document data to pass it on the server
	DocumentPosting.PrepareDataStructuresBeforePosting(AdditionalProperties);
	
	// 4. Collect document data, available for posing, and fill created structure 
	Documents.ItemReceipt.PrepareDataStructuresForPosting(Ref, AdditionalProperties, RegisterRecords);
	
	// 5. Fill register records with document's postings
	DocumentPosting.FillRecordSets(AdditionalProperties, RegisterRecords, Cancel);
	
	// 6. Write document postings to register
	DocumentPosting.WriteRecordSets(AdditionalProperties, RegisterRecords);
	
	// 7. Check register blanaces according to document's changes
	DocumentPosting.CheckPostingResults(AdditionalProperties, RegisterRecords, Cancel);
	
	// 8. Clear used temporary document data
	DocumentPosting.ClearDataStructuresAfterPosting(AdditionalProperties);
	
	
	// OLD Posting
	
	RegisterInventory = True;
	
	If RegisterInventory Then
		
		RegisterRecords.InventoryJrnl.Write = True;
		
		For Each CurRowLineItems In LineItems Do
			If CurRowLineItems.Product.Type = Enums.InventoryTypes.Inventory Then
				Record = RegisterRecords.InventoryJrnl.Add();
				Record.RecordType = AccumulationRecordType.Receipt;
				Record.Period = Date;
				Record.Product = CurRowLineItems.Product;
				Record.Location = Location;
				If CurRowLineItems.Product.CostingMethod = Enums.InventoryCosting.WeightedAverage Then
				Else
					Record.Layer = Ref;
				EndIf;
				Record.Qty = CurRowLineItems.Quantity;
				ItemAmount = 0;
				ItemAmount = CurRowLineItems.Quantity * CurRowLineItems.Price * ExchangeRate; 
				Record.Amount = ItemAmount;
				
				// Updating the ItemLastCost register
				Reg = InformationRegisters.ItemLastCost.CreateRecordManager();
				Reg.Product = CurRowLineItems.Product;
				Reg.Cost = CurRowLineItems.Price * ExchangeRate;
				Reg.Write(True);
			EndIf;
		EndDo;
		
	EndIf;
	
	// fill in the account posting value table with amounts
	
	//PostingDatasetVAT = New ValueTable();
	//PostingDatasetVAT.Columns.Add("VATAccount");
	//PostingDatasetVAT.Columns.Add("AmountRC");
	
	PostingDataset = New ValueTable();
	PostingDataset.Columns.Add("Account");
	PostingDataset.Columns.Add("AmountRC");	
	
	CalculateByPlannedCosting = False;
	PurchaseLiabilityAccount  = Constants.PurchaseLiabilityAccount.Get();
	CostVarianceAccount       = Constants.CostVarianceAccount.Get();
	
	For Each CurRowLineItems in LineItems Do
		// Detect inventory item in table part
		IsInventoryPosting = (Not CurRowLineItems.Product.IsEmpty()) And (CurRowLineItems.Product.Type = Enums.InventoryTypes.Inventory);
		
		PostingLine = PostingDataset.Add();
		If CalculateByPlannedCosting And IsInventoryPosting Then
			//PostingLine.Account = AccruedPurchasesAccount;
		Else
			PostingLine.Account = CurRowLineItems.Product.InventoryOrExpenseAccount;
		EndIf;	
		//If PriceIncludesVAT Then
		//	PostingLine.AmountRC = (CurRowLineItems.LineTotal - CurRowLineItems.VAT) * ExchangeRate;
		//Else
			PostingLine.AmountRC = CurRowLineItems.LineTotal * ExchangeRate;
		//EndIf;
		
		// Calculating diference between ordered cost and invoiced cost of inventory items
		//If CalculateByPlannedCosting And IsInventoryPosting Then
		//	// Calculate difference in ordered and invoiced sum
		//	OrderCostDiff = CurRowLineItems.Quantity * (CurRowLineItems.OrderPrice - CurRowLineItems.Price);
		//	// Book found difference
		//	If OrderCostDiff <> 0 Then
		//		// Increase/Decrease booked value by ordering cost
		//		PostingLine.AmountRC = PostingLine.AmountRC + OrderCostDiff;
		//		// Found difference will be booked to the Purchased Variance account
		//		PostingLine = PostingDataset.Add();       
		//		PostingLine.Account = PurchaseVarianceAccount;
		//		PostingLine.AmountRC = - OrderCostDiff;
		//	EndIf;
		//EndIf;
		
		//If CurRowLineItems.VAT > 0 Then
		//	PostingLineVAT = PostingDatasetVAT.Add();
		//	PostingLineVAT.VATAccount = VAT_FL.VATAccount(CurRowLineItems.VATCode, "Purchase");
		//	PostingLineVAT.AmountRC = CurRowLineItems.VAT * ExchangeRate;
		//EndIf;
		
	EndDo;
	
	PostingDataset.GroupBy("Account", "AmountRC");
	
	NoOfPostingRows = PostingDataset.Count();
	
	// GL posting
	
	RegisterRecords.GeneralJournal.Write = True;	
	
	For i = 0 To NoOfPostingRows - 1 Do
		
		If PostingDataset[i][1] > 0 Then // Dr: Amount > 0
			Record = RegisterRecords.GeneralJournal.AddDebit();
			Record.Account = PostingDataset[i][0];
			Record.Period = Date;
			Record.AmountRC = PostingDataset[i][1];
			
		ElsIf PostingDataset[i][1] < 0 Then // Cr: Amount < 0
			Record = RegisterRecords.GeneralJournal.AddCredit();
			Record.Account = PostingDataset[i][0];
			Record.Period = Date;
			Record.AmountRC = -PostingDataset[i][1];
			
		EndIf;	
	EndDo;
	
	Record = RegisterRecords.GeneralJournal.AddCredit();
	Record.Account = PurchaseLiabilityAccount;
	Record.Period = Date;
	Record.Amount = DocumentTotal;
	Record.Currency = Currency;
	Record.AmountRC = DocumentTotal * ExchangeRate;
	
	//PostingDatasetVAT.GroupBy("VATAccount", "AmountRC");
	//NoOfPostingRows = PostingDatasetVAT.Count();
	//For i = 0 To NoOfPostingRows - 1 Do
	//	Record = RegisterRecords.GeneralJournal.AddDebit();
	//	Record.Account = PostingDatasetVAT[i][0];
	//	Record.Period = Date;
	//	Record.AmountRC = PostingDatasetVAT[i][1];	
	//EndDo;	
	
	
	RegisterRecords.ProjectData.Write = True;
	For Each CurRowLineItems In LineItems Do
		Record = RegisterRecords.ProjectData.Add();
		Record.RecordType = AccumulationRecordType.Expense;
		Record.Period = Date;
		Record.Project = CurRowLineItems.Project;
		Record.Amount = CurRowLineItems.LineTotal;		
	EndDo;
	
EndProcedure

Procedure UndoPosting(Cancel)

	// OLD Undo Posting
	
	Query = New Query("SELECT
	                  |	ItemReceiptLineItems.Product,
	                  |	SUM(ItemReceiptLineItems.Quantity) AS Quantity
	                  |FROM
	                  |	Document.ItemReceipt.LineItems AS ItemReceiptLineItems
	                  |WHERE
	                  |	ItemReceiptLineItems.Ref = &Ref
	                  |	AND ItemReceiptLineItems.Product.Type = VALUE(Enum.InventoryTypes.Inventory)
	                  |
	                  |GROUP BY
	                  |	ItemReceiptLineItems.Product");
	Query.SetParameter("Ref", Ref);
	Dataset = Query.Execute().Select();
	
	//AllowNegativeInventory = Constants.AllowNegativeInventory.Get();
	
	While Dataset.Next() Do
	
		CurrentBalance = 0;
		
		Query2 = New Query("SELECT
						  |	InventoryJrnlBalance.QtyBalance
						  |FROM
						  |	AccumulationRegister.InventoryJrnl.Balance AS InventoryJrnlBalance
						  |WHERE
						  |	InventoryJrnlBalance.Product = &Product
						  |	AND InventoryJrnlBalance.Location = &Location");			
		
		Query2.SetParameter("Product", Dataset.Product);
		Query2.SetParameter("Location", Location);
		
		QueryResult = Query2.Execute();
			
		If QueryResult.IsEmpty() Then
		Else
			Dataset2 = QueryResult.Unload();
			CurrentBalance = Dataset2[0][0];
		EndIf;
						
		If Dataset.Quantity > CurrentBalance Then
			CurProd = Dataset.Product;
			Message = New UserMessage();
			Message.Text= StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en='Insufficient balance on %1';de='Nicht ausreichende Bilanz'"),CurProd);
			Message.Message();
			//If NOT AllowNegativeInventory Then
				Cancel = True;
				Return;
			//EndIf;
		EndIf;
		
	EndDo;	
	
	// 1. Common posting clearing / deactivate manual ajusted postings
	DocumentPosting.PrepareRecordSetsForPostingClearing(AdditionalProperties, RegisterRecords);
	
	// 2. Skip manually adjusted documents
	If ManualAdjustment Then
		Return;
	EndIf;
	
	// 3. Create structures with document data to pass it on the server
	DocumentPosting.PrepareDataStructuresBeforePosting(AdditionalProperties);
	
	// 4. Collect document data, required for posing clearing, and fill created structure 
	Documents.ItemReceipt.PrepareDataStructuresForPostingClearing(Ref, AdditionalProperties, RegisterRecords);
	
	// 5. Write document postings to register
	DocumentPosting.WriteRecordSets(AdditionalProperties, RegisterRecords);

	// 6. Check register blanaces according to document's changes
	DocumentPosting.CheckPostingResults(AdditionalProperties, RegisterRecords, Cancel);

	// 7. Clear used temporary document data
	DocumentPosting.ClearDataStructuresAfterPosting(AdditionalProperties);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	// Clear manual ajustment attribute
	ManualAdjustment = False;
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	Var TabularSectionData; Cancel = False;
	
	// Filling on the base of other referenced object
	If FillingData <> Undefined Then
		
		// 0. Custom check of purchase order for interactive generate of items receipt on the base of purchase order
		If (TypeOf(FillingData) = Type("DocumentRef.PurchaseOrder"))
		And Not Documents.ItemReceipt.CheckStatusOfPurchaseOrder(Ref, FillingData) Then
			Cancel = True;
			Return;
		EndIf;
		
		// 1. Common filling of parameters
		DocumentParameters = New Structure("Ref, Date, Metadata",
		                                    Ref, ?(ValueIsFilled(Date), Date, CurrentSessionDate()), Metadata());
		DocumentFilling.PrepareDataStructuresBeforeFilling(AdditionalProperties, DocumentParameters, FillingData, Cancel);
		
		// 2. Cancel filling on failed data
		If Cancel Then
			Return;
		EndIf;
		
		// 3. Collect document data, available for filling, and fill created structure 
		Documents.ItemReceipt.PrepareDataStructuresForFilling(Ref, AdditionalProperties);
		
		// 4. Check collected data
		DocumentFilling.CheckDataStructuresOnFilling(AdditionalProperties, Cancel);
		
		// 5. Fill document fields
		If Not Cancel Then
			// Fill "draft" values to attributes (all including non-critical fields will be filled)
			FillPropertyValues(ThisObject, AdditionalProperties.Filling.FillingTables.Table_Attributes[0]);
			
			// Fill checked unique values to attributes (critical fields will be filled)
			FillPropertyValues(ThisObject, AdditionalProperties.Filling.FillingTables.Table_Check[0]);
			
			// Fill line items
			For Each TabularSection In AdditionalProperties.Metadata.TabularSections Do
				If AdditionalProperties.Filling.FillingTables.Property("Table_" + TabularSection.Name, TabularSectionData) Then
					ThisObject[TabularSection.Name].Load(TabularSectionData);
				EndIf;
			EndDo;
		EndIf;
		
		// 6. Clear used temporary document data
		DocumentFilling.ClearDataStructuresAfterFilling(AdditionalProperties);
	EndIf;
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	// Check doubles in items (to be sure of proper orders placement)
	GeneralFunctions.CheckDoubleItems(Ref, LineItems, "Project, Order, Product, LineNumber",, Cancel);
	
EndProcedure

#EndIf

#EndRegion
