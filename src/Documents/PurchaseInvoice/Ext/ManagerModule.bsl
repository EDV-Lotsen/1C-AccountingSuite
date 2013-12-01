
////////////////////////////////////////////////////////////////////////////////
// Purchase invoice: Manager module
//------------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
#Region PUBLIC_INTERFACE

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

//------------------------------------------------------------------------------
// Document posting

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
		Query.Text = Query.Text + Query_OrdersDispatched_Lock(LocksList);
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
		Query.Text = Query.Text + Query_OrdersDispatched_Balance(BalancesList);
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
		             Query_OrdersDispatched(TablesList);
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

//------------------------------------------------------------------------------
// Document filling

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
			
		ElsIf FillingData.Key = "Document_ItemReceipt" Then
			Query.Text = Query.Text +
			             Query_Filling_Document_ItemReceipt_Attributes(TablesList) +
			             Query_Filling_Document_ItemReceipt_OrdersStatuses(TablesList) +
			             Query_Filling_Document_ItemReceipt_OrdersDispatched(TablesList) +
			             Query_Filling_Document_ItemReceipt_LineItems(TablesList) +
			             Query_Filling_Document_ItemReceipt_Totals(TablesList);
			
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

// Check status of passed purchase order by ref
// Returns True if status passed for invoice filling
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
	
	// Execute query
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
#Region COMMANDS_HANDLERS

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

// Handler of standard print command
//
// Parameters:
//  Spreadsheet  - SpreadsheetDocument - Output spreadsheet.
//  SheetTitle   - String      - Spreadsheet title.
//  DocumentRef  - DocumentRef - Reference to document to be printed.
//               - Array       - Array of the document references to be printed in the same media.
//  TemplateName - String      - Name of replacing template for using within custom or predefined templates.
//               - Array       - Array of individual template names for each document reference.
//               - Undefined   - If not specified, then standard template will be used.
//
// Returns:
//  Spreadsheet  - Filled print form.
//  Title        - Filled spreadsheet title.
//
Procedure Print(Spreadsheet, SheetTitle, DocumentRef, TemplateName = Undefined) Export
	
	//------------------------------------------------------------------------------
	// 1. Filling of parameters
	
	// Common filling of parameters.
	PrintingTables                  = New Structure;
	DocumentParameters              = New Structure("Ref, Metadata, TemplateName");
	DocumentParameters.Ref          = DocumentRef;
	DocumentParameters.Metadata     = Metadata.Documents.PurchaseInvoice;
	DocumentParameters.TemplateName = TemplateName;
	
	//------------------------------------------------------------------------------
	// 2. Collect document data, available for printing, and fill printing structure.
	PrepareDataStructuresForPrinting(DocumentRef, DocumentParameters, PrintingTables);
	
	//------------------------------------------------------------------------------
	// 3. Fill output spreadsheet using the template and requested document data.
	
	// Define common template for the document.
	CommonTemplate       = DocumentPrinting.GetDocumentTemplate(DocumentParameters, PrintingTables);
	LogoPicture          = DocumentPrinting.GetDocumentLogo(DocumentParameters, PrintingTables);
	SheetTitle           = DocumentPrinting.GetDocumentTitle(DocumentParameters);
	LastUsedTemplateName = Undefined;
	
	// Prepare the output.
	Spreadsheet.Clear();
	
	// Go thru references and fill out the spreadsheet by each document.
	For Each DocumentAttributes In PrintingTables.Table_Printing_Document_Attributes Do
		
		//------------------------------------------------------------------------------
		// 3.1. Define template for the document.
		
		// Set the document template.
		If (DocumentParameters.TemplateName = Undefined)
		Or TypeOf(DocumentParameters.TemplateName) = Type("String") Then
			// Assign the common template for all documents.
			Template = CommonTemplate;
			
		ElsIf TypeOf(DocumentParameters.TemplateName) = Type("Array") Then
			// Use an individual template for each document.
			IndividualTemplateName = DocumentPrinting.GetIndividualTemplateName(DocumentRef, DocumentAttributes.Ref, DocumentParameters);
			If IndividualTemplateName = Undefined Then
				Template = CommonTemplate;
				LastUsedTemplateName = Undefined;
			ElsIf IndividualTemplateName <> LastUsedTemplateName Then
				Template = DocumentPrinting.GetDocumentTemplate(DocumentParameters, PrintingTables, IndividualTemplateName);
				LastUsedTemplateName = IndividualTemplateName;
			EndIf;
		EndIf;
		
		//------------------------------------------------------------------------------
		// 3.2. Output document data to spreadsheet using selected template.
		
		// Document output.
		If Template <> Undefined Then
			
			// Put logo into the template.
			DocumentPrinting.FillLogoInDocumentTemplate(Template, LogoPicture);
			
			// Fill document header.
			TemplateArea = Template.GetArea("Header");
			TemplateArea.Parameters.Fill(DocumentAttributes);
			TemplateArea.Parameters.Fill(PrintingTables.Table_OurCompany_Addresses_BillingAddress[0]);
			TemplateArea.Parameters.Fill(PrintingTables.Table_Company_Addresses_BillingAddress.Find(DocumentAttributes.Ref, "Ref"));
			
			// Output the header to the sheet.
			Spreadsheet.Put(TemplateArea);
			
			// Output the line items header to the sheet.
			TemplateArea = Template.GetArea("LineItemsHeader");
			Spreadsheet.Put(TemplateArea);
			
			// Output line items of current document.
			TemplateArea = Template.GetArea("LineItems");
			LineItems = PrintingTables.Table_Printing_Document_LineItems.FindRows(New Structure("Ref", DocumentAttributes.Ref));
			For Each Row In LineItems Do
				TemplateArea.Parameters.Fill(Row);
				Spreadsheet.Put(TemplateArea, 1);
			EndDo;
			
			// Output VAT (for VAT financial localization).
			If DocumentAttributes.VATTotal <> 0 Then;
				// Put subtotal.
				TemplateArea = Template.GetArea("Subtotal");
				TemplateArea.Parameters.Subtotal = ?(DocumentAttributes.PriceIncludesVAT,
				                                     DocumentAttributes.DocumentTotal,
				                                     DocumentAttributes.DocumentTotal - DocumentAttributes.VATTotal);
				Spreadsheet.Put(TemplateArea);
				
				// Put VAT.
				TemplateArea = Template.GetArea("VAT");
				TemplateArea.Parameters.VATTotal = DocumentAttributes.VATTotal;
				Spreadsheet.Put(TemplateArea);
			EndIf;
			
			// Output document total.
			TemplateArea = Template.GetArea("Total");
			TemplateArea.Parameters.DocumentTotal = DocumentAttributes.DocumentTotal;
			Spreadsheet.Put(TemplateArea);
		EndIf;
	EndDo;
	
