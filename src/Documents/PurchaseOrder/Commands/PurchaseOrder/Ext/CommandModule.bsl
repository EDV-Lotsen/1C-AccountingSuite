
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
		PrintManagementClient.RunPrintCommand("Document.PurchaseOrder",
     "PurchaseOrder", CommandParameter, CommandExecuteParameters, Undefined);

	
EndProcedure
