
&AtClient
Procedure BankAccountOnChange(Item)
	
	//Items.BankAccountLabel.Title =
	//	CommonUse.GetAttributeValue(Object.BankAccount, "Description");

	//Object.Number = GeneralFunctions.NextCheckNumber(Object.BankAccount);	
	
	AccountCurrency = CommonUse.GetAttributeValue(Object.BankAccount, "Currency");
	Object.ExchangeRate = GeneralFunctions.GetExchangeRate(Object.Date, AccountCurrency);
	
	Items.ExchangeRate.Title = GeneralFunctionsReusable.DefaultCurrencySymbol() + "/1" + CommonUse.GetAttributeValue(AccountCurrency, "Symbol");
	
	//Items.ExchangeRate.Title = GeneralFunctionsReusable.DefaultCurrencySymbol() + "/1" + CommonUse.GetAttributeValue(Object.Currency, "Symbol");
	//Items.FCYCurrency.Title = CommonUse.GetAttributeValue(AccountCurrency, "Symbol");
    //Items.RCCurrency.Title = GeneralFunctionsReusable.DefaultCurrencySymbol(); 
	
	CheckCompanyCurrency();
	For Each CurRow in Object.LineItems Do 
		LineItemsAccountOnChangeAtServer(CurRow.Account, Object.LineItems.IndexOf(CurRow)+1);
	EndDo;	
	
	If Object.PaymentMethod = CheckPaymentMethod() Then
		ChoiceProcessing = New NotifyDescription("UpdateBankCheck", ThisForm);
		ShowQueryBox(ChoiceProcessing, "Would you like to load the next check number for this bank account?", QuestionDialogMode.YesNo, 0);
	EndIf;
	
	Object.DocumentTotal = Object.LineItems.Total("Amount");
	Object.DocumentTotalRC = Object.LineItems.Total("Amount") * Object.ExchangeRate;
		
EndProcedure



&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("Company") Then
		Object.Company = Parameters.Company;
	EndIf;
	
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
		
	//Items.BankAccountLabel.Title =
	//	CommonUse.GetAttributeValue(Object.BankAccount, "Description");
		
	//AccountCurrency = CommonUse.GetAttributeValue(Object.BankAccount, "Currency");
	//Items.ExchangeRate.Title = GeneralFunctionsReusable.DefaultCurrencySymbol() + "/1" + CommonUse.GetAttributeValue(AccountCurrency, "Symbol");

	//Items.FCYCurrency.Title = CommonUse.GetAttributeValue(AccountCurrency, "Symbol");
    //Items.RCCurrency.Title = GeneralFunctionsReusable.DefaultCurrencySymbol();
	
	//If NOT GeneralFunctionsReusable.FunctionalOptionValue("MultiCurrency") Then
	//	Items.FCYCurrency.Visible = False;
	//EndIf;
	
	//Disable voiding if document is not posted
	If Object.Ref.Posted = False Then
		Items.FormMarkAsVoid.Enabled = False;
	EndIf;
	
	CheckVoid();
	
	CheckARandAPAccounts();
	
EndProcedure

