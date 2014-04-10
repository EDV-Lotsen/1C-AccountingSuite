
////////////////////////////////////////////////////////////////////////////////
// Purchase order: Manager module
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
	              Query_OrdersDispatched(TablesList);
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
#Region COMMANDS_HANDLERS

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

// Handler of standard print command.
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
	// 1. Filling of parameters.
	
	// Common filling of parameters.
	PrintingTables                  = New Structure;
	DocumentParameters              = New Structure("Ref, Metadata, TemplateName");
	DocumentParameters.Ref          = DocumentRef;
	DocumentParameters.Metadata     = Metadata.Documents.PurchaseOrder;
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
	
	Try
		FooterLogo = GeneralFunctions.GetFooterPO("POfooter1");
		Footer1Pic = New Picture(FooterLogo);
		FooterLogo2 = GeneralFunctions.GetFooterPO("POfooter2");
		Footer2Pic = New Picture(FooterLogo2);
		FooterLogo3 = GeneralFunctions.GetFooterPO("POfooter3");
		Footer3Pic = New Picture(FooterLogo3);
	Except
	EndTry;

	
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
			

			//if a dropship customer exists
			If DocumentRef[0].DropshipCompany <> Catalogs.Companies.EmptyRef() Then
				
				TemplateArea.Parameters.UsName = DocumentRef[0].DropshipCompany;
				TemplateArea.Parameters.UsBillLine1 = DocumentRef[0].DropshipShipTo.AddressLine1;
				TemplateArea.Parameters.UsBillLine2 = DocumentRef[0].DropshipShipTo.AddressLine2;
				TemplateArea.Parameters.UsBillCityStateZIP = DocumentRef[0].DropshipShipTo.City + ", " + DocumentRef[0].DropshipShipTo.State.Code + " " +  DocumentRef[0].DropshipShipTo.Zip;
				TemplateArea.Parameters.UsBillCountry = DocumentRef[0].DropshipShipTo.Country;
				
			EndIf;

			If Constants.POShowEmail.Get() = False Then
				  TemplateArea.Parameters.UsBillEmail = "";
				 	

			EndIf;
			  
			If Constants.POShowFedTax.Get() = False Then
				  TemplateArea.Parameters.UsBillFedTaxID = "";
			  Else
				  TemplateArea.Parameters.UsBillFedTaxID = Constants.FederalTaxID.Get();
			EndIf;

			If Constants.POShowFax.Get() = False Then
				  TemplateArea.Parameters.UsBillFax = "";
			Else
				  TemplateArea.Parameters.UsBillFax = Constants.Fax.Get();	  	
			EndIf;

			Try
				If Constants.POShowWebsite.Get() = False Then
					  TemplateArea.Parameters.Website = "";
				Else
					  TemplateArea.Parameters.Website = Constants.Website.Get(); 
				  EndIf;
			Except
			EndTry;
			  
			If Constants.POShowPhone2.Get() = False Then
				  TemplateArea.Parameters.UsBillCell = "";
			Else
				  TemplateArea.Parameters.UsBillCell = Constants.Cell.Get();
			EndIf;
			  
			Try
				If TemplateArea.Parameters.UsBillFax <> "" And TemplateArea.Parameters.UsBillFax <> Undefined Then
					TemplateArea.Parameters.Fax = "Fax";
				EndIf;

				If TemplateArea.Parameters.USBillFedTaxID <> "" And TemplateArea.Parameters.USBillFedTaxID <> Undefined Then
					TemplateArea.Parameters.FederalTaxID = "Fed Tax ID";
				EndIf;
			Except
			EndTry;
  

			
			// Output the header to the sheet.
			Spreadsheet.Put(TemplateArea);
			
			// Output the line items header to the sheet.
			TemplateArea = Template.GetArea("LineItemsHeader");
			Spreadsheet.Put(TemplateArea);
			
			// Output line items of current document.
			TemplateArea = Template.GetArea("LineItems");
			LineItems = PrintingTables.Table_Printing_Document_LineItems.FindRows(New Structure("Ref", DocumentAttributes.Ref));
			For Each Row In LineItems Do
				//If vendor code or vendor description supplied, replace in template.
				TemplateArea.Parameters.Fill(Row);
				CurProd = Row.Product;
				If CurProd.vendor_code <> "" Then
					TemplateArea.Parameters.Product = CurProd.vendor_code;
				EndIf;
				
				If CurProd.vendor_description <> "" Then
					TemplateArea.Parameters.ProductDescription = CurProd.vendor_description;
				EndIf;
				Spreadsheet.Put(TemplateArea, 1);
			EndDo;
			
			// Output document total.
			TemplateArea = Template.GetArea("Total");
			TemplateArea.Parameters.Fill(DocumentAttributes);
			Spreadsheet.Put(TemplateArea);
		EndIf;
		
