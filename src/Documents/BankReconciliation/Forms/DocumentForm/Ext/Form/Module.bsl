


&AtClient
// StatementToDateOnChange UI event handler.
// A reconciliation document repopulates its line items upon the ToDate field change,
// cleared amount is set to 0, cleared balance is recalculated, interest and service charge dates are
// defaulted to the ToDate.
//
Procedure StatementToDateOnChange(Item)
	
	FillReconciliationSpec(Object.StatementToDate, Object.BankAccount);
	Object.ClearedAmount = 0;
	
	DTotal = 0;
	For Each DocumentLine in Object.LineItems Do	
		If DocumentLine.Cleared = True Then
			DTotal = DTotal + DocumentLine.TransactionAmount;
		EndIf;
	EndDo;
	
	Object.ClearedAmount = DTotal;
	
	RecalcClearedBalance(0);
	Object.InterestEarnedDate = Object.StatementToDate;
	Object.ServiceChargeDate = Object.StatementToDate;
	
EndProcedure

&AtServer
// The procedure fills in line items of a bank reconciliation document.
// Three types of documents are selected - deposits for cash receipts, invoice payments and cash purchases
// in the DateFrom DateTo interval.
//
Procedure FillReconciliationSpec(StatementToDate, BankAccount)
	
	OldLI = New Array;
	
	For Each DocumentLine in Object.LineItems Do
		
		If DocumentLine.Cleared = True Then
			
			OldLineItems = New Structure;
			OldLineItems.Insert("Transaction", DocumentLine.Transaction);
			OldLineItems.Insert("Date", DocumentLine.Date);
			OldLineItems.Insert("TransactionAmount", DocumentLine.TransactionAmount);
			OldLineItems.Insert("Company", DocumentLine.Company);			
			OldLI.Add(OldLineItems);
			
		EndIf;
		
	EndDo;
	
	Object.LineItems.Clear();
	
	NumOfRows = OldLI.Count();
	
	For i = 1 To NumOfRows Do
		
		DataLine = Object.LineItems.Add();
		DataLine.Transaction = OldLI[i-1].Transaction;
		DataLine.Date = OldLI[i-1].Date;
		DataLine.Cleared = True;
		DataLine.TransactionAmount = OldLI[i-1].TransactionAmount;
		DataLine.Company = OldLI[i-1].Company;
		
	EndDo;
	
	Query = New Query("SELECT
	                  |	TransactionReconciliation.Document AS Ref,
					  |	TransactionReconciliation.Document.Date AS Date,
	                  |	TransactionReconciliation.Document.Company AS Company,
	                  |	TransactionReconciliation.Amount AS DocumentTotal
	                  |FROM
	                  |	InformationRegister.TransactionReconciliation AS TransactionReconciliation
	                  |WHERE
	                  |	TransactionReconciliation.Document.Date <= &StatementToDate
	                  |	AND TransactionReconciliation.Account = &BankAccount
	                  |	AND TransactionReconciliation.Reconciled = FALSE
	                  |
	                  |ORDER BY
	                  |	TransactionReconciliation.Document.Date");
						  
	Query.SetParameter("StatementToDate", EndOfDay(StatementToDate));
	Query.SetParameter("BankAccount", BankAccount);
	
	Result = Query.Execute().Choose();
	
	While Result.Next() Do
		
		DataLine = Object.LineItems.Add();
		DataLine.Transaction = Result.Ref;
		DataLine.Date = Result.Date;
		DataLine.TransactionAmount = Result.DocumentTotal;
		DataLine.Company = Result.Company;
		
	EndDo;
	
	Object.LineItems.Sort("Date Asc, TransactionAmount Desc");
	
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
	If TabularPartRow.Cleared = True Then
		RecalcClearedBalance(TabularPartRow.TransactionAmount);
	Else
		RecalcClearedBalance(-1 * TabularPartRow.TransactionAmount);
	EndIf;
	
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
		CommonUse.GetAttributeValue(Object.BankAccount, "Description");

	// AdditionalReportsAndDataProcessors
	AdditionalReportsAndDataProcessors.OnCreateAtServer(ThisForm);
	// End AdditionalReportsAndDataProcessors
	
EndProcedure

&AtClient
Procedure BankAccountOnChange(Item)
	
	Items.BankAccountLabel.Title =
		CommonUse.GetAttributeValue(Object.BankAccount, "Description");
		
	DoMessageBox("Update the Statement To date to recalculate the reconciliation");

EndProcedure


