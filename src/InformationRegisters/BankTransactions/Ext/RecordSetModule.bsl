//For a new records need to assign an UUID
Procedure BeforeWrite(Cancel, Replacing)
	For Each Record In ThisObject Do
		If Not ValueIsFilled(Record.ID) then
			Record.ID = New UUID;
			If ThisObject.Filter.ID.Use Then
				ThisObject.Filter.ID.Value = Record.ID;
			EndIf;
		EndIf;
	EndDo;
EndProcedure
