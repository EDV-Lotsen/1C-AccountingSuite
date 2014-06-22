
////////////////////////////////////////////////////////////////////////////////
// Sales return: Manager module
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
		             Query_InventoryJournal_Lock(LocksList) +
		             Query_ItemLastCosts_Lock(LocksList);
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
		             Query_InventoryJournal_Balance(BalancesList) +
		             Query_ItemLastCosts_SliceLast(BalancesList);
		
		// Reuse locked inventory items & items last costs list.
		DocumentPosting.PutTemporaryTable(QueryResult[LocksList.AccumulationRegister_InventoryJournal].Unload(),
		                                  "Table_InventoryJournal_Lock", Query.TempTablesManager);
		DocumentPosting.PutTemporaryTable(QueryResult[LocksList.InformationRegister_ItemLastCosts].Unload(),
		                                  "Table_ItemLastCosts_Lock", Query.TempTablesManager);
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
	If InventoryPosting Then
		Query.Text = Query.Text +
		             Query_InventoryJournal_LineItems(TablesList) +
		             Query_InventoryJournal_Balance_Quantity(TablesList) +
		             Query_InventoryJournal(TablesList);
	EndIf;
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

// -> CODE REVIEW
Procedure Print(Spreadsheet, Ref) Export
		
	CustomTemplate = GeneralFunctions.GetCustomTemplate("Document.SalesReturn", "Credit memo");
	
	If CustomTemplate = Undefined Then
		Template = Documents.SalesReturn.GetTemplate("PF_MXL_SalesReturn");
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
   |	SalesReturn.Ref,
   |	SalesReturn.Company,
   |	SalesReturn.Date,
   |	SalesReturn.DocumentTotal,
   |	SalesReturn.SalesTaxRC,
   |	SalesReturn.ReturnType,
   |	SalesReturn.ParentDocument,
   |	SalesReturn.RefNum,
   |	SalesReturn.Number,
   |	SalesReturn.Currency,
   //|	SalesReturn.PriceIncludesVAT,
   //|	SalesReturn.VATTotal,
   |	SalesReturn.LineItems.(
   |		Product,
   |		Product.UM AS UM,
   |		ProductDescription,
   |		Quantity,
   //|		VATCode,
   //|		VAT,
   |		Price,
   |		LineTotal
   |	),
   |	SalesReturn.DueDate,
   |	GeneralJournalBalance.AmountRCBalance AS Balance
   |FROM
   |	AccountingRegister.GeneralJournal.Balance AS GeneralJournalBalance
   |		RIGHT JOIN Document.SalesReturn AS SalesReturn
   |		ON (GeneralJournalBalance.ExtDimension1 = SalesReturn.Company
   |			AND GeneralJournalBalance.ExtDimension2 = SalesReturn.Ref)
   |WHERE
   |	SalesReturn.Ref IN(&Ref)";
   Query.SetParameter("Ref", Ref);
   Selection = Query.Execute().Select();
   
   Spreadsheet.Clear();
   //InsertPageBreak = False;
   While Selection.Next() Do
	   
	BinaryLogo = GeneralFunctions.GetLogo();
	MyPicture = New Picture(BinaryLogo);
	Pict=Template.Drawings.Add(SpreadsheetDocumentDrawingType.Picture);
	IndexOf=Template.Drawings.IndexOf(Pict);
	Template.Drawings[IndexOf].Picture = MyPicture;
	Template.Drawings[IndexOf].Line = New Line(SpreadsheetDocumentDrawingLineType.None);
	Template.Drawings[IndexOf].Place(Spreadsheet.Area("R3C1:R6C2"));
	   
	   
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
	
 Query = New Query();
   Query.Text =
   "SELECT
   |	SalesReturn.Ref,
   |	SalesReturn.Company,
   |	SalesReturn.Date,
   |	SalesReturn.DocumentTotal,
   |	SalesReturn.SalesTaxRC,
   |	SalesReturn.ReturnType,
   |	SalesReturn.ParentDocument,
   |	SalesReturn.RefNum,
   |	SalesReturn.Number,
   |	SalesReturn.Currency,
   //|	SalesReturn.PriceIncludesVAT,
   //|	SalesReturn.VATTotal,
   |	SalesReturn.LineItems.(
   |		Product,
   |		Product.UM AS UM,
   |		ProductDescription,
   |		Quantity,
   //|		VATCode,
   //|		VAT,
   |		Price,
   |		LineTotal
   |	),
   |	SalesReturn.DueDate,
   |	GeneralJournalBalance.AmountRCBalance AS Balance
   |FROM
   |	AccountingRegister.GeneralJournal.Balance AS GeneralJournalBalance
   |		RIGHT JOIN Document.SalesReturn AS SalesReturn
   |		ON (GeneralJournalBalance.ExtDimension1 = SalesReturn.Company
   |			AND GeneralJournalBalance.ExtDimension2 = SalesReturn.Ref)
   |WHERE
   |	SalesReturn.Ref IN(&Ref)";
   Query.SetParameter("Ref", Ref);
   Test = Query.Execute().Select();
	 
	TemplateArea = Template.GetArea("Header");
	  		
	UsBill = PrintTemplates.ContactInfoDatasetUs();
	//ThemShip = PrintTemplates.ContactInfoDataset(Selection.Company, "ThemShip", Selection.ShipTo);
	
	Query = New Query;
		Query.Text =
		"SELECT
		|	Addresses.Ref
		|FROM
		|	Catalog.Addresses AS Addresses
		|WHERE
		|	Addresses.Owner = &Owner
		|	AND Addresses.DefaultBilling = &True";
	Query.Parameters.Insert("Owner", Selection.Company);
	Query.Parameters.Insert("True", True);
	BillAddr = Query.Execute().Unload();
	If BillAddr.Count() > 0 Then
		ThemBill = PrintTemplates.ContactInfoDataset(Selection.Company, "ThemBill", BillAddr[0].Ref);
	Else
		ThemBill = PrintTemplates.ContactInfoDataset(Selection.Company, "ThemBill",Catalogs.Addresses.EmptyRef());
	EndIf;

	
	TemplateArea.Parameters.Fill(UsBill);
	//TemplateArea.Parameters.Fill(ThemShip);
	TemplateArea.Parameters.Fill(ThemBill);
	
	  //  TemplateArea = Template.GetArea("Footer");
	  //  OurContactInfo = UsBill.UsName + " - " + UsBill.UsBillLine1Line2 + " - " + UsBill.UsBillCityStateZIP + " - " + UsBill.UsBillPhone;
	  //  TemplateArea.Parameters.OurContactInfo = OurContactInfo;
	  //Spreadsheet.Put(TemplateArea);

	
	
	 TemplateArea.Parameters.Date = Selection.Date;
	 TemplateArea.Parameters.Number = Selection.Number;
	 TemplateArea.Parameters.RMA = Selection.RefNum;
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
		 CompanyName = Selection.Company.Description;
		 CompanyNameLen = StrLen(CompanyName);
		 Try
			 If NOT SelectionLineItems.Project = "" Then
				ProjectLen = StrLen(SelectionLineItems.Project);
			 	TemplateArea.Parameters.Project = Right(SelectionLineItems.Project, ProjectLen - CompanyNameLen - 2);
			EndIf;
		Except
		EndTry;
		 //TemplateArea.Parameters.PO = SelectionLineItems.PO;
		 LineTotal = SelectionLineItems.LineTotal;
		 LineTotalSum = LineTotalSum + LineTotal;
		 Spreadsheet.Put(TemplateArea, SelectionLineItems.Level());
		 
	 EndDo;
	 //////   sales tax check
	//If Selection.SalesTax <> 0 Then;
		 TemplateArea = Template.GetArea("Subtotal");
		 TemplateArea.Parameters.Subtotal = LineTotalSum;
		 Spreadsheet.Put(TemplateArea);
		 
		 TemplateArea = Template.GetArea("SalesTax");
		 TemplateArea.Parameters.SalesTaxTotal = Selection.SalesTaxRC;
		 Spreadsheet.Put(TemplateArea);
	//EndIf; 
	  ////////
	 
	//If Selection.VATTotal <> 0 Then;
	//	 TemplateArea = Template.GetArea("Subtotal");
	//	 TemplateArea.Parameters.Subtotal = LineTotalSum;
	//	 Spreadsheet.Put(TemplateArea);
	//	 
	//	 TemplateArea = Template.GetArea("VAT");
	//	 TemplateArea.Parameters.VATTotal = Selection.VATTotal;
	//	 Spreadsheet.Put(TemplateArea);
	//EndIf; 
		 
	 TemplateArea = Template.GetArea("Total");
	 //If Selection.PriceIncludesVAT Then
	 	DTotal = LineTotalSum + Selection.SalesTaxRC;
	//Else
	//	DTotal = LineTotalSum + Selection.VATTotal;
	//EndIf;
	TemplateArea.Parameters.DocumentTotal = DTotal;
	Spreadsheet.Put(TemplateArea);
	
	//TemplateArea = Template.GetArea("Credits");
	//If NOT Selection.Balance = NULL Then
	//	TemplateArea.Parameters.Credits = DTotal - Selection.Balance;
	//ElsIf Selection.Ref.Posted = FALSE Then
	//	TemplateArea.Parameters.Credits = 0;
	//Else
	//	TemplateArea.Parameters.Credits = DTotal;
	//EndIf;
	//Spreadsheet.Put(TemplateArea);
	//
	//TemplateArea = Template.GetArea("Balance");
	//If NOT Selection.Balance = NULL Then
	//	TemplateArea.Parameters.Balance = Selection.Balance;
	//Else
	//	TemplateArea.Parameters.Balance = 0;
	//EndIf;
	//Spreadsheet.Put(TemplateArea);
	 
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
	 
	TemplateArea = Template.GetArea("EmptySpace");
	Spreadsheet.Put(TemplateArea);

	 
	 TemplateArea = Template.GetArea("Footer");
	 TemplateArea.Parameters.FooterContents = Constants.SalesInvoiceFooter.Get();
	Spreadsheet.Put(TemplateArea);
	 
	Spreadsheet.ВывестиГоризонтальныйРазделительСтраниц();

	 
   EndDo;
   
   //Return SpreadsheetDocument;
   
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
	|	LineItems.Ref.Location                   AS Location,
	// ------------------------------------------------------
	// Agregates
	|	SUM(LineItems.Quantity)                  AS QuantityRequested
	// ------------------------------------------------------
	|INTO
	|	Table_InventoryJournal_LineItems
	|FROM
	|	Document.SalesReturn.LineItems           AS LineItems
	|WHERE
	|	    LineItems.Ref                   = &Ref
	|	AND LineItems.Product.Type          = VALUE(Enum.InventoryTypes.Inventory)
	|	AND LineItems.Product.CostingMethod = VALUE(Enum.InventoryCosting.FIFO)
	|GROUP BY
	|	LineItems.Product.CostingMethod,
	|	LineItems.Product,
	|	LineItems.Ref.Location
	|
	|UNION ALL
	|
	|SELECT // WAve for quantity calcualtion
	// ------------------------------------------------------
	// Dimensions
	|	LineItems.Product.CostingMethod          AS Type,
	|	LineItems.Product                        AS Product,
	|	LineItems.Ref.Location                   AS Location,
	// ------------------------------------------------------
	// Agregates
	|	SUM(LineItems.Quantity)                  AS QuantityRequested
	// ------------------------------------------------------
	|FROM
	|	Document.SalesReturn.LineItems           AS LineItems
	|WHERE
	|	    LineItems.Ref                   = &Ref
	|	AND LineItems.Product.Type          = VALUE(Enum.InventoryTypes.Inventory)
	|	AND LineItems.Product.CostingMethod = VALUE(Enum.InventoryCosting.WeightedAverage)
	|GROUP BY
	|	LineItems.Product.CostingMethod,
	|	LineItems.Product,
	|	LineItems.Ref.Location
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
	|	Document.SalesReturn.LineItems           AS LineItems
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
	
	// Add InventoryJournal balance table to document structure.
	TablesList.Insert("Table_InventoryJournal_Balance_Quantity", TablesList.Count());
	
	// Collect inventory data.
	QueryText =
	"SELECT // WAve for amount calcualtion
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
	|INTO
	|	Table_InventoryJournal_Balance_Quantity
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
Function Query_InventoryJournal(TablesList)
	
	// Add InventoryJournal table to document structure.
	TablesList.Insert("Table_InventoryJournal", TablesList.Count());
	
	// Collect inventory data.
	QueryText =
	"SELECT // FIFO
	// ------------------------------------------------------
	// Standard attributes
	|	SalesReturn.Ref                       AS Recorder,
	|	SalesReturn.Date                      AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Dimensions
	|	LineItems_FIFO.Product                AS Product,
	|	LineItems_FIFO.Location               AS Location,
	|	SalesReturn.Ref                       AS Layer,
	// ------------------------------------------------------
	// Resources
	|	LineItems_FIFO.QuantityRequested      AS Quantity,
	|	CAST ( // Format(LastCost * QuantityRequested, ""ND=15; NFD=2"")
	|		 ItemLastCosts.Cost * LineItems_FIFO.QuantityRequested
	|		 AS NUMBER (15, 2))               AS Amount
	// ------------------------------------------------------
	// Attributes
	// ------------------------------------------------------
	|FROM
	|	Table_InventoryJournal_LineItems AS LineItems_FIFO
	|	LEFT JOIN Table_ItemLastCosts_SliceLast AS ItemLastCosts
	|		ON  ItemLastCosts.Product = LineItems_FIFO.Product
	|	LEFT JOIN Document.SalesReturn AS SalesReturn
	|		ON True
	|WHERE
	|	SalesReturn.Ref = &Ref
	|	AND LineItems_FIFO.Type = VALUE(Enum.InventoryCosting.FIFO)
	|	AND LineItems_FIFO.QuantityRequested > 0
	|
	|UNION ALL
	|
	|SELECT // WeightedAverage by quantity
	// ------------------------------------------------------
	// Standard attributes
	|	SalesReturn.Ref                       AS Recorder,
	|	SalesReturn.Date                      AS Period,
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
	|	LEFT JOIN Document.SalesReturn AS SalesReturn
	|		ON True
	|WHERE
	|	SalesReturn.Ref = &Ref
	|	AND LineItems_WAve.Type      = VALUE(Enum.InventoryCosting.WeightedAverage)
	|	AND LineItems_WAve.Location <> VALUE(Catalog.Locations.EmptyRef)
	|	AND LineItems_WAve.QuantityRequested > 0
	|
	|UNION ALL
	|
	|SELECT // WeightedAverage by amount
	// ------------------------------------------------------
	// Standard attributes
	|	SalesReturn.Ref                       AS Recorder,
	|	SalesReturn.Date                      AS Period,
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
	|	CASE
	|		WHEN ISNULL(Balance_WAve.Quantity, 0) > 0
	|		// The balance is still active.
	|		THEN CAST ( // Format(Amount * QuantityReceipt / Quantity, ""ND=15; NFD=2"")
	|			 ISNULL(Balance_WAve.Amount, 0) * LineItems_WAve.QuantityRequested / Balance_WAve.Quantity
	|			 AS NUMBER (15, 2))
	|		ELSE CAST ( // Format(LastCost * QuantityRequested, ""ND=15; NFD=2"")
	|			 ItemLastCosts.Cost * LineItems_WAve.QuantityRequested
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
	|	LEFT JOIN Table_ItemLastCosts_SliceLast AS ItemLastCosts
	|		ON  ItemLastCosts.Product = LineItems_WAve.Product
	|	LEFT JOIN Document.SalesReturn AS SalesReturn
	|		ON True
	|WHERE
	|	SalesReturn.Ref = &Ref
	|	AND LineItems_WAve.Type     = VALUE(Enum.InventoryCosting.WeightedAverage)
	|	AND LineItems_WAve.Location = VALUE(Catalog.Locations.EmptyRef)
	|	AND // Amount > 0
	|	CASE
	|		WHEN ISNULL(Balance_WAve.Quantity, 0) > 0
	|		// The balance is still active.
	|		THEN CAST ( // Format(Amount * QuantityReceipt / Quantity, ""ND=15; NFD=2"")
	|			 ISNULL(Balance_WAve.Amount, 0) * LineItems_WAve.QuantityRequested / Balance_WAve.Quantity
	|			 AS NUMBER (15, 2))
	|		ELSE CAST ( // Format(LastCost * QuantityRequested, ""ND=15; NFD=2"")
	|			 ItemLastCosts.Cost * LineItems_WAve.QuantityRequested
	|			 AS NUMBER (15, 2))
	|	END > 0";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for dimensions lock data.
Function Query_InventoryJournal_Lock(TablesList)
	
	// Add InventoryJournal - Add table to locks structure.
	TablesList.Insert("AccumulationRegister_InventoryJournal", TablesList.Count());
	
	// Collect dimensions for inventory journal locking.
	QueryText =
	"SELECT DISTINCT // WeightedAverage by quantity & amount
	// ------------------------------------------------------
	// Dimensions
	|	LineItems.Product                     AS Product
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
	"SELECT // WAve by quantity and amount
	// ------------------------------------------------------
	// Dimensions
	|	InventoryJournalBalance.Product.CostingMethod
	|	                                         AS Type,
	|	InventoryJournalBalance.Product          AS Product,
	|	InventoryJournalBalance.Location         AS Location,
	|	CASE // Type definition for layer field.
	|		WHEN InventoryJournalBalance.Product.CostingMethod = VALUE(Enum.InventoryCosting.FIFO)
	|		THEN InventoryJournalBalance.Layer
	|		ELSE NULL
	|	END                                      AS Layer,
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

// Query for dimensions lock data.
Function Query_ItemLastCosts_Lock(TablesList)
	
	// Add ItemLastCosts - Add table to locks structure.
	TablesList.Insert("InformationRegister_ItemLastCosts", TablesList.Count());
	
	// Collect dimensions for items last cost locking.
	QueryText =
	"SELECT DISTINCT
	// ------------------------------------------------------
	// Dimensions
	|	LineItems.Product                     AS Product
	// ------------------------------------------------------
	|FROM
	|	Table_LineItems AS LineItems
	|WHERE
	|	LineItems.Product.Type = VALUE(Enum.InventoryTypes.Inventory)";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for balances data.
Function Query_ItemLastCosts_SliceLast(TablesList)
	
	// Add ItemLastCosts - SliceLast table to balances structure.
	TablesList.Insert("Table_ItemLastCosts_SliceLast", TablesList.Count());
	
	// Collect items last cost last state.
	QueryText =
	"SELECT
	// ------------------------------------------------------
	// Dimensions
	|	ItemLastCosts.Product                    AS Product,
	// ------------------------------------------------------
	// Resources
	|	ItemLastCosts.Cost                       AS Cost
	// ------------------------------------------------------
	// Attributes
	// ------------------------------------------------------
	|FROM
	|	InformationRegister.ItemLastCosts.SliceLast(&PointInTime,
	|		(Product) IN (SELECT Product FROM Table_ItemLastCosts_Lock))
	|		                                     AS ItemLastCosts";
	
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

//Query for Sales Tax
Function Query_SalesTaxOwed(TablesList)
	// Add SalesTaxOwed table to document structure.
	TablesList.Insert("Table_SalesTaxOwed", TablesList.Count());
	
	// Collect sales tax data.
	QueryText =
	"SELECT
	|	SalesReturn.Ref AS Recorder,
	|	SalesReturn.Ref.Date AS Period,
	|	0 AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	TRUE AS Active,
	|	AccountingMethod.Ref AS ChargeType,
	|	SalesReturn.Agency AS Agency,
	|	SalesReturn.Rate AS TaxRate,
	|	SalesReturn.SalesTaxComponent AS SalesTaxComponent,
	|	-1 * (SalesReturn.Ref.DocumentTotalRC - SalesReturn.Ref.SalesTaxRC) AS GrossSale,
	|	-1 * SalesReturn.Ref.TaxableSubtotal AS TaxableSale,
	|	-1 * SalesReturn.Amount AS TaxPayable
	|FROM
	|	Document.SalesReturn.SalesTaxAcrossAgencies AS SalesReturn
	|		LEFT JOIN Enum.AccountingMethod AS AccountingMethod
	|		ON (CASE
	|				WHEN SalesReturn.Ref.ReturnType = VALUE(Enum.ReturnTypes.CreditMemo)
	|					THEN AccountingMethod.Ref = VALUE(Enum.AccountingMethod.Accrual)
	|				ELSE TRUE
	|			END)
	|WHERE
	|	SalesReturn.Ref = &Ref";
		
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
		
EndFunction

//Query for Sales Tax in the General Journal
//Function Query_SalesTax_GeneralJournal(TablesList)
//	// Add GeneralJournal table to document structure.
//	TablesList.Insert("Table_GeneralJournal", TablesList.Count());
//	
//	// Collect sales tax data.
//	QueryText =
//	"SELECT 
//	// ------------------------------------------------------
//	// Standard attributes
//	|	SalesReturn.Ref                      AS Recorder,
//	|	SalesReturn.Date                     AS Period,
//	|	0                                     AS LineNumber,
//	|	VALUE(AccountingRecordType.Credit) AS RecordType,
//	|	True                                  AS Active,
//	|	VALUE(ChartOfAccounts.ChartOfAccounts.TaxPayable) AS Account,
//	// ------------------------------------------------------
//	// Dimensions
//	// ------------------------------------------------------
//	// Resources
//	|	-1 * SalesReturn.SalesTaxRC AS AmountRC
//	// ------------------------------------------------------
//	// Attributes
//	// ------------------------------------------------------
//	|FROM
//	|	Document.SalesReturn AS SalesReturn
//	|WHERE
//	|	SalesReturn.Ref = &Ref";
//	
//	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
//		
//EndFunction

//------------------------------------------------------------------------------
// Document filling

//------------------------------------------------------------------------------
// Document printing

#EndIf

#EndRegion

