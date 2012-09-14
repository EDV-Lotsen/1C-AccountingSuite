// Substitutes parameters into a string. Max possible number of parameters - 10.
// Parameters in the string are defined as %<parameter number>. Parameter numbering starts from one.
//
// Parameters:
// SubstituteString - String - string template with parameters (sections like "%ParameterName").
// Parameter<n> - String - parameter
//
// Returned value:
// String - text string with substituted parameters
//
// Example:
// String = SubstituteParametersIntoString(NStr("en='%1 submitted a %2'"), "John", "report");
//
Function SubstituteParametersIntoString(Val SubstituteString,
                                   Val Parameter1,
                                   Val Parameter2 = Undefined,
                                   Val Parameter3 = Undefined,
                                   Val Parameter4 = Undefined,
                                   Val Parameter5 = Undefined,
                                   Val Parameter6 = Undefined,
                                   Val Parameter7 = Undefined,
                                   Val Parameter8 = Undefined,
                                   Val Parameter9 = Undefined,
                                   Val Parameter10 = Undefined) Export
	
	ResultString = SubstituteString;
	
	ResultString = StrReplace(ResultString, "%1", Parameter1);
	
	If Parameter2 <> Undefined Then
		ResultString = StrReplace(ResultString, "%2", Parameter2);
	EndIf;
	
	If Parameter3 <> Undefined Then
		ResultString = StrReplace(ResultString, "%3", Parameter3);
	EndIf;
	
	If Parameter4 <> Undefined Then
		ResultString = StrReplace(ResultString, "%4", Parameter4);
	EndIf;
	
	If Parameter5 <> Undefined Then
		ResultString = StrReplace(ResultString, "%5", Parameter5);
	EndIf;
	
	If Parameter6 <> Undefined Then
		ResultString = StrReplace(ResultString, "%6", Parameter6);
	EndIf;
	
	If Parameter7 <> Undefined Then
		ResultString = StrReplace(ResultString, "%7", Parameter7);
	EndIf;
	
	If Parameter8 <> Undefined Then
		ResultString = StrReplace(ResultString, "%8", Parameter8);
	EndIf;
	
	If Parameter9 <> Undefined Then
		ResultString = StrReplace(ResultString, "%9", Parameter9);
	EndIf;
	
	If Parameter10 <> Undefined Then
		ResultString = StrReplace(ResultString, "%10", Parameter10);
	EndIf;
	
	Return ResultString;
	
EndFunction