&AtServer
Function GetDate()
	
	Return CurrentSessionDate();
	
EndFunction

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	RunInventoryItemQuickReport(CommandParameter);
EndProcedure

&AtClient
Procedure RunInventoryItemQuickReport(Item)
	
	ParametersStructure = New Structure;
	ParametersStructure.Insert("GenerateOnOpen", True); 
	ReportForm = GetForm("Report.InventoryItemQuickReport.Form.ReportForm", ParametersStructure,, True);
	
	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	ReportFormSettings = ReportForm.Report.SettingsComposer.Settings;
	
	PeriodSettingID   = ReportFormSettings.DataParameters.Items.Find("Period").UserSettingID;
	LocationSettingID = ReportFormSettings.DataParameters.Items.Find("Location").UserSettingID;
	ItemSettingID     = ReportFormSettings.DataParameters.Items.Find("Item").UserSettingID;
	
	UserSettings = ReportForm.Report.SettingsComposer.UserSettings.Items;
	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	//Period
	SessionDate = GetDate();
	UserSettings.Find(PeriodSettingID).Value = New StandardPeriod(BegOfMonth(SessionDate), EndOfMonth(SessionDate));
	UserSettings.Find(PeriodSettingID).Use = True;
	
	//Location
	UserSettings.Find(LocationSettingID).Value = PredefinedValue("Catalog.Locations.EmptyRef");
	UserSettings.Find(LocationSettingID).Use = False;
	
	//Item
	//UserSettings.Find(ItemSettingID).Value = Items.List.CurrentRow;
	UserSettings.Find(ItemSettingID).Value = Item;
	UserSettings.Find(ItemSettingID).Use = True;
	
	ReturnStructure = ProcessDetailsAtServer(ReportForm.Report, ReportForm.Result, ReportForm.DetailsData, ReportForm.UUID, "ReportObject.InventoryItemQuickReport");

	ReportForm.Result = ReturnStructure.Result;
	ReportForm.DetailsData = ReturnStructure.DetailsData;
	
	ReportForm.Open();
	
EndProcedure

&AtServer
Function ProcessDetailsAtServer(Val ReportRF, Val ResultRF, Val DetailsDataRF, Val UUID_RF, ObjectTypeName)
	
	ReportObject = FormDataToValue(ReportRF, Type(ObjectTypeName));
	ResultRF.Clear();                                                                              
	ReportObject.ComposeResult(ResultRF, DetailsDataRF);                                  
	Address = PutToTempStorage(DetailsDataRF, UUID_RF); 
	
	Return New Structure("Result, DetailsData", ResultRF, Address);       
	
EndFunction