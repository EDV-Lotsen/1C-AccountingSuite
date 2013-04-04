

////////////////////////////////////////////////////////////////////////////////
//   Module "WorkWithEmailsInterfaces", contains functions-interfaces,
// for work with emails. Must be included in every
// configuration, that contains e-mails susbsystem.
//
//   Functions do not contain specifications of parameters - they can be found
// in module, directly implementing this or that mechanism of operations with
// emails (with servers).
//

////////////////////////////////////////////////////////////////////////////////
//
// Block of overrided functions-interfaces (for calls from outside)
//

// Gets ref to account using account purpose kind
// Parameters:
// AccountPurposeKind - Enums.AccountPurposeKinds -
//                 account purpose kind
// Value returned:
// UserAccount 		  - CatalogRef.EmailAccounts - ref
//                 to account description
//
Function GetSystemAccount() Export
	
	Return Emails.GetSystemAccount();
	
EndFunction

// Checks, that system account is available
// (can be used)
//
Function SystemAccountAvailable() Export
	
	Return Emails.SystemAccountAvailable();
	
EndFunction

// Get available e-mail accounts
// Parameters:
// ForSending 		  - Boolean - If True, then only accounts allowing to send emails will be selected
// ForReceiving   - Boolean - If True, then only accounts aloowing to receive emails will be selected
// Value returned:
// AvailableAccounts - ValueTable 	- With columns:
//    Ref         	 - CatalogRef.EmailAccounts - Ref to account
//    Description 	 - String 		- Account description
//    Address        - String 		- Email address
//
Function GetAvailableEmailAccounts(Val ForSending = False, Val ForReceiving = False, Val IncludeSystemAccount = False) Export
	
	Return Emails.GetAvailableEmailAccounts(ForSending, ForReceiving, IncludeSystemAccount);
	
EndFunction

// Function implementing mechanics of email message sending
//
// Parameters:
// UserAccount 		- CatalogRef.EmailAccounts - ref to
//                 			e-mail account
// MessageParameters - Structure 		- contains all information about the message:
//                   	contains following keys:
//    Recipient*       - Array of structures, string - internet address of message recipient
//                 		Address         - string - email address
//                 		Presentation 	- string - recipient name
//
//    Subject*      - String 			- subject of email message
//    Body*      	- Email message body (plain text in encoding wiin-1251)
//    Attachments   - Map
//                 key     				- attachmentDescription - string - attachment description
//                 value 				- BinaryData - attachment data
//
// additional structure keys, that may be used:
//    ResponseAddress 	- map 	 - see fields similar to field Recipient
//    Password      	- string - password for account access
//    TextType   		- String / Enum.EmailTypes defines type of passed text
//                  available values:
//                  HTML/EmailTextTypes.HTML - email message text in HTML format
//                  PlainText/EmailMessageTextType.PlainText - plain text of email message. Displayed "as is" (default value)
//                  RichText/EmailMessageTextType.RichText - email message text in Rich Text format
//
//    note.: message parameters marked with sign '*' are mandatory
//           i.e. consider that when function runs they are already initialized
//
// Value returned:
// String - id of sent email message at smtp server
//
// COMMENT: function can call an exception, that has to be processed
//
Function SendEmail(Val UserAccount, Val MessageParameters) Export
	
	Return Emails.SendEmail(UserAccount, MessageParameters);
	
EndFunction
