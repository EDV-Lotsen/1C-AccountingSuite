////////////////////////////////////////////////////////////////////////////////
// Bank reconciliation: Document form
//------------------------------------------------------------------------------
// Available on:
// - Client (managed application)
// - Server
//

#Region EVENTS_HANDLERS

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Object.Ref.IsEmpty() Then
		Object.BankAccount = Constants.BankAccount.Get();
		Object.Date = CurrentDate();
		Object.BankServiceChargeAccount 	= Constants.BankServiceChargeAccount.Get();
		Object.BankInterestEarnedAccount 	= Constants.BankInterestEarnedAccount.Get();
		//Auto-fill beginning balance and available documents
		Object.BeginningBalance = GetBeginningBalance(Object.BankAccount, Object.Date, Object.Ref);
		Object.InterestEarnedDate = Object.Date;
		Object.ServiceChargeDate = Object.Date;
		
		FillReconciliationSpec(Object.Date, Object.BankAccount);
		//Calculate totals
		Object.ClearedAmount = 0;
		Object.ClearedBalance = Object.BeginningBalance + Object.InterestEarned -
		Object.ServiceCharge + Object.ClearedAmount;	
		Object.Difference = Object.EndingBalance - Object.ClearedBalance;
	
		Items.LineItemsCleared.FooterText = Format(Object.ClearedAmount, "NFD=2; NZ=");	
	EndIf;
		
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	//Obtain bank transactions description
	Query = New Query("SELECT
	                  |	BankReconciliationLineItems.Transaction,
	                  |	BankReconciliationLineItems.TransactionAmount,
	                  |	BankReconciliationLineItems.Cleared
	                  |INTO TabularSection
	                  |FROM
	                  |	Document.BankReconciliation.LineItems AS BankReconciliationLineItems
	                  |WHERE
	                  |	BankReconciliationLineItems.Ref = &Ref
	                  |;
	                  |
	                  |////////////////////////////////////////////////////////////////////////////////
	                  |SELECT
	                  |	TransactionsForReconciliation.Ref,
	                  |	TransactionsForReconciliation.Date,
	                  |	TransactionsForReconciliation.Company,
	                  |	TransactionsForReconciliation.Number,
	                  |	SUM(TransactionsForReconciliation.Amount) AS Amount,
	                  |	MIN(TransactionsForReconciliation.Cleared) AS Cleared
	                  |INTO UnreconciledTransactions
	                  |FROM
	                  |	(SELECT
	                  |		BankReconciliationBalance.Document AS Ref,
	                  |		BankReconciliationBalance.Document.Date AS Date,
	                  |		BankReconciliationBalance.Document.Company AS Company,
	                  |		BankReconciliationBalance.Document.Number AS Number,
	                  |		BankReconciliationBalance.AmountBalance AS Amount,
	                  |		FALSE AS Cleared
	                  |	FROM
	                  |		AccumulationRegister.BankReconciliation.Balance(, Account = &BankAccount) AS BankReconciliationBalance
	                  |	WHERE
	                  |		BankReconciliationBalance.Document.Date <= &EndOfStatementDate
	                  |	
	                  |	UNION ALL
	                  |	
	                  |	SELECT
	                  |		BankReconciliation.Document,
	                  |		BankReconciliation.Document.Date,
	                  |		BankReconciliation.Document.Company,
	                  |		BankReconciliation.Document.Number,
	                  |		BankReconciliation.Amount,
	                  |		TRUE
	                  |	FROM
	                  |		AccumulationRegister.BankReconciliation AS BankReconciliation
	                  |	WHERE
	                  |		BankReconciliation.Recorder = &ThisDocument
	                  |		AND BankReconciliation.Active = TRUE) AS TransactionsForReconciliation
	                  |
	                  |GROUP BY
	                  |	TransactionsForReconciliation.Ref,
	                  |	TransactionsForReconciliation.Date,
	                  |	TransactionsForReconciliation.Company,
	                  |	TransactionsForReconciliation.Number
	                  |;
	                  |
	                  |////////////////////////////////////////////////////////////////////////////////
	                  |SELECT
	                  |	UnreconciledTransactions.Ref AS Transaction,
	                  |	UnreconciledTransactions.Date,
	                  |	UnreconciledTransactions.Company,
	                  |	UnreconciledTransactions.Number AS DocNumber,
	                  |	UnreconciledTransactions.Amount AS TransactionAmount,
	                  |	ISNULL(TabularSection.Cleared, UnreconciledTransactions.Cleared) AS Cleared,
	                  |	CASE
	                  |		WHEN UnreconciledTransactions.Amount > 0
	                  |			THEN UnreconciledTransactions.Amount
	                  |		ELSE 0
	                  |	END AS Deposit,
	                  |	CASE
	                  |		WHEN UnreconciledTransactions.Amount < 0
	                  |			THEN UnreconciledTransactions.Amount
	                  |		ELSE 0
	                  |	END AS Payment,
	                  |	ISNULL(BankTransactions.TransactionDate, DATETIME(1, 1, 1)) AS BankTransactionDate,
	                  |	ISNULL(BankTransactions.Description, """") AS BankTransactionDescription,
	                  |	ISNULL(BankTransactions.Amount, 0) AS BankTransactionAmount,
	                  |	ISNULL(BankTransactions.Category, VALUE(Catalog.BankTransactionCategories.EmptyRef)) AS BankTransactionCategory
	                  |FROM
	                  |	UnreconciledTransactions AS UnreconciledTransactions
	                  |		LEFT JOIN InformationRegister.BankTransactions AS BankTransactions
	                  |		ON UnreconciledTransactions.Ref = BankTransactions.Document
	                  |			AND (BankTransactions.BankAccount.AccountingAccount = &BankAccount)
	                  |		LEFT JOIN TabularSection AS TabularSection
	                  |		ON UnreconciledTransactions.Ref = TabularSection.Transaction
	                  |			AND (CASE
	                  |				WHEN UnreconciledTransactions.Amount < 0
	                  |					THEN CASE
	                  |							WHEN UnreconciledTransactions.Amount <= TabularSection.TransactionAmount
	                  |								THEN TRUE
	                  |							ELSE FALSE
	                  |						END
	                  |				ELSE CASE
	                  |						WHEN UnreconciledTransactions.Amount >= TabularSection.TransactionAmount
	                  |							THEN TRUE
	                  |						ELSE FALSE
	                  |					END
	                  |			END)
	                  |
	                  |ORDER BY
	                  |	UnreconciledTransactions.Date");
					  
	Query.SetParameter("Ref", Object.Ref);
	Query.SetParameter("BoundaryEndOfStatementDate", New Boundary(EndOfDay(Object.Date), BoundaryType.Including));
	Query.SetParameter("EndOfStatementDate", EndOfDay(Object.Date));
	Query.SetParameter("BankAccount", Object.BankAccount);
	Query.SetParameter("ThisDocument", Object.Ref);
	
	VTResult = Query.Execute().Unload();	
	LineItems.Load(VTResult);

	//Calculate cleared amount
	Object.ClearedAmount = 0;
	ClearedRows = LineItems.FindRows(New Structure("Cleared", True));
	For Each ClearedRow In ClearedRows Do
		Object.ClearedAmount = Object.ClearedAmount + ClearedRow.TransactionAmount;
	EndDo;
	Object.ClearedBalance = Object.BeginningBalance + Object.InterestEarned -
		Object.ServiceCharge + Object.ClearedAmount;	
	Object.Difference = Object.EndingBalance - Object.ClearedBalance;
	
	Items.LineItemsCleared.FooterText = Format(Object.ClearedAmount, "NFD=2; NZ=");
	
	Items.LineItemsDeposit.FooterText = Format(LineItems.Total("Deposit"), "NFD=2; NZ=");
	Items.LineItemsPayment.FooterText = Format(LineItems.Total("Payment"), "NFD=2; NZ=");

	LineItems.Sort("Date Asc, TransactionAmount Desc");
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	//Period closing
	If PeriodClosingServerCall.DocumentPeriodIsClosed(CurrentObject.Ref, CurrentObject.Date) Then
		PermitWrite = PeriodClosingServerCall.DocumentWritePermitted(WriteParameters);
		CurrentObject.AdditionalProperties.Insert("PermitWrite", PermitWrite);	
	EndIf;
	
	//Copy cleared line items to the object's tabular section
	ClearedItems = LineItems.FindRows(New Structure("Cleared", True));
	ClearedItemsVT = LineItems.Unload(ClearedItems,"Transaction, Cleared, TransactionAmount");
	CurrentObject.LineItems.Load(ClearedItemsVT);
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
     
EndProcedure

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
	
EndProcedure

#EndRegion

#Region CONTROLS_EVENTS_HANDLERS

&AtClient
// StatementToDateOnChange UI event handler.
// A reconciliation document repopulates its line items upon the ToDate field change,
// cleared amount is set to 0, cleared balance is recalculated, interest and service charge dates are
// defaulted to the ToDate.
//
Procedure StatementToDateOnChange(Item)
	
	Object.BeginningBalance = GetBeginningBalance(Object.BankAccount, Object.Date, Object.Ref);
	RefillReconcilliation();
		
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

&AtClient
Procedure BankAccountOnChange(Item)

	If Not ValueIsFilled(Object.Date) Then
		Object.Date = CurrentDate();
	EndIf;
	Object.BeginningBalance = GetBeginningBalance(Object.BankAccount, Object.Date, Object.Ref);
	RefillReconcilliation();

EndProcedure


#EndRegion

#Region TABULAR_SECTION_EVENTS_HANDLERS

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
Procedure LineItemsOnActivateRow(Item)
	If Item.CurrentData = Undefined Then
		return;
	EndIf;
	CurrentBankTransactionDescription 	= Item.CurrentData.BankTransactionDescription;
	CurrentBankTransactionDate			= Item.CurrentData.BankTransactionDate;
	CurrentBankTransactionAmount		= Item.CurrentData.BankTransactionAmount;
EndProcedure

&AtClient
Procedure LineItemsBeforeAddRow(Item, Cancel, Clone, Parent, Folder, Parameter)
	// A user can't add rows manually
	Cancel = True;
EndProcedure

&AtClient
Procedure LineItemsBeforeDeleteRow(Item, Cancel)
	// If a transaction is Cleared then Cancel deletion
	If Items.LineItems.CurrentData.Cleared Then
		Cancel = True;
		UM = New UserMessage();
		UM.SetData(Object);
		UM.Field = "Object.LineItems[" + String(Items.LineItems.CurrentData.LineNumber-1) + "]." + "Cleared";
		UM.Text  = "Can not delete the current row as it is cleared";
		UM.Message();
	EndIf;
EndProcedure

#EndRegion

#Region COMMANDS_HANDLERS

&AtClient
Procedure RefreshList(Command)
	
	RefillReconcilliation();
	
EndProcedure

&AtClient
Procedure ClearAll(Command)
	For Each LineItem In LineItems Do
		LineItem.Cleared = True;
	EndDo;
	Object.ClearedAmount = LineItems.Total("TransactionAmount");
	RecalcClearedBalance(0);
EndProcedure

&AtClient
Procedure UnclearAll(Command)
	For Each LineItem In LineItems Do
		LineItem.Cleared = False;
	EndDo;
	Object.ClearedAmount = 0;
	RecalcClearedBalance(0);
EndProcedure

#EndRegion

#Region PRIVATE_IMPLEMENTATION

&AtClient
Procedure RefillReconcilliation()
	
	FillReconciliationSpec(Object.Date, Object.BankAccount);
	Object.ClearedAmount = 0;
	
	DTotal = 0;
	For Each DocumentLine In LineItems Do	
		If DocumentLine.Cleared = True Then
			DTotal = DTotal + DocumentLine.TransactionAmount;
		EndIf;
	EndDo;
	
	Object.ClearedAmount = DTotal;
	
	RecalcClearedBalance(0);
	Object.InterestEarnedDate = Object.Date;
	Object.ServiceChargeDate = Object.Date;
	
EndProcedure

&AtServer
// The procedure fills in line items of a bank reconciliation document.
// Three types of documents are selected - deposits for cash receipts, invoice payments and cash purchases
// in the DateFrom DateTo interval.
//
Procedure FillReconciliationSpec(Date, BankAccount)
	
	//Filling from accumulation register
	
	Query = New Query("SELECT
	                  |	TabularSection.Transaction,
	                  |	TabularSection.TransactionAmount,
	                  |	TabularSection.Cleared
	                  |INTO TabularSection
	                  |FROM
	                  |	&TabularSection AS TabularSection
	                  |;
	                  |
	                  |////////////////////////////////////////////////////////////////////////////////
	                  |SELECT
	                  |	TransactionsForReconciliation.Ref,
	                  |	TransactionsForReconciliation.Date,
	                  |	TransactionsForReconciliation.Company,
	                  |	TransactionsForReconciliation.Number,
	                  |	SUM(TransactionsForReconciliation.Amount) AS Amount,
	                  |	MIN(TransactionsForReconciliation.Cleared) AS Cleared
	                  |INTO UnreconciledTransactions
	                  |FROM
	                  |	(SELECT
	                  |		BankReconciliationBalance.Document AS Ref,
	                  |		BankReconciliationBalance.Document.Date AS Date,
	                  |		BankReconciliationBalance.Document.Company AS Company,
	                  |		BankReconciliationBalance.Document.Number AS Number,
	                  |		BankReconciliationBalance.AmountBalance AS Amount,
	                  |		FALSE AS Cleared
	                  |	FROM
	                  |		AccumulationRegister.BankReconciliation.Balance(, Account = &BankAccount) AS BankReconciliationBalance
	                  |	WHERE
	                  |		BankReconciliationBalance.Document.Date <= &EndOfStatementDate
	                  |	
	                  |	UNION ALL
	                  |	
	                  |	SELECT
	                  |		BankReconciliation.Document,
	                  |		BankReconciliation.Document.Date,
	                  |		BankReconciliation.Document.Company,
	                  |		BankReconciliation.Document.Number,
	                  |		BankReconciliation.Amount,
	                  |		TRUE
	                  |	FROM
	                  |		AccumulationRegister.BankReconciliation AS BankReconciliation
	                  |	WHERE
	                  |		BankReconciliation.Recorder = &ThisDocument
	                  |		AND BankReconciliation.Active = TRUE
	                  |		AND BankReconciliation.Document.Date <= &EndOfStatementDate
	                  |		AND BankReconciliation.Account = &BankAccount) AS TransactionsForReconciliation
	                  |
	                  |GROUP BY
	                  |	TransactionsForReconciliation.Ref,
	                  |	TransactionsForReconciliation.Date,
	                  |	TransactionsForReconciliation.Company,
	                  |	TransactionsForReconciliation.Number
	                  |;
	                  |
	                  |////////////////////////////////////////////////////////////////////////////////
	                  |SELECT
	                  |	UnreconciledTransactions.Ref AS Transaction,
	                  |	UnreconciledTransactions.Date,
	                  |	UnreconciledTransactions.Company,
	                  |	UnreconciledTransactions.Number AS DocNumber,
	                  |	UnreconciledTransactions.Amount AS TransactionAmount,
	                  |	ISNULL(TabularSection.Cleared, UnreconciledTransactions.Cleared) AS Cleared,
	                  |	CASE
	                  |		WHEN UnreconciledTransactions.Amount > 0
	                  |			THEN UnreconciledTransactions.Amount
	                  |		ELSE 0
	                  |	END AS Deposit,
	                  |	CASE
	                  |		WHEN UnreconciledTransactions.Amount < 0
	                  |			THEN UnreconciledTransactions.Amount
	                  |		ELSE 0
	                  |	END AS Payment,
	                  |	ISNULL(BankTransactions.TransactionDate, DATETIME(1, 1, 1)) AS BankTransactionDate,
	                  |	ISNULL(BankTransactions.Description, """") AS BankTransactionDescription,
	                  |	ISNULL(BankTransactions.Amount, 0) AS BankTransactionAmount,
	                  |	ISNULL(BankTransactions.Category, VALUE(Catalog.BankTransactionCategories.EmptyRef)) AS BankTransactionCategory
	                  |FROM
	                  |	UnreconciledTransactions AS UnreconciledTransactions
	                  |		LEFT JOIN InformationRegister.BankTransactions AS BankTransactions
	                  |		ON UnreconciledTransactions.Ref = BankTransactions.Document
	                  |			AND (BankTransactions.BankAccount.AccountingAccount = &BankAccount)
	                  |		LEFT JOIN TabularSection AS TabularSection
	                  |		ON UnreconciledTransactions.Ref = TabularSection.Transaction
	                  |			AND (CASE
	                  |				WHEN UnreconciledTransactions.Amount < 0
	                  |					THEN CASE
	                  |							WHEN UnreconciledTransactions.Amount <= TabularSection.TransactionAmount
	                  |								THEN TRUE
	                  |							ELSE FALSE
	                  |						END
	                  |				ELSE CASE
	                  |						WHEN UnreconciledTransactions.Amount >= TabularSection.TransactionAmount
	                  |							THEN TRUE
	                  |						ELSE FALSE
	                  |					END
	                  |			END)
	                  |
	                  |ORDER BY
	                  |	UnreconciledTransactions.Date");
					  
	Query.SetParameter("TabularSection", LineItems.Unload(, "Transaction, TransactionAmount, Cleared"));
	Query.SetParameter("BoundaryEndOfStatementDate", New Boundary(EndOfDay(Date), BoundaryType.Including));
	Query.SetParameter("EndOfStatementDate", EndOfDay(Date));
	Query.SetParameter("BankAccount", BankAccount);
	Query.SetParameter("ThisDocument", Object.Ref);
	
	VTResult = Query.Execute().Unload();	
	LineItems.Load(VTResult);
	ThisForm.Modified = True;
	
	//Calculate cleared amount
	Object.ClearedAmount = 0;
	ClearedRows = LineItems.FindRows(New Structure("Cleared", True));
	For Each ClearedRow In ClearedRows Do
		Object.ClearedAmount = Object.ClearedAmount + ClearedRow.TransactionAmount;
	EndDo;
	Object.ClearedBalance = Object.BeginningBalance + Object.InterestEarned -
		Object.ServiceCharge + Object.ClearedAmount;	
	Object.Difference = Object.EndingBalance - Object.ClearedBalance;
	
	Items.LineItemsCleared.FooterText = Format(Object.ClearedAmount, "NFD=2; NZ=");
	
	Items.LineItemsDeposit.FooterText = Format(LineItems.Total("Deposit"), "NFD=2; NZ=");
	Items.LineItemsPayment.FooterText = Format(LineItems.Total("Payment"), "NFD=2; NZ=");

	LineItems.Sort("Date Asc, TransactionAmount Desc");
	
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

&AtServerNoContext
Function GetBeginningBalance(Val BankAccount, Val StatementDate, Val Ref)
	//Fill in Beginning balance
	Request = New Query("SELECT TOP 1
	                    |	BankReconciliation.Date AS Date,
	                    |	BankReconciliation.EndingBalance
	                    |FROM
	                    |	Document.BankReconciliation AS BankReconciliation
	                    |WHERE
	                    |	BankReconciliation.DeletionMark = FALSE
	                    |	AND BankReconciliation.Posted = TRUE
	                    |	AND BankReconciliation.BankAccount = &CurrentBankAccount
	                    |	AND BankReconciliation.Date <= &StatementDate
	                    |	AND BankReconciliation.Ref <> &Ref
	                    |
	                    |ORDER BY
	                    |	BankReconciliation.PointInTime DESC");
	Request.SetParameter("CurrentBankAccount", BankAccount);
	Request.SetParameter("StatementDate", StatementDate);
	Request.SetParameter("Ref", Ref);
	Res = Request.Execute().Unload();
	If Res.Count() > 0 Then 
		return Res[0].EndingBalance;
	Else
		return 0;
	EndIf;
EndFunction

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

#EndRegion