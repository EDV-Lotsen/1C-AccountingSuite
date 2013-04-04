
//------------------------------------------------------------------------------
// SPECIFICATION OF THE PARAMETERS PASSED TO THE FORM
//
//	Account*		- ValueList, CatalogRef.EMailAccounts
//						if type is value list, then
//						presentation - account description,
//						value 		 - ref to account
//
//	ToWhom			- ValueList, String:
//						if value list, then presentation is - recipient name
//												value       - e-mail address
//						if string then list of e-mail addresses,
//						in the format of correct e-mail address*
//
//	Attachments		- ValueList, where
//						presentation - string 		- attachment description
//						value        - BinaryData 	- attachment binary data
//									 - String 		- file address in temporary storage
//									 - String 		- path to file at client
//
//	DeleteFilesAfterSend - boolean - delete files in local file system
//								after successful sending
//
//	Subject				- String - message subject
//	Body				- String - message body
//	ResponseAddress		- String - address which will be used for response
//								   by message recipients
//
// Use
//
// *format of correct e-mail addresse:
// Z = ([User Name] [<]user@mailserver[>][;]), String = Z[Z]..
//
// Value to return:
//
// Undefined
//
// Boolean: true 	- message has been sent successfully
//			false   - message has not been sent
//
//------------------------------------------------------------------------------
// FORM OPERATION SPECIFICATION
//
// If in the list of the passed accounts is more than one record, then option
// to select the account, used for sending the message,
// will appear on the form.
// If files to be attached exist on the 1C:Enterprise server, then
// ref to binary data in temporary storage, but not binary data
// should be passed as a parameter.
//
//------------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
// SECTION OF FORM AND FORM ITEMS EVENT HANDLERS
//

// Handler of event "OnCreateAtServer" of form
// Fills form fields using parameters passed to the form
//
// Form parameters:
// UserAccount*  - CatalogRef.EMailAccounts, list -
//               	ref to account, that will be used
//              	on message send, or list of accounts (for choice)
// Attachments   - map    	  - message attachments, where
//                 key        - filename
//                 value 	  - file binary data
// Subject       - string 	  - message subject
// Body          - string 	  - message body
// ToWhom        - map/string - message addressees
//                 if type is a map, then
//                 key        - string - Recipient name
//                 value 	  - string - electronic address as: addr@server
//
&AtServer
Procedure OnCreateAtServer(Cancellation, StandardProcessing)
	
	
	LetterSubject 	= Parameters.Subject;
	LetterBody 		= Parameters.Body;
	ResponseAddress = Parameters.ResponseAddress;
	
	MessageAttachments = Parameters.Attachments;
	
	// mark those attachments, that are the paths to files at client
	For Each DetailsAttachment in MessageAttachments Do
		If TypeOf(DetailsAttachment.Value) = Type("String") Then
			If IsTempStorageURL(DetailsAttachment.Value) Then
				DetailsAttachment.Value = GetFromTempStorage(DetailsAttachment.Value);
			Else
				DetailsAttachment.Check = True; // This is file path in local file system
			EndIf;
		EndIf;
	EndDo;
	
	// processing form complex parameters (of composite type)
	// UserAccount, ToWhom
	SetPrivilegedMode(True);
	If		TypeOf(Parameters.UserAccount) = Type("CatalogRef.EMailAccounts") Then
		UserAccount = Parameters.UserAccount;
		PasswordIsAssigned = ValueIsFilled(UserAccount.Password);
	Else
		If TypeOf(Parameters.UserAccount) = Type("ValueList") Then
			SetOfUserAccounts = Parameters.UserAccount;
			If SetOfUserAccounts.Count() = 0 Then
				TextOfMessage = NStr("en = 'Account records to send the mail message have not been defined'");
				Cancellation = True;
			EndIf;
		Else
			TextOfMessage = NStr("en = 'Account records to send the mail message have not been defined'");
			Cancellation = True;
		EndIf;
		
		If Cancellation Then
			CommonUseClientServer.MessageToUser(TextOfMessage);
			Return;
		EndIf;
		
		PasswordIsSetMas = New Array;
		
		For Each ItemAccount In SetOfUserAccounts Do
			Items.UserAccount.ChoiceList.Add(
										ItemAccount.Value,
										ItemAccount.Presentation);
			If ItemAccount.Value.UseForReceiving Then
				ResponseAddressesByAccountRecords.Add(ItemAccount.Value,
														GetMailAddressByAccount(ItemAccount.Value));
			EndIf;
			If ValueIsFilled(ItemAccount.Value.Password) Then
				PasswordIsSetMas.Add(ItemAccount.Value);
			EndIf;
		EndDo;
		PasswordIsAssigned = New FixedArray(PasswordIsSetMas);
		Items.UserAccount.ChoiceList.SortByPresentation();
		UserAccount = SetOfUserAccounts[0].Value;
		Items.UserAccount.ChoiceListButton = True;
	EndIf;
	
	If	TypeOf(Parameters.ToWhom) = Type("ValueList") Then
		RecipientMailAddress = "";
		For Each ItemMailAddress In Parameters.ToWhom Do
			If ValueIsFilled(ItemMailAddress.Presentation) then
				RecipientMailAddress = RecipientMailAddress
										+ ItemMailAddress.Presentation
										+ " <"
										+ ItemMailAddress.Value
										+ ">; "
			Else
				RecipientMailAddress = RecipientMailAddress 
										+ ItemMailAddress.Value
										+ "; ";
			EndIf;
		EndDo;
	ElsIf TypeOf(Parameters.ToWhom) = Type("String") Then
		RecipientMailAddress = Parameters.ToWhom;
	EndIf;
	
	// Get list of addresses, used earlier by user
	ResponseAddressesList = CommonSettingsStorage.Load("NewEmailEditing", "ResponseAddressesList", , CommonUse.CurrentUser());
	
	If ResponseAddressesList <> Undefined And ResponseAddressesList.Count() > 0 Then
		For Each OfItemResponseAddress In ResponseAddressesList Do
			Items.ResponseAddress.ChoiceList.Add(OfItemResponseAddress.Value, OfItemResponseAddress.Presentation);
		EndDo;
		Items.ResponseAddress.ChoiceListButton = True;
	EndIf;
	
	If ValueIsFilled(ResponseAddress) Then
		AutomaticResponseAddressSubstitution = False;
	Else
		If UserAccount.UseForReceiving Then
			// set address by default
			If ValueIsFilled(UserAccount.UserName) then
				ResponseAddress = UserAccount.UserName + " <" + UserAccount.EmaiAddress + ">";
			Else
				ResponseAddress = UserAccount.EmaiAddress;
			EndIf;
		EndIf;
		
		AutomaticResponseAddressSubstitution = True;
	EndIf;
	
