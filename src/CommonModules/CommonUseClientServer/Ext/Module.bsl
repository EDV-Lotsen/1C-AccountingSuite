
////////////////////////////////////////////////////////////////////////////////
// Client and server procedures of common use

// Generates and shows message, which can be linked with
// form control.
//
//	Parameters
//	UserMessageText				- String - message text.
//	ObjectOrRef					- Ref to IB object or object
//	Field						- String - description of form attribute
//	DataPath					- String - path to data (path to form attribute)
//	Cancellation						- Boolean - Out parameter.
//                                Being assigned value True in this procedure.
//
//	Usage examples:
//	1. For output message of managed form field, linked with object attribute:
//	CommonUseClientServer.MessageToUser(
//		NStr("en = 'Error message.'"), ,
//		"FieldInFormAttributeObject",
//		"Object");
//
//	Alternative variant of usage in object form:
//	CommonUseClientServer.MessageToUser(
//		NStr("en = 'Error message.'"), ,
//		"Object.FieldInFormAttributeObject");
//
//	2. For output message of managed form field, linked with form attribute:
//	CommonUseClientServer.MessageToUser(
//		NStr("en = 'Error message.'"), ,
//		"FormAttributeName");
//
//	3. For output message from code at server:
//	CommonUseClientServer.MessageToUser(
//		NStr("en = 'Error message.'"),ObjectRef,,,Cancellation);
//
Procedure MessageToUser(Val UserMessageText,
						Val ObjectOrRef = Undefined,
						Val Field 		= "",
						Val DataPath	= "",
						Cancellation  	= False) Export
	
	Message 		 = New UserMessage;
	Message.Text 	 = UserMessageText;
	Message.Field 	 = Field;
	Message.DataPath = DataPath;
	
	If ObjectOrRef <> Undefined Then
		Message.SetData(ObjectOrRef);
	EndIf;
	
	Message.Message();
	Cancellation = True;
	
EndProcedure

// Supplements receiver value table with data from source value table
//
// Parameters:
//  TableSource   - Value table - table where rows for filling will be taken
//  TableReceiver - Value table - table where rows from source table will be added
//
Procedure SupplementTable(TableSource, TableReceiver) Export
	
	For Each TableRowSource In TableSource Do
		
		FillPropertyValues(TableReceiver.Add(), TableRowSource);
		
	EndDo;
	
EndProcedure

// Supplements value table Table with values from array Array.
//
// Parameters:
//  Table 		- ValueTable - table, which has to be filled with values from array
//  Array 		- Array - array of values for filling value table
//  FieldName 	- String - name of value table field, where values from array have to be loaded
//
Procedure SupplementTableFromArray(Table, Array, FieldName) Export

	For Each Value In Array Do
		
		Table.Add()[FieldName] = Value;
		
	EndDo;
	
EndProcedure

