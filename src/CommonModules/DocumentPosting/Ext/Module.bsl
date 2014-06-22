
////////////////////////////////////////////////////////////////////////////////
// Document posting: Server module
//------------------------------------------------------------------------------
// Available on:
// - Server
// - External Connection
//

////////////////////////////////////////////////////////////////////////////////
#Region PUBLIC_INTERFACE

//------------------------------------------------------------------------------
// Supplemental functions checking state of selected flags of document/recordset objects

// Check presence of boolean flag in document properties and returns it value.
// If flag don't exist, False is returned.
//
// Parameters:
//  Properties - Structure - Document parameters containing required attributes and tables.
//  Flag       - String    - Name of requested property in Properties structure.
//
// Returns:
//  Boolean    - Value of property.
//
Function FlagValue(Properties, Flag) Export
	Var FlagValue;
	
	Return Properties.Property(Flag, FlagValue) And FlagValue;
	
EndFunction

// Check flag of new document.
//
// Parameters:
//  AdditionalProperties - Structure - Document parameters containing required attributes and tables.
//    * IsNew            - Boolean   - New document flag.
//
// Returns:
//  Boolean - Value of new document flag.
//
Function IsNew(AdditionalProperties) Export
	
	Return FlagValue(AdditionalProperties, "IsNew");
	
EndFunction

// Check flag of presence of manual adjustment in the document postings.
//
// Parameters:
//  AdditionalProperties - Structure - Document parameters containing required attributes and tables.
//    * ManualAdjustment - Boolean   - Manual adjustment flag.
//
// Returns:
//  Boolean - Value of manual adjustment flag.
//
Function ManualAdjustment(AdditionalProperties) Export
	
	Return FlagValue(AdditionalProperties, "ManualAdjustment");
	
EndFunction

// Check flag of registration of changes in postings only.
//
// Parameters:
//  AdditionalProperties - Structure - Additional record set parameters containing required attributes and tables.
//    * WriteChangesOnly - Boolean   - Registration of changes only flag.
//
// Returns:
//  Boolean - Value of registration of changes only flag.
//
Function WriteChangesOnly(AdditionalProperties) Export
	
	Return FlagValue(AdditionalProperties, "WriteChangesOnly");
	
EndFunction

// Check if passed table is not a query result but temporary table summary.
//
// Parameters:
//  Table - ValueTable - Table to be checked against query result.
//
// Returns:
//  Boolean - Is a temporary table summary.
//
Function IsTemporaryTable(Table) Export
	
	// Check table columns.
	If Table.Columns.Count() = 1 Then
		
		// Examine the first column.
		CheckColumn = Table.Columns[0];
		If  CheckColumn.Name       = "Count"
		And CheckColumn.Title      = "Count"
		And CheckColumn.Width      = 32
		And CheckColumn.ValueType  = New TypeDescription("Number")
		Then
			// This is definitely temporary table summary.
			Return True;
		EndIf;
		
	EndIf;
	
	// The table doesn't match the temporary table criteria.
	Return False;
	
EndFunction

//------------------------------------------------------------------------------
// Preparing the document data before write an object

// Save additional document parameters required for posting before writing an object.
//
// Parameters:
//  AdditionalProperties - Structure - Additional object parameters containing required attributes and tables.
//  DocumentParameters   - Structure - Object attributes, inaccessible on the server call to be packed into AdditionalProperties structure.
//  Cancel               - Boolean   - Flag of transaction cancel.
//  WriteMode            - DocumentWriteMode   - Invoked document writing mode (write or posting).
//  PostingMode          - DocumentPostingMode - Invoked document posting mode (real-time or regular).
//
Procedure PrepareDataStructuresBeforeWrite(AdditionalProperties, DocumentParameters, Cancel, WriteMode, PostingMode) Export
	
	// Cache document attributes minimizing data requests - pack posting parameters into AdditionalProperties.
	For Each DocumentParameter In DocumentParameters Do
		AdditionalProperties.Insert(DocumentParameter.Key, DocumentParameter.Value);
	EndDo;
	
	// Posting - Structure containing data to be transferred on the server and post the document.
	AdditionalProperties.Insert("Posting", New Structure);
	
	// Specify Writing / Posting mode of document.
	AdditionalProperties.Posting.Insert("WriteMode",   WriteMode);
	AdditionalProperties.Posting.Insert("PostingMode", PostingMode);
	
EndProcedure

// Performs managed (manual) lock of object data
// preventing other clients reding data which will be changed during posting transaction.
//
// Parameters:
//  ObjectName   - String       - Name of object where datalock will be applied.
//  DataSource   - QueryResult  - Contains flat table having all requred dimensions in columns.
//  DataLockMode - DataLockMode - Shared or Exclusive.
//
Procedure LockDataSourceBeforeWrite(ObjectName, DataSource, DataLockMode) Export
	
	// Create new managed data lock.
	DataLock = New DataLock;
	
	// Set data lock parameters.
	LockItem = DataLock.Add(ObjectName);
	LockItem.Mode = DataLockMode;
	LockItem.DataSource = DataSource;
	For Each Column In DataSource.Columns Do
		LockItem.UseFromDataSource(Column.Name, Column.Name);
	EndDo;
	
	// Set lock on the object.
	DataLock.Lock();
	
EndProcedure

//------------------------------------------------------------------------------
// Creating/filling/clearing additional document properties during document posting

