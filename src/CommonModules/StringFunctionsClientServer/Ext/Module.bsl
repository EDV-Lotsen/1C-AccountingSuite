
////////////////////////////////////////////////////////////////////////////////
// Basic functionality - String functions: Client & Server
//------------------------------------------------------------------------------
// Available on:
// - Client (managed application)
// - Server
// - External Connection
//

////////////////////////////////////////////////////////////////////////////////
#Region PUBLIC_INTERFACE

// Splits the string on several strings by the separator. The separator can be any length.
//
// Parameters:
// String - String - text with separators;
// Separator - String - text separator, at least 1 character;
// SkipEmptyStrings - Boolean - flag that shows whether empty strings should be included in a result;
// If this parameter has not been set, the function executes in compatibility with its earlier version mode:
// - if space is used as a separator, empty strings are not included in the result, for 
// other separators empty strings are included in the result.
// - if String parameter does not contain significant characters (or it is an empty string)
// and space is used as a separator, the function
// returns an array with a single empty string value (""),
// - if String parameter does not contain significant characters (or it is an empty string)
// and any character except space is used as a separator, the function
// returns an empty array.
// QuoteChar - String - quoted string delimiter. If not specified, then quoted strings are ignored.
// Typical quote char is double quote symbol ("). The quotes used in quoted string should be doubled ("").
//
// Returns:
// Array - array of strings.
//
// Examples:
// SplitStringIntoSubstringArray(",One,Two,", ",") - returns an array of 5 elements, three of them are empty strings;
// SplitStringIntoSubstringArray(",One,Two,", ",", True) - returns an array of 2 elements;
// SplitStringIntoSubstringArray(" one two ", " ") - returns an array of 2 elements;
// SplitStringIntoSubstringArray("") - returns an empty array;
// SplitStringIntoSubstringArray("",,False) - returns an array with an empty string ("");
// SplitStringIntoSubstringArray("", " ") - returns an array with an empty string ("");
//
Function SplitStringIntoSubstringArray(Val String, Separator = ",", Val SkipEmptyStrings = Undefined, QuoteChar = "") Export
	
	// Define resulting strings array.
	Result = New Array;
	
	// Add an empty string to an array for backward compatibility.
	If SkipEmptyStrings = Undefined Then
		SkipEmptyStrings = ?(Separator = " ", True, False);
		If IsBlankString(String) Then 
			If Separator = " " Then
				Result.Add("");
			EndIf;
			Return Result;
		EndIf;
	EndIf;
	
	// Use quoted strings if quote char specified.
	UseQuotes    = Not IsBlankString(QuoteChar);
	QuotedStr    = "";
	QuoteCharLen = StrLen(QuoteChar);
	SeparatorLen = StrLen(Separator);
	
	// Get next separator position.
	Position = Find(String, Separator);
	While Position > 0 Do
		
		// Check quotes for quoted strings.
		If UseQuotes Then
			QuotedPosition = Find(?(QuotedStr <> "", QuotedStr, String), QuoteChar);
			If (QuotedPosition > 0) And (QuotedPosition < Position) Then
				
				// Get remaining part of the string
				QuotedStr = Mid(?(QuotedStr <> "", QuotedStr, String), QuotedPosition + QuoteCharLen);
				
				// Find the closing quote
				QuotedPosition = Find(QuotedStr, QuoteChar);
				While QuotedPosition > 0 Do
					
					// Check double quote
					If StrLen(QuotedStr) >= QuotedPosition + QuoteCharLen
					And Mid(QuotedStr, QuotedPosition + QuoteCharLen, QuoteCharLen) = QuoteChar Then
						// Double quote found, continue.
						QuotedStr = Mid(QuotedStr, QuotedPosition + 2 * QuoteCharLen);
					Else
						// Single closing quote found
						QuotedStr = Mid(QuotedStr, QuotedPosition + QuoteCharLen);
						Break;
					EndIf;
					
					// Find next quote position
					QuotedPosition = Find(QuotedStr, QuoteChar);
				EndDo;
				
				// Find next separator position.
				Position = Find(QuotedStr, Separator);
				If Position = 0 Then
					// No separators found. Interrupt cycle.
					Break;
				Else
					// New position of separator detected. Check of next possible quotes.
					Continue;
				EndIf;
			EndIf;
			
			// Check quotation was previously found.
			If QuotedStr <> "" Then
				// Recalculate separator position to the original string.
				Position = Position + (StrLen(String) - StrLen(QuotedStr));
				// Clear used quoted string.
				QuotedStr = "";
			EndIf;
		EndIf;
		
		// Get current element and add it to the array.
		Substring = Left(String, Position - 1);
		If Not SkipEmptyStrings Or Not IsBlankString(Substring) Then
			If UseQuotes And Left(Substring, 1) = QuoteChar And Right(Substring, 1) = QuoteChar Then
				// Cut quoted string.
				Result.Add(Mid(Substring, 2, StrLen(Substring) - 2));
			Else
				// Add string.
				Result.Add(Substring);
			EndIf;
		EndIf;
		
		// Cut rest of string and recalculate the next separator position.
		String = Mid(String, Position + SeparatorLen);
		Position = Find(String, Separator);
	EndDo;
	
	// Add rest of the string to the array.
	If Not SkipEmptyStrings Or Not IsBlankString(String) Then
		If UseQuotes And Left(String, 1) = QuoteChar And Right(String, 1) = QuoteChar Then
			// Cut quoted string.
			Result.Add(Mid(String, 2, StrLen(String) - 2));
		Else
			// Add string.
			Result.Add(String);
		EndIf;
	EndIf;
	
	// Return resulting array.
	Return Result;
	
