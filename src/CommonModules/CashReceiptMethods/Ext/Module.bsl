
&AtServer
// Calculations for cash payments
Procedure CashPaymentCalculation(Object) Export
	
	TotalCredit = Object.CreditMemos.Total("Payment");
	TotalAmountToDistribute = TotalCredit;
	
	ClearTabularSections(Object, True, False);
	
	For Each LineItem In Object.LineItems Do
		LineItem.Payment = 0;
		
		LineBalance = LineItem.BalanceFCY2;
		If TotalAmountToDistribute = 0 Then 
			Break;
		ElsIf TotalAmountToDistribute < LineBalance Then 
			FillPaymentWithDiscount(Object, LineItem.Document, LineItem.BalanceFCY2, LineItem.Payment, LineItem.Discount, TotalAmountToDistribute);
			TotalAmountToDistribute = TotalAmountToDistribute - LineItem.Payment;
		Else	
			FillPaymentWithDiscount(Object, LineItem.Document, LineItem.BalanceFCY2, LineItem.Payment, LineItem.Discount);
			TotalAmountToDistribute = TotalAmountToDistribute - LineItem.Payment;
		EndIf;
		
		If LineItem.Payment > 0 Then 
			LineItem.Check = True;
		EndIf;	
	EndDo;
	
	AdditionalPaymentCall(Object);

EndProcedure

&AtServer
// Calculates the object's unapplied
Procedure UnappliedCalculation_old(Object) Export
		
	TotalLinePayment = Object.LineItems.Total("Payment");
	TotalCredit = Object.CreditMemos.Total("Payment");
	
	// Unapplied payment amount is equal to the total cash payment + the total credits applied
	// The amount paid in LineItems (which can include cash payments and credit payments)
	Object.UnappliedPayment = (Object.CashPayment + TotalCredit) - TotalLinePayment;
	
EndProcedure

&AtServer
// Used to recalculate the CashPayment value and DocumentTotal values when there is a change in the document
Procedure AdditionalPaymentCall(Object, RecalcUP = True) Export

	DefaultCurrency = GeneralFunctionsReusable.DefaultCurrency();
	
	TotalDiscount = Object.LineItems.Total("Discount");
	TotalInvoices = Object.LineItems.Total("Payment");
	TotalCredit = Object.CreditMemos.Total("Payment");

	If (Object.UnappliedPayment < TotalCredit-TotalInvoices) or RecalcUP Then 
		Object.UnappliedPayment = TotalCredit-TotalInvoices
	EndIf;	
	
	Object.CashPayment = Object.UnappliedPayment + TotalInvoices - TotalCredit;
	
	
	Object.DocumentTotalRC = (Object.CashPayment * Object.ExchangeRate) + (TotalCredit * Object.ExchangeRate) + (TotalDiscount * Object.ExchangeRate);
	Object.DocumentTotal = Object.CashPayment + TotalCredit + TotalDiscount;
	Object.DiscountAmount = TotalDiscount;
	
EndProcedure

