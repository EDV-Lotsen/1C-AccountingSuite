

// Returns enum value corresponding to a string name of event status
//
Function EventLogEntryTransactionStatusValueByName(Name) Export
	
	EnumValue = Undefined;
	If Name = "Committed" Then
		EnumValue = EventLogEntryTransactionStatus.Committed;
	ElsIf Name = "Unfinished" Then
		EnumValue = EventLogEntryTransactionStatus.Unfinished;
	ElsIf Name = "NotApplicable" Then
		EnumValue = EventLogEntryTransactionStatus.NotApplicable;
	ElsIf Name = "RolledBack" Then
		EnumValue = EventLogEntryTransactionStatus.RolledBack;
	EndIf;
	Return EnumValue;
	
EndFunction

Function EventLogLevelValueByName(Name) Export
	
	EnumValue = Undefined;
	If Name = "Information" Then
		EnumValue = EventLogLevel.Information;
	ElsIf Name = "Error" Then
		EnumValue = EventLogLevel.Error;
	ElsIf Name = "Warning" Then
		EnumValue = EventLogLevel.Warning;
	ElsIf Name = "Note" Then
		EnumValue = EventLogLevel.Note;
	EndIf;
	Return EnumValue;
	
EndFunction
