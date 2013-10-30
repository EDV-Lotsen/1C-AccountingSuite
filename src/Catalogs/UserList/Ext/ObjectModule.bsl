﻿
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

