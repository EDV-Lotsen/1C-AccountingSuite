

////////////////////////////////////////////////////////////////////////////////
// FORM EVENT HANDLERS
//

&AtServer
Procedure OnCreateAtServer(Cancellation, StandardProcessing)
	
	If NOT AccessRight("Insert", Metadata.Catalogs.Users) Then
		Items.CreateUser.Visible = False;
	EndIf;
	
	If Parameters.ChoiceMode Then
		If Items.Find("IBUsers") <> Undefined Then
			Items.IBUsers.Visible = False;
		EndIf;
		
		// Filter of items not marked for deletion
		UsersList.Filter.Items[0].Use = True;
		Items.UsersList.ChoiceMode    = True;
		
		// Selection mode
		If Parameters.CloseOnChoice = False Then
			Items.UsersList.MultipleChoice = True;
			Items.UsersList.SelectionMode  = TableSelectionMode.MultiRow;
		EndIf;
	Else
		Items.SelectUser.Visible        = False;
	EndIf;
	
	// Configure constant data for user list
	UsersList.Parameters.SetParameterValue("EmptyUUID", New Uuid("00000000-0000-0000-0000-000000000000"));
		
EndProcedure
