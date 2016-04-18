
////////////////////////////////////////////////////////////////////////////////
// Shipment: Manager module
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
		             Query_OrdersRegistered_Lock(LocksList);
	EndIf;
	Query.Text = Query.Text +
	             Query_InventoryJournal_Lock(LocksList);
	
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
		             Query_OrdersRegistered_Balance(BalancesList);
	EndIf;
	Query.Text = Query.Text +
	             Query_InventoryJournal_Balance(BalancesList);
	
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
	OrdersPosting    = AdditionalProperties.Orders.Count() > 0;
	
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
	If OrdersPosting Then
		Query.Text = Query.Text +
					 Query_OrdersStatuses(TablesList) +
					 Query_OrdersRegistered(TablesList);
	EndIf;
	Query.Text = Query.Text +
				 Query_Lots(TablesList) +
				 Query_SerialNumbers(TablesList) +
				 Query_InventoryJournal_LineItems(TablesList) +
				 Query_InventoryJournal_Balance_Quantity(TablesList) +
				 Query_InventoryJournal_Balance_FIFO(TablesList) +
				 Query_InventoryJournal(TablesList) +
				 Query_GeneralJournal_ProductCost(TablesList) +
				 Query_GeneralJournal_ProductCost_Total(TablesList) +
				 Query_GeneralJournal_LineItems(TablesList) +
				 Query_GeneralJournal_Accounts_COGS_Quantity(TablesList) +
				 Query_GeneralJournal_Accounts_COGS_Amount(TablesList) +
				 Query_GeneralJournal_Accounts_COGS(TablesList) +
				 Query_GeneralJournal_Accounts_InvOrExp_Quantity(TablesList) +
				 Query_GeneralJournal_Accounts_InvOrExp_Amount(TablesList) +
				 Query_GeneralJournal_Accounts_InvOrExp(TablesList) +
				 Query_GeneralJournal(TablesList) +
	             //--//GJ++
	             Query_GeneralJournalAnalyticsDimensions_Accounts_COGS_Quantity(TablesList) +
	             Query_GeneralJournalAnalyticsDimensions_Accounts_COGS_Amount(TablesList) +
	             Query_GeneralJournalAnalyticsDimensions_Accounts_COGS(TablesList) +
	             Query_GeneralJournalAnalyticsDimensions_Accounts_COGS_Difference_Amount(TablesList) +
	             Query_GeneralJournalAnalyticsDimensions_Accounts_COGS_Difference(TablesList) +
	             Query_GeneralJournalAnalyticsDimensions_Accounts_InvOrExp_Quantity(TablesList) +
	             Query_GeneralJournalAnalyticsDimensions_Accounts_InvOrExp_Amount(TablesList) +
	             Query_GeneralJournalAnalyticsDimensions_Accounts_InvOrExp(TablesList) +
	             Query_GeneralJournalAnalyticsDimensions_Accounts_InvOrExp_Difference_Amount(TablesList) +
	             Query_GeneralJournalAnalyticsDimensions_Accounts_InvOrExp_Difference(TablesList) +
				 Query_GeneralJournalAnalyticsDimensions_Transactions(TablesList) +
	             Query_GeneralJournalAnalyticsDimensions(TablesList) +
	             //--//GJ--
				 Query_CashFlowData(TablesList);
				 
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

// Check proper closing of order items by the shipment items.
Procedure CheckOrderQuantity(DocumentRef, DocumentDate, Company, LineItems, Cancel) Export
	ErrorsCount = 0;
	MessageText = "";
	
	// 1. Create a query to request data.
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Date", DocumentDate);
	
	// 2. Fill out the line items table.
	ShipmentLineItems = LineItems.Unload(, "LineNumber, Order, Product, Unit, Location, DeliveryDate, Project, Class, QtyUnits");
	ShipmentLineItems.Columns.Insert(1, "Company", New TypeDescription("CatalogRef.Companies"), "", 20);
	ShipmentLineItems.FillValues(Company, "Company");
	DocumentPosting.PutTemporaryTable(ShipmentLineItems, "ShipmentLineItems", Query.TempTablesManager);
	
	// 3. Request uninvoiced items for each line item.
	Query.Text = "
		|SELECT
		|	LineItems.LineNumber          AS LineNumber,
		|	LineItems.Order               AS Order,
		|	LineItems.Product.Code        AS ProductCode,
		|	LineItems.Product.Description AS ProductDescription,
		|	OrdersRegisteredBalance.QuantityBalance - OrdersRegisteredBalance.ShippedShipmentBalance - LineItems.QtyUnits AS UninvoicedQuantity
		|FROM
		|	ShipmentLineItems AS LineItems
		|	LEFT JOIN AccumulationRegister.OrdersRegistered.Balance(&Date, (Company, Order, Product, Unit, Location, DeliveryDate, Project, Class)
		|		   IN (SELECT Company, Order, Product, Unit, Location, DeliveryDate, Project, Class FROM ShipmentLineItems)) AS OrdersRegisteredBalance
		|		ON  LineItems.Company      = OrdersRegisteredBalance.Company
		|		AND LineItems.Order        = OrdersRegisteredBalance.Order
		|		AND LineItems.Product      = OrdersRegisteredBalance.Product
		|		AND LineItems.Unit         = OrdersRegisteredBalance.Unit
		|		AND LineItems.Location     = OrdersRegisteredBalance.Location
		|		AND LineItems.DeliveryDate = OrdersRegisteredBalance.DeliveryDate
		|		AND LineItems.Project      = OrdersRegisteredBalance.Project
		|		AND LineItems.Class        = OrdersRegisteredBalance.Class
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
				                            NStr("en = 'The shipped quantity of product %1 in line %2 exceeds ordered quantity in %3.'"), TrimAll(Row.ProductCode) + " " + TrimAll(Row.ProductDescription), Row.LineNumber, Row.Order);
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
		If FillingData.Key = "Document_SalesOrder" Then
			Query.Text = Query.Text +
			             Query_Filling_Document_SalesOrder_Attributes(TablesList) +
			             Query_Filling_Document_SalesOrder_CommonTotals(TablesList) +
			             Query_Filling_Document_SalesOrder_OrdersStatuses(TablesList) +
			             Query_Filling_Document_SalesOrder_OrdersRegistered(TablesList) +
			             Query_Filling_Document_SalesOrder_LineItems(TablesList) +
			             Query_Filling_Document_SalesOrder_Totals(TablesList);
			
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
	
	If GeneralFunctionsReusable.FunctionalOptionValue("SalesTaxCharging") Then
		Query.Text = Query.Text + Query_Filling_SalesTaxAcrossAgencies(TablesList);			 
	EndIf;
	
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

// Check status of passed sales order by ref.
// Returns True if status passed for shipment filling.
Function CheckStatusOfSalesOrder(DocumentRef, FillingRef) Export
	
	// Create new query.
	Query = New Query;
	Query.SetParameter("Ref", FillingRef);
	
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
		MessageText = NStr("en = 'Failed to generate the %1 on the base of %2 %3.'");
		MessageText = StringFunctionsClientServer.SubstituteParametersInString(MessageText,
		                                                                       Lower(Metadata.FindByType(TypeOf(DocumentRef)).Presentation()),
		                                                                       Lower(OrderStatus),
		                                                                       Lower(Metadata.FindByType(TypeOf(FillingRef)).Presentation())); 
		CommonUseClientServer.MessageToUser(MessageText, FillingRef);
	EndIf;
	
	Return StatusOK;
	
EndFunction

// Check "Use Shipment" of passed sales order by ref. 
Function CheckUseShipmentOfSalesOrder(DocumentRef, FillingRef) Export
	
	StatusOK = FillingRef.UseShipment;
	
	If Not StatusOK Then
		MessageText = NStr("en = 'Failed to generate the %1 because %2 does not use Shipment.'");
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

//------------------------------------------------------------------------------
// Document printing

