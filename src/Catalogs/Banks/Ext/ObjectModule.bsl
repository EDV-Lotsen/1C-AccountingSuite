Procedure OnWrite(Cancel)
	
	If ValueIsFilled(ThisObject.Icon.Get()) Then
		ThisObject.IconUrl = GetURL(ThisObject, "Icon");
	Else
		ThisObject.IconUrl = "";
	EndIf;
	
EndProcedure
