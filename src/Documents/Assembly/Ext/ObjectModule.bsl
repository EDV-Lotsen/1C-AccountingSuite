
////////////////////////////////////////////////////////////////////////////////
// Assembly: Object module
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
	
	// Precheck of register balances to complete filling of document posting.
	If WriteMode = DocumentWriteMode.Posting Then
		
		// Precheck of document data, calculation of temporary data, required for document posting.
		If (Not ManualAdjustment) Then
			DocumentParameters = New Structure("Ref, PointInTime,   LineItems",
			                                    Ref, PointInTime(), LineItems.Unload(, "Product, Unit, Location, Project, Class, QtyUM"));
			Documents.Assembly.PrepareDataBeforeWrite(AdditionalProperties, DocumentParameters, Cancel);
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	// Check residuals cost.
	LineSubtotal_      = LineItems.Total("LineTotal");
	WasteSubtotal_     = LineItems.Total("WasteTotal");
	ResidualsSubtotal_ = Residuals.Total("LineTotal");
	ProcessedMaterials = ?(LineSubtotal_ > WasteSubtotal_, LineSubtotal_ - WasteSubtotal_, 0);
	ResidualsPercent   = ?(ProcessedMaterials = 0, 0, ResidualsSubtotal_ * 100 / ProcessedMaterials);
	
	// If residuals coming over 100% - then stop checking document.
	If ResidualsPercent > 100 Then
		MessageText = StringFunctionsClientServer.SubstituteParametersInString(
		              NStr("en = 'The residuals cost reached %1%% of processed materials. Reduce the residuals cost to 100%% or less.'"),
		              Round(ResidualsPercent, 2));
		CommonUseClientServer.MessageToUser(MessageText, Ref,,, Cancel);
		Return;
	EndIf;
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	// Forced assign the new document number.
	If ThisObject.IsNew() And Not ValueIsFilled(ThisObject.Number) Then ThisObject.SetNewNumber(); EndIf;
	
	// Filling new document or filling on the base of another document.
	If FillingData = Undefined Then
		// Filling of the new created document with default values.
		Location = GeneralFunctions.GetDefaultLocation();
		
	Else
		
		// Filling on the base of assembly.
		If TypeOf(FillingData) = Type("CatalogRef.Products") Then
			
			// Check assembly flag.
			If Not FillingData.Assembly Then
				Cancel = True;
				Return;
			EndIf;
			
			// Define rounding precision.
			QuantityPrecision = GeneralFunctionsReusable.DefaultQuantityPrecision();
			
			// Fill assembly data.
			ThisObject.Product            = FillingData;
			ThisObject.ProductDescription = FillingData.Description;
			ThisObject.UnitSet            = FillingData.UnitSet;
			ThisObject.Unit               = FillingData.UnitSet.DefaultPurchaseUnit;
			ThisObject.WasteAccount       = FillingData.WasteAccount;
			
			// Redefine assembly location.
			If  ThisObject.Location       = Catalogs.Locations.EmptyRef() Then
				ThisObject.Location       = ?(FillingData.DefaultLocation <> Catalogs.Locations.EmptyRef(),
				                              FillingData.DefaultLocation,
				                              GeneralFunctions.GetDefaultLocation());
			EndIf;
			
			// Calculate assembly quantities.
			ThisObject.QtyUnits           = 1; // Default 1 item for proper filling of table part.
			ThisObject.QtyUM              = Round(Round(ThisObject.QtyUnits, QuantityPrecision) *
			                                          ?(ThisObject.Unit.Factor > 0, ThisObject.Unit.Factor, 1), QuantityPrecision);
			
			// Load BOM.
			ThisObject.LineItems.Load(FillingData.LineItems.Unload());
			For Each Row In ThisObject.LineItems Do
				// Recalculate quantity / cost.
				Row.QtyItem       = Row.QtyUnits;
				Row.QtyUnits      = Round(Round(Row.QtyItem, QuantityPrecision) *
				                          Round(ThisObject.QtyUnits, QuantityPrecision) *
				                              ?(ThisObject.Unit.Factor > 0, ThisObject.Unit.Factor, 1), QuantityPrecision);
				Row.QtyUM         = Round(Round(Row.QtyUnits, QuantityPrecision) *
				                              ?(Row.Unit.Factor > 0, Row.Unit.Factor, 1), QuantityPrecision);
				Row.PriceUnits    = Round(GeneralFunctions.ProductLastCost(Row.Product) *
				                        ?(Row.Unit.Factor > 0, Row.Unit.Factor, 1),
				                          GeneralFunctionsReusable.PricePrecisionForOneItem(Row.Product));
				Row.LineTotal     = Round(Round(Row.QtyUnits,   QuantityPrecision) *
				                          Round(Row.PriceUnits, GeneralFunctionsReusable.PricePrecisionForOneItem(Row.Product)), 2);
				// Recalculate wastes.
				Row.WasteQtyUnits = Round(Round(Row.QtyUnits, QuantityPrecision) *
				                                Row.WastePercent / 100, QuantityPrecision);
				Row.WasteQtyUM    = Round(Round(Row.WasteQtyUnits, QuantityPrecision) *
				                              ?(Row.Unit.Factor > 0, Row.Unit.Factor, 1), QuantityPrecision);
				Row.WasteTotal    = Round(Round(Row.WasteQtyUnits, QuantityPrecision) *
				                          Round(Row.PriceUnits, GeneralFunctionsReusable.PricePrecisionForOneItem(Row.Product)), 2);
				// Fill analytics.
				FillPropertyValues(Row, ThisObject, "Location, Project, Class");
			EndDo;
			ThisObject.LineSubtotal      = ThisObject.LineItems.Total("LineTotal");
			ThisObject.WasteSubtotal     = ThisObject.LineItems.Total("WasteTotal");
			
			// Load residuals.
			ThisObject.Residuals.Load(FillingData.Residuals.Unload());
			For Each Row In ThisObject.Residuals Do
				// Recalculate quantity / cost.
				Row.QtyItem    = Row.QtyUnits;
				Row.QtyUnits   = Round(Round(Row.QtyItem, QuantityPrecision) *
				                       Round(ThisObject.QtyUnits, QuantityPrecision) *
				                           ?(ThisObject.Unit.Factor > 0, ThisObject.Unit.Factor, 1), QuantityPrecision);
				Row.QtyUM      = Round(Round(Row.QtyUnits, QuantityPrecision) *
				                           ?(Row.Unit.Factor > 0, Row.Unit.Factor, 1), QuantityPrecision);
				Row.LineTotal  = ?(Round(Row.QtyUnits, QuantityPrecision) > 0,
				                   Round((ThisObject.LineSubtotal - ThisObject.WasteSubtotal) *
				                         Row.Percent / 100, 2), 0);
				Row.PriceUnits = ?(Round(Row.QtyUnits, QuantityPrecision) > 0,
				                   Round(Row.LineTotal / Round(Row.QtyUnits, QuantityPrecision),
				                   GeneralFunctionsReusable.PricePrecisionForOneItem(Row.Product)), 0);
				// Fill analytics.
				FillPropertyValues(Row, ThisObject, "Location");
			EndDo;
			ThisObject.ResidualsSubtotal = ThisObject.Residuals.Total("LineTotal");
			
			// Load services.
			ThisObject.Services.Load(FillingData.Services.Unload());
			For Each Row In ThisObject.Services Do
				// Recalculate quantity / cost.
				Row.QtyItem    = Row.QtyUnits;
				Row.QtyUnits   = Round(Round(Row.QtyItem, QuantityPrecision) *
				                       Round(ThisObject.QtyUnits, QuantityPrecision) *
				                           ?(ThisObject.Unit.Factor > 0, ThisObject.Unit.Factor, 1), QuantityPrecision);
				Row.QtyUM      = Round(Round(Row.QtyUnits, QuantityPrecision) *
				                           ?(Row.Unit.Factor > 0, Row.Unit.Factor, 1), QuantityPrecision);
				Row.PriceUnits    = Round(GeneralFunctions.ProductLastCost(Row.Product) *
				                        ?(Row.Unit.Factor > 0, Row.Unit.Factor, 1),
				                          GeneralFunctionsReusable.PricePrecisionForOneItem(Row.Product));
				Row.LineTotal     = Round(Round(Row.QtyUnits,   QuantityPrecision) *
				                          Round(Row.PriceUnits, GeneralFunctionsReusable.PricePrecisionForOneItem(Row.Product)), 2);
				// Fill analytics.
				FillPropertyValues(Row, ThisObject, "Project, Class");
			EndDo;
			ThisObject.ServicesSubtotal  = ThisObject.Services.Total("LineTotal");
			
			// Calculate common assembly total.
			ThisObject.DocumentTotal     = ThisObject.LineSubtotal - ThisObject.ResidualsSubtotal - ThisObject.WasteSubtotal + ThisObject.ServicesSubtotal;
		EndIf;
	EndIf;
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	// Forced assign the new document number.
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
	Documents.Assembly.PrepareDataStructuresForPosting(Ref, AdditionalProperties, RegisterRecords);
	
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
	Documents.Assembly.PrepareDataStructuresForPostingClearing(Ref, AdditionalProperties, RegisterRecords);
	
	// 5. Write document postings to register.
	DocumentPosting.WriteRecordSets(AdditionalProperties, RegisterRecords);
	
	// 6. Check register blanaces according to document's changes.
	DocumentPosting.CheckPostingResults(AdditionalProperties, RegisterRecords, Cancel);
	
	// 7. Clear used temporary document data.
	DocumentPosting.ClearDataStructuresAfterPosting(AdditionalProperties);
	
EndProcedure

Procedure OnSetNewNumber(StandardProcessing, Prefix)
	
	StandardProcessing = False;
	
	Numerator = Catalogs.DocumentNumbering.Assembly;
	NextNumber = GeneralFunctions.Increment(Numerator.Number);
	
	While Documents.Assembly.FindByNumber(NextNumber) <> Documents.Assembly.EmptyRef() And NextNumber <> "" Do
		ObjectNumerator = Numerator.GetObject();
		ObjectNumerator.Number = NextNumber;
		ObjectNumerator.Write();
		
		NextNumber = GeneralFunctions.Increment(NextNumber);
	EndDo;
	
	ThisObject.Number = NextNumber; 

EndProcedure

#EndIf

#EndRegion
