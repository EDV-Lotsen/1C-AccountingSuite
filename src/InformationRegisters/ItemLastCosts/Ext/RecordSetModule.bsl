
////////////////////////////////////////////////////////////////////////////////
// Item last costs: Recordset module
//------------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
#Region EVENT_HANDLERS

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

Procedure BeforeWrite(Cancel, Replacing)
	
	// Skip checking for loaded datasets or overwritten data.
	If DataExchange.Load Or Not DocumentPosting.WriteChangesOnly(AdditionalProperties) Then
		Return;
	EndIf;
	
	// Lock register, preventing other transactions to read data from register before changing.
	LockForUpdate = True;
	
	// Assign additional data tables (if needed) to the AdditionalProperties.Posting structure.
	
EndProcedure

Procedure OnWrite(Cancel, Replacing)
	
	// Skip checking for loaded datasets or overwritten data.
	If DataExchange.Load Or Not DocumentPosting.WriteChangesOnly(AdditionalProperties) Then
		Return;
	EndIf;
	
	// Assign additional data tables (if needed) to the AdditionalProperties.Posting structure.
	
EndProcedure

#EndIf

#EndRegion
