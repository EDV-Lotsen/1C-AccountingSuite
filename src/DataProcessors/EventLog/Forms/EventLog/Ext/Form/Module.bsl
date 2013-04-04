
//////////////////////////////////////////////////////////////////////////////////////////
// EVENT HANDLERS

&AtServer
Procedure OnCreateAtServer(Cancellation, StandardProcessing)
	
	EventLogFilter = New Structure;
	
	If Not IsBlankString(Parameters.User) Then
		
		UserName = Parameters.User;
		FilterByUser = New ValueList;
		ByUser = FilterByUser.Add(UserName);
		If IsBlankString(UserName) Then
			ByUser.Presentation = Users.FullNameOfNotSpecifiedUser();
		Else
			ByUser.Presentation = UserName;
		EndIf;
		
		EventLogFilter.Insert("User", FilterByUser);
		
	EndIf;
	
	If ValueIsFilled(Parameters.EventLogMessage) Then
		FilterByEvent = New ValueList;
		FilterByEvent.Add(Parameters.EventLogMessage, Parameters.EventLogMessage);
		EventLogFilter.Insert("Event", FilterByEvent);
	EndIf;
	
	If Parameters.Property("StartDate") Then
		EventLogFilter.Insert("StartDate", Parameters.StartDate);
	EndIf;
	
	If Parameters.Property("EndDate") Then
		EventLogFilter.Insert("EndDate", Parameters.EndDate);
	EndIf;
	
	NumberOfEventsDisplayed = 200;
	
	ReadEventLog(EventLogFilter);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "EventLogFilterApplied" And Source = ThisForm Then
		EventLogFilter.Clear();
		
		For Each ItemOfList In Parameter Do
			EventLogFilter.Insert(ItemOfList.Presentation, ItemOfList.Value);
		EndDo;
		
		RefreshCurrentList();
	EndIf;
	
EndProcedure


&AtClient
Procedure RefreshCurrentList() Export
	
	ReadEventLog(EventLogFilter);
	
	// Positioning in the end of the list
	If Log.Count() > 0 Then
		Items.Log.CurrentRow = Log[Log.Count() - 1].GetID();
	EndIf;
	
EndProcedure

&AtClient
Procedure ClearFilter()
	
	EventLogFilter.Clear();
	RefreshCurrentList();
	
EndProcedure

&AtClient
Procedure OpenDataForViewing()
	
	CurrentData = Items.Log.CurrentData;
	If CurrentData = Undefined Or CurrentData.Data = Undefined Then
		DoMessageBox(NStr("en = 'This record of log event is not connected to the data (see the column ""Data"")'"));
		Return;
	EndIf;
	
	Try
		OpenValue(CurrentData.Data);
	Except
		WarningText = NStr("en = 'This record of log event is connected with the data but cannot display it."
						   "%1'");
		If CurrentData.Event = "_$Data$_.Delete" Then 
			// this is a delete event
			WarningText =
					StringFunctionsClientServer.SubstitureParametersInString(
						WarningText,
						NStr("en = 'Data is deleted from IB'"));
		Else
			WarningText =
				StringFunctionsClientServer.SubstitureParametersInString(
						WarningText,
						NStr("en = 'The data might have been deleted form the database'"));
		EndIf;
		DoMessageBox(WarningText);
	EndTry;
	
EndProcedure

