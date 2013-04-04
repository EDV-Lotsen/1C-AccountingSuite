
// Handler of event OnStart is called
// for performing actions, required for the subsystem
// DynamicUpdateMonitoringClient.
//
Procedure OnStart() Export
	AttachIdleHandler("InfobaseDynamicChangesCheckIdleHandler", 20 * 60);
EndProcedure
