
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	//Paste handler content.
	FormParameters = New Structure("", );
	OpenForm("DataProcessor.YodleeBankAccountsManagement.Form", FormParameters, CommandExecuteParameters.Source, CommandExecuteParameters.Uniqueness, CommandExecuteParameters.Window, CommandExecuteParameters.URL);
EndProcedure
