
////////////////////////////////////////////////////////////////////////////////
// Sales Order: Manager module
//------------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
#Region EVENTS_HANDLERS

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	
	StandardProcessing = False;
	
	Presentation = "SO #" + Data.Number + " " + Format(Data.Date, "DLF=D"); 
	
EndProcedure

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region PUBLIC_INTERFACE

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

//------------------------------------------------------------------------------
// Document posting

// Collect document data for posting on the server.
Function PrepareDataStructuresForPosting(DocumentRef, AdditionalProperties, RegisterRecords) Export
	
	// Create list of posting tables (according to the list of registers).
	TablesList = New Structure;
	
	// Create a query to request document data.
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	
	// Query for document's tables.
	Query.Text  = Query_OrdersStatuses(TablesList) +
	              Query_OrdersRegistered(TablesList);
	QueryResult = Query.ExecuteBatch();
	
	// Save documents table in posting parameters.
	For Each DocumentTable In TablesList Do
		ResultTable = QueryResult[DocumentTable.Value].Unload();
		If Not DocumentPosting.IsTemporaryTable(ResultTable) Then
			AdditionalProperties.Posting.PostingTables.Insert(DocumentTable.Key, ResultTable);
		EndIf;
	EndDo;
	
	// Clear used temporary tables manager.
	Query.TempTablesManager.Close();
	
	// Fill list of registers to check (non-negative) balances in posting parameters.
	FillRegistersCheckList(AdditionalProperties, RegisterRecords);
	
EndFunction

// Collect document data for clearing posting on the server.
Function PrepareDataStructuresForPostingClearing(DocumentRef, AdditionalProperties, RegisterRecords) Export
	
	// Fill list of registers to check (non-negative) balances in posting parameters.
	FillRegistersCheckList(AdditionalProperties, RegisterRecords);
	
EndFunction

#EndIf

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region COMMANDS_HANDLERS

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

//------------------------------------------------------------------------------
// Document printing

// -> CODE REVIEW
Procedure Print(Spreadsheet, SheetTitle, Ref, TemplateName = Undefined) Export
	PrintFormFunctions.PrintSO(Spreadsheet, SheetTitle, Ref, TemplateName);
EndProcedure

