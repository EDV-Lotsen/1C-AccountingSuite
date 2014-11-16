
&AtClient
Procedure Support(Command)
	GotoURL("http://help.accountingsuite.com");
EndProcedure

&AtClient
Procedure UserGuide(Command)
	GotoURL("http://userguide.accountingsuite.com");
	//OpenHelpContent();
EndProcedure

&AtClient
Procedure OpenNew(Command)
	If CFOTodayConstant() Then
		GotoURL("https://cfotoday.accountingsuite.com");
	Else
		GotoURL("https://login.accountingsuite.com");
	EndIf;
EndProcedure

&AtServer
Function CFOTodayConstant()
	Return Constants.CFOToday.Get();
EndFunction

&AtClient
Procedure ReleaseNotes(Command)
	GotoURL("http://releases.accountingsuite.com/release-notes");
EndProcedure

&AtClient
Procedure OnboardingWebinars(Command)
	GotoURL("https://attendee.gotowebinar.com/rt/8808644308605056514");
EndProcedure

&AtClient
Procedure ProductDemoForAccountants(Command)
	GotoURL("https://attendee.gotowebinar.com/rt/7437736924938618882");
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Constants.CFOToday.Get() = False Then
		Items.Group4.Visible = False;
	EndIf;
EndProcedure
