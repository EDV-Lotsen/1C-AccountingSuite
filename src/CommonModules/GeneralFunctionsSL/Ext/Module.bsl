
// Returns an object manager by a metadata object's full name
//
// Parameters:
//  FullName    - String, full name of a metadata object,
//                 for example, "Catalog.Companies"
//
// ReturnedValue:
//  CatalogManager, DocumentManager, ...
//
// This is an abridged version of the function. For the full version see the Subsystems Library (SL)
//
Function ObjectManagerByFullName(FullName) Export
	
	NameParts = StringFunctionsClientServer.SplitStringIntoArrayOfSubstrings(FullName, ".");
	
	ClassMO = NameParts[0];
	NameMO   = NameParts[1];
	
	If Upper(ClassMO) = "DOCUMENT" Then
		Return Documents[NameMO];		
	Else
		Raise StringFunctionsClientServer.SubstituteParametersIntoString(
			NStr("en='Unknown metadata object type (%1)'"), ClassMO);
	EndIf;
	
EndFunction

// Returns a value of a user setting by its name.
//
// Parameters:
//    corresponds to the method CommonSettingsStorage.Load
//
// This is an abridged version of the function. For the full version see the Subsystems Library (SL)
//
Function CommonSettingsStorageLoad(ObjectKey, SettingsKey = Undefined, DefaultValue = Undefined, 
		SettingsDescription = Undefined, UserName = Undefined) Export
	
	Result = Undefined;
	
	If (Result = Undefined) И (DefaultValue <> Undefined) Then
		Result = DefaultValue;
	EndIf;

	Return Result;
	
EndFunction

// Saves a user setting by its name. 
// 
// Parameters:
//    corresponds to the method CommonSettingsStorage.Save
//
// This is an abridged version of the function. For the full version see the Subsystems Library (SL)
//
Procedure CommonSettingsStorageSave(ObjectKey, SettingsKey = Undefined, Value,
	SettingsDescription = Undefined, UserName = Undefined, 
	NeedToRefreshReusableValues = False) Export
	
	Return;
	
EndProcedure



