
&AtServer
// The procedure selects all vendor invoices and customer returns having an unpaid balance
// and fills in line items of a payment.
//
Procedure FillDocumentList(Company)
		
	Object.LineItems.Clear();
	
	Query = New Query;
	Query.Text = "SELECT
	             |	GeneralJournalBalance.AmountBalance * -1 AS AmountBalance,
	             |	GeneralJournalBalance.AmountRCBalance * -1 AS AmountRCBalance,
	             |	GeneralJournalBalance.ExtDimension2.Ref AS Ref
	             |FROM
	             |	AccountingRegister.GeneralJournal.Balance AS GeneralJournalBalance
	             |WHERE
	             |	GeneralJournalBalance.AmountBalance <> 0
	             |	AND GeneralJournalBalance.ExtDimension2 REFS Document.PurchaseInvoice
	             |	AND GeneralJournalBalance.ExtDimension1 = &Company
	             |
	             |UNION ALL
	             |
	             |SELECT
	             |	GeneralJournalBalance.AmountBalance * -1,
	             |	GeneralJournalBalance.AmountRCBalance * -1,
	             |	GeneralJournalBalance.ExtDimension2.Ref
	             |FROM
	             |	AccountingRegister.GeneralJournal.Balance AS GeneralJournalBalance
	             |WHERE
	             |	GeneralJournalBalance.AmountBalance <> 0
	             |	AND GeneralJournalBalance.ExtDimension2 REFS Document.SalesReturn
	             |	AND GeneralJournalBalance.ExtDimension1 = &Company";
				 
	Query.SetParameter("Company", Company);
	
	Result = Query.Execute().Choose();
	
	While Result.Next() Do
		
		DataLine = Object.LineItems.Add();
		
		DataLine.Document = Result.Ref;
		DataLine.Currency = Result.Ref.Currency;
		Dataline.DueFCY = Result.AmountBalance;
		Dataline.Due = Result.AmountRCBalance;
		DataLine.Payment = 0;
		
	EndDo;	
	
EndProcedure

&AtClient
// CompanyOnChange UI event handler. The procedure repopulates line items upon a company change.
//
Procedure CompanyOnChange(Item)
	
	FillDocumentList(Object.Company);
	
EndProcedure


&AtClient
// The procedure notifies all related dynamic lists that the changes in data have occured.
//
Procedure AfterWrite(WriteParameters)
	
	For Each DocumentLine in Object.LineItems Do
		
		RepresentDataChange(DocumentLine.Document, DataChangeType.Update);
		
	EndDo;
		
EndProcedure

&AtClient
// The procedure deletes all line items which are
// not paid by this payment
//
Procedure BeforeWrite(Cancel, WriteParameters)
	
	If Object.LineItems.Count() = 0 Then
		Message("Payment can not have empty lines. The system automatically shows unpaid documents to the selected company in the line items");
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
// LineItemsPaymentOnChange UI event handler.
// The procedure calculates a document total in the foreign currency (DocumentTotal) and in the
// reporting currency (DocumentTotalRC).
//
Procedure LineItemsPaymentOnChange(Item)
	
	TabularPartRow = Items.LineItems.CurrentData;
	Object.DocumentTotal = Object.LineItems.Total("Payment");
	ExchangeRate = GeneralFunctions.GetExchangeRate(Object.Date, GeneralFunctionsReusable.DefaultCurrency(),
		GeneralFunctions.GetSpecDocumentCurrency(TabularPartRow.Document));
    Object.DocumentTotalRC = Object.LineItems.Total("Payment") * ExchangeRate;
	
EndProcedure

&AtClient
// Retrieves the account's description
//
Procedure BankAccountOnChange(Item)
	
	Items.BankAccountLabel.Title =
		GeneralFunctions.GetAttributeValue(Object.BankAccount, "Description");

EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	//Title = "Payment " + Object.Number + " " + Format(Object.Date, "DLF=D");
	
	If Object.BankAccount.IsEmpty() Then
		Object.BankAccount = Constants.BankAccount.Get();
	Else
	EndIf; 

	Items.BankAccountLabel.Title =
		GeneralFunctions.GetAttributeValue(Object.BankAccount, "Description");
		
	If GeneralFunctionsReusable.FunctionalOptionValue("MultiCurrency") Then	
		Items.LineItemsPayment.Title = "Payment FCY";	
	EndIf;	
		
EndProcedure