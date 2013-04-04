
&AtClient
Procedure AccountFromOnChange(Item)
	
	Items.AccFromLabel.Title =
		CommonUse.GetAttributeValue(Object.AccountFrom, "Description");
		
EndProcedure

&AtClient
Procedure AccountToOnChange(Item)
	
	Items.AccToLabel.Title =
		CommonUse.GetAttributeValue(Object.AccountTo, "Description");

EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
		
	Items.AccFromLabel.Title =
		CommonUse.GetAttributeValue(Object.AccountFrom, "Description");
		
	Items.AccToLabel.Title =
		CommonUse.GetAttributeValue(Object.AccountTo, "Description");
		
	// AdditionalReportsAndDataProcessors
	AdditionalReportsAndDataProcessors.OnCreateAtServer(ThisForm);
	// End AdditionalReportsAndDataProcessors
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)

	If Object.AccountFrom = Object.AccountTo Then
		
		Message = New UserMessage();
		Message.Text=NStr("en='Account from and Account to can not be the same'");
		Message.Message();
		Cancel = True;
		Return;

		
	EndIf;
	
EndProcedure