Procedure Print(Spreadsheet, SheetTitle, Ref, TemplateName = Undefined) Export
	PrintFormFunctions.PrintShipment(Spreadsheet, SheetTitle, Ref, TemplateName); 	  
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
	|	0                                     AS LineNumber,
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
	|	Document.Shipment.LineItems AS LineItems
	|WHERE
	|	LineItems.Ref = &Ref
	|	AND LineItems.Order <> VALUE(Document.SalesOrder.EmptyRef)
	|
	|UNION ALL
	|
	|SELECT
	// ------------------------------------------------------
	// Standard attributes
	|	Document.Ref                          AS Recorder,
	|	Document.Date                         AS Period,
	|	0                                     AS LineNumber,
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
	|	Document.Shipment AS Document
	|WHERE
	|	Document.Ref = &Ref
	|ORDER BY
	|	Order";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_OrdersRegistered(TablesList)
	
	// Add OrdersRegistered table to document structure.
	TablesList.Insert("Table_OrdersRegistered", TablesList.Count());
	
	// Collect orders registered data.
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
	|	LineItems.Ref                         AS Shipment,
	|	LineItems.Product                     AS Product,
	|	LineItems.Unit                        AS Unit,
	|	LineItems.Location                    AS Location,
	|	LineItems.DeliveryDate                AS DeliveryDate,
	|	LineItems.Project                     AS Project,
	|	LineItems.Class                       AS Class,
	// ------------------------------------------------------
	// Resources
	|	0                                     AS Quantity,
	|	CASE
	|		WHEN LineItems.Product.Type = VALUE(Enum.InventoryTypes.Inventory)
	|			THEN LineItems.QtyUnits
	|       ELSE 0
	|   END                                   AS Shipped,
	|	LineItems.QtyUnits                    AS ShippedShipment,
	|	0                                     AS Invoiced
	// ------------------------------------------------------
	// Attributes
	// ------------------------------------------------------
	|FROM
	|	Document.Shipment.LineItems AS LineItems
	|WHERE
	|	LineItems.Ref = &Ref
	|	AND LineItems.Order <> VALUE(Document.SalesOrder.EmptyRef)
	|ORDER BY
	|	LineNumber";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for dimensions lock data.
Function Query_OrdersRegistered_Lock(TablesList)
	
	// Add OrdersRegistered - Lock table to locks structure.
	TablesList.Insert("AccumulationRegister_OrdersRegistered", TablesList.Count());
	
	// Collect dimensions for orders registered locking.
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
	|	LineItems.Order <> VALUE(Document.SalesOrder.EmptyRef)";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for balances data.
