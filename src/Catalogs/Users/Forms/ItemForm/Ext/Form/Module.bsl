
////////////////////////////////////////////////////////////////////////////////
// FORM EVENT HANDLERS
//

&AtServer
Procedure OnCreateAtServer(Cancellation, StandardProcessing)
	
	//** Assign initial values
	//   before loading data from settings at server
	//   for case, when data have not been recorded yet and are not being loaded
	ShowOnlySelectedRoles = (Items.RepresentationOfRoles.CurrentPage = Items.OnlySelectedRoles);
	
	//** Fill constant data
	
	PrepareChoiceListAndTableOfRoles();
	
	// Fill language choice list
	For each LanguageMetadata IN Metadata.Languages Do
		Items.LanguagePresentation.ChoiceList.Add(LanguageMetadata.Synonym);
	EndDo;
	
	//** Preparation for the interactive actions including form open scenarios
	
	SetActionsWithRoles();
	
	SetPrivilegedMode(True);
	
	If NOT ValueIsFilled(Object.Ref) Then
		// Creating new item
		If ValueIsFilled(Parameters.CopyingValue) Then
			// Copying item
			Object.Description = "";
			ReadIBUser(ValueIsFilled(Parameters.CopyingValue.IBUserID));
		Else
			// Inserting item
			Object.IBUserID = Parameters.IBUserID;
			// Reading initial values of IB user properties
			ReadIBUser();
		EndIf;
	Else
		// Opening existing item
		ReadIBUser();
	EndIf;
	
	SetPrivilegedMode(False);
	
	DefineActionsInForm();
	
	DefineUserInconsistenciesWithUserIB();
	
	//** Assign constant accessibility of the properties
	Items.IBUserProperties.Visible = ValueIsFilled(ActionsInForm.IBUserProperties);
	Items.RepresentationOfRoles.Visible       = ValueIsFilled(ActionsInForm.Roles);
	
	ReadOnly = ReadOnly OR
	                 ActionsInForm.Roles <> 				"Edit" And
	                 NOT ( ActionsInForm.IBUserProperties = "EditAll" OR
	                      ActionsInForm.IBUserProperties =  "EditOfTheir"     ) And
	                 ActionsInForm.ItemProperties <> 		"Edit";
	
	SetReadOnlyOfRoles(ActionsInForm.Roles <> "Edit");
	
	MarkRolesByList();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancellation)
	
	#If WebClient Then
	Items.InfBaseUserOSUser.ChoiceButton = False;
	#EndIf
	
	SetAccessibilityOfProperties();
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancellation)
	
	ClearMessages();
	
	If ActionsInForm.Roles = "Edit" And Roles.Count() = 0 Then
		
		If DoQueryBox(NStr("en = 'No roles have been assigned to the user of the information base. Do you wan to continue?'"),
						   QuestionDialogMode.YesNo,
						   ,
						   ,
						   NStr("en = 'Record of the information base user'")) = DialogReturnCode.No Then
			Cancellation = True;
		EndIf;
	EndIf;
	
	If NeedToCreateFirstAdministrator() Then
		QuestionText = NStr("en = 'First user of the information base must have full rights.""Role will be automatically added. Do you want to continue?'");
		UsersClientOverrided.QuestionTextBeforeWriteFirstAdministrator(QuestionText);
		If DoQueryBox(QuestionText,
		            QuestionDialogMode.YesNo,
		            ,
		            ,
		            NStr("en = 'Record of the information base user'")) = DialogReturnCode.No Then
			Cancellation = True;
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancellation, CurrentObject, WriteParameters)
	
	If NeedToCreateFirstAdministrator() Then
		WriteParameters.Insert("FirstAdministratorRecord");
	EndIf;
	
	If ActionsInForm.ItemProperties <> "Edit" Then
		FillPropertyValues(CurrentObject, CommonUse.GetAttributeValues(CurrentObject.Ref, "Description, DeletionMark"));
	EndIf;
	
	If AccessToInformationBaseAllowed Then
		
		If Items.FullNameInconsistenceExplanation.Visible Then
			InfBaseUserFullName = Object.Description;
		EndIf;
		
		WriteIBUser(CurrentObject, Cancellation);
		If NOT Cancellation Then
			If CurrentObject.IBUserID <> OldIBUserID Then
				WriteParameters.Insert("AddedIBUser", CurrentObject.IBUserID);
			Else
				WriteParameters.Insert("IBUserChanged", CurrentObject.IBUserID);
			EndIf
		EndIf;
		
	ElsIf NOT IsLinkWithNonexistentIBUser OR
	          ActionsInForm.IBUserProperties = "EditAll" Then
		
		CurrentObject.IBUserID = Undefined;
	EndIf;
	
EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancellation, CurrentObject, WriteParameters)
	
	If NOT AccessToInformationBaseAllowed And IBUserExists Then
		DeleteIBUsers(Cancellation);
		If NOT Cancellation Then
			WriteParameters.Insert("DeletedIBUser", OldIBUserID);
		EndIf;
	EndIf;
	
	If WriteParameters.Property("FirstAdministratorRecord") Then
		SetPrivilegedMode(True);
			UsersOverrided.OnWriteOfFirstAdministrator(Object.Ref);
		SetPrivilegedMode(False);
	EndIf;
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	If CurrentObject.AdditionalProperties.Property("AreErrors") Then
		WriteParameters.Insert("AreErrors");
	EndIf;
	
	ReadIBUser();
	
	DefineUserInconsistenciesWithUserIB(WriteParameters);
	
	MarkRolesByList();
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	If WriteParameters.Property("AddedIBUser") Then
		Notify("AddedIBUser", WriteParameters.AddedIBUser, ThisForm);
		
	ElsIf WriteParameters.Property("IBUserChanged") Then
		Notify("IBUserChanged", WriteParameters.IBUserChanged, ThisForm);
		
	ElsIf WriteParameters.Property("DeletedIBUser") Then
		Notify("DeletedIBUser", WriteParameters.DeletedIBUser, ThisForm);
		
	ElsIf WriteParameters.Property("ClearedLinkWithNotExistingIBUser") Then
		Notify("ClearedLinkWithNotExistingIBUser", WriteParameters.ClearedLinkWithNotExistingIBUser, ThisForm);
	EndIf;
	
	If WriteParameters.Property("AreErrors") Then
		DoMessageBox(NStr("en = 'Some errors occurred while writing (see event log)'"));
	EndIf;
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancellation, CheckedAttributes)
	
	If AccessToInformationBaseAllowed Then
		
		FillCheckProcessingOfRoleList(Cancellation);
		
		If NOT Cancellation And IsBlankString(InfBaseUserName) Then
			CommonUseClientServer.MessageToUser(
							NStr("en = 'Information base User''s name not filled in'"), ,
							"InfBaseUserName", ,
							Cancellation);
		EndIf;
		
		If  NOT Cancellation And InfBaseUserPassword <> Undefined And Password <> PasswordConfirmation Then
			CommonUseClientServer.MessageToUser(
							NStr("en = 'Password and password conformation do not match'"), ,
							"Password", ,
							Cancellation);
			Return;
		EndIf;
		
		If NOT Cancellation And NOT IsBlankString(InfBaseUserOSUser) Then
			SetPrivilegedMode(True);
			Try
				IBUser = InfoBaseUsers.CreateUser();
				IBUser.OSUser = InfBaseUserOSUser;
			Except
				CommonUseClientServer.MessageToUser(
								NStr("en = 'OS user should be in the format \\DomainName\\userUame '"), ,
								"InfBaseUserOSUser", ,
								Cancellation);
			EndTry;
			SetPrivilegedMode(False);
		EndIf;
	EndIf;
	
	If Cancellation Then
		CheckedAttributes.Clear();
	EndIf;
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	If Settings["ShowOnlySelectedRoles"] = False Then
		Items.RepresentationOfRoles.CurrentPage = Items.AmongAllSelectedRoles;
	Else
		Items.RepresentationOfRoles.CurrentPage = Items.OnlySelectedRoles;
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Event handlers of commands and form items
//

&AtClient
Procedure FullNameRunSynchronization(Command)
	
	Object.Description = InfBaseUserFullName;
	Items.FullNameInconsistenceProcessing.Visible = False;
	
EndProcedure