&AtServer
Procedure CheckVoid()
	
	//Check if there is a voiding entry for this document
	Query = New Query;
	Query.Text = "SELECT
	             |	GeneralJournalEntry.Ref
	             |FROM
	             |	Document.GeneralJournalEntry AS GeneralJournalEntry
	             |WHERE
	             |	GeneralJournalEntry.VoidingEntry = &Ref";
				 
	Query.SetParameter("Ref", Object.Ref);
	QueryResult = Query.Execute().Unload();
	If QueryResult.Count() <> 0 Then
		Items.VoidMessage.Title = "This payment has been voided by";
		VoidingGJ = QueryResult[0].Ref;
		Items.VoidInfo.Visible = True;
		Items.FormMarkAsVoid.Enabled = False;
	Else
		Items.VoidInfo.Visible = False;
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
	
	CheckARandAPAccounts();
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	                        
	If Object.PaymentMethod.IsEmpty() Then
		Cancel = True;
		Message = New UserMessage();
		Message.Text=NStr("en='Select a payment method'");
		Message.Message();
	EndIf;		
	
	If Object.PaymentMethod = CheckPaymentMethod() Then
	
		Try
			If Number(Object.Number) < 0 OR Number(Object.Number) > 100000 Then
				Cancel = True;
				Message = New UserMessage();
				Message.Text=NStr("en='Enter a check number from 0 to 10000'");
				Message.Message();
			EndIf;
		Except
			
			Cancel = True;
			Message = New UserMessage();
			Message.Text=NStr("en='Enter a check number from 0 to 10000'");
			Message.Message();

		EndTry;
		
	Endif;

	
	NoOfRows = Object.LineItems.Count();
	
	If NoOfRows = 0 Then
		
		Cancel = True;
		Message = New UserMessage();
		Message.Text=NStr("en='Enter at least one account and amount in the line items'");
		//Message.Field = "Object.LineItems";
		Message.Message();

	EndIf;
	
	If Object.DocumentTotal < 0 Then
		Cancel = True;
		Message = New UserMessage();
		Message.Text=NStr("en='Check amount needs to be greater or equal to zero'");
		Message.Message();
	EndIf;
	
	If Not Object.Company.IsEmpty() And Object.RemitTo.IsEmpty() Then
		Cancel = True;
		MessageTextTemplate = NStr("en = 'Set ""Remit to"" address for selected %1'");
		Message(StrTemplate(MessageTextTemplate, Items.Company.Title));    
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
Procedure DateOnChange(Item)
	
	AccountCurrency = CommonUse.GetAttributeValue(Object.BankAccount, "Currency");
    Object.ExchangeRate = GeneralFunctions.GetExchangeRate(Object.Date, AccountCurrency);

EndProcedure

&AtClient
Procedure CompanyOnChange(Item)
	
	CompanyOnChangeAtServer();
	
		
EndProcedure

&AtServer
Procedure CompanyOnChangeAtServer()
	
	//Object.CompanyCode = CommonUse.GetAttributeValue(Object.Company, "Code");
	
	UpdateRemitToAddress();
	
	If Not CheckCompanyCurrency() Then 
		Return;
	EndIf;	
	
	ExistPurchaseInvoice();
	
EndProcedure

&AtServer
Function CheckCompanyCurrency()
	
	If (Not Object.Company.DefaultCurrency.IsEmpty()) and (Object.BankAccount.AccountType = Enums.AccountTypes.OtherCurrentLiability and Object.BankAccount.CreditCard) Then 
		If (Object.Company.DefaultCurrency <> Constants.DefaultCurrency.Get()) Then 
			CommonUseClientServer.MessageToUser("Company default currency must be equal to default currency when using Credit card account",,"Object.Company");
			Object.Company = Catalogs.Companies.EmptyRef();
		EndIf;
		Return False;
	ElsIf (Not Object.Company.DefaultCurrency.IsEmpty()) and (Object.Company.DefaultCurrency <> Object.BankAccount.Currency) Then 
		CommonUseClientServer.MessageToUser("Company default currency must be the same as the currency of Bank account",,"Object.Company");
		Object.Company = Catalogs.Companies.EmptyRef(); 	
		Return False;
	EndIf;	
	
	Return True;
	
EndFunction	

&AtServer
Procedure UpdateRemitToAddress()
	
	Query = New Query;
	Query.Text = "
		|SELECT
		|	Addresses.Ref AS Address
		|FROM
		|	Catalog.Addresses AS Addresses
		|WHERE
		|	Addresses.Owner = &Company
		|	AND Addresses.DefaultRemitTo";
	Query.SetParameter("Company", Object.Company);
	
	QuerySelection = Query.Execute().Select();
	If QuerySelection.Next() Then
		Object.RemitTo = QuerySelection.Address;	
	EndIf;
	
EndProcedure

