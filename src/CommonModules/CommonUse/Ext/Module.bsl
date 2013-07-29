
////////////////////////////////////////////////////////////////////////////////
// Base functionality subsystem.
//------------------------------------------------------------------------------
// Common server procedures and functions for working with:
// - infobase data;
// - applied types and value collections;
// - math operations;
// - external connections;
// - forms;
// - types, metadata objects, and their string presentations;
// - metadata object type definition;
// - saving/reading/deleting settings to/from storages;
// - spreadsheet documents;
// - event log;
// - data separation mode;
// - API versioning.
//
// The module also includes auxiliary procedures and functions.
//

////////////////////////////////////////////////////////////////////////////////
#Region PUBLIC_INTERFACE

////////////////////////////////////////////////////////////////////////////////
#Region Common_procedures_and_functions_for_working_with_infobase_data

// Returns a structure that contains attribute values read from the infobase by
// object reference.
// 
// If access to any of the attributes is denied, an exception is raised.
// To be able to read attribute values irrespective of current user rights,
// turn privileged mode on.
// 
// Parameters:
// Ref - Reference - reference to a catalog, a document, or any other infobase object;
// AttributeNames - String or Structure - If AttributeNames is a string, it 
// contains attribute names separated by commas.
// Example: "Code, Description, Parent".
// If AttributeNames is a structure, its keys are used for resulting structure keys, 
// and its values are field names. If a value is empty, it is considered
// equal to the key.
// 
// Returns:
// Structure where keys are the same as in AttributeNames, and values are the retrieved field values.
//
Function GetAttributeValues(Ref, AttributeNames) Export

	If TypeOf(AttributeNames) = Type("Structure") Then
		AttributeStructure = AttributeNames;
	ElsIf TypeOf(AttributeNames) = Type("String") Then
		AttributeStructure = New Structure(AttributeNames);
	Else
		Raise StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en = 'Invalid AttributeNames type: %1.'"), 
			String(TypeOf(AttributeNames)));
	EndIf;

	FieldTexts = "";
	For Each KeyAndValue In AttributeStructure Do
		FieldName = ?(ValueIsFilled(KeyAndValue.Value), TrimAll(KeyAndValue.Value), TrimAll(KeyAndValue.Key));
		Alias = TrimAll(KeyAndValue.Key);
		FieldTexts = FieldTexts + ?(IsBlankString(FieldTexts), "", ",") + "
			|	" + FieldName + " AS " + Alias;
	EndDo;

	Query = New Query(
		"SELECT
		|" + FieldTexts + "
		|FROM
		|	" + Ref.Metadata().FullName() + " AS AliasForSpecifiedTable
		|WHERE
		|	AliasForSpecifiedTable.Ref = &Ref
		|");
	Query.SetParameter("Ref", Ref);
	Selection = Query.Execute().Choose();
	Selection.Next();

	Result = New Structure;
	For Each KeyAndValue In AttributeStructure Do
		Result.Insert(KeyAndValue.Key);
	EndDo;
	FillPropertyValues(Result, Selection);

	Return Result;
EndFunction

// Returns an attribute value read from the infobase by object reference.
// 
// If access to the attribute is denied, an exception is raised.
// To be able to read the attribute value irrespective of current user rights,
// turn privileged mode on.
// 
// Parameters:
// Ref - AnyRef- reference to a catalog, a document, or any other infobase object;
// AttributeName - String, for example, "Code".
// 
// Returns:
// Arbitrary. It depends on the type of the read attribute.
//
Function GetAttributeValue(Ref, AttributeName) Export
	
	Result = GetAttributeValues(Ref, AttributeName);
	Return Result[AttributeName];
	
EndFunction 

// Returns a map that contains attribute values of several objects read from the infobase.
// 
//
// If access to any of the attributes is denied, an exception is raised.
// To be able to read attribute values irrespective of current user rights,
// turn privileged mode on.
// 
// Parameters:
// RefArray - array of references to objects of the same type (it is important
// that all referenced objects have the same type);
//
// AttributeNames - String - it must contains attribute names separated by commas.
// 			These attributes will be used for keys in the resulting structures.
// 			Example: "Code, Description, Parent".
// 
// Returns:
// Map where keys are object references, and values are structures that contains
// 			AttributeNames as keys and attribute values as values.
//
Function ObjectAttributeValues(RefArray, AttributeNames) Export
	
	AttributeValues = New Map;
	If RefArray.Count() = 0 Then
		Return AttributeValues;
	EndIf;
	
	Query = New Query;
	Query.Text =
		"SELECT
		|	Ref, " + AttributeNames + "
		|FROM
		|	" + RefArray[0].Metadata().FullName() + " AS Table
		|WHERE
		|	Table.Ref IN (&RefArray)";
	Query.SetParameter("RefArray", RefArray);
	
	Selection = Query.Execute().Choose();
	While Selection.Next() Do
		Result = New Structure(AttributeNames);
		FillPropertyValues(Result, Selection);
		AttributeValues[Selection.Ref] = Result;
	EndDo;
	
	Return AttributeValues;
	
EndFunction

// Returns values of a specific attribute for several objects read from the infobase.
// 
// If access to the attribute is denied, an exception is raised.
// To be able to read attribute values irrespective of current user rights,
// turn privileged mode on.
// 
// Parameters:
// RefArray - array of references to objects of the same type (it is important that all
// referenced objects have the same type);
// AttributeName - String - for example, "Code".
// 
// Returns:
// Map where keys are object references, and values are attribute values.
//
Function ObjectAttributeValue(RefArray, AttributeName) Export
	
	AttributeValues = ObjectAttributeValues(RefArray, AttributeName);
	For Each Item In AttributeValues Do
		AttributeValues[Item.Key] = Item.Value[AttributeName];
	EndDo;
		
	Return AttributeValues;
	
EndFunction

// Checks whether the documents are posted.
//
// Parameters:
// Documents - Array - documents to be checked.
//
// Returns:
// Array - unposted documents from the Documents array.
//
Function CheckDocumentsPosted(Val Documents) Export
	
	Result = New Array;
	
	QueryPattern = 	
		"SELECT
		|	Document.Ref AS Ref
		|FROM
		|	&DocumentName AS Document
		|WHERE
		|	Document.Ref IN(&DocumentArray)
		|	AND (NOT Document.Posted)";
	
	UnionAllText =
		"
		|
		|UNION ALL
		|
		|";
		
	DocumentNames = New Array;
	For Each Document In Documents Do
		DocumentName = Document.Metadata().FullName();
		If DocumentNames.Find(DocumentName) = Undefined
		 And Metadata.Documents.Contains(Metadata.FindByFullName(DocumentName)) Then	
			DocumentNames.Add(DocumentName);
		EndIf;
	EndDo;
	
	QueryText = "";
	For Each DocumentName In DocumentNames Do
		If Not IsBlankString(QueryText) Then
			QueryText = QueryText + UnionAllText;
		EndIf;
		SubqueryText = StrReplace(QueryPattern, "&DocumentName", DocumentName);
		QueryText = QueryText + SubqueryText;
	EndDo;
		
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("DocumentArray", Documents);
	
	If Not IsBlankString(QueryText) Then
		Result = Query.Execute().Unload().UnloadColumn("Ref");
	EndIf;
	
	Return Result;
	
EndFunction

// Attempts to post the documents.
//
// Parameters:
//	Documents - Array - documents to be posted.
//
// Returns:
//	Array - array of structures with the following fields:
//									Ref - unposted document;
//									ErrorDescription - posting error text.
//
Function PostDocuments(Documents) Export
	
	UnpostedDocuments = New Array;
	
	For Each DocumentRef In Documents Do
		
		CompletedSuccessfully = False;
		DocumentObject = DocumentRef.GetObject();
		If DocumentObject.FillCheck() Then
			Try
				DocumentObject.Write(DocumentWriteMode.Posting);
				CompletedSuccessfully = True;
			Except
				ErrorPresentation = BriefErrorDescription(ErrorInfo());
				ErrorMessageText = NStr("en = 'Error posting the document: %1.'");
				ErrorMessageText = StringFunctionsClientServer.SubstituteParametersInString(ErrorMessageText, ErrorPresentation);
				WriteLogEvent(NStr("en = 'Posting documents before printing.'"),
					EventLogLevel.Information, DocumentObject.Metadata(), DocumentRef, 
					DetailErrorDescription(ErrorInfo()));
			EndTry;
		Else
			ErrorPresentation = NStr("en = 'Document fields are not filled.'");
		EndIf;
		
		If Not CompletedSuccessfully Then
			UnpostedDocuments.Add(New Structure("Ref,ErrorDescription", DocumentRef, ErrorPresentation));
		EndIf;
		
	EndDo;
	
	Return UnpostedDocuments;
	
EndFunction 

// Checks whether there are references to the object in the infobase.
//
// Parameters:
// Ref - Array of AnyRef.
//
// SearchInServiceObjects - Boolean - default value is False.
// If it is set to True, the list of search exceptions for references
// will not be taken into account.
//
// Returns:
// Boolean.
//
Function HasReferencesToObjectInInfoBase(Val RefOrRefArray, Val SearchInServiceObjects = False) Export
	
	SetPrivilegedMode(True);
	
	If TypeOf(RefOrRefArray) = Type("Array") Then
		RefArray = RefOrRefArray;
	Else
		RefArray = New Array;
		RefArray.Add(RefOrRefArray);
	EndIf;
	
	RefsTable = FindByRef(RefArray);
	
	If Not SearchInServiceObjects Then
		
		ServiceObjects = New Array();
		Exceptions = New Array;
		
		For Each ReferenceDetails In RefsTable Do
			If ServiceObjects.Find(ReferenceDetails.Metadata.FullName()) <> Undefined Then
				Exceptions.Add(ReferenceDetails);
			EndIf;
		EndDo;
		
		For Each ExceptionString In Exceptions Do
			RefsTable.Delete(ExceptionString);
		EndDo;
	EndIf;
	
	
	Return RefsTable.Count() > 0;
	
EndFunction

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region Common_server_procedures_and_functions_for_working_with_applied_types_and_value_collections

// Gets a name of the enumeration value (enumeration value is a metadata object).
//
// Parameters:
// Value - enumeration value whose name will be retrieved.
//
// Returns:
// String - name of the enumeration value.
//
Function EnumValueName(Value) Export
	
	MetadataObject = Value.Metadata();
	
	ValueIndex = Enums[MetadataObject.Name].IndexOf(Value);
	
	Return MetadataObject.EnumValues[ValueIndex].Name;
	
EndFunction 

// Fills the destination array with unique values from the source array.
// If an element from the source array is already present, it is not added.
//
// Parameters:
// DestinationArray – Array – array to be filled with unique values;
// SourceArray – Array – array of values for filling DestinationArray.
//
Procedure FillArrayWithUniqueValues(DestinationArray, SourceArray) Export
	
	UniqueValues = New Map;
	
	For Each Value In DestinationArray Do
		UniqueValues.Insert(Value, True);
	EndDo;
	
	For Each Value In SourceArray Do
		If UniqueValues[Value] = Undefined Then
			DestinationArray.Add(Value);
			UniqueValues.Insert(Value, True);
		EndIf;
	EndDo;
	
EndProcedure

// Deletes AttributeArray elements that match to object attribute names from 
// the NoncheckableAttributeArray array.
// The procedure is intended for use in FillCheckProcessing event handlers.
//
// Parameters:
//	AttributeArray - Array of strings that contain names of object attributes;
//	NoncheckableAttributeArray - Array of string that contain names of object attributes
// that are excluded from checking.
//
Procedure DeleteAttributesNotToCheckFromArray(AttributeArray, NoncheckableAttributeArray) Export
	
	For Each ArrayElement In NoncheckableAttributeArray Do
	
		SequenceNumber = AttributeArray.Find(ArrayElement);
		If SequenceNumber <> Undefined Then
			AttributeArray.Delete(SequenceNumber);
		EndIf;
	
	EndDo;
	
EndProcedure

// Converts the value table into an array.
//	Use this function to pass data that is received on the server as a value table 
//	to the client. This is only possible if all of values
//	from the value table can be passed to the client.
//
//	The resulting array contains structures that duplicate 
//	value table row structures.
//
//	It is recommended that you do not use this procedure to convert value tables
//	with a large number of rows.
//
//	Parameters: 
// ValueTable.
//
//	Returns:
// Array.
//
Function ValueTableToArray(ValueTable) Export
	
	Array = New Array();
	StructureAsString = "";
	CommaRequired = False;
	For Each Column In ValueTable.Columns Do
		If CommaRequired Then
			StructureAsString = StructureAsString + ",";
		EndIf;
		StructureAsString = StructureAsString + Column.Name;
		CommaRequired = True;
	EndDo;
	For Each String In ValueTable Do
		NewRow = New Structure(StructureAsString);
		FillPropertyValues(NewRow, String);
		Array.Add(NewRow);
	EndDo;
	Return Array;

EndFunction

// Creates a structure with properties whose names 
// match the value table column names
// of the passed row, and
// fills this structure with values from the row.
// 
// Parameters:
// ValueTableRow - ValueTableRow.
//
// Returns:
// Structure.
//
Function ValueTableRowToStructure(ValueTableRow) Export
	
	Structure = New Structure;
	For Each Column In ValueTableRow.Owner().Columns Do
		Structure.Insert(Column.Name, ValueTableRow[Column.Name]);
	EndDo;
	
	Return Structure;
	
EndFunction

Function GetStructureKeysAsString(Structure, Separator = ",") Export
	
	Result = "";
	
	For Each Item In Structure Do
		
		SeparatorChar = ?(IsBlankString(Result), "", Separator);
		
		Result = Result + SeparatorChar + Item.Key;
		
	EndDo;
	
	Return Result;
EndFunction

// Gets a string of structure keys separated by the separator character.
//
// Parameters:
//	Structure - Structure - structure whose keys will be converted into a string;
//	Separator - String - separator that will be inserted between the keys.
//
// Returns:
//	String - string of structure keys separated by the separator character.
//
Function StructureKeysToString(Structure, Separator = ",") Export
	
	Result = "";
	
	For Each Item In Structure Do
		
		SeparatorChar = ?(IsBlankString(Result), "", Separator);
		
		Result = Result + SeparatorChar + Item.Key;
		
	EndDo;
	
	Return Result;
EndFunction

// Creates a structure that matches the information register record manager. 
// 
// Parameters:
// RecordManager - InformationRegisterRecordManager;
// RegisterMetadata - information register metadata.
//
Function StructureByRecordManager(RecordManager, RegisterMetadata) Export
	
	RecordAsStructure = New Structure;
	
	If RegisterMetadata.InformationRegisterPeriodicity <> Metadata.ObjectProperties.InformationRegisterPeriodicity.Nonperiodical Then
		RecordAsStructure.Insert("Period", RecordManager.Period);
	EndIf;
	For Each Field In RegisterMetadata.Dimensions Do
		RecordAsStructure.Insert(Field.Name, RecordManager[Field.Name]);
	EndDo;
	For Each Field In RegisterMetadata.Resources Do
		RecordAsStructure.Insert(Field.Name, RecordManager[Field.Name]);
	EndDo;
	For Each Field In RegisterMetadata.Attributes Do
		RecordAsStructure.Insert(Field.Name, RecordManager[Field.Name]);
	EndDo;
	
	Return RecordAsStructure;
	
EndFunction

// Creates an array and copies values from the row collection column into this array.
//
// Parameters:
//	RowCollection - collection where iteration using For each ... In ... Do operator 
//		is available;
//	ColumnName - String - name of the collection field to be retrieved;
//	UniqueValuesOnly - Boolean, optional - if it is True, the resulting array
//	will contain unique values only. 
//
Function UnloadColumn(RowCollection, ColumnName, UniqueValuesOnly = False) Export

	ValueArray = New Array;
	
	UniqueValues = New Map;
	
	For Each CollectionRow In RowCollection Do
		Value = CollectionRow[ColumnName];
		If UniqueValuesOnly And UniqueValues[Value] <> Undefined Then
			Continue;
		EndIf;
		ValueArray.Add(Value);
		UniqueValues.Insert(Value, True);
	EndDo; 
	
	Return ValueArray;
	
EndFunction

// Converts XML text into a value table.
// The function creates table columns based on the XML description.
//
// Parameters:
// XMLText - text in the XML format.
//
// XML schema:
//<?xml version="1.0" encoding="utf-8"?>
//<xs:schema attributeFormDefault="unqualified" elementFormDefault="qualified" xmlns:xs="http://www.w3.org/2001/XMLSchema">
// <xs:element name="Items">
//	<xs:complexType>
//	 <xs:sequence>
//		<xs:element maxOccurs="unbounded" name="Item">
//		 <xs:complexType>
//			<xs:attribute name="Code" type="xs:integer" use="required" />
//			<xs:attribute name="Name" type="xs:string" use="required" />
//			<xs:attribute name="Abbreviation" type="xs:string" use="required" />
//			<xs:attribute name="PostalCode" type="xs:string" use="required" />
//		 </xs:complexType>
//		</xs:element>
//	 </xs:sequence>
//	 <xs:attribute name="Description" type="xs:string" use="required" />
//	 <xs:attribute name="Columns" type="xs:string" use="required" />
//	</xs:complexType>
// </xs:element>
//</xs:schema>
//
// See examples of XML files in the demo configuration.
// 
// Example:
// ClassifierTable = ReadXMLToTable(InformationRegisters.AddressClassifier.
// GetTemplate("AddressClassifierUnits").GetText());
//
// Returns:
// ValueTable.
//
Function ReadXMLToTable(XMLText) Export
	
	Reader = New XMLReader;
	Reader.SetString(XMLText);
	
	// Reading the first node and checking it
	If Not Reader.Read() Then
		Raise("XML is empty.");
	ElsIf Reader.Name <> "Items" Then
		Raise("Error in the XML structure.");
	EndIf;
	
	// Getting table details and creating the table
	TableName = Reader.GetAttribute("Description");
	ColumnNames = StrReplace(Reader.GetAttribute("Columns"), ",", Chars.LF);
	Columns = StrLineCount(ColumnNames);
	
	ValueTable = New ValueTable;
	For Cnt = 1 to Columns Do
		ValueTable.Columns.Add(StrGetLine(ColumnNames, Cnt), New TypeDescription("String"));
	EndDo;
	
	// Filling the table with values
	While Reader.Read() Do
		
		If Reader.NodeType <> XMLNodeType.StartElement Then
			Continue;
		ElsIf Reader.Name <> "Item" Then
			Raise("Error in the XML structure.");
		EndIf;
		
		NewRow = ValueTable.Add();
		For Cnt = 1 to Columns Do
			ColumnName = StrGetLine(ColumnNames, Cnt);
			NewRow[Cnt-1] = Reader.GetAttribute(ColumnName);
		EndDo;
		
	EndDo;
	
	// Filling the resulting value table
	Result = New Structure;
	Result.Insert("TableName", TableName);
	Result.Insert("Data", ValueTable);
	
	Return Result;
	
EndFunction

// Compares two row collections. 
// Both collections must meet the following requirements:
//	- iteration using For each ... In ... Do operator is available;
//	- both collections include all columns that are passed to the ColumnNames parameter.
// If ColumnNames is empty, all columns included in one of the collections must be included 
// into the other one and vice versa.
//
// Parameters:
//	RowsCollection1 - collection that meets the requirements listed above;
//	RowsCollection2 - collection that meets the requirements listed above;
//	ColumnNames - String separated by commas - names of columns 
//						whose values will be compared. 
//						This parameter is optional for collections
//						that allow retrieving their column names:
//						ValueTable, ValueList, Map, and Structure.
//						If this parameter is not specified, values of all columns
//						will be compared. For collections of other types,
//						this parameter is mandatory.
//	ExcludingColumns	- names of columns whose values are not compared. Optional.
//	IncludingRowOrder - Boolean - If it is True, the collections are considered 
//						equal only if they have identical row order.
//
Function IdenticalCollections(RowsCollection1, RowsCollection2, ColumnNames = "", ExcludingColumns = "", IncludingRowOrder = False) Export
	
	// Collection types that allow retrieving their column names
	SpecialCollectionTypes = New Array;
	SpecialCollectionTypes.Add(Type("ValueTable"));
	SpecialCollectionTypes.Add(Type("ValueList"));
	
	KeyAndValueCollectionTypes = New Array;
	KeyAndValueCollectionTypes.Add(Type("Map"));
	KeyAndValueCollectionTypes.Add(Type("Structure"));
	KeyAndValueCollectionTypes.Add(Type("FixedMap"));
	KeyAndValueCollectionTypes.Add(Type("FixedStructure"));
	
	If IsBlankString(ColumnNames) Then
		If SpecialCollectionTypes.Find(TypeOf(RowsCollection1)) <> Undefined 
			Or KeyAndValueCollectionTypes.Find(TypeOf(RowsCollection1)) <> Undefined Then
			ColumnsToCompare = New Array;
			If TypeOf(RowsCollection1) = Type("ValueTable") Then
				For Each Column In RowsCollection1.Columns Do
					ColumnsToCompare.Add(Column.Name);
				EndDo;
			ElsIf TypeOf(RowsCollection1) = Type("ValueList") Then
				ColumnsToCompare.Add("Value");
				ColumnsToCompare.Add("Picture");
				ColumnsToCompare.Add("Check");
				ColumnsToCompare.Add("Presentation");
			ElsIf KeyAndValueCollectionTypes.Find(TypeOf(RowsCollection1)) <> Undefined Then
				ColumnsToCompare.Add("Key");
				ColumnsToCompare.Add("Value");
			EndIf;
		Else
			ErrorMessage = NStr("en = 'For collections of the %1 type, you have to specify names of fields that will be compared.'");
			Raise StringFunctionsClientServer.SubstituteParametersInString(ErrorMessage, TypeOf(RowsCollection1));
		EndIf;
	Else
		ColumnsToCompare = StringFunctionsClientServer.SplitStringIntoSubstringArray(ColumnNames);
	EndIf;

	// Removing excluded columns
	ColumnsToCompare = CommonUseClientServer.ReduceArray(ColumnsToCompare, 
					   StringFunctionsClientServer.SplitStringIntoSubstringArray(ExcludingColumns));
						
	If IncludingRowOrder Then
		
		// Iterating both collections in parallel
		CollectionRowNumber1 = 0;
		For Each CollectionRow1 In RowsCollection1 Do
			// Searching for the same row in the second collection
			CollectionRowNumber2 = 0;
			HasCollectionRows2 = False;
			For Each CollectionRow2 In RowsCollection2 Do
				HasCollectionRows2 = True;
				If CollectionRowNumber2 = CollectionRowNumber1 Then
					Break;
				EndIf;
				CollectionRowNumber2 = CollectionRowNumber2 + 1;
			EndDo;
			If Not HasCollectionRows2 Then
				// Second collection has no rows
				Return False;
			EndIf;
			// Comparing field values for two rows
			For Each ColumnName In ColumnsToCompare Do
				If CollectionRow1[ColumnName] <> CollectionRow2[ColumnName] Then
					Return False;
				EndIf;
			EndDo;
			CollectionRowNumber1 = CollectionRowNumber1 + 1;
		EndDo;
		
		CollectionRowCount1 = CollectionRowNumber1;
		
		// Calculating rows in the second collection
		CollectionRowCount2 = 0;
		For Each CollectionRow2 In RowsCollection2 Do
			CollectionRowCount2 = CollectionRowCount2 + 1;
		EndDo;
		
		// If the first collection has no rows, 
		// the second collection must have no rows too.
		If CollectionRowCount1 = 0 Then
			For Each CollectionRow2 In RowsCollection2 Do
				Return False;
			EndDo;
			CollectionRowCount2 = 0;
		EndIf;
		
		// Number of rows must be the same in both collections
		If CollectionRowCount1 <> CollectionRowCount2 Then
			Return False;
		EndIf;
		
	Else
	
		// Compares two row collections without taking row order into account.
		
		// Accumulating compared rows in the first collection to ensure that:
		// - the search for identical rows is only performed once,
		// - all accumulated rows exist in the second collection.
		
		FilterRows = New ValueTable;
		FilterParameters = New Structure;
		For Each ColumnName In ColumnsToCompare Do
			FilterRows.Columns.Add(ColumnName);
			FilterParameters.Insert(ColumnName);
		EndDo;
		
		HasCollectionRows1 = False;
		For Each FilterRow In RowsCollection1 Do
			
			FillPropertyValues(FilterParameters, FilterRow);
			If FilterRows.FindRows(FilterParameters).Count() > 0 Then
				// Row with such field values is already checked
				Continue;
			EndIf;
			FillPropertyValues(FilterRows.Add(), FilterRow);
			
			// Calculating rows in the first collection
			CollectionRowsFound1 = 0;
			For Each CollectionRow1 In RowsCollection1 Do
				RowFits = True;
				For Each ColumnName In ColumnsToCompare Do
					If CollectionRow1[ColumnName] <> FilterRow[ColumnName] Then
						RowFits = False;
						Break;
					EndIf;
				EndDo;
				If RowFits Then
					CollectionRowsFound1 = CollectionRowsFound1 + 1;
				EndIf;
			EndDo;
			
			// Calculating rows in the second collection
			CollectionRowsFound2 = 0;
			For Each CollectionRow2 In RowsCollection2 Do
				RowFits = True;
				For Each ColumnName In ColumnsToCompare Do
					If CollectionRow2[ColumnName] <> FilterRow[ColumnName] Then
						RowFits = False;
						Break;
					EndIf;
				EndDo;
				If RowFits Then
					CollectionRowsFound2 = CollectionRowsFound2 + 1;
					// If the number of rows in the second collection is greater then the number of 
					// rows in the first one, the collections are not equal.
					If CollectionRowsFound2 > CollectionRowsFound1 Then
						Return False;
					EndIf;
				EndIf;
			EndDo;
			
			// The number of rows must be equal for both collections
			If CollectionRowsFound1 <> CollectionRowsFound2 Then
				Return False;
			EndIf;
			
			HasCollectionRows1 = True;
			
		EndDo;
		
		// If the first collection has no rows, 
		// the second collection must have no rows too.
		If Not HasCollectionRows1 Then
			For Each CollectionRow2 In RowsCollection2 Do
				Return False;
			EndDo;
		EndIf;
		
		// Checking that all rows from the second collection exist in the first one.
		For Each CollectionRow2 In RowsCollection2 Do
			FillPropertyValues(FilterParameters, CollectionRow2);
			If FilterRows.FindRows(FilterParameters).Count() = 0 Then
				Return False;
			EndIf;
		EndDo;
	
	EndIf;
	
	Return True;
	
EndFunction

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region Math_procedures_and_functions

// Distributes the amount according to the weight coefficients.
//
// Parameters:
//		SrcAmount - amount to be distributed; 
//		CoeffArray - array of weight coefficients; 
//		Precision - rounding precision. Optional.
//
//	Returns:
//		AmountArray - Array - array that has the same length as the coefficient array 
//			dimension. It contains amounts calculated according to the distribution coefficients
// If distribution cannot be performed (amount = 0, number of coefficients = 0,
// or coefficient sum = 0), the return value is Undefined.
//
Function DistributeAmountProportionallyCoefficients(Val SrcAmount, CoeffArray, Val Precision = 2) Export
	
	If CoeffArray.Count() = 0 Or Not ValueIsFilled(SrcAmount) Then
		Return Undefined;
	EndIf;
	
	MaxIndex = 0;
	MaxVal = 0;
	DistribAmount = 0;
	AmountCoeff = 0;
	
	For K = 0 to CoeffArray.Count() - 1 Do
		
		AbsNumber = ?(CoeffArray[K] > 0, CoeffArray[K], - CoeffArray[K]);
		
		If MaxVal < AbsNumber Then
			MaxVal = AbsNumber;
			MaxIndex = K;
		EndIf;
		
		AmountCoeff = AmountCoeff + CoeffArray[K];
		
	EndDo;
	
	If AmountCoeff = 0 Then
		Return Undefined;
	EndIf;
	
	AmountArray = New Array(CoeffArray.Count());
	
	For K = 0 to CoeffArray.Count() - 1 Do
		AmountArray[K] = Round(SrcAmount * CoeffArray[K] / AmountCoeff, Precision, 1);
		DistribAmount = DistribAmount + AmountArray[K];
	EndDo;
	
	// Adding rounding error to the AmountArray element with maximum weight.
	If Not DistribAmount = SrcAmount Then
		AmountArray[MaxIndex] = AmountArray[MaxIndex] + SrcAmount - DistribAmount;
	EndIf;
	
	Return AmountArray;
	
EndFunction

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region Procedures_and_functions_for_working_with_external_connections

// Returns the COM class name for establishing connection to 1C:Enterprise.
//
Function COMConnectorName() Export
	
	SystemInfo = New SystemInfo;
	VersionSubstrings = StringFunctionsClientServer.SplitStringIntoSubstringArray(
		SystemInfo.AppVersion, ".");
	Return "v" + VersionSubstrings[0] + VersionSubstrings[1] + ".COMConnector";
	
EndFunction	

// Establishes an external connection to an infobase by passed connection parameters,
// and returns this connection.
// 
// Parameters:
// Parameters - Structure - contains parameters for establishing an external connection to an infobase.
// The structure must contain the following keys (see the CommonUseClientServer.ExternalConnectionParameterStructure function for details):
//
//	 InfoBaseOperationMode - Number - infobase operation mode: 0 for the file mode, 1 for the client/server mode;
//	 InfoBaseDirectory - String - infobase directory, used in the file mode;
//	 PlatformServerName - String - platform server name, used in the client/server mode;
//	 InfoBaseNameAtPlatformServer - String - infobase name at the platform server;
//	 OSAuthorization - Boolean - flag that shows whether the infobase user is selected based on the operating system user;
//	 UserName - String - infobase user name;
//	 UserPassword - String - infobase user password;
// 
// ErrorMessageString – String – optional. If an error occurs when establishing
// an external connection, the error message text is returned to this parameter.
//
// Returns:
// COM object - if the external connection has been established successfully;
// Undefined - if the external connection has not been established.
// 
Function SetExternalConnection(Parameters, ErrorMessageString = "", ErrorAttachingAddIn = False) Export
	
	// The return value (COM object)
	Connection = Undefined;
	
	Try
		COMConnector = New COMObject(COMConnectorName()); // "V82.COMConnector"
	Except
		ErrorMessageString = NStr("en = 'Error while establishing the external connection: %1'");
		ErrorMessageString = StringFunctionsClientServer.SubstituteParametersInString(ErrorMessageString, DetailErrorDescription(ErrorInfo()));
		ErrorAttachingAddIn = True;
		Return Undefined;
	EndTry;
	
	If Parameters.InfoBaseOperationMode = 0 Then
		
		If IsBlankString(Parameters.InfoBaseDirectory) Then
			
			ErrorMessageString = NStr("en = 'The infobase directory is not specified.'");
			Return Undefined;
			
		EndIf;
		
		If Parameters.OSAuthorization Then
			
			ConnectionString = "File = ""&InfoBaseDirectory""";
			
			ConnectionString = StrReplace(ConnectionString, "&InfoBaseDirectory", Parameters.InfoBaseDirectory);
			
		Else
			
			ConnectionString = "File = ""&InfoBaseDirectory""; Usr = ""&UserName""; Pwd = ""&UserPassword""";
			
			ConnectionString = StrReplace(ConnectionString, "&InfoBaseDirectory", Parameters.InfoBaseDirectory);
			ConnectionString = StrReplace(ConnectionString, "&UserName", Parameters.UserName);
			ConnectionString = StrReplace(ConnectionString, "&UserPassword", Parameters.UserPassword);
			
		EndIf;
		
	Else // Client/server mode
		
		If IsBlankString(Parameters.PlatformServerName)
			Or IsBlankString(Parameters.InfoBaseNameAtPlatformServer) Then
			
			ErrorMessageString = NStr("en = 'The mandatory connection parameters (server name and infobase name)are not specified.'");
			Return Undefined;
			
		EndIf;
		
		If Parameters.OSAuthorization Then
			
			ConnectionString = "Srvr = &PlatformServerName; Ref = &InfoBaseNameAtPlatformServer";
			
			ConnectionString = StrReplace(ConnectionString, "&PlatformServerName", Parameters.PlatformServerName);
			ConnectionString = StrReplace(ConnectionString, "&InfoBaseNameAtPlatformServer", Parameters.InfoBaseNameAtPlatformServer);
			
		Else
			
			ConnectionString = "Srvr = &PlatformServerName; Ref = &InfoBaseNameAtPlatformServer; Usr = ""&UserName""; Pwd = ""&UserPassword""";
			
			ConnectionString = StrReplace(ConnectionString, "&PlatformServerName", Parameters.PlatformServerName);
			ConnectionString = StrReplace(ConnectionString, "&InfoBaseNameAtPlatformServer", Parameters.InfoBaseNameAtPlatformServer);
			ConnectionString = StrReplace(ConnectionString, "&UserName", Parameters.UserName);
			ConnectionString = StrReplace(ConnectionString, "&UserPassword", Parameters.UserPassword);
			
		EndIf;
		
	EndIf;
	
	Try
		Connection = COMConnector.Connect(ConnectionString);
	Except
		
		ErrorAttachingAddIn = True;
		
		DetailErrorDescription = DetailErrorDescription(ErrorInfo());
		
		ErrorMessageString = NStr("en = 'Error establishing the external connection: %1'");
		ErrorMessageString = StringFunctionsClientServer.SubstituteParametersInString(ErrorMessageString, DetailErrorDescription);
		Return Undefined;
	EndTry;
	
	Return Connection;
EndFunction

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region Auxiliary_procedures_and_functions

// Executes the export procedure by name.
//
// Parameters
// ExportProcedureName – String – export procedure name in the following format:
//										 <object name>.<procedure name> where <object name> is 
// 										a common module or an object manager module.
// Parameters - Array - parameters for passing to the <ExportProcedureName> procedure
// ordered by their positions in the array;
// DataArea - Number - data area where the procedure will be executed.
// 
// Example:
// ExecuteSafely("MyCommonModule.MyProcedure"); 
//
Procedure ExecuteSafely(ExportProcedureName, Parameters = Undefined, DataArea = Undefined) Export
	
	// Checking the ExportProcedureName format. 
	NameParts = StringFunctionsClientServer.SplitStringIntoSubstringArray(ExportProcedureName, ".");
	If NameParts.Count() <> 2 And NameParts.Count() <> 3 Then
		Raise StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en = 'Invalid format of the ExportProcedureName parameter %1.'"),
			ExportProcedureName);
	EndIf;

	ObjectName = NameParts[0];
	If NameParts.Count() = 2 And Metadata.CommonModules.Find(ObjectName) = Undefined Then
		Raise StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en = 'Invalid format of the ExportProcedureName parameter %1.'"),
			ExportProcedureName);
	EndIf;
		
	If NameParts.Count() = 3 Then
		ValidTypeNames = New Array;
		ValidTypeNames.Add(Upper(TypeNameConstants()));
		ValidTypeNames.Add(Upper(TypeNameInformationRegisters()));
		ValidTypeNames.Add(Upper(TypeNameAccumulationRegisters()));
		ValidTypeNames.Add(Upper(TypeNameAccountingRegisters()));
		ValidTypeNames.Add(Upper(TypeNameCalculationRegisters()));
		ValidTypeNames.Add(Upper(TypeNameCatalogs()));
		ValidTypeNames.Add(Upper(TypeNameDocuments()));
		ValidTypeNames.Add(Upper(TypeNameReports()));
		ValidTypeNames.Add(Upper(TypeNameDataProcessors()));
		ValidTypeNames.Add(Upper(TypeNameBusinessProcesses()));
		ValidTypeNames.Add(Upper(TypeNameTasks()));
		ValidTypeNames.Add(Upper(TypeNameChartsOfAccounts()));
		ValidTypeNames.Add(Upper(TypeNameExchangePlans()));
		ValidTypeNames.Add(Upper(TypeNameChartsOfCharacteristicTypes()));
		ValidTypeNames.Add(Upper(TypeNameChartsOfCalculationTypes()));
		TypeName = Upper(NameParts[0]);
		If ValidTypeNames.Find(TypeName) = Undefined Then
			Raise StringFunctionsClientServer.SubstituteParametersInString(
				NStr("en = 'Invalid format of the ExportProcedureName parameter %1.'"),
				ExportProcedureName);
		EndIf;
	EndIf;
	
	MethodName = NameParts[NameParts.UBound()];
	TempStructure = New Structure;
	Try
		TempStructure.Insert(MethodName);
	Except
		WriteLogEvent(NStr("en = 'Safe method execution.'"), EventLogLevel.Error, , ,
			DetailErrorDescription(ErrorInfo()));
		Raise StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en = 'Invalid format of the ExportProcedureName parameter %1.'"),
			ExportProcedureName);
	EndTry;
	
	ParametersString = "";
	If Parameters <> Undefined And Parameters.Count() > 0 Then
		For Index = 0 to Parameters.UBound() Do 
			ParametersString = ParametersString + "Parameters[" + Index + "],";
		EndDo;
		ParametersString = Mid(ParametersString, 1, StrLen(ParametersString) - 1);
	EndIf;
	
	Execute ExportProcedureName + "(" + ParametersString + ")";
	
