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
	             |	GeneralJournalBalance.AmountBalance AS BalanceFCY,
				 |	GeneralJournalBalance.AmountBalance * ISNULL(ExchangeRates.Rate, 1) AS Balance,
				 |  ISNULL(ExchangeRates.Rate, 1) AS ExchangeRate,
				 |	0 AS Payment,
				 |	GeneralJournalBalance.ExtDimension2.Ref AS Document,
				 |	GeneralJournalBalance.ExtDimension2.Ref.Currency Currency
				 |FROM
				 |  // Get due rests from accounting balance
	             |	AccountingRegister.GeneralJournal.Balance (&Date,
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
				 
	Query.SetParameter("Date",    ?(ValueIsFilled(Object.Ref), Object.Date, CurrentSessionDate()));
	Query.SetParameter("Company", Company);
	
	ResultSelection = Query.Execute().Select();
	While ResultSelection.Next() Do
		LineItems = Object.LineItems.Add();
		FillPropertyValues(LineItems, ResultSelection);
	EndDo;
	
EndProcedure

&AtServer
// The procedure selects all credit memos having an unpaid balance
// and fills in credit memos table of a cash receipt.
//
Procedure FillCreditMemos(Company)
	
	Object.CreditMemos.Clear();
	
	Query = New Query;
	Query.Text = "SELECT
				 |	-GeneralJournalBalance.AmountBalance AS BalanceFCY,
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
	
	ResultSelection = Query.Execute().Select();
	While ResultSelection.Next() Do
		LineItems = Object.CreditMemos.Add();
		FillPropertyValues(LineItems, ResultSelection);
	EndDo;
	
EndProcedure

//&AtServer
// The procedure applies all of the amounts of credit memos
// to the amounts of sales invoices / purchase returns.
//
//Procedure DistributeCreditMemos(RecalculateCreditMemoPayments = True)
//	
//	DefaultCurrency = GeneralFunctionsReusable.DefaultCurrency();
//	LineItem = Undefined;
//	CurrentInvoice = 0;
//	CurrentBalanceRC = 0;
//	CurrentBalance = 0;
//	CurrentCurrency = Undefined;
//	CurrentRate = 0;
//	
//	// Fill maximum possible netting amount
//	For Each LineItemCM In Object.CreditMemos Do
//		// Get credit memo amount for distribution
//		If RecalculateCreditMemoPayments Then
//			CMMxPayment = LineItemCM.BalanceFCY;  // Max available payment value for credit memo - document total
//			CMAmount    = LineItemCM.BalanceFCY;
//			CMAmountRC  = LineItemCM.Balance;
//		Else
//			CMMxPayment = LineItemCM.Payment; // Max available payment value for credit memo - defined by user
//			CMAmount    = LineItemCM.Payment;
//			CMAmountRC  = ?(LineItemCM.Currency = DefaultCurrency, LineItemCM.Payment,
//						  ?(LineItemCM.Payment = LineItemCM.BalanceFCY, LineItemCM.Balance, Round(LineItemCM.Payment * LineItemCM.ExchangeRate, 2)));
//		EndIf;
//		CMCurrency = LineItemCM.Currency;
//		CMRate	   = LineItemCM.ExchangeRate;
//		// Clear payment value (will be renewed within calculation)
//		LineItemCM.Payment = 0;
//		
//		// Cycle through invoices until there is something do distribute
//		While CMAmountRC > 0 Do
//			
//			// Find next invoice to close
//			If CurrentBalanceRC = 0 Then
//				If CurrentInvoice = Object.LineItems.Count() Then
//					// All due already distributed
//					Break;
//				Else
//					// Get new invoice
//					CurrentInvoice = CurrentInvoice +1;
//					LineItem       = Object.LineItems.Get(CurrentInvoice-1);
//					CurrentBalance     = LineItem.BalanceFCY;
//					CurrentBalanceRC   = LineItem.Balance;
//					CurrentCurrency= LineItem.Currency;
//					CurrentRate    = LineItem.ExchangeRate;
//					// Clear payment value (will be renewed within calculation)
//					LineItem.Payment = 0;
//				EndIf;
//			EndIf;
//			
//			// Find possible amount to close
//			If ?(CMCurrency = CurrentCurrency, CMAmount > CurrentBalance, CMAmountRC > CurrentBalanceRC) Then
//				
//				// Claculate CM payment and rest of a due
//				If CMCurrency = CurrentCurrency Then
//					CMPayment = CurrentBalance;
//				Else f
//					CMPayment = Round(CMAmount * CurrentBalanceRC / CMAmountRC, 2);
//				EndIf;
//				
//				// Save new payment to credit memo
//				LineItemCM.Payment = LineItemCM.Payment + CMPayment;
//				If Not LineItemCM.Check Then LineItemCM.Check = True; EndIf;
//				// Recalculate rest of CM due
//				CMAmount   = ?(CMPayment > CMAmount, 0, CMAmount - CMPayment);
//				CMAmountRC = ?(CMAmount > 0,            CMAmountRC - Round(CMPayment * CMRate, 2), 0);
//				
//				// Close an invoice/return DueFCY -> Payment
//				LineItem.Payment = LineItem.BalanceFCY;
//				// Clear rest of a due
//				CurrentBalance = 0;
//				CurrentBalanceRC = 0;
//				
//			Else // ?(CMCurrency = CurrentCurrency, CMAmount <= CurrentDue, CMAmountRC <= CurrentDueRC)
//				
//				// Claculate CM payment and rest of a due
//				If CurrentCurrency = CMCurrency Then
//					CurrentPayment = CMAmount;
//				Else
//					CurrentPayment = Round(CurrentBalance * CMAmountRC / CurrentBalanceRC, 2);
//				EndIf;
//				
//				// Save new payment to invoice/return
//				LineItem.Payment = LineItem.Payment + CurrentPayment;
//				// Recalculate rest of a invoice/return due
//				CurrentBalance   = ?(CurrentPayment > CurrentBalance, 0, CurrentBalance - CurrentPayment);
//				CurrentBalanceRC = ?(CurrentBalance > 0,                 CurrentBalanceRC - Round(CurrentPayment * CurrentRate, 2), 0);
//				
//				// Close the credit memo CMMxPayment(DueFCY or User defined) -> Payment
//				LineItemCM.Payment = CMMxPayment;
//				If Not LineItemCM.Check Then LineItemCM.Check = True; EndIf;
//				// Clear rest of CM due
//				CMAmount   = 0;
//				CMAmountRC = 0;
//			EndIf;	
//		EndDo;
//				
//	EndDo;
//	
//	// Clear rest invoice/return lines
//	For i = CurrentInvoice To Object.LineItems.Count()-1 Do
//		Object.LineItems[i].Payment = 0;
//	EndDo;
//	
//EndProcedure

//&AtServer
// The procedure applies the amount paid by the customer to rest of invoices
// to the amounts of sales invoices / purchase returns.
//
//Procedure DistributeCashPayment()
//	
//	DefaultCurrency = GeneralFunctionsReusable.DefaultCurrency();
//	LineItem = Undefined;
//	CurrentInvoice = 0;
//	CurrentBalanceRC = 0;
//	CurrentBalance = 0;
//	CurrentCurrency = Undefined;
//	CurrentRate = 0;
//	
//	// Fill/distribute paid amount on the rest of invoices
//	MxPayment = Object.CashPayment;
//	Amount    = MxPayment;
//	Rate      = ?(Object.Currency = DefaultCurrency, 1,                  GeneralFunctions.GetExchangeRate(Object.Date, Object.Currency));
//	AmountRC  = ?(Object.Currency = DefaultCurrency, Object.CashPayment, Round(Object.CashPayment * Rate, 2));
//	
//	// Cycle through invoices until there is something do distribute
//	While AmountRC > 0 Do
//		
//		// Find next invoice to close
//		If CurrentBalanceRC = 0 Then
//			If CurrentInvoice = Object.LineItems.Count() Then
//				// All due already distributed
//				Break;
//			Else
//				// Get new invoice
//				CurrentInvoice   = CurrentInvoice +1;
//				LineItem         = Object.LineItems.Get(CurrentInvoice-1);
//				CurrentBalance   = LineItem.BalanceFCY;
//				CurrentBalanceRC = LineItem.Balance;
//				CurrentCurrency  = LineItem.Currency;
//				CurrentRate      = LineItem.ExchangeRate;
//				If Object.CreditMemos.Count() > 0 Then
//					CurrentPaid  = LineItem.Payment;
//				Else // Credit memos are not applied.
//					CurrentPaid  = 0;
//				EndIf;
//			EndIf;
//		EndIf;
//		
//		// Find possible amount to close
//		If ?(Object.Currency = CurrentCurrency, Amount > (CurrentBalance-CurrentPaid), Amount > (Round(Amount * CurrentBalanceRC / AmountRC, 2) - CurrentPaid)) Then
//			
//			// Claculate payment and rest of a due
//			If Object.Currency = CurrentCurrency Then
//				Payment = CurrentBalance - CurrentPaid;
//			Else
//				Payment = Round(Amount * CurrentBalanceRC / AmountRC, 2) - CurrentPaid;
//			EndIf;
//			
//			// Recalculate rest of CM due
//			Amount   = ?(Payment > Amount, 0, Amount - Payment);
//			AmountRC = ?(Amount > 0,          AmountRC - Round(Payment * Rate, 2), 0);
//			
//			// Close an invoice/return DueFCY -> Payment
//			LineItem.Payment = LineItem.BalanceFCY;
//			// Clear rest of a due
//			CurrentBalance = 0;
//			CurrentBalanceRC = 0;
//			
//		Else // ?(Currency = CurrentCurrency, Amount <= CurrentDue-CurrentPaid, AmountRC <= Round(Amount * CurrentDueRC / AmountRC, 2) - CurrentPaid
//			
//			// Claculate payment and rest of a due
//			If CurrentCurrency = Object.Currency Then
//				CurrentPayment = Amount;
//			Else
//				CurrentPayment = Round(CurrentBalance * AmountRC / CurrentBalanceRC, 2);
//			EndIf;
//			
//			// Save new payment to invoice/return
//			LineItem.Payment = CurrentPaid + CurrentPayment;
//			// Recalculate rest of a invoice/return due
//			CurrentBalance   = ?(CurrentPayment > CurrentBalance, 0, CurrentBalance - CurrentPayment);
//			CurrentBalanceRC = ?(CurrentBalance > 0,                 CurrentBalanceRC - Round(CurrentPayment * CurrentRate, 2), 0);
//			
//			// Clear rest of payment
//			Amount   = 0;
//			AmountRC = 0;
//		EndIf;	
//	EndDo;
//	
//	// Remove the rest of cash payment while in automatic distribution
//	If Amount > 0 Then
//		Object.UnappliedPayment = Amount;
//		// Beta: Currently will not be used: unapplied payment will be used instead.
//		// Object.CashPayment = MxPayment - Amount;
//	EndIf;
//	
//EndProcedure

&AtClient
// CompanyOnChange UI event handler. The procedure repopulates line items
// upon a company change.
//
Procedure CompanyOnChange(Item)
	
	//Object.CompanyCode = CommonUse.GetAttributeValue(Object.Company, "Code");
	
	EmailSet();
	// Fill in current receivables
	FillDocumentList(Object.Company);
	// Fill in credit memos
	FillCreditMemos(Object.Company);
	// Distribute credit memos on receivables
	//DistributeCreditMemos();
	// Distribute paid amount on receivables
	//DistributeCashPayment();
	
	// Update totals
	//LineItemsPaymentOnChange(Items.LineItemsPayment);
	
	//Object.BalChange = 0;	
	//For Each LineItem In Object.LineItems Do
	//		//CreditTotal =  CreditTotal + LineItemCM.Payment;
	//		Object.BalChange = Object.BalChange + LineItem.Balance;
	//EndDo;
	RemainingBalance();
	
	Object.BalanceTotal = Object.BalChange;
	
	If Object.LineItems.Count() > 0 Then
		Items.PayAllDoc.Visible = true;
	Else
		Items.PayAllDoc.Visible = false;
	Endif;

	
EndProcedure

&AtClient
Procedure RemainingBalance()

	Object.BalChange = 0;	
	For Each LineItem In Object.LineItems Do
			//CreditTotal =  CreditTotal + LineItemCM.Payment;
			Object.BalChange = Object.BalChange + LineItem.Balance - LineItem.Payment;
	EndDo;
		
		

EndProcedure

&AtClient
Procedure UnappliedCalc()
	
	DefaultCurrency = GeneralFunctionsReusable.DefaultCurrency();
	CompanyCurrency = CompanyCurrency();
	
	TotalPay = 0;
	BalTotal = 0;
	For Each LineItem In Object.LineItems Do

			TotalPay = TotalPay + LineItem.Payment;
			BalTotal = BalTotal + LineItem.Balance;
	EndDo;
		
	CredTotal = 0;
	For Each LineItem In Object.CreditMemos Do

			CredTotal = CredTotal + LineItem.Payment;
	EndDo;	
	
	If CompanyCurrency = DefaultCurrency Then
			Object.UnappliedPayment = (Object.CashPayment + CredTotal) - TotalPay;

		Else
			Rate = GeneralFunctions.GetExchangeRate(Object.Date, CompanyCurrency);
			CashDistribute = Object.CashPayment/Rate;
			Object.UnappliedPayment = (CashDistribute + CredTotal) - TotalPay; 
	Endif;

	
	//Object.UnappliedPayment = (Object.CashPayment + CredTotal) - TotalPay; 
	
EndProcedure

&AtServer
Function CompanyCurrency()
	return Object.Company.DefaultCurrency;
EndFunction

&AtClient
Procedure CashPaymentOnChange(Item)
	DefaultCurrency = GeneralFunctionsReusable.DefaultCurrency();
	// Distribute paid amount on receivables
	//DistributeCashPayment();
	
	// Update totals
	//LineItemsPaymentOnChange(Items.LineItemsPayment);
	PayRef = True;
	
	If ManualCheck = False Then

	
	    CompanyCurrency = CompanyCurrency();
		CurrencyMatch = True;
		
		If CompanyCurrency = DefaultCurrency Then
			CashDistribute = Object.CashPayment;
			CurrencyMatch = True;
		Else
			Rate = GeneralFunctions.GetExchangeRate(Object.Date, CompanyCurrency);
			CashDistribute = Object.CashPayment/Rate;
			CurrencyMatch = False;
			
		Endif;
				
		
		CreditTotal = 0;	
		For Each LineItemCM In Object.CreditMemos Do
				//CreditTotal =  CreditTotal + LineItemCM.Payment;
				CreditTotal = CreditTotal + LineItemCM.Payment;
		EndDo;

		CreditOverFlow = CreditTotal;

		
			For Each LineItem In Object.LineItems Do
				
				LineItem.Payment = 0;
				Balance = 0;
				If CurrencyMatch = False Then
					Balance = LineItem.BalanceFCY;
				Else
					Balance = LineItem.Balance;
				Endif;
					
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
		
		
			For Each LineItem In Object.LineItems Do
				
				Balance = 0;
				If CurrencyMatch = False Then
					Balance = LineItem.BalanceFCY;
				Else
					Balance = LineItem.Balance;
				Endif;

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
			EndDo;
			
			If CashDistribute > 0 Then
				Object.UnappliedPayment = CashDistribute;
				UnappliedCalc();
			Elsif CashDistribute <= 0 And Object.CreditTotal <= 0 Then
				Object.UnappliedPayment = 0;
			Endif;
			
			//Endif;
		
	Endif;

EndProcedure

&AtClient
// LineItemsPaymentOnChange UI event handler.
// The procedure calculates a document total in the foreign currency (DocumentTotal) and in the
// reporting currency (DocumentTotalRC).
//
Procedure LineItemsPaymentOnChange(Item)
	
	DefaultCurrency = GeneralFunctionsReusable.DefaultCurrency();
	//
	//// Update document totals
	//DocumentTotalRC = 0;
	//For Each Row In Object.LineItems Do
	//	If Row.Currency = DefaultCurrency Then
	//		DocumentTotalRC = DocumentTotalRC + Row.Payment;
	//	Else
	//		DocumentTotalRC = DocumentTotalRC + Round(Row.Payment * Row.ExchangeRate, 2);
	//	EndIf;
	//EndDo;
	//Object.DocumentTotal = Object.LineItems.Total("Payment");
	//Object.DocumentTotalRC = DocumentTotalRC;
	//Object.UnappliedPayment = Max(Object.CashPayment - DocumentTotalRC, 0);
	If ManualCheck = False Then 
	
		If Items.LineItems.CurrentData.Check = False Then
			Items.LineItems.CurrentData.Check = True;
		Endif;

		
		TabularPartRow = Items.LineItems.CurrentData;
		
		
		If TabularPartRow.Currency = DefaultCurrency Then
			If TabularPartRow.Payment > TabularPartRow.Balance Then
				TabularPartRow.Payment = TabularPartRow.Balance;
			Endif;
			
		Elsif TabularPartRow.Payment > TabularPartRow.BalanceFCY Then
			  TabularPartRow.Payment = TabularPartRow.BalanceFCY;
		Endif;
		
		If TabularPartRow.Payment = 0 Then
			TabularPartRow.Check = False;
		Endif;
		
		PayTotal = 0;
		CreditTotal = 0;
		Object.BalChange = Object.BalanceTotal;
		
		For Each LineItem In Object.LineItems Do
			
				If LineItem.Currency = DefaultCurrency Then
					PayTotal =  PayTotal + LineItem.Payment;
					CreditTotal = CreditTotal + LineItem.CreditApplied;
				Else
					PayTotal =  PayTotal + LineItem.Payment * LineItem.ExchangeRate;
					//CreditTotal = CreditTotal + LineItem.CreditApplied;
				Endif;
				
		EndDo;
				
		//Object.UnappliedPayment = Object.CashPayment - PayTotal;
				
		//Object.DocumentTotalRC = Object.CashPayment;
		Object.DocumentTotal = Object.CashPayment;
		CreditTotal = 0;
		For Each LineItemCM In Object.CreditMemos Do
				CreditTotal =  CreditTotal + LineItemCM.Payment;
				//Object.AppliedCredit = CreditTotal + LineItemCM.Payment;
		EndDo;
		PaymentTotal = Object.DocumentTotalRC;
		NumberOfLines = Object.LineItems.Count() - 1;
		While NumberOfLines >=0 Do
			
			PaymentTotal = PaymentTotal + Object.LineItems[NumberOfLines].Payment;		
			NumberOfLines = NumberOfLines - 1;
			
		EndDo;
				
		If PayRef = False Then
			Object.CashPayment = PayTotal - CreditTotal;
		Endif;

		UnAppliedCalc();


	
	Endif;
			
EndProcedure

&AtClient
Procedure AdditionalPaymentCall()

	DefaultCurrency = GeneralFunctionsReusable.DefaultCurrency();

	PayTotal = 0;
	BalanceTotal = 0;
	
	For Each LineItem In Object.LineItems Do
		If LineItem.Currency = DefaultCurrency Then
			PayTotal =  PayTotal + LineItem.Payment;
		Else
			PayTotal =  PayTotal + LineItem.Payment * LineItem.ExchangeRate;
			
		Endif;
			
			
	EndDo;
			
	//Object.UnappliedPayment = Object.CashPayment - PayTotal;
			
	//Object.DocumentTotalRC = Object.CashPayment;
	Object.DocumentTotal = Object.CashPayment;
	CreditTotal = 0;
	For Each LineItemCM In Object.CreditMemos Do
			CreditTotal =  CreditTotal + LineItemCM.Payment;
			//Object.AppliedCredit = CreditTotal + LineItemCM.Payment;
	EndDo;
	
	//UnAppliedCalc();
	
	If PayRef = False Then
		Object.CashPayment = PayTotal - CreditTotal;
	Endif;

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
		CommonUseClient.ShowCustomMessageBox(ThisForm, "Bank reconciliation", "The transaction you are editing has been reconciled. Saving 
		|your changes could put you out of balance the next time you try to reconcile. 
		|To modify it you should exclude it from the Bank rec. document.", PredefinedValue("Enum.MessageStatus.Warning"));
	EndIf;
	
	DefaultCurrency = GeneralFunctionsReusable.DefaultCurrency();
	CompanyCurrency = CompanyCurrency();
	Rate = GeneralFunctions.GetExchangeRate(Object.Date, CompanyCurrency);
	
	PayTotal = 0;
	BalanceFCY = 0;
	For Each LineItem In Object.LineItems Do
				PayTotal =  PayTotal + LineItem.Payment;
				BalanceFCY = BalanceFCY + LineItem.BalanceFCY;
	EndDo;
			
	If PayTotal = 0 And Object.UnappliedPayment = 0 Then
		Message("No payment is being made.");
		Cancel = True;
		Return;
	EndIf;
		

	If CompanyCurrency = DefaultCurrency Then
		If PayTotal > (Object.CashPayment + Object.CreditTotal)  Then
			Message("Payment is greater than (Set Payment + Credit)");
			Cancel = True;
		Return;
		Endif;
	Else
		//If PayTotal > (Round((Object.CashPayment/Rate),2) + Object.CreditTotal)  Then
		//Message("Payment is greater than (Set Payment + Credit)");
		//Cancel = True;
		//Return;
		//Endif;
		
	EndIf;
	
 //   If Object.CreditTotal > 0 or Object.UnappliedPayment > 0 Then
 //   	
 //   	Mode = QuestionDialogMode.YesNo;
 //   	Answer = DoQueryBox(StringFunctionsClientServer.SubstituteParametersInString(
 //   			NStr("en='Total Payment: %1 %5, Cash Payment: %2 %6, Credit Used: %3 %5, Unapplied Payment %4 %5. /n Is This Correct?'"),PayTotal,Object.CashPayment,Object.CreditTotal,Object.UnappliedPayment,CompanyCurrency,DefaultCurrency), Mode, 0);
 //   	If Answer = DialogReturnCode.No Then
 //  			 Return;
 //   	EndIf;
 //

 //   	//ShowMessageBox(Undefined, StringFunctionsClientServer.SubstituteParametersInString(
 //   	//		NStr("en='Total Payment: %1 %5, Cash Payment: %2 %6, Credit Used: %3 %5, Unapplied Payment %4 %5'"),PayTotal,Object.CashPayment,Object.CreditTotal,Object.UnappliedPayment,CompanyCurrency,DefaultCurrency));
 //   Endif;


	
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

	//
	//If Object.DocumentTotalRC = 0 Then
		  Object.DocumentTotalRC = PayTotal*Rate;
		  Object.DocumentTotal = PayTotal;
	//Endif;
	
	//Object.Currency = Object.LineItems[0].Currency;
	//NumberOfRows = Object.LineItems.Count() - 1;
	//While NumberOfRows >= 0 Do
	//	
	//	If NOT Object.LineItems[NumberOfRows].Currency = Object.Currency Then
	//		Message("All documents in the line items need to have the same currency");
	//		Cancel = True;
	//		Return;
	//	EndIf;
	//	
	//	NumberOfRows = NumberOfRows - 1;
	//EndDo;
	
	// Request user confirmation on credit memo creation.
	//If Not BeforeWriteChoiceProcessed = True Then
	//	
	//	If  Object.UnappliedPayment > 0 And Object.UnappliedPaymentCreditMemo.IsEmpty() Then
	//		ChoiceProcessing = New NotifyDescription("BeforeWriteChoiceProcessing", ThisForm, WriteParameters);
	//		QuestionTitle    = "Unaplied payment found.";
	//		QuestionText     = StringFunctionsClientServer.SubstituteParametersInString(NStr("en = 'You have an unaplied payment %1.
	//						   |Create a credit memo for the unapplied amount?'"), Format(Object.UnappliedPayment, "NFD=2"));
	//		ShowQueryBox(ChoiceProcessing, QuestionText, QuestionDialogMode.OKCancel,,DialogReturnCode.OK, QuestionTitle);
	//		Cancel = True;
	//		Return;
	//	EndIf;
	//	
	//Else
	//	// Clear used confirmation flag.
	//	BeforeWriteChoiceProcessed = Undefined;
	//EndIf;
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	//Period closing
	If PeriodClosingServerCall.DocumentPeriodIsClosed(CurrentObject.Ref, CurrentObject.Date) Then
		PermitWrite = PeriodClosingServerCall.DocumentWritePermitted(WriteParameters);
		CurrentObject.AdditionalProperties.Insert("PermitWrite", PermitWrite);	
	EndIf;
	
	//If Object.Ref.IsEmpty() Then
	//
	//	MatchVal = Increment(Constants.CashReceiptLastNumber.Get());
	//	If Object.Number = MatchVal Then
	//		Constants.CashReceiptLastNumber.Set(MatchVal);
	//	Else
	//		If Increment(Object.Number) = "" Then
	//		Else
	//			If StrLen(Increment(Object.Number)) > 20 Then
	//				 Constants.CashReceiptLastNumber.Set("");
	//			Else
	//				Constants.CashReceiptLastNumber.Set(Increment(Object.Number));
	//			Endif;

	//		Endif;
	//	Endif;
	//Endif;
	//
	//If Object.Number = "" Then
	//	Message("Cash Receipt Number is empty");
	//	Cancel = True;
	//Endif;

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

EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("SalesInvoice") Then
		ProcessNewCashReceipt(Parameters.SalesInvoice);
	EndIf;
	
	//ConstantCashReceipt = Constants.CashReceiptLastNumber.Get();
	//If Object.Ref.IsEmpty() Then		
	//	
	//	Object.Number = Constants.CashReceiptLastNumber.Get();
	//Endif;

	//Title = "Receipt " + Object.Number + " " + Format(Object.Date, "DLF=D");
	
	Items.Company.Title = GeneralFunctionsReusable.GetCustomerName();
	Items.UnappliedPayment.ReadOnly = True;
	
	If Object.DepositType = "2" Then
		Items.BankAccount.ReadOnly = False;
	Else // 1, Null, ""
		Items.BankAccount.ReadOnly = True;
	EndIf;
	
	//If Object.BankAccount.IsEmpty() Then
	//	Object.BankAccount = Constants.BankAccount.Get();
	//Else
	//EndIf;
	
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
	EndIf;
	
	// Set checks for credit memos
	For Each LineItem In Object.CreditMemos Do
		If LineItem.Payment > 0 Then LineItem.Check = True; EndIf;
	EndDo;
	
	For Each LineItem In Object.LineItems Do
		If LineItem.Payment > 0 Then LineItem.Check = True; EndIf;
	EndDo;

	
	// Update elements status.
	Items.FormChargeWithStripe.Enabled = IsBlankString(Object.StripeID);
	
	// Check credit memo applied.
	//If Not Object.UnappliedPaymentCreditMemo.IsEmpty() Then
	//	ReadOnly = True;
	//EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	//If Not Object.UnappliedPaymentCreditMemo.IsEmpty() Then
	//	Message(NStr("en = 'The object has posted unapllied payment.
	//					   |Document modification is not allowed.'"));
	//EndIf;

	Object.BalChange = 0;	
	For Each LineItem In Object.LineItems Do
			//CreditTotal =  CreditTotal + LineItemCM.Payment;
			Object.BalChange = Object.BalChange + LineItem.Balance;
	EndDo;

	Object.BalanceTotal = Object.BalChange;
	
	//If GeneralFunctionsReusable.FunctionalOptionValue("MultiCurrency") Then
	//	Items.PaidAmount.ReadOnly = True;
	//Else
	//	Items.PaidAmount.ReadOnly = False;
	//EndIf;

	
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

//&AtClient
//// Disables editing of the Bank Account field if the deposit type is Undeposited Funds
////
//Procedure DepositTypeOnChange(Item)
//	
//	If Object.DepositType = "2" Then
//		Items.BankAccount.ReadOnly = False;
//	Else // 1, Null, ""
//		Items.BankAccount.ReadOnly = True;
//	EndIf;
//	
//EndProcedure

&AtClient
Procedure CheckOnChange(Item)
	
	PayTotal = 0;
	BalTotal = 0;
	
	DefaultCurrency = GeneralFunctionsReusable.DefaultCurrency();
	
	// Fill/clear payment value
	If Items.CreditMemos.CurrentData.Check Then
		
		If Items.CreditMemos.CurrentData.Currency = DefaultCurrency Then
			
			For Each LineItem In Object.LineItems Do
				BalTotal = BalTotal + LineItem.Balance;
				PayTotal = PayTotal + LineItem.Payment;
			EndDo;

		
			If Items.CreditMemos.CurrentData.Balance > (BalTotal - PayTotal) And PayRef = True Then
				Items.CreditMemos.CurrentData.Payment = BalTotal - PayTotal;
			Else
				Items.CreditMemos.CurrentData.Payment = Items.CreditMemos.CurrentData.Balance;
			Endif;
		Else
			
			For Each LineItem In Object.LineItems Do
				BalTotal = BalTotal + LineItem.BalanceFCY;
				PayTotal = PayTotal + LineItem.Payment;
			EndDo;

			If Items.CreditMemos.CurrentData.BalanceFCY > (BalTotal - PayTotal) And PayRef = True Then
				Items.CreditMemos.CurrentData.Payment = BalTotal - PayTotal;
			Else
				Items.CreditMemos.CurrentData.Payment = Items.CreditMemos.CurrentData.BalanceFCY;
			Endif;
		Endif;

		
	Else
		Items.CreditMemos.CurrentData.Payment = 0;
		
		For Each LineItem In Object.LineItems Do
			LineItem.Check = False;
			LineItem.Payment = 0;
		EndDo;
		
	EndIf;
	
	
	If ManualCheck = False Then
		
		AdditionalCreditPay();
	
	Endif;
	
	// Invoke inherited payment change event
	//CreditMemosPaymentOnChange(Item)
EndProcedure

&AtClient
Procedure Check2OnChange(Item)

	DefaultCurrency = GeneralFunctionsReusable.DefaultCurrency();
	
	PayTotal = 0;
	For Each LineItem In Object.LineItems Do
		PayTotal = PayTotal + LineItem.Payment;
	EndDo;
	
	If Items.LineItems.CurrentData.Check Then
		If Items.LineItems.CurrentData.Balance > (Object.CashPayment - PayTotal) and PayRef = True Then
				Items.LineItems.CurrentData.Payment = Object.CashPayment - PayTotal;
		Else
			If Items.LineItems.CurrentData.ExchangeRate = DefaultCurrency Then	
				Items.LineItems.CurrentData.Payment = Items.LineItems.CurrentData.Balance;
			Else
				Items.LineItems.CurrentData.Payment = Items.LineItems.CurrentData.BalanceFCY;
			Endif;
			
		Endif;
	Else	
		Items.LineItems.CurrentData.Payment = 0;
	EndIf;
		
	If ManualCheck = False Then 
	
		RemainingBalance();
		
		AdditionalPaymentCall();
	
	Endif;
	// Invoke inherited payment change event
	//CreditMemosPaymentOnChange(Item)
EndProcedure


&AtClient
Procedure CreditMemosPaymentOnChange(Item)
	
	// Limit payment value to credit memo amount
	//If Items.CreditMemos.CurrentData.Payment > Items.CreditMemos.CurrentData.BalanceFCY Then
	//	Items.CreditMemos.CurrentData.Payment = Items.CreditMemos.CurrentData.BalanceFCY;
	//EndIf;
	
	// Recalculate invoice/return's payment value
	//DistributeCreditMemos(False);
	
	// Update cash payment distribution
	//DistributeCashPayment();
	
	// Update totals
	//LineItemsPaymentOnChange(Items.LineItemsPayment);
	
	DefaultCurrency = GeneralFunctionsReusable.DefaultCurrency();
	
	If ManualCheck = False Then 
		
		If Items.CreditMemos.CurrentData.Currency = DefaultCurrency Then
			If Items.CreditMemos.CurrentData.Payment > Items.CreditMemos.CurrentData.Balance Then
				Items.CreditMemos.CurrentData.Payment = Items.CreditMemos.CurrentData.Balance;	
			Endif;
		Elsif Items.CreditMemos.CurrentData.Payment > Items.CreditMemos.CurrentData.BalanceFCY Then
			Items.CreditMemos.CurrentData.Payment = Items.CreditMemos.CurrentData.BalanceFCY;
		Endif;
		
		PayTotal = 0;
		BalTotal = 0;
		For Each LineItem In Object.LineItems Do
			If Items.CreditMemos.CurrentData.Currency = DefaultCurrency Then
				BalTotal = BalTotal + LineItem.Balance;
			Else
				BalTotal = BalTotal + LineItem.BalanceFCY;
			Endif;
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
				//CreditTotal =  CreditTotal + LineItemCM.Payment;
				CreditTotal = CreditTotal + LineItemCM.Payment;
		EndDo;
			
		
		Object.CreditTotal = CreditTotal;
		Object.AppliedCredit = Object.CreditTotal;
					
		//CreditOverFlow = CreditTotal - PayTotal;

		//If Items.CreditMemos.CurrentData.Check Then
		//
		//	For Each LineItem In Object.LineItems Do
		//		
		//		While CreditOverFlow > 0 And LineItem.Payment < LineItem.Balance Do
		//			AmountToPay = LineItem.Balance - LineItem.Payment;
		//			If AmountToPay >= CreditOverFlow Then
		//				LineItem.Payment = LineItem.Payment + CreditOverFlow;
		//				CreditOverFlow = 0;
		//				LineItem.Check = true;
		//			Else
		//				LineItem.Payment = LineItem.Payment + AmountToPay;
		//				CreditOverFlow=  CreditOverFlow - AmountToPay;
		//				LineItem.Check = true;
		//			Endif;
		//		EndDo;
		//	EndDo;
		//	
		//Endif;
		
		AdditionalCreditPay();
		
	Endif;

EndProcedure

&AtClient
Procedure AdditionalCreditPay()
	
	CreditTotal = 0;	
	For Each LineItemCM In Object.CreditMemos Do
			//CreditTotal =  CreditTotal + LineItemCM.Payment;
			CreditTotal = CreditTotal + LineItemCM.Payment;
	EndDo;
		
	
	Object.CreditTotal = CreditTotal;
	Object.AppliedCredit = Object.CreditTotal;
		
	// subtract total credit amount from cashpayment
	PayTotal = 0;
	For Each LineItem In Object.LineItems Do
			PayTotal = PayTotal + LineItem.Payment;
	EndDo;
	
	
	DefaultCurrency = GeneralFunctionsReusable.DefaultCurrency();	
	
	CreditOverFlow = Items.CreditMemos.CurrentData.Payment;//CreditTotal;

	If Items.CreditMemos.CurrentData.Check Then
	
		For Each LineItem In Object.LineItems Do
			
			If Items.CreditMemos.CurrentData.Currency = DefaultCurrency Then

				While CreditOverFlow > 0 And LineItem.Payment < LineItem.Balance Do
					AmountToPay = LineItem.Balance - LineItem.Payment;
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
			Else
				
				While CreditOverFlow > 0 And LineItem.Payment < LineItem.BalanceFCY Do
					AmountToPay = LineItem.BalanceFCY - LineItem.Payment;
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
			Endif;
				
		EndDo;
		
	Endif;
	
	Object.AppliedCredit = CreditOverFlow;
	UnappliedCalc();
	
EndProcedure

&AtClient
Procedure CreditMemosAppliedOnChange(Item)
	
	CreditTotal = 0;
	TabularPartRow = Items.LineItems.CurrentData;
	
	For Each LineItem In Object.LineItems Do
			CreditTotal =  CreditTotal + LineItem.CreditApplied;
	EndDo;
	TempVal =  Object.AppliedCredit - CreditTotal;
	
	If CreditTotal > Object.AppliedCredit Then
		Message("Paying with more credit than applied");
		
	Elsif TabularPartRow.CreditApplied > TabularPartRow.Balance Then
		Message("Credit exceeds invoice balance");		
	Else
		 Object.AppliedCredit = Object.CreditTotal - CreditTotal;
	Endif;
	

EndProcedure

&AtServer
Function SessionTenant()
	
	Return SessionParameters.TenantValue;
	
EndFunction

&AtClient
Procedure ChargeWithStripe(Command)
	
	
	// Check document saved.
	If Object.Ref.IsEmpty() Or Modified Then
		Message(NStr("en = 'The document is not saved.
                                |Save document first.';de='Das Dokument ist nicht gespeicher'"));
		Return;
	EndIf;
	
	// Check customer registered.
	StripeCustomerID = CommonUse.GetAttributeValue(Object.Company, "StripeID");
	If IsBlankString(StripeCustomerID) Then
		Message(NStr("en = 'The customer is not registered in Stripe
		                        |Register the customer and their payment card first.'"));
		Return;
	EndIf;
	
	// Define charge parameters.
	InputParameters    = New Structure("amount, currency, customer, description",
	                                   Object.CashPayment * 100,
	                                   "usd",
	                                   StripeCustomerID,
	                                   SessionTenant() + " Invoice " + Object.Number + " from " + Format(Object.Date,"DLF=D"));
	
	// Call Stripe for a charge.
	PostResult = ApiStripeRequestorInterface.PostCharges(InputParameters);
	
	// Check created charge.
	If PostResult.Result = Undefined Then
		// Failed creating charge.
		Message(NStr("en = 'Failed creating Stripe charge.'" + Chars.LF + PostResult.Description));
		Return;
		
	ElsIf Not PostResult.Result.Property("id", Object.StripeID) Then
		// Server returned the wrong object.
		Message(NStr("en = 'Failed creating Stripe charge.'" + Chars.LF + NStr("en = 'Stripe server request failed.'")));
		Return;
		
	Else
		
		Object.StripeCardName    = PostResult.Result.card.name;
		Object.StripeAmount  = PostResult.Result.amount/100;
		Object.StripeCreated = PostResult.Result.created;
		Object.StripeCardType    = PostResult.Result.card.type;
		Object.StripeLast4   = PostResult.Result.card.last4;
	
		// Charge successfully created.
		Message(NStr("en = 'Stripe charge successfully created.'"));
		
		// Mark form as modified.
		Modified = True;
	EndIf;

	// Update elements status.
	Items.FormChargeWithStripe.Enabled = IsBlankString(Object.StripeID);

EndProcedure

&AtClient
Procedure ManualCheckOnChange(Item)
	// Insert handler contents.
	If ManualCheck = False Then
		items.UnappliedPayment.ReadOnly = True;
	Else
		items.UnappliedPayment.ReadOnly = False;
	Endif;
	
EndProcedure

&AtClient
Procedure SendEmail(Command)
	SendEmailAtServer();
EndProcedure

&AtServer
Procedure SendEmailAtServer()

	
	If Object.Ref.IsEmpty() Then
		Message("An email cannot be sent until the invoice is posted or written");
	Else
		
	If Object.EmailTo <> "" Then
		
	// 	//imagelogo = Base64String(GeneralFunctions.GetLogo());
	 	If constants.logoURL.Get() = "" Then
			 imagelogo = "http://www.accountingsuite.com/images/logo-a.png";
	 	else
			 imagelogo = Constants.logoURL.Get();  
	 	Endif;
	 	
		
		
		datastring = "";
		TotalAmount = 0;
		TotalCredits = 0;
		For Each DocumentLine in Object.LineItems Do
			
			DocObj = DocumentLine.Document.Ref.GetObject();
			
			TotalAmount = TotalAmount + DocumentLine.Payment;
			datastring = datastring + "<TR height=""20""><TD style=""border-spacing: 0px 0px;height: 20px;"">" + DocumentLine.Document.Ref +  "</TD><TD style=""border-spacing: 0px 0px;height: 20px;"">" + DocObj.DocumentTotalRC + "</TD><TD style=""border-spacing: 0px 0px;height: 20px;"">" + DocumentLine.Balance + "</TD><TD style=""border-spacing: 0px 0px;height: 20px;"">" + DocumentLine.Payment + "</TD></TR>";

		EndDo;
		
		For Each CreditLine in Object.CreditMemos Do
			
			TotalCredits = TotalCredits + CreditLine.Payment;

	 	EndDo;

	    	 
	    MailProfil = New InternetMailProfile; 
	    
	    MailProfil.SMTPServerAddress = ServiceParameters.SMTPServer();
		//MailProfil.SMTPServerAddress = Constants.MailProfAddress.Get();
	    MailProfil.SMTPUseSSL = ServiceParameters.SMTPUseSSL();
		//MailProfil.SMTPUseSSL = Constants.MailProfSSL.Get();
	    MailProfil.SMTPPort = 465;  
	    
	    MailProfil.Timeout = 180; 
	    
		
		MailProfil.SMTPPassword = ServiceParameters.SendGridPassword();
	 	  
		MailProfil.SMTPUser = ServiceParameters.SendGridUserName();
		
		//MailProfil.SMTPPassword = "At/XCgOEv2nAyR+Nu7CC0WnhUVvbqndhaz1UkUkmQQTU"; 
		//MailProfil.SMTPPassword = Constants.MailProfPass.Get();
	    
	    //MailProfil.SMTPUser = "AKIAJIZ4ECYUL7N3P3BA"; 
		//MailProfil.SMTPUser = Constants.MailProfUser.Get();
	    
	    
	    send = New InternetMailMessage; 
	    //send.To.Add(object.shipto.Email);
	    send.To.Add(object.EmailTo);
		
		If Object.EmailCC <> "" Then
			EAddresses = StringFunctionsClientServer.SplitStringIntoSubstringArray(Object.EmailCC, ",");
			For Each EmailAddress in EAddresses Do
				send.CC.Add(EmailAddress);
			EndDo;
		Endif;
		
		
	    send.From.Address = Constants.Email.Get();
	    send.From.DisplayName = "AccountingSuite";
	    send.Subject = Constants.SystemTitle.Get() + " - Cash Receipt " + Object.Number + " from " + Format(Object.Date,"DLF=D") + " - $" + Format(Object.DocumentTotalRC,"NFD=2");
	    
	    FormatHTML = FormAttributeToValue("Object").GetTemplate("TemplateTest").GetText();
	 	  
	 	 
		If Object.StripeID <> "" Then
			FormatHTML2 = StrReplace(FormatHTML,"Receipt No.","Stripe ID");
			FormatHTML2 = StrReplace(FormatHTML2,"object.number",object.StripeID);
			FormatHTML2 = StrReplace(FormatHTML2,"<td align=""right""  id=""param1""></td>","<td align=""right"" style=""font-size: 12px;"">Payment Information: </td>");
			FormatHTML2 = StrReplace(FormatHTML2,"<td align=""right""  id=""param3""></td>","<td align=""right"">Last 4 Digits: " + Object.StripeLast4 + "</td>");
			FormatHTML2 = StrReplace(FormatHTML2,"<td align=""right""  id=""param2""></td>","<td align=""right""> Method: " + Object.StripeCardType + "</td>");
			
		Else
			FormatHTML2 = StrReplace(FormatHTML,"object.number",object.RefNum);
		Endif;
	 	 FormatHTML2 = StrReplace(FormatHTML2,"imagelogo",imagelogo);
	 	  FormatHTML2 = StrReplace(FormatHTML2,"object.date",Format(object.Date,"DLF=D"));
	 	  //BillTo
	 	  FormatHTML2 = StrReplace(FormatHTML2,"object.company",object.Company);

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

		  
		  
		  FormatHTML2 = StrReplace(FormatHTML2,"object.shipto1",Dataset[0].AddressLine1);
	 	  FormatHTML2 = StrReplace(FormatHTML2,"object.shipto2",Dataset[0].AddressLine2);
	 	 CityStateZip = Dataset[0].City + Dataset[0].State + Dataset[0].ZIP;
	 	 
	 	 If CityStateZip = "" Then
	 	 	FormatHTML2 = StrReplace(FormatHTML2,"object.city object.state object.zip","");
	 	 Else
	 	  	FormatHTML2 = StrReplace(FormatHTML2,"object.city object.state object.zip",Dataset[0].City + ", " + Dataset[0].State + " " + Dataset[0].ZIP);
	 	 Endif;
	 	  FormatHTML2 = StrReplace(FormatHTML2,"object.country",Dataset[0].Country);
	 	  //lineitems
	 	  FormatHTML2 = StrReplace(FormatHTML2,"lineitems",datastring);
 	   
	 	  //User's company info
	 	  FormatHTML2 = StrReplace(FormatHTML2,"mycompany",Constants.SystemTitle.Get()); 
	 	  FormatHTML2 = StrReplace(FormatHTML2,"myaddress1",Constants.AddressLine1.Get());
	 	  FormatHTML2 = StrReplace(FormatHTML2,"myaddress2",Constants.AddressLine2.Get());
	 	  FormatHTML2 = StrReplace(FormatHTML2,"mycity mystate myzip",Constants.City.Get() + ", " + Constants.State.Get() + " " + Constants.ZIP.Get());
	 	  FormatHTML2 = StrReplace(FormatHTML2,"myphone",Constants.Phone.Get());
	 	  FormatHTML2 = StrReplace(FormatHTML2,"myemail",Constants.Email.Get());
	 	  
	 	  FormatHTML2 = StrReplace(FormatHTML2,"object.total",Format(TotalAmount,"NFD=2"));
		  FormatHTML2 = StrReplace(FormatHTML2,"object.totpayment",Format(Object.CashPayment,"NFD=2"));
		  
	   If Object.UnappliedPayment = 0 Then
	 	   FormatHTML2 = StrReplace(FormatHTML2,"object.unapplied","0.00");
	   Else
	  		 FormatHTML2 = StrReplace(FormatHTML2,"object.unapplied",Format(Object.UnappliedPayment,"NFD=2"));
	   Endif;
		  
	   If TotalCredits = 0 Then
	 	   FormatHTML2 = StrReplace(FormatHTML2,"object.credits","0.00");
	   Else
	  		 FormatHTML2 = StrReplace(FormatHTML2,"object.credits",Format(TotalCredits,"NFD=2"));
	   Endif;

	   //Note
	   FormatHTML2 = StrReplace(FormatHTML2,"object.note",Object.EmailNote);
	  
		send.Texts.Add(FormatHTML2,InternetMailTextType.HTML);
			
		Posta = New InternetMail; 
		Posta.Logon(MailProfil); 
		Posta.Send(send); 
		Posta.Logoff();
		
		Message("Cash receipt email has been sent");
		
		//DocObject = object.ref.GetObject();
		//DocObject.EmailTo = Object.EmailTo;
		//DocObject.LastEmail = "Last email on " + Format(CurrentDate(),"DLF=DT") + " to " + Object.EmailTo;
		//DocObject.Write(DocumentWriteMode.Posting);
		SentEmail = True;

		Else
	 		 Message("The recipient email has not been specified");
	    Endif;
	 	
	 Endif;
	
	
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
Procedure CheckAll(Command)
	
	
	//test4 = items.LineItems;
	////items.check2 = true;
	//
	//For Each LineItem In Object.LineItems Do
	//	  LineItem.Check = True;
	//	 test =  items.LineItems.CurrentData;
	//	 test6 = 6;
	//EndDo;

EndProcedure


&AtServer
Function Increment(NumberToInc)
	
	//Last = Constants.SalesInvoiceLastNumber.Get();
	Last = NumberToInc;
	//Last = "AAAAA";
	LastCount = StrLen(Last);
	Digits = new Array();
	For i = 1 to LastCount Do	
		Digits.Add(Mid(Last,i,1));

	EndDo;
	
	NumPos = 9999;
	lengthcount = 0;
	firstnum = false;
	j = 0;
	While j < LastCount Do
		If NumCheck(Digits[LastCount - 1 - j]) Then
			if firstnum = false then //first number encountered, remember position
				firstnum = true;
				NumPos = LastCount - 1 - j;
				lengthcount = lengthcount + 1;
			Else
				If firstnum = true Then
					If NumCheck(Digits[LastCount - j]) Then //if the previous char is a number
						lengthcount = lengthcount + 1;  //next numbers, add to length.
					Else
						break;
					Endif;
				Endif;
			Endif;
						
		Endif;
		j = j + 1;
	EndDo;
	
	NewString = "";
	
	If lengthcount > 0 Then //if there are numbers in the string
		changenumber = Mid(Last,(NumPos - lengthcount + 2),lengthcount);
		NumVal = Number(changenumber);
		NumVal = NumVal + 1;
		StringVal = String(NumVal);
		StringVal = StrReplace(StringVal,",","");
		
		StringValLen = StrLen(StringVal);
		changenumberlen = StrLen(changenumber);
		LeadingZeros = Left(changenumber,(changenumberlen - StringValLen));

		LeftSide = Left(Last,(NumPos - lengthcount + 1));
		RightSide = Right(Last,(LastCount - NumPos - 1));
		NewString = LeftSide + LeadingZeros + StringVal + RightSide; //left side + incremented number + right side
		
	Endif;
	
	Next = NewString;

	return NewString;
	
EndFunction

&AtServer
Function NumCheck(CheckValue)
	 
	For i = 0 to  9 Do
		If CheckValue = String(i) Then
			Return True;
		Endif;
	EndDo;
		
	Return False;
		
EndFunction

&AtClient
Procedure PayAllDoc(Command)
	
	Total = 0;
	For Each LineItem In Object.LineItems Do
		test = LineItem;
		//Items.LineItems.CurrentData.Check = True;
		LineItem.Check = True;
		LineItem.Payment = LineItem.Balance;
		//LineItemsCheckOnChange(Items.LineItems.CurrentData.Check);
		Total = Total + LineItem.Payment;

	EndDo;
	
	Object.CashPayment = Total;

	
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
	EmailSet();
	FillDocumentList(Object.Company);
	For Each Doc In Object.LineItems Do
		If Doc.Document = SalesInvoice Then
			Doc.Payment = Doc.Balance;
			Object.CashPayment = Doc.Balance;
			Object.DocumentTotal = Doc.Balance;
			Object.DocumentTotalRC = Doc.BalanceFCY;
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

