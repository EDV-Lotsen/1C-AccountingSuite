////////////////////////////////////////////////////////////////////////////////
// EXPORT PROCEDURES AND FUNCTIONS
                          
// Initializes form functional option parameters - it is required
// for generating from command interface.
// This procedure is designed to be used in OnCreateAtServer event hanlder.
//
// Parameters:
//  Form - the Form which for to set functional option parameters.
//
// Returns: 
//  No.
//
Procedure OnCreateAtServer(Form) Export
	
	If IsBlankString(InfobaseUsers.CurrentUser().Name)
		OR IsInRole(Metadata.Roles.FullAccess)
		OR IsInRole(Metadata.Roles.UseAdditionalReportsAndDataProcessors)
		OR IsInRole(Metadata.Roles.AddChangeAdditionalReportsAndDataProcessors) Then
		
		FormNameArray = StringFunctionsClientServer.DecomposeStringIntoSubstringsArray(Form.FormName, ".");
		FullMetadataObjectName = FormNameArray[0] + "." + FormNameArray[1];
		
		If	IsObjectForm(FullMetadataObjectName, Form.FormName) Then
			Form.SetFormFunctionalOptionParameters(New Structure("FormWithAdditionalReportsAndDataProcessorsType", "ObjectForm"));
		Else
			Form.SetFormFunctionalOptionParameters(New Structure("FormWithAdditionalReportsAndDataProcessorsType", "ListForm"));
		EndIf;
		
		Form.SetFormFunctionalOptionParameters(New Structure("ConfigurationObjectType", FullMetadataObjectName));
		
	EndIf;
	
EndProcedure

// Generates print forms using external source.
//
// Parameters:
//  DataSource - CatalogRef.AdditionalReportsAndDataProcessors - reference to 
//		the external data processor
//  SourceParameters - Structure with keys:
//		SafeMode - boolean - if safe mode is enabled
//		CommandID - string - list of templates, separated by comma
//		DestinationObjects - array - array of refs to the destination objects
// 			parameters, filled in function (see description in 
//			PrintManagementOverrided module)
//  PrintFormsCollection - ValueTable - with following columns:
//		SpreadsheetDocument - SpreadsheetDocument - the print result
//		TemplateSynonym - String - the presentation of the printed form
//		Picture - Picture - the picture for the row
//		FullPathToTemplate - String - the path to the template of the form
//  PrintObjects - ValueList - list of objects to print
//  OutputParameters - Structure - for fields set see 
//		PrintManagement.PrepareOutputParametersStructure
//
// Returns: 
//  No.
//
Procedure PrintFromExternalDataSource(DataSource,
									  SourceParameters,
									  PrintFormsCollection,
									  PrintObjects,
									  OutputParameters) Export
	                    	
	PrintFormsCollection = PrintManagement.PrepareCollectionOfPrintForms(SourceParameters.CommandID);
	
	OutputParameters 			 = PrintManagement.PrepareOutputParametersStructure();
	
	PrintObjects	 			 = New ValueList;
	
	AdditionalDataProcessorObject  = GetAdditionalDataProcessorObject(DataSource, SourceParameters.SafeMode);
	
	AdditionalDataProcessorObject.Print(
					SourceParameters.DestinationObjects,
					PrintFormsCollection, PrintObjects, OutputParameters);
	
	// Check if all templates have been generated
	For Each Row In PrintFormsCollection Do
		If Row.SpreadsheetDocument = Undefined Then
			ErrorMessageText = StringFunctionsClientServer.SubstitureParametersInString(
										NStr("en = 'Print handler has not generated spreadsheet document for: %1'"),
										Row.DesignName);
			Raise(ErrorMessageText);
		EndIf;
		
		Row.SpreadsheetDocument.Copies = Row.NumberOfCopies;
	EndDo;

EndProcedure

// Checks if the given form name is the main form of the given metadata object.
//
// Parameters:
//  FullMetadataObjectName - String - the metadata object's full name
//  FormName - String - the full form name
//
// Returns: 
//  True - when the form is the main form of the metadata object
//	False - otherwise.
//
Function IsObjectForm(FullMetadataObjectName, FormName) Export
	
	MetadataObject = Metadata.FindByFullName(FullMetadataObjectName);
	
	If MetadataObject.DefaultObjectForm.FullName() = FormName Then
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

