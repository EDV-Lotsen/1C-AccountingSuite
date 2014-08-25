
////////////////////////////////////////////////////////////////////////////////
// Purchase order: Manager module
//------------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
#Region EVENTS_HANDLERS

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	
	StandardProcessing = False;
	
	Presentation = "PO #" + Data.Number + " " + Format(Data.Date, "DLF=D"); 
	
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
	              Query_OrdersDispatched(TablesList);
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
Procedure Print(Spreadsheet, SheetTitle, Ref, TemplateName = Undefined) Export
SheetTitle = "Purchase order";
	CustomTemplate = GeneralFunctions.GetCustomTemplate("Document.PurchaseOrder", SheetTitle);
	
	If CustomTemplate = Undefined Then
		Template = Documents.PurchaseOrder.GetTemplate("NewPOPrintForm");
	Else
		Template = CustomTemplate;
	EndIf;
	
   // Quering necessary data.
   Query = New Query();
   Query.Text =
   "SELECT
   |	PurchaseOrder.Ref,
   |	PurchaseOrder.DataVersion,
   |	PurchaseOrder.DeletionMark,
   |	PurchaseOrder.Number,
   |	PurchaseOrder.Date,
   |	PurchaseOrder.Posted,
   |	PurchaseOrder.Company,
   |	PurchaseOrder.CompanyAddress,
   |	PurchaseOrder.DropshipCompany,
   |	PurchaseOrder.DropshipShipTo,
   |	PurchaseOrder.DropshipBillTo,
   |	PurchaseOrder.DropshipConfirmTo,
   |	PurchaseOrder.DropshipRefNum,
   |	PurchaseOrder.SalesPerson,
   |	PurchaseOrder.Currency,
   |	PurchaseOrder.ExchangeRate,
   |	PurchaseOrder.Location,
   |	PurchaseOrder.DeliveryDate,
   |	PurchaseOrder.Project,
   |	PurchaseOrder.Class,
   |	PurchaseOrder.Memo,
   |	PurchaseOrder.ManualAdjustment,
   |	PurchaseOrder.DocumentTotal,
   |	PurchaseOrder.DocumentTotalRC,
   |	PurchaseOrder.BaseDocument,
   |	PurchaseOrder.EmailNote,
   |	PurchaseOrder.LastEmail,
   |	PurchaseOrder.EmailTo,
   |	PurchaseOrder.LineItems.(
   |		Ref,
   |		LineNumber,
   |		Product,
   |		ProductDescription,
   |		UnitSet,
   |		QtyUnits,
   |		Unit,
   |		QtyUM,
   |		PriceUnits,
   |		LineTotal,
   |		Location,
   |		DeliveryDate,
   |		Project,
   |		Class
   |	)
   |FROM
   |	Document.PurchaseOrder AS PurchaseOrder
   |WHERE
   |	PurchaseOrder.Ref IN(&Ref)";
   Query.SetParameter("Ref", Ref);
   Selection = Query.Execute().Select();
  
   Spreadsheet.Clear();
   
    While Selection.Next() Do
	   
	BinaryLogo = GeneralFunctions.GetLogo();
	LogoPicture = New Picture(BinaryLogo);
	DocumentPrinting.FillLogoInDocumentTemplate(Template, LogoPicture); 
	
	Try
		FooterLogo = GeneralFunctions.GetFooterPO("POfooter1");
		Footer1Pic = New Picture(FooterLogo);
		FooterLogo2 = GeneralFunctions.GetFooterPO("POfooter2");
		Footer2Pic = New Picture(FooterLogo2);
		FooterLogo3 = GeneralFunctions.GetFooterPO("POfooter3");
		Footer3Pic = New Picture(FooterLogo3);
	Except
	EndTry;
	
	//Add footer with page count	
	Template.Footer.Enabled = True;
	Template.Footer.RightText = "Page [&PageNumber] of [&PagesTotal]";
   
	TemplateArea = Template.GetArea("Header");
	
	TemplateArea.Parameters.CustomerPO = Selection.DropShipRefNum;
	  		
	UsBill = PrintTemplates.ContactInfoDatasetUs();
	//UseDropShip = False;
	If Selection.DropshipShipTo <> Catalogs.Addresses.EmptyRef() Then
		ThemShip = PrintTemplates.ContactInfoDataset(Selection.DropshipCompany, "ThemShip", Selection.DropshipShipTo);
		//UseDropShip = True;
	Else
		// ship to us //
		ThemShip = PrintTemplates.ContactInfoDatasetUs();
	EndIf;
	
	ThemBill = PrintTemplates.ContactInfoDataset(Selection.Company, "ThemBill", Selection.CompanyAddress);
	
	TemplateArea.Parameters.Fill(UsBill);
	Try TemplateArea.Parameters.Fill(ThemShip); Except Endtry;
	TemplateArea.Parameters.Fill(ThemBill);
	
	TemplateArea.Parameters.VendorString = Upper(Constants.VendorName.Get()) + ":";
		
	If Constants.POShowFullName.Get() = True Then
		//If SessionParameters.TenantValue = "1100674" Or Constants.SIShowFullName.Get() = True Then
		If Selection.DropshipShipTo <> Catalogs.Addresses.EmptyRef() Then
			TemplateArea.Parameters.ThemFullName = ThemShip.ThemShipSalutation + " " + ThemShip.ThemShipFirstName + " " + ThemShip.ThemShipLastName;
		Else
			// ship to us
			TemplateArea.Parameters.ThemFullName = "";
		EndIf;
	EndIf;
	
	
	If Constants.POShowCountry.Get() = False Then
		TemplateArea.Parameters.ThemBillCountry = "";
		TemplateArea.Parameters.ThemShipCountry = "";
	EndIf;

	TemplateArea.Parameters.Date = Selection.Date;
	TemplateArea.Parameters.Number = Selection.Number;
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
	
	If TemplateArea.Parameters.UsBillEmail <> "" AND Constants.POShowEmail.Get() = False Then
		TemplateArea.Parameters.UsBillEmail = ""; 
	EndIf;
	
	//ThemBill filling
	If TemplateArea.Parameters.ThemBillLine1 <> "" Then
		TemplateArea.Parameters.ThemBillLine1 = TemplateArea.Parameters.ThemBillLine1 + Chars.LF; 
	Else
		TemplateArea.Parameters.ThemBillLine1 = "";
	EndIf;

	If TemplateArea.Parameters.ThemBillLine2 <> "" Then
		TemplateArea.Parameters.ThemBillLine2 = TemplateArea.Parameters.ThemBillLine2 + Chars.LF; 
	Else
		TemplateArea.Parameters.ThemBillLine2 = "";
	EndIf;
	
	If TemplateArea.Parameters.ThemBillLine3 <> "" Then
		TemplateArea.Parameters.ThemBillLine3 = TemplateArea.Parameters.ThemBillLine3 + Chars.LF; 
	Else
		TemplateArea.Parameters.ThemBillLine3 = "";
	EndIf;
	
	If TemplateArea.Parameters.ThemBillCityStateZIP <> "" Then
		TemplateArea.Parameters.ThemBillCityStateZIP = TemplateArea.Parameters.ThemBillCityStateZIP + Chars.LF; 
	EndIf;
	
	//ThemShip filling
	Try
		If TemplateArea.Parameters.ThemShipLine1 <> "" Then
			TemplateArea.Parameters.ThemShipLine1 = TemplateArea.Parameters.ThemShipLine1 + Chars.LF; 
		Else
			TemplateArea.Parameters.ThemShipLine1 = "";
		EndIf;

		If TemplateArea.Parameters.ThemShipLine2 <> "" Then
			TemplateArea.Parameters.ThemShipLine2 = TemplateArea.Parameters.ThemShipLine2 + Chars.LF; 
		Else
			TemplateArea.Parameters.ThemShipLine2 = "";
		EndIf;
		
		If TemplateArea.Parameters.ThemShipLine3 <> "" Then
			TemplateArea.Parameters.ThemShipLine3 = TemplateArea.Parameters.ThemShipLine3 + Chars.LF; 
		Else
			TemplateArea.Parameters.ThemShipLine3 = "";
		EndIf;
		
		If TemplateArea.Parameters.ThemShipCityStateZIP <> "" Then
			TemplateArea.Parameters.ThemShipCityStateZIP = TemplateArea.Parameters.ThemShipCityStateZIP + Chars.LF; 
		EndIf;
	
	Except // ship to us
		If Constants.MultiLocation.Get() = True Then
			
			TemplateArea.Parameters.ThemShipLine1 = Selection.Location.AddressLine1 + Chars.LF; 
			TemplateArea.Parameters.ThemShipLine2 = Selection.Location.AddressLine2 + Chars.LF;  
			TemplateArea.Parameters.ThemShipLine3 = Selection.Location.AddressLine3 + Chars.LF; 
			TemplateArea.Parameters.ThemShipName = String(Selection.Location) + Chars.LF;
			If Selection.Location.City <> "" AND String(Selection.Location.State) <> "" Then
				comma = ", ";
			Else
				comma = "";
			EndIf;
			TemplateArea.Parameters.ThemShipCityStateZIP = Selection.Location.City + comma + Selection.Location.State + " " + Selection.Location.ZIP + Chars.LF;  
			//TemplateArea.Parameters.ThemShipPhone = "";  
			//TemplateArea.Parameters.ThemShipFax = ""; 
			//TemplateArea.Parameters.ThemShipEmail = "";
			
		Else
		
			If TemplateArea.Parameters.UsBillLine1 <> "" Then
			TemplateArea.Parameters.ThemShipLine1 = TemplateArea.Parameters.UsBillLine1; 
			EndIf;

			If TemplateArea.Parameters.UsBillLine2 <> "" Then
				TemplateArea.Parameters.ThemShipLine2 = TemplateArea.Parameters.UsBillLine2; 
			EndIf;
			
			TemplateArea.Parameters.ThemShipLine3 = "";
			TemplateArea.Parameters.ThemShipName = TemplateArea.Parameters.UsName;
			
			If TemplateArea.Parameters.UsBillCityStateZIP <> "" Then
				TemplateArea.Parameters.ThemShipCityStateZIP = TemplateArea.Parameters.UsBillCityStateZIP + Chars.LF; 
			EndIf;
			
