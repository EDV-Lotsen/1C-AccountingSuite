
Procedure OnStart()
	
	STitle = GeneralFunctions.GetSystemTitle();
	CurrentUser = GeneralFunctions.GetUserName();
	
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
	GeneralFunctions.UpdateInfobase();
	GeneralFunctions.UpdatingHierarchyChartOfAccounts();
	GeneralFunctions.UpdatingDocumentJournalOfCompanies();
	
EndProcedure


