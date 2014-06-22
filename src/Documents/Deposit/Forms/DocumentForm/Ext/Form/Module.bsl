
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
	
	If Parameters.Property("Company") Then
		
		NewLine = Object.Accounts.Add();
		NewLine.Company = Parameters.Company; 	
		
	EndIf;
	
	//ConstantDeposit = Constants.DepositLastNumber.Get();
	//If Object.Ref.IsEmpty() Then		
	//	
	//	Object.Number = Constants.DepositLastNumber.Get();
	//Endif;

	
	//Title = "Deposit " + Object.Number + " " + Format(Object.Date, "DLF=D");
	
	If Object.BankAccount.IsEmpty() Then
		Object.BankAccount = Constants.BankAccount.Get();
	Else
	EndIf; 
		
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

		
		Result = Query.Execute().Select();
		
		While Result.Next() Do

			//Changed
			//DataLine = Object.LineItems.Add();
			
			If Result.CashPayment > 0 Then // if there is a credit memo in a cash receipt
				DataLine = Object.LineItems.Add();
				DataLine.Document = Result.Ref;
				DataLine.Customer = Result.Customer;
				DataLine.Currency = Result.Currency;
				DataLine.DocumentTotal = Result.CashPayment;
				DataLine.DocumentTotalRC = Result.CashPayment;
				DataLine.Payment = False;
				
			Else
				//Modification by Bernard
				If TypeOf(Result.Ref) <> Type("DocumentRef.CashReceipt") Then
				    DataLine = Object.LineItems.Add();
					DataLine.Document = Result.Ref;
					DataLine.Customer = Result.Customer;
					DataLine.Currency = Result.Currency;
					DataLine.DocumentTotal = Result.DocumentTotal;
					DataLine.DocumentTotalRC = Result.DocumentTotalRC;
					DataLine.Payment = False;
					
				Endif;
				
			EndIf;
				
		EndDo;
		
	EndIf;
	
EndProcedure

&AtClient
// Writes deposit data to the originating documents
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
	If ReconciledDocumentsServerCall.RequiresExcludingFromBankReconciliation(Object.Ref, Object.DocumentTotalRC, Object.Date, Object.BankAccount, WriteParameters.WriteMode) Then
		Cancel = True;
		CommonUseClient.ShowCustomMessageBox(ThisForm, "Bank reconciliation", "The transaction you are editing has been reconciled. Saving 
		|your changes could put you out of balance the next time you try to reconcile. 
		|To modify it you should exclude it from the Bank rec. document.", PredefinedValue("Enum.MessageStatus.Warning"));
	EndIf;    
	
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
	
	//Checked = False;
	//For Each DocLine In Object.LineItems Do
	//	
	//	If DocLine.Payment = True Then
	//		Checked = True;
	//	EndIf;
	//EndDo;
	//
	//If Checked = False  Then
	//	Message("Cannot post with no line items.");
	//	Cancel = True;
	//	Return;
	//EndIf;

	
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

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)		
	
	//Period closing
	If PeriodClosingServerCall.DocumentPeriodIsClosed(CurrentObject.Ref, CurrentObject.Date) Then
		PermitWrite = PeriodClosingServerCall.DocumentWritePermitted(WriteParameters);
		CurrentObject.AdditionalProperties.Insert("PermitWrite", PermitWrite);	
	EndIf;

	//If Object.Ref.IsEmpty() Then
	//
	//	MatchVal = Increment(Constants.DepositLastNumber.Get());
	//	If Object.Number = MatchVal Then
	//		Constants.DepositLastNumber.Set(MatchVal);
	//	Else
	//		If Increment(Object.Number) = "" Then
	//		Else
	//			If StrLen(Increment(Object.Number)) > 20 Then
	//				 Constants.DepositLastNumber.Set("");
	//			Else
	//				Constants.DepositLastNumber.Set(Increment(Object.Number));
	//			Endif;

	//		Endif;
	//	Endif;
	//Endif;
	//
	//If Object.Number = "" Then
	//	Message("Deposit Number is empty");
	//	Cancel = True;
	//Endif;

EndProcedure

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
		
		If  Object.Ref.IsEmpty() Then
			AccountsOnChange(Items.Accounts);	
		EndIf;	
		///////////////////////////////////////////////
	Else
		AttachIdleHandler("AfterOpen", 0.1, True);
	EndIf;		
	
EndProcedure


