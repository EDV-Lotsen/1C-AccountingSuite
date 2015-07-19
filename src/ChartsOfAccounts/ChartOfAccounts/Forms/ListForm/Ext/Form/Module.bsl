////////////////////////////////////////////////////////////////////////////////
// Chart of accounts: List form
//------------------------------------------------------------------------------
// Available on:
// - Client (managed application)
// - Server
//

////////////////////////////////////////////////////////////////////////////////
#Region EVENTS_HANDLERS

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	TypeBalance = 1;
	GetTrialBalance();
	
	//DisplayFooter = False;
	//IsInternalUser1 = Find(SessionParameters.ACSUser,"@accountingsuite.com");
	//If IsInternalUser1 <> 0 Then
	//	DisplayFooter = True;	
	//EndIf;
	//Items.Footer.Visible = DisplayFooter;

EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	Items.List.Representation = TableRepresentation.List;
	Items.List.InitialTreeView = InitialTreeView.NoExpand;

EndProcedure

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region CONTROLS_EVENTS_HANDLERS

&AtClient
Procedure TypeBalanceOnChange(Item)
	
	If TypeBalance = 0 Then	
		GetRegularBalance();
	Else
		GetTrialBalance();
	EndIf;
	
EndProcedure

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region COMMANDS_HANDLERS

&AtClient
Procedure GeneralLedger(Command)
	
	CurrentAccount = Items.List.CurrentRow;	
	
	If ValueIsFilled(CurrentAccount) Then
				
		ParametersStructure = New Structure;
		ParametersStructure.Insert("GenerateOnOpen", True); 
		ReportForm = GetForm("Report.GeneralLedger.Form.ReportForm", ParametersStructure,, True);
		
		///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		ReportFormSettings = ReportForm.Report.SettingsComposer.Settings;
		
		//Period
		PeriodSettingID = ReportFormSettings.DataParameters.Items.Find("Period").UserSettingID;
		
		//Account
		AccountField = ReportFormSettings.Filter.FilterAvailableFields.Items.Find("AccountFilter").Field;
		AccountSettingID  = "";

		For Each Item In ReportFormSettings.Filter.Items Do
			If Item.LeftValue = AccountField Then
				AccountSettingID = Item.UserSettingID;
				Break;
			EndIf;
		EndDo;
		
		UserSettings = ReportForm.Report.SettingsComposer.UserSettings.Items;
		///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		
		//Period
		UserSettings.Find(PeriodSettingID).Value = New StandardPeriod(AddMonth(CurrentDate(), -3), CurrentDate());
		UserSettings.Find(PeriodSettingID).Use = True;
		
		//Item
		UserSettings.Find(AccountSettingID).RightValue = CurrentAccount;
		UserSettings.Find(AccountSettingID).ComparisonType = DataCompositionComparisonType.InHierarchy; 
		UserSettings.Find(AccountSettingID).Use = True; 
		///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		
		ReturnStructure = ProcessDetailsAtServer(ReportForm.Report, ReportForm.Result, ReportForm.DetailsData, ReportForm.UUID);
		ReportForm.Result = ReturnStructure.Result;
		ReportForm.DetailsData = ReturnStructure.DetailsData;
		
		ReportForm.Open();
			
	EndIf;
	
EndProcedure

&AtClient
Procedure ImportChartOfAccounts(Command)
	
	If ListIsEmpty() Then
		
		Notify = New NotifyDescription("ExcelFileUpload", ThisForm);
		
		BeginPutFile(Notify, "", "*.acs", True, ThisForm.UUID);
		
	Else
		
		ShowMessageBox(,NStr("en = 'This function available for the empty list only!'"));
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ExportChartOfAccounts(Command)
	
	Spreadsheet = New SpreadsheetDocument;
	ExportChartOfAccountsAtServer(Spreadsheet);
	
	Structure = GeneralFunctions.GetExcelFile("Chart of accounts", Spreadsheet);
	
	GetFile(Structure.Address, StrReplace(Structure.FileName, ".xlsx",".acs"), True); 
	
