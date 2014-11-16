
&AtClient
Procedure OnOpen(Cancel)
	OnOpenAtServer();
EndProcedure

&AtServer
Procedure OnOpenAtServer()
	
	CurUser = InfoBaseUsers.FindByName(SessionParameters.ACSUser);
	Try
		If CurUser.Roles.Contains(Metadata.Roles.FullAccess1) = False Then
			Items.FormCommandBar.ChildItems.FormCreate.Visible  = False;
		EndIf;
	Except
	EndTry;

EndProcedure

//&AtClient
//Procedure ListBeforeDeleteRow(Item, Cancel)
//	
//		
//			
//	userobj = Items.List.CurrentRow;
//	userstring = CommonUse.GetAttributeValue(userobj, "Description");

//	userstrvalue = userstring;
//	
//	
//EndProcedure

//&AtServer
//Function ReturnCurrentUser()
//	return SessionParameters.ACSUser;
//EndFunction



//&AtServer
//Procedure DeleteUser(userstring)
//	// Insert handler contents.
//	
//	HeadersMap = New Map();
//	HeadersMap.Insert("apisecretkey", Constants.APISecretKey.Get());
//	
//	HTTPRequest = New HTTPRequest("/deleteuser", HeadersMap);
//	HTTPRequest.SetBodyFromString("user=" + userstring,TextEncoding.ANSI);
//	
//	SSLConnection = New OpenSSLSecureConnection();
//	
//	HTTPConnection = New HTTPConnection("api.accountingsuite.com",,,,,,SSLConnection);
//	Result = HTTPConnection.Post(HTTPRequest);

//	theuser = InfoBaseUsers.FindByName(userstring);
//	
//	theuser.Delete();
//	

//	
//EndProcedure

//&AtClient
//Procedure ListAfterDeleteRow(Item)
//	// Insert handler contents.
//	
//	If ReturnCurrentUser() <> userstrvalue Then

//		//DeleteObj(userobj);	
//		DeleteUser(userstrvalue);
//	Else
//		Message("Cannot delete oneself");
//	Endif;

//EndProcedure
