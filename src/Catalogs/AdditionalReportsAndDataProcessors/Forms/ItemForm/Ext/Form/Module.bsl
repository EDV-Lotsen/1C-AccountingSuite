
////////////////////////////////////////////////////////////////////////////////
// FORM EVENT HANDLERS
//

&AtServer
Procedure OnCreateAtServer(Cancellation, StandardProcessing)
	
	RegistrationOfDataProcessor = False;
	
	If Object.Ref = Catalogs.AdditionalReportsAndDataProcessors.EmptyRef() Then
		IsNewObject = True;
	Else
		IsNewObject = False;
		If AdditionalReportsAndDataProcessors.IsAssignedDataProcessorType(Object.Type) Then
			FullAssignmentsValue = AdditionalReportsAndDataProcessors.GetAllAssignmentsByAdditionalDataProcessorType(Object.Type);
			ValueToFormAttribute(FullAssignmentsValue, "FullAssignments");
		EndIf;
	EndIf;
	
	FillCommands();
	
	SetFormItems();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancellation)
	
	If IsNewObject Then
		
		If NOT OpenDialogOfDataProcessorReportFileLoad() Then
			Cancellation = True;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancellation, CurrentObject, WriteParameters)
	
	If RegistrationOfDataProcessor Then
		CurrentObject.DataProcessorStorage = New ValueStorage(DataProcessorBinaryData , New Deflation(9));
		RegistrationOfDataProcessor = False;
	EndIf;
	
	If Object.Type = Enums.AdditionalReportAndDataProcessorTypes.AdditionalDataProcessor Then
		
		CurrentObject.AdditionalProperties.Insert("DataProcessorCommands", FormAttributeToValue("DataProcessorCommands"));
		
	EndIf;
	
EndProcedure

&AtClient
Procedure LoadReportProcessingFile(Command)
	
	OpenDialogOfDataProcessorReportFileLoad();
	
EndProcedure

&AtClient
Procedure UnloadReportProcessingFile(Command)
	
	If AttachFileSystemExtension() Then
		
		FileSaveDialog = New FileDialog(FileDialogMode.Save);
		FileSaveDialog.FullFileName = Object.FileName;
		FileSaveDialog.Filter = "External DataProcessors|*.epf|External reports|*.erf";
		FileSaveDialog.Multiselect = False;
		FileSaveDialog.Title = NStr("en = 'Specify file'");
		
		If FileSaveDialog.Choose() Then
			
			Address = PutDataProcessorFileToTemporaryStorage();
			
			If Address = Undefined Then
				DoMessageBox(NStr("en = 'There is no data to process.'"));
				Return;
			EndIf;
			
			FilesBeingReceived = New Array;
			FilesBeingReceived.Add(New TransferableFileDescription(, Address));
			
			FilesReceived = New Array;
			
			GetFiles(FilesBeingReceived, FilesReceived, FileSaveDialog.FullFileName, False);
		EndIf;
		
	Else
		
		Address = PutDataProcessorFileToTemporaryStorage();
		
		If Address = Undefined Then
			DoMessageBox(NStr("en = 'There is no data to process.'"));
			Return;
		EndIf;
		
		GetFile(Address, Object.FileName, True);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "ChooseMetadataObjects" Then
		
		Object.Assignments.Clear();
		
		For Each ItemParameter In Parameter Do
			
			// search passed destination in the full possible destination
			RowsFound = FullAssignments.FindRows(New Structure("FullMetadataObjectName", ItemParameter.Value));
			
			If RowsFound.Count() > 0 Then
				NewAssignments = Object.Assignments.Add();
				NewAssignments.FullMetadataObjectName = ItemParameter.Value;
			EndIf;
			
		EndDo;
		
		Modified = True;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SpecifyDataProcessorAssignments(Command)
	
	FilterByMetadataObjects = GetFilterByMetadataObjects(Object.Type);
	
	SelectedMetadataObjects = New ValueList;
	
	For Each ItemAssignments IN Object.Assignments Do
		SelectedMetadataObjects.Add(ItemAssignments.FullMetadataObjectName);
	EndDo;
	
	FormParameters = New Structure;
	
	FormParameters.Insert("FilterByMetadataObjects", FilterByMetadataObjects);
	FormParameters.Insert("SelectedMetadataObjects", SelectedMetadataObjects);
	
	OpenForm("CommonForm.ChooseMetadataObjects", FormParameters);
	
