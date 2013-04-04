
////////////////////////////////////////////////////////////////////////////////
// COMMON PROCEDURES AND FUNCTIONS

// Check if documents are posted
// Parameters
//  Documents - array - documents, to be checked if they are posted
// Value to return:
//  Array 	  - unposted documents from the array Documents
//
Function DocumentsArePosted(Val Documents) Export
	
	QueryText = "SELECT
		|	Document.Ref AS Ref
		|FROM
		|	Document.[DocumentName] AS Document
		|WHERE
		|	Document.Ref In (&DocumentsArray)
		|	And Not Document.Posted";
	
	DocumentName = StringFunctionsClientServer.DecomposeStringIntoSubstringsArray(
		Documents[0].Metadata().FullName(), ".")[1];
	
	QueryText = StrReplace(QueryText, "[DocumentName]", DocumentName);
	
	Query 		= New Query;
	Query.Text  = QueryText;
	Query.SetParameter("DocumentsArray", Documents);
	
	Return Query.Execute().Unload().UnloadColumn("Ref");
	
EndFunction

// Procedure does documents posting before generating a print form.
//
// Parameters:
//	Documents - Array - Documents, that have to be posted
//
// Value returned:
//	Array	  - documents, that were not posted
//
Function PostDocuments(Documents, TypeOfPostedDocuments) Export
	
	DocumentName = StringFunctionsClientServer.DecomposeStringIntoSubstringsArray(
						Documents[0].Metadata().FullName(), ".")[1];
	
	TypeOfPostedDocuments = TypeOf(Documents[0]);
	
	UnpostedDocuments = New Array;
	
	For Each DocumentRef In Documents Do
		
		DocumentObject = DocumentRef.GetObject();
		
		CompletedSuccessfully = False;
		
		If DocumentObject.FillCheck() Then
			Try
				DocumentObject.Write(DocumentWriteMode.Posting);
				CompletedSuccessfully = True;
			Except
				ErrorPresentation = BriefErrorDescription(ErrorInfo());
				ErrorMessageText  = NStr("en = 'Error during the document posting: %1'");
				ErrorMessageText  = StringFunctionsClientServer.SubstitureParametersInString(ErrorMessageText, ErrorPresentation);
				WriteLogEvent(NStr("en = 'Posting documents on printing'"),
					EventLogLevel.Information,
					DocumentObject.Metadata(),
					DocumentRef,
					ErrorMessageText);
			EndTry;
		EndIf;
		
		If Not CompletedSuccessfully Then
			UnpostedDocuments.Add(DocumentRef);
		EndIf;
		
	EndDo;
	
	Return UnpostedDocuments;
	
EndFunction 

// Function returns ref to db current user,
// determined using configuration user account.
//
// Value returned:
//  CatalogRef.Users
//
Function CurrentUser() Export
	
	SetPrivilegedMode(True);
	
	Return SessionParameters.CurrentUser;
	
EndFunction 

// Run export procedure by name without parameters.
//
// Parameters
//  ExportProcedureName – String    – export procedure name in format
//									   <name of object>.<name of procedure>, where <name of object> - is
// 									   common module or object manager module.
//
// Example:
//  RunSafely("MyCommonModule.MyProcedure");
//
Procedure RunSafely(Val ExportProcedureName) Export
	
	// Check preconditions for a format of ExportProcedureName.
	NameParts = StringFunctionsClientServer.DecomposeStringIntoSubstringsArray(ExportProcedureName, ".");
	If NameParts.Count() <> 2 Then
		Raise StringFunctionsClientServer.SubstitureParametersInString(
			NStr("en = 'Incorrect format of the ExportProcedureName (%1) parameter'"),
			ExportProcedureName);
	EndIf;

	ObjectName = NameParts[0];
	If (Metadata.CommonModules.Find(ObjectName) 		 = Undefined)
 		And (Metadata.DataProcessors.Find(ObjectName) 	 = Undefined) 
 		And (Metadata.Documents.Find(ObjectName) 		 = Undefined) 
 		And (Metadata.Catalogs.Find(ObjectName) 		 = Undefined)
 		And (Metadata.BusinessProcesses.Find(ObjectName) = Undefined) Then
		Raise StringFunctionsClientServer.SubstitureParametersInString(
			NStr("en = 'Incorrect format of the ExportProcedureName (%1) parameter '"),
			ExportProcedureName);
	EndIf;

	Execute ExportProcedureName + "();";
	
EndProcedure

// Function GetAttributeValues returns structure,
// containig values of attributes read from infobase
// by object ref.
//
//  If there is no access to one of attributes, access rights exception will be raised.
//  If attribute should be read regardless of user rights,
//  then it is required to use preliminary transition into privileged mode.
//
// Parameters:
//  Ref       		- ref to object, - catalog item, document, ...
//  AttributeNames 	- String, attribute names separated by comma,
//               in format of requirements to structure properties.
//               For example, "Code, Description, Parent".
//
// Value returned:
//  Structure    	- contains list of properties, as a list of names in string
//                 AttributeNames, with values of attributes, read
//                 from infobase.
//
Function GetAttributeValues(Ref, AttributeNames) Export
	
	Query 	   = New Query;
	Query.Text =
		"SELECT
		|	" + AttributeNames + "
		|FROM
		|	" + Ref.Metadata().FullName() + " AS Table
		|WHERE
		|	Table.Ref = &Ref";
	Query.SetParameter("Ref", Ref);
	
	Selection 	= Query.Execute().Choose();
	Selection.Next();
	Result 		= New Structure(StrReplace(AttributeNames, ".", ""));
	FillPropertyValues(Result, Selection);
	
	Return Result;
	
