
////////////////////////////////////////////////////////////////////////////////
// Base functionality subsystem.
//------------------------------------------------------------------------------
// Support of long server actions at the web client.
//

////////////////////////////////////////////////////////////////////////////////
#Region PUBLIC_INTERFACE

// Request the form that indicates progress of a time-consuming action.
//
// Returns:
//  ManagedForm - opened common form.
//
Function GetLongActionForm() Export
	
	Return GetForm("CommonForm.LongAction");
	
EndFunction

#EndRegion
