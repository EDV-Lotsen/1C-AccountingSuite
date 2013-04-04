
///////////////////////////////////////////////////////////////
// Event handlers

// Handler of event "on create at server"
//
&AtServer
Procedure OnCreateAtServer(Cancellation, StandardProcessing)
	DeletionMode = "Full";
EndProcedure

// Handler of event "OnChange" of form item DeletionMode
//
&AtClient
Procedure DeletionModeOnChange(Item)
	ButtonsAccessibility();
EndProcedure

// Handler of event "OnChange" of field "Check"
// Calls recursive function, which sets dependable mark flags
// in parent and child items
//
&AtClient
Procedure CheckOnChange(Item)
	
	CurrentData = Items.ListMarkedForDeletion.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	SetMarkInList(CurrentData, CurrentData.Check, True);
	
EndProcedure

// Handler of click on button "Set all" of list command bar
// of tree ListMarkedForDeletion.
// Set mark to every object found
//
&AtClient
Procedure CommandListOfMarkedCheckAll()
	ListItems = ListMarkedForDeletion.GetItems();
	For Each Item In ListItems Do
		SetMarkInList(Item, True, True);
		Parent = Item.GetParent();
		If Parent = Undefined Then
			CheckParent(Item)
		EndIf;
	EndDo;
EndProcedure

// Handler of click on button "Remove all" of list command bar
// of tree ListMarkedForDeletion.
// Removes mark for every object found
//
&AtClient
Procedure CommandListOfMarkedLiftAll()
	ListItems = ListMarkedForDeletion.GetItems();
	For Each Item In ListItems Do
		SetMarkInList(Item, False, True);
		Parent = Item.GetParent();
		If Parent = Undefined Then
			CheckParent(Item)
		EndIf;	
	EndDo;
EndProcedure

// Handler of event "Selection" of tree row NotDeletedObjectsTree
// Tries to open selected value
//
&AtClient
Procedure NotDeletedObjectsTreeSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData = Items.NotDeletedObjectsTree.CurrentData;
	
	If CurrentData = Undefined OR TypeOf(CurrentData.Value) = Type("String") Then
		Return;
	EndIf;
	
	// This row represents object, that prevented deletion of marked and selected item
	StandardProcessing = False;
	OpenValue(CurrentData.Value);
	
EndProcedure

// Handler of event "Selection" of tree row ListMarkedForDeletion
// Tries to open selected value
//
&AtClient
Procedure ListMarkedForDeletionSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData = Items.ListMarkedForDeletion.CurrentData;
	If CurrentData = Undefined Then 
		Return;
	EndIf;
	
	If CurrentData.GetItems().Count() = 0 Then
		StandardProcessing = False;
		OpenValue(CurrentData.Value);
	EndIf;
	
EndProcedure

// Handler of click on button "Next" of form command bar
//
&AtClient
Procedure RunNext()
	
	CurrentPage = Items.FormPages.CurrentPage;
	
	If CurrentPage = Items.DeleteModeChoice Then
		Status(NStr("en = 'Searches for objects marked for deletion '"));
		
		FillingMarkedForDeletionTree();
		
		If LevelNumberMarkedForDeletion = 1 Then
			For Each Item In ListMarkedForDeletion.GetItems() Do
				Id = Item.GetID();
				Items.ListMarkedForDeletion.Expand(Id, False);
			EndDo;
		EndIf;
		
		Items.FormPages.CurrentPage = Items.MarkedForDeletion;
		ButtonsAccessibility();
	EndIf;
	
EndProcedure

// Handler of click on button "Back" of form command bar
//
&AtClient
Procedure RunBack()
	
	CurrentPage = Items.FormPages.CurrentPage;
	If CurrentPage = Items.MarkedForDeletion Then
		Items.FormPages.CurrentPage = Items.DeleteModeChoice;
		ButtonsAccessibility();
	ElsIf CurrentPage = Items.NondeletionReasons Then
		If DeletionMode = "Full" Then
			Items.FormPages.CurrentPage = Items.DeleteModeChoice;
		Else
			Items.FormPages.CurrentPage = Items.MarkedForDeletion;
		EndIf;
		ButtonsAccessibility();
	EndIf;
	
EndProcedure

