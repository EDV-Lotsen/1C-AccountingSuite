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
				 |			Account IN (SELECT ARAccount FROM Document.SalesReturn WHERE Company = &Company AND ReturnType = VALUE(Enum.ReturnTypes.CreditMemo)),
				 |			,
				 |			ExtDimension1 = &Company AND ExtDimension2 REFS Document.SalesReturn AND ExtDimension2.ReturnType = VALUE(Enum.ReturnTypes.CreditMemo)) AS GeneralJournalBalance
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

&AtServer
// The procedure applies all of the amounts of credit memos
// to the amounts of sales invoices / purchase returns.
//
Procedure DistributeCreditMemos(RecalculateCreditMemoPayments = True)
	
	DefaultCurrency = GeneralFunctionsReusable.DefaultCurrency();
	LineItem = Undefined;
	CurrentInvoice = 0;
	CurrentBalanceRC = 0;
	CurrentBalance = 0;
	CurrentCurrency = Undefined;
	CurrentRate = 0;
	
	// Fill maximum possible netting amount
	For Each LineItemCM In Object.CreditMemos Do
		// Get credit memo amount for distribution
		If RecalculateCreditMemoPayments Then
			CMMxPayment = LineItemCM.BalanceFCY;  // Max available payment value for credit memo - document total
			CMAmount    = LineItemCM.BalanceFCY;
			CMAmountRC  = LineItemCM.Balance;
		Else
			CMMxPayment = LineItemCM.Payment; // Max available payment value for credit memo - defined by user
			CMAmount    = LineItemCM.Payment;
			CMAmountRC  = ?(LineItemCM.Currency = DefaultCurrency, LineItemCM.Payment,
						  ?(LineItemCM.Payment = LineItemCM.BalanceFCY, LineItemCM.Balance, Round(LineItemCM.Payment * LineItemCM.ExchangeRate, 2)));
		EndIf;
		CMCurrency = LineItemCM.Currency;
		CMRate	   = LineItemCM.ExchangeRate;
		// Clear payment value (will be renewed within calculation)
		LineItemCM.Payment = 0;
		
		// Cycle through invoices until there is something do distribute
		While CMAmountRC > 0 Do
			
			// Find next invoice to close
			If CurrentBalanceRC = 0 Then
				If CurrentInvoice = Object.LineItems.Count() Then
					// All due already distributed
					Break;
				Else
					// Get new invoice
					CurrentInvoice = CurrentInvoice +1;
					LineItem       = Object.LineItems.Get(CurrentInvoice-1);
					CurrentBalance     = LineItem.BalanceFCY;
					CurrentBalanceRC   = LineItem.Balance;
					CurrentCurrency= LineItem.Currency;
					CurrentRate    = LineItem.ExchangeRate;
					// Clear payment value (will be renewed within calculation)
					LineItem.Payment = 0;
				EndIf;
			EndIf;
			
			// Find possible amount to close
			If ?(CMCurrency = CurrentCurrency, CMAmount > CurrentBalance, CMAmountRC > CurrentBalanceRC) Then
				
				// Claculate CM payment and rest of a due
				If CMCurrency = CurrentCurrency Then
					CMPayment = CurrentBalance;
				Else
					CMPayment = Round(CMAmount * CurrentBalanceRC / CMAmountRC, 2);
				EndIf;
				
				// Save new payment to credit memo
				LineItemCM.Payment = LineItemCM.Payment + CMPayment;
				If Not LineItemCM.Check Then LineItemCM.Check = True; EndIf;
				// Recalculate rest of CM due
				CMAmount   = ?(CMPayment > CMAmount, 0, CMAmount - CMPayment);
				CMAmountRC = ?(CMAmount > 0,            CMAmountRC - Round(CMPayment * CMRate, 2), 0);
				
				// Close an invoice/return DueFCY -> Payment
				LineItem.Payment = LineItem.BalanceFCY;
				// Clear rest of a due
				CurrentBalance = 0;
				CurrentBalanceRC = 0;
				
			Else // ?(CMCurrency = CurrentCurrency, CMAmount <= CurrentDue, CMAmountRC <= CurrentDueRC)
				
				// Claculate CM payment and rest of a due
				If CurrentCurrency = CMCurrency Then
					CurrentPayment = CMAmount;
				Else
					CurrentPayment = Round(CurrentBalance * CMAmountRC / CurrentBalanceRC, 2);
				EndIf;
				
				// Save new payment to invoice/return
				LineItem.Payment = LineItem.Payment + CurrentPayment;
				// Recalculate rest of a invoice/return due
				CurrentBalance   = ?(CurrentPayment > CurrentBalance, 0, CurrentBalance - CurrentPayment);
				CurrentBalanceRC = ?(CurrentBalance > 0,                 CurrentBalanceRC - Round(CurrentPayment * CurrentRate, 2), 0);
				
				// Close the credit memo CMMxPayment(DueFCY or User defined) -> Payment
				LineItemCM.Payment = CMMxPayment;
				If Not LineItemCM.Check Then LineItemCM.Check = True; EndIf;
				// Clear rest of CM due
				CMAmount   = 0;
				CMAmountRC = 0;
			EndIf;	
		EndDo;
				
	EndDo;
	
	// Clear rest invoice/return lines
	For i = CurrentInvoice To Object.LineItems.Count()-1 Do
		Object.LineItems[i].Payment = 0;
	EndDo;
	
