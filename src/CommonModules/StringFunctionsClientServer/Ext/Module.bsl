
////////////////////////////////////////////////////////////////////////////////
// PROCEDURES AND FUNCTIONS FOR OPERATIONS WITH STRINGS

// Function "splits" string into sunstrings, using specified
//      separator. Separator can be of any length.
//      If separator is space, then adjacent spaces
//      are considered as one separator, but leading and endinf spaces of the Str parameter
//      are ignored.
//      For example,
//      DecomposeStringIntoSubstringsArray(",one,,,two", ",") will return the array of values containing 5 items,
//      three of which are empty strings, but
//      DecomposeStringIntoSubstringsArray(" one   two", " ") will return the array of values containing 2 items
//
//  Parameters:
//      Str 		-   String, that has to be split into substrings.
//                      Parameter is passed by value.
//      Separator   -   String-separator, by default - comma.
//
//  Value returned:
//      array of values, whose items are - substrings
//
Function DecomposeStringIntoSubstringsArray(Val Str, Separator = ",") Export
	
	RowsArray = New Array();
	If Separator = " " Then
		Str = TrimAll(Str);
		While 1 = 1 Do
			Pos = Find(Str, Separator);
			If Pos = 0 Then
				RowsArray.Add(Str);
				Return RowsArray;
			EndIf;
			RowsArray.Add(Left(Str, Pos - 1));
			Str = TrimL(Mid(Str, Pos));
		EndDo;
	Else
		SeparatorLength = StrLen(Separator);
		While 1 = 1 Do
			Pos = Find(Str, Separator);
			If Pos = 0 Then
				If (TrimAll(Str) <> "") Then
					RowsArray.Add(Str);
				EndIf;
				Return RowsArray;
			EndIf;
			RowsArray.Add(Left(Str,Pos - 1));
			Str = Mid(Str, Pos + SeparatorLength);
		EndDo;
	EndIf;
	
EndFunction 

// Returns string, generated from the array of items, separated with the char-separator
//
// Parameters:
//  Array  			- Array - array of items used to get the resultant string
//  Separator 		- String - arbitrary set of chars, which will be used as the separator of items in the string
//
// Value returned:
//  Result 			- String - string, generated from the array of items, separated with the char-separator
//
Function GetStringFromSubstringArray(Array, Separator = ",") Export
	
	// returned function value
	Result = "";
	
	For Each Item IN Array Do
		
		Substring = ?(TypeOf(Item) = Type("String"), Item, String(Item));
		
		SubstringSeparator = ?(IsBlankString(Result), "", Separator);
		
		Result = Result + SubstringSeparator + Substring;
		
	EndDo;
	
	Return Result;
	
EndFunction

// Compare two version strings.
//
// Parameters
//  VersionString1   – String – version number in format RR.{P|PP}.ZZ.AA
//  VersionString2   – String – second version number for the comparioson
//
// Value returned:
//   Number  		 – greater than 0, if VersionString1 > VersionString2; 0, if versions are identical.
//
Function CompareVersions(Val VersionString1, Val VersionString2) Export
	
	String1  = ?(IsBlankString(VersionString1), "0.0.0.0", VersionString1);
	String2  = ?(IsBlankString(VersionString2), "0.0.0.0", VersionString2);
	Version1 = DecomposeStringIntoSubstringsArray(String1, ".");
	If Version1.Count() <> 4 Then
		Raise SubstitureParametersInString(
		                    NStr("en = 'Incorrect format of the row of the version:%1'"), VersionString1);
	EndIf;
	Version2 = DecomposeStringIntoSubstringsArray(String2, ".");
	If Version2.Count() <> 4 Then
		Raise SubstitureParametersInString(
	                         NStr("en = 'Incorrect format of the row of the version:%1'"), VersionString2);
	EndIf;
	
	Result = 0;
	For Digit = 0 To 3 Do
		Result = Number(Version1[Digit]) - Number(Version2[Digit]);
		If Result <> 0 Then
			Return Result;
		EndIf;
	EndDo;
	Return Result;
	
