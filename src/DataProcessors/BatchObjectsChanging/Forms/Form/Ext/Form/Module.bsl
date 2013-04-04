
///////////////////////////////////////////////////////////////////////////////
// Attributes created in attribute EditableObjects have names as Attribute_<fields>
// Fields created on form in form table ObjectsForChange have names Item_<name>
//
// DESCRIPTION OF ATTRIBUTES
//
// --- Settings of transactional processing ---------------------------------------
// TPPortionSetting - number
//   1 - in one portion
//   2 - in portions, by number of objects
//   3 - in portions, by object percentage
// TPPercentageOfObjectsInPortion - contains value if PortionChangeSetting = 2
// TPNumberOfObjectsInPortion - contains value if PortionChangeSetting = 3
// ------------------------------------------------------------------------------
//
// --- Modification of attributes being blocked -----------------------------------------
// IsFormOfUnlockingOfAttributes - could be used for objects
//						having blocked attributes, True - if there is a form to work
//						with blocked attributes (FormOfWorkWithBlockedAttributes).
//
// FullNameOfFormWorkWithBlockedAttributes - string - full name of form to be used
//						in function OpenFormModal, For example,
//						"Catalog.Item.Form.FormOfWorkWithBlockedAttributes"
// ------------------------------------------------------------------------------

///////////////////////////////////////////////////////////////////////////////
// Block of procedures and functions of work with history of changes

&AtServer
Procedure AddChangeToHistory(ChangeStructure, ChangePresentation)
	
	// Settings of change history is an array of structures with keys:
	// Change - array with structure of change
	// Presentation - presentation of setting to user
	Settings = CommonSettingsStorage.Load("BatchObjectsChanging", "ChangesHistory/"+FullName,, CommonUse.CurrentUser());
	
	If Settings = Undefined Then
		Settings = New Array;
	EndIf;
	
	Found = -1;
	
	For IndexOf = 0 TO Settings.UBound() Do
		If Settings.Get(IndexOf).Presentation = ChangePresentation Then
			Found = IndexOf;
			Break;
		EndIf;
	EndDo;
	
	If Found <> -1 Then
		Settings.Delete(Found);
	EndIf;
	
	Settings.Insert(0, New Structure("Update, Presentation", ChangeStructure, ChangePresentation));
	
	If Settings.Count() > 20 Then
		Settings.Delete(19);
	EndIf;
	
	CommonSettingsStorage.Save("BatchObjectsChanging", "ChangesHistory/"+FullName, Settings, , CommonUse.CurrentUser());
	
	LoadHistoryOfOperations();
	
EndProcedure

&AtServer
Procedure LoadHistoryOfOperations()
	
	HistoryOfOperations = CommonSettingsStorage.Load("BatchObjectsChanging", "ChangesHistory/"+FullName,, CommonUse.CurrentUser());
	
	If HistoryOfOperations = Undefined Then
		Return;
	EndIf;
	
	HistoryOfOperationsList.Clear();
	
	For Each OperationDescription In HistoryOfOperations Do
		HistoryOfOperationsList.Add(OperationDescription.Update, OperationDescription.Presentation);
	EndDo;
	
EndProcedure

&AtClient
Procedure SetChangeOperations(ArrayOfOperations)
	
	AreBlocked = False;
	
	For Each DescriptionOfChange In ArrayOfOperations Do
		
		SearchStructure = New Structure;
		SearchStructure.Insert("OperationKind", DescriptionOfChange.OperationKind);
		
		If DescriptionOfChange.OperationKind = 1 Then // object attribute
			SearchStructure.Insert("AttributeName", DescriptionOfChange.AttributeName);
		Else
			SearchStructure.Insert("Property", DescriptionOfChange.Property);
		EndIf;
		
		RowsFound = Object.Operations.FindRows(SearchStructure);
		
		If RowsFound.Count() > 0 Then
			If RowsFound[0].BlockedAttribute  Then
				AreBlocked = True;
				Continue;
			EndIf;
			RowsFound[0].Value = DescriptionOfChange.Value;
			RowsFound[0].Change = True;
		EndIf;
		
	EndDo;
	
	If AreBlocked Then
		DoMessageBox(NStr("en = 'Some attributes are blocked for modifications, changes not set'"));
	EndIf;
	
EndProcedure

///////////////////////////////////////////////////////////////////////////////
// Block of auxiliary procedures and functions

