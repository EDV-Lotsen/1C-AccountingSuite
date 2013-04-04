
////////////////////////////////////////////////////////////////////////////////
// EXPORT FUNCTIONS

Procedure RefreshInfoOnSchedule(AdditionalDataProcessor, Command, Schedule, Use, Cancellation) Export
	
	// get scheduled job by id, if object is not found, create new one
	ScheduledJobObject = GetScheduledJob(Command.ScheduledJobGUID);
	
	// update SJ properties
	SetScheduledJobParameters(ScheduledJobObject, Schedule, Use, AdditionalDataProcessor.Ref, Command);
	
	// write modified job
	WriteScheduledJob(Cancellation, ScheduledJobObject);
	
	//put scheduled job GUID into the object attribute
	Command.ScheduledJobGUID = ScheduledJobObject.UUID;
	
EndProcedure

Procedure DeleteScheduledJob(ScheduledJobGUID) Export
	
	ScheduledJobObject = FindScheduledJob(ScheduledJobGUID);
	
	If ScheduledJobObject <> Undefined Then
		SetPrivilegedMode(True);
		ScheduledJobObject.Delete();
	EndIf;
	
EndProcedure

Function FindScheduledJob(UUIDTasks) Export
	
	SetPrivilegedMode(True);
	
	Try
		CurrentScheduledJob = ScheduledJobs.FindByUUID(UUIDTasks);
	Except
		CurrentScheduledJob = Undefined;
	EndTry;
	
	Return CurrentScheduledJob;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Block of the service functions

Procedure SetScheduledJobParameters(ScheduledJobObject, Schedule, Use, Ref, Command)
	
	SJParameters = New Array;
	SJParameters.Add(Command.Id);
	SJParameters.Add(Ref);
	
	ScheduledJobDescription = 
		StringFunctionsClientServer.SubstitureParametersInString(
				NStr("en = 'Launch data processors: %1'"),
				TrimAll(Command.Presentation) );
	
	ScheduledJobObject.Description  = Left(ScheduledJobDescription, 120);
	ScheduledJobObject.Use 			= Use;
	ScheduledJobObject.Parameters   = SJParameters;
	
	ScheduledJobObject.Schedule		= Schedule;
	
EndProcedure

// Writes scheduled job
//
// Parameters:
//  Cancellation		  - Boolean - cancel flag. If there were any errors during the procedure execution,
//                          then flag is assigned to True
//  ScheduledJobObject 	  - scheduled job object, that has to be written
//
Procedure WriteScheduledJob(Cancel, ScheduledJobObject)
	
	SetPrivilegedMode(True);
	
	Try
		
		// writing  the job
		ScheduledJobObject.Write();
		
	Except
		NString = NStr("en = 'An error occurred while saving the scheduled job. 
                        |Detailed error description: %1'");
		
		MessageString = StringFunctionsClientServer.SubstitureParametersInString(NString,
								BriefErrorDescription(ErrorInfo()));
		
		CommonUseClientServer.MessageToUser(MessageString, , , , Cancel);
	EndTry;
	
EndProcedure

Function GetScheduledJob(ScheduledJobGUID)
	
	SetPrivilegedMode(True);
	
	ScheduledJobObject = FindScheduledJob(ScheduledJobGUID);
	
	// create scheduled job if required
	If ScheduledJobObject = Undefined Then
		
		ScheduledJobObject = ScheduledJobs.CreateScheduledJob("RunAdditionalDataProcessors");
		
	EndIf;
	
	Return ScheduledJobObject;
	
EndFunction
