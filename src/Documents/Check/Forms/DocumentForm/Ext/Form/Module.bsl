
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
	
	Items.FormPayWithDwolla.Enabled = IsBlankString(Object.DwollaTrxID);
		
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
	
	If Object.PaymentMethod.IsEmpty() Then
		Cancel = True;
		Message = New UserMessage();
		Message.Text=NStr("en='Select a payment method'");
		Message.Field = "Object.PaymentMethod";
		Message.Message();
	EndIf;		
	
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
		    If Object.Number <> "DRAFT" Then
				Cancel = True;
				Message = New UserMessage();
				Message.Text=NStr("en='Enter a check number from 0 to 9999 (99999)'");
				Message.Field = "Object.Number";
				Message.Message();
			EndIf
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
						  
	ExistPurchaseInvoice(Object.Company);
	
EndProcedure

&AtServer
Procedure ExistPurchaseInvoice(Company)
	
	Query = New Query("SELECT
	                  |	DocumentPurchaseInvoice.Ref,
	                  |	DocumentPurchaseInvoice.Number,
	                  |	DocumentPurchaseInvoice.Date,
	                  |	DocumentPurchaseInvoice.Company,
	                  |	DocumentPurchaseInvoice.CompanyCode,
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
	
	
	//If Object.PaymentMethod = Catalogs.PaymentMethods.Check Then
	//	
	//	If CurrentObject.Ref.IsEmpty() Then
	//	
	//		LastNumber = GeneralFunctions.LastCheckNumber(Object.BankAccount);
	//		
	//		LastNumberString = "";
	//		If LastNumber < 10000 Then
	//			LastNumberString = Left(String(LastNumber+1),1) + Right(String(LastNumber+1),3)
	//		Else
	//			LastNumberString = Left(String(LastNumber+1),2) + Right(String(LastNumber+1),3)
	//		EndIf;
	//		
	//		CurrentObject.Number = LastNumberString;
	//		CurrentObject.PhysicalCheckNum = LastNumber + 1;
	//		
	//	Else
	//		CurrentObject.PhysicalCheckNum = Number(CurrentObject.Number);		
	//	EndIf;
	//Endif;	

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
Procedure PayWithDwolla(Command)
	
	DAT = DwollaAccessToken();
	
	If IsBlankString(DAT) Then
		Message(NStr("en = 'Please connect to Dwolla in Settings > Integrations.'"));
		Return;
	EndIf;
	
	// Check document saved.
	If Object.Ref.IsEmpty() Or Modified Then
		Message(NStr("en = 'The document is not saved. Please save the document first.'"));
		Return;
	EndIf;
	
	// Check DwollaID
	DwollaID = CommonUse.GetAttributeValue(Object.Company, "DwollaID");
	If IsBlankString(DwollaID) Then
		Message(NStr("en = 'Enter a Dwolla e-mail ID on the customer card.'"));
		Return;
	Else
		AtSign = Find(DwollaID,"@");
		If AtSign = 0 Then
			IsEmail = False;
		Else
			IsEmail = True;
		EndIf;
	EndIf;
	
	If IsEmail Then
					
		DwollaData = New Map();
		DwollaData.Insert("destinationId", DwollaID);
		DwollaData.Insert("oauth_token", DAT);
		DwollaData.Insert("amount", Format(Object.DocumentTotalRC,"NG=0"));
		DwollaData.Insert("fundsSource", DwollaFundingSource());
		DwollaData.Insert("destinationType", "Email");
		DwollaData.Insert("pin", DwollaPin);
		
		DataJSON = InternetConnectionClientServer.EncodeJSON(DwollaData);
			
	Else
		
		DwollaData = New Map();
		DwollaData.Insert("destinationId", DwollaID);
		DwollaData.Insert("oauth_token", DAT);
		DwollaData.Insert("amount", Format(Object.DocumentTotalRC,"NG=0"));
		DwollaData.Insert("fundsSource", DwollaFundingSource());
		DwollaData.Insert("pin", DwollaPin);
		
		DataJSON = InternetConnectionClientServer.EncodeJSON(DwollaData);
	
	EndIf;

			
	ResultBodyJSON = DwollaCharge(DataJSON);	
	
	If ResultBodyJSON.Success AND ResultBodyJSON.Message = "Success" Then
		Object.DwollaTrxID = Format(ResultBodyJSON.Response, "NG=0"); //Format(num, "NG=")
		Message(NStr("en = 'Payment was successfully made. Please save the document.'"));
		Modified = True;
	Else
		Message(ResultBodyJSON.Message);
	EndIf;
	
	Items.FormPayWithDwolla.Enabled = IsBlankString(Object.DwollaTrxID);

EndProcedure

&AtServer
Function DwollaCharge(DataJSON)
	
	HeadersMap = New Map();
	HeadersMap.Insert("Content-Type", "application/json");		
	ConnectionSettings = New Structure;
	Connection = InternetConnectionClientServer.CreateConnection( "https://www.dwolla.com/oauth/rest/transactions/send", ConnectionSettings).Result;
	ResultBody = InternetConnectionClientServer.SendRequest(Connection, "Post", ConnectionSettings, HeadersMap, DataJSON).Result;
	
	//HeadersMap = New Map();
	//HeadersMap.Insert("Content-Type", "application/json");
	//
	//HTTPRequest = New HTTPRequest("/oauth/rest/transactions/send",HeadersMap);
	//	
	//HTTPRequest.SetBodyFromString(DataJSON,TextEncoding.ANSI);
	//
	//SSLConnection = New OpenSSLSecureConnection();
	//
	//HTTPConnection = New HTTPConnection("www.dwolla.com",,,,,,SSLConnection);
	//Result = HTTPConnection.Post(HTTPRequest);
	//ResultBody = Result.GetBodyAsString(TextEncoding.UTF8);
	ResultBodyJSON = InternetConnectionClientServer.DecodeJSON(ResultBody);
	
	Return ResultBodyJSON;
	
EndFunction


&AtServer
Function DwollaAccessToken()
	
	Return Constants.dwolla_access_token.Get();	
	
EndFunction

&AtServer
Function DwollaFundingSource()
	
	Return Constants.dwolla_funding_source.Get();
	
EndFunction

&AtClient
Procedure NumberOnChange(Item)
	NumberOnChangeAtServer();
EndProcedure

&AtServer
Procedure NumberOnChangeAtServer()
	
	CheckExist = Documents.Check.FindByNumber(Object.Number);
	If CheckExist <> Documents.Check.EmptyRef() Then
		Message("Check number already exists");
		Object.Number = "";
	Endif;
	
EndProcedure

&AtClient
Procedure PayWithRipple(Command)
	
	Address = GetRippleAddress(Object.Company);
	
	If Address <> "" Then
		GotoURL("https://ripple.com/client/#/send?to=" + Address + "&amount=" + Format(Object.DocumentTotalRC,"NG=0"));
	EndIf;
	
EndProcedure

&AtServer
Function GetRippleAddress(Company)
	
	Return Company.RippleAddress;	
	
EndFunction
