

////////////////////////////////////////////////////////////////////////////////
// FORM EVENT HANDLERS
//

&AtServer
Procedure OnCreateAtServer(Cancellation, StandardProcessing)
	
	If NOT AccessRight("Administration", Metadata) Then
		Raise(NStr("en = 'User does not have administrative rights!'"));
	EndIf;
	Items.TableScheduledJobsProcessingSetup.Visible             = StandardSubsystemsOverrided.ClientParameters().FileInformationBase;
	Items.TableScheduledJobsOpenSeparateProcessingSession.Visible = StandardSubsystemsOverrided.ClientParameters().FileInformationBase;
	EmptyID = String(New Uuid("00000000-0000-0000-0000-000000000000"));
	TextUndefined = ScheduledJobsServer.TextUndefined();
	
	If CommonUse.FileInformationBase() Then
		Items.UserName.Visible = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancellation)
	
	If NOT SettingsLoaded Then
		OnLoadDataFromSettingsAtServer(New Map);
	EndIf;
	RefreshScheduledJobChoiceList();
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "ScheduledJobModified" Then
		RefreshScheduledJobsTable();
		RefreshScheduledJobChoiceList();
	EndIf;
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
		
	RefreshScheduledJobsTable();
	
	// Configure filter of background jobs
	If Settings.Get("FilterByActivityStatus") = Undefined Then
		Settings.Insert("FilterByActivityStatus", True);
	EndIf;
	
	If Settings.Get("FilterByCompletedStatus") = Undefined Then
		Settings.Insert("FilterByCompletedStatus", True);
	EndIf;
	
	If Settings.Get("FilterByCompletedStatusAborted") = Undefined Then
		Settings.Insert("FilterByCompletedStatusAborted", True);
	EndIf;

	If Settings.Get("FilterByCancelledStatus") = Undefined Then
		Settings.Insert("FilterByCancelledStatus", True);
	EndIf;
	
	If Settings.Get("FilterByScheduledJob") = Undefined
	 OR Settings.Get("ScheduledJobToBeFilteredID")   = Undefined Then
		Settings.Insert("FilterByScheduledJob", False);
		Settings.Insert("ScheduledJobToBeFilteredID", EmptyID);
	EndIf;
	
	// Configure filter by period "No filter"
	// (see. handler of event FilterKindByPeriodOnChange of radio button)
	If Settings.Get("FilterKindByPeriod") = Undefined
	 OR Settings.Get("FilterPeriodFrom")       = Undefined
	 OR Settings.Get("FilterPeriodTo")      = Undefined Then
		Settings.Insert("FilterKindByPeriod", 0);
		Settings.Insert("FilterPeriodFrom",  BegOfDay(CurrentDate()) - 3*360);
		Settings.Insert("FilterPeriodTo", BegOfDay(CurrentDate()) + 9*360);
	EndIf;
	
	For each KeyAndValue In Settings Do
		Try
			ThisForm[KeyAndValue.Key] = KeyAndValue.Value;
		Except
		EndTry;
	EndDo;
	// Configure visibility and accessibility.
	Items.FilterPeriodFrom.ReadOnly  = NOT (FilterKindByPeriod = 4);
	Items.FilterPeriodTo.ReadOnly = NOT (FilterKindByPeriod = 4);
	Items.ScheduledJobToBeFiltered.Enabled = FilterByScheduledJob;
	
	RefreshBackgroundJobsTable();
	
	
	SettingsLoaded = True;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Event handlers of commands and form items
//

&AtClient
Procedure ChangeScheduledJobExecute()
	
	AddCopyChangeScheduledJob("Change");
	
EndProcedure

&AtClient
Procedure RefreshDataExecute()
	
	RefreshData();
	
EndProcedure

&AtClient
Procedure OpenBackgroundJobExecute()
	
	If Items.TableBackgroundJobs.CurrentData = Undefined Then
		DoMessageBox (NStr("en = 'Select a background job'"));
	Else
		OpenFormModal("DataProcessor.ScheduledAndBackgroundJobs.Form.BackgroundJob",
		                     New Structure("Id", Items.TableBackgroundJobs.CurrentData.Id));
	EndIf;
	
EndProcedure

