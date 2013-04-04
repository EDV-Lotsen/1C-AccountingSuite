
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	PrintManagementClient.RunPrintCommand("Document.SalesOrder",
     "SalesOrder", CommandParameter, CommandExecuteParameters, Undefined);
	 
EndProcedure
