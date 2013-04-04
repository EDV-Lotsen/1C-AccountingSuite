
&AtServer
Procedure OnCreateAtServer(Cancellation, StandardProcessing)
	
	SectionName = Parameters.SectionName;
	
	DataProcessorsTypeString = Parameters.Type;
	
	If	  DataProcessorsTypeString = AdditionalReportsAndDataProcessorsClientServer.DataProcessorTypeObjectFilling() Then
		Title = NStr("en = 'Filling Objects Commands'");
	ElsIf DataProcessorsTypeString = AdditionalReportsAndDataProcessorsClientServer.DataProcessorTypeReport() Then
		Title = NStr("en = 'Reports'");
	ElsIf DataProcessorsTypeString = AdditionalReportsAndDataProcessorsClientServer.DataProcessorTypePrintForm() Then
		Title = NStr("en = 'Additional Print Forms'");
	ElsIf DataProcessorsTypeString = AdditionalReportsAndDataProcessorsClientServer.DataProcessorTypeCreatingRelatedObjects() Then
		Title = NStr("en = 'Commands of Creation of Linked Objects'");
	ElsIf DataProcessorsTypeString = AdditionalReportsAndDataProcessorsClientServer.DataProcessorTypeAdditionalDataProcessor() Then
		Title = NStr("en = 'Additional Data Processors ('") + AdditionalReportsAndDataProcessors.GetCommandWorkspaceName(SectionName) + ")";
	ElsIf DataProcessorsTypeString = AdditionalReportsAndDataProcessorsClientServer.DataProcessorTypeAdditionalReport()Then
		Title = NStr("en = 'Additional Reports ('") + AdditionalReportsAndDataProcessors.GetCommandWorkspaceName(SectionName) + ")";
	EndIf;
	
	DataProcessorsType = AdditionalReportsAndDataProcessors.GetDataProcessorTypeByTypeString(DataProcessorsTypeString);
	
	If DataProcessorsType = Enums.AdditionalReportAndDataProcessorTypes.AdditionalReport
	 OR DataProcessorsType = Enums.AdditionalReportAndDataProcessorTypes.Report Then
		Items.CustomizeQuickAccessList.Title = NStr("en = 'Customize the list of my reports'");
	Else
		Items.CustomizeQuickAccessList.Title = NStr("en = 'Customize the list of my data processors'");
	EndIf;
	
	IsGlobalDataProcessorTypes = AdditionalReportsAndDataProcessors.IsGlobalDataProcessorType(DataProcessorsType);
	
	ThisIsAppointedDataProcessors = AdditionalReportsAndDataProcessors.IsAssignedDataProcessorType(DataProcessorsType);
	
	If ThisIsAppointedDataProcessors Then
		
		Items.CustomizeQuickAccessList.Visible = False;
		
		DestinationObjects.LoadValues(Parameters.DestinationObjects.UnloadValues());
		DestinationObjRef = DestinationObjects.Get(0).Value;
		MetadataOfDestinationObj = DestinationObjects.Get(0).Value.Metadata();
		
		FullMetadataObjectName = MetadataOfDestinationObj.FullName();
		
		IsObjectForm = AdditionalReportsAndDataProcessors.IsObjectForm(FullMetadataObjectName, Parameters.FormName);
		
	EndIf;
	
	FillTableOfDataProcessors();
	
EndProcedure

