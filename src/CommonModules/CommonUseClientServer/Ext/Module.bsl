
////////////////////////////////////////////////////////////////////////////////
// Base functionality subsystem.
//------------------------------------------------------------------------------
// Client and server procedures and functions of common use for working with:
// - print forms;
// - files;
// - managed forms;
// - email addresses;
// - dynamic list filters;
// - others.
//

////////////////////////////////////////////////////////////////////////////////
#Region PUBLIC_INTERFACE

////////////////////////////////////////////////////////////////////////////////
#Region User_interface_functions

// Generates and displays the message that can relate to a form item.
//
// Parameters
// MessageToUserText - String - message text;
// DataKey - Any infobase object reference -
// infobase object reference, to which this message relates,
// or a record key;
// Field - String - form item description;
// DataPath - String - data path (path to a form attribute);
// Cancel - Boolean - Output parameter. It is always set to True.
//
//
//	Examples:
//
//	1. Showing the message associated with the object attribute near the managed form field:
//	CommonUseClientServer.MessageToUser(
//		NStr("en = 'Error message.'"), ,
//		"FieldInFormObject",
//		"Object");
//
//	An alternative variant of using in the object form module:
//	CommonUseClientServer.MessageToUser(
//		NStr("en = 'Error message.'"), ,
//		"Object.FieldInFormObject");
//
//	2. Showing the message associated with the form attribute near the managed form field:
//	CommonUseClientServer.MessageToUser(
//		NStr("en = 'Error message.'"), ,
//		"FormAttributeName");
//
//	3. Showing the message associated with infobase object attribute.
//	CommonUseClientServer.MessageToUser(
//		NStr("en = 'Error message.'"), ObjectInfobase, "Responsible");
//
// 4. Showing messages associated with an infobase object attribute by reference.
//	CommonUseClientServer.MessageToUser(
//		NStr("en = 'Error message.'"), Ref, , , Cancel);
//
// Incorrect using:
// 1. Passing DataKey and DataPath parameters at the same time.
// 2. Passing a value of an illegal type to the DataKey parameter.
// 3. Specifying a reference without specifying a field (and/or a data path).
//
Procedure MessageToUser(
		Val MessageToUserText,
		Val DataKey = Undefined,
		Val Field = "",
		Val DataPath = "",
		Cancel = False) Export
	
	Message = New UserMessage;
	Message.Text = MessageToUserText;
	Message.Field = Field;
	
	IsObject = False;
	
#If Not (ThinClient Or WebClient) Then
	If DataKey <> Undefined
	 And XMLTypeOf(DataKey) <> Undefined Then
		ValueTypeString = XMLTypeOf(DataKey).TypeName;
		IsObject = Find(ValueTypeString, "Object.") > 0;
	EndIf;
#EndIf
	
	If IsObject Then
		Message.SetData(DataKey);
	Else
		Message.DataKey = DataKey;
	EndIf;
	
	If Not IsBlankString(DataPath) Then
		Message.DataPath = DataPath;
	EndIf;
		
	Message.Message();
	
	Cancel = True;
	
EndProcedure

// Adds the error to the error list that will be displayed to the user
// with the ShowErrorsToUser() procedure.
// It is used in FillCheckProcessing procedures.
//
// Parameters:
// Errors - Undefined - new list will be created,
// - value that is set at the first call of this procedure with the Undefined value.
//
// ErrorField - String - value that is specified in the Field property of the UserMessage object.
// If you want a row number to be included, it must contain %1.
// For example, "Object.Description" or "Object.Users[%1].User".
//
// SingleErrorText - String - error message, it is used if there is only one ErrorGroup in the collection,
// for example, NStr("en = 'User is not selected.'").
//
// ErrorGroup - Arbitrary - it is used to choose between the single error text and
// the several error text, for example, the "Object.Users" name.
// If this value is not filled, the single error text should be used.
//
// LineNumber - Number - numbering starts with 0, it specifies the row number, that must be included
// in the ErrorField string and in the SeveralErrorText (LineNumber + 1 is substituted).
//
// SeveralErrorText - String - error message, it is used if several errors with the same 
// ErrorGroup property is added, for example, NStr("en = 'User in row %1 is not selected.'").
//
Procedure AddUserError(Errors, Val ErrorField, Val SingleErrorText, Val ErrorGroup = "", Val LineNumber = 0, Val SeveralErrorText = "") Export
	
	If Errors = Undefined Then
		Errors = New Structure;
		Errors.Insert("ErrorList", New Array);
		Errors.Insert("ErrorGroups", New Map);
	EndIf;
	
	If Not ValueIsFilled(ErrorGroup) Then
		// If the error group is empty, the single error text must be used.
	Else
		If Errors.ErrorGroups[ErrorGroup] = Undefined Then
			// The error group has been used only once, the single error text must be used.
			Errors.ErrorGroups.Insert(ErrorGroup, False);
		Else
			// The error group has been used several times, the several error text must be used.
			Errors.ErrorGroups.Insert(ErrorGroup, True);
		EndIf;
	EndIf;
	
	Error = New Structure;
	Error.Insert("ErrorField", ErrorField);
	Error.Insert("SingleErrorText", SingleErrorText);
	Error.Insert("ErrorGroup", ErrorGroup);
	Error.Insert("LineNumber", LineNumber );
	Error.Insert("SeveralErrorText", SeveralErrorText);
	
	Errors.ErrorList.Add(Error);
	
EndProcedure

// Displays errors added with the AddUserError() procedure.
//
// Parameters:
// Errors - Undefined - value set in the AddUserError() procedure;
// Cancel - Boolean - it is set to True if errors have been displayed.
//
Procedure ShowErrorsToUser(Val Errors, Cancel = False) Export
	
	If Errors = Undefined Then
		Return;
	Else
		Cancel = True;
	EndIf;
	
	For Each Error In Errors.ErrorList Do
		
		If Errors.ErrorGroups[Error.ErrorGroup] <> True Then
			
			MessageToUser(
				Error.SingleErrorText,
				,
				StrReplace(Error.ErrorField, "%1", Format(Error.LineNumber, "NZ=0; NG=")));
		Else
			MessageToUser(
				StrReplace(Error.SeveralErrorText, "%1", Format(Error.LineNumber + 1, "NZ=0; NG=")),
				,
				StrReplace(Error.ErrorField, "%1", Format(Error.LineNumber, "NZ=0; NG=")));
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region Value_collections_operations

// Generates a path to the LineNumber row and the AttributeName column 
// of the TabularSectionName tabular section to display messages on the form.
// This procedure is for using with the MessageToUser procedure.
// (for passing values to the Field parameter or to the DataPath parameter). 
//
// Parameters:
// TabularSectionName - String - tabular section name;
// LineNumber - Number - tabular section row number;
// AttributeName - String - attribute name.
//
// Returns:
// String - Path to a table cell.
//
Function PathToTabularSection(Val TabularSectionName, Val LineNumber, 
	Val AttributeName) Export

	Return TabularSectionName + "[" + Format(LineNumber - 1, "NZ=0; NG=0") + "]." + AttributeName;

EndFunction

// Supplements the destination value table with data from the source value table.
//
// Parameters:
// SourceTable - ValueTable - rows from this table will be added to the destination table;
// DestinationTable - ValueTable - rows from the source table will be added to this table.
//
Procedure SupplementTable(SourceTable, DestinationTable) Export
	
	For Each SourceTableRow In SourceTable Do
		
		FillPropertyValues(DestinationTable.Add(), SourceTableRow);
		
	EndDo;
	
EndProcedure

// Supplements the Table value table with values from the Array array.
//
// Parameters:
// Table - ValueTable - table to be supplied with values from the array;
// Array - Array - array of values for filling the table;
// FieldName - String - name of value table field, to be supplied with values from the array.
//
Procedure SupplementTableFromArray(Table, Array, FieldName) Export

	For Each Value In Array Do
		
		Table.Add()[FieldName] = Value;
		
	EndDo;
	
EndProcedure

