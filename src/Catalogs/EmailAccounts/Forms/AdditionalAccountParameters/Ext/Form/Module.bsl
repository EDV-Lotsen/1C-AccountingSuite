
////////////////////////////////////////////////////////////////////////////////
//     FORM MODULE OF ITEM OF THE CATALOG E-MAIL ACCOUNTS     //
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
// SECTION OF FORM AND FORM ITEMS EVENT HANDLERS
//

// Handler of event "OnCreateAtServer" of form
//
&AtServer
Procedure OnCreateAtServer(Cancellation, StandardProcessing)
	
	Ref = Parameters.Ref;
	
	Fill_ListSMTPAuthentication_MT();
	Fill_ListSMTPAuthenticationMode_SP();
	
	AccountStructure = Parameters.AccountStructure;
	
	ServerWaitDuration = AccountStructure.Timeout;
	
	LeaveMessageCopiesAtServer = AccountStructure.LeaveMessageCopiesAtServer;
	LeaveMessageCopiesNumberOfDays = AccountStructure.RemoveFromServerAfter;
	
	SMTPPort = AccountStructure.SMTPPort;
	POP3Port = AccountStructure.POP3Port;
	
	POP3AuthenticationMode = AccountStructure.POP3AuthenticationMode;
	
	SMTPAuthenticationMode 		= AccountStructure.SMTPAuthenticationMode;
	SMTPUser        		 	= AccountStructure.SMTPUser;
	SMTPPassword              	= AccountStructure.SMTPPassword;
	
	SMTPAuthentication = AccountStructure.SMTPAuthentication;
	
	SMTPAuthenticationPassed = ?(SMTPAuthentication = Enums.SMTPAuthenticationSettings.NotDefined, False, True);
	
	PrepareForm();
	
EndProcedure

// Handler of event "on change" of form item "SMTPAuthentication".
// Calls procedure updating group of additional authentication
// paramaters.
//
&AtClient
Procedure SMTPAuthenticationOnChange(Item)
	
	SetAdditionalParametersBySMTPAuthentication();
	
EndProcedure

// Handler of event "on change" of form item "AdditionalSMTPAuthenticationIsRequired".
// Assignes parameters of the authentication "by default", and also
// clears them if the flag of necessity of additional SMTP authentication being cleared.
//
&AtClient
Procedure SMTPAuthenticationPassedOnChange(Item)
	
	If SMTPAuthenticationPassed Then
		Items.SMTPAuthentication.Enabled = True;
		SMTPAuthenticationMode = ?(SMTPAuthenticationMode = SMTPAuthenticationMode_None(),
		                             SMTPAuthenticationMode_ByDefault(),
		                             SMTPAuthenticationMode);
		SMTPAuthentication = SMTPAuthentication_SimilarlyPOP3();
		SetAdditionalParametersBySMTPAuthentication();
	Else
		Items.SMTPAuthentication.Enabled = False;
		SMTPAuthentication = SMTPAuthentication_NotDefined();
		SMTPAuthenticationMode = SMTPAuthenticationMode_None();
		SetAdditionalParametersBySMTPAuthentication();
	EndIf;
	
EndProcedure


// Handler of event of click on button "SetDefaultPorts".
// Initializes POP3 and SMTP ports of servers by default:
// for SMTP - 25, for POP3 - 110.
//
&AtClient
Procedure SetPortsByDefaultExecute()
	
	SMTPPort = 25;
	POP3Port = 110;
	
EndProcedure

// Handler of event "on change" of form item "LeaveMessageCopiesAtServer".
//
&AtClient
Procedure LeaveCcMessageAtServerOnChange(Item)
	
	If LeaveMessageCopiesAtServer Then
		Items.LeaveMessageCopiesNumberOfDays.Enabled = True;
	Else
		Items.LeaveMessageCopiesNumberOfDays.Enabled = False;
	EndIf;
	
EndProcedure

