
// Data processor description
// Tabular section Operations - contains information set, describing the changes.
// One record describes one change.
// Attributes of tabular section:
//		OperationKind - number - tells us WHAT to do:
//								 1 - attribute change
//								 2 - additional attribute change
//								 3 - additional property change
//		AttributeName - string - name of modified attribute (operation type = 1)
//		Property	  - CCT - ref to modified property (operation type = 2 or 3)
//		Presentation  - string - operation presentation for user,
//					    on OperationKind = 1 - attribute synonym
//					    on OperationKind - 2 and 3 - property description
//		Change        - Boolean - indicator showing that operation must be executed
//					    the only way to clear values
//		Value         - new value
//		BlockedAttribute - Boolean - this is a locked attribute
//		ValidTypes       - String - contains enumeration of type names (via ";")
//

Var	NoErrors,
		Error_NotClassified,			// install, if cannot determine exact reason
		Error_FillCheckProcessing,		// happens, if fillcheck processing returned cancel
		Error_ObjectWrite,				// happens, if during object write exception has been raised
		Error_ObjectLock,				// happens on object lock attempt
		Error_AdditionalDataWrite;   	// happens on attempt to write additional data 

Var AdditionalDataAndAttributesManagementModule;

// Procedure fills object operation table:
// 1. Attributes
// 2. Properties
//
Procedure FillTableOfOperationsWithObject() Export
	
	Var InUseBanEditAttributes;
		
	FirstBeingChanged = ObjectsForChange[0].Ref;
	
	MetadataObject = FirstBeingChanged.Metadata();
	
	// Get object manager for obtaining the arrays of not-edited interactively
	// and locked attributes
	ObjectManager = CommonUse.ObjectManagerByFullName(MetadataObject.FullName());
	
	LockableAttributes = New Array;
	
	NotEditable = New Array;
	
	FilterableAttributes = GetEditFilterByType(MetadataObject);
	
	//////////////////////////////////////////////////////////////////////////////////////////
	// Filteration by disabled functional options
	
	ClosedFunctionalOptions = New ValueTable;
	ClosedFunctionalOptions.Columns.Add("AttributeName",  New TypeDescription("String"));
	
	For Each FODescription In Metadata.FunctionalOptions Do
		
		If StringFunctionsClientServer.DecomposeStringIntoSubstringsArray(FODescription.Location.FullName(), ".")[0] <> "Constant" Then
			Continue;
		EndIf;
		ValueOfFO = GetFunctionalOption(FODescription.Name);
		
		If TypeOf(ValueOfFO) <> Type("Boolean") Then
			Continue;
		EndIf;
		
		If ValueOfFO Then
			Continue;
		EndIf;
		
		For Each AttributeMO In MetadataObject.Attributes Do
			If FODescription.Content.Contains(AttributeMO) Then
				NewRow = ClosedFunctionalOptions.Add();
				NewRow.AttributeName = AttributeMO.Name;
			EndIf;
		EndDo;
	EndDo;
	
	ClosedFunctionalOptions.GroupBy("AttributeName");
	
	For Each ClosedFO In ClosedFunctionalOptions Do
		FilterableAttributes.Add(ClosedFO.AttributeName);
	EndDo;
	
	// Filteration by disabled functional options
	//////////////////////////////////////////////////////////////////////////////////////////
	
	
	Operations.Clear();
	
	AddAttributesToSet(MetadataObject.StandardAttributes,
							NotEditable,
							FilterableAttributes,
							LockableAttributes);
	
	AddAttributesToSet(MetadataObject.Attributes,
							NotEditable,
							FilterableAttributes,
							LockableAttributes);
	
	Operations.Sort("Presentation Asc");
	
	If AdditionalDataAndAttributesManagementModule <> Undefined Then
		UsedAdditionalAttributes = AdditionalDataAndAttributesManagementModule.UseAdditionalAttributes(ObjectsForChange[0].Ref);
		UsedAdditionalData  = AdditionalDataAndAttributesManagementModule.UseAdditionalData (ObjectsForChange[0].Ref);
		
		If AdditionalDataAndAttributesManagementModule <> Undefined And (UsedAdditionalAttributes OR UsedAdditionalData) Then
			AddAdditionalDataAndAttributesToSet();
		EndIf;
	Else
		UsedAdditionalAttributes = False;
		UsedAdditionalData = False;
	EndIf;
	