// Supplements the DestinationArray array with values from the SourceArray array.
//
// Parameters:
// DestinationArray - Array - array to be supplied with values;
// SourceArray - Array - array of values to supply DestinationArray;
//	UniqueValuesOnly - Boolean, optional - if it is True, then 
// 		only values that are not included in the destination array will be supplied. Such values will be supplied only once. 
//
Procedure SupplementArray(DestinationArray, SourceArray, UniqueValuesOnly = False) Export

	UniqueValues = New Map;
	
	If UniqueValuesOnly Then
		For Each Value In DestinationArray Do
			UniqueValues.Insert(Value, True);
		EndDo;
	EndIf;
	
	For Each Value In SourceArray Do
		If UniqueValuesOnly And UniqueValues[Value] <> Undefined Then
			Continue;
		EndIf;
		DestinationArray.Add(Value);
		UniqueValues.Insert(Value, True);
	EndDo;
	
EndProcedure

// Removes one conditional appearance item, if this is a value list.
// 
// Parameters:
// ConditionalAppearance - form item conditional appearance;
// UserSettingID - String - setting ID;
// Value - value to be removed from the appearance list.
//
Procedure RemoveValueListConditionalAppearance(
						ConditionalAppearance,
						Val UserSettingID,
						Val Value) Export
	
	For Each CAItem In ConditionalAppearance.Items Do
		If CAItem.UserSettingID = UserSettingID Then
			If CAItem.Filter.Items.Count() = 0 Then
				Return;
			EndIf;
			ItemFilterList = CAItem.Filter.Items[0];
			If ItemFilterList.RightValue = Undefined Then
				Return;
			EndIf;
			ListItem = ItemFilterList.RightValue.FindByValue(Value);
			If ListItem <> Undefined Then
				ItemFilterList.RightValue.Delete(ListItem);
			EndIf;
			ItemFilterList.RightValue = ItemFilterList.RightValue;
			Return;
		EndIf;
	EndDo;
	
EndProcedure

// Deletes all occurrences of the passed value from the array.
//
// Parameters:
// Array - array, from which the value will be deleted;
// Value - value to be deleted from the array.
//
Procedure DeleteAllValueOccurrencesFromArray(Array, Value) Export
	
	CollectionItemCount = Array.Count();
	
	For ReverseIndex = 1 to CollectionItemCount Do
		
		Index = CollectionItemCount - ReverseIndex;
		
		If Array[Index] = Value Then
			
			Array.Delete(Index);
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Deletes all occurrences of specified type values.
//
// Parameters:
// Array - array, from which values will be deleted;
// Type – type of values to be deleted from array.
//
Procedure DeleteAllTypeOccurrencesFromArray(Array, Type) Export
	
	CollectionItemCount = Array.Count();
	
	For ReverseIndex = 1 to CollectionItemCount Do
		
		Index = CollectionItemCount - ReverseIndex;
		
		If TypeOf(Array[Index]) = Type Then
			
			Array.Delete(Index);
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Deletes one value from the array.
//
// Parameters:
// Array - array, from which the value will be deleted;
// Value - value to be deleted from the array.
//
Procedure DeleteValueFromArray(Array, Value) Export
	
	Index = Array.Find(Value);
	
	If Index <> Undefined Then
		
		Array.Delete(Index);
		
	EndIf;
	
EndProcedure

// Fills the destination collection with values from the source collection.
// Objects of the following types can be a destination collection and a source collection:
// ValueTable, ValueTree, ValueList, and other collection types.
//
// Parameters:
// SourceCollection - value collection that is a source of filling data;
// DestinationCollection - value collection that is a destination of filling data.
//
Procedure FillPropertyCollection(SourceCollection, DestinationCollection) Export
	
	For Each Item In SourceCollection Do
		
		FillPropertyValues(DestinationCollection.Add(), Item);
		
	EndDo;
	
EndProcedure

// Gets an array of values containing marked items of the value list.
//
// Parameters:
// List - ValueList - value list, with which an array of values will be generated;
// 
// Returns:
// Array - array of values that contains marked items.
//
Function GetMarkedListItemArray(List) Export
	
	// Returned value of the function
	Array = New Array;
	
	For Each Item In List Do
		
		If Item.Check Then
			
			Array.Add(Item.Value);
			
		EndIf;
		
	EndDo;
	
	Return Array;
EndFunction

// Subtracts one array of elements from another. Returns the result of subtraction.
//
// Parameters:
// Array - array, whose elements are deleted if they are identical to elements of SubtractionArray;
// SubtractionArray - array of elements to be subtracted.
// 
// Returns:
// Array – the result of subtraction.
//
Function ReduceArray(Array, SubtractionArray) Export
	
	Result = New Array;
	
	For Each Element In Array Do
		
		If SubtractionArray.Find(Element) = Undefined Then
			
			Result.Add(Element);
			
		EndIf;
		
	EndDo;
	
	Return Result;
	
EndFunction

// Converts the job schedule into a structure.
//
// Parameters:
// Schedule - JobSchedule;
// 
// Returns:
// Structure.
//
Function ScheduleToStructure(Val Schedule) Export
	
	ScheduleValue = Schedule;
	If ScheduleValue = Undefined Then
		ScheduleValue = New JobSchedule();
	EndIf;
	FieldList = "CompletionTime,EndTime,BeginTime,EndDate,StartDate,DayInMonth,WeekDayInMonth," + 
		"WeekDays,CompletionInterval,Months,RepeatPause,WeeksPeriod,RepeatPeriodInDay,DaysRepeatPeriod";
	Result = New Structure(FieldList);
	FillPropertyValues(Result, ScheduleValue, FieldList);
	DetailedDailySchedules = New Array;
	For Each DailySchedule In Schedule.DetailedDailySchedules Do
		DetailedDailySchedules.Add(ScheduleToStructure(DailySchedule));
	EndDo;
	Result.Insert("DetailedDailySchedules", DetailedDailySchedules);
	Return Result;
	
EndFunction		

// Converts the structure into a JobSchedule.
//
// Parameters:
// ScheduleStructure - Structure;
// 
// Returns:
// JobSchedule.
//
Function StructureToSchedule(Val ScheduleStructure) Export
	
	If ScheduleStructure = Undefined Then
		Return New JobSchedule();
	EndIf;
	FieldList = "CompletionTime,EndTime,BeginTime,EndDate,StartDate,DayInMonth,WeekDayInMonth," + 
		"WeekDays,CompletionInterval,Months,RepeatPause,WeeksPeriod,RepeatPeriodInDay,DaysRepeatPeriod";
	Result = New JobSchedule;
	FillPropertyValues(Result, ScheduleStructure, FieldList);
	DetailedDailySchedules = New Array;
	For Each Schedule In ScheduleStructure.DetailedDailySchedules Do
		 DetailedDailySchedules.Add(StructureToSchedule(Schedule));
	EndDo;
	Result.DetailedDailySchedules = DetailedDailySchedules; 
	Return Result;
	
EndFunction		

// Creates a copy of the passed object.
//
// Parameters:
// Source - Arbitrary - object to be copied.
//
// Returns:
// Arbitrary - copy of the object that is passed to the Source parameter.
//
// Note:
// The function cannot be used for object types (CatalogObject, DocumentObject, and others).
//
Function CopyRecursive(Source) Export
	
	Var Receiver;
	
	SourceType = TypeOf(Source);
	If SourceType = Type("Structure") Then
		Destination = CopyStructure(Source);
	ElsIf SourceType = Type("Map") Then
		Destination = CopyMap(Source);
	ElsIf SourceType = Type("Array") Then
		Destination = CopyArray(Source);
	ElsIf SourceType = Type("ValueList") Then
		Destination = CopyValueList(Source);
	#If Server Or ThickClient Or ExternalConnection Then
	ElsIf SourceType = Type("ValueTable") Then
		Destination = Source.Copy();
	#EndIf
	Else
		Destination = Source;
	EndIf;
	
	Return Receiver;
	
EndFunction

