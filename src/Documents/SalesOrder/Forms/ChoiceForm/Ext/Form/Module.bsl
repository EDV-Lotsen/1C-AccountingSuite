
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Set company name title (Customer)
	Items.Company.Title = GeneralFunctionsReusable.GetCustomerName();
	
	// AdditionalReportsAndDataProcessors
	AdditionalReportsAndDataProcessors.OnCreateAtServer(ThisForm);
	// End AdditionalReportsAndDataProcessors
	
EndProcedure
