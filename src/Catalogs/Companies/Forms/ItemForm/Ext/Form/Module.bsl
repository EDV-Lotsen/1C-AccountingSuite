﻿
&AtServer
// Prefills default currency, default accounts, controls field visibility
// 
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	                            
	LoadAddrPage();
	If Object.Ref.IsEmpty() Then
		   ProjectTable.Parameters.SetParameterValue("Ref", "");
	Else
	ProjectTable.Parameters.SetParameterValue("Ref", Object.Ref);
	Endif;

		
	Try
		Items.Customer.Title = GeneralFunctionsReusable.GetCustomerName();
		Items.Vendor.Title = GeneralFunctionsReusable.GetVendorName();
	Except
	EndTry;
	                       
	If Object.Terms.IsEmpty() Then
		Try
			Object.Terms = Catalogs.PaymentTerms.Net30;
		Except
		EndTry;
	EndIf;
	
	If Object.DefaultCurrency.IsEmpty() Then
		Try
			Object.DefaultCurrency = Constants.DefaultCurrency.Get();
		Except
		EndTry;
	EndIf;
	
	Items.IncomeAcctLabel.Title = Object.IncomeAccount.Description;
	Items.ExpenseAcctLabel.Title = Object.ExpenseAccount.Description;
	Items.APAcctLabel.Title = Object.APAccount.Description;
	Items.ARAcctLabel.Title = Object.ARAccount.Description;
	
	If Object.Customer = False Then
		//Items.IncomeAccount.ReadOnly = True;
		//Items.CatalogProjectsOpenByValue.Visible = False;
	Else
		//Items.CatalogProjectsOpenByValue.Visible = True;
		Items.Customer.Enabled = False;
	EndIf;
	
	If Object.Vendor = False Then
		//Items.ExpenseAccount.ReadOnly = True;
	Else
		Items.Vendor.Enabled = False;
	EndIf;
	
	//If Object.Ref = Catalogs.Companies.OurCompany Then
	//	Items.Vendor1099.Visible = False;
	//	Items.DefaultCurrency.Visible = False;
	//	Items.SalesTaxCode.Visible = False;
	//	Items.ExpenseAccount.Visible = False;
	//	Items.ExpenseAcctLabel.Visible = False;
	//	Items.IncomeAccount.Visible = False;
	//	Items.IncomeAcctLabel.Visible = False;
	//	Items.Group2.ReadOnly = True;
	//	Items.Terms.Visible = False;
	//EndIf;
	
	//Items.FormRegisterCard.Enabled = IsBlankString(Object.StripeToken);
	//Items.FormDeleteCard.Enabled   = Not IsBlankString(Object.StripeID);
	//Items.FormRegisterCustomer.Enabled = IsBlankString(Object.StripeID) And Not IsBlankString(Object.StripeToken);
	
EndProcedure

&AtClient
// Determines the account's description
//
Procedure ExpenseAccountOnChange(Item)
	
	Items.ExpenseAcctLabel.Title = CommonUse.GetAttributeValue(Object.ExpenseAccount, "Description");
		
EndProcedure

&AtClient
// Determines the account's description
//
Procedure IncomeAccountOnChange(Item)
	
	Items.IncomeAcctLabel.Title =
		CommonUse.GetAttributeValue(Object.IncomeAccount, "Description");
		
	EndProcedure