&AtServer
Procedure FillObjectTreeForChange(ArrayOfFilled)
	
	TableOfWorkedOut = New ValueTable;
	ArrayOfTypes = New Array;
	ArrayOfTypes.Add(TypeOf(Parameters.ObjectsArray[0]));
	TableOfWorkedOut.Columns.Add("Ref", New TypeDescription(ArrayOfTypes));
	
	For Each Item In ArrayOfFilled Do
		TableOfWorkedOut.Add().Ref = Item;
	EndDo;
	
	MetadataObject = Parameters.ObjectsArray[0].Metadata();
	
	MetadataObjectKind = CommonUse.ObjectClassByRef(Parameters.ObjectsArray[0]);
	
	QueryText =
		"SELECT
		|	Ref
		|Into
		|	WorkedOut
		|FROM
		|	&TableOfWorkedOut AS WorkedOut
		|;
		|SELECT
		|	Table.Ref AS Ref,
		|	0 AS ErrorCode,
		|	CASE WHEN WorkedOut.Ref IS NULL 
		|		THEN True
		|	ELSE False
		|END AS Change,";
		
	If IncludeHierarchy Then
		QueryText = QueryText + "
		|	CASE WHEN Table.DeletionMark THEN
		|		CASE WHEN Table.IsFolder THEN	1
		|		ELSE 3
		|		END
		|	ELSE
		|		CASE WHEN Table.IsFolder THEN	0
		|		ELSE 2
		|		END
		|	End AS PictureCode";
	Else
		QueryText = QueryText + "
		|	CASE WHEN Table.DeletionMark THEN 3
		|	ELSE 2
		|	END AS PictureCode";
	EndIf;
	
	CounterOfAdditAttributes = 0;
	CounterOfAdditInformation = 0;
	
	LeftJoinByAdditAttributes = "";
	LeftJoinByAdditInfo = "";
	
	ParametersProperties = New Map;
	
	For Each ColumnDetails In FormAttributeToValue("EditableObjects").Columns Do
		
		If CheckNonchangeableAttribute(ColumnDetails.Name) Then
			Continue;
		EndIf;
		
		If HasPrefix(ColumnDetails.Name, AttributeNamePrefix()) Then
			
			QueryText = QueryText + "," + Chars.LF + StringWithoutPrefix(ColumnDetails.Name, AttributeNamePrefix()) + " AS " + ColumnDetails.Name
			
		ElsIf HasPrefix(ColumnDetails.Name, PrefixOfNameOfAdditAttribute()) Then
			
			CounterOfAdditAttributes = CounterOfAdditAttributes + 1;
			QueryText = QueryText + "," + Chars.LF + 
			StrReplace("AdditionalAttributes[x].Value AS ", "[x]", String(CounterOfAdditAttributes)) + ColumnDetails.Name;
			
			LeftJoinByAdditAttributes = LeftJoinByAdditAttributes + "
			|		LEFT JOIN
			|			[MetadataObjectKind].[NameOfMetadataObject].AdditionalAttributes AS AdditionalAttributes[x]
			|			ON AdditionalAttributes[x].Ref = Table.Ref
			|			 And AdditionalAttributes[x].Property = &AdditAttribute[x]";
			
			LeftJoinByAdditAttributes = StrReplace(LeftJoinByAdditAttributes, "[x]", String(CounterOfAdditAttributes));
			
			UnIdString = StrReplace(StringWithoutPrefix(ColumnDetails.Name, PrefixOfNameOfAdditAttribute()), "_", "-");
			UnId = New Uuid(UnIdString);
			//Property = ChartsOfCharacteristicTypes.AdditionalDataAndAttributes.GetRef(UnId);
			//
			//ParametersProperties.Insert(StrReplace("AdditAttribute[x]", "[x]", String(CounterOfAdditAttributes)), Property);
		
		ElsIf HasPrefix(ColumnDetails.Name, PrefixOfNameOfAdditInfo()) Then
			CounterOfAdditInformation = CounterOfAdditInformation + 1;
			QueryText = QueryText + "," + Chars.LF + 
			StrReplace("AdditionalData[x].Value AS ", "[x]", String(CounterOfAdditInformation)) + ColumnDetails.Name;
			
			LeftJoinByAdditInfo = LeftJoinByAdditInfo + "
			|		LEFT JOIN
			|			InformationRegister.AdditionalData AS AdditionalData[x]
			|			ON AdditionalData[x].Object = Table.Ref
			|			 And AdditionalData[x].Property = &AdditInformation[x]";
			
			LeftJoinByAdditInfo = StrReplace(LeftJoinByAdditInfo, "[x]", String(CounterOfAdditInformation));
			
			UnIdString = StrReplace(StringWithoutPrefix(ColumnDetails.Name, PrefixOfNameOfAdditInfo()), "_", "-");
			UnId = New Uuid(UnIdString);
			//Property = ChartsOfCharacteristicTypes.AdditionalDataAndAttributes.GetRef(UnId);
			//
			//ParametersProperties.Insert(StrReplace("AdditInformation[x]", "[x]", String(CounterOfAdditInformation)), Property);
			
		EndIf;
		
	EndDo;
	
	QueryText = QueryText + "
		|FROM
		|	[MetadataObjectKind].[NameOfMetadataObject] AS Table
		|		LEFT JOIN WorkedOut
		|			ON Table.Ref = WorkedOut.Ref";
	
	QueryText = QueryText + LeftJoinByAdditAttributes;
	QueryText = QueryText + LeftJoinByAdditInfo;
	
	QueryText = QueryText + "
		|WHERE";
	
	If ProcessRecursively And IncludeHierarchy Then
		QueryText = QueryText + "
		|	Table.Ref In HIERARCHY(&RefsArray)";
	Else
		QueryText = QueryText + "
		|	Table.Ref In (&RefsArray)";
	EndIf;
	
	QueryText = QueryText + "
		|ORDER BY";
	
	If ProcessRecursively And IncludeHierarchy Then
		QueryText = QueryText + "
		|	Table.IsFolder HIERARCHY ASC,";
	EndIf;
	
	QueryText = QueryText + "
		|	Table.Ref ASC";
		
	QueryText = StrReplace(QueryText, "[MetadataObjectKind]",   MetadataObjectKind);
	QueryText = StrReplace(QueryText, "[NameOfMetadataObject]", MetadataObject.Name);
	
	TTManager = New TempTablesManager;
	
	Query = New Query;
	Query.TempTablesManager = TTManager;
	Query.Text = QueryText;
	Query.Parameters.Insert("RefsArray", Parameters.ObjectsArray);
	Query.SetParameter("TableOfWorkedOut", TableOfWorkedOut);
	
	For Each ParameterProperty In ParametersProperties Do
		Query.SetParameter(ParameterProperty.Key, ParameterProperty.Value);
	EndDo;
	
	ValueToFormData(Query.Execute().Unload(QueryResultIteration.ByGroupsWithHierarchy), EditableObjects);
	
EndProcedure

&AtServer
Procedure FillSolidObjectListForChange(ItemCollection)
	
	For Each CollectionItem In ItemCollection Do
		NewRow = Object.ObjectsForChange.Add();
		NewRow.Ref = CollectionItem.Ref;
		FillSolidObjectListForChange(CollectionItem.GetItems());
	EndDo;
	
EndProcedure

&AtClientAtServerNoContext
Function ToolTipTextOfActionsPage(ObjectCount)
	
	Return StringFunctionsClientServer.SubstitureParametersInString(
				NStr("en = 'Click ""Next"" button to see editable objects (%1)'"),
				ObjectCount);
	
EndFunction

&AtClientAtServerNoContext
// Change accessibility of form commands depending on current country
//
Procedure SetStatusOfFormItems(Items, Quantity = 0)
	
	If Quantity > 0 Then
		Items.ToolTipOfActionsPage.Title = ToolTipTextOfActionsPage(Quantity);
	EndIf;
	
	If Items.Pages.CurrentPage = Items.SetupOfChanges Then
		Items.FormBack.Enabled = False;
		Items.FormNext.Enabled = True;
	ElsIf Items.Pages.CurrentPage = Items.ChangeOfObjects Then
		Items.FormBack.Enabled = True;
		Items.FormNext.Enabled = False;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure FillArrayOfModified(Array, Items)
	
	For Each Item In Items Do
		If NOT Item.Change Then
			Array.Add(Item.Ref);
		EndIf;
		Child = Item.GetItems();
		If Child.Count() > 0 Then
			FillArrayOfModified(Array, Child);
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure GenerateAndFillTreeOfEditableObjects()
	
	ArrayOfFilled = New Array;
	
	FillArrayOfModified(ArrayOfFilled, EditableObjects.GetItems());
	
	GenerateTreeOfEditableObjects();
	FillObjectTreeForChange(ArrayOfFilled);
	
	ChangeTableOfObjects = False;
	
EndProcedure

&AtServer
Function ObjectCountForProcessing()
	
	Return EditableObjects.Rows.Count();
	
EndFunction // ObjectCountForProcessing()

&AtClientAtServerNoContext
Function StringWithoutPrefix(AttributeNameWithPrefix, Prefix)
	Return Right(AttributeNameWithPrefix, StrLen(AttributeNameWithPrefix) - StrLen(Prefix));
EndFunction

