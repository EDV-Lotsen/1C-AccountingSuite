
////////////////////////////////////////////////////////////////////////////////
// Recurring documents: Record form
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
	
	// Automatic close for application self-test.
	If Parameters.Property("SelfTest") Then
		Return;
	EndIf;
	
	// Read base date from the parameters (if it available).
	Parameters.Property("FromDate", FromDate);
	
	// Read schedule parameters.
	ScheduleParameters = InformationRegisters.RecurringDocuments.GetSchedule(Record.RecurringDocument, Record.LineID);
	
	// Load schedule parameters to the form attributes.
	FillPropertyValues(ThisForm, ScheduleParameters);
	
	// Assign the default month interval (for newly created records).
	If Record.LineID = 0 Then Interval = 3 EndIf;
	
	// Update pages settings.
	Items.SelectActionPages.CurrentPage = Items.SelectActionPages.ChildItems[Action-1];
	Items.SelectIntervalPages.CurrentPage = Items.SelectIntervalPages.ChildItems[Interval-1];
	
	// Update form presentation depending on the schedule options.
	ActionOnChangeAtServer();
	IntervalOnChangeAtServer();
	MonthTypeOnChangeAtServer();
	StopTypeOnChangeAtServer();
	
	// Update form elements presentation.
	Items.FormExecute.Enabled = Not Modified;
	Items.RecurringDocument.Visible = Not ValueIsFilled(Record.RecurringDocument);
	
EndProcedure

&AtClient
Procedure OnClose()
	
	// Process server operations.
	OnCloseAtServer();
	
EndProcedure

