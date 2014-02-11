
////////////////////////////////////////////////////////////////////////////////
// Stripe API: Client
//------------------------------------------------------------------------------
// Available on:
// - Client (managed application)
//

////////////////////////////////////////////////////////////////////////////////
#Region PUBLIC_INTERFACE

//------------------------------------------------------------------------------
// Secret key input functions

// Request secure key data and calls encoding of the data.
//
// Parameters:
//  KeyDescription - String - Demonstartes description of entering key in string entry dialog.
//  FormOwner      - ManagedForm - Reference of owner form, responsible for key encode request.
//  FormItem       - String - Name of form item, requesting input of secret key.
//
// Returns:
//  FixedArray - Encoded key data for saving in database:
//  - [0] PublicHeader - String - Public header of saved key,
//  - [1] HUID - UUID  - Encoded key data,
//  - [2] LUID - UUID  - Encoded key data,
//  String     - Describing an error if failed,
//  UUID       - ID of background job if operation pending,
//  Undefined  - User cancels the operation.
//
Function SecureInputKey(KeyDescription, FormOwner, FormItem) Export
	Var KeyText;
	
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
	BackgroundJobParameters.Add(FormItem);
	BackgroundJobParameters.Add(KeyDescription);
	
	// Create a text description to input dialog.
	Header = StringFunctionsClientServer.SubstituteParametersInString(NStr("en = 'Input %1:'"), Lower(KeyDescription));
	
	// Define input handler and invoke string input.
	#If WebClient Then
		InputProcessing = New NotifyDescription("SecureInputKeyInputProcessing", ThisObject, StorageAddress);
	#Else
		InputProcessing = New NotifyDescription("EncodeSecretKey", ApiStripeProtectedServerCall, StorageAddress);
	#EndIf
	ShowInputString(InputProcessing, KeyText, Header);
	
	// Start timer waiting input handler to be completed.
	Return SecureInputKeyResultProcessing(FormOwner);
	
EndFunction

// Process the user input of secret key (for web-client only)
// Parameters:
//  KeyText           - String    - Specifies API key to encode.
//                    - Undefined - Processing of cancelled user input.
//  StorageAddress    - String    - Address in temporary storage where job result should be placed.
//                                  If not specified, then direct call will be used.
//
// Returns:
//  ResultDescription - Structure with following parameters:
//  - Result:
//     if job completed:
//      Fixed Array:
//       PublicHeader - String, Public header of encoded secret key.
//       HUID, LUID   - UUID,   Encoded hex code for saving in database.
//     else if user currently entering the secret key:
//      UUID          - Empty UUID.
//     else if job is now pending then UUID:
//      UUID          - UUID of pending job.
//     else if user cancelled user input:
//      Undefined     - Undefined.
//     else if error or exception occured:
//      String        - Error description.
//  - Description     - String - Job execution status:
//                      Initializing, Canceled, Completed, Pending or Failed.
//
Function SecureInputKeyInputProcessing(KeyText, StorageAddress = Undefined) Export
	
	// Redirect client call to server (for web-client only)
	Return ApiStripeProtectedServerCall.EncodeSecretKey(KeyText, StorageAddress);
	
EndFunction