EndFunction 

// Merges strings from the array into a string with separators.
//
// Parameters:
// Array - Array - array of strings to be merged into a single string;
// Separator - String - any character set that will be used as a separator.
//
// Returns:
// String - string with separators.
//
Function GetStringFromSubstringArray(Array, Separator = ",") Export
	
	// The value that is returned
	Result = "";
	
	For Each Element In Array Do
		
		Substring = ?(TypeOf(Element) = Type("String"), Element, String(Element));
		
		SubstringSeparator = ?(IsBlankString(Result), "", Separator);
		
		Result = Result + SubstringSeparator + Substring;
		
	EndDo;
	
	Return Result;
	
EndFunction

// Determines whether the character is a separator.
//
// Parameters:
// CharCode - Number - character code;
// WordSeparators - String - separator characters.
//
// Returns:
// Boolean - True if the character is a separator.
//
Function IsWordSeparator(CharCode, WordSeparators = "") Export
	
	If Not IsBlankString(WordSeparators) Then
		
		Return Find(WordSeparators, Char(CharCode)) > 0;
		
	Else
		
		Ranges = New Array;
		Ranges.Add(New Structure("Min,Max", 48, 57)); 		// numerals
		Ranges.Add(New Structure("Min,Max", 65, 90)); 		// capital Roman characters
		Ranges.Add(New Structure("Min,Max", 97, 122)); 		// lowercase Roman characters
		Ranges.Add(New Structure("Min,Max", 95, 95)); 		// the _ character
		
		For Each Range In Ranges Do
			If CharCode >= Range.Min And CharCode <= Range.Max Then
				Return False;
			EndIf;
		EndDo;
		
		Return True;
		
	EndIf;
	
EndFunction

// Splits the string into several strings using a specified separator set.
// If the WordSeparators parameter is not specified, any of the characters that are not Roman characters, 
// Cyrillic characters, numeric characters, or the _ character are considered separators.
//
// Parameters:
// String - String - string to be split into words;
// WordSeparators - String - string containing separator characters.
//
// Returns:
// Array of values whose elements are obtained by splitting the string.
//
// Example:
// SplitStringIntoWordArray("one-@#two2_!three") returns an array of values: "one", "two2_", "three";
// SplitStringIntoWordArray("one-@#two2_!three", "#@!_") returns an array of values: "one-", "two2", "three".
//
Function SplitStringIntoWordArray(Val String, WordSeparators = "") Export
	
	Words = New Array;
	
	TextSize = StrLen(String);
	WordStart = 1;
	For Position = 1 to TextSize Do
		CharCode = CharCode(String, Position);
		If IsWordSeparator(CharCode, WordSeparators) Then
			If Position <> WordStart Then
				Words.Add(Mid(String, WordStart, Position - WordStart));
			EndIf;
			WordStart = Position + 1;
		EndIf;
	EndDo;
	
	If Position <> WordStart Then
		Words.Add(Mid(String, WordStart, Position - WordStart));
	EndIf;
	
	Return Words;
	
