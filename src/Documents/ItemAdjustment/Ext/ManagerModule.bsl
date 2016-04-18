
////////////////////////////////////////////////////////////////////////////////
// Item adjustment: Manager module
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
	InventoryPosting = True; // Post always.
	
	
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
	Query.Text = "";
	If InventoryPosting Then
		Query.Text = Query.Text +
		             Query_InventoryJournal_Lock(LocksList);
	EndIf;
	
	// 2.2. Proceed with locking the data.
	If Not IsBlankString(Query.Text) Then
		QueryResult = Query.ExecuteBatch();
		For Each LockTable In LocksList Do
			DocumentPosting.LockDataSourceBeforeWrite(StrReplace(LockTable.Key, "_", "."), QueryResult[LockTable.Value], DataLockMode.Exclusive);
		EndDo;
	EndIf;
	
	
	// 3.1. Query for register balances excluding document data (if it already affected to).
	Query.Text = "";
	If InventoryPosting Then
		Query.Text = Query.Text +
		             Query_InventoryJournal_Balance(BalancesList);
		
		// Reuse locked inventory items list.
		DocumentPosting.PutTemporaryTable(QueryResult[LocksList.AccumulationRegister_InventoryJournal].Unload(),
		                                  "Table_InventoryJournal_Lock", Query.TempTablesManager);
	EndIf;
	
	// 3.3. Save balances in posting parameters.
	If Not IsBlankString(Query.Text) Then
		QueryResult = Query.ExecuteBatch();
		For Each BalanceTable In BalancesList Do
			PreCheck.Insert(BalanceTable.Key, QueryResult[BalanceTable.Value].Unload());
		EndDo;
		Query.TempTablesManager.Close();
	EndIf;
	
	// 3.4. Put structure of prechecked registers in additional properties.
	If PreCheck.Count() > 0 Then
		AdditionalProperties.Posting.Insert("PreCheck", PreCheck);
	EndIf;
	
EndFunction

// Collect document data for posting on the server (in terms of document).
Function PrepareDataStructuresForPosting(DocumentRef, AdditionalProperties, RegisterRecords) Export
	Var PreCheck;
	
	//------------------------------------------------------------------------------
	// 1. Prepare structures for querying data.
	
	// Set optional accounting flags.
	InventoryPosting      = True; // Post always.
	GeneralJournalPosting = True; // Post always.
	
	// Create list of posting tables (according to the list of registers).
	TablesList = New Structure;
	
	// Create a query to request document data.
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	
	//------------------------------------------------------------------------------
	// 2. Prepare query text.
	
	// Query for document's tables.
	Query.Text   = "";
	If InventoryPosting Then
		Query.Text = Query.Text +
		             Query_InventoryJournal_LineItems(TablesList) +
		             Query_InventoryJournal_Balance_Quantity(TablesList) +
		             Query_InventoryJournal_Balance_FIFO(TablesList) +
		             Query_InventoryJournal(TablesList);
	EndIf;
	If GeneralJournalPosting Then
		Query.Text = Query.Text +
		             Query_GeneralJournal(TablesList)+
				 	 //--//GJ++
	             	 Query_GeneralJournalAnalyticsDimensions_Transactions(TablesList) +
				 	 Query_GeneralJournalAnalyticsDimensions(TablesList) +
				 	 //--//GJ--
					 Query_CashFlowData(TablesList);

	EndIf;
	
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

