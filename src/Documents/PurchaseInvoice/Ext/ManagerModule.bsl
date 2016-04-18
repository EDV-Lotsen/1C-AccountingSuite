
////////////////////////////////////////////////////////////////////////////////
// Purchase invoice: Manager module
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
		             Query_OrdersDispatched_Balance(BalancesList) +
					 Query_OrdersDispatchedIR_Balance(BalancesList);
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
	             Query_GeneralJournal_Accounts_ExpAP(TablesList) +
	             Query_GeneralJournal(TablesList) +
				 //--//GJ++
				 Query_GeneralJournalAnalyticsDimensions_Accounts_InvOrExp(TablesList)+
				 Query_GeneralJournalAnalyticsDimensions_Accounts_InvOrExp_Difference_Amount(TablesList)+
				 Query_GeneralJournalAnalyticsDimensions_Accounts_InvOrExp_Difference(TablesList)+
				 Query_GeneralJournalAnalyticsDimensions_Accounts_InvOrExpNeg_Difference_Amount(TablesList)+
				 Query_GeneralJournalAnalyticsDimensions_Accounts_InvOrExpNeg_Difference(TablesList)+
				 Query_GeneralJournalAnalyticsDimensions_Transactions(TablesList)+
	             Query_GeneralJournalAnalyticsDimensions(TablesList)+
	             //--//GJ--

				 Query_CashFlowData_Accounts_Positive(TablesList) +
				 Query_CashFlowData_Accounts_Positive_Amount(TablesList) +
				 Query_CashFlowData_Accounts_Negative(TablesList) +
				 Query_CashFlowData_Accounts_Negative_Amount(TablesList) +
				 Query_CashFlowData_Accounts_Paid(TablesList) +
				 Query_CashFlowData_Accounts_Paid_Amount(TablesList) +
				 Query_CashFlowData_Accounts_Paid_Transactions(TablesList) +
				 Query_CashFlowData_Accounts_Paid_Transactions_Corrected(TablesList) +
				 Query_CashFlowData_Accounts_Paid_Transactions_Amount(TablesList) +
				 Query_CashFlowData_CB_Accounts(TablesList) +
				 Query_CashFlowData_CB_Accounts_Amount(TablesList) +
				 Query_CashFlowData(TablesList) +
				 
	             Query_ProjectData_Accounts(TablesList) +
	             Query_ProjectData_Accounts_InvOrExp(TablesList) +
	             Query_ProjectData(TablesList) +
	             Query_ClassData_Accounts(TablesList) +
	             Query_ClassData_Accounts_InvOrExp(TablesList) +
	             Query_ClassData(TablesList) +
	             Query_ItemLastCosts(TablesList);
	
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
	
	// Optionally check/update orders posting.
	If OrdersPosting Then
		// Custom update after filling of all tables.
		CheckCloseParentOrders(DocumentRef, AdditionalProperties, Query.TempTablesManager);
	EndIf;
	
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
Procedure CheckOrderQuantity(DocumentRef, DocumentDate, Company, LineItems, Filter, Cancel) Export
	ErrorsCount = 0;
	MessageText = "";
	
	// 1. Create a query to request data.
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Date", DocumentDate);
	
	// 2. Fill out the line items table.
	InvoiceLineItems = LineItems.Unload(Filter, "LineNumber, Order, ItemReceipt, Product, Unit, Location, DeliveryDate, Project, Class, QtyUnits");
	InvoiceLineItems.Columns.Insert(1, "Company", New TypeDescription("CatalogRef.Companies"), "", 20);
	InvoiceLineItems.FillValues(Company, "Company");
	DocumentPosting.PutTemporaryTable(InvoiceLineItems, "InvoiceLineItems", Query.TempTablesManager);
	
	// 3. Request uninvoiced items for each line item.
	Query.Text = "
		|SELECT
		|	LineItems.LineNumber          AS LineNumber,
		|	LineItems.Order               AS Order,
		|	LineItems.ItemReceipt         AS ItemReceipt,
		|	LineItems.Product.Code        AS ProductCode,
		|	LineItems.Product.Description AS ProductDescription,
		|	CASE 
		|       WHEN LineItems.ItemReceipt <> VALUE(Document.ItemReceipt.EmptyRef) 
		|		    THEN OrdersDispatchedBalance.ReceivedIRBalance - OrdersDispatchedBalance.InvoicedBalance - LineItems.QtyUnits 
		|		ELSE OrdersDispatchedBalance.QuantityBalance - OrdersDispatchedBalance.InvoicedBalance - LineItems.QtyUnits
		|   END                           AS UninvoicedQuantity
		|FROM
		|	InvoiceLineItems AS LineItems
		|	LEFT JOIN AccumulationRegister.OrdersDispatched.Balance(&Date, (Company, Order, ItemReceipt, Product, Unit, Location, DeliveryDate, Project, Class)
		|		      IN (SELECT Company, Order, ItemReceipt, Product, Unit, Location, DeliveryDate, Project, Class FROM InvoiceLineItems)) AS OrdersDispatchedBalance
		|		ON  LineItems.Company      = OrdersDispatchedBalance.Company
		|		AND LineItems.Order        = OrdersDispatchedBalance.Order
		|		AND LineItems.ItemReceipt  = OrdersDispatchedBalance.ItemReceipt
		|		AND LineItems.Product      = OrdersDispatchedBalance.Product
		|		AND LineItems.Unit         = OrdersDispatchedBalance.Unit
		|		AND LineItems.Location     = OrdersDispatchedBalance.Location
		|		AND LineItems.DeliveryDate = OrdersDispatchedBalance.DeliveryDate
		|		AND LineItems.Project      = OrdersDispatchedBalance.Project
		|		AND LineItems.Class        = OrdersDispatchedBalance.Class
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
				                            NStr("en = 'The product %1 in line %2 was not declared in %3.'"), TrimAll(Row.ProductCode) + " " + TrimAll(Row.ProductDescription), Row.LineNumber, ?(ValueIsFilled(Row.ItemReceipt), Row.ItemReceipt, Row.Order));
			EndIf;
			
		ElsIf Row.UninvoicedQuantity < 0 Then
			ErrorsCount = ErrorsCount + 1;
			If ErrorsCount <= 10 Then
				MessageText = MessageText + ?(Not IsBlankString(MessageText), Chars.LF, "") +
				                            StringFunctionsClientServer.SubstituteParametersInString(
				                            NStr("en = 'The invoiced quantity of product %1 in line %2 exceeds ordered quantity in %3.'"), TrimAll(Row.ProductCode) + " " + TrimAll(Row.ProductDescription), Row.LineNumber, ?(ValueIsFilled(Row.ItemReceipt), Row.ItemReceipt, Row.Order));
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
			             Query_Filling_Document_PurchaseOrder_SerialNumbers(TablesList) +
			             Query_Filling_Document_PurchaseOrder_Totals(TablesList);
			
		ElsIf FillingData.Key = "Document_ItemReceipt" Then 
			Query.Text = Query.Text +
			             Query_Filling_Document_ItemReceipt_Attributes(TablesList) +
			             Query_Filling_Document_ItemReceipt_OrdersStatuses(TablesList) +
			             Query_Filling_Document_ItemReceipt_OrdersDispatched(TablesList) +
			             Query_Filling_Document_ItemReceipt_LineItems(TablesList) +
			             Query_Filling_Document_ItemReceipt_SerialNumbers(TablesList) +
			             Query_Filling_Document_ItemReceipt_Totals(TablesList);
			
		Else // Next filling source.
		EndIf;
		
		Query.SetParameter("FillingData_" + FillingData.Key, FillingData.Value);
	EndDo;
	
	// Add combining query.
	Query.Text = Query.Text +
	             Query_Filling_Attributes(TablesList) +
	             Query_Filling_LineItems(TablesList) +
	             Query_Filling_SerialNumbers(TablesList);
	
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
// Returns True if status passed for invoice filling.
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

// Check status of passed item receipt by ref.
// Returns True if status passed for invoice filling.
Function CheckStatusOfItemReceipt(DocumentRef, FillingRef) Export
	
	// Create new query.
	Query = New Query;
	Query.SetParameter("Ref", FillingRef);
	
	QueryText = 
		"SELECT
		|	CASE
		|		WHEN ItemReceipt.DeletionMark THEN
		|			 VALUE(Enum.OrderStatuses.Deleted)
		|		WHEN NOT ItemReceipt.Posted THEN
		|			 VALUE(Enum.OrderStatuses.Draft)
		|		WHEN OrdersStatuses.Status IS NULL THEN
		|			 VALUE(Enum.OrderStatuses.Open)
		|		WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.EmptyRef) THEN
		|			 VALUE(Enum.OrderStatuses.Open)
		|		ELSE
		|			 OrdersStatuses.Status
		|	END AS Status
		|FROM
		|	Document.ItemReceipt AS ItemReceipt
		|	LEFT JOIN InformationRegister.OrdersStatuses.SliceLast AS OrdersStatuses
		|		ON ItemReceipt.Ref = OrdersStatuses.Order
		|WHERE
		|	ItemReceipt.Ref = &Ref";
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
	
	If StatusOK Then
		MessageText = NStr("en = 'Failed to generate the %1 because %2 use Item receipt.'");
		MessageText = StringFunctionsClientServer.SubstituteParametersInString(MessageText,
		                                                                       Lower(Metadata.FindByType(TypeOf(DocumentRef)).Presentation()),
		                                                                       Lower(Metadata.FindByType(TypeOf(FillingRef)).Presentation())); 
		CommonUseClientServer.MessageToUser(MessageText, FillingRef);
	EndIf;
	
	Return StatusOK;
	
EndFunction

//------------------------------------------------------------------------------
// Document printing

// Collect document data for printing on the server.
Function PrepareDataStructuresForPrinting(DocumentRef, AdditionalProperties, PrintingTables) Export
	
	// Create list of printing tables.
	TablesList   = New Structure;
	
	// Define printing template.
	TemplateName = ?(ValueIsFilled(AdditionalProperties.TemplateName),
	                               AdditionalProperties.TemplateName,
	                               AdditionalProperties.Metadata.Synonym);
	
	// Convert multiple templates to strings array.
	If TypeOf(TemplateName) = Type("String") And Find(TemplateName, ",") > 0 Then
		TemplateName = StringFunctionsClientServer.SplitStringIntoSubstringArray(TemplateName);
		AdditionalProperties.TemplateName = TemplateName;
	EndIf;
	
	// Create a query to request document data.
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref",          DocumentRef);
	Query.SetParameter("ObjectName",   AdditionalProperties.Metadata.FullName());
	Query.SetParameter("TemplateName", TemplateName);
	
	// Query for document's tables.
	Query.Text  = Query_Printing_Document_Data(TablesList) +
	              Query_Printing_Document_Attributes(TablesList) +
	              Query_Printing_Document_LineItems(TablesList) +
	              DocumentPrinting.Query_OurCompany_Addresses_BillingAddress(TablesList) +
	              DocumentPrinting.Query_Company_Addresses_BillingAddress(TablesList) +
	              DocumentPrinting.Query_CustomPrintForms_Logo(TablesList) +
	              DocumentPrinting.Query_CustomPrintForms_Template(TablesList);
	
	// Execute query.
	QueryResult = Query.ExecuteBatch();
	
	// Save document tables in printing parameters.
	For Each DocumentTable In TablesList Do
		PrintingTables.Insert(DocumentTable.Key, QueryResult[DocumentTable.Value].Unload());
	EndDo;
	
	// Dispose query objects.
	Query.TempTablesManager.Close();
	Query = Undefined;
	
EndFunction

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
	|	CASE
	|       WHEN LineItems.ItemReceipt <> VALUE(Document.ItemReceipt.EmptyRef)
	|			THEN LineItems.ItemReceipt
	|		ELSE LineItems.Order 
	|	END                                   AS Order,
	// ------------------------------------------------------
	// Resources
	|	VALUE(Enum.OrderStatuses.Backordered) AS Status
	// ------------------------------------------------------
	// Attributes
	// ------------------------------------------------------
	|FROM
	|	Document.PurchaseInvoice.LineItems AS LineItems
	|WHERE
	|	LineItems.Ref = &Ref
	|	AND LineItems.Order <> VALUE(Document.PurchaseOrder.EmptyRef)
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
	|	LineItems.ItemReceipt                 AS ItemReceipt,
	|	LineItems.Product                     AS Product,
	|	LineItems.Unit                        AS Unit,
	|	LineItems.Location                    AS Location,
	|	LineItems.DeliveryDate                AS DeliveryDate,
	|	LineItems.Project                     AS Project,
	|	LineItems.Class                       AS Class,
	// ------------------------------------------------------
	// Resources
	|	0                                     AS Quantity,
	|	CASE WHEN LineItems.ItemReceipt <> VALUE(Document.ItemReceipt.EmptyRef)
	|        THEN 0
	|        WHEN LineItems.Product.Type = VALUE(Enum.InventoryTypes.Inventory)
	|	     THEN CASE WHEN LineItems.QtyUnits - 
	|	                    CASE WHEN OrdersDispatchedBalance.Received - OrdersDispatchedBalance.Invoiced > 0
	|	                         THEN OrdersDispatchedBalance.Received - OrdersDispatchedBalance.Invoiced
	|	                         ELSE 0 END > 0
	|	               THEN LineItems.QtyUnits - 
	|	                    CASE WHEN OrdersDispatchedBalance.Received - OrdersDispatchedBalance.Invoiced > 0
	|	                         THEN OrdersDispatchedBalance.Received - OrdersDispatchedBalance.Invoiced
	|	                         ELSE 0 END
	|	               ELSE 0 END
	|	     ELSE 0 END                       AS Received,
	|	0                                     AS ReceivedIR,
	|	LineItems.QtyUnits                    AS Invoiced
	// ------------------------------------------------------
	// Attributes
	// ------------------------------------------------------
	|FROM
	|	Document.PurchaseInvoice.LineItems AS LineItems
	|	LEFT JOIN Table_OrdersDispatched_Balance AS OrdersDispatchedBalance
	|		ON  OrdersDispatchedBalance.Company      = LineItems.Ref.Company
	|		AND OrdersDispatchedBalance.Order        = LineItems.Order
	|		AND OrdersDispatchedBalance.ItemReceipt  = LineItems.ItemReceipt
	|		AND OrdersDispatchedBalance.Product      = LineItems.Product
	|		AND OrdersDispatchedBalance.Unit         = LineItems.Unit
	|		AND OrdersDispatchedBalance.Location     = LineItems.Location
	|		AND OrdersDispatchedBalance.DeliveryDate = LineItems.DeliveryDate
	|		AND OrdersDispatchedBalance.Project      = LineItems.Project
	|		AND OrdersDispatchedBalance.Class        = LineItems.Class
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

