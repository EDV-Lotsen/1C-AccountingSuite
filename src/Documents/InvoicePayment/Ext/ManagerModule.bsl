
&AtServer
Function GetLineItemsAccountsQuery() Export
	
	QueryText = "SELECT 
	|	Accounts.Ref As APAccount 
	|INTO TmpAccnts
	|	FROM ChartOfAccounts.ChartOfAccounts As Accounts
	|WHERE Accounts.AccountType = Value(Enum.AccountTypes.AccountsPayable)
	|UNION 
	|SELECT 
	|	ARAccount 
	|	FROM Document.SalesReturn 
	|WHERE Company = &Company ";
	
	Return QueryText;

EndFunction	

&AtServer
Function GetCreditsAccountsQuery() Export
	
	QueryText = "SELECT 
	|	Accounts.Ref As APAccount 
	|INTO TmpAccnts
	|	FROM ChartOfAccounts.ChartOfAccounts As Accounts
	|WHERE Accounts.AccountType = Value(Enum.AccountTypes.AccountsPayable) ";
	
	Return QueryText;

EndFunction	

&AtServer
Procedure PrintCheck(Spreadsheet, Ref) Export
	
	Template = Documents.InvoicePayment.GetTemplate("PrintCheck");
	Query = New Query;
	Query.Text =
	"SELECT
	|	InvoicePayment.Date,
	|	InvoicePayment.Company,
	|	InvoicePayment.RemitTo,
	|	InvoicePayment.DocumentTotalRC,
	|	InvoicePayment.Memo,
	|	InvoicePayment.LineItems.(
	|		Ref,
	|		LineNumber,
	|		Document,
	|		Document.Date,
	|		Document.Number,
	|		VALUETYPE(InvoicePayment.LineItems.Document) AS DocType,
	|		Document.DocumentTotalRC,
	|		Payment,
	|		Balance,
	|		BalanceFCY,
	|		Currency
	|	),
	|	InvoicePayment.BankAccount.Description AS BankDesc,
	|	InvoicePayment.CashPayment,
	|	InvoicePayment.Credits.(
	|		Ref,
	|		LineNumber,
	|		Document,
	|		Document.Date,
	|		Document.Number,
	|		VALUETYPE(InvoicePayment.Credits.Document) AS DocType,
	|		Document.DocumentTotalRC,
	|		Payment,
	|		Document.Currency
	|	)
	|FROM
	|	Document.InvoicePayment AS InvoicePayment
	|WHERE
	|	InvoicePayment.Ref IN(&Ref)";
	Query.Parameters.Insert("Ref", Ref);
	
	//Selection = Query.Execute().Unload();
	
	Selection = Query.Execute().Select();
	
	/////
	AreaCaption = Template.GetArea("Caption");
	Header = Template.GetArea("Header");
	Header2 = Template.GetArea("Header2");
	EndStatement = Template.GetArea("EndStatement");
	EndStatement2 = Template.GetArea("EndStatement2");
	
	Spreadsheet.Clear();
	InsertPageBreak = False;
	While Selection.Next() Do
		If InsertPageBreak Then
			Spreadsheet.PutHorizontalPageBreak();
		EndIf;
		
		Spreadsheet.LeftMargin = 17 + Constants.CheckHorizontalAdj.Get();
		Spreadsheet.TopMargin = 15 + Constants.CheckVerticalAdj.Get();
		
		//Query = New Query;
		//Query.Text =
		//"SELECT
		//|	Addresses.Ref
		//|FROM
		//|	Catalog.Addresses AS Addresses
		//|WHERE
		//|	Addresses.Owner = &Owner
		//|	AND Addresses.DefaultBilling = &True";
		//Query.Parameters.Insert("Owner", Selection.Company);
		//Query.Parameters.Insert("True", True);
		//BillAddr = Query.Execute().Unload();
		//If BillAddr.Count() > 0 Then
		//	ThemBill = PrintTemplates.ContactInfoDataset(Selection.Company, "ThemBill", BillAddr[0].Ref);
		//Else
		//	ThemBill = PrintTemplates.ContactInfoDataset(Selection.Company, "ThemBill",Catalogs.Addresses.EmptyRef());
		//EndIf;
		
		ThemBill = PrintTemplates.ContactInfoDataset(Selection.Company, "ThemBill", Selection.RemitTo);
		
		
		//ThemBill = PrintTemplates.ContactInfoDataset(Selection.Company, "ThemBill", Catalogs.Addresses.EmptyRef());
		
		Spreadsheet.Put(AreaCaption);
		
		Header.Parameters.Fill(Selection);
		Header.Parameters.Fill(ThemBill);
		
		numtostr = string(Selection.CashPayment);   //VS:ACS-2689:3/1/2016: Changed from DocumentTotalRC to CashPayment.
		Result = StrOccurrenceCount(numtostr,".");	
		
		ParametersSubject="dollar and, dollars and, cent, cents, 2";
		
		Rawamount = NumberInWords(Selection.CashPayment,,ParametersSubject);  //VS:ACS-2689:3/1/2016: Changed from DocumentTotalRC to CashPayment.
		
		If Selection.CashPayment > 1 Then         //VS:ACS-2689:3/1/2016: Changed from DocumentTotalRC to CashPayment.
			Rawamount = StrReplace(Rawamount,"dollar ","dollars ");
		Endif;
		
		
		For	i = StrLen(Rawamount) To 110 Do
			Rawamount = Rawamount + "*";
		EndDo;
		
		Header.Parameters.WrittenAmount = "**" + Rawamount;
		
		FormattedNum = Format(Selection.CashPayment, "NFD=2; NZ=0.00");   //VS:ACS-2689:3/1/2016: Changed from DocumentTotalRC to CashPayment.
		Header.Parameters.CashPayment = "**" + FormattedNum + "**";  //VS:ACS-2689:3/1/2016: Changed from DocumentTotalRC to CashPayment.
		
		//If Result = 0 Then
		//	Header.Parameters.DocumentTotalRC = "**" + Selection.DocumentTotalRC + ".00**";
		//Else
		//	FormattedNum = Format(Selection.DocumentTotalRC, "NFD=2");
		//	Header.Parameters.DocumentTotalRC = "**" + FormattedNum + "**";
		
		//Endif;	
		
		RemitTo = ThemBill.RemitTo;
		
		If RemitTo <> "" Then
			Header.Parameters.RemitTo = RemitTo;
		Else
			Header.Parameters.RemitTo = ThemBill.ThemName;
		Endif;
		
		//Header.Parameters.BankAccount = Selection.BankDesc;
		
		Spreadsheet.Put(Header, Selection.Level());		
		
		
		//InvoicePayment Fill
		SelectionLineItems = Selection.LineItems.Select();
		
		TemplateBills = Template.GetArea("Bills");
		InvoiceCount = 0;
		While SelectionLineItems.Next() Do
			
			//--//
			If InvoiceCount = 15 Then
				InvoiceCount = InvoiceCount + 1;
				
				TemplateBills.Parameters.InvoiceDate  = "...";
				TemplateBills.Parameters.Type         = "...";
				TemplateBills.Parameters.ReferenceNum = "..."; 
				TemplateBills.Parameters.OrigAmount   = "...";
				TemplateBills.Parameters.BalDue       = "...";
				TemplateBills.Parameters.Payment      = "...";
				
				Spreadsheet.Put(TemplateBills, SelectionLineItems.Level());
				Continue;
			ElsIf InvoiceCount > 15 Then
				Break;
			EndIf;
			//--//
			
			FormattedDate = Format(SelectionLineItems.Document.Date, "DF=""MM/dd/yyyy""");		                    
			//TemplateBills.Parameters.InvoiceDate = SelectionLineItems.Document.Date;
			TemplateBills.Parameters.InvoiceDate = FormattedDate;
			
			TemplateBills.Parameters.Type = SelectionLineItems.DocType;
			TemplateBills.Parameters.ReferenceNum = SelectionLineItems.Document.Number;
			TemplateBills.Parameters.Payment = SelectionLineItems.Payment;
			
			Query2 = New Query;
			Query2.Text =
			"SELECT
			|	GeneralJournalBalance.AmountRCBalance * -1 AS Balance
			|FROM
			|	AccountingRegister.GeneralJournal.Balance AS GeneralJournalBalance
			|WHERE
			|	GeneralJournalBalance.ExtDimension2 = &Ref2";
			
			Query2.Parameters.Insert("Ref2", SelectionLineItems.Document);
			Query2Result = Query2.Execute();
			If Query2Result.IsEmpty() Then
				BalanceD = 0;
			Else
				BalanceD = Query2.Execute().Unload()[0][0];
			EndIf;
			
			numtostr = string(SelectionLineItems.Document.DocumentTotalRC);
			Result = StrOccurrenceCount(numtostr,".");
			
			FormattedNum = Format(BalanceD, "NFD=2");
			TemplateBills.Parameters.BalDue = FormattedNum;
			
			
			numtostr = string(SelectionLineItems.Document.DocumentTotalRC);
			Result = StrOccurrenceCount(numtostr,".");
			
			FormattedNum = Format(SelectionLineItems.Document.DocumentTotalRC, "NFD=2");
			TemplateBills.Parameters.OrigAmount = FormattedNum;
			
			
			Spreadsheet.Put(TemplateBills, SelectionLineItems.Level());
			InvoiceCount = InvoiceCount + 1;
			
		EndDo;
		
		
		CreditsCount = 0;
		If InvoiceCount <= 15 Then
			SelectionCredits = Selection.Credits.Select();	
			While SelectionCredits.Next() Do
				
				//--//
				If CreditsCount = 15 Then
					CreditsCount = CreditsCount + 1;
					
					TemplateBills.Parameters.InvoiceDate  = "...";
					TemplateBills.Parameters.Type         = "...";
					TemplateBills.Parameters.ReferenceNum = "..."; 
					TemplateBills.Parameters.OrigAmount   = "...";
					TemplateBills.Parameters.BalDue       = "...";
					TemplateBills.Parameters.Payment      = "...";
					
					Spreadsheet.Put(TemplateBills, SelectionCredits.Level());
					Continue;
				ElsIf CreditsCount > 15 Then
					Break;
				EndIf;
				//--//
				
				FormattedDate = Format(SelectionCredits.Document.Date, "DF=""MM/dd/yyyy""");		                    
				//TemplateBills.Parameters.InvoiceDate = SelectionLineItems.Document.Date;
				TemplateBills.Parameters.InvoiceDate = FormattedDate;
				
				TemplateBills.Parameters.Type = SelectionCredits.DocType;
				TemplateBills.Parameters.ReferenceNum = SelectionCredits.Document.Number;
				TemplateBills.Parameters.Payment = SelectionCredits.Payment;
				
				Query2 = New Query;
				Query2.Text =
				"SELECT
				|	GeneralJournalBalance.AmountRCBalance * -1 AS Balance
				|FROM
				|	AccountingRegister.GeneralJournal.Balance AS GeneralJournalBalance
				|WHERE
				|	GeneralJournalBalance.ExtDimension2 = &Ref2";
				
				Query2.Parameters.Insert("Ref2", SelectionCredits.Document);
				Query2Result = Query2.Execute();
				If Query2Result.IsEmpty() Then
					BalanceD = 0;
				Else
					BalanceD = Query2.Execute().Unload()[0][0];
				EndIf;
				
				numtostr = string(SelectionCredits.Document.DocumentTotalRC);
				Result = StrOccurrenceCount(numtostr,".");
				
				FormattedNum = Format(BalanceD, "NFD=2");
				TemplateBills.Parameters.BalDue = FormattedNum;
				
				
				numtostr = string(SelectionCredits.Document.DocumentTotalRC);
				Result = StrOccurrenceCount(numtostr,".");
				
				FormattedNum = Format(SelectionCredits.Document.DocumentTotalRC, "NFD=2");
				TemplateBills.Parameters.OrigAmount = FormattedNum;
				
				
				Spreadsheet.Put(TemplateBills, SelectionCredits.Level());
				CreditsCount = CreditsCount + 1;
				
			EndDo;
		EndIf;
		
		//TemplateArea = Template.GetArea("EmptyArea");
		//  Spreadsheet.Put(TemplateArea);
		FillArea = Template.GetArea("FillArea");
		For I = InvoiceCount + CreditsCount To 15 Do
			Spreadsheet.Put(FillArea);
		EndDo;
		
			
		EndStatement.Parameters.BankAccount = Selection.BankDesc;
		EndStatement.Parameters.Memo = Selection.Memo;
		EndStatement.Parameters.DocumentTotalRC2 = Selection.CashPayment;//VS:ACS-2689:3/1/2016: Changed from DocumentTotalRC to CashPayment.
		Spreadsheet.Put(EndStatement);
		
		
		TemplateArea = Template.GetArea("EmptyArea3");
		Spreadsheet.Put(TemplateArea);
		
		
		Head2 = Template.GetArea("Header2"); 
		Head2.Parameters.Date = Selection.Date;
		If RemitTo <> "" Then
			Head2.Parameters.RemitTo = RemitTo;
		Else
			Head2.Parameters.RemitTo = ThemBill.ThemName;
		Endif;
		Spreadsheet.Put(Head2);
		
		//Second InvoiceFill
		SelectionLineItems = Selection.LineItems.Select();
		
		TemplateBills = Template.GetArea("Bills2");
		InvoiceCount = 0;
		While SelectionLineItems.Next() Do
			
			//--//
			If InvoiceCount = 15 Then
				InvoiceCount = InvoiceCount + 1;
				
				TemplateBills.Parameters.InvoiceDate  = "...";
				TemplateBills.Parameters.Type         = "...";
				TemplateBills.Parameters.ReferenceNum = "..."; 
				TemplateBills.Parameters.OrigAmount   = "...";
				TemplateBills.Parameters.BalDue       = "...";
				TemplateBills.Parameters.Payment      = "...";
				
				Spreadsheet.Put(TemplateBills, SelectionLineItems.Level());
				Continue;
			ElsIf InvoiceCount > 15 Then
				Break;
			EndIf;
			//--//
			
			FormattedDate = Format(SelectionLineItems.Document.Date, "DF=""MM/dd/yyyy""");		                    
			//TemplateBills.Parameters.InvoiceDate = SelectionLineItems.Document.Date;
			TemplateBills.Parameters.InvoiceDate = FormattedDate;
			
			TemplateBills.Parameters.Type = SelectionLineItems.DocType;
			TemplateBills.Parameters.ReferenceNum = SelectionLineItems.Document.Number;
			TemplateBills.Parameters.Payment = SelectionLineItems.Payment;
			
			Query2 = New Query;
			Query2.Text =
			"SELECT
			|	GeneralJournalBalance.AmountRCBalance * -1 AS Balance
			|FROM
			|	AccountingRegister.GeneralJournal.Balance AS GeneralJournalBalance
			|WHERE
			|	GeneralJournalBalance.ExtDimension2 = &Ref2";
			
			Query2.Parameters.Insert("Ref2", SelectionLineItems.Document);
			Query2Result = Query2.Execute();
			If Query2Result.IsEmpty() Then
				BalanceD = 0;
			Else
				BalanceD = Query2.Execute().Unload()[0][0];
			EndIf;
			
			
			
			numtostr = string(SelectionLineItems.Document.DocumentTotalRC);
			Result = StrOccurrenceCount(numtostr,".");
			
			FormattedNum = Format(BalanceD, "NFD=2");
			TemplateBills.Parameters.BalDue = FormattedNum;	
			
			numtostr = string(SelectionLineItems.Document.DocumentTotalRC);
			Result = StrOccurrenceCount(numtostr,".");
			
			FormattedNum = Format(SelectionLineItems.Document.DocumentTotalRC, "NFD=2");
			TemplateBills.Parameters.OrigAmount = FormattedNum;
			
			
			Spreadsheet.Put(TemplateBills, SelectionLineItems.Level());
			InvoiceCount = InvoiceCount + 1;
			
		EndDo;
		//
		
		CreditsCount = 0;
		If InvoiceCount <= 15 Then
			SelectionCredits = Selection.Credits.Select();	
			While SelectionCredits.Next() Do
				
				//--//
				If CreditsCount = 15 Then
					CreditsCount = CreditsCount + 1;
					
					TemplateBills.Parameters.InvoiceDate  = "...";
					TemplateBills.Parameters.Type         = "...";
					TemplateBills.Parameters.ReferenceNum = "..."; 
					TemplateBills.Parameters.OrigAmount   = "...";
					TemplateBills.Parameters.BalDue       = "...";
					TemplateBills.Parameters.Payment      = "...";
					
					Spreadsheet.Put(TemplateBills, SelectionCredits.Level());
					Continue;
				ElsIf CreditsCount > 15 Then
					Break;
				EndIf;
				//--//
				
				FormattedDate = Format(SelectionCredits.Document.Date, "DF=""MM/dd/yyyy""");		                    
				//TemplateBills.Parameters.InvoiceDate = SelectionLineItems.Document.Date;
				TemplateBills.Parameters.InvoiceDate = FormattedDate;
				
				TemplateBills.Parameters.Type = SelectionCredits.DocType;
				TemplateBills.Parameters.ReferenceNum = SelectionCredits.Document.Number;
				TemplateBills.Parameters.Payment = SelectionCredits.Payment;
				
				Query2 = New Query;
				Query2.Text =
				"SELECT
				|	GeneralJournalBalance.AmountRCBalance * -1 AS Balance
				|FROM
				|	AccountingRegister.GeneralJournal.Balance AS GeneralJournalBalance
				|WHERE
				|	GeneralJournalBalance.ExtDimension2 = &Ref2";
				
				Query2.Parameters.Insert("Ref2", SelectionCredits.Document);
				Query2Result = Query2.Execute();
				If Query2Result.IsEmpty() Then
					BalanceD = 0;
				Else
					BalanceD = Query2.Execute().Unload()[0][0];
				EndIf;
				
				numtostr = string(SelectionCredits.Document.DocumentTotalRC);
				Result = StrOccurrenceCount(numtostr,".");
				
				FormattedNum = Format(BalanceD, "NFD=2");
				TemplateBills.Parameters.BalDue = FormattedNum;
				
				
				numtostr = string(SelectionCredits.Document.DocumentTotalRC);
				Result = StrOccurrenceCount(numtostr,".");
				
				FormattedNum = Format(SelectionCredits.Document.DocumentTotalRC, "NFD=2");
				TemplateBills.Parameters.OrigAmount = FormattedNum;
				
				
				Spreadsheet.Put(TemplateBills, SelectionCredits.Level());
				CreditsCount = CreditsCount + 1;
				
			EndDo;
		EndIf;
		
		//TemplateArea = Template.GetArea("EmptyArea");
		//  Spreadsheet.Put(TemplateArea);
		FillArea = Template.GetArea("FillArea");
		For I = InvoiceCount + CreditsCount To 15 Do
			Spreadsheet.Put(FillArea);
		EndDo;
		
		
		EndStatement2.Parameters.BankAccount = Selection.BankDesc;
		EndStatement2.Parameters.Memo = Selection.Memo;
		EndStatement2.Parameters.DocumentTotalRC2 = Selection.CashPayment;//VS:ACS-2689:3/1/2016: Changed from DocumentTotalRC to CashPayment.
		
		Spreadsheet.Put(EndStatement2);
		
		
		InsertPageBreak = True;
		
		//
		Spreadsheet.PageSize = "Letter"; 
		Spreadsheet.FitToPage = True;
		
	EndDo;
	
	
