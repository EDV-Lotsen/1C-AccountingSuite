
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	PrintManagementClient.ExecutePrintCommand("Document.SalesQuote",
     "SalesQuoteUM", CommandParameter, CommandExecuteParameters, Undefined);
	 
EndProcedure
