
Procedure SessionParametersSetting(SessionParameterNames)
	
	If SessionParameterNames = Undefined Then
		// Section of setting session parameters on session start (SessionParameterNames = Undefined)
		// Set session parameters, that can be initialized
		// on system start
		
	Else
		// Set session parameters "on request"
		
		// SessionNumber parameters, whose initialization requires access to the same data
		// should be initialized as group. To avoid their repeat initialization,
		// names of already initialized session parameters are kept in array InitializedParameters
		InitializedParameters = New Array;
		For each ParameterName In SessionParameterNames Do
			SetSessionParameterValue(ParameterName, InitializedParameters);
		EndDo;	
	EndIf;
	
EndProcedure

// Set session parameter values and return names of already initialized session parameters
// in parameter InitializedParameters.
//
// Parameters:
//   ParameterName  		- String - session parameter name, which has to be initialized.
//   InitializedParameters  - Array  - array, where names of initialized
//                                     parameters are addded.
//
Procedure SetSessionParameterValue(Val ParameterName, InitializedParameters)
	
	// StandardSubsystems
	// If in curent call SessionParametersSetting parameter ParameterName has already
	// been set up - return.
	If InitializedParameters.Find(ParameterName) <> Undefined Then
		Return;
	EndIf;
	
	// Users
	Users.DefineCurrentUser(ParameterName, InitializedParameters);
	// End Users
	
	// Basic functionality
	CommonUse.SessionParametersInitialization(ParameterName, InitializedParameters);
	// End Basic functionality
	
	// End StandardSubsystems
	
	// To initialize session parameters following pattern can be used:
	//If ParameterName = <ParameterName> Then
	//   InitializedParameters.Add(<ParameterName>);
	//ElsIf

EndProcedure