// Creates a copy of the value of the Structure type.
//
// Parameters:
// SourceStructure – Structure – structure to be copied.
// 
// Returns:
// Structure - copy of the source structure.
//
Function CopyStructure(SourceStructure) Export
	
	ResultStructure = New Structure;
	
	For Each KeyAndValue In SourceStructure Do
		ResultStructure.Insert(KeyAndValue.Key, CopyRecursive(KeyAndValue.Value));
	EndDo;
	
	Return ResultStructure;
	
EndFunction

// Creates a copy of the value of the Map type.
//
// Parameters:
// SourceMap – Map - map to be copied.
// 
// Returns:
// Map - copy of the source map.
//
Function CopyMap(SourceMap) Export
	
	ResultMap= New Map;
	
	For Each KeyAndValue In SourceMap Do
		ResultMap.Insert(KeyAndValue.Key, CopyRecursive(KeyAndValue.Value));
	EndDo;
	
	Return ResultMap;

EndFunction

// Creates a copy of the value of the Array type.
//
// Parameters:
// SourceArray – Array - array to be copied.
// 
// Returns:
// Array - copy of the source array.
//
Function CopyArray(SourceArray) Export
	
	ResultArray = New Array;
	
	For Each Item In SourceArray Do
		ResultArray.Add(CopyRecursive(Item));
	EndDo;
	
	Return ResultArray;
	
EndFunction

// Creates a copy of the value of the ValueList type.
//
// Parameters:
// SourceList – ValueList - value list to be copied.
// 
// Returns:
// ValueList - copy of the source value list.
//
Function CopyValueList(SourceList) Export
	
	ResultList = New ValueList;
	
	For Each ListItem In SourceList Do
		ResultList.Add(
			CopyRecursive(ListItem.Value), 
			ListItem.Presentation, 
			ListItem.Check, 
			ListItem.Picture);
	EndDo;
	
	Return ResultList;
	
EndFunction

// Compares value list items or array elements by values.
//
Function ValueListsEqual(List1, List2) Export
	
	EqualLists = True;
	
	For Each ListItem1 In List1 Do
		If FindInList(List2, ListItem1) = Undefined Then
			EqualLists = False;
			Break;
		EndIf;
	EndDo;
	
	If EqualLists Then
		For Each ListItem2 In List2 Do
			If FindInList(List1, ListItem2) = Undefined Then
				EqualLists = False;
				Break;
			EndIf;
		EndDo;
	EndIf;
	
	Return EqualLists;
	
EndFunction 

// Creates an array and places the passed value in it.
//
Function ValueInArray(Value) Export
	
	Array = New Array;
	Array.Add(Value);
	
	Return Array;
	
EndFunction

// Gets the configuration version number without the assembly number
//
// Parameters:
// Version - String - configuration version in the following format: EE.SS.RR.AA,
// where AA is the assembly number to be removed.
// 
// Returns:
// String - configuration version number without the assembly number in the following format: EE.SS.RR
//
Function ConfigurationVersionWithoutAssemblyNumber(Val Version) Export
	
	Array = StringFunctionsClientServer.SplitStringIntoSubstringArray(Version, ".");
	
	If Array.Count() < 3 Then
		Return Version;
	EndIf;
	
	Result = "[Edition].[Subedition].[Release]";
	Result = StrReplace(Result, "[Edition]", Array[0]);
	Result = StrReplace(Result, "[Subedition]", Array[1]);
	Result = StrReplace(Result, "[Release]", Array[2]);
	
	Return Result;
EndFunction

// Compare two version strings.
//
// Parameters
// VersionString1 – String – version number in the following format EE.{S|SS}.RR.AA
// VersionString2 – String – second version number to be compared.
//
// Returns:
// Number – greater than 0 if VersionString1 > VersionString2; 0 if the versions are equal.
//
Function CompareVersions(Val VersionString1, Val VersionString2) Export
	
	String1 = ?(IsBlankString(VersionString1), "0.0.0.0", VersionString1);
	String2 = ?(IsBlankString(VersionString2), "0.0.0.0", VersionString2);
	Version1 = StringFunctionsClientServer.SplitStringIntoSubstringArray(String1, ".");
	If Version1.Count() <> 4 Then
		Raise StringFunctionsClientServer.SubstituteParametersInString(
		 NStr("en = 'Invalid version string format: %1'"), VersionString1);
	EndIf;
	Version2 = StringFunctionsClientServer.SplitStringIntoSubstringArray(String2, ".");
	If Version2.Count() <> 4 Then
		Raise StringFunctionsClientServer.SubstituteParametersInString(
	 NStr("en = 'Invalid version string format: %1'"), VersionString2);
	EndIf;
	
	Result = 0;
	For Digit = 0 to 3 Do
		Result = Number(Version1[Digit]) - Number(Version2[Digit]);
		If Result <> 0 Then
			Return Result;
		EndIf;
	EndDo;
	Return Result;
	
EndFunction

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region Procedures_and_functions_for_calling_of_non_mandatory_subsystems

// Returns reference to common module by it's name.
//
// Parameters:
//  Name         - String - Name of common module, for example:
//                 "CommonUse",
//                 "CommonUseClientServer".
//
// Returns:
//  CommonModule - reference to common module.
//
Function CommonModule(Name) Export
	
	#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
		
		// Check existance of passed module name preventing code execution at server.
		If Metadata.CommonModules.Find(Name) <> Undefined Then
			Module = Eval(Name);
		Else
			Module = Undefined;
		EndIf;
		
	#Else
		// Execute directly at client.
		Module = Eval(Name);
	#EndIf
	
	#If Not WebClient Then
		
		// Check resulting data preventing sensitive data to be returned at client.
		If TypeOf(Module) <> Eval("Type(""CommonModule"")") Then
			Raise StringFunctionsClientServer.SubstituteParametersInString(
				NStr("en = 'Common module ""%1"" was not found.'"), Name);
		EndIf;
		
	#EndIf
	
	Return Module;
	
EndFunction

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region Functions_for_working_with_files

// Deletes all files in the specified directory.
//
// Parameters:
// Path - String - the full path to the directory, whose
// files will be deleted.
//
Procedure DeleteDirectoryWithFiles(Path) Export
	
	Directory = New File(Path);
	
	If Directory.Exist() Then
		DeleteFiles(Path);
	EndIf;
	
EndProcedure // DeleteDirectoryWithFiles()

// Adds the final separator character to the passed directory path if it is missing.
// If the OperatingSystem parameter is not specified, separator selection is based on separators
// from the "DirectoryPath" parameter.
//
// Parameters:
// DirectoryPath - String - directory path;
// Platform - Type of the operating system - type of the operating system that runs 1C:Enterprise (It has an effect on separator selection).
//
// Returns:
// String - directory path with the final separator character.
//
// Examples:
// Result = AddFinalPathSeparator("C:\My directory");
// Returns "C:\My directory\"
// Result = AddFinalPathSeparator("C:\My directory\"); 
// Returns "C:\My directory\"
// Result = AddFinalPathSeparator("ftp://My directory/"); 
// Returns "ftp://My directory/"
// Result = AddFinalPathSeparator("%APPDATA%", PlatformType.Windows_x86_64); 
// Returns "%APPDATA%\"
//
Function AddFinalPathSeparator(Val DirectoryPath, Val Platform = Undefined) Export
	
	If IsBlankString(DirectoryPath) Then
		Return DirectoryPath;
	EndIf;
	
	CharToAdd = "\";
	If Platform = Undefined Then
		If Find(DirectoryPath, "/") > 0 Then
			CharToAdd = "/";
		EndIf;
	Else
		If Platform = PlatformType.Linux_x86 Or Platform = PlatformType.Linux_x86_64 Then
			CharToAdd = "/";
		EndIf;
	EndIf;
	
	If Right(DirectoryPath, 1) <> CharToAdd Then
		Return DirectoryPath + CharToAdd;
	Else 
		Return DirectoryPath;
	EndIf;
	
EndFunction

