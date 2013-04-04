
////////////////////////////////////////////////////////////////////////////////
//                   FORM MODULE OF THE WINDOWS USERS CHOICE                 //
////////////////////////////////////////////////////////////////////////////////

// Procedure handler of event "OnOpen" of form
//
&AtClient
Procedure OnOpen(Cancellation)
	
	#If ThickClientOrdinaryApplication OR ThickClientManagedApplication Then
	DomainAndUsersTable = OSUsers();
	#ElsIf ThinClient Then
	DomainAndUsersTable = New FixedArray (OSUsers());
	#EndIf
	
	FillDomainsList();
	
EndProcedure

// Procedure fills list of domains
//
&AtClient
Procedure FillDomainsList ()
	
	ListOfDomains.Clear();
	
	For Each Record In DomainAndUsersTable Do
		Domain = ListOfDomains.Add();
		Domain.DomainName = Record.DomainName;
	EndDo;
	
EndProcedure

// Procedure handler of event OnActivate row of the domains table
//
&AtClient
Procedure DomainTableOnActivateRow(Item)
	
	DomainName = Item.CurrentData.DomainName;
	
	For Each Record In DomainAndUsersTable Do
		If Record.DomainName = DomainName Then
			ListOfUsersOfCurrentDomain.Clear();
			For Each User In Record.Users Do
				DomainUser = ListOfUsersOfCurrentDomain.Add();
				DomainUser.UserName = User;
			EndDo;
			Break;
		EndIf;
	EndDo;
	
EndProcedure

// Procedure handler of event OnSelection row of the users table.
// Generates string for using Windows user authentication.
//
&AtClient
Procedure DomainUsersTableSelection(Item, RowSelected, Field, StandardProcessing)
	
	ComposeResultAndCloseForm();
	
EndProcedure

// Handler of click event of button "Windows user choice" of form.
// Checks, that user is selected and closes form with
// window-authentication string for the selected user.
//
&AtClient
Procedure CommandOKExecute()
	
	DomainName = Items.DomainTable.CurrentData.DomainName;
	UserName = Items.DomainUsersTable.CurrentData.UserName;
	
	If TrimAll(DomainName) <> "" And TrimAll(UserName) <> "" Then
		ComposeResultAndCloseForm();
	EndIf;
	
EndProcedure

// Procedure composes choice result in string presentation \\DOMAIN\DOMAIN_USER_NAME
// and closes form, returning this value, as a form operation result.
//
&AtClient
Procedure ComposeResultAndCloseForm()
	
	DomainName 			= Items.DomainTable.CurrentData.DomainName;
	UserName 			= Items.DomainUsersTable.CurrentData.UserName;
	WindowsUserString 	= "\\" + DomainName + "\" + UserName;
	Close(WindowsUserString);
	
EndProcedure
