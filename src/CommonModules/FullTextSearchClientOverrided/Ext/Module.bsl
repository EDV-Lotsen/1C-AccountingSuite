

// Called on object open from full-text search
// Function OnObjectOpen allows to configure
// behaviour when result being opened from the list of information found in full-text serach
// For example, this is required when using subsystem "Business-processes and tasks".
//
// Parameters
//  Value - object, found in full-text search, for example CatalogRef
//  StandardProcessing - Boolean - by default True.
//   If posting has been changed (manually open form for Value),
//   then StandardProcessing assign to False
//
// When using subsystem "Business-processes and tasks" need
// to insert following code:
//
//If TypeOf(Value) = Type("TaskRef.ExecutorTask") Then
//	If BusinessProcessesAndTasksClient.OpenTaskExecutionForm(Value) Then
//		StandardProcessing = False;
//	EndIf;
//EndIf;
//
Procedure OnObjectOpen(Value, StandardProcessing) Export
	
EndProcedure
