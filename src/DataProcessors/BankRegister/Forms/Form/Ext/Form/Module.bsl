&AtClient
Var EditingNewRow, Sorting, SkippingTableFieldsForChecks;

#Region EVENTS_HANDLERS

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	ApplyConditionalAppearance();
	SetBalancesVisibility(ThisForm, Object.HideBalances);
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	If ValueIsFilled(Object.DateStart) And ValueIsFilled(Object.DateEnd) And ValueIsFilled(Object.BankAccount) Then
		FillBankTransactions();
		SetBalancesVisibility(ThisForm, Object.HideBalances);
	EndIf;
	
	If Object.EditBegBal Then 
		Items.BalanceStart.Visible = False;
		Items.BalanceStartEdit.Visible = True;
	Else
		Items.BalanceStart.Visible = True;
		Items.BalanceStartEdit.Visible = False;
	EndIf;

	EndOfDateEnd = EndOfDay(Object.DateEnd);
	PeriodPresentation = PeriodPresentation(Object.DateStart, EndOfDateEnd);
	ApplyEditingMode();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	EditingNewRow 	= False; 
	Sorting 		= False;
	
	AttachIdleHandler("AfterOpen", 0.1, True);
	
EndProcedure

&AtClient
Procedure AfterOpen()

	If Not (ValueIsFilled(Object.DateStart) And ValueIsFilled(Object.DateEnd) And ValueIsFilled(Object.BankAccount)) Then
		If Not (ValueIsFilled(Object.DateStart) And ValueIsFilled(Object.DateEnd)) Then
			Object.DateStart 	= BegOfMonth(CurrentDate());
			Object.DateEnd 		= EndOfMonth(CurrentDate());
		EndIf;

		Settings(Undefined);
	EndIf;
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(SelectedValue, ChoiceSource)
	
	If TypeOf(SelectedValue) = Type("Structure") Then
		If (SelectedValue.BeginOfPeriod <> Object.DateStart) Or (SelectedValue.EndOfPeriod <> Object.DateEnd) Then
			Object.DepositsTotal = 0;
			Object.PaymentsTotal = 0;
		EndIf;
		Object.DateStart 	= SelectedValue.BeginOfPeriod;
		Object.DateEnd		= SelectedValue.EndOfPeriod;
	EndIf;
	EndOfDateEnd = EndOfDay(Object.DateEnd);
	PeriodPresentation = PeriodPresentation(Object.DateStart, EndOfDateEnd);
	FillBankTransactions();
	
EndProcedure

#ENDREGION

#REGION FORM_COMMAND_HANDLERS

&AtClient
Procedure CreateTransactions(Command)
	
	CreateTransactionsAtServer();
	
EndProcedure

&AtClient
Procedure Refresh(Command)
	
	FillBankTransactions();
	
EndProcedure

&AtClient
Procedure UploadTransactions(Command)
	
	ImageAddress = "";
	
	Notify = New NotifyDescription("FileUpload", ThisForm);

	BeginPutFile(Notify, "", "*.qif; *.qbo; *.qfx; *.ofx; *.csv; *.iif", True, ThisForm.UUID);
	
EndProcedure

&AtClient
Procedure Settings(Command)
	
	Notify = New NotifyDescription("ProcessSettingsChange", ThisObject);
	FormParameters = New Structure("HideBalances, DoNotUseJournalEntry, DoNotUseAdjustingJournalEntry, EditBegBal, DateStart, DateEnd, AccountInBank, BankAccount, UseBankReconciliationForBegBal, EditNumbersWithoutDecimalPoint");
	FillPropertyValues(FormParameters, Object);
	OpenForm("DataProcessor.BankRegister.Form.Settings", FormParameters, ThisForm,,,, Notify, FormWindowOpeningMode.LockOwnerWindow);
				
EndProcedure

&AtClient
Procedure ProcessSettingsChange(Result, Parameters) Export
	
	If TypeOf(Result) = Type("Structure") Then
		FillPropertyValues(Object, Result, "HideBalances, DoNotUseJournalEntry, DoNotUseAdjustingJournalEntry, EditBegBal, DateStart, DateEnd, AccountInBank, BankAccount, UseBankReconciliationForBegBal, EditNumbersWithoutDecimalPoint");
		If Result.PeriodChanged Then
			Object.DepositsTotal = 0;
			Object.PaymentsTotal = 0;
		EndIf;
	Else
		return;
	EndIf;
	
	ProcessSettingsChangeAtServer();
		
EndProcedure

#ENDREGION

#REGION FORM_ITEMS_HANDLERS

&AtClient
Procedure BankAccountOnChange(Item)
	
	BankAccountOnChangeAtServer();
	
EndProcedure

&AtClient
Procedure BankTransactionsDepositOnChange(Item)
	
	ApplyNumberEditMode(Object, Items.BankTransactions.CurrentData.Deposit);
	CurrentData = Items.BankTransactions.CurrentData;
	If CurrentData.Deposit <> 0 Then
		CurrentData.Payment = 0;
		CurrentData.OperationType = "Deposit";
	EndIf;
		
EndProcedure

&AtClient
Procedure BankTransactionsPaymentOnChange(Item)
	
	ApplyNumberEditMode(Object, Items.BankTransactions.CurrentData.Payment);
	CurrentData = Items.BankTransactions.CurrentData;
	If CurrentData.Payment <> 0 Then
		CurrentData.Deposit = 0;
		CurrentData.OperationType = "Payment";
	EndIf;
	
EndProcedure

&AtClient
Procedure BankTransactionsOperationTypeOnChange(Item)
	
	
	CurrentData = Items.BankTransactions.CurrentData;
	If CurrentData.OperationType = "Deposit" Then
		CurrentData.Payment = 0;
	ElsIf CurrentData.OperationType = "Payment" Then
		CurrentData.Deposit = 0;
	EndIf;
	
EndProcedure

&AtClient
Procedure BankTransactionsSelection(Item, SelectedRow, Field, StandardProcessing)
	
	If Field = Items.BankTransactionsDocument Then
		If ValueIsFilled(Items.BankTransactions.CurrentData.Document) Then
			ShowValue(,Items.BankTransactions.CurrentData.Document);
		EndIf;
	EndIf;

EndProcedure

&AtClient
Procedure BankTransactionsOnEditEnd(Item, NewRow, CancelEdit)
	
	//PerformanceMeasurementClientServer.StartTimeMeasurement("Quick Entry Create Transaction");
	
	If (Not CancelEdit) And EditingNewRow Then
		CreateTransactionsAtServer(Items.BankTransactions.CurrentRow);
	EndIf;
	
EndProcedure

&AtClient
Procedure BankTransactionsOnStartEdit(Item, NewRow, Clone)
	
	EditingNewRow = NewRow;
	If Clone Then
		NewRow						= Items.BankTransactions.CurrentData;
		NewRow.Document 			= Undefined;
		NewRow.OperationType 		= "";
		NewRow.RefNumber 			= "";
		NewRow.HasDocument 			= Undefined;
		NewRow.AmountClosingBalance = 0;
		NewRow.Cleared 				= "";
		NewRow.Reconciled 			= "";
		NewRow.TransactionID        = New UUID("00000000-0000-0000-0000-000000000000");
	EndIf;
	
EndProcedure

&AtClient
Procedure BankTransactionsBeforeDeleteRow(Item, Cancel)
	
	Cancel = True;
	CurrentDocument = Item.CurrentData.Document;
	CurrentRow		= Item.CurrentRow;
	TransactionID	= Item.CurrentData.TransactionID;
	QueryParameters = New Structure("CurrentDocument, CurrentRow, TransactionID", CurrentDocument, CurrentRow, TransactionID);
	Notify = New NotifyDescription("ProcessQueryAnswer", ThisObject, QueryParameters);
	If ValueIsFilled(CurrentDocument) Then
		ShowQueryBox(Notify, "Are you sure you want to delete this document (" + String(CurrentDocument) + ")?", QuestionDialogMode.YesNoCancel,, DialogReturnCode.Cancel, "Quick register");
	Else
		ShowQueryBox(Notify, "Are you sure you want to delete the current row?", QuestionDialogMode.YesNoCancel,, DialogReturnCode.Cancel, "Quick Entry");
	EndIf;
	
EndProcedure

&AtClient
Procedure ProcessQueryAnswer(Result, Parameters) Export
	
	If Result <> DialogReturnCode.Yes Then
		return;
	EndIf;
	CurrentRow = Object.BankTransactions.FindByID(Parameters.CurrentRow);
	If CurrentRow = Undefined Then
		return;
	EndIf;
	If CurrentRow.Document <> Parameters.CurrentDocument Then
		return;
	EndIf;
	If Not ((TypeOf(Parameters.CurrentDocument) = Type("DocumentRef.Deposit")) Or (TypeOf(Parameters.CurrentDocument) = Type("DocumentRef.Check")) Or (Parameters.CurrentDocument = Undefined)) Then
		CommonUseClientServer.MessageToUser("In Quick Entry only Deposits and Payments can be deleted. To delete a document of a different type please use Cloud Banking or document's list form");
		return;
	EndIf;
		
	DeleteTransactionAtServer(Parameters);
		
EndProcedure

