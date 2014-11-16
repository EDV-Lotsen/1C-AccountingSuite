&AtServer
Var OpeningReportForm; 

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.GenerateOnOpen <> Undefined And Parameters.GenerateOnOpen Then
		GenerateOnOpen = True;
	EndIf;
	
	Items.PeriodVariant.ChoiceList.LoadValues(GeneralFunctions.GetCustomizedPeriodsList());
	PeriodVariant = GeneralFunctions.GetDefaultPeriodVariant();
	GeneralFunctions.ChangeDatesByPeriod(PeriodVariant, PeriodStartDate, PeriodEndDate);
	
	OpeningReportForm = True;
			
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	Variant = CurrentVariantDescription;
	
	OnOpenAtServer();
	
EndProcedure

&AtServer
Procedure OnOpenAtServer()
	
	If GenerateOnOpen Then
		
		Items.Result.StatePresentation.Visible = False;
		Items.Result.StatePresentation.AdditionalShowMode = AdditionalShowMode.DontUse;
		
		GeneralFunctions.ChangePeriodIntoReportForm(ThisForm.Report.SettingsComposer, PeriodVariant, PeriodStartDate, PeriodEndDate);
		
	Else
		
		GeneralFunctions.ChangePeriodIntoUserSettings(ThisForm.Report.SettingsComposer, PeriodStartDate, PeriodEndDate);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ResultDetailProcessing(Item, Details, StandardProcessing)
	
	If Details <> Undefined And TypeOf(Details) = Type("DataCompositionDetailsID") Then 
		
		ParametersStructure = New Structure;
		ParametersStructure.Insert("GenerateOnOpen", True); 
		ReportForm = GetForm("Report.IncomeStatementCashBasis.Form.ReportForm", ParametersStructure,, True);
		
		///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		ReportFormSettings = ReportForm.Report.SettingsComposer.Settings;
		PeriodSettingID = ReportFormSettings.DataParameters.Items.Find("Period").UserSettingID;
		UserSettings = ReportForm.Report.SettingsComposer.UserSettings.Items;
		//////////////////////////////////
		ReportFormSettingsHere = ThisForm.Report.SettingsComposer.Settings;
		PeriodSettingIDHere = ReportFormSettingsHere.DataParameters.Items.Find("Period").UserSettingID;
		UserSettingsHere = ThisForm.Report.SettingsComposer.UserSettings.Items;
		
		//Period
		UserSettings.Find(PeriodSettingID).Value = UserSettingsHere.Find(PeriodSettingIDHere).Value;
		UserSettings.Find(PeriodSettingID).Use = UserSettingsHere.Find(PeriodSettingIDHere).Use;
		///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		
		ReturnStructure = ProcessDetailsAtServer(ReportForm.Report, ReportForm.Result, ReportForm.DetailsData, ReportForm.UUID, Details);
		
		If ReturnStructure <> Undefined Then
			
			StandardProcessing = False;
			
			ReportForm.Result = ReturnStructure.Result;
			ReportForm.DetailsData = ReturnStructure.DetailsData;
			
			ReportForm.Open();
			
		EndIf;
		
	ElsIf Details <> Undefined Then
		
		ShowValue(, Details);		
		
	EndIf;
	
EndProcedure

&AtServer
Function ProcessDetailsAtServer(Val ReportRF, Val ResultRF, Val DetailsDataRF, Val UUID_RF, Details)
	
	//1.
	MainDataCompositionSchema = Reports.IncomeStatementCashBasis.GetTemplate("IncomeStatement");
	DataCompositionDetailsProcess = New DataCompositionDetailsProcess(DetailsData, New DataCompositionAvailableSettingsSource(MainDataCompositionSchema));	
	DataCompositionSettings = DataCompositionDetailsProcess.DrillDown(Details, New DataCompositionField("Recorder"));	
	
	//2.
	If DataCompositionSettings <> Undefined Then 
		
		ReportRF.SettingsComposer.LoadSettings(DataCompositionSettings);
		ResultRF.Clear();                                                                              

		ReportObject = FormDataToValue(ReportRF, Type("ReportObject.IncomeStatementCashBasis"));
		ReportObject.ComposeResult(ResultRF, DetailsDataRF);                                  
		Address = PutToTempStorage(DetailsDataRF, UUID_RF); 
		
		Return New Structure("Result, DetailsData", ResultRF, Address);    
		
	EndIf;
	
	Return Undefined;
	
EndFunction

&AtClient
Procedure Excel(Command)
	
	Structure = GeneralFunctions.GetExcelFile("Income statement", Result);
	
	GetFile(Structure.Address, Structure.FileName, True); 

EndProcedure

&AtClient
Procedure VariantOnChange(Item)
	
	CurrentVariantDescription = Variant;
	SetCurrentVariant(CurrentVariantDescription);
	
	ModifiedStatePresentation();
		
EndProcedure

&AtServer
Procedure ModifiedStatePresentation()
	
	Items.Result.StatePresentation.Visible = True;
	Items.Result.StatePresentation.Text = "Report not generated. Click ""Run report"" to obtain a report.";
	Items.Result.StatePresentation.AdditionalShowMode = AdditionalShowMode.Irrelevance;
	
EndProcedure

&AtClient
Procedure Create(Command)
	
	GeneralFunctions.ChangePeriodIntoUserSettings(ThisForm.Report.SettingsComposer, PeriodStartDate, PeriodEndDate);
	Report.SettingsComposer.LoadUserSettings(Report.SettingsComposer.UserSettings);
	
	ComposeResult();
	
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

&AtServer
Procedure OnUpdateUserSettingSetAtServer(StandardProcessing)
	
	If OpeningReportForm <> Undefined And OpeningReportForm Then
		
	Else
		GeneralFunctions.ChangePeriodIntoReportForm(ThisForm.Report.SettingsComposer, PeriodVariant, PeriodStartDate, PeriodEndDate);
	EndIf;	
		
EndProcedure
