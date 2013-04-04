
////////////////////////////////////////////////////////////////////////////////
// Sales Invoice: Manager module
//------------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
// DOCUMENT POSTING

// Pre-check, lock, calculate data before write document
Function PrepareDataBeforeWrite(AdditionalProperties, DocumentParameters, Cancel) Export
	
	// 0.1. Access data without rights checking
	SetPrivilegedMode(True);
	
	// 0.2. Create list of query tables (according to the list of requested balances)
	PreCheck     = New Structure;
	LocksList    = New Structure;
	BalancesList = New Structure;
	
	
	// 1.1. Create a query to request data
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	
	// 1.2. Put supplied DocumentParameters in query parameters and temporary tables
	For Each Parameter In DocumentParameters Do
		If TypeOf(Parameter.Value) = Type("ValueTable") Then
			DocumentPosting.PutTemporaryTable(Parameter.Value, "Table_"+Parameter.Key, Query.TempTablesManager);
		ElsIf TypeOf(Parameter.Value) = Type("PointInTime") Then
			Query.SetParameter(Parameter.Key, New Boundary(Parameter.Value, BoundaryType.Excluding));
		Else
			Query.SetParameter(Parameter.Key, Parameter.Value);
		EndIf;
	EndDo;
	
	
	// 2.1. Request data for lock in register before accessing balances
	Query.Text = "";
	If AdditionalProperties.Orders.Count() > 0 Then
		Query.Text = Query.Text + Query_OrdersRegistered_Lock(LocksList);
	EndIf;
	
	// 2.2. Proceed with locking the data
	If Not IsBlankString(Query.Text) Then
		QueryResult = Query.ExecuteBatch();
		For Each LockTable In LocksList Do
			DocumentPosting.LockDataSourceBeforeWrite(StrReplace(LockTable.Key, "_", "."), QueryResult[LockTable.Value], DataLockMode.Exclusive);
		EndDo;
	EndIf;
		
	
	// 3.1. Query for order balances excluding document data (if it already affected to)
	Query.Text = "";
	If AdditionalProperties.Orders.Count() > 0 Then
		Query.Text = Query.Text + Query_OrdersRegistered_Balance(BalancesList);
	EndIf;
	
	// 3.2. Save balances in posting parameters
	If Not IsBlankString(Query.Text) Then
		QueryResult = Query.ExecuteBatch();
		For Each BalanceTable In BalancesList Do
			PreCheck.Insert(BalanceTable.Key, QueryResult[BalanceTable.Value].Unload());
		EndDo;
	EndIf;
	
	// 3.3. Put structure of prechecked registers in additional properties
	If PreCheck.Count() > 0 Then
		AdditionalProperties.Posting.Insert("PreCheck", PreCheck);
	EndIf;
	
EndFunction

// Collect document data for posting on the server (in terms of document)
Function PrepareDataStructuresForPosting(DocumentRef, AdditionalProperties, RegisterRecords) Export
	Var PreCheck;
	
	// Create list of posting tables (according to the list of registers)
	TablesList = New Structure;
	
	// Create a query to request document data
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	
	// Query for document's tables
	Query.Text   = "";
	If AdditionalProperties.Orders.Count() > 0 Then
		Query.Text = Query.Text +
		             Query_OrdersStatuses(TablesList) +
	                 Query_OrdersRegistered(TablesList);
	EndIf;
				  
	// Execute query, fill temporary tables with postings data
	If Not IsBlankString(Query.Text) Then
		// Fill data from precheck
		If AdditionalProperties.Posting.Property("PreCheck", PreCheck) And PreCheck.Count() > 0 Then
			For Each PreCheckTable In PreCheck Do
				DocumentPosting.PutTemporaryTable(PreCheckTable.Value, PreCheckTable.Key, Query.TempTablesManager);
			EndDo;
		EndIf;
		
		// Execute query
		QueryResult = Query.ExecuteBatch();
		
		// Save documents table in posting parameters
		For Each DocumentTable In TablesList Do
			AdditionalProperties.Posting.PostingTables.Insert(DocumentTable.Key, QueryResult[DocumentTable.Value].Unload());
		EndDo;
		
		// Custom update after filling of all tables
		CheckCloseParentOrders(DocumentRef, AdditionalProperties, Query.TempTablesManager);
	EndIf;
	
	// Fill list of registers to check (non-negative) balances in posting parameters
	FillRegistersCheckList(AdditionalProperties, RegisterRecords);
	
EndFunction

// Collect document data for posting on the server (in terms of document)
Function PrepareDataStructuresForPostingClearing(DocumentRef, AdditionalProperties, RegisterRecords) Export
	
	// Fill list of registers to check (non-negative) balances in posting parameters
	FillRegistersCheckList(AdditionalProperties, RegisterRecords);
	
EndFunction

// Query for document data
Function Query_OrdersStatuses(TablesList)

	// Add OrdersStatuses table to document structure
	TablesList.Insert("Table_OrdersStatuses", TablesList.Count());
	
	// Collect orders statuses data
	QueryText =
	"SELECT DISTINCT
	// ------------------------------------------------------
	// Standard Attributes
	|	LineItems.Ref                         AS Recorder,
	|	LineItems.Ref.Date                    AS Period,
	|	1                                     AS LineNumber,
	|	True								  AS Active,
	// ------------------------------------------------------
	// Dimensions
	|	LineItems.Order                       AS Order,
	// ------------------------------------------------------
	// Resources
	|	VALUE(Enum.OrderStatuses.Backordered) AS Status
	// ------------------------------------------------------
	// Attributes
	// ------------------------------------------------------
	|FROM
	|	Document.SalesInvoice.LineItems AS LineItems
	|WHERE
	|	LineItems.Ref = &Ref
	|   AND LineItems.Order <> VALUE(Document.SalesOrder.EmptyRef)
	|ORDER BY
	|	LineItems.Order.Date";

	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data
