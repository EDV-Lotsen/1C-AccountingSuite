
////////////////////////////////////////////////////////////////////////////////
// MODULE CONTAINS IMPLEMENTATION OF OPERATION MECHANICS WITH EMAILS
// (program interfaces for external use)
//

// Function for sending messages. Checks correctness of filling the account
// and calls function responding for sending
//
// see parameters of the function SendMessage
//
Function SendEmail(Val EmailAccount, Val MessageParameters) Export
	
	If TypeOf(EmailAccount) <> Type("CatalogRef.EmailAccounts")
	   Or Not ValueIsFilled(EmailAccount) Then
		Raise NStr("en = 'The e-mail account is not filled or not filled correctly'");
	EndIf;
	
	If MessageParameters = Undefined Then
		Raise NStr("en = 'E-mail sending paramenters are not set!'");
	EndIf;
	
	Recipient = "";
	If MessageParameters.Property("Recipient", Recipient) Then
		If TypeOf(Recipient) = Type("String") Then
			MessageParameters.Recipient = CommonUseClientServer.ParseEmailString(Recipient);
		EndIf;
	Else
		Raise NStr("en = 'No recipients are specified'");
	EndIf;
	
	Cc = "";
	If MessageParameters.Property("Cc", Cc) Then
		If TypeOf(Cc) = Type("String") Then
			MessageParameters.Cc = CommonUseClientServer.ParseEmailString(Cc);
		EndIf;
	EndIf;
	
	Bcc = "";
	If MessageParameters.Property("Bcc", Bcc) Then
		If TypeOf(Bcc) = Type("String") Then
			MessageParameters.Bcc = CommonUseClientServer.ParseEmailString(Bcc);
		EndIf;
	EndIf;
	
	ResponseAddress = Undefined;
	
	// verify if ResponseAddress is filled correctly
	If MessageParameters.Property("ResponseAddress", ResponseAddress) Then
		MessageParameters.ResponseAddress = CommonUseClientServer.ParseEmailString(ResponseAddress);
	EndIf;
	
	Attachments = Undefined;
	
	If MessageParameters.Property("Attachments", Attachments) Then
		For Each Attachment In Attachments Do
			If IsTempStorageURL(Attachment.Value) Then
				Attachments.Insert(Attachment.Key, GetFromTempStorage(Attachment.Value));
			EndIf;
		EndDo;
		MessageParameters.Attachments = Attachments;
	EndIf;
	
	Return SendMessage(EmailAccount, MessageParameters);
	
EndFunction

// Function loads messages. Checks if account is filled correctly
// and calls function responding for loading messages.
//
// function parameters see in function ReceiveMessages
//
Function ReceiveEmails(Val EmailAccount, Val LoadingParameters = Undefined) Export
	
	If Not EmailAccount.UseForReceiving Then
		Raise NStr("en = 'The e-mail account is not configured for receiving messages.'");
	EndIf;
	
	Result = ReceiveMessages(EmailAccount, LoadingParameters);
	
	Return Result;
	
EndFunction

// Gets ref to account using account purpose kind
// Parameters:
// AccountPurposeKind - Enums.AccountPurposeKinds -
//                 account purpose kind
// Value returned:
// EmailAccount 		  - CatalogRef.EmailAccounts - ref
//                 to account description
//
Function GetSystemAccount() Export
	
	Return Catalogs.EmailAccounts.SystemEmailAccount;
	
EndFunction

// Checks, that predefined system e-mail account
// can be used
//
Function SystemAccountAvailable() Export
	
	If Not AccessRight("Read", Metadata.Catalogs.EmailAccounts) Then
		Return False;
	EndIf;
	
	QueryText =
		"SELECT ALLOWED
		|	EmailAccounts.Ref AS Ref
		|FROM
		|	Catalog.EmailAccounts AS EmailAccounts
		|WHERE
		|	EmailAccounts.Ref = &Ref";
	
	Query = New Query;
	Query.Text = QueryText;
	Query.Parameters.Insert("Ref", Catalogs.EmailAccounts.SystemEmailAccount);
	If Query.Execute().IsEmpty() Then
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

