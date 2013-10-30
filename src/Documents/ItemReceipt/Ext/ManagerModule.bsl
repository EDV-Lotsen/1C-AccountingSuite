
////////////////////////////////////////////////////////////////////////////////
// Item Receipt: Manager module
//------------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
// DOCUMENT POSTING

// Collect document data for posting on the server (in terms of document)
Function PrepareDataStructuresForPosting(DocumentRef, AdditionalProperties, RegisterRecords) Export
	// Create list of posting tables (according to the list of registers)
	TablesList = New Structure;
	
	// Create a query to request document data
	Query = New Query;
	Query.SetParameter("Ref", DocumentRef);
	
	// Query for document's tables
	Query.Text  = Query_OrdersStatuses(TablesList) +
	              Query_OrdersDispatched(TablesList);
	QueryResult = Query.ExecuteBatch();
	
	// Save documents table in posting parameters
	For Each DocumentTable In TablesList Do
		AdditionalProperties.Posting.PostingTables.Insert(DocumentTable.Key, QueryResult[DocumentTable.Value].Unload());
	EndDo;
	
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
	|	True                                  AS Active,
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
	|	Document.ItemReceipt.LineItems AS LineItems
	|WHERE
	|	LineItems.Ref = &Ref
	|	AND LineItems.Order <> VALUE(Document.PurchaseOrder.EmptyRef)
	|ORDER BY
	|	LineItems.Order.Date";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data
Function Query_OrdersDispatched(TablesList)
	
	// Add OrdersDispatched table to document structure
	TablesList.Insert("Table_OrdersDispatched", TablesList.Count());
	
	// Collect orders dispatched data
	QueryText =
	"SELECT
	// ------------------------------------------------------
	// Standard Attributes
	|	LineItems.Ref                         AS Recorder,
	|	LineItems.Ref.Date                    AS Period,
	|	LineItems.LineNumber                  AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Dimensions
	|	LineItems.Ref.Company                 AS Company,
	|	LineItems.Order                       AS Order,
	|	LineItems.Product                     AS Product,
	// ------------------------------------------------------
	// Resources
	|	0                                     AS Quantity,
	|	LineItems.Quantity                    AS Received,
	|	0                                     AS Invoiced
	// ------------------------------------------------------
	// Attributes
	// ------------------------------------------------------
	|FROM
	|	Document.ItemReceipt.LineItems AS LineItems
	|WHERE
	|	LineItems.Ref = &Ref
	|	AND LineItems.Order <> VALUE(Document.PurchaseOrder.EmptyRef)
	|ORDER BY
	|	LineNumber";
	
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
		If FillingData.Key = "Document_PurchaseOrder" Then
			Query.Text = Query.Text +
						 Query_Filling_Document_PurchaseOrder_Attributes(TablesList) +
						 Query_Filling_Document_PurchaseOrder_OrdersStatuses(TablesList) +
						 Query_Filling_Document_PurchaseOrder_OrdersDispatched(TablesList) +
						 Query_Filling_Document_PurchaseOrder_LineItems(TablesList) +
						 Query_Filling_Document_PurchaseOrder_Totals(TablesList);
			
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
Function Query_Filling_Document_PurchaseOrder_Attributes(TablesList)
	
	// Add Attributes table to document structure
	TablesList.Insert("Table_Document_PurchaseOrder_Attributes", TablesList.Count());
	
	// Collect attributes data
	QueryText =
		"SELECT
		|	PurchaseOrder.Ref                       AS FillingData,
		|	PurchaseOrder.Company                   AS Company,
		|	PurchaseOrder.CompanyCode               AS CompanyCode,
		|	PurchaseOrder.Currency                  AS Currency,
		|	PurchaseOrder.ExchangeRate              AS ExchangeRate,
		|	PurchaseOrder.Location                  AS Location,
		|	PurchaseOrder.PriceIncludesVAT          AS PriceIncludesVAT,
		|	PurchaseOrder.Project                   AS Project
		|INTO
		|	Table_Document_PurchaseOrder_Attributes
		|FROM
		|	Document.PurchaseOrder AS PurchaseOrder
		|WHERE
		|	PurchaseOrder.Ref IN (&FillingData_Document_PurchaseOrder)";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document filling
