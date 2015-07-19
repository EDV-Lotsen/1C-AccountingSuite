
////////////////////////////////////////////////////////////////////////////////
// Base functionality subsystem.
//------------------------------------------------------------------------------
// Server interface procedures and functions of common use for working with:
// - saving/reading/deleting settings to/from storages.
//

////////////////////////////////////////////////////////////////////////////////
#Region PUBLIC_INTERFACE

// Set default value of setting defined for the passed user.
// Use common settings storage for saving of user settings.
//
// Parameters:
//  Setting   - String    - Setting name.
//  Value     - Arbitrary - Value of setting.
//  User      - String    - User defining setting (current user by default).
//
Procedure SetValueAsDefault(Setting, Value, User = Undefined) Export 

	// Get current setting value.
	CurrentValueByDefault = GetValueByDefault(Setting,, User);
	
	// Check value type and compare old and new value.
	If TypeOf(Value) <> TypeOf(CurrentValueByDefault)
	Or Value <> CurrentValueByDefault Then
		
		// Save new value of setting.
		CommonSettingsStorage.Save(Upper(Setting),, Value,, User);
		
	EndIf;

EndProcedure

// Get default value of setting defined for the passed user.
// Use common settings storage for saving of user settings.
//
// Parameters:
//  Setting   - String    - Setting name.
//  Default   - Arbitrary - Default (or empty) value of the same type as expected.
//                          or Undefined to skip value checking.
//  User      - String    - User for which setting was defined (current user by default).
//
// Returns:
//  Value     - Arbitrary - Value of setting.
//
Function GetValueByDefault(Setting, Default = Undefined, User = Undefined) Export
	
	// Get value from common storage.
	Value = CommonSettingsStorage.Load(Upper(Setting),,, User);
	
	// Check value is properly filled
	If  Default = Undefined Then
		// No value for compare provided: skip value checking.
		Return Value;
		
	ElsIf Value = Undefined                // No value defined for this setting.
	   Or TypeOf(Value) <> TypeOf(Default) // Value defined, but other type than expected.
	Then // Only default value defined.
		
		// Try to use the existing value in the database if only one defined.
		If CommonUse.IsReference(TypeOf(Default)) Then
			
			// Check presence of only one ref othis kind in database.
			OnlyOneRef = CommonUse.RefIfOnlyOne(TypeOf(Default));
			If OnlyOneRef <> Undefined Then
				
				// Save currently found value for the later use.
				CommonSettingsStorage.Save(Upper(Setting),, OnlyOneRef,, User);
				
				// Return set value.
				Return OnlyOneRef;
			EndIf;
		EndIf;
		
		// No proper value found.
		Return Default;
		
	// Both Value and Default are defined.
	ElsIf (Value <> Default) // This is not default (or empty) value (prevents empty search).
	  And (CommonUse.IsReference(TypeOf(Value)))   // This is value of reference type
	  And (Not CommonUse.RefExists(Value)) // And reference actually don't exist.
	Then // Value of proper type saved, but no more exists in the database.
		
		// Broken link found.
		CommonSettingsStorage.Delete(Upper(Setting),, User);
		
		// Try to get value once again.
		Return GetValueByDefault(Setting, Default, User);
		
	Else
		// Value of proper type.
		Return Value;
	EndIf;
	
EndFunction