EndProcedure

// Checks the validity of the export procedure name before passing it
// to the Execute operator. If the name is invalid,
// an exception is raised.
//
Function CheckExportProcedureName(Val ExportProcedureName, MessageText) Export
	
	// Checking ExportProcedureName format preconditions
	NameParts = StringFunctionsClientServer.SplitStringIntoSubstringArray(ExportProcedureName, ".");
	If NameParts.Count() <> 2 And NameParts.Count() <> 3 Then
		MessageText = StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en = 'The ExportProcedureName parameter has incorrect format %1.'"),
			ExportProcedureName);
		Return False;
	EndIf;

	ObjectName = NameParts[0];
	If NameParts.Count() = 2 And Metadata.CommonModules.Find(ObjectName) = Undefined Then
		MessageText = StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en = 'The ExportProcedureName parameter has incorrect format %1.'"),
			ExportProcedureName);
		Return False;
	EndIf;
		
	If NameParts.Count() = 3 Then
		ValidTypeNames = New Array;
		ValidTypeNames.Add(Upper(TypeNameConstants()));
		ValidTypeNames.Add(Upper(TypeNameInformationRegisters()));
		ValidTypeNames.Add(Upper(TypeNameAccumulationRegisters()));
		ValidTypeNames.Add(Upper(TypeNameAccountingRegisters()));
		ValidTypeNames.Add(Upper(TypeNameCalculationRegisters()));
		ValidTypeNames.Add(Upper(TypeNameCatalogs()));
		ValidTypeNames.Add(Upper(TypeNameDocuments()));
		ValidTypeNames.Add(Upper(TypeNameBusinessProcesses()));
		ValidTypeNames.Add(Upper(TypeNameTasks()));
		ValidTypeNames.Add(Upper(TypeNameChartsOfAccounts()));
		ValidTypeNames.Add(Upper(TypeNameExchangePlans()));
		ValidTypeNames.Add(Upper(TypeNameChartsOfCharacteristicTypes()));
		ValidTypeNames.Add(Upper(TypeNameChartsOfCalculationTypes()));
		TypeName = Upper(NameParts[0]);
		If ValidTypeNames.Find(TypeName) = Undefined Then
			MessageText = StringFunctionsClientServer.SubstituteParametersInString(
				NStr("en = 'The ExportProcedureName parameter has incorrect format %1.'"),
				ExportProcedureName);
			Return False;
		EndIf;
	EndIf;
	
	Return True;
	
