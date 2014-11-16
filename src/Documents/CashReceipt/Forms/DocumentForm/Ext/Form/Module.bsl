&AtClient
Var BeforeWriteChoiceProcessed;

&AtServer
// The procedure selects all sales invoices and vendor returns having an unpaid balance
// and fills in line items of a cash receipt.
//
Procedure FillDocumentList(Company)
	
	Object.LineItems.Clear();
	
	Query = New Query;
	Query.Text = "SELECT
	             |	GeneralJournalBalance.AmountBalance AS BalanceFCY2,
				 |	GeneralJournalBalance.AmountBalance * ISNULL(ExchangeRates.Rate, 1) AS Balance,
				 |  ISNULL(ExchangeRates.Rate, 1) AS ExchangeRate,
				 |	0 AS Payment,
				 |	GeneralJournalBalance.ExtDimension2.Ref AS Document,
				 |	GeneralJournalBalance.ExtDimension2.Ref.Currency Currency2
				 |FROM
				 |  // Get due rests from accounting balance
	             |	AccountingRegister.GeneralJournal.Balance (,
				 |			Account IN (SELECT ARAccount FROM Document.SalesInvoice UNION SELECT APAccount FROM Document.PurchaseReturn WHERE Company = &Company),
				 |			,
				 |			ExtDimension1 = &Company
				 |			AND (ExtDimension2 REFS Document.SalesInvoice OR
	             |			     ExtDimension2 REFS Document.PurchaseReturn)) AS GeneralJournalBalance
				 |
				 |	// Calculate exchange rate for a document on a present moment
				 |	LEFT JOIN
				 |		InformationRegister.ExchangeRates.SliceLast(&Date, ) AS ExchangeRates
				 |	ON
				 |		GeneralJournalBalance.ExtDimension2.Ref.Currency = ExchangeRates.Currency
				 |
				 |ORDER BY
				 |  GeneralJournalBalance.ExtDimension2.Date";
				 
	Query.SetParameter("Date",    Object.Date);			 
	Query.SetParameter("Company", Company);
	
	NonCurrencyMatch = 0;
	ResultSelection = Query.Execute().Select();
	While ResultSelection.Next() Do
		//Display only if currency of lineitem matches company currency
		If ResultSelection.Currency2 = Company.DefaultCurrency Then
			LineItems = Object.LineItems.Add();
			FillPropertyValues(LineItems, ResultSelection);
		Else
			NonCurrencyMatch = NonCurrencyMatch + 1;
		EndIf;
		//Otherwise - here - we'll keep track of undisplayed lineitems here (pending)
	EndDo;
	
	If NonCurrencyMatch = 1 Then
		  Message(String(NonCurrencyMatch) + " invoice is not shown due to non-matching currency"); 
	ElsIf NonCurrencyMatch > 0 Then
		  Message(String(NonCurrencyMatch) + " invoices were not shown due to non-matching currency"); 
	EndIf;

EndProcedure

&AtServer
// The procedure selects all credit memos having an unpaid balance
// and fills in credit memos table of a cash receipt.
//
Procedure FillCreditMemos(Company)
	
	Object.CreditMemos.Clear();
	
	Query = New Query;
	Query.Text = "SELECT
				 |	-GeneralJournalBalance.AmountBalance AS BalanceFCY2,
				 |	-GeneralJournalBalance.AmountBalance * ISNULL(ExchangeRates.Rate, 1) AS Balance,
				 |  ISNULL(ExchangeRates.Rate, 1) AS ExchangeRate,
				 |	0 AS Payment,
				 |	GeneralJournalBalance.ExtDimension2.Ref AS Document,
				 |	GeneralJournalBalance.ExtDimension2.Ref.Currency Currency,
				 |  False AS Check
				 |FROM
				 |  // Get due rests from accounting balance
				 |	AccountingRegister.GeneralJournal.Balance(&Date,
				 |			Account IN (SELECT ARAccount FROM Document.SalesReturn WHERE Company = &Company AND ReturnType = VALUE(Enum.ReturnTypes.CreditMemo) UNION SELECT ARAccount FROM Document.CashReceipt WHERE Company = &Company),
				 |			,
				 |			ExtDimension1 = &Company AND
				 |          ((ExtDimension2 REFS Document.SalesReturn AND
				 |			ExtDimension2.ReturnType = VALUE(Enum.ReturnTypes.CreditMemo)) OR
				 |			ExtDimension2 REFS Document.CashReceipt))
				 |			AS GeneralJournalBalance
				 |
				 |	// Calculate exchange rate for a document on a present moment
				 |	LEFT JOIN
				 |		InformationRegister.ExchangeRates.SliceLast(&Date, ) AS ExchangeRates
				 |	ON
				 |		GeneralJournalBalance.ExtDimension2.Ref.Currency = ExchangeRates.Currency
				 |
				 |ORDER BY
				 |  GeneralJournalBalance.ExtDimension2.Date";				 
				 
	Query.SetParameter("Date",    ?(ValueIsFilled(Object.Ref), Object.Date, CurrentSessionDate()));
	Query.SetParameter("Company", Company);
	
	NonCurrencyMatch = 0;
	ResultSelection = Query.Execute().Select();
	While ResultSelection.Next() Do
		//Display only if currency of lineitem matches company currency
		If ResultSelection.Currency = Company.DefaultCurrency Then
			LineItems = Object.CreditMemos.Add();
			FillPropertyValues(LineItems, ResultSelection);
		Else
			NonCurrencyMatch = NonCurrencyMatch + 1;
		EndIf;
		//Otherwise - here - we'll keep track of undisplayed lineitems here (pending)
	EndDo;
	
	If NonCurrencyMatch = 1 Then
		  Message(String(NonCurrencyMatch) + " credit was not shown due to non-matching currency"); 
	ElsIf NonCurrencyMatch > 0 Then
		  Message(String(NonCurrencyMatch) + " credits were not shown due to non-matching currency"); 
	EndIf;
	