EndProcedure

&AtServerNoContext
Function GetFilterByMetadataObjects(DataProcessorKind)
	
	FilterByMetadataObjects = New ValueList;
	
	If		DataProcessorKind = Enums.AdditionalReportAndDataProcessorTypes.ObjectFilling Then
		CommonCommand = Metadata.CommonCommands.AdditionalReportsAndDataProcessorsFillObject;
		
	ElsIf	DataProcessorKind = Enums.AdditionalReportAndDataProcessorTypes.Report Then
		CommonCommand = Metadata.CommonCommands.AdditionalReportsAndDataProcessorsReports;
		
	ElsIf	DataProcessorKind = Enums.AdditionalReportAndDataProcessorTypes.PrintForm Then
		CommonCommand = Metadata.CommonCommands.AdditionalReportsAndDataProcessorsPrintForms;
		
	ElsIf	DataProcessorKind = Enums.AdditionalReportAndDataProcessorTypes.CreateLinkedObjects Then
		CommonCommand = Metadata.CommonCommands.AdditionalReportsAndDataProcessorsCreatingLinkedObjects;
	EndIf;
	
	For Each CommandParameterType In CommonCommand.CommandParameterType.Types() Do
		FilterByMetadataObjects.Add(Metadata.FindByType(CommandParameterType).FullName());
	EndDo;
	
	Return FilterByMetadataObjects;
	
EndFunction

