
////////////////////////////////////////////////////////////////////////////////
// Sales Order: Object module
//------------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
#Region EVENT_HANDLERS

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	// -> CODE REVIEW
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
	
	// Check positive discounts.
	If Discount > 0 Then
		MessageText = StringFunctionsClientServer.SubstituteParametersInString(NStr("en = 'Specified discount: %1. A discount should be negative number.'"), Format(Discount, "NFD=2; NZ="));
		CommonUseClientServer.MessageToUser(MessageText, Ref,,, Cancel);
	EndIf;
	
	// Check sales tax rate filling
	If GeneralFunctionsReusable.FunctionalOptionValue("SalesTaxCharging") And Not UseAvatax Then
		If Not ValueIsFilled(SalesTaxRate) Then
			CommonUseClientServer.MessageToUser(NStr("en = 'Field ""Sales tax rate"" is empty'"), Ref, "SalesTaxRate",, Cancel);
		EndIf;
	EndIf;
	
	// Check doubles in items (to be sure of proper orders placement).
	GeneralFunctions.CheckDoubleItems(Ref, LineItems, "Product, Unit, Location, DeliveryDate, Project, Class, LineNumber",, Cancel);
	
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
		UseShipment      = Constants.EnhancedInventoryShipping.Get();

	Else
		
		If TypeOf(FillingData) = Type("DocumentRef.Quote") Then
			
			If Not Documents.Quote.IsOpen(FillingData) Then
				Cancel = True;
				Return;	
			EndIf;
			
			//Fill attributes
			FillPropertyValues(ThisObject, FillingData, "Company, RefNum, ShipTo, BillTo, ConfirmTo, SalesPerson, Project,
			|Class, DropshipCompany, DropshipShipTo, DropshipConfirmTo, DropshipRefNum, Currency, ExchangeRate, SalesTaxRate,
			|DiscountIsTaxable, DiscountPercent, TaxableSubtotal, DocumentTotalRC, LineSubtotal, Discount, SalesTax, Shipping,
			|DocumentTotal, SubTotal, SalesTaxRC, Location, DeliveryDate, Terms"); 
			
			Date         = CurrentSessionDate(); 
			BaseDocument = FillingData; 
			
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
	
	BaseDocument = Undefined;
	
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

#EndRegion
