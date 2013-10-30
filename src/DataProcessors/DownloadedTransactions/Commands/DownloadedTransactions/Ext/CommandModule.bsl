
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	//Вставить содержимое обработчика.
	FormParameters = New Structure("", );
	OpenForm("DataProcessor.DownloadedTransactions.Form", FormParameters, CommandExecuteParameters.Source, CommandExecuteParameters.Uniqueness, CommandExecuteParameters.Window, CommandExecuteParameters.URL);
EndProcedure
