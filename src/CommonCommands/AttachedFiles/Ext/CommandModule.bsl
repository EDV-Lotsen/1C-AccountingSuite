
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	FormAttribute = New Structure;
	FormAttribute.Insert("FormOwner",  CommandParameter);
	
	OpenForm("InformationRegister.FileStorage.Form.ListForm", 
	FormAttribute, 
	CommandExecuteParameters.Source, 
	CommandExecuteParameters.Uniqueness, 
	CommandExecuteParameters.Window);

EndProcedure
