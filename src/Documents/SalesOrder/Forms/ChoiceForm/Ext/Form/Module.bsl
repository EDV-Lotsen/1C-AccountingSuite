
////////////////////////////////////////////////////////////////////////////////
// Sales order: Choice form
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
	
	If Constants.UseSOPrepayment.Get() Then
		Items.Amount.Visible = True;
		Items.AmountRC.Visible = True;
	Else 	
		Items.Amount.Visible = False;
		Items.AmountRC.Visible = False;
	EndIf;	
	
EndProcedure

#EndRegion