&AtServer
// Need to change attribute on filtering of operations with objects
// EditableObjects (add new columns) and change form table
// (add new columns on the form).
//
Procedure GenerateTreeOfEditableObjects()
	
	ExistingAttributesSet = New Array;
	
	For Each ColumnDetails In FormAttributeToValue("EditableObjects").Columns Do
		
		If CheckNonchangeableAttribute(ColumnDetails.Name) Then
			Continue;
		EndIf;
		
		ExistingAttributesSet.Add(ColumnDetails.Name);
	EndDo;
	
	NewSetOfAttributes = New Array;
	
	For Each Operation In Object.Operations Do
		If    Operation.Change And Operation.OperationKind = 1 Then
			NewSetOfAttributes.Add(AttributeNamePrefix()+Operation.AttributeName);
		ElsIf Operation.Change And Operation.OperationKind = 2 Then
			NewSetOfAttributes.Add(PrefixOfNameOfAdditAttribute()+StrReplace(Operation.Property.Uuid(), "-", "_"));
		ElsIf Operation.Change And Operation.OperationKind = 3 Then
			NewSetOfAttributes.Add(PrefixOfNameOfAdditInfo()+StrReplace(Operation.Property.Uuid(), "-", "_"));
		EndIf;
	EndDo;
	
	NamesAddedRequisites = DifferenceOfArrays(NewSetOfAttributes, ExistingAttributesSet);
	NamesOfDeletedAttributes = DifferenceOfArrays(ExistingAttributesSet, NewSetOfAttributes);
	
	AttributesBeingAdded = New Array;
	
	For Each AttributeName In NamesAddedRequisites Do
		
		If HasPrefix(AttributeName, AttributeNamePrefix()) Then
		
			Operation = Object.Operations.FindRows(New Structure("AttributeName", StringWithoutPrefix(AttributeName, AttributeNamePrefix())))[0];
			ValidTypesArray = StringFunctionsClientServer.DecomposeStringIntoSubstringsArray(Operation.ValidTypes, ";");
			
			TypesArray = New Array;
			
			For Each ValidTypeString In ValidTypesArray Do
				TypesArray.Add(Type(ValidTypeString));
			EndDo;
			
			TypeDescription = New TypeDescription(TypesArray);
			
		ElsIf HasPrefix(AttributeName, PrefixOfNameOfAdditAttribute())
			  OR HasPrefix(AttributeName, PrefixOfNameOfAdditInfo()) Then
			
			Prefix = ?(HasPrefix(AttributeName, PrefixOfNameOfAdditAttribute()),
							PrefixOfNameOfAdditAttribute(),
							PrefixOfNameOfAdditInfo());
			
			UnId = New Uuid(StrReplace(StringWithoutPrefix(AttributeName, Prefix), "_", "-"));
			
			//Property = ChartsOfCharacteristicTypes.AdditionalDataAndAttributes.GetRef(UnId);
			//
			//TypeDescription = Property.ValueType;
			//
			//Operation = Object.Operations.FindRows(New Structure("Property", Property))[0];
			
		EndIf;
		
		AttributesBeingAdded.Add(New FormAttribute(AttributeName, TypeDescription, "EditableObjects", Operation.Presentation));
		
	EndDo;
	
	AttributesToBeDeleted = New Array;
	
	For Each AttributeName In NamesOfDeletedAttributes Do
		AttributesToBeDeleted.Add("EditableObjects."+AttributeName);
	EndDo;
	
	ChangeAttributes(AttributesBeingAdded, AttributesToBeDeleted);
	
	FormFieldsToBeDeleted = New Array;
	
	For Each FormField In Items.ObjectsForChange.ChildItems Do
		If TypeOf(FormField) = Type("FormField") And FormField.DataPath = "" Then
			FormFieldsToBeDeleted.Add(FormField);
		EndIf;
	EndDo;
	
	For Each AddedAttribute In AttributesBeingAdded Do
		NewFormItem = Items.Add(PrefixOfNameOfFormField()+AddedAttribute.Name, Type("FormField"), Items.ObjectsForChange);
		NewFormItem.DataPath = "EditableObjects."+AddedAttribute.Name;
	EndDo;
	
EndProcedure

&AtServerNoContext
Function DifferenceOfArrays(ArraySource, ArraySubtractable)
	
	Result = New Array;
	
	For Each ArrayItem In ArraySource Do
		If ArraySubtractable.Find(ArrayItem) = Undefined Then
			Result.Add(ArrayItem);
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

///////////////////////////////////////////////////////////////////////////////
// Block of procedures - form item event handlers

&AtClient
// Handler of event BeforeAddRow of table of form TableTableOfOperations
//
Procedure TableOfOperationsBeforeRowChange(Item, Cancellation)
	
	If (Item.CurrentItem.Name = "TableOfOperationsChange"
		OR Item.CurrentItem.Name = "TableOfOperationsValue")
	   And Item.CurrentData.BlockedAttribute Then
		QuestionGoToToAttributeUnblocking();
		Cancellation = True;
		Return;
	EndIf;
	
	SetConstraintsOfSelectedTypesAndChoiceParameters(Item);
	
EndProcedure

&AtClient
// Handler of event selection of table of form TableTableOfOperations
// sets type restriction for edited attribute
//
Procedure TableOfOperationsSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field.Name = "TableOfOperationsValue"
	   And Item.CurrentData.BlockedAttribute Then
		
		QuestionGoToToAttributeUnblocking();
		StandardProcessing = False;
		
		Return;
		
	EndIf;
	
	SetConstraintsOfSelectedTypesAndChoiceParameters(Item);
	
EndProcedure

&AtClient
Procedure QuestionGoToToAttributeUnblocking()
	
	QuestionText = NStr("en = 'Attention! Attribute is locked, go to unblock attributes?'");
	
	Buttons = New ValueList;
	Buttons.Add(DialogReturnCode.Yes, NStr("en = 'Yes'"));
	Buttons.Add(DialogReturnCode.Cancel, NStr("en = 'Cancel'"));
	
	Result = DoQueryBox(QuestionText, Buttons, , DialogReturnCode.Yes, NStr("en = 'Attribute is locked'"));
	
	If Result = DialogReturnCode.Yes Then
		AllowEditOfAttributes();
	EndIf;
	
EndProcedure

&AtServer
Procedure SetChoiceParametersServer(ChoiceParameters, ChoiceParametersArray)
	
		For IndexOf = 1 to StrLineCount(ChoiceParameters) Do
			
			ChoiceParametersString = StrGetLine(ChoiceParameters, IndexOf);
		
			FieldNamePosition 			= Find(ChoiceParametersString, ";") - 1;
			FilterFieldName 			= Mid(ChoiceParametersString, 1, FieldNamePosition);
			ChoiceParametersString 		= Right(ChoiceParametersString, StrLen(ChoiceParametersString)-FieldNamePosition-1);
			TypeNamePosition 			= Find(ChoiceParametersString, ";") - 1;
			TypeName 					= Mid(ChoiceParametersString, 1, TypeNamePosition);
			ChoiceParametersString 		= Right(ChoiceParametersString, StrLen(ChoiceParametersString)-TypeNamePosition-1);
			Value 						= ChoiceParametersString;
			
			ChoiceParametersArray.Add(New ChoiceParameter(FilterFieldName,XMLValue(Type(TypeName), Value)) );
		
		EndDo;
	
