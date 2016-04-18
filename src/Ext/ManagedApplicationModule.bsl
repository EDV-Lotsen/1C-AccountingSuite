
Procedure OnStart()
	
	CurrentUser = GeneralFunctions.GetUserName();
	
	STitle = GeneralFunctionsReusable.GetSystemTitle();
	AppName = "AccountingSuite 1C-DN Edition";
	AppTitle = "";
	If STitle = "" Then
		AppTitle = CurrentUser + " / " + AppName + " ";
	Else
		AppTitle = STitle + " / " + CurrentUser + " / " + AppName + " ";
	EndIf;
	SetApplicationCaption(AppTitle);

	GeneralFunctions.FirstLaunch();
	GeneralFunctions.CheckConnectionAtServer();
	GeneralFunctions.UpdateInfobase();
	GeneralFunctions.UpdatingHierarchyChartOfAccounts();
	RefreshInterface();
	
	If GeneralFunctions.GetSettingsPopUp() Then
		OpenForm("CommonForm.GeneralSettings");
	EndIf;
	
EndProcedure
