
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	 OpenForm("DataProcessor.EventLogMonitor.Form",, CommandExecuteParameters.Source, CommandExecuteParameters.Uniqueness, CommandExecuteParameters.Window);
EndProcedure
