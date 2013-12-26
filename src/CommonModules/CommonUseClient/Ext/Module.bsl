
// Shows custom message box to the user
//
// Parameters:
//  FormOwner - ManagedForm - form-owner of the message window
//  Title - String - title of the message box
//  Message - String - message text
//  MessageStatus = EnumRef.MessageStatuse - defines an icon, displaying severity of the problem
//    supported values: NoStatus, Information, Warning
//
Procedure ShowCustomMessageBox(FormOwner, Title = "", Message, MessageStatus = Undefined) Export
	If MessageStatus = Undefined Then 
		MessageStatus = PredefinedValue("Enum.MessageStatus.NoStatus");
	EndIf;
	If Not ValueIsFilled(Title) Then
		Title = "Message";
	EndIf;
	Params = New Structure("Title, Message, MessageStatus", Title, Message, MessageStatus);
	OpenForm("CommonForm.MessageBox", Params, FormOwner,,,,, FormWindowOpeningMode.LockOwnerWindow); 
EndProcedure