EndProcedure

// Performs modification in objects
//
// Parameters:
//   ObjectsArray 			- array of refs, subset (or complet set)
//							  of refs from ObjectsForChange, optional
// TransactionManagement 	- boolean - used by function during recursive call so,
//							  that trancaction would not be set (do not complete)
//
Function RunChangeOfObjects(ProcessedObjects = Undefined,
									Val StopUpdateOnError = Undefined) Export
	
	ChangeResult = 	New Structure("AreErrors, DataProcessorStatus");
	ChangeResult.AreErrors				= False;
	ChangeResult.DataProcessorStatus	= New Map;
	
	If StopUpdateOnError = Undefined Then
		StopUpdateOnError = AbortOnError;
	EndIf;
	
	If ProcessedObjects = Undefined Then
		ProcessedObjects = New Array;
		For Each StringEditedObject In ObjectsForChange Do
			ProcessedObjects.Add(StringEditedObject.Ref);
		EndDo;
	EndIf;
	
	CheckForGroup = CheckForGroup(ProcessedObjects[0]);
	
	If ChangeInTransaction Then
		BeginTransaction(DataLockControlMode.Managed);
	EndIf;
	
	ChangeOperation = Operations.FindRows(New Structure("Change", True));
	
	For Each Ref In ProcessedObjects Do
		
		ObjectBeingEdited = Ref.GetObject();
		
		Try
			LockDataForEdit(ObjectBeingEdited.Ref);
		Except
			InfoInfo = ErrorInfo();
			BriefErrorDescription = BriefErrorDescription(InfoInfo);
			FillResultOfChanges(ChangeResult, Ref, Error_ObjectLock, BriefErrorDescription);
			If ChangeInTransaction Then
				RollbackTransaction();
				Return ChangeResult;
			EndIf;
			If StopUpdateOnError Then
				Return ChangeResult;
			EndIf;
			Continue;
		EndTry;
		
		EditableObjectAttributes 		= New Array;
		EditableAdditObjectAttributes 	= New Map;
		EditableAdditObjectInfo 		= New Map;
		
		ArrayRecordsAdditInformation 	= New Array;
		
		///////////////////////////////////////////////////////////////////////////////////////
		// Filter of change operations by each object
		//
		
		For Each Operation In ChangeOperation Do
			
			If Operation.OperationKind = 1 Then // attribute change
				
				// do not set attributes for the groups, which do not have these attributes
				If CheckForGroup And ObjectBeingEdited.IsFolder Then
					ThisIsStandardAttribute = False;
					For Each StandardAttributeDescription In ObjectBeingEdited.Metadata().StandardAttributes Do
						If StandardAttributeDescription.Name = Operation.AttributeName Then
							ThisIsStandardAttribute = True;
						EndIf;
					EndDo;
					If NOT ThisIsStandardAttribute Then
						Continue;
					EndIf;
				EndIf;
				
				ObjectBeingEdited[Operation.AttributeName] = Operation.Value;
				EditableObjectAttributes.Add(Operation.AttributeName);
				
			ElsIf Operation.OperationKind = 2 Then // change addit attribute
				
				If Not PropertyNeedToChange(ObjectBeingEdited.Ref, Operation.Property) Then
					Continue;
				EndIf;
				
				StringFound = ObjectBeingEdited.AdditionalAttributes.Find(Operation.Property, "Property");
				
				If StringFound = Undefined Then
					StringFound = ObjectBeingEdited.AdditionalAttributes.Add();
					StringFound.Property = Operation.Property;
				EndIf;
				
				StringFound.Value = Operation.Value;
				
				FormAttributeName = PrefixOfNameOfAdditAttribute() + StrReplace(String(Operation.Property.UUID()), "-", "_");
				EditableAdditObjectAttributes.Insert(FormAttributeName, Operation.Value);
				
			ElsIf Operation.OperationKind = 3 Then // change addit information
				
				//If Not PropertyNeedToChange(ObjectBeingEdited.Ref, Operation.Property) Then
				//	Continue;
				//EndIf;
				//
				//RecordManager = InformationRegisters.AdditionalData.CreateRecordManager();
				//
				//RecordManager.Object = ObjectBeingEdited.Ref;
				//RecordManager.Property = Operation.Property;
				//RecordManager.Value = Operation.Value;
				//
				//ArrayRecordsAdditInformation.Add(RecordManager);
				//
				//FormAttributeName = PrefixOfNameOfAdditInfo() + StrReplace(String(Operation.Property.UUID()), "-", "_");
				//EditableAdditObjectInfo.Insert(FormAttributeName, Operation.Value);
				
			EndIf;
			
		EndDo; // For Each Operation In ChangeOperation Do
		
		//
		// Filter of change operations by each object
		///////////////////////////////////////////////////////////////////////////////////////
		
		///////////////////////////////////////////////////////////////////////////////////////
		// Block of fillcheck processing
		//
		
		AbortChange = False;
		FillCheckSuccessfull = True;
		
		Try
			If ObjectBeingEdited.FillCheck() Then
				
			Else
				FillResultOfChanges(ChangeResult, Ref, Error_FillCheckProcessing,
						NStr("en = 'Check fill error.'")+GetStringOfMessagesAboutErrors());
				If StopUpdateOnError Or ChangeInTransaction Then
					AbortChange = True;
				EndIf;
				FillCheckSuccessfull = False;
			EndIf;
		Except
			InfoInfo = ErrorInfo();
			BriefErrorDescription = BriefErrorDescription(InfoInfo);
			FillResultOfChanges(ChangeResult, Ref, Error_NotClassified, BriefErrorDescription);
			If StopUpdateOnError Or ChangeInTransaction Then
				AbortChange = True;
			EndIf;
			FillCheckSuccessfull = False;
		EndTry;
		
		If AbortChange Then
			If ChangeInTransaction Then
				RollbackTransaction();
			EndIf;
			
			Return ChangeResult;
		EndIf;
		
		If NOT FillCheckSuccessfull Then
			Continue;
		EndIf;
		
		//
		// Block of fillcheck processing
		///////////////////////////////////////////////////////////////////////////////////////
		
		///////////////////////////////////////////////////////////////////////////////////////
		// Block of additional data write
		//
		
		If ArrayRecordsAdditInformation.Count() > 0 Then
			
			If NOT ChangeInTransaction Then
				// If transaction is not used on change of objects - enable it
				// for modification of addit information in register
				BeginTransaction(DataLockControlMode.Managed);
			EndIf;
			
			Try
				For Each RecordManager In ArrayRecordsAdditInformation Do
					RecordManager.Write(True);
				EndDo;
			Except
				InfoInfo = ErrorInfo();
				
				BriefErrorDescription = BriefErrorDescription(InfoInfo);
				FillResultOfChanges(ChangeResult, Ref, Error_AdditionalDataWrite, BriefErrorDescription);
				
				RollbackTransaction();
				
				If ChangeInTransaction OR StopUpdateOnError Then
					Return ChangeResult;
				EndIf;
			EndTry;
			
		EndIf;
		
		//
		// Block of additional data write
		///////////////////////////////////////////////////////////////////////////////////////
		
		Try
			ObjectBeingEdited.Write();
		Except
			InfoInfo = ErrorInfo();
			Cancellation = True;
			BriefErrorDescription = BriefErrorDescription(InfoInfo);
			FillResultOfChanges(ChangeResult, Ref, 
							Error_ObjectWrite,
							BriefErrorDescription + Chars.LF + GetStringOfMessagesAboutErrors());
			If ChangeInTransaction Then // cancel transaction at any recursion level
				RollbackTransaction();
			EndIf;
			If AbortOnError Then
				Return ChangeResult;
			EndIf;
		EndTry;
		
		// Fix transaction of writing addit. properties if objects are being written
		// outside the transaction
		If NOT ChangeInTransaction And ArrayRecordsAdditInformation.Count() > 0 Then
			CommitTransaction();
		EndIf;
		
		FillResultOfChanges(ChangeResult, Ref, NoErrors,, 
					ObjectBeingEdited, EditableObjectAttributes,
					EditableAdditObjectAttributes, EditableAdditObjectInfo);
		
		UnlockDataForEdit(ObjectBeingEdited.Ref);
		
	EndDo;
	
	If ChangeInTransaction Then
		CommitTransaction();
	EndIf;
	
	Return ChangeResult;
	