Function Query_Filling_Document_PurchaseOrder_OrdersStatuses(TablesList)
	
	// Add OrdersStatuses table to document structure
	TablesList.Insert("Table_Document_PurchaseOrder_OrdersStatuses", TablesList.Count());
	
	// Collect orders statuses data
	QueryText =
		"SELECT
		// ------------------------------------------------------
		// Dimensions
		|	PurchaseOrder.Ref                        AS Order,
		// ------------------------------------------------------
		// Resources
		|	CASE
		|		WHEN PurchaseOrder.DeletionMark THEN
		|			 VALUE(Enum.OrderStatuses.Deleted)
		|		WHEN NOT PurchaseOrder.Posted THEN
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
		|	Table_Document_PurchaseOrder_OrdersStatuses
		|FROM
		|	Document.PurchaseOrder AS PurchaseOrder
		|		LEFT JOIN InformationRegister.OrdersStatuses.SliceLast AS OrdersStatuses
		|		ON PurchaseOrder.Ref = OrdersStatuses.Order
		|WHERE
		|	PurchaseOrder.Ref IN (&FillingData_Document_PurchaseOrder)";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document filling
Function Query_Filling_Document_PurchaseOrder_OrdersDispatched(TablesList)
	
	// Add OrdersDispatched table to document structure
	TablesList.Insert("Table_Document_PurchaseOrder_OrdersDispatched", TablesList.Count());
	
	// Collect orders items data
	QueryText =
		"SELECT
		// ------------------------------------------------------
		// Dimensions
		|	OrdersDispatchedBalance.Company          AS Company,
		|	OrdersDispatchedBalance.Order            AS Order,
		|	OrdersDispatchedBalance.Product          AS Product,
		// ------------------------------------------------------
		// Resources                                                                                                        // ---------------------------------------
		|	OrdersDispatchedBalance.QuantityBalance  AS Quantity,                                                           // Backorder quantity calculation
		|	CASE                                                                                                            // ---------------------------------------
		|		WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Open)        THEN 0                                   // Order status = Open:
		|		WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Backordered) THEN                                     //   Backorder = 0
		|			CASE                                                                                                    // Order status = Backorder:
		|				WHEN OrdersDispatchedBalance.Product.Type = VALUE(Enum.InventoryTypes.Inventory) THEN               //   Inventory:
		|					CASE                                                                                            //     Backorder = Ordered - Received >= 0
		|						WHEN OrdersDispatchedBalance.QuantityBalance > OrdersDispatchedBalance.ReceivedBalance THEN //     |
		|							 OrdersDispatchedBalance.QuantityBalance - OrdersDispatchedBalance.ReceivedBalance      //     |
		|						ELSE 0 END                                                                                  //     |
		|				WHEN OrdersDispatchedBalance.Product.Type = VALUE(Enum.InventoryTypes.NonInventory) THEN            //   Non-inventory:
		|					CASE                                                                                            //     Backorder = Ordered - Invoiced >= 0
		|						WHEN OrdersDispatchedBalance.QuantityBalance > OrdersDispatchedBalance.InvoicedBalance THEN //     |
		|							 OrdersDispatchedBalance.QuantityBalance - OrdersDispatchedBalance.InvoicedBalance      //     |
		|						ELSE 0 END                                                                                  //     |
		|				ELSE 0                                                                                              //   NULL or something else:
		|				END                                                                                                 //     0
		|		WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Closed)      THEN 0                                   // Order status = Closed:
		|		ELSE 0                                                                                                      //   Backorder = 0
		|		END                                  AS Backorder
		// ------------------------------------------------------
		|INTO
		|	Table_Document_PurchaseOrder_OrdersDispatched
		|FROM
		|	AccumulationRegister.OrdersDispatched.Balance(,
		|		(Company, Order, Product) IN
		|			(SELECT
		|				PurchaseOrderLineItems.Ref.Company,
		|				PurchaseOrderLineItems.Ref,
		|				PurchaseOrderLineItems.Product
		|			FROM
		|				Document.PurchaseOrder.LineItems AS PurchaseOrderLineItems
		|			WHERE
		|				PurchaseOrderLineItems.Ref IN (&FillingData_Document_PurchaseOrder))) AS OrdersDispatchedBalance
		|	LEFT JOIN Table_Document_PurchaseOrder_OrdersStatuses AS OrdersStatuses
		|		ON OrdersDispatchedBalance.Order = OrdersStatuses.Order";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document filling
