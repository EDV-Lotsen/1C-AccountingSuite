
////////////////////////////////////////////////////////////////////////////////
// Purchase order: List form
//------------------------------------------------------------------------------
// Available on:
// - Client (managed application)
// - Server
//

////////////////////////////////////////////////////////////////////////////////
#Region EVENTS_HANDLERS

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Set proper Company field presentation.
	CompanyTitle = GeneralFunctionsReusable.GetVendorName();
	Items.Company.Title     = CompanyTitle;
	//Items.CompanyCode.Title = StringFunctionsClientServer.SubstituteParametersInString(
	//						  NStr("en = '%1 #'"), CompanyTitle);
	
EndProcedure

#EndRegion