EndProcedure

#EndIf

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region PRIVATE_IMPLEMENTATION

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

//------------------------------------------------------------------------------
// Document posting

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
	|	Document.PurchaseInvoice.LineItems AS LineItems
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
	|	LineItems.Location                    AS Location,
	|	LineItems.DeliveryDate                AS DeliveryDate,
	|	LineItems.Project                     AS Project,
	|	LineItems.Class                       AS Class,
	// ------------------------------------------------------
	// Resources
	|	0                                     AS Quantity,
	|	CASE WHEN LineItems.Product.Type = VALUE(Enum.InventoryTypes.Inventory)
	|	     THEN CASE WHEN LineItems.Quantity - 
	|	                    CASE WHEN OrdersDispatchedBalance.Received - OrdersDispatchedBalance.Invoiced > 0
	|	                         THEN OrdersDispatchedBalance.Received - OrdersDispatchedBalance.Invoiced
	|	                         ELSE 0 END > 0
	|	               THEN LineItems.Quantity - 
	|	                    CASE WHEN OrdersDispatchedBalance.Received - OrdersDispatchedBalance.Invoiced > 0
	|	                         THEN OrdersDispatchedBalance.Received - OrdersDispatchedBalance.Invoiced
	|	                         ELSE 0 END
	|	               ELSE 0 END
	|	     ELSE 0 END                       AS Received,
	|	LineItems.Quantity                    AS Invoiced
	// ------------------------------------------------------
	// Attributes
	// ------------------------------------------------------
	|FROM
	|	Document.PurchaseInvoice.LineItems AS LineItems
	|	LEFT JOIN Table_OrdersDispatched_Balance AS OrdersDispatchedBalance
	|		ON  OrdersDispatchedBalance.Company      = LineItems.Ref.Company
	|		AND OrdersDispatchedBalance.Order        = LineItems.Order
	|		AND OrdersDispatchedBalance.Product      = LineItems.Product
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

// Query for dimensions lock data
Function Query_OrdersDispatched_Lock(TablesList)
	
	// Add OrdersDispatched - Lock table to locks structure
	TablesList.Insert("AccumulationRegister_OrdersDispatched", TablesList.Count());
	
	// Collect dimensions for orders dispatched locking
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
	|	LineItems.Order <> VALUE(Document.PurchaseOrder.EmptyRef)";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for balances data
