
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