EndProcedure

&AtClient
Procedure RefreshList(Command)
	
	If TypeBalance = 0 Then	
		GetRegularBalance();
	Else
		GetTrialBalance();
	EndIf;
	
EndProcedure

#EndRegion

#Region EXCEL

&AtClient
Procedure ExcelFileUpload(Result, Address, SelectedFileName, AdditionalParameters) Export
	
	If Find(SelectedFileName, ".acs") = 0 Then
		ShowMessageBox(, NStr("en = 'Please upload a valid ACS file (.acs)'"));
		Return;
	EndIf;
	
	If ValueIsFilled(Address) Then
		ShowUserNotification(NStr("en = 'Reading file with  ACS...'"));
		
		Errors = False;
		ImportData(Address, Errors);
	EndIf;
	
	If Not Errors Then
		Items.List.Refresh();
		ShowMessageBox(,NStr("en = 'Done!'"));
	EndIf;
	
EndProcedure

&AtServer
Procedure ImportData(TempStorageAddress, Errors)
	
	BinaryData = GetFromTempStorage(TempStorageAddress);

	TempFileName = GetTempFileName("xls");
	BinaryData.Write(TempFileName);
	
	Try
		COMExcel   = New COMObject("Excel.Application");
		Excel      = COMExcel.Application.WorkBooks.Open(TempFileName);
		ExcelSheet = Excel.Sheets(1);
	Except
		ErrorDescription = ErrorDescription();
		CommonUseClientServer.MessageToUser(NStr("en = 'An error occurred. Details:'") + ErrorDescription);
		
		Errors = True;
		Return;
	EndTry;
			
	//Clear collections
	VT = New ValueTable();
	VT.Columns.Add("Code",               New TypeDescription("String"));
	VT.Columns.Add("Description",        New TypeDescription("String"));
	VT.Columns.Add("Parent",             New TypeDescription("String"));
	VT.Columns.Add("AccountType",        New TypeDescription("EnumRef.AccountTypes"));
	VT.Columns.Add("Category1099",       New TypeDescription("CatalogRef.USTaxCategories1099"));
	VT.Columns.Add("Currency",           New TypeDescription("CatalogRef.Currencies"));
	VT.Columns.Add("CashFlowSection",    New TypeDescription("EnumRef.CashFlowSections"));
	VT.Columns.Add("Memo",               New TypeDescription("String"));
	VT.Columns.Add("CreditCard",         New TypeDescription("Boolean"));
	VT.Columns.Add("ReclassAccount",     New TypeDescription("String"));
	VT.Columns.Add("CashFromOperations", New TypeDescription("Boolean"));
	VT.Columns.Add("RCL",                New TypeDescription("Boolean"));
	VT.Columns.Add("RetainedEarnings",   New TypeDescription("Boolean"));
	VT.Columns.Add("gc_rectype",         New TypeDescription("String"));
	VT.Columns.Add("gc_totlev",          New TypeDescription("String"));
	
	CurrentRowNumber = 1;	
	LastRowNumber    = ExcelSheet.Cells.SpecialCells(11).Row;
	
	While True Do
		
		CurrentRowNumber = CurrentRowNumber + 1;
		
		//-------------------------------------------------------------------------------------
		_Code               = TrimAll(ExcelSheet.Cells(CurrentRowNumber,  1).Text);
		_Description        = TrimAll(ExcelSheet.Cells(CurrentRowNumber,  2).Text);
		_Parent             = TrimAll(ExcelSheet.Cells(CurrentRowNumber,  3).Text);
		_AccountType        = TrimAll(ExcelSheet.Cells(CurrentRowNumber,  4).Text);
		_Category1099       = TrimAll(ExcelSheet.Cells(CurrentRowNumber,  5).Text);
		_Currency           = TrimAll(ExcelSheet.Cells(CurrentRowNumber,  6).Text);
		_CashFlowSection    = TrimAll(ExcelSheet.Cells(CurrentRowNumber,  7).Text);
		_Memo               = TrimAll(ExcelSheet.Cells(CurrentRowNumber,  8).Text);
		_CreditCard         = TrimAll(ExcelSheet.Cells(CurrentRowNumber,  9).Text);
		_ReclassAccount     = TrimAll(ExcelSheet.Cells(CurrentRowNumber, 10).Text);
		_CashFromOperations = TrimAll(ExcelSheet.Cells(CurrentRowNumber, 11).Text);
		_RCL                = TrimAll(ExcelSheet.Cells(CurrentRowNumber, 12).Text);
		_RetainedEarnings   = TrimAll(ExcelSheet.Cells(CurrentRowNumber, 13).Text);
		_gc_rectype         = TrimAll(ExcelSheet.Cells(CurrentRowNumber, 14).Text);
		_gc_totlev          = TrimAll(ExcelSheet.Cells(CurrentRowNumber, 15).Text);
		
		//-------------------------------------------------------------------------------------
		RowVT = VT.Add();
		RowVT.Code                = _Code;
		RowVT.Description         = _Description;
		RowVT.Parent              = _Parent;
		RowVT.AccountType         = GetAccountType(_AccountType);
		Try
			RowVT.Category1099    = Catalogs.USTaxCategories1099[_Category1099];
		Except
			RowVT.Category1099    = Catalogs.USTaxCategories1099.EmptyRef();
		EndTry;
		RowVT.Currency            = Catalogs.Currencies.FindByAttribute("Symbol", _Currency);
		Try
			RowVT.CashFlowSection = Enums.CashFlowSections[_CashFlowSection];
		Except
			RowVT.CashFlowSection = Enums.CashFlowSections.EmptyRef();
		EndTry;
		RowVT.Memo                = _Memo;
		RowVT.CreditCard          = ?(Lower(_CreditCard) = "yes", True, False);
		RowVT.ReclassAccount      = _ReclassAccount;
		RowVT.CashFromOperations  = ?(Lower(_CashFromOperations) = "yes", True, False);
		RowVT.RCL                 = ?(Lower(_RCL) = "yes", True, False);
		RowVT.RetainedEarnings    = ?(Lower(_RetainedEarnings) = "yes", True, False);
		RowVT.gc_rectype          = _gc_rectype;
		RowVT.gc_totlev           = _gc_totlev;
		
		If CurrentRowNumber >= LastRowNumber Then
			Break;	
		EndIf;
		
	EndDo;
	
	Excel.Close();
	
	CreateChartOfAccounts(VT, Errors);
	
