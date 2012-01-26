
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	PrintManagementClient.ExecutePrintCommand("Document.SalesInvoice",
     "SalesInvoice", CommandParameter, CommandExecuteParameters, Undefined);
	
EndProcedure
