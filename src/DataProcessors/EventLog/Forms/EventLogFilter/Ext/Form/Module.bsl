
/////////////////////////////////////////////////////////////////////////////////////////////////////
// AUXILIARY PROCEDURES AND FUNCTIONS
&AtServer
Procedure FillImportanceAndStatus()
	// Fill control Importance
	Importance.Add("Error",         String(EventLogLevel.Error));
	Importance.Add("Warning", 		String(EventLogLevel.Warning));
	Importance.Add("Information",   String(EventLogLevel.Information));
	Importance.Add("Note",     		String(EventLogLevel.Note));
	
	// Fill control TransactionStatus
	TransactionStatus.Add("NotApplicable", 	String(EventLogEntryTransactionStatus.NotApplicable));
	TransactionStatus.Add("Committed", 		String(EventLogEntryTransactionStatus.Committed));
	TransactionStatus.Add("Unfinished",   	String(EventLogEntryTransactionStatus.Unfinished));
	TransactionStatus.Add("RolledBack",     String(EventLogEntryTransactionStatus.RolledBack));
	
EndProcedure

&AtServer
Procedure FillFilterParameters()
	
	ListOfFilterParameters = Parameters.Filter;
	IsFilterByLevel  = False;
	IsFilterByStatus = False;
	
	For Each FilterParameter In ListOfFilterParameters Do
		ParameterName = FilterParameter.Presentation;
		Value     = FilterParameter.Value;
		
		If Upper(ParameterName) = Upper("StartDate") Then
			// StartDate
			FilterInterval.StartDate = Value;
			FilterIntervalStartDate  = Value;
			
		ElsIf Upper(ParameterName) = Upper("EndDate") Then
			// EndDate
			FilterInterval.EndDate = Value;
			FilterIntervalEndDate  = Value;
			
		ElsIf Upper(ParameterName) = Upper("User") Then
			// User
			ListOfUsers = Value;
			
		ElsIf Upper(ParameterName) = Upper("Event") Then
			// Event
			Events = Value;
			
		ElsIf Upper(ParameterName) = Upper("Computer") Then
			// Computer
			Computers = Value;
			
		ElsIf Upper(ParameterName) = Upper("ApplicationName") Then
			// ApplicationName
			Applications = Value;
			
		ElsIf Upper(ParameterName) = Upper("Comment") Then
			// Comment
			Comment = Value;
			
		ElsIf Upper(ParameterName) = Upper("Metadata") Then
			// Metadata
			Metadata = Value;
			
		ElsIf Upper(ParameterName) = Upper("Data") Then
			// Data
			Data = Value;
			
		ElsIf Upper(ParameterName) = Upper("DataPresentation") Then
			// DataPresentation
			DataPresentation = Value;
			
		ElsIf Upper(ParameterName) = Upper("TransactionID") Then
			// TransactionID
			TransactionID = Value;
			
		ElsIf Upper(ParameterName) = Upper("ServerName") Then
			// ServerName
			ActiveServers = Value;
			
		ElsIf Upper(ParameterName) = Upper("SessionNumber") Then
			// Seance
			Sessions = Value;
			StrSessions = "";
			For Each SessionNumber In Sessions Do
				StrSessions = StrSessions + ?(StrSessions = "", "", "; ") + SessionNumber;
			EndDo;
			
		ElsIf Upper(ParameterName) = Upper("Port") Then
			// Port
			MainIPPorts = Value;
			
		ElsIf Upper(ParameterName) = Upper("SyncPort") Then
			// SyncPort
			SyncPorts = Value;
			
		ElsIf Upper(ParameterName) = Upper("Level") Then
			// Level
			IsFilterByLevel = True;
			For Each ValueListItem In Importance Do
				If Value.FindByValue(ValueListItem.Value) <> Undefined Then
					ValueListItem.Check = True;
				EndIf;
			EndDo;
			
		ElsIf Upper(ParameterName) = Upper("TransactionStatus") Then
			// TransactionStatus
			IsFilterByStatus = True;
			For Each ValueListItem In TransactionStatus Do
				If Value.FindByValue(ValueListItem.Value) <> Undefined Then
					ValueListItem.Check = True;
				EndIf;
			EndDo;
			
		EndIf;
		
	EndDo;
	
	If Not IsFilterByLevel Then
		For Each ValueListItem In Importance Do
			ValueListItem.Check = True;
		EndDo;
	EndIf;
	
	If Not IsFilterByStatus Then
		For Each ValueListItem In TransactionStatus Do
			ValueListItem.Check = True;
		EndDo;
	EndIf;
		
	
