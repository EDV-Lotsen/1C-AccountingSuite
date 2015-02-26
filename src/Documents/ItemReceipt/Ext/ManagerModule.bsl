
////////////////////////////////////////////////////////////////////////////////
// Item Receipt: Manager module
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
	OrdersPosting    = AdditionalProperties.Orders.Count() > 0;
	
	
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
	If OrdersPosting Then
		Query.Text = Query.Text +
		             Query_OrdersDispatched_Lock(LocksList);
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
	If OrdersPosting Then
		Query.Text = Query.Text +
		             Query_OrdersDispatched_Balance(BalancesList);
	EndIf;
	
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
	OrdersPosting = AdditionalProperties.Orders.Count() > 0;
	
	// Create list of posting tables (according to the list of registers).
	TablesList = New Structure;
	
	// Create a query to request document data.
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	
	//------------------------------------------------------------------------------
	// 2. Prepare query text.
	
	// Query for document's tables.
	Query.Text = "";
	If OrdersPosting Then
		Query.Text = Query.Text +
		             Query_OrdersStatuses(TablesList) +
		             Query_OrdersDispatched(TablesList);
	EndIf;
	Query.Text = Query.Text +
				 Query_Lots(TablesList) +
				 Query_SerialNumbers(TablesList) +
				 Query_InventoryJournal_LineItems(TablesList) +
				 Query_InventoryJournal(TablesList) +
				 Query_GeneralJournal_LineItems(TablesList) +
				 Query_GeneralJournal_Accounts_InvOrExp(TablesList) +
				 Query_GeneralJournal_Accounts_OCL(TablesList) +
				 Query_GeneralJournal(TablesList);
	
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

// Check proper closing of order items by the invoice items.
Procedure CheckOrderQuantity(DocumentRef, DocumentDate, Company, LineItems, Cancel) Export
	ErrorsCount = 0;
	MessageText = "";
	
	// 1. Create a query to request data.
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Date", DocumentDate);
	
	// 2. Fill out the line items table.
	InvoiceLineItems = LineItems.Unload(, "LineNumber, Order, Product, Unit, LocationOrder, DeliveryDateOrder, Project, Class, QtyUnits");
	InvoiceLineItems.Columns.Insert(1, "Company", New TypeDescription("CatalogRef.Companies"), "", 20);
	InvoiceLineItems.FillValues(Company, "Company");
	DocumentPosting.PutTemporaryTable(InvoiceLineItems, "InvoiceLineItems", Query.TempTablesManager);
	
	// 3. Request uninvoiced items for each line item.
	Query.Text = "
		|SELECT
		|	LineItems.LineNumber          AS LineNumber,
		|	LineItems.Order               AS Order,
		|	LineItems.Product.Code        AS ProductCode,
		|	LineItems.Product.Description AS ProductDescription,
		|	OrdersDispatchedBalance.QuantityBalance - OrdersDispatchedBalance.ReceivedIRBalance - LineItems.QtyUnits AS UninvoicedQuantity
		|FROM
		|	InvoiceLineItems AS LineItems
		|	LEFT JOIN AccumulationRegister.OrdersDispatched.Balance(&Date, (Company, Order, Product, Unit, Location, DeliveryDate, Project, Class)
		|		      IN (SELECT Company, Order, Product, Unit, LocationOrder, DeliveryDateOrder, Project, Class FROM InvoiceLineItems)) AS OrdersDispatchedBalance
		|		ON  LineItems.Company           = OrdersDispatchedBalance.Company
		|		AND LineItems.Order             = OrdersDispatchedBalance.Order
		|		AND LineItems.Product           = OrdersDispatchedBalance.Product
		|		AND LineItems.Unit              = OrdersDispatchedBalance.Unit
		|		AND LineItems.LocationOrder     = OrdersDispatchedBalance.Location
		|		AND LineItems.DeliveryDateOrder = OrdersDispatchedBalance.DeliveryDate
		|		AND LineItems.Project           = OrdersDispatchedBalance.Project
		|		AND LineItems.Class             = OrdersDispatchedBalance.Class
		|ORDER BY
		|	LineItems.LineNumber";
	UninvoicedItems = Query.Execute().Unload();
	
	// 4. Process status of line items and create diagnostic message.
	For Each Row In UninvoicedItems Do
		If Row.UninvoicedQuantity = Null Then
			ErrorsCount = ErrorsCount + 1;
			If ErrorsCount <= 10 Then
				MessageText = MessageText + ?(Not IsBlankString(MessageText), Chars.LF, "") +
				                            StringFunctionsClientServer.SubstituteParametersInString(
				                            NStr("en = 'The product %1 in line %2 was not declared in %3.'"), TrimAll(Row.ProductCode) + " " + TrimAll(Row.ProductDescription), Row.LineNumber, Row.Order);
			EndIf;
			
		ElsIf Row.UninvoicedQuantity < 0 Then
			ErrorsCount = ErrorsCount + 1;
			If ErrorsCount <= 10 Then
				MessageText = MessageText + ?(Not IsBlankString(MessageText), Chars.LF, "") +
				                            StringFunctionsClientServer.SubstituteParametersInString(
				                            NStr("en = 'The received quantity of product %1 in line %2 exceeds ordered quantity in %3.'"), TrimAll(Row.ProductCode) + " " + TrimAll(Row.ProductDescription), Row.LineNumber, Row.Order);
			EndIf;
		EndIf;
	EndDo;
	If ErrorsCount > 10 Then
		MessageText = MessageText + Chars.LF + StringFunctionsClientServer.SubstituteParametersInString(
		                                       NStr("en = 'There are also %1 error(s) found'"), Format(ErrorsCount - 10, "NFD=0; NG=0"));
	EndIf;
	
	// 5. Notify user if failed items found.
	If ErrorsCount > 0 Then
		CommonUseClientServer.MessageToUser(MessageText, DocumentRef,,, Cancel);
	EndIf;
	
EndProcedure

//------------------------------------------------------------------------------
// Document filling