EndFunction

// Function GetAttributeValue returns value
// of attribute, read from infobase by object ref.
//
//  If there is no access to attribute, exception is raised.
//  If attribute should be read regardless of user rights,
//  then it is required to use preliminary transition into privileged mode.
//
// Parameters:
//  Ref      		 - ref to object, - catalog item, document, ...
//  AttributeName	 - String, for example, "Code".
//
// Value returned:
//  Arbitrary   	 - depends on value type of attribute read.
//
Function GetAttributeValue(Ref, AttributeName) Export
	
	Result = GetAttributeValues(Ref, AttributeName);
	Return Result[AttributeName];
	
EndFunction 

// Union two value tables by condition "AND".
// Returns value table, resultant as a merge of two tables by condition "AND".
//
// Parameters:
//  Table1         		- ValueTable - first value table for merge
//  Table2         		- ValueTable - second value table for merge
//  TableFields      	- String 	 - table fields, separated by comma, used for merge
//  IteratorFieldName 	- String 	 - name of a service column of a value table.
//                              This name must be unique in a set of columns of first and second tables.
//                              Variable TableFields should not include this name.
//                              Default value - "TableFieldIterator"
//
// Value returned:
//  ValueTable 			-  value table, resultant as a merge of two tables by condition "AND".
//
Function MergeTablesOnCondition(Table1, Table2, Val TableFields, IteratorFieldName = "TableFieldIterator") Export
	
	Table1.GroupBy(TableFields);
	Table2.GroupBy(TableFields);
	
	AddIteratorToTable(Table1, +1, IteratorFieldName);
	AddIteratorToTable(Table2, -1, IteratorFieldName);
	
	TableResult = Table1.Copy();
	
	CommonUseClientServer.SupplementTable(Table2, TableResult);
	
	TableResult.GroupBy(TableFields, IteratorFieldName);
	
	TableResult = TableResult.Copy(New Structure(IteratorFieldName, 0));
	
	TableResult.Columns.Delete(IteratorFieldName);
	
	Return TableResult;
	
EndFunction

// Gets name of  enum value as metadata object
//
// Parameters:
//  Value  - enum value, for which, enum value should be received
//
// Value returned:
//  String - name of enum value as metadata object
//
Function GetEnumNameByValue(Value) Export
	
	MetadataObject = Value.Metadata();
	
	ValueIndex = Enums[MetadataObject.Name].IndexOf(Value);
	
	Return MetadataObject.EnumValues[ValueIndex].Name;
	
EndFunction 

// Adds column to value table. Fills column by passed value
//
// Parameters:
//  Table          	    - ValueTable - value table for adding a column
//  IteratorValue 		- Arbitrary - value, which will be used to fill new table field
//  IteratorFieldName   - String - name of field being added
//
Procedure AddIteratorToTable(Table, IteratorValue, IteratorFieldName) Export
	
	Table.Columns.Add(IteratorFieldName);
	
	Table.FillValues(IteratorValue, IteratorFieldName);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// AUXILIARY PROCEDURES AND FUNCTIONS

// Returns name of COM-class for work with 1C:Enterprise 8 via COM-connection.
//
Function COMConnectorName() Export
	
	SystemInformation = New SystemInfo;
	VersionSubstring  = StringFunctionsClientServer.DecomposeStringIntoSubstringsArray(
		SystemInformation.AppVersion, ".");
	Return "v" + VersionSubstring[0] + VersionSubstring[1] + ".COMConnector";
	
EndFunction	

// Function FileInformationBase determines operation mode
// of infobase, file (True) or Server (False).
//  On check InfobaseConnectionString is used, which
// can be assigned directly.
//
// Parameters:
//  InfobaseConnectionString - String - parameter is used, if
//                 we need to check connection string of not current infobase.
//
// Value returned:
//  Boolean.
//
Function FileInformationBase(Val InfobaseConnectionString = "") Export
			
	If IsBlankString(InfobaseConnectionString) Then
		InfobaseConnectionString =  InfobaseConnectionString();
	EndIf;
	Return Find(Upper(InfobaseConnectionString), "FILE=") = 1;
	
EndFunction 

// Get infobase presentation to display to a user.
//
// Value returned:
//   String      - Presentation of the infobase
//
// Example of the result returned:
// - for IB in file mode: \\FileServer\1c_ib\
// - for IB in server mode: ServerName:1111 / information_base_name
//
Function GetInfobasePresentation() Export
	
	InfobaseConnectionString = InfobaseConnectionString();
	
	If FileInformationBase(InfobaseConnectionString) Then
		PathToDB = Mid(InfobaseConnectionString, 6, StrLen(InfobaseConnectionString) - 6);
	Else
		// need to add infobase path name to server name
		SearchPosition = Find(Upper(InfobaseConnectionString), "SRVR=");
		
		If SearchPosition <> 1 Then
			Return Undefined;
		EndIf;
		
		SemicolonPosition 	= Find(InfobaseConnectionString, ";");
		CopyingStartPosition   	= 6 + 1;
		CopyEndPosition 		= SemicolonPosition - 2; 
		
		ServerName = Mid(InfobaseConnectionString, CopyingStartPosition, CopyEndPosition - CopyingStartPosition + 1);
		
		InfobaseConnectionString = Mid(InfobaseConnectionString, SemicolonPosition + 1);
		
		// position of the server name
		SearchPosition = Find(Upper(InfobaseConnectionString), "REF=");
		
		If SearchPosition <> 1 Then
			Return Undefined;
		EndIf;
		
		CopyingStartPosition    = 6;
		SemicolonPosition  = Find(InfobaseConnectionString, ";");
		CopyEndPosition 		= SemicolonPosition - 2; 
		
		InfobaseNameAtServer = Mid(InfobaseConnectionString, CopyingStartPosition, CopyEndPosition - CopyingStartPosition + 1);
		
		PathToDB = ServerName + "/ " + InfobaseNameAtServer;
		
	EndIf;
	
	Return PathToDB;
	
