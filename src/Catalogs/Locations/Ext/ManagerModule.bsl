////////////////////////////////////////////////////////////////////////////////
// Locations: Manager module
//------------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
#Region EVENTS_HANDLERS

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	
	StandardProcessing = False;
	
	GetPresentation(Data.Ref, Presentation); 
	
EndProcedure

Procedure GetPresentation(Ref, Presentation)
	
	Presentation = ?(Presentation = "", Ref.Description, Ref.Description + ": " + Presentation);  
	
	If ValueIsFilled(Ref.Parent) Then
		GetPresentation(Ref.Parent, Presentation)
	EndIf;
	
EndProcedure

#EndRegion