EndFunction

///////////////////////////////////////////////////////////////////////////////
// Block of service functions and procedures

Function PropertyNeedToChange(Ref, Property)
	
	If AdditionalDataAndAttributesManagementModule = Undefined Then
		Return False;
	EndIf;
	
	//StringOfEditedObject = ObjectsForChange.Find(Ref, "Ref");
	//
	//If StringOfEditedObject = Undefined Then
	//	If NOT AdditionalDataAndAttributesManagementModule.ObjectPropertyExists(Ref, Property) Then
	//		Return False;
	//	EndIf;
	//Else
	//	PropertyIsNotFound = False;
	//	
	//	If Property.IsAdditionalData Then
	//		CollectionOfProperties = StringOfEditedObject.AdditInformationContent;
	//	Else
	//		CollectionOfProperties = StringOfEditedObject.ContentOfAdditAttributes;
	//	EndIf;
	//	
	//	If IsBlankString(CollectionOfProperties) Then
	//		Return False;
	//	EndIf;
	//	
	//	For RowIndex = 1 To StrLineCount(CollectionOfProperties) Do
	//		StringUId = StrGetLine(CollectionOfProperties, RowIndex);
	//		PropertiesOf_Object = ChartsOfCharacteristicTypes.AdditionalDataAndAttributes.GetRef(New UUID(TrimAll(StringUId)));
	//		If Property = PropertiesOf_Object Then // object has a property
	//			PropertyIsNotFound = True;
	//			Break;
	//		EndIf;
	//	EndDo;
	//	
	//	If Not PropertyIsNotFound Then
	//		Return False;
	//	EndIf;
	//	
	//EndIf;
	
	Return True;
	