&AtClient
Procedure DescriptionOnChange(Item)
	
	// If FullName is defined, then it has to be updated.
	// Note.: undefined FullName or other property
	//        is not taken into account on IB user write
	//        FullName is defined only for type
	//        of interactive actions "WithoutRestriction"
	If InfBaseUserFullName <> Undefined Then
		InfBaseUserFullName = Object.Description;
	EndIf;
	
	If NOT IBUserExists And AccessToInformationBaseAllowed Then
		InfBaseUserName = GetShortNameOfIBUser(Object.Description);
	EndIf;
	
EndProcedure

&AtClient
Procedure AccessToInformationBaseAllowedOnChange(Item)
	
	If NOT IBUserExists And AccessToInformationBaseAllowed Then
		InfBaseUserName       = GetShortNameOfIBUser(Object.Description);
		InfBaseUserFullName = Object.Description;
	EndIf;
	
	SetAccessibilityOfProperties();
	
EndProcedure

&AtClient
Procedure InfBaseUserStandardAuthenticationOnChange(Item)
	
	SetAccessibilityOfProperties();
	
EndProcedure

&AtClient
Procedure PasswordOnChange(Item)
	
	InfBaseUserPassword = Password;
	
EndProcedure

&AtClient
Procedure InfBaseUserOSAuthenticationOnChange(Item)
	
	SetAccessibilityOfProperties();
	
EndProcedure

&AtClient
Procedure InfBaseUserOSUserStartChoice(Item, ChoiceData, StandardProcessing)
	
	#If NOT WebClient Then
		Result = OpenFormModal("Catalog.Users.Form.OSUserChoiceForm");
		
		If TypeOf(Result) = Type("String") Then
			InfBaseUserOSUser = Result;
		EndIf;
	#EndIf
	
EndProcedure

//** For operation of the roles interface

&AtClient
Procedure FillRoles(Command)
	
	OpenForm("Catalog.Users.Form.ChoiceFormRoles", New Structure("CloseOnChoice", False), Items.Roles);
	
EndProcedure

&AtClient
Procedure RolesOnChange(Item)
	
	MarkRolesByList();
	
EndProcedure

&AtClient
Procedure RolesOnEditEnd(Item, NewRow, CancelEdit)
	
	MarkRolesByList();
	
EndProcedure

&AtClient
Procedure RolesChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	AddSelectedRoles(ValueSelected);
	
EndProcedure


&AtClient
Procedure RoleSynonymOnChange(Item)
	
	If ValueIsFilled(Items.Roles.CurrentData.RoleSynonym) Then
		Items.Roles.CurrentData.RoleSynonym = ChoiceListOfRoles.FindByValue(Items.Roles.CurrentData.Role).Presentation;
	Else
		Items.Roles.CurrentData.Role = "";
	EndIf;
	
EndProcedure

&AtClient
Procedure RoleSynonymStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	InitialValue = ?(Items.Roles.CurrentData = Undefined, Undefined, Items.Roles.CurrentData.Role);
	OpenForm("Catalog.Users.Form.ChoiceFormRoles", New Structure("CurrentRow", InitialValue), Item);

EndProcedure

&AtClient
Procedure RoleSynonymChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	
	Items.Roles.CurrentData.Role        = ValueSelected;
	Items.Roles.CurrentData.RoleSynonym = ChoiceListOfRoles.FindByValue(Items.Roles.CurrentData.Role).Presentation;
	
EndProcedure

&AtClient
Procedure RoleSynonymAutoComplete(Item, Text, ChoiceData, Wait, StandardProcessing)
	
	If ValueIsFilled(Text) Then 
		StandardProcessing = False;
		ChoiceData = GenerateRolesChoiceData(Text);
	EndIf;
	
EndProcedure

&AtClient
Procedure RoleSynonymTextEditEnd(Item, Text, ChoiceData, StandardProcessing)
	
	If ValueIsFilled(Text) Then 
		StandardProcessing = False;
		ChoiceData = GenerateRolesChoiceData(Text);
	EndIf;
	
EndProcedure


&AtClient
Procedure TableOfRolesCheckOnChange(Item)
	
	TableRow = Items.TableOfRoles.CurrentData;
	
	RolesFound = Roles.FindRows(New Structure("Role", TableRow.Name));
	
	If TableRow.Check Then
		If RolesFound.Count() = 0 Then
			String = Roles.Add();
			String.Role = TableRow.Name;
			String.RoleSynonym = TableRow.Synonym;
		EndIf;
	ElsIf RolesFound.Count() > 0 Then
		Roles.Delete(RolesFound[0]);
	EndIf;
	
