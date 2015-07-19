&AtClient
Var BeforeWriteChoiceProcessed;

&AtClient
// CompanyOnChange UI event handler. The procedure repopulates line items
// upon a company change.
//
Procedure CompanyOnChange(Item)
	
	Object.Currency = CommonUse.GetAttributeValue(Object.Company, "DefaultCurrency");
	
	EmailSet();
	
	// Set form exchange rate to company's latest
	UpdateExchangeRate();
	
	CompanyOnChangeAtServer();
			
	If Object.LineItems.Count() > 0 Then
		Items.PayAllDoc.Visible = true;
		Items.SpaceFill.Visible = true;
	Else
		Items.PayAllDoc.Visible = false;
		Items.SpaceFill.Visible = false;
	Endif;
	
EndProcedure

&AtServer
Procedure CompanyOnChangeAtServer()
	If Object.Company.ARAccount <> ChartsofAccounts.ChartOfAccounts.EmptyRef() Then
		Object.ARAccount = Object.Company.ARAccount;
	Else
		DefaultCurrency = GeneralFunctionsReusable.DefaultCurrency();
		Object.ARAccount = DefaultCurrency.DefaultARAccount;
	EndIf;
	
	// Fill in current receivables
	CashReceiptMethods.FillDocumentList(Object.Company,Object);
	
	// Fill in credit memos
	CashReceiptMethods.FillCreditMemos(Object.Company,Object);

EndProcedure

&AtServer
Function CompanyCurrency()
	return Object.Company.DefaultCurrency;
EndFunction

&AtClient
Procedure CashPaymentOnChange(Item)
	CashPaymentOnChangeAtServer();					
EndProcedure

&AtServer
Procedure CashPaymentOnChangeAtServer()
	CashReceiptMethods.CashPaymentCalculation(Object,PayRef);
EndProcedure

&AtClient
// LineItemsPaymentOnChange UI event handler.
// The procedure calculates a document total in the foreign currency (DocumentTotal) and in the
// reporting currency (DocumentTotalRC).
//
Procedure LineItemsPaymentOnChange(Item)
	
	DefaultCurrency = GeneralFunctionsReusable.DefaultCurrency();
		
	If Items.LineItems.CurrentData.Check = False Then
		Items.LineItems.CurrentData.Check = True;
	Endif;

	
	TabularPartRow = Items.LineItems.CurrentData;
				
	// Limit the payment to at most the BalanceFCY amount
	If TabularPartRow.Payment > TabularPartRow.BalanceFCY2 Then
		  TabularPartRow.Payment = TabularPartRow.BalanceFCY2;
	Endif;
	
	// If payment is none, uncheck the lineitem
	If TabularPartRow.Payment = 0 Then
		TabularPartRow.Check = False;
	Endif;
	
	PayTotal = 0;
	CreditTotal = 0;	
	For Each LineItem In Object.LineItems Do		
				PayTotal =  PayTotal + LineItem.Payment;
				CreditTotal = CreditTotal + LineItem.CreditApplied;		
	EndDo;
				
	CreditTotal = 0;
	For Each LineItemCM In Object.CreditMemos Do
			CreditTotal =  CreditTotal + LineItemCM.Payment;
	EndDo;
			
	LineItemsPaymentOnChangeAtServer();
			
EndProcedure

&AtServer
Procedure LineItemsPaymentOnChangeAtServer()
	CashReceiptMethods.AdditionalPaymentCall(Object,PayRef);
EndProcedure

