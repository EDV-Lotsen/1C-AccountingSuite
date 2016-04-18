&AtServer
Var OpeningReportForm; 

&AtServer
Procedure ModifiedStatePresentation()
	
	Items.Result.StatePresentation.Visible = True;
	Items.Result.StatePresentation.Text = "Report not generated. Click ""Run report"" to obtain a report.";
	Items.Result.StatePresentation.AdditionalShowMode = AdditionalShowMode.Irrelevance;
	
EndProcedure

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

//////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////

&AtClient
Procedure ResultDetailProcessing(Item, Details, StandardProcessing)
	
	Structure = GetDetailsAtServer(Details);
	
	If Structure <> Undefined And Structure.Account <> Undefined Then
		
		StandardProcessing = False;
		
		ParametersStructure = New Structure;
		ParametersStructure.Insert("GenerateOnOpen", True); 
		ParametersStructure.Insert("VariantKey", "Default");
		
		ReportForm = GetForm("Report.GeneralLedger.Form.ReportForm", ParametersStructure,, True);
		
		///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		ReportFormSettings = ReportForm.Report.SettingsComposer.Settings;
		UserSettings       = ReportForm.Report.SettingsComposer.UserSettings.Items;	
		
		//Period
		PeriodSettingID       = ReportFormSettings.DataParameters.Items.Find("Period").UserSettingID;
		
		//Account
		AccountField          = ReportFormSettings.Filter.FilterAvailableFields.Items.Find("AccountFilter").Field;
		AccountSettingID      = "";
		
		//AccountType
		AccountTypeField      = ReportFormSettings.Filter.FilterAvailableFields.Items.Find("AccountTypeFilter").Field;
		AccountTypeSettingID  = "";
		
		//Company
		CompanyField          = ReportFormSettings.Filter.FilterAvailableFields.Items.Find("CompanyFilter").Field;
		CompanySettingID      = "";
		
		//Customer
		CustomerField         = ReportFormSettings.Filter.FilterAvailableFields.Items.Find("CustomerFilter").Field;
		CustomerSettingID     = "";
		
		//Vendor
		VendorField           = ReportFormSettings.Filter.FilterAvailableFields.Items.Find("VendorFilter").Field;
		VendorSettingID       = "";
		
		//OrGroup
		OrGroupSettingID      = "";
		
		//AndGroup
		AndGroupSettingID     = "";
		
		For Each Item In ReportFormSettings.Filter.Items Do
			
			If TypeOf(Item) = Type("DataCompositionFilterItem") Then 
				
				If Item.LeftValue = AccountField Then
					AccountSettingID = Item.UserSettingID;
				ElsIf Item.LeftValue = AccountTypeField Then 
					AccountTypeSettingID = Item.UserSettingID;
				EndIf;
				
			ElsIf TypeOf(Item) = Type("DataCompositionFilterItemGroup") Then 
				
				If Item.UserSettingPresentation = "OR group (additional)" Then
					OrGroupSettingID = Item.UserSettingID; 
				EndIf;
				
				For Each GroupItem In Item.Items Do
					
					If TypeOf(GroupItem) = Type("DataCompositionFilterItem") Then 
						
						If GroupItem.LeftValue = CompanyField Then 
							CompanySettingID = GroupItem.UserSettingID;
						EndIf;
						
					ElsIf TypeOf(GroupItem) = Type("DataCompositionFilterItemGroup") Then
						
						If GroupItem.UserSettingPresentation = "AND group (additional)" Then
							AndGroupSettingID = GroupItem.UserSettingID; 
						EndIf;
						
						For Each GroupItemItems In GroupItem.Items Do
														
							If GroupItemItems.LeftValue = CustomerField Then 
								CustomerSettingID = GroupItemItems.UserSettingID;
							ElsIf GroupItemItems.LeftValue = VendorField Then 
								VendorSettingID = GroupItemItems.UserSettingID;
							EndIf;
							
						EndDo;
						
					EndIf;
					
				EndDo;
				
			EndIf;
			
		EndDo;
		
		///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		
		//AccountSettingID
		UserSettings.Find(AccountSettingID).RightValue         = PredefinedValue("ChartOfAccounts.ChartOfAccounts.EmptyRef");
		UserSettings.Find(AccountSettingID).ComparisonType     = DataCompositionComparisonType.Equal;
		UserSettings.Find(AccountSettingID).Use                = False;
		
		//AccountTypeSettingID
		UserSettings.Find(AccountTypeSettingID).RightValue     = PredefinedValue("Enum.AccountTypes.EmptyRef");
		UserSettings.Find(AccountTypeSettingID).ComparisonType = DataCompositionComparisonType.Equal;
		UserSettings.Find(AccountTypeSettingID).Use            = False;
		
		//CompanySettingID
		UserSettings.Find(CompanySettingID).RightValue         = PredefinedValue("Catalog.Companies.EmptyRef");
		UserSettings.Find(CompanySettingID).ComparisonType     = DataCompositionComparisonType.Equal;
		UserSettings.Find(CompanySettingID).Use                = False;
		
		//CustomerSettingID
		UserSettings.Find(CustomerSettingID).RightValue        = False;
		UserSettings.Find(CustomerSettingID).ComparisonType    = DataCompositionComparisonType.Equal; 
		UserSettings.Find(CustomerSettingID).Use               = False; 
		
		//VendorSettingID
		UserSettings.Find(VendorSettingID).RightValue          = False;
		UserSettings.Find(VendorSettingID).ComparisonType      = DataCompositionComparisonType.Equal; 
		UserSettings.Find(VendorSettingID).Use                 = False; 
		
		//OrGroupSettingID
		UserSettings.Find(OrGroupSettingID).Use                = False;

		//AndGroupSettingID
		UserSettings.Find(AndGroupSettingID).Use               = False;
		
		///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		
		//Period
		ReportFormSettingsHere = ThisForm.Report.SettingsComposer.Settings;
		PeriodSettingIDHere = ReportFormSettingsHere.DataParameters.Items.Find("Period").UserSettingID;
		UserSettingsHere = ThisForm.Report.SettingsComposer.UserSettings.Items;
		
		UserSettings.Find(PeriodSettingID).Value = UserSettingsHere.Find(PeriodSettingIDHere).Value;
		UserSettings.Find(PeriodSettingID).Use = UserSettingsHere.Find(PeriodSettingIDHere).Use;
		
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
		Structure.Insert("Account", Undefined);
		Structure.Insert("Hierarchy", Undefined);
		
		Data = GetFromTempStorage(DetailsData);	
		
		For Each ArrayItem In Data.Items.Get(Details).GetParents() Do
			
			If TypeOf(ArrayItem) = Type("DataCompositionFieldDetailsItem") Then
				
				For Each Field In ArrayItem.GetFields() Do
					
					If Field.Field = "Account" Then 
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

//////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////

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
	
	Try
		CurParameters = New Structure("ObjectTypeID", ThisForm.FormName);
		CommonUseClient.ApplyPrintFormSettings(Result,CurParameters);
	Except
	EndTry;
	
EndProcedure

&AtServer
Procedure OnUpdateUserSettingSetAtServer(StandardProcessing)
	
	If OpeningReportForm <> Undefined And OpeningReportForm Then
		
	Else
		GeneralFunctions.ChangePeriodIntoReportForm(ThisForm.Report.SettingsComposer, PeriodVariant, PeriodStartDate, PeriodEndDate);
	EndIf;	
	
	ModifiedStatePresentation();
		
EndProcedure

&AtClient
Procedure Excel(Command)
	
	Structure = GeneralFunctions.GetExcelFile("Trial balance", Result);
	
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

