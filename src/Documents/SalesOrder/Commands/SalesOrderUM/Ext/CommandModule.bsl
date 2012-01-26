
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	PrintManagementClient.ExecutePrintCommand("Document.SalesOrder",
     "SalesOrderUM", CommandParameter, CommandExecuteParameters, Undefined);
	 
EndProcedure