EndProcedure
//////////////////////////////////////////////////////////////////////
//-------------------------Filling procedures------------------------- 

&AtServer
// The procedure selects all vendor invoices and customer returns having an unpaid balance
// and fills in line items of an invoice payment.
//
Procedure FillDocumentList(Object, Company) Export
		
	Object.LineItems.Clear();
	
	Query = New Query;
	Query.Text = GetLineItemsAccountsQuery() + "
	|;
	|SELECT
	|	GeneralJournalBalance.AmountBalance * -1 AS AmountBalance,
	|	GeneralJournalBalance.AmountRCBalance * -1 AS AmountRCBalance,
	|	GeneralJournalBalance.ExtDimension2.Ref AS Ref,
	|	Isnull(GeneralJournalBalance.ExtDimension2.Currency, GeneralJournalBalance.Currency) AS Currency,
	|	GeneralJournalBalance.ExtDimension2.Date
	|FROM
	|	AccountingRegister.GeneralJournal.Balance(,Account IN (SELECT APAccount FROM TmpAccnts as TmpAccnts) ) AS GeneralJournalBalance
	|WHERE
	|	GeneralJournalBalance.AmountBalance <> 0
	|	AND (GeneralJournalBalance.ExtDimension2 REFS Document.PurchaseInvoice OR
	|		GeneralJournalBalance.ExtDimension2 REFS Document.Deposit OR
	|		GeneralJournalBalance.ExtDimension2 REFS Document.GeneralJournalEntry OR
	|		GeneralJournalBalance.ExtDimension2 REFS Document.SalesReturn)
	|	AND GeneralJournalBalance.ExtDimension1 = &Company
	|ORDER BY
	|	GeneralJournalBalance.ExtDimension2.Date";
	
	Query.SetParameter("Company", Company);
	
	Result = Query.Execute().Select();
	
	NonCurrencyMatch = 0;
	
	While Result.Next() Do
		
		CurDiscountDate = Date('00010101');
		
		If TypeOf(Result.Ref) = Type("DocumentRef.GeneralJournalEntry") Then  
			If Result.AmountBalance < 0 Then 
				Continue;
			EndIf;
		ElsIf TypeOf(Result.Ref) = Type("DocumentRef.PurchaseInvoice") Then  
			CurrentLineDoc = Result.Ref;
			LineTerms = CurrentLineDoc.Terms; 
			If ValueIsFilled(LineTerms) Then 
				LineDiscountDays = LineTerms.DiscountDays;
				If LineDiscountDays <> 0 Then 
					CurDiscountDate = CurrentLineDoc.Date + LineDiscountDays*3600*24;
				EndIf;	
			EndIf;
			
			
		ElsIf TypeOf(Result.Ref) = Type("DocumentRef.Deposit") Then  
			
		ElsIf TypeOf(Result.Ref) = Type("DocumentRef.SalesReturn") Then  
			
		Endif;
		
		If Result.Currency <> Company.DefaultCurrency Then
			NonCurrencyMatch = NonCurrencyMatch + 1;
			Continue;
		EndIf;	
		
		DataLine = Object.LineItems.Add();
		
		DataLine.Document = Result.Ref;
		DataLine.Currency = Result.Currency;
		
		Dataline.BalanceFCY = Result.AmountBalance;
		Dataline.Balance = Result.AmountRCBalance;
		DataLine.Payment = 0;
		DataLine.DiscountDate = CurDiscountDate;
	EndDo;	
	
	If NonCurrencyMatch = 1 Then
		Message(String(NonCurrencyMatch) + " Bill was not shown due to non-matching currency"); 
	ElsIf NonCurrencyMatch > 0 Then
		Message(String(NonCurrencyMatch) + " Bills were not shown due to non-matching currency"); 
	EndIf;

	