Function Query_OrdersRegistered(TablesList)

	// Add OrdersRegistered table to document structure
	TablesList.Insert("Table_OrdersRegistered", TablesList.Count());
	
	// Collect orders registered data
	QueryText =
	"SELECT
	// ------------------------------------------------------
	// Standard Attributes
	|	LineItems.Ref                         AS Recorder,
	|	LineItems.Ref.Date                    AS Period,
	|	LineItems.LineNumber                  AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	True								  AS Active,
	// ------------------------------------------------------
	// Dimensions
	|	LineItems.Ref.Company                 AS Company,
	|	LineItems.Order                       AS Order,
	|	LineItems.Product                     AS Product,
	// ------------------------------------------------------
	// Resources
	|	0                                     AS Quantity,
	|	CASE WHEN LineItems.Product.Type = VALUE(Enum.InventoryTypes.Inventory)
	|	     THEN CASE WHEN LineItems.Quantity - 
	|	                    CASE WHEN OrdersRegisteredBalance.Shipped - OrdersRegisteredBalance.Invoiced > 0
	|	                         THEN OrdersRegisteredBalance.Shipped - OrdersRegisteredBalance.Invoiced
	|	                         ELSE 0 END > 0
	|	               THEN LineItems.Quantity - 
	|	                    CASE WHEN OrdersRegisteredBalance.Shipped - OrdersRegisteredBalance.Invoiced > 0
	|	                         THEN OrdersRegisteredBalance.Shipped - OrdersRegisteredBalance.Invoiced
	|	                         ELSE 0 END
	|	               ELSE 0 END
	|	     ELSE 0 END                       AS Shipped,
	|	LineItems.Quantity                    AS Invoiced,
	// ------------------------------------------------------
	// Attributes
	|	LineItems.Ref.DeliveryDate            AS DeliveryDate
	// ------------------------------------------------------
	|FROM
	|	Document.SalesInvoice.LineItems AS LineItems
	|	LEFT JOIN Table_OrdersRegistered_Balance AS OrdersRegisteredBalance
	|		ON  OrdersRegisteredBalance.Company = LineItems.Ref.Company
	|		AND OrdersRegisteredBalance.Order   = LineItems.Order
	|		AND OrdersRegisteredBalance.Product = LineItems.Product
	|WHERE
	|	LineItems.Ref = &Ref
	|   AND LineItems.Order <> VALUE(Document.SalesOrder.EmptyRef)
	|ORDER BY
	|	LineNumber";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for dimensions lock data
Function Query_OrdersRegistered_Lock(TablesList)
	
	// Add OrdersRegistered - Lock table to locks structure
	TablesList.Insert("AccumulationRegister_OrdersRegistered", TablesList.Count());
	
	// Collect dimensions for orders registered locking
	QueryText = 
	"SELECT DISTINCT
	// ------------------------------------------------------
	// Dimensions
	|	&Company                              AS Company,
	|	LineItems.Order                       AS Order,
	|	LineItems.Product                     AS Product
	// ------------------------------------------------------
	|FROM
	|	Table_LineItems AS LineItems
	|WHERE
	|   LineItems.Order <> VALUE(Document.SalesOrder.EmptyRef)";

	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for balances data
Function Query_OrdersRegistered_Balance(TablesList)
	
	// Add OrdersRegistered - Balances table to balances structure
	TablesList.Insert("Table_OrdersRegistered_Balance", TablesList.Count());
	
	// Collect orders registered balances
	QueryText =
	"SELECT
	// ------------------------------------------------------
	// Dimensions
	|	OrdersRegisteredBalance.Company          AS Company,
	|	OrdersRegisteredBalance.Order            AS Order,
	|	OrdersRegisteredBalance.Product          AS Product,
	// ------------------------------------------------------
	// Resources
	|	OrdersRegisteredBalance.QuantityBalance  AS Quantity,
	|	OrdersRegisteredBalance.ShippedBalance   AS Shipped,
	|	OrdersRegisteredBalance.InvoicedBalance  AS Invoiced
	// ------------------------------------------------------
	|FROM
	|	AccumulationRegister.OrdersRegistered.Balance(&PointInTime,
	|		(Company, Order) IN
	|			(SELECT
	|				&Company,
	|				LineItems.Order
	|			FROM
	|				Table_LineItems AS LineItems)) AS OrdersRegisteredBalance";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Put structure of registers, which balance should be checked during posting
Procedure FillRegistersCheckList(AdditionalProperties, RegisterRecords)

	// Create structure of registers and its resources to check balances
	BalanceCheck = New Structure;
		
	// Fill structure depending on document write mode
	If AdditionalProperties.Posting.WriteMode = DocumentWriteMode.Posting Then
		
		// No checks performed while posting
	ElsIf AdditionalProperties.Posting.WriteMode = DocumentWriteMode.UndoPosting Then
		
		// No checks performed while unposting
	EndIf;

	// Return structure of registers to check
	If BalanceCheck.Count() > 0 Then
		AdditionalProperties.Posting.Insert("BalanceCheck", BalanceCheck);
	EndIf;
	
EndProcedure

