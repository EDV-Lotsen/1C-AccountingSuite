
Procedure BeforeWrite(Cancellation)
	
	If IBUserID <> New UUID("00000000-0000-0000-0000-000000000000") And
	     Users.UserByIDExists(IBUserID, Ref) Then
	
		Raise(NStr("en = 'One system login can be connected only to one user!'"));
	EndIf;
	
EndProcedure

Procedure BeforeDelete(Cancellation)
	
	If Users.IBUserExists(IBUserID) Then
		ErrorDescription = "";
		If NOT Users.DeleteIBUsers(IBUserID, ErrorDescription) Then
			Raise(ErrorDescription);
		EndIf;
	EndIf;
	
EndProcedure
