&AtServer
Var OpeningReportForm; 

#Region EVENTS_HANDLERS

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	ThisIsDrillDown = False;
	If ValueIsFilled(Parameters.VariantKey) Then
		SetCurrentVariant(Parameters.VariantKey);
		ThisIsDrillDown = True;
		Items.Variant.Visible = False;
	EndIf;
	//If the report is opened by the user (not by a drilldown processing)
	If Not ThisIsDrillDown Then
		Variant = CurrentVariantKey;
		If Items.Variant.ChoiceList.FindByValue(Variant) = Undefined Then
			Variant = "Default";
			CurrentVariantKey = "Default";
			SetCurrentVariant(CurrentVariantKey);
		EndIf;
	Else
		SetCurrentVariant(CurrentVariantKey);
	EndIf;
	
	Items.PeriodVariant.ChoiceList.LoadValues(GeneralFunctions.GetCustomizedPeriodsList());
	
	If ThisIsDrillDown Then
		If Parameters.Filter.Property("MonthPeriod") Then
			PeriodStartDate = Parameters.Filter.MonthPeriod;
			PeriodEndDate 	= EndOfMonth(Parameters.Filter.MonthPeriod);
		ElsIf Parameters.Filter.Property("QuarterPeriod") Then
			PeriodStartDate = Parameters.Filter.QuarterPeriod;
			PeriodEndDate 	= EndOfQuarter(Parameters.Filter.QuarterPeriod);
		ElsIf Parameters.Filter.Property("HalfYearPeriod") Then
			PeriodStartDate = Parameters.Filter.HalfYearPeriod;
			PeriodEndDate 	= EndOfMonth(AddMonth(Parameters.Filter.HalfYearPeriod, 5));
		ElsIf Parameters.Filter.Property("YearPeriod") Then
			PeriodStartDate = Parameters.Filter.YearPeriod;
			PeriodEndDate 	= EndOfYear(Parameters.Filter.YearPeriod);
		Else //Set period values from user settings if passed as a parameter
			PeriodParameter = New DataCompositionParameter("Period");
			For Each USItem In Parameters.UserSettings.Items Do
				If TypeOf(USItem) = Type("DataCompositionSettingsParameterValue") Then
					If USItem.Parameter = PeriodParameter Then
						PeriodStartDate = USItem.Value.StartDate;
						PeriodEndDate	= USItem.Value.EndDate;
						Break;
					EndIf;
				EndIf;
			EndDo;
		EndIf;
	Else
		PeriodVariant = GeneralFunctions.GetDefaultPeriodVariant();
		GeneralFunctions.ChangeDatesByPeriod(PeriodVariant, PeriodStartDate, PeriodEndDate);
	EndIf;
	
	OpeningReportForm = True;
		
	If Parameters.GenerateOnOpen <> Undefined And Parameters.GenerateOnOpen Then
		GenerateOnOpen = True;
		Parameters.GenerateOnOpen = False;
	EndIf;
		
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If GenerateOnOpen Then
		CreateAtServer();
	Else
		GeneralFunctions.ChangePeriodIntoUserSettings(ThisForm.Report.SettingsComposer, PeriodStartDate, PeriodEndDate);
	EndIf;
	
EndProcedure

&AtServer
Procedure CreateAtServer()
	
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
	
	ModifiedStatePresentation();
		
EndProcedure

#EndRegion

#Region CONTROLS_EVENTS_HANDLERS

&AtClient
Procedure VariantOnChange(Item)
	
	//
	CurrentPeriodStartDate = PeriodStartDate; 
	CurrentPeriodEndDate   = PeriodEndDate;
	CurrentPeriodVariant   = PeriodVariant;
	
	CurrentVariantDescription = Variant;
	SetCurrentVariant(CurrentVariantDescription);
	
	PeriodStartDate = CurrentPeriodStartDate; 
	PeriodEndDate   = CurrentPeriodEndDate;
	PeriodVariant   = CurrentPeriodVariant;
	GeneralFunctions.ChangePeriodIntoUserSettings(ThisForm.Report.SettingsComposer, PeriodStartDate, PeriodEndDate);
	
	ModifiedStatePresentation();
		
EndProcedure

