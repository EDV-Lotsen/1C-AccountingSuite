

&AtServer
Procedure OnCreateAtServer(Cancellation, StandardProcessing)
	
	Title = 
			StringFunctionsClientServer.SubstitureParametersInString(
					NStr("en = 'Select Users That Can Run ""%1""'"),
					Parameters.CommandPresentation);
	
	For Each UserString In Parameters.UsersWithQuickAccess Do
		NewRow = ShortListUsers.Add();
		NewRow.User = UserString.Value;
	EndDo;
	
	FillTableOfUsersWithShortList();
	
EndProcedure

&AtServer
Procedure FillTableOfUsersWithShortList()
	
	UsersArray = ShortListUsers.Unload().UnloadColumn("User");
	
	QueryText = "SELECT
	            |	TRUE AS InUse,
	            |	Users.Ref AS User
	            |FROM
	            |	Catalog.Users AS Users
	            |WHERE
	            |	(NOT Users.DeletionMark)
	            |	AND (NOT Users.Ref IN (&UsersArray))";
	
	Query = New Query;
	Query.Text = QueryText;
	Query.Parameters.Insert("UsersArray", UsersArray);
	ValueToFormAttribute(Query.Execute().Unload(), "AllUsers");
	
EndProcedure

&AtClient
Procedure OK(Command)
	
	Result = New ValueList;
	
	For Each CollectionItem In ShortListUsers Do
		Result.Add(CollectionItem.User);
	EndDo;
	
	Close(Result);
	
EndProcedure

&AtClient
Procedure ShortListUsersDrag(Item, DragParameters, StandardProcessing, String, Field)
	If TypeOf(DragParameters.Value[0]) = Type("Number") Then
		Return;
	EndIf;
	
	MoveUsers(ShortListUsers, AllUsers, DragParameters.Value);
	
EndProcedure

&AtClient
Procedure ShortListUsersDragCheck(Item, DragParameters, StandardProcessing, String, Field)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure AllUsersDrag(Item, DragParameters, StandardProcessing, String, Field)
	
	If TypeOf(DragParameters.Value[0]) = Type("Number") Then
		Return;
	EndIf;
	
	MoveUsers(AllUsers, ShortListUsers, DragParameters.Value);
	
EndProcedure

&AtClient
Procedure AllUsersDragCheck(Item, DragParameters, StandardProcessing, String, Field)
	
	StandardProcessing = False;
	
EndProcedure

// Block of the service functions

&AtClient
Procedure MoveUsers(Receiver, Source, ArrayOfItemBeingDragged)
	
	For Each DraggedItem In ArrayOfItemBeingDragged Do
		NewUser = Receiver.Add();
		NewUser.User = DraggedItem.User;
		Source.Delete(DraggedItem);
	EndDo;
	
	Receiver.Sort("User Asc");
	
EndProcedure
