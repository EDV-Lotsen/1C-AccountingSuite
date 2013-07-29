
&AtClient
Procedure BankAccountOnChange(Item)
	
	// test
	
	Items.BankAccountLabel.Title =
		CommonUse.GetAttributeValue(Object.BankAccount, "Description");

	//Object.Number = GeneralFunctions.NextCheckNumber(Object.BankAccount);	
	
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
	
	Items.Company.Title = GeneralFunctionsReusable.GetVendorName();
	
	If Object.DontCreate Then
		Cancel = True;
		Return;
	EndIf;
		
	If Object.BankAccount.IsEmpty() Then
		Object.BankAccount = Constants.BankAccount.Get();
		AccountCurrency = CommonUse.GetAttributeValue(Object.BankAccount, "Currency");
		Object.ExchangeRate = GeneralFunctions.GetExchangeRate(Object.Date, AccountCurrency);
	Else
	EndIf; 
	
	//If Object.Ref.IsEmpty() Then
	//	Object.Number = GeneralFunctions.NextCheckNumber(Object.BankAccount);
	//EndIf;
	
	Items.BankAccountLabel.Title =
		CommonUse.GetAttributeValue(Object.BankAccount, "Description");
		
	//AccountCurrency = CommonUse.GetAttributeValue(Object.BankAccount, "Currency");
	//Items.ExchangeRate.Title = GeneralFunctionsReusable.DefaultCurrencySymbol() + "/1" + CommonUse.GetAttributeValue(AccountCurrency, "Symbol");

	//Items.FCYCurrency.Title = CommonUse.GetAttributeValue(AccountCurrency, "Symbol");
    //Items.RCCurrency.Title = GeneralFunctionsReusable.DefaultCurrencySymbol();
	
	If NOT GeneralFunctionsReusable.FunctionalOptionValue("MultiCurrency") Then
		Items.FCYCurrency.Visible = False;
	EndIf;
	
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
	
	If NOT Object.Ref.IsEmpty() AND Object.PaymentMethod = CheckPaymentMethod() Then
	
	Try
		If Number(Object.Number) <= 0 OR Number(Object.Number) >= 100000 Then
			Cancel = True;
			Message = New UserMessage();
			Message.Text=NStr("en='Enter a check number from 0 to 9999 (99999)'");
			Message.Field = "Object.Number";
			Message.Message();
		EndIf;
	Except
			Cancel = True;
			Message = New UserMessage();
			Message.Text=NStr("en='Enter a check number from 0 to 9999 (99999)'");
			Message.Field = "Object.Number";
			Message.Message();
	EndTry;	
		
	Endif;
	
	NoOfRows = Object.LineItems.Count();
	
	If NoOfRows = 0 Then
		
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
	
	//test = Object.Number;
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

&AtClient
Procedure LineItemsOnChange(Item)
	
	If NewRow = true Then
		CurrentData = Item.CurrentData;
		CurrentData.Project = Object.Project;
		NewRow = false;
	Endif;

	
	// Fill new row
	 If LineItems_OnAddRow Then
	  // Clear used flag
	  LineItems_OnAddRow = False;
	  
	  // Fill row data with default values
	  CurrentData = Item.CurrentData;
	  ExpenseAccount = GetExpenseAccount(Object.Company);
	  CurrentData.Account = ExpenseAccount;
	  CurrentData.AccountDescription = CommonUse.GetAttributeValue(ExpenseAccount, "Description");
	  
	EndIf;

EndProcedure

&AtServer
Function GetExpenseAccount(Vendor)
	
	Return Vendor.ExpenseAccount;
	
EndFunction

&AtClient
Procedure LineItemsBeforeAddRow(Item, Cancel, Clone, Parent, Folder)
	
	NewRow = true;
	// Set Add Row flag
	 If Not Cancel Then
	  LineItems_OnAddRow = True;
  	EndIf;
  
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	
	If Object.PaymentMethod = Catalogs.PaymentMethods.Check Then
		
		If CurrentObject.Ref.IsEmpty() Then
		
			LastNumber = GeneralFunctions.LastCheckNumber(Object.BankAccount);
			
			LastNumberString = "";
			If LastNumber < 10000 Then
				LastNumberString = Left(String(LastNumber+1),1) + Right(String(LastNumber+1),3)
			Else
				LastNumberString = Left(String(LastNumber+1),2) + Right(String(LastNumber+1),3)
			EndIf;
			
			CurrentObject.Number = LastNumberString;
			CurrentObject.PhysicalCheckNum = LastNumber + 1;
			
		Else
			CurrentObject.PhysicalCheckNum = Number(CurrentObject.Number);		
		EndIf;
	Endif;

EndProcedure

&AtClient
Procedure PaymentMethodOnChange(Item)
	If Object.PaymentMethod = CheckPaymentMethod() Then
		Object.Number = "auto";
		Items.Number.ReadOnly = True;
	Else
		Object.Number = "";
		Items.Number.ReadOnly = False;
	EndIf;
EndProcedure

&AtServer
Function CheckPaymentMethod()
	
	Return Catalogs.PaymentMethods.Check;
	
EndFunction
