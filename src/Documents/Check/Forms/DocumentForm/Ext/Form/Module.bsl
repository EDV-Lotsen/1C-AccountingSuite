
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
	
	If Object.PaymentMethod = CheckPaymentMethod() Then
		ChoiceProcessing = New NotifyDescription("UpdateBankCheck", ThisForm);
		ShowQueryBox(ChoiceProcessing, "Would you like to load the next check number for this bank account?", QuestionDialogMode.YesNo, 0);
	EndIf;
	
EndProcedure



&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("Company") Then
		Object.Company = Parameters.Company;
	EndIf;
	
	//Items.FormPayWithDwolla.Enabled = IsBlankString(Object.DwollaTrxID);
	
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
Procedure DateOnChange(Item)
	
	AccountCurrency = CommonUse.GetAttributeValue(Object.BankAccount, "Currency");
    Object.ExchangeRate = GeneralFunctions.GetExchangeRate(Object.Date, AccountCurrency);

EndProcedure

&AtClient
Procedure CompanyOnChange(Item)
	
	//Object.CompanyCode = CommonUse.GetAttributeValue(Object.Company, "Code");
						  
	ExistPurchaseInvoice(Object.Company);
	
EndProcedure

&AtServer
Procedure ExistPurchaseInvoice(Company)
	
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
					  
					  Query.SetParameter("Company", Company);
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
Function DwollaPaymentMethod()
	
	Return Catalogs.PaymentMethods.FindByDescription("Dwolla");
	
EndFunction
	

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
	If ReconciledDocumentsServerCall.RequiresExcludingFromBankReconciliation(Object.Ref, -1*Object.DocumentTotalRC, Object.Date, Object.BankAccount, WriteParameters.WriteMode) Then
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
Procedure PayWithBitcoin(Command)
	
	coinbase_api_key = coinbase_api_key();
	
	If IsBlankString(coinbase_api_key) Then
		Message(NStr("en = 'Please connect to Coinbase in Settings > Integrations.'"));
		Return;
	EndIf;
	
	// Check document saved.
	If Object.Ref.IsEmpty() Or Modified Then
		Message(NStr("en = 'The document is not saved. Please save the document first.'"));
		Return;
	EndIf;
	
	// Check DwollaID
	bitcoin_address = CommonUse.GetAttributeValue(Object.Company, "bitcoin_address");
	If IsBlankString(bitcoin_address) Then
		Message(NStr("en = 'Enter a bitcoin address on the vendor card.'"));
		Return;
	Else
	EndIf;
						
	CoinbaseData = New Map();
	CoinbaseData.Insert("to", bitcoin_address);
	CoinbaseData.Insert("amount_string", Format(Object.DocumentTotalRC,"NG=0"));
	CoinbaseData.Insert("amount_currency_iso", "USD");
	
	CoinbaseTrx = New Map();
	CoinbaseTrx.Insert("transaction", CoinbaseData);
	
	DataJSON = InternetConnectionClientServer.EncodeJSON(CoinbaseTrx);

			
	ResultBodyJSON = CoinbaseCharge(DataJSON);	
	
	If ResultBodyJSON.success Then
		Object.CoinbaseTrxID = ResultBodyJSON.transaction.id; //Format(num, "NG=")
		Message(NStr("en = 'Payment was successfully made. Please save the document.'"));
		//Message(ResultBodyJSON.transaction.id);
		Modified = True;
	Else
		Message("Transaction failed");
	EndIf;
	
	Items.FormPayWithBitcoin.Enabled = IsBlankString(Object.CoinbaseTrxID);

EndProcedure

&AtServer
Function CoinbaseCharge(DataJSON)
	
	HeadersMap = New Map();
	HeadersMap.Insert("Content-Type", "application/json");		
	ConnectionSettings = New Structure;
	Connection = InternetConnectionClientServer.CreateConnection( "https://coinbase.com/api/v1/transactions/send_money?api_key=" + coinbase_api_key(), ConnectionSettings).Result;
	ResultBody = InternetConnectionClientServer.SendRequest(Connection, "Post", ConnectionSettings, HeadersMap, DataJSON).Result;
	
	ResultBodyJSON = InternetConnectionClientServer.DecodeJSON(ResultBody);
	
	Return ResultBodyJSON;
	
EndFunction


&AtServer
Function coinbase_api_key()
	
	Return Constants.coinbase_api_key.Get();	
	
EndFunction

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



