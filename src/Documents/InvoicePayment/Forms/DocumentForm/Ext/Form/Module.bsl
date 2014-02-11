
&AtServer
// The procedure selects all vendor invoices and customer returns having an unpaid balance
// and fills in line items of an invoice payment.
//
Procedure FillDocumentList(Company)
		
	Object.LineItems.Clear();
	
	Query = New Query;
	Query.Text = "SELECT
	             |	GeneralJournalBalance.AmountBalance * -1 AS AmountBalance,
	             |	GeneralJournalBalance.AmountRCBalance * -1 AS AmountRCBalance,
	             |	GeneralJournalBalance.ExtDimension2.Ref AS Ref,
				 |  GeneralJournalBalance.ExtDimension2.Date
	             |FROM
	             |	AccountingRegister.GeneralJournal.Balance AS GeneralJournalBalance
	             |WHERE
	             |	GeneralJournalBalance.AmountBalance <> 0
	             |	AND (GeneralJournalBalance.ExtDimension2 REFS Document.PurchaseInvoice OR
	             |       GeneralJournalBalance.ExtDimension2 REFS Document.SalesReturn)
	             |	AND GeneralJournalBalance.ExtDimension1 = &Company
				 |ORDER BY
				 |	GeneralJournalBalance.ExtDimension2.Date";
				 
	Query.SetParameter("Company", Company);
	
	Result = Query.Execute().Choose();
	
	While Result.Next() Do
		// Skip credit memos. Due to high load on subdimensions in query and small quantity of returns - do this in loop
		If TypeOf(Result.Ref) = Type("DocumentRef.SalesReturn") AND Result.Ref.ReturnType = Enums.ReturnTypes.CreditMemo Then
			Continue;
		EndIf;
		
		DataLine = Object.LineItems.Add();
		
		DataLine.Document = Result.Ref;
		DataLine.Currency = Result.Ref.Currency;
		Dataline.BalanceFCY = Result.AmountBalance;
		Dataline.Balance = Result.AmountRCBalance;
		DataLine.Payment = 0;
		
	EndDo;	
	
EndProcedure

&AtClient
// CompanyOnChange UI event handler. The procedure repopulates line items upon a company change.
//
Procedure CompanyOnChange(Item)
	
	//Object.CompanyCode = CommonUse.GetAttributeValue(Object.Company, "Code");
	FillDocumentList(Object.Company);
	LineItemsPaymentOnChange(Items.LineItemsPayment);
	
	If Object.LineItems.Count() > 0 Then
		Items.PayAll.Visible = true;
	Else
		Items.PayAll.Visible = false;
	Endif;
	
EndProcedure


&AtClient
// The procedure notifies all related dynamic lists that the changes in data have occured.
//
Procedure AfterWrite(WriteParameters)
	
	For Each DocumentLine in Object.LineItems Do
		
		RepresentDataChange(DocumentLine.Document, DataChangeType.Update);
		
	EndDo;
		
EndProcedure

