
////////////////////////////////////////////////////////////////////////////////
// Item Receipt: Object module
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
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	// 1. Common postings clearing / reactivate manual ajusted postings.
	DocumentPosting.PrepareRecordSetsForPosting(AdditionalProperties, RegisterRecords);
	
	// 2. Skip manually adjusted documents.
	If ManualAdjustment Then
		Return;
	EndIf;
	
	// 3. Create structures with document data to pass it on the server.
	DocumentPosting.PrepareDataStructuresBeforePosting(AdditionalProperties);
	
	// 4. Collect document data, available for posing, and fill created structure.
	Documents.ItemReceipt.PrepareDataStructuresForPosting(Ref, AdditionalProperties, RegisterRecords);
	
	// 5. Fill register records with document's postings.
	DocumentPosting.FillRecordSets(AdditionalProperties, RegisterRecords, Cancel);
	
	// 6. Write document postings to register.
	DocumentPosting.WriteRecordSets(AdditionalProperties, RegisterRecords);
	
	// 7. Check register blanaces according to document's changes.
	DocumentPosting.CheckPostingResults(AdditionalProperties, RegisterRecords, Cancel);
	
	// 8. Clear used temporary document data.
	DocumentPosting.ClearDataStructuresAfterPosting(AdditionalProperties);
	
	
	// -> CODE REVIEW
	
	// Fill in the account posting value table with amounts.
	PostingDataset = New ValueTable();
	PostingDataset.Columns.Add("Account");
	PostingDataset.Columns.Add("AmountRC");
	
	CalculateByPlannedCosting = False;
	PurchaseLiabilityAccount  = ChartsOfAccounts.ChartOfAccounts.EmptyRef(); // Constants.PurchaseLiabilityAccount.Get();
	CostVarianceAccount       = ChartsOfAccounts.ChartOfAccounts.EmptyRef(); // Constants.CostVarianceAccount.Get();
	
	For Each CurRowLineItems in LineItems Do
		// Detect inventory item in table part.
		IsInventoryPosting = (Not CurRowLineItems.Product.IsEmpty()) And (CurRowLineItems.Product.Type = Enums.InventoryTypes.Inventory);
		
		PostingLine = PostingDataset.Add();
		If CalculateByPlannedCosting And IsInventoryPosting Then
			//PostingLine.Account = AccruedPurchasesAccount;
		Else
			PostingLine.Account = CurRowLineItems.Product.InventoryOrExpenseAccount;
		EndIf;
		PostingLine.AmountRC = CurRowLineItems.LineTotal * ExchangeRate;
	EndDo;
	
	PostingDataset.GroupBy("Account", "AmountRC");
	
	NoOfPostingRows = PostingDataset.Count();
	
	// GL posting.
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
	
	RegisterRecords.ProjectData.Write = True;
	For Each CurRowLineItems In LineItems Do
		Record = RegisterRecords.ProjectData.Add();
		Record.RecordType = AccumulationRecordType.Expense;
		Record.Period = Date;
		Record.Project = CurRowLineItems.Project;
		Record.Amount = CurRowLineItems.LineTotal;
	EndDo;
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
	Documents.ItemReceipt.PrepareDataStructuresForPostingClearing(Ref, AdditionalProperties, RegisterRecords);
	
	// 5. Write document postings to register.
	DocumentPosting.WriteRecordSets(AdditionalProperties, RegisterRecords);
	
	// 6. Check register blanaces according to document's changes.
	DocumentPosting.CheckPostingResults(AdditionalProperties, RegisterRecords, Cancel);
	
	// 7. Clear used temporary document data.
	DocumentPosting.ClearDataStructuresAfterPosting(AdditionalProperties);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	// Clear manual adjustment attribute.
	ManualAdjustment = False;
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	Var TabularSectionData; Cancel = False;
	
	// Filling on the base of other referenced object.
	If FillingData <> Undefined Then
		
		// 0. Custom check of purchase order for interactive generate of items receipt on the base of purchase order.
		If (TypeOf(FillingData) = Type("DocumentRef.PurchaseOrder"))
		And Not Documents.ItemReceipt.CheckStatusOfPurchaseOrder(Ref, FillingData) Then
			Cancel = True;
			Return;
		EndIf;
		
		// 1. Common filling of parameters.
		DocumentParameters = New Structure("Ref, Date, Metadata",
		                                    Ref, ?(ValueIsFilled(Date), Date, CurrentSessionDate()), Metadata());
		DocumentFilling.PrepareDataStructuresBeforeFilling(AdditionalProperties, DocumentParameters, FillingData, Cancel);
		
		// 2. Cancel filling on failed data.
		If Cancel Then
			Return;
		EndIf;
		
		// 3. Collect document data, available for filling, and fill created structure.
		Documents.ItemReceipt.PrepareDataStructuresForFilling(Ref, AdditionalProperties);
		
		// 4. Check collected data.
		DocumentFilling.CheckDataStructuresOnFilling(AdditionalProperties, Cancel);
		
		// 5. Fill document fields.
		If Not Cancel Then
			// Fill "draft" values to attributes (all including non-critical fields will be filled).
			FillPropertyValues(ThisObject, AdditionalProperties.Filling.FillingTables.Table_Attributes[0]);
			
			// Fill checked unique values to attributes (critical fields will be filled).
			FillPropertyValues(ThisObject, AdditionalProperties.Filling.FillingTables.Table_Check[0]);
			
			// Fill line items.
			For Each TabularSection In AdditionalProperties.Metadata.TabularSections Do
				If AdditionalProperties.Filling.FillingTables.Property("Table_" + TabularSection.Name, TabularSectionData) Then
					ThisObject[TabularSection.Name].Load(TabularSectionData);
				EndIf;
			EndDo;
		EndIf;
		
		// 6. Clear used temporary document data.
		DocumentFilling.ClearDataStructuresAfterFilling(AdditionalProperties);
	EndIf;
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	// Check doubles in items (to be sure of proper orders placement).
	GeneralFunctions.CheckDoubleItems(Ref, LineItems, "Project, Order, Product, LineNumber",, Cancel);
	
EndProcedure

#EndIf

#EndRegion