EndProcedure

&AtClient
// Sets restrictions of selected value types and of choice parameters
//
Procedure SetConstraintsOfSelectedTypesAndChoiceParameters(Item)
	
	Field = Item.ChildItems.TableOfOperationsValue;
	
	ValidTypesString = Item.CurrentData.ValidTypes;
	
	ValidTypesArray = StringFunctionsClientServer.DecomposeStringIntoSubstringsArray(ValidTypesString, ";");
	
	ArrayOfTypes = New Array;
	
	For Each TypeString In ValidTypesArray Do
		ArrayOfTypes.Add(Type(TypeString));
	EndDo;
	
	Field.TypeRestriction = New TypeDescription(ArrayOfTypes);
	
	ChoiceParametersArray = New Array;
	
	If NOT IsBlankString(Item.CurrentData.ChoiceParameters) Then
#If WebClient Then
		SetChoiceParametersServer(Item.CurrentData.ChoiceParameters, ChoiceParametersArray)
#Else
		For IndexOf = 1 to StrLineCount(Item.CurrentData.ChoiceParameters) Do
			
			ChoiceParametersString = StrGetLine(Item.CurrentData.ChoiceParameters, IndexOf);
		
			FieldNamePosition 		= Find(ChoiceParametersString, ";") - 1;
			FilterFieldName 		= Mid(ChoiceParametersString, 1, FieldNamePosition);
			ChoiceParametersString 	= Right(ChoiceParametersString, StrLen(ChoiceParametersString)-FieldNamePosition-1);
			TypeNamePosition 		= Find(ChoiceParametersString, ";") - 1;
			TypeName 				= Mid(ChoiceParametersString, 1, TypeNamePosition);
			ChoiceParametersString 	= Right(ChoiceParametersString, StrLen(ChoiceParametersString)-TypeNamePosition-1);
			Value 					= ChoiceParametersString;
			
			ChoiceParametersArray.Add(New ChoiceParameter(FilterFieldName,XMLValue(Type(TypeName), Value)) );
		
		EndDo;
#EndIf
	EndIf;
	
	If Not IsBlankString(Item.CurrentData.ChoiceParameterLinks) Then
	
		For IndexOf = 1 to StrLineCount(Item.CurrentData.ChoiceParameterLinks) Do
			
			ChoiceParametersLinkString 	= StrGetLine(Item.CurrentData.ChoiceParameterLinks, IndexOf);
			ParsedRows 					= StringFunctionsClientServer.DecomposeStringIntoSubstringsArray(ChoiceParametersLinkString, ";");
			ParameterName 				= TrimAll(ParsedRows[0]);
			AttributeName 				= TrimAll(ParsedRows[1]);
			RowsFound 					= Object.Operations.FindRows(New Structure("OperationKind,AttributeName", 1, AttributeName));
			If RowsFound.Count() = 1 Then
				Value = RowsFound[0].Value;
				If ValueIsFilled(Value) Then
					ChoiceParametersArray.Add(New ChoiceParameter(ParameterName, Value));
				EndIf;
			EndIf;
			
		EndDo;
	
	EndIf;
	
	Field.ChoiceParameters = New FixedArray(ChoiceParametersArray);
	
	ChoiceFoldersAndItems = Item.CurrentData.ChoiceFoldersAndItems;
	
	If ChoiceFoldersAndItems <> "" Then
		If	  ChoiceFoldersAndItems = "Folders" Then
			Field.ChoiceFoldersAndItems = FoldersAndItems.Folders;
		ElsIf ChoiceFoldersAndItems = "FoldersAndItems" Then
			Field.ChoiceFoldersAndItems = FoldersAndItems.FoldersAndItems;
		ElsIf ChoiceFoldersAndItems = "Items" Then
			Field.ChoiceFoldersAndItems = FoldersAndItems.Items;
		Else
			Field.ChoiceFoldersAndItems = FoldersAndItems.Auto;
		EndIf;
	Else
		Field.ChoiceFoldersAndItems = FoldersAndItems.Auto;
	EndIf;
	
EndProcedure

&AtClient
Procedure TableOfOperationsOnEditEnd(Item, NewRow, CancelEdit)
	
	If Item.CurrentItem.Name = "TableOfOperationsValue" Then
		If CancelEdit Then
			
		ElsIf NOT ValueIsFilled(Item.CurrentData.Value) Then
			Item.CurrentData.Change = False;
			ChangeTableOfObjects = True;
		Else
			Item.CurrentData.Change = True;
			ChangeTableOfObjects = True;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure ObjectsForChangeSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field = Items.ObjectsForChangeRef Then
		StandardProcessing = False;
		OpenObjectByRef();
	EndIf;
	
EndProcedure

///////////////////////////////////////////////////////////////////////////////
// Block of procedures - form event handlers

&AtClient
Procedure OnOpen(Cancellation)
	
	If IncorrectDataProcessorCall Then
		Cancellation = True;
		DoMessageBox(NStr("en = 'Data Processing is used only together with the objects of the information base'"),0,NStr("en = ''"));
		Return;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnClose()
	
	SaveDataProcessorSettings(
			FullName,
			Object.ChangeInTransaction,
			Object.AbortOnError,
			TPPortionSetting,
			TPPercentageOfObjectsInPortion,
			TPNumberOfObjectsInPortion,
			ProcessRecursively);
	
EndProcedure

&AtServerNoContext
Procedure SaveDataProcessorSettings(FullName, ChangeInTransaction, AbortOnError,
			TPPortionSetting, TPPercentageOfObjectsInPortion, TPNumberOfObjectsInPortion, ProcessRecursively)
	
	SettingsStructure = New Structure;
	
	SettingsStructure.Insert("ChangeInTransaction",				ChangeInTransaction);
	SettingsStructure.Insert("AbortOnError",					AbortOnError);
	SettingsStructure.Insert("TPPortionSetting",				TPPortionSetting);
	SettingsStructure.Insert("TPPercentageOfObjectsInPortion",	TPPercentageOfObjectsInPortion);
	SettingsStructure.Insert("TPNumberOfObjectsInPortion",		TPNumberOfObjectsInPortion);
	SettingsStructure.Insert("ProcessRecursively",				ProcessRecursively);
	
	CommonSettingsStorage.Save("DataProcessor.BatchObjectsChanging", FullName, SettingsStructure, , CommonUse.CurrentUser());
	
EndProcedure

