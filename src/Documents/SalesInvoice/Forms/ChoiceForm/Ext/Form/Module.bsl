
////////////////////////////////////////////////////////////////////////////////
// Sales invoice: Choice form
//------------------------------------------------------------------------------
// Available on:
// - Client (managed application)
// - Server
//

////////////////////////////////////////////////////////////////////////////////
#Region EVENTS_HANDLERS

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Set proper company field presentation.
	CustomerName = GeneralFunctionsReusable.GetCustomerName();
	Items.Company.Title           = CustomerName;
	Items.Company.ToolTip         = StringFunctionsClientServer.SubstituteParametersInString(NStr("en = '%1 name'"), CustomerName);
	Items.DropshipCompany.Title   = StringFunctionsClientServer.SubstituteParametersInString(NStr("en = 'Dropship %1'"), Lower(CustomerName));
	Items.DropshipCompany.ToolTip = StringFunctionsClientServer.SubstituteParametersInString(NStr("en = 'Dropship %1 name'"), Lower(CustomerName));
	
EndProcedure

#EndRegion