EndProcedure

&AtServer
// The procedure applies the amount paid by the customer to rest of invoices
// to the amounts of sales invoices / purchase returns.
//
Procedure DistributeCashPayment()
	
	DefaultCurrency = GeneralFunctionsReusable.DefaultCurrency();
	LineItem = Undefined;
	CurrentInvoice = 0;
	CurrentBalanceRC = 0;
	CurrentBalance = 0;
	CurrentCurrency = Undefined;
	CurrentRate = 0;
	
	// Fill/distribute paid amount on the rest of invoices
	MxPayment = Object.CashPayment;
	Amount    = MxPayment;  
	Rate	  = ?(Object.Currency = DefaultCurrency, 1,                  GeneralFunctions.GetExchangeRate(Object.Date, Object.Currency));
	AmountRC  = ?(Object.Currency = DefaultCurrency, Object.CashPayment, Round(Object.CashPayment * Rate, 2));
	
	// Cycle through invoices until there is something do distribute
	While AmountRC > 0 Do
		
		// Find next invoice to close
		If CurrentBalanceRC = 0 Then
			If CurrentInvoice = Object.LineItems.Count() Then
				// All due already distributed
				Break;
			Else
				// Get new invoice
				CurrentInvoice = CurrentInvoice +1;
				LineItem       = Object.LineItems.Get(CurrentInvoice-1);
				CurrentBalance     = LineItem.BalanceFCY;
				CurrentBalanceRC   = LineItem.Balance;
				CurrentCurrency= LineItem.Currency;
				CurrentRate    = LineItem.ExchangeRate;
				CurrentPaid    = LineItem.Payment;
			EndIf;
		EndIf;
		
		// Find possible amount to close
		If ?(Object.Currency = CurrentCurrency, Amount > (CurrentBalance-CurrentPaid), Amount > (Round(Amount * CurrentBalanceRC / AmountRC, 2) - CurrentPaid)) Then
			
			// Claculate payment and rest of a due
			If Object.Currency = CurrentCurrency Then
				Payment = CurrentBalance - CurrentPaid;
			Else
				Payment = Round(Amount * CurrentBalanceRC / AmountRC, 2) - CurrentPaid;
			EndIf;
			
			// Recalculate rest of CM due
			Amount   = ?(Payment > Amount, 0, Amount - Payment);
			AmountRC = ?(Amount > 0,          AmountRC - Round(Payment * Rate, 2), 0);
			
			// Close an invoice/return DueFCY -> Payment
			LineItem.Payment = LineItem.BalanceFCY;
			// Clear rest of a due
			CurrentBalance = 0;
			CurrentBalanceRC = 0;
			
		Else // ?(Currency = CurrentCurrency, Amount <= CurrentDue-CurrentPaid, AmountRC <= Round(Amount * CurrentDueRC / AmountRC, 2) - CurrentPaid
			
			// Claculate payment and rest of a due
			If CurrentCurrency = Object.Currency Then
				CurrentPayment = Amount;
			Else
				CurrentPayment = Round(CurrentBalance * AmountRC / CurrentBalanceRC, 2);
			EndIf;
			
			// Save new payment to invoice/return
			LineItem.Payment = LineItem.Payment + CurrentPayment;
			// Recalculate rest of a invoice/return due
			CurrentBalance   = ?(CurrentPayment > CurrentBalance, 0, CurrentBalance - CurrentPayment);
			CurrentBalanceRC = ?(CurrentBalance > 0,                 CurrentBalanceRC - Round(CurrentPayment * CurrentRate, 2), 0);
			
			// Clear rest of payment
			Amount   = 0;
			AmountRC = 0;
		EndIf;	
	EndDo;
	
	// Remove the rest of cash payment while in automatic distribution
	If Amount > 0 Then
		Object.CashPayment = MxPayment - Amount;
	EndIf;
	