&AtServer
Procedure LoadDataProcessorSettings()
	
	SettingsStructure = CommonSettingsStorage.Load("DataProcessor.BatchObjectsChanging", FullName, , CommonUse.CurrentUser());
	
	If SettingsStructure = Undefined Then
		Object.ChangeInTransaction 		= True;
		Object.AbortOnError 			= True;
		TPPortionSetting 				= 1;
		TPPercentageOfObjectsInPortion 	= 100;
		TPNumberOfObjectsInPortion 		= 1;
		ProcessRecursively 				= False;
	Else
		Object.ChangeInTransaction		= SettingsStructure.ChangeInTransaction;
		Object.AbortOnError				= SettingsStructure.AbortOnError;
		TPPortionSetting				= SettingsStructure.TPPortionSetting;
		TPPercentageOfObjectsInPortion	= SettingsStructure.TPPercentageOfObjectsInPortion;
		TPNumberOfObjectsInPortion		= SettingsStructure.TPNumberOfObjectsInPortion;
		ProcessRecursively				= SettingsStructure.ProcessRecursively;
	EndIf;
	
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancellation, StandardProcessing)
	
	IncorrectDataProcessorCall = False;
	
	If TypeOf(Parameters.ObjectsArray) <> Type("Array") Then
		IncorrectDataProcessorCall = True;
		Return;
	EndIf;
	
	// Optimization - to avoid regeneration of table
	// of objects being changed on simple scrolling
	ChangeTableOfObjects = False;
	
	ObjectMetadata = Parameters.ObjectsArray[0].Metadata();
	
	FullName = ObjectMetadata.FullName();
	
	CurrentUser = Users.AuthorizedUser();
	
	// Load data processor settings
	LoadDataProcessorSettings();
	
	// Load history of operations with current type of objects
	LoadHistoryOfOperations();
	
	// Set title for the table of objects being changed
	Items.ObjectsForChangeRef.Title = ObjectMetadata.Synonym;
	
	// Hierarchical object
	IncludeHierarchy = MetadataObjectHierarchical();
	
	// Fill valid actions with object using passed object set and object type
	FillTreeOfObjectsAndOperations();
	
	// If there are no blocked attributes - hide button "AllowEditOfAttributes"
	If Object.Operations.FindRows(
			New Structure("BlockedAttribute", True) ).Count() = 0 Then
		If Items.Find("AllowEditOfAttributes") <> Undefined Then
			Items.AllowEditOfAttributes.Visible = False;
		EndIf;
	Else
		If ObjectMetadata.Forms.Find("UnlockingOfAttributes") = Undefined Then
			IsFormOfUnlockingOfAttributes = False;
		Else
			IsFormOfUnlockingOfAttributes = True;
			FullNameOfFormWorkWithBlockedAttributes = FullName + ".Form.UnlockingOfAttributes";
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillTreeOfObjectsAndOperations()
	
	ArrayOfFilled = New Array;
	FillArrayOfModified(ArrayOfFilled, EditableObjects.GetItems());
	
	Object.ObjectsForChange.Clear();
	Object.Operations.Clear();
	EditableObjects.GetItems().Clear();
	
	FillObjectTreeForChange(ArrayOfFilled);
	
	FillSolidObjectListForChange(EditableObjects.GetItems());
	
	ObjectDataProcessor = FormAttributeToValue("Object");
	ObjectDataProcessor.FillTableOfOperationsWithObject();
	ValueToFormAttribute(ObjectDataProcessor, "Object");
	
	SetStatusOfFormItems(Items, Object.ObjectsForChange.Count());
	
EndProcedure

///////////////////////////////////////////////////////////////////////////////
// Block of procedures - command handlers

&AtClient
Procedure HistoryOfOperations(Command)
	
	StandardProcessing = False;
	
	If HistoryOfOperationsList.Count() = 0 Then
		DoMessageBox(NStr("en = 'The specified type of objects does not have group change record history.'"));
		Return;
	EndIf;
	
	ValueList = New ValueList;
	
	For Each DescriptionOfChange In HistoryOfOperationsList Do
		ValueList.Add(DescriptionOfChange.Value, DescriptionOfChange.Presentation);
	EndDo;
	
	Selection = ChooseFromMenu(ValueList, Items.HistoryOfOperations);
	
	If Selection <> Undefined Then
		SetChangeOperations(Selection.Value);
	EndIf;
	
EndProcedure

&AtClient
Procedure Back(Command)
	
	If Items.Pages.CurrentPage = Items.ChangeOfObjects Then
		Items.Pages.CurrentPage = Items.SetupOfChanges;
		SetStatusOfFormItems(Items);
	EndIf;
	
EndProcedure

&AtClient
Procedure NextStep(Command)
	
	GoToPageOfObjectChanges();
	
EndProcedure

&AtClient
Procedure GoToPageOfObjectChanges()
	
	If Items.Pages.CurrentPage = Items.SetupOfChanges Then
		Items.Pages.CurrentPage = Items.ChangeOfObjects;
		SetStatusOfFormItems(Items);
		If ChangeTableOfObjects Then
			GenerateAndFillTreeOfEditableObjects();
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenObjectByRefCommandHandler(Command)
	
	OpenObjectByRef();
	
EndProcedure

&AtClient
// Handler of command "Change"
//
Procedure ChangeCommandHandler(Command)
	
	If Items.FormChange.Title = NStr("en = 'Change'") Then
	
		If Object.Operations.FindRows(New Structure("Change", True)).Count() = 0 Then
			
			QuestionText = NStr("en = 'Attention, no changes has been indicated, Do you want to proceed>'");
			Result = DoQueryBox(QuestionText, QuestionDialogMode.OKCancel, , , "Update of objects");
			
			If Result <> DialogReturnCode.OK Then
				Return;
			EndIf;
			
		EndIf;
		
		SetButtonsDuringModification(True);
		
		GoToPageOfObjectChanges();
		
		AttachIdleHandler("ChangeObjects", 0.1, True);
		
	ElsIf CurrentStatusOfChange <> Undefined Then
		
		CurrentStatusOfChange.AbortChange = True;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SetButtonsDuringModification(ModificationStart)
	
	Items.FormBack.Enabled = NOT ModificationStart;
	Items.FormCancel.Enabled = NOT ModificationStart;
	
	If ModificationStart Then
		Items.FormChange.Title = NStr("en = 'Abort'");
	Else
		Items.FormChange.Title = NStr("en = 'Change'");
	EndIf;
	
EndProcedure

&AtClient
Function PrepareTreeForChange(ItemCollection, CurrentEditableObjects)
	
	NumberOfBeingModified = 0;
	
	For Each ItemBeingEdited In ItemCollection Do
		ItemBeingEdited.ErrorCode = 0;
		If ItemBeingEdited.Change Then
			NumberOfBeingModified = NumberOfBeingModified + 1;
			CurrentEditableObjects.Add(ItemBeingEdited.Ref, ItemBeingEdited.GetID());
		EndIf;
		NumberOfBeingModified = NumberOfBeingModified + PrepareTreeForChange(ItemBeingEdited.GetItems(), CurrentEditableObjects);
	EndDo;
	
	Return NumberOfBeingModified;
	
EndFunction

