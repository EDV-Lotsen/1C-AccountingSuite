
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
	
	SheetTitle = "Sales order";
	CustomTemplate = GeneralFunctions.GetCustomTemplate("Document.SalesOrder", SheetTitle);
	
	If CustomTemplate = Undefined Then
		//Template = Documents.SalesOrder.GetTemplate("PF_MXL_SalesOrder");
		Template = Documents.SalesOrder.GetTemplate("New_SalesOrder_Form");
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
   |	SalesOrder.DataVersion,
   |	SalesOrder.DeletionMark,
   |	SalesOrder.Number,
   |	SalesOrder.Date,
   |	SalesOrder.Posted,
   |	SalesOrder.Company,
   |	SalesOrder.ShipTo,
   |	SalesOrder.BillTo,
   |	SalesOrder.ConfirmTo,
   |	SalesOrder.RefNum,
   |	SalesOrder.DropshipCompany,
   |	SalesOrder.DropshipShipTo,
   |	SalesOrder.DropshipConfirmTo,
   |	SalesOrder.DropshipRefNum,
   |	SalesOrder.SalesPerson,
   |	SalesOrder.Currency,
   |	SalesOrder.ExchangeRate,
   |	SalesOrder.Location,
   |	SalesOrder.DeliveryDate,
   |	SalesOrder.Project,
   |	SalesOrder.Class,
   |	SalesOrder.Memo,
   |	SalesOrder.ManualAdjustment,
   |	SalesOrder.LineSubtotal,
   |	SalesOrder.DiscountPercent,
   |	SalesOrder.Discount,
   |	SalesOrder.SubTotal,
   |	SalesOrder.Shipping,
   |	SalesOrder.SalesTax,
   |	SalesOrder.SalesTaxRC,
   |	SalesOrder.DocumentTotal,
   |	SalesOrder.DocumentTotalRC,
   |	SalesOrder.______Review______,
   |	SalesOrder.NewObject,
   |	SalesOrder.CF1String,
   |	SalesOrder.EmailNote,
   |	SalesOrder.SalesTaxRate,
   |	SalesOrder.DiscountIsTaxable,
   |	SalesOrder.SalesTaxAmount,
   |	SalesOrder.TaxableSubtotal,
   |	SalesOrder.ExternalMemo,
   |	SalesOrder.LineItems.(
   |		Ref,
   |		LineNumber,
   |		Product,
   |		ProductDescription,
   |		Quantity,
   |		UM,
   |		Price,
   |		LineTotal,
   |		Taxable,
   |		TaxableAmount,
   |		Location,
   |		DeliveryDate,
   |		Project,
   |		Class
   |	),
   |	SalesOrder.SalesTaxAcrossAgencies.(
   |		Ref,
   |		LineNumber,
   |		Agency,
   |		Rate,
   |		Amount,
   |		SalesTaxRate,
   |		SalesTaxComponent
   |	),
   |	GeneralJournalBalance.Account,
   |	GeneralJournalBalance.ExtDimension1,
   |	GeneralJournalBalance.ExtDimension2,
   |	GeneralJournalBalance.Currency AS Currency1,
   |	GeneralJournalBalance.AmountBalance,
   |	GeneralJournalBalance.AmountBalanceDr,
   |	GeneralJournalBalance.AmountBalanceCr,
   |	GeneralJournalBalance.AmountSplittedBalanceDr,
   |	GeneralJournalBalance.AmountSplittedBalanceCr,
   |	GeneralJournalBalance.AmountRCBalance AS Balance,
   |	GeneralJournalBalance.AmountRCBalanceDr,
   |	GeneralJournalBalance.AmountRCBalanceCr,
   |	GeneralJournalBalance.AmountRCSplittedBalanceDr,
   |	GeneralJournalBalance.AmountRCSplittedBalanceCr
   |FROM
   |	Document.SalesOrder AS SalesOrder
   |		LEFT JOIN AccountingRegister.GeneralJournal.Balance AS GeneralJournalBalance
   |		ON (GeneralJournalBalance.ExtDimension1 = SalesOrder.Company)
   |			AND (GeneralJournalBalance.ExtDimension2 = SalesOrder.Ref)
   |WHERE
   |	SalesOrder.Ref IN(&Ref)";
   Query.SetParameter("Ref", Ref);
   Selection = Query.Execute().Select();
  
   Spreadsheet.Clear();
   
    While Selection.Next() Do
	   
	BinaryLogo = GeneralFunctions.GetLogo();
	LogoPicture = New Picture(BinaryLogo);
	DocumentPrinting.FillLogoInDocumentTemplate(Template, LogoPicture); 
	
	Try
		FooterLogo = GeneralFunctions.GetFooterPO("SOfooter1");
		Footer1Pic = New Picture(FooterLogo);
		FooterLogo2 = GeneralFunctions.GetFooterPO("SOfooter2");
		Footer2Pic = New Picture(FooterLogo2);
		FooterLogo3 = GeneralFunctions.GetFooterPO("SOfooter3");
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
	If Selection.DropshipRefNum <> "" Then
		TemplateArea.Parameters.RefNum = Selection.DropshipRefNum;
	Else
		TemplateArea.Parameters.RefNum = Selection.RefNum;
	EndIf;
	TemplateArea.Parameters.SalesPerson = Selection.SalesPerson;
			
	////If Constants.SIShowFullName.Get() = True Then
	//If SessionParameters.TenantValue = "1100674" Or Constants.SIShowFullName.Get() = True Then
	//	TemplateArea.Parameters.ThemFullName = ThemBill.ThemBillSalutation + " " + ThemBill.ThemBillFirstName + " " + ThemBill.ThemBillLastName;
	//	TemplateArea.Parameters.ThemFullName2 = ThemShip.ThemShipSalutation + " " + ThemShip.ThemShipFirstName + " " + ThemShip.ThemShipLastName;

	//EndIf;
		
	If Constants.SOShowFullName.Get() = True Then
		TemplateArea.Parameters.ThemFullName = ThemBill.ThemBillSalutation + " " + ThemBill.ThemBillFirstName + " " + ThemBill.ThemBillLastName;
		TempFullName = ThemShip.ThemShipSalutation + " " + ThemShip.ThemShipFirstName + " " + ThemShip.ThemShipLastName;
		If TempFullName = TemplateArea.Parameters.ThemFullName Then
			TemplateArea.Parameters.ThemShipFullName = "";
		Else
			TemplateArea.Parameters.ThemShipFullName = TempFullName + Chars.LF;
		EndIf;
		
	EndIf;

	
	TemplateArea.Parameters.Date = Selection.Date;
	TemplateArea.Parameters.Number = Selection.Number;
	//TemplateArea.Parameters.RefNum = Selection.RefNum;
	//TemplateArea.Parameters.Carrier = Selection.Carrier;
	//TemplateArea.Parameters.TrackingNumber = Selection.TrackingNumber;
	//TemplateArea.Parameters.SalesPerson = Selection.SalesPerson;
	//TemplateArea.Parameters.FOB = Selection.FOB;
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
	
	//ThemShip filling
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
	 
	 Spreadsheet.Put(TemplateArea);
	 
	//If Constants.SOShowEmail.Get() = False Then
	//	Direction = SpreadsheetDocumentShiftType.Vertical;
	//	Area = Spreadsheet.Area("EmailArea");
	//	Spreadsheet.DeleteArea(Area, Direction);
	//	Spreadsheet.InsertArea(Spreadsheet.Area("R10"), Spreadsheet.Area("R10"), 
	//	SpreadsheetDocumentShiftType.Vertical);

	//EndIf;
	 
	If Constants.SOShowPhone2.Get() = False Then
		Direction = SpreadsheetDocumentShiftType.Vertical;
		Area = Spreadsheet.Area("MobileArea");
		Spreadsheet.DeleteArea(Area, Direction);
		Spreadsheet.InsertArea(Spreadsheet.Area("R10"), Spreadsheet.Area("R10"), 
        SpreadsheetDocumentShiftType.Vertical);
	EndIf;
	
	If Constants.SOShowWebsite.Get() = False Then
		Direction = SpreadsheetDocumentShiftType.Vertical;
		Area = Spreadsheet.Area("WebsiteArea");
		Spreadsheet.DeleteArea(Area, Direction);
		Spreadsheet.InsertArea(Spreadsheet.Area("R10"), Spreadsheet.Area("R10"), 
		SpreadsheetDocumentShiftType.Vertical);

	EndIf;
	
	If Constants.SOShowFax.Get() = False Then
		Direction = SpreadsheetDocumentShiftType.Vertical;
		Area = Spreadsheet.Area("FaxArea");
		Spreadsheet.DeleteArea(Area, Direction);
		Spreadsheet.InsertArea(Spreadsheet.Area("R10"), Spreadsheet.Area("R10"), 
		SpreadsheetDocumentShiftType.Vertical);

	EndIf;
	
	If Constants.SOShowFedTax.Get() = False Then
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
		LineTotal = SelectionLineItems.LineTotal;
		TemplateArea.Parameters.Quantity = Format(SelectionLineItems.Quantity, QuantityFormat); //+ " " + SelectionLineItems.Unit;
		TemplateArea.Parameters.Price = "$" + Format(SelectionLineItems.Price, "NFD=2; NZ=");
		TemplateArea.Parameters.LineTotal = "$" + Format(SelectionLineItems.LineTotal, "NFD=2; NZ=");
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

			If Constants.SOFoot1Type.Get()= Enums.TextOrImage.Image Then	
				DocumentPrinting.FillPictureInDocumentTemplate(Template, Footer1Pic, "SOfooter1");
				TemplateArea2 = Template.GetArea("FooterField|FooterSection1");	
				Spreadsheet.Put(TemplateArea2);
			Elsif Constants.SOFoot1Type.Get() = Enums.TextOrImage.Text Then
				TemplateArea2 = Template.GetArea("TextField|FooterSection1");
				TemplateArea2.Parameters.FooterTextLeft = Constants.OrderFooterTextLeft.Get();
				Spreadsheet.Put(TemplateArea2);
			EndIf;
		
			If Constants.SOFoot2Type.Get()= Enums.TextOrImage.Image Then
				DocumentPrinting.FillPictureInDocumentTemplate(Template, Footer2Pic, "SOfooter2");
				TemplateArea2 = Template.GetArea("FooterField|FooterSection2");	
				Spreadsheet.Join(TemplateArea2);
			
			Elsif Constants.SOFoot2Type.Get() = Enums.TextOrImage.Text Then
				TemplateArea2 = Template.GetArea("TextField|FooterSection2");
				TemplateArea2.Parameters.FooterTextCenter = Constants.OrderFooterTextCenter.Get();
				Spreadsheet.Join(TemplateArea2);
			EndIf;
		
			If Constants.SOFoot3Type.Get()= Enums.TextOrImage.Image Then
					DocumentPrinting.FillPictureInDocumentTemplate(Template, Footer3Pic, "SOfooter3");
					TemplateArea2 = Template.GetArea("FooterField|FooterSection3");	
					Spreadsheet.Join(TemplateArea2);
			Elsif Constants.SOFoot3Type.Get() = Enums.TextOrImage.Text Then
					TemplateArea2 = Template.GetArea("TextField|FooterSection3");
					TemplateArea2.Parameters.FooterTextRight = Constants.OrderFooterTextRight.Get();
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
	TemplateArea.Parameters.TermAndCond = Constants.SalesOrderFooter.Get();
	Spreadsheet.Put(TemplateArea);

	
	TemplateArea = Template.GetArea("Area3|Area2");
	TemplateArea.Parameters.LineSubtotal = Selection.Currency.Symbol + Format(Selection.LineSubtotal, "NFD=2; NZ=");
	TemplateArea.Parameters.Discount = "("+ Selection.Currency.Symbol + Format(Selection.Discount, "NFD=2; NZ=") + ")";
	TemplateArea.Parameters.Subtotal = Selection.Currency.Symbol + Format(Selection.Subtotal, "NFD=2; NZ=");
	TemplateArea.Parameters.Shipping = Selection.Currency.Symbol + Format(Selection.Shipping, "NFD=2; NZ=");
	TemplateArea.Parameters.SalesTax = Selection.Currency.Symbol + Format(Selection.SalesTax, "NFD=2; NZ=");
	TemplateArea.Parameters.Total = Selection.Currency.Symbol + Format(Selection.DocumentTotal, "NFD=2; NZ=");