// Get available e-mail accounts
// Parameters:
// ForSending 				- Boolean - If True, then only accounts allowing to send emails will be selected
// ForReceiving   		- Boolean - If True, then only accounts aloowing to receive emails will be selected
// Value returned:
// AvailableAccounts 	- ValueTable - With columns:
//    Ref       		- CatalogRef.EmailAccounts - Ref to account
//    Description 		- String 	 - Account description
//    Address       	- String 	 - InternetMail address
//
Function GetAvailableEmailAccounts(Val ForSending,
										Val ForReceiving,
										Val IncludeSystemAccount) Export
	
	QueryText = 
	"SELECT ALLOWED
	|	EmailAccounts.Ref AS Ref,
	|	EmailAccounts.Description AS Description,
	|	EmailAccounts.EmaiAddress AS Address
	|FROM
	|	Catalog.EmailAccounts AS EmailAccounts";
	
	If ForSending Or ForReceiving Then
		StrConditions = ?(ForSending, "EmailAccounts.UseForSending", "");
		StrConditions = StrConditions + ?(ForSending And ForReceiving, " And ", "");
		StrConditions = StrConditions + ?(ForReceiving, "EmailAccounts.UseForReceiving", "");
		QueryText 	  = QueryText + "
			|WHERE " + StrConditions;
	Else
		QueryText = QueryText + "
			|WHERE";
	EndIf;
	
	Query = New Query;
	Query.Text = QueryText;
	
	If NOT IncludeSystemAccount Then
		Query.Text = Query.Text +
		"
		|	EmailAccounts.Ref <> &SystemAccount";
		Query.Parameters.Insert("SystemAccount", Catalogs.EmailAccounts.SystemEmailAccount);
	EndIf;
	
	Return Query.Execute().Unload();
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Function of sending - implementation of sending mechanics
// of email message itself
//
// Function, implementing sending mechanics of email message
//
// Parameters:
// EmailAccount - CatalogRef.EmailAccounts - ref to
//                 e-mail account
// MessageParameters - Structure - contains all information about the message:
//                   contains following keys:
//    Recipient*       - Array of structures, string - internet address of message recipient
//                 Address          - string - email address
//                 Presentation 	- string - recipient name
//    Cc       - 	Array of structures, string - internet addresses of message recipients
//                 is used to generate a message for copy field
//                 in case of array of structures, format of every structure is:
//                 Address          - string - email address (required filled)
//                 Presentation 	- string - recipient name
//    Bcc - 		Array of structures, string - internet addresses of message recipients
//                 is used to generate a message for the field of blind copies
//                 in case of array of structures, format of every structure is:
//                 Address          - string - email address (required filled)
//                 Presentation 	- string - recipient name
//
//    Subject*      - String - subject of email message
//    Body*      	- InternetMail message body (plain text in encoding wiin-1251)
//    Attachments   - map
//                	Key     - attachmentDescription - string - attachment description
//                 	Value 	- BinaryData - attachment data
//
// additional structure keys, that may be used:
//    ResponseAddress 	- Map 	 - see fields similar to field Recipient
//    Password      	- string - password for account access
//    TextType   		- String / Enum.EmailTextTypes/EmailMessageTextType defines type of passed text
//            			  available values:
//                  HTML/EmailTextTypes.HTML 				 - email message text in HTML format
//                  PlainText/EmailMessageTextType.PlainText - plain text of email message. Displayed "as is" (default value)
//                  RichText/EmailMessageTextType.RichText 	 - email message text in Rich Text format
//
//    note.: parameters noted with '*' are required
//           i.e. consider that when function runs they are already initialized
//
// Value returned:
// String - id of sent email message at smtp server
//
// COMMENT: function can call an exception, that has to be processed
//
Function SendMessage(Val EmailAccount, Val MessageParameters) Export
	
	// Declaration of variables before first use
	// as parameter of method Property of structure MessageParameters.
	// Variables contain values of parameters passed to function.
	Var Recipient, Subject, Body, Attachments, ResponseAddress, TextType, Cc, Bcc;
	
	If Not MessageParameters.Property("Subject", Subject) Then
		Subject = "";
	EndIf;
	
	If Not MessageParameters.Property("Body", Body) Then
		Body = "";
	EndIf;
	
	Recipient = MessageParameters.Recipient;
	
	If TypeOf(Recipient) = Type("String") Then
		Recipient = CommonUseClientServer.ParseEmailString(Recipient);
	EndIf;
	
	MessageParameters.Property("Attachments", Attachments);
	
	InternetMail = New InternetMailMessage;
	InternetMail.Subject = Subject;
	
	// generate recipient address
	For Each RecipientMailAddress In Recipient Do
		Recipient = InternetMail.To.Add(RecipientMailAddress.Address);
		Recipient.DisplayName = RecipientMailAddress.Presentation;
	EndDo;
	
	If MessageParameters.Property("Cc", Cc) Then
		// generate recipient address of Copy field
		For Each RecipientMailAddressCC In Cc Do
			Recipient = InternetMail.Cc.Add(RecipientMailAddressCC.Address);
			Recipient.DisplayName = RecipientMailAddressCC.Presentation;
		EndDo;
	EndIf;
	
	If MessageParameters.Property("Bcc", Bcc) Then
		// generate recipient address of Copy field
		For Each RecipientMailAddressBCC In Bcc Do
			Recipient = InternetMail.Bcc.Add(RecipientMailAddressBCC.Address);
			Recipient.DisplayName = RecipientMailAddressBCC.Presentation;
		EndDo;
	EndIf;
	
	// generate response address, if required
	If MessageParameters.Property("ResponseAddress", ResponseAddress) Then
		For Each ResponseMailAddress In ResponseAddress Do
			ReturnMailAddress = InternetMail.ReplyTo.Add(ResponseMailAddress.Address);
			ReturnMailAddress.DisplayName = ResponseMailAddress.Presentation;
		EndDo;
	EndIf;
	
	// add recipient name to the message
	InternetMail.SenderName       = EmailAccount.UserName;
	InternetMail.From.DisplayName = EmailAccount.UserName;
	InternetMail.From.Address     = EmailAccount.EmaiAddress;
	
	// add attachments to the message
	If Attachments <> Undefined Then
		For Each ItemAttachment In Attachments Do
			InternetMail.Attachments.Add(ItemAttachment.Value, ItemAttachment.Key);
		EndDo;
	EndIf;

	// Set string with basis identifiers
	If MessageParameters.Property("ReasonIDs") Then
		InternetMail.SetField("References", MessageParameters.ReasonIDs);
	EndIf;
	
	// add text
	Text = InternetMail.Texts.Add(Body);
	If MessageParameters.Property("TextType", TextType) Then
		If TypeOf(TextType) = Type("String") Then
			If TextType = "HTML" Then
				Text.TextType = InternetMailTextType.HTML;
			ElsIf TextType = "RichText" Then
				Text.TextType = InternetMailTextType.RichText;
			Else
				Text.TextType = InternetMailTextType.PlainText;
			EndIf;
		ElsIf TypeOf(TextType) = Type("EnumRef.EmailTypes") Then
			If TextType = Enums.EmailTypes.HTML
				  Or TextType = Enums.EmailTypes.HtmlWithPictures Then
				Text.TextType = InternetMailTextType.HTML;
			ElsIf TextType = Enums.EmailTypes.RichText Then
				Text.TextType = InternetMailTextType.RichText;
			Else
				Text.TextType = InternetMailTextType.PlainText;
			EndIf;
		Else
			Text.TextType = TextType;
		EndIf;
	Else
		Text.TextType = InternetMailTextType.PlainText;
	EndIf;

	// Assign importance
	Importance = Undefined;
	If MessageParameters.Property("Importance", Importance) Then
		InternetMail.Importance = Importance;
	EndIf;
	
	// Assign encoding
	Encoding = Undefined;
	If MessageParameters.Property("Encoding", Encoding) Then
		InternetMail.Encoding = Encoding;
	EndIf;

	If MessageParameters.Property("Password") Then
		Profile = GenerateInternetProfile(EmailAccount, MessageParameters.Password);
	Else
		Profile = GenerateInternetProfile(EmailAccount);
	EndIf;
	
	Connection = New InternetMail;
	
	Connection.Logon(Profile);
	
	Connection.Send(InternetMail);
	
	Connection.Logoff();
	
	Return InternetMail.MessageID;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Function checking emails - implementation of sending mechanics
