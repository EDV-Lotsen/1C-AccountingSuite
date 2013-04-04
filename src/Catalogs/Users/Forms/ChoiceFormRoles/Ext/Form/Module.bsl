

////////////////////////////////////////////////////////////////////////////////
// FORM EVENT HANDLERS
//

&AtServer
Procedure OnCreateAtServer(Cancellation, StandardProcessing)
	
	FillMode = Parameters.CloseOnChoice = False;
	
	If FillMode Then
		Title = NStr("en = 'Select Roles'");
		Items.Roles.MultipleChoice 						= True;
		Items.Roles.SelectionMode	 					= TableSelectionMode.MultiRow;
		Items.RolesOfCurrentSubsystem.MultipleChoice 	= True;
		Items.RolesOfCurrentSubsystem.SelectionMode 	= TableSelectionMode.MultiRow;
	Else
		Title = NStr("en = 'Select Role'");
	EndIf;
	
	TreeOfSubsystems = UsersServerSecondUse.TreeOfSubsystems();
	TreeOfSubsystems.Rows.Sort("Synonym Asc", True);
	ValueToFormData(TreeOfSubsystems, Subsystems);
	
	AllRoles = UsersServerSecondUse.AllRoles();
	
	For Each String In AllRoles Do
		If Upper(String.Name) = Upper("FullAccess") Then
			Continue;
		EndIf;
		
		// Fill roles
		NewRow = Roles.Add();
		NewRow.Name               	= String.Name;
		NewRow.Synonym           	= String.Synonym;
		NewRow.SubsystemNames    	= String.SubsystemNames;
		NewRow.SynonymsOfSubsystems = String.SynonymsOfSubsystems;
		
	EndDo;
	Roles.Sort("Synonym Asc");
	
	Parameters.Property("CurrentRow", CurrentRole);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancellation)
	
	OnCurrentRoleChange();
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	ShowSubsystems1 = Settings["ShowSubsystems1"];
	Items.DisplayMethod.CurrentPage = ?(ShowSubsystems1, Items.SubsystemRoles, Items.ListOfRoles);
	Items.ShowSubsystems.Check = ShowSubsystems1;
	
	ShowRolesOfSubordinateSubsystems = Settings["ShowRolesOfSubordinateSubsystems"];
	
EndProcedure


////////////////////////////////////////////////////////////////////////////////
// Event handlers of commands and form items
//

&AtClient
Procedure Select(Command)
	
	If Items.DisplayMethod.CurrentPage = Items.SubsystemRoles Then
		SelectedRows = Items.RolesOfCurrentSubsystem.SelectedRows;
		Collection = RolesOfCurrentSubsystem;
	Else
		SelectedRows = Items.Roles.SelectedRows;
		Collection = Roles;
	EndIf;
	
	If SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	If SelectedRows.Count() > 1 OR FillMode Then
		ChoiceValue = New Array;
		For each Id In SelectedRows Do
			ChoiceValue.Add(Collection.FindByID(Id).Name);
		EndDo;
		
	Else
		ChoiceValue = Collection.FindByID(SelectedRows[0]).Name;
	EndIf;
	
	NotifyChoice(ChoiceValue);
	
EndProcedure

&AtClient
Procedure ShowSubsystems(Command)
	
	ShowSubsystems1 = NOT ShowSubsystems1;
	
	Items.DisplayMethod.CurrentPage = ?(ShowSubsystems1, Items.SubsystemRoles, Items.ListOfRoles);
	Items.ShowSubsystems.Check = ShowSubsystems1;
	
EndProcedure


&AtClient
Procedure RolesValueChoice(Item, Value, StandardProcessing)
	
	StandardProcessing = False;
	
	If TypeOf(Value) = Type("Array") Then
		ChoiceValue = New Array;
		For each Id In Value Do
			ChoiceValue.Add(Roles.FindByID(Id).Name);
		EndDo;
		
	Else
		ChoiceValue = Roles.FindByID(Value).Name;
	EndIf;
	
	NotifyChoice(ChoiceValue);
	
EndProcedure

