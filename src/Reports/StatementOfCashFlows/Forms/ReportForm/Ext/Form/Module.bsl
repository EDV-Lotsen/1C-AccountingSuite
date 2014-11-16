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
	
	Structure = GetDetailsAtServer(Details);
	
	//1. NetIncome///
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
				Period.StartDate = PeriodHere.StartDate;
				Period.EndDate = PeriodHere.EndDate; 
			Else
				Period.StartDate = '00010101';
				Period.EndDate = '39991231'; 
			EndIf;
			
		EndIf;
		
		UserSettings.Find(PeriodSettingID).Value = Period;
		UserSettings.Find(PeriodSettingID).Use = True;
						
		ReturnStructure = ProcessDetailsNetIncomeAtServer(ReportForm.Report, ReportForm.Result, ReportForm.DetailsData, ReportForm.UUID, "IncomeStatement");
		ReportForm.Result = ReturnStructure.Result;
		ReportForm.DetailsData = ReturnStructure.DetailsData;
		
		ReportForm.Open();
		
	//2. the rest///
	ElsIf Details <> Undefined And TypeOf(Details) = Type("DataCompositionDetailsID") Then 
		
		ParametersStructure = New Structure;
		ParametersStructure.Insert("GenerateOnOpen", True); 
		ReportForm = GetForm("Report.StatementOfCashFlows.Form.ReportForm", ParametersStructure,, True);
		
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
		
	//3. ///
	ElsIf Details <> Undefined Then
		
		ShowValue(, Details);		
		
	EndIf;
	
EndProcedure

&AtServer
Function GetDetailsAtServer(Details)
	
	If TypeOf(Details) = Type("DataCompositionDetailsID") Then 
		
		Structure = New Structure;
		Structure.Insert("NetIncome", Undefined);
		Structure.Insert("Period", Undefined);
		
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
						
						//If Structure.NetIncome <> Undefined Then
						//	Structure.Insert("Period", New StandardPeriod(BegOfYear(Field.Value), EndOfQuarter(Field.Value)));
						//Else
						Structure.Insert("Period", New StandardPeriod(BegOfQuarter(Field.Value), EndOfQuarter(Field.Value)));
						//EndIf;
						
					ElsIf Field.Field = "MonthPeriod" Then 
						
						//If Structure.NetIncome <> Undefined Then
						//	Structure.Insert("Period", New StandardPeriod(BegOfYear(Field.Value), EndOfMonth(Field.Value)));
						//Else
						Structure.Insert("Period", New StandardPeriod(BegOfMonth(Field.Value), EndOfMonth(Field.Value)));
						//EndIf;
						
					ElsIf Field.Field = "WeekPeriod" Then 
						
						//If Structure.NetIncome <> Undefined Then
						//	Structure.Insert("Period", New StandardPeriod(BegOfYear(Field.Value), EndOfWeek(Field.Value)));
						//Else
						Structure.Insert("Period", New StandardPeriod(BegOfWeek(Field.Value), EndOfWeek(Field.Value)));
						//EndIf;
						
					ElsIf Field.Field = "DayPeriod" Then
						
						//If Structure.NetIncome <> Undefined Then
						//	Structure.Insert("Period", New StandardPeriod(BegOfYear(Field.Value), EndOfDay(Field.Value)));
						//Else
						Structure.Insert("Period", New StandardPeriod(BegOfDay(Field.Value), EndOfDay(Field.Value)));
						//EndIf;
						
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
Function ProcessDetailsNetIncomeAtServer(Val ReportRF, Val ResultRF, Val DetailsDataRF, Val UUID_RF, NameReport)
	
	ReportObject = FormDataToValue(ReportRF, Type("ReportObject." + NameReport));
	ResultRF.Clear();                                                                              
	ReportObject.ComposeResult(ResultRF, DetailsDataRF);                                  
	Address = PutToTempStorage(DetailsDataRF, UUID_RF); 
	
	Return New Structure("Result, DetailsData", ResultRF, Address);       
	
EndFunction


&AtServer
Function ProcessDetailsAtServer(Val ReportRF, Val ResultRF, Val DetailsDataRF, Val UUID_RF, Details)
	
	//1.
	MainDataCompositionSchema = Reports.StatementOfCashFlows.GetTemplate("StatementOfCashFlows");
	DataCompositionDetailsProcess = New DataCompositionDetailsProcess(DetailsData, New DataCompositionAvailableSettingsSource(MainDataCompositionSchema));	
	DataCompositionSettings = DataCompositionDetailsProcess.DrillDown(Details, New DataCompositionField("Recorder"));	
	
	//2.
	If DataCompositionSettings <> Undefined Then 
		
		ReportRF.SettingsComposer.LoadSettings(DataCompositionSettings);
		ResultRF.Clear();                                                                              

		ReportObject = FormDataToValue(ReportRF, Type("ReportObject.StatementOfCashFlows"));
		ReportObject.ComposeResult(ResultRF, DetailsDataRF);                                  
		Address = PutToTempStorage(DetailsDataRF, UUID_RF); 
		
		Return New Structure("Result, DetailsData", ResultRF, Address);    
		
	EndIf;
	
	Return Undefined;
	
EndFunction

&AtClient
Procedure Excel(Command)
	
	Structure = GeneralFunctions.GetExcelFile("Statement of cash flows", Result);
	
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
	
	//PerformanceMeasurementClientServer.StartTimeMeasurement("StatementOfCashFlows Create");
	
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