EndFunction

// Resets session parameters to Undefined. 
// 
// Parameters: 
// ClearingParameters - String - names of session parameters to be cleared separated by commas;
// Exceptions - String - names of the session parameters to be preserved separated by commas.
//
Procedure ClearSessionParameters(ClearingParameters = "", Exceptions = "") Export
	
	ExceptionArray = StringFunctionsClientServer.SplitStringIntoSubstringArray(Exceptions);
	ParametersForClearingArray = StringFunctionsClientServer.SplitStringIntoSubstringArray(ClearingParameters);
	
	If ParametersForClearingArray.Count() = 0 Then
		For Each SessionParameter In Metadata.SessionParameters Do
			If ExceptionArray.Find(SessionParameter.Name) = Undefined Then
				ParametersForClearingArray.Add(SessionParameter.Name);
			EndIf;
		EndDo;
	EndIf;
	SessionParameters.Clear(ParametersForClearingArray);
	
EndProcedure

// Returns the value in the XML string format.
// The following value types can be serialized into an XML string with this function: 
// Undefined, Null, Boolean, Number, String, Date, Type, UUID, BinaryData,
// ValueStorage, TypeDescription, data object references and the data 
// objects themselves, sets of register records, and the constant value manager.
//
// Parameters:
// Value – Arbitrary - value to be serialized into an XML string.
//
// Returns:
// String - resulting string.
//
Function ValueToXMLString(Value) Export
	
	XMLWriter = New XMLWriter;
	XMLWriter.SetString();
	XDTOSerializer.WriteXML(XMLWriter, Value, XMLTypeAssignment.Explicit);
	
	Return XMLWriter.Close();
