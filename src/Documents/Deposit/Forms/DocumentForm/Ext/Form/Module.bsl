
&AtClient
Procedure LineItemsBeforeDeleteRow(Item, Cancel)
	Cancel = True;
	Return;
EndProcedure

&AtServer
// Selects receipts and customer payments to be deposited and fills in the document's
// line items.
//
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	//Title = "Deposit " + Object.Number + " " + Format(Object.Date, "DLF=D");
	
	If Object.BankAccount.IsEmpty() Then
		Object.BankAccount = Constants.BankAccount.Get();
	Else
	EndIf; 
	
	Items.BankAccountLabel.Title =
		GeneralFunctions.GetAttributeValue(Object.BankAccount, "Description");
	
	If Object.Ref.IsEmpty() Then
			
		Query = New Query;
		Query.Text = "SELECT
		             |	Receipt.Ref,
					 |	Receipt.Currency,
		             |	Receipt.DocumentTotal,
		             |	Receipt.DocumentTotalRC AS DocumentTotalRC
		             |FROM
		             |	Document.Receipt AS Receipt
		             |WHERE
		             |	Receipt.DepositType = &Undeposited
		             |	AND Receipt.Deposited = &InDeposits
					 |
					 |UNION ALL
					 |
					 |SELECT
					 |	CashSale.Ref,
					 |  CashSale.Currency,
		             |	CashSale.DocumentTotal,
		             |	CashSale.DocumentTotalRC
		             |FROM
		             |	Document.CashSale AS CashSale
		             |WHERE
		             |	CashSale.DepositType = &Undeposited
		             |	AND CashSale.Deposited = &InDeposits";

		Query.SetParameter("Undeposited", "1");
		Query.SetParameter("InDeposits", False);

					 
		Result = Query.Execute().Choose();
		
		While Result.Next() Do
			
			DataLine = Object.LineItems.Add();
			
			DataLine.Document = Result.Ref;
			DataLine.Currency = Result.Currency;
			DataLine.DocumentTotal = Result.DocumentTotal;
			DataLine.DocumentTotalRC = Result.DocumentTotalRC;
			DataLine.Payment = False;
			
		EndDo;

	EndIf;
	
EndProcedure

&AtClient
// Writes deposit data to the originating documents
//
Procedure BeforeWrite(Cancel, WriteParameters)
	
	If Object.LineItems.Count() = 0 Then
		Message("Deposit can not have empty lines. The system automatically shows undeposited documents in the line items");
		Cancel = True;
		Return;
	EndIf;	
	
	For Each DocumentLine in Object.LineItems Do
		If DocumentLine.Document = Undefined Then
			Message("Deposit can not have empty lines. The system automatically shows undeposited documents in the line items");
			Cancel = True;
			Return;
		EndIf;
	EndDo;
							
	// deletes from this document lines that were not marked as deposited
	
	NumberOfLines = Object.LineItems.Count() - 1;
	
	While NumberOfLines >=0 Do
		
		If Object.LineItems[NumberOfLines].Payment = False Then
			Object.LineItems.Delete(NumberOfLines);
		Else
		EndIf;
		
		NumberOfLines = NumberOfLines - 1;
		
	EndDo;
	
EndProcedure

&AtClient
// Calculates document total
// 
Procedure LineItemsPaymentOnChange(Item)
	
	TabularPartRow = Items.LineItems.CurrentData;
	
	If TabularPartRow.Payment Then
		Object.DocumentTotal = Object.DocumentTotal + TabularPartRow.DocumentTotal;
		Object.DocumentTotalRC = Object.DocumentTotalRC + TabularPartRow.DocumentTotalRC;
	EndIf;

    If TabularPartRow.Payment = False Then
		Object.DocumentTotal = Object.DocumentTotal - TabularPartRow.DocumentTotal;
		Object.DocumentTotalRC = Object.DocumentTotalRC - TabularPartRow.DocumentTotalRC;
	EndIf;

EndProcedure

&AtClient
// Retrieve the account's description
//
Procedure BankAccountOnChange(Item)
	
	Items.BankAccountLabel.Title =
		GeneralFunctions.GetAttributeValue(Object.BankAccount, "Description");
		
EndProcedure

&AtClient
Procedure LineItemsBeforeAddRow(Item, Cancel, Clone, Parent, Folder)
	Cancel = True;
	Return;
EndProcedure