Function Query_OrdersDispatched_Balance(TablesList)
	
	// Add OrdersDispatched - Balances table to balances structure
	TablesList.Insert("Table_OrdersDispatched_Balance", TablesList.Count());
	
	// Collect orders dispatched balances
	QueryText =
	"SELECT
	// ------------------------------------------------------
	// Dimensions
	|	OrdersDispatchedBalance.Company          AS Company,
	|	OrdersDispatchedBalance.Order            AS Order,
	|	OrdersDispatchedBalance.Product          AS Product,
	|	OrdersDispatchedBalance.Location         AS Location,
	|	OrdersDispatchedBalance.DeliveryDate     AS DeliveryDate,
	|	OrdersDispatchedBalance.Project          AS Project,
	|	OrdersDispatchedBalance.Class            AS Class,
	// ------------------------------------------------------
	// Resources
	|	OrdersDispatchedBalance.QuantityBalance  AS Quantity,
	|	OrdersDispatchedBalance.ReceivedBalance  AS Received,
	|	OrdersDispatchedBalance.InvoicedBalance  AS Invoiced
	// ------------------------------------------------------
	|FROM
	|	AccumulationRegister.OrdersDispatched.Balance(&PointInTime,
	|		(Company, Order, Product) IN
	|			(SELECT
	|				&Company,
	|				LineItems.Order,
	|				LineItems.Product
	|			FROM
	|				Table_LineItems AS LineItems)) AS OrdersDispatchedBalance";
	
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
	// Table_OrdersDispatched_Balance already placed in TempTablesManager 
	DocumentPosting.PutTemporaryTable(AdditionalProperties.Posting.PostingTables.Table_OrdersDispatched, "Table_OrdersDispatched", Query.TempTablesManager);
	
	// Create query for calculate order status
	QueryText = QueryText +
	// Combine balance with document postings
	"SELECT
	// ------------------------------------------------------
	// Dimensions
	|	OrdersDispatchedBalance.Company          AS Company,
	|	OrdersDispatchedBalance.Order            AS Order,
	|	OrdersDispatchedBalance.Product          AS Product,
	// ------------------------------------------------------
	// Resources
	|	OrdersDispatchedBalance.Quantity         AS Quantity,
	|	OrdersDispatchedBalance.Received         AS Received,
	|	OrdersDispatchedBalance.Invoiced         AS Invoiced
	// ------------------------------------------------------
	|INTO
	|	OrdersDispatched_Balance_And_Postings
	|FROM
	|	Table_OrdersDispatched_Balance AS OrdersDispatchedBalance
	|   // (Company, Order) IN (SELECT Company, Order FROM Table_LineItems)
	|
	|UNION ALL
	|
	|SELECT
	// ------------------------------------------------------
	// Dimensions
	|	OrdersDispatched.Company,
	|	OrdersDispatched.Order,
	|	OrdersDispatched.Product,
	// ------------------------------------------------------
	// Resources
	|	OrdersDispatched.Quantity,
	|	OrdersDispatched.Received,
	|	OrdersDispatched.Invoiced
	// ------------------------------------------------------
	|FROM
	|	Table_OrdersDispatched AS OrdersDispatched
	|   // Table_LineItems WHERE LineItems.Ref = &Ref AND Order <> EmptyRef()
	|";
	QueryText   = QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	QueryTables = QueryTables + 1;
	
	// Calculate final balance after posting the invoice
	QueryText = QueryText +
	"SELECT
	// ------------------------------------------------------
	// Dimensions
	|	OrdersDispatchedBalance.Company          AS Company,
	|	OrdersDispatchedBalance.Order            AS Order,
	|	OrdersDispatchedBalance.Product          AS Product,
	|	OrdersDispatchedBalance.Product.Type     AS Type,
	// ------------------------------------------------------
	// Resources
	|	SUM(OrdersDispatchedBalance.Quantity)    AS Quantity,
	|	SUM(OrdersDispatchedBalance.Received)    AS Received,
	|	SUM(OrdersDispatchedBalance.Invoiced)    AS Invoiced
	// ------------------------------------------------------
	|INTO
	|	OrdersDispatched_Balance_AfterWrite
	|FROM
	|	OrdersDispatched_Balance_And_Postings AS OrdersDispatchedBalance
	|GROUP BY
	|	OrdersDispatchedBalance.Company,
	|	OrdersDispatchedBalance.Order,
	|	OrdersDispatchedBalance.Product,
	|	OrdersDispatchedBalance.Product.Type";
	QueryText   = QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	QueryTables = QueryTables + 1;
	
	// Calculate unreceived and uninvoiced items
	QueryText = QueryText +
	"SELECT
	// ------------------------------------------------------
	// Dimensions
	|	OrdersDispatchedBalance.Company          AS Company,
	|	OrdersDispatchedBalance.Order            AS Order,
	|	OrdersDispatchedBalance.Product          AS Product,
	// ------------------------------------------------------
	// Resources
	|	CASE WHEN OrdersDispatchedBalance.Type = VALUE(Enum.InventoryTypes.Inventory)
	|	     THEN OrdersDispatchedBalance.Quantity - OrdersDispatchedBalance.Received
	|	     ELSE 0 END                          AS UnReceived,
	|	CASE WHEN OrdersDispatchedBalance.Type = VALUE(Enum.InventoryTypes.Inventory)
	|	     THEN OrdersDispatchedBalance.Received - OrdersDispatchedBalance.Invoiced
	|	     WHEN OrdersDispatchedBalance.Type = VALUE(Enum.InventoryTypes.NonInventory)
	|	     THEN OrdersDispatchedBalance.Quantity - OrdersDispatchedBalance.Invoiced
	|	     ELSE 0 END                          AS UnInvoiced
	// ------------------------------------------------------
	|INTO
	|	OrdersDispatched_Balance_Unclosed
	|FROM
	|	OrdersDispatched_Balance_AfterWrite AS OrdersDispatchedBalance
	|WHERE
	|	CASE WHEN OrdersDispatchedBalance.Type = VALUE(Enum.InventoryTypes.Inventory)
	|	     THEN OrdersDispatchedBalance.Quantity - OrdersDispatchedBalance.Received
	|	     ELSE 0 END > 0
	|OR CASE WHEN OrdersDispatchedBalance.Type = VALUE(Enum.InventoryTypes.Inventory)
	|	     THEN OrdersDispatchedBalance.Received - OrdersDispatchedBalance.Invoiced
	|	     WHEN OrdersDispatchedBalance.Type = VALUE(Enum.InventoryTypes.NonInventory)
	|	     THEN OrdersDispatchedBalance.Quantity - OrdersDispatchedBalance.Invoiced
	|	     ELSE 0 END > 0";
	QueryText   = QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	QueryTables = QueryTables + 1;
	
	// Determine orders having unclosed items in balance
	QueryText = QueryText +
	"SELECT
	// ------------------------------------------------------
	// Dimensions
	|	OrdersDispatchedBalance.Order            AS Order,
	|	SUM(OrdersDispatchedBalance.UnReceived
	|	  + OrdersDispatchedBalance.UnInvoiced)  AS Unclosed
	// ------------------------------------------------------
	|INTO
	|	OrdersDispatched_Balance_Orders_Unclosed
	|FROM
	|	OrdersDispatched_Balance_Unclosed AS OrdersDispatchedBalance
	|GROUP BY
	|	OrdersDispatchedBalance.Order";
	QueryText   = QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	QueryTables = QueryTables + 1;
	
	// Calculate closed orders (those in invoice, which don't have unclosed items in theirs balance)
	QueryText = QueryText +
	"SELECT DISTINCT
	|	OrdersDispatched.Order AS Order
	|FROM
	|	Table_OrdersDispatched AS OrdersDispatched
	|	// Table_LineItems WHERE LineItems.Ref = &Ref AND Order <> EmptyRef()
	|	LEFT JOIN OrdersDispatched_Balance_Orders_Unclosed AS OrdersDispatchedBalanceUnclosed
	|		  ON  OrdersDispatchedBalanceUnclosed.Order = OrdersDispatched.Order
	|WHERE
	|	// No unclosed items
	|	ISNULL(OrdersDispatchedBalanceUnclosed.Unclosed, 0) = 0";
	QueryText   = QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	QueryTables = QueryTables + 1;
	
	// Clear orders registered postings table
	QueryText   = QueryText + 
	"DROP Table_OrdersDispatched";
	QueryText   = QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
	// Clear balance with document postings table
	QueryText   = QueryText + 
	"DROP OrdersDispatched_Balance_And_Postings";
	QueryText   = QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
	// Clear final balance after posting the invoice table
	QueryText   = QueryText + 
	"DROP OrdersDispatched_Balance_AfterWrite";
	QueryText   = QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
		
	// Clear unshipped and uninvoiced items table
	QueryText   = QueryText + 
	"DROP OrdersDispatched_Balance_Unclosed";
	QueryText   = QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
	// Clear orders having unclosed items in balance table
	QueryText   = QueryText + 
	"DROP OrdersDispatched_Balance_Orders_Unclosed";
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

