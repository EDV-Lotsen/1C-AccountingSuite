

// Function GetRefSearchExclusions returns list of metadata object names,
// which can refer to different metadata objects not affecting application business logics,
//  For example, tha fact that there are refs from information register "Object versions" to the items of catalog "Item"
// does not limit deletion of the items of catalog "Item".
//
// Value returned:
//  Array       - array of strings, for example, "InformationRegister.ObjectVersions".
//
Function GetRefSearchExclusions() Export
	
	Array = New Array;
	
	Return Array;
	
EndFunction // GetRefSearchExclusions()
