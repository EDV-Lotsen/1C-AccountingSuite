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
Procedure ResultDetailProcessing(Item, Details, StandardProcessing)
	
	Structure = GetDetailsAtServer(Details);
	
	//NetIncome///
	If Structure <> Undefined And Structure.NetIncome <> Undefined Then
		
		StandardProcessing = False;
		
		ParametersStructure = New Structure;
		ParametersStructure.Insert("GenerateOnOpen", True); 
		ParametersStructure.Insert("VariantKey", "Total");
		
	    ReportForm = GetForm("Report.IncomeStatement.Form.ReportForm", ParametersStructure,, True);
		
		///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		ReportFormSettings = ReportForm.Report.SettingsComposer.Settings;
		PeriodSettingID   = ReportFormSettings.DataParameters.Items.Find("Period").UserSettingID;
		UserSettings = ReportForm.Report.SettingsComposer.UserSettings.Items;	
		///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		
		Period = New StandardPeriod;
			
		If Structure.Period <> Undefined Then
			Period = Structure.Period; 		
		Else			
			
			ReportFormSettingsHere = ThisForm.Report.SettingsComposer.Settings;
			PeriodSettingIDHere = ReportFormSettingsHere.DataParameters.Items.Find("Period").UserSettingID;
			UserSettingsHere = ThisForm.Report.SettingsComposer.UserSettings.Items;
			
			If UserSettingsHere.Find(PeriodSettingIDHere).Use Then 
				PeriodHere = UserSettingsHere.Find(PeriodSettingIDHere).Value;
				Period.StartDate = BegOfYear(PeriodHere.EndDate);
				Period.EndDate = PeriodHere.EndDate; 
			Else
				Period.StartDate = '39990101';
				Period.EndDate = '39991231'; 
			EndIf;
			
		EndIf;
		
		UserSettings.Find(PeriodSettingID).Value = Period;
		UserSettings.Find(PeriodSettingID).Use = True;
						
		ReturnStructure = ProcessDetailsAtServer(ReportForm.Report, ReportForm.Result, ReportForm.DetailsData, ReportForm.UUID, "IncomeStatement");
		ReportForm.Result = ReturnStructure.Result;
		ReportForm.DetailsData = ReturnStructure.DetailsData;
		
		ReportForm.Open();
		
	//Account///
	ElsIf Structure <> Undefined And Structure.Account <> Undefined Then
		
		StandardProcessing = False;
		
		ParametersStructure = New Structure;
		ParametersStructure.Insert("GenerateOnOpen", True); 
		ParametersStructure.Insert("VariantKey", "Default");
		
	    ReportForm = GetForm("Report.GeneralLedger.Form.ReportForm", ParametersStructure,, True);
		
		///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		ReportFormSettings = ReportForm.Report.SettingsComposer.Settings;
		
		//Period
		PeriodSettingID   = ReportFormSettings.DataParameters.Items.Find("Period").UserSettingID;
		
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
		If Structure.Period <> Undefined Then
			UserSettings.Find(PeriodSettingID).Value = Structure.Period;
			UserSettings.Find(PeriodSettingID).Use = True;
		Else			
			
			ReportFormSettingsHere = ThisForm.Report.SettingsComposer.Settings;
			PeriodSettingIDHere = ReportFormSettingsHere.DataParameters.Items.Find("Period").UserSettingID;
			UserSettingsHere = ThisForm.Report.SettingsComposer.UserSettings.Items;
			
			UserSettings.Find(PeriodSettingID).Value = UserSettingsHere.Find(PeriodSettingIDHere).Value;
			UserSettings.Find(PeriodSettingID).Use = UserSettingsHere.Find(PeriodSettingIDHere).Use;
		EndIf;
		
		//Item
		UserSettings.Find(AccountSettingID).RightValue = Structure.Account;
		UserSettings.Find(AccountSettingID).ComparisonType = ?(Structure.Hierarchy, DataCompositionComparisonType.InHierarchy, DataCompositionComparisonType.Equal); 
		UserSettings.Find(AccountSettingID).Use = True; 
		///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		
		ReturnStructure = ProcessDetailsAtServer(ReportForm.Report, ReportForm.Result, ReportForm.DetailsData, ReportForm.UUID, "GeneralLedger");
		ReportForm.Result = ReturnStructure.Result;
		ReportForm.DetailsData = ReturnStructure.DetailsData;
		
		ReportForm.Open();
		
	EndIf;	
	
