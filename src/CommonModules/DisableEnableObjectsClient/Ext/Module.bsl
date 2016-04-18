
////////////////////////////////////////////////////////////////////////////////
// Disable/Enable Objects: Common client functions
//------------------------------------------------------------------------------
// Available on:
// - Client
//

////////////////////////////////////////////////////////////////////////////////
// Primary functions:
// - manages attribute InArchive;

////////////////////////////////////////////////////////////////////////////////
#Region PUBLIC_INTERFACE

// Procedure manages attribute InArchive in given objects.
//
// Parameters:
//  Objects       - Arbitrary   - reference to object or array of references to objects
//   that have attribute InArchive.
//  SourceForm    - ManagedForm - form where command was called.
//  EstimatedType - Type        - estimated type of objects to exclude incorrect values (group fields in lists and etc.).
//  IsListForm    - Boolean     - if True then SourceForm is list form (or choice form), if False - object form.
//
Procedure DisableEnableObjects(Objects, SourceForm, EstimatedType, IsListForm = True) Export
	
	If TypeOf(Objects) = Type("Array") Then // If Objects is array then copy it to work with copy further.
		ObjectsArray = CommonUseClientServer.CopyArray(Objects);
	Else  // If Objects is single ref then create new Array with this ref.
		ObjectsArray = New Array;
		ObjectsArray.Add(Objects);
	EndIf;
	
	If Not IsListForm And SourceForm.Modified Then // Use command for saved object only.
		ShowMessageBox(,NStr("en = 'Save object first.'")); 
		Return;
	EndIf;
	
	// Calculate value that will be set in objects and check types of objects.
	
	FlagValueToSet  = True; // By default we try to disable objects.
	K               = ObjectsArray.Count();
	While K > 0 Do
		
		K         = K - 1;
		ObjectRef = ObjectsArray[K];
		
		// Check object type.
		If TypeOf(ObjectRef) <> EstimatedType Then // It hase wrong type - remove it.
			ObjectsArray.Delete(K);
			Continue;
		EndIf;
		
		// Object has right type check its current InArchive value.
		If IsListForm Then
			
			If  SourceForm.Items.List.RowData(ObjectRef).InArchive Then
				
				FlagValueToSet = False; // One Object in array is already disabled. Enable all objects.
			EndIf;
		Else
			
			If SourceForm.Object.InArchive Then
				
				FlagValueToSet = False; // Object is already disabled. Enable him.
			EndIf;
		EndIf;
	EndDo;
	
	If ObjectsArray.Count() = 0 Then
		ShowMessageBox(,NStr("en = 'There is no right object selected.'")); 
		Return;
	EndIf;

	
	If FlagValueToSet Then
		TextTemplate = NStr("en = 'Disable %1?'");
	Else
		TextTemplate = NStr("en = 'Enable %1?'");
	EndIf;
	
	If ObjectsArray.Count() = 1 Then
		QueryText = StrTemplate(TextTemplate, NStr("en = 'object '") + ObjectsArray[0]);
	Else
		QueryText = StrTemplate(TextTemplate, NStr("en = 'selected objects'"));
	EndIf;
	
	QueryParameters = New Structure;
	QueryParameters.Insert("Objects"       , ObjectsArray);
	QueryParameters.Insert("FlagValueToSet", FlagValueToSet);
	QueryParameters.Insert("IsListForm"    , IsListForm);
	QueryParameters.Insert("Form"          , SourceForm);
	
	Notify = New NotifyDescription("DisableEnableObjectsEnd", ThisObject, QueryParameters);
	
	ShowQueryBox(Notify, QueryText, QuestionDialogMode.OKCancel); 
	
EndProcedure

Procedure DisableEnableObjectsEnd(Answer, Parameters) Export
	
	If Answer = DialogReturnCode.Cancel Then
		Return;
	EndIf;
	
	DisableEnableObjectsServerCall.DisableEnableCommandServer(Parameters.Objects, Parameters.FlagValueToSet);
	
	If Parameters.IsListForm Then
		Parameters.Form.Items.List.Refresh(); // Refresh list on source form.
	Else
		Parameters.Form.Read(); // Reread object after change.
		NotifyChanged(Parameters.Objects[0]);
	EndIf;
	
EndProcedure

#EndRegion



