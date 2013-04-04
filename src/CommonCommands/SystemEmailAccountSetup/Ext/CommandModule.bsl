

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	OpenFormModal("Catalog.EmailAccounts.ObjectForm", 
						New Structure("Key", EmailOperations.GetSystemAccount()));
	
EndProcedure
