
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	PrintManagementClient.ExecutePrintCommand("Document.PurchaseQuote",
     "PurchaseQuoteUM", CommandParameter, CommandExecuteParameters, Undefined);
	 
EndProcedure