Function CheckNumberAllowed(Num, Ref, BankAccount) Export
	
	Try
		CheckNum = Number(Num);
	Except
		Return New Structure("DuplicatesFound, Allow", False, True);
	EndTry;
	
	If (CheckNum < 100) Or (CheckNum > 99999999) Then
		Return New Structure("DuplicatesFound, Allow", False, True);
	EndIf;

	Query = New Query("SELECT TOP 1
	                  |	ChecksWithNumber.Number,
	                  |	ChecksWithNumber.Ref,
	                  |	AllowDuplicateCheckNumbers.Value AS AllowDuplicateCheckNumbers
	                  |FROM
	                  |	(SELECT
	                  |		Check.PhysicalCheckNum AS Number,
	                  |		Check.Ref AS Ref
	                  |	FROM
	                  |		Document.Check AS Check
	                  |	WHERE
	                  |		Check.BankAccount = &BankAccount
	                  |		AND Check.PaymentMethod = VALUE(Catalog.PaymentMethods.Check)
	                  |		AND Check.PhysicalCheckNum = &CheckNum
	                  |	
	                  |	UNION ALL
	                  |	
	                  |	SELECT
	                  |		InvoicePayment.PhysicalCheckNum,
	                  |		InvoicePayment.Ref
	                  |	FROM
	                  |		Document.InvoicePayment AS InvoicePayment
	                  |	WHERE
	                  |		InvoicePayment.BankAccount = &BankAccount
	                  |		AND InvoicePayment.PaymentMethod = VALUE(Catalog.PaymentMethods.Check)
	                  |		AND InvoicePayment.PhysicalCheckNum = &CheckNum) AS ChecksWithNumber,
	                  |	Constant.AllowDuplicateCheckNumbers AS AllowDuplicateCheckNumbers
	                  |WHERE
	                  |	ChecksWithNumber.Ref <> &CurrentRef");
	Query.SetParameter("BankAccount", BankAccount);
	Query.SetParameter("CheckNum", CheckNum);
	Query.SetParameter("CurrentRef", Ref);
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Return New Structure("DuplicatesFound, Allow", False, True);
	Else	
		Res = QueryResult.Select();
		Res.Next();
		Return New Structure("DuplicatesFound, Allow", True, Res.AllowDuplicateCheckNumbers);
	EndIf;		
	
EndFunction

#Region LONG_ACTION

// Starting do long action process and then check it.
// Parameters:
//  CurrentJobID   - UUID      - Processing of previously started job for checking it's status,
// 	KeyParameters  - Structure - Parameters for background job "CommonUse.DoLongAction".  
//  StorageAddress - String    - Address in temporary storage where job result should be placed.
//                                  If not specified, then direct call will be used.
//
// Returns:
//  ResultDescription - Structure with following parameters:
//  - Result:
//  	FixedArray    - Data from background job "CommonUse.DoLongAction",
//  	String        - Describing an error if failed,
//  	UUID          - ID of background job if operation pending,
//  	Undefined  	  - User cancels the operation.
//  - Description     - String - Job execution status:
//                      Initializing, Canceled, Completed, Pending or Failed.
//
Function CheckLongAction(Val CurrentJobID, KeyParameters = Undefined, StorageAddress) Export
	
	Try
		// A new long action
		If KeyParameters <> Undefined Then
			
			// Define job parameters.
			JobParameters = New Array;
			JobParameters.Add(KeyParameters);
			JobParameters.Add(StorageAddress);
			
			// Define timeout when the control will be returned to the user.
			If GetClientConnectionSpeed() = ClientConnectionSpeed.Low Then
				Timeout = 2;
			Else
				Timeout = 1;
			EndIf;
			
			// Request long action.
			Job = BackgroundJobs.Execute("CommonUse.DoLongAction", JobParameters,, NStr("en = 'Long action'"));
			
			// Let job to be executed within 1-2 sec.
			Try
				Job.WaitForCompletion(Timeout);
			Except
				// Timeout: Job is now pending.
			EndTry;
			
			// Define job ID for future check of it's status.
			CurrentJobID = Job.UUID;
			
		EndIf;
		
		// Check job execution result.
		If ValueIsFilled(CurrentJobID) And JobCompleted(CurrentJobID) Then
			
			// Job is completed.
			Result = GetFromTempStorage(StorageAddress);
			Return ResultDescription(Result, ?(TypeOf(Result) = Type("Array"), "Completed", "Failed"));
			
		Else
			// Job is started and now pending.
			Return ResultDescription(CurrentJobID, "Pending");
		EndIf;
		
	Except
		// Return error description.
		Return ResultDescription(NStr("en = 'Error of long action:'") + Chars.LF +
		                         GetErrorInfo(ErrorInfo()).Description, "Failed");
	EndTry;
	
EndFunction

#EndRegion

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region PRIVATE_IMPLEMENTATION

// Checks background job state by the passed ID.
//
// Parameters:
//  JobID - UUID - background job ID.
//
// Returns:
//  Boolean - True if the job completed successfully,
//            False - if the job is still executing.
//  In other cases an exception is raised.
//
Function JobCompleted(Val JobID)
	
	Job = BackgroundJobs.FindByUUID(JobID);
	
	If Job <> Undefined
		And Job.State = BackgroundJobState.Active Then
		Return False;
	EndIf;
	
	ActionNotExecuted = True;
	ShowFullErrorText = False;
	
	If Job = Undefined Then
		WriteLogEvent(NStr("en = 'Long actions. Background job is not found'"),
			EventLogLevel.Error,,, String(JobID));
			
	Else
		If Job.State = BackgroundJobState.Failed Then
			JobError = Job.ErrorInfo;
			If JobError <> Undefined Then
				WriteLogEvent(NStr("en = 'Long actions. Background job failed'"),
					EventLogLevel.Error,,,
					DetailErrorDescription(Job.ErrorInfo));
				ShowFullErrorText = True;
			Else
				WriteLogEvent(NStr("en = 'Long actions. Background job failed'"),
					EventLogLevel.Error,,,
					NStr("en = 'The job finished with an unknown error.'"));
			EndIf;
			
		ElsIf Job.State = BackgroundJobState.Canceled Then
			WriteLogEvent(NStr("en = 'Long actions. Administrator canceled background job'"),
				EventLogLevel.Error,,,
				NStr("en = 'The job was canceled.'"));
				
		Else
			Return True;
		EndIf;
	EndIf;
	
	If ShowFullErrorText Then
		ErrorText = BriefErrorDescription(GetErrorInfo(Job.ErrorInfo));
		Raise(ErrorText);
		
	ElsIf ActionNotExecuted Then
		Raise(NStr("en = 'Background job cannot be executed.
		                 |See details in the Event log.'"));
	EndIf;
	
EndFunction

// Returns the structure with passed parameters.
//
// Parameters:
//  Result             - Arbitrary - Returned function value.
//  Description        - String - Success string or error description.
//
// Returns:
//  Structure with the passed parameters:
//   Result            - Arbitrary.
//   Description       - String.
//
Function ResultDescription(Result, Description = "")
	
	// Return parameters converted to the structure
	Return New Structure("Result, Description", Result, Description);
	
EndFunction

// Checks exception info and returns it's cause.
//
// Parameters:
//  ErrorObj - ErrorInfo - Exception description object.
//
// Returns:
//  ErrorObj - Exception cause info.
//
Function GetErrorInfo(ErrorObj)
	
	// Get exception cause.
	If TypeOf(ErrorObj) = Type("ErrorInfo") Then
		While TypeOf(ErrorObj.Cause) = Type("ErrorInfo") Do
			ErrorObj = ErrorObj.Cause;
		EndDo;
	EndIf;
	
	// Return found cause.
	Return ErrorObj;
	
EndFunction

#EndRegion