
&AtServerNoContext
Procedure SaveTemplateOpenModeSetting(AskTemplateOpenMode, TemplateOpenModeView)
	
	CommonSettingsStorage.Save("TemplateOpenSetting", "AskTemplateOpenMode", AskTemplateOpenMode);
	CommonSettingsStorage.Save("TemplateOpenSetting", "TemplateOpenModeView", TemplateOpenModeView);
	
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Value = CommonSettingsStorage.Load("TemplateOpenSetting", "AskTemplateOpenMode");
	
	If Value = Undefined Then
		DontAskAgain = False;
	Else
		DontAskAgain = NOT Value;
	EndIf;
	
	Value = CommonSettingsStorage.Load("TemplateOpenSetting", "TemplateOpenModeView");
	
	If Value = Undefined Then
		OpenMode = 0;
	Else
		If Value Then
			OpenMode = 0;
		Else
			OpenMode = 1;
		EndIf;
	EndIf;

EndProcedure

&AtClient
Procedure ОК(Command)
	
	AskTemplateOpenMode = NOT DontAskAgain;
	TemplateOpenModeView = ?(OpenMode = 0, True, False);
	
	SaveTemplateOpenModeSetting(AskTemplateOpenMode, TemplateOpenModeView);
	
	Close(New Structure("DontAskAgain, OpenModeView",
							DontAskAgain,
							TemplateOpenModeView) );

EndProcedure