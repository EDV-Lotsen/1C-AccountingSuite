
// Function RolesEditingProhibited is used for
// the control of the subsystems Users,
// when it is required to switch in the mode of IB users role autoassignement,
// for example, when adding-in the subsystems AccessManagement.
//
// Value returned:
//  Boolean.
//
Function RolesEditingProhibited() Export
	
	Return False;
	
EndFunction

// Procedure ChangeActionsInForm allows to override
// behaviour of the user forms
// when this is required, for example, when embedding the subsystem "Access management".
//
// Parameters:
//  Ref - CatalogRef.Users,
//           ref to a user
//           on form creation.
//
//  ActionsInForm - Structure (with the properties of String type):
//           Roles                   = "", "View",     "Edit"
//           ContactInformation   	 = "", "View",     "Edit"
//           IBUserProperties 		 = "", "ViewAll",  "EditAll", EditOfTheir"
//           ItemProperties      	 = "", "View",     "Edit"
//
Procedure ChangeActionsInForm(Val Ref = Undefined, Val ActionsInForm) Export
	
EndProcedure

// Handler of event OnWrite of infobase user
// being called from procedure WriteIBUser(), if user
// has really been recorded.
//
// Parameters:
//  OldProperties  - Structure, see parameters returned by function Users.ReadIBUser()
//  NewProperties  - Structure, see parameters returned by function Users.WriteIBUser()
//
Procedure OnWriteOfInformationBaseUser(Val OldProperties, Val NewProperties) Export
	
EndProcedure

// Handler of event AfterDeleteRow of infobase user
// being called from procedures DeleteIBUsers(), if user
// has really been deleted.
//
// Parameters:
//  OldProperties - Structure, see parameters returned by function Users.ReadIBUser()
//
Procedure AfterInfobaseUserDelete(Val OldProperties) Export
	
EndProcedure

// Handler of event OnWriteOfFirstAdministrator being called
// from the user form in handler OnWriteAtServer,
// from function Users.AuthorizationError() on administrator authorization,
// when there is no one administrator registered in Users catalog
//
// Parameters:
//  User - CatalogRef.Users (object update is prohibited)
//
Procedure OnWriteOfFirstAdministrator(User) Export
		
EndProcedure

// Handler of event WarningTextAfterWriteOfFirstAdministrator is called
// from function Users.AuthorizationError() on administrator authorization,
// when there is no one administrator registered in Users catalog
//
// Parameters:
//  WarningText - String
//
Procedure WarningTextAfterWriteOfFirstAdministrator(WarningText) Export
		
EndProcedure


