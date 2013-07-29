
Procedure BeforeDelete(Cancel)
	// Insert handler code.
			 
	userstring = ThisObject.Description;
	userstrvalue = userstring;

	
	If ReturnCurrentUser() <> userstrvalue Then

		//DeleteObj(userobj);	
		DeleteUser(userstrvalue);
	Else
		Message("Cannot delete oneself");
		Cancel = True;
	Endif;
	
EndProcedure

&AtServer
Procedure DeleteUser(userstring)
	 //Insert handler contents.
		
	HeadersMap = New Map();
	HeadersMap.Insert("apisecretkey", Constants.APISecretKey.Get());
	
	HTTPRequest = New HTTPRequest("/deleteuser", HeadersMap);
	HTTPRequest.SetBodyFromString("user=" + userstring,TextEncoding.ANSI);
	
	SSLConnection = New OpenSSLSecureConnection();
	
	HTTPConnection = New HTTPConnection("api.accountingsuite.com",,,,,,SSLConnection);
	Result = HTTPConnection.Post(HTTPRequest);

	theuser = InfoBaseUsers.FindByName(userstring);
	
	theuser.Delete();
	

	
EndProcedure

&AtServer
Function ReturnCurrentUser()
	return SessionParameters.ACSUser;
EndFunction

//&AtServer
//Function ReturnObject()
//	return CatalogObject.UserList.ThisObject();
//EndFunction

