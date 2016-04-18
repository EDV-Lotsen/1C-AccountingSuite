
&AtClient
Procedure ExportToFile(Command)
	Structure = GeneralFunctions.GetExcelFile("Adjustment Journal", Result);
	GetFile(Structure.Address, Structure.FileName, True); 
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	Date = CurrentDate();
EndProcedure

&AtServer
Procedure RunAtServer()
	Param = Report.SettingsComposer.Settings.DataParameters.Items.Find("Period");
	CurSettings = Report.SettingsComposer.GetSettings();
	Param = CurSettings.DataParameters.Items.Find("Period");
	If Param <> Undefined Then 
		Param.Value = New Boundary(EndOfDay(Date),BoundaryType.Including);
	EndIf;
	Report.SettingsComposer.LoadSettings(CurSettings);
	
	ComposeResult();
	
EndProcedure

&AtClient
Procedure Run(Command)
	
	RunAtServer();
	
	Try
		CurParameters = New Structure("ObjectTypeID",ThisForm.FormName);
		CommonUseClient.ApplyPrintFormSettings(Result,CurParameters);
	Except
	EndTry;
	
EndProcedure
