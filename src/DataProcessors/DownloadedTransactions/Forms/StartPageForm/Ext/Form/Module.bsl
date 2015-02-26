&AtClient
Var FormActivated;

#Region EVENTS_HANDLERS

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	//CurUser = InfoBaseUsers.FindByName(SessionParameters.ACSUser);
	//If CurUser.Roles.Contains(Metadata.Roles.BankAccounting) = True Then
	//	Items.CFOToday.Visible = True;
	//	Items.Navigation.Visible = False;
	//Else
	//	Items.CFOToday.Visible = False;
	//	Items.Navigation.Visible = True;
	//EndIf;
	
	CurrentBankAccountDescription = "Cloud banking";
	Diagram.ChartType = ChartType.Column;
	If Day(CurrentSessionDate()) < 5 Then
		DiagramMonthsCount = 4;
	Else
		DiagramMonthsCount = 3;
	EndIf;
	FillAvailableAccounts();	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	AttachIdleHandler("UpdateAvailableAccounts", 60, False);
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	If EventName = "DeletedBankAccount" Then //Deleted online bank account
		DeletedAccount = Parameter;
		FoundRows = AvailableBankAccounts.FindRows(New Structure("BankAccount", DeletedAccount));
		If FoundRows.Count() > 0 Then
			If FoundRows[0].GetID() = Items.AvailableBankAccounts.CurrentRow Then
				//Change current row
				CurrentIndex = AvailableBankAccounts.IndexOf(FoundRows[0]);
				NewIndex = 0;
				If AvailableBankAccounts.Count() > 0 Then
					If CurrentIndex > 0 Then
						NewIndex = CurrentIndex - 1;
					Else
						NewIndex = 0;
					EndIf;
				Else
					FillAvailableAccounts();
					return;
				EndIf;
				Items.AvailableBankAccounts.CurrentRow = AvailableBankAccounts[NewIndex].GetID();
				AvailableBankAccounts.Delete(FoundRows[0]); //Remove the deleted bank account from the list
	            RefreshAvailableAccounts();
			Else
				AvailableBankAccounts.Delete(FoundRows[0]);
			EndIf;
		EndIf;
	EndIf;
EndProcedure

#EndRegion

#Region CONTROLS_EVENTS_HANDLERS

&AtClient
Procedure ScaleOnChange(Item)
	AvailableBankAccountsOnActivateRow(Undefined);
EndProcedure

#EndRegion

#Region TABULAR_SECTION_EVENTS_HANDLERS

&AtClient
Procedure AvailableBankAccountsOnActivateRow(Item)
	
	//First activation to be skipped, because the diagram is already refreshed
	If FormActivated = Undefined Then
		FormActivated = True;
		return;
	EndIf;
	If Items.AvailableBankAccounts.CurrentData = Undefined Then
		return;
	EndIf;
	CurrentBankAccountDescription = Items.AvailableBankAccounts.CurrentData.BankAccountDescription;
	AttachIdleHandler("ProcessBankAccountChange", 0.1, True);
	
EndProcedure

&AtClient
Procedure AvailableBankAccountsSelection(Item, SelectedRow, Field, StandardProcessing)
	
	If ValueIsFilled(Items.AvailableBankAccounts.CurrentData.AccountingAccount) Then
		SelectedBankAccount = Items.AvailableBankAccounts.CurrentData.BankAccount;
		OpenForm("DataProcessor.DownloadedTransactions.Form", New Structure("BankAccount", SelectedBankAccount));
		Notify("StartPageForm_SelectedBankAccount", SelectedBankAccount);
	Else
		Notify = New NotifyDescription("AssignAccountingAccountOrNot", ThisObject, new Structure("BankAccount", Items.AvailableBankAccounts.CurrentData.BankAccount));
		Message = "The selected bank account is not associated with a General Ledger account.
		|Do you wish to assign a G/L account now?"; 
		CommonUseClient.ShowCustomQueryBox(Notify, Message, QuestionDialogMode.YesNoCancel, 0, DialogReturnCode.Cancel, "Cloud Banking");
	EndIf;
	
EndProcedure