&AtServer
// Checks if the user indicated if the company is a customer, vendor, or both.
//
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
		
	If Object.Vendor = False AND Object.Customer = False Then
		
		// AND NOT Object.Ref = GeneralFunctions.GetOurCompany()
		
		Message = New UserMessage();
		Message.Text=NStr("en='Select if the company is a customer, vendor, or both'");
		Message.Field = "Object.Customer";
		Message.Message();
		Cancel = True;
		Return;
	
	EndIf;
	
	If NOT Object.Ref.IsEmpty() Then 
		
		DefaultShippingSet = False;
		DefaultShippingQty = 0;
		DefaultBillingSet = False;
		DefaultBillingQty = 0;
		
		Query = New Query("SELECT
		                  |	Addresses.DefaultBilling,
		                  |	Addresses.DefaultShipping
		                  |FROM
		                  |	Catalog.Addresses AS Addresses
		                  |WHERE
		                  |	Addresses.Owner = &Ref");	
		Query.SetParameter("Ref", Object.Ref);
		QueryResult = Query.Execute();
		If QueryResult.IsEmpty() Then		
		Else
			Selection = QueryResult.Choose();
			While Selection.Next() Do
				
				If Selection.DefaultShipping = True
					Then DefaultShippingSet = True;
					DefaultShippingQty = DefaultShippingQty + 1;
				EndIf;
				
				If Selection.DefaultBilling = True
					Then DefaultBillingSet = True;
					DefaultBillingQty = DefaultBillingQty + 1;
				EndIf;
				
			EndDo;						
		EndIf;
		
		If DefaultShippingSet = False OR DefaultBillingSet = False OR DefaultShippingQty > 1 OR DefaultBillingQty > 1 Then
			
			Message = New UserMessage();
			Message.Text=NStr("en='Set one default shipping and one default billing address'");
			Message.Field = "Object.Addresses";
			Message.Message();
			Cancel = True;
			Return;
		
		EndIf;
		
	EndIf;
	

EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	Query = New Query("SELECT
	                  |	Addresses.Ref
	                  |FROM
	                  |	Catalog.Addresses AS Addresses
	                  |WHERE
	                  |	Addresses.Owner = &Ref");
	
	Query.SetParameter("Ref", Object.Ref);
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		AddressLine = Catalogs.Addresses.CreateItem();
		AddressLine.Owner = Object.Ref;
		AddressLine.Description = "Primary";
		AddressLine.DefaultShipping = True;
		AddressLine.DefaultBilling = True;
		AddressLine.Write();		
	EndIf;
	
	// Update visibility of flags
	Items.Customer.Enabled = Not Object.Customer;
	Items.Vendor.Enabled = Not Object.Vendor;
	
	MainAddr = Catalogs.Addresses.FindByDescription("Primary",,,Object.Ref);
	//MainAddr = Catalogs.Addresses.FindByCode("00001",,,Object.Ref);
	MainObj = MainAddr.GetObject();
	MainObj.Email = PrimaryAddr.Email;
	MainObj.AddressLine1 = PrimaryAddr.AddressLine1;
	MainObj.AddressLine2 = PrimaryAddr.AddressLine2;
	MainObj.Phone = PrimaryAddr.Phone;
	MainObj.City = PrimaryAddr.City;
	MainObj.State = PrimaryAddr.State;
	MainObj.Country = PrimaryAddr.Country;
	MainObj.ZIP = PrimaryAddr.ZIP;
	MainObj.Write();

	
EndProcedure

&AtClient
Procedure ARAccountOnChange(Item)
	
	Items.ARAcctLabel.Title =
		CommonUse.GetAttributeValue(Object.ARAccount, "Description");
		
EndProcedure

&AtClient
Procedure APAccountOnChange(Item)
	
	Items.APAcctLabel.Title =
		CommonUse.GetAttributeValue(Object.APAccount, "Description");
		
EndProcedure

&AtClient
Procedure SalesTransactions(Command)
	
	// setting composer values
	// fixed filter 
	CompanyFilter = Новый Структура("Company", Object.Ref);
	FormParameters = Новый Структура("Отбор, СформироватьПриОткрытии, КомпоновщикНастроекПользовательскиеНастройки.Видимость",CompanyFilter,True,False);
	OpenForm("Report.SalesTransactionDetail.ObjectForm",FormParameters,,,,,,FormWindowOpeningMode.LockWholeInterface);
EndProcedure


&AtClient
Procedure Projects(Command)
	FormParameters = New Structure();
	
	FltrParameters = New Structure();
	FltrParameters.Insert("Customer", Object.Ref);
	FormParameters.Insert("Filter", FltrParameters);
	OpenForm("Catalog.Projects.ListForm",FormParameters, Object.Ref);
EndProcedure

&AtServer
Procedure LoadAddrPage()
	
	MainAddr = Catalogs.Addresses.FindByDescription("Primary",,,Object.Ref);
	//MainAddr = Catalogs.Addresses.FindByCode("00001",,,Object.Ref);
	PrimaryAddr.Email = MainAddr.Email;
	PrimaryAddr.Phone = MainAddr.Phone;
	PrimaryAddr.AddressLine1 = MainAddr.AddressLine1;
	PrimaryAddr.AddressLine2 = MainAddr.AddressLine2;
	PrimaryAddr.City = MainAddr.City;
	PrimaryAddr.State = MainAddr.State;
	PrimaryAddr.Country = MainAddr.Country;
	PrimaryAddr.Zip = MainAddr.ZIP;
EndProcedure