//	TemplateArea.Parameters.Balance = Selection.Currency.Symbol + Format(Selection.Balance, "NFD=2; NZ=");

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
	
	If Constants.SOFoot1Type.Get()= Enums.TextOrImage.Image Then	
			DocumentPrinting.FillPictureInDocumentTemplate(Template, Footer1Pic, "SOfooter1");
			TemplateArea = Template.GetArea("FooterField|FooterSection1");	
			Spreadsheet.Put(TemplateArea);
	Elsif Constants.SOFoot1Type.Get() = Enums.TextOrImage.Text Then
			TemplateArea = Template.GetArea("TextField|FooterSection1");
			TemplateArea.Parameters.FooterTextLeft = Constants.OrderFooterTextLeft.Get();
			Spreadsheet.Put(TemplateArea);
	EndIf;
		
	If Constants.SOFoot2Type.Get()= Enums.TextOrImage.Image Then
			DocumentPrinting.FillPictureInDocumentTemplate(Template, Footer2Pic, "SOfooter2");
			TemplateArea = Template.GetArea("FooterField|FooterSection2");	
			Spreadsheet.Join(TemplateArea);		
	Elsif Constants.SOFoot2Type.Get() = Enums.TextOrImage.Text Then
			TemplateArea = Template.GetArea("TextField|FooterSection2");
			TemplateArea.Parameters.FooterTextCenter = Constants.OrderFooterTextCenter.Get();
			Spreadsheet.Join(TemplateArea);
	EndIf;
		
	If Constants.SOFoot3Type.Get()= Enums.TextOrImage.Image Then
			DocumentPrinting.FillPictureInDocumentTemplate(Template, Footer3Pic, "SOfooter3");
			TemplateArea = Template.GetArea("FooterField|FooterSection3");	
			Spreadsheet.Join(TemplateArea);
	Elsif Constants.SOFoot3Type.Get() = Enums.TextOrImage.Text Then
			TemplateArea = Template.GetArea("TextField|FooterSection3");
			TemplateArea.Parameters.FooterTextRight = Constants.OrderFooterTextRight.Get();
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

	//QuantityFormat = GeneralFunctionsReusable.DefaultQuantityFormat();
	Header = Template.GetArea("Header");
	AreaLineItems = Template.GetArea("LineItems");
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
		             |		WHEN OrdersStatusesSliceLast.Status = VALUE(Enum.OrderStatuses.Backordered)
		             |				AND OrdersRegisteredBalance.QuantityBalance >= OrdersRegisteredBalance.ShippedBalance
		             |			THEN OrdersRegisteredBalance.QuantityBalance - OrdersRegisteredBalance.ShippedBalance
		             |		WHEN OrdersStatusesSliceLast.Status = VALUE(Enum.OrderStatuses.Closed)
		             |			THEN 0
		             |		ELSE SalesOrderLineItems.Quantity
		             |	END AS Needed,
		             |	CASE
		             |		WHEN ISNULL(InventoryJournalBalance.QuantityBalance, 0) <= CASE
		             |				WHEN OrdersStatusesSliceLast.Status = VALUE(Enum.OrderStatuses.Backordered)
		             |						AND OrdersRegisteredBalance.QuantityBalance >= OrdersRegisteredBalance.ShippedBalance
		             |					THEN OrdersRegisteredBalance.QuantityBalance - OrdersRegisteredBalance.ShippedBalance
		             |				WHEN OrdersStatusesSliceLast.Status = VALUE(Enum.OrderStatuses.Closed)
		             |					THEN 0
		             |				ELSE SalesOrderLineItems.Quantity
		             |			END
		             |			THEN ISNULL(InventoryJournalBalance.QuantityBalance, 0)
		             |		ELSE CASE
		             |				WHEN OrdersStatusesSliceLast.Status = VALUE(Enum.OrderStatuses.Backordered)
		             |						AND OrdersRegisteredBalance.QuantityBalance >= OrdersRegisteredBalance.ShippedBalance
		             |					THEN OrdersRegisteredBalance.QuantityBalance - OrdersRegisteredBalance.ShippedBalance
		             |				WHEN OrdersStatusesSliceLast.Status = VALUE(Enum.OrderStatuses.Closed)
		             |					THEN 0
		             |				ELSE SalesOrderLineItems.Quantity
		             |			END
		             |	END AS ToPick
		             |FROM
		             |	Document.SalesOrder.LineItems AS SalesOrderLineItems
		             |		LEFT JOIN InformationRegister.OrdersStatuses.SliceLast AS OrdersStatusesSliceLast
		             |		ON SalesOrderLineItems.Ref = OrdersStatusesSliceLast.Order
		             |		LEFT JOIN AccumulationRegister.OrdersRegistered.Balance AS OrdersRegisteredBalance
		             |		ON SalesOrderLineItems.Ref = OrdersRegisteredBalance.Order
		             |			AND SalesOrderLineItems.Ref.Company = OrdersRegisteredBalance.Company
		             |			AND SalesOrderLineItems.Product = OrdersRegisteredBalance.Product
		             |			AND SalesOrderLineItems.Location = OrdersRegisteredBalance.Location
		             |			AND SalesOrderLineItems.DeliveryDate = OrdersRegisteredBalance.DeliveryDate
		             |			AND SalesOrderLineItems.Project = OrdersRegisteredBalance.Project
		             |			AND SalesOrderLineItems.Class = OrdersRegisteredBalance.Class
		             |			AND SalesOrderLineItems.Quantity = OrdersRegisteredBalance.QuantityBalance
		             |		LEFT JOIN AccumulationRegister.InventoryJournal.Balance AS InventoryJournalBalance
		             |		ON SalesOrderLineItems.Product = InventoryJournalBalance.Product
		             |			AND SalesOrderLineItems.Location = InventoryJournalBalance.Location
		             |WHERE
		             |	SalesOrderLineItems.Ref = &Ref
		             |	AND SalesOrderLineItems.Product.Type = VALUE(Enum.InventoryTypes.Inventory)
		             |	AND CASE
		             |			WHEN OrdersStatusesSliceLast.Status = VALUE(Enum.OrderStatuses.Backordered)
		             |					AND OrdersRegisteredBalance.QuantityBalance >= OrdersRegisteredBalance.ShippedBalance
		             |				THEN OrdersRegisteredBalance.QuantityBalance - OrdersRegisteredBalance.ShippedBalance
		             |			WHEN OrdersStatusesSliceLast.Status = VALUE(Enum.OrderStatuses.Closed)
		             |				THEN 0
		             |			ELSE SalesOrderLineItems.Quantity
		             |		END > 0
		             |
		             |ORDER BY
		             |	SalesOrderLineItems.LineNumber";
					 
		Query.SetParameter("Ref", RefLine.Ref);
		
		Selection = Query.Execute().Select();
		
		While Selection.Next() Do
			AreaLineItems.Parameters.Fill(Selection);
			//AreaLineItems.Parameters.Needed = Format(Selection.Needed, QuantityFormat)+ " " + Selection.Unit;
			//AreaLineItems.Parameters.ToPick = Format(Selection.ToPick, QuantityFormat)+ " " + Selection.UM;
			Spreadsheet.Put(AreaLineItems);
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
	|	LineItems.UM                          AS Unit,
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