// Query for balances data.
Function Query_OrdersDispatchedIR_Balance(TablesList)
	
	// Add OrdersDispatchedIR - Balances table to balances structure.
	TablesList.Insert("Table_OrdersDispatchedIR_Balance", TablesList.Count());
	
	// Collect orders dispatched balances.
	QueryText =
	"SELECT
	// ------------------------------------------------------
	// Dimensions
	|	OrdersDispatchedBalance.Company            AS Company,
	|	VALUE(Document.PurchaseOrder.EmptyRef)     AS Order,
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
    |       (Company, ItemReceipt) IN
	|		(SELECT DISTINCT &Company, LineItems.ItemReceipt // Requred for proper item Receipt closing
	|		 FROM Table_LineItems AS LineItems
	|        WHERE LineItems.ItemReceipt <> VALUE(Document.ItemReceipt.EmptyRef))) AS OrdersDispatchedBalance";
	
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
	|	LineItems.LocationActual              AS Location,
	|	LineItems.Lot                         AS Lot,
	// ------------------------------------------------------
	// Resources
	|	LineItems.QtyUM                       AS Quantity
	// ------------------------------------------------------
	// Attributes
	// ------------------------------------------------------
	|FROM
	|	Document.PurchaseInvoice.LineItems AS LineItems
	|WHERE
	|	    LineItems.Ref = &Ref
	|	AND LineItems.Product        <> VALUE(Catalog.Products.EmptyRef)
	|	AND LineItems.Product.HasLotsSerialNumbers
	|	AND LineItems.Product.UseLots = 0
	|	AND LineItems.LocationActual <> VALUE(Catalog.Locations.EmptyRef)
	|	AND LineItems.Lot            <> VALUE(Catalog.Lots.EmptyRef)
	|	AND LineItems.ItemReceipt     = VALUE(Document.ItemReceipt.EmptyRef)
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
	|	Document.PurchaseInvoice.SerialNumbers AS SerialNumbers
	|	LEFT JOIN Document.PurchaseInvoice.LineItems AS LineItems
	|		ON  LineItems.Ref         = SerialNumbers.Ref
	|		AND LineItems.LineID      = SerialNumbers.LineItemsLineID
	|		AND LineItems.ItemReceipt = VALUE(Document.ItemReceipt.EmptyRef)
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
	|	LineItems.LocationActual                 AS Location,
	// ------------------------------------------------------
	// Agregates
	|	SUM(LineItems.QtyUM)                     AS QuantityRequested,
	|	SUM(LineItems.LineTotal)                 AS AmountRequested
	// ------------------------------------------------------
	|INTO
	|	Table_InventoryJournal_LineItems
	|FROM
	|	Document.PurchaseInvoice.LineItems AS LineItems
	|WHERE
	|	    LineItems.Ref                   = &Ref
	|   AND LineItems.ItemReceipt           = VALUE(Document.ItemReceipt.EmptyRef)
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
	|	SUM(LineItems.QtyUM)                     AS QuantityRequested,
	|	SUM(LineItems.LineTotal)                 AS AmountRequested
	// ------------------------------------------------------
	|FROM
	|	Document.PurchaseInvoice.LineItems AS LineItems
	|WHERE
	|	    LineItems.Ref                   = &Ref
	|   AND LineItems.ItemReceipt           = VALUE(Document.ItemReceipt.EmptyRef)
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
	|	SUM(LineItems.QtyUM)                     AS QuantityRequested,
	|	SUM(LineItems.LineTotal)                 AS AmountRequested
	// ------------------------------------------------------
	|FROM
	|	Document.PurchaseInvoice.LineItems AS LineItems
	|WHERE
	|	    LineItems.Ref                   = &Ref
	|   AND LineItems.ItemReceipt           = VALUE(Document.ItemReceipt.EmptyRef)
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
	|	PurchaseInvoice.Ref                   AS Recorder,
	|	PurchaseInvoice.Date                  AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Dimensions
	|	LineItems_FIFO.Product                AS Product,
	|	LineItems_FIFO.Location               AS Location,
	|	PurchaseInvoice.Ref                   AS Layer,
	// ------------------------------------------------------
	// Resources
	|	LineItems_FIFO.QuantityRequested      AS Quantity,
	|	CAST( // Format(LineTotal * ExchangeRate, ""ND=17; NFD=2"")
	|		LineItems_FIFO.AmountRequested * PurchaseInvoice.ExchangeRate
	|		AS NUMBER (17, 2))                AS Amount
	// ------------------------------------------------------
	// Attributes
	// ------------------------------------------------------
	|FROM
	|	Table_InventoryJournal_LineItems AS LineItems_FIFO
	|	LEFT JOIN Document.PurchaseInvoice AS PurchaseInvoice
	|		ON PurchaseInvoice.Ref = &Ref
	|WHERE
	|	    LineItems_FIFO.Type = VALUE(Enum.InventoryCosting.FIFO)
	|	AND LineItems_FIFO.QuantityRequested > 0
	|
	|UNION ALL
	|
	|SELECT // WeightedAverage by quantity
	// ------------------------------------------------------
	// Standard attributes
	|	PurchaseInvoice.Ref                   AS Recorder,
	|	PurchaseInvoice.Date                  AS Period,
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
	|	LEFT JOIN Document.PurchaseInvoice AS PurchaseInvoice
	|		ON PurchaseInvoice.Ref = &Ref
	|WHERE
	|	    LineItems_WAve.Type      = VALUE(Enum.InventoryCosting.WeightedAverage)
	|	AND LineItems_WAve.Location <> VALUE(Catalog.Locations.EmptyRef)
	|	AND LineItems_WAve.QuantityRequested > 0
	|
	|UNION ALL
	|
	|SELECT // WeightedAverage by amount
	// ------------------------------------------------------
	// Standard attributes
	|	PurchaseInvoice.Ref                   AS Recorder,
	|	PurchaseInvoice.Date                  AS Period,
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
	|		LineItems_WAve.AmountRequested * PurchaseInvoice.ExchangeRate
	|		AS NUMBER (17, 2))                AS Amount
	// ------------------------------------------------------
	// Attributes
	// ------------------------------------------------------
	|FROM
	|	Table_InventoryJournal_LineItems AS LineItems_WAve
	|	LEFT JOIN Document.PurchaseInvoice AS PurchaseInvoice
	|		ON PurchaseInvoice.Ref = &Ref
	|WHERE
	|	    LineItems_WAve.Type     = VALUE(Enum.InventoryCosting.WeightedAverage)
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
	|	LineItems.Product.Type                          AS Type,
	|	LineItems.Product.COGSAccount                   AS COGSAccount,
	|   CASE
	|       WHEN LineItems.Product.Type = VALUE(Enum.InventoryTypes.Inventory) AND LineItems.ItemReceipt <> VALUE(Document.ItemReceipt.EmptyRef)
	|		THEN Constants.OCLAccount
	|       ELSE LineItems.Product.InventoryOrExpenseAccount
	|   END                                             AS InvOrExpAccount,
	|	LineItems.Class                                 AS Class,
	|	LineItems.Project                               AS Project,
	// ------------------------------------------------------
	// Resources
	|	LineItems.LineTotal                             AS Amount,
	|	ISNULL(
	|          CAST(
	|
	|               CAST(LineItems.QtyUnits * CASE
	|					                          WHEN LineItemsIR.Product.PricePrecision = 3
	|						                      THEN CAST(LineItemsIR.PriceUnits AS NUMBER(17, 3))
	|		     			                      WHEN LineItemsIR.Product.PricePrecision = 4
	|						                      THEN CAST(LineItemsIR.PriceUnits AS NUMBER(17, 4))
	|					                          ELSE CAST(LineItemsIR.PriceUnits AS NUMBER(17, 2))
	|				                          END 
	|                    AS NUMBER(17, 2)) 
	|
	|               * CASE
	|				      WHEN LineItemsIR.Ref.ExchangeRate > 0
	|				      THEN LineItemsIR.Ref.ExchangeRate
	|				      ELSE 1
	|				  END 
	|
	|		        / CASE
	|                     WHEN LineItems.Ref.ExchangeRate > 0
	|			          THEN LineItems.Ref.ExchangeRate
	|			          ELSE 1 
	|                 END
	|
	|               AS NUMBER(17, 2))
	|
	|          , LineItems.LineTotal)                   AS IRAmount	
	// ------------------------------------------------------
	|INTO
	|	Table_GeneralJournal_LineItems
	|FROM
	|	Document.PurchaseInvoice.LineItems AS LineItems
	|		LEFT JOIN Document.ItemReceipt.LineItems AS LineItemsIR
	|		ON      LineItems.ItemReceipt  = LineItemsIR.Ref
	|			AND LineItems.Order        = LineItemsIR.Order
	|			AND LineItems.Product      = LineItemsIR.Product
	|           AND LineItems.Product.Type = VALUE(Enum.InventoryTypes.Inventory)
	|			AND LineItems.Unit         = LineItemsIR.Unit
	|			AND LineItems.Location     = LineItemsIR.LocationOrder
	|			AND LineItems.DeliveryDate = LineItemsIR.DeliveryDateOrder
	|			AND LineItems.Project      = LineItemsIR.Project
	|			AND LineItems.Class        = LineItemsIR.Class
	|		LEFT JOIN Constants AS Constants
	|		ON (TRUE)
	|WHERE
	|	LineItems.Ref = &Ref
	|
	|UNION ALL
	|
	|SELECT
	// ------------------------------------------------------
	// Dimensions
	|	VALUE(Enum.InventoryTypes.EmptyRef)             AS Type,
	|	VALUE(ChartOfAccounts.ChartOfAccounts.EmptyRef) AS COGSAccount,
	|	Accounts.Account                                AS InvOrExpAccount,
	|	Accounts.Class                                  AS Class,
	|	Accounts.Project                                AS Project,
	// ------------------------------------------------------
	// Resources
	|	Accounts.Amount                                 AS Amount,
	|   Accounts.Amount                                 AS IRAmount
	// ------------------------------------------------------
	|FROM
	|	Document.PurchaseInvoice.Accounts AS Accounts
	|WHERE
	|	Accounts.Ref = &Ref";
	
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
	|	SUM(Accounts.IRAmount)                AS Amount
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
Function Query_GeneralJournal_Accounts_ExpAP(TablesList)
	
	// Add GeneralJournal AP or expenses accounts table to document structure.
	TablesList.Insert("Table_GeneralJournal_Accounts_ExpAP", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // ExpAP accounts selection
	// ------------------------------------------------------
	// Dimensions
	|	Constants.ExpenseAccount  AS ExpenseAccount,
	// ------------------------------------------------------
	// Resources
	|	SUM(Accounts.Amount)      AS Amount,
	|	SUM(Accounts.IRAmount)    AS IRAmount
	// ------------------------------------------------------
	|INTO
	|	Table_GeneralJournal_Accounts_ExpAP
	|FROM
	|	Table_GeneralJournal_LineItems AS Accounts
	|		LEFT JOIN Constants AS Constants
	|		ON (TRUE)
	|GROUP BY
	|	Constants.ExpenseAccount";
	
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
	|	PurchaseInvoice.Ref                   AS Recorder,
	|	PurchaseInvoice.Date                  AS Period,
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
	|	CASE 	WHEN InvOrExp.InvOrExpAccount.AccountType = VALUE(Enum.AccountTypes.Bank)
	|			THEN InvOrExp.InvOrExpAccount.Currency
	|			ELSE NULL
	|	END 								  AS Currency, // Changed to case by MISA
	// ------------------------------------------------------
	// Resources
	|	CASE 	WHEN InvOrExp.InvOrExpAccount.AccountType = VALUE(Enum.AccountTypes.Bank)
	|			THEN InvOrExp.Amount
	|			ELSE NULL
	|	END 								  AS Amount,   // Changed to case by MISA
	|	CAST( // Format(Amount * ExchangeRate, ""ND=17; NFD=2"")
	|		InvOrExp.Amount *
	|		CASE WHEN PurchaseInvoice.ExchangeRate > 0
	|			 THEN PurchaseInvoice.ExchangeRate
	|			 ELSE 1 END
	|		AS NUMBER (17, 2))                AS AmountRC,
	// ------------------------------------------------------
	// Attributes
	|	NULL                                  AS Memo
	// ------------------------------------------------------
	|FROM
	|	Table_GeneralJournal_Accounts_InvOrExp AS InvOrExp
	|	LEFT JOIN Document.PurchaseInvoice AS PurchaseInvoice
	|		ON PurchaseInvoice.Ref = &Ref
	|WHERE
	|	// Amount > 0
	|	InvOrExp.Amount > 0
	|
	|UNION ALL
	|
	|SELECT // Cr: Expenses
	// ------------------------------------------------------
	// Standard attributes
	|	PurchaseInvoice.Ref                   AS Recorder,
	|	PurchaseInvoice.Date                  AS Period,
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
	|	CAST( // Format(Amount * ExchangeRate, ""ND=17; NFD=2"")
	|		-InvOrExp.Amount *
	|		CASE WHEN PurchaseInvoice.ExchangeRate > 0
	|			 THEN PurchaseInvoice.ExchangeRate
	|			 ELSE 1 END
	|		AS NUMBER (17, 2))                AS AmountRC,
	// ------------------------------------------------------
	// Attributes
	|	NULL                                  AS Memo
	// ------------------------------------------------------
	|FROM
	|	Table_GeneralJournal_Accounts_InvOrExp AS InvOrExp
	|	LEFT JOIN Document.PurchaseInvoice AS PurchaseInvoice
	|		ON PurchaseInvoice.Ref = &Ref
	|WHERE
	|	// Amount > 0
	|	-InvOrExp.Amount > 0
	|
	|UNION ALL
	|
	|SELECT // Cr: Accounts payable
	// ------------------------------------------------------
	// Standard attributes
	|	PurchaseInvoice.Ref                   AS Recorder,
	|	PurchaseInvoice.Date                  AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccountingRecordType.Credit)    AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Accounting attributes
	|	PurchaseInvoice.APAccount             AS Account,
	|	VALUE(ChartOfCharacteristicTypes.Dimensions.Company)
	|	                                      AS ExtDimensionType1,
	|	PurchaseInvoice.Company               AS ExtDimension1,
	|	VALUE(ChartOfCharacteristicTypes.Dimensions.Document)
	|	                                      AS ExtDimensionType2,
	|	PurchaseInvoice.Ref                   AS ExtDimension2,
	// ------------------------------------------------------
	// Dimensions
	|	PurchaseInvoice.Currency              AS Currency,
	// ------------------------------------------------------
	// Resources
	|	ExpAP.IRAmount                        AS Amount,
	|	CAST( // Format(Amount * ExchangeRate, ""ND=17; NFD=2"")
	|		ExpAP.IRAmount *
	|		CASE WHEN PurchaseInvoice.ExchangeRate > 0
	|			 THEN PurchaseInvoice.ExchangeRate
	|			 ELSE 1 END
	|		AS NUMBER (17, 2))                AS AmountRC,
	// ------------------------------------------------------
	// Attributes
	|	Null                                  AS Memo
	// ------------------------------------------------------
	|FROM
	|	Table_GeneralJournal_Accounts_ExpAP AS ExpAP
	|	LEFT JOIN Document.PurchaseInvoice AS PurchaseInvoice
	|		ON PurchaseInvoice.Ref = &Ref
	|WHERE
	|	// Amount > 0
	|	ExpAP.IRAmount > 0
	|
	|UNION ALL
	|
	|SELECT // Dr: Accounts payable
	// ------------------------------------------------------
	// Standard attributes
	|	PurchaseInvoice.Ref                   AS Recorder,
	|	PurchaseInvoice.Date                  AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccountingRecordType.Debit)     AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Accounting attributes
	|	PurchaseInvoice.APAccount             AS Account,
	|	VALUE(ChartOfCharacteristicTypes.Dimensions.Company)
	|	                                      AS ExtDimensionType1,
	|	PurchaseInvoice.Company               AS ExtDimension1,
	|	VALUE(ChartOfCharacteristicTypes.Dimensions.Document)
	|	                                      AS ExtDimensionType2,
	|	PurchaseInvoice.Ref                   AS ExtDimension2,
	// ------------------------------------------------------
	// Dimensions
	|	PurchaseInvoice.Currency              AS Currency,
	// ------------------------------------------------------
	// Resources
	|	-ExpAP.IRAmount                       AS Amount,
	|	CAST( // Format(Amount * ExchangeRate, ""ND=17; NFD=2"")
	|		-ExpAP.IRAmount *
	|		CASE WHEN PurchaseInvoice.ExchangeRate > 0
	|			 THEN PurchaseInvoice.ExchangeRate
	|			 ELSE 1 END
	|		AS NUMBER (17, 2))                AS AmountRC,
	// ------------------------------------------------------
	// Attributes
	|	Null                                  AS Memo
	// ------------------------------------------------------
	|FROM
	|	Table_GeneralJournal_Accounts_ExpAP AS ExpAP
	|	LEFT JOIN Document.PurchaseInvoice AS PurchaseInvoice
	|		ON PurchaseInvoice.Ref = &Ref
	|WHERE
	|	// Amount > 0
	|	-ExpAP.IRAmount > 0
	|
	|UNION ALL
	|
	|SELECT // Dr or Cr: Purchase variance
	// ------------------------------------------------------
	// Standard attributes
	|	PurchaseInvoice.Ref                   AS Recorder,
	|	PurchaseInvoice.Date                  AS Period,
	|	0                                     AS LineNumber,
	|	CASE WHEN ExpAP.Amount - ExpAP.IRAmount > 0
	|	     THEN VALUE(AccountingRecordType.Debit)
	|	     ELSE VALUE(AccountingRecordType.Credit)
	|	END                                   AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Accounting attributes
	|	ExpAP.ExpenseAccount                  AS Account,
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
	|	     CASE WHEN ExpAP.Amount - ExpAP.IRAmount > 0
	|	          THEN ExpAP.Amount - ExpAP.IRAmount
	|	          ELSE ExpAP.IRAmount - ExpAP.Amount
	|	     END *
	|	     CASE WHEN PurchaseInvoice.ExchangeRate > 0
	|	          THEN PurchaseInvoice.ExchangeRate
	|	          ELSE 1 END
	|	     AS NUMBER (17, 2))               AS AmountRC,
	// ------------------------------------------------------
	// Attributes
	|	Null                                  AS Memo
	// ------------------------------------------------------
	|FROM
	|	Table_GeneralJournal_Accounts_ExpAP AS ExpAP
	|	LEFT JOIN Document.PurchaseInvoice AS PurchaseInvoice
	|		ON PurchaseInvoice.Ref = &Ref
	|WHERE
	|	// Amount <> IRAmount
	|	ExpAP.Amount - ExpAP.IRAmount <> 0
	|
	|UNION ALL
	|
	|SELECT // Dr or Cr: Accounts payable
	// ------------------------------------------------------
	// Standard attributes
	|	PurchaseInvoice.Ref                   AS Recorder,
	|	PurchaseInvoice.Date                  AS Period,
	|	0                                     AS LineNumber,
	|	CASE WHEN ExpAP.Amount - ExpAP.IRAmount > 0
	|	     THEN VALUE(AccountingRecordType.Credit)
	|	     ELSE VALUE(AccountingRecordType.Debit)
	|	END                                   AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Accounting attributes
	|	PurchaseInvoice.APAccount             AS Account,
	|	VALUE(ChartOfCharacteristicTypes.Dimensions.Company)
	|	                                      AS ExtDimensionType1,
	|	PurchaseInvoice.Company               AS ExtDimension1,
	|	VALUE(ChartOfCharacteristicTypes.Dimensions.Document)
	|	                                      AS ExtDimensionType2,
	|	PurchaseInvoice.Ref                   AS ExtDimension2,
	// ------------------------------------------------------
	// Dimensions
	|	PurchaseInvoice.Currency              AS Currency,
	// ------------------------------------------------------
	// Resources
	|	CASE WHEN ExpAP.Amount - ExpAP.IRAmount > 0
	|	     THEN ExpAP.Amount - ExpAP.IRAmount
	|	     ELSE ExpAP.IRAmount - ExpAP.Amount
	|	END                                   AS Amount,
	|	CAST( // Format(Amount * ExchangeRate, ""ND=17; NFD=2"")
	|	     CASE WHEN ExpAP.Amount - ExpAP.IRAmount > 0
	|	          THEN ExpAP.Amount - ExpAP.IRAmount
	|	          ELSE ExpAP.IRAmount - ExpAP.Amount
	|	     END *
	|	     CASE WHEN PurchaseInvoice.ExchangeRate > 0
	|	          THEN PurchaseInvoice.ExchangeRate
	|	          ELSE 1 END
	|	     AS NUMBER (17, 2))               AS AmountRC,
	// ------------------------------------------------------
	// Attributes
	|	Null                                  AS Memo
	// ------------------------------------------------------
	|FROM
	|   Table_GeneralJournal_Accounts_ExpAP AS ExpAP
	|	LEFT JOIN Document.PurchaseInvoice AS PurchaseInvoice
	|		ON PurchaseInvoice.Ref = &Ref
	|WHERE
	|	// Amount <> IRAmount
	|	ExpAP.Amount - ExpAP.IRAmount <> 0";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