//				TemplateArea.Parameters.ThemShipPhone = ""; 			
//				TemplateArea.Parameters.ThemShipFax = ""; 
//				TemplateArea.Parameters.ThemShipEmail = "";		
		EndIf;
		
	EndTry;

	 
	 Spreadsheet.Put(TemplateArea);
	 	
	If Constants.POShowPhone2.Get() = False Then
		Direction = SpreadsheetDocumentShiftType.Vertical;
		Area = Spreadsheet.Area("MobileArea");
		Spreadsheet.DeleteArea(Area, Direction);
		Spreadsheet.InsertArea(Spreadsheet.Area("R10"), Spreadsheet.Area("R10"), 
        SpreadsheetDocumentShiftType.Vertical);
	EndIf;
	
	If Constants.POShowWebsite.Get() = False Then
		Direction = SpreadsheetDocumentShiftType.Vertical;
		Area = Spreadsheet.Area("WebsiteArea");
		Spreadsheet.DeleteArea(Area, Direction);
		Spreadsheet.InsertArea(Spreadsheet.Area("R10"), Spreadsheet.Area("R10"), 
		SpreadsheetDocumentShiftType.Vertical);

	EndIf;
	
	If Constants.POShowFax.Get() = False Then
		Direction = SpreadsheetDocumentShiftType.Vertical;
		Area = Spreadsheet.Area("FaxArea");
		Spreadsheet.DeleteArea(Area, Direction);
		Spreadsheet.InsertArea(Spreadsheet.Area("R10"), Spreadsheet.Area("R10"), 
		SpreadsheetDocumentShiftType.Vertical);

	EndIf;
	
	If Constants.POShowFedTax.Get() = False Then
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
	QuantityFormat = GeneralFunctionsReusable.DefaultQuantityFormat();
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
		If SelectionLineItems.Product.vendor_code <> "" Then
			TemplateArea.Parameters.Product = SelectionLineItems.Product.vendor_code;
		EndIf;
		If SelectionLineItems.Product.vendor_description <> "" Then
			TemplateArea.Parameters.ProductDescription = SelectionLineItems.Product.vendor_description;
		EndIf;
		LineTotal = SelectionLineItems.LineTotal;
		TemplateArea.Parameters.Quantity = Format(SelectionLineItems.QtyUnits, QuantityFormat);
		TemplateArea.Parameters.Price = Selection.Currency.Symbol + Format(SelectionLineItems.PriceUnits, "NFD=2; NZ=");
		TemplateArea.Parameters.UM = SelectionLineItems.Unit.Code;
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
		RowsToCheck.Add(Footer);
		RowsToCheck.Add(DividerArea);
		
		If Spreadsheet.CheckPut(RowsToCheck) = False Then
			
			// Add divider and footer to bottom, break to next page, add header.
			
			Row = Template.GetArea("EmptyRow");
			Spreadsheet.Put(Row);
			
			DividerArea = Template.GetArea("DividerArea");
			Spreadsheet.Put(DividerArea);

			If Constants.POFoot1Type.Get()= Enums.TextOrImage.Image Then	
				DocumentPrinting.FillPictureInDocumentTemplate(Template, Footer1Pic, "POfooter1");
				TemplateArea2 = Template.GetArea("FooterField|FooterSection1");	
				Spreadsheet.Put(TemplateArea2);
			Elsif Constants.POFoot1Type.Get() = Enums.TextOrImage.Text Then
				TemplateArea2 = Template.GetArea("TextField|FooterSection1");
				TemplateArea2.Parameters.FooterTextLeft = Constants.POFooterTextLeft.Get();
				Spreadsheet.Put(TemplateArea2);
			EndIf;
		
			If Constants.POFoot2Type.Get()= Enums.TextOrImage.Image Then
				DocumentPrinting.FillPictureInDocumentTemplate(Template, Footer2Pic, "POfooter2");
				TemplateArea2 = Template.GetArea("FooterField|FooterSection2");	
				Spreadsheet.Join(TemplateArea2);
			
			Elsif Constants.POFoot2Type.Get() = Enums.TextOrImage.Text Then
				TemplateArea2 = Template.GetArea("TextField|FooterSection2");
				TemplateArea2.Parameters.FooterTextCenter = Constants.POFooterTextCenter.Get();
				Spreadsheet.Join(TemplateArea2);
			EndIf;
		
			If Constants.POFoot3Type.Get()= Enums.TextOrImage.Image Then
					DocumentPrinting.FillPictureInDocumentTemplate(Template, Footer3Pic, "POfooter3");
					TemplateArea2 = Template.GetArea("FooterField|FooterSection3");	
					Spreadsheet.Join(TemplateArea2);
			Elsif Constants.POFoot3Type.Get() = Enums.TextOrImage.Text Then
					TemplateArea2 = Template.GetArea("TextField|FooterSection3");
					TemplateArea2.Parameters.FooterTextRight = Constants.POFooterTextRight.Get();
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
	
	If AddHeader = True Then
		HeaderArea = Spreadsheet.GetArea("TopHeader");
		Spreadsheet.Put(HeaderArea);
		Spreadsheet.Put(Row);
	EndIf;

	 
	TemplateArea = Template.GetArea("Area3|Area1");					
	TemplateArea.Parameters.TermAndCond = Selection.Ref.EmailNote;
	Spreadsheet.Put(TemplateArea);

	
	TemplateArea = Template.GetArea("Area3|Area2");
	TemplateArea.Parameters.Total = Selection.Currency.Symbol + Format(Selection.DocumentTotal, "NFD=2; NZ=");

	Spreadsheet.Join(TemplateArea);
		
	Row = Template.GetArea("EmptyRow");
	Footer = Template.GetArea("FooterField");
	Compensator = Template.GetArea("Compensator");
	RowsToCheck = New Array();
	RowsToCheck.Add(Row);
	RowsToCheck.Add(Footer);
	RowsToCheck.Add(Row);
	
	
	While Spreadsheet.CheckPut(RowsToCheck) Do
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
	
	//Final footer
	
	If Constants.POFoot1Type.Get()= Enums.TextOrImage.Image Then	
			DocumentPrinting.FillPictureInDocumentTemplate(Template, Footer1Pic, "POfooter1");
			TemplateArea = Template.GetArea("FooterField|FooterSection1");	
			Spreadsheet.Put(TemplateArea);
	Elsif Constants.POFoot1Type.Get() = Enums.TextOrImage.Text Then
			TemplateArea = Template.GetArea("TextField|FooterSection1");
			TemplateArea.Parameters.FooterTextLeft = Constants.POFooterTextLeft.Get();
			Spreadsheet.Put(TemplateArea);
	EndIf;
		
	If Constants.POFoot2Type.Get()= Enums.TextOrImage.Image Then
			DocumentPrinting.FillPictureInDocumentTemplate(Template, Footer2Pic, "POfooter2");
			TemplateArea = Template.GetArea("FooterField|FooterSection2");	
			Spreadsheet.Join(TemplateArea);		
	Elsif Constants.POFoot2Type.Get() = Enums.TextOrImage.Text Then
			TemplateArea = Template.GetArea("TextField|FooterSection2");
			TemplateArea.Parameters.FooterTextCenter = Constants.POFooterTextCenter.Get();
			Spreadsheet.Join(TemplateArea);
	EndIf;
		
	If Constants.POFoot3Type.Get()= Enums.TextOrImage.Image Then
			DocumentPrinting.FillPictureInDocumentTemplate(Template, Footer3Pic, "POfooter3");
			TemplateArea = Template.GetArea("FooterField|FooterSection3");	
			Spreadsheet.Join(TemplateArea);
	Elsif Constants.POFoot3Type.Get() = Enums.TextOrImage.Text Then
			TemplateArea = Template.GetArea("TextField|FooterSection3");
			TemplateArea.Parameters.FooterTextRight = Constants.POFooterTextRight.Get();
			Spreadsheet.Join(TemplateArea);
	EndIf;
		
	Spreadsheet.PutHorizontalPageBreak(); //.ВывестиГоризонтальныйРазделительСтраниц();
	Spreadsheet.FitToPage  = True;
	
	// Remove footer information if only a page.
	If Spreadsheet.PageCount() = 1 Then
		Spreadsheet.Footer.Enabled = False;
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
	|	LineItems.Unit                        AS Unit,
	|	LineItems.Location                    AS Location,
	|	LineItems.DeliveryDate                AS DeliveryDate,
	|	LineItems.Project                     AS Project,
	|	LineItems.Class                       AS Class,
	// ------------------------------------------------------
	// Resources
	|	LineItems.QtyUnits                    AS Quantity,
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
	//|	DocumentLineItems.UM                  AS UM,
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