Function Query_Filling_Document_PurchaseOrder_LineItems(TablesList)
	
	// Add LineItems table to document structure
	TablesList.Insert("Table_Document_PurchaseOrder_LineItems", TablesList.Count());
	
	// Collect line items data
	QueryText =
		"SELECT
		|	PurchaseOrderLineItems.Ref                 AS FillingData,
		|	PurchaseOrderLineItems.Product             AS Product,
		|	PurchaseOrderLineItems.ProductDescription  AS ProductDescription,
		|	PurchaseOrderLineItems.Price               AS Price,
		|	CASE
		|		WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Open)
		|			THEN ISNULL(OrdersDispatched.Quantity, PurchaseOrderLineItems.Quantity)
		|		WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Backordered)
		|			THEN ISNULL(OrdersDispatched.Backorder, PurchaseOrderLineItems.Quantity)
		|		WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Closed)
		|			THEN ISNULL(OrdersDispatched.Backorder, 0)
		|		ELSE 0
		|	END                                        AS Quantity,
		|	CAST( // Format(Quantity * Price, ""ND=15; NFD=2"")
		|		CASE
		|			WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Open)
		|				THEN ISNULL(OrdersDispatched.Quantity, PurchaseOrderLineItems.Quantity)
		|			WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Backordered)
		|				THEN ISNULL(OrdersDispatched.Backorder, PurchaseOrderLineItems.Quantity)
		|			WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Closed)
		|				THEN ISNULL(OrdersDispatched.Backorder, 0)
		|			ELSE 0
		|		END * PurchaseOrderLineItems.Price 
		|		AS NUMBER (15, 2))                     AS LineTotal,
		|	PurchaseOrderLineItems.VATCode             AS VATCode,
		|	CAST( // Format(LineTotal * VATRate / 100, ""ND=15; NFD=2"")
		|		CAST( // Format(Quantity * Price, ""ND=15; NFD=2"")
		|			CASE
		|				WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Open)
		|					THEN ISNULL(OrdersDispatched.Quantity, PurchaseOrderLineItems.Quantity)
		|				WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Backordered)
		|					THEN ISNULL(OrdersDispatched.Backorder, PurchaseOrderLineItems.Quantity)
		|				WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Closed)
		|					THEN ISNULL(OrdersDispatched.Backorder, 0)
		|				ELSE 0
		|			END * PurchaseOrderLineItems.Price
		|		AS NUMBER (15, 2)) *
		|		CASE // VATRate = ?(Ref.PriceIncludesVAT, VATCode.PurchaseInclRate, VATCode.PurchaseExclRate)
		|			WHEN PurchaseOrderLineItems.Ref.PriceIncludesVAT IS NULL THEN 0
		|			WHEN PurchaseOrderLineItems.Ref.PriceIncludesVAT         THEN ISNULL(PurchaseOrderLineItems.VATCode.PurchaseInclRate, 0)
		|			ELSE                                                          ISNULL(PurchaseOrderLineItems.VATCode.PurchaseExclRate, 0)
		|		END /
		|		100
		|	AS NUMBER (15, 2))                         AS VAT,
		|	PurchaseOrderLineItems.Ref                 AS Order,
		|	PurchaseOrderLineItems.Ref.Company         AS Company,
		|	PurchaseOrderLineItems.Project             AS Project
		|INTO
		|	Table_Document_PurchaseOrder_LineItems
		|FROM
		|	Document.PurchaseOrder.LineItems AS PurchaseOrderLineItems
		|	LEFT JOIN Table_Document_PurchaseOrder_OrdersDispatched AS OrdersDispatched
		|		ON  OrdersDispatched.Company = PurchaseOrderLineItems.Ref.Company
		|		AND OrdersDispatched.Order   = PurchaseOrderLineItems.Ref
		|		AND OrdersDispatched.Product = PurchaseOrderLineItems.Product
		|	LEFT JOIN Table_Document_PurchaseOrder_OrdersStatuses AS OrdersStatuses
		|		ON OrdersStatuses.Order = PurchaseOrderLineItems.Ref
		|WHERE
		|	 PurchaseOrderLineItems.Ref IN (&FillingData_Document_PurchaseOrder)
		|AND PurchaseOrderLineItems.Product.Type = VALUE(Enum.InventoryTypes.Inventory)"; // Skip non-inventory items
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document filling
Function Query_Filling_Document_PurchaseOrder_Totals(TablesList)
	
	// Add Totals table to document structure
	TablesList.Insert("Table_Document_PurchaseOrder_Totals", TablesList.Count());
	
	// Collect totals data
	QueryText =
		"SELECT
		// Totals of document
		|	PurchaseOrderLineItems.FillingData      AS FillingData,
		|
		|	CAST( // Format(Total(VAT) * ExchangeRate, ""ND=15; NFD=2"")
		|		SUM(PurchaseOrderLineItems.VAT) *
		|		PurchaseOrder.ExchangeRate
		|		AS NUMBER (15, 2))                  AS VATTotal,
		|
		|	CASE
		|		WHEN PurchaseOrder.PriceIncludesVAT THEN // Total(LineTotal)
		|			SUM(PurchaseOrderLineItems.LineTotal)
		|		ELSE                                     // Total(LineTotal) + Total(VAT)
		|			SUM(PurchaseOrderLineItems.LineTotal) +
		|			SUM(PurchaseOrderLineItems.VAT)
		|	END                                     AS DocumentTotal,
		|
		|	CAST( // Format(DocumentTotal * ExchangeRate, ""ND=15; NFD=2"")
		|		CASE // DocumentTotal
		|			WHEN PurchaseOrder.PriceIncludesVAT THEN // Total(LineTotal)
		|				SUM(PurchaseOrderLineItems.LineTotal)
		|			ELSE                                     // Total(LineTotal) + Total(VAT)
		|				SUM(PurchaseOrderLineItems.LineTotal) +
		|				SUM(PurchaseOrderLineItems.VAT)
		|		END *
		|		PurchaseOrder.ExchangeRate
		|		AS NUMBER (15, 2))                  AS DocumentTotalRC
		|
		|INTO
		|	Table_Document_PurchaseOrder_Totals
		|FROM
		|	Table_Document_PurchaseOrder_LineItems AS PurchaseOrderLineItems
		|	LEFT JOIN Table_Document_PurchaseOrder_Attributes AS PurchaseOrder
		|		ON PurchaseOrder.FillingData = PurchaseOrderLineItems.FillingData
		|GROUP BY
		|	PurchaseOrderLineItems.FillingData,
		|	PurchaseOrder.ExchangeRate,
		|	PurchaseOrder.PriceIncludesVAT";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document filling