EndFunction

Function GetStringOfMessagesAboutErrors()
	
	ErrorPresentation = "";
	ArrayOfMessages = GetUserMessages(True);
	
	For Each UserMessage In ArrayOfMessages Do
		ErrorPresentation = ErrorPresentation + UserMessage.Text + Chars.LF;
	EndDo;
	
	Return ErrorPresentation;
	
EndFunction

Procedure FillResultOfChanges(Result, Ref, ErrorCode, ErrorMessage = "",
		ObjectBeingEdited = Undefined, EditableObjectAttributes = Undefined,
		EditableAdditObjectAttributes = Undefined, EditableAdditObjectInfo = Undefined)
	
	ChangeStatus = New Structure("ErrorCode,ErrorMessage");
	
	If ErrorCode = NoErrors Then
		ChangeStatus.Insert("ValuesOfModifiedAttributes", New Map);
		If EditableObjectAttributes <> Undefined Then
			For Each AttributeName In EditableObjectAttributes Do
				ChangeStatus.ValuesOfModifiedAttributes.Insert(AttributeName, ObjectBeingEdited[AttributeName]);
			EndDo;
		EndIf;
		ChangeStatus.Insert("ValuesOfModifiedAdditAttributes", EditableAdditObjectAttributes);
		ChangeStatus.Insert("ValuesOfModifiedAdditInformation", EditableAdditObjectInfo);
	Else
		Result.AreErrors = True;
	EndIf;
	
	ChangeStatus.ErrorCode = ErrorCode;
	ChangeStatus.ErrorMessage = ErrorMessage;
	
	Result.DataProcessorStatus.Insert(Ref, ChangeStatus);
	
EndProcedure

Function PrefixOfNameOfAdditAttribute()
	Return "AdditAttribute_";
EndFunction