// Adds \ or / to the end of the path
//
Procedure AddSlashIfNeeded(NewPath, CurrentPlatformType) Export
	
	If StrLen(NewPath) = 0 Then
		Return;
	EndIf;	
	
	If Right(NewPath, 1) <> "\" And Right(NewPath,1) <> "/" Then
		
		If CurrentPlatformType = PlatformType.Windows_x86 Or CurrentPlatformType = PlatformType.Windows_x86_64 Then
			NewPath = NewPath + "\";
		Else	
			NewPath = NewPath + "/";
		EndIf;			
	EndIf;
	
EndProcedure	

// Generates a full file name from the directory name and the file name.
//
// Parameters
// DirectoryName – String that contains the path to the directory with the file on the hard disk;
// FileName – String that contains the file name without the directory name.
//
// Returns:
// String – the full file name with the directory name.
//
Function GetFullFileName(Val DirectoryName, Val FileName) Export

	If Not IsBlankString(FileName) Then
		
		Slash = "";
		If (Right(DirectoryName, 1) <> "\") And (Right(DirectoryName, 1) <> "/") Then
			Slash = ?(Find(DirectoryName, "\") = 0, "/", "\");
		EndIf;
		
		Return DirectoryName + Slash + FileName;
		
	Else
		
		Return DirectoryName;
		
	EndIf;

EndFunction

// Splits the full file name into components.
//
// Parameters
// FullFileName – string that contains the full file path.
// IsFolder – Boolean - a flag that shows whether a full directory name is being splited (not a file name).
//
// Returns:
// Structure – file name, splited into components (like File object properties):
//		FullName - contains the full file path, it is equal to the FullFileName input parameter;
//		Path - contains the path to the directory, where the file is placed;
//		Name - contains the file name with the extension but without the file path;
//		Extension - contains the file extension;
//		BaseName - contains the file name without the extension and the path;
//			Example: if FullFileName = "c:\temp\test.txt" then the structure is filled in the following way:
//				FullName: "c:\temp\test.txt"
//				Path: "c:\temp\"
//				Name: "test.txt"
//				Extension: ".txt"
//				BaseName: "test"
//
Function SplitFullFileName(Val FullFileName, IsFolder = False) Export
	
	FileNameStructure = New Structure("FullName,Path,Name,Extension,BaseName");
	
	// Removing the final slash from the full file name and recording the resulted full name to the structure
	If IsFolder And (Right(FullFileName, 1) = "/" Or Right(FullFileName, 1) = "\") Then
		If IsFolder Then
			FullFileName = Mid(FullFileName, 1, StrLen(FullFileName) - 1);
		Else
			// If the file path ends with slash, then the file has no name
			FileNameStructure.Insert("FullName", FullFileName); 
			FileNameStructure.Insert("Path", FullFileName); 
			FileNameStructure.Insert("Name", ""); 
			FileNameStructure.Insert("Extension", ""); 
			FileNameStructure.Insert("BaseName", ""); 
			Return FileNameStructure;
		EndIf;
	EndIf;
	FileNameStructure.Insert("FullName", FullFileName); 
	
	// If the full file name is empty, then all other structure parameters have to be returned empty too
	If StrLen(FullFileName) = 0 Then 
		FileNameStructure.Insert("Path", ""); 
		FileNameStructure.Insert("Name", ""); 
		FileNameStructure.Insert("Extension", ""); 
		FileNameStructure.Insert("BaseName", ""); 
		Return FileNameStructure;
	EndIf;
	
	// Extracting the file path and the file name									 
	If Find(FullFileName, "/") > 0 Then
		SeparatorPosition = StringFunctionsClientServer.FindCharFromEnd(FullFileName, "/");
	ElsIf Find(FullFileName, "\") > 0 Then
		SeparatorPosition = StringFunctionsClientServer.FindCharFromEnd(FullFileName, "\");
	Else
		SeparatorPosition = 0;
	EndIf;
	FileNameStructure.Insert("Path", Left(FullFileName, SeparatorPosition)); 
	FileNameStructure.Insert("Name", Mid(FullFileName, SeparatorPosition + 1));
	
	// Extracting the file extension (folders have no extensions)
	If IsFolder Then
		FileNameStructure.Insert("Extension", "");
		FileNameStructure.Insert("BaseName", FileNameStructure.Name);
	Else
DotPosition = StringFunctionsClientServer.FindCharFromEnd(FileNameStructure.Name, ".");
		If DotPosition = 0 Then
			FileNameStructure.Insert("Extension", "");
			FileNameStructure.Insert("BaseName", FileNameStructure.Name);
		Else
			FileNameStructure.Insert("Extension", Mid(FileNameStructure.Name, DotPosition));
			FileNameStructure.Insert("BaseName", Left(FileNameStructure.Name, DotPosition - 1));
		EndIf;
	EndIf;
	
	Return FileNameStructure;
	
EndFunction

// Returns a string of prohibited characters
// according to the Reserved Characters and Words section of http://en.wikipedia.org/wiki/Filename
// Returns:
// String - string of prohibited characters.
//
Function GetProhibitedCharsInFileName() Export

	ProhibitedChars = """/\[]:;|=?*<>";
	Return ProhibitedChars;

EndFunction

// Checks whether the file name has prohibited characters. 
//
// Parameters
// FileName - String 
// Returns:
// Array - array of prohibited characters that are found in the file name.
// If there are no prohibited characters, an empty array is returned.
//
Function FindProhibitedCharsInFileName(FileName) Export

	ProhibitedChars = GetProhibitedCharsInFileName();
	
	FoundProhibitedCharArray = New Array;
	
	For CharPosition = 1 to StrLen(ProhibitedChars) Do
		CharToCheck = Mid(ProhibitedChars,CharPosition,1);
		If Find(FileName,CharToCheck) <> 0 Then
			FoundProhibitedCharArray.Add(CharToCheck);
		EndIf;
	EndDo;
	
	Return FoundProhibitedCharArray;

EndFunction

// Replaces prohibited characters in the file name.
//
// Parameters
// FileName - String - initial file name;
// ReplaceWith - String - string that will be substituted for prohibited characters.
//
// Returns:
// String - resulting file name.
//
Function ReplaceProhibitedCharsInFileName(FileName, ReplaceWith = " ") Export

	FoundProhibitedCharArray = FindProhibitedCharsInFileName(FileName);
	For Each ProhibitedChar In FoundProhibitedCharArray Do
		FileName = StrReplace(FileName,ProhibitedChar,ReplaceWith);
	EndDo;
	
	Return FileName;

EndFunction

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region Functions_for_working_with_email_addresses

// Splits the string with email addresses according to the RFC 5322 standard with the following restrictions:
//
// 1. It is allowed only letters, digits, the _ character, the - character, the . character, and the @ character in the address.
// 2. Bracket characters <>[]() are allowed but will be replaced with the space character.
// 3. Groups are prohibited.
//
// Parameters:
// String - String - string that contains email addresses (mailbox-list).
//
// Returns:
// Array - array of address structures with the following fields:
// Alias - String - address presentation;
// Address - String - found and met the requirements email address;
// If a text that looks like an address is found, but it does not meet the standard requirements,
// this text is interpreted as an Alias field value.
// ErrorDescription - String - Error text presentation or an empty string if there are no errors.
//
Function EmailsFromString(Val String) Export
	
	Result = New Array;
	
	// Replacing brackets with the space characters.
	BracketChars = "<>()[]";
	String = ReplaceCharsInStringWithSpaces(String, BracketChars);
	
	// Adjusting splitters to one kind
	String = StrReplace(String, ",", ";");
	
	// Parsing the mailbox-list into mailboxes
	AddressArray = StringFunctionsClientServer.SplitStringIntoSubstringArray(String, ";", True);
	
	// Symbols that are allowed for alias (display-name)
	Letters = "abcdefghijklmnopqrstuvwxyz";
	Digits = "0123456789";
	AdditionalChars = "._- ";
	
	// Extracting the alias (display-name) and the address (addr-spec) from the address string (Mailbox)
	For Each AddressString In AddressArray Do
		
		Alias = "";
		Address = "";
		ErrorDescription = "";
		
		If StrOccurrenceCount(AddressString, "@") <> 1 Then
			Alias = AddressString;
		Else
			// Everything that does not have email address format is interpreted as aliases
			For Each Substring In StringFunctionsClientServer.SplitStringIntoSubstringArray(AddressString, " ") Do
				If IsBlankString(Address) And EmailAddressMeetsRequirements(Substring) Then
					Address = Substring;
				Else
					Alias = Alias + " " + Substring;
				EndIf;
			EndDo;
		EndIf;
		
		Alias = TrimAll(Alias);
		
		// Checks
		HasProhibitedCharsInAlias = Not StringContainsAllowedCharsOnly(Lower(Alias), Letters + Digits + AdditionalChars);
		AddressDefined = Not IsBlankString(Address);
		StringContainsEmail = Find(AddressString, "@") > 0;
		
		If AddressDefined Then 
			If HasProhibitedCharsInAlias Then
				ErrorDescription = NStr("en = 'Presentation contains prohibited characters'");
			EndIf;
		Else
			If StringContainsEmail Then 
				ErrorDescription = NStr("en = 'Email address contains errors'");
			Else
				ErrorDescription = NStr("en = 'String does not contain email addresses'");
			EndIf;
		EndIf;	
		
		AddressStructure = New Structure("Alias,Address,ErrorDescription", Alias, Address, ErrorDescription);
		Result.Add(AddressStructure);
	EndDo;
	
	Return Result;	
	
EndFunction

// Checks whether email address meets the RFC 5321, RFC 5322,
// RFC 5335, RFC 5336, and RFC 3696 standard requirements.
// In addition, the function limits using special symbols.
// 
// Parameters:
// Address - String - email to be validated.
//
// Returns:
// Boolean - True if there are no errors.
//
Function EmailAddressMeetsRequirements(Val Address) Export
	
	// Symbols that are allowed for an email address
	Letters = "abcdefghijklmnopqrstuvwxyz";
	Digits = "0123456789";
	SpecChars = ".@_-";
	
	// Checking all special symbol combinations
	If StrLen(SpecChars) > 1 Then
		For Position1 = 1 to StrLen(SpecChars)-1 Do
			Char1 = Mid(SpecChars, Position1, 1);
			For Position2 = Position1 + 1 to StrLen(SpecChars) Do
				Char2 = Mid(SpecChars, Position2, 1);
				Combination1 = Char1 + Char2;
				Combination2 = Char2 + Char1;
				If Find(Address, Combination1) > 0 Or Find(Address, Combination2) > 0 Then
					Return False;
				EndIf;
			EndDo;
		EndDo;
	EndIf;
	
	// Checking the @ symbol
	If StrOccurrenceCount(Address, "@") <> 1 Then
		Return False;
	EndIf;
	 
	// Checking two dots in succession
	If Find(Address, "..") > 0 Then
		Return False;
	EndIf;
	
	// Adjusting the address string to the lower case
	Address = Lower(Address);
	
	// Check allowed symbols
	If Not StringContainsAllowedCharsOnly(Address, Letters + Digits + SpecChars) Then
		Return False;
	EndIf;
	
	// Splitting the address into a local-part and domain
	Position = Find(Address,"@");
	LocalName = Left(Address, Position - 1);
	Domain = Mid(Address, Position + 1);
	
// Checking whether LocalName and Domain are filled and their lengths meet the requirements
	If IsBlankString(LocalName)
	 	Or IsBlankString(Domain)
		Or StrLen(LocalName) > 64
		Or StrLen(Domain) > 255 Then
		
		Return False;
	EndIf;
	
	// Checking whether there are any special characters at the beginning and at the end of LocalName and Domain 
	If HasCharsLeftRight(LocalName, SpecChars) Or HasCharsLeftRight(Domain, SpecChars) Then
		Return False;
	EndIf;
	
	// Domain has to contain at least one dot
	If Find(Domain,".") = 0 Then
		Return False;
	EndIf;
	
	// Domain has to contain no _ characters
	If Find(Domain,"_") > 0 Then
		Return False;
	EndIf;
	
	// Extracting a top-level domain (TLD) from the domain name 
	TLD = Domain;
	Position = Find(TLD,".");
	While Position > 0 Do
		TLD = Mid(TLD, Position + 1);
		Position = Find(TLD,".");
	EndDo;
	
	// Checking TLD (at least 2 characters, letters only)
	Return StrLen(TLD) >= 2 And StringContainsAllowedCharsOnly(TLD,Letters);
	
EndFunction

// Checks correctness of the passed string with email addresses.
//
// String format:
// Z = UserName|[User Name] [<]user@mail_server[>], String = Z[<splitter*>Z]
// 
// Note: splitter* is any address splitter.
//
// Parameters:
// EmailAddressString - String - correct string with email addresses.
//
// Returns:
// Structure
// State - Boolean - flag that shows whether conversion completed successfully.
// If conversion completed successfully it contains Value, which is
// an array of structures with the following keys:
// Address - recipient email address;
// Presentation - recipient name.
// If conversion failed it contains ErrorMessage - String.
//
// IMPORTANT: The function returns an array of structures, where one field (any field)
// can be empty. It can be used by various
// subsystems for mapping user names
// to email addresses. Therefore it is necessary to check before sending whether 
// email address is filled.
//
Function SplitStringWithEmailAddresses(Val EmailAddressString) Export
	
	Result = New Array;
	
	ProhibitedChars = "!#$%^&*()+`~|\/=";
	
	ProhibitedCharsMessage = NStr("en = 'There is a prohibited character %1 in the email address %2'");
	MessageInvalidEmailFormat = NStr("en = 'Incorrect email address %1'");
	
	SubstringArray = StringFunctionsClientServer.SplitStringIntoSubstringArray(EmailAddressString,";",True);
	SubstringArrayToProcess = New Array;
	
	For Each ArrayElement In SubstringArray Do
		If Find(ArrayElement,",") > 0 Then
			AdditionalSubstringArray = StringFunctionsClientServer.SplitStringIntoSubstringArray(EmailAddressString);
			For Each AdditionalArrayElement In AdditionalSubstringArray Do
				SubstringArrayToProcess.Add(AdditionalArrayElement);
			EndDo;
		Else
			SubstringArrayToProcess.Add(ArrayElement);
		EndIf;
	EndDo;
	
	For Each AddressString In SubstringArrayToProcess Do
		
		Index = 1; // Number of processed character.
		Accumulator = ""; // character accumulator. After the end of analysis, it passes its 
		// value to the full name or to the mail address.
		AddresseeFullName = ""; // Variable that accumulates the addressee name.
		EmailAddress = ""; // Variable that accumulates the email address.
		// 1 - Generating the full name: any allowed characters of the addressee name are expected.
		// 2 - Generating the mail address: any allowed characters of the email address are expected.
		// 3 - Ending mail address generation: a splitter character or a space character are expected. 
		ParsingStage = 1; 
		
		While Index <= StrLen(AddressString) Do
			
			Char = Mid(AddressString, Index, 1);
			
			If Char = " " Then
				Index = ?((SkipChar(AddressString, Index, " ") - 1) > Index,
				SkipChar(AddressString, Index, " ") - 1,
				Index);
				If ParsingStage = 1 Then
					AddresseeFullName = AddresseeFullName + Accumulator + " ";
				ElsIf ParsingStage = 2 Then
					EmailAddress = Accumulator;
					ParsingStage = 3;
				EndIf;
				Accumulator = "";
			ElsIf Char = "@" Then
				If ParsingStage = 1 Then
					ParsingStage = 2;
					
					For PCSearchIndex = 1 to StrLen(Accumulator) Do
						If Find(ProhibitedChars, Mid(Accumulator, PCSearchIndex, 1)) > 0 Then
							Raise StringFunctionsClientServer.SubstituteParametersInString(
							 ProhibitedCharsMessage,Mid(Accumulator, PCSearchIndex, 1),AddressString);
						EndIf;
					EndDo;
					
					Accumulator = Accumulator + Char;
				ElsIf ParsingStage = 2 Then
					Raise StringFunctionsClientServer.SubstituteParametersInString(
					 MessageInvalidEmailFormat,AddressString);
				ElsIf ParsingStage = 3 Then
					Raise StringFunctionsClientServer.SubstituteParametersInString(
					 MessageInvalidEmailFormat,AddressString);
				EndIf;
			Else
				If ParsingStage = 2 Or ParsingStage = 3 Then
					If Find(ProhibitedChars, Char) > 0 Then
						Raise StringFunctionsClientServer.SubstituteParametersInString(
						 ProhibitedCharsMessage,Char,AddressString);
					EndIf;
				EndIf;
				
				Accumulator = Accumulator + Char;
			EndIf;
			
			Index = Index + 1;
		EndDo;
		
		If ParsingStage = 1 Then
			AddresseeFullName = AddresseeFullName + Accumulator;
		ElsIf ParsingStage = 2 Then
			EmailAddress = Accumulator;
		EndIf;
		
		If IsBlankString(EmailAddress) And (Not IsBlankString(AddresseeFullName)) Then
			Raise StringFunctionsClientServer.SubstituteParametersInString(
			 MessageInvalidEmailFormat,AddresseeFullName);
		ElsIf StrOccurrenceCount(EmailAddress,"@") <> 1 Then 
			Raise StringFunctionsClientServer.SubstituteParametersInString(
			 MessageInvalidEmailFormat,EmailAddress);
		EndIf;
		
		If Not (IsBlankString(AddresseeFullName) And IsBlankString(EmailAddress)) Then
			Result.Add(CheckAndPrepareEmailAddress(AddresseeFullName, EmailAddress));
		EndIf;
		
	EndDo;
	
	Return Result;
	
EndFunction

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region Functions_for_working_with_dynamic_list_filters

// Searches for items and groups of the dynamic list filter.
// Parameters:
// SearchArea - container with items and groups of the filter, for example
// List.Filter or a group in the filter;
// FieldName - data composition field name (is not used for groups);
// Presentation - data composition field presentation;
// Note: The function can search by LeftValue or by Presentation.
//
Function FindFilterItemsAndGroups(Val SearchArea,
									Val FieldName = Undefined,
									Val Presentation = Undefined) Export
	
	If ValueIsFilled(FieldName) Then
		SearchMethod = New DataCompositionField(FieldName);
		SearchMethod = 1;
	Else
		SearchMethod = 2;
		SearchMethod = Presentation;
	EndIf;
	
	ItemArray = New Array;
	
	FindRecursively(SearchArea.Items, ItemArray, SearchMethod, SearchMethod);
	
	Return ItemArray;
	
EndFunction

// Adds filter groups.
// Parameters:
// ItemCollection - container with items and groups of the filter, for example
// List.Filter or a group in the filter;
// GroupType - DataCompositionFilterItemsGroupType - group type; 
// Presentation - string - group presentation;
//
Function CreateFilterItemGroup(ItemCollection, Presentation, GroupType) Export
	
	FilterItemGroup = FindFilterItemByPresentation(ItemCollection, Presentation);
	If FilterItemGroup = Undefined Then
		FilterItemGroup = ItemCollection.Add(Type("DataCompositionFilterItemGroup"));
	Else
		FilterItemGroup.Items.Clear();
	EndIf;
	
	FilterItemGroup.Presentation = Presentation;
	FilterItemGroup.Application = DataCompositionFilterApplicationType.Items;
	FilterItemGroup.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	FilterItemGroup.GroupType = GroupType;
	FilterItemGroup.Use = True;
	
	Return FilterItemGroup;
	
EndFunction

// Adds the composition item into the composition item container.
// Parameters:
// ItemCollection - container with items and groups of the filter, for example
// List.Filter or a group in the filter;
// FieldName - String - data composition field name;
// ComparisonType - DataCompositionComparisonType - comparison type; 
// RightValue - Arbitrary;
// Presentation - data composition item presentation;
// Use - Boolean - item usage;
// ViewMode - DataCompositionSettingsItemViewMode - view mode.
//
Function AddCompositionItem(AreaToAdd,
									Val FieldName,
									Val ComparisonType,
									Val RightValue = Undefined,
									Val Presentation = Undefined,
									Val Use = Undefined,
									Val ViewMode = Undefined) Export
	
	Item = AreaToAdd.Items.Add(Type("DataCompositionFilterItem"));
	Item.LeftValue = New DataCompositionField(FieldName);
	Item.ComparisonType = ComparisonType;
	
	If ViewMode = Undefined Then
		Item.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	Else
		Item.ViewMode = ViewMode;
	EndIf;
	
	If RightValue <> Undefined Then
		Item.RightValue = RightValue;
	EndIf;
	
	If Presentation <> Undefined Then
		Item.Presentation = Presentation;
	EndIf;
	
	If Use <> Undefined Then
		Item.Use = Use;
	EndIf;
	
	Return Item;
	
EndFunction

// Changes filter items.
// Parameters:
// FieldName - String - composition field name;
// ComparisonType - DataCompositionComparisonType - comparison type;
// RightValue - Arbitrary;
// Presentation - String - data composition item presentation;
// Use - Boolean - item usage;
// ViewMode - DataCompositionSettingsItemViewMode - view mode.
//
Function ChangeFilterItems(SearchArea,
								Val FieldName = Undefined,
								Val Presentation = Undefined,
								Val RightValue = Undefined,
								Val ComparisonType = Undefined,
								Val Use = Undefined,
								Val ViewMode = Undefined) Export
	
	If ValueIsFilled(FieldName) Then
		SearchMethod = New DataCompositionField(FieldName);
		SearchMethod = 1;
	Else
		SearchMethod = 2;
		SearchMethod = Presentation;
	EndIf;
	
	ItemArray = New Array;
	
	FindRecursively(SearchArea.Items, ItemArray, SearchMethod, SearchMethod);
	
	For Each Item In ItemArray Do
		If FieldName <> Undefined Then
			Item.LeftValue = New DataCompositionField(FieldName);
		EndIf;
		If Presentation <> Undefined Then
			Item.Presentation = Presentation;
		EndIf;
		If Use <> Undefined Then
			Item.Use = Use;
		EndIf;
		If ComparisonType <> Undefined Then
			Item.ComparisonType = ComparisonType;
		EndIf;
		If RightValue <> Undefined Then
			Item.RightValue = RightValue;
		EndIf;
		If ViewMode <> Undefined Then
			Item.ViewMode = ViewMode;
		EndIf;
	EndDo;
	
	Return ItemArray.Count();
	
EndFunction

// Deletes filter items. 
// Parameters:
// AreaToDelete - container with items and groups of the filter, for example
// List.Filter or a group in the filter;
// FieldName - data composition field name (is not used for groups);
// Presentation - data composition field presentation.
// Note: The function can search by LeftValue or by Presentation.
// 
Procedure DeleteFilterItems(Val AreaToDelete,
										Val FieldName = Undefined,
										Val Presentation = Undefined) Export
	
	If ValueIsFilled(FieldName) Then
		SearchMethod = New DataCompositionField(FieldName);
		SearchMethod = 1;
	Else
		SearchMethod = 2;
		SearchMethod = Presentation;
	EndIf;
	
	ItemArray = New Array;
	
	FindRecursively(AreaToDelete.Items, ItemArray, SearchMethod, SearchMethod);
	
	For Each Item In ItemArray Do
		If Item.Parent = Undefined Then
			AreaToDelete.Items.Delete(Item);
		Else
			Item.Parent.Items.Delete(Item);
		EndIf;
	EndDo;
	
EndProcedure

// Is used to set a filter item or, if it is not 
// found, to create a new one.
// Parameters
// WhereToAdd - container with items and groups of the filter, for example
// List.Filter or a group in the filter;
// FieldName - String - data composition field name (must always be filled);
// Fields to be set:
// ComparisonType - DataCompositionComparisonType - comparison type;
// RightValue - Arbitrary;
// Presentation - data composition field presentation;
// Use - Boolean - item usage;
// ViewMode - DataCompositionSettingsItemViewMode - view mode.
//
Procedure SetFilterItem(WhereToAdd,
								Val FieldName,
								Val RightValue = Undefined,
								Val ComparisonType = Undefined,
								Val Presentation = Undefined,
								Val Use = Undefined,
								Val ViewMode = Undefined) Export
	
	ModifiedCount = ChangeFilterItems(WhereToAdd, FieldName, Presentation,
							RightValue, ComparisonType, Use, ViewMode);
	
	If ModifiedCount = 0 Then
		If ComparisonType = Undefined Then
			ComparisonType = DataCompositionComparisonType.Equal;
		EndIf;
		AddCompositionItem(WhereToAdd, FieldName, ComparisonType,
								RightValue, Presentation, Use, ViewMode);
	EndIf;
	
EndProcedure

// Sets Value to ParameterName of List 
// or disables its usage (it depends on the Use parameter).
//
Procedure SetDynamicListParameter(List, ParameterName, Value, Use = True) Export
	
	If Use Then
		List.Parameters.SetParameterValue(ParameterName, Value);
	Else
		ParameterValue = List.Parameters.FindParameterValue(New DataCompositionParameter(ParameterName));
		If ParameterValue <> Undefined Then
			ParameterValue.Value = Value;
			ParameterValue.Use = False;
		EndIf;
	EndIf;
	
EndProcedure 

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region Functions_for_working_with_managed_forms

// Gets the form attribute value. 
// Parameters:
// 	Form - Managed form;
//		AttributePath - string - data path, for example: "Object.ShippingDate".
//
Function GetFormAttributeByPath(Form, AttributePath) Export
	
	NameArray = StringFunctionsClientServer.SplitStringIntoSubstringArray(AttributePath, ".");
	
	Object = Form;
	LastField = NameArray[NameArray.Count()-1];
	
	For Cnt = 0 to NameArray.Count()-2 Do
		Object = Object[NameArray[Cnt]]
	EndDo;
	
	Return Object[LastField];
	
EndFunction

// Sets the value to the form attribute.
// Parameters:
// 	Form - Managed form;
// 	AttributePath - string - data path, for example: "Object.ShippingDate".
//		Value - new value.
//
Procedure SetFormAttributeByPath(Form, AttributePath, Value, NotFilledOnly = False) Export
	
	NameArray = StringFunctionsClientServer.SplitStringIntoSubstringArray(AttributePath, ".");
	
	Object = Form;
	LastField = NameArray[NameArray.Count()-1];
	
	For Cnt = 0 to NameArray.Count()-2 Do
		Object = Object[NameArray[Cnt]]
	EndDo;
	If Not NotFilledOnly Or Not ValueIsFilled(Object[LastField]) Then
		Object[LastField] = Value;
	EndIf;
	
EndProcedure

// Searches for a filter item in the collection by the specified presentation. 
//
// Parameters:
// WhereToAdd - container with items and groups of the filter, for example
// List.Filter or a group in the filter;
// Presentation - String - group presentation;
//
Function FindFilterItemByPresentation(ItemCollection, Presentation) Export
	
	ReturnValue = Undefined;
	
	For Each FilterItem In ItemCollection Do
		If FilterItem.Presentation = Presentation Then
			ReturnValue = FilterItem;
			Break;
		EndIf;
	EndDo;
	
	Return ReturnValue
	
EndFunction

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region Other_functions

// Determines the infobase mode: file (True) or client/server (False).
// This function requires the InfoBaseConnectionString parameter. 
// You can specify this parameter explicitly.
//
// Parameters:
// InfoBaseConnectionString - String - if this parameter is empty, 
// the connection string of the current infobase connection is used.
//
// Returns:
// Boolean.
//
Function FileInfoBase(Val InfoBaseConnectionString = "") Export
			
	If IsBlankString(InfoBaseConnectionString) Then
		InfoBaseConnectionString = InfoBaseConnectionString();
	EndIf;
	Return Find(Upper(InfoBaseConnectionString), "FILE=") = 1;
	
EndFunction 

// Returns a parameter structure template for establishing an external connection.
// Parameters have to be filled with required values and be passed
// to the CommonUse.SetExternalConnection() method.
//
Function ExternalConnectionParameterStructure() Export
	
	ParametersStructure = New Structure;
	ParametersStructure.Insert("InfoBaseOperationMode", 0);
	ParametersStructure.Insert("InfoBaseDirectory", "");
	ParametersStructure.Insert("PlatformServerName", "");
	ParametersStructure.Insert("InfoBaseNameAtPlatformServer", "");
	ParametersStructure.Insert("OSAuthorization", False);
	ParametersStructure.Insert("UserName", "");
	ParametersStructure.Insert("UserPassword", "");
	
	Return ParametersStructure;
EndFunction

// Extracts connection parameters from the infobase connection string 
// and passes parameters to structure for setting an external connections.
//
Function GetConnectionParametersFromInfoBaseConnectionString(Val ConnectionString) Export
	
	Result = ExternalConnectionParameterStructure();
	
	Parameters = StringFunctionsClientServer.GetParametersFromString(ConnectionString);
	
	Parameters.Property("File", Result.InfoBaseDirectory);
	Parameters.Property("Srvr", Result.PlatformServerName);
	Parameters.Property("Ref", Result.InfoBaseNameAtPlatformServer);
	
	Result.InfoBaseOperationMode = ?(Parameters.Property("File"), 0, 1);
	
	Return Result;
EndFunction

// Gets value tree row ID (GetID() method) for the specified tree row field value.
// Is used to determine the cursor position in hierarchical lists.
//
Procedure GetTreeRowIDByFieldValue(FieldName, RowID, TreeItemCollection, RowKey, StopSearch) Export
	
	For Each TreeRow In TreeItemCollection Do
		
		If StopSearch Then
			Return;
		EndIf;
		
		If TreeRow[FieldName] = RowKey Then
			
			RowID = TreeRow.GetID();
			
			StopSearch = True;
			
			Return;
			
		EndIf;
		
		ItemCollection = TreeRow.GetItems();
		
		If ItemCollection.Count() > 0 Then
			
			GetTreeRowIDByFieldValue(FieldName, RowID, ItemCollection, RowKey, StopSearch);
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Replaces prohibited characters in the XML string with the specified characters.
//
// Parameters:
// Text – String – prohibited characters in this string will be replaced;
// ReplacementChar – String – prohibited characters in XML string will be replaced with this string.
// 
// Returns:
// String - resulting string.
//
Function ReplaceDisallowedXMLCharacters(Val Text, ReplacementChar = " ") Export
	
#If Not WebClient Then
	BeginningPosition = 1;
	While True Do
		Position = FindDisallowedXMLCharacters(Text, BeginningPosition);
		If Position = 0 Then
			Break;
		EndIf;
		// If returned position is greater than it can be, it has to be corrected.
		If Position > 1 Then
			DisallowedChar = Mid(Text, Position - 1, 1);
			If FindDisallowedXMLCharacters(DisallowedChar) > 0 Then
				Text = StrReplace(Text, DisallowedChar, ReplacementChar);
			EndIf;
		EndIf;
		DisallowedChar = Mid(Text, Position, 1);
		If FindDisallowedXMLCharacters(DisallowedChar) > 0 Then
			Text = StrReplace(Text, DisallowedChar, ReplacementChar);
		EndIf;
		BeginningPosition = Position + 1;
	EndDo;
#EndIf

	Return Text;
EndFunction

// Deletes prohibited characters from the XML string.
//
// Parameters:
// Text – String – prohibited characters in this string will be deleted.
// 
// Returns:
// String - resulting string.
//
Function DeleteDisallowedXMLCharacters(Val Text) Export
	
	Return ReplaceDisallowedXMLCharacters(Text, "");
	
EndFunction

// Compares two schedules.
//
// Parameters
//  Schedule1, Schedule2 - JobSchedule.
//
// Returns
// Boolean - True if the schedules are equal, otherwise is False.
//
Function SchedulesAreEqual(Val Schedule1, Val Schedule2) Export
	Schedule1 = ScheduleToStructure(Schedule1);
	Schedule2 = ScheduleToStructure(Schedule2);
	
	For Each ScheduleAttribute In Schedule1 Do
		If TypeOf(ScheduleAttribute.Value) <> Type("Array") Then
			If ScheduleAttribute.Value <> Schedule2[ScheduleAttribute.Key] Then
				Return False;
			EndIf;
		Else
			If ScheduleAttribute.Value.Count() <> Schedule2[ScheduleAttribute.Key].Count() Then
				Return False;
			EndIf;
			
			For ItemNumber = 0 to ScheduleAttribute.Value.Count()-1 Do
				If ScheduleAttribute.Key = "DetailedDailySchedules" Then
					If Not SchedulesAreEqual(ScheduleAttribute.Value[ItemNumber],Schedule2[ScheduleAttribute.Key][ItemNumber]) Then
						Return False;
					EndIf;
				Else
					If ScheduleAttribute.Value[ItemNumber] <> Schedule2[ScheduleAttribute.Key][ItemNumber] Then
						Return False;
					EndIf;
				EndIf;
			EndDo;
		EndIf;
	EndDo;
	
	Return True;
EndFunction

// Sets Value to the PropertyName property of the ItemName form item.
// This procedure is used when the form item is absent from the form because
// the user is not authorized to access the object, the object item, or a command.
//
// Parameters:
// FormItems - Items property of the managed form;
// ItemName - String - form item name;
// PropertyName - String - name of the form item property to be set;
// Value - Arbitrary - new item value;
//
Procedure SetFormItemProperty(FormItems, ItemName, PropertyName, Value) Export

	FormItem = FormItems.Find(ItemName);
	If FormItem <> Undefined Then
		FormItem[PropertyName] = Value;
	EndIf;

EndProcedure 

// Returns a PropertyName property value of the ItemName form item.
// This procedure is used when the form item is absent from the form because
// the user is not authorized to access the object, the object item, or a command.
//
// Parameters:
// FormItems - Items property of the managed form;
// ItemName - String - form item name;
// PropertyName - String - name of the form item property to be set.
// 
// Returns:
// Arbitrary - PropertyName property value of the ItemName form item.
//
Function FormItemPropertyValue(FormItems, ItemName, PropertyName) Export

	FormItem = FormItems.Find(ItemName);
	Return ?(FormItem <> Undefined, FormItem[PropertyName], Undefined);

EndFunction 

#EndRegion

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region PRIVATE_IMPLEMENTATION

// Searches for the item in the value list or in the array.
//
Function FindInList(List, Item)
	
	Var ItemInList;
	
	If TypeOf(List) = Type("ValueList") Then
		If TypeOf(Item) = Type("ValueListItem") Then
			ItemInList = List.FindByValue(Item.Value);
		Else
			ItemInList = List.FindByValue(Item);
		EndIf;
	EndIf;
	
	If TypeOf(List) = Type("Array") Then
		ItemInList = List.Find(Item);
	EndIf;
	
	Return ItemInList;
	
EndFunction

// Checks that email address does not contain border characters.
// If border characters is used correctly, the procedure deletes them.
// Parameters:
// AddresseeFullName - String - recipient name;
// EmailAddress - String - email address;
// Returns:
// Structure with the following keys:
// Status - Boolean - flag that shows whether the operation completed successfully;
// ErrorMessage - contains an error message if the operation failed;
// Value - Structure - if the operation completed successfully, it contains an email address structure with the following keys:
// - Address - String;
// - Presentation - String.
//
Function CheckAndPrepareEmailAddress(Val AddresseeFullName, Val EmailAddress)
	
	ProhibitedCharInRecipientName = NStr("en = 'There is a prohibited character in the addressee name.'");
	EmailContainsProhibitedChar = NStr("en = 'There is a prohibited character in the email address.'");
	BorderChars = "<>[]";
	
	EmailAddress = TrimAll(EmailAddress);
	AddresseeFullName = TrimAll(AddresseeFullName);
	
	If Left(AddresseeFullName, 1) = "<" Then
		If Right(AddresseeFullName, 1) = ">" Then
			AddresseeFullName = Mid(AddresseeFullName, 2, StrLen(AddresseeFullName)-2);
		Else
			Raise ProhibitedCharInRecipientName;
		EndIf;
	ElsIf Left(AddresseeFullName, 1) = "[" Then
		If Right(AddresseeFullName, 1) = "]" Then
			AddresseeFullName = Mid(AddresseeFullName, 2, StrLen(AddresseeFullName)-2);
		Else
			Raise ProhibitedCharInRecipientName;
		EndIf;
	EndIf;
	
	If Left(EmailAddress, 1) = "<" Then
		If Right(EmailAddress, 1) = ">" Then
			EmailAddress = Mid(EmailAddress, 2, StrLen(EmailAddress)-2);
		Else
			Raise EmailContainsProhibitedChar;
		EndIf;
	ElsIf Left(EmailAddress, 1) = "[" Then
		If Right(EmailAddress, 1) = "]" Then
			EmailAddress = Mid(EmailAddress, 2, StrLen(EmailAddress)-2);
		Else
			Raise EmailContainsProhibitedChar;
		EndIf;
	EndIf;
	
	For Index = 1 to StrLen(BorderChars) Do
		If Find(AddresseeFullName, Mid(BorderChars, Index, 1)) <> 0
		 Or Find(EmailAddress, Mid(BorderChars, Index, 1)) <> 0 Then
			Raise EmailContainsProhibitedChar;
		EndIf;
	EndDo;
	
	Return New Structure("Address, Presentation", EmailAddress,AddresseeFullName);
	
EndFunction

// Shifts a position marker while the current character is the SkippedChar.
// Returns number of marker position.
//
Function SkipChar(Val String,
Val CurrentIndex,
Val SkippedChar)
	
	Result = CurrentIndex;
	
	// Removes skipped characters, if any
	While CurrentIndex < StrLen(String) Do
		If Mid(String, CurrentIndex, 1) <> SkippedChar Then
			Return CurrentIndex;
		EndIf;
		CurrentIndex = CurrentIndex + 1;
	EndDo;
	
	Return CurrentIndex;
	
EndFunction

// Finds item in tree hierarchically.
Procedure FindRecursively(ItemCollection, ItemArray, SearchMethod, SearchValue)
	
	For Each FilterItem In ItemCollection Do
		
		If TypeOf(FilterItem) = Type("DataCompositionFilterItem") Then
			
			If SearchMethod = 1 Then
				If FilterItem.LeftValue = SearchValue Then
					ItemArray.Add(FilterItem);
				EndIf;
			ElsIf SearchMethod = 2 Then
				If FilterItem.Presentation = SearchValue Then
					ItemArray.Add(FilterItem);
				EndIf;
			EndIf;
		Else
			
			FindRecursively(FilterItem.Items, ItemArray, SearchMethod, SearchValue);
			
			If SearchMethod = 2 And FilterItem.Presentation = SearchMethod Then
				ItemArray.Add(FilterItem);
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Replaces all CharsToReplace in a string with spaces.
Function ReplaceCharsInStringWithSpaces(String, CharsToReplace)
	Result = String;
	For Position = 1 to StrLen(Chars) Do
		Result = StrReplace(Result, Mid(CharsToReplace, Position, 1), " ");
	EndDo;
	Return Result;
EndFunction

// Checks whether the string has left or right the chars form CharsToCheck string.
Function HasCharsLeftRight(String, CharsToCheck)
	For Position = 1 to StrLen(CharsToCheck) Do
		Char = Mid(CharsToCheck, Position, 1);
		CharFound = (Left(String,1) = Char) Or (Right(String,1) = Char);
		If CharFound Then
			Return True;
		EndIf;
	EndDo;
	Return False;
EndFunction

// Checks whether the string has only allowed chars.
Function StringContainsAllowedCharsOnly(String, AllowedChars)
	CharacterArray = New Array;
	For Position = 1 to StrLen(AllowedChars) Do
		CharacterArray.Add(Mid(AllowedChars,Position,1));
	EndDo;
	
	For Position = 1 to StrLen(String) Do
		If CharacterArray.Find(Mid(String, Position, 1)) = Undefined Then
			Return False;
		EndIf;
	EndDo;
	
	Return True;
EndFunction

#EndRegion
