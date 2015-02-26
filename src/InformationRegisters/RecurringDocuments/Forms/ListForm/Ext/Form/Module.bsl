
////////////////////////////////////////////////////////////////////////////////
// Recurring documents: List form
//------------------------------------------------------------------------------
// Available on:
// - Client (managed application)
// - Server
//

////////////////////////////////////////////////////////////////////////////////
#Region EVENTS_HANDLERS

//------------------------------------------------------------------------------
// Common form events processing

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// If opened from document - close some list features.
	If Parameters.Filter.Property("RecurringDocument", RecurringDocument) And (Not RecurringDocument.IsEmpty()) Then
		
		// Hide the document column and actions from the view.
		Items.RecurringDocument.Visible = False;
		
		// Lock test running of the scedule.
		//Items.FormStartScheduledActions.Title = "Test run";
		Items.FormStartScheduledActions.Visible = False;
		
	EndIf;
	
EndProcedure

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region CONTROLS_EVENTS_HANDLERS

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region TABULAR_SECTION_EVENTS_HANDLERS

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region COMMANDS_HANDLERS

&AtClient
Procedure StartScheduledActions(Command)
	
	// Manual start of actions scheduled for today.
	If StartScheduledActionsAtServer() Then
		ShowMessageBox(Undefined, NStr("en = 'Action(s) executed successfully.'"));
	Else
		ShowMessageBox(Undefined, NStr("en = 'Action(s) execution is failed.'"));
	EndIf;
	
EndProcedure

&AtServer
Function StartScheduledActionsAtServer()
	
	// Manual start of actions scheduled for today.
	If (Not RecurringDocument = Undefined) And (Not RecurringDocument.IsEmpty()) Then
		// Start action for a current document.
		Return InformationRegisters.RecurringDocuments.ProcessCurrentScheduledActions(CurrentDate(), RecurringDocument);
	Else
		// Start all scheduled actions.
		Return InformationRegisters.RecurringDocuments.ProcessCurrentScheduledActions(CurrentDate());
	EndIf;
	
EndFunction

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region PRIVATE_IMPLEMENTATION

#EndRegion

