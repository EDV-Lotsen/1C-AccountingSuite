

////////////////////////////////////////////////////////////////////////////////
// FORM EVENT HANDLERS
//

&AtServer
Procedure OnCreateAtServer(Cancellation, StandardProcessing)
	
	ProcessingPeriod = 3;                              // Seconds.
	LeftBeforeProcessingStart = ProcessingPeriod + 1;  // Seconds.
	
EndProcedure

&AtClient
Procedure OnOpen(Cancellation)
	
	ProcessScheduledJobs();
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Event handlers of commands and form items
//

&AtClient
Procedure StopProcessingAndTerminateSessionExecute()
	
	Close();
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Auxiliary form procedures and functions
//

&AtClient
Procedure ProcessScheduledJobs()
	
	Restart = False;
	If NeedToStopProcessing(LaunchParameter, Restart) Then
		Close(?(Restart, "Restart", Undefined));
	Else
		LeftBeforeProcessingStart = LeftBeforeProcessingStart - 1;
		If LeftBeforeProcessingStart <= 0 Then
			
			LeftBeforeProcessingStart = ProcessingPeriod;
			
			StatusBar = NStr("en = 'Processing, please wait...'");
			RefreshDataRepresentation();
			
			ScheduledJobsServer.ProcessScheduledJobs();
			
		EndIf;
	EndIf;
	
	// Abort processing on CTRL+BREAK
	AttachIdleHandler("StopProcessingAndTerminateSessionExecute", 1, True);
	UserInterruptProcessing();
	DetachIdleHandler("StopProcessingAndTerminateSessionExecute");
	
	AttachIdleHandler("ProcessScheduledJobs", 1, True);
	StatusBar = StringFunctionsClientServer.SubstitureParametersInString(
	                    NStr("en = 'Processing will start in %1 sec'"), String(LeftBeforeProcessingStart) );
	
EndProcedure

&AtServer
Function NeedToStopProcessing(LaunchParameter, Restart)
	
	Restart = DataBaseConfigurationChangedDynamically();
	
	Return Restart OR
	        ScheduledJobsServer.ParentSessionSetAndCompleted(LaunchParameter) OR
	        NOT ScheduledJobsServer.CurrentSessionHandlesTasks();
	
EndFunction
