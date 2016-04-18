
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	ShowSessionsAtServer();
	
	If ListOfUsers.Count() = 0 Then
		Cancel = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure ShowSessions(Command)
	
	ShowSessionsAtServer();
	
EndProcedure

&AtClient
Procedure TerminateSessions(Command)
	
	TerminateSessionsAtServer();
	ShowMessageBox(, "Done!");
	ThisForm.Close();
	
EndProcedure

&AtClient
Procedure CloseForm(Command)
	
	ThisForm.Close();
	
EndProcedure

&AtServer
Procedure ShowSessionsAtServer()
	
	SetPrivilegedMode(True);
	
	ListOfUsers.Clear();
	
	CurrentUser       = InfobaseUsers.CurrentUser();
	CurrentUserName   = CurrentUser.Name;
	CurrentUserTenant = CurrentUser.DataSeparation.Tenant;
	
	Users = GetInfoBaseSessions();
	For Each User In Users Do
		
		If User.User.Name = CurrentUserName
			And User.User.DataSeparation.Tenant = CurrentUserTenant
			And User.SessionNumber <> InfoBaseSessionNumber()
			Then
			
			NewRow = ListOfUsers.Add();
			NewRow.Name             = User.User.FullName;
			NewRow.SessionNumber    = User.SessionNumber;
			NewRow.ConnectionNumber = User.ConnectionNumber;
			NewRow.Application      = ApplicationPresentation(User.ApplicationName);
			NewRow.SessionStarted   = User.SessionStarted;
		EndIf;
		
	EndDo;
	
	SetPrivilegedMode(False);
	
EndProcedure

&AtServer
Procedure TerminateSessionsAtServer()
	
	SetPrivilegedMode(True);
	
	InfoBaseConnectionString = InfoBaseConnectionString(); 
	If Find(InfoBaseConnectionString, "Srvr") > 0 Then
		// Server
		Find1           = Find(InfoBaseConnectionString, "Srvr=");
		SubstringSearch = Mid(InfoBaseConnectionString, Find1 + 6);
		ServerName      = Left(SubstringSearch, Find(SubstringSearch, """") - 1);
		// Database
		Find1           = Find(InfoBaseConnectionString, "Ref=");
		SubstringSearch = Mid(InfoBaseConnectionString, Find1 + 5);
		DataBaseName    = Left(SubstringSearch, Find(SubstringSearch, """") - 1);
	Else
		// For other ways this algorithm doesn't work
		Return;
	EndIf;
	
	Connector    = New COMObject("V83.COMConnector");
	ConnectAgent = Connector.ConnectAgent(ServerName);
	Clusters     = ConnectAgent.GetClusters();
	For Each Cluster In Clusters Do
		
		ConnectAgent.Authenticate(Cluster,"","");
		WorkingProcesses = ConnectAgent.GetWorkingProcesses(Cluster);
		DataBases        = ConnectAgent.GetInfoBases(Cluster);
		
		For Each DataBase In DataBases Do
			If Upper(DataBase.Name) = Upper(DataBaseName) Then
				Sessions = ConnectAgent.GetInfoBaseSessions(Cluster, DataBase);
				For Each Session In Sessions Do
					
					Array = ListOfUsers.FindRows(New Structure("SessionNumber", Session.SessionID)); 
					If Array.Count() > 0 Then
						ConnectAgent.TerminateSession(Cluster, Session);
					EndIf;
					
				EndDo;
			EndIf;
		EndDo;
	EndDo;
	
	SetPrivilegedMode(False);
	
EndProcedure