EndProcedure

&AtClient
Procedure ShowOnlySelectedRoles(Command)
	
	ShowOnlySelectedRoles = NOT ShowOnlySelectedRoles;
	
	Items.RepresentationOfRoles.CurrentPage = ?(ShowOnlySelectedRoles, Items.OnlySelectedRoles, Items.AmongAllSelectedRoles);
	CurrentItem = ?(ShowOnlySelectedRoles, Items.Roles, Items.TableOfRoles);
	
EndProcedure

&AtClient
Procedure CheckAll(Command)
	
	MarkAllAtServer();
	
EndProcedure

&AtClient
Procedure UncheckAll(Command)
	
	UncheckAllAtServer();
	
EndProcedure


////////////////////////////////////////////////////////////////////////////////
// Auxiliary form procedures and functions
//

&AtServer
Function NeedToCreateFirstAdministrator()
	
	SetPrivilegedMode(True);
	
	If InfoBaseUsers.GetUsers().Count() = 0 Then
		//
		If UsersOverrided.RolesEditingProhibited()
		 OR Roles.FindRows(New Structure("Role", "FullAccess")).Count() = 0 Then
			//
			Return True;
		EndIf;
	EndIf;
	
	Return False;
	
EndFunction

&AtServer
Procedure DefineActionsInForm()
	
	ActionsInForm = New Structure;
	ActionsInForm.Insert("Roles",                   ""); // "", "View",     "Edit"
	ActionsInForm.Insert("IBUserProperties", 		""); // "", "ViewAll", 	"EditAll", "EditOfTheir"
	ActionsInForm.Insert("ItemProperties",       	""); // "", "View",     "Edit"
	
	If Users.CurrentUserHaveFullAccess() Then
		// Administrator
		ActionsInForm.Roles                   = "Edit";
		ActionsInForm.IBUserProperties 		  = "EditAll";
		ActionsInForm.ItemProperties       	  = "Edit";
		
	ElsIf ValueIsFilled(CommonUse.CurrentUser()) And
	          Object.Ref = CommonUse.CurrentUser() Then
		// Own properties
		ActionsInForm.Roles                   = "";
		ActionsInForm.IBUserProperties 		  = "EditOfTheir";
		ActionsInForm.ItemProperties      	  = "View";
	Else
		// Another's properties
		ActionsInForm.Roles                   = "";
		ActionsInForm.IBUserProperties 		  = "";
		ActionsInForm.ItemProperties       	  = "View";
	EndIf;
	
	UsersOverrided.ChangeActionsInForm(Object.Ref, ActionsInForm);
	
	// Check action names in the form
	If Find(", View, Edit,", ", " + ActionsInForm.Roles + ",") = 0 Then
		ActionsInForm.Roles = "";
	ElsIf UsersOverrided.RolesEditingProhibited() Then
		ActionsInForm.Roles = "View";
	EndIf;
	If Find(", ViewAll, EditAll, EditOfTheir,", ", " + ActionsInForm.IBUserProperties + ",") = 0 Then
		ActionsInForm.IBUserProperties = "";
	EndIf;
	If Find(", View, Edit,", ", " + ActionsInForm.ItemProperties + ",") = 0 Then
		ActionsInForm.ItemProperties = "";
	EndIf;
	
EndProcedure

//** Read, write, delete, calculate of IB user short name, check mismatch