// Collect source data for filling document on the server (in terms of document).
Function PrepareDataStructuresForFilling(DocumentRef, AdditionalProperties) Export
	
	// Create list of posting tables (according to the list of registers).
	TablesList = New Structure;
	
	// Create a query to request document data.
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref",  DocumentRef);
	Query.SetParameter("Date", AdditionalProperties.Date);
	
	// Query for document's tables.
	Query.Text   = "";
	For Each FillingData In AdditionalProperties.Filling.FillingData Do
		
		// Construct query by passed sources.
		If FillingData.Key = "Document_PurchaseOrder" Then
			Query.Text = Query.Text +
			             Query_Filling_Document_PurchaseOrder_Attributes(TablesList) +
			             Query_Filling_Document_PurchaseOrder_OrdersStatuses(TablesList) +
			             Query_Filling_Document_PurchaseOrder_OrdersDispatched(TablesList) +
			             Query_Filling_Document_PurchaseOrder_LineItems(TablesList) +
			             Query_Filling_Document_PurchaseOrder_Totals(TablesList);
			
		Else // Next filling source.
		EndIf;
		
		Query.SetParameter("FillingData_" + FillingData.Key, FillingData.Value);
	EndDo;
	
	// Add combining query.
	Query.Text = Query.Text +
	             Query_Filling_Attributes(TablesList) +
	             Query_Filling_LineItems(TablesList);
	
	// Add check query.
	Query.Text = Query.Text +
	             Query_Filling_Check(TablesList, FillingCheckList(AdditionalProperties));
	
	// Execute query, fill temporary tables with filling data.
	If TablesList.Count() > 3 Then
		
		// Execute query.
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

// Check status of passed purchase order by ref.
// Returns True if status passed for filling.
Function CheckStatusOfPurchaseOrder(DocumentRef, FillingRef) Export
	
	// Create new query.
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

// Check "Use Item receipt" of passed purchase order by ref. 
Function CheckUseItemReceiptOfPurchaseOrder(DocumentRef, FillingRef) Export
	
	StatusOK = FillingRef.UseIR;
	
	If Not StatusOK Then
		MessageText = NStr("en = 'Failed to generate the %1 because %2 does not use Item receipt.'");
		MessageText = StringFunctionsClientServer.SubstituteParametersInString(MessageText,
		                                                                       Lower(Metadata.FindByType(TypeOf(DocumentRef)).Presentation()),
		                                                                       Lower(Metadata.FindByType(TypeOf(FillingRef)).Presentation())); 
		CommonUseClientServer.MessageToUser(MessageText, FillingRef);
	EndIf;
	
	Return StatusOK;
	
EndFunction

#EndIf

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region COMMANDS_HANDLERS

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

Procedure Print(Spreadsheet, Ref) Export
	
	CustomTemplate = GeneralFunctions.GetCustomTemplate("Document.ItemReceipt", "Item receipt");
	
	If CustomTemplate = Undefined Then
		//Template = Documents.ItemReceipt.GetTemplate("");
	Else
		//Template = CustomTemplate;
	EndIf;  
   
EndProcedure

#EndIf

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region PRIVATE_IMPLEMENTATION

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

//------------------------------------------------------------------------------
// Document posting

// Query for document data.
Function Query_OrdersStatuses(TablesList)
	
	// Add OrdersStatuses table to document structure.
	TablesList.Insert("Table_OrdersStatuses", TablesList.Count());
	
	// Collect orders statuses data.
	QueryText =
	"SELECT DISTINCT
	// ------------------------------------------------------
	// Standard attributes
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
	|
	|UNION ALL
	|
	|SELECT
	// ------------------------------------------------------
	// Standard attributes
	|	Document.Ref                          AS Recorder,
	|	Document.Date                         AS Period,
	|	1                                     AS LineNumber,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Dimensions
	|	Document.Ref                          AS Order,
	// ------------------------------------------------------
	// Resources
	|	VALUE(Enum.OrderStatuses.Open)        AS Status
	// ------------------------------------------------------
	// Attributes
	// ------------------------------------------------------
	|FROM
	|	Document.ItemReceipt AS Document
	|WHERE
	|	Document.Ref = &Ref
	|ORDER BY
	|	Order";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_OrdersDispatched(TablesList)
	
	// Add OrdersDispatched table to document structure.
	TablesList.Insert("Table_OrdersDispatched", TablesList.Count());
	
	// Collect orders dispatched data.
	QueryText =
	"SELECT
	// ------------------------------------------------------
	// Standard attributes
	|	LineItems.Ref                         AS Recorder,
	|	LineItems.Ref.Date                    AS Period,
	|	LineItems.LineNumber                  AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Dimensions
	|	LineItems.Ref.Company                 AS Company,
	|	LineItems.Order                       AS Order,
	|	LineItems.Ref                         AS ItemReceipt,
	|	LineItems.Product                     AS Product,
	|	LineItems.Unit                        AS Unit,
	|	LineItems.LocationOrder               AS Location,
	|	LineItems.DeliveryDateOrder           AS DeliveryDate,
	|	LineItems.Project                     AS Project,
	|	LineItems.Class                       AS Class,
	// ------------------------------------------------------
	// Resources
	|	0                                     AS Quantity,
	|	CASE
	|		WHEN LineItems.Product.Type = VALUE(Enum.InventoryTypes.Inventory)
	|			THEN LineItems.QtyUnits
	|       ELSE 0
	|   END                                   AS Received,
	|	LineItems.QtyUnits                    AS ReceivedIR,
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

// Query for dimensions lock data.
Function Query_OrdersDispatched_Lock(TablesList)
	
	// Add OrdersDispatched - Lock table to locks structure.
	TablesList.Insert("AccumulationRegister_OrdersDispatched", TablesList.Count());
	
	// Collect dimensions for orders dispatched locking.
	QueryText =
	"SELECT DISTINCT
	// ------------------------------------------------------
	// Dimensions
	|	&Company                              AS Company,
	|	LineItems.Order                       AS Order,
	|	LineItems.Product                     AS Product,
	|	LineItems.Unit                        AS Unit
	// ------------------------------------------------------
	|FROM
	|	Table_LineItems AS LineItems
	|WHERE
	|	LineItems.Order <> VALUE(Document.PurchaseOrder.EmptyRef)";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for balances data.