// Custom check for closing of parent orders
// Procedure uses custom data of document to check orders closing
// This prevents from requesting already acquired data
Procedure CheckCloseParentOrders(DocumentRef, AdditionalProperties, TempTablesManager)
	Var Table_OrdersStatuses;
	
	// Skip check if order absent
	If AdditionalProperties.Orders.Count() = 0 Then
		Return;
	EndIf;
	
	// Create new query
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	
	// Empty query text and tables
	QueryText   = "";
	QueryTables = -1;
	
	// Put temporary table for calculating of final status
	// Table_OrdersRegistered_Balance already placed in TempTablesManager 
	DocumentPosting.PutTemporaryTable(AdditionalProperties.Posting.PostingTables.Table_OrdersRegistered, "Table_OrdersRegistered", Query.TempTablesManager);
	
	// Create query for calculate order status
	QueryText = QueryText +
	// Combine balance with document postings
	"SELECT
	// ------------------------------------------------------
	// Dimensions
	|	OrdersRegisteredBalance.Company          AS Company,
	|	OrdersRegisteredBalance.Order            AS Order,
	|	OrdersRegisteredBalance.Product          AS Product,
	// ------------------------------------------------------
	// Resources
	|	OrdersRegisteredBalance.Quantity         AS Quantity,
	|	OrdersRegisteredBalance.Shipped          AS Shipped,
	|	OrdersRegisteredBalance.Invoiced         AS Invoiced
	// ------------------------------------------------------
	|INTO
	|	OrdersRegistered_Balance_And_Postings
	|FROM
	|	Table_OrdersRegistered_Balance AS OrdersRegisteredBalance
	|   // (Company, Order) IN (SELECT Company, Order FROM Table_LineItems)
	|
	|UNION ALL
	|
	|SELECT
	// ------------------------------------------------------
	// Dimensions
	|	OrdersRegistered.Company,
	|	OrdersRegistered.Order,
	|	OrdersRegistered.Product,
	// ------------------------------------------------------
	// Resources
	|	OrdersRegistered.Quantity,
	|	OrdersRegistered.Shipped,
	|	OrdersRegistered.Invoiced
	// ------------------------------------------------------
	|FROM
	|	Table_OrdersRegistered AS OrdersRegistered
	|   // Table_LineItems WHERE LineItems.Ref = &Ref AND Order <> EmptyRef()
	|";
	QueryText   = QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	QueryTables = QueryTables + 1;
	
	// Calculate final balance after posting the invoice
	QueryText = QueryText +
	"SELECT
	// ------------------------------------------------------
	// Dimensions
	|	OrdersRegisteredBalance.Company          AS Company,
	|	OrdersRegisteredBalance.Order            AS Order,
	|	OrdersRegisteredBalance.Product          AS Product,
	|	OrdersRegisteredBalance.Product.Type     AS Type,
	// ------------------------------------------------------
	// Resources
	|	SUM(OrdersRegisteredBalance.Quantity)    AS Quantity,
	|	SUM(OrdersRegisteredBalance.Shipped)     AS Shipped,
	|	SUM(OrdersRegisteredBalance.Invoiced)    AS Invoiced
	// ------------------------------------------------------
	|INTO
	|	OrdersRegistered_Balance_AfterWrite
	|FROM
	|	OrdersRegistered_Balance_And_Postings AS OrdersRegisteredBalance
	|GROUP BY
	|	OrdersRegisteredBalance.Company,
	|	OrdersRegisteredBalance.Order,
	|	OrdersRegisteredBalance.Product,
	|	OrdersRegisteredBalance.Product.Type";
	QueryText   = QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	QueryTables = QueryTables + 1;
	
	// Calculate unshipped and uninvoiced items
	QueryText = QueryText +
	"SELECT
	// ------------------------------------------------------
	// Dimensions
	|	OrdersRegisteredBalance.Company          AS Company,
	|	OrdersRegisteredBalance.Order            AS Order,
	|	OrdersRegisteredBalance.Product          AS Product,
	// ------------------------------------------------------
	// Resources
	|   CASE WHEN OrdersRegisteredBalance.Type = VALUE(Enum.InventoryTypes.Inventory)
	|	     THEN OrdersRegisteredBalance.Quantity - OrdersRegisteredBalance.Shipped
	|	     ELSE 0 END                          AS UnShipped,
	|   CASE WHEN OrdersRegisteredBalance.Type = VALUE(Enum.InventoryTypes.Inventory)
	|	     THEN OrdersRegisteredBalance.Shipped  - OrdersRegisteredBalance.Invoiced
	|        WHEN OrdersRegisteredBalance.Type = VALUE(Enum.InventoryTypes.NonInventory)
	|	     THEN OrdersRegisteredBalance.Quantity - OrdersRegisteredBalance.Invoiced
	|	     ELSE 0 END                          AS UnInvoiced
	// ------------------------------------------------------
	|INTO
	|	OrdersRegistered_Balance_Unclosed
	|FROM
	|	OrdersRegistered_Balance_AfterWrite AS OrdersRegisteredBalance
	|WHERE
	|   CASE WHEN OrdersRegisteredBalance.Type = VALUE(Enum.InventoryTypes.Inventory)
	|	     THEN OrdersRegisteredBalance.Quantity - OrdersRegisteredBalance.Shipped
	|	     ELSE 0 END > 0
	|OR CASE WHEN OrdersRegisteredBalance.Type = VALUE(Enum.InventoryTypes.Inventory)
	|	     THEN OrdersRegisteredBalance.Shipped  - OrdersRegisteredBalance.Invoiced
	|        WHEN OrdersRegisteredBalance.Type = VALUE(Enum.InventoryTypes.NonInventory)
	|	     THEN OrdersRegisteredBalance.Quantity - OrdersRegisteredBalance.Invoiced
	|	     ELSE 0 END > 0";
	QueryText   = QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	QueryTables = QueryTables + 1;
	
	// Determine orders having unclosed items in balance
	QueryText = QueryText +
	"SELECT
	// ------------------------------------------------------
	// Dimensions
	|	OrdersRegisteredBalance.Order            AS Order,
	|	SUM(OrdersRegisteredBalance.UnShipped
	|     + OrdersRegisteredBalance.UnInvoiced)  AS Unclosed
	// ------------------------------------------------------
	|INTO
	|	OrdersRegistered_Balance_Orders_Unclosed
	|FROM
	|	OrdersRegistered_Balance_Unclosed AS OrdersRegisteredBalance
	|GROUP BY
	|	OrdersRegisteredBalance.Order";
	QueryText   = QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	QueryTables = QueryTables + 1;
	
	// Calculate closed orders (those in invoice, which don't have unclosed items in theirs balance)
	QueryText = QueryText +
	"SELECT DISTINCT
	|	OrdersRegistered.Order AS Order
	|FROM
	|	Table_OrdersRegistered AS OrdersRegistered
	|   // Table_LineItems WHERE LineItems.Ref = &Ref AND Order <> EmptyRef()
	|	LEFT JOIN OrdersRegistered_Balance_Orders_Unclosed AS OrdersRegisteredBalanceUnclosed
	|		  ON  OrdersRegisteredBalanceUnclosed.Order = OrdersRegistered.Order
	|WHERE
	|	// No unclosed items
	|	ISNULL(OrdersRegisteredBalanceUnclosed.Unclosed, 0) = 0";
	QueryText   = QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	QueryTables = QueryTables + 1;
	
	// Clear orders registered postings table
	QueryText   = QueryText + 
	"DROP Table_OrdersRegistered";
	QueryText   = QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
	// Clear balance with document postings table
	QueryText   = QueryText + 
	"DROP OrdersRegistered_Balance_And_Postings";
	QueryText   = QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
	// Clear final balance after posting the invoice table
	QueryText   = QueryText + 
	"DROP OrdersRegistered_Balance_AfterWrite";
	QueryText   = QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
		
	// Clear unshipped and uninvoiced items table
	QueryText   = QueryText + 
	"DROP OrdersRegistered_Balance_Unclosed";
	QueryText   = QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
	// Clear orders having unclosed items in balance table
	QueryText   = QueryText + 
	"DROP OrdersRegistered_Balance_Orders_Unclosed";
	QueryText   = QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
	// Execute query
	Query.Text  = QueryText;
	QueryResult = Query.ExecuteBatch();
	
	// Check status of final query
	If Not QueryResult[QueryTables].IsEmpty()
	// Update OrderStatus in prefilled table of postings
	And AdditionalProperties.Posting.PostingTables.Property("Table_OrdersStatuses", Table_OrdersStatuses) Then
		
	    // Update closed orders
		Selection = QueryResult[QueryTables].Choose();
		While Selection.Next() Do
			
			// Set OrderStatus -> Closed
			Row = Table_OrdersStatuses.Find(Selection.Order, "Order");
			If Not Row = Undefined Then
				Row.Status = Enums.OrderStatuses.Closed;
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure
	
