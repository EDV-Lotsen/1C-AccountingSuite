
////////////////////////////////////////////////////////////////////////////////
// Sales Invoice: Object module
//------------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
#Region EVENT_HANDLERS

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	// -> CODE REVIEW
	// For webhooks.
	If NewObject = True Then
		NewObject = False;
	Else
		If Ref = Documents.SalesInvoice.EmptyRef() Then
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
		
		// Save custom document parameters.
		Orders = LineItems.UnloadColumn("Order");
		GeneralFunctions.NormalizeArray(Orders);
		
		// Common filling of parameters.
		DocumentParameters = New Structure("Ref, Date, IsNew,   Posted, ManualAdjustment, Metadata,   Orders",
		                                    Ref, Date, IsNew(), Posted, ManualAdjustment, Metadata(), Orders);
		DocumentPosting.PrepareDataStructuresBeforeWrite(AdditionalProperties, DocumentParameters, Cancel, WriteMode, PostingMode);
	EndIf;
	
	// Precheck of register balances to complete filling of document posting.
	If WriteMode = DocumentWriteMode.Posting Then
		
		// Precheck of document data, calculation of temporary data, required for document posting.
		If (Not ManualAdjustment) Then
			DocumentParameters = New Structure("Ref, PointInTime,   Company, LineItems",
			                                    Ref, PointInTime(), Company, LineItems.Unload(, "Order, Shipment, Product, Unit, Location, LocationActual, DeliveryDate, Project, Class, QtyUM"));
			Documents.SalesInvoice.PrepareDataBeforeWrite(AdditionalProperties, DocumentParameters, Cancel);
		EndIf;
				
	EndIf;
	
	AvaTaxServer.AvataxDocumentBeforeWrite(ThisObject, Cancel);	
	
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
	LotsSerialNumbers.CheckSerialNumbersFilling(Ref, PointInTime(), LineItems, SerialNumbers, 1, "Shipment", Cancel);
	
	// Create items filter by non-empty orders.
	FilledOrders = GeneralFunctions.InvertCollectionFilter(LineItems, LineItems.FindRows(New Structure("Order", Documents.SalesOrder.EmptyRef())));
	
	// Check doubles in items (to be sure of proper orders placement).
	//If Not SessionParameters.TenantValue = "1101092" Then // Locked for the tenant "1101092"
		GeneralFunctions.CheckDoubleItems(Ref, LineItems, "Product, Unit, Order, Shipment, Location, DeliveryDate, Project, Class, LineNumber", FilledOrders, Cancel);
	//EndIf;
	
	// Check proper closing of order items by the invoice items.
	If Not Cancel Then
		Documents.SalesInvoice.CheckOrderQuantity(Ref, Date, Company, LineItems, FilledOrders, Cancel);
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
		ARAccount        = Currency.DefaultARAccount;
		LocationActual   = GeneralFunctions.GetDefaultLocation();
		
	Else
		
		// -> CODE REVIEW
		//Quote
		If TypeOf(FillingData) = Type("DocumentRef.Quote") Then
			
			If Not Documents.Quote.IsOpen(FillingData) Then
				Cancel = True;
				Return;	
			EndIf;
			
			// Fill attributes.
			FillPropertyValues(ThisObject, FillingData, "Company, RefNum, ShipTo, BillTo, ConfirmTo, SalesPerson, Project,
			|Class, DropshipCompany, DropshipShipTo, DropshipConfirmTo, DropshipRefNum, Currency, ExchangeRate, SalesTaxRate,
			|DiscountIsTaxable, DiscountPercent, TaxableSubtotal, DocumentTotalRC, LineSubtotal, Discount, SalesTax, Shipping,
			|DocumentTotal, SubTotal, SalesTaxRC, Terms"); 
			
			Date               = CurrentSessionDate(); 
			BaseDocument       = FillingData; 
			LocationActual     = FillingData.Location; 
			DeliveryDateActual = FillingData.DeliveryDate;
			ARAccount          = Currency.DefaultARAccount;
			DueDate            = ?(Not Terms.IsEmpty(), Date + Terms.Days * 60*60*24, '00010101');
			EmailNote          = Constants.SalesInvoiceFooter.Get(); 
			
			//Fill "line items"
			ThisObject.LineItems.Load(FillingData.LineItems.Unload());
			
			//Fill additional fields in "line items"
			For Each Line In ThisObject.LineItems Do
				Line.LocationActual = Line.Location;
				Line.DeliveryDateActual = Line.DeliveryDate;
			EndDo;
			
			//Fill "Sales tax across agencies"
			ThisObject.SalesTaxAcrossAgencies.Load(FillingData.SalesTaxAcrossAgencies.Unload());
			
			Return;
			
		EndIf;
		//End Quote
		// <- CODE REVIEW
		
		// Generate on the base of Sales order & Shipment.
		Cancel = False; TabularSectionData = Undefined;
		
		// 0. Custom check of sales order for interactive generate of sales invoice on the base of sales order.
		If (TypeOf(FillingData) = Type("DocumentRef.SalesOrder"))
		And ((Not Documents.SalesInvoice.CheckStatusOfSalesOrder(Ref, FillingData)) Or (Documents.SalesInvoice.CheckUseShipmentOfSalesOrder(Ref, FillingData))) Then
			Cancel = True;
			Return;
		EndIf;
		
		// 0. Custom check of shipment for interactive generate of sales invoice on the base of shipment.
		If (TypeOf(FillingData) = Type("DocumentRef.Shipment"))
		And (Not Documents.SalesInvoice.CheckStatusOfShipment(Ref, FillingData)) Then
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
		Documents.SalesInvoice.PrepareDataStructuresForFilling(Ref, AdditionalProperties);
		
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
		
		// 7 Custom filling of UUIDs.
		EmptyUUID = New UUID("00000000-0000-0000-0000-000000000000");
		For Each Row In LineItems Do
			If Row.LineID = EmptyUUID Then
				Row.LineID = New UUID();
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	If ThisObject.IsNew() Then ThisObject.SetNewNumber(); EndIf;
	
	DwollaTrxID = 0;
	
	// Clear manual adjustment attribute.
	ManualAdjustment = False;
	
	// -> CODE REVIEW
	BaseDocument = Undefined;
	// <- CODE REVIEW
	
EndProcedure

// -> CODE REVIEW
Procedure OnSetNewNumber(StandardProcessing, Prefix)
	
	StandardProcessing = False;
	
	Numerator = Catalogs.DocumentNumbering.SalesInvoice;
	NextNumber = GeneralFunctions.Increment(Numerator.Number);
	
	While Documents.SalesInvoice.FindByNumber(NextNumber) <> Documents.SalesInvoice.EmptyRef() And NextNumber <> "" Do
		ObjectNumerator = Numerator.GetObject();
		ObjectNumerator.Number = NextNumber;
		ObjectNumerator.Write();
		
		NextNumber = GeneralFunctions.Increment(NextNumber);
	EndDo;
	
	ThisObject.Number = NextNumber; 

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
	Documents.SalesInvoice.PrepareDataStructuresForPosting(Ref, AdditionalProperties, RegisterRecords);
	
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
	Documents.SalesInvoice.PrepareDataStructuresForPostingClearing(Ref, AdditionalProperties, RegisterRecords);
	
	// 5. Write document postings to register.
	DocumentPosting.WriteRecordSets(AdditionalProperties, RegisterRecords);
	
	// 6. Check register blanaces according to document's changes.
	DocumentPosting.CheckPostingResults(AdditionalProperties, RegisterRecords, Cancel);
	
	// 7. Clear used temporary document data.
	DocumentPosting.ClearDataStructuresAfterPosting(AdditionalProperties);
	
EndProcedure

Procedure BeforeDelete(Cancel)
	
	//Avatax. Delete the document at Avatax prior to actual deletion
	AvaTaxServer.AvataxDocumentBeforeDelete(ThisObject, Cancel, "SalesInvoice");
	
EndProcedure

#EndIf

#EndRegion