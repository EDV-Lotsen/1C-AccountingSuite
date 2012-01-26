////////////////////////////////////////////////////////////////////////////////
// General client procedures

// Returns True if this web-client doesn't support the file extension module
Function ThisWebClientDoesNotSupportFileExtensionModule() Export
	
	SysInfo = New SystemInfo;
	
	If Find(SysInfo.UserAgentInformation, "Safari") <> 0 Then
		Return True;
	EndIf;
	
	If Find(SysInfo.UserAgentInformation, "Chrome") <> 0 Then
		Return True;
	EndIf;
		
	Return False;
	
EndFunction
