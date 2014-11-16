
&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	//  create price book in zoho
	If Constants.zoho_auth_token.Get() <> "" Then
		If Object.NewObject = True Then
			ThisAction = "create";
		Else
			ThisAction = "update";
		EndIf;
		zoho_Functions.zoho_ThisPriceLevel(ThisAction,Object.Ref);
	EndIf;

EndProcedure