&AtServer
Procedure DeleteTransactionAtServer(Parameters)
	
	Try
	BeginTransaction(DataLockControlMode.Managed);
	If ValueIsFilled(Parameters.TransactionID) Then
		BTRecordset = InformationRegisters.BankTransactions.CreateRecordSet();
		BTRecordset.Filter.ID.Set(Parameters.TransactionID);
		BTRecordset.Write(True);
	ElsIf ValueIsFilled(Parameters.CurrentDocument) Then
		Request = New Query("SELECT
		                    |	BankTransactions.ID
		                    |FROM
		                    |	InformationRegister.BankTransactions AS BankTransactions
		                    |WHERE
		                    |	BankTransactions.Document = &Document");	
		Request.SetParameter("Document", Parameters.CurrentDocument);
		IDs = Request.Execute().Unload();
	
		For Each IDRow In IDs Do
			BTRecordset = InformationRegisters.BankTransactions.CreateRecordSet();
			BTRecordset.Filter.ID.Set(IDRow.ID);
			BTRecordset.Write(True);
		EndDo;	
	EndIf;
	
	// Delete the document
	If ValueIsFilled(Parameters.CurrentDocument) Then
		DocumentObject = Parameters.CurrentDocument.GetObject();
		DocumentObject.Delete();
	EndIf;

	CommitTransaction();
	Object.BankTransactions.Delete(Object.BankTransactions.FindByID(Parameters.CurrentRow));
	Except
		ErrorDescription = ErrorDescription();
		If TransactionActive() Then
			RollbackTransaction();
		EndIf;
		CommonUseClientServer.MessageToUser(ErrorDescription);
	EndTry;
	
EndProcedure

&AtClient
Procedure BankTransactionsOnChange(Item)
	
	If (Not EditingNewRow) AND (Not Sorting) Then
		CreateTransactionsAtServer(Items.BankTransactions.CurrentRow);
	EndIf;
	
EndProcedure

&AtClient
Procedure BankTransactionsBeforeAddRow(Item, Cancel, Clone, Parent, Folder, Parameter)
	
	//Allow only one line to be in the entry mode at a time
	Transactions = Object.BankTransactions.FindRows(New Structure("HasDocument", False));
	If Transactions.Count() > 0 Then
		Cancel = True;
		CommonUseClientServer.MessageToUser("Please, finish editing the current row before adding the new one", Object, "Object.BankTransactions[" + Format(Transactions[0].LineNumber-1, "NFD=; NG=0")+ "].Period");
	Else
		EditingNewRow = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure BankTransactionsCompanyOnChange(Item)
	
	CustomerAttributes = CommonUse.GetAttributeValues(Items.BankTransactions.CurrentData.Company, "Code, Vendor, Customer, ExpenseAccount, IncomeAccount");
	Items.BankTransactions.CurrentData.CompanyCode 	= CustomerAttributes.Code;
	If Not ValueIsFilled(Items.BankTransactions.CurrentData.Category) Then
		If CustomerAttributes.Vendor = True Then
			Items.BankTransactions.CurrentData.Category = CustomerAttributes.ExpenseAccount;
		ElsIf CustomerAttributes.Customer = True Then
			Items.BankTransactions.CurrentData.Category = CustomerAttributes.IncomeAccount;		
		EndIf;
	EndIf;
	
	//Implement editing mode for entering checks: after filling a customer, move to payment amount cell
	If EditingNewRow Then
		If (Object.EditingMode = 1) Or ((CustomerAttributes.Vendor = True) And (CustomerAttributes.Customer = False)) Then //Checks
			If ValueIsFilled(Items.BankTransactions.CurrentData.Category) Then
				SkippingTableFieldsForChecks 			= True;
				Items.BankTransactionsCategory.ReadOnly = True;
				Items.BankTransactionsMemo.ReadOnly 	= True;
				Items.BankTransactionsDeposit.ReadOnly 	= True;
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure EditingModeOnChange(Item)
	
	ApplyEditingMode();
	
EndProcedure

&AtClient
Procedure BankTransactionsOnActivateRow(Item)
	
	If EditingNewRow = Undefined Then
		EditingNewRow = False;
	EndIf;
	If EditingNewRow Then
		If (Not ValueIsFilled(Items.BankTransactions.CurrentData.Period)) 
			Or (Not ValueIsFilled(Items.BankTransactions.CurrentData.RefNumber)) Then
			LastRow = GetLastRow();
			If LastRow = Undefined Then
				return;
			EndIf;
		EndIf;    		
		If Not ValueIsFilled(Items.BankTransactions.CurrentData.Period) Then
				Items.BankTransactions.CurrentData.Period = LastRow.Period;
		EndIf;
		If Not ValueIsFilled(Items.BankTransactions.CurrentData.RefNumber) Then
			If ValueIsFilled(LastRow.RefNumber) Then
				Try
					RefNum = Number(LastRow.RefNumber);
				Except
					RefNum = 0;
				EndTry;
				If (RefNum > 100) And (RefNum < 99999999) Then
					NewRefNum = Generalfunctions.LastCheckNumber(Object.BankAccount) + 1;
					Items.BankTransactions.CurrentData.RefNumber = Format(NewRefNum,"NG=0");
				Else
					Items.BankTransactions.CurrentData.RefNumber = LastRow.RefNumber;
				EndIf;
			EndIf;				
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure BankTransactionsOnActivateCell(Item)
	
	If SkippingTableFieldsForChecks Then
		Items.BankTransactionsCategory.ReadOnly = False;
		Items.BankTransactionsMemo.ReadOnly 	= False;
		Items.BankTransactionsDeposit.ReadOnly	= False;
		SkippingTableFieldsForChecks = False;
	EndIf;

EndProcedure

&AtClient
Procedure DepositsTotalOnChange(Item)
	
	ApplyNumberEditMode(Object, Object.DepositsTotal);
	Object.DepositsDifference 	= Object.DepositsTotal - Object.DepositsEntered;
	
EndProcedure

&AtClient
Procedure PaymentsTotalOnChange(Item)
	
	ApplyNumberEditMode(Object, Object.PaymentsTotal);
	Object.PaymentsDifference	= Object.PaymentsTotal - Object.PaymentsEntered;
	
EndProcedure

&AtClient
Procedure ChoosePeriod(Command)
	
	FormParameters = New Structure("BeginOfPeriod, EndOfPeriod", Object.DateStart, Object.DateEnd);
	OpenForm("CommonForm.ChoiceStandardPeriod", FormParameters, ThisForm, ,,,, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure BalanceStartEditOnChange(Item)
	
	ApplyNumberEditMode(Object, Object.BalanceStart);
	Object.BalanceEnd		= Object.BalanceStart + Object.DepositsEntered - Object.PaymentsEntered;
	
EndProcedure

&AtClient
Procedure BankTransactionsRefNumberOnChange(Item)
	CheckNumberResult = CommonUseServerCall.CheckNumberAllowed(Items.BankTransactions.CurrentData.RefNumber, Undefined, Object.BankAccount);
	If CheckNumberResult.DuplicatesFound Then
		If Not CheckNumberResult.Allow Then
			CommonUseClientServer.MessageToUser("Check number already exists for this bank account", Object, "Object.BankTransactions[" + Format(Items.BankTransactions.CurrentData.LineNumber-1, "NFD=; NG=0")+ "].RefNumber");
		Else
			Notify = New NotifyDescription("ProcessUserResponseOnRefNumberDuplicated", ThisObject);
			ShowQueryBox(Notify, "Check number already exists for this bank account. Continue?", QuestionDialogMode.YesNo);
		EndIf;
	Else
		ClearMessages();
	EndIf;
EndProcedure

&AtClient
Procedure ProcessUserResponseOnRefNumberDuplicated(Result, Parameters) Export
	
	If Result = DialogReturnCode.No Then
		CommonUseClientServer.MessageToUser("Check number already exists for this bank account", Object, "Object.BankTransactions[" + Format(Items.BankTransactions.CurrentData.LineNumber-1, "NFD=; NG=0")+ "].RefNumber");
	EndIf;
	
EndProcedure

#ENDREGION

#REGION FORM_SERVER_FUNCTIONS

&AtServer
Procedure BankAccountOnChangeAtServer()
	
	//Find the corresponding account in bank
	Object.BankAccount = Object.AccountInBank.AccountingAccount;
	If Not ValueIsFilled(Object.BankAccount) Then
		CommonUseClientServer.MessageToUser("Please, assign ACS account to the bank account. Bank account form -> Assigned to", Object, "AccountInBank");
		return;
	EndIf;
	FillBankTransactions();
		
EndProcedure

&AtServer
Procedure FillBankTransactions(RecordersList = Undefined)
	
	If Not (Object.DoNotUseJournalEntry Or Object.DoNotUseAdjustingJournalEntry Or Object.UseBankReconciliationForBegBal Or RecordersList <> Undefined) Then
		
		Request = New Query("SELECT ALLOWED
		                    |	GeneralJournalBalanceAndTurnovers.Recorder AS Recorder,
		                    |	GeneralJournalBalanceAndTurnovers.Period AS Period,
		                    |	GeneralJournalBalanceAndTurnovers.AmountRCClosingBalance,
		                    |	GeneralJournalBalanceAndTurnovers.Recorder.PointInTime AS RecorderPointInTime,
		                    |	GeneralJournalBalanceAndTurnovers.AmountRCOpeningBalance
		                    |INTO Recorders
		                    |FROM
		                    |	AccountingRegister.GeneralJournal.BalanceAndTurnovers(&DateStart, &DateEnd, Recorder, , Account = &Account, , ) AS GeneralJournalBalanceAndTurnovers
		                    |WHERE
		                    |	CASE
		                    |			WHEN &RecordersListIsSet = TRUE
		                    |				THEN GeneralJournalBalanceAndTurnovers.Recorder IN (&RecordersList)
		                    |			ELSE TRUE
		                    |		END
		                    |
		                    |INDEX BY
		                    |	Recorder
		                    |;
		                    |
		                    |////////////////////////////////////////////////////////////////////////////////
		                    |SELECT ALLOWED
		                    |	Recorders.Recorder AS Recorder,
		                    |	Recorders.Period,
		                    |	MAX(ClassData.Class) AS Class,
		                    |	MAX(ProjectData.Project) AS Project,
		                    |	Recorders.AmountRCClosingBalance,
		                    |	Recorders.RecorderPointInTime
		                    |INTO RecordersWithClassesAndProjects
		                    |FROM
		                    |	Recorders AS Recorders
		                    |		LEFT JOIN AccumulationRegister.ClassData AS ClassData
		                    |		ON Recorders.Recorder = ClassData.Recorder
		                    |		LEFT JOIN AccumulationRegister.ProjectData AS ProjectData
		                    |		ON Recorders.Recorder = ProjectData.Recorder
		                    |WHERE
		                    |	NOT Recorders.Recorder IS NULL 
		                    |	AND Recorders.Recorder <> UNDEFINED
		                    |
		                    |GROUP BY
		                    |	Recorders.Recorder,
		                    |	Recorders.Period,
		                    |	Recorders.AmountRCClosingBalance,
		                    |	Recorders.RecorderPointInTime
		                    |
		                    |INDEX BY
		                    |	Recorder
		                    |;
		                    |
		                    |////////////////////////////////////////////////////////////////////////////////
		                    |SELECT ALLOWED
		                    |	GeneralJournal.Recorder AS Document,
		                    |	VALUETYPE(GeneralJournal.Recorder) AS OperationType,
		                    |	GeneralJournal.Period AS Period,
		                    |	ISNULL(GeneralJournal.Recorder.Company, BankTransactions.Company) AS Company,
		                    |	CASE
		                    |		WHEN GeneralJournal.RecordType = VALUE(AccountingRecordType.Debit)
		                    |			THEN GeneralJournal.AmountRC
		                    |		ELSE 0
		                    |	END AS Deposit,
		                    |	CASE
		                    |		WHEN GeneralJournal.RecordType = VALUE(AccountingRecordType.Credit)
		                    |			THEN GeneralJournal.AmountRC
		                    |		ELSE 0
		                    |	END AS Payment,
		                    |	ISNULL(GeneralJournal1.Account, BankTransactions.Category) AS Category,
		                    |	GeneralJournal.Recorder.Memo AS Memo,
		                    |	ISNULL(RecordersWithClassesAndProjects.Class, BankTransactions.Class) AS Field1,
		                    |	ISNULL(RecordersWithClassesAndProjects.Project, BankTransactions.Project) AS Field2,
		                    |	TRUE AS HasDocument,
		                    |	BankTransactions.ID AS TransactionID,
		                    |	CASE
		                    |		WHEN ISNULL(BankTransactions.Accepted, FALSE)
		                    |			THEN ""C""
		                    |		ELSE """"
		                    |	END AS Cleared,
		                    |	CASE
		                    |		WHEN ISNULL(BankReconciliationBalance.AmountBalance, 0) = 0
		                    |			THEN ""R""
		                    |		ELSE """"
		                    |	END AS Reconciled,
		                    |	RecordersWithClassesAndProjects.AmountRCClosingBalance AS AmountClosingBalance,
		                    |	RecordersWithClassesAndProjects.RecorderPointInTime,
		                    |	CASE
		                    |		WHEN GeneralJournal.Recorder REFS Document.Check
		                    |			THEN GeneralJournal.Recorder.Number
		                    |		ELSE """"
		                    |	END AS RefNumber,
		                    |	CASE
		                    |		WHEN GeneralJournal.Recorder.Company IS NULL 
		                    |			THEN BankTransactions.Company.Code
		                    |		ELSE GeneralJournal.Recorder.Company.Code
		                    |	END AS CompanyCode
		                    |FROM
		                    |	RecordersWithClassesAndProjects AS RecordersWithClassesAndProjects
		                    |		LEFT JOIN AccountingRegister.GeneralJournal AS GeneralJournal
		                    |			LEFT JOIN AccountingRegister.GeneralJournal AS GeneralJournal1
		                    |			ON GeneralJournal.Recorder = GeneralJournal1.Recorder
		                    |				AND GeneralJournal.Account <> GeneralJournal1.Account
		                    |				AND (GeneralJournal.AmountRC = GeneralJournal1.AmountRC
		                    |					OR GeneralJournal.AmountRC = -1 * GeneralJournal1.AmountRC)
		                    |		ON RecordersWithClassesAndProjects.Recorder = GeneralJournal.Recorder
		                    |			AND (GeneralJournal.Account = &Account)
		                    |		LEFT JOIN InformationRegister.BankTransactions AS BankTransactions
		                    |		ON RecordersWithClassesAndProjects.Recorder = BankTransactions.Document
		                    |			AND (BankTransactions.BankAccount = &AccountInBank)
		                    |		LEFT JOIN AccumulationRegister.BankReconciliation.Balance(
		                    |				,
		                    |				Document IN
		                    |					(SELECT
		                    |						Recorders.Recorder
		                    |					FROM
		                    |						Recorders AS Recorders)) AS BankReconciliationBalance
		                    |		ON RecordersWithClassesAndProjects.Recorder = BankReconciliationBalance.Document
		                    |			AND (BankReconciliationBalance.Account = &Account)
		                    |
		                    |ORDER BY
		                    |	RecordersWithClassesAndProjects.RecorderPointInTime
		                    |;
		                    |
		                    |////////////////////////////////////////////////////////////////////////////////
		                    |SELECT TOP 1
		                    |	Recorders.AmountRCOpeningBalance AS AmountOpeningBalance
		                    |FROM
		                    |	Recorders AS Recorders
		                    |WHERE
		                    |	&RecordersListIsSet = FALSE
		                    |
		                    |ORDER BY
		                    |	Recorders.Period,
		                    |	Recorders.Recorder.PointInTime
							|;
							|");
	Else
		
		Request = New Query();
		Request.Text = "SELECT ALLOWED
		               |	GeneralJournalBalanceAndTurnovers.Recorder AS Recorder,
		               |	GeneralJournalBalanceAndTurnovers.Period AS Period,
		               |	GeneralJournalBalanceAndTurnovers.AmountRCClosingBalance,
		               |	GeneralJournalBalanceAndTurnovers.Recorder.PointInTime AS RecorderPointInTime,
		               |	GeneralJournalBalanceAndTurnovers.AmountRCOpeningBalance
		               |INTO Recorders
		               |FROM
		               |	AccountingRegister.GeneralJournal.BalanceAndTurnovers(&DateStart, &DateEnd, Recorder, , Account = &Account, , ) AS GeneralJournalBalanceAndTurnovers
		               |WHERE
		               |	CASE
		               |			WHEN &RecordersListIsSet = TRUE
		               |				THEN GeneralJournalBalanceAndTurnovers.Recorder IN (&RecordersList)
		               |			ELSE TRUE
		               |		END
		               |
		               |INDEX BY
		               |	Recorder
		               |;
		               |
		               |////////////////////////////////////////////////////////////////////////////////
		               |SELECT ALLOWED
		               |	Recorders.Recorder AS Recorder,
		               |	Recorders.Period,
		               |	MAX(ClassData.Class) AS Class,
		               |	MAX(ProjectData.Project) AS Project,
		               |	Recorders.AmountRCClosingBalance,
		               |	Recorders.RecorderPointInTime
		               |INTO RecordersWithClassesAndProjects
		               |FROM
		               |	Recorders AS Recorders
		               |		LEFT JOIN AccumulationRegister.ClassData AS ClassData
		               |		ON Recorders.Recorder = ClassData.Recorder
		               |		LEFT JOIN AccumulationRegister.ProjectData AS ProjectData
		               |		ON Recorders.Recorder = ProjectData.Recorder
		               |WHERE
		               |	NOT Recorders.Recorder IS NULL 
		               |	AND Recorders.Recorder <> UNDEFINED
		               |	AND CASE
		               |			WHEN Recorders.Recorder REFS Document.GeneralJournalEntry
		               |				THEN Recorders.Recorder.Adjusting = TRUE
		               |							AND &DoNotUseAdjustingJournalEntry = FALSE
		               |						OR Recorders.Recorder.Adjusting = FALSE
		               |							AND &DoNotUseJournalEntry = FALSE
		               |			ELSE TRUE
		               |		END
		               |
		               |GROUP BY
		               |	Recorders.Recorder,
		               |	Recorders.Period,
		               |	Recorders.AmountRCClosingBalance,
		               |	Recorders.RecorderPointInTime
		               |
		               |INDEX BY
		               |	Recorder
		               |;
		               |
		               |////////////////////////////////////////////////////////////////////////////////
		               |SELECT ALLOWED
		               |	GeneralJournal.Recorder AS Document,
		               |	VALUETYPE(GeneralJournal.Recorder) AS OperationType,
		               |	GeneralJournal.Period AS Period,
		               |	ISNULL(GeneralJournal.Recorder.Company, BankTransactions.Company) AS Company,
		               |	CASE
		               |		WHEN GeneralJournal.RecordType = VALUE(AccountingRecordType.Debit)
		               |			THEN GeneralJournal.AmountRC
		               |		ELSE 0
		               |	END AS Deposit,
		               |	CASE
		               |		WHEN GeneralJournal.RecordType = VALUE(AccountingRecordType.Credit)
		               |			THEN GeneralJournal.AmountRC
		               |		ELSE 0
		               |	END AS Payment,
		               |	ISNULL(GeneralJournal1.Account, BankTransactions.Category) AS Category,
		               |	GeneralJournal.Recorder.Memo AS Memo,
		               |	ISNULL(RecordersWithClassesAndProjects.Class, BankTransactions.Class) AS Field1,
		               |	ISNULL(RecordersWithClassesAndProjects.Project, BankTransactions.Project) AS Field2,
		               |	TRUE AS HasDocument,
		               |	BankTransactions.ID AS TransactionID,
		               |	CASE
		               |		WHEN ISNULL(BankTransactions.Accepted, FALSE)
		               |			THEN ""C""
		               |		ELSE """"
		               |	END AS Cleared,
		               |	CASE
		               |		WHEN ISNULL(BankReconciliationBalance.AmountBalance, 0) = 0
		               |			THEN ""R""
		               |		ELSE """"
		               |	END AS Reconciled,
		               |	RecordersWithClassesAndProjects.AmountRCClosingBalance AS AmountClosingBalance,
		               |	RecordersWithClassesAndProjects.RecorderPointInTime,
		               |	CASE
		               |		WHEN GeneralJournal.Recorder REFS Document.Check
		               |			THEN GeneralJournal.Recorder.Number
		               |		ELSE """"
		               |	END AS RefNumber,
		               |	CASE
		               |		WHEN GeneralJournal.Recorder.Company IS NULL 
		               |			THEN BankTransactions.Company.Code
		               |		ELSE GeneralJournal.Recorder.Company.Code
		               |	END AS CompanyCode
		               |FROM
		               |	RecordersWithClassesAndProjects AS RecordersWithClassesAndProjects
		               |		LEFT JOIN AccountingRegister.GeneralJournal AS GeneralJournal
		               |			LEFT JOIN AccountingRegister.GeneralJournal AS GeneralJournal1
		               |			ON GeneralJournal.Recorder = GeneralJournal1.Recorder
		               |				AND GeneralJournal.Account <> GeneralJournal1.Account
		               |				AND (GeneralJournal.AmountRC = GeneralJournal1.AmountRC
		               |					OR GeneralJournal.AmountRC = -1 * GeneralJournal1.AmountRC)
		               |		ON RecordersWithClassesAndProjects.Recorder = GeneralJournal.Recorder
		               |			AND (GeneralJournal.Account = &Account)
		               |		LEFT JOIN InformationRegister.BankTransactions AS BankTransactions
		               |		ON RecordersWithClassesAndProjects.Recorder = BankTransactions.Document
		               |			AND (BankTransactions.BankAccount = &AccountInBank)
		               |		LEFT JOIN AccumulationRegister.BankReconciliation.Balance(
		               |				,
		               |				Document IN
		               |					(SELECT
		               |						Recorders.Recorder
		               |					FROM
		               |						Recorders AS Recorders)) AS BankReconciliationBalance
		               |		ON RecordersWithClassesAndProjects.Recorder = BankReconciliationBalance.Document
		               |			AND (BankReconciliationBalance.Account = &Account)
		               |
		               |ORDER BY
		               |	RecordersWithClassesAndProjects.RecorderPointInTime
					   |;
					   |";
	If Not Object.UseBankReconciliationForBegBal Then 
		Request.Text = Request.Text + "SELECT TOP 1
		                              |	Recorders.AmountRCOpeningBalance AS AmountOpeningBalance
		                              |FROM
		                              |	Recorders AS Recorders
		                              |WHERE
		                              |	&RecordersListIsSet = FALSE
		                              |
		                              |ORDER BY
		                              |	Recorders.Period,
		                              |	Recorders.Recorder.PointInTime
		                              |;
		                              |
		                              |////////////////////////////////////////////////////////////////////////////////
		                              |SELECT ALLOWED
		                              |	ISNULL(JETurnovers.AmountTurnover, 0) AS AmountTurnover
		                              |FROM
		                              |	(SELECT
		                              |		SUM(GeneralJournalBalanceAndTurnovers.AmountRCTurnover) AS AmountTurnover
		                              |	FROM
		                              |		AccountingRegister.GeneralJournal.BalanceAndTurnovers(, &BeforeDateStart, Recorder, , Account = &Account, , ) AS GeneralJournalBalanceAndTurnovers
		                              |	WHERE
		                              |		CASE
		                              |				WHEN GeneralJournalBalanceAndTurnovers.Recorder REFS Document.GeneralJournalEntry
		                              |					THEN GeneralJournalBalanceAndTurnovers.Recorder.Adjusting = TRUE
		                              |								AND &DoNotUseAdjustingJournalEntry = TRUE
		                              |							OR GeneralJournalBalanceAndTurnovers.Recorder.Adjusting = FALSE
		                              |								AND &DoNotUseJournalEntry = TRUE
		                              |				ELSE FALSE
		                              |			END) AS JETurnovers
		                              |";
	Else
		Request.Text = Request.Text + "////////////////////////////////////////////////////////////////////////////////
									  |	SELECT ALLOWED
		                              |	BankReconciliation.EndingBalance AS ReconcilliationEndingBalance
		                              |FROM
		                              |	(SELECT
		                              |		MAX(BankReconciliation.Date) AS Date
		                              |	FROM
		                              |		Document.BankReconciliation AS BankReconciliation
		                              |	WHERE
		                              |		BankReconciliation.BankAccount = &Account
		                              |		AND BankReconciliation.Posted = TRUE
		                              |		AND BankReconciliation.Date < &BankRegisterDateStart) AS LatestReconcilliation
		                              |		INNER JOIN Document.BankReconciliation AS BankReconciliation
		                              |		ON LatestReconcilliation.Date = BankReconciliation.Date
		                              |			AND (BankReconciliation.BankAccount = &Account)
		                              |			AND (BankReconciliation.Posted)
		                              |";
					   
		Request.SetParameter("BankRegisterDateStart", Object.DateStart);					   
	EndIf;
		Request.SetParameter("DoNotUseAdjustingJournalEntry", Object.DoNotUseAdjustingJournalEntry);
		Request.SetParameter("DoNotUseJournalEntry", Object.DoNotUseJournalEntry);
		If ValueIsFilled(Object.DateStart) Then
			Request.SetParameter("BeforeDateStart", New Boundary(Object.DateStart, BoundaryType.Excluding));
		Else
			Request.SetParameter("BeforeDateStart", New Boundary('00010102', BoundaryType.Excluding));
		EndIf;
	EndIf;						
						
	Request.SetParameter("Account", Object.BankAccount);
	Request.SetParameter("AccountInBank", Object.AccountInBank);
	Request.SetParameter("DateStart", New Boundary(Object.DateStart, BoundaryType.Including));
	Request.SetParameter("DateEnd", New Boundary(EndOfDay(Object.DateEnd), BoundaryType.Including));
	Request.SetParameter("RecordersList", RecordersList); 
	Request.SetParameter("RecordersListIsSet", ?(RecordersList = Undefined, False, True));
	If RecordersList = Undefined Then
		BatchResult			= Request.ExecuteBatch();
		BankTransactions 	= BatchResult[2].Unload();
				
		Object.BankTransactions.Load(BankTransactions);
				
		If Not Object.UseBankReconciliationForBegBal Then
			BankBalances		= BatchResult[3].Unload();
		    If BankBalances.Count() > 0 Then
				Object.BalanceStart = BankBalances[0].AmountOpeningBalance;
				If Object.DoNotUseJournalEntry Or Object.DoNotUseAdjustingJournalEntry Then
					JETurnovers		= BatchResult[4].Unload();
					If JETurnovers.Count() > 0 Then
						Object.BalanceStart = Object.BalanceStart - JETurnovers[0].AmountTurnover;
					EndIf;
				EndIf;
			Else
				Object.BalanceStart = 0;
			EndIf;
		Else
			BankBalances 		= BatchResult[3].Unload(); 
			If BankBalances.Count() > 0 Then
				Object.BalanceStart = BankBalances[0].ReconcilliationEndingBalance;
			Else
				Object.BalanceStart = 0;
			EndIf;
		EndIf;
		
		//Fix the current order in the Sequence column
		index = 1;
		For Each BankTransaction In Object.BankTransactions Do
			BankTransaction.Sequence = index;
			index = index + 1;
		EndDo;
		
		If Object.BankTransactions.Count() > 0 Then
			Items.BankTransactions.CurrentRow = Object.BankTransactions[Object.BankTransactions.Count()-1].GetID();	
		EndIf;
		
	Else
		BatchResult			= Request.ExecuteBatch();
		ResTable 			= BatchResult[2].Unload();
		For Each ResRow In ResTable Do
			FoundRows = Object.BankTransactions.FindRows(New Structure("Document", ResRow.Document));
			If FoundRows.Count() > 0 Then
				FillPropertyValues(FoundRows[0], ResRow);
				If Not ValueIsFilled(FoundRows[0].Sequence) Then
					FoundRows[0].Sequence = Object.BankTransactions.Count();
				EndIf;
			Else
				NewRow = Object.BankTransactions.Add();
				FillPropertyValues(NewRow, ResRow);
				NewRow.Sequence = Object.BankTransactions.Count() + 1;
			EndIf;
		EndDo;
	EndIf;
	//Recalculating totals
	Object.DepositsEntered 	= Object.BankTransactions.Total("Deposit");
	Object.PaymentsEntered	= Object.BankTransactions.Total("Payment");
	Object.DepositsDifference	= Object.DepositsTotal - Object.DepositsEntered;
	Object.PaymentsDifference	= Object.PaymentsTotal - Object.PaymentsEntered;
	Object.BalanceEnd		= Object.BalanceStart + Object.DepositsEntered - Object.PaymentsEntered;
	
EndProcedure

&AtServer
Procedure CreateTransactionsAtServer(RowID = Undefined)
	
	//Save current data in BankTransactionsUnaccepted for using in case of failure
	CurrentTransactions = Object.BankTransactions.Unload();
	If RowID = Undefined Then
		Transactions = Object.BankTransactions.FindRows(New Structure("HasDocument", False));
	Else
		Transactions = New Array();
		Transactions.Add(Object.BankTransactions.FindByID(RowID));
	EndIf;
	Try
	BeginTransaction();
	UpdatedRecorders = New Array();
	i = 0;
	BTRecordset = InformationRegisters.BankTransactions.CreateRecordSet();
	While i < Transactions.Count() Do
		Tran = Transactions[i];
		
		//Perform filling check
		If (Tran.Payment = 0 And Tran.Deposit = 0) Or (Not ValueIsFilled(Tran.Category)) Or (Not ValueIsFilled(Tran.Period)) Then
			i = i + 1;
			Continue;
		EndIf;
		//A user can modify only Deposit and Check
		If TypeOf(Tran.Document) <> Type("DocumentRef.Deposit") And TypeOf(Tran.Document) <> Type("DocumentRef.Check") And Tran.Document <> Undefined Then
			i = i + 1;
			Continue;
		EndIf;
		
		If Tran.Payment <> 0 Then //Create Check
			Tran.Document				= Create_DocumentCheck(Tran);
			Tran.HasDocument 			= True;
		ElsIf Tran.Deposit <> 0 Then //Create Deposit
			Tran.Document				= Create_DocumentDeposit(Tran);
			Tran.HasDocument			= True;
		Else
			i = i + 1;
			Continue;
		EndIf;
		
		UpdatedRecorders.Add(Tran.Document);
		
		//Add (save) current row to a information register
		BTRecordset.Clear();
		BTRecordSet.Filter.Reset();
		If NOT ValueIsFilled(Tran.TransactionID) then
			Tran.TransactionID = New UUID();
		EndIf;
		BTRecordset.Filter.ID.Set(Tran.TransactionID);
		BTRecordset.Write(True);
		
		BTRecordset.Clear();
		BTRecordset.Filter.TransactionDate.Set(Tran.Period);
		BTRecordset.Filter.BankAccount.Set(Object.AccountInBank);
		BTRecordset.Filter.Company.Set(Tran.Company);
		BTRecordset.Filter.ID.Set(Tran.TransactionID);
		NewRecord = BTRecordset.Add();
		FillPropertyValues(NewRecord, Tran);
		NewRecord.TransactionDate = Tran.Period;
		NewRecord.BankAccount 	= Object.AccountInBank;
		NewRecord.Description	= Tran.Memo;
		NewRecord.Amount 		= ?(Tran.Deposit > 0, Tran.Deposit, -1*Tran.Payment);
		NewRecord.Accepted 		= True;
		NewRecord.ID			= Tran.TransactionID;
		BTRecordset.Write(True);
		
		i = i + 1;
	EndDo;
		
	Except
	    ErrDesc	= ErrorDescription();
		If TransactionActive() Then
			RollbackTransaction();
		EndIf;
		Object.BankTransactions.Load(CurrentTransactions);
		CommonUseClientServer.MessageToUser(ErrDesc);
		Return;
	EndTry;		
	
	CommitTransaction();
	FillBankTransactions(UpdatedRecorders);
	
EndProcedure

&AtServer
Function Create_DocumentCheck(Tran)	
	
	If ValueIsFilled(Tran.Document) then
		If Not DocumentIsAutoGenerated(Tran.Document) Then
			return Tran.Document;
		EndIf;
		
		//Refill only auto-generated documents
		NewCheck		= Tran.Document.GetObject();
	Else
		NewCheck 		= Documents.Check.CreateDocument();
	EndIf;
	NewCheck.Date 				= Tran.Period;
	If ValueIsFilled(Tran.RefNumber) Then
		NewCheck.Number = Tran.RefNumber;
	EndIf;
	NewCheck.BankAccount 		= Object.BankAccount;
	NewCheck.Memo 				= Tran.Memo;
	NewCheck.Company 			= Tran.Company;
	NewCheck.DocumentTotal 		= Tran.Payment;
	NewCheck.DocumentTotalRC 	= Tran.Payment;
	NewCheck.ExchangeRate 		= 1;
	Try
		RefNum = Number(Tran.RefNumber);
	Except
		RefNum = 0;
	EndTry;
	If (RefNum > 100) And (RefNum < 99999999) Then
		NewCheck.PaymentMethod 	= Catalogs.PaymentMethods.Check;
	Else
		NewCheck.PaymentMethod		= Catalogs.PaymentMethods.DebitCard;
	EndIf;
	NewCheck.Project			= Tran.Project;
	NewCheck.AutoGenerated		= True;
	
	NewCheck.LineItems.Clear();
	NewLine = NewCheck.LineItems.Add();
	NewLine.Account 			= Tran.Category;
	NewLine.Amount 				= Tran.Payment;
	NewLine.Memo 				= Tran.Memo;
	NewLine.Class				= Tran.Class;
	NewLine.Project 			= Tran.Project;
	//Deletion mark
	If NewCheck.DeletionMark Then
		NewCheck.DeletionMark	= False;	
	EndIf;
	NewCheck.Write(DocumentWriteMode.Posting);
	
	Return NewCheck.Ref;
	
EndFunction

&AtServer
Function Create_DocumentDeposit(Tran)
	
	If ValueIsFilled(Tran.Document) then
		If Not DocumentIsAutoGenerated(Tran.Document) Then
			return Tran.Document;
		EndIf;
		
		//Refill only auto-generated documents
		NewDeposit		= Tran.Document.GetObject();
	Else
		NewDeposit 		= Documents.Deposit.CreateDocument();
	EndIf;
	NewDeposit.Date 			= Tran.Period;
	NewDeposit.BankAccount 		= Object.BankAccount;
	NewDeposit.Memo 			= Tran.Memo;
	NewDeposit.DocumentTotal 	= Tran.Deposit;
	NewDeposit.DocumentTotalRC 	= Tran.Deposit;
	NewDeposit.TotalDeposits	= 0;
	NewDeposit.TotalDepositsRC	= 0;
	NewDeposit.AutoGenerated	= True;
		
	NewDeposit.Accounts.Clear();
	NewLine = NewDeposit.Accounts.Add();
	NewLine.Account 			= Tran.Category;
	NewLine.Memo 				= Tran.Memo;
	NewLine.Company				= Tran.Company;
	NewLine.Amount 				= Tran.Deposit;
	NewLine.Class 				= Tran.Class;
	NewLine.Project 			= Tran.Project;
	//Deletion mark
	If NewDeposit.DeletionMark Then
		NewDeposit.DeletionMark	= False;	
	EndIf;
	NewDeposit.Write(DocumentWriteMode.Posting);
	
	Return NewDeposit.Ref;
	
EndFunction

&AtServerNoContext
Function DocumentIsAutoGenerated(Document)
	If (TypeOf(Document) = Type("DocumentRef.Deposit")) 
		Or (TypeOf(Document) = Type("DocumentRef.Check"))
		Or (TypeOf(Document) = Type("DocumentRef.BankTransfer"))
		Or (TypeOf(Document) = Type("DocumentRef.CashReceipt")) 
		Or (TypeOf(Document) = Type("DocumentRef.InvoicePayment")) Then
		return Document.AutoGenerated;
	Else
		return False;
	EndIf;
EndFunction

&AtServer
Procedure ApplyConditionalAppearance()
	
	CA = ThisForm.ConditionalAppearance; 
 	CA.Items.Clear(); 

	//After a document is created document type cannot be changed
	ElementCA = CA.Items.Add(); 
	
	FieldAppearance = ElementCA.Fields.Items.Add(); 
	FieldAppearance.Field = New DataCompositionField("BankTransactionsDeposit"); 
 	FieldAppearance.Use = True; 

	FilterElement = ElementCA.Filter.Items.Add(Type("DataCompositionFilterItem")); // current row filter 
	FilterElement.LeftValue 		= New DataCompositionField("Object.BankTransactions.Payment"); 
	FilterElement.ComparisonType 	= DataCompositionComparisonType.NotEqual; 
	FilterElement.RightValue 		= 0; 
	FilterElement.Use				= True;
	
	FilterElement = ElementCA.Filter.Items.Add(Type("DataCompositionFilterItem")); // current row filter 
	FilterElement.LeftValue 		= New DataCompositionField("Object.BankTransactions.HasDocument"); 
	FilterElement.ComparisonType 	= DataCompositionComparisonType.Equal; 
	FilterElement.RightValue 		= True; 
	FilterElement.Use				= True;
	
	ElementCA.Appearance.SetParameterValue("Readonly", True); 
	
	ElementCA = CA.Items.Add(); 
	
	FieldAppearance = ElementCA.Fields.Items.Add(); 
	FieldAppearance.Field = New DataCompositionField("BankTransactionsPayment"); 
 	FieldAppearance.Use = True; 

	FilterElement = ElementCA.Filter.Items.Add(Type("DataCompositionFilterItem")); // current row filter 
	FilterElement.LeftValue 		= New DataCompositionField("Object.BankTransactions.Deposit"); 
	FilterElement.ComparisonType 	= DataCompositionComparisonType.NotEqual; 
	FilterElement.RightValue 		= 0; 
	FilterElement.Use				= True;
	
	FilterElement = ElementCA.Filter.Items.Add(Type("DataCompositionFilterItem")); // current row filter 
	FilterElement.LeftValue 		= New DataCompositionField("Object.BankTransactions.HasDocument"); 
	FilterElement.ComparisonType 	= DataCompositionComparisonType.Equal; 
	FilterElement.RightValue 		= True; 
	FilterElement.Use				= True;
	
	ElementCA.Appearance.SetParameterValue("Readonly", True); 
	
	//Modifications are allowed only to the Deposit and Check
	 ElementCA = CA.Items.Add(); 
	
	AddDataCompositionFields(ElementCA, Items.BankTransactions.ChildItems);
	
	FilterElement = ElementCA.Filter.Items.Add(Type("DataCompositionFilterItem")); // current row filter 
	FilterElement.LeftValue 		= New DataCompositionField("Object.BankTransactions.OperationType"); 
	FilterElement.ComparisonType 	= DataCompositionComparisonType.NotEqual; 
	FilterElement.RightValue 		= "Deposit"; 
	FilterElement.Use				= True;
	
	FilterElement = ElementCA.Filter.Items.Add(Type("DataCompositionFilterItem")); // current row filter 
	FilterElement.LeftValue 		= New DataCompositionField("Object.BankTransactions.OperationType"); 
	FilterElement.ComparisonType 	= DataCompositionComparisonType.NotEqual; 
	FilterElement.RightValue 		= "Payment"; 
	FilterElement.Use				= True;
	
	FilterElement = ElementCA.Filter.Items.Add(Type("DataCompositionFilterItem")); // current row filter 
	FilterElement.LeftValue 		= New DataCompositionField("Object.BankTransactions.OperationType"); 
	FilterElement.ComparisonType 	= DataCompositionComparisonType.NotEqual; 
	FilterElement.RightValue 		= ""; 
	FilterElement.Use				= True;
	
	ElementCA.Appearance.SetParameterValue("Readonly", True); 
	
	//Ref Number can be used for Checks only
	ElementCA = CA.Items.Add(); 
	
	FieldAppearance = ElementCA.Fields.Items.Add(); 
	FieldAppearance.Field = New DataCompositionField("BankTransactionsRefNumber"); 
	 FieldAppearance.Use = True; 

	FilterElement = ElementCA.Filter.Items.Add(Type("DataCompositionFilterItem")); // current row filter 
	FilterElement.LeftValue 		= New DataCompositionField("Object.BankTransactions.OperationType"); 
	FilterElement.ComparisonType 	= DataCompositionComparisonType.NotEqual; 
	FilterElement.RightValue 		= "Payment"; 
	FilterElement.Use				= True;
	
	FilterElement = ElementCA.Filter.Items.Add(Type("DataCompositionFilterItem")); // current row filter 
	FilterElement.LeftValue 		= New DataCompositionField("Object.BankTransactions.OperationType"); 
	FilterElement.ComparisonType 	= DataCompositionComparisonType.NotEqual; 
	FilterElement.RightValue 		= ""; 
	FilterElement.Use				= True;
			
	ElementCA.Appearance.SetParameterValue("Readonly", True); 
	
	//If PaymentsDifference <> 0 Then highlight in red color
	ElementCA = CA.Items.Add(); 
	
	FieldAppearance = ElementCA.Fields.Items.Add(); 
	FieldAppearance.Field = New DataCompositionField("PaymentsDifference"); 
 	FieldAppearance.Use = True; 

	FilterElement = ElementCA.Filter.Items.Add(Type("DataCompositionFilterItem")); // current row filter 
	FilterElement.LeftValue 		= New DataCompositionField("Object.PaymentsDifference"); 
	FilterElement.ComparisonType 	= DataCompositionComparisonType.NotEqual; 
	FilterElement.RightValue 		= 0; 
	FilterElement.Use				= True;
	
	ElementCA.Appearance.SetParameterValue("TextColor", WebColors.Red); 
	
	//If DepositsDifference <> 0 Then highlight in red color
	ElementCA = CA.Items.Add(); 
	
	FieldAppearance = ElementCA.Fields.Items.Add(); 
	FieldAppearance.Field = New DataCompositionField("DepositsDifference"); 
 	FieldAppearance.Use = True; 

	FilterElement = ElementCA.Filter.Items.Add(Type("DataCompositionFilterItem")); // current row filter 
	FilterElement.LeftValue 		= New DataCompositionField("Object.DepositsDifference"); 
	FilterElement.ComparisonType 	= DataCompositionComparisonType.NotEqual; 
	FilterElement.RightValue 		= 0; 
	FilterElement.Use				= True;
	
	ElementCA.Appearance.SetParameterValue("TextColor", WebColors.Red); 
	
	//Display for a Company Code as well as Description
	Request = New Query("SELECT ALLOWED
	                    |	Companies.Code,
	                    |	Companies.Description
	                    |FROM
	                    |	Catalog.Companies AS Companies");
	Companies = Request.Execute().Unload();
	
	For Each Company In Companies Do
		
		ElementCA = CA.Items.Add(); 
	
		FieldAppearance = ElementCA.Fields.Items.Add(); 
		FieldAppearance.Field = New DataCompositionField("BankTransactionsCompany"); 
 		FieldAppearance.Use = True; 
		
		FilterElement = ElementCA.Filter.Items.Add(Type("DataCompositionFilterItem")); // current row filter 
		FilterElement.LeftValue 		= New DataCompositionField("Object.BankTransactions.CompanyCode"); 
		FilterElement.ComparisonType 	= DataCompositionComparisonType.Equal; 
		FilterElement.RightValue 		= Company.Code; 
		FilterElement.Use				= True;
		
		FilterElement = ElementCA.Filter.Items.Add(Type("DataCompositionFilterItem")); // current row filter 
		FilterElement.LeftValue 		= New DataCompositionField("Object.BankTransactions.Company"); 
		FilterElement.ComparisonType 	= DataCompositionComparisonType.NotEqual; 
		FilterElement.RightValue 		= Catalogs.Companies.EmptyRef(); 
		FilterElement.Use				= True;
	
		ElementCA.Appearance.SetParameterValue("Text", Company.Code + " " + Company.Description); 	
		
	EndDo;	

EndProcedure

&AtServer
Procedure AddDataCompositionFields(ElementCA, ChildItems, ExceptingFields = "")
	
	For Each ChildItem IN ChildItems Do
		If TypeOf(ChildItem) = Type("FormField") Then
			If Find(ExceptingFields, ChildItem.Name) > 0 Then
				Continue;
			EndIf;
 			FieldAppearance = ElementCA.Fields.Items.Add(); // Fields of the table with CA 
			FieldAppearance.Field = New DataCompositionField(ChildItem.Name); 
 			FieldAppearance.Use = True; 
		ElsIf TypeOf(ChildItem) = Type("FormGroup") Then
			AddDataCompositionFields(ElementCA, ChildItem.ChildItems, ExceptingFields);
		EndIf;
	EndDo;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetBalancesVisibility(ThisForm, HideBalances)
	
	Items 	= ThisForm.Items;
	Items.BankTransactionsAmountClosingBalance.Visible 	= Not HideBalances;
	
EndProcedure

&AtServer
Procedure ProcessSettingsChangeAtServer()
	
	SetBalancesVisibility(ThisForm, Object.HideBalances);
	
	If Object.EditBegBal Then 
		Items.BalanceStart.Visible = False;
		Items.BalanceStartEdit.Visible = True;
	Else
		Items.BalanceStart.Visible = True;
		Items.BalanceStartEdit.Visible = False;
	EndIf;
	EndOfDateEnd = EndOfDay(Object.DateEnd);
	PeriodPresentation = PeriodPresentation(Object.DateStart, EndOfDateEnd);
	
	FillBankTransactions();
	
EndProcedure

&AtClient
Procedure SortListAsc(Command)
	
	Sorting = True;
	If (Items.BankTransactions.CurrentItem.Name = "BankTransactionsPeriod") Then
		Object.BankTransactions.Sort("Period Asc, Sequence Asc");
	Else
		Object.BankTransactions.Sort(StrReplace(Items.BankTransactions.CurrentItem.Name, "BankTransactions", "") + " ASC");
	EndIf;
	Sorting = False;
	
EndProcedure

&AtClient
Procedure SortListDesc(Command)
	
	Sorting = True;
	If (Items.BankTransactions.CurrentItem.Name = "BankTransactionsPeriod") Then
		Object.BankTransactions.Sort("Period Desc, Sequence Desc");
	Else
		Object.BankTransactions.Sort(StrReplace(Items.BankTransactions.CurrentItem.Name, "BankTransactions", "") + " DESC");
	EndIf;
	Sorting = False;

EndProcedure

&AtClientAtServerNoContext
Procedure ApplyNumberEditMode(Object, EditValue)
	
	If Object.EditNumbersWithoutDecimalPoint Then
		EditValue = EditValue/100;
	EndIf;
	
EndProcedure

&AtServer
Procedure ApplyEditingMode()
	
	If Object.EditingMode = 0 Then //Show all
		Items.BankTransactions.RowFilter = Undefined;
		Items.BankTransactionsDeposit.Visible = True;
		Items.BankTransactionsPayment.Visible = True;
	ElsIf Object.EditingMode = 1 Then //Checks
		Items.BankTransactions.RowFilter = New FixedStructure("Deposit", 0);
		Items.BankTransactionsDeposit.Visible = False;
		Items.BankTransactionsPayment.Visible = True;
	ElsIf Object.EditingMode = 2 Then //Deposits
		Items.BankTransactions.RowFilter = New FixedStructure("Payment", 0);
		Items.BankTransactionsPayment.Visible = False;
		Items.BankTransactionsDeposit.Visible = True;
	EndIf;
		
EndProcedure

&AtClient
Function GetLastRow()
	
	If Object.EditingMode = 0 Then //All
		If Object.BankTransactions.Count() > 1 Then
			return Object.BankTransactions[Object.BankTransactions.Count()-2];
		Else
			return Undefined;
		EndIf;
	ElsIf Object.EditingMode = 1 Then //Checks
		FoundChecks = Object.BankTransactions.FindRows(New Structure("Deposit", 0));
		If FoundChecks.Count() > 1 Then
			return FoundChecks[FoundChecks.Count()-2];
		Else
			return Undefined;
		EndIf;
	ElsIf Object.EditingMode = 2 Then //Deposits
		FoundDeposits = Object.BankTransactions.FindRows(New Structure("Payment", 0));
		If FoundDeposits.Count() > 1 Then
			return FoundDeposits[FoundDeposits.Count()-2];
		Else
			return Undefined;
		EndIf;
	EndIf;
	
EndFunction

#ENDREGION

#REGION FILE_UPLOAD

&AtClient
Procedure FileUpload(Result, Address, SelectedFileName, AdditionalParameters) Export
	
	Extension = Lower(Right(SelectedFileName, 4));
	
	If Extension <> ".qif"
		And Extension <> ".qbo"
		And Extension <> ".qfx"
		And Extension <> ".ofx"
		And Extension <> ".csv"
		And Extension <> ".iif"
		And Extension <> ".txt"
		Then
		
		ShowMessageBox(, NStr("en = 'Please upload a valid file:
                               |.qif
                               |.qbo
                               |.qfx
                               |.ofx
                               |.csv
                               |.iif
                               |.txt'"));
		Return;
		
	EndIf;
	
	If ValueIsFilled(Address) And Extension = ".qif" Then
		QIF_UploadTransactionsAtServer(Address);
	ElsIf ValueIsFilled(Address) And (Extension = ".qbo" Or Extension = ".qfx" Or Extension = ".ofx") Then
		QBO_QFX_OFX_UploadTransactionsAtServer(Address);
	ElsIf ValueIsFilled(Address) And (Extension = ".csv" Or Extension = ".txt") Then
		CSV_TXT_UploadTransactionsAtServer(Address);
	ElsIf ValueIsFilled(Address) And Extension = ".iif" Then
		IIF_UploadTransactionsAtServer(Address);
	EndIf;
	
EndProcedure

&AtServer
Procedure QIF_UploadTransactionsAtServer(TempStorageAddress)
	
	TableOfRules = GetTableOfRules();
	
	BinaryData = GetFromTempStorage(TempStorageAddress);
	TempFileName = GetTempFileName("qif");
	BinaryData.Write(TempFileName);
	
	Try
		SourceText.Read(TempFileName);
	Except
		TextMessage = NStr("en = 'Can not read the file.'");
		CommonUseClientServer.MessageToUser(TextMessage);
		Return;
	EndTry;
	
	LineCountTotal = SourceText.LineCount();
	
	NewTransaction    = True;
	NumberTransaction = 0;
	
	For LineNumber = 1 To LineCountTotal Do
		
		CurrentLine = SourceText.GetLine(LineNumber);
		CurrentLine = TrimAll(CurrentLine);
		
		//begin ^
		If NewTransaction Then	
			NumberTransaction = NumberTransaction + 1;
			NewTransaction    = False;
			NewRow            = New Structure("TransactionDate, Amount, CheckNumber, Description", '00010101', 0, "", "");
		EndIf;
		
		//D
		If Left(CurrentLine, 1) = "D" Then
			DataOfRow = Mid(CurrentLine, 2, StrLen(CurrentLine) - 1);
			
			TransactionDate = '00010101';
			DateParts = StringFunctionsClientServer.SplitStringIntoSubstringArray(DataOfRow, "/");
			If DateParts.Count() = 3 then
				Try
					TransactionDate = Date(CommonUse.CSV_GetYear(DateParts[2]), DateParts[0], DateParts[1]);
				Except
				EndTry;				
			EndIf;
						
			NewRow.TransactionDate = TransactionDate;
		EndIf;
		
		//T
		If Left(CurrentLine, 1) = "T" Then
			DataOfRow = Mid(CurrentLine, 2, StrLen(CurrentLine) - 1);
			
			NewRow.Amount = CommonUse.CSV_GetNumber(DataOfRow);
		EndIf;
		
		//N
		If Left(CurrentLine, 1) = "N" Then
			DataOfRow = Mid(CurrentLine, 2, StrLen(CurrentLine) - 1);
			
			NewRow.CheckNumber = DataOfRow;
		EndIf;
		
		//P
		If Left(CurrentLine, 1) = "P" Then
			DataOfRow = Mid(CurrentLine, 2, StrLen(CurrentLine) - 1);
			
			NewRow.Description = DataOfRow;
		EndIf;
		
		//end ^
		If Left(CurrentLine, 1) = "^" Then
			
			NewTransaction = True;
			
			RecordTransaction(NewRow, NumberTransaction, TableOfRules);
		
		EndIf;
				
	EndDo;
	
	CreateTransactionsAtServer();
	
	CommonUseClientServer.MessageToUser(NStr("en = 'The uploading of bank transactions is complete!'"));
	
EndProcedure

&AtServer
Procedure QBO_QFX_OFX_UploadTransactionsAtServer(TempStorageAddress) 
	
	TableOfRules = GetTableOfRules();
	
	BinaryData = GetFromTempStorage(TempStorageAddress);
	TempFileName = GetTempFileName("ofx");
	BinaryData.Write(TempFileName);
	
	Try
		SourceText.Read(TempFileName);
	Except
		TextMessage = NStr("en = 'Can not read the file.'");
		CommonUseClientServer.MessageToUser(TextMessage);
		Return;
	EndTry;

	LineCountTotal = SourceText.LineCount();
	
	NewSTMTTRN        = False;
	NumberTransaction = 0;
	
	For LineNumber = 1 To LineCountTotal Do
		
		CurrentLine = SourceText.GetLine(LineNumber);
		CurrentLine = TrimAll(CurrentLine);
		
		//<STMTTRN>
		If Not NewSTMTTRN And Find(CurrentLine, "<STMTTRN>") > 0 Then
			NumberTransaction = NumberTransaction + 1;
			NewSTMTTRN        = True;
			NewRow            = New Structure("TransactionDate, Amount, CheckNumber, Description", '00010101', 0, "", "");
		EndIf;
		
		//<DTPOSTED>
		If NewSTMTTRN And Find(CurrentLine, "<DTPOSTED>") > 0 Then
			StartPosition = Find(CurrentLine, "<DTPOSTED>") + 10;
			Year  = Mid(CurrentLine, StartPosition, 4);
			Month = Mid(CurrentLine, StartPosition + 4, 2);
			Day   = Mid(CurrentLine, StartPosition + 4+ 2, 2);
			
			NewRow.TransactionDate = Date(Year, Month, Day);
		EndIf;
		
		//<TRNAMT>
		If NewSTMTTRN And Find(CurrentLine, "<TRNAMT>") > 0 Then
			StartPosition = Find(CurrentLine, "<TRNAMT>") + 8;
			CountOfCharacters = StrLen(CurrentLine) - StartPosition + 1;
			
			NewRow.Amount = Number(Mid(CurrentLine, StartPosition, CountOfCharacters));
		EndIf;
		
		//<CHECKNUM>
		If NewSTMTTRN And Find(CurrentLine, "<CHECKNUM>") > 0 Then
			StartPosition = Find(CurrentLine, "<CHECKNUM>") + 10;
			CountOfCharacters = StrLen(CurrentLine) - StartPosition + 1;
			
			NewRow.CheckNumber = Mid(CurrentLine, StartPosition, CountOfCharacters);
		EndIf;
		
		//<NAME>
		If NewSTMTTRN And Find(CurrentLine, "<NAME>") > 0 Then
			StartPosition = Find(CurrentLine, "<NAME>") + 6;
			CountOfCharacters = StrLen(CurrentLine) - StartPosition + 1;
			
			NewRow.Description = Mid(CurrentLine, StartPosition, CountOfCharacters);
		EndIf;
		
		//</STMTTRN>
		If NewSTMTTRN And Find(CurrentLine, "</STMTTRN>") > 0 Then
			NewSTMTTRN = False;
			
			RecordTransaction(NewRow, NumberTransaction, TableOfRules);
			
		EndIf;
				
	EndDo;
	
	//
	CreateTransactionsAtServer();
	
	CommonUseClientServer.MessageToUser(NStr("en = 'The uploading of bank transactions is complete!'"));
	
EndProcedure

&AtServer
Procedure CSV_TXT_UploadTransactionsAtServer(TempStorageAddress)
	
	TableOfRules = GetTableOfRules();
	
	BinaryData = GetFromTempStorage(TempStorageAddress);
	TempFileName = GetTempFileName("csv");
	BinaryData.Write(TempFileName);
	
	Try
		SourceText.Read(TempFileName);
		CSV_Text = SourceText.GetText();
	Except
		TextMessage = NStr("en = 'Can not read the file.'");
		CommonUseClientServer.MessageToUser(TextMessage);
		Return;
	EndTry;
	
	VT = CommonUse.CSV_GetValueTable(CSV_Text, Object.AccountInBank.CSV_Separator);
	
	//Check settings
	If Not CommonUse.CSV_CheckBankAccountSettings(Object.AccountInBank, VT.Columns.Count()) Then
		Return;
	EndIf;
	
	NumberTransaction = 0;
	
	For Each CurrentLine In VT Do
		
		If VT.IndexOf(CurrentLine) = 0 And Object.AccountInBank.CSV_HasHeaderRow Then
			Continue;
		EndIf;
		
		NumberTransaction = NumberTransaction + 1;
		
		Try
			
			DateRow            = CurrentLine[Object.AccountInBank.CSV_DateColumn - 1];
			If Object.AccountInBank.CSV_CheckNumberColumn > 0 Then
				CheckNumberRow = CurrentLine[Object.AccountInBank.CSV_CheckNumberColumn - 1];
			Else
				CheckNumberRow = "";
			EndIf;
			DescriptionRow     = CurrentLine[Object.AccountInBank.CSV_DescriptionColumn - 1];
			MoneyInRow         = CurrentLine[Object.AccountInBank.CSV_MoneyInColumn - 1];
			MoneyOutRow        = CurrentLine[Object.AccountInBank.CSV_MoneyOutColumn - 1];
			
			MoneyInRow         = CommonUse.CSV_GetNumber(MoneyInRow);
			MoneyOutRow        = CommonUse.CSV_GetNumber(MoneyOutRow);
			
			If MoneyInRow <> 0 Then
				AmountRow      = MoneyInRow * ?(Object.AccountInBank.CSV_MoneyInColumnChangeSymbol, -1, 1);
			Else
				AmountRow      = MoneyOutRow * ?(Object.AccountInBank.CSV_MoneyOutColumnChangeSymbol, -1, 1);
			EndIf;
			
		Except
			
			TextMessage = NStr("en = 'Check format of file or settings CSV!'");
			CommonUseClientServer.MessageToUser(TextMessage);
			
		EndTry;
		
		TransactionDate = '00010101';
		DateParts = StringFunctionsClientServer.SplitStringIntoSubstringArray(DateRow, "/");
		If DateParts.Count() = 3 then
			Try
				TransactionDate = Date(CommonUse.CSV_GetYear(DateParts[2]), DateParts[0], DateParts[1]);
			Except
			EndTry;				
		EndIf;
		
		NewRow = New Structure("TransactionDate, Amount, CheckNumber, Description", '00010101', 0, "", "");
		NewRow.TransactionDate 	= TransactionDate;
		NewRow.CheckNumber 		= CheckNumberRow;
		NewRow.Description 		= DescriptionRow;
		NewRow.Amount 			= AmountRow;
		
		RecordTransaction(NewRow, NumberTransaction, TableOfRules);
		
	EndDo;
	
	//
	CreateTransactionsAtServer();
	
	CommonUseClientServer.MessageToUser(NStr("en = 'The uploading of bank transactions is complete!'"));
	
EndProcedure

&AtServer
Procedure IIF_UploadTransactionsAtServer(TempStorageAddress)
	
	TableOfRules = GetTableOfRules();
	
	BinaryData = GetFromTempStorage(TempStorageAddress);
	TempFileName = GetTempFileName("iif");
	BinaryData.Write(TempFileName);
	
	Try
		SourceText.Read(TempFileName);
	Except
		TextMessage = NStr("en = 'Can not read the file.'");
		CommonUseClientServer.MessageToUser(TextMessage);
		Return;
	EndTry;
	
	LineCountTotal = SourceText.LineCount();
	
	StructureOfTransaction = New Structure("DATE, AMOUNT, DOCNUM, NAME");
	HeaderFound            = False;
	NumberTransaction      = 0;
	
	For LineNumber = 1 To LineCountTotal Do
		
		CurrentLine = SourceText.GetLine(LineNumber);
		
		If Left(CurrentLine, 5) = "!TRNS" Then
			
			HeaderFound = True;
			HeaderParts = StringFunctionsClientServer.SplitStringIntoSubstringArray(CurrentLine, Chars.Tab);
			
			For Each RowParts In HeaderParts Do
				
				If Find("DATE", RowParts) Then
					StructureOfTransaction.Insert("DATE", HeaderParts.Find(RowParts));
				ElsIf Find("AMOUNT", RowParts) Then
					StructureOfTransaction.Insert("AMOUNT", HeaderParts.Find(RowParts));
				ElsIf Find("DOCNUM", RowParts) Then
					StructureOfTransaction.Insert("DOCNUM", HeaderParts.Find(RowParts));
				ElsIf Find("NAME", RowParts) Then
					StructureOfTransaction.Insert("NAME", HeaderParts.Find(RowParts));
				EndIf;
				
			EndDo;
			
		EndIf;
		
		If HeaderFound And Left(CurrentLine, 4) = "TRNS" Then
			
			NumberTransaction  = NumberTransaction + 1;
			NewRow             = New Structure("TransactionDate, Amount, CheckNumber, Description", '00010101', 0, "", "");
			
			//1.
			StructureOfLine  = New Array;
			NumberCharacters = StrLen(CurrentLine);
			UseDoubleQuotes  = False;
			ValueField       = "";
			
			For i = 1 To NumberCharacters Do
				
				CurrentSymbol = Mid(CurrentLine, i, 1);
				
				If CurrentSymbol = Chars.Tab And (Not UseDoubleQuotes) Then
					StructureOfLine.Add(CommonUse.CSV_ChangeValue(ValueField));
					ValueField = "";
				ElsIf CurrentSymbol = """" Then
					UseDoubleQuotes = Not UseDoubleQuotes; 
					ValueField = ValueField + CurrentSymbol;
				Else
					ValueField = ValueField + CurrentSymbol;
				EndIf;
				
				If i = NumberCharacters Then
					StructureOfLine.Add(CommonUse.CSV_ChangeValue(ValueField));
					ValueField = "";
				EndIf;
				
			EndDo;
			
			//2.
			//DATE
			If StructureOfTransaction.DATE <> Undefined Then
				DataOfRow = StructureOfLine[StructureOfTransaction.DATE];	
				
				TransactionDate = '00010101';
				DateParts = StringFunctionsClientServer.SplitStringIntoSubstringArray(DataOfRow, "/");
				If DateParts.Count() = 3 then
					Try
						TransactionDate = Date(CommonUse.CSV_GetYear(DateParts[2]), DateParts[0], DateParts[1]);
					Except
					EndTry;				
				EndIf;
				
				NewRow.TransactionDate = TransactionDate;
			EndIf;
			
			//AMOUNT
			If StructureOfTransaction.AMOUNT <> Undefined Then
				DataOfRow = StructureOfLine[StructureOfTransaction.AMOUNT];
				
				NewRow.Amount = CommonUse.CSV_GetNumber(DataOfRow);
			EndIf;
			
			//DOCNUM
			If StructureOfTransaction.DOCNUM <> Undefined Then
				DataOfRow = StructureOfLine[StructureOfTransaction.DOCNUM];
				
				NewRow.CheckNumber = DataOfRow;
			EndIf;
			
			//NAME
			If StructureOfTransaction.NAME <> Undefined Then
				DataOfRow = StructureOfLine[StructureOfTransaction.NAME];
				
				NewRow.Description = DataOfRow;
			EndIf;
			
			RecordTransaction(NewRow, NumberTransaction, TableOfRules);

		EndIf;
		
	EndDo;
	
	//
	CreateTransactionsAtServer();
	
	CommonUseClientServer.MessageToUser(NStr("en = 'The uploading of bank transactions is complete!'"));
	
EndProcedure

&AtServer
Function GetTableOfRules()
	
	VT = New ValueTable;
	
	Query = New Query;
	Query.Text = "SELECT
	             |	Companies.Ref AS Company,
	             |	Companies.ImportMatch AS Rule
	             |FROM
	             |	Catalog.Companies AS Companies
	             |WHERE
	             |	Companies.ImportMatch <> """"
	             |	AND Companies.DeletionMark = FALSE";
	
	VT = Query.Execute().Unload();
	
	For Each LineVT In VT Do
		LineVT.Rule = StrReplace(LineVT.Rule, "*", "%");
	EndDo;
	
	Return VT;
	
EndFunction

&AtServer
Procedure RecordTransaction(NewRow, NumberTransaction, TableOfRules)
	
	If (Not ValueIsFilled(NewRow.TransactionDate))
		OR (NewRow.TransactionDate < Object.DateStart)
		OR (NewRow.TransactionDate > Object.DateEnd) Then
		
		TextMessage = StringFunctionsClientServer.SubstituteParametersInString(NStr("en = 'The bank transaction #%1 (%2 %3) does not belong to the processing period (%4)!'"), NumberTransaction, NewRow.Description, NewRow.Amount, Format(NewRow.TransactionDate, "DLF=D"));
		CommonUseClientServer.MessageToUser(TextMessage);
		
	ElsIf DataProcessors.DownloadedTransactions.TransactionIsDuplicate(Object.AccountInBank, NewRow.TransactionDate, NewRow.Amount, NewRow.CheckNumber, NewRow.Description, Object.BankTransactions.Unload()) Then
		
		//
		
	Else
		
		//Check ref number
		CheckNumberResult = CommonUseServerCall.CheckNumberAllowed(NewRow.CheckNumber, Undefined, Object.BankAccount);
		If CheckNumberResult.DuplicatesFound Then
			If Not CheckNumberResult.Allow Then
				TextMessage = StringFunctionsClientServer.SubstituteParametersInString(NStr("en = 'The bank transaction # %1 from %2 (%3 %4) does not upload because it''s has duplication check number %5!'"), NumberTransaction, Format(NewRow.TransactionDate, "DLF=D"), NewRow.Description, NewRow.Amount, NewRow.CheckNumber);
				CommonUseClientServer.MessageToUser(TextMessage);
				
				Return;	
			Else
				TextMessage = StringFunctionsClientServer.SubstituteParametersInString(NStr("en = 'The bank transaction # %1 from %2 (%3 %4) has duplication check number %5!'"), NumberTransaction, Format(NewRow.TransactionDate, "DLF=D"), NewRow.Description, NewRow.Amount, NewRow.CheckNumber);
				CommonUseClientServer.MessageToUser(TextMessage);
			EndIf;
		EndIf;
		
		//Add transaction 
		NewTransaction = Object.BankTransactions.Add();
		
		NewTransaction.Period            = NewRow.TransactionDate;
		NewTransaction.RefNumber         = NewRow.CheckNumber;
		NewTransaction.Memo              = NewRow.Description;
		NewTransaction.Company           = GetCompanyByMatch(NewRow.Description, TableOfRules);
		NewTransaction.CompanyCode       = NewTransaction.Company.Code;
		
		If NewTransaction.Company.Vendor And ValueIsFilled(NewTransaction.Company.ExpenseAccount) Then
			NewTransaction.Category      = NewTransaction.Company.ExpenseAccount;
		ElsIf NewTransaction.Company.Customer And ValueIsFilled(NewTransaction.Company.IncomeAccount) Then
			NewTransaction.Category      = NewTransaction.Company.IncomeAccount;
		ElsIf NewRow.Amount > 0 Then
			NewTransaction.Category      = Object.AccountInBank.DefaultDepositAccount;
		Else
			NewTransaction.Category      = Object.AccountInBank.DefaultCheckAccount;
		EndIf;
		
		If NewRow.Amount > 0 Then
			NewTransaction.Deposit       = NewRow.Amount;
			NewTransaction.OperationType = "Deposit";
		Else
			NewTransaction.Payment       = -NewRow.Amount;
			NewTransaction.OperationType = "Payment";
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Function GetCompanyByMatch(SearchString, TableOfRules)
	
	FoundCompany = Catalogs.Companies.EmptyRef();
	
	Query = New Query;
	Query.Text = "SELECT
	             |	RulesTable.Rule AS Rule,
	             |	RulesTable.Company AS Company
	             |INTO RulesTable
	             |FROM
	             |	&TableOfRules AS RulesTable
	             |
	             |INDEX BY
	             |	Rule
	             |;
	             |
	             |////////////////////////////////////////////////////////////////////////////////
	             |SELECT
	             |	RulesTable.Company
	             |FROM
	             |	RulesTable AS RulesTable
	             |WHERE
	             |	&ImportMatch LIKE RulesTable.Rule";
	
	Query.SetParameter("TableOfRules", TableOfRules);
	Query.SetParameter("ImportMatch", SearchString);
	
	SelectionDetailRecords = Query.Execute().Select();
	
	If SelectionDetailRecords.Count() = 1 Then
		
		While SelectionDetailRecords.Next() Do
			FoundCompany = SelectionDetailRecords.Company;
		EndDo;
		
	EndIf;
	
	Return FoundCompany; 
	
EndFunction

#ENDREGION

EditingNewRow = False;
SkippingTableFieldsForChecks = False;