EndProcedure

&AtClient
// CompanyOnChange UI event handler. The procedure repopulates line items
// upon a company change.
//
Procedure CompanyOnChange(Item)
	
	Object.Currency = CommonUse.GetAttributeValue(Object.Company, "DefaultCurrency");
	
	EmailSet();
	
	// Set form exchange rate to company's latest
	UpdateExchangeRate();
	
	// Fill in current receivables
	FillDocumentList(Object.Company);
	// Fill in credit memos
	FillCreditMemos(Object.Company);
		
	If Object.LineItems.Count() > 0 Then
		Items.PayAllDoc.Visible = true;
		Items.SpaceFill.Visible = true;
	Else
		Items.PayAllDoc.Visible = false;
		Items.SpaceFill.Visible = false;
	Endif;

	CompanyOnChangeAtServer();
	
EndProcedure

&AtServer
Procedure CompanyOnChangeAtServer()
	If Object.Company.ARAccount <> ChartsofAccounts.ChartOfAccounts.EmptyRef() Then
		Object.ARAccount = Object.Company.ARAccount;
	Else
		DefaultCurrency = GeneralFunctionsReusable.DefaultCurrency();
		Object.ARAccount = DefaultCurrency.DefaultARAccount;
	EndIf;
EndProcedure

&AtClient
Procedure UnappliedCalc()
		
	TotalPay = 0;
	// Keep track of total lineitem payments
	For Each LineItem In Object.LineItems Do
			TotalPay = TotalPay + LineItem.Payment;
	EndDo;
		
	CredTotal = 0;
	For Each LineItem In Object.CreditMemos Do
			CredTotal = CredTotal + LineItem.Payment;
	EndDo;	
	
	// Unapplied payment amount is equal to the total cash payment + the total credits applied
	// - the amount paid in lineitems (which can include cash payments and credit payments)
	Object.UnappliedPayment = (Object.CashPayment + CredTotal) - TotalPay;
	
EndProcedure

&AtServer
Function CompanyCurrency()
	return Object.Company.DefaultCurrency;
EndFunction

