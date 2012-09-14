///////////////////////////////////////////////////////////////
// Event handlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	DeleteMode = "Full";
EndProcedure

&AtClient
Procedure DeleteModeOnChange(Item)
	ButtonAvailability();
EndProcedure

&AtClient
// Calls a recursive function that sets dependency flag marks on parent and child items
//
Procedure MarkOnChange(Item)
		
	CurrentData = Items.SelectedForDeletionList.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	SetMarkInList(CurrentData, CurrentData.Mark, True);
	
EndProcedure

&AtClient
// Selects all found objects
//
Procedure CommandSelectAll()
		
	ListItems = SelectedForDeletionList.GetItems();
	For Each Item In ListItems Do
		SetMarkInList(Item, True, True);
	EndDo;
	
EndProcedure

&AtClient
// Unselects all found objects
//
Procedure CommandUnselectAll()
		
	ListItems = SelectedForDeletionList.GetItems();
	For Each Item In ListItems Do
		SetMarkInList(Item, False, True);
	EndDo;
EndProcedure

&AtClient
// Trying to open the selected value
//
Procedure NonDeletedObjectsTreeChoice(Item, SelectedRow, Field, StandardProcessing)
		
	CurrentData = Items.NonDeletedObjectsTree.CurrentData;
	If CurrentData = Undefined Then 
		Return;
	EndIf;;
	
	If CurrentData.GetItems().Count() = 0 Then
		// displays the object that prevented deletion of the marked and selected object
		StandardProcessing = False;
		OpenValue(CurrentData.Value);
	EndIf;
	
EndProcedure


&AtClient
// Trying to open the selected value
//
Procedure SelectedForDeletionListChoice(Item, SelectedRow, Field, StandardProcessing)
		
	CurrentData = Items.SelectedForDeletionList.CurrentData;
	If CurrentData = Undefined Then 
		Return;
	EndIf;
	
	If CurrentData.GetItems().Count() = 0 Then
		StandardProcessing = False;
		OpenValue(CurrentData.Value);
	EndIf;
	
EndProcedure

&AtClient
Procedure GoNext()
		
	CurrentPage = Items.FormPages.CurrentPage;
	
	If CurrentPage = Items.DeleteModeChoice Then
		Status(NStr("en = 'Searching for marked for deletion objects'"));
		
		FillingMarkedForSelectionTree();
		If LevelsSelectedForDeletionCount = 1 Then 
			For Each Item In SelectedForDeletionList.GetItems() Do
				ID = Item.GetID();
				Items.SelectedForDeletionList.Expand(ID, False);
			EndDo;
		EndIf;
		
		Items.FormPages.CurrentPage = Items.SelectedForDeletion;
		ButtonAvailability();
	EndIf;
	
EndProcedure

&AtClient
Procedure GoBack()
		
	CurrentPage = Items.FormPages.CurrentPage;
	If CurrentPage = Items.SelectedForDeletion Then
		Items.FormPages.CurrentPage = Items.DeleteModeChoice;
		ButtonAvailability();
	ElsIf CurrentPage = Items.NonDeletionReasons Then
		If DeleteMode = "Full" Then
			Items.FormPages.CurrentPage = Items.DeleteModeChoice;
		Else
			Items.FormPages.CurrentPage = Items.SelectedForDeletion;
		EndIf;
		ButtonAvailability();
	EndIf;
	
EndProcedure