&AtClient
Procedure ConfigureCommandSchedule(Command)
	
	CurrentData = Items.DataProcessorCommands.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If CurrentData.ItIsAllowed Then
		Cancellation = False;
		SetSchedule(CurrentData, Cancellation);
		If NOT Cancellation Then
			Modified = True;
		EndIf;
	Else
		DoMessageBox(NStr("en = 'Command is used only on client.
                           |Scheduled job can be set up only for commands executed on server.'"));
	EndIf;
	
EndProcedure

&AtClient
Procedure DataProcessorCommandsBeforeRowChange(Item, Cancellation)
	
	If Item.CurrentItem = Items.DataProcessorCommands.ChildItems.CommandsUse Then
		
		If NOT Item.CurrentData.ItIsAllowed Then
			
			Cancellation = True;
			DoMessageBox(NStr("en = 'Command is used only on client.
                               |Scheduled job can be set up only for commands executed on server.'"));
		ElsIf Item.CurrentData.SchedulePresentation1 = strScheduleNotDefined()Then
			
			SetSchedule(Items.DataProcessorCommands.CurrentData, Cancellation);
			
		EndIf;
		
	ElsIf Item.CurrentItem = Items.DataProcessorCommands.ChildItems.CommandsSchedule Then
		
		If NOT Item.CurrentData.ItIsAllowed Then
			Cancellation = True;
		EndIf;
		
	ElsIf Item.CurrentItem = Items.DataProcessorCommands.ChildItems.QuickAccessPresentation Then
		
		ConfigureQuickAccessCommonHandler(Item.CurrentData);
		Cancellation = True;
		
	EndIf
	
EndProcedure

&AtClient
Procedure CommandsScheduleStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Items.DataProcessorCommands.CurrentData;
	
	If NOT CurrentData.ItIsAllowed Then
		Return;
	EndIf;
	
	SetSchedule(CurrentData);
	
EndProcedure

&AtClient
Procedure SpecifySectionsOfCommandInterface(Command)
	
	Sections = New ValueList;
	
	For Each SectionItem In Object.Sections Do
		Sections.Add(SectionItem.SectionName);
	EndDo;
	
	Result = OpenFormModal("Catalog.AdditionalReportsAndDataProcessors.Form.FillOfSections",
						New Structure("Sections,DataProcessorKind", Sections, Object.Type));
	
	If TypeOf(Result) = Type("ValueList") Then
		Object.Sections.Clear();
		For Each SectionVal In Result Do
			NewRow = Object.Sections.Add();
			NewRow.SectionName = SectionVal.Value;
		EndDo;
		Modified = True;
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// AUXILIARY FUNCTIONS

&AtServer
// Gets data processor file from a temporary storage, tries to create object
// of the data processor (external report) and gets information from the data processor (report) object
//
Function RegisterDataProcessor(AddressInTemporaryStorage,
								FileName,
								FileExtension)
	
	DataProcessorBinaryData = GetFromTempStorage(AddressInTemporaryStorage);
	TemporaryFileName = GetTempFileName(FileExtension);
	DataProcessorBinaryData.Write(TemporaryFileName);
	
	Try
		If Upper(FileExtension) = "EPF" Then
			AdditionalDataProcessor = ExternalDataProcessors.Create(TemporaryFileName, True);
		Else
			AdditionalDataProcessor = ExternalReports.Create(TemporaryFileName, True);
		EndIf;
	Except
		CommonUseClientServer.MessageToUser(BriefErrorDescription(ErrorInfo()));
		Return False;
	EndTry;
	
	Try
		RegistrationData = AdditionalDataProcessor.AdditionalDataProcessorInfo();
	Except
		CommonUseClientServer.MessageToUser(
				NStr("en = 'The report might be outdated or additional:'")
					+ BriefErrorDescription(ErrorInfo()));
		Return False;
	EndTry;
	
	ObjectValue = FormAttributeToValue("Object");
	
	If Object.FileName = FileName
		And Object.Type = Enums.AdditionalReportAndDataProcessorTypes[RegistrationData.Type] Then
	// if this is a reregistration of the same data processor - do not clear the destination
	Else
		ObjectValue.Assignments.Clear();
	EndIf;
	
	// Initialization information about the data processor
	ObjectValue.Type = Enums.AdditionalReportAndDataProcessorTypes[RegistrationData.Type];
	ObjectValue.Description		= RegistrationData.Description;
	ObjectValue.Version			= RegistrationData.Version;
	ObjectValue.SafeMode		= RegistrationData.SafeMode;
	ObjectValue.Information		= RegistrationData.Information;
	
	// Define name of the data processor file
	ObjectValue.FileName = FileName;
	
	// If this is a new data processor or destination is not filled - assign destination from a data processor
	If (Object.Ref = Catalogs.AdditionalReportsAndDataProcessors.EmptyRef()
		 OR ObjectValue.Assignments.Count() = 0)
		And (ObjectValue.Type = Enums.AdditionalReportAndDataProcessorTypes.ObjectFilling
			OR ObjectValue.Type = Enums.AdditionalReportAndDataProcessorTypes.Report
			OR ObjectValue.Type = Enums.AdditionalReportAndDataProcessorTypes.PrintForm
			OR ObjectValue.Type = Enums.AdditionalReportAndDataProcessorTypes.CreateLinkedObjects)
		 THEN
		
		ObjectValue.UseForObjectForm = True;
		ObjectValue.UseForListForm = True;
		
		FullAssignmentsValue = AdditionalReportsAndDataProcessors.GetAllAssignmentsByAdditionalDataProcessorType(ObjectValue.Type);
		
		If RegistrationData.Property("Assignments") Then
			
			For Each ItemSpecifiedAssignments In RegistrationData.Assignments Do
				
				SplittedString = StringFunctionsClientServer.DecomposeStringIntoSubstringsArray(ItemSpecifiedAssignments, ".");
				
				If SplittedString[1] = "*" Then
					
					AssignmentssFound = FullAssignmentsValue.FindRows(New Structure("Class", SplittedString[0]));
					
					For Each ItemAssignmentsFound In AssignmentssFound Do
						NewRow = ObjectValue.Assignments.Add();
						NewRow.FullMetadataObjectName = ItemAssignmentsFound.FullMetadataObjectName;
					EndDo;
					
				Else
					
					If FullAssignmentsValue.FindRows(New Structure("FullMetadataObjectName", ItemSpecifiedAssignments)).Count() > 0 Then
						NewRow = ObjectValue.Assignments.Add();
						NewRow.FullMetadataObjectName = ItemSpecifiedAssignments;
					EndIf;
					
				EndIf;
				
			EndDo;
		EndIf;
		
		ObjectValue.Assignments.GroupBy("FullMetadataObjectName", "");
		
		ValueToFormAttribute(FullAssignmentsValue, "FullAssignments");
		
	EndIf;
	
	SavedCommands = ObjectValue.Commands.Unload();
	
	ObjectValue.Commands.Clear();
	
	// Initialize commands
	
	For Each ItemCommandDescription In RegistrationData.Commands Do
		
		NewRow = ObjectValue.Commands.Add();
		NewRow.Id			= ItemCommandDescription.Id;
		NewRow.Presentation	= ItemCommandDescription.Presentation;
		NewRow.Modifier		= ItemCommandDescription.Modifier;
		NewRow.ShowAlert 	= ItemCommandDescription.ShowAlert;
		
		If ItemCommandDescription.UsageVariant = "FormOpening" Then
			NewRow.StartVariant = Enums.AdditionalDataProcessorsUsageVariants.FormOpening;
		ElsIf ItemCommandDescription.UsageVariant = "CallClientMethod" Then
			NewRow.StartVariant = Enums.AdditionalDataProcessorsUsageVariants.CallClientMethod;
		ElsIf ItemCommandDescription.UsageVariant = "CallServerMethod" Then
			NewRow.StartVariant = Enums.AdditionalDataProcessorsUsageVariants.CallServerMethod;
		Else
			TextOfMessage = NStr("en = 'For the command %1 the launching method is not determined.'");
			TextOfMessage = StringFunctionsClientServer.SubstitureParametersInString(TextOfMessage, ItemCommandDescription.Presentation);
			Raise TextOfMessage;
		EndIf;
		
	EndDo;
	
	ObjectValue.Responsible = CommonUse.CurrentUser();
	
	ValueToFormAttribute(ObjectValue, "Object");
	
	SetFormItems(True);
	
	FillCommands(SavedCommands);
	
	Return True;
	
EndFunction

&AtServer
Procedure FillCommands(SavedCommands = Undefined)
	
	DataProcessorCommands.Clear();
	
	For Each ItemCommand In Object.Commands Do
		
		NewCommand = DataProcessorCommands.Add();
		
		NewCommand.Presentation = ItemCommand.Presentation;
		NewCommand.Id = ItemCommand.Id;
		
		If Object.Type = Enums.AdditionalReportAndDataProcessorTypes.AdditionalDataProcessor Then
			QueryTex = "SELECT
			           |	DataProcessorsAccessUserSettings.User AS User
			           |FROM
			           |	InformationRegister.DataProcessorsAccessUserSettings AS DataProcessorsAccessUserSettings
			           |WHERE
			           |	DataProcessorsAccessUserSettings.AdditionalReportOrDataProcessor = &AdditionalReportOrDataProcessor
			           |	AND DataProcessorsAccessUserSettings.CommandID = &CommandID
			           |	AND DataProcessorsAccessUserSettings.Available";
			Query = New Query;
			Query.Text = QueryTex;
			Query.Parameters.Insert("AdditionalReportOrDataProcessor", Object.Ref);
			Query.Parameters.Insert("CommandID", ItemCommand.Id);
			
			SetPrivilegedMode(True);
			
			Unload = Query.Execute().Unload();
			NewCommand.QuickAccessList.LoadValues(Unload.UnloadColumn("User"));
			
			NewCommand.QuickAccessPresentation = 
					GetStringOfUsersPresentationWithQuickAccess(
							NewCommand.QuickAccessList.Count());
			SetPrivilegedMode(False);
		EndIf;
		
		If Object.Type = Enums.AdditionalReportAndDataProcessorTypes.AdditionalDataProcessor
			And ItemCommand.StartVariant = Enums.AdditionalDataProcessorsUsageVariants.CallServerMethod Then
			
			// Can assign the schedule and specify use
			NewCommand.ItIsAllowed = True;
			
			ScheduledJobSet = False;
			
			If SavedCommands = Undefined Then
				// load commands from the object table
				ScheduledJobGUID = ItemCommand.ScheduledJobGUID;
			Else
				
				StringFound = SavedCommands.Find(ItemCommand.Id, "Id");
				
				If StringFound = Undefined Then
				// no correspondence found
				Else
					ScheduledJobGUID = StringFound.ScheduledJobGUID;
					SavedCommands.Delete(StringFound);
				EndIf;
				
			EndIf;
			
			If ValueIsFilled(ScheduledJobGUID) Then
				
				ScheduledJob = Catalogs.AdditionalReportsAndDataProcessors.FindScheduledJob(ScheduledJobGUID);
				
				If ScheduledJob = Undefined Then
					
					ItemCommand.ScheduledJobGUID = New Uuid("00000000-0000-0000-0000-000000000000");
					
				Else
					
					ItemCommand.ScheduledJobGUID = ScheduledJobGUID;
					
					NewCommand.SchedulePresentation1 = String(ScheduledJob.Schedule);
					NewCommand.Use					 = ScheduledJob.Use;
					NewCommand.Schedule.Add(ScheduledJob.Schedule);
					
					ScheduledJobSet = True;
				EndIf;
				
			EndIf;
			
			If NOT ScheduledJobSet Then
				NewCommand.SchedulePresentation1 = strScheduleNotDefined();
				NewCommand.Use	= False;
			EndIf;
			
		Else
			NewCommand.SchedulePresentation1 = NStr("en = 'Not applicable - the command is used only on client'");
			NewCommand.Use			= False;
			NewCommand.ItIsAllowed	= False;
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure SetFormItems(Registration = False)
	
	If Registration OR ValueIsFilled(Object.Ref)Then
		
		If Object.Type = Enums.AdditionalReportAndDataProcessorTypes.AdditionalDataProcessor 
		 OR Object.Type = Enums.AdditionalReportAndDataProcessorTypes.AdditionalReport Then
					
			Items.DataProcessorCommands.ChildItems.CommandsSchedule.Visible = True;
			Items.DataProcessorCommands.ChildItems.CommandsUse.Visible = True;
			
			Items.PagesSectionsAssignments.CurrentPage =
				Items.PageSections;
			
		ElsIf AdditionalReportsAndDataProcessors.IsAssignedDataProcessorType(Object.Type) Then
			
			Items.DataProcessorCommands.ChildItems.CommandsSchedule.Visible = False;
			Items.DataProcessorCommands.ChildItems.CommandsUse.Visible = False;
			
			Items.PagesSectionsAssignments.CurrentPage = Items.PageAssignments;
				
			Items.DataProcessorCommandsConfigureQuickAccessToCommand.Visible = False;
			Items.DataProcessorCommandsConfigureCommandSchedule.Visible = False;
			
			Items.DataProcessorCommands.ChildItems.QuickAccessPresentation.Visible = False;
			
		EndIf;
		
		If Object.SafeMode Then
			Items.GroupAdditionalData.CurrentPage = Items.GroupInformation;
		Else
			Items.GroupAdditionalData.CurrentPage = Items.GroupWarning;
		EndIf;
		
		If IsNewObject Then
			If Object.Type = Enums.AdditionalReportAndDataProcessorTypes.AdditionalReport
			 OR Object.Type = Enums.AdditionalReportAndDataProcessorTypes.Report Then
				Title = NStr("en = 'Additional Report (Creating)'");
			Else
				Title = NStr("en = 'Additional Data Processor (Creating)'");
			EndIf;
		Else
			If Object.Type = Enums.AdditionalReportAndDataProcessorTypes.AdditionalReport
			 OR Object.Type = Enums.AdditionalReportAndDataProcessorTypes.Report Then
				Title = Object.Description + " " + NStr("en = '(Additional Report)'");
			Else
				Title = Object.Description + " " + NStr("en = '(Additional Data Processor)'");
			EndIf;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ConfigureQuickAccessCommonHandler(CurrentData)
	
	Id = CurrentData.Id;
	
	CurrentDataCollectionItem = DataProcessorCommands.FindRows(New Structure("Id", Id))[0];
	
	Result = OpenFormModal("Catalog.AdditionalReportsAndDataProcessors.Form.QuickAccessToAdditionalReportsAndDataProcessors",
					New Structure("UsersWithQuickAccess, CommandPresentation", 
									CurrentDataCollectionItem.QuickAccessList,
									CurrentData.Presentation));
	
	If TypeOf(Result) = Type("ValueList") Then
		CurrentDataCollectionItem.QuickAccessList.Clear();
		For Each ItemUser In Result Do
			CurrentDataCollectionItem.QuickAccessList.Add(ItemUser.Value);
		EndDo;
		Modified = True;
	EndIf;
	
	CurrentDataCollectionItem.QuickAccessPresentation =
			GetStringOfUsersPresentationWithQuickAccess(CurrentDataCollectionItem.QuickAccessList.Count());
	
EndProcedure

&AtServer
Function PutDataProcessorFileToTemporaryStorage()
	
	If RegistrationOfDataProcessor Then
		Return PutToTempStorage(DataProcessorBinaryData);
	EndIf;
	
	If Object.Ref = Catalogs.AdditionalReportsAndDataProcessors.EmptyRef() Then
		Return Undefined;
	EndIf;
	
	Value = FormAttributeToValue("Object").DataProcessorStorage.Get();
	
	If TypeOf(Value) <> Type("BinaryData") Then
		Return Undefined;
	EndIf;
	
	Return PutToTempStorage(Value);
	
EndFunction

&AtClient
Function OpenDialogOfDataProcessorReportFileLoad()
	
	If AttachFileSystemExtension() Then
		
		FileOpenDialog = New FileDialog(FileDialogMode.Open);
		FileOpenDialog.FullFileName = Object.FileName;
		FileOpenDialog.Filter = "External DataProcessors (*.epf)|*.epf|External reports (*.erf)|*.erf";
		FileOpenDialog.Multiselect = False;
		FileOpenDialog.Title = NStr("en = 'Select the file'");
		
		FilesBeingPlaced = New Array;
		PlacedFiles = New Array;
		
		If PutFiles(FilesBeingPlaced, PlacedFiles, FileOpenDialog, True) Then
			SubstringsArray = StringFunctionsClientServer.DecomposeStringIntoSubstringsArray(PlacedFiles[0].Name, "\");
			FileName = SubstringsArray.Get(SubstringsArray.UBound());
			FileExtension = Right(FileName, 3);
			
			If Not RegisterDataProcessor(PlacedFiles[0].Location, FileName, FileExtension) Then
				Return False;
			EndIf;
		Else
			Return False;
		EndIf;
	Else
		
		AddressInTemporaryStorage = "";
		SelectedFileName = "";
		
		If PutFile(AddressInTemporaryStorage, , SelectedFileName, True) Then
			
			SubstringsArray = StringFunctionsClientServer.DecomposeStringIntoSubstringsArray(SelectedFileName, "\");
			FileName = SubstringsArray.Get(SubstringsArray.UBound());
			FileExtension = Right(FileName, 3);
			
			If	  Upper(FileExtension) = "EPF" Then
			// external data processor
			ElsIf Upper(FileExtension) = "ERF" Then
			// external report
			Else
				DoMessageBox(NStr("en = 'It is impossible to detect the file type by extension'"));
				Return False;
			EndIf;
			
			If NOT RegisterDataProcessor(AddressInTemporaryStorage, FileName, FileExtension) Then
				Return False;
			EndIf;
		Else
			Return False;
		EndIf;
	
	EndIf;
	
	Modified = True;
	RegistrationOfDataProcessor = True;
	
	Return True;
	
EndFunction

&AtClient
Function ScheduledJobScheduleEdit(Schedule)
	
	If Schedule = Undefined Then
		
		Schedule = New JobSchedule;
		
	EndIf;
	
	Dialog = New ScheduledJobDialog(Schedule);
	
	// open dialog for schedule edit
	If Dialog.DoModal() Then
		
		Schedule = Dialog.Schedule;
		
	EndIf;
	
	Return Schedule;
	
EndFunction

&AtClient
Procedure SetSchedule(CurrentData, Cancellation = False)
	
	If CurrentData.Schedule.Count() > 0 Then
		Schedule = CurrentData.Schedule.Get(0).Value;
	Else
		Schedule = Undefined;
	EndIf;
	
	Schedule = ScheduledJobScheduleEdit(Schedule);
	
	CurrentData.Schedule.Clear();
	CurrentData.Schedule.Add(Schedule);
	
	CurrentData.SchedulePresentation1 = String(Schedule);
	
	If CurrentData.SchedulePresentation1 = EmptySchedulePresentation() Then
		CurrentData.SchedulePresentation1 = strScheduleNotDefined();
		CurrentData.Use = False;
		Cancellation = True;
	Else
		CurrentData.Use = True;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function EmptySchedulePresentation()
	
	Return String(New JobSchedule);
	
EndFunction

&AtClientAtServerNoContext
Function strScheduleNotDefined()
	
	Return NStr("en = 'The schedule is not set'");
	
EndFunction

&AtClient
Procedure ConfigureQuickAccess(Command)
	
	CurrentData = Items.DataProcessorCommands.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	ConfigureQuickAccessCommonHandler(CurrentData);
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancellation, CheckedAttributes)
	
	If AdditionalReportsAndDataProcessors.IsAssignedDataProcessorType(Object.Type) Then
		
		If NOT Object.UseForObjectForm And NOT Object.UseForListForm Then
			CommonUseClientServer.MessageToUser(
					NStr("en = 'It is required to indicate a data processor at least for one form'"),,,"Object.UseForObjectForm", Cancellation);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function GetStringOfUsersPresentationWithQuickAccess(NumberOfUsersWithQuickAccess)
	
	If NumberOfUsersWithQuickAccess = 0 Then
		
		QuickAccessPresentation = NStr("en = 'The command is not in quick access'");
		
	Else
		
		LastDigit = Number(Right(String(NumberOfUsersWithQuickAccess),1));
		
		If LastDigit = 1 Then
			QuickAccessPresentation = NStr("en = '%1 user'");
		ElsIf LastDigit = 2 Or LastDigit = 3 Or LastDigit = 4 Then
			QuickAccessPresentation = NStr("en = '%1 user'");
		Else
			QuickAccessPresentation = NStr("en = '%1 user'");
		EndIf;
		
		QuickAccessPresentation = StringFunctionsClientServer.SubstitureParametersInString(QuickAccessPresentation, String(NumberOfUsersWithQuickAccess))
		
	EndIf;
	
	Return QuickAccessPresentation;
	
EndFunction
