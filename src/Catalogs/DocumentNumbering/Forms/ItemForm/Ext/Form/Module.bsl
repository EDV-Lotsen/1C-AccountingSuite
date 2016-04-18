
&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	If Object.Ref = Catalogs.DocumentNumbering.Companies  And StrLen(Object.Number) > 5 Then
		
		MessageText = NStr("en = 'Company number can''t be longer than 5 characters.'");
		CommonUseClientServer.MessageToUser(MessageText, Object.Ref, "Object.Number");
		
		Cancel = True;
		
	EndIf;
	
	If (Object.Ref = Catalogs.DocumentNumbering.Assembly
		Or Object.Ref = Catalogs.DocumentNumbering.PurchaseReturn
		Or Object.Ref = Catalogs.DocumentNumbering.CreditMemo)
		And (StrLen(Object.Number)) > 6 Then
		
		MessageText = NStr("en = 'The number can''t be longer than 6 characters.'");
		CommonUseClientServer.MessageToUser(MessageText, Object.Ref, "Object.Number");
		
		Cancel = True;
		
	EndIf;
	
EndProcedure