// Runs the global data processor with given command ID. See RunDataProcessorDirectly
// for more information on how it is run.
// It is designed to be the handler of RunAdditionalDataProcessors scheduled 
// job instance.
//
// Parameters:
//  AdditionalDataProcessor - CatalogRef.AdditionalReportsAndDataProcessors
//  CommandID 			  - String - ID of the command that will be executed
//
// Returns: 
//  No.
//
Procedure RunDataProcessorInScheduledJob(AdditionalDataProcessor, CommandID) Export
	
	StartDataProcessorExecution(AdditionalDataProcessor, CommandID);
	
	RunDataProcessorDirectly(AdditionalDataProcessor, CommandID, AdditionalDataProcessor.SafeMode);
	
	FinishDataProcessorExecution(AdditionalDataProcessor, CommandID);
	
EndProcedure

// Gets the value table with the list of metadata objects, which can be processed 
// by the data processor of the given type.
// The list of metadata objects is taken from the common command, corresponding to the
// data processor type. For global data processors empty set is returned.
//
// Parameters:
//  Type - Enum.AdditionalReportAndDataProcessorTypes - additional data processor type
//
// Returns:
//	ValueTable with following columns:
//		FullMetadataObjectName - String - full name of the metadata object, for example
//			"Catalog.Currencies"
//		Class - String - metadata class, for example "Catalog"
//		Object - String - metadata object name, for example "Currencies"
//
Function GetAllAssignmentsByAdditionalDataProcessorType(Type) Export
	
	Assignments = New ValueTable;
	Assignments.Columns.Add("FullMetadataObjectName");
	Assignments.Columns.Add("Class");
	Assignments.Columns.Add("Object");
	
	Command = Undefined;
	
	If	  Type = Enums.AdditionalReportAndDataProcessorTypes.ObjectFilling Then
		Command = Metadata.CommonCommands.AdditionalReportsAndDataProcessorsFillObject;
	ElsIf Type = Enums.AdditionalReportAndDataProcessorTypes.Report Then
		Command = Metadata.CommonCommands.AdditionalReportsAndDataProcessorsReports;
	ElsIf Type = Enums.AdditionalReportAndDataProcessorTypes.PrintForm Then
		Command = Metadata.CommonCommands.AdditionalReportsAndDataProcessorsPrintForms;
	ElsIf Type = Enums.AdditionalReportAndDataProcessorTypes.CreateLinkedObjects Then
		Command = Metadata.CommonCommands.AdditionalReportsAndDataProcessorsCreatingLinkedObjects;
	EndIf;
	
	If Command <> Undefined Then
		
		For Each CurrentType In Command.CommandParameterType.Types() Do
			FullMetadataObjectName = Metadata.FindByType(CurrentType).FullName();
			SplittedString = StringFunctionsClientServer.DecomposeStringIntoSubstringsArray(FullMetadataObjectName, ".");
			NewAssignment = Assignments.Add();
			NewAssignment.FullMetadataObjectName = FullMetadataObjectName;
			NewAssignment.Class	= SplittedString[0];
			NewAssignment.Object = SplittedString[1];
		EndDo;
		
	EndIf;
	
	Return Assignments;
	
EndFunction

// Checks, whether the report or data processor is the global data processor 
// or report by its type.
//
// Parameters:
//  Type - EnumRef.AdditionalReportAndDataProcessorTypes - data processor type
//
// Returns:
//	True - this is global report or data processor
//	False - this is assigned report or data processor
//
Function IsGlobalDataProcessorType(Type) Export
	
	Return (Type = Enums.AdditionalReportAndDataProcessorTypes.AdditionalDataProcessor)
		OR (Type = Enums.AdditionalReportAndDataProcessorTypes.AdditionalReport);
	
EndFunction

// Checks, whether the report or data processor is of "assigned to objects" 
// category by its type.
//
// Parameters:
//  Type - EnumRef.AdditionalReportAndDataProcessorTypes - data processor type
//
// Returns:
//	True - this is assigned report or data processor
//	False - this is global report or data processor
//
Function IsAssignedDataProcessorType(Type) Export
	
	Return Not IsGlobalDataProcessorType(Type);
	