EndProcedure

&AtServerNoContext
Function GetMailAddressByAccount(Val UserAccount)
	
	Return TrimAll(UserAccount.UserName)
			+ ? (IsBlankString(TrimAll(UserAccount.UserName)),
					UserAccount.EmaiAddress,
					" <" + UserAccount.EmaiAddress + ">");
	
EndFunction

// Handler of form events "on open"
// Calls attachment list filling function
//
&AtClient
Procedure OnOpen(Cancellation)
	
	RefreshAttachmentPresentation();
	
EndProcedure

// Handler click event of button "Send message" of form
//
&AtClient
Procedure SendLetterExecute()
	
	ClearMessages();
	
	Try
		GivenMailAddress = CommonUseClientServer.ParseEmailString(RecipientMailAddress);
	Except
		CommonUseClientServer.MessageToUser(
				BriefErrorDescription(ErrorInfo()), ,
				RecipientMailAddress);
		Return;
	EndTry;
	
	If ValueIsFilled(ResponseAddress) Then
		Try
			GivenResponseAddress = CommonUseClientServer.ParseEmailString(ResponseAddress);
		Except
			CommonUseClientServer.MessageToUser(
					BriefErrorDescription(ErrorInfo()), ,
					"ResponseAddress");
			Return;
		EndTry;
	EndIf;
	
	Password = Undefined;
	
	If ((TypeOf(PasswordIsAssigned) = Type("Boolean") And Not PasswordIsAssigned)
	 Or  (TypeOf(PasswordIsAssigned) = Type("FixedArray") And PasswordIsAssigned.Find(UserAccount) = Undefined)) Then
		ParameterAccount = New Structure("UserAccount", UserAccount);
		Password = OpenFormModal("CommonForm.UserAccountPasswordConfirmation", ParameterAccount);
		If TypeOf(Password) <> Type("String") Then
			Return;
		EndIf;
	EndIf;
	
	LetterParameters = GenerateLetterParameters(GivenMailAddress, Password);
	
	If LetterParameters = Undefined Then
		CommonUseClientServer.MessageToUser(NStr("en = 'Error of generating parameters of the mail message'"));
		Return;
	EndIf;
	
	Try
		Emails.SendEmail(UserAccount, LetterParameters);
	Except
		CommonUseClientServer.MessageToUser(BriefErrorDescription(ErrorInfo()));
		Return;
	EndTry;
	
	SaveResponseAddress(ResponseAddress);
	DoMessageBox(NStr("en = 'Message is sent successfully'"));
	
	SetStatusOfSentMessage();
	