// Save data and structures which will be used in posting procedure as additional parameters of object.
//
// Parameters:
//  AdditionalProperties - Structure - Additional object parameters (to be filled).
//
Procedure PrepareDataStructuresBeforePosting(AdditionalProperties) Export
	
	// PostingTables - Structure containing document tables data for posting the document.
	AdditionalProperties.Posting.Insert("PostingTables", New Structure);
	
	// TempTablesManager - Temporary tables manager, containing document data requested for creating document postings.
	AdditionalProperties.Posting.Insert("StructTempTablesManager", New Structure("TempTablesManager", New TempTablesManager));
	
EndProcedure

// Clear used additional document data passed as additional properties.
//
// Parameters:
//  AdditionalProperties - Structure - Additional object parameters (to be cleared).
//    * Posting          - Structure - Structure of document posting parameters.
//       ** StructTempTablesManager  - Structure - Structure containing temporary tables.
//          *** TempTablesManager    - TempTablesManager - Manager of temporary tables.
//
Procedure ClearDataStructuresAfterPosting(AdditionalProperties) Export
	
	// Dispose used temporary tables managers.
	AdditionalProperties.Posting.StructTempTablesManager.TempTablesManager.Close();
	
EndProcedure

//------------------------------------------------------------------------------
// Document's recordset changing - common handlers

// Prepares recordsets of the document to be posted in registers.
// 1. Clear old records from recordset (required for thick client only).
// 2. Trigger flag Write for records, which document has on previous posting.
// 3. Switch manually adjusted recordsets to the active state.
// 4. Writes empty recordsets if previously posted document has new date shifted forward.
// Called from document module on posting.
//
// Parameters:
//  AdditionalProperties - Structure                 - Additional object parameters containing required attributes and tables.
//  RegisterRecords      - RegisterRecordsCollection - Document postings list, which will be filled during document posting.
//  ForcedClearWriteRecordsetsBeforePosing - Boolean - Defines forced writing recordsets before posting the document:
//    False: Registers, having postings, will be cleared, but not written in the database (required for analyse of current state);
//    True:  All registers having document postings will be foced written before posting the document (analyse is not required).
//
Procedure PrepareRecordSetsForPosting(AdditionalProperties, RegisterRecords, ForcedClearWriteRecordsetsBeforePosing = False) Export
	
	// Skip recordset processing for new documents.
	If IsNew(AdditionalProperties) Then
		Return;
	EndIf;
	
	// Create array of registers which having postings and thus require forced write.
	ArrayOfRegistersHavingDocumentPostings = GetArrayOfRegistersHavingDocumentPostings(
	                                         AdditionalProperties.Ref,
	                                         AdditionalProperties.Metadata.RegisterRecords);
	
	// Mark all of register recordsets, where document has postings, for writing.
	For Each RegisterName In ArrayOfRegistersHavingDocumentPostings Do
		RegisterRecords[RegisterName].Write = True;
	EndDo;
	
	// Process manual postings.
	If ManualAdjustment(AdditionalProperties) Then
		
		// Reactivate manually created register records.
		For Each RegisterName In ArrayOfRegistersHavingDocumentPostings Do
			RegisterRecords[RegisterName].Read();
			RegisterRecords[RegisterName].SetActive(True);
		EndDo;
		
	// Process automatical postings.
	Else
		// Clear existing postings in all registers, where document has bookings.
		For Each RecordSet In RegisterRecords Do
			If RecordSet.Count() > 0 Then
				RecordSet.Clear();
			EndIf;
		EndDo;
		
		// Process forced clearing of data sets (performs forced check of register balances).
		If ForcedClearWriteRecordsetsBeforePosing Then
			For Each RegisterName In ArrayOfRegistersHavingDocumentPostings Do
				// Forced write of registers.
				RegisterRecords[RegisterName].Write();
				RegisterRecords[RegisterName].Write = False;
			EndDo;
		EndIf;
		
	EndIf;
	
EndProcedure

// Prepares recordsets of the document to clearing posted records in registers.
// 1. Trigger flag Write for records, which document has on a posting.
// 2. Switch manually adjusted recordsets to the inactive state.
// Called from document module on undo posting.
//
// Parameters:
//  AdditionalProperties - Structure                 - Additional object parameters containing required attributes and tables.
//  RegisterRecords      - RegisterRecordsCollection - Document postings list, which will be cleared during document posting clearing.
//
Procedure PrepareRecordSetsForPostingClearing(AdditionalProperties, RegisterRecords) Export
	
	// Create array of registers which are require forced cleaning.
	ArrayOfRegistersHavingDocumentPostings = GetArrayOfRegistersHavingDocumentPostings(
	                                         AdditionalProperties.Ref,
	                                         AdditionalProperties.Metadata.RegisterRecords);
	
	// Mark all of register recordsets, where document has postings, for writing.
	For Each RegisterName In ArrayOfRegistersHavingDocumentPostings Do
		RegisterRecords[RegisterName].Write = True;
	EndDo;
	
	// Process manual postings.
	If ManualAdjustment(AdditionalProperties) Then
		
		// Deactivate manually created register records.
		For Each RegisterName In ArrayOfRegistersHavingDocumentPostings Do
			RegisterRecords[RegisterName].Read();
			RegisterRecords[RegisterName].SetActive(False);
		EndDo;
		RegisterRecords.Write();
		
	// Process automatical postings.
	Else
		// Postings will be automatically cleared on writing the datasets.
	EndIf;
	
EndProcedure

