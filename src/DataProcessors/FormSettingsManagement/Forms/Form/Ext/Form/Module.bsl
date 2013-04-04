
//////////////////////////////////////////////////////////////////////
// AUXILIARY PROCEDURES AND FUNCTIONS
&AtServer
Procedure FillUsersList()
	
	ListOfUsers = InfoBaseUsers.GetUsers();
	
	For Each CurUser In ListOfUsers Do
		
		Items.User.ChoiceList.Add(CurUser.Name);
		
	EndDo;
	
EndProcedure

&AtServer
Procedure RefreshFormsList()
	
	DataProcessor = FormAttributeToValue("Object");
	FormList = New ValueList;
	DataProcessor.GetFormList(FormList);
	Forms.Clear();
	DataProcessor.GetSavedSettingsList(FormList, User, Forms);
	
EndProcedure

&AtServer
Function GetSelectedSettingsArray()
	
	SettingsArray = New Array;
	
	SelectedElements = Items.FilteredForms.SelectedRows;
	
	For Each DedicatedElement In SelectedElements Do
		
		SettingsArray.Add(Forms.FindByValue(FilteredForms.FindByID(DedicatedElement).Value).Value);
		
	EndDo;
	
	Return SettingsArray;
	
EndFunction

&AtServer
Procedure CopyAtServer(UsersReceiver)

	SettingsForCopyArray = GetSelectedSettingsArray();
	
	DataProcessor = FormAttributeToValue("Object");
	DataProcessor.CopyFormSettings(User, UsersReceiver, SettingsForCopyArray);
		
EndProcedure

&AtServer
Procedure DeleteAtServer()
	
	SettingsForDeleteArray = GetSelectedSettingsArray();
	
	DataProcessor = FormAttributeToValue("Object");
	DataProcessor.DeleteFormSettings(User, SettingsForDeleteArray);
	
EndProcedure

Procedure ApplyFilter()
	
	FilteredForms.Clear();
	
	For Each ItemForm1 In Forms Do
		
		If Search = "" Or Find(Upper(ItemForm1.Presentation), Upper(Search)) <> 0 Then
			
			FilteredForms.Add(ItemForm1.Value, ItemForm1.Presentation, ItemForm1.Check, ItemForm1.Picture);
			
		EndIf;
		
	EndDo;
	
	UsedSearch = Search;
	
EndProcedure

//////////////////////////////////////////////////////////////////////
// Command handlers
&AtClient
Procedure RefreshExecute()
	
	RefreshFormsList();
	ApplyFilter();
	
EndProcedure

&AtClient
Procedure CopyExecute()
	
	If Items.FilteredForms.SelectedRows.Count() = 0 Then
		DoMessageBox(NStr("en = 'To copy you need to choose the settings which need to be copied'"));
		Return;
	EndIf;
	
	ListOfUsers = Items.User.ChoiceList.Copy();
	
	If ListOfUsers.Count() = 0 Then
		DoMessageBox(NStr("en = 'It is impossible to copy settings as system does not have users.'"));
		Return;
	EndIf;
	
	ItemOfList = ListOfUsers.FindByValue(User);
	If ItemOfList <> Undefined Then
		ListOfUsers.Delete(ItemOfList);
	EndIf;
	
	If ListOfUsers.CheckItems(NStr("en = 'Check users who need copied settings'")) Then
		UsersReceiver = New Array;
		For Each Item In ListOfUsers Do
			Items.User.ChoiceList.FindByValue(Item.Value).Check = Item.Check;
			If Item.Check Then
				UsersReceiver.Add(Item.Value);
			EndIf;
		EndDo;
		
		If UsersReceiver.Count() = 0 Then
			DoMessageBox(NStr("en = 'Check the box of the users that need copy of the settings. '"));
			Return;
		EndIf;
		
		QuestionText = NStr("en = 'After settings user settings user form will open with copied settings. Previous settings will be lost. Do you really want to copy settings to the selected users?'");
		If DoQueryBox(QuestionText, QuestionDialogMode.YesNo,, DialogReturnCode.Yes) <> DialogReturnCode.Yes Then
			Return;
		EndIf;
		
		CopyAtServer(UsersReceiver);
		ShowUserNotification(NStr("en = 'Settings copied'"));
	EndIf;
	
EndProcedure

&AtClient
Procedure DeleteExecute()
	
	If Items.FilteredForms.SelectedRows.Count() = 0 Then
		
		DoMessageBox(NStr("en = 'To delete, it is necessary to select the settings that need to be deleted'"));
		Return;
		
	EndIf;
	
	QuestionText = NStr("en = 'After deleting the settings form will open with default settings. Do you really want to delete settings?'");
	If DoQueryBox(QuestionText, QuestionDialogMode.YesNo,, DialogReturnCode.Yes) <> DialogReturnCode.Yes Then
		
		Return;
		
	EndIf;
	
	DeleteAtServer();
	RefreshFormsList();
	ApplyFilter();
	
	ShowUserNotification(NStr("en = 'Settings deleted'"));
	
EndProcedure

&AtClient
Procedure SearchExecute()
	
	ApplyFilter();
	
EndProcedure

//////////////////////////////////////////////////////////////////////
// FORM EVENT HANDLERS
&AtServer
Procedure OnCreateAtServer(Cancellation, StandardProcessing)
	
	FillUsersList();
	User = UserName();
	RefreshFormsList();
	ApplyFilter();
	
EndProcedure

//////////////////////////////////////////////////////////////////////
// Event handlers of form items
&AtClient
Procedure UserOnChange(Item)
	
	RefreshFormsList();
	ApplyFilter();
	
EndProcedure

&AtClient
Procedure SearchOnChange(Item)
	
	ApplyFilter();
	
EndProcedure