EndProcedure

&AtServer
Procedure CreateChartOfAccounts(VT, Errors)
	
	VT.Columns.Add("Ref", New TypeDescription("ChartOfAccountsRef.ChartOfAccounts"));
	
	BeginTransaction(DataLockControlMode.Managed);
	//-------------------------------------------------------------------------------------------------	
	Try
		
		For each CurrentLine In VT Do
			
			NewAccount = ChartsOfAccounts.ChartOfAccounts.CreateAccount();
			
			NewAccount.Code               = CurrentLine.Code;
			NewAccount.Order              = CurrentLine.Code;
			NewAccount.Description        = CurrentLine.Description;
			NewAccount.Type               = AccountType.ActivePassive;
			NewAccount.OffBalance         = False;
			
			NewAccount.AccountType        = CurrentLine.AccountType;
			NewAccount.Category1099       = CurrentLine.Category1099;
			NewAccount.Currency           = CurrentLine.Currency;
			NewAccount.CashFlowSection    = CurrentLine.CashFlowSection;
			NewAccount.Memo               = CurrentLine.Memo;
			NewAccount.CreditCard         = CurrentLine.CreditCard;
			NewAccount.CashFromOperations = CurrentLine.CashFromOperations;
			NewAccount.RCL                = CurrentLine.RCL;
			NewAccount.RetainedEarnings   = CurrentLine.RetainedEarnings;
			NewAccount.gc_rectype         = CurrentLine.gc_rectype;
			NewAccount.gc_totlev          = CurrentLine.gc_totlev;
			
			NewAccount.Write();
			
			CurrentLine.Ref = NewAccount.Ref;
			
		EndDo;
		
	Except
		Errors = True;
		ErrorDescription = ErrorDescription();
		CommonUseClientServer.MessageToUser(CurrentLine.Code + " " + CurrentLine.Description + ": " + ErrorDescription);
	EndTry;
	//-------------------------------------------------------------------------------------------------
	If Errors Then
		If TransactionActive() Then
			RollbackTransaction();
		EndIf;
	Else
		CommitTransaction();
		
		For each CurrentLine In VT Do
			
			If ValueIsFilled(CurrentLine.Parent) Or ValueIsFilled(CurrentLine.ReclassAccount) Then
				
				ChartOfAccountsObject = CurrentLine.Ref.GetObject();	
				
				If ValueIsFilled(CurrentLine.Parent) Then
					ChartOfAccountsObject.Parent = ChartsOfAccounts.ChartOfAccounts.FindByCode(CurrentLine.Parent);
				EndIf;
				
				If ValueIsFilled(CurrentLine.ReclassAccount) Then
					ChartOfAccountsObject.ReclassAccount = ChartsOfAccounts.ChartOfAccounts.FindByCode(CurrentLine.ReclassAccount);
				EndIf;
				
				ChartOfAccountsObject.Write();
				
			EndIf;
			
		EndDo;
	EndIf;
	
