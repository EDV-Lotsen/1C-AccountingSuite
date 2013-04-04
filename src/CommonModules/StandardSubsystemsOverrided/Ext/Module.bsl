
// Not interactive IB data update on library version change
// Required IB update "input point" in library.
Procedure RunInfobaseUpdate() Export
	
	InfobaseUpdate.RunUpdateIteration("StandardSubsystems", LibVersion(), 
		UpdateHandlers());
	
EndProcedure

// Returns version number of the SL.
//
Function LibVersion() Export
	
	Return "1.0.7.5";
	
EndFunction

// Returns list of procedures-handlers of library update
//
// Value returned:
//   Structure - description of the structure fields see in function
//               InfobaseUpdate.NewUpdateHandlersTable()
Function UpdateHandlers()
	
	Handlers = InfobaseUpdate.NewUpdateHandlersTable();
	
	// Connect procedures-handlers of library update
	
	// FullTextSearch
	Handler = Handlers.Add();
	Handler.Version = "1.0.3.10";
	Handler.Procedure = "FullTextSearchServer.InitializeFunctionalOptionFullTextSearch";
	// End FullTextSearch
	
	// Users
	Handler = Handlers.Add();
	Handler.Version = "1.0.5.2";
	Handler.Procedure = "Users.FillUserIDs";
	// End Users
	
	// AdditionalReportsAndDataProcessors
	Handler = Handlers.Add();
	Handler.Version = "1.0.7.1";
	Handler.Procedure = "AdditionalReportsAndDataProcessors.UpdateDataProcessorsAccessUserSettings";
	// End AdditionalReportsAndDataProcessors
	
	Return Handlers;
	
EndFunction

// Returns structure of parameters, for the initialization of
// configuration at client.
//
Function ClientParameters() Export
	
	Parameters = New Structure();
	
	// StandardSubsystems
	Parameters.Insert("AuthorizationError", Users.AuthorizationError());
	If ValueIsFilled(Parameters.AuthorizationError) Then
		Return New FixedStructure(Parameters);
	EndIf;
	Parameters.Insert("InformationBaseLockedForUpdate",  InfobaseUpdate.IsImpossibleToUpdateInfobase());
	Parameters.Insert("InfobaseUpdateRequired",          InfobaseUpdate.InfobaseUpdateRequired());
	Parameters.Insert("AuthorizedUser", 				 Users.AuthorizedUser());
	Parameters.Insert("ThisIsBasicConfigurationVersion", ThisIsBasicConfigurationVersion());
	Parameters.Insert("ApplicationTitle",                TrimAll(Constants.SystemTitle.Get()));
	Parameters.Insert("DetailedInformation",             Metadata.DetailedInformation);
	Parameters.Insert("FileInformationBase",             CommonUse.FileInformationBase());
	
	// ScheduledJobs
	If CommonUse.FileInformationBase() Then
		Parameters.Insert("OpenParametersOfScheduledJobsProcessingSession", 
			New FixedStructure(ScheduledJobsServer.OpenParametersOfScheduledJobsProcessingSession(True)));
	EndIf;
	// End ScheduledJobs
	
	// End StandardSubsystems
	
	Return New FixedStructure(Parameters);
	
EndFunction

// Returns flag, indicating if configuration is basic.
//
// Implementation example:
//  If configurations are issued in pairs, then in the name of basic version
//  additional word "Basic" may be included. Then logics
//  of the determination of basic version is following:
//
//	Return Find(Upper(Metadata.Name), "BASIC") > 0;
//
// Value returned:
//   Boolean   - True, if configuration is - basic.
//
Function ThisIsBasicConfigurationVersion() Export

	Return Find(Upper(Metadata.Name), "BASIC") > 0;

EndFunction