EndFunction

// Attaches external data processor. After data processor is attached
// it becomes known in the system under specific name. After that
// data processor can be opened.
//
// Parameters:
//   AdditionalDataProcessor - CatalogRef.AdditionalReportsAndDataProcessors
//   SafeMode - Boolean - if data processor should be run in safe mode
//
// Returns:
//   String - the data processor name in the system
//
Function AttachAdditionalDataProcessor(AdditionalDataProcessor, SafeMode) Export
	
	SetPrivilegedMode(True);
	
	DataProcessorBinaryData   = AdditionalDataProcessor.GetObject().DataProcessorStorage.Get();
	AddressInTemporaryStorage = PutToTempStorage(DataProcessorBinaryData);
	
	If AdditionalDataProcessor.Type  = Enums.AdditionalReportAndDataProcessorTypes.Report
	 OR AdditionalDataProcessor.Type = Enums.AdditionalReportAndDataProcessorTypes.AdditionalReport Then
		Return ExternalReports.Connect(AddressInTemporaryStorage,, SafeMode);
	Else
		Return ExternalDataProcessors.Connect(AddressInTemporaryStorage,, SafeMode);
	EndIf;
	
EndFunction

// Creates data processor object and passes control to it using known interface.
// For the assigned data processors the assignement objects are specified also. 
// From some data processors the execution result is received.
//
// Parameters:
//  AdditionalDataProcessorRef - CatalogRef.AdditionalReportsAndDataProcessors
//  CommandID 		   - String - id of one of data processor's commands
//  SafeMode 		   - Boolean - if data processor should be run in safe mode
//  DestinationObjects - Array - objects which to the data processor is assigned
//  ExecutionResult    - Array - the data processor execution result is returned 
//		through this parameter
//
// Returns:
//  No.
//
Procedure RunDataProcessorDirectly(AdditionalDataProcessorRef,
								   CommandID,
								   SafeMode,
								   DestinationObjects = Undefined,
								   ExecutionResult = Undefined) Export
	
	SetPrivilegedMode(True);
	
	AdditionalDataProcessor = GetAdditionalDataProcessorObject(AdditionalDataProcessorRef, SafeMode);
	
	DataProcessorsType = AdditionalDataProcessorRef.Type;
	
	If DataProcessorsType = Enums.AdditionalReportAndDataProcessorTypes.AdditionalDataProcessor
	   Or DataProcessorsType = Enums.AdditionalReportAndDataProcessorTypes.AdditionalReport Then
		
		AdditionalDataProcessor.RunCommand(CommandID);
		
	ElsIf DataProcessorsType = Enums.AdditionalReportAndDataProcessorTypes.CreateLinkedObjects Then
		
		CreatedObjects = New Array;
		
		AdditionalDataProcessor.RunCommand(CommandID, DestinationObjects, CreatedObjects);
		
		ExecutionResult = New Array;
		
		For Each ObjectCreated In CreatedObjects Do
			Type = TypeOf(ObjectCreated);
			If ExecutionResult.Find(Type) = Undefined Then
				ExecutionResult.Add(Type);
			EndIf;
		EndDo;
		
	ElsIf DataProcessorsType = Enums.AdditionalReportAndDataProcessorTypes.ObjectFilling Then
		
		AdditionalDataProcessor.RunCommand(CommandID, DestinationObjects);
		
		ExecutionResult = New Array;
		
		For Each ModifiedObject In DestinationObjects Do
			Type = TypeOf(ModifiedObject);
			If ExecutionResult.Find(Type) = Undefined Then
				ExecutionResult.Add(Type);
			EndIf;
		EndDo;
		
	ElsIf DataProcessorsType = Enums.AdditionalReportAndDataProcessorTypes.AdditionalReport Then
		
		AdditionalDataProcessor.RunCommand(CommandID, DestinationObjects);
		
	ElsIf DataProcessorsType = Enums.AdditionalReportAndDataProcessorTypes.PrintForm Then
		
		AdditionalDataProcessor.Print(CommandID, DestinationObjects);
		
	EndIf;
	
