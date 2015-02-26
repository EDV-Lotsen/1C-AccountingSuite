
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
	
	If Constants.DisplayOrderIndicators.Get() = False Then
		Items.Received.Visible = False;
		Items.Invoiced.Visible = False;
	EndIf;

	
	// Set proper company field presentation.
	VendorName   = GeneralFunctionsReusable.GetVendorName();
	CustomerName = GeneralFunctionsReusable.GetCustomerName();
	Items.Company.Title           = VendorName;
	Items.Company.ToolTip         = StringFunctionsClientServer.SubstituteParametersInString(NStr("en = '%1 name'"), VendorName);
	Items.DropshipCompany.Title   = CustomerName;
	Items.DropshipCompany.ToolTip = StringFunctionsClientServer.SubstituteParametersInString(NStr("en = '%1 name'"), CustomerName);
	
	// Set parameters of List.
	List.Parameters.SetParameterValue("CurrentDateSession", BegOfDay(CurrentSessionDate()));
	
EndProcedure

#EndRegion