// Query for document data.
Function Query_InventoryJournal_LineItems(TablesList)
	
	// Add InventoryJournal - line items table to document structure.
	TablesList.Insert("Table_InventoryJournal_LineItems", TablesList.Count());
	
	// Collect inventory data.
	QueryText =
	
	"SELECT // FIFO, WAve for quantity and amount calculation
	// ------------------------------------------------------
	// Dimensions
	|	LineItems.Product.CostingMethod          AS Type,
	|	LineItems.Product                        AS Product,
	|	LineItems.Location                       AS Location,
	|	LineItems.Layer                          AS Layer,
	// ------------------------------------------------------
	// Resources
	|	LineItems.Quantity                       AS QuantityRequested,
	|	LineItems.Amount                         AS AmountRequested
	// ------------------------------------------------------
	|INTO
	|	Table_InventoryJournal_LineItems
	|FROM
	|	Document.ItemAdjustment AS LineItems
	|WHERE
	|	    LineItems.Ref                   = &Ref
	|	AND LineItems.Product.Type          = VALUE(Enum.InventoryTypes.Inventory)";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_InventoryJournal_Balance_Quantity(TablesList)
	
	// Add InventoryJournal - items balance table to document structure.
	TablesList.Insert("Table_InventoryJournal_Balance_Quantity", TablesList.Count());
	
	// Collect inventory data.
	QueryText =
	"SELECT // FIFO
	// ------------------------------------------------------
	// Dimensions
	|	InventoryJournalBalance.Type             AS Type,
	|	InventoryJournalBalance.Product          AS Product,
	|	InventoryJournalBalance.Location         AS Location,
	// ------------------------------------------------------
	// Agregates
	|	SUM(InventoryJournalBalance.Quantity)    AS Quantity,
	|	0                                        AS Amount
	// ------------------------------------------------------
	|INTO
	|	Table_InventoryJournal_Balance_Quantity
	|FROM
	|	Table_InventoryJournal_Balance AS InventoryJournalBalance
	|WHERE
	|	InventoryJournalBalance.Type = VALUE(Enum.InventoryCosting.FIFO)
	|GROUP BY
	|	InventoryJournalBalance.Type,
	|	InventoryJournalBalance.Product,
	|	InventoryJournalBalance.Location
	|
	|UNION ALL
	|
	|SELECT // WAve for quantity calcualtion
	// ------------------------------------------------------
	// Dimensions
	|	InventoryJournalBalance.Type             AS Type,
	|	InventoryJournalBalance.Product          AS Product,
	|	InventoryJournalBalance.Location         AS Location,
	// ------------------------------------------------------
	// Agregates
	|	SUM(InventoryJournalBalance.Quantity)    AS Quantity,
	|	0                                        AS Amount
	// ------------------------------------------------------
	|FROM
	|	Table_InventoryJournal_Balance AS InventoryJournalBalance
	|WHERE
	|	    InventoryJournalBalance.Type      = VALUE(Enum.InventoryCosting.WeightedAverage)
	|	AND InventoryJournalBalance.Location <> VALUE(Catalog.Locations.EmptyRef)
	|GROUP BY
	|	InventoryJournalBalance.Type,
	|	InventoryJournalBalance.Product,
	|	InventoryJournalBalance.Location
	|
	|UNION ALL
	|
	|SELECT // WAve for amount calcualtion
	// ------------------------------------------------------
	// Dimensions
	|	InventoryJournalBalance.Type             AS Type,
	|	InventoryJournalBalance.Product          AS Product,
	|	VALUE(Catalog.Locations.EmptyRef)        AS Location,
	// ------------------------------------------------------
	// Agregates
	|	SUM(InventoryJournalBalance.Quantity)    AS Quantity,
	|	SUM(InventoryJournalBalance.Amount)      AS Amount
	// ------------------------------------------------------
	|FROM
	|	Table_InventoryJournal_Balance AS InventoryJournalBalance
	|WHERE
	|	InventoryJournalBalance.Type = VALUE(Enum.InventoryCosting.WeightedAverage)
	|GROUP BY
	|	InventoryJournalBalance.Type,
	|	InventoryJournalBalance.Product";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_InventoryJournal_Balance_FIFO(TablesList)
	
	// Add InventoryJournal balance table to document structure.
	TablesList.Insert("Table_InventoryJournal_Balance_FIFO", TablesList.Count());
	
	// Collect inventory data.
	QueryText =
	"SELECT
	// ------------------------------------------------------
	// Dimensions
	|	InventoryJournalBalance.Product          AS Product,
	|	InventoryJournalBalance.Location         AS Location,
	|	InventoryJournalBalance.Layer            AS Layer,
	// ------------------------------------------------------
	// Resources
	|	InventoryJournalBalance.Quantity         AS Quantity,
	|	InventoryJournalBalance.Amount           AS Amount,
	// ------------------------------------------------------
	// Agregates
	|	SUM(InventoryJournalCumulative.Quantity) AS QuantityCumulative,
	|	SUM(InventoryJournalCumulative.Amount)   AS AmountCumulative
	// ------------------------------------------------------
	|INTO
	|	Table_InventoryJournal_Balance_FIFO
	|FROM
	|	Table_InventoryJournal_Balance AS InventoryJournalBalance
	|	LEFT JOIN Table_InventoryJournal_Balance AS InventoryJournalCumulative
	|		ON  InventoryJournalBalance.Product =  InventoryJournalCumulative.Product
	|		AND InventoryJournalBalance.Location = InventoryJournalCumulative.Location
	|		AND InventoryJournalBalance.Layer.PointInTime >= InventoryJournalCumulative.Layer.PointInTime
	|WHERE
	|	InventoryJournalBalance.Type = VALUE(Enum.InventoryCosting.FIFO)
	|GROUP BY
	|	InventoryJournalBalance.Product,
	|	InventoryJournalBalance.Location,
	|	InventoryJournalBalance.Layer,
	|	InventoryJournalBalance.Quantity,
	|	InventoryJournalBalance.Amount";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_InventoryJournal(TablesList)
	
	// Add InventoryJournal table to document structure.
	TablesList.Insert("Table_InventoryJournal", TablesList.Count());
	
	// Collect inventory data.
	QueryText =
	"SELECT // Receipt, FIFO, Auto & Manual layering, Amount storno with possible negative balances.
	// ------------------------------------------------------
	// Standard attributes
	|	ItemAdjustment.Ref                    AS Recorder,
	|	ItemAdjustment.Date                   AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Dimensions
	|	LineItems_FIFO.Product                AS Product,
	|	LineItems_FIFO.Location               AS Location,
	|	CASE
	|		// Auto layering
	|		WHEN LineItems_FIFO.Layer = Undefined                                THEN ItemAdjustment.Ref
	|		WHEN LineItems_FIFO.Layer = VALUE(Document.ItemAdjustment.EmptyRef)  THEN ItemAdjustment.Ref
	|		WHEN LineItems_FIFO.Layer = VALUE(Document.PurchaseInvoice.EmptyRef) THEN ItemAdjustment.Ref
	|		WHEN LineItems_FIFO.Layer = VALUE(Document.SalesReturn.EmptyRef)     THEN ItemAdjustment.Ref
	|		// Manual layering
	|		ELSE LineItems_FIFO.Layer
	|	END                                   AS Layer,
	// ------------------------------------------------------
	// Resources
	|	LineItems_FIFO.QuantityRequested      AS Quantity,
	|	LineItems_FIFO.AmountRequested        AS Amount
	// ------------------------------------------------------
	// Attributes
	// ------------------------------------------------------
	|FROM
	|	Table_InventoryJournal_LineItems AS LineItems_FIFO
	|	LEFT JOIN Document.ItemAdjustment AS ItemAdjustment
	|		ON True
	|WHERE
	|	ItemAdjustment.Ref = &Ref
	|	// Receipt
	|	AND (LineItems_FIFO.QuantityRequested > 0
	|	 OR (LineItems_FIFO.QuantityRequested = 0 AND LineItems_FIFO.AmountRequested > 0))
	|	// FIFO
	|	AND LineItems_FIFO.Type = VALUE(Enum.InventoryCosting.FIFO)
	|	// Revaluation defined
	|	AND // Quantity > 0 OR Amount <> 0
	|	(LineItems_FIFO.QuantityRequested > 0 OR
	|	 LineItems_FIFO.AmountRequested <> 0)
	|
	|UNION ALL
	|
	|SELECT // Expense, FIFO, Auto layering, Normal balances.
	// ------------------------------------------------------
	// Standard attributes
	|	ItemAdjustment.Ref                    AS Recorder,
	|	ItemAdjustment.Date                   AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Dimensions
	|	Balance_FIFO.Product                  AS Product,
	|	Balance_FIFO.Location                 AS Location,
	|	Balance_FIFO.Layer                    AS Layer,
	// ------------------------------------------------------
	// Resources
	|	CASE
	|		WHEN Balance_FIFO.QuantityCumulative <= -LineItems_FIFO.QuantityRequested
	|		// The layer written off completely.
	|		THEN Balance_FIFO.Quantity
	|		// The layer written partially or left off.
	|		ELSE CASE
	|			WHEN Balance_FIFO.Quantity - LineItems_FIFO.QuantityRequested - Balance_FIFO.QuantityCumulative > 0
	|			// The layer written off partially.
	|			THEN Balance_FIFO.Quantity - LineItems_FIFO.QuantityRequested - Balance_FIFO.QuantityCumulative
	|			// The layer is not requested and left off.
	|			ELSE 0
	|		END
	|	END                                   AS Quantity,
	|	CASE
	|		WHEN Balance_FIFO.AmountCumulative <= -LineItems_FIFO.AmountRequested
	|		// The layer written off completely.
	|		THEN Balance_FIFO.Amount
	|		// The layer written partially or left off.
	|		ELSE CASE
	|			WHEN Balance_FIFO.Amount - LineItems_FIFO.AmountRequested - Balance_FIFO.AmountCumulative > 0
	|			// The layer written off partially.
	|			THEN Balance_FIFO.Amount - LineItems_FIFO.AmountRequested - Balance_FIFO.AmountCumulative
	|			// The layer is not requested and left off.
	|			ELSE 0
	|		END
	|	END                                   AS Amount
	// ------------------------------------------------------
	// Attributes
	// ------------------------------------------------------
	|FROM
	|	Table_InventoryJournal_Balance_FIFO AS Balance_FIFO
	|	LEFT JOIN Table_InventoryJournal_LineItems AS LineItems_FIFO
	|		ON  Balance_FIFO.Product  = LineItems_FIFO.Product
	|		AND Balance_FIFO.Location = LineItems_FIFO.Location
	|	LEFT JOIN Document.ItemAdjustment AS ItemAdjustment
	|		ON True
	|WHERE
	|	ItemAdjustment.Ref = &Ref
	|	// Expense
	|	AND (LineItems_FIFO.QuantityRequested < 0
	|	 OR (LineItems_FIFO.QuantityRequested = 0 AND LineItems_FIFO.AmountRequested < 0))
	|	// FIFO
	|	AND LineItems_FIFO.Type   = VALUE(Enum.InventoryCosting.FIFO)
	|	// Auto layering
	|	AND (LineItems_FIFO.Layer = Undefined                                OR
	|	     LineItems_FIFO.Layer = VALUE(Document.ItemAdjustment.EmptyRef)  OR
	|	     LineItems_FIFO.Layer = VALUE(Document.PurchaseInvoice.EmptyRef) OR
	|	     LineItems_FIFO.Layer = VALUE(Document.SalesReturn.EmptyRef))
	|	// Revaluation defined
	|	AND // Quantity > 0 OR Amount > 0
	|	(CASE
	|		WHEN Balance_FIFO.QuantityCumulative <= -LineItems_FIFO.QuantityRequested
	|		// The layer written off completely.
	|		THEN Balance_FIFO.Quantity
	|		// The layer written partially or left off.
	|		ELSE CASE
	|			WHEN Balance_FIFO.Quantity - LineItems_FIFO.QuantityRequested - Balance_FIFO.QuantityCumulative > 0
	|			// The layer written off partially.
	|			THEN Balance_FIFO.Quantity - LineItems_FIFO.QuantityRequested - Balance_FIFO.QuantityCumulative
	|			// The layer is not requested and left off.
	|			ELSE 0
	|		END
	|	END > 0 OR
	|	CASE
	|		WHEN Balance_FIFO.AmountCumulative <= -LineItems_FIFO.AmountRequested
	|		// The layer written off completely.
	|		THEN Balance_FIFO.Amount
	|		// The layer written partially or left off.
	|		ELSE CASE
	|			WHEN Balance_FIFO.Amount - LineItems_FIFO.AmountRequested - Balance_FIFO.AmountCumulative > 0
	|			// The layer written off partially.
	|			THEN Balance_FIFO.Amount - LineItems_FIFO.AmountRequested - Balance_FIFO.AmountCumulative
	|			// The layer is not requested and left off.
	|			ELSE 0
	|		END
	|	END > 0)
	|
	|UNION ALL
	|
	|SELECT // Expense, FIFO, Auto layering, Negative balances.
	// ------------------------------------------------------
	// Standard attributes
	|	ItemAdjustment.Ref                    AS Recorder,
	|	ItemAdjustment.Date                   AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Dimensions
	|	LineItems_FIFO.Product                AS Product,
	|	LineItems_FIFO.Location               AS Location,
	|	NULL                                  AS Layer,
	// ------------------------------------------------------
	// Resources
	|	CASE
	|		// Check quantity balance
	|		WHEN -LineItems_FIFO.QuantityRequested > ISNULL(Balance_FIFO.Quantity, 0)
	|		// The balance became negative
	|		THEN -LineItems_FIFO.QuantityRequested - ISNULL(Balance_FIFO.Quantity, 0)
	|		// The balance still positive or zeroed.
	|		ELSE 0
	|	END                                   AS Quantity,
	|	CASE
	|		// Check amount balance
	|		WHEN -LineItems_FIFO.AmountRequested > ISNULL(Balance_FIFO.Amount, 0)
	|		// The balance became negative
	|		THEN -LineItems_FIFO.AmountRequested - ISNULL(Balance_FIFO.Amount, 0)
	|		// The balance still positive or zeroed.
	|		ELSE 0
	|	END                                   AS Amount
	// ------------------------------------------------------
	// Attributes
	// ------------------------------------------------------
	|FROM
	|	Table_InventoryJournal_LineItems AS LineItems_FIFO
	|	LEFT JOIN Table_InventoryJournal_Balance_Quantity AS Balance_FIFO
	|		ON  Balance_FIFO.Product  = LineItems_FIFO.Product
	|		AND Balance_FIFO.Location = LineItems_FIFO.Location
	|	LEFT JOIN Document.ItemAdjustment AS ItemAdjustment
	|		ON True
	|WHERE
	|	ItemAdjustment.Ref = &Ref
	|	// Expense
	|	AND (LineItems_FIFO.QuantityRequested < 0
	|	 OR (LineItems_FIFO.QuantityRequested = 0 AND LineItems_FIFO.AmountRequested < 0))
	|	// FIFO
	|	AND LineItems_FIFO.Type   = VALUE(Enum.InventoryCosting.FIFO)
	|	// Auto layering
	|	AND (LineItems_FIFO.Layer = Undefined                                OR
	|	     LineItems_FIFO.Layer = VALUE(Document.ItemAdjustment.EmptyRef)  OR
	|	     LineItems_FIFO.Layer = VALUE(Document.PurchaseInvoice.EmptyRef) OR
	|	     LineItems_FIFO.Layer = VALUE(Document.SalesReturn.EmptyRef))
	|	// Revaluation defined
	|	AND // Quantity > 0 OR Amount > 0
	|	(CASE
	|		// Check quantity balance
	|		WHEN -LineItems_FIFO.QuantityRequested > ISNULL(Balance_FIFO.Quantity, 0)
	|		// The balance became negative
	|		THEN -LineItems_FIFO.QuantityRequested - ISNULL(Balance_FIFO.Quantity, 0)
	|		// The balance still positive or zeroed.
	|		ELSE 0
	|	END > 0 OR
	|	CASE
	|		// Check amount balance
	|		WHEN -LineItems_FIFO.AmountRequested > ISNULL(Balance_FIFO.Amount, 0)
	|		// The balance became negative
	|		THEN -LineItems_FIFO.AmountRequested - ISNULL(Balance_FIFO.Amount, 0)
	|		// The balance still positive or zeroed.
	|		ELSE 0
	|	END > 0)
	|
	|UNION ALL
	|
	|SELECT // Expense by quantity, Receipt by amount, FIFO, Auto layering, Amount only.
	// ------------------------------------------------------
	// Standard attributes
	|	ItemAdjustment.Ref                    AS Recorder,
	|	ItemAdjustment.Date                   AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Dimensions
	|	LineItems_FIFO.Product                AS Product,
	|	LineItems_FIFO.Location               AS Location,
	|	ItemAdjustment.Ref                    AS Layer,
	// ------------------------------------------------------
	// Resources
	|	0                                     AS Quantity,
	|	CASE
	|		// Check amount storno
	|		WHEN LineItems_FIFO.AmountRequested > 0
	|		// Storno amount
	|		THEN LineItems_FIFO.AmountRequested
	|		ELSE 0
	|	END                                   AS Amount
	// ------------------------------------------------------
	// Attributes
	// ------------------------------------------------------
	|FROM
	|	Table_InventoryJournal_LineItems AS LineItems_FIFO
	|	LEFT JOIN Table_InventoryJournal_Balance_Quantity AS Balance_FIFO
	|		ON  Balance_FIFO.Product  = LineItems_FIFO.Product
	|		AND Balance_FIFO.Location = LineItems_FIFO.Location
	|	LEFT JOIN Document.ItemAdjustment AS ItemAdjustment
	|		ON True
	|WHERE
	|	ItemAdjustment.Ref = &Ref
	|	// Expense
	|	AND LineItems_FIFO.QuantityRequested < 0
	|	// FIFO
	|	AND LineItems_FIFO.Type   = VALUE(Enum.InventoryCosting.FIFO)
	|	// Auto layering
	|	AND (LineItems_FIFO.Layer = Undefined                                OR
	|	     LineItems_FIFO.Layer = VALUE(Document.ItemAdjustment.EmptyRef)  OR
	|	     LineItems_FIFO.Layer = VALUE(Document.PurchaseInvoice.EmptyRef) OR
	|	     LineItems_FIFO.Layer = VALUE(Document.SalesReturn.EmptyRef))
	|	// Revaluation defined
	|	AND // Amount > 0
	|	CASE
	|		// Check amount storno
	|		WHEN LineItems_FIFO.AmountRequested > 0
	|		// Storno amount
	|		THEN LineItems_FIFO.AmountRequested
	|		ELSE 0
	|	END > 0
	|
	|UNION ALL
	|
	|SELECT // Expense, FIFO, Manual layering, Amount storno & Negative balances.
	// ------------------------------------------------------
	// Standard attributes
	|	ItemAdjustment.Ref                    AS Recorder,
	|	ItemAdjustment.Date                   AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Dimensions
	|	LineItems_FIFO.Product                AS Product,
	|	LineItems_FIFO.Location               AS Location,
	|	LineItems_FIFO.Layer                  AS Layer,
	// ------------------------------------------------------
	// Resources
	|	-LineItems_FIFO.QuantityRequested     AS Quantity,
	|	-LineItems_FIFO.AmountRequested       AS Amount
	// ------------------------------------------------------
	// Attributes
	// ------------------------------------------------------
	|FROM
	|	Table_InventoryJournal_LineItems AS LineItems_FIFO
	|	LEFT JOIN Document.ItemAdjustment AS ItemAdjustment
	|		ON True
	|WHERE
	|	ItemAdjustment.Ref = &Ref
	|	// Expense
	|	AND (LineItems_FIFO.QuantityRequested < 0
	|	 OR (LineItems_FIFO.QuantityRequested = 0 AND LineItems_FIFO.AmountRequested < 0))
	|	// FIFO
	|	AND LineItems_FIFO.Type    = VALUE(Enum.InventoryCosting.FIFO)
	|	// Manual layering
	|	AND (LineItems_FIFO.Layer <> Undefined                                AND
	|	     LineItems_FIFO.Layer <> VALUE(Document.ItemAdjustment.EmptyRef)  AND
	|	     LineItems_FIFO.Layer <> VALUE(Document.PurchaseInvoice.EmptyRef) AND
	|	     LineItems_FIFO.Layer <> VALUE(Document.SalesReturn.EmptyRef))
	|	// Revaluation defined
	|	AND // Quantity > 0 OR Amount <> 0
	|	(-LineItems_FIFO.QuantityRequested > 0 OR
	|	 -LineItems_FIFO.AmountRequested <> 0)
	|
	|UNION ALL
	|
	|SELECT // Receipt, WAve, by quantity.
	// ------------------------------------------------------
	// Standard attributes
	|	ItemAdjustment.Ref                    AS Recorder,
	|	ItemAdjustment.Date                   AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Dimensions
	|	LineItems_WAve.Product                AS Product,
	|	LineItems_WAve.Location               AS Location,
	|	NULL                                  AS Layer,
	// ------------------------------------------------------
	// Resources
	|	LineItems_WAve.QuantityRequested      AS Quantity,
	|	0                                     AS Amount
	// ------------------------------------------------------
	// Attributes
	// ------------------------------------------------------
	|FROM
	|	Table_InventoryJournal_LineItems AS LineItems_WAve
	|	LEFT JOIN Document.ItemAdjustment AS ItemAdjustment
	|		ON True
	|WHERE
	|	ItemAdjustment.Ref = &Ref
	|	// Receipt by quantity & Revaluation defined
	|	AND LineItems_WAve.QuantityRequested > 0
	|	// WAve
	|	AND LineItems_WAve.Type = VALUE(Enum.InventoryCosting.WeightedAverage)
	|
	|UNION ALL
	|
	|SELECT // Expense, WAve, by quantity.
	// ------------------------------------------------------
	// Standard attributes
	|	ItemAdjustment.Ref                    AS Recorder,
	|	ItemAdjustment.Date                   AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Dimensions
	|	LineItems_WAve.Product                AS Product,
	|	LineItems_WAve.Location               AS Location,
	|	NULL                                  AS Layer,
	// ------------------------------------------------------
	// Resources
	|	-LineItems_WAve.QuantityRequested     AS Quantity,
	|	0                                     AS Amount
	// ------------------------------------------------------
	// Attributes
	// ------------------------------------------------------
	|FROM
	|	Table_InventoryJournal_LineItems AS LineItems_WAve
	|	LEFT JOIN Document.ItemAdjustment AS ItemAdjustment
	|		ON True
	|WHERE
	|	ItemAdjustment.Ref = &Ref
	|	// Expense by quantity & Revaluation defined
	|	AND LineItems_WAve.QuantityRequested < 0
	|	// WAve
	|	AND LineItems_WAve.Type = VALUE(Enum.InventoryCosting.WeightedAverage)
	|
	|UNION ALL
	|
	|SELECT // Receipt, WAve, by amount.
	// ------------------------------------------------------
	// Standard attributes
	|	ItemAdjustment.Ref                    AS Recorder,
	|	ItemAdjustment.Date                   AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Dimensions
	|	LineItems_WAve.Product                AS Product,
	|	VALUE(Catalog.Locations.EmptyRef)     AS Location,
	|	NULL                                  AS Layer,
	// ------------------------------------------------------
	// Resources
	|	0                                     AS Quantity,
	|	LineItems_WAve.AmountRequested        AS Amount
	// ------------------------------------------------------
	// Attributes
	// ------------------------------------------------------
	|FROM
	|	Table_InventoryJournal_LineItems AS LineItems_WAve
	|	LEFT JOIN Document.ItemAdjustment AS ItemAdjustment
	|		ON True
	|WHERE
	|	ItemAdjustment.Ref = &Ref
	|	// Receipt by amount, Revaluation defined
	|	AND LineItems_WAve.AmountRequested > 0
	|	// WAve
	|	AND LineItems_WAve.Type = VALUE(Enum.InventoryCosting.WeightedAverage)
	|
	|UNION ALL
	|
	|SELECT // Expense, WAve, by amount with possible negative balances.
	// ------------------------------------------------------
	// Standard attributes
	|	ItemAdjustment.Ref                    AS Recorder,
	|	ItemAdjustment.Date                   AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Dimensions
	|	LineItems_WAve.Product                AS Product,
	|	VALUE(Catalog.Locations.EmptyRef)     AS Location,
	|	NULL                                  AS Layer,
	// ------------------------------------------------------
	// Resources
	|	0                                     AS Quantity,
	|	-LineItems_WAve.AmountRequested       AS Amount
	// ------------------------------------------------------
	// Attributes
	// ------------------------------------------------------
	|FROM
	|	Table_InventoryJournal_LineItems AS LineItems_WAve
	|	LEFT JOIN Document.ItemAdjustment AS ItemAdjustment
	|		ON True
	|WHERE
	|	ItemAdjustment.Ref = &Ref
	|	// Expense by amount, Revaluation defined
	|	AND LineItems_WAve.AmountRequested < 0
	|	// WAve
	|	AND LineItems_WAve.Type = VALUE(Enum.InventoryCosting.WeightedAverage)";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for dimensions lock data.