//------------------------------------------------------------------------------
// Document filling

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
		|	PurchaseOrder.DeliveryDate              AS DeliveryDate,
		|	PurchaseOrder.Project                   AS Project,
		|	PurchaseOrder.Class                     AS Class,
		|	CASE
		|		WHEN PurchaseOrder.Company.Terms.Days IS NULL THEN DATEADD(&Date, DAY, 14)
		|		WHEN PurchaseOrder.Company.Terms.Days = 0     THEN DATEADD(&Date, DAY, 14)
		|		ELSE                                               DATEADD(&Date, DAY, PurchaseOrder.Company.Terms.Days)
		|	END                                     AS DueDate,
		|	ISNULL(PurchaseOrder.Company.Terms, VALUE(Catalog.PaymentTerms.EmptyRef))
		|	                                        AS Terms,
		|	ISNULL(PurchaseOrder.Currency.DefaultAPAccount, VALUE(ChartOfAccounts.ChartOfAccounts.EmptyRef))
		|	                                        AS APAccount,
		|	PurchaseOrder.PriceIncludesVAT          AS PriceIncludesVAT
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
		|		(Company, Order, Product, Location, DeliveryDate, Project, Class) IN
		|			(SELECT
		|				PurchaseOrderLineItems.Ref.Company,
		|				PurchaseOrderLineItems.Ref,
		|				PurchaseOrderLineItems.Product,
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
		|	PurchaseOrderLineItems.UM                  AS UM,
		|	PurchaseOrderLineItems.Price               AS Price,
		|	PurchaseOrderLineItems.Price               AS OrderPrice,
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
		|	PurchaseOrderLineItems.Location            AS Location,
		|	PurchaseOrderLineItems.DeliveryDate        AS DeliveryDate,
		|	PurchaseOrderLineItems.Ref                 AS Order,
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
		|		AND OrdersDispatched.Location     = PurchaseOrderLineItems.Location
		|		AND OrdersDispatched.DeliveryDate = PurchaseOrderLineItems.DeliveryDate
		|		AND OrdersDispatched.Project      = PurchaseOrderLineItems.Project
		|		AND OrdersDispatched.Class        = PurchaseOrderLineItems.Class
		|	LEFT JOIN Table_Document_PurchaseOrder_OrdersStatuses AS OrdersStatuses
		|		ON OrdersStatuses.Order = PurchaseOrderLineItems.Ref
		|WHERE
		|	PurchaseOrderLineItems.Ref IN (&FillingData_Document_PurchaseOrder)";
	
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
Function Query_Filling_Document_ItemReceipt_Attributes(TablesList)
	
	// Add Attributes table to document structure
	TablesList.Insert("Table_Document_ItemReceipt_Attributes", TablesList.Count());
	
	// Collect attributes data
	QueryText =
		"SELECT
		|	ItemReceipt.Ref                         AS FillingData,
		|	ItemReceipt.Company                     AS Company,
		|	ItemReceipt.CompanyCode                 AS CompanyCode,
		|	ItemReceipt.Currency                    AS Currency,
		|	ItemReceipt.ExchangeRate                AS ExchangeRate,
		|	ItemReceipt.Location                    AS Location,
		|	ItemReceipt.DeliveryDate                AS DeliveryDate,
		|	ItemReceipt.Project                     AS Project,
		|	ItemReceipt.Class                       AS Class,
		|	CASE
		|		WHEN ItemReceipt.Company.Terms.Days IS NULL THEN DATEADD(&Date, DAY, 14)
		|		WHEN ItemReceipt.Company.Terms.Days = 0     THEN DATEADD(&Date, DAY, 14)
		|		ELSE                                               DATEADD(&Date, DAY, ItemReceipt.Company.Terms.Days)
		|	END                                     AS DueDate,
		|	ISNULL(ItemReceipt.Company.Terms, VALUE(Catalog.PaymentTerms.EmptyRef))
		|	                                        AS Terms,
		|	ISNULL(ItemReceipt.Currency.DefaultAPAccount, VALUE(ChartOfAccounts.ChartOfAccounts.EmptyRef))
		|	                                        AS APAccount,
		|	ItemReceipt.PriceIncludesVAT            AS PriceIncludesVAT
		|INTO
		|	Table_Document_ItemReceipt_Attributes
		|FROM
		|	Document.ItemReceipt AS ItemReceipt
		|WHERE
		|	ItemReceipt.Ref IN (&FillingData_Document_ItemReceipt)";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document filling
Function Query_Filling_Document_ItemReceipt_OrdersStatuses(TablesList)
	
	// Add OrdersStatuses table to document structure
	TablesList.Insert("Table_Document_ItemReceipt_OrdersStatuses", TablesList.Count());
	
	// Collect orders statuses data
	QueryText =
		"SELECT
		// ------------------------------------------------------
		// Dimensions
		|	ItemReceipt.Ref                         AS Order,
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

// Query for document filling
Function Query_Filling_Document_ItemReceipt_OrdersDispatched(TablesList)
	
	// Add OrdersDispatched table to document structure
	TablesList.Insert("Table_Document_ItemReceipt_OrdersDispatched", TablesList.Count());
	
	// Collect orders items data
	QueryText =
		"SELECT
		// ------------------------------------------------------
		// Dimensions
		|	OrdersDispatchedBalance.Company          AS Company,
		|	OrdersDispatchedBalance.Order            AS Order,
		|	OrdersDispatchedBalance.Product          AS Product,
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
		|	Table_Document_ItemReceipt_OrdersDispatched
		|FROM
		|	AccumulationRegister.OrdersDispatched.Balance(,
		|		(Company, Order, Product) IN
		|			(SELECT
		|				ItemReceiptLineItems.Ref.Company,
		|				ItemReceiptLineItems.Ref,
		|				ItemReceiptLineItems.Product,
		|				ItemReceiptLineItems.Location,
		|				ItemReceiptLineItems.DeliveryDate,
		|				ItemReceiptLineItems.Project,
		|				ItemReceiptLineItems.Class
		|			FROM
		|				Document.ItemReceipt.LineItems AS ItemReceiptLineItems
		|			WHERE
		|				ItemReceiptLineItems.Ref IN (&FillingData_Document_ItemReceipt))) AS OrdersDispatchedBalance
		|	LEFT JOIN Table_Document_ItemReceipt_OrdersStatuses AS OrdersStatuses
		|		ON OrdersDispatchedBalance.Order = OrdersStatuses.Order";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document filling
Function Query_Filling_Document_ItemReceipt_LineItems(TablesList)
	
	// Add LineItems table to document structure
	TablesList.Insert("Table_Document_ItemReceipt_LineItems", TablesList.Count());
	
	// Collect line items data
	QueryText =
		"SELECT
		|	ItemReceiptLineItems.Ref                   AS FillingData,
		|	ItemReceiptLineItems.Product               AS Product,
		|	ItemReceiptLineItems.ProductDescription    AS ProductDescription,
		|	ItemReceiptLineItems.UM                    AS UM,
		|	ItemReceiptLineItems.Price                 AS Price,
		|	ItemReceiptLineItems.Price                 AS OrderPrice,
		|	CASE
		|		WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Open)
		|			THEN ISNULL(OrdersDispatched.Quantity, ItemReceiptLineItems.Quantity)
		|		WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Backordered)
		|			THEN ISNULL(OrdersDispatched.Backorder, ItemReceiptLineItems.Quantity)
		|		WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Closed)
		|			THEN ISNULL(OrdersDispatched.Backorder, 0)
		|		ELSE 0
		|	END                                        AS Quantity,
		|	CAST( // Format(Quantity * Price, ""ND=15; NFD=2"")
		|		CASE
		|			WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Open)
		|				THEN ISNULL(OrdersDispatched.Quantity, ItemReceiptLineItems.Quantity)
		|			WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Backordered)
		|				THEN ISNULL(OrdersDispatched.Backorder, ItemReceiptLineItems.Quantity)
		|			WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Closed)
		|				THEN ISNULL(OrdersDispatched.Backorder, 0)
		|			ELSE 0
		|		END * ItemReceiptLineItems.Price 
		|		AS NUMBER (15, 2))                     AS LineTotal,
		|	ItemReceiptLineItems.VATCode             AS VATCode,
		|	CAST( // Format(LineTotal * VATRate / 100, ""ND=15; NFD=2"")
		|		CAST( // Format(Quantity * Price, ""ND=15; NFD=2"")
		|			CASE
		|				WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Open)
		|					THEN ISNULL(OrdersDispatched.Quantity, ItemReceiptLineItems.Quantity)
		|				WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Backordered)
		|					THEN ISNULL(OrdersDispatched.Backorder, ItemReceiptLineItems.Quantity)
		|				WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Closed)
		|					THEN ISNULL(OrdersDispatched.Backorder, 0)
		|				ELSE 0
		|			END * ItemReceiptLineItems.Price
		|		AS NUMBER (15, 2)) *
		|		CASE // VATRate = ?(Ref.PriceIncludesVAT, VATCode.PurchaseInclRate, VATCode.PurchaseExclRate)
		|			WHEN ItemReceiptLineItems.Ref.PriceIncludesVAT IS NULL THEN 0
		|			WHEN ItemReceiptLineItems.Ref.PriceIncludesVAT         THEN ISNULL(ItemReceiptLineItems.VATCode.PurchaseInclRate, 0)
		|			ELSE                                                          ISNULL(ItemReceiptLineItems.VATCode.PurchaseExclRate, 0)
		|		END /
		|		100
		|	AS NUMBER (15, 2))                         AS VAT,
		|	ItemReceiptLineItems.Location              AS Location,
		|	ItemReceiptLineItems.DeliveryDate          AS DeliveryDate,
		|	ItemReceiptLineItems.Order                 AS Order,
		|	ItemReceiptLineItems.Project               AS Project,
		|	ItemReceiptLineItems.Class                 AS Class,
		|	ItemReceiptLineItems.Ref.Company           AS Company
		|INTO
		|	Table_Document_ItemReceipt_LineItems
		|FROM
		|	Document.ItemReceipt.LineItems AS ItemReceiptLineItems
		|	LEFT JOIN Table_Document_ItemReceipt_OrdersDispatched AS OrdersDispatched
		|		ON  OrdersDispatched.Company      = ItemReceiptLineItems.Ref.Company
		|		AND OrdersDispatched.Order        = ItemReceiptLineItems.Ref
		|		AND OrdersDispatched.Product      = ItemReceiptLineItems.Product
		|		AND OrdersDispatched.Location     = ItemReceiptLineItems.Location
		|		AND OrdersDispatched.DeliveryDate = ItemReceiptLineItems.DeliveryDate
		|		AND OrdersDispatched.Project      = ItemReceiptLineItems.Project
		|		AND OrdersDispatched.Class        = ItemReceiptLineItems.Class
		|	LEFT JOIN Table_Document_ItemReceipt_OrdersStatuses AS OrdersStatuses
		|		ON OrdersStatuses.Order = ItemReceiptLineItems.Ref
		|WHERE
		|	ItemReceiptLineItems.Ref IN (&FillingData_Document_ItemReceipt)";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document filling