EndProcedure

&AtServer
// Procedure selects all opened vendor credits
//
Procedure FillCreditList(Object, Company) Export 
	
	Object.Credits.Clear();
	
	If Not Object.Ref.IsEmpty() Then 
		Query = New Query;
		Query.Text = 
		"SELECT
		|	FALSE AS Found,
		|	InvoicePaymentCredits.Document,
		|	InvoicePaymentCredits.Payment
		|FROM
		|	Document.InvoicePayment.Credits AS InvoicePaymentCredits
		|WHERE
		|	InvoicePaymentCredits.Ref = &Ref
		|ORDER BY
		|	InvoicePaymentCredits.LineNumber";
		
		Query.SetParameter("Ref", Object.Ref);
		CurrentCredits = Query.Execute().Unload();
		For Each Row in CurrentCredits Do 
			LineItems = Object.Credits.Add();
			LineItems.Document = Row.Document;
			LineItems.BalanceFCY2 = Row.Payment;
			LineItems.Payment = Row.Payment;
			LineItems.Check = True;
			LineItems.Currency = Constants.DefaultCurrency.Get();
		EndDo;	
	EndIf;
	
	Query = New Query;
	Query.Text = Documents.InvoicePayment.GetCreditsAccountsQuery() + "
	|;
	|SELECT
	|	GeneralJournalBalance.AmountBalance AS BalanceFCY2,
	|	0 AS Payment,
	|	GeneralJournalBalance.ExtDimension2.Ref AS Document,
	|	ISNULL(GeneralJournalBalance.ExtDimension2.Ref.Currency, GeneralJournalBalance.Currency) AS Currency,
	|	False AS Check
	|FROM
	|	AccountingRegister.GeneralJournal.Balance(,	Account IN (SELECT APAccount FROM TmpAccnts as TmpAccnts),,
	|			ExtDimension1 = &Company AND
	|          (ExtDimension2 REFS Document.PurchaseReturn 
	|			OR ExtDimension2 REFS Document.GeneralJournalEntry
	|			OR ExtDimension2 REFS Document.Check
	|			OR ExtDimension2 REFS Document.InvoicePayment))
	|			AS GeneralJournalBalance
	|
	|ORDER BY
	|  GeneralJournalBalance.ExtDimension2.Date";				 
				 
	Query.SetParameter("Date",    ?(ValueIsFilled(Object.Ref), New Boundary(Object.Date, BoundaryType.Including), CurrentSessionDate()));
	Query.SetParameter("Company", Company);
	
	NonCurrencyMatch = 0;
	
	ResultSelection = Query.Execute().Select();
	While ResultSelection.Next() Do
		
		If (ResultSelection.Document = Object.Ref) And (Not Object.Ref.IsEmpty()) Then 
			Continue;
		EndIf;
		
		If TypeOf(ResultSelection.Document) = Type("DocumentRef.GeneralJournalEntry") Then  
			If ResultSelection.BalanceFCY2 < 0 Then 
				Continue;
			EndIf;
		ElsIf TypeOf(ResultSelection.Document) = Type("DocumentRef.InvoicePayment") Then  
			
		ElsIf TypeOf(ResultSelection.Document) = Type("DocumentRef.Check") Then  
			
		ElsIf TypeOf(ResultSelection.Document) = Type("DocumentRef.PurchaseReturn") Then  
			
		Endif;
		
		If ResultSelection.Currency = Company.DefaultCurrency Then
			FoundRows = Object.Credits.FindRows(New Structure("Document",ResultSelection.Document));
			If FoundRows.Count() > 0  Then 
				LineItems = FoundRows[0];
				LineItems.BalanceFCY2 = LineItems.BalanceFCY2 + ResultSelection.BalanceFCY2;
			Else 	
				LineItems = Object.Credits.Add();
				FillPropertyValues(LineItems, ResultSelection);
			EndIf;	
		Else
			NonCurrencyMatch = NonCurrencyMatch + 1;
		EndIf;
		
	EndDo;
	
	If NonCurrencyMatch = 1 Then
		Message(String(NonCurrencyMatch) + " credit was not shown due to non-matching currency"); 
	ElsIf NonCurrencyMatch > 0 Then
		Message(String(NonCurrencyMatch) + " credits were not shown due to non-matching currency"); 
	EndIf;
	