Function CheckForGroup(Ref)
	
	ObjectKind = CommonUse.ObjectClassByRef(Ref);
	ObjectMetadata = Ref.Metadata();
	
	If ObjectKind = "Catalog"
	   And ObjectMetadata.Hierarchical
	   And ObjectMetadata.HierarchyType = Metadata.ObjectProperties.HierarchyType.HierarchyFoldersAndItems Then
		
		Return True;
		
	EndIf;
	
	Return False;
	
EndFunction

Procedure AddAdditionalDataAndAttributesToSet()
	
	AdditionalAttributesTable = New ValueTable;
	AdditionalAttributesTable.Columns.Add("Property",  	New TypeDescription("ChartOfCharacteristicTypesRef.AdditionalDataAndAttributes"));
	AdditionalAttributesTable.Columns.Add("Description",  	New TypeDescription("String"));
	AdditionalAttributesTable.Columns.Add("ValueType",  	New TypeDescription("TypeDescription"));
	
	AdditionalDataTable = New ValueTable;
	AdditionalDataTable.Columns.Add("Property",  	New TypeDescription("ChartOfCharacteristicTypesRef.AdditionalDataAndAttributes"));
	AdditionalDataTable.Columns.Add("Description",  New TypeDescription("String"));
	AdditionalDataTable.Columns.Add("ValueType",  	New TypeDescription("TypeDescription"));
	
	For Each ObjectForChange In ObjectsForChange Do
		
		ObjectClassByRef = CommonUse.ObjectClassByRef(ObjectForChange.Ref);
		If (ObjectClassByRef = "Catalog" OR ObjectClassByRef = "ChartOfCharacteristicTypes")
		   And CommonUse.ObjectIsFolder(ObjectForChange.Ref) Then
			Continue;
		EndIf;
		
			AdditAttributes = AdditionalDataAndAttributesManagementModule.GetPropertiesList(ObjectForChange.Ref, , False);
			
			For Each PropertyRef In AdditAttributes Do
				ObjectForChange.ContentOfAdditAttributes = ObjectForChange.ContentOfAdditAttributes + String(PropertyRef.UUID()) + Chars.LF;
				NewRow = AdditionalAttributesTable.Add();
				
				ObjectProperty = PropertyRef.GetObject();
				
				NewRow.Property	= ObjectProperty.Ref;;
				NewRow.Description= ObjectProperty.Description;
				NewRow.ValueType	= ObjectProperty.ValueType;
			EndDo;
			
			AdditInfo1 = AdditionalDataAndAttributesManagementModule.GetPropertiesList(ObjectForChange.Ref, False);
			
			For Each PropertyRef In AdditInfo1 Do
				ObjectForChange.AdditInformationContent = ObjectForChange.AdditInformationContent + String(PropertyRef.UUID()) + Chars.LF;
				NewRow = AdditionalDataTable.Add();
				
				ObjectProperty = PropertyRef.GetObject();
				
				NewRow.Property	= ObjectProperty.Ref;;
				NewRow.Description= ObjectProperty.Description;
				NewRow.ValueType	= ObjectProperty.ValueType;
			EndDo;
		
	EndDo;
	
	AdditionalAttributesTable.GroupBy("Property,Description,ValueType");
	AdditionalAttributesTable.Sort("Description Asc");
	AdditionalDataTable.GroupBy("Property,Description,ValueType");
	AdditionalDataTable.Sort("Description Asc");
	
	AddPropertyToTableOfOperations(AdditionalAttributesTable);
	AddPropertyToTableOfOperations(AdditionalDataTable, False);
	
EndProcedure

Procedure AddPropertyToTableOfOperations(TableOfAdditProperties, ThisIsAdditAttribute = True)
	
	For Each TableRow In TableOfAdditProperties Do
		NewOperation = Operations.Add();
		NewOperation.OperationKind = ?(ThisIsAdditAttribute, 2, 3);
		
		NewOperation.Property		= TableRow.Property;
		NewOperation.Presentation 	= TableRow.Description;
		
		ValidTypesString = "";
		
		For Each Type In TableRow.ValueType.Types() Do 
			TypePresentation = CommonUse.GetStringPresentationOfType(Type);
			ValidTypesString = TypePresentation + ";" + ValidTypesString;
		EndDo;
		
		ValidTypesString = Left(ValidTypesString, StrLen(ValidTypesString)-1);
		
		NewOperation.ValidTypes = ValidTypesString;
	
	EndDo;
	
