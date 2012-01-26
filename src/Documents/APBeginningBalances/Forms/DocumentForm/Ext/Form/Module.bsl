
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Items.Company.Title = GeneralFunctionsReusable.GetVendorName();
	
	//Title = "A/P beg. bal. " + Object.Number;
	
	If GeneralFunctionsReusable.FunctionalOptionValue("MultiCurrency") Then
	Else
		If Object.AmountRC = NULL Then			
			Object.AmountRC = 0;
		EndIf;
	EndIf;

	If Object.DueDate = Date(1,1,1) Then
		Object.DueDate = Constants.BeginningBalancesDate.Get() + 60*60*24*30;
	EndIf;

EndProcedure
