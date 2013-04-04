

////////////////////////////////////////////////////////////////////////////////
// FORM EVENT HANDLERS
//

&AtServer
Procedure OnCreateAtServer(Cancellation, StandardProcessing)

	Action = Parameters.Action;
	
	If Find(", Add, Copy, Change,", ", " + Action + ",") = 0 Then
		Raise(NStr("en = 'Incorrect parameters in Scheduled Job form'"));
	EndIf;
	Items.UserName.Enabled = NOT CommonUse.FileInformationBase();
	
	If Action = "Add" Then
		Schedule = New JobSchedule;
		For each ScheduledJobMetadata IN Metadata.ScheduledJobs Do
			ScheduledJobsMetadataDetailss.Add
			(ScheduledJobMetadata.Name + "
			 |" + ScheduledJobMetadata.Synonym + "
			 |" + ScheduledJobMetadata.MethodName,
			 ?(IsBlankString(ScheduledJobMetadata.Synonym),
			   ScheduledJobMetadata.Name,
			   ScheduledJobMetadata.Synonym) );
		EndDo;
	Else
		SchTask = ScheduledJobsServer.GetScheduledJob(Parameters.Id);
		FillPropertyValues(ThisForm, SchTask, "Key, Description, Use, UserName, RestartIntervalOnFailure, RestartCountOnFailure");
		Id        = String(SchTask.Uuid);
		MetadataName        = ?(SchTask.Metadata <> Undefined, SchTask.Metadata.Name,       NStr("en = '<no metadata>'"));
		MetadataSynonym    = ?(SchTask.Metadata <> Undefined, SchTask.Metadata.Synonym,   NStr("en = '<no metadata>'"));
		MetadataMethodName  = ?(SchTask.Metadata <> Undefined, SchTask.Metadata.MethodName, NStr("en = '<no metadata>'"));
		Schedule = SchTask.Schedule;
		UserMessagesAndErrorInformationDetails = ScheduledJobsServer.MessagesAndDescriptionsOfScheduledJobErrors(SchTask);
	EndIf;
	
	If Action <> "Change" Then
		Id = NStr("en = '<will be created during recording>'");
		Use = False;
		Description = ?(Action = "Add", "", ScheduledJobsServer.ScheduledJobPresentation(SchTask));
	EndIf;
	
	// Fill choice list of user name
	ScheduledJobsServer.AddUsernamesToValueList(Items.UserName.ChoiceList);
	
EndProcedure 

&AtClient
Procedure OnOpen(Cancellation)
	
	If Action = "Add" Then
		// Scheduled job (metadata) template choice
		ItemOfList = ScheduledJobsMetadataDetailss.ChooseItem(NStr("en = 'Select predefined template for the scheduled job'"));
		If ItemOfList = Undefined Then
			Cancellation = True;
			Return;
		Else
			MetadataName       = StrGetLine(ItemOfList.Value, 1);
			MetadataSynonym    = StrGetLine(ItemOfList.Value, 2);
			MetadataMethodName = StrGetLine(ItemOfList.Value, 3);
			Description        = ItemOfList.Presentation;
		EndIf;
	EndIf;
	
	mJobRecorded = False;
	RefreshFormTitle();

EndProcedure

&AtClient
Procedure BeforeClose(Cancellation, StandardProcessing)
	
	If Modified Then
		ReturnCode = DoQueryBox(NStr("en = 'Write changes?'"), QuestionDialogMode.YesNoCancel);
		If ReturnCode = DialogReturnCode.Yes Then
			WriteScheduledJob();
		ElsIf ReturnCode = DialogReturnCode.Cancel Then
			Cancellation = True;
		EndIf;
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Event handlers of commands and form items
//

&AtClient
Procedure WriteAndCloseExecute()
	
	WriteScheduledJob();
	Close();
	
EndProcedure

&AtClient
Procedure Write(Command)
	
	WriteScheduledJob();
	
EndProcedure

&AtClient
Procedure OpenScheduleExecute()

	Dialog = New ScheduledJobDialog(Schedule);
	If Dialog.DoModal() Then
		Schedule = Dialog.Schedule;
		Modified = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure DescriptionOnChange(Item)
	
	RefreshFormTitle();
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Auxiliary form procedures and functions
//

&AtClient
Procedure WriteScheduledJob()
	
	WriteScheduledJobAtServer();
	RefreshFormTitle();
	Notify("ScheduledJobModified");
	
EndProcedure

&AtServer
Procedure WriteScheduledJobAtServer()
	
	If Action = "Change" Then
		SchTask = ScheduledJobsServer.GetScheduledJob(Id);
	Else
		SchTask = ScheduledJobs.CreateScheduledJob(Metadata.ScheduledJobs[MetadataName]);
		Id = String(SchTask.Uuid);
		Action = "Change";
	EndIf;
	
	FillPropertyValues(SchTask, ThisForm, "Key, Description, Use, UserName, RestartIntervalOnFailure, RestartCountOnFailure");
	SchTask.Schedule = Schedule;
	SchTask.Write();
	
	Modified = False;
	
EndProcedure

&AtClient
Procedure RefreshFormTitle()
	
	If NOT IsBlankString(Description) Then
		Presentation = Description;
	ElsIf NOT IsBlankString(MetadataSynonym) Then
		Presentation = MetadataSynonym;
	Else
		Presentation = MetadataName;
	EndIf;
	If Action <> "Change" Then
		Title = StringFunctionsClientServer.SubstitureParametersInString(NStr("en = 'Scheduled Job (Create)'"), Presentation);
	Else
		Title = StringFunctionsClientServer.SubstitureParametersInString(NStr("en = '%1 (Scheduled Job)'"), Presentation);
	EndIf;
	
EndProcedure