&AtClient
Procedure ResultDetailProcessing(Item, Details, StandardProcessing)
	If (CurrentVariantKey = "Default") Or (CurrentVariantKey = "ShowByQuarters")
		Or (CurrentVariantKey = "ShowByHalfYears") Or (CurrentVariantKey = "ShowByYears")
		Or (CurrentVariantKey = "TaxRatesAcrossAgencies") Then
				
		ParametersStructure = PrepareDrilldownParametersAtServer(Details, CurrentVariantKey);
	
		If ParametersStructure <> Undefined Then
			StandardProcessing = False;
			OpenForm("Report.SalesTaxOwed.Form.ReportForm", ParametersStructure,, True);
		EndIf;
				
	EndIf;
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

#EndRegion

#Region COMMANDS_HANDLERS

&AtClient
Procedure Create(Command)
	
	GeneralFunctions.ChangePeriodIntoUserSettings(ThisForm.Report.SettingsComposer, PeriodStartDate, PeriodEndDate);
	Report.SettingsComposer.LoadUserSettings(Report.SettingsComposer.UserSettings);
	
	ComposeResult();
Try
	CurParameters = New Structure("ObjectTypeID",ThisForm.FormName);
	CommonUseClient.ApplyPrintFormSettings(Result,CurParameters);
Except
EndTry
	
EndProcedure

&AtClient
Procedure Excel(Command)
	
	Structure = GeneralFunctions.GetExcelFile("Sales tax owed", Result);
	
	GetFile(Structure.Address, Structure.FileName, True); 

EndProcedure

#EndRegion

#Region PRIVATE_IMPLEMENTATION

&AtServer
Procedure ModifiedStatePresentation()
	
	Items.Result.StatePresentation.Visible = True;
	Items.Result.StatePresentation.Text = "Report not generated. Click ""Run report"" to obtain a report.";
	Items.Result.StatePresentation.AdditionalShowMode = AdditionalShowMode.Irrelevance;
	
EndProcedure

&AtServer
Function GetDetailsAtServer(Details)
	If TypeOf(Details) = Type("DataCompositionDetailsID") Then 
		
		ReturnStructure = New Structure;
	
		Data = GetFromTempStorage(DetailsData);	
		
		ReturnStructure = GetDetailsRecursively(Data.Items.Get(Details), ReturnStructure);
			
		return ReturnStructure;
		
	Else
		return Undefined;
	EndIf;
	
EndFunction

&AtServer
Function GetDetailsRecursively(DataCompositionDetail, ReturnStructure)
	
	For Each Field In DataCompositionDetail.GetFields() Do
		
		ReturnStructure.Insert(Field.Field, Field.Value);
			
	EndDo;

	For Each ArrayItem In DataCompositionDetail.GetParents() Do
		
		If TypeOf(ArrayItem) = Type("DataCompositionFieldDetailsItem") Then
			
			GetDetailsRecursively(ArrayItem, ReturnStructure);
			
		ElsIf TypeOf(ArrayItem) = Type("DataCompositionGroupDetailsItem") Then
			
			For Each DetailItem In ArrayItem.GetParents() Do
				GetDetailsRecursively(DetailItem, ReturnStructure);
			EndDo;
			
		EndIf;
	EndDo;	
	return ReturnStructure;
	
EndFunction