EndFunction

// Returns a value restored from the XML string. 
// The following value types can be restored from the XML string with this function: 
// Undefined, Null, Boolean, Number, String, Date, Type, UUID, BinaryData,
// ValueStorage, TypeDescription, data object references and the data 
// objects themselves, sets of register records, and the constant value manager.
//
// Parameters:
// XMLString – serialized string.
//
// Returns:
// String - resulting string.
//
Function ValueFromXMLString(XMLString) Export
	
	XMLReader = New XMLReader;
	XMLReader.SetString(XMLString);
	
	Return XDTOSerializer.ReadXML(XMLReader);
EndFunction

// Generates a query search string from the source string.
//
// Parameters:
//	SearchString - String - source string that contains characters prohibited in queries. 	
//
// Returns:
// String - resulting string.
//
Function GenerateSearchQueryString(Val SearchString) Export
	
	ResultingSearchString = SearchString;
	ResultingSearchString = StrReplace(ResultingSearchString, "~", "~~");
	ResultingSearchString = StrReplace(ResultingSearchString, "%", "~%");
	ResultingSearchString = StrReplace(ResultingSearchString, "_", "~_");
	ResultingSearchString = StrReplace(ResultingSearchString, "[", "~[");
	ResultingSearchString = StrReplace(ResultingSearchString, "-", "~-");
	
	Return ResultingSearchString;
	
EndFunction

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region Procedures_and_functions_for_working_with_forms

// Fills a form attribute of the ValueTree type.
//
// Parameters:
// TreeItemCollection – form attribute of the ValueTree type;
// 							 It will be filled with values from the ValueTree parameter.
// ValueTree – ValueTree – data for filling TreeItemCollection.
//
Procedure FillFormDataTreeItemCollection(TreeItemCollection, ValueTree) Export
	
	For Each Row In ValueTree.Rows Do
		
		TreeItem = TreeItemCollection.Add();
		
		FillPropertyValues(TreeItem, Row);
		
		If Row.Rows.Count() > 0 Then
			
			FillFormDataTreeItemCollection(TreeItem.GetItems(), Row);
			
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region Procedures_and_functions_for_working_with_types_metadata_objects_and_their_string_presentations

// Gets the configuration metadata tree with the specified filter by metadata objects.
//
// Parameters:
// Filter – Structure – contains filter item values.
//						If this parameter is specified, the metadata tree will be retrieved according to the filter value; 
//						Key - String – metadata item property name;
//						Value - Array – array of filter values.
//
// Example of initializing the Filter variable:
//
// Array = New Array;
// Array.Add("Constant.UseDataExchange");
// Array.Add("Catalog.Currencies");
// Array.Add("Catalog.Companies");
// Filter = New Structure;
// Filter.Insert("FullName", Array);
// 
// Returns:
// ValueTree - configuration metadata tree.
//
Function GetConfigurationMetadataTree(Filter = Undefined) Export
	
	UseFilter = (Filter <> Undefined);
	
	MetadataObjectCollections = New ValueTable;
	MetadataObjectCollections.Columns.Add("Name");
	MetadataObjectCollections.Columns.Add("Synonym");
	MetadataObjectCollections.Columns.Add("Picture");
	MetadataObjectCollections.Columns.Add("ObjectPicture");
	
	NewMetadataObjectCollectionRow("Constants", "Constants", PictureLib.Constant, PictureLib.Constant, MetadataObjectCollections);
	NewMetadataObjectCollectionRow("Catalogs", "Catalogs", PictureLib.Catalog, PictureLib.Catalog, MetadataObjectCollections);
	NewMetadataObjectCollectionRow("Documents", "Documents", PictureLib.Document, PictureLib.DocumentObject, MetadataObjectCollections);
	NewMetadataObjectCollectionRow("ChartsOfCharacteristicTypes", "Charts of characteristic types", PictureLib.ChartOfCharacteristicTypes, PictureLib.ChartOfCharacteristicTypesObject, MetadataObjectCollections);
	NewMetadataObjectCollectionRow("ChartsOfAccounts", "Charts of accounts", PictureLib.ChartOfAccounts, PictureLib.ChartOfAccountsObject, MetadataObjectCollections);
	NewMetadataObjectCollectionRow("ChartsOfCalculationTypes", "Charts of calculation types", PictureLib.ChartOfCharacteristicTypes, PictureLib.ChartOfCharacteristicTypesObject, MetadataObjectCollections);
	NewMetadataObjectCollectionRow("InformationRegisters", "Information registers", PictureLib.InformationRegister, PictureLib.InformationRegister, MetadataObjectCollections);
	NewMetadataObjectCollectionRow("AccumulationRegisters", "Accumulation registers", PictureLib.AccumulationRegister, PictureLib.AccumulationRegister, MetadataObjectCollections);
	NewMetadataObjectCollectionRow("AccountingRegisters", "Accounting registers", PictureLib.AccountingRegister, PictureLib.AccountingRegister, MetadataObjectCollections);
	NewMetadataObjectCollectionRow("CalculationRegisters", "Calculation registers", PictureLib.CalculationRegister, PictureLib.CalculationRegister, MetadataObjectCollections);
	NewMetadataObjectCollectionRow("BusinessProcesses", "Business processes", PictureLib.BusinessProcess, PictureLib.BusinessProcessObject, MetadataObjectCollections);
	NewMetadataObjectCollectionRow("Tasks", "Tasks", PictureLib.Task, PictureLib.TaskObject, MetadataObjectCollections);
	
	// The return value 
	MetadataTree = New ValueTree;
	MetadataTree.Columns.Add("Name");
	MetadataTree.Columns.Add("FullName");
	MetadataTree.Columns.Add("Synonym");
	MetadataTree.Columns.Add("Picture");
	
	For Each CollectionRow In MetadataObjectCollections Do
		
		TreeRow = MetadataTree.Rows.Add();
		
		FillPropertyValues(TreeRow, CollectionRow);
		
		For Each MetadataObject In Metadata[CollectionRow.Name] Do
			
			// ============================ {Filter}
			If UseFilter Then
				
				ObjectPassedFilter = True;
				
				For Each FilterItem In Filter Do
					
					Value = ?(Upper(FilterItem.Key) = Upper("FullName"), MetadataObject.FullName(), MetadataObject[FilterItem.Key]);
					
					If FilterItem.Value.Find(Value) = Undefined Then
						
						ObjectPassedFilter = False;
						
						Break;
						
					EndIf;
					
				EndDo;
				
				If Not ObjectPassedFilter Then
					
					Continue;
					
				EndIf;
				
			EndIf;
			// ============================ {Filter}
			
			MOTreeRow = TreeRow.Rows.Add();
			MOTreeRow.Name = MetadataObject.Name;
			MOTreeRow.FullName = MetadataObject.FullName();
			MOTreeRow.Synonym = MetadataObject.Synonym;
			MOTreeRow.Picture = CollectionRow.ObjectPicture;
			
		EndDo;
		
	EndDo;
	
	// Deleting rows that have no subordinate items
	If UseFilter Then
		
		// Using reverse value tree iteration order
		CollectionItemCount = MetadataTree.Rows.Count();
		
		For ReverseIndex = 1 to CollectionItemCount Do
			
			CurrentIndex = CollectionItemCount - ReverseIndex;
			
			TreeRow = MetadataTree.Rows[CurrentIndex];
			
			If TreeRow.Rows.Count() = 0 Then
				
				MetadataTree.Rows.Delete(CurrentIndex);
				
			EndIf;
			
		EndDo;
	
	EndIf;
	
	Return MetadataTree;
	
EndFunction

// Returns detailed information about the configuration 
// (detailed information is a configuration metadata property).
//
// Returns: 
// String - string with detailed information about the configuration.
//
Function GetConfigurationDetails() Export
	
	Return Metadata.DetailedInformation;
	
