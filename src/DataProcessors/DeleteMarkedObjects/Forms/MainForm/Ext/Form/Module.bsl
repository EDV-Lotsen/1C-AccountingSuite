
&AtClient
Procedure CommandSelectedSelectAll()
	
	ListItems = SelectedForDeletionList.GetItems();
	For Each LI In ListItems Do
		SetMarkInList(LI, True, True);
	EndDo;
	
EndProcedure

&AtClient
Procedure CommandSelectedUnselect()
	
	ListItems = SelectedForDeletionList.GetItems();
	For Each LI In ListItems Do
		SetMarkInList(LI, False, True);
	EndDo;
	
EndProcedure

&AtClient
Procedure DoNext()
	
	CurrentPage = Items.FormPages.CurrentPage;
	If CurrentPage = Items.DeleteModeSelection Then
		
		Status(NStr("en ='Searching for objects selected for deletion'", "en"));
		FillMarkedForDeletionTree();
		Items.CommandNext.Visible           = False;
		Items.CommandDelete.Visible         = True;
		Items.CommandDelete.DefaultButton = True;
		Items.FormPages.CurrentPage = Items.SelectedForDeletion;
		
	ElsIf CurrentPage = Items.DeleteResuts Then
		
		Items.CommandNext.Visible    = False;
		Items.CommandDelete.Visible  = False;
		Items.Close.DefaultButton = True;
		Items.FormPages.CurrentPage = Items.NonDeleteReasons;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DoDelete()
	
	If DeleteMode = "Full" Then
		Status(NStr("en ='Searching and deleting objects selected for deletion'", "en"));
	Else
		Status(NStr("en ='Deleting selected objects'", "en"));
	EndIf;
	
	DeleteMarkedAtServer();
	
EndProcedure

&AtServer
Function FindOrAddTreeBranch(TreeBranches, Value, View, Mark)
	
	// Trying to find an existing branch in TreeBranches without children
	Branch = TreeBranches.Find(Value, "Value", False);
	If Branch = Undefined Then
		// No such branch, creating a new one
		Branch = TreeBranches.Add();
		Branch.Value      = Value;
		Branch.View = View;
		Branch.Mark       = Mark;
	EndIf;

	Return Branch;
	
EndFunction

&AtServer
Function FindOrAddTreeBranchWithImage(TreeBranches, Value, View, PicNumber)  // СтрокиДерева
	
	// Trying to find an existing branch in TreeBranches without children
	Branch = TreeBranches.Find(Value, "Value", False);
	If Branch = Undefined Then
		// No such branch, creating a new one
		Branch = TreeBranches.Add();
		Branch.Value      = Value;
		Branch.View = View;
		Branch.PicNumber = PicNumber;
	EndIf;

	Return Branch;
	
EndFunction

&AtServer
Procedure FillMarkedForDeletionTree()
	
	// Filling a tree of marked for deletion
	TreeOfMarked = FormAttributeToValue("SelectedForDeletionList");
	// processing marked
	ArrayOfMarked = FindMarkedForDeletion();
	For Each ArrayOfMarkedItem In ArrayOfMarked Do
		MetadataObjectValue = ArrayOfMarkedItem.Metadata().FullName();
		MetadataObjectView = ArrayOfMarkedItem.Metadata().Presentation();
		MetadataObjectRow = FindOrAddTreeBranch(TreeOfMarked.Rows, MetadataObjectValue, MetadataObjectView, True);
		FindOrAddTreeBranch(MetadataObjectRow.Rows, ArrayOfMarkedItem, String(ArrayOfMarkedItem) + " - " + MetadataObjectView, True); //  Строка(ArrayOfMarkedItem)
	EndDo;
	TreeOfMarked.Rows.Sort("Value", True); 
	For Each MetadataObjectRow In TreeOfMarked.Rows Do
		// create a view for rows, displaying a metadata object branch
		MetadataObjectRow.View = MetadataObjectRow.View + " (" + MetadataObjectRow.Rows.Count() + ")"; 
	EndDo;
	
	ValueToFormAttribute(TreeOfMarked, "SelectedForDeletionList");
	
EndProcedure

