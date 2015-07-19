&AtClient
Var EditingNewRow, Sorting, SkippingTableFieldsForChecks;

#Region EVENTS_HANDLERS

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Object.ShowClassColumn = True;
		
	ApplyConditionalAppearance();
	SetColumnsVisibility(ThisForm, Object.ShowClassColumn);
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	If ValueIsFilled(Object.DateStart) And ValueIsFilled(Object.DateEnd) And ValueIsFilled(Object.BankAccount) Then
		BankAccountOnChangeAtServer();
		FillBankTransactions();
		SetColumnsVisibility(ThisForm, Object.ShowClassColumn);
	EndIf;
	
	EndOfDateEnd = EndOfDay(Object.DateEnd);
	PeriodPresentation = PeriodPresentation(Object.DateStart, EndOfDateEnd);
	
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
	FormParameters = New Structure("DateStart, DateEnd, AccountInBank, BankAccount, ShowClassColumn");
	FillPropertyValues(FormParameters, Object);
	OpenForm("DataProcessor.BankRegister.Form.Settings", FormParameters, ThisForm,,,, Notify, FormWindowOpeningMode.LockOwnerWindow);
				
EndProcedure

&AtClient
Procedure ProcessSettingsChange(Result, Parameters) Export
	
	If TypeOf(Result) = Type("Structure") Then
		FillPropertyValues(Object, Result, "DateStart, DateEnd, AccountInBank, BankAccount, ShowClassColumn");
	Else
		return;
	EndIf;
	
	ProcessSettingsChangeAtServer();
		
EndProcedure

&AtClient
Procedure SortListAsc(Command)
	
	Sorting = True;
	SortListAscAtServer();
	Sorting = False;

EndProcedure

&AtClient
Procedure SortListDesc(Command)
	
	Sorting = True;
	SortListDescAtServer();
	Sorting = False;

EndProcedure

#ENDREGION

#REGION FORM_ITEMS_HANDLERS

&AtClient
Procedure BankAccountOnChange(Item)
	
	BankAccountOnChangeAtServer();
	FillBankTransactions();
	
EndProcedure

&AtClient
Procedure BankTransactionsDepositOnChange(Item)
	
	CurrentData = Items.BankTransactions.CurrentData;
	If CurrentData.Deposit <> 0 Then
		CurrentData.Payment = 0;
		CurrentData.OperationType = "Deposit";
	EndIf;
		
EndProcedure

