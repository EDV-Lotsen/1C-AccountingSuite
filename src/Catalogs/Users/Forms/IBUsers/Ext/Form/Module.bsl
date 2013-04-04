
// Field IBUsers.ProblemCode
// 0 - IBUser is not recorded to the catalog
// 1 - FullName differs from Description
// 2 - IBUser is not found
// 3 - IBUser is empty UUID
// 4 - everything is OK
// for codes 0,1 red background
// for codes 2,3 grey background
//

////////////////////////////////////////////////////////////////////////////////
// FORM EVENT HANDLERS
//

&AtServer
Procedure OnCreateAtServer(Cancellation, StandardProcessing)
	
	SetPrivilegedMode(True);
	
	If NOT Users.CurrentUserHaveFullAccess() Then
		Raise(NStr("en = 'Do not have full access rights!'"));
	EndIf;
	
	Filter = "All";
	FilterPresentation = Items.FilterPresentation.ChoiceList[0].Presentation;
	
	FillIBUsers(True);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "AddedIBUser" OR
	   EventName = "IBUserChanged" OR
	   EventName = "DeletedIBUser" OR
	   EventName = "ClearedLinkWithNotExistingIBUser" Then
		
		FillIBUsers();
	EndIf;
	
EndProcedure


////////////////////////////////////////////////////////////////////////////////
// Event handlers of commands and form items
//

&AtClient
Procedure Change(Command)
	
	OpenUserByRef();
	
EndProcedure

&AtClient
Procedure Refresh(Command)
	
	FillIBUsers();
	
EndProcedure

&AtClient
Procedure FilterPresentationOnChange(Item)
	
	If NOT ValueIsFilled(FilterPresentation) Then
		Filter = "All";
		FilterPresentation = Items.FilterPresentation.ChoiceList.FindByValue(Filter).Presentation;
	EndIf;
	
	FillIBUsers();
	
EndProcedure

&AtClient
Procedure FilterPresentationStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	SelectedElement = ChooseFromList(Items.FilterPresentation.ChoiceList, Item, Items.FilterPresentation.ChoiceList.FindByValue(Filter));
	
	If SelectedElement <> Undefined Then
		
		Filter             = SelectedElement.Value;
		FilterPresentation = SelectedElement.Presentation;
		FilterPresentationOnChange(Item);
	EndIf;
	
EndProcedure

&AtClient
Procedure UsersOfInfBaseSelection(Item, RowSelected, Field, StandardProcessing)
	
	OpenUserByRef();
	
EndProcedure

&AtClient
Procedure UsersOfInfBaseOnActivateRow(Item)
	
	CanDelete = Items.UsersOfInfBase.CurrentData <> Undefined And
	            Items.UsersOfInfBase.CurrentData.ProblemCode = 0;
	
	Items.UsersOfInfBaseDelete.Enabled           = CanDelete;
	Items.ContextMenuInfobaseUsersDelete.Enabled = CanDelete;
	
EndProcedure

&AtClient
Procedure UsersOfInfBaseBeforeDelete(Item, Cancellation)
	
	If Items.UsersOfInfBase.CurrentData.ProblemCode = 0 Then
		If DoQueryBox(NStr("en = 'Delete information base user?'"), QuestionDialogMode.YesNo) = DialogReturnCode.Yes Then
			DeleteIBUsers(Items.UsersOfInfBase.CurrentData.IBUserID, Cancellation);
		Else
			Cancellation = True;
		EndIf;
	Else
		Cancellation = True;
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Auxiliary form procedures and functions
//