// Handler of click on button "Delete" of form command bar
//
&AtClient
Procedure RunDelete()
	
	Var TypesOfDeletedObjects;
	
	If DeletionMode = "Full" Then
		Status(NStr("en = 'Searching and deleting marked objects'"));
	Else
		Status(NStr("en = 'Deleting selected files'"));
	EndIf;
	
	MessageAboutError = "";
	If DeleteSelectedAtServer(MessageAboutError, TypesOfDeletedObjects) Then
		For Each TypeOfDeletedObject In TypesOfDeletedObjects Do
			NotifyChanged(TypeOfDeletedObject);
		EndDo;
	Else
		DoMessageBox(MessageAboutError);
		Return;
	EndIf;
	
	RefreshTreeOfMarked = True;
	If NumberOfNotDeletedObjects = 0 Then
		If DeletedObjects = 0 Then
			Text = NStr("en = 'No objects has been marked for deletion. Object deletion was not performed'");
			RefreshTreeOfMarked = False;
		Else
			Text = StringFunctionsClientServer.SubstitureParametersInString(
			             NStr("en = 'Delete marked objects successfully completed!"
							  "Objects deleted: %1.'"),
			             DeletedObjects);
		EndIf;
		DoMessageBox(Text);
	Else
		Items.FormPages.CurrentPage = Items.NondeletionReasons;
		For Each Item In NotDeletedObjectsTree.GetItems() Do
			Id = Item.GetID();
			Items.NotDeletedObjectsTree.Expand(Id, False);
		EndDo;
		ButtonsAccessibility();
		DoMessageBox(StringOfResults);
	EndIf;
	
	If RefreshTreeOfMarked Then
		FillingMarkedForDeletionTree();
		
		If LevelNumberMarkedForDeletion = 1 Then 
			For Each Item In ListMarkedForDeletion.GetItems() Do
				Id = Item.GetID();
				Items.ListMarkedForDeletion.Expand(Id, False);
			EndDo;
		EndIf;
	EndIf;
	
EndProcedure

/////////////////////////////////////////////////////////////////////////
// Auxiliary procedures

// Changes accessibility of form buttons depending on
// current page and status of form attributes
//
&AtClient
Procedure ButtonsAccessibility()
	
	CurrentPage = Items.FormPages.CurrentPage;
	
	If CurrentPage = Items.DeleteModeChoice Then
		Items.CommandBack.Enabled   = False;
		If DeletionMode = "Full" Then
			Items.CommandNext.Enabled   = False;
			Items.CommandDelete.Enabled = True;
		ElsIf DeletionMode = "Selective" Then
			Items.CommandNext.Enabled 	= True;
			Items.CommandDelete.Enabled = False;
		EndIf;
	ElsIf CurrentPage = Items.MarkedForDeletion Then
		Items.CommandBack.Enabled   = True;
		Items.CommandNext.Enabled   = False;
		Items.CommandDelete.Enabled = True;
	ElsIf CurrentPage = Items.NondeletionReasons Then
		Items.CommandBack.Enabled   = True;
		Items.CommandNext.Enabled   = False;
		Items.CommandDelete.Enabled = False;
	EndIf;
	
EndProcedure

// Returns tree branch in branch TreeRows by value Value
// If branch is not found - new one is created
//
&AtServer
Function FindOrAddTreeBranch(TreeRows, Value, Presentation, Check)
	
	// Attempt to find existing branch in TreeRows without nested items
	Branch = TreeRows.Find(Value, "Value", False);
	
	If Branch = Undefined Then
		// No such branch, create new one
		Branch 				= TreeRows.Add();
		Branch.Value      	= Value;
		Branch.Presentation = Presentation;
		Branch.Check       	= Check;
	EndIf;
	
	Return Branch;
	
EndFunction

&AtServer
Function FindOrAddTreeBranchWithPicture(TreeRows, Value, Presentation, PictureNo)
	// Attempt to find existing branch in TreeRows without nested items
	Branch = TreeRows.Find(Value, "Value", False);
	If Branch = Undefined Then
		// No such branch, create new one
		Branch = TreeRows.Add();
		Branch.Value      	= Value;
		Branch.Presentation = Presentation;
		Branch.PictureNo 	= PictureNo;
	EndIf;

	Return Branch;
EndFunction

// Fills tree of objects marked for deletion
//
&AtServer
Procedure FillingMarkedForDeletionTree()
	
	// Filling tree of objects marked for deletion
	TreeOfMarked = FormAttributeToValue("ListMarkedForDeletion");
	
	TreeOfMarked.Rows.Clear();
	
	// process marked objects
	ArrayOfMarked = DataProcessors.DeleteMarkedObjects.GetMarkedForDeletion();
	
	For Each ArrayOfMarkedItem In ArrayOfMarked Do
		MetadataObjectValue = ArrayOfMarkedItem.Metadata().FullName();
		MetadataObjectPresentation = ArrayOfMarkedItem.Metadata().Presentation();
		MetadataObjectRow = FindOrAddTreeBranch(TreeOfMarked.Rows, MetadataObjectValue, MetadataObjectPresentation, True);
		FindOrAddTreeBranch(MetadataObjectRow.Rows, ArrayOfMarkedItem, String(ArrayOfMarkedItem) + " - " + MetadataObjectPresentation, True);
	EndDo;
	
	TreeOfMarked.Rows.Sort("Value", True);
	
	For Each MetadataObjectRow In TreeOfMarked.Rows Do
		// create presentation for rows, representing branch of metadata object
		MetadataObjectRow.Presentation = MetadataObjectRow.Presentation + " (" + MetadataObjectRow.Rows.Count() + ")";
	EndDo;
	
	LevelNumberMarkedForDeletion = TreeOfMarked.Rows.Count();
	
	ValueToFormAttribute(TreeOfMarked, "ListMarkedForDeletion");
	
