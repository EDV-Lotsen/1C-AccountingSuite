
&AtServer
// Prefills default currency, default accounts, controls field visibility
// 
Procedure OnCreateAtServer(Cancel, StandardProcessing)
		
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
	
	If Object.ExpenseAccount.IsEmpty() Then
		Try
			ExpenseAccount = Constants.ExpenseAccount.Get(); 
			Object.ExpenseAccount = ExpenseAccount;
			Items.ExpenseAcctLabel.Title = ExpenseAccount.Description;
		Except
		EndTry;
	Else
		Try
			Items.ExpenseAcctLabel.Title = Object.ExpenseAccount.Description;
		Except
		EndTry;
	EndIf;
	
	If Object.IncomeAccount.IsEmpty() Then
		Try
			IncomeAccount = Constants.IncomeAccount.Get();
			Object.IncomeAccount = IncomeAccount;
			Items.IncomeAcctLabel.Title = IncomeAccount.Description;
		Except
		EndTry;
	Else
		Try
			Items.IncomeAcctLabel.Title = Object.IncomeAccount.Description;
		Except
		EndTry;
	EndIf;
	
	If Object.Customer = False Then
		//Items.IncomeAccount.ReadOnly = True;
	Else
		Items.Customer.Enabled = False;
	EndIf;
	
	If Object.Vendor = False Then
		//Items.ExpenseAccount.ReadOnly = True;
	Else
		Items.Vendor.Enabled = False;
	EndIf;
	
	If Object.Ref = Catalogs.Companies.OurCompany Then
		Items.Vendor1099.Visible = False;
		Items.DefaultCurrency.Visible = False;
		Items.SalesTaxCode.Visible = False;
		Items.ExpenseAccount.Visible = False;
		Items.ExpenseAcctLabel.Visible = False;
		Items.IncomeAccount.Visible = False;
		Items.IncomeAcctLabel.Visible = False;
		Items.Group2.ReadOnly = True;
		Items.Terms.Visible = False;
	EndIf;
	
	// AdditionalReportsAndDataProcessors
	AdditionalReportsAndDataProcessors.OnCreateAtServer(ThisForm);
	// End AdditionalReportsAndDataProcessors
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	// Update form presentation
	VendorOnChange(Items.Vendor);
	CustomerOnChange(Items.Customer);
EndProcedure

&AtClient
// Sets accounts visibility
//
Procedure VendorOnChange(Item)
	
	If Object.Vendor AND Object.Ref.IsEmpty() Then
		//Items.ExpenseAccount.ReadOnly = False;
	Else
		//Items.ExpenseAccount.ReadOnly = True;
	EndIf;
	
EndProcedure

&AtClient
// Sets accounts visibility
//
Procedure CustomerOnChange(Item)
	
	If Object.Customer AND Object.Ref.IsEmpty() Then
		//Items.IncomeAccount.ReadOnly = False;
	Else
		//Items.IncomeAccount.ReadOnly = True;
	EndIf;

EndProcedure

&AtClient
// Determines the account's description
//
Procedure ExpenseAccountOnChange(Item)
	
	Items.ExpenseAcctLabel.Title =
		CommonUse.GetAttributeValue(Object.ExpenseAccount, "Description");
		
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
		
	If Object.Vendor = False AND Object.Customer = False AND
		NOT Object.Ref = GeneralFunctions.GetOurCompany() Then
		
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
	
EndProcedure
