

////////////////////////////////////////////////////////////////////////////////
// Client procedures of common use

Procedure BatchObjectsChanging(List) Export
	
	SelectedRows 	= List.SelectedRows;
	
	FormParameters 	= New Structure("ObjectsArray", New Array);
	
	For Each SelectedRow In SelectedRows Do
		If TypeOf(SelectedRow) = Type("DynamicalListGroupRow") Then
			Continue;
		EndIf;
		FormParameters.ObjectsArray.Add(List.RowData(SelectedRow).Ref);
	EndDo;
	
	If FormParameters.ObjectsArray.Count() = 0 Then
		DoMessageBox(NStr("en = 'This command cannot be executed for selected object!'"));
		Return;
	EndIf;
		
	OpenForm("DataProcessor.BatchObjectsChanging.Form", FormParameters);
	
EndProcedure

// Procedure SetArbitraryApplicationTitle sets standard
// application title, using name presentation of the current user
// and string in constant ApplicationTitle (if specified) or
// current title of the application GetApplicationCaption() (if constant is not set).
//
// Parameters:
//  TitlePresentation - String, optional parameter, used for generating the application
//                 title from presentation, set by user, instead of presentation,
//                 specified in constant (or obtained via calling function GetApplicationCaption()).
//
Procedure SetArbitraryApplicationTitle() Export
	
	TitlePresentation = StandardSubsystemsOverrided.ClientParameters().ApplicationTitle;
	
	UserPresentation  = StandardSubsystemsClientSecondUse.ClientParameters().AuthorizedUser;
	
	HeaderTemplate 	  = "%MainTitle / %User /";
	
	If IsBlankString(TrimAll(TitlePresentation)) Then
		ApplicationTitle = StrReplace(HeaderTemplate, "%MainTitle", StandardSubsystemsOverrided.ClientParameters().DetailedInformation);
	Else
		ApplicationTitle = StrReplace(HeaderTemplate, "%MainTitle", TrimAll(TitlePresentation));
	EndIf;
	
	ApplicationTitle = StrReplace(ApplicationTitle, "%User", UserPresentation);
	
	SetApplicationCaption(ApplicationTitle);
	
EndProcedure

// Procedure ConvertSummerTimeToCurrentTime modifies passed
// time value to a local time from winter to current taking into account NTFS correction.
//
// Parameters:
//  Datetime    - Date, time being converted.
//
// Value returned:
//  Date 		- converted time.
//
Procedure ConvertSummerTimeToCurrentTime(Datetime) Export
	
	Datetime = ToLocalTime(Datetime);
	
EndProcedure

// Suggests to user to install the extension of work with files in web-client.
// At the same time initializing session parameter SuggestWorkWithFilesExtensionInstallationByDefault.
//
// Procedure is designated to be used in the beginning of code locks, where work with files is performed.
// For example:
//
//    SuggestWorkWithFilesExtensionInstallationNow("For document printing extension of work with files has to be installed");
//    // below document print code is located
//    //...
//
// Parameters
//  Message  - String - message text. If not specified, then default text being shown.
//
Procedure SuggestWorkWithFilesExtensionInstallationNow(Message = Undefined) Export
	
#If Not WebClient Then
	Return;  // works only in web-client
#EndIf

	IsExtensionAttached = AttachFileSystemExtension();
	If IsExtensionAttached Then
		Return; // if extension already installed - no reason to ask about it
	EndIf;	

	If CommonUseClientSecondUse.ThisIsWebClientWithoutSupportOfWorkWithFilesExtension() Then
		Return;
	EndIf;	
	
	SuggestInstallation = CommonUseClientSecondUse.GetOfferInstallationOfExtensionOfWorkWithFiles();
	
	If SuggestInstallation = False Then
		Return;
	EndIf;
	
	// show dialog here
	FormParameters  = New Structure("Message", Message);
	ReturnCode 		= OpenFormModal("CommonForm.QuestionAboutWorkWithFilesExtensionInstallation", FormParameters);
	If ReturnCode 	= Undefined Then
		ReturnCode  = True;
	EndIf;
	
	SuggestInstallation = ReturnCode;
	CommonUse.SaveSuggestWorkWithFilesExtensionInstallation(SuggestInstallation);
	RefreshReusableValues();

EndProcedure 

////////////////////////////////////////////////////////////////////////////////
// Functions for processing user actions during edit process of
// multiline text, for example comment in documents

// Opens edit form of arbitraty multiline text in modal mode
//
// Parameters:
// MultilineText      - String - arbitrary text, that has to be edited
// EditResult 		  - String - variable, where edit result vill be placed
// Modified      	  - String - flag indicating if form was modified
// Title              - String - text, that has to be displayed in form title
//
Procedure OpenMultilineTextEditForm(Val MultilineText, EditResult, Modified = False, 
		Val Title = Undefined) Export
	
	If Title = Undefined Then
		TextEntered = InputString(MultilineText,,, True);
	Else
		TextEntered = InputString(MultilineText, Title,, True);
	EndIf;
	
	If Not TextEntered Then
		Return;
	EndIf;
		
	EditResult = MultilineText;
	If Not Modified Then
		Modified = True;
	EndIf;
	
EndProcedure

// Opens edit form of multiline comment in modal mode
//
// Parameters:
// MultilineText     - String - arbitrary text, that has to be edited
// EditResult 		 - String - variable, where edit result vill be placed
// Modified       	 - String - flag indicating if form was modified
//
Procedure OpenCommentEditForm(Val MultilineText, EditResult,
	Modified = False) Export
	
	OpenMultilineTextEditForm(MultilineText, EditResult, Modified, 
		NStr("en = 'Comment'"));
	
EndProcedure