////////////////////////////////////////////////////////////////////////////////
// DOCUMENT FILLING

// Collect source data for filling document on the server (in terms of document)
Function PrepareDataStructuresForFilling(DocumentRef, AdditionalProperties) Export
	
	// Create list of posting tables (according to the list of registers)
	TablesList = New Structure;
	
	// Create a query to request document data
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref",  DocumentRef);
	Query.SetParameter("Date", AdditionalProperties.Date);
	
	// Query for document's tables
	Query.Text   = "";
	For Each FillingData In AdditionalProperties.Filling.FillingData Do
		
		// Construct query by passed sources
		If FillingData.Key = "Document_SalesOrder" Then
			Query.Text = Query.Text +
	                     Query_Filling_Document_SalesOrder_Attributes(TablesList) +
                         Query_Filling_Document_SalesOrder_OrdersStatuses(TablesList) +
                         Query_Filling_Document_SalesOrder_OrdersRegistered(TablesList) +
                         Query_Filling_Document_SalesOrder_LineItems(TablesList) +
                         Query_Filling_Document_SalesOrder_Totals(TablesList);
			
		Else // Next filling source
		EndIf;
		
		Query.SetParameter("FillingData_" + FillingData.Key, FillingData.Value);
	EndDo;
	
	// Add combining query
	Query.Text = Query.Text +
                 Query_Filling_Attributes(TablesList) +
                 Query_Filling_LineItems(TablesList);
				 
	// Add check query
	Query.Text = Query.Text +
                 Query_Filling_Check(TablesList, FillingCheckList(AdditionalProperties));
	
	// Execute query, fill temporary tables with filling data
	If TablesList.Count() > 3 Then
		
		// Execute query
		QueryResult = Query.ExecuteBatch();
		
		AdditionalProperties.Filling.FillingTables.Insert("Table_Attributes", DocumentPosting.GetTemporaryTable(Query.TempTablesManager, "Table_Attributes"));
		For Each TabularSection In AdditionalProperties.Metadata.TabularSections Do
			If TablesList.Property("Table_"+TabularSection.Name) Then
				AdditionalProperties.Filling.FillingTables.Insert("Table_"+TabularSection.Name, DocumentPosting.GetTemporaryTable(Query.TempTablesManager, "Table_"+TabularSection.Name));
			EndIf;
		EndDo;	
		AdditionalProperties.Filling.FillingTables.Insert("Table_Check", DocumentPosting.GetTemporaryTable(Query.TempTablesManager, "Table_Check"));
	EndIf;
	
EndFunction

// Query for document filling
Function Query_Filling_Document_SalesOrder_Attributes(TablesList)

	// Add Attributes table to document structure
	TablesList.Insert("Table_Document_SalesOrder_Attributes", TablesList.Count());
	
	// Collect attributes data
	QueryText =
		"SELECT
		|	SalesOrder.Ref                          AS FillingData,
		|	SalesOrder.Company                      AS Company,
		|	SalesOrder.CompanyCode                  AS CompanyCode,
		|	SalesOrder.Currency                     AS Currency,
		|	SalesOrder.ExchangeRate                 AS ExchangeRate,
		|	SalesOrder.Location                     AS Location,
		|	&Date                                   AS DeliveryDate,
		|	CASE
		|		WHEN SalesOrder.Company.Terms.Days IS NULL THEN DATEADD(&Date, DAY, 14)
		|		WHEN SalesOrder.Company.Terms.Days = 0     THEN DATEADD(&Date, DAY, 14)
		|		ELSE                                            DATEADD(&Date, DAY, SalesOrder.Company.Terms.Days)
		|	END                                     AS DueDate,
		|	ISNULL(SalesOrder.Company.Terms, VALUE(Catalog.PaymentTerms.EmptyRef))
		|	                                        AS Terms,
		|	ISNULL(SalesOrder.Currency.DefaultARAccount, VALUE(ChartOfAccounts.ChartOfAccounts.EmptyRef))
		|	                                        AS ARAccount,
		|	SalesOrder.PriceIncludesVAT             AS PriceIncludesVAT,
		|	SalesOrder.ShipTo                       AS ShipTo
		|INTO
		|	Table_Document_SalesOrder_Attributes
		|FROM
		|	Document.SalesOrder AS SalesOrder
		|WHERE
		|	SalesOrder.Ref IN (&FillingData_Document_SalesOrder)";

	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document filling
Function Query_Filling_Document_SalesOrder_OrdersStatuses(TablesList)

	// Add OrdersStatuses table to document structure
	TablesList.Insert("Table_Document_SalesOrder_OrdersStatuses", TablesList.Count());
	
	// Collect orders statuses data
	QueryText =
		"SELECT
		// ------------------------------------------------------
		// Dimensions
		|	SalesOrder.Ref                          AS Order,
		// ------------------------------------------------------
		// Resources
		|	CASE
		|		WHEN SalesOrder.DeletionMark THEN
		|			 VALUE(Enum.OrderStatuses.Deleted)
		|		WHEN NOT SalesOrder.Posted THEN
		|			 VALUE(Enum.OrderStatuses.Draft)
		|		WHEN OrdersStatuses.Status IS NULL THEN
		|			 VALUE(Enum.OrderStatuses.Open)
		|		WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.EmptyRef) THEN
		|			 VALUE(Enum.OrderStatuses.Open)
		|		ELSE
		|			 OrdersStatuses.Status
		|	END                                     AS Status
		// ------------------------------------------------------
		|INTO
		|	Table_Document_SalesOrder_OrdersStatuses
		|FROM
		|	Document.SalesOrder AS SalesOrder
		|		LEFT JOIN InformationRegister.OrdersStatuses.SliceLast AS OrdersStatuses
		|		ON SalesOrder.Ref = OrdersStatuses.Order
		|WHERE
		|	SalesOrder.Ref IN (&FillingData_Document_SalesOrder)";

	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document filling
