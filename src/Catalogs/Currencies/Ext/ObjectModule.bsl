
Procedure BeforeWrite(Cancel)
	
	If NewObject = True Then
		NewObject = False
	Else
		If Ref = Catalogs.Currencies.EmptyRef() Then
			NewObject = True;
		EndIf;
	EndIf;

EndProcedure