&AtServer
Procedure OnCloseAtServer()
	
	// Define date constants.
	EmptyDate   = '00010101';
	CurrentDate = BegOfDay(CurrentDate());
	
	// If document should to be created - do process scheduled actions.
	If    FormUpdated = True       // The data in the schedule are changed before close.
	And  (Record.EventDate         > EmptyDate And Record.EventDate         <= CurrentDate)
	And  (Record.ScheduledDate     > EmptyDate And Record.ScheduledDate     >= CurrentDate)
	And ((Record.CompletedUpTo     > EmptyDate And Record.CompletedUpTo     <  CurrentDate) Or (Record.CompletedUpTo     = EmptyDate))
	And ((Record.LastExecutionDate > EmptyDate And Record.LastExecutionDate <  CurrentDate) Or (Record.LastExecutionDate = EmptyDate))
	Then  InformationRegisters.RecurringDocuments.ProcessCurrentScheduledActions(CurrentDate(), Record.RecurringDocument);
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	// Check recurring document filling.
	If Not ValueIsFilled(Record.RecurringDocument) Then
		Cancel = True;
		ShowMessageBox(Undefined, NStr("en = 'The schedule can not be saved without the recurring document specified.
		                                     |Select the recurring document.'"),, NStr("en = 'Error writing the recurring template'"));
		Return;
	EndIf;
	
	// Check days in advance / remind before
	
	// Interval & range parameters.
	If Action = 1 or Action = 2 Then          // Generate & remind
		
		// Interval parameters.
		If Interval                  = 1 Then // Daily.
			MaxAdvance = Days;
			
		ElsIf Interval               = 2 Then // Weekly.
			MaxAdvance = 7 * Weeks;
			
		ElsIf Interval               = 3 Then // Monthly.
			MaxAdvance = 28 * Months;
			
		ElsIf Interval               = 4 Then // Yearly.
			MaxAdvance = 365;
		EndIf;
	EndIf;
	
	// Action parameters.
	If Action                        = 1 Then // Generate.
		// Can not generate the document in advance before previous scheduled date.
		If DaysAdvance >= MaxAdvance Then
			// Roll back the writing transaction and show the notification.
			Cancel = True;
			ShowMessageBox(Undefined, NStr("en = 'The number of days in advance to create a document must be lower than the schedule interval.
			                                     |Reduce the number of days in advance.'"),, NStr("en = 'Error writing the recurring template'"));
		EndIf;
		
	ElsIf Action                     = 2 Then // Remind.
		// Can not remind before the previous scheduled date.
		If RemindBefore >= MaxAdvance Then
			// Roll back the writing transaction and show the notification.
			Cancel = True;
			ShowMessageBox(Undefined, NStr("en = 'The reminder period must be lower than the schedule interval.
			                                     |Reduce the number of days to remind.'"),, NStr("en = 'Error writing the recurring template'"));
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// Push schedule parameters from the form attributes to the value storage.
	CurrentObject.Schedule = InformationRegisters.RecurringDocuments.PutToSchedule(ThisForm);
	
	// Assign the new record ID (for newly created records).
	If CurrentObject.LineID = 0 Then CurrentObject.LineID = InformationRegisters.RecurringDocuments.GetNewNumber(CurrentObject.RecurringDocument) EndIf;
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	// Update form elements presentation.
	Items.FormExecute.Enabled = Not Modified;
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	// Set data updated flag for run of updated schedule on closing.
	FormUpdated = True;
	
EndProcedure

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region CONTROLS_EVENTS_HANDLERS

//------------------------------------------------------------------------------
// Form items events processing

&AtClient
Procedure RecurringDocumentOnChange(Item)
	
	// Update recurring document presentation.
	RecurringDocumentOnChangeAtServer();
	
EndProcedure

&AtClient
Procedure SelectActionPagesOnCurrentPageChange(Item, CurrentPage)
	
	// Change current action.
	Action = Items.SelectActionPages.ChildItems.IndexOf(Items.SelectActionPages.CurrentPage) + 1;
	
	// Update action presentation.
	ActionOnChangeAtServer();
	
EndProcedure

&AtClient
Procedure SelectIntervalPagesOnCurrentPageChange(Item, CurrentPage)
	
	// Change current interval.
	Interval = Items.SelectIntervalPages.ChildItems.IndexOf(Items.SelectIntervalPages.CurrentPage) + 1;
	
	// Update interval presentation.
	IntervalOnChangeAtServer();
	
EndProcedure

&AtClient
Procedure GenerateModeOnChange(Item)
	
	// Update generate mode presentation.
	GenerateModeOnChangeAtServer();
	
EndProcedure

&AtClient
Procedure DaysAdvanceOnChange(Item)
	
	// Update advance days presentation.
	DaysAdvanceOnChangeAtServer();
	
EndProcedure

&AtClient
Procedure RemindBeforeOnChange(Item)
	
	// Update remind before presentation.
	RemindBeforeOnChangeAtServer();
	
EndProcedure

&AtClient
Procedure DaysOnChange(Item)
	
	// Update days presentation.
	DaysOnChangeAtServer();
	
EndProcedure

&AtClient
Procedure WeeksOnChange(Item)
	
	// Update days presentation.
	WeeksOnChangeAtServer();
	
EndProcedure

&AtClient
Procedure WeeksDayOnChange(Item)
	
	// Update week day presentation.
	WeeksDayOnChangeAtServer();
	
EndProcedure

&AtClient
Procedure MonthTypeOnChange(Item)
	
	// Proceed focus change.
	MonthTypeOnChangeAtServer();
	
EndProcedure

&AtClient
Procedure MonthsOnChange(Item)
	
	// Update month presentation.
	MonthsOnChangeAtServer();
	
EndProcedure

&AtClient
Procedure MonthsDayOnChange(Item)
	
	// Update month day presentation.
	MonthsDayOnChangeAtServer();
	
EndProcedure

&AtClient
Procedure MonthsWeekOnChange(Item)
	
	// Update month week presentation.
	MonthsWeekOnChangeAtServer();
	
EndProcedure

&AtClient
Procedure MonthsWeekDayOnChange(Item)
	
	// Update month week day presentation.
	MonthsWeekDayOnChangeAtServer();
	
EndProcedure

&AtClient
Procedure YearsMonthOnChange(Item)
	
	// Update year month presentation.
	YearsMonthOnChangeAtServer();
	
EndProcedure

&AtClient
Procedure YearsMonthDayOnChange(Item)
	
	// Update year month day presentation.
	YearsMonthDayOnChangeAtServer();
	
EndProcedure

&AtClient
Procedure StartDateOnChange(Item)
	
	// Update start date presentation.
	StartDateOnChangeAtServer();
	
EndProcedure

&AtClient
Procedure StopTypeOnChange(Item)
	
	// Proceed focus change.
	StopTypeOnChangeAtServer();
	
EndProcedure

&AtClient
Procedure StopDateOnChange(Item)
	
	// Update stop date presentation.
	StopDateOnChangeAtServer();
	
EndProcedure

&AtClient
Procedure StopAfterOnChange(Item)
	
	// Update stop after number of occurrencies presentation.
	StopAfterOnChangeAtServer();
	
EndProcedure

//------------------------------------------------------------------------------
// Object fields presentation processing

&AtServer
Procedure RecurringDocumentOnChangeAtServer()
	
	// Update schedule presentation.
	SchedulePresentationUpdate();
	
	// Update scheduled date.
	ScheduledDateUpdate();
	
EndProcedure

&AtServer
Procedure ActionOnChangeAtServer()
	
	// Set available schedule options.
	ShowOptions = (Action = 1 Or Action = 2);   // Generate or remind
	Items.SelectInterval.Enabled = ShowOptions;
	Items.SelectRange.Enabled    = ShowOptions;
	
	// Update schedule presentation.
	SchedulePresentationUpdate();
	
	// Update scheduled date.
	ScheduledDateUpdate();
	
EndProcedure

&AtServer
Procedure IntervalOnChangeAtServer()
	
	// Update schedule presentation.
	SchedulePresentationUpdate();
	
	// Update scheduled date.
	ScheduledDateUpdate();
	
EndProcedure

&AtServer
Procedure GenerateModeOnChangeAtServer()
	
	// Update schedule presentation.
	SchedulePresentationUpdate();
	
	// Update scheduled date.
	ScheduledDateUpdate();
	
EndProcedure

&AtServer
Procedure DaysAdvanceOnChangeAtServer()
	
	// Update schedule presentation.
	SchedulePresentationUpdate();
	
	// Update scheduled date.
	ScheduledDateUpdate();
	
EndProcedure

&AtServer
Procedure RemindBeforeOnChangeAtServer()
	
	// Update schedule presentation.
	SchedulePresentationUpdate();
	
	// Update scheduled date.
	ScheduledDateUpdate();
	
EndProcedure

&AtServer
Procedure DaysOnChangeAtServer()
	
	// Update schedule presentation.
	SchedulePresentationUpdate();
	
	// Update scheduled date.
	ScheduledDateUpdate();
	
EndProcedure

&AtServer
Procedure WeeksOnChangeAtServer()
	
	// Update schedule presentation.
	SchedulePresentationUpdate();
	
	// Update scheduled date.
	ScheduledDateUpdate();
	
EndProcedure

&AtServer
Procedure WeeksDayOnChangeAtServer()
	
	// Update schedule presentation.
	SchedulePresentationUpdate();
	
	// Update scheduled date.
	ScheduledDateUpdate();
	
EndProcedure

&AtServer
Procedure MonthTypeOnChangeAtServer()
	
	// Update controls presentation basing on month type.
	If    MonthType = 1 Then // Monthly option 1.
		// Set enabled feature to the 1-st option.
		Items.MonthsDayGroup1.Enabled = True;
		Items.MonthsDayGroup2.Enabled = False;
		
	ElsIf MonthType = 2 Then // Monthly option 2.
		// Set enabled feature to the 2-nd option.
		Items.MonthsDayGroup1.Enabled = False;
		Items.MonthsDayGroup2.Enabled = True;
	EndIf;
	
	// Update schedule presentation.
	SchedulePresentationUpdate();
	
	// Update scheduled date.
	ScheduledDateUpdate();
	
EndProcedure

&AtServer
Procedure MonthsOnChangeAtServer()
	
	// Update schedule presentation.
	SchedulePresentationUpdate();
	
	// Update scheduled date.
	ScheduledDateUpdate();
	
EndProcedure

&AtServer
Procedure MonthsDayOnChangeAtServer()
	
	// Update schedule presentation.
	SchedulePresentationUpdate();
	
	// Update scheduled date.
	ScheduledDateUpdate();
	
EndProcedure

&AtServer
Procedure MonthsWeekOnChangeAtServer()
	
	// Update schedule presentation.
	SchedulePresentationUpdate();
	
	// Update scheduled date.
	ScheduledDateUpdate();
	
EndProcedure

&AtServer
Procedure MonthsWeekDayOnChangeAtServer()
	
	// Update schedule presentation.
	SchedulePresentationUpdate();
	
	// Update scheduled date.
	ScheduledDateUpdate();
	
EndProcedure

&AtServer
Procedure YearsMonthOnChangeAtServer()
	
	// Update schedule presentation.
	SchedulePresentationUpdate();
	
	// Update scheduled date.
	ScheduledDateUpdate();
	
EndProcedure

&AtServer
Procedure YearsMonthDayOnChangeAtServer()
	
	// Update schedule presentation.
	SchedulePresentationUpdate();
	
	// Update scheduled date.
	ScheduledDateUpdate();
	
EndProcedure

&AtServer
Procedure StartDateOnChangeAtServer()
	
	// Update schedule presentation.
	SchedulePresentationUpdate();
	
	// Update scheduled date.
	ScheduledDateUpdate();
	
EndProcedure

&AtServer
Procedure StopTypeOnChangeAtServer()
	
	// Update controls presentation basing on schedule stop type.
	If    StopType = 1 Then // Stop option 1.
		// Set enabled feature to the 1-st option.
		Items.StopDate.Enabled = True;
		Items.StopAfterGroup.Enabled = False;
		Items.StopProceedContinuously.Enabled = False;
		
	ElsIf StopType = 2 Then // Stop option 2.
		// Set enabled feature to the 2-nd option.
		Items.StopDate.Enabled = False;
		Items.StopAfterGroup.Enabled = True;
		Items.StopProceedContinuously.Enabled = False;
		
	ElsIf StopType = 3 Then // Stop option 3.
		// Set enabled feature to the 3-rd option.
		Items.StopDate.Enabled = False;
		Items.StopAfterGroup.Enabled = False;
		Items.StopProceedContinuously.Enabled = True;
	EndIf;
	
	// Update schedule presentation.
	SchedulePresentationUpdate();
	
	// Update scheduled date.
	ScheduledDateUpdate();
	
EndProcedure

&AtServer
Procedure StopDateOnChangeAtServer()
	
	// Update schedule presentation.
	SchedulePresentationUpdate();
	
	// Update scheduled date.
	ScheduledDateUpdate();
	
EndProcedure

&AtServer
Procedure StopAfterOnChangeAtServer()
	
	// Update schedule presentation.
	SchedulePresentationUpdate();
	
	// Update scheduled date.
	ScheduledDateUpdate();
	
EndProcedure

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region TABULAR_SECTION_EVENTS_HANDLERS

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region COMMANDS_HANDLERS

&AtClient
Procedure ExecuteAction(Command)
	
	// Execute current action.
	If ExecuteActionAtServer() Then
		ShowMessageBox(Undefined, NStr("en = 'The action executed successfully.'"));
	Else
		ShowMessageBox(Undefined, NStr("en = 'The action execution is failed.'"));
	EndIf;
	
EndProcedure

&AtServer
Function ExecuteActionAtServer()
	
	// Execute current action for the specified recurring document.
	Return InformationRegisters.RecurringDocuments.ProcessCurrentScheduledActions(
		CurrentDate(), Record.RecurringDocument);
	
EndFunction

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region PRIVATE_IMPLEMENTATION

&AtServer
Procedure SchedulePresentationUpdate()
	
	// Update schedule presentation basing on the schedule options.
	SchedulePresentation = "{ActionPresentation}{IntervalPresentation}{RangePresentation}.";
	
	// Update recurring document presentation.
	RecurringDocument = ?(ValueIsFilled(Record.RecurringDocument), Record.RecurringDocument, "...");
	
	// Action parameters.
	If Action                        = 1 Then // Generate.
		
		// Select generation mode.
		If GenerateMode              = 1 Then // Create draft documents.
			ActionPresentation = NStr("en = 'Generate a draft copy of %1%2'");
		ElsIf GenerateMode           = 2 Then // Create posted documents.
			ActionPresentation = NStr("en = 'Generate and post a copy of %1%2'");
		EndIf;
		
		// Create in advance.
		If DaysAdvance               = 0 Then // Create on schediule.
			AdvanceStr = "";
		Else                                  // Create in advance.
			AdvanceStr = StringFunctionsClientServer.SubstituteParametersInString(
			             NStr("en = ' %1 day(s) in advance'"), Format(DaysAdvance, ""));
		EndIf;
		
		// Format action string.
		ActionPresentation = StringFunctionsClientServer.SubstituteParametersInString(
		                     ActionPresentation, RecurringDocument, AdvanceStr);
		
	ElsIf Action                     = 2 Then // Remind.
		
		// Format action string.
		ActionPresentation = NStr("en = 'Remind me to copy %1%2'");
		
		// Remind before.
		If RemindBefore              = 0 Then // Remind on schediule.
			BeforeStr = "";
		Else                                  // Remind before.
			BeforeStr = StringFunctionsClientServer.SubstituteParametersInString(
			            NStr("en = ' %1 day(s) before the transaction date'"), Format(RemindBefore, ""));
		EndIf;
		
		// Format action string.
		ActionPresentation = StringFunctionsClientServer.SubstituteParametersInString(
		                     ActionPresentation, RecurringDocument, BeforeStr);
		
	ElsIf Action                     = 3 Then // Save.
		
		// Format action string.
		ActionPresentation = StringFunctionsClientServer.SubstituteParametersInString(
		                     NStr("en = 'Save %1 as a template'"), RecurringDocument);
	EndIf;
	
	// Interval & range parameters.
	If Action = 1 or Action = 2 Then          // Generate & remind
		
		// Interval parameters.
		If Interval                  = 1 Then // Daily.
			
			// Format interval string.
			IntervalPresentation = StringFunctionsClientServer.SubstituteParametersInString(
			                       NStr("en = ' every %1 day(s)'"), Format(Days, ""));
			
		ElsIf Interval               = 2 Then // Weekly.
			
			// Format interval string.
			WeeksDayPresentation = Items.WeeksDay.ChoiceList.FindByValue(WeeksDay).Presentation;
			IntervalPresentation = StringFunctionsClientServer.SubstituteParametersInString(
			                       NStr("en = ' every %1 week(s) on %2s'"), Format(Weeks, ""), WeeksDayPresentation);
			
		ElsIf Interval               = 3 Then // Monthly.
			
			// Select month schedule type.
			If MonthType             = 1 Then // By the day of month.
				
				// Format interval string.
				MonthsDayPresentation = Lower(Items.MonthsDay.ChoiceList.FindByValue(MonthsDay).Presentation);
				IntervalPresentation  = StringFunctionsClientServer.SubstituteParametersInString(
				                        NStr("en = ' on the %1 day of every %2 month(s)'"), MonthsDayPresentation, Format(Months, ""));
				
			ElsIf MonthType          = 2 Then // By the week day in month.
				
				// Format interval string.
				MonthsWeekPresentation    = Lower(Items.MonthsWeek.ChoiceList.FindByValue(MonthsWeek).Presentation);
				MonthsWeekDayPresentation = Items.MonthsWeekDay.ChoiceList.FindByValue(MonthsWeekDay).Presentation;
				IntervalPresentation      = StringFunctionsClientServer.SubstituteParametersInString(
				                            NStr("en = ' on the %1 %2 of every %3 month(s)'"), MonthsWeekPresentation, MonthsWeekDayPresentation, Format(Months, ""));
			EndIf;
			
		ElsIf Interval               = 4 Then // Yearly.
			
			// Format interval string.
			YearsMonthPresentation    = Items.YearsMonth.ChoiceList.FindByValue(YearsMonth).Presentation;
			YearsMonthDayPresentation = Lower(Items.YearsMonthDay.ChoiceList.FindByValue(YearsMonthDay).Presentation);
			IntervalPresentation      = StringFunctionsClientServer.SubstituteParametersInString(
			                            NStr("en = ' yearly on the %1 day of %2'"), YearsMonthDayPresentation, YearsMonthPresentation);
		EndIf;
		
		// Range parameters.
		// Start options.
		If StartDate > '00010101000000' Then // Start date specified.
			
			// Format starting string.
			StartPresentation = StringFunctionsClientServer.SubstituteParametersInString(
			                    NStr("en = ' starting on or after %1'"), Format(StartDate, "DLF=D"));
		Else
			// Start limitation is not used.
			StartPresentation = "";
		EndIf;
			
		// Stop options.
		If StopType                  = 1 Then // Stop after the date.
			// Define stop date.
			If StopDate > '00010101000000' Then // Stop date specified.
				
				// Format stoping string.
				StopPresentation = StringFunctionsClientServer.SubstituteParametersInString(
				                   NStr("en = '%1 stopping after %2'"),
				                   ?(Not IsBlankString(StartPresentation), " and", ""),
				                   Format(StopDate, "DLF=D"));
			Else
				// Stop limitation is not used.
				StopPresentation = "";
			EndIf;
			
		ElsIf StopType               = 2 Then // Stop after number of occurrencies.
			// Define occurrencies number.
			If StopAfter > 0 Then
				// Format stoping string.
				StopPresentation = StringFunctionsClientServer.SubstituteParametersInString(
				                   NStr("en = '%1 stopping after %2 occurrence(s)'"),
				                   ?(Not IsBlankString(StartPresentation), " and", ""),
				                   Format(StopAfter, ""));
			Else
				// Stop limitation is not used.
				StopPresentation = "";
			EndIf;
			
		ElsIf StopType               = 3 Then // Do not stop, proceed continuously.
			// Stop limitation is not used.
			StopPresentation = "";
		EndIf;
		
		// Format range string.
		RangePresentation = StringFunctionsClientServer.SubstituteParametersInString(
		                    NStr("en = '%1%2'"), StartPresentation, StopPresentation);
	Else
		// Interval & range are not used.
		IntervalPresentation = "";
		RangePresentation    = "";
	EndIf;
	
	// Format schedule string.
	SchedulePresentation = StringFunctionsClientServer.SubstituteParametersInStringByName(
	                       SchedulePresentation,
	                       New Structure("ActionPresentation, IntervalPresentation, RangePresentation",
	                                      ActionPresentation, IntervalPresentation, RangePresentation));
	
	// Compare with saved value.
	If Record.SchedulePresentation <> SchedulePresentation Then
		// Update record data.
		Record.SchedulePresentation = SchedulePresentation;
		// Set record modification flag.
		Modified = True;
		// Update form elements presentation.
		Items.FormExecute.Enabled = Not Modified;
	EndIf;
	
EndProcedure

&AtServer
Procedure ScheduledDateUpdate()
	
	// Copy the record data to the local variables (preventing occasional changing).
	EmptyDate         = '00010101';
	CurrentDate       = BegOfDay(CurrentDate());
	EventDate         = Record.EventDate;
	LastExecutionDate = Record.LastExecutionDate;
	CompletedUpTo     = Record.CompletedUpTo;
	OccurrencesCount  = Record.OccurrencesCount;
	
	// Update user visible schedule presentation with latest occurance.
	If LastExecutionDate > EmptyDate Then
		SchedulePresentation = SchedulePresentation + Chars.LF +
		                       StringFunctionsClientServer.SubstituteParametersInString(
		                       NStr("en = 'The action was executed %1 time(s). Latest occurrence on: %2.'"), OccurrencesCount, Format(LastExecutionDate, "DLF=D"));
	EndIf;
	
	// Update the start date for schedule.
	If ValueIsFilled(Record.RecurringDocument) And CompletedUpTo > EmptyDate Then
		CompletedUpTo = ?(BegOfDay(Record.RecurringDocument.Date) > CompletedUpTo, BegOfDay(Record.RecurringDocument.Date), CompletedUpTo);
	Else
		CompletedUpTo = ?(ValueIsFilled(Record.RecurringDocument), BegOfDay(Record.RecurringDocument.Date), CompletedUpTo);
	EndIf;
	
	// Generate the schedule date and the nearest event date.
	ScheduledDate = InformationRegisters.RecurringDocuments.CalculateScheduledDate(FromDate, ThisForm, LastExecutionDate, CompletedUpTo, OccurrencesCount, EventDate);
	
	// Update user visible schedule presentation with nearest date information.
	If ScheduledDate > EmptyDate Then
		SchedulePresentation = SchedulePresentation + Chars.LF +
		                       StringFunctionsClientServer.SubstituteParametersInString(
		                       NStr("en = 'Nearest scheduled date: %1.'"), Format(ScheduledDate, "DLF=D"));
		If EventDate > EmptyDate And EventDate < ScheduledDate Then
			SchedulePresentation = SchedulePresentation + 
			                       StringFunctionsClientServer.SubstituteParametersInString(
			                       NStr("en = ' The action will occur on: %1.'"), Format(?(EventDate > CurrentDate, EventDate, CurrentDate), "DLF=D"));
		EndIf;
	EndIf;
	
	// Compare with saved value.
	If Record.ScheduledDate <> ScheduledDate Or Record.EventDate <> EventDate Then
		// Update record data.
		Record.ScheduledDate = ScheduledDate;
		Record.EventDate = EventDate;
		// Set record modification flag.
		Modified = True;
		// Update form elements presentation.
		Items.FormExecute.Enabled = Not Modified;
	EndIf;
	
EndProcedure

#EndRegion
