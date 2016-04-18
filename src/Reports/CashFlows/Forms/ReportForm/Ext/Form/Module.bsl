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
	
	Variant = StrReplace(CurrentVariantDescription, " ", "");
	
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
	
	If Structure <> Undefined And Structure.BankReconciliation <> Undefined Then
		
		StandardProcessing = False;
		
		ShowValue(, Structure.BankReconciliation);		
	
	ElsIf Details <> Undefined And TypeOf(Details) = Type("DataCompositionDetailsID") Then 
		
		ParametersStructure = New Structure;
		ParametersStructure.Insert("GenerateOnOpen", True); 
		ReportForm = GetForm("Report.CashFlows.Form.ReportForm", ParametersStructure,, True);
		
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
		
	ElsIf Details <> Undefined Then
		
		ShowValue(, Details);		
		
	EndIf;
	
EndProcedure

&AtServer
Function GetDetailsAtServer(Details)
		
	If TypeOf(Details) = Type("DataCompositionDetailsID") Then 
		
		Structure = New Structure;
		Structure.Insert("StartDate", Undefined);
		Structure.Insert("EndDate", Undefined);
		Structure.Insert("Account", Undefined);
		Structure.Insert("BegBal", False);
		Structure.Insert("EndBal", False);
		Structure.Insert("BankReconciliation", Undefined);
		
		Data = GetFromTempStorage(DetailsData);	
		
		//1.
		For Each Field In Data.Items.Get(Details).GetFields() Do
			
			If Field.Field = "BegBal" Then
				Structure.Insert("BegBal", True);
			ElsIf Field.Field = "EndBal" Then
				Structure.Insert("EndBal", True);
			ElsIf Field.Field = "BegBalTotal" Then 
				Structure.Insert("StartDate", PeriodStartDate);
				Structure.Insert("EndDate", EndOfDay(PeriodEndDate));
				Structure.Insert("BegBal", True);
			ElsIf Field.Field = "EndBalTotal" Then
				Structure.Insert("StartDate", PeriodStartDate);
				Structure.Insert("EndDate", EndOfDay(PeriodEndDate));
				Structure.Insert("EndBal", True);
			ElsIf Field.Field = "BegBalTotalPP" Then 
				Structure.Insert("StartDate", AddMonth(PeriodStartDate, -12));
				Structure.Insert("EndDate", EndOfDay(AddMonth(PeriodEndDate, -12)));
				Structure.Insert("BegBal", True);
			ElsIf Field.Field = "EndBalTotalPP" Then
				Structure.Insert("StartDate", AddMonth(PeriodStartDate, -12));
				Structure.Insert("EndDate", EndOfDay(AddMonth(PeriodEndDate, -12)));
				Structure.Insert("EndBal", True);
			EndIf;
			
		EndDo;
		
		//2.
		For Each ArrayItem In Data.Items.Get(Details).GetParents() Do
			
			If TypeOf(ArrayItem) = Type("DataCompositionFieldDetailsItem") Then
				
				For Each Field In ArrayItem.GetFields() Do
					
					If Field.Field = "YearPeriod" Then 
						
						StartDate = BegOfYear(Field.Value);
						StartDate = ?(StartDate < PeriodStartDate, PeriodStartDate, StartDate);
						
						EndDate = EndOfYear(Field.Value);
						EndDate = ?(EndDate > EndOfDay(PeriodEndDate), EndOfDay(PeriodEndDate), EndDate);
						
						Structure.Insert("StartDate", StartDate);
						Structure.Insert("EndDate", EndDate);
						
					ElsIf Field.Field = "QuarterPeriod" Then 
						
						StartDate = BegOfQuarter(Field.Value);
						StartDate = ?(StartDate < PeriodStartDate, PeriodStartDate, StartDate);
						
						EndDate = EndOfQuarter(Field.Value);
						EndDate = ?(EndDate > EndOfDay(PeriodEndDate), EndOfDay(PeriodEndDate), EndDate);
						
						Structure.Insert("StartDate", StartDate);
						Structure.Insert("EndDate", EndDate);
						
					ElsIf Field.Field = "MonthPeriod" Then 
						
						StartDate = BegOfMonth(Field.Value);
						StartDate = ?(StartDate < PeriodStartDate, PeriodStartDate, StartDate);
						
						EndDate = EndOfMonth(Field.Value);
						EndDate = ?(EndDate > EndOfDay(PeriodEndDate), EndOfDay(PeriodEndDate), EndDate);
						
						Structure.Insert("StartDate", StartDate);
						Structure.Insert("EndDate", EndDate);
						
					ElsIf Field.Field = "Account" Then
						
						Structure.Insert("Account", Field.Value);
						
					EndIf;
					
				EndDo;
				
			EndIf;
			
		EndDo;
		
		//3.
		If Structure.BegBal
		And Structure.StartDate <> Undefined
		And Structure.EndDate <> Undefined
		And Structure.Account <> Undefined
		Then
			
			Query = New Query;
			Query.Text = "SELECT
			             |	BankReconciliation.Ref AS Document,
			             |	BankReconciliation.Date AS DateOfDocument
			             |FROM
			             |	Document.BankReconciliation AS BankReconciliation
			             |WHERE
			             |	BankReconciliation.Date <= &EndDate
			             |	AND BankReconciliation.BankAccount = &Account
			             |	AND BankReconciliation.Posted = TRUE
			             |	AND BankReconciliation.DeletionMark = FALSE
			             |
			             |ORDER BY
			             |	BankReconciliation.Date DESC";
			
			Query.SetParameter("Account", Structure.Account);
			Query.SetParameter("EndDate", Structure.EndDate);
			
			QueryResult = Query.Execute();
			
			SelectionDetailRecords = QueryResult.Select();
			
			HaveDocument = False;
			
			While SelectionDetailRecords.Next() Do
				
				If (Not HaveDocument) Or (SelectionDetailRecords.DateOfDocument >=  Structure.StartDate) Then
					Structure.Insert("BankReconciliation", SelectionDetailRecords.Document);
				EndIf;
				
				HaveDocument = True;
				
			EndDo;
			
		ElsIf Structure.EndBal
		And Structure.EndDate <> Undefined
		And Structure.Account <> Undefined
		Then

			Query = New Query;
			Query.Text = "SELECT TOP 1
			             |	BankReconciliation.Ref AS Document,
			             |	BankReconciliation.Date AS DateOfDocument
			             |FROM
			             |	Document.BankReconciliation AS BankReconciliation
			             |WHERE
			             |	BankReconciliation.Date <= &EndDate
			             |	AND BankReconciliation.BankAccount = &Account
			             |	AND BankReconciliation.Posted = TRUE
			             |	AND BankReconciliation.DeletionMark = FALSE
			             |
			             |ORDER BY
			             |	BankReconciliation.Date DESC";
			
			Query.SetParameter("Account", Structure.Account);
			Query.SetParameter("EndDate", Structure.EndDate);
			
			QueryResult = Query.Execute();
			
			SelectionDetailRecords = QueryResult.Select();
			
			While SelectionDetailRecords.Next() Do
				Structure.Insert("BankReconciliation", SelectionDetailRecords.Document);
			EndDo;
			
		EndIf;
			
		//4.
		Return Structure; 
		
	Else 
		
		Return Undefined; 
		
	EndIf;
	
