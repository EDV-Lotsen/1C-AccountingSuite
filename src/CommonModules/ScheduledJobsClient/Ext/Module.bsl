

////////////////////////////////////////////////////////////////////////////////
// PROCEDURES HANDLING SYSTEM EVENTS
//

// Handler of event OnStart is called
// for executing actions, required for the subsystem ScheduledJobs.
//
Procedure OnStart() Export

	If Find(LaunchParameter, "DoScheduledJobs") <> 0 Then
		Warn  = (Find(LaunchParameter, "SkipMessageBox") =  0);
		SeparateSession = (Find(LaunchParameter, "AloneIBSession") <> 0);
		#If WebClient Then
			Exit(False);
		#EndIf
		If StandardSubsystemsClientSecondUse.ClientParameters().FileInformationBase Then
			TasksAreProcessingOK = Undefined;
			ErrorDescription = "";
			If ScheduledJobsServer.CurrentSessionHandlesTasks(TasksAreProcessingOK, True, ErrorDescription) Then
				SetApplicationCaption(StringFunctionsClientServer.SubstitureParametersInString(NStr("en = 'Scheduled jobs processing: %1'"),
				                                                                                      GetApplicationCaption() ));
				If SeparateSession Then
					// Process in separate session.
					MainWindow = MainWindow();
					If MainWindow = Undefined Then
						OpenForm("DataProcessor.ScheduledAndBackgroundJobs.Form.DesktopOfSeparateSessionOfScheduledJobs" );
					Else
						OpenForm("DataProcessor.ScheduledAndBackgroundJobs.Form.DesktopOfSeparateSessionOfScheduledJobs",,,, MainWindow);
					EndIf;
					If OpenFormModal("DataProcessor.ScheduledAndBackgroundJobs.Form.ScheduledJobsProcessing") = "Restart" Then
						Exit(False, True, " /C""" + LaunchParameter + """");
					EndIf;
					Exit(False);
				Else
					// Process in current session.
					AttachIdleHandler("ScheduledJobsProcessingInMainSession", 1, True);
				EndIf;
			Else
				If Warn Then
					If TasksAreProcessingOK Then
						DoMessageBox(NStr("en = 'Scheduled jobs processing session is already open!'"));
					Else
						DoMessageBox(StringFunctionsClientServer.SubstitureParametersInString(NStr("en = 'Scheduled jobs processing session is already open!"" ""%1'"), ErrorDescription ));
					EndIf;
				EndIf;
				If SeparateSession Then
					Exit(False);
				EndIf;
			EndIf;
		Else
			If Warn Then
				DoMessageBox(NStr("en = 'Scheduled jobs are processed on the server! '"));
			EndIf;
			If SeparateSession Then
				Exit(False);
			EndIf;
		EndIf;
		
	ElsIf StandardSubsystemsClientSecondUse.ClientParameters().FileInformationBase Then
		
		ParametersReadOnly = StandardSubsystemsClientSecondUse.ClientParameters().OpenParametersOfScheduledJobsProcessingSession;
		
		If ParametersReadOnly.Cancellation Then
			OnScheduledJobsProcessingError(ParametersReadOnly.ErrorDescription);
		ElsIf ParametersReadOnly.RequiredToOpenSeparateSession Then
			AttachIdleHandler("OpenSeparateSessionOfScheduledJobsProcessingViaIdleHandler", 1, True);
		EndIf;
		
		If ParametersReadOnly.NotifyAboutProcessingIncorrectStatus Then
			AttachIdleHandler("NotifyAboutFailureInScheduledJobsProcessingStatus", ParametersReadOnly.PeriodNotifications * 60, True);
		EndIf;
	EndIf;
	
EndProcedure // OnStart()


////////////////////////////////////////////////////////////////////////////////
// METHODS OF SCHEDULED JOBS MANAGER EXTENSION
//

// Function OpenSeparateSessionOfScheduledJobsProcessing() starts new session,
// handling scheduled jobs.
//  Only for thin and thick clients (Web is not supported).
//
// Value returned:
//  Structure
//    Cancellation             	- Boolean.
//    ErrorDescription    		- String.
//
Function OpenSeparateSessionOfScheduledJobsProcessing() Export
                                                          
	Parameters = ScheduledJobsServer.OpenParametersOfScheduledJobsProcessingSession(False);
	
	If NOT Parameters.Cancellation And Parameters.RequiredToOpenSeparateSession Then
		TryOpenSeparateSessionOfScheduledJobsDataProcessor(Parameters);
	EndIf;
	
	Return Parameters;
	
EndFunction // OpenSeparateSessionOfScheduledJobsProcessing()

// Procedure TryOpenSeparateSessionOfScheduledJobsDataProcessor()
// tries to open new session, handling scheduled jobs.
//
// Parameters:
//  Parameters    - Structure, used properties:
//                   AdditionalParametersOfCommandLine 				- String.
//                   Cancellation                                   - Boolean, output parameter.
//                   ErrorDescription                         		- String, output parameter.
//
Procedure TryOpenSeparateSessionOfScheduledJobsDataProcessor(Val Parameters) Export
	
	#If NOT WebClient Then
		Try
			Parameters.ExecutedOpenAttempt = True;
			RunSystem(
				?(Find(Upper(LaunchParameter), "/DEBUG") = Undefined, "", "/DEBUG ")
				+ Parameters.AdditionalParametersOfCommandLine);
		Except
			Parameters.ErrorDescription = ErrorDescription();
			Parameters.Cancellation = True;
		EndTry;
	#Else
		Parameters.Cancellation = True;
		Parameters.ErrorDescription = NStr( "en = 'Processing of scheduled jobs in a separate session of web client cannot be done!
                                             |To process the scheduled jobs administrator should set up standard to thin client in the web-server!'");
	#EndIf
	Parameters.ErrorDescription = ?(IsBlankString(Parameters.ErrorDescription),
	                             "",
	                             StrReplace(NStr("en = 'SessionNumber handling of scheduled jobs opening error: %1'"), "%1", Parameters.ErrorDescription));
	
EndProcedure // TryOpenSeparateSessionOfScheduledJobsDataProcessor()


////////////////////////////////////////////////////////////////////////////////
// OTHER PROCEDURES
//

// Procedure OnScheduledJobsProcessingError is called
// from the procedure ScheduledJobsGlobal.NotifyAboutFailureInScheduledJobsProcessingStatus()
// and ScheduledJobsClient.OnStart().
//  Call is done, if discovered, that something wrong in scheduled jobs processing:
// none processing session, "frozen" session, session ``is not operating`` for long time.
//
// Parameters:
//  ErrorDescription - String
//
Procedure OnScheduledJobsProcessingError(ErrorDescription) Export
	
	If StandardSubsystemsClientSecondUse.ClientParameters().OpenParametersOfScheduledJobsProcessingSession.CurrentUserAdministrator Then
		ShowUserNotification(
				NStr("en = 'Scheduled jobs are not processed. '"),
				"e1cib/app/DataProcessor.ScheduledAndBackgroundJobs",
				ErrorDescription,
				PictureLib.ErrorScheduledJobProcessing);
	Else
		ShowUserNotification(
				NStr("en = 'Scheduled jobs are not processed. '"),
				,
				ErrorDescription + Chars.LF + NStr("en = 'Contact to administrator.'"),
				PictureLib.ErrorScheduledJobProcessing);
	EndIf;
	
	
EndProcedure

// Procedure AttachGlobalIdleHandler() is used
// from displayed forms, because in the form module method is overrided.
//
Procedure AttachGlobalIdleHandler(ProcedureName, Interval, Once = False) Export

	AttachIdleHandler(ProcedureName, Interval, Once);
	
EndProcedure

// Procedure DisableGlobalIdleHandler() is used
// from displayed forms, because in the form module method is overrided.
//
Procedure DisableGlobalIdleHandler(ProcedureName) Export
	
	DetachIdleHandler(ProcedureName);

EndProcedure

Function MainWindow() Export
	
	MainWindow = Undefined;
	
	Windows = GetWindows();
	If Windows <> Undefined Then
		For each Window In Windows Do
			If Window.IsMain Then
				MainWindow = Window;
				Break;
			EndIf;
		EndDo;
	EndIf;
	
	Return MainWindow;
	
EndFunction