Function Query_Filling_Document_ItemReceipt_Totals(TablesList)
	
	// Add Totals table to document structure
	TablesList.Insert("Table_Document_ItemReceipt_Totals", TablesList.Count());
	
	// Collect totals data
	QueryText =
		"SELECT
		// Totals of document
		|	ItemReceiptLineItems.FillingData        AS FillingData,
		|
		|	CAST( // Format(Total(VAT) * ExchangeRate, ""ND=15; NFD=2"")
		|		SUM(ItemReceiptLineItems.VAT) *
		|		ItemReceipt.ExchangeRate
		|		AS NUMBER (15, 2))                  AS VATTotal,
		|
		|	CASE
		|		WHEN ItemReceipt.PriceIncludesVAT THEN // Total(LineTotal)
		|			SUM(ItemReceiptLineItems.LineTotal)
		|		ELSE                                     // Total(LineTotal) + Total(VAT)
		|			SUM(ItemReceiptLineItems.LineTotal) +
		|			SUM(ItemReceiptLineItems.VAT)
		|	END                                     AS DocumentTotal,
		|
		|	CAST( // Format(DocumentTotal * ExchangeRate, ""ND=15; NFD=2"")
		|		CASE // DocumentTotal
		|			WHEN ItemReceipt.PriceIncludesVAT THEN // Total(LineTotal)
		|				SUM(ItemReceiptLineItems.LineTotal)
		|			ELSE                                     // Total(LineTotal) + Total(VAT)
		|				SUM(ItemReceiptLineItems.LineTotal) +
		|				SUM(ItemReceiptLineItems.VAT)
		|		END *
		|		ItemReceipt.ExchangeRate
		|		AS NUMBER (15, 2))                  AS DocumentTotalRC
		|
		|INTO
		|	Table_Document_ItemReceipt_Totals
		|FROM
		|	Table_Document_ItemReceipt_LineItems AS ItemReceiptLineItems
		|	LEFT JOIN Table_Document_ItemReceipt_Attributes AS ItemReceipt
		|		ON ItemReceipt.FillingData = ItemReceiptLineItems.FillingData
		|GROUP BY
		|	ItemReceiptLineItems.FillingData,
		|	ItemReceipt.ExchangeRate,
		|	ItemReceipt.PriceIncludesVAT";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document filling