EndProcedure

// Adds to operation set (in fact is a set of attributes and properties) those ones,
// that could be edited
// It does not contain:
//  not edited operations - depend on settings of metadata object itself
//  filtered - are set for metadata object class
// It contains with exception:
//  LockableAttributes - attributes, that could be edited
//  only when user is in role EditObjectDetails
// Parameters passed:
// Attributes - collection of attributes (standard attributes) of metadata object
// NotEditable, FilterableAttributes - array - filter by attributes
// LockableAttributes - array - attributes being locked
//
Procedure AddAttributesToSet(Attributes,
								NotEditable,
								FilterableAttributes,
								LockableAttributes)
	
	For Each AttributeDetails In Attributes Do
	
		If TypeOf(AttributeDetails) = Type("StandardAttributeDescription") Then
			If NOT AccessRight("Edit", ObjectsForChange[0].Ref.Metadata(), , AttributeDetails.Name) Then
				Continue;
			EndIf;
		Else
			If NOT AccessRight("Edit", AttributeDetails) Then
				Continue;
			EndIf;
		EndIf;
		
		If NotEditable.Find(AttributeDetails.Name) <> Undefined Then
			Continue;
		EndIf;
		
		If FilterableAttributes.Find(AttributeDetails.Name) <> Undefined Then
			Continue;
		EndIf;
		
		ChoiceFoldersAndItems = "";
		
		If TypeOf(AttributeDetails) = Type("StandardAttributeDescription")
		   And (AttributeDetails.Name = "Parent" OR AttributeDetails.Name = "Parent") Then
			ChoiceFoldersAndItems = "Folders";
		Else
			IsReferentialType = False;
			For Each Type In AttributeDetails.Type.Types() Do
				If CommonUse.IsReferentialType(Type) Then
					IsReferentialType = True;
					Break;
				EndIf;
			EndDo;
			If IsReferentialType Then
				If AttributeDetails.ChoiceFoldersAndItems = FoldersAndItemsUse.Folders Then
					ChoiceFoldersAndItems = "Folders";
				ElsIf AttributeDetails.ChoiceFoldersAndItems = FoldersAndItemsUse.FoldersAndItems Then
					ChoiceFoldersAndItems = "FoldersAndItems";
				ElsIf AttributeDetails.ChoiceFoldersAndItems = FoldersAndItemsUse.Items Then
					ChoiceFoldersAndItems = "Items";
				EndIf;
			EndIf;
		EndIf;
		
		// collect attribute types
		ValidTypesString = "";
		
		For Each Type In AttributeDetails.Type.Types() Do
			TypePresentation = CommonUse.GetStringPresentationOfType(Type);
			ValidTypesString = TypePresentation + ";" + ValidTypesString;
		EndDo;
		
		ValidTypesString = Left(ValidTypesString, StrLen(ValidTypesString)-1);
		
		// if there are types available for change - attribute should not be included to the final set
		If IsBlankString(ValidTypesString) Then
			Continue;
		EndIf;
		
		ChoiceParametersString = "";
		
		For Each DescriptionOfChoiceParameter In AttributeDetails.ChoiceParameters Do
			
			CurrentCPString = "[FilterField];[TypeString];[ValueString]";
			
			ValueType = TypeOf(DescriptionOfChoiceParameter.Value);
			
			If ValueType = Type("FixedArray") Then
				
				TypeAsString = "FixedArray";
				ValueString = "";
				
				
				For Each Item In DescriptionOfChoiceParameter.Value Do
					
					ValueStringTemplate = "[Type]%[Value]";
					ValueStringTemplate = StrReplace(ValueStringTemplate, "[Type]", CommonUse.GetStringPresentationOfType(TypeOf(Item)));
					ValueStringTemplate = StrReplace(ValueStringTemplate, "[Value]", XMLString(Item));
					ValueString = ValueString + ?(IsBlankString(ValueString), "", "%%") + ValueStringTemplate;
					
				EndDo;
				
			Else
				TypeAsString = CommonUse.GetStringPresentationOfType(ValueType);
				ValueString = XMLString(DescriptionOfChoiceParameter.Value);
			EndIf;
			
			If Not IsBlankString(ValueString) Then
				
				CurrentCPString = StrReplace(CurrentCPString, "[FilterField]", DescriptionOfChoiceParameter.Name);
				CurrentCPString = StrReplace(CurrentCPString, "[TypeString]", TypeAsString);
				CurrentCPString = StrReplace(CurrentCPString, "[ValueString]", ValueString);
				
				ChoiceParametersString = ChoiceParametersString + CurrentCPString + Chars.LF;
				
			EndIf;
			
		EndDo;
		
		ChoiceParametersString = Left(ChoiceParametersString, StrLen(ChoiceParametersString)-1);
		
		ChoiceParameterLinksString = "";
		
		For Each DescriptionOfChoiceParameterLinks In AttributeDetails.ChoiceParameterLinks Do
			CurrentCPLString = "[ParameterName];[AttributeName]";
			CurrentCPLString = StrReplace(CurrentCPLString, "[ParameterName]", DescriptionOfChoiceParameterLinks.Name);
			CurrentCPLString = StrReplace(CurrentCPLString, "[AttributeName]", DescriptionOfChoiceParameterLinks.DataPath);
			ChoiceParameterLinksString = ChoiceParameterLinksString + CurrentCPLString + Chars.LF;
		EndDo;
		
		ChoiceParameterLinksString = Left(ChoiceParameterLinksString, StrLen(ChoiceParameterLinksString)-1);
		
		NewOperation = Operations.Add();
		NewOperation.AttributeName = AttributeDetails.Name;
		NewOperation.Presentation = ?(IsBlankString(AttributeDetails.Synonym), AttributeDetails.Name, AttributeDetails.Synonym);
		NewOperation.OperationKind = 1; // attribute
		NewOperation.ValidTypes = ValidTypesString;
		NewOperation.ChoiceParameters = ChoiceParametersString;
		NewOperation.ChoiceParameterLinks = ChoiceParameterLinksString;
		NewOperation.ChoiceFoldersAndItems = ChoiceFoldersAndItems;
		
		If LockableAttributes.Find(AttributeDetails.Name) <> Undefined Then
			NewOperation.BlockedAttribute = True;
		EndIf;
		
	EndDo;
	