&AtServer
Function PrepareDrilldownParametersAtServer(Details, CurrentVariantKey)
	DetailsStructure = GetDetailsAtServer(Details);
	ParametersStructure = Undefined;
	If DetailsStructure <> Undefined Then 
		If DetailsStructure.Property("GrossSales") Or DetailsStructure.Property("TaxableSales")
			Or DetailsStructure.Property("TaxAmount") Or DetailsStructure.Property("Adjustments")
			Or DetailsStructure.Property("Payments") Or DetailsStructure.Property("Balance")
			Or DetailsStructure.Property("DetailedBalance") Or DetailsStructure.Property("TotalGrossSales")
			Or DetailsStructure.Property("TotalTaxableSales") Then
			StandardProcessing = False;
			
			Filter = New Structure();
			For Each DSElement In DetailsStructure Do
				If DSElement.Key = "GrossSales" Or DSElement.Key = "TaxableSales"
					Or DSElement.Key = "TaxAmount" Or DSElement.Key = "Adjustments"
					Or DSElement.Key = "Payments" Or DSElement.Key = "Balance" 
					Or DSElement.Key = "DetailedBalance" Or DSElement.Key = "TotalGrossSales"
					Or DSElement.Key = "TotalTaxableSales" Then
					Continue;
				EndIf;
				Filter.Insert(DSElement.Key, DSElement.Value);
			EndDo;
			//Append filter with fixed settings filter  
			If CurrentVariantKey = "TaxRatesAcrossAgencies" Then
				FixedSettingsFilter = Report.SettingsComposer.FixedSettings.Filter;
				For Each FilterItem In FixedSettingsFilter.Items Do
					If Filter.Property(String(FilterItem.LeftValue)) Then
						Continue;
					EndIf;
					Filter.Insert(String(FilterItem.LeftValue), FilterItem.RightValue);
				EndDo;
			EndIf;
			
			ParametersStructure = New Structure;
			ParametersStructure.Insert("GenerateOnOpen", True); 
			If CurrentVariantKey <> "TaxRatesAcrossAgencies" Then
				ParametersStructure.Insert("VariantKey", "TaxRatesAcrossAgencies");	
			Else
				ParametersStructure.Insert("VariantKey", "TransactionReport");	
			EndIf;
			ParametersStructure.Insert("Filter", Filter);
			//Adjust the Period for it to conform to the filter
			UserSettings = Report.SettingsComposer.UserSettings;
			DrillDownUserSettings = New DataCompositionUserSettings();
			PeriodUserSetting = Undefined;
			PeriodParameter = New DataCompositionParameter("Period");
			For Each USItem In UserSettings.Items Do
				DDUSItem = DrillDownUserSettings.Items.Add(TypeOf(USItem));
				If (TypeOf(DDUSItem) = Type("DataCompositionSettingsParameterValue")) And (CurrentVariantKey <> "TaxRatesAcrossAgencies") Then
					FillPropertyValues(DDUSItem, USItem,,"Value");
					If DDUSItem.Parameter = PeriodParameter Then
						PeriodUserSetting = DDUSItem;
						PeriodUserSetting.Value = New StandardPeriod();
						//When filter is not set for period, pass a user setting period
						If TypeOf(USItem.Value) = Type("StandardPeriod") Then
							PeriodUserSetting.Value = USItem.Value;
						EndIf;
					EndIf;
				Else
					FillPropertyValues(DDUSItem, USItem);
				EndIf;
			EndDo;
			
			//If PeriodUserSetting <> Undefined Then
			//	If Filter.Property("MonthPeriod") Then
			//		PeriodUserSetting.Value.Variant 	= StandardPeriodVariant.Custom;	
			//		PeriodUserSetting.Value.StartDate 	= Filter.MonthPeriod;
			//		PeriodUserSetting.Value.EndDate 	= EndOfMonth(Filter.MonthPeriod);
			//	ElsIf Filter.Property("QuarterPeriod") Then
			//		PeriodUserSetting.Value.Variant 	= StandardPeriodVariant.Custom;	
			//		PeriodUserSetting.Value.StartDate 	= Filter.QuarterPeriod;
			//		PeriodUserSetting.Value.EndDate 	= EndOfQuarter(Filter.QuarterPeriod);
			//	ElsIf Filter.Property("HalfYearPeriod") Then
			//		PeriodUserSetting.Value.Variant 	= StandardPeriodVariant.Custom;	
			//		PeriodUserSetting.Value.StartDate 	= Filter.HalfYearPeriod;
			//		PeriodUserSetting.Value.EndDate 	= EndOfMonth(AddMonth(Filter.HalfYearPeriod, 5));
			//	ElsIf Filter.Property("YearPeriod") Then
			//		PeriodUserSetting.Value.Variant 	= StandardPeriodVariant.Custom;	
			//		PeriodUserSetting.Value.StartDate 	= Filter.YearPeriod;
			//		PeriodUserSetting.Value.EndDate 	= EndOfYear(Filter.YearPeriod);
			//	EndIf;
			//EndIf;
			
			ParametersStructure.Insert("UserSettings", DrillDownUserSettings);
			
		EndIf;
	EndIf;
	
	return ParametersStructure;
EndFunction

#EndRegion