EndProcedure

&AtClient
Function GetEventLogFilter()
	
	Sessions.Clear();
	Str = StrSessions;
	Str = StrReplace(Str, ";", " ");
	Str = StrReplace(Str, ",", " ");
	Str = TrimAll(Str);
	TS = New TypeDescription("Number");
	
	While Not IsBlankString(Str) Do
		Pos = Find(Str, " ");
		
		If Pos = 0 Then
			Value = TS.AdjustValue(Str);
			Str = "";
		Else
			Value = TS.AdjustValue(Left(Str, Pos-1));
			Str = TrimAll(Mid(Str, Pos+1));
		EndIf;
		
		If Value <> 0 Then
			Sessions.Add(Value);
		EndIf;
	EndDo;
	
	Filter = New ValueList;
	
	// Start, end date
	If FilterIntervalStartDate <> '00010101000000' Then 
		Filter.Add(FilterIntervalStartDate, "StartDate");
	EndIf;
	If FilterIntervalEndDate <> '00010101000000' Then
		Filter.Add(FilterIntervalEndDate, "EndDate");
	EndIf;
	
	// User
	If ListOfUsers.Count() > 0 Then 
		Filter.Add(ListOfUsers, "User");
	EndIf;
	
	// Event
	If Events.Count() > 0 Then 
		Filter.Add(Events, "Event");
	EndIf;
	
	// Computer
	If Computers.Count() > 0 Then 
		Filter.Add(Computers, "Computer");
	EndIf;
	
	// ApplicationName
	If Applications.Count() > 0 Then 
		Filter.Add(Applications, "ApplicationName");
	EndIf;
	
	// Comment
	If Not IsBlankString(Comment) Then 
		Filter.Add(Comment, "Comment");
	EndIf;
	
	// Metadata
	If Metadata.Count() > 0 Then 
		Filter.Add(Metadata, "Metadata");
	EndIf;
	
	// Data
	If (Data <> Undefined) And (Not Data.IsEmpty()) Then
		Filter.Add(Data, "Data");
	EndIf;
	
	// DataPresentation
	If Not IsBlankString(DataPresentation) Then 
		Filter.Add(DataPresentation, "DataPresentation");
	EndIf;
	
	// TransactionID
	If Not IsBlankString(TransactionID) Then 
		Filter.Add(TransactionID, "TransactionID");
	EndIf;
	
	// ServerName
	If ActiveServers.Count() > 0 Then 
		Filter.Add(ActiveServers, "ServerName");
	EndIf;
	
	// Seance
	If Sessions.Count() > 0 Then 
		Filter.Add(Sessions, "SessionNumber");
	EndIf;
	
	// Port
	If MainIPPorts.Count() > 0 Then 
		Filter.Add(MainIPPorts, "Port");
	EndIf;
	
	// SyncPort
	If SyncPorts.Count() > 0 Then 
		Filter.Add(SyncPorts, "SyncPort");
	EndIf;
	
	// Level
	LevelList = New ValueList;
	For Each ValueListItem In Importance Do
		If ValueListItem.Check Then 
			LevelList.Add(ValueListItem.Value, ValueListItem.Presentation);
		EndIf;
	EndDo;
	If LevelList.Count() > 0 And LevelList.Count() <> Importance.Count() Then
		Filter.Add(LevelList, "Level");
	EndIf;
	
	// TransactionStatus
	StatusList = New ValueList;
	For Each ValueListItem In TransactionStatus Do
		If ValueListItem.Check Then 
			StatusList.Add(ValueListItem.Value, ValueListItem.Presentation);
		EndIf;
	EndDo;
	If StatusList.Count() > 0 And StatusList.Count() <> TransactionStatus.Count() Then
		Filter.Add(StatusList, "TransactionStatus");
	EndIf;
	
	Return Filter;
	