Function Query_InventoryJournal_Lock(TablesList)
	
	// Add InventoryJournal - Lock table to locks structure.
	TablesList.Insert("AccumulationRegister_InventoryJournal", TablesList.Count());
	
	// Collect dimensions for inventory journal locking.
	QueryText =
	"SELECT DISTINCT // FIFO & WAve by quantity
	// ------------------------------------------------------
	// Dimensions
	|	LineItems.Product                     AS Product,
	|	LineItems.Location                    AS Location
	// ------------------------------------------------------
	|FROM
	|	Table_LineItems AS LineItems
	|WHERE
	|	LineItems.Product.Type = VALUE(Enum.InventoryTypes.Inventory)
	|
	|UNION ALL
	|
	|SELECT DISTINCT // WAve by amount
	// ------------------------------------------------------
	// Dimensions
	|	LineItems.Product                     AS Product,
	|	VALUE(Catalog.Locations.EmptyRef)     AS Location
	// ------------------------------------------------------
	|FROM
	|	Table_LineItems AS LineItems
	|WHERE
	|	    LineItems.Product.Type          = VALUE(Enum.InventoryTypes.Inventory)
	|	AND LineItems.Product.CostingMethod = VALUE(Enum.InventoryCosting.WeightedAverage)";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for balances data.