Procedure PrintQuote(Spreadsheet, SheetTitle, Ref, TemplateName = Undefined) Export
	
	SheetTitle = "Sales quote";
	CustomTemplate = GeneralFunctions.GetCustomTemplate("Document.SalesOrder", SheetTitle);
	
	If CustomTemplate = Undefined Then
		Template = Documents.SalesOrder.GetTemplate("PF_MXL_SalesQuote");
	Else
		Template = CustomTemplate;
	EndIf;

	
	//Template = Documents.SalesOrder.GetTemplate("PF_MXL_SalesQuote");
	
	// Create a spreadsheet document and set print parameters.
  // SpreadsheetDocument = New SpreadsheetDocument;
  // SpreadsheetDocument.PrintParametersName = "PrintParameters_SalesOrder";

   // Quering necessary data.
   Query = New Query();
   Query.Text =
   "SELECT
   |	SalesOrder.Ref,
   |	SalesOrder.Company,
   |	SalesOrder.Date,
   |	SalesOrder.DocumentTotal,
   |	SalesOrder.SalesTax,
   |	SalesOrder.Number,
   |	SalesOrder.ShipTo,
   |	SalesOrder.Currency,
   |	SalesOrder.LineItems.(
   |		Product,
   |		ProductDescription,
   |		Unit AS UM,
   |		QtyUnits AS Quantity,
   |		PriceUnits AS Price,
   |		LineTotal
   |	),
   |	SalesOrder.BillTo,
   |	SalesOrder.LineSubtotal,
   |	SalesOrder.Discount,
   |	SalesOrder.SubTotal,
   |	SalesOrder.Shipping,
   |	SalesOrder.DocumentTotal,
   |	SalesOrder.DropshipCompany,
   |	SalesOrder.DropshipShipTo
   |FROM
   |	Document.SalesOrder AS SalesOrder
   |WHERE
   |	SalesOrder.Ref IN(&Ref)";
   Query.SetParameter("Ref", Ref);
   Selection = Query.Execute().Select();
  
   Spreadsheet.Clear();
   
   InsertPageBreak = False;
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

	 
	//Template = PrintManagement.GetTemplate("Document.SalesOrder.PF_MXL_SalesOrder");
	 
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
	 
	 TemplateArea.Parameters.Date = Selection.Date;
	 TemplateArea.Parameters.Number = Selection.Number;
	 
	 Spreadsheet.Put(TemplateArea);

	 TemplateArea = Template.GetArea("LineItemsHeader");
	 Spreadsheet.Put(TemplateArea);
	 
	 SelectionLineItems = Selection.LineItems.Select();
	 TemplateArea = Template.GetArea("LineItems");
	 //LineTotalSum = 0;
	 While SelectionLineItems.Next() Do
		 
		 TemplateArea.Parameters.Fill(SelectionLineItems);
		 LineTotal = SelectionLineItems.LineTotal;
		 //LineTotalSum = LineTotalSum + LineTotal;
		 Spreadsheet.Put(TemplateArea, SelectionLineItems.Level());
		 
	 EndDo;
	 
		TemplateArea = Template.GetArea("LineSubtotal");
		TemplateArea.Parameters.LineSubtotal = Selection.LineSubtotal;

		 Spreadsheet.Put(TemplateArea);
		 
		TemplateArea = Template.GetArea("Discount");
		TemplateArea.Parameters.Discount = Selection.Discount;
		 Spreadsheet.Put(TemplateArea);

	
		TemplateArea = Template.GetArea("SubTotal");
		 TemplateArea.Parameters.Subtotal = Selection.SubTotal;
		 Spreadsheet.Put(TemplateArea);
		 
		 TemplateArea = Template.GetArea("Shipping");
		 TemplateArea.Parameters.Shipping = Selection.Shipping;


		 Spreadsheet.Put(TemplateArea);


		 
		 TemplateArea = Template.GetArea("SalesTax");
		 TemplateArea.Parameters.SalesTax = Selection.SalesTax;
		 Spreadsheet.Put(TemplateArea);
		 
		 TemplateArea = Template.GetArea("Total");
		 TemplateArea.Parameters.TotalCur = "Total " + Selection.Currency.Symbol;
		 TemplateArea.Parameters.Total = Selection.DocumentTotal;
		 Spreadsheet.Put(TemplateArea); 
		 
			
	//Try
	// 	TemplateArea = Template.GetArea("Footer");
	//	OurContactInfo = UsBill.UsName + " - " + UsBill.UsBillLine1Line2 + " - " + UsBill.UsBillCityStateZIP + " - " + UsBill.UsBillPhone;
	//	TemplateArea.Parameters.OurContactInfo = OurContactInfo;
	// 	Spreadsheet.Put(TemplateArea);
	// Except
	//EndTry;


	 //Spreadsheet.Put(TemplateArea);

	 
     // Setting a print area in the spreadsheet document where to output the object.
     // Necessary for kit printing. 
     //PrintManagement.SetDocumentPrintArea(SpreadsheetDocument, BeginningLineNumber, PrintObjects, Selection.Ref);

	 InsertPageBreak = True;
	 
   EndDo;
   
   //Return SpreadsheetDocument;
   
EndProcedure

