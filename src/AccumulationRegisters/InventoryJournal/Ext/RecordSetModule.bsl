
////////////////////////////////////////////////////////////////////////////////
// Inventory Journal: Recordset module
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
	
	// Save current state of register records before write of recordset.
	DocumentPosting.CheckRecordsetChangesBeforeWrite(Filter.Recorder.Value, AdditionalProperties, Cancel);
	
EndProcedure

Procedure OnWrite(Cancel, Replacing)
	
	// Skip checking for loaded datasets or overwritten data.
	If DataExchange.Load Or Not DocumentPosting.WriteChangesOnly(AdditionalProperties) Then
		Return;
	EndIf;
	
	// Save difference between old and new list of register records.
	DocumentPosting.CheckRecordsetChangesOnWrite(Filter.Recorder.Value, AdditionalProperties, Cancel);
	
EndProcedure

#EndIf

#EndRegion