Function Query_InventoryJournal_Balance(TablesList)
	
	// Add InventoryJournal - Balances table to balances structure.
	TablesList.Insert("Table_InventoryJournal_Balance", TablesList.Count());
	
	// Collect inventory journal balances.
	QueryText =
	"SELECT // FIFO
	// ------------------------------------------------------
	// Dimensions
	|	InventoryJournalBalance.Product.CostingMethod
	|	                                         AS Type,
	|	InventoryJournalBalance.Product          AS Product,
	|	InventoryJournalBalance.Location         AS Location,
	|	InventoryJournalBalance.Layer            AS Layer,
	// ------------------------------------------------------
	// Resources
	|	InventoryJournalBalance.QuantityBalance  AS Quantity,
	|	InventoryJournalBalance.AmountBalance    AS Amount
	// ------------------------------------------------------
	|FROM
	|	AccumulationRegister.InventoryJournal.Balance(&PointInTime,
	|		(Product, Location) IN
	|		(SELECT DISTINCT Product, Location FROM Table_InventoryJournal_Lock WHERE Product.CostingMethod = VALUE(Enum.InventoryCosting.FIFO)))
	|		                                     AS InventoryJournalBalance
	|
	|UNION ALL
	|
	|SELECT // WAve by quantity and amount
	// ------------------------------------------------------
	// Dimensions
	|	InventoryJournalBalance.Product.CostingMethod
	|	                                         AS Type,
	|	InventoryJournalBalance.Product          AS Product,
	|	InventoryJournalBalance.Location         AS Location,
	|	NULL                                     AS Layer,
	// ------------------------------------------------------
	// Resources
	|	InventoryJournalBalance.QuantityBalance  AS Quantity,
	|	InventoryJournalBalance.AmountBalance    AS Amount
	// ------------------------------------------------------
	|FROM
	|	AccumulationRegister.InventoryJournal.Balance(&PointInTime,
	|		(Product) IN
	|		(SELECT DISTINCT Product FROM Table_InventoryJournal_Lock WHERE Product.CostingMethod = VALUE(Enum.InventoryCosting.WeightedAverage)))
	|		                                     AS InventoryJournalBalance";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_GeneralJournal(TablesList)
	
	// Add GeneralJournal table to document structure.
	TablesList.Insert("Table_GeneralJournal", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // Receipt by amount, Dr
	// ------------------------------------------------------
	// Standard attributes
	|	ItemAdjustment.Ref                    AS Recorder,
	|	ItemAdjustment.Date                   AS Period,
	|	1                                     AS LineNumber,
	|	VALUE(AccountingRecordType.Debit)     AS RecordType,
	|	True                                  AS Active,
	|	ItemAdjustment.Product.InventoryOrExpenseAccount AS Account,
	|	NULL                                  AS ExtDimensionTypeDr1,
	|	NULL                                  AS ExtDimensionTypeDr2,
	|	NULL                                  AS ExtDimensionDr1,
	|	NULL                                  AS ExtDimensionDr2,
	// ------------------------------------------------------
	// Dimensions
	|	VALUE(Catalog.Currencies.EmptyRef)    AS Currency,
	// ------------------------------------------------------
	// Resources
	|	0                                     AS Amount,
	|	ItemAdjustment.Amount                 AS AmountRC,
	// ------------------------------------------------------
	// Attributes
	|	""""                                  AS Memo
	// ------------------------------------------------------
	|FROM
	|	Document.ItemAdjustment AS ItemAdjustment
	|WHERE
	|	ItemAdjustment.Ref = &Ref
	|	// Receipt by amount, Revaluation defined
	|	AND ItemAdjustment.Amount > 0
	|	// Inventory item
	|	AND ItemAdjustment.Product.Type = VALUE(Enum.InventoryTypes.Inventory)
	|
	|UNION ALL
	|
	|SELECT // Receipt by amount, Cr
	// ------------------------------------------------------
	// Standard attributes
	|	ItemAdjustment.Ref                    AS Recorder,
	|	ItemAdjustment.Date                   AS Period,
	|	1                                     AS LineNumber,
	|	VALUE(AccountingRecordType.Credit)    AS RecordType,
	|	True                                  AS Active,
	|	ItemAdjustment.IncomeExpenseAccount   AS Account,
	|	NULL                                  AS ExtDimensionTypeCr1,
	|	NULL                                  AS ExtDimensionTypeCr2,
	|	NULL                                  AS ExtDimensionCr1,
	|	NULL                                  AS ExtDimensionCr2,
	// ------------------------------------------------------
	// Dimensions
	|	VALUE(Catalog.Currencies.EmptyRef)    AS Currency,
	// ------------------------------------------------------
	// Resources
	|	0                                     AS Amount,
	|	ItemAdjustment.Amount                 AS AmountRC,
	// ------------------------------------------------------
	// Attributes
	|	""""                                  AS Memo
	// ------------------------------------------------------
	|FROM
	|	Document.ItemAdjustment AS ItemAdjustment
	|WHERE
	|	ItemAdjustment.Ref = &Ref
	|	// Receipt by amount, Revaluation defined
	|	AND ItemAdjustment.Amount > 0
	|	// Inventory item
	|	AND ItemAdjustment.Product.Type = VALUE(Enum.InventoryTypes.Inventory)
	|
	|UNION ALL
	|
	|SELECT // Expense by amount, Dr
	// ------------------------------------------------------
	// Standard attributes
	|	ItemAdjustment.Ref                    AS Recorder,
	|	ItemAdjustment.Date                   AS Period,
	|	1                                     AS LineNumber,
	|	VALUE(AccountingRecordType.Debit)     AS RecordType,
	|	True                                  AS Active,
	|	ItemAdjustment.IncomeExpenseAccount   AS Account,
	|	NULL                                  AS ExtDimensionTypeDr1,
	|	NULL                                  AS ExtDimensionTypeDr2,
	|	NULL                                  AS ExtDimensionDr1,
	|	NULL                                  AS ExtDimensionDr2,
	// ------------------------------------------------------
	// Dimensions
	|	VALUE(Catalog.Currencies.EmptyRef)    AS Currency,
	// ------------------------------------------------------
	// Resources
	|	0                                     AS Amount,
	|	-ItemAdjustment.Amount                AS AmountRC,
	// ------------------------------------------------------
	// Attributes
	|	""""                                  AS Memo
	// ------------------------------------------------------
	|FROM
	|	Document.ItemAdjustment AS ItemAdjustment
	|WHERE
	|	ItemAdjustment.Ref = &Ref
	|	// Expense by amount, Revaluation defined
	|	AND ItemAdjustment.Amount < 0
	|	// Inventory item
	|	AND ItemAdjustment.Product.Type = VALUE(Enum.InventoryTypes.Inventory)
	|
	|UNION ALL
	|
	|SELECT // Expense by amount, Cr
	// ------------------------------------------------------
	// Standard attributes
	|	ItemAdjustment.Ref                    AS Recorder,
	|	ItemAdjustment.Date                   AS Period,
	|	1                                     AS LineNumber,
	|	VALUE(AccountingRecordType.Credit)    AS RecordType,
	|	True                                  AS Active,
	|	ItemAdjustment.Product.InventoryOrExpenseAccount AS Account,
	|	NULL                                  AS ExtDimensionTypeCr1,
	|	NULL                                  AS ExtDimensionTypeCr2,
	|	NULL                                  AS ExtDimensionCr1,
	|	NULL                                  AS ExtDimensionCr2,
	// ------------------------------------------------------
	// Dimensions
	|	VALUE(Catalog.Currencies.EmptyRef)    AS Currency,
	// ------------------------------------------------------
	// Resources
	|	0                                     AS Amount,
	|	-ItemAdjustment.Amount                AS AmountRC,
	// ------------------------------------------------------
	// Attributes
	|	""""                                  AS Memo
	// ------------------------------------------------------
	|FROM
	|	Document.ItemAdjustment AS ItemAdjustment
	|WHERE
	|	ItemAdjustment.Ref = &Ref
	|	// Expense by amount, Revaluation defined
	|	AND ItemAdjustment.Amount < 0
	|	// Inventory item
	|	AND ItemAdjustment.Product.Type = VALUE(Enum.InventoryTypes.Inventory)";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

//--//GJ++
	
// Query for document data.
Function Query_GeneralJournalAnalyticsDimensions_Transactions(TablesList)
	
	// Add GeneralJournalAnalyticsDimensions_Transactions table to document structure.
	TablesList.Insert("Table_GeneralJournalAnalyticsDimensions_Transactions", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // Receipt by amount, Receipt
	// ------------------------------------------------------
	// Standard attributes
	|	ItemAdjustment.Ref                    AS Recorder,
	|	ItemAdjustment.Date                   AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Accounting attributes
	|	ItemAdjustment.Product.InventoryOrExpenseAccount
	|                                         AS Account,
	// ------------------------------------------------------
	// Dimensions
	|	NULL                                  AS Company,
	|	NULL                                  AS Class,
	|	NULL                                  AS Project,
	// ------------------------------------------------------
	// Resources
	|	ItemAdjustment.Amount                 AS AmountRC
	// ------------------------------------------------------
	|INTO Table_GeneralJournalAnalyticsDimensions_Transactions
	|FROM
	|	Document.ItemAdjustment AS ItemAdjustment
	|WHERE
	|	ItemAdjustment.Ref = &Ref
	|	// Receipt by amount, Revaluation defined
	|	AND ItemAdjustment.Amount > 0
	|	// Inventory item
	|	AND ItemAdjustment.Product.Type = VALUE(Enum.InventoryTypes.Inventory)
	|
	|UNION ALL
	|
	|SELECT // Receipt by amount, Expense
	// ------------------------------------------------------
	// Standard attributes
	|	ItemAdjustment.Ref                    AS Recorder,
	|	ItemAdjustment.Date                   AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Accounting attributes
	|	ItemAdjustment.IncomeExpenseAccount   AS Account,
	// ------------------------------------------------------
	// Dimensions
	|	NULL                                  AS Company,
	|	NULL                                  AS Class,
	|	NULL                                  AS Project,
	// ------------------------------------------------------
	// Resources
	|	ItemAdjustment.Amount                 AS AmountRC
	// ------------------------------------------------------
	|FROM
	|	Document.ItemAdjustment AS ItemAdjustment
	|WHERE
	|	ItemAdjustment.Ref = &Ref
	|	// Receipt by amount, Revaluation defined
	|	AND ItemAdjustment.Amount > 0
	|	// Inventory item
	|	AND ItemAdjustment.Product.Type = VALUE(Enum.InventoryTypes.Inventory)
	|
	|UNION ALL
	|
	|SELECT // Expense by amount, Receipt
	// ------------------------------------------------------
	// Standard attributes
	|	ItemAdjustment.Ref                    AS Recorder,
	|	ItemAdjustment.Date                   AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Accounting attributes
	|	ItemAdjustment.IncomeExpenseAccount   AS Account,
	// ------------------------------------------------------
	// Dimensions
	|	NULL                                  AS Company,
	|	NULL                                  AS Class,
	|	NULL                                  AS Project,
	// ------------------------------------------------------
	// Resources
	|	-ItemAdjustment.Amount                AS AmountRC
	// ------------------------------------------------------	
	|FROM
	|	Document.ItemAdjustment AS ItemAdjustment
	|WHERE
	|	ItemAdjustment.Ref = &Ref
	|	// Expense by amount, Revaluation defined
	|	AND ItemAdjustment.Amount < 0
	|	// Inventory item
	|	AND ItemAdjustment.Product.Type = VALUE(Enum.InventoryTypes.Inventory)
	|
	|UNION ALL
	|
	|SELECT // Expense by amount, Expense
	// ------------------------------------------------------
	// Standard attributes
	|	ItemAdjustment.Ref                    AS Recorder,
	|	ItemAdjustment.Date                   AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Accounting attributes
	|	ItemAdjustment.Product.InventoryOrExpenseAccount
	|                                         AS Account,
	// ------------------------------------------------------
	// Dimensions
	|	NULL                                  AS Company,
	|	NULL                                  AS Class,
	|	NULL                                  AS Project,
	// ------------------------------------------------------
	// Resources
	|	-ItemAdjustment.Amount          AS AmountRC
	// ------------------------------------------------------
	|FROM
	|	Document.ItemAdjustment AS ItemAdjustment
	|WHERE
	|	ItemAdjustment.Ref = &Ref
	|	// Expense by amount, Revaluation defined
	|	AND ItemAdjustment.Amount < 0
	|	// Inventory item
	|	AND ItemAdjustment.Product.Type = VALUE(Enum.InventoryTypes.Inventory)";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_GeneralJournalAnalyticsDimensions(TablesList)
	
	// Add GeneralJournalAnalyticsDimensions table to document structure.
	TablesList.Insert("Table_GeneralJournalAnalyticsDimensions", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // Transactions
	// ------------------------------------------------------
	// Standard attributes
	|	Transaction.Recorder                  AS Recorder,
	|	Transaction.Period                    AS Period,
	|	Transaction.LineNumber                AS LineNumber,
	|	Transaction.RecordType                AS RecordType,
	|	Transaction.Active                    AS Active,
	// ------------------------------------------------------
	// Accounting attributes
	|	Transaction.Account                   AS Account,
	// ------------------------------------------------------
	// Dimensions
	|	Transaction.Company                   AS Company,
	|	Transaction.Class                     AS Class,
	|	Transaction.Project                   AS Project,
	// ------------------------------------------------------
	// Resources
	|	Transaction.AmountRC                  AS AmountRC
	// ------------------------------------------------------
	|FROM
	|	Table_GeneralJournalAnalyticsDimensions_Transactions AS Transaction";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

//--//GJ--

// Query for document data.
Function Query_CashFlowData(TablesList)
	
	// Add CashFlowData table to document structure.
	TablesList.Insert("Table_CashFlowData", TablesList.Count());
	
	// Collect cash flow data.
	QueryText =
	"SELECT // Transactions
	// ------------------------------------------------------
	// Standard attributes
	|	Transaction.Recorder                  AS Recorder,
	|	Transaction.Period                    AS Period,
	|	Transaction.LineNumber                AS LineNumber,
	|	Transaction.RecordType                AS RecordType,
	|	Transaction.Active                    AS Active,
	// ------------------------------------------------------
	// Accounting attributes
	|	Transaction.Account                   AS Account,
	// ------------------------------------------------------
	// Dimensions
	|	Transaction.Company                   AS Company,
	|	ItemAdjustment.Ref                    AS Document,
	|	Null                                  AS SalesPerson,
	|	Transaction.Class                     AS Class,
	|	Transaction.Project                   AS Project,
	// ------------------------------------------------------
	// Resources
	|	Transaction.AmountRC                  AS AmountRC,
	// ------------------------------------------------------
	// Attributes
	|	NULL                                  AS PaymentMethod
	// ------------------------------------------------------
	|FROM
	|	Table_GeneralJournalAnalyticsDimensions_Transactions AS Transaction
	|	LEFT JOIN Document.ItemAdjustment AS ItemAdjustment
	|		ON ItemAdjustment.Ref = &Ref";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction
	
// Put structure of registers, which balance should be checked during posting.
Procedure FillRegistersCheckList(AdditionalProperties, RegisterRecords)
	
	// Create structure of registers and its resources to check balances.
	BalanceCheck = New Structure;
	
	// Fill structure depending on document write mode.
	If AdditionalProperties.Posting.WriteMode = DocumentWriteMode.Posting Then
		
		// Add resources for check changes in recordset.
		CheckPostings = New Array;
		CheckPostings.Add("{Table}.Quantity{Posting}, <>, 0"); // Check decreasing and increasing quantity.
		CheckPostings.Add("{Table}.Amount{Posting},   <>, 0"); // Check decreasing and increasing amount.
		
		// Add resources for check register balances.
		CheckBalances = New Array;
		CheckBalances.Add("{Table}.Quantity{Balance}, <, 0");  // Check negative inventory quantity balance.
		CheckBalances.Add("{Table}.Amount{Balance},   <, 0");  // Check negative inventory amount balance.
		
		// Add messages for different error situations.
		CheckMessages = New Array;
		CheckMessages.Add(NStr("en = '{Product}?{Layer}:
		                             |There is an insufficient balance of {-Quantity} at the {Location}.|Layer = "" of {Layer}""'"));
		CheckMessages.Add(NStr(StrReplace("en = '{Product}?{Layer}:
		                             |There is an insufficient balance of {Currency}{-Amount}?{Location}.|Layer = "" of {Layer}"";Location = "" at the {Location}""'",
		                             "{Currency}", GeneralFunctionsReusable.DefaultCurrencySymbol())));
		
		// Add register to check it's recordset changes and balances during posting.
		BalanceCheck.Insert("InventoryJournal", New Structure("CheckPostings, CheckBalances, CheckMessages", CheckPostings, CheckBalances, CheckMessages));
		
	ElsIf AdditionalProperties.Posting.WriteMode = DocumentWriteMode.UndoPosting Then
		
		// Add resources for check changes in recordset.
		CheckPostings = New Array;
		CheckPostings.Add("{Table}.Quantity{Posting}, <, 0"); // Check decreasing quantity.
		CheckPostings.Add("{Table}.Amount{Posting},   <, 0"); // Check decreasing amount.
		
		// Add resources for check register balances.
		CheckBalances = New Array;
		CheckBalances.Add("{Table}.Quantity{Balance}, <, 0");  // Check negative inventory quantity balance.
		CheckBalances.Add("{Table}.Amount{Balance},   <, 0");  // Check negative inventory amount balance.
		
		// Add messages for different error situations.
		CheckMessages = New Array;
		CheckMessages.Add(NStr("en = '{Product}?{Layer}:
		                             |There is an insufficient balance of {-Quantity} at the {Location}.|Layer = "" of {Layer}""'"));
		CheckMessages.Add(NStr(StrReplace("en = '{Product}?{Layer}:
		                             |There is an insufficient balance of {Currency}{-Amount}?{Location}.|Layer = "" of {Layer}"";Location = "" at the {Location}""'",
		                             "{Currency}", GeneralFunctionsReusable.DefaultCurrencySymbol())));
		
		// Add register to check it's recordset changes and balances during posting.
		BalanceCheck.Insert("InventoryJournal", New Structure("CheckPostings, CheckBalances, CheckMessages", CheckPostings, CheckBalances, CheckMessages));
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

