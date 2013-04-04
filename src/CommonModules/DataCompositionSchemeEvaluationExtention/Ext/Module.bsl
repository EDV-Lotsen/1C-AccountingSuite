//////////////////////////////////////////////////////////////////////////////////
// Data composition scheme: Eevaluation extention: Global, Server
// Extends internal expressions language of data composition scheme
//------------------------------------------------------------------------------
// Global module. Available on:
// - Server
// - External Connection
//

////////////////////////////////////////////////////////////////////////////////
// FUNCTIONS FOR WORKING WITH STRING TYPE VALUES

// Function converts value to lower case
Function ToLower(Value) Export
	Return Lower(Value);
EndFunction

// Function converts value to upper case
Function ToUpper(Value) Export
	Return Upper(Value);
EndFunction