EndProcedure	


//////////////////////////////////////////////////////////////////////
//------------------------- Recalc procedures ------------------------

&AtServer
// Calculations for cash payments
Procedure CashPaymentCalculation(Object) Export
	
	TotalCredit = Object.Credits.Total("Payment");
	TotalAmountToDistribute = TotalCredit;
	
	ClearTabularSections(Object, True, False);
	
	For Each LineItem In Object.LineItems Do
		LineItem.Payment = 0;
		
		LineBalance = LineItem.BalanceFCY;
		If TotalAmountToDistribute = 0 Then 
			Break;
		ElsIf TotalAmountToDistribute < LineBalance Then 
			FillPaymentWithDiscount(Object, LineItem.Document, LineItem.BalanceFCY, LineItem.Payment, LineItem.Discount, TotalAmountToDistribute);
			TotalAmountToDistribute = TotalAmountToDistribute - LineItem.Payment;
		Else	
			FillPaymentWithDiscount(Object, LineItem.Document, LineItem.BalanceFCY, LineItem.Payment, LineItem.Discount);
			TotalAmountToDistribute = TotalAmountToDistribute - LineItem.Payment;
		EndIf;
		
		If LineItem.Payment > 0 Then 
			LineItem.Check = True;
		EndIf;	
	EndDo;
	
	AdditionalPaymentCall(Object);
	
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
		For Each CreditRow In Object.Credits Do 
			CreditRow.Payment = 0;
			CreditRow.Check = False;
		EndDo;	
	EndIf;	
	
