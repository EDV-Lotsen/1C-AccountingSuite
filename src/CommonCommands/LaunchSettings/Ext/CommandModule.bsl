
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	//Paste handler content.
	//FormParameters = New Structure("", );
	OpenForm("CommonForm.GeneralSettings", , CommandExecuteParameters.Source, CommandExecuteParameters.Uniqueness, CommandExecuteParameters.Window, CommandExecuteParameters.URL);
EndProcedure
