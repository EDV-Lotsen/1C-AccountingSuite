
&AtClient
// StatementToDateOnChange UI event handler.
// A reconciliation document repopulates its line items upon the ToDate field change,
// cleared amount is set to 0, cleared balance is recalculated, interest and service charge dates are
// defaulted to the ToDate.
//
Procedure StatementToDateOnChange(Item)
	
	FillReconciliationSpec(Object.StatementFromDate, Object.StatementToDate, Object.BankAccount);
	Object.ClearedAmount = 0;
	RecalcClearedBalance(0);
	Object.InterestEarnedDate = Object.StatementToDate;
	Object.ServiceChargeDate = Object.StatementToDate;
	
EndProcedure

&AtServer
// The procedure fills in line items of a bank reconciliation document.
// Three types of documents are selected - deposits for incoming payments, and payments and purchase
// payments for outgoing payments (thus the amounts are multiplied by -1) in the DateFrom
// DateTo interval.
//
Procedure FillReconciliationSpec(StatementFromDate, StatementToDate, BankAccount)
	
	Object.LineItems.Clear();
	
	Query = New Query("SELECT
	                  |	Deposit.DocumentTotal,
	                  |	Deposit.Ref,
	                  |	NULL AS Company
	                  |FROM
	                  |	Document.Deposit AS Deposit
	                  |WHERE
	                  |	Deposit.Date BETWEEN &StatementFromDate AND &StatementToDate
	                  |	AND Deposit.BankAccount = &BankAccount
	                  |
	                  |UNION ALL
	                  |
	                  |SELECT
	                  |	Payment.DocumentTotal * -1,
	                  |	Payment.Ref,
	                  |	Payment.Company
	                  |FROM
	                  |	Document.Payment AS Payment
	                  |WHERE
	                  |	Payment.Date BETWEEN &StatementFromDate AND &StatementToDate
					  | AND Payment.BankAccount = &BankAccount
					  |
	                  |UNION ALL
	                  |
	                  |SELECT
	                  |	CashPurchase.DocumentTotal * -1,
	                  |	CashPurchase.Ref,
	                  |	CashPurchase.Company
	                  |FROM
	                  |	Document.CashPurchase AS CashPurchase
	                  |WHERE
	                  |	CashPurchase.Date BETWEEN &StatementFromDate AND &StatementToDate
					  | AND CashPurchase.BankAccount = &BankAccount");
	
	Query.SetParameter("StatementFromDate", StatementFromDate);
	Query.SetParameter("StatementToDate", StatementToDate);
	Query.SetParameter("BankAccount", BankAccount);
	
	Result = Query.Execute().Choose();
	
	While Result.Next() Do
		
		DataLine = Object.LineItems.Add();
		
		DataLine.Transaction = Result.Ref;
		DataLine.TransactionAmount = Result.DocumentTotal;
		DataLine.Company = Result.Company;
		
	EndDo;
	
EndProcedure

&AtClient
// All related dynamic lists are notified of changes in the data
//
Procedure AfterWrite(WriteParameters)
	
		For Each DocumentLine in Object.LineItems Do
		
			RepresentDataChange(DocumentLine.Transaction, DataChangeType.Update);
		
		EndDo;

EndProcedure

&AtClient
// LineItemsClearedOnChange UI event handler.
// When a particular amount is cleared the procedure recalculates a cleared balance.
//
Procedure LineItemsClearedOnChange(Item)
	
	TabularPartRow = Items.LineItems.CurrentData;
	RecalcClearedBalance(TabularPartRow.TransactionAmount);
	
EndProcedure

&AtClient
// The procedure recalculates a cleared balance as beginning balance + interest earned
// - service charge + amount cleared in this line.
//
Procedure RecalcClearedBalance(Amount)
	
	Object.ClearedAmount = Object.ClearedAmount + Amount;	
	Object.ClearedBalance = Object.BeginningBalance + Object.InterestEarned -
		Object.ServiceCharge + Object.ClearedAmount;	
	Object.Difference = Object.EndingBalance - Object.ClearedBalance;
	
EndProcedure

&AtClient
// ServiceChargeOnChange UI event handler. The procedure recalculates a cleared balance.
//
Procedure ServiceChargeOnChange(Item)
	
	RecalcClearedBalance(0);
	
EndProcedure

&AtClient
// InterestEarnedOnChange UI event handler. The procedure recalculates a cleared balance.
//
Procedure InterestEarnedOnChange(Item)
	
	RecalcClearedBalance(0);
	
EndProcedure

&AtClient
// BeginningBalancedOnChange UI event handler. The procedure recalculates a cleared balance.
//
Procedure BeginningBalanceOnChange(Item)
	
	RecalcClearedBalance(0);
	
EndProcedure

&AtClient
// EndgingBalanceOnChange UI event handler. The procedure recalculates a cleared balance.
//
Procedure EndingBalanceOnChange(Item)
	
	RecalcClearedBalance(0);
	
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	//Title = "Bank rec. " + Object.Number + " " + Format(Object.Date, "DLF=D");
	
	If Object.BankAccount.IsEmpty() Then
		Object.BankAccount = Constants.BankAccount.Get();
	Else
	EndIf; 
	
	Items.BankAccountLabel.Title =
		GeneralFunctions.GetAttributeValue(Object.BankAccount, "Description");

EndProcedure

&AtClient
Procedure BankAccountOnChange(Item)
	
	Items.BankAccountLabel.Title =
		GeneralFunctions.GetAttributeValue(Object.BankAccount, "Description");
		
	DoMessageBox("Update the Statement To date to recalculate the reconciliation");

EndProcedure


