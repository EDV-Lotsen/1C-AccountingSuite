&AtClient
Var BeforeWriteChoiceProcessed;

&AtClient
// CompanyOnChange UI event handler. The procedure repopulates line items
// upon a company change.
//
Procedure CompanyOnChange(Item)
	
	Object.Currency = CommonUse.GetAttributeValue(Object.Company, "DefaultCurrency");
	
	EmailSet();
	
	CompanyOnChangeAtServer();
	
	If Object.LineItems.Count() > 0 Then
		Items.PayAllDoc.Visible = true;
		Items.SpaceFill.Visible = true;
	Else
		Items.PayAllDoc.Visible = false;
		Items.SpaceFill.Visible = false;
	Endif;
	
	UpdateTabTitles();
	
	If Object.CreditMemos.Count() > 0 Then 
		Items.Group2.CurrentPage = Items.CreditMemosGroup;
	EndIf;
	
EndProcedure

&AtServer
Procedure CompanyOnChangeAtServer()
	
	If Object.Company.ARAccount <> ChartsofAccounts.ChartOfAccounts.EmptyRef() Then
		Object.ARAccount = Object.Company.ARAccount;
	ElsIf Not Object.Currency.DefaultARAccount.IsEmpty() Then
		Object.ARAccount = Object.Currency.DefaultARAccount;	
	Else
		DefaultCurrency = GeneralFunctionsReusable.DefaultCurrency();
		Object.ARAccount = DefaultCurrency.DefaultARAccount;
	EndIf;
	
	// Fill in current receivables
	CashReceiptMethods.FillDocumentList(Object.Company,Object);
	
	// Fill in credit memos
	CashReceiptMethods.FillCreditMemos(Object.Company,Object);
	CashReceiptMethods.ClearTabularSections(Object, True, True);
	CashReceiptMethods.AdditionalPaymentCall(Object);
	
	UpdateFormula();
	
	LimitARAccountChoice();
	
EndProcedure

&AtServer
Procedure LimitARAccountChoice()
	
	NewArray = New Array();
	If Object.Company.Customer Then 
		NewArray.Add(Enums.AccountTypes.AccountsReceivable);
	EndIf;
	If Object.Company.Vendor Then 
		NewArray.Add(Enums.AccountTypes.AccountsPayable);
	EndIf;
	
	NewParam = New ChoiceParameter("Filter.AccountType", new FixedArray(NewArray));
	ParamArray = New Array();
	ParamArray.Add(NewParam);
	NewParams = New FixedArray(ParamArray);
	
	Items.ARAccount.ChoiceParameters = NewParams;
	
EndProcedure	

&AtServer
Function CompanyCurrency()
	
	Return Object.Company.DefaultCurrency;
	
EndFunction

&AtClient
// LineItemsPaymentOnChange UI event handler.
// The procedure calculates a document total in the foreign currency (DocumentTotal) and in the
// reporting currency (DocumentTotalRC).
//
Procedure LineItemsPaymentOnChange(Item)
	
	DefaultCurrency = GeneralFunctionsReusable.DefaultCurrency();
		
	TabularPartRow = Items.LineItems.CurrentData;
	TabularPartRow.Check = True;
	
	LimitPaymentWithDiscountAtServer(TabularPartRow.Document, TabularPartRow.BalanceFCY2, TabularPartRow.Payment, TabularPartRow.Discount);
	
	// If payment is none, uncheck the lineitem
	If TabularPartRow.Payment = 0 Then
		TabularPartRow.Check = False;
	Endif;
			
	LineItemsPaymentOnChangeAtServer();
			
EndProcedure

&AtServer
Procedure LineItemsPaymentOnChangeAtServer()
	CashReceiptMethods.AdditionalPaymentCall(Object);
	UpdateFormula();
EndProcedure

