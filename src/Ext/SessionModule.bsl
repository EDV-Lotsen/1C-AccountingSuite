
Procedure SessionParametersSetting(RequiredParameters)
	
	CurrentUser = InfobaseUsers.CurrentUser();
	SessionParameters.ACSUser = CurrentUser.Name;
	SessionParameters.TimeTrackToInvoiceDate = CurrentSessionDate();
	
EndProcedure
