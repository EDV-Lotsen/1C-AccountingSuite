
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
		PrintManagementClient.RunPrintCommand("Document.PurchaseInvoice",
     "PurchaseInvoice", CommandParameter, CommandExecuteParameters, Undefined);

	
EndProcedure
