
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	PrintManagementClient.RunPrintCommand("Document.SalesInvoice",
     "SalesInvoice", CommandParameter, CommandExecuteParameters, Undefined);
	
EndProcedure