EndFunction

&AtServer
Function ProcessDetailsAtServer(Val ReportRF, Val ResultRF, Val DetailsDataRF, Val UUID_RF, Details)
	
	//1.
	MainDataCompositionSchema = Reports.CashFlows.GetTemplate("CashFlows");
	DataCompositionDetailsProcess = New DataCompositionDetailsProcess(DetailsData, New DataCompositionAvailableSettingsSource(MainDataCompositionSchema));	
	DataCompositionSettings = DataCompositionDetailsProcess.DrillDown(Details, New DataCompositionField("Recorder"));	
	
	//2.
	If DataCompositionSettings <> Undefined Then 
		
		ReportRF.SettingsComposer.LoadSettings(DataCompositionSettings);
		ResultRF.Clear();                                                                              

		ReportObject = FormDataToValue(ReportRF, Type("ReportObject.CashFlows"));
		ReportObject.ComposeResult(ResultRF, DetailsDataRF);                                  
		Address = PutToTempStorage(DetailsDataRF, UUID_RF); 
		
		Return New Structure("Result, DetailsData", ResultRF, Address);    
		
	EndIf;
	
	Return Undefined;
	
EndFunction

&AtClient
Procedure Excel(Command)
	
	Structure = GeneralFunctions.GetExcelFile("R and D", Result);
	
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
	
	ComposeResult(ResultCompositionMode.Background);
	
EndProcedure

&AtClient
Procedure PeriodVariantOnChange(Item)
	
	GeneralFunctions.ChangeDatesByPeriod(PeriodVariant, PeriodStartDate, PeriodEndDate);
	GeneralFunctions.ChangePeriodIntoUserSettings(ThisForm.Report.SettingsComposer, PeriodStartDate, PeriodEndDate);
	ModifiedStatePresentation();
	
EndProcedure

&AtClient
Procedure PeriodStartDateOnChange(Item)
	
	If Variant = "Years" Then
		PeriodStartDate = BegOfYear(PeriodStartDate);
	ElsIf Variant = "Quarters" Then
		PeriodStartDate = BegOfQuarter(PeriodStartDate);
	Else
		PeriodStartDate = BegOfMonth(PeriodStartDate);
	EndIf;
	
	If PeriodStartDate > PeriodEndDate Then
		PeriodStartDate = PeriodEndDate; 	
	EndIf;
	
	PeriodVariant = GeneralFunctions.GetCustomVariantName();
	GeneralFunctions.ChangePeriodIntoUserSettings(ThisForm.Report.SettingsComposer, PeriodStartDate, PeriodEndDate);
	ModifiedStatePresentation();
	
EndProcedure

&AtClient
Procedure PeriodEndDateOnChange(Item)
	
	If Variant = "Years" Then
		PeriodEndDate = EndOfYear(PeriodEndDate);
	ElsIf Variant = "Quarters" Then
		PeriodEndDate = EndOfQuarter(PeriodEndDate);
	Else
		PeriodEndDate = EndOfMonth(PeriodEndDate);
	EndIf;
	
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

&AtClient
Procedure Print(Command)
	
	SetPrintParameters();
		
	Result.Print(PrintDialogUseMode.Use);
	
EndProcedure

&AtServer
Procedure SetPrintParameters() 
	
	//
	Result.PageSize = "Letter"; 
	Result.FitToPage = True;
	
	//
	Result.RepeatOnRowPrint = Result.Area(1, , 6, );
			
	//Header
	Result.Header.Enabled       = True;
	Result.Header.StartPage     = 1;
	Result.Header.VerticalAlign = VerticalAlign.Bottom;	
	Result.Header.Font          = New Font(Result.Header.Font, , , , True);
	Result.Header.LeftText      = "";
	Result.Header.CenterText    = "";
	Result.Header.RightText     = "Page [&PageNumber] of [&PagesTotal]
								  |" + Format(CurrentDate(), "DF='MMM d, yyyy h:mm:ss tt'");
    	
EndProcedure