&AtClient
// Main loop of change of objects
//
Procedure ChangeObjects()
	
	ClearMessages();
	
	CurrentStatusOfChange = New Structure;
	
	CurrentEditableObjects = New ValueList;
	
	ObjectCountForProcessing = PrepareTreeForChange(EditableObjects.GetItems(), CurrentEditableObjects);
	
	If ObjectCountForProcessing = 0 Then
		SetButtonsDuringModification(False);
		DoMessageBox(NStr("en = 'Objects for modification have not been defined'"));
		Return;
	EndIf;
	
	CurrentStatusOfChange.Insert("CurrentEditableObjects", CurrentEditableObjects);
	
	If Object.ChangeInTransaction Then
		
		If TPPortionSetting = 1 Then // processing in one call
			
			ShowUserNotification(NStr("en = 'Group change of objects'"), ,NStr("en = 'Please wait, data processor can take long time...'"));
			ShowPercentageOfProcessed = False;
			
			PortionSize = ObjectCountForProcessing;
			
		Else
			
			ShowPercentageOfProcessed = True;
			
			If TPPortionSetting = 2 Then // in portions by number of objects
				PortionSize = ?(TPNumberOfObjectsInPortion < ObjectCountForProcessing, 
									TPNumberOfObjectsInPortion, ObjectCountForProcessing);
			Else // in portions by object percentage
				PortionSize = Round(ObjectCountForProcessing * TPPercentageOfObjectsInPortion / 100);
				If PortionSize = 0 Then
					PortionSize = 1;
				EndIf;
			EndIf;
			
		EndIf;
	Else
		
		If ObjectCountForProcessing >= NontransactionalPortionTransitionBoundary() Then
			// Number of objects - is a constant
			PortionSize = NontransactionalPortionOfObtainingObjectData();
		Else
			// Number of objects - has variable value, percentage from total quantity
			PortionSize = Round(ObjectCountForProcessing * NontransactionalPortionOfObtainingDataPercent() / 100);
			If PortionSize = 0 Then
				PortionSize = 1;
			EndIf;
		EndIf;
		
		Status(NStr("en = 'Objects is processing'"), 0, NStr("en = 'Group change of objects'"));
		
		ShowPercentageOfProcessed = True;
	EndIf;
	
	CurrentStatusOfChange.Insert("AreItemsForProcessing", 		True);
	CurrentStatusOfChange.Insert("CurrentPosition", 			0); 		// position of last processed item. 1 - first item.
	CurrentStatusOfChange.Insert("NumberOfErrors", 				0);			// initialize error counter
	CurrentStatusOfChange.Insert("NumberOfModified", 			0);			// initialize counter of modified items
	CurrentStatusOfChange.Insert("StopUpdateOnError", 			Object.AbortOnError);
	CurrentStatusOfChange.Insert("ObjectCountForProcessing", 	ObjectCountForProcessing);
	CurrentStatusOfChange.Insert("PortionSize", 				PortionSize);
	CurrentStatusOfChange.Insert("ShowPercentageOfProcessed", 	ShowPercentageOfProcessed);
	CurrentStatusOfChange.Insert("AbortChange", 				False);
	
	AttachIdleHandler("ChangePortionOfObjects", 0.1, True);
	
EndProcedure