EndProcedure

&AtServer
Function GetDetailsAtServer(Details)
	
	If TypeOf(Details) = Type("DataCompositionDetailsID") Then 
		
		Structure = New Structure;
		Structure.Insert("NetIncome", Undefined);
		Structure.Insert("Period", Undefined);
		Structure.Insert("Account", Undefined);
		Structure.Insert("Hierarchy", Undefined);
		
		Data = GetFromTempStorage(DetailsData);	
		
		//1.
		For Each Field In Data.Items.Get(Details).GetFields() Do
			
			If Field.Field = "NetIncome" Then 
				Structure.Insert("NetIncome", Field.Value);
			EndIf;
			
		EndDo;
		
		//2.
		For Each ArrayItem In Data.Items.Get(Details).GetParents() Do
			
			If TypeOf(ArrayItem) = Type("DataCompositionFieldDetailsItem") Then
				
				For Each Field In ArrayItem.GetFields() Do
					
					If Field.Field = "YearPeriod" Then 
						
						Structure.Insert("Period", New StandardPeriod(BegOfYear(Field.Value), EndOfYear(Field.Value)));
						
					ElsIf Field.Field = "QuarterPeriod" Then 
						
						If Structure.NetIncome <> Undefined Then
							Structure.Insert("Period", New StandardPeriod(BegOfYear(Field.Value), EndOfQuarter(Field.Value)));
						Else
							Structure.Insert("Period", New StandardPeriod(BegOfQuarter(Field.Value), EndOfQuarter(Field.Value)));
						EndIf;
						
					ElsIf Field.Field = "MonthPeriod" Then 
						
						If Structure.NetIncome <> Undefined Then
							Structure.Insert("Period", New StandardPeriod(BegOfYear(Field.Value), EndOfMonth(Field.Value)));
						Else
							Structure.Insert("Period", New StandardPeriod(BegOfMonth(Field.Value), EndOfMonth(Field.Value)));
						EndIf;
						
					ElsIf Field.Field = "WeekPeriod" Then 
						
						If Structure.NetIncome <> Undefined Then
							Structure.Insert("Period", New StandardPeriod(BegOfYear(Field.Value), EndOfWeek(Field.Value)));
						Else
							Structure.Insert("Period", New StandardPeriod(BegOfWeek(Field.Value), EndOfWeek(Field.Value)));
						EndIf;
						
					ElsIf Field.Field = "DayPeriod" Then
						
						If Structure.NetIncome <> Undefined Then
							Structure.Insert("Period", New StandardPeriod(BegOfYear(Field.Value), EndOfDay(Field.Value)));
						Else
							Structure.Insert("Period", New StandardPeriod(BegOfDay(Field.Value), EndOfDay(Field.Value)));
						EndIf;
						
					ElsIf Field.Field = "Account" Then 
						Structure.Insert("Account", Field.Value); 
						Structure.Insert("Hierarchy", Field.Hierarchy); 
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
Function ProcessDetailsAtServer(Val ReportRF, Val ResultRF, Val DetailsDataRF, Val UUID_RF, NameReport)
	
	ReportObject = FormDataToValue(ReportRF, Type("ReportObject." + NameReport));
	ResultRF.Clear();                                                                              
	ReportObject.ComposeResult(ResultRF, DetailsDataRF);                                  
	Address = PutToTempStorage(DetailsDataRF, UUID_RF); 
	
	Return New Structure("Result, DetailsData", ResultRF, Address);       
	
EndFunction

&AtClient
Procedure Excel(Command)
	
	Structure = GeneralFunctions.GetExcelFile("Balance sheet", Result);
	
	GetFile(Structure.Address, Structure.FileName, True); 

EndProcedure

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

&AtServer
Procedure ModifiedStatePresentation()
	
	Items.Result.StatePresentation.Visible = True;
	Items.Result.StatePresentation.Text = "Report not generated. Click ""Run report"" to obtain a report.";
	Items.Result.StatePresentation.AdditionalShowMode = AdditionalShowMode.Irrelevance;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)	
	
	Variant = CurrentVariantDescription;
	
	GeneralFunctions.ChangePeriodIntoUserSettings(ThisForm.Report.SettingsComposer, PeriodStartDate, PeriodEndDate);
	
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
