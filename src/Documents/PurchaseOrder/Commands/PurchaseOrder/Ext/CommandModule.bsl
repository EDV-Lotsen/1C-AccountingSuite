
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
		PrintManagementClient.ExecutePrintCommand("Document.PurchaseOrder",
     "PurchaseOrder", CommandParameter, CommandExecuteParameters, Undefined);

	
EndProcedure
