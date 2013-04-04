

// Returns objects marked for deletion. Filter by filter is possible.
//
Function GetMarkedForDeletion() Export
	
	ArrayMarked = FindMarkedForDeletion();
	
	Result = New Array;
	For Each ItemMarked In ArrayMarked Do
		If AccessRight("InteractiveDeleteMarked", ItemMarked.Metadata()) Then
			Result.Add(ItemMarked);
		EndIf
	EndDo;
	
	Return Result;
	
EndFunction

// Function deletes objects marked for deletion
// Parameters:
// ToBeDeleted 				 - Array - references for objects to be deleted
// CheckReferentialIntegrity - need to check referential integrity
//									if True, then objects for which there exist refs in IB
//									will not be deleted, but will be returned as function result
//
// Value to return:
//   value table, describing references to objects being deleted
//
Function DeleteMarkedObjects1(Val ToBeDeleted, TypesOfDeletedObjectsArray) Export
	
	ExclusiveAccess = False;
	
	Try
		If Not ExclusiveMode() Then
			SetExclusiveMode(True);
		EndIf;
		ExclusiveAccess = ExclusiveMode();
	Except
		Return FillOperationStatus(NStr("en = 'Failed to set the exclusive mode'"), False);
	EndTry;
	
	TypesOfDeletedObjects = GetTableOfTypesOfDeletedObjects();
	RefreshTableOfTypesOfObjectsToBeDeleted(TypesOfDeletedObjects, ToBeDeleted);
	
	Founds = New ValueTable;
	NotDeleted = New Array;
	
	Try
		DeleteObjects(ToBeDeleted, True, Founds);
	// Records of infobase objects could get to table Found,
	// which are are linked with IB objects, links with whom must be filtered
	Except
		ErrorMessage = DetailErrorDescription(ErrorInfo());
		SetExclusiveMode(False);
		Return FillOperationStatus(ErrorMessage, False);
	EndTry;
	
	ToBeDeleted = New Array;
	RefsSearchExceptions = CommonUseOverrided.GetRefSearchExclusions();
	GroupedByRef = Founds.Copy(, "Ref");
	GroupedByRef.GroupBy("Ref");
	GroupedByRef = GroupedByRef.UnloadColumn("Ref");
	For Each ItemsByRef In GroupedByRef Do
		LinksByRef = Founds.FindRows(New Structure("Ref", ItemsByRef.Ref));
		For Each ItemLink In LinksByRef Do
			If RefsSearchExceptions.Find(ItemLink.Metadata.FullName()) <> Undefined Then
				Founds.Delete(ItemLink);
			EndIf;
		EndDo;
		If Founds.FindRows(New Structure("Ref", ItemsByRef.Ref)).Count() = 0 Then
			// Object had just filtered links - delete it
			ToBeDeleted.Add(ItemsByRef.Ref);
		Else
			NotDeleted.Add(ItemsByRef.Ref);
		EndIf;
	EndDo;
	
	Try
		// deletion without referential integrity control (checked manually)
		DeleteObjects(ToBeDeleted, False);
	Except
		ErrorMessage = DetailErrorDescription(ErrorInfo());
		SetExclusiveMode(False);
		Return FillOperationStatus(ErrorMessage, False);
	EndTry;
	
	For Each NotDeletedObject In NotDeleted Do
		RowsFound = TypesOfDeletedObjects.FindRows(New Structure("Type", TypeOf(NotDeletedObject)));
		If RowsFound.Count() > 0 Then
			TypesOfDeletedObjects.Delete(RowsFound[0]);
		EndIf;
	EndDo;
	
	TypesOfDeletedObjectsArray = TypesOfDeletedObjects.UnloadColumn("Type");
	
	If ExclusiveAccess Then
		SetExclusiveMode(False);
	EndIf;
	
	Return FillOperationStatus(Founds);
	
EndFunction

Function GetTableOfTypesOfDeletedObjects()
	
	ObjectTypesToBeDeleted = New ValueTable;
	ObjectTypesToBeDeleted.Columns.Add("Type", New TypeDescription("Type"));
	
	Return ObjectTypesToBeDeleted;
	
EndFunction

Procedure RefreshTableOfTypesOfObjectsToBeDeleted(Table, Val ObjectsToBeDeleted)
	
	For Each ObjectToBeDeleted In ObjectsToBeDeleted Do
		NewType = Table.Add();
		NewType.Type = TypeOf(ObjectToBeDeleted);
	EndDo;
	
	Table.GroupBy("Type");
	
EndProcedure

// Returns structure with fields Status and Value using passed parameters
//
Function FillOperationStatus(Val Value, Val Status = True)
	
	Return New Structure("Status, Value", Status, Value);
	
EndFunction
