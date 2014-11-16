
Procedure OnStart()
	
		STitle = GeneralFunctions.GetSystemTitle();
		CurrentUser = GeneralFunctions.GetUserName();
		
		If GeneralFunctions.GetCFOTodayConstant() = True Then
			AppName = "CFOToday"
		Else
			AppName = "AccountingSuite"
		EndIf;
		
		AppTitle = "";
		If STitle = "" Then
			AppTitle = CurrentUser + " / " + AppName + " ";
		Else
			AppTitle = STitle + " / " + CurrentUser + " / " + AppName + " ";
		EndIf;
		
		SetApplicationCaption(AppTitle);
	
		GeneralFunctions.FirstLaunch();
	
EndProcedure


