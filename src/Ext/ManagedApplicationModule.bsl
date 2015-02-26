
Procedure OnStart()
	
	CurrentUser = GeneralFunctions.GetUserName();
	
	STitle = GeneralFunctions.GetSystemTitle();
	
	AppName = "AccountingSuite";
	
	AppTitle = "";
	If STitle = "" Then
		AppTitle = CurrentUser + " / " + AppName + " ";
	Else
		AppTitle = STitle + " / " + CurrentUser + " / " + AppName + " ";
	EndIf;
	
	SetApplicationCaption(AppTitle);

	GeneralFunctions.FirstLaunch();
	GeneralFunctions.CheckConnectionAtServer();
	
	If GeneralFunctions.IsUserDisabled(CurrentUser) Then
		ShowMessageBox(New NotifyDescription("CloseApp", CommonUseClient, False), NStr("en = 'Your user access to the database is locked!'"));
	EndIf;
		
EndProcedure

