
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Try
		Items.Customer.Title = GeneralFunctionsReusable.GetCustomerName();
		Items.Vendor.Title = GeneralFunctionsReusable.GetVendorName();
	Except
	EndTry;
	
EndProcedure