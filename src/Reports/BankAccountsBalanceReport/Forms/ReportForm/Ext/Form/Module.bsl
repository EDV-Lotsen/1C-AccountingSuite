
&AtClient
Procedure ExportToFile(Command)
	Structure = GeneralFunctions.GetExcelFile("Adjustment Journal", Result);
	GetFile(Structure.Address, Structure.FileName, True); 
EndProcedure

&AtClient
Procedure Print(Command)
	PrintAtServer();
	Result.Print(PrintDialogUseMode.Use);
EndProcedure


&AtServer
Procedure PrintAtServer()
	Result.PageSize = "Letter"; 
	Result.FitToPage = True;
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
		Param.Value = Date;
	EndIf;
	Report.SettingsComposer.LoadSettings(CurSettings);
	
	ComposeResult();
	
EndProcedure

&AtClient
Procedure Run(Command)
	RunAtServer();
EndProcedure
