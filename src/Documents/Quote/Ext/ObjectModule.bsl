
////////////////////////////////////////////////////////////////////////////////
// Sales Order: Object module
//------------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
#Region EVENT_HANDLERS

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	If Discount > 0 Then
		Message = New UserMessage();
		Message.Text=NStr("en='A discount should be a negative number'");
		//Message.Field = "Object.Description";
		Message.Message();
		Cancel = True;
		Return;
	EndIf;
	
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
		// Generate on the base of another document.
	EndIf;
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	If ThisObject.IsNew() Then ThisObject.SetNewNumber(); EndIf;
	
	// Clear manual adjustment attribute.
	ManualAdjustment = False;
	
EndProcedure

#EndIf

Procedure OnSetNewNumber(StandardProcessing, Prefix)
	
	StandardProcessing = False;
	
	Numerator = Catalogs.DocumentNumbering.Quote;
	NextNumber = GeneralFunctions.Increment(Numerator.Number);
	
	While Documents.Quote.FindByNumber(NextNumber) <> Documents.Quote.EmptyRef() And NextNumber <> "" Do
		ObjectNumerator = Numerator.GetObject();
		ObjectNumerator.Number = NextNumber;
		ObjectNumerator.Write();
		
		NextNumber = GeneralFunctions.Increment(NextNumber);
	EndDo;
	
	ThisObject.Number = NextNumber; 

EndProcedure

#EndRegion