&AtClient
Procedure ViewCurrentEventsInIndividualWindow()
	
	Data = Items.Log.CurrentData;
	If Data = Undefined Then
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("Date",                    	Data.Date);
	FormParameters.Insert("UserName",         			Data.UserName);
	FormParameters.Insert("ApplicationPresentation", 	Data.ApplicationPresentation);
	FormParameters.Insert("Computer",               	Data.Computer);
	FormParameters.Insert("Event",                 		Data.Event);
	FormParameters.Insert("EventPresentation",    		Data.EventPresentation);
	FormParameters.Insert("Comment",             		Data.Comment);
	FormParameters.Insert("MetadataPresentation", 		Data.MetadataPresentation);
	FormParameters.Insert("Data",                  		Data.Data);
	FormParameters.Insert("DataPresentation",     		Data.DataPresentation);
	FormParameters.Insert("TransactionID",              Data.TransactionID);
	FormParameters.Insert("TransactionStatus",        	Data.TransactionStatus);
	FormParameters.Insert("Session",                   	Data.Session);
	FormParameters.Insert("ServerName",           		Data.ServerName);
	FormParameters.Insert("Port",          				Data.Port);
	FormParameters.Insert("SyncPort",   				Data.SyncPort);
	
	If ValueIsFilled(Data.DataAddress) Then
		FormParameters.Insert("DataAddress", Data.DataAddress);
	EndIf;
	
	OpenForm("DataProcessor.EventLog.Form.EventForm", FormParameters);
	
EndProcedure

&AtClient
Procedure SetDateIntervalForView()
	
	// Get current period
	StartDate    = Undefined;
	EndDate = Undefined;
	EventLogFilter.Property("StartDate", StartDate);
	EventLogFilter.Property("EndDate", EndDate);
	StartDate    = ?(TypeOf(StartDate)    = Type("Date"), StartDate, '00010101000000');
	EndDate = ?(TypeOf(EndDate) = Type("Date"), EndDate, '00010101000000');
	
	If IntervalOfDates.StartDate <> StartDate Then
		IntervalOfDates.StartDate = StartDate;
	EndIf;
	
	If IntervalOfDates.EndDate <> EndDate Then
		IntervalOfDates.EndDate = EndDate;
	EndIf;
	
	// Edit currernt period
	Dialog = New StandardPeriodEditDialog;
	Dialog.Period = IntervalOfDates;
	
	If Dialog.Edit() Then
		// Update current period
		IntervalOfDates = Dialog.Period;
		If IntervalOfDates.StartDate = '00010101000000' Then
			EventLogFilter.Delete("StartDate");
		Else
			EventLogFilter.Insert("StartDate", IntervalOfDates.StartDate);
		EndIf;
		If IntervalOfDates.EndDate = '00010101000000' Then
			EventLogFilter.Delete("EndDate");
		Else
			EventLogFilter.Insert("EndDate", IntervalOfDates.EndDate);
		EndIf;
		RefreshCurrentList();
	EndIf;
	
EndProcedure

&AtClient
Procedure SetFilter()
	
	FilterList = New ValueList;
	
	For Each StructureItem In EventLogFilter Do
		FilterList.Add(StructureItem.Value, StructureItem.Key);
	EndDo;
	
	FilterForm = OpenForm("DataProcessor.EventLog.Form.EventLogFilter",
	                           New Structure("Filter", FilterList),
	                           ThisForm);
	
EndProcedure

&AtClient
Procedure SetFilterByValueInCurrentColumn()
	
	Data = Items.Log.CurrentData;
	If Data = Undefined Then
		Return;
	EndIf;
	PresentationColumnName = Items.Log.CurrentItem.Name;
	If PresentationColumnName = "Date" Then
		Return;
	EndIf;
	SelectValue = Data[PresentationColumnName];
	Presentation  = Data[PresentationColumnName];
	
	FilterItemName = PresentationColumnName;
	If PresentationColumnName = "UserName" Then 
		FilterItemName = "User";
		SelectValue = Data["User"];
	ElsIf PresentationColumnName = "ApplicationPresentation" Then
		FilterItemName = "ApplicationName";
		SelectValue = Data["ApplicationName"];
	ElsIf PresentationColumnName = "EventPresentation" Then
		FilterItemName = "Event";
		SelectValue = Data["Event"];
	EndIf;
	
	// No filter by empty strings
	If TypeOf(SelectValue) = Type("String") And IsBlankString(SelectValue) Then
		// For default user name is empty, allow to filter
		If PresentationColumnName <> "UserName" Then 
			Return;
		EndIf;
	EndIf;
	
	CurrentValue = Undefined;
	If EventLogFilter.Property(FilterItemName, CurrentValue) Then
		// Filter is applied
		EventLogFilter.Delete(FilterItemName);
	Else
		If FilterItemName = "Data" Or          // non list filters, just 1 value
			 FilterItemName = "Comment" Or
			 FilterItemName = "TransactionID" Or
			 FilterItemName = "DataPresentation" Then 
			EventLogFilter.Insert(FilterItemName, SelectValue);
		Else
			FilterList = New ValueList;
			FilterList.Add(SelectValue, Presentation);
			EventLogFilter.Insert(FilterItemName, FilterList);
		EndIf;
	EndIf;
	
	RefreshCurrentList();
	