EndFunction

// Substitutes the parameters in the string. The maximum number of the parameters is 9.
// Parameters in the string are specified as %<parameter number>. Parameter numbering starts with 1.
//
// Parameters:
// SubstitutionString – String – string pattern that includes parameters in the following format: %ParameterName;
// Parameter<n> - String - parameter to be substituted.
//
// Returns:
// String – string with substituted parameters.
//
// Example:
// SubstituteParametersInString(NStr("en='%1 went to %2'"), "John", "a zoo") = "John went to a zoo".
//
Function SubstituteParametersInString(Val SubstitutionString,
	Val Parameter1, Val Parameter2 = Undefined, Val Parameter3 = Undefined,
	Val Parameter4 = Undefined, Val Parameter5 = Undefined, Val Parameter6 = Undefined,
	Val Parameter7 = Undefined, Val Parameter8 = Undefined, Val Parameter9 = Undefined) Export
	
	If SubstitutionString = Undefined Or StrLen(SubstitutionString) = 0 Then
		Return "";
	EndIf;
	
	Result = "";
	StartPosition = 1;
	Position = 1;
	While Position <= StrLen(SubstitutionString) Do
		StringChar = Mid(SubstitutionString, Position, 1);
		If StringChar <> "%" Then
			Position = Position + 1;
			Continue;
		EndIf;
		Result = Result + Mid(SubstitutionString, StartPosition, Position - StartPosition);
		Position = Position + 1;
		StringChar = Mid(SubstitutionString, Position, 1);
		
		If StringChar = "%" Then
			Position = Position + 1;
			StartPosition = Position;
			Result = Result + "%";
			Continue;
		EndIf;
		
		Try
			ParameterNumber = Number(StringChar);
		Except
			Raise NStr("en='SubstitutionString source string has an invalid format: %'" + StringChar);
		EndTry;
		
		If StringChar = "1" Then
			ParameterValue = Parameter1;
		ElsIf StringChar = "2" Then
			ParameterValue = Parameter2;
		ElsIf StringChar = "3" Then
			ParameterValue = Parameter3;
		ElsIf StringChar = "4" Then
			ParameterValue = Parameter4;
		ElsIf StringChar = "5" Then
			ParameterValue = Parameter5;
		ElsIf StringChar = "6" Then
			ParameterValue = Parameter6;
		ElsIf StringChar = "7" Then
			ParameterValue = Parameter7;
		ElsIf StringChar = "8" Then
			ParameterValue = Parameter8;
		ElsIf StringChar = "9" Then
			ParameterValue = Parameter9;
		Else
			Raise NStr("en='SubstitutionString source string has an invalid format: %'" + ParameterValue);
		EndIf;
		If ParameterValue = Undefined Then
			ParameterValue = "";
		Else
			ParameterValue = String(ParameterValue);
		EndIf;
		Result = Result + ParameterValue;
		Position = Position + 1;
		StartPosition = Position;
	
	EndDo;
	
	If (StartPosition <= StrLen(SubstitutionString)) Then
		Result = Result + Mid(SubstitutionString, StartPosition, StrLen(SubstitutionString) - StartPosition + 1);
	EndIf;
	
	Return Result;
	
EndFunction

// Substitutes the parameters in the string. The number of the parameters in the string is unlimited.
// Parameters in the string are specified as %<parameter number>. Parameter numbering 
// starts with 1.
//
// Parameters:
// SubstitutionString – String – string pattern that includes parameters in the following format: %ParameterName;
// ParameterArray - Array - array of strings that corresponds to the parameters in the substitution string.
//
// Returns:
// String – string with substituted parameters.
//
// Example:
// ParameterArray = New Array;
// ParameterArray = ParameterArray.Add("John");
// ParameterArray = ParameterArray.Add("a zoo");
//
// String = SubstituteParametersInString(NStr("en='%1 went to %2'"), ParameterArray);
//
Function SubstituteParametersInStringFromArray(Val SubstitutionString, Val ParameterArray) Export
	
	ResultString = SubstitutionString;
	
	Index = ParameterArray.Count();
	While Index > 0 Do
		Value = ParameterArray[Index - 1];
		If Not IsBlankString(Value) Then
			ResultString = StrReplace(ResultString, "%" + Format(Index, "NG="), Value);
		EndIf;
		Index = Index - 1;
	EndDo;
	
	Return ResultString;
	