&AtClient
// The procedure deletes all line items which are
// not paid by this invoice payment
//
Procedure BeforeWrite(Cancel, WriteParameters)
	
	//Closing period
	If DocumentPosting.DocumentPeriodIsClosed(Object.Ref, Object.Date) Then
		Cancel = Not DocumentPosting.DocumentWritePermitted(WriteParameters);
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
	
	// preventing posting if already included in a bank rec
	If DocumentPosting.RequiresExcludingFromBankReconciliation(Object.Ref, -1*Object.DocumentTotalRC, Object.Date, Object.BankAccount, WriteParameters.WriteMode) Then
		Cancel = True;
		CommonUseClient.ShowCustomMessageBox(ThisForm, "Bank reconciliation", "The transaction you are editing has been reconciled. Saving 
		|your changes could put you out of balance the next time you try to reconcile. 
		|To modify it you should exclude it from the Bank rec. document.", PredefinedValue("Enum.MessageStatus.Warning"));
	EndIf;	
	
	TotalPay = Object.LineItems.Total("Payment");

	If Object.LineItems.Count() = 0 Or TotalPay = 0 Then
		Message("Invoice Payment can not have empty or no paid lines.");
		Cancel = True;
		Return;
	EndIf;
	
	NumberOfLines = Object.LineItems.Count() - 1;
	
	While NumberOfLines >=0 Do
		
		If Object.LineItems[NumberOfLines].Payment = 0 Then
			Object.LineItems.Delete(NumberOfLines);
		Else
		EndIf;
		
		NumberOfLines = NumberOfLines - 1;
		
	EndDo;
	
	If Object.LineItems.Count() > 0 Then
		Object.Currency = Object.LineItems[0].Currency;
	Else
		GeneralFunctionsReusable.DefaultCurrency();
	Endif;
	
	NumberOfRows = Object.LineItems.Count() - 1;
		
	While NumberOfRows >= 0 Do
		
		If NOT Object.LineItems[NumberOfRows].Currency = Object.Currency Then
			Message("All documents in the line items need to have the same currency");
			Cancel = True;
			Return;
	    EndIf;
		
		NumberOfRows = NumberOfRows - 1;
		
	EndDo;
	
EndProcedure

&AtClient
// LineItemsPaymentOnChange UI event handler.
// The procedure calculates a document total in the foreign currency (DocumentTotal) and in the
// reporting currency (DocumentTotalRC).
//
Procedure LineItemsPaymentOnChange(Item)
	
	DefaultCurrency = GeneralFunctionsReusable.DefaultCurrency();
		
	DocumentTotalRC = 0;
	For Each Row In Object.LineItems Do
		If Row.Currency = DefaultCurrency Then
			DocumentTotalRC = DocumentTotalRC + Row.Payment;
		Else
			ExchangeRate = GeneralFunctions.GetExchangeRate(Object.Date, Row.Currency);
			DocumentTotalRC = DocumentTotalRC + Round(Row.Payment * ExchangeRate, 2);
		EndIf;
	EndDo;
	Object.DocumentTotal = Object.LineItems.Total("Payment");
	Object.DocumentTotalRC = DocumentTotalRC;
	
	If Items.LineItems.CurrentData <> Undefined Then
		If Items.LineItems.CurrentData.Payment > 0 Then
			Items.LineItems.CurrentData.Check = True;
		Else
			Items.LineItems.CurrentData.Check = False;
		Endif;
	Endif;

	
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Items.FormPayWithDwolla.Enabled = IsBlankString(Object.DwollaTrxID);
	
	//Title = "Payment " + Object.Number + " " + Format(Object.Date, "DLF=D");
	
	Items.Company.Title = GeneralFunctionsReusable.GetVendorName();
	
	If Object.BankAccount.IsEmpty() Then
		Object.BankAccount = Constants.BankAccount.Get();
	Else
	EndIf; 

	//Items.BankAccountLabel.Title =
	//	CommonUse.GetAttributeValue(Object.BankAccount, "Description");
	
	If GeneralFunctionsReusable.FunctionalOptionValue("MultiCurrency") Then	
		Items.LineItemsPayment.Title = "Payment FCY";	
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	//Period closing
	If DocumentPosting.DocumentPeriodIsClosed(CurrentObject.Ref, CurrentObject.Date) Then
		PermitWrite = DocumentPosting.DocumentWritePermitted(WriteParameters);
		CurrentObject.AdditionalProperties.Insert("PermitWrite", PermitWrite);	
	EndIf;
	
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
		
		If Object.Number = ""  AND Object.Ref.IsEmpty() = False Then
			Object.Number = StrReplace(Generalfunctions.LastCheckNumber(object.BankAccount),",","");
		Else
			Object.Number = StrReplace(Generalfunctions.LastCheckNumber(object.BankAccount) + 1,",","");
		EndIf;

	Else
		Object.Number = "";
		Items.Number.ReadOnly = False;
	EndIf;

EndProcedure

&AtServer
Function CheckPaymentMethod()
	
	Return Catalogs.PaymentMethods.Check;
	
EndFunction


&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	If Object.PaymentMethod.IsEmpty() Then
		Cancel = True;
		Message = New UserMessage();
		Message.Text=NStr("en='Select a payment method'");
		Message.Field = "Object.PaymentMethod";
		Message.Message();
	EndIf;	
	
	If NOT Object.Ref.IsEmpty() And Object.PaymentMethod = CheckPaymentMethod() Then
	
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
			EndIF;
	EndTry;
		
	Endif;

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
		Object.DwollaTrxID = Format(ResultBodyJSON.Response, "NG=0");
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
Procedure PayAll(Command)
	
	Total = 0;
	For Each LineItem In Object.LineItems Do
		test = LineItem;
		//Items.LineItems.CurrentData.Check = True;
		LineItem.Check = True;
		LineItem.Payment = LineItem.Balance;
		//LineItemsCheckOnChange(Items.LineItems.CurrentData.Check);
		Total = Total + LineItem.Payment;

	EndDo;
	
	Object.DocumentTotalRC = Total;
	
EndProcedure


&AtClient
Procedure LineItemsCheckOnChange(Item)
	
	If Items.LineItems.CurrentData.Check Then
		Items.LineItems.CurrentData.Payment = Items.LineItems.CurrentData.Balance;
	Else
		Items.LineItems.CurrentData.Payment = 0;
	
	Endif;
	
	TotalRevision();
	
EndProcedure

&AtServer
Procedure TotalRevision()
	
	Total = 0;
	For Each LineItem In Object.LineItems Do
		
	Total = Total + LineItem.Payment;	
		
	EndDo;
	
	Object.DocumentTotalRC = Total;
	
EndProcedure

&AtServer
Function GetRippleAddress(Company)
	
	Return Company.RippleAddress;	
	
EndFunction

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


