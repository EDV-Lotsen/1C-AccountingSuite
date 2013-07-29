
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Set company name title (Customer)
	Items.Company.Title = GeneralFunctionsReusable.GetCustomerName();
	
EndProcedure
