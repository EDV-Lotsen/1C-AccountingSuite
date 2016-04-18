
////////////////////////////////////////////////////////////////////////////////
// Cash sale: Object module
//------------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
#Region EVENT_HANDLERS

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	// -> CODE REVIEW
	//Check whether the document is deposited or not
	If Posted Then
		Request = New Query("SELECT
		                    |	UndepositedDocuments.Amount,
		                    |	UndepositedDocuments.AmountRC
		                    |FROM
		                    |	AccumulationRegister.UndepositedDocuments AS UndepositedDocuments
		                    |WHERE
		                    |	UndepositedDocuments.Document = &CurrentDocument
		                    |	AND UndepositedDocuments.RecordType = VALUE(AccumulationRecordType.Expense)");
		Request.SetParameter("CurrentDocument", Ref);
		Sel = Request.Execute().Select();
		If Sel.Next() Then
			If Sel.Amount <> DocumentTotal Then
				CommonUseClientServer.MessageToUser("The document is deposited. Document total amount (" + Format(DocumentTotal, "NFD=2; NZ=") + ") differs from the deposited amount (" + Format(Sel.Amount, "NFD=2; NZ=") + "). Unpost the Deposit document first.", ThisObject,, "Object.DocumentTotal", Cancel); 
			ElsIf WriteMode = DocumentWriteMode.UndoPosting Then
				CommonUseClientServer.MessageToUser("The document is deposited. Unpost the Deposit document first.", ThisObject,,, Cancel); 	
			EndIf;
		EndIf;
	EndIf;
	// <- CODE REVIEW
	
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
			                                    Ref, PointInTime(), Company, Location, LineItems.Unload(, "Product, Unit, Project, Class, QtyUM"));
			Documents.CashSale.PrepareDataBeforeWrite(AdditionalProperties, DocumentParameters, Cancel);
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	// -> CODE REVIEW
	If Discount > 0 Then
		// ??? !!!
		Message = New UserMessage();
		Message.Text=NStr("en='A discount should be a negative number'");
		//Message.Field = "Object.Description";
		Message.Message();
		Cancel = True;
		Return;
	EndIf;
	// <- CODE REVIEW
	
	// Check proper filling of lots.
	LotsSerialNumbers.CheckLotsFilling(Ref, LineItems, Cancel);
	
	// Check proper filling of serial numbers.
	LotsSerialNumbers.CheckSerialNumbersFilling(Ref, PointInTime(), LineItems, SerialNumbers, 1, "", Cancel);
	
	// Check sales tax rate filling
	If GeneralFunctionsReusable.FunctionalOptionValue("SalesTaxCharging") Then
		If Not ValueIsFilled(SalesTaxRate) Then
			CommonUseClientServer.MessageToUser(NStr("en = 'Field ""Sales tax rate"" is empty'"), Ref, "SalesTaxRate",, Cancel);
		EndIf;
	EndIf;
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	// Forced assign the new document number.
	If ThisObject.IsNew() And Not ValueIsFilled(ThisObject.Number) Then ThisObject.SetNewNumber(); EndIf;
	
	// Filling new document or filling on the base of another document.
	If FillingData = Undefined Then
		// Filling of the new created document with default values.
		Currency         = Constants.DefaultCurrency.Get();
		ExchangeRate     = GeneralFunctions.GetExchangeRate(Date, Currency);
		Location         = GeneralFunctions.GetDefaultLocation();
		
	Else
		// Generate on the base of another document.
		
	EndIf;
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	If ThisObject.IsNew() Then ThisObject.SetNewNumber(); EndIf;
	
	// Clear manual adjustment attribute.
	ManualAdjustment = False;
	
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
	Documents.CashSale.PrepareDataStructuresForPosting(Ref, AdditionalProperties, RegisterRecords);
	
	// 5. Fill register records with document's postings.
	DocumentPosting.FillRecordSets(AdditionalProperties, RegisterRecords, Cancel);
	
	// 6. Write document postings to register.
	DocumentPosting.WriteRecordSets(AdditionalProperties, RegisterRecords);
	
	// 7. Check register blanaces according to document's changes.
	DocumentPosting.CheckPostingResults(AdditionalProperties, RegisterRecords, Cancel);
	
	// 8. Clear used temporary document data.
	DocumentPosting.ClearDataStructuresAfterPosting(AdditionalProperties);
	
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
	Documents.CashSale.PrepareDataStructuresForPostingClearing(Ref, AdditionalProperties, RegisterRecords);
	
	// 5. Write document postings to register.
	DocumentPosting.WriteRecordSets(AdditionalProperties, RegisterRecords);
	
	// 6. Check register blanaces according to document's changes.
	DocumentPosting.CheckPostingResults(AdditionalProperties, RegisterRecords, Cancel);
	
	// 7. Clear used temporary document data.
	DocumentPosting.ClearDataStructuresAfterPosting(AdditionalProperties);
	
EndProcedure

#EndIf

#EndRegion

