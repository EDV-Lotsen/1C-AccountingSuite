
// Function AuthorizedUser returns
// session current user.
//
// Value returned:
//  CatalogRef.Users
//
Function AuthorizedUser() Export
	
	SetPrivilegedMode(True);
	
	Return SessionParameters.CurrentUser;
	
EndFunction

// Function CurrentUserHaveFullAccess checks,
// if IB current user has full rights or
// IB user of the current user.
//
//  Full Access user is:
// a) IB user if IB user list is empty,
//    if main role is not specified or FullAccess,
// b) user IB with role FullAccess.
//
//
// Parameters:
//  User - Undefined (check IB current user),
//                  Catalog.Users
//                  (search IB user by UUID,
//                  specified in the attribute IBUserID,
//                  if IB user is not found, False is returned).
//
// Value returned:
//  Boolean.
//
Function CurrentUserHaveFullAccess(User = Undefined) Export
	
	SetPrivilegedMode(True);
	
	If ValueIsFilled(User) And User <> AuthorizedUser() Then
		IBUser = InfobaseUsers.FindByUUID(CommonUse.GetAttributeValue(User, "IBUserID"));
		If IBUser = Undefined Then
			Return False;
		EndIf;
	Else
		IBUser = InfobaseUsers.CurrentUser();
	EndIf;
	
	If IBUser.UUID = InfobaseUsers.CurrentUser().UUID Then
		
		If ValueIsFilled(IBUser.Name) Then
			
			Return IsInRole("FullAccess") OR InfobaseUsers.FindByUUID(InfobaseUsers.CurrentUser().UUID).Roles.Contains(Metadata.Roles.FullAccess);
		Else
			// Empty user has been authorized - user list is empty,
			// if main role is empty - all rights are allowed.
			If Metadata.DefaultRole = Undefined OR
			   Metadata.DefaultRole = Metadata.Roles.FullAccess Then
				
				Return True;
			Else
				Return False;
			EndIf;
		EndIf;
	Else
		Return IBUser.Roles.Contains(Metadata.Roles.FullAccess);
	EndIf;
	
EndFunction

// Function FullNameOfNotSpecifiedUser returns
// presentation of unspecified user, i.e. when
// user list is empty.
//
// Value returned:
//  String.
//
Function FullNameOfNotSpecifiedUser() Export
	
	Return NStr("en = '<Not specified>'");
	
EndFunction

// Function CreateFirstAdministrator is used
// on update and initial filling of the infobase
//  When using subsystem AccessManagement
// first administrator will be automatically included
// in access group Administrators (if action is added-in)
//
// Parameters:
//  UserAccount - InfobaseUser - is used
//                  when first administrator should be created replacing already existing
//                  IB user (see function Users.AuthorizationError())
//
Procedure CreateFirstAdministrator(UserAccount = Undefined) Export
	
	// Insert administrator (system administrator - full rights).
	
	If UserAccount = Undefined Then
		UserAccount = InfobaseUsers.FindByName("Administrator");
		If UserAccount = Undefined Then
			UserAccount = InfobaseUsers.CreateUser();
		EndIf;
	EndIf;
	UserAccount.Name        = "Administrator";
	UserAccount.FullName 	= UserAccount.Name;
	UserAccount.Roles.Clear();
	UserAccount.Roles.Add(Metadata.Roles.FullAccess);
	UserAccount.Write();
	
	If UserByIDExists(UserAccount.UUID) Then
		User = Catalogs.Users.FindByAttribute("IBUserID", UserAccount.UUID);
	EndIf;
	
	If NOT ValueIsFilled(User) Then
		User = Catalogs.Users.FindByDescription(UserAccount.Name);
		If ValueIsFilled(User)
		   And ValueIsFilled(User.IBUserID)
		   And User.IBUserID <> UserAccount.UUID
		   And InfobaseUsers.FindByUUID(User.IBUserID) <> Undefined Then
			User = Undefined;
		EndIf;
	EndIf;
	
	If NOT ValueIsFilled(User) Then
		User = Catalogs.Users.CreateItem();
	Else
		User = User.GetObject();
	EndIf;
	User.IBUserID = UserAccount.UUID;
	User.Description = UserAccount.FullName;
	User.Write();
	
	UsersOverrided.OnWriteOfFirstAdministrator(User.Ref);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Interface procedures and functions

