

&AtClient
Procedure DoNotInstall(Command)
	Close(False); // do not suggest
EndProcedure

&AtClient
Procedure SetLater(Command)
	Close(True); // suggest later  - in other session
EndProcedure

&AtClient
Procedure SetNow(Command)
	InstallFileSystemExtension();
	Close(False); // do not suggest
EndProcedure

&AtClient
Procedure CloseForm(Command)
	Close(True); // suggest later  - in other session
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancellation, StandardProcessing)
	
	If Parameters.Property("Message") Then
		If Parameters.Message <> Undefined Then
			Items.DecorationExplanation.Title = Parameters.Message + Chars.LF + NStr("en = 'Install and connect?'");
		EndIf;
	EndIf;
	
EndProcedure