EndProcedure

// Handler of event "choice processing" of field Account
//  Substitutes response address, if flag of automatic response substitution
// is on.
//
&AtClient
Procedure AccountChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	If AutomaticResponseAddressSubstitution Then
		ResponseAddress = ResponseAddressesByAccountRecords.FindByValue(ValueSelected).Presentation;
	EndIf;
	
EndProcedure

// Handler of event "text edit end" of field ResponseAddress.
// If entered e-mail address is different from the default filled address
//
&AtClient
Procedure ResponseAddressTextEditEnd(Item, Text, ChoiceData, StandardProcessing)
	
	If AutomaticResponseAddressSubstitution Then
		If Not ValueIsFilled(ResponseAddress)
		 OR Not ValueIsFilled(Text) Then
			AutomaticResponseAddressSubstitution = False;
		Else
			AddressMap1 = CommonUseClientServer.ParseEmailString(ResponseAddress);
			Try
				AddressMap2 = CommonUseClientServer.ParseEmailString(Text);
			Except
				MessageAboutError = BriefErrorDescription(ErrorInfo());
				CommonUseClientServer.MessageToUser(MessageAboutError, , "ResponseAddress");
				StandardProcessing = False;
				Return;
			EndTry;
				
			If NOT EMAILAddressesAreTheSame(AddressMap1, AddressMap2) Then
				AutomaticResponseAddressSubstitution = False;
			EndIf;
		EndIf;
	EndIf;
	
	ResponseAddress = GetGivenMailingAddressInFormat(Text);
	
EndProcedure

// Handler of event "choice processing" of field ResponseAddress.
// Removes flag of autosubstitution of reply addresse
//
&AtClient
Procedure ResponseAddressChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	AutomaticResponseAddressSubstitution = False;
	
EndProcedure

// Handler of event "clear" of field ResponseAddress.
//
&AtClient
Procedure ResponseAddressClear(Item, StandardProcessing)

	StandardProcessing = False;
	UpdateResponseAddressInStoredList(ResponseAddress, False);
	
	For Each OfItemResponseAddress In Items.ResponseAddress.ChoiceList Do
		If OfItemResponseAddress.Value = ResponseAddress
		   And OfItemResponseAddress.Presentation = ResponseAddress Then
			Items.ResponseAddress.ChoiceList.Delete(OfItemResponseAddress);
		EndIf;
	EndDo;
	
	ResponseAddress = "";
	
EndProcedure

// Handler of event "before delete" of field Attachments
// Deletes attachment from the list, and also calls function
// of attachments presentation table refresh
//
&AtClient
Procedure AttachmentsBeforeDelete(Item, Cancellation)
	
	AttachmentDescription = Item.CurrentData[Item.CurrentItem.Name];
	
	For Each ItemAttachment In MessageAttachments Do
		If ItemAttachment.Presentation = AttachmentDescription Then
			MessageAttachments.Delete(ItemAttachment);
		EndIf;
	EndDo;
	
	RefreshAttachmentPresentation();
	
EndProcedure

// Handler of event of button click of command bar "attach file"
//
&AtClient
Procedure AttachFileExecute()
	
	AddFileToAttachments();
	
EndProcedure

// Handler of event "before add line" of field Attachments
//
&AtClient
Procedure AttachmentsBeforeAddRow(Item, Cancellation, Clone, Parent, Folder)
	
	Cancellation = True;
	AddFileToAttachments();
	
EndProcedure

&AtClient
Procedure AttachmentsSelection(Item, RowSelected, Field, StandardProcessing)
	
	OpenAttachment();
	
EndProcedure

&AtClient
Procedure OpenFile(Command)
	OpenAttachment();
EndProcedure

