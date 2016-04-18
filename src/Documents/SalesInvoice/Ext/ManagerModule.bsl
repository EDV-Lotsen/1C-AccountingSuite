
////////////////////////////////////////////////////////////////////////////////
// Sales Invoice: Manager module
//------------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
#Region EVENTS_HANDLERS

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	
	//StandardProcessing = False;
	//
	//Presentation = "SI #" + Data.Number + " " + Format(Data.Date, "DLF=D"); 
	
EndProcedure

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
		             Query_OrdersRegistered_Balance(BalancesList) +
					 Query_OrdersRegisteredShipment_Balance(BalancesList);
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
	SalesTaxPosting  = GeneralFunctionsReusable.FunctionalOptionValue("SalesTaxCharging");
	
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
				 Query_GeneralJournal_Accounts_Income(TablesList) +
				 Query_GeneralJournal_Accounts_COGS_Quantity(TablesList) +
				 Query_GeneralJournal_Accounts_COGS_Amount(TablesList) +
				 Query_GeneralJournal_Accounts_COGS(TablesList) +
				 Query_GeneralJournal_Accounts_InvOrExp_Quantity(TablesList) +
				 Query_GeneralJournal_Accounts_InvOrExp_Amount(TablesList) +
				 Query_GeneralJournal_Accounts_InvOrExp(TablesList) +
				 Query_GeneralJournal(TablesList) +
				 //--//GJ++
	             Query_GeneralJournalAnalyticsDimensions_Accounts_Income(TablesList)+
	             Query_GeneralJournalAnalyticsDimensions_Accounts_Income_Difference_Amount(TablesList)+
	             Query_GeneralJournalAnalyticsDimensions_Accounts_Income_Difference(TablesList)+
	             Query_GeneralJournalAnalyticsDimensions_Accounts_COGS_Quantity(TablesList)+
	             Query_GeneralJournalAnalyticsDimensions_Accounts_COGS_Amount(TablesList)+
	             Query_GeneralJournalAnalyticsDimensions_Accounts_COGS(TablesList)+
	             Query_GeneralJournalAnalyticsDimensions_Accounts_COGS_Difference_Amount(TablesList)+
	             Query_GeneralJournalAnalyticsDimensions_Accounts_COGS_Difference(TablesList)+
	             Query_GeneralJournalAnalyticsDimensions_Accounts_InvOrExp_Quantity(TablesList)+
	             Query_GeneralJournalAnalyticsDimensions_Accounts_InvOrExp_Amount(TablesList)+
	             Query_GeneralJournalAnalyticsDimensions_Accounts_InvOrExp(TablesList)+
	             Query_GeneralJournalAnalyticsDimensions_Accounts_InvOrExp_Difference_Amount(TablesList)+
	             Query_GeneralJournalAnalyticsDimensions_Accounts_InvOrExp_Difference(TablesList)+
	             Query_GeneralJournalAnalyticsDimensions_Transactions(TablesList)+
	             Query_GeneralJournalAnalyticsDimensions(TablesList)+
	             //--//GJ--
				 
				 Query_CashFlowData_Difference_Amount(TablesList) +
				 Query_CashFlowData_Difference(TablesList) +
	             Query_CashFlowData(TablesList) +
				 
				 Query_ProjectData_Accounts_Income(TablesList) +
				 Query_ProjectData_Accounts_COGS_Quantity(TablesList) +
				 Query_ProjectData_Accounts_COGS_Amount(TablesList) +
				 Query_ProjectData_Accounts_COGS(TablesList) +
				 Query_ProjectData(TablesList) +
				 Query_ClassData_Accounts_Income(TablesList) +
				 Query_ClassData_Accounts_COGS_Quantity(TablesList) +
				 Query_ClassData_Accounts_COGS_Amount(TablesList) +
				 Query_ClassData_Accounts_COGS(TablesList) +
				 Query_ClassData(TablesList) +
				 Query_OrderTransactions(TablesList);
				 
	If SalesTaxPosting Then
		Query.Text = Query.Text +
					 Query_SalesTaxOwed(TablesList);
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
	
	// Custom orders update after filling of all tables.
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

// Automatically accept existing SO prepayment on posting new SI with SO in tab section.
Procedure ProcessSalesOrdersPrepayment(DocumentRef) Export
	
	If Constants.UseSOPrepayment.Get() = False Then 
		Return;
	EndIf;	
	
	If False Then 
		DocumentRef = Documents.SalesInvoice.FindByNumber("");
	EndIf;	
	
	Company = DocumentRef.Company;
	Currency = DocumentRef.Currency;
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	SalesInvoiceLineItems.Order
		|INTO Orders
		|FROM
		|	Document.SalesInvoice.LineItems AS SalesInvoiceLineItems
		|WHERE
		|	SalesInvoiceLineItems.Ref = &Ref
		|	AND SalesInvoiceLineItems.Order <> VALUE(Document.SalesOrder.EmptyRef)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	CashReceipt.Ref
		|INTO SOPrepayments
		|FROM
		|	Orders AS Orders
		|		INNER JOIN Document.CashReceipt AS CashReceipt
		|		ON Orders.Order = CashReceipt.SalesOrder
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	GeneralJournalBalance.ExtDimension1 AS Company,
		|	GeneralJournalBalance.ExtDimension2 As Document,
		|	-GeneralJournalBalance.AmountBalance AS Amount,
		|	-GeneralJournalBalance.AmountRCBalance AS AmountRC
		|FROM
		|	AccountingRegister.GeneralJournal.Balance(,Account = &ARPrepaymentAccount,, ExtDimension1 = (&Company) AND ExtDimension2 IN (SELECT SOPrepayments.Ref FROM SOPrepayments AS SOPrepayments)) AS GeneralJournalBalance";
	
	Query.SetParameter("ARPrepaymentAccount", Currency.DefaultPrepaymentAR);
	Query.SetParameter("Company", Company);
	Query.SetParameter("Ref", DocumentRef);
	
	PrepaymentTable = Query.Execute().Unload();
	SOPrepaymentTotalAmount = 0;
	If PrepaymentTable.Count() = 0 Then 
		Return;
	Else 
		SOPrepaymentTotalAmount = PrepaymentTable.Total("Amount");
	EndIf;	
	
	///////////////////////////////////////////////////////////////////////////////////////	
	SIBalanceQuery = New Query;
	SIBalanceQuery.Text = "SELECT
	|	Isnull(SUM(GeneralJournalTurnovers.AmountTurnover),0) AS Amount,
	|	Isnull(SUM(GeneralJournalTurnovers.AmountRCTurnover),0) AS AmountRC
	|FROM
	|	AccountingRegister.GeneralJournal.Turnovers(,,Recorder,Account = &ARAccount,, ExtDimension1 = &Company AND ExtDimension2 = &SIRef) AS GeneralJournalTurnovers
	|WHERE
	|	GeneralJournalTurnovers.Recorder <> &SIRef";
	
	
	SIBalanceQuery.SetParameter("SIRef",  DocumentRef);			 
	SIBalanceQuery.SetParameter("Company", Company);
	SIBalanceQuery.SetParameter("ARAccount", Currency.DefaultARAccount);
	QueryBalanceResult = SIBalanceQuery.Execute().Select();
	
	SIBalance = DocumentRef.DocumentTotal;
	
	While QueryBalanceResult.Next() Do 
		SIBalance = SIBalance + QueryBalanceResult.Amount;
	EndDo;
	
	If SIBalance <= 0 Then
		Return;
	EndIf;
	
	SOPrepaymentToDistribute = Min(SIBalance,SOPrepaymentTotalAmount);
	
	AuxCashReceipt = Documents.CashReceipt.CreateDocument();
	AuxCashReceipt.Date = DocumentRef.Date;
	AuxCashReceipt.Company = Company;
	AuxCashReceipt.Currency = Currency;
	If Not Currency.IsEmpty() Then 
		AuxCashReceipt.Currency = Currency;
	ElsIf Not Company.DefaultCurrency.IsEmpty() Then 
		AuxCashReceipt.Currency = Company.DefaultCurrency;
	ElsIf Not Company.ARAccount.Currency.IsEmpty() Then 
		AuxCashReceipt.Currency = Company.ARAccount.Currency;
	Else 
		AuxCashReceipt.Currency = GeneralFunctionsReusable.DefaultCurrency();
	EndIf;	
		
	EmailQuery = New Query();
	EmailQuery.Text = "SELECT
	|	Addresses.Email
	|FROM
	|	Catalog.Addresses AS Addresses
	|WHERE
	|	Addresses.Owner = &Company
	|	AND Addresses.DefaultBilling";
	EmailQuery.SetParameter("Company", Company);
	EmailQueryResult = EmailQuery.Execute().Select();	
	If EmailQueryResult.Next() Then
		AuxCashReceipt.EmailTo = EmailQueryResult.Email;
	EndIf;
	
	If Not Company.ARAccount.IsEmpty()Then 
		AuxCashReceipt.ARAccount = Company.ARAccount;
	ElsIf Not Currency.DefaultARAccount.IsEmpty() Then 
		AuxCashReceipt.ARAccount = AuxCashReceipt.Currency.DefaultARAccount;
	Else 
		AuxCashReceipt.ARAccount = DocumentRef.ARAccount;
	EndIf;
	
	AuxCashReceipt.BankAccount = Constants.UndepositedFundsAccount.Get();
	AuxCashReceipt.DepositType = 1;
	
	
	AuxCashReceipt.ExchangeRate = GeneralFunctions.GetExchangeRate(AuxCashReceipt.Date, AuxCashReceipt.Currency);
	
	LineItems = AuxCashReceipt.LineItems.Add();
	LineItems.Document = DocumentRef;
	LineItems.Payment =  SOPrepaymentToDistribute;
	
	SOPrepayQty = 0;
	NamesOfAppliedSOPrepayments = "";
	For Each Credit in PrepaymentTable Do 
		If SOPrepaymentToDistribute > 0 Then 
			DocCredit = AuxCashReceipt.CreditMemos.Add();
			DocCredit.Document = Credit.Document;
			DocCredit.Payment = Min(Credit.Amount,SOPrepaymentToDistribute);
			SOPrepaymentToDistribute = SOPrepaymentToDistribute - DocCredit.Payment;
			SOPrepayQty = SOPrepayQty + 1;
			NamesOfAppliedSOPrepayments = NamesOfAppliedSOPrepayments + ?(NamesOfAppliedSOPrepayments = "","",", ") + Credit.Document;
		Else
			Break;
		EndIf;
	EndDo;
	
	AuxCashReceipt.DocumentTotal = SOPrepaymentToDistribute;
	AuxCashReceipt.DocumentTotalRC = SOPrepaymentToDistribute*AuxCashReceipt.ExchangeRate;
	Try
		AuxCashReceipt.Write(DocumentWriteMode.Posting);
		If SOPrepayQty > 1 Then 
			Message("SO Prepayments: "+NamesOfAppliedSOPrepayments+" were applied. Was created " + AuxCashReceipt.Ref);
		Else	
			Message("SO Prepayment "+NamesOfAppliedSOPrepayments+" was applied. Was created " + AuxCashReceipt.Ref);
		EndIf;	
	Except
		Msg = ErrorDescription();
		Message("Error occurred on applying SO prepayments for this sales invoice: " + Msg);
	EndTry;
	//SelectionDetailRecords = QueryResult.Select();
	//
	//While SelectionDetailRecords.Next() Do
	//	
	//EndDo;

	
EndProcedure	

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
	InvoiceLineItems = LineItems.Unload(Filter, "LineNumber, Order, Shipment, Product, Unit, Location, DeliveryDate, Project, Class, QtyUnits");
	InvoiceLineItems.Columns.Insert(1, "Company", New TypeDescription("CatalogRef.Companies"), "", 20);
	InvoiceLineItems.FillValues(Company, "Company");
	DocumentPosting.PutTemporaryTable(InvoiceLineItems, "InvoiceLineItems", Query.TempTablesManager);
	
	// 3. Request uninvoiced items for each line item.
	Query.Text = "
		|SELECT
		|	LineItems.LineNumber          AS LineNumber,
		|	LineItems.Order               AS Order,
		|	LineItems.Shipment            AS Shipment,
		|	LineItems.Product.Code        AS ProductCode,
		|	LineItems.Product.Description AS ProductDescription,
		|	CASE 
		|       WHEN LineItems.Shipment <> VALUE(Document.Shipment.EmptyRef) 
		|		    THEN OrdersRegisteredBalance.ShippedShipmentBalance - OrdersRegisteredBalance.InvoicedBalance - LineItems.QtyUnits 
		|		ELSE OrdersRegisteredBalance.QuantityBalance - OrdersRegisteredBalance.InvoicedBalance - LineItems.QtyUnits
		|   END                           AS UninvoicedQuantity	
		|FROM
		|	InvoiceLineItems AS LineItems
		|	LEFT JOIN AccumulationRegister.OrdersRegistered.Balance(&Date, (Company, Order, Shipment, Product, Unit, Location, DeliveryDate, Project, Class)
		|		      IN (SELECT Company, Order, Shipment, Product, Unit, Location, DeliveryDate, Project, Class FROM InvoiceLineItems)) AS OrdersRegisteredBalance
		|		ON  LineItems.Company      = OrdersRegisteredBalance.Company
		|		AND LineItems.Order        = OrdersRegisteredBalance.Order
		|		AND LineItems.Shipment     = OrdersRegisteredBalance.Shipment
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
				                            NStr("en = 'The product %1 in line %2 was not declared in %3.'"), TrimAll(Row.ProductCode) + " " + TrimAll(Row.ProductDescription), Row.LineNumber, ?(ValueIsFilled(Row.Shipment), Row.Shipment, Row.Order));
			EndIf;
			
		ElsIf Row.UninvoicedQuantity < 0 Then
			ErrorsCount = ErrorsCount + 1;
			If ErrorsCount <= 10 Then
				MessageText = MessageText + ?(Not IsBlankString(MessageText), Chars.LF, "") +
				                            StringFunctionsClientServer.SubstituteParametersInString(
				                            NStr("en = 'The invoiced quantity of product %1 in line %2 exceeds ordered quantity in %3.'"), TrimAll(Row.ProductCode) + " " + TrimAll(Row.ProductDescription), Row.LineNumber, ?(ValueIsFilled(Row.Shipment), Row.Shipment, Row.Order));
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
			             Query_Filling_Document_SalesOrder_SerialNumbers(TablesList) +
			             Query_Filling_Document_SalesOrder_Totals(TablesList);
						 
		ElsIf FillingData.Key = "Document_Shipment" Then 
			Query.Text = Query.Text +
						 Query_Filling_Document_Shipment_Attributes(TablesList) +
						 Query_Filling_Document_Shipment_CommonTotals(TablesList) +
						 Query_Filling_Document_Shipment_OrdersStatuses(TablesList) +
						 Query_Filling_Document_Shipment_OrdersRegistered(TablesList) +
						 Query_Filling_Document_Shipment_LineItems(TablesList) +
						 Query_Filling_Document_Shipment_SerialNumbers(TablesList) +
						 Query_Filling_Document_Shipment_Totals(TablesList);
			
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
// Returns True if status passed for invoice filling.
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

// Check status of passed shipment by ref.
// Returns True if status passed for invoice filling.
Function CheckStatusOfShipment(DocumentRef, FillingRef) Export
	
	// Create new query.
	Query = New Query;
	Query.SetParameter("Ref", FillingRef);
	
	QueryText = 
		"SELECT
		|	CASE
		|		WHEN Shipment.DeletionMark THEN
		|			 VALUE(Enum.OrderStatuses.Deleted)
		|		WHEN NOT Shipment.Posted THEN
		|			 VALUE(Enum.OrderStatuses.Draft)
		|		WHEN OrdersStatuses.Status IS NULL THEN
		|			 VALUE(Enum.OrderStatuses.Open)
		|		WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.EmptyRef) THEN
		|			 VALUE(Enum.OrderStatuses.Open)
		|		ELSE
		|			 OrdersStatuses.Status
		|	END AS Status
		|FROM
		|	Document.Shipment AS Shipment
		|	LEFT JOIN InformationRegister.OrdersStatuses.SliceLast AS OrdersStatuses
		|		ON Shipment.Ref = OrdersStatuses.Order
		|WHERE
		|	Shipment.Ref = &Ref";
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
	
	If StatusOK Then
		MessageText = NStr("en = 'Failed to generate the %1 because %2 use Shipment.'");
		MessageText = StringFunctionsClientServer.SubstituteParametersInString(MessageText,
		                                                                       Lower(Metadata.FindByType(TypeOf(DocumentRef)).Presentation()),
		                                                                       Lower(Metadata.FindByType(TypeOf(FillingRef)).Presentation())); 
		CommonUseClientServer.MessageToUser(MessageText, FillingRef);
	EndIf;
	
	Return StatusOK;
	
EndFunction

//------------------------------------------------------------------------------
// Document printing

#EndIf

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region COMMANDS_HANDLERS

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

//------------------------------------------------------------------------------
// Document printing

// -> CODE REVIEW
Procedure Print(Spreadsheet, SheetTitle, Ref, TemplateName = Undefined) Export
	PrintFormFunctions.PrintSI(Spreadsheet, SheetTitle, Ref, TemplateName); 	  
EndProcedure