EndFunction

// Puts parameters in string. Maximum possible number of parameters - 9.
// Parameters in string are sprecified as %<parameter number>. Numeration of the parameters
// is started from 1.
//
// Parameters
//  LookupString  		– String – string template with parameters (occurrences of type "%ParameterName").
// Parameter<n>         - String - parameter
// Value returned:
//   String   			– text string with the replaced parameters
//
// Example:
// String = SubstitureParametersInString(NStr("en = '%1 went to the %2'"), "John", "Zoo");
//
Function SubstitureParametersInString( Val LookupString,
									Val Parameter1,
									Val Parameter2 = Undefined,
									Val Parameter3 = Undefined,
									Val Parameter4 = Undefined,
									Val Parameter5 = Undefined,
									Val Parameter6 = Undefined,
									Val Parameter7 = Undefined,
									Val Parameter8 = Undefined,
									Val Parameter9 = Undefined) Export
	
	If LookupString = Undefined OR StrLen(LookupString) = 0 Then
		Return "";
	EndIf;
	
	Result 		 = "";
	BegPosition  = 1;
	CharPosition = 1;
	While CharPosition <= StrLen(LookupString) Do
		StringChar = Mid(LookupString, CharPosition, 1);
		If StringChar <> "%" Then
			CharPosition = CharPosition + 1;
			Continue;
		EndIf;
		Result = Result + Mid(LookupString, BegPosition, CharPosition - BegPosition);
		CharPosition = CharPosition + 1;
		StringChar = Mid(LookupString, CharPosition, 1);
		
		If StringChar = "%" Then
			CharPosition = CharPosition + 1;
			BegPosition = CharPosition;
			Continue;
		EndIf;
		
		Try
			ParameterNumber = Number(StringChar);
		Except
			Raise NStr("en = 'The LookupString input string is not formatted properly: '") + LookupString;
		EndTry;
		
		If StringChar = "1" Then
			ValueOfParameter = Parameter1;
		ElsIf StringChar = "2" Then
			ValueOfParameter = Parameter2;
		ElsIf StringChar = "3" Then
			ValueOfParameter = Parameter3;
		ElsIf StringChar = "4" Then
			ValueOfParameter = Parameter4;
		ElsIf StringChar = "5" Then
			ValueOfParameter = Parameter5;
		ElsIf StringChar = "6" Then
			ValueOfParameter = Parameter6;
		ElsIf StringChar = "7" Then
			ValueOfParameter = Parameter7;
		ElsIf StringChar = "8" Then
			ValueOfParameter = Parameter8;
		ElsIf StringChar = "9" Then
			ValueOfParameter = Parameter9;
		Else
			Raise NStr("en = 'The LookupString input string is not formatted properly: '") + LookupString;
		EndIf;
		If ValueOfParameter = Undefined Then
			ValueOfParameter = "";
		Else
			ValueOfParameter = String(ValueOfParameter);
		EndIf;
		Result = Result + ValueOfParameter;
		CharPosition = CharPosition + 1;
		BegPosition = CharPosition;
	
	EndDo;
	
	If (BegPosition <= StrLen(LookupString)) Then
		Result = Result + Mid(LookupString, BegPosition, StrLen(LookupString) - BegPosition + 1);
	EndIf;
	
	Return Result;
	
EndFunction

// Inserts parameters into string. Number of parameter is not restricted.
// Parameters in string are sprecified as %<parameter number>. Numeration of the parameters
// is started from 1.
//
// Parameters
//  LookupString  		– String – string template with parameters (occurrences of type "%1").
//  ArrayOfParameters   - Array  - array of strings, corresponding to the parameters in the insertion string
//
// Value returned:
//   String   			– text string with the replaced parameters
//
// Example:
// ArrayOfParameters = New Array;
// ArrayOfParameters = ArrayOfParameters.Add("John");
// ArrayOfParameters = ArrayOfParameters.Add("Zoo");
//
// String = SubstitureParametersInString(NStr("en = '%1 went to the %2'"), ArrayOfParameters);
//
Function SubstitureParametersInStringFromArray(Val LookupString, Val ArrayOfParameters) Export
	
	ResultString = LookupString;
	
	For IndexOf = 1 To ArrayOfParameters.Count() Do
		If Not IsBlankString(ArrayOfParameters[IndexOf-1]) Then
			ResultString = StrReplace(ResultString, "%"+String(IndexOf), ArrayOfParameters[IndexOf-1]);
		EndIf;
	EndDo;
	
	Return ResultString;
	