&AtClient
Procedure CashPaymentOnChange(Item)
	
	// Marks that CashPayment was the first field to have applied a payment
	PayRef = True;

	CashDistribute = Object.CashPayment;
	
	// Sum total of current credit payments
	CreditTotal = 0;	
	For Each LineItemCM In Object.CreditMemos Do
			CreditTotal = CreditTotal + LineItemCM.Payment;
	EndDo;

	// Keep track of surplus credit to be applied
	CreditOverFlow = CreditTotal;

	
	For Each LineItem In Object.LineItems Do
		
		LineItem.Payment = 0;
		Balance = LineItem.BalanceFCY2;
			
		// If there is leftover credit to be applied, and there is still an amount to be paid for
		// a lineitem's balance, then apply the credit from CreditOverFlow
		While CreditOverFlow > 0 And LineItem.Payment < Balance Do
			AmountToPay = Balance - LineItem.Payment;
			If AmountToPay >= CreditOverFlow Then
				LineItem.Payment = LineItem.Payment + CreditOverFlow;
				CreditOverFlow = 0;
				LineItem.Check = true;
			Else
				LineItem.Payment = LineItem.Payment + AmountToPay;
				CreditOverFlow=  CreditOverFlow - AmountToPay;
				LineItem.Check = true;
			Endif;
		EndDo;
	EndDo;

	// Now that we have applied all of the credit, we now apply the cash payment amount
	For Each LineItem In Object.LineItems Do
		
		Balance = LineItem.BalanceFCY2;
		// If there is still cash left in CashDistribute to be applied, and there is still an amount to be paid 
		// for a lineitem's balance, apply cash from CashDistribute
		While CashDistribute > 0 And LineItem.Payment < Balance Do
			AmountToPay = Balance - LineItem.Payment;
			If AmountToPay >= CashDistribute Then
				LineItem.Payment = LineItem.Payment + CashDistribute;
				CashDistribute = 0;
				LineItem.Check = true;
			Else
				LineItem.Payment = LineItem.Payment + AmountToPay;
				CashDistribute=  CashDistribute - AmountToPay;
				LineItem.Check = true;
			Endif;
		EndDo;
		
		If LineItem.Payment = 0 Then
			LineItem.Check = False;
		EndIf;
	EndDo;
	
	// If there is leftover cash after applying cashpaymment to line items, the rest goes into
	// Unapplied payments
	If CashDistribute > 0 Then
		Object.UnappliedPayment = CashDistribute;
		UnappliedCalc();
	Elsif CashDistribute <= 0 And CreditTotal <= 0 Then
		Object.UnappliedPayment = 0;
	Endif;
	
	AdditionalPaymentCall();
					
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
			
	AdditionalPaymentCall();
			
EndProcedure

&AtClient
// Used to recalculate the CashPayment value and DocumentTotal values when there is a change in the document
Procedure AdditionalPaymentCall()

	DefaultCurrency = GeneralFunctionsReusable.DefaultCurrency();

	PayTotal = 0;	
	For Each LineItem In Object.LineItems Do
			PayTotal =  PayTotal + LineItem.Payment;			
	EndDo;
	
	CreditTotal = 0;
	For Each LineItemCM In Object.CreditMemos Do
			CreditTotal =  CreditTotal + LineItemCM.Payment;
	EndDo;
	
	// CashPayment amount is equal to the difference of applied payments - the credits applied
	If PayRef = False Then
		Object.CashPayment = PayTotal - CreditTotal;
	Endif;
	
	Object.DocumentTotalRC = Object.CashPayment * Object.ExchangeRate;
	Object.DocumentTotal = Object.CashPayment;

	UnAppliedCalc();
	
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
		Items.BankAccount.ReadOnly = False;
	Else // 1, Null, ""
		Items.BankAccount.ReadOnly = True;
	EndIf;
		
	If Object.BankAccount.IsEmpty() Then
		If Object.DepositType = "2" Then
			Object.BankAccount = Constants.BankAccount.Get();
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
	UpdateLineItemBalances();

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
	
	AdditionalCreditPay();
	
	// Invoke inherited payment change event
	//CreditMemosPaymentOnChange(Item)
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
			
	AdditionalPaymentCall();
	
EndProcedure


&AtClient
Procedure CreditMemosPaymentOnChange(Item)
		
	DefaultCurrency = GeneralFunctionsReusable.DefaultCurrency();
			
	If Items.CreditMemos.CurrentData.Payment > Items.CreditMemos.CurrentData.BalanceFCY2 Then
		Items.CreditMemos.CurrentData.Payment = Items.CreditMemos.CurrentData.BalanceFCY2;
	Endif;
	
	//Credit Memo Line Item Change
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
	
	AdditionalCreditPay();
		

EndProcedure

