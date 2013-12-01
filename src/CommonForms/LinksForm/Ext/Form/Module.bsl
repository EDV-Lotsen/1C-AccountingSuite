
&AtClient
Procedure Support(Command)
	GotoURL("http://accountingsuite.com/support");
EndProcedure

&AtClient
Procedure UserGuide(Command)
	OpenHelpContent();
EndProcedure

&AtClient
Procedure OpenNew(Command)
	GotoURL("https://login.accountingsuite.com");
EndProcedure
