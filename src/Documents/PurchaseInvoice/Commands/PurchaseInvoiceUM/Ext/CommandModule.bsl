
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
		PrintManagementClient.ExecutePrintCommand("Document.PurchaseInvoice",
     "PurchaseInvoiceUM", CommandParameter, CommandExecuteParameters, Undefined);

	
EndProcedure
