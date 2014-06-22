
&AtClient
Procedure Create(Command)
	
	  OpenForm("DataProcessor.GenerateStatements.Form");
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "UpdateStatements" Then
		Items.List.Refresh();
	EndIf;
	
EndProcedure
