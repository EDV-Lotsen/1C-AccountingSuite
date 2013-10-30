
////////////////////////////////////////////////////////////////////////////////
// Purchase Order: Object module
//------------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
// OBJECT EVENTS HANDLERS

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
	Documents.PurchaseOrder.PrepareDataStructuresForPosting(Ref, AdditionalProperties, RegisterRecords);
	
	// 5. Fill register records with document's postings
	DocumentPosting.FillRecordSets(AdditionalProperties, RegisterRecords, Cancel);
	
	// 6. Write document postings to register
	DocumentPosting.WriteRecordSets(AdditionalProperties, RegisterRecords);
	
	// 7. Check register blanaces according to document's changes
	DocumentPosting.CheckPostingResults(AdditionalProperties, RegisterRecords, Cancel);
	
	// 8. Clear used temporary document data
	DocumentPosting.ClearDataStructuresAfterPosting(AdditionalProperties);
	
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
	Documents.PurchaseOrder.PrepareDataStructuresForPostingClearing(Ref, AdditionalProperties, RegisterRecords);
	
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

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	// Check doubles in items (to be sure of proper orders placement)
	GeneralFunctions.CheckDoubleItems(Ref, LineItems, "Product, LineNumber", Cancel);
	
EndProcedure