&AtServer
Function GetAvailableCommands(ThisIsAppointedDataProcessors)
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	
	QueryText = "
			|SELECT
			|	AdditionalReportsAndDataProcessorsCommands.Presentation AS Presentation,
			|	AdditionalReportsAndDataProcessorsCommands.Id AS Id,
			|	AdditionalReportsAndDataProcessorsCommands.ShowAlert AS ShowAlert,
			|	AdditionalReportsAndDataProcessorsCommands.Modifier AS Modifier,
			|	CASE
			|		WHEN AdditionalReportsAndDataProcessorsCommands.StartVariant = VALUE(Enum.AdditionalDataProcessorsUsageVariants.CallClientMethod)
			|			THEN ""CallClientMethod""
			|		WHEN AdditionalReportsAndDataProcessorsCommands.StartVariant = VALUE(Enum.AdditionalDataProcessorsUsageVariants.CallServerMethod)
			|			THEN ""CallServerMethod""
			|		WHEN AdditionalReportsAndDataProcessorsCommands.StartVariant = VALUE(Enum.AdditionalDataProcessorsUsageVariants.FormOpening)
			|			THEN ""FormOpening""
			|	END AS StartVariant,
			|	AdditionalReportsAndDataProcessors.Ref			AS Ref,
			|	AdditionalReportsAndDataProcessors.SafeMode	AS SafeMode
			|FROM
			|	Catalog.AdditionalReportsAndDataProcessors AS AdditionalReportsAndDataProcessors
			|	JOIN Catalog.AdditionalReportsAndDataProcessors.Commands AS AdditionalReportsAndDataProcessorsCommands
			|			ON AdditionalReportsAndDataProcessorsCommands.Ref = AdditionalReportsAndDataProcessors.Ref";
	
	If ThisIsAppointedDataProcessors Then
		QueryText = QueryText + "
			|	JOIN Catalog.AdditionalReportsAndDataProcessors.Assignments AS AdditionalReportsAndDataProcessorsAssignments
			|			ON AdditionalReportsAndDataProcessorsAssignments.Ref = AdditionalReportsAndDataProcessors.Ref";
	Else
		QueryText = QueryText + "
			|	JOIN Catalog.AdditionalReportsAndDataProcessors.Sections AS AdditionalReportsAndDataProcessorsSections
			|			ON AdditionalReportsAndDataProcessorsSections.Ref = AdditionalReportsAndDataProcessors.Ref
			|	LEFT JOIN InformationRegister.DataProcessorsAccessUserSettings AS DataProcessorsAccessUserSettings
			|			ON DataProcessorsAccessUserSettings.AdditionalReportOrDataProcessor = AdditionalReportsAndDataProcessors.Ref
			|			 And DataProcessorsAccessUserSettings.CommandID = AdditionalReportsAndDataProcessorsCommands.Id
			|			 And DataProcessorsAccessUserSettings.User = &User";
		Query.Parameters.Insert("User", CommonUse.CurrentUser());
	EndIf;
	
	//////////////////////////
	// apply filters
	
	QueryText = QueryText + "
			|WHERE
			|	AdditionalReportsAndDataProcessors.Type = &DataProcessorsType
			|	And NOT AdditionalReportsAndDataProcessors.DeletionMark
			|	And (
			|		AdditionalReportsAndDataProcessors.Publication = VALUE(Enum.AdditionalReportsAndDataProcessorsPublicationVariants.InUse)";
			
	If IsInRole(Metadata.Roles.AddChangeAdditionalReportsAndDataProcessors)
		OR IsInRole(Metadata.Roles.FullAccess) Then
		QueryText = QueryText + "
			|	OR AdditionalReportsAndDataProcessors.Publication = VALUE(Enum.AdditionalReportsAndDataProcessorsPublicationVariants.DebugMode)";
	EndIf;
	
	QueryText = QueryText + "
									| )";
	
	If ThisIsAppointedDataProcessors Then
		QueryText = QueryText + "
			|	And AdditionalReportsAndDataProcessorsAssignments.FullMetadataObjectName LIKE &FullMetadataObjectName";
			
		Query.Parameters.Insert("FullMetadataObjectName", FullMetadataObjectName);
		
		If IsObjectForm Then
			QueryText = QueryText + "
			|	And AdditionalReportsAndDataProcessors.UseForObjectForm";
		Else
			QueryText = QueryText + "
			|	And AdditionalReportsAndDataProcessors.UseForListForm";
		EndIf;
		
	Else
		QueryText = QueryText + "
			|	And AdditionalReportsAndDataProcessorsSections.SectionName = &SectionName
			|	And DataProcessorsAccessUserSettings.Available";
		Query.Parameters.Insert("SectionName", SectionName);
	EndIf;
	
	Query.Text = QueryText;
	
	Query.Parameters.Insert("DataProcessorsType", DataProcessorsType);
	
	Return Query.Execute().Unload();
	
EndFunction

&AtClient
Procedure DataProcessorsSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	RunDataProcessorByParameters();
	
EndProcedure

&AtClient
Procedure RunDataProcessor(Command)
	
	RunDataProcessorByParameters()
	
EndProcedure

&AtClient
Procedure RunDataProcessorByParameters()
	
	CurrentData = Items.DataProcessors.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If IsGlobalDataProcessorTypes Then
		DestinationObjectsArray = Undefined;
	Else
		DestinationObjectsArray = DestinationObjects.UnloadValues();
	EndIf;
	
	AdditionalReportsAndDataProcessorsClient.RunDataProcessor(
					CurrentData.Ref,
					DataProcessorsTypeString,
					CurrentData.Id,
					CurrentData.SafeMode,
					CurrentData.StartVariant,
					CurrentData.ShowAlert,
					CurrentData.Modifier,
					DestinationObjectsArray);
	
	Close();
	
EndProcedure

&AtServer
Procedure FillTableOfDataProcessors()
	
	ValueToFormAttribute(GetAvailableCommands(ThisIsAppointedDataProcessors), "DataProcessors");
	
EndProcedure

&AtClient
Procedure Configure(Command)
	
	Result = OpenFormModal	("CommonForm.CurrentUserReportsAndDataProcessorsSetup",
		New Structure		("DataProcessorsType,IsGlobalDataProcessorTypes,CurrentSection", 
						DataProcessorsType,
						IsGlobalDataProcessorTypes,
						SectionName
						) );
	
	If TypeOf(Result) = Type("Boolean") Then
		FillTableOfDataProcessors();
	EndIf;
	
EndProcedure