EndFunction

// Get the infobase presentation for displaying it to the user.
//
// Returns:
// String - infobase presentation. 
//
// Result example:
// - if the infobase operates in the file mode: \\FileServer\1C_ib
// - if the infobase operates in the client/server mode: ServerName:1111 / Information_base_name
//
Function GetInfoBasePresentation() Export
	
	InfoBaseConnectionString = InfoBaseConnectionString();
	
	If CommonUseClientServer.FileInfoBase(InfoBaseConnectionString) Then
		PathToDB = Mid(InfoBaseConnectionString, 6, StrLen(InfoBaseConnectionString) - 6);
	Else
		// Adding the infobase name to the server name 
		SearchPosition = Find(Upper(InfoBaseConnectionString), "SRVR=");
		
		If SearchPosition <> 1 Then
			Return Undefined;
		EndIf;
		
		SemicolonPosition = Find(InfoBaseConnectionString, ";");
		CopyStartPosition = 6 + 1;
		CopyingEndPosition = SemicolonPosition - 2; 
		
		ServerName = Mid(InfoBaseConnectionString, CopyStartPosition, CopyingEndPosition - CopyStartPosition + 1);
		
		InfoBaseConnectionString = Mid(InfoBaseConnectionString, SemicolonPosition + 1);
		
		// Server name position
		SearchPosition = Find(Upper(InfoBaseConnectionString), "REF=");
		
		If SearchPosition <> 1 Then
			Return Undefined;
		EndIf;
		
		CopyStartPosition = 6;
		SemicolonPosition = Find(InfoBaseConnectionString, ";");
		CopyingEndPosition = SemicolonPosition - 2; 
		
		InfoBaseNameAtServer = Mid(InfoBaseConnectionString, CopyStartPosition, CopyingEndPosition - CopyStartPosition + 1);
		
		PathToDB = ServerName + "/ " + InfoBaseNameAtServer;
		
	EndIf;
	
	Return PathToDB;
	
EndFunction

// Returns a string of configuration metadata object attributes of the specified type.
//
// Parameters:
// Ref – AnyRef – reference to the infobase item whose attibutes will be retrieved;
// Type – Type – attribute value type.
// 
// Returns:
// String – string with configuration metadata object attributes separated by commas.
//
Function AttributeNamesByType(Ref, Type) Export
	
	Result = "";
	ObjectMetadata = Ref.Metadata();
	
	For Each Attribute In ObjectMetadata.Attributes Do
		If Attribute.Type.ContainsType(Type) Then
			Result = Result + ?(IsBlankString(Result), "", ", ") + Attribute.Name;
		EndIf;
	EndDo;
	
	Return Result;
EndFunction

// Returns a name of the base type by the passed metadata object value.
//
// Parameters:
// MetadataObject - metadata object for determining the base type.
// 
// Returns:
// String - base type name.
//
Function BaseTypeNameByMetadataObject(MetadataObject) Export
	
	If Metadata.Documents.Contains(MetadataObject) Then
		Return TypeNameDocuments();
		
	ElsIf Metadata.Catalogs.Contains(MetadataObject) Then
		Return TypeNameCatalogs();
		
	ElsIf Metadata.Enums.Contains(MetadataObject) Then
		Return TypeNameEnums();
		
	ElsIf Metadata.InformationRegisters.Contains(MetadataObject) Then
		Return TypeNameInformationRegisters();
		
	ElsIf Metadata.AccumulationRegisters.Contains(MetadataObject) Then
		Return TypeNameAccumulationRegisters();
		
	ElsIf Metadata.AccountingRegisters.Contains(MetadataObject) Then
		Return TypeNameAccountingRegisters();
		
	ElsIf Metadata.CalculationRegisters.Contains(MetadataObject) Then
		Return TypeNameCalculationRegisters();
		
	ElsIf Metadata.ExchangePlans.Contains(MetadataObject) Then
		Return TypeNameExchangePlans();
		
	ElsIf Metadata.ChartsOfCharacteristicTypes.Contains(MetadataObject) Then
		Return TypeNameChartsOfCharacteristicTypes();
		
	ElsIf Metadata.BusinessProcesses.Contains(MetadataObject) Then
		Return TypeNameBusinessProcesses();
		
	ElsIf Metadata.Tasks.Contains(MetadataObject) Then
		Return TypeNameTasks();
		
	ElsIf Metadata.ChartsOfAccounts.Contains(MetadataObject) Then
		Return TypeNameChartsOfAccounts();
		
	ElsIf Metadata.ChartsOfCalculationTypes.Contains(MetadataObject) Then
		Return TypeNameChartsOfCalculationTypes();
		
	ElsIf Metadata.Constants.Contains(MetadataObject) Then
		Return TypeNameConstants();
		
	ElsIf Metadata.DocumentJournals.Contains(MetadataObject) Then
		Return TypeNameDocumentJournals();
		
	Else
		
		Return "";
		
	EndIf;
	
EndFunction

// Returns an object manager by the full metadata object name.
//
// This function does not process business process route points.
//
// Parameters:
// FullName - String - metadata object full name,
// for example: "Catalog.Companies".
//
// Returns:
// ObjectManager (CatalogManager, DocumentManager, and so on). 
//
Function ObjectManagerByFullName(FullName) Export
	
	NameParts = StringFunctionsClientServer.SplitStringIntoSubstringArray(FullName, ".");
	
	MOClass = NameParts[0];
	MOName = NameParts[1];
	
	If Upper(MOClass) = "EXCHANGEPLAN" Then
		Return ExchangePlans[MOName];
		
	ElsIf Upper(MOClass) = "CATALOG" Then
		Return Catalogs[MOName];
		
	ElsIf Upper(MOClass) = "DOCUMENT" Then
		Return Documents[MOName];
		
	ElsIf Upper(MOClass) = "DOCUMENTJOURNAL" Then
		Return DocumentJournals[MOName];
		
	ElsIf Upper(MOClass) = "ENUM" Then
		Return Enums[MOName];
		
	ElsIf Upper(MOClass) = "REPORT" Then
		Return Reports[MOName];
		
	ElsIf Upper(MOClass) = "DATAPROCESSOR" Then
		Return DataProcessors[MOName];
		
	ElsIf Upper(MOClass) = "CHARTOFCHARACTERISTICTYPES" Then
		Return ChartsOfCharacteristicTypes[MOName];
		
	ElsIf Upper(MOClass) = "CHARTOFACCOUNTS" Then
		Return ChartsOfAccounts[MOName];
		
	ElsIf Upper(MOClass) = "CHARTOFCALCULATIONTYPES" Then
		Return ChartsOfCalculationTypes[MOName];
		
	ElsIf Upper(MOClass) = "INFORMATIONREGISTER" Then
		Return InformationRegisters[MOName];
		
	ElsIf Upper(MOClass) = "ACCUMULATIONREGISTER" Then
		Return AccumulationRegisters[MOName];
		
	ElsIf Upper(MOClass) = "ACCOUNTINGREGISTER" Then
		Return AccountingRegisters[MOName];
		
	ElsIf Upper(MOClass) = "CALCULATIONREGISTER" Then
		Return CalculationRegisters[MOName];
		
	ElsIf Upper(MOClass) = "BUSINESSPROCESS" Then
		Return BusinessProcesses[MOName];
		
	ElsIf Upper(MOClass) = "TASK" Then
		Return Tasks[MOName];
	Else
		Raise StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en = 'Unknown type of metadata object %1.'"), MOClass);
	EndIf;
	
EndFunction

// Returns an object manager by the object reference.
//
// This function does not process business process route points.
//
// Parameters:
// Ref - Reference - object reference (catalog item, document, and so on).
//
// Returns:
// ObjectManager (CatalogManager, DocumentManager, and so on). 
//
Function ObjectManagerByRef(Ref) Export
	
	ObjectName = Ref.Metadata().Name;
	ReferenceType = TypeOf(Ref);
	
	If Catalogs.AllRefsType().ContainsType(ReferenceType) Then
		Return Catalogs[ObjectName];
		
	ElsIf Documents.AllRefsType().ContainsType(ReferenceType) Then
		Return Documents[ObjectName];
		
	ElsIf BusinessProcesses.AllRefsType().ContainsType(ReferenceType) Then
		Return BusinessProcesses[ObjectName];
		
	ElsIf ChartsOfCharacteristicTypes.AllRefsType().ContainsType(ReferenceType) Then
		Return ChartsOfCharacteristicTypes[ObjectName];
		
	ElsIf ChartsOfAccounts.AllRefsType().ContainsType(ReferenceType) Then
		Return ChartsOfAccounts[ObjectName];
		
	ElsIf ChartsOfCalculationTypes.AllRefsType().ContainsType(ReferenceType) Then
		Return ChartsOfCalculationTypes[ObjectName];
		
	ElsIf Tasks.AllRefsType().ContainsType(ReferenceType) Then
		Return Tasks[ObjectName];
		
	ElsIf ExchangePlans.AllRefsType().ContainsType(ReferenceType) Then
		Return ExchangePlans[ObjectName];
		
	ElsIf Enums.AllRefsType().ContainsType(ReferenceType) Then
		Return Enums[ObjectName];
	Else
		Return Undefined;
	EndIf;
	
EndFunction

// Checks whether the infobase record exists by its reference.
//
// Parameters:
// AnyRef - any infobase reference value.
// 
// Returns:
// True if the record exists;
// False if the record does not exist.
//
Function RefExists(AnyRef) Export
	
	QueryText = "
	|SELECT
	|	Ref
	|FROM
	|	[TableName]
	|WHERE
	|	Ref = &Ref
	|";
	
	QueryText = StrReplace(QueryText, "[TableName]", TableNameByRef(AnyRef));
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Ref", AnyRef);
	
	SetPrivilegedMode(True);
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

// Checks whether the only one reference exists for passed reference type.
//
// Parameters:
// Type - applied object type.
// 
// Returns:
// Ref if the record exists and only one;
// Undefined if the record does not exist, or more then one exist.
//
Function RefIfOnlyOne(Type) Export
	
	QueryText = "
	|SELECT ALLOWED TOP 2
	|	Ref
	|FROM
	|	[TableName]
	|WHERE
	|	NOT DeletionMark";
	
	QueryText = StrReplace(QueryText, "[TableName]", TableNameByType(Type));
	
	Query = New Query;
	Query.Text = QueryText;
	
	Selection = Query.Execute().Choose();
	If Selection.Count() = 1 Then
		Selection.Next();
		Return Selection.Ref;
	Else
		Return Undefined;
	EndIf;
	
EndFunction

// Returns a metadata object kind name 
// by the object reference.
//
// This function does not process business process route points.
//
// Parameters:
// Ref - Reference - object reference (catalog item, document, and so on).
//
// Returns:
// String - metadata object kind name ("Catalog", "Document", and so on).
//
Function ObjectKindByRef(Ref) Export
	
	Return ObjectKindByType(TypeOf(Ref));
	
EndFunction 

// Returns a metadata object kind name by the object type.
//
// This function does not process business process route points.
//
// Parameters:
// Type - applied object type.
//
// Returns:
// String - metadata object kind name ("Catalog", "Document", and so on).
//
Function ObjectKindByType(Type) Export
	
	If Catalogs.AllRefsType().ContainsType(Type) Then
		Return "Catalog";
	
	ElsIf Documents.AllRefsType().ContainsType(Type) Then
		Return "Document";
	
	ElsIf BusinessProcesses.AllRefsType().ContainsType(Type) Then
		Return "BusinessProcess";
	
	ElsIf ChartsOfCharacteristicTypes.AllRefsType().ContainsType(Type) Then
		Return "ChartOfCharacteristicTypes";
	
	ElsIf ChartsOfAccounts.AllRefsType().ContainsType(Type) Then
		Return "ChartOfAccounts";
	
	ElsIf ChartsOfCalculationTypes.AllRefsType().ContainsType(Type) Then
		Return "ChartOfCalculationTypes";
	
	ElsIf Tasks.AllRefsType().ContainsType(Type) Then
		Return "Task";
	
	ElsIf ExchangePlans.AllRefsType().ContainsType(Type) Then
		Return "ExchangePlan";
	
	ElsIf Enums.AllRefsType().ContainsType(Type) Then
		Return "Enumeration";
	
	Else
		Raise StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en = 'Invalid parameter value type %1.'"), String(Type));
	
	EndIf;
	