&AtClient
Procedure AdditionalCreditPay()
	
	CreditTotal = 0;	
	For Each LineItemCM In Object.CreditMemos Do
			CreditTotal = CreditTotal + LineItemCM.Payment;
	EndDo;
		
	AppliedCredit = CreditTotal;
		
	// subtract total credit amount from cashpayment
	PayTotal = 0;
	For Each LineItem In Object.LineItems Do
			PayTotal = PayTotal + LineItem.Payment;
	EndDo;
	
	
	DefaultCurrency = GeneralFunctionsReusable.DefaultCurrency();	
	
	CreditOverFlow = Items.CreditMemos.CurrentData.Payment;//CreditTotal;
		
	//Applies the credit amount to line items. Applies from top line items down, depending if a line item is full
	// and there is a leftover amount from the selected credit.
	If Items.CreditMemos.CurrentData.Check Then
	
		If CreditAppliedPositive > 0 Then
		
			For Each LineItem In Object.LineItems Do
								
				While CreditAppliedPositive > 0 And LineItem.Payment < LineItem.BalanceFCY2 Do
					AmountToPay = LineItem.BalanceFCY2 - LineItem.Payment;
					If AmountToPay >= CreditAppliedPositive Then
						LineItem.Payment = LineItem.Payment + CreditAppliedPositive;
						CreditAppliedPositive = 0;
						LineItem.Check = true;
					Else
						LineItem.Payment = LineItem.Payment + AmountToPay;
						CreditAppliedPositive =  CreditAppliedPositive - AmountToPay;
						LineItem.Check = true;
					Endif;
				EndDo;
					
			EndDo;
			
		ElsIf CreditAppliedNegative > 0 Then
			
			For Each LineItem In Object.LineItems Do
								
				While CreditAppliedNegative > 0 And LineItem.Payment > 0 Do
					If LineItem.Payment >= CreditAppliedNegative Then
						LineItem.Payment = LineItem.Payment - CreditAppliedNegative;
						CreditAppliedNegative = 0;
						If LineItem.Payment = 0 Then
							LineItem.Check = false;
						Else
							LineItem.Check = true;
						EndIf;

					Else
						LineItem.Payment = LineItem.Payment - CreditAppliedNegative;
						CreditOverFlow =  CreditOverFlow - CreditAppliedNegative;
						LineItem.Check = true;
					Endif;
				EndDo;
					
			EndDo;
			
		Else
			 For Each LineItem In Object.LineItems Do
								
				While CreditOverFlow > 0 And LineItem.Payment < LineItem.BalanceFCY2 Do
					AmountToPay = LineItem.BalanceFCY2 - LineItem.Payment;
					If AmountToPay >= CreditOverFlow Then
						LineItem.Payment = LineItem.Payment + CreditOverFlow;
						CreditOverFlow = 0;
						LineItem.Check = true;
					Else
						LineItem.Payment = LineItem.Payment + AmountToPay;
						CreditOverFlow=  CreditOverFlow - AmountToPay;
						LineItem.Check = true;
					Endif;
				EndDo;
					
			EndDo;

		EndIf;
		
	Endif;
	
	AppliedCredit = CreditOverFlow;
	UnappliedCalc();
	
EndProcedure

&AtServer
Function SessionTenant()
	
	Return SessionParameters.TenantValue;
	
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
		
	AdditionalPaymentCall();
	
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
	FillDocumentList(Object.Company);
	For Each Doc In Object.LineItems Do
		If Doc.Document = SalesInvoice Then
			Doc.Payment = Doc.BalanceFCY2;
			//Doc.Payment = Doc.BalanceFCY; //alan fix
			Object.CashPayment = Doc.BalanceFCY2;
			Object.DocumentTotal = Doc.BalanceFCY2;
			Object.DocumentTotalRC = Doc.BalanceFCY2 * Object.ExchangeRate;
		EndIf;
	EndDo;
	FillCreditMemos(Object.Company);

	
	
EndProcedure


&AtClient
Procedure DepositTypeOnChange(Item)
	DepositTypeOnChangeAtServer();
EndProcedure


&AtServer
Procedure DepositTypeOnChangeAtServer()
	If Object.DepositType = "2" Then
		Items.BankAccount.ReadOnly = False;
		Object.BankAccount = Constants.BankAccount.Get();
	Else // 1, Null, ""
		Object.BankAccount = Constants.UndepositedFundsAccount.Get();
		Items.BankAccount.ReadOnly = True;
	EndIf;
EndProcedure


&AtClient
Procedure ExchangeRateOnChange(Item)
	UpdateExchangeRate();	
	// Update CashPayment, DocumentTotal, and Unapplied values
	AdditionalPaymentCall();
EndProcedure

&AtServer
// Updates exchange rate based on set exchange rate
// LineItem reporting balance is set based on exchange rate
Procedure UpdateExchangeRate()
	If Object.ExchangeRate = 0 Then
		Object.ExchangeRate = GeneralFunctions.GetExchangeRate(Object.Date, CompanyCurrency());
	EndIf;
EndProcedure