EndFunction

// Checks if string contains only digits.
//
// Parameters:
//  CheckString - string for verification.
//  TakeIntoAccountLeadingZeros - Boolean - should leading zeros be taken into account.
//  TakeIntoAccountSpaces - Boolean - should spaces be taken into account.
//
// Value returned:
//  True       - string contains only digits;
//  False      - string does not contain only digits.
//
Function StringContainsOnlyDigits(Val CheckString, Val TakeIntoAccountLeadingZeros = True, Val TakeIntoAccountSpaces = True) Export
	
	If TypeOf(CheckString) <> Type("String") Then
		Return False;
	EndIf;
	
	If NOT ValueIsFilled(CheckString) Then
		Return True;
	EndIf;
	
	If NOT TakeIntoAccountSpaces Then
		CheckString = StrReplace(CheckString, " ", "");
	EndIf;
	
	If NOT TakeIntoAccountLeadingZeros Then
		FirstDigitNumber = 0;
		For a = 1 To StrLen(CheckString) Do
			FirstDigitNumber = FirstDigitNumber + 1;
			CharCode = CharCode(Mid(CheckString, a, 1));
			If CharCode <> 48 Then
				Break;
			EndIf;
		EndDo;
		CheckString = Mid(CheckString, FirstDigitNumber);
	EndIf;
	
	For a = 1 To StrLen(CheckString) Do
		CharCode = CharCode(Mid(CheckString, a, 1));
		If NOT (CharCode >= 48 And CharCode <= 57) Then
			Return False;
		EndIf;
	EndDo;
	
	Return True;
	
EndFunction // StringContainsOnlyDigits()

