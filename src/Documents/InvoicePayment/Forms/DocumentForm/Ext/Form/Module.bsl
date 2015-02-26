
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
	
	Result = Query.Execute().Select();
	
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
	
	Notify("UpdateBillInformation", Object.Company);
		
EndProcedure

&AtClient
// The procedure deletes all line items which are
// not paid by this invoice payment
//
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
	
	If Parameters.Property("Company") And Object.Ref.IsEmpty() Then
		Object.Company = Parameters.Company;
		OpenOrdersSelectionForm = True; 
	EndIf;
	
	//Items.FormPayWithDwolla.Enabled = IsBlankString(Object.DwollaTrxID);
	
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
	
	//Disable voiding if document is not posted
	If Object.Ref.Posted = False Then
		Items.FormMarkAsVoid.Enabled = False;
	EndIf;
	
	CheckVoid();
	Attribute1 = Object.Ref;	
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
		Items.VoidMessage.Title = "This bill payment has been voided by";
		VoidingGJ = QueryResult[0].Ref;
		Items.VoidInfo.Visible = True;
		Items.FormMarkAsVoid.Enabled = False;
	Else
		Items.VoidInfo.Visible = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	AttachIdleHandler("AfterOpen", 0.1, True);
	
EndProcedure

&AtClient
Procedure AfterOpen()
	
	ThisForm.Activate();
	
	If ThisForm.IsInputAvailable() Then
		///////////////////////////////////////////////
		DetachIdleHandler("AfterOpen");
		
		If OpenOrdersSelectionForm Then
			CompanyOnChange(Items.Company);	
		EndIf;	
		///////////////////////////////////////////////
	Else 
		AttachIdleHandler("AfterOpen", 0.1, True);
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

	//If WriteParameters.WriteMode = DocumentWriteMode.Posting Then
	//	
	//	If Object.PaymentMethod = Catalogs.PaymentMethods.Check Then
	//		
	//		If CheckNumberAllowed(Object.Number) = True Then
	//	
	//			CurrentObject.PhysicalCheckNum = CurrentObject.Number;
	//		Else
	//			Message("Check number already exists for this bank account");
	//			Cancel = True;
	//		EndIf;

	//	Endif;
	//EndIf;

	

EndProcedure

&AtClient
Procedure PaymentMethodOnChange(Item)
	
	If Object.PaymentMethod = CheckPaymentMethod() Then
		
		If Object.Number = ""  AND Object.Ref.IsEmpty() = False Then
			Object.Number = StrReplace(Generalfunctions.LastCheckNumber(object.BankAccount),",","");
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


EndProcedure


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
	
	For Each LineItem In Object.LineItems Do
		LineItem.Check = True;
		LineItem.Payment = LineItem.BalanceFCY;
	EndDo;
	
	//Object.DocumentTotalRC = Total;
	TotalRevision();

	
EndProcedure


&AtClient
Procedure LineItemsCheckOnChange(Item)
	
	If Items.LineItems.CurrentData.Check Then
			Items.LineItems.CurrentData.Payment = Items.LineItems.CurrentData.BalanceFCY;
	Else                           
		Items.LineItems.CurrentData.Payment = 0;
	
	Endif;
	
	TotalRevision();
	
EndProcedure

&AtServer
Procedure TotalRevision()
	Test = GeneralFunctions.GetExchangeRate(CurrentSessionDate(),Object.Currency);
	Object.DocumentTotal =  Object.LineItems.Total("Payment");
	If Constants.MultiCurrency.Get() = False Then
		Object.DocumentTotalRC =  Object.LineItems.Total("Payment");
	Else
		Object.DocumentTotalRC =  Object.LineItems.Total("Payment") * Test;
	EndIf;
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
Procedure BankAccountOnChange(Item)
	
	If Object.PaymentMethod = CheckPaymentMethod() Then
		ChoiceProcessing = New NotifyDescription("UpdateBankCheck", ThisForm);
		ShowQueryBox(ChoiceProcessing, "Would you like to load the next check number for this bank account?", QuestionDialogMode.YesNo, 0);
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
	Str.Insert("InvoicePayRef", Object.Ref);
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