Function Query_Filling_Attributes(TablesList)
	
	// Add Attributes table to document structure
	TablesList.Insert("Table_Attributes", TablesList.Count());
	
	// Fill data from attributes and totals
	QueryText = "";
	If TablesList.Property("Table_Document_PurchaseOrder_Attributes") Then
		QueryText = QueryText + ?(Not IsBlankString(QueryText),
		"
		|
		|UNION ALL
		|
		|",
		"");
		
		SelectionText =
		"SELECT
		|	Document_PurchaseOrder_Attributes.FillingData,
		|	Document_PurchaseOrder_Attributes.Company,
		|	Document_PurchaseOrder_Attributes.CompanyCode,
		|	Document_PurchaseOrder_Totals.DocumentTotal,
		|	Document_PurchaseOrder_Attributes.Currency,
		|	Document_PurchaseOrder_Attributes.ExchangeRate,
		|	Document_PurchaseOrder_Totals.DocumentTotalRC,
		|	Document_PurchaseOrder_Attributes.Location,
		|	Document_PurchaseOrder_Totals.VATTotal,
		|	Document_PurchaseOrder_Attributes.PriceIncludesVAT,
		|	Document_PurchaseOrder_Attributes.Project
		|{Into}
		|FROM
		|	Table_Document_PurchaseOrder_Attributes AS Document_PurchaseOrder_Attributes
		|	LEFT JOIN Table_Document_PurchaseOrder_Totals AS Document_PurchaseOrder_Totals
		|		ON Document_PurchaseOrder_Totals.FillingData = Document_PurchaseOrder_Attributes.FillingData";
		
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
	If TablesList.Property("Table_Document_PurchaseOrder_LineItems") Then
		QueryText = QueryText + ?(Not IsBlankString(QueryText),
		"
		|
		|UNION ALL
		|
		|",
		"");
		
		SelectionText =
		"SELECT
		|	Document_PurchaseOrder_LineItems.FillingData,
		|	Document_PurchaseOrder_LineItems.Product,
		|	Document_PurchaseOrder_LineItems.ProductDescription,
		|	Document_PurchaseOrder_LineItems.Price,
		|	Document_PurchaseOrder_LineItems.Quantity,
		|	Document_PurchaseOrder_LineItems.LineTotal,
		|	Document_PurchaseOrder_LineItems.VATCode,
		|	Document_PurchaseOrder_LineItems.VAT,
		|	Document_PurchaseOrder_LineItems.Order,
		|	Document_PurchaseOrder_LineItems.Project
		|{Into}
		|FROM
		|	Table_Document_PurchaseOrder_LineItems AS Document_PurchaseOrder_LineItems
		|WHERE
		|	Document_PurchaseOrder_LineItems.Quantity > 0";
		
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
	CheckAttributes.Insert("PriceIncludesVAT", "Check");
	// Maximal possible values
	// {No min/max fields are defined}
	// Summarize totals
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

