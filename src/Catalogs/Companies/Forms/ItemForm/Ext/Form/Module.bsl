
&AtServer
// Prefills default currency, default accounts, controls field visibility
// 
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Items.Customer.Title = GeneralFunctionsReusable.GetCustomerName();
	Items.Vendor.Title = GeneralFunctionsReusable.GetVendorName();
	
	If Object.DefaultCurrency.IsEmpty() Then
		Object.DefaultCurrency = Constants.DefaultCurrency.Get();
	EndIf;
	
	If Object.ExpenseAccount.IsEmpty() Then
		ExpenseAccount = Constants.ExpenseAccount.Get(); 
		Object.ExpenseAccount = ExpenseAccount;
		Items.ExpenseAcctLabel.Title = ExpenseAccount.Description;
	Else
		Items.ExpenseAcctLabel.Title = Object.ExpenseAccount.Description;
	EndIf;
	
	If Object.IncomeAccount.IsEmpty() Then
		IncomeAccount = Constants.IncomeAccount.Get();
		Object.IncomeAccount = IncomeAccount;
		Items.IncomeAcctLabel.Title = IncomeAccount.Description;
	Else
		Items.IncomeAcctLabel.Title = Object.IncomeAccount.Description;
	EndIf;
	
	If Object.Customer = False Then
		Items.IncomeAccount.ReadOnly = True;
	EndIf;
	
	If Object.Vendor = False Then
		Items.ExpenseAccount.ReadOnly = True;
	EndIf;
	
	If Object.Ref = Catalogs.Companies.OurCompany Then
		Items.Vendor1099.Visible = False;
		Items.DefaultCurrency.Visible = False;
		Items.SalesTaxCode.Visible = False;
		Items.Bank.Visible = False;
		Items.ExpenseAccount.Visible = False;
		Items.ExpenseAcctLabel.Visible = False;
		Items.IncomeAccount.Visible = False;
		Items.IncomeAcctLabel.Visible = False;
		Items.Group2.ReadOnly = True;
	EndIf;
	
EndProcedure

&AtClient
// Sets accounts visibility
//
Procedure VendorOnChange(Item)
	
	If Object.Vendor Then
		Items.ExpenseAccount.ReadOnly = False;
		Items.Bank.ReadOnly = False;
	Else
		Items.ExpenseAccount.ReadOnly = True;
		Items.Bank.ReadOnly = True;
	EndIf;
	
EndProcedure

&AtClient
// Sets accounts visibility
//
Procedure CustomerOnChange(Item)
	
	If Object.Customer Then
		Items.IncomeAccount.ReadOnly = False;
	Else
		Items.IncomeAccount.ReadOnly = True;
	EndIf;

EndProcedure

&AtClient
// Determines the account's description
//
Procedure ExpenseAccountOnChange(Item)
	
	Items.ExpenseAcctLabel.Title =
		GeneralFunctions.GetAttributeValue(Object.ExpenseAccount, "Description");
		
EndProcedure

&AtClient
// Determines the account's description
//
Procedure IncomeAccountOnChange(Item)
	
	Items.IncomeAcctLabel.Title =
		GeneralFunctions.GetAttributeValue(Object.IncomeAccount, "Description");
		
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

EndProcedure
