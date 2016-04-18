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
	
	If Structure <> Undefined Then
		
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
		
		ReportFormSettingsHere = ThisForm.Report.SettingsComposer.Settings;
		UserSettingsHere       = ThisForm.Report.SettingsComposer.UserSettings.Items;
		
		//Period
		PeriodSettingIDHere = ReportFormSettingsHere.DataParameters.Items.Find("Period").UserSettingID;
		
		If Structure.Period <> Undefined Then
			UserSettings.Find(PeriodSettingID).Value = Structure.Period;
			UserSettings.Find(PeriodSettingID).Use   = True;
		Else
			UserSettings.Find(PeriodSettingID).Value = UserSettingsHere.Find(PeriodSettingIDHere).Value;
			UserSettings.Find(PeriodSettingID).Use   = UserSettingsHere.Find(PeriodSettingIDHere).Use;
		EndIf;
		
		//Account
		If Structure.Account <> Undefined Then
			UserSettings.Find(AccountSettingID).RightValue     = Structure.Account;
			UserSettings.Find(AccountSettingID).ComparisonType = ?(Structure.Hierarchy, DataCompositionComparisonType.InHierarchy, DataCompositionComparisonType.Equal); 
			UserSettings.Find(AccountSettingID).Use            = True; 
		Else
			UserSettings.Find(AccountSettingID).RightValue     = PredefinedValue("ChartOfAccounts.ChartOfAccounts.EmptyRef");
			UserSettings.Find(AccountSettingID).ComparisonType = DataCompositionComparisonType.Equal;
			UserSettings.Find(AccountSettingID).Use            = False;
		EndIf;
		
		//AccountType
		If Structure.AccountType <> Undefined Then
			UserSettings.Find(AccountTypeSettingID).RightValue     = Structure.AccountType;
			UserSettings.Find(AccountTypeSettingID).ComparisonType = DataCompositionComparisonType.Equal; 
			UserSettings.Find(AccountTypeSettingID).Use            = True; 
		Else
			UserSettings.Find(AccountTypeSettingID).RightValue     = PredefinedValue("Enum.AccountTypes.EmptyRef");
			UserSettings.Find(AccountTypeSettingID).ComparisonType = DataCompositionComparisonType.Equal;
			UserSettings.Find(AccountTypeSettingID).Use            = False;
		EndIf;
		
		//OrGroup
		If Structure.Company <> Undefined Then
			
			//OrGroup
			UserSettings.Find(OrGroupSettingID).Use             = True;
			//Company
			UserSettings.Find(CompanySettingID).RightValue      = Structure.Company;
			UserSettings.Find(CompanySettingID).ComparisonType  = DataCompositionComparisonType.Equal; 
			UserSettings.Find(CompanySettingID).Use             = True; 
			
			//AndGroup
			UserSettings.Find(AndGroupSettingID).Use            = False;
			//Customer
			UserSettings.Find(CustomerSettingID).RightValue     = False;
			UserSettings.Find(CustomerSettingID).ComparisonType = DataCompositionComparisonType.Equal; 
			UserSettings.Find(CustomerSettingID).Use            = False; 
			//Vendor
			UserSettings.Find(VendorSettingID).RightValue       = False;
			UserSettings.Find(VendorSettingID).ComparisonType   = DataCompositionComparisonType.Equal; 
			UserSettings.Find(VendorSettingID).Use              = False; 
			
		ElsIf Structure.NotSpecified <> Undefined Then
			
			//OrGroup
			UserSettings.Find(OrGroupSettingID).Use             = True;
			//Company
			UserSettings.Find(CompanySettingID).RightValue      = PredefinedValue("Catalog.Companies.EmptyRef");
			UserSettings.Find(CompanySettingID).ComparisonType  = DataCompositionComparisonType.NotFilled;
			UserSettings.Find(CompanySettingID).Use             = True;
					
			//AndGroup
			UserSettings.Find(AndGroupSettingID).Use            = True;
			//Customer
			UserSettings.Find(CustomerSettingID).RightValue     = ?(Variant = "Customers", False, True);
			UserSettings.Find(CustomerSettingID).ComparisonType = DataCompositionComparisonType.Equal; 
			UserSettings.Find(CustomerSettingID).Use            = True; 
			//Vendor
			UserSettings.Find(VendorSettingID).RightValue       = ?(Variant = "Vendors", False, True);
			UserSettings.Find(VendorSettingID).ComparisonType   = DataCompositionComparisonType.Equal; 
			UserSettings.Find(VendorSettingID).Use              = True; 
			
		Else
			
			//OrGroup
			UserSettings.Find(OrGroupSettingID).Use             = False;
			//Company
			UserSettings.Find(CompanySettingID).RightValue      = PredefinedValue("Catalog.Companies.EmptyRef");
			UserSettings.Find(CompanySettingID).ComparisonType  = DataCompositionComparisonType.Equal;
			UserSettings.Find(CompanySettingID).Use             = False;
					
			//AndGroup
			UserSettings.Find(AndGroupSettingID).Use            = False;
			//Customer
			UserSettings.Find(CustomerSettingID).RightValue     = False;
			UserSettings.Find(CustomerSettingID).ComparisonType = DataCompositionComparisonType.Equal; 
			UserSettings.Find(CustomerSettingID).Use            = False; 
			//Vendor
			UserSettings.Find(VendorSettingID).RightValue       = False;
			UserSettings.Find(VendorSettingID).ComparisonType   = DataCompositionComparisonType.Equal; 
			UserSettings.Find(VendorSettingID).Use              = False; 
			
		EndIf;
		
		///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		
		ReturnStructure        = ProcessDetailsAtServer(ReportForm.Report, ReportForm.Result, ReportForm.DetailsData, ReportForm.UUID, "GeneralLedger");
		ReportForm.Result      = ReturnStructure.Result;
		ReportForm.DetailsData = ReturnStructure.DetailsData;
		
		ReportForm.Open();
		
	ElsIf Details <> Undefined Then
		
		ShowValue(, Details);		
		
	EndIf;
	
