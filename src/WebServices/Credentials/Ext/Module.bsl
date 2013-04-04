
Function ChangePwd(User, NewPwd)
	
	ChangeUser = InfoBaseUsers.FindByName(User);
	ChangeUser.Password = NewPwd;
	ChangeUser.Write(); 
	
EndFunction

Function AddUsr(User)
	
	NewUser = InfoBaseUsers.CreateUser();

	NewUser.Name = User;
	NewUser.FullName = User;
	NewUser.StandardAuthentication = True;
	NewUser.Password = "random";
	NewUser.Roles.Add(Metadata.Roles.FullAccess1);
	NewUser.ShowInList = False;

	NewUser.Write();
	
	NewSLUser = Catalogs.Users.CreateItem();
	NewSLUser.Description = User;
	NewSLUser.IBUserID = NewUser.UUID;
	NewSLUser.Write();
	
	NewUserList = Catalogs.UserList.CreateItem();
	NewUserList.Description = User;
	NewUserList.Role = "FullRights";
	NewUserList.Write();
	
	// API call
	
	//APIURL = "api.accountingsuite.com";
	//
	//Source = TempFilesDir() + "req2.tmp";
	//Result = TempFilesDir() + "answ2.tmp";
	//
	////POSTRequest = New TextWriter(Source,TextEncoding.UTF8,,False,);
	//POSTRequest = New TextWriter(Source,TextEncoding.ANSI,,False,);
	//POSTRequest.Write("newuser=" + User + "&role=FullAccess");
	//POSTRequest.Close();
	//
	//SSLConnection = New OpenSSLSecureConnection();
	//
	//Try
	//	Connection = New HTTPConnection(APIURL,,,,,,SSLConnection);
	//	//Connection = New HTTPConnection(APIURL,,,,,,);
	//	HTTPHeader = New Map();
	//	HTTPHeader.Insert("Content-Type", "application/x-www-form-urlencoded; charset=UTF-8");
	//	HTTPHeader.Insert("apipublickey", Constants.APIPublicKey.Get());
	//	Connection.Post(Source, "/newuser", Result, HTTPHeader);
	//Except
	//	Message(ErrorInfo().Description);
	//EndTry;

EndFunction

Function AddUsrPwd(User, Pwd)
	
	NewUser = InfoBaseUsers.CreateUser();

	NewUser.Name = User;
	NewUser.FullName = User;
	NewUser.StandardAuthentication = True;
	NewUser.Password = Pwd;
	NewUser.Roles.Add(Metadata.Roles.FullAccess1);
	NewUser.ShowInList = False;

	NewUser.Write();
	
	NewSLUser = Catalogs.Users.CreateItem();
	NewSLUser.Description = User;
	NewSLUser.IBUserID = NewUser.UUID;
	NewSLUser.Write();
	
	NewUserList = Catalogs.UserList.CreateItem();
	NewUserList.Description = User;
	NewUserList.Role = "FullRights";
	NewUserList.Write();
	
EndFunction

Function ChangeTitle(Title)
	Constants.SystemTitle.Set(Title);
EndFunction

Function ChangeUsrPwd(User, Pwd)
	
	MasterUser = InfobaseUsers.FindByName("user@accountingsuite.com");
	MasterUser.Name = User;
	MasterUser.FullName = User;
	MasterUser.Password = Pwd;
	MasterUser.Write();
	
	// also change in Users, UserList
	
EndFunction