EndFunction

// Check, that type description consists of a single value type and
// matches required type.
//
// Value returned:
//   Boolean      - Matches or not
//
Function TypeDetailsConsistsOfType(TypeDetails, ValueType) Export
	
	If TypeDetails.Types().Count() = 1
	   And TypeDetails.Types().Get(0) = ValueType Then
		Return True;
	EndIf;
	
	Return False;

EndFunction

// Function ReadXMLToTable converts text of XML format to a value table.
// Columns of the table are being generated based on description in XML.
//
// Parameters:
//  TextXML     - text of XML format.
//
// Value returned:
//  ValueTable.
//
Function ReadXMLToTable(TextXML) Export
	
	Read = New XMLReader;
	Read.SetString(TextXML);
	
	// Read first node and check it
	If Not Read.Read() Then
		Raise("XML is empty");
	ElsIf Read.Name <> "Items" Then
		Raise("Error in XML structure");
	EndIf;
	
	// Get Description table and create the table
	TableName = Read.GetAttribute("Description");
	ColumnNames = StrReplace(Read.GetAttribute("Columns"), ",", Chars.LF);
	ColumnsQty = StrLineCount(ColumnNames);
	
	ValueTable = New ValueTable;
	For Acc = 1 To ColumnsQty Do
		ValueTable.Columns.Add(StrGetLine(ColumnNames, Acc), New TypeDescription("String"));
	EndDo;
	
	// Fill values in table
	While Read.Read() Do
		
		If Read.NodeType <> XMLNodeType.StartElement Then
			Continue;
		ElsIf Read.Name <> "Item" Then
			Raise("Error in XML structure");
		EndIf;
		
		newStr = ValueTable.Add();
		For Acc = 1 To ColumnsQty Do
			ColumnName = StrGetLine(ColumnNames, Acc);
			newStr[Acc-1] = Read.GetAttribute(ColumnName);
		EndDo;
		
	EndDo;
	
	// Fill result
	Result = New Structure;
	Result.Insert("TableName", TableName);
	Result.Insert("Data", ValueTable);
	
	Return Result;
	
EndFunction // ReadXMLToTable()

// Function SaveFileAtServer transfers binary data from temporary
// storage to a file at server (data in temporary storage is deleted).
//
// Parameters:
//  AddressInTemporaryStorage - address, pointing to a value in temporary storage.
//  FileName     - String, optional parameter,
//                 full file name at server for saving binary data.
//
// Value returned:
//  String       - full file name at server, where binary data is saved.
//
Function SaveFileAtServer(Val AddressInTemporaryStorage, Val FileName = Undefined) Export
	
	If FileName = Undefined Then
		FileName = GetTempFileName();
	EndIf;
	
	BinaryData = GetFromTempStorage(AddressInTemporaryStorage);
	BinaryData.Write(FileName);
	
	DeleteFromTempStorage(AddressInTemporaryStorage);
	
	Return FileName;
	
EndFunction // SaveFileAtServer()

// Procedure is called in server context and deleted temporary files at 1C:Enterprise server.
//
Procedure DeleteFilesAt1CEnterpriseServer(Path) Export
	
	CommonUseClientServer.DeleteFilesInDirectory(Path);
	
EndProcedure

// Gets value table with the description of required properties of all attributes of metadata object
// Gets values of properties of standard attributes and user attributes (created in designer mode)
//
// Parameters:
//  MetadataObject  - Configuration metadata object. Need to get values of properties for this object.
//                      For example: Metadata.Document.SaleOfGoodsAndServices
//  Properties 		- String - properties of attributes, separated by comma, whose values have to be obtained.
//                      For example: "Name, Type, Synonym, ToolTip"
//
// Value returned:
//  ValueTable 		- value table with the description of required properties of all attributes of metadata object
//
Function GetTableOfDescriptionOfObjectProperties(MetadataObject, Properties) Export
	
	PropertiesArray = StringFunctionsClientServer.DecomposeStringIntoSubstringsArray(Properties);
	
	// returned function value
	TableOfDescriptionOfObjectProperties = New ValueTable;
	
	// add fileds to a table according to the names of passed properties
	For Each PropertyName In PropertiesArray Do
		
		TableOfDescriptionOfObjectProperties.Columns.Add(TrimAll(PropertyName));
		
	EndDo;
	
	// fill table row with metadata object attributes properties
	For Each Attribute In MetadataObject.Attributes Do
		
		FillPropertyValues(TableOfDescriptionOfObjectProperties.Add(), Attribute);
		
	EndDo;
	
	// fill table row with metadata object standard attributes properties
	For Each Attribute In MetadataObject.StandardAttributes Do
		
		FillPropertyValues(TableOfDescriptionOfObjectProperties.Add(), Attribute);
		
	EndDo;
	
	Return TableOfDescriptionOfObjectProperties;
	
EndFunction