Function Query_OrdersDispatched_Balance(TablesList)
	
	// Add OrdersDispatched - Balances table to balances structure.
	TablesList.Insert("Table_OrdersDispatched_Balance", TablesList.Count());
	
	// Collect orders dispatched balances.
	QueryText =
	"SELECT
	// ------------------------------------------------------
	// Dimensions
	|	OrdersDispatchedBalance.Company            AS Company,
	|	OrdersDispatchedBalance.Order              AS Order,
	|	OrdersDispatchedBalance.ItemReceipt        AS ItemReceipt,
	|	OrdersDispatchedBalance.Product            AS Product,
	|	OrdersDispatchedBalance.Unit               AS Unit,
	|	OrdersDispatchedBalance.Location           AS Location,
	|	OrdersDispatchedBalance.DeliveryDate       AS DeliveryDate,
	|	OrdersDispatchedBalance.Project            AS Project,
	|	OrdersDispatchedBalance.Class              AS Class,
	// ------------------------------------------------------
	// Resources
	|	OrdersDispatchedBalance.QuantityBalance    AS Quantity,
	|	OrdersDispatchedBalance.ReceivedBalance    AS Received,
	|	OrdersDispatchedBalance.ReceivedIRBalance  AS ReceivedIR,
	|	OrdersDispatchedBalance.InvoicedBalance    AS Invoiced
	// ------------------------------------------------------
	|FROM
	|	AccumulationRegister.OrdersDispatched.Balance(&PointInTime,
	|		(Company, Order) IN
	|		(SELECT DISTINCT &Company, LineItems.Order // Requred for proper order closing
	|		 FROM Table_LineItems AS LineItems)) AS OrdersDispatchedBalance";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_Lots(TablesList)
	
	// Add Lots table to document structure.
	TablesList.Insert("Table_Lots", TablesList.Count());
	
	// Collect lots data.
	QueryText =
	"SELECT
	// ------------------------------------------------------
	// Standard attributes
	|	LineItems.Ref                         AS Recorder,
	|	LineItems.Ref.Date                    AS Period,
	|	LineItems.LineNumber                  AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Dimensions
	|	LineItems.Product                     AS Product,
	|	LineItems.Location                    AS Location,
	|	LineItems.Lot                         AS Lot,
	// ------------------------------------------------------
	// Resources
	|	LineItems.QtyUM                       AS Quantity
	// ------------------------------------------------------
	// Attributes
	// ------------------------------------------------------
	|FROM
	|	Document.ItemReceipt.LineItems AS LineItems
	|WHERE
	|	    LineItems.Ref = &Ref
	|	AND LineItems.Product  <> VALUE(Catalog.Products.EmptyRef)
	|	AND LineItems.Product.HasLotsSerialNumbers
	|	AND LineItems.Product.UseLots = 0
	|	AND LineItems.Location <> VALUE(Catalog.Locations.EmptyRef)
	|	AND LineItems.Lot      <> VALUE(Catalog.Lots.EmptyRef)
	|ORDER BY
	|	LineItems.LineNumber";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_SerialNumbers(TablesList)
	
	// Add SerialNumbers table to document structure.
	TablesList.Insert("Table_SerialNumbers", TablesList.Count());
	
	// Collect serial numbers data.
	QueryText =
	"SELECT
	// ------------------------------------------------------
	// Standard attributes
	|	SerialNumbers.Ref                     AS Recorder,
	|	SerialNumbers.Ref.Date                AS Period,
	|	SerialNumbers.LineNumber              AS LineNumber,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Dimensions
	|	ISNULL(LineItems.Product, VALUE(Catalog.Products.EmptyRef))
	|	                                      AS Product,
	|	SerialNumbers.SerialNumber            AS SerialNumber,
	// ------------------------------------------------------
	// Resources
	|	True                                  AS OnHand
	// ------------------------------------------------------
	// Attributes
	// ------------------------------------------------------
	|FROM
	|	Document.ItemReceipt.SerialNumbers AS SerialNumbers
	|	LEFT JOIN Document.ItemReceipt.LineItems AS LineItems
	|		ON  SerialNumbers.Ref             = LineItems.Ref
	|		AND SerialNumbers.LineItemsLineID = LineItems.LineID
	|WHERE
	|	    SerialNumbers.Ref = &Ref
	|	AND SerialNumbers.SerialNumber <> """"
	|	AND ISNULL(LineItems.Product, VALUE(Catalog.Products.EmptyRef)) <> VALUE(Catalog.Products.EmptyRef)
	|	AND ISNULL(LineItems.Product.HasLotsSerialNumbers, False)
	|	AND ISNULL(LineItems.Product.UseLots, -1) = 1
	|	AND ISNULL(LineItems.Product.UseSerialNumbersOnGoodsReception, False)
	|ORDER BY
	|	SerialNumbers.LineNumber";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_InventoryJournal_LineItems(TablesList)
	
	// Add InventoryJournal - line items table to document structure.
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
	|	SUM(LineItems.QtyUM)                     AS QuantityRequested,
	|	SUM(LineItems.LineTotal)                 AS AmountRequested
	// ------------------------------------------------------
	|INTO
	|	Table_InventoryJournal_LineItems
	|FROM
	|	Document.ItemReceipt.LineItems AS LineItems
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
	|	SUM(LineItems.QtyUM)                     AS QuantityRequested,
	|	SUM(LineItems.LineTotal)                 AS AmountRequested
	// ------------------------------------------------------
	|FROM
	|	Document.ItemReceipt.LineItems AS LineItems
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
	|	SUM(LineItems.QtyUM)                     AS QuantityRequested,
	|	SUM(LineItems.LineTotal)                 AS AmountRequested
	// ------------------------------------------------------
	|FROM
	|	Document.ItemReceipt.LineItems AS LineItems
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
Function Query_InventoryJournal(TablesList)
	
	// Add InventoryJournal table to document structure.
	TablesList.Insert("Table_InventoryJournal", TablesList.Count());
	
	// Collect inventory data.
	QueryText =
	"SELECT // FIFO
	// ------------------------------------------------------
	// Standard attributes
	|	ItemReceipt.Ref                       AS Recorder,
	|	ItemReceipt.Date                      AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Dimensions
	|	LineItems_FIFO.Product                AS Product,
	|	LineItems_FIFO.Location               AS Location,
	|	ItemReceipt.Ref                       AS Layer,
	// ------------------------------------------------------
	// Resources
	|	LineItems_FIFO.QuantityRequested      AS Quantity,
	|	CAST( // Format(LineTotal * ExchangeRate, ""ND=17; NFD=2"")
	|		LineItems_FIFO.AmountRequested * ItemReceipt.ExchangeRate
	|		AS NUMBER (17, 2))                AS Amount
	// ------------------------------------------------------
	// Attributes
	// ------------------------------------------------------
	|FROM
	|	Table_InventoryJournal_LineItems AS LineItems_FIFO
	|	LEFT JOIN Document.ItemReceipt AS ItemReceipt
	|		ON True
	|WHERE
	|	ItemReceipt.Ref = &Ref
	|	AND LineItems_FIFO.Type = VALUE(Enum.InventoryCosting.FIFO)
	|	AND LineItems_FIFO.QuantityRequested > 0
	|
	|UNION ALL
	|
	|SELECT // WeightedAverage by quantity
	// ------------------------------------------------------
	// Standard attributes
	|	ItemReceipt.Ref                       AS Recorder,
	|	ItemReceipt.Date                      AS Period,
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
	|	LEFT JOIN Document.ItemReceipt AS ItemReceipt
	|		ON True
	|WHERE
	|	ItemReceipt.Ref = &Ref
	|	AND LineItems_WAve.Type      = VALUE(Enum.InventoryCosting.WeightedAverage)
	|	AND LineItems_WAve.Location <> VALUE(Catalog.Locations.EmptyRef)
	|	AND LineItems_WAve.QuantityRequested > 0
	|
	|UNION ALL
	|
	|SELECT // WeightedAverage by amount
	// ------------------------------------------------------
	// Standard attributes
	|	ItemReceipt.Ref                       AS Recorder,
	|	ItemReceipt.Date                      AS Period,
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
	|	CAST( // Format(LineTotal * ExchangeRate, ""ND=17; NFD=2"")
	|		LineItems_WAve.AmountRequested * ItemReceipt.ExchangeRate
	|		AS NUMBER (17, 2))                AS Amount
	// ------------------------------------------------------
	// Attributes
	// ------------------------------------------------------
	|FROM
	|	Table_InventoryJournal_LineItems AS LineItems_WAve
	|	LEFT JOIN Document.ItemReceipt AS ItemReceipt
	|		ON True
	|WHERE
	|	ItemReceipt.Ref = &Ref
	|	AND LineItems_WAve.Type     = VALUE(Enum.InventoryCosting.WeightedAverage)
	|	AND LineItems_WAve.Location = VALUE(Catalog.Locations.EmptyRef)
	|	AND LineItems_WAve.QuantityRequested > 0";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_GeneralJournal_LineItems(TablesList)
	
	// Add GeneralJournal requested items table to document structure.
	TablesList.Insert("Table_GeneralJournal_LineItems", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT
	// ------------------------------------------------------
	// Dimensions
	|	LineItems.Product.COGSAccount               AS COGSAccount,
	|	LineItems.Product.InventoryOrExpenseAccount AS InvOrExpAccount,
	|	Constants.OCLAccount                        AS OCLAccount,
	// ------------------------------------------------------
	// Resources
	|	LineItems.LineTotal                         AS Amount
	// ------------------------------------------------------
	|INTO
	|	Table_GeneralJournal_LineItems
	|FROM
	|	Document.ItemReceipt.LineItems AS LineItems
	|		LEFT JOIN Constants AS Constants
	|		ON (TRUE)
	|WHERE
	|	LineItems.Ref = &Ref
	|   AND LineItems.Product.Type = VALUE(Enum.InventoryTypes.Inventory)";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_GeneralJournal_Accounts_InvOrExp(TablesList)
	
	// Add GeneralJournal inventory or expenses accounts table to document structure.
	TablesList.Insert("Table_GeneralJournal_Accounts_InvOrExp", TablesList.Count());
	
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
	|	Table_GeneralJournal_Accounts_InvOrExp
	|FROM
	|	Table_GeneralJournal_LineItems AS Accounts
	|GROUP BY
	|	Accounts.InvOrExpAccount";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_GeneralJournal_Accounts_OCL(TablesList)
	
	// Add GeneralJournal other current liability account table to document structure.
	TablesList.Insert("Table_GeneralJournal_Accounts_OCL", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // OCL account selection
	// ------------------------------------------------------
	// Dimensions
	|	Accounts.OCLAccount                   AS OCLAccount,
	// ------------------------------------------------------
	// Resources
	|	SUM(Accounts.Amount)                  AS Amount
	// ------------------------------------------------------
	|INTO
	|	Table_GeneralJournal_Accounts_OCL
	|FROM
	|	Table_GeneralJournal_LineItems AS Accounts
	|GROUP BY
	|	Accounts.OCLAccount";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_GeneralJournal(TablesList)
	
	// Add GeneralJournal table to document structure.
	TablesList.Insert("Table_GeneralJournal", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // Dr: Inventory
	// ------------------------------------------------------
	// Standard attributes
	|	ItemReceipt.Ref                       AS Recorder,
	|	ItemReceipt.Date                      AS Period,
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
	|	CAST( // Format(Amount * ExchangeRate, ""ND=17; NFD=2"")
	|		InvOrExp.Amount *
	|		CASE WHEN ItemReceipt.ExchangeRate > 0
	|			 THEN ItemReceipt.ExchangeRate
	|			 ELSE 1 END
	|		AS NUMBER (17, 2))                AS AmountRC,
	// ------------------------------------------------------
	// Attributes
	|	NULL                                  AS Memo
	// ------------------------------------------------------
	|FROM
	|	Table_GeneralJournal_Accounts_InvOrExp AS InvOrExp
	|	LEFT JOIN Document.ItemReceipt AS ItemReceipt
	|		ON True
	|WHERE
	|	ItemReceipt.Ref = &Ref
	|	AND // Amount > 0
	|		InvOrExp.Amount > 0
	|
	|UNION ALL
	|
	|SELECT // Cr: OCL
	// ------------------------------------------------------
	// Standard attributes
	|	ItemReceipt.Ref                       AS Recorder,
	|	ItemReceipt.Date                      AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccountingRecordType.Credit)    AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Accounting attributes
	|	OCL.OCLAccount                        AS Account,
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
	|	CAST( // Format(Amount * ExchangeRate, ""ND=17; NFD=2"")
	|		OCL.Amount *
	|		CASE WHEN ItemReceipt.ExchangeRate > 0
	|			 THEN ItemReceipt.ExchangeRate
	|			 ELSE 1 END
	|		AS NUMBER (17, 2))                AS AmountRC,
	// ------------------------------------------------------
	// Attributes
	|	NULL                                  AS Memo
	// ------------------------------------------------------
	|FROM
	|	Table_GeneralJournal_Accounts_OCL AS OCL
	|	LEFT JOIN Document.ItemReceipt AS ItemReceipt
	|		ON True
	|WHERE
	|	ItemReceipt.Ref = &Ref
	|	AND // Amount > 0
	|		OCL.Amount > 0";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Put structure of registers, which balance should be checked during posting.
Procedure FillRegistersCheckList(AdditionalProperties, RegisterRecords)
	
	// Create structure of registers and its resources to check balances.
	BalanceCheck = New Structure;
	
	// Fill structure depending on document write mode.
	If AdditionalProperties.Posting.WriteMode = DocumentWriteMode.Posting Then
		
		// OrdersDispatched
		
		//// Add resources for check changes in recordset.
		//CheckPostings = New Array;
		//CheckPostings.Add("{Table}.ReceivedIR{Posting}, <, 0"); // Check decreasing ReceivedIR.
		//
		//// Add resources for check register balances.
		//CheckBalances = New Array;
		//CheckBalances.Add("{Table}.ReceivedIR{Balance}, <, {Table}.Invoiced{Balance}"); // Check over-invoiced balance.
		//
		//// Add messages for different error situations.
		//CheckMessages = New Array;
		//CheckMessages.Add(NStr("en = '{Product}:
		//							 |Order quantity {ReceivedIR} is lower then invoiced quantity {Invoiced}'")); // Over-invoiced balance.
		//
		//// Add register to check it's recordset changes and balances during posting.
		//BalanceCheck.Insert("OrdersDispatched", New Structure("CheckPostings, CheckBalances, CheckMessages", CheckPostings, CheckBalances, CheckMessages));
		
		// InventoryJournal
		
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
		
		// Add register to check it's recordset changes and balances during posting.
		BalanceCheck.Insert("InventoryJournal", New Structure("CheckPostings, CheckBalances, CheckMessages", CheckPostings, CheckBalances, CheckMessages));
		
		// Lots
		
		// Add resources for check changes in recordset.
		CheckPostings = New Array;
		CheckPostings.Add("{Table}.Quantity{Posting}, <, 0"); // Check decreasing quantity.
		
		// Add resources for check register balances.
		CheckBalances = New Array;
		CheckBalances.Add("{Table}.Quantity{Balance}, <, 0"); // Check negative lots balance.
		
		// Add messages for different error situations.
		CheckMessages = New Array;
		CheckMessages.Add(NStr("en = '{Product}?{Lot}:
		                             |There is an insufficient balance of {-Quantity} at the {Location}.|Lot = "", lot {Lot}""'"));
		
		// Add register to check it's recordset changes and balances during posting.
		BalanceCheck.Insert("Lots", New Structure("CheckPostings, CheckBalances, CheckMessages", CheckPostings, CheckBalances, CheckMessages));
		
	ElsIf AdditionalProperties.Posting.WriteMode = DocumentWriteMode.UndoPosting Then
		
		// OrdersDispatched
		
		//// Add resources for check changes in recordset.
		//CheckPostings = New Array;
		//CheckPostings.Add("{Table}.ReceivedIR{Posting}, <, 0"); // Check decreasing ReceivedIR.
		//
		//// Add resources for check register balances.
		//CheckBalances = New Array;
		//CheckBalances.Add("{Table}.ReceivedIR{Balance}, <, {Table}.Invoiced{Balance}"); // Check over-invoiced balance.
		//
		//// Add messages for different error situations.
		//CheckMessages = New Array;
		//CheckMessages.Add(NStr("en = '{Product}:
		//							 |{Invoiced} items already invoiced'")); // Over-invoiced balance.
		//
		//// Add registers to check it's recordset changes and balances during undo posting.
		//BalanceCheck.Insert("OrdersDispatched", New Structure("CheckPostings, CheckBalances, CheckMessages", CheckPostings, CheckBalances, CheckMessages));
		
		// InventoryJournal
		
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
		
		// Lots
		
		// Add resources for check changes in recordset.
		CheckPostings = New Array;
		CheckPostings.Add("{Table}.Quantity{Posting}, <, 0"); // Check decreasing quantity.
		
		// Add resources for check register balances.
		CheckBalances = New Array;
		CheckBalances.Add("{Table}.Quantity{Balance}, <, 0"); // Check negative lots balance.
		
		// Add messages for different error situations.
		CheckMessages = New Array;
		CheckMessages.Add(NStr("en = '{Product}?{Lot}:
		                             |There is an insufficient balance of {-Quantity} at the {Location}.|Lot = "", lot {Lot}""'"));
		
		// Add register to check it's recordset changes and balances during posting.
		BalanceCheck.Insert("Lots", New Structure("CheckPostings, CheckBalances, CheckMessages", CheckPostings, CheckBalances, CheckMessages));
	EndIf;
	
	// Return structure of registers to check.
	If BalanceCheck.Count() > 0 Then
		AdditionalProperties.Posting.Insert("BalanceCheck", BalanceCheck);
	EndIf;
	
EndProcedure

//------------------------------------------------------------------------------
// Document filling

// Query for document filling.
Function Query_Filling_Document_PurchaseOrder_Attributes(TablesList)
	
	// Add Attributes table to document structure.
	TablesList.Insert("Table_Document_PurchaseOrder_Attributes", TablesList.Count());
	
	// Collect attributes data.
	QueryText =
		"SELECT
		|	PurchaseOrder.Ref                       AS FillingData,
		|	PurchaseOrder.Company                   AS Company,
		|	PurchaseOrder.CompanyAddress            AS CompanyAddress,
		|	PurchaseOrder.Currency                  AS Currency,
		|	PurchaseOrder.ExchangeRate              AS ExchangeRate,
		|	CASE
		|		WHEN PurchaseOrder.Company.Terms.Days IS NULL THEN DATEADD(&Date, DAY, 14)
		|		WHEN PurchaseOrder.Company.Terms.Days = 0     THEN DATEADD(&Date, DAY, 14)
		|		ELSE                                               DATEADD(&Date, DAY, PurchaseOrder.Company.Terms.Days)
		|	END                                     AS DueDate,
		|	PurchaseOrder.Location                  AS Location,
		|	PurchaseOrder.DeliveryDate              AS DeliveryDate,
		|	PurchaseOrder.Project                   AS Project,
		|	PurchaseOrder.Class                     AS Class
		|INTO
		|	Table_Document_PurchaseOrder_Attributes
		|FROM
		|	Document.PurchaseOrder AS PurchaseOrder
		|WHERE
		|	PurchaseOrder.Ref IN (&FillingData_Document_PurchaseOrder)";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document filling.
Function Query_Filling_Document_PurchaseOrder_OrdersStatuses(TablesList)
	
	// Add OrdersStatuses table to document structure.
	TablesList.Insert("Table_Document_PurchaseOrder_OrdersStatuses", TablesList.Count());
	
	// Collect orders statuses data.
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

// Query for document filling.
Function Query_Filling_Document_PurchaseOrder_OrdersDispatched(TablesList)
	
	// Add OrdersDispatched table to document structure.
	TablesList.Insert("Table_Document_PurchaseOrder_OrdersDispatched", TablesList.Count());
	
	// Collect orders items data.
	QueryText =
		"SELECT
		// ------------------------------------------------------
		// Dimensions
		|	OrdersDispatchedBalance.Company          AS Company,
		|	OrdersDispatchedBalance.Order            AS Order,
		|	OrdersDispatchedBalance.Product          AS Product,
		|	OrdersDispatchedBalance.Unit             AS Unit,
		|	OrdersDispatchedBalance.Location         AS Location,
		|	OrdersDispatchedBalance.DeliveryDate     AS DeliveryDate,
		|	OrdersDispatchedBalance.Project          AS Project,
		|	OrdersDispatchedBalance.Class            AS Class,
		// ------------------------------------------------------
		// Resources                                                                                                          // ---------------------------------------
		|	OrdersDispatchedBalance.QuantityBalance  AS Quantity,                                                             // Backorder quantity calculation
		|	CASE                                                                                                              // ---------------------------------------
		|		WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Open)        THEN 0                                     // Order status = Open:
		|		WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Backordered) THEN                                       //   Backorder = 0
		|			 CASE                                                                                                     // Order status = Backorder:    
		|				 WHEN OrdersDispatchedBalance.QuantityBalance > OrdersDispatchedBalance.ReceivedIRBalance             //     |
		|				 THEN OrdersDispatchedBalance.QuantityBalance - OrdersDispatchedBalance.ReceivedIRBalance             //   Backorder = Ordered - ReceivedIR >= 0
		|			 ELSE 0 END                                                                                               //     |
		|		WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Closed)      THEN 0                                     // Order status = Closed:
		|		ELSE 0                                                                                                        //   Backorder = 0
		|		END                                  AS Backorder
		// ------------------------------------------------------
		|INTO
		|	Table_Document_PurchaseOrder_OrdersDispatched
		|FROM
		|	AccumulationRegister.OrdersDispatched.Balance(,
		|		(Company, Order, Product, Unit, Location, DeliveryDate, Project, Class) IN
		|			(SELECT
		|				PurchaseOrderLineItems.Ref.Company,
		|				PurchaseOrderLineItems.Ref,
		|				PurchaseOrderLineItems.Product,
		|				PurchaseOrderLineItems.Unit,
		|				PurchaseOrderLineItems.Location,
		|				PurchaseOrderLineItems.DeliveryDate,
		|				PurchaseOrderLineItems.Project,
		|				PurchaseOrderLineItems.Class
		|			FROM
		|				Document.PurchaseOrder.LineItems AS PurchaseOrderLineItems
		|			WHERE
		|				PurchaseOrderLineItems.Ref IN (&FillingData_Document_PurchaseOrder))) AS OrdersDispatchedBalance
		|	LEFT JOIN Table_Document_PurchaseOrder_OrdersStatuses AS OrdersStatuses
		|		ON OrdersDispatchedBalance.Order = OrdersStatuses.Order";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document filling.
Function Query_Filling_Document_PurchaseOrder_LineItems(TablesList)
	
	// Add LineItems table to document structure.
	TablesList.Insert("Table_Document_PurchaseOrder_LineItems", TablesList.Count());
	
	// Collect line items data.
	QueryText =
		"SELECT
		|	PurchaseOrderLineItems.Ref                 AS FillingData,
		|	PurchaseOrderLineItems.Product             AS Product,
		|	PurchaseOrderLineItems.ProductDescription  AS ProductDescription,
		|	PurchaseOrderLineItems.UnitSet             AS UnitSet,
		|	PurchaseOrderLineItems.Unit                AS Unit,
		|	CASE
		|		WHEN PurchaseOrderLineItems.Product.PricePrecision = 3
		|			THEN CAST(PurchaseOrderLineItems.PriceUnits AS NUMBER(17, 3))
		|		WHEN PurchaseOrderLineItems.Product.PricePrecision = 4
		|			THEN CAST(PurchaseOrderLineItems.PriceUnits AS NUMBER(17, 4))
		|		ELSE CAST(PurchaseOrderLineItems.PriceUnits AS NUMBER(17, 2))
		|	END                                        AS PriceUnits,
		|	
		|	// QtyUnits
		|	CASE
		|		WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Open)
		|			THEN ISNULL(OrdersDispatched.Quantity, PurchaseOrderLineItems.QtyUnits)
		|		WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Backordered)
		|			THEN ISNULL(OrdersDispatched.Backorder, PurchaseOrderLineItems.QtyUnits)
		|		WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Closed)
		|			THEN ISNULL(OrdersDispatched.Backorder, 0)
		|		ELSE 0
		|	END                                        AS QtyUnits,
		|	
		|	// QtyUM
		|	CAST( // Format(Quantity * Unit.Factor, ""ND=15; NFD={4}"")
		|		CASE
		|			WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Open)
		|				THEN ISNULL(OrdersDispatched.Quantity, PurchaseOrderLineItems.QtyUnits)
		|			WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Backordered)
		|				THEN ISNULL(OrdersDispatched.Backorder, PurchaseOrderLineItems.QtyUnits)
		|			WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Closed)
		|				THEN ISNULL(OrdersDispatched.Backorder, 0)
		|			ELSE 0
		|		END * 
		|		CASE
		|			WHEN PurchaseOrderLineItems.Unit.Factor > 0
		|				THEN PurchaseOrderLineItems.Unit.Factor
		|			ELSE 1
		|		END
		|		AS NUMBER (15, {QuantityPrecision}))   AS QtyUM,
		|	
		|	// LineTotal
		|	CAST( // Format(Quantity * Price, ""ND=17; NFD=2"")
		|		CASE
		|			WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Open)
		|				THEN ISNULL(OrdersDispatched.Quantity, PurchaseOrderLineItems.QtyUnits)
		|			WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Backordered)
		|				THEN ISNULL(OrdersDispatched.Backorder, PurchaseOrderLineItems.QtyUnits)
		|			WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Closed)
		|				THEN ISNULL(OrdersDispatched.Backorder, 0)
		|			ELSE 0
		|		END * CASE
		|			WHEN PurchaseOrderLineItems.Product.PricePrecision = 3
		|				THEN CAST(PurchaseOrderLineItems.PriceUnits AS NUMBER(17, 3))
		|			WHEN PurchaseOrderLineItems.Product.PricePrecision = 4
		|				THEN CAST(PurchaseOrderLineItems.PriceUnits AS NUMBER(17, 4))
		|			ELSE CAST(PurchaseOrderLineItems.PriceUnits AS NUMBER(17, 2))
		|		END AS NUMBER (17, 2))                 AS LineTotal,
		|	
		|	PurchaseOrderLineItems.Ref                 AS Order,
		|	PurchaseOrderLineItems.Location            AS LocationOrder,
		|	PurchaseOrderLineItems.Location            AS Location,
		|	PurchaseOrderLineItems.DeliveryDate        AS DeliveryDateOrder,
		|	PurchaseOrderLineItems.DeliveryDate        AS DeliveryDate,
		|	PurchaseOrderLineItems.Project             AS Project,
		|	PurchaseOrderLineItems.Class               AS Class,
		|	PurchaseOrderLineItems.Ref.Company         AS Company
		|INTO
		|	Table_Document_PurchaseOrder_LineItems
		|FROM
		|	Document.PurchaseOrder.LineItems AS PurchaseOrderLineItems
		|	LEFT JOIN Table_Document_PurchaseOrder_OrdersDispatched AS OrdersDispatched
		|		ON  OrdersDispatched.Company      = PurchaseOrderLineItems.Ref.Company
		|		AND OrdersDispatched.Order        = PurchaseOrderLineItems.Ref
		|		AND OrdersDispatched.Product      = PurchaseOrderLineItems.Product
		|		AND OrdersDispatched.Unit         = PurchaseOrderLineItems.Unit
		|		AND OrdersDispatched.Location     = PurchaseOrderLineItems.Location
		|		AND OrdersDispatched.DeliveryDate = PurchaseOrderLineItems.DeliveryDate
		|		AND OrdersDispatched.Project      = PurchaseOrderLineItems.Project
		|		AND OrdersDispatched.Class        = PurchaseOrderLineItems.Class
		|	LEFT JOIN Table_Document_PurchaseOrder_OrdersStatuses AS OrdersStatuses
		|		ON OrdersStatuses.Order = PurchaseOrderLineItems.Ref
		|WHERE
		|	PurchaseOrderLineItems.Ref IN (&FillingData_Document_PurchaseOrder)"; 
		
	// Update query rounding using quantity precision.
	QueryText = StrReplace(QueryText, "{QuantityPrecision}", GeneralFunctionsReusable.DefaultQuantityPrecision());
	
	// Return text of query
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document filling.
Function Query_Filling_Document_PurchaseOrder_Totals(TablesList)
	
	// Add Totals table to document structure.
	TablesList.Insert("Table_Document_PurchaseOrder_Totals", TablesList.Count());
	
	// Collect totals data.
	QueryText =
		"SELECT
		// Totals of document
		|	PurchaseOrderLineItems.FillingData      AS FillingData,
		|
		|	// Total(LineTotal)
		|	SUM(PurchaseOrderLineItems.LineTotal)   AS DocumentTotal,
		|
		|	CAST( // Format(DocumentTotal * ExchangeRate, ""ND=17; NFD=2"")
		|		SUM(PurchaseOrderLineItems.LineTotal) * // Total(LineTotal)
		|		PurchaseOrder.ExchangeRate
		|		AS NUMBER (17, 2))                  AS DocumentTotalRC
		|
		|INTO
		|	Table_Document_PurchaseOrder_Totals
		|FROM
		|	Table_Document_PurchaseOrder_LineItems AS PurchaseOrderLineItems
		|	LEFT JOIN Table_Document_PurchaseOrder_Attributes AS PurchaseOrder
		|		ON PurchaseOrder.FillingData = PurchaseOrderLineItems.FillingData
		|GROUP BY
		|	PurchaseOrderLineItems.FillingData,
		|	PurchaseOrder.ExchangeRate";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document filling.
Function Query_Filling_Attributes(TablesList)
	
	// Add Attributes table to document structure.
	TablesList.Insert("Table_Attributes", TablesList.Count());
	
	// Fill data from attributes and totals.
	QueryText = "";
	
	// Fill from purchase orders.
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
		|	Document_PurchaseOrder_Attributes.CompanyAddress,
		|	Document_PurchaseOrder_Attributes.Currency,
		|	Document_PurchaseOrder_Attributes.ExchangeRate,
		|	Document_PurchaseOrder_Attributes.DueDate,
		|	Document_PurchaseOrder_Attributes.Location,
		|	Document_PurchaseOrder_Attributes.DeliveryDate,
		|	Document_PurchaseOrder_Attributes.Project,
		|	Document_PurchaseOrder_Attributes.Class,
		|	Document_PurchaseOrder_Totals.DocumentTotal,
		|	Document_PurchaseOrder_Totals.DocumentTotalRC
		|{Into}
		|FROM
		|	Table_Document_PurchaseOrder_Attributes AS Document_PurchaseOrder_Attributes
		|	LEFT JOIN Table_Document_PurchaseOrder_Totals AS Document_PurchaseOrder_Totals
		|		ON Document_PurchaseOrder_Totals.FillingData = Document_PurchaseOrder_Attributes.FillingData";
		
		// Add selection to a query.
		QueryText = QueryText + StrReplace(SelectionText, "{Into}",
		?(IsBlankString(QueryText), 
		"INTO
		|	Table_Attributes",
		""));
	EndIf;
	
	// Fill data from next source.
	// ---------------------------
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document filling.
Function Query_Filling_LineItems(TablesList)
	
	// Add LineItems table to document structure.
	TablesList.Insert("Table_LineItems", TablesList.Count());
	
	// Fill data from attributes and totals.
	QueryText = "";
	
	// Fill from purchase orders.
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
		|	Document_PurchaseOrder_LineItems.UnitSet,
		|	Document_PurchaseOrder_LineItems.QtyUnits,
		|	Document_PurchaseOrder_LineItems.Unit,
		|	Document_PurchaseOrder_LineItems.QtyUM,
		|	Document_PurchaseOrder_LineItems.PriceUnits,
		|	Document_PurchaseOrder_LineItems.LineTotal,
		|	Document_PurchaseOrder_LineItems.LocationOrder,
		|	Document_PurchaseOrder_LineItems.Location,
		|	Document_PurchaseOrder_LineItems.DeliveryDateOrder,
		|	Document_PurchaseOrder_LineItems.DeliveryDate,
		|	Document_PurchaseOrder_LineItems.Project,
		|	Document_PurchaseOrder_LineItems.Class,
		|	Document_PurchaseOrder_LineItems.Order
		|{Into}
		|FROM
		|	Table_Document_PurchaseOrder_LineItems AS Document_PurchaseOrder_LineItems
		|WHERE
		|	Document_PurchaseOrder_LineItems.QtyUnits > 0";
		
		// Add selection to a query.
		QueryText = QueryText + StrReplace(SelectionText, "{Into}",
		?(IsBlankString(QueryText), 
		"INTO
		|	Table_LineItems",
		""));
	EndIf;
	
	// Fill data from next source.
	// ---------------------------
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Fill structure of attributes, which should be checked during filling.
Function FillingCheckList(AdditionalProperties)
	
	// Create structure of registers and its resources to check balances.
	CheckAttributes = New Structure;
	// Group by attributes to check uniqueness.
	CheckAttributes.Insert("Company",         "Check");
	CheckAttributes.Insert("Currency",        "Check");
	CheckAttributes.Insert("ExchangeRate",    "Check");
	// Maximal possible values.
	CheckAttributes.Insert("DueDate",         "Max");
	CheckAttributes.Insert("DeliveryDate",    "Max");
	// Summarize totals.
	CheckAttributes.Insert("DocumentTotal",   "Sum");
	CheckAttributes.Insert("DocumentTotalRC", "Sum");
	
	// Save structure of attributes to check.
	If CheckAttributes.Count() > 0 Then
		AdditionalProperties.Filling.Insert("CheckAttributes", CheckAttributes);
	EndIf;
	
	// Return saved structure.
	Return CheckAttributes;
	
EndFunction

// Query for document filling.
Function Query_Filling_Check(TablesList, CheckAttributes)
	
	// Check attributes to be checked.
	If CheckAttributes.Count() = 0 Then
		Return "";
	EndIf;
	
	// Add Attributes table to document structure.
	TablesList.Insert("Table_Check", TablesList.Count());
	
	// Fill data from attributes and totals.
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
			// Attributes - uniqueness check.
			DimensionText = StrReplace("Attributes.{Attribute} AS {Attribute}", "{Attribute}", Attribute.Key);
			SelectionText = ?(IsBlankString(SelectionText), DimensionText, SelectionText+",
				|	"+DimensionText);
			// Group by section.
			DimensionText = StrReplace("Attributes.{Attribute}", "{Attribute}", Attribute.Key);
			GroupByText   = ?(IsBlankString(GroupByText), DimensionText, GroupByText+",
				|	"+DimensionText);
		Else
			// Agregate function.
			If Find(Attribute.Value, "(") > 0 Then
				// Agregate function with custom declaration.
				AggregationText = StrReplace(Attribute.Value + " AS {Attribute}", "{Attribute}", Attribute.Key);
			Else
				// Attribute agregate function.
				AggregationText = StrReplace(Upper(Attribute.Value)+"(Attributes.{Attribute}) AS {Attribute}", "{Attribute}", Attribute.Key);
			EndIf;
			SelectionText = ?(IsBlankString(SelectionText), AggregationText, SelectionText+",
				|	"+AggregationText);
		EndIf;
	EndDo;
	QueryText = StrReplace(QueryText, "{Selection}", SelectionText);
	QueryText = StrReplace(QueryText, "{GroupBy}",   GroupByText);
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

#EndIf

#EndRegion
