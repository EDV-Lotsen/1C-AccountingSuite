
Procedure OnStart()
	
		STitle = GeneralFunctions.GetSystemTitle();
		CurrentUser = GeneralFunctions.GetUserName();
		
		AppTitle = "";
		If STitle = "" Then
			AppTitle = CurrentUser + " / AccountingSuite ";
		Else
			AppTitle = STitle + " / " + CurrentUser + " / AccountingSuite"
		EndIf;
		
		SetApplicationCaption(AppTitle);
	
		GeneralFunctions.FirstLaunch();
	
EndProcedure

