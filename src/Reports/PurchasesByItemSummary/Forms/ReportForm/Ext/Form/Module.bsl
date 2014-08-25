&AtServer
Var OpeningReportForm; 

&AtClient
Procedure ResultDetailProcessing(Item, Details, StandardProcessing)
	
	Structure = GetDetailsAtServer(Details);
	
	If Structure <> Undefined And Structure.Item <> Undefined Then
		
		StandardProcessing = False;
		
		ParametersStructure = New Structure;
		ParametersStructure.Insert("GenerateOnOpen", True); 
	    ReportForm = GetForm("Report.PurchasesByItemDetail.Form.ReportForm", ParametersStructure,, True);
		
		///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		ReportFormSettings = ReportForm.Report.SettingsComposer.Settings;
		
		PeriodSettingID   = ReportFormSettings.DataParameters.Items.Find("Period").UserSettingID;
		LocationSettingID = ReportFormSettings.DataParameters.Items.Find("Location").UserSettingID;
		
		For Each Filter In ReportFormSettings.Filter.Items Do
			
			If Filter.UserSettingPresentation = "Company" Then
				CompanySettingID  = Filter.UserSettingID;
			ElsIf Filter.UserSettingPresentation = "Item" Then 
				ItemSettingID     = Filter.UserSettingID;
			EndIf;
			
		EndDo;
		
		UserSettings = ReportForm.Report.SettingsComposer.UserSettings.Items;
		
		//////////////////////////////////
		ReportFormSettingsHere = ThisForm.Report.SettingsComposer.Settings;
		
		PeriodSettingIDHere   = ReportFormSettingsHere.DataParameters.Items.Find("Period").UserSettingID;
		LocationSettingIDHere = ReportFormSettingsHere.DataParameters.Items.Find("Location").UserSettingID;
		
		For Each Filter In ReportFormSettingsHere.Filter.Items Do
			
			If Filter.UserSettingPresentation = "Company" Then
				CompanySettingIDHere  = Filter.UserSettingID;
			EndIf;
		
		EndDo;
		
		UserSettingsHere = ThisForm.Report.SettingsComposer.UserSettings.Items;
		///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		
		//Period
		UserSettings.Find(PeriodSettingID).Value = UserSettingsHere.Find(PeriodSettingIDHere).Value;
		UserSettings.Find(PeriodSettingID).Use = UserSettingsHere.Find(PeriodSettingIDHere).Use;
		
		//Location
		UserSettings.Find(LocationSettingID).Value = UserSettingsHere.Find(LocationSettingIDHere).Value;
		UserSettings.Find(LocationSettingID).Use = UserSettingsHere.Find(LocationSettingIDHere).Use;
		
		////////////////////
		////////////////////
		
		//Company
		UserSettings.Find(CompanySettingID).Use = UserSettingsHere.Find(CompanySettingIDHere).Use;
		UserSettings.Find(CompanySettingID).ComparisonType = UserSettingsHere.Find(CompanySettingIDHere).ComparisonType;
		UserSettings.Find(CompanySettingID).RightValue = UserSettingsHere.Find(CompanySettingIDHere).RightValue;
				
		//Item
		If Structure.Item <> Undefined Then
			UserSettings.Find(ItemSettingID).Use = True;
			UserSettings.Find(ItemSettingID).ComparisonType = DataCompositionComparisonType.Equal;
			UserSettings.Find(ItemSettingID).RightValue = Structure.Item;
		Else 
			UserSettings.Find(ItemSettingID).Use = False;
			UserSettings.Find(ItemSettingID).ComparisonType = DataCompositionComparisonType.Equal;
			UserSettings.Find(ItemSettingID).RightValue = PredefinedValue("Catalog.Products.EmptyRef");
		EndIf;
		
		///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		
		ReturnStructure = ProcessDetailsAtServer(ReportForm.Report, ReportForm.Result, ReportForm.DetailsData, ReportForm.UUID);
		ReportForm.Result = ReturnStructure.Result;
		ReportForm.DetailsData = ReturnStructure.DetailsData;
		
		ReportForm.Open();
		
	EndIf;	
	
EndProcedure

&AtServer
Function GetDetailsAtServer(Details)
	
	If TypeOf(Details) = Type("DataCompositionDetailsID") Then 
		
		Structure = New Structure;
		Structure.Insert("Item", Undefined);
		
		Data = GetFromTempStorage(DetailsData);	
		
		For Each ArrayItem In Data.Items.Get(Details).GetParents() Do
			
			If TypeOf(ArrayItem) = Type("DataCompositionFieldDetailsItem") Then
				
				For Each Field In ArrayItem.GetFields() Do
					
					If Field.Field = "Item" Then 
						Structure.Insert("Item", Field.Value);
					EndIf;
					
				EndDo;
				
			EndIf;
			
		EndDo;
		
		Return Structure; 
		
	Else 
		
		Return Undefined; 
		
	EndIf;
	
EndFunction

&AtServer
Function ProcessDetailsAtServer(Val ReportRF, Val ResultRF, Val DetailsDataRF, Val UUID_RF)
	
	ReportObject = FormDataToValue(ReportRF, Type("ReportObject.PurchasesByItemDetail"));
	ResultRF.Clear();                                                                              
	ReportObject.ComposeResult(ResultRF, DetailsDataRF);                                  
	Address = PutToTempStorage(DetailsDataRF, UUID_RF); 
	
	Return New Structure("Result, DetailsData", ResultRF, Address);       
	
EndFunction

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
	
EndProcedure

&AtServer
Procedure ModifiedStatePresentation()
	
	Items.Result.StatePresentation.Visible = True;
	Items.Result.StatePresentation.Text = "Report not generated. Click ""Run report"" to obtain a report.";
	Items.Result.StatePresentation.AdditionalShowMode = AdditionalShowMode.Irrelevance;
	
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
Procedure Create(Command)
	
	GeneralFunctions.ChangePeriodIntoUserSettings(ThisForm.Report.SettingsComposer, PeriodStartDate, PeriodEndDate);
	Report.SettingsComposer.LoadUserSettings(Report.SettingsComposer.UserSettings);
	
	ComposeResult();
	
EndProcedure

&AtServer
Procedure OnUpdateUserSettingSetAtServer(StandardProcessing)
	
	If OpeningReportForm <> Undefined And OpeningReportForm Then
		
	Else
		GeneralFunctions.ChangePeriodIntoReportForm(ThisForm.Report.SettingsComposer, PeriodVariant, PeriodStartDate, PeriodEndDate);
	EndIf;	
		
EndProcedure

&AtClient
Procedure Excel(Command)
	
	Structure = GeneralFunctions.GetExcelFile("Purchases by item summary", Result);
	
	GetFile(Structure.Address, Structure.FileName, True); 

EndProcedure