EndProcedure

&AtClient
Procedure NumberOfEventsDisplayedOnChange(Item)
	
	RefreshCurrentList();
	
EndProcedure

&AtClient
Procedure EventLogSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData = Items.Log.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If Field.Name = "Data" Or Field.Name = "DataPresentation" Then
		If CurrentData.Data <> Undefined And (TypeOf(CurrentData.Data) <> Type("String") And ValueIsFilled(CurrentData.Data)) Then
			OpenDataForViewing();
			Return;
		EndIf;
	EndIf;
	
	If Field.Name = "Date" Then
		SetDateIntervalForView();
		Return;
	EndIf;
	
	ViewCurrentEventsInIndividualWindow();
	
EndProcedure

///////////////////////////////////////////////////////////////////////////////////////////////
// Auxiliary procedures

&AtServer
Procedure ReadEventLog(Val EventLogFilterAtClient)
	
	// Delete temporary data prepared earlier
	DescriptionOfAddresses = Log.Unload(, "DataAddress");
	DescriptionOfAddresses.GroupBy("DataAddress");
	For each Address In DescriptionOfAddresses.UnloadColumn("DataAddress") Do
		If ValueIsFilled(Address) Then
			DeleteFromTempStorage(Address);
		EndIf;
	EndDo;
	
	// Prepare filter
	Filter = New Structure;
	For Each FilterItem In EventLogFilterAtClient Do
		Filter.Insert(FilterItem.Key, FilterItem.Value);
	EndDo;
	FilterConversion(Filter);
	
	// Unload filtered events
	LogEvents = New ValueTable;
	UnloadEventLog(LogEvents, Filter, , , NumberOfEventsDisplayed);
	LogEvents.Columns.Add("PictureNumber", New TypeDescription("Number"));
	LogEvents.Columns.Add("DataAddress",  New TypeDescription("String"));
	
	// Fill picture numbers of rows
	For Each LogEvent In LogEvents Do
		
		// Set relative picture number
		If LogEvent.Level = EventLogLevel.Information Then
			LogEvent.PictureNumber = 0;
		ElsIf LogEvent.Level = EventLogLevel.Warning Then
			LogEvent.PictureNumber = 1;
		ElsIf LogEvent.Level = EventLogLevel.Error Then
			LogEvent.PictureNumber = 2;
		Else
			LogEvent.PictureNumber = 3;
		EndIf;
		// Set absolute picture number
		If LogEvent.TransactionStatus = EventLogEntryTransactionStatus.Unfinished
		 OR LogEvent.TransactionStatus = EventLogEntryTransactionStatus.RolledBack Then
			LogEvent.PictureNumber = LogEvent.PictureNumber + 4;
		EndIf;
		
		// Transform metadata array to value list
		ListOfMetadataPresentations = New ValueList;
		If TypeOf(LogEvent.MetadataPresentation) = Type("Array") Then
			ListOfMetadataPresentations.LoadValues(LogEvent.MetadataPresentation);
		Else
			ListOfMetadataPresentations.Add(String(LogEvent.MetadataPresentation));
		EndIf;
		LogEvent.MetadataPresentation = ListOfMetadataPresentations;
		
		// Processing data of special events
		If LogEvent.Event = "_$Access$_.Access" Then
			LogEvent.DataAddress = PutToTempStorage(LogEvent.Data, Uuid);
			LogEvent.Data = ?(LogEvent.Data.Data = Undefined, "", "...");
			
		ElsIf LogEvent.Event = "_$Access$_.AccessDenied" Then
			LogEvent.DataAddress = PutToTempStorage(LogEvent.Data, Uuid);
			If LogEvent.Data.Property("Right") Then
				LogEvent.Data = NStr("en = 'Right:'") + LogEvent.Data.Right;
			Else
				LogEvent.Data = NStr("en = 'Action:'") + LogEvent.Data.Action + ?(LogEvent.Data.Data = Undefined, "", ", ...");
			EndIf;
			
		ElsIf LogEvent.Event = "_$Session$_.Authentication"
		      OR LogEvent.Event = "_$Session$_.AuthenticationError" Then
			LogEvent.DataAddress = PutToTempStorage(LogEvent.Data, Uuid);
			LogEventData = "";
			For each KeyAndValue IN LogEvent.Data Do
				If ValueIsFilled(LogEventData) Then
					LogEventData = LogEventData + ", ...";
					Break;
				EndIf;
				LogEventData = KeyAndValue.Key + ": " + KeyAndValue.Value;
			EndDo;
			LogEvent.Data = LogEventData;
			
		ElsIf LogEvent.Event = "_$User$_.Delete" Then
			LogEvent.DataAddress = PutToTempStorage(LogEvent.Data, Uuid);
			LogEventData = "";
			For each KeyAndValue IN LogEvent.Data Do
				LogEventData = KeyAndValue.Key + ": " + KeyAndValue.Value;
				Break;
			EndDo;
			LogEvent.Data = LogEventData;
			
		ElsIf LogEvent.Event = "_$User$_.New"
		      OR LogEvent.Event = "_$User$_.Update" Then
			LogEvent.DataAddress = PutToTempStorage(LogEvent.Data, Uuid);
			IBUserName = "";
			LogEvent.Data.Property("Name", IBUserName);
			LogEvent.Data = NStr("en = 'Name:'") + IBUserName + ", ...";
			
		EndIf;
		
		SetPrivilegedMode(True);
		// Username clarification
		If LogEvent.User = New Uuid("00000000-0000-0000-0000-000000000000") Then
			LogEvent.UserName = NStr("en = '<Undefined>'");
			
		ElsIf LogEvent.UserName = "" Then
			LogEvent.UserName = Users.FullNameOfNotSpecifiedUser();
			
		ElsIf InfoBaseUsers.FindByUUID(LogEvent.User) = Undefined Then
			LogEvent.UserName = LogEvent.UserName + " " + NStr("en = '<deleted>'");
			
		EndIf;
		SetPrivilegedMode(False);
	EndDo;
	
	ValueToFormAttribute(LogEvents, "Log");
	
	GenerateFilterPresentation();
	
