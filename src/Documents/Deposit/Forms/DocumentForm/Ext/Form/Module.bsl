
&AtClient
Procedure LineItemsBeforeDeleteRow(Item, Cancel)
	Cancel = True;
	Return;
EndProcedure

&AtServer
// Selects cash receipts and cash sales to be deposited and fills in the document's
// line items.
//
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	//Title = "Deposit " + Object.Number + " " + Format(Object.Date, "DLF=D");
	
	If Object.BankAccount.IsEmpty() Then
		Object.BankAccount = Constants.BankAccount.Get();
	Else
	EndIf; 
	
	Items.BankAccountLabel.Title =
		CommonUse.GetAttributeValue(Object.BankAccount, "Description");
	
	If Object.Ref.IsEmpty() Then
			
		Query = New Query;
		// KZUZIK - changed NULL to 0 in CashSale.CashPayment
		Query.Text = "SELECT
		             |	CashReceipt.Ref AS Ref,
		             |	CashReceipt.Currency,
		             |	CashReceipt.CashPayment,
		             |	CashReceipt.DocumentTotal,
		             |	CashReceipt.DocumentTotalRC AS DocumentTotalRC,
		             |	CashReceipt.Date AS Date,
					 |  CashReceipt.Company AS Customer
		             |FROM
		             |	Document.CashReceipt AS CashReceipt
		             |WHERE
		             |	CashReceipt.DepositType = &Undeposited
		             |	AND CashReceipt.Deposited = &InDeposits
		             |
		             |UNION ALL
		             |
		             |SELECT
		             |	CashSale.Ref,
		             |	CashSale.Currency,
		             |	0,                                    
		             |	CashSale.DocumentTotal,
		             |	CashSale.DocumentTotalRC,
		             |	CashSale.Date,
					 |  CashSale.Company
		             |FROM
		             |	Document.CashSale AS CashSale
		             |WHERE
		             |	CashSale.DepositType = &Undeposited
		             |	AND CashSale.Deposited = &InDeposits
		             |
		             |ORDER BY
		             |	Date";

		Query.SetParameter("Undeposited", "1");
		Query.SetParameter("InDeposits", False);

		
		Result = Query.Execute().Choose();
		
		While Result.Next() Do
			
			DataLine = Object.LineItems.Add();
			
			If Result.CashPayment > 0 Then // if there is a credit memo in a cash receipt
				
				DataLine.Document = Result.Ref;
				DataLine.Customer = Result.Customer;
				DataLine.Currency = Result.Currency;
				DataLine.DocumentTotal = Result.CashPayment;
				DataLine.DocumentTotalRC = Result.CashPayment;
				DataLine.Payment = False;
				
			Else
				
				DataLine.Document = Result.Ref;
				DataLine.Customer = Result.Customer;
				DataLine.Currency = Result.Currency;
				DataLine.DocumentTotal = Result.DocumentTotal;
				DataLine.DocumentTotalRC = Result.DocumentTotalRC;
				DataLine.Payment = False;
				
			EndIf;
				
		EndDo;
		
	EndIf;
	
EndProcedure

&AtClient
// Writes deposit data to the originating documents
//
Procedure BeforeWrite(Cancel, WriteParameters)
	
	//If Object.LineItems.Count() = 0 Then
	//	Message("Deposit can not have empty lines. The system automatically shows undeposited documents in the line items");
	//	Cancel = True;
	//	Return;
	//EndIf;	
	//
	//For Each DocumentLine in Object.LineItems Do
	//	If DocumentLine.Document = Undefined Then
	//		Message("Deposit can not have empty lines. The system automatically shows undeposited documents in the line items");
	//		Cancel = True;
	//		Return;
	//	EndIf;
	//EndDo;
							
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
		
		Object.TotalDeposits = Object.TotalDeposits + TabularPartRow.DocumentTotal;
		Object.TotalDepositsRC = Object.TotalDepositsRC + TabularPartRow.DocumentTotalRC;
	EndIf;

    If TabularPartRow.Payment = False Then
		Object.DocumentTotal = Object.DocumentTotal - TabularPartRow.DocumentTotal;
		Object.DocumentTotalRC = Object.DocumentTotalRC - TabularPartRow.DocumentTotalRC;
		
		Object.TotalDeposits = Object.TotalDeposits - TabularPartRow.DocumentTotal;
		Object.TotalDepositsRC = Object.TotalDepositsRC - TabularPartRow.DocumentTotalRC;
	EndIf;

EndProcedure

&AtClient
// Retrieve the account's description
//
Procedure BankAccountOnChange(Item)
	
	Items.BankAccountLabel.Title =
		CommonUse.GetAttributeValue(Object.BankAccount, "Description");
		
EndProcedure

&AtClient
Procedure LineItemsBeforeAddRow(Item, Cancel, Clone, Parent, Folder)
	Cancel = True;
	Return;
EndProcedure

&AtClient
Procedure AccountsOnChange(Item)
	
	Object.DocumentTotal = Object.TotalDeposits + Object.Accounts.Total("Amount");
	Object.DocumentTotalRC = Object.TotalDepositsRC + Object.Accounts.Total("Amount");

EndProcedure

&AtClient
Procedure AccountsAmountOnChange(Item)
	Object.DocumentTotal = Object.TotalDeposits + Object.Accounts.Total("Amount");
	Object.DocumentTotalRC = Object.TotalDepositsRC + Object.Accounts.Total("Amount");
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	HasBankAccounts = False;
	
	For Each CurRowLineItems In Object.Accounts Do
		
		If CurRowLineItems.Account.AccountType = Enums.AccountTypes.Bank Then
			
			HasBankAccounts = True;
			
		EndIf;
				
	EndDo;	
	
	If HasBankAccounts Then
		
		Message = New UserMessage();
		Message.Text=NStr("en='Deposit document can not be used for bank transfers. Use the Bank Transfer document instead.'");
		Message.Message();
		Cancel = True;
		Return;
		
	EndIf;
	
EndProcedure