&AtServer
Procedure UpdateLineItemBalances()
	
	Query = New Query;
	Query.Text = "SELECT
	             |	GeneralJournalBalance.AmountBalance AS BalanceFCY2,
	             |	GeneralJournalBalance.ExtDimension2.Ref AS Document,
	             |	CashReceiptLineItems.Document AS Document1,
	             |	CashReceiptLineItems.LineNumber,
	             |	""LineItems"" AS TabularSection
	             |FROM
	             |	Document.CashReceipt.LineItems AS CashReceiptLineItems
	             |		LEFT JOIN InformationRegister.ExchangeRates.SliceLast(&Date, ) AS ExchangeRates
	             |		ON CashReceiptLineItems.Ref.Currency = ExchangeRates.Currency
	             |		LEFT JOIN AccountingRegister.GeneralJournal.Balance(
	             |				,
	             |				Account IN
	             |					(SELECT
	             |						Document.SalesInvoice.ARAccount
	             |					FROM
	             |						Document.SalesInvoice
	             |				
	             |					UNION
	             |				
	             |					SELECT
	             |						Document.PurchaseReturn.APAccount
	             |					FROM
	             |						Document.PurchaseReturn
	             |					WHERE
	             |						Document.PurchaseReturn.Company = &Company),
	             |				,
	             |				ExtDimension1 = &Company
	             |					AND (ExtDimension2 REFS Document.SalesInvoice
	             |						OR ExtDimension2 REFS Document.PurchaseReturn)) AS GeneralJournalBalance
	             |		ON CashReceiptLineItems.Document = GeneralJournalBalance.ExtDimension2
	             |WHERE
	             |	CashReceiptLineItems.Ref = &Ref
				 |
				 |UNION ALL
				 |
				 |SELECT
				 |	-GeneralJournalBalance.AmountBalance AS BalanceFCY2,
				 |	GeneralJournalBalance.ExtDimension2.Ref AS Document,
				 |	CashReceiptCreditMemos.Document AS Document1,
				 |	CashReceiptCreditMemos.LineNumber,
				 |	""CreditMemos"" AS TabularSection
				 |FROM
				 |  Document.CashReceipt.CreditMemos As CashReceiptCreditMemos
				 |		LEFT JOIN InformationRegister.ExchangeRates.SliceLast(&Date, ) AS ExchangeRates
				 |		ON CashReceiptCreditMemos.Ref.Currency = ExchangeRates.Currency
				 |		LEFT JOIN AccountingRegister.GeneralJournal.Balance(
				 |			,
				 |			Account IN
				 |				(SELECT
				 |					Document.SalesReturn.ARAccount
				 |				FROM
				 |					Document.SalesReturn
				 |				WHERE
				 |					Document.SalesReturn.Company = &Company
				 |					AND Document.SalesReturn.ReturnType = VALUE(Enum.ReturnTypes.CreditMemo)
				 |			
				 |				UNION
				 |			
				 |				SELECT
				 |					Document.CashReceipt.ARAccount
				 |				FROM
				 |					Document.CashReceipt
				 |				WHERE
				 |					Document.CashReceipt.Company = &Company),
				 |			,
				 |			ExtDimension1 = &Company
				 |				AND (ExtDimension2 REFS Document.SalesReturn
				 |						AND ExtDimension2.ReturnType = VALUE(Enum.ReturnTypes.CreditMemo)
				 |					OR ExtDimension2 REFS Document.CashReceipt)) AS GeneralJournalBalance
				 |		ON CashReceiptCreditMemos.Document = GeneralJournalBalance.ExtDimension2
	             |WHERE
	             |	CashReceiptCreditMemos.Ref = &Ref";
				 
	Query.SetParameter("Date",  ?(ValueIsFilled(Object.Ref), Object.Date, CurrentSessionDate()));			 
	Query.SetParameter("Company", Object.Company);
	Query.SetParameter("Ref", Object.Ref);
	ResultQuery = Query.Execute().Unload();
	
	
	For Each LineRow In Object.LineItems Do
		FoundRows = ResultQuery.FindRows(New Structure("TabularSection, LineNumber", "LineItems", LineRow.LineNumber));
		If FoundRows.Count()>0 Then
			LineRow.BalanceFCY2 = FoundRows[0].BalanceFCY2;
		EndIf;

	EndDo;
	
	For Each CreditRow In Object.CreditMemos Do
		FoundRows = ResultQuery.FindRows(New Structure("TabularSection, LineNumber", "CreditMemos", CreditRow.LineNumber));
		If FoundRows.Count()>0 Then
				CreditRow.BalanceFCY2 = FoundRows[0].BalanceFCY2;
		EndIf;
	EndDo;
	
EndProcedure

&AtClient
Procedure AuditLogRecord(Command)
	
	FormParameters = New Structure();	
	FltrParameters = New Structure();
	FltrParameters.Insert("DocUUID", String(Object.Ref.UUID()));
	FormParameters.Insert("Filter", FltrParameters);
	OpenForm("CommonForm.AuditLogList",FormParameters, Object.Ref);
	

EndProcedure


