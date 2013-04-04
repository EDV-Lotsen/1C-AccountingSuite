
////////////////////////////////////////////////////////////////////////////////
// OBJECT EVENT HANDLERS

Procedure BeforeWrite(Cancellation)
	
	If NOT IsNew() Then
		
		ObjectInIB = Ref.GetObject();
		
		If Type <> ObjectInIB.Type Then
			CommonUseClientServer.MessageToUser(
					NStr("en = 'Additional report or data processor cannot be changed after object has been recorded into information base.'"),,,,
					Cancellation);
		EndIf;
		
	EndIf;
	
	If DeletionMark Then
		Publication = Enums.AdditionalReportsAndDataProcessorsPublicationVariants.NotInUse;
	EndIf;
	
	If IsFolder Then
		
	// do not process the folders
		
	ElsIf AdditionalReportsAndDataProcessors.IsAssignedDataProcessorType(Type) Then
		
		ResourceName = GetResourceNameByDataProcessorKind(Type);
		
		If IsNew() Then
			PreviousAssignments = New ValueTable;
			PreviousAssignments.Columns.Add("FullMetadataObjectName", New TypeDescription("String"));
		Else
			PreviousAssignments = ObjectInIB.Assignments;
		EndIf;
		
		Table = GroupingByField(PreviousAssignments, Assignments, "FullMetadataObjectName", "String");
		
		Deleted = Table.FindRows(New Structure("Flag1", -1));
		Added = Table.FindRows(New Structure("Flag1", 1));
		Remaining = Table.FindRows(New Structure("Flag1", 0));
		
		If PreviousAssignments.Count() > 0 Then
			
			ArrayOfDeleted = New Array;
			
			For Each DeletedItem In Deleted Do
				ArrayOfDeleted.Add(DeletedItem.FullMetadataObjectName);
			EndDo;
			
			If ObjectInIB.UseForObjectForm Then
				GroupRegisterOfAccessibilityReportsAndDataProcessors(ArrayOfDeleted, Ref, Type, ResourceName, "ObjectForm");
			EndIf;
			
			If ObjectInIB.UseForListForm Then
				GroupRegisterOfAccessibilityReportsAndDataProcessors(ArrayOfDeleted, Ref, Type, ResourceName, "ListForm");
			EndIf;
			
		EndIf; // PreviousAssignments.Count() > 0
		
		If Remaining.Count() > 0 Then
			
			If NOT ObjectInIB.UseForObjectForm And UseForObjectForm Then // include
				For Each StringAssignments In Remaining Do
					SetCommandAccessibility(StringAssignments.FullMetadataObjectName, "ObjectForm", ResourceName, True);
				EndDo;
			ElsIf ObjectInIB.UseForObjectForm And NOT UseForObjectForm Then
				ArrayOfReleased = New Array;
				For Each ItemBeingReleased In Remaining Do
					ArrayOfReleased.Add(ItemBeingReleased.FullMetadataObjectName);
				EndDo;
				GroupRegisterOfAccessibilityReportsAndDataProcessors(ArrayOfReleased, Ref, Type, ResourceName, "ObjectForm");
			EndIf;
			
			If NOT ObjectInIB.UseForListForm And UseForListForm Then // include
				For Each StringAssignments In Remaining Do
					SetCommandAccessibility(StringAssignments.FullMetadataObjectName, "ListForm", ResourceName, True);
				EndDo;
			ElsIf ObjectInIB.UseForListForm And NOT UseForListForm Then
				ArrayOfReleased = New Array;
				For Each ItemBeingReleased In Remaining Do
					ArrayOfReleased.Add(ItemBeingReleased.FullMetadataObjectName);
				EndDo;
				GroupRegisterOfAccessibilityReportsAndDataProcessors(ArrayOfReleased, Ref, Type, ResourceName, "ListForm");
			EndIf;
			
		EndIf;
		
		If Added.Count() > 0 Then
			
			If UseForObjectForm Then
				For Each StringAssignments In Added Do
					SetCommandAccessibility(StringAssignments.FullMetadataObjectName, "ObjectForm", ResourceName, True);
				EndDo;
			EndIf;
			
			If UseForListForm Then
				For Each StringAssignments In Added Do
					SetCommandAccessibility(StringAssignments.FullMetadataObjectName, "ListForm", ResourceName, True);
				EndDo;
			EndIf;
			
		EndIf;
		
	ElsIf Type = Enums.AdditionalReportAndDataProcessorTypes.AdditionalDataProcessor Then
		
		CommandsTable = Undefined;
		
		If AdditionalProperties.Property("DataProcessorCommands", CommandsTable) Then
		
			// transfer data about the scheduled jobs in commands into the object
			// and update scheduled jobs, if required
			For Each ItemCommand In CommandsTable Do
				
				If ItemCommand.Schedule.Count() > 0 Then
					Schedule = ItemCommand.Schedule.Get(0).Value;
				Else
					Schedule = EmptySchedulePresentation();
				EndIf;
				
				CommandInObject = Commands.FindRows(New Structure("Id", ItemCommand.Id))[0];
				
				If String(Schedule) = EmptySchedulePresentation() Then // maybe scheduled job has been deleted
					If ValueIsFilled(CommandInObject.ScheduledJobGUID) Then
						Catalogs.AdditionalReportsAndDataProcessors.DeleteScheduledJob(CommandInObject.ScheduledJobGUID);
						CommandInObject.ScheduledJobGUID = "";
					EndIf;
				Else
					Catalogs.AdditionalReportsAndDataProcessors.RefreshInfoOnSchedule(
								ThisObject, CommandInObject, Schedule, ItemCommand.Use, Cancellation);
				EndIf;
				
			EndDo; // For Each ItemCommand In CommandsTable Do
			
		EndIf; // If AdditionalProperties.Property("DataProcessorCommands", CommandsTable) Then
		
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancellation)
	
	CommandsTable = Undefined;
	
	If AdditionalProperties.Property("DataProcessorCommands", CommandsTable) Then
		
		SetPrivilegedMode(True);
		
		For Each ItemCommand In CommandsTable Do
			
			RecordSet = InformationRegisters.DataProcessorsAccessUserSettings.CreateRecordSet();
			RecordSet.Filter.AdditionalReportOrDataProcessor.Set(Ref);
			RecordSet.Filter.CommandID.Set(ItemCommand.Id);
			
			For Each ItemUser In ItemCommand.QuickAccessList Do
				Record = RecordSet.Add();
				Record.AdditionalReportOrDataProcessor = Ref;
				Record.CommandID = ItemCommand.Id;
				Record.User = ItemUser.Value;
				Record.Available = True;
			EndDo;
			
			RecordSet.Write(True);
			
		EndDo;
		
		SetPrivilegedMode(False);
		
	EndIf;
	
