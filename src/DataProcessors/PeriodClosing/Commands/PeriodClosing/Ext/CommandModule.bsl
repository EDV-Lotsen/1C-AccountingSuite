
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	//Paste handler content.
	FormParameters = New Structure("", );
	OpenForm("DataProcessor.PeriodClosing.Form", FormParameters, CommandExecuteParameters.Source, CommandExecuteParameters.Uniqueness, CommandExecuteParameters.Window);
	
EndProcedure
