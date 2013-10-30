
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
		Items.FormStartScheduledActions.Title = "Execute";
		
		// Get register record associated with document.
		RecordManager = InformationRegisters.RecurringDocuments.CreateRecordManager();
		RecordManager.RecurringDocument = RecurringDocument;
		RecordManager.Read();
		
		// It is unpossible to create new schedule templates to the same document.
		If RecordManager.Selected() Then
			Items.List.ChangeRowSet = False;
		EndIf;
		
	// Opened classic list.
	Else
		// The recurring document cannot be selected from the schedule list.
		Items.List.ChangeRowSet = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure ListNewWriteProcessing(NewObject, Source, StandardProcessing)
	
	// Process the creating of new schedule.
	ListNewWriteProcessingAtServer();
	
EndProcedure

&AtServer
Procedure ListNewWriteProcessingAtServer()
	
	// If linked record saved - close some list features.
	If (Not RecurringDocument = Undefined) And (Not RecurringDocument.IsEmpty()) Then
		
		// Get register record associated with document.
		RecordManager = InformationRegisters.RecurringDocuments.CreateRecordManager();
		RecordManager.RecurringDocument = RecurringDocument;
		RecordManager.Read();
		
		// It is unpossible to create new schedule templates to the same document.
		If RecordManager.Selected() Then
			Items.List.ChangeRowSet = False;
		EndIf;
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