EndProcedure

// Gets the data processor type from its string presentation
//
// Parameters:
//   TypeString - String - the presentation of the data processor type as string
//
// Returns:
//   EnumRef.AdditionalReportAndDataProcessorTypes - data processor kind
//
Function GetDataProcessorTypeByTypeString(TypeString) Export
	
	If	  TypeString = AdditionalReportsAndDataProcessorsClientServer.DataProcessorTypeObjectFilling() Then
		Return Enums.AdditionalReportAndDataProcessorTypes.ObjectFilling;
	ElsIf TypeString = AdditionalReportsAndDataProcessorsClientServer.DataProcessorTypeReport() Then
		Return Enums.AdditionalReportAndDataProcessorTypes.Report;
	ElsIf TypeString = AdditionalReportsAndDataProcessorsClientServer.DataProcessorTypePrintForm() Then
		Return Enums.AdditionalReportAndDataProcessorTypes.PrintForm;
	ElsIf TypeString = AdditionalReportsAndDataProcessorsClientServer.DataProcessorTypeCreatingRelatedObjects() Then
		Return Enums.AdditionalReportAndDataProcessorTypes.CreateLinkedObjects;
	ElsIf TypeString = AdditionalReportsAndDataProcessorsClientServer.DataProcessorTypeAdditionalDataProcessor() Then
		Return Enums.AdditionalReportAndDataProcessorTypes.AdditionalDataProcessor;
	ElsIf TypeString = AdditionalReportsAndDataProcessorsClientServer.DataProcessorTypeAdditionalReport() Then
		Return Enums.AdditionalReportAndDataProcessorTypes.AdditionalReport;
	EndIf;
	
EndFunction

// Creates the external data processor (report) instance by saving it as a file and
// opening as an external.
//
// Parameters:
//  AdditionalDataProcessorRef - CatalogRef.AdditionalReportsAndDataProcessors
//  SafeMode - Boolean - if data processor should be launched in safe mode
//
// Returns:
//   String - the data processor name in the system
//
Function GetAdditionalDataProcessorObject(AdditionalDataProcessorRef, SafeMode) Export
	
	AdditionalDataProcessorObject = AdditionalDataProcessorRef.GetObject();
	
	DataProcessorBinaryData = AdditionalDataProcessorObject.DataProcessorStorage.Get();
	
	TemporaryFileName = GetTempFileName("epf");
	
	DataProcessorBinaryData.Write(TemporaryFileName);
	
	If AdditionalDataProcessorObject.Type = Enums.AdditionalReportAndDataProcessorTypes.Report
	   Or AdditionalDataProcessorObject.Type = Enums.AdditionalReportAndDataProcessorTypes.AdditionalReport Then
		Return ExternalReports.Create(TemporaryFileName, SafeMode);
	Else
		Return ExternalDataProcessors.Create(TemporaryFileName, SafeMode);
	EndIf;
	
EndFunction

// Gets the command workspace name. First the data processor commands are searched if
// no command is found the report commands are searched.
//
// Parameters:
//  CommandName - String - the command name.
//
// Returns: 
//  String - the workspace name for the found command.
//
Function GetCommandWorkspaceName(CommandName) Export
	
	CommandsTable = AdditionalReportsAndDataProcessorsOverrided.GetAdditionalDataProcessorCommonCommands();
	
	Founds = CommandsTable.FindRows(New Structure("CommandName", CommandName));
	
	If Founds.Count() = 0 Then
		CommandsTable = AdditionalReportsAndDataProcessorsOverrided.GetAdditionalReportCommonCommands();
		Founds = CommandsTable.FindRows(New Structure("CommandName", CommandName));
	EndIf;
	
	Return Founds[0].WorkspaceName;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// AUXILIARY PROCEDURES AND FUNCTIONS

Procedure StartDataProcessorExecution(AdditionalDataProcessorRef, CommandID)
	
	MessageText = StringFunctionsClientServer.SubstitureParametersInString(
		NStr("en = 'Running the handler. Command: %1.'"),
		CommandID);
	
	WriteEventToEventLog(AdditionalDataProcessorRef, MessageText);
	
EndProcedure

