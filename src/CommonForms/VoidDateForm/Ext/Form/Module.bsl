
&AtClient
Procedure AcceptButton(Command)
	ThisForm.Close(VoidDate);
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	VoidDate = CurrentSessionDate();
EndProcedure
