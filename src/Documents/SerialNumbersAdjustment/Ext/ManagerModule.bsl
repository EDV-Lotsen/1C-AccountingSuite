
////////////////////////////////////////////////////////////////////////////////
// Serial numbers adjustment: Manager module
//------------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
#Region PUBLIC_INTERFACE

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

//------------------------------------------------------------------------------
// Document posting

// Pre-check, lock, calculate data before write document.
Function PrepareDataBeforeWrite(AdditionalProperties, DocumentParameters, Cancel) Export
	
	// 0.1. Access data without rights checking.
	SetPrivilegedMode(True);
	
	// 0.2. Create list of query tables (according to the list of requested balances).
	PreCheck     = New Structure;
	LocksList    = New Structure;
	BalancesList = New Structure;
	
	// 0.3. Set optional accounting flags.
	
	
	// 1.1. Create a query to request data.
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	
	// 1.2. Put supplied DocumentParameters in query parameters and temporary tables.
	For Each Parameter In DocumentParameters Do
		If TypeOf(Parameter.Value) = Type("ValueTable") Then
			DocumentPosting.PutTemporaryTable(Parameter.Value, "Table_"+Parameter.Key, Query.TempTablesManager);
		ElsIf TypeOf(Parameter.Value) = Type("PointInTime") Then
			Query.SetParameter(Parameter.Key, New Boundary(Parameter.Value, BoundaryType.Excluding));
		Else
			Query.SetParameter(Parameter.Key, Parameter.Value);
		EndIf;
	EndDo;
	
	
	// 2.1. Request data for lock in registers before accessing balances.
	Query.Text = Query_SerialNumbers_Lock(LocksList);
	
	// 2.2. Proceed with locking the data.
	If Not IsBlankString(Query.Text) Then
		QueryResult = Query.ExecuteBatch();
		For Each LockTable In LocksList Do
			DocumentPosting.LockDataSourceBeforeWrite(StrReplace(LockTable.Key, "_", "."), QueryResult[LockTable.Value], DataLockMode.Exclusive);
		EndDo;
	EndIf;
	
	
	// 3.1. Query for register balances excluding document data (if it already affected to).
	Query.Text = Query_SerialNumbers_Balance(BalancesList);
	
	// 3.2. Save balances in posting parameters.
	If Not IsBlankString(Query.Text) Then
		QueryResult = Query.ExecuteBatch();
		For Each BalanceTable In BalancesList Do
			PreCheck.Insert(BalanceTable.Key, QueryResult[BalanceTable.Value].Unload());
		EndDo;
		Query.TempTablesManager.Close();
	EndIf;
	
	// 3.3. Put structure of prechecked registers in additional properties.
	If PreCheck.Count() > 0 Then
		AdditionalProperties.Posting.Insert("PreCheck", PreCheck);
	EndIf;
	
EndFunction

// Collect document data for posting on the server (in terms of document).
Function PrepareDataStructuresForPosting(DocumentRef, AdditionalProperties, RegisterRecords) Export
	Var PreCheck;
	
	//------------------------------------------------------------------------------
	// 1. Prepare structures for querying data.
	
	// Create list of posting tables (according to the list of registers).
	TablesList = New Structure;
	
	// Create a query to request document data.
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	
	//------------------------------------------------------------------------------
	// 2. Prepare query text.
	
	// Query for document's tables.
	Query.Text = Query.Text +
	             Query_SerialNumbers(TablesList);
	
	//------------------------------------------------------------------------------
	// 3. Execute query and fill data structures.
	
	// Execute query, fill temporary tables with postings data.
	If Not IsBlankString(Query.Text) Then
		// Fill data from precheck.
		If AdditionalProperties.Posting.Property("PreCheck", PreCheck) And PreCheck.Count() > 0 Then
			For Each PreCheckTable In PreCheck Do
				DocumentPosting.PutTemporaryTable(PreCheckTable.Value, PreCheckTable.Key, Query.TempTablesManager);
			EndDo;
		EndIf;
		
		// Execute query.
		QueryResult = Query.ExecuteBatch();
		
		// Save documents table in posting parameters.
		For Each DocumentTable In TablesList Do
			ResultTable = QueryResult[DocumentTable.Value].Unload();
			If Not DocumentPosting.IsTemporaryTable(ResultTable) Then
				AdditionalProperties.Posting.PostingTables.Insert(DocumentTable.Key, ResultTable);
			EndIf;
		EndDo;
	EndIf;
	
	//------------------------------------------------------------------------------
	// 4. Final check of posting data correctness (i.e. negative balances and s.o.).
	
	// Clear used temporary tables manager.
	Query.TempTablesManager.Close();
	
	// Fill list of registers to check (non-negative) balances in posting parameters.
	FillRegistersCheckList(AdditionalProperties, RegisterRecords);
	
EndFunction

// Collect document data for posting on the server (in terms of document).
Function PrepareDataStructuresForPostingClearing(DocumentRef, AdditionalProperties, RegisterRecords) Export
	
	// Fill list of registers to check (non-negative) balances in posting parameters.
	FillRegistersCheckList(AdditionalProperties, RegisterRecords);
	
EndFunction

//------------------------------------------------------------------------------
// Document fill check processing

//------------------------------------------------------------------------------
// Document filling

