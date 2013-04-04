&AtServer
Procedure OnCreateAtServer(Cancellation, StandardProcessing)
	
	If Parameters.CloseOnChoice = Undefined OR Parameters.CloseOnChoice Then
		Title = NStr("en = 'Select User'");
	Else
		Title = NStr("en = 'Select Users'");
		Items.UsersList.MultipleChoice = True;
		Items.UsersList.SelectionMode = TableSelectionMode.MultiRow;
	EndIf;
	
	UsersList.Parameters.SetParameterValue("EmptyUUID", New Uuid("00000000-0000-0000-0000-000000000000"));
	
EndProcedure

&AtClient
Procedure IBUserAdministration(Command)
	OpenForm("Catalog.Users.Form.IBUsers");
EndProcedure
