
////////////////////////////////////////////////////////////////////////////////
// General Journal: Recordset module
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
	
EndProcedure

Procedure OnWrite(Cancel, Replacing)
	
	// Skip checking for loaded datasets or overwritten data.
	If DataExchange.Load Or Not DocumentPosting.WriteChangesOnly(AdditionalProperties) Then
		Return;
	EndIf;
	
EndProcedure

#EndIf

#EndRegion
