
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Set company name title (Vendor)
	Items.Company.Title = GeneralFunctionsReusable.GetVendorName();
	
EndProcedure