EndProcedure

&AtServer
Procedure FilterConversion(Filter)
	
	For Each FilterItem In Filter Do
		If TypeOf(FilterItem.Value) = Type("ValueList") Then
			FilterItemConversion(Filter, FilterItem);
		ElsIf Upper(FilterItem.Key) = Upper("TransactionID") Then
			If Find(FilterItem.Value, "(") = 0 Then
				Filter.Insert(FilterItem.Key, "(" + FilterItem.Value);
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure FilterItemConversion(Filter, FilterItem)
	
	// This procedure is called, if filter item is a value list,
	// filter should contain array of values. Convert list to array.
	NewValue = New Array;
	
	For Each ValueFromList In FilterItem.Value Do
		If Upper(FilterItem.Key) = Upper("Level") Then
			// Mesage levels are represented as string, need to cast to enum value
			NewValue.Add(DataProcessors.EventLog.EventLogLevelValueByName(ValueFromList.Value));
		ElsIf Upper(FilterItem.Key) = Upper("TransactionStatus") Then
			// Transaction statuses are 'Strings', need to cast to enum value
			NewValue.Add(DataProcessors.EventLog.EventLogEntryTransactionStatusValueByName(ValueFromList.Value));
		Else
			NewValue.Add(ValueFromList.Value);
		EndIf;
	EndDo;
	
	Filter.Insert(FilterItem.Key, NewValue);
	