&AtClient
Procedure CancelBackgroundJobExecute()
	
	If Items.TableBackgroundJobs.CurrentData = Undefined Then
		DoMessageBox( NStr("en = 'Select a background job'") );
		
	Else
		CancelBackgroundJobAtServer(Items.TableBackgroundJobs.CurrentData.Id);
		DoMessageBox( NStr("en = 'The job cancelled, but cancellation status
                            |will be set in a few seconds,
                            |you might need to perform manual update.'") );
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenScheduledJobSheduleExecute()
	
	CurrentData = Items.TableScheduledJobs.CurrentData;
	
	If CurrentData = Undefined Then
		DoMessageBox( NStr("en = 'Select a scheduled job'") );
	Else
		Dialog = New ScheduledJobDialog(ScheduledJobsServer.GetScheduledJobSchedule(CurrentData.Id));
		If Dialog.DoModal() Then
			ScheduledJobsServer.SetScheduledJobSchedule(CurrentData.Id, Dialog.Schedule);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenSeparateSessionOfScheduledJobsProcessingExecute()
	
	AttachIdleHandler("OpenSeparateSessionOfScheduledJobsProcessingViaIdleHandler", 1, True);
	
EndProcedure

&AtClient
Procedure ScheduledJobsProcessingSettingsExecute()
	
	FormParameters = New Structure("HideCommandOfSeparateSessionOpening", True);
	
	OpenFormModal("DataProcessor.ScheduledAndBackgroundJobs.Form.ScheduledJobsProcessingSettings", FormParameters);
	
EndProcedure

&AtClient
Procedure ProcessScheduledJobManuallyExecute()

	If Items.TableScheduledJobs.CurrentData = Undefined Then
		DoMessageBox( NStr("en = 'Select a scheduled job'") );
	Else
		For each SelectedRow In Items.TableScheduledJobs.SelectedRows Do
			CurrentData = TableScheduledJobs.FindByID(SelectedRow);
			BackgroundTaskID = "";
			If StandardSubsystemsClientSecondUse.ClientParameters().FileInformationBase Then
				StartMoment = CurrentDate();
				ShowUserNotification(NStr("en = 'Scheduled job is running'"), ,
					StringFunctionsClientServer.SubstitureParametersInString(NStr("en = '%1.
                                                                                   |The procedure has been started in this session %2'"),
						CurrentData.Description,
						String(StartMoment)),
					PictureLib.RunScheduledJobManually);
				ProcessScheduledJobManuallyAtServer(CurrentData.Id, StartMoment, BackgroundTaskID);
			Else
				StartMoment = Undefined;
				ProcessScheduledJobManuallyAtServer(CurrentData.Id, StartMoment, BackgroundTaskID);
				ShowUserNotification(NStr("en = 'Scheduled job is running'"), ,
					StringFunctionsClientServer.SubstitureParametersInString(NStr("en = '%1.
                                                                                   |The procedure has been started in background job %2'"),
						CurrentData.Description,
						String(StartMoment)),
					PictureLib.RunScheduledJobManually);
			EndIf;
			JobIDsOnManualProcessing.Add(BackgroundTaskID, CurrentData.Description);
			AttachIdleHandler("MessageAboutEndingOfManualProcessingOfScheduledJob", 1, True);
		EndDo;
		
		
		For i=0 to 100 do
		For each SelectedRow In Items.TableScheduledJobs.SelectedRows Do
			CurrentData = TableScheduledJobs.FindByID(SelectedRow);
			BackgroundTaskID = "";
			If StandardSubsystemsClientSecondUse.ClientParameters().FileInformationBase Then
				StartMoment = CurrentDate();
				ShowUserNotification(NStr("en = 'Scheduled job is running'"), ,
					StringFunctionsClientServer.SubstitureParametersInString(NStr("en = '%1.
                                                                                   |The procedure has been started in this session %2'"),
						CurrentData.Description,
						String(StartMoment)),
					PictureLib.RunScheduledJobManually);
				ProcessScheduledJobManuallyAtServer(CurrentData.Id, StartMoment, BackgroundTaskID);
			Else
				StartMoment = Undefined;
				ProcessScheduledJobManuallyAtServer(CurrentData.Id, StartMoment, BackgroundTaskID);
				ShowUserNotification(NStr("en = 'Scheduled job started'"), ,
					StringFunctionsClientServer.SubstitureParametersInString(NStr("en = '%1.
                                                                                   |The procedure is started in background job %2'"),
						CurrentData.Description,
						String(StartMoment)),
					PictureLib.RunScheduledJobManually);
			EndIf;
			JobIDsOnManualProcessing.Add(BackgroundTaskID, CurrentData.Description);
			AttachIdleHandler("MessageAboutEndingOfManualProcessingOfScheduledJob", 1, True);
		EndDo;
		Enddo;
			
		
		
	EndIf;
	
EndProcedure


&AtClient
Procedure FilterKindByPeriodOnChange(Item)

	Items.FilterPeriodFrom.ReadOnly  = NOT (FilterKindByPeriod = 4);
	Items.FilterPeriodTo.ReadOnly = NOT (FilterKindByPeriod = 4);
	If FilterKindByPeriod = 0 Then
		FilterPeriodFrom = '00010101';
		FilterPeriodTo   = '00010101';
	ElsIf FilterKindByPeriod = 1 Then
		FilterPeriodFrom = BegOfDay(CurrentDate()) - 3*3600;
		FilterPeriodTo   = BegOfDay(CurrentDate()) + 9*3600;
	ElsIf FilterKindByPeriod = 2 Then
		FilterPeriodFrom = BegOfDay(CurrentDate()) - 24*3600;
		FilterPeriodTo   = EndOfDay(FilterPeriodFrom);
	ElsIf FilterKindByPeriod = 3 Then
		FilterPeriodFrom = BegOfDay(CurrentDate());
		FilterPeriodTo   = EndOfDay(FilterPeriodFrom);
	ElsIf FilterKindByPeriod = 4 Then
		FilterPeriodFrom = BegOfDay(CurrentDate());
		FilterPeriodTo   = FilterPeriodFrom;
	EndIf;
	
EndProcedure

&AtClient
Procedure FilterByScheduledJobOnChange(Item)

	Items.ScheduledJobToBeFiltered.Enabled = FilterByScheduledJob;
	
EndProcedure

&AtClient
Procedure ScheduledJobToBeFilteredClear(Item, StandardProcessing)

	StandardProcessing = False;
	ScheduledJobToBeFilteredID = EmptyID;
	ScheduledJobToBeFilteredPresentation = TextUndefined;
	
EndProcedure

&AtClient
Procedure ScheduledJobToBeFilteredChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	ItemOfList = Items.ScheduledJobToBeFiltered.ChoiceList.FindByValue(ValueSelected);
	ScheduledJobToBeFilteredID = ItemOfList.Value;
	ScheduledJobToBeFilteredPresentation = ItemOfList.Presentation;
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure ClearBackgroundJobsHistory(Command)
	
	ClearBackgroundJobsHistoryAtServer();
	
EndProcedure

&AtServer
Procedure ClearBackgroundJobsHistoryAtServer()
	
	ScheduledJobsServer.ClearBackgroundJobsHistory();
	RefreshData();
	
EndProcedure


&AtClient
Procedure TableBackgroundJobsSelection(Item, RowSelected, Field, StandardProcessing)
	
	OpenBackgroundJobExecute();
	
EndProcedure

&AtClient
Procedure TableScheduledJobsSelection(Item, RowSelected, Field, StandardProcessing)
	
	ChangeScheduledJobExecute();
	
EndProcedure

&AtClient
Procedure TableScheduledJobsBeforeAddRow(Item, Cancellation, Clone, Parent, Folder)
	
	Cancellation = True;
	
	AddCopyChangeScheduledJob(?(Clone, "Copy", "Add"));
	
EndProcedure

&AtClient
Procedure TableScheduledJobsBeforeDelete(Item, Cancellation)
	
	Cancellation = True;
	
	If Items.TableScheduledJobs.SelectedRows.Count() > 1 Then
		DoMessageBox(NStr("en = 'Select one scheduled job.'"));
	ElsIf Item.CurrentData.Predefined Then
		DoMessageBox( NStr("en = 'It is impossible to delete predefined scheduled job.'") );
	ElsIf DoQueryBox(NStr("en = 'Delete scheduled job?'"), QuestionDialogMode.YesNo) = DialogReturnCode.Yes Then
		DeleteScheduledJobExecuteAtServer(Items.TableScheduledJobs.CurrentData.Id);
	EndIf;
	
EndProcedure


////////////////////////////////////////////////////////////////////////////////
// Auxiliary form procedures and functions
//

&AtServer
Procedure RefreshScheduledJobChoiceList()
	
	Table = TableScheduledJobs;
	List = Items.ScheduledJobToBeFiltered.ChoiceList;
	// Add predefined item.
	If List.Count() = 0 Then
		List.Add(EmptyID, TextUndefined);
	EndIf;
	IndexOf = 1;
	For each SchTask IN Table Do
		If IndexOf >= List.Count() OR List[IndexOf].Value <> SchTask.Id Then
			// Insert new job
			List.Insert(IndexOf, SchTask.Id, SchTask.Description);
		Else
			List[IndexOf].Presentation = SchTask.Description;
		EndIf;
		IndexOf = IndexOf + 1;
	EndDo;
	// Delete needless rows
	While IndexOf < List.Count() Do
		List.Delete(IndexOf);
	EndDo;
	
	ItemOfList = List.FindByValue(ScheduledJobToBeFilteredID);
	If ItemOfList = Undefined Then
		ScheduledJobToBeFilteredID = EmptyID;
		ScheduledJobToBeFilteredPresentation = TextUndefined;
	Else
		ScheduledJobToBeFilteredPresentation = ItemOfList.Presentation;
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessScheduledJobManuallyAtServer(Val ScheduledJobID, StartMoment, BackgroundTaskID)
	
	ScheduledJobsServer.ProcessScheduledJobManually(ScheduledJobID, StartMoment, BackgroundTaskID);
	
	RefreshData();
	
EndProcedure

&AtServer
Procedure CancelBackgroundJobAtServer(Id)
	
	ScheduledJobsServer.CancelBackgroundJob(Id);
	
	RefreshData();
	
EndProcedure


&AtServer
Procedure DeleteScheduledJobExecuteAtServer(Id)
	
	SchTask = ScheduledJobsServer.GetScheduledJob(Id);
	String = TableScheduledJobs.FindRows(New Structure("Id", Id))[0];
	SchTask.Delete();
	TableScheduledJobs.Delete(TableScheduledJobs.IndexOf(String));
	
EndProcedure

&AtClient
Procedure AddCopyChangeScheduledJob(Action)
	
	If Items.TableScheduledJobs.CurrentData = Undefined Then
		DoMessageBox ( NStr("en = 'Select a scheduled job.'") );
		
	ElsIf Action = "Change" And Items.TableScheduledJobs.SelectedRows.Count() > 1 Then
		DoMessageBox(NStr("en = 'Select a scheduled job.'"));
	Else
		OpenFormModal("DataProcessor.ScheduledAndBackgroundJobs.Form.ScheduledJob",
		                     New Structure("Id, Action",
		                                      Items.TableScheduledJobs.CurrentData.Id,
		                                      Action));
	EndIf;
	
EndProcedure


&AtClient
Procedure MessageAboutEndingOfManualProcessingOfScheduledJob()
	
	AlertsAboutProcessingEnding = AlertsAboutScheduledJobsProcessingEnding();
	For each Alert In AlertsAboutProcessingEnding Do
			ShowUserNotification(NStr("en = 'Scheduled job completed'"), ,
				StringFunctionsClientServer.SubstitureParametersInString(NStr("en = '%1.
                                                                               |The procedure completed %2'"),
					Alert.ScheduledJobPresentation,
					String(Alert.EndMoment)),
				PictureLib.RunScheduledJobManually);
	EndDo;
	
	If JobIDsOnManualProcessing.Count() > 0 Then
		AttachIdleHandler("MessageAboutEndingOfManualProcessingOfScheduledJob", 1, True);
	EndIf;

EndProcedure

&AtServer
Function AlertsAboutScheduledJobsProcessingEnding()
	
	AlertsAboutProcessingEnding = New Array;
	If JobIDsOnManualProcessing.Count() > 0 Then
		IndexOf = JobIDsOnManualProcessing.Count() - 1;
		While IndexOf >= 0 Do
			EndMoment = ScheduledJobsServer.GetBackgroundJobProperties(JobIDsOnManualProcessing[IndexOf].Value, "End").End;
			If ValueIsFilled(EndMoment) Then
				AlertsAboutProcessingEnding.Add(New Structure("ScheduledJobPresentation, EndMoment", JobIDsOnManualProcessing[IndexOf].Presentation, EndMoment));
				JobIDsOnManualProcessing.Delete(IndexOf);
			EndIf;
			IndexOf = IndexOf - 1;
		EndDo;
	EndIf;
	
	RefreshData();
	
	Return AlertsAboutProcessingEnding;
	
EndFunction

&AtServer
Procedure RefreshData()
	
	RefreshScheduledJobsTable();
	RefreshBackgroundJobsTable();
	RefreshScheduledJobChoiceList();
	
EndProcedure

&AtServer
Procedure RefreshScheduledJobsTable()

	// Update TableScheduledJobs and ChoiceList of scheduled job for filter.
	CurrentTasks = ScheduledJobs.GetScheduledJobs();
	Table = TableScheduledJobs;
	IndexOf = 0;
	For each SchTask IN CurrentTasks Do
		Id = String(SchTask.Uuid);
		If IndexOf >= Table.Count() OR Table[IndexOf].Id <> Id Then
			// Insert new job
			Updated = Table.Insert(IndexOf);
			// Assign unique ID
			Updated.Id = Id;
		Else
			Updated = Table[IndexOf];
		EndIf;
		FillPropertyValues(Updated, SchTask);
		// Clarify Description
		Updated.Description = ScheduledJobsServer.ScheduledJobPresentation(SchTask);
		// Assign CompletionDate and CompletionStatus by last background procedure
		LastBackgroundJobProperties = ScheduledJobsServer.GetLastBackgroundJobPropertiesOfScheduledJobDataProcessor(SchTask);
		If LastBackgroundJobProperties = Undefined Then
			Updated.EndDate       = TextUndefined;
			Updated.RunStatus = TextUndefined;
		Else
			Updated.EndDate       = ?(ValueIsFilled(LastBackgroundJobProperties.End),
			                                    LastBackgroundJobProperties.End,
			                                    "<>");
			Updated.RunStatus = LastBackgroundJobProperties.State;
		EndIf;
		IndexOf = IndexOf + 1;
	EndDo;
	// Delete needless rows
	While IndexOf < Table.Count() Do
		Table.Delete(IndexOf);
	EndDo;
	
EndProcedure

&AtServer
Procedure RefreshBackgroundJobsTable()
	
	// 1. Create filter
	Filter = New Structure;
	// 1.1. Add filter by statuses
	StatesArray = New Array;
	If FilterByActivityStatus Then 
		StatesArray.Add(BackgroundJobState.Active);
	EndIf;
	If FilterByCompletedStatus Then 
		StatesArray.Add(BackgroundJobState.Completed);
	EndIf;
	If FilterByCompletedStatusAborted Then 
		StatesArray.Add(BackgroundJobState.Failed);
	EndIf;
	If FilterByCancelledStatus Then 
		StatesArray.Add(BackgroundJobState.Canceled);
	EndIf;
	If StatesArray.Count() <> 4 Then
		If StatesArray.Count() = 1 Then
			Filter.Insert("State", StatesArray[0]);
		Else
			Filter.Insert("State", StatesArray);
		EndIf;
	EndIf;
	// 1.2. Add filter by scheduled job
	If FilterByScheduledJob Then
		Filter.Insert(
				"ScheduledJobID",
				?(ScheduledJobToBeFilteredID = EmptyID,
				"",
				ScheduledJobToBeFilteredID));
	EndIf;
	// 1.3. Add filter by period
	If FilterKindByPeriod <> 0 Then
		Filter.Insert("Begin", FilterPeriodFrom);
		Filter.Insert("End",  FilterPeriodTo);
	EndIf;
	
	// 2. Update list of background jobs
	Table = TableBackgroundJobs;
	BackgroundJobsQuantityTotal = 0;
	CurrentTable = ScheduledJobsServer.GetBackgroundJobsPropertiesTable(Filter, BackgroundJobsQuantityTotal);
	IndexOf = 0;
	For each SchTask IN CurrentTable Do
		If IndexOf >= Table.Count() OR Table[IndexOf].Id <> SchTask.Id Then
			// Insert new job
			Updated = Table.Insert(IndexOf);
			// Assign unique ID
			Updated.Id = SchTask.Id;
		Else
			Updated = Table[IndexOf];
		EndIf;
		FillPropertyValues(Updated, SchTask);
		// Set description of scheduled job from collection TableScheduledJobs
		Rows = TableScheduledJobs.FindRows(New Structure("Id", SchTask.ScheduledJobID));
		If Rows.Count() = 0 Then
			Updated.ScheduledJobDescription = ?(IsBlankString(SchTask.ScheduledJobID),
			                                                 TextUndefined,
			                                                 NStr("en = '<not found>'"));
		Else
			Updated.ScheduledJobDescription = Rows[0].Description;
		EndIf;
		// Set end date of selected background job
		Updated.End = ?(ValueIsFilled(SchTask.End), Updated.End, "<>");
		// Increment index
		IndexOf = IndexOf + 1;
	EndDo;
	// Delete needless rows
	While IndexOf < Table.Count() Do
		Table.Delete(Table.Count()-1);
	EndDo;
	BackgroundJobsQuantityInTable = Table.Count();

EndProcedure