Procedure PrintPackingList(Spreadsheet, SheetTitle, Ref, TemplateName = Undefined) Export  
	
	SheetTitle = "Packing list";
	CustomTemplate = GeneralFunctions.GetCustomTemplate("Document.SalesInvoice", SheetTitle);
	
	//++ Misa, 11/17/2014 ACS 1486
	SplitQuantinyField = False;
	//-- Misa 11/17/2014 ACS 1486
	
	If CustomTemplate = Undefined Then
		Template = Documents.SalesInvoice.GetTemplate("PF_MXL_PackingList");
		//++ Misa, 11/17/2014 ACS 1486
		SplitQuantinyField = True;
		//-- Misa 11/17/2014 ACS 1486
	Else
		Template = CustomTemplate;
	EndIf;
	
	// Create a spreadsheet document and set print parameters.
  // SpreadsheetDocument = New SpreadsheetDocument;
   //SpreadsheetDocument.PrintParametersName = "PrintParameters_SalesInvoice";

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
   |	SalesInvoice.ShipTo,
   |	SalesInvoice.Currency,
   |	SalesInvoice.LineItems.(
   |		Product,
   |		ProductDescription,
   |		LineItems.Order.RefNum AS PO,
   |		QtyUnits,
   |		Unit,
   |		QtyUM,
   |		PriceUnits,
   |		LineTotal,
   |		Project
   |	),
   |	SalesInvoice.Terms,
   |	SalesInvoice.DueDate,
   |	GeneralJournalBalance.AmountRCBalance AS Balance,
   |	SalesInvoice.BillTo,
   |	SalesInvoice.Posted,
   |	SalesInvoice.LineSubtotal,
   |	SalesInvoice.Discount,
   |	SalesInvoice.SubTotal,
   |	SalesInvoice.Shipping,
   |	SalesInvoice.DocumentTotal AS DocumentTotal1,
   |	SalesInvoice.RefNum,
   |	SalesInvoice.TrackingNumber,
   |	SalesInvoice.Carrier,
   |	SalesInvoice.DropshipCompany,
   |	SalesInvoice.DropshipShipTo
   |FROM
   |	Document.SalesInvoice AS SalesInvoice
   |		LEFT JOIN AccountingRegister.GeneralJournal.Balance AS GeneralJournalBalance
   |		ON (GeneralJournalBalance.ExtDimension1 = SalesInvoice.Company)
   |			AND (GeneralJournalBalance.ExtDimension2 = SalesInvoice.Ref)
   |WHERE
   |	SalesInvoice.Ref IN(&Ref)";
   Query.SetParameter("Ref", Ref);
   Selection = Query.Execute().Select();

   
   Spreadsheet.Clear();
   
   While Selection.Next() Do
	   
	BinaryLogo = GeneralFunctions.GetLogo();
	LogoPicture = New Picture(BinaryLogo);
	//Pict=Template.Drawings.Add(SpreadsheetDocumentDrawingType.Picture);
	//IndexOf=Template.Drawings.IndexOf(Pict);
	//Template.Drawings[IndexOf].Picture = MyPicture;
	//Template.Drawings[IndexOf].Line = New Line(SpreadsheetDocumentDrawingLineType.None);
	//Template.Drawings[IndexOf].Place(Spreadsheet.Area("R3C1:R6C2"));
	DocumentPrinting.FillLogoInDocumentTemplate(Template, LogoPicture);  
	   
	   
   //	FirstDocument = True;
   //
   //	While Selection.Next() Do
   // 	
   // 	If Not FirstDocument Then
   // 		// All documents need to be outputted on separate pages.
   // 		SpreadsheetDocument.PutHorizontalPageBreak();
   // 	EndIf;
   // 	FirstDocument = False;
   // 	// Remember current document output beginning line number.
   // 	BeginningLineNumber = SpreadsheetDocument.TableHeight + 1;

	 
	//Template = PrintManagement.GetTemplate("Document.SalesInvoice.PF_MXL_SalesInvoice");
	
	 
	TemplateArea = Template.GetArea("Header");
	  		
	UsBill = PrintTemplates.ContactInfoDatasetUs();
	ThemShip = PrintTemplates.ContactInfoDataset(Selection.Company, "ThemShip", Selection.ShipTo);	
	ThemBill = PrintTemplates.ContactInfoDataset(Selection.Company, "ThemBill", Selection.BillTo);
	
	TemplateArea.Parameters.Fill(UsBill);
	TemplateArea.Parameters.Fill(ThemShip);
	TemplateArea.Parameters.Fill(ThemBill);
	
	 TemplateArea.Parameters.Date = Selection.Date;
	 TemplateArea.Parameters.Number = Selection.Number;
	 TemplateArea.Parameters.RefNum = Selection.RefNum;
	 TemplateArea.Parameters.Carrier = Selection.Carrier;
	 TemplateArea.Parameters.TrackingNumber = Selection.TrackingNumber;
	 Try
	 	TemplateArea.Parameters.Terms = Selection.Terms;
		TemplateArea.Parameters.DueDate = Selection.DueDate;
	Except
	EndTry;
	 
	Spreadsheet.Put(TemplateArea);

	TemplateArea = Template.GetArea("LineItemsHeader");
	Spreadsheet.Put(TemplateArea);
	
	SelectionLineItems = Selection.LineItems.Select();
	TemplateArea = Template.GetArea("LineItems");
	LineTotalSum = 0;
	QuantityFormat = GeneralFunctionsReusable.DefaultQuantityFormat();
	While SelectionLineItems.Next() Do
		
		TemplateArea.Parameters.Fill(SelectionLineItems);
		
		//++ MisA 11/17/2014 ACS 1486
		//TemplateArea.Parameters.Quantity  = Format(SelectionLineItems.QtyUnits, QuantityFormat)+ " " + SelectionLineItems.Unit;
		If SplitQuantinyField Then 
			TemplateArea.Parameters.Quantity  = Format(SelectionLineItems.QtyUnits, QuantityFormat);
			TemplateArea.Parameters.Unit  = SelectionLineItems.Unit;
		Else
			TemplateArea.Parameters.Quantity  = Format(SelectionLineItems.QtyUnits, QuantityFormat)+ " " + SelectionLineItems.Unit;
		EndIf;	
		//-- MisA 11/17/2014 ACS 1486
		
		//TemplateArea.Parameters.PO = SelectionLineItems.PO;
		//LineTotal = SelectionLineItems.LineTotal;
		//LineTotalSum = LineTotalSum + LineTotal;
		Spreadsheet.Put(TemplateArea, SelectionLineItems.Level());
		
	EndDo;
	 
	Spreadsheet.PutHorizontalPageBreak();
	Spreadsheet.FitToPage  = True;

	 //////   sales tax check
	//If Selection.SalesTax <> 0 Then;
	//	 TemplateArea = Template.GetArea("Subtotal");
	//	 TemplateArea.Parameters.Subtotal = LineTotalSum;
	//	 Spreadsheet.Put(TemplateArea);
	//	 
	//	 TemplateArea = Template.GetArea("SalesTax");
	//	 TemplateArea.Parameters.SalesTaxTotal = Selection.SalesTax;
	//	 Spreadsheet.Put(TemplateArea);
	//EndIf; 
	//  ////////
	// 
	//If Selection.VATTotal <> 0 Then;
	//	 TemplateArea = Template.GetArea("Subtotal");
	//	 TemplateArea.Parameters.Subtotal = LineTotalSum;
	//	 Spreadsheet.Put(TemplateArea);
	//	 
	//	 TemplateArea = Template.GetArea("VAT");
	//	 TemplateArea.Parameters.VATTotal = Selection.VATTotal;
	//	 Spreadsheet.Put(TemplateArea);
	//EndIf; 
	//	 
	// TemplateArea = Template.GetArea("Total");
	// If Selection.PriceIncludesVAT Then
	//	 //added sales tax here
	// 	TemplateArea.Parameters.DocumentTotal = LineTotalSum + Selection.SalesTax;
	//	//
	//Else
	//	TemplateArea.Parameters.DocumentTotal = LineTotalSum + Selection.VATTotal;
	//EndIf;
	// Spreadsheet.Put(TemplateArea);
	 
	//Try
	// 	TemplateArea = Template.GetArea("Footer");
	//	OurContactInfo = UsBill.UsName + " - " + UsBill.UsBillLine1Line2 + " - " + UsBill.UsBillCityStateZIP + " - " + UsBill.UsBillPhone;
	//	TemplateArea.Parameters.OurContactInfo = OurContactInfo;
	// 	Spreadsheet.Put(TemplateArea);
	// Except
	//EndTry;


	 //TemplateArea = Template.GetArea("Currency");
	 //TemplateArea.Parameters.Currency = Selection.Currency;
	 //Spreadsheet.Put(TemplateArea);
	 
     // Setting a print area in the spreadsheet document where to output the object.
     // Necessary for kit printing.
     //PrintManagement.SetDocumentPrintArea(SpreadsheetDocument, BeginningLineNumber, PrintObjects, Selection.Ref);

	 //InsertPageBreak = True;
	 
   EndDo;
   
   //Return SpreadsheetDocument;
   
EndProcedure

Procedure PrintPackingListDropship(Spreadsheet, SheetTitle, Ref, TemplateName = Undefined) Export  
	
	SheetTitle = "Packing list (dropship)";
	CustomTemplate = GeneralFunctions.GetCustomTemplate("Document.SalesInvoice", SheetTitle);
	
	//++ Misa, 11/17/2014 ACS 1486
	SplitQuantinyField = False;
	//-- Misa 11/17/2014 ACS 1486
	
	If CustomTemplate = Undefined Then
		Template = Documents.SalesInvoice.GetTemplate("PF_MXL_PackingListDropship");
		//++ Misa, 11/17/2014 ACS 1486
		SplitQuantinyField = True;
		//-- Misa 11/17/2014 ACS 1486
	Else
		Template = CustomTemplate;
	EndIf;
	
	// Create a spreadsheet document and set print parameters.
  // SpreadsheetDocument = New SpreadsheetDocument;
   //SpreadsheetDocument.PrintParametersName = "PrintParameters_SalesInvoice";

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
   |	SalesInvoice.ShipTo,
   |	SalesInvoice.Currency,
   |	SalesInvoice.LineItems.(
   |		Product,
   |		ProductDescription,
   |		LineItems.Order.RefNum AS PO,
   |		QtyUnits,
   |		Unit,
   |		QtyUM,
   |		PriceUnits,
   |		LineTotal,
   |		Project
   |	),
   |	SalesInvoice.Terms,
   |	SalesInvoice.DueDate,
   |	GeneralJournalBalance.AmountRCBalance AS Balance,
   |	SalesInvoice.BillTo,
   |	SalesInvoice.Posted,
   |	SalesInvoice.LineSubtotal,
   |	SalesInvoice.Discount,
   |	SalesInvoice.SubTotal,
   |	SalesInvoice.Shipping,
   |	SalesInvoice.DocumentTotal AS DocumentTotal1,
   |	SalesInvoice.RefNum,
   |	SalesInvoice.TrackingNumber,
   |	SalesInvoice.Carrier,
   |	SalesInvoice.DropshipCompany,
   |	SalesInvoice.DropshipShipTo
   |FROM
   |	Document.SalesInvoice AS SalesInvoice
   |		LEFT JOIN AccountingRegister.GeneralJournal.Balance AS GeneralJournalBalance
   |		ON (GeneralJournalBalance.ExtDimension1 = SalesInvoice.Company)
   |			AND (GeneralJournalBalance.ExtDimension2 = SalesInvoice.Ref)
   |WHERE
   |	SalesInvoice.Ref IN(&Ref)";
   Query.SetParameter("Ref", Ref);
   Selection = Query.Execute().Select();

   
   Spreadsheet.Clear();
   //InsertPageBreak = False;
   While Selection.Next() Do
	   
	//BinaryLogo = GeneralFunctions.GetLogo();
	//MyPicture = New Picture(BinaryLogo);
	//Pict=Template.Drawings.Add(SpreadsheetDocumentDrawingType.Picture);
	//IndexOf=Template.Drawings.IndexOf(Pict);
	//Template.Drawings[IndexOf].Picture = MyPicture;
	//Template.Drawings[IndexOf].Line = New Line(SpreadsheetDocumentDrawingLineType.None);
	//Template.Drawings[IndexOf].Place(Spreadsheet.Area("R3C1:R6C2"));
	 
	//Template = PrintManagement.GetTemplate("Document.SalesInvoice.PF_MXL_SalesInvoice");
	 
	TemplateArea = Template.GetArea("Header");
	  		
	UsBill = PrintTemplates.ContactInfoDatasetUs();
	ThemShip = PrintTemplates.ContactInfoDataset(Selection.DropshipCompany, "ThemShip", Selection.DropshipShipTo);

	ThemBill = PrintTemplates.ContactInfoDataset(Selection.Company, "ThemBill", Selection.BillTo);
	
	TemplateArea.Parameters.Fill(UsBill);
	TemplateArea.Parameters.Fill(ThemShip);
	TemplateArea.Parameters.Fill(ThemBill);
	
	 TemplateArea.Parameters.Date = Selection.Date;
	 TemplateArea.Parameters.Number = Selection.Number;
	 TemplateArea.Parameters.RefNum = Selection.RefNum;
	 TemplateArea.Parameters.Carrier = Selection.Carrier;
	 TemplateArea.Parameters.TrackingNumber = Selection.TrackingNumber;
	 Try
	 	TemplateArea.Parameters.Terms = Selection.Terms;
		TemplateArea.Parameters.DueDate = Selection.DueDate;
	Except
	EndTry;
	 
	 	
	Spreadsheet.Put(TemplateArea);
	
	TemplateArea = Template.GetArea("LineItemsHeader");
	Spreadsheet.Put(TemplateArea);
	
	SelectionLineItems = Selection.LineItems.Select();
	TemplateArea = Template.GetArea("LineItems");
	LineTotalSum = 0;
	QuantityFormat = GeneralFunctionsReusable.DefaultQuantityFormat();
	While SelectionLineItems.Next() Do
		
		TemplateArea.Parameters.Fill(SelectionLineItems);
		//++ MisA 11/17/2014 ACS 1486
		//TemplateArea.Parameters.Quantity  = Format(SelectionLineItems.QtyUnits, QuantityFormat)+ " " + SelectionLineItems.Unit;
		If SplitQuantinyField Then 
			TemplateArea.Parameters.Quantity  = Format(SelectionLineItems.QtyUnits, QuantityFormat);
			TemplateArea.Parameters.Unit  = SelectionLineItems.Unit;
		Else
			TemplateArea.Parameters.Quantity  = Format(SelectionLineItems.QtyUnits, QuantityFormat)+ " " + SelectionLineItems.Unit;
		EndIf;	
		//-- MisA 11/17/2014 ACS 1486
		Spreadsheet.Put(TemplateArea, SelectionLineItems.Level());
		
	EndDo;
	 
	Spreadsheet.PutHorizontalPageBreak();
    Spreadsheet.FitToPage  = True;

	EndDo;
   
   
