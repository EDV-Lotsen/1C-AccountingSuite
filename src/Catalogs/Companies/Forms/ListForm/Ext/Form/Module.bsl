
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Try
		Items.Customer.Title = GeneralFunctionsReusable.GetCustomerName();
		Items.Vendor.Title = GeneralFunctionsReusable.GetVendorName();
	Except
	EndTry;
	
	Transactions.Parameters.SetParameterValue("Company", Catalogs.Companies.EmptyRef());
EndProcedure

&AtClient
Procedure ContractorsOnActivateRow(Item) 
	//AttachIdleHandler("AttachFilter", 0.2, True);
	AttachFilter();
	CompanyInfoCall();	
	test3 = 3;
EndProcedure

&AtClient 
Procedure AttachFilter() Export
	curCustomer = Items.List.CurrentRow;	
	
	Transactions.Parameters.SetParameterValue("Company", curCustomer);
	
EndProcedure

&AtServer
Procedure CompanyInfoCall()
	
	Company = Items.List.CurrentRow;
	test3 = 3;
	
EndProcedure
