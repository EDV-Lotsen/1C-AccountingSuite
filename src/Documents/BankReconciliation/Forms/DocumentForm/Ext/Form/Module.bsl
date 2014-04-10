


&AtClient
// StatementToDateOnChange UI event handler.
// A reconciliation document repopulates its line items upon the ToDate field change,
// cleared amount is set to 0, cleared balance is recalculated, interest and service charge dates are
// defaulted to the ToDate.
//
Procedure StatementToDateOnChange(Item)
	
	RefillReconcilliation();
		
EndProcedure

&AtClient
Procedure RefillReconcilliation()
	
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
		
		If (DocumentLine.Cleared = True) And (DocumentLine.Date <= EndOfDay(StatementToDate)) Then
			
			OldLineItems = New Structure;
			OldLineItems.Insert("Transaction", DocumentLine.Transaction);
			OldLineItems.Insert("Date", DocumentLine.Date);
			OldLineItems.Insert("TransactionAmount", DocumentLine.TransactionAmount);
			OldLineItems.Insert("Company", DocumentLine.Company);
			OldLineItems.Insert("DocNumber", DocumentLine.DocNumber);
			OldLineItems.Insert("BankTransactionDescription", DocumentLine.BankTransactionDescription);
			OldLineItems.Insert("BankTransactionDate", DocumentLine.BankTransactionDate);
			OldLineItems.Insert("BankTransactionAmount", DocumentLine.BankTransactionAmount);
			OldLineItems.Insert("BankTransactionCategory", DocumentLine.BankTransactionCategory);
			OldLineItems.Insert("Cleared", True);
			OldLI.Add(OldLineItems);
			
		EndIf;
		
	EndDo;
	
	Object.LineItems.Clear();
	
	NumOfRows = OldLI.Count();
	
	For i = 1 To NumOfRows Do
		
		DataLine = Object.LineItems.Add();
		FillPropertyValues(DataLine, OldLI[i-1]);
		If DataLine.TransactionAmount > 0 Then
			DataLine.Deposit = DataLine.TransactionAmount;
		Else
			DataLine.Payment = DataLine.TransactionAmount;
		EndIf;
		//DataLine.Transaction = OldLI[i-1].Transaction;
		//DataLine.Date = OldLI[i-1].Date;
		//DataLine.Cleared = True;
		//DataLine.TransactionAmount = OldLI[i-1].TransactionAmount;
		//DataLine.DocNumber = OldLI[i-1].DocNumber;
		//DataLine.Company = OldLI[i-1].Company;
		
	EndDo;
	
	Query = New Query("SELECT
	                  |	TransactionReconciliation.Document AS Ref,
	                  |	TransactionReconciliation.Document.Date AS Date,
	                  |	TransactionReconciliation.Document.Company AS Company,
	                  |	TransactionReconciliation.Document.Number AS Number,
	                  |	TransactionReconciliation.Amount AS DocumentTotal
	                  |INTO UnreconciledTransactions
	                  |FROM
	                  |	InformationRegister.TransactionReconciliation AS TransactionReconciliation
	                  |WHERE
	                  |	TransactionReconciliation.Document.Date <= &StatementToDate
	                  |	AND TransactionReconciliation.Account = &BankAccount
	                  |	AND TransactionReconciliation.Reconciled = FALSE
	                  |;
	                  |
	                  |////////////////////////////////////////////////////////////////////////////////
	                  |SELECT
	                  |	UnreconciledTransactions.Ref AS Transaction,
	                  |	UnreconciledTransactions.Date,
	                  |	UnreconciledTransactions.Company,
	                  |	UnreconciledTransactions.Number AS DocNumber,
	                  |	UnreconciledTransactions.DocumentTotal AS TransactionAmount,
	                  |	ISNULL(BankTransactions.TransactionDate, DATETIME(1, 1, 1)) AS BankTransactionDate,
	                  |	ISNULL(BankTransactions.Description, """") AS BankTransactionDescription,
	                  |	ISNULL(BankTransactions.Amount, 0) AS BankTransactionAmount,
	                  |	ISNULL(BankTransactions.Category, VALUE(Catalog.BankTransactionCategories.EmptyRef)) AS BankTransactionCategory
	                  |FROM
	                  |	UnreconciledTransactions AS UnreconciledTransactions
	                  |		LEFT JOIN InformationRegister.BankTransactions AS BankTransactions
	                  |		ON UnreconciledTransactions.Ref = BankTransactions.Document
	                  |			AND (BankTransactions.BankAccount.AccountingAccount = &BankAccount)
	                  |
	                  |ORDER BY
	                  |	UnreconciledTransactions.Date");
						  
	Query.SetParameter("StatementToDate", EndOfDay(StatementToDate));
	Query.SetParameter("BankAccount", BankAccount);
	
	Result = Query.Execute().Select();
	
	While Result.Next() Do
		
		// replace with a more efficient search in array algorithm
		OldTransaction = False;
		For i = 1 To NumOfRows Do	
			If OldLI[i-1].Transaction = Result.Transaction Then
				OldTransaction = True;
			EndIf;			
		EndDo;

		If NOT OldTransaction Then
		
			DataLine = Object.LineItems.Add();
			FillPropertyValues(DataLine, Result);
			//DataLine.Transaction = Result.Ref;
			//DataLine.Date = Result.Date;
			//DataLine.DocNumber = Result.Number;
			//DataLine.TransactionAmount = Result.DocumentTotal;
			//DataLine.Company = Result.Company;
			If DataLine.TransactionAmount > 0 Then
				DataLine.Deposit = DataLine.TransactionAmount;
			Else
				DataLine.Payment = DataLine.TransactionAmount;
			EndIf;
			
		EndIf;
		
	EndDo;
	
	//Calculate cleared amount
	Object.ClearedAmount = 0;
	ClearedRows = Object.LineItems.FindRows(New Structure("Cleared", True));
	For Each ClearedRow In ClearedRows Do
		Object.ClearedAmount = Object.ClearedAmount + ClearedRow.TransactionAmount;
	EndDo;
	Object.ClearedBalance = Object.BeginningBalance + Object.InterestEarned -
		Object.ServiceCharge + Object.ClearedAmount;	
	Object.Difference = Object.EndingBalance - Object.ClearedBalance;
	
	Items.LineItemsCleared.FooterText = Format(Object.ClearedAmount, "NFD=2; NZ=");
	
	Items.LineItemsDeposit.FooterText = Format(Object.LineItems.Total("Deposit"), "NFD=2; NZ=");
	Items.LineItemsPayment.FooterText = Format(Object.LineItems.Total("Payment"), "NFD=2; NZ=");

	Object.LineItems.Sort("Date Asc, TransactionAmount Desc");
	
EndProcedure

&AtClient
// All related dynamic lists are notified of changes in the data
//
Procedure AfterWrite(WriteParameters)
	
		//Works very slowly
		//For Each DocumentLine in Object.LineItems Do
		//
		//	RepresentDataChange(DocumentLine.Transaction, DataChangeType.Update);
		//
		//EndDo;
		
		//Refill LineItems with Transaction description
		
		i = 0;
		While i < BankTransactionsCache.Count() Do
			If Object.LineItems[i].Transaction = BankTransactionsCache[i].Transaction Then
				FillPropertyValues(Object.LineItems[i], BankTransactionsCache[i]);
			EndIf;
			i = i + 1;
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
	
	Items.LineItemsCleared.FooterText = Format(Object.ClearedAmount, "NFD=2; NZ=");	
	
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
	
	If Object.Ref.IsEmpty() Then
		Object.BankServiceChargeAccount 	= Constants.BankServiceChargeAccount.Get();
		Object.BankInterestEarnedAccount 	= Constants.BankInterestEarnedAccount.Get();
	EndIf;
	
	//Items.BankAccountLabel.Title =
	//	CommonUse.GetAttributeValue(Object.BankAccount, "Description");
	
EndProcedure

&AtClient
Procedure BankAccountOnChange(Item)
	
	//Items.BankAccountLabel.Title =
	//	CommonUse.GetAttributeValue(Object.BankAccount, "Description");
	If ValueIsFilled(Object.BankAccount) Then
		Object.BeginningBalance = GetBeginningBalance(Object.BankAccount);
	EndIf;
	Message("Update the Statement To date to recalculate the reconciliation");

EndProcedure

&AtServerNoContext
Function GetBeginningBalance(Val BankAccount)
	//Fill in Beginning balance
	Request = New Query("SELECT TOP 1
	                    |	BankReconciliation.StatementToDate AS StatementToDate,
	                    |	BankReconciliation.EndingBalance
	                    |FROM
	                    |	Document.BankReconciliation AS BankReconciliation
	                    |WHERE
	                    |	BankReconciliation.DeletionMark = FALSE
	                    |	AND BankReconciliation.Posted = TRUE
	                    |	AND BankReconciliation.BankAccount = &CurrentBankAccount
	                    |
	                    |ORDER BY
	                    |	StatementToDate DESC");
	Request.SetParameter("CurrentBankAccount", BankAccount);
	Res = Request.Execute().Unload();
	If Res.Count() > 0 Then 
		return Res[0].EndingBalance;
	Else
		return 0;
	EndIf;
EndFunction

&AtClient
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
	
	//Cache transaction data
	BankTransactionsCache.Clear();
	For Each Line In Object.LineItems Do
		NewLine = BankTransactionsCache.Add();
		FillPropertyValues(NewLine, Line);
	EndDo;
EndProcedure

//Closing period
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

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	//Period closing
	If PeriodClosingServerCall.DocumentPeriodIsClosed(CurrentObject.Ref, CurrentObject.Date) Then
		PermitWrite = PeriodClosingServerCall.DocumentWritePermitted(WriteParameters);
		CurrentObject.AdditionalProperties.Insert("PermitWrite", PermitWrite);	
	EndIf;
EndProcedure

&AtClient
Procedure ClearAll(Command)
	For Each LineItem In Object.LineItems Do
		LineItem.Cleared = True;
	EndDo;
	Object.ClearedAmount = Object.LineItems.Total("TransactionAmount");
	RecalcClearedBalance(0);
EndProcedure

&AtClient
Procedure UnclearAll(Command)
	For Each LineItem In Object.LineItems Do
		LineItem.Cleared = False;
	EndDo;
	Object.ClearedAmount = 0;
	RecalcClearedBalance(0);
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	//Obtain bank transactions description
	Request = New Query("SELECT
	                    |	BankReconciliationLineItems.Transaction
	                    |INTO Documents
	                    |FROM
	                    |	Document.BankReconciliation.LineItems AS BankReconciliationLineItems
	                    |WHERE
	                    |	BankReconciliationLineItems.Ref = &Ref
	                    |;
	                    |
	                    |////////////////////////////////////////////////////////////////////////////////
	                    |SELECT
	                    |	Documents.Transaction,
	                    |	BankTransactions.TransactionDate,
	                    |	BankTransactions.Description,
	                    |	BankTransactions.Category,
	                    |	BankTransactions.Amount
	                    |FROM
	                    |	Documents AS Documents
	                    |		INNER JOIN InformationRegister.BankTransactions AS BankTransactions
	                    |		ON Documents.Transaction = BankTransactions.Document
	                    |			AND (BankTransactions.BankAccount.AccountingAccount = &BankAccount)");
	Request.SetParameter("Ref", CurrentObject.Ref);
	Request.SetParameter("BankAccount", CurrentObject.BankAccount);
	BankTransactions = Request.Execute().Unload();
	//Fill Deposits and Payments columns
	DepositsTotal = 0;
	PaymentsTotal = 0;
	//Calculate cleared amount
	ClearedAmount = 0;
	For Each LineItem In Object.LineItems Do
		If LineItem.TransactionAmount > 0 Then
			LineItem.Deposit = LineItem.TransactionAmount;
			DepositsTotal = DepositsTotal + LineItem.Deposit;
		Else
			LineItem.Payment = LineItem.TransactionAmount;
			PaymentsTotal = PaymentsTotal + LineItem.Payment; 
		EndIf;
		FoundRows = BankTransactions.FindRows(New Structure("Transaction", LineItem.Transaction));
		If FoundRows.Count() > 0 Then
			LineItem.BankTransactionDescription = FoundRows[0].Description;
			LineItem.BankTransactionDate = FoundRows[0].TransactionDate;
			LineItem.BankTransactionAmount = FoundRows[0].Amount;
			LineItem.BankTransactionCategory = FoundRows[0].Category; 
		EndIf;
		If LineItem.Cleared Then
			ClearedAmount = ClearedAmount + LineItem.TransactionAmount;
		EndIf;
	EndDo;
	If ClearedAmount <> Object.ClearedAmount Then
		Object.ClearedAmount = ClearedAmount;
		Object.ClearedBalance = Object.BeginningBalance + Object.InterestEarned -
			Object.ServiceCharge + Object.ClearedAmount;	
		Object.Difference = Object.EndingBalance - Object.ClearedBalance;
	EndIf;
	
	Items.LineItemsCleared.FooterText = Format(Object.ClearedAmount, "NFD=2; NZ=");
	Items.LineItemsDeposit.FooterText = Format(DepositsTotal, "NFD=2; NZ=");
	Items.LineItemsPayment.FooterText = Format(PaymentsTotal, "NFD=2; NZ=");
EndProcedure

&AtClient
Procedure LineItemsOnActivateRow(Item)
	If Item.CurrentData = Undefined Then
		return;
	EndIf;
	CurrentBankTransactionDescription 	= Item.CurrentData.BankTransactionDescription;
	CurrentBankTransactionDate			= Item.CurrentData.BankTransactionDate;
	CurrentBankTransactionAmount		= Item.CurrentData.BankTransactionAmount;
EndProcedure

&AtClient
Procedure RefreshList(Command)
	
	RefillReconcilliation();
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	If Not ValueIsFilled(Object.BankInterestEarnedAccount) And (ValueIsFilled(Object.InterestEarned)) Then
		Cancel = True;
		Message = New UserMessage();
		Message.SetData(Object);
		Message.Field = "Object.BankInterestEarnedAccount";
		Message.Text = NStr("en = 'Bank interest earned account is not filled'");
		Message.Message();
	EndIf;
	
	If (Not ValueIsFilled(Object.BankServiceChargeAccount)) And (ValueIsFilled(Object.ServiceCharge)) Then
		Cancel = True;
		Message = New UserMessage();
		Message.SetData(Object);
		Message.Field = "Object.BankServiceChargeAccount";
		Message.Text = NStr("en = 'Bank service charge account is not filled'");
		Message.Message();
	EndIf;

	Request = New Query("SELECT
	                    |	BankDocuments.Transaction AS Document,
	                    |	BankDocuments.TransactionAmount AS Amount
	                    |INTO ReconcilliationDocuments
	                    |FROM
	                    |	&BankDocuments AS BankDocuments
	                    |;
	                    |
	                    |////////////////////////////////////////////////////////////////////////////////
	                    |SELECT ALLOWED
	                    |	IncorrectRows.Document,
	                    |	IncorrectRows.Amount,
	                    |	IncorrectRows.UnreconciledAmount
	                    |FROM
	                    |	(SELECT
	                    |		ReconcilliationDocuments.Document AS Document,
	                    |		ReconcilliationDocuments.Amount AS Amount,
	                    |		ReconcilliationDocuments.Amount - ISNULL(TransactionReconciliation.Amount, 0) AS UnreconciledAmount
	                    |	FROM
	                    |		ReconcilliationDocuments AS ReconcilliationDocuments
	                    |			LEFT JOIN InformationRegister.TransactionReconciliation AS TransactionReconciliation
	                    |			ON ReconcilliationDocuments.Document = TransactionReconciliation.Document
	                    |				AND (TransactionReconciliation.Account = &Account)) AS IncorrectRows
	                    |WHERE
	                    |	(IncorrectRows.Amount = 0
	                    |			OR IncorrectRows.UnreconciledAmount <> 0)");
	BankDocuments = Object.LineItems.Unload(,"Transaction, TransactionAmount");
	Request.SetParameter("BankDocuments", BankDocuments);
	Request.SetParameter("Account", Object.BankAccount);
	Result = Request.Execute();
	If Result.IsEmpty() Then 
		return;
	EndIf;
	Sel = Result.Select();
	While Sel.Next() Do
		FoundRow = Object.LineItems.FindRows(New Structure("Transaction", Sel.Document));
		RowNumber = FoundRow[0].LineNumber;
		Message = New UserMessage();
		Message.SetData(Object);
		Message.Text=NStr("en = 'Current amount differs from the amount, available for reconcilliation. Please, use the Refresh button to fix it!'");
		If (FoundRow[0].TransactionAmount < 0) Then
			Message.Field = "Object.LineItems[" + String(RowNumber-1) + "].Payment";
		Else
			Message.Field = "Object.LineItems[" + String(RowNumber-1) + "].Deposit";
		EndIf;
		Message.Message();
		Cancel = True; 
	EndDo;	     
EndProcedure