EndProcedure

Procedure BeforeDelete(Cancellation)
	
	If IsFolder Then
		
	// do not process the folders
		
	ElsIf AdditionalReportsAndDataProcessors.IsAssignedDataProcessorType(Type) Then
		
		ResourceName = GetResourceNameByDataProcessorKind(Type);
		
		ArrayOfDeleted = New Array;
		
		For Each ItemAssignments IN Assignments Do
			ArrayOfDeleted.Add(ItemAssignments.FullMetadataObjectName);
		EndDo;
		
		If UseForObjectForm Then
			GroupRegisterOfAccessibilityReportsAndDataProcessors(ArrayOfDeleted, Ref, Type, ResourceName, "ObjectForm");
		EndIf;
		
		If UseForListForm Then
			GroupRegisterOfAccessibilityReportsAndDataProcessors(ArrayOfDeleted, Ref, Type, ResourceName, "ListForm");
		EndIf;
		
	Else
		
		If Type = Enums.AdditionalReportAndDataProcessorTypes.AdditionalDataProcessor Then
			
			For Each ItemCommand In Commands Do
				
				Catalogs.AdditionalReportsAndDataProcessors.DeleteScheduledJob(ItemCommand.ScheduledJobGUID);
				
			EndDo;
			
		EndIf;
	EndIf;
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	ScheduledJobGUID = "";
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	ScheduledJobGUID = "";
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// AUXILIARY FUNCTIONS