// Write prepared recordsets into document's register records.
//
// Parameters:
//  AdditionalProperties - Structure                 - Additional object parameters containing required attributes and tables.
//  RegisterRecords      - RegisterRecordsCollection - Document postings list, which is filled during document posting.
//  Cancel               - Boolean                   - Flag of transaction cancel.
//
Procedure FillRecordSets(AdditionalProperties, RegisterRecords, Cancel) Export
	Var TableRecordSet;
	
	// Write prepared table of records to the Document's RecordSet.
	For Each RecordSet In RegisterRecords Do
		
		// Get recordset name by it's presentation (without accessing to metadata properties).
		RecordSetFullName = String(RecordSet);
		RecordSetName = Mid(RecordSetFullName, Find(RecordSetFullName,".") + 1);
		
		// Get postings table from Additional properties of Document.
		If AdditionalProperties.Posting.PostingTables.Property(
			StrReplace("Table_{Recordset}", "{Recordset}", RecordSetName),
			TableRecordSet) Then
			
			// Skip posting if none of items present.
			If Cancel Or TableRecordSet.Count() = 0 Then
				Continue;
			EndIf;
			
			// Load prepared postings into register.
			RecordSet.Write = True;
			RecordSet.Load(TableRecordSet);
		EndIf;
	EndDo;
	
EndProcedure

// Writes document records to appropriate recordsets.
// Copies additional parameters into recordsets modules for registration
// of recordsets changes (to avoid full reposting of document).
//
// Parameters:
//  AdditionalProperties - Structure                 - Additional object parameters containing required attributes and tables.
//  RegisterRecords      - RegisterRecordsCollection - Document postings list, which is filled during document posting.
//
Procedure WriteRecordSets(AdditionalProperties, RegisterRecords) Export
	Var BalanceCheck;
	
	// Create list of registers to create table of changes.
	If AdditionalProperties.Posting.Property("BalanceCheck", BalanceCheck) Then
		For Each BalanceRegister In BalanceCheck Do
			
			// Fill recordset properties.
			RecordSet = RegisterRecords[BalanceRegister.Key];
			If RecordSet.Write Then
				
				// Assign additional recordset properties for posting register records.
				RecordSet.AdditionalProperties.Insert("IsNew", IsNew(AdditionalProperties));
				RecordSet.AdditionalProperties.Insert("WriteChangesOnly", True);
				RecordSet.AdditionalProperties.Insert("Metadata", RecordSet.Metadata());
				
				// Structure of temporary tables to pass it to recordset.
				RecordSet.AdditionalProperties.Insert("Posting", New Structure);
				RecordSet.AdditionalProperties.Posting.Insert("StructTempTablesManager",
					AdditionalProperties.Posting.StructTempTablesManager);
				
				// Pass an array of checked register resources to recordset.
				RecordSet.AdditionalProperties.Posting.Insert("CheckPostings",
					BalanceRegister.Value.CheckPostings);
			EndIf;
		EndDo;
	EndIf;
	
	// Proceed with write of document records.
	RegisterRecords.Write();
	
EndProcedure

//------------------------------------------------------------------------------
// Check recordset changes

