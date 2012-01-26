
// Returns objects marked for deleteion. Selection by filter is possible.
// 
//
Function GetSelectedForDeletion(val Filter = Undefined) Export
	
	SetPrivilegedMode(True); // 360
	
	ArrayMarked = FindMarkedForDeletion();
	
	If Filter <> Undefined Then
		Result = New Array;
		For Each ItemMarked In ArrayMarked Do
			If ItemMarked.Metadata().Name = Filter Then
				Result.Add(ItemMarked);
			EndIf;
		EndDo;
	Else
		Result = ArrayMarked;
	EndIf;
	
	Return Result;
	
EndFunction

// Deletion of marked for deletion objects function
// Parameters:
// ToBeDeleted - ValueTable - array of marked for deletion objects and elements in the infobase
// CheckRefIntegrity - requires a check of referential integrity
//                                 if True objects that are referenced in the infobase
//                                 won't be deleted and will be returned as the function's result
//
// Returned value
// value table characterizing references to the deleted objects
//
Function DeleteMarkedObjects(val ToBeDeleted,
                                  val CheckRefIntegrity = True) Export
	
	SetPrivilegedMode(True); // 360							  
								  
	ExclusiveAccess = False;
	
	If CheckRefIntegrity Then
		Try
			If NOT ExclusiveMode() Then 
				SetExclusiveMode(True);
			EndIf;
			ExclusiveAccess = ExclusiveMode();
		Except
			Return OperationStatus(NStr("en = 'Cannot gain exclusive access'"), False);
		EndTry;
	EndIf;
	
	Try
		Found = New ValueTable;
		DeleteObjects(ToBeDeleted, CheckRefIntegrity, Found);
	Except
		ErrorInfo = ErrorInfo();
		
		If CheckRefIntegrity AND ExclusiveAccess Then
			SetExclusiveMode(False);
		EndIf;
		
		If ErrorInfo.Cause = Undefined Then
			ErrorMessage = ErrorInfo.Description;
		Else
			ErrorMessage = ErrorInfo.Cause.Description;
		EndIf;
		
		Raise ErrorMessage;
	EndTry;
	
	If CheckRefIntegrity AND ExclusiveAccess Then
		SetExclusiveMode(False);
	EndIf;
	
	Return OperationStatus(Found);
	
EndFunction

// Returns a structure with the Status and Value fields for the passed parameters
//
Function OperationStatus(val Value, val Status = True)
	
	Return New Structure("Status, Value", Status, Value);
	
EndFunction
