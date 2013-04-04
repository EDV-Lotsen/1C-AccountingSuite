
////////////////////////////////////////////////////////////////////////////////
// FORM EVENT HANDLERS

&AtServer
Procedure OnCreateAtServer(Cancellation, StandardProcessing)
	
	DataProcessorsType = Parameters.DataProcessorsType;
	IsGlobalDataProcessorTypes = Parameters.IsGlobalDataProcessorTypes;
	CurrentSection = Parameters.CurrentSection;
	
	FillTreeOfDataProcessors(True,  "MyCommands");
	FillTreeOfDataProcessors(False, "CommandsSource");
	
EndProcedure

&AtClient
Procedure AddCommand(Command)
	
	CurrentData = Items.CommandsSource.CurrentData;
	
	If CurrentData <> Undefined And NOT IsBlankString(CurrentData.Id) Then
		AddCommandServer(CurrentData.DataProcessor, CurrentData.Id);
	EndIf;
	
EndProcedure

&AtClient
Procedure DeleteCommand(Command)
	
	CurrentData = Items.MyCommands.CurrentData;
	
	If CurrentData <> Undefined And NOT IsBlankString(CurrentData.Id) Then
		DeleteCommandServer(CurrentData.DataProcessor, CurrentData.Id);
	EndIf;
	
EndProcedure

&AtClient
Procedure AddAllCommands(Command)
	
	If IsGlobalDataProcessorTypes Then
		CommandsSourceItems = CommandsSource.GetItems();
		
		For Each StringSections In CommandsSourceItems Do
			ItemSection  = FindItemSection(MyCommands, StringSections.SectionName, StringSections.Description);
			CommandItems = StringSections.GetItems();
			For Each ItemCommand In CommandItems Do
				NewCommand = FindItemCommand(ItemSection.GetItems(), ItemCommand.Id);
				FillPropertyValues(NewCommand, ItemCommand);
			EndDo;
		EndDo;
	Else
		AddAllCommandsServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure DeleteAllCommands(Command)
	
	MyCommands.GetItems().Clear();
	
EndProcedure

&AtClient
Procedure OK(Command)
	
	WriteSetOfUserDataProcessors();
	Close(True);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// AUXILIARY FUNCTIONS

&AtServer
Function FillTreeOfDataProcessors(UserCommands, NameItemsOfTreeAttribute)
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	
	QueryText = "
			|SELECT";
	
	If IsGlobalDataProcessorTypes Then
		QueryText = QueryText + "
			|	AdditionalReportsAndDataProcessorsSections.SectionName AS SectionName,";
	EndIf;
	
	QueryText = QueryText + "
			|	AdditionalReportsAndDataProcessorsCommands.Presentation AS Description,
			|	AdditionalReportsAndDataProcessorsCommands.Id AS Id,
			|	AdditionalReportsAndDataProcessors.Ref			AS DataProcessor
			|FROM
			|	Catalog.AdditionalReportsAndDataProcessors AS AdditionalReportsAndDataProcessors
			|	JOIN Catalog.AdditionalReportsAndDataProcessors.Commands AS AdditionalReportsAndDataProcessorsCommands
			|			ON AdditionalReportsAndDataProcessorsCommands.Ref = AdditionalReportsAndDataProcessors.Ref";
	
	If IsGlobalDataProcessorTypes Then
		QueryText = QueryText + "
			|	JOIN Catalog.AdditionalReportsAndDataProcessors.Sections AS AdditionalReportsAndDataProcessorsSections
			|			ON AdditionalReportsAndDataProcessorsSections.Ref = AdditionalReportsAndDataProcessors.Ref";
	EndIf;
	
	If UserCommands Then
		QueryText = QueryText + "
			|	LEFT JOIN InformationRegister.DataProcessorsAccessUserSettings AS DataProcessorsAccessUserSettings
			|			ON DataProcessorsAccessUserSettings.AdditionalReportOrDataProcessor = AdditionalReportsAndDataProcessors.Ref
			|			 And DataProcessorsAccessUserSettings.CommandID = AdditionalReportsAndDataProcessorsCommands.Id
			|			 And DataProcessorsAccessUserSettings.User = &User";
	EndIf;
	
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
									
	If UserCommands Then
		QueryText = QueryText + "
			|	And DataProcessorsAccessUserSettings.Available";
	EndIf;
	
	If IsGlobalDataProcessorTypes Then
		QueryText = QueryText + "
			|TOTALS BY
			|	SectionName";
	EndIf;
	
	Query.Parameters.Insert("User", CommonUse.CurrentUser());
	
	Query.Text = QueryText;
	
	Query.Parameters.Insert("DataProcessorsType", DataProcessorsType);
	
	If IsGlobalDataProcessorTypes Then
		TreeOfCommands = Query.Execute().Unload(QueryResultIteration.ByGroups);
	Else
		CommandsTable = Query.Execute().Unload();
	EndIf;
	
	CommandsTree = FormAttributeToValue(NameItemsOfTreeAttribute);
	CommandsTree.Rows.Clear();
	
	OwnIndex = 0;
	IndexOf = 0;
	
	If IsGlobalDataProcessorTypes Then
		For Each StringSections In TreeOfCommands.Rows Do
			UpperLevelRow 				 = CommandsTree.Rows.Add();
			UpperLevelRow.SectionName 	 = StringSections.SectionName;
			UpperLevelRow.Description 	 = AdditionalReportsAndDataProcessors.GetCommandWorkspaceName(StringSections.SectionName);
			If UpperLevelRow.SectionName = CurrentSection Then
				OwnIndex = IndexOf;
			EndIf;
			For Each CommandString In StringSections.Rows Do
				CommandsDescriptionRow = UpperLevelRow.Rows.Add();
				FillPropertyValues(CommandsDescriptionRow, CommandString);
				IndexOf = IndexOf + 1;
			EndDo;
			IndexOf = IndexOf + 1;
		EndDo;
	Else
		For Each ItemCommand In CommandsTable Do
			NewRow = CommandsTree.Rows.Add();
			FillPropertyValues(NewRow, ItemCommand);
		EndDo;
	EndIf;
	
	ValueToFormAttribute(CommandsTree, NameItemsOfTreeAttribute);
	
	Items[NameItemsOfTreeAttribute].CurrentRow = OwnIndex;
	