&AtClient
Procedure AttachmentsDragCheck(Item, DragParameters, StandardProcessing, String, Field)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure AttachmentsDrag(Item, DragParameters, StandardProcessing, String, Field)
	
	StandardProcessing = False;
	
	If TypeOf(DragParameters.Value) = Type("File") Then
		TemporaryStorageAddress = "";
		If PutFile(TemporaryStorageAddress, DragParameters.Value.FullName, , False) Then
			Files = New Array;
			FileBeingTransmitted = New TransferableFileDescription(DragParameters.Value.Name, TemporaryStorageAddress);
			Files.Add(FileBeingTransmitted);
			AddFilesToList(Files);
			RefreshAttachmentPresentation();
		EndIf;
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// SECTION OF SERVICE FUNCTIONS
//

&AtClient
Procedure SetStatusOfSentMessage()
	
	Title 							= NStr("en = 'Message is sent'");
	Items.SendMessage1.Enabled 		= False;
	Items.Cancel.Title 				= NStr("en = 'Close'");;
	Items.EmailAddressTo.ReadOnly 	= True;
	Items.LetterSubject.ReadOnly 	= True;
	Items.LetterBody.ReadOnly 		= True;
	Items.Attachments.ReadOnly 		= True;
	Items.UserAccount.ReadOnly 		= True;
	Items.ResponseAddress.ReadOnly 	= True;
	Items.AttachFile.Enabled 		= False;
	
EndProcedure

&AtClient
Procedure OpenAttachment()
	
	If Items.Attachments.CurrentData <> Undefined Then
		AttachmentDescription = Items.Attachments.CurrentData[Items.Attachments.CurrentItem.Name];
		
		For Each AttachmentsListItem In MessageAttachments Do
			If AttachmentsListItem.Presentation = AttachmentDescription Then
				If TypeOf(AttachmentsListItem.Value) = Type("BinaryData") Then
#If WebClient Then
					AddressInTemporaryStorage = PutToTempStorage(AttachmentsListItem.Value);
					GetFile(AddressInTemporaryStorage, , True)
#Else
					File = New File(AttachmentsListItem.Presentation);
					If File.Extension = "mxl" Then
						SpreadsheetDocument = GetSpreadsheetDocumentByBinaryData(AttachmentsListItem.Value);
						SpreadsheetDocument.ReadOnly = True;
						SpreadsheetDocument.Show(AttachmentsListItem.Presentation);
					Else
						FilenameForOpen = GetTempFileName(File.Extension);
						AttachmentsListItem.Value.Write(FilenameForOpen);
						RunApp(FilenameForOpen);
					EndIf;
#EndIf
				Else
#If NOT WebClient Then
					If Right(TrimAll(AttachmentsListItem.Value), 4) = ".mxl" Then
						SpreadsheetDocument = GetSpreadsheetDocumentByBinaryData(New BinaryData(AttachmentsListItem.Value));
						SpreadsheetDocument.ReadOnly = True;
						SpreadsheetDocument.Show(AttachmentsListItem.Presentation, AttachmentsListItem.Value);
					Else
#EndIf
						RunApp(AttachmentsListItem.Value);
#If NOT WebClient Then
					EndIf;
#EndIf
				EndIf;
				Break;
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

&AtServerNoContext
Function GetSpreadsheetDocumentByBinaryData(BinaryData)
	
	FileName = GetTempFileName("mxl");
	BinaryData.Write(FileName);
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.Read(FileName);
	
	Return SpreadsheetDocument;
	
EndFunction

&AtClient
Procedure AddFileToAttachments()
	
	Var PlacedFiles;
	
	If AttachFileSystemExtension() Then
		PlacedFiles = New Array;
		If PutFiles(, PlacedFiles, "", True, ) Then
			AddFilesToList(PlacedFiles);
			RefreshAttachmentPresentation();
		EndIf;
	Else
		DoMessageBox(NStr("en = 'Web client does not have file system extension allowing to add files. '"));
	EndIf;
	
EndProcedure

&AtServer
Procedure AddFilesToList(PlacedFiles)
	
	For Each FileDetails In PlacedFiles Do
		File = New File(FileDetails.Name);
		MessageAttachments.Add(GetFromTempStorage(FileDetails.Location), File.Name);
		DeleteFromTempStorage(FileDetails.Location);
	EndDo;
	
EndProcedure

// Updates presentation of list of attachments
//
//
&AtClient
Procedure RefreshAttachmentPresentation()
	
	AttachmentsPresentation.Clear();
	
	indexOf = 0;
	
	For Each ItemAttachment In MessageAttachments Do
		If IndexOf = 0 Then
			PresentationRow = AttachmentsPresentation.Add();
		EndIf;
		
		PresentationRow["Attachment"+String(IndexOf+1)] = ItemAttachment.Presentation;
		
		IndexOf = IndexOf + 1;
		If IndexOf = 2 then
			IndexOf = 0;
		EndIf;
	EndDo;
	