Function Query_Filling_Document_SalesOrder_OrdersRegistered(TablesList)

	// Add OrdersRegistered table to document structure
	TablesList.Insert("Table_Document_SalesOrder_OrdersRegistered", TablesList.Count());
	
	// Collect orders items data
	QueryText =
		"SELECT
		// ------------------------------------------------------
		// Dimensions
		|	OrdersRegisteredBalance.Company          AS Company,
		|	OrdersRegisteredBalance.Order            AS Order,
		|	OrdersRegisteredBalance.Product          AS Product,
		// ------------------------------------------------------
		// Resources                                                                                                        // ---------------------------------------
		|	OrdersRegisteredBalance.QuantityBalance  AS Quantity,                                                           // Backorder quantity calculation
		|	CASE                                                                                                            // ---------------------------------------
		|		WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Open)        THEN 0                                   // Order status = Open:
		|		WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Backordered) THEN                                     //   Backorder = 0
		|			CASE                                                                                                    // Order status = Backorder:
		|				WHEN OrdersRegisteredBalance.Product.Type = VALUE(Enum.InventoryTypes.Inventory) THEN               //   Inventory:
		|					CASE                                                                                            //     Backorder = Ordered - Shipped >= 0
		|						WHEN OrdersRegisteredBalance.QuantityBalance > OrdersRegisteredBalance.ShippedBalance THEN  //     |
		|							 OrdersRegisteredBalance.QuantityBalance - OrdersRegisteredBalance.ShippedBalance       //     |
		|						ELSE 0 END                                                                                  //     |
		|				WHEN OrdersRegisteredBalance.Product.Type = VALUE(Enum.InventoryTypes.NonInventory) THEN            //   Non-inventory:
		|					CASE                                                                                            //     Backorder = Ordered - Invoiced >= 0
		|						WHEN OrdersRegisteredBalance.QuantityBalance > OrdersRegisteredBalance.InvoicedBalance THEN //     |
		|							 OrdersRegisteredBalance.QuantityBalance - OrdersRegisteredBalance.InvoicedBalance      //     |
		|						ELSE 0 END                                                                                  //     |
		|				ELSE 0                                                                                              //   NULL or something else:
		|               END                                                                                                 //     0
		|		WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Closed)      THEN 0                                   // Order status = Closed:
		|		ELSE 0                                                                                                      //   Backorder = 0
		|		END                                  AS Backorder
		// ------------------------------------------------------
		|INTO
		|	Table_Document_SalesOrder_OrdersRegistered
		|FROM
		|	AccumulationRegister.OrdersRegistered.Balance(,
		|		(Company, Order, Product) IN
		|			(SELECT
		|				SalesOrderLineItems.Ref.Company,
		|				SalesOrderLineItems.Ref,
		|				SalesOrderLineItems.Product
		|			FROM
		|				Document.SalesOrder.LineItems AS SalesOrderLineItems
		|			WHERE
		|				SalesOrderLineItems.Ref IN (&FillingData_Document_SalesOrder))) AS OrdersRegisteredBalance
		|	LEFT JOIN Table_Document_SalesOrder_OrdersStatuses AS OrdersStatuses
		|		ON OrdersRegisteredBalance.Order = OrdersStatuses.Order";

	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document filling
