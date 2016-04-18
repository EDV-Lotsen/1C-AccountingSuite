
////////////////////////////////////////////////////////////////////////////////
// Disable/Enable Objects server call: Common server call functions
//------------------------------------------------------------------------------
// Available on:
// - Client
// - ServerCall

////////////////////////////////////////////////////////////////////////////////
// Primary functions:
// - manages attribute InArchive;

////////////////////////////////////////////////////////////////////////////////
#Region PUBLIC_INTERFACE
 
Procedure DisableEnableCommandServer(Companies, FlagValueToSet) Export
	
	InArchiveValues = CommonUse.ObjectAttributeValue(Companies, "InArchive");
	For Each Item In InArchiveValues Do
		
		If Item.Value = FlagValueToSet Then
			Continue;
		EndIf;
		
		CompanyObject           = Item.Key.GetObject();
		CompanyObject.InArchive = FlagValueToSet;
		CompanyObject.Write();
	EndDo;
	
EndProcedure

#EndRegion