// Check job status and returns job data.
//
// Parameters:
//  FormOwner  - ManagedForm - Reference of owner form, responsible for key encode request.
//
// Returns:
//  FixedArray - Encoded key data for saving in database:
//  - [0] PublicHeader - String - Public header of saved key,
//  - [1] HUID - UUID  - Encoded key data,
//  - [2] LUID - UUID  - Encoded key data,
//  String     - Describing an error if failed,
//  UUID       - ID of background job if operation pending,
//  Undefined  - User cancels the operation.
//
Function SecureInputKeyResultProcessing(FormOwner) Export
	
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
	FormItem                = BackgroundJobParameters[4].Value;
	KeyDescription          = BackgroundJobParameters[5].Value;
	
	// Check current job status.
	ResultDescription = ApiStripeProtectedServerCall.EncodeSecretKey(JobID, StorageAddress);
	
	// Check execution result.
	If ResultDescription.Description = "Initializing" Then // Job is not yet started.
		// Define input waiting interval.
		CurrentInterval = 1; // max 1 sec. after input will be closed.
		
		// Wailting for background job to be started.
		FormOwner.AttachIdleHandler("SecretKeyEncoding", CurrentInterval, True);
		
		// Set Job ID as result.
		Result = ResultDescription.Result;
		
	ElsIf ResultDescription.Description = "Canceled" Then // Job canceled by the user.
		// Transfer default value.
		Result = ResultDescription.Result;
		
	ElsIf ResultDescription.Description = "Completed" Then // Successfully completed.
		// Close splash form.
		LongActionsClient.CloseLongActionForm(BackgroundJobParameters[3].Value);
		
		// Get encoding key data.
		Result = ResultDescription.Result;
		
	ElsIf ResultDescription.Description = "Failed" Then // Exception occured.
		// Close splash form.
		LongActionsClient.CloseLongActionForm(BackgroundJobParameters[3].Value);
		
		// Get empty object or error description.
		Result = ResultDescription.Result;
		
		// Check failed cause.
		If Result = Undefined Then // Key is not encrypted due to optimization.
			// Define user query messages.
			RetryQueryHeader  = StringFunctionsClientServer.SubstituteParametersInString(
			                    NStr("en = 'Input %1'"), Lower(KeyDescription));
			RetryQueryMessage = StringFunctionsClientServer.SubstituteParametersInString(
			                    NStr("en = 'Cannot create the encoded key for the specified string.
			                               |This can occur due to the time optimization of the encryption algorithm.
			                               |Would you like to retry the input of the %1?'"), Lower(KeyDescription));
			
			// Define query retry parameters.
			AdditionalParameters = New Structure("KeyDescription, FormOwner, FormItem",
			                                      KeyDescription, FormOwner, FormItem);
			// Ask user to retry.
			RetryQueryProcessing = New NotifyDescription("SecureInputKeyResultProcessingRetry", ThisObject, AdditionalParameters);
			ShowQueryBox(RetryQueryProcessing, RetryQueryMessage, QuestionDialogMode.RetryCancel,, DialogReturnCode.Retry, RetryQueryHeader);
			
			// Define empty Job ID. It will not be processed at client side.
			Result = New UUID("00000000-0000-0000-0000-000000000000");
			
		// Error ocured during encoding.
		Else
			// Result contains error description.
		EndIf;
		
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
			SplashFormHeader  = StringFunctionsClientServer.SubstituteParametersInString(
			                    NStr("en = 'Encrypting %1'"),  Lower(KeyDescription));
			SplashFormMessage = StringFunctionsClientServer.SubstituteParametersInString(
			                    NStr("en = 'The %1 is being encrypted.
			                               |Please wait...'"), Lower(KeyDescription));
			// Show splash form.
			BackgroundJobParameters[3].Value = LongActionsClient.OpenLongActionForm(FormOwner, JobID, SplashFormHeader, SplashFormMessage);
		EndIf;
		
		// Reattach form idle handler.
		FormOwner.AttachIdleHandler("SecretKeyEncoding", IdleHandlerParameters.CurrentInterval, True);
		
		// Update idle handler parameters (how long to wait before next check).
		LongActionsClient.UpdateIdleHandlerParameters(BackgroundJobParameters[2].Value);
		
		// Set Job ID as result.
		Result = ResultDescription.Result;
	EndIf;
	
	Return Result;
	
EndFunction

// Process retry query result processing.
//
// Parameters:
//  QueryResult          - DialogReturnCode - Retry or Cancel.
//  AdditionalParameters - Structure - Encoding retry parameters:
//                         KeyDescription, FormOwner, FormItem.
//
Function SecureInputKeyResultProcessingRetry(QueryResult, AdditionalParameters) Export
	
	// Check user query result.
	If QueryResult = DialogReturnCode.Retry Then
		// Restore passed retry parameters.
		KeyDescription = AdditionalParameters.KeyDescription;
		FormOwner      = AdditionalParameters.FormOwner;
		FormItem       = AdditionalParameters.FormItem;
		
		// Retry key encoding.
		SecureInputKey(KeyDescription, FormOwner, FormItem);
		
	// Cancel secret key encoding.
	Else
		// Restore passed retry parameters.
		KeyDescription = AdditionalParameters.KeyDescription;
		
		// Create user message.
		Header = StringFunctionsClientServer.SubstituteParametersInString(
		         NStr("en = 'Encoding %1:'"), Lower(KeyDescription));
		Result = StringFunctionsClientServer.SubstituteParametersInString(
		         NStr("en = 'Encoding of %1 has been cancelled.'"), Lower(KeyDescription));
		
		ShowMessageBox(Undefined,Result,,Header);
	EndIf;
	
EndFunction

#EndRegion
