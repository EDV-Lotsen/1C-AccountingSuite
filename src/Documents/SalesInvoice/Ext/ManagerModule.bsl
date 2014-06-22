
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
	If OrdersPosting Then
		Query.Text = Query.Text +
		             Query_OrdersRegistered_Lock(LocksList);
	EndIf;
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
	If OrdersPosting Then
		Query.Text = Query.Text +
		             Query_OrdersRegistered_Balance(BalancesList);
	EndIf;
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
	OrdersPosting    = AdditionalProperties.Orders.Count() > 0;
	InventoryPosting = True; // Post always.
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
	Query.Text   = "";
	If OrdersPosting > 0 Then
		Query.Text = Query.Text +
		             Query_OrdersStatuses(TablesList) +
		             Query_OrdersRegistered(TablesList);
	EndIf;
	If InventoryPosting Then
		Query.Text = Query.Text +
		             Query_InventoryJournal_LineItems(TablesList) +
		             Query_InventoryJournal_Balance_Quantity(TablesList) +
		             Query_InventoryJournal_Balance_FIFO(TablesList) +
		             Query_InventoryJournal(TablesList);
	EndIf;
	If SalesTaxPosting Then
		Query.Text = Query.Text +
		             Query_SalesTaxOwed(TablesList) +
		             Query_GeneralJournal_SalesTax(TablesList);
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
	If OrdersPosting > 0 Then
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
	InvoiceLineItems = LineItems.Unload(Filter, "LineNumber, Order, Product, Location, DeliveryDate, Project, Class, Quantity");
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
		|	OrdersRegisteredBalance.QuantityBalance - OrdersRegisteredBalance.InvoicedBalance - LineItems.Quantity AS UninvoicedQuantity
		|FROM
		|	InvoiceLineItems AS LineItems
		|	LEFT JOIN AccumulationRegister.OrdersRegistered.Balance(&Date, (Company, Order, Product, Location, DeliveryDate, Project, Class)
		|		   IN (SELECT Company, Order, Product, Location, DeliveryDate, Project, Class FROM InvoiceLineItems)) AS OrdersRegisteredBalance
		|		ON  LineItems.Company      = OrdersRegisteredBalance.Company
		|		AND LineItems.Order        = OrdersRegisteredBalance.Order
		|		AND LineItems.Product      = OrdersRegisteredBalance.Product
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
				                            NStr("en = 'The invoiced quantity of product %1 in line %2 exceeds ordered quantity in %3.'"), TrimAll(Row.ProductCode) + " " + TrimAll(Row.ProductDescription), Row.LineNumber, Row.Order);
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
	
	SheetTitle = "Sales invoice";
	CustomTemplate = GeneralFunctions.GetCustomTemplate("Document.SalesInvoice", SheetTitle);
	
	If CustomTemplate = Undefined Then
		If Constants.SalesInvoicePO.Get() = False Then
			Template = Documents.SalesInvoice.GetTemplate("New_SalesInvoice_Form");//("PF_MXL_SalesInvoice");
		ElsIf Constants.SalesInvoicePO.Get() = True Then
			Template = Documents.SalesInvoice.GetTemplate("PF_MXL_SalesInvoice_PO");
		EndIf;
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
   |		Product.UM AS UM,
   |		ProductDescription,
   |		LineItems.Order.RefNum AS PO,
   |		Quantity,
   |		Price,
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
   |	SalesInvoice.SalesPerson,
   |	SalesInvoice.FOB,
   |	SalesInvoice.DropshipCompany,
   |	SalesInvoice.DropshipShipTo,
   |	SalesInvoice.DropshipRefNum
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
	DocumentPrinting.FillLogoInDocumentTemplate(Template, LogoPicture); 
	
	Try
		FooterLogo = GeneralFunctions.GetFooter1();
		Footer1Pic = New Picture(FooterLogo);
		FooterLogo2 = GeneralFunctions.GetFooter2();
		Footer2Pic = New Picture(FooterLogo2);
		FooterLogo3 = GeneralFunctions.GetFooter3();
		Footer3Pic = New Picture(FooterLogo3);
	Except
	EndTry;
	
	//Add footer with page count	
	Template.Footer.Enabled = True;
	Template.Footer.RightText = "Page [&PageNumber] of [&PagesTotal]";
   
	TemplateArea = Template.GetArea("Header");
	  		
	UsBill = PrintTemplates.ContactInfoDatasetUs();
	If Selection.DropshipShipTo <> Catalogs.Addresses.EmptyRef() Then
		ThemShip = PrintTemplates.ContactInfoDataset(Selection.DropshipCompany, "ThemShip", Selection.DropshipShipTo);
	Else
		ThemShip = PrintTemplates.ContactInfoDataset(Selection.Company, "ThemShip", Selection.ShipTo);
	EndIf;
	
	ThemBill = PrintTemplates.ContactInfoDataset(Selection.Company, "ThemBill", Selection.BillTo);
	
	TemplateArea.Parameters.Fill(UsBill);
	TemplateArea.Parameters.Fill(ThemShip);
	TemplateArea.Parameters.Fill(ThemBill);
		
	If Constants.SIShowFullName.Get() = True Then
		TemplateArea.Parameters.ThemFullName = ThemBill.ThemBillSalutation + " " + ThemBill.ThemBillFirstName + " " + ThemBill.ThemBillLastName;
		TemplateArea.Parameters.ThemShipFullName = ThemShip.ThemShipSalutation + " " + ThemShip.ThemShipFirstName + " " + ThemShip.ThemShipLastName + Chars.LF;
	EndIf;


	
	TemplateArea.Parameters.Date = Selection.Date;
	TemplateArea.Parameters.Number = Selection.Number;
	
	If Selection.DropshipShipTo <> Catalogs.Addresses.EmptyRef() Then
		TemplateArea.Parameters.RefNum = Selection.DropShipRefNum;	
	Else 
		TemplateArea.Parameters.RefNum = Selection.RefNum;
	EndIf;

	TemplateArea.Parameters.Carrier = Selection.Carrier;
	TemplateArea.Parameters.TrackingNumber = Selection.TrackingNumber;
	TemplateArea.Parameters.SalesPerson = Selection.SalesPerson;
	TemplateArea.Parameters.FOB = Selection.FOB;
	 Try
	 	TemplateArea.Parameters.Terms = Selection.Terms;
		TemplateArea.Parameters.DueDate = Selection.DueDate;
	Except
	EndTry;
	
	//UsBill filling
	If TemplateArea.Parameters.UsBillLine1 <> "" Then
		TemplateArea.Parameters.UsBillLine1 = TemplateArea.Parameters.UsBillLine1 + Chars.LF; 
	EndIf;

	If TemplateArea.Parameters.UsBillLine2 <> "" Then
		TemplateArea.Parameters.UsBillLine2 = TemplateArea.Parameters.UsBillLine2 + Chars.LF; 
	EndIf;
	
	If TemplateArea.Parameters.UsBillCityStateZIP <> "" Then
		TemplateArea.Parameters.UsBillCityStateZIP = TemplateArea.Parameters.UsBillCityStateZIP + Chars.LF; 
	EndIf;
	
	If TemplateArea.Parameters.UsBillPhone <> "" Then
		TemplateArea.Parameters.UsBillPhone = TemplateArea.Parameters.UsBillPhone + Chars.LF; 
	EndIf;
	
	If TemplateArea.Parameters.UsBillEmail <> "" AND Constants.SIShowEmail.Get() = False Then
		TemplateArea.Parameters.UsBillEmail = ""; 
	EndIf;
		
	
	//ThemBill filling
	If TemplateArea.Parameters.ThemBillLine1 <> "" Then
		TemplateArea.Parameters.ThemBillLine1 = TemplateArea.Parameters.ThemBillLine1 + Chars.LF; 
	EndIf;

	If TemplateArea.Parameters.ThemBillLine2 <> "" Then
		TemplateArea.Parameters.ThemBillLine2 = TemplateArea.Parameters.ThemBillLine2 + Chars.LF; 
	EndIf;
	
	If TemplateArea.Parameters.ThemBillLine3 <> "" Then
		TemplateArea.Parameters.ThemBillLine3 = TemplateArea.Parameters.ThemBillLine3 + Chars.LF; 
	EndIf;
	
	//ThemShip filling
	If TemplateArea.Parameters.ThemShipLine1 <> "" Then
		TemplateArea.Parameters.ThemShipLine1 = TemplateArea.Parameters.ThemShipLine1 + Chars.LF; 
	EndIf;

	If TemplateArea.Parameters.ThemShipLine2 <> "" Then
		TemplateArea.Parameters.ThemShipLine2 = TemplateArea.Parameters.ThemShipLine2 + Chars.LF; 
	EndIf;
	
	If TemplateArea.Parameters.ThemShipLine3 <> "" Then
		TemplateArea.Parameters.ThemShipLine3 = TemplateArea.Parameters.ThemShipLine3 + Chars.LF; 
	EndIf;
	 
	 Spreadsheet.Put(TemplateArea);	 	 
	 	 
	If Constants.SIShowPhone2.Get() = False Then
		Direction = SpreadsheetDocumentShiftType.Vertical;
		Area = Spreadsheet.Area("MobileArea");
		Spreadsheet.DeleteArea(Area, Direction);
		Spreadsheet.InsertArea(Spreadsheet.Area("R10"), Spreadsheet.Area("R10"), 
        SpreadsheetDocumentShiftType.Vertical);
	EndIf;
	
	If Constants.SIShowWebsite.Get() = False Then
		Direction = SpreadsheetDocumentShiftType.Vertical;
		Area = Spreadsheet.Area("WebsiteArea");
		Spreadsheet.DeleteArea(Area, Direction);
		Spreadsheet.InsertArea(Spreadsheet.Area("R10"), Spreadsheet.Area("R10"), 
		SpreadsheetDocumentShiftType.Vertical);

	EndIf;
	
	If Constants.SIShowFax.Get() = False Then
		Direction = SpreadsheetDocumentShiftType.Vertical;
		Area = Spreadsheet.Area("FaxArea");
		Spreadsheet.DeleteArea(Area, Direction);
		Spreadsheet.InsertArea(Spreadsheet.Area("R10"), Spreadsheet.Area("R10"), 
		SpreadsheetDocumentShiftType.Vertical);

	EndIf;
	
	If Constants.SIShowFedTax.Get() = False Then
		Direction = SpreadsheetDocumentShiftType.Vertical;
		Area = Spreadsheet.Area("FedTaxArea");
		Spreadsheet.DeleteArea(Area, Direction);
		Spreadsheet.InsertArea(Spreadsheet.Area("R10"), Spreadsheet.Area("R10"), 
		SpreadsheetDocumentShiftType.Vertical);

	EndIf;
		
	SelectionLineItems = Selection.LineItems.Select();
	TemplateArea = Template.GetArea("LineItems");
	LineTotalSum = 0;
	LineItemSwitch = False;
	CurrentLineItemIndex = 0;
	
	While SelectionLineItems.Next() Do
				 
		CurrentLineItemIndex = CurrentLineItemIndex + 1;
		
		TemplateArea.Parameters.Fill(SelectionLineItems);
		CompanyName = Selection.Company.Description;
		CompanyNameLen = StrLen(CompanyName);
		Try
			 If NOT SelectionLineItems.Project = "" Then
				ProjectLen = StrLen(SelectionLineItems.Project);
			 	TemplateArea.Parameters.Project = Right(SelectionLineItems.Project, ProjectLen - CompanyNameLen - 2);
			EndIf;
		Except
		EndTry;
		LineTotal = SelectionLineItems.LineTotal;
		TemplateArea.Parameters.Price = Selection.Currency.Symbol + Format(SelectionLineItems.Price, "NFD=2; NZ=");
		TemplateArea.Parameters.LineTotal = Selection.Currency.Symbol + Format(SelectionLineItems.LineTotal, "NFD=2; NZ=");
		
		Spreadsheet.Put(TemplateArea, SelectionLineItems.Level());
		
		If LineItemSwitch = False Then
			TemplateArea = Template.GetArea("LineItems2");
			LineItemSwitch = True;
		Else
			TemplateArea = Template.GetArea("LineItems");
			LineItemSwitch = False;
		EndIf;
		
		// If can't fit next line, place header
		
		Footer = Template.GetArea("Area3");
		RowsToCheck = New Array();
		RowsToCheck.Add(TemplateArea);
		DividerArea = Template.GetArea("DividerArea");
		RowsToCheck.Add(DividerArea);
		RowsToCheck.Add(Footer);
		
		If Spreadsheet.CheckPut(RowsToCheck) = False Then
			
			// Add divider and footer to bottom, break to next page, add header.
			
			Row = Template.GetArea("EmptyRow");
			Spreadsheet.Put(Row);
			
			DividerArea = Template.GetArea("DividerArea");
			Spreadsheet.Put(DividerArea);

			If Constants.SIFoot1Type.Get()= Enums.TextOrImage.Image Then	
				DocumentPrinting.FillPictureInDocumentTemplate(Template, Footer1Pic, "footer1");
				TemplateArea2 = Template.GetArea("FooterField|FooterSection1");	
				Spreadsheet.Put(TemplateArea2);
			Elsif Constants.SIFoot1Type.Get() = Enums.TextOrImage.Text Then
				TemplateArea2 = Template.GetArea("TextField|FooterSection1");
				TemplateArea2.Parameters.FooterTextLeft = Constants.InvoiceFooterTextLeft.Get();
				Spreadsheet.Put(TemplateArea2);
			EndIf;
		
			If Constants.SIFoot2Type.Get()= Enums.TextOrImage.Image Then
				DocumentPrinting.FillPictureInDocumentTemplate(Template, Footer2Pic, "footer2");
				TemplateArea2 = Template.GetArea("FooterField|FooterSection2");	
				Spreadsheet.Join(TemplateArea2);
			
			Elsif Constants.SIFoot2Type.Get() = Enums.TextOrImage.Text Then
				TemplateArea2 = Template.GetArea("TextField|FooterSection2");
				TemplateArea2.Parameters.FooterTextCenter = Constants.InvoiceFooterTextCenter.Get();
				Spreadsheet.Join(TemplateArea2);
			EndIf;
		
			If Constants.SIFoot3Type.Get()= Enums.TextOrImage.Image Then
					DocumentPrinting.FillPictureInDocumentTemplate(Template, Footer3Pic, "footer3");
					TemplateArea2 = Template.GetArea("FooterField|FooterSection3");	
					Spreadsheet.Join(TemplateArea2);
			Elsif Constants.SIFoot3Type.Get() = Enums.TextOrImage.Text Then
					TemplateArea2 = Template.GetArea("TextField|FooterSection3");
					TemplateArea2.Parameters.FooterTextRight = Constants.InvoiceFooterTextRight.Get();
					Spreadsheet.Join(TemplateArea2);
			EndIf;	
			
			Spreadsheet.PutHorizontalPageBreak();
			Header =  Spreadsheet.GetArea("TopHeader");
			
			LineItemsHeader = Template.GetArea("LineItemsHeader");
			EmptySpace = Template.GetArea("EmptyRow");
			Spreadsheet.Put(Header);
			Spreadsheet.Put(EmptySpace);
			If CurrentLineItemIndex < SelectionLineItems.Count() Then
				Spreadsheet.Put(LineItemsHeader);
			EndIf;
		EndIf;

		 
	 EndDo;
	
	TemplateArea = Template.GetArea("EmptySpace");
	Spreadsheet.Put(TemplateArea);

	 
	Row = Template.GetArea("EmptyRow");
	DetailArea = Template.GetArea("Area3");
	Compensator = Template.GetArea("Compensator");
	RowsToCheck = New Array();
	RowsToCheck.Add(Row);
	RowsToCheck.Add(DetailArea);
	
	
	// If Area3 does not fit, print to next page and add preceding header
	
	AddHeader = False;
	If Spreadsheet.CheckPut(DetailArea) = False Then
		AddHeader = True;
	EndIf;
		
	While Spreadsheet.CheckPut(RowsToCheck) = False Do
		 Spreadsheet.Put(Row);
	   	 RowsToCheck.Clear();
	  	 RowsToCheck.Add(DetailArea);
		 RowsToCheck.Add(Row);
	EndDo;
	
	//Push down until bottom with space for footer  -  Saved here for future reference.

		//Footer = Template.GetArea("FooterField");
		//RowsToCheck.Add(Row);
		//RowsToCheck.Add(Footer);
		//While Spreadsheet.CheckPut(RowsToCheck) Do
		//	 Spreadsheet.Put(Row);
		//   	 RowsToCheck.Clear();
		//  	 RowsToCheck.Add(DetailArea);
		//	 RowsToCheck.Add(Row);
		//	 RowsToCheck.Add(Footer);
		//	 RowsToCheck.Add(Row);
		//	 RowsToCheck.Add(Row);
		//EndDo;
	
	If AddHeader = True Then
		HeaderArea = Spreadsheet.GetArea("TopHeader");
		Spreadsheet.Put(HeaderArea);
		Spreadsheet.Put(Row);
	EndIf;
	
	TemplateArea = Template.GetArea("Area3|Area1");					
	TemplateArea.Parameters.TermAndCond = Selection.Ref.EmailNote;
	Spreadsheet.Put(TemplateArea);

	
	TemplateArea = Template.GetArea("Area3|Area2");
	TemplateArea.Parameters.LineSubtotal = Selection.Currency.Symbol + Format(Selection.LineSubtotal, "NFD=2; NZ=");
	TemplateArea.Parameters.Discount = "(" + Selection.Currency.Symbol + Format(Selection.Discount, "NFD=2; NZ=") + ")";
	TemplateArea.Parameters.Subtotal = Selection.Currency.Symbol + Format(Selection.Subtotal, "NFD=2; NZ=");
	TemplateArea.Parameters.Shipping = Selection.Currency.Symbol + Format(Selection.Shipping, "NFD=2; NZ=");
	TemplateArea.Parameters.SalesTax = Selection.Currency.Symbol + Format(Selection.SalesTax, "NFD=2; NZ=");
	TemplateArea.Parameters.Total = Selection.Currency.Symbol + Format(Selection.DocumentTotal, "NFD=2; NZ=");
	NonNullBalance = 0;
	If Selection.Balance <> NULL Then NonNullBalance = Selection.Balance; EndIf;
	TemplateArea.Parameters.Balance = Selection.Currency.Symbol + Format(NonNullBalance, "NFD=2; NZ=");

	Spreadsheet.Join(TemplateArea);	
		
	Row = Template.GetArea("EmptyRow");
	Footer = Template.GetArea("FooterField");
	Compensator = Template.GetArea("Compensator");
	RowsToCheck = New Array();
	RowsToCheck.Add(Row);
	RowsToCheck.Add(Footer);
	RowsToCheck.Add(Row);	
	
	While Spreadsheet.CheckPut(RowsToCheck) = False Do
		 Spreadsheet.Put(Row);
	   	 RowsToCheck.Clear();
	  	 RowsToCheck.Add(Footer);
		 RowsToCheck.Add(Row);
	EndDo;
	 
	While Spreadsheet.CheckPut(RowsToCheck) Do
		 Spreadsheet.Put(Row);
	   	 RowsToCheck.Clear();
	  	 RowsToCheck.Add(Footer);
		 RowsToCheck.Add(Row);
		 RowsToCheck.Add(Row);
		 RowsToCheck.Add(Row);

	EndDo;


	TemplateArea = Template.GetArea("DividerArea");
	Spreadsheet.Put(TemplateArea);
	
	// Final footer 
	
	If Constants.SIFoot1Type.Get()= Enums.TextOrImage.Image Then	
			DocumentPrinting.FillPictureInDocumentTemplate(Template, Footer1Pic, "footer1");
			TemplateArea = Template.GetArea("FooterField|FooterSection1");	
			Spreadsheet.Put(TemplateArea);
	Elsif Constants.SIFoot1Type.Get() = Enums.TextOrImage.Text Then
			TemplateArea = Template.GetArea("TextField|FooterSection1");
			TemplateArea.Parameters.FooterTextLeft = Constants.InvoiceFooterTextLeft.Get();
			Spreadsheet.Put(TemplateArea);
	EndIf;
		
	If Constants.SIFoot2Type.Get()= Enums.TextOrImage.Image Then
			DocumentPrinting.FillPictureInDocumentTemplate(Template, Footer2Pic, "footer2");
			TemplateArea = Template.GetArea("FooterField|FooterSection2");	
			Spreadsheet.Join(TemplateArea);
			
	Elsif Constants.SIFoot2Type.Get() = Enums.TextOrImage.Text Then
			TemplateArea = Template.GetArea("TextField|FooterSection2");
			TemplateArea.Parameters.FooterTextCenter = Constants.InvoiceFooterTextCenter.Get();
			Spreadsheet.Join(TemplateArea);
	EndIf;
		
	If Constants.SIFoot3Type.Get()= Enums.TextOrImage.Image Then
			DocumentPrinting.FillPictureInDocumentTemplate(Template, Footer3Pic, "footer3");
			TemplateArea = Template.GetArea("FooterField|FooterSection3");	
			Spreadsheet.Join(TemplateArea);
	Elsif Constants.SIFoot3Type.Get() = Enums.TextOrImage.Text Then
			TemplateArea = Template.GetArea("TextField|FooterSection3");
			TemplateArea.Parameters.FooterTextRight = Constants.InvoiceFooterTextRight.Get();
			Spreadsheet.Join(TemplateArea);
	EndIf;	
	
	Spreadsheet.PutHorizontalPageBreak(); //.ВывестиГоризонтальныйРазделительСтраниц();
	Spreadsheet.FitToPage  = True;
	
	// Remove footer information if only a page.
	If Spreadsheet.PageCount() = 1 Then
		Spreadsheet.Footer.Enabled = False;
	EndIf;

   EndDo;
   
   //Return SpreadsheetDocument;
   
