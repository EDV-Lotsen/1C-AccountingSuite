
////////////////////////////////////////////////////////////////////////////////
// INBOBASE DATA UPDATE ON  CONFIGURATION VERSION CHANGE

// Check infobase shold be updated on configuration version change.
//
Function InfobaseUpdateRequired() Export
	
	Return UpdateRequired(Metadata.Version, InfobaseVersion(Metadata.Name));
	
EndFunction

// Check if current user is allowed to process infobase update.
//
Function HaveInfobaseUpdateRights() Export
	
	Return AccessRight("ExclusiveMode", Metadata) And AccessRight("Administration", Metadata);
	
EndFunction	

Function IsImpossibleToUpdateInfobase() Export
	
	Return InfobaseUpdateRequired() And NOT HaveInfobaseUpdateRights();
	
EndFunction	

// Execute interactive update of IB data.
//
// Result:
//      Undefined 	 - update has not been done (is not required)
//      String       - temporary storage address with the list of processed update handlers
//
Function RunInfobaseUpdate() Export

	MetadataVersion  = Metadata.Version;
	DataVersion		 = InfobaseVersion(Metadata.Name);
	If IsBlankString(MetadataVersion) Then
		 MetadataVersion = "0.0.0.0";
	EndIf;
	 
	If Not UpdateRequired(MetadataVersion, DataVersion) Then
		Return Undefined;
	EndIf;
	
	Message = StringFunctionsClientServer.SubstitureParametersInString(
		NStr("en = 'The configuration version has changed: from %1 to %2. Infobase update will be performed.'"),
		DataVersion, MetadataVersion);
	WriteInformation(Message);
	
	// Check that there are enough rights to update the infobase.
	If Not HaveInfobaseUpdateRights() Then
		Message = NStr("en = 'Not enough access rights to perform updates. Contact system administrator.'");
		WriteError(Message);
		Raise Message;
	EndIf;
	
	SettingValue = CommonSettingsStorage.Load("InfobaseVersionUpdate", "DebugMode");
	DebugMode 	 = SettingValue = True;
	
	// Set exclusive mode for infobase update.
	If Not DebugMode Then
		Try
			SetExclusiveMode(True);
		Except
			Message = StringFunctionsClientServer.SubstitureParametersInString(
				NStr("en = 'Unable to perform infobase updates because there are other sessions connected to it.
                      |Contact system administrator.
                      |Error details: %1'"),
				BriefErrorDescription(ErrorInfo()));
			
			WriteError(Message);
			
			Raise Message;
		EndTry;
	EndIf;	
	
	Try
		ListOfUpdateHandlers = InfobaseUpdateOverrided.UpdateHandlers();
		
		// Also procedures of Subsystems Library data update are always called
		//
		Handler 			= ListOfUpdateHandlers.Add();
		Handler.Version 	= "*";
		Handler.Procedure 	= "StandardSubsystemsOverrided.RunInfobaseUpdate";
		
		ExecutedHandlers = RunUpdateIteration(Metadata.Name, Metadata.Version,
			ListOfUpdateHandlers);
	Except
		Message = StringFunctionsClientServer.SubstitureParametersInString(
			NStr("en = 'Infobase update to version %1 completed with errors: %2'"),
				MetadataVersion,
				DetailErrorDescription(ErrorInfo()));
		WriteError(Message);
		// Disable exclusive mode.
		If Not DebugMode Then
			//SetExclusiveMode(False);
		EndIf;	
		Raise;
	EndTry;
	
	// Disable exclusive mode.
	If NOT DebugMode Then
		SetExclusiveMode(False);
	EndIf;	
	
	Message = StringFunctionsClientServer.SubstitureParametersInString(
		NStr("en = 'Infobase update to version %1 completed successfully.'"), MetadataVersion);
	WriteInformation(Message);
	
	OutputUpdatesDetails = DataVersion <> "0.0.0.0";
	InfobaseUpdateOverrided.AfterUpdate(DataVersion, MetadataVersion, 
		ExecutedHandlers, OutputUpdatesDetails);
	
	Address = "";
	If OutputUpdatesDetails Then
		Address = PutToTempStorage(ExecutedHandlers, New UUID);
	EndIf;
	
	Return Address;

EndFunction

// Execute update handlers from the list UpdateHandlers
// for the component LibraryID to version MetadataInfobaseVersion.
//
// Parameters
//  LibraryID  			– String – configuration name or library ID.
//  MetadataInfobaseVersion   – String – metadata version, till which
//                                      update should be performed.
//  UpdateHandlers    	– Map	 – list of update handlers.
//
// Value returned:
//   ValueTree  	    – executed updates handlers.
//
Function RunUpdateIteration(Val LibraryID, Val MetadataInfobaseVersion, 
	Val UpdateHandlers) Export
	
	CurrentInfobaseVersion = InfobaseVersion(LibraryID);
	If IsBlankString(CurrentInfobaseVersion) Then
		 CurrentInfobaseVersion = "0.0.0.0";
	EndIf;
	NewInfobaseVersion    = CurrentInfobaseVersion;
	MetadataVersion = MetadataInfobaseVersion;
	If IsBlankString(MetadataVersion) Then
		 MetadataVersion = "0.0.0.0";
	EndIf;
	
	If CurrentInfobaseVersion = MetadataVersion Then
		Return New ValueTree();
	EndIf;
	
	RunningHandlers = UpdateHandlersInInterval(UpdateHandlers, CurrentInfobaseVersion, MetadataVersion);
	For Each Version In RunningHandlers.Rows Do
		
		If Version.Version = "*" Then
			Message = NStr("en = 'Performing necessary infobase update operations'");
		Else
			NewInfobaseVersion = Version.Version;
			
			If LibraryID = Metadata.Name Then 
				Message  = NStr("en = 'Performing infobase update form version %1 to version %2.'");
			Else
				Message	 = NStr("en = 'Updates for infobase of the parent configuration %3 from version %1 to version %2 are being installed.'");
			EndIf;
			
			Message = StringFunctionsClientServer.SubstitureParametersInString(Message,
			    CurrentInfobaseVersion, NewInfobaseVersion, LibraryID);
			
		EndIf;
		
		WriteInformation(Message);
		
		For Each Handler In Version.Rows Do
			CommonUse.RunSafely(Handler.Procedure);
		EndDo;
		
		If Version.Version = "*" Then
			Message = NStr("en = 'The required infobase update operations are completed.'");
		Else
			// Set infobase version number
			SetInfobaseVersion(LibraryID, NewInfobaseVersion);
			
			If LibraryID = Metadata.Name Then 
				Message = NStr("en = 'Update of the infobase from version %1 to version %2 completed.'");
			Else
				Message = NStr("en = 'The infobase update of the parent configuration %3 from version %1 to version %2 completed.'");
			EndIf;
			
			Message = StringFunctionsClientServer.SubstitureParametersInString(Message,
			  	CurrentInfobaseVersion, NewInfobaseVersion, LibraryID);
			
			CurrentInfobaseVersion = NewInfobaseVersion;
			
		EndIf;
		WriteInformation(Message);
		
	EndDo;
	
	// Set infobase version number
	If InfobaseVersion(LibraryID) <> MetadataInfobaseVersion Then
		SetInfobaseVersion(LibraryID, MetadataInfobaseVersion);
	EndIf;
	
	Return RunningHandlers;
	
EndFunction

Function NewUpdateHandlersTable() Export
	
	Handlers = New ValueTable;
	Handlers.Columns.Add("Version", 	New TypeDescription("String", New StringQualifiers(0)));
	Handlers.Columns.Add("Procedure", 	New TypeDescription("String", New StringQualifiers(0)));
	Handlers.Columns.Add("Optional");
	Return Handlers;
	
EndFunction

// Get configuration version or version of parent configuration (library),
// that is stored in infobase.
//
// Parameters
//  LibraryID  – String – configuration name or library ID.
//
// Value returned:
//   String    – version.
//
// Example:
//   IBConfigurationVersion = InfobaseVersion(Metadata.Name);
//
Function InfobaseVersion(Val LibraryID) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query(
		"SELECT
		|	SubsystemVersions.Version AS Version
		|FROM
		|	InformationRegister.SubsystemVersions AS SubsystemVersions
		|WHERE
		|	SubsystemVersions.SubsystemName = &SubsystemName");
	Query.Parameters.Insert("SubsystemName", LibraryID);
	ValueTable = Query.Execute().Unload();
	Result = "";
	If ValueTable.Count() > 0 Then
		Result = TrimAll(ValueTable[0].Version);
	EndIf;
	Return ?(IsBlankString(Result), "0.0.0.0", Result);

EndFunction

////////////////////////////////////////////////////////////////////////////////
// AUXILIARY PROCEDURES AND FUNCTIONS

Function UpdateRequired(Val MetadataVersion, Val DataVersion) 
	
	Return Not IsBlankString(MetadataVersion) And DataVersion <> MetadataVersion;
	
EndFunction

Procedure SetInfobaseVersion(Val LibraryID, Val VersionNo) 
	
	RecordSet = InformationRegisters.SubsystemVersions.CreateRecordSet();
	RecordSet.Filter.SubsystemName.Set(LibraryID);
	
	NewRecord = RecordSet.Add();
	
	NewRecord.SubsystemName = LibraryID;
	NewRecord.Version 		= VersionNo;
	
	RecordSet.Write();
	
EndProcedure

Function UpdateHandlersInInterval(Val AllHandlers, Val VersionFrom, Val VersionBefore)
	
	QueryBuilder 					 = New QueryBuilder();
	Source 							 = New DataSourceDescription(AllHandlers);
	Source.Columns.Version.Dimension = True;
	QueryBuilder.DataSource  		 = Source;
	QueryBuilder.Dimensions.Add("Version");
	QueryBuilder.Execute();
	SelectionTotals			 		 = QueryBuilder.Result.Choose(QueryResultIteration.ByGroups);
	
	RunningHandlers = New ValueTree();
	RunningHandlers.Columns.Add("Version");
	RunningHandlers.Columns.Add("Procedure");
	While SelectionTotals.Next() Do
		
		If SelectionTotals.Version <> "*" And 
			Not (StringFunctionsClientServer.CompareVersions(SelectionTotals.Version, VersionFrom) > 0 
				And StringFunctionsClientServer.CompareVersions(SelectionTotals.Version, VersionBefore) <= 0) Then
			Continue;
		EndIf;
		
		VersionString = Undefined;
		Selection = SelectionTotals.Choose(QueryResultIteration.Linear);
		While Selection.Next() Do
			If Selection.Procedure = Null Then
				Continue;
			EndIf;
			If Selection.Optional  = True And VersionFrom = "0.0.0.0" Then
				Continue;
			EndIf;
			If VersionString  = Undefined Then
				VersionString = RunningHandlers.Rows.Add();
				VersionString.Version = SelectionTotals.Version;
			EndIf;
			Handler = VersionString.Rows.Add();
			FillPropertyValues(Handler, Selection, "Version, Procedure");
		EndDo;
		
	EndDo;
	
	// sort handlers ascending by version
	RowsCount = RunningHandlers.Rows.Count();
	For Ind1 = 2 To RowsCount Do
		For Ind2 = 0 To RowsCount - Ind1 Do
			
			If RunningHandlers.Rows[Ind2].Version = "*" Then
				Result = -1;
			ElsIf RunningHandlers.Rows[Ind2+1].Version = "*" Then
				Result = 1;
			Else
				Result = StringFunctionsClientServer.CompareVersions(RunningHandlers.Rows[Ind2].Version, RunningHandlers.Rows[Ind2+1].Version);
			EndIf;	
			
			If Result > 0  Then 
				RunningHandlers.Rows.Move(Ind2, 1);
			EndIf;
			
		EndDo;
	EndDo;
	
	Return RunningHandlers;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// LOGGING OF UPDATE PROCESS

Function EventLogMessage()
	
	Return NStr("en = 'Infobase Update'");
	
EndFunction	

Procedure WriteInformation(Val Text) 
	
	WriteLogEvent(EventLogMessage(), EventLogLevel.Information,,, Text);
	
EndProcedure

Procedure WriteError(Val Text) 
	
	WriteLogEvent(EventLogMessage(), EventLogLevel.Error,,, Text);
	
EndProcedure