//	Converts value table into array.
//	Can be used to pass data to client, which has been received
//	at server as value table in case, if value table
//	contains only those values, which can be
//  passed to client
//
//	Resultant array contains structures, which replicate structure
//	 of columns of value table.
//
//	Do not use it to convert value tables
//	with too many rows.
//
//	Parameters: ValueTable
//	Returned value: Array
//
Function ValueTableToArray(ValueTable) Export
	Array = New Array();
	StructureAsString = "";
	NeedComma = False;
	For Each Column In ValueTable.Columns Do
		If NeedComma Then
			StructureAsString = StructureAsString + ",";
		EndIf;
		StructureAsString = StructureAsString + Column.Name;
		NeedComma = True;
	EndDo;
	For Each String In ValueTable Do
		NewRow = New Structure(StructureAsString);
		FillPropertyValues(NewRow, String);
		Array.Add(NewRow);
	EndDo;
	Return Array;

EndFunction

////////////////////////////////////////////////////////////////////////////////
// Functions for work with eventlog

// Procedure writes comments in batches to eventlog
//
// Parameters: EventsForEventLog - array of structures, client global variable
// Each structure - message for eventlog.
// After write variable is cleared.
Procedure WriteEventsToEventLog(EventsForEventLog) Export
	
	If TypeOf(EventsForEventLog) <> Type("ValueList") Then
		Return;
	EndIf;	
	
	If EventsForEventLog.Count() = 0 Then
		Return;
	EndIf;
	
	For Each JournalMessage In EventsForEventLog Do
		MessageValue = JournalMessage.Value;
		
		EventName 		 = MessageValue.EventName;
		EventLevel 		 = GetEventLevelByPresentation(MessageValue.LevelPresentation);
		MetadataObject 	 = MessageValue.MetadataObject;
		Data 			 = MessageValue.Data;
		Comment 		 = MessageValue.Comment;
		
		If MessageValue.ModePresentation = "Transactional" Then
			TransactionMode = EventLogEntryTransactionMode.Transactional;
		Else
			TransactionMode = EventLogEntryTransactionMode.Independent;
		EndIf;
		
		WriteLogEvent(EventName, EventLevel, MetadataObject, 
			Data, Comment, TransactionMode);			
		
	EndDo;
	
	EventsForEventLog.Clear();
	
EndProcedure

// Procedure logging events to eventlog
//
// Parameters: LevelList - value list,
// Descriptions of event logging levels, which have to be enabled
Procedure EnableEventLogUse(LevelList = Undefined) Export
	SetPrivilegedMode(True);
	Try
		SetExclusiveMode(True);
		ArrayOfLevels = New Array();
		
		If LevelList = Undefined Then
		
			ArrayOfLevels.Add(EventLogLevel.Information);
			ArrayOfLevels.Add(EventLogLevel.Error);
			ArrayOfLevels.Add(EventLogLevel.Warning);
			ArrayOfLevels.Add(EventLogLevel.Note);
			
		Else
			
			ArrayOfLevels = SetLevelsByString(LevelList);
			
		EndIf;
			
		SetEventLogUsing(ArrayOfLevels);	
		SetExclusiveMode(False);
	Except
		SetPrivilegedMode(False);	
		Raise
	EndTry;
	SetPrivilegedMode(False);	
EndProcedure

Function SetLevelsByString(LevelList)
	ArrayOfLevelNames = StringFunctionsClientServer.DecomposeStringIntoSubstringsArray(LevelList);
	ArrayOfLevels	  = New Array;
	For Each LevelName In ArrayOfLevelNames Do
		ArrayOfLevels.Add(GetEventLevelByPresentation(LevelName));
	EndDo;
	Return ArrayOfLevels;
EndFunction

// Checks, if logging of event to eventlog is enabled
Function IsEventLogEnabled(ListOfChecks = Undefined) Export	
	ArrayOfModes = GetEventLogUsing();
	If ListOfChecks = Undefined Then
		Return ArrayOfModes.Count() = 4 ;
	Else
		ArrayOfModeNames =  StringFunctionsClientServer.DecomposeStringIntoSubstringsArray(ListOfChecks);
		For Each ModeName In ArrayOfModeNames Do
			CurrentVerifiableMode = GetEventLevelByPresentation(ModeName);
			If ArrayOfModes.Find(CurrentVerifiableMode) = Undefined Then
				Return False;
			EndIf;
		EndDo;
	EndIf;
	Return True;
EndFunction


////////////////////////////////////////////////////////////////////////////////
// Auxiliary procedures and functions working with types
// and their string presentations

Function GetEventLevelByPresentation(LevelPresentation)
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

// Returns name of base type using passed value of metadata object
//
// Parameters:
//  MetadataObject  - object metadata, used to determine base type
//
// Value returned:
//  String 			- name of base type by passed value of metadata object
//
Function BaseTypeNameByMetadataObject(MetadataObject) Export
	
	If Metadata.Documents.Contains(MetadataObject) Then
		Return DocumentsClassName();
		
	ElsIf Metadata.Catalogs.Contains(MetadataObject) Then
		Return CatalogsClassName();
		
	ElsIf Metadata.InformationRegisters.Contains(MetadataObject) Then
		Return InformationRegistersClassName();
		
	ElsIf Metadata.AccumulationRegisters.Contains(MetadataObject) Then
		Return AccumulationRegistersClassName();
		
	ElsIf Metadata.AccountingRegisters.Contains(MetadataObject) Then
		Return AccountingRegistersClassName();
		
	ElsIf Metadata.CalculationRegisters.Contains(MetadataObject) Then
		Return CalculationRegistersClassName();
		
	ElsIf Metadata.ExchangePlans.Contains(MetadataObject) Then
		Return ExchangePlansClassName();
		
	ElsIf Metadata.ChartsOfCharacteristicTypes.Contains(MetadataObject) Then
		Return ChartsOfCharacteristicTypesClassName();
		
	ElsIf Metadata.BusinessProcesses.Contains(MetadataObject) Then
		Return BusinessProcessesClassName();
		
	ElsIf Metadata.Tasks.Contains(MetadataObject) Then
		Return TasksClassName();
		
	ElsIf Metadata.ChartsOfAccounts.Contains(MetadataObject) Then
		Return ChartsOfAccountsClassName();
		
	ElsIf Metadata.ChartsOfCalculationTypes.Contains(MetadataObject) Then
		Return ChartsOfCalculationTypesClassName();
		
	ElsIf Metadata.Constants.Contains(MetadataObject) Then
		Return ConstantsClassName();
		
	Else
		
		Return "";
		
	EndIf;
	
