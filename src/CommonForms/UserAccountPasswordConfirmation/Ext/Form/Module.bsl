
//------------------------------------------------------------------------------
// SPECIFICATION OF THE PARAMETERS PASSED TO THE FORM
//
// UserAccount*  - CatalogRef.EMailAccounts
//
// Value to return:
//
// Undefined  - user hasn't entered the password
// Structure  -
//            key "Status", boolean 	- true or false depending if call is successful
//            key "Password", string 	- if status is True contains password
//            key "MessageAboutError" 	- in case if status is True contains message
//                                       error text
//
//------------------------------------------------------------------------------
// FORM OPERATION SPECIFICATION
//
// If in the list of the passed accounts is more than one record, then option
// to select the account, used for sending the message,
// will appear on the form.
//
//------------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
// SECTION OF FORM AND FORM ITEMS EVENT HANDLERS
//

// Handler of event "OnCreateAtServer" of form
//
&AtServer
Procedure OnCreateAtServer(Cancellation, StandardProcessing)
	
	If Parameters.UserAccount.IsEmpty() Then
		Cancellation = True;
		Return;
	EndIf;
	
	UserAccount = Parameters.UserAccount;
	
	Result = LoadPassword();
	
	If ValueIsFilled(Result) Then
		Password = Result;
		PasswordConfirmation = Result;
		DoPasswordSave = True;
	Else
		Password = "";
		PasswordConfirmation = "";
		DoPasswordSave = False;
	EndIf;
	
EndProcedure

// Handler of event press button "Continue"
//
&AtClient
Procedure SavePasswordAndContinueExecute()
	
	If Password <> PasswordConfirmation Then
		CommonUseClientServer.MessageToUser(
						NStr("en = 'Password and password conformation do not match'"), , "Password");
		Return;
	EndIf;
	
	If DoPasswordSave Then
		SavePassword(Password);
	Else
		SavePassword(Undefined);
	EndIf;
	
	Close(Password);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// SECTION OF SERVICE FUNCTIONS
//

// Saves value in IB settings system storage
//
&AtServer
Procedure SavePassword(Value)
	
	CommonSettingsStorage.Save(
	               "AccountPasswordConfirmationForm",
	               UserAccount,
	               Value, ,
	               CommonUse.CurrentUser());
	
EndProcedure

// Obtains value from IB settings system storage
//
&AtServer
Function LoadPassword()
	
	Value = CommonSettingsStorage.Load(
	               "AccountPasswordConfirmationForm",
	               UserAccount, ,
	               CommonUse.CurrentUser());
	
	Return Value;
	
EndFunction