//--//GJ++

// Query for document data.
Function Query_GeneralJournalAnalyticsDimensions_Accounts_InvOrExp(TablesList)
	
	// Add GeneralJournalAnalyticsDimensions inventory or expenses accounts table to document structure.
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
	|	SUM(Accounts.IRAmount)                AS Amount
	// ------------------------------------------------------
	|INTO
	|	Table_GeneralJournalAnalyticsDimensions_Accounts_InvOrExp
	|FROM
	|	Table_GeneralJournal_LineItems AS Accounts
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
		|	InvOrExp_Dimensions.InvOrExpAccount        AS InvOrExpAccount,
		// ------------------------------------------------------
		// Resources
		|	CAST( // Format(Amount * ExchangeRate, ""ND=17; NFD=2"")
		|		InvOrExp_Dimensions.Amount *
		|		CASE WHEN PurchaseInvoice.ExchangeRate > 0
		|			 THEN PurchaseInvoice.ExchangeRate
		|			 ELSE 1 END
		|		AS NUMBER (17, 2))                     AS Amount
		// ------------------------------------------------------
		|INTO
		|	Table_GeneralJournalAnalyticsDimensions_Accounts_InvOrExp_Difference_Amount
		|FROM
		|	Table_GeneralJournal_Accounts_InvOrExp AS InvOrExp_Dimensions
		|	LEFT JOIN Document.PurchaseInvoice AS PurchaseInvoice
		|		ON PurchaseInvoice.Ref = &Ref
		|WHERE
		|	// Amount > 0
		|	InvOrExp_Dimensions.Amount > 0
		|
		|UNION ALL
		|
		|SELECT // InvOrExp Dimensions accounts selection
		// ------------------------------------------------------
		// Dimensions
		|	InvOrExp_Dimensions.InvOrExpAccount        AS InvOrExpAccount,
		// ------------------------------------------------------
		// Resources
		|	CAST( // Format(Amount * ExchangeRate, ""ND=17; NFD=2"")
		|		InvOrExp_Dimensions.Amount *
		|		CASE WHEN PurchaseInvoice.ExchangeRate > 0
		|			 THEN PurchaseInvoice.ExchangeRate
		|			 ELSE 1 END
		|		AS NUMBER (17, 2)) * -1                AS Amount
		// ------------------------------------------------------
		|FROM
		|	Table_GeneralJournalAnalyticsDimensions_Accounts_InvOrExp AS InvOrExp_Dimensions
		|	LEFT JOIN Document.PurchaseInvoice AS PurchaseInvoice
		|		ON PurchaseInvoice.Ref = &Ref
		|WHERE
		|	// Amount > 0
		|	InvOrExp_Dimensions.Amount > 0";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_GeneralJournalAnalyticsDimensions_Accounts_InvOrExp_Difference(TablesList)
	
	// Add GeneralJournalAnalyticsDimensions difference InvOrExp table to document structure.
	TablesList.Insert("Table_GeneralJournalAnalyticsDimensions_Accounts_InvOrExp_Difference", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // Dimensions difference selection
	// Dimensions
	// ------------------------------------------------------
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
Function Query_GeneralJournalAnalyticsDimensions_Accounts_InvOrExpNeg_Difference_Amount(TablesList)
	
	// Add GeneralJournalAnalyticsDimensions difference InvOrExpNeg amount table to document structure.
	TablesList.Insert("Table_GeneralJournalAnalyticsDimensions_Accounts_InvOrExpNeg_Difference_Amount", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
		"SELECT // InvOrExpNeg accounts selection
		// ------------------------------------------------------
		// Dimensions
		|	InvOrExpNeg_Dimensions.InvOrExpAccount   AS InvOrExpAccount,
		// ------------------------------------------------------
		// Resources
		|	CAST( // Format(Amount * ExchangeRate, ""ND=17; NFD=2"")
		|		-InvOrExpNeg_Dimensions.Amount *
		|		CASE WHEN PurchaseInvoice.ExchangeRate > 0
		|			 THEN PurchaseInvoice.ExchangeRate
		|			 ELSE 1 END
		|		AS NUMBER (17, 2))                   AS Amount
		// ------------------------------------------------------
		|INTO
		|	Table_GeneralJournalAnalyticsDimensions_Accounts_InvOrExpNeg_Difference_Amount
		|FROM
		|	Table_GeneralJournal_Accounts_InvOrExp AS InvOrExpNeg_Dimensions
		|	LEFT JOIN Document.PurchaseInvoice AS PurchaseInvoice
		|		ON PurchaseInvoice.Ref = &Ref
		|WHERE
		|	// Amount > 0
		|	-InvOrExpNeg_Dimensions.Amount > 0
		|
		|UNION ALL
		|
		|SELECT // InvOrExpNeg Dimensions accounts selection
		// ------------------------------------------------------
		// Dimensions
		|	InvOrExpNeg_Dimensions.InvOrExpAccount   AS InvOrExpAccount,
		// ------------------------------------------------------
		// Resources
		|	CAST( // Format(Amount * ExchangeRate, ""ND=17; NFD=2"")
		|		-InvOrExpNeg_Dimensions.Amount *
		|		CASE WHEN PurchaseInvoice.ExchangeRate > 0
		|			 THEN PurchaseInvoice.ExchangeRate
		|			 ELSE 1 END
		|		AS NUMBER (17, 2)) * -1              AS Amount
		// ------------------------------------------------------
		|FROM
		|	Table_GeneralJournalAnalyticsDimensions_Accounts_InvOrExp AS InvOrExpNeg_Dimensions
		|	LEFT JOIN Document.PurchaseInvoice AS PurchaseInvoice
		|		ON PurchaseInvoice.Ref = &Ref
		|WHERE
		|	// Amount > 0
		|	-InvOrExpNeg_Dimensions.Amount > 0";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_GeneralJournalAnalyticsDimensions_Accounts_InvOrExpNeg_Difference(TablesList)
	
	// Add GeneralJournalAnalyticsDimensions difference InvOrExpNeg table to document structure.
	TablesList.Insert("Table_GeneralJournalAnalyticsDimensions_Accounts_InvOrExpNeg_Difference", TablesList.Count());
	
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
	|	Table_GeneralJournalAnalyticsDimensions_Accounts_InvOrExpNeg_Difference
	|FROM
	|	Table_GeneralJournalAnalyticsDimensions_Accounts_InvOrExpNeg_Difference_Amount AS DimensionsDifference
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
	"SELECT // Receipt: Inventory
	// ------------------------------------------------------
	// Standard attributes
	|	PurchaseInvoice.Ref                   AS Recorder,
	|	PurchaseInvoice.Date                  AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Accounting attributes
	|	InvOrExp.InvOrExpAccount              AS Account,
	// ------------------------------------------------------
	// Dimensions
	|	PurchaseInvoice.Company               AS Company,
	|	InvOrExp.Class                        AS Class,
	|	InvOrExp.Project                      AS Project,
	// ------------------------------------------------------
	// Resources
	|	CAST( // Format(Amount * ExchangeRate, ""ND=17; NFD=2"")
	|		InvOrExp.Amount *
	|		CASE WHEN PurchaseInvoice.ExchangeRate > 0
	|			 THEN PurchaseInvoice.ExchangeRate
	|			 ELSE 1 END
	|		AS NUMBER (17, 2))                AS AmountRC,
	// ------------------------------------------------------
	// Attributes
	|	1                                     AS JournalEntryIntNum,
	|	False                                 AS JournalEntryMainRec
	// ------------------------------------------------------
	|INTO Table_GeneralJournalAnalyticsDimensions_Transactions
	|FROM
	|	Table_GeneralJournalAnalyticsDimensions_Accounts_InvOrExp AS InvOrExp
	|	LEFT JOIN Document.PurchaseInvoice AS PurchaseInvoice
	|		ON PurchaseInvoice.Ref = &Ref
	|WHERE
	|	// Amount > 0
	|	InvOrExp.Amount > 0
	|
	|UNION ALL
	|
	|SELECT // Receipt: Inventory (difference)
	// ------------------------------------------------------
	// Standard attributes
	|	PurchaseInvoice.Ref                   AS Recorder,
	|	PurchaseInvoice.Date                  AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Accounting attributes
	|	InvOrExp.InvOrExpAccount              AS Account,
	// ------------------------------------------------------
	// Dimensions
	|	PurchaseInvoice.Company               AS Company,
	|	NULL                                  AS Class,
	|	NULL                                  AS Project,
	// ------------------------------------------------------
	// Resources
	|	InvOrExp.Amount                       AS AmountRC,
	// ------------------------------------------------------
	// Attributes
	|	1                                     AS JournalEntryIntNum,
	|	False                                 AS JournalEntryMainRec
	// ------------------------------------------------------
	|FROM
	|	Table_GeneralJournalAnalyticsDimensions_Accounts_InvOrExp_Difference AS InvOrExp
	|	LEFT JOIN Document.PurchaseInvoice AS PurchaseInvoice
	|		ON PurchaseInvoice.Ref = &Ref
	|WHERE
	|	// Amount <> 0
	|	InvOrExp.Amount <> 0
	|
	|UNION ALL
	|
	|SELECT // Expense: Expenses
	// ------------------------------------------------------
	// Standard attributes
	|	PurchaseInvoice.Ref                   AS Recorder,
	|	PurchaseInvoice.Date                  AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Accounting attributes
	|	InvOrExp.InvOrExpAccount              AS Account,
	// ------------------------------------------------------
	// Dimensions
	|	PurchaseInvoice.Company               AS Company,
	|	InvOrExp.Class                        AS Class,
	|	InvOrExp.Project                      AS Project,
	// ------------------------------------------------------
	// Resources
	|	CAST( // Format(Amount * ExchangeRate, ""ND=17; NFD=2"")
	|		-InvOrExp.Amount *
	|		CASE WHEN PurchaseInvoice.ExchangeRate > 0
	|			 THEN PurchaseInvoice.ExchangeRate
	|			 ELSE 1 END
	|		AS NUMBER (17, 2))                AS AmountRC,
	// ------------------------------------------------------
	// Attributes
	|	1                                     AS JournalEntryIntNum,
	|	False                                 AS JournalEntryMainRec
	// ------------------------------------------------------
	|FROM
	|	Table_GeneralJournalAnalyticsDimensions_Accounts_InvOrExp AS InvOrExp
	|	LEFT JOIN Document.PurchaseInvoice AS PurchaseInvoice
	|		ON PurchaseInvoice.Ref = &Ref
	|WHERE
	|	// Amount > 0
	|	-InvOrExp.Amount > 0
	|
	|UNION ALL
	|
	|SELECT // Expense: Expenses (difference)
	// ------------------------------------------------------
	// Standard attributes
	|	PurchaseInvoice.Ref                   AS Recorder,
	|	PurchaseInvoice.Date                  AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Accounting attributes
	|	InvOrExp.InvOrExpAccount              AS Account,
	// ------------------------------------------------------
	// Dimensions
	|	PurchaseInvoice.Company               AS Company,
	|	NULL                                  AS Class,
	|	NULL                                  AS Project,
	// ------------------------------------------------------
	// Resources
	|	InvOrExp.Amount                       AS AmountRC,
	// ------------------------------------------------------
	// Attributes
	|	1                                     AS JournalEntryIntNum,
	|	False                                 AS JournalEntryMainRec
	// ------------------------------------------------------
	|FROM
	|	Table_GeneralJournalAnalyticsDimensions_Accounts_InvOrExpNeg_Difference AS InvOrExp
	|	LEFT JOIN Document.PurchaseInvoice AS PurchaseInvoice
	|		ON PurchaseInvoice.Ref = &Ref
	|WHERE
	|	// Amount <> 0
	|	InvOrExp.Amount <> 0
	|
	|UNION ALL
	|
	|SELECT // Expense: Accounts payable
	// ------------------------------------------------------
	// Standard attributes
	|	PurchaseInvoice.Ref                   AS Recorder,
	|	PurchaseInvoice.Date                  AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Accounting attributes
	|	PurchaseInvoice.APAccount             AS Account,
	// ------------------------------------------------------
	// Dimensions
	|	PurchaseInvoice.Company               AS Company,
	|	NULL                                  AS Class,
	|	NULL                                  AS Project,
	// ------------------------------------------------------
	// Resources
	|	CAST( // Format(Amount * ExchangeRate, ""ND=17; NFD=2"")
	|		ExpAP.IRAmount *
	|		CASE WHEN PurchaseInvoice.ExchangeRate > 0
	|			 THEN PurchaseInvoice.ExchangeRate
	|			 ELSE 1 END
	|		AS NUMBER (17, 2))                AS AmountRC,
	// ------------------------------------------------------
	// Attributes
	|	1                                     AS JournalEntryIntNum,
	|	True                                  AS JournalEntryMainRec
	// ------------------------------------------------------
	|FROM
	|	Table_GeneralJournal_Accounts_ExpAP AS ExpAP
	|	LEFT JOIN Document.PurchaseInvoice AS PurchaseInvoice
	|		ON PurchaseInvoice.Ref = &Ref
	|WHERE
	|	// Amount > 0
	|	ExpAP.IRAmount > 0
	|
	|UNION ALL
	|
	|SELECT // Receipt: Accounts payable
	// ------------------------------------------------------
	// Standard attributes
	|	PurchaseInvoice.Ref                   AS Recorder,
	|	PurchaseInvoice.Date                  AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Accounting attributes
	|	PurchaseInvoice.APAccount             AS Account,
	// ------------------------------------------------------
	// Dimensions
	|	PurchaseInvoice.Company               AS Company,
	|	NULL                                  AS Class,
	|	NULL                                  AS Project,
	// ------------------------------------------------------
	// Resources
	|	CAST( // Format(Amount * ExchangeRate, ""ND=17; NFD=2"")
	|		-ExpAP.IRAmount *
	|		CASE WHEN PurchaseInvoice.ExchangeRate > 0
	|			 THEN PurchaseInvoice.ExchangeRate
	|			 ELSE 1 END
	|		AS NUMBER (17, 2))                AS AmountRC,
	// ------------------------------------------------------
	// Attributes
	|	1                                     AS JournalEntryIntNum,
	|	True                                  AS JournalEntryMainRec
	// ------------------------------------------------------
	|FROM
	|	Table_GeneralJournal_Accounts_ExpAP AS ExpAP
	|	LEFT JOIN Document.PurchaseInvoice AS PurchaseInvoice
	|		ON PurchaseInvoice.Ref = &Ref
	|WHERE
	|	// Amount > 0
	|	-ExpAP.IRAmount > 0
	|
	|UNION ALL
	|
	|SELECT // Receipt or Expense: Purchase variance
	// ------------------------------------------------------
	// Standard attributes
	|	PurchaseInvoice.Ref                   AS Recorder,
	|	PurchaseInvoice.Date                  AS Period,
	|	0                                     AS LineNumber,
	|	CASE WHEN ExpAP.Amount - ExpAP.IRAmount > 0
	|        THEN VALUE(AccumulationRecordType.Receipt)
	|        ELSE VALUE(AccumulationRecordType.Expense)
	|	END                                   AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Accounting attributes
	|	ExpAP.ExpenseAccount                  AS Account,
	// ------------------------------------------------------
	// Dimensions
	|	PurchaseInvoice.Company               AS Company,
	|	NULL                                  AS Class,
	|	NULL                                  AS Project,
	// ------------------------------------------------------
	// Resources
	|	CAST( // Format(Amount * ExchangeRate, ""ND=17; NFD=2"")
	|	     CASE WHEN ExpAP.Amount - ExpAP.IRAmount > 0
	|             THEN ExpAP.Amount - ExpAP.IRAmount
	|             ELSE ExpAP.IRAmount - ExpAP.Amount
	|        END *
	|		 CASE WHEN PurchaseInvoice.ExchangeRate > 0
	|		      THEN PurchaseInvoice.ExchangeRate
	|			  ELSE 1 END
	|		 AS NUMBER (17, 2))               AS AmountRC,
	// ------------------------------------------------------
	// Attributes
	|	1                                     AS JournalEntryIntNum,
	|	False                                 AS JournalEntryMainRec
	// ------------------------------------------------------
	|FROM
	|   Table_GeneralJournal_Accounts_ExpAP AS ExpAP
	|	LEFT JOIN Document.PurchaseInvoice AS PurchaseInvoice
	|		ON PurchaseInvoice.Ref = &Ref
	|WHERE
	|	// Amount <> IRAmount
	|	ExpAP.Amount - ExpAP.IRAmount <> 0
	|
	|UNION ALL
	|
	|SELECT // Receipt or Expense: Accounts payable
	// ------------------------------------------------------
	// Standard attributes
	|	PurchaseInvoice.Ref                   AS Recorder,
	|	PurchaseInvoice.Date                  AS Period,
	|	0                                     AS LineNumber,
	|	CASE WHEN ExpAP.Amount - ExpAP.IRAmount > 0
	|        THEN VALUE(AccumulationRecordType.Expense)
	|        ELSE VALUE(AccumulationRecordType.Receipt)
	|	END                                   AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Accounting attributes
	|	PurchaseInvoice.APAccount             AS Account,
	// ------------------------------------------------------
	// Dimensions
	|	PurchaseInvoice.Company               AS Company,
	|	NULL                                  AS Class,
	|	NULL                                  AS Project,
	// ------------------------------------------------------
	// Resources
	|	CAST( // Format(Amount * ExchangeRate, ""ND=17; NFD=2"")
	|	     CASE WHEN ExpAP.Amount - ExpAP.IRAmount > 0
	|             THEN ExpAP.Amount - ExpAP.IRAmount
	|             ELSE ExpAP.IRAmount - ExpAP.Amount
	|        END *
	|		 CASE WHEN PurchaseInvoice.ExchangeRate > 0
	|		      THEN PurchaseInvoice.ExchangeRate
	|			  ELSE 1 END
	|		 AS NUMBER (17, 2))               AS AmountRC,
	// ------------------------------------------------------
	// Attributes
	|	1                                     AS JournalEntryIntNum,
	|	True                                  AS JournalEntryMainRec
	// ------------------------------------------------------
	|FROM
	|   Table_GeneralJournal_Accounts_ExpAP AS ExpAP
	|	LEFT JOIN Document.PurchaseInvoice AS PurchaseInvoice
	|		ON PurchaseInvoice.Ref = &Ref
	|WHERE
	|	// Amount <> IRAmount
	|	ExpAP.Amount - ExpAP.IRAmount <> 0";
	
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
	|	Transaction.AmountRC                  AS AmountRC,
	// ------------------------------------------------------
	// Attributes
	|	Transaction.JournalEntryIntNum        AS JournalEntryIntNum,
	|	Transaction.JournalEntryMainRec       AS JournalEntryMainRec
	// ------------------------------------------------------
	|FROM
	|	Table_GeneralJournalAnalyticsDimensions_Transactions AS Transaction";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

//--//GJ--


// Query for document data.
Function Query_CashFlowData_Accounts_Positive(TablesList)
	
	// Add CashFlowData inventory or expenses accounts (positive) table to document structure.
	TablesList.Insert("Table_CashFlowData_Accounts_Positive", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // Positive accounts selection
	// Accounting attributes
	|	AccountsTab.Account                                  AS Account,
	// ------------------------------------------------------
	// Dimensions
	|	AccountsTab.Class                                    AS Class,
	|	AccountsTab.Project                                  AS Project,
	// ------------------------------------------------------
	// Resources
	|	AccountsTab.AmountRC                                 AS AmountRC
	// ------------------------------------------------------
	|INTO
	|	Table_CashFlowData_Accounts_Positive
	|FROM
	|	Table_GeneralJournalAnalyticsDimensions_Transactions AS AccountsTab
	|WHERE 
	|	AccountsTab.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		AND AccountsTab.Account.AccountType <> VALUE(Enum.AccountTypes.AccountsReceivable)
	|		AND AccountsTab.Account.AccountType <> VALUE(Enum.AccountTypes.AccountsPayable)";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_CashFlowData_Accounts_Positive_Amount(TablesList)
	
	// Add CashFlowData inventory or expenses accounts (positive amount) table to document structure.
	TablesList.Insert("Table_CashFlowData_Accounts_Positive_Amount", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // Positive accounts selection
	// ------------------------------------------------------
	// Resources
	|	SUM(Accounts.AmountRC)               AS AmountRC
	// ------------------------------------------------------
	|INTO
	|	Table_CashFlowData_Accounts_Positive_Amount
	|FROM
	|	Table_CashFlowData_Accounts_Positive AS Accounts";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_CashFlowData_Accounts_Negative(TablesList)
	
	// Add CashFlowData inventory or expenses accounts (negative) table to document structure.
	TablesList.Insert("Table_CashFlowData_Accounts_Negative", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // Negative accounts selection
	// ------------------------------------------------------
	// Resources
	|	AccountsTab.AmountRC                                 AS AmountRC
	// ------------------------------------------------------
	|INTO
	|	Table_CashFlowData_Accounts_Negative
	|FROM
	|	Table_GeneralJournalAnalyticsDimensions_Transactions AS AccountsTab
	|WHERE 
	|	AccountsTab.RecordType = VALUE(AccumulationRecordType.Expense)
	|		AND AccountsTab.Account.AccountType <> VALUE(Enum.AccountTypes.AccountsReceivable)
	|		AND AccountsTab.Account.AccountType <> VALUE(Enum.AccountTypes.AccountsPayable)";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_CashFlowData_Accounts_Negative_Amount(TablesList)
	
	// Add CashFlowData inventory or expenses accounts (negative amount) table to document structure.
	TablesList.Insert("Table_CashFlowData_Accounts_Negative_Amount", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // Negative accounts selection
	// ------------------------------------------------------
	// Resources
	|	SUM(Accounts.AmountRC)               AS AmountRC
	// ------------------------------------------------------
	|INTO
	|	Table_CashFlowData_Accounts_Negative_Amount
	|FROM
	|	Table_CashFlowData_Accounts_Negative AS Accounts";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_CashFlowData_Accounts_Paid(TablesList)
	
	// Add CashFlowData inventory or expenses accounts (Paid) table to document structure.
	TablesList.Insert("Table_CashFlowData_Accounts_Paid", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // Rec: Positive Inventory and Expenses (Expense)
	// ------------------------------------------------------
	// Dimensions
	|	PositivePaid.Account                 AS Account,
	// ------------------------------------------------------
	// Dimensions
	|	PositivePaid.Class                   AS Class,
	|	PositivePaid.Project                 AS Project,
	// ------------------------------------------------------
	// Resources
	|	CAST( // Format(Negative_Amount * (Positive * ExchangeRate) / Positive_Amount, ""ND=17; NFD=2"")
	|		Negative_Amount.AmountRC * PositivePaid.AmountRC / Positive_Amount.AmountRC
	|		AS NUMBER (17, 2))               AS AmountRC
	// ------------------------------------------------------
	|INTO
	|	Table_CashFlowData_Accounts_Paid	
	|FROM
	|	Table_CashFlowData_Accounts_Positive AS PositivePaid 
	|	LEFT JOIN Table_CashFlowData_Accounts_Positive_Amount AS Positive_Amount
	|		ON TRUE
	|	LEFT JOIN Table_CashFlowData_Accounts_Negative_Amount AS Negative_Amount
	|		ON TRUE
	|WHERE
	|	// Amount <> 0
	|	Negative_Amount.AmountRC <> 0
	|		AND Positive_Amount.AmountRC <> 0
	|		AND PositivePaid.AmountRC <> 0";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_CashFlowData_Accounts_Paid_Amount(TablesList)
	
	// Add CashFlowData inventory or expenses accounts (Paid amount) table to document structure.
	TablesList.Insert("Table_CashFlowData_Accounts_Paid_Amount", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // Rec: Positive Inventory and Expenses (Expense)
	// ------------------------------------------------------
	// Resources
	|	SUM(Paid.AmountRC)      AS AmountRC
	// ------------------------------------------------------
	|INTO
	|	Table_CashFlowData_Accounts_Paid_Amount	
	|FROM
	|	Table_CashFlowData_Accounts_Paid AS Paid";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_CashFlowData_Accounts_Paid_Transactions(TablesList)
	
	// Add CashFlowData_Accounts_Paid_Transactions table to document structure.
	TablesList.Insert("Table_CashFlowData_Accounts_Paid_Transactions", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // Paid Transactions
	// ------------------------------------------------------
	// Accounting attributes
	|	PaidTransaction.Account               AS Account,
	// ------------------------------------------------------
	// Dimensions
	|	PaidTransaction.Class                 AS Class,
	|	PaidTransaction.Project               AS Project,
	// ------------------------------------------------------
	// Resources
	|	PaidTransaction.AmountRC              AS AmountRC
	// ------------------------------------------------------
	|INTO Table_CashFlowData_Accounts_Paid_Transactions
	|FROM
	|	Table_CashFlowData_Accounts_Paid AS PaidTransaction
	|WHERE
	|	PaidTransaction.AmountRC <> 0
	|		AND (PaidTransaction.Account.AccountType = VALUE(Enum.AccountTypes.Income)
	|			OR PaidTransaction.Account.AccountType = VALUE(Enum.AccountTypes.CostOfSales)
	|			OR PaidTransaction.Account.AccountType = VALUE(Enum.AccountTypes.Expense)
	|			OR PaidTransaction.Account.AccountType = VALUE(Enum.AccountTypes.OtherIncome)
	|			OR PaidTransaction.Account.AccountType = VALUE(Enum.AccountTypes.OtherExpense)
	|			OR PaidTransaction.Account.AccountType = VALUE(Enum.AccountTypes.IncomeTaxExpense))
	|
	|UNION ALL
	|
	|SELECT TOP 1 // Paid Transactions (difference)
	// ------------------------------------------------------
	// Accounting attributes
	|	PaidTransaction.Account                AS Account,
	// ------------------------------------------------------
	// Dimensions
	|	PaidTransaction.Class                  AS Class,
	|	PaidTransaction.Project                AS Project,
	// ------------------------------------------------------
	// Resources
	|	Negative_Amount.AmountRC - Paid_Amount.AmountRC
	|								           AS AmountRC
	// ------------------------------------------------------
	|FROM
	|	Table_CashFlowData_Accounts_Paid AS PaidTransaction 
	|	LEFT JOIN Table_CashFlowData_Accounts_Negative_Amount AS Negative_Amount
	|		ON TRUE
	|	LEFT JOIN Table_CashFlowData_Accounts_Paid_Amount AS Paid_Amount
	|		ON TRUE
	|WHERE
	|	PaidTransaction.AmountRC <> 0
	|		AND (PaidTransaction.Account.AccountType = VALUE(Enum.AccountTypes.Income)
	|			OR PaidTransaction.Account.AccountType = VALUE(Enum.AccountTypes.CostOfSales)
	|			OR PaidTransaction.Account.AccountType = VALUE(Enum.AccountTypes.Expense)
	|			OR PaidTransaction.Account.AccountType = VALUE(Enum.AccountTypes.OtherIncome)
	|			OR PaidTransaction.Account.AccountType = VALUE(Enum.AccountTypes.OtherExpense)
	|			OR PaidTransaction.Account.AccountType = VALUE(Enum.AccountTypes.IncomeTaxExpense))
	|		AND (Negative_Amount.AmountRC - Paid_Amount.AmountRC) <> 0";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_CashFlowData_Accounts_Paid_Transactions_Corrected(TablesList)
	
	// Add CashFlowData_Accounts_Paid_Transactions_Corrected table to document structure.
	TablesList.Insert("Table_CashFlowData_Accounts_Paid_Transactions_Corrected", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // Paid Transactions
	// ------------------------------------------------------
	// Accounting attributes
	|	PaidTransaction.Account               AS Account,
	// ------------------------------------------------------
	// Dimensions
	|	PaidTransaction.Class                 AS Class,
	|	PaidTransaction.Project               AS Project,
	// ------------------------------------------------------
	// Resources
	|	SUM(PaidTransaction.AmountRC)         AS AmountRC
	// ------------------------------------------------------
	|INTO Table_CashFlowData_Accounts_Paid_Transactions_Corrected
	|FROM
	|	Table_CashFlowData_Accounts_Paid_Transactions AS PaidTransaction
	|WHERE
	|	PaidTransaction.AmountRC <> 0
	|GROUP BY
	|	PaidTransaction.Account,
	|	PaidTransaction.Class,
	|	PaidTransaction.Project";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_CashFlowData_Accounts_Paid_Transactions_Amount(TablesList)
	
	// Add CashFlowData_Accounts_Paid_Transactions_Amount table to document structure.
	TablesList.Insert("Table_CashFlowData_Accounts_Paid_Transactions_Amount", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // Paid Transactions
	// ------------------------------------------------------
	// Resources
	|	SUM(PaidTransaction.AmountRC)         AS AmountRC
	// ------------------------------------------------------
	|INTO Table_CashFlowData_Accounts_Paid_Transactions_Amount
	|FROM
	|	Table_CashFlowData_Accounts_Paid_Transactions AS PaidTransaction
	|WHERE
	|	PaidTransaction.AmountRC <> 0";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_CashFlowData_CB_Accounts(TablesList)
	
	// Add CashFlowData CashBasis Accounts table to document structure.
	TablesList.Insert("Table_CashFlowData_CB_Accounts", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // CashBasis Accounts
	// ------------------------------------------------------
	// Resources
	|	CASE
	|		WHEN Transaction.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN Transaction.AmountRC                   
	|		ELSE Transaction.AmountRC * -1
	|	END                                                  AS AmountRC
	// ------------------------------------------------------
	|INTO
	|	Table_CashFlowData_CB_Accounts
	|FROM
	|	Table_GeneralJournalAnalyticsDimensions_Transactions AS Transaction
	|WHERE
	|	(Transaction.Account.AccountType <> VALUE(Enum.AccountTypes.AccountsReceivable)
	|		AND Transaction.Account.AccountType <> VALUE(Enum.AccountTypes.AccountsPayable)
	|		AND Transaction.Account.AccountType <> VALUE(Enum.AccountTypes.Income)
	|		AND Transaction.Account.AccountType <> VALUE(Enum.AccountTypes.CostOfSales)
	|		AND Transaction.Account.AccountType <> VALUE(Enum.AccountTypes.Expense)
	|		AND Transaction.Account.AccountType <> VALUE(Enum.AccountTypes.OtherIncome)
	|		AND Transaction.Account.AccountType <> VALUE(Enum.AccountTypes.OtherExpense)
	|		AND Transaction.Account.AccountType <> VALUE(Enum.AccountTypes.IncomeTaxExpense))
	|	OR (Transaction.Account.AccountType <> VALUE(Enum.AccountTypes.AccountsReceivable)
	|		AND Transaction.Account.AccountType <> VALUE(Enum.AccountTypes.AccountsPayable)
	|		AND Transaction.RecordType = VALUE(AccumulationRecordType.Expense))";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_CashFlowData_CB_Accounts_Amount(TablesList)
	
	// Add CashFlowData CashBasis Accounts Amount table to document structure.
	TablesList.Insert("Table_CashFlowData_CB_Accounts_Amount", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // CashBasis Accounts
	// ------------------------------------------------------
	// Resources
	|	SUM(Transaction.AmountRC)      AS AmountRC
	// ------------------------------------------------------
	|INTO
	|	Table_CashFlowData_CB_Accounts_Amount
	|FROM
	|	Table_CashFlowData_CB_Accounts AS Transaction";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_CashFlowData(TablesList)
	
	// Add CashFlowData table to document structure.
	TablesList.Insert("Table_CashFlowData", TablesList.Count());
	
	// Collect cash flow data.
	QueryText =
	"SELECT // CashBasis Transactions 
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
	|	PurchaseInvoice.Ref                   AS Document,
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
	|	LEFT JOIN Document.PurchaseInvoice AS PurchaseInvoice
	|		ON PurchaseInvoice.Ref = &Ref
	|WHERE
	|	(Transaction.Account.AccountType <> VALUE(Enum.AccountTypes.AccountsReceivable)
	|		AND Transaction.Account.AccountType <> VALUE(Enum.AccountTypes.AccountsPayable)
	|		AND Transaction.Account.AccountType <> VALUE(Enum.AccountTypes.Income)
	|		AND Transaction.Account.AccountType <> VALUE(Enum.AccountTypes.CostOfSales)
	|		AND Transaction.Account.AccountType <> VALUE(Enum.AccountTypes.Expense)
	|		AND Transaction.Account.AccountType <> VALUE(Enum.AccountTypes.OtherIncome)
	|		AND Transaction.Account.AccountType <> VALUE(Enum.AccountTypes.OtherExpense)
	|		AND Transaction.Account.AccountType <> VALUE(Enum.AccountTypes.IncomeTaxExpense))
	|	OR (Transaction.Account.AccountType <> VALUE(Enum.AccountTypes.AccountsReceivable)
	|		AND Transaction.Account.AccountType <> VALUE(Enum.AccountTypes.AccountsPayable)
	|		AND Transaction.RecordType = VALUE(AccumulationRecordType.Expense))
	|
	|UNION ALL
	|
	|SELECT // CashBasis Transactions Accounts Payable (difference)
	// ------------------------------------------------------
	// Standard attributes
	|	PurchaseInvoice.Ref                   AS Recorder,
	|	PurchaseInvoice.Date                  AS Period,
	|	0                                     AS LineNumber,
	|	CASE
	|		WHEN TransactionAP.AmountRC > 0
	|			THEN VALUE(AccumulationRecordType.Expense)
	|		ELSE VALUE(AccumulationRecordType.Receipt)
	|	END                                   AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Accounting attributes
	|	PurchaseInvoice.APAccount             AS Account,
	// ------------------------------------------------------
	// Dimensions
	|	PurchaseInvoice.Company               AS Company,
	|	PurchaseInvoice.Ref                   AS Document,
	|	NULL                                  AS SalesPerson,
	|	NULL                                  AS Class,
	|	NULL                                  AS Project,
	// ------------------------------------------------------
	// Resources
	|	CASE
	|		WHEN TransactionAP.AmountRC > 0
	|			THEN TransactionAP.AmountRC                
	|		ELSE TransactionAP.AmountRC * -1
	|	END                                   AS AmountRC,
	// ------------------------------------------------------
	// Attributes
	|	NULL                                  AS PaymentMethod
	// ------------------------------------------------------
	|FROM
	|	Table_CashFlowData_CB_Accounts_Amount AS TransactionAP
	|	LEFT JOIN Document.PurchaseInvoice AS PurchaseInvoice
	|		ON PurchaseInvoice.Ref = &Ref
	|WHERE
	|	TransactionAP.AmountRC <> 0
	|
	|UNION ALL
	|
	|SELECT // Paid Transactions
	// ------------------------------------------------------
	// Standard attributes
	|	PurchaseInvoice.Ref                   AS Recorder,
	|	PurchaseInvoice.Date                  AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Accounting attributes
	|	PaidTransaction.Account               AS Account,
	// ------------------------------------------------------
	// Dimensions
	|	PurchaseInvoice.Company               AS Company,
	|	PurchaseInvoice.Ref                   AS Document,
	|	NULL                                  AS SalesPerson,
	|	PaidTransaction.Class                 AS Class,
	|	PaidTransaction.Project               AS Project,
	// ------------------------------------------------------
	// Resources
	|	PaidTransaction.AmountRC              AS AmountRC,
	// ------------------------------------------------------
	// Attributes
	|	NULL                                  AS PaymentMethod
	// ------------------------------------------------------
	|FROM
	|	Table_CashFlowData_Accounts_Paid_Transactions_Corrected AS PaidTransaction
	|	LEFT JOIN Document.PurchaseInvoice AS PurchaseInvoice
	|		ON PurchaseInvoice.Ref = &Ref
	|WHERE
	|	PaidTransaction.AmountRC <> 0
	|
	|UNION ALL
	|
	|SELECT // Paid Transactions Accounts Payable (difference)
	// ------------------------------------------------------
	// Standard attributes
	|	PurchaseInvoice.Ref                   AS Recorder,
	|	PurchaseInvoice.Date                  AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Accounting attributes
	|	PurchaseInvoice.APAccount             AS Account,
	// ------------------------------------------------------
	// Dimensions
	|	PurchaseInvoice.Company               AS Company,
	|	PurchaseInvoice.Ref                   AS Document,
	|	NULL                                  AS SalesPerson,
	|	NULL                                  AS Class,
	|	NULL                                  AS Project,
	// ------------------------------------------------------
	// Resources
	|	PaidTransaction.AmountRC              AS AmountRC,
	// ------------------------------------------------------
	// Attributes
	|	NULL                                  AS PaymentMethod
	// ------------------------------------------------------
	|FROM
	|	Table_CashFlowData_Accounts_Paid_Transactions_Amount AS PaidTransaction
	|	LEFT JOIN Document.PurchaseInvoice AS PurchaseInvoice
	|		ON PurchaseInvoice.Ref = &Ref
	|WHERE
	|	PaidTransaction.AmountRC <> 0";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction


// Query for document data.
Function Query_ProjectData_Accounts(TablesList)
	
	// Add ProjectData inventory or expenses accounts table to document structure.
	TablesList.Insert("Table_ProjectData_Accounts", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // InvOrExp accounts selection
	// ------------------------------------------------------
	// Dimensions
	|	Accounts.InvOrExpAccount              AS InvOrExpAccount,
	|	Accounts.Project                      AS Project,
	// ------------------------------------------------------
	// Resources
	|	Accounts.IRAmount                     AS Amount
	// ------------------------------------------------------
	|INTO
	|	Table_ProjectData_Accounts
	|FROM
	|	Table_GeneralJournal_LineItems AS Accounts
	|WHERE
	|	Accounts.Type <> VALUE(Enum.InventoryTypes.Inventory)
	|	AND (Accounts.InvOrExpAccount.AccountType = VALUE(Enum.AccountTypes.Expense) OR
	|		 Accounts.InvOrExpAccount.AccountType = VALUE(Enum.AccountTypes.OtherExpense) OR
	|		 Accounts.InvOrExpAccount.AccountType = VALUE(Enum.AccountTypes.CostOfSales) OR
	|		 Accounts.InvOrExpAccount.AccountType = VALUE(Enum.AccountTypes.Income) OR
	|		 Accounts.InvOrExpAccount.AccountType = VALUE(Enum.AccountTypes.OtherIncome) OR
	|		 Accounts.InvOrExpAccount.AccountType = VALUE(Enum.AccountTypes.IncomeTaxExpense))";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_ProjectData_Accounts_InvOrExp(TablesList)
	
	// Add ProjectData inventory or expenses accounts table to document structure.
	TablesList.Insert("Table_ProjectData_Accounts_InvOrExp", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // InvOrExp accounts selection
	// ------------------------------------------------------
	// Dimensions
	|	Accounts.InvOrExpAccount              AS InvOrExpAccount,
	|	Accounts.Project                      AS Project,
	// ------------------------------------------------------
	// Resources
	|	SUM(Accounts.Amount)                  AS Amount
	// ------------------------------------------------------
	|INTO
	|	Table_ProjectData_Accounts_InvOrExp
	|FROM
	|	Table_ProjectData_Accounts AS Accounts
	|GROUP BY
	|	Accounts.InvOrExpAccount,
	|	Accounts.Project";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_ProjectData(TablesList)
	
	// Add ProjectData table to document structure.
	TablesList.Insert("Table_ProjectData", TablesList.Count());
	
	// Collect project data.
	QueryText =
	"SELECT // Exp: Inventory and Expenses
	// ------------------------------------------------------
	// Standard attributes
	|	PurchaseInvoice.Ref                   AS Recorder,
	|	PurchaseInvoice.Date                  AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Dimensions
	|	InvOrExp.InvOrExpAccount              AS Account,
	|	InvOrExp.Project                      AS Project,
	// ------------------------------------------------------
	// Resources
	|	CAST( // Format(Amount * ExchangeRate, ""ND=17; NFD=2"")
	|		InvOrExp.Amount *
	|		CASE WHEN PurchaseInvoice.ExchangeRate > 0
	|			 THEN PurchaseInvoice.ExchangeRate
	|			 ELSE 1 END
	|		AS NUMBER (17, 2))                AS Amount
	// ------------------------------------------------------
	// Attributes
	// ------------------------------------------------------
	|FROM
	|	Table_ProjectData_Accounts_InvOrExp AS InvOrExp
	|	LEFT JOIN Document.PurchaseInvoice AS PurchaseInvoice
	|		ON PurchaseInvoice.Ref = &Ref
	|WHERE
	|	// Amount <> 0
	|	InvOrExp.Amount <> 0";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_ClassData_Accounts(TablesList)
	
	// Add ClassData inventory or expenses accounts table to document structure.
	TablesList.Insert("Table_ClassData_Accounts", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // InvOrExp accounts selection
	// ------------------------------------------------------
	// Dimensions
	|	Accounts.InvOrExpAccount              AS InvOrExpAccount,
	|	Accounts.Class                        AS Class,
	// ------------------------------------------------------
	// Resources
	|	Accounts.IRAmount                     AS Amount
	// ------------------------------------------------------
	|INTO
	|	Table_ClassData_Accounts
	|FROM
	|	Table_GeneralJournal_LineItems AS Accounts
	|WHERE
	|	Accounts.Type <> VALUE(Enum.InventoryTypes.Inventory)
	|	AND (Accounts.InvOrExpAccount.AccountType = VALUE(Enum.AccountTypes.Expense) OR
	|		 Accounts.InvOrExpAccount.AccountType = VALUE(Enum.AccountTypes.OtherExpense) OR
	|		 Accounts.InvOrExpAccount.AccountType = VALUE(Enum.AccountTypes.CostOfSales) OR
	|		 Accounts.InvOrExpAccount.AccountType = VALUE(Enum.AccountTypes.Income) OR
	|		 Accounts.InvOrExpAccount.AccountType = VALUE(Enum.AccountTypes.OtherIncome) OR
	|		 Accounts.InvOrExpAccount.AccountType = VALUE(Enum.AccountTypes.IncomeTaxExpense))";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_ClassData_Accounts_InvOrExp(TablesList)
	
	// Add ClassData inventory or expenses accounts table to document structure.
	TablesList.Insert("Table_ClassData_Accounts_InvOrExp", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // InvOrExp accounts selection
	// ------------------------------------------------------
	// Dimensions
	|	Accounts.InvOrExpAccount              AS InvOrExpAccount,
	|	Accounts.Class                        AS Class,
	// ------------------------------------------------------
	// Resources
	|	SUM(Accounts.Amount)                  AS Amount
	// ------------------------------------------------------
	|INTO
	|	Table_ClassData_Accounts_InvOrExp
	|FROM
	|	Table_ClassData_Accounts AS Accounts
	|GROUP BY
	|	Accounts.InvOrExpAccount,
	|	Accounts.Class";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_ClassData(TablesList)
	
	// Add ClassData table to document structure.
	TablesList.Insert("Table_ClassData", TablesList.Count());
	
	// Collect class data.
	QueryText =
	"SELECT // Exp: Inventory and Expenses
	// ------------------------------------------------------
	// Standard attributes
	|	PurchaseInvoice.Ref                   AS Recorder,
	|	PurchaseInvoice.Date                  AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Dimensions
	|	InvOrExp.InvOrExpAccount              AS Account,
	|	InvOrExp.Class                        AS Class,
	// ------------------------------------------------------
	// Resources
	|	CAST( // Format(Amount * ExchangeRate, ""ND=17; NFD=2"")
	|		InvOrExp.Amount *
	|		CASE WHEN PurchaseInvoice.ExchangeRate > 0
	|			 THEN PurchaseInvoice.ExchangeRate
	|			 ELSE 1 END
	|		AS NUMBER (17, 2))                AS Amount
	// ------------------------------------------------------
	// Attributes
	// ------------------------------------------------------
	|FROM
	|	Table_ClassData_Accounts_InvOrExp AS InvOrExp
	|	LEFT JOIN Document.PurchaseInvoice AS PurchaseInvoice
	|		ON PurchaseInvoice.Ref = &Ref
	|WHERE
	|	// Amount <> 0
	|	InvOrExp.Amount <> 0";
	
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
	|	LineItems.Ref AS Recorder,
	|	LineItems.Ref.Date AS Period,
	|	MIN(LineItems.LineNumber) AS LineNumber,
	|	TRUE AS Active,
	// ------------------------------------------------------
	// Dimensions
	|	LineItems.Product AS Product,
	// ------------------------------------------------------
	// Resources
	|	AVG(CASE
	|			WHEN LineItems.Product.PricePrecision = 3
	|				THEN CAST(LineItems.PriceUnits * CASE
	|							WHEN LineItems.Ref.ExchangeRate > 0
	|								THEN LineItems.Ref.ExchangeRate
	|							ELSE 1
	|						END / CASE
	|							WHEN LineItems.Unit.Factor > 0
	|								THEN LineItems.Unit.Factor
	|							ELSE 1
	|						END AS NUMBER(17, 3))
	|			WHEN LineItems.Product.PricePrecision = 4
	|				THEN CAST(LineItems.PriceUnits * CASE
	|							WHEN LineItems.Ref.ExchangeRate > 0
	|								THEN LineItems.Ref.ExchangeRate
	|							ELSE 1
	|						END / CASE
	|							WHEN LineItems.Unit.Factor > 0
	|								THEN LineItems.Unit.Factor
	|							ELSE 1
	|						END AS NUMBER(17, 4))
	|			ELSE CAST(LineItems.PriceUnits * CASE
	|						WHEN LineItems.Ref.ExchangeRate > 0
	|							THEN LineItems.Ref.ExchangeRate
	|						ELSE 1
	|					END / CASE
	|						WHEN LineItems.Unit.Factor > 0
	|							THEN LineItems.Unit.Factor
	|						ELSE 1
	|					END AS NUMBER(17, 2))
	|		END) AS Cost
	// ------------------------------------------------------
	// Attributes
	// ------------------------------------------------------
	|FROM
	|	Document.PurchaseInvoice.LineItems AS LineItems
	|WHERE
	|	LineItems.Ref = &Ref
	|	AND (CASE
	|			WHEN LineItems.Product.PricePrecision = 3
	|				THEN CAST(LineItems.PriceUnits * CASE
	|							WHEN LineItems.Ref.ExchangeRate > 0
	|								THEN LineItems.Ref.ExchangeRate
	|							ELSE 1
	|						END / CASE
	|							WHEN LineItems.Unit.Factor > 0
	|								THEN LineItems.Unit.Factor
	|							ELSE 1
	|						END AS NUMBER(17, 3))
	|			WHEN LineItems.Product.PricePrecision = 4
	|				THEN CAST(LineItems.PriceUnits * CASE
	|							WHEN LineItems.Ref.ExchangeRate > 0
	|								THEN LineItems.Ref.ExchangeRate
	|							ELSE 1
	|						END / CASE
	|							WHEN LineItems.Unit.Factor > 0
	|								THEN LineItems.Unit.Factor
	|							ELSE 1
	|						END AS NUMBER(17, 4))
	|			ELSE CAST(LineItems.PriceUnits * CASE
	|						WHEN LineItems.Ref.ExchangeRate > 0
	|							THEN LineItems.Ref.ExchangeRate
	|						ELSE 1
	|					END / CASE
	|						WHEN LineItems.Unit.Factor > 0
	|							THEN LineItems.Unit.Factor
	|						ELSE 1
	|					END AS NUMBER(17, 2))
	|		END) > 0
	|
	|GROUP BY
	|	LineItems.Product,
	|	LineItems.Ref,
	|	LineItems.Ref.Date
	|
	|ORDER BY
	|	LineNumber";
	
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

// Custom check for closing of parent orders.
// Procedure uses custom data of document to check orders closing.
// This prevents from requesting already acquired data.
Procedure CheckCloseParentOrders(DocumentRef, AdditionalProperties, TempTablesManager)
	Var Table_OrdersStatuses;
	
	// Skip check if order absent.
	If AdditionalProperties.Orders.Count() = 0 Then
		Return;
	EndIf;
	
	// Create new query.
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	
	// Empty query text and tables.
	QueryText   = "";
	QueryTables = -1;
	
	// Put temporary table for calculating of final status.
	// Table_OrdersDispatched_Balance already placed in TempTablesManager.
	DocumentPosting.PutTemporaryTable(AdditionalProperties.Posting.PostingTables.Table_OrdersDispatched, "Table_OrdersDispatched", Query.TempTablesManager);
	
	// Create query for calculate order status.
	QueryText = QueryText +
	// Combine balance with document postings.
	"SELECT
	// ------------------------------------------------------
	// Dimensions
	|	OrdersDispatchedBalance.Company          AS Company,
	|	OrdersDispatchedBalance.Order            AS Order,
	|	VALUE(Document.ItemReceipt.EmptyRef)     AS ItemReceipt,
	|	OrdersDispatchedBalance.Product          AS Product,
	|	OrdersDispatchedBalance.Unit             AS Unit,
	|	OrdersDispatchedBalance.Location         AS Location,
	|	OrdersDispatchedBalance.DeliveryDate     AS DeliveryDate,
	|	OrdersDispatchedBalance.Project          AS Project,
	|	OrdersDispatchedBalance.Class            AS Class,
	// ------------------------------------------------------
	// Resources
	|	OrdersDispatchedBalance.Quantity         AS Quantity,
	|	OrdersDispatchedBalance.Received         AS Received,
	|	OrdersDispatchedBalance.ReceivedIR       AS ReceivedIR,
	|	OrdersDispatchedBalance.Invoiced         AS Invoiced
	// ------------------------------------------------------
	|INTO
	|	OrdersDispatched_Balance_And_Postings
	|FROM
	|	Table_OrdersDispatched_Balance AS OrdersDispatchedBalance
	|	// (Company, Order) IN (SELECT DISTINCT &Company, LineItems.Order FROM Table_LineItems AS LineItems)
	|
	|UNION ALL
	|
	|SELECT
	// ------------------------------------------------------
	// Dimensions
	|	OrdersDispatched.Company,
	|	OrdersDispatched.Order,
	|	VALUE(Document.ItemReceipt.EmptyRef),
	|	OrdersDispatched.Product,
	|	OrdersDispatched.Unit,
	|	OrdersDispatched.Location,
	|	OrdersDispatched.DeliveryDate,
	|	OrdersDispatched.Project,
	|	OrdersDispatched.Class,
	// ------------------------------------------------------
	// Resources
	|	OrdersDispatched.Quantity,
	|	OrdersDispatched.Received,
	|	OrdersDispatched.ReceivedIR,
	|	OrdersDispatched.Invoiced
	// ------------------------------------------------------
	|FROM
	|	Table_OrdersDispatched AS OrdersDispatched
	|	// Table_LineItems WHERE LineItems.Ref = &Ref AND Order <> EmptyRef()
	|
	|UNION ALL
	|
	|SELECT
	// ------------------------------------------------------
	// Dimensions
	|	OrdersDispatchedIRBalance.Company        AS Company,
	|	OrdersDispatchedIRBalance.Order          AS Order,
	|	OrdersDispatchedIRBalance.ItemReceipt    AS ItemReceipt,
	|	OrdersDispatchedIRBalance.Product        AS Product,
	|	OrdersDispatchedIRBalance.Unit           AS Unit,
	|	OrdersDispatchedIRBalance.Location       AS Location,
	|	OrdersDispatchedIRBalance.DeliveryDate   AS DeliveryDate,
	|	OrdersDispatchedIRBalance.Project        AS Project,
	|	OrdersDispatchedIRBalance.Class          AS Class,
	// ------------------------------------------------------
	// Resources
	|	OrdersDispatchedIRBalance.Quantity       AS Quantity,
	|	OrdersDispatchedIRBalance.Received       AS Received,
	|	OrdersDispatchedIRBalance.ReceivedIR     AS ReceivedIR,
	|	OrdersDispatchedIRBalance.Invoiced       AS Invoiced
	// ------------------------------------------------------
	|FROM
	|	Table_OrdersDispatchedIR_Balance AS OrdersDispatchedIRBalance
    |   // (Company, ItemReceipt) IN (SELECT DISTINCT &Company, LineItems.ItemReceipt FROM Table_LineItems AS LineItems WHERE LineItems.ItemReceipt <> VALUE(Document.ItemReceipt.EmptyRef))
	|
	|UNION ALL
	|
	|SELECT
	// ------------------------------------------------------
	// Dimensions
	|	OrdersDispatchedIR.Company,
	|	VALUE(Document.PurchaseOrder.EmptyRef),
	|	OrdersDispatchedIR.ItemReceipt,
	|	OrdersDispatchedIR.Product,
	|	OrdersDispatchedIR.Unit,
	|	OrdersDispatchedIR.Location,
	|	OrdersDispatchedIR.DeliveryDate,
	|	OrdersDispatchedIR.Project,
	|	OrdersDispatchedIR.Class,
	// ------------------------------------------------------
	// Resources
	|	OrdersDispatchedIR.Quantity,
	|	OrdersDispatchedIR.Received,
	|	OrdersDispatchedIR.ReceivedIR,
	|	OrdersDispatchedIR.Invoiced
	// ------------------------------------------------------
	|FROM
	|	Table_OrdersDispatched AS OrdersDispatchedIR
	|	// Table_LineItems WHERE LineItems.Ref = &Ref AND Order <> EmptyRef()
	|WHERE
	|	OrdersDispatchedIR.ItemReceipt <> VALUE(Document.ItemReceipt.EmptyRef)
	|";
	QueryText   = QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	QueryTables = QueryTables + 1;
	
	// Calculate final balance after posting the invoice.
	QueryText = QueryText +
	"SELECT
	// ------------------------------------------------------
	// Dimensions
	|	OrdersDispatchedBalance.Company          AS Company,
	|	OrdersDispatchedBalance.Order            AS Order,
	|	OrdersDispatchedBalance.ItemReceipt      AS ItemReceipt,
	|	OrdersDispatchedBalance.Product          AS Product,
	|	OrdersDispatchedBalance.Product.Type     AS Type,
	|	OrdersDispatchedBalance.Unit             AS Unit,
	|	OrdersDispatchedBalance.Location         AS Location,
	|	OrdersDispatchedBalance.DeliveryDate     AS DeliveryDate,
	|	OrdersDispatchedBalance.Project          AS Project,
	|	OrdersDispatchedBalance.Class            AS Class,
	// ------------------------------------------------------
	// Resources
	|	SUM(OrdersDispatchedBalance.Quantity)    AS Quantity,
	|	SUM(OrdersDispatchedBalance.Received)    AS Received,
	|	SUM(OrdersDispatchedBalance.ReceivedIR)  AS ReceivedIR,
	|	SUM(OrdersDispatchedBalance.Invoiced)    AS Invoiced
	// ------------------------------------------------------
	|INTO
	|	OrdersDispatched_Balance_AfterWrite
	|FROM
	|	OrdersDispatched_Balance_And_Postings AS OrdersDispatchedBalance
	|GROUP BY
	|	OrdersDispatchedBalance.Company,
	|	OrdersDispatchedBalance.Order,
	|	OrdersDispatchedBalance.ItemReceipt,
	|	OrdersDispatchedBalance.Product,
	|	OrdersDispatchedBalance.Product.Type,
	|	OrdersDispatchedBalance.Unit,
	|	OrdersDispatchedBalance.Location,
	|	OrdersDispatchedBalance.DeliveryDate,
	|	OrdersDispatchedBalance.Project,
	|	OrdersDispatchedBalance.Class";
	QueryText   = QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	QueryTables = QueryTables + 1;
	
	// Calculate unreceived and(or) uninvoiced items.
	QueryText = QueryText +
	"SELECT
	// ------------------------------------------------------
	// Dimensions
	|	OrdersDispatchedBalance.Company          AS Company,
	|	OrdersDispatchedBalance.Order            AS Order,
	|	OrdersDispatchedBalance.ItemReceipt      AS ItemReceipt,
	|	OrdersDispatchedBalance.Product          AS Product,
	|	OrdersDispatchedBalance.Unit             AS Unit,
	|	OrdersDispatchedBalance.Location         AS Location,
	|	OrdersDispatchedBalance.DeliveryDate     AS DeliveryDate,
	|	OrdersDispatchedBalance.Project          AS Project,
	|	OrdersDispatchedBalance.Class            AS Class,
	// ------------------------------------------------------
	// Resources
	|	CASE WHEN OrdersDispatchedBalance.ItemReceipt <> VALUE(Document.ItemReceipt.EmptyRef)
	|		 THEN 0
	|		 WHEN OrdersDispatchedBalance.Type = VALUE(Enum.InventoryTypes.Inventory)
	|	     THEN OrdersDispatchedBalance.Quantity - OrdersDispatchedBalance.Received
	|	     ELSE 0 END                          AS UnReceived,
	|	CASE WHEN OrdersDispatchedBalance.ItemReceipt <> VALUE(Document.ItemReceipt.EmptyRef)
	|        THEN OrdersDispatchedBalance.ReceivedIR - OrdersDispatchedBalance.Invoiced
	|        WHEN OrdersDispatchedBalance.Type = VALUE(Enum.InventoryTypes.Inventory)
	|	     THEN OrdersDispatchedBalance.Received - OrdersDispatchedBalance.Invoiced
	|	     WHEN OrdersDispatchedBalance.Type = VALUE(Enum.InventoryTypes.NonInventory)
	|	     THEN OrdersDispatchedBalance.Quantity - OrdersDispatchedBalance.Invoiced
	|	     ELSE 0 END                          AS UnInvoiced
	// ------------------------------------------------------
	|INTO
	|	OrdersDispatched_Balance_Unclosed
	|FROM
	|	OrdersDispatched_Balance_AfterWrite AS OrdersDispatchedBalance";
	
	QueryText   = QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	QueryTables = QueryTables + 1;
	
	// Calculate unclosed.
	QueryText = QueryText +
	"SELECT
	// ------------------------------------------------------
	// Dimensions
	|	OrdersDispatchedBalance.Order            AS Order,
	|	OrdersDispatchedBalance.ItemReceipt      AS ItemReceipt,
	|	SUM(CASE WHEN OrdersDispatchedBalance.UnReceived > 0 THEN OrdersDispatchedBalance.UnReceived ELSE 0 END
	|	  + CASE WHEN OrdersDispatchedBalance.UnInvoiced > 0 THEN OrdersDispatchedBalance.UnInvoiced ELSE 0 END)
	|                                            AS Unclosed
	// ------------------------------------------------------
	|INTO
	|	OrdersDispatched_Balance_Orders_Unclosed
	|FROM
	|	OrdersDispatched_Balance_Unclosed AS OrdersDispatchedBalance
	|GROUP BY
	|	OrdersDispatchedBalance.Order,
	|	OrdersDispatchedBalance.ItemReceipt";
	QueryText   = QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	QueryTables = QueryTables + 1;
	
	// Calculate closed orders (those in invoice, which don't have unclosed items in theirs balance).
	QueryText = QueryText +
	"SELECT DISTINCT
	|	OrdersDispatchedBalanceUnclosed.Order       AS Order,
	|	OrdersDispatchedBalanceUnclosed.ItemReceipt AS ItemReceipt
	|FROM
	|	OrdersDispatched_Balance_Orders_Unclosed AS OrdersDispatchedBalanceUnclosed
	|WHERE
	|	// No unclosed items
	|	OrdersDispatchedBalanceUnclosed.Unclosed = 0";
	QueryText   = QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	QueryTables = QueryTables + 1;
	
	// Clear orders dispatch postings table.
	QueryText   = QueryText + 
	"DROP Table_OrdersDispatched";
	QueryText   = QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
	// Clear balance with document postings table.
	QueryText   = QueryText + 
	"DROP OrdersDispatched_Balance_And_Postings";
	QueryText   = QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
	// Clear final balance after posting the invoice table.
	QueryText   = QueryText + 
	"DROP OrdersDispatched_Balance_AfterWrite";
	QueryText   = QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
	// Clear unshipped and uninvoiced items table.
	QueryText   = QueryText + 
	"DROP OrdersDispatched_Balance_Unclosed";
	QueryText   = QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
	// Clear orders having unclosed items in balance table.
	QueryText   = QueryText + 
	"DROP OrdersDispatched_Balance_Orders_Unclosed";
	QueryText   = QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
	// Execute query.
	Query.Text  = QueryText;
	QueryResult = Query.ExecuteBatch();
	
	// Check status of final query.
	If Not QueryResult[QueryTables].IsEmpty()
	// Update OrderStatus in prefilled table of postings.
	And AdditionalProperties.Posting.PostingTables.Property("Table_OrdersStatuses", Table_OrdersStatuses) Then
		
		// Update closed orders.
		Selection = QueryResult[QueryTables].Select();
		While Selection.Next() Do
			
			Order = ?(ValueIsFilled(Selection.ItemReceipt), Selection.ItemReceipt, Selection.Order);
			
			// Set OrderStatus -> Closed.
			Row = Table_OrdersStatuses.Find(Order, "Order");
			If Row = Undefined Then
				NewRow = Table_OrdersStatuses.Add();
				NewRow.Recorder   = AdditionalProperties.Ref;
				NewRow.Period     = AdditionalProperties.Date;
				NewRow.LineNumber = 1;
				NewRow.Active     = True;
				NewRow.Order      = Order;
				NewRow.Status     = Enums.OrderStatuses.Closed;
			Else
				Row.Status = Enums.OrderStatuses.Closed;
			EndIf;
		EndDo;
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
		|	ISNULL(PurchaseOrder.Currency.DefaultAPAccount, VALUE(ChartOfAccounts.ChartOfAccounts.EmptyRef))
		|	                                        AS APAccount,
		|	CASE
		|		WHEN PurchaseOrder.Company.Terms.Days IS NULL THEN DATEADD(&Date, DAY, 14)
		|		WHEN PurchaseOrder.Company.Terms.Days = 0     THEN DATEADD(&Date, DAY, 14)
		|		ELSE                                               DATEADD(&Date, DAY, PurchaseOrder.Company.Terms.Days)
		|	END                                     AS DueDate,
		|	PurchaseOrder.Location                  AS LocationActual,
		|	PurchaseOrder.DeliveryDate              AS DeliveryDateActual,
		|	PurchaseOrder.Project                   AS Project,
		|	PurchaseOrder.Class                     AS Class,
		|	ISNULL(PurchaseOrder.Company.Terms, VALUE(Catalog.PaymentTerms.EmptyRef))
		|	                                        AS Terms
		|INTO
		|	Table_Document_PurchaseOrder_Attributes
		|FROM
		|	Document.PurchaseOrder AS PurchaseOrder
		|WHERE
		|	PurchaseOrder.Ref IN (&FillingData_Document_PurchaseOrder)";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document filling.
Function Query_Filling_Document_ItemReceipt_Attributes(TablesList)
	
	// Add Attributes table to document structure.
	TablesList.Insert("Table_Document_ItemReceipt_Attributes", TablesList.Count());
	
	// Collect attributes data.
	QueryText =
		"SELECT
		|	ItemReceipt.Ref                         AS FillingData,
		|	ItemReceipt.Company                     AS Company,
		|	ItemReceipt.CompanyAddress              AS CompanyAddress,
		|	ItemReceipt.Currency                    AS Currency,
		|	ItemReceipt.ExchangeRate                AS ExchangeRate,
		|	ISNULL(ItemReceipt.Currency.DefaultAPAccount, VALUE(ChartOfAccounts.ChartOfAccounts.EmptyRef))
		|	                                        AS APAccount,
		|	ItemReceipt.DueDate                     AS DueDate,
		|	ItemReceipt.Location                    AS LocationActual,
		|	ItemReceipt.DeliveryDate                AS DeliveryDateActual,
		|	ItemReceipt.Project                     AS Project,
		|	ItemReceipt.Class                       AS Class,
		|	ISNULL(ItemReceipt.Company.Terms, VALUE(Catalog.PaymentTerms.EmptyRef))
		|	                                        AS Terms
		|INTO
		|	Table_Document_ItemReceipt_Attributes
		|FROM
		|	Document.ItemReceipt AS ItemReceipt
		|WHERE
		|	ItemReceipt.Ref IN (&FillingData_Document_ItemReceipt)";
	
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
Function Query_Filling_Document_ItemReceipt_OrdersStatuses(TablesList)
	
	// Add OrdersStatuses table to document structure.
	TablesList.Insert("Table_Document_ItemReceipt_OrdersStatuses", TablesList.Count());
	
	// Collect orders statuses data.
	QueryText =
		"SELECT
		// ------------------------------------------------------
		// Dimensions
		|	ItemReceipt.Ref                        AS Order,
		// ------------------------------------------------------
		// Resources
		|	CASE
		|		WHEN ItemReceipt.DeletionMark THEN
		|			 VALUE(Enum.OrderStatuses.Deleted)
		|		WHEN NOT ItemReceipt.Posted THEN
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
		|	Table_Document_ItemReceipt_OrdersStatuses
		|FROM
		|	Document.ItemReceipt AS ItemReceipt
		|		LEFT JOIN InformationRegister.OrdersStatuses.SliceLast AS OrdersStatuses
		|		ON ItemReceipt.Ref = OrdersStatuses.Order
		|WHERE
		|	ItemReceipt.Ref IN (&FillingData_Document_ItemReceipt)";
	
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
Function Query_Filling_Document_ItemReceipt_OrdersDispatched(TablesList)
	
	// Add OrdersDispatched table to document structure.
	TablesList.Insert("Table_Document_ItemReceipt_OrdersDispatched", TablesList.Count());
	
	// Collect orders items data.
	QueryText =
		"SELECT
		// ------------------------------------------------------
		// Dimensions
		|	OrdersDispatchedBalance.Company           AS Company,
		|	OrdersDispatchedBalance.Order             AS Order,
		|	OrdersDispatchedBalance.ItemReceipt       AS ItemReceipt,
		|	OrdersDispatchedBalance.Product           AS Product,
		|	OrdersDispatchedBalance.Unit              AS Unit,
		|	OrdersDispatchedBalance.Location          AS Location,
		|	OrdersDispatchedBalance.DeliveryDate      AS DeliveryDate,
		|	OrdersDispatchedBalance.Project           AS Project,
		|	OrdersDispatchedBalance.Class             AS Class,
		// ------------------------------------------------------
		// Resources                                                                                                        
		|	OrdersDispatchedBalance.ReceivedIRBalance AS Quantity,                                                           
		|	CASE                                                                                                            
		|		WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Open)        THEN 0                                   
		|		WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Backordered) THEN                                     
		|			 CASE                                                                                                   
		|			      WHEN OrdersDispatchedBalance.ReceivedIRBalance > OrdersDispatchedBalance.InvoicedBalance          
		|				  THEN OrdersDispatchedBalance.ReceivedIRBalance - OrdersDispatchedBalance.InvoicedBalance          
		|			      ELSE 0 
		|            END                                                                                                    
		|		WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Closed)      THEN 0                                   
		|		ELSE 0                                                                                                      
		|	END                                       AS Backorder
		// ------------------------------------------------------
		|INTO
		|	Table_Document_ItemReceipt_OrdersDispatched
		|FROM
		|	AccumulationRegister.OrdersDispatched.Balance(,
		|		(Company, Order, ItemReceipt, Product, Unit, Location, DeliveryDate, Project, Class) IN
		|			(SELECT
		|				ItemReceiptLineItems.Ref.Company,
		|				ItemReceiptLineItems.Order,
		|				ItemReceiptLineItems.Ref,
		|				ItemReceiptLineItems.Product,
		|				ItemReceiptLineItems.Unit,
		|				ItemReceiptLineItems.LocationOrder,
		|				ItemReceiptLineItems.DeliveryDateOrder,
		|				ItemReceiptLineItems.Project,
		|				ItemReceiptLineItems.Class
		|			FROM
		|				Document.ItemReceipt.LineItems AS ItemReceiptLineItems
		|			WHERE
		|				ItemReceiptLineItems.Ref IN (&FillingData_Document_ItemReceipt))) AS OrdersDispatchedBalance
		|	LEFT JOIN Table_Document_ItemReceipt_OrdersStatuses AS OrdersStatuses
		|		ON OrdersDispatchedBalance.ItemReceipt = OrdersStatuses.Order";
	
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
		|	NULL                                       AS LineID,
		|	PurchaseOrderLineItems.Product             AS Product,
		|	PurchaseOrderLineItems.ProductDescription  AS ProductDescription,
		|	VALUE(Catalog.Lots.EmptyRef)               AS Lot,
		|	PurchaseOrderLineItems.UnitSet             AS UnitSet,
		|	PurchaseOrderLineItems.Unit                AS Unit,
		|	CASE
		|		WHEN PurchaseOrderLineItems.Product.PricePrecision = 3
		|			THEN CAST(PurchaseOrderLineItems.PriceUnits AS NUMBER(17, 3))
		|		WHEN PurchaseOrderLineItems.Product.PricePrecision = 4
		|			THEN CAST(PurchaseOrderLineItems.PriceUnits AS NUMBER(17, 4))
		|		ELSE CAST(PurchaseOrderLineItems.PriceUnits AS NUMBER(17, 2))
		|	END                                        AS PriceUnits,
		|	CASE
		|		WHEN PurchaseOrderLineItems.Product.PricePrecision = 3
		|			THEN CAST(PurchaseOrderLineItems.PriceUnits AS NUMBER(17, 3))
		|		WHEN PurchaseOrderLineItems.Product.PricePrecision = 4
		|			THEN CAST(PurchaseOrderLineItems.PriceUnits AS NUMBER(17, 4))
		|		ELSE CAST(PurchaseOrderLineItems.PriceUnits AS NUMBER(17, 2))
		|	END                                        AS OrderPriceUnits,
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
		|	VALUE(Document.ItemReceipt.EmptyRef)       AS ItemReceipt,
		|	PurchaseOrderLineItems.Location            AS Location,
		|	PurchaseOrderLineItems.Location            AS LocationActual,
		|	PurchaseOrderLineItems.DeliveryDate        AS DeliveryDate,
		|	PurchaseOrderLineItems.DeliveryDate        AS DeliveryDateActual,
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
Function Query_Filling_Document_ItemReceipt_LineItems(TablesList)
	
	// Add LineItems table to document structure.
	TablesList.Insert("Table_Document_ItemReceipt_LineItems", TablesList.Count());
	
	// Collect line items data.
	QueryText =
		"SELECT
		|	ItemReceiptLineItems.Ref                   AS FillingData,
		|	ItemReceiptLineItems.LineID                AS LineID,
		|	ItemReceiptLineItems.Product               AS Product,
		|	ItemReceiptLineItems.ProductDescription    AS ProductDescription,
		|	ItemReceiptLineItems.Lot                   AS Lot,
		|	ItemReceiptLineItems.UnitSet               AS UnitSet,
		|	ItemReceiptLineItems.Unit                  AS Unit,
		|	CASE
		|		WHEN ItemReceiptLineItems.Product.PricePrecision = 3
		|			THEN CAST(ItemReceiptLineItems.PriceUnits AS NUMBER(17, 3))
		|		WHEN ItemReceiptLineItems.Product.PricePrecision = 4
		|			THEN CAST(ItemReceiptLineItems.PriceUnits AS NUMBER(17, 4))
		|		ELSE CAST(ItemReceiptLineItems.PriceUnits AS NUMBER(17, 2))
		|	END                                        AS PriceUnits,
		|	CASE
		|		WHEN ItemReceiptLineItems.Product.PricePrecision = 3
		|			THEN CAST(ItemReceiptLineItems.PriceUnits AS NUMBER(17, 3))
		|		WHEN ItemReceiptLineItems.Product.PricePrecision = 4
		|			THEN CAST(ItemReceiptLineItems.PriceUnits AS NUMBER(17, 4))
		|		ELSE CAST(ItemReceiptLineItems.PriceUnits AS NUMBER(17, 2))
		|	END                                        AS OrderPriceUnits,
		|	
		|	// QtyUnits
		|	CASE
		|		WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Open)
		|			THEN ISNULL(OrdersDispatched.Quantity, ItemReceiptLineItems.QtyUnits)
		|		WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Backordered)
		|			THEN ISNULL(OrdersDispatched.Backorder, ItemReceiptLineItems.QtyUnits)
		|		WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Closed)
		|			THEN ISNULL(OrdersDispatched.Backorder, 0)
		|		ELSE 0
		|	END                                        AS QtyUnits,
		|	
		|	// QtyUM
		|	CAST( // Format(Quantity * Unit.Factor, ""ND=15; NFD={4}"")
		|		CASE
		|			WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Open)
		|				THEN ISNULL(OrdersDispatched.Quantity, ItemReceiptLineItems.QtyUnits)
		|			WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Backordered)
		|				THEN ISNULL(OrdersDispatched.Backorder, ItemReceiptLineItems.QtyUnits)
		|			WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Closed)
		|				THEN ISNULL(OrdersDispatched.Backorder, 0)
		|			ELSE 0
		|		END * 
		|		CASE
		|			WHEN ItemReceiptLineItems.Unit.Factor > 0
		|				THEN ItemReceiptLineItems.Unit.Factor
		|			ELSE 1
		|		END
		|		AS NUMBER (15, {QuantityPrecision}))   AS QtyUM,
		|	
		|	// LineTotal
		|	CAST( // Format(Quantity * Price, ""ND=17; NFD=2"")
		|		CASE
		|			WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Open)
		|				THEN ISNULL(OrdersDispatched.Quantity, ItemReceiptLineItems.QtyUnits)
		|			WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Backordered)
		|				THEN ISNULL(OrdersDispatched.Backorder, ItemReceiptLineItems.QtyUnits)
		|			WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Closed)
		|				THEN ISNULL(OrdersDispatched.Backorder, 0)
		|			ELSE 0
		|		END * CASE
		|			WHEN ItemReceiptLineItems.Product.PricePrecision = 3
		|				THEN CAST(ItemReceiptLineItems.PriceUnits AS NUMBER(17, 3))
		|			WHEN ItemReceiptLineItems.Product.PricePrecision = 4
		|				THEN CAST(ItemReceiptLineItems.PriceUnits AS NUMBER(17, 4))
		|			ELSE CAST(ItemReceiptLineItems.PriceUnits AS NUMBER(17, 2))
		|		END AS NUMBER (17, 2))                 AS LineTotal,
		|	
		|	ItemReceiptLineItems.Order                 AS Order,
		|	ItemReceiptLineItems.Ref                   AS ItemReceipt,
		|	ItemReceiptLineItems.LocationOrder         AS Location,
		|	ItemReceiptLineItems.Location              AS LocationActual,
		|	ItemReceiptLineItems.DeliveryDateOrder     AS DeliveryDate,
		|	ItemReceiptLineItems.DeliveryDate          AS DeliveryDateActual,
		|	ItemReceiptLineItems.Project               AS Project,
		|	ItemReceiptLineItems.Class                 AS Class,
		|	ItemReceiptLineItems.Ref.Company           AS Company
		|INTO
		|	Table_Document_ItemReceipt_LineItems
		|FROM
		|	Document.ItemReceipt.LineItems AS ItemReceiptLineItems
		|	LEFT JOIN Table_Document_ItemReceipt_OrdersDispatched AS OrdersDispatched
		|		ON  OrdersDispatched.Company      = ItemReceiptLineItems.Ref.Company
		|		AND OrdersDispatched.Order        = ItemReceiptLineItems.Order
		|		AND OrdersDispatched.ItemReceipt  = ItemReceiptLineItems.Ref
		|		AND OrdersDispatched.Product      = ItemReceiptLineItems.Product
		|		AND OrdersDispatched.Unit         = ItemReceiptLineItems.Unit
		|		AND OrdersDispatched.Location     = ItemReceiptLineItems.LocationOrder
		|		AND OrdersDispatched.DeliveryDate = ItemReceiptLineItems.DeliveryDateOrder
		|		AND OrdersDispatched.Project      = ItemReceiptLineItems.Project
		|		AND OrdersDispatched.Class        = ItemReceiptLineItems.Class
		|	LEFT JOIN Table_Document_ItemReceipt_OrdersStatuses AS OrdersStatuses
		|		ON OrdersStatuses.Order = ItemReceiptLineItems.Ref
		|WHERE
		|	ItemReceiptLineItems.Ref IN (&FillingData_Document_ItemReceipt)";
	
	// Update query rounding using quantity precision.
	QueryText = StrReplace(QueryText, "{QuantityPrecision}", GeneralFunctionsReusable.DefaultQuantityPrecision());
	
	// Return text of query
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document filling.
Function Query_Filling_Document_PurchaseOrder_SerialNumbers(TablesList)
	
	// Add SerialNumbers table to document structure.
	TablesList.Insert("Table_Document_PurchaseOrder_SerialNumbers", TablesList.Count());
	
	// Collect line items data.
	QueryText =
		"SELECT
		|	PurchaseOrderSerialNumbers.Ref             AS FillingData,
		|	NULL                                       AS LineItemsLineID,
		|	""""                                       AS SerialNumber
		|INTO
		|	Table_Document_PurchaseOrder_SerialNumbers
		|FROM
		|	Document.PurchaseOrder AS PurchaseOrderSerialNumbers
		|WHERE
		|	PurchaseOrderSerialNumbers.Ref IN (&FillingData_Document_PurchaseOrder)";
	
	// Return text of query
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document filling.
Function Query_Filling_Document_ItemReceipt_SerialNumbers(TablesList)
	
	// Add SerialNumbers table to document structure.
	TablesList.Insert("Table_Document_ItemReceipt_SerialNumbers", TablesList.Count());
	
	// Collect line items data.
	QueryText =
		"SELECT
		|	ItemReceiptSerialNumbers.Ref               AS FillingData,
		|	ItemReceiptSerialNumbers.LineItemsLineID   AS LineItemsLineID,
		|	ItemReceiptSerialNumbers.SerialNumber      AS SerialNumber
		|INTO
		|	Table_Document_ItemReceipt_SerialNumbers
		|FROM
		|	Document.ItemReceipt.SerialNumbers AS ItemReceiptSerialNumbers
		|WHERE
		|	ItemReceiptSerialNumbers.Ref IN (&FillingData_Document_ItemReceipt)";
	
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
Function Query_Filling_Document_ItemReceipt_Totals(TablesList)
	
	// Add Totals table to document structure.
	TablesList.Insert("Table_Document_ItemReceipt_Totals", TablesList.Count());
	
	// Collect totals data.
	QueryText =
		"SELECT
		// Totals of document
		|	ItemReceiptLineItems.FillingData        AS FillingData,
		|
		|	// Total(LineTotal)
		|	SUM(ItemReceiptLineItems.LineTotal)     AS DocumentTotal,
		|
		|	CAST( // Format(DocumentTotal * ExchangeRate, ""ND=17; NFD=2"")
		|		SUM(ItemReceiptLineItems.LineTotal) * // Total(LineTotal)
		|		ItemReceipt_.ExchangeRate
		|		AS NUMBER (17, 2))                  AS DocumentTotalRC
		|
		|INTO
		|	Table_Document_ItemReceipt_Totals
		|FROM
		|	Table_Document_ItemReceipt_LineItems AS ItemReceiptLineItems
		|	LEFT JOIN Table_Document_ItemReceipt_Attributes AS ItemReceipt_
		|		ON ItemReceipt_.FillingData = ItemReceiptLineItems.FillingData
		|GROUP BY
		|	ItemReceiptLineItems.FillingData,
		|	ItemReceipt_.ExchangeRate";
	
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
		|	Document_PurchaseOrder_Attributes.APAccount,
		|	Document_PurchaseOrder_Attributes.DueDate,
		|	Document_PurchaseOrder_Attributes.LocationActual,
		|	Document_PurchaseOrder_Attributes.DeliveryDateActual,
		|	Document_PurchaseOrder_Attributes.Project,
		|	Document_PurchaseOrder_Attributes.Class,
		|	Document_PurchaseOrder_Attributes.Terms,
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
		
	// Fill from item receipt.
	If TablesList.Property("Table_Document_ItemReceipt_Attributes") Then
		QueryText = QueryText + ?(Not IsBlankString(QueryText),
		"
		|
		|UNION ALL
		|
		|",
		"");
			
		SelectionText =
		"SELECT
		|	Document_ItemReceipt_Attributes.FillingData,
		|	Document_ItemReceipt_Attributes.Company,
		|	Document_ItemReceipt_Attributes.CompanyAddress,
		|	Document_ItemReceipt_Attributes.Currency,
		|	Document_ItemReceipt_Attributes.ExchangeRate,
		|	Document_ItemReceipt_Attributes.APAccount,
		|	Document_ItemReceipt_Attributes.DueDate,
		|	Document_ItemReceipt_Attributes.LocationActual,
		|	Document_ItemReceipt_Attributes.DeliveryDateActual,
		|	Document_ItemReceipt_Attributes.Project,
		|	Document_ItemReceipt_Attributes.Class,
		|	Document_ItemReceipt_Attributes.Terms,
		|	Document_ItemReceipt_Totals.DocumentTotal,
		|	Document_ItemReceipt_Totals.DocumentTotalRC
		|{Into}
		|FROM
		|	Table_Document_ItemReceipt_Attributes AS Document_ItemReceipt_Attributes
		|	LEFT JOIN Table_Document_ItemReceipt_Totals AS Document_ItemReceipt_Totals
		|		ON Document_ItemReceipt_Totals.FillingData = Document_ItemReceipt_Attributes.FillingData";
		
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
		|	Document_PurchaseOrder_LineItems.LineID,
		|	Document_PurchaseOrder_LineItems.Product,
		|	Document_PurchaseOrder_LineItems.ProductDescription,
		|	Document_PurchaseOrder_LineItems.Lot,
		|	Document_PurchaseOrder_LineItems.UnitSet,
		|	Document_PurchaseOrder_LineItems.QtyUnits,
		|	Document_PurchaseOrder_LineItems.Unit,
		|	Document_PurchaseOrder_LineItems.QtyUM,
		|	Document_PurchaseOrder_LineItems.PriceUnits,
		|	Document_PurchaseOrder_LineItems.OrderPriceUnits,
		|	Document_PurchaseOrder_LineItems.LineTotal,
		|	Document_PurchaseOrder_LineItems.Order,
		|	Document_PurchaseOrder_LineItems.ItemReceipt,
		|	Document_PurchaseOrder_LineItems.Location,
		|	Document_PurchaseOrder_LineItems.LocationActual,
		|	Document_PurchaseOrder_LineItems.DeliveryDate,
		|	Document_PurchaseOrder_LineItems.DeliveryDateActual,
		|	Document_PurchaseOrder_LineItems.Project,
		|	Document_PurchaseOrder_LineItems.Class
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
		
	// Fill from item receipt.
	If TablesList.Property("Table_Document_ItemReceipt_LineItems") Then
		QueryText = QueryText + ?(Not IsBlankString(QueryText), 
		"
		|
		|UNION ALL
		|
		|",
		"");
		
		SelectionText =
		"SELECT
		|	Document_ItemReceipt_LineItems.FillingData,
		|	Document_ItemReceipt_LineItems.LineID,
		|	Document_ItemReceipt_LineItems.Product,
		|	Document_ItemReceipt_LineItems.ProductDescription,
		|	Document_ItemReceipt_LineItems.Lot,
		|	Document_ItemReceipt_LineItems.UnitSet,
		|	Document_ItemReceipt_LineItems.QtyUnits,
		|	Document_ItemReceipt_LineItems.Unit,
		|	Document_ItemReceipt_LineItems.QtyUM,
		|	Document_ItemReceipt_LineItems.PriceUnits,
		|	Document_ItemReceipt_LineItems.OrderPriceUnits,
		|	Document_ItemReceipt_LineItems.LineTotal,
		|	Document_ItemReceipt_LineItems.Order,
		|	Document_ItemReceipt_LineItems.ItemReceipt,
		|	Document_ItemReceipt_LineItems.Location,
		|	Document_ItemReceipt_LineItems.LocationActual,
		|	Document_ItemReceipt_LineItems.DeliveryDate,
		|	Document_ItemReceipt_LineItems.DeliveryDateActual,
		|	Document_ItemReceipt_LineItems.Project,
		|	Document_ItemReceipt_LineItems.Class
		|{Into}
		|FROM
		|	Table_Document_ItemReceipt_LineItems AS Document_ItemReceipt_LineItems
		|WHERE
		|	Document_ItemReceipt_LineItems.QtyUnits > 0";
		
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

// Query for document filling.
Function Query_Filling_SerialNumbers(TablesList)
	
	// Add LineItems table to document structure.
	TablesList.Insert("Table_SerialNumbers", TablesList.Count());
	
	// Fill data from attributes and totals.
	QueryText = "";
	
	// Fill from purchase orders.
	If TablesList.Property("Table_Document_PurchaseOrder_SerialNumbers") Then
		QueryText = QueryText + ?(Not IsBlankString(QueryText), 
		"
		|
		|UNION ALL
		|
		|",
		"");
		
		SelectionText =
		"SELECT
		|	Document_PurchaseOrder_SerialNumbers.FillingData,
		|	Document_PurchaseOrder_SerialNumbers.LineItemsLineID,
		|	Document_PurchaseOrder_SerialNumbers.SerialNumber
		|{Into}
		|FROM
		|	Table_Document_PurchaseOrder_SerialNumbers AS Document_PurchaseOrder_SerialNumbers
		|WHERE
		|	Document_PurchaseOrder_SerialNumbers.SerialNumber <> """"";
		
		// Add selection to a query.
		QueryText = QueryText + StrReplace(SelectionText, "{Into}",
		?(IsBlankString(QueryText), 
		"INTO
		|	Table_SerialNumbers",
		""));
		
	EndIf;
		
	// Fill from item receipt.
	If TablesList.Property("Table_Document_ItemReceipt_SerialNumbers") Then
		QueryText = QueryText + ?(Not IsBlankString(QueryText), 
		"
		|
		|UNION ALL
		|
		|",
		"");
		
		SelectionText =
		"SELECT
		|	Document_ItemReceipt_SerialNumbers.FillingData,
		|	Document_ItemReceipt_SerialNumbers.LineItemsLineID,
		|	Document_ItemReceipt_SerialNumbers.SerialNumber
		|{Into}
		|FROM
		|	Table_Document_ItemReceipt_SerialNumbers AS Document_ItemReceipt_SerialNumbers
		|WHERE
		|	Document_ItemReceipt_SerialNumbers.SerialNumber <> """"";
		
		// Add selection to a query.
		QueryText = QueryText + StrReplace(SelectionText, "{Into}",
		?(IsBlankString(QueryText), 
		"INTO
		|	Table_SerialNumbers",
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
	CheckAttributes.Insert("Company",            "Check");
	CheckAttributes.Insert("Currency",           "Check");
	CheckAttributes.Insert("ExchangeRate",       "Check");
	CheckAttributes.Insert("APAccount",          "Check");
	// Maximal possible values.
	CheckAttributes.Insert("DueDate",            "Max");
	CheckAttributes.Insert("DeliveryDateActual", "Max");
	// Summarize totals.
	CheckAttributes.Insert("DocumentTotal",      "Sum");
	CheckAttributes.Insert("DocumentTotalRC",    "Sum");
	
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

//------------------------------------------------------------------------------
// Document printing

// Query for document data.
Function Query_Printing_Document_Data(TablesList)
	
	// Add document table to query structure.
	TablesList.Insert("Table_Printing_Document_Data", TablesList.Count());
	
	// Collect document data.
	QueryText =
	"SELECT
	// ------------------------------------------------------
	// Document data
	|	Document.Ref                          AS Ref,
	|	Document.PointInTime                  AS PointInTime,
	|	Document.Company                      AS Company
	// ------------------------------------------------------
	|INTO
	|	Table_Printing_Document_Data
	|FROM
	|	Document.PurchaseInvoice AS Document
	|WHERE
	|	Document.Ref IN(&Ref)";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_Printing_Document_Attributes(TablesList)
	
	// Add document table to query structure.
	TablesList.Insert("Table_Printing_Document_Attributes", TablesList.Count());
	
	// Collect attributes and totals.
	QueryText =
	"SELECT
	// ------------------------------------------------------
	// Attributes
	|	Document.Ref                          AS Ref,
	|	Document.Number                       AS Number,
	|	Document.Date                         AS Date,
	|	Document.Company                      AS Company,
	|	Document.Currency                     AS Currency,
	// ------------------------------------------------------
	// Totals
	|	Document.DocumentTotal                AS DocumentTotal
	// ------------------------------------------------------
	|FROM
	|	Table_Printing_Document_Data AS Document_Data
	|	LEFT JOIN Document.PurchaseInvoice AS Document
	|		ON Document.Ref = Document_Data.Ref
	|ORDER BY
	|	Document_Data.PointInTime ASC";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_Printing_Document_LineItems(TablesList)
	
	// Add document table to query structure.
	TablesList.Insert("Table_Printing_Document_LineItems", TablesList.Count());
	
	// Collect line items data.
	QueryText =
	"SELECT
	// ------------------------------------------------------
	// Line items table
	|	DocumentLineItems.Ref                 AS Ref,
	|	DocumentLineItems.LineNumber          AS LineNumber,
	|	DocumentLineItems.Product             AS Product,
	|	DocumentLineItems.ProductDescription  AS ProductDescription,
	|	DocumentLineItems.QtyUnits            AS QtyUnits,
	|	DocumentLineItems.Unit                AS Unit,
	|	DocumentLineItems.PriceUnits          AS PriceUnits,
	|	DocumentLineItems.LineTotal           AS LineTotal
	// ------------------------------------------------------
	|FROM
	|	Table_Printing_Document_Data AS Document_Data
	|	LEFT JOIN Document.PurchaseInvoice.LineItems AS DocumentLineItems
	|		ON DocumentLineItems.Ref = Document_Data.Ref
	|ORDER BY
	|	Document_Data.PointInTime ASC,
	|	DocumentLineItems.LineNumber ASC";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

#EndIf

#EndRegion