EndProcedure
// <- CODE REVIEW

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
	|	CASE
	|       WHEN LineItems.Shipment <> VALUE(Document.Shipment.EmptyRef)
	|			THEN LineItems.Shipment
	|		ELSE LineItems.Order 
	|	END                                   AS Order,
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
	|	AND LineItems.Order <> VALUE(Document.SalesOrder.EmptyRef)
	|ORDER BY
	|	Order";
	
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
	|	Document.SalesInvoice.LineItems AS LineItems
	|WHERE
	|	    LineItems.Ref = &Ref
	|	AND LineItems.Product        <> VALUE(Catalog.Products.EmptyRef)
	|	AND LineItems.Product.HasLotsSerialNumbers
	|	AND LineItems.Product.UseLots = 0
	|	AND LineItems.LocationActual <> VALUE(Catalog.Locations.EmptyRef)
	|	AND LineItems.Lot            <> VALUE(Catalog.Lots.EmptyRef)
	|	AND LineItems.Shipment        = VALUE(Document.Shipment.EmptyRef)
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
	|	Document.SalesInvoice.SerialNumbers AS SerialNumbers
	|	LEFT JOIN Document.SalesInvoice.LineItems AS LineItems
	|		ON  LineItems.Ref         = SerialNumbers.Ref
	|		AND LineItems.LineID      = SerialNumbers.LineItemsLineID
	|		AND LineItems.Shipment    = VALUE(Document.Shipment.EmptyRef)
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
	|	Document.SalesInvoice.LineItems AS LineItems
	|WHERE
	|	    LineItems.Ref                   = &Ref
	|   AND LineItems.Shipment              = VALUE(Document.Shipment.EmptyRef)
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
	|	Document.SalesInvoice.LineItems AS LineItems
	|WHERE
	|	    LineItems.Ref                   = &Ref
	|   AND LineItems.Shipment              = VALUE(Document.Shipment.EmptyRef)
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
	|	Document.SalesInvoice.LineItems AS LineItems
	|WHERE
	|	    LineItems.Ref                   = &Ref
	|   AND LineItems.Shipment              = VALUE(Document.Shipment.EmptyRef)
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
	|	SalesInvoice.Ref                      AS Recorder,
	|	SalesInvoice.Date                     AS Period,
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
	|	LEFT JOIN Document.SalesInvoice AS SalesInvoice
	|		ON True
	|WHERE
	|	SalesInvoice.Ref = &Ref
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
	|	SalesInvoice.Ref                      AS Recorder,
	|	SalesInvoice.Date                     AS Period,
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
	|	LEFT JOIN Document.SalesInvoice AS SalesInvoice
	|		ON True
	|WHERE
	|	SalesInvoice.Ref = &Ref
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
	|	SalesInvoice.Ref                      AS Recorder,
	|	SalesInvoice.Date                     AS Period,
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
	|	LEFT JOIN Document.SalesInvoice AS SalesInvoice
	|		ON True
	|WHERE
	|	SalesInvoice.Ref = &Ref
	|	AND LineItems_WAve.Type      = VALUE(Enum.InventoryCosting.WeightedAverage)
	|	AND LineItems_WAve.Location <> VALUE(Catalog.Locations.EmptyRef)
	|	AND LineItems_WAve.QuantityRequested > 0
	|
	|UNION ALL
	|
	|SELECT // WeightedAverage by amount
	// ------------------------------------------------------
	// Standard attributes
	|	SalesInvoice.Ref                      AS Recorder,
	|	SalesInvoice.Date                     AS Period,
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
	|	LEFT JOIN Document.SalesInvoice AS SalesInvoice
	|		ON True
	|WHERE
	|	SalesInvoice.Ref = &Ref
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
	|	LineItems.Product.CostingMethod       		AS Type,
	|	LineItems.Product                     		AS Product,
	|	LineItems.LocationActual             		AS Location,
	|	LineItems.Product.IncomeAccount       		AS IncomeAccount,
	|	LineItems.Product.COGSAccount         		AS COGSAccount,
	|	LineItems.Product.InventoryOrExpenseAccount AS InvOrExpAccount,
	|	LineItems.Class                       		AS Class,
	|	LineItems.Project                     		AS Project,
	|	CASE WHEN LineItems.Shipment <> VALUE(Document.Shipment.EmptyRef)
	|        THEN TRUE
	|        ELSE FALSE END                         AS HasShipment,
	|			
	// ------------------------------------------------------
	// Resources
	|	LineItems.QtyUM                       		AS Quantity,
	|	LineItems.LineTotal                   		AS Amount
	// ------------------------------------------------------
	|INTO
	|	Table_GeneralJournal_LineItems
	|FROM
	|	Document.SalesInvoice.LineItems AS LineItems
	|WHERE
	|	LineItems.Ref = &Ref";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_GeneralJournal_Accounts_Income(TablesList)
	
	// Add GeneralJournal income accounts table to document structure.
	TablesList.Insert("Table_GeneralJournal_Accounts_Income", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // Income accounts selection
	// ------------------------------------------------------
	// Dimensions
	|	Accounts.IncomeAccount                AS IncomeAccount,
	// ------------------------------------------------------
	// Resources
	|	SUM(Accounts.Amount)                  AS Amount
	// ------------------------------------------------------
	|INTO
	|	Table_GeneralJournal_Accounts_Income
	|FROM
	|	Table_GeneralJournal_LineItems AS Accounts
	|GROUP BY
	|	Accounts.IncomeAccount";
	
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
	|WHERE
	|	Accounts.HasShipment = FALSE
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
	|WHERE
	|	Accounts.HasShipment = FALSE
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
	"SELECT // Dr: Accounts receivable
	// ------------------------------------------------------
	// Standard attributes
	|	SalesInvoice.Ref                      AS Recorder,
	|	SalesInvoice.Date                     AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccountingRecordType.Debit)     AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Accounting attributes
	|	SalesInvoice.ARAccount                AS Account,
	|	VALUE(ChartOfCharacteristicTypes.Dimensions.Company)
	|	                                      AS ExtDimensionType1,
	|	SalesInvoice.Company                  AS ExtDimension1,
	|	VALUE(ChartOfCharacteristicTypes.Dimensions.Document)
	|	                                      AS ExtDimensionType2,
	|	SalesInvoice.Ref                      AS ExtDimension2,
	// ------------------------------------------------------
	// Dimensions
	|	SalesInvoice.Currency                 AS Currency,
	// ------------------------------------------------------
	// Resources
	|	SalesInvoice.DocumentTotal            AS Amount,
	|	SalesInvoice.DocumentTotalRC          AS AmountRC,
	// ------------------------------------------------------
	// Attributes
	|	Null                                  AS Memo
	// ------------------------------------------------------
	|FROM
	|	Document.SalesInvoice AS SalesInvoice
	|WHERE
	|	SalesInvoice.Ref = &Ref
	|	AND // Amount > 0
	|		(SalesInvoice.DocumentTotal > 0
	|	  OR SalesInvoice.DocumentTotalRC > 0)
	|
	|UNION ALL
	|
	|SELECT // Dr: Discount
	// ------------------------------------------------------
	// Standard attributes
	|	SalesInvoice.Ref                      AS Recorder,
	|	SalesInvoice.Date                     AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccountingRecordType.Debit)     AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Accounting attributes
	|	CASE
	|		WHEN ISNULL(Constants.DiscountsAccount, VALUE(ChartOfAccounts.ChartOfAccounts.EmptyRef)) = VALUE(ChartOfAccounts.ChartOfAccounts.EmptyRef)
	|		THEN Constants.ExpenseAccount     // Default expense account
	|		ELSE Constants.DiscountsAccount   // Default discount account
	|	END                                   AS Account,
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
	|	CAST( // Format(-Discount * ExchangeRate, ""ND=17; NFD=2"")
	|		-SalesInvoice.Discount *
	|		 CASE WHEN SalesInvoice.ExchangeRate > 0
	|			  THEN SalesInvoice.ExchangeRate
	|			  ELSE 1 END
	|		 AS NUMBER (17, 2))               AS AmountRC,
	// ------------------------------------------------------
	// Attributes
	|	NULL                                  AS Memo
	// ------------------------------------------------------
	|FROM
	|	Document.SalesInvoice AS SalesInvoice
	|	LEFT JOIN Constants AS Constants
	|		ON True
	|WHERE
	|	SalesInvoice.Ref = &Ref
	|	AND // Discount > 0
	|		-SalesInvoice.Discount > 0
	|
	|UNION ALL
	|
	|SELECT // Cr: Shipping
	// ------------------------------------------------------
	// Standard attributes
	|	SalesInvoice.Ref                      AS Recorder,
	|	SalesInvoice.Date                     AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccountingRecordType.Credit)    AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Accounting attributes
	|	CASE
	|		WHEN ISNULL(Constants.ShippingExpenseAccount, VALUE(ChartOfAccounts.ChartOfAccounts.EmptyRef)) = VALUE(ChartOfAccounts.ChartOfAccounts.EmptyRef)
	|		THEN Constants.IncomeAccount           // Default income account
	|		ELSE Constants.ShippingExpenseAccount  // Default shipping expense account
	|	END                                   AS Account,
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
	|	CAST( // Format(Shipping * ExchangeRate, ""ND=17; NFD=2"")
	|		SalesInvoice.Shipping *
	|		CASE WHEN SalesInvoice.ExchangeRate > 0
	|			 THEN SalesInvoice.ExchangeRate
	|			 ELSE 1 END
	|		AS NUMBER (17, 2))                AS AmountRC,
	// ------------------------------------------------------
	// Attributes
	|	NULL                                  AS Memo
	// ------------------------------------------------------
	|FROM
	|	Document.SalesInvoice AS SalesInvoice
	|	LEFT JOIN Constants AS Constants
	|		ON True
	|WHERE
	|	SalesInvoice.Ref = &Ref
	|	AND // Shipping > 0
	|		SalesInvoice.Shipping > 0
	|
	|UNION ALL
	|
	|SELECT // Cr: Sales tax
	// ------------------------------------------------------
	// Standard attributes
	|	SalesInvoice.Ref                      AS Recorder,
	|	SalesInvoice.Date                     AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccountingRecordType.Credit)    AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Accounting attributes
	|	CASE
	|		WHEN ISNULL(Constants.TaxPayableAccount, VALUE(ChartOfAccounts.ChartOfAccounts.EmptyRef)) = VALUE(ChartOfAccounts.ChartOfAccounts.EmptyRef)
	|		THEN Constants.IncomeAccount      // Default income account
	|		ELSE Constants.TaxPayableAccount  // Default tax payable account
	|	END                                   AS Account,
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
	|	CAST( // Format(SalesTax * ExchangeRate, ""ND=17; NFD=2"")
	|		SalesInvoice.SalesTax *
	|		CASE WHEN SalesInvoice.ExchangeRate > 0
	|			 THEN SalesInvoice.ExchangeRate
	|			 ELSE 1 END
	|		AS NUMBER (17, 2))                AS AmountRC,
	// ------------------------------------------------------
	// Attributes
	|	NULL                                  AS Memo
	// ------------------------------------------------------
	|FROM
	|	Document.SalesInvoice AS SalesInvoice
	|	LEFT JOIN Constants AS Constants
	|		ON True
	|WHERE
	|	SalesInvoice.Ref = &Ref
	|	AND // SalesTax > 0
	|		SalesInvoice.SalesTax > 0
	|
	|UNION ALL
	|
	|SELECT // Cr: Income
	// ------------------------------------------------------
	// Standard attributes
	|	SalesInvoice.Ref                      AS Recorder,
	|	SalesInvoice.Date                     AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccountingRecordType.Credit)    AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Accounting attributes
	|	Income.IncomeAccount                  AS Account,
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
	|		Income.Amount *
	|		CASE WHEN SalesInvoice.ExchangeRate > 0
	|			 THEN SalesInvoice.ExchangeRate
	|			 ELSE 1 END
	|		AS NUMBER (17, 2))                AS AmountRC,
	// ------------------------------------------------------
	// Attributes
	|	NULL                                  AS Memo
	// ------------------------------------------------------
	|FROM
	|	Table_GeneralJournal_Accounts_Income AS Income
	|	LEFT JOIN Document.SalesInvoice AS SalesInvoice
	|		ON True
	|WHERE
	|	SalesInvoice.Ref = &Ref
	|	AND // Amount > 0
	|		Income.Amount > 0
	|
	|UNION ALL
	|
	|SELECT // Dr: COGS
	// ------------------------------------------------------
	// Standard attributes
	|	SalesInvoice.Ref                      AS Recorder,
	|	SalesInvoice.Date                     AS Period,
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
	|	LEFT JOIN Document.SalesInvoice AS SalesInvoice
	|		ON True
	|WHERE
	|	SalesInvoice.Ref = &Ref
	|	AND // Amount > 0
	|		COGS.Amount > 0
	|
	|UNION ALL
	|
	|SELECT // Cr: Inventory or Expenses accounts
	// ------------------------------------------------------
	// Standard attributes
	|	SalesInvoice.Ref                      AS Recorder,
	|	SalesInvoice.Date                     AS Period,
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
	|	LEFT JOIN Document.SalesInvoice AS SalesInvoice
	|		ON True
	|WHERE
	|	SalesInvoice.Ref = &Ref
	|	AND // Amount > 0
	|		InvOrExp.Amount > 0";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

//--//GJ++

