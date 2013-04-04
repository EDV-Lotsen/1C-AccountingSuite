
////////////////////////////////////////////////////////////////////////////////
// SECTION OF FORM AND FORM ITEMS EVENT HANDLERS
//

// Handler of event "OnCreateAtServer" of form
//
&AtServer
Procedure OnCreateAtServer(Cancellation, StandardProcessing)
	
	If ValueIsFilled(Object.Password) Then
		KeepPassword = True;
	EndIf;
	
	// Hide not used items
	// if only the subsystem of work with emails is used
	If Metadata.CommonModules.Find("EMailsManagement") = Undefined Then
		Items.IncludeUserNameInPresentation.Visible = False;
	EndIf;
	
	If Object.Ref.IsEmpty() Then
		Object.UseForSending = True;
		Object.UseForReceiving = True;
	EndIf;
	
EndProcedure

// Handler of form event "before write at server"
//
&AtServer
Procedure BeforeWriteAtServer(Cancellation, CurrentObject)
	
	If NOT KeepPassword Then
		CurrentObject.Password = "";
	EndIf;
	
	If Object.SMTPAuthentication <> Enums.SMTPAuthenticationSettings.SpecifiedAsParameters Then
		Object.SMTPUser = "";
		Object.SMTPPassword = "";
	EndIf;
	
EndProcedure

// Handler of click event of button "Extra" of form
//
&AtClient
Procedure AdditionalSettingsRun()
	
	AccountStructure = New Structure;
	AccountStructure.Insert("Timeout",                    	Object.Timeout);
	AccountStructure.Insert("LeaveMessageCopiesAtServer", 	Object.LeaveMessageCopiesAtServer);
	AccountStructure.Insert("RemoveFromServerAfter", 		Object.RemoveFromServerAfter);
	AccountStructure.Insert("SMTPUser",                 	Object.SMTPUser);
	AccountStructure.Insert("SMTPPassword",                 Object.SMTPPassword);
	AccountStructure.Insert("POP3Port",                     Object.POP3Port);
	AccountStructure.Insert("SMTPPort",                     Object.SMTPPort);
	AccountStructure.Insert("SMTPAuthentication",           Object.SMTPAuthentication);
	AccountStructure.Insert("SMTPAuthenticationMode",       Object.SMTPAuthenticationMode);
	AccountStructure.Insert("POP3AuthenticationMode",       Object.POP3AuthenticationMode);
	
	CallParameters = New Structure("Ref, AccountStructure", Object.Ref, AccountStructure);
	
	OpenForm("Catalog.EMailAccounts.Form.AdditionalAccountParameters", CallParameters);
	
	
EndProcedure

// Handles the alert, coming from the form of settings of e-mail account additional properties,
// containing some e-mail account settings.
//
&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "SetAdditionalOptionsOfEMailAccount" And Source = Object.Ref Then
		Object.Timeout                    	= Parameter.ServerWaitDuration;
		Object.LeaveMessageCopiesAtServer 	= Parameter.LeaveMessageCopiesAtServer;
		Object.RemoveFromServerAfter 		= Parameter.RemoveFromServerAfter;
		Object.SMTPUser                 	= Parameter.SMTPUser;
		Object.SMTPPassword                 = Parameter.SMTPPassword;
		Object.POP3Port                     = Parameter.POP3Port;
		Object.SMTPPort                     = Parameter.SMTPPort;
		Object.SMTPAuthentication          = Parameter.SMTPAuthentication;
		Object.SMTPAuthenticationMode       = Parameter.SMTPAuthenticationMode;
		Object.POP3AuthenticationMode       = Parameter.POP3AuthenticationMode;
		Modified = True;
	EndIf;
	
EndProcedure
