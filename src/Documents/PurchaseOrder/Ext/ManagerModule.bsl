
////////////////////////////////////////////////////////////////////////////////
// Purchase Order: Manager module
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
	"SELECT
	// ------------------------------------------------------
	// Standard Attributes
	|	Document.Ref                          AS Recorder,
	|	Document.Date                         AS Period,
	|	1                                     AS LineNumber,
	|	True								  AS Active,
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
	|	Document.PurchaseOrder AS Document
	|WHERE
	|	Document.Ref = &Ref";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data
Function Query_OrdersDispatched(TablesList)

	// Add OrdersDispatched table to document structure
	TablesList.Insert("Table_OrdersDispatched", TablesList.Count());
	
	// Collect orders registered data
	QueryText =
	"SELECT
	// ------------------------------------------------------
	// Standard Attributes
	|	LineItems.Ref                         AS Recorder,
	|	LineItems.Ref.Date                    AS Period,
	|	LineItems.LineNumber                  AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	True								  AS Active,
	// ------------------------------------------------------
	// Dimensions
	|	LineItems.Ref.Company                 AS Company,
	|	LineItems.Ref                         AS Order,
	|	LineItems.Product                     AS Product,
	// ------------------------------------------------------
	// Resources
	|	LineItems.Quantity                    AS Quantity,
	|	0                                     AS Received,
	|	0                                     AS Invoiced
	// ------------------------------------------------------
	// Attributes
	// ------------------------------------------------------
	|FROM
	|	Document.PurchaseOrder.LineItems AS LineItems
	|WHERE
	|	LineItems.Ref = &Ref
	|ORDER BY
	|	LineNumber";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Put an array of registers, which balance should be checked during posting