EndFunction

// Substitutes parameter values for their names in the string pattern. Parameters in the string are enclosed in braces.
// Optional parameters are enclosed in braces preceded by question mark (?), optional templates are placed in string after vertical bar (|).
// Optional template will be placed in original string if it's value isn't empty.
//
// Parameters:
//
// StringPattern  - String    - string where values will be substituted;
// ValuesToInsert - Structure - value structure where keys are parameter names without reserved characters
//                              and values are values to be substituted.
// ValuesFormat   - Structure - value structure where keys are parameter names without reserved characters
//                              and values are format strings to be applied to value before filling the pattern.
//
// Returns:
// String - string with substituted values.
//
// Example:
// SubstituteParametersInStringByName("Hello, {Name} {Surname}.", New Structure("Surname,Name", "Doe", "John"));
// Returns: "Hello, John Doe".
//
// Example:
// SubstituteParametersInStringByName("Hello?{Name}!|Name = "", dear {Name}"" ", New Structure("Name", "John Doe"));
// Returns: "Hello, dear John Doe!". If value Name in structure will be empty the function will return: "Hello!".
//
Function SubstituteParametersInStringByName(Val StringPattern, ValuesToInsert, ValuesFormat = Undefined) Export
	
	Result    = StringPattern;
	FormatStr = "";
	
	OptionalPartsDelimiterPosition = Find(StringPattern, "|");
	If OptionalPartsDelimiterPosition > 0 Then
		
		// Decode optional patterns from string.
		OptionalPatterns = GetParametersFromString(Mid(StringPattern, OptionalPartsDelimiterPosition + 1));
		OptionalPattern  = "";
		Result           = Left(StringPattern, OptionalPartsDelimiterPosition - 1);
		
		// Replace original patterns from string with their optional patterns.
		For Each Parameter In ValuesToInsert Do
			If ValueIsFilled(Parameter.Value) And OptionalPatterns.Property(Parameter.Key, OptionalPattern)Then
				Result = StrReplace(Result, "?{" + Parameter.Key + "}", OptionalPattern);
			Else
				Result = StrReplace(Result, "?{" + Parameter.Key + "}", "");
			EndIf;
		EndDo;
	EndIf;
	
	For Each Parameter In ValuesToInsert Do
		
		// Check preserved formatting.
		ApplyFormat = ValueIsFilled(ValuesFormat) And ValuesFormat.Property(Parameter.Key, FormatStr);
		
		// Unar minus operation.
		If Find(Result, "{-" + Parameter.Key + "}") > 0 Then
			Result = StrReplace(Result, "{-" + Parameter.Key + "}", ?(ApplyFormat, Format(-Parameter.Value, FormatStr), -Parameter.Value));
		EndIf;
		
		// Standard operation.
		Result = StrReplace(Result, "{"  + Parameter.Key + "}", ?(ApplyFormat, Format(Parameter.Value, FormatStr), Parameter.Value));
	EndDo;
	
	Return Result;
	
EndFunction

// Gets parameter values from the string.
//
// Parameters:
// ParameterString - String - string that contains parameters, each of them is a substring
// in the following format: <Parameter name>=<Value>.
// Substrings are separated from each other by the ; character.
//
// Example:
// "File=""c:\InfoBases\Trade""; Usr=""Director"";"
//
// Returns:
// Structure - parameter structure, where keys are parameter names, and values are parameter values.
//
Function GetParametersFromString(Val ParameterString) Export
	
	Result = New Structure;
	
	DoubleQuoteChar = Char(34); // (")
	
	SubstringArray = SplitStringIntoSubstringArray(ParameterString, ";");
	
	For Each CurParameterString In SubstringArray Do
		
		FirstEqualSignPosition = Find(CurParameterString, "=");
		
		// Getting parameter name
		ParameterName = TrimAll(Left(CurParameterString, FirstEqualSignPosition - 1));
		
		// Getting parameter value
		ParameterValue = TrimAll(Mid(CurParameterString, FirstEqualSignPosition + 1));
		
		If Left(ParameterValue, 1) = DoubleQuoteChar
			And Right(ParameterValue, 1) = DoubleQuoteChar Then
			
			ParameterValue = Mid(ParameterValue, 2, StrLen(ParameterValue) - 2);
			
		EndIf;
		
		Try
			Result.Insert(ParameterName, ParameterValue);
		Except
		EndTry;
		
	EndDo;
	
	Return Result;
	
