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
EndProcedure

#EndRegion

#Region CONTROLS_EVENTS_HANDLERS

&AtClient
Procedure VariantOnChange(Item)
	
	CurrentVariantDescription = Variant;
	SetCurrentVariant(CurrentVariantDescription);
	
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

#EndRegion

#Region TABULAR_SECTION_EVENTS_HANDLERS

#EndRegion

#Region COMMANDS_HANDLERS

&AtClient
Procedure Create(Command)
	ComposeResult();
EndProcedure

&AtClient
Procedure Excel(Command)
	
	FileName = "" + GetSystemTitle() + " - Sales tax owed.xlsx"; 
	GetFile(GetFileName(), FileName, True); 

EndProcedure


#EndRegion

#Region PRIVATE_IMPLEMENTATION

&AtServer
Function GetFileName()
	
	TemporaryFileName = GetTempFileName(".xlsx");
	
	Result.Write(TemporaryFileName, SpreadsheetDocumentFileType.XLSX);
	BinaryData = New BinaryData(TemporaryFileName);
	
	DeleteFiles(TemporaryFileName);
	
	Return PutToTempStorage(BinaryData);
	
EndFunction

&AtServerNoContext
Function GetSystemTitle()
	
	SystemTitle = Constants.SystemTitle.Get();
	
	NewSystemTitle = "";
	
	For i = 1 To StrLen(SystemTitle) Do
		
		Char = Mid(SystemTitle, i, 1);
		
		If Find("#&\/:*?""<>|.", Char) > 0 Then
			NewSystemTitle = NewSystemTitle + " ";	
		Else
			NewSystemTitle = NewSystemTitle + Char;	
		EndIf;
		
	EndDo;	
	
	Return NewSystemTitle;
	
EndFunction

&AtServer
Procedure ModifiedStatePresentation()
	
	Items.Result.StatePresentation.Visible = True;
	Items.Result.StatePresentation.Text = "Report not generated. Click ""Create Report"" to obtain a report.";
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
			Or DetailsStructure.Property("DetailedBalance") Then
			StandardProcessing = False;
			
			Filter = New Structure();
			For Each DSElement In DetailsStructure Do
				If DSElement.Key = "GrossSales" Or DSElement.Key = "TaxableSales"
					Or DSElement.Key = "TaxAmount" Or DSElement.Key = "Adjustments"
					Or DSElement.Key = "Payments" Or DSElement.Key = "Balance" 
					Or DSElement.Key = "DetailedBalance" Then
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
					EndIf;
				Else
					FillPropertyValues(DDUSItem, USItem);
				EndIf;
			EndDo;
			
			If PeriodUserSetting <> Undefined Then
				If Filter.Property("MonthPeriod") Then
					PeriodUserSetting.Value.Variant 	= StandardPeriodVariant.Custom;	
					PeriodUserSetting.Value.StartDate 	= Filter.MonthPeriod;
					PeriodUserSetting.Value.EndDate 	= EndOfMonth(Filter.MonthPeriod);
				ElsIf Filter.Property("QuarterPeriod") Then
					PeriodUserSetting.Value.Variant 	= StandardPeriodVariant.Custom;	
					PeriodUserSetting.Value.StartDate 	= Filter.QuarterPeriod;
					PeriodUserSetting.Value.EndDate 	= EndOfQuarter(Filter.QuarterPeriod);
				ElsIf Filter.Property("HalfYearPeriod") Then
					PeriodUserSetting.Value.Variant 	= StandardPeriodVariant.Custom;	
					PeriodUserSetting.Value.StartDate 	= Filter.HalfYearPeriod;
					PeriodUserSetting.Value.EndDate 	= EndOfMonth(AddMonth(Filter.HalfYearPeriod, 5));
				ElsIf Filter.Property("YearPeriod") Then
					PeriodUserSetting.Value.Variant 	= StandardPeriodVariant.Custom;	
					PeriodUserSetting.Value.StartDate 	= Filter.YearPeriod;
					PeriodUserSetting.Value.EndDate 	= EndOfYear(Filter.YearPeriod);
				EndIf;
			EndIf;
			
			ParametersStructure.Insert("UserSettings", DrillDownUserSettings);
			
		EndIf;
	EndIf;
	
	return ParametersStructure;
EndFunction

#EndRegion