// Check status of passed purchase order by ref
// Returns True if status passed for filling
Function CheckStatusOfPurchaseOrder(DocumentRef, FillingRef) Export
	
	// Create new query
	Query = New Query;
	Query.SetParameter("Ref", FillingRef);
	
	QueryText =
		"SELECT
		|	CASE
		|		WHEN PurchaseOrder.DeletionMark THEN
		|			 VALUE(Enum.OrderStatuses.Deleted)
		|		WHEN NOT PurchaseOrder.Posted THEN
		|			 VALUE(Enum.OrderStatuses.Draft)
		|		WHEN OrdersStatuses.Status IS NULL THEN
		|			 VALUE(Enum.OrderStatuses.Open)
		|		WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.EmptyRef) THEN
		|			 VALUE(Enum.OrderStatuses.Open)
		|		ELSE
		|			 OrdersStatuses.Status
		|	END AS Status
		|FROM
		|	Document.PurchaseOrder AS PurchaseOrder
		|	LEFT JOIN InformationRegister.OrdersStatuses.SliceLast AS OrdersStatuses
		|		ON PurchaseOrder.Ref = OrdersStatuses.Order
		|WHERE
		|	PurchaseOrder.Ref = &Ref";
	Query.Text  = QueryText;
	OrderStatus = Query.Execute().Unload()[0].Status;
	
	StatusOK = (OrderStatus = Enums.OrderStatuses.Open) Or (OrderStatus = Enums.OrderStatuses.Backordered);
	If Not StatusOK Then
		MessageText = NStr("en = 'Failed to generate the %1 on the base of %2 %3.'");
		MessageText = StringFunctionsClientServer.SubstituteParametersInString(MessageText,
		                                                                       Lower(Metadata.FindByType(TypeOf(DocumentRef)).Presentation()),
		                                                                       Lower(OrderStatus),
		                                                                       Lower(Metadata.FindByType(TypeOf(FillingRef)).Presentation())); 
		CommonUseClientServer.MessageToUser(MessageText, FillingRef);
	EndIf;
	Return StatusOK;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// DOCUMENT PRINTING (OLD)