&AtClient
Procedure CommandDelete()
		
	If DeleteMode = "Full" Then
		Status(NStr("en = 'Searching and deleting marked objects'"));
	Else
		Status(NStr("en = 'Deleting selected objects'"));
	EndIf;
	
	ErrorMessage = "";
	If NOT DeleteSelectedAtServer(ErrorMessage) Then
		Status(ErrorMessage);
		Return;
	EndIf;
	
	RefreshTree = True;
	If UndeletedObjectsCount = 0 Then
		If DeletedObjectsCount = 0 Then
			Text = NStr("en = 'No selected objects. None deleted'");
			RefreshTree = False;
		Else
			Text = StringFunctionsClientServer.SubstituteParametersIntoString(
			             NStr("en = 'Objects have been successfully deleted!
			                        |Objects deleted: %1.'"),
			             DeletedObjectsCount);
		EndIf;
		DoMessageBox(Text);
	Else
		Items.FormPages.CurrentPage = Items.NonDeletionReasons;
		For Each Item In NonDeletedObjectsTree.GetItems() Do
			ID = Item.GetID();
			Items.NonDeletedObjectsTree.Expand(ID, False);
		EndDo;
		ButtonAvailability();
		DoMessageBox(ResultsLine);
	EndIf;
	
	If RefreshTree Then
		FillingMarkedForSelectionTree();
		
		If LevelsSelectedForDeletionCount = 1 Then
			For Each Item In SelectedForDeletionList.GetItems() Do
				ID = Item.GetID();
				Items.SelectedForDeletionList.Expand(ID, False);
			EndDo;
		EndIf;
	EndIf;
	
EndProcedure

/////////////////////////////////////////////////////////////////////////
// Additional procedures

&AtClient
// Changes availability of buttons on the form depensing on the current page and
// form attributes
//
Procedure ButtonAvailability()
	CurrentPage = Items.FormPages.CurrentPage;
	If CurrentPage = Items.DeleteModeChoice Then
		Items.CommandBack.Enabled = False;
		If DeleteMode = "Full" Then
			Items.CommandNext.Enabled = False;
			Items.CommandDelete.Enabled = True;
		ElsIf DeleteMode = "Selective" Then
			Items.CommandNext.Enabled = True;
			Items.CommandDelete.Enabled = False;
		EndIf;
	ElsIf CurrentPage = Items.SelectedForDeletion Then
		Items.CommandBack.Enabled = True;
		Items.CommandNext.Enabled = False;
		Items.CommandDelete.Enabled = True;
	ElsIf CurrentPage = Items.NonDeletionReasons Then
		Items.CommandBack.Enabled = True;
		Items.CommandNext.Enabled = False;
		Items.CommandDelete.Enabled = False;
	EndIf;
EndProcedure

&AtServer
// Returns a tree branch in the TreeBranches branch by the value of Value
// If the branch is not found - creates a new one
//
Function FindOrAddTreeBranch(TreeBranches, Value, Presentation, Mark)
	
	SetPrivilegedMode(True); // 360
	
	// Trying to find the existing branch in TreeBranches without nested
	Branch = TreeBranches.Find(Value, "Value", False);
	If Branch = Undefined Then
		// The branch doesn't exist - create a new one
		Branch = TreeBranches.Add();
		Branch.Value      = Value;
		Branch.Presentation = Presentation;
		Branch.Mark       = Mark;
	EndIf;

	Return Branch;
EndFunction

&AtServer
Function FindOrAddTreeBranchWPicture(TreeBranches, Value, Presentation, ImageNumber)
	
	SetPrivilegedMode(True); // 360
	
	// Trying to find an existing branch in TreeBranches without nested
	Branch = TreeBranches.Find(Value, "Value", False);
	If Branch = Undefined Then
		// Branch doesn't exist - create new one
		Branch = TreeBranches.Add();
		Branch.Value      = Value;
		Branch.Presentation = Presentation;
		Branch.ImageNumber = ImageNumber;
	EndIf;

	Return Branch;
EndFunction

&AtServer
// Fills in the tree of objects marked for deletion
//
Procedure FillingMarkedForSelectionTree()
	
	SetPrivilegedMode(True); // 360
	
	// Fills in the tree of objects marked for deletion
	TreeOfSelected = FormAttributeToValue("SelectedForDeletionList");
	TreeOfSelected.Rows.Clear();
	// Processing marked
	ArrayOfSelected = DataProcessors.DeleteMarkedObjects.GetSelectedForDeletion();
	For Each ArrayOfSelectedItem In ArrayOfSelected Do
		MetadataObjectValue = ArrayOfSelectedItem.Metadata().FullName();
		MetadataObjectPresentation = ArrayOfSelectedItem.Metadata().Presentation();
		MetadataObjectRow = FindOrAddTreeBranch(TreeOfSelected.Rows, MetadataObjectValue, MetadataObjectPresentation, True);
		FindOrAddTreeBranch(MetadataObjectRow.Rows, ArrayOfSelectedItem, String(ArrayOfSelectedItem) + " - " + MetadataObjectPresentation, True);
	EndDo;
	TreeOfSelected.Rows.Sort("Value", True);
	For Each MetadataObjectRow In TreeOfSelected.Rows Do
		// Create a presentation for rows displaying a branch of the metadata object
		MetadataObjectRow.Presentation = MetadataObjectRow.Presentation + " (" + MetadataObjectRow.Rows.Count() + ")";
	EndDo;
	LevelsSelectedForDeletionCount = TreeOfSelected.Rows.Count();
	
	ValueToFormAttribute(TreeOfSelected, "SelectedForDeletionList");
	
EndProcedure

&AtClient
// Recursive function that removes / sets marks for dependent parent and child items
//
Procedure SetMarkInList(Data, Mark, CheckParent)
		
	Data.Mark = Mark;
	
	// Set for dependent
	ItemRows = Data.GetItems();
	For Each Item In ItemRows Do
		SetMarkInList(Item, Mark, False);
	EndDo;
	// Check parent
	Parent = Data.GetParent();
	If CheckParent AND Parent <> Undefined Then
		ParentMark = True;
		ItemRows = Parent.GetItems();
		For Each Item In ItemRows Do
			If NOT Item.Mark Then
				ParentMark = False;
				Break;
			EndIf;
		EndDo;
		If ParentMark <> Parent.Mark Then
			Parent.Mark = ParentMark;
		EndIf;
	EndIf;
EndProcedure

&AtServer
// Trying to delete the selected objects
// Objects that can't be deleted are shown in a separate table
//
Function DeleteSelectedAtServer(ErrorMessage)
	
	SetPrivilegedMode(True); // 360
	
	ToBeDeleted = New Array;
	If DeleteMode = "Full" Then
		// On full deleteion get all marked for deletion
		ToBeDeleted = DataProcessors.DeleteMarkedObjects.GetSelectedForDeletion();
	Else                                               
		// Fill in an array with references to selected marked for deletion items
		MetadataRowsCollection = SelectedForDeletionList.GetItems();
		For Each MetadataObjectRow In MetadataRowsCollection Do
			RefRowsCollection = MetadataObjectRow.GetItems();
			For Each RefRow In RefRowsCollection Do
				If RefRow.Mark Then
					ToBeDeleted.Add(RefRow.Value);
				EndIf;
			EndDo;
		EndDo;
	EndIf;
	
	// Perform deletion
	Result = DataProcessors.DeleteMarkedObjects.DeleteMarkedObjects(ToBeDeleted);
	IF NOT Result.Status Then
		ErrorMessage = Result.Value;
		Return False;
	Else
		Found = Result.Value;
	EndIf;
	// Create a table of non-deleted objects
	NonDeletedObjectsTree.GetItems().Clear();
	Tree = FormAttributeToValue("NonDeletedObjectsTree");
	For Each F In Found Do
		NonDeleted = F[0];
		Referencing = F[1];
		MetadataObjectReferencing = F[2].Presentation();
		MetadataObjectNondeletedValue = NonDeleted.Metadata().FullName();
		MetadataObjectNondeletedPresentation = NonDeleted.Metadata().Presentation();
		// Metadata branch
		MetadataObjectRow = FindOrAddTreeBranchWPicture(Tree.Rows, MetadataObjectNondeletedValue, MetadataObjectNondeletedPresentation, 0);
		// Branch of a non-deleted object
		NondeletedRefRow = FindOrAddTreeBranchWPicture(MetadataObjectRow.Rows, NonDeleted, String(NonDeleted), 2);
		// Branch of a reference to the non-deleted object
		FindOrAddTreeBranchWPicture(NondeletedRefRow.Rows, Referencing, String(Referencing) + " - " + MetadataObjectReferencing, 1);
	EndDo;
	Tree.Rows.Sort("Value", True);
	ValueToFormAttribute(Tree, "NonDeletedObjectsTree");
	
	// Checking completion of the deletion procedure
	// Count the number of non-deleted, for this count in the select level tree branch where they are present
	UndeletedObjectsCount = 0;
	For Each MetadataObjectRow In Tree.Rows Do
		UndeletedObjectsCount = UndeletedObjectsCount + MetadataObjectRow.Rows.Count();
	EndDo;
	
	DeletedObjectsCount   = ToBeDeleted.Количество() - UndeletedObjectsCount;
	If DeletedObjectsCount = 0 Then
		ResultsLine = NStr("en = 'None deleted, because there are references to the objects in the infobase'");
	Else
		ResultsLine =
		    StringFunctionsClientServer.SubstituteParametersIntoString(
		        NStr("en = 'Marked objects successfully deleted!
		                   |Objects deleted: %1.'"),
		        String(DeletedObjectsCount));
	EndIf;
	If UndeletedObjectsCount > 0 Then
		ResultsLine = ResultsLine + Chars.LF +
		    StringFunctionsClientServer.SubstituteParametersIntoString(
		        NStr("en = 'Objects not deleted: %1.
		                   |Objects are not deleted to maintain infobase integrity, because there are references to the objects.
		                   |Press ОК to view the list of objects that haven't been deleted.'"),
		        String(UndeletedObjectsCount));
	EndIf;
	
	Return True;
	
EndFunction