Procedure FillRegistersCheckList(AdditionalProperties, RegisterRecords)

	// Create structure of registers and its resources to check balances
	BalanceCheck = New Structure;
		
	// Fill structure depending on document write mode
	If AdditionalProperties.Posting.WriteMode = DocumentWriteMode.Posting Then
		
		// Add resources for check changes in recordset
		CheckPostings = New Array;
		CheckPostings.Add("{Table}.Quantity{Posting}, <, 0"); // Check decreasing quantity
		
		// Add resources for check register balances
		CheckBalances = New Array;
		CheckBalances.Add("{Table}.Quantity{Balance}, <, {Table}.Received{Balance}"); // Check over-shipping balance
		CheckBalances.Add("{Table}.Quantity{Balance}, <, {Table}.Invoiced{Balance}"); // Check over-invoiced balance
		
		// Add messages for different error situations
		CheckMessages = New Array;
		CheckMessages.Add(NStr("en = '{Product}:
		                             |Order quantity {Quantity} is lower then received quantity {Received}'")); // Over-shipping balance
		CheckMessages.Add(NStr("en = '{Product}:
		                             |Order quantity {Quantity} is lower then invoiced quantity {Invoiced}'")); // Over-invoiced balance
									 
		// Add register to check it's recordset changes and balances during posting
		BalanceCheck.Insert("OrdersDispatched", New Structure("CheckPostings, CheckBalances, CheckMessages", CheckPostings, CheckBalances, CheckMessages));
		
	ElsIf AdditionalProperties.Posting.WriteMode = DocumentWriteMode.UndoPosting Then
		
		// Add resources for check the balances
		CheckPostings = New Array;
		CheckPostings.Add("{Table}.Quantity{Posting},  <, 0"); // Check decreasing quantity
		
		// Add resources for check register balances
		CheckBalances = New Array;
		CheckBalances.Add("{Table}.Quantity{Balance}, <, {Table}.Received{Balance}"); // Check over-shipping balance
		CheckBalances.Add("{Table}.Quantity{Balance}, <, {Table}.Invoiced{Balance}"); // Check over-invoiced balance
		
		// Add messages for different error situations
		CheckMessages = New Array;
		CheckMessages.Add(NStr("en = '{Product}:
		                             |{Received} items already received'")); // Over-shipping balance
		CheckMessages.Add(NStr("en = '{Product}:
		                             |{Invoiced} items already invoiced'")); // Over-invoiced balance
		
		// Add registers to check it's recordset changes and balances during undo posting
		BalanceCheck.Insert("OrdersDispatched", New Structure("CheckPostings, CheckBalances, CheckMessages", CheckPostings, CheckBalances, CheckMessages));
		
	EndIf;

	// Return structure of registers to check
	If BalanceCheck.Count() > 0 Then
		AdditionalProperties.Posting.Insert("BalanceCheck", BalanceCheck);
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// DOCUMENT PRINTING (OLD)

Procedure Print(ObjectArray, PrintParameters, PrintFormsCollection,
           PrintObjects, OutputParameters) Export

     // Setting the kit printing option.
     OutputParameters.AvailablePrintingByKits = True;

     // Checking if a spreadsheet document generation needed for the Purchase Order template.
    If PrintManagement.NeedToPrintTemplate(PrintFormsCollection, "PurchaseOrder") Then

         // Generating a spreadsheet document and adding it into the print form collection.
         PrintManagement.OutputSpreadsheetDocumentToCollection(PrintFormsCollection,
             "PurchaseOrder", "Purchase order", PrintTemplate(ObjectArray, PrintObjects));

	EndIf;
		 
EndProcedure
	 
Function PrintTemplate(ObjectArray, PrintObjects)
	
	// Create a spreadsheet document and set print parameters.
   SpreadsheetDocument = New SpreadsheetDocument;
   SpreadsheetDocument.PrintParametersName = "PrintParameters_PurchaseOrder";


   // Quering necessary data.
   Query = New Query();
   Query.Text =
   "SELECT
   |	PurchaseOrder.Ref,
   |	PurchaseOrder.Company,
   |	PurchaseOrder.Date,
   |	PurchaseOrder.DocumentTotal,
   |	PurchaseOrder.Number,
   |	PurchaseOrder.PriceIncludesVAT,
   |	PurchaseOrder.Currency,
   |	PurchaseOrder.VATTotal,
   |	PurchaseOrder.LineItems.(
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
   |	Document.PurchaseOrder AS PurchaseOrder
   |WHERE
   |	PurchaseOrder.Ref IN(&ObjectArray)";
   Query.SetParameter("ObjectArray", ObjectArray);
   Selection = Query.Execute().Choose();
   
   	FirstDocument = True;

	Us = Catalogs.Companies.OurCompany;
   
   	While Selection.Next() Do
		
		If Not FirstDocument Then
			// All documents need to be outputted on separate pages.
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		FirstDocument = False;
		// Remember current document output beginning line number.
		BeginningLineNumber = SpreadsheetDocument.TableHeight + 1;

	 
	 Template = PrintManagement.GetTemplate("Document.PurchaseOrder.PF_MXL_PurchaseOrder");
	 
	 TemplateArea = Template.GetArea("Header");
	 
	UsBill = PrintTemplates.ContactInfoDataset(Us, "UsBill", Catalogs.Addresses.EmptyRef());
	ThemBill = PrintTemplates.ContactInfoDataset(Selection.Company, "ThemBill", Catalogs.Addresses.EmptyRef());
	
	TemplateArea.Parameters.Fill(UsBill);
	TemplateArea.Parameters.Fill(ThemBill);
	 	 
	 TemplateArea.Parameters.Date = Selection.Date;
	 TemplateArea.Parameters.Number = Selection.Number;
	 
	 SpreadsheetDocument.Put(TemplateArea);

	 TemplateArea = Template.GetArea("LineItemsHeader");
	 SpreadsheetDocument.Put(TemplateArea);
	 
	 SelectionLineItems = Selection.LineItems.Choose();
	 TemplateArea = Template.GetArea("LineItems");
	 LineTotalSum = 0;
	 While SelectionLineItems.Next() Do
		 
		 TemplateArea.Parameters.Fill(SelectionLineItems);
		 LineTotal = SelectionLineItems.LineTotal;
		 LineTotalSum = LineTotalSum + LineTotal;
		 SpreadsheetDocument.Put(TemplateArea, SelectionLineItems.Level());
		 
	 EndDo;
	 	 
	If Selection.VATTotal <> 0 Then;
		 TemplateArea = Template.GetArea("Subtotal");
		 TemplateArea.Parameters.Subtotal = LineTotalSum;
		 SpreadsheetDocument.Put(TemplateArea);
		 
		 TemplateArea = Template.GetArea("VAT");
		 TemplateArea.Parameters.VATTotal = Selection.VATTotal;
		 SpreadsheetDocument.Put(TemplateArea);
	EndIf; 
		 
	 TemplateArea = Template.GetArea("Total");
	If Selection.PriceIncludesVAT Then
	 	TemplateArea.Parameters.DocumentTotal = LineTotalSum;
	Else
		TemplateArea.Parameters.DocumentTotal = LineTotalSum + Selection.VATTotal;
	EndIf;
	 SpreadsheetDocument.Put(TemplateArea);

	 TemplateArea = Template.GetArea("Currency");
	 TemplateArea.Parameters.Currency = Selection.Currency;
	 SpreadsheetDocument.Put(TemplateArea);
	 
     // Setting a print area in the spreadsheet document where to output the object.
     // Necessary for kit printing. 
     PrintManagement.SetDocumentPrintArea(SpreadsheetDocument, BeginningLineNumber, PrintObjects, Selection.Ref);

   EndDo;
   
   Return SpreadsheetDocument;
   
EndFunction