EndFunction

// Checks whether the string contains numeric characters only.
//
// Parameters:
// CheckString - String - string to be checked;
// IncludingLeadingZeros - Boolean - flag that shows whether the string to be checked can include leading zeros;
// IncludingSpaces - Boolean - flag that shows whether the string to be checked can includes spaces.
//
// Returns:
// True - string contains numeric characters only or is empty;
// False - string contains not only numeric characters.
//
Function OnlyDigitsInString(Val CheckString, Val IncludingLeadingZeros = True, Val IncludingSpaces = True) Export
	
	If TypeOf(CheckString) <> Type("String") Then
		Return False;
	EndIf;
	
	If Not ValueIsFilled(CheckString) Then
		Return True;
	EndIf;
	
	If Not IncludingSpaces Then
		CheckString = StrReplace(CheckString, " ", "");
	EndIf;
	
	If Not IncludingLeadingZeros Then
		FirstDigitNumber = 0;
		For a = 1 to StrLen(CheckString) Do
			FirstDigitNumber = FirstDigitNumber + 1;
			CharCode = CharCode(Mid(CheckString, a, 1));
			If CharCode <> 48 Then
				Break;
			EndIf;
		EndDo;
		CheckString = Mid(CheckString, FirstDigitNumber);
	EndIf;
	
	For a = 1 to StrLen(CheckString ) Do
		CharCode = CharCode(Mid(CheckString , a, 1));
		If Not (CharCode >= 48 And CharCode <= 57) Then
			Return False;
		EndIf;
	EndDo;
	
	Return True;
	
EndFunction

// Checks whether the string contains Roman characters only.
//
// Parameters:
// WithWordSeparators - Boolean - flag that shows whether the string to be checked can includes word separators.
// Available word separators are defined in the IsWordSeparator function;
// AllowedChars - string to be checked.
//
// Returns:
// True - string contains only Roman characters or is empty;
// False - string contains not only Roman characters.
//
Function OnlyRomanString(Val CheckString, Val WithWordSeparators = True, AllowedChars = "") Export
	
	If TypeOf(CheckString) <> Type("String") Then
		Return False;
	EndIf;
	
	If Not ValueIsFilled(CheckString) Then
		Return True;
	EndIf;
	
	ValidCharacterCodes = New Array;
	
	For a = 1 to StrLen(AllowedChars) Do
		ValidCharacterCodes.Add(CharCode(Mid(AllowedChars, a, 1)));
	EndDo;
	
	For a = 1 to StrLen(CheckString) Do
		CharCode = CharCode(Mid(CheckString, a, 1));
		If ((CharCode < 65) Or (CharCode > 90 And CharCode < 97) Or (CharCode > 122))
			And (ValidCharacterCodes.Find(CharCode) = Undefined) 
			And Not (Not WithWordSeparators And IsWordSeparator(CharCode)) Then
			Return False;
		EndIf;
	EndDo;
	
	Return True;
	
EndFunction

// Deletes double quotation marks from the beginning and the end of the string, if any.
//
// Parameters:
// String - source string;
//
// Returns:
// String - string without double quotation marks.
//
Function RemoveDoubleQuotationMarks(Val String) Export
	
	While Left(String, 1) = """" Do
		String = Mid(String, 2); 
	EndDo; 
	
	While Right(String, 1) = """" Do
		String = Left(String, StrLen(String) - 1);
	EndDo;
	
	Return String;
	
EndFunction 

// Deletes the specified number of characters from the end of the string.
//
// Parameters:
// Text - String - string where the last characters will be deleted;
// CharsCount - Number - the number of characters to be deleted.
//
Procedure DeleteLastCharsInString(Text, CharsCount) Export
	
	Text = Left(Text, StrLen(Text) - CharsCount);
	
EndProcedure 