&AtClient
Procedure AssignAccountingAccountOrNot(Result, Parameters) Export
	
	If Result = DialogReturnCode.Yes Then
		Notify = New NotifyDescription("OnComplete_AssignAccountingAccount", ThisObject);
		Params = New Structure("PerformAssignAccount, RefreshAccount", True, Parameters.BankAccount);
		OpenForm("DataProcessor.YodleeBankAccountsManagement.Form.Form", Params, ThisForm,,,, Notify, FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
	
EndProcedure

&AtClient
Procedure OnComplete_AssignAccountingAccount(ClosureResult, AdditionalParameters) Export
	
	If ClosureResult <> Undefined Then //Successfully added account
		If TypeOf(ClosureResult) = Type("Array") Then
			If ClosureResult.Count() > 0 Then
				AssignedItem = ClosureResult[0];
				If TypeOf(AssignedItem) = Type("CatalogRef.BankAccounts") Then
					RefreshAvailableAccounts(AssignedItem);
				EndIf;
			EndIf;
		EndIf;
	EndIf;

	If ValueIsFilled(Items.AvailableBankAccounts.CurrentData.AccountingAccount) Then
		SelectedBankAccount = Items.AvailableBankAccounts.CurrentData.BankAccount;
		OpenForm("DataProcessor.DownloadedTransactions.Form", New Structure("BankAccount", SelectedBankAccount));
		Notify("StartPageForm_SelectedBankAccount", SelectedBankAccount);
	EndIf;
	
EndProcedure

#EndRegion

#Region COMMANDS_HANDLERS

&AtClient
Procedure AddAccount(Command)
	Notify = New NotifyDescription("OnComplete_AddAccount", ThisObject);
	Params = New Structure("PerformAddAccount", True);
	OpenForm("DataProcessor.YodleeBankAccountsManagement.Form.Form", Params, ThisForm,,,, Notify, FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

//------------------------Navigation Full Form--------------------------------

&AtClient
Procedure CashReceipt(Command)
	OpenForm("Document.CashReceipt.Form.DocumentForm");
EndProcedure

&AtClient
Procedure CashSale(Command)
	OpenForm("Document.CashSale.Form.DocumentForm");
EndProcedure

&AtClient
Procedure ChartOfAccounts(Command)
	OpenForm("ChartOfAccounts.ChartOfAccounts.Form.ListForm");
EndProcedure

&AtClient
Procedure GJEntry(Command)
	OpenForm("Document.GeneralJournalEntry.Form.DocumentForm");
EndProcedure

&AtClient
Procedure InvoicePayment(Command)
	OpenForm("Document.InvoicePayment.Form.DocumentForm");
EndProcedure

&AtClient
Procedure PurchaseOrder(Command)
	OpenForm("Document.PurchaseOrder.Form.DocumentForm");
EndProcedure

&AtClient
Procedure PurchaseInvoice(Command)
	OpenForm("Document.PurchaseInvoice.Form.DocumentForm");
EndProcedure

&AtClient
Procedure SalesOrder(Command)
	OpenForm("Document.SalesOrder.Form.DocumentForm");
EndProcedure

&AtClient
Procedure SalesInvoice(Command)
	OpenForm("Document.SalesInvoice.Form.DocumentForm");
EndProcedure

#EndRegion

#Region PRIVATE_IMPLEMENTATION

&AtServer
Procedure FillAvailableAccounts()
	Request = New Query("SELECT ALLOWED
	                    |	BankAccounts.Ref AS BankAccount,
	                    |	BankAccounts.CurrentBalance,
	                    |	BankAccounts.LastUpdatedTimeUTC,
	                    |	BankAccounts.AccountingAccount
	                    |INTO AvailableAccounts
	                    |FROM
	                    |	Catalog.BankAccounts AS BankAccounts
	                    |WHERE
	                    |	BankAccounts.DeletionMark = FALSE
	                    |;
	                    |
	                    |////////////////////////////////////////////////////////////////////////////////
	                    |SELECT ALLOWED
	                    |	GeneralJournalBalance.AmountBalance,
	                    |	GeneralJournalBalance.Account
	                    |INTO GLBalance
	                    |FROM
	                    |	AccountingRegister.GeneralJournal.Balance(
	                    |			,
	                    |			Account IN
	                    |				(SELECT
	                    |					AA.AccountingAccount
	                    |				FROM
	                    |					AvailableAccounts AS AA),
	                    |			,
	                    |			) AS GeneralJournalBalance
	                    |;
	                    |
	                    |////////////////////////////////////////////////////////////////////////////////
	                    |SELECT
	                    |	AvailableAccounts.BankAccount,
	                    |	COUNT(BankTransactions.ID) AS TransactionsCount
	                    |INTO CountOfTransactions
	                    |FROM
	                    |	InformationRegister.BankTransactions AS BankTransactions
	                    |		INNER JOIN AvailableAccounts AS AvailableAccounts
	                    |		ON (BankTransactions.Accepted = FALSE)
	                    |			AND (BankTransactions.Hidden = FALSE)
	                    |			AND BankTransactions.BankAccount = AvailableAccounts.BankAccount
	                    |
	                    |GROUP BY
	                    |	AvailableAccounts.BankAccount
	                    |;
	                    |
	                    |////////////////////////////////////////////////////////////////////////////////
	                    |SELECT
	                    |	AvailableAccounts.BankAccount,
	                    |	AvailableAccounts.BankAccount.Description,
	                    |	AvailableAccounts.CurrentBalance AS BankBalanceNumber,
	                    |	AvailableAccounts.LastUpdatedTimeUTC,
	                    |	ISNULL(CountOfTransactions.TransactionsCount, 0) AS UnacceptedTransactionsCount,
	                    |	ISNULL(GLBalance.AmountBalance, 0) AS GLBalanceNumber,
	                    |	""Bank balance"" AS BankBalanceCaption,
	                    |	""In AccountingSuite"" AS GLBalanceCaption,
	                    |	AvailableAccounts.AccountingAccount
	                    |FROM
	                    |	AvailableAccounts AS AvailableAccounts
	                    |		LEFT JOIN GLBalance AS GLBalance
	                    |		ON AvailableAccounts.AccountingAccount = GLBalance.Account
	                    |		LEFT JOIN CountOfTransactions AS CountOfTransactions
	                    |		ON AvailableAccounts.BankAccount = CountOfTransactions.BankAccount
	                    |;
	                    |
	                    |////////////////////////////////////////////////////////////////////////////////
	                    |SELECT ALLOWED
	                    |	BEGINOFPERIOD(BankTransactions.TransactionDate, MONTH) AS Month,
	                    |	SUM(CASE
	                    |			WHEN BankTransactions.Amount >= 0
	                    |				THEN BankTransactions.Amount
	                    |			ELSE 0
	                    |		END) AS Deposits,
	                    |	SUM(CASE
	                    |			WHEN BankTransactions.Amount < 0
	                    |				THEN BankTransactions.Amount
	                    |			ELSE 0
	                    |		END) AS Payments
	                    |FROM
	                    |	(SELECT TOP 1
	                    |		AvailableAccounts.BankAccount AS BankAccount
	                    |	FROM
	                    |		AvailableAccounts AS AvailableAccounts) AS FirstBankAccount
	                    |		INNER JOIN InformationRegister.BankTransactions AS BankTransactions
	                    |		ON FirstBankAccount.BankAccount = BankTransactions.BankAccount
	                    |			AND (BankTransactions.TransactionDate >= &BeginOfPeriod)
	                    |			AND (BankTransactions.TransactionDate <= &EndOfPeriod)
	                    |			AND (BankTransactions.ID = BankTransactions.OriginalID
	                    |				OR BankTransactions.OriginalID = &EmptyID)
	                    |
	                    |GROUP BY
	                    |	BEGINOFPERIOD(BankTransactions.TransactionDate, MONTH)
	                    |
	                    |ORDER BY
	                    |	Month");
	CurDate 			= CurrentUniversalDate();
	LocalDate 			= ToLocalTime(CurDate, SessionTimeZone());
	EndOfThisMonth		= EndOfMonth(LocalDate);
	BegOfThisMonth 		= BegOfMonth(LocalDate);
	BegOfPeriod			= AddMonth(BegOfThisMonth, -1 * DiagramMonthsCount);
	Request.SetParameter("BeginOfPeriod", BegOfPeriod);
	Request.SetParameter("EndOfPeriod", EndOfThisMonth);
	Request.SetParameter("EmptyID", New UUID("00000000-0000-0000-0000-000000000000"));

	ResArray = Request.ExecuteBatch();
	Res = ResArray[ResArray.Count()-2];
	AvailableBankAccounts.Clear();
	If NOT Res.IsEmpty() Then
		If Items.CloudBankingPages.CurrentPage <> Items.DiagramAccountsPage Then
			Items.CloudBankingPages.CurrentPage = Items.DiagramAccountsPage;
		EndIf;
		Sel = Res.Select();
		While Sel.Next() Do
			NewRow = AvailableBankAccounts.Add();
			FillPropertyValues(NewRow, Sel);
			AccountLastUpdated 	= GetLastUpdatedString(Sel.LastUpdatedTimeUTC);
			NewRow.UpdatedOn = AccountLastUpdated;
			NewRow.BankBalance = "$" + Format(Sel.BankBalanceNumber, "NFD=2; NDS=.; NZ=; NG=3,0");
			NewRow.GLBalance = "$" + Format(Sel.GLBalanceNumber, "NFD=2; NDS=.; NZ=; NG=3,0");
		EndDo;
		CurrentBankAccountDescription = AvailableBankAccounts[0].BankAccountDescription;
	Else
		Items.CloudBankingPages.CurrentPage = Items.ConnectNewAccountPage;
		return;
	EndIf;
	
	//Building diagram
	Res = ResArray[ResArray.Count()-1];
	Sel = Res.Select();
	MonthData = New Array();
	While Sel.Next() Do
		MonthData.Add(New Structure("Month, Deposits, Payments", Sel.Month, Sel.Deposits, Sel.Payments));
	EndDo;
	
	Diagram.RefreshEnabled = False;
	Diagram.Clear();
	DepositsSeries = Diagram.SetSeries("Deposits");
	PaymentsSeries = Diagram.SetSeries("Payments");
	DepositsSeries.Color = Items.DepositsColor.BackColor;
	PaymentsSeries.Color = Items.PaymentsColor.BackColor;
	
	For Each Row In MonthData Do
		MonthRepresentation = Format(Row.Month, "DF=MMMM");
		MonthPoint = Diagram.SetPoint(MonthRepresentation);
		Diagram.SetValue(MonthPoint, DepositsSeries, Row.Deposits/1000,, "Deposits in " + MonthRepresentation + ": " + Format(Row.Deposits, "NFD=2; NZ="));
		Diagram.SetValue(MonthPoint, PaymentsSeries, -1 * Row.Payments/1000,, "Payments in " + MonthRepresentation + ": " + Format(Row.Payments, "NFD=2; NZ="));
	EndDo;
	Diagram.ShowLegend = False;
	Diagram.RefreshEnabled = True;

EndProcedure

&AtServer
Procedure RefreshAvailableAccounts(BankAccount = Undefined)
	//If BankAccount is not passed then try to obtain it from the current row 
	If BankAccount = Undefined Then
		If Items.AvailableBankAccounts.CurrentRow <> Undefined Then
			FoundRow = AvailableBankAccounts.FindByID(Items.AvailableBankAccounts.CurrentRow);
			If FoundRow <> Undefined Then
				BankAccount = FoundRow.BankAccount;
			EndIf;
		EndIf;
	Else
		//Set the current row to correspond to the bank account
		FoundRows = AvailableBankAccounts.FindRows(New Structure("BankAccount", BankAccount));
		If FoundRows.Count() > 0 Then
			CurrentID = FoundRows[0].GetID();
			If Items.AvailableBankAccounts.CurrentRow <> CurrentID Then
				Items.AvailableBankAccounts.CurrentRow = CurrentID;
			EndIf;
		EndIf;
	EndIf;
	Request = New Query("SELECT ALLOWED
	                    |	BankAccounts.Ref AS BankAccount,
	                    |	BankAccounts.CurrentBalance,
	                    |	BankAccounts.LastUpdatedTimeUTC,
	                    |	BankAccounts.AccountingAccount
	                    |INTO AvailableAccounts
	                    |FROM
	                    |	Catalog.BankAccounts AS BankAccounts
	                    |WHERE
	                    |	BankAccounts.DeletionMark = FALSE
	                    |;
	                    |
	                    |////////////////////////////////////////////////////////////////////////////////
	                    |SELECT ALLOWED
	                    |	GeneralJournalBalance.AmountBalance,
	                    |	GeneralJournalBalance.Account
	                    |INTO GLBalance
	                    |FROM
	                    |	AccountingRegister.GeneralJournal.Balance(
	                    |			,
	                    |			Account IN
	                    |				(SELECT
	                    |					AA.AccountingAccount
	                    |				FROM
	                    |					AvailableAccounts AS AA),
	                    |			,
	                    |			) AS GeneralJournalBalance
	                    |;
	                    |
	                    |////////////////////////////////////////////////////////////////////////////////
	                    |SELECT
	                    |	AvailableAccounts.BankAccount,
	                    |	COUNT(BankTransactions.ID) AS TransactionsCount
	                    |INTO CountOfTransactions
	                    |FROM
	                    |	InformationRegister.BankTransactions AS BankTransactions
	                    |		INNER JOIN AvailableAccounts AS AvailableAccounts
	                    |		ON (BankTransactions.Accepted = FALSE)
	                    |			AND (BankTransactions.Hidden = FALSE)
	                    |			AND BankTransactions.BankAccount = AvailableAccounts.BankAccount
	                    |
	                    |GROUP BY
	                    |	AvailableAccounts.BankAccount
	                    |;
	                    |
	                    |////////////////////////////////////////////////////////////////////////////////
	                    |SELECT
	                    |	AvailableAccounts.BankAccount,
	                    |	AvailableAccounts.BankAccount.Description,
	                    |	AvailableAccounts.CurrentBalance AS BankBalanceNumber,
	                    |	AvailableAccounts.LastUpdatedTimeUTC,
	                    |	ISNULL(CountOfTransactions.TransactionsCount, 0) AS UnacceptedTransactionsCount,
	                    |	ISNULL(GLBalance.AmountBalance, 0) AS GLBalanceNumber,
	                    |	""Bank balance"" AS BankBalanceCaption,
	                    |	""In AccountingSuite"" AS GLBalanceCaption,
	                    |	AvailableAccounts.AccountingAccount
	                    |FROM
	                    |	AvailableAccounts AS AvailableAccounts
	                    |		LEFT JOIN GLBalance AS GLBalance
	                    |		ON AvailableAccounts.AccountingAccount = GLBalance.Account
	                    |		LEFT JOIN CountOfTransactions AS CountOfTransactions
	                    |		ON AvailableAccounts.BankAccount = CountOfTransactions.BankAccount
	                    |;
	                    |
	                    |////////////////////////////////////////////////////////////////////////////////
	                    |SELECT ALLOWED
	                    |	BEGINOFPERIOD(BankTransactions.TransactionDate, MONTH) AS Month,
	                    |	SUM(CASE
	                    |			WHEN BankTransactions.Amount >= 0
	                    |				THEN BankTransactions.Amount
	                    |			ELSE 0
	                    |		END) AS Deposits,
	                    |	SUM(CASE
	                    |			WHEN BankTransactions.Amount < 0
	                    |				THEN BankTransactions.Amount
	                    |			ELSE 0
	                    |		END) AS Payments
	                    |FROM
	                    |	InformationRegister.BankTransactions AS BankTransactions
	                    |WHERE
	                    |	BankTransactions.BankAccount = &BankAccount
	                    |	AND BankTransactions.TransactionDate >= &BeginOfPeriod
	                    |	AND BankTransactions.TransactionDate <= &EndOfPeriod
	                    |	AND (BankTransactions.ID = BankTransactions.OriginalID
	                    |			OR BankTransactions.OriginalID = &EmptyID)
	                    |
	                    |GROUP BY
	                    |	BEGINOFPERIOD(BankTransactions.TransactionDate, MONTH)
	                    |
	                    |ORDER BY
	                    |	Month");
	CurDate 			= CurrentUniversalDate();
	LocalDate 			= ToLocalTime(CurDate, SessionTimeZone());
	EndOfThisMonth		= EndOfMonth(LocalDate);
	BegOfThisMonth 		= BegOfMonth(LocalDate);
	BegOfPeriod			= AddMonth(BegOfThisMonth, -1 * DiagramMonthsCount);
	Request.SetParameter("BankAccount", BankAccount);
	Request.SetParameter("BeginOfPeriod", BegOfPeriod);
	Request.SetParameter("EndOfPeriod", EndOfThisMonth);
	Request.SetParameter("EmptyID", New UUID("00000000-0000-0000-0000-000000000000"));

	ResArray = Request.ExecuteBatch();
	Res = ResArray[ResArray.Count()-2];
	RefreshedBankAccounts = Res.Unload();
	
	If RefreshedBankAccounts.Count() > 0 Then
		If Items.CloudBankingPages.CurrentPage <> Items.DiagramAccountsPage Then
			Items.CloudBankingPages.CurrentPage = Items.DiagramAccountsPage;
		EndIf;
	Else
		Items.CloudBankingPages.CurrentPage = Items.ConnectNewAccountPage;
		return;
	EndIf;
	
	For Each RefreshedBankAccount In RefreshedBankAccounts Do
		FoundRows = AvailableBankAccounts.FindRows(New Structure("BankAccount", RefreshedBankAccount.BankAccount));
		If FoundRows.Count() > 0 Then // Refresh existing row
			NewRow = FoundRows[0];
			FillPropertyValues(NewRow, RefreshedBankAccount);
			AccountLastUpdated 	= GetLastUpdatedString(RefreshedBankAccount.LastUpdatedTimeUTC);
			NewRow.UpdatedOn = AccountLastUpdated;
			NewRow.BankBalance = "$" + Format(RefreshedBankAccount.BankBalanceNumber, "NFD=2; NDS=.; NZ=; NG=3,0");
			NewRow.GLBalance = "$" + Format(RefreshedBankAccount.GLBalanceNumber, "NFD=2; NDS=.; NZ=; NG=3,0");
		Else // Add new row
			NewRow = AvailableBankAccounts.Add();
			FillPropertyValues(NewRow, RefreshedBankAccount);
			AccountLastUpdated 	= GetLastUpdatedString(RefreshedBankAccount.LastUpdatedTimeUTC);
			NewRow.UpdatedOn = AccountLastUpdated;
			NewRow.BankBalance = "$" + Format(RefreshedBankAccount.BankBalanceNumber, "NFD=2; NDS=.; NZ=; NG=3,0");
			NewRow.GLBalance = "$" + Format(RefreshedBankAccount.GLBalanceNumber, "NFD=2; NDS=.; NZ=; NG=3,0");
		EndIf;
	EndDo;
		
	//Check if some bank account was deleted
	CurrentRow = Items.AvailableBankAccounts.CurrentRow;
	NeedToRefreshDiagram = False;
	NewCurrentBankAccount = Undefined;
	i = 0;
	While i < AvailableBankAccounts.Count() Do
		AvailableBankAccount = AvailableBankAccounts[i];
		FoundRows = RefreshedBankAccounts.FindRows(New Structure("BankAccount", AvailableBankAccount.BankAccount));
		If FoundRows.Count() = 0 Then //Bank account was deleted
			If AvailableBankAccount.GetID() = CurrentRow Then
				NeedToRefreshDiagram = True;
				//Find the new "Current" row
				If i > 0 Then
					Items.AvailableBankAccounts.CurrentRow = AvailableBankAccounts[i-1].GetID();
					NewCurrentBankAccount = AvailableBankAccounts[i-1].BankAccount;
				ElsIf AvailableBankAccounts.Count() > 1 Then
					Items.AvailableBankAccounts.CurrentRow = AvailableBankAccounts[i+1].GetID();
					NewCurrentBankAccount = AvailableBankAccounts[i+1].BankAccount;
				EndIf;
			EndIf;
			AvailableBankAccounts.Delete(i);
			Continue;
		Else
			i = i + 1;
		EndIf;
	EndDo;
	If NeedToRefreshDiagram Then
		If RefreshedBankAccounts.Count() > 0 Then
			RefreshAvailableAccounts(NewCurrentBankAccount);
		Else
			FillAvailableAccounts();
		EndIf;
		return;
	EndIf;
	
	//Building diagram
	Res = ResArray[ResArray.Count()-1];
	Sel = Res.Select();
	MonthData = New Array();
	While Sel.Next() Do
		MonthData.Add(New Structure("Month, Deposits, Payments", Sel.Month, Sel.Deposits, Sel.Payments));
	EndDo;
	
	Diagram.RefreshEnabled = False;
	Diagram.Clear();
	DepositsSeries = Diagram.SetSeries("Deposits");
	PaymentsSeries = Diagram.SetSeries("Payments");
	DepositsSeries.Color = Items.DepositsColor.BackColor;
	PaymentsSeries.Color = Items.PaymentsColor.BackColor;
	
	For Each Row In MonthData Do
		MonthRepresentation = Format(Row.Month, "DF=MMMM");
		MonthPoint = Diagram.SetPoint(MonthRepresentation);
		Diagram.SetValue(MonthPoint, DepositsSeries, Row.Deposits/1000,, "Deposits in " + MonthRepresentation + ": " + Format(Row.Deposits, "NFD=2; NZ="));
		Diagram.SetValue(MonthPoint, PaymentsSeries, -1 * Row.Payments/1000,, "Payments in " + MonthRepresentation + ": " + Format(Row.Payments, "NFD=2; NZ="));
	EndDo;
	Diagram.ShowLegend = False;
	Diagram.RefreshEnabled = True;
EndProcedure

&AtClientAtServerNoContext
Function GetLastUpdatedString(LastUpdatedTimeUTC)
	LastUpdated = ToLocalTime(LastUpdatedTimeUTC);
	If (Not ValueIsFilled(LastUpdated)) Or (LastUpdated < '19800101') Then
		return "Not updated";
	EndIf;
	LocalTime = CurrentDate();
	If ((LocalTime - LastUpdated) < 3600) Then //Recently within 1 hour
		return Format(Int((LocalTime - LastUpdated)/60), "NFD=0; NZ=") + " minutes ago"; ;
	ElsIf ((LocalTime - LastUpdated) < 24*3600) Then //Within 24 hours ago
		HourDiff = Int((LocalTime - LastUpdated)/3600);
		return Format(HourDiff, "NFD=0; NZ=") + ?(HourDiff = 1, " hour", " hours") +" ago";
	ElsIf BegOfDay(LocalTime - 24*3600) = BegOfDay(LastUpdated) Then //Yesterday
		return "Yesterday";
	Else
		return Format(LastUpdated, "DLF=DD");
	EndIf;		 
EndFunction

&AtServer
Procedure UpdateDiagram(CurrentBankAccount)
	
	Diagram.RefreshEnabled = False;
	Diagram.Clear();
	DepositsSeries = Diagram.SetSeries("Deposits");
	PaymentsSeries = Diagram.SetSeries("Payments");
	DepositsSeries.Color = Items.DepositsColor.BackColor;
	PaymentsSeries.Color = Items.PaymentsColor.BackColor;
	
	MonthData = GetDataForDiagram(CurrentBankAccount, DiagramMonthsCount);
	For Each Row In MonthData Do
		MonthRepresentation = Format(Row.Month, "DF=MMMM");
		MonthPoint = Diagram.SetPoint(MonthRepresentation);
		Diagram.SetValue(MonthPoint, DepositsSeries, Row.Deposits/1000,, "Deposits in " + MonthRepresentation + ": " + Format(Row.Deposits, "NFD=2; NZ="));
		Diagram.SetValue(MonthPoint, PaymentsSeries, -1 * Row.Payments/1000,, "Payments in " + MonthRepresentation + ": " + Format(Row.Payments, "NFD=2; NZ="));
	EndDo;
	Diagram.ShowLegend = False;
	Diagram.RefreshEnabled = True;
EndProcedure

&AtServerNoContext
Function GetDataForDiagram(BankAccount, NumberOfMonths = 2)
	Request = New Query("SELECT ALLOWED
	                    |	BEGINOFPERIOD(BankTransactions.TransactionDate, MONTH) AS Month,
	                    |	SUM(CASE
	                    |			WHEN BankTransactions.Amount >= 0
	                    |				THEN BankTransactions.Amount
	                    |			ELSE 0
	                    |		END) AS Deposits,
	                    |	SUM(CASE
	                    |			WHEN BankTransactions.Amount < 0
	                    |				THEN BankTransactions.Amount
	                    |			ELSE 0
	                    |		END) AS Payments
	                    |FROM
	                    |	InformationRegister.BankTransactions AS BankTransactions
	                    |WHERE
	                    |	BankTransactions.BankAccount = &BankAccount
	                    |	AND BankTransactions.TransactionDate >= &BeginOfPeriod
	                    |	AND BankTransactions.TransactionDate <= &EndOfPeriod
	                    |	AND (BankTransactions.ID = BankTransactions.OriginalID
	                    |			OR BankTransactions.OriginalID = &EmptyID)
	                    |
	                    |GROUP BY
	                    |	BEGINOFPERIOD(BankTransactions.TransactionDate, MONTH)
	                    |
	                    |ORDER BY
	                    |	Month");
	CurDate 			= CurrentUniversalDate();
	LocalDate 			= ToLocalTime(CurDate, SessionTimeZone());
	EndOfThisMonth		= EndOfMonth(LocalDate);
	BegOfThisMonth 		= BegOfMonth(LocalDate);
	BegOfPeriod			= AddMonth(BegOfThisMonth, -1 * NumberOfMonths);
	Request.SetParameter("BankAccount", BankAccount);
	Request.SetParameter("BeginOfPeriod", BegOfPeriod);
	Request.SetParameter("EndOfPeriod", EndOfThisMonth);
	Request.SetParameter("EmptyID", New UUID("00000000-0000-0000-0000-000000000000"));
	Sel = Request.Execute().Select();
	Result = New Array();
	While Sel.Next() Do
		Result.Add(New Structure("Month, Deposits, Payments", Sel.Month, Sel.Deposits, Sel.Payments));
	EndDo;
	return Result;
	
EndFunction

&AtClient
Procedure ProcessBankAccountChange() Export
	
	UpdateDiagram(Items.AvailableBankAccounts.CurrentData.BankAccount);

EndProcedure

&AtClient
Procedure OnComplete_AddAccount(ClosureResult, AdditionalParameters) Export
	If ClosureResult <> Undefined Then //Successfully added account
		If TypeOf(ClosureResult) = Type("Array") Then
			If ClosureResult.Count() > 0 Then
				NewAddedItem = ClosureResult[0];
				If TypeOf(NewAddedItem) = Type("CatalogRef.BankAccounts") Then
					RefreshAvailableAccounts(NewAddedItem);
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdateAvailableAccounts() Export
	RefreshAvailableAccounts();
EndProcedure

&AtClient
Procedure QuickEntry(Command)
	OpenForm("DataProcessor.BankRegisterCFOToday.Form.Form");
EndProcedure

&AtClient
Procedure BankRec(Command)
	OpenForm("Document.BankReconciliation.Form.ListForm");
EndProcedure

&AtClient
Procedure CustomerVendorCentral(Command)
	OpenForm("Catalog.Companies.Form.ListForm");
EndProcedure

&AtClient
Procedure CloudBanking(Command)
	OpenForm("DataProcessor.DownloadedTransactions.Form.Form");
EndProcedure

&AtClient
Procedure JournalEntries(Command)
	OpenForm("Document.GeneralJournalEntry.Form.ListForm");
EndProcedure

&AtClient
Procedure Checks(Command)
	OpenForm("Document.Check.Form.ListForm");
EndProcedure

&AtClient
Procedure Deposits(Command)
	OpenForm("Document.Deposit.Form.ListForm");
EndProcedure

#EndRegion