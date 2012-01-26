
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
		PrintManagementClient.ExecutePrintCommand("Document.PurchaseInvoice",
     "PurchaseInvoice", CommandParameter, CommandExecuteParameters, Undefined);

	
EndProcedure