EndFunction 

// Returns full metadata object name by the passed reference value.
// Example:
// "Catalog.Items";
// "Document.Invoice".
//
// Parameters:
// Ref - AnyRef - value of the reference whose infobase table name will be retrieved.
// 
// Returns:
// String - full metadata object name.
//
Function TableNameByRef(Ref) Export
	
	Return Ref.Metadata().FullName();
	
EndFunction

// Returns full metadata object name by the passed type.
//
// Example:
// "Catalog.Items";
// "Document.Invoice".
//
// Parameters:
// Type - applied object type.
// 
// Returns:
// String - full metadata object name.
//
Function TableNameByType(Type) Export
	
	Return Metadata.FindByType(Type).FullName();
	
EndFunction

// Checks whether the value has a reference type.
//
// Parameters:
// Value - Any;
//
// Returns:
// Boolean - True if the value has a reference type.
//
Function ReferenceTypeValue(Value) Export
	
	If Value = Undefined Then
		Return False;
	EndIf;
	
	If Catalogs.AllRefsType().ContainsType(TypeOf(Value)) Then
		Return True;
	EndIf;
	
	If Documents.AllRefsType().ContainsType(TypeOf(Value)) Then
		Return True;
	EndIf;
	
	If Enums.AllRefsType().ContainsType(TypeOf(Value)) Then
		Return True;
	EndIf;
	
	If ChartsOfCharacteristicTypes.AllRefsType().ContainsType(TypeOf(Value)) Then
		Return True;
	EndIf;
	
	If ChartsOfAccounts.AllRefsType().ContainsType(TypeOf(Value)) Then
		Return True;
	EndIf;
	
	If ChartsOfCalculationTypes.AllRefsType().ContainsType(TypeOf(Value)) Then
		Return True;
	EndIf;
	
	If BusinessProcesses.AllRefsType().ContainsType(TypeOf(Value)) Then
		Return True;
	EndIf;
	
	If BusinessProcesses.RoutePointsAllRefsType().ContainsType(TypeOf(Value)) Then
		Return True;
	EndIf;
	
	If Tasks.AllRefsType().ContainsType(TypeOf(Value)) Then
		Return True;
	EndIf;
	
	If ExchangePlans.AllRefsType().ContainsType(TypeOf(Value)) Then
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

// Checks whether the type is a reference type.
//
Function IsReference(Type) Export
	
	Return Catalogs.AllRefsType().ContainsType(Type)
		Or Documents.AllRefsType().ContainsType(Type)
		Or Enums.AllRefsType().ContainsType(Type)
		Or ChartsOfCharacteristicTypes.AllRefsType().ContainsType(Type)
		Or ChartsOfAccounts.AllRefsType().ContainsType(Type)
		Or ChartsOfCalculationTypes.AllRefsType().ContainsType(Type)
		Or BusinessProcesses.AllRefsType().ContainsType(Type)
		Or BusinessProcesses.RoutePointsAllRefsType().ContainsType(Type)
		Or Tasks.AllRefsType().ContainsType(Type)
		Or ExchangePlans.AllRefsType().ContainsType(Type);
	
EndFunction

// Checks whether the object is a folder.
//
// Parameters:
// Object - items belonging to catalogs or charts of characteristic types only.
//
Function ObjectIsFolder(Object) Export
	
	ObjectMetadata = Object.Metadata();
	
	If IsCatalog(ObjectMetadata)
	And Not (ObjectMetadata.Hierarchical And ObjectMetadata.HierarchyType = Metadata.ObjectProperties.HierarchyType.HierarchyFoldersAndItems) Then
		Return False;
	EndIf;
	
	If ReferenceTypeValue(Object) Then
		Return Object.IsFolder;
	EndIf;
	
	Ref = Object.Ref;
	
	If Not ValueIsFilled(Ref) Then
		Return False;
	EndIf;
	
	Return GetAttributeValue(Ref, "IsFolder");
	
EndFunction

// Returns a string presentation of the type. 
// In case of reference types the function returns a presentation in the following format: "CatalogRef.ObjectName" or "DocumentRef.ObjectName".
// For other types it transforms the type to a string, for example, "Number".
//
Function TypePresentationString(Type) Export
	
	Presentation = "";
	
	If IsReference(Type) Then
	
		FullName = Metadata.FindByType(Type).FullName();
		ObjectName = StringFunctionsClientServer.SplitStringIntoSubstringArray(FullName, ".")[1];
		
		If Catalogs.AllRefsType().ContainsType(Type) Then
			Presentation = "CatalogRef";
		
		ElsIf Documents.AllRefsType().ContainsType(Type) Then
			Presentation = "DocumentRef";
		
		ElsIf BusinessProcesses.AllRefsType().ContainsType(Type) Then
			Presentation = "BusinessProcessRef";
		
		ElsIf ChartsOfCharacteristicTypes.AllRefsType().ContainsType(Type) Then
			Presentation = "ChartOfCharacteristicTypesRef";
		
		ElsIf ChartsOfAccounts.AllRefsType().ContainsType(Type) Then
			Presentation = "ChartOfAccountsRef";
		
		ElsIf ChartsOfCalculationTypes.AllRefsType().ContainsType(Type) Then
			Presentation = "ChartOfCalculationTypesRef";
		
		ElsIf Tasks.AllRefsType().ContainsType(Type) Then
			Presentation = "TaskRef";
		
		ElsIf ExchangePlans.AllRefsType().ContainsType(Type) Then
			Presentation = "ExchangePlanRef";
		
		ElsIf Enums.AllRefsType().ContainsType(Type) Then
			Presentation = "EnumRef";
		
		EndIf;
		
		Result = ?(Presentation = "", Presentation, Presentation + "." + ObjectName);
		
	Else
		
		Result = String(Type);
		
	EndIf;
	
	Return Result;
	
EndFunction

// Checks whether the type description contains only one value type and it 
// is equal to the specified type.
//
// Returns:
// Boolean.
//
Function TypeDescriptionContainsType(TypeDescription, ValueType) Export
	
	If TypeDescription.Types().Count() = 1
	 And TypeDescription.Types().Get(0) = ValueType Then
		Return True;
	EndIf;
	
	Return False;

EndFunction

// Checks whether the catalog has the tabular section.
//
//Parameters
// CatalogName - String - name of the catalog to be checked.
// TabularSectionName - String - name of the tabular section whose existence will be checked.
//
//Returns:
// Boolean - True if the catalog has the tabular section, otherwise is False.
//
//Example:
// If Not CommonUse.CatalogHasTabularSection(CatalogName, "ContactInformation") Then
// 	Return;
// EndIf;
//
Function CatalogHasTabularSection(CatalogName, TabularSectionName) Export
	
	Return (Metadata.Catalogs[CatalogName].TabularSections.Find(TabularSectionName) <> Undefined);
	
EndFunction 

// Generates an extended object presentation.
// An extended object presentation contains an object presentation, a code, and a description.
// If generating an extended object presentation failed,
// then the function returns a standard object presentation generated by the platform.
//
// An example of the returning value:
// "Counterparty 0A-0001234, Telecom"
//
// Parameters:
// Object. Type: CatalogRef,
//				ChartOfAccountsRef,
//				ExchangePlanRef,
//				ChartOfCharacteristicTypesRef,
//				ChartOfCalculationTypesRef.
// The object whose extended presentation will be generated.
//
// Returns:
// String - extended object presentation.
// 
Function ExtendedObjectPresentation(Object) Export
	
	MetadataObject = Object.Metadata();
	
	BaseTypeName = BaseTypeNameByMetadataObject(MetadataObject);
	
	If BaseTypeName = TypeNameCatalogs()
		Or BaseTypeName = TypeNameChartsOfAccounts()
		Or BaseTypeName = TypeNameExchangePlans()
		Or BaseTypeName = TypeNameChartsOfCharacteristicTypes()
		Or BaseTypeName = TypeNameChartsOfCalculationTypes()
		Then
		
		If IsStandardAttribute(MetadataObject.StandardAttributes, "Code")
			And IsStandardAttribute(MetadataObject.StandardAttributes, "Description") Then
			
			AttributeValues = GetAttributeValues(Object, "Code, Description");
			
			ObjectPresentation = ?(IsBlankString(MetadataObject.ObjectPresentation), 
										?(IsBlankString(MetadataObject.Synonym), MetadataObject.Name, MetadataObject.Synonym
										),
									MetadataObject.ObjectPresentation
			);
			
			Result = "[ObjectPresentation] [Code], [Description]";
			Result = StrReplace(Result, "[ObjectPresentation]", ObjectPresentation);
			Result = StrReplace(Result, "[Code]", ?(IsBlankString(AttributeValues.Code), "<>", AttributeValues.Code));
			Result = StrReplace(Result, "[Description]", ?(IsBlankString(AttributeValues.Description), "<>", AttributeValues.Description));
			
		Else
			
			Result = String(Object);
			
		EndIf;
		
	Else
		
		Result = String(Object);
		
	EndIf;
	
	Return Result;
EndFunction

// Returns a flag that shows whether the attribute is a standard attribute.
//
// Parameters:
// StandardAttributes – StandardAttributeDescriptions - collection whose types and values describe standard attibutes;
// AttributeName – String – attribute to be checked.
// 
// Returns:
// Boolean. True if attribute is a standard attribute, otherwise is False.
//
Function IsStandardAttribute(StandardAttributes, AttributeName) Export
	
	For Each Attribute In StandardAttributes Do
		
		If Attribute.Name = AttributeName Then
			
			Return True;
			
		EndIf;
		
	EndDo;
	
	Return False;
	
EndFunction

// Gets a value table with the required property information of all metadata object attributes.
// Gets property values of standard and custom attributes (Custom attributes are attributes created in the designer mode.)
//
// Parameters:
// MetadataObject - metadata object whose attribute property values will be retrieved.
// For example: Metadata.Document.Invoice;
// Properties - String - attribute properties separated by commas whose values will be retrieved.
// For example: "Name, Type, Synonym, ToolTip".
//
// Returns:
// ValueTable - returning value table.
//
Function GetObjectPropertyInfoTable(MetadataObject, Properties) Export
	
	PropertyArray = StringFunctionsClientServer.SplitStringIntoSubstringArray(Properties);
	
	// The value to be returned
	ObjectPropertyInfoTable = New ValueTable;
	
	// Adding fields to the value table according to the names of the passed properties
	For Each PropertyName In PropertyArray Do
		
		ObjectPropertyInfoTable.Columns.Add(TrimAll(PropertyName));
		
	EndDo;
	
	// Filling table rows with metadata object attribute values
	For Each Attribute In MetadataObject.Attributes Do
		
		FillPropertyValues(ObjectPropertyInfoTable.Add(), Attribute);
		
	EndDo;
	
	// Filling table rows with values of the standard metadata object attributes 
	For Each Attribute In MetadataObject.StandardAttributes Do
		
		FillPropertyValues(ObjectPropertyInfoTable.Add(), Attribute);
		
	EndDo;
	
	Return ObjectPropertyInfoTable;
	
EndFunction

// Returns a common attribute content item usage state.
//
// Parameters:
// ContentItem - MetadataObject - common attribute content item 
// whose usage will be checked;
// CommonAttributeMetadata - MetadataObject - common attribute metadata 
// whose ContentItem usage will be checked.
//
// Returns:
// Boolean - True if the content item is used, otherwise is False.
//
Function CommonAttributeContentItemUsed(Val ContentItem, Val CommonAttributeMetadata) Export
	
	If ContentItem.Use = Metadata.ObjectProperties.CommonAttributeUse.Use Then
		Return True;
	ElsIf ContentItem.Use = Metadata.ObjectProperties.CommonAttributeUse.DontUse Then
		Return False;
	Else
		Return CommonAttributeMetadata.AutoUse = Metadata.ObjectProperties.CommonAttributeAutoUse.Use;
	EndIf;
	
EndFunction

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region Functions_for_working_with_metadata_object_type_definition

//------------------------------------------------------------------------------
// Reference data types.

// Checks whether the metadata object belongs to the Document type.
//
// Parameters:
// MetadataObject – metadata object to be checked.
// 
// Returns:
// Boolean - True if the metadata object belongs to the specified type, otherwise is False.
//
Function IsDocument(MetadataObject) Export
	
	Return BaseTypeNameByMetadataObject(MetadataObject) = TypeNameDocuments();
	
