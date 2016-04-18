
// Shows custom message box to the user
//
// Parameters:
//  FormOwner - ManagedForm - form-owner of the message window
//  Title - String - title of the message box
//  Message - String - message text
//  MessageStatus = EnumRef.MessageStatuse - defines an icon, displaying severity of the problem
//    supported values: NoStatus, Information, Warning
//
Procedure ShowCustomMessageBox(FormOwner, Title = "", Message, MessageStatus = Undefined, Notify = Undefined) Export
	If MessageStatus = Undefined Then 
		MessageStatus = PredefinedValue("Enum.MessageStatus.NoStatus");
	EndIf;
	If Not ValueIsFilled(Title) Then
		Title = "Message";
	EndIf;
	//Params = New Structure("Title, Message, MessageStatus", Title, Message, MessageStatus);
	//OpenForm("CommonForm.MessageBox", Params, FormOwner,,,,, FormWindowOpeningMode.LockOwnerWindow); 
	ArrayOfMessages = New Array();
	If MessageStatus = PredefinedValue("Enum.MessageStatus.NoStatus") Then
		
	ElsIf MessageStatus = PredefinedValue("Enum.MessageStatus.Information") Then
		ArrayOfMessages.Add(PictureLib.Information32);
	ElsIf MessageStatus = PredefinedValue("Enum.MessageStatus.Warning") Then
		ArrayOfMessages.Add(PictureLib.Warning32);
	EndIf;
	ArrayOfMessages.Add("    " + Message);
	If Notify <> Undefined Then
		ShowMessageBox(Notify, New FormattedString(ArrayOfMessages),,Title);
	Else
		ShowMessageBox(, New FormattedString(ArrayOfMessages),,Title);
	EndIf;
	
EndProcedure

// Shows custom query box to the user
//
// Parameters:
//  Notify - Type : NotifyDescription - procedure, that will process the results of user choice
//  Title - String - title of the message box
//  Message - String - message text
//
Procedure ShowCustomQueryBox(Notify, Message, DialogMode, Timeout=0, DefaultButton, Title = "") Export
	
	ArrayOfMessages = New Array();
	ArrayOfMessages.Add(PictureLib.Question32);
	ArrayOfMessages.Add("    " + Message);
	FormedString = New FormattedString(ArrayOfMessages);
	ShowQueryBox(Notify, FormedString, DialogMode, Timeout, DefaultButton, Title);
	
EndProcedure

Procedure CloseApp(Parameter1) Export
	Exit(False, False);
EndProcedure

#Region LONG_ACTION

// Begin to do long action.
//
// Parameters:
//  KeyDescription - String - Demonstrates description which shows form of long action.
//  KeyParameters  - Structure - Parameters for background job "CommonUse.DoLongAction".  
//  FormOwner      - ManagedForm - Reference of owner form, responsible for long action.
//
// Returns:
//  FixedArray - Data from background job "CommonUse.DoLongAction",
//  String     - Describing an error if failed,
//  UUID       - ID of background job if operation pending,
//  Undefined  - User cancels the operation.
//
Function StartLongAction(KeyDescription, KeyParameters, FormOwner) Export
	
	// Check background job parameters storage.
	Try
		// Access to the background parameters in the form.
		BackgroundJobParameters = FormOwner.BackgroundJobParameters;
	Except
		// Error accessing to form storage.
		Return Undefined;
	EndTry;
	
	// Define empty Job ID.
	JobID = New UUID("00000000-0000-0000-0000-000000000000");
	
	// Define result storage address, attached to owner form.
	StorageAddress = PutToTempStorage(JobID, FormOwner.UUID);
	
	// Define idle handler parameters (how long to wait before next check).
	IdleHandlerParameters = Undefined;
	LongActionsClient.InitIdleHandlerParameters(IdleHandlerParameters);
	
	// Define empty handler to splash form.
	SplashForm = Undefined;
	
	// Define initial state of background job parameters.
	BackgroundJobParameters.Clear();
	BackgroundJobParameters.Add(JobID);
	BackgroundJobParameters.Add(StorageAddress);
	BackgroundJobParameters.Add(IdleHandlerParameters);
	BackgroundJobParameters.Add(SplashForm);
	BackgroundJobParameters.Add(KeyDescription);
		
	// Start timer waiting input handler to be completed.
	Return ResultProcessingLongAction(FormOwner, KeyParameters);
	
EndFunction

