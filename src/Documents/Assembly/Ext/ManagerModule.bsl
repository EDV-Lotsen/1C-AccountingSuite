
////////////////////////////////////////////////////////////////////////////////
// Assembly: Manager module
//------------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
#Region EVENTS_HANDLERS

//------------------------------------------------------------------------------
// Document presentation

#EndRegion

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
	Query.Text = Query_InventoryJournal_Lock(LocksList);
	
	// 2.2. Proceed with locking the data.
	If Not IsBlankString(Query.Text) Then
		QueryResult = Query.ExecuteBatch();
		For Each LockTable In LocksList Do
			DocumentPosting.LockDataSourceBeforeWrite(StrReplace(LockTable.Key, "_", "."), QueryResult[LockTable.Value], DataLockMode.Exclusive);
		EndDo;
	EndIf;
	
	
	// 3.1. Query for register balances excluding document data (if it already affected to).
	Query.Text = Query_InventoryJournal_Balance(BalancesList);
	
	// 3.1.a. Reuse locked inventory items list.
	DocumentPosting.PutTemporaryTable(QueryResult[LocksList.AccumulationRegister_InventoryJournal].Unload(),
	                                  "Table_InventoryJournal_Lock", Query.TempTablesManager);
	
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
	
	// Set optional accounting flags.
	// Reserved for future use.
	
	// Create list of posting tables (according to the list of registers).
	TablesList = New Structure;
	
	// Create a query to request document data.
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	
	//------------------------------------------------------------------------------
	// 2. Prepare query text.
	
	// Query for document's tables.
	Query.Text = Query_InventoryJournal_LineItems(TablesList) +
				 Query_InventoryJournal_Services(TablesList) +
				 Query_InventoryJournal_Wastes(TablesList) +
				 Query_InventoryJournal_Residuals(TablesList) +
				 Query_InventoryJournal_Assembly(TablesList) +
				 Query_InventoryJournal_Balance_Quantity(TablesList) +
				 Query_InventoryJournal_Balance_FIFO(TablesList) +
				 Query_InventoryJournal_MaterialCost(TablesList) +
				 Query_InventoryJournal_MaterialCost_Total(TablesList) +
				 Query_InventoryJournal_WasteCost(TablesList) +
				 Query_InventoryJournal_WasteCost_Total(TablesList) +
				 Query_InventoryJournal_Totals(TablesList) +
				 Query_InventoryJournal_ResidualCost(TablesList) +
				 Query_InventoryJournal_ResidualCost_Total(TablesList) +
				 Query_InventoryJournal_Totals2(TablesList) +
				 Query_InventoryJournal_DocumentTotal(TablesList) +
				 Query_InventoryJournal_AssemblyCost_Total(TablesList) +
				 Query_InventoryJournal(TablesList) +
				 Query_ItemLastCosts_AssemblyResidualsServices(TablesList) +
				 Query_ItemLastCosts_AssemblyResidualsServices_Total(TablesList) +
				 Query_ItemLastCosts(TablesList) +
				 Query_GeneralJournal_Materials(TablesList) +
				 Query_GeneralJournal_Services(TablesList) +
				 Query_GeneralJournal_Wastes(TablesList) +
				 Query_GeneralJournal_Residuals(TablesList) +
				 Query_GeneralJournal_Accounts_Materials_InvOrExp_Quantity(TablesList) +
				 Query_GeneralJournal_Accounts_Materials_InvOrExp_Amount(TablesList) +
				 Query_GeneralJournal_Accounts_Materials_InvOrExp(TablesList) +
				 Query_GeneralJournal_Accounts_Residuals_InvOrExp_Quantity(TablesList) +
				 Query_GeneralJournal_Accounts_Residuals_InvOrExp_Amount(TablesList) +
				 Query_GeneralJournal_Accounts_Residuals_InvOrExp(TablesList) +
				 Query_GeneralJournal_Accounts_Services_InvOrExp(TablesList) +
				 Query_GeneralJournal(TablesList) +
				 //--//GJ++
				 Query_GeneralJournalAnalyticsDimensions_Accounts_Materials_InvOrExp_Quantity(TablesList) +
				 Query_GeneralJournalAnalyticsDimensions_Accounts_Materials_InvOrExp_Amount(TablesList) +
				 Query_GeneralJournalAnalyticsDimensions_Accounts_Materials_InvOrExp(TablesList) +
				 Query_GeneralJournalAnalyticsDimensions_Accounts_Materials_InvOrExp_Difference_Amount(TablesList) +
				 Query_GeneralJournalAnalyticsDimensions_Accounts_Materials_InvOrExp_Difference(TablesList) +
				 Query_GeneralJournalAnalyticsDimensions_Accounts_Services_InvOrExp(TablesList) +
				 Query_GeneralJournalAnalyticsDimensions_Accounts_Services_InvOrExp_Difference_Amount(TablesList) +
				 Query_GeneralJournalAnalyticsDimensions_Accounts_Services_InvOrExp_Difference(TablesList) +
	             Query_GeneralJournalAnalyticsDimensions_Transactions(TablesList)+
				 Query_GeneralJournalAnalyticsDimensions(TablesList)+
				 //--//GJ--
				 Query_CashFlowData(TablesList) +
				 
				 Query_ProjectData_Accounts_Wastes_Quantity(TablesList) +
				 Query_ProjectData_Accounts_Wastes_Amount(TablesList) +
				 Query_ProjectData_Accounts_Wastes(TablesList) +
				 Query_ProjectData_Accounts_Services(TablesList) +
				 Query_ProjectData(TablesList) +
				 Query_ClassData_Accounts_Wastes_Quantity(TablesList) +
				 Query_ClassData_Accounts_Wastes_Amount(TablesList) +
				 Query_ClassData_Accounts_Wastes(TablesList) +
				 Query_ClassData_Accounts_Services(TablesList) +
				 Query_ClassData(TablesList);

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

Procedure Print(Spreadsheet, SheetTitle, Ref, TemplateName = Undefined) Export
	
	PrintFormFunctions.PrintAssembly(Spreadsheet, SheetTitle, Ref, TemplateName); 
	
