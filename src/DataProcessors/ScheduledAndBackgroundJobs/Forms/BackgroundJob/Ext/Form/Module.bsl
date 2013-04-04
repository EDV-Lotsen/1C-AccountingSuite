


////////////////////////////////////////////////////////////////////////////////
// FORM EVENT HANDLERS
//

&AtServer
Procedure OnCreateAtServer(Cancellation, StandardProcessing)

	BackgroundJobProperties = ScheduledJobsServer.GetBackgroundJobProperties(Parameters.Id);
	FillPropertyValues(ThisForm, BackgroundJobProperties, "Key, Description, Begin, End, Location, State, MethodName");
	UserMessagesAndErrorInformationDetails = ScheduledJobsServer.MessagesAndDescriptionsOfBackgroundJobErrors(Parameters.Id);
	If ValueIsFilled(BackgroundJobProperties.ScheduledJobID) Then
		ScheduledJobID = BackgroundJobProperties.ScheduledJobID;
		ScheduledJobDescription  = ScheduledJobsServer.ScheduledJobPresentation(BackgroundJobProperties.ScheduledJobID);
	Else
		ScheduledJobDescription  = ScheduledJobsServer.TextUndefined();
		ScheduledJobID = ScheduledJobsServer.TextUndefined();
	EndIf;

EndProcedure