Function Query_Filling_Document_SalesOrder_LineItems(TablesList)

	// Add LineItems table to document structure
	TablesList.Insert("Table_Document_SalesOrder_LineItems", TablesList.Count());
	
	// Collect line items data
	QueryText =
		"SELECT
		|	SalesOrderLineItems.Ref                 AS FillingData,
		|	SalesOrderLineItems.Product             AS Product,
		|	SalesOrderLineItems.ProductDescription  AS ProductDescription,
		|	SalesOrderLineItems.Price               AS Price,
		|	CASE
		|		WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Open)
		|			THEN ISNULL(OrdersRegistered.Quantity, SalesOrderLineItems.Quantity)
		|		WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Backordered)
		|			THEN ISNULL(OrdersRegistered.Backorder, SalesOrderLineItems.Quantity)
		|		WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Closed)
		|			THEN ISNULL(OrdersRegistered.Backorder, 0)
		|		ELSE 0
		|	END                                     AS Quantity,
		|	CAST( // Format(Quantity * Price, ""ND=15; NFD=2"")
		|		CASE
		|			WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Open)
		|				THEN ISNULL(OrdersRegistered.Quantity, SalesOrderLineItems.Quantity)
		|			WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Backordered)
		|				THEN ISNULL(OrdersRegistered.Backorder, SalesOrderLineItems.Quantity)
		|			WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Closed)
		|				THEN ISNULL(OrdersRegistered.Backorder, 0)
		|			ELSE 0
		|		END * SalesOrderLineItems.Price 
		|		AS NUMBER (15, 2))                  AS LineTotal,
		|	SalesOrderLineItems.SalesTaxType        AS SalesTaxType,
		|	CASE
		|		WHEN SalesOrderLineItems.SalesTaxType = VALUE(Enum.SalesTaxTypes.Taxable)
		|			THEN // TaxableAmount = LineTotal
		|				CAST( // Format(Quantity * Price, ""ND=15; NFD=2"")
		|					CASE
		|						WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Open)
		|							THEN ISNULL(OrdersRegistered.Quantity, SalesOrderLineItems.Quantity)
		|						WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Backordered)
		|							THEN ISNULL(OrdersRegistered.Backorder, SalesOrderLineItems.Quantity)
		|						WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Closed)
		|							THEN ISNULL(OrdersRegistered.Backorder, 0)
		|						ELSE 0
		|					END * SalesOrderLineItems.Price 
		|				AS NUMBER (15, 2))
		|		ELSE 0
		|	END                                     AS TaxableAmount,
		|	SalesOrderLineItems.VATCode             AS VATCode,
		|	CAST( // Format(LineTotal * VATRate / 100, ""ND=15; NFD=2"")
		|		CAST( // Format(Quantity * Price, ""ND=15; NFD=2"")
		|			CASE
		|				WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Open)
		|					THEN ISNULL(OrdersRegistered.Quantity, SalesOrderLineItems.Quantity)
		|				WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Backordered)
		|					THEN ISNULL(OrdersRegistered.Backorder, SalesOrderLineItems.Quantity)
		|				WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Closed)
		|					THEN ISNULL(OrdersRegistered.Backorder, 0)
		|				ELSE 0
		|			END * SalesOrderLineItems.Price
		|		AS NUMBER (15, 2)) *
		|		CASE // VATRate = ?(Ref.PriceIncludesVAT, VATCode.SalesInclRate, VATCode.SalesExclRate)
		|			WHEN SalesOrderLineItems.Ref.PriceIncludesVAT IS NULL THEN 0
		|			WHEN SalesOrderLineItems.Ref.PriceIncludesVAT         THEN ISNULL(SalesOrderLineItems.VATCode.SalesInclRate, 0)
		|			ELSE                                                       ISNULL(SalesOrderLineItems.VATCode.SalesExclRate, 0)
		|		END /
		|		100
		|	AS NUMBER (15, 2))                      AS VAT,
		|	SalesOrderLineItems.Ref                 AS Order,
		|	SalesOrderLineItems.Ref.Company         AS Company
		|INTO
		|	Table_Document_SalesOrder_LineItems
		|FROM
		|	Document.SalesOrder.LineItems AS SalesOrderLineItems
		|	LEFT JOIN Table_Document_SalesOrder_OrdersRegistered AS OrdersRegistered
		|		ON  OrdersRegistered.Company = SalesOrderLineItems.Ref.Company
		|		AND OrdersRegistered.Order   = SalesOrderLineItems.Ref
		|		AND OrdersRegistered.Product = SalesOrderLineItems.Product
		|	LEFT JOIN Table_Document_SalesOrder_OrdersStatuses AS OrdersStatuses
		|		ON OrdersStatuses.Order = SalesOrderLineItems.Ref
		|WHERE
		|	SalesOrderLineItems.Ref IN (&FillingData_Document_SalesOrder)";
		
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document filling
Function Query_Filling_Document_SalesOrder_Totals(TablesList)

	// Add Totals table to document structure
	TablesList.Insert("Table_Document_SalesOrder_Totals", TablesList.Count());
	
	// Collect totals data
	QueryText =
		"SELECT
		// Totals of document
		|	SalesOrderLineItems.FillingData         AS FillingData,
		|
		|	CAST( // Format(Total(TaxableAmount) * Company.SalesTaxCode.TaxRate / 100, ""ND=15; NFD=2"")
		|		SUM(SalesOrderLineItems.TaxableAmount) *
		|		ISNULL(SalesOrderLineItems.Company.SalesTaxCode.TaxRate, 0) /
		|		100
		|		AS NUMBER (15, 2))                  AS SalesTax,
		|
		|	CAST( // Format(Total(VAT) * ExchangeRate, ""ND=15; NFD=2"")
		|		SUM(SalesOrderLineItems.VAT) *
		|		SalesOrder.ExchangeRate
		|		AS NUMBER (15, 2))                  AS VATTotal,
		|
		|	CASE
		|		WHEN SalesOrder.PriceIncludesVAT THEN // Total(LineTotal) + SalesTax
		|			SUM(SalesOrderLineItems.LineTotal) +
		|			CAST( // Format(Total(TaxableAmount) * TaxRate / 100, ""ND=15; NFD=2"")
		|				SUM(SalesOrderLineItems.TaxableAmount) *
		|				ISNULL(SalesOrderLineItems.Company.SalesTaxCode.TaxRate, 0) /
		|				100
		|				AS NUMBER (15, 2))
		|		ELSE                                  // Total(LineTotal) + SalesTax + Total(VAT)
		|			SUM(SalesOrderLineItems.LineTotal) +
		|			CAST( // Format(Total(TaxableAmount) * Company.SalesTaxCode.TaxRate / 100, ""ND=15; NFD=2"")
		|				SUM(SalesOrderLineItems.TaxableAmount) *
		|				ISNULL(SalesOrderLineItems.Company.SalesTaxCode.TaxRate, 0) /
		|				100
		|				AS NUMBER (15, 2)) +
		|			SUM(SalesOrderLineItems.VAT)
		|	END                                     AS DocumentTotal,
		|
		|	CAST( // Format(DocumentTotal * ExchangeRate, ""ND=15; NFD=2"")
		|		CASE // DocumentTotal
		|			WHEN SalesOrder.PriceIncludesVAT THEN // Total(LineTotal) + SalesTax
		|				SUM(SalesOrderLineItems.LineTotal) +
		|				CAST( // Format(Total(TaxableAmount) * Company.SalesTaxCode.TaxRate / 100, ""ND=15; NFD=2"")
		|					SUM(SalesOrderLineItems.TaxableAmount) *
		|					ISNULL(SalesOrderLineItems.Company.SalesTaxCode.TaxRate, 0) /
		|					100
		|					AS NUMBER (15, 2))
		|			ELSE                                  // Total(LineTotal) + SalesTax + Total(VAT)
		|				SUM(SalesOrderLineItems.LineTotal) +
		|				CAST( // Format(Total(TaxableAmount) * Company.SalesTaxCode.TaxRate / 100, ""ND=15; NFD=2"")
		|					SUM(SalesOrderLineItems.TaxableAmount) *
		|					ISNULL(SalesOrderLineItems.Company.SalesTaxCode.TaxRate, 0) /
		|					100
		|					AS NUMBER (15, 2)) +
		|				SUM(SalesOrderLineItems.VAT)
		|		END *
		|		SalesOrder.ExchangeRate
		|		AS NUMBER (15, 2))                  AS DocumentTotalRC
		|
		|INTO
		|	Table_Document_SalesOrder_Totals
		|FROM
		|	Table_Document_SalesOrder_LineItems AS SalesOrderLineItems
		|	LEFT JOIN Table_Document_SalesOrder_Attributes AS SalesOrder
		|		ON SalesOrder.FillingData = SalesOrderLineItems.FillingData
		|GROUP BY
		|	SalesOrderLineItems.FillingData,
		|	SalesOrderLineItems.Company.SalesTaxCode.TaxRate,
		|	SalesOrder.ExchangeRate,
		|	SalesOrder.PriceIncludesVAT";

	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document filling
