
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// custom fields
	
	CF1Type = Constants.CF1Type.Get();
	CF2Type = Constants.CF2Type.Get();
	CF3Type = Constants.CF3Type.Get();
	CF4Type = Constants.CF4Type.Get();
	CF5Type = Constants.CF5Type.Get();
	
	If CF1Type = "None" Then
		Items.CF1Num.Visible = False;
		Items.CF1String.Visible = False;
	ElsIf CF1Type = "Number" Then
		Items.CF1Num.Visible = True;
		Items.CF1String.Visible = False;
		Items.CF1Num.Title = Constants.CF1Name.Get();
	ElsIf CF1Type = "String" Then
	    Items.CF1Num.Visible = False;
		Items.CF1String.Visible = True;
		Items.CF1String.Title = Constants.CF1Name.Get();
	ElsIf CF1Type = "" Then
		Items.CF1Num.Visible = False;
		Items.CF1String.Visible = False;
	EndIf;
	
	If CF2Type = "None" Then
		Items.CF2Num.Visible = False;
		Items.CF2String.Visible = False;
	ElsIf CF2Type = "Number" Then
		Items.CF2Num.Visible = True;
		Items.CF2String.Visible = False;
		Items.CF2Num.Title = Constants.CF2Name.Get();
	ElsIf CF2Type = "String" Then
	    Items.CF2Num.Visible = False;
		Items.CF2String.Visible = True;
		Items.CF2String.Title = Constants.CF2Name.Get();
	ElsIf CF2Type = "" Then
		Items.CF2Num.Visible = False;
		Items.CF2String.Visible = False;
	EndIf;
	
	If CF3Type = "None" Then
		Items.CF3Num.Visible = False;
		Items.CF3String.Visible = False;
	ElsIf CF3Type = "Number" Then
		Items.CF3Num.Visible = True;
		Items.CF3String.Visible = False;
		Items.CF3Num.Title = Constants.CF3Name.Get();
	ElsIf CF3Type = "String" Then
	    Items.CF3Num.Visible = False;
		Items.CF3String.Visible = True;
		Items.CF3String.Title = Constants.CF3Name.Get();
	ElsIf CF3Type = "" Then
		Items.CF3Num.Visible = False;
		Items.CF3String.Visible = False;
	EndIf;
	
	If CF4Type = "None" Then
		Items.CF4Num.Visible = False;
		Items.CF4String.Visible = False;
	ElsIf CF4Type = "Number" Then
		Items.CF4Num.Visible = True;
		Items.CF4String.Visible = False;
		Items.CF4Num.Title = Constants.CF4Name.Get();
	ElsIf CF4Type = "String" Then
	    Items.CF4Num.Visible = False;
		Items.CF4String.Visible = True;
		Items.CF4String.Title = Constants.CF4Name.Get();
	ElsIf CF4Type = "" Then
		Items.CF4Num.Visible = False;
		Items.CF4String.Visible = False;
	EndIf;

	If CF5Type = "None" Then
		Items.CF5Num.Visible = False;
		Items.CF5String.Visible = False;
	ElsIf CF5Type = "Number" Then
		Items.CF5Num.Visible = True;
		Items.CF5String.Visible = False;
		Items.CF5Num.Title = Constants.CF5Name.Get();
	ElsIf CF5Type = "String" Then
	    Items.CF5Num.Visible = False;
		Items.CF5String.Visible = True;
		Items.CF5String.Title = Constants.CF5Name.Get();
	ElsIf CF5Type = "" Then
		Items.CF5Num.Visible = False;
		Items.CF5String.Visible = False;
	EndIf;	
	
	// end custom fields

	QuantityFormat = GeneralFunctionsReusable.DefaultQuantityFormat();
	Items.QtyOnPO.Format               = QuantityFormat; 
	Items.QtyOnSO.Format               = QuantityFormat; 
	Items.QtyOnHand.Format             = QuantityFormat; 
	Items.QtyAvailableToPromise.Format = QuantityFormat; 
	
	// Update prices presentation.
	PriceFormat = GeneralFunctionsReusable.DefaultPriceFormat();
	Items.Price.Format = PriceFormat;
	
EndProcedure

&AtClient
Procedure RunInventoryItemQuickReport(Command)
	
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
	UserSettings.Find(ItemSettingID).Value = Items.List.CurrentRow;
	UserSettings.Find(ItemSettingID).Use = True;
	
	ReturnStructure = ProcessDetailsAtServer(ReportForm.Report, ReportForm.Result, ReportForm.DetailsData, ReportForm.UUID);
	ReportForm.Result = ReturnStructure.Result;
	ReportForm.DetailsData = ReturnStructure.DetailsData;
	
	ReportForm.Open();
	
EndProcedure

&AtServerNoContext
Function ProcessDetailsAtServer(Val ReportRF, Val ResultRF, Val DetailsDataRF, Val UUID_RF)
	
	ReportObject = FormDataToValue(ReportRF, Type("ReportObject.InventoryItemQuickReport"));
	ResultRF.Clear();                                                                              
	ReportObject.ComposeResult(ResultRF, DetailsDataRF);                                  
	Address = PutToTempStorage(DetailsDataRF, UUID_RF); 
	
	Return New Structure("Result, DetailsData", ResultRF, Address);       
	
EndFunction

&AtServerNoContext
Function GetDate()
	
	Return CurrentSessionDate();
	
EndFunction

