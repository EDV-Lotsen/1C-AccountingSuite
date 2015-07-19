﻿
&AtServer
// Prefills default currency, default accounts, controls field visibility
// 
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	//--//
	If Object.Ref.IsEmpty() Then
		FirstNumber = Object.Code;
	EndIf;
	//--//
	
	//If Constants.SalesTaxCharging.Get() = True AND Object.Customer = True Then
	//	Items.TaxTab.Visible = True;
	//Else
	//	Items.TaxTab.Visible = False;
	//EndIf;
	VendorOnChangeItemsVisibilityAtServer();
	CustomerOnChangeItemsVisibilityAtServer();
	ApplyTaxAttributesPresentation(ThisForm);
	
	If GeneralFunctionsReusable.DisplayAPICodesSetting() = False Then
		Items.api_code.Visible = False;
	EndIf;
	
	If NOT Object.Ref.IsEmpty() Then
		api_code = String(Object.Ref.UUID());
	EndIf;
	
	// custom fields
	
	CF1Type = Constants.CF1CType.Get();
	CF2Type = Constants.CF2CType.Get();
	CF3Type = Constants.CF3CType.Get();
	CF4Type = Constants.CF4CType.Get();
	CF5Type = Constants.CF5CType.Get();
	
	If CF1Type = "None" Then
		Items.CF1Num.Visible = False;
		Items.CF1String.Visible = False;
	ElsIf CF1Type = "Number" Then
		Items.CF1Num.Visible = True;
		Items.CF1String.Visible = False;
		Items.CF1Num.Title = Constants.CF1CName.Get();
	ElsIf CF1Type = "String" Then
	    Items.CF1Num.Visible = False;
		Items.CF1String.Visible = True;
		Items.CF1String.Title = Constants.CF1CName.Get();
	ElsIf CF1Type = "" Then
		Items.CF1Num.Visible = False;
		Items.CF1String.Visible = False;
	EndIf;
	
	If CF2Type = "None" Then
		Items.CF2Num.Visible = False;
		Items.CF2String.Visible = False;
	ElsIf CF2Type = "Number" Then
		Items.CF2Num.Visible = True;
		Items.CF2String.Visible = False;
		Items.CF2Num.Title = Constants.CF2CName.Get();
	ElsIf CF2Type = "String" Then
	    Items.CF2Num.Visible = False;
		Items.CF2String.Visible = True;
		Items.CF2String.Title = Constants.CF2CName.Get();
	ElsIf CF2Type = "" Then
		Items.CF2Num.Visible = False;
		Items.CF2String.Visible = False;
	EndIf;
	
	If CF3Type = "None" Then
		Items.CF3Num.Visible = False;
		Items.CF3String.Visible = False;
	ElsIf CF3Type = "Number" Then
		Items.CF3Num.Visible = True;
		Items.CF3String.Visible = False;
		Items.CF3Num.Title = Constants.CF3CName.Get();
	ElsIf CF3Type = "String" Then
	    Items.CF3Num.Visible = False;
		Items.CF3String.Visible = True;
		Items.CF3String.Title = Constants.CF3CName.Get();
	ElsIf CF3Type = "" Then
		Items.CF3Num.Visible = False;
		Items.CF3String.Visible = False;
	EndIf;
	
	If CF4Type = "None" Then
		Items.CF4Num.Visible = False;
		Items.CF4String.Visible = False;
	ElsIf CF4Type = "Number" Then
		Items.CF4Num.Visible = True;
		Items.CF4String.Visible = False;
		Items.CF4Num.Title = Constants.CF4CName.Get();
	ElsIf CF4Type = "String" Then
	    Items.CF4Num.Visible = False;
		Items.CF4String.Visible = True;
		Items.CF4String.Title = Constants.CF4CName.Get();
	ElsIf CF4Type = "" Then
		Items.CF4Num.Visible = False;
		Items.CF4String.Visible = False;
	EndIf;
	
	If CF5Type = "None" Then
		Items.CF5Num.Visible = False;
		Items.CF5String.Visible = False;
	ElsIf CF5Type = "Number" Then
		Items.CF5Num.Visible = True;
		Items.CF5String.Visible = False;
		Items.CF5Num.Title = Constants.CF5CName.Get();
	ElsIf CF5Type = "String" Then
	    Items.CF5Num.Visible = False;
		Items.CF5String.Visible = True;
		Items.CF5String.Title = Constants.CF5CName.Get();
	ElsIf CF5Type = "" Then
		Items.CF5Num.Visible = False;
		Items.CF5String.Visible = False;
	EndIf;

	// end custom fields

	
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
	
	
	
	//Items.FormRegisterCard.Enabled = IsBlankString(Object.StripeToken);
	//Items.FormDeleteCard.Enabled   = Not IsBlankString(Object.StripeID);
	
	If Object.Ref.IsEmpty() Then
		Transactions.Parameters.SetParameterValue("Company", Catalogs.Companies.EmptyRef());
		Items.GroupTransactions.Visible = False;
	Else
		Transactions.Parameters.SetParameterValue("Company", Object.Ref);
	EndIf;
	
EndProcedure