Procedure PickList(Spreadsheet, Ref) Export
	
	Template = Documents.SalesOrder.GetTemplate("PickList");

	QuantityFormat = GeneralFunctionsReusable.DefaultQuantityFormat();
	Header = Template.GetArea("Header");
	AreaHeader_1 = Template.GetArea("Header_1");

	AreaLineItems = Template.GetArea("LineItems");
	AreaLineItems_1 = Template.GetArea("LineItems_1");
	Spreadsheet.Clear();

	InsertPageBreak = False;
	For Each RefLine In Ref Do
		
		If InsertPageBreak Then
			Spreadsheet.PutHorizontalPageBreak();
		EndIf;

		//Header
		Parameters = New Structure;
		Parameters.Insert("Company", RefLine.Company);
		Parameters.Insert("Date", RefLine.Date);
		Parameters.Insert("Number", RefLine.Number);
		
		If ValueIsFilled(RefLine.DropshipShipTo) Then
			ThemShip = PrintTemplates.ContactInfoDataset(RefLine.DropshipCompany, "ThemShip", RefLine.DropshipShipTo);
		Else
			ThemShip = PrintTemplates.ContactInfoDataset(RefLine.Company, "ThemShip", RefLine.ShipTo);
		EndIf;
		
 		Parameters.Insert("ThemShipName", ThemShip.ThemShipName);
 		Parameters.Insert("ThemShipLine1", ?(ValueIsFilled(ThemShip.ThemShipLine1), ThemShip.ThemShipLine1 + Chars.LF, ""));
 		Parameters.Insert("ThemShipLine2", ?(ValueIsFilled(ThemShip.ThemShipLine2), ThemShip.ThemShipLine2 + Chars.LF, ""));
 		Parameters.Insert("ThemShipLine3", ?(ValueIsFilled(ThemShip.ThemShipLine3), ThemShip.ThemShipLine3 + Chars.LF, ""));
 		Parameters.Insert("ThemShipCityStateZIP", ThemShip.ThemShipCityStateZIP);
		
		Header.Parameters.Fill(Parameters);
		Spreadsheet.Put(Header);

		//LineItems
		Query = New Query;
		Query.Text = "SELECT
		             |	SalesOrderLineItems.Product AS Item,
		             |	SalesOrderLineItems.ProductDescription AS Description,
		             |	SalesOrderLineItems.Location AS Warehouse,
		             |	SalesOrderLineItems.DeliveryDate AS ShipDate,
		             |	CASE
		             |		WHEN OrdersStatusesSliceLast.Status = VALUE(Enum.OrderStatuses.Open)
		             |			THEN OrdersRegisteredBalance.QuantityBalance
		             |		WHEN OrdersStatusesSliceLast.Status = VALUE(Enum.OrderStatuses.Backordered)
		             |				AND OrdersRegisteredBalance.QuantityBalance > OrdersRegisteredBalance.ShippedBalance
		             |			THEN OrdersRegisteredBalance.QuantityBalance - OrdersRegisteredBalance.ShippedBalance
		             |		ELSE 0
		             |	END AS Needed,
		             |	CASE
		             |		WHEN OrdersStatusesSliceLast.Status = VALUE(Enum.OrderStatuses.Open)
		             |			THEN OrdersRegisteredBalance.QuantityBalance * SalesOrderLineItems.Unit.Factor
		             |		WHEN OrdersStatusesSliceLast.Status = VALUE(Enum.OrderStatuses.Backordered)
		             |				AND OrdersRegisteredBalance.QuantityBalance > OrdersRegisteredBalance.ShippedBalance
		             |			THEN (OrdersRegisteredBalance.QuantityBalance - OrdersRegisteredBalance.ShippedBalance) * SalesOrderLineItems.Unit.Factor
		             |		ELSE 0
		             |	END AS NeededBaseUM,
		             |	SalesOrderLineItems.Unit AS Unit,
		             |	ISNULL(InventoryJournalBalance.QuantityBalance, 0) AS ToPick,
		             |	Units.Code AS AbbreviationBaseUM
		             |FROM
		             |	Document.SalesOrder.LineItems AS SalesOrderLineItems
		             |		LEFT JOIN InformationRegister.OrdersStatuses.SliceLast AS OrdersStatusesSliceLast
		             |		ON SalesOrderLineItems.Ref = OrdersStatusesSliceLast.Order
		             |		LEFT JOIN AccumulationRegister.OrdersRegistered.Balance AS OrdersRegisteredBalance
		             |		ON SalesOrderLineItems.Ref = OrdersRegisteredBalance.Order
		             |			AND SalesOrderLineItems.Ref.Company = OrdersRegisteredBalance.Company
		             |			AND SalesOrderLineItems.Product = OrdersRegisteredBalance.Product
		             |			AND SalesOrderLineItems.Unit = OrdersRegisteredBalance.Unit
		             |			AND SalesOrderLineItems.Location = OrdersRegisteredBalance.Location
		             |			AND SalesOrderLineItems.DeliveryDate = OrdersRegisteredBalance.DeliveryDate
		             |			AND SalesOrderLineItems.Project = OrdersRegisteredBalance.Project
		             |			AND SalesOrderLineItems.Class = OrdersRegisteredBalance.Class
		             |			AND SalesOrderLineItems.QtyUnits = OrdersRegisteredBalance.QuantityBalance
		             |		LEFT JOIN AccumulationRegister.InventoryJournal.Balance AS InventoryJournalBalance
		             |		ON SalesOrderLineItems.Product = InventoryJournalBalance.Product
		             |			AND SalesOrderLineItems.Location = InventoryJournalBalance.Location
		             |		LEFT JOIN Catalog.Units AS Units
		             |		ON (Units.BaseUnit = TRUE)
		             |			AND SalesOrderLineItems.Product.UnitSet = Units.Owner
		             |WHERE
		             |	SalesOrderLineItems.Ref = &Ref
		             |	AND SalesOrderLineItems.Product.Type = VALUE(Enum.InventoryTypes.Inventory)
		             |
		             |ORDER BY
		             |	Item";
					 
		Query.SetParameter("Ref", RefLine.Ref);
		
		QueryResult = Query.Execute();
		Selection = QueryResult.Select();
		
		While Selection.Next() Do
			
			If Selection.Needed = 0 Then Continue; EndIf; 
			
			AreaLineItems.Parameters.Fill(Selection);
			AreaLineItems.Parameters.Needed = Format(Selection.Needed, QuantityFormat)+ " " + Selection.Unit.Code;
			
			Spreadsheet.Put(AreaLineItems);
		EndDo;
		
		//------------------------------------------------------------------------
		Spreadsheet.Put(AreaHeader_1);
		
		TT = New ValueTable;
		TT = QueryResult.Unload();                                         
		TT.GroupBy("Item, Description, Warehouse, ToPick, AbbreviationBaseUM", "NeededBaseUM");
		TT.Sort("Item");
		
		For Each LineTT In TT Do
			
			If LineTT.NeededBaseUM = 0 Then Continue; EndIf; 
			
			AreaLineItems_1.Parameters.Fill(LineTT);
			AreaLineItems_1.Parameters.NeededBaseUM = Format(LineTT.NeededBaseUM, QuantityFormat)+ " " + LineTT.AbbreviationBaseUM;
			AreaLineItems_1.Parameters.ToPick = Format(LineTT.ToPick, QuantityFormat)+ " " + LineTT.AbbreviationBaseUM;
			
			Spreadsheet.Put(AreaLineItems_1);
		EndDo;

		InsertPageBreak = True;
		
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
	"SELECT
	// ------------------------------------------------------
	// Standard Attributes
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
	|	Document.SalesOrder AS Document
	|WHERE
	|	Document.Ref = &Ref";
	
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
	|	LineItems.Ref                         AS Order,
	|	LineItems.Product                     AS Product,
	|	LineItems.Unit                        AS Unit,
	|	LineItems.Location                    AS Location,
	|	LineItems.DeliveryDate                AS DeliveryDate,
	|	LineItems.Project                     AS Project,
	|	LineItems.Class                       AS Class,
	// ------------------------------------------------------
	// Resources
	|	LineItems.QtyUnits                    AS Quantity,
	|	0                                     AS Shipped,
	|	0                                     AS Invoiced
	// ------------------------------------------------------
	// Attributes
	// ------------------------------------------------------
	|FROM
	|	Document.SalesOrder.LineItems AS LineItems
	|WHERE
	|	LineItems.Ref = &Ref
	|ORDER BY
	|	LineNumber";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Put an array of registers, which balance should be checked during posting.
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
		CheckBalances.Add("{Table}.Quantity{Balance}, <, {Table}.Shipped{Balance}");  // Check over-shipping balance.
		CheckBalances.Add("{Table}.Quantity{Balance}, <, {Table}.Invoiced{Balance}"); // Check over-invoiced balance.
		
		// Add messages for different error situations.
		CheckMessages = New Array;
		CheckMessages.Add(NStr("en = '{Product}:
		                             |Order quantity {Quantity} is lower then shipped quantity {Shipped}'"));   // Over-shipping balance.
		CheckMessages.Add(NStr("en = '{Product}:
		                             |Order quantity {Quantity} is lower then invoiced quantity {Invoiced}'")); // Over-invoiced balance.
		
		// Add register to check it's recordset changes and balances during posting.
		BalanceCheck.Insert("OrdersRegistered", New Structure("CheckPostings, CheckBalances, CheckMessages", CheckPostings, CheckBalances, CheckMessages));
		
	ElsIf AdditionalProperties.Posting.WriteMode = DocumentWriteMode.UndoPosting Then
		
		// Add resources for check the balances.
		CheckPostings = New Array;
		CheckPostings.Add("{Table}.Quantity{Posting},  <, 0"); // Check decreasing quantity.
		
		// Add resources for check register balances.
		CheckBalances = New Array;
		CheckBalances.Add("{Table}.Quantity{Balance}, <, {Table}.Shipped{Balance}");  // Check over-shipping balance.
		CheckBalances.Add("{Table}.Quantity{Balance}, <, {Table}.Invoiced{Balance}"); // Check over-invoiced balance.
		
		// Add messages for different error situations.
		CheckMessages = New Array;
		CheckMessages.Add(NStr("en = '{Product}:
		                             |{Shipped} items already shipped'"));    // Over-shipping balance.
		CheckMessages.Add(NStr("en = '{Product}:
		                             |{Invoiced} items already invoiced'"));  // Over-invoiced balance.
		
		// Add registers to check it's recordset changes and balances during undo posting.
		BalanceCheck.Insert("OrdersRegistered", New Structure("CheckPostings, CheckBalances, CheckMessages", CheckPostings, CheckBalances, CheckMessages));
		
	EndIf;
	
	// Return structure of registers to check.
	If BalanceCheck.Count() > 0 Then
		AdditionalProperties.Posting.Insert("BalanceCheck", BalanceCheck);
	EndIf;
	
EndProcedure

#EndIf

#EndRegion

