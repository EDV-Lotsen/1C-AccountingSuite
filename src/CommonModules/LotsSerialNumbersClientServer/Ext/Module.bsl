
////////////////////////////////////////////////////////////////////////////////
// Lots & Serial numbers: Server module
//------------------------------------------------------------------------------
// Available on:
// - Server
// - External Connection
// - Client
//

////////////////////////////////////////////////////////////////////////////////
#Region PUBLIC_INTERFACE

//------------------------------------------------------------------------------
// Lots servicing functions.

//------------------------------------------------------------------------------
// Serials servicing functions.

// Decode serial numbers from arbitrary string.
//  SerialNumbersStr - String - String representation of product serial numbers.
//
// Returns:
//  Array - Decoded serial numbers array.
//
Function GetSerialNumbersArrayFromStr(SerialNumbersStr) Export
	
	// Check possible delimeters in group of serial numbers copied form clipboard.
	Str = TrimAll(SerialNumbersStr); SerialNumbers = New Array;
	Delimiters = ";," + Chars.CR + Chars.LF + Chars.Tab + " ";
	DelimiterFound = False;
	For i = 1 To StrLen(Delimiters) Do
		Delimiter = Mid(Delimiters, i, 1);
		If Find(Str, Delimiter) > 0 Then
			SerialNumbers  = StringFunctionsClientServer.SplitStringIntoSubstringArray(Str, Delimiter, True);
			DelimiterFound = True;
			Break;
		EndIf;
	EndDo;
	
	// If delimeters are not found, it is still possible, that only one item persists.
	If (Not DelimiterFound) And (Not IsBlankString(Str)) Then
		SerialNumbers.Add(Str);
	EndIf;
	
	// Check serial numbers contents.
	i = 0;
	While i < SerialNumbers.Count() Do
		If IsBlankString(SerialNumbers[i]) Then
			SerialNumbers.Delete(i);
		Else
			SerialNumbers[i] = TrimAll(SerialNumbers[i]);
			i = i + 1;
		EndIf;
	EndDo;
	
	// Delete duplicates.
	GeneralFunctions.NormalizeArray(SerialNumbers);
	
	// Return created array.
	Return SerialNumbers;
	
EndFunction

// Format serial numbers string from the passed array of serial numbers.
//  SerialNumbersArr - Array - Serial numbers array.
//
// Returns:
//  String - Formatted string representation of product serial numbers.
//
Function FormatSerialNumbersStr(Val SerialNumbersArr) Export
	
	// Check serial numbers contents.
	i = 0;
	While i < SerialNumbersArr.Count() Do
		If IsBlankString(SerialNumbersArr[i]) Then
			SerialNumbersArr.Delete(i);
		Else
			SerialNumbersArr[i] = TrimAll(SerialNumbersArr[i]);
			i = i + 1;
		EndIf;
	EndDo;
	
	// Delete duplicates.
	GeneralFunctions.NormalizeArray(SerialNumbersArr);
	
	// Create the string of serial numbers delimited by the commas.
	Return StringFunctionsClientServer.GetStringFromSubstringArray(SerialNumbersArr, ", ");
	
EndFunction

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region PRIVATE_IMPLEMENTATION

#EndRegion