// Searches for a character, starts from the end of the string.
//
// Parameters:
// String - String - string where search is performed;
// Char - String - character that the string is searched for.
//
// Returns:
// Number - character position in the string. 
// If the string does not contain the specified character, the function returns 0.
//
Function FindCharFromEnd(Val String, Val Char) Export
	
	For Position = -StrLen(String) to -1 Do
		If Mid(String, -Position, 1) = Char Then
			Return -Position;
		EndIf;
	EndDo;
	
	Return 0;
		
EndFunction

// Checks whether a string is a UUID.
// UUID is a string in the following format:
// XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX, where X = [0..9,a..f].
//
// Parameters:
// String - String - string to be checked.
//
// Returns:
// Boolean - True if the passed string is a UUID.
Function IsUUID(Val String) Export
	
	Pattern = "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX";
	
	If StrLen(Pattern) <> StrLen(String) Then
		Return False;
	EndIf;
	For Position = 1 to StrLen(String) Do
		If CharCode(Pattern, Position) = 88 And ((CharCode(String, Position) < 48 Or CharCode(String, Position) > 57) And (CharCode(String, Position) < 97 Or CharCode(String, Position) > 102))
			Or CharCode(Pattern, Position) = 45 And CharCode(String, Position) <> 45 Then
			Return False;
		EndIf;
	EndDo;
	
	Return True;

EndFunction

// Generates a string with the specified length filled with the specified character.
//
// Parameters:
// Char - string - character used for filling.
// StringLength - Number - required length of the resulting string.
//
// Returns:
// String - string filled with the specified character.
//
Function GenerateCharacterString(Val Char, Val StringLength) Export
	
	Result = "";
	For Counter = 1 to StringLength Do
		Result = Result + Char;
	EndDo;
	
	Return Result;
	
EndFunction

// Supplements the string to a specified length with characters on the left or on the right and returns it.
// Insignificant characters on the left and on the right are deleted. By default, the function supplements a string with the 0 (zero) character on the left.
//
// Parameters:
// String - String - source string to be supplemented with characters;
// StringLength - Number - required string length;
// Char - String - character used for supplementing the string;
// Mode - String - Left or Right - indicates whether the string is supplemented on the left or on the right.
// 
// Returns:
// String - string supplemented with characters.
//
// Example 1:
// String = "1234"; StringLength = 10; Char = "0"; Mode = "Left"
// Returns: "0000001234"
//
// Example 2:
// String = " 1234 "; StringLength = 10; Char = "#"; Mode = "Right"
// Returns: "1234######"
//
Function SupplementString(Val String, Val StringLength, Val Char = "0", Val Mode = "Left") Export
	
	If IsBlankString(Char) Then
		Char = "0";
	EndIf;
	
	// The parameter must be a single character.
	Char = Left(Char, 1);
	
	// Deleting spaces on the left and on the right of the the string
	String = TrimAll(String);
	
	CharToAddCount = StringLength - StrLen(String);
	
	If CharToAddCount > 0 Then
		
		StringToAdd = GenerateCharacterString(Char, CharToAddCount);
		
		If Upper(Mode) = "LEFT" Then
			
			String = StringToAdd + String;
			
		ElsIf Upper(Mode) = "RIGHT" Then
			
			String = String + StringToAdd;
			
		EndIf;
		
	EndIf;
	
	Return String;
	
EndFunction

// Deletes repeating characters on the left or on the right of the string.
//
// Parameters:
// String - String - source string where repeating characters will be deleted;
// Char - String - character to be deleted;
// Mode - String - "Left" or "Right" - indicates whether characters are deleted on the left or on the right.
// Returns:
// String - truncated string.
//
Function DeleteDuplicatedChars(Val String, Val Char, Val Mode = "Left") Export
	
	If Upper(Mode) = "LEFT" Then
		
		While Left(String, 1)= Char Do
			
			String = Mid(String, 2);
			
		EndDo;
		
	ElsIf Upper(Mode) = "RIGHT" Then
		
		While Right(String, 1)= Char Do
			
			String = Left(String, StrLen(String) - 1);
			
		EndDo;
		
	EndIf;
	
	Return String;
EndFunction