//------------------------------------------------------------------------------
// Document printing

#EndIf

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region COMMANDS_HANDLERS

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

//------------------------------------------------------------------------------
// Document printing

#EndIf

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region PRIVATE_IMPLEMENTATION

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

//------------------------------------------------------------------------------
// Document posting

// Query for dimensions lock data.
Function Query_SerialNumbers_Lock(TablesList)
	
	// Add SerialNumbers - Lock table to locks structure.
	TablesList.Insert("InformationRegister_SerialNumbers", TablesList.Count());
	
	// Collect dimensions for serial numbers locking.
	QueryText =
	"SELECT
	// ------------------------------------------------------
	// Dimensions
	|	&Product                              AS Product
	// ------------------------------------------------------
	|";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for balances data.
Function Query_SerialNumbers_Balance(TablesList)
	
	// Add SerialNumbers - Balances table to balances structure.
	TablesList.Insert("Table_SerialNumbers_Balance", TablesList.Count());
	
	// Collect serial numbers balances.
	QueryText =
	"SELECT
	// ------------------------------------------------------
	// Dimensions
	|	SerialNumbers.Product                 AS Product,
	|	SerialNumbers.SerialNumber            AS SerialNumber,
	// ------------------------------------------------------
	// Resources
	|	SerialNumbers.OnHand                  AS OnHand
	// ------------------------------------------------------
	|FROM
	|	InformationRegister.SerialNumbers.SliceLast(&PointInTime, Product = &Product)
	|	                                      AS SerialNumbers";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_SerialNumbers(TablesList)
	
	// Add SerialNumbers table to document structure.
	TablesList.Insert("Table_SerialNumbers", TablesList.Count());
	
	// Collect serial numbers data.
	QueryText =
	"SELECT // Update serial numbers with new data.
	// ------------------------------------------------------
	// Standard attributes
	|	SerialNumbersTbl.Ref                  AS Recorder,
	|	SerialNumbersTbl.Ref.Date             AS Period,
	|	0                                     AS LineNumber,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Dimensions
	|	SerialNumbersTbl.Ref.Product          AS Product,
	|	SerialNumbersTbl.SerialNumber         AS SerialNumber,
	// ------------------------------------------------------
	// Resources
	|	SerialNumbersTbl.OnHand               AS OnHand
	// ------------------------------------------------------
	// Attributes
	// ------------------------------------------------------
	|FROM
	|	Document.SerialNumbersAdjustment.SerialNumbers AS SerialNumbersTbl
	|	LEFT JOIN Table_SerialNumbers_Balance AS SerialNumbersBalance
	|		ON  SerialNumbersTbl.Ref.Product  = SerialNumbersBalance.Product
	|		AND SerialNumbersTbl.SerialNumber = SerialNumbersBalance.SerialNumber
	|WHERE
	|	SerialNumbersTbl.Ref = &Ref
	|	// Change found
	|	AND SerialNumbersTbl.OnHand <> ISNULL(SerialNumbersBalance.OnHand, False)
	|
	|UNION ALL
	|
	|SELECT // Delete unused serial numbers.
	// ------------------------------------------------------
	// Standard attributes
	|	SerialNumbersAdjustment.Ref           AS Recorder,
	|	SerialNumbersAdjustment.Date          AS Period,
	|	0                                     AS LineNumber,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Dimensions
	|	SerialNumbersBalance.Product          AS Product,
	|	SerialNumbersBalance.SerialNumber     AS SerialNumber,
	// ------------------------------------------------------
	// Resources
	|	False                                 AS OnHand
	// ------------------------------------------------------
	// Attributes
	// ------------------------------------------------------
	|FROM
	|	Table_SerialNumbers_Balance AS SerialNumbersBalance
	|	LEFT JOIN Document.SerialNumbersAdjustment.SerialNumbers AS SerialNumbersTbl
	|		ON  SerialNumbersTbl.Ref.Product  = SerialNumbersBalance.Product
	|		AND SerialNumbersTbl.SerialNumber = SerialNumbersBalance.SerialNumber
	|	LEFT JOIN Document.SerialNumbersAdjustment AS SerialNumbersAdjustment
	|		ON SerialNumbersAdjustment.Ref = &Ref
	|WHERE
	|	// Serial is not declared.
	|	SerialNumbersTbl.OnHand IS NULL";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Put structure of registers, which balance should be checked during posting.
Procedure FillRegistersCheckList(AdditionalProperties, RegisterRecords)
	
	// Create structure of registers and its resources to check balances.
	BalanceCheck = New Structure;
	
	// Fill structure depending on document write mode.
	If AdditionalProperties.Posting.WriteMode = DocumentWriteMode.Posting Then
		// Add register to check it's recordset changes and balances during posting.
	ElsIf AdditionalProperties.Posting.WriteMode = DocumentWriteMode.UndoPosting Then
		// Add register to check it's recordset changes and balances during posting.
	EndIf;
	
	// Return structure of registers to check.
	If BalanceCheck.Count() > 0 Then
		AdditionalProperties.Posting.Insert("BalanceCheck", BalanceCheck);
	EndIf;
	
EndProcedure

//------------------------------------------------------------------------------
// Document filling

//------------------------------------------------------------------------------
// Document printing

#EndIf

#EndRegion

