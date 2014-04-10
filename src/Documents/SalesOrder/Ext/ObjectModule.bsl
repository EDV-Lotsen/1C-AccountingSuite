
////////////////////////////////////////////////////////////////////////////////
// Sales Order: Object module
//------------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
#Region EVENT_HANDLERS

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

// -> CODE REVIEW
Procedure BeforeDelete(Cancel)
	
	companies_webhook = Constants.sales_orders_webhook.Get();
	
	If NOT companies_webhook = "" Then	
		
		WebhookMap = New Map(); 
		WebhookMap.Insert("apisecretkey",Constants.APISecretKey.Get());
		WebhookMap.Insert("resource","salesorders");
		WebhookMap.Insert("action","delete");
		WebhookMap.Insert("api_code",String(Ref.UUID()));
		
		WebhookParams = New Array();
		WebhookParams.Add(Constants.sales_orders_webhook.Get());
		WebhookParams.Add(WebhookMap);
		LongActions.ExecuteInBackground("GeneralFunctions.SendWebhook", WebhookParams);
	
	EndIf;
	
EndProcedure
// <- CODE REVIEW

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	// -> CODE REVIEW
	// For webhooks.
	If NewObject = True Then
		NewObject = False;
	Else
		If Ref = Documents.SalesOrder.EmptyRef() Then
			NewObject = True;
		EndIf;
	EndIf;
	// <- CODE REVIEW
	
	// Save document parameters before posting the document.
	If WriteMode = DocumentWriteMode.Posting
	Or WriteMode = DocumentWriteMode.UndoPosting Then
		
		// Common filling of parameters.
		DocumentParameters = New Structure("Ref, Date, IsNew,   Posted, ManualAdjustment, Metadata",
		                                    Ref, Date, IsNew(), Posted, ManualAdjustment, Metadata());
		DocumentPosting.PrepareDataStructuresBeforeWrite(AdditionalProperties, DocumentParameters, Cancel, WriteMode, PostingMode);
		
	EndIf;
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	// -> CODE REVIEW
	If Discount > 0 Then
		Message = New UserMessage();
		Message.Text=NStr("en='A discount should be a negative number'");
		//Message.Field = "Object.Description";
		Message.Message();
		Cancel = True;
		Return;
	EndIf;
	// <- CODE REVIEW
	
	
	// Check doubles in items (to be sure of proper orders placement).
	GeneralFunctions.CheckDoubleItems(Ref, LineItems, "Product, Location, DeliveryDate, Project, Class, LineNumber",, Cancel);
	
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
		// Generate on the base of another document.
	EndIf;
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	// Clear manual ajustment attribute.
	ManualAdjustment = False;
	
EndProcedure

// -> CODE REVIEW
Procedure OnWrite(Cancel)
	
	companies_webhook = Constants.sales_orders_webhook.Get();
	
	If NOT companies_webhook = "" Then	
		
		WebhookMap = New Map(); 
		WebhookMap.Insert("apisecretkey",Constants.APISecretKey.Get());
		WebhookMap.Insert("resource","salesorders");
		If NewObject = True Then
			WebhookMap.Insert("action","create");
		Else
			WebhookMap.Insert("action","update");
		EndIf;
		WebhookMap.Insert("api_code",String(Ref.UUID()));
		
		WebhookParams = New Array();
		WebhookParams.Add(Constants.sales_orders_webhook.Get());
		WebhookParams.Add(WebhookMap);
		LongActions.ExecuteInBackground("GeneralFunctions.SendWebhook", WebhookParams);
	
	EndIf;
	
EndProcedure
// <- CODE REVIEW

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
	Documents.SalesOrder.PrepareDataStructuresForPosting(Ref, AdditionalProperties, RegisterRecords);
	
	// 5. Fill register records with document's postings.
	DocumentPosting.FillRecordSets(AdditionalProperties, RegisterRecords, Cancel);
	
	// 6. Write document postings to register.
	DocumentPosting.WriteRecordSets(AdditionalProperties, RegisterRecords);
	
	// 7. Check register blanaces according to document's changes.
	DocumentPosting.CheckPostingResults(AdditionalProperties, RegisterRecords, Cancel);
	
	// 8. Clear used temporary document data.
	DocumentPosting.ClearDataStructuresAfterPosting(AdditionalProperties);
	
	
	// -> CODE REVIEW
	RegisterRecords.OrderTransactions.Write = True;
	Record = RegisterRecords.OrderTransactions.Add();
	Record.RecordType = AccumulationRecordType.Receipt;
	Record.Period = Date;
	Record.Order = Ref;
	Record.Amount = DocumentTotalRC;
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
	Documents.SalesOrder.PrepareDataStructuresForPostingClearing(Ref, AdditionalProperties, RegisterRecords);
	
	// 5. Write document postings to register.
	DocumentPosting.WriteRecordSets(AdditionalProperties, RegisterRecords);
	
	// 6. Check register blanaces according to document's changes.
	DocumentPosting.CheckPostingResults(AdditionalProperties, RegisterRecords, Cancel);
	
	// 7. Clear used temporary document data.
	DocumentPosting.ClearDataStructuresAfterPosting(AdditionalProperties);
	
EndProcedure

#EndIf

#EndRegion