EndFunction

// Function ObjectManagerByFullName returns object manager
// using metadata object full name.
//
// Route points of business-processes are not processed.
//
// Parameters:
//  FullName    - String, full name of metadata object,
//                 for example, "Catalog.Companies".
//
// Value returned:
//  CatalogManager, DocumentManager, ...
//
Function ObjectManagerByFullName(FullName) Export
	
	NameParts = StringFunctionsClientServer.DecomposeStringIntoSubstringsArray(FullName, ".");
	
	MOClass = NameParts[0];
	MOName	= NameParts[1];
	
	If    Upper(MOClass) = "CATALOG" Then
		Return Catalogs[MOName];
	ElsIf Upper(MOClass) = "DOCUMENT" Then
		Return Documents[MOName];
	ElsIf Upper(MOClass) = "BUSINESSPROCESS" Then
		Return BusinessProcesses[MOName];
	ElsIf Upper(MOClass) = "CHARTOFCHARACTERISTICTYPES" Then
		Return ChartsOfCharacteristicTypes[MOName];
	ElsIf Upper(MOClass) = "CHARTOFACCOUNTS" Then
		Return ChartsOfAccounts[MOName];
	ElsIf Upper(MOClass) = "ChartOfCalculationTypes" Then
		Return ChartsOfCalculationTypes[MOName];
	ElsIf Upper(MOClass) = "TASK" Then
		Return Tasks[MOName];
	ElsIf Upper(MOClass) = "EXCHANGEPLAN" Then
		Return ExchangePlans[MOName];
	ElsIf Upper(MOClass) = "ENUM" Then
		Return Enums[MOName];
	ElsIf Upper(MOClass) = "DATAPROCESSOR" Then
		Return DataProcessors[MOName];
	ElsIf Upper(MOClass) = "REPORT" Then
		Return Reports[MOName];
	Else
		Raise StringFunctionsClientServer.SubstitureParametersInString(
			NStr("en = 'Unknown type of metadata object (%1)'"), MOClass);
	EndIf;
	
EndFunction 

// Function ObjectManagerByFullName returns object manager
// by object ref.
//
// Route points of business-processes are not processed.
//
// Parameters:
//  Ref       - ref to object, - catalog item, document, ...
//
// Value returned:
//  CatalogManager, DocumentManager, ...
//
Function ObjectManagerByRef(Ref) Export
	
	ObjectName  = Ref.Metadata().Name;
	RefType 	= TypeOf(Ref);
	
	If Catalogs.AllRefsType().ContainsType(RefType) Then
		Return Catalogs[ObjectName];
	ElsIf Documents.AllRefsType().ContainsType(RefType) Then
		Return Documents[ObjectName];
	ElsIf BusinessProcesses.AllRefsType().ContainsType(RefType) Then
		Return BusinessProcesses[ObjectName];
	ElsIf ChartsOfCharacteristicTypes.AllRefsType().ContainsType(RefType) Then
		Return ChartsOfCharacteristicTypes[ObjectName];
	ElsIf ChartsOfAccounts.AllRefsType().ContainsType(RefType) Then
		Return ChartsOfAccounts[ObjectName];
	ElsIf ChartsOfCalculationTypes.AllRefsType().ContainsType(RefType) Then
		Return ChartsOfCalculationTypes[ObjectName];
	ElsIf Tasks.AllRefsType().ContainsType(RefType) Then
		Return Tasks[ObjectName];
	ElsIf ExchangePlans.AllRefsType().ContainsType(RefType) Then
		Return ExchangePlans[ObjectName];
	ElsIf Enums.AllRefsType().ContainsType(RefType) Then
		Return Enums[ObjectName];
	Else
		Return Undefined;
	EndIf;
	
EndFunction // ObjectManagerByRef()

// Checks if physical record about passed ref value is exists in infobase
//
// Parameters:
//  AnyRef - value of any ref of infobase
//
// Value returned:
//  True - ref physically exists;
//  False   - ref physically does not exist
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
	
	QueryText = StrReplace(QueryText, "[TableName]", FullMetadataObjectNameByRef(AnyRef));
	
	Query 	   = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Ref", AnyRef);
	
	SetPrivilegedMode(True);
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

// Function ObjectClassByRef returns name of kind of metadata objects
// by object ref.
//
// Route points of business-processes are not processed.
//
// Parameters:
//  Ref       	 - ref to object, - catalog item, document, ...
//
// Value returned:
//  String       - name of the kind of metadata objects, for example, "Catalog", "Document" ...
//
Function ObjectClassByRef(Ref) Export
	
	Return ObjectClassByType(TypeOf(Ref));
	
EndFunction 

// Function returns name of kind of metadata objects by object type.
//
// Route points of business-processes are not processed.
//
// Parameters:
//  Type         - Type of applied object, defined in configuration
//
// Value returned:
//  String       - name of the kind of metadata objects, for example, "Catalog", "Document" ...
//
Function ObjectClassByType(Type) Export
	
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
		Return "Enum";
	
	Else
		Raise StringFunctionsClientServer.SubstitureParametersInString(
			NStr("en = 'Incorrect parameter value type (%1)'"), String(Type));
	
	EndIf;
	