&AtServer
// Calculations for applied credits   // OLD
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
	//UnappliedCalculation(Object);
	
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
	             |						OR ExtDimension2 REFS Document.Check
				 |						OR ExtDimension2 REFS Document.GeneralJournalEntry
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
				// |					AND Document.SalesReturn.ReturnType = VALUE(Enum.ReturnTypes.CreditMemo)
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
				 //|						AND ExtDimension2.ReturnType = VALUE(Enum.ReturnTypes.CreditMemo)
				 |					OR ExtDimension2 REFS Document.GeneralJournalEntry 
				 |					OR ExtDimension2 REFS Document.Deposit
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
		
		Try
			CurrentLineDoc = LineRow.Document;
			LineTerms = CurrentLineDoc.Terms; 
			If ValueIsFilled(LineTerms) Then 
				LineDiscountDays = LineTerms.DiscountDays;
				LineRow.DiscountDate = CurrentLineDoc.Date + LineDiscountDays*3600*24;
				If LineDiscountDays = 0 Then 
					LineRow.DiscountDate = Date('00010101');
				EndIf;	
			Else 	
				LineRow.DiscountDate = Date('00010101');
			EndIf;
		Except
			LineRow.DiscountDate = Date('00010101');
		EndTry; 
		If TypeOf(CurrentLineDoc) = Type("DocumentRef.SalesInvoice") Then 
			SOList = New ValueList;
			For Each SubLine in CurrentLineDoc.LineItems Do 
				If SOList.Count() = 2 Then 
					
				EndIf;
				If Not ValueIsFilled(SubLine.Order) Then 
					Continue;
				EndIf;	
				
				If SOList.FindByValue(SubLine.Order) = Undefined Then 
					SOList.Add(SubLine.Order);
					If SOList.Count() > 1 Then 
						LineRow.SalesOrder = "-Split-";
						Break;
					Else 	
						LineRow.SalesOrder = SubLine.Order;
					EndIf;	
					
				EndIf;	
			EndDo;
			
		Endif;	
	EndDo;
	
	For Each CreditRow In Object.CreditMemos Do
		FoundRows = ResultQuery.FindRows(New Structure("TabularSection, LineNumber", "CreditMemos", CreditRow.LineNumber));
		If FoundRows.Count()>0 Then
			CreditRow.BalanceFCY2 = FoundRows[0].BalanceFCY2;
			If TypeOf(CreditRow.Document) = Type("DocumentRef.CashReceipt") Then  
				CreditRow.SalesOrder = CreditRow.Document.SalesOrder;
			Endif;
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
// The procedure selects all sales invoices and vendor returns having an unpaid balance
// and fills in line items of a cash receipt.
Procedure FillDocumentList(Company, Object) Export
	
	Object.LineItems.Clear();
	
	Query = New Query;
	//Query.Text = "SELECT
	//|	GeneralJournalBalance.Account As ARAccount,
	//|	GeneralJournalBalance.AmountBalance AS BalanceFCY2,
	//|	GeneralJournalBalance.AmountBalance * ISNULL(ExchangeRates.Rate, 1) AS Balance,
	//|  ISNULL(ExchangeRates.Rate, 1) AS ExchangeRate,
	//|	0 AS Payment,
	//|	GeneralJournalBalance.ExtDimension2.Ref AS Document,
	//|	GeneralJournalBalance.ExtDimension2.Ref.Currency Currency2
	//|FROM
	//|  // Get due rests from accounting balance
	//|	AccountingRegister.GeneralJournal.Balance (,
	//|			Account IN (SELECT ARAccount FROM Document.SalesInvoice UNION SELECT APAccount FROM Document.PurchaseReturn WHERE Company = &Company),
	//|			,
	//|			ExtDimension1 = &Company
	//|			AND (ExtDimension2 REFS Document.SalesInvoice OR
	//|			     ExtDimension2 REFS Document.GeneralJournalEntry OR
	//|			     ExtDimension2 REFS Document.PurchaseReturn)) AS GeneralJournalBalance
	//|
	//|	// Calculate exchange rate for a document on a present moment
	//|	LEFT JOIN
	//|		InformationRegister.ExchangeRates.SliceLast(&Date, ) AS ExchangeRates
	//|	ON
	//|		GeneralJournalBalance.ExtDimension2.Ref.Currency = ExchangeRates.Currency
	//|
	//|ORDER BY
	//|  GeneralJournalBalance.ExtDimension2.Date";
	
	Query.Text = "
	|SELECT 
	|	Accounts.Ref As ARAccount 
	|INTO TmpAccnts
	|	FROM ChartOfAccounts.ChartOfAccounts As Accounts
	|WHERE Accounts.AccountType = Value(Enum.AccountTypes.AccountsReceivable)
	|UNION 
	|SELECT 
	|	APAccount 
	|	FROM Document.PurchaseReturn 
	|WHERE Company = &Company
	|
	|;
	|SELECT
	|	GeneralJournalBalance.Account As ARAccount,
	|	GeneralJournalBalance.AmountBalance AS BalanceFCY2,
	|	GeneralJournalBalance.AmountBalance * ISNULL(ExchangeRates.Rate, 1) AS Balance,
	|  	ISNULL(ExchangeRates.Rate, 1) AS ExchangeRate,
	|	0 AS Payment,
	|	GeneralJournalBalance.ExtDimension2.Ref AS Document,
	|	ISNULL(GeneralJournalBalance.ExtDimension2.Ref.Currency, GeneralJournalBalance.Currency) AS Currency2
	|FROM
	|  // Get due rests from accounting balance
	|	AccountingRegister.GeneralJournal.Balance (,
	|			Account IN (SELECT ARAccount FROM TmpAccnts as TmpAccnts),
	|			,
	|			ExtDimension1 = &Company
	|			AND (ExtDimension2 REFS Document.SalesInvoice OR
	|			     ExtDimension2 REFS Document.GeneralJournalEntry OR
	|			     ExtDimension2 REFS Document.Check OR
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
	NonARMatch = 0;
	ResultSelection = Query.Execute().Select();
	
	While ResultSelection.Next() Do
		ContinueFlag = False;
		CurDiscountDate = Date('00010101');
		SOList = New ValueList;
		
		If TypeOf(ResultSelection.Document) = Type("DocumentRef.GeneralJournalEntry") Then  
			If ResultSelection.BalanceFCY2 < 0 Then 
				Continue;
			ElsIf ResultSelection.ARAccount <> Object.ARAccount Then
				NonARMatch = NonARMatch + 1;
				ContinueFlag = True
			EndIf;
			
		ElsIf TypeOf(ResultSelection.Document) = Type("DocumentRef.SalesInvoice") Then  
			CurrentLineDoc = ResultSelection.Document;
			LineTerms = CurrentLineDoc.Terms; 
			If ValueIsFilled(LineTerms) Then 
				LineDiscountDays = LineTerms.DiscountDays;
				If LineDiscountDays <> 0 Then 
					CurDiscountDate = CurrentLineDoc.Date + LineDiscountDays*3600*24;
				EndIf;	
			EndIf;
			If ResultSelection.ARAccount <> Object.ARAccount Then
				NonARMatch = NonARMatch + 1;
				ContinueFlag = True
			Else 
				If SOList.Count() < 2 Then 
					For Each SubLine in CurrentLineDoc.LineItems Do 
						If Not ValueIsFilled(SubLine.Order) Then 
							Continue;
						EndIf;	
						If SOList.FindByValue(SubLine.Order) = Undefined Then 
							SOList.Add(SubLine.Order);
						EndIf;	
					EndDo;
				EndIf;	
			EndIf;
			
			
			
		ElsIf TypeOf(ResultSelection.Document) = Type("DocumentRef.Check") Then  
			CurrentLineDoc = ResultSelection.Document;
			If ResultSelection.ARAccount <> Object.ARAccount Then
				NonARMatch = NonARMatch + 1;
				ContinueFlag = True
			EndIf;	
			
		Endif;    
		
		If ResultSelection.Currency2 <> Company.DefaultCurrency Then
			//Display only if currency of lineitem matches company currency
			NonCurrencyMatch = NonCurrencyMatch + 1;
			ContinueFlag = True
		EndIf;	
		
		If ContinueFlag Then 
			Continue;
		EndIf;	
		
		LineItems = Object.LineItems.Add();
		FillPropertyValues(LineItems, ResultSelection);
		LineItems.DiscountDate = CurDiscountDate;
		
		If SOList.Count() = 1 Then 
			LineItems.SalesOrder = SOList[0].Value;
		ElsIf SOList.Count() > 1 Then 
			LineItems.SalesOrder = "-Split-";
		EndIf;
		
		
	EndDo;
	
	If NonCurrencyMatch = 1 Then
		Message(String(NonCurrencyMatch) + " invoice was not shown due to non-matching currency"); 
	ElsIf NonCurrencyMatch > 0 Then
		Message(String(NonCurrencyMatch) + " invoices were not shown due to non-matching currency"); 
	EndIf;
	
	If NonARMatch = 1 Then
		Message(String(NonARMatch) + " invoice was not shown due to non-matching AR Account"); 
	ElsIf NonARMatch > 0 Then
		Message(String(NonARMatch) + " invoices were not shown due to non-matching AR Account"); 
	EndIf;
	
EndProcedure

&AtServer
// The procedure selects all credit memos having an unpaid balance
// and fills in credit memos table of a cash receipt.
Procedure FillCreditMemos(Company, Object) Export
	
	Object.CreditMemos.Clear();
	
	Query = New Query;
	Query.Text = "SELECT
	|	Accounts.Ref As ARAccount 
	|INTO TmpAccnts
	|	FROM ChartOfAccounts.ChartOfAccounts As Accounts
	|WHERE Accounts.AccountType = Value(Enum.AccountTypes.AccountsReceivable)
	|
	|;
	|SELECT 
	|	GeneralJournalBalance.Account As ARAccount,
	|	-GeneralJournalBalance.AmountBalance AS BalanceFCY2,
	|	-GeneralJournalBalance.AmountBalance * ISNULL(ExchangeRates.Rate, 1) AS Balance,
	|  ISNULL(ExchangeRates.Rate, 1) AS ExchangeRate,
	|	0 AS Payment,
	|	GeneralJournalBalance.ExtDimension2.Ref AS Document,
	|	ISNULL(GeneralJournalBalance.ExtDimension2.Ref.Currency,GeneralJournalBalance.Currency) Currency,
	|  False AS Check
	|FROM
	|  // Get due rests from accounting balance
	|	AccountingRegister.GeneralJournal.Balance(,
	//|	AccountingRegister.GeneralJournal.Balance(&Date,
	//|			Account IN (SELECT ARAccount FROM Document.SalesReturn WHERE Company = &Company AND ReturnType = VALUE(Enum.ReturnTypes.CreditMemo) UNION SELECT ARAccount FROM Document.CashReceipt WHERE Company = &Company),
	|			Account IN (SELECT ARAccount FROM TmpAccnts as TmpAccnts),
	|			,
	|			ExtDimension1 = &Company AND
	|          (ExtDimension2 REFS Document.SalesReturn OR
	|			ExtDimension2 REFS Document.GeneralJournalEntry OR
	|			ExtDimension2 REFS Document.Deposit OR
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
	
	Query.SetParameter("Date",    ?(ValueIsFilled(Object.Date), Object.Date, CurrentSessionDate()));
	Query.SetParameter("Company", Company);
	
	NonCurrencyMatch = 0;
	NonARMatch = 0;
	ResultSelection = Query.Execute().Select();
	
	While ResultSelection.Next() Do
		ContinueFlag = False;
		
		CurDiscountDate = Date('00010101');
		
		If TypeOf(ResultSelection.Document) = Type("DocumentRef.GeneralJournalEntry") Then  
			If ResultSelection.BalanceFCY2 < 0 Then 
				Continue;
			EndIf;
		Endif;
		
		If ResultSelection.ARAccount <> Object.ARAccount Then
			NonARMatch = NonARMatch + 1;
			ContinueFlag = True
		EndIf;
		
		If ResultSelection.Currency <> Company.DefaultCurrency Then
			NonCurrencyMatch = NonCurrencyMatch + 1;
			ContinueFlag = True
		EndIf;	
		
		If ContinueFlag Then 
			Continue;
		EndIf;
		
		LineItems = Object.CreditMemos.Add();
		FillPropertyValues(LineItems, ResultSelection);
		
		If TypeOf(ResultSelection.Document) = Type("DocumentRef.CashReceipt") Then  
			LineItems.SalesOrder = ResultSelection.Document.SalesOrder;
		Endif;
		
	EndDo;
	
	
	If NonCurrencyMatch = 1 Then
		Message(String(NonCurrencyMatch) + " credit was not shown due to non-matching currency"); 
	ElsIf NonCurrencyMatch > 0 Then
		Message(String(NonCurrencyMatch) + " credits were not shown due to non-matching currency"); 
	EndIf;
	
	If NonARMatch = 1 Then
		Message(String(NonARMatch) + " credit was not shown due to non-matching AR Account"); 
	ElsIf NonARMatch > 0 Then
		Message(String(NonARMatch) + " credit were not shown due to non-matching AR Account"); 
	EndIf;
	
	
EndProcedure

&AtServer
// Procedure Fill Line payment according to Discount in salesInvoice
//
Procedure FillPaymentWithDiscount(Object, LineDocument, LineBalance, LinePayment, LineDiscount, AvailablePayment = Undefined) Export
	
	Try
		Terms = LineDocument.Terms; 
	Except
		Terms = Undefined; // Works only for Sales Invoice
	EndTry; 
	
	
	If ValueIsFilled(Terms) Then 
		DiscountPercent = Terms.DiscountPercent;
		DiscountDays = Terms.DiscountDays;
		If (LineDocument.Date + DiscountDays*3600*24) >= Object.Date Then 
			LinePayment = LineBalance*(1-(DiscountPercent*0.01));
			If AvailablePayment = Undefined Then 
				LineDiscount = LineBalance * DiscountPercent*0.01;
			ElsIf LinePayment > AvailablePayment Then 
				If DiscountPercent = 100 Then // Safety check
					LinePayment = 0;
					LineDiscount = AvailablePayment;
				Else 	
					LinePayment = AvailablePayment;
					LineDiscount = (LinePayment/(1-(DiscountPercent*0.01)))*DiscountPercent*0.01;
				EndIf;	
			Else				
				LineDiscount = LineBalance * DiscountPercent*0.01;
			EndIf;	
		Else 
			LineDiscount = 0;
			LinePayment = ?(AvailablePayment = Undefined, LineBalance, AvailablePayment);
		EndIf;	
		
	Else 
		LineDiscount = 0;
		LinePayment = ?(AvailablePayment = Undefined, LineBalance, AvailablePayment);
	EndIf;	
	
EndProcedure	

&AtServer
// Procedure Fill Line payment according to Discount in salesInvoice and limit if it Payment + Discount > Balance
//
Procedure LimitPaymentWithDiscount(Object, LineDocument, LineBalance, LinePayment, LineDiscount) Export
	
	Try
		Terms = LineDocument.Terms; 
	Except
		Terms = Undefined; // Works only for Sales Invoice
	EndTry; 
	
	If LinePayment > LineBalance Then 
		LinePayment = LineBalance;
	EndIf;	
	
	If ValueIsFilled(Terms) Then 
		DiscountPercent = Terms.DiscountPercent;
		DiscountDays = Terms.DiscountDays;
		If (LineDocument.Date + DiscountDays*3600*24) >= Object.Date Then 
			If DiscountPercent <> 100 Then 
				LineDiscount = (LinePayment/(1-(DiscountPercent*0.01)))*DiscountPercent*0.01;
			Else 
				LineDiscount = LineBalance;
			EndIf;
			If LinePayment + LineDiscount > LineBalance Then 
				LineDiscount = LineBalance - LinePayment;
			EndIf;	
		Else 
			LineDiscount = 0;
		EndIf;	
	Else 
		LineDiscount = 0;
	EndIf;	
	
EndProcedure	

&AtServer
// Clear and recalculate Editable and Calculated Values
// Object: DocObject.CashReceipt or FormDataStructure(CashReceipt) From doc form
// ClearItemLimes: If true, will be cleared all editable values in Item Lines
// ClearCreditLines: If true, will be cleared all editable valuesIn credit Memos
Procedure ClearTabularSections(Object, ClearItemLimes = False, ClearCreditLines = False) Export 
	
	If ClearItemLimes Then 
		For Each LineRow In Object.LineItems Do 
			LineRow.Payment = 0;
			LineRow.Discount = 0;
			LineRow.Check = False;
		EndDo;	
	EndIf;	
	
	If ClearCreditLines Then 
		For Each CreditRow In Object.CreditMemos Do 
			CreditRow.Payment = 0;
			CreditRow.Check = False;
		EndDo;	
	EndIf;	
	
EndProcedure