EndProcedure

&AtServer
// Used to recalculate the CashPayment value and DocumentTotal values when there is a change in the document
Procedure AdditionalPaymentCall(Object, RecalcUP = True) Export

	TotalDiscount = Object.LineItems.Total("Discount");
	TotalInvoices = Object.LineItems.Total("Payment");
	TotalCredit = Object.Credits.Total("Payment");
	ExchangeRate = GeneralFunctions.GetExchangeRate(Object.Date,Object.Currency);
	
	If (Object.UnappliedPayment < TotalCredit-TotalInvoices) or RecalcUP Then 
		Object.UnappliedPayment = TotalCredit-TotalInvoices
	EndIf;	
	
	Object.CashPayment = Object.UnappliedPayment + TotalInvoices - TotalCredit;
	
	
	Object.DocumentTotalRC = (Object.CashPayment * ExchangeRate) + (TotalCredit * ExchangeRate) + (TotalDiscount * ExchangeRate);
	Object.DocumentTotal = Object.CashPayment + TotalCredit + TotalDiscount;
	Object.DiscountAmount = TotalDiscount;
	
EndProcedure

&AtServer
// Calculates the object's unapplied
Procedure UnappliedCalculation_Old(Object) Export
		
	TotalLinePayment = Object.LineItems.Total("Payment");
	TotalCredit = Object.Credits.Total("Payment");
	
	Object.UnappliedPayment = (Object.CashPayment + TotalCredit) - TotalLinePayment;
	
EndProcedure

&AtServer
// Calculates the object's unapplied
Procedure CalculateCashPaymentBasedOnUnappliedPayment_Old(Object) Export
		
	TotalLinePayment = Object.LineItems.Total("Payment");
	TotalCredit = Object.Credits.Total("Payment");
	Object.CashPayment = Object.UnappliedPayment + TotalLinePayment - TotalCredit;
	
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



//////////////////////////////////////////////////////////////////////

&AtServer
Procedure Test()
	
	Spread = New SpreadsheetDocument;
	test = Spread.PageWidth;
EndProcedure