EndFunction 

// Returns full name of metadata object by the ref passed value
// for example,
//  "Catalog.Item";
//  "Document.PurchaseInvoice"
//
// Parameters:
//  Ref 	- AnyRef - ref value, for which name of IB table has to be obtained
//
// Value returned:
//  String 	- full name of metadata object for the specified ref value
//
Function FullMetadataObjectNameByRef(Ref) Export
	
	Return Metadata.FindByType(TypeOf(Ref)).FullName();
	
EndFunction

Function GetStringPresentationOfType(Type) Export
	
	Presentation = "";
	
	If IsReferentialType(Type) Then
	
		FullName = Metadata.FindByType(Type).FullName();
		ObjectName = StringFunctionsClientServer.DecomposeStringIntoSubstringsArray(FullName, ".")[1];
		
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

// Function IsReferentialTypeValue checks, that value is of referencial data type
//
// Parameters:
//  Ref       	  - ref to object, - catalog item, document, ...
//
// Value returned:
//  Boolean       - True, if value type is referencial.
//
Function IsReferentialTypeValue(Value) Export
	
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

// Check that type is of referencial data type
//
Function IsReferentialType(Type) Export
	
	Return Catalogs.AllRefsType						().ContainsType(Type)
		Or Documents.AllRefsType					().ContainsType(Type)
		Or Enums.AllRefsType						().ContainsType(Type)
		Or ChartsOfCharacteristicTypes.AllRefsType	().ContainsType(Type)
		Or ChartsOfAccounts.AllRefsType				().ContainsType(Type)
		Or ChartsOfCalculationTypes.AllRefsType		().ContainsType(Type)
		Or BusinessProcesses.AllRefsType			().ContainsType(Type)
		Or BusinessProcesses.RoutePointsAllRefsType	().ContainsType(Type)
		Or Tasks.AllRefsType						().ContainsType(Type)
		Or ExchangePlans.AllRefsType				().ContainsType(Type);
	
EndFunction

// If object is group
// As a parameter can accept only catalog or CCT
//
Function ObjectIsFolder(Object) Export
	
	ObjectMetadata = Object.Metadata();
	
	If Not (ObjectMetadata.Hierarchical And ObjectMetadata.HierarchyType = Metadata.ObjectProperties.HierarchyType.HierarchyFoldersAndItems) Then
		Return False;
	EndIf;
	
	If CommonUse.IsReferentialTypeValue(Object) Then
		Return Object.IsFolder;
	EndIf;
	
	Ref = Object.Ref;
	
	If Not ValueIsFilled(Ref) Then
		Return False;
	EndIf;
	
	Return CommonUse.GetAttributeValue(Ref, "IsFolder");
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Auxiliary functions for installation of extension of work with files in web-client.

// Returns value of session parameter SuggestWorkWithFilesExtensionInstallationByDefault.
// Value returned:
//  Boolean - value of session parameter SuggestWorkWithFilesExtensionInstallationByDefault.
//
Function SessionParametersSuggestWorkWithFilesExtensionInstallationByDefault() Export
	SetPrivilegedMode(True);   
	Return SessionParameters.SuggestWorkWithFilesExtensionInstallationByDefault;
EndFunction

// Sets value of session parameter SuggestWorkWithFilesExtensionInstallationByDefault.
// Parameters:
//  Suggest  - Boolean - new value of session parameter SuggestWorkWithFilesExtensionInstallationByDefault.
//
Procedure SetSessionParameterSuggestWorkWithFilesExtensionInstallationByDefault(Suggest) Export
	SetPrivilegedMode(True);   
	SessionParameters.SuggestWorkWithFilesExtensionInstallationByDefault = Suggest;
EndProcedure	

// Saves SuggestWorkWithFilesExtensionInstallationByDefault in settings and session parameter
Procedure SaveSuggestWorkWithFilesExtensionInstallation(Suggest) Export
	
	CommonSettingsStorage.Save("ApplicationSettings", "SuggestWorkWithFilesExtensionInstallationByDefault", 
		Suggest);	
	
	// here always assign False, to avoid disturbing in this session.
	//  but to CommonSettingsStorage True can be written
	//   - and on next start we will suggest installation again
	SetSessionParameterSuggestWorkWithFilesExtensionInstallationByDefault(False);
EndProcedure	

// Assigns session parameter SuggestWorkWithFilesExtensionInstallationByDefault
// on system start.
//
// Parameters
//  ParameterName  			- String - name of the parameter being initialized
//  InitializedParameters   - Array  - array, where names of initialized
//                 session parameters are collected
//
Procedure SessionParametersInitialization(ParameterName, InitializedParameters) Export

	If ParameterName <> "SuggestWorkWithFilesExtensionInstallationByDefault" Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);   
	
	If ParameterName = "SuggestWorkWithFilesExtensionInstallationByDefault" Then
		
		SuggestInstallation = CommonSettingsStorage.Load("ApplicationSettings", 
			"SuggestWorkWithFilesExtensionInstallationByDefault");
		If SuggestInstallation = Undefined Then
			SuggestInstallation = True;
			CommonSettingsStorage.Save("ApplicationSettings", 
				"SuggestWorkWithFilesExtensionInstallationByDefault", SuggestInstallation);
		EndIf;
		
		SessionParameters.SuggestWorkWithFilesExtensionInstallationByDefault = SuggestInstallation;
		InitializedParameters.Add(ParameterName);
		
	EndIf;
	
