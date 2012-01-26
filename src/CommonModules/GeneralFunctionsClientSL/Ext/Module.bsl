// Offers to a user to install the web-client file extension module,
// and if the installation is rejected notifies that the operation can't be continued.
//
// Designed for use in the beginning of code fragments, which work with files only with the installed extension.
// For example:
//
//    If Not FileExtensionModuleEnabled("To print the document install the file extension module.") Then
//      Return;
//    EndIf; 
//    // document code printing code
//    //...
//
// Parameters
//  OfferText    - String - text offering to install the file extension module. 
//                                 If not specified, the default text is displayed.
//  WarningText - String - text warning that the operation can't be continued. 
//                                 If not specified, the default text is displayed.
//
// Returned value:
//  Boolean - True, if the extension is enabled.
//   
Function FileExtensionModuleEnabled(OfferText = Undefined, WarningText = Undefined) Export
	
	Result = GeneralFunctionsClientSL.OfferInstallingFileExtensionModule(OfferText);
	MessageText = "";
	If Result = "NotEnabled" Then
		If WarningText <> Undefined Then
			MessageText = WarningText;
		Else
			MessageText = NStr("en = 'Action is not available - the web-client file extension module is not enabled.'")
		EndIf;
	ElsIf Result = "UnsupportedWebClient" Then
		MessageText = NStr("en = 'Action is not available in the used web-client - the web-client file extension module can not be installed.'");
	EndIf;
	If Not IsBlankString(MessageText) Then
		DoMessageBox(MessageText);
	EndIf;
	Return Result = "Enabled";
	
EndFunction

// Offers a user to install the web-client file extension module.
// And initialized the AskToInstallFileExtensionModule session parameter.
//
// Designed to use in the beginning of code fragments, which work with files.
// For example:
//
//    OfferInstallingFileExtensionModule("To print the document install the file extension module.");
//    // document printing code
//    //...
//
// Parameters
//  OfferText  - String - message text. If not specified, the default text is used.
//   
// Returned value:
//  String - possible value:
//           Enabled                - extension enabled
//           NotEnabled              - user refused enabling the extension
//           UnsupportedWebClient - the extension can't be enabled, as it's not supported in the used web-client
//   
Function OfferInstallingFileExtensionModule(OfferText = Undefined) Export
	
#If WebClient Then
	ExtensionEnabled = AttachFileSystemExtension();
	If ExtensionEnabled Then
		Return "Enabled"; // if the extension is already enabled don't ask
	EndIf;
	
	If GeneralFunctionClientReusable.ThisWebClientDoesNotSupportFileExtensionModule() Then
		Return "UnsupportedWebClient";
	EndIf;
	
	FirstRequestInSession = False;
	
	If AskToInstallFileExtensionModule = Undefined Then
		
		FirstRequestInSession = True;
		AskToInstallFileExtensionModule = GeneralFunctionsSL.CommonSettingsStorageLoad("ProgramSettings", 
			"AskToInstallFileExtensionModule");
		If AskToInstallFileExtensionModule = Undefined Then
			AskToInstallFileExtensionModule = True;
			GeneralFunctionsSL.CommonSettingsStorageSave("ProgramSettings", "AskToInstallFileExtensionModule", 
				AskToInstallFileExtensionModule);
		EndIf;
		
	EndIf;
	
	If AskToInstallFileExtensionModule = False Then
		Return ?(ExtensionEnabled, "Enabled", "NotEnabled");
	EndIf;
	
	If FirstRequestInSession Then
		FormParameters = New Structure("Message", OfferText);
		ReturnCode = OpenFormModal("CommonForm.FileExtensionModuleInstallationDialogBox", FormParameters);
		If ReturnCode = Undefined Then
			ReturnCode = True;
		EndIf;
		
		AskToInstallFileExtensionModule = ReturnCode;
		GeneralFunctionsSL.CommonSettingsStorageSave("ProgramSettings", "AskToInstallFileExtensionModule", 
			AskToInstallFileExtensionModule);
	EndIf;
	Return ?(AttachFileSystemExtension(), "Enabled", "NotEnabled");
	
#Else
	Return "Enabled";
#EndIf
	
EndFunction