EndProcedure

&AtServer
Procedure GenerateFilterPresentation()

	FilterPresentation = "";
	// Interval
	IntervalBeginDate    = Undefined;
	IntervalEndingDate = Undefined;
	If Not EventLogFilter.Property("StartDate", IntervalBeginDate) Or
		 IntervalBeginDate = Undefined Then 
		IntervalBeginDate    = '00010101000000';
	EndIf;
	If Not EventLogFilter.Property("EndDate", IntervalEndingDate) Or
		 IntervalEndingDate = Undefined Then 
		IntervalEndingDate = '00010101000000';
	EndIf;
	If Not (IntervalBeginDate = '00010101000000' And IntervalEndingDate = '00010101000000') Then
		FilterPresentation = PeriodPresentation(IntervalBeginDate, IntervalEndingDate);
	EndIf;
	
	AddRestrictionToFilterPresentation(FilterPresentation, "User");
	AddRestrictionToFilterPresentation(FilterPresentation, "Event");
	
	// Other restrictions set using presentations, without specifying restriction values
	For Each FilterItem In EventLogFilter Do
		RestrictionName = FilterItem.Key;
		If Upper(RestrictionName) = Upper("StartDate") 
				Or Upper(RestrictionName) = Upper("EndDate") 
				Or Upper(RestrictionName) = Upper("User")
				Or Upper(RestrictionName) = Upper("Event") Then
			Continue; // Interval and user has already been output
		EndIf;
		
		// For some restrictions change presentation
		If Upper(RestrictionName) = Upper("ApplicationName") Then
			RestrictionName = NStr("en = 'ClientType'");
			
		ElsIf Upper(RestrictionName) = Upper("TransactionStatus") Then
			RestrictionName = NStr("en = 'Transaction status'");
			
		ElsIf Upper(RestrictionName) = Upper("DataPresentation") Then
			RestrictionName = NStr("en = 'Data presentation'");
			
		ElsIf Upper(RestrictionName) = Upper("ServerName") Then
			RestrictionName = NStr("en = 'Server name'");
			
		ElsIf Upper(RestrictionName) = Upper("Port") Then
			RestrictionName = NStr("en = 'Main IP port'");
			
		ElsIf Upper(RestrictionName) = Upper("SyncPort") Then
			RestrictionName = NStr("en = 'Sync port'");
			
		EndIf;
		
		If Not IsBlankString(FilterPresentation) Then 
			FilterPresentation = FilterPresentation + "; ";
		EndIf;
		FilterPresentation = FilterPresentation + RestrictionName;
	EndDo;
	
	If IsBlankString(FilterPresentation) Then
		FilterPresentation = NStr("en = 'Not installed'");
	EndIf;
	
EndProcedure

&AtServer
Procedure AddRestrictionToFilterPresentation(FilterPresentation, RestrictionName)
	
	ListOfRestrictions = "";
	Restriction = "";
	
	If EventLogFilter.Property(RestrictionName, ListOfRestrictions) Then
		For Each ItemOfList In ListOfRestrictions Do
			If Not IsBlankString(Restriction) Then
				Restriction = Restriction + ", ";
			EndIf;
			Restriction = Restriction + ItemOfList.Presentation;
		EndDo;
	
		If Not IsBlankString(FilterPresentation) Then 
			FilterPresentation = FilterPresentation + "; ";
		EndIf;
	
		FilterPresentation = FilterPresentation + Restriction;
	
	EndIf;
	
EndProcedure