EndProcedure 

////////////////////////////////////////////////////////////////////////////////
// Functions of determination of metadata object type

// Referencial data types
Function MetadataObjectIsDocument(MetadataObject) Export
	
	Return BaseTypeNameByMetadataObject(MetadataObject) = DocumentsClassName();
	
EndFunction

Function MetadataObjectIsCatalog(MetadataObject) Export
	
	Return BaseTypeNameByMetadataObject(MetadataObject) = CatalogsClassName();
	
EndFunction

Function MetadataObjectIsExchangePlan(MetadataObject) Export
	
	Return BaseTypeNameByMetadataObject(MetadataObject) = ExchangePlansClassName();
	
EndFunction

Function MetadataObjectIsChartOfCharacteristicTypes(MetadataObject) Export
	
	Return BaseTypeNameByMetadataObject(MetadataObject) = ChartsOfCharacteristicTypesClassName();
	
EndFunction

Function MetadataObjectIsBusinessProcess(MetadataObject) Export
	
	Return BaseTypeNameByMetadataObject(MetadataObject) = BusinessProcessesClassName();
	
EndFunction

Function MetadataObjectIsTask(MetadataObject) Export
	
	Return BaseTypeNameByMetadataObject(MetadataObject) = TasksClassName();
	
EndFunction

Function MetadataObjectIsChartOfAccounts(MetadataObject) Export
	
	Return BaseTypeNameByMetadataObject(MetadataObject) = ChartsOfAccountsClassName();
	
EndFunction

Function MetadataObjectIsChartOfCalculationTypes(MetadataObject) Export
	
	Return BaseTypeNameByMetadataObject(MetadataObject) = ChartsOfCalculationTypesClassName();
	
EndFunction

// Registers
Function MetadataObjectIsInformationRegister(MetadataObject) Export
	
	Return BaseTypeNameByMetadataObject(MetadataObject) = InformationRegistersClassName();
	
EndFunction

Function MetadataObjectIsAccumulationRegister(MetadataObject) Export
	
	Return BaseTypeNameByMetadataObject(MetadataObject) = AccumulationRegistersClassName();
	
EndFunction

Function MetadataObjectIsAccountingRegister(MetadataObject) Export
	
	Return BaseTypeNameByMetadataObject(MetadataObject) = AccountingRegistersClassName();
	
EndFunction

Function MetadataObjectIsCalculationRegister(MetadataObject) Export
	
	Return BaseTypeNameByMetadataObject(MetadataObject) = CalculationRegistersClassName();
	
EndFunction

// Constants
Function MetadataObjectIsConstant(MetadataObject) Export
	
	Return BaseTypeNameByMetadataObject(MetadataObject) = ConstantsClassName();
	
EndFunction

// Common
Function MetadataObjectIsRegister(MetadataObject) Export
	
	BaseTypeName = BaseTypeNameByMetadataObject(MetadataObject);
	
	Return BaseTypeName = InformationRegistersClassName()
		OR BaseTypeName = AccumulationRegistersClassName()
		OR BaseTypeName = AccountingRegistersClassName()
		OR BaseTypeName = CalculationRegistersClassName();
	
EndFunction

Function MetadataObjectIsOfReferentialType(MetadataObject) Export
	
	BaseTypeName = BaseTypeNameByMetadataObject(MetadataObject);
	
	Return BaseTypeName = CatalogsClassName()
		OR BaseTypeName = DocumentsClassName()
		OR BaseTypeName = BusinessProcessesClassName()
		OR BaseTypeName = TasksClassName()
		OR BaseTypeName = ChartsOfAccountsClassName()
		OR BaseTypeName = ExchangePlansClassName()
		OR BaseTypeName = ChartsOfCharacteristicTypesClassName()
		OR BaseTypeName = ChartsOfCalculationTypesClassName();
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Constants

Function InformationRegistersClassName() Export
	
	Return "InformationRegisters";
	
EndFunction

Function AccumulationRegistersClassName() Export
	
	Return "AccumulationRegisters";
	
EndFunction

Function AccountingRegistersClassName() Export
	
	Return "AccountingRegisters";
	
EndFunction

Function CalculationRegistersClassName() Export
	
	Return "CalculationRegisters";
	
EndFunction

Function DocumentsClassName() Export
	
	Return "Documents";
	
EndFunction

Function CatalogsClassName() Export
	
	Return "Catalogs";
	
EndFunction

Function ExchangePlansClassName() Export
	
	Return "ExchangePlans";
	
EndFunction

Function ChartsOfCharacteristicTypesClassName() Export
	
	Return "ChartsOfCharacteristicTypes";
	
EndFunction

Function BusinessProcessesClassName() Export
	
	Return "BusinessProcesses";
	
EndFunction

Function TasksClassName() Export
	
	Return "Tasks";
	
EndFunction

Function ChartsOfAccountsClassName() Export
	
	Return "ChartsOfAccounts";
	
EndFunction

Function ChartsOfCalculationTypesClassName() Export
	
	Return "ChartsOfCalculationTypes";
	
EndFunction

Function ConstantsClassName() Export
	
	Return "Constants";
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
//  Save and read settings

// Passes array of settings from client to server for write
//(array of structures with the fields Object Options Value)
Procedure CommonSettingsStorageSaveArray(StructuresArray) Export
	For Each Item In StructuresArray Do
		CommonSettingsStorage.Save(Item.Object, Item.Options, Item.Value);
	EndDo;
EndProcedure

// Passes setting for write from client to server
Procedure CommonSettingsStorageSave(Object, Options, Value) Export
	CommonSettingsStorage.Save(Object, Options, Value);