&AtServer
// Checks if the user indicated if the company is a customer, vendor, or both.
//
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	Query = New Query("SELECT
	                  |	Companies.Ref
	                  |FROM
	                  |	Catalog.Companies AS Companies
	                  |WHERE
	                  |	Companies.Description = &Description");
	Query.SetParameter("Description", Object.Description);
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then		
	Else
		Dataset = QueryResult.Unload();
		If NOT Dataset[0][0] = Object.Ref Then
			Message = New UserMessage();
			Message.Text=NStr("en='Another company is already using this name. Please use a different name.'");
			//Message.Field = "Object.Description";
			Message.Message();
			Cancel = True;
			Return;
		EndIf;
	EndIf;

	
	If Object.Vendor = False AND Object.Customer = False Then
		
		// AND NOT Object.Ref = GeneralFunctions.GetOurCompany()
		
		Message = New UserMessage();
		Message.Text=NStr("en='Select if the company is a customer, vendor, or both'");
		//Message.Field = "Object.Customer";
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
			Selection = QueryResult.Select();
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
			//Message.Field = "Object.Addresses";
			Message.Message();
			Cancel = True;
			Return;
		
		EndIf;
		
	EndIf;
	

EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	//--//
	If FirstNumber <> "" Then
		
		Numerator = Catalogs.DocumentNumbering.Companies.GetObject();
		NextNumber = GeneralFunctions.Increment(Numerator.Number);
		If FirstNumber = NextNumber And NextNumber = Object.Code Then
			Numerator.Number = FirstNumber;
			Numerator.Write();
		EndIf;
		
		FirstNumber = "";
	EndIf;
	//--//
		
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
	
	
	//Query = New Query("SELECT
	//				  |	Addresses.Ref
	//				  |FROM
	//				  |	Catalog.Addresses AS Addresses
	//				  |WHERE
	//				  |	Addresses.Owner = &Ref");
	//
	//Query.SetParameter("Ref", Object.Ref);
	//QueryResult = Query.Execute();
	//If QueryResult.IsEmpty() Then
	//Else
	//	DataSet = QueryResult.Unload();
	//	
	//	//MainAddr = Catalogs.Addresses.FindByDescription("Primary",,,Object.Ref);
	//	MainAddr = DataSet[0][0];
	//	//MainAddr = Catalogs.Addresses.FindByCode("00001",,,Object.Ref);
	//	MainObj = MainAddr.GetObject();
	//	MainObj.FirstName = PrimaryAddr.FirstName;
	//	MainObj.MiddleName = PrimaryAddr.MiddleName;
	//	MainObj.LastName = PrimaryAddr.LastName;
	//	MainObj.Email = PrimaryAddr.Email;
	//	MainObj.AddressLine1 = PrimaryAddr.AddressLine1;
	//	MainObj.AddressLine2 = PrimaryAddr.AddressLine2;
	//	MainObj.Phone = PrimaryAddr.Phone;
	//	MainObj.City = PrimaryAddr.City;
	//	MainObj.State = PrimaryAddr.State;
	//	MainObj.Country = PrimaryAddr.Country;
	//	MainObj.ZIP = PrimaryAddr.ZIP;
	//	MainObj.Write();

	//EndIf;
	
	companies_url = Constants.companies_webhook.Get();
	
	If NOT companies_url = "" Then
		
		WebhookMap = GeneralFunctions.ReturnCompanyObjectMap(Object.Ref);
		WebhookMap.Insert("resource","companies");
		If Object.NewObject = True Then
			WebhookMap.Insert("action","create");
		Else
			WebhookMap.Insert("action","update");
		EndIf;
		WebhookMap.Insert("apisecretkey",Constants.APISecretKey.Get());
		
		WebhookParams = New Array();
		WebhookParams.Add(companies_url);
		WebhookParams.Add(WebhookMap);
		LongActions.ExecuteInBackground("GeneralFunctions.SendWebhook", WebhookParams);
	
	EndIf;
	
	//  create account in zoho 
	If Constants.zoho_auth_token.Get() <> "" AND Object.Customer = True Then
		If Object.NewObject = True Then
			ThisAction = "create";
		Else
			ThisAction = "update";
		EndIf;
		zoho_Functions.zoho_ThisAccount(ThisAction, Object.Ref);
	EndIf;
		
EndProcedure

&AtServer
Function GetAPISecretKey()
	
	//K.Zuzik
	Return Constants.APISecretKey.Get();
	
EndFunction

&AtClient
Procedure RegisterCard(Command)
	
	// Check element saved.
	If Object.Ref.IsEmpty() Or Modified Then
		ShowMessageBox(Undefined, NStr("en = 'Current item is not saved.
                                       |Save customer first.'"));
		Return;
	EndIf;
	
	//K.Zuzik
	statestring = GetAPISecretKey() + Object.Code;
	GotoURL("https://addcard.accountingsuite.com/check?state=" + statestring);
	Close();
	
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
	PrimaryAddr.FirstName = MainAddr.FirstName;
	PrimaryAddr.MiddleName = MainAddr.MiddleName;
	PrimaryAddr.LastName = MainAddr.LastName;
	PrimaryAddr.Email = MainAddr.Email;
	PrimaryAddr.Phone = MainAddr.Phone;
	PrimaryAddr.AddressLine1 = MainAddr.AddressLine1;
	PrimaryAddr.AddressLine2 = MainAddr.AddressLine2;
	PrimaryAddr.City = MainAddr.City;
	PrimaryAddr.State = MainAddr.State;
	PrimaryAddr.Country = MainAddr.Country;
	PrimaryAddr.Zip = MainAddr.ZIP;
EndProcedure


&AtClient
Procedure VendorOnChange(Item)
	
	VendorOnChangeAtServer();
	
EndProcedure

&AtServer
Procedure VendorOnChangeAtServer()
	VendorOnChangeItemsVisibilityAtServer();
EndProcedure

&AtServer
Procedure VendorOnChangeItemsVisibilityAtServer()
	//dedicated procedure for visibility to call on start
	isVendor = Object.Vendor;
	
	Items.ExpenseAccount.Visible = isVendor;
	Items.APAccount.Visible = isVendor;
	Items.Group1099.Visible = isVendor;
	Items.Employee.Visible = isVendor;
	
EndProcedure

&AtClient
Procedure CustomerOnChange(Item)
	CustomerOnChangeAtServer();
EndProcedure


&AtServer
Procedure CustomerOnChangeAtServer()
	
	CustomerOnChangeItemsVisibilityAtServer();
	
	If Object.Customer Then
		If Constants.SalesTaxMarkNewCustomersTaxable.Get() = True Then
			Object.Taxable 		= True;
			Object.SalesTaxRate = Constants.SalesTaxDefault.Get();
		EndIf;
		If GeneralFunctions.FunctionalOptionValue("AvataxEnabled") Then
			Object.UseAvatax 	= True;
		EndIf;
	Else
		Object.Taxable 		= False;
		Object.SalesTaxRate = Catalogs.SalesTaxRates.EmptyRef();
		Object.UseAvatax	= False;
	EndIf;
	ApplyTaxAttributesPresentation(ThisForm);
	
EndProcedure

&AtServer
Procedure CustomerOnChangeItemsVisibilityAtServer()
	//dedicated procedure for visibility to call on start
	If Constants.SalesTaxCharging.Get() = True AND Object.Customer = True Then
		Items.TaxTab.Visible = True;
	Else
		Items.TaxTab.Visible = False;
	EndIf;
	
	isCustomer = Object.Customer;
	
	Items.IncomeAccount.Visible = isCustomer;
	Items.ARAccount.Visible = isCustomer;
	Items.PriceLevel.Visible = isCustomer;
	Items.SalesPerson.Visible = isCustomer;
	//Items.CreditCard.Visible = isCustomer;
	
EndProcedure

&AtClient
Procedure TaxableOnChange(Item)
	
	TaxableOnChangeAtServer();
		
EndProcedure

&AtServer
Procedure TaxableOnChangeAtServer()
	
	If Object.Taxable Then
		Object.SalesTaxRate = Constants.SalesTaxDefault.Get();
	Else
		Object.SalesTaxRate = Catalogs.SalesTaxRates.EmptyRef();
	EndIf;
	
	ApplyTaxAttributesPresentation(ThisForm);
	
EndProcedure

&AtClientAtServerNoContext
Procedure ApplyTaxAttributesPresentation(ThisForm)
	
	Object 	= ThisForm.Object;
	Items	= ThisForm.Items;
		
	If Object.Taxable = True Then
		Items.SalesTaxRate.Enabled = True;
	Else
		Items.SalesTaxRate.Enabled = False;
	EndIf;	
	
	If Object.Taxable Or Object.UseAvatax Then
		Items.ResaleNO.Enabled = True;
	Else
		Items.ResaleNO.Enabled = False;
	EndIf;
	
	If GeneralFunctionsReusable.FunctionalOptionValue("AvataxEnabled") Then
		If Object.UseAvatax Then
			Items.AvataxCustomerUsageType.Enabled 	= True;
			Items.BusinessIdentificationNo.Enabled 	= True;
			Items.Taxable.Enabled		= False;
			Items.SalesTaxRate.Enabled 	= False;
		Else
			Items.AvataxCustomerUsageType.Enabled 	= False;
			Items.BusinessIdentificationNo.Enabled 	= False;
			Items.Taxable.Enabled		= True;
			Items.SalesTaxRate.Enabled 	= True;
		EndIf;
	Else  //Avatax disabled
		Items.VATGroup.Visible 	= False;
		Items.Taxable.Enabled		= True;
		Items.SalesTaxRate.Enabled 	= True;
	EndIf;
	
EndProcedure

&AtClient
Procedure TransactionsSelection(Item, SelectedRow, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	ShowValue(, GetDocumentOfTransaction()); 
	
EndProcedure

&AtServer
Function GetDocumentOfTransaction()
	
	Return Items.Transactions.CurrentRow.Document;	
	
EndFunction

&AtClient
Procedure UseAvataxOnChange(Item)
	
	ApplyTaxAttributesPresentation(ThisForm);
	
EndProcedure