Function Query_Filling_Attributes(TablesList)

	// Add Attributes table to document structure
	TablesList.Insert("Table_Attributes", TablesList.Count());
	
	// Fill data from attributes and totals
	QueryText = "";
	If TablesList.Property("Table_Document_SalesOrder_Attributes") Then
		QueryText = QueryText + ?(Not IsBlankString(QueryText), 
		"
		|
		|UNION ALL
		|
		|",
		"");
		
		SelectionText =
		"SELECT
		|	Document_SalesOrder_Attributes.FillingData,
		|	Document_SalesOrder_Attributes.Company,
		|	Document_SalesOrder_Attributes.CompanyCode,
		|	Document_SalesOrder_Totals.SalesTax,
		|	Document_SalesOrder_Totals.DocumentTotal,
		|	Document_SalesOrder_Attributes.Currency,
		|	Document_SalesOrder_Attributes.ExchangeRate,
		|	Document_SalesOrder_Totals.DocumentTotalRC,
		|	Document_SalesOrder_Attributes.Location,
		|	Document_SalesOrder_Attributes.DeliveryDate,
		|	Document_SalesOrder_Attributes.DueDate,
		|	Document_SalesOrder_Attributes.Terms,
		|	Document_SalesOrder_Totals.VATTotal,
		|	Document_SalesOrder_Attributes.ARAccount,
		|	Document_SalesOrder_Attributes.PriceIncludesVAT,
		|	Document_SalesOrder_Attributes.ShipTo
		|{Into}
		|FROM
		|	Table_Document_SalesOrder_Attributes AS Document_SalesOrder_Attributes
		|	LEFT JOIN Table_Document_SalesOrder_Totals AS Document_SalesOrder_Totals
		|		ON Document_SalesOrder_Totals.FillingData = Document_SalesOrder_Attributes.FillingData";
		
		QueryText = QueryText + StrReplace(SelectionText, "{Into}",
		?(IsBlankString(QueryText), 
		"INTO
		|	Table_Attributes",
		""));
	EndIf;
	
	// Fill data from next source
	// --------------------------
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document filling
Function Query_Filling_LineItems(TablesList)

	// Add LineItems table to document structure
	TablesList.Insert("Table_LineItems", TablesList.Count());
	
	// Fill data from attributes and totals
	QueryText = "";
	If TablesList.Property("Table_Document_SalesOrder_LineItems") Then
		QueryText = QueryText + ?(Not IsBlankString(QueryText), 
		"
		|
		|UNION ALL
		|
		|",
		"");
		
		SelectionText =
		"SELECT
		|	Document_SalesOrder_LineItems.FillingData,
		|	Document_SalesOrder_LineItems.Product,
		|	Document_SalesOrder_LineItems.ProductDescription,
		|	Document_SalesOrder_LineItems.Price,
		|	Document_SalesOrder_LineItems.Quantity,
		|	Document_SalesOrder_LineItems.LineTotal,
		|	Document_SalesOrder_LineItems.SalesTaxType,
		|	Document_SalesOrder_LineItems.TaxableAmount,
		|	Document_SalesOrder_LineItems.VATCode,
		|	Document_SalesOrder_LineItems.VAT,
		|	Document_SalesOrder_LineItems.Order
		|{Into}
		|FROM
		|	Table_Document_SalesOrder_LineItems AS Document_SalesOrder_LineItems
		|WHERE
		|	Document_SalesOrder_LineItems.Quantity > 0";
		
		QueryText = QueryText + StrReplace(SelectionText, "{Into}",
		?(IsBlankString(QueryText), 
		"INTO
		|	Table_LineItems",
		""));
	EndIf;
	
	// Fill data from next source
	// --------------------------
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Fill structure of attributes, which should be checked during filling
Function FillingCheckList(AdditionalProperties)

	// Create structure of registers and its resources to check balances
	CheckAttributes = New Structure;
	// Group by attributes to check uniqueness
	CheckAttributes.Insert("Company",          "Check");
	CheckAttributes.Insert("Currency",         "Check");
	CheckAttributes.Insert("ExchangeRate",     "Check");
	CheckAttributes.Insert("Location",         "Check");
	CheckAttributes.Insert("ARAccount",        "Check");
	CheckAttributes.Insert("ShipTo",           "Check");
	CheckAttributes.Insert("PriceIncludesVAT", "Check");
	// Maximal possible values
	CheckAttributes.Insert("DeliveryDate",     "Max");
	CheckAttributes.Insert("DueDate",          "Max");
	// Summarize totals
	CheckAttributes.Insert("SalesTax",         "Sum");
	CheckAttributes.Insert("VATTotal",         "Sum");
	CheckAttributes.Insert("DocumentTotal",    "Sum");
	CheckAttributes.Insert("DocumentTotalRC",  "Sum");
	
	// Save structure of attributes to check
	If CheckAttributes.Count() > 0 Then
		AdditionalProperties.Filling.Insert("CheckAttributes", CheckAttributes);
	EndIf;
	
	// Return saved structure
	Return CheckAttributes;
	
EndFunction

