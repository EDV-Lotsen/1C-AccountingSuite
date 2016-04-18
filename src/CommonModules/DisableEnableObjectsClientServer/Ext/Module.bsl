
////////////////////////////////////////////////////////////////////////////////
// Disable/Enable Objects client-server: Common client-server functions
//------------------------------------------------------------------------------
// Available on:
// - Client
// - Server

////////////////////////////////////////////////////////////////////////////////
// Primary functions:
// - manages form list filter by attribute InArchive;

////////////////////////////////////////////////////////////////////////////////
#Region PUBLIC_INTERFACE
 
Procedure SetFilterCompaniesInArchive(Form, Use) Export
	
	If Use Then
		CommonUseClientServer.SetFilterItem(
			Form.List.Filter, "InArchive", False);
	Else
		CommonUseClientServer.DeleteFilterItems(
			Form.List.Filter, "InArchive");
	EndIf;
	
EndProcedure

#EndRegion