// of email message itself
//
// Function, implementing mechanics of messages downloading from mail server
// for specified e-mail account
//
// Parameters:
// EmailAccount 		- CatalogRef.EmailAccounts - ref to e-mail account
//
// LoadingParameters  - structure
// key "Columns" 	 - array - array of strings with column names
//                     columns names must correspond to object fields InternetMailMessage
// key "TestingMode" - boolean - if True then call is performed in account test
//                               mode - messages are being selected,
//                               but they are not included in returned value; by default
//                               test mode is disabled
// key "GetTitles" 	- boolean - if True then set being returned contains only message headers
// HeadersIDs 		- array - message headers or iDs, entire messages used to obtain:
//
// key "Password"   - string - password for access to POP3
//
// Value returned:
// MessagesSet*- value table, contains adapted variant of message list at server
//                 Columns of value table (by default):
//                 Importance, Attachments, PostDating, DateReceived, Caption, SenderName,
//                 Id, Cc, Reply address, From, Recipients, Size, Texts,
//                 Encoding, NonASCIISymbolsEncodingMode, Partial
//                 being filled if status is True
//
// Note. * - in test mode does not participate in generating of value being returned
//
Function ReceiveMessages(Val EmailAccount, Val LoadingParameters = Undefined)
	
	// Is used to check login possibility into mailbox
	Var TestingMode;
	
	// Get only message headers
	Var GetTitles;
	
	// Message headers or iDs, entire messages used to get
	Var HeadersIDs;
	
	If LoadingParameters.Property("TestingMode") Then
		TestingMode = LoadingParameters.TestingMode;
	Else
		TestingMode = False;
	EndIf;
	
	If LoadingParameters.Property("GetTitles") Then
		GetTitles = LoadingParameters.GetTitles;
	Else
		GetTitles = False;
	EndIf;
	
	If LoadingParameters.Property("Password") Then
		Profile = GenerateInternetProfile(EmailAccount, LoadingParameters.Password);
	Else
		Profile = GenerateInternetProfile(EmailAccount);
	EndIf;
	
	If LoadingParameters.Property("HeadersIDs") Then
		HeadersIDs = LoadingParameters.HeadersIDs;
	Else
		HeadersIDs = New Array;
	EndIf;
	
	Connection = New InternetMail;
	
	Connection.Logon(Profile);
	
	If TestingMode Or GetTitles Then
		
		LettersSet = Connection.GetHeaders();
		
	Else
		
		If EmailAccount.LeaveMessageCopiesAtServer Then
			
			If EmailAccount.RemoveFromServerAfter > 0 Then
				
				Headers = Connection.GetHeaders();
				
				MessagesSetForDelete = New Array;
				
				For Each HeaderItem In Headers Do
					CurrentDate = CurrentDate();
					DatesDifference = (CurrentDate - HeaderItem.PostDating) / (3600*24);
					If DatesDifference >= EmailAccount.RemoveFromServerAfter Then
						MessagesSetForDelete.Add(HeaderItem);
					EndIf;
				EndDo;
				
				Connection.DeleteMessages(MessagesSetForDelete);
			EndIf;
			
			DeleteMessagesOnSelectionFromServer = False;
			
		Else
			
			DeleteMessagesOnSelectionFromServer = True;
			
		EndIf;
		
		LettersSet = Connection.Get(DeleteMessagesOnSelectionFromServer, HeadersIDs);
		
	EndIf;
	
	Connection.Logoff();
	
	If TestingMode Then
		Return True;
	EndIf;
	
	If LoadingParameters.Property("Columns") Then
		MessagesSet = GetAdaptedMessagesSet(LettersSet, LoadingParameters.Columns);
	Else
		MessagesSet = GetAdaptedMessagesSet(LettersSet);
	EndIf;
	
	Return MessagesSet;
	