EndProcedure

Procedure PrintPackingList(Spreadsheet, SheetTitle, Ref, TemplateName = Undefined) Export  
	
	SheetTitle = "Packing list";
	CustomTemplate = GeneralFunctions.GetCustomTemplate("Document.SalesInvoice", SheetTitle);
	
	If CustomTemplate = Undefined Then
		Template = Documents.SalesInvoice.GetTemplate("PF_MXL_PackingList");
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
   |		Product.UM AS UM,
   |		ProductDescription,
   |		LineItems.Order.RefNum AS PO,
   |		Quantity,
   |		Price,
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
   |	SalesInvoice.DocumentTotal,
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
	 While SelectionLineItems.Next() Do
		 
		 TemplateArea.Parameters.Fill(SelectionLineItems);
		 //TemplateArea.Parameters.PO = SelectionLineItems.PO;
		 //LineTotal = SelectionLineItems.LineTotal;
		 //LineTotalSum = LineTotalSum + LineTotal;
		 Spreadsheet.Put(TemplateArea, SelectionLineItems.Level());
		 
	 EndDo;
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
	
	If CustomTemplate = Undefined Then
		Template = Documents.SalesInvoice.GetTemplate("PF_MXL_PackingListDropship");
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
   |		Product.UM AS UM,
   |		ProductDescription,
   |		LineItems.Order.RefNum AS PO,
   |		Quantity,
   |		Price,
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
   |	SalesInvoice.DocumentTotal,
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
	 While SelectionLineItems.Next() Do
		 
		 TemplateArea.Parameters.Fill(SelectionLineItems);
		 Spreadsheet.Put(TemplateArea, SelectionLineItems.Level());
		 
	 EndDo;
	 
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
	|	Document.SalesInvoice.LineItems AS LineItems
	|WHERE
	|	LineItems.Ref = &Ref
	|	AND LineItems.Order <> VALUE(Document.SalesOrder.EmptyRef)
	|ORDER BY
	|	LineItems.Order.Date";
	
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
	|	                    CASE WHEN OrdersRegisteredBalance.Shipped - OrdersRegisteredBalance.Invoiced > 0
	|	                         THEN OrdersRegisteredBalance.Shipped - OrdersRegisteredBalance.Invoiced
	|	                         ELSE 0 END > 0
	|	               THEN LineItems.Quantity - 
	|	                    CASE WHEN OrdersRegisteredBalance.Shipped - OrdersRegisteredBalance.Invoiced > 0
	|	                         THEN OrdersRegisteredBalance.Shipped - OrdersRegisteredBalance.Invoiced
	|	                         ELSE 0 END
	|	               ELSE 0 END
	|	     ELSE 0 END                       AS Shipped,
	|	LineItems.Quantity                    AS Invoiced
	// ------------------------------------------------------
	// Attributes
	// ------------------------------------------------------
	|FROM
	|	Document.SalesInvoice.LineItems AS LineItems
	|	LEFT JOIN Table_OrdersRegistered_Balance AS OrdersRegisteredBalance
	|		ON  OrdersRegisteredBalance.Company      = LineItems.Ref.Company
	|		AND OrdersRegisteredBalance.Order        = LineItems.Order
	|		AND OrdersRegisteredBalance.Product      = LineItems.Product
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
	|	LineItems.Product                     AS Product
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
	|	OrdersRegisteredBalance.Company          AS Company,
	|	OrdersRegisteredBalance.Order            AS Order,
	|	OrdersRegisteredBalance.Product          AS Product,
	|	OrdersRegisteredBalance.Location         AS Location,
	|	OrdersRegisteredBalance.DeliveryDate     AS DeliveryDate,
	|	OrdersRegisteredBalance.Project          AS Project,
	|	OrdersRegisteredBalance.Class            AS Class,
	// ------------------------------------------------------
	// Resources
	|	OrdersRegisteredBalance.QuantityBalance  AS Quantity,
	|	OrdersRegisteredBalance.ShippedBalance   AS Shipped,
	|	OrdersRegisteredBalance.InvoicedBalance  AS Invoiced
	// ------------------------------------------------------
	|FROM
	|	AccumulationRegister.OrdersRegistered.Balance(&PointInTime,
	|		(Company, Order) IN
	|		(SELECT DISTINCT &Company, LineItems.Order // Requred for proper order closing
	|		 FROM Table_LineItems AS LineItems)) AS OrdersRegisteredBalance";
	
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
	|	SUM(LineItems.Quantity)                  AS QuantityRequested
	// ------------------------------------------------------
	|INTO
	|	Table_InventoryJournal_LineItems
	|FROM
	|	Document.SalesInvoice.LineItems AS LineItems
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
	|	SUM(LineItems.Quantity)                  AS QuantityRequested
	// ------------------------------------------------------
	|FROM
	|	Document.SalesInvoice.LineItems AS LineItems
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
	|	SUM(LineItems.Quantity)                  AS QuantityRequested
	// ------------------------------------------------------
	|FROM
	|	Document.SalesInvoice.LineItems AS LineItems
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
	|			THEN CAST ( // Format(Amount * QuantityExpense / Quantity, ""ND=15; NFD=2"")
	|				 Balance_FIFO.Amount * 
	|				(Balance_FIFO.Quantity + LineItems_FIFO.QuantityRequested - Balance_FIFO.QuantityCumulative) /
	|				 Balance_FIFO.Quantity
	|				 AS NUMBER (15, 2))
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
	|		ELSE CAST ( // Format(Amount / QuantityExpense / Quantity, ""ND=15; NFD=2"")
	|			 Balance_WAve.Amount * LineItems_WAve.QuantityRequested / Balance_WAve.Quantity
	|			 AS NUMBER (15, 2))
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
	|		ELSE CAST ( // Format(Amount / QuantityExpense / Quantity, ""ND=15; NFD=2"")
	|			 Balance_WAve.Amount * LineItems_WAve.QuantityRequested / Balance_WAve.Quantity
	|			 AS NUMBER (15, 2))
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