// Removes double quotes from both ends, if they are present.
//
// Parameters:
//  String       - input string;
//
// Value returned:
//  String 		 - string without double quoted.
//
Function RemoveQuotes(Val String) Export
	
	Result = String;
	While Find(Result, """") = 1 Do
		Result = Mid(Result, 2); 
	EndDo; 
	While Find(Result, """") = StrLen(Result) Do
		Result = Mid(Result, 1, StrLen(Result) - 1); 
	EndDo; 
	Return Result;
	
EndFunction 

// Procedure deletes from string specified number of chars on the right
//
Procedure DeleteLatestCharInRow(Text, NumberOfCharacters1) Export
	
	Text = Left(Text, StrLen(Text) - NumberOfCharacters1);
	
EndProcedure 

// Finds char in string from the end
//
Function FindCharFromEnd(Val EntireString, Val OneSymbol) Export
	
	StartPosition = 1; 
	StringLength = StrLen(EntireString);
	
	For CurrentPosition = 1 To StrLen(EntireString) Do
		RealPosition 	= StringLength - CurrentPosition + 1;
		CurrentChar 	= Mid(EntireString, RealPosition, 1);
		If CurrentChar = OneSymbol Then
			Return RealPosition;
		EndIf;
	EndDo;
	
	Return 0;
	
EndFunction

// Function checks, if input string is UUID
//
Function ThisIsUUID(IDString) Export
	
	UIDString = IDString;
	Pattern = "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX";
	
	If StrLen(Pattern) <> StrLen(UIDString) Then
		Return False;
	EndIf;
	For Acc = 1 To StrLen(UIDString) Do
		If CharCode(Pattern, acc) = 88 And 
			((CharCode(UIDString, acc) < 48 OR CharCode(UIDString, acc) > 57) And (CharCode(UIDString, acc) < 97 or CharCode(UIDString, acc) > 102)) Then
			Return false; 
		 ElsIf CharCode(Pattern, acc) = 45 And CharCode(UIDString, acc) <> 45 Then
			Return False;
		EndIf;
	EndDo;
	
	Return True;

EndFunction

// Generates string of the repeated chars of the specified length
//
Function GenerateStringOfCharacters(Char, NumberOfCharacters) Export
	
	// returned function value
	Result = "";
	
	For IndexOf = 1 TO NumberOfCharacters Do
		
		Result = Result + Char;
		
	EndDo;
	
	Return Result;
EndFunction

// Supplements the string passed as first parameter ith chars on the right and on the left to the specfied lenght and returns it
// Meaningless chars on the left and on the right are deleted
// By default function adds string with zeros on the left
//
// Parameters:
//  String       - String - source string, that needs to be supplemented with chars to the desired length
//  StringLength - Number - required final string length
//  Char      	 - String - (optional) char value, used to supplement the string with
//  Mode       	 - String - (optional) [OnTheLeft|Ontheright] mode of inserting the chars to the source string: on the left or on the right
//
// Example 1:
// String = "1234"; StringLength = 10; Char = "0"; Mode = "OnTheLeft"
// Return: "0000001234"
//
// Example 2:
// String = " 1234  "; StringLength = 10; Char = "#"; Mode = "Ontheright"
// Return: "1234######"
//
// Value returned:
//  String - string, supplement with chars on the left or on the right
//
Function SupplementString(Val String, Val StringLength, Val Char = "0", Val Mode = "OnTheLeft") Export
	
	If IsBlankString(Char) Then
		Char = "0";
	EndIf;
	
	// char length should not be greater than 1
	Char = Left(Char, 1);
	
	// delete side spaces on the left and on the right
	String = TrimAll(String);
	
	NumberOfCharactersToAdd = StringLength - StrLen(String);
	
	If NumberOfCharactersToAdd > 0 Then
		
		RowToBeAdded = GenerateStringOfCharacters(Char, NumberOfCharactersToAdd);
		
		If Upper(Mode) = "ONTHELEFT" Then
			
			String = RowToBeAdded + String;
			
		ElsIf Upper(Mode) = "ONTHERIGHT" Then
			
			String = String + RowToBeAdded;
			
		EndIf;
		
	EndIf;
	
	Return String;
	
EndFunction

// Deletes repeated chars on the left / on the right in the input string
//
// Parameters:
//  String      - String - source string, from which repeated spaces should be removed
//  Char        - String - char value, that has to be removed
//  Mode        - String - (optional) [OnTheLeft|Ontheright] mode of inserting the chars to the source string: on the left or on the right
//
Function DeleteDuplicatedChars(Val String, Val Char, Val Mode = "OnTheLeft") Export
	
	If Upper(Mode) = "ONTHELEFT" Then
		
		While Left(String, 1)= Char Do
			
			String = Mid(String, 2);
			
		EndDo;
		
	ElsIf Upper(Mode) = "ONTHERIGHT" Then
		
		While Right(String, 1)= Char Do
			
			String = Left(String, StrLen(String) - 1);
			
		EndDo;
		
	EndIf;
	
	Return String;
EndFunction

// Gets configuration version number without the assebly number
//
// Parameters:
//  Version - String - configuration version in format RR.PP.ZZ.AA,
//                    where AA – is an assembly number, that will be removed
//
//  Value returned:
//  String  - configuration version number without assembly number in format RR.PP.ZZ
//
Function ConfigurationVersionWithoutAssemblyNumber(Val Version) Export
	
	Array = DecomposeStringIntoSubstringsArray(Version, ".");
	
	If Array.Count() < 3 Then
		Return Version;
	EndIf;
	
	Result = "[Revision].[Subedition].[Release1]";
	Result = StrReplace(Result, "[Revision]",   	Array[0]);
	Result = StrReplace(Result, "[Subedition]", 	Array[1]);
	Result = StrReplace(Result, "[Release1]",       Array[2]);
	
	Return Result;
EndFunction



