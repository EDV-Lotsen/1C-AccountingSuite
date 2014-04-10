
////////////////////////////////////////////////////////////////////////////////
// Sales Order: Manager module
//------------------------------------------------------------------------------

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
	Query.SetParameter("Ref", DocumentRef);
	
	// Query for document's tables.
	Query.Text  = Query_OrdersStatuses(TablesList) +
	              Query_OrdersRegistered(TablesList);
	QueryResult = Query.ExecuteBatch();
	
	// Save documents table in posting parameters.
	For Each DocumentTable In TablesList Do
		AdditionalProperties.Posting.PostingTables.Insert(DocumentTable.Key, QueryResult[DocumentTable.Value].Unload());
	EndDo;
	
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
	
	SheetTitle = "Sales order";
	CustomTemplate = GeneralFunctions.GetCustomTemplate("Document.SalesOrder", SheetTitle);
	
	If CustomTemplate = Undefined Then
		Template = Documents.SalesOrder.GetTemplate("PF_MXL_SalesOrder");
	Else
		Template = CustomTemplate;
	EndIf;
	
	//Template = Documents.SalesOrder.GetTemplate("PF_MXL_SalesOrder");
	
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
   |		UM,
   |		Quantity,
   |		Price,
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
	
	
	//test = TemplateArea.Drawings.LogoPlaceholder;
	//Template.Drawings.LogoPlaceholder.Picture = BinaryLogo;
	
	
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
		 TemplateArea.Parameters.Total = Selection.DocumentTotal;
		 Spreadsheet.Put(TemplateArea);
		 
		 TemplateArea = Template.GetArea("TermandCondition");					
		 TemplateArea.Parameters.TermAndCond = Selection.Ref.ExternalMemo;
		 Spreadsheet.Put(TemplateArea);

		 
	//Try
	// 	TemplateArea = Template.GetArea("Footer");
	//	OurContactInfo = UsBill.UsName + " - " + UsBill.UsBillLine1Line2 + " - " + UsBill.UsBillCityStateZIP + " - " + UsBill.UsBillPhone;
	//	TemplateArea.Parameters.OurContactInfo = OurContactInfo;
	// 	Spreadsheet.Put(TemplateArea);
	// Except
	//EndTry;


	 //Spreadsheet.Put(TemplateArea);

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
   |		Product.UM AS UM,
   |		Quantity,
   |		Price,
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
	|	LineItems.Location                    AS Location,
	|	LineItems.DeliveryDate                AS DeliveryDate,
	|	LineItems.Project                     AS Project,
	|	LineItems.Class                       AS Class,
	// ------------------------------------------------------
	// Resources
	|	LineItems.Quantity                    AS Quantity,
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