Function Query_Filling_Attributes(TablesList)
	
	// Add Attributes table to document structure
	TablesList.Insert("Table_Attributes", TablesList.Count());
	
	// Fill data from attributes and totals
	QueryText = "";
	
	// Fill from purchase orders
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
		|	Document_PurchaseOrder_Attributes.DeliveryDate,
		|	Document_PurchaseOrder_Attributes.Project,
		|	Document_PurchaseOrder_Attributes.Class,
		|	Document_PurchaseOrder_Attributes.DueDate,
		|	Document_PurchaseOrder_Attributes.Terms,
		|	Document_PurchaseOrder_Totals.VATTotal,
		|	Document_PurchaseOrder_Attributes.APAccount,
		|	Document_PurchaseOrder_Attributes.PriceIncludesVAT
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
	
	// Fill from goods receipts
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
		|	Document_ItemReceipt_Attributes.CompanyCode,
		|	Document_ItemReceipt_Totals.DocumentTotal,
		|	Document_ItemReceipt_Attributes.Currency,
		|	Document_ItemReceipt_Attributes.ExchangeRate,
		|	Document_ItemReceipt_Totals.DocumentTotalRC,
		|	Document_ItemReceipt_Attributes.Location,
		|	Document_ItemReceipt_Attributes.DeliveryDate,
		|	Document_ItemReceipt_Attributes.Project,
		|	Document_ItemReceipt_Attributes.Class,
		|	Document_ItemReceipt_Attributes.DueDate,
		|	Document_ItemReceipt_Attributes.Terms,
		|	Document_ItemReceipt_Totals.VATTotal,
		|	Document_ItemReceipt_Attributes.APAccount,
		|	Document_ItemReceipt_Attributes.PriceIncludesVAT
		|{Into}
		|FROM
		|	Table_Document_ItemReceipt_Attributes AS Document_ItemReceipt_Attributes
		|	LEFT JOIN Table_Document_ItemReceipt_Totals AS Document_ItemReceipt_Totals
		|		ON Document_ItemReceipt_Totals.FillingData = Document_ItemReceipt_Attributes.FillingData";
		
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
	
	// Fill from purchase orders
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
		|	Document_PurchaseOrder_LineItems.UM,
		|	Document_PurchaseOrder_LineItems.Price,
		|	Document_PurchaseOrder_LineItems.OrderPrice,
		|	Document_PurchaseOrder_LineItems.Quantity,
		|	Document_PurchaseOrder_LineItems.LineTotal,
		|	Document_PurchaseOrder_LineItems.VATCode,
		|	Document_PurchaseOrder_LineItems.VAT,
		|	Document_PurchaseOrder_LineItems.Location,
		|	Document_PurchaseOrder_LineItems.DeliveryDate,
		|	Document_PurchaseOrder_LineItems.Order,
		|	Document_PurchaseOrder_LineItems.Project,
		|	Document_PurchaseOrder_LineItems.Class
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
	
	// Fill from goods receipts
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
		|	Document_ItemReceipt_LineItems.Product,
		|	Document_ItemReceipt_LineItems.ProductDescription,
		|	Document_ItemReceipt_LineItems.UM,
		|	Document_ItemReceipt_LineItems.Price,
		|	Document_ItemReceipt_LineItems.OrderPrice,
		|	Document_ItemReceipt_LineItems.Quantity,
		|	Document_ItemReceipt_LineItems.LineTotal,
		|	Document_ItemReceipt_LineItems.VATCode,
		|	Document_ItemReceipt_LineItems.VAT,
		|	Document_ItemReceipt_LineItems.Location,
		|	Document_ItemReceipt_LineItems.DeliveryDate,
		|	Document_ItemReceipt_LineItems.Order,
		|	Document_ItemReceipt_LineItems.Project,
		|	Document_ItemReceipt_LineItems.Class
		|{Into}
		|FROM
		|	Table_Document_ItemReceipt_LineItems AS Document_ItemReceipt_LineItems
		|WHERE
		|	Document_ItemReceipt_LineItems.Quantity > 0";
		
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
	CheckAttributes.Insert("APAccount",        "Check");
	CheckAttributes.Insert("PriceIncludesVAT", "Check");
	// Maximal possible values
	CheckAttributes.Insert("DueDate",          "Max");
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

//------------------------------------------------------------------------------
// Document printing

// Query for document data
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

// Query for document data
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
	|	Document.PriceIncludesVAT             AS PriceIncludesVAT,
	// ------------------------------------------------------
	// Totals
	|	Document.DocumentTotal                AS DocumentTotal,
	|	Document.VATTotal                     AS VATTotal
	// ------------------------------------------------------
	|FROM
	|	Table_Printing_Document_Data AS Document_Data
	|	LEFT JOIN Document.PurchaseInvoice AS Document
	|		ON Document.Ref = Document_Data.Ref
	|ORDER BY
	|	Document_Data.PointInTime ASC";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data
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
	|	DocumentLineItems.Quantity            AS Quantity,
	|	DocumentLineItems.UM                  AS UM,
	|	DocumentLineItems.Price               AS Price,
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