EndProcedure

&AtServer
Function ExportChartOfAccountsAtServer(Spreadsheet)
	
	Template = ChartsOfAccounts.ChartOfAccounts.GetTemplate("CFO_PrintForm");
	
	Header = Template.GetArea("Header");
	Spreadsheet.Put(Header);
	
	SelectChartOfAccounts = ChartsOfAccounts.ChartOfAccounts.Select();
	
	While SelectChartOfAccounts.Next() Do 
		
		Line = Template.GetArea("Line");
		
		Line.Parameters.Code               = SelectChartOfAccounts.Code;
		Line.Parameters.Description        = SelectChartOfAccounts.Description;
		Line.Parameters.Parent	           = SelectChartOfAccounts.Parent.Code;
		Line.Parameters.AccountType	       = SelectChartOfAccounts.AccountType;//.Metadata().EnumValues[Enums[SelectChartOfAccounts.AccountType.Metadata().Name].IndexOf(SelectChartOfAccounts.AccountType)].Name;
		Line.Parameters.Category1099	   = SelectChartOfAccounts.Category1099.PredefinedDataName;
		Line.Parameters.Currency	       = SelectChartOfAccounts.Currency.Symbol;
		Line.Parameters.CashFlowSection    = SelectChartOfAccounts.CashFlowSection;
		Line.Parameters.Memo               = SelectChartOfAccounts.Memo;
		Line.Parameters.CreditCard         = ?(SelectChartOfAccounts.CreditCard, "Yes", "");
		Line.Parameters.ReclassAccount     = SelectChartOfAccounts.ReclassAccount.Code;
		Line.Parameters.CashFromOperations = ?(SelectChartOfAccounts.CashFromOperations, "Yes", "");
		Line.Parameters.RCL                = ?(SelectChartOfAccounts.RCL, "Yes", "");
		Line.Parameters.RetainedEarnings   = ?(SelectChartOfAccounts.RetainedEarnings, "Yes", "");
		Line.Parameters.gc_rectype         = SelectChartOfAccounts.gc_rectype;
		Line.Parameters.gc_totlev          = SelectChartOfAccounts.gc_totlev;
		
		Spreadsheet.Put(Line);
		
	EndDo;
	
EndFunction

