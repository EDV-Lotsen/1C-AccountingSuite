
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Items.Company.Title = GeneralFunctionsReusable.GetCustomerName();
	
	// AdditionalReportsAndDataProcessors
	AdditionalReportsAndDataProcessors.OnCreateAtServer(ThisForm);
	// End AdditionalReportsAndDataProcessors
	
EndProcedure
