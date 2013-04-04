

// Procedure for getting report about errors and warning of eventlog
// Parameters
// SelectionPeriodBegin    - Date/DateTime - lower boundary of selection period
// SelectionPeriodEnding   - Date/DateTime - upper boundary of selection period
// SaveTimeOfLastSelection - Boolean - if true, then on successful selection
//                 			 to the storage of system settings ending time of current selection period
//                 			 will be recorded
//
// Note
// If selection period is not specified, then do selection for last 24 hours, if
// selection time has been saved earlier, then this time is set as
// period start.
//
//
Procedure GenerateErrorReportAndSendReport(Val SelectionPeriodBegin = Undefined,
                                                  Val SelectionPeriodEnding = Undefined,
                                                  Val SaveTimeOfLastSelection = True) Export
	
	If ValueIsFilled(SelectionPeriodBegin)
	   And ValueIsFilled(SelectionPeriodEnding) Then
		SelectionPeriod = New Structure;
		SelectionPeriod.Insert("Beginofperiod", SelectionPeriodBegin);
		SelectionPeriod.Insert("PeriodEnding",  SelectionPeriodEnding);
	Else
		SelectionPeriod = GetDataSelectionPeriod();
	EndIf;
	
	// based on data received generate report and write it on disk
	ReportResult = GenerateReport(SelectionPeriod.Beginofperiod,
	                                                SelectionPeriod.PeriodEnding);
	
	Report = ReportResult.Report;
	
	ReportFileName = GetTempFileName();
	
	Report.Write(ReportFileName);
	
	// generate and send message
	Attachments = New Map;
	
	Attachments.Insert("report.mxl", New BinaryData(ReportFileName));
	
	DeleteFiles(ReportFileName);
	
	MessageParameters = New Structure;
	
	ReportRecipients = EventLogManagement.GetReportReceiptRecipientsByEventLog();
	
	If IsBlankString(ReportRecipients) Then
		Raise NStr("en = 'No recipient of the error and warnings report specified.'");
		
	EndIf;
	
	MessageParameters.Insert("Recipient", ReportRecipients);
	
	IBPresentation = CommonUse.GetInfobasePresentation();
	
	MessageParameters.Insert("Subject",
	                StringFunctionsClientServer.SubstitureParametersInString(
	                  NStr("en = 'Event log control: %1.'"), IBPresentation ));
	
	MessageBodyText = NStr("en = 'Information on errors and warnings in the event log.
                            |Information base: %1.
                            |Data selection period: from %2 to %3.
                            |Errors total: %4.
                            |Warnings total: %5.
                            |Attachment contains detailed errors and warnings report.
                            |For more detailed information see event log.'");
	
	MessageBodyText = 
	            StringFunctionsClientServer.SubstitureParametersInString(
	                  MessageBodyText,
	                  IBPresentation,
	                  SelectionPeriod.Beginofperiod,
	                  SelectionPeriod.PeriodEnding,
	                  ReportResult.TotalByErrors,
	                  ReportResult.TotalByWarnings );
	
	MessageParameters.Insert("Body", MessageBodyText);
	
	MessageParameters.Insert("Attachments", Attachments);
	
	EmailOperations.SendEmail(EmailOperations.GetSystemAccount(),
							MessageParameters);
	
	If SaveTimeOfLastSelection Then
		SaveTimeOfLastInformationSelection(SelectionPeriod.PeriodEnding);
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// SERVICE FUNCTIONS

// Function gets information about errors in eventlog based on period specified
// Parameters
// BeginOfPeriod    - date - start of period
// PeriodEnding     - date - end of period
//
// Value to return:
// value table      - records from eventlog according to filter:
//                    EventLogLevel - EventLogLevel.Error
//                    Begin and End of period - from parameters
//
Function GetInformationAboutEventLogErrors(Val Beginofperiod, Val PeriodEnding)
	
	EventLogData = New ValueTable;
	
	ErrorsRegistrationLevels = New Array;
	ErrorsRegistrationLevels.Add(EventLogLevel.Error);
	ErrorsRegistrationLevels.Add(EventLogLevel.Warning);
	
	UnloadEventLog(EventLogData,
	                           New Structure("Level, StartDate, EndDate",
	                                           ErrorsRegistrationLevels,
	                                           Beginofperiod,
	                                           PeriodEnding));
	
	Return EventLogData;
	
EndFunction

// Service procedure defines period of time. We need to get eventlog
// data for this period. In addition procedure writes period ending using passed key
// to system setting storage - to use
// on next procedure call
//
Function GetDataSelectionPeriod()
	
	Result = New Structure;
	
	LatestInformationSelectionTime = GetLatestInformationSelectionTime();
	
	PeriodEnding = CurrentDate();
	
	If LatestInformationSelectionTime = Undefined Then // if scheduled job hasn't been executed yet  - select data for 24 hours
		BeginOfPeriod = PeriodEnding - 86400;
	Else
		BeginOfPeriod = LatestInformationSelectionTime;
	EndIf;
	
	Result.Insert("Beginofperiod", BeginOfPeriod);
	Result.Insert("PeriodEnding",  PeriodEnding);
	
	Return Result;
	
EndFunction

// Gets time of previous data collection from eventlog
//
Function GetLatestInformationSelectionTime()
	
	LatestInformationSelectionTime = Undefined;
	
	ReportParameters = CommonSettingsStorage.Load("ReportParametersByEventLog");
	
	If ReportParameters <> Undefined Then
		ReportParameters.Property("LatestInformationSelectionTime", LatestInformationSelectionTime);
	EndIf;
	
	Return LatestInformationSelectionTime;
	
EndFunction

// Saves time of previous data collection from eventlog
//
Procedure SaveTimeOfLastInformationSelection(LatestInformationSelectionTime)
	
	ReportParameters = CommonSettingsStorage.Load("ReportParametersByEventLog");
	
	If ReportParameters = Undefined Or TypeOf(ReportParameters) <> Type("Structure") Then
		ReportParameters = New Structure;
	EndIf;
	
	ReportParameters.Insert("LatestInformationSelectionTime", LatestInformationSelectionTime);
	
	CommonSettingsStorage.Save("ReportParametersByEventLog", ,
	                                     ReportParameters);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Block of functions for report generation

// Function, generates report about errors registered in eventlog
// Parameters
// EventLogData - value table - table unloaded from eventlog
// following columns are required: Date, UserName, ApplicationPresentation,
//                                          EventPresentation, Comment, Level
//
Function GenerateReport(	Val Beginofperiod,
							Val PeriodEnding) Export
	
	Result = New Structure;
	
	Report = New SpreadsheetDocument;
	
	Template = DataProcessors.EventLogMonitor.GetTemplate("ErrorsReportTemplateInEventLog");
	
	EventLogData = GetInformationAboutEventLogErrors(Beginofperiod, PeriodEnding);
	
	///////////////////////////////////////////////////////////////////////////////
	// Block of preliminary data prepare
	//
	
	GroupingByComments = EventLogData.Copy();
	GroupingByComments.Columns.Add("TotalByComment");
	GroupingByComments.FillValues(1, "TotalByComment");
	GroupingByComments.GroupBy("Level, Comment, Event, EventPresentation", "TotalByComment");
	
	RowsArray_LevelError = GroupingByComments.FindRows(
									New Structure("Level", EventLogLevel.Error));
	
	RowsArray_LevelWarning = GroupingByComments.FindRows(
									New Structure("Level", EventLogLevel.Warning));
	
	Grouping_Errors         = GroupingByComments.Copy(RowsArray_LevelError);
	Grouping_Errors.Sort("TotalByComment Desc");
	Grouping_Warning 		= GroupingByComments.Copy(RowsArray_LevelWarning);
	Grouping_Warning.Sort("TotalByComment Desc");
	
	///////////////////////////////////////////////////////////////////////////////
	// Block of report generation
	//
	
	Area = Template.GetArea("ReportHeader");
	Area.Parameters.SelectionPeriodBeginning    = Beginofperiod;
	Area.Parameters.SelectionPeriodEnd 			= PeriodEnding;
	Area.Parameters.InformationBasePresentation = CommonUse.GetInfobasePresentation();
	Report.Put(Area);
	
	TSBindingResult = GenerateTabularSection(Template, EventLogData, Grouping_Errors);
	
	Report.Put(Template.GetArea("IsBlankString"));
	Area = Template.GetArea("ErrorBlockTitle");
	Area.Parameters.NumberOfErrors = String(TSBindingResult.Total);
	Report.Put(Area);
	
	If TSBindingResult.Total > 0 Then
		Report.Put(TSBindingResult.TabularSection);
	EndIf;
	
	Result.Insert("TotalByErrors", TSBindingResult.Total);
	
	TSBindingResult = GenerateTabularSection(Template, EventLogData, Grouping_Warning);
	
	Report.Put(Template.GetArea("IsBlankString"));
	Area = Template.GetArea("WarningBlockTitle");
	Area.Parameters.NumberOfWarnings = TSBindingResult.Total;
	Report.Put(Area);
	
	If TSBindingResult.Total > 0 Then
		Report.Put(TSBindingResult.TabularSection);
	EndIf;
	
	Result.Insert("TotalByWarnings", TSBindingResult.Total);
	
	Report.ShowGrid = False;
	
	Result.Insert("Report", Report);
	
	Return Result;
	
EndFunction

// Add tabular section with errors to report. Errors are put grouped
// by comment.
// Parameters:
// Report  		- SpreadsheetDocument - report, where information will be displayed
// Template  	- SpreadsheetDocument - source of formatted areas, which will be used on report generation
// EventLogData - ValueTable - data about errors and warnings from eventlog "as is"
// GroupedData 	- ValueTable - information grouped by comments by their number
//
Function GenerateTabularSection(Template, EventLogData, GroupedData)
	
	Report = New SpreadsheetDocument;
	
	Total = 0;
	
	If GroupedData.Count() > 0 Then
		Report.Put(Template.GetArea("IsBlankString"));
		
		For Each Record In GroupedData Do
			Total = Total + Record.TotalByComment;
			RowsArray = EventLogData.FindRows(
			                   New Structure("Level, Comment",
			                           EventLogLevel.Error,
			                           Record.Comment));
			
			Area = Template.GetArea("TabularSectionBodyHeader");
			Area.Parameters.Fill(Record);
			Report.Put(Area);
			
			Report.StartRowGroup(, False);
			For Each String In RowsArray Do
				Area = Template.GetArea("TabularSectionBodyDetails");
				Area.Parameters.Fill(String);
				Report.Put(Area);
			EndDo;
			Report.EndRowGroup();
			Report.Put(Template.GetArea("IsBlankString"));
		EndDo;
	EndIf;
	
	Result = New Structure("TabularSection, Total", Report, Total);
	
	Return Result;
	
EndFunction