//newlyadded


 	TemplateArea = Template.GetArea("Notes");
	TemplateArea.Parameters.Notes = Constants.PONotes.Get();
	Spreadsheet.Put(TemplateArea);
	


	Try
		If Constants.POFoot1Type.Get()= Enums.TextOrImage.Image Then
			DocumentPrinting.FillPictureInDocumentTemplate(Template,Footer1Pic, "POfooter1");
		EndIf;
		If Constants.POFoot2Type.Get()= Enums.TextOrImage.Image Then
			DocumentPrinting.FillPictureInDocumentTemplate(Template, Footer2Pic, "POfooter2");
		EndIf;
		If Constants.POFoot3Type.Get()= Enums.TextOrImage.Image Then
			DocumentPrinting.FillPictureInDocumentTemplate(Template, Footer3Pic, "POfooter3");
		EndIf;	
	Except
	EndTry;	
	
	Row = Template.GetArea("SpaceRow");
	Footer = Template.GetArea("Footer");
	RowsToCheck = New Array();
	RowsToCheck.Add(Row);
	RowsToCheck.Add(Footer);
	
	If Constants.POFoot1Type.Get() = Enums.TextOrImage.Text Then
		Footer.Parameters.POFooterLeft = Constants.POFooterTextLeft.Get();
	EndIf;
	If Constants.POFoot2Type.Get() = Enums.TextOrImage.Text Then
		Footer.Parameters.POFooterCenter = Constants.POFooterTextCenter.Get();
	EndIf;
	If Constants.POFoot3Type.Get() = Enums.TextOrImage.Text Then
		Footer.Parameters.POFooterRight = Constants.POFooterTextRight.Get();
	EndIf;

	
	While Spreadsheet.CheckPut(RowsToCheck) Do
		 SpreadSheet.Put(Row);

		 RowsToCheck.Clear();
		 RowsToCheck.Add(Row);
		 RowsToCheck.Add(Footer);
		 RowsToCheck.Add(Row);
	EndDo;

	Spreadsheet.Put(Footer);
//newlyadded
	Spreadsheet.PutHorizontalPageBreak();
	EndDo;
		
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
	"SELECT
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
	|	Document.PurchaseOrder AS Document
	|WHERE
	|	Document.Ref = &Ref";
	
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
	|	LineItems.Ref                         AS Order,
	|	LineItems.Product                     AS Product,
	|	LineItems.Location                    AS Location,
	|	LineItems.DeliveryDate                AS DeliveryDate,
	|	LineItems.Project                     AS Project,
	|	LineItems.Class                       AS Class,
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
		CheckBalances.Add("{Table}.Quantity{Balance}, <, {Table}.Received{Balance}"); // Check over-shipping balance.
		CheckBalances.Add("{Table}.Quantity{Balance}, <, {Table}.Invoiced{Balance}"); // Check over-invoiced balance.
		
		// Add messages for different error situations.
		CheckMessages = New Array;
		CheckMessages.Add(NStr("en = '{Product}:
		                             |Order quantity {Quantity} is lower then received quantity {Received}'")); // Over-shipping balance.
		CheckMessages.Add(NStr("en = '{Product}:
		                             |Order quantity {Quantity} is lower then invoiced quantity {Invoiced}'")); // Over-invoiced balance.
		
		// Add register to check it's recordset changes and balances during posting.
		BalanceCheck.Insert("OrdersDispatched", New Structure("CheckPostings, CheckBalances, CheckMessages", CheckPostings, CheckBalances, CheckMessages));
		
	ElsIf AdditionalProperties.Posting.WriteMode = DocumentWriteMode.UndoPosting Then
		
		// Add resources for check changes in recordset.
		CheckPostings = New Array;
		CheckPostings.Add("{Table}.Quantity{Posting}, <, 0"); // Check decreasing quantity.
		
		// Add resources for check register balances.
		CheckBalances = New Array;
		CheckBalances.Add("{Table}.Quantity{Balance}, <, {Table}.Received{Balance}"); // Check over-shipping balance.
		CheckBalances.Add("{Table}.Quantity{Balance}, <, {Table}.Invoiced{Balance}"); // Check over-invoiced balance.
		
		// Add messages for different error situations.
		CheckMessages = New Array;
		CheckMessages.Add(NStr("en = '{Product}:
		                             |{Received} items already received'")); // Over-shipping balance.
		CheckMessages.Add(NStr("en = '{Product}:
		                             |{Invoiced} items already invoiced'")); // Over-invoiced balance.
		
		// Add registers to check it's recordset changes and balances during undo posting.
		BalanceCheck.Insert("OrdersDispatched", New Structure("CheckPostings, CheckBalances, CheckMessages", CheckPostings, CheckBalances, CheckMessages));
		
	EndIf;
	
	// Return structure of registers to check.
	If BalanceCheck.Count() > 0 Then
		AdditionalProperties.Posting.Insert("BalanceCheck", BalanceCheck);
	EndIf;
	
EndProcedure

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
	|	Document.PurchaseOrder AS Document
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
	|	LEFT JOIN Document.PurchaseOrder AS Document
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
	|	DocumentLineItems.Quantity            AS Quantity,
	|	DocumentLineItems.UM                  AS UM,
	|	DocumentLineItems.Price               AS Price,
	|	DocumentLineItems.LineTotal           AS LineTotal
	// ------------------------------------------------------
	|FROM
	|	Table_Printing_Document_Data AS Document_Data
	|	LEFT JOIN Document.PurchaseOrder.LineItems AS DocumentLineItems
	|		ON DocumentLineItems.Ref = Document_Data.Ref
	|ORDER BY
	|	Document_Data.PointInTime ASC,
	|	DocumentLineItems.LineNumber ASC";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

#EndIf

#EndRegion