EndProcedure

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
	
	// Add InventoryJournal - requested items table to document structure.
	TablesList.Insert("Table_InventoryJournal_LineItems", TablesList.Count());
	
	// Collect inventory data.
	QueryText =
	"SELECT // FIFO
	// ------------------------------------------------------
	// Dimensions
	|	LineItems.Product.CostingMethod          AS Type,
	|	LineItems.Product                        AS Product,
	|	LineItems.Location                       AS Location,
	// ------------------------------------------------------
	// Agregates
	|	SUM(LineItems.QtyUM)                     AS QuantityRequested
	// ------------------------------------------------------
	|INTO
	|	Table_InventoryJournal_LineItems
	|FROM
	|	Document.Assembly.LineItems AS LineItems
	|WHERE
	|	    LineItems.Ref                   = &Ref
	|	AND LineItems.Product.Type          = VALUE(Enum.InventoryTypes.Inventory)
	|	AND LineItems.Product.CostingMethod = VALUE(Enum.InventoryCosting.FIFO)
	|GROUP BY
	|	LineItems.Product.CostingMethod,
	|	LineItems.Product,
	|	LineItems.Location
	|
	|UNION ALL
	|
	|SELECT // WAve for quantity calcualtion
	// ------------------------------------------------------
	// Dimensions
	|	LineItems.Product.CostingMethod          AS Type,
	|	LineItems.Product                        AS Product,
	|	LineItems.Location                       AS Location,
	// ------------------------------------------------------
	// Agregates
	|	SUM(LineItems.QtyUM)                     AS QuantityRequested
	// ------------------------------------------------------
	|FROM
	|	Document.Assembly.LineItems AS LineItems
	|WHERE
	|	    LineItems.Ref                   = &Ref
	|	AND LineItems.Product.Type          = VALUE(Enum.InventoryTypes.Inventory)
	|	AND LineItems.Product.CostingMethod = VALUE(Enum.InventoryCosting.WeightedAverage)
	|GROUP BY
	|	LineItems.Product.CostingMethod,
	|	LineItems.Product,
	|	LineItems.Location
	|
	|UNION ALL
	|
	|SELECT // WAve for amount calcualtion
	// ------------------------------------------------------
	// Dimensions
	|	LineItems.Product.CostingMethod          AS Type,
	|	LineItems.Product                        AS Product,
	|	VALUE(Catalog.Locations.EmptyRef)        AS Location,
	// ------------------------------------------------------
	// Agregates
	|	SUM(LineItems.QtyUM)                     AS QuantityRequested
	// ------------------------------------------------------
	|FROM
	|	Document.Assembly.LineItems AS LineItems
	|WHERE
	|	    LineItems.Ref                   = &Ref
	|	AND LineItems.Product.Type          = VALUE(Enum.InventoryTypes.Inventory)
	|	AND LineItems.Product.CostingMethod = VALUE(Enum.InventoryCosting.WeightedAverage)
	|GROUP BY
	|	LineItems.Product.CostingMethod,
	|	LineItems.Product";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_InventoryJournal_Services(TablesList)
	
	// Add InventoryJournal - requested services table to document structure.
	TablesList.Insert("Table_InventoryJournal_Services", TablesList.Count());
	
	// Collect inventory data.
	QueryText =
	"SELECT
	// ------------------------------------------------------
	// Dimensions
	|	Services.Product                         AS Product,
	// ------------------------------------------------------
	// Agregates
	|	SUM(Services.QtyUM)                      AS Quantity,
	|	SUM(Services.LineTotal)                  AS Amount
	// ------------------------------------------------------
	|INTO
	|	Table_InventoryJournal_Services
	|FROM
	|	Document.Assembly.Services AS Services
	|WHERE
	|	    Services.Ref          = &Ref
	|	AND Services.Product.Type = VALUE(Enum.InventoryTypes.NonInventory)
	|GROUP BY
	|	Services.Product";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_InventoryJournal_Wastes(TablesList)
	
	// Add InventoryJournal - requested wastes table to document structure.
	TablesList.Insert("Table_InventoryJournal_Wastes", TablesList.Count());
	
	// Collect inventory data.
	QueryText =
	"SELECT // FIFO
	// ------------------------------------------------------
	// Dimensions
	|	LineItems.Product.CostingMethod          AS Type,
	|	LineItems.Product                        AS Product,
	|	LineItems.Location                       AS Location,
	// ------------------------------------------------------
	// Agregates
	|	SUM(LineItems.WasteQtyUM)                AS QuantityRequested
	// ------------------------------------------------------
	|INTO
	|	Table_InventoryJournal_Wastes
	|FROM
	|	Document.Assembly.LineItems AS LineItems
	|WHERE
	|	    LineItems.Ref                   = &Ref
	|	AND LineItems.Product.Type          = VALUE(Enum.InventoryTypes.Inventory)
	|	AND LineItems.Product.CostingMethod = VALUE(Enum.InventoryCosting.FIFO)
	|GROUP BY
	|	LineItems.Product.CostingMethod,
	|	LineItems.Product,
	|	LineItems.Location
	|
	|UNION ALL
	|
	|SELECT // WAve for quantity calcualtion
	// ------------------------------------------------------
	// Dimensions
	|	LineItems.Product.CostingMethod          AS Type,
	|	LineItems.Product                        AS Product,
	|	LineItems.Location                       AS Location,
	// ------------------------------------------------------
	// Agregates
	|	SUM(LineItems.WasteQtyUM)                AS QuantityRequested
	// ------------------------------------------------------
	|FROM
	|	Document.Assembly.LineItems AS LineItems
	|WHERE
	|	    LineItems.Ref                   = &Ref
	|	AND LineItems.Product.Type          = VALUE(Enum.InventoryTypes.Inventory)
	|	AND LineItems.Product.CostingMethod = VALUE(Enum.InventoryCosting.WeightedAverage)
	|GROUP BY
	|	LineItems.Product.CostingMethod,
	|	LineItems.Product,
	|	LineItems.Location
	|
	|UNION ALL
	|
	|SELECT // WAve for amount calcualtion
	// ------------------------------------------------------
	// Dimensions
	|	LineItems.Product.CostingMethod          AS Type,
	|	LineItems.Product                        AS Product,
	|	VALUE(Catalog.Locations.EmptyRef)        AS Location,
	// ------------------------------------------------------
	// Agregates
	|	SUM(LineItems.WasteQtyUM)                AS QuantityRequested
	// ------------------------------------------------------
	|FROM
	|	Document.Assembly.LineItems AS LineItems
	|WHERE
	|	    LineItems.Ref                   = &Ref
	|	AND LineItems.Product.Type          = VALUE(Enum.InventoryTypes.Inventory)
	|	AND LineItems.Product.CostingMethod = VALUE(Enum.InventoryCosting.WeightedAverage)
	|GROUP BY
	|	LineItems.Product.CostingMethod,
	|	LineItems.Product";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_InventoryJournal_Residuals(TablesList)
	
	// Add InventoryJournal - residuals table to document structure.
	TablesList.Insert("Table_InventoryJournal_Residuals", TablesList.Count());
	
	// Collect inventory data.
	QueryText =
	"SELECT // FIFO
	// ------------------------------------------------------
	// Dimensions
	|	Residuals.Product.CostingMethod          AS Type,
	|	Residuals.Product                        AS Product,
	|	Residuals.Location                       AS Location,
	|	Residuals.Percent                        AS Percent,
	// ------------------------------------------------------
	// Agregates
	|	SUM(Residuals.QtyUM)                     AS QuantityRequested
	// ------------------------------------------------------
	|INTO
	|	Table_InventoryJournal_Residuals
	|FROM
	|	Document.Assembly.Residuals AS Residuals
	|WHERE
	|	    Residuals.Ref                   = &Ref
	|	AND Residuals.Product.Type          = VALUE(Enum.InventoryTypes.Inventory)
	|	AND Residuals.Product.CostingMethod = VALUE(Enum.InventoryCosting.FIFO)
	|GROUP BY
	|	Residuals.Product.CostingMethod,
	|	Residuals.Product,
	|	Residuals.Location,
	|	Residuals.Percent
	|
	|UNION ALL
	|
	|SELECT // WAve for quantity calcualtion
	// ------------------------------------------------------
	// Dimensions
	|	Residuals.Product.CostingMethod          AS Type,
	|	Residuals.Product                        AS Product,
	|	Residuals.Location                       AS Location,
	|	Residuals.Percent                        AS Percent,
	// ------------------------------------------------------
	// Agregates
	|	SUM(Residuals.QtyUM)                     AS QuantityRequested
	// ------------------------------------------------------
	|FROM
	|	Document.Assembly.Residuals AS Residuals
	|WHERE
	|	    Residuals.Ref                   = &Ref
	|	AND Residuals.Product.Type          = VALUE(Enum.InventoryTypes.Inventory)
	|	AND Residuals.Product.CostingMethod = VALUE(Enum.InventoryCosting.WeightedAverage)
	|GROUP BY
	|	Residuals.Product.CostingMethod,
	|	Residuals.Product,
	|	Residuals.Location,
	|	Residuals.Percent
	|
	|UNION ALL
	|
	|SELECT // WAve for amount calcualtion
	// ------------------------------------------------------
	// Dimensions
	|	Residuals.Product.CostingMethod          AS Type,
	|	Residuals.Product                        AS Product,
	|	VALUE(Catalog.Locations.EmptyRef)        AS Location,
	|	Residuals.Percent                        AS Percent,
	// ------------------------------------------------------
	// Agregates
	|	SUM(Residuals.QtyUM)                     AS QuantityRequested
	// ------------------------------------------------------
	|FROM
	|	Document.Assembly.Residuals AS Residuals
	|WHERE
	|	    Residuals.Ref                   = &Ref
	|	AND Residuals.Product.Type          = VALUE(Enum.InventoryTypes.Inventory)
	|	AND Residuals.Product.CostingMethod = VALUE(Enum.InventoryCosting.WeightedAverage)
	|GROUP BY
	|	Residuals.Product.CostingMethod,
	|	Residuals.Product,
	|	Residuals.Percent";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_InventoryJournal_Assembly(TablesList)
	
	// Add InventoryJournal - assembly table to document structure.
	TablesList.Insert("Table_InventoryJournal_Assembly", TablesList.Count());
	
	// Collect inventory data.
	QueryText =
	"SELECT // FIFO
	// ------------------------------------------------------
	// Dimensions
	|	Assembly.Product.CostingMethod           AS Type,
	|	Assembly.Product                         AS Product,
	|	Assembly.Location                        AS Location,
	// ------------------------------------------------------
	// Agregates
	|	SUM(Assembly.QtyUM)                      AS QuantityRequested
	// ------------------------------------------------------
	|INTO
	|	Table_InventoryJournal_Assembly
	|FROM
	|	Document.Assembly AS Assembly
	|WHERE
	|	    Assembly.Ref                   = &Ref
	|	AND Assembly.Product.Type          = VALUE(Enum.InventoryTypes.Inventory)
	|	AND Assembly.Product.CostingMethod = VALUE(Enum.InventoryCosting.FIFO)
	|GROUP BY
	|	Assembly.Product.CostingMethod,
	|	Assembly.Product,
	|	Assembly.Location
	|
	|UNION ALL
	|
	|SELECT // WAve for quantity calcualtion
	// ------------------------------------------------------
	// Dimensions
	|	Assembly.Product.CostingMethod           AS Type,
	|	Assembly.Product                         AS Product,
	|	Assembly.Location                        AS Location,
	// ------------------------------------------------------
	// Agregates
	|	SUM(Assembly.QtyUM)                      AS QuantityRequested
	// ------------------------------------------------------
	|FROM
	|	Document.Assembly AS Assembly
	|WHERE
	|	    Assembly.Ref                   = &Ref
	|	AND Assembly.Product.Type          = VALUE(Enum.InventoryTypes.Inventory)
	|	AND Assembly.Product.CostingMethod = VALUE(Enum.InventoryCosting.WeightedAverage)
	|GROUP BY
	|	Assembly.Product.CostingMethod,
	|	Assembly.Product,
	|	Assembly.Location
	|
	|UNION ALL
	|
	|SELECT // WAve for amount calcualtion
	// ------------------------------------------------------
	// Dimensions
	|	Assembly.Product.CostingMethod           AS Type,
	|	Assembly.Product                         AS Product,
	|	VALUE(Catalog.Locations.EmptyRef)        AS Location,
	// ------------------------------------------------------
	// Agregates
	|	SUM(Assembly.QtyUM)                      AS QuantityRequested
	// ------------------------------------------------------
	|FROM
	|	Document.Assembly AS Assembly
	|WHERE
	|	    Assembly.Ref                   = &Ref
	|	AND Assembly.Product.Type          = VALUE(Enum.InventoryTypes.Inventory)
	|	AND Assembly.Product.CostingMethod = VALUE(Enum.InventoryCosting.WeightedAverage)
	|GROUP BY
	|	Assembly.Product.CostingMethod,
	|	Assembly.Product";
	
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
	|	SUM(InventoryJournalCumulative.Quantity) AS QuantityCumulative
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
Function Query_InventoryJournal_MaterialCost(TablesList)
	
	// Add InventoryJournal - material cost table to document structure.
	TablesList.Insert("Table_InventoryJournal_MaterialCost", TablesList.Count());
	
	// Collect inventory data.
	QueryText =
	"SELECT // FIFO
	// ------------------------------------------------------
	// Dimensions
	|	Balance_FIFO.Product                  AS Product,
	|	Balance_FIFO.Location                 AS Location,
	// ------------------------------------------------------
	// Resources
	|	CASE
	|		WHEN Balance_FIFO.QuantityCumulative <= LineItems_FIFO.QuantityRequested
	|		// The layer written off completely.
	|		THEN Balance_FIFO.Quantity
	|		// The layer written partially or left off.
	|		ELSE CASE
	|			WHEN Balance_FIFO.Quantity + LineItems_FIFO.QuantityRequested - Balance_FIFO.QuantityCumulative > 0
	|			// The layer written off partially.
	|			THEN Balance_FIFO.Quantity + LineItems_FIFO.QuantityRequested - Balance_FIFO.QuantityCumulative
	|			// The layer is not requested and left off.
	|			ELSE 0
	|		END
	|	END                                   AS Quantity,
	|	CASE
	|		WHEN Balance_FIFO.QuantityCumulative <= LineItems_FIFO.QuantityRequested
	|		// The layer written off completely.
	|		THEN Balance_FIFO.Amount
	|		// The layer written partially or left off.
	|		ELSE CASE
	|			WHEN Balance_FIFO.Quantity + LineItems_FIFO.QuantityRequested - Balance_FIFO.QuantityCumulative > 0
	|			// The layer written off partially.
	|			THEN CAST ( // Format(Amount * QuantityExpense / Quantity, ""ND=17; NFD=2"")
	|				 Balance_FIFO.Amount * 
	|				(Balance_FIFO.Quantity + LineItems_FIFO.QuantityRequested - Balance_FIFO.QuantityCumulative) /
	|				 Balance_FIFO.Quantity
	|				 AS NUMBER (17, 2))
	|			// The layer is not requested and left off.
	|			ELSE 0
	|		END
	|	END                                   AS Amount
	// ------------------------------------------------------
	|INTO
	|	Table_InventoryJournal_MaterialCost
	// ------------------------------------------------------
	|FROM
	|	Table_InventoryJournal_Balance_FIFO AS Balance_FIFO
	|	LEFT JOIN Table_InventoryJournal_LineItems AS LineItems_FIFO
	|		ON  Balance_FIFO.Product  = LineItems_FIFO.Product
	|		AND Balance_FIFO.Location = LineItems_FIFO.Location
	|WHERE
	|	LineItems_FIFO.Type = VALUE(Enum.InventoryCosting.FIFO)
	|
	|UNION ALL
	|
	|SELECT // WeightedAverage
	// ------------------------------------------------------
	// Dimensions
	|	LineItems_WAve.Product                AS Product,
	|	VALUE(Catalog.Locations.EmptyRef)     AS Location,
	// ------------------------------------------------------
	// Resources
	|	CASE
	|		WHEN ISNULL(Balance_WAve.Quantity, 0) < LineItems_WAve.QuantityRequested
	|		// The product written off completely (negative balances).
	|		THEN ISNULL(Balance_WAve.Quantity, 0)
	|		// The product written off completely, or partially, or left off.
	|		ELSE LineItems_WAve.QuantityRequested
	|	END                                   AS Quantity,
	|	CASE
	|		WHEN ISNULL(Balance_WAve.Quantity, 0) <= LineItems_WAve.QuantityRequested
	|		// The product written off completely.
	|		THEN ISNULL(Balance_WAve.Amount, 0)
	|		// The product written off partially.
	|		ELSE CAST ( // Format(Amount / QuantityExpense / Quantity, ""ND=17; NFD=2"")
	|			 Balance_WAve.Amount * LineItems_WAve.QuantityRequested / Balance_WAve.Quantity
	|			 AS NUMBER (17, 2))
	|	END                                   AS Amount
	// ------------------------------------------------------
	|FROM
	|	Table_InventoryJournal_LineItems AS LineItems_WAve
	|	LEFT JOIN Table_InventoryJournal_Balance_Quantity AS Balance_WAve
	|		ON  Balance_WAve.Product  = LineItems_WAve.Product
	|		AND Balance_WAve.Location = VALUE(Catalog.Locations.EmptyRef)
	|WHERE
	|	 LineItems_WAve.Type = VALUE(Enum.InventoryCosting.WeightedAverage)
	|AND LineItems_WAve.Location = VALUE(Catalog.Locations.EmptyRef)";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_InventoryJournal_MaterialCost_Total(TablesList)
	
	// Add InventoryJournal inventory - material cost total table to document structure.
	TablesList.Insert("Table_InventoryJournal_MaterialCost_Total", TablesList.Count());
	
	// Collect inventory data.
	QueryText =
	"SELECT
	// ------------------------------------------------------
	// Dimensions
	|	ProductCost.Product                  AS Product,
	|	ProductCost.Location                 AS Location,
	// ------------------------------------------------------
	// Resources
	|	SUM(ProductCost.Quantity)            AS Quantity,
	|	SUM(ProductCost.Amount)              AS Amount
	// ------------------------------------------------------
	|INTO
	|	Table_InventoryJournal_MaterialCost_Total
	// ------------------------------------------------------
	|FROM
	|	Table_InventoryJournal_MaterialCost AS ProductCost
	|GROUP BY
	|	ProductCost.Product,
	|	ProductCost.Location";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_InventoryJournal_WasteCost(TablesList)
	
	// Add InventoryJournal - waste cost table to document structure.
	TablesList.Insert("Table_InventoryJournal_WasteCost", TablesList.Count());
	
	// Collect inventory data.
	QueryText =
	"SELECT // FIFO
	// ------------------------------------------------------
	// Dimensions
	|	LineItems_FIFO.Product                AS Product,
	|	LineItems_FIFO.Location               AS Location,
	// ------------------------------------------------------
	// Resources
	|	CASE
	|		WHEN ISNULL(Balance_FIFO.Quantity, 0) < LineItems_FIFO.QuantityRequested
	|		// The product written off completely (negative balances).
	|		THEN ISNULL(Balance_FIFO.Quantity, 0)
	|		// The product written off completely, or partially, or left off.
	|		ELSE LineItems_FIFO.QuantityRequested
	|	END                                   AS Quantity,
	|	CASE
	|		WHEN ISNULL(Balance_FIFO.Quantity, 0) <= LineItems_FIFO.QuantityRequested
	|		// The product written off completely.
	|		THEN ISNULL(Balance_FIFO.Amount, 0)
	|		// The product written off partially.
	|		ELSE CAST ( // Format(Amount / QuantityExpense / Quantity, ""ND=17; NFD=2"")
	|			 Balance_FIFO.Amount * LineItems_FIFO.QuantityRequested / Balance_FIFO.Quantity
	|			 AS NUMBER (17, 2))
	|	END                                   AS Amount
	// ------------------------------------------------------
	|INTO
	|	Table_InventoryJournal_WasteCost
	// ------------------------------------------------------
	|FROM
	|	Table_InventoryJournal_Wastes AS LineItems_FIFO
	|	LEFT JOIN Table_InventoryJournal_MaterialCost_Total AS Balance_FIFO
	|		ON  Balance_FIFO.Product  = LineItems_FIFO.Product
	|		AND Balance_FIFO.Location = LineItems_FIFO.Location
	|WHERE
	|	LineItems_FIFO.Type = VALUE(Enum.InventoryCosting.FIFO)
	|
	|UNION ALL
	|
	|SELECT // WeightedAverage
	// ------------------------------------------------------
	// Dimensions
	|	LineItems_WAve.Product                AS Product,
	|	VALUE(Catalog.Locations.EmptyRef)     AS Location,
	// ------------------------------------------------------
	// Resources
	|	CASE
	|		WHEN ISNULL(Balance_WAve.Quantity, 0) < LineItems_WAve.QuantityRequested
	|		// The product written off completely (negative balances).
	|		THEN ISNULL(Balance_WAve.Quantity, 0)
	|		// The product written off completely, or partially, or left off.
	|		ELSE LineItems_WAve.QuantityRequested
	|	END                                   AS Quantity,
	|	CASE
	|		WHEN ISNULL(Balance_WAve.Quantity, 0) <= LineItems_WAve.QuantityRequested
	|		// The product written off completely.
	|		THEN ISNULL(Balance_WAve.Amount, 0)
	|		// The product written off partially.
	|		ELSE CAST ( // Format(Amount / QuantityExpense / Quantity, ""ND=17; NFD=2"")
	|			 Balance_WAve.Amount * LineItems_WAve.QuantityRequested / Balance_WAve.Quantity
	|			 AS NUMBER (17, 2))
	|	END                                   AS Amount
	// ------------------------------------------------------
	|FROM
	|	Table_InventoryJournal_Wastes AS LineItems_WAve
	|	LEFT JOIN Table_InventoryJournal_MaterialCost_Total AS Balance_WAve
	|		ON  Balance_WAve.Product  = LineItems_WAve.Product
	|		AND Balance_WAve.Location = VALUE(Catalog.Locations.EmptyRef)
	|WHERE
	|	 LineItems_WAve.Type = VALUE(Enum.InventoryCosting.WeightedAverage)
	|AND LineItems_WAve.Location = VALUE(Catalog.Locations.EmptyRef)";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_InventoryJournal_WasteCost_Total(TablesList)
	
	// Add InventoryJournal inventory - waste cost total table to document structure.
	TablesList.Insert("Table_InventoryJournal_WasteCost_Total", TablesList.Count());
	
	// Collect inventory data.
	QueryText =
	"SELECT
	// ------------------------------------------------------
	// Dimensions
	|	ProductCost.Product                  AS Product,
	|	ProductCost.Location                 AS Location,
	// ------------------------------------------------------
	// Resources
	|	SUM(ProductCost.Quantity)            AS Quantity,
	|	SUM(ProductCost.Amount)              AS Amount
	// ------------------------------------------------------
	|INTO
	|	Table_InventoryJournal_WasteCost_Total
	// ------------------------------------------------------
	|FROM
	|	Table_InventoryJournal_WasteCost AS ProductCost
	|GROUP BY
	|	ProductCost.Product,
	|	ProductCost.Location";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_InventoryJournal_Totals(TablesList)
	
	// Add InventoryJournal inventory - common totals table to document structure.
	TablesList.Insert("Table_InventoryJournal_Totals", TablesList.Count());
	
	// Collect inventory data.
	QueryText =
	"SELECT
	// ------------------------------------------------------
	// Resources
	|	SUM(MaterialCost.Amount)             AS MaterialCost,
	|	SUM(WasteCost.Amount)                AS WasteCost
	// ------------------------------------------------------
	|INTO
	|	Table_InventoryJournal_Totals
	// ------------------------------------------------------
	|FROM
	|	Table_InventoryJournal_MaterialCost_Total AS MaterialCost
	|	LEFT JOIN Table_InventoryJournal_WasteCost_Total AS WasteCost
	|		ON  WasteCost.Product  = MaterialCost.Product
	|		AND WasteCost.Location = MaterialCost.Location";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_InventoryJournal_ResidualCost(TablesList)
	
	// Add InventoryJournal - residual cost table to document structure.
	TablesList.Insert("Table_InventoryJournal_ResidualCost", TablesList.Count());
	
	// Collect inventory data.
	QueryText =
	"SELECT // FIFO
	// ------------------------------------------------------
	// Dimensions
	|	LineItems_FIFO.Product                AS Product,
	|	LineItems_FIFO.Location               AS Location,
	// ------------------------------------------------------
	// Resources
	|	LineItems_FIFO.QuantityRequested      AS Quantity,
	|	CAST ( // Format(AssemblyCost * ResidualsPercent / 100%, ""ND=17; NFD=2"")
	|		CASE WHEN ISNULL(Totals.MaterialCost - Totals.WasteCost, 0) > 0
	|		     THEN ISNULL(Totals.MaterialCost - Totals.WasteCost, 0)
	|		     ELSE 0 END *
	|		LineItems_FIFO.Percent / 100
	|		AS NUMBER (17, 2))                AS Amount
	// ------------------------------------------------------
	|INTO
	|	Table_InventoryJournal_ResidualCost
	// ------------------------------------------------------
	|FROM
	|	Table_InventoryJournal_Residuals AS LineItems_FIFO
	|	LEFT JOIN Table_InventoryJournal_Totals AS Totals
	|		ON True
	|WHERE
	|	LineItems_FIFO.Type = VALUE(Enum.InventoryCosting.FIFO)
	|
	|UNION ALL
	|
	|SELECT // WeightedAverage
	// ------------------------------------------------------
	// Dimensions
	|	LineItems_WAve.Product                AS Product,
	|	VALUE(Catalog.Locations.EmptyRef)     AS Location,
	// ------------------------------------------------------
	// Resources
	|	LineItems_WAve.QuantityRequested      AS Quantity,
	|	CAST ( // Format(AssemblyCost * ResidualsPercent / 100%, ""ND=17; NFD=2"")
	|		CASE WHEN ISNULL(Totals.MaterialCost - Totals.WasteCost, 0) > 0
	|		     THEN ISNULL(Totals.MaterialCost - Totals.WasteCost, 0)
	|		     ELSE 0 END *
	|		LineItems_WAve.Percent / 100
	|		AS NUMBER (17, 2))                AS Amount
	// ------------------------------------------------------
	|FROM
	|	Table_InventoryJournal_Residuals AS LineItems_WAve
	|	LEFT JOIN Table_InventoryJournal_Totals AS Totals
	|		ON True
	|WHERE
	|	 LineItems_WAve.Type = VALUE(Enum.InventoryCosting.WeightedAverage)
	|AND LineItems_WAve.Location = VALUE(Catalog.Locations.EmptyRef)";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_InventoryJournal_ResidualCost_Total(TablesList)
	
	// Add InventoryJournal inventory - residual cost total table to document structure.
	TablesList.Insert("Table_InventoryJournal_ResidualCost_Total", TablesList.Count());
	
	// Collect inventory data.
	QueryText =
	"SELECT
	// ------------------------------------------------------
	// Dimensions
	|	ProductCost.Product                  AS Product,
	|	ProductCost.Location                 AS Location,
	// ------------------------------------------------------
	// Resources
	|	SUM(ProductCost.Quantity)            AS Quantity,
	|	SUM(ProductCost.Amount)              AS Amount
	// ------------------------------------------------------
	|INTO
	|	Table_InventoryJournal_ResidualCost_Total
	// ------------------------------------------------------
	|FROM
	|	Table_InventoryJournal_ResidualCost AS ProductCost
	|GROUP BY
	|	ProductCost.Product,
	|	ProductCost.Location";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_InventoryJournal_Totals2(TablesList)
	
	// Add InventoryJournal inventory - common totals table to document structure.
	TablesList.Insert("Table_InventoryJournal_Totals2", TablesList.Count());
	
	// Collect inventory data.
	QueryText =
	"SELECT
	// ------------------------------------------------------
	// Resources
	|	Totals.MaterialCost                  AS MaterialCost,
	|	Totals.WasteCost                     AS WasteCost,
	|	0                                    AS ResidualCost,
	|	0                                    AS ServicesCost
	// ------------------------------------------------------
	|INTO
	|	Table_InventoryJournal_Totals2
	// ------------------------------------------------------
	|FROM
	|	Table_InventoryJournal_Totals AS Totals
	|
	|UNION ALL
	|
	|SELECT
	// ------------------------------------------------------
	// Resources
	|	0                                    AS MaterialCost,
	|	0                                    AS WasteCost,
	|	SUM(ResidualCost.Amount)             AS ResidualCost,
	|	0                                    AS ServicesCost
	// ------------------------------------------------------
	|FROM
	|	Table_InventoryJournal_ResidualCost_Total AS ResidualCost
	|
	|UNION ALL
	|
	|SELECT
	// ------------------------------------------------------
	// Resources
	|	0                                    AS MaterialCost,
	|	0                                    AS WasteCost,
	|	0                                    AS ResidualCost,
	|	SUM(ServicesCost.Amount)             AS ServicesCost
	// ------------------------------------------------------
	|FROM
	|	Table_InventoryJournal_Services AS ServicesCost";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_InventoryJournal_DocumentTotal(TablesList)
	
	// Add InventoryJournal inventory - common totals table to document structure.
	TablesList.Insert("Table_InventoryJournal_DocumentTotal", TablesList.Count());
	
	// Collect inventory data.
	QueryText =
	"SELECT
	// ------------------------------------------------------
	// Resources
	|	SUM(Totals.MaterialCost)             AS MaterialCost,
	|	SUM(Totals.WasteCost)                AS WasteCost,
	|	SUM(Totals.ResidualCost)             AS ResidualCost,
	|	SUM(Totals.ServicesCost)             AS ServicesCost,
	|	SUM(Totals.MaterialCost) -
	|	SUM(Totals.WasteCost) -
	|	SUM(Totals.ResidualCost) +
	|	SUM(Totals.ServicesCost)             AS AssemblyCost
	// ------------------------------------------------------
	|INTO
	|	Table_InventoryJournal_DocumentTotal
	// ------------------------------------------------------
	|FROM
	|	Table_InventoryJournal_Totals2 AS Totals";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_InventoryJournal_AssemblyCost_Total(TablesList)
	
	// Add InventoryJournal inventory - assembly cost total table to document structure.
	TablesList.Insert("Table_InventoryJournal_AssemblyCost_Total", TablesList.Count());
	
	// Collect inventory data.
	QueryText =
	"SELECT // FIFO
	// ------------------------------------------------------
	// Dimensions
	|	Assembly_FIFO.Product                 AS Product,
	|	Assembly_FIFO.Location                AS Location,
	// ------------------------------------------------------
	// Resources
	|	Assembly_FIFO.QuantityRequested       AS Quantity,
	|	ISNULL(Totals.AssemblyCost, 0)        AS Amount
	// ------------------------------------------------------
	|INTO
	|	Table_InventoryJournal_AssemblyCost_Total
	// ------------------------------------------------------
	|FROM
	|	Table_InventoryJournal_Assembly AS Assembly_FIFO
	|	LEFT JOIN Table_InventoryJournal_DocumentTotal AS Totals
	|		ON True
	|WHERE
	|	Assembly_FIFO.Type = VALUE(Enum.InventoryCosting.FIFO)
	|
	|UNION ALL
	|
	|SELECT // WeightedAverage
	// ------------------------------------------------------
	// Dimensions
	|	Assembly_WAve.Product                 AS Product,
	|	VALUE(Catalog.Locations.EmptyRef)     AS Location,
	// ------------------------------------------------------
	// Resources
	|	Assembly_WAve.QuantityRequested       AS Quantity,
	|	ISNULL(Totals.AssemblyCost, 0)        AS Amount
	// ------------------------------------------------------
	|FROM
	|	Table_InventoryJournal_Assembly AS Assembly_WAve
	|	LEFT JOIN Table_InventoryJournal_DocumentTotal AS Totals
	|		ON True
	|WHERE
	|	 Assembly_WAve.Type = VALUE(Enum.InventoryCosting.WeightedAverage)
	|AND Assembly_WAve.Location = VALUE(Catalog.Locations.EmptyRef)";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_InventoryJournal(TablesList)
	
	// Add InventoryJournal table to document structure.
	TablesList.Insert("Table_InventoryJournal", TablesList.Count());
	
	// Collect inventory data.
	QueryText =
	// ------------------------------------------------------
	// [-] Materials
	// ------------------------------------------------------
	"SELECT // FIFO normal balances
	// ------------------------------------------------------
	// Standard attributes
	|	Assembly.Ref                          AS Recorder,
	|	Assembly.Date                         AS Period,
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
	|		WHEN Balance_FIFO.QuantityCumulative <= LineItems_FIFO.QuantityRequested
	|		// The layer written off completely.
	|		THEN Balance_FIFO.Quantity
	|		// The layer written partially or left off.
	|		ELSE CASE
	|			WHEN Balance_FIFO.Quantity + LineItems_FIFO.QuantityRequested - Balance_FIFO.QuantityCumulative > 0
	|			// The layer written off partially.
	|			THEN Balance_FIFO.Quantity + LineItems_FIFO.QuantityRequested - Balance_FIFO.QuantityCumulative
	|			// The layer is not requested and left off.
	|			ELSE 0
	|		END
	|	END                                   AS Quantity,
	|	CASE
	|		WHEN Balance_FIFO.QuantityCumulative <= LineItems_FIFO.QuantityRequested
	|		// The layer written off completely.
	|		THEN Balance_FIFO.Amount
	|		// The layer written partially or left off.
	|		ELSE CASE
	|			WHEN Balance_FIFO.Quantity + LineItems_FIFO.QuantityRequested - Balance_FIFO.QuantityCumulative > 0
	|			// The layer written off partially.
	|			THEN CAST ( // Format(Amount * QuantityExpense / Quantity, ""ND=17; NFD=2"")
	|				 Balance_FIFO.Amount * 
	|				(Balance_FIFO.Quantity + LineItems_FIFO.QuantityRequested - Balance_FIFO.QuantityCumulative) /
	|				 Balance_FIFO.Quantity
	|				 AS NUMBER (17, 2))
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
	|	LEFT JOIN Document.Assembly AS Assembly
	|		ON True
	|WHERE
	|	Assembly.Ref = &Ref
	|	AND LineItems_FIFO.Type = VALUE(Enum.InventoryCosting.FIFO)
	|	AND // Quantity > 0
	|	CASE
	|		WHEN Balance_FIFO.QuantityCumulative <= LineItems_FIFO.QuantityRequested
	|		// The layer written off completely.
	|		THEN Balance_FIFO.Quantity
	|		// The layer written partially or left off.
	|		ELSE CASE
	|			WHEN Balance_FIFO.Quantity + LineItems_FIFO.QuantityRequested - Balance_FIFO.QuantityCumulative > 0
	|			// The layer written off partially.
	|			THEN Balance_FIFO.Quantity + LineItems_FIFO.QuantityRequested - Balance_FIFO.QuantityCumulative
	|			// The layer is not requested and left off.
	|			ELSE 0
	|		END
	|	END > 0
	|
	|UNION ALL
	|
	|SELECT // FIFO negative balances
	// ------------------------------------------------------
	// Standard attributes
	|	Assembly.Ref                          AS Recorder,
	|	Assembly.Date                         AS Period,
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
	|		WHEN LineItems_FIFO.QuantityRequested > ISNULL(Balance_FIFO.Quantity, 0)
	|		// The balance became negative.
	|		THEN LineItems_FIFO.QuantityRequested - ISNULL(Balance_FIFO.Quantity, 0)
	|		// The balance still positive or zeroed.
	|		ELSE 0
	|	END                                   AS Quantity,
	|	0                                     AS Amount
	// ------------------------------------------------------
	// Attributes
	// ------------------------------------------------------
	|FROM
	|	Table_InventoryJournal_LineItems AS LineItems_FIFO
	|	LEFT JOIN Table_InventoryJournal_Balance_Quantity AS Balance_FIFO
	|		ON  Balance_FIFO.Product  = LineItems_FIFO.Product
	|		AND Balance_FIFO.Location = LineItems_FIFO.Location
	|	LEFT JOIN Document.Assembly AS Assembly
	|		ON True
	|WHERE
	|	Assembly.Ref = &Ref
	|	AND LineItems_FIFO.Type = VALUE(Enum.InventoryCosting.FIFO)
	|	AND // Quantity > 0
	|	CASE
	|		WHEN LineItems_FIFO.QuantityRequested > ISNULL(Balance_FIFO.Quantity, 0)
	|		// The balance became negative.
	|		THEN LineItems_FIFO.QuantityRequested - ISNULL(Balance_FIFO.Quantity, 0)
	|		// The balance still positive or zeroed.
	|		ELSE 0
	|	END > 0
	|
	|UNION ALL
	|
	|SELECT // WeightedAverage by quantity
	// ------------------------------------------------------
	// Standard attributes
	|	Assembly.Ref                          AS Recorder,
	|	Assembly.Date                         AS Period,
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
	|	LineItems_WAve.QuantityRequested      AS Quantity,
	|	0                                     AS Amount
	// ------------------------------------------------------
	// Attributes
	// ------------------------------------------------------
	|FROM
	|	Table_InventoryJournal_LineItems AS LineItems_WAve
	|	LEFT JOIN Document.Assembly AS Assembly
	|		ON True
	|WHERE
	|	Assembly.Ref = &Ref
	|	AND LineItems_WAve.Type      = VALUE(Enum.InventoryCosting.WeightedAverage)
	|	AND LineItems_WAve.Location <> VALUE(Catalog.Locations.EmptyRef)
	|	AND LineItems_WAve.QuantityRequested > 0
	|
	|UNION ALL
	|
	|SELECT // WeightedAverage by amount
	// ------------------------------------------------------
	// Standard attributes
	|	Assembly.Ref                          AS Recorder,
	|	Assembly.Date                         AS Period,
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
	|	CASE
	|		WHEN ISNULL(Balance_WAve.Quantity, 0) <= LineItems_WAve.QuantityRequested
	|		// The product written off completely.
	|		THEN ISNULL(Balance_WAve.Amount, 0)
	|		// The product written off partially.
	|		ELSE CAST ( // Format(Amount / QuantityExpense / Quantity, ""ND=17; NFD=2"")
	|			 Balance_WAve.Amount * LineItems_WAve.QuantityRequested / Balance_WAve.Quantity
	|			 AS NUMBER (17, 2))
	|	END                                   AS Amount
	// ------------------------------------------------------
	// Attributes
	// ------------------------------------------------------
	|FROM
	|	Table_InventoryJournal_LineItems AS LineItems_WAve
	|	LEFT JOIN Table_InventoryJournal_Balance_Quantity AS Balance_WAve
	|		ON  Balance_WAve.Product  = LineItems_WAve.Product
	|		AND Balance_WAve.Location = VALUE(Catalog.Locations.EmptyRef)
	|	LEFT JOIN Document.Assembly AS Assembly
	|		ON True
	|WHERE
	|	Assembly.Ref = &Ref
	|	AND LineItems_WAve.Type     = VALUE(Enum.InventoryCosting.WeightedAverage)
	|	AND LineItems_WAve.Location = VALUE(Catalog.Locations.EmptyRef)
	|	AND // Amount > 0
	|	CASE
	|		WHEN ISNULL(Balance_WAve.Quantity, 0) <= LineItems_WAve.QuantityRequested
	|		// The product written off completely.
	|		THEN ISNULL(Balance_WAve.Amount, 0)
	|		// The product written off partially.
	|		ELSE CAST ( // Format(Amount / QuantityExpense / Quantity, ""ND=17; NFD=2"")
	|			 Balance_WAve.Amount * LineItems_WAve.QuantityRequested / Balance_WAve.Quantity
	|			 AS NUMBER (17, 2))
	|	END > 0
	|
	|UNION ALL
	|
	// ------------------------------------------------------
	// [+] Assembly
	// ------------------------------------------------------
	|SELECT // FIFO
	// ------------------------------------------------------
	// Standard attributes
	|	Assembly.Ref                          AS Recorder,
	|	Assembly.Date                         AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Dimensions
	|	Assembly_FIFO.Product                 AS Product,
	|	Assembly_FIFO.Location                AS Location,
	|	Assembly.Ref                          AS Layer,
	// ------------------------------------------------------
	// Resources
	|	Assembly_FIFO.QuantityRequested       AS Quantity,
	|	ISNULL(AssemblyCost.Amount, 0)        AS Amount
	// ------------------------------------------------------
	// Attributes
	// ------------------------------------------------------
	|FROM
	|	Table_InventoryJournal_Assembly AS Assembly_FIFO
	|	LEFT JOIN Table_InventoryJournal_AssemblyCost_Total AS AssemblyCost
	|		ON  Assembly_FIFO.Product  = AssemblyCost.Product
	|		AND Assembly_FIFO.Location = AssemblyCost.Location
	|	LEFT JOIN Document.Assembly AS Assembly
	|		ON True
	|WHERE
	|	Assembly.Ref = &Ref
	|	AND Assembly_FIFO.Type = VALUE(Enum.InventoryCosting.FIFO)
	|	AND Assembly_FIFO.QuantityRequested > 0
	|
	|UNION ALL
	|
	|SELECT // WeightedAverage by quantity
	// ------------------------------------------------------
	// Standard attributes
	|	Assembly.Ref                          AS Recorder,
	|	Assembly.Date                         AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Dimensions
	|	Assembly_WAve.Product                 AS Product,
	|	Assembly_WAve.Location                AS Location,
	|	NULL                                  AS Layer,
	// ------------------------------------------------------
	// Resources
	|	Assembly_WAve.QuantityRequested       AS Quantity,
	|	0                                     AS Amount
	// ------------------------------------------------------
	// Attributes
	// ------------------------------------------------------
	|FROM
	|	Table_InventoryJournal_Assembly AS Assembly_WAve
	|	LEFT JOIN Document.Assembly AS Assembly
	|		ON True
	|WHERE
	|	Assembly.Ref = &Ref
	|	AND Assembly_WAve.Type      = VALUE(Enum.InventoryCosting.WeightedAverage)
	|	AND Assembly_WAve.Location <> VALUE(Catalog.Locations.EmptyRef)
	|	AND Assembly_WAve.QuantityRequested > 0
	|
	|UNION ALL
	|
	|SELECT // WeightedAverage by amount
	// ------------------------------------------------------
	// Standard attributes
	|	Assembly.Ref                          AS Recorder,
	|	Assembly.Date                         AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Dimensions
	|	Assembly_WAve.Product                 AS Product,
	|	VALUE(Catalog.Locations.EmptyRef)     AS Location,
	|	NULL                                  AS Layer,
	// ------------------------------------------------------
	// Resources
	|	0                                     AS Quantity,
	|	ISNULL(AssemblyCost.Amount, 0)        AS Amount
	// ------------------------------------------------------
	// Attributes
	// ------------------------------------------------------
	|FROM
	|	Table_InventoryJournal_Assembly AS Assembly_WAve
	|	LEFT JOIN Table_InventoryJournal_AssemblyCost_Total AS AssemblyCost
	|		ON  Assembly_WAve.Product  = AssemblyCost.Product
	|		AND Assembly_WAve.Location = AssemblyCost.Location
	|	LEFT JOIN Document.Assembly AS Assembly
	|		ON True
	|WHERE
	|	Assembly.Ref = &Ref
	|	AND Assembly_WAve.Type     = VALUE(Enum.InventoryCosting.WeightedAverage)
	|	AND Assembly_WAve.Location = VALUE(Catalog.Locations.EmptyRef)
	|	AND Assembly_WAve.QuantityRequested > 0
	|
	|UNION ALL
	|
	// ------------------------------------------------------
	// [+] Residuals
	// ------------------------------------------------------
	|SELECT // FIFO
	// ------------------------------------------------------
	// Standard attributes
	|	Assembly.Ref                          AS Recorder,
	|	Assembly.Date                         AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Dimensions
	|	Residuals_FIFO.Product                AS Product,
	|	Residuals_FIFO.Location               AS Location,
	|	Assembly.Ref                          AS Layer,
	// ------------------------------------------------------
	// Resources
	|	Residuals_FIFO.QuantityRequested      AS Quantity,
	|	CASE
	|		WHEN Residuals_FIFO.QuantityRequested = ISNULL(ResidualCost.Quantity, 0)
	|		// The product written off completely.
	|		THEN ISNULL(ResidualCost.Amount, 0)
	|		// The product written partially off.
	|		ELSE CASE
	|			WHEN ISNULL(ResidualCost.Quantity, 0) > 0
	|			THEN CAST ( // Format(Amount * Quantity / QuantityTotal, ""ND=17; NFD=2"")
	|				 ISNULL(ResidualCost.Amount, 0) *
	|				 Residuals_FIFO.QuantityRequested /
	|				 ISNULL(ResidualCost.Quantity, 0)
	|				 AS NUMBER (17, 2))
	|			// The product doesn't exist.
	|			ELSE 0
	|		END
	|	END                                   AS Amount
	// ------------------------------------------------------
	// Attributes
	// ------------------------------------------------------
	|FROM
	|	Table_InventoryJournal_Residuals AS Residuals_FIFO
	|	LEFT JOIN Table_InventoryJournal_ResidualCost_Total AS ResidualCost
	|		ON  Residuals_FIFO.Product  = ResidualCost.Product
	|		AND Residuals_FIFO.Location = ResidualCost.Location
	|	LEFT JOIN Document.Assembly AS Assembly
	|		ON True
	|WHERE
	|	Assembly.Ref = &Ref
	|	AND Residuals_FIFO.Type = VALUE(Enum.InventoryCosting.FIFO)
	|	AND Residuals_FIFO.QuantityRequested > 0
	|
	|UNION ALL
	|
	|SELECT // WeightedAverage by quantity
	// ------------------------------------------------------
	// Standard attributes
	|	Assembly.Ref                          AS Recorder,
	|	Assembly.Date                         AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Dimensions
	|	Residuals_WAve.Product                AS Product,
	|	Residuals_WAve.Location               AS Location,
	|	NULL                                  AS Layer,
	// ------------------------------------------------------
	// Resources
	|	Residuals_WAve.QuantityRequested      AS Quantity,
	|	0                                     AS Amount
	// ------------------------------------------------------
	// Attributes
	// ------------------------------------------------------
	|FROM
	|	Table_InventoryJournal_Residuals AS Residuals_WAve
	|	LEFT JOIN Document.Assembly AS Assembly
	|		ON True
	|WHERE
	|	Assembly.Ref = &Ref
	|	AND Residuals_WAve.Type      = VALUE(Enum.InventoryCosting.WeightedAverage)
	|	AND Residuals_WAve.Location <> VALUE(Catalog.Locations.EmptyRef)
	|	AND Residuals_WAve.QuantityRequested > 0
	|
	|UNION ALL
	|
	|SELECT // WeightedAverage by amount
	// ------------------------------------------------------
	// Standard attributes
	|	Assembly.Ref                          AS Recorder,
	|	Assembly.Date                         AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Dimensions
	|	Residuals_WAve.Product                AS Product,
	|	VALUE(Catalog.Locations.EmptyRef)     AS Location,
	|	NULL                                  AS Layer,
	// ------------------------------------------------------
	// Resources
	|	0                                     AS Quantity,
	|	CASE
	|		WHEN Residuals_WAve.QuantityRequested = ISNULL(ResidualCost.Quantity, 0)
	|		// The product written off completely.
	|		THEN ISNULL(ResidualCost.Amount, 0)
	|		// The product written partially off.
	|		ELSE CASE
	|			WHEN ISNULL(ResidualCost.Quantity, 0) > 0
	|			THEN CAST ( // Format(Amount * Quantity / QuantityTotal, ""ND=17; NFD=2"")
	|				 ISNULL(ResidualCost.Amount, 0) *
	|				 Residuals_WAve.QuantityRequested /
	|				 ISNULL(ResidualCost.Quantity, 0)
	|				 AS NUMBER (17, 2))
	|			// The product doesn't exist.
	|			ELSE 0
	|		END
	|	END                                   AS Amount
	// ------------------------------------------------------
	// Attributes
	// ------------------------------------------------------
	|FROM
	|	Table_InventoryJournal_Residuals AS Residuals_WAve
	|	LEFT JOIN Table_InventoryJournal_ResidualCost_Total AS ResidualCost
	|		ON  Residuals_WAve.Product  = ResidualCost.Product
	|		AND Residuals_WAve.Location = ResidualCost.Location
	|	LEFT JOIN Document.Assembly AS Assembly
	|		ON True
	|WHERE
	|	Assembly.Ref = &Ref
	|	AND Residuals_WAve.Type     = VALUE(Enum.InventoryCosting.WeightedAverage)
	|	AND Residuals_WAve.Location = VALUE(Catalog.Locations.EmptyRef)
	|	AND Residuals_WAve.QuantityRequested > 0";
	
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
Function Query_ItemLastCosts_AssemblyResidualsServices(TablesList)
	
	// Add ItemLastCosts table to document structure.
	TablesList.Insert("Table_ItemLastCosts_AssemblyResidualsServices", TablesList.Count());
	
	// Collect items cost data.
	QueryText =
	"SELECT
	// ------------------------------------------------------
	// [*] Assembly
	// ------------------------------------------------------
	// Dimensions
	|	Assembly.Product                        AS Product,
	// ------------------------------------------------------
	// Resources
	|	CASE
	|		WHEN Assembly.Product.PricePrecision = 3
	|			THEN CAST(ISNULL(Totals.AssemblyCost, 0) /
	|						CASE WHEN Assembly.QtyUM > 0
	|							 THEN Assembly.QtyUM
	|							 ELSE 1
	|						END AS NUMBER(17, 3))
	|		WHEN Assembly.Product.PricePrecision = 4
	|			THEN CAST(ISNULL(Totals.AssemblyCost, 0) /
	|						CASE WHEN Assembly.QtyUM > 0
	|							 THEN Assembly.QtyUM
	|							 ELSE 1
	|						END AS NUMBER(17, 4))
	|		ELSE CAST(ISNULL(Totals.AssemblyCost, 0) /
	|						CASE WHEN Assembly.QtyUM > 0
	|							 THEN Assembly.QtyUM
	|							 ELSE 1
	|						END AS NUMBER(17, 2))
	|	END                                      AS Cost
	// ------------------------------------------------------
	|INTO
	|	Table_ItemLastCosts_AssemblyResidualsServices
	// ------------------------------------------------------
	|FROM
	|	Document.Assembly AS Assembly
	|	LEFT JOIN Table_InventoryJournal_DocumentTotal AS Totals
	|		ON True
	|WHERE
	|	Assembly.Ref = &Ref
	|	AND // Cost > 0
	|		CASE
	|			WHEN Assembly.Product.PricePrecision = 3
	|				THEN CAST(ISNULL(Totals.AssemblyCost, 0) /
	|						CASE WHEN Assembly.QtyUM > 0
	|							 THEN Assembly.QtyUM
	|							 ELSE 1
	|						END AS NUMBER(17, 3))
	|			WHEN Assembly.Product.PricePrecision = 4
	|				THEN CAST(ISNULL(Totals.AssemblyCost, 0) /
	|						CASE WHEN Assembly.QtyUM > 0
	|							 THEN Assembly.QtyUM
	|							 ELSE 1
	|						END AS NUMBER(17, 4))
	|			ELSE CAST(ISNULL(Totals.AssemblyCost, 0) /
	|						CASE WHEN Assembly.QtyUM > 0
	|							 THEN Assembly.QtyUM
	|							 ELSE 1
	|						END AS NUMBER(17, 2))
	|		END > 0
	|
	|UNION ALL
	|
	|SELECT
	// ------------------------------------------------------
	// [+] Residuals
	// ------------------------------------------------------
	// Dimensions
	|	Residuals.Product                        AS Product,
	// ------------------------------------------------------
	// Resources
	|	CASE
	|		WHEN Residuals.Product.PricePrecision = 3
	|			THEN CAST(Residuals.PriceUnits /
	|						CASE WHEN Residuals.Unit.Factor > 0
	|							 THEN Residuals.Unit.Factor
	|							 ELSE 1
	|						END AS NUMBER(17, 3))
	|		WHEN Residuals.Product.PricePrecision = 4
	|			THEN CAST(Residuals.PriceUnits /
	|						CASE WHEN Residuals.Unit.Factor > 0
	|							 THEN Residuals.Unit.Factor
	|							 ELSE 1
	|						END AS NUMBER(17, 4))
	|		ELSE CAST(Residuals.PriceUnits /
	|						CASE WHEN Residuals.Unit.Factor > 0
	|							 THEN Residuals.Unit.Factor
	|							 ELSE 1
	|						END AS NUMBER(17, 2))
	|	END                                      AS Cost
	// ------------------------------------------------------
	// Attributes
	// ------------------------------------------------------
	|FROM
	|	Document.Assembly.Residuals AS Residuals
	|WHERE
	|	Residuals.Ref = &Ref
	|	AND // Cost > 0
	|		CASE
	|			WHEN Residuals.Product.PricePrecision = 3
	|				THEN CAST(Residuals.PriceUnits /
	|							CASE WHEN Residuals.Unit.Factor > 0
	|								 THEN Residuals.Unit.Factor
	|								 ELSE 1
	|							END AS NUMBER(17, 3))
	|			WHEN Residuals.Product.PricePrecision = 4
	|				THEN CAST(Residuals.PriceUnits /
	|							CASE WHEN Residuals.Unit.Factor > 0
	|								 THEN Residuals.Unit.Factor
	|								 ELSE 1
	|							END AS NUMBER(17, 4))
	|			ELSE CAST(Residuals.PriceUnits /
	|							CASE WHEN Residuals.Unit.Factor > 0
	|								 THEN Residuals.Unit.Factor
	|								 ELSE 1
	|							END AS NUMBER(17, 2))
	|		END > 0
	|
	|UNION ALL
	|
	|SELECT
	// ------------------------------------------------------
	// [+] Services
	// ------------------------------------------------------
	// Dimensions
	|	Services.Product                         AS Product,
	// ------------------------------------------------------
	// Resources
	|	CASE
	|		WHEN Services.Product.PricePrecision = 3
	|			THEN CAST(Services.PriceUnits /
	|						CASE WHEN Services.Unit.Factor > 0
	|							 THEN Services.Unit.Factor
	|							 ELSE 1
	|						END AS NUMBER(17, 3))
	|		WHEN Services.Product.PricePrecision = 4
	|			THEN CAST(Services.PriceUnits /
	|						CASE WHEN Services.Unit.Factor > 0
	|							 THEN Services.Unit.Factor
	|							 ELSE 1
	|						END AS NUMBER(17, 4))
	|		ELSE CAST(Services.PriceUnits /
	|						CASE WHEN Services.Unit.Factor > 0
	|							 THEN Services.Unit.Factor
	|							 ELSE 1
	|						END AS NUMBER(17, 2))
	|	END                                      AS Cost
	// ------------------------------------------------------
	// Attributes
	// ------------------------------------------------------
	|FROM
	|	Document.Assembly.Services AS Services
	|WHERE
	|	Services.Ref = &Ref
	|	AND // Cost > 0
	|		CASE
	|			WHEN Services.Product.PricePrecision = 3
	|				THEN CAST(Services.PriceUnits /
	|							CASE WHEN Services.Unit.Factor > 0
	|								 THEN Services.Unit.Factor
	|								 ELSE 1
	|							END AS NUMBER(17, 3))
	|			WHEN Services.Product.PricePrecision = 4
	|				THEN CAST(Services.PriceUnits /
	|							CASE WHEN Services.Unit.Factor > 0
	|								 THEN Services.Unit.Factor
	|								 ELSE 1
	|							END AS NUMBER(17, 4))
	|			ELSE CAST(Services.PriceUnits /
	|							CASE WHEN Services.Unit.Factor > 0
	|								 THEN Services.Unit.Factor
	|								 ELSE 1
	|							END AS NUMBER(17, 2))
	|		END > 0";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_ItemLastCosts_AssemblyResidualsServices_Total(TablesList)
	
	// Add ItemLastCosts table to document structure.
	TablesList.Insert("Table_ItemLastCosts_AssemblyResidualsServices_Total", TablesList.Count());
	
	// Collect items cost data.
	QueryText =
	"SELECT
	// ------------------------------------------------------
	// Dimensions
	|	Source.Product                           AS Product,
	// ------------------------------------------------------
	// Resources
	|	MAX(Source.Cost)                         AS Cost
	// ------------------------------------------------------
	|INTO
	|	Table_ItemLastCosts_AssemblyResidualsServices_Total
	// ------------------------------------------------------
	|FROM
	|	Table_ItemLastCosts_AssemblyResidualsServices AS Source
	|GROUP BY
	|	Source.Product";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_ItemLastCosts(TablesList)
	
	// Add ItemLastCosts table to document structure.
	TablesList.Insert("Table_ItemLastCosts", TablesList.Count());
	
	// Collect items cost data.
	QueryText =
	"SELECT
	// ------------------------------------------------------
	// Standard attributes
	|	Assembly.Ref                             AS Recorder,
	|	Assembly.Date                            AS Period,
	|	0                                        AS LineNumber,
	|	True                                     AS Active,
	// ------------------------------------------------------
	// Dimensions
	|	Source.Product                           AS Product,
	// ------------------------------------------------------
	// Resources
	|	Source.Cost                              AS Cost
	// ------------------------------------------------------
	// Attributes
	// ------------------------------------------------------
	|FROM
	|	Table_ItemLastCosts_AssemblyResidualsServices_Total AS Source
	|	LEFT JOIN Document.Assembly AS Assembly
	|		On True
	|WHERE
	|	Assembly.Ref = &Ref
	|	AND // Cost > 0
	|		Source.Cost > 0";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_GeneralJournal_Materials(TablesList)
	
	// Add GeneralJournal requested items table to document structure.
	TablesList.Insert("Table_GeneralJournal_Materials", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT
	// ------------------------------------------------------
	// Dimensions
	|	LineItems.Product.CostingMethod       AS Type,
	|	LineItems.Product                     AS Product,
	//--//GJ++
	|	LineItems.Class                       AS Class,
	|	LineItems.Project                     AS Project,
	//--//GJ--
	|	LineItems.Location                    AS Location,
	|	LineItems.Product.InventoryOrExpenseAccount AS InvOrExpAccount,
	// ------------------------------------------------------
	// Resources
	|	LineItems.QtyUM                       AS Quantity
	// ------------------------------------------------------
	|INTO
	|	Table_GeneralJournal_Materials
	|FROM
	|	Document.Assembly.LineItems AS LineItems
	|WHERE
	|	LineItems.Ref = &Ref";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_GeneralJournal_Services(TablesList)
	
	// Add GeneralJournal requested items table to document structure.
	TablesList.Insert("Table_GeneralJournal_Services", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT
	// ------------------------------------------------------
	// Dimensions
	|	Services.Product                      AS Product,
	|	Services.Product.InventoryOrExpenseAccount AS ServicesAccount,
	|	Services.Class                        AS Class,
	|	Services.Project                      AS Project,
	// ------------------------------------------------------
	// Resources
	|	Services.QtyUM                        AS Quantity,
	|	Services.LineTotal                    AS Amount
	// ------------------------------------------------------
	|INTO
	|	Table_GeneralJournal_Services
	|FROM
	|	Document.Assembly.Services AS Services
	|WHERE
	|	Services.Ref = &Ref";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_GeneralJournal_Wastes(TablesList)
	
	// Add GeneralJournal requested items table to document structure.
	TablesList.Insert("Table_GeneralJournal_Wastes", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT
	// ------------------------------------------------------
	// Dimensions
	|	LineItems.Product.CostingMethod       AS Type,
	|	LineItems.Product                     AS Product,
	|	LineItems.Location                    AS Location,
	|	LineItems.Ref.WasteAccount            AS WasteAccount,
	|	LineItems.Class                       AS Class,
	|	LineItems.Project                     AS Project,
	// ------------------------------------------------------
	// Resources
	|	LineItems.WasteQtyUM                  AS Quantity
	// ------------------------------------------------------
	|INTO
	|	Table_GeneralJournal_Wastes
	|FROM
	|	Document.Assembly.LineItems AS LineItems
	|WHERE
	|	LineItems.Ref = &Ref";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_GeneralJournal_Residuals(TablesList)
	
	// Add GeneralJournal requested items table to document structure.
	TablesList.Insert("Table_GeneralJournal_Residuals", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT
	// ------------------------------------------------------
	// Dimensions
	|	Residuals.Product.CostingMethod       AS Type,
	|	Residuals.Product                     AS Product,
	|	Residuals.Location                    AS Location,
	|	Residuals.Product.InventoryOrExpenseAccount AS InvOrExpAccount,
	// ------------------------------------------------------
	// Resources
	|	Residuals.QtyUM                       AS Quantity
	// ------------------------------------------------------
	|INTO
	|	Table_GeneralJournal_Residuals
	|FROM
	|	Document.Assembly.Residuals AS Residuals
	|WHERE
	|	Residuals.Ref = &Ref";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_GeneralJournal_Accounts_Materials_InvOrExp_Quantity(TablesList)
	
	// Add GeneralJournal InvOrExp accounts table to document structure.
	TablesList.Insert("Table_GeneralJournal_Accounts_Materials_InvOrExp_Quantity", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // InvOrExp accounts selection
	// ------------------------------------------------------
	// Dimensions
	|	Accounts.InvOrExpAccount              AS InvOrExpAccount,
	|	Accounts.Product                      AS Product,
	|	Accounts.Location                     AS Location,
	|	Accounts.Type                         AS Type,
	// ------------------------------------------------------
	// Resources
	|	SUM(Accounts.Quantity)                AS Quantity
	// ------------------------------------------------------
	|INTO
	|	Table_GeneralJournal_Accounts_Materials_InvOrExp_Quantity
	|FROM
	|	Table_GeneralJournal_Materials AS Accounts
	|GROUP BY
	|	Accounts.InvOrExpAccount,
	|	Accounts.Product,
	|	Accounts.Location,
	|	Accounts.Type";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_GeneralJournal_Accounts_Materials_InvOrExp_Amount(TablesList)
	
	// Add GeneralJournal InvOrExp accounts table to document structure.
	TablesList.Insert("Table_GeneralJournal_Accounts_Materials_InvOrExp_Amount", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // FIFO
	// ------------------------------------------------------
	// Dimensions
	|	Accounts.InvOrExpAccount              AS InvOrExpAccount,
	// ------------------------------------------------------
	// Resources
	|	CASE
	|		WHEN ISNULL(ProductCost.Quantity, 0) <= Accounts.Quantity
	|		// The product written off completely.
	|		THEN ISNULL(ProductCost.Amount, 0)
	|		// The product written off partially.
	|		ELSE CAST ( // Format(Amount / QuantityExpense / Quantity, ""ND=17; NFD=2"")
	|			ProductCost.Amount * Accounts.Quantity / ProductCost.Quantity
	|			AS NUMBER (17, 2))
	|	END                                   AS Amount
	// ------------------------------------------------------
	|INTO
	|	Table_GeneralJournal_Accounts_Materials_InvOrExp_Amount
	|FROM
	|	Table_GeneralJournal_Accounts_Materials_InvOrExp_Quantity AS Accounts
	|	LEFT JOIN Table_InventoryJournal_MaterialCost_Total AS ProductCost
	|		ON  ProductCost.Product  = Accounts.Product
	|		AND ProductCost.Location = Accounts.Location
	|WHERE
	|	Accounts.Type = VALUE(Enum.InventoryCosting.FIFO)
	|
	|UNION ALL
	|
	|SELECT // WeightedAverage
	// ------------------------------------------------------
	// Dimensions
	|	Accounts.InvOrExpAccount              AS InvOrExpAccount,
	// ------------------------------------------------------
	// Resources
	|	CASE
	|		WHEN ISNULL(ProductCost.Quantity, 0) <= Accounts.Quantity
	|		// The product written off completely.
	|		THEN ISNULL(ProductCost.Amount, 0)
	|		// The product written off partially.
	|		ELSE CAST ( // Format(Amount / QuantityExpense / Quantity, ""ND=17; NFD=2"")
	|			ProductCost.Amount * Accounts.Quantity / ProductCost.Quantity
	|			AS NUMBER (17, 2))
	|	END                                   AS Amount
	// ------------------------------------------------------
	|FROM
	|	Table_GeneralJournal_Accounts_Materials_InvOrExp_Quantity AS Accounts
	|	LEFT JOIN Table_InventoryJournal_MaterialCost_Total AS ProductCost
	|		ON  ProductCost.Product  = Accounts.Product
	|		AND ProductCost.Location = VALUE(Catalog.Locations.EmptyRef)
	|WHERE
	|	Accounts.Type = VALUE(Enum.InventoryCosting.WeightedAverage)";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_GeneralJournal_Accounts_Materials_InvOrExp(TablesList)
	
	// Add GeneralJournal InvOrExp accounts table to document structure.
	TablesList.Insert("Table_GeneralJournal_Accounts_Materials_InvOrExp", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // InvOrExp accounts selection
	// ------------------------------------------------------
	// Dimensions
	|	Accounts.InvOrExpAccount              AS InvOrExpAccount,
	// ------------------------------------------------------
	// Resources
	|	SUM(Accounts.Amount)                  AS Amount
	// ------------------------------------------------------
	|INTO
	|	Table_GeneralJournal_Accounts_Materials_InvOrExp
	|FROM
	|	Table_GeneralJournal_Accounts_Materials_InvOrExp_Amount AS Accounts
	|GROUP BY
	|	Accounts.InvOrExpAccount";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_GeneralJournal_Accounts_Residuals_InvOrExp_Quantity(TablesList)
	
	// Add GeneralJournal InvOrExp accounts table to document structure.
	TablesList.Insert("Table_GeneralJournal_Accounts_Residuals_InvOrExp_Quantity", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // InvOrExp accounts selection
	// ------------------------------------------------------
	// Dimensions
	|	Accounts.InvOrExpAccount              AS InvOrExpAccount,
	|	Accounts.Product                      AS Product,
	|	Accounts.Location                     AS Location,
	|	Accounts.Type                         AS Type,
	// ------------------------------------------------------
	// Resources
	|	SUM(Accounts.Quantity)                AS Quantity
	// ------------------------------------------------------
	|INTO
	|	Table_GeneralJournal_Accounts_Residuals_InvOrExp_Quantity
	|FROM
	|	Table_GeneralJournal_Residuals AS Accounts
	|GROUP BY
	|	Accounts.InvOrExpAccount,
	|	Accounts.Product,
	|	Accounts.Location,
	|	Accounts.Type";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_GeneralJournal_Accounts_Residuals_InvOrExp_Amount(TablesList)
	
	// Add GeneralJournal InvOrExp accounts table to document structure.
	TablesList.Insert("Table_GeneralJournal_Accounts_Residuals_InvOrExp_Amount", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // FIFO
	// ------------------------------------------------------
	// Dimensions
	|	Accounts.InvOrExpAccount              AS InvOrExpAccount,
	// ------------------------------------------------------
	// Resources
	|	CASE
	|		WHEN ISNULL(ProductCost.Quantity, 0) <= Accounts.Quantity
	|		// The product written off completely.
	|		THEN ISNULL(ProductCost.Amount, 0)
	|		// The product written off partially.
	|		ELSE CAST ( // Format(Amount / QuantityExpense / Quantity, ""ND=17; NFD=2"")
	|			ProductCost.Amount * Accounts.Quantity / ProductCost.Quantity
	|			AS NUMBER (17, 2))
	|	END                                   AS Amount
	// ------------------------------------------------------
	|INTO
	|	Table_GeneralJournal_Accounts_Residuals_InvOrExp_Amount
	|FROM
	|	Table_GeneralJournal_Accounts_Residuals_InvOrExp_Quantity AS Accounts
	|	LEFT JOIN Table_InventoryJournal_ResidualCost_Total AS ProductCost
	|		ON  ProductCost.Product  = Accounts.Product
	|		AND ProductCost.Location = Accounts.Location
	|WHERE
	|	Accounts.Type = VALUE(Enum.InventoryCosting.FIFO)
	|
	|UNION ALL
	|
	|SELECT // WeightedAverage
	// ------------------------------------------------------
	// Dimensions
	|	Accounts.InvOrExpAccount              AS InvOrExpAccount,
	// ------------------------------------------------------
	// Resources
	|	CASE
	|		WHEN ISNULL(ProductCost.Quantity, 0) <= Accounts.Quantity
	|		// The product written off completely.
	|		THEN ISNULL(ProductCost.Amount, 0)
	|		// The product written off partially.
	|		ELSE CAST ( // Format(Amount / QuantityExpense / Quantity, ""ND=17; NFD=2"")
	|			ProductCost.Amount * Accounts.Quantity / ProductCost.Quantity
	|			AS NUMBER (17, 2))
	|	END                                   AS Amount
	// ------------------------------------------------------
	|FROM
	|	Table_GeneralJournal_Accounts_Residuals_InvOrExp_Quantity AS Accounts
	|	LEFT JOIN Table_InventoryJournal_ResidualCost_Total AS ProductCost
	|		ON  ProductCost.Product  = Accounts.Product
	|		AND ProductCost.Location = VALUE(Catalog.Locations.EmptyRef)
	|WHERE
	|	Accounts.Type = VALUE(Enum.InventoryCosting.WeightedAverage)";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_GeneralJournal_Accounts_Residuals_InvOrExp(TablesList)
	
	// Add GeneralJournal InvOrExp accounts table to document structure.
	TablesList.Insert("Table_GeneralJournal_Accounts_Residuals_InvOrExp", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // InvOrExp accounts selection
	// ------------------------------------------------------
	// Dimensions
	|	Accounts.InvOrExpAccount              AS InvOrExpAccount,
	// ------------------------------------------------------
	// Resources
	|	SUM(Accounts.Amount)                  AS Amount
	// ------------------------------------------------------
	|INTO
	|	Table_GeneralJournal_Accounts_Residuals_InvOrExp
	|FROM
	|	Table_GeneralJournal_Accounts_Residuals_InvOrExp_Amount AS Accounts
	|GROUP BY
	|	Accounts.InvOrExpAccount";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_GeneralJournal_Accounts_Services_InvOrExp(TablesList)
	
	// Add GeneralJournal services accounts table to document structure.
	TablesList.Insert("Table_GeneralJournal_Accounts_Services_InvOrExp", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // Services accounts selection
	// ------------------------------------------------------
	// Dimensions
	|	Accounts.ServicesAccount              AS ServicesAccount,
	// ------------------------------------------------------
	// Resources
	|	SUM(Accounts.Amount)                  AS Amount
	// ------------------------------------------------------
	|INTO
	|	Table_GeneralJournal_Accounts_Services_InvOrExp
	|FROM
	|	Table_GeneralJournal_Services AS Accounts
	|GROUP BY
	|	Accounts.ServicesAccount";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_GeneralJournal(TablesList)
	
	// Add GeneralJournal table to document structure.
	TablesList.Insert("Table_GeneralJournal", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // Cr: Inventory (raw materials)
	// ------------------------------------------------------
	// Standard attributes
	|	Assembly.Ref                          AS Recorder,
	|	Assembly.Date                         AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccountingRecordType.Credit)    AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Accounting attributes
	|	InvOrExp.InvOrExpAccount              AS Account,
	|	VALUE(ChartOfCharacteristicTypes.Dimensions.EmptyRef)
	|	                                      AS ExtDimensionType1,
	|	NULL                                  AS ExtDimension1,
	|	VALUE(ChartOfCharacteristicTypes.Dimensions.EmptyRef)
	|	                                      AS ExtDimensionType2,
	|	NULL                                  AS ExtDimension2,
	// ------------------------------------------------------
	// Dimensions
	|	NULL                                  AS Currency,
	// ------------------------------------------------------
	// Resources
	|	NULL                                  AS Amount,
	|	InvOrExp.Amount                       AS AmountRC,
	// ------------------------------------------------------
	// Attributes
	|	NULL                                  AS Memo
	// ------------------------------------------------------
	|FROM
	|	Table_GeneralJournal_Accounts_Materials_InvOrExp AS InvOrExp
	|	LEFT JOIN Document.Assembly AS Assembly
	|		ON True
	|WHERE
	|	Assembly.Ref = &Ref
	|	AND // Amount > 0
	|		InvOrExp.Amount > 0
	|
	|UNION ALL
	|
	|SELECT // Cr: Services
	// ------------------------------------------------------
	// Standard attributes
	|	Assembly.Ref                          AS Recorder,
	|	Assembly.Date                         AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccountingRecordType.Credit)    AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Accounting attributes
	|	InvOrExp.ServicesAccount              AS Account,
	|	VALUE(ChartOfCharacteristicTypes.Dimensions.EmptyRef)
	|	                                      AS ExtDimensionType1,
	|	NULL                                  AS ExtDimension1,
	|	VALUE(ChartOfCharacteristicTypes.Dimensions.EmptyRef)
	|	                                      AS ExtDimensionType2,
	|	NULL                                  AS ExtDimension2,
	// ------------------------------------------------------
	// Dimensions
	|	NULL                                  AS Currency,
	// ------------------------------------------------------
	// Resources
	|	NULL                                  AS Amount,
	|	InvOrExp.Amount                       AS AmountRC,
	// ------------------------------------------------------
	// Attributes
	|	NULL                                  AS Memo
	// ------------------------------------------------------
	|FROM
	|	Table_GeneralJournal_Accounts_Services_InvOrExp AS InvOrExp
	|	LEFT JOIN Document.Assembly AS Assembly
	|		ON True
	|WHERE
	|	Assembly.Ref = &Ref
	|	AND // Amount > 0
	|		InvOrExp.Amount > 0
	|
	|UNION ALL
	|
	|SELECT // Dr: Wastes
	// ------------------------------------------------------
	// Standard attributes
	|	Assembly.Ref                          AS Recorder,
	|	Assembly.Date                         AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccountingRecordType.Debit)     AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Accounting attributes
	|	Assembly.WasteAccount                 AS Account,
	|	VALUE(ChartOfCharacteristicTypes.Dimensions.EmptyRef)
	|	                                      AS ExtDimensionType1,
	|	NULL                                  AS ExtDimension1,
	|	VALUE(ChartOfCharacteristicTypes.Dimensions.EmptyRef)
	|	                                      AS ExtDimensionType2,
	|	NULL                                  AS ExtDimension2,
	// ------------------------------------------------------
	// Dimensions
	|	NULL                                  AS Currency,
	// ------------------------------------------------------
	// Resources
	|	NULL                                  AS Amount,
	|	Totals.WasteCost                      AS AmountRC,
	// ------------------------------------------------------
	// Attributes
	|	NULL                                  AS Memo
	// ------------------------------------------------------
	|FROM
	|	Document.Assembly AS Assembly
	|	LEFT JOIN Table_InventoryJournal_DocumentTotal AS Totals
	|		ON True
	|WHERE
	|	Assembly.Ref = &Ref
	|	AND // Amount > 0
	|		Totals.WasteCost > 0
	|
	|UNION ALL
	|
	|SELECT // Dr: Assembly
	// ------------------------------------------------------
	// Standard attributes
	|	Assembly.Ref                          AS Recorder,
	|	Assembly.Date                         AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccountingRecordType.Debit)     AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Accounting attributes
	|	Assembly.Product.InventoryOrExpenseAccount AS Account,
	|	VALUE(ChartOfCharacteristicTypes.Dimensions.EmptyRef)
	|	                                      AS ExtDimensionType1,
	|	NULL                                  AS ExtDimension1,
	|	VALUE(ChartOfCharacteristicTypes.Dimensions.EmptyRef)
	|	                                      AS ExtDimensionType2,
	|	NULL                                  AS ExtDimension2,
	// ------------------------------------------------------
	// Dimensions
	|	NULL                                  AS Currency,
	// ------------------------------------------------------
	// Resources
	|	NULL                                  AS Amount,
	|	Totals.AssemblyCost                   AS AmountRC,
	// ------------------------------------------------------
	// Attributes
	|	NULL                                  AS Memo
	// ------------------------------------------------------
	|FROM
	|	Document.Assembly AS Assembly
	|	LEFT JOIN Table_InventoryJournal_DocumentTotal AS Totals
	|		ON True
	|WHERE
	|	Assembly.Ref = &Ref
	|	AND // Amount > 0
	|		Totals.AssemblyCost > 0
	|
	|UNION ALL
	|
	|SELECT // Dr: Residuals
	// ------------------------------------------------------
	// Standard attributes
	|	Assembly.Ref                          AS Recorder,
	|	Assembly.Date                         AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccountingRecordType.Debit)     AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Accounting attributes
	|	InvOrExp.InvOrExpAccount              AS Account,
	|	VALUE(ChartOfCharacteristicTypes.Dimensions.EmptyRef)
	|	                                      AS ExtDimensionType1,
	|	NULL                                  AS ExtDimension1,
	|	VALUE(ChartOfCharacteristicTypes.Dimensions.EmptyRef)
	|	                                      AS ExtDimensionType2,
	|	NULL                                  AS ExtDimension2,
	// ------------------------------------------------------
	// Dimensions
	|	NULL                                  AS Currency,
	// ------------------------------------------------------
	// Resources
	|	NULL                                  AS Amount,
	|	InvOrExp.Amount                       AS AmountRC,
	// ------------------------------------------------------
	// Attributes
	|	NULL                                  AS Memo
	// ------------------------------------------------------
	|FROM
	|	Table_GeneralJournal_Accounts_Residuals_InvOrExp AS InvOrExp
	|	LEFT JOIN Document.Assembly AS Assembly
	|		ON True
	|WHERE
	|	Assembly.Ref = &Ref
	|	AND // Amount > 0
	|		InvOrExp.Amount > 0";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

//--//GJ++

// Query for document data.
Function Query_GeneralJournalAnalyticsDimensions_Accounts_Materials_InvOrExp_Quantity(TablesList)
	
	// Add GeneralJournalAnalyticsDimensions InvOrExp accounts table to document structure.
	TablesList.Insert("Table_GeneralJournalAnalyticsDimensions_Accounts_Materials_InvOrExp_Quantity", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // InvOrExp accounts selection
	// ------------------------------------------------------
	// Dimensions
	|	Accounts.InvOrExpAccount              AS InvOrExpAccount,
	|	Accounts.Product                      AS Product,
	|	Accounts.Class                        AS Class,
	|	Accounts.Project                      AS Project,
	|	Accounts.Location                     AS Location,
	|	Accounts.Type                         AS Type,
	// ------------------------------------------------------
	// Resources
	|	SUM(Accounts.Quantity)                AS Quantity
	// ------------------------------------------------------
	|INTO
	|	Table_GeneralJournalAnalyticsDimensions_Accounts_Materials_InvOrExp_Quantity
	|FROM
	|	Table_GeneralJournal_Materials AS Accounts
	|GROUP BY
	|	Accounts.InvOrExpAccount,
	|	Accounts.Product,
	|	Accounts.Class,
	|	Accounts.Project,
	|	Accounts.Location,
	|	Accounts.Type";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_GeneralJournalAnalyticsDimensions_Accounts_Materials_InvOrExp_Amount(TablesList)
	
	// Add GeneralJournalAnalyticsDimensions InvOrExp accounts table to document structure.
	TablesList.Insert("Table_GeneralJournalAnalyticsDimensions_Accounts_Materials_InvOrExp_Amount", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // FIFO
	// ------------------------------------------------------
	// Dimensions
	|	Accounts.InvOrExpAccount              AS InvOrExpAccount,
	|	Accounts.Class                        AS Class,
	|	Accounts.Project                      AS Project,
	// ------------------------------------------------------
	// Resources
	|	CASE
	|		WHEN ISNULL(ProductCost.Quantity, 0) <= Accounts.Quantity
	|		// The product written off completely.
	|		THEN ISNULL(ProductCost.Amount, 0)
	|		// The product written off partially.
	|		ELSE CAST ( // Format(Amount / QuantityExpense / Quantity, ""ND=17; NFD=2"")
	|			ProductCost.Amount * Accounts.Quantity / ProductCost.Quantity
	|			AS NUMBER (17, 2))
	|	END                                   AS Amount
	// ------------------------------------------------------
	|INTO
	|	Table_GeneralJournalAnalyticsDimensions_Accounts_Materials_InvOrExp_Amount
	|FROM
	|	Table_GeneralJournalAnalyticsDimensions_Accounts_Materials_InvOrExp_Quantity AS Accounts
	|	LEFT JOIN Table_InventoryJournal_MaterialCost_Total AS ProductCost
	|		ON  ProductCost.Product  = Accounts.Product
	|		AND ProductCost.Location = Accounts.Location
	|WHERE
	|	Accounts.Type = VALUE(Enum.InventoryCosting.FIFO)
	|
	|UNION ALL
	|
	|SELECT // WeightedAverage
	// ------------------------------------------------------
	// Dimensions
	|	Accounts.InvOrExpAccount              AS InvOrExpAccount,
	|	Accounts.Class                        AS Class,
	|	Accounts.Project                      AS Project,
	// ------------------------------------------------------
	// Resources
	|	CASE
	|		WHEN ISNULL(ProductCost.Quantity, 0) <= Accounts.Quantity
	|		// The product written off completely.
	|		THEN ISNULL(ProductCost.Amount, 0)
	|		// The product written off partially.
	|		ELSE CAST ( // Format(Amount / QuantityExpense / Quantity, ""ND=17; NFD=2"")
	|			ProductCost.Amount * Accounts.Quantity / ProductCost.Quantity
	|			AS NUMBER (17, 2))
	|	END                                   AS Amount
	// ------------------------------------------------------
	|FROM
	|	Table_GeneralJournalAnalyticsDimensions_Accounts_Materials_InvOrExp_Quantity AS Accounts
	|	LEFT JOIN Table_InventoryJournal_MaterialCost_Total AS ProductCost
	|		ON  ProductCost.Product  = Accounts.Product
	|		AND ProductCost.Location = VALUE(Catalog.Locations.EmptyRef)
	|WHERE
	|	Accounts.Type = VALUE(Enum.InventoryCosting.WeightedAverage)";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_GeneralJournalAnalyticsDimensions_Accounts_Materials_InvOrExp(TablesList)
	
	// Add GeneralJournalAnalyticsDimensions InvOrExp accounts table to document structure.
	TablesList.Insert("Table_GeneralJournalAnalyticsDimensions_Accounts_Materials_InvOrExp", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // InvOrExp accounts selection
	// ------------------------------------------------------
	// Dimensions
	|	Accounts.InvOrExpAccount              AS InvOrExpAccount,
	|	Accounts.Class                        AS Class,
	|	Accounts.Project                      AS Project,
	// ------------------------------------------------------
	// Resources
	|	SUM(Accounts.Amount)                  AS Amount
	// ------------------------------------------------------
	|INTO
	|	Table_GeneralJournalAnalyticsDimensions_Accounts_Materials_InvOrExp
	|FROM
	|	Table_GeneralJournalAnalyticsDimensions_Accounts_Materials_InvOrExp_Amount AS Accounts
	|GROUP BY
	|	Accounts.InvOrExpAccount,
	|	Accounts.Class,
	|	Accounts.Project";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_GeneralJournalAnalyticsDimensions_Accounts_Materials_InvOrExp_Difference_Amount(TablesList)
	
	// Add GeneralJournalAnalyticsDimensions difference InvOrExp amount table to document structure.
	TablesList.Insert("Table_GeneralJournalAnalyticsDimensions_Accounts_Materials_InvOrExp_Difference_Amount", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // Inventory (raw materials) accounts selection
	// ------------------------------------------------------
	// Dimensions
	|	InvOrExp_Dimensions.InvOrExpAccount             AS InvOrExpAccount,	
	// ------------------------------------------------------
	// Resources
	|	InvOrExp_Dimensions.Amount                      AS Amount
	// ------------------------------------------------------
	|INTO
	|	Table_GeneralJournalAnalyticsDimensions_Accounts_Materials_InvOrExp_Difference_Amount
	|FROM
	|	Table_GeneralJournal_Accounts_Materials_InvOrExp AS InvOrExp_Dimensions
	|	LEFT JOIN Document.Assembly AS Assembly
	|		ON True
	|WHERE
	|	Assembly.Ref = &Ref
	|	AND // Amount > 0
	|		InvOrExp_Dimensions.Amount > 0
	|
	|UNION ALL
	|
	|SELECT // Inventory (raw materials) Dimensions accounts selection
	// ------------------------------------------------------
	// Dimensions
	|	InvOrExp_Dimensions.InvOrExpAccount             AS InvOrExpAccount,	
	// ------------------------------------------------------
	// Resources
	|	InvOrExp_Dimensions.Amount  * -1                AS Amount
	// ------------------------------------------------------
	|FROM
	|	Table_GeneralJournalAnalyticsDimensions_Accounts_Materials_InvOrExp AS InvOrExp_Dimensions
	|	LEFT JOIN Document.Assembly AS Assembly
	|		ON True
	|WHERE
	|	Assembly.Ref = &Ref
	|	AND // Amount > 0
	|		InvOrExp_Dimensions.Amount > 0";	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_GeneralJournalAnalyticsDimensions_Accounts_Materials_InvOrExp_Difference(TablesList)
	
	// Add GeneralJournalAnalyticsDimensions difference InvOrExp table to document structure.
	TablesList.Insert("Table_GeneralJournalAnalyticsDimensions_Accounts_Materials_InvOrExp_Difference", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // Dimensions difference selection
	// ------------------------------------------------------
	// Dimensions
	|	DimensionsDifference.InvOrExpAccount       AS InvOrExpAccount,	
	// ------------------------------------------------------
	// Resources
	|	SUM(DimensionsDifference.Amount)           AS Amount
	// ------------------------------------------------------
	|INTO
	|	Table_GeneralJournalAnalyticsDimensions_Accounts_Materials_InvOrExp_Difference
	|FROM
	|	Table_GeneralJournalAnalyticsDimensions_Accounts_Materials_InvOrExp_Difference_Amount AS DimensionsDifference
	|GROUP BY
	|	DimensionsDifference.InvOrExpAccount";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_GeneralJournalAnalyticsDimensions_Accounts_Services_InvOrExp(TablesList)
	
	// Add GeneralJournalAnalyticsDimensions services accounts table to document structure.
	TablesList.Insert("Table_GeneralJournalAnalyticsDimensions_Accounts_Services_InvOrExp", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // Services accounts selection
	// ------------------------------------------------------
	// Dimensions
	|	Accounts.ServicesAccount              AS ServicesAccount,
	|	Accounts.Class                        AS Class,
	|	Accounts.Project                      AS Project,
	// ------------------------------------------------------
	// Resources
	|	SUM(Accounts.Amount)                  AS Amount
	// ------------------------------------------------------
	|INTO
	|	Table_GeneralJournalAnalyticsDimensions_Accounts_Services_InvOrExp
	|FROM
	|	Table_GeneralJournal_Services AS Accounts
	|GROUP BY
	|	Accounts.ServicesAccount,
	|	Accounts.Class,
	|	Accounts.Project";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_GeneralJournalAnalyticsDimensions_Accounts_Services_InvOrExp_Difference_Amount(TablesList)
	
	// Add GeneralJournalAnalyticsDimensions difference InvOrExp amount table to document structure.
	TablesList.Insert("Table_GeneralJournalAnalyticsDimensions_Accounts_Services_InvOrExp_Difference_Amount", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // Services accounts selection
	// ------------------------------------------------------
	// Dimensions
	|	InvOrExp_Dimensions.ServicesAccount             AS ServicesAccount,
	// ------------------------------------------------------
	// Resources
	|	InvOrExp_Dimensions.Amount                      AS Amount
	// ------------------------------------------------------
	|INTO
	|	Table_GeneralJournalAnalyticsDimensions_Accounts_Services_InvOrExp_Difference_Amount
	|FROM
	|	Table_GeneralJournal_Accounts_Services_InvOrExp AS InvOrExp_Dimensions
	|	LEFT JOIN Document.Assembly AS Assembly
	|		ON True
	|WHERE
	|	Assembly.Ref = &Ref
	|	AND // Amount > 0
	|		InvOrExp_Dimensions.Amount > 0
	|
	|UNION ALL
	|
	|SELECT // Services Dimensions accounts selection
	// ------------------------------------------------------
	// Dimensions
	|	InvOrExp_Dimensions.ServicesAccount             AS ServicesAccount,
	// ------------------------------------------------------
	// Resources
	|	InvOrExp_Dimensions.Amount  * -1                AS Amount
	// ------------------------------------------------------
	|FROM
	|	Table_GeneralJournalAnalyticsDimensions_Accounts_Services_InvOrExp AS InvOrExp_Dimensions
	|	LEFT JOIN Document.Assembly AS Assembly
	|		ON True
	|WHERE
	|	Assembly.Ref = &Ref
	|	AND // Amount > 0
	|		InvOrExp_Dimensions.Amount > 0";	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_GeneralJournalAnalyticsDimensions_Accounts_Services_InvOrExp_Difference(TablesList)
	
	// Add GeneralJournalAnalyticsDimensions difference InvOrExp table to document structure.
	TablesList.Insert("Table_GeneralJournalAnalyticsDimensions_Accounts_Services_InvOrExp_Difference", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // Dimensions difference selection
	// ------------------------------------------------------
	// Dimensions
	|	DimensionsDifference.ServicesAccount       AS ServicesAccount,
	// ------------------------------------------------------
	// Resources
	|	SUM(DimensionsDifference.Amount)           AS Amount
	// ------------------------------------------------------
	|INTO
	|	Table_GeneralJournalAnalyticsDimensions_Accounts_Services_InvOrExp_Difference
	|FROM
	|	Table_GeneralJournalAnalyticsDimensions_Accounts_Services_InvOrExp_Difference_Amount AS DimensionsDifference
	|GROUP BY
	|	DimensionsDifference.ServicesAccount";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_GeneralJournalAnalyticsDimensions_Transactions(TablesList)
	
	// Add GeneralJournalAnalyticsDimensions_Transactions table to document structure.
	TablesList.Insert("Table_GeneralJournalAnalyticsDimensions_Transactions", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // Expense: Inventory (raw materials)
	// ------------------------------------------------------
	// Standard attributes
	|	Assembly.Ref                          AS Recorder,
	|	Assembly.Date                         AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Accounting attributes
	|	InvOrExp.InvOrExpAccount              AS Account,
	// ------------------------------------------------------
	// Dimensions
	|	NULL                                  AS Company,
	|	InvOrExp.Class                        AS Class,
	|	InvOrExp.Project                      AS Project,
	// ------------------------------------------------------
	// Resources
	|	InvOrExp.Amount                       AS AmountRC
	// ------------------------------------------------------
	|INTO Table_GeneralJournalAnalyticsDimensions_Transactions
	|FROM
	|	Table_GeneralJournalAnalyticsDimensions_Accounts_Materials_InvOrExp AS InvOrExp
	|	LEFT JOIN Document.Assembly AS Assembly
	|		ON True
	|WHERE
	|	Assembly.Ref = &Ref
	|	AND // Amount > 0
	|		InvOrExp.Amount > 0
	|
	|UNION ALL
	|
	|SELECT // Expense: Inventory (raw materials) (difference)
	// ------------------------------------------------------
	// Standard attributes
	|	Assembly.Ref                          AS Recorder,
	|	Assembly.Date                         AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Accounting attributes
	|	InvOrExp.InvOrExpAccount              AS Account,
	// ------------------------------------------------------
	// Dimensions
	|	NULL                                  AS Company,
	|	NULL                                  AS Class,
	|	NULL                                  AS Project,
	// ------------------------------------------------------
	// Resources
	|	InvOrExp.Amount                       AS AmountRC
	// ------------------------------------------------------
	|FROM
	|	Table_GeneralJournalAnalyticsDimensions_Accounts_Materials_InvOrExp_Difference AS InvOrExp
	|	LEFT JOIN Document.Assembly AS Assembly
	|		ON True
	|WHERE
	|	Assembly.Ref = &Ref
	|	AND // Amount <> 0
	|		InvOrExp.Amount <> 0
	|
	|UNION ALL
	|
	|SELECT // Expense: Services
	// ------------------------------------------------------
	// Standard attributes
	|	Assembly.Ref                          AS Recorder,
	|	Assembly.Date                         AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Accounting attributes
	|	InvOrExp.ServicesAccount              AS Account,
	// ------------------------------------------------------
	// Dimensions
	|	NULL                                  AS Company,
	|	InvOrExp.Class                        AS Class,
	|	InvOrExp.Project                      AS Project,
	// ------------------------------------------------------
	// Resources
	|	InvOrExp.Amount                       AS AmountRC
	// ------------------------------------------------------
	|FROM
	|	Table_GeneralJournalAnalyticsDimensions_Accounts_Services_InvOrExp AS InvOrExp
	|	LEFT JOIN Document.Assembly AS Assembly
	|		ON True
	|WHERE
	|	Assembly.Ref = &Ref
	|	AND // Amount > 0
	|		InvOrExp.Amount > 0
	|UNION ALL
	|
	|SELECT // Expense: Services (difference)
	// ------------------------------------------------------
	// Standard attributes
	|	Assembly.Ref                          AS Recorder,
	|	Assembly.Date                         AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Accounting attributes
	|	InvOrExp.ServicesAccount              AS Account,
	// ------------------------------------------------------
	// Dimensions
	|	NULL                                  AS Company,
	|	NULL                                  AS Class,
	|	NULL                                  AS Project,
	// ------------------------------------------------------
	// Resources
	|	InvOrExp.Amount                       AS AmountRC
	// ------------------------------------------------------
	|FROM
	|	Table_GeneralJournalAnalyticsDimensions_Accounts_Services_InvOrExp_Difference AS InvOrExp
	|	LEFT JOIN Document.Assembly AS Assembly
	|		ON True
	|WHERE
	|	Assembly.Ref = &Ref
	|	AND // Amount <> 0
	|		InvOrExp.Amount <> 0
	|
	|UNION ALL
	|
	|SELECT // Receipt: Wastes
	// ------------------------------------------------------
	// Standard attributes
	|	Assembly.Ref                          AS Recorder,
	|	Assembly.Date                         AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Accounting attributes
	|	Assembly.WasteAccount                 AS Account,
	// ------------------------------------------------------
	// Dimensions
	|	NULL                                  AS Company,
	|	NULL                                  AS Class,
	|	NULL                                  AS Project,
	// ------------------------------------------------------
	// Resources
	|	Totals.WasteCost                      AS AmountRC
	// ------------------------------------------------------
	|FROM
	|	Document.Assembly AS Assembly
	|	LEFT JOIN Table_InventoryJournal_DocumentTotal AS Totals
	|		ON True
	|WHERE
	|	Assembly.Ref = &Ref
	|	AND // Amount > 0
	|		Totals.WasteCost > 0
	|
	|UNION ALL
	|
	|SELECT // Receipt: Assembly
	// ------------------------------------------------------
	// Standard attributes
	|	Assembly.Ref                          AS Recorder,
	|	Assembly.Date                         AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Accounting attributes
	|	Assembly.Product.InventoryOrExpenseAccount
	|                                         AS Account,
	// ------------------------------------------------------
	// Dimensions
	|	NULL                                  AS Company,
	|	Assembly.Class                        AS Class,
	|	Assembly.Project                      AS Project,
	// ------------------------------------------------------
	// Resources
	|	Totals.AssemblyCost                   AS AmountRC
	// ------------------------------------------------------
	|FROM
	|	Document.Assembly AS Assembly
	|	LEFT JOIN Table_InventoryJournal_DocumentTotal AS Totals
	|		ON True
	|WHERE
	|	Assembly.Ref = &Ref
	|	AND // Amount > 0
	|		Totals.AssemblyCost > 0
	|
	|UNION ALL
	|
	|SELECT // Receipt: Residuals
	// ------------------------------------------------------
	// Standard attributes
	|	Assembly.Ref                          AS Recorder,
	|	Assembly.Date                         AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Accounting attributes
	|	InvOrExp.InvOrExpAccount              AS Account,
	// ------------------------------------------------------
	// Dimensions
	|	NULL                                  AS Company,
	|	Assembly.Class                        AS Class,
	|	Assembly.Project                      AS Project,
	// ------------------------------------------------------
	// Resources
	|	InvOrExp.Amount                       AS AmountRC
	// ------------------------------------------------------
	|FROM
	|	Table_GeneralJournal_Accounts_Residuals_InvOrExp AS InvOrExp
	|	LEFT JOIN Document.Assembly AS Assembly
	|		ON True
	|WHERE
	|	Assembly.Ref = &Ref
	|	AND // Amount > 0
	|		InvOrExp.Amount > 0";
	
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
	|	Assembly.Ref                          AS Document,
	|	NULL                                  AS SalesPerson,
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
	|	LEFT JOIN Document.Assembly AS Assembly
	|		ON Assembly.Ref = &Ref";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction


// Query for document data.
Function Query_ProjectData_Accounts_Wastes_Quantity(TablesList)
	
	// Add ProjectData wastes accounts table to document structure.
	TablesList.Insert("Table_ProjectData_Accounts_Wastes_Quantity", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // Wastes accounts selection
	// ------------------------------------------------------
	// Dimensions
	|	Accounts.WasteAccount                 AS WasteAccount,
	|	Accounts.Project                      AS Project,
	|	Accounts.Product                      AS Product,
	|	Accounts.Location                     AS Location,
	|	Accounts.Type                         AS Type,
	// ------------------------------------------------------
	// Resources
	|	SUM(Accounts.Quantity)                AS Quantity
	// ------------------------------------------------------
	|INTO
	|	Table_ProjectData_Accounts_Wastes_Quantity
	|FROM
	|	Table_GeneralJournal_Wastes AS Accounts
	|GROUP BY
	|	Accounts.WasteAccount,
	|	Accounts.Project,
	|	Accounts.Product,
	|	Accounts.Location,
	|	Accounts.Type";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_ProjectData_Accounts_Wastes_Amount(TablesList)
	
	// Add ProjectData wastes accounts table to document structure.
	TablesList.Insert("Table_ProjectData_Accounts_Wastes_Amount", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // FIFO
	// ------------------------------------------------------
	// Dimensions
	|	Accounts.WasteAccount                 AS WasteAccount,
	|	Accounts.Project                      AS Project,
	// ------------------------------------------------------
	// Resources
	|	CASE
	|		WHEN ISNULL(ProductCost.Quantity, 0) <= Accounts.Quantity
	|		// The product written off completely.
	|		THEN ISNULL(ProductCost.Amount, 0)
	|		// The product written off partially.
	|		ELSE CAST ( // Format(Amount / QuantityExpense / Quantity, ""ND=17; NFD=2"")
	|			ProductCost.Amount * Accounts.Quantity / ProductCost.Quantity
	|			AS NUMBER (17, 2))
	|	END                                   AS Amount
	// ------------------------------------------------------
	|INTO
	|	Table_ProjectData_Accounts_Wastes_Amount
	|FROM
	|	Table_ProjectData_Accounts_Wastes_Quantity AS Accounts
	|	LEFT JOIN Table_InventoryJournal_WasteCost_Total AS ProductCost
	|		ON  ProductCost.Product  = Accounts.Product
	|		AND ProductCost.Location = Accounts.Location
	|WHERE
	|	Accounts.Type = VALUE(Enum.InventoryCosting.FIFO)
	|
	|UNION ALL
	|
	|SELECT // WeightedAverage
	// ------------------------------------------------------
	// Dimensions
	|	Accounts.WasteAccount                 AS WasteAccount,
	|	Accounts.Project                      AS Project,
	// ------------------------------------------------------
	// Resources
	|	CASE
	|		WHEN ISNULL(ProductCost.Quantity, 0) <= Accounts.Quantity
	|		// The product written off completely.
	|		THEN ISNULL(ProductCost.Amount, 0)
	|		// The product written off partially.
	|		ELSE CAST ( // Format(Amount / QuantityExpense / Quantity, ""ND=17; NFD=2"")
	|			ProductCost.Amount * Accounts.Quantity / ProductCost.Quantity
	|			AS NUMBER (17, 2))
	|	END                                   AS Amount
	// ------------------------------------------------------
	|FROM
	|	Table_ProjectData_Accounts_Wastes_Quantity AS Accounts
	|	LEFT JOIN Table_InventoryJournal_WasteCost_Total AS ProductCost
	|		ON  ProductCost.Product  = Accounts.Product
	|		AND ProductCost.Location = VALUE(Catalog.Locations.EmptyRef)
	|WHERE
	|	Accounts.Type = VALUE(Enum.InventoryCosting.WeightedAverage)";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_ProjectData_Accounts_Wastes(TablesList)
	
	// Add ProjectData wastes accounts table to document structure.
	TablesList.Insert("Table_ProjectData_Accounts_Wastes", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // Wastes accounts selection
	// ------------------------------------------------------
	// Dimensions
	|	Accounts.WasteAccount                 AS WasteAccount,
	|	Accounts.Project                      AS Project,
	// ------------------------------------------------------
	// Resources
	|	SUM(Accounts.Amount)                  AS Amount
	// ------------------------------------------------------
	|INTO
	|	Table_ProjectData_Accounts_Wastes
	|FROM
	|	Table_ProjectData_Accounts_Wastes_Amount AS Accounts
	|GROUP BY
	|	Accounts.WasteAccount,
	|	Accounts.Project";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_ProjectData_Accounts_Services(TablesList)
	
	// Add ProjectData services accounts table to document structure.
	TablesList.Insert("Table_ProjectData_Accounts_Services", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // Services accounts selection
	// ------------------------------------------------------
	// Dimensions
	|	Accounts.ServicesAccount              AS ServicesAccount,
	|	Accounts.Project                      AS Project,
	// ------------------------------------------------------
	// Resources
	|	SUM(Accounts.Amount)                  AS Amount
	// ------------------------------------------------------
	|INTO
	|	Table_ProjectData_Accounts_Services
	|FROM
	|	Table_GeneralJournal_Services AS Accounts
	|GROUP BY
	|	Accounts.ServicesAccount,
	|	Accounts.Project";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_ProjectData(TablesList)
	
	// Add ProjectData table to document structure.
	TablesList.Insert("Table_ProjectData", TablesList.Count());
	
	// Collect project data.
	QueryText =
	"SELECT // Exp: Wastes
	// ------------------------------------------------------
	// Standard attributes
	|	Assembly.Ref                          AS Recorder,
	|	Assembly.Date                         AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Dimensions
	|	Wastes.WasteAccount                   AS Account,
	|	Wastes.Project                        AS Project,
	// ------------------------------------------------------
	// Resources
	|	Wastes.Amount                         AS Amount
	// ------------------------------------------------------
	// Attributes
	// ------------------------------------------------------
	|FROM
	|	Table_ProjectData_Accounts_Wastes AS Wastes
	|	LEFT JOIN Document.Assembly AS Assembly
	|		ON True
	|WHERE
	|	Assembly.Ref = &Ref
	|	AND // Amount > 0
	|		Wastes.Amount > 0
	|
	|UNION ALL
	|
	|SELECT // Exp: Services
	// ------------------------------------------------------
	// Standard attributes
	|	Assembly.Ref                          AS Recorder,
	|	Assembly.Date                         AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Dimensions
	|	ServicesPrj.ServicesAccount           AS Account,
	|	ServicesPrj.Project                   AS Project,
	// ------------------------------------------------------
	// Resources
	|	ServicesPrj.Amount                    AS Amount
	// ------------------------------------------------------
	// Attributes
	// ------------------------------------------------------
	|FROM
	|	Table_ProjectData_Accounts_Services AS ServicesPrj
	|	LEFT JOIN Document.Assembly AS Assembly
	|		ON True
	|WHERE
	|	Assembly.Ref = &Ref
	|	AND // Amount > 0
	|		ServicesPrj.Amount > 0";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_ClassData_Accounts_Wastes_Quantity(TablesList)
	
	// Add ClassData wastes accounts table to document structure.
	TablesList.Insert("Table_ClassData_Accounts_Wastes_Quantity", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // Wastes accounts selection
	// ------------------------------------------------------
	// Dimensions
	|	Accounts.WasteAccount                 AS WasteAccount,
	|	Accounts.Class                        AS Class,
	|	Accounts.Product                      AS Product,
	|	Accounts.Location                     AS Location,
	|	Accounts.Type                         AS Type,
	// ------------------------------------------------------
	// Resources
	|	SUM(Accounts.Quantity)                AS Quantity
	// ------------------------------------------------------
	|INTO
	|	Table_ClassData_Accounts_Wastes_Quantity
	|FROM
	|	Table_GeneralJournal_Wastes AS Accounts
	|GROUP BY
	|	Accounts.WasteAccount,
	|	Accounts.Class,
	|	Accounts.Product,
	|	Accounts.Location,
	|	Accounts.Type";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_ClassData_Accounts_Wastes_Amount(TablesList)
	
	// Add ClassData wastes accounts table to document structure.
	TablesList.Insert("Table_ClassData_Accounts_Wastes_Amount", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // FIFO
	// ------------------------------------------------------
	// Dimensions
	|	Accounts.WasteAccount                 AS WasteAccount,
	|	Accounts.Class                        AS Class,
	// ------------------------------------------------------
	// Resources
	|	CASE
	|		WHEN ISNULL(ProductCost.Quantity, 0) <= Accounts.Quantity
	|		// The product written off completely.
	|		THEN ISNULL(ProductCost.Amount, 0)
	|		// The product written off partially.
	|		ELSE CAST ( // Format(Amount / QuantityExpense / Quantity, ""ND=17; NFD=2"")
	|			ProductCost.Amount * Accounts.Quantity / ProductCost.Quantity
	|			AS NUMBER (17, 2))
	|	END                                   AS Amount
	// ------------------------------------------------------
	|INTO
	|	Table_ClassData_Accounts_Wastes_Amount
	|FROM
	|	Table_ClassData_Accounts_Wastes_Quantity AS Accounts
	|	LEFT JOIN Table_InventoryJournal_WasteCost_Total AS ProductCost
	|		ON  ProductCost.Product  = Accounts.Product
	|		AND ProductCost.Location = Accounts.Location
	|WHERE
	|	Accounts.Type = VALUE(Enum.InventoryCosting.FIFO)
	|
	|UNION ALL
	|
	|SELECT // WeightedAverage
	// ------------------------------------------------------
	// Dimensions
	|	Accounts.WasteAccount                 AS WasteAccount,
	|	Accounts.Class                        AS Class,
	// ------------------------------------------------------
	// Resources
	|	CASE
	|		WHEN ISNULL(ProductCost.Quantity, 0) <= Accounts.Quantity
	|		// The product written off completely.
	|		THEN ISNULL(ProductCost.Amount, 0)
	|		// The product written off partially.
	|		ELSE CAST ( // Format(Amount / QuantityExpense / Quantity, ""ND=17; NFD=2"")
	|			ProductCost.Amount * Accounts.Quantity / ProductCost.Quantity
	|			AS NUMBER (17, 2))
	|	END                                   AS Amount
	// ------------------------------------------------------
	|FROM
	|	Table_ClassData_Accounts_Wastes_Quantity AS Accounts
	|	LEFT JOIN Table_InventoryJournal_WasteCost_Total AS ProductCost
	|		ON  ProductCost.Product  = Accounts.Product
	|		AND ProductCost.Location = VALUE(Catalog.Locations.EmptyRef)
	|WHERE
	|	Accounts.Type = VALUE(Enum.InventoryCosting.WeightedAverage)";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_ClassData_Accounts_Wastes(TablesList)
	
	// Add ClassData wastes accounts table to document structure.
	TablesList.Insert("Table_ClassData_Accounts_Wastes", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // Wastes accounts selection
	// ------------------------------------------------------
	// Dimensions
	|	Accounts.WasteAccount                 AS WasteAccount,
	|	Accounts.Class                        AS Class,
	// ------------------------------------------------------
	// Resources
	|	SUM(Accounts.Amount)                  AS Amount
	// ------------------------------------------------------
	|INTO
	|	Table_ClassData_Accounts_Wastes
	|FROM
	|	Table_ClassData_Accounts_Wastes_Amount AS Accounts
	|GROUP BY
	|	Accounts.WasteAccount,
	|	Accounts.Class";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_ClassData_Accounts_Services(TablesList)
	
	// Add ClassData services accounts table to document structure.
	TablesList.Insert("Table_ClassData_Accounts_Services", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // Services accounts selection
	// ------------------------------------------------------
	// Dimensions
	|	Accounts.ServicesAccount              AS ServicesAccount,
	|	Accounts.Class                        AS Class,
	// ------------------------------------------------------
	// Resources
	|	SUM(Accounts.Amount)                  AS Amount
	// ------------------------------------------------------
	|INTO
	|	Table_ClassData_Accounts_Services
	|FROM
	|	Table_GeneralJournal_Services AS Accounts
	|GROUP BY
	|	Accounts.ServicesAccount,
	|	Accounts.Class";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_ClassData(TablesList)
	
	// Add ClassData table to document structure.
	TablesList.Insert("Table_ClassData", TablesList.Count());
	
	// Collect class data.
	QueryText =
	"SELECT // Exp: Wastes
	// ------------------------------------------------------
	// Standard attributes
	|	Assembly.Ref                          AS Recorder,
	|	Assembly.Date                         AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Dimensions
	|	Wastes.WasteAccount                   AS Account,
	|	Wastes.Class                          AS Class,
	// ------------------------------------------------------
	// Resources
	|	Wastes.Amount                         AS Amount
	// ------------------------------------------------------
	// Attributes
	// ------------------------------------------------------
	|FROM
	|	Table_ClassData_Accounts_Wastes AS Wastes
	|	LEFT JOIN Document.Assembly AS Assembly
	|		ON True
	|WHERE
	|	Assembly.Ref = &Ref
	|	AND // Amount > 0
	|		Wastes.Amount > 0
	|
	|UNION ALL
	|
	|SELECT // Exp: Services
	// ------------------------------------------------------
	// Standard attributes
	|	Assembly.Ref                          AS Recorder,
	|	Assembly.Date                         AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Dimensions
	|	ServicesCls.ServicesAccount           AS Account,
	|	ServicesCls.Class                     AS Class,
	// ------------------------------------------------------
	// Resources
	|	ServicesCls.Amount                    AS Amount
	// ------------------------------------------------------
	// Attributes
	// ------------------------------------------------------
	|FROM
	|	Table_ClassData_Accounts_Services AS ServicesCls
	|	LEFT JOIN Document.Assembly AS Assembly
	|		ON True
	|WHERE
	|	Assembly.Ref = &Ref
	|	AND // Amount > 0
	|		ServicesCls.Amount > 0";
	
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
		
		// Add resources for check register balances.
		CheckBalances = New Array;
		CheckBalances.Add("{Table}.Quantity{Balance}, <, 0");  // Check negative inventory balance.
		
		// Add messages for different error situations.
		CheckMessages = New Array;
		CheckMessages.Add(NStr("en = '{Product}?{Layer}:
		                             |There is an insufficient balance of {-Quantity} at the {Location}.|Layer = "" of {Layer}""'"));
		
		// Add register to check it's recordset changes and balances during posting.
		BalanceCheck.Insert("InventoryJournal", New Structure("CheckPostings, CheckBalances, CheckMessages", CheckPostings, CheckBalances, CheckMessages));
		
	ElsIf AdditionalProperties.Posting.WriteMode = DocumentWriteMode.UndoPosting Then
		
		// Add resources for check changes in recordset.
		CheckPostings = New Array;
		CheckPostings.Add("{Table}.Quantity{Posting}, <, 0"); // Check decreasing quantity.
		
		// Add resources for check register balances.
		CheckBalances = New Array;
		CheckBalances.Add("{Table}.Quantity{Balance}, <, 0"); // Check negative inventory balance.
		
		// Add messages for different error situations.
		CheckMessages = New Array;
		CheckMessages.Add(NStr("en = '{Product}?{Layer}:
		                             |There is an insufficient balance of {-Quantity} at the {Location}.|Layer = "" of {Layer}""'"));
		
		// Add registers to check it's recordset changes and balances during undo posting.
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