EndProcedure

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
	DistributeCreditMemos();
	// Distribute paid amount on receivables
	DistributeCashPayment();
	
	// Update totals
	LineItemsPaymentOnChange(Items.LineItemsPayment);
EndProcedure

&AtClient
Procedure CashPaymentOnChange(Item)
	// Distribute paid amount on receivables
	DistributeCashPayment();
	
	// Update totals
	LineItemsPaymentOnChange(Items.LineItemsPayment);
EndProcedure

&AtClient
// LineItemsPaymentOnChange UI event handler.
// The procedure calculates a document total in the foreign currency (DocumentTotal) and in the
// reporting currency (DocumentTotalRC).
//
Procedure LineItemsPaymentOnChange(Item)
	
	DefaultCurrency = GeneralFunctionsReusable.DefaultCurrency();
	
	// Update document totals
	DocumentTotalRC = 0;
	For Each Row In Object.LineItems Do
		If Row.Currency = DefaultCurrency Then
			DocumentTotalRC = DocumentTotalRC + Row.Payment;
		Else
			DocumentTotalRC = DocumentTotalRC + Round(Row.Payment * Row.ExchangeRate, 2);
		EndIf;
	EndDo;
	Object.DocumentTotal = Object.LineItems.Total("Payment");
	Object.DocumentTotalRC = DocumentTotalRC;
	
EndProcedure

&AtClient
// The procedure deletes all line items which are not paid by this cash receipt
//
Procedure BeforeWrite(Cancel, WriteParameters)
	
	If Object.LineItems.Count() = 0 Then
		Message("Cash Receipt can not have empty lines. The system automatically shows unpaid documents of the selected company in the line items");
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

	 
	Object.Currency = Object.LineItems[0].Currency;
	NumberOfRows = Object.LineItems.Count() - 1;
		
	While NumberOfRows >= 0 Do
		
		If NOT Object.LineItems[NumberOfRows].Currency = Object.Currency Then
			Message("All documents in the line items need to have the same currency");
			Cancel = True;
			Return;
	    EndIf;
		
		NumberOfRows = NumberOfRows - 1;
		
	EndDo
	
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
	
	If Object.DepositType = "2" Then
		Items.BankAccount.ReadOnly = False;
	Else // 1, Null, ""
		Items.BankAccount.ReadOnly = True;
	EndIf;
	
	If Object.BankAccount.IsEmpty() Then
		Object.BankAccount = Constants.BankAccount.Get();
	Else
	EndIf; 
	
	Items.BankAccountLabel.Title =
		CommonUse.GetAttributeValue(Object.BankAccount, "Description");

	If GeneralFunctionsReusable.FunctionalOptionValue("MultiCurrency") Then	
		Items.CreditMemosPayment.Title = "Payment FCY";	
		Items.LineItemsPayment.Title = "Payment FCY";	
	EndIf;
	
	// Set checks for credit memos
	For Each LineItem In Object.CreditMemos Do
		If LineItem.Payment > 0 Then LineItem.Check = True; EndIf;
	EndDo;
	
	// AdditionalReportsAndDataProcessors
	AdditionalReportsAndDataProcessors.OnCreateAtServer(ThisForm);
	// End AdditionalReportsAndDataProcessors
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	// Set checks for credit memos
	For Each LineItem In Object.CreditMemos Do
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
	
	// Fill/clear payment value
	If Items.CreditMemos.CurrentData.Check Then
		Items.CreditMemos.CurrentData.Payment = Items.CreditMemos.CurrentData.BalanceFCY;
	Else
		Items.CreditMemos.CurrentData.Payment = 0;
	EndIf;
	
	// Invoke inherited payment change event
	CreditMemosPaymentOnChange(Item)
EndProcedure

&AtClient
Procedure CreditMemosPaymentOnChange(Item)
	
	// Limit payment value to credit memo amount
	If Items.CreditMemos.CurrentData.Payment > Items.CreditMemos.CurrentData.BalanceFCY Then
		Items.CreditMemos.CurrentData.Payment = Items.CreditMemos.CurrentData.BalanceFCY;
	EndIf;
	
	// Recalculate invoice/return's payment value
	DistributeCreditMemos(False);
	
	// Update cash payment distribution
	DistributeCashPayment();
	
	// Update totals
	LineItemsPaymentOnChange(Items.LineItemsPayment);
EndProcedure