&AtClient
Procedure BankTransactionsPaymentOnChange(Item)
	
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
	
	If Field = Items.BankTransactionsOperationType Then
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
		Item.CurrentData.Document 				= Undefined;
		Item.CurrentData.OperationType 			= "";
		Item.CurrentData.RefNumber 				= "";
		Item.CurrentData.HasDocument 			= False;
		Item.CurrentData.AmountClosingBalance 	= 0;
		Item.CurrentData.Cleared 				= False;
		Item.CurrentData.Reconciled 			= False;
		Item.CurrentData.TransactionID        	= New UUID("00000000-0000-0000-0000-000000000000");
		If Item.CurrentData.ClassSplit Then
			Item.CurrentData.Class = PredefinedValue("Catalog.Classes.EmptyRef");
			Item.CurrentData.ClassSplit = False;
		EndIf;
		If Item.CurrentData.CompanySplit Then
			Item.CurrentData.Company = PredefinedValue("Catalog.Companies.EmptyRef");
			Item.CurrentData.CompanySplit = False;
		EndIf;
		If Item.CurrentData.CategorySplit Then
			Item.CurrentData.Category = PredefinedValue("ChartOfAccounts.ChartOfAccounts.EmptyRef");
			Item.CurrentData.CategorySplit = False;
		EndIf;
		Item.CurrentData.DocumentSplit = False;
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
	
	If Clone Then
		Cancel = True;
		return;
	EndIf;
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
		If (CustomerAttributes.Vendor = True) And (CustomerAttributes.Customer = False) Then //Checks
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
Procedure BankTransactionsOnActivateRow(Item)
	
	If EditingNewRow = Undefined Then
		EditingNewRow = False;
	EndIf;
	If EditingNewRow Then
		
		If Items.BankTransactions.CurrentData = Undefined Then
			return;
		EndIf;
		
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
Procedure ChoosePeriod(Command)
	
	FormParameters = New Structure("BeginOfPeriod, EndOfPeriod", Object.DateStart, Object.DateEnd);
	OpenForm("CommonForm.ChoiceStandardPeriod", FormParameters, ThisForm, ,,,, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure BalanceStartEditOnChange(Item)
	
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

&AtClient
Function GetLastRow()
	
	If Object.BankTransactions.Count() > 1 Then
		return Object.BankTransactions[Object.BankTransactions.Count()-2];
	Else
		return Undefined;
	EndIf;
	
EndFunction

#ENDREGION

#REGION FORM_SERVER_FUNCTIONS

&AtServer
Procedure BankAccountOnChangeAtServer()
	
	//Find the corresponding account in bank
	Object.AccountInBank = Catalogs.BankAccounts.EmptyRef();
	Request = New Query("SELECT
	                    |	BankAccounts.Ref
	                    |FROM
	                    |	Catalog.BankAccounts AS BankAccounts
	                    |WHERE
	                    |	BankAccounts.AccountingAccount = &AccountingAccount");
	Request.SetParameter("AccountingAccount", Object.BankAccount);
	Res = Request.Execute();
	If Not Res.IsEmpty() Then
		Sel = Res.Select();
		Sel.Next();
		Object.AccountInBank = Sel.Ref;
	Else //Bank account not found. Need to create the new one
		BeginTransaction(DataLockControlMode.Managed);
		Block = New DataLock();
		LockItem = Block.Add("Catalog.BankAccounts");
		LockItem.Mode = DataLockMode.Exclusive;
		Block.Lock();
		Request = New Query("SELECT
		                    |	BankAccounts.Ref
		                    |FROM
		                    |	Catalog.BankAccounts AS BankAccounts
		                    |WHERE
		                    |	BankAccounts.AccountingAccount = &AccountingAccount");
		Request.SetParameter("AccountingAccount", Object.BankAccount);
		Res = Request.Execute();
		If Res.IsEmpty() Then
			Bank = Catalogs.Banks.EmptyRef();
			//Select Offline bank
			//Try to find the Offline bank, if not found then create the new one
			Request = New Query("SELECT
			                    |	Banks.Ref
			                    |FROM
			                    |	Catalog.Banks AS Banks
			                    |WHERE
			                    |	Banks.Code = ""000000000""");
			Res = Request.Execute();
			If Res.IsEmpty() Then
				SetPrivilegedMode(True);
				OfflineBank = Catalogs.Banks.CreateItem();
				OfflineBank.Code 		= "000000000";
				OfflineBank.Description = "Offline bank";
				OfflineBank.Write();
				SetPrivilegedMode(False);
				Bank = OfflineBank.Ref;
			Else
				Sel = Res.Select();
				Sel.Next();
				Bank = Sel.Ref;
			EndIf;
			NewAccount = Catalogs.BankAccounts.CreateItem();
			NewAccount.Owner = Bank;
			NewAccount.Description = Object.BankAccount.Description;
			NewAccount.AccountingAccount = Object.BankAccount;
			NewAccount.Write();
			Object.AccountInBank = NewAccount.Ref;
		Else
			Sel = Res.Select();
			Sel.Next();
			Object.AccountInBank = Sel.Ref;
		EndIf;	
		CommitTransaction();
	EndIf;
		
EndProcedure

&AtServer
Procedure FillBankTransactions(RecordersList = Undefined)
	
		Request = New Query();
		Request.Text = "SELECT ALLOWED
		               |	GeneralJournalBalanceAndTurnovers.Recorder AS Recorder,
		               |	GeneralJournalBalanceAndTurnovers.Period AS Period,
		               |	GeneralJournalBalanceAndTurnovers.AmountRCClosingBalance,
		               |	GeneralJournalBalanceAndTurnovers.Recorder.PointInTime AS RecorderPointInTime,
		               |	GeneralJournalBalanceAndTurnovers.AmountRCOpeningBalance,
		               |	COUNT(DISTINCT GeneralJournalTurnovers.Account) AS GLAccountCount,
		               |	MAX(GeneralJournalTurnovers.Account) AS GLAccount,
		               |	GeneralJournalBalanceAndTurnovers.AmountRCTurnoverDr AS Debit,
		               |	GeneralJournalBalanceAndTurnovers.AmountRCTurnoverCr AS Credit
		               |INTO Recorders
		               |FROM
		               |	AccountingRegister.GeneralJournal.BalanceAndTurnovers(&DateStart, &DateEnd, Recorder, , Account = &Account, , ) AS GeneralJournalBalanceAndTurnovers
		               |		FULL JOIN AccountingRegister.GeneralJournal.Turnovers(&DateStart, &DateEnd, Recorder, Account <> &Account, , ) AS GeneralJournalTurnovers
		               |		ON GeneralJournalBalanceAndTurnovers.Recorder = GeneralJournalTurnovers.Recorder
		               |			AND (GeneralJournalBalanceAndTurnovers.AmountRCTurnover = GeneralJournalTurnovers.AmountRCTurnover
		               |				OR GeneralJournalBalanceAndTurnovers.AmountRCTurnover = -1 * GeneralJournalTurnovers.AmountRCTurnover)
		               |WHERE
		               |	CASE
		               |			WHEN &RecordersListIsSet = TRUE
		               |				THEN GeneralJournalBalanceAndTurnovers.Recorder IN (&RecordersList)
		               |			ELSE TRUE
		               |		END
		               |
		               |GROUP BY
		               |	GeneralJournalBalanceAndTurnovers.Recorder,
		               |	GeneralJournalBalanceAndTurnovers.Period,
		               |	GeneralJournalBalanceAndTurnovers.AmountRCClosingBalance,
		               |	GeneralJournalBalanceAndTurnovers.Recorder.PointInTime,
		               |	GeneralJournalBalanceAndTurnovers.AmountRCOpeningBalance,
		               |	GeneralJournalBalanceAndTurnovers.AmountRCTurnoverDr,
		               |	GeneralJournalBalanceAndTurnovers.AmountRCTurnoverCr
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
		               |	Recorders.AmountRCOpeningBalance,
		               |	Recorders.AmountRCClosingBalance,
		               |	Recorders.RecorderPointInTime,
		               |	COUNT(DISTINCT ClassData.Class) AS ClassesCount,
		               |	COUNT(DISTINCT ProjectData.Project) AS ProjectsCount,
		               |	MAX(CashFlowData.Company) AS Company,
		               |	COUNT(DISTINCT CashFlowData.Company) AS CompanyCount,
		               |	Recorders.GLAccountCount,
		               |	Recorders.GLAccount,
		               |	Recorders.Debit,
		               |	Recorders.Credit
		               |INTO RecordersWithClassesAndProjects
		               |FROM
		               |	Recorders AS Recorders
		               |		LEFT JOIN AccumulationRegister.ClassData AS ClassData
		               |		ON Recorders.Recorder = ClassData.Recorder
		               |		LEFT JOIN AccumulationRegister.ProjectData AS ProjectData
		               |		ON Recorders.Recorder = ProjectData.Recorder
		               |		LEFT JOIN AccumulationRegister.CashFlowData AS CashFlowData
		               |		ON Recorders.Recorder = CashFlowData.Recorder
		               |WHERE
		               |	NOT Recorders.Recorder IS NULL 
		               |	AND Recorders.Recorder <> UNDEFINED
		               |
		               |GROUP BY
		               |	Recorders.Recorder,
		               |	Recorders.Period,
		               |	Recorders.AmountRCClosingBalance,
		               |	Recorders.RecorderPointInTime,
		               |	Recorders.GLAccountCount,
		               |	Recorders.GLAccount,
		               |	Recorders.Debit,
		               |	Recorders.Credit,
		               |	Recorders.AmountRCOpeningBalance
		               |
		               |INDEX BY
		               |	Recorder
		               |;
		               |
		               |////////////////////////////////////////////////////////////////////////////////
		               |SELECT ALLOWED
		               |	RecordersWithClassesAndProjects.Recorder AS Document,
		               |	VALUETYPE(RecordersWithClassesAndProjects.Recorder) AS OperationType,
		               |	RecordersWithClassesAndProjects.Period AS Period,
		               |	RecordersWithClassesAndProjects.Company AS Company,
		               |	RecordersWithClassesAndProjects.Debit AS Deposit,
		               |	RecordersWithClassesAndProjects.Credit AS Payment,
		               |	RecordersWithClassesAndProjects.GLAccount AS Category,
		               |	RecordersWithClassesAndProjects.Recorder.Memo AS Memo,
		               |	RecordersWithClassesAndProjects.Class AS Class,
		               |	RecordersWithClassesAndProjects.Project AS Field2,
		               |	TRUE AS HasDocument,
		               |	BankTransactions.ID AS TransactionID,
		               |	CASE
		               |		WHEN ISNULL(BankReconciliationBalance.AmountBalance, 0) = 0
		               |			THEN TRUE
		               |		ELSE FALSE
		               |	END AS Reconciled,
		               |	CASE
		               |		WHEN ISNULL(BankReconciliationBalance.AmountBalance, 0) = 0
		               |			THEN ""R""
		               |		WHEN ISNULL(BankTransactions.Accepted, FALSE)
		               |			THEN ""C""
		               |		ELSE """"
		               |	END AS TransactionStatus,
		               |	RecordersWithClassesAndProjects.AmountRCOpeningBalance AS AmountOpeningBalance,
		               |	RecordersWithClassesAndProjects.AmountRCClosingBalance AS AmountClosingBalance,
		               |	RecordersWithClassesAndProjects.RecorderPointInTime,
		               |	RecordersWithClassesAndProjects.Recorder.Number AS RefNumber,
		               |	RecordersWithClassesAndProjects.Company.Code AS CompanyCode,
		               |	CASE
		               |		WHEN RecordersWithClassesAndProjects.ClassesCount > 1
		               |			THEN TRUE
		               |		ELSE FALSE
		               |	END AS ClassSplit,
		               |	CASE
		               |		WHEN RecordersWithClassesAndProjects.GLAccountCount <> 1
		               |			THEN TRUE
		               |		ELSE FALSE
		               |	END AS CategorySplit,
		               |	CASE
		               |		WHEN RecordersWithClassesAndProjects.CompanyCount > 1
		               |			THEN TRUE
		               |		ELSE FALSE
		               |	END AS CompanySplit,
		               |	CASE
		               |		WHEN RecordersWithClassesAndProjects.ClassesCount > 1
		               |				OR RecordersWithClassesAndProjects.GLAccountCount <> 1
		               |				OR RecordersWithClassesAndProjects.CompanyCount > 1
		               |			THEN TRUE
		               |		ELSE FALSE
		               |	END AS DocumentSplit
		               |FROM
		               |	RecordersWithClassesAndProjects AS RecordersWithClassesAndProjects
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
		               |	Recorders.Recorder = UNDEFINED
		               |
		               |ORDER BY
		               |	Recorders.Period";
								
	Request.SetParameter("Account", Object.BankAccount);
	Request.SetParameter("AccountInBank", Object.AccountInBank);
	Request.SetParameter("DateStart", New Boundary(Object.DateStart, BoundaryType.Including));
	Request.SetParameter("DateEnd", New Boundary(EndOfDay(Object.DateEnd), BoundaryType.Including));
	Request.SetParameter("RecordersList", RecordersList); 
	Request.SetParameter("RecordersListIsSet", ?(RecordersList = Undefined, False, True));
	If RecordersList = Undefined Then
		BatchResult			= Request.ExecuteBatch();
		BankTransactions 	= BatchResult[2].Unload();
		BalanceStartTable	= BatchResult[3].Unload();
				
		Object.BankTransactions.Load(BankTransactions);
				
		If BankTransactions.Count() > 0 Then
			Object.BalanceStart = BankTransactions[0].AmountOpeningBalance;
		ElsIf BalanceStartTable.Count() > 0 Then
			Object.BalanceStart = BalanceStartTable[0].AmountOpeningBalance;
		Else
			Object.BalanceStart = 0;
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
		
		//Fill the latest date for the document to keep the current order
		LastDate = Tran.Period;
		If Not ValueIsFilled(Tran.Document) Then
			BegOfPeriod = BegOfDay(Tran.Period);
			EndOfPeriod = EndOfDay(Tran.Period);
			For Each TranItem In CurrentTransactions Do
				If TranItem.Period >= BegOfPeriod And TranItem.Period <= EndOfPeriod And TranItem.Period > LastDate Then
					LastDate = TranItem.Period;
				EndIf;
			EndDo;
			If LastDate < EndOfPeriod Then
				LastDate = LastDate + 1;
			EndIf;
			Tran.Period = LastDate;
		EndIf;
		
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
		If ValueIsFilled(Tran.TransactionStatus) Then //If Cleared
			
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
			
		ElsIf ValueIsFilled(Tran.TransactionID) Then // if a user cleared status then remove bank transaction
			
			BTRecordset.Clear();
			BTRecordSet.Filter.Reset();
			BTRecordset.Filter.ID.Set(Tran.TransactionID);
			BTRecordset.Write(True);
			
		EndIf;
		
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
	If ValueIsFilled(Tran.RefNumber) Then
		NewDeposit.Number = Tran.RefNumber;
	EndIf;
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
	
	//For reconciled documents only readonly access
	ElementCA = CA.Items.Add(); 
	
	AddDataCompositionFields(ElementCA, Items.BankTransactions.ChildItems);
	
	FilterElement = ElementCA.Filter.Items.Add(Type("DataCompositionFilterItem")); // current row filter 
	FilterElement.LeftValue 		= New DataCompositionField("Object.BankTransactions.Reconciled"); 
	FilterElement.ComparisonType 	= DataCompositionComparisonType.Equal; 
	FilterElement.RightValue 		= True; 
	FilterElement.Use				= True;
	
	ElementCA.Appearance.SetParameterValue("Readonly", True); 
	
	//For reconciled documents display "R" in status column
	ElementCA = CA.Items.Add(); 
	
	FieldAppearance = ElementCA.Fields.Items.Add(); 
	FieldAppearance.Field = New DataCompositionField("BankTransactionsTransactionStatus"); 
 	FieldAppearance.Use = True; 
	
	FilterElement = ElementCA.Filter.Items.Add(Type("DataCompositionFilterItem")); // current row filter 
	FilterElement.LeftValue 		= New DataCompositionField("Object.BankTransactions.Reconciled"); 
	FilterElement.ComparisonType 	= DataCompositionComparisonType.Equal; 
	FilterElement.RightValue 		= True; 
	FilterElement.Use				= True;
	
	DefaultFont = ElementCA.Appearance.FindParameterValue(New DataCompositionParameter("Font")).Value;
	BoldFont	= New Font(DefaultFont,,,True,,,); //Bold font
	ElementCA.Appearance.SetParameterValue("Font", BoldFont); 
	ElementCA.Appearance.SetParameterValue("Text", "R"); 
	
	//If several companies in one document display -SPLIT-
	ElementCA = CA.Items.Add(); 
	
	FieldAppearance = ElementCA.Fields.Items.Add(); 
	FieldAppearance.Field = New DataCompositionField("BankTransactionsCompany"); 
 	FieldAppearance.Use = True; 
	
	FilterElement = ElementCA.Filter.Items.Add(Type("DataCompositionFilterItem")); // current row filter 
	FilterElement.LeftValue 		= New DataCompositionField("Object.BankTransactions.CompanySplit"); 
	FilterElement.ComparisonType 	= DataCompositionComparisonType.Equal; 
	FilterElement.RightValue 		= True; 
	FilterElement.Use				= True;
	
	DefaultFont = ElementCA.Appearance.FindParameterValue(New DataCompositionParameter("Font")).Value;
	BoldFont	= New Font(DefaultFont,,,True,,,); //Bold font
	ElementCA.Appearance.SetParameterValue("Font", BoldFont); 
	ElementCA.Appearance.SetParameterValue("Text", "-Split-"); 
	
	//If several G/L accounts in one document display -SPLIT-
	ElementCA = CA.Items.Add(); 
	
	FieldAppearance = ElementCA.Fields.Items.Add(); 
	FieldAppearance.Field = New DataCompositionField("BankTransactionsCategory"); 
 	FieldAppearance.Use = True; 
	
	FilterElement = ElementCA.Filter.Items.Add(Type("DataCompositionFilterItem")); // current row filter 
	FilterElement.LeftValue 		= New DataCompositionField("Object.BankTransactions.CategorySplit"); 
	FilterElement.ComparisonType 	= DataCompositionComparisonType.Equal; 
	FilterElement.RightValue 		= True; 
	FilterElement.Use				= True;
	
	DefaultFont = ElementCA.Appearance.FindParameterValue(New DataCompositionParameter("Font")).Value;
	BoldFont	= New Font(DefaultFont,,,True,,,); //Bold font
	ElementCA.Appearance.SetParameterValue("Font", BoldFont); 
	ElementCA.Appearance.SetParameterValue("Text", "-Split-"); 
	ElementCA.Appearance.SetParameterValue("MarkIncomplete", False); 
	
	//If several Classes in one document display -SPLIT-
	ElementCA = CA.Items.Add(); 
	
	FieldAppearance = ElementCA.Fields.Items.Add(); 
	FieldAppearance.Field = New DataCompositionField("BankTransactionsClass"); 
 	FieldAppearance.Use = True; 
	
	FilterElement = ElementCA.Filter.Items.Add(Type("DataCompositionFilterItem")); // current row filter 
	FilterElement.LeftValue 		= New DataCompositionField("Object.BankTransactions.ClassSplit"); 
	FilterElement.ComparisonType 	= DataCompositionComparisonType.Equal; 
	FilterElement.RightValue 		= True; 
	FilterElement.Use				= True;
	
	DefaultFont = ElementCA.Appearance.FindParameterValue(New DataCompositionParameter("Font")).Value;
	BoldFont	= New Font(DefaultFont,,,True,,,); //Bold font
	ElementCA.Appearance.SetParameterValue("Font", BoldFont); 
	ElementCA.Appearance.SetParameterValue("Text", "-Split-"); 
	
	//For reconciled documents only readonly access
	ElementCA = CA.Items.Add(); 
	
	AddDataCompositionFields(ElementCA, Items.BankTransactions.ChildItems);
	
	FilterElement = ElementCA.Filter.Items.Add(Type("DataCompositionFilterItem")); // current row filter 
	FilterElement.LeftValue 		= New DataCompositionField("Object.BankTransactions.DocumentSplit"); 
	FilterElement.ComparisonType 	= DataCompositionComparisonType.Equal; 
	FilterElement.RightValue 		= True; 
	FilterElement.Use				= True;
	
	ElementCA.Appearance.SetParameterValue("Readonly", True); 
	
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
		
		FilterElement = ElementCA.Filter.Items.Add(Type("DataCompositionFilterItem")); // current row filter 
		FilterElement.LeftValue 		= New DataCompositionField("Object.BankTransactions.CompanySplit"); 
		FilterElement.ComparisonType 	= DataCompositionComparisonType.Equal; 
		FilterElement.RightValue 		= False; 
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
Procedure SetColumnsVisibility(ThisForm, ShowClassColumn)
	
	Items 	= ThisForm.Items;
	Items.BankTransactionsClass.Visible 	= ShowClassColumn;
	
EndProcedure

&AtServer
Procedure ProcessSettingsChangeAtServer()
	
	SetColumnsVisibility(ThisForm, Object.ShowClassColumn);
	
	EndOfDateEnd = EndOfDay(Object.DateEnd);
	PeriodPresentation = PeriodPresentation(Object.DateStart, EndOfDateEnd);
	
	FillBankTransactions();
	
EndProcedure

&AtServer
Procedure SortListAscAtServer()
	
	If (Items.BankTransactions.CurrentItem.Name = "BankTransactionsPeriod") Then
		Object.BankTransactions.Sort("Period Asc, Sequence Asc");
	Else
		Object.BankTransactions.Sort(StrReplace(Items.BankTransactions.CurrentItem.Name, "BankTransactions", "") + " ASC");
	EndIf;

	For Each Item In Items.BankTransactionsGroup.ChildItems Do
		Item.Title = StrReplace(Item.Title, "↑ ", "");
		Item.Title = StrReplace(Item.Title, "↓ ", "");
	EndDo;
	Items.BankTransactions.CurrentItem.Title = "↑ " + Items.BankTransactions.CurrentItem.Title;

EndProcedure

&AtServer
Procedure SortListDescAtServer()
	
	If (Items.BankTransactions.CurrentItem.Name = "BankTransactionsPeriod") Then
		Object.BankTransactions.Sort("Period Desc, Sequence Desc");
	Else
		Object.BankTransactions.Sort(StrReplace(Items.BankTransactions.CurrentItem.Name, "BankTransactions", "") + " DESC");
	EndIf;
	For Each Item In Items.BankTransactionsGroup.ChildItems Do
		Item.Title = StrReplace(Item.Title, "↑ ", "");
		Item.Title = StrReplace(Item.Title, "↓ ", "");
	EndDo;
	Items.BankTransactions.CurrentItem.Title = "↓ " + Items.BankTransactions.CurrentItem.Title;
	
EndProcedure

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
			DescriptionVT     = New ValueTable;
			DescriptionVT.Columns.Add("Description", New TypeDescription("String"));
			DescriptionVT.Columns.Add("Order", New TypeDescription("String"));
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
			PreDescription = "";
			PreDescription = Mid(CurrentLine, 2, StrLen(CurrentLine) - 1);
			
			NewRowDescriptionVT = DescriptionVT.Add();
			NewRowDescriptionVT.Description = PreDescription; 
			NewRowDescriptionVT.Order       = "A" + LeadingZeros(LineNumber, 6);
		EndIf;
		
		//M
		If Left(CurrentLine, 1) = "M" Then
			PreDescription = "";
			PreDescription = Mid(CurrentLine, 2, StrLen(CurrentLine) - 1);
			
			NewRowDescriptionVT = DescriptionVT.Add();
			NewRowDescriptionVT.Description = PreDescription; 
			NewRowDescriptionVT.Order       = "Z" + LeadingZeros(LineNumber, 6);
		EndIf;
		
		//end ^
		If Left(CurrentLine, 1) = "^" Then
			//MEMO
			CheckArray          = New Array;
			PreviousDescription = "";
			DescriptionVT.Sort("Order");
			For Each CurrentDescriptionVT In DescriptionVT Do
				
				If CheckArray.Find(CurrentDescriptionVT.Description) = Undefined Then
					CheckArray.Add(CurrentDescriptionVT.Description);	
					
					NewRow.Description = ?(NewRow.Description = "", CurrentDescriptionVT.Description, NewRow.Description + " " + CurrentDescriptionVT.Description); 	
				EndIf; 
				
			EndDo;
			
			//
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
	
	//--//
	TemproraryText     = SourceText.GetText();
	TemproraryText     = StrReplace(TemproraryText, "</STMTTRN>",       Chars.CR + "</STMTTRN>");
	TemproraryText     = StrReplace(TemproraryText, "<BANKACCTTO>",     Chars.CR + "<BANKACCTTO>");
	TemproraryText     = StrReplace(TemproraryText, "<CCACCTTO>",       Chars.CR + "<CCACCTTO>");
	TemproraryText     = StrReplace(TemproraryText, "<CHECKNUM>",       Chars.CR + "<CHECKNUM>");
	TemproraryText     = StrReplace(TemproraryText, "<CORRECTACTION>",  Chars.CR + "<CORRECTACTION>");
	TemproraryText     = StrReplace(TemproraryText, "<CORRECTFITID>",   Chars.CR + "<CORRECTFITID>");
	TemproraryText     = StrReplace(TemproraryText, "<CURRENCY>",       Chars.CR + "<CURRENCY>");
	TemproraryText     = StrReplace(TemproraryText, "<DTAVAIL>",        Chars.CR + "<DTAVAIL>");
	TemproraryText     = StrReplace(TemproraryText, "<DTPOSTED>",       Chars.CR + "<DTPOSTED>");
	TemproraryText     = StrReplace(TemproraryText, "<DTUSER>",         Chars.CR + "<DTUSER>");
	TemproraryText     = StrReplace(TemproraryText, "<EXTDNAME>",       Chars.CR + "<EXTDNAME>");
	TemproraryText     = StrReplace(TemproraryText, "<FITID>",          Chars.CR + "<FITID>");
	TemproraryText     = StrReplace(TemproraryText, "<IMAGEDATA>",      Chars.CR + "<IMAGEDATA>");
	TemproraryText     = StrReplace(TemproraryText, "<INV401KSOURCE>",  Chars.CR + "<INV401KSOURCE>");
	TemproraryText     = StrReplace(TemproraryText, "<MEMO>",           Chars.CR + "<MEMO>");
	TemproraryText     = StrReplace(TemproraryText, "<MVNT.PAYEE>",     Chars.CR + "<MVNT.PAYEE>");
	TemproraryText     = StrReplace(TemproraryText, "<NAME>",           Chars.CR + "<NAME>");
	TemproraryText     = StrReplace(TemproraryText, "<ORIGCURRENCY>",   Chars.CR + "<ORIGCURRENCY>");
	TemproraryText     = StrReplace(TemproraryText, "<PAYEE>",          Chars.CR + "<PAYEE>");
	TemproraryText     = StrReplace(TemproraryText, "<PAYEEID>",        Chars.CR + "<PAYEEID>");
	TemproraryText     = StrReplace(TemproraryText, "<REFNUM>",         Chars.CR + "<REFNUM>");
	TemproraryText     = StrReplace(TemproraryText, "<SIC>",            Chars.CR + "<SIC>");
	TemproraryText     = StrReplace(TemproraryText, "<SRVRTID>",        Chars.CR + "<SRVRTID>");
	TemproraryText     = StrReplace(TemproraryText, "<STMTTRN>",        Chars.CR + "<STMTTRN>");
	TemproraryText     = StrReplace(TemproraryText, "<TRNAMT>",         Chars.CR + "<TRNAMT>");
	TemproraryText     = StrReplace(TemproraryText, "<TRNTYPE>",        Chars.CR + "<TRNTYPE>");
	SourceText.SetText(TemproraryText); 
	//--//

	LineCountTotal    = SourceText.LineCount();
	
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
			CurrentLine   = StrReplace(CurrentLine, "</DTPOSTED>", "");
			StartPosition = Find(CurrentLine, "<DTPOSTED>") + 10;
			Year  = Mid(CurrentLine, StartPosition, 4);
			Month = Mid(CurrentLine, StartPosition + 4, 2);
			Day   = Mid(CurrentLine, StartPosition + 4+ 2, 2);
			
			NewRow.TransactionDate = Date(Year, Month, Day);
		EndIf;
		
		//<TRNAMT>
		If NewSTMTTRN And Find(CurrentLine, "<TRNAMT>") > 0 Then
			CurrentLine   = StrReplace(CurrentLine, "</TRNAMT>", "");
			StartPosition = Find(CurrentLine, "<TRNAMT>") + 8;
			CountOfCharacters = StrLen(CurrentLine) - StartPosition + 1;
			
			NewRow.Amount = Number(Mid(CurrentLine, StartPosition, CountOfCharacters));
		EndIf;
		
		//<CHECKNUM>
		If NewSTMTTRN And Find(CurrentLine, "<CHECKNUM>") > 0 Then
			CurrentLine   = StrReplace(CurrentLine, "</CHECKNUM>", "");
			StartPosition = Find(CurrentLine, "<CHECKNUM>") + 10;
			CountOfCharacters = StrLen(CurrentLine) - StartPosition + 1;
			
			NewRow.CheckNumber = Mid(CurrentLine, StartPosition, CountOfCharacters);
		EndIf;
		
		//<NAME>
		If NewSTMTTRN And Find(CurrentLine, "<NAME>") > 0 Then
			CurrentLine   = StrReplace(CurrentLine, "</NAME>", "");
			StartPosition = Find(CurrentLine, "<NAME>") + 6;
			CountOfCharacters = StrLen(CurrentLine) - StartPosition + 1;
			
			PreDescription = "";
			PreDescription = Mid(CurrentLine, StartPosition, CountOfCharacters);
			If NewRow.Description = "" Then
				NewRow.Description = PreDescription;
			ElsIf NewRow.Description <> PreDescription Then
				NewRow.Description = NewRow.Description + " " + PreDescription;
			EndIf;
		EndIf;
		
		//<MEMO>
		If NewSTMTTRN And Find(CurrentLine, "<MEMO>") > 0 Then
			CurrentLine   = StrReplace(CurrentLine, "</MEMO>", "");
			StartPosition = Find(CurrentLine, "<MEMO>") + 6;
			CountOfCharacters = StrLen(CurrentLine) - StartPosition + 1;
			
			PreDescription = "";
			PreDescription = Mid(CurrentLine, StartPosition, CountOfCharacters);
			If NewRow.Description = "" Then
				NewRow.Description = PreDescription;
			ElsIf NewRow.Description <> PreDescription Then
				NewRow.Description = NewRow.Description + " " + PreDescription;
			EndIf;
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
	
	StructureOfTransaction = New Structure("DATE, AMOUNT, DOCNUM, NAME, MEMO");
	HeaderFound            = False;
	NumberTransaction      = 0;
	
	For LineNumber = 1 To LineCountTotal Do
		
		CurrentLine = SourceText.GetLine(LineNumber);
		
		If Left(CurrentLine, 5) = "!TRNS" Then
			
			HeaderFound = True;
			HeaderParts = StringFunctionsClientServer.SplitStringIntoSubstringArray(CurrentLine, Chars.Tab);
			
			For Each RowParts In HeaderParts Do
				
				If Find("DATE", RowParts) Then
					StructureOfTransaction.Insert("DATE",   HeaderParts.Find(RowParts));
				ElsIf Find("AMOUNT", RowParts) Then
					StructureOfTransaction.Insert("AMOUNT", HeaderParts.Find(RowParts));
				ElsIf Find("DOCNUM", RowParts) Then
					StructureOfTransaction.Insert("DOCNUM", HeaderParts.Find(RowParts));
				ElsIf Find("NAME", RowParts) Then
					StructureOfTransaction.Insert("NAME",   HeaderParts.Find(RowParts));
				ElsIf Find("MEMO", RowParts) Then
					StructureOfTransaction.Insert("MEMO",   HeaderParts.Find(RowParts));
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
				
				PreDescription = "";
				PreDescription = DataOfRow;
				If NewRow.Description = "" Then
					NewRow.Description = PreDescription;
				ElsIf NewRow.Description <> PreDescription Then
					NewRow.Description = NewRow.Description + " " + PreDescription;
				EndIf;
			EndIf;
			
			//MEMO
			If StructureOfTransaction.MEMO <> Undefined Then
				DataOfRow = StructureOfLine[StructureOfTransaction.MEMO];
				
				PreDescription = "";
				PreDescription = DataOfRow;
				If NewRow.Description = "" Then
					NewRow.Description = PreDescription;
				ElsIf NewRow.Description <> PreDescription Then
					NewRow.Description = NewRow.Description + " " + PreDescription;
				EndIf;
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
				TextMessage = StringFunctionsClientServer.SubstituteParametersInString(NStr("en = 'Check #%1 was not uploaded as that check number already exists in the system.  Enable duplicate check numbers in Settings --> Features.'"), NewRow.CheckNumber);
				CommonUseClientServer.MessageToUser(TextMessage);
				
				Return;	
			Else
				TextMessage = StringFunctionsClientServer.SubstituteParametersInString(NStr("en = 'Check #%1 was uploaded, but another transaction has the same check number.  Please check to ensure it is not a duplicate transaction.'"), NewRow.CheckNumber);
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

&AtClient
Procedure BankAccountStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	ChoiceData = new ValueList();
	ChoiceData.LoadValues(FillBankAccountChoiceListAtServer());
	
EndProcedure

&AtServerNoContext
Function FillBankAccountChoiceListAtServer()
	
	Request = New Query("SELECT
	                    |	ChartOfAccounts.Ref
	                    |FROM
	                    |	ChartOfAccounts.ChartOfAccounts AS ChartOfAccounts
	                    |WHERE
	                    |	(ChartOfAccounts.AccountType = VALUE(Enum.AccountTypes.Bank)
	                    |			OR ChartOfAccounts.AccountType = VALUE(Enum.AccountTypes.OtherCurrentLiability)
	                    |				AND ChartOfAccounts.CreditCard = TRUE)");
	ResTable = Request.Execute().Unload();
	return ResTable.UnloadColumn("Ref");
	
EndFunction

&AtClient
Procedure Reconcile(Command)
	
	If Not (ValueIsFilled(Object.DateStart) And ValueIsFilled(Object.DateEnd)) Then
		ShowMessageBox(, "Please, choose the Period first!",, "Bank Register");
		return;
	EndIf;
	
	BankReconciliation = GetBankReconciliation(Object.BankAccount, Object.DateStart, Object.DateEnd);
	Notify = New NotifyDescription("UpdateRegister", ThisObject);
	If ValueIsFilled(BankReconciliation) Then
		OpenForm("Document.BankReconciliation.ObjectForm", New Structure("Key", BankReconciliation),,,,, Notify);
	Else
		OpenForm("Document.BankReconciliation.ObjectForm", New Structure("BankAccount, StatementDate", Object.BankAccount, Object.DateEnd),,,,, Notify);
	EndIf;
	
EndProcedure

&AtServerNoContext
Function GetBankReconciliation(BankAccount, DateStart, DateEnd)
	
	Request = New Query("SELECT
	                    |	BankReconciliation.Ref
	                    |FROM
	                    |	(SELECT
	                    |		MAX(BankReconciliation.Date) AS Date,
	                    |		BankReconciliation.BankAccount AS BankAccount
	                    |	FROM
	                    |		Document.BankReconciliation AS BankReconciliation
	                    |	WHERE
	                    |		BankReconciliation.BankAccount = &BankAccount
	                    |		AND BankReconciliation.Date >= &DateStart
	                    |		AND BankReconciliation.Date <= &DateEnd
	                    |		AND BankReconciliation.DeletionMark = FALSE
	                    |	
	                    |	GROUP BY
	                    |		BankReconciliation.BankAccount) AS LastReconciliation
	                    |		INNER JOIN Document.BankReconciliation AS BankReconciliation
	                    |		ON LastReconciliation.BankAccount = BankReconciliation.BankAccount
	                    |			AND LastReconciliation.Date = BankReconciliation.Date
	                    |WHERE
	                    |	BankReconciliation.DeletionMark = FALSE");
	Request.SetParameter("BankAccount", BankAccount);
	Request.SetParameter("DateStart", BegOfDay(DateStart));
	Request.SetParameter("DateEnd", EndOfDay(DateEnd));
	Res = Request.Execute();
	If Not Res.IsEmpty() Then
		Sel = Res.Select();
		Sel.Next();
		return Sel.Ref;
	Else
		return Documents.BankReconciliation.EmptyRef();
	EndIf;
	
EndFunction

&AtClient
Procedure UpdateRegister(ClosureResult, AdditionalParameters) Export
	
	FillBankTransactions();
	
EndProcedure

Function LeadingZeros(Number, NumberOfZeros)

	StringNumber = String(Number);
	ZerosNeeded = NumberOfZeros - StrLen(StringNumber);
	NumberWithZeros = "";
	For i = 1 to ZerosNeeded Do
		NumberWithZeros = NumberWithZeros + "0";
	EndDo;
	
	Return NumberWithZeros + StringNumber;
	
EndFunction

#ENDREGION

EditingNewRow = False;
SkippingTableFieldsForChecks = False;