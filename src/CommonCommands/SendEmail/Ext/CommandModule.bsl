
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	If CommandParameter.Count() = 1
		Or CommandExecuteParameters.Source.FormName = "Document.Statement.Form.ListForm" 
		Or CommandExecuteParameters.Source.FormName = "Document.SalesOrder.Form.ListForm"
		Or CommandExecuteParameters.Source.FormName = "Document.CashSale.Form.ListForm"
		Or CommandExecuteParameters.Source.FormName = "Document.SalesReturn.Form.ListForm"
		Or CommandExecuteParameters.Source.FormName = "Document.Quote.Form.ListForm"
		Then
		
		FormParameters = New Structure("Ref",CommandParameter[0]);
		OpenForm("CommonForm.EmailForm", FormParameters,,,,,, FormWindowOpeningMode.LockOwnerWindow);
		
	Elsif CommandParameter.Count() > 1 Then
		
		FormParameters = New Structure("Refs",CommandParameter);
		OpenForm("CommonForm.MultiEmail", FormParameters,,,,,, FormWindowOpeningMode.LockOwnerWindow);
		
	Else
		Message("Please select a document/documents to email.");
	EndIf;
	
EndProcedure