Function GroupingByField(Table1, Table2, FieldName, TypeNameFields)
	
	Table = GetComparisonTable(FieldName, TypeNameFields);
	
	For Each ItemFullName In Table1.UnloadColumn(FieldName) Do
		NewRow = Table.Add();
		NewRow[FieldName] = ItemFullName;
		NewRow.Flag1 = -1;
	EndDo;
	
	For Each ItemFullName In Table2.UnloadColumn(FieldName) Do
		NewRow = Table.Add();
		NewRow[FieldName] = ItemFullName;
		NewRow.Flag1 = +1;
	EndDo;
	
	Table.GroupBy(FieldName, "Flag1");
	
	Return Table;
	
EndFunction

Function GetComparisonTable(ColumnName, TypeName)
	
	ValueTable = New ValueTable;
	
	ValueTable.Columns.Add(ColumnName, New TypeDescription(TypeName));
	ValueTable.Columns.Add("Flag1", New TypeDescription("Number"));
	
	Return ValueTable;
	
EndFunction

Procedure SetCommandAccessibility(FullMetadataObjectName, FormType, ResourceName, Value)
	
	SetPrivilegedMode(True);
	
	RecordManager = InformationRegisters.AdditionalDataProcessorsAssociation.CreateRecordManager();
	RecordManager.ObjectType = FullMetadataObjectName;
	RecordManager.FormType = FormType;
	RecordManager.Read();
	RecordManager.ObjectType = FullMetadataObjectName;
	RecordManager.FormType = FormType;
	RecordManager[ResourceName] = Value;
	RecordManager.Write(True);
	
EndProcedure

Procedure GroupRegisterOfAccessibilityReportsAndDataProcessors(ArrayOfDeleted, Ref, Type, ResourceName, FormType)
	
	If ArrayOfDeleted.Count() = 0 Then
		Return;
	EndIf;
	
	QueryText = "
			|SELECT DISTINCT
			|	AssignmentsED.FullMetadataObjectName AS FullMetadataObjectName
			|FROM
			|	Catalog.AdditionalReportsAndDataProcessors.Assignments AS AssignmentsED
			|	JOIN
			|		Catalog.AdditionalReportsAndDataProcessors AS AdditionalReportsAndDataProcessors
			|			ON AssignmentsED.Ref = AdditionalReportsAndDataProcessors.Ref
			|WHERE
			|	AssignmentsED.FullMetadataObjectName In (&SetOfNames)
			|	And AdditionalReportsAndDataProcessors.Ref <> &Ref
			|	And AdditionalReportsAndDataProcessors.Type = &Type";
	
	If FormType = "ObjectForm" Then
		QueryText = QueryText + "
			|	And AdditionalReportsAndDataProcessors.UseForObjectForm";
	ElsIf FormType = "ListForm" Then
		QueryText = QueryText + "
			|	And AdditionalReportsAndDataProcessors.UseForListForm";
	EndIf;
	
	Query = New Query;
	Query.Text = QueryText;
	Query.Parameters.Insert("SetOfNames",	ArrayOfDeleted);
	Query.Parameters.Insert("Ref",			Ref);
	Query.Parameters.Insert("Type",			Type);
	
	NamesOfAllowed = Query.Execute().Unload().UnloadColumn("FullMetadataObjectName");
	
	For Each FullMetadataObjectName In ArrayOfDeleted Do
		If NamesOfAllowed.Find(FullMetadataObjectName) = Undefined Then
			SetCommandAccessibility(FullMetadataObjectName, FormType, ResourceName, False);
		EndIf;
	EndDo;
	
EndProcedure

Function GetResourceNameByDataProcessorKind(Type)
	
	ResourceName = Undefined;
	
	If Type = Enums.AdditionalReportAndDataProcessorTypes.ObjectFilling Then
		ResourceName = "UseObjectFilling";
	EndIf;
	
	If Type = Enums.AdditionalReportAndDataProcessorTypes.Report Then
		ResourceName = "UseReports";
	EndIf;
	
	If Type = Enums.AdditionalReportAndDataProcessorTypes.PrintForm Then
		ResourceName = "UsePrintForms";
	EndIf;
	
	If Type = Enums.AdditionalReportAndDataProcessorTypes.CreateLinkedObjects Then
		ResourceName = "UseLinkedObjectsCreating";
	EndIf;
	
	Return ResourceName;
	
EndFunction

Function EmptySchedulePresentation()
	
	Return String(New JobSchedule);
	
EndFunction
