
Procedure BeforeStart(Cancel)
		
	// StandardSubsystems
	
	// Users
	If ValueIsFilled(StandardSubsystemsClientSecondUse.ClientParameters().AuthorizationError) Then
		
		DoMessageBox(StandardSubsystemsClientSecondUse.ClientParameters().AuthorizationError);
		Cancel = True;
		Return;
		
	EndIf;
	// End Users
	
	// InfobaseVersionUpdate
	Cancel = Cancel OR NOT InfobaseUpdateClient.RunningInfobaseUpdatePermitted();
	// End InfobaseVersionUpdate
	
	// End StandardSubsystems
	
EndProcedure

Procedure OnStart()
	
	// StandardSubsystems
	
	// BasicFunctionality
	CommonUseClient.SetArbitraryApplicationTitle();
	// End BasicFunctionality
	
	// InfobaseVersionUpdate
	InfobaseUpdateClient.RunInfobaseUpdate();
	// End InfobaseVersionUpdate
	
	// ScheduledJobs
	ScheduledJobsClient.OnStart();
	// End ScheduledJobs
	
	// DynamicUpdateMonitoring
	DynamicUpdateMonitoringClient.OnStart();
	// End DynamicUpdateMonitoring
	
	// End StandardSubsystems
	
EndProcedure