&AtServer
Procedure ExistPurchaseInvoice()
	
	Query = New Query("SELECT
		|	DocumentPurchaseInvoice.Ref,
		|	DocumentPurchaseInvoice.Number,
		|	DocumentPurchaseInvoice.Date,
		|	DocumentPurchaseInvoice.Company,
		//|	DocumentPurchaseInvoice.CompanyCode,
		|	DocumentPurchaseInvoice.DocumentTotal,
		|	DocumentPurchaseInvoice.DocumentTotalRC,
		|	GeneralJournalBalance.AmountBalance * -1 AS BalanceFCY,
		|	GeneralJournalBalance.AmountRCBalance * -1 AS Balance,
		|	DocumentPurchaseInvoice.Memo
		|FROM
		|	Document.PurchaseInvoice AS DocumentPurchaseInvoice
		|		LEFT JOIN AccountingRegister.GeneralJournal.Balance AS GeneralJournalBalance
		|		ON (GeneralJournalBalance.ExtDimension2 = DocumentPurchaseInvoice.Ref)
		|			AND (GeneralJournalBalance.ExtDimension2 REFS Document.PurchaseInvoice)
		|WHERE
		|	DocumentPurchaseInvoice.Company = &Company
		|	AND GeneralJournalBalance.AmountRCBalance * -1 <> 0");
					  
	Query.SetParameter("Company", Object.Company);
	Result = Query.Execute().Unload();

	If Result.Count() > 0 Then

		Message(StringFunctionsClientServer.SubstituteParametersInString(
		NStr("en = 'There are unpaid invoices for %1, if you would like to pay them, use the Invoice Payment (Check) document under Purchases'"), Object.Company));
	Endif;
	
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
	  //CurrentData.AccountDescription = CommonUse.GetAttributeValue(ExpenseAccount, "Description");
	  
  EndIf;
  
  Object.DocumentTotal = Object.LineItems.Total("Amount");
  Object.DocumentTotalRC = Object.LineItems.Total("Amount") * Object.ExchangeRate;

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
	
	//Period closing
	If PeriodClosingServerCall.DocumentPeriodIsClosed(CurrentObject.Ref, CurrentObject.Date) Then
		PermitWrite = PeriodClosingServerCall.DocumentWritePermitted(WriteParameters);
		CurrentObject.AdditionalProperties.Insert("PermitWrite", PermitWrite);	
	EndIf;
	
	If Object.PaymentMethod = Catalogs.PaymentMethods.Check Then
			
		If WriteParameters.AllowCheckNumber = True Then
	
			CurrentObject.PhysicalCheckNum = CurrentObject.Number;
			CurrentObject.AdditionalProperties.Insert("AllowCheckNumber", True);	
			
		Else
			Message("Check number already exists for this bank account");
			Cancel = True;
		EndIf;

	Endif;
	
	CheckARandAPAccounts(Cancel);
	
EndProcedure

&AtClient
Procedure PaymentMethodOnChange(Item)
	
	If Object.PaymentMethod = CheckPaymentMethod() Then
		
		//if existing check has payment method changed
		If Object.Number = ""  AND Object.Ref.IsEmpty() = False Then
			Object.Number = StrReplace(Generalfunctions.LastCheckNumber(object.BankAccount),",","");
		//if a new check has its payment method changed
		Elsif Object.Number = "" And Object.Ref.IsEmpty() Then
			Object.Number = StrReplace(Generalfunctions.LastCheckNumber(object.BankAccount) + 1,",","");
		Else
		EndIf;


	Else
		
	EndIf;
	
EndProcedure

&AtServer
Function CheckPaymentMethod()
	
	Return Catalogs.PaymentMethods.Check;
	
EndFunction

&AtClient
Procedure URLOpen(Command)
	GotoURL(Object.URL);
EndProcedure

&AtClient
Procedure NumberOnChange(Item)
	NumberOnChangeAtServer();
EndProcedure

&AtServer
Procedure NumberOnChangeAtServer()
	
	CheckExist = Documents.Check.FindByNumber(Object.Number);
	If CheckExist <> Documents.Check.EmptyRef() Then
		Message("Check number already exists");
	Endif;
	
EndProcedure

&AtServer
Function GetRippleAddress(Company)
	
	Return Company.RippleAddress;	
	
EndFunction

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	//Closing period
	If PeriodClosingServerCall.DocumentPeriodIsClosed(Object.Ref, Object.Date) Then
		Cancel = Not PeriodClosingServerCall.DocumentWritePermitted(WriteParameters);
		If Cancel Then
			If WriteParameters.Property("PeriodClosingPassword") And WriteParameters.Property("Password") Then
				If WriteParameters.Password = TRUE Then //Writing the document requires a password
					ShowMessageBox(, "Invalid password!",, "Closed period notification");
				EndIf;
			Else
				Notify = New NotifyDescription("ProcessUserResponseOnDocumentPeriodClosed", ThisObject, WriteParameters);
				Password = "";
				OpenForm("CommonForm.ClosedPeriodNotification", New Structure, ThisForm,,,, Notify, FormWindowOpeningMode.LockOwnerWindow);
			EndIf;
			return;
		EndIf;
	EndIf;
	
	//Check number shouldn't be duplicated normally. 
	//Check its uniqueness and if not ask use to allow duplication (if applicable) 
	If Object.PaymentMethod = PredefinedValue("Catalog.PaymentMethods.Check") Then
		CheckNumberResult = CommonUseServerCall.CheckNumberAllowed(Object.Number, Object.Ref, Object.BankAccount);
		If CheckNumberResult.DuplicatesFound Then
			If Not CheckNumberResult.Allow Then
				Cancel = True;
				CommonUseClientServer.MessageToUser("Check number already exists for this bank account", Object, "Object.Number");
			Else
				If WriteParameters.Property("AllowCheckNumber") Then
					If Not WriteParameters.AllowCheckNumber Then
						Cancel = True;
					EndIf;
				Else
					Notify = New NotifyDescription("ProcessUserResponseOnCheckNumberDuplicated", ThisObject, WriteParameters);
					ShowQueryBox(Notify, "Check number already exists for this bank account. Continue?", QuestionDialogMode.YesNo);
					Cancel = True;
				EndIf;
			EndIf;
		Else
			WriteParameters.Insert("AllowCheckNumber", True);
		EndIf;
	EndIf;
	
	// preventing posting if already included in a bank rec
	If ReconciledDocumentsServerCall.DocumentRequiresExcludingFromBankReconciliation(Object, WriteParameters.WriteMode) Then
		Cancel = True;
		CommonUseClient.ShowCustomMessageBox(ThisForm, "Bank reconciliation", "The transaction you are editing has been reconciled. Saving your changes could put you out of balance the next time you try to reconcile. 
		|To modify it you should exclude it from the Bank rec. document.", PredefinedValue("Enum.MessageStatus.Warning"));
	EndIf;    
	
EndProcedure

//Closing period
&AtClient
Procedure ProcessUserResponseOnDocumentPeriodClosed(Result, Parameters) Export
	If (TypeOf(Result) = Type("String")) Then //Inserted password
		Parameters.Insert("PeriodClosingPassword", Result);
		Parameters.Insert("Password", TRUE);
		Write(Parameters);
	ElsIf (TypeOf(Result) = Type("DialogReturnCode")) Then //Yes, No or Cancel
		If Result = DialogReturnCode.Yes Then
			Parameters.Insert("PeriodClosingPassword", "Yes");
			Parameters.Insert("Password", FALSE);
			Write(Parameters);
		EndIf;
	EndIf;	
EndProcedure

&AtClient
Procedure ProcessUserResponseOnCheckNumberDuplicated(Result, Parameters) Export
	
	If Result = DialogReturnCode.Yes Then
		Parameters.Insert("AllowCheckNumber", True);
		Write(Parameters);
	Else
		Parameters.Insert("AllowCheckNumber", False);
		Write(Parameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	AttachIdleHandler("AfterOpen", 0.1, True);
	
EndProcedure

&AtClient
Procedure AfterOpen()
	
	If ThisForm.IsInputAvailable() Then
		
		DetachIdleHandler("AfterOpen");
		
		If  Object.Ref.IsEmpty() And ValueIsFilled(Object.Company) Then
			CompanyOnChange(Items.Company);	
		EndIf;	
		
	EndIf;		
	
EndProcedure

&AtClient
Procedure UpdateBankCheck(Result, Parameters) Export
   	If Result = DialogReturnCode.Yes Then
		Object.Number = StrReplace(Generalfunctions.LastCheckNumber(object.BankAccount) + 1,",","");       
    EndIf;              
EndProcedure

&AtClient
Procedure MarkAsVoid(Command)
	Notify = New NotifyDescription("OpenJournalEntry", ThisObject);
	OpenForm("CommonForm.VoidDateForm",,,,,,Notify,FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

&AtClient
Procedure OpenJournalEntry(Parameter1,Parameter2) Export
	
	Str = New Structure;
	Str.Insert("CheckRef", Object.Ref);
	Str.Insert("VoidDate", Parameter1);
	If Parameter1 <> Undefined Then
		OpenForm("Document.GeneralJournalEntry.ObjectForm",Str);	
	EndIf;
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "UpdateVoid" And Parameter = Object.Ref Then
		
		CheckVoid();
		
	EndIf;

EndProcedure

&AtClient
Procedure AuditLogRecord(Command)
	
	FormParameters = New Structure();	
	FltrParameters = New Structure();
	FltrParameters.Insert("DocUUID", String(Object.Ref.UUID()));
	FormParameters.Insert("Filter", FltrParameters);
	OpenForm("CommonForm.AuditLogList",FormParameters, Object.Ref);
	
EndProcedure

&AtServer
Procedure CheckARandAPAccounts(Cancel = False)
	
	ErrorMessage = "";
	ARAPCounter = 0;
	
	CompanyEmpty = Object.Company.IsEmpty();
	
	For Each AccountRow In Object.LineItems Do 
		If AccountRow.Account.AccountType = Enums.AccountTypes.AccountsPayable Then 
			
			ARAPCounter = ARAPCounter + 1;
			If CompanyEmpty Then 
				CommonUseClientServer.MessageToUser("AP Account is in tabular section. Vendor must be selected.",,"Object.Company");
				Cancel = True;
			ElsIf Not Object.Company.Vendor Then 
				CommonUseClientServer.MessageToUser("To select AP account you must select Vendor first.",,"Object.Company");
				Cancel = True;
			EndIf;	
		ElsIf AccountRow.Account.AccountType = Enums.AccountTypes.AccountsReceivable Then 	
			Items.Company.Title = GeneralFunctionsReusable.GetCustomerName();
			ARAPCounter = ARAPCounter + 1;
			If CompanyEmpty Then 
				CommonUseClientServer.MessageToUser("AR Account is in tabular section. Customer must be selected.",,"Object.Company");
				Cancel = True;
			ElsIf Not Object.Company.Customer Then 
				CommonUseClientServer.MessageToUser("To select AR account you must select Customer first.",,"Object.Company");
				Cancel = True;
			EndIf;	
		EndIf;
	EndDo;	
	
	If ARAPCounter > 1 Then 
		Message("Only one AP or AR Account is allowed in tabular section");
		Cancel = True;
	ElsIf ARAPCounter = 0 Then 
		Items.Company.Title = GeneralFunctionsReusable.GetVendorName();
	EndIf;	
		
EndProcedure

&AtClient
Procedure LineItemsAccountOnChange(Item)
	//CurrentAccount = Items.LineItems.CurrentData.Account;
	LineItemsAccountOnChangeAtServer(Items.LineItems.CurrentData.Account, Items.LineItems.CurrentData.LineNumber);
EndProcedure

&AtServer
Procedure LineItemsAccountOnChangeAtServer(CurrentAccount, LineNumber)
	
	IsAR = (CurrentAccount.AccountType = Enums.AccountTypes.AccountsReceivable);
	IsAP = (CurrentAccount.AccountType = Enums.AccountTypes.AccountsPayable);
	IsBank = (CurrentAccount.AccountType = Enums.AccountTypes.Bank);
	
	If IsAP or IsAR Or IsBank Then 
		If Object.BankAccount.AccountType = Enums.AccountTypes.OtherCurrentLiability and Object.BankAccount.CreditCard Then 
			If CurrentAccount.Currency <> Constants.DefaultCurrency.Get() Then 
				CommonUseClientServer.MessageToUser("Accounts currency must be equal to default currency when using Credit card account",,"Object.LineItems["+(LineNumber-1)+"].Account");
				CurrentAccount = ChartsOfAccounts.ChartOfAccounts.EmptyRef(); 	
			EndIf;	
		ElsIf CurrentAccount.Currency <> Object.BankAccount.Currency Then 
			CommonUseClientServer.MessageToUser("Account currency must be the same as the currency of Bank account",,"Object.LineItems["+(LineNumber-1)+"].Account");
			CurrentAccount = ChartsOfAccounts.ChartOfAccounts.EmptyRef(); 	
		EndIf;	
	EndIf;	
	
	If IsAR Or IsAP Then 
		CompanyEmpty = Object.Company.IsEmpty();
		ARAPCounter = 0;
		
		For Index = 0 to (Object.LineItems.Count()-1) Do 
			If Index = (LineNumber-1) Then 
				Continue;	
			EndIf;
			AccountRow = Object.LineItems[Index];
			If AccountRow.Account.AccountType = Enums.AccountTypes.AccountsPayable Then 
				ARAPCounter = ARAPCounter + 1;
			ElsIf AccountRow.Account.AccountType = Enums.AccountTypes.AccountsReceivable Then 	
				ARAPCounter = ARAPCounter + 1;
			EndIf;
		EndDo;	
		
		If ARAPCounter > 0 Then 
			CommonUseClientServer.MessageToUser("Only one AP or AR Account is allowed in tabular section",,"Object.LineItems["+(LineNumber-1)+"].Account");
			CurrentAccount = ChartsOfAccounts.ChartOfAccounts.EmptyRef(); 
		ElsIf CompanyEmpty And IsAP Then 
			CommonUseClientServer.MessageToUser("AP Account is in tabular section. Vendor must be selected.",,"Object.Company");
			Items.Company.Title = GeneralFunctionsReusable.GetVendorName();
		ElsIf CompanyEmpty And IsAR Then 
			CommonUseClientServer.MessageToUser("AR Account is in tabular section. Customer must be selected.",,"Object.Company");	
			Items.Company.Title = GeneralFunctionsReusable.GetCustomerName();
		ElsIf (Not Object.Company.Customer) And IsAR Then 
			CommonUseClientServer.MessageToUser("To select AR account you must select Customer first.",,"Object.Company");
			Items.Company.Title = GeneralFunctionsReusable.GetCustomerName();
		ElsIf (Not Object.Company.Vendor) And IsAP Then 
			CommonUseClientServer.MessageToUser("To select AP account you must select Vendor first.",,"Object.Company");
			Items.Company.Title = GeneralFunctionsReusable.GetVendorName();
		EndIf;
	Else 
		ARAPCounter = 0;
		For Each AccountRow in Object.LineItems Do
			If AccountRow.Account.AccountType = Enums.AccountTypes.AccountsPayable Then 
				ARAPCounter = ARAPCounter + 1;
			ElsIf AccountRow.Account.AccountType = Enums.AccountTypes.AccountsReceivable Then 	
				ARAPCounter = ARAPCounter + 1;
			EndIf;
		EndDo;	
		If ARAPCounter = 0 Then 	
			Items.Company.Title = GeneralFunctionsReusable.GetVendorName();
		EndIf;	
	EndIf;	
EndProcedure

&AtClient
Procedure ExchangeRateOnChange(Item)
	Object.DocumentTotal = Object.LineItems.Total("Amount");
	Object.DocumentTotalRC = Object.LineItems.Total("Amount") * Object.ExchangeRate;
EndProcedure