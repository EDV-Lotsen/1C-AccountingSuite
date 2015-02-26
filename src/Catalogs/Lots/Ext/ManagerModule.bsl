
////////////////////////////////////////////////////////////////////////////////
// Lots: Manager module
//------------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
#Region EVENTS_HANDLERS

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	
	// Use custom fileds for bilding presentation.
	StandardProcessing = False;
	
	// Add presentation fields names.
	Fields.Add("Owner");
	Fields.Add("Code");
	
EndProcedure

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	
	// Create the date presentation for expiration dates.
	If TypeOf(Data.Owner) = Type("CatalogRef.Products") And Data.Owner.UseLotsType = 2 Then
		
		// Build custom presentation.
		StandardProcessing = False;
		
		// Format production/expiry date.
		Presentation = Format(Date(Data.Code), "DLF=D; DE=-");
	EndIf;
	
EndProcedure

#EndIf

#EndRegion