Function Query_OrdersRegistered_Balance(TablesList)
	
	// Add OrdersRegistered - Balances table to balances structure.
	TablesList.Insert("Table_OrdersRegistered_Balance", TablesList.Count());
	
	// Collect orders registered balances.
	QueryText =
	"SELECT
	// ------------------------------------------------------
	// Dimensions
	|	OrdersRegisteredBalance.Company                AS Company,
	|	OrdersRegisteredBalance.Order                  AS Order,
	|	OrdersRegisteredBalance.Shipment               AS Shipment,
	|	OrdersRegisteredBalance.Product                AS Product,
	|	OrdersRegisteredBalance.Unit                   AS Unit,
	|	OrdersRegisteredBalance.Location               AS Location,
	|	OrdersRegisteredBalance.DeliveryDate           AS DeliveryDate,
	|	OrdersRegisteredBalance.Project                AS Project,
	|	OrdersRegisteredBalance.Class                  AS Class,
	// ------------------------------------------------------
	// Resources
	|	OrdersRegisteredBalance.QuantityBalance        AS Quantity,
	|	OrdersRegisteredBalance.ShippedBalance         AS Shipped,
	|	OrdersRegisteredBalance.ShippedShipmentBalance AS ShippedShipment,
	|	OrdersRegisteredBalance.InvoicedBalance        AS Invoiced
	// ------------------------------------------------------
	|FROM
	|	AccumulationRegister.OrdersRegistered.Balance(&PointInTime,
	|		(Company, Order) IN
	|		(SELECT DISTINCT &Company, LineItems.Order // Requred for proper order closing
	|		 FROM Table_LineItems AS LineItems)) AS OrdersRegisteredBalance";
	
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
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Dimensions
	|	LineItems.Product                     AS Product,
	|	LineItems.LocationActual              AS Location,
	|	LineItems.Lot                         AS Lot,
	// ------------------------------------------------------
	// Resources
	|	LineItems.QtyUM                       AS Quantity
	// ------------------------------------------------------
	// Attributes
	// ------------------------------------------------------
	|FROM
	|	Document.Shipment.LineItems AS LineItems
	|WHERE
	|	    LineItems.Ref = &Ref
	|	AND LineItems.Product  <> VALUE(Catalog.Products.EmptyRef)
	|	AND LineItems.Product.HasLotsSerialNumbers
	|	AND LineItems.Product.UseLots = 0
	|	AND LineItems.LocationActual <> VALUE(Catalog.Locations.EmptyRef)
	|	AND LineItems.Lot            <> VALUE(Catalog.Lots.EmptyRef)
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
	|	False                                 AS OnHand
	// ------------------------------------------------------
	// Attributes
	// ------------------------------------------------------
	|FROM
	|	Document.Shipment.SerialNumbers AS SerialNumbers
	|	LEFT JOIN Document.Shipment.LineItems AS LineItems
	|		ON  SerialNumbers.Ref             = LineItems.Ref
	|		AND SerialNumbers.LineItemsLineID = LineItems.LineID
	|WHERE
	|	    SerialNumbers.Ref = &Ref
	|	AND SerialNumbers.SerialNumber <> """"
	|	AND ISNULL(LineItems.Product, VALUE(Catalog.Products.EmptyRef)) <> VALUE(Catalog.Products.EmptyRef)
	|	AND ISNULL(LineItems.Product.HasLotsSerialNumbers, False)
	|	AND ISNULL(LineItems.Product.UseLots, -1) = 1
	|	AND ISNULL(LineItems.Product.UseSerialNumbersOnShipment, False)
	|ORDER BY
	|	SerialNumbers.LineNumber";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

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
	|	LineItems.LocationActual                 AS Location,
	// ------------------------------------------------------
	// Agregates
	|	SUM(LineItems.QtyUM)                     AS QuantityRequested
	// ------------------------------------------------------
	|INTO
	|	Table_InventoryJournal_LineItems
	|FROM
	|	Document.Shipment.LineItems AS LineItems
	|WHERE
	|	    LineItems.Ref                   = &Ref
	|	AND LineItems.Product.Type          = VALUE(Enum.InventoryTypes.Inventory)
	|	AND LineItems.Product.CostingMethod = VALUE(Enum.InventoryCosting.FIFO)
	|GROUP BY
	|	LineItems.Product.CostingMethod,
	|	LineItems.Product,
	|	LineItems.LocationActual
	|
	|UNION ALL
	|
	|SELECT // WAve for quantity calcualtion
	// ------------------------------------------------------
	// Dimensions
	|	LineItems.Product.CostingMethod          AS Type,
	|	LineItems.Product                        AS Product,
	|	LineItems.LocationActual                 AS Location,
	// ------------------------------------------------------
	// Agregates
	|	SUM(LineItems.QtyUM)                     AS QuantityRequested
	// ------------------------------------------------------
	|FROM
	|	Document.Shipment.LineItems AS LineItems
	|WHERE
	|	    LineItems.Ref                   = &Ref
	|	AND LineItems.Product.Type          = VALUE(Enum.InventoryTypes.Inventory)
	|	AND LineItems.Product.CostingMethod = VALUE(Enum.InventoryCosting.WeightedAverage)
	|GROUP BY
	|	LineItems.Product.CostingMethod,
	|	LineItems.Product,
	|	LineItems.LocationActual
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
	|	Document.Shipment.LineItems AS LineItems
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
Function Query_InventoryJournal(TablesList)
	
	// Add InventoryJournal table to document structure.
	TablesList.Insert("Table_InventoryJournal", TablesList.Count());
	
	// Collect inventory data.
	QueryText =
	"SELECT // FIFO normal balances
	// ------------------------------------------------------
	// Standard attributes
	|	Shipment.Ref                          AS Recorder,
	|	Shipment.Date                         AS Period,
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
	|	LEFT JOIN Document.Shipment AS Shipment
	|		ON True
	|WHERE
	|	Shipment.Ref = &Ref
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
	|	Shipment.Ref                          AS Recorder,
	|	Shipment.Date                         AS Period,
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
	|	LEFT JOIN Document.Shipment AS Shipment
	|		ON True
	|WHERE
	|	Shipment.Ref = &Ref
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
	|	Shipment.Ref                          AS Recorder,
	|	Shipment.Date                         AS Period,
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
	|	LEFT JOIN Document.Shipment AS Shipment
	|		ON True
	|WHERE
	|	Shipment.Ref = &Ref
	|	AND LineItems_WAve.Type      = VALUE(Enum.InventoryCosting.WeightedAverage)
	|	AND LineItems_WAve.Location <> VALUE(Catalog.Locations.EmptyRef)
	|	AND LineItems_WAve.QuantityRequested > 0
	|
	|UNION ALL
	|
	|SELECT // WeightedAverage by amount
	// ------------------------------------------------------
	// Standard attributes
	|	Shipment.Ref                          AS Recorder,
	|	Shipment.Date                         AS Period,
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
	|	LEFT JOIN Document.Shipment AS Shipment
	|		ON True
	|WHERE
	|	Shipment.Ref = &Ref
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
	|	END > 0";
	
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
	|	LineItems.LocationActual              AS Location
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
Function Query_GeneralJournal_ProductCost(TablesList)
	
	// Add GeneralJournal inventory - product cost table to document structure.
	TablesList.Insert("Table_GeneralJournal_ProductCost", TablesList.Count());
	
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
	|	Table_GeneralJournal_ProductCost
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
Function Query_GeneralJournal_ProductCost_Total(TablesList)
	
	// Add GeneralJournal inventory - product cost total table to document structure.
	TablesList.Insert("Table_GeneralJournal_ProductCost_Total", TablesList.Count());
	
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
	|	Table_GeneralJournal_ProductCost_Total
	// ------------------------------------------------------
	|FROM
	|	Table_GeneralJournal_ProductCost AS ProductCost
	|GROUP BY
	|	ProductCost.Product,
	|	ProductCost.Location";
	
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
	|	LineItems.Product.CostingMethod       AS Type,
	|	LineItems.Product                     AS Product,
	|	LineItems.LocationActual              AS Location,
	|	LineItems.Product.IncomeAccount       AS IncomeAccount,
	|	LineItems.Product.COGSAccount         AS COGSAccount,
	|	LineItems.Product.InventoryOrExpenseAccount AS InvOrExpAccount,
	|	LineItems.Class                       AS Class,
	|	LineItems.Project                     AS Project,
	// ------------------------------------------------------
	// Resources
	|	LineItems.QtyUM                       AS Quantity,
	|	LineItems.LineTotal                   AS Amount
	// ------------------------------------------------------
	|INTO
	|	Table_GeneralJournal_LineItems
	|FROM
	|	Document.Shipment.LineItems AS LineItems
	|WHERE
	|	LineItems.Ref = &Ref";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_GeneralJournal_Accounts_COGS_Quantity(TablesList)
	
	// Add GeneralJournal COGS accounts table to document structure.
	TablesList.Insert("Table_GeneralJournal_Accounts_COGS_Quantity", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // COGS accounts selection
	// ------------------------------------------------------
	// Dimensions
	|	Accounts.COGSAccount                  AS COGSAccount,
	|	Accounts.Product                      AS Product,
	|	Accounts.Location                     AS Location,
	|	Accounts.Type                         AS Type,
	// ------------------------------------------------------
	// Resources
	|	SUM(Accounts.Quantity)                AS Quantity
	// ------------------------------------------------------
	|INTO
	|	Table_GeneralJournal_Accounts_COGS_Quantity
	|FROM
	|	Table_GeneralJournal_LineItems AS Accounts
	|GROUP BY
	|	Accounts.COGSAccount,
	|	Accounts.Product,
	|	Accounts.Location,
	|	Accounts.Type";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_GeneralJournal_Accounts_COGS_Amount(TablesList)
	
	// Add GeneralJournal COGS accounts table to document structure.
	TablesList.Insert("Table_GeneralJournal_Accounts_COGS_Amount", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // FIFO
	// ------------------------------------------------------
	// Dimensions
	|	Accounts.COGSAccount                  AS COGSAccount,
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
	|	Table_GeneralJournal_Accounts_COGS_Amount
	|FROM
	|	Table_GeneralJournal_Accounts_COGS_Quantity AS Accounts
	|	LEFT JOIN Table_GeneralJournal_ProductCost_Total AS ProductCost
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
	|	Accounts.COGSAccount                  AS COGSAccount,
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
	|	Table_GeneralJournal_Accounts_COGS_Quantity AS Accounts
	|	LEFT JOIN Table_GeneralJournal_ProductCost_Total AS ProductCost
	|		ON  ProductCost.Product  = Accounts.Product
	|		AND ProductCost.Location = VALUE(Catalog.Locations.EmptyRef)
	|WHERE
	|	Accounts.Type = VALUE(Enum.InventoryCosting.WeightedAverage)";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_GeneralJournal_Accounts_COGS(TablesList)
	
	// Add GeneralJournal COGS accounts table to document structure.
	TablesList.Insert("Table_GeneralJournal_Accounts_COGS", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // COGS accounts selection
	// ------------------------------------------------------
	// Dimensions
	|	Accounts.COGSAccount                  AS COGSAccount,
	// ------------------------------------------------------
	// Resources
	|	SUM(Accounts.Amount)                  AS Amount
	// ------------------------------------------------------
	|INTO
	|	Table_GeneralJournal_Accounts_COGS
	|FROM
	|	Table_GeneralJournal_Accounts_COGS_Amount AS Accounts
	|GROUP BY
	|	Accounts.COGSAccount";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_GeneralJournal_Accounts_InvOrExp_Quantity(TablesList)
	
	// Add GeneralJournal InvOrExp accounts table to document structure.
	TablesList.Insert("Table_GeneralJournal_Accounts_InvOrExp_Quantity", TablesList.Count());
	
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
	|	Table_GeneralJournal_Accounts_InvOrExp_Quantity
	|FROM
	|	Table_GeneralJournal_LineItems AS Accounts
	|GROUP BY
	|	Accounts.InvOrExpAccount,
	|	Accounts.Product,
	|	Accounts.Location,
	|	Accounts.Type";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_GeneralJournal_Accounts_InvOrExp_Amount(TablesList)
	
	// Add GeneralJournal InvOrExp accounts table to document structure.
	TablesList.Insert("Table_GeneralJournal_Accounts_InvOrExp_Amount", TablesList.Count());
	
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
	|	Table_GeneralJournal_Accounts_InvOrExp_Amount
	|FROM
	|	Table_GeneralJournal_Accounts_InvOrExp_Quantity AS Accounts
	|	LEFT JOIN Table_GeneralJournal_ProductCost_Total AS ProductCost
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
	|	Table_GeneralJournal_Accounts_InvOrExp_Quantity AS Accounts
	|	LEFT JOIN Table_GeneralJournal_ProductCost_Total AS ProductCost
	|		ON  ProductCost.Product  = Accounts.Product
	|		AND ProductCost.Location = VALUE(Catalog.Locations.EmptyRef)
	|WHERE
	|	Accounts.Type = VALUE(Enum.InventoryCosting.WeightedAverage)";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_GeneralJournal_Accounts_InvOrExp(TablesList)
	
	// Add GeneralJournal InvOrExp accounts table to document structure.
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
	|	Table_GeneralJournal_Accounts_InvOrExp_Amount AS Accounts
	|GROUP BY
	|	Accounts.InvOrExpAccount";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_GeneralJournal(TablesList)
	
	// Add GeneralJournal table to document structure.
	TablesList.Insert("Table_GeneralJournal", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // Dr: COGS
	// ------------------------------------------------------
	// Standard attributes
	|	Shipment.Ref                          AS Recorder,
	|	Shipment.Date                         AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccountingRecordType.Debit)     AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Accounting attributes
	|	COGS.COGSAccount                      AS Account,
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
	|	COGS.Amount                           AS AmountRC,
	// ------------------------------------------------------
	// Attributes
	|	NULL                                  AS Memo
	// ------------------------------------------------------
	|FROM
	|	Table_GeneralJournal_Accounts_COGS AS COGS
	|	LEFT JOIN Document.Shipment AS Shipment
	|		ON True
	|WHERE
	|	Shipment.Ref = &Ref
	|	AND // Amount > 0
	|		COGS.Amount > 0
	|
	|UNION ALL
	|
	|SELECT // Cr: Inventory or Expences accounts
	// ------------------------------------------------------
	// Standard attributes
	|	Shipment.Ref                          AS Recorder,
	|	Shipment.Date                         AS Period,
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
	|	Table_GeneralJournal_Accounts_InvOrExp AS InvOrExp
	|	LEFT JOIN Document.Shipment AS Shipment
	|		ON True
	|WHERE
	|	Shipment.Ref = &Ref
	|	AND // Amount > 0
	|		InvOrExp.Amount > 0";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

//--//GJ++

// Query for document data.
Function Query_GeneralJournalAnalyticsDimensions_Accounts_COGS_Quantity(TablesList)
	
	// Add GeneralJournalAnalyticsDimensions COGS accounts table to document structure.
	TablesList.Insert("Table_GeneralJournalAnalyticsDimensions_Accounts_COGS_Quantity", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // COGS accounts selection
	// ------------------------------------------------------
	// Dimensions
	|	Accounts.COGSAccount                  AS COGSAccount,
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
	|	Table_GeneralJournalAnalyticsDimensions_Accounts_COGS_Quantity
	|FROM
	|	Table_GeneralJournal_LineItems AS Accounts
	|GROUP BY
	|	Accounts.COGSAccount,
	|	Accounts.Product,
	|	Accounts.Class,
	|	Accounts.Project,
	|	Accounts.Location,
	|	Accounts.Type";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_GeneralJournalAnalyticsDimensions_Accounts_COGS_Amount(TablesList)
	
	// Add GeneralJournalAnalyticsDimensions COGS accounts table to document structure.
	TablesList.Insert("Table_GeneralJournalAnalyticsDimensions_Accounts_COGS_Amount", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // FIFO
	// ------------------------------------------------------
	// Dimensions
	|	Accounts.COGSAccount                  AS COGSAccount,
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
	|	Table_GeneralJournalAnalyticsDimensions_Accounts_COGS_Amount
	|FROM
	|	Table_GeneralJournalAnalyticsDimensions_Accounts_COGS_Quantity AS Accounts
	|	LEFT JOIN Table_GeneralJournal_ProductCost_Total AS ProductCost
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
	|	Accounts.COGSAccount                  AS COGSAccount,
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
	|	Table_GeneralJournalAnalyticsDimensions_Accounts_COGS_Quantity AS Accounts
	|	LEFT JOIN Table_GeneralJournal_ProductCost_Total AS ProductCost
	|		ON  ProductCost.Product  = Accounts.Product
	|		AND ProductCost.Location = VALUE(Catalog.Locations.EmptyRef)
	|WHERE
	|	Accounts.Type = VALUE(Enum.InventoryCosting.WeightedAverage)";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_GeneralJournalAnalyticsDimensions_Accounts_COGS(TablesList)
	
	// Add GeneralJournalAnalyticsDimensions COGS accounts table to document structure.
	TablesList.Insert("Table_GeneralJournalAnalyticsDimensions_Accounts_COGS", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // COGS accounts selection
	// ------------------------------------------------------
	// Dimensions
	|	Accounts.COGSAccount                  AS COGSAccount,
	|	Accounts.Class                        AS Class,
	|	Accounts.Project                      AS Project,
	// ------------------------------------------------------
	// Resources
	|	SUM(Accounts.Amount)                  AS Amount
	// ------------------------------------------------------
	|INTO
	|	Table_GeneralJournalAnalyticsDimensions_Accounts_COGS
	|FROM
	|	Table_GeneralJournalAnalyticsDimensions_Accounts_COGS_Amount AS Accounts
	|GROUP BY
	|	Accounts.COGSAccount,
	|	Accounts.Class,
	|	Accounts.Project";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_GeneralJournalAnalyticsDimensions_Accounts_COGS_Difference_Amount(TablesList)
	
	// Add GeneralJournalAnalyticsDimensions difference COGS amount table to document structure.
	TablesList.Insert("Table_GeneralJournalAnalyticsDimensions_Accounts_COGS_Difference_Amount", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // COGS accounts selection
	// ------------------------------------------------------
	// Dimensions
	|	COGS_Dimensions.COGSAccount                      AS COGSAccount,
	// ------------------------------------------------------
	// Resources
	|	COGS_Dimensions.Amount                           AS Amount
	// ------------------------------------------------------
	|INTO
	|	Table_GeneralJournalAnalyticsDimensions_Accounts_COGS_Difference_Amount
	|FROM
	|	Table_GeneralJournal_Accounts_COGS AS COGS_Dimensions
	|	LEFT JOIN Document.Shipment AS Shipment
	|		ON True
	|WHERE
	|	Shipment.Ref = &Ref
	|	AND // Amount > 0
	|		COGS_Dimensions.Amount > 0
	|
	|UNION ALL
	|
	|SELECT // COGS Dimensions accounts selection
	// ------------------------------------------------------
	// Dimensions
	|	COGS_Dimensions.COGSAccount                      AS COGSAccount,
	// ------------------------------------------------------
	// Resources
	|	COGS_Dimensions.Amount * -1                      AS Amount
	// ------------------------------------------------------
	|FROM
	|	Table_GeneralJournalAnalyticsDimensions_Accounts_COGS AS COGS_Dimensions
	|	LEFT JOIN Document.Shipment AS Shipment
	|		ON True
	|WHERE
	|	Shipment.Ref = &Ref
	|	AND // Amount > 0
	|		COGS_Dimensions.Amount > 0";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_GeneralJournalAnalyticsDimensions_Accounts_COGS_Difference(TablesList)
	
	// Add GeneralJournalAnalyticsDimensions difference COGS table to document structure.
	TablesList.Insert("Table_GeneralJournalAnalyticsDimensions_Accounts_COGS_Difference", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // Dimensions difference selection
	// ------------------------------------------------------
	// Dimensions
	|	DimensionsDifference.COGSAccount           AS COGSAccount,
	// ------------------------------------------------------
	// Resources
	|	SUM(DimensionsDifference.Amount)           AS Amount
	// ------------------------------------------------------
	|INTO
	|	Table_GeneralJournalAnalyticsDimensions_Accounts_COGS_Difference
	|FROM
	|	Table_GeneralJournalAnalyticsDimensions_Accounts_COGS_Difference_Amount AS DimensionsDifference
	|GROUP BY
	|	DimensionsDifference.COGSAccount";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_GeneralJournalAnalyticsDimensions_Accounts_InvOrExp_Quantity(TablesList)
	
	// Add GeneralJournalAnalyticsDimensions InvOrExp accounts table to document structure.
	TablesList.Insert("Table_GeneralJournalAnalyticsDimensions_Accounts_InvOrExp_Quantity", TablesList.Count());
	
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
	|	Table_GeneralJournalAnalyticsDimensions_Accounts_InvOrExp_Quantity
	|FROM
	|	Table_GeneralJournal_LineItems AS Accounts
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
Function Query_GeneralJournalAnalyticsDimensions_Accounts_InvOrExp_Amount(TablesList)
	
	// Add GeneralJournalAnalyticsDimensions InvOrExp accounts table to document structure.
	TablesList.Insert("Table_GeneralJournalAnalyticsDimensions_Accounts_InvOrExp_Amount", TablesList.Count());
	
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
	|	Table_GeneralJournalAnalyticsDimensions_Accounts_InvOrExp_Amount
	|FROM
	|	Table_GeneralJournalAnalyticsDimensions_Accounts_InvOrExp_Quantity AS Accounts
	|	LEFT JOIN Table_GeneralJournal_ProductCost_Total AS ProductCost
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
	|	Table_GeneralJournalAnalyticsDimensions_Accounts_InvOrExp_Quantity AS Accounts
	|	LEFT JOIN Table_GeneralJournal_ProductCost_Total AS ProductCost
	|		ON  ProductCost.Product  = Accounts.Product
	|		AND ProductCost.Location = VALUE(Catalog.Locations.EmptyRef)
	|WHERE
	|	Accounts.Type = VALUE(Enum.InventoryCosting.WeightedAverage)";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_GeneralJournalAnalyticsDimensions_Accounts_InvOrExp(TablesList)
	
	// Add GeneralJournalAnalyticsDimensions InvOrExp accounts table to document structure.
	TablesList.Insert("Table_GeneralJournalAnalyticsDimensions_Accounts_InvOrExp", TablesList.Count());
	
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
	|	Table_GeneralJournalAnalyticsDimensions_Accounts_InvOrExp
	|FROM
	|	Table_GeneralJournalAnalyticsDimensions_Accounts_InvOrExp_Amount AS Accounts
	|GROUP BY
	|	Accounts.InvOrExpAccount,
	|	Accounts.Class,
	|	Accounts.Project";

	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_GeneralJournalAnalyticsDimensions_Accounts_InvOrExp_Difference_Amount(TablesList)
	
	// Add GeneralJournalAnalyticsDimensions difference InvOrExp amount table to document structure.
	TablesList.Insert("Table_GeneralJournalAnalyticsDimensions_Accounts_InvOrExp_Difference_Amount", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // InvOrExp accounts selection
	// ------------------------------------------------------
	// Dimensions
	|	InvOrExp_Dimensions.InvOrExpAccount                  AS InvOrExpAccount,
	// ------------------------------------------------------
	// Resources
	|	InvOrExp_Dimensions.Amount                           AS Amount
	// ------------------------------------------------------
	|INTO
	|	Table_GeneralJournalAnalyticsDimensions_Accounts_InvOrExp_Difference_Amount
	|FROM
	|	Table_GeneralJournal_Accounts_InvOrExp AS InvOrExp_Dimensions
	|	LEFT JOIN Document.Shipment AS Shipment
	|		ON True
	|WHERE
	|	Shipment.Ref = &Ref
	|	AND // Amount > 0
	|		InvOrExp_Dimensions.Amount > 0
	|
	|UNION ALL
	|
	|SELECT // InvOrExp Dimensions accounts selection
	// ------------------------------------------------------
	// Dimensions
	|	InvOrExp_Dimensions.InvOrExpAccount                  AS InvOrExpAccount,
	// ------------------------------------------------------
	// Resources
	|	InvOrExp_Dimensions.Amount * -1                      AS Amount
	// ------------------------------------------------------
	|FROM
	|	Table_GeneralJournalAnalyticsDimensions_Accounts_InvOrExp AS InvOrExp_Dimensions
	|	LEFT JOIN Document.Shipment AS Shipment
	|		ON True
	|WHERE
	|	Shipment.Ref = &Ref
	|	AND // Amount > 0
	|		InvOrExp_Dimensions.Amount > 0";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_GeneralJournalAnalyticsDimensions_Accounts_InvOrExp_Difference(TablesList)
	
	// Add GeneralJournalAnalyticsDimensions difference InvOrExp table to document structure.
	TablesList.Insert("Table_GeneralJournalAnalyticsDimensions_Accounts_InvOrExp_Difference", TablesList.Count());
	
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
	|	Table_GeneralJournalAnalyticsDimensions_Accounts_InvOrExp_Difference
	|FROM
	|	Table_GeneralJournalAnalyticsDimensions_Accounts_InvOrExp_Difference_Amount AS DimensionsDifference

	|GROUP BY
	|	DimensionsDifference.InvOrExpAccount";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_GeneralJournalAnalyticsDimensions_Transactions(TablesList)
	
	// Add GeneralJournalAnalyticsDimensions_Transactions table to document structure.
	TablesList.Insert("Table_GeneralJournalAnalyticsDimensions_Transactions", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // Receipt: COGS
	// ------------------------------------------------------
	// Standard attributes
	|	Shipment.Ref                          AS Recorder,
	|	Shipment.Date                         AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Accounting attributes
	|	COGS.COGSAccount                      AS Account,
	// ------------------------------------------------------
	// Dimensions
	|	Shipment.Company                      AS Company,
	|	COGS.Class                            AS Class,
	|	COGS.Project                          AS Project,
	// ------------------------------------------------------
	// Resources
	|	COGS.Amount                           AS AmountRC
	// ------------------------------------------------------
	|INTO Table_GeneralJournalAnalyticsDimensions_Transactions
	|FROM
	|	Table_GeneralJournalAnalyticsDimensions_Accounts_COGS AS COGS
	|	LEFT JOIN Document.Shipment AS Shipment
	|		ON True
	|WHERE
	|	Shipment.Ref = &Ref
	|	AND // Amount > 0
	|		COGS.Amount > 0
	|
	|UNION ALL
	|
	|SELECT // Receipt: COGS (difference)
	// ------------------------------------------------------
	// Standard attributes
	|	Shipment.Ref                          AS Recorder,
	|	Shipment.Date                         AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Accounting attributes
	|	COGS.COGSAccount                      AS Account,
	// ------------------------------------------------------
	// Dimensions
	|	Shipment.Company                      AS Company,
	|	NULL                                  AS Class,
	|	NULL                                  AS Project,
	// ------------------------------------------------------
	// Resources
	|	COGS.Amount                           AS AmountRC
	// ------------------------------------------------------
	|FROM
	|	Table_GeneralJournalAnalyticsDimensions_Accounts_COGS_Difference AS COGS
	|	LEFT JOIN Document.Shipment AS Shipment
	|		ON True
	|WHERE
	|	Shipment.Ref = &Ref
	|	AND // Amount <> 0
	|		COGS.Amount <> 0
	|
	|
	|UNION ALL
	|
	|SELECT // Expense: Inventory or Expenses accounts
	// ------------------------------------------------------
	// Standard attributes
	|	Shipment.Ref                          AS Recorder,
	|	Shipment.Date                         AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Accounting attributes
	|	InvOrExp.InvOrExpAccount              AS Account,
	// ------------------------------------------------------
	// Dimensions
	|	Shipment.Company                      AS Company,
	|	InvOrExp.Class                        AS Class,
	|	InvOrExp.Project                      AS Project,
	// ------------------------------------------------------
	// Resources
	|	InvOrExp.Amount                       AS AmountRC
	// ------------------------------------------------------
	|FROM
	|	Table_GeneralJournalAnalyticsDimensions_Accounts_InvOrExp AS InvOrExp
	|	LEFT JOIN Document.Shipment AS Shipment
	|		ON True
	|WHERE
	|	Shipment.Ref = &Ref
	|	AND // Amount > 0
	|		InvOrExp.Amount > 0
	|
	|UNION ALL
	|
	|SELECT // Expense: Inventory or Expenses accounts (difference)
	// ------------------------------------------------------
	// Standard attributes
	|	Shipment.Ref                          AS Recorder,
	|	Shipment.Date                         AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Accounting attributes
	|	InvOrExp.InvOrExpAccount              AS Account,
	// ------------------------------------------------------
	// Dimensions
	|	Shipment.Company                      AS Company,
	|	NULL                                  AS Class,
	|	NULL                                  AS Project,
	// ------------------------------------------------------
	// Resources
	|	InvOrExp.Amount                       AS AmountRC
	// ------------------------------------------------------
	|FROM
	|	Table_GeneralJournalAnalyticsDimensions_Accounts_InvOrExp_Difference AS InvOrExp
	|	LEFT JOIN Document.Shipment AS Shipment
	|		ON True
	|WHERE
	|	Shipment.Ref = &Ref
	|	AND // Amount <> 0
	|		InvOrExp.Amount <> 0";
	
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
	|	Shipment.Ref                          AS Document,
	|	Shipment.SalesPerson                  AS SalesPerson,
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
	|	LEFT JOIN Document.Shipment AS Shipment
	|		ON Shipment.Ref = &Ref";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction


// Put structure of registers, which balance should be checked during posting.
Procedure FillRegistersCheckList(AdditionalProperties, RegisterRecords)
	
	// Create structure of registers and its resources to check balances.
	BalanceCheck = New Structure;
	
	// Fill structure depending on document write mode.
	If AdditionalProperties.Posting.WriteMode = DocumentWriteMode.Posting Then
		
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
		
		// OrdersRegistered
		
		// Add resources for check changes in recordset.
		CheckPostings = New Array;
		CheckPostings.Add("{Table}.ShippedShipment{Posting}, <, 0"); // Check decreasing ShippedShipment.
		
		// Add resources for check register balances.
		CheckBalances = New Array;
		CheckBalances.Add("{Table}.ShippedShipment{Balance}, <, {Table}.Invoiced{Balance}"); // Check over-invoiced balance.
		
		// Add messages for different error situations.
		CheckMessages = New Array;
		CheckMessages.Add(NStr("en = '{Product}:
		                             |Order quantity {ShippedShipment} is lower then invoiced quantity {Invoiced}'")); // Over-invoiced balance.
		
		// Add register to check it's recordset changes and balances during posting.
		BalanceCheck.Insert("OrdersRegistered", New Structure("CheckPostings, CheckBalances, CheckMessages", CheckPostings, CheckBalances, CheckMessages));
	EndIf;
	
	// Return structure of registers to check.
	If BalanceCheck.Count() > 0 Then
		AdditionalProperties.Posting.Insert("BalanceCheck", BalanceCheck);
	EndIf;
	
EndProcedure

//------------------------------------------------------------------------------
// Document filling

// Query for document filling.
Function Query_Filling_Document_SalesOrder_Attributes(TablesList)
	
	// Add Attributes table to document structure.
	TablesList.Insert("Table_Document_SalesOrder_Attributes", TablesList.Count());
	
	// Collect attributes data.
	QueryText =
		"SELECT
		|	SalesOrder.Ref                      AS FillingData,
		|	SalesOrder.Company                  AS Company,
		|	SalesOrder.ShipTo                   AS ShipTo,
		|	SalesOrder.BillTo                   AS BillTo,
		|	SalesOrder.ConfirmTo                AS ConfirmTo,
		|	SalesOrder.RefNum                   AS RefNum,
		|	SalesOrder.DropshipCompany          AS DropshipCompany,
		|	SalesOrder.DropshipShipTo           AS DropshipShipTo,
		|	SalesOrder.DropshipConfirmTo        AS DropshipConfirmTo,
		|	SalesOrder.DropshipRefNum           AS DropshipRefNum,
		|	SalesOrder.SalesPerson              AS SalesPerson,
		|	SalesOrder.Currency                 AS Currency,
		|	SalesOrder.ExchangeRate             AS ExchangeRate,
		|	SalesOrder.Location                 AS LocationActual,
		|	SalesOrder.DeliveryDate             AS DeliveryDateActual,
		|	SalesOrder.Project                  AS Project,
		|	SalesOrder.Class                    AS Class,
		|	ISNULL(SalesOrder.Company.Terms, VALUE(Catalog.PaymentTerms.EmptyRef))
		|                                       AS Terms,
		|	SalesOrder.DiscountPercent          AS DiscountPercent,
		|	SalesOrder.Shipping                 AS Shipping,
		|	SalesOrder.SalesTaxRate             AS SalesTaxRate,
		|	SalesOrder.DiscountIsTaxable        AS DiscountIsTaxable,
		|	SalesOrder.DiscountTaxability       AS DiscountTaxability,
		|	SalesOrder.UseAvatax                AS UseAvatax,
		|	SalesOrder.AvataxShippingTaxCode    AS AvataxShippingTaxCode
		|INTO Table_Document_SalesOrder_Attributes
		|FROM
		|	Document.SalesOrder AS SalesOrder
		|WHERE
		|	SalesOrder.Ref IN(&FillingData_Document_SalesOrder)";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document filling.
Function Query_Filling_Document_SalesOrder_CommonTotals(TablesList)
	
	// Add Totals table to document structure.
	TablesList.Insert("Table_Document_SalesOrder_CommonTotals", TablesList.Count());
	
	// Collect totals data.
	QueryText =
		"SELECT
		// Totals of document
		|	SalesOrderLineItems.Ref                 AS FillingData,
		|	
		|	// Total of taxable amount
		|	SUM(CASE
		|			WHEN SalesOrderLineItems.Taxable = True THEN
		|				SalesOrderLineItems.TaxableAmount +
		|				CASE // Discount
		|					WHEN SalesOrderLineItems.Ref.LineSubtotal > 0 THEN
		|						SalesOrderLineItems.Ref.Discount *
		|						SalesOrderLineItems.LineTotal /
		|						SalesOrderLineItems.Ref.LineSubtotal
		|					ELSE 0
		|				END
		|			ELSE 0
		|		END)                                AS TaxableAmount
		|	
		|INTO
		|	Table_Document_SalesOrder_CommonTotals
		|FROM
		|	Document.SalesOrder.LineItems AS SalesOrderLineItems
		|WHERE
		|	SalesOrderLineItems.Ref IN (&FillingData_Document_SalesOrder)
		|GROUP BY
		|	SalesOrderLineItems.Ref";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document filling.
Function Query_Filling_Document_SalesOrder_OrdersStatuses(TablesList)
	
	// Add OrdersStatuses table to document structure.
	TablesList.Insert("Table_Document_SalesOrder_OrdersStatuses", TablesList.Count());
	
	// Collect orders statuses data.
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
		|		LEFT JOIN InformationRegister.OrdersStatuses.SliceLast(, Order IN (&FillingData_Document_SalesOrder)) AS OrdersStatuses
		|		ON SalesOrder.Ref = OrdersStatuses.Order
		|WHERE
		|	SalesOrder.Ref IN (&FillingData_Document_SalesOrder)";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document filling.
Function Query_Filling_Document_SalesOrder_OrdersRegistered(TablesList)
	
	// Add OrdersRegistered table to document structure.
	TablesList.Insert("Table_Document_SalesOrder_OrdersRegistered", TablesList.Count());
	
	// Collect orders items data.
	QueryText =
		"SELECT
		// ------------------------------------------------------
		// Dimensions
		|	OrdersRegisteredBalance.Company          AS Company,
		|	OrdersRegisteredBalance.Order            AS Order,
		|	OrdersRegisteredBalance.Product          AS Product,
		|	OrdersRegisteredBalance.Unit             AS Unit,
		|	OrdersRegisteredBalance.Location         AS Location,
		|	OrdersRegisteredBalance.DeliveryDate     AS DeliveryDate,
		|	OrdersRegisteredBalance.Project          AS Project,
		|	OrdersRegisteredBalance.Class            AS Class,
		// ------------------------------------------------------
		// Resources                                                                                                        // ---------------------------------------
		|	OrdersRegisteredBalance.QuantityBalance  AS Quantity,                                                           // Backorder quantity calculation
		|	CASE                                                                                                            // ---------------------------------------
		|		WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Open)        THEN 0                                   // Order status = Open:
		|		WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Backordered) THEN                                     //   Backorder = 0
		|			 CASE                                                                                                   // Order status = Backorder:    
		|				 WHEN OrdersRegisteredBalance.QuantityBalance > OrdersRegisteredBalance.ShippedShipmentBalance      //     |
		|				 THEN OrdersRegisteredBalance.QuantityBalance - OrdersRegisteredBalance.ShippedShipmentBalance      //   Backorder = Ordered - ShippedShipment >= 0
		|			 ELSE 0 END                                                                                             //     |
		|		WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Closed)      THEN 0                                   // Order status = Closed:
		|		ELSE 0                                                                                                      //   Backorder = 0
		|		END                                  AS Backorder
		// ------------------------------------------------------
		|INTO
		|	Table_Document_SalesOrder_OrdersRegistered
		|FROM
		|	AccumulationRegister.OrdersRegistered.Balance(,
		|		(Company, Order, Product, Unit, Location, DeliveryDate, Project, Class) IN
		|			(SELECT
		|				SalesOrderLineItems.Ref.Company,
		|				SalesOrderLineItems.Ref,
		|				SalesOrderLineItems.Product,
		|				SalesOrderLineItems.Unit,
		|				SalesOrderLineItems.Location,
		|				SalesOrderLineItems.DeliveryDate,
		|				SalesOrderLineItems.Project,
		|				SalesOrderLineItems.Class
		|			FROM
		|				Document.SalesOrder.LineItems AS SalesOrderLineItems
		|			WHERE
		|				SalesOrderLineItems.Ref IN (&FillingData_Document_SalesOrder))) AS OrdersRegisteredBalance
		|	LEFT JOIN Table_Document_SalesOrder_OrdersStatuses AS OrdersStatuses
		|		ON OrdersRegisteredBalance.Order = OrdersStatuses.Order";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document filling.
Function Query_Filling_Document_SalesOrder_LineItems(TablesList)
	
	// Add LineItems table to document structure.
	TablesList.Insert("Table_Document_SalesOrder_LineItems", TablesList.Count());
	
	// Collect line items data.
	QueryText =
		"SELECT
		|	SalesOrderLineItems.Ref                 AS FillingData,
		|	SalesOrderLineItems.Product             AS Product,
		|	SalesOrderLineItems.ProductDescription  AS ProductDescription,
		|	SalesOrderLineItems.UnitSet             AS UnitSet,
		|	SalesOrderLineItems.Unit                AS Unit,
		|	CASE
		|		WHEN SalesOrderLineItems.Product.PricePrecision = 3
		|			THEN CAST(SalesOrderLineItems.PriceUnits AS NUMBER(17, 3))
		|		WHEN SalesOrderLineItems.Product.PricePrecision = 4
		|			THEN CAST(SalesOrderLineItems.PriceUnits AS NUMBER(17, 4))
		|		ELSE CAST(SalesOrderLineItems.PriceUnits AS NUMBER(17, 2))
		|	END          							AS PriceUnits,
		|	
		|	// QtyUnits
		|	CASE
		|		WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Open)
		|			THEN ISNULL(OrdersRegistered.Quantity, SalesOrderLineItems.QtyUnits)
		|		WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Backordered)
		|			THEN ISNULL(OrdersRegistered.Backorder, SalesOrderLineItems.QtyUnits)
		|		WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Closed)
		|			THEN ISNULL(OrdersRegistered.Backorder, 0)
		|		ELSE 0
		|	END                                     AS QtyUnits,
		|	
		|	// QtyUM
		|	CAST( // Format(Quantity * Unit.Factor, ""ND=15; NFD={4}"")
		|		CASE
		|			WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Open)
		|				THEN ISNULL(OrdersRegistered.Quantity, SalesOrderLineItems.QtyUnits)
		|			WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Backordered)
		|				THEN ISNULL(OrdersRegistered.Backorder, SalesOrderLineItems.QtyUnits)
		|			WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Closed)
		|				THEN ISNULL(OrdersRegistered.Backorder, 0)
		|			ELSE 0
		|		END * 
		|		CASE
		|			WHEN SalesOrderLineItems.Unit.Factor > 0
		|				THEN SalesOrderLineItems.Unit.Factor
		|			ELSE 1
		|		END
		|		AS NUMBER (15, {QuantityPrecision})) AS QtyUM,
		|	
		|	// LineTotal
		|	CAST( // Format(Quantity * Price, ""ND=17; NFD=2"")
		|		CASE
		|			WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Open)
		|				THEN ISNULL(OrdersRegistered.Quantity, SalesOrderLineItems.QtyUnits)
		|			WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Backordered)
		|				THEN ISNULL(OrdersRegistered.Backorder, SalesOrderLineItems.QtyUnits)
		|			WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Closed)
		|				THEN ISNULL(OrdersRegistered.Backorder, 0)
		|			ELSE 0
		|		END * CASE
		|			WHEN SalesOrderLineItems.Product.PricePrecision = 3
		|				THEN CAST(SalesOrderLineItems.PriceUnits AS NUMBER(17, 3))
		|			WHEN SalesOrderLineItems.Product.PricePrecision = 4
		|				THEN CAST(SalesOrderLineItems.PriceUnits AS NUMBER(17, 4))
		|			ELSE CAST(SalesOrderLineItems.PriceUnits AS NUMBER(17, 2))
		|		END
		|		AS NUMBER (17, 2))                   AS LineTotal,
		|	
		|	// Discount
		|	CAST( // Format(Discount * LineTotal / Subtotal, ""ND=17; NFD=2"")
		|		CASE
		|			WHEN SalesOrderLineItems.Ref.LineSubtotal > 0 THEN
		|				SalesOrderLineItems.Ref.Discount *
		|				CASE // LineTotal = Quantity * Price
		|					WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Open)
		|						THEN ISNULL(OrdersRegistered.Quantity, SalesOrderLineItems.QtyUnits)
		|					WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Backordered)
		|						THEN ISNULL(OrdersRegistered.Backorder, SalesOrderLineItems.QtyUnits)
		|					WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Closed)
		|						THEN ISNULL(OrdersRegistered.Backorder, 0)
		|					ELSE 0
		|				END * CASE
		|					WHEN SalesOrderLineItems.Product.PricePrecision = 3
		|						THEN CAST(SalesOrderLineItems.PriceUnits AS NUMBER(17, 3))
		|					WHEN SalesOrderLineItems.Product.PricePrecision = 4
		|						THEN CAST(SalesOrderLineItems.PriceUnits AS NUMBER(17, 4))
		|					ELSE CAST(SalesOrderLineItems.PriceUnits AS NUMBER(17, 2))
		|				END /
		|				SalesOrderLineItems.Ref.LineSubtotal
		|			ELSE 0
		|		END
		|		AS NUMBER (17, 2))                  AS Discount,
		|	
		|	// Taxable flag
		|	SalesOrderLineItems.Taxable             AS Taxable,
		|	
		|	// Taxable amount
		|	CAST( // Format(?(Taxable, LineTotal, 0), ""ND=17; NFD=2"")
		|		CASE
		|			WHEN SalesOrderLineItems.Taxable = True THEN
		|				CASE // Quantity * Price
		|					WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Open)
		|						THEN ISNULL(OrdersRegistered.Quantity, SalesOrderLineItems.QtyUnits)
		|					WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Backordered)
		|						THEN ISNULL(OrdersRegistered.Backorder, SalesOrderLineItems.QtyUnits)
		|					WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Closed)
		|						THEN ISNULL(OrdersRegistered.Backorder, 0)
		|					ELSE 0
		|				END * CASE
		|					WHEN SalesOrderLineItems.Product.PricePrecision = 3
		|						THEN CAST(SalesOrderLineItems.PriceUnits AS NUMBER(17, 3))
		|					WHEN SalesOrderLineItems.Product.PricePrecision = 4
		|						THEN CAST(SalesOrderLineItems.PriceUnits AS NUMBER(17, 4))
		|					ELSE CAST(SalesOrderLineItems.PriceUnits AS NUMBER(17, 2))
		|				END
		|			ELSE 0
		|		END
		|		AS NUMBER (17, 2))                  AS TaxableAmount,
		|	
		|	// Tax amount
		|	CAST( // Format(TaxableAmount * TaxRate, ""ND=17; NFD=2"")
		|		// Taxable amount
		|		CASE
		|			WHEN SalesOrderLineItems.Taxable = True THEN
		|				CASE // LineTotal
		|					WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Open)
		|						THEN ISNULL(OrdersRegistered.Quantity, SalesOrderLineItems.QtyUnits)
		|					WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Backordered)
		|						THEN ISNULL(OrdersRegistered.Backorder, SalesOrderLineItems.QtyUnits)
		|					WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Closed)
		|						THEN ISNULL(OrdersRegistered.Backorder, 0)
		|					ELSE 0
		|				END * CASE
		|					WHEN SalesOrderLineItems.Product.PricePrecision = 3
		|						THEN CAST(SalesOrderLineItems.PriceUnits AS NUMBER(17, 3))
		|					WHEN SalesOrderLineItems.Product.PricePrecision = 4
		|						THEN CAST(SalesOrderLineItems.PriceUnits AS NUMBER(17, 4))
		|					ELSE CAST(SalesOrderLineItems.PriceUnits AS NUMBER(17, 2))
		|				END
		|				+
		|				CASE // Discount
		|					WHEN SalesOrderLineItems.Ref.LineSubtotal > 0 THEN
		|						SalesOrderLineItems.Ref.Discount *
		|						CASE // LineTotal = Quantity * Price
		|							WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Open)
		|								THEN ISNULL(OrdersRegistered.Quantity, SalesOrderLineItems.QtyUnits)
		|							WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Backordered)
		|								THEN ISNULL(OrdersRegistered.Backorder, SalesOrderLineItems.QtyUnits)
		|							WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Closed)
		|								THEN ISNULL(OrdersRegistered.Backorder, 0)
		|							ELSE 0
		|						END * CASE
		|							WHEN SalesOrderLineItems.Product.PricePrecision = 3
		|								THEN CAST(SalesOrderLineItems.PriceUnits AS NUMBER(17, 3))
		|							WHEN SalesOrderLineItems.Product.PricePrecision = 4
		|								THEN CAST(SalesOrderLineItems.PriceUnits AS NUMBER(17, 4))
		|							ELSE CAST(SalesOrderLineItems.PriceUnits AS NUMBER(17, 2))
		|						END /
		|						SalesOrderLineItems.Ref.LineSubtotal
		|					ELSE 0
		|				END
		|			ELSE 0
		|		END *
		|		// Tax rate
		|		CASE
		|			WHEN CommonTotals.TaxableAmount > 0 THEN
		|				SalesOrderLineItems.Ref.SalesTax /
		|				CommonTotals.TaxableAmount
		|			ELSE 0
		|		END
		|		AS NUMBER (17, 2))                  AS SalesTax,
		|	
		|	SalesOrderLineItems.Ref                 AS Order,
		|	SalesOrderLineItems.Location            AS Location,
		|	SalesOrderLineItems.Location            AS LocationActual,
		|	SalesOrderLineItems.DeliveryDate        AS DeliveryDate,
		|	SalesOrderLineItems.DeliveryDate        AS DeliveryDateActual,
		|	SalesOrderLineItems.Project             AS Project,
		|	SalesOrderLineItems.Class               AS Class,
		|	SalesOrderLineItems.Ref.Company         AS Company,
		|	SalesOrderLineItems.AvataxTaxCode       AS AvataxTaxCode,
		|	SalesOrderLineItems.DiscountIsTaxable   AS DiscountIsTaxable
		|INTO
		|	Table_Document_SalesOrder_LineItems
		|FROM
		|	Document.SalesOrder.LineItems AS SalesOrderLineItems
		|	LEFT JOIN Table_Document_SalesOrder_CommonTotals AS CommonTotals
		|		ON CommonTotals.FillingData = SalesOrderLineItems.Ref
		|	LEFT JOIN Table_Document_SalesOrder_OrdersRegistered AS OrdersRegistered
		|		ON  OrdersRegistered.Company      = SalesOrderLineItems.Ref.Company
		|		AND OrdersRegistered.Order        = SalesOrderLineItems.Ref
		|		AND OrdersRegistered.Product      = SalesOrderLineItems.Product
		|		AND OrdersRegistered.Unit         = SalesOrderLineItems.Unit
		|		AND OrdersRegistered.Location     = SalesOrderLineItems.Location
		|		AND OrdersRegistered.DeliveryDate = SalesOrderLineItems.DeliveryDate
		|		AND OrdersRegistered.Project      = SalesOrderLineItems.Project
		|		AND OrdersRegistered.Class        = SalesOrderLineItems.Class
		|	LEFT JOIN Table_Document_SalesOrder_OrdersStatuses AS OrdersStatuses
		|		ON OrdersStatuses.Order = SalesOrderLineItems.Ref
		|WHERE
		|	SalesOrderLineItems.Ref IN (&FillingData_Document_SalesOrder)";
		
	// Update query rounding using quantity precision.
	QueryText = StrReplace(QueryText, "{QuantityPrecision}", GeneralFunctionsReusable.DefaultQuantityPrecision());
	
	// Return text of query
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document filling.
Function Query_Filling_Document_SalesOrder_Totals(TablesList)
	
	// Add Totals table to document structure.
	TablesList.Insert("Table_Document_SalesOrder_Totals", TablesList.Count());
	
	// Collect totals data.
	QueryText =
		"SELECT
		// Totals of document
		|	SalesOrderLineItems.FillingData         AS FillingData,
		|	
		|	// Total(LineTotal)
		|	SUM(SalesOrderLineItems.LineTotal)      AS LineSubtotal,
		|	
		|	// Total(Discount)
		|	SUM(SalesOrderLineItems.Discount)       AS Discount,
		|	
		|	// Total(LineTotal) + Total(Discount)
		|	SUM(SalesOrderLineItems.LineTotal) +
		|	SUM(SalesOrderLineItems.Discount)       AS SubTotal,
		|	
		|	// Total(SalesTax)
		|	SUM(SalesOrderLineItems.SalesTax)       AS SalesTax,
		|	
		|	// Format(SalesTax * ExchangeRate, ""ND=17; NFD=2"")
		|	CAST( // Format(SalesTax * ExchangeRate, ""ND=17; NFD=2"")
		|		SUM(SalesOrderLineItems.SalesTax) *
		|		SalesOrder.ExchangeRate
		|		AS NUMBER (17, 2))                  AS SalesTaxRC
		|	
		|INTO
		|	Table_Document_SalesOrder_Totals
		|FROM
		|	Table_Document_SalesOrder_LineItems AS SalesOrderLineItems
		|	LEFT JOIN Table_Document_SalesOrder_Attributes AS SalesOrder
		|		ON SalesOrder.FillingData = SalesOrderLineItems.FillingData
		|GROUP BY
		|	SalesOrderLineItems.FillingData,
		|	SalesOrder.ExchangeRate";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document filling.
Function Query_Filling_Attributes(TablesList)
	
	// Add Attributes table to document structure.
	TablesList.Insert("Table_Attributes", TablesList.Count());
	
	// Fill data from attributes and totals.
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
		|	Document_SalesOrder_Attributes.ShipTo,
		|	Document_SalesOrder_Attributes.BillTo,
		|	Document_SalesOrder_Attributes.ConfirmTo,
		|	Document_SalesOrder_Attributes.RefNum,
		|	Document_SalesOrder_Attributes.DropshipCompany,
		|	Document_SalesOrder_Attributes.DropshipShipTo,
		|	Document_SalesOrder_Attributes.DropshipConfirmTo,
		|	Document_SalesOrder_Attributes.DropshipRefNum,
		|	Document_SalesOrder_Attributes.SalesPerson,
		|	Document_SalesOrder_Attributes.Currency,
		|	Document_SalesOrder_Attributes.ExchangeRate,
		|	Document_SalesOrder_Attributes.LocationActual,
		|	Document_SalesOrder_Attributes.DeliveryDateActual,
		|	Document_SalesOrder_Attributes.Project,
		|	Document_SalesOrder_Attributes.Class,
		|	Document_SalesOrder_Attributes.Terms,
		|	Document_SalesOrder_Totals.LineSubtotal,
		|	Document_SalesOrder_Attributes.DiscountPercent,
		|	Document_SalesOrder_Totals.Discount,
		|	Document_SalesOrder_Totals.SubTotal,
		|	Document_SalesOrder_Attributes.Shipping,
		|	Document_SalesOrder_Totals.SalesTax,
		|	Document_SalesOrder_Totals.SalesTaxRC,
		|	Document_SalesOrder_Attributes.SalesTaxRate,
		|	Document_SalesOrder_Attributes.DiscountIsTaxable,
		|	Document_SalesOrder_Attributes.DiscountTaxability,
		|	Document_SalesOrder_Attributes.UseAvatax,
		|	Document_SalesOrder_Attributes.AvataxShippingTaxCode
		|{Into}
		|FROM
		|	Table_Document_SalesOrder_Attributes AS Document_SalesOrder_Attributes
		|	LEFT JOIN Table_Document_SalesOrder_Totals AS Document_SalesOrder_Totals
		|		ON Document_SalesOrder_Totals.FillingData = Document_SalesOrder_Attributes.FillingData";
		
		// Add selection to a query
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

// Query for document filling.
Function Query_Filling_LineItems(TablesList)
	
	// Add LineItems table to document structure.
	TablesList.Insert("Table_LineItems", TablesList.Count());
	
	// Fill data from attributes and totals.
	QueryText = "";
	
	// Fill from sales orders.
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
		|	Document_SalesOrder_LineItems.UnitSet,
		|	Document_SalesOrder_LineItems.QtyUnits,
		|	Document_SalesOrder_LineItems.Unit,
		|	Document_SalesOrder_LineItems.QtyUM,
		|	Document_SalesOrder_LineItems.PriceUnits,
		|	Document_SalesOrder_LineItems.LineTotal,
		|	Document_SalesOrder_LineItems.Taxable,
		|	Document_SalesOrder_LineItems.TaxableAmount,
		|	Document_SalesOrder_LineItems.Order,
		|	Document_SalesOrder_LineItems.Location,
		|	Document_SalesOrder_LineItems.LocationActual,
		|	Document_SalesOrder_LineItems.DeliveryDate,
		|	Document_SalesOrder_LineItems.DeliveryDateActual,
		|	Document_SalesOrder_LineItems.Project,
		|	Document_SalesOrder_LineItems.Class,
		|	Document_SalesOrder_LineItems.AvataxTaxCode,
		|	Document_SalesOrder_LineItems.DiscountIsTaxable
		|{Into}
		|FROM
		|	Table_Document_SalesOrder_LineItems AS Document_SalesOrder_LineItems
		|WHERE
		|	Document_SalesOrder_LineItems.QtyUnits > 0";
		
		// Add selection to a query
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

// Query for document filling.
Function Query_Filling_SalesTaxAcrossAgencies(TablesList)
	
	// Add SalesTaxAcrossAgencies table to document structure.
	TablesList.Insert("Table_SalesTaxAcrossAgencies", TablesList.Count());
	
	// Fill data from attributes and totals.
	QueryText = "";
	
	QueryText = "SELECT
	            |	SalesOrderSalesTaxAcrossAgencies.Agency,
	            |	SalesOrderSalesTaxAcrossAgencies.Rate,
	            |	SalesOrderSalesTaxAcrossAgencies.Amount,
	            |	SalesOrderSalesTaxAcrossAgencies.SalesTaxRate,
	            |	SalesOrderSalesTaxAcrossAgencies.SalesTaxComponent,
	            |	SalesOrderSalesTaxAcrossAgencies.AvataxTaxComponent
	            |INTO Table_SalesTaxAcrossAgencies
	            |FROM
	            |	Document.SalesOrder.SalesTaxAcrossAgencies AS SalesOrderSalesTaxAcrossAgencies
	            |WHERE
	            |	SalesOrderSalesTaxAcrossAgencies.Ref IN(&FillingData_Document_SalesOrder)";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Fill structure of attributes, which should be checked during filling.
Function FillingCheckList(AdditionalProperties)
	
	// Create structure of registers and its resources to check balances.
	CheckAttributes = New Structure;
	// Group by attributes to check uniqueness.
	CheckAttributes.Insert("Company",            "Check");
	CheckAttributes.Insert("ShipTo",             "Check");
	CheckAttributes.Insert("BillTo",             "Check");
	CheckAttributes.Insert("DropshipCompany",    "Check");
	CheckAttributes.Insert("DropshipShipTo",     "Check");
	CheckAttributes.Insert("Currency",           "Check");
	CheckAttributes.Insert("ExchangeRate",       "Check");
	// Maximal possible values.
	CheckAttributes.Insert("DeliveryDateActual", "Max");
	// Summarize totals.
	CheckAttributes.Insert("LineSubtotal",       "Sum");
	CheckAttributes.Insert("DiscountPercent",    "CAST( // Format(-Total(Discount) / Total(LineSubtotal) * 100%, ""ND=15; NFD=2"")
	                                             |		CASE
	                                             |			WHEN SUM(Attributes.LineSubtotal) > 0
	                                             |				THEN -100 * SUM(Attributes.Discount) / SUM(Attributes.LineSubtotal)
	                                             |			ELSE 0
	                                             |		END
	                                             |		AS NUMBER (4, 2))");
	CheckAttributes.Insert("Discount",           "Sum");
	CheckAttributes.Insert("SubTotal",           "Sum");
	CheckAttributes.Insert("Shipping",           "Max");
	CheckAttributes.Insert("SalesTax",           "Sum");
	CheckAttributes.Insert("SalesTaxRC",         "Sum");
	CheckAttributes.Insert("DocumentTotal",      "SUM(Attributes.SubTotal) + MAX(Attributes.Shipping) + SUM(Attributes.SalesTax)");
	CheckAttributes.Insert("DocumentTotalRC",    "CAST( // Format(DocumentTotal * ExchangeRate, ""ND=17; NFD=2"")
	                                             |		(SUM(Attributes.SubTotal) + MAX(Attributes.Shipping) + SUM(Attributes.SalesTax)) *
	                                             |		Attributes.ExchangeRate
	                                             |		AS NUMBER (17, 2))");
	CheckAttributes.Insert("SalesTaxRate",       "CASE 
												 |    WHEN COUNT(DISTINCT Attributes.SalesTaxRate) > 1
												 |        THEN VALUE(Catalog.SalesTaxRates.EmptyRef)
												 |    ELSE MAX(Attributes.SalesTaxRate)
												 |END");
	CheckAttributes.Insert("DiscountIsTaxable",  "CASE 
												 |    WHEN COUNT(DISTINCT Attributes.DiscountIsTaxable) > 1
												 |        THEN TRUE
												 |    ELSE MAX(Attributes.DiscountIsTaxable)
												 |END");
	
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
