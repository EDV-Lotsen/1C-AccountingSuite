&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	//t = CurrentLanguage().LanguageCode;
	
	If CurrentLanguage().LanguageCode = "pt" Then
		TemplateName = "Navigation_pt";
	EndIf;
	
	If CurrentLanguage().LanguageCode = "de" Then
		TemplateName = "Navigation_de";
	EndIf;
	
	If CurrentLanguage().LanguageCode = "en" Then
		TemplateName = "Navigation_en";
	EndIf;
	
	DesktopNavigation = GetCommonTemplate(TemplateName).GetText();
	
EndProcedure

&AtClient
Procedure DesktopNavigationOnClick(Item, EventData, StandardProcessing)
	
		StandardProcessing = False;
		
		Try
		
			FormNameString = EventData.Element.href;
			FormNameString = StrReplace(FormNameString, "v8config://", "");
			FormNameString = StrReplace(FormNameString, "/", "");
			OpenForm(FormNameString);

		Except
		EndTry;
		
EndProcedure