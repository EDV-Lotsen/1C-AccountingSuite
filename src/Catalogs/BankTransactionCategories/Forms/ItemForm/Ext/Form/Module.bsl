
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	ThisObj = FormAttributeToValue("Object");
	If (Not ThisObj.IsNew()) AND (Not ValueIsFilled(Object.Account)) Then
		ThisForm.CurrentItem = Items.Account;
	EndIf;
EndProcedure