// Query for sales tax data
Function Query_SalesTaxOwed(TablesList)
	
	// Add SalesTaxOwed table to document structure.
	TablesList.Insert("Table_SalesTaxOwed", TablesList.Count());
	
	// Collect sales tax data.
	QueryText =
	"SELECT 
	// ------------------------------------------------------
	// Standard attributes
	|	SalesInvoice.Ref                         AS Recorder,
	|	SalesInvoice.Ref.Date                    AS Period,
	|	0                                        AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt)    AS RecordType,
	|	True                                     AS Active,
	// ------------------------------------------------------
	// Dimensions
	|	VALUE(Enum.AccountingMethod.Accrual)     AS ChargeType,
	|	SalesInvoice.Agency                      AS Agency,
	|	SalesInvoice.Rate                        AS TaxRate,
	|	SalesInvoice.SalesTaxComponent           AS SalesTaxComponent,
	// ------------------------------------------------------
	// Resources
	|	SalesInvoice.Ref.DocumentTotalRC - SalesInvoice.Ref.SalesTax
	|	                                         AS GrossSale,
	|	SalesInvoice.Ref.TaxableSubtotal         AS TaxableSale,
	|	SalesInvoice.Amount                      AS TaxPayable
	// ------------------------------------------------------
	// Attributes
	// ------------------------------------------------------
	|FROM
	|	Document.SalesInvoice.SalesTaxAcrossAgencies AS SalesInvoice
	|WHERE
	|	SalesInvoice.Ref = &Ref";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for sales tax to be posted in General Journal