&AtServer
Procedure FillIBUsers(OnFormCreate = False)
	
	UsersOfInfBase.Clear();
	AreImproperlyRecorded = False;
	
	Query = New Query(
	"SELECT
	|	Users.Ref,
	|	Users.Description,
	|	Users.IBUserID,
	|	Users.DeletionMark
	|FROM
	|	Catalog.Users AS Users");
	
	Selection = Query.Execute().Choose();
	
	While Selection.Next() Do
		
		IBUser = InfoBaseUsers.FindByUUID(Selection.IBUserID);
		
		NewRow = UsersOfInfBase.Add();
		NewRow.ProblemCode         = 4;
		NewRow.Ref                 = Selection.Ref;
		NewRow.FullName            = Selection.Description;
		NewRow.DeletionMark        = Selection.DeletionMark;
		
		If IBUser = Undefined Then
			NewRow.ProblemCode = ?(ValueIsFilled(Selection.IBUserID), 2, 3);
			AreImproperlyRecorded = AreImproperlyRecorded OR ValueIsFilled(Selection.IBUserID);
		Else
			NewRow.Name                         = IBUser.Name;
			NewRow.StandardAuthentication  		= IBUser.StandardAuthentication;
			NewRow.OSAuthentication             = IBUser.OSAuthentication;
			NewRow.OSUser              			= IBUser.OSUser;
			NewRow.IBUserID 					= IBUser.Uuid;
			
			If Selection.Description <> IBUser.FullName Then // mismatch by full name
				NewRow.ProblemCode = 1;
				AreImproperlyRecorded = True;
			EndIf;
		EndIf;
		
		NewRow.Picture = GetPictureNoByStatus(NewRow.ProblemCode, NewRow.DeletionMark, False);
		
	EndDo;
	
	IBUsers = InfoBaseUsers.GetUsers();
	
	For Each IBUser In IBUsers Do
		
		If UsersOfInfBase.FindRows(New Structure("IBUserID", IBUser.Uuid)).Count() = 0 Then
			// no such IB user in the catalog
			NewRow = UsersOfInfBase.Add();
			NewRow.ProblemCode            = 0;
			NewRow.FullName               = IBUser.FullName;
			NewRow.Name                   = IBUser.Name;
			NewRow.StandardAuthentication = IBUser.StandardAuthentication;
			NewRow.OSAuthentication       = IBUser.OSAuthentication;
			NewRow.OSUser                 = IBUser.OSUser;
			NewRow.IBUserID 			  = IBUser.Uuid;
			NewRow.Picture                = GetPictureNoByStatus(NewRow.ProblemCode, NewRow.DeletionMark, False);
			AreImproperlyRecorded 	 	  = True;
		EndIf;
		
	EndDo;
	
	If OnFormCreate And AreImproperlyRecorded Then
		Filter = "WrittenIncorrectly";
		FilterPresentation = Items.FilterPresentation.ChoiceList[1].Presentation;
	EndIf;
	
	RowsToBeDeleted = New Array;
	If Filter = "WrittenIncorrectly" Then
		RowsToBeDeleted.Add(UsersOfInfBase.FindRows(New Structure("ProblemCode", 3)));
		RowsToBeDeleted.Add(UsersOfInfBase.FindRows(New Structure("ProblemCode", 4)));
		
	ElsIf Filter = "NoInfobaseUser" Then
		RowsToBeDeleted.Add(UsersOfInfBase.FindRows(New Structure("ProblemCode", 0)));
		RowsToBeDeleted.Add(UsersOfInfBase.FindRows(New Structure("ProblemCode", 1)));
		RowsToBeDeleted.Add(UsersOfInfBase.FindRows(New Structure("ProblemCode", 4)));
	EndIf;
	
	For Each Rows In RowsToBeDeleted Do
		For Each String In Rows Do
			UsersOfInfBase.Delete(UsersOfInfBase.IndexOf(String));
		EndDo;
	EndDo;
	
	UsersOfInfBase.Sort("DeletionMark Asc, ProblemCode Asc");
	
	Items.WarningGroup.Visible = AreImproperlyRecorded;
	
EndProcedure

&AtServer
Function GetPictureNoByStatus(Val ProblemCode, Val DeletionMark, Val ThisIsExternalUser)
	
	PictureNo = -1;
	
	If ProblemCode = 1 OR ProblemCode = 0 Then
		PictureNo = 5;
	EndIf;
		
	If DeletionMark Then
		If ProblemCode = 2 OR ProblemCode = 3 OR ProblemCode = 4 Then
			PictureNo = 0;
		EndIf;
	Else
		If ProblemCode = 4 Then
			PictureNo = 1;
		ElsIf ProblemCode = 2 OR ProblemCode = 3 Then
			PictureNo = 4;
		EndIf;
	EndIf;
	
	If PictureNo >= 0 And ThisIsExternalUser Then
		PictureNo = PictureNo + 6;
	EndIf;
	
	Return PictureNo;
	
EndFunction

&AtServer
Procedure DeleteIBUsers(IBUserID, Cancellation)
	
	ErrorDescription = "";
	If NOT Users.DeleteIBUsers(IBUserID, ErrorDescription) Then
		CommonUseClientServer.MessageToUser(ErrorDescription, , , , Cancellation);
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenUserByRef()
	
	CurrentData = Items.UsersOfInfBase.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If CurrentData.ProblemCode = 0 Then
		DoMessageBox(NStr(	"en = 'Specified user is not linked with a catalog user.
                                  |To create login linked to the user check the box ""Allow access to information base"" in the corresponding item form.'"));
		
		Cancellation = False;
		UsersOfInfBaseBeforeDelete(Items.UsersOfInfBase, Cancellation);
		If NOT Cancellation Then
			UsersOfInfBase.Delete(CurrentData);
		EndIf;
	Else
		OpenForm("Catalog.Users.ObjectForm", New Structure("Key", CurrentData.Ref));
	EndIf;
	
EndProcedure
