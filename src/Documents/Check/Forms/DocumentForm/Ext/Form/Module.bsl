
&AtClient
Procedure BankAccountOnChange(Item)
	
	Items.BankAccountLabel.Title =
		CommonUse.GetAttributeValue(Object.BankAccount, "Description");

	Object.Number = GeneralFunctions.NextCheckNumber(Object.BankAccount);	
	
	AccountCurrency = CommonUse.GetAttributeValue(Object.BankAccount, "Currency");
	Object.ExchangeRate = GeneralFunctions.GetExchangeRate(Object.Date, AccountCurrency);
	
	Items.ExchangeRate.Title = GeneralFunctionsReusable.DefaultCurrencySymbol() + "/1" + CommonUse.GetAttributeValue(AccountCurrency, "Symbol");
	
	//Items.ExchangeRate.Title = GeneralFunctionsReusable.DefaultCurrencySymbol() + "/1" + CommonUse.GetAttributeValue(Object.Currency, "Symbol");
	Items.FCYCurrency.Title = CommonUse.GetAttributeValue(AccountCurrency, "Symbol");
    Items.RCCurrency.Title = GeneralFunctionsReusable.DefaultCurrencySymbol(); 
	
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	//Title = "Check " + Object.Number + " " + Format(Object.Date, "DLF=D");
		
	If Object.DontCreate Then
		Cancel = True;
		Return;
	EndIf;
	
	If NOT Object.ParentDocument = Undefined Then
		Items.LineItems.ReadOnly = True;
	EndIf;
	
	If Object.BankAccount.IsEmpty() Then
		Object.BankAccount = Constants.BankAccount.Get();
		AccountCurrency = CommonUse.GetAttributeValue(Object.BankAccount, "Currency");
		Object.ExchangeRate = GeneralFunctions.GetExchangeRate(Object.Date, AccountCurrency);
	Else
	EndIf; 
	
	If Object.Ref.IsEmpty() Then
		Object.Number = GeneralFunctions.NextCheckNumber(Object.BankAccount);
	EndIf;
	
	Items.BankAccountLabel.Title =
		CommonUse.GetAttributeValue(Object.BankAccount, "Description");
		
	AccountCurrency = CommonUse.GetAttributeValue(Object.BankAccount, "Currency");
	Items.ExchangeRate.Title = GeneralFunctionsReusable.DefaultCurrencySymbol() + "/1" + CommonUse.GetAttributeValue(AccountCurrency, "Symbol");

	Items.FCYCurrency.Title = CommonUse.GetAttributeValue(AccountCurrency, "Symbol");
    Items.RCCurrency.Title = GeneralFunctionsReusable.DefaultCurrencySymbol();
	
	If NOT GeneralFunctionsReusable.FunctionalOptionValue("MultiCurrency") Then
		Items.FCYGroup.Visible = False;
	EndIf;

	// AdditionalReportsAndDataProcessors
	AdditionalReportsAndDataProcessors.OnCreateAtServer(ThisForm);
	// End AdditionalReportsAndDataProcessors
	
EndProcedure

&AtClient
Procedure LineItemsAmountOnChange(Item)
	
	Object.DocumentTotal = Object.LineItems.Total("Amount");
	Object.DocumentTotalRC = Object.LineItems.Total("Amount") * Object.ExchangeRate;
	
EndProcedure

&AtClient
Procedure LineItemsAfterDeleteRow(Item)
	
	Object.DocumentTotal = Object.LineItems.Total("Amount");
	Object.DocumentTotalRC = Object.LineItems.Total("Amount") * Object.ExchangeRate;
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	NoOfRows = Object.LineItems.Count();
	
	If NoOfRows = 0 AND Object.ParentDocument = Undefined Then
		
		Cancel = True;
		Message = New UserMessage();
		Message.Text=NStr("en='Enter at least one account and amount in the line items';de='Geben Sie mindestens ein Konto und einen Betrag in der Zeile'");
		Message.Field = "Object.LineItems";
		Message.Message();

	EndIf;
	
	If Object.DocumentTotal < 0 Then
		Cancel = True;
		Message = New UserMessage();
		Message.Text=NStr("en='Check amount needs to be greater or equal to zero'");
		Message.Message();
		Return;
	EndIf;

	
	// Checking for duplicate check numbers and disables saving of a check
	// with a duplicate number for the same bank account
	
	//Query = New Query("SELECT
	//				  |	Check.Number AS Number
	//				  |FROM
	//				  |	Document.Check AS Check
	//				  |WHERE
	//				  |	Check.BankAccount = &BankAccount
	//				  |	AND Check.Number = &Number
	//				  |
	//				  |ORDER BY
	//				  |	Number DESC");
	//Query.SetParameter("BankAccount", Object.BankAccount);
	//Query.SetParameter("Number", Object.Number);
	//QueryResult = Query.Execute();
	//
	//If QueryResult.IsEmpty() Then				
	//Else
	//	
	//	Cancel = True;
	//	Message = New UserMessage();
	//	Message.Text=NStr("en='Check number already exists'");
	//	Message.Field = "Object.Number";
	//	Message.Message();
	//	
	//EndIf;
	
EndProcedure

&AtClient
Procedure LineItemsAccountOnChange(Item)
	
	TabularPartRow = Items.LineItems.CurrentData;
	TabularPartRow.AccountDescription = CommonUse.GetAttributeValue
		(TabularPartRow.Account, "Description");

EndProcedure

&AtClient
Procedure DateOnChange(Item)
	
	AccountCurrency = CommonUse.GetAttributeValue(Object.BankAccount, "Currency");
    Object.ExchangeRate = GeneralFunctions.GetExchangeRate(Object.Date, AccountCurrency);

EndProcedure

&AtClient
Procedure CompanyOnChange(Item)
	
	Object.CompanyCode = CommonUse.GetAttributeValue(Object.Company, "Code");
	
EndProcedure
