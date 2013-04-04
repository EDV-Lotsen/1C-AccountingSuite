

&AtServer
Procedure OnCreateAtServer(Cancellation, StandardProcessing)
	
	Value = CommonSettingsStorage.Load("SetupOfTemplatesOpening", "AskTemplateOpeningMode");
	
	If Value = Undefined Then
		DoNotAskAnyMore = False;
	Else
		DoNotAskAnyMore = NOT Value;
	EndIf;
	
	Value = CommonSettingsStorage.Load("SetupOfTemplatesOpening", "TemplateOpeningModeView");
	
	If Value = Undefined Then
		HowToOpen = 0;
	Else
		If Value Then
			HowToOpen = 0;
		Else
			HowToOpen = 1;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure OK(Command)
	
	AskTemplateOpeningMode = NOT DoNotAskAnyMore;
	TemplateOpeningModeView = ?(HowToOpen = 0, True, False);
	
	SaveSettingsOfTemplateOpeningMode(AskTemplateOpeningMode, TemplateOpeningModeView);
	
	Close(New Structure("DoNotAskAnyMore, OpeningModeView",
							DoNotAskAnyMore,
							TemplateOpeningModeView) );
	
EndProcedure

&AtServerNoContext
Procedure SaveSettingsOfTemplateOpeningMode(AskTemplateOpeningMode, TemplateOpeningModeView)
	
	CommonSettingsStorage.Save("SetupOfTemplatesOpening", "AskTemplateOpeningMode", AskTemplateOpeningMode);
	CommonSettingsStorage.Save("SetupOfTemplatesOpening", "TemplateOpeningModeView", TemplateOpeningModeView);
	
EndProcedure