// Handler of click event of button "FillAddParametersAndReturn".
// Checks correctness of the form attribute values and returns
// control to the calling code with filled additional parameters
// of the e-mail account.
//
&AtClient
Procedure FillAddParametersAndReturnExecute()
	
	If SMTPAuthenticationPassed
	   And SMTPAuthentication <> SMTPAuthentication_SimilarlyPOP3()
	   And SMTPAuthentication <> SMTPAuthentication_SpecifiedAsParameters()
	   And SMTPAuthentication <> SMTPAuthentication_POP3BeforeSMTP() Then
		CommonUseClientServer.MessageToUser(
		              NStr("en = 'It is required to choose the methods of SMTP authentication'"));
		Return;
	EndIf;
	
	Notify("SetAdditionalOptionsOfEMailAccount", FillExtendedParameters(), Ref);
	
	Close();
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// SECTION OF SERVICE FUNCTIONS
//

// Function, generating settings parameters before passing them to the calling code.
//
// Value returned:
// Structure
// key "SMTPPort", value - number, port SMTP
// key "POP3Port", value - number, port POP3
// key "LeaveMessageCopiesAtServer" - boolean - flag indicating, that messages should be kept at server
// key "RemoveFromServerAfter" 		- number - number of days, to store message at server
// key "ServerWaitDuration", value 	- number of second to wait for operation success at server
// key "SMTPAuthentication", Enum.SMTPAuthentication
// key "SMTPUser", value 			- string, SMTP authentication username
// key "SMTPPassword", value 		- string, SMTP authentication password
// key "SMTPAuthenticationMode"*, Enum.SMTPAuthenticationMode
//
// key "POP3AuthenticationMode" - Enum.POP3AuthenticationMode
//
// *- on authentication "SimilarlyPOP3" authentication type is not being assined,
//    meanwhile it is being copied
//
// All fields are filled, despite the authentication parameters. Thus we just need to get these paramaters
// 'as is' without additional data processors from calling code.
//
&AtClient
Function FillExtendedParameters()
	
	Result = New Structure;
	
	Result.Insert("SMTPPort", SMTPPort);
	Result.Insert("POP3Port", POP3Port);
	
	Result.Insert("LeaveMessageCopiesAtServer", LeaveMessageCopiesAtServer);
	LeaveMessageCopiesNumberOfDays = ?(	 LeaveMessageCopiesAtServer,
	                                     LeaveMessageCopiesNumberOfDays,
	                                     0);
	Result.Insert("RemoveFromServerAfter", LeaveMessageCopiesNumberOfDays);
	
	Result.Insert("ServerWaitDuration", ServerWaitDuration);
	
	If SMTPAuthenticationPassed Then
		Result.Insert("SMTPAuthentication", SMTPAuthentication);
		If SMTPAuthentication = (SMTPAuthentication_SpecifiedAsParameters()) Then
			Result.Insert("SMTPUser", 				SMTPUser);
			Result.Insert("SMTPPassword", 			SMTPPassword);
			Result.Insert("SMTPAuthenticationMode", SMTPAuthenticationMode);
		Else
			Result.Insert("SMTPUser", "");
			Result.Insert("SMTPPassword", "");
			Result.Insert("SMTPAuthenticationMode", SMTPAuthenticationMode_None());
		EndIf;
	Else
		Result.Insert("SMTPAuthentication", SMTPAuthentication_NotDefined());
		Result.Insert("SMTPUser", "");
		Result.Insert("SMTPPassword", "");
		Result.Insert("SMTPAuthenticationMode", SMTPAuthenticationMode_None());
	EndIf;
	
	Result.Insert("POP3AuthenticationMode", POP3AuthenticationMode);
	
	Return Result;
	
EndFunction

