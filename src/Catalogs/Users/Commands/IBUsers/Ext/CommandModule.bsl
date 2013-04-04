

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	FormParameters = New Structure;
	
	If TypeOf(CommandExecuteParameters.Source) = Type("ManagedForm") Then
		
		If CommandExecuteParameters.Source.FormName = "Catalog.Users.Form.ListForm" Then
			FormParameters.Insert("Filter", "Users");
		EndIf;
	EndIf;
	
	OpenForm("Catalog.Users.Form.IBUsers", FormParameters, CommandExecuteParameters.Source, CommandExecuteParameters.Uniqueness, CommandExecuteParameters.Window);
	
EndProcedure
