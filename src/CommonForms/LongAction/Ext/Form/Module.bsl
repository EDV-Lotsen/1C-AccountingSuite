
////////////////////////////////////////////////////////////////////////////////
// Long actions: Splash form
//------------------------------------------------------------------------------
// Available on:
// - Client (managed application)
// - Server
//

////////////////////////////////////////////////////////////////////////////////
#Region FORM_EVENTS_HANDLERS

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Automatic close for application self-test.
	If Parameters.Property("SelfTest") Then
		Return;
	EndIf;
	
	// Fill ID of processing background job.
	If ValueIsFilled(Parameters.JobID) Then
		JobID = Parameters.JobID;
	Else
		Items.FormCancel.Visible = False;
	EndIf;
	
	// Set form title.
	If Not IsBlankString(Parameters.Title) Then
		Title = Parameters.Title;
	EndIf;
	
	// Set form message.
	If Not IsBlankString(Parameters.Message) Then
		Message = Parameters.Message;
	Else
		Message = NStr("en = 'The action is in progress. Please wait.'");
	EndIf;
	
EndProcedure

&AtClient
Procedure OnClose()
	
	// Close at server (does not defined by platfom).
	OnCloseAtServer();
	
EndProcedure

&AtServer
Procedure OnCloseAtServer()
	
	// Cancel execution of a background job.
	LongActions.CancelJobExecution(JobID);
	
EndProcedure

#EndRegion
