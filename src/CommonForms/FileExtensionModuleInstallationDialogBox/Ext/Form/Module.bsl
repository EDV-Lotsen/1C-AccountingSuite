
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("Description") Then
		If Parameters.Description <> Undefined Then
			Items.DecorationDescription.Title = Parameters.Description + Chars.LF + + NStr("en = ' Install and enable?'");
		EndIf;
	EndIf;

EndProcedure

&AtClient
Procedure CloseForm(Command)
	
	Close(True); // offer later - in a different session

EndProcedure

&AtClient
Procedure InstallNow(Command)
	
	InstallFileSystemExtension();
	
	ExtensionEnabled = AttachFileSystemExtension();
	If NOT ExtensionEnabled Then
		Close(True); // offer later - in a different session
	Else	
		Close(False); // don't offer
	EndIf;	

EndProcedure

&AtClient
Procedure InstallLater(Command)
	
	Close(True); // offer later - in a different session

EndProcedure

&AtClient
Procedure DoNotInstall(Command)
	
	Close(False); // don't offer

EndProcedure
