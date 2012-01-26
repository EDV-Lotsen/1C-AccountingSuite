
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	PrintManagementClient.ExecutePrintCommand("Document.PurchaseQuote",
     "PurchaseQuote", CommandParameter, CommandExecuteParameters, Undefined);
	 
EndProcedure