// Query for document filling
Function Query_Filling_Check(TablesList, CheckAttributes)

	// Check attributes to be checked
	If CheckAttributes.Count() = 0 Then
		Return "";
	EndIf;
	
	// Add Attributes table to document structure
	TablesList.Insert("Table_Check", TablesList.Count());
	
	// Fill data from attributes and totals
	QueryText =
	"SELECT
	|	{Selection}
	|INTO
	|	Table_Check
	|FROM
	|	Table_Attributes AS Attributes
	|GROUP BY
	|	{GroupBy}";
	
	SelectionText = ""; GroupByText = "";
	For Each Attribute In CheckAttributes Do
		If Attribute.Value = "Check" Then
			// Attributes - uniqueness check
			DimensionText = StrReplace("Attributes.{Attribute} AS {Attribute}", "{Attribute}", Attribute.Key);
			SelectionText = ?(IsBlankString(SelectionText), DimensionText, SelectionText+",
				|	"+DimensionText);
			// Group by section	
			DimensionText = StrReplace("Attributes.{Attribute}", "{Attribute}", Attribute.Key);
			GroupByText   = ?(IsBlankString(GroupByText), DimensionText, GroupByText+",
				|	"+DimensionText);
		Else
			// Agregate function
			DimensionText = StrReplace(Upper(Attribute.Value)+"(Attributes.{Attribute}) AS {Attribute}", "{Attribute}", Attribute.Key);
			SelectionText = ?(IsBlankString(SelectionText), DimensionText, SelectionText+",
				|	"+DimensionText);
		EndIf;
	EndDo;
	QueryText = StrReplace(QueryText, "{Selection}", SelectionText);
	QueryText = StrReplace(QueryText, "{GroupBy}",   GroupByText);
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Check status of passed sales order by ref
// Returns True if status passed for invoice filling
Function CheckStatusOfSalesOrder(Ref) Export
	
	// Create new query
	Query = New Query;
	Query.SetParameter("Ref", Ref);
	
	QueryText = 
		"SELECT
		|	CASE
		|		WHEN SalesOrder.DeletionMark THEN
		|			 VALUE(Enum.OrderStatuses.Deleted)
		|		WHEN NOT SalesOrder.Posted THEN
		|			 VALUE(Enum.OrderStatuses.Draft)
		|		WHEN OrdersStatuses.Status IS NULL THEN
		|			 VALUE(Enum.OrderStatuses.Open)
		|		WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.EmptyRef) THEN
		|			 VALUE(Enum.OrderStatuses.Open)
		|		ELSE
		|			 OrdersStatuses.Status
		|	END AS Status
		|FROM
		|	Document.SalesOrder AS SalesOrder
		|	LEFT JOIN InformationRegister.OrdersStatuses.SliceLast AS OrdersStatuses
		|		ON SalesOrder.Ref = OrdersStatuses.Order
		|WHERE
		|	SalesOrder.Ref = &Ref";
	Query.Text  = QueryText;
	OrderStatus = Query.Execute().Unload()[0].Status;
	
	StatusOK = (OrderStatus = Enums.OrderStatuses.Open) Or (OrderStatus = Enums.OrderStatuses.Backordered);
	If Not StatusOK Then
		MessageText = NStr("en = 'Failed to generate the invoice on the base of %1 %2.'");
		MessageText = StringFunctionsClientServer.SubstitureParametersInString(MessageText,
																			   Lower(OrderStatus),
																			   Lower(Metadata.FindByType(TypeOf(Ref)).Presentation())); 
		CommonUseClientServer.MessageToUser(MessageText, Ref);
	EndIf;
	Return StatusOK;	
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// DOCUMENT PRINTING (OLD)

Procedure Print(ObjectArray, PrintParameters, PrintFormsCollection,
           PrintObjects, OutputParameters) Export

     // Setting the kit printing option.
     OutputParameters.AvailablePrintingByKits = True;

     // Checking if a spreadsheet document generation needed for the Sales Invoice template.
    If PrintManagement.NeedToPrintTemplate(PrintFormsCollection, "SalesInvoice") Then

         // Generating a spreadsheet document and adding it into the print form collection.
         PrintManagement.OutputSpreadsheetDocumentToCollection(PrintFormsCollection,
             "SalesInvoice", "Sales invoice", PrintTemplate(ObjectArray, PrintObjects));

	EndIf;
		 
EndProcedure

Function PrintTemplate(ObjectArray, PrintObjects)
	
	// Create a spreadsheet document and set print parameters.
   SpreadsheetDocument = New SpreadsheetDocument;
   SpreadsheetDocument.PrintParametersName = "PrintParameters_SalesInvoice";

   // Quering necessary data.
   Query = New Query();
   Query.Text =
   "SELECT
   |	SalesInvoice.Ref,
   |	SalesInvoice.Company,
   |	SalesInvoice.Date,
   |	SalesInvoice.DocumentTotal,
   |	SalesInvoice.SalesTax,
   |	SalesInvoice.Number,
   |    SalesInvoice.ShipTo,
   |	SalesInvoice.Currency,
   | 	SalesInvoice.PriceIncludesVAT,
   |	SalesInvoice.VATTotal,
   |	SalesInvoice.LineItems.(
   |		Product,
   |		Product.UM AS UM,
   |		ProductDescription,
   |		Quantity,
   |		VATCode,
   |		VAT,
   |		Price,
   |		LineTotal
   |	)
   |FROM
   |	Document.SalesInvoice AS SalesInvoice
   |WHERE
   |	SalesInvoice.Ref IN(&ObjectArray)";
   Query.SetParameter("ObjectArray", ObjectArray);
   Selection = Query.Execute().Choose();
   
   	FirstDocument = True;

	Us = Catalogs.Companies.OurCompany;
   
   	While Selection.Next() Do
		
		If Not FirstDocument Then
			// All documents need to be outputted on separate pages.
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		FirstDocument = False;
		// Remember current document output beginning line number.
		BeginningLineNumber = SpreadsheetDocument.TableHeight + 1;

	 
	Template = PrintManagement.GetTemplate("Document.SalesInvoice.PF_MXL_SalesInvoice");
	 
	TemplateArea = Template.GetArea("Header");
	  		
	UsBill = PrintTemplates.ContactInfoDataset(Us, "UsBill", Catalogs.Addresses.EmptyRef());
	ThemShip = PrintTemplates.ContactInfoDataset(Selection.Company, "ThemShip", Selection.ShipTo);
	ThemBill = PrintTemplates.ContactInfoDataset(Selection.Company, "ThemBill", Catalogs.Addresses.EmptyRef());
	
	TemplateArea.Parameters.Fill(UsBill);
	TemplateArea.Parameters.Fill(ThemShip);
	TemplateArea.Parameters.Fill(ThemBill);
	
	 TemplateArea.Parameters.Date = Selection.Date;
	 TemplateArea.Parameters.Number = Selection.Number;
	 
	 SpreadsheetDocument.Put(TemplateArea);

	 TemplateArea = Template.GetArea("LineItemsHeader");
	 SpreadsheetDocument.Put(TemplateArea);
	 
	 SelectionLineItems = Selection.LineItems.Choose();
	 TemplateArea = Template.GetArea("LineItems");
	 LineTotalSum = 0;
	 While SelectionLineItems.Next() Do
		 
		 TemplateArea.Parameters.Fill(SelectionLineItems);
		 LineTotal = SelectionLineItems.LineTotal;
		 LineTotalSum = LineTotalSum + LineTotal;
		 SpreadsheetDocument.Put(TemplateArea, SelectionLineItems.Level());
		 
	 EndDo;
	 	 
	If Selection.VATTotal <> 0 Then;
		 TemplateArea = Template.GetArea("Subtotal");
		 TemplateArea.Parameters.Subtotal = LineTotalSum;
		 SpreadsheetDocument.Put(TemplateArea);
		 
		 TemplateArea = Template.GetArea("VAT");
		 TemplateArea.Parameters.VATTotal = Selection.VATTotal;
		 SpreadsheetDocument.Put(TemplateArea);
	EndIf; 
		 
	 TemplateArea = Template.GetArea("Total");
	If Selection.PriceIncludesVAT Then
	 	TemplateArea.Parameters.DocumentTotal = LineTotalSum;
	Else
		TemplateArea.Parameters.DocumentTotal = LineTotalSum + Selection.VATTotal;
	EndIf;
	 SpreadsheetDocument.Put(TemplateArea);

	 TemplateArea = Template.GetArea("Currency");
	 TemplateArea.Parameters.Currency = Selection.Currency;
	 SpreadsheetDocument.Put(TemplateArea);
	 
     // Setting a print area in the spreadsheet document where to output the object.
     // Necessary for kit printing.
     PrintManagement.SetDocumentPrintArea(SpreadsheetDocument, BeginningLineNumber, PrintObjects, Selection.Ref);

   EndDo;
   
   Return SpreadsheetDocument;
   
EndFunction