&AtClient
// Is used to modify object portion
Procedure ChangePortionOfObjects()
	
	Var NumberOfErrors, NumberOfModified;
	
	StartPosition = CurrentStatusOfChange.CurrentPosition;
	TargetPosition = CurrentStatusOfChange.CurrentPosition+CurrentStatusOfChange.PortionSize;
	
	While True Do
		PortionArray = GetPortionOfObjectsToProcess(StartPosition+1, TargetPosition);
		
		// Change portion at server
		ChangeResult = ChangeAtServer(PortionArray, CurrentStatusOfChange.StopUpdateOnError);
		
		// Transfer information about processed objects to the table
		FillStateOfProcessed(ChangeResult, NumberOfErrors, NumberOfModified);
		
		CurrentStatusOfChange.NumberOfErrors = NumberOfErrors + CurrentStatusOfChange.NumberOfErrors;
		CurrentStatusOfChange.NumberOfModified = NumberOfModified + CurrentStatusOfChange.NumberOfModified;
		
		If NOT (CurrentStatusOfChange.StopUpdateOnError And ChangeResult.AreErrors) Then
			Break;
		EndIf;
		
		// If there are errors in transaction - roll the entire transaction back
		If Object.ChangeInTransaction Then
			WarningText = NStr("en = 'On change of the objects some errors detected-changes have been cancelled'");
			AttachIdleHandler("FinishChangeOfObjects", 0.1, True);
			Return; // early exit from procedure
		EndIf;
		
		QuestionText = NStr("en = 'Attention, errors occurred while modifying the objects (group of objects).
                             |Abort the objects change/update and view the errors occurred?'");
		Buttons = New ValueList;
		Buttons.Add(DialogReturnCode.Abort, 	NStr("en = 'Abort'"));
		Buttons.Add(DialogReturnCode.Ignore,	NStr("en = 'Continue'"));
		Buttons.Add(DialogReturnCode.No, 		NStr("en = 'Do not ask any more'"));
		
		Result = DoQueryBox(QuestionText, Buttons, , DialogReturnCode.Abort, NStr("en = 'Error when changing objects'"));
		
		If Result = Undefined Or Result = DialogReturnCode.Abort Then
			AttachIdleHandler("FinishChangeOfObjects", 0.1, True);
			Return; // early exit from procedure
		EndIf;
			
		If Result = DialogReturnCode.Ignore OR Result = DialogReturnCode.No Then
			// start post processing of portion objects
			
			If Result = DialogReturnCode.No Then
				// in current loop no more changes are stopped by error
				CurrentStatusOfChange.StopUpdateOnError = False;
			EndIf;
			
			If PortionArray.Count() <= 1 Then
				Break;
			EndIf;
			
			For Each ProcessedObjectStatus In ChangeResult.DataProcessorStatus Do
				StartPosition = StartPosition + 1;
				If ProcessedObjectStatus.Value.ErrorCode > 1 Then
					Break;
				EndIf;
			EndDo;
			
			Continue;
			
		EndIf;
	EndDo;
	
	Items.ObjectsForChange.CurrentRow = CurrentStatusOfChange.CurrentPosition;
	
	CurrentStatusOfChange.CurrentPosition = CurrentStatusOfChange.CurrentPosition + CurrentStatusOfChange.PortionSize;
	
	If CurrentStatusOfChange.ShowPercentageOfProcessed Then
		// calculate current percentage of processed objects
		CurrentPercent = CurrentStatusOfChange.CurrentPosition / CurrentStatusOfChange.ObjectCountForProcessing * 100;
		Status(NStr("en = 'Objects is processing'"), CurrentPercent, NStr("en = 'Group change of objects'"));
	EndIf;
	
	AreItemsForProcessing = ?(CurrentStatusOfChange.CurrentPosition < CurrentStatusOfChange.ObjectCountForProcessing, True, False);
	
	If AreItemsForProcessing And NOT CurrentStatusOfChange.AbortChange Then
		AttachIdleHandler("ChangePortionOfObjects", 0.1, True);
	Else
		AttachIdleHandler("FinishChangeOfObjects", 0.1, True);
	EndIf;
	
EndProcedure

&AtClient
// Is used to modify object portion
Procedure FinishChangeOfObjects()
	
	If Object.ChangeInTransaction
	   And TPPortionSetting = 1 Then // processing in one call
		ShowUserNotification(NStr("en = 'Group change of objects'"), , NStr("en = 'Objects  data processing has been completed'"));
	EndIf;
	
	FinalizingActionsOnChangeServer();
	
	SetButtonsDuringModification(False);
	
	NotifyChanged(TypeOf(Parameters.ObjectsArray[0]));
	
	CurrentStatusOfChange = Undefined;
	
EndProcedure

&AtServer
// Final actions on change at server.
//  - current page is changed with change result
//  - current status is logged to history of changes
//
Procedure FinalizingActionsOnChangeServer()
	
	If CurrentStatusOfChange.NumberOfErrors > 0 Then
		
		Items.PagesOfTipsOfObjectsChange.CurrentPage =
			Items.PageToolTipAfterChangesAreErrors;
		
		If Object.ChangeInTransaction Then
			NumberOfModified = 0;
		Else
			NumberOfModified = String(CurrentStatusOfChange.NumberOfModified);
		EndIf;
		
		Items.ToolTipAfterChangeAreErrors.Title = 
			StringFunctionsClientServer.SubstitureParametersInString(
				NStr("en = 'Failed to modify objects. Modified %1 of %2 objects'"),
				NumberOfModified,
				String(CurrentStatusOfChange.ObjectCountForProcessing));
		
	Else
		Items.PagesOfTipsOfObjectsChange.CurrentPage =
			Items.PageToolTipSuccessfulUpdate;
		Items.ToolTipSuccessfulUpdate.Title = 
			StringFunctionsClientServer.SubstitureParametersInString(
				NStr("en = 'Modifying objects completed successfully.""Modified: %1.'"),
				String(CurrentStatusOfChange.NumberOfModified));
		
	EndIf;
	
	CollectionOpracij = Object.Operations.FindRows(New Structure("Change", True));
	
	DescriptionOfChange = New Array;
	PresentationPattern = "[Field]=<Value>";
	ChangePresentation = "";
	
	For Each OperationDescription In CollectionOpracij Do
		
		ChangeStructure = New Structure;
		ChangeStructure.Insert("OperationKind",		OperationDescription.OperationKind);
		ChangeStructure.Insert("AttributeName",		OperationDescription.AttributeName);
		ChangeStructure.Insert("Property",			OperationDescription.Property);
		ChangeStructure.Insert("Value",				OperationDescription.Value);
		
		DescriptionOfChange.Add(ChangeStructure);
		CurrentOperation 	= StrReplace(PresentationPattern,	"[Field]", TrimAll(String(OperationDescription.Presentation)));
		CurrentOperation 	= StrReplace(CurrentOperation, 		"<Value>", TrimAll(String(OperationDescription.Value)));
		ChangePresentation 	= ChangePresentation + CurrentOperation +"; ";
	EndDo;
	
	ChangePresentation = Left(ChangePresentation, StrLen(ChangePresentation) - 2);
	
	AddChangeToHistory(DescriptionOfChange, ChangePresentation);
	
EndProcedure

&AtClient
// Parameters DataProcessorStatus - map,
// key - ref to object, value 		- structure with keys ErrorCode,MessageAboutError
//				ErrorCode 			- 0 - no errors
//				MessageAboutError	- text error presentation
//
Procedure FillStateOfProcessed(ChangeResult, NumberOfErrors, NumberOfModified)
	
	NumberOfErrors = 0;
	NumberOfModified = 0;
	
	For Each ProcessedObjectStatus In ChangeResult.DataProcessorStatus Do
		
		LineNumber = -1;
		
		Id = Number(CurrentStatusOfChange.CurrentEditableObjects.FindByValue(ProcessedObjectStatus.Key).Presentation);
		
		TreeItem = EditableObjects.FindByID(Id);
		
		TreeItem.ErrorCode = ProcessedObjectStatus.Value.ErrorCode;
		
		If ProcessedObjectStatus.Value.ErrorCode > 1 Then
			NumberOfErrors = NumberOfErrors + 1;
			
			CommonUseClientServer.MessageToUser(
					ProcessedObjectStatus.Value.MessageAboutError
					+ "(" + String(ProcessedObjectStatus.Key) + ")", ,
					"EditableObjects["+String(Id)+"].Ref");
		Else
			NumberOfModified = NumberOfModified + 1;
			
			If NOT (Object.ChangeInTransaction And ChangeResult.AreErrors) Then
				For Each ModifiedAttribute In ProcessedObjectStatus.Value.ValuesOfModifiedAttributes Do
					LinkedAttributeName = AttributeNamePrefix() + ModifiedAttribute.Key;
					If TreeItem.Property(LinkedAttributeName) Then
						TreeItem[LinkedAttributeName] = ModifiedAttribute.Value;
					EndIf;
				EndDo;
				For Each ModifiedAttribute In ProcessedObjectStatus.Value.ValuesOfModifiedAdditAttributes Do
					If TreeItem.Property(ModifiedAttribute.Key) Then
						TreeItem[ModifiedAttribute.Key] = ModifiedAttribute.Value;
					EndIf;
				EndDo;
				For Each ModifiedAttribute In ProcessedObjectStatus.Value.ValuesOfModifiedAdditInformation Do
					If TreeItem.Property(ModifiedAttribute.Key) Then
						TreeItem[ModifiedAttribute.Key] = ModifiedAttribute.Value;
					EndIf;
				EndDo;
				
				TreeItem.Change = False;
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtClient
// Get refs to objects being processed in the interval
//
// Parameters
//  LowerBound  - item index. 1 - first item
//  UpperBound  - item index, 1 - first item
//
Function GetPortionOfObjectsToProcess(LowerBound, UpperBound)
	
	Portion = New Array;
	
	For IndexOf = LowerBound To UpperBound Do
		If IndexOf <= CurrentStatusOfChange.ObjectCountForProcessing Then
			Portion.Add(
				EditableObjects.FindByID(
					Number(CurrentStatusOfChange.CurrentEditableObjects.Get(IndexOf-1).Presentation)).Ref);
		EndIf;
	EndDo;
	
	Return Portion;
	
EndFunction

&AtServer
Function ChangeAtServer(ObjectsForProcessing, Val StopUpdateOnError)
	
	Result = FormAttributeToValue("Object").RunChangeOfObjects(ObjectsForProcessing, StopUpdateOnError);
	
	Return Result;
	
EndFunction

&AtClient
Procedure ConfigureChangeParameters(Command)
	
	Settings = New Structure;
	
	Settings.Insert("ChangeInTransaction",		 Object.ChangeInTransaction);
	Settings.Insert("ProcessRecursively",		 ProcessRecursively);
	Settings.Insert("AbortOnError",				 Object.AbortOnError);
	Settings.Insert("PortionSetting",			 TPPortionSetting);
	Settings.Insert("ObjectPercentageInPortion", TPPercentageOfObjectsInPortion);
	Settings.Insert("NumberOfObjectsInPortion",	 TPNumberOfObjectsInPortion);
	Settings.Insert("IncludeHierarchy",			 IncludeHierarchy);
	
	Result = OpenFormModal("DataProcessor.BatchObjectsChanging.Form.Settings", Settings);
	
	RegeneratedContentOfOperationsAndObjectTree = False;
	
	If TypeOf(Result) = Type("Structure") Then
		If IncludeHierarchy And ProcessRecursively <> Result.ProcessRecursively Then
			ProcessRecursively	= Result.ProcessRecursively;
			RegeneratedContentOfOperationsAndObjectTree = True;
		EndIf;
		Object.ChangeInTransaction		= Result.ChangeInTransaction;
		Object.AbortOnError				= Result.AbortOnError;
		TPPortionSetting				= Result.PortionSetting;
		TPPercentageOfObjectsInPortion	= Result.ObjectPercentageInPortion;
		TPNumberOfObjectsInPortion		= Result.NumberOfObjectsInPortion;
	EndIf;
	
	If RegeneratedContentOfOperationsAndObjectTree Then
		FillTreeOfObjectsAndOperations();
	EndIf;
	
EndProcedure

&AtClient
Procedure GoToEventLog(Command)
	
	ELParameters = New Structure("User", CurrentUser);
	
	OpenFormModal("DataProcessor.EventLog.Form", ELParameters, ThisForm);
	
EndProcedure

&AtClient
Procedure AllowEditOfAttributesCommandHandler(Command)
	
	AllowEditOfAttributes();
	
EndProcedure

&AtClient
Procedure AllowEditOfAttributes()
	
	BlockedRowAttributes = Object.Operations.FindRows(New Structure("BlockedAttribute", True));
	
	If IsFormOfUnlockingOfAttributes Then
		
		AllowedAttributes = OpenFormModal(FullNameOfFormWorkWithBlockedAttributes);
		
		If TypeOf(AllowedAttributes) = Type("Array")
		   And AllowedAttributes.Count() > 0 Then
			
			For Each OperationDescriptionString In BlockedRowAttributes Do
				If OperationDescriptionString.BlockedAttribute
				   And AllowedAttributes.Find(OperationDescriptionString.AttributeName) <> Undefined Then
					OperationDescriptionString.BlockedAttribute = False;
				EndIf;
			EndDo;
			
			If Object.Operations.FindRows(New Structure("BlockedAttribute", True)).Count() = 0 Then
				Items.AllowEditOfAttributes.Enabled = False;
			EndIf;
			
		EndIf;
	Else
		
		RefsArray = New Array;
		
		FillObjectsToChangeArray(EditableObjects.GetItems(), RefsArray);
		
		SynonymsOfAttributes = New Array;
		
		For Each OperationDescriptionString In BlockedRowAttributes Do
			SynonymsOfAttributes.Add(OperationDescriptionString.Presentation);
		EndDo;
		
	EndIf;
	
EndProcedure


&AtClient
Procedure FillObjectsToChangeArray(RowsCollection, RefsArray)
	
	For Each ChangingObjectRow In RowsCollection Do
		RefsArray.Add(ChangingObjectRow.Ref);
		FillObjectsToChangeArray(ChangingObjectRow.GetItems(), RefsArray);
	EndDo;
	
EndProcedure

&AtClient
Procedure OpenObjectByRef()
	
	StructureOfParameters = New Structure;
	StructureOfParameters.Insert("ReadOnly", True);
	StructureOfParameters.Insert("Key", Items.ObjectsForChange.CurrentData.Ref);
	
	OpenForm(FullName + ".ObjectForm", StructureOfParameters);
	
EndProcedure

&AtClient
Procedure ChangesCheckCheckAll(Command)
	
	SetDeletionMarkValue(EditableObjects.GetItems(), True);
	
EndProcedure

&AtClient
Procedure ChangesCheckUncheckAll(Command)
	
	SetDeletionMarkValue(EditableObjects.GetItems(), False);
	
EndProcedure

&AtClient
Procedure SetDeletionMarkValue(ItemCollection, Value)
	
	For Each CollectionItem In ItemCollection Do
		CollectionItem.Change = Value;
		SetDeletionMarkValue(CollectionItem.GetItems(), Value);
	EndDo;
	
EndProcedure


///////////////////////////////////////////////////////////////////////////////
// Service functions

&AtClientAtServerNoContext
Function CheckNonchangeableAttribute(AttributeName)
	
	If AttributeName = "Ref"
	 OR AttributeName = "Change"
	 OR AttributeName = "ErrorCode"
	 OR AttributeName = "PictureCode"
	Then
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

&AtServer
Function MetadataObjectHierarchical()
	
	RefOfFirst = Parameters.ObjectsArray[0];
	ObjectClassByRef = CommonUse.ObjectClassByRef(RefOfFirst);
	
	If ((ObjectClassByRef = "Catalog" OR ObjectClassByRef = "ChartOfCharacteristicTypes") And RefOfFirst.Metadata().Hierarchical)
	 OR (ObjectClassByRef = "ChartOfAccounts") Then
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

&AtClientAtServerNoContext
Function HasPrefix(AttributeName, Prefix)
	
	Return Left(AttributeName, StrLen(Prefix)) = Prefix;
	
EndFunction

&AtClientAtServerNoContext
Function AttributeNamePrefix()
	Return "Attribute_";
EndFunction

&AtClientAtServerNoContext
Function PrefixOfNameOfAdditAttribute()
	Return "AdditAttribute_";
EndFunction

&AtClientAtServerNoContext
Function PrefixOfNameOfAdditInfo()
	Return "AdditInformation_";
EndFunction

&AtClientAtServerNoContext
Function PrefixOfNameOfFormField()
	Return "Item_";
EndFunction

&AtClientAtServerNoContext
Function NontransactionalPortionTransitionBoundary()
	
	Return 100; // if there are more than 100 objects in the list of modified items
// then change occures for a constant object quantity
// see NontransactionalPortionOfObtainingObjectData()
	
EndFunction

&AtClientAtServerNoContext
Function NontransactionalPortionOfObtainingDataPercent()
	
	Return 10;	// if there are less than 100 objects in the list of modified items 
// change occures by portions by percentage of objects in total object number
	
EndFunction

&AtClientAtServerNoContext
Function NontransactionalPortionOfObtainingObjectData()
	
	Return 10;	// if there are more than 100 objects in the list of modified items
// change occures by portions by constant
// object number
	
EndFunction
