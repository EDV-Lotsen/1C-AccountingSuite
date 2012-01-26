
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	PrintManagementClient.ExecutePrintCommand("Document.SalesInvoice",
     "SalesInvoiceUM", CommandParameter, CommandExecuteParameters, Undefined);
	
EndProcedure
