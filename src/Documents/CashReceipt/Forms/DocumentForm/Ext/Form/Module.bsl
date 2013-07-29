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
	
	ResultSelection = Query.Execute().Choose();
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
	
	ResultSelection = Query.Execute().Choose();
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
	
	Object.CompanyCode = CommonUse.GetAttributeValue(Object.Company, "Code");
	
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
			CashDistribute = Round(Object.CashPayment/Rate);
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
	
	//If Object.LineItems.Count() = 0 Then
	//	Message("Cash Receipt can not have empty lines. The system automatically shows unpaid documents of the selected company in the line items");
	//	Cancel = True;
	//	Return;
	//EndIf;

	DefaultCurrency = GeneralFunctionsReusable.DefaultCurrency();
	CompanyCurrency = CompanyCurrency();
	Rate = GeneralFunctions.GetExchangeRate(Object.Date, CompanyCurrency);
	
	PayTotal = 0;
	BalanceFCY = 0;
	For Each LineItem In Object.LineItems Do
				PayTotal =  PayTotal + LineItem.Payment;
				BalanceFCY = BalanceFCY + LineItem.BalanceFCY;
	EndDo;

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
		  Object.DocumentTotalRC = Object.CashPayment;
		  Object.DocumentTotal = Object.CashPayment/Rate;
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

	//Title = "Receipt " + Object.Number + " " + Format(Object.Date, "DLF=D");
	
	Items.Company.Title = GeneralFunctionsReusable.GetCustomerName();
	Items.UnappliedPayment.ReadOnly = True;
	
	If Object.DepositType = "2" Then
		Items.BankAccount.ReadOnly = False;
	Else // 1, Null, ""
		Items.BankAccount.ReadOnly = True;
	EndIf;
	
	If Object.BankAccount.IsEmpty() Then
		Object.BankAccount = Constants.BankAccount.Get();
	Else
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

&AtClient
// Retrieves the account's description
//
Procedure BankAccountOnChange(Item)
	
	Items.BankAccountLabel.Title =
		CommonUse.GetAttributeValue(Object.BankAccount, "Description");

EndProcedure

&AtClient
// Disables editing of the Bank Account field if the deposit type is Undeposited Funds
//
Procedure DepositTypeOnChange(Item)
	
	If Object.DepositType = "2" Then
		Items.BankAccount.ReadOnly = False;
	Else // 1, Null, ""
		Items.BankAccount.ReadOnly = True;
	EndIf;
	
EndProcedure

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

&AtClient
Procedure ManualCheckOnChange(Item)
	// Insert handler contents.
	If ManualCheck = False Then
		items.UnappliedPayment.ReadOnly = True;
	Else
		items.UnappliedPayment.ReadOnly = False;
	Endif;
	
EndProcedure
