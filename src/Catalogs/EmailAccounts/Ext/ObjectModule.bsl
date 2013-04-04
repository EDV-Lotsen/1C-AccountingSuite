

Procedure Filling(FillingData, StandardProcessing)
	
	FillObjectByDefaultValues();
	
EndProcedure

Procedure FillObjectByDefaultValues() Export
	
	UserName = "1c:Enterprise";
	SMTPAuthentication = Enums.SMTPAuthenticationSettings.NotDefined;
	UseForReceiving = False;
	LeaveMessageCopiesAtServer = False;
	RemoveFromServerAfter = 0;
	Timeout = 30;
	SMTPAuthentication    = Enums.SMTPAuthenticationSettings.NotDefined;
	SMTPAuthenticationMode = Enums.SMTPAuthenticationMethods.None;
	POP3AuthenticationMode = Enums.POP3AuthenticationMethods.General;
	SMTPUser = "";
	SMTPPassword = "";
	POP3Port = 110;
	SMTPPort = 25;
	
EndProcedure
