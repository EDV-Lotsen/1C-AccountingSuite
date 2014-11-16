
Procedure BeforeWrite(Cancel)
	If IsNew() Then
		NewObject = True;
	Else
		NewObject = False;
	EndIf;
EndProcedure
