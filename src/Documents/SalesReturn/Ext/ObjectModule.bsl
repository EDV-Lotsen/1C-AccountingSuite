
////////////////////////////////////////////////////////////////////////////////
// Sales return: Object module
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
		DocumentParameters = New Structure("Ref, Date, IsNew,   Posted, ManualAdjustment, Metadata  , ReturnType",
		                                    Ref, Date, IsNew(), Posted, ManualAdjustment, Metadata(), ReturnType);
		DocumentPosting.PrepareDataStructuresBeforeWrite(AdditionalProperties, DocumentParameters, Cancel, WriteMode, PostingMode);
	EndIf;
	
	// Precheck of register balances to complete filling of document posting.
	If WriteMode = DocumentWriteMode.Posting Then
		
		// Precheck of document data, calculation of temporary data, required for document posting.
		If (Not ManualAdjustment) Then
			DocumentParameters = New Structure("Ref, PointInTime,   Company, Location, LineItems",
			                                    Ref, PointInTime(), Company, Location, LineItems.Unload(, "Product, Unit, QtyUM, Project, Class"));
			Documents.SalesReturn.PrepareDataBeforeWrite(AdditionalProperties, DocumentParameters, Cancel);
		EndIf;
		
	EndIf;
	
	AvaTaxServer.AvataxDocumentBeforeWrite(ThisObject, Cancel);
		
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	// Forced assign the new document number.
	If ThisObject.IsNew() Then ThisObject.SetNewNumber(); EndIf;
	
	// Filling new document or filling on the base of another document.
	If FillingData = Undefined Then
		// Filling of the new created document with default values.
		Currency         = Constants.DefaultCurrency.Get();
		ExchangeRate     = GeneralFunctions.GetExchangeRate(Date, Currency);
		Location         = GeneralFunctions.GetDefaultLocation();
		
	Else
		// Generate on the base of sales invoice document.
		If (TypeOf(FillingData) = Type("DocumentRef.SalesInvoice")) Then
			
			// -> CODE REVIEW
			ParentDocument    		= FillingData.Ref;
			Company          		= FillingData.Company;
			DocumentTotal     		= FillingData.DocumentTotal;
			DocumentTotalRC   		= FillingData.DocumentTotalRC;
			SalesTax        		= FillingData.SalesTax;
			Currency          		= FillingData.Currency;
			ExchangeRate      		= FillingData.ExchangeRate;
			ARAccount         		= FillingData.ARAccount;
			Location          		= FillingData.LocationActual;
			ARAccount         		= FillingData.ARAccount;
			LineSubtotalRC    		= FillingData.LineSubtotal;
			SalesTaxRate      		= FillingData.SalesTaxRate;
			DiscountPercent   		= FillingData.DiscountPercent;
			Discount          		= FillingData.Discount;
			DiscountIsTaxable 		= FillingData.DiscountIsTaxable;
			SalesPerson       		= FillingData.SalesPerson;
			UseAvatax		  		= FillingData.UseAvatax;
			AvataxShippingTaxCode 	= FillingData.AvataxShippingTaxCode;
			DiscountTaxability		= FillingData.DiscountTaxability;
			ShipFrom				= FillingData.ShipTo;
			Shipping 				= FillingData.Shipping;
			
			For Each CurRowLineItems In FillingData.LineItems Do
				NewRow = LineItems.Add();
				FillPropertyValues(NewRow, CurRowLineItems);
			EndDo;
			
			If Not UseAvatax Then
				For Each SalesTaxAA In FillingData.SalesTaxAcrossAgencies Do
					NewSTAA = SalesTaxAcrossAgencies.Add();
					FillPropertyValues(NewSTAA, SalesTaxAA);
				EndDo;
			EndIf;
			// <- CODE REVIEW
			
		EndIf;
	EndIf;
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	// Clear manual adjustment attribute.
	ManualAdjustment = False;
	
EndProcedure

Procedure Posting(Cancel, Mode)
	
	// 1. Common postings clearing / reactivate manual ajusted postings.
	DocumentPosting.PrepareRecordSetsForPosting(AdditionalProperties, RegisterRecords);
	
	// 2. Skip manually adjusted documents.
	If ManualAdjustment Then
		Return;
	EndIf;
	
	// 3. Create structures with document data to pass it on the server.
	DocumentPosting.PrepareDataStructuresBeforePosting(AdditionalProperties);
	
	// 4. Collect document data, available for posing, and fill created structure.
	Documents.SalesReturn.PrepareDataStructuresForPosting(Ref, AdditionalProperties, RegisterRecords);
	
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
	Documents.SalesReturn.PrepareDataStructuresForPostingClearing(Ref, AdditionalProperties, RegisterRecords);
	
	// 5. Write document postings to register.
	DocumentPosting.WriteRecordSets(AdditionalProperties, RegisterRecords);
	
	// 6. Check register blanaces according to document's changes.
	DocumentPosting.CheckPostingResults(AdditionalProperties, RegisterRecords, Cancel);
	
	// 7. Clear used temporary document data.
	DocumentPosting.ClearDataStructuresAfterPosting(AdditionalProperties);
		
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	If Not UseAvatax Then
		FoundShipFrom = CheckedAttributes.Find("ShipFrom");
		If FoundShipFrom <> Undefined Then
			CheckedAttributes.Delete(FoundShipFrom);
		EndIf;
	EndIf;

EndProcedure

Procedure BeforeDelete(Cancel)
	
	//Avatax. Delete the document at Avatax prior to actual deletion
	AvaTaxServer.AvataxDocumentBeforeDelete(ThisObject, Cancel, "ReturnInvoice");

EndProcedure

#EndIf

#EndRegion
