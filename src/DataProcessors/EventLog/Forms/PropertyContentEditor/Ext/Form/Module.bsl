

/////////////////////////////////////////////////////////////////////////////////////////
// Export procedures

&AtClient
Procedure SetEditorParameters(EditableList, FilteredParameters)
	StructureOfFilterParameters = GetEventLogFilterValuesByColumn(FilteredParameters);
	FilterValues = StructureOfFilterParameters[FilteredParameters];
	
	If TypeOf(FilterValues) = Type("Array") Then
		ListItems = List.GetItems();
		For Each ArrayItem In FilterValues Do
			NewItem = ListItems.Add();
			NewItem.Check = False;
			NewItem.Value = ArrayItem;
			NewItem.Presentation = ArrayItem;
		EndDo;
	ElsIf TypeOf(FilterValues) = Type("Map") Then
		If FilteredParameters = "Event" Or FilteredParameters = "Event" Or
			 FilteredParameters = "Metadata" Or FilteredParameters = "Metadata" Then 
			// Load as tree
			For Each MapItem In FilterValues Do
				NewItem = GetTreeBranch(MapItem.Value);
				NewItem.Check = False;
				NewItem.Value = MapItem.Key;
			EndDo;
		Else 
			// Load as flat list
			ListItems = List.GetItems();
			For Each MapItem In FilterValues Do
				NewItem = ListItems.Add();
				NewItem.Check = False;
				NewItem.Value = MapItem.Key;
				If (FilteredParameters = "User" Or FilteredParameters = "User") Then
					// For users - key is the name
					NewItem.Value = MapItem.Value;
					NewItem.Presentation = MapItem.Value;
					If NewItem.Value = "" Then
						// Case for default user
						NewItem.Value = "";
						NewItem.Presentation = Users.FullNameOfNotSpecifiedUser();
					EndIf;
				Else
					NewItem.Presentation = MapItem.Value;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	
	// Mark tree tems, if they have matching items in EditableList
	CheckFoundItems(List.GetItems(), EditableList);
	
	// check if list contains subordinate items. If thare is no items
	// - set control to List mode
	ThisIsTree = False;
	For Each TreeItem In List.GetItems() Do
		If TreeItem.GetItems().Count() > 0 Then 
			ThisIsTree = True;
			Break;
		EndIf;
	EndDo;
	If Not ThisIsTree Then
		Items.List.Representation = TableRepresentation.List;
	EndIf;
EndProcedure

&AtClient
Function GetEditedList()
	
	EditableList = New ValueList;
	
	EditableList.Clear();
	AreUnchecked = False;
	GetSubtreeList(EditableList, List.GetItems(), AreUnchecked);
	
	Return EditableList;
	
EndFunction

/////////////////////////////////////////////////////////////////////////////////////////
// Auxiliary procedures
&AtClient
Function GetTreeBranch(Presentation)
	PathRows = SortStringByPoints(Presentation);
	If PathRows.Count() = 1 Then
		TreeItems = List.GetItems();
		BranchName = PathRows[0];
	Else
		// Make path to parent branch from parts of path
		ParentPathPresentation = "";
		For Acc = 0 To PathRows.Count() - 2 Do
			If Not IsBlankString(ParentPathPresentation) Then
				ParentPathPresentation = ParentPathPresentation + ".";
			EndIf;
			ParentPathPresentation = ParentPathPresentation + PathRows[Acc];
		EndDo;
		TreeItems = GetTreeBranch(ParentPathPresentation).GetItems();
		BranchName = PathRows[PathRows.Count() - 1];
	EndIf;
	
	For Each TreeItem In TreeItems Do
		If TreeItem.Presentation = BranchName Then
			Return TreeItem;
		EndIf;
	EndDo;
	// Not found, need to create
	TreeItem = TreeItems.Add();
	TreeItem.Presentation = BranchName;
	TreeItem.Check = False;
	Return TreeItem;
EndFunction

// Function splits string into array of strings, using point as separator
&AtClient
Function SortStringByPoints(Val Presentation)
	Particles = New Array;
	While True Do
		Presentation = TrimAll(Presentation);
		PointPosition = Find(Presentation, ".");
		If PointPosition > 0 Then
			Particle = TrimAll(Left(Presentation, PointPosition - 1));
			Particles.Add(Particle);
			Presentation = Mid(Presentation, PointPosition + 1);
		Else
			Particles.Add(TrimAll(Presentation));
			Break;
		EndIf;
	EndDo;
	Return Particles;
EndFunction