// Prepares a table of old document register records before write recordset.
// Used on document reposting to deteremine required balance check of register.
// Result is placed in temporary tables manager defined in additional properties.
//
// Parameters:
//  Recorder             - DocumentRef - Recorder placing register records into recordset.
//  AdditionalProperties - Structure   - Additional recordset parameters containing required attributes and tables.
//  Cancel               - Boolean     - Flag of transaction cancel.
//
Procedure CheckRecordsetChangesBeforeWrite(Recorder, AdditionalProperties, Cancel) Export
	Var CheckPostings;
	
	// Skip checking if resources for checking are not defined.
	If Not AdditionalProperties.Posting.Property("CheckPostings", CheckPostings)
	   Or CheckPostings.Count() = 0 Then
		Return;
	EndIf;
	
	// 0. Current recordset is placed in temporary table RegisterRecords[<Register name>]
	// to compare new recordset (on write) with previous which already exists.
	Query = New Query;
	Query.SetParameter("Recorder", Recorder);
	Query.SetParameter("IsNew",    AdditionalProperties.IsNew);
	Query.TempTablesManager =      AdditionalProperties.Posting.StructTempTablesManager.TempTablesManager;
	
	// 1. Create a query for all of register records, containing dimensions and resources.
	QueryText = 
	"SELECT
	|	{Selection}
	|INTO
	|	RegisterRecords_{Register}_BeforeWrite
	|FROM
	|	AccumulationRegister.{Register} AS Table
	|WHERE
	|	Table.Recorder = &Recorder
	|	AND (NOT &IsNew)";
	
	// 2. Add to query dimensions and resources of register.
	SelectionText = "Table.Period AS Period";
	For Each Dimension In AdditionalProperties.Metadata.Dimensions Do
		DimensionText = StrReplace("Table.{Dimension} AS {Dimension}", "{Dimension}", Dimension.Name);
		SelectionText = ?(IsBlankString(SelectionText), DimensionText, SelectionText+",
			|	"+DimensionText);
	EndDo;
	For Each Resource In AdditionalProperties.Metadata.Resources Do
		ResourceText  = StrReplace("CASE WHEN Table.RecordType = VALUE(AccumulationRecordType.Receipt) THEN -Table.{Resource} ELSE Table.{Resource} END AS {Resource}_BeforeWrite", "{Resource}", Resource.Name);
		SelectionText = ?(IsBlankString(SelectionText), ResourceText, SelectionText+",
			|	"+ResourceText);
	EndDo;
	QueryText = StrReplace(QueryText, "{Selection}", SelectionText);
	
	// 3. Combine final query text.
	QueryText = StrReplace(QueryText, "{Register}",  AdditionalProperties.Metadata.Name);
	
	// 4. Complete and execute query. Result is placed in temporary table.
	Query.Text = QueryText;
	Query.Execute();
	
EndProcedure

// Compares a table of old document postings with new ones written to the register.
// Used on document reposting to deteremine required balance check of register.
// Result is placed in structure of temporary tables manager in additional properties.
//
// Parameters:
//  Recorder             - DocumentRef - Recorder placing register records into recordset.
//  AdditionalProperties - Structure   - Additional recordset parameters containing required attributes and tables.
//  Cancel               - Boolean     - Flag of transaction cancel.
//
Procedure CheckRecordsetChangesOnWrite(Recorder, AdditionalProperties, Cancel) Export
	Var CheckPostings;
	
	// Skip checking if resources for checking are not defined.
	If Not AdditionalProperties.Posting.Property("CheckPostings", CheckPostings)
	   Or CheckPostings.Count() = 0 Then
		Return;
	EndIf;
	
	// 0. Current recordset is placed in temporary table RegisterRecords[<Register name>]
	// to compare new recordset (on write) with previous which already exists.
	Query = New Query;
	Query.SetParameter("Recorder", Recorder);
	Query.TempTablesManager =      AdditionalProperties.Posting.StructTempTablesManager.TempTablesManager;
	
	// 1. Create a query for all of register records, containing dimensions and having changes in resources.
	QueryText =
	"SELECT
	|	{Selection}
	|INTO
	|	RegisterRecords_{Register}_Diff
	|FROM
	|	({NestedQuery_BeforeWrite}
	|
	|	UNION ALL
	|
	|	{NestedQuery_OnWrite}
	|
	|	WHERE
	|		TableOnWrite.Recorder = &Recorder) AS TableDiff
	|GROUP BY
	|	{GroupBy}
	|HAVING
	|	({Having})
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|DROP RegisterRecords_{Register}_BeforeWrite";
	
	// Add to query dimensions and resources of register.
	SelectionText = "TableDiff.Period AS Period";
	For Each Dimension In AdditionalProperties.Metadata.Dimensions Do
		DimensionText = StrReplace("TableDiff.{Dimension} AS {Dimension}", "{Dimension}", Dimension.Name);
		SelectionText = ?(IsBlankString(SelectionText), DimensionText, SelectionText+",
			|	"+DimensionText);
	EndDo;
	For Each Resource In AdditionalProperties.Metadata.Resources Do
		ResourceText  = StrReplace("SUM(TableDiff.{Resource}_Diff) AS {Resource}_Diff", "{Resource}", Resource.Name);
		SelectionText = ?(IsBlankString(SelectionText), ResourceText, SelectionText+",
			|	"+ResourceText);
	EndDo;
	QueryText = StrReplace(QueryText, "{Selection}", SelectionText);
	
	// 2. Create query reading data saved before write.
	NestedQuery_BeforeWrite = 
		"SELECT
	|		{Selection}
	|	FROM
	|		RegisterRecords_{Register}_BeforeWrite AS TableBeforeWrite";
	
	// Add to query dimensions and resources of register.
	SelectionText = "TableBeforeWrite.Period AS Period";
	For Each Dimension In AdditionalProperties.Metadata.Dimensions Do
		DimensionText = StrReplace("TableBeforeWrite.{Dimension} AS {Dimension}", "{Dimension}", Dimension.Name);
		SelectionText = ?(IsBlankString(SelectionText), DimensionText, SelectionText+",
			|		"+DimensionText);
	EndDo;
	For Each Resource In AdditionalProperties.Metadata.Resources Do
		ResourceText  = StrReplace("TableBeforeWrite.{Resource}_BeforeWrite AS {Resource}_Diff", "{Resource}", Resource.Name);
		SelectionText = ?(IsBlankString(SelectionText), ResourceText, SelectionText+",
			|		"+ResourceText);
	EndDo;
	NestedQuery_BeforeWrite = StrReplace(NestedQuery_BeforeWrite, "{Selection}", SelectionText);
	QueryText = StrReplace(QueryText, "{NestedQuery_BeforeWrite}", NestedQuery_BeforeWrite);
	
	// 3. Create query reading actual data produced on write.
	NestedQuery_OnWrite = 
		"SELECT
	|		{Selection}
	|	FROM
	|		AccumulationRegister.{Register} AS TableOnWrite";
	
	// Add to query dimensions and resources of register.
	SelectionText = "TableOnWrite.Period";
	For Each Dimension In AdditionalProperties.Metadata.Dimensions Do
		DimensionText = StrReplace("TableOnWrite.{Dimension}", "{Dimension}", Dimension.Name);
		SelectionText = ?(IsBlankString(SelectionText), DimensionText, SelectionText+",
			|		"+DimensionText);
	EndDo;
	For Each Resource In AdditionalProperties.Metadata.Resources Do
		ResourceText  = StrReplace("CASE WHEN TableOnWrite.RecordType = VALUE(AccumulationRecordType.Receipt) THEN TableOnWrite.{Resource} ELSE -TableOnWrite.{Resource} END", "{Resource}", Resource.Name);
		SelectionText = ?(IsBlankString(SelectionText), ResourceText, SelectionText+",
			|		"+ResourceText);
	EndDo;
	NestedQuery_OnWrite = StrReplace(NestedQuery_OnWrite, "{Selection}", SelectionText);
	QueryText = StrReplace(QueryText, "{NestedQuery_OnWrite}", NestedQuery_OnWrite);
	
	// 4. Complete GroupBy clause.
	SelectionText = "TableDiff.Period";
	For Each Dimension In AdditionalProperties.Metadata.Dimensions Do
		DimensionText = StrReplace("TableDiff.{Dimension}", "{Dimension}", Dimension.Name);
		SelectionText = ?(IsBlankString(SelectionText), DimensionText, SelectionText+",
			|	"+DimensionText);
	EndDo;
	QueryText = StrReplace(QueryText, "{GroupBy}", SelectionText);
	
	// 5. Complete Having clause.
	SelectionText = "";
	For Each CheckDiff In CheckPostings Do
		ResourceCheck = StringFunctionsClientServer.SplitStringIntoSubstringArray(CheckDiff);
		ResourceText  = StrReplace("SUM({Resource}) {Sign} {Value}", "{Resource}", ResourceCheck[0]);
		ResourceText  = StrReplace(ResourceText, "{Sign}", ResourceCheck[1]);
		ResourceText  = StrReplace(ResourceText, "{Value}", ResourceCheck[2]);
		ResourceText  = StrReplace(ResourceText, "{Table}", "TableDiff");
		ResourceText  = StrReplace(ResourceText, "{Posting}", "_Diff");
		SelectionText = ?(IsBlankString(SelectionText), ResourceText, SelectionText+"
			|	OR "+ResourceText);
	EndDo;
	QueryText = StrReplace(QueryText, "{Having}", SelectionText);
	
	// 6. Combine final query text.
	QueryText = StrReplace(QueryText, "{Register}",  AdditionalProperties.Metadata.Name);
	
	// 7. Complete and execute query. Result is placed in temporary table.
	Query.Text = QueryText;
	Selection  = Query.ExecuteBatch()[0].Select();
	Selection.Next();
	
	// 8. Add table with changes into additional parameters of recordset.
	AdditionalProperties.Posting.StructTempTablesManager.Insert(StrReplace("RegisterRecords_{Register}_Diff", "{Register}", AdditionalProperties.Metadata.Name), Selection.Count > 0);
	
EndProcedure

//------------------------------------------------------------------------------
// Check registers balances

// Check posting result (non-negative balances and s.o.).
//
// Parameters:
//  AdditionalProperties - Structure - Additional object parameters containing required attributes and tables.
//  PostingParameters    - Structure - Object and transaction parameters, inaccessible on the server call to be packed into AdditionalProperties.
//  Cancel               - Boolean   - Flag of transaction cancel.
//
Procedure CheckPostingResults(AdditionalProperties, RegisterRecords, Cancel) Export
	Var BalanceCheck, CheckBalances, CheckMessages;
	
	// Skip check if no balance registers are present.
	If Not AdditionalProperties.Posting.Property("BalanceCheck", BalanceCheck)
	   Or BalanceCheck.Count() = 0 Then
		Return;
	EndIf;
	
	// 0. Create query to temporary tables having differences in postings.
	Query        = New Query;
	QueryText    = "";
	QueryTables  = AdditionalProperties.Posting.StructTempTablesManager;
	CheckList    = New Array;
	
	// 1. Create a query for register balances, which document can affect changing it's postings.
	For Each QueryTable In QueryTables Do
		
		// 1.1.Skip service data, tables having no changes, incomplete balances check specification.
		TableName       = QueryTable.Key;
		TableHasChanges = QueryTable.Value;
		
		// Skip TempTablesManager itself and tables having no changes.
		If (TableName = "TempTablesManager") Or (Not TableHasChanges) Then
			Continue;
		EndIf;
		
		// Define register for balance check by table name.
		CheckRegister = StrReplace(TableName,     "RegisterRecords_", ""); // Table name has following format:
		CheckRegister = StrReplace(CheckRegister, "_Diff",            ""); // RegisterRecords_{Register}_Diff
		
		// Skip checking if resources for balance checking are not defined.
		If    Not BalanceCheck[CheckRegister].Property("CheckBalances", CheckBalances)
		   Or Not BalanceCheck[CheckRegister].Property("CheckMessages", CheckMessages)
		   Or CheckBalances.Count() <> CheckMessages.Count()
		   Or CheckBalances.Count() = 0
		Then
			Continue;
		EndIf;
		
		// 1.2. Add changed register in checklist.
		CheckList.Add(CheckRegister);
		
		// 1.3. Request register structure from metadata.
		RegisterMetadata = RegisterRecords[CheckRegister].AdditionalProperties.Metadata;
		
		// 1.4. Create query template for balnces of selected register.
		QueryText = QueryText + // Primary check for actual balances.
		"SELECT
		|	{Selection}
		|INTO
		|	RegisterBalance_{Register}
		|FROM
		|	AccumulationRegister.{Register}.Balance(,
		|		{Filter}) AS Balances
		|WHERE
		|	{Condition}";
		
		// Additional check of in-time balances for new document posted by back-date or a document that already saved.
		If Not IsNew(AdditionalProperties) Or BegOfDay(AdditionalProperties.Date) < BegOfDay(CurrentSessionDate()) Then
			QueryText = QueryText + "
			|
			|UNION
			|
			|SELECT
			|	{Selection}
			|FROM
			|	AccumulationRegister.{Register}.Balance(&PointInTime,
			|		{Filter}) AS Balances
			|WHERE
			|	{Condition}";
		EndIf;
		
		// 1.5. Add to query dimensions and resources of register.
		SelectionText = "";
		For Each Dimension In RegisterMetadata.Dimensions Do
			DimensionText = StrReplace("Balances.{Dimension} AS {Dimension}", "{Dimension}", Dimension.Name);
			SelectionText = ?(IsBlankString(SelectionText), DimensionText, SelectionText+",
				|	"+DimensionText);
		EndDo;
		For Each Resource In RegisterMetadata.Resources Do
			ResourceText  = StrReplace("Balances.{Resource}Balance AS {Resource}", "{Resource}", Resource.Name);
			SelectionText = ?(IsBlankString(SelectionText), ResourceText, SelectionText+",
				|	"+ResourceText);
		EndDo;
		QueryText = StrReplace(QueryText, "{Selection}", SelectionText);
		
		// 1.6. Complete Filter by differences found during posting.
		FilterText =
				"({Selection}) IN
		|			({NestedQuery})";
		
		// Add dimensions of register to balances filter.
		SelectionText = "";
		For Each Dimension In RegisterMetadata.Dimensions Do
			DimensionText = Dimension.Name;
			SelectionText = ?(IsBlankString(SelectionText), DimensionText, SelectionText+", "+DimensionText);
		EndDo;
		FilterText = StrReplace(FilterText, "{Selection}", SelectionText);
		
		// Add nested query to differences table in temporary tables manager.
		NestedQuery = 
					"SELECT
		|				{Selection}
		|			FROM
		|				RegisterRecords_{Register}_Diff AS TableDiff";
		
		// Add to query dimensions of register.
		SelectionText = "";
		For Each Dimension In RegisterMetadata.Dimensions Do
			DimensionText = StrReplace("TableDiff.{Dimension}", "{Dimension}", Dimension.Name);
			SelectionText = ?(IsBlankString(SelectionText), DimensionText, SelectionText+",
				|				"+DimensionText);
		EndDo;
		NestedQuery = StrReplace(NestedQuery, "{Selection}",   SelectionText);
		FilterText  = StrReplace(FilterText,  "{NestedQuery}", NestedQuery);
		QueryText   = StrReplace(QueryText,   "{Filter}",      FilterText);
		
		// 1.7. Complete Where clause.
		SelectionText = "";
		For Each CheckBalance In CheckBalances Do
			ResourceCheck = StringFunctionsClientServer.SplitStringIntoSubstringArray(CheckBalance);
			ResourceText  = StrReplace("{Resource} {Sign} {Value}", "{Resource}", ResourceCheck[0]);
			ResourceText  = StrReplace(ResourceText, "{Sign}", ResourceCheck[1]);
			ResourceText  = StrReplace(ResourceText, "{Value}", ResourceCheck[2]);
			ResourceText  = StrReplace(ResourceText, "{Table}", "Balances");
			ResourceText  = StrReplace(ResourceText, "{Balance}", "Balance");
			SelectionText = ?(IsBlankString(SelectionText), ResourceText, SelectionText+"
				|	OR "+ResourceText);
		EndDo;
		QueryText = StrReplace(QueryText, "{Condition}", SelectionText);
		
		// 1.8. Combine query text for a selected register.
		QueryText = StrReplace(QueryText, "{Register}",  CheckRegister);
		
		// 1.9. Add delimiter to a query.
		QueryText = QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	EndDo;
	
	// 2. Skip check if no changes in balance registers are found.
	If CheckList.Count() = 0 Then
		Return;
	EndIf;
	
	// 3.1. Set query parameters.
	If IsNew(AdditionalProperties) And BegOfDay(AdditionalProperties.Date) < BegOfDay(CurrentSessionDate()) Then
		// New document posted in back-date.
		Query.SetParameter("PointInTime", New Boundary(EndOfDay(AdditionalProperties.Date), BoundaryType.Including));
	ElsIf Not IsNew(AdditionalProperties) Then
		// Document was already saved.
		Query.SetParameter("PointInTime",
			New Boundary(New PointInTime(AdditionalProperties.Date, AdditionalProperties.Ref), BoundaryType.Including));
	EndIf;
	
	// 3.2. Execute batch query.
	Query.TempTablesManager = QueryTables.TempTablesManager;
	Query.Text  = QueryText;
	QueryResult = Query.ExecuteBatch();
	
	// 4. Create messages for user about insufficient balances.
	MessageTemplate   = "";
	MessageParams     = New Structure;
	ParamsFormat      = New Structure;
	QuantityFormat    = GeneralFunctionsReusable.DefaultQuantityFormat();
	QuantityTypeDescr = New TypeDescription("Number", New NumberQualifiers(15, 4));
	AmountFormat      = GeneralFunctionsReusable.DefaultAmountFormat();
	AmountTypeDescr   = New TypeDescription("Number", New NumberQualifiers(15, 2));
	SubQuery          = Undefined;
	Errors            = 0;
	I = -1;
	For Each Result In QueryResult Do
		I = I + 1;
		
		// 4.1. Skip empty tables (positive balanced registers).
		Selection = Result.Select();
		If Not Selection.Next() Or Selection.Count = 0 Then
			Continue;
		EndIf;
		
		// 4.2. Error found - create individual massages for each register.
		CheckRegister    = CheckList[I];
		RegisterMetadata = RegisterRecords[CheckRegister].AdditionalProperties.Metadata;
		
		// 4.3. Create value table with unique combination of register dimension
		//     (to reduce count of possible errors about the same dimensions).
		SearchRec = New Structure;
		ReportedCombinations = New ValueTable;
		For Each Dimension In RegisterMetadata.Dimensions Do
			ReportedCombinations.Columns.Add(Dimension.Name);
		EndDo;
		
		// 4.4. Create new query for detection, which trigger alarmed.
		If SubQuery = Undefined Then
			SubQuery = New Query;
			SubQuery.TempTablesManager = QueryTables.TempTablesManager;
		EndIf;
		
		// 4.5. Request data from temporary table.
		QueryText =
		"SELECT
		|	*
		|FROM
		|	RegisterBalance_{Register} AS Table
		|WHERE
		|	{Condition}";
		
		// 4.6. Test each condition and create individual message.
		J = -1;
		For Each CheckBalance In CheckBalances Do
			J = J + 1;
			
			// 4.6.1. Select condition to check from list of conditions.
			ResourceCheck  = StringFunctionsClientServer.SplitStringIntoSubstringArray(CheckBalance);
			ResourceText   = StrReplace("{Resource} {Sign} {Value}", "{Resource}", ResourceCheck[0]);
			ResourceText   = StrReplace(ResourceText, "{Sign}", ResourceCheck[1]);
			ResourceText   = StrReplace(ResourceText, "{Value}", ResourceCheck[2]);
			ResourceText   = StrReplace(ResourceText, "{Table}", "Table");
			ResourceText   = StrReplace(ResourceText, "{Balance}", "");
			
			// 4.6.2. Create subquery based on query template.
			SubQueryText   = StrReplace(QueryText,    "{Condition}", ResourceText);
			SubQueryText   = StrReplace(SubQueryText, "{Register}",  CheckRegister);
			
			// 4.6.3. Execute query to a temporary table and fill appropriate message with correct data.
			SubQuery.Text  = SubQueryText;
			SubQueryResult = SubQuery.Execute();
			
			// 4.6.4. Skip unused conditions.
			If SubQueryResult.IsEmpty() Then
				Continue;
			EndIf;
			Selection = SubQueryResult.Select();
			
			// 4.6.5. Get formatted message template.
			MessageTemplate = CheckMessages[J];
			MessageParams.Clear();
			ParamsFormat.Clear();
			
			// 4.6.6. Cycle through found errors and fill appropriate messages.
			While Selection.Next() Do
				
				// 4.6.6.1. Skip already reported errors (by dimensions combinations).
				For Each Dimension In RegisterMetadata.Dimensions Do
					SearchRec.Insert(Dimension.Name, Selection[Dimension.Name]);
				EndDo;
				If ReportedCombinations.FindRows(SearchRec).Count() > 0 Then
					// Skip message.
					Continue;
				Else
					// Add combination to cache.
					ReportedCombination = ReportedCombinations.Add();
					FillPropertyValues(ReportedCombination, SearchRec);
				EndIf;
				
				// 4.6.6.2. Create message text.
				For Each Dimension In RegisterMetadata.Dimensions Do
					
					// Skip unused presentations.
					If Find(MessageTemplate, "{"+Dimension.Name+"}") = 0 Then Continue; EndIf;
					
					// Convert value to it's presentation.
					Value = Selection[Dimension.Name];
					If TypeOf(Value) = Type("CatalogRef.Companies") Then
						Presentation = TrimAll(Value.Code) + " " + TrimAll(Value.Description);
						
					ElsIf TypeOf(Value) = Type("CatalogRef.Products") Then
						Presentation = TrimAll(Value.Code) + " " + TrimAll(Value.Description);
						
					Else
						Presentation = TrimAll(Value);
					EndIf;
					
					// Add parameters for message filling.
					MessageParams.Insert(Dimension.Name, Presentation);
				EndDo;
				
				For Each Resource In RegisterMetadata.Resources Do
					
					// Skip unused presentations.
					If Find(MessageTemplate, "{"+Resource.Name+"}") + Find(MessageTemplate, "{-"+Resource.Name+"}") = 0 Then Continue; EndIf;
					
					// Add parameters for message filling.
					MessageParams.Insert(Resource.Name, Selection[Resource.Name]);
					
					// Apply special formatting to resources.
					If Resource.Type = QuantityTypeDescr Then
						ParamsFormat.Insert(Resource.Name, QuantityFormat);
					ElsIf Resource.Type = AmountTypeDescr Then
						ParamsFormat.Insert(Resource.Name, AmountFormat);
					EndIf;
				EndDo;
				
				// Fill pattern with parameters.
				MessageText = StringFunctionsClientServer.SubstituteParametersInStringByName(MessageTemplate, MessageParams, ParamsFormat);
				
				// 4.6.6.3. Transfer message to user.
				Errors = Errors + 1;
				If Errors <= 10 Then // There is no need to inform user more then 10 times.
					CommonUseClientServer.MessageToUser(MessageText, AdditionalProperties.Ref,,, Cancel);
				EndIf;
			EndDo;
		EndDo;
	EndDo;
	
	// 4.6.7. Inform user about remaining errors.
	If Errors > 10 Then
		MessageText = NStr("en = 'There are also %1 error(s) found'");
		MessageText = StringFunctionsClientServer.SubstituteParametersInString(MessageText, Format(Errors-10, "NFD=0; NG=0"));
		CommonUseClientServer.MessageToUser(MessageText, AdditionalProperties.Ref,,, Cancel);
	EndIf;
	
	// 5. Create message about common status of operation.
	If Cancel Then
		If AdditionalProperties.Posting.WriteMode = DocumentWriteMode.Posting Then
			MessageText = NStr("en = 'Posting aborted'");
		ElsIf AdditionalProperties.Posting.WriteMode = DocumentWriteMode.UndoPosting Then
			MessageText = NStr("en = 'Posting can''t be canceled'");
		EndIf;
		CommonUseClientServer.MessageToUser(MessageText, AdditionalProperties.Ref);
	EndIf;
	
EndProcedure

//------------------------------------------------------------------------------
// Service query functions

// Returns text delimiter (comment string) for visual splitting of batch query.
//
// Returns:
//  String - Batch query delimiter.
//
Function GetDelimeterOfBatchQuery() Export
	
	// Create delimiter text.
	DelimiterText =
	";
	|
	|////////////////////////////////////////////////////////////////////////////////
	|";
	
	Return DelimiterText;
	
EndFunction

// Converts linear query result to structure.
// Structure contains keys from column names, and values from first line of query result.
//
// Parameters:
//  QueryResult - QueryResult - Linear query result to be converted to structure.
//
// Returns:
//  Structure   - Query data converted from query result.
//
Function GetStructureFromQueryResult(QueryResult) Export
	
	// Structure of returned parameters.
	ParametersStructure = New Structure;
	
	// Fill structure with query values.
	Selection = QueryResult.Select();
	Selection.Next();
	For Each Column In QueryResult.Columns Do
		ParametersStructure.Insert(Column.Name, Selection[Column.Name]);
	EndDo;
	
	// Return filled structure.
	Return ParametersStructure;
	
EndFunction

// Returns content of temporary table in particular tables manager.
// Used for debugging of posting procedures.
//
// Parameters:
//  TempTablesManager - TempTablesManager - Temporary tables manager (storage of queried data).
//  TempTableName     - String            - Name of required temporary table in a manager.
//
// Returns:
//  ValueTable - Containing requested temporary table from manager.
//
Function GetTemporaryTable(TempTablesManager, TempTableName) Export
	
	// Query full content of temporary table by it's name in a manager.
	QueryText = 
	"SELECT
	|	*
	|FROM
	|	{TempTableName}";
	
	// Assign parameters to query.
	Query = New Query;
	Query.Text = StrReplace(QueryText, "{TempTableName}", TempTableName);
	Query.TempTablesManager = TempTablesManager;
	
	// Execute query and return the table to user.
	Return Query.Execute().Unload();
	
EndFunction

// Puts value table into temporary tables manager to access it in batch query.
// If TempTablesManager is omitted then new TempTablesManager will be created.
//
// Parameters:
//  TempTableData     - ValueTable        - Unloaded value table data.
//  TempTableName     - String            - Name of temporary table in a manager.
//  TempTablesManager - TempTablesManager - Temporary tables manager (to put value table into).
//
// Returns:
//  TempTablesManager - New TempTablesManager containing requested temporary table (if not supplied).
//
Function PutTemporaryTable(TempTableData, TempTableName, TempTablesManager = Undefined) Export
	
	// Create a query to put value table.
	Query = New Query;
	
	// Assign TempTablesManager to a query.
	If TempTablesManager = Undefined Then
		Query.TempTablesManager = New TempTablesManager;
	Else
		Query.TempTablesManager = TempTablesManager;
	EndIf;
	
	// Query full content of value table and put it by it's name in a manager.
	QueryText =
	"SELECT
	|	*
	|INTO
	|	{TempTableName}
	|FROM
	|	&{TempTableName} AS {TempTableName}";
	Query.Text = StrReplace(QueryText, "{TempTableName}", TempTableName);
	Query.SetParameter(TempTableName, TempTableData);
	Query.ExecuteBatch();
	
	// If temporary tables manager is not supplied - will be returnd as value.
	If TempTablesManager = Undefined Then
		Return Query.TempTablesManager;
	Else
		// Protection against lost temporary tables.
		Return Undefined;
	EndIf;
	
EndFunction

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region PRIVATE_IMPLEMENTATION

// Creates array of register names, where the document has recorded it's bookings.
//
// Parameters:
//  DocumentRef     - DocumentRef              - Reference for listing of register names.
//  RegisterRecords - MetadataObjectCollection - Metadata of document, containing list of registers, where bookings of document can be recorded.
//  ArrayOfExcludedRegisters           - Array - List of registers to skip checking of register records (strings).
//
// Returns:
//  Array - Names of registers (strings).
//
Function GetArrayOfRegistersHavingDocumentPostings(DocumentRef, RegisterRecords, ArrayOfExcludedRegisters = Undefined)
	
	// Create a query and set predefined filter by document.
	Query = New Query;
	Query.SetParameter("Recorder", DocumentRef);
	
	// Result: Array of registers names.
	Result = New Array;
	MaxTablesInQuery = 256;
	
	// Initialize counters.
	CounterTables = 0;
	CounterRecordings = 0;
	TotalRecordings = RegisterRecords.Count();
	QueryText = "";
	
	// Cycle through registers available for document.
	For Each RegisterRecord In RegisterRecords Do
		// Update iterator.
		CounterRecordings = CounterRecordings + 1;
		
		// Check skipping of register.
		SkipRegister = ArrayOfExcludedRegisters <> Undefined
		           And ArrayOfExcludedRegisters.Find(RegisterRecord.Name) <> Undefined;
		
		// Add register records to query text.
		If Not SkipRegister Then
			
			// Add UNION to query.
			If CounterTables > 0 Then
				QueryText = QueryText + "
				|UNION ALL
				|";
			EndIf;
			
			// Add register name to query.
			CounterTables = CounterTables + 1;
			QueryText = QueryText + 
			"
			|SELECT TOP 1
			|""" + RegisterRecord.Name + """ AS RegisterName
			|
			|FROM " + RegisterRecord.FullName() + "
			|
			|WHERE Recorder = &Recorder
			|";
		EndIf;
		
		// Execute query by using not more then MaxTablesInQuery tables in the same query.
		If CounterTables = MaxTablesInQuery Or CounterRecordings = TotalRecordings Then
			// Apply assembled query text.
			Query.Text = QueryText;
			QueryText = "";
			CounterTables = 0;
			
			// Add query result to an array.
			If Result.Count() = 0 Then
				// First query - unload query result to an array.
				Result = Query.Execute().Unload().UnloadColumn("RegisterName");
			Else
				// Add query result to an array.
				Selection = Query.Execute().Select();
				While Selection.Next() Do
					Result.Add(Selection.RegisterName);
				EndDo;
			EndIf;
		EndIf;
	EndDo;
	
	// Return registers list.
	Return Result;
EndFunction

#EndRegion