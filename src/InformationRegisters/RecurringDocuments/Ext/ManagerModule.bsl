
////////////////////////////////////////////////////////////////////////////////
// Recurring documents: Manager module
//------------------------------------------------------------------------------
// Available on:
// - Server
//

////////////////////////////////////////////////////////////////////////////////
#Region PUBLIC_INTERFACE

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

//------------------------------------------------------------------------------
// Schedule conversation functions

// Read schedule parameters for passed document.
//
// Parameters:
//  DocumentRef - DefinedType.RecurringDocuments.Ref - Reference for reading from the database.
//  RecordID    - UUID                               - ID of selected document schedule.
//
// Returns:
//  Structure - Schedule parameters unpacked from the value storage.
//
Function GetSchedule(DocumentRef, RecordID) Export
	
	// Get settings in priveleged mode.
	SetPrivilegedMode(True);
	
	// Define the schedule parameters structure.
	ScheduleParameters = New Structure("Action, Days, DaysAdvance, GenerateMode, Interval,
	                                   |Months, MonthsDay, MonthsWeek, MonthsWeekDay, MonthType,
	                                   |RemindBefore, StartDate, StopAfter, StopDate, StopType,
	                                   |Weeks, WeeksDay, YearsMonth, YearsMonthDay");
	
	// Get register record associated with document.
	RecordManager = InformationRegisters.RecurringDocuments.CreateRecordManager();
	RecordManager.RecurringDocument = DocumentRef;
	RecordManager.LineID            = RecordID;
	RecordManager.Read();
	
	// Load saved schedule from value storage.
	If RecordManager.Selected() Then
		// Get contents of value storage.
		ScheduleData = RecordManager.Schedule.Get();
		If TypeOf(ScheduleData) = Type("Structure") Then
			// Fill data read from the database.
			FillPropertyValues(ScheduleParameters, ScheduleData);
		Else
			// Fill schedule with default data.
			FillPropertyValues(ScheduleParameters, GetDefaultSchedule());
		EndIf;
	Else
		// Fill schedule with default data.
		FillPropertyValues(ScheduleParameters, GetDefaultSchedule());
	EndIf;
	
	// Return the structure of schedule parameters.
	Return ScheduleParameters;
	
EndFunction

// Fills schedule structure with default values.
//
// Returns:
//  Structure - Schedule parameters filled with default values.
//
Function GetDefaultSchedule() Export
	
	// Define the schedule structure.
	ScheduleParameters = New Structure("Action, Days, DaysAdvance, GenerateMode, Interval,
	                                   |Months, MonthsDay, MonthsWeek, MonthsWeekDay, MonthType,
	                                   |RemindBefore, StartDate, StopAfter, StopDate, StopType,
	                                   |Weeks, WeeksDay, YearsMonth, YearsMonthDay");
	
	// Action parameters.
	ScheduleParameters.Action        = 1; // Generate.
	// Action: Generate.
	ScheduleParameters.GenerateMode  = 1; // Create draft documents.
	ScheduleParameters.DaysAdvance   = 0; // Create documents direct when event occurs.
	// Action: Remind.
	ScheduleParameters.RemindBefore  = 0; // Remind at the date when event should occur.
	
	// Interval parameters.
	ScheduleParameters.Interval      = 1; // Daily.
	// Interval: Daily.
	ScheduleParameters.Days          = 1; // Every day.
	// Interval: Weekly.
	ScheduleParameters.Weeks         = 1; // Every week.
	ScheduleParameters.WeeksDay      = 1; // on Monday.
	// Interval: Monthly.
	ScheduleParameters.MonthType     = 1; // Monthly option 1.
	// Interval: Monthly option 1.
	ScheduleParameters.MonthsDay     = 1; // 1st
	ScheduleParameters.Months        = 1; // of every Month
	// Interval: Monthly option 2.
	ScheduleParameters.MonthsWeek    = 1; // 1st
	ScheduleParameters.MonthsWeekDay = 1; // Monday
	ScheduleParameters.Months        = 1; // of every Month
	// Interval: Yearly.
	ScheduleParameters.YearsMonth    = 1; // Januar
	ScheduleParameters.YearsMonthDay = 1; // 1st
	
	// Range parameters.
	ScheduleParameters.StartDate     = '00010101'; // From the current date.
	ScheduleParameters.StopType      = 1;          // Stop after the date.
	ScheduleParameters.StopDate      = '00010101'; // Proceed continuously.
	ScheduleParameters.StopAfter     = 1;          // Proceed only once.
	
	// Return filled schedule parameters.
	Return ScheduleParameters;
	
EndFunction

// Converts structure to the schedule ValueStorage.
//
// Parameters:
//  ScheduleParameters - Structure - Schedule parameters to be packed to the value storage.
//
// Returns:
//  ValueStorage - Scedule contents for saving it in the database.
//
Function PutToSchedule(ScheduleParameters) Export
	
	// Define the saving structure.
	SavingParameters = New Structure("Action, Days, DaysAdvance, GenerateMode, Interval,
	                                 |Months, MonthsDay, MonthsWeek, MonthsWeekDay, MonthType,
	                                 |RemindBefore, StartDate, StopAfter, StopDate, StopType,
	                                 |Weeks, WeeksDay, YearsMonth, YearsMonthDay");
	FillPropertyValues(SavingParameters, ScheduleParameters);
	
	// Return a value storage for saving in the database.
	Return New ValueStorage(SavingParameters);
	
EndFunction

//------------------------------------------------------------------------------
// Schedule identification functions

// Generate a sequential record number for the passed document.
//
// Parameters:
//  DocumentRef - DefinedType.RecurringDocuments.Ref - Reference for generation of new sequential number.
//
// Returns:
//  Number - New sequential number.
//
Function GetNewNumber(DocumentRef) Export
	
	// Prepare a query text for requesting last existing LineID.
	QueryText =
	"SELECT TOP 1
	|	RecurringDocuments.LineID
	|FROM
	|	InformationRegister.RecurringDocuments AS RecurringDocuments
	|WHERE
	|	RecurringDocuments.RecurringDocument = &Ref
	|ORDER BY
	|	RecurringDocuments.LineID Desc";
	
	// Create a new query.
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Ref", DocumentRef);
	QueryResult = Query.Execute();
	
	// Calculate sequential number.
	If QueryResult.IsEmpty() Then
		Return 1; // The first line.
	Else
		Return QueryResult.Unload()[0].LineID + 1; // Next number.
	EndIf;
	
	
EndFunction

//------------------------------------------------------------------------------
// Schedule operations functions

// Calculates next sceduled date for the passed schedule.
//
// Parameters:
//  FromDate          - Date      - Date, the schedule date calculated for, usually the current date.
//  FromSchedule      - Structure - Schedule parameters, as defined in GetDefaultSchedule() function
//  LastExecutionDate - Date      - Date of the last execution of the scheduled action.
//  CompletedUpTo     - Date      - The date till which the task fully completed (the closing date).
//  OccurrencesCount  - Number    - Positive count of event occurrences.
//  EventDate         - Date      - (Returned) Date when event occurrs before the action date comes.
//
// Returns:
//  Date      - Next scheduled date for the passed FromDate.
//
Function CalculateScheduledDate(FromDate, FromSchedule, LastExecutionDate, CompletedUpTo, OccurrencesCount, EventDate = '00010101') Export
	
	// Get default schedule (structure compatibility protection)
	Schedule = GetDefaultSchedule();
	FillPropertyValues(Schedule, FromSchedule);
	
	// Time constants.
	DayTime  = 24 * 60 * 60;
	WeekTime = 7 * DayTime;
	
	// Get current server date (to prevent schedule from being executed twice or more by different users).
	CurrentDate      = BegOfDay(CurrentDate());
	CurrentEventDate = CurrentDate - ?(Schedule.Action = 1, Schedule.DaysAdvance,
	                                 ?(Schedule.Action = 2, Schedule.RemindBefore,
	                                 0)) * DayTime;
	EmptyDate        = '00010101';
	ScheduledDate    = EmptyDate;
	EventDate        = EmptyDate;
	
	// Process trigger actions.
	If Schedule.Action = 1                 // Action: Generate.
	Or Schedule.Action = 2 Then            // Action: Remind.
		
		// 1. Define actual start and stop dates.
		
		// 1.1. Define starting date.
		If    FromDate = EmptyDate And Schedule.StartDate = EmptyDate And CompletedUpTo = EmptyDate Then
			// Start schedule from the current moment.
			StartDate = CurrentDate;
			
		ElsIf CompletedUpTo >= FromDate And CompletedUpTo >= Schedule.StartDate Then
			// Completion is the last possible date.
			StartDate = CompletedUpTo;
			
		ElsIf FromDate >= CompletedUpTo And FromDate >= Schedule.StartDate Then
			// Use passed moment.
			StartDate = BegOfDay(FromDate);
			
		Else
			// Use scedule date.
			StartDate = Schedule.StartDate;
		EndIf;
		
		// 1.2. Define stopping date.
		If Schedule.StopType = 1 Then      // Stop after date.
			// Check stopping date.
			If Schedule.StopDate = EmptyDate Then // Non-stop.
				// Don't assign stop limitation.
				StopDate = EmptyDate;      // Don't limit the stop date.
				
			ElsIf Schedule.StopDate >= StartDate Then // Stop date defined.
				// Assign stop date.
				StopDate = Schedule.StopDate;
				
			Else // StopDate < StartDate
				Return EmptyDate;
			EndIf;
			
		ElsIf Schedule.StopType = 2 Then   // Stop after number of tries.
			// Check number of tries.
			If OccurrencesCount < Schedule.StopAfter Then
				// OK, proceed to define next scheduled date.
				StopDate = EmptyDate;      // Don't limit the stop date.
				
			Else // OccurrencesCount >= StopAfter
				 // All tries are used.
				Return EmptyDate;
			EndIf;
			
		ElsIf Schedule.StopType = 3 Then   // Proceed continuosly.
			// Don't assign stop limitation.
			StopDate = EmptyDate;          // Don't limit the stop date.
			
		Else
			// Don't assign stop limitation.
			StopDate = EmptyDate;          // Don't limit the stop date.
		EndIf;
		
		// 2. Define next possible chronological date according to interval settings.
		
		// 2.1. Daily.
		If Schedule.Interval = 1 Then
			
			// Check starting day.
			If StartDate <= CurrentDate Then // Start date is in the past or present.
				
				// Calculate expected occurencies count.
				Occurencies = (CurrentDate - StartDate) / DayTime / Schedule.Days;
				If Occurencies > Int(Occurencies) Then
					
					// Scheduled for the day in the future.
					ScheduledDate = StartDate + (Int(Occurencies) + 1) * Schedule.Days * DayTime;
				Else
					// The event is scheduled for today.
					ScheduledDate = CurrentDate;
				EndIf;
				
			Else // Start date is in the future.
				
				// The first ocurrence is a start date.
				ScheduledDate = StartDate;
			EndIf;
			
			// Calcualate nearest scheduled date for current period or for next period.
			While (ScheduledDate < CurrentDate)
			   Or (CompletedUpTo >= ScheduledDate Or LastExecutionDate >= ScheduledDate) Do
				
				// Calculate the next day for event.
				ScheduledDate = ScheduledDate + Schedule.Days * DayTime;
			EndDo;
			
		// 2.2. Weekly.
		ElsIf Schedule.Interval = 2 Then
			
			// Check starting week.
			If (StartDate <= CurrentDate) Then // Start date is in the past or present.
				
				// Calculate current dates difference in weeks.
				WeekDiff = (CurrentDate - StartDate) / DayTime / 7;
				Occurencies = WeekDiff / Schedule.Weeks;
				If Occurencies > Int(Occurencies) Then // Scheduled for the week in the future.
					
					// Scheduled for the day in the future.
					ScheduledWeek = BegOfWeek(StartDate) + (Int(Occurencies) + 1) * Schedule.Weeks * WeekTime;
					
				Else // The event is scheduled for current week.
					
					// Calculate begin of the current week.
					ScheduledWeek = BegOfWeek(CurrentDate);
				EndIf;
				
			Else // Start date is in the future.
				
				// The first ocurrence is a start date.
				ScheduledWeek = BegOfWeek(StartDate);
			EndIf;
			
			// Calcualate nearest scheduled date for current period or for next period.
			While (ScheduledDate < CurrentDate)
			   Or (BegOfWeek(CompletedUpTo) >= BegOfWeek(ScheduledDate) Or BegOfWeek(LastExecutionDate) >= BegOfWeek(ScheduledDate)) Do
				
				// The specified Xth day of the scheduled week.
				ScheduledDate = ScheduledWeek + (Schedule.WeeksDay - 1) * DayTime;
				
				// Calculate the next week for event.
				ScheduledWeek = ScheduledWeek + Schedule.Weeks * WeekTime;
			EndDo;
			
		// 2.3. Monthly.
		ElsIf Schedule.Interval = 3 Then
			
			// 2.3.1. Calculate schedule date by the day of month.
			If Schedule.MonthType = 1 Then
				
				// Check starting month.
				If (StartDate <= CurrentDate) Then // Start date is in the past or present.
					
					// Calculate current dates difference in months.
					MonthDiff = (Year(CurrentDate) - Year(StartDate)) * 12 + (Month(CurrentDate) - Month(StartDate));
					Occurencies = MonthDiff / Schedule.Months;
					If Occurencies > Int(Occurencies) Then // Scheduled for the month in the future.
						
						// Scheduled for the day in the future.
						ScheduledMonth = AddMonth(BegOfMonth(StartDate), (Int(Occurencies) + 1) * Schedule.Months);
						
					Else // The event is scheduled for current month.
						
						// Calculate begin of the current month.
						ScheduledMonth = BegOfMonth(CurrentDate);
					EndIf;
					
				Else // Start date is in the future.
					
					// The first ocurrence is a start date.
					ScheduledMonth = BegOfMonth(StartDate);
				EndIf;
				
				// Calcualate nearest scheduled date for current period or for next period.
				While (ScheduledDate < CurrentDate)
				   Or (BegOfMonth(CompletedUpTo) >= BegOfMonth(ScheduledDate) Or BegOfMonth(LastExecutionDate) >= BegOfMonth(ScheduledDate)) Do
					
					// Calculate scheduled date for the scheduled month.
					If Schedule.MonthsDay = 29 Then
						// Last day of the scheduled month.
						ScheduledDate = BegOfDay(EndOfMonth(ScheduledMonth));
					Else
						// The specified Xth day of the scheduled month.
						ScheduledDate = ScheduledMonth + (Schedule.MonthsDay - 1) * DayTime;
					EndIf;
					
					// Calculate the next month for event.
					ScheduledMonth = AddMonth(ScheduledMonth, Schedule.Months);
				EndDo;
				
			// 2.3.2. Calculate schedule date by the day of week of month.
			ElsIf Schedule.MonthType = 2 Then
				
				// Check starting month.
				If (StartDate <= CurrentDate) Then // Start date is in the past or present.
					
					// Calculate current dates difference in months.
					MonthDiff = (Year(CurrentDate) - Year(StartDate)) * 12 + (Month(CurrentDate) - Month(StartDate));
					Occurencies = MonthDiff / Schedule.Months;
					If Occurencies > Int(Occurencies) Then // Scheduled for the month in the future.
						
						// Scheduled for the day in the future.
						ScheduledMonth = AddMonth(BegOfMonth(StartDate), (Int(Occurencies) + 1) * Schedule.Months);
						
					Else // The event is scheduled for current month.
						
						// Calculate begin of the current month.
						ScheduledMonth = BegOfMonth(CurrentDate);
					EndIf;
					
				Else // Start date is in the future.
					
					// The first ocurrence is a start date.
					ScheduledMonth = BegOfMonth(StartDate);
				EndIf;
				
				// Calcualate nearest scheduled date for current period or for next period.
				While (ScheduledDate < CurrentDate)
				   Or (BegOfMonth(CompletedUpTo) >= BegOfMonth(ScheduledDate) Or BegOfMonth(LastExecutionDate) >= BegOfMonth(ScheduledDate)) Do
					
					// Calculate scheduled week day for current month.
					If Schedule.MonthsWeek = 5 Then // Last week day in a month.
						
						// Calculate last week day.
						LastMonthDate = BegOfDay(EndOfMonth(ScheduledMonth));
						LastWeekDay   = WeekDay(LastMonthDate);
						
						// Calculate scheduled date basing on chronological week day in a month.
						If Schedule.MonthsWeekDay > LastWeekDay Then
							ScheduledDate = LastMonthDate - (7 - (Schedule.MonthsWeekDay - LastWeekDay)) * DayTime;
						Else
							ScheduledDate = LastMonthDate - (LastWeekDay - Schedule.MonthsWeekDay) * DayTime;
						EndIf;
						
					Else // Calculate Xth week day from the begin.
						
						// Calculate first week day.
						FirstMonthDate = ScheduledMonth;
						FirstWeekDay   = WeekDay(FirstMonthDate);
						
						// Calculate scheduled date basing on chronological week day in a month.
						If Schedule.MonthsWeekDay >= FirstWeekDay Then
							ScheduledDate = FirstMonthDate + (Schedule.MonthsWeekDay - FirstWeekDay) * DayTime + (Schedule.MonthsWeek - 1) * WeekTime;
						Else
							ScheduledDate = FirstMonthDate + (7 - (FirstWeekDay - Schedule.MonthsWeekDay)) * DayTime + (Schedule.MonthsWeek - 1) * WeekTime;
						EndIf;
					EndIf;
					
					// Calculate the next month for event.
					ScheduledMonth = AddMonth(ScheduledMonth, Schedule.Months);
				EndDo;
				
			Else // Type of month start date is not defined.
				Return EmptyDate;
			EndIf;
			
		// 2.4. Yearly.
		ElsIf Schedule.Interval = 4 Then
			
			// Check starting year.
			If (StartDate <= CurrentDate) Then // Start date is in the past or present.
				
				// Calculate current dates difference in years.
				YearDiff = Year(CurrentDate) - Year(StartDate);
				Occurencies = YearDiff;
				If Occurencies > Int(Occurencies) Then // Scheduled for the year in the future.
					
					// Scheduled for the day in the future.
					ScheduledYear = AddMonth(BegOfYear(StartDate), (Int(Occurencies) + 1) * 12);
					
				Else // The event is scheduled for current year.
					
					// Calculate begin of the current year.
					ScheduledYear = BegOfYear(CurrentDate);
				EndIf;
				
			Else // Start date is in the future.
				
				// The first ocurrence is a start date.
				ScheduledYear = BegOfYear(StartDate);
			EndIf;
			
			// Calcualate nearest scheduled date for current period or for next period.
			While (ScheduledDate < CurrentDate)
			   Or (BegOfYear(CompletedUpTo) >= BegOfYear(ScheduledDate) Or BegOfYear(LastExecutionDate) >= BegOfYear(ScheduledDate)) Do
				
				// Calculate scheduled month for the scheduled year.
				ScheduledMonth = AddMonth(ScheduledYear, Schedule.YearsMonth - 1);
				
				// Calculate scheduled date for scheduled month.
				If Schedule.YearsMonthDay = 29 Then
					// Last day of the scheduled month.
					ScheduledDate = BegOfDay(EndOfMonth(ScheduledMonth));
				Else
					// The specified Xth day of the scheduled month.
					ScheduledDate = ScheduledMonth + (Schedule.YearsMonthDay - 1) * DayTime;
				EndIf;
				
				// Calculate the next year for event.
				ScheduledYear = AddMonth(ScheduledYear, 12);
			EndDo;
			
		Else // Interval is not defined.
			Return EmptyDate;
		EndIf;
		
		// 3. Ajust scheduled date to the stop date (if defined).
		If (StopDate > EmptyDate) And (ScheduledDate > StopDate) Then
			Return EmptyDate;
		EndIf;
		
		// 4. Calculate event date before the schedule date.
		If Schedule.Action = 1 Then    // Action: Generate.
			
			// Assign event date according to the schedule date.
			If ScheduledDate > EmptyDate Then
				EventDate = ScheduledDate - Schedule.DaysAdvance * DayTime;
			Else
				EventDate = EmptyDate;
			EndIf;
			
		ElsIf Schedule.Action = 2 Then // Action: Remind.
			
			// Assign event date according to the schedule date.
			If ScheduledDate > EmptyDate Then
				EventDate = ScheduledDate - Schedule.RemindBefore * DayTime;
			Else
				EventDate = EmptyDate;
			EndIf;
		EndIf;
		
		// Return calculated scheduled date.
		Return ScheduledDate;
		
	ElsIf Schedule.Action = 3 Then       // Action: Save.
		// Just saved in a list. Scheduled date is not defined.
		Return EmptyDate;
		
	Else
		// Scheduled date is not defined.
		Return EmptyDate;
	EndIf;
	
EndFunction

// Process current scheduled actions planned for the current date.
//
// Parameters:
//  CurrentDate       - Date        - Date, the actions are calculated for, usually the current server date.
//  SelectedDocument  - DocumentRef - Recurring document which must be processed out of assigned schedule.
//
// Returns:
//  Boolean - The succesion of scheduled actions processing.
//
Function ProcessCurrentScheduledActions(CurrentEventDate, SelectedDocument = Undefined) Export
	
	// Define function variables.
	SuccessfullyCompleted = True;
	CurrentDate   = BegOfDay(CurrentEventDate);
	EmptyDate     = '00010101'; // Empty date
	NextEventDate = EmptyDate;
	
	// Request the data without checking the user rights.
	SetPrivilegedMode(True);
	
	// 1. Search for scheduled actions which event occurs today.
	SourceQuery = 
		"SELECT
		|	RecurringDocuments.RecurringDocument,
		|	RecurringDocuments.LineID,
		|	RecurringDocuments.Schedule,
		|	RecurringDocuments.SchedulePresentation,
		|	RecurringDocuments.ScheduledDate,
		|	RecurringDocuments.EventDate,
		|	RecurringDocuments.CompletedUpTo,
		|	RecurringDocuments.LastExecutionDate,
		|	RecurringDocuments.OccurrencesCount
		|FROM
		|	InformationRegister.RecurringDocuments AS RecurringDocuments
		|WHERE
		|{Condition}";
		
	// Add proper condition to a query.
	If SelectedDocument = Undefined Then // Process all documents in a range EventDate <= CurrentDate <= ScheduledDate
		QueryText = StrReplace(SourceQuery, "{Condition}",
		"     (RecurringDocuments.EventDate         > &EmptyDate AND RecurringDocuments.EventDate         <= &CurrentDate)
		|AND  (RecurringDocuments.ScheduledDate     > &EmptyDate AND RecurringDocuments.ScheduledDate     >= &CurrentDate)
		|AND ((RecurringDocuments.CompletedUpTo     > &EmptyDate AND RecurringDocuments.CompletedUpTo     <  &CurrentDate) OR (RecurringDocuments.CompletedUpTo     = &EmptyDate))
		|AND ((RecurringDocuments.LastExecutionDate > &EmptyDate AND RecurringDocuments.LastExecutionDate <  &CurrentDate) OR (RecurringDocuments.LastExecutionDate = &EmptyDate))");
	Else // Process the selected document only independent of the nearest schedule date.
		QueryText = StrReplace(SourceQuery, "{Condition}",
		"	RecurringDocuments.RecurringDocument = &SelectedDocument");
	EndIf;
	
	// Create the query and pass it's parameters.
	Query = New Query(QueryText);
	Query.SetParameter("CurrentDate",      CurrentDate);
	Query.SetParameter("EmptyDate",        EmptyDate);
	Query.SetParameter("SelectedDocument", SelectedDocument);
	
	// Process selected actions.
	QueryResult = Query.Execute();
	If Not QueryResult.IsEmpty() Then
		
		Try
			// Update the database in transaction.
			BeginTransaction(DataLockControlMode.Managed);
			
			// Create a list of documents to be locked.
			LockDocuments = QueryResult.Unload().Copy(,"RecurringDocument");
			LockDocuments.GroupBy("RecurringDocument");
			
			// Lock the register records preventing reading old schedule data.
			DocumentPosting.LockDataSourceBeforeWrite("InformationRegister.RecurringDocuments", LockDocuments, DataLockMode.Exclusive);
			
			// Get record manager.
			RecordManager = InformationRegisters.RecurringDocuments.CreateRecordManager();
			
			// Get current document.
			Selection = QueryResult.Select();
			While Selection.Next() Do
				
				// Get schedule details.
				ScheduleStructure = Selection.Schedule.Get();
				
				// Execute the action for the document.
				If ExecuteScheduledAction(Selection.RecurringDocument, ScheduleStructure, Selection.ScheduledDate, Selection.SchedulePresentation) Then
					
					// Update schedule data.
					RecordManager.RecurringDocument    = Selection.RecurringDocument;
					RecordManager.LineID               = Selection.LineID;
					RecordManager.Schedule             = Selection.Schedule;
					RecordManager.SchedulePresentation = Selection.SchedulePresentation;
					
					// Calculate next schedule date.
					RecordManager.ScheduledDate        = CalculateScheduledDate(EmptyDate, ScheduleStructure, CurrentDate, Selection.ScheduledDate, Selection.OccurrencesCount + 1, NextEventDate);
					RecordManager.EventDate            = NextEventDate;
					RecordManager.CompletedUpTo        = ?(RecordManager.ScheduledDate > EmptyDate, Selection.ScheduledDate, EmptyDate); // Lock current schedule date (do no track the schedule till the completed date).
					
					// Update the last event occurrence.
					RecordManager.LastExecutionDate    = CurrentDate;
					RecordManager.OccurrencesCount     = Selection.OccurrencesCount + 1;
					RecordManager.Write(True);
					
				Else // There are some errors while processing the action.
					SuccessfullyCompleted = False;
				EndIf;
			EndDo;
			
			Try
				CommitTransaction();
			Except
				// The transaction is rolled back.
				SuccessfullyCompleted = False;
			EndTry;
		Except
			// The schedule register can not be locked.
			SuccessfullyCompleted = False;
		EndTry;
	EndIf;
	
	// 2. Search for outdated events and update the schedule date for them.
	If SelectedDocument = Undefined Then
		// Add another condition to a query.
		QueryText = StrReplace(SourceQuery, "{Condition}",
		"	(RecurringDocuments.ScheduledDate > &EmptyDate AND RecurringDocuments.ScheduledDate < &CurrentDate)");
		Query.Text = QueryText;
		
		// Process outdated recurring documents.
		QueryResult = Query.Execute();
		If Not QueryResult.IsEmpty() Then
			
			Try
				// Update the database in transaction.
				BeginTransaction(DataLockControlMode.Managed);
				
				// Create a list of documents to be locked.
				LockDocuments = QueryResult.Unload().Copy(,"RecurringDocument");
				LockDocuments.GroupBy("RecurringDocument");
				
				// Lock the register records preventing reading old schedule data.
				DocumentPosting.LockDataSourceBeforeWrite("InformationRegister.RecurringDocuments", LockDocuments, DataLockMode.Exclusive);
				
				// Get record manager.
				RecordManager = InformationRegisters.RecurringDocuments.CreateRecordManager();
				
				// Get current document.
				Selection = QueryResult.Select();
				While Selection.Next() Do
					
					// Get schedule details.
					ScheduleStructure = Selection.Schedule.Get();
					
					// Update schedule data.
					RecordManager.RecurringDocument    = Selection.RecurringDocument;
					RecordManager.LineID               = Selection.LineID;
					RecordManager.Schedule             = Selection.Schedule;
					RecordManager.SchedulePresentation = Selection.SchedulePresentation;
					
					// Calculate completance date.
					CompletedUpTo = ?(BegOfDay(Selection.RecurringDocument.Date) > Selection.CompletedUpTo, BegOfDay(Selection.RecurringDocument.Date), Selection.CompletedUpTo);
					
					// Calculate next schedule date.
					RecordManager.ScheduledDate        = CalculateScheduledDate(EmptyDate, ScheduleStructure, Selection.LastExecutionDate, CompletedUpTo, Selection.OccurrencesCount, NextEventDate);
					RecordManager.EventDate            = NextEventDate;
					RecordManager.CompletedUpTo        = Selection.CompletedUpTo;
					
					// Update the last event occurrence.
					RecordManager.LastExecutionDate    = Selection.LastExecutionDate;
					RecordManager.OccurrencesCount     = Selection.OccurrencesCount;
					RecordManager.Write(True);
				EndDo;
				
				Try
					CommitTransaction();
				Except
					// The transaction is rolled back.
					SuccessfullyCompleted = False;
				EndTry;
			Except
				// The schedule register can not be locked.
				SuccessfullyCompleted = False;
			EndTry;
		EndIf;
	EndIf;
	
	// Return the succession flag.
	Return SuccessfullyCompleted;
	
EndFunction

// Executes the planned action.
//
// Parameters:
//  RecurringDocument        - Document.Ref - Source document which will be copied/notified during the action.
//  FromSchedule             - Structure    - Scedule describing new document/notification cration mode.
//  ScheduledDate            - Date         - Date by which the new document will be created, usually the current server date.
//  NotificationPresentation - String       - Notification message which will be presented in notification.
//
// Returns:
//  Boolean - The succesion of scheduled actions processing.
//
Function ExecuteScheduledAction(RecurringDocument, FromSchedule, ScheduledDate, NotificationPresentation) Export
	
	// Define function variables.
	SuccessfullyCompleted = True;
	
	// Get default schedule (structure compatibility protection)
	Schedule = GetDefaultSchedule();
	FillPropertyValues(Schedule, FromSchedule);
	
	// Process specified action.
	If Schedule.Action    = 1 Then // Generate.
		Try
			// Generate a document copy.
			DocumentCopy = RecurringDocument.Copy();
			DocumentCopy.Date = ScheduledDate;
			
			// Write created document.
			If Schedule.GenerateMode    = 1 Then // Create draft documents.
				DocumentCopy.Write();
			ElsIf Schedule.GenerateMode = 2 Then // Create posted documents.
				DocumentCopy.Write(DocumentWriteMode.Posting,  DocumentPostingMode.Regular);
			EndIf;
		Except
			// Failed writing the document.
			SuccessfullyCompleted = False;
		EndTry;
		
	ElsIf Schedule.Action = 2 Then // Remind.
		Try
			// Create new notification.
			Notification = InformationRegisters.Notifications.CreateRecordManager();
			Notification.Period      = ScheduledDate;
			Notification.Subject     = StringFunctionsClientServer.SubstituteParametersInString(
			                           NStr("en = 'Generate a copy of %1.'"), RecurringDocument);
			Notification.Description = NotificationPresentation;
			Notification.Object      = RecurringDocument;
			Notification.Write(False);
		Except
			// Failed writing the notification.
			SuccessfullyCompleted = False;
		EndTry;
	EndIf;
	
	// Return the succession flag.
	Return SuccessfullyCompleted;
	
EndFunction

#EndIf

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region PRIVATE_IMPLEMENTATION

#EndRegion
