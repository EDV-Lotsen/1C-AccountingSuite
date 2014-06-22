
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
	If ThisObject.IsNew() And Not ValueIsFilled(ThisObject.Number) Then ThisObject.SetNewNumber(); EndIf;
	
	// Filling new document or filling on the base of another document.
	If FillingData = Undefined Then
		// Filling of the new created document with default values.
		Currency         = Constants.DefaultCurrency.Get();
		ExchangeRate     = GeneralFunctions.GetExchangeRate(Date, Currency);
		Location         = Catalogs.Locations.MainWarehouse;
		
	Else
		
		If TypeOf(FillingData) = Type("DocumentRef.Quote") Then
			
			If Not Documents.Quote.IsOpen(FillingData) Then
				Cancel = True;
				Return;	
			EndIf;
			
			//Fill attributes
			FillPropertyValues(ThisObject, FillingData, "Company, ShipTo, BillTo, ConfirmTo, SalesPerson, Project,
			|Class, DropshipCompany, DropshipShipTo, DropshipConfirmTo, DropshipRefNum, Currency, ExchangeRate, SalesTaxRate,
			|DiscountIsTaxable, DiscountPercent, TaxableSubtotal, DocumentTotalRC, LineSubtotal, Discount, SalesTax, Shipping,
			|DocumentTotal, SubTotal, SalesTaxRC, Location, DeliveryDate, Terms"); 
			
			Date         = CurrentSessionDate(); 
			BaseDocument = FillingData; 
			ExternalMemo = Constants.SalesOrderFooter.Get();
			
			//Fill "line items"
			ThisObject.LineItems.Load(FillingData.LineItems.Unload());
			
			//Fill "Sales tax across agencies"
			ThisObject.SalesTaxAcrossAgencies.Load(FillingData.SalesTaxAcrossAgencies.Unload());
			
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	If ThisObject.IsNew() Then ThisObject.SetNewNumber(); EndIf;
	
	// Clear manual adjustment attribute.
	ManualAdjustment = False;
	
EndProcedure

// -> CODE REVIEW
Procedure OnWrite(Cancel)
	
	//companies_webhook = Constants.sales_orders_webhook.Get();
	//
	//If NOT companies_webhook = "" Then	
	//	
	//	WebhookMap = New Map(); 
	//	WebhookMap.Insert("apisecretkey",Constants.APISecretKey.Get());
	//	WebhookMap.Insert("resource","salesorders");
	//	If NewObject = True Then
	//		WebhookMap.Insert("action","create");
	//	Else
	//		WebhookMap.Insert("action","update");
	//	EndIf;
	//	WebhookMap.Insert("api_code",String(Ref.UUID()));
	//	
	//	WebhookParams = New Array();
	//	WebhookParams.Add(Constants.sales_orders_webhook.Get());
	//	WebhookParams.Add(WebhookMap);
	//	LongActions.ExecuteInBackground("GeneralFunctions.SendWebhook", WebhookParams);
	//
	//EndIf;
	
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
	
	so_url_webhook = Constants.sales_orders_webhook.Get();
	
	If NOT so_url_webhook = "" Then
		
		WebhookMap = GeneralFunctions.ReturnSaleOrderMap(Ref);
		WebhookMap.Insert("resource","salesorders");
		If NewObject = True Then
			WebhookMap.Insert("action","create");
		Else
			WebhookMap.Insert("action","update");
		EndIf;
		WebhookMap.Insert("apisecretkey",Constants.APISecretKey.Get());
		
		WebhookParams = New Array();
		WebhookParams.Add(so_url_webhook);
		WebhookParams.Add(WebhookMap);
		LongActions.ExecuteInBackground("GeneralFunctions.SendWebhook", WebhookParams);
		
	EndIf;
	
	email_so_webhook = Constants.so_webhook_email.Get();
	
	If NOT email_so_webhook = "" Then
		
		WebhookMap2 = GeneralFunctions.ReturnSaleOrderMap(Ref);
		WebhookMap2.Insert("resource","salesorders");
		If NewObject = True Then
			WebhookMap2.Insert("action","create");
		Else
			WebhookMap2.Insert("action","update");
		EndIf;
		WebhookMap2.Insert("apisecretkey",Constants.APISecretKey.Get());
		
		WebhookParams2 = New Array();
		WebhookParams2.Add(email_so_webhook);
		WebhookParams2.Add(WebhookMap2);
		LongActions.ExecuteInBackground("GeneralFunctions.EmailWebhook", WebhookParams2);
		
	EndIf;
	
	
	
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

Procedure OnSetNewNumber(StandardProcessing, Prefix)
	
	StandardProcessing = False;
	
	Numerator = Catalogs.DocumentNumbering.SalesOrder;
	NextNumber = GeneralFunctions.Increment(Numerator.Number);
	
	While Documents.SalesOrder.FindByNumber(NextNumber) <> Documents.SalesOrder.EmptyRef() And NextNumber <> "" Do
		ObjectNumerator = Numerator.GetObject();
		ObjectNumerator.Number = NextNumber;
		ObjectNumerator.Write();
		
		NextNumber = GeneralFunctions.Increment(NextNumber);
	EndDo;
	
	ThisObject.Number = NextNumber; 

EndProcedure

#EndRegion