&AtServer
Procedure DeleteMarkedAtServer()
	
	ToDelete = New Array;
	If DeleteMode = "Full" Then
		// For the full deletion mode - get all all marked for deletion
		ToDelete = FindMarkedForDeletion();
	Else
		// Filling the array with selected marked for deletion objects
		MetadataRows = SelectedForDeletionList.GetItems();
		For Each MetadataRowItem In MetadataRows Do
			RefRowCollection = MetadataRowItem.ПолучитьЭлементы();
			For Each RefRow In RefRowCollection Do
				If RefRow.Mark Then
					ToDelete.Add(RefRow.Value);
				EndIf;
			EndDo;
		EndDo;
	EndIf;
	
	OriginatingPage = Items.FormPages.CurrentPage;
	Items.FormPages.CurrentPage = Items.DeleteResuts;
	
	// Perform deletion
	Found = New ValueTable;
	Try
		ExclusiveAccess = ExclusiveMode();
		If NOT ExclusiveAccess Then 
			SetExclusiveMode(True);
		EndIf;
		УдалитьОбъекты(ToDelete, True, Found);
		If NOT ExclusiveAccess Then 
			SetExclusiveMode(False);
		EndIf;
	Except
		Items.FormPages.CurrentPage = OriginatingPage;
		Raise;
	EndTry;
	
	// Create a table of undeleted objects
	NonDeletedObjectTree.GetItems().Clear();
	Tree = FormAttributeToValue("NonDeletedObjectTree");
	For Each FoundObject In Found Do
		Undeleted = FoundObject[0];
		Referencing = FoundObject[1];
		ReferencingMetadataObject = FoundObject[2].Presentation();
		UndeletedMetadataValue = Undeleted.Metadata().FullName();
		UndeletedMetadataView = Undeleted.Metadata().Presentation();
		// metadata branch
		MetadataRowItem = FindOrAddTreeBranchWithImage(Tree.Rows, UndeletedMetadataValue, UndeletedMetadataView, 0);
		// undeleted object tree
		UndeletedRef = FindOrAddTreeBranchWithImage(MetadataRowItem.Rows, Undeleted, String(Undeleted), 2);
		// undeleted object reference tree
		FindOrAddTreeBranchWithImage(UndeletedRef.Rows, Referencing, Строка(Referencing) + " - " + ReferencingMetadataObject, 1);
	EndDo;
	Tree.Rows.Sort("Value", True);
	ValueToFormAttribute(Tree, "NonDeletedObjectTree");
	
	// Checking if the deletion procedure is complete
	// Counting the undeleted, for that count in the select level tree branch
	UndeletedObjects = 0;
	For Each MetadataRowItem In Tree.Rows Do
		UndeletedObjects = UndeletedObjects + MetadataRowItem.Rows.Count(); //.Строки.Количество();
	EndDo;
	
	DeletedObjects   = ToDelete.Count() - UndeletedObjects;
	
	ResultString = String(DeletedObjects) 
		+ NStr("en =' objects deleted!';de=' objekt gelöscht!'");
	If UndeletedObjects > 0 Then
		ResultString = ResultString + Chars.LF + Chars.LF;
		ResultString = ResultString 
			+ UndeletedObjects 
			+ NStr("en =' objects can not be deleted - in the database'") 
			+ Chars.LF;
		ResultString = ResultString 
			+ NStr("en ='other objects are referencing them.'");
	EndIf;
	
	If NonDeletedObjectTree.GetItems().Count() = 0 Then
		// if everything deleted, finishing, display the result, only the Close option is available
		Items.CommandNext.Visible         = False;
		Items.CommandDelete.Visible       = False;
		Items.Close.DefaultButton	    = True;
	Else
		// undeleted are present, allow navigation to the page with the undeletion reasons
		Items.CommandNext.Visible         = True;
		Items.CommandDelete.Visible       = False;
		Items.CommandNext.DefaultButton	= True;
	EndIf;
	
EndProcedure

&AtClient
Procedure SetMarkInList(Data, Mark, CheckParent)
	
	Data.Mark = Mark;
	
	// Set for the children
	LineItems = Data.GetItems();
	For Each LI In LineItems Do
		SetMarkInList(LI, Mark, False);
	EndDo;
	// Checking the parent
	Parent = Data.GetParent();
	If CheckParent AND Parent <> Undefined Then 
		ParentMark = True;
		LineItems = Parent.GetItems();
		For Each LI In LineItems Do
			If NOT LI.Mark Then
				ParentMark = False;
				Break;
			EndIf;
		EndDo;
		If ParentMark <> Parent.Mark Then
			Parent.Mark = ParentMark;
		EndIf;
	EndIf;
	
EndProcedure

//&AtServer
//Procedure OnCreateAtServer(Cancel, StandardProcessing)
//	
//	DeleteMode = "Full";
//	Items.CommandNext.Visible = False;

//EndProcedure

&AtClient
Procedure DeleteModeOnChange(Item)
	
	If DeleteMode = "Full" Then
		Items.CommandNext.Visible   = False;
		Items.CommandDelete.Visible = True;
		Items.CommandDelete.DefaultButton = False;
	ElsIf DeleteMode = "Selected" Then
		Items.CommandNext.Visible = True;
		Items.CommandDelete.Visible = False;
		Items.CommandNext.DefaultButton = True;
	EndIf;

EndProcedure

&AtClient
Procedure MarkOnChange(Item)
	
	CurrentData = Items.SelectedForDeletionList.CurrentData;
	If CurrentData = Undefined Then 
		Return;
	EndIf;
	
	SetMarkInList(CurrentData, CurrentData.Mark, True);

EndProcedure

&AtClient
Procedure NonDeletedObjectTreeSelection(Item, SelectedRow, Field, StandardProcessing)
	
	CurrentData = Items.NonDeletedObjectTree.CurrentData;
	If CurrentData = Undefined Then 
		Return;
	EndIf;
	
	If CurrentData.GetItems().Count() = 0 Then
		// this row displays an object, which prevented deleting the marked and selected
		StandardProcessing = False;
		ShowValue( ,CurrentData.Value);
	EndIf;

EndProcedure

&AtClient
Procedure SelectedForDeletionListSelection(Item, SelectedRow, Field, StandardProcessing)
	
	CurrentData = Items.SelectedForDeletionList.CurrentData;
	If CurrentData = Undefined Then 
		Return;
	EndIf;
	
	If CurrentData.GetItems().Count() = 0 Then
		// this row displays an object marked for deletion
		StandardProcessing = False;
		ShowValue( ,CurrentData.Value);
	EndIf;

EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	DeleteMode = "Full";
	Items.CommandNext.Visible = False;

EndProcedure
