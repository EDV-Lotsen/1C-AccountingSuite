
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Items.Customer.Title = GeneralFunctionsReusable.GetCustomerName();
	Items.Vendor.Title = GeneralFunctionsReusable.GetVendorName();
	
EndProcedure