Function Query_GeneralJournal_SalesTax(TablesList)
	
	// Add General Journal table to document structure.
	TablesList.Insert("Table_GeneralJournal", TablesList.Count());
	
	// Collect sales tax data.
	QueryText =
	"SELECT 
	// ------------------------------------------------------
	// Standard attributes
	|	SalesInvoice.Ref                         AS Recorder,
	|	SalesInvoice.Date                        AS Period,
	|	0                                        AS LineNumber,
	|	VALUE(AccountingRecordType.Credit)       AS RecordType,
	|	True                                     AS Active,
	|	VALUE(ChartOfAccounts.ChartOfAccounts.TaxPayable) AS Account,
	|	NULL                                     AS ExtDimensionTypeDr1,
	|	NULL                                     AS ExtDimensionTypeDr2,
	|	NULL                                     AS ExtDimensionDr1,
	|	NULL                                     AS ExtDimensionDr2,
	// ------------------------------------------------------
	// Dimensions
	|	VALUE(Catalog.Currencies.EmptyRef)       AS Currency,
	// ------------------------------------------------------
	// Resources
	|	0                                        AS Amount,
	|	SalesInvoice.SalesTax                    AS AmountRC,
	// ------------------------------------------------------
	// Attributes
	|	""""                                     AS Memo
	// ------------------------------------------------------
	|FROM
	|	Document.SalesInvoice AS SalesInvoice
	|WHERE
	|	SalesInvoice.Ref = &Ref";
	
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
		
	ElsIf AdditionalProperties.Posting.WriteMode = DocumentWriteMode.UndoPosting Then
		
		// No checks performed while unposting, it does not lead to decreasing the balance.
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
	|	OrdersRegisteredBalance.Product          AS Product,
	|	OrdersRegisteredBalance.Location         AS Location,
	|	OrdersRegisteredBalance.DeliveryDate     AS DeliveryDate,
	|	OrdersRegisteredBalance.Project          AS Project,
	|	OrdersRegisteredBalance.Class            AS Class,
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
	|	// (Company, Order) IN (SELECT Company, Order FROM Table_LineItems)
	|
	|UNION ALL
	|
	|SELECT
	// ------------------------------------------------------
	// Dimensions
	|	OrdersRegistered.Company,
	|	OrdersRegistered.Order,
	|	OrdersRegistered.Product,
	|	OrdersRegistered.Location,
	|	OrdersRegistered.DeliveryDate,
	|	OrdersRegistered.Project,
	|	OrdersRegistered.Class,
	// ------------------------------------------------------
	// Resources
	|	OrdersRegistered.Quantity,
	|	OrdersRegistered.Shipped,
	|	OrdersRegistered.Invoiced
	// ------------------------------------------------------
	|FROM
	|	Table_OrdersRegistered AS OrdersRegistered
	|	// Table_LineItems WHERE LineItems.Ref = &Ref AND Order <> EmptyRef()
	|";
	QueryText   = QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	QueryTables = QueryTables + 1;
	
	// Calculate final balance after posting the invoice.
	QueryText = QueryText +
	"SELECT
	// ------------------------------------------------------
	// Dimensions
	|	OrdersRegisteredBalance.Company          AS Company,
	|	OrdersRegisteredBalance.Order            AS Order,
	|	OrdersRegisteredBalance.Product          AS Product,
	|	OrdersRegisteredBalance.Product.Type     AS Type,
	|	OrdersRegisteredBalance.Location         AS Location,
	|	OrdersRegisteredBalance.DeliveryDate     AS DeliveryDate,
	|	OrdersRegisteredBalance.Project          AS Project,
	|	OrdersRegisteredBalance.Class            AS Class,
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
	|	OrdersRegisteredBalance.Product.Type,
	|	OrdersRegisteredBalance.Location,
	|	OrdersRegisteredBalance.DeliveryDate,
	|	OrdersRegisteredBalance.Project,
	|	OrdersRegisteredBalance.Class";
	QueryText   = QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	QueryTables = QueryTables + 1;
	
	// Calculate unshipped and uninvoiced items.
	QueryText = QueryText +
	"SELECT
	// ------------------------------------------------------
	// Dimensions
	|	OrdersRegisteredBalance.Company          AS Company,
	|	OrdersRegisteredBalance.Order            AS Order,
	|	OrdersRegisteredBalance.Product          AS Product,
	|	OrdersRegisteredBalance.Location         AS Location,
	|	OrdersRegisteredBalance.DeliveryDate     AS DeliveryDate,
	|	OrdersRegisteredBalance.Project          AS Project,
	|	OrdersRegisteredBalance.Class            AS Class,
	// ------------------------------------------------------
	// Resources
	|	CASE WHEN OrdersRegisteredBalance.Type = VALUE(Enum.InventoryTypes.Inventory)
	|	     THEN OrdersRegisteredBalance.Quantity - OrdersRegisteredBalance.Shipped
	|	     ELSE 0 END                          AS UnShipped,
	|	CASE WHEN OrdersRegisteredBalance.Type = VALUE(Enum.InventoryTypes.Inventory)
	|	     THEN OrdersRegisteredBalance.Shipped  - OrdersRegisteredBalance.Invoiced
	|	     WHEN OrdersRegisteredBalance.Type = VALUE(Enum.InventoryTypes.NonInventory)
	|	     THEN OrdersRegisteredBalance.Quantity - OrdersRegisteredBalance.Invoiced
	|	     ELSE 0 END                          AS UnInvoiced
	// ------------------------------------------------------
	|INTO
	|	OrdersRegistered_Balance_Unclosed
	|FROM
	|	OrdersRegistered_Balance_AfterWrite AS OrdersRegisteredBalance
	|WHERE
	|	CASE WHEN OrdersRegisteredBalance.Type = VALUE(Enum.InventoryTypes.Inventory)
	|	     THEN OrdersRegisteredBalance.Quantity - OrdersRegisteredBalance.Shipped
	|	     ELSE 0 END > 0
	|OR CASE WHEN OrdersRegisteredBalance.Type = VALUE(Enum.InventoryTypes.Inventory)
	|	     THEN OrdersRegisteredBalance.Shipped  - OrdersRegisteredBalance.Invoiced
	|	     WHEN OrdersRegisteredBalance.Type = VALUE(Enum.InventoryTypes.NonInventory)
	|	     THEN OrdersRegisteredBalance.Quantity - OrdersRegisteredBalance.Invoiced
	|	     ELSE 0 END > 0";
	QueryText   = QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	QueryTables = QueryTables + 1;
	
	// Determine orders having unclosed items in balance.
	QueryText = QueryText +
	"SELECT
	// ------------------------------------------------------
	// Dimensions
	|	OrdersRegisteredBalance.Order            AS Order,
	|	SUM(OrdersRegisteredBalance.UnShipped
	|	  + OrdersRegisteredBalance.UnInvoiced)  AS Unclosed
	// ------------------------------------------------------
	|INTO
	|	OrdersRegistered_Balance_Orders_Unclosed
	|FROM
	|	OrdersRegistered_Balance_Unclosed AS OrdersRegisteredBalance
	|GROUP BY
	|	OrdersRegisteredBalance.Order";
	QueryText   = QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	QueryTables = QueryTables + 1;
	
	// Calculate closed orders (those in invoice, which don't have unclosed items in theirs balance).
	QueryText = QueryText +
	"SELECT DISTINCT
	|	OrdersRegistered.Order AS Order
	|FROM
	|	Table_OrdersRegistered AS OrdersRegistered
	|	// Table_LineItems WHERE LineItems.Ref = &Ref AND Order <> EmptyRef()
	|	LEFT JOIN OrdersRegistered_Balance_Orders_Unclosed AS OrdersRegisteredBalanceUnclosed
	|		  ON  OrdersRegisteredBalanceUnclosed.Order = OrdersRegistered.Order
	|WHERE
	|	// No unclosed items
	|	ISNULL(OrdersRegisteredBalanceUnclosed.Unclosed, 0) = 0";
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
			
			// Set OrderStatus -> Closed.
			Row = Table_OrdersStatuses.Find(Selection.Order, "Order");
			If Not Row = Undefined Then
				Row.Status = Enums.OrderStatuses.Closed;
			EndIf;
		EndDo;
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
		|	SalesOrder.SalesTaxRate,
		|	SalesOrder.DiscountIsTaxable
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
		|		(Company, Order, Product, Location, DeliveryDate, Project, Class) IN
		|			(SELECT
		|				SalesOrderLineItems.Ref.Company,
		|				SalesOrderLineItems.Ref,
		|				SalesOrderLineItems.Product,
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
		|	SalesOrderLineItems.UM                  AS UM,
		|	SalesOrderLineItems.Price               AS Price,
		|	
		|	// Quantity
		|	CASE
		|		WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Open)
		|			THEN ISNULL(OrdersRegistered.Quantity, SalesOrderLineItems.Quantity)
		|		WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Backordered)
		|			THEN ISNULL(OrdersRegistered.Backorder, SalesOrderLineItems.Quantity)
		|		WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Closed)
		|			THEN ISNULL(OrdersRegistered.Backorder, 0)
		|		ELSE 0
		|	END                                     AS Quantity,
		|	
		|	// LineTotal
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
		|	
		|	// Discount
		|	CAST( // Format(Discount * LineTotal / Subtotal, ""ND=15; NFD=2"")
		|		CASE
		|			WHEN SalesOrderLineItems.Ref.LineSubtotal > 0 THEN
		|				SalesOrderLineItems.Ref.Discount *
		|				CASE // LineTotal = Quantity * Price
		|					WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Open)
		|						THEN ISNULL(OrdersRegistered.Quantity, SalesOrderLineItems.Quantity)
		|					WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Backordered)
		|						THEN ISNULL(OrdersRegistered.Backorder, SalesOrderLineItems.Quantity)
		|					WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Closed)
		|						THEN ISNULL(OrdersRegistered.Backorder, 0)
		|					ELSE 0
		|				END * SalesOrderLineItems.Price /
		|				SalesOrderLineItems.Ref.LineSubtotal
		|			ELSE 0
		|		END
		|		AS NUMBER (15, 2))                  AS Discount,
		|	
		|	// Taxable flag
		|	SalesOrderLineItems.Taxable             AS Taxable,
		|	
		|	// Taxable amount
		|	CAST( // Format(?(Taxable, LineTotal, 0), ""ND=15; NFD=2"")
		|		CASE
		|			WHEN SalesOrderLineItems.Taxable = True THEN
		|				CASE // Quantity * Price
		|					WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Open)
		|						THEN ISNULL(OrdersRegistered.Quantity, SalesOrderLineItems.Quantity)
		|					WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Backordered)
		|						THEN ISNULL(OrdersRegistered.Backorder, SalesOrderLineItems.Quantity)
		|					WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Closed)
		|						THEN ISNULL(OrdersRegistered.Backorder, 0)
		|					ELSE 0
		|				END * SalesOrderLineItems.Price
		|			ELSE 0
		|		END
		|		AS NUMBER (15, 2))                  AS TaxableAmount,
		|	
		|	// Tax amount
		|	CAST( // Format(TaxableAmount * TaxRate, ""ND=15; NFD=2"")
		|		// Taxable amount
		|		CASE
		|			WHEN SalesOrderLineItems.Taxable = True THEN
		|				CASE // LineTotal
		|					WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Open)
		|						THEN ISNULL(OrdersRegistered.Quantity, SalesOrderLineItems.Quantity)
		|					WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Backordered)
		|						THEN ISNULL(OrdersRegistered.Backorder, SalesOrderLineItems.Quantity)
		|					WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Closed)
		|						THEN ISNULL(OrdersRegistered.Backorder, 0)
		|					ELSE 0
		|				END * SalesOrderLineItems.Price
		|				+
		|				CASE // Discount
		|					WHEN SalesOrderLineItems.Ref.LineSubtotal > 0 THEN
		|						SalesOrderLineItems.Ref.Discount *
		|						CASE // LineTotal = Quantity * Price
		|							WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Open)
		|								THEN ISNULL(OrdersRegistered.Quantity, SalesOrderLineItems.Quantity)
		|							WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Backordered)
		|								THEN ISNULL(OrdersRegistered.Backorder, SalesOrderLineItems.Quantity)
		|							WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.Closed)
		|								THEN ISNULL(OrdersRegistered.Backorder, 0)
		|							ELSE 0
		|						END * SalesOrderLineItems.Price /
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
		|		AS NUMBER (15, 2))                  AS SalesTax,
		|	
		|	SalesOrderLineItems.Ref                 AS Order,
		|	SalesOrderLineItems.Location            AS Location,
		|	SalesOrderLineItems.Location            AS LocationActual,
		|	SalesOrderLineItems.DeliveryDate        AS DeliveryDate,
		|	SalesOrderLineItems.DeliveryDate        AS DeliveryDateActual,
		|	SalesOrderLineItems.Project             AS Project,
		|	SalesOrderLineItems.Class               AS Class,
		|	SalesOrderLineItems.Ref.Company         AS Company
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
		|		AND OrdersRegistered.Location     = SalesOrderLineItems.Location
		|		AND OrdersRegistered.DeliveryDate = SalesOrderLineItems.DeliveryDate
		|		AND OrdersRegistered.Project      = SalesOrderLineItems.Project
		|		AND OrdersRegistered.Class        = SalesOrderLineItems.Class
		|	LEFT JOIN Table_Document_SalesOrder_OrdersStatuses AS OrdersStatuses
		|		ON OrdersStatuses.Order = SalesOrderLineItems.Ref
		|WHERE
		|	SalesOrderLineItems.Ref IN (&FillingData_Document_SalesOrder)";
	
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
		|	// Format(SalesTax * ExchangeRate, ""ND=15; NFD=2"")
		|	CAST( // Format(SalesTax * ExchangeRate, ""ND=15; NFD=2"")
		|		SUM(SalesOrderLineItems.SalesTax) *
		|		SalesOrder.ExchangeRate
		|		AS NUMBER (15, 2))                  AS SalesTaxRC
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
		|	Document_SalesOrder_Attributes.ARAccount,
		|	Document_SalesOrder_Attributes.DueDate,
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
		|	Document_SalesOrder_Attributes.DiscountIsTaxable
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
		|	Document_SalesOrder_LineItems.Quantity,
		|	Document_SalesOrder_LineItems.UM,
		|	Document_SalesOrder_LineItems.Price,
		|	Document_SalesOrder_LineItems.LineTotal,
		|	Document_SalesOrder_LineItems.Taxable,
		|	Document_SalesOrder_LineItems.TaxableAmount,
		|	Document_SalesOrder_LineItems.Order,
		|	Document_SalesOrder_LineItems.Location,
		|	Document_SalesOrder_LineItems.LocationActual,
		|	Document_SalesOrder_LineItems.DeliveryDate,
		|	Document_SalesOrder_LineItems.DeliveryDateActual,
		|	Document_SalesOrder_LineItems.Project,
		|	Document_SalesOrder_LineItems.Class
		|{Into}
		|FROM
		|	Table_Document_SalesOrder_LineItems AS Document_SalesOrder_LineItems
		|WHERE
		|	Document_SalesOrder_LineItems.Quantity > 0";
		
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
	
	QueryText = "SELECT TOP 1
	            |	Table_Check.SalesTaxRate
	            |INTO CurrentSalesTaxRate
	            |FROM
	            |	Table_Check AS Table_Check
	            |;
	            |
	            |////////////////////////////////////////////////////////////////////////////////
	            |SELECT
	            |	SalesTaxRates.Agency,
	            |	SalesTaxRates.Rate AS Rate,
	            |	0 AS Amount
	            |INTO Table_SalesTaxAcrossAgencies
	            |FROM
	            |	CurrentSalesTaxRate AS CurrentSalesTaxRate
	            |		INNER JOIN Catalog.SalesTaxRates AS SalesTaxRates
	            |		ON (CurrentSalesTaxRate.SalesTaxRate = SalesTaxRates.Ref
	            |				OR CurrentSalesTaxRate.SalesTaxRate = SalesTaxRates.Parent)
	            |			AND (SalesTaxRates.CombinedTaxRate = FALSE)";
	
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
	CheckAttributes.Insert("DocumentTotalRC",    "CAST( // Format(DocumentTotal * ExchangeRate, ""ND=15; NFD=2"")
	                                             |		(SUM(Attributes.SubTotal) + MAX(Attributes.Shipping) + SUM(Attributes.SalesTax)) *
	                                             |		Attributes.ExchangeRate
	                                             |		AS NUMBER (15, 2))");
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


//------------------------------------------------------------------------------
// Document printing

#EndIf

#EndRegion