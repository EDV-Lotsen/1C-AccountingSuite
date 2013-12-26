
Procedure BeforeDelete(Cancel)
	
	If Constants.ServiceDB.Get() = True Then
	
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
		
	EndIf;
	
EndProcedure

&AtServer
Procedure DeleteUser(userstring)	

	
EndProcedure

&AtServer
Function ReturnCurrentUser()
	return SessionParameters.ACSUser;
EndFunction

//&AtServer
//Function ReturnObject()
//	return CatalogObject.UserList.ThisObject();
//EndFunction