&AtClient
// The procedure deletes all line items which are not paid by this cash receipt
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
	
	// preventing posting if already included in a bank rec
	If ReconciledDocumentsServerCall.RequiresExcludingFromBankReconciliation(Object.Ref, Object.CashPayment, Object.Date, Object.BankAccount, WriteParameters.WriteMode) Then
		Cancel = True;
		CommonUseClient.ShowCustomMessageBox(ThisForm, "Bank reconciliation", "The transaction you are editing has been reconciled. Saving your changes could put you out of balance the next time you try to reconcile. 
		|To modify it you should exclude it from the Bank rec. document.", PredefinedValue("Enum.MessageStatus.Warning"));
	EndIf;

	NumberOfLines = Object.LineItems.Count() - 1;
	While NumberOfLines >=0 Do
		
		If Object.LineItems[NumberOfLines].Payment = 0 Then
			Object.LineItems.Delete(NumberOfLines);
		EndIf;
		
		NumberOfLines = NumberOfLines - 1;
		
	EndDo;
	
	NumberOfLines = Object.CreditMemos.Count() - 1;
	While NumberOfLines >=0 Do
		          
		If Object.CreditMemos[NumberOfLines].Payment = 0 Then
			Object.CreditMemos.Delete(NumberOfLines);
		EndIf;
		
		NumberOfLines = NumberOfLines - 1;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	//Period closing
	If PeriodClosingServerCall.DocumentPeriodIsClosed(CurrentObject.Ref, CurrentObject.Date) Then
		PermitWrite = PeriodClosingServerCall.DocumentWritePermitted(WriteParameters);
		CurrentObject.AdditionalProperties.Insert("PermitWrite", PermitWrite);	
	EndIf;
	
	LineItemArray = New Array();
	For Each LineItem In Object.LineItems Do
		LineItemArray.Add(LineItem.BalanceFCY2);	
	EndDo;
	CurrentObject.AdditionalProperties.Insert("LineItems", LineItemArray);
	
EndProcedure

&AtClient
// The procedure deletes all line items which are not paid by this cash receipt
//
Procedure BeforeWriteChoiceProcessing(ChoiceResult, WriteParameters) Export
	
	// Process user unapplied payment confirmation.
	//If ChoiceResult = DialogReturnCode.OK Then
	//	
	//	// Re-request document writing.
	//	BeforeWriteChoiceProcessed = True;
	//	Write(WriteParameters);
	//EndIf;
	
EndProcedure

&AtClient
// The procedure notifies all related dynamic lists that the changes in data have occured.
//
Procedure AfterWrite(WriteParameters)
	
	/////////
	/////////
	
	// Request user to repost subordinate documents.
	Structure = New Structure("Type, DocumentRef", "RepostSubordinateDocumentsOfCashReceipt", Object.Ref); 
	KeyData = CommonUseClient.StartLongAction(NStr("en = 'Posting subordinate document(s)'"), Structure, ThisForm);
	If WriteParameters.Property("CloseAfterWrite") Then
		BackgroundJobParameters.Add(True);// [5]
	Else
		BackgroundJobParameters.Add(False);// [5]
	EndIf;
	CheckObtainedData(KeyData);
	
	/////////
	/////////
	
	For Each DocumentLine in Object.LineItems Do
				
		RepresentDataChange(DocumentLine.Document, DataChangeType.Update);
		
	EndDo;
	
	Notify("UpdatePayInvoiceInformation", Object.Company);

EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("Company") And Object.Ref.IsEmpty() Then
		Object.Company = Parameters.Company;
		AutoselectInvoices = True;
	EndIf;
	
	If Parameters.Property("SalesInvoice") Then
		ProcessNewCashReceipt(Parameters.SalesInvoice);
	EndIf;
	
	Items.Company.Title = GeneralFunctionsReusable.GetCustomerName();
	Items.UnappliedPayment.ReadOnly = True;
	
	If Object.DepositType = "2" Then
		//Items.BankAccount.ReadOnly = False;
	Else // 1, Null, ""
		//Items.BankAccount.ReadOnly = True;
	EndIf;
		
	If Object.BankAccount.IsEmpty() Then
		If Object.DepositType = "2" Then
			DefaultBankAccount = Constants.BankAccount.Get();
			If DefaultBankAccount.Currency <> Object.Currency and DefaultBankAccount <> Constants.DefaultCurrency.Get() Then 
				DefaultBankAccount = ChartsOfAccounts.ChartOfAccounts.EmptyRef();
			EndIf;	
			Object.BankAccount = DefaultBankAccount;
		Else
			Object.BankAccount = Constants.UndepositedFundsAccount.Get();
		EndIf;
	EndIf;
	
	If Object.ARAccount.IsEmpty() Then
		DefaultCurrency = GeneralFunctionsReusable.DefaultCurrency();
		Object.ARAccount = DefaultCurrency.DefaultARAccount;
	Else
	EndIf;
	
	If GeneralFunctionsReusable.FunctionalOptionValue("MultiCurrency") Then	
		Items.CreditMemosPayment.Title = "Payment FCY";	
		Items.LineItemsPayment.Title = "Payment FCY";
		Items.CreditMemosBalanceFCY.Title = "Balance FCY";
		Items.LineItemsBalanceFCY.Title = "Balance FCY";
	EndIf;
	
	// Set checks for credit memos
	For Each LineItem In Object.CreditMemos Do
		If LineItem.Payment > 0 Then LineItem.Check = True; EndIf;
	EndDo;
	
	For Each LineItem In Object.LineItems Do
		If LineItem.Payment > 0 Then LineItem.Check = True; EndIf;
	EndDo;

	
	// Update elements status.
	//Items.FormChargeWithStripe.Enabled = IsBlankString(Object.StripeID);
		
	If Object.Ref.IsEmpty() Then
		Object.EmailNote = Constants.CashReceiptFooter.Get();
	EndIf;
	
	// Update lineitem balances.
	CashReceiptMethods.UpdateLineItemBalances(Object);
	
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
		
		If AutoselectInvoices Then
			CompanyOnChange(Items.Company);	
		EndIf;	
		///////////////////////////////////////////////
	Else 
		AttachIdleHandler("AfterOpen", 0.1, True);
	EndIf;	
	
EndProcedure


&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	// Set checks for credit memos
	For Each LineItem In Object.CreditMemos Do
		If LineItem.Payment > 0 Then LineItem.Check = True; EndIf;
	EndDo;
	
	For Each LineItem In Object.LineItems Do
		If LineItem.Payment > 0 Then LineItem.Check = True; EndIf;
	EndDo;

	
EndProcedure

&AtClient
// Fills credit payment amount to match the credit balance of lineitem
Procedure CheckOnChange(Item)
	
	PayTotal = 0;
	BalTotal = 0;
	
	DefaultCurrency = GeneralFunctionsReusable.DefaultCurrency();
	
	// Fill/clear payment value
	If Items.CreditMemos.CurrentData.Check Then
		
		If Items.CreditMemos.CurrentData.Currency2 = DefaultCurrency Then
			
			For Each LineItem In Object.LineItems Do
				BalTotal = BalTotal + LineItem.BalanceFCY2;
				PayTotal = PayTotal + LineItem.Payment;
			EndDo;

		
			If Items.CreditMemos.CurrentData.BalanceFCY2 > (BalTotal - PayTotal) And PayRef = True Then
				Items.CreditMemos.CurrentData.Payment = BalTotal - PayTotal;
			Else
				Items.CreditMemos.CurrentData.Payment = Items.CreditMemos.CurrentData.BalanceFCY2;
			Endif;
		Else
			
			For Each LineItem In Object.LineItems Do
				BalTotal = BalTotal + LineItem.BalanceFCY2;
				PayTotal = PayTotal + LineItem.Payment;
			EndDo;

			If Items.CreditMemos.CurrentData.BalanceFCY2 > (BalTotal - PayTotal) And PayRef = True Then
				Items.CreditMemos.CurrentData.Payment = BalTotal - PayTotal;
			Else
				Items.CreditMemos.CurrentData.Payment = Items.CreditMemos.CurrentData.BalanceFCY2;
			Endif;
		Endif;

		
	Else
		Items.CreditMemos.CurrentData.Payment = 0;
		
		For Each LineItem In Object.LineItems Do
			LineItem.Check = False;
			LineItem.Payment = 0;
		EndDo;
		
	EndIf;
	
	CurrentLineItemPay = Items.CreditMemos.CurrentData.Payment;
	CurrentCheckMarkStatus = Items.CreditMemos.CurrentData.Check;
	CheckOnChangeAtServer(CurrentLineItemPay,CurrentCheckMarkStatus);

	
	// Invoke inherited payment change event
	//CreditMemosPaymentOnChange(Item)
EndProcedure

&AtServer
Procedure CheckOnChangeAtServer(PayAmount,CheckStatus)
	CashReceiptMethods.AdditionalCreditPay(Object,CreditAppliedNegative,CreditAppliedPositive,PayAmount,CheckStatus);	
	CashReceiptMethods.AdditionalPaymentCall(Object,PayRef);

EndProcedure

&AtClient
// Fills payment amount for lineitem based on lineitem balance
Procedure Check2OnChange(Item)

	DefaultCurrency = GeneralFunctionsReusable.DefaultCurrency();
	
	PayTotal = 0;
	For Each LineItem In Object.LineItems Do
		PayTotal = PayTotal + LineItem.Payment;
	EndDo;
	
	If Items.LineItems.CurrentData.Check Then
		If Object.UnappliedPayment >= Items.LineItems.CurrentData.Payment Then
			Object.UnappliedPayment = Object.UnappliedPayment - Items.LineItems.CurrentData.Payment;
		EndIf;
		Items.LineItems.CurrentData.Payment = Items.LineItems.CurrentData.BalanceFCY2;
		If PayRef = False Then
			Object.CashPayment = Object.CashPayment + Items.LineItems.CurrentData.Payment;
		Else
			PayRef = False;
		EndIf;
	Else
		If Object.UnappliedPayment < Object.CashPayment Then
			Object.UnappliedPayment = Object.UnappliedPayment + Items.LineItems.CurrentData.Payment;
		EndIf;
		Items.LineItems.CurrentData.Payment = 0;
	EndIf;
			
	Check2OnChangeAtServer();
	
EndProcedure

&AtServer
Procedure Check2OnChangeAtServer()
	CashReceiptMethods.AdditionalPaymentCall(Object,PayRef);
EndProcedure


&AtClient
Procedure CreditMemosPaymentOnChange(Item)
		
	DefaultCurrency = GeneralFunctionsReusable.DefaultCurrency();
			
	If Items.CreditMemos.CurrentData.Payment > Items.CreditMemos.CurrentData.BalanceFCY2 Then
		Items.CreditMemos.CurrentData.Payment = Items.CreditMemos.CurrentData.BalanceFCY2;
	Endif;
	
	//Credit Memo Line Item Change
	//CreditAppliedPositive and CreditAppliedNegative determine whethere there has been a
	// reduction in credits applied or an increase in credits applied.
	//		- CreditPayment: New CreditMemo section total from the payment change.
	//		- CreditTotal: What is currently applied to the LineItems section right now (without the payment change).
	CreditPayment = Object.CreditMemos.Total("Payment");
	If CreditPayment > CreditTotal Then
		  CreditAppliedPositive = CreditPayment - CreditTotal;
	Else
		  CreditAppliedNegative = CreditTotal - CreditPayment;
	EndIf; 
	  
	If Items.CreditMemos.CurrentData.Payment Then
		Items.CreditMemos.CurrentData.Check = False;
	Endif;   
	
	PayTotal = 0;
	BalTotal = 0;
	For Each LineItem In Object.LineItems Do
			BalTotal = BalTotal + LineItem.BalanceFCY2;
			PayTotal = PayTotal + LineItem.Payment;
	EndDo;
	
	If Items.CreditMemos.CurrentData.Payment > (BalTotal - PayTotal) Then
		Items.CreditMemos.CurrentData.Payment = BalTotal - PayTotal;
		
	Endif;
	
	If Items.CreditMemos.CurrentData.Check = False Then
		Items.CreditMemos.CurrentData.Check = True;
	Endif;
	
	TabularPartRow = Items.CreditMemos.CurrentData;
	
	CreditTotal = 0;	
	For Each LineItemCM In Object.CreditMemos Do
			CreditTotal = CreditTotal + LineItemCM.Payment;
	EndDo;
		
	AppliedCredit = CreditTotal;
	
	CurrentLineItemPay = Items.CreditMemos.CurrentData.Payment;
	CurrentCheckMarkStatus = Items.CreditMemos.CurrentData.Check;
	
	CreditMemosPaymentOnChangeAtServer(CurrentLineItemPay,CurrentCheckMarkStatus);

EndProcedure

&AtServer
Procedure CreditMemosPaymentOnChangeAtServer(PayAmount,CheckStatus)
	CashReceiptMethods.AdditionalCreditPay(Object,CreditAppliedNegative,CreditAppliedPositive,PayAmount,CheckStatus);
EndProcedure

&AtServer
Function SessionTenant()
	
	Return SessionParameters.TenantValue;
	
EndFunction

&AtServer
Function GetInvoiceNumber(Ref)
	Invoice = Ref.Lineitems[0].Document;
	Return Invoice.Number;
EndFunction


&AtClient
Procedure SendEmail(Command)
	If Object.Ref.IsEmpty() OR IsPosted() = False Then
		Message("An email cannot be sent until the cash receipt is posted");
	Else	
		FormParameters = New Structure("Ref",Object.Ref );
		OpenForm("CommonForm.EmailForm", FormParameters,,,,,, FormWindowOpeningMode.LockOwnerWindow);	
	EndIf;
EndProcedure

&AtServer
Function IsPosted()
	Return Object.Ref.Posted;	
EndFunction

&AtServer
Procedure SendEmailAtServer()
EndProcedure

&AtServer
Procedure EmailSet()
	Query = New Query("SELECT
		                  |	Addresses.FirstName,
		                  |	Addresses.MiddleName,
		                  |	Addresses.LastName,
		                  |	Addresses.Phone,
		                  |	Addresses.Fax,
		                  |	Addresses.Email,
		                  |	Addresses.AddressLine1,
		                  |	Addresses.AddressLine2,
		                  |	Addresses.City,
		                  |	Addresses.State.Code AS State,
		                  |	Addresses.Country,
		                  |	Addresses.ZIP,
		                  |	Addresses.RemitTo
		                  |FROM
		                  |	Catalog.Addresses AS Addresses
		                  |WHERE
		                  |	Addresses.Owner = &Company
		                  |	AND Addresses.DefaultBilling = TRUE");
		Query.SetParameter("Company", object.company);
			QueryResult = Query.Execute();	
		Dataset = QueryResult.Unload();
		
	If Dataset.Count() > 0 Then
			Object.EmailTo = Dataset[0].Email;
		EndIf;
		
EndProcedure

&AtClient
Procedure OnClose()
	
	//Because value type of BackgroundJobParameters is Arbitrary
	BackgroundJobParameters.Clear();
	
	OnCloseAtServer();
	
EndProcedure

&AtServer
Procedure OnCloseAtServer()

	If SentEmail = True Then
		
		DocObject = object.ref.GetObject();
		DocObject.EmailTo = Object.EmailTo;
		DocObject.LastEmail = "Last email on " + Format(CurrentDate(),"DLF=DT") + " to " + Object.EmailTo;
		DocObject.Write();
	Endif;

EndProcedure

&AtClient
// When the Select All button is pressed, checks all lineitem payments and fills them based on the balance
Procedure PayAllDoc(Command)
	
	Total = 0;
	For Each LineItem In Object.LineItems Do
		LineItem.Check = True;
		LineItem.Payment = LineItem.BalanceFCY2;
		Total = Total + LineItem.Payment;

	EndDo;
		
	PayAllDocAtServer();
	
EndProcedure

&AtServer
Procedure PayAllDocAtServer()
	CashReceiptMethods.AdditionalPaymentCall(Object,PayRef);	
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

&AtServer
Procedure ProcessNewCashReceipt(SalesInvoice)
	
	Object.Company = SalesInvoice.Company;
	Object.Date = CurrentDate();
	UpdateExchangeRate();
	EmailSet();
	CashReceiptMethods.FillDocumentList(Object.Company,Object);
	For Each Doc In Object.LineItems Do
		If Doc.Document = SalesInvoice Then
			Doc.Payment = Doc.BalanceFCY2;
			//Doc.Payment = Doc.BalanceFCY; //alan fix
			Object.CashPayment = Doc.BalanceFCY2;
			Object.DocumentTotal = Doc.BalanceFCY2;
			Object.DocumentTotalRC = Doc.BalanceFCY2 * Object.ExchangeRate;
		EndIf;
	EndDo;
	CashReceiptMethods.FillCreditMemos(Object.Company,Object);
	
EndProcedure


&AtClient
Procedure DepositTypeOnChange(Item)
	DepositTypeOnChangeAtServer();
EndProcedure


&AtServer
Procedure DepositTypeOnChangeAtServer()
	If Object.DepositType = "2" Then
		//Items.BankAccount.ReadOnly = False;
		// ++ MisA 11/20/2014 If bank account has currency other than CR and CD, then deny to use this account
		DefaultBankAccount = Constants.BankAccount.Get();
		If DefaultBankAccount.Currency <> Object.Currency and DefaultBankAccount <> Constants.DefaultCurrency.Get() Then 
			DefaultBankAccount = ChartsOfAccounts.ChartOfAccounts.EmptyRef();
		EndIf;	
		Object.BankAccount = DefaultBankAccount;
		// -- MisA 11/20/2014
	Else // 1, Null, ""
		Object.BankAccount = Constants.UndepositedFundsAccount.Get();
		//Items.BankAccount.ReadOnly = True;
	EndIf;
EndProcedure

&AtClient
Procedure ExchangeRateOnChange(Item)
	//UpdateExchangeRate();	
	// Update CashPayment, DocumentTotal, and Unapplied values
	ExchangeRateOnChangeAtServer();
EndProcedure

&AtServer 
Procedure ExchangeRateOnChangeAtServer()
	CashReceiptMethods.AdditionalPaymentCall(Object,PayRef);
EndProcedure

&AtServer
// Updates exchange rate based on set exchange rate
// LineItem reporting balance is set based on exchange rate
Procedure UpdateExchangeRate()
	//If Object.ExchangeRate = 0 Then 	// --MisA 11/20/2014
		Object.ExchangeRate = GeneralFunctions.GetExchangeRate(Object.Date, CompanyCurrency());
	//EndIf;							// --MisA 11/20/2014
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
Procedure OnReadAtServer(CurrentObject)

	// Update lineitem balances.
	CashReceiptMethods.UpdateLineItemBalances(Object);

EndProcedure

&AtClient
Procedure BankAccountStartChoice(Item, ChoiceData, StandardProcessing)
	//StandardProcessing = False;
	//FormParameters = Undefined;
	//BankAccountStartChoiceAtServer(FormParameters);
	//OpenForm("ChartOfAccounts.ChartOfAccounts.ChoiceForm",FormParameters,Item);
	////ChoiceData1= Undefined;
EndProcedure

&AtServer
// Procedure sets parameters structure with filter by Account type and Currencies
//
Procedure BankAccountStartChoiceAtServer(FormParameters)
	//ChoiceParameters = New Structure;
	//ChoiceParameters.Insert("AccountType",Enums.AccountTypes.Bank);
	//Currencies = New Array;
	//Currencies.Add(Object.Company.DefaultCurrency);
	//Currencies.Add(Constants.DefaultCurrency.Get());
	//ChoiceParameters.Insert("Currency",Currencies);
	//FormParameters = New Structure("Filter",ChoiceParameters);
	//FormParameters.Insert("ChoiceMode",True);
EndProcedure

&AtClient
Procedure CheckObtainedData(KeyData)
	
	// Check whether job finished.
	If (TypeOf(KeyData) = Type("UUID")) Or (KeyData = Undefined) Then
		// Job is now pending.
	ElsIf TypeOf(KeyData) = Type("Array") Then 
		// Show results.
		
		MessageText = "";
		
		For Each Row In KeyData Do
			MessageText = MessageText + Row + Chars.LF;	
		EndDo;
		
		If ValueIsFilled(MessageText) Then
			ShowMessageBox(, MessageText);
		EndIf;
		
		//
		If BackgroundJobParameters[5].Value Then
			Close();
		EndIf;
		
	ElsIf TypeOf(KeyData) = Type("String") Then
		// Error message.
		
		//
		If BackgroundJobParameters[5].Value Then
			Close();
		EndIf;
		
	EndIf;
	
EndProcedure

#Region LONG_ACTION

// Attachable procedure, called as idle handler.
&AtClient
Procedure IdleHandlerLongAction() 
	
	// Process background job result.
	KeyData = CommonUseClient.ResultProcessingLongAction(ThisForm);
	CheckObtainedData(KeyData);
	
EndProcedure

#EndRegion