// Unchecks one item of conditional appearance, if this is a value list.
// Parameters
// ConditionalAppearance 	- Conditional appearance of form item
// UserSettingID 			- String - settings ID
// Value 					- Value, that has to be removed from the appearance list
//
Procedure RemoveConditionalAppearanceOfValueList(ConditionalAppearance,
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
			ItemOfList = ItemFilterList.RightValue.FindByValue(Value);
			If ItemOfList <> Undefined Then
				ItemFilterList.RightValue.Delete(ItemOfList);
			EndIf;
			ItemFilterList.RightValue = ItemFilterList.RightValue;
			Return;
		EndIf;
	EndDo;
	
EndProcedure

// Deletes one value from array
//
// Parameters:
//  Array - array, where the value has to be deleted from
//  Value - value being deleted from array
//
Procedure DeleteValueFromArray(Array, Value) Export
	
	Index = Array.Find(Value);
	
	If Index <> Undefined Then
		
		Array.Delete(Index);
		
	EndIf;
	
EndProcedure

// Fills receiver-collection with values from source-collection
// Following types can be as source and receiver collections:
// ValueTable; ValueTree; ValueList and pr.
//
// Parameters:
//  CollectionSource 	- value collection, which is a source for data filling
//  CollectionReceiver 	- value collection, which is a receiver for data filling
//
Procedure FillPropertyCollection(CollectionSource, CollectionReceiver) Export
	
	For Each Item In CollectionSource Do
		
		FillPropertyValues(CollectionReceiver.Add(), Item);
		
	EndDo;
	
EndProcedure

// Gets array of values containing from marked items of value list
//
// Parameters:
//  List  - ValueList - value list to be used to create array of values
//
// Value returned:
//  Array - array of values containing from marked items of value list
//
Function GetArrayOfMarkedListItems(List) Export
	
	// returned function value
	Array = New Array;
	
	For Each Item In List Do
		
		If Item.Check Then
			
			Array.Add(Item.Value);
			
		EndIf;
		
	EndDo;
	
	Return Array;
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Functions for work with file system
//

// Procedure DeleteFilesInDirectory deletes all files in specified directory.
//
// Parameters:
//  Path         - String, directory full path, where all files
//                 has to be deleted.
//
Procedure DeleteFilesInDirectory(Path) Export
	
	Directory = New File(Path);
	
	If Directory.Exist() Then
		DeleteFiles(Path);
	EndIf;
	
EndProcedure // DeleteFilesInDirectory()

// Adds closing char-separator to the passed directory path,
// if it is required.
//
// Parameters
//  DirectoryPath  	- String - path to a directory
//
// Value returned:
//   String   		- path to a directory with closing char-separator.
//
// Usage examples:
//    Result = AddFinalPathSeparator("C:\My directory"); // returns "C:\My directory\"
//    Result = AddFinalPathSeparator("C:\My directory\"); // returns "C:\My directory\"
//    Result = AddFinalPathSeparator("ftp://My directory"); // returns "ftp://My directory/"
//
Function AddFinalPathSeparator(Val DirectoryPath) Export
	If IsBlankString(DirectoryPath) Then
		Return DirectoryPath;
	EndIf;
	
	PathSeparator = "\";
	If Find(DirectoryPath, "/") > 0 Then
		PathSeparator = "/";
	EndIf;
	
	Length = StrLen(DirectoryPath);
	If Length = 0 Then
		Return PathSeparator;
	ElsIf Mid(DirectoryPath, Length, 1) <> PathSeparator Then
		Return DirectoryPath + PathSeparator;
	Else 
		Return DirectoryPath;
	EndIf;
EndFunction

//  Compose full file name from directory name and file name.
//
// Parameters
//  DirectoryName  	– String, containing path to file directory on disk.
//  FileName     	– String, containing file name, without directory name.
//
// Value returned:
//   String 		– full file name with directory.
//
Function JoinFileName(Val DirectoryName, Val FileName) Export

	If Not IsBlankString(FileName) Then
		
		PathSeparator = "";
		If (Right(DirectoryName, 1) <> "\") And (Right(DirectoryName, 1) <> "/") Then
			PathSeparator = ?(Find(DirectoryName, "\") = 0, "/", "\");
		EndIf;
		
		Return DirectoryName + PathSeparator + FileName;
		
	Else
		
		Return DirectoryName;
		
	EndIf;

EndFunction

////////////////////////////////////////////////////////////////////////////////
// Functions for work with email addresses
//

// Function checks that string with e-mail addresses is entered correctly
//
// String format:
// Z = UserName|[User Name] [<]user@mail_server[>], String = Z[<separator*>Z]..
//
//   note.: separator* - any separator of addresses
//
// Parameters:
// AddressString - string - correct string with email addresses
//
// Value returned:
// Structure
// key Status - Boolean - success or failure of conversion
// in case of success contains key Value:
//           Array of structures, where
//                  Address- of e-mail recipient
//                  Presentation   - recipient name
// in case of failure contains key ErrorMessage - string
//
//  IMPORTANT: Function returns array of structures, where one field (any)
//         may be not filled. May be used by different
//         subsystems for their mapping of user name
//         to some e-mail address. That is why, it is required to check
//         before sending, that field of email address is filled.
//
Function ParseEmailString(Val EmailAddressString) Export
	
	Result = New Array;
	
	InvalidChars = "!#$%^&*()+`~|\/=";
	CharsSeparators = ";,";
	
	CharIndex = 1;           // number of char being processed
	Buffer = "";          	 // chars buffer, after analysis goes to either full name
							 // or to email address
	FullNameAddressee = "";  // variable, accumulating addressee name
	EmailAddress = "";       // variable, accumulating e-mail address
	// 1 - generate full name: any valid chars of addressee name are expected
	// 2 - generate email address: any valid chars of email address are expected
	// 3 - end generating of next email address - chars separators or spaces are expected
	ParsingPhase = 1; 
	
	MessageInvalidChars = NStr("en = 'Invalid chars in the postal address'");
	MessageWrongEmailAddressFormat = NStr("en = 'Incorrect format of the postal address.'");
	
	While CharIndex <= StrLen(EmailAddressString) Do
		
		Char = Mid(EmailAddressString, CharIndex, 1);
		
		If Char = " " Then
			CharIndex = ? ((SearchChar(EmailAddressString, CharIndex, " ") - 1) > CharIndex,
			             SearchChar(EmailAddressString, CharIndex, " ") - 1,
			             CharIndex);
			If ParsingPhase  = 1 Then
				FullNameAddressee = FullNameAddressee + Buffer + " ";
			ElsIf ParsingPhase = 2 Then
				EmailAddress = Buffer;
				ParsingPhase = 3;
			EndIf;
			Buffer = "";
		ElsIf Char = "@" Then
			If ParsingPhase = 1 Then
				ParsingPhase = 2;
				
				For SearchIndexNS = 1 To StrLen(Buffer) Do
					If Find(InvalidChars, Mid(Buffer, SearchIndexNS, 1)) > 0 Then
						Raise MessageInvalidChars;
					EndIf;
				EndDo;
				
				Buffer = Buffer + Char;
			ElsIf ParsingPhase = 2 Then
				Raise MessageWrongEmailAddressFormat;
			ElsIf ParsingPhase = 3 Then
				Raise MessageWrongEmailAddressFormat;
			EndIf;
		ElsIf Find(CharsSeparators, Char) > 0 Then
			
			If ParsingPhase = 1 Then
				FullNameAddressee = FullNameAddressee + Buffer;
			ElsIf ParsingPhase = 2 Then
				EmailAddress = Buffer;
			EndIf;
			
			ParsingPhase = 1;
			
			If Not (IsBlankString(FullNameAddressee) And IsBlankString(EmailAddress)) Then
				Result.Add(CheckAndPrepareEmailAddress(FullNameAddressee, EmailAddress));
			EndIf;
			
			EmailAddress 	  = "";
			FullNameAddressee = "";
			Buffer 		      = "";
		Else
			If ParsingPhase = 2 Or ParsingPhase = 3 Then
				If Find(InvalidChars, Char) > 0 Then
					Raise MessageInvalidChars;
				EndIf;
			EndIf;
			
			Buffer = Buffer + Char;
		EndIf;
		
		CharIndex = CharIndex + 1;
	EndDo;
	
	If ParsingPhase = 1 Then
		FullNameAddressee = FullNameAddressee + Buffer;
	ElsIf ParsingPhase = 2 Then
		EmailAddress = Buffer;
	EndIf;

	If NOT (IsBlankString(FullNameAddressee) And IsBlankString(EmailAddress)) Then
		Result.Add(CheckAndPrepareEmailAddress(FullNameAddressee, EmailAddress));
	EndIf;
	
	Return Result;
	
EndFunction

// Checks, that email address does not contain framing chars
// if framing chars are inserted correctly - removes them
// Parameters:
//  FullNameAddressee 	- String  - addressee name
//  MailAddress     	- String  - email address
// Value returned:
//  Structure:
//   Key status 		- Boolean - operation success either failure
//   ErrorMessage 	- if operation failed - contains error message
//   Value - structure 	- if operation is successful, contains saved structure of email
//                          address: keys - Address, Presentation (strings)
//
Function CheckAndPrepareEmailAddress(Val FullNameAddressee, Val EmailAddress)
	
	InvalidCharInAddresseeName  = NStr("en = 'Invalid character in addressee name'");
	InvalidCharInEmailAddress = NStr("en = 'Invalid character in e-mail address'");
	BorderChars = "<>[]";
	ValidEmailChars = "abcdefghijklmnopqrstuvwxyz0123456789-_.@";
	
	EmailAddress     	= TrimAll(EmailAddress);
	FullNameAddressee 	= TrimAll(FullNameAddressee);
	
	If Left(FullNameAddressee, 1) = "<" Then
		If Right(FullNameAddressee, 1) = ">" Then
			FullNameAddressee = Mid(FullNameAddressee, 2, StrLen(FullNameAddressee)-2);
		Else
			Raise InvalidCharInAddresseeName;
		EndIf;
	ElsIf Left(FullNameAddressee, 1) = "[" Then
		If Right(FullNameAddressee, 1) = "]" Then
			FullNameAddressee = Mid(FullNameAddressee, 2, StrLen(FullNameAddressee)-2);
		Else
			Raise InvalidCharInAddresseeName;
		EndIf;
	EndIf;
	
	If Left(EmailAddress, 1) = "<" Then
		If Right(EmailAddress, 1) = ">" Then
			EmailAddress = Mid(EmailAddress, 2, StrLen(EmailAddress)-2);
		Else
			Raise InvalidCharInEmailAddress;
		EndIf;
	ElsIf Left(EmailAddress, 1) = "[" Then
		If Right(EmailAddress, 1) = "]" Then
			EmailAddress = Mid(EmailAddress, 2, StrLen(EmailAddress)-2);
		Else
			Raise InvalidCharInEmailAddress;
		EndIf;
	EndIf;
	
	For CharIndex = 1 To StrLen(BorderChars) Do
		If Find(FullNameAddressee, Mid(BorderChars, CharIndex, 1)) <> 0
		   Or Find(EmailAddress,     Mid(BorderChars, CharIndex, 1)) <> 0 Then
			Raise InvalidCharInEmailAddress;
		EndIf;
	EndDo;
	
	If Not NotListedInValidCharsFoundInString(EmailAddress, ValidEmailChars) Then
		Raise InvalidCharInEmailAddress;
	EndIf;
	
	Return New Structure("Address, Presentation", EmailAddress,FullNameAddressee);
	
EndFunction

Function NotListedInValidCharsFoundInString(StringBeingChecked, ValidChars)
	
	For CharIndex = 1 To StrLen(StringBeingChecked) Do
		Char = Mid(StringBeingChecked, CharIndex, 1);
		
		If Find(ValidChars, Lower(Char)) = 0 Then
			Return False;
		EndIf;
		
	EndDo;
	
	Return True;
	
EndFunction

// Generates structure with keys Status (True) and Value
//
Function GenerateResultStructure(Val Value, Val Status = True) Export
	
	If Status Then
		Return New Structure("Status, Value", True, Value);
	Else
		Return New Structure("Status, ErrorMessage", False, Value);
	EndIf;
	
EndFunction

// Moves position marker until char Char is being met
// returns position number in the string, where marker stopped
//
Function SearchChar(Val String,
                    Val CurrentIndex,
                    Val SkippedChar)
	
	Result = CurrentIndex;
	
	// remove unneeded spaces if we have them
	While CurrentIndex < StrLen(String) Do
		If Mid(String, CurrentIndex, 1) <> SkippedChar Then
			Return CurrentIndex;
		EndIf;
		CurrentIndex = CurrentIndex + 1;
	EndDo;
	
	Return CurrentIndex;
	
EndFunction

#If Not WebClient Then
// Function GetTempDirectoryPath returns full path
// to new directory in directory of temporary files.
//
// Parameters:
//  ID 		- String, begining part of directory name in temporary directory.
//
// Value returned:
//  String 	- full name of temporary directory, for example "TempFilesDir() + DataProcessor123\".
//
Function GetTempDirectoryPath(Val Id) Export
	
	Index = 0;
	
	While True Do
		
		PathToDirectory  = TempFilesDir() + Id + String(Index) + "\";
		DirectoryOnDrive = New File(PathToDirectory);
		If Not DirectoryOnDrive.Exist() Then
			CreateDirectory(PathToDirectory);
			Return PathToDirectory;
		EndIf;
		Index = Index + 1;
		
	EndDo;
	
EndFunction // GetTempDirectoryPath()
#EndIf

////////////////////////////////////////////////////////////////////////////////
// Functions for work with filters of dynamic lists
//

// Search of dynamic list filter items and groups
// Parameters:
// ContainerForSearching 	- container with filter items and groups, for example
//					List.Filter
//					or group in filter
// FieldName 	- name of composition field (is not used for groups)
// Presentation - presentation of composition field
// Note: search can be done either by LeftValue, or by Presentation
//
Function FindFilterItemsAndGroups(Val ContainerForSearching,
								  Val FieldName = Undefined,
								  Val Presentation = Undefined) Export
	
	If ValueIsFilled(FieldName) Then
		SearchValue  = New DataCompositionField(FieldName);
		SearchMethod = 1;
	Else
		SearchMethod = 2;
		SearchValue  = Presentation;
	EndIf;
	
	ItemsArray = New Array;
	
	FindFilterItemRecursively(ContainerForSearching.Items, ItemsArray, SearchMethod, SearchValue);
	
	Return ItemsArray;
	
EndFunction

// Add filter group
// Parameters:
// ContainerForAdding 	- container with filter items and groups, for example
//					List.Filter
//					or group in filter
// GroupType 	- DataCompositionFilterItemsGroupType - group type
// Presentation string - group presentation
//
Function AddFiltersGroup(ContainerForAdding, Val GroupType, Val Presentation = "") Export
	
	Group 			    = ContainerForAdding.Items.Add(Type("DataCompositionFilterItemGroup"));
	Group.GroupType 	= GroupType;
	Group.Presentation  = Presentation;
	Group.Use 			= True;
	
	Return Group;
	
EndFunction

// Add composition item to composition item container
// Parameters:
// ContainerForAdding 		- Container with filter items and groups, for example
//						List.Filter
//						or group in filter
// FieldName 		- String - name for data composition field
// ComparisonKind 	- DataCompositionComparisonKind - comparison type
// RightValue 		- Arbitrary
// Presentation		- Presentation of data composition field
// Use - boolean 	- Item use
//
Function AddFilterItem(ContainerForAdding,
					   Val FieldName,
					   Val ComparisonType,
					   Val RightValue 		= Undefined,
					   Val Presentation  	= Undefined,
					   Val Use  			= Undefined) Export
	
	Item 				= ContainerForAdding.Items.Add(Type("DataCompositionFilterItem"));
	Item.LeftValue 		= New DataCompositionField(FieldName);
	Item.ComparisonType = ComparisonType;
	
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

// Modification of filter items
// Parameters
// FieldName 		- String - name of composition field
// ComparisonKind 	- DataCompositionComparisonKind - comparison type
// RightValue 		- Arbitrary
// Presentation 	- String - presentation of data composition item
//
Function ChangeFilterItems(ContainerForSearching,
						   Val FieldName 		= Undefined,
						   Val Presentation 	= Undefined,
						   Val RightValue		= Undefined,
						   Val ComparisonType 	= Undefined,
						   Val Use 				= Undefined) Export
	
	If ValueIsFilled(FieldName) Then
		SearchValue  = New DataCompositionField(FieldName);
		SearchMethod = 1;
	Else
		SearchMethod = 2;
		SearchValue  = Presentation;
	EndIf;
	
	ItemsArray = New Array;
	
	FindFilterItemRecursively(ContainerForSearching.Items, ItemsArray, SearchMethod, SearchValue);
	
	For Each Item In ItemsArray Do
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
	EndDo;
	
	Return ItemsArray.Count();
	
EndFunction

// Search of dynamic list filter items and groups
// Parameters:
// ContainerForDeleting - Container with filter items and groups, for example
//					List.Filter
//					or group in filter
// FieldName    - Name of composition field (is not used for groups)
// Presentation - Presentation of composition field
// Note: search can be done either by LeftValue, or by Presentation
//
Procedure DeleteFilterGroupItems(Val ContainerForDeleting,
								 Val FieldName 	  = Undefined,
								 Val Presentation = Undefined) Export
	
	If ValueIsFilled(FieldName) Then
		SearchValue  = New DataCompositionField(FieldName);
		SearchMethod = 1;
	Else
		SearchMethod = 2;
		SearchValue  = Presentation;
	EndIf;
	
	ItemsArray = New Array;
	
	FindFilterItemRecursively(ContainerForDeleting.Items, ItemsArray, SearchMethod, SearchValue);
	
	For Each Item In ItemsArray Do
		If Item.Parent = Undefined Then
			ContainerForDeleting.Items.Delete(Item);
		Else
			Item.Parent.Items.Delete(Item);
		EndIf;
	EndDo;
	
EndProcedure

// Is used to create filter item or, if it is not found,
// assigning properties for the existing items
// Parameters
// ContainerForAdding 	- container with filter items and groups, for example
//					List.Filter
//					or group in filter
// FieldName 			- String - name for data composition field (is filled always)
// Fields to be assigned:
// ComparisonKind		- DataCompositionComparisonKind - comparison type
// RightValue 			- Arbitrary
// Presentation 		- Presentation of data composition field
// Use - boolean 		- Item use
//
Procedure SetFilterItem(ContainerForAdding,
						Val FieldName,
						Val RightValue 		= Undefined,
						Val ComparisonType 	= Undefined,
						Val Presentation 	= Undefined,
						Val Use 			= Undefined) Export
	
	ModifiedCount = ChangeFilterItems(ContainerForAdding, FieldName, Presentation,
					         		  RightValue, ComparisonType, Use);
	
	If ModifiedCount = 0 Then
		If ComparisonType = Undefined Then
			ComparisonType = DataCompositionComparisonType.Equal;
		EndIf;
		AddFilterItem(ContainerForAdding, FieldName, ComparisonType,
					  RightValue, Presentation, Use);
	EndIf;
	
EndProcedure

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
	
EndProcedure // SetDynamicListParameter()

// Service functions

Procedure FindFilterItemRecursively(ItemCollection, ItemsArray, SearchMethod, SearchValue)
	
	For Each FilterItem In ItemCollection Do
		
		If TypeOf(FilterItem) = Type("DataCompositionFilterItem") Then
			
			If SearchMethod = 1 Then
				If FilterItem.LeftValue = SearchValue Then
					ItemsArray.Add(FilterItem);
				EndIf;
			ElsIf SearchMethod = 2 Then
				If FilterItem.Presentation = SearchValue Then
					ItemsArray.Add(FilterItem);
				EndIf;
			EndIf;
		Else
			
			FindFilterItemRecursively(FilterItem.Items, ItemsArray, SearchMethod, SearchValue);
			
			If SearchMethod = 2 And FilterItem.Presentation = SearchValue Then
				ItemsArray.Add(FilterItem);
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure
