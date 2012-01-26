
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
		PrintManagementClient.ExecutePrintCommand("Document.PurchaseOrder",
     "PurchaseOrderUM", CommandParameter, CommandExecuteParameters, Undefined);

	
EndProcedure
