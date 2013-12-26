
////////////////////////////////////////////////////////////////////////////////
// Sales Order: Object module
//------------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
#Region EVENT_HANDLERS

//------------------------------------------------------------------------------
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
		
	// for webhooks
	If NewObject = True Then
		NewObject = False;
	Else
		If Ref = Documents.SalesOrder.EmptyRef() Then
			NewObject = True;
		EndIf;
	EndIf;
	
	// Save document parameters before posting the document
	If WriteMode = DocumentWriteMode.Posting
	Or WriteMode = DocumentWriteMode.UndoPosting Then
		
		// Common filling of parameters
		DocumentParameters = New Structure("Ref, Date, IsNew,   Posted, ManualAdjustment, Metadata",
		                                    Ref, Date, IsNew(), Posted, ManualAdjustment, Metadata());
		DocumentPosting.PrepareDataStructuresBeforeWrite(AdditionalProperties, DocumentParameters, Cancel, WriteMode, PostingMode);
		
	EndIf;
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	// Check doubles in items (to be sure of proper orders placement)
	GeneralFunctions.CheckDoubleItems(Ref, LineItems, "Product, Location, DeliveryDate, Project, Class, LineNumber",, Cancel);
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	// Filling of the new created document.
	If FillingData = Undefined Then
		Currency         = Constants.DefaultCurrency.Get();
		ExchangeRate     = 1;
		PriceIncludesVAT = GeneralFunctionsReusable.PriceIncludesVAT();
		Location         = Catalogs.Locations.MainWarehouse;
	EndIf;
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	// Clear manual ajustment attribute
	ManualAdjustment = False;
	
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
	Documents.SalesOrder.PrepareDataStructuresForPosting(Ref, AdditionalProperties, RegisterRecords);
	
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
	Documents.SalesOrder.PrepareDataStructuresForPostingClearing(Ref, AdditionalProperties, RegisterRecords);
	
	// 5. Write document postings to register
	DocumentPosting.WriteRecordSets(AdditionalProperties, RegisterRecords);
	
	// 6. Check register blanaces according to document's changes
	DocumentPosting.CheckPostingResults(AdditionalProperties, RegisterRecords, Cancel);
	
	// 7. Clear used temporary document data
	DocumentPosting.ClearDataStructuresAfterPosting(AdditionalProperties);
	
EndProcedure

#EndIf

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
//------------------------------------------------------------------------------

#EndRegion
