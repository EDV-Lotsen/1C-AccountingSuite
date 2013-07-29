
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	Items.Company.Title = GeneralFunctionsReusable.GetVendorName();
EndProcedure
