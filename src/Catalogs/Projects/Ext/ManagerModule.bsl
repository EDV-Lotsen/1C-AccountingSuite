
////////////////////////////////////////////////////////////////////////////////
// Projects: Manager module
//------------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
#Region EVENTS_HANDLERS

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	
	// Activate custom presentation.
	StandardProcessing = False;
	
	// Assign fields that will be used for presentation generation.
	Fields.Add("Description");
	Fields.Add("Customer");
	
EndProcedure

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	
	// Use custom presentation.
	StandardProcessing = False;
	
	// Set presentation.
	CustomerPresentation = String(Data.Customer);
	Presentation = ?(Not IsBlankString(CustomerPresentation), CustomerPresentation + ": ", "") + Data.Description;
	
EndProcedure

#EndRegion