&AtClient
// The procedure deletes all line items which are not paid by this cash receipt
//
Procedure BeforeWrite(Cancel, WriteParameters)	
	
	WriteParameters.Insert("NewObject", Not ValueIsFilled(Object.Ref));
	
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
	If ReconciledDocumentsServerCall.DocumentRequiresExcludingFromBankReconciliation(Object, WriteParameters.WriteMode) Then
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
	
	If CommonUse.GetConstant("DiscountsAccount").IsEmpty() Then 
		If Object.DiscountAmount > 0 Then 
			Message("Discount Account isn't set. Please select Discount and Allowances Account in Settings.");
			Cancel = True;
		EndIf;	
	EndIf;	
	
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
	
	If WriteParameters.Property("NewObject") And WriteParameters.NewObject Then
		
	Else
		
		// Request user to repost subordinate documents.
		Structure = New Structure("Type, DocumentRef", "RepostSubordinateDocumentsOfCashReceipt", Object.Ref); 
		KeyData = CommonUseClient.StartLongAction(NStr("en = 'Re-posting linked transactions'"), Structure, ThisForm);
		If WriteParameters.Property("CloseAfterWrite") Then
			BackgroundJobParameters.Add(True);// [5]
		Else
			BackgroundJobParameters.Add(False);// [5]
		EndIf;
		CheckObtainedData(KeyData);
		
	EndIf;

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
		If Object.Company.ARAccount <> ChartsofAccounts.ChartOfAccounts.EmptyRef() Then
			Object.ARAccount = Object.Company.ARAccount;
		ElsIf Not Object.Currency.DefaultARAccount.IsEmpty() Then
			Object.ARAccount = Object.Currency.DefaultARAccount;
		EndIf;	
	EndIf;
	
	If Parameters.Property("SalesInvoice") Then
		ProcessNewCashReceipt(Parameters.SalesInvoice);
	EndIf;
	
	UseSOPrepayment = Constants.UseSOPrepayment.Get();
	If Parameters.Property("SalesOrderPrepayment") and UseSOPrepayment Then
		ProcessNewSOPrepayment(Parameters.SalesOrderPrepayment);
	EndIf;
		
	Items.Company.Title = GeneralFunctionsReusable.GetCustomerName();
	//Items.UnappliedPayment.ReadOnly = True;
	
	If Object.DepositType = "2" Then
		//Items.BankAccount.ReadOnly = False;
		Items.BankAccount.Enabled = True;
	Else // 1, Null, ""
		//Items.BankAccount.ReadOnly = True;
		Items.BankAccount.Enabled = False;
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
	
	If Object.Ref.IsEmpty() Then
		Object.EmailNote = Constants.CashReceiptFooter.Get();
	EndIf;
	
	// Update lineitem balances.
	CashReceiptMethods.UpdateLineItemBalances(Object);
	
	UpdateTabTitles();
	
	If Object.CreditMemos.Count() > 0 Then 
		Items.Group2.CurrentPage = Items.CreditMemosGroup;
	EndIf;	
	
	//Find a deposit document
	If Not Object.Ref.IsEmpty() Then
		
		Request = New Query("SELECT
		                    |	UndepositedDocuments.Recorder
		                    |FROM
		                    |	AccumulationRegister.UndepositedDocuments AS UndepositedDocuments
		                    |WHERE
		                    |	UndepositedDocuments.Document = &Ref
		                    |	AND UndepositedDocuments.RecordType = VALUE(AccumulationRecordType.Expense)");
		Request.SetParameter("Ref", Object.Ref);
		Res = Request.Execute();
		If Not Res.IsEmpty() Then
			Items.DepositDocument.Visible = True;
			Items.DepositType.Visible = False;
			Sel = Res.Select();
			Sel.Next();
			DepositDocument = Sel.Recorder;
		Else
			Items.DepositDocument.Visible = False;
			Items.DepositType.Visible = True;
		EndIf;
		
	Else
		
		Items.DepositDocument.Visible = False;		
		Items.DepositType.Visible = True;
		
	EndIf;
	
	If UseSOPrepayment And (Not Object.SalesOrder.IsEmpty()) Then // can be set only if object is created based on SO, by dedicated button.
		Items.Documents.Visible = False;
		Items.CreditMemosGroup.Visible = False;
		Items.Company.ReadOnly = True;
		Items.SalesOrder.ReadOnly = True;
	EndIf;
	
	If Not UseSOPrepayment Then 
		Items.CreditMemosSalesOrder.Visible = False;
		Items.LineItemsSalesOrder.Visible = False;
	EndIf;	
	
	LimitARAccountChoice();
	
	ProcessVisibilityOfDiscountFields();
	
	UpdateFormula();
	
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
	
	DefaultCurrency = GeneralFunctionsReusable.DefaultCurrency();
	
	If Items.CreditMemos.CurrentData.Check Then
		Items.CreditMemos.CurrentData.Payment = Items.CreditMemos.CurrentData.BalanceFCY2;
	Else
		Items.CreditMemos.CurrentData.Payment = 0;
	EndIf;
	
	CheckOnChangeAtServer();

EndProcedure

&AtServer
Procedure CheckOnChangeAtServer()
	CashReceiptMethods.CashPaymentCalculation(Object);
	UpdateFormula();
EndProcedure

&AtClient
// Fills payment amount for lineitem based on lineitem balance
Procedure Check2OnChange(Item)

	DefaultCurrency = GeneralFunctionsReusable.DefaultCurrency();
	
	If Items.LineItems.CurrentData.Check Then
		CurrentRow = Items.LineItems.CurrentData;
		FillPaymentWithDiscountAtServer(CurrentRow.Document, CurrentRow.BalanceFCY2, CurrentRow.Payment, CurrentRow.Discount);
		RecalcPayment = True;
	Else
		Items.LineItems.CurrentData.Discount = 0;
		Items.LineItems.CurrentData.Payment = 0;
		RecalcPayment = False;
	EndIf;
	Check2OnChangeAtServer(RecalcPayment);
		
EndProcedure

&AtServer
Procedure FillPaymentWithDiscountAtServer(CurrentDocument, CurrentBalance, CurrentPayment, CurrentDiscount)
	CashReceiptMethods.FillPaymentWithDiscount(Object, CurrentDocument, CurrentBalance, CurrentPayment, CurrentDiscount);
EndProcedure

&AtServer
Procedure LimitPaymentWithDiscountAtServer(CurrentDocument, CurrentBalance, CurrentPayment, CurrentDiscount)
	CashReceiptMethods.LimitPaymentWithDiscount(Object, CurrentDocument, CurrentBalance, CurrentPayment, CurrentDiscount);
EndProcedure

&AtServer
Procedure Check2OnChangeAtServer(RecalcPayment)
	CashReceiptMethods.AdditionalPaymentCall(Object);
	UpdateFormula();
EndProcedure

&AtClient
Procedure CreditMemosPaymentOnChange(Item)
	
	DefaultCurrency = GeneralFunctionsReusable.DefaultCurrency();
	
	If Items.CreditMemos.CurrentData.Payment > Items.CreditMemos.CurrentData.BalanceFCY2 Then
		Items.CreditMemos.CurrentData.Payment = Items.CreditMemos.CurrentData.BalanceFCY2;
	Endif;
	
	If Items.CreditMemos.CurrentData.Payment = 0 Then
		Items.CreditMemos.CurrentData.Check = False;
	Else 	
		Items.CreditMemos.CurrentData.Check = True;
	Endif;   
	
	CreditMemosPaymentOnChangeAtServer();
	
EndProcedure

&AtServer
Procedure CreditMemosPaymentOnChangeAtServer()
	CashReceiptMethods.CashPaymentCalculation(Object);
	UpdateFormula();
EndProcedure

&AtClient
Procedure UnappliedPaymentOnChange(Item)
	UnappliedPaymentOnChangeAtServer();
EndProcedure

&AtServer
Procedure UnappliedPaymentOnChangeAtServer()
	CashReceiptMethods.AdditionalPaymentCall(Object,false);
	UpdateFormula();
EndProcedure

&AtServer
Function IsPosted()
	Return Object.Ref.Posted;	
EndFunction

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
		FillPaymentWithDiscountAtServer(LineItem.Document, LineItem.BalanceFCY2, LineItem.Payment, LineItem.Discount);
	EndDo;
		
	PayAllDocAtServer();
	
EndProcedure

&AtServer
Procedure PayAllDocAtServer()
	CashReceiptMethods.AdditionalPaymentCall(Object);	
	UpdateFormula();
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
	
	Object.Date = CurrentDate();
	
	Object.Company = SalesInvoice.Company;
	
	EmailSet();
	
	If Object.Company.ARAccount <> ChartsofAccounts.ChartOfAccounts.EmptyRef() Then
		Object.ARAccount = Object.Company.ARAccount;
	ElsIf Not Object.Currency.DefaultARAccount.IsEmpty() Then
		Object.ARAccount = Object.Currency.DefaultARAccount;
	Else
		DefaultCurrency = GeneralFunctionsReusable.DefaultCurrency();
		Object.ARAccount = DefaultCurrency.DefaultARAccount;
	EndIf;
	

	Object.Currency = CompanyCurrency();
	If Object.Currency.IsEmpty() Then
		Object.Currency = Object.ARAccount.Currency;
	EndIf;
	
	Object.ExchangeRate = GeneralFunctions.GetExchangeRate(Object.Date, Object.Currency);

	
	If Object.LineItems.Count() > 0 Then
		Items.PayAllDoc.Visible = true;
		Items.SpaceFill.Visible = true;
	Else
		Items.PayAllDoc.Visible = false;
		Items.SpaceFill.Visible = false;
	Endif;
	
	CashReceiptMethods.FillDocumentList(Object.Company,Object);
	For Each Doc In Object.LineItems Do
		If Doc.Document = SalesInvoice Then
			FillPaymentWithDiscountAtServer(Doc.Document, Doc.BalanceFCY2, Doc.Payment, Doc.Discount);
		EndIf;
	EndDo;
	
	CashReceiptMethods.FillCreditMemos(Object.Company,Object);
	
	CashReceiptMethods.AdditionalPaymentCall(Object);	
	
EndProcedure

&AtServer
Procedure ProcessNewSOPrepayment(SalesOrder)
	
	Object.Date = CurrentDate();
	Object.Company = SalesOrder.Company;
	//Object.SOPrepayment = True;
	Object.SalesOrder = SalesOrder;
	
	EmailSet();
	Object.Currency = CompanyCurrency();
	
	If Object.Currency.IsEmpty() Then
		Object.Currency = Constants.DefaultCurrency;
	EndIf;
	
	Object.ExchangeRate = GeneralFunctions.GetExchangeRate(Object.Date, Object.Currency);
	
	If Not Object.Currency.DefaultPrepaymentAR.IsEmpty() Then
		Object.ARAccount = Object.Currency.DefaultPrepaymentAR;
	EndIf;
	
	LimitARAccountChoice();
	
	Object.PaymentMethod = Catalogs.PaymentMethods.Check;
	Object.CashPayment = Object.SalesOrder.DocumentTotal;
	
	PaymentsWereChangedManually = True;
	
	CashReceiptMethods.AdditionalPaymentCall(Object, PaymentsWereChangedManually);	
	UpdateFormula();	
	
EndProcedure

&AtClient
Procedure DepositTypeOnChange(Item)
	DepositTypeOnChangeAtServer();
EndProcedure


&AtServer
Procedure DepositTypeOnChangeAtServer()
	If Object.DepositType = "2" Then
		//Items.BankAccount.ReadOnly = False;
		Items.BankAccount.Enabled = True;
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
		Items.BankAccount.Enabled = False;
	EndIf;
EndProcedure

&AtClient
Procedure ExchangeRateOnChange(Item)
	
	ExchangeRateOnChangeAtServer();
	
EndProcedure

&AtServer 
Procedure ExchangeRateOnChangeAtServer()
	CashReceiptMethods.AdditionalPaymentCall(Object, False);
	UpdateFormula();
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

&AtServer
Procedure UpdateTabTitles()
	InvoicesCount    = Object.LineItems.Count();
	CreditCount = Object.CreditMemos.Count();
	Items.Documents.Title = StringFunctionsClientServer.SubstituteParametersInString(NStr("en = 'Invoices [%1]'"),    InvoicesCount);
	Items.CreditMemosGroup.Title  = StringFunctionsClientServer.SubstituteParametersInString(NStr("en = 'Credits [%1]'"), CreditCount);	
EndProcedure	

&AtClient
Procedure LineItemsDiscountOnChange(Item)
	
	TabularPartRow = Items.LineItems.CurrentData;
	// Limit the payment to at most the BalanceFCY and Discount
	If TabularPartRow.Payment > 0 Then 
		
		If (TabularPartRow.Payment + TabularPartRow.Discount) > TabularPartRow.BalanceFCY2 Then
			TabularPartRow.Discount = TabularPartRow.BalanceFCY2 - TabularPartRow.Payment;
		Endif;
		LineItemsDiscountOnChangeAtServer();
	Else 
		TabularPartRow.Discount = 0;
	EndIf;
EndProcedure

&AtServer
Procedure LineItemsDiscountOnChangeAtServer()
	CashReceiptMethods.AdditionalPaymentCall(Object);
	UpdateFormula();
EndProcedure

&AtServer
Procedure UpdateFormula()
	
	TotalFormula = 
	"Total Invoices ("+Object.LineItems.Total("Payment")+") - " + 
	"Credits ("+Object.CreditMemos.Total("Payment")+") + "+
	"Unapplied Payments ("+Object.UnappliedPayment+") = "+
	"Total Cash Payment ("+Object.CashPayment+")  ";
	
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

// temporary procedure to easy Hide or unhide Discount fields.
// Made to hide Discounts utility, must be deletted after Discounts will be in production
// and remove call from "OnCreateAtServer"
&AtServer
Procedure ProcessVisibilityOfDiscountFields()
	
	Visible = Constants.UseExtendedDiscountsInPayments.Get();
	
	Items.DiscountAmount.Visible = Visible;
	Items.LineItemsDiscountDate.Visible = Visible;
	Items.LineItemsDiscount.Visible = Visible;
	
EndProcedure