EndProcedure

// Passes for write from client to server
Function CommonSettingsStorageLoad(Object, Options) Export
	Return CommonSettingsStorage.Load(Object, Options);
EndFunction

Procedure FillItemCollectionOfFormDataTree(TreeItemCollection, ValueTree) Export
	
	For Each String In ValueTree.Rows Do
		
		TreeItem = TreeItemCollection.Add();
		
		FillPropertyValues(TreeItem, String);
		
		If String.Rows.Count() > 0 Then
			
			FillItemCollectionOfFormDataTree(TreeItem.GetItems(), String);
			
		EndIf;
		
	EndDo;
	
EndProcedure

Function GetConfigurationMetadataTree(Filter = Undefined) Export
	
	UseFilter = (Filter <> Undefined);
	
	CollectionsOfMetadataObjects = New ValueTable;
	CollectionsOfMetadataObjects.Columns.Add("Name");
	CollectionsOfMetadataObjects.Columns.Add("Synonym");
	CollectionsOfMetadataObjects.Columns.Add("Picture");
	CollectionsOfMetadataObjects.Columns.Add("ObjectPicture");
	
	CollectionsOfMetadataObjectsNewRow("Constants",             	  "Constants",                 		 PictureLib.Constant,              		PictureLib.Constant,                    	 CollectionsOfMetadataObjects);
	CollectionsOfMetadataObjectsNewRow("Catalogs",             		  "Catalogs",               		 PictureLib.Catalog,             		PictureLib.Catalog,                   		 CollectionsOfMetadataObjects);
	CollectionsOfMetadataObjectsNewRow("Documents",               	  "Documents",                 		 PictureLib.Document,               	PictureLib.DocumentObject,               	 CollectionsOfMetadataObjects);
	CollectionsOfMetadataObjectsNewRow("ChartsOfCharacteristicTypes", "Charts of Characteristics Types", PictureLib.ChartOfCharacteristicTypes, PictureLib.ChartOfCharacteristicTypesObject, CollectionsOfMetadataObjects);
	CollectionsOfMetadataObjectsNewRow("ChartsOfAccounts",            "Charts of Accounts",              PictureLib.ChartOfAccounts,            PictureLib.ChartOfAccountsObject,            CollectionsOfMetadataObjects);
	CollectionsOfMetadataObjectsNewRow("ChartsOfCalculationTypes",    "Charts of Calculation Types", 	 PictureLib.ChartOfCalculationTypes, 	PictureLib.ChartOfCalculationTypesObject,    CollectionsOfMetadataObjects);
	CollectionsOfMetadataObjectsNewRow("InformationRegisters",        "Information Registers",           PictureLib.InformationRegister,        PictureLib.InformationRegister,              CollectionsOfMetadataObjects);
	CollectionsOfMetadataObjectsNewRow("AccumulationRegisters",       "Accumulation Registers",          PictureLib.AccumulationRegister,       PictureLib.AccumulationRegister,             CollectionsOfMetadataObjects);
	CollectionsOfMetadataObjectsNewRow("AccountingRegisters",     	  "Accounting Registers",      		 PictureLib.AccountingRegister,     	PictureLib.AccountingRegister,           	 CollectionsOfMetadataObjects);
	CollectionsOfMetadataObjectsNewRow("CalculationRegisters",        "Calculation Registers",           PictureLib.CalculationRegister,        PictureLib.CalculationRegister,              CollectionsOfMetadataObjects);
	CollectionsOfMetadataObjectsNewRow("BusinessProcesses",           "Business Processes",           	 PictureLib.BusinessProcess,         	PictureLib.BusinessProcessObject,          	 CollectionsOfMetadataObjects);
	CollectionsOfMetadataObjectsNewRow("Tasks",                  	  "Tasks",                    		 PictureLib.Task,                 		PictureLib.TaskObject,                 		 CollectionsOfMetadataObjects);
	
	// returned function value
	MetadataTree = New ValueTree;
	MetadataTree.Columns.Add("Name");
	MetadataTree.Columns.Add("FullName");
	MetadataTree.Columns.Add("Synonym");
	MetadataTree.Columns.Add("Picture");
	
	For Each CollectionRow In CollectionsOfMetadataObjects Do
		
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
			
			MOTreeRow 			= TreeRow.Rows.Add();
			MOTreeRow.Name      = MetadataObject.Name;
			MOTreeRow.FullName  = MetadataObject.FullName();
			MOTreeRow.Synonym   = MetadataObject.Synonym;
			MOTreeRow.Picture   = CollectionRow.ObjectPicture;
			
		EndDo;
		
	EndDo;
	
	// delete rows without child items
	If UseFilter Then
		
		// use reverse order to loop over value tree
		CollectionItemsCount = MetadataTree.Rows.Count();
		
		For ReverseIndex = 1 To CollectionItemsCount Do
			
			CurrentIndex = CollectionItemsCount - ReverseIndex;
			
			TreeRow 	 = MetadataTree.Rows[CurrentIndex];
			
			If TreeRow.Rows.Count() = 0 Then
				
				MetadataTree.Rows.Delete(CurrentIndex);
				
			EndIf;
			
		EndDo;
	
	EndIf;
	
	Return MetadataTree;
	
EndFunction

Procedure CollectionsOfMetadataObjectsNewRow(Name, Synonym, Picture, ObjectPicture, Tab)
	
	NewRow 					= Tab.Add();
	NewRow.Name             = Name;
	NewRow.Synonym          = Synonym;
	NewRow.Picture          = Picture;
	NewRow.ObjectPicture    = ObjectPicture;
	
EndProcedure
