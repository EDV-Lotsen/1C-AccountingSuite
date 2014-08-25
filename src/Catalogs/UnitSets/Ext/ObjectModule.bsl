
////////////////////////////////////////////////////////////////////////////////
// Unit sets: Object module
//------------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
#Region EVENT_HANDLERS

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	// Forced assign the new catalog number.
	//If ThisObject.IsNew() And Not ValueIsFilled(ThisObject.Number) Then ThisObject.SetNewNumber(); EndIf;
	
EndProcedure

#EndIf

#EndRegion
