
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	ThisForm.Title = Parameters.Title;
	If Parameters.MessageStatus = Enums.MessageStatus.NoStatus Then
		Items.MessageIcon.Visible = False;
	ElsIf Parameters.MessageStatus = Enums.MessageStatus.Information Then
		Items.MessageIcon.Picture = PictureLib.Information32;
	ElsIf Parameters.MessageStatus = Enums.MessageStatus.Warning Then
		Items.MessageIcon.Picture = PictureLib.Warning32;
	EndIf;
	Items.Message.Title = Parameters.Message;
EndProcedure
