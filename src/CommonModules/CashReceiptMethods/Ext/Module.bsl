&AtServer
// Calculations for cash payments
Procedure CashPaymentCalculation(Object, PayRef) Export
	
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
		UnappliedCalculation(Object);
	Elsif CashDistribute <= 0 And CreditTotal <= 0 Then
		Object.UnappliedPayment = 0;
	Endif;
	
	AdditionalPaymentCall(Object, PayRef);
					
EndProcedure

&AtServer
// Calculates the object's unapplied
Procedure UnappliedCalculation(Object) Export
		
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
// Used to recalculate the CashPayment value and DocumentTotal values when there is a change in the document
Procedure AdditionalPaymentCall(Object, PayRef) Export

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
	
	If Object.LineItems.Total("Payment") = 0 AND Object.CashPayment <> 0 Then
		Object.DocumentTotalRC = (Object.CashPayment * Object.ExchangeRate) + (CreditTotal * Object.ExchangeRate);
		Object.DocumentTotal = Object.CashPayment + CreditTotal;
	Else
		Object.DocumentTotalRC = Object.CashPayment * Object.ExchangeRate;
		Object.DocumentTotal = Object.CashPayment;
	EndIf;

	UnappliedCalculation(Object);
	
EndProcedure

&AtServer
// Calculations for applied credits
Procedure AdditionalCreditPay(Object, CreditAppliedNegative, CreditAppliedPositive, CurrentLineItemPay, CurrentCheckMarkStatus) Export
	
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
	
	CreditOverFlow = CurrentLineItemPay;//Items.CreditMemos.CurrentData.Payment;//CreditTotal;
		
	//Applies the credit amount to line items. Applies from top line items down, depending if a line item is full
	// and there is a leftover amount from the selected credit.
	If CurrentCheckMarkStatus Then
	
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
	UnappliedCalculation(Object);
	
EndProcedure

&AtServer
// Retrieves current balance for lineitems in Cash Receipt
Procedure UpdateLineItemBalances(Object) Export
	
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

&AtServer
// The procedure selects all sales invoices and vendor returns having an unpaid balance
// and fills in line items of a cash receipt.
Procedure FillDocumentList(Company, Object) Export
	
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
Procedure FillCreditMemos(Company, Object) Export
	
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
