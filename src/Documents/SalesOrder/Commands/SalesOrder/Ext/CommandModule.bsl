
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	PrintManagementClient.ExecutePrintCommand("Document.SalesOrder",
     "SalesOrder", CommandParameter, CommandExecuteParameters, Undefined);
	 
EndProcedure
