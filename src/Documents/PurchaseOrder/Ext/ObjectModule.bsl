
////////////////////////////////////////////////////////////////////////////////
// Purchase order: Object module
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

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	// Check doubles in items (to be sure of proper orders placement).
	GeneralFunctions.CheckDoubleItems(Ref, LineItems, "Product, Location, DeliveryDate, Project, Class, LineNumber",, Cancel);
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	If ThisObject.IsNew() And Not ValueIsFilled(ThisObject.Number) Then ThisObject.SetNewNumber() EndIf;
	
	If FillingData = Undefined Then
		// Filling of the new created document with default values.
		Currency         = Constants.DefaultCurrency.Get();
		ExchangeRate     = GeneralFunctions.GetExchangeRate(Date, Currency);
		Location         = Catalogs.Locations.MainWarehouse;
		
	Else
		
		// Generate on the base of some document.
		
		If TypeOf(FillingData) = Type("DocumentRef.SalesOrder") Then
			
			//Fill attributes
			Date         = CurrentSessionDate(); 
			BaseDocument = FillingData; 
			
			Currency     = FillingData.Currency;
			ExchangeRate = FillingData.ExchangeRate;
			Location     = FillingData.Location;
			DeliveryDate = FillingData.DeliveryDate;
			Project      = FillingData.Project;
			Class        = FillingData.Class;
			
			If Constants.CopyDropshipPrintOptionsSO_PO.Get() Then
				
				DropshipCompany   = FillingData.DropshipCompany;
				DropshipShipTo    = FillingData.DropshipShipTo;
				DropshipConfirmTo = FillingData.DropshipConfirmTo; 
				DropshipRefNum    = FillingData.DropshipRefNum;
				
			EndIf;
			
			//Fill "line items"
			QuantityPrecision = 0; //QuantityPrecision = Constants.QtyPrecision.Get(); 
			For Each Line In FillingData.LineItems Do 
				
				NewLine = LineItems.Add();
				NewLine.Product            = Line.Product;
				NewLine.ProductDescription = Line.ProductDescription;
				NewLine.Quantity           = Line.Quantity;
				NewLine.UM                 = Line.UM;
				NewLine.Price              = GeneralFunctions.ProductLastCost(NewLine.Product);
				NewLine.LineTotal          = Round(Round(NewLine.Quantity, QuantityPrecision) * NewLine.Price, 2);
				NewLine.Price              = ?(Round(NewLine.Quantity, QuantityPrecision) > 0,
	                                           Round(NewLine.LineTotal / Round(NewLine.Quantity, QuantityPrecision), 2), 0);
				NewLine.Location           = Line.Location;
				NewLine.DeliveryDate       = Line.DeliveryDate;
				NewLine.Project            = Line.Project;
				NewLine.Class              = Line.Class;
				
			EndDo;
			
			DocumentTotal   = LineItems.Total("LineTotal");
			DocumentTotalRC = Round(DocumentTotal * ExchangeRate, 2);
			
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	If ThisObject.IsNew() Then ThisObject.SetNewNumber() EndIf;
	
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
	Documents.PurchaseOrder.PrepareDataStructuresForPosting(Ref, AdditionalProperties, RegisterRecords);
	
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
	Documents.PurchaseOrder.PrepareDataStructuresForPostingClearing(Ref, AdditionalProperties, RegisterRecords);
	
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
	
	Numerator = Catalogs.DocumentNumbering.PurchaseOrder;
	NextNumber = GeneralFunctions.Increment(Numerator.Number);
	
	While Documents.PurchaseOrder.FindByNumber(NextNumber) <> Documents.PurchaseOrder.EmptyRef() And NextNumber <> "" Do
		ObjectNumerator = Numerator.GetObject();
		ObjectNumerator.Number = NextNumber;
		ObjectNumerator.Write();
		
		NextNumber = GeneralFunctions.Increment(NextNumber);
	EndDo;
	
	ThisObject.Number = NextNumber; 

EndProcedure

#EndRegion