EndFunction

&AtServer
Procedure AddCommandServer(DataProcessor, Id)
	
	MyCommandsTree = FormAttributeToValue("MyCommands");
	RowsFound = MyCommandsTree.Rows.FindRows(New Structure("DataProcessor,Id", DataProcessor, Id), True);
	If RowsFound.Count() > 0 Then
		Return;
	EndIf;
	
	CommandsSourceTree = FormAttributeToValue("CommandsSource");
	RowsFound = CommandsSourceTree.Rows.FindRows(New Structure("DataProcessor,Id", DataProcessor, Id), True);
		
	If IsGlobalDataProcessorTypes Then	
		For Each StringFound In RowsFound Do
			ItemSection = FindItemSection(MyCommands, StringFound.SectionName, StringFound.Parent.Description);
			NewCommand = ItemSection.GetItems().Add();
			FillPropertyValues(NewCommand, StringFound);
		EndDo;
	Else
		NewCommand = MyCommands.GetItems().Add();
		FillPropertyValues(NewCommand, RowsFound[0]);
	EndIf;
	
EndProcedure

&AtServer
Procedure AddAllCommandsServer()
	
	ValueToFormAttribute(FormAttributeToValue("CommandsSource"), "MyCommands");
	
EndProcedure

&AtServer
Procedure DeleteCommandServer(DataProcessor, Id)
	
	MyCommandsItems = MyCommands.GetItems();
	
	If IsGlobalDataProcessorTypes Then
		
		SectionsToBeDeleted = New Array;
		
		For Each StringSections In MyCommandsItems Do
			CommandItems = StringSections.GetItems();
			For Each CommandString In CommandItems Do
				If CommandString.DataProcessor = DataProcessor And CommandString.Id = Id Then
					CommandItems.Delete(CommandItems.IndexOf(CommandString));
					Break;
				EndIf;
			EndDo;
			If CommandItems.Count() = 0 Then
				SectionsToBeDeleted.Add(MyCommandsItems.IndexOf(StringSections));
			EndIf;
		EndDo;
		
		TableSectionsToBeDeleted = New ValueTable;
		TableSectionsToBeDeleted.Columns.Add("Partition", New TypeDescription("Number",New NumberQualifiers(10)));
		For Each SectionToBeDeleted In SectionsToBeDeleted Do
			String = TableSectionsToBeDeleted.Add();
			String.Partition = SectionToBeDeleted;
		EndDo;
		TableSectionsToBeDeleted.GroupBy("Partition");
		TableSectionsToBeDeleted.Sort("Partition Desc");
		
		SectionsToBeDeleted = TableSectionsToBeDeleted.UnloadColumn("Partition");
		
		For Each SectionToBeDeleted In SectionsToBeDeleted Do
			MyCommandsItems.Delete(SectionToBeDeleted);
		EndDo;
		
	Else
		
		For Each CommandString In MyCommandsItems Do
			If CommandString.DataProcessor = DataProcessor And CommandString.Id = Id Then
				MyCommandsItems.Delete(MyCommandsItems.IndexOf(CommandString));
				Break;
			EndIf;
		EndDo;
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function FindItemSection(FormDataCommands, SectionName, Description)
	
	Result = Undefined;
	
	For Each DataItem In FormDataCommands.GetItems() Do
		If DataItem.SectionName = SectionName Then
			Result = DataItem;
			Break;
		EndIf;
	EndDo;
	
	If Result = Undefined Then
		NewSection 				= FormDataCommands.GetItems().Add();
		NewSection.SectionName 	= SectionName;
		NewSection.Description 	= Description;
		Result 					= NewSection;
	EndIf;
	
	Return Result;
	
