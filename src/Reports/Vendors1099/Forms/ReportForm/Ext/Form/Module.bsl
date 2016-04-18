
&AtClient
Procedure Create(Command)
	
	GenerateCSVReport();
	
	ComposeResult();
	
	Try
		CurParameters = New Structure("ObjectTypeID",ThisForm.FormName);
		CommonUseClient.ApplyPrintFormSettings(Result,CurParameters);
	Except
	EndTry;
	
EndProcedure

&AtClient
Procedure GetExcel(Command)
	
	Structure = GeneralFunctions.GetExcelFile("Vendors 1099", Result);
	
	GetFile(Structure.Address, Structure.FileName, True); 
	
EndProcedure

&AtClient
Procedure GetCSV(Command)
	
	Structure = GeneralFunctions.GetCSVFile("Vendors 1099", ResultCSV);
	
	GetFile(Structure.Address, Structure.FileName, True); 
	
EndProcedure

&AtServer
Procedure OnUpdateUserSettingSetAtServer(StandardProcessing)
	
	ModifiedStatePresentation();
	
EndProcedure

&AtServer
Procedure ModifiedStatePresentation()
	
	Items.Result.StatePresentation.Visible = True;
	Items.Result.StatePresentation.Text = "Report not generated. Click ""Run report"" to obtain a report.";
	Items.Result.StatePresentation.AdditionalShowMode = AdditionalShowMode.Irrelevance;
	
EndProcedure

&AtServer
Procedure GenerateCSVReport()
	
	MainDataCompositionSchema = Reports.Vendors1099.GetTemplate("List1099");
	
	DataCompositionSettingsComposer = New DataCompositionSettingsComposer;
	DataCompositionAvailableSettingsSource = New DataCompositionAvailableSettingsSource(MainDataCompositionSchema);
	DataCompositionSettingsComposer.Initialize(DataCompositionAvailableSettingsSource);
	DataCompositionSettingsComposer.LoadSettings(MainDataCompositionSchema.SettingVariants.Find("CSV").Settings);
	
	//
	SettingsCSV         = DataCompositionSettingsComposer.Settings;
	UserSettingsCSV     = DataCompositionSettingsComposer.UserSettings.Items;
	
	TaxYearSettingIDCSV     = SettingsCSV.DataParameters.Items.Find("TaxYear").UserSettingID;
	ModeSettingIDCSV        = SettingsCSV.DataParameters.Items.Find("Mode").UserSettingID;
		
	SettingsDefault     = Report.SettingsComposer.Settings;
	UserSettingsDefault = Report.SettingsComposer.UserSettings.Items;

	TaxYearSettingIDDefault = SettingsDefault.DataParameters.Items.Find("TaxYear").UserSettingID;
	ModeSettingIDDefault    = SettingsDefault.DataParameters.Items.Find("Mode").UserSettingID;	
	
	UserSettingsCSV.Find(TaxYearSettingIDCSV).Value = UserSettingsDefault.Find(TaxYearSettingIDDefault).Value;
	UserSettingsCSV.Find(TaxYearSettingIDCSV).Use   = UserSettingsDefault.Find(TaxYearSettingIDDefault).Use;
	
	UserSettingsCSV.Find(ModeSettingIDCSV).Value    = UserSettingsDefault.Find(ModeSettingIDDefault).Value;
	UserSettingsCSV.Find(ModeSettingIDCSV).Use      = UserSettingsDefault.Find(ModeSettingIDDefault).Use;
	//
	
	Settings = DataCompositionSettingsComposer.GetSettings();
	
	DataCompositionDetailsData = New DataCompositionDetailsData;
	
	DataCompositionTemplateComposer = New DataCompositionTemplateComposer;
	                                                                                                                                     
	DataCompositionTemplate = DataCompositionTemplateComposer.Execute(MainDataCompositionSchema, Settings, DataCompositionDetailsData);
	
	DataCompositionProcessor = New DataCompositionProcessor;
	DataCompositionProcessor.Initialize(DataCompositionTemplate, , DataCompositionDetailsData);
	
	ResultCSV.Clear();
	
	DataCompositionResultSpreadsheetDocumentOutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	DataCompositionResultSpreadsheetDocumentOutputProcessor.SetDocument(ResultCSV);
	
	DataCompositionResultSpreadsheetDocumentOutputProcessor.Output(DataCompositionProcessor); 
	
EndProcedure

&AtClient
Procedure TaxYearOnChange(Item)
	
	ModifiedStatePresentation();
	
EndProcedure

&AtClient
Procedure ShowOnChange(Item)
	
	ModifiedStatePresentation();
	
EndProcedure
