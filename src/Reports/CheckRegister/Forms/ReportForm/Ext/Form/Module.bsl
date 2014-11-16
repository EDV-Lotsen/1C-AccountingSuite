&AtServer
Var OpeningReportForm; 

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Items.PeriodVariant.ChoiceList.LoadValues(GeneralFunctions.GetCustomizedPeriodsList());
	PeriodVariant = GeneralFunctions.GetDefaultPeriodVariant();
	GeneralFunctions.ChangeDatesByPeriod(PeriodVariant, PeriodStartDate, PeriodEndDate);
	
	OpeningReportForm = True;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	GeneralFunctions.ChangePeriodIntoUserSettings(ThisForm.Report.SettingsComposer, PeriodStartDate, PeriodEndDate);
	ChangeFilterIntoUserSettings(ThisForm.Report.SettingsComposer, "BankAccount", Account);
	
EndProcedure

&AtClient
Procedure Create(Command)
	
	If Not ValueIsFilled(Account) Then
		
		MessOnError = New UserMessage();
		MessOnError.Field = "Account";
		MessOnError.Text  = "Field ""Account"" not filled";
		MessOnError.Message();
		
		Return;
		
	EndIf;
	
	GeneralFunctions.ChangePeriodIntoUserSettings(ThisForm.Report.SettingsComposer, PeriodStartDate, PeriodEndDate);
	ChangeFilterIntoUserSettings(ThisForm.Report.SettingsComposer, "BankAccount", Account);
	Report.SettingsComposer.LoadUserSettings(Report.SettingsComposer.UserSettings);
	
	ComposeResult();
	
EndProcedure

&AtClient
Procedure Excel(Command)
	
	Structure = GeneralFunctions.GetExcelFile("Check register", Result);
	
	GetFile(Structure.Address, Structure.FileName, True); 

EndProcedure

&AtClient
Procedure PeriodVariantOnChange(Item)
	
	GeneralFunctions.ChangeDatesByPeriod(PeriodVariant, PeriodStartDate, PeriodEndDate);
	GeneralFunctions.ChangePeriodIntoUserSettings(ThisForm.Report.SettingsComposer, PeriodStartDate, PeriodEndDate);
	ModifiedStatePresentation();
	
EndProcedure

&AtClient
Procedure PeriodStartDateOnChange(Item)
	
	If PeriodStartDate > PeriodEndDate Then
		PeriodStartDate = PeriodEndDate; 	
	EndIf;
	
	PeriodVariant = GeneralFunctions.GetCustomVariantName();
	GeneralFunctions.ChangePeriodIntoUserSettings(ThisForm.Report.SettingsComposer, PeriodStartDate, PeriodEndDate);
	ModifiedStatePresentation();
	
EndProcedure

&AtClient
Procedure PeriodEndDateOnChange(Item)
	
	If PeriodStartDate > PeriodEndDate Then
		PeriodStartDate = PeriodEndDate; 	
	EndIf;
	
	PeriodVariant = GeneralFunctions.GetCustomVariantName();
	GeneralFunctions.ChangePeriodIntoUserSettings(ThisForm.Report.SettingsComposer, PeriodStartDate, PeriodEndDate);
	ModifiedStatePresentation();
	
EndProcedure

&AtClient
Procedure AccountOnChange(Item)
	
	ChangeFilterIntoUserSettings(ThisForm.Report.SettingsComposer, "BankAccount", Account);
	ModifiedStatePresentation();
	
EndProcedure

&AtServer
Procedure ModifiedStatePresentation()
	
	Items.Result.StatePresentation.Visible = True;
	Items.Result.StatePresentation.Text = "Report not generated. Click ""Run report"" to obtain a report.";
	Items.Result.StatePresentation.AdditionalShowMode = AdditionalShowMode.Irrelevance;
	
EndProcedure

&AtServer
Procedure OnUpdateUserSettingSetAtServer(StandardProcessing)
	
	If OpeningReportForm <> Undefined And OpeningReportForm Then
		
	Else
		GeneralFunctions.ChangePeriodIntoReportForm(ThisForm.Report.SettingsComposer, PeriodVariant, PeriodStartDate, PeriodEndDate);
		ChangeFilterIntoReportForm(ThisForm.Report.SettingsComposer, "BankAccount", Account);
	EndIf;
	
EndProcedure

//---------------------------------------------------------------------------------------------------------------------

&AtServer
Procedure ChangeFilterIntoUserSettings(SettingsComposer, FilterName, FilterValue)
	
	ReportFormSettings = SettingsComposer.Settings;
	FilterSettingID   = ReportFormSettings.DataParameters.Items.Find(FilterName).UserSettingID;
	UserSettings = SettingsComposer.UserSettings.Items;
	
	UserSettings.Find(FilterSettingID).Value = FilterValue;
	UserSettings.Find(FilterSettingID).Use   = True;
	
	//ReportFormSettings = SettingsComposer.Settings;
	//
	//For Each Filter In ReportFormSettings.Filter.Items Do
	//	
	//	If Filter.UserSettingPresentation = FilterName Then
	//		FilterSettingID  = Filter.UserSettingID;
	//	EndIf;
	//	
	//EndDo;
	//
	//UserSettings = SettingsComposer.UserSettings.Items;
	//
	//UserSettings.Find(FilterSettingID).Use            = True;
	//UserSettings.Find(FilterSettingID).ComparisonType = DataCompositionComparisonType.Equal;
	//UserSettings.Find(FilterSettingID).RightValue     = FilterValue;
		
EndProcedure

&AtServer
Procedure ChangeFilterIntoReportForm(SettingsComposer, FilterName, FilterValue)
	
	ReportFormSettings = SettingsComposer.Settings;
	FilterSettingID = ReportFormSettings.DataParameters.Items.Find(FilterName).UserSettingID;
	UserSettings = SettingsComposer.UserSettings.Items;
	
	FilterValue = UserSettings.Find(FilterSettingID).Value;
	
EndProcedure