// Prepares form for use - fills different
// choice lists, adjusts items accessibility, values
// by default. Does not fill form attributes by passed parameters.
//
&AtServer
Procedure PrepareForm()
	
	If SMTPAuthenticationPassed Then
		Items.SMTPAuthentication.Enabled = True;
	Else
		Items.SMTPAuthentication.Enabled = False;
	EndIf;
	
	If LeaveMessageCopiesAtServer Then
		Items.LeaveMessageCopiesNumberOfDays.Enabled = True;
	Else
		Items.LeaveMessageCopiesNumberOfDays.Enabled = False;
	EndIf;
	
	Items.GroupSMTPAuthentication.CurrentPage = ?(SMTPAuthentication = Enums.SMTPAuthenticationSettings.SpecifiedAsParameters,
	                                                      Items.GroupOptions,
	                                                      Items.GroupEmptyPage);
	
EndProcedure

// Procedure updates visibility of the authentication parameters
// for choice of the authentication method "ParametersAreSpecified".
//
&AtClient
Procedure SetAdditionalParametersBySMTPAuthentication()
	
	Items.GroupSMTPAuthentication.CurrentPage =
	                  ?(SMTPAuthentication = SMTPAuthentication_SpecifiedAsParameters(),
	                   Items.GroupOptions,
	                   Items.GroupEmptyPage);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// BLOCK OF SERVICE FUNCTIONS FOR OPTIMIZATION OF THE ENUMERATION CALLS
// - SMTPAuthentication
// - POP3AuthenticationMode
// - SMTPAuthenticationMode
// FROM CLIENT PROCEDURES
//

&AtServer
Function Fill_ListSMTPAuthentication_MT()
	
	ListSMTPAuthentication_MT.Add(Enums.SMTPAuthenticationSettings.POP3BeforeSMTP,
	                                     "POP3BeforeSMTP");
	ListSMTPAuthentication_MT.Add(Enums.SMTPAuthenticationSettings.SimilarlyPOP3,
	                                     "SimilarlyPOP3");
	ListSMTPAuthentication_MT.Add(Enums.SMTPAuthenticationSettings.SpecifiedAsParameters,
	                                     "SpecifiedAsParameters");
	ListSMTPAuthentication_MT.Add(Enums.SMTPAuthenticationSettings.NotDefined,
	                                     "NotDefined");
	
EndFunction

&AtClient
Function SMTPAuthentication_POP3BeforeSMTP()
	
	Return ListSMTPAuthentication_MT[0].Value;
	
EndFunction

&AtClient
Function SMTPAuthentication_SimilarlyPOP3()
	
	Return ListSMTPAuthentication_MT[1].Value;
	
EndFunction

&AtClient
Function SMTPAuthentication_SpecifiedAsParameters()
	
	Return ListSMTPAuthentication_MT[2].Value;
	
EndFunction

&AtClient
Function SMTPAuthentication_NotDefined()
	
	Return ListSMTPAuthentication_MT[3].Value;
	
EndFunction

&AtServer
Function Fill_ListSMTPAuthenticationMode_SP()
	
	ListSMTPAuthenticationMode_MT.Add(Enums.SMTPAuthenticationMethods.CramMD5,
	                                     "CramMD5");
	ListSMTPAuthenticationMode_MT.Add(Enums.SMTPAuthenticationMethods.Login,
	                                     "Login");
	ListSMTPAuthenticationMode_MT.Add(Enums.SMTPAuthenticationMethods.Plain,
	                                     "Plain");
	ListSMTPAuthenticationMode_MT.Add(Enums.SMTPAuthenticationMethods.None,
	                                     "None");
	ListSMTPAuthenticationMode_MT.Add(Enums.SMTPAuthenticationMethods.Default,
	                                     "Default");
	
EndFunction

&AtClient
Function SMTPAuthenticationMode_None()
	
	Return ListSMTPAuthenticationMode_MT[3].Value;
	
EndFunction

&AtClient
Function SMTPAuthenticationMode_ByDefault()
	
	Return ListSMTPAuthenticationMode_MT[4].Value;
	
EndFunction