&AtClient
Procedure RolesOnActivateRow(Item)
	
	If Item.CurrentData = Undefined Then
		Return;
	EndIf;
	
	CurrentRole = Item.CurrentData.Name;
	
	OnCurrentRoleChange();
	
EndProcedure


&AtClient
Procedure SubsystemsOnActivateRow(Item)
	
	// Fill subsystem roles.
	RolesOfCurrentSubsystem.Clear();
	
	If Item.CurrentData = Undefined Then
		Return;
	EndIf;
	
	For each RoleRow In Roles Do
		If Find(", " + RoleRow.SubsystemNames + ", ", ", " + Item.CurrentData.FullName + ?(ShowRolesOfSubordinateSubsystems, "", ", ")) > 0 Then
			
			NewRow 			= RolesOfCurrentSubsystem.Add();
			NewRow.Name     = RoleRow.Name;
			NewRow.Synonym 	= RoleRow.Synonym;
		EndIf;
		
	EndDo;

EndProcedure

&AtClient
Procedure ShowRolesOfSubordinateSubsystemsOnChange(Item)
	
	SubsystemsOnActivateRow(Items.Subsystems);
	
EndProcedure


&AtClient
Procedure RolesOfCurrentSubsystemValueChoice(Item, Value, StandardProcessing)
	
	StandardProcessing = False;
	
	If TypeOf(Value) = Type("Array") Then
		ChoiceValue = New Array;
		For each Id In Value Do
			ChoiceValue.Add(RolesOfCurrentSubsystem.FindByID(Id).Name);
		EndDo;
		
	Else
		ChoiceValue = RolesOfCurrentSubsystem.FindByID(Value).Name;
	EndIf;
	
	NotifyChoice(ChoiceValue);
	
EndProcedure

&AtClient
Procedure RolesOfCurrentSubsystemOnActivateRow(Item)
	
	If Item.CurrentData = Undefined Then
		Return;
	EndIf;
	
	CurrentRole = Item.CurrentData.Name;
	
	OnCurrentRoleChange();
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Auxiliary form procedures and functions
//

&AtClient
Procedure OnCurrentRoleChange()
	
	If NOT ValueIsFilled(CurrentRole) Then
		Return;
	EndIf;
	
	RowsFound = Roles.FindRows(New Structure("Name", CurrentRole));
	If RowsFound.Count() > 0 Then
		If Items.Roles.CurrentRow <> RowsFound[0].GetID() Then
			Items.Roles.CurrentRow = RowsFound[0].GetID();
		EndIf;
		RoleRow = RowsFound[0];
		
		RowsFound = RolesOfCurrentSubsystem.FindRows(New Structure("Name", CurrentRole));
		If RowsFound.Count() > 0 Then
			If Items.RolesOfCurrentSubsystem.CurrentRow <> RowsFound[0].GetID() Then
				Items.RolesOfCurrentSubsystem.CurrentRow = RowsFound[0].GetID();
			EndIf;
		ElsIf CurrentSubsystemOfRoleIsSet(RoleRow, Subsystems.GetItems()) Then
			SubsystemsOnActivateRow(Items.Subsystems);
			RowsFound = RolesOfCurrentSubsystem.FindRows(New Structure("Name", CurrentRole));
			If Items.RolesOfCurrentSubsystem.CurrentRow <> RowsFound[0].GetID() Then
				Items.RolesOfCurrentSubsystem.CurrentRow = RowsFound[0].GetID();
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Function CurrentSubsystemOfRoleIsSet(RoleRow, ItemsOfSubsystems)
	
	For each SubsystemsItem In ItemsOfSubsystems Do
		If Find(", " + RoleRow.SubsystemNames + ", ", ", " + SubsystemsItem.FullName + ", ") > 0 Then
			If Items.Subsystems.CurrentRow <> SubsystemsItem.GetID() Then
				Items.Subsystems.CurrentRow = SubsystemsItem.GetID();
			EndIf;
			Return True;
		EndIf;
		If CurrentSubsystemOfRoleIsSet(RoleRow, SubsystemsItem.GetItems()) Then
			Return True;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