EndFunction

// Establishes connection with mail server
// Parameters:
// Profile       - InternetMailProfile - e-mail account profile,
//                 used, to establish connection
//
// Value returned:
// Connection (type InternetMail)
//
Function ConnectToEmailServer(Profile) Export
	
	Connection = New InternetMail;
	Connection.Logon(Profile);
	
	Return Connection;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Block of system and auxiliary subsystem functions
//

// Generates email connection profile using passed account ref
//
// Parameters
// EmailAccount - CatalogRef.ElectronicMailAccount -
//                 profile parameters represented as map
//
// Value to return:
// Mail profile (type InternetMailProfile)
//
Function GenerateInternetProfile(Val EmailAccount,
                                 Val Password = Undefined,
                                 Val CreateSMTPProfile = True,
                                 Val CreatePOP3Profile = True) Export
	
	Profile = New InternetMailProfile;
	
	Profile.User = EmailAccount.User;
	
	Profile.Timeout = EmailAccount.Timeout;
	
	If ValueIsFilled(Password) Then
		Profile.Password = Password;
	Else
		Profile.Password = EmailAccount.Password;
	EndIf;
	
	If CreateSMTPProfile Then
		Profile.SMTPServerAddress = EmailAccount.SMTPServer;
		Profile.SMTPPort          = EmailAccount.SMTPPort;
		
		If EmailAccount.SMTPAuthentication    = Enums.SMTPAuthenticationSettings.SimilarlyPOP3 Then
			Profile.SMTPAuthentication        = SMTPAuthenticationMode.Default;
			Profile.SMTPUser                  = EmailAccount.User;
			Profile.SMTPPassword              = EmailAccount.Password;
		ElsIf EmailAccount.SMTPAuthentication = Enums.SMTPAuthenticationSettings.SpecifiedAsParameters Then
			
			If EmailAccount.SMTPAuthenticationMode = Enums.SMTPAuthenticationMethods.CramMD5 Then
				Profile.SMTPAuthentication = SMTPAuthenticationMode.CramMD5;
			ElsIf EmailAccount.SMTPAuthenticationMode = Enums.SMTPAuthenticationMethods.Login Then
				Profile.SMTPAuthentication = SMTPAuthenticationMode.Login;
			ElsIf EmailAccount.SMTPAuthenticationMode = Enums.SMTPAuthenticationMethods.Plain Then
				Profile.SMTPAuthentication = SMTPAuthenticationMode.Plain;
			ElsIf EmailAccount.SMTPAuthenticationMode = Enums.SMTPAuthenticationMethods.None Then
				Profile.SMTPAuthentication = SMTPAuthenticationMode.None;
			Else
				Profile.SMTPAuthentication = SMTPAuthenticationMode.Default;
			EndIf;
			
			Profile.SMTPUser = EmailAccount.SMTPUser;
			Profile.SMTPPassword       = EmailAccount.SMTPPassword;
			
		ElsIf EmailAccount.SMTPAuthentication = Enums.SMTPAuthenticationSettings.POP3BeforeSMTP Then
			Profile.SMTPAuthentication = SMTPAuthenticationMode.None;
			Profile.POP3BeforeSMTP = True;
		Else
			Profile.SMTPAuthentication = SMTPAuthenticationMode.None;
		EndIf;
	EndIf;
	
	If CreatePOP3Profile Then
		Profile.POP3ServerAddress = EmailAccount.POP3Server;
		Profile.POP3Port          = EmailAccount.POP3Port;
		
		If EmailAccount.POP3AuthenticationMode = Enums.POP3AuthenticationMethods.APOP Then
			Profile.POP3Authentication = POP3AuthenticationMode.APOP;
		ElsIf EmailAccount.POP3AuthenticationMode = Enums.POP3AuthenticationMethods.CramMD5 Then
			Profile.POP3Authentication = POP3AuthenticationMode.CramMD5;
		Else
			Profile.POP3Authentication = POP3AuthenticationMode.General;
		EndIf;
	EndIf;
	
	Return Profile;
	
