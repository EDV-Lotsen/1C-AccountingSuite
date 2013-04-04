
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Items.Company.Title = GeneralFunctionsReusable.GetVendorName();
	
	// AdditionalReportsAndDataProcessors
	AdditionalReportsAndDataProcessors.OnCreateAtServer(ThisForm);
	// End AdditionalReportsAndDataProcessors
	
EndProcedure