&AtServer
Procedure ReadIBUser(OnItemCopy = False, OnlyRoles = False)
	
	SetPrivilegedMode(True);
	
	ReadRoles = Undefined;
	
	If OnlyRoles Then
		Users.ReadIBUser(Object.IBUserID, , ReadRoles);
		FillRolesServer(ReadRoles);
		Return;
	EndIf;
	
	Password              			= "";
	PasswordConfirmation 			= "";
	ReadProperties              	= Undefined;
	OldIBUserID 					= Undefined;
	IBUserExists          			= False;
	AccessToInformationBaseAllowed  = False;
	
	// Fill initial values of properties of IBuser for a user.
	Users.ReadIBUser(Undefined, ReadProperties, ReadRoles);
	ReadProperties.InfBaseUserShowInList = True;
	FillPropertyValues(ThisForm, ReadProperties);
	InfBaseUserStandardAuthentication = True;
	
	If OnItemCopy Then
		
		If Users.ReadIBUser(Parameters.CopyingValue.IBUserID, ReadProperties, ReadRoles) Then
			// Because cloned user is linked with IBuser,
			// then future link is set for a new user too.
			AccessToInformationBaseAllowed = True;
			// Because IBUser of the cloned user has been read,
			// then properties and roles of IBUser are copied.
			FillPropertyValues(ThisForm,
			                         ReadProperties,
			                         "InfBaseUserStandardAuthentication,
			                         |InfBaseUserProhibitedToChangePassword,
			                         |InfBaseUserShowInList,
			                         |InfBaseUserOSAuthentication");
		EndIf;
		Object.IBUserID = Undefined;
	Else
		If Users.ReadIBUser(Object.IBUserID, ReadProperties, ReadRoles) Then
		
			IBUserExists          = True;
			AccessToInformationBaseAllowed = True;
			OldIBUserID = Object.IBUserID;
			
			FillPropertyValues(ThisForm,
			                         ReadProperties,
			                         "InfBaseUserName,
			                         |InfBaseUserFullName,
			                         |InfBaseUserStandardAuthentication,
			                         |InfBaseUserShowInList,
			                         |InfBaseUserProhibitedToChangePassword,
			                         |InfBaseUserOSAuthentication,
			                         |InfBaseUserOSUser");
			
			If ReadProperties.InfBaseUserPasswordIsSet Then
				Password              = "**********";
				PasswordConfirmation = "**********";
			EndIf;
		EndIf;
	EndIf;
	
	FillPresentationStartupMode(ReadProperties.InfBaseUserRunMode);
	FillLanguagePresentation(ReadProperties.InfBaseUserLanguage);
	FillRolesServer(ReadRoles);
	
EndProcedure

&AtServer
Procedure WriteIBUser(CurrentObject, Cancellation)
	
	// Restore actions in form, if they were modified at client
	DefineActionsInForm();
	
	If NOT (ActionsInForm.IBUserProperties = "EditAll" OR
	         ActionsInForm.IBUserProperties = "EditOfTheir"    )Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	NewProperties = Undefined;
	NewRoles      = Undefined;
	
	// Read old properties/fill initial properties of IBUser for a user.
	Users.ReadIBUser(CurrentObject.IBUserID, NewProperties);
	
	If ActionsInForm.IBUserProperties = "EditAll" Then
		FillPropertyValues(NewProperties, ThisForm);
		NewProperties.InfBaseUserRunMode = GetSelectedRunMode();
	Else
		FillPropertyValues(NewProperties,
		                         ThisForm,
		                         "InfBaseUserName,
		                         |InfBaseUserPassword");
	EndIf;
	NewProperties.InfBaseUserLanguage = GetSelectedLanguage();
		
	If ActionsInForm.Roles = "Edit" Then
		NewRoles = Roles.Unload().UnloadColumn("Role");
	EndIf;
	
	// Trying to  write IB user
	ErrorDescription = "";
	If Users.WriteIBUser(CurrentObject.IBUserID, NewProperties, NewRoles, NOT IBUserExists, ErrorDescription) Then
		If NOT IBUserExists Then
			CurrentObject.IBUserID = NewProperties.InfBaseUserUUID;
			IBUserExists = True;
		EndIf;
	Else
		Cancellation = True;
		CommonUseClientServer.MessageToUser(ErrorDescription);
	EndIf;
	
EndProcedure

&AtServer
Function DeleteIBUsers(Cancellation)
	
	SetPrivilegedMode(True);
	
	ErrorDescription = "";
	If NOT Users.DeleteIBUsers(OldIBUserID, ErrorDescription) Then
		CommonUseClientServer.MessageToUser(ErrorDescription, , , , Cancellation);
	EndIf;
	
EndFunction

&AtClient
Function GetShortNameOfIBUser(Val FullName)
	
	ShortName = "";
	FirstCycleRun = True;
	
	While True Do
		If NOT FirstCycleRun Then
			ShortName = ShortName + Upper(Left(FullName, 1));
		EndIf;
		SpacePosition = Find(FullName, " ");
		If SpacePosition = 0 Then
			If FirstCycleRun Then
				ShortName = FullName;
			EndIf;
			Break;
		EndIf;
		
		If FirstCycleRun Then
			ShortName = Left(FullName, SpacePosition - 1);
		EndIf;
		
		FullName = Right(FullName, StrLen(FullName) - SpacePosition);
		
		FirstCycleRun = False;
	EndDo;
	
	ShortName = StrReplace(ShortName, " ", "");
	
	Return ShortName;
	
EndFunction

&AtServer
Procedure DefineUserInconsistenciesWithUserIB(WriteParameters = Undefined) Export
	
	//** Check match of the IBUser property "FullName" and the user property "Description"
	
	If NOT (ActionsInForm.ItemProperties       = "Edit" And
	         ActionsInForm.IBUserProperties = "EditAll") Then
		// Read user FullName cannot be modified, if it does not match
		InfBaseUserFullName = Undefined;
	EndIf;
	
	If NOT IBUserExists OR
	     InfBaseUserFullName = Undefined OR
	     InfBaseUserFullName = Object.Description Then
		
		Items.FullNameInconsistenceProcessing.Visible = False;
		
	ElsIf ValueIsFilled(Object.Ref) Then
	
		Items.FullNameInconsistenceExplanation.Title = StringFunctionsClientServer.SubstitureParametersInString(
				Items.FullNameInconsistenceExplanation.Title,
				InfBaseUserFullName);
	Else
		Object.Description = InfBaseUserFullName;
		Items.FullNameInconsistenceProcessing.Visible = False;
	EndIf;
	
	//** Determine if there is link with inexistent IB user
	IsNewLinkWithNonexistentIBUser = NOT IBUserExists And ValueIsFilled(Object.IBUserID);
	If WriteParameters <> Undefined
	   And IsLinkWithNonexistentIBUser
	   And NOT IsNewLinkWithNonexistentIBUser Then
		
		WriteParameters.Insert("ClearedLinkWithNotExistingIBUser", Object.Ref);
	EndIf;
	IsLinkWithNonexistentIBUser = IsNewLinkWithNonexistentIBUser;
	
	If ActionsInForm.IBUserProperties <> "EditAll" Then
		// Link cannot be changed
		Items.LinkInconsistenceProcessing.Visible = False;
	Else
		Items.LinkInconsistenceProcessing.Visible = IsLinkWithNonexistentIBUser;
	EndIf;
	
EndProcedure

//** Initial filling, check fill, properties accessibility

&AtServer
Procedure FillPresentationStartupMode(RunMode)
	
	If RunMode = "Auto" Then
		StartModePresentation = NStr("en = 'Auto'");
		
	ElsIf RunMode = "OrdinaryApplication" Then
		StartModePresentation = NStr("en = 'Ordinary application'");
		
	ElsIf RunMode = "ManagedApplication" Then
		StartModePresentation = NStr("en = 'Managed application'");
	Else
		StartModePresentation = "";
	EndIf;
	
EndProcedure

&AtServer
Function GetSelectedRunMode()
	
	If StartModePresentation = NStr("en = 'Auto'") Then
		Return "Auto";
		
	ElsIf StartModePresentation = NStr("en = 'Ordinary application'") Then
		Return "OrdinaryApplication";
		
	ElsIf StartModePresentation = NStr("en = 'Managed application'") Then
		Return "ManagedApplication";
		
	EndIf;
	
	Return "";
	
EndFunction

&AtServer
Procedure FillLanguagePresentation(Language)
	
	LanguagePresentation = "";
	
	For each LanguageMetadata IN Metadata.Languages Do
	
		If LanguageMetadata.Name = Language Then
			LanguagePresentation = LanguageMetadata.Synonym;
			Break;
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Function GetSelectedLanguage()
	
	For each LanguageMetadata IN Metadata.Languages Do
	
		If LanguageMetadata.Synonym = LanguagePresentation Then
			Return LanguageMetadata.Name;
		EndIf;
	EndDo;
	
	Return "";
	
EndFunction

&AtServer
Procedure FillRolesServer(ReadRoles)
	
	Roles.Clear();
	
	For each Role In ReadRoles Do
		NewRow = Roles.Add();
		NewRow.Role        = Role;
		NewRow.RoleSynonym = TableOfRoles.FindRows(New Structure("Name", Role))[0].Synonym;
	EndDo;
	
	Roles.Sort("RoleSynonym");
	
EndProcedure

&AtClient
Procedure SetAccessibilityOfProperties()
	
	Items.Description.ReadOnly                                 	= ActionsInForm.ItemProperties       <> "Edit";
	Items.AccessToInformationBaseAllowed.ReadOnly            	= ActionsInForm.IBUserProperties <> "EditAll";
	Items.IBUserProperties.ReadOnly                       		= ActionsInForm.IBUserProperties =  "ViewAll";
	Items.InfBaseUserStandardAuthentication.ReadOnly 			= ActionsInForm.IBUserProperties <> "EditAll";
	Items.Password.ReadOnly                                     = InfBaseUserProhibitedToChangePassword;
	Items.PasswordConfirmation.ReadOnly                         = InfBaseUserProhibitedToChangePassword;
	Items.InfBaseUserProhibitedToChangePassword.ReadOnly   		= ActionsInForm.IBUserProperties <> "EditAll";
	Items.InfBaseUserShowInList.ReadOnly   						= ActionsInForm.IBUserProperties <> "EditAll";
	Items.InfBaseUserOSAuthentication.ReadOnly          		= ActionsInForm.IBUserProperties <> "EditAll";
	Items.InfBaseUserOSUser.ReadOnly            				= ActionsInForm.IBUserProperties <> "EditAll";
	Items.StartModePresentation.ReadOnly                   		= ActionsInForm.IBUserProperties <> "EditAll";
	
	Items.MainProperties.Enabled                     			= AccessToInformationBaseAllowed;
	Items.RepresentationOfRoles.Enabled                     	= AccessToInformationBaseAllowed;
	Items.InfBaseUserName.AutoMarkIncomplete 					= AccessToInformationBaseAllowed;
	
	Items.Password.Enabled                                      = InfBaseUserStandardAuthentication;
	Items.PasswordConfirmation.Enabled                        	= InfBaseUserStandardAuthentication;
	Items.InfBaseUserProhibitedToChangePassword.Enabled 		= InfBaseUserStandardAuthentication;
	Items.InfBaseUserShowInList.Enabled 						= InfBaseUserStandardAuthentication;
	
	Items.InfBaseUserOSUser.Enabled 							= InfBaseUserOSAuthentication;
	
EndProcedure

//** For operation of the roles interface

&AtServer
Procedure SetActionsWithRoles()
	
	BanEdit = UsersOverrided.RolesEditingProhibited();
	
	// ** OnlySelectedRoles
	// Main menu
	Items.RolesFill.Visible                       = NOT BanEdit;
	Items.RolesAdd.Visible                        = NOT BanEdit;
	Items.RolesDelete.Visible                     = NOT BanEdit;
	Items.RolesMoveUp.Visible                	  = NOT BanEdit;
	Items.RolesMoveDown.Visible                   = NOT BanEdit;
	Items.RolesSortListAsc.Visible  			  = NOT BanEdit;
	Items.RolesSortListDesc.Visible    		 	  = NOT BanEdit;
	// Context menu
	Items.ContextMenuRolesFill.Visible        	  = NOT BanEdit;
	Items.ContextMenuRolesAdd.Visible         	  = NOT BanEdit;
	Items.ContextMenuRolesDelete.Visible          = NOT BanEdit;
	Items.ContextMenuRolesMoveUp.Visible 		  = NOT BanEdit;
	Items.ContextMenuRolesMoveDown.Visible  	  = NOT BanEdit;
	
	// ** AmongAllSelectedRoles
	// Main menu
	Items.TableOfRolesCheckAll.Visible            = NOT BanEdit;
	Items.TableOfRolesUncheckAll.Visible          = NOT BanEdit;
	Items.TableOfRolesSortListAsc.Visible 		  = NOT BanEdit;
	Items.TableOfRolesSortListDesc.Visible    	  = NOT BanEdit;
	
EndProcedure

&AtServer
Procedure MarkAllAtServer()
	
	For each TableRow In TableOfRoles Do
		
		TableRow.Check = True;
		
		RolesFound = Roles.FindRows(New Structure("Role", TableRow.Name));
		If RolesFound.Count() = 0 Then
			String = Roles.Add();
			String.Role = TableRow.Name;
			String.RoleSynonym = TableRow.Synonym;
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure UncheckAllAtServer()
	
	For each TableRow In TableOfRoles Do
		
		TableRow.Check = False;
		
		RolesFound = Roles.FindRows(New Structure("Role", TableRow.Name));
		If RolesFound.Count() > 0 Then
			Roles.Delete(RolesFound[0]);
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure AddSelectedRoles(SelectedRoles)
	
	For each Value In SelectedRoles Do
	
		ItemOfList = ChoiceListOfRoles.FindByValue(Value);
		If ItemOfList <> Undefined Then
			
			If Roles.FindRows(New Structure("Role", Value)).Count() = 0 Then
				
				String = Roles.Add();
				String.Role        = ItemOfList.Value;
				String.RoleSynonym = ItemOfList.Presentation;
			EndIf;
		EndIf;
	EndDo;
	
	MarkRolesByList();
	
EndProcedure

&AtServer
Procedure PrepareChoiceListAndTableOfRoles()
	
	AllRoles = UsersServerSecondUse.AllRoles();
	AllRoles.Sort("Synonym");
	
	For each String In AllRoles Do
		// Fill choice list
		ChoiceListOfRoles.Add(String.Name, String.Synonym);
		// Fill table of roles
		TableRow = TableOfRoles.Add();
		FillPropertyValues(TableRow, String);
	EndDo;
	
EndProcedure

&AtServer
Procedure SetReadOnlyOfRoles(Val ReadOnlyOfRoles)
	
	Items.Roles.ReadOnly         = ReadOnlyOfRoles;
	Items.TableOfRoles.ReadOnly  = ReadOnlyOfRoles;
	
	Items.RolesFill.Enabled                	= NOT ReadOnlyOfRoles;
	Items.ContextMenuRolesFill.Enabled 		= NOT ReadOnlyOfRoles;
	Items.TableOfRolesCheckAll.Enabled 		= NOT ReadOnlyOfRoles;
	Items.TableOfRolesUncheckAll.Enabled    = NOT ReadOnlyOfRoles;
	
EndProcedure

&AtServer
Procedure MarkRolesByList()
	
	For each TableRow In TableOfRoles Do
		
		TableRow.Check = Roles.FindRows(New Structure("Role", TableRow.Name)).Count() > 0;
		
	EndDo;
	
EndProcedure

&AtClient
Function GenerateRolesChoiceData(Text)
	
	List = ChoiceListOfRoles.Copy();
	
	ItemNumber = List.Count()-1;
	While ItemNumber >= 0 Do
		If Upper(Left(List[ItemNumber].Presentation, StrLen(Text))) <> Upper(Text) Then
			List.Delete(ItemNumber);
		EndIf;
		ItemNumber = ItemNumber - 1;
	EndDo;
	
	Return List;
	
EndFunction

&AtServer
Procedure FillCheckProcessingOfRoleList(Cancellation)
	
	// Check unfilled and duplicated roles.
	LineNumber = Roles.Count()-1;
	While NOT Cancellation And LineNumber >= 0 Do
	
		CurrentRow = Roles.Get(LineNumber);
		
		// Check that value is filled.
		If NOT ValueIsFilled(CurrentRow.RoleSynonym) Then
			CommonUseClientServer.MessageToUser(NStr("en = 'Role not filled!'"),
			                                                  ,
			                                                  "Roles[" + Format(LineNumber, "NG=0") + "].RoleSynonym",
			                                                  ,
			                                                  Cancellation);
			Return;
		EndIf;
		
		// Check duplicated values.
		ValuesFound = Roles.FindRows(New Structure("Role", CurrentRow.Role));
		If ValuesFound.Count() > 1 Then
			CommonUseClientServer.MessageToUser( NStr("en = 'Role repeats!'"),
			                                                  ,
			                                                  "Roles[" + Format(LineNumber, "NG=0") + "].RoleSynonym",
			                                                  ,
			                                                  Cancellation);
			Return;
		EndIf;
			
		LineNumber = LineNumber - 1;
	EndDo;
	
EndProcedure