EndFunction

// Function writes adapted message set using passed columns.
// Values of columns, whose types are not supported for operation at client
// are being converted to String.
//
Function GetAdaptedMessagesSet(Val LettersSet, Val Columns = Undefined)
	
	Result = CreateAdaptedMessageDescription(Columns);
	
	For Each MailMessage In LettersSet Do
		NewRow = Result.Add();
		
		For Each ColumnDescription In Columns Do
			
			Value = MailMessage[ColumnDescription];
			
			If TypeOf(Value) = Type("InternetMailAddresses") Then
				TotalValue = "";
				For Each NextAddress  In Value Do
					TempValue =  NextAddress.Address;
					If ValueIsFilled(NextAddress.DisplayName) Then
						TempValue = NextAddress.DisplayName + " <" + TempValue + ">";
					EndIf;
					If ValueIsFilled(TempValue) Then
						TempValue = TempValue + "; "
					EndIf;
					TotalValue = TotalValue + TempValue;
				EndDo;
				
				If ValueIsFilled(TotalValue) Then
					TotalValue = mid(TotalValue, 1, StrLen(TotalValue)-2)
				EndIf;
				
				value = TotalValue;
			EndIf;
			
			If TypeOf(Value) = Type("InternetMailAddress") Then
				TempValue =  Value.Address;
				If ValueIsFilled(Value.DisplayName) Then
					TempValue = Value.DisplayName + " <" + TempValue + ">";
				EndIf;
				value = TempValue;
			EndIf;
			
			If TypeOf(Value) = Type("InternetMailMessageImportance") Then
				value = String(Value);
			EndIf;
			
			If TypeOf(Value) = Type("InternetMailMessageNonASCIISymbolsEncodingMode") Then
				value = String(Value);
			EndIf;
			
			If TypeOf(Value) = Type("InternetMailAttachments") Then
				ValueMap = New Map;
			
				For Each NextAttachment In Value Do
					AttachmentName    = NextAttachment.Name;
					BinaryData = NextAttachment.Data;
					ValueMap.Insert(AttachmentName, BinaryData);
				EndDo;
				
				value = ValueMap;
			EndIf;
			
			If TypeOf(Value) = Type("InternetMailTexts") Then
				ValueArray = New Array;
				For Each NextText In Value Do
					ValueMap = New Map;
					
					ValueMap.Insert("Data", NextText.Data);
					ValueMap.Insert("Encoding", NextText.Encoding);
					ValueMap.Insert("Text", NextText.Text);
					ValueMap.Insert("TextType", String(NextText.TextType));
					
					ValueArray.Add(ValueMap);
				EndDo;
				value = ValueArray;
			EndIf;
			
			NewRow[ColumnDescription] = Value;
		EndDo;
	EndDo;
	
	Return Result;
	