EndFunction

// Checks whether the metadata object belongs to the Catalog type.
//
// Parameters:
// MetadataObject – metadata object to be checked.
// 
// Returns:
// Boolean - True if the metadata objects belongs to the specified type, otherwise is False.
//
Function IsCatalog(MetadataObject) Export
	
	Return BaseTypeNameByMetadataObject(MetadataObject) = TypeNameCatalogs();
	
EndFunction

// Checks whether the metadata object belongs to the Enumeration type.
// 
// Parameters:
// MetadataObject – metadata object to be checked.
// 
// Returns:
// Boolean - True if the metadata objects belongs to the specified type, otherwise is False.
//
Function IsEnum(MetadataObject) Export
	
	Return BaseTypeNameByMetadataObject(MetadataObject) = TypeNameEnums();
	
EndFunction

// Checks whether the metadata object belongs to the Exchange plan type.
// 
// Parameters:
// MetadataObject – metadata object to be checked.
// 
// Returns:
// Boolean - True if the metadata objects belongs to the specified type, otherwise is False.
//
Function IsExchangePlan(MetadataObject) Export
	
	Return BaseTypeNameByMetadataObject(MetadataObject) = TypeNameExchangePlans();
	
EndFunction

// Checks whether the metadata object belongs to the Chart of characteristic types type.
// 
// Parameters:
// MetadataObject – metadata object to be checked.
// 
// Returns:
// Boolean - True if the metadata objects belongs to the specified type, otherwise is False.
//
Function IsChartOfCharacteristicTypes(MetadataObject) Export
	
	Return BaseTypeNameByMetadataObject(MetadataObject) = TypeNameChartsOfCharacteristicTypes();
	
EndFunction

// Checks whether the metadata object belongs to the Business process type.
// 
// Parameters:
// MetadataObject – metadata object to be checked.
// 
// Returns:
// Boolean - True if the metadata objects belongs to the specified type, otherwise is False.
//
Function IsBusinessProcess(MetadataObject) Export
	
	Return BaseTypeNameByMetadataObject(MetadataObject) = TypeNameBusinessProcesses();
	
EndFunction

// Checks whether the metadata object belongs to the Task type.
// 
// Parameters:
// MetadataObject – metadata object to be checked.
// 
// Returns:
// Boolean - True if the metadata objects belongs to the specified type, otherwise is False.
//
Function IsTask(MetadataObject) Export
	
	Return BaseTypeNameByMetadataObject(MetadataObject) = TypeNameTasks();
	
EndFunction

// Checks whether the metadata object belongs to the Chart of accounts type.
// 
// Parameters:
// MetadataObject – metadata object to be checked.
// 
// Returns:
// Boolean - True if the metadata objects belongs to the specified type, otherwise is False.
//
Function IsChartOfAccounts(MetadataObject) Export
	
	Return BaseTypeNameByMetadataObject(MetadataObject) = TypeNameChartsOfAccounts();
	
EndFunction

// Checks whether the metadata object belongs to the Chart of calculation types type.
// 
// Parameters:
// MetadataObject – metadata object to be checked.
// 
// Returns:
// Boolean - True if the metadata objects belongs to the specified type, otherwise is False.
//
Function IsChartOfCalculationTypes(MetadataObject) Export
	
	Return BaseTypeNameByMetadataObject(MetadataObject) = TypeNameChartsOfCalculationTypes();
	
EndFunction

//------------------------------------------------------------------------------
// Registers.

// Checks whether the metadata object belongs to the information register type.
// 
// Parameters:
// MetadataObject – metadata object to be checked.
// 
// Returns:
// Boolean - True if the metadata objects belongs to the specified type, otherwise is False.
//
Function IsInformationRegister(MetadataObject) Export
	
	Return BaseTypeNameByMetadataObject(MetadataObject) = TypeNameInformationRegisters();
	
EndFunction

// Checks whether the metadata object belongs to the Accumulation register type.
// 
// Parameters:
// MetadataObject – metadata object to be checked.
// 
// Returns:
// Boolean - True if the metadata objects belongs to the specified type, otherwise is False.
//
Function IsAccumulationRegister(MetadataObject) Export
	
	Return BaseTypeNameByMetadataObject(MetadataObject) = TypeNameAccumulationRegisters();
	
EndFunction

// Checks whether the metadata object belongs to the Accounting register type.
// 
// Parameters:
// MetadataObject – metadata object to be checked.
// 
// Returns:
// Boolean - True if the metadata objects belongs to the specified type, otherwise is False.
//
Function IsAccountingRegister(MetadataObject) Export
	
	Return BaseTypeNameByMetadataObject(MetadataObject) = TypeNameAccountingRegisters();
	
EndFunction

// Checks whether the metadata object belongs to the Calculation register type.
// 
// Parameters:
// MetadataObject – metadata object to be checked.
// 
// Returns:
// Boolean - True if the metadata objects belongs to the specified type, otherwise is False.
//
Function IsCalculationRegister(MetadataObject) Export
	
	Return BaseTypeNameByMetadataObject(MetadataObject) = TypeNameCalculationRegisters();
	
EndFunction

// Checks whether the metadata object belongs to a register type.
// 
// Parameters:
// MetadataObject – metadata object to be checked.
// 
// Returns:
// Boolean - True if the metadata objects belongs to the specified type, otherwise is False.
//
Function IsRegister(MetadataObject) Export
	
	BaseTypeName = BaseTypeNameByMetadataObject(MetadataObject);
	
	Return BaseTypeName = TypeNameInformationRegisters()
		Or BaseTypeName = TypeNameAccumulationRegisters()
		Or BaseTypeName = TypeNameAccountingRegisters()
		Or BaseTypeName = TypeNameCalculationRegisters();
	
EndFunction

//------------------------------------------------------------------------------
// Constants.

// Checks whether the metadata object belongs to the Constant type.
// 
// Parameters:
// MetadataObject – metadata object to be checked.
// 
// Returns:
// Boolean - True if the metadata objects belongs to the specified type, otherwise is False.
//
Function IsConstant(MetadataObject) Export
	
	Return BaseTypeNameByMetadataObject(MetadataObject) = TypeNameConstants();
	
EndFunction

//------------------------------------------------------------------------------
// Document journals.

// Checks whether the metadata object belongs to the Document journal type.
// 
// Parameters:
// MetadataObject – metadata object to be checked.
// 
// Returns:
// Boolean - True if the metadata objects belongs to the specified type, otherwise is False.
//
Function IsDocumentJournal(MetadataObject) Export
	
	Return BaseTypeNameByMetadataObject(MetadataObject) = TypeNameDocumentJournals();
	
EndFunction

//------------------------------------------------------------------------------
// References.

// Checks whether the metadata object belongs to a reference type.
// 
// Parameters:
// MetadataObject – metadata object to be checked.
// 
// Returns:
// Boolean - True if the metadata objects belongs to the specified type, otherwise is False.
//
Function IsReferenceTypeObject(MetadataObject) Export
	
	BaseTypeName = BaseTypeNameByMetadataObject(MetadataObject);
	
	Return BaseTypeName = TypeNameCatalogs()
		Or BaseTypeName = TypeNameDocuments()
		Or BaseTypeName = TypeNameBusinessProcesses()
		Or BaseTypeName = TypeNameTasks()
		Or BaseTypeName = TypeNameChartsOfAccounts()
		Or BaseTypeName = TypeNameExchangePlans()
		Or BaseTypeName = TypeNameChartsOfCharacteristicTypes()
		Or BaseTypeName = TypeNameChartsOfCalculationTypes();
	
EndFunction

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region Type_names_definitions

// Returns a value for identification of the Information registers type. 
//
// Returns:
// String.
//
Function TypeNameInformationRegisters() Export
	
	Return "InformationRegisters";
	
EndFunction

// Returns a value for identification of the Accumulation registers type. 
//
// Returns:
// String.
//
Function TypeNameAccumulationRegisters() Export
	
	Return "AccumulationRegisters";
	
EndFunction

// Returns a value for identification of the Accounting registers type. 
//
// Returns:
// String.
//
Function TypeNameAccountingRegisters() Export
	
	Return "AccountingRegisters";
	
EndFunction

// Returns a value for identification of the Calculation registers type. 
//
// Returns:
// String.
//
Function TypeNameCalculationRegisters() Export
	
	Return "CalculationRegisters";
	
EndFunction

// Returns a value for identification of the Documents type. 
//
// Returns:
// String.
//
Function TypeNameDocuments() Export
	
	Return "Documents";
	
EndFunction

// Returns a value for identification of the Catalogs type. 
//
// Returns:
// String.
//
Function TypeNameCatalogs() Export
	
	Return "Catalogs";
	
EndFunction

// Returns a value for identification of the Enumerations type. 
//
// Returns:
// String.
//
Function TypeNameEnums() Export
	
	Return "Enums";
	
EndFunction

// Returns a value for identification of the Reports type. 
//
// Returns:
// String.
//
Function TypeNameReports() Export
	
	Return "Reports";
	
EndFunction

// Returns a value for identification of the Data processors type. 
//
// Returns:
// String.
//
Function TypeNameDataProcessors() Export
	
	Return "DataProcessors";
	
EndFunction

// Returns a value for identification of the Exchange plans type. 
//
// Returns:
// String.
//
Function TypeNameExchangePlans() Export
	
	Return "ExchangePlans";
	
EndFunction

// Returns a value for identification of the Charts of characteristic types type. 
//
// Returns:
// String.
//
Function TypeNameChartsOfCharacteristicTypes() Export
	
	Return "ChartsOfCharacteristicTypes";
	
EndFunction

// Returns a value for identification of the Business processes type. 
//
// Returns:
// String.
//
Function TypeNameBusinessProcesses() Export
	
	Return "BusinessProcesses";
	
EndFunction

// Returns a value for identification of the Tasks type. 
//
// Returns:
// String.
//
Function TypeNameTasks() Export
	
	Return "Tasks";
	
EndFunction

// Returns a value for identification of the Charts of accounts type. 
//
// Returns:
// String.
//
Function TypeNameChartsOfAccounts() Export
	
	Return "ChartsOfAccounts";
	
EndFunction

// Returns a value for identification of the Charts of calculation types type. 
//
// Returns:
// String.
//
Function TypeNameChartsOfCalculationTypes() Export
	
	Return "ChartsOfCalculationTypes";
	
EndFunction

// Returns a value for identification of the Constants type. 
//
// Returns:
// String.
//
Function TypeNameConstants() Export
	
	Return "Constants";
	
EndFunction

// Returns a value for identification of the Document journals type. 
//
// Returns:
// String.
//
Function TypeNameDocumentJournals() Export
	
	Return "DocumentJournals";
	
EndFunction

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region Saving_reading_and_deleting_settings_from_storages

// Saves settings to the common settings storage.
// 
// Parameters:
// Corresponds to the CommonSettingsStorage.Save method. 
// See StorageSave() procedure parameters for details. 
//
Procedure CommonSettingsStorageSave(ObjectKey, SettingsKey = "", Value,
	SettingsDescription = Undefined, UserName = Undefined, 
	NeedToRefreshReusableValues = False) Export
	
	StorageSave(
		CommonSettingsStorage,
		ObjectKey,
		SettingsKey,
		Value,
		SettingsDescription,
		UserName,
		NeedToRefreshReusableValues
	);
	
EndProcedure

// Loads settings from the common settings storage.
//
// Parameters:
// Corresponds to the CommonSettingsStorage.Load method. 
// See StorageLoad() procedure parameters for details. 
//
Function CommonSettingsStorageLoad(ObjectKey, SettingsKey = "", DefaultValue = Undefined, 
	SettingsDescription = Undefined, UserName = Undefined) Export
	
	Return StorageLoad(
		CommonSettingsStorage,
		ObjectKey,
		SettingsKey,
		DefaultValue,
		SettingsDescription,
		UserName
	);
	
EndFunction

// Deletes settings from the common settings storage.
// 
// Parameters:
// Corresponds to the CommonSettingsStorage.Delete method. 
// See StorageDelete() procedure parameters for details. 
//
Procedure CommonSettingsStorageDelete(ObjectKey, SettingsKey, UserName) Export
	
	StorageDelete(
		CommonSettingsStorage,
		ObjectKey,
		SettingsKey,
		UserName
	);
	
EndProcedure