EndProcedure

&AtServer
Function GetDetailsAtServer(Details)
	
	If TypeOf(Details) = Type("DataCompositionDetailsID") Then 
		
		Structure = New Structure;
		Structure.Insert("Account",      Undefined);
		Structure.Insert("Hierarchy",    Undefined);
		Structure.Insert("AccountType",  Undefined);
		Structure.Insert("Company",      Undefined);
		Structure.Insert("Period",       Undefined);
		Structure.Insert("NotSpecified", Undefined);
		
		Data = GetFromTempStorage(DetailsData);	
		
		//1.
		For Each Field In Data.Items.Get(Details).GetFields() Do
			
			If Field.Field = "NotSpecified" Then 
				Structure.Insert("NotSpecified", Field.Value);
			EndIf;
			
		EndDo;
		
		//2.
		For Each ArrayItem In Data.Items.Get(Details).GetParents() Do
			
			If TypeOf(ArrayItem) = Type("DataCompositionFieldDetailsItem") Then
				
				For Each Field In ArrayItem.GetFields() Do
					
					If Field.Field = "Account" Then 
						
						Structure.Insert("Account", Field.Value);
						Structure.Insert("Hierarchy", Field.Hierarchy);
						
					ElsIf Field.Field = "AccountType" Then 
						
						Structure.Insert("AccountType", Field.Value);
						
					ElsIf Field.Field = "Company" Then 
						
						Structure.Insert("Company", Field.Value);
						
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
Function ProcessDetailsAtServer(Val ReportRF, Val ResultRF, Val DetailsDataRF, Val UUID_RF, NameReport)
	
	ReportObject = FormDataToValue(ReportRF, Type("ReportObject." + NameReport));
	ResultRF.Clear();                                                                              
	ReportObject.ComposeResult(ResultRF, DetailsDataRF);                                  
	Address = PutToTempStorage(DetailsDataRF, UUID_RF); 
	
	Return New Structure("Result, DetailsData", ResultRF, Address);       
	
EndFunction

&AtClient
Procedure Excel(Command)
	
	Structure = GeneralFunctions.GetExcelFile("Income statement", Result);
	
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
Procedure Create(Command)
	
	GeneralFunctions.ChangePeriodIntoUserSettings(ThisForm.Report.SettingsComposer, PeriodStartDate, PeriodEndDate);
	Report.SettingsComposer.LoadUserSettings(Report.SettingsComposer.UserSettings);
	
	ComposeResult();
	
	UpdateHierarchy();
	
	Try
		CurParameters = New Structure("ObjectTypeID", ThisForm.FormName);
		CommonUseClient.ApplyPrintFormSettings(Result,CurParameters);
	Except
	EndTry;
	
EndProcedure

&AtServer
Procedure UpdateHierarchy()
	
	//0.
	TableHeight = Result.TableHeight;	
	
	If Variant = "Total" And TableHeight > 0 Then 
		
		Area = Result.Area("R1:R" + TableHeight);
		Area.Ungroup();
		
	EndIf;	
	
	RowsToDelete = New ValueList; 
	
	//1.
	PreviousText     = "";
	PreviousAddParam = "";
	
	For CurrentRow = 1 To TableHeight Do
		
		CurrentText     = Result.Area("R" + CurrentRow +"C1").Text;
		CurrentAddParam = Result.Area("R" + CurrentRow +"C1").VerticalAlign;
		
		If (CurrentText = PreviousText) And (CurrentAddParam = PreviousAddParam) Then
			RowsToDelete.Add(CurrentRow);
		EndIf;
		
		PreviousText     = CurrentText;
		PreviousAddParam = CurrentAddParam; 
		 
	EndDo;
	
	//2.
	DeletedRows = 0;
	
	For Each RowToDelete In RowsToDelete Do
		
		DeleteArea = Result.Area("R" + (RowToDelete.Value - DeletedRows));
		Result.DeleteArea(DeleteArea, SpreadsheetDocumentShiftType.Vertical);
		
		DeletedRows = DeletedRows + 1;
		
	EndDo;
	
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
	
	ModifiedStatePresentation();
		
EndProcedure