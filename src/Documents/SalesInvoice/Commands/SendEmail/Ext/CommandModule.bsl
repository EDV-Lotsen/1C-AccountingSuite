
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	If CommandParameter.Count() = 1 Then
		FormParameters = New Structure("Ref",CommandParameter[0]);
		OpenForm("CommonForm.EmailForm", FormParameters,,,,,, FormWindowOpeningMode.LockOwnerWindow);
	Elsif CommandParameter.Count() > 1 Then
		FormParameters = New Structure("Refs",CommandParameter);
		OpenForm("CommonForm.MultiEmail", FormParameters,,,,,, FormWindowOpeningMode.LockOwnerWindow);
	Else
		Message("Please select a document/documents to email.");
	EndIf;
	
EndProcedure
