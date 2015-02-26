
Procedure SessionParametersSetting(RequiredParameters)
	
	
	CurrentUser = InfobaseUsers.CurrentUser(); // GeneralFunctions.CurrentUserValue();
	SessionParameters.ACSUser = CurrentUser.Name;
	SessionParameters.TimeTrackToInvoiceDate = CurrentSessionDate();
	
EndProcedure