EndProcedure

// Recursive function, which sets / removes marks
// for depending parent and child items
//
&AtClient
Procedure SetMarkInList(Data, Check, VerifyParent)
	
	// Set for child items
	RowItems = Data.GetItems();
	
	For Each Item In RowItems Do
		Item.Check = Check;
		SetMarkInList(Item, Check, False);
	EndDo;
	
	// Check parent
	Parent = Data.GetParent();
	
	If verifyParent And Parent <> Undefined Then 
		CheckParent(Parent);
	EndIf;	
EndProcedure

&AtClient
Procedure CheckParent(Parent)
	ParentCheck = True;
		RowItems = Parent.GetItems();
		For Each Item In RowItems Do
			If Not Item.Check Then
				ParentCheck = False;
				Break;
			EndIf;
		EndDo;
	Parent.Check = ParentCheck;
EndProcedure


// Tries to delete selected objects
// Objects, that have not been deleted are displayed in separate table
//
&AtServer
Function DeleteSelectedAtServer(MessageAboutError, TypesOfDeletedObjects)
	
	ToBeDeleted = New Array;
	
	If DeletionMode = "Full" Then
		// On complete deletion we get entire list of items marked for deletion
		ToBeDeleted = DataProcessors.DeleteMarkedObjects.GetMarkedForDeletion();
	Else
		// Fill array with refs to selected items, marked for deletion
		MetadataRowsCollection = ListMarkedForDeletion.GetItems();
		For Each MetadataObjectRow In MetadataRowsCollection Do
			RefRowsCollection = MetadataObjectRow.GetItems();
			For Each RefRow In RefRowsCollection Do
				If RefRow.Check Then
					ToBeDeleted.Add(RefRow.Value);
				EndIf;
			EndDo;
		EndDo;
	EndIf;
	
	NumberOfDeleted = ToBeDeleted.Count();
	
	// Perform deletion
	Result = DataProcessors.DeleteMarkedObjects.DeleteMarkedObjects1(ToBeDeleted, TypesOfDeletedObjects);
	
	If Not Result.Status Then
		MessageAboutError = Result.Value;
		Return False;
	Else
		Founds = Result.Value;
	EndIf;
	
	// Create table of not deleted objects
	NotDeletedObjectsTree.GetItems().Clear();
	
	Tree = FormAttributeToValue("NotDeletedObjectsTree");
	
	For Each Found In Founds Do
		NotDeleted = Found[0];
		Referring = Found[1];
		MetadataObjectOfReferencingOne = Found[2].Presentation();
		MetadataObjectNotDeletedValue = NotDeleted.Metadata().FullName();
		MetadataObjectNotDeletedPresentation = NotDeleted.Metadata().Presentation();
		//metadata branch
		MetadataObjectRow = FindOrAddTreeBranchWithPicture(Tree.Rows, MetadataObjectNotDeletedValue, MetadataObjectNotDeletedPresentation, 0);
		//branch of not deleted object
		RowOfRefToNotDeletedDBObject = FindOrAddTreeBranchWithPicture(MetadataObjectRow.Rows, NotDeleted, String(NotDeleted), 2);
		//branch of ref to not deleted object
		FindOrAddTreeBranchWithPicture(RowOfRefToNotDeletedDBObject.Rows, Referring, String(Referring) + " - " + MetadataObjectOfReferencingOne, 1);
	EndDo;
	
	Tree.Rows.Sort("Value", True);
	ValueToFormAttribute(Tree, "NotDeletedObjectsTree");
	
	// Check completion of delete operation
	// Calculate number of not deleted objects by counting tree branches
	// of second level, where they exist
	NumberOfNotDeletedObjects = 0;
	For Each MetadataObjectRow In Tree.Rows Do
		NumberOfNotDeletedObjects = NumberOfNotDeletedObjects + MetadataObjectRow.Rows.Count();
	EndDo;
	
	DeletedObjects   = NumberOfDeleted - NumberOfNotDeletedObjects;
	If DeletedObjects = 0 Then
		StringOfResults = NStr("en = 'No objects were deleted. The infobase contains references to all of the selected objects.'");
	Else
		StringOfResults = 
			StringFunctionsClientServer.SubstitureParametersInString(
				NStr("en = 'Deletion of marked objects is complete.
                      |Objects deleted: %1.'"),
							String(DeletedObjects));
	EndIf;
	If NumberOfNotDeletedObjects > 0 Then
		StringOfResults = StringOfResults + Chars.LF +
			StringFunctionsClientServer.SubstitureParametersInString(
				NStr("en = 'Objects not deleted: %1.
                      |Objects that are not deleted are referenced by other objects.'"),
				String(NumberOfNotDeletedObjects));
	EndIf;
	
	Return True;
	
EndFunction