// Replaces characters in the string.
//
// Parameters:
// CharsToReplace - String - string of characters that will be replaced;
// String - String - source string;
// ReplacementChars - String - string of characters for replacing CharsToReplace characters.
// 
// Returns:
// String - string with character replaced.
//
// Note: The function is intended for simple replacement scenarios, for example, for replacing the Ä character with the A character.
// The function processes the passed string sequentially, therefore:
// ReplaceOneCharsWithAnother("pd", "spider", "np") returns "sniper",
// ReplaceOneCharsWithAnother("dr", "spider", "rd") does not return "spired".
//
Function ReplaceCharsWithAnother(CharsToReplace, String, ReplacementChars) Export
	
	Result = String;
	
	For CharacterNumber = 1 to StrLen(CharsToReplace) Do
		Result = StrReplace(Result, Mid(CharsToReplace, CharacterNumber, 1), Mid(ReplacementChars, CharacterNumber, 1));
	EndDo;
	
	Return Result;
	
EndFunction

// Converting the Arabic number into a Roman one.
//
// Parameters:
//	ArabicNumber	- integer from 0 to 999;
//
// Returns:
//	String - number in Roman notation.
//
// Example:
//	ConvertNumberIntoRomanNotation(17) = "XVII".
//
Function ConvertNumberIntoRomanNotation(ArabicNumber) Export
	
	RomanNumber	= "";
	ArabicNumber	= SupplementString(ArabicNumber, 3);

	c1 = "I"; c5 = "V"; c10 = "X"; c50 = "L"; c100 ="C"; c500 = "D"; c1000 = "M";

	Units	= Number(Mid(ArabicNumber, 3, 1));
	Tens	= Number(Mid(ArabicNumber, 2, 1));
	Hundreds	= Number(Mid(ArabicNumber, 1, 1));
	
	RomanNumber = RomanNumber + ConvertDigitIntoRomanNotation(Hundreds, c100, c500, c1000);
	RomanNumber = RomanNumber + ConvertDigitIntoRomanNotation(Tens, c10, c50, c100);
	RomanNumber = RomanNumber + ConvertDigitIntoRomanNotation(Units, c1, c5, c10);
	
	Return RomanNumber;
	
EndFunction 

// Converts the Roman number into an Arabic one.
//
// Parameters:
//	RomanNumber - String - number in Roman notation;
//
// Returns:
//	Number in Arabic notation.
//
// Example:
//	ConvertNumberIntoArabNotation("XVII") = 17.
//
Function ConvertNumberIntoArabNotation(RomanNumber) Export
	
	ArabicNumber=0;
	
	c1 = "I"; c5 = "V"; c10 = "X"; c50 = "L"; c100 ="C"; c500 = "D"; c1000 = "M";
	
	RomanNumber = TrimAll(RomanNumber);
	CharsCount = StrLen(RomanNumber);
	
	For Cnt=1 to CharsCount Do
		If Mid(RomanNumber,Cnt,1) = c1000 Then
			ArabicNumber = ArabicNumber+1000;
		ElsIf Mid(RomanNumber,Cnt,1) = c500 Then
			ArabicNumber = ArabicNumber+500;
		ElsIf Mid(RomanNumber,Cnt,1) = c100 Then
			If (Cnt < CharsCount) And ((Mid(RomanNumber,Cnt+1,1) = c500) Or (Mid(RomanNumber,Cnt+1,1) = c1000)) Then
				ArabicNumber = ArabicNumber-100;
			Else
				ArabicNumber = ArabicNumber+100;
			EndIf;
		ElsIf Mid(RomanNumber,Cnt,1) = c50 Then
			ArabicNumber = ArabicNumber+50;
		ElsIf Mid(RomanNumber,Cnt,1) = c10 Then
			If (Cnt < CharsCount) And ((Mid(RomanNumber,Cnt+1,1) = c50) Or (Mid(RomanNumber,Cnt+1,1) = c100)) Then
				ArabicNumber = ArabicNumber-10;
			Else
				ArabicNumber = ArabicNumber+10;
			EndIf;
		ElsIf Mid(RomanNumber,Cnt,1) = c5 Then
			ArabicNumber = ArabicNumber+5;
		ElsIf Mid(RomanNumber,Cnt,1) = c1 Then
			If (Cnt < CharsCount) And ((Mid(RomanNumber,Cnt+1,1) = c5) Or (Mid(RomanNumber,Cnt+1,1) = c10)) Then
				ArabicNumber = ArabicNumber-1;
			Else
				ArabicNumber = ArabicNumber+1;
			EndIf;
		EndIf;
	EndDo;
	
	Return ArabicNumber;
	