EndFunction

&AtClientAtServerNoContext
Function FindItemCommand(FormDataTreeItemCollection, Id)
	
	Result = Undefined;
	
	For Each DataItem In FormDataTreeItemCollection Do
		If DataItem.Id = Id Then
			Result = DataItem;
			Break;
		EndIf;
	EndDo;
	
	If Result = Undefined Then
		NewSection 	= FormDataTreeItemCollection.Add();
		Result 		= NewSection;
	EndIf;
	
	Return Result;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// WORK WITH REGISTER RECORDS OF DATAPROCESSOR USER ACCESSIBILITY

&AtServer
Procedure WriteSetOfUserDataProcessors()
	
	QueryText = "
			|SELECT
			|	AdditionalReportsAndDataProcessorsCommands.Id AS Id,
			|	AdditionalReportsAndDataProcessors.Ref				AS DataProcessor
			|FROM
			|	Catalog.AdditionalReportsAndDataProcessors AS AdditionalReportsAndDataProcessors
			|	JOIN Catalog.AdditionalReportsAndDataProcessors.Commands AS AdditionalReportsAndDataProcessorsCommands
			|			ON AdditionalReportsAndDataProcessorsCommands.Ref = AdditionalReportsAndDataProcessors.Ref
			|WHERE
			|	AdditionalReportsAndDataProcessors.Type = &DataProcessorsType";
	
	Query = New Query;
	Query.Parameters.Insert("DataProcessorsType", DataProcessorsType);
	Query.Text = QueryText;
	
	TableOfDataProcessors = Query.Execute().Unload();
	
	MyCommandsTree = FormAttributeToValue("MyCommands");
	
	TableOfMyCommands = GetTable();
	
	If IsGlobalDataProcessorTypes Then
		For Each StringSections In MyCommandsTree.Rows Do
			For Each CommandString In StringSections.Rows Do
				NewRow = TableOfMyCommands.Add();
				FillPropertyValues(NewRow, CommandString);
			EndDo;
		EndDo;
	Else
		For Each CommandString In MyCommandsTree.Rows Do
			NewRow = TableOfMyCommands.Add();
			FillPropertyValues(NewRow, CommandString);
		EndDo;
	EndIf;
	
	TableOfMyCommands.GroupBy("DataProcessor,Id");
	
	//----------------
	
	TableOfComparison = TableOfDataProcessors.Copy();
	TableOfComparison.Columns.Add("Flag1", New TypeDescription("Number", New NumberQualifiers(1)));
	For Each String In TableOfComparison Do
		String.Flag1 = -1;
	EndDo;
	
	For Each String In TableOfMyCommands Do
		NewRow = TableOfComparison.Add();
		FillPropertyValues(NewRow, String);
		NewRow.Flag1 = +1;
	EndDo;
	
	TableOfComparison.GroupBy("DataProcessor,Id", "Flag1");
	
	RowsForExceptionFromTheirList = TableOfComparison.FindRows(New Structure("Flag1", -1));
	RowsForAddToTheirList = TableOfComparison.FindRows(New Structure("Flag1", 0));
	
	BeginTransaction();
	
	Try
		DeleteCommandsFromTheirList(RowsForExceptionFromTheirList);
		AddCommandsToTheirList(RowsForAddToTheirList);
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

&AtServerNoContext
Procedure AddCommandsToTheirList(RowsForAddToTheirList)
	
	SetPrivilegedMode(True);
	
	For Each ItemRow In RowsForAddToTheirList Do
		
		Record 									= InformationRegisters.DataProcessorsAccessUserSettings.CreateRecordManager();
		Record.AdditionalReportOrDataProcessor	= ItemRow.DataProcessor;
		Record.CommandID 						= ItemRow.Id;
		Record.User								= CommonUse.CurrentUser();
		Record.Available						= True;
		
		Record.Write(True);
	EndDo;
	
EndProcedure

&AtServerNoContext
Procedure DeleteCommandsFromTheirList(RowsForExceptionFromTheirList)
	
	SetPrivilegedMode(True);
	
	For Each ItemRow In RowsForExceptionFromTheirList Do
		
		Record 									= InformationRegisters.DataProcessorsAccessUserSettings.CreateRecordManager();
		Record.AdditionalReportOrDataProcessor	= ItemRow.DataProcessor;
		Record.CommandID 						= ItemRow.Id;
		Record.User								= CommonUse.CurrentUser();
		Record.Read();
		Record.Delete();
		
	EndDo;
	
EndProcedure

&AtServerNoContext
Function GetTable()
	
	CommandsTable = New ValueTable;
	CommandsTable.Columns.Add("DataProcessor", New TypeDescription("CatalogRef.AdditionalReportsAndDataProcessors"));
	CommandsTable.Columns.Add("Id",			 New TypeDescription("String"));
	
	Return CommandsTable;
	
EndFunction
