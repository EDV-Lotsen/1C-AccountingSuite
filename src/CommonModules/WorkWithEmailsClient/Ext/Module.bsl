

// Interface client function supporting simplified call of edit form
// of a new message.
// Parameters
// From*  		  - ValueList, CatalogRef.EmailAccounts -
//                 account (list) used to send the message
//                 message. If type is value list, then
//                   presentation 	- account description,
//                   value 			- account ref
//
// Recipient      - ValueList, String:
//                   if value list, then presentation 	 - recipient name
//                                            value      - email address
//                   if string then list of email addresses,
//                   in the format of proper e-mail address*
//
// Subject        - String - message subject
// Text           - String - message body
//
// FileList    	  - ValueList, where
//                   presentation 	- String 	 - attachment description
//                   value      	- BinaryData - attachment binary data
//                                 	- String - file address in temporary storage
//                                 	- String - path to a file at client
//
// DeleteFilesAfterSending - boolean - delete temporary files after sending the message
// MessageShouldBeSavedAutomatically   - boolean - if message should be saved (used only
//                                      if Interaction subsystem is added-in)
//
Procedure OpenEmailMessageSendForm(Val From = Undefined,
												Val Recipient 							= Undefined,
												Val Subject 							= "",
												Val Text 								= "",
												Val FileList							= Undefined,
												Val DeleteFilesAfterSending 				= False,
												Val MessageShouldBeSavedAutomatically 	= True) Export
	
	EmailsClient.OpenEmailMessageSendForm(From,
		Recipient, Subject, Text, FileList, DeleteFilesAfterSending);
	
EndProcedure


// Checks e-mail account
//
// Parameters
// UserAccount - CatalogRef.EmailAccounts - account,
//					that has to be checked
//
Procedure CheckAccount(Val UserAccount) Export
	
	ClearMessages();
	
	Status(NStr("en = 'Check e-mail account'"),,NStr("en = 'Checking account information. Please wait...'"));
	
	If Emails.PasswordIsSet(UserAccount) Then
		PasswordParameter = Undefined;
	Else
		ParameterAccount  = New Structure("UserAccount", UserAccount);
		PasswordParameter = OpenFormModal("CommonForm.UserAccountPasswordConfirmation", ParameterAccount);
		If TypeOf(PasswordParameter) <> Type("String") Then
			Return
		EndIf;
	EndIf;
	
	ErrorMessage = "";
	AdditionalMessage = "";
	Emails.EmailsSendingAndReceivingIsPossible(UserAccount, PasswordParameter, ErrorMessage, AdditionalMessage);
	
	If ValueIsFilled(ErrorMessage) Then
		DoMessageBox(StringFunctionsClientServer.SubstitureParametersInString(
						NStr("en = 'Verification parameters of the account has completed with errors: %1'"), ErrorMessage ),,
						NStr("en = 'Check e-mail account'"));
	Else
		DoMessageBox(StringFunctionsClientServer.SubstitureParametersInString(
						NStr("en = 'Verification parameters of the account has successfully completed ! %1'"),
						AdditionalMessage ),,
						NStr("en = 'Check e-mail account'"));
	EndIf;
	
EndProcedure // CheckAccount()
