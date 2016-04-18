
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
	
	If Parameters.Property("FormattedMessage") Then
		
		FormattedMessage = Parameters.FormattedMessage;
		
		Items.Message.Visible          = False;
		Items.FormattedMessage.Visible = True;
		
	Else
		
		Items.Message.Title = Parameters.Message;
		
		Items.Message.Visible          = True;
		Items.FormattedMessage.Visible = False;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FormattedMessageURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	ThisForm.Close();
	
EndProcedure