EndFunction 

// Deletes HTML tags from the text and returns the unformatted text. 
//
// Parameters:
// SourceText - String - HTML formatted text.
//
// Returns:
// String - free of tags, scripts, and headers text.
//
Function ExtractTextFromHTML(Val SourceText) Export
	Result = "";
	
	Text = Lower(SourceText);
	
	// Removing everything except body
	Position = Find(Text, "<body");
	If Position > 0 Then
		Text = Mid(Text, Position + 5);
		SourceText = Mid(SourceText, Position + 5);
		Position = Find(Text, ">");
		If Position > 0 Then
			Text = Mid(Text, Position + 1);
			SourceText = Mid(SourceText, Position + 1);
		EndIf;
	EndIf;
	
	Position = Find(Text, "</body>");
	If Position > 0 Then
		Text = Left(Text, Position - 1);
		SourceText = Left(SourceText, Position - 1);
	EndIf;
	
	// Removing scripts
	Position = Find(Text, "<script");
	While Position > 0 Do
		ClosingTagPosition = Find(Text, "</script>");
		If ClosingTagPosition = 0 Then
			// Closing tag is not found, removing the remaining text.
			ClosingTagPosition = StrLen(Text);
		EndIf;
		Text = Left(Text, Position - 1) + Mid(Text, ClosingTagPosition + 9);
		SourceText = Left(SourceText, Position - 1) + Mid(SourceText, ClosingTagPosition + 9);
		Position = Find(Text, "<script");
	EndDo;
	
	// Removing styles
	Position = Find(Text, "<style");
	While Position > 0 Do
		ClosingTagPosition = Find(Text, "</style>");
		If ClosingTagPosition = 0 Then
			// Closing tag is not found, removing the remaining text.
			ClosingTagPosition = StrLen(Text);
		EndIf;
		Text = Left(Text, Position - 1) + Mid(Text, ClosingTagPosition + 8);
		SourceText = Left(SourceText, Position - 1) + Mid(SourceText, ClosingTagPosition + 8);
		Position = Find(Text, "<style");
	EndDo;
	
	// Removing all tags
	Position = Find(Text, "<");
	While Position > 0 Do
		Result = Result + Left(SourceText, Position-1);
		Text = Mid(Text, Position + 1);
		SourceText = Mid(SourceText, Position + 1);
		Position = Find(Text, ">");
		If Position > 0 Then
			Text = Mid(Text, Position + 1);
			SourceText = Mid(SourceText, Position + 1);
		EndIf;
		Position = Find(Text, "<");
	EndDo;
	Result = Result + SourceText;
	
	Return TrimAll(Result);
	
EndFunction

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region PRIVATE_IMPLEMENTATION

// Converting the Arabic numerals into a Roman ones. 
//
// Parameters
//	Digit - Number - numeral from 0 to 9;
// RomanOne, RomanFive, RomanTen - String - characters representing Roman numerals.
//
// Returns
//	String - characters in the Roman notation.
//
// Example: 
//	ConvertDigitIntoRomanNotation(7,"I","V","X") = "VII".
//
Function ConvertDigitIntoRomanNotation(Digit, RomanOne, RomanFive, RomanTen)
	
	RomanDigit="";
	If Digit = 1 Then
		RomanDigit = RomanOne;
	ElsIf Digit = 2 Then
		RomanDigit = RomanOne + RomanOne;
	ElsIf Digit = 3 Then
		RomanDigit = RomanOne + RomanOne + RomanOne;
	ElsIf Digit = 4 Then
		RomanDigit = RomanOne + RomanFive;
	ElsIf Digit = 5 Then
		RomanDigit = RomanFive;
	ElsIf Digit = 6 Then
		RomanDigit = RomanFive + RomanOne;
	ElsIf Digit = 7 Then
		RomanDigit = RomanFive + RomanOne + RomanOne;
	ElsIf Digit = 8 Then
		RomanDigit = RomanFive + RomanOne + RomanOne + RomanOne;
	ElsIf Digit = 9 Then
		RomanDigit = RomanOne + RomanTen;
	EndIf;
	Return RomanDigit;
	
EndFunction

#EndRegion