Procedure FinishDataProcessorExecution(AdditionalDataProcessorRef, CommandID)
	
	MessageText = StringFunctionsClientServer.SubstitureParametersInString(
		NStr("en = 'Result from the handler. Command: %1.'"),
		CommandID);
	
	WriteEventToEventLog(AdditionalDataProcessorRef, MessageText);
	
EndProcedure

Procedure WriteEventToEventLog(AdditionalDataProcessorRef, MessageText)
	
	WriteLogEvent(NStr("en = 'Additional reports and data processors'"),
				  EventLogLevel.Information,
				  AdditionalDataProcessorRef.Metadata(),
				  AdditionalDataProcessorRef,
				  MessageText);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// INFOBASE UPDATE HANDLERS

// Updates information register records about accessibility of additional data
// processors
//
// Parameters:
//  No.
//
// Returns: 
//  No.
//
Procedure UpdateDataProcessorsAccessUserSettings() Export
	
	UsersWithAdditionalDataProcessors = GetUsersArrayWithAccessToAdditionalDataProcessors();
	
	RecordsTable = GetRecordsTable(UsersWithAdditionalDataProcessors);
	
	For Each User In UsersWithAdditionalDataProcessors Do
		RecordSet = InformationRegisters.DataProcessorsAccessUserSettings.CreateRecordSet();
		RecordSet.Filter.User.Set(User);
		RapidAccessRecords = RecordsTable.FindRows(New Structure("User,Available", User, True));
		For Each RapidAccessRecord In RapidAccessRecords Do
			NewRecord = RecordSet.Add();
			NewRecord.AdditionalReportOrDataProcessor = RapidAccessRecord.DataProcessor;
			NewRecord.CommandID			= RapidAccessRecord.Id;
			NewRecord.User				= User;
			NewRecord.Available			= True;
		EndDo;
		RecordSet.Write(True);
	EndDo;
	
EndProcedure

Function GetRecordsTable(UsersWithAdditionalDataProcessors)
	
	QueryText = "SELECT
	            |	AdditionalReportsAndDataProcessors.Ref AS DataProcessor,
	            |	CommandsOfAdditionalReportsAndDataProcessors.ID AS Id
	            |FROM
	            |	Catalog.AdditionalReportsAndDataProcessors AS AdditionalReportsAndDataProcessors
	            |		INNER JOIN Catalog.AdditionalReportsAndDataProcessors.Commands AS CommandsOfAdditionalReportsAndDataProcessors
	            |		ON (CommandsOfAdditionalReportsAndDataProcessors.Ref = AdditionalReportsAndDataProcessors.Ref)";
	
	Query = New Query;
	Query.Text = QueryText;
	DataProcessorsWithCommands = Query.Execute().Unload();
	
	RecordsTable = New ValueTable;
	RecordsTable.Columns.Add("DataProcessor", New TypeDescription("CatalogRef.AdditionalReportsAndDataProcessors"));
	RecordsTable.Columns.Add("Id", 	  	      New TypeDescription("String"));
	RecordsTable.Columns.Add("User",  		  New TypeDescription("CatalogRef.Users"));
	RecordsTable.Columns.Add("Available",     New TypeDescription("Boolean"));
	
	For Each DataProcessorCommand In DataProcessorsWithCommands Do
		For Each User In UsersWithAdditionalDataProcessors Do
			NewRow 				 = RecordsTable.Add();
			NewRow.DataProcessor = DataProcessorCommand.DataProcessor;
			NewRow.Id 			 = DataProcessorCommand.Id;
			NewRow.User			 = User;
			NewRow.Available     = True;
		EndDo;
	EndDo;
	
	QueryText = "SELECT
	            |	AdditionalReportsAndDataProcessors.Ref AS DataProcessor,
	            |	CommandsOfAdditionalReportsAndDataProcessors.ID AS Id,
	            |	Users.Ref AS User,
	            |	DataProcessorsAccessUserSettings.Available AS Available
	            |FROM
	            |	Catalog.AdditionalReportsAndDataProcessors AS AdditionalReportsAndDataProcessors
	            |		INNER JOIN Catalog.AdditionalReportsAndDataProcessors.Commands AS CommandsOfAdditionalReportsAndDataProcessors
	            |		ON (CommandsOfAdditionalReportsAndDataProcessors.Ref = AdditionalReportsAndDataProcessors.Ref)
	            |		INNER JOIN InformationRegister.DataProcessorsAccessUserSettings AS DataProcessorsAccessUserSettings
	            |		ON (DataProcessorsAccessUserSettings.AdditionalReportOrDataProcessor = AdditionalReportsAndDataProcessors.Ref)
	            |			AND (DataProcessorsAccessUserSettings.CommandID = CommandsOfAdditionalReportsAndDataProcessors.ID)
	            |		INNER JOIN Catalog.Users AS Users
	            |		ON (Users.Ref = DataProcessorsAccessUserSettings.User)";
	
	Query = New Query;
	Query.Text = QueryText;
	PersonalAccessExceptions = Query.Execute().Unload();
	
	For Each PersonalAccessException In PersonalAccessExceptions Do
		
		String = RecordsTable.FindRows(New Structure("DataProcessor,Id,User",
												PersonalAccessException.DataProcessor,
												PersonalAccessException.Id,
												PersonalAccessException.User))[0];
		
		String.Available = Not PersonalAccessException.Available; // previously this value was an access exception, inverting it
		
	EndDo;
	
	Return RecordsTable;
	