// Query for document data.
Function Query_GeneralJournalAnalyticsDimensions_Accounts_Income(TablesList)
	
	// Add GeneralJournalAnalyticsDimensions income accounts table to document structure.
	TablesList.Insert("Table_GeneralJournalAnalyticsDimensions_Accounts_Income", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // Income Dimensions accounts selection
	// ------------------------------------------------------
	// Dimensions
	|	Accounts.IncomeAccount                AS IncomeAccount,
	|	Accounts.Class                        AS Class,
	|	Accounts.Project                      AS Project,
	// ------------------------------------------------------
	// Resources
	|	SUM(Accounts.Amount)                  AS Amount
	// ------------------------------------------------------
	|INTO
	|	Table_GeneralJournalAnalyticsDimensions_Accounts_Income
	|FROM
	|	Table_GeneralJournal_LineItems AS Accounts
	|GROUP BY
	|	Accounts.IncomeAccount,
	|	Accounts.Class,
	|	Accounts.Project";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_GeneralJournalAnalyticsDimensions_Accounts_Income_Difference_Amount(TablesList)
	
	// Add GeneralJournalAnalyticsDimensions difference amount table to document structure.
	TablesList.Insert("Table_GeneralJournalAnalyticsDimensions_Accounts_Income_Difference_Amount", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // Income accounts selection
	// ------------------------------------------------------
	// Dimensions
	|	IncomeDimensions.IncomeAccount        AS IncomeAccount,
	// ------------------------------------------------------
	// Resources
	|	CAST( // Format(Amount * ExchangeRate, ""ND=17; NFD=2"")
	|		IncomeDimensions.Amount *
	|		CASE WHEN SalesInvoice.ExchangeRate > 0
	|			 THEN SalesInvoice.ExchangeRate
	|			 ELSE 1 END
	|		AS NUMBER (17, 2))                AS Amount
	// ------------------------------------------------------
	|INTO
	|	Table_GeneralJournalAnalyticsDimensions_Accounts_Income_Difference_Amount
	|FROM
	|	Table_GeneralJournal_Accounts_Income AS IncomeDimensions
	|	LEFT JOIN Document.SalesInvoice AS SalesInvoice
	|		ON True
	|WHERE
	|	SalesInvoice.Ref = &Ref
	|	AND // Amount > 0
	|		IncomeDimensions.Amount > 0
	|
	|UNION ALL
	|
	|SELECT // Income Dimensions accounts selection
	// ------------------------------------------------------
	// Dimensions
	|	IncomeDimensions.IncomeAccount        AS IncomeAccount,
	// ------------------------------------------------------
	// Resources
	|	CAST( // Format(Amount * ExchangeRate, ""ND=17; NFD=2"")
	|		IncomeDimensions.Amount *
	|		CASE WHEN SalesInvoice.ExchangeRate > 0
	|			 THEN SalesInvoice.ExchangeRate
	|			 ELSE 1 END
	|		AS NUMBER (17, 2)) * -1           AS Amount
	// ------------------------------------------------------
	|FROM
	|	Table_GeneralJournalAnalyticsDimensions_Accounts_Income AS IncomeDimensions
	|	LEFT JOIN Document.SalesInvoice AS SalesInvoice
	|		ON True
	|WHERE
	|	SalesInvoice.Ref = &Ref
	|	AND // Amount > 0
	|		IncomeDimensions.Amount > 0";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_GeneralJournalAnalyticsDimensions_Accounts_Income_Difference(TablesList)
	
	// Add GeneralJournalAnalyticsDimensions difference table to document structure.
	TablesList.Insert("Table_GeneralJournalAnalyticsDimensions_Accounts_Income_Difference", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // Dimensions difference selection
	// ------------------------------------------------------
	// Dimensions
	|	DimensionsDifference.IncomeAccount         AS IncomeAccount,
	// ------------------------------------------------------
	// Resources
	|	SUM(DimensionsDifference.Amount)           AS Amount
	// ------------------------------------------------------
	|INTO
	|	Table_GeneralJournalAnalyticsDimensions_Accounts_Income_Difference
	|FROM
	|	Table_GeneralJournalAnalyticsDimensions_Accounts_Income_Difference_Amount AS DimensionsDifference
	|GROUP BY
	|	DimensionsDifference.IncomeAccount";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

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
	|WHERE
	|	Accounts.HasShipment = FALSE
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
	|	LEFT JOIN Document.SalesInvoice AS SalesInvoice
	|		ON True
	|WHERE
	|	SalesInvoice.Ref = &Ref
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
	|	LEFT JOIN Document.SalesInvoice AS SalesInvoice
	|		ON True
	|WHERE
	|	SalesInvoice.Ref = &Ref
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
	|   Accounts.Class                        AS Class,
	|   Accounts.Project                      AS Project,
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
	|WHERE
	|	Accounts.HasShipment = FALSE
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
	|   Accounts.Class,
	|   Accounts.Project";
	
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
	|	LEFT JOIN Document.SalesInvoice AS SalesInvoice
	|		ON True
	|WHERE
	|	SalesInvoice.Ref = &Ref
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
	|	LEFT JOIN Document.SalesInvoice AS SalesInvoice
	|		ON True
	|WHERE
	|	SalesInvoice.Ref = &Ref
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
	"SELECT // Receipt: Accounts receivable
	// ------------------------------------------------------
	// Standard attributes
	|	SalesInvoice.Ref                      AS Recorder,
	|	SalesInvoice.Date                     AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Accounting attributes
	|	SalesInvoice.ARAccount                AS Account,
	// ------------------------------------------------------
	// Dimensions
	|	SalesInvoice.Company                  AS Company,
	|	NULL                                  AS Class,
	|	NULL                                  AS Project,
	// ------------------------------------------------------
	// Resources
	|	SalesInvoice.DocumentTotalRC          AS AmountRC,
	// ------------------------------------------------------
	// Attributes
	|	1                                     AS JournalEntryIntNum,
	|	True                                  AS JournalEntryMainRec
	// ------------------------------------------------------
	|INTO Table_GeneralJournalAnalyticsDimensions_Transactions
	|FROM
	|	Document.SalesInvoice AS SalesInvoice
	|WHERE
	|	SalesInvoice.Ref = &Ref
	|	AND // Amount > 0
	|		(SalesInvoice.DocumentTotal > 0
	|	  OR SalesInvoice.DocumentTotalRC > 0)
	|
	|UNION ALL
	|
	|SELECT // Receipt: Discount
	// ------------------------------------------------------
	// Standard attributes
	|	SalesInvoice.Ref                      AS Recorder,
	|	SalesInvoice.Date                     AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Accounting attributes
	|	CASE
	|		WHEN ISNULL(Constants.DiscountsAccount, VALUE(ChartOfAccounts.ChartOfAccounts.EmptyRef)) = VALUE(ChartOfAccounts.ChartOfAccounts.EmptyRef)
	|		THEN Constants.ExpenseAccount     // Default expense account
	|		ELSE Constants.DiscountsAccount   // Default discount account
	|	END                                   AS Account,
	// ------------------------------------------------------
	// Dimensions
	|	SalesInvoice.Company                  AS Company,
	|	NULL                                  AS Class,
	|	NULL                                  AS Project,
	// ------------------------------------------------------
	// Resources
	|	CAST( // Format(-Discount * ExchangeRate, ""ND=17; NFD=2"")
	|		-SalesInvoice.Discount *
	|		 CASE WHEN SalesInvoice.ExchangeRate > 0
	|			  THEN SalesInvoice.ExchangeRate
	|			  ELSE 1 END
	|		 AS NUMBER (17, 2))               AS AmountRC,
	// ------------------------------------------------------
	// Attributes
	|	1                                     AS JournalEntryIntNum,
	|	False                                 AS JournalEntryMainRec
	// ------------------------------------------------------
	|FROM
	|	Document.SalesInvoice AS SalesInvoice
	|	LEFT JOIN Constants AS Constants
	|		ON True
	|WHERE
	|	SalesInvoice.Ref = &Ref
	|	AND // Discount > 0
	|		-SalesInvoice.Discount > 0
	|
	|UNION ALL
	|
	|SELECT // Expense: Shipping
	// ------------------------------------------------------
	// Standard attributes
	|	SalesInvoice.Ref                      AS Recorder,
	|	SalesInvoice.Date                     AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Accounting attributes
	|	CASE
	|		WHEN ISNULL(Constants.ShippingExpenseAccount, VALUE(ChartOfAccounts.ChartOfAccounts.EmptyRef)) = VALUE(ChartOfAccounts.ChartOfAccounts.EmptyRef)
	|		THEN Constants.IncomeAccount           // Default income account
	|		ELSE Constants.ShippingExpenseAccount  // Default shipping expense account
	|	END                                   AS Account,
	// ------------------------------------------------------
	// Dimensions
	|	SalesInvoice.Company                  AS Company,
	|	NULL                                  AS Class,
	|	NULL                                  AS Project,
	// ------------------------------------------------------
	// Resources
	|	CAST( // Format(Shipping * ExchangeRate, ""ND=17; NFD=2"")
	|		SalesInvoice.Shipping *
	|		CASE WHEN SalesInvoice.ExchangeRate > 0
	|			 THEN SalesInvoice.ExchangeRate
	|			 ELSE 1 END
	|		AS NUMBER (17, 2))                AS AmountRC,
	// ------------------------------------------------------
	// Attributes
	|	1                                     AS JournalEntryIntNum,
	|	False                                 AS JournalEntryMainRec
	// ------------------------------------------------------
	|FROM
	|	Document.SalesInvoice AS SalesInvoice
	|	LEFT JOIN Constants AS Constants
	|		ON True
	|WHERE
	|	SalesInvoice.Ref = &Ref
	|	AND // Shipping > 0
	|		SalesInvoice.Shipping > 0
	|
	|UNION ALL
	|
	|SELECT // Expense: Sales tax
	// ------------------------------------------------------
	// Standard attributes
	|	SalesInvoice.Ref                      AS Recorder,
	|	SalesInvoice.Date                     AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Accounting attributes
	|	CASE
	|		WHEN ISNULL(Constants.TaxPayableAccount, VALUE(ChartOfAccounts.ChartOfAccounts.EmptyRef)) = VALUE(ChartOfAccounts.ChartOfAccounts.EmptyRef)
	|		THEN Constants.IncomeAccount      // Default income account
	|		ELSE Constants.TaxPayableAccount  // Default tax payable account
	|	END                                   AS Account,
	// ------------------------------------------------------
	// Dimensions
	|	SalesInvoice.Company                  AS Company,
	|	NULL                                  AS Class,
	|	NULL                                  AS Project,
	// ------------------------------------------------------
	// Resources
	|	CAST( // Format(SalesTax * ExchangeRate, ""ND=17; NFD=2"")
	|		SalesInvoice.SalesTax *
	|		CASE WHEN SalesInvoice.ExchangeRate > 0
	|			 THEN SalesInvoice.ExchangeRate
	|			 ELSE 1 END
	|		AS NUMBER (17, 2))                AS AmountRC,
	// ------------------------------------------------------
	// Attributes
	|	1                                     AS JournalEntryIntNum,
	|	False                                 AS JournalEntryMainRec
	// ------------------------------------------------------
	|FROM
	|	Document.SalesInvoice AS SalesInvoice
	|	LEFT JOIN Constants AS Constants
	|		ON True
	|WHERE
	|	SalesInvoice.Ref = &Ref
	|	AND // SalesTax > 0
	|		SalesInvoice.SalesTax > 0
	|
	|UNION ALL
	|
	|SELECT // Expense: Income
	// ------------------------------------------------------
	// Standard attributes
	|	SalesInvoice.Ref                      AS Recorder,
	|	SalesInvoice.Date                     AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Accounting attributes
	|	Income.IncomeAccount                  AS Account,
	// ------------------------------------------------------
	// Dimensions
	|	SalesInvoice.Company                  AS Company,
	|	Income.Class                          AS Class,
	|	Income.Project                        AS Project,
	// ------------------------------------------------------
	// Resources
	|	CAST( // Format(Amount * ExchangeRate, ""ND=17; NFD=2"")
	|		Income.Amount *
	|		CASE WHEN SalesInvoice.ExchangeRate > 0
	|			 THEN SalesInvoice.ExchangeRate
	|			 ELSE 1 END
	|		AS NUMBER (17, 2))                AS AmountRC,
	// ------------------------------------------------------
	// Attributes
	|	1                                     AS JournalEntryIntNum,
	|	False                                 AS JournalEntryMainRec
	// ------------------------------------------------------
	|FROM
	|	Table_GeneralJournalAnalyticsDimensions_Accounts_Income	AS Income
	|	LEFT JOIN Document.SalesInvoice AS SalesInvoice
	|		ON True
	|WHERE
	|	SalesInvoice.Ref = &Ref
	|	AND // Amount > 0
	|		Income.Amount > 0
	|
	|UNION ALL
	|
	|SELECT // Expense: Income (difference)
	// ------------------------------------------------------
	// Standard attributes
	|	SalesInvoice.Ref                      AS Recorder,
	|	SalesInvoice.Date                     AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Accounting attributes
	|	Income.IncomeAccount                  AS Account,
	// ------------------------------------------------------
	// Dimensions
	|	SalesInvoice.Company                  AS Company,
	|	NULL                                  AS Class,
	|	NULL                                  AS Project,
	// ------------------------------------------------------
	// Resources
	|	Income.Amount                         AS AmountRC,
	// ------------------------------------------------------
	// Attributes
	|	1                                     AS JournalEntryIntNum,
	|	False                                 AS JournalEntryMainRec
	// ------------------------------------------------------
	|FROM
	|	Table_GeneralJournalAnalyticsDimensions_Accounts_Income_Difference	AS Income
	|	LEFT JOIN Document.SalesInvoice AS SalesInvoice
	|		ON True
	|WHERE
	|	SalesInvoice.Ref = &Ref
	|	AND // Amount <> 0
	|		Income.Amount <> 0
	|
	|UNION ALL
	|
	|SELECT // Receipt: COGS
	// ------------------------------------------------------
	// Standard attributes
	|	SalesInvoice.Ref                      AS Recorder,
	|	SalesInvoice.Date                     AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Accounting attributes
	|	COGS.COGSAccount                      AS Account,
	// ------------------------------------------------------
	// Dimensions
	|	SalesInvoice.Company                  AS Company,
	|	COGS.Class                            AS Class,
	|	COGS.Project                          AS Project,
	// ------------------------------------------------------
	// Resources
	|	COGS.Amount                           AS AmountRC,
	// ------------------------------------------------------
	// Attributes
	|	2                                     AS JournalEntryIntNum,
	|	True                                  AS JournalEntryMainRec
	// ------------------------------------------------------
	|FROM
	|	Table_GeneralJournalAnalyticsDimensions_Accounts_COGS AS COGS
	|	LEFT JOIN Document.SalesInvoice AS SalesInvoice
	|		ON True
	|WHERE
	|	SalesInvoice.Ref = &Ref
	|	AND // Amount > 0
	|		COGS.Amount > 0
	|
	|UNION ALL
	|
	|SELECT // Receipt: COGS (difference)
	// ------------------------------------------------------
	// Standard attributes
	|	SalesInvoice.Ref                      AS Recorder,
	|	SalesInvoice.Date                     AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Accounting attributes
	|	COGS.COGSAccount                      AS Account,
	// ------------------------------------------------------
	// Dimensions
	|	SalesInvoice.Company                  AS Company,
	|	NULL                                  AS Class,
	|	NULL                                  AS Project,
	// ------------------------------------------------------
	// Resources
	|	COGS.Amount                           AS AmountRC,
	// ------------------------------------------------------
	// Attributes
	|	2                                     AS JournalEntryIntNum,
	|	True                                  AS JournalEntryMainRec
	// ------------------------------------------------------
	|FROM
	|	Table_GeneralJournalAnalyticsDimensions_Accounts_COGS_Difference AS COGS
	|	LEFT JOIN Document.SalesInvoice AS SalesInvoice
	|		ON True
	|WHERE
	|	SalesInvoice.Ref = &Ref
	|	AND // Amount <> 0
	|		COGS.Amount <> 0
	|
	|UNION ALL
	|
	|SELECT // Expense: Inventory or Expenses accounts
	// ------------------------------------------------------
	// Standard attributes
	|	SalesInvoice.Ref                      AS Recorder,
	|	SalesInvoice.Date                     AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Accounting attributes
	|	InvOrExp.InvOrExpAccount              AS Account,
	// ------------------------------------------------------
	// Dimensions
	|	SalesInvoice.Company                  AS Company,
	|	InvOrExp.Class                        AS Class,
	|	InvOrExp.Project                      AS Project,
	// ------------------------------------------------------
	// Resources
	|	InvOrExp.Amount                       AS AmountRC,
	// ------------------------------------------------------
	// Attributes
	|	2                                     AS JournalEntryIntNum,
	|	False                                 AS JournalEntryMainRec
	// ------------------------------------------------------
	|FROM
	|	Table_GeneralJournalAnalyticsDimensions_Accounts_InvOrExp AS InvOrExp
	|	LEFT JOIN Document.SalesInvoice AS SalesInvoice
	|		ON True
	|WHERE
	|	SalesInvoice.Ref = &Ref
	|	AND // Amount > 0
	|		InvOrExp.Amount > 0
	|
	|UNION ALL
	|
	|SELECT // Expense: Inventory or Expenses accounts (difference)
	// ------------------------------------------------------
	// Standard attributes
	|	SalesInvoice.Ref                      AS Recorder,
	|	SalesInvoice.Date                     AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Accounting attributes
	|	InvOrExp.InvOrExpAccount              AS Account,
	// ------------------------------------------------------
	// Dimensions
	|	SalesInvoice.Company                  AS Company,
	|	NULL                                  AS Class,
	|	NULL                                  AS Project,
	// ------------------------------------------------------
	// Resources
	|	InvOrExp.Amount                       AS AmountRC,
	// ------------------------------------------------------
	// Attributes
	|	2                                     AS JournalEntryIntNum,
	|	False                                 AS JournalEntryMainRec
	// ------------------------------------------------------
	|FROM
	|	Table_GeneralJournalAnalyticsDimensions_Accounts_InvOrExp_Difference AS InvOrExp
	|	LEFT JOIN Document.SalesInvoice AS SalesInvoice
	|		ON True
	|WHERE
	|	SalesInvoice.Ref = &Ref
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
Function Query_CashFlowData_Difference_Amount(TablesList)
	
	// Add CashFlowData_Difference_Amount table to document structure.
	TablesList.Insert("Table_CashFlowData_Difference_Amount", TablesList.Count());
	
	// Collect cash flow data.
	QueryText =
	"SELECT // Difference amount
	// ------------------------------------------------------
	// Resources
	|	CASE
	|		WHEN Transaction.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN Transaction.AmountRC                   
	|		ELSE Transaction.AmountRC * -1
	|	END                                                  AS AmountRC
	// ------------------------------------------------------
	|INTO Table_CashFlowData_Difference_Amount
	|FROM
	|	Table_GeneralJournalAnalyticsDimensions_Transactions AS Transaction
	|	LEFT JOIN Constant.TaxPayableAccount AS TaxPayableAccount
	|		ON True
	|WHERE
	|	Transaction.Account.AccountType <> VALUE(Enum.AccountTypes.AccountsReceivable)
	|	AND Transaction.Account.AccountType <> VALUE(Enum.AccountTypes.AccountsPayable)
	|	AND Transaction.Account.AccountType <> VALUE(Enum.AccountTypes.Income)
	|	AND Transaction.Account.AccountType <> VALUE(Enum.AccountTypes.CostOfSales)
	|	AND Transaction.Account.AccountType <> VALUE(Enum.AccountTypes.Expense)
	|	AND Transaction.Account.AccountType <> VALUE(Enum.AccountTypes.OtherIncome)
	|	AND Transaction.Account.AccountType <> VALUE(Enum.AccountTypes.OtherExpense)
	|	AND Transaction.Account.AccountType <> VALUE(Enum.AccountTypes.IncomeTaxExpense)
	|	AND Transaction.Account <> TaxPayableAccount.Value";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_CashFlowData_Difference(TablesList)
	
	// Add CashFlowData_Difference table to document structure.
	TablesList.Insert("Table_CashFlowData_Difference", TablesList.Count());
	
	// Collect cash flow data.
	QueryText =
	"SELECT // Difference
	// ------------------------------------------------------
	// Resources
	|	SUM(Transaction.AmountRC)            AS AmountRC
	// ------------------------------------------------------
	|INTO Table_CashFlowData_Difference
	|FROM
	|	Table_CashFlowData_Difference_Amount AS Transaction";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_CashFlowData(TablesList)
	
	// Add CashFlowData table to document structure.
	TablesList.Insert("Table_CashFlowData", TablesList.Count());
	
	// Collect cash flow data.
	QueryText =
	"SELECT // Transactions of Assets
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
	|	SalesInvoice.Ref                      AS Document,
	|	SalesInvoice.SalesPerson              AS SalesPerson,
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
	|	LEFT JOIN Document.SalesInvoice AS SalesInvoice
	|		ON SalesInvoice.Ref = &Ref
	|	LEFT JOIN Constant.TaxPayableAccount AS TaxPayableAccount
	|		ON True
	|WHERE
	|	Transaction.Account.AccountType <> VALUE(Enum.AccountTypes.AccountsReceivable)
	|	AND Transaction.Account.AccountType <> VALUE(Enum.AccountTypes.AccountsPayable)
	|	AND Transaction.Account.AccountType <> VALUE(Enum.AccountTypes.Income)
	|	AND Transaction.Account.AccountType <> VALUE(Enum.AccountTypes.CostOfSales)
	|	AND Transaction.Account.AccountType <> VALUE(Enum.AccountTypes.Expense)
	|	AND Transaction.Account.AccountType <> VALUE(Enum.AccountTypes.OtherIncome)
	|	AND Transaction.Account.AccountType <> VALUE(Enum.AccountTypes.OtherExpense)
	|	AND Transaction.Account.AccountType <> VALUE(Enum.AccountTypes.IncomeTaxExpense)
	|	AND Transaction.Account <> TaxPayableAccount.Value
	|
	|UNION ALL
	|
	|SELECT // Accounts Receivable (difference)
	// ------------------------------------------------------
	// Standard attributes
	|	SalesInvoice.Ref                      AS Recorder,
	|	SalesInvoice.Date                     AS Period,
	|	0                                     AS LineNumber,
	|	CASE
	|		WHEN TransactionAR.AmountRC > 0
	|			THEN VALUE(AccumulationRecordType.Expense)
	|		ELSE VALUE(AccumulationRecordType.Receipt)
	|	END                                   AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Accounting attributes
	|	SalesInvoice.ARAccount                AS Account,
	// ------------------------------------------------------
	// Dimensions
	|	SalesInvoice.Company                  AS Company,
	|	SalesInvoice.Ref                      AS Document,
	|	SalesInvoice.SalesPerson              AS SalesPerson,
	|	NULL                                  AS Class,
	|	NULL                                  AS Project,
	// ------------------------------------------------------
	// Resources
	|	CASE
	|		WHEN TransactionAR.AmountRC > 0
	|			THEN TransactionAR.AmountRC                
	|		ELSE TransactionAR.AmountRC * -1
	|	END                                   AS AmountRC,
	// ------------------------------------------------------
	// Attributes
	|	NULL                                  AS PaymentMethod
	// ------------------------------------------------------
	|FROM
	|	Table_CashFlowData_Difference AS TransactionAR
	|	LEFT JOIN Document.SalesInvoice AS SalesInvoice
	|		ON SalesInvoice.Ref = &Ref
	|WHERE
	|	TransactionAR.AmountRC <> 0";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction


// Query for document data.
Function Query_ProjectData_Accounts_Income(TablesList)
	
	// Add ProjectData income accounts table to document structure.
	TablesList.Insert("Table_ProjectData_Accounts_Income", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // Income accounts selection
	// ------------------------------------------------------
	// Dimensions
	|	Accounts.IncomeAccount                AS IncomeAccount,
	|	Accounts.Project                      AS Project,
	// ------------------------------------------------------
	// Resources
	|	SUM(Accounts.Amount)                  AS Amount
	// ------------------------------------------------------
	|INTO
	|	Table_ProjectData_Accounts_Income
	|FROM
	|	Table_GeneralJournal_LineItems AS Accounts
	|GROUP BY
	|	Accounts.IncomeAccount,
	|	Accounts.Project";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_ProjectData_Accounts_COGS_Quantity(TablesList)
	
	// Add ProjectData COGS accounts table to document structure.
	TablesList.Insert("Table_ProjectData_Accounts_COGS_Quantity", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // COGS accounts selection
	// ------------------------------------------------------
	// Dimensions
	|	Accounts.COGSAccount                  AS COGSAccount,
	|	Accounts.Project                      AS Project,
	|	Accounts.Product                      AS Product,
	|	Accounts.Location                     AS Location,
	|	Accounts.Type                         AS Type,
	// ------------------------------------------------------
	// Resources
	|	SUM(Accounts.Quantity)                AS Quantity
	// ------------------------------------------------------
	|INTO
	|	Table_ProjectData_Accounts_COGS_Quantity
	|FROM
	|	Table_GeneralJournal_LineItems AS Accounts
	|WHERE
	|	Accounts.HasShipment = FALSE
	|GROUP BY
	|	Accounts.COGSAccount,
	|	Accounts.Project,
	|	Accounts.Product,
	|	Accounts.Location,
	|	Accounts.Type";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_ProjectData_Accounts_COGS_Amount(TablesList)
	
	// Add ProjectData COGS accounts table to document structure.
	TablesList.Insert("Table_ProjectData_Accounts_COGS_Amount", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // FIFO
	// ------------------------------------------------------
	// Dimensions
	|	Accounts.COGSAccount                  AS COGSAccount,
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
	|	Table_ProjectData_Accounts_COGS_Amount
	|FROM
	|	Table_ProjectData_Accounts_COGS_Quantity AS Accounts
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
	|	Table_ProjectData_Accounts_COGS_Quantity AS Accounts
	|	LEFT JOIN Table_GeneralJournal_ProductCost_Total AS ProductCost
	|		ON  ProductCost.Product  = Accounts.Product
	|		AND ProductCost.Location = VALUE(Catalog.Locations.EmptyRef)
	|WHERE
	|	Accounts.Type = VALUE(Enum.InventoryCosting.WeightedAverage)";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_ProjectData_Accounts_COGS(TablesList)
	
	// Add ProjectData COGS accounts table to document structure.
	TablesList.Insert("Table_ProjectData_Accounts_COGS", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // COGS accounts selection
	// ------------------------------------------------------
	// Dimensions
	|	Accounts.COGSAccount                  AS COGSAccount,
	|	Accounts.Project                      AS Project,
	// ------------------------------------------------------
	// Resources
	|	SUM(Accounts.Amount)                  AS Amount
	// ------------------------------------------------------
	|INTO
	|	Table_ProjectData_Accounts_COGS
	|FROM
	|	Table_ProjectData_Accounts_COGS_Amount AS Accounts
	|GROUP BY
	|	Accounts.COGSAccount,
	|	Accounts.Project";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_ProjectData(TablesList)
	
	// Add ProjectData table to document structure.
	TablesList.Insert("Table_ProjectData", TablesList.Count());
	
	// Collect project data.
	QueryText =
	"SELECT // Rec: Income
	// ------------------------------------------------------
	// Standard attributes
	|	SalesInvoice.Ref                      AS Recorder,
	|	SalesInvoice.Date                     AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Dimensions
	|	Income.IncomeAccount                  AS Account,
	|	Income.Project                        AS Project,
	// ------------------------------------------------------
	// Resources
	|	CAST( // Format(Amount * ExchangeRate, ""ND=17; NFD=2"")
	|		Income.Amount *
	|		CASE WHEN SalesInvoice.ExchangeRate > 0
	|			 THEN SalesInvoice.ExchangeRate
	|			 ELSE 1 END
	|		AS NUMBER (17, 2))                AS Amount
	// ------------------------------------------------------
	// Attributes
	// ------------------------------------------------------
	|FROM
	|	Table_ProjectData_Accounts_Income AS Income
	|	LEFT JOIN Document.SalesInvoice AS SalesInvoice
	|		ON True
	|WHERE
	|	SalesInvoice.Ref = &Ref
	|	AND // Amount > 0
	|		Income.Amount > 0
	|
	|UNION ALL
	|
	|SELECT // Rec: Discount
	// ------------------------------------------------------
	// Standard attributes
	|	SalesInvoice.Ref                      AS Recorder,
	|	SalesInvoice.Date                     AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Dimensions
	|	Income.IncomeAccount                  AS Account,
	|	Income.Project                        AS Project,
	// ------------------------------------------------------
	// Resources
	|	CAST( // Format(Discount * IncomeByProject / IncomeTotal * ExchangeRate, ""ND=17; NFD=2"")
	|		CASE WHEN SalesInvoice.LineSubtotal > 0
	|			 THEN SalesInvoice.Discount * Income.Amount / SalesInvoice.LineSubtotal
	|			 ELSE 0 END *
	|		CASE WHEN SalesInvoice.ExchangeRate > 0
	|			 THEN SalesInvoice.ExchangeRate
	|			 ELSE 1 END
	|		AS NUMBER (17, 2))                AS Amount
	// ------------------------------------------------------
	// Attributes
	// ------------------------------------------------------
	|FROM
	|	Table_ProjectData_Accounts_Income AS Income
	|	LEFT JOIN Document.SalesInvoice AS SalesInvoice
	|		ON True
	|WHERE
	|	SalesInvoice.Ref = &Ref
	|	AND // Discount > 0
	|		-1 *
	|		CASE WHEN SalesInvoice.LineSubtotal > 0
	|			 THEN SalesInvoice.Discount * Income.Amount / SalesInvoice.LineSubtotal
	|			 ELSE 0 END > 0
	|
	|UNION ALL
	|
	|SELECT // Exp: COGS
	// ------------------------------------------------------
	// Standard attributes
	|	SalesInvoice.Ref                      AS Recorder,
	|	SalesInvoice.Date                     AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Dimensions
	|	COGS.COGSAccount                      AS Account,
	|	COGS.Project                          AS Project,
	// ------------------------------------------------------
	// Resources
	|	COGS.Amount                           AS Amount
	// ------------------------------------------------------
	// Attributes
	// ------------------------------------------------------
	|FROM
	|	Table_ProjectData_Accounts_COGS AS COGS
	|	LEFT JOIN Document.SalesInvoice AS SalesInvoice
	|		ON True
	|WHERE
	|	SalesInvoice.Ref = &Ref
	|	AND // Amount > 0
	|		COGS.Amount > 0";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_ClassData_Accounts_Income(TablesList)
	
	// Add ClassData income accounts table to document structure.
	TablesList.Insert("Table_ClassData_Accounts_Income", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // Income accounts selection
	// ------------------------------------------------------
	// Dimensions
	|	Accounts.IncomeAccount                AS IncomeAccount,
	|	Accounts.Class                        AS Class,
	// ------------------------------------------------------
	// Resources
	|	SUM(Accounts.Amount)                  AS Amount
	// ------------------------------------------------------
	|INTO
	|	Table_ClassData_Accounts_Income
	|FROM
	|	Table_GeneralJournal_LineItems AS Accounts
	|GROUP BY
	|	Accounts.IncomeAccount,
	|	Accounts.Class";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_ClassData_Accounts_COGS_Quantity(TablesList)
	
	// Add ClassData COGS accounts table to document structure.
	TablesList.Insert("Table_ClassData_Accounts_COGS_Quantity", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // COGS accounts selection
	// ------------------------------------------------------
	// Dimensions
	|	Accounts.COGSAccount                  AS COGSAccount,
	|	Accounts.Class                        AS Class,
	|	Accounts.Product                      AS Product,
	|	Accounts.Location                     AS Location,
	|	Accounts.Type                         AS Type,
	// ------------------------------------------------------
	// Resources
	|	SUM(Accounts.Quantity)                AS Quantity
	// ------------------------------------------------------
	|INTO
	|	Table_ClassData_Accounts_COGS_Quantity
	|FROM
	|	Table_GeneralJournal_LineItems AS Accounts
	|WHERE
	|	Accounts.HasShipment = FALSE
	|GROUP BY
	|	Accounts.COGSAccount,
	|	Accounts.Class,
	|	Accounts.Product,
	|	Accounts.Location,
	|	Accounts.Type";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_ClassData_Accounts_COGS_Amount(TablesList)
	
	// Add ClassData COGS accounts table to document structure.
	TablesList.Insert("Table_ClassData_Accounts_COGS_Amount", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // FIFO
	// ------------------------------------------------------
	// Dimensions
	|	Accounts.COGSAccount                  AS COGSAccount,
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
	|	Table_ClassData_Accounts_COGS_Amount
	|FROM
	|	Table_ClassData_Accounts_COGS_Quantity AS Accounts
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
	|	Table_ClassData_Accounts_COGS_Quantity AS Accounts
	|	LEFT JOIN Table_GeneralJournal_ProductCost_Total AS ProductCost
	|		ON  ProductCost.Product  = Accounts.Product
	|		AND ProductCost.Location = VALUE(Catalog.Locations.EmptyRef)
	|WHERE
	|	Accounts.Type = VALUE(Enum.InventoryCosting.WeightedAverage)";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_ClassData_Accounts_COGS(TablesList)
	
	// Add ClassData COGS accounts table to document structure.
	TablesList.Insert("Table_ClassData_Accounts_COGS", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // COGS accounts selection
	// ------------------------------------------------------
	// Dimensions
	|	Accounts.COGSAccount                  AS COGSAccount,
	|	Accounts.Class                        AS Class,
	// ------------------------------------------------------
	// Resources
	|	SUM(Accounts.Amount)                  AS Amount
	// ------------------------------------------------------
	|INTO
	|	Table_ClassData_Accounts_COGS
	|FROM
	|	Table_ClassData_Accounts_COGS_Amount AS Accounts
	|GROUP BY
	|	Accounts.COGSAccount,
	|	Accounts.Class";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_ClassData(TablesList)
	
	// Add ClassData table to document structure.
	TablesList.Insert("Table_ClassData", TablesList.Count());
	
	// Collect class data.
	QueryText =
	"SELECT // Rec: Income
	// ------------------------------------------------------
	// Standard Attributes
	|	SalesInvoice.Ref                      AS Recorder,
	|	SalesInvoice.Date                     AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Dimensions
	|	Income.IncomeAccount                  AS Account,
	|	Income.Class                          AS Class,
	// ------------------------------------------------------
	// Resources
	|	CAST( // Format(Amount * ExchangeRate, ""ND=17; NFD=2"")
	|		Income.Amount *
	|		CASE WHEN SalesInvoice.ExchangeRate > 0
	|			 THEN SalesInvoice.ExchangeRate
	|			 ELSE 1 END
	|		AS NUMBER (17, 2))                AS Amount
	// ------------------------------------------------------
	// Attributes
	// ------------------------------------------------------
	|FROM
	|	Table_ClassData_Accounts_Income AS Income
	|	LEFT JOIN Document.SalesInvoice AS SalesInvoice
	|		ON True
	|WHERE
	|	SalesInvoice.Ref = &Ref
	|	AND // Amount > 0
	|		Income.Amount > 0
	|
	|UNION ALL
	|
	|SELECT // Rec: Discount
	// ------------------------------------------------------
	// Standard Attributes
	|	SalesInvoice.Ref                      AS Recorder,
	|	SalesInvoice.Date                     AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Dimensions
	|	Income.IncomeAccount                  AS Account,
	|	Income.Class                          AS Class,
	// ------------------------------------------------------
	// Resources
	|	CAST( // Format(Discount * IncomeByClass / IncomeTotal * ExchangeRate, ""ND=17; NFD=2"")
	|		CASE WHEN SalesInvoice.LineSubtotal > 0
	|			 THEN SalesInvoice.Discount * Income.Amount / SalesInvoice.LineSubtotal
	|			 ELSE 0 END *
	|		CASE WHEN SalesInvoice.ExchangeRate > 0
	|			 THEN SalesInvoice.ExchangeRate
	|			 ELSE 1 END
	|		AS NUMBER (17, 2))                AS Amount
	// ------------------------------------------------------
	// Attributes
	// ------------------------------------------------------
	|FROM
	|	Table_ClassData_Accounts_Income AS Income
	|	LEFT JOIN Document.SalesInvoice AS SalesInvoice
	|		ON True
	|WHERE
	|	SalesInvoice.Ref = &Ref
	|	AND // Discount > 0
	|		-1 *
	|		CASE WHEN SalesInvoice.LineSubtotal > 0
	|			 THEN SalesInvoice.Discount * Income.Amount / SalesInvoice.LineSubtotal
	|			 ELSE 0 END > 0
	|
	|UNION ALL
	|
	|SELECT // Exp: COGS
	// ------------------------------------------------------
	// Standard attributes
	|	SalesInvoice.Ref                      AS Recorder,
	|	SalesInvoice.Date                     AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Dimensions
	|	COGS.COGSAccount                      AS Account,
	|	COGS.Class                            AS Class,
	// ------------------------------------------------------
	// Resources
	|	COGS.Amount                           AS Amount
	// ------------------------------------------------------
	// Attributes
	// ------------------------------------------------------
	|FROM
	|	Table_ClassData_Accounts_COGS AS COGS
	|	LEFT JOIN Document.SalesInvoice AS SalesInvoice
	|		ON True
	|WHERE
	|	SalesInvoice.Ref = &Ref
	|	AND // Amount > 0
	|		COGS.Amount > 0";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_SalesTaxOwed(TablesList)
	
	// Add SalesTaxOwed table to document structure.
	TablesList.Insert("Table_SalesTaxOwed", TablesList.Count());
	
	// Collect sales tax data.
	QueryText =
	"SELECT
	// ------------------------------------------------------
	// Standard attributes
	|	SalesTax.Ref                             AS Recorder,
	|	SalesTax.Ref.Date                        AS Period,
	|	0                                        AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt)    AS RecordType,
	|	True                                     AS Active,
	// ------------------------------------------------------
	// Dimensions
	|	VALUE(Enum.AccountingMethod.Accrual)     AS ChargeType,
	|	SalesTax.Agency                          AS Agency,
	|	SalesTax.Rate                            AS TaxRate,
	|	SalesTax.SalesTaxComponent               AS SalesTaxComponent,
	// ------------------------------------------------------
	// Resources
	|	// Referencial: Document total including discounts and shipment.
	|	CAST( // Format((DocumentTotal - SalesTax.Ref.SalesTax) * ExchangeRate, ""ND=17; NFD=2"")
	|		(SalesTax.Ref.DocumentTotal - SalesTax.Ref.SalesTax) *
	|		CASE WHEN SalesTax.Ref.ExchangeRate > 0
	|			 THEN SalesTax.Ref.ExchangeRate
	|			 ELSE 1 END
	|		AS NUMBER (17, 2))                   AS GrossSale,
	|	// Tax calculation base.
	|	CAST( // Format(TaxableSubtotal * ExchangeRate, ""ND=17; NFD=2"")
	|		SalesTax.Ref.TaxableSubtotal *
	|		CASE WHEN SalesTax.Ref.ExchangeRate > 0
	|			 THEN SalesTax.Ref.ExchangeRate
	|			 ELSE 1 END
	|		AS NUMBER (17, 2))                   AS TaxableSale,
	|	// Current sales tax value for the selected agency.
	|	CAST( // Format(TaxableSubtotal * ExchangeRate, ""ND=17; NFD=2"")
	|		SalesTax.Amount *
	|		CASE WHEN SalesTax.Ref.ExchangeRate > 0
	|			 THEN SalesTax.Ref.ExchangeRate
	|			 ELSE 1 END
	|		AS NUMBER (17, 2))                   AS TaxPayable,
	// ------------------------------------------------------
	// Attributes
	|	NULL                                     AS Reason
	// ------------------------------------------------------
	|FROM
	|	Document.SalesInvoice.SalesTaxAcrossAgencies AS SalesTax
	|WHERE
	|	SalesTax.Ref = &Ref
	|	AND SalesTax.Ref.UseAvatax = FALSE
	|ORDER BY
	|	SalesTax.LineNumber";
	
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
		
		// No checks performed while unposting, it does not lead to decreasing the balance.
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
		|	SalesOrder.Ref AS FillingData,
		|	SalesOrder.Company AS Company,
		|	SalesOrder.ShipTo AS ShipTo,
		|	SalesOrder.BillTo AS BillTo,
		|	SalesOrder.ConfirmTo AS ConfirmTo,
		|	SalesOrder.RefNum AS RefNum,
		|	SalesOrder.DropshipCompany AS DropshipCompany,
		|	SalesOrder.DropshipShipTo AS DropshipShipTo,
		|	SalesOrder.DropshipConfirmTo AS DropshipConfirmTo,
		|	SalesOrder.DropshipRefNum AS DropshipRefNum,
		|	SalesOrder.SalesPerson AS SalesPerson,
		|	SalesOrder.Currency AS Currency,
		|	SalesOrder.ExchangeRate AS ExchangeRate,
		|	ISNULL(SalesOrder.Currency.DefaultARAccount, VALUE(ChartOfAccounts.ChartOfAccounts.EmptyRef)) AS ARAccount,
		|	CASE
		|		WHEN SalesOrder.Company.Terms.Days IS NULL 
		|			THEN DATEADD(&Date, DAY, 14)
		|		WHEN SalesOrder.Company.Terms.Days = 0
		|			THEN DATEADD(&Date, DAY, 14)
		|		ELSE DATEADD(&Date, DAY, SalesOrder.Company.Terms.Days)
		|	END AS DueDate,
		|	SalesOrder.Location AS LocationActual,
		|	SalesOrder.DeliveryDate AS DeliveryDateActual,
		|	SalesOrder.Project AS Project,
		|	SalesOrder.Class AS Class,
		|	ISNULL(SalesOrder.Company.Terms, VALUE(Catalog.PaymentTerms.EmptyRef)) AS Terms,
		|	SalesOrder.DiscountPercent AS DiscountPercent,
		|	SalesOrder.Shipping AS Shipping,
		|	NULL AS FOB,
		|	NULL AS Carrier,
		|	NULL AS TrackingNumber,
		|	SalesOrder.SalesTaxRate AS SalesTaxRate,
		|	SalesOrder.DiscountIsTaxable AS DiscountIsTaxable,
		|	SalesOrder.UseAvatax AS UseAvatax,
		|	SalesOrder.AvataxShippingTaxCode AS AvataxShippingTaxCode,
		|	SalesOrder.DiscountTaxability AS DiscountTaxability,
		|	SalesOrder.DiscountType AS DiscountType,
		|	SalesOrder.Discount AS Discount,
		|	SalesOrder.Company.UseAvatax
		|INTO Table_Document_SalesOrder_Attributes
		|FROM
		|	Document.SalesOrder AS SalesOrder
		|WHERE
		|	SalesOrder.Ref IN(&FillingData_Document_SalesOrder)";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document filling.
Function Query_Filling_Document_Shipment_Attributes(TablesList)
	
	// Add Attributes table to document structure.
	TablesList.Insert("Table_Document_Shipment_Attributes", TablesList.Count());
	
	// Collect attributes data.
	QueryText =
		"SELECT
		|	Shipment.Ref AS FillingData,
		|	Shipment.Company AS Company,
		|	Shipment.ShipTo AS ShipTo,
		|	Shipment.BillTo AS BillTo,
		|	Shipment.ConfirmTo AS ConfirmTo,
		|	Shipment.RefNum AS RefNum,
		|	Shipment.DropshipCompany AS DropshipCompany,
		|	Shipment.DropshipShipTo AS DropshipShipTo,
		|	Shipment.DropshipConfirmTo AS DropshipConfirmTo,
		|	Shipment.DropshipRefNum AS DropshipRefNum,
		|	Shipment.SalesPerson AS SalesPerson,
		|	Shipment.Currency AS Currency,
		|	Shipment.ExchangeRate AS ExchangeRate,
		|	ISNULL(Shipment.Currency.DefaultARAccount, VALUE(ChartOfAccounts.ChartOfAccounts.EmptyRef)) AS ARAccount,
		|	CASE
		|		WHEN Shipment.Company.Terms.Days IS NULL 
		|			THEN DATEADD(&Date, DAY, 14)
		|		WHEN Shipment.Company.Terms.Days = 0
		|			THEN DATEADD(&Date, DAY, 14)
		|		ELSE DATEADD(&Date, DAY, Shipment.Company.Terms.Days)
		|	END AS DueDate,
		|	Shipment.LocationActual AS LocationActual,
		|	Shipment.DeliveryDateActual AS DeliveryDateActual,
		|	Shipment.Project AS Project,
		|	Shipment.Class AS Class,
		|	ISNULL(Shipment.Company.Terms, VALUE(Catalog.PaymentTerms.EmptyRef)) AS Terms,
		|	Shipment.DiscountPercent AS DiscountPercent,
		|	Shipment.Shipping AS Shipping,
		|	Shipment.FOB AS FOB,
		|	Shipment.Carrier AS Carrier,
		|	Shipment.TrackingNumber AS TrackingNumber,
		|	Shipment.SalesTaxRate AS SalesTaxRate,
		|	Shipment.DiscountIsTaxable AS DiscountIsTaxable,
		|	Shipment.UseAvatax AS UseAvatax,
		|	Shipment.AvataxShippingTaxCode AS AvataxShippingTaxCode,
		|	Shipment.DiscountTaxability AS DiscountTaxability,
		|	Shipment.Company.UseAvatax
		|INTO Table_Document_Shipment_Attributes
		|FROM
		|	Document.Shipment AS Shipment
		|WHERE
		|	Shipment.Ref IN(&FillingData_Document_Shipment)";
	
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
Function Query_Filling_Document_Shipment_CommonTotals(TablesList)
	
	// Add Totals table to document structure.
	TablesList.Insert("Table_Document_Shipment_CommonTotals", TablesList.Count());
	
	// Collect totals data.
	QueryText =
		"SELECT
		// Totals of document
		|	ShipmentLineItems.Ref                 AS FillingData,
		|	
		|	// Total of taxable amount
		|	SUM(CASE
		|			WHEN ShipmentLineItems.Taxable = True THEN
		|				ShipmentLineItems.TaxableAmount +
		|				CASE // Discount
		|					WHEN ShipmentLineItems.Ref.LineSubtotal > 0 THEN
		|						ShipmentLineItems.Ref.Discount *
		|						ShipmentLineItems.LineTotal /
		|						ShipmentLineItems.Ref.LineSubtotal
		|					ELSE 0
		|				END
		|			ELSE 0
		|		END)                                AS TaxableAmount
		|	
		|INTO
		|	Table_Document_Shipment_CommonTotals
		|FROM
		|	Document.Shipment.LineItems AS ShipmentLineItems
		|WHERE
		|	ShipmentLineItems.Ref IN (&FillingData_Document_Shipment)
		|GROUP BY
		|	ShipmentLineItems.Ref";
	
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
		|	NULL                                    AS LineID,
		|	SalesOrderLineItems.Product             AS Product,
		|	SalesOrderLineItems.ProductDescription  AS ProductDescription,
		|	NULL                                    AS Lot,
		|	SalesOrderLineItems.UnitSet             AS UnitSet,
		|	SalesOrderLineItems.Unit                AS Unit,
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
		|	// PriceUnits
		|	CASE
		|		WHEN SalesOrderLineItems.Product.PricePrecision = 3
		|			THEN CAST(SalesOrderLineItems.PriceUnits AS NUMBER(17, 3))
		|		WHEN SalesOrderLineItems.Product.PricePrecision = 4
		|			THEN CAST(SalesOrderLineItems.PriceUnits AS NUMBER(17, 4))
		|		ELSE CAST(SalesOrderLineItems.PriceUnits AS NUMBER(17, 2))
		|	END                                     AS PriceUnits,
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
		|		AS NUMBER (17, 2))                  AS LineTotal,
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
		|	VALUE(Document.Shipment.EmptyRef)       AS Shipment,
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
Function Query_Filling_Document_Shipment_LineItems(TablesList)
	
	// Add LineItems table to document structure.
	TablesList.Insert("Table_Document_Shipment_LineItems", TablesList.Count());
	
	// Collect line items data.
	QueryText =
		"SELECT
		|	ShipmentLineItems.Ref                   AS FillingData,
		|	ShipmentLineItems.LineID                AS LineID,
		|	ShipmentLineItems.Product               AS Product,
		|	ShipmentLineItems.ProductDescription    AS ProductDescription,
		|	ShipmentLineItems.Lot                   AS Lot,
		|	ShipmentLineItems.UnitSet               AS UnitSet,
		|	ShipmentLineItems.Unit                  AS Unit,
		|	
		|	// QtyUnits
		|	CASE
		|		WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Open)
		|			THEN ISNULL(OrdersRegistered.Quantity, ShipmentLineItems.QtyUnits)
		|		WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Backordered)
		|			THEN ISNULL(OrdersRegistered.Backorder, ShipmentLineItems.QtyUnits)
		|		WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Closed)
		|			THEN ISNULL(OrdersRegistered.Backorder, 0)
		|		ELSE 0
		|	END                                     AS QtyUnits,
		|	
		|	// QtyUM
		|	CAST( // Format(Quantity * Unit.Factor, ""ND=15; NFD={4}"")
		|		CASE
		|			WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Open)
		|				THEN ISNULL(OrdersRegistered.Quantity, ShipmentLineItems.QtyUnits)
		|			WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Backordered)
		|				THEN ISNULL(OrdersRegistered.Backorder, ShipmentLineItems.QtyUnits)
		|			WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Closed)
		|				THEN ISNULL(OrdersRegistered.Backorder, 0)
		|			ELSE 0
		|		END * 
		|		CASE
		|			WHEN ShipmentLineItems.Unit.Factor > 0
		|				THEN ShipmentLineItems.Unit.Factor
		|			ELSE 1
		|		END
		|		AS NUMBER (15, {QuantityPrecision})) AS QtyUM,
		|	
		|	// PriceUnits
		|	CASE
		|		WHEN ShipmentLineItems.Product.PricePrecision = 3
		|			THEN CAST(ShipmentLineItems.PriceUnits AS NUMBER(17, 3))
		|		WHEN ShipmentLineItems.Product.PricePrecision = 4
		|			THEN CAST(ShipmentLineItems.PriceUnits AS NUMBER(17, 4))
		|		ELSE CAST(ShipmentLineItems.PriceUnits AS NUMBER(17, 2))
		|	END                                      AS PriceUnits,
		|	
		|	// LineTotal
		|	CAST( // Format(Quantity * Price, ""ND=17; NFD=2"")
		|		CASE
		|			WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Open)
		|				THEN ISNULL(OrdersRegistered.Quantity, ShipmentLineItems.QtyUnits)
		|			WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Backordered)
		|				THEN ISNULL(OrdersRegistered.Backorder, ShipmentLineItems.QtyUnits)
		|			WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Closed)
		|				THEN ISNULL(OrdersRegistered.Backorder, 0)
		|			ELSE 0
		|		END * CASE
		|			WHEN ShipmentLineItems.Product.PricePrecision = 3
		|				THEN CAST(ShipmentLineItems.PriceUnits AS NUMBER(17, 3))
		|			WHEN ShipmentLineItems.Product.PricePrecision = 4
		|				THEN CAST(ShipmentLineItems.PriceUnits AS NUMBER(17, 4))
		|			ELSE CAST(ShipmentLineItems.PriceUnits AS NUMBER(17, 2))
		|		END
		|		AS NUMBER (17, 2))                  AS LineTotal,
		|	
		|	// Discount
		|	CAST( // Format(Discount * LineTotal / Subtotal, ""ND=17; NFD=2"")
		|		CASE
		|			WHEN ShipmentLineItems.Ref.LineSubtotal > 0 THEN
		|				ShipmentLineItems.Ref.Discount *
		|				CASE // LineTotal = Quantity * Price
		|					WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Open)
		|						THEN ISNULL(OrdersRegistered.Quantity, ShipmentLineItems.QtyUnits)
		|					WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Backordered)
		|						THEN ISNULL(OrdersRegistered.Backorder, ShipmentLineItems.QtyUnits)
		|					WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Closed)
		|						THEN ISNULL(OrdersRegistered.Backorder, 0)
		|					ELSE 0
		|				END * CASE
		|					WHEN ShipmentLineItems.Product.PricePrecision = 3
		|						THEN CAST(ShipmentLineItems.PriceUnits AS NUMBER(17, 3))
		|					WHEN ShipmentLineItems.Product.PricePrecision = 4
		|						THEN CAST(ShipmentLineItems.PriceUnits AS NUMBER(17, 4))
		|					ELSE CAST(ShipmentLineItems.PriceUnits AS NUMBER(17, 2))
		|				END /
		|				ShipmentLineItems.Ref.LineSubtotal
		|			ELSE 0
		|		END
		|		AS NUMBER (17, 2))                  AS Discount,
		|	
		|	// Taxable flag
		|	ShipmentLineItems.Taxable               AS Taxable,
		|	
		|	// Taxable amount
		|	CAST( // Format(?(Taxable, LineTotal, 0), ""ND=17; NFD=2"")
		|		CASE
		|			WHEN ShipmentLineItems.Taxable = True THEN
		|				CASE // Quantity * Price
		|					WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Open)
		|						THEN ISNULL(OrdersRegistered.Quantity, ShipmentLineItems.QtyUnits)
		|					WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Backordered)
		|						THEN ISNULL(OrdersRegistered.Backorder, ShipmentLineItems.QtyUnits)
		|					WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Closed)
		|						THEN ISNULL(OrdersRegistered.Backorder, 0)
		|					ELSE 0
		|				END * CASE
		|					WHEN ShipmentLineItems.Product.PricePrecision = 3
		|						THEN CAST(ShipmentLineItems.PriceUnits AS NUMBER(17, 3))
		|					WHEN ShipmentLineItems.Product.PricePrecision = 4
		|						THEN CAST(ShipmentLineItems.PriceUnits AS NUMBER(17, 4))
		|					ELSE CAST(ShipmentLineItems.PriceUnits AS NUMBER(17, 2))
		|				END
		|			ELSE 0
		|		END
		|		AS NUMBER (17, 2))                  AS TaxableAmount,
		|	
		|	// Tax amount
		|	CAST( // Format(TaxableAmount * TaxRate, ""ND=17; NFD=2"")
		|		// Taxable amount
		|		CASE
		|			WHEN ShipmentLineItems.Taxable = True THEN
		|				CASE // LineTotal
		|					WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Open)
		|						THEN ISNULL(OrdersRegistered.Quantity, ShipmentLineItems.QtyUnits)
		|					WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Backordered)
		|						THEN ISNULL(OrdersRegistered.Backorder, ShipmentLineItems.QtyUnits)
		|					WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Closed)
		|						THEN ISNULL(OrdersRegistered.Backorder, 0)
		|					ELSE 0
		|				END * CASE
		|					WHEN ShipmentLineItems.Product.PricePrecision = 3
		|						THEN CAST(ShipmentLineItems.PriceUnits AS NUMBER(17, 3))
		|					WHEN ShipmentLineItems.Product.PricePrecision = 4
		|						THEN CAST(ShipmentLineItems.PriceUnits AS NUMBER(17, 4))
		|					ELSE CAST(ShipmentLineItems.PriceUnits AS NUMBER(17, 2))
		|				END
		|				+
		|				CASE // Discount
		|					WHEN ShipmentLineItems.Ref.LineSubtotal > 0 THEN
		|						ShipmentLineItems.Ref.Discount *
		|						CASE // LineTotal = Quantity * Price
		|							WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Open)
		|								THEN ISNULL(OrdersRegistered.Quantity, ShipmentLineItems.QtyUnits)
		|							WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Backordered)
		|								THEN ISNULL(OrdersRegistered.Backorder, ShipmentLineItems.QtyUnits)
		|							WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Closed)
		|								THEN ISNULL(OrdersRegistered.Backorder, 0)
		|							ELSE 0
		|						END * CASE
		|							WHEN ShipmentLineItems.Product.PricePrecision = 3
		|								THEN CAST(ShipmentLineItems.PriceUnits AS NUMBER(17, 3))
		|							WHEN ShipmentLineItems.Product.PricePrecision = 4
		|								THEN CAST(ShipmentLineItems.PriceUnits AS NUMBER(17, 4))
		|							ELSE CAST(ShipmentLineItems.PriceUnits AS NUMBER(17, 2))
		|						END /
		|						ShipmentLineItems.Ref.LineSubtotal
		|					ELSE 0
		|				END
		|			ELSE 0
		|		END *
		|		// Tax rate
		|		CASE
		|			WHEN CommonTotals.TaxableAmount > 0 THEN
		|				ShipmentLineItems.Ref.SalesTax /
		|				CommonTotals.TaxableAmount
		|			ELSE 0
		|		END
		|		AS NUMBER (17, 2))                  AS SalesTax,
		|	
		|	ShipmentLineItems.Order                 AS Order,
		|	ShipmentLineItems.Ref                   AS Shipment,
		|	ShipmentLineItems.Location              AS Location,
		|	ShipmentLineItems.LocationActual        AS LocationActual,
		|	ShipmentLineItems.DeliveryDate          AS DeliveryDate,
		|	ShipmentLineItems.DeliveryDateActual    AS DeliveryDateActual,
		|	ShipmentLineItems.Project               AS Project,
		|	ShipmentLineItems.Class                 AS Class,
		|	ShipmentLineItems.Ref.Company           AS Company,
		|	ShipmentLineItems.AvataxTaxCode         AS AvataxTaxCode,
		|	ShipmentLineItems.DiscountIsTaxable     AS DiscountIsTaxable
		|INTO
		|	Table_Document_Shipment_LineItems
		|FROM
		|	Document.Shipment.LineItems AS ShipmentLineItems
		|	LEFT JOIN Table_Document_Shipment_CommonTotals AS CommonTotals
		|		ON CommonTotals.FillingData = ShipmentLineItems.Ref
		|	LEFT JOIN Table_Document_Shipment_OrdersRegistered AS OrdersRegistered
		|		ON  OrdersRegistered.Company      = ShipmentLineItems.Ref.Company
		|		AND OrdersRegistered.Order        = ShipmentLineItems.Order
		|		AND OrdersRegistered.Shipment     = ShipmentLineItems.Ref
		|		AND OrdersRegistered.Product      = ShipmentLineItems.Product
		|		AND OrdersRegistered.Unit         = ShipmentLineItems.Unit
		|		AND OrdersRegistered.Location     = ShipmentLineItems.Location
		|		AND OrdersRegistered.DeliveryDate = ShipmentLineItems.DeliveryDate
		|		AND OrdersRegistered.Project      = ShipmentLineItems.Project
		|		AND OrdersRegistered.Class        = ShipmentLineItems.Class
		|	LEFT JOIN Table_Document_Shipment_OrdersStatuses AS OrdersStatuses
		|		ON OrdersStatuses.Order = ShipmentLineItems.Ref
		|WHERE
		|	ShipmentLineItems.Ref IN (&FillingData_Document_Shipment)";
		
	// Update query rounding using quantity precision.
	QueryText = StrReplace(QueryText, "{QuantityPrecision}", GeneralFunctionsReusable.DefaultQuantityPrecision());
	
	// Return text of query
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document filling.
Function Query_Filling_Document_SalesOrder_SerialNumbers(TablesList)
	
	// Add SerialNumbers table to document structure.
	TablesList.Insert("Table_Document_SalesOrder_SerialNumbers", TablesList.Count());
	
	// Collect line items data.
	QueryText =
		"SELECT
		|	SalesOrderSerialNumbers.Ref                AS FillingData,
		|	NULL                                       AS LineItemsLineID,
		|	""""                                       AS SerialNumber
		|INTO
		|	Table_Document_SalesOrder_SerialNumbers
		|FROM
		|	Document.SalesOrder AS SalesOrderSerialNumbers
		|WHERE
		|	SalesOrderSerialNumbers.Ref IN (&FillingData_Document_SalesOrder)";
	
	// Return text of query
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document filling.
Function Query_Filling_Document_Shipment_SerialNumbers(TablesList)
	
	// Add SerialNumbers table to document structure.
	TablesList.Insert("Table_Document_Shipment_SerialNumbers", TablesList.Count());
	
	// Collect line items data.
	QueryText =
		"SELECT
		|	ShipmentSerialNumbers.Ref                  AS FillingData,
		|	ShipmentSerialNumbers.LineItemsLineID      AS LineItemsLineID,
		|	ShipmentSerialNumbers.SerialNumber         AS SerialNumber
		|INTO
		|	Table_Document_Shipment_SerialNumbers
		|FROM
		|	Document.Shipment.SerialNumbers AS ShipmentSerialNumbers
		|WHERE
		|	ShipmentSerialNumbers.Ref IN (&FillingData_Document_Shipment)";
	
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
Function Query_Filling_Document_Shipment_Totals(TablesList)
	
	// Add Totals table to document structure.
	TablesList.Insert("Table_Document_Shipment_Totals", TablesList.Count());
	
	// Collect totals data.
	QueryText =
		"SELECT
		// Totals of document
		|	ShipmentLineItems.FillingData         AS FillingData,
		|	
		|	// Total(LineTotal)
		|	SUM(ShipmentLineItems.LineTotal)      AS LineSubtotal,
		|	
		|	// Total(Discount)
		|	SUM(ShipmentLineItems.Discount)       AS Discount,
		|	
		|	// Total(LineTotal) + Total(Discount)
		|	SUM(ShipmentLineItems.LineTotal) +
		|	SUM(ShipmentLineItems.Discount)       AS SubTotal,
		|	
		|	// Total(SalesTax)
		|	SUM(ShipmentLineItems.SalesTax)       AS SalesTax,
		|	
		|	// Format(SalesTax * ExchangeRate, ""ND=17; NFD=2"")
		|	CAST( // Format(SalesTax * ExchangeRate, ""ND=17; NFD=2"")
		|		SUM(ShipmentLineItems.SalesTax) *
		|		Shipment_.ExchangeRate
		|		AS NUMBER (17, 2))                  AS SalesTaxRC
		|	
		|INTO
		|	Table_Document_Shipment_Totals
		|FROM
		|	Table_Document_Shipment_LineItems AS ShipmentLineItems
		|	LEFT JOIN Table_Document_Shipment_Attributes AS Shipment_
		|		ON Shipment_.FillingData = ShipmentLineItems.FillingData
		|GROUP BY
		|	ShipmentLineItems.FillingData,
		|	Shipment_.ExchangeRate";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document filling.
Function Query_Filling_Attributes(TablesList)
	
	// Add Attributes table to document structure.
	TablesList.Insert("Table_Attributes", TablesList.Count());
	
	// Fill data from attributes and totals.
	QueryText = "";
	
	// Fill from sales orders.
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
		|	Document_SalesOrder_Attributes.ARAccount,
		|	Document_SalesOrder_Attributes.DueDate,
		|	Document_SalesOrder_Attributes.LocationActual,
		|	Document_SalesOrder_Attributes.DeliveryDateActual,
		|	Document_SalesOrder_Attributes.Project,
		|	Document_SalesOrder_Attributes.Class,
		|	Document_SalesOrder_Attributes.Terms,
		|	Document_SalesOrder_Totals.LineSubtotal,
		|	Document_SalesOrder_Attributes.DiscountPercent,
		|	CASE
		|		WHEN Document_SalesOrder_Attributes.DiscountType = VALUE(Enum.DiscountType.FixedAmount)
		|			THEN Document_SalesOrder_Attributes.Discount
		|		ELSE Document_SalesOrder_Totals.Discount
		|	END AS Discount,
		|	Document_SalesOrder_Totals.SubTotal,
		|	Document_SalesOrder_Attributes.Shipping,
		|	Document_SalesOrder_Attributes.FOB,
		|	Document_SalesOrder_Attributes.Carrier,
		|	Document_SalesOrder_Attributes.TrackingNumber,
		|	CASE
		|		WHEN Document_SalesOrder_Attributes.CompanyUseAvatax
		|			THEN 0
		|		ELSE Document_SalesOrder_Totals.SalesTax
		|	END AS SalesTax,
		|	CASE
		|		WHEN Document_SalesOrder_Attributes.CompanyUseAvatax
		|			THEN 0
		|		ELSE Document_SalesOrder_Totals.SalesTaxRC
		|	END AS SalesTaxRC,
		|	Document_SalesOrder_Attributes.SalesTaxRate,
		|	Document_SalesOrder_Attributes.DiscountIsTaxable,
		|	CASE
		|		WHEN Document_SalesOrder_Attributes.CompanyUseAvatax
		|			THEN TRUE
		|		ELSE Document_SalesOrder_Attributes.UseAvatax
		|	END AS UseAvatax,
		|	Document_SalesOrder_Attributes.AvataxShippingTaxCode,
		|	Document_SalesOrder_Attributes.DiscountTaxability,
		|	Document_SalesOrder_Attributes.DiscountType
		|{Into}
		|FROM
		|	Table_Document_SalesOrder_Attributes AS Document_SalesOrder_Attributes
		|		LEFT JOIN Table_Document_SalesOrder_Totals AS Document_SalesOrder_Totals
		|		ON (Document_SalesOrder_Totals.FillingData = Document_SalesOrder_Attributes.FillingData)";
		
		// Add selection to a query
		QueryText = QueryText + StrReplace(SelectionText, "{Into}",
		?(IsBlankString(QueryText), 
		"INTO
		|	Table_Attributes",
		""));
		
	EndIf;
	
	// Fill from shipment.
	If TablesList.Property("Table_Document_Shipment_Attributes") Then
		QueryText = QueryText + ?(Not IsBlankString(QueryText),
		"
		|
		|UNION ALL
		|
		|",
		"");
		
		SelectionText =
		"SELECT
		|	Document_Shipment_Attributes.FillingData,
		|	Document_Shipment_Attributes.Company,
		|	Document_Shipment_Attributes.ShipTo,
		|	Document_Shipment_Attributes.BillTo,
		|	Document_Shipment_Attributes.ConfirmTo,
		|	Document_Shipment_Attributes.RefNum,
		|	Document_Shipment_Attributes.DropshipCompany,
		|	Document_Shipment_Attributes.DropshipShipTo,
		|	Document_Shipment_Attributes.DropshipConfirmTo,
		|	Document_Shipment_Attributes.DropshipRefNum,
		|	Document_Shipment_Attributes.SalesPerson,
		|	Document_Shipment_Attributes.Currency,
		|	Document_Shipment_Attributes.ExchangeRate,
		|	Document_Shipment_Attributes.ARAccount,
		|	Document_Shipment_Attributes.DueDate,
		|	Document_Shipment_Attributes.LocationActual,
		|	Document_Shipment_Attributes.DeliveryDateActual,
		|	Document_Shipment_Attributes.Project,
		|	Document_Shipment_Attributes.Class,
		|	Document_Shipment_Attributes.Terms,
		|	Document_Shipment_Totals.LineSubtotal,
		|	Document_Shipment_Attributes.DiscountPercent,
		|	Document_Shipment_Totals.Discount,
		|	Document_Shipment_Totals.SubTotal,
		|	Document_Shipment_Attributes.Shipping,
		|	Document_Shipment_Attributes.FOB,
		|	Document_Shipment_Attributes.Carrier,
		|	Document_Shipment_Attributes.TrackingNumber,
		|	CASE
		|		WHEN Document_Shipment_Attributes.CompanyUseAvatax
		|			THEN 0
		|		ELSE Document_Shipment_Totals.SalesTax
		|	END AS SalesTax,
		|	CASE
		|		WHEN Document_Shipment_Attributes.CompanyUseAvatax
		|			THEN 0
		|		ELSE Document_Shipment_Totals.SalesTaxRC
		|	END AS SalesTaxRC,
		|	Document_Shipment_Attributes.SalesTaxRate,
		|	Document_Shipment_Attributes.DiscountIsTaxable,
		|	CASE
		|		WHEN Document_Shipment_Attributes.CompanyUseAvatax
		|			THEN TRUE
		|		ELSE Document_Shipment_Attributes.UseAvatax
		|	END AS UseAvatax,
		|	Document_Shipment_Attributes.AvataxShippingTaxCode,
		|	Document_Shipment_Attributes.DiscountTaxability
		|{Into}
		|FROM
		|	Table_Document_Shipment_Attributes AS Document_Shipment_Attributes
		|	LEFT JOIN Table_Document_Shipment_Totals AS Document_Shipment_Totals
		|		ON Document_Shipment_Totals.FillingData = Document_Shipment_Attributes.FillingData";
		
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
		|	Document_SalesOrder_LineItems.LineID,
		|	Document_SalesOrder_LineItems.Product,
		|	Document_SalesOrder_LineItems.ProductDescription,
		|	Document_SalesOrder_LineItems.Lot,
		|	Document_SalesOrder_LineItems.UnitSet,
		|	Document_SalesOrder_LineItems.QtyUnits,
		|	Document_SalesOrder_LineItems.Unit,
		|	Document_SalesOrder_LineItems.QtyUM,
		|	Document_SalesOrder_LineItems.PriceUnits,
		|	Document_SalesOrder_LineItems.LineTotal,
		|	Document_SalesOrder_LineItems.Taxable,
		|	Document_SalesOrder_LineItems.TaxableAmount,
		|	Document_SalesOrder_LineItems.Order,
		|	Document_SalesOrder_LineItems.Shipment,
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
	
	// Fill from shipment.
	If TablesList.Property("Table_Document_Shipment_LineItems") Then
		QueryText = QueryText + ?(Not IsBlankString(QueryText), 
		"
		|
		|UNION ALL
		|
		|",
		"");
		
		SelectionText =
		"SELECT
		|	Document_Shipment_LineItems.FillingData,
		|	Document_Shipment_LineItems.LineID,
		|	Document_Shipment_LineItems.Product,
		|	Document_Shipment_LineItems.ProductDescription,
		|	Document_Shipment_LineItems.Lot,
		|	Document_Shipment_LineItems.UnitSet,
		|	Document_Shipment_LineItems.QtyUnits,
		|	Document_Shipment_LineItems.Unit,
		|	Document_Shipment_LineItems.QtyUM,
		|	Document_Shipment_LineItems.PriceUnits,
		|	Document_Shipment_LineItems.LineTotal,
		|	Document_Shipment_LineItems.Taxable,
		|	Document_Shipment_LineItems.TaxableAmount,
		|	Document_Shipment_LineItems.Order,
		|	Document_Shipment_LineItems.Shipment,
		|	Document_Shipment_LineItems.Location,
		|	Document_Shipment_LineItems.LocationActual,
		|	Document_Shipment_LineItems.DeliveryDate,
		|	Document_Shipment_LineItems.DeliveryDateActual,
		|	Document_Shipment_LineItems.Project,
		|	Document_Shipment_LineItems.Class,
		|	Document_Shipment_LineItems.AvataxTaxCode,
		|	Document_Shipment_LineItems.DiscountIsTaxable
		|{Into}
		|FROM
		|	Table_Document_Shipment_LineItems AS Document_Shipment_LineItems
		|WHERE
		|	Document_Shipment_LineItems.QtyUnits > 0";
		
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
Function Query_Filling_SerialNumbers(TablesList)
	
	// Add LineItems table to document structure.
	TablesList.Insert("Table_SerialNumbers", TablesList.Count());
	
	// Fill data from attributes and totals.
	QueryText = "";
	
	// Fill from purchase orders.
	If TablesList.Property("Table_Document_SalesOrder_SerialNumbers") Then
		QueryText = QueryText + ?(Not IsBlankString(QueryText), 
		"
		|
		|UNION ALL
		|
		|",
		"");
		
		SelectionText =
		"SELECT
		|	Document_SalesOrder_SerialNumbers.FillingData,
		|	Document_SalesOrder_SerialNumbers.LineItemsLineID,
		|	Document_SalesOrder_SerialNumbers.SerialNumber
		|{Into}
		|FROM
		|	Table_Document_SalesOrder_SerialNumbers AS Document_SalesOrder_SerialNumbers
		|WHERE
		|	Document_SalesOrder_SerialNumbers.SerialNumber <> """"";
		
		// Add selection to a query.
		QueryText = QueryText + StrReplace(SelectionText, "{Into}",
		?(IsBlankString(QueryText), 
		"INTO
		|	Table_SerialNumbers",
		""));
		
	EndIf;
		
	// Fill from item receipt.
	If TablesList.Property("Table_Document_Shipment_SerialNumbers") Then
		QueryText = QueryText + ?(Not IsBlankString(QueryText), 
		"
		|
		|UNION ALL
		|
		|",
		"");
		
		SelectionText =
		"SELECT
		|	Document_Shipment_SerialNumbers.FillingData,
		|	Document_Shipment_SerialNumbers.LineItemsLineID,
		|	Document_Shipment_SerialNumbers.SerialNumber
		|{Into}
		|FROM
		|	Table_Document_Shipment_SerialNumbers AS Document_Shipment_SerialNumbers
		|WHERE
		|	Document_Shipment_SerialNumbers.SerialNumber <> """"";
		
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

// Query for document filling.
Function Query_Filling_SalesTaxAcrossAgencies(TablesList)
	
	// Add SalesTaxAcrossAgencies table to document structure.
	TablesList.Insert("Table_SalesTaxAcrossAgencies", TablesList.Count());
	
	// Fill data from attributes and totals.
	QueryText = "";
	
	// Fill from sales orders.
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
		|	SalesOrderSalesTaxAcrossAgencies.Agency,
		|	SalesOrderSalesTaxAcrossAgencies.Rate,
		|	SalesOrderSalesTaxAcrossAgencies.Amount,
		|	SalesOrderSalesTaxAcrossAgencies.SalesTaxRate,
		|	SalesOrderSalesTaxAcrossAgencies.SalesTaxComponent,
		|	SalesOrderSalesTaxAcrossAgencies.AvataxTaxComponent
		|{Into}
		|FROM
		|	Document.SalesOrder.SalesTaxAcrossAgencies AS SalesOrderSalesTaxAcrossAgencies
		|WHERE
		|	SalesOrderSalesTaxAcrossAgencies.Ref IN(&FillingData_Document_SalesOrder)
		|	AND SalesOrderSalesTaxAcrossAgencies.Ref.Company.UseAvatax = FALSE";
		
		// Add selection to a query.
		QueryText = QueryText + StrReplace(SelectionText, "{Into}",
		?(IsBlankString(QueryText), 
		"INTO
		|	Table_SalesTaxAcrossAgencies",
		""));
		
	EndIf;
	
	// Fill from shipment.
	If TablesList.Property("Table_Document_Shipment_Attributes") Then
		QueryText = QueryText + ?(Not IsBlankString(QueryText), 
		"
		|
		|UNION ALL
		|
		|",
		"");
		
		SelectionText =
		"SELECT
		|	ShipmentSalesTaxAcrossAgencies.Agency,
		|	ShipmentSalesTaxAcrossAgencies.Rate,
		|	ShipmentSalesTaxAcrossAgencies.Amount,
		|	ShipmentSalesTaxAcrossAgencies.SalesTaxRate,
		|	ShipmentSalesTaxAcrossAgencies.SalesTaxComponent,
		|	ShipmentSalesTaxAcrossAgencies.AvataxTaxComponent
		|{Into}
		|FROM
		|	Document.Shipment.SalesTaxAcrossAgencies AS ShipmentSalesTaxAcrossAgencies
		|WHERE
		|	ShipmentSalesTaxAcrossAgencies.Ref IN(&FillingData_Document_Shipment)
		|	AND ShipmentSalesTaxAcrossAgencies.Ref.Company.UseAvatax = FALSE";
		
		// Add selection to a query.
		QueryText = QueryText + StrReplace(SelectionText, "{Into}",
		?(IsBlankString(QueryText), 
		"INTO
		|	Table_SalesTaxAcrossAgencies",
		""));
		
	EndIf;
	
	// Fill data from next source.
	// ---------------------------
	
	Return QueryText //+ DocumentPosting.GetDelimeterOfBatchQuery();
	
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
	CheckAttributes.Insert("ARAccount",          "Check");
	// Maximal possible values.
	CheckAttributes.Insert("DueDate",            "Max");
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
	|	LineItems.Shipment                    AS Shipment,
	|	LineItems.Product                     AS Product,
	|	LineItems.Unit                        AS Unit,
	|	LineItems.Location                    AS Location,
	|	LineItems.DeliveryDate                AS DeliveryDate,
	|	LineItems.Project                     AS Project,
	|	LineItems.Class                       AS Class,
	// ------------------------------------------------------
	// Resources
	|	0                                     AS Quantity,
	|	CASE WHEN LineItems.Shipment <> VALUE(Document.Shipment.EmptyRef)
	|        THEN 0
	|	     WHEN LineItems.Product.Type = VALUE(Enum.InventoryTypes.Inventory)
	|	     THEN CASE WHEN LineItems.QtyUnits - 
	|	                    CASE WHEN OrdersRegisteredBalance.Shipped - OrdersRegisteredBalance.Invoiced > 0
	|	                         THEN OrdersRegisteredBalance.Shipped - OrdersRegisteredBalance.Invoiced
	|	                         ELSE 0 END > 0
	|	               THEN LineItems.QtyUnits - 
	|	                    CASE WHEN OrdersRegisteredBalance.Shipped - OrdersRegisteredBalance.Invoiced > 0
	|	                         THEN OrdersRegisteredBalance.Shipped - OrdersRegisteredBalance.Invoiced
	|	                         ELSE 0 END
	|	               ELSE 0 END
	|	     ELSE 0 END                       AS Shipped,
	|	0                                     AS ShippedShipment,
	|	LineItems.QtyUnits                    AS Invoiced
	// ------------------------------------------------------
	// Attributes
	// ------------------------------------------------------
	|FROM
	|	Document.SalesInvoice.LineItems AS LineItems
	|	LEFT JOIN Table_OrdersRegistered_Balance AS OrdersRegisteredBalance
	|		ON  OrdersRegisteredBalance.Company      = LineItems.Ref.Company
	|		AND OrdersRegisteredBalance.Order        = LineItems.Order
	|		AND OrdersRegisteredBalance.Shipment     = LineItems.Shipment
	|		AND OrdersRegisteredBalance.Product      = LineItems.Product
	|		AND OrdersRegisteredBalance.Unit         = LineItems.Unit
	|		AND OrdersRegisteredBalance.Location     = LineItems.Location
	|		AND OrdersRegisteredBalance.DeliveryDate = LineItems.DeliveryDate
	|		AND OrdersRegisteredBalance.Project      = LineItems.Project
	|		AND OrdersRegisteredBalance.Class        = LineItems.Class
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
	|	OrdersRegisteredBalance.Company         		 AS Company,
	|	OrdersRegisteredBalance.Order           		 AS Order,
	|	OrdersRegisteredBalance.Shipment        		 AS Shipment,
	|	OrdersRegisteredBalance.Product         		 AS Product,
	|	OrdersRegisteredBalance.Unit            		 AS Unit,
	|	OrdersRegisteredBalance.Location        		 AS Location,
	|	OrdersRegisteredBalance.DeliveryDate    		 AS DeliveryDate,
	|	OrdersRegisteredBalance.Project         		 AS Project,
	|	OrdersRegisteredBalance.Class           		 AS Class,
	// ------------------------------------------------------
	// Resources
	|	OrdersRegisteredBalance.QuantityBalance 		 AS Quantity,
	|	OrdersRegisteredBalance.ShippedBalance   		 AS Shipped,
	|	OrdersRegisteredBalance.ShippedShipmentBalance   AS ShippedShipment,
	|	OrdersRegisteredBalance.InvoicedBalance 		 AS Invoiced
	// ------------------------------------------------------
	|FROM
	|	AccumulationRegister.OrdersRegistered.Balance(&PointInTime,
	|		(Company, Order) IN
	|		(SELECT DISTINCT &Company, LineItems.Order // Requred for proper order closing
	|		 FROM Table_LineItems AS LineItems)) AS OrdersRegisteredBalance";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for balances data.
Function Query_OrdersRegisteredShipment_Balance(TablesList)
	
	// Add OrdersRegisteredShipment - Balances table to balances structure.
	TablesList.Insert("Table_OrdersRegisteredShipment_Balance", TablesList.Count());
	
	// Collect orders dispatched balances.
	QueryText =
	"SELECT
	// ------------------------------------------------------
	// Dimensions
	|	OrdersRegisteredBalance.Company            		AS Company,
	|	VALUE(Document.SalesOrder.EmptyRef)        		AS Order,
	|	OrdersRegisteredBalance.Shipment           		AS Shipment,
	|	OrdersRegisteredBalance.Product            		AS Product,
	|	OrdersRegisteredBalance.Unit              	 	AS Unit,
	|	OrdersRegisteredBalance.Location           		AS Location,
	|	OrdersRegisteredBalance.DeliveryDate       		AS DeliveryDate,
	|	OrdersRegisteredBalance.Project            		AS Project,
	|	OrdersRegisteredBalance.Class              		AS Class,
	// ------------------------------------------------------
	// Resources
	|	OrdersRegisteredBalance.QuantityBalance    		AS Quantity,
	|	OrdersRegisteredBalance.ShippedBalance    		AS Shipped,
	|	OrdersRegisteredBalance.ShippedShipmentBalance  AS ShippedShipment,
	|	OrdersRegisteredBalance.InvoicedBalance    		AS Invoiced
	// ------------------------------------------------------
	|FROM
	|	AccumulationRegister.OrdersRegistered.Balance(&PointInTime,
    |       (Company, Shipment) IN
	|		(SELECT DISTINCT &Company, LineItems.Shipment // Requred for proper item Receipt closing
	|		 FROM Table_LineItems AS LineItems
	|        WHERE LineItems.Shipment <> VALUE(Document.Shipment.EmptyRef))) AS OrdersRegisteredBalance";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_OrderTransactions(TablesList)
	
	// Add OrderTransactions table to document structure.
	TablesList.Insert("Table_OrderTransactions", TablesList.Count());
	
	// Collect orders transactions data.
	QueryText =
	"SELECT DISTINCT // Exp: Order Transactions
	// ------------------------------------------------------
	// Standard attributes
	|	LineItems.Ref                         AS Recorder,
	|	LineItems.Ref.Date                    AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Dimensions
	|	LineItems.Order                       AS Order,
	// ------------------------------------------------------
	// Resources
	|	0                                     AS Amount
	// ------------------------------------------------------
	// Attributes
	// ------------------------------------------------------
	|FROM
	|	Document.SalesInvoice.LineItems AS LineItems
	|WHERE
	|	LineItems.Ref = &Ref
	|	AND LineItems.Order <> VALUE(Document.SalesOrder.EmptyRef)
	|ORDER BY
	|	LineItems.Order.Date";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

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
	// Table_OrdersRegistered_Balance already placed in TempTablesManager.
	DocumentPosting.PutTemporaryTable(AdditionalProperties.Posting.PostingTables.Table_OrdersRegistered, "Table_OrdersRegistered", Query.TempTablesManager);
	
	// Create query for calculate order status.
	QueryText = QueryText +
	// Combine balance with document postings.
	"SELECT
	// ------------------------------------------------------
	// Dimensions
	|	OrdersRegisteredBalance.Company          AS Company,
	|	OrdersRegisteredBalance.Order            AS Order,
	|	VALUE(Document.Shipment.EmptyRef)        AS Shipment,
	|	OrdersRegisteredBalance.Product          AS Product,
	|	OrdersRegisteredBalance.Unit             AS Unit,
	|	OrdersRegisteredBalance.Location         AS Location,
	|	OrdersRegisteredBalance.DeliveryDate     AS DeliveryDate,
	|	OrdersRegisteredBalance.Project          AS Project,
	|	OrdersRegisteredBalance.Class            AS Class,
	// ------------------------------------------------------
	// Resources
	|	OrdersRegisteredBalance.Quantity         AS Quantity,
	|	OrdersRegisteredBalance.Shipped          AS Shipped,
	|	OrdersRegisteredBalance.ShippedShipment  AS ShippedShipment,
	|	OrdersRegisteredBalance.Invoiced         AS Invoiced
	// ------------------------------------------------------
	|INTO
	|	OrdersRegistered_Balance_And_Postings
	|FROM
	|	Table_OrdersRegistered_Balance AS OrdersRegisteredBalance
	|	// (Company, Order) IN (SELECT DISTINCT &Company, LineItems.Order FROM Table_LineItems AS LineItems)
	|
	|UNION ALL
	|
	|SELECT
	// ------------------------------------------------------
	// Dimensions
	|	OrdersRegistered.Company,
	|	OrdersRegistered.Order,
	|	VALUE(Document.Shipment.EmptyRef),
	|	OrdersRegistered.Product,
	|	OrdersRegistered.Unit,
	|	OrdersRegistered.Location,
	|	OrdersRegistered.DeliveryDate,
	|	OrdersRegistered.Project,
	|	OrdersRegistered.Class,
	// ------------------------------------------------------
	// Resources
	|	OrdersRegistered.Quantity,
	|	OrdersRegistered.Shipped,
	|	OrdersRegistered.ShippedShipment,
	|	OrdersRegistered.Invoiced
	// ------------------------------------------------------
	|FROM
	|	Table_OrdersRegistered AS OrdersRegistered
	|	// Table_LineItems WHERE LineItems.Ref = &Ref AND Order <> EmptyRef()
	|
	|UNION ALL
	|
	|SELECT
	// ------------------------------------------------------
	// Dimensions
	|	OrdersRegisteredShipment_Balance.Company         AS Company,
	|	OrdersRegisteredShipment_Balance.Order           AS Order,
	|	OrdersRegisteredShipment_Balance.Shipment        AS Shipment,
	|	OrdersRegisteredShipment_Balance.Product         AS Product,
	|	OrdersRegisteredShipment_Balance.Unit            AS Unit,
	|	OrdersRegisteredShipment_Balance.Location        AS Location,
	|	OrdersRegisteredShipment_Balance.DeliveryDate    AS DeliveryDate,
	|	OrdersRegisteredShipment_Balance.Project         AS Project,
	|	OrdersRegisteredShipment_Balance.Class           AS Class,
	// ------------------------------------------------------
	// Resources
	|	OrdersRegisteredShipment_Balance.Quantity        AS Quantity,
	|	OrdersRegisteredShipment_Balance.Shipped         AS Shipped,
	|	OrdersRegisteredShipment_Balance.ShippedShipment AS ShippedShipment,
	|	OrdersRegisteredShipment_Balance.Invoiced        AS Invoiced
	// ------------------------------------------------------
	|FROM
	|	Table_OrdersRegisteredShipment_Balance AS OrdersRegisteredShipment_Balance
    |   // (Company, Shipment) IN (SELECT DISTINCT &Company, LineItems.Shipment FROM Table_LineItems AS LineItems WHERE LineItems.Shipment <> VALUE(Document.Shipment.EmptyRef))
	|
	|UNION ALL
	|
	|SELECT
	// ------------------------------------------------------
	// Dimensions
	|	OrdersRegisteredShipment.Company,
	|	VALUE(Document.SalesOrder.EmptyRef),
	|	OrdersRegisteredShipment.Shipment,
	|	OrdersRegisteredShipment.Product,
	|	OrdersRegisteredShipment.Unit,
	|	OrdersRegisteredShipment.Location,
	|	OrdersRegisteredShipment.DeliveryDate,
	|	OrdersRegisteredShipment.Project,
	|	OrdersRegisteredShipment.Class,
	// ------------------------------------------------------
	// Resources
	|	OrdersRegisteredShipment.Quantity,
	|	OrdersRegisteredShipment.Shipped,
	|	OrdersRegisteredShipment.ShippedShipment,
	|	OrdersRegisteredShipment.Invoiced
	// ------------------------------------------------------
	|FROM
	|	Table_OrdersRegistered AS OrdersRegisteredShipment
	|	// Table_LineItems WHERE LineItems.Ref = &Ref AND Order <> EmptyRef()
	|WHERE
	|	OrdersRegisteredShipment.Shipment <> VALUE(Document.Shipment.EmptyRef)
	|";
	QueryText   = QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	QueryTables = QueryTables + 1;
	
	// Calculate final balance after posting the invoice.
	QueryText = QueryText +
	"SELECT
	// ------------------------------------------------------
	// Dimensions
	|	OrdersRegisteredBalance.Company              AS Company,
	|	OrdersRegisteredBalance.Order                AS Order,
	|	OrdersRegisteredBalance.Shipment             AS Shipment,
	|	OrdersRegisteredBalance.Product              AS Product,
	|	OrdersRegisteredBalance.Product.Type         AS Type,
	|	OrdersRegisteredBalance.Unit                 AS Unit,
	|	OrdersRegisteredBalance.Location             AS Location,
	|	OrdersRegisteredBalance.DeliveryDate         AS DeliveryDate,
	|	OrdersRegisteredBalance.Project              AS Project,
	|	OrdersRegisteredBalance.Class                AS Class,
	// ------------------------------------------------------
	// Resources
	|	SUM(OrdersRegisteredBalance.Quantity)        AS Quantity,
	|	SUM(OrdersRegisteredBalance.Shipped)         AS Shipped,
	|	SUM(OrdersRegisteredBalance.ShippedShipment) AS ShippedShipment,
	|	SUM(OrdersRegisteredBalance.Invoiced)        AS Invoiced
	// ------------------------------------------------------
	|INTO
	|	OrdersRegistered_Balance_AfterWrite
	|FROM
	|	OrdersRegistered_Balance_And_Postings AS OrdersRegisteredBalance
	|GROUP BY
	|	OrdersRegisteredBalance.Company,
	|	OrdersRegisteredBalance.Order,
	|	OrdersRegisteredBalance.Shipment,
	|	OrdersRegisteredBalance.Product,
	|	OrdersRegisteredBalance.Product.Type,
	|	OrdersRegisteredBalance.Unit,
	|	OrdersRegisteredBalance.Location,
	|	OrdersRegisteredBalance.DeliveryDate,
	|	OrdersRegisteredBalance.Project,
	|	OrdersRegisteredBalance.Class";
	QueryText   = QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	QueryTables = QueryTables + 1;
	
	// Calculate unshipped and(or) uninvoiced items.
	QueryText = QueryText +
	"SELECT
	// ------------------------------------------------------
	// Dimensions
	|	OrdersRegisteredBalance.Company          AS Company,
	|	OrdersRegisteredBalance.Order            AS Order,
	|	OrdersRegisteredBalance.Shipment         AS Shipment,
	|	OrdersRegisteredBalance.Product          AS Product,
	|	OrdersRegisteredBalance.Unit             AS Unit,
	|	OrdersRegisteredBalance.Location         AS Location,
	|	OrdersRegisteredBalance.DeliveryDate     AS DeliveryDate,
	|	OrdersRegisteredBalance.Project          AS Project,
	|	OrdersRegisteredBalance.Class            AS Class,
	// ------------------------------------------------------
	// Resources
	|	CASE WHEN OrdersRegisteredBalance.Shipment <> VALUE(Document.Shipment.EmptyRef)
	|		 THEN 0
	|		 WHEN OrdersRegisteredBalance.Type = VALUE(Enum.InventoryTypes.Inventory)
	|	     THEN OrdersRegisteredBalance.Quantity - OrdersRegisteredBalance.Shipped
	|	     ELSE 0 END                          AS UnShipped,
	|	CASE WHEN OrdersRegisteredBalance.Shipment <> VALUE(Document.Shipment.EmptyRef)
	|        THEN OrdersRegisteredBalance.ShippedShipment - OrdersRegisteredBalance.Invoiced
	|        WHEN OrdersRegisteredBalance.Type = VALUE(Enum.InventoryTypes.Inventory)
	|	     THEN OrdersRegisteredBalance.Shipped - OrdersRegisteredBalance.Invoiced
	|	     WHEN OrdersRegisteredBalance.Type = VALUE(Enum.InventoryTypes.NonInventory)
	|	     THEN OrdersRegisteredBalance.Quantity - OrdersRegisteredBalance.Invoiced
	|	     ELSE 0 END                          AS UnInvoiced
	// ------------------------------------------------------
	|INTO
	|	OrdersRegistered_Balance_Unclosed
	|FROM
	|	OrdersRegistered_Balance_AfterWrite AS OrdersRegisteredBalance";
	
	QueryText   = QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	QueryTables = QueryTables + 1;
	
	// Calculate unclosed.
	QueryText = QueryText +
	"SELECT
	// ------------------------------------------------------
	// Dimensions
	|	OrdersRegisteredBalance.Order            AS Order,
	|	OrdersRegisteredBalance.Shipment         AS Shipment,
	|	SUM(OrdersRegisteredBalance.UnShipped
	|	  + OrdersRegisteredBalance.UnInvoiced)  AS Unclosed
	// ------------------------------------------------------
	|INTO
	|	OrdersRegistered_Balance_Orders_Unclosed
	|FROM
	|	OrdersRegistered_Balance_Unclosed AS OrdersRegisteredBalance
	|GROUP BY
	|	OrdersRegisteredBalance.Order,
	|	OrdersRegisteredBalance.Shipment";
	QueryText   = QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	QueryTables = QueryTables + 1;
	
	// Calculate closed orders (those in invoice, which don't have unclosed items in theirs balance).
	QueryText = QueryText +
	"SELECT DISTINCT
	|	OrdersRegisteredBalanceUnclosed.Order       AS Order,
	|	OrdersRegisteredBalanceUnclosed.Shipment    AS Shipment
	|FROM
	|	OrdersRegistered_Balance_Orders_Unclosed AS OrdersRegisteredBalanceUnclosed
	|WHERE
	|	// No unclosed items
	|	OrdersRegisteredBalanceUnclosed.Unclosed = 0";
	QueryText   = QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	QueryTables = QueryTables + 1;
	
	// Clear orders registered postings table.
	QueryText   = QueryText + 
	"DROP Table_OrdersRegistered";
	QueryText   = QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
	// Clear balance with document postings table.
	QueryText   = QueryText + 
	"DROP OrdersRegistered_Balance_And_Postings";
	QueryText   = QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
	// Clear final balance after posting the invoice table.
	QueryText   = QueryText + 
	"DROP OrdersRegistered_Balance_AfterWrite";
	QueryText   = QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
		
	// Clear unshipped and uninvoiced items table.
	QueryText   = QueryText + 
	"DROP OrdersRegistered_Balance_Unclosed";
	QueryText   = QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
	// Clear orders having unclosed items in balance table.
	QueryText   = QueryText + 
	"DROP OrdersRegistered_Balance_Orders_Unclosed";
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
			
			Order = ?(ValueIsFilled(Selection.Shipment), Selection.Shipment, Selection.Order);
			
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
Function Query_Filling_Document_Shipment_OrdersStatuses(TablesList)
	
	// Add OrdersStatuses table to document structure.
	TablesList.Insert("Table_Document_Shipment_OrdersStatuses", TablesList.Count());
	
	// Collect orders statuses data.
	QueryText =
		"SELECT
		// ------------------------------------------------------
		// Dimensions
		|	Shipment.Ref                          AS Order,
		// ------------------------------------------------------
		// Resources
		|	CASE
		|		WHEN Shipment.DeletionMark THEN
		|			 VALUE(Enum.OrderStatuses.Deleted)
		|		WHEN NOT Shipment.Posted THEN
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
		|	Table_Document_Shipment_OrdersStatuses
		|FROM
		|	Document.Shipment AS Shipment
		|		LEFT JOIN InformationRegister.OrdersStatuses.SliceLast(, Order IN (&FillingData_Document_Shipment)) AS OrdersStatuses
		|		ON Shipment.Ref = OrdersStatuses.Order
		|WHERE
		|	Shipment.Ref IN (&FillingData_Document_Shipment)";
	
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
		|				END                                                                                                 //     0
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
Function Query_Filling_Document_Shipment_OrdersRegistered(TablesList)
	
	// Add OrdersRegistered table to document structure.
	TablesList.Insert("Table_Document_Shipment_OrdersRegistered", TablesList.Count());
	
	// Collect orders items data.
	QueryText =
		"SELECT
		// ------------------------------------------------------
		// Dimensions
		|	OrdersRegisteredBalance.Company          		AS Company,
		|	OrdersRegisteredBalance.Order            		AS Order,
		|	OrdersRegisteredBalance.Shipment         		AS Shipment,
		|	OrdersRegisteredBalance.Product          		AS Product,
		|	OrdersRegisteredBalance.Unit             		AS Unit,
		|	OrdersRegisteredBalance.Location         		AS Location,
		|	OrdersRegisteredBalance.DeliveryDate     		AS DeliveryDate,
		|	OrdersRegisteredBalance.Project          		AS Project,
		|	OrdersRegisteredBalance.Class            		AS Class,
		// ------------------------------------------------------
		// Resources
		|	OrdersRegisteredBalance.ShippedShipmentBalance  AS Quantity,
		|	CASE
		|		WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Open)        THEN 0
		|		WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Backordered) THEN
		|			 CASE                                                                                                   
		|			      WHEN OrdersRegisteredBalance.ShippedShipmentBalance > OrdersRegisteredBalance.InvoicedBalance          
		|				  THEN OrdersRegisteredBalance.ShippedShipmentBalance - OrdersRegisteredBalance.InvoicedBalance          
		|			      ELSE 0 
		|            END                                                                                                    
		|		WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Closed)      THEN 0
		|		ELSE 0
		|	END                                             AS Backorder
		// ------------------------------------------------------
		|INTO
		|	Table_Document_Shipment_OrdersRegistered
		|FROM
		|	AccumulationRegister.OrdersRegistered.Balance(,
		|		(Company, Order, Shipment, Product, Unit, Location, DeliveryDate, Project, Class) IN
		|			(SELECT
		|				ShipmentLineItems.Ref.Company,
		|				ShipmentLineItems.Order,
		|				ShipmentLineItems.Ref,
		|				ShipmentLineItems.Product,
		|				ShipmentLineItems.Unit,
		|				ShipmentLineItems.Location,
		|				ShipmentLineItems.DeliveryDate,
		|				ShipmentLineItems.Project,
		|				ShipmentLineItems.Class
		|			FROM
		|				Document.Shipment.LineItems AS ShipmentLineItems
		|			WHERE
		|				ShipmentLineItems.Ref IN (&FillingData_Document_Shipment))) AS OrdersRegisteredBalance
		|	LEFT JOIN Table_Document_Shipment_OrdersStatuses AS OrdersStatuses
		|		ON OrdersRegisteredBalance.Shipment = OrdersStatuses.Order";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

//------------------------------------------------------------------------------
// Document printing

#EndIf

#EndRegion