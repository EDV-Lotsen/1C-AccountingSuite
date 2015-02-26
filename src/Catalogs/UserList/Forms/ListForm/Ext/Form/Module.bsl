
&AtClient
Procedure OnOpen(Cancel)
	OnOpenAtServer();
EndProcedure

&AtServer
Procedure OnOpenAtServer()
	
	CurUser = InfoBaseUsers.FindByName(SessionParameters.ACSUser);
	Try
		If CurUser.Roles.Contains(Metadata.Roles.BankAccounting) = True Then
		Else
			If CurUser.Roles.Contains(Metadata.Roles.FullAccess1) = False Then
				Items.FormCommandBar.ChildItems.FormCreate.Visible  = False;
			EndIf;
		EndIf;
	Except
	EndTry;

EndProcedure