&AtServer
Function GetEventLogFilterValuesByColumn(FilteredParameters)
	Return GetEventLogFilterValues(FilteredParameters);
EndFunction

&AtClient
Procedure GetSubtreeList(EditableList, TreeItems, AreUnchecked)
	For Each TreeItem In TreeItems Do
		If TreeItem.GetItems().Count() <> 0 Then
			GetSubtreeList(EditableList, TreeItem.GetItems(), AreUnchecked);
		Else
			If TreeItem.Check Then
				NewListItem = EditableList.Add();
				NewListItem.Value      = TreeItem.Value;
				NewListItem.Presentation = AssemblePresentation(TreeItem);
			Else
				AreUnchecked = True;
			EndIf;
		EndIf;
	EndDo;
EndProcedure

&AtClient
Procedure CheckFoundItems(TreeItems, EditableList)
	For Each TreeItem In TreeItems Do
		If TreeItem.GetItems().Count() <> 0 Then 
			CheckFoundItems(TreeItem.GetItems(), EditableList);
		Else
			AssembledPresentation = AssemblePresentation(TreeItem);
			For Each ItemOfList In EditableList Do
				If AssembledPresentation = ItemOfList.Presentation Then
					CheckTreeItem(TreeItem, True);
					Break;
				EndIf;
			EndDo;
		EndIf;
	EndDo;
EndProcedure

&AtClient
Procedure CheckTreeItem(TreeItem, Check, CheckParentState = True)
	TreeItem.Check = Check;
	// Mark all subordinate tree items
	For Each SubordinateTreeItem In TreeItem.GetItems() Do
		CheckTreeItem(SubordinateTreeItem, Check, False);
	EndDo;
	// Validate, if parent status should change
	If CheckParentState Then
		CheckBranchCheckState(TreeItem.GetParent());
	EndIf;
EndProcedure

&AtClient
Procedure CheckBranchCheckState(Branch)
	If Branch = Undefined Then 
		Return;
	EndIf;
	SubordinateBranches = Branch.GetItems();
	If SubordinateBranches.Count() = 0 Then
		Return;
	EndIf;
	
	IsTrue = False;
	IsFalse = False;
	For Each SubordinateBranch In SubordinateBranches Do
		If SubordinateBranch.Check Then
			IsTrue = True;
			If IsFalse Then
				Break;
			EndIf;
		Else
			IsFalse = True;
			If IsTrue Then
				Break;
			EndIf;
		EndIf;
	EndDo;
	
	If IsTrue Then
		If IsFalse Then
			// there are both marked and not marked, for us assign notmarked and mark the parent
			If Branch.Check Then
				Branch.Check = False;
				CheckBranchCheckState(Branch.GetParent());
			EndIf;
		Else
			// All subordinate are marked
			If Not Branch.Check Then
				Branch.Check = True;
				CheckBranchCheckState(Branch.GetParent());
			EndIf;
		EndIf;
	Else
		// all subordinate are not marked
		If Branch.Check Then
			Branch.Check = False;
			CheckBranchCheckState(Branch.GetParent());
		EndIf;
	EndIf;
EndProcedure

&AtClient
Function AssemblePresentation(TreeItem)
	If TreeItem = Undefined Then 
		Return "";
	EndIf;
	If TreeItem.GetParent() = Undefined Then
		Return TreeItem.Presentation;
	EndIf;
	Return AssemblePresentation(TreeItem.GetParent()) + "." + TreeItem.Presentation;
EndFunction

&AtClient
Procedure SetupOfMarks(Value)
	For Each TreeItem In List.GetItems() Do
		CheckTreeItem(TreeItem, Value, False);
	EndDo;
EndProcedure

/////////////////////////////////////////////////////////////////////////////////////////
// EVENT HANDLERS
&AtClient
Procedure CheckAllFlags()
	SetupOfMarks(True);
EndProcedure

&AtClient
Procedure UnmarkAll()
	SetupOfMarks(False);
EndProcedure

&AtClient
Procedure CheckOnChange(Item)
	CheckTreeItem(Items.List.CurrentData, Items.List.CurrentData.Check);
EndProcedure

&AtClient
Procedure ChooseFilterContent(Command)
	
	Notify("EventLogFilterElementsValuesChoice",
	           GetEditedList(),
	           FormOwner);
	Close();
	
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancellation, StandardProcessing)
	
	EditableList = Parameters.EditableList;
	FilteredParameters = Parameters.FilteredParameters;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancellation)
	
	SetEditorParameters(EditableList, FilteredParameters);
	
EndProcedure