EndProcedure

// Obtains array of attributes, that should not be edited
// at configuration level
//
Function GetEditFilterByType(MetadataObject)
	
	FilterXML = DataProcessors.BatchObjectsChanging.GetTemplate("FilterOfAttributes").GetText();
	
	FilterTable = CommonUse.ReadXMLToTable(FilterXML).Data;
	
	// Attributes, locked for any type of metadata object
	CommonFilter = FilterTable.FindRows(New Structure("ObjectType", "*"));
	
	// Attributes, locked for the specified type of metadata object
	FilterByMOType = FilterTable.FindRows(
							New Structure("ObjectType", 
							CommonUse.BaseTypeNameByMetadataObject(MetadataObject)) );
	
	FilterableAttributes = New Array;
	
	For Each RowDescription In CommonFilter Do
		FilterableAttributes.Add(RowDescription.Attribute);
	EndDo;
	
	For Each RowDescription In FilterByMOType Do
		FilterableAttributes.Add(RowDescription.Attribute);
	EndDo;
	
	Return FilterableAttributes;
	
EndFunction

// no information 0
NoErrors					= 1;
Error_NotClassified			= 2;
Error_FillCheckProcessing	= 3;
Error_ObjectWrite 			= 4;
Error_ObjectLock			= 5;
Error_AdditionalDataWrite	= 6;

// For data processor use without subsystem 'properties', link with module AdditionalDataAndAttributesManagement
// is determined in enterprise mode, but not during compilation
AdditionalDataAndAttributesManagementModule =
	?(Metadata.FindByFullName("CommonModule.AdditionalDataAndAttributesManagement") = Undefined,
				Undefined,
				Eval("AdditionalDataAndAttributesManagement"));
