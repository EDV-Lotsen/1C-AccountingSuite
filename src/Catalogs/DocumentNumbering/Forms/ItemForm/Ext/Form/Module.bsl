
&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	If Object.Ref = Catalogs.DocumentNumbering.Companies  And StrLen(Object.Number) > 5 Then
		
		MessageText = NStr("en = 'Company number can''t be longer than 5 characters.'");
		CommonUseClientServer.MessageToUser(MessageText, Object.Ref, "Object.Number");
		
		Cancel = True;
		
	EndIf;
	
EndProcedure
