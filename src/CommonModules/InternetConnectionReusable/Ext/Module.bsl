
////////////////////////////////////////////////////////////////////////////////
// Internet connection: Client & Server with return of resable values
//------------------------------------------------------------------------------
// Available on:
// - Client (managed application))
// - Server
// - External Connection
//
// Reusable during:
// - User session
//

////////////////////////////////////////////////////////////////////////////////
#Region PUBLIC_INTERFACE

//------------------------------------------------------------------------------
// Settings returning functions (API variables)

// Returns structure with possible HTTP connection methods.
// Used as alternative to enums for client calls.
//
// Returns:
//  Structure - Collection of HTTPConnection methods and their representation.
//
Function GetHTTPConnectionMethods() Export
	
	Return New Structure("Get,   Put,   Post,   Delete",
	                     "Get", "Put", "Post", "Delete");
	
EndFunction

// Returns structure with possible FTP connection methods.
// Used as alternative to enums for client calls.
//
// Returns:
//  Structure - Collection of FTPConnection methods and their representation.
//
Function GetFTPConnectionMethods() Export
	
	Return New Structure("Get,   Put,   Delete,   Move,   GetCurrentDirectory,   SetCurrentDirectory,   CreateDirectory,   FindFiles",
	                     "Get", "Put", "Delete", "Move", "GetCurrentDirectory", "SetCurrentDirectory", "CreateDirectory", "FindFiles");
	
EndFunction

#EndRegion