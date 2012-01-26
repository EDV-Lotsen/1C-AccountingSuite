
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	PrintManagementClient.ExecutePrintCommand("Document.SalesQuote",
     "SalesQuote", CommandParameter, CommandExecuteParameters, Undefined);
	 
EndProcedure