EndFunction

/////////////////////////////////////////////////////////////////////////////////////////////////////
// EVENT HANDLERS
&AtServer
Procedure OnCreateAtServer(Cancellation, StandardProcessing)
	
	FillImportanceAndStatus();
	FillFilterParameters();
	
EndProcedure

&AtClient
Procedure ChoiceExecution(Item, ChoiceData, StandardProcessing)
	
	Var EditableList, FilteredParameters;
	
	StandardProcessing = False;
	
	PropertyContentEditorItemName = Item.Name;
	
	If PropertyContentEditorItemName = Items.Users.Name Then
		EditableList = ListOfUsers;
		FilteredParameters = "User";
	ElsIf PropertyContentEditorItemName = Items.Events.Name Then
		EditableList = Events;
		FilteredParameters = "Event";
	ElsIf PropertyContentEditorItemName = Items.Computers.Name Then
		EditableList = Computers;
		FilteredParameters = "Computer";
	ElsIf PropertyContentEditorItemName = Items.Applications.Name Then
		EditableList = Applications;
		FilteredParameters = "ApplicationName";
	ElsIf PropertyContentEditorItemName = Items.Metadata.Name Then
		EditableList = Metadata;
		FilteredParameters = "Metadata";
	ElsIf PropertyContentEditorItemName = Items.ActiveServers.Name Then
		EditableList = ActiveServers;
		FilteredParameters = "ServerName";
	ElsIf PropertyContentEditorItemName = Items.MainIPPorts.Name Then
		EditableList = MainIPPorts;
		FilteredParameters = "Port";
	ElsIf PropertyContentEditorItemName = Items.SyncPorts.Name Then
		EditableList = SyncPorts;
		FilteredParameters = "SyncPort";
	Else
		StandardProcessing = True;
		Return;
	EndIf;
	
	FormParameters = New Structure;
	
	FormParameters.Insert("EditableList", EditableList);
	FormParameters.Insert("FilteredParameters", FilteredParameters);
	
	// Opening of property editor
	OpenForm("DataProcessor.EventLog.Form.PropertyContentEditor",
	             FormParameters,
	             ThisForm);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	Var EditableList, FilteredParameters, StandardProcessing;
	
	If EventName = "EventLogFilterElementsValuesChoice"
	   And Source = ThisForm Then
		If PropertyContentEditorItemName = Items.Users.Name Then
			ListOfUsers = Parameter;
		ElsIf PropertyContentEditorItemName = Items.Events.Name Then
			Events = Parameter;
		ElsIf PropertyContentEditorItemName = Items.Computers.Name Then
			Computers = Parameter;
		ElsIf PropertyContentEditorItemName = Items.Applications.Name Then
			Applications = Parameter;
		ElsIf PropertyContentEditorItemName = Items.Metadata.Name Then
			Metadata = Parameter;
		ElsIf PropertyContentEditorItemName = Items.ActiveServers.Name Then
			ActiveServers = Parameter;
		ElsIf PropertyContentEditorItemName = Items.MainIPPorts.Name Then
			MainIPPorts = Parameter;
		ElsIf PropertyContentEditorItemName = Items.SyncPorts.Name Then
			SyncPorts = Parameter;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure SetFilterAndCloseForm(Command)
	
	Notify("EventLogFilterApplied",
	           GetEventLogFilter(),
	           FormOwner);
	Close();
	
EndProcedure


&AtClient
Procedure FilterIntervalOnChange(Item)
	
	FilterIntervalStartDate    = FilterInterval.StartDate;
	FilterIntervalEndDate = FilterInterval.EndDate;
	
EndProcedure

&AtClient
Procedure FilterIntervalDateOnChange(Item)
	
	FilterInterval.Variant       = StandardPeriodVariant.Custom;
	FilterInterval.StartDate    = FilterIntervalStartDate;
	FilterInterval.EndDate = FilterIntervalEndDate;
	
EndProcedure