// Function GenerateUserChoiceData returns list
// of users not marked for deletion.
//  Used in event handlers TextEditEnd and AutoComplete.
//
// Parameters:
//  Text        	- String, chars entered by user.
//  IncludingGroups - Boolean, if True, include user groups (not used).
//  IncludingExternalUsers - Undefined, False, True (not used).
//  WithoutUsers	- Boolean, if True, then items of the catalog Users being excluded from the result.
//
Function GenerateUserChoiceData(Val Text, Val IncludingGroups = True, Val IncludingExternalUsers = Undefined, WithoutUsers = False) Export
	
	Query = New Query;
	Query.SetParameter("Text", Text + "%");
	Query.SetParameter("EmptyUUID", New UUID("00000000-0000-0000-0000-000000000000"));
	Query.Text = 
	"SELECT ALLOWED
	|	VALUE(Catalog.Users.EmptyRef) AS Ref,
	|	"""" AS Description,
	|	-1 AS PictureNo
	|WHERE
	|	FALSE";
	
	If NOT WithoutUsers Then
		Query.Text = Query.Text + " UNION ALL " +
		"SELECT
		|	Users.Ref,
		|	Users.Description,
		|	CASE
		|		WHEN Users.IBUserID = &EmptyUUID
		|			THEN 4
		|		ELSE 1
		|	END AS PictureNo
		|FROM
		|	Catalog.Users AS Users
		|WHERE
		|	(NOT Users.DeletionMark)
		|	AND Users.Description LIKE &Text";
	EndIf;
	
	ChoiceData = New ValueList;
	Selection  = Query.Execute().Choose();
	While Selection.Next() Do
	
		ChoiceData.Add(Selection.Ref, Selection.Description, , PictureLib["UserIcons" + Format(Selection.PictureNo + 1, "ND1=2; NLZ=; NG=")]);
	EndDo;
	
	Return ChoiceData;
	
EndFunction

// Procedure FillUserPictureNumbers fills picture numbers of users.
//
// Parameters:
//  Table       	- FormDataCollection.
//  FieldNameUser 	- String, field name containing ref to a user.
//  ImageNumberFieldName - String, field name, containing image number, that should be assigned.
//  RowID  			- Undefined, Number, row ID (not sequence number),
//                    when Undefined, fill images for all table rows.
//
Procedure FillUserPictureNumbers(Table, FieldNameUser, ImageNumberFieldName, RowID = Undefined) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query(StrReplace(
	"SELECT DISTINCT
	|	Users.#FieldNameUser AS User
	|INTO Users
	|FROM
	|	&Users AS Users
	|;
	|
	|SELECT
	|	Users.User,
	|	CASE
	|		WHEN Users.User = Undefined
	|			THEN -1
	|		WHEN VALUETYPE(Users.User) = TYPE(Catalog.Users)
	|			THEN CASE
	|					WHEN Users.User.DeletionMark
	|						THEN 0
	|					ELSE CASE
	|							WHEN Users.User.IBUserID = &EmptyUUID
	|								THEN 4
	|							ELSE 1
	|						END
	|				END
	|		ELSE -2
	|	END AS PictureNo
	|FROM
	|	Users AS Users", "#FieldNameUser", FieldNameUser));
	Query.SetParameter("EmptyUUID", New UUID("00000000-0000-0000-0000-000000000000"));
	
	If RowID = Undefined Then
		
		Query.SetParameter("Users", Table.Unload(, FieldNameUser));
		PictureNumbers = Query.Execute().Unload();
		
		For each String In Table Do
			String[ImageNumberFieldName] = PictureNumbers.Find(String[FieldNameUser], "User").PictureNo;
		EndDo;
	Else
		String 			= Table.FindByID(RowID);
		RowsArray	 	= New Array;
		RowsArray.Add(String);
		Query.SetParameter("Users", Table.Unload(RowsArray, FieldNameUser));
		PictureNumbers 	= Query.Execute().Unload();
		
		String[ImageNumberFieldName] = PictureNumbers.Find(String[FieldNameUser], "User").PictureNo;
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Procedures of the subsystems for internal needs

// Function ReadIBUser reads properties of infobase user
// using string or unique identifier.
//
// Parameters:
//  Id - Undefined, String, UUID (user id).
//  Properties     - Structure:
//                 InfBaseUserUUID   					 - UUID
//                 InfBaseUserName                       - String
//                 InfBaseUserFullName                	 - String
//
//                 InfBaseUserStandardAuthentication 	 - Boolean
//                 InfBaseUserShowInList   				 - Boolean
//                 InfBaseUserPassword                   - Undefined
//                 InfBaseUserStoredPasswordValue 		 - String
//                 InfBaseUserPasswordIsSet          	 - Boolean
//                 InfBaseUserProhibitedToChangePassword - Boolean
//
//                 InfBaseUserOSAuthentication         	 - Boolean
//                 InfBaseUserOSUser            		 - String
//
//                 InfBaseUserDefaultInterface         	 - String (interface name from collection Metadata.Interfaces)
//                 InfBaseUserRunMode              		 - String (values: "Auto", "OrdinaryApplication", "ManagedApplication")
//                 InfBaseUserLanguage                   - String (language name from collection Metadata.Languages)
//
//  Roles          		 	- Array of values of type String (role names from collection Metadata.Roles)
//
//  ErrorDescription 		- String, contains error description, if read failed.
//
// Value returned:
//  Boolean,
//  if True 				- success, else cancellation, see ErrorDescription.
//
Function ReadIBUser(Val Id, Properties = Undefined, Roles = Undefined, ErrorDescription = "", IBUser = Undefined) Export
	
	// Prepare structures of returned data
	Properties = New Structure;
	Properties.Insert("InfBaseUserUUID",  					 	New UUID);
	Properties.Insert("InfBaseUserName",                      	"");
	Properties.Insert("InfBaseUserFullName",                 	"");
	Properties.Insert("InfBaseUserStandardAuthentication", 		False);
	Properties.Insert("InfBaseUserShowInList",   				False);
	Properties.Insert("InfBaseUserPassword",                    Undefined);
	Properties.Insert("InfBaseUserStoredPasswordValue", 		"");
	Properties.Insert("InfBaseUserPasswordIsSet",          		False);
	Properties.Insert("InfBaseUserProhibitedToChangePassword",  False);
	Properties.Insert("InfBaseUserOSAuthentication",          	False);
	Properties.Insert("InfBaseUserOSUser",                      "");
	Properties.Insert("InfBaseUserDefaultInterface",            ?(Metadata.DefaultInterface = Undefined, "", Metadata.DefaultInterface.Name));
	Properties.Insert("InfBaseUserRunMode",                     "Auto");
	Properties.Insert("InfBaseUserLanguage",                    ?(Metadata.DefaultLanguage = Undefined, "", Metadata.DefaultLanguage.Name));
	
	Roles = New Array;
	
	If TypeOf(Id) = Type("UUID") Then
		IBUser = InfobaseUsers.FindByUUID(Id);
	ElsIf TypeOf(Id) = Type("String") Then
		IBUser = InfobaseUsers.FindByName(Id);
	Else
		IBUser = Undefined;
	EndIf;
	
	If IBUser = Undefined Then
		ErrorDescription = StrReplace(NStr(""), "%1", Id);
		Return False;
	EndIf;
	
	Properties.InfBaseUserUUID     						= IBUser.UUID;
	Properties.InfBaseUserName                          = IBUser.Name;
	Properties.InfBaseUserFullName                   	= IBUser.FullName;
	Properties.InfBaseUserStandardAuthentication   		= IBUser.StandardAuthentication;
	Properties.InfBaseUserShowInList     				= IBUser.ShowInList;
	Properties.InfBaseUserStoredPasswordValue   		= IBUser.StoredPasswordValue;
	Properties.InfBaseUserPasswordIsSet            		= IBUser.PasswordIsSet;
	Properties.InfBaseUserProhibitedToChangePassword    = IBUser.CannotChangePassword;
	Properties.InfBaseUserOSAuthentication            	= IBUser.OSAuthentication;
	Properties.InfBaseUserOSUser              			= IBUser.OSUser;
	Properties.InfBaseUserDefaultInterface           	= ?(IBUser.DefaultInterface = Undefined, "", IBUser.DefaultInterface.Name);
	Properties.InfBaseUserRunMode                		= ?(IBUser.RunMode = ClientRunMode.OrdinaryApplication,
	                                                            "OrdinaryApplication",
	                                                            ?(IBUser.RunMode = ClientRunMode.ManagedApplication,
	                                                              "ManagedApplication",
	                                                              "Auto"));
	Properties.InfBaseUserLanguage                      = ?(IBUser.Language = Undefined, "", IBUser.Language.Name);
	
	For each Role In IBUser.Roles Do
		Roles.Add(Role.Name);
	EndDo;
	
	Return True;
	
EndFunction

// Function WriteIBUser
// or overwrites properties of the IBUser,
//      found by string or unique id,
// or creates new IBUser, when 'create' is specified,
//      if iBUser is found - it is an error
//
// Parameters:
//  Id - String, UUID (user id).
//  NewProperties - Structure (property may not be specified,
//                            then read or initial value being used)
//                 InfBaseUserUUID   			- Undefined (assigned after writing IB user)
//                 InfBaseUserName              - Undefined, String
//                 InfBaseUserFullName          - Undefined, String
//
//                 InfBaseUserStandardAuthentication 		- Undefined, Boolean
//                 InfBaseUserShowInList   					- Undefined, Boolean
//                 InfBaseUserPassword                  	- Undefined, String
//                 InfBaseUserStoredPasswordValue 			- Undefined, String
//                 InfBaseUserPasswordIsSet          		- Undefined, Boolean
//                 InfBaseUserProhibitedToChangePassword    - Undefined, Boolean
//
//                 InfBaseUserOSAuthentication          	- Undefined, Boolean
//                 InfBaseUserOSUser            			- Undefined, String
//
//                 InfBaseUserDefaultInterface         		- Undefined, String (interface name from collection Metadata.Interfaces)
//                 InfBaseUserRunMode              			- Undefined, String (values: "Auto", "OrdinaryApplication", "ManagedApplication"
//                 InfBaseUserLanguage                      - Undefined, String (language name from collection Metadata.Languages)
//
//  NewRoles      		- Undefined, Array of values of type String (role names from collection Metadata.Roles)
//
//  ErrorDescription 	- String, contains error description, if read failed.
//
// Value returned:
//  Boolean,
//  if True		 		- success, else cancellation, see ErrorDescription.
//
Function WriteIBUser(Val Id, Val NewProperties, Val NewRoles, Val CreateNew = False, ErrorDescription = "") Export
	
	IBUser 			= Undefined;
	OldProperties 	= Undefined;
	OldRoles     	= Undefined;
	Properties      = Undefined;
	Roles           = Undefined;
	
	PreliminaryRead = ReadIBUser(Id, OldProperties, OldRoles, ErrorDescription);
	
	If NOT ReadIBUser(Id, Properties, Roles, ErrorDescription, IBUser) OR NOT PreliminaryRead Then
		
		If CreateNew Then
			IBUser = InfobaseUsers.CreateUser();
		Else
			Return False;
		EndIf;
	ElsIf CreateNew Then
		ErrorDescription = StrReplace(NStr("en = 'It is impossible to create user of the Information base ""%1"", user already exists!'"), "%1", Id);
		Return False;
	EndIf;
	
	// Prepare new values of properties
	For each KeyAndValue In Properties Do
		If NewProperties.Property(KeyAndValue.Key) And NewProperties[KeyAndValue.Key] <> Undefined Then
			Properties[KeyAndValue.Key] = NewProperties[KeyAndValue.Key];
		EndIf;
	EndDo;
	
	If NewRoles <> Undefined Then
		Roles = NewRoles;
	EndIf;
	
	// Assign new values of properties
	
	IBUser.Name                         	= Properties.InfBaseUserName;
	IBUser.FullName                   		= Properties.InfBaseUserFullName;
	IBUser.StandardAuthentication   		= Properties.InfBaseUserStandardAuthentication;
	IBUser.ShowInList     					= Properties.InfBaseUserShowInList;
	If Properties.InfBaseUserPassword <> Undefined Then
		IBUser.Password                  = Properties.InfBaseUserPassword;
	EndIf;
	IBUser.CannotChangePassword     = Properties.InfBaseUserProhibitedToChangePassword;
	IBUser.OSAuthentication         = Properties.InfBaseUserOSAuthentication;
	IBUser.OSUser             	 	= Properties.InfBaseUserOSUser;
	If ValueIsFilled(Properties.InfBaseUserDefaultInterface) Then
	    IBUser.DefaultInterface     = Metadata.Interfaces[Properties.InfBaseUserDefaultInterface];
	Else
	    IBUser.DefaultInterface     = Undefined;
	EndIf;
	If ValueIsFilled(Properties.InfBaseUserRunMode) Then
	    IBUser.RunMode            	= ClientRunMode[Properties.InfBaseUserRunMode];
	EndIf;
	If ValueIsFilled(Properties.InfBaseUserLanguage) Then
	    IBUser.Language             = Metadata.Languages[Properties.InfBaseUserLanguage];
	Else
	    IBUser.Language             = Undefined;
	EndIf;
	
	IBUser.Roles.Clear();
	For each Role In Roles Do
		IBUser.Roles.Add(Metadata.Roles[Role]);
	EndDo;
	
	// Add role FullAccess, on the attempt to create first user with empty role set
	If InfobaseUsers.GetUsers().Count() = 0 And
	     NOT IBUser.Roles.Contains(Metadata.Roles.FullAccess) Then
		
		IBUser.Roles.Add(Metadata.Roles.FullAccess);
	EndIf;
	
	// Try to write new or modified IBUser
	Try
		IBUser.Write();
	Except
		ErrorInfo = ErrorInfo();
		If ErrorInfo.Cause = Undefined Then
			ErrorDescription = ErrorInfo.Description;
		Else
			ErrorDescription = ErrorInfo.Cause.Description;
		EndIf;
		ErrorDescription = NStr("en = 'Error while recording user of the information base'") + Chars.LF + ErrorDescription;
		Return False;
	EndTry;
	
	NewProperties.InfBaseUserUUID = IBUser.UUID;
	
	UsersOverrided.OnWriteOfInformationBaseUser(OldProperties, Properties);
	
	Return True;
	
EndFunction

// Function deletes infobase user
// using string or unique id.
//
// Parameters:
//  ErrorDescription - String, contains error description, if read failed.
//
// Value returned:
//  Boolean,
//  if True - success, else cancellation, see ErrorDescription.
//
Function DeleteIBUsers(Val Id, ErrorDescription = "") Export
	
	IBUser 		= Undefined;
	Properties  = Undefined;
	Roles       = Undefined;
	
	If NOT ReadIBUser(Id, Properties, Roles, ErrorDescription, IBUser) Then
		Return False;
	Else
		Try
			IBUser.Delete();
		Except
			ErrorDescription = NStr("en = 'Error occurred while deleting information base user'") + Chars.LF + ErrorInfo().Cause.Details;
			Return False;
		EndTry;
	EndIf;
	
	UsersOverrided.AfterInfobaseUserDelete(Properties);
	
	Return True;
	
EndFunction

// Function checks existence of the infobase user
// Parameters
// Id - UUID, String
//                 UID of IBUser or IBUser name
//
// Value returned:
//  Boolean
//
Function IBUserExists(Val Id) Export
	
	SetPrivilegedMode(True);
	
	If TypeOf(Id) = Type("UUID") Then
		IBUser = InfobaseUsers.FindByUUID(Id);
	Else
		IBUser = InfobaseUsers.FindByName(Id);
	EndIf;
	
	If IBUser = Undefined Then
		Return False;
	Else
		Return True;
	EndIf;
	
EndFunction

// Procedure, determines user, under whom session is running and tries
// to find correspondence in catalog Users. If correspondence
// was not found - new item is being created. SessionNumber parameter CurrentUser
// is being assigned as a ref to the found (created) catalog item.
//
Procedure DefineCurrentUser(Val ParameterName, InitializedParameters) Export
	
	SetPrivilegedMode(True);
	
	If ParameterName <> "CurrentUser" Then
		Return;
	EndIf;
	
	UserNotFound = False;
	CreateUser   = False;
	
	If IsBlankString(InfobaseUsers.CurrentUser().Name) Then
		
		If CurrentUserHaveFullAccess() Then
			
			UserName     = FullNameOfNotSpecifiedUser();
			UserFullName = FullNameOfNotSpecifiedUser();
			
			Query = New Query;
			Query.Text = "SELECT TOP 1
			             |	Users.Ref AS Ref
			             |FROM
			             |	Catalog.Users AS Users
			             |WHERE
			             |	Users.Description = &UserFullName";
			
			Query.Parameters.Insert("UserFullName", UserFullName);
			
			Result = Query.Execute();
			
			If Result.IsEmpty() Then
				UserNotFound = True;
				CreateUser   = True;
				IBUserID  	 = "";
			Else
				Selection 					  = Result.Choose();
				Selection.Next();
				SessionParameters.CurrentUser = Selection.Ref;
			EndIf;
		Else
			UserNotFound = True;
		EndIf;
	Else
		IBUserID = InfobaseUsers.CurrentUser().UUID;
		
		Query = New Query;
		Query.Parameters.Insert("IBUserID ", IBUserID);
		
		Query.Text =
		"SELECT TOP 1
		|	Users.Ref AS Ref
		|FROM
		|	Catalog.Users AS Users
		|WHERE
		|	Users.IBUserID = &IBUserID";
		ResultUsers = Query.Execute();
		
		If ResultUsers.IsEmpty() Then
			If CurrentUserHaveFullAccess() Then
				
				CurrentUser         = InfobaseUsers.CurrentUser();
				UserName            = CurrentUser.Name;
				UserFullName        = CurrentUser.FullName;
				IBUserID 			= CurrentUser.UUID;
				UserByDescription   = UserRefByFullDescription(UserFullName);
				
				If UserByDescription = Undefined Then
					UserNotFound	 = True;
					CreateUser  	 = True;
				Else
					SessionParameters.CurrentUser = UserByDescription;
				EndIf;
			Else
				UserNotFound = True;
			EndIf;
		Else
			Selection = ResultUsers.Choose();
			Selection.Next();
			SessionParameters.CurrentUser = Selection.Ref;
		EndIf;
	EndIf;
	
	If CreateUser Then
		RefOfNew 						= Catalogs.Users.GetRef();
		SessionParameters.CurrentUser 	= RefOfNew;
		
		NewUser 		 = Catalogs.Users.CreateItem();
		NewUser.IBUserID = IBUserID;
		NewUser.Description                = UserFullName;
		NewUser.SetNewObjectRef(RefOfNew);
		
		Try
			NewUser.Write();
		Except
			ErrorMessageText = StringFunctionsClientServer.SubstitureParametersInString(
			                           NStr("en = 'Authorization failed.""User: %1 not found in ""Users Catalog"".
                                             |Contact system administrator.
                                             |Error occurred while adding user to catalog %2'"),
			                           UserName,
			                           BriefErrorDescription(ErrorInfo()) );
			Raise ErrorMessageText;
		EndTry;
	
	ElsIf UserNotFound Then
		Raise MessageTextUserNotFoundInCatalog(UserName);
	EndIf;
	
	InitializedParameters.Add(ParameterName);
	
EndProcedure

Function UserByIDExists(UUID, RefToCurrent = Undefined) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text = "SELECT
	             |	TRUE AS ValueTrue
	             |FROM
	             |	Catalog.Users AS Users
	             |WHERE
	             |	Users.IBUserID = &UUID
	             |	AND Users.Ref <> &RefToCurrent";
	Query.SetParameter("RefToCurrent", RefToCurrent);
	Query.SetParameter("UUID", UUID);
	
	Return NOT Query.Execute().IsEmpty();
	
EndFunction

Function IBUserNotLocked(Val UserName) Export
	
	SetPrivilegedMode(True);
	
	IBUser = InfobaseUsers.FindByName(UserName);
	
	If IBUser = Undefined Then
		Return True;
	EndIf;
	
	If UserByIDExists(IBUser.UUID) Then
		Return False;
	Else
		Return True;
	EndIf
	
EndFunction

// Procedure is called on system start
// to check if authorization can be performed
// and call filling of values of session parameter
// CurrentUser
//
Function AuthorizationError() Export
	
	SetPrivilegedMode(True);
	
	If IsBlankString(InfobaseUsers.CurrentUser().Name)
	 OR UserByIDExists(InfobaseUsers.CurrentUser().UUID) Then
		// User by default is authorizing
		// or IBUser was not founr in the catalog
		Return "";
	EndIf;
	
	// Need to, either create first administrator, or show message about authorization abort
	
	ErrorMessageText = "";
	NeedToCreateFirstAdministrator = False;
	
	IBUsers = InfobaseUsers.GetUsers();
	If IBUsers.Count() = 1 Then
		NeedToCreateFirstAdministrator = True;
		
	ElsIf Not AccessRight("Administration", Metadata, InfobaseUsers.CurrentUser()) Then
		// Normal user, created in designer, is authorizing
		ErrorMessageText = MessageTextUserNotFoundInCatalog(InfobaseUsers.CurrentUser().Name);
	Else
		// Additional administrator, created in designer, is authorizing
		WorkingAdministrator = Undefined;
		For each IBUser In IBUsers Do
			If AccessRight("Administration", Metadata, IBUser)
			   And UserByIDExists(IBUser.UUID) Then
				
				WorkingAdministrator = IBUser;
				Break;
			EndIf;
		EndDo;
		
		If WorkingAdministrator = Undefined Then
			// Need to create/restore the administrator
			NeedToCreateFirstAdministrator = True;
		Else
			ErrorMessageText = AdministratorMessageTextIsNotFoundInCatalog(InfobaseUsers.CurrentUser().Name, WorkingAdministrator.Name)
		EndIf;
	EndIf;
	
	If NeedToCreateFirstAdministrator Then
		ErrorMessageText = NStr("en = 'New Information Base user with administrative rights created in the configurator has been detected:
                                 |- User Full Rights has been set 
                                 |- User renamed as Administrator 
                                 |- User has been recorded in the catalog Users 
                                 |It is recommended to create Users of the information base in the 1C:Enterprise mode.
                                 |System will now shut down. Please restart 1C:Enterprise.'");
		                                    
	CreateFirstAdministrator(InfobaseUsers.CurrentUser());
	UsersOverrided.WarningTextAfterWriteOfFirstAdministrator(ErrorMessageText);
		
	ElsIf NOT ValueIsFilled(ErrorMessageText) Then
		Try
			AuthorizedUser();
		Except
			ErrorMessageText = ErrorMessageText + Chars.LF + Chars.LF + BriefErrorDescription(ErrorInfo());
		EndTry;
	EndIf;
	
	Return ErrorMessageText;
	
EndFunction

Function MessageTextUserNotFoundInCatalog(UserName)
	
	ErrorMessageText = NStr("en = 'Authorization failed. The system will now shut down.
                             |User ""%1"" not found in ""Users"" catalog.
                             |Contact system administrator.'");
	
	ErrorMessageText = StringFunctionsClientServer.SubstitureParametersInString(ErrorMessageText, UserName);
	
	Return ErrorMessageText;
	
EndFunction

Function AdministratorMessageTextIsNotFoundInCatalog(AdministratorName, WorkingAdministratorName)
	
	ErrorMessageText = NStr("en = 'Authorization failed. The system will now shut down.
                             |Administrator ""%1"" not found in ""Users"" catalog.
                             |Infobase users should be created in the 1C:Enterprise mode.
                             |Contact administrator ""%2"".'");
	
	ErrorMessageText = StringFunctionsClientServer.SubstitureParametersInString(ErrorMessageText, AdministratorName, WorkingAdministratorName);
	
	Return ErrorMessageText;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Procedures-handlers updating subsystem data

Function UserRefByFullDescription(FullName)
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text = "SELECT
	             |	Users.Ref AS Ref
	             |FROM
	             |	Catalog.Users AS Users
	             |WHERE
	             |	Users.Description = &FullName";
	Query.SetParameter("FullName", FullName);
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Return Undefined;
	EndIf;
	
	Selection = QueryResult.Choose();
	Selection.Next();
	
	User = Selection.Ref;
	
	If IBUserNotLocked(User.IBUserID) Then
		Return User;
	EndIf;
	
	Return Undefined;
	
EndFunction

// Procedure is called on configuration update to the version 1.0.5.2
// Tries to correspond / fill attribute "IBUserID"
// for each item of catalog Users.
//
Procedure FillUserIDs() Export
	
	SetPrivilegedMode(True);
	
	ListOfUsers = Catalogs.Users.Select();
	
	IBUsers = InfobaseUsers.GetUsers();
	
	While ListOfUsers.Next() Do
		User = ListOfUsers.Ref;
		If Not ValueIsFilled(User.IBUserID)
			And Lower(TrimAll(User.Description)) <> Lower(FullNameOfNotSpecifiedUser()) Then
			UserFullName = TrimAll(User.Description);
			For Each IBUser In IBUsers Do
				If UserFullName = TrimAll(Left(IBUser.FullName, Metadata.Catalogs.Users.DescriptionLength))
				   And Not UserByIDExists(IBUser.UUID) Then
					ObjectUser = User.GetObject();
					ObjectUser.IBUserID = IBUser.UUID;
					ObjectUser.Write();
					Continue;
				EndIf;
			EndDo;
		EndIf;
	EndDo;
	
EndProcedure
