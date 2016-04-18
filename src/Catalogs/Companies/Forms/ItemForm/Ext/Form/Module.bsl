
&AtServer
// Prefills default currency, default accounts, controls field visibility
// 
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	//--//
	If Object.Ref.IsEmpty() Then
		FirstNumber = Object.Code;
	EndIf;
	//--//
	
	VendorOnChangeItemsVisibilityAtServer();
	CustomerOnChangeItemsVisibilityAtServer();
	ApplyTaxAttributesPresentation(ThisForm);
	
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
		
	If Object.Customer Then
		Items.Customer.Enabled = False;
	EndIf;
	
	If Object.Vendor Then
		Items.Vendor.Enabled = False;
	EndIf;
	
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
		
		Message = New UserMessage();
		Message.Text=NStr("en='Select if the company is a customer, vendor, or both'");
		//Message.Field = "Object.Customer";
		Message.Message();
		Cancel = True;
		Return;
	
	EndIf;
	
	If GeneralFunctionsReusable.FunctionalOptionValue("SalesTaxCharging") And Object.Customer Then
		If Not ValueIsFilled(Object.SalesTaxRate) Then
			Message = New UserMessage();
			Message.Text=NStr("en='Please, assign the default tax rate'");
			Message.Field = "Object.SalesTaxRate";
			Message.Message();
			Cancel = True;
		EndIf;
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
		AddressLine.Owner           = Object.Ref;
		AddressLine.Description     = "Primary";
		AddressLine.DefaultShipping = True;
		AddressLine.DefaultBilling  = True;
		AddressLine.DefaultRemitTo  = True;
		AddressLine.Write();
	EndIf;
		
	// Update visibility of flags
	Items.Customer.Enabled = Not Object.Customer;
	Items.Vendor.Enabled = Not Object.Vendor;
	
EndProcedure

&AtServer
Procedure LoadAddrPage()
	
	MainAddr = Catalogs.Addresses.FindByDescription("Primary",,,Object.Ref);
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
		Object.Taxable = True;
	Else
		Object.Taxable = False;
	EndIf;
	
EndProcedure

&AtServer
Procedure CustomerOnChangeItemsVisibilityAtServer()
	
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
	
	Object = ThisForm.Object;
	Items  = ThisForm.Items;
		
	If Object.Taxable = True Then
		Items.SalesTaxRate.Enabled = True;
	Else
		Items.SalesTaxRate.Enabled = False;
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
Procedure DescriptionOnChange(Item)
	
	If (ValueIsFilled(Object.FullName)) And (Object.FullName <> Object.Description) And (Object.Vendor) Then
		
		ProcessingParameters = New NotifyDescription("AnswerProcessing", ThisObject);
		QuestionText         = StringFunctionsClientServer.SubstituteParametersInString(
		                       NStr("en = 'Would you like to change full name of company from ""%1"" to ""%2""?'"), Object.FullName, Object.Description);
		
		ShowQueryBox(ProcessingParameters, QuestionText, QuestionDialogMode.YesNo,,,);
		
	Else
		Object.FullName = Object.Description;
	EndIf;
	
EndProcedure

&AtClient
Procedure AnswerProcessing(ChoiceResult, ProcessingParameters) Export
	
	If ChoiceResult = DialogReturnCode.Yes Then
		Object.FullName = Object.Description;
	EndIf;
	
EndProcedure


