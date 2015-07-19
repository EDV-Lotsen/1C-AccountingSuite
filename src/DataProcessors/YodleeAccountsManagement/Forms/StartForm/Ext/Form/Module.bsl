
&AtClient
Procedure AddAccount(Command)
		
	Notify = New NotifyDescription("OnComplete_AddAccount", ThisObject);
	Params = New Structure("PerformAddAccount", True);
	OpenForm("DataProcessor.YodleeAccountsManagement.Form.Form", Params, ThisForm,,,, Notify, FormWindowOpeningMode.LockOwnerWindow);

EndProcedure

&AtClient
Procedure OnComplete_AddAccount(ClosureResult, AdditionalParameters) Export
	
	ShowMessageBox(,"Added account successfully!");
	
EndProcedure