&AtServer
Function GetAccountType(Synonym);
	
    EnumValues = Metadata.Enums.AccountTypes.EnumValues;
    For each EnumValue In EnumValues Do
        If EnumValue.Synonym = Synonym Then
            Return Enums.AccountTypes[EnumValue.Name];
        EndIf;
	EndDo;
	
    Return Enums.AccountTypes.EmptyRef();
	
EndFunction

#EndRegion

#Region BALANCE

&AtServer
Procedure GetRegularBalance()
	
	List.QueryText = "SELECT
	                 |	ChartOfAccounts.Ref AS Ref,
	                 |	ChartOfAccounts.Code AS Code,
	                 |	ChartOfAccounts.Parent.Code AS Parent,
	                 |	ChartOfAccounts.ReclassAccount AS Reclass,
	                 |	ChartOfAccounts.CreditCard AS CreditCard,
	                 |	ChartOfAccounts.Description AS Description,
	                 |	ChartOfAccounts.AccountType AS AccountType,
	                 |	NewChartOfAccounts.Balance AS Balance,
	                 |	ChartOfAccounts.Category1099 AS Category1099,
	                 |	ChartOfAccounts.gc_rectype AS gc_rectype,
	                 |	ChartOfAccounts.gc_totlev AS gc_totlev
	                 |FROM
	                 |	ChartOfAccounts.ChartOfAccounts AS ChartOfAccounts
	                 |		LEFT JOIN (SELECT
	                 |			ChartOfAccountsChartOfAccounts.Ref AS Ref,
	                 |			ChartOfAccountsChartOfAccounts.Code AS Code,
	                 |			ChartOfAccountsChartOfAccounts.Description AS Description,
	                 |			ChartOfAccountsChartOfAccounts.AccountType AS AccountType,
	                 |			SUM(CASE
	                 |					WHEN GeneralJournalBalance.AmountRCBalance IS NULL 
	                 |						THEN 0
	                 |					WHEN ChartOfAccountsChartOfAccounts.AccountType = VALUE(Enum.AccountTypes.AccountsPayable)
	                 |							OR ChartOfAccountsChartOfAccounts.AccountType = VALUE(Enum.AccountTypes.OtherCurrentLiability)
	                 |							OR ChartOfAccountsChartOfAccounts.AccountType = VALUE(Enum.AccountTypes.LongTermLiability)
	                 |							OR ChartOfAccountsChartOfAccounts.AccountType = VALUE(Enum.AccountTypes.Equity)
	                 |							OR ChartOfAccountsChartOfAccounts.AccountType = VALUE(Enum.AccountTypes.Income)
	                 |							OR ChartOfAccountsChartOfAccounts.AccountType = VALUE(Enum.AccountTypes.OtherIncome)
	                 |						THEN -GeneralJournalBalance.AmountRCBalance
	                 |					ELSE GeneralJournalBalance.AmountRCBalance
	                 |				END) AS Balance,
	                 |			ChartOfAccountsChartOfAccounts.Category1099 AS Category1099
	                 |		FROM
	                 |			ChartOfAccounts.ChartOfAccounts AS ChartOfAccountsChartOfAccounts
	                 |				LEFT JOIN (SELECT
	                 |					ChartOfAccounts.Ref AS Ref,
	                 |					ISNULL(HierarchyChartOfAccounts.Route, """") AS Route
	                 |				FROM
	                 |					ChartOfAccounts.ChartOfAccounts AS ChartOfAccounts
	                 |						LEFT JOIN InformationRegister.HierarchyChartOfAccounts AS HierarchyChartOfAccounts
	                 |						ON ChartOfAccounts.Ref = HierarchyChartOfAccounts.Account) AS NestedSelect
	                 |					LEFT JOIN AccountingRegister.GeneralJournal.Balance AS GeneralJournalBalance
	                 |					ON NestedSelect.Ref = GeneralJournalBalance.Account
	                 |				ON (NestedSelect.Route LIKE ""%/"" + ChartOfAccountsChartOfAccounts.Code + ""/%"")
	                 |		
	                 |		GROUP BY
	                 |			ChartOfAccountsChartOfAccounts.Ref,
	                 |			ChartOfAccountsChartOfAccounts.Code,
	                 |			ChartOfAccountsChartOfAccounts.Description,
	                 |			ChartOfAccountsChartOfAccounts.AccountType,
	                 |			ChartOfAccountsChartOfAccounts.Category1099) AS NewChartOfAccounts
	                 |		ON ChartOfAccounts.Ref = NewChartOfAccounts.Ref";
	
EndProcedure

&AtServer
Procedure GetTrialBalance()
	
	//1.
	VT = GetTableBalance();
	
	//2.
	CaseText         = "";
	NumbeOfParameter = 0;
	
	For Each LineVT In VT Do                                                           
		
		NumbeOfParameter = NumbeOfParameter + 1;
		
		CaseText = CaseText + "WHEN ChartOfAccounts.Ref = &Ref_" + NumbeOfParameter + " THEN &Balance_" + NumbeOfParameter + " ";
		
	EndDo;
	
	CaseText = ?(ValueIsFilled(CaseText), CaseText, "WHEN TRUE THEN 0");	
	
	//3.
	List.QueryText = "SELECT
	               |	ChartOfAccounts.Ref AS Ref,
				   |	ChartOfAccounts.Code AS Code,
				   |	ChartOfAccounts.Parent.Code AS Parent,
				   |	ChartOfAccounts.ReclassAccount AS Reclass,
				   |	ChartOfAccounts.CreditCard AS CreditCard,
				   |	ChartOfAccounts.Description AS Description,
				   |	ChartOfAccounts.AccountType AS AccountType,
				   |	ChartOfAccounts.Category1099 AS Category1099,
	               |	ChartOfAccounts.gc_rectype AS gc_rectype,
	               |	ChartOfAccounts.gc_totlev AS gc_totlev,
	               |	CASE
	               |		" + CaseText + "
	               |		ELSE 0
	               |	END AS Balance
	               |FROM
	               |	ChartOfAccounts.ChartOfAccounts AS ChartOfAccounts";
				   
	//4.
	NumbeOfParameter = 0;
	
	For Each LineVT In VT Do                                                           
		
		NumbeOfParameter = NumbeOfParameter + 1;
		
		List.Parameters.SetParameterValue("Ref_" + NumbeOfParameter, LineVT.Account);
		List.Parameters.SetParameterValue("Balance_" + NumbeOfParameter, LineVT.Balance);
	
	EndDo;
	
EndProcedure

&AtServerNoContext
Function GetTableBalance();
	
	ValueTable = New ValueTable();
	ValueTable.Columns.Add("Account");	
	ValueTable.Columns.Add("Balance");	
	
	Query = New Query;
	Query.Text = 
		"SELECT TOP 1
		|	ChartOfAccounts.Ref AS Account
		|INTO RetainedEarningsAccount
		|FROM
		|	ChartOfAccounts.ChartOfAccounts AS ChartOfAccounts
		|WHERE
		|	ChartOfAccounts.RetainedEarnings = TRUE
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	GeneralJournalBalancesAndTurnovers.Account AS Account,
		|	GeneralJournalBalancesAndTurnovers.Account.AccountType AS AccountAccountType,
		|	GeneralJournalBalancesAndTurnovers.AmountRCOpeningSplittedBalanceDr,
		|	GeneralJournalBalancesAndTurnovers.AmountRCOpeningSplittedBalanceCr,
		|	GeneralJournalBalancesAndTurnovers.AmountRCTurnoverDr,
		|	GeneralJournalBalancesAndTurnovers.AmountRCTurnoverCr,
		|	GeneralJournalBalancesAndTurnovers.AmountRCClosingSplittedBalanceDr,
		|	GeneralJournalBalancesAndTurnovers.AmountRCClosingSplittedBalanceCr
		|INTO BalancesAndTurnovers
		|FROM
		|	AccountingRegister.GeneralJournal.BalanceAndTurnovers(&BeginOfFiscalYear, &CurrentSessionDate, Auto, , , , ) AS GeneralJournalBalancesAndTurnovers
		|
		|INDEX BY
		|	Account,
		|	AccountAccountType
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	RetainedEarningsAccount.Account AS Account,
		|	BalancesAndTurnovers.AmountRCOpeningSplittedBalanceDr AS AmountRCOpeningSplittedBalanceDr,
		|	BalancesAndTurnovers.AmountRCOpeningSplittedBalanceCr AS AmountRCOpeningSplittedBalanceCr,
		|	0 AS AmountRCTurnoverDr,
		|	0 AS AmountRCTurnoverCr,
		|	BalancesAndTurnovers.AmountRCOpeningSplittedBalanceDr AS AmountRCClosingSplittedBalanceDr,
		|	BalancesAndTurnovers.AmountRCOpeningSplittedBalanceCr AS AmountRCClosingSplittedBalanceCr
		|INTO RetainedEarnings
		|FROM
		|	BalancesAndTurnovers AS BalancesAndTurnovers
		|		LEFT JOIN RetainedEarningsAccount AS RetainedEarningsAccount
		|		ON (TRUE)
		|WHERE
		|	BalancesAndTurnovers.AccountAccountType IN (VALUE(Enum.AccountTypes.Income), VALUE(Enum.AccountTypes.CostOfSales), VALUE(Enum.AccountTypes.Expense), VALUE(Enum.AccountTypes.OtherExpense), VALUE(Enum.AccountTypes.OtherIncome), VALUE(Enum.AccountTypes.IncomeTaxExpense))
		|
		|UNION ALL
		|
		|SELECT
		|	RetainedEarningsAccount.Account,
		|	BalancesAndTurnovers.AmountRCClosingSplittedBalanceDr,
		|	BalancesAndTurnovers.AmountRCClosingSplittedBalanceCr,
		|	0,
		|	0,
		|	BalancesAndTurnovers.AmountRCClosingSplittedBalanceDr,
		|	BalancesAndTurnovers.AmountRCClosingSplittedBalanceCr
		|FROM
		|	BalancesAndTurnovers AS BalancesAndTurnovers
		|		LEFT JOIN RetainedEarningsAccount AS RetainedEarningsAccount
		|		ON (TRUE)
		|WHERE
		|	BalancesAndTurnovers.Account.RetainedEarnings
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	RetainedEarnings.Account AS Account,
		|	VALUE(Enum.AccountTypes.Equity) AS AccountType,
		|	CASE
		|		WHEN SUM(RetainedEarnings.AmountRCOpeningSplittedBalanceDr) - SUM(RetainedEarnings.AmountRCOpeningSplittedBalanceCr) > 0
		|			THEN SUM(RetainedEarnings.AmountRCOpeningSplittedBalanceDr) - SUM(RetainedEarnings.AmountRCOpeningSplittedBalanceCr)
		|		ELSE 0
		|	END - CASE
		|		WHEN SUM(RetainedEarnings.AmountRCOpeningSplittedBalanceDr) - SUM(RetainedEarnings.AmountRCOpeningSplittedBalanceCr) < 0
		|			THEN -(SUM(RetainedEarnings.AmountRCOpeningSplittedBalanceDr) - SUM(RetainedEarnings.AmountRCOpeningSplittedBalanceCr))
		|		ELSE 0
		|	END AS Balance
		|FROM
		|	RetainedEarnings AS RetainedEarnings
		|
		|GROUP BY
		|	RetainedEarnings.Account
		|
		|UNION ALL
		|
		|SELECT
		|	BalancesAndTurnovers.Account,
		|	BalancesAndTurnovers.AccountAccountType,
		|	CASE
		|		WHEN BalancesAndTurnovers.AccountAccountType IN (VALUE(Enum.AccountTypes.Income), VALUE(Enum.AccountTypes.CostOfSales), VALUE(Enum.AccountTypes.Expense), VALUE(Enum.AccountTypes.OtherExpense), VALUE(Enum.AccountTypes.OtherIncome), VALUE(Enum.AccountTypes.IncomeTaxExpense))
		|			THEN BalancesAndTurnovers.AmountRCTurnoverDr
		|		ELSE BalancesAndTurnovers.AmountRCClosingSplittedBalanceDr
		|	END - CASE
		|		WHEN BalancesAndTurnovers.AccountAccountType IN (VALUE(Enum.AccountTypes.Income), VALUE(Enum.AccountTypes.CostOfSales), VALUE(Enum.AccountTypes.Expense), VALUE(Enum.AccountTypes.OtherExpense), VALUE(Enum.AccountTypes.OtherIncome), VALUE(Enum.AccountTypes.IncomeTaxExpense))
		|			THEN BalancesAndTurnovers.AmountRCTurnoverCr
		|		ELSE BalancesAndTurnovers.AmountRCClosingSplittedBalanceCr
		|	END
		|FROM
		|	BalancesAndTurnovers AS BalancesAndTurnovers
		|WHERE
		|	NOT BalancesAndTurnovers.Account.RetainedEarnings
		|	AND CASE
		|			WHEN BalancesAndTurnovers.AccountAccountType IN (VALUE(Enum.AccountTypes.Income), VALUE(Enum.AccountTypes.CostOfSales), VALUE(Enum.AccountTypes.Expense), VALUE(Enum.AccountTypes.OtherExpense), VALUE(Enum.AccountTypes.OtherIncome), VALUE(Enum.AccountTypes.IncomeTaxExpense))
		|					AND BalancesAndTurnovers.AmountRCTurnoverDr = 0
		|					AND BalancesAndTurnovers.AmountRCTurnoverCr = 0
		|				THEN FALSE
		|			ELSE TRUE
		|		END
		|TOTALS
		|	SUM(Balance)
		|BY
		|	Account ONLY HIERARCHY";
		
	CurrentSessionDate = CurrentSessionDate();
	Query.SetParameter("BeginOfFiscalYear" , GeneralFunctions.GetBeginOfFiscalYear(CurrentSessionDate));
	Query.SetParameter("CurrentSessionDate" , CurrentSessionDate);
	
	ValueTree = Query.Execute().Unload(QueryResultIteration.ByGroupsWithHierarchy);
	
	RecursionRowOfTree(ValueTree.Rows, ValueTable);
	
	Return ValueTable;
	
EndFunction

&AtServerNoContext
Procedure RecursionRowOfTree(Rows, VT)
	
	For Each Row In Rows Do
		
		If VT.Find(Row.Account, "Account") = Undefined Then
			
			NewRow = VT.Add();
			NewRow.Account = Row.Account;
			NewRow.Balance = Row.Balance;
			
			RecursionRowOfTree(Row.Rows, VT);
			
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region PRIVATE_IMPLEMENTATION

&AtServer
Function ProcessDetailsAtServer(Val ReportRF, Val ResultRF, Val DetailsDataRF, Val UUID_RF)
	
	ReportObject = FormDataToValue(ReportRF, Type("ReportObject.GeneralLedger"));
	ResultRF.Clear();                                                                              
	ReportObject.ComposeResult(ResultRF, DetailsDataRF);                                  
	Address = PutToTempStorage(DetailsDataRF, UUID_RF); 
	
	Return New Structure("Result, DetailsData", ResultRF, Address);       
	
EndFunction

&AtServerNoContext
Function ListIsEmpty()
	
	Query = New Query;
	Query.Text = "SELECT
	             |	ChartOfAccounts.Ref AS Ref
	             |FROM
	             |	ChartOfAccounts.ChartOfAccounts AS ChartOfAccounts";
	
	If Query.Execute().Select().Count() = 0 Then
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

#EndRegion