EndFunction

Function GetUsersArrayWithAccessToAdditionalDataProcessors()
	
	Result = New Array;
	
	QueryText = "SELECT
	            |	Users.Ref
	            |FROM
	            |	Catalog.Users AS Users";
	
	Query = New Query;
	Query.Text = QueryText;
	
	AllUsers = Query.Execute().Unload().UnloadColumn("Ref");
	
	For Each User In AllUsers Do
		
		IBUser = InfobaseUsers.FindByUUID(User.IBUserID);
		
		If IBUser <> Undefined Then
			If IBUser.Roles.Contains(Metadata.Roles.UseAdditionalReportsAndDataProcessors)
			   Or IBUser.Roles.Contains(Metadata.Roles.AddChangeAdditionalReportsAndDataProcessors)
			   Or IBUser.Roles.Contains(Metadata.Roles.FullAccess) Then
				Result.Add(User);
			EndIf;
		EndIf;
		
	EndDo;
	
	QueryText = "SELECT DISTINCT
	            |	DataProcessorsAccessUserSettings.User
	            |FROM
	            |	InformationRegister.DataProcessorsAccessUserSettings AS DataProcessorsAccessUserSettings
	            |WHERE
	            |	NOT DataProcessorsAccessUserSettings.User IN (&UsersArray)";
	
	Query = New Query;
	Query.Text = QueryText;
	Query.Parameters.Insert("UsersArray", Result);
	
	UsersInRegister = Query.Execute().Unload().UnloadColumn("User");
	
	For Each User In UsersInRegister Do
		Result.Add(User);
	EndDo;
	
	Return Result;
	
EndFunction

///////////////////////////////////////////////////////////////////////////////////////////
// Service functions which are used in AdditionalReportsAndDataProcessorsOverrided
// common module.
//

// Service function which is used to define the structure of table of workspace names
// for global additional reports and data processors
//
// Parameters:
//  No.
//
// Returns:
//  ValueTable with following columns:
//  	CommandName - String
//  	WorkspaceName - String
//
Function CreateCommandsTable() Export
	
	Table = New ValueTable;
	
	Table.Columns.Add("CommandName", New TypeDescription("String"));
	Table.Columns.Add("WorkspaceName", New TypeDescription("String"));
	
	Return Table;
	
EndFunction

// Service procedure which is used to add a new row with the workspace description to the
// commands table for global additional reports and data processors
//
// Parameters:
//  CommandsTable - ValueTable - the structure of this table is generated using 
//		CreateCommandsTable()
//  CommandName - String - the related common command name
//  WorkspaceName - String - the user-friendly presentation of the workspace
//
Procedure AddCommand(CommandsTable, CommandName, WorkspaceName) Export
	
	NewRow = CommandsTable.Add();
	NewRow.CommandName = CommandName;
	NewRow.WorkspaceName = WorkspaceName;
	
EndProcedure
