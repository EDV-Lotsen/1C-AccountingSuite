
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	If CommandParameter = Undefined Then
		Return;
	EndIf;
	OpenForm("Report.DocumentRegisterRecords.Form", New Structure("Document", CommandParameter), , True, CommandExecuteParameters.Window);

EndProcedure