EndProcedure

// Checks possibility of sending the message and if
// possible - generates send parameters
//
&AtClient
Function GenerateLetterParameters(Val GivenMailAddress,
                                    Val Password = Undefined)
	
	LetterParameters = New Structure;
	
	If ValueIsFilled(Password) Then
		LetterParameters.Insert("Password", Password);
	EndIf;
	
	If ValueIsFilled(GivenMailAddress) Then
		LetterParameters.Insert("Recipient", GivenMailAddress);
	EndIf;
	
	If ValueIsFilled(ResponseAddress) Then
		LetterParameters.Insert("ResponseAddress", ResponseAddress);
	EndIf;
	
	If ValueIsFilled(LetterSubject) Then
		LetterParameters.Insert("Subject", LetterSubject);
	EndIf;
	
	If ValueIsFilled(LetterBody) Then
		LetterParameters.Insert("Body", LetterBody);
	EndIf;
	
	If MessageAttachments.Count() > 0 Then
		Attachments = New Map;
		For Each ItemAttachment In MessageAttachments Do
			If ItemAttachment.Check Then
				BinaryData = New BinaryData(ItemAttachment.Value);
				Attachments.Insert(ItemAttachment.Presentation, BinaryData);
			Else
				Attachments.Insert(ItemAttachment.Presentation, ItemAttachment.Value);
			EndIf;
		EndDo;
		LetterParameters.Insert("Attachments", Attachments);
	EndIf;
	
	Return LetterParameters;
	
EndFunction

// Adds response address to the list of saved values
//
&AtServerNoContext
Function SaveResponseAddress(Val ResponseAddress)
	
	UpdateResponseAddressInStoredList(ResponseAddress);
	
EndFunction

// Adds response address to the list of saved values
//
&AtServerNoContext
Function UpdateResponseAddressInStoredList(Val ResponseAddress,
                                                   Val AddAddressToList = True)
	
	// Get list of addresses, used earlier by user
	ResponseAddressesList = CommonSettingsStorage.Load(
	                            "NewEmailEditing",
	                            "ResponseAddressesList", ,
	                            CommonUse.CurrentUser());
	
	If ResponseAddressesList = Undefined Then
		ResponseAddressesList = New ValueList();
	EndIf;
	
	For Each ItemResponseAddress In ResponseAddressesList Do
		If ItemResponseAddress.Value = ResponseAddress
		   And ItemResponseAddress.Presentation = ResponseAddress Then
			ResponseAddressesList.Delete(ItemResponseAddress);
		EndIf;
	EndDo;
	
	If AddAddressToList
	   And ValueIsFilled(ResponseAddress) Then
		ResponseAddressesList.Insert(0, ResponseAddress, ResponseAddress);
	EndIf;
	
	CommonSettingsStorage.Save(
	                 "NewEmailEditing",
	                 "ResponseAddressesList",
	                 ResponseAddressesList, ,
	                 CommonUse.CurrentUser());
	
EndFunction

// Compares two e-mail addresses
// Parameters
// AddressMap1 - string - first e-mail address
// AddressMap2 - string - second e-mail address
// Value to return:
// True, or False depending on the identity of e-mail addresses
//
&AtClient
Function EMAILAddressesAreTheSame(AddressMap1, AddressMap2)
	
	If AddressMap1.Count() <> 1
	 Or AddressMap2.Count() <> 1 Then
		Return False;
	EndIf;
	
	If AddressMap1[0].Presentation = AddressMap2[0].Presentation
	   And AddressMap1[0].Address         = AddressMap2[0].Address Then
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

// Returns casted e-mail address
//
&AtClient
Function GetGivenMailingAddressInFormat(Text)
	
	MailAddress = "";
	
	AddressArray = CommonUseClientServer.ParseEmailString(Text);
	
	For Each ItemAddress In AddressArray Do
		If ValueIsFilled(ItemAddress.Presentation) then
			MailAddress = MailAddress + ItemAddress.Presentation
							+ ? (IsBlankString(TrimAll(ItemAddress.Address)), "", " <" + ItemAddress.Address + ">");
		Else
			MailAddress = MailAddress + ItemAddress.Address + "; ";
		EndIf;
	EndDo;
		
	Return MailAddress;
	
EndFunction
