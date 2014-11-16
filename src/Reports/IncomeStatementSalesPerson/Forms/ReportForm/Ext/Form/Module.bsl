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
	
	Variant = CurrentVariantDescription;
	
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
Procedure VariantOnChange(Item)
	
	CurrentVariantDescription = Variant;
	SetCurrentVariant(CurrentVariantDescription);
	
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
	
	Structure = GeneralFunctions.GetExcelFile("Sales by rep", Result);
	
	GetFile(Structure.Address, Structure.FileName, True); 

EndProcedure

&AtClient
Procedure ResultDetailProcessing(Item, Details, StandardProcessing)
	
	Structure = GetDetailsAtServer(Details);
	
	If Structure <> Undefined And Structure.SalesPerson <> Undefined Then
		
		StandardProcessing = False;
		
		ParametersStructure = New Structure;
		ParametersStructure.Insert("GenerateOnOpen", True); 
	    ReportForm = GetForm("Report.IncomeStatementSalesPersonDetail.Form.ReportForm", ParametersStructure,, True);
		
		///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		ReportFormSettings = ReportForm.Report.SettingsComposer.Settings;
		
		PeriodSettingID = ReportFormSettings.DataParameters.Items.Find("Period").UserSettingID;
		
		For Each Filter In ReportFormSettings.Filter.Items Do
			
			If Filter.UserSettingPresentation = "Sales person" Then 
				SalesPersonSettingID = Filter.UserSettingID;
			EndIf;
			
		EndDo;
		
		UserSettings = ReportForm.Report.SettingsComposer.UserSettings.Items;
		
		//////////////////////////////////
		ReportFormSettingsHere = ThisForm.Report.SettingsComposer.Settings;
		
		PeriodSettingIDHere = ReportFormSettingsHere.DataParameters.Items.Find("Period").UserSettingID;
		
		UserSettingsHere = ThisForm.Report.SettingsComposer.UserSettings.Items;
		///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		
		//Period
		If Structure.Period <> Undefined Then
			UserSettings.Find(PeriodSettingID).Value = Structure.Period;
			UserSettings.Find(PeriodSettingID).Use = True;
		Else
			UserSettings.Find(PeriodSettingID).Value = UserSettingsHere.Find(PeriodSettingIDHere).Value;
			UserSettings.Find(PeriodSettingID).Use = UserSettingsHere.Find(PeriodSettingIDHere).Use;
		EndIf;
		
		//Item
		If Structure.SalesPerson <> Undefined Then
			UserSettings.Find(SalesPersonSettingID).Use = True;
			UserSettings.Find(SalesPersonSettingID).ComparisonType = DataCompositionComparisonType.Equal;
			UserSettings.Find(SalesPersonSettingID).RightValue = Structure.SalesPerson;
		Else 
			UserSettings.Find(SalesPersonSettingID).Use = False;
			UserSettings.Find(SalesPersonSettingID).ComparisonType = DataCompositionComparisonType.Equal;
			UserSettings.Find(SalesPersonSettingID).RightValue = PredefinedValue("Catalog.SalesPeople.EmptyRef");
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
		Structure.Insert("SalesPerson", Undefined);
		Structure.Insert("Period", Undefined);
		
		Data = GetFromTempStorage(DetailsData);	
		
		For Each ArrayItem In Data.Items.Get(Details).GetParents() Do
			
			If TypeOf(ArrayItem) = Type("DataCompositionFieldDetailsItem") Then
				
				For Each Field In ArrayItem.GetFields() Do
					
					If Field.Field = "SalesPerson" Then 
						
						Structure.Insert("SalesPerson", Field.Value);
						
					ElsIf Field.Field = "YearPeriod" Then 
						
						Structure.Insert("Period", New StandardPeriod(BegOfYear(Field.Value), EndOfYear(Field.Value)));
						
					ElsIf Field.Field = "QuarterPeriod" Then 
						
						Structure.Insert("Period", New StandardPeriod(BegOfQuarter(Field.Value), EndOfQuarter(Field.Value)));
						
					ElsIf Field.Field = "MonthPeriod" Then 
						
						Structure.Insert("Period", New StandardPeriod(BegOfMonth(Field.Value), EndOfMonth(Field.Value)));
						
					ElsIf Field.Field = "WeekPeriod" Then 
						
						Structure.Insert("Period", New StandardPeriod(BegOfWeek(Field.Value), EndOfWeek(Field.Value)));
						
					ElsIf Field.Field = "DayPeriod" Then
						
						Structure.Insert("Period", New StandardPeriod(BegOfDay(Field.Value), EndOfDay(Field.Value)));
						
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
	
	ReportObject = FormDataToValue(ReportRF, Type("ReportObject.IncomeStatementSalesPersonDetail"));
	ResultRF.Clear();                                                                              
	ReportObject.ComposeResult(ResultRF, DetailsDataRF);                                  
	Address = PutToTempStorage(DetailsDataRF, UUID_RF); 
	
	Return New Structure("Result, DetailsData", ResultRF, Address);       
	
EndFunction