// Check job status and returns job data.
//
// Parameters:
//  FormOwner     - ManagedForm - Reference of owner form, responsible for long action.
// 	KeyParameters - Structure - Parameters for background job "CommonUse.DoLongAction".  
//
// Returns:
//  FixedArray - Data from background job "CommonUse.DoLongAction",
//  String     - Describing an error if failed,
//  UUID       - ID of background job if operation pending,
//  Undefined  - User cancels the operation.
//
Function ResultProcessingLongAction(FormOwner, KeyParameters = Undefined) Export
	
	// Request current background job parameters.
	Try
		// Access to the background parameters in the form.
		BackgroundJobParameters = FormOwner.BackgroundJobParameters;
		If Not ValueIsFilled(BackgroundJobParameters) Then
			// Cancel next processing.
			Return Undefined;
		EndIf;
	Except
		// Error reading data from form storage.
		Return Undefined;
	EndTry;
	
	// Read job parameters.
	JobID                   = BackgroundJobParameters[0].Value;
	StorageAddress          = BackgroundJobParameters[1].Value;
	IdleHandlerParameters   = BackgroundJobParameters[2].Value;
	SplashForm              = BackgroundJobParameters[3].Value;
	KeyDescription          = BackgroundJobParameters[4].Value;
	
	// Check current job status.
	ResultDescription = CommonUseServerCall.CheckLongAction(JobID, KeyParameters, StorageAddress);
	
	// Check execution result.
	If ResultDescription.Description = "Completed" Then // Successfully completed.
		// Close splash form.
		LongActionsClient.CloseLongActionForm(BackgroundJobParameters[3].Value);
		
		// Get data from background job.
		Result = ResultDescription.Result;
		
	ElsIf ResultDescription.Description = "Failed" Then // Exception occured.
		// Close splash form.
		LongActionsClient.CloseLongActionForm(BackgroundJobParameters[3].Value);
		
		// Get empty object or error description.
		Result = ResultDescription.Result;
		
	ElsIf ResultDescription.Description = "Pending" Then
		// Get running job ID.
		If ResultDescription.Result <> JobID Then
			// New job ID assigned.
			JobID = ResultDescription.Result;
			BackgroundJobParameters[0].Value = JobID;
		EndIf;
		
		// Open splash form displaying waiting message (if not previously opened).
		If SplashForm = Undefined Then
			// Define user messages.
			SplashFormHeader  = KeyDescription;
			SplashFormMessage = NStr("en = 'Processing has been started.
			                               |Please wait...'");
			// Show splash form.
			BackgroundJobParameters[3].Value = LongActionsClient.OpenLongActionForm(FormOwner, JobID, SplashFormHeader, SplashFormMessage);
		EndIf;
		
		// Reattach form idle handler.
		FormOwner.AttachIdleHandler("IdleHandlerLongAction", IdleHandlerParameters.CurrentInterval, True);
		
		// Update idle handler parameters (how long to wait before next check).
		LongActionsClient.UpdateIdleHandlerParameters(BackgroundJobParameters[2].Value);
		
		// Set Job ID as result.
		Result = ResultDescription.Result;
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

Procedure ApplyPrintFormSettingsOnSettingsChange(Result, Parameters) Export
	
	If TypeOf(Result) = Type("DialogReturnCode") Then
		If Result <> DialogReturnCode.OK Then
			return;
		EndIf;
	EndIf;
	If TypeOf(Result) = Type("String") Then
		If Result <> "PrintReport" Then
			return;
		EndIf;
	EndIf;
	
	ResultDocument		= Parameters.SourceForm.Result;
	PrintFormSettings = ApplyPrintFormSettings(ResultDocument,Parameters, False);
		
	If TypeOf(Result) = Type("String") Then
		If Result = "PrintReport" Then
			ResultDocument.Print(PrintDialogUseMode.Use);
		EndIf;
	EndIf;
	
EndProcedure

Function ApplyPrintFormSettings(ResultDocument, Parameters, ProcessObjectTypeID = True) Export
	
	If ProcessObjectTypeID Then
		ObjectTypeID = GetObjectTypeID(Parameters.ObjectTypeID);
	Else
		ObjectTypeID = Parameters.ObjectTypeID;
	EndIf;
	PrintFormSettings 	= PrintFormFunctions.GetPrintFormSettings(ObjectTypeID);
	FillPropertyValues(ResultDocument, PrintFormSettings);
	ResultDocument.PageOrientation = ?(PrintFormSettings.PrintPageOrientation = 0, PageOrientation.Portrait, PageOrientation.Landscape);
	Return PrintFormSettings;
	
EndFunction

Function GetObjectTypeID(Val ReportFormName) Export
	
	If StrFind(ReportFormName, "Report.") > 0 Then
		ReportFormName	= StrReplace(ReportFormName, "Report.", "");
		DotPos			= StrFind(ReportFormName, ".");
		ReportFormName	= "Report." + Left(ReportFormName, ?(DotPos=0, DotPos, DotPos-1));
	EndIf;
	return ReportFormName;

EndFunction

Procedure Transactions(ObjectRef, FormParameters = Undefined) Export
	
	// Open transactions form with selected filter.
	If FormParameters = Undefined Then
		FormParameters = New Structure();
		FormParameters.Insert("Source", ObjectRef);
	EndIf;
	NewFormType = CommonUseServerCall.GetConstantValue("UseExtendedTransactionsRepresentation");
	//NewFormType = True;
	OpenForm(?(NewFormType=True,"CommonForm.OrderTransactions","CommonForm.OrderTransactionsNonExtended"), FormParameters, ObjectRef, ObjectRef.UUID());
	
EndProcedure