EndFunction

// Function prepares the table, where messages from mail server
// will be stored.
//
// Parameters
// Columns 		- string - list of message fields, separated by comma, which
//                    	   have to be saved to table. Parameter changes its type to array.
// Value to return:
// ValueTable 	- empty value table with columns
//
Function CreateAdaptedMessageDescription(Columns = Undefined)
	
	If Columns <> Undefined
	   And TypeOf(Columns) = Type("String") Then
		Columns = StringFunctionsClientServer.DecomposeStringIntoSubstringsArray(Columns, ",");
		For IndexOf = 0 To Columns.Count()-1 Do
			Columns[IndexOf] = TrimAll(Columns[IndexOf]);
		EndDo;
	EndIf;
	
	DefaultColumnsArray = New Array;
	DefaultColumnsArray.Add("Importance");
	DefaultColumnsArray.Add("Attachments");
	DefaultColumnsArray.Add("PostDating");
	DefaultColumnsArray.Add("DateReceived");
	DefaultColumnsArray.Add("Title");
	DefaultColumnsArray.Add("SenderName");
	DefaultColumnsArray.Add("Id");
	DefaultColumnsArray.Add("Cc");
	DefaultColumnsArray.Add("ReplyTo");
	DefaultColumnsArray.Add("From");
	DefaultColumnsArray.Add("To");
	DefaultColumnsArray.Add("Size");
	DefaultColumnsArray.Add("Subject");
	DefaultColumnsArray.Add("Texts");
	DefaultColumnsArray.Add("Encoding");
	DefaultColumnsArray.Add("NonASCIISymbolsEncodingMode");
	DefaultColumnsArray.Add("Partial");
	
	If Columns = Undefined Then
		Columns = DefaultColumnsArray;
	EndIf;
	
	Result = New ValueTable;
	
	For Each ColumnDescription In Columns Do
		Result.Columns.Add(ColumnDescription);
	EndDo;
	
	Return Result;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Block of functions of initial initialization and update of IB
