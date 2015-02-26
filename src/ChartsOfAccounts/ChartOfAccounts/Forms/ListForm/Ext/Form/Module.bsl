
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

&AtServer
Function ProcessDetailsAtServer(Val ReportRF, Val ResultRF, Val DetailsDataRF, Val UUID_RF)
	
	ReportObject = FormDataToValue(ReportRF, Type("ReportObject.GeneralLedger"));
	ResultRF.Clear();                                                                              
	ReportObject.ComposeResult(ResultRF, DetailsDataRF);                                  
	Address = PutToTempStorage(DetailsDataRF, UUID_RF); 
	
	Return New Structure("Result, DetailsData", ResultRF, Address);       
	
EndFunction


&AtClient
Procedure ImportChartOfAccounts(Command)
	
	If ListIsEmpty() Then
		
		Notify = New NotifyDescription("ExcelFileUpload", ThisForm);
		
		BeginPutFile(Notify, "", "*.xls", True, ThisForm.UUID);
		
	Else
		
		ShowMessageBox(,NStr("en = 'This function available for the empty list only!'"));
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ExportChartOfAccounts(Command)
	
	Spreadsheet = New SpreadsheetDocument;
	ExportChartOfAccountsAtServer(Spreadsheet);
	
	Structure = GeneralFunctions.GetExcelFile("Chart of accounts", Spreadsheet);
	
	GetFile(Structure.Address, Structure.FileName, True); 
	
EndProcedure


#Region EXCEL

&AtClient
Procedure ExcelFileUpload(Result, Address, SelectedFileName, AdditionalParameters) Export
	
	If (Find(SelectedFileName, ".xls") = 0)
		And (Find(SelectedFileName, ".xlsx") = 0)
		And (Find(SelectedFileName, ".XLS") = 0)
		And (Find(SelectedFileName, ".XLSX") = 0)
		Then
		ShowMessageBox(, NStr("en = 'Please upload a valid Excel file (.xls, .xlsx)'"));
		Return;
	EndIf;
	
	If ValueIsFilled(Address) Then
		ShowUserNotification(NStr("en = 'Reading file with  Microsoft Excel...'"));
		
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