// Saves an array of user settings to StructureArray. 
// Can be called on client.
// 
// Parameters:
// StructureArray - Array - Array of Structure with the following fields:
// Object, Setting, Value;
// NeedToRefreshReusableValues - Boolean - flag that shows whether reusable values will be updated.
//
Procedure CommonSettingsStorageSaveArray(StructureArray,
	NeedToRefreshReusableValues = False) Export
	
	If Not AccessRight("SaveUserData", Metadata) Then
		Return;
	EndIf;
	
	For Each Element In StructureArray Do
		CommonSettingsStorage.Save(Element.Object, Element.Setting, Element.Value);
	EndDo;
	
	If NeedToRefreshReusableValues Then
		RefreshReusableValues();
	EndIf;
	
EndProcedure

// Saves the StructureArray user settings array and updates 
// reusable values. Can be called on client.
// 
// Parameters:
// StructureArray - Array - Array of Structure with the following fields:
// Object, Setting, Value.
//
Procedure CommonSettingsStorageSaveArrayAndRefreshReusableValues(StructureArray) Export
	
	CommonSettingsStorageSaveArray(StructureArray, True);
	
EndProcedure

// Saves settings to the common settings storage and updates 
// reusable values.
// 
// Parameters:
// Corresponds to the CommonSettingsStorage.Save method. 
// See StorageSave() procedure parameters for details. 
//
Procedure CommonSettingsStorageSaveAndRefreshReusableValues(ObjectKey, SettingsKey, Value) Export
	
	CommonSettingsStorageSave(ObjectKey, SettingsKey, Value,,,True);
	
EndProcedure

// Saves settings to the common settings storage.
// 
// Parameters:
// Corresponds to the CommonSettingsStorage.Save method. 
// See StorageSave() procedure parameters for details. 
//
Procedure SystemSettingsStorageSave(ObjectKey, SettingsKey = "", Value,
	SettingsDescription = Undefined, UserName = Undefined, 
	NeedToRefreshReusableValues = False) Export
	
	StorageSave(
		SystemSettingsStorage, 
		ObjectKey, 
		SettingsKey, 
		Value,
		SettingsDescription, 
		UserName, 
		NeedToRefreshReusableValues
	);
	
EndProcedure

// Loads settings from the common settings storage.
//
// Parameters: 
// Corresponds to the CommonSettingsStorage.Load method. 
// See StorageLoad() procedure parameters for details. 
//
Function SystemSettingsStorageLoad(ObjectKey, SettingsKey = "", DefaultValue = Undefined, 
	SettingsDescription = Undefined, UserName = Undefined) Export
	
	Return StorageLoad(
		SystemSettingsStorage, 
		ObjectKey, 
		SettingsKey, 
		DefaultValue, 
		SettingsDescription, 
		UserName
	);
	
EndFunction

// Deletes settings from the common settings storage.
//
// Parameters:
// Corresponds to the CommonSettingsStorage.Delete method. 
// See StorageDelete() procedure parameters for details. 
//
Procedure SystemSettingsStorageDelete(ObjectKey, SettingsKey, UserName) Export
	
	StorageDelete(
		SystemSettingsStorage,
		ObjectKey,
		SettingsKey,
		UserName
	);
	
EndProcedure

// Saves settings to the form data settings storage.
// 
// Parameters:
// Corresponds to the CommonSettingsStorage.Save method. 
// See StorageSave() procedure parameters for details. 
//
Procedure FormDataSettingsStorageSave(ObjectKey, SettingsKey = "", Value,
	SettingsDescription = Undefined, UserName = Undefined, 
	NeedToRefreshReusableValues = False) Export
	
	StorageSave(
		FormDataSettingsStorage, 
		ObjectKey, 
		SettingsKey, 
		Value,
		SettingsDescription, 
		UserName, 
		NeedToRefreshReusableValues
	);
	
EndProcedure

// Loads settings from the form data settings storage.
//
// Parameters:
// Corresponds to the CommonSettingsStorage.Load method. 
// See StorageLoad() procedure parameters for details. 
//
Function FormDataSettingsStorageLoad(ObjectKey, SettingsKey = "", DefaultValue = Undefined, 
	SettingsDescription = Undefined, UserName = Undefined) Export
	
	Return StorageLoad(
		FormDataSettingsStorage, 
		ObjectKey, 
		SettingsKey, 
		DefaultValue, 
		SettingsDescription, 
		UserName
	);
	
EndFunction

// Deletes settings from the form data settings storage.
//
// Parameters:
// Corresponds to the CommonSettingsStorage.Delete method. 
// See StorageDelete() procedure parameters for details. 
//
Procedure FormDataSettingsStorageDelete(ObjectKey, SettingsKey, UserName) Export
	
	StorageDelete(
		FormDataSettingsStorage,
		ObjectKey,
		SettingsKey,
		UserName
	);
	
EndProcedure

// Saves settings to the settings storage through its manager.
// 
// Parameters:
// StorageManager - StandardSettingsStorageManager - storage where settings will be saved;
// ObjectKey - String - settings object key; 
// For details, see Settings automatically saved in system storage help topic;
// SettingsKey - String - saved settings key;
// Value - contains settings to be saved in the storage.
// SettingsDescription - SettingsDescription - contains information about settings.
// UserName - String - user name whose settings will be saved.
// If this parameter is not specified, current user settings will be saved.
// NeedToRefreshReusableValues - Boolean.
//
Procedure StorageSave(StorageManager, ObjectKey, SettingsKey, Value,
	SettingsDescription, UserName, NeedToRefreshReusableValues)
	
	If Not AccessRight("SaveUserData", Metadata) Then
		Return;
	EndIf;
	
	StorageManager.Save(ObjectKey, SettingsKey, Value, SettingsDescription, UserName);
	
	If NeedToRefreshReusableValues Then
		RefreshReusableValues();
	EndIf;
	
EndProcedure

// Loads settings from the settings storage through its manager.
//
// Parameters:
// StorageManager - StandardSettingsStorageManager - settings will be loaded from this storage;
// ObjectKey - String - settings object key; 
// For details, see Settings automatically saved in system storage help topic;
// SettingsKey - String - loading settings key;
// DefaultValue - value to be loaded if settings are not found.
// SettingsDescription - SettingsDescription - settings description can be retrieved through this parameter.
// UserName - String - user name whose settings will be loaded.
// If this parameter is not specified, current user settings will be loaded.
// 
// Returns: 
// Loaded from storage settings. Undefined if settings is not found and DefaultValue is Undefined.
// 
Function StorageLoad(StorageManager, ObjectKey, SettingsKey, DefaultValue,
	SettingsDescription, UserName)
	
	Result = Undefined;
	
	If AccessRight("SaveUserData", Metadata) Then
		Result = StorageManager.Load(ObjectKey, SettingsKey, SettingsDescription, UserName);
	EndIf;
	
	If (Result = Undefined) And (DefaultValue <> Undefined) Then
		Result = DefaultValue;
	EndIf;

	Return Result;
	
EndFunction

// Deletes settings from the settings storage using the settings storage manager.
//
// Parameters:
// StorageManager - StandardSettingsStorageManager - storage where settings will be deleted;
// ObjectKey - String - settings object key;
// If this parameter is Undefined, all object settings will be deleted.
// SettingsKey - String - deleting settings key;
// If this parameter is Undefined, settings with any key will be deleted.
// UserName - String - user name whose settings will be deleted;
// If this parameter is not specified, all user settings will be deleted.
// 
Procedure StorageDelete(StorageManager, ObjectKey, SettingsKey, UserName)
	
	If AccessRight("SaveUserData", Metadata) Then
		StorageManager.Delete(ObjectKey, SettingsKey, UserName);
	EndIf;
	
EndProcedure

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region Functions_for_working_with_spreadsheet_documents

// Checks whether the passed spreadsheet document fits a single page in the print layout.
//
// Parameters
// Spreadsheet – Spreadsheet document;
// AreasToPut – Array of Table or Spreadsheet document to be checked;
// ResultOnError - result to be returned in case of error.
//
// Returns:
// Boolean – flag that shows whether the passed spreadsheet document fits a single page.
//
Function SpreadsheetDocumentFitsPage(Spreadsheet, AreasToPut, ResultOnError = True) Export

	Try
		Return Spreadsheet.CheckPut(AreasToPut);
	Except
		Return ResultOnError;
	EndTry;

EndFunction 

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region Functions_for_working_with_the_event_log

// Batch record of messages to the event log.
// 
// Parameters: 
// EventsForEventLog - Array of Structure - global client variable. 
// Each structure is a message to be recorded in the event log.
// This variable will be cleared after recording.
//
Procedure WriteEventsToEventLog(EventsForEventLog) Export
	
	If TypeOf(EventsForEventLog) <> Type("ValueList") Then
		Return;
	EndIf;	
	
	If EventsForEventLog.Count() = 0 Then
		Return;
	EndIf;
	
	For Each LogMessage In EventsForEventLog Do
		MessagesValue = LogMessage.Value;
		EventName = MessagesValue.EventName;
		EventLevel = EventLevelByPresentation(MessagesValue.LevelPresentation);
		EventDate = CurrentSessionDate();
		If MessagesValue.Property("EventDate") And ValueIsFilled(MessagesValue.EventDate) Then
			EventDate = MessagesValue.EventDate;
		EndIf;
		Comment = String(EventDate) + " " + MessagesValue.Comment;
		WriteLogEvent(EventName, EventLevel,,, Comment);
	EndDo;
	EventsForEventLog.Clear();
	
EndProcedure

// Enables event log usage.
//
// Parameters: 
// LevelList - Value list - names of event log levels to be enabled. 
//
Procedure EnableUseEventLog(LevelList = Undefined) Export
	SetPrivilegedMode(True);
	Try
		SetExclusiveMode(True);
		LevelArray = New Array();
		
		If LevelList = Undefined Then
			LevelArray.Add(EventLogLevel.Information);
			LevelArray.Add(EventLogLevel.Error);
			LevelArray.Add(EventLogLevel.Warning);
			LevelArray.Add(EventLogLevel.Note);
		Else
			LevelArray = LogEventLevelsByString(LevelList);
		EndIf;
			
		SetEventLogUsing(LevelArray);	
		SetExclusiveMode(False);
	Except
		SetPrivilegedMode(False);	
		Raise
	EndTry;
	SetPrivilegedMode(False);	
EndProcedure

// Checks whether event recording to the event log is enabled.
//
// Parameters: 
// CheckList - ValueList - list of string presentations of event log usage modes to be checked.
//					If it is Undefined, then all modes are checked.
//
// Returns:
// True if the specified modes are enabled, otherwise is False.
//
Function EventLogEnabled(CheckList = Undefined) Export	
	ModeArray = GetEventLogUsing();
	If CheckList = Undefined Then
		Return ModeArray.Count() = 4 ;
	Else
		ModeNameArray = StringFunctionsClientServer.SplitStringIntoSubstringArray(CheckList);
		For Each Name In ModeNameArray Do
			CurrentModeToCheck = EventLevelByPresentation(Name);
			If ModeArray.Find(CurrentModeToCheck) = Undefined Then
				Return False;
			EndIf;
		EndDo;
	EndIf;
	Return True;
EndFunction

#EndRegion

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region PRIVATE_IMPLEMENTATION

Function EventLevelByPresentation(LevelPresentation)
	If LevelPresentation = "Information" Then
		Return EventLogLevel.Information;
	ElsIf LevelPresentation = "Error" Then
		Return EventLogLevel.Error;
	ElsIf LevelPresentation = "Warning" Then
		Return EventLogLevel.Warning; 
	ElsIf LevelPresentation = "Note" Then
		Return EventLogLevel.Note;
	EndIf;	
EndFunction

Function LogEventLevelsByString(LevelList)
	LevelNameArray = StringFunctionsClientServer.SplitStringIntoSubstringArray(LevelList);
	LevelArray = New Array;
	For Each Name In LevelNameArray Do
		LevelArray.Add(EventLevelByPresentation(Name));
	EndDo;
	Return LevelArray;
EndFunction

Procedure NewMetadataObjectCollectionRow(Name, Synonym, Picture, ObjectPicture, Tab)
	
	NewRow = Tab.Add();
	NewRow.Name = Name;
	NewRow.Synonym = Synonym;
	NewRow.Picture = Picture;
	NewRow.ObjectPicture = ObjectPicture;
	
EndProcedure

#EndRegion
