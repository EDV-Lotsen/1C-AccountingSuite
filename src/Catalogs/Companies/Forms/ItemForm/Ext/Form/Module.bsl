
&AtServer
// Prefills default currency, default accounts, controls field visibility
// 
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
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
	
	If Object.Vendor = True Then
		Items.Group1099.Visible = True;
	Else
		Items.Group1099.Visible = False;
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
	
	Items.FormRegisterCard.Enabled = IsBlankString(Object.StripeToken);
	Items.FormDeleteCard.Enabled   = Not IsBlankString(Object.StripeID);
	//Items.FormRegisterCustomer.Enabled = IsBlankString(Object.StripeID) And Not IsBlankString(Object.StripeToken);
	
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
Procedure DeleteCard(Command)
	
	// Check element saved.
	If Object.Ref.IsEmpty() Or Modified Then
		// Save the customer first.
		ShowMessageBox(Undefined, NStr("en = 'Current item is not saved.
		                                     |Save customer first.'"));
	Else
		// Request Stripe to delete card.
		ResultDescription = DeleteCardAtServer();
		ShowMessageBox(Undefined, ResultDescription);
	EndIf;
	
EndProcedure

&AtServer
Function DeleteCardAtServer()
	var deleted, id, code;
	
	// Request Stripe to delete cuctomer (and it's card) from Stripe API.
	RequestResult = ApiStripeRequestorInterface.DeleteCustomer(Object.StripeID);
	RequestResultObj = RequestResult.Result;
	If  (RequestResultObj <> Undefined)
	And (TypeOf(RequestResultObj) = Type("Structure"))
	And (RequestResultObj.Property("id", id) And id = Object.StripeID)
	And (RequestResultObj.Property("deleted", deleted) And deleted = True)
	Then
		// Requested object deleted as expected.
		Object.StripeToken = "";
		Object.StripeID    = "";
		Object.last4       = "";
		Object.exp_month   = 0;
		Object.exp_year    = 0;
		Object.type        = "";
		
		// Create user message.
		ResultDescription  = NStr("en = 'Customer card successfully deleted.'");
		
	ElsIf (RequestResultObj = Undefined)
	  And (RequestResult.AdditionalData.Property("Code", code) And code = 404) // Not found
	Then
		// Requested object already deleted.
		Object.StripeToken = "";
		Object.StripeID    = "";
		Object.last4       = "";
		Object.exp_month   = 0;
		Object.exp_year    = 0;
		Object.type        = "";
		
		// Create user message.
		ResultDescription  = NStr("en = 'Customer card already deleted in Stripe.'");
	Else
		
		// Create user message.
		ResultDescription  = RequestResult.Description;
	EndIf;
	
	// Update elements presentation.
	Items.FormRegisterCard.Enabled = IsBlankString(Object.StripeToken);
	Items.FormDeleteCard.Enabled   = Not IsBlankString(Object.StripeID);
	
	// Return user message.
	Return ResultDescription;
	
EndFunction

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
	
	If Object.Vendor = True Then
		Items.Group1099.Visible = True;
	Else
		Items.Group1099.Visible = False;
	EndIf;
	
EndProcedure