Procedure Print(Spreadsheet, Ref) Export  // ObjectArray, PrintObjects
	
	CustomTemplate = GeneralFunctions.GetCustomTemplate("Document.ItemReceipt", "Item receipt");
	
	If CustomTemplate = Undefined Then
		Template = Documents.ItemReceipt.GetTemplate("PF_MXL_ItemReceipt");
	Else
		Template = CustomTemplate;
	EndIf;
	
	// Create a spreadsheet document and set print parameters.
	//SpreadsheetDocument = New SpreadsheetDocument;
	//SpreadsheetDocument.PrintParametersName = "PrintParameters_ItemReceipt";

	// Quering necessary data.
	Query = New Query();
	Query.Text =
	"SELECT
	|	ItemReceipt.Ref,
	|	ItemReceipt.Company,
	|	ItemReceipt.Date,
	|	ItemReceipt.DocumentTotal,
	|	ItemReceipt.Number,
	|	ItemReceipt.PriceIncludesVAT,
	|	ItemReceipt.Currency,
	|	ItemReceipt.VATTotal,
	|	ItemReceipt.LineItems.(
	|		Product,
	|		ProductDescription,
	|		Product.UM AS UM,
	|		Quantity,
	|		Price,
	|		VATCode,
	|		VAT,
	|		LineTotal
	|	)
	|FROM
	|	Document.ItemReceipt AS ItemReceipt
	|WHERE
	|	ItemReceipt.Ref IN(&Ref)";
	Query.SetParameter("Ref", Ref);
	Selection = Query.Execute().Choose();
	
	//AreaCaption = Template.GetArea("Caption");
	//Header = Template.GetArea("Header");
	Spreadsheet.Clear();

	InsertPageBreak = False;
	While Selection.Next() Do

	
   //	FirstDocument = True;
   //
   //	While Selection.Next() Do
   // 	
   // 	If Not FirstDocument Then
   // 		// All documents need to be outputted on separate pages.
   // 		Spreadsheet.PutHorizontalPageBreak();
   // 	EndIf;
   // 	FirstDocument = False;
   // 	// Remember current document output beginning line number.
   // 	BeginningLineNumber = Spreadsheet.TableHeight + 1;
	 	 
	TemplateArea = Template.GetArea("Header");
	
	UsBill = PrintTemplates.ContactInfoDatasetUs();
	ThemBill = PrintTemplates.ContactInfoDataset(Selection.Company, "ThemBill", Catalogs.Addresses.EmptyRef());
	
	TemplateArea.Parameters.Fill(UsBill);
	TemplateArea.Parameters.Fill(ThemBill);
	 	 
	 TemplateArea.Parameters.Date = Selection.Date;
	 TemplateArea.Parameters.Number = Selection.Number;
	 
	 Spreadsheet.Put(TemplateArea);

	 TemplateArea = Template.GetArea("LineItemsHeader");
	 Spreadsheet.Put(TemplateArea);
	 
	 SelectionLineItems = Selection.LineItems.Choose();
	 TemplateArea = Template.GetArea("LineItems");
	 LineTotalSum = 0;
	 While SelectionLineItems.Next() Do
		 
		 TemplateArea.Parameters.Fill(SelectionLineItems);
		 LineTotal = SelectionLineItems.LineTotal;
		 LineTotalSum = LineTotalSum + LineTotal;
		 Spreadsheet.Put(TemplateArea, SelectionLineItems.Level());
		 
	 EndDo;
	 
	//If Selection.SalesTax <> 0 Then;
	//	 TemplateArea = Template.GetArea("Subtotal");
	//	 TemplateArea.Parameters.Subtotal = LineTotalSum;
	//	 Spreadsheet.Put(TemplateArea);
	//	 
	//	 TemplateArea = Template.GetArea("SalesTax");
	//	 TemplateArea.Parameters.SalesTaxTotal = Selection.SalesTax;
	//	 Spreadsheet.Put(TemplateArea);
	//EndIf; 

	
	If Selection.VATTotal <> 0 Then;
		 TemplateArea = Template.GetArea("Subtotal");
		 TemplateArea.Parameters.Subtotal = LineTotalSum;
		 Spreadsheet.Put(TemplateArea);
		 
		 TemplateArea = Template.GetArea("VAT");
		 TemplateArea.Parameters.VATTotal = Selection.VATTotal;
		 Spreadsheet.Put(TemplateArea);
	EndIf; 
		 
	 TemplateArea = Template.GetArea("Total");
	If Selection.PriceIncludesVAT Then
	 	TemplateArea.Parameters.DocumentTotal = LineTotalSum; //+ Selection.SalesTax;
	Else
		TemplateArea.Parameters.DocumentTotal = LineTotalSum + Selection.VATTotal;
	EndIf;

	 Spreadsheet.Put(TemplateArea);

	 //TemplateArea = Template.GetArea("Currency");
	 //TemplateArea.Parameters.Currency = Selection.Currency;
	 //Spreadsheet.Put(TemplateArea);
	 
     // Setting a print area in the spreadsheet document where to output the object.
     // Necessary for kit printing. 
     //PrintManagement.SetDocumentPrintArea(SpreadsheetDocument, BeginningLineNumber, PrintObjects, Selection.Ref);

	 InsertPageBreak = True;
	 
   EndDo;
   
   //Return SpreadsheetDocument;
   
EndProcedure