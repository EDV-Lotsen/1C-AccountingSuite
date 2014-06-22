
&AtClient
Procedure ResultDetailProcessing(Item, Details, StandardProcessing)
	
	Structure = GetDetailsAtServer(Details);
	
	If Structure <> Undefined And (Structure.Item <> Undefined Or Structure.Location <> Undefined) Then
		
		StandardProcessing = False;
		
		ParametersStructure = New Structure;
		ParametersStructure.Insert("GenerateOnOpen", True); 
	    ReportForm = GetForm("Report.InventoryItemQuickReport.Form.ReportForm", ParametersStructure,, True);
		
		///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		ReportFormSettings = ReportForm.Report.SettingsComposer.Settings;
		
		PeriodSettingID   = ReportFormSettings.DataParameters.Items.Find("Period").UserSettingID;
		LocationSettingID = ReportFormSettings.DataParameters.Items.Find("Location").UserSettingID;
		ItemSettingID     = ReportFormSettings.DataParameters.Items.Find("Item").UserSettingID;
		
		UserSettings = ReportForm.Report.SettingsComposer.UserSettings.Items;
		
		//////////////////////////////////
		ReportFormSettingsHere = ThisForm.Report.SettingsComposer.Settings;
		
		PeriodSettingIDHere   = ReportFormSettingsHere.DataParameters.Items.Find("Period").UserSettingID;
		LocationSettingIDHere = ReportFormSettingsHere.DataParameters.Items.Find("Location").UserSettingID;
		//ItemSettingIDHere     = ReportFormSettingsHere.DataParameters.Items.Find("Item").UserSettingID;
		
		UserSettingsHere = ThisForm.Report.SettingsComposer.UserSettings.Items;
		///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		
		//Period
		UserSettings.Find(PeriodSettingID).Value = UserSettingsHere.Find(PeriodSettingIDHere).Value;
		UserSettings.Find(PeriodSettingID).Use = UserSettingsHere.Find(PeriodSettingIDHere).Use;
		
		//Location
		UserSettings.Find(LocationSettingID).Value = UserSettingsHere.Find(LocationSettingIDHere).Value;
		UserSettings.Find(LocationSettingID).Use = UserSettingsHere.Find(LocationSettingIDHere).Use;
		
		//Item
		If Structure.Item <> Undefined Then
			UserSettings.Find(ItemSettingID).Value = Structure.Item;
			UserSettings.Find(ItemSettingID).Use = True;
		Else 
			UserSettings.Find(ItemSettingID).Value = PredefinedValue("Catalog.Products.EmptyRef");
			UserSettings.Find(ItemSettingID).Use = False;
		EndIf;
		
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
		Structure.Insert("Location", Undefined);
		
		Data = GetFromTempStorage(DetailsData);	
		
		For Each ArrayItem In Data.Items.Get(Details).GetParents() Do
			
			If TypeOf(ArrayItem) = Type("DataCompositionFieldDetailsItem") Then
				
				For Each Field In ArrayItem.GetFields() Do
					
					If Field.Field = "Item" Then 
						Structure.Insert("Item", Field.Value);
					ElsIf Field.Field = "Location" Then 
						Structure.Insert("Location", Field.Value);
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
	
	ReportObject = FormDataToValue(ReportRF, Type("ReportObject.InventoryItemQuickReport"));
	ResultRF.Clear();                                                                              
	ReportObject.ComposeResult(ResultRF, DetailsDataRF);                                  
	Address = PutToTempStorage(DetailsDataRF, UUID_RF); 
	
	Return New Structure("Result, DetailsData", ResultRF, Address);       
	
EndFunction
