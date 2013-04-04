
&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
		
	NewUser = InfoBaseUsers.CreateUser();

	NewUser.Name = Object.Description;
	NewUser.FullName = Object.Description;
	NewUser.StandardAuthentication = True;
	NewUser.Password = "random";
	NewUser.Roles.Add(Metadata.Roles.FullAccess1);
	NewUser.ShowInList = False;

	NewUser.Write();
	
	NewSLUser = Catalogs.Users.CreateItem();
	NewSLUser.Description = Object.Description;
	NewSLUser.IBUserID = NewUser.UUID;
	NewSLUser.Write();
	
	// API call
	
	APIURL = "api.accountingsuite.com";
	
	Source = TempFilesDir() + "req2.tmp";
	Result = TempFilesDir() + "answ2.tmp";
	
	//POSTRequest = New TextWriter(Source,TextEncoding.UTF8,,False,);
	POSTRequest = New TextWriter(Source,TextEncoding.ANSI,,False,);
	POSTRequest.Write("newuser=" + Object.Description + "&role=User");
	POSTRequest.Close();
	
	SSLConnection = New OpenSSLSecureConnection();
	
	Try
		Connection = New HTTPConnection(APIURL,,,,,,SSLConnection);
		//Connection = New HTTPConnection(APIURL,,,,,,);
		HTTPHeader = New Map();
		HTTPHeader.Insert("Content-Type", "application/x-www-form-urlencoded; charset=UTF-8");
		HTTPHeader.Insert("apipublickey", Constants.APIPublicKey.Get());
		Connection.Post(Source, "/newuser", Result, HTTPHeader);
	Except
		Message(ErrorInfo().Description);
	EndTry;
	
	//CustomerFile = New TextReader;
	//CustomerFile.Open(TempFilesDir() + "answ.tmp");
	//Str = CustomerFile.ReadLine(Chars.CR);
	//Position = Find(Str,"cus_");
	//CID = Mid(Str,Position+4,14);
	//Object.CustomerStripeID = CID;
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// check correct e-mail address formatting
	
	If NOT EmailCheck(Object.Description) Then
		
		Message = New UserMessage();
		Message.Text=NStr("en='Please enter a correct e-mail address'");
		Message.Field = "Object.Description";
		Message.Message();
		Cancel = True;
		Return;
		
	EndIf;
	
	// check uniqueness of the name
	
	Query = New Query("SELECT
	                  |	UserList.Ref
	                  |FROM
	                  |	Catalog.UserList AS UserList
	                  |WHERE
	                  |	UserList.Description = &Description");
					  
	Query.SetParameter("Description", Object.Description);
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
	Else
		
		Message = New UserMessage();
		Message.Text=NStr("en='E-mail address is not unique'");
		Message.Field = "Object.Description";
		Message.Message();
		Cancel = True;
		Return;

	EndIf;
		
EndProcedure


Function EmailCheck(StringToCheck)
	
	Template = ".+@.+\..+";
	RegExp = New COMObject("VBScript.RegExp");
	RegExp.MultiLine = False;
	RegExp.Global = True;
	RegExp.IgnoreCase = True;
	RegExp.Pattern = Template;
	If RegExp.Test(StringToCheck) Then
	     Return True;
	Else
	     Return False;
	EndIf;
	 
EndFunction

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If NOT Object.Ref.IsEmpty() Then
		
			Message = New UserMessage();
			Message.Text=NStr("en='User editing feature is not available at this moment.'");
			Message.Field = "Object.Description";
			Message.Message();
			Cancel = True;
			Return;
		
	EndIf;

EndProcedure


