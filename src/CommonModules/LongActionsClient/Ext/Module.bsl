
////////////////////////////////////////////////////////////////////////////////
// Base functionality subsystem.
//------------------------------------------------------------------------------
// Support of long server actions at the web client.
//

////////////////////////////////////////////////////////////////////////////////
#Region PUBLIC_INTERFACE

// Fills the parameter structure with default values.
//
// Parameters:
// IdleHandlerParameters - Structure - procedure fills this structure with default values.
//
Procedure InitIdleHandlerParameters(IdleHandlerParameters) Export
	
	// Fill structure with default parameters.
	IdleHandlerParameters = New Structure(
		"MinInterval,MaxInterval,CurrentInterval,IntervalMagnificationFactor", 1, 15, 1, 1.4);
	
EndProcedure

// Fills the parameter structure with new calculated values.
//
// Parameters:
// IdleHandlerParameters - Structure - procedure fills this structure with calculated values.
//
//
Procedure UpdateIdleHandlerParameters(IdleHandlerParameters) Export
	
	// Update structure calculating current values.
	IdleHandlerParameters.CurrentInterval = IdleHandlerParameters.CurrentInterval * IdleHandlerParameters.IntervalMagnificationFactor;
	If IdleHandlerParameters.CurrentInterval > IdleHandlerParameters.MaxInterval Then
		IdleHandlerParameters.CurrentInterval = IdleHandlerParameters.MaxInterval;
	EndIf;
	
EndProcedure

//------------------------------------------------------------------------------
// Procedures and functions for working with the long action splash form

// Opens the long operation splash form.
// 
// Parameters:
// FormOwner - ManagedForm - the form from which the long action form has opened. 
// JobID     - UUID - background job ID.
// Title     - Form title.
// Message   - Displayed message.
//
// Returns:
// ManagedForm - opened form reference.
//
Function OpenLongActionForm(Val FormOwner, Val JobID = Undefined, Title = "", Message = "") Export
	
	// Request long action splash form.
	LongActionForm = LongActionsClientReusable.GetLongActionForm();
	
	// Check whether form alrady open.
	If LongActionForm.IsOpen() Then
		
		// Open new form.
		LongActionForm = OpenForm(
			"CommonForm.LongAction",
			New Structure("JobID, Title, Message",
			               JobID, Title, Message),
			FormOwner);
	Else
		// Open cached form.
		LongActionForm.FormOwner = FormOwner;
		LongActionForm.JobID     = JobID;
		LongActionForm.Title     = Title;
		LongActionForm.Message   = Message;
		LongActionForm.Open();
	EndIf;
	
	// Return form reference.
	Return LongActionForm;
	
EndFunction

// Closes the long action splash form.
// 
// Parameters:
// LongActionForm - ManagedForm - long action progress bar form reference.
// 
Procedure CloseLongActionForm(LongActionForm) Export
	
	// Check whether passed ref is a splash form.
	If TypeOf(LongActionForm) = Type("ManagedForm") Then
		
		// Check whether form is still opened.
		If LongActionForm.IsOpen() Then
			LongActionForm.Close();
		EndIf;
	EndIf;
	
	// Clear form ref.
	LongActionForm = Undefined;
	
EndProcedure

#EndRegion