//

// Fills system account with default values
//
Procedure FillSystemAccount() Export
	
	EmailAccount = Catalogs.EmailAccounts.SystemEmailAccount.GetObject();
	EmailAccount.FillObjectByDefaultValues();
	EmailAccount.Write();
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
//
// Block of functions for account check
//

&AtServer
Function PasswordIsSet(EmailAccount) Export
	
	Return ValueIsFilled(EmailAccount.Password);
	
EndFunction

&AtServer
Procedure EmailsSendingAndReceivingIsPossible(EmailAccount, PasswordParameter, ErrorMessage, AdditionalMessage) Export
	
	ErrorMessage = "";
	AdditionalMessage = "";
	
	If EmailAccount.UseForSending Then
		Try
			TestMessagesSendingIsPossible(EmailAccount, PasswordParameter);
		Except
			ErrorMessage = StringFunctionsClientServer.SubstitureParametersInString(
				NStr("en = 'Error while during the message: %1'"),
				BriefErrorDescription(ErrorInfo()) );
		EndTry;
	Else
		AdditionalMessage = Chars.LF + NStr("en = 'Note: The e-mail account is not set for sending emails'");
	EndIf;
	
	If EmailAccount.UseForReceiving Then
		Try
			CheckLoginToIncomingMailServer(EmailAccount, PasswordParameter);
		Except
			If ValueIsFilled(ErrorMessage) Then
				ErrorMessage = ErrorMessage + Chars.LF;
			EndIf;
			
			ErrorMessage = ErrorMessage
				+ StringFunctionsClientServer.SubstitureParametersInString(
						NStr("en = 'Error accessing to the incoming e-mail server: %1'"),
						BriefErrorDescription(ErrorInfo()) );
		EndTry;
	Else
		AdditionalMessage = AdditionalMessage
			+ Chars.LF
			+ NStr("en = 'Note: The e-mail account is not set for receiving e-mails'");
	EndIf;
	
EndProcedure

// Procedure checking if email message can be sent
// using the account
//
// Parameters
// EmailAccount - CatalogRef.EmailAccounts - account,
//                 that has to be checked
//
// Value to return:
// Structure
// key "status" 			- boolean, if True 				- successfully logged in to pop3 server
//                 if False - pop3 server login error
// key "ErrorMessage1" - string - if status is False 	- contains error message
//
&AtServer
Procedure TestMessagesSendingIsPossible(Val EmailAccount, Val Password = Undefined)
	
	MessageParameters = New Structure;
	
	MessageParameters.Insert("Subject",   NStr("en = '1C:Enterprise Test Message'"));
	MessageParameters.Insert("Body", 	  NStr("en = 'The email is sent by 1C:Enterprise service'"));
	MessageParameters.Insert("Recipient", EmailAccount.EmaiAddress);
	If Password <> Undefined Then
		MessageParameters.Insert("Password", Password);
	EndIf;
	
	SendEmail(EmailAccount, MessageParameters);
	
EndProcedure

// Procedure checks that email message can be received using
// using the account
//
// Parameters
// EmailAccount  - CatalogRef.EmailAccounts - account,
//                 that has to be checked
//
// Value to return:
// Structure
// key "status" - boolean, if True 	- successfully logged in to pop3 server
//                 if False 		- pop3 server login error
// key "ErrorMessage1" 		- string - if status is False - contains error message
//
&AtServer
Procedure CheckLoginToIncomingMailServer(Val EmailAccount, Val Password = Undefined)
	
	LoadingParameters = New Structure("TestingMode", True);
	
	If Password <> Undefined Then
		LoadingParameters.Insert("Password", Password);
	EndIf;
	
	ReceiveEmails(EmailAccount, LoadingParameters);
	
EndProcedure
