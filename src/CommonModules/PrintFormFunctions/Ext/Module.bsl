
Function PrintSO(Spreadsheet, SheetTitle, Ref, TemplateName = Undefined) Export
	
	TestData = New Map(); // creating a structure of print form data for testing
	
	SheetTitle = "Sales order";
	CustomTemplate = GeneralFunctions.GetCustomTemplate("Document.SalesOrder", SheetTitle);
	
	If CustomTemplate = Undefined Then
		Template = Documents.SalesOrder.GetTemplate("New_SalesOrder_Form");
	Else
		Template = CustomTemplate;
	EndIf;
	
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
   |	SalesOrder.UseAvatax,
   |	SalesOrder.SalesTax,
   |	SalesOrder.SalesTaxRC,
   |	SalesOrder.DocumentTotal,
   |	SalesOrder.DocumentTotalRC,
   |	SalesOrder.CF1String,
   |	SalesOrder.EmailNote,
   |	SalesOrder.SalesTaxRate,
   |	SalesOrder.DiscountIsTaxable,
   |	SalesOrder.SalesTaxAmount,
   |	SalesOrder.TaxableSubtotal,
   |	SalesOrder.LineItems.(
   |		Ref,
   |		LineNumber,
   |		Product,
   |		ProductDescription,
   |		QtyUnits,
   |		Unit,
   |		QtyUM,
   |		PriceUnits,
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
   |	GeneralJournalBalance.AmountRCSplittedBalanceCr,
   |	ISNULL(OrderTransactionsBalance.AmountBalance, 0) AS BalanceDue,
   |	- ISNULL(GeneralJournalOrderBalance.AmountBalance, 0) AS SOBalance
   |FROM
   |	Document.SalesOrder AS SalesOrder
   |		LEFT JOIN AccountingRegister.GeneralJournal.Balance AS GeneralJournalBalance
   |		ON (GeneralJournalBalance.ExtDimension1 = SalesOrder.Company)
   |			AND (GeneralJournalBalance.ExtDimension2 = SalesOrder.Ref)
   |		LEFT JOIN AccumulationRegister.OrderTransactions.Balance AS OrderTransactionsBalance
   |		ON (OrderTransactionsBalance.Order = SalesOrder.Ref)
   |		LEFT JOIN AccountingRegister.GeneralJournal.Balance (,,, ExtDimension1 REFS Catalog.Companies AND ExtDimension2 REFS Document.CashReceipt) AS GeneralJournalOrderBalance
   |		ON (GeneralJournalOrderBalance.ExtDimension1 = SalesOrder.Company)
   |			AND (Isnull(GeneralJournalOrderBalance.ExtDimension2.SalesOrder, Undefined) = SalesOrder.Ref)
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
			
	If Constants.SOShowFullName.Get() = True Then
		TemplateArea.Parameters.ThemFullName = GetDescriptionContactPerson(ThemBill, "Bill");
		TempFullName = GetDescriptionContactPerson(ThemShip, "Ship");
		If TempFullName = TemplateArea.Parameters.ThemFullName Then
			TemplateArea.Parameters.ThemShipFullName = "";
		Else
			TemplateArea.Parameters.ThemShipFullName = TempFullName + Chars.LF;
		EndIf;
		
	EndIf;

	If Constants.SOShowCountry.Get() = False Then
		TemplateArea.Parameters.ThemBillCountry = "";
		TemplateArea.Parameters.ThemShipCountry = "";
	EndIf;
	
	TemplateArea.Parameters.Date = Selection.Date;
	TemplateArea.Parameters.Number = Selection.Number;
	
	TestData.Insert("Number", Selection.Number); // for unit testing
	
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
	
	If TemplateArea.Parameters.ThemBillCityStateZIP <> "" Then
		TemplateArea.Parameters.ThemBillCityStateZIP = TemplateArea.Parameters.ThemBillCityStateZIP + Chars.LF; 
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
	
	If TemplateArea.Parameters.ThemShipCityStateZIP <> "" Then
		TemplateArea.Parameters.ThemShipCityStateZIP = TemplateArea.Parameters.ThemShipCityStateZIP + Chars.LF; 
	EndIf;
	
	TestData.Insert("ThemShip_ThemShipZIP", ThemShip.ThemShipZIP); //for unit testing
	 
	Spreadsheet.Put(TemplateArea);
	 	 
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
		TemplateArea.Parameters.UM = SelectionLineItems.Unit.Code;
		//TemplateArea.Parameters.Quantity = Format(SelectionLineItems.QtyUnits, QuantityFormat)+ " " + SelectionLineItems.Unit;
		ProductPrecisionFormat = GeneralFunctionsReusable.PriceFormatForOneItem(SelectionLineItems.Product);
		TemplateArea.Parameters.Price     = Format(SelectionLineItems.PriceUnits, ProductPrecisionFormat + "; NZ=");
		TemplateArea.Parameters.LineTotal = Format(SelectionLineItems.LineTotal, "NFD=2; NZ=");
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
	TemplateArea.Parameters.TermAndCond = Selection.EmailNote;
	Spreadsheet.Put(TemplateArea);

	
	TemplateArea = Template.GetArea("Area3|Area2");
	TemplateArea.Parameters.LineSubtotal  = Format(Selection.LineSubtotal, "NFD=2; NZ=");
	TemplateArea.Parameters.Discount      = Format(Selection.Discount, "NFD=2; NZ=");
	TemplateArea.Parameters.Subtotal      = Format(Selection.Subtotal, "NFD=2; NZ=");
	TemplateArea.Parameters.Shipping      = Format(Selection.Shipping, "NFD=2; NZ=");
	TemplateArea.Parameters.SalesTaxTitle = GetDescriptionSalesTax(Selection.Ref, Selection.UseAvatax);
	TemplateArea.Parameters.SalesTax      = Format(Selection.SalesTax, "NFD=2; NZ=");
	TemplateArea.Parameters.NetTotalTitle =  "Net Total " + Selection.Currency.Description + ":";
	TemplateArea.Parameters.Total         = Format(Selection.DocumentTotal, "NFD=2; NZ=");
	
	If Constants.SOPrintBalance.Get() Then 
		If Constants.UseSOPrepayment.Get() Then 
			TemplateArea.Parameters.BalanceDueTitle = "Prepayment balance " + Selection.Currency.Description + ":";
			TemplateArea.Parameters.BalanceDue      = Format(Selection.SOBalance, "NFD=2; NZ=");
		Else 
			TemplateArea.Parameters.BalanceDueTitle = "Balance due " + Selection.Currency.Description + ":";
			TemplateArea.Parameters.BalanceDue      = Format(Selection.BalanceDue, "NFD=2; NZ=");
		EndIf;
	EndIf;

	TestData.Insert("Total",TemplateArea.Parameters.Total); // for unit testing
	TestData.Insert("Currency", Selection.Currency.Symbol); // for unit testing

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
		
	Spreadsheet.PutHorizontalPageBreak();
	Spreadsheet.FitToPage  = True;
	
	// Remove footer information if only a page.
	If Spreadsheet.PageCount() = 1 Then
		Spreadsheet.Footer.Enabled = False;
	EndIf;

	EndDo;

	Return TestData;	
   
EndFunction

Function PrintSI(Spreadsheet, SheetTitle, Ref, TemplateName = Undefined) Export
	
	TestData = New Map(); // creating a structure of print form data for testing
	
	SheetTitle = "Sales invoice";
	CustomTemplate = GeneralFunctions.GetCustomTemplate("Document.SalesInvoice", SheetTitle);
	
	If CustomTemplate = Undefined Then
		//If Constants.SalesInvoicePO.Get() = False Then
			Template = Documents.SalesInvoice.GetTemplate("New_SalesInvoice_Form");//("PF_MXL_SalesInvoice");
		//ElsIf Constants.SalesInvoicePO.Get() = True Then
		//	Template = Documents.SalesInvoice.GetTemplate("PF_MXL_SalesInvoice_PO");
		//EndIf;
	Else
		Template = CustomTemplate;
	EndIf;
	
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
   |		Product.Category AS Category,
   |		ProductDescription,
   |		LineItems.Order.RefNum AS PO,
   |		QtyUnits,
   |		Unit,
   |		QtyUM,
   |		PriceUnits,
   |		Product.Price AS StandardPrice,
   |		LineTotal,
   |		Project,
   |		Class,
   |		DeliveryDateActual,
   |		Lot
   |	),
   |	SalesInvoice.Terms,
   |	SalesInvoice.DueDate,
   |	GeneralJournalBalance.AmountRCBalance AS BalanceRC,
   |	GeneralJournalBalance.AmountBalance AS Balance,
   |	SalesInvoice.BillTo,
   |	SalesInvoice.ConfirmTo,
   |	SalesInvoice.Posted,
   |	SalesInvoice.LineSubtotal,
   |	SalesInvoice.Discount,
   |	SalesInvoice.SubTotal,
   |	SalesInvoice.Shipping,
   |	SalesInvoice.UseAvatax,
   |	SalesInvoice.DocumentTotal AS DocumentTotal1,
   |	SalesInvoice.RefNum,
   |	SalesInvoice.TrackingNumber,
   |	SalesInvoice.Carrier,
   |	SalesInvoice.SalesPerson,
   |	SalesInvoice.FOB,
   |	SalesInvoice.DropshipCompany,
   |	SalesInvoice.DropshipShipTo,
   |	SalesInvoice.DropshipRefNum,
   |	SalesInvoice.LocationActual,
   |	SalesInvoice.SalesTaxAcrossAgencies.(
   |		Ref,
   |		LineNumber,
   |		Agency,
   |		Rate,
   |		Amount,
   |		SalesTaxRate,
   |		SalesTaxComponent,
   |		AvataxTaxComponent
   |	)
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
		TemplateArea.Parameters.ThemFullName = GetDescriptionContactPerson(ThemBill, "Bill") + Chars.LF;
		TemplateArea.Parameters.ThemShipFullName = GetDescriptionContactPerson(ThemShip, "Ship") + Chars.LF;
	EndIf;
	
	If Constants.SIShowCountry.Get() = False Then
		TemplateArea.Parameters.ThemBillCountry = "";
		TemplateArea.Parameters.ThemShipCountry = "";
	EndIf;
	
	TemplateArea.Parameters.Date = Selection.Date;
	TemplateArea.Parameters.Number = Selection.Number;
	
	TestData.Insert("Number",TemplateArea.Parameters.Number); // for unit testing
	
	If Selection.DropshipShipTo <> Catalogs.Addresses.EmptyRef() Then
		TemplateArea.Parameters.RefNum = Selection.DropShipRefNum;	
	Else 
		TemplateArea.Parameters.RefNum = Selection.RefNum;
	EndIf;
	
	TemplateArea.Parameters.Carrier = Selection.Carrier;
	TemplateArea.Parameters.TrackingNumber = Selection.TrackingNumber;
	TemplateArea.Parameters.SalesPerson = Selection.SalesPerson;
	TemplateArea.Parameters.FOB = Selection.FOB;
	If ValueIsFilled(Selection.ConfirmTo) Then 
		TemplateArea.Parameters.ConfirmTo = GetDescriptionContactPerson(PrintTemplates.ContactInfoDataset(Selection.Company, "ThemBill", Selection.ConfirmTo), "Bill");
	EndIf;

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
	
	If TemplateArea.Parameters.ThemBillCityStateZIP <> "" Then
		TemplateArea.Parameters.ThemBillCityStateZIP = TemplateArea.Parameters.ThemBillCityStateZIP + Chars.LF; 
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
	
	If TemplateArea.Parameters.ThemShipCityStateZIP <> "" Then
		TemplateArea.Parameters.ThemShipCityStateZIP = TemplateArea.Parameters.ThemShipCityStateZIP + Chars.LF; 
	EndIf;

	
	TestData.Insert("ThemBill_Line1", ThemBill.ThemBillLine1); // for unit testing
	TestData.Insert("ThemShip_City", ThemBill.ThemBillCity);
	 
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
	ShowClass    = Constants.SIShowClassCol.Get();
	ShowSVC      = Constants.SIShowSVCCol.Get();
	ShowDiscount = Constants.SIShowDiscountCol.Get();
	If ShowSVC = True Then
		TemplateArea = Template.GetArea("LineItemsHeaderService");
		Spreadsheet.Put(TemplateArea);
		TemplateArea = Template.GetArea("LineItems3Service");
	ElsIf ShowClass Then
		TemplateArea = Template.GetArea("LineItemsHeaderLot");
		Spreadsheet.Put(TemplateArea);
		TemplateArea = Template.GetArea("LineItems5Lot");	
	ElsIf ShowDiscount Then
		TemplateArea = Template.GetArea("LineItemsHeaderDiscount");
		Spreadsheet.Put(TemplateArea);
		TemplateArea = Template.GetArea("LineItems7Discount");	
	Else
		TemplateArea = Template.GetArea("LineItemsHeader");
		Spreadsheet.Put(TemplateArea);
		TemplateArea = Template.GetArea("LineItems");
	EndIf;

	LineTotalSum = 0;
	LineItemSwitch = False;
	CurrentLineItemIndex = 0;
	QuantityFormat = GeneralFunctionsReusable.DefaultQuantityFormat();
	OnlyServiceItems = True;
	
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
		
		If SelectionLineItems.Product.Type = Enums.InventoryTypes.Inventory Then
			OnlyServiceItems = False;
		EndIf;
		
		LineTotal = SelectionLineItems.LineTotal;
		TemplateArea.Parameters.UM = SelectionLineItems.Unit.Code;
		//TemplateArea.Parameters.Quantity  = Format(SelectionLineItems.QtyUnits, QuantityFormat)+ " " + SelectionLineItems.Unit;
		ProductPrecisionFormat = GeneralFunctionsReusable.PriceFormatForOneItem(SelectionLineItems.Product);
		TemplateArea.Parameters.Price     = Format(SelectionLineItems.PriceUnits, ProductPrecisionFormat + "; NZ=");
		TemplateArea.Parameters.LineTotal = Format(SelectionLineItems.LineTotal, "NFD=2; NZ=");
		If ShowSVC Then
			TemplateArea.Parameters.DeliveryDate = Format(SelectionLineItems.DeliveryDateActual,"DLF=D;");
		ElsIf ShowDiscount Then
			TemplateArea.Parameters.StandardPrice = Format(SelectionLineItems.StandardPrice, ProductPrecisionFormat + "; NZ=");
			TemplateArea.Parameters.Discount      = Format(?(SelectionLineItems.StandardPrice <> 0, (((SelectionLineItems.PriceUnits / SelectionLineItems.StandardPrice) * 100) - 100) * -1 , 0), "NFD=2; NZ=0.00") + " %";
		EndIf;

		Spreadsheet.Put(TemplateArea, SelectionLineItems.Level());
		
		If LineItemSwitch = False Then
			If ShowSVC Then
				TemplateArea = Template.GetArea("LineItems4Service");	
			ElsIf ShowClass Then
				TemplateArea = Template.GetArea("LineItems6Lot");
			ElsIf ShowDiscount Then
				TemplateArea = Template.GetArea("LineItems8Discount");
			Else
				TemplateArea = Template.GetArea("LineItems2");
			EndIf;
			LineItemSwitch = True;
		Else
			If ShowSVC Then
				TemplateArea = Template.GetArea("LineItems3Service");	
			ElsIf ShowClass Then
				TemplateArea = Template.GetArea("LineItems5Lot");
			ElsIf ShowDiscount Then
				TemplateArea = Template.GetArea("LineItems7Discount");
			Else
				TemplateArea = Template.GetArea("LineItems");
			EndIf;
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
	
	// If line items are all service, remove shipTo	
	If Constants.SIShowShipTo.Get() = False And OnlyServiceItems = True Then
		Direction = SpreadsheetDocumentShiftType.Horizontal;
		Area = Spreadsheet.Area("PreAddrArea");
		Spreadsheet.DeleteArea(Area, Direction);	
		
		Area = Spreadsheet.Area("ShipToArea");
		Spreadsheet.DeleteArea(Area, Direction);
	EndIf;
	
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
	TemplateArea.Parameters.LineSubtotal = Format(Selection.LineSubtotal, "NFD=2; NZ=");
	TemplateArea.Parameters.Discount = "(" + Format(Selection.Discount, "NFD=2; NZ=") + ")";
	//TemplateArea.Parameters.Subtotal = Format(Selection.Subtotal, "NFD=2; NZ=");
	TemplateArea.Parameters.Shipping = Format(Selection.Shipping, "NFD=2; NZ=");
	If Selection.LocationActual.Country <> Catalogs.Countries.FindByCode("US") AND Selection.LocationActual.Country <> Catalogs.Countries.EmptyRef() AND Selection.Ref.UseAvatax = True Then
		TemplateArea.Parameters.SalesTaxTitle = "VAT (" + Selection.Ref.SalesTaxAcrossAgencies[0].Rate + "%)";
		TemplateArea.Parameters.SalesTax = Format(Selection.Ref.SalesTaxAcrossAgencies[0].Amount, "NFD=2; NZ=");
	Else
		TemplateArea.Parameters.SalesTaxTitle = GetDescriptionSalesTax(Selection.Ref, Selection.UseAvatax);
		TemplateArea.Parameters.SalesTax = Format(Selection.SalesTax, "NFD=2; NZ=");
	EndIf;
	TemplateArea.Parameters.Total = Format(Selection.DocumentTotal, "NFD=2; NZ=");
	// change here if need to disable showing currency if multi-currency isn't enabled
	TemplateArea.Parameters.NetTotalTitle = "Net Total " + Selection.Currency.Description + ":";
	//TemplateArea.Parameters.PaymentsCreditsTitle = "Payments/Credits:";
	TemplateArea.Parameters.BalanceDueTitle = "Balance Due " + Selection.Currency.Description + ":";
	// end change here
	NonNullBalance = 0;
	If Selection.Balance <> NULL Then NonNullBalance = Selection.Balance; EndIf;
	TemplateArea.Parameters.Balance = Format(NonNullBalance, "NFD=2; NZ=");
	Try
		PaymentsCredits = ?(Selection.Posted, Selection.DocumentTotal - NonNullBalance, 0);
		
		TemplateArea.Parameters.PaymentsCredits = Format(PaymentsCredits, "NFD=2; NZ=");
	Except
	EndTry;
	TestData.Insert("Currency",Selection.Currency.Symbol); // for unit testing
	TestData.Insert("LineSubtotal",TemplateArea.Parameters.LineSubtotal);
	
	Spreadsheet.Join(TemplateArea);	
		
	Row = Template.GetArea("EmptyRow");
	Footer = Template.GetArea("FooterField");
	Compensator = Template.GetArea("Compensator");
	SIFooter1 = Constants.SIFoot1Type.Get();
	SIFooter2 = Constants.SIFoot2Type.Get();
	SIFooter3 = Constants.SIFoot3Type.Get();
	SIFooterNone = Enums.TextOrImage.None;
	
	PrintSIFooter =  Not ((SIFooter1 = SIFooterNone) And (SIFooter2 = SIFooterNone) And (SIFooter3 = SIFooterNone));
	
	RowsToCheck = New Array();
	RowsToCheck.Add(Row);
	If PrintSIFooter Then 
		RowsToCheck.Add(Footer);
	EndIf;
	RowsToCheck.Add(Row);	
	
	While Spreadsheet.CheckPut(RowsToCheck) = False Do
		Spreadsheet.Put(Row);
	   	RowsToCheck.Clear();
	  	If PrintSIFooter Then 
			RowsToCheck.Add(Footer);
		EndIf;
		RowsToCheck.Add(Row);
	EndDo;
	 
	While Spreadsheet.CheckPut(RowsToCheck) Do
		Spreadsheet.Put(Row);
	   	RowsToCheck.Clear();
	  	If PrintSIFooter Then 
			RowsToCheck.Add(Footer);
		EndIf;
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
	
	Spreadsheet.PutHorizontalPageBreak();
	Spreadsheet.FitToPage  = True;
	
	// Remove footer information if only a page.
	If Spreadsheet.PageCount() = 1 Then
		Spreadsheet.Footer.Enabled = False;
	EndIf;

   EndDo;
   
   Return TestData;
		
EndFunction

Function PrintShipment(Spreadsheet, SheetTitle, Ref, TemplateName = Undefined) Export
	
	SheetTitle = "Shipment";
	CustomTemplate = GeneralFunctions.GetCustomTemplate("Document.Shipment", SheetTitle);
	
	If CustomTemplate = Undefined Then
		Template = Documents.Shipment.GetTemplate("ShipmentPrintForm");
	Else
		Template = CustomTemplate;
	EndIf;
	
	// Quering necessary data.
	Query = New Query();
	Query.Text = "SELECT
	             |	Shipment.Ref,
	             |	Shipment.Company,
	             |	Shipment.Date,
	             |	Shipment.Number,
	             |	Shipment.ShipTo,
	             |	Shipment.LineItems.(
	             |		Product,
	             |		ProductDescription,
	             |		LineItems.Order.RefNum AS PO,
	             |		QtyUnits,
	             |		Unit,
	             |		QtyUM,
	             |		Project,
	             |		DeliveryDateActual,
	             |		Lot
	             |	),
	             |	Shipment.Terms,
	             |	Shipment.BillTo,
	             |	Shipment.Posted,
	             |	Shipment.RefNum,
	             |	Shipment.TrackingNumber,
	             |	Shipment.Carrier,
	             |	Shipment.SalesPerson,
	             |	Shipment.FOB,
	             |	Shipment.DropshipCompany,
	             |	Shipment.DropshipShipTo,
	             |	Shipment.DropshipRefNum,
	             |	Shipment.LocationActual
	             |FROM
	             |	Document.Shipment AS Shipment
	             |WHERE
	             |	Shipment.Ref IN(&Ref)";
				
	Query.SetParameter("Ref", Ref);
	Selection = Query.Execute().Select();
   
   Spreadsheet.Clear();

   While Selection.Next() Do
	   
	BinaryLogo = GeneralFunctions.GetLogo();
	LogoPicture = New Picture(BinaryLogo);
	DocumentPrinting.FillLogoInDocumentTemplate(Template, LogoPicture); 
	
	Try
		FooterLogo = GeneralFunctions.GetFooterPO("ShipmentFooter1");
		Footer1Pic = New Picture(FooterLogo);
		FooterLogo2 = GeneralFunctions.GetFooterPO("ShipmentFooter2");
		Footer2Pic = New Picture(FooterLogo2);
		FooterLogo3 = GeneralFunctions.GetFooterPO("ShipmentFooter3");
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
		
	If Constants.ShipmentShowFullName.Get() = True Then
		TemplateArea.Parameters.ThemFullName = GetDescriptionContactPerson(ThemBill, "Bill") + Chars.LF;
		TemplateArea.Parameters.ThemShipFullName = GetDescriptionContactPerson(ThemShip, "Ship") + Chars.LF;
	EndIf;
	
	If Constants.ShipmentShowCountry.Get() = False Then
		TemplateArea.Parameters.ThemBillCountry = "";
		TemplateArea.Parameters.ThemShipCountry = "";
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
	
	If TemplateArea.Parameters.UsBillEmail <> "" AND Constants.ShipmentShowEmail.Get() = False Then
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
	
	If TemplateArea.Parameters.ThemBillCityStateZIP <> "" Then
		TemplateArea.Parameters.ThemBillCityStateZIP = TemplateArea.Parameters.ThemBillCityStateZIP + Chars.LF; 
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
	
	If TemplateArea.Parameters.ThemShipCityStateZIP <> "" Then
		TemplateArea.Parameters.ThemShipCityStateZIP = TemplateArea.Parameters.ThemShipCityStateZIP + Chars.LF; 
	EndIf;

	Spreadsheet.Put(TemplateArea);
	 	 
	If Constants.ShipmentShowPhone2.Get() = False Then
		Direction = SpreadsheetDocumentShiftType.Vertical;
		Area = Spreadsheet.Area("MobileArea");
		Spreadsheet.DeleteArea(Area, Direction);
		Spreadsheet.InsertArea(Spreadsheet.Area("R10"), Spreadsheet.Area("R10"), 
        SpreadsheetDocumentShiftType.Vertical);
	EndIf;
	
	If Constants.ShipmentShowWebsite.Get() = False Then
		Direction = SpreadsheetDocumentShiftType.Vertical;
		Area = Spreadsheet.Area("WebsiteArea");
		Spreadsheet.DeleteArea(Area, Direction);
		Spreadsheet.InsertArea(Spreadsheet.Area("R10"), Spreadsheet.Area("R10"), 
		SpreadsheetDocumentShiftType.Vertical);

	EndIf;
	
	If Constants.ShipmentShowFax.Get() = False Then
		Direction = SpreadsheetDocumentShiftType.Vertical;
		Area = Spreadsheet.Area("FaxArea");
		Spreadsheet.DeleteArea(Area, Direction);
		Spreadsheet.InsertArea(Spreadsheet.Area("R10"), Spreadsheet.Area("R10"), 
		SpreadsheetDocumentShiftType.Vertical);

	EndIf;
	
	SelectionLineItems = Selection.LineItems.Select();
	ShowClass = Constants.ShipmentShowClassCol.Get();
	ShowSVC = Constants.ShipmentShowSVCCol.Get();
	If ShowSVC = True Then
		TemplateArea = Template.GetArea("LineItemsHeaderService");
		Spreadsheet.Put(TemplateArea);
		TemplateArea = Template.GetArea("LineItems3Service");
	ElsIf ShowClass Then
		TemplateArea = Template.GetArea("LineItemsHeaderLot");
		Spreadsheet.Put(TemplateArea);
		TemplateArea = Template.GetArea("LineItems5Lot");	
	Else
		TemplateArea = Template.GetArea("LineItemsHeader");
		Spreadsheet.Put(TemplateArea);
		TemplateArea = Template.GetArea("LineItems");
	EndIf;

	LineItemSwitch = False;
	CurrentLineItemIndex = 0;
	QuantityFormat = GeneralFunctionsReusable.DefaultQuantityFormat();
	OnlyServiceItems = True;
	
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
		
		If SelectionLineItems.Product.Type = Enums.InventoryTypes.Inventory Then
			OnlyServiceItems = False;
		EndIf;
		
		TemplateArea.Parameters.UM = SelectionLineItems.Unit.Code;
		ProductPrecisionFormat = GeneralFunctionsReusable.PriceFormatForOneItem(SelectionLineItems.Product);
		If ShowSVC = True Then
			TemplateArea.Parameters.DeliveryDateActual = Format(SelectionLineItems.DeliveryDateActual,"DLF=D;");
		EndIf;

		Spreadsheet.Put(TemplateArea, SelectionLineItems.Level());
		
		If LineItemSwitch = False Then
			If ShowSVC = True Then
				TemplateArea = Template.GetArea("LineItems4Service");	
			Elsif ShowClass Then
				TemplateArea = Template.GetArea("LineItems6Lot");
			Else
				TemplateArea = Template.GetArea("LineItems2");
			EndIf;
			LineItemSwitch = True;
		Else
			If ShowSVC = True Then
				TemplateArea = Template.GetArea("LineItems3Service");
			Elsif ShowClass Then
				TemplateArea = Template.GetArea("LineItems5Lot");
			Else
				TemplateArea = Template.GetArea("LineItems");
			EndIf;
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

			If Constants.ShipmentFoot1Type.Get()= Enums.TextOrImage.Image Then	
				DocumentPrinting.FillPictureInDocumentTemplate(Template, Footer1Pic, "footer1");
				TemplateArea2 = Template.GetArea("FooterField|FooterSection1");	
				Spreadsheet.Put(TemplateArea2);
			Elsif Constants.ShipmentFoot1Type.Get() = Enums.TextOrImage.Text Then
				TemplateArea2 = Template.GetArea("TextField|FooterSection1");
				TemplateArea2.Parameters.FooterTextLeft = Constants.ShipmentFooterTextLeft.Get();
				Spreadsheet.Put(TemplateArea2);
			EndIf;
		
			If Constants.ShipmentFoot2Type.Get()= Enums.TextOrImage.Image Then
				DocumentPrinting.FillPictureInDocumentTemplate(Template, Footer2Pic, "footer2");
				TemplateArea2 = Template.GetArea("FooterField|FooterSection2");	
				Spreadsheet.Join(TemplateArea2);
			
			Elsif Constants.ShipmentFoot2Type.Get() = Enums.TextOrImage.Text Then
				TemplateArea2 = Template.GetArea("TextField|FooterSection2");
				TemplateArea2.Parameters.FooterTextCenter = Constants.ShipmentFooterTextCenter.Get();
				Spreadsheet.Join(TemplateArea2);
			EndIf;
		
			If Constants.ShipmentFoot3Type.Get()= Enums.TextOrImage.Image Then
					DocumentPrinting.FillPictureInDocumentTemplate(Template, Footer3Pic, "footer3");
					TemplateArea2 = Template.GetArea("FooterField|FooterSection3");	
					Spreadsheet.Join(TemplateArea2);
			Elsif Constants.ShipmentFoot3Type.Get() = Enums.TextOrImage.Text Then
					TemplateArea2 = Template.GetArea("TextField|FooterSection3");
					TemplateArea2.Parameters.FooterTextRight = Constants.ShipmentFooterTextRight.Get();
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
	
	// If line items are all service, remove shipTo	
	If Constants.ShipmentShowShipTo.Get() = False And OnlyServiceItems = True Then
		Direction = SpreadsheetDocumentShiftType.Horizontal;
		Area = Spreadsheet.Area("PreAddrArea");
		Spreadsheet.DeleteArea(Area, Direction);	
		
		Area = Spreadsheet.Area("ShipToArea");
		Spreadsheet.DeleteArea(Area, Direction);
	EndIf;
	
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
	
	TemplateArea = Template.GetArea("Area3");	
	//TemplateArea.Parameters.TermAndCond = Selection.Ref.EmailNote;
	Spreadsheet.Put(TemplateArea);
		
	Row = Template.GetArea("EmptyRow");
	Footer = Template.GetArea("FooterField");
	Compensator = Template.GetArea("Compensator");
	SIFooter1 = Constants.ShipmentFoot1Type.Get();
	SIFooter2 = Constants.ShipmentFoot2Type.Get();
	SIFooter3 = Constants.ShipmentFoot3Type.Get();
	SIFooterNone = Enums.TextOrImage.None;
	
	PrintSIFooter =  Not ((SIFooter1 = SIFooterNone) And (SIFooter2 = SIFooterNone) And (SIFooter3 = SIFooterNone));
	
	RowsToCheck = New Array();
	RowsToCheck.Add(Row);
	If PrintSIFooter Then 
		RowsToCheck.Add(Footer);
	EndIf;
	RowsToCheck.Add(Row);	
	
	While Spreadsheet.CheckPut(RowsToCheck) = False Do
		Spreadsheet.Put(Row);
	   	RowsToCheck.Clear();
	  	If PrintSIFooter Then 
			RowsToCheck.Add(Footer);
		EndIf;
		RowsToCheck.Add(Row);
	EndDo;
	 
	While Spreadsheet.CheckPut(RowsToCheck) Do
		Spreadsheet.Put(Row);
	   	RowsToCheck.Clear();
	  	If PrintSIFooter Then 
			RowsToCheck.Add(Footer);
		EndIf;
		RowsToCheck.Add(Row);
		RowsToCheck.Add(Row);
		RowsToCheck.Add(Row);

	EndDo;


	TemplateArea = Template.GetArea("DividerArea");
	Spreadsheet.Put(TemplateArea);
	
	// Final footer 
	
	If Constants.ShipmentFoot1Type.Get()= Enums.TextOrImage.Image Then	
			DocumentPrinting.FillPictureInDocumentTemplate(Template, Footer1Pic, "footer1");
			TemplateArea = Template.GetArea("FooterField|FooterSection1");	
			Spreadsheet.Put(TemplateArea);
	Elsif Constants.ShipmentFoot1Type.Get() = Enums.TextOrImage.Text Then
			TemplateArea = Template.GetArea("TextField|FooterSection1");
			TemplateArea.Parameters.FooterTextLeft = Constants.ShipmentFooterTextLeft.Get();
			Spreadsheet.Put(TemplateArea);
	EndIf;
		
	If Constants.ShipmentFoot2Type.Get()= Enums.TextOrImage.Image Then
			DocumentPrinting.FillPictureInDocumentTemplate(Template, Footer2Pic, "footer2");
			TemplateArea = Template.GetArea("FooterField|FooterSection2");	
			Spreadsheet.Join(TemplateArea);
			
	Elsif Constants.ShipmentFoot2Type.Get() = Enums.TextOrImage.Text Then
			TemplateArea = Template.GetArea("TextField|FooterSection2");
			TemplateArea.Parameters.FooterTextCenter = Constants.ShipmentFooterTextCenter.Get();
			Spreadsheet.Join(TemplateArea);
	EndIf;
		
	If Constants.ShipmentFoot3Type.Get()= Enums.TextOrImage.Image Then
			DocumentPrinting.FillPictureInDocumentTemplate(Template, Footer3Pic, "footer3");
			TemplateArea = Template.GetArea("FooterField|FooterSection3");	
			Spreadsheet.Join(TemplateArea);
	Elsif Constants.ShipmentFoot3Type.Get() = Enums.TextOrImage.Text Then
			TemplateArea = Template.GetArea("TextField|FooterSection3");
			TemplateArea.Parameters.FooterTextRight = Constants.ShipmentFooterTextRight.Get();
			Spreadsheet.Join(TemplateArea);
	EndIf;	
	
	Spreadsheet.PutHorizontalPageBreak();
	Spreadsheet.FitToPage  = True;
	
	// Remove footer information if only a page.
	If Spreadsheet.PageCount() = 1 Then
		Spreadsheet.Footer.Enabled = False;
	EndIf;

   EndDo;
		
EndFunction

Function PrintAssembly(Spreadsheet, SheetTitle, RefArray, TemplateName = Undefined) Export
	
	Spreadsheet.Clear();
	SetPageSize(Spreadsheet);
	
	SheetTitle = "Assembly";
	CustomTemplate = GeneralFunctions.GetCustomTemplate("Document.Assembly", SheetTitle);
	
	If CustomTemplate = Undefined Then
		Template = Documents.Assembly.GetTemplate("AssemblyPrintForm");
	Else
		Template = CustomTemplate;
	EndIf;
		
	TopHeader    = Template.GetArea("TopHeader");
	MiddleHeader = Template.GetArea("MiddleHeader");
	BottomHeader = Template.GetArea("BottomHeader");
	Line         = Template.GetArea("Line");
	LineGray     = Template.GetArea("LineGray");
	LineForward  = Template.GetArea("LineForward");
	Footer       = Template.GetArea("Footer");
	BottomFooter = Template.GetArea("BottomFooter");
	EmptyLine    = Template.GetArea("EmptyLine");
	
	QuantityFormat    = GeneralFunctionsReusable.DefaultQuantityFormat();
	QuantityPrecision = GeneralFunctionsReusable.DefaultQuantityPrecision();
	
	SettingsPrintedForm = PrintFormFunctions.GetSettingsPrintedForm(Enums.PrintedForms.AssemblyMainForm);
	
	InsertPageBreak = False;
	For Each Ref In RefArray Do
		
		If InsertPageBreak Then
			Spreadsheet.PutHorizontalPageBreak();
		EndIf;
		
		//***Quering necessary data***
		Query = New Query();
		Query.Text = "SELECT
		             |	AssemblyLineItems.Ref,
		             |	AssemblyLineItems.Product,
		             |	AssemblyLineItems.ProductDescription,
		             |	AssemblyLineItems.Lot,
		             |	AssemblyLineItems.UnitSet,
		             |	AssemblyLineItems.QtyItem,
		             |	AssemblyLineItems.QtyUnits,
		             |	AssemblyLineItems.Unit,
		             |	AssemblyLineItems.QtyUM,
		             |	AssemblyLineItems.PriceUnits,
		             |	AssemblyLineItems.LineTotal,
		             |	AssemblyLineItems.WastePercent,
		             |	AssemblyLineItems.WasteQtyUnits,
		             |	AssemblyLineItems.WasteQtyUM,
		             |	AssemblyLineItems.WasteTotal,
		             |	AssemblyLineItems.Location,
		             |	AssemblyLineItems.Project,
		             |	AssemblyLineItems.Class,
		             |	ISNULL(InventoryJournalBalance.QuantityBalance, 0) AS QuantityBalance
		             |FROM
		             |	Document.Assembly.LineItems AS AssemblyLineItems
		             |		LEFT JOIN AccumulationRegister.InventoryJournal.Balance AS InventoryJournalBalance
		             |		ON AssemblyLineItems.Product = InventoryJournalBalance.Product
		             |			AND AssemblyLineItems.Location = InventoryJournalBalance.Location
		             |WHERE
		             |	AssemblyLineItems.Ref = &Ref
		             |
		             |UNION ALL
		             |
		             |SELECT
		             |	AssemblyServices.Ref,
		             |	AssemblyServices.Product,
		             |	AssemblyServices.ProductDescription,
		             |	NULL,
		             |	AssemblyServices.UnitSet,
		             |	AssemblyServices.QtyItem,
		             |	AssemblyServices.QtyUnits,
		             |	AssemblyServices.Unit,
		             |	AssemblyServices.QtyUM,
		             |	AssemblyServices.PriceUnits,
		             |	AssemblyServices.LineTotal,
		             |	NULL,
		             |	NULL,
		             |	NULL,
		             |	NULL,
		             |	NULL,
		             |	AssemblyServices.Project,
		             |	AssemblyServices.Class,
		             |	NULL
		             |FROM
		             |	Document.Assembly.Services AS AssemblyServices
		             |WHERE
		             |	AssemblyServices.Ref = &Ref";
		
		Query.SetParameter("Ref", Ref);
		Selection = Query.Execute().Select();
		//***End Quering necessary data***
		
		//***HEADER***
		
		//---------
		//TopHeader
		//---------
		ParametersOfHeader = New Structure; 
		ParametersOfHeader.Insert("Number", Ref.Number); 
		ParametersOfHeader.Insert("Date", Ref.Date); 
		
		//Status
		// Request assembly status.
		AssemblyStatus = Enums.AssemblyStatuses.EmptyRef(); 
		If (Not ValueIsFilled(Ref)) Or (Ref.DeletionMark) Or (Not Ref.Posted) Then
			// The assembly has pending status.
			AssemblyStatus = Enums.AssemblyStatuses.Pending;
		Else
			// The assembly has been completed.
			AssemblyStatus = Enums.AssemblyStatuses.Completed;
		EndIf;
		
		// Fill extended assembly status.
		If Not ValueIsFilled(Ref) Then
			ParametersOfHeader.Insert("Status", String(Enums.AssemblyStatuses.New));
		ElsIf Ref.DeletionMark Then
			ParametersOfHeader.Insert("Status", String(Enums.AssemblyStatuses.Deleted));
		Else
			ParametersOfHeader.Insert("Status", String(AssemblyStatus));
		EndIf;
		
		TopHeader.Parameters.Fill(ParametersOfHeader);
		
		//Add logo
		BinaryLogo = GeneralFunctions.GetLogo();
		LogoPicture = New Picture(BinaryLogo);
		DocumentPrinting.FillLogoInDocumentTemplate(TopHeader, LogoPicture); 
				
		UsBill   = PrintTemplates.ContactInfoDatasetUs();
		
		TopHeader.Parameters.Fill(UsBill);
		
		//UsBill filling
		If TopHeader.Parameters.UsBillLine1 <> "" Then
			TopHeader.Parameters.UsBillLine1 = TopHeader.Parameters.UsBillLine1 + Chars.LF; 
		EndIf;
		
		If TopHeader.Parameters.UsBillLine2 <> "" Then
			TopHeader.Parameters.UsBillLine2 = TopHeader.Parameters.UsBillLine2 + Chars.LF; 
		EndIf;
		
		If TopHeader.Parameters.UsBillCityStateZIP <> "" Then
			TopHeader.Parameters.UsBillCityStateZIP = TopHeader.Parameters.UsBillCityStateZIP + Chars.LF; 
		EndIf;
		
		If TopHeader.Parameters.UsBillPhone <> "" Then
			TopHeader.Parameters.UsBillPhone = TopHeader.Parameters.UsBillPhone + Chars.LF; 
		EndIf;
		
		If Not SettingsPrintedForm.ShowEmail Then
			TopHeader.Parameters.UsBillEmail = ""; 
		EndIf;
		
		//UsInfo filling
		If TopHeader.Parameters.UsBillCell <> "" And SettingsPrintedForm.ShowMobile Then
			TopHeader.Parameters.UsBillCell      = TopHeader.Parameters.UsBillCell + Chars.LF;
			TopHeader.Parameters.TitleUsBillCell = "Mobile:" + Chars.LF;
		Else
			TopHeader.Parameters.UsBillCell      = "";
		EndIf;
		
		If TopHeader.Parameters.UsWebsite <> "" And SettingsPrintedForm.ShowWebsite Then
			TopHeader.Parameters.UsWebsite      = TopHeader.Parameters.UsWebsite + Chars.LF;
			TopHeader.Parameters.TitleUsWebsite = "Website:" + Chars.LF;
		Else
			TopHeader.Parameters.UsWebsite      = "";
		EndIf;
		
		If TopHeader.Parameters.UsBillFax <> "" And SettingsPrintedForm.ShowFax Then
			TopHeader.Parameters.UsBillFax      = TopHeader.Parameters.UsBillFax + Chars.LF;
			TopHeader.Parameters.TitleUsBillFax = "Fax:" + Chars.LF;
		Else
			TopHeader.Parameters.UsBillFax      = "";
		EndIf;
		
		If TopHeader.Parameters.UsBillFedTaxID <> "" And SettingsPrintedForm.ShowFederalTaxID Then
			TopHeader.Parameters.TitleUsBillFedTaxID = "Federal Tax ID:";
		Else
			TopHeader.Parameters.UsBillFedTaxID      = "";
		EndIf;
		
		//------------
		//MiddleHeader
		//------------
		MiddleHeader.Parameters.Product            = Ref.Product;
		MiddleHeader.Parameters.ProductDescription = Ref.ProductDescription;
		MiddleHeader.Parameters.QtyUnits           = Format(Ref.QtyUnits, QuantityFormat);
		MiddleHeader.Parameters.Unit               = Ref.Unit;
		MiddleHeader.Parameters.Location           = Ref.Location;
		
		//If Ref.Product.HasLotsSerialNumbers Then
		//	If Ref.Product.UseLots = 0 Then
		//		MiddleHeader.Parameters.LotTitle = "Lot:";
		//		MiddleHeader.Parameters.Lot      = Ref.Lot;
		//	ElsIf Ref.Product.UseLots = 1 Then
		//		
		//		SerialNumbersArray = New Array;
		//		For Each CurrentRow In Ref.SerialNumbers Do
		//			SerialNumbersArray.Add(CurrentRow.SerialNumber);
		//		EndDo;
		//		
		//		MiddleHeader.Parameters.LotTitle = "Serial #:";
		//		MiddleHeader.Parameters.Lot      = LotsSerialNumbersClientServer.FormatSerialNumbersStr(SerialNumbersArray);
		//	EndIf;
		//EndIf;
						
		//------------
		//BottomHeader
		//------------
		//BottomHeader.Parameters.Fill();
		
		//***END HEADER***
		
		//***Footer***
		ParametersOfFooter = New Structure;
		ParametersOfFooter.Insert("CurrentDate", Format(CurrentSessionDate(), "DF='dddd, MMM d, yyyy h:mm:ss tt'"));
		
		Footer.Parameters.Fill(ParametersOfFooter);
		//***End Footer***
		
		//***BottomFooter***
		If SettingsPrintedForm.FooterTypeLeft = Enums.TextOrImage.Text Then
			BottomFooter.Parameters.FooterTextLeft   = SettingsPrintedForm.FooterTextLeft;
		ElsIf SettingsPrintedForm.FooterTypeLeft = Enums.TextOrImage.Image Then 
			FooterLeftLogo   = GeneralFunctions.GetFooterPO("AssemblyFooterLeft");
			FooterLeftPic    = New Picture(FooterLeftLogo);
			DocumentPrinting.FillPictureInDocumentTemplate(BottomFooter, FooterLeftPic, "FooterImageLeft"); 
		Else
			//	
		EndIf;
		
		If SettingsPrintedForm.FooterTypeCenter = Enums.TextOrImage.Text Then
			BottomFooter.Parameters.FooterTextCenter   = SettingsPrintedForm.FooterTextCenter;
		ElsIf SettingsPrintedForm.FooterTypeCenter = Enums.TextOrImage.Image Then 
			FooterCenterLogo   = GeneralFunctions.GetFooterPO("AssemblyFooterCenter");
			FooterCenterPic    = New Picture(FooterCenterLogo);
			DocumentPrinting.FillPictureInDocumentTemplate(BottomFooter, FooterCenterPic, "FooterImageCenter"); 
		Else
			//	
		EndIf;
		
		If SettingsPrintedForm.FooterTypeRight = Enums.TextOrImage.Text Then
			BottomFooter.Parameters.FooterTextRight   = SettingsPrintedForm.FooterTextRight;
		ElsIf SettingsPrintedForm.FooterTypeRight = Enums.TextOrImage.Image Then 
			FooterRightLogo   = GeneralFunctions.GetFooterPO("AssemblyFooterRight");
			FooterRightPic    = New Picture(FooterRightLogo);
			DocumentPrinting.FillPictureInDocumentTemplate(BottomFooter, FooterRightPic, "FooterImageRight"); 
		Else
			//	
		EndIf;
		//***End BottomFooter***
		
		////***Line***
		LineIsGray      = False;
		Array           = New Array;
		
		Spreadsheet.Put(TopHeader);
		Spreadsheet.Put(MiddleHeader);
		Spreadsheet.Put(BottomHeader);
		
		While Selection.Next() Do
			
			//
			If Selection.Product.Type = Enums.InventoryTypes.Inventory Then
				QtyOnHand = Round(Round(Selection.QuantityBalance, QuantityPrecision) * ?(Selection.Unit.Factor > 0, Selection.Unit.Factor, 1), QuantityPrecision);
			Else
				QtyOnHand = "";
			EndIf;
			
			ParametersOfLine = New Structure;
			ParametersOfLine.Insert("Product", Selection.Product);
			ParametersOfLine.Insert("Sub", ?(Selection.Product.Assembly, "√", ""));
			ParametersOfLine.Insert("ProductDescription", Selection.ProductDescription);
			ParametersOfLine.Insert("Type", Selection.Product.Type); 
			ParametersOfLine.Insert("QtyItem", Format(Selection.QtyItem, QuantityFormat)); 
			ParametersOfLine.Insert("QtyUnits", Format(Selection.QtyUnits, QuantityFormat)); 		
			ParametersOfLine.Insert("QtyOnHand", Format(QtyOnHand, QuantityFormat)); 
			ParametersOfLine.Insert("Unit", Selection.Unit); 
			ParametersOfLine.Insert("Location", Selection.Location); 
			
			//------------------------------------------------------
			InputLine = Undefined;
			
			If LineIsGray Then 
				LineGray.Parameters.Fill(ParametersOfLine);
				InputLine = LineGray;
			Else
				Line.Parameters.Fill(ParametersOfLine);
				InputLine = Line;
			EndIf;
			
			Array.Clear();
			Array.Add(InputLine);
			Array.Add(BottomFooter);
			
			If Spreadsheet.CheckPut(Array) Then 
				Spreadsheet.Put(InputLine);
			Else
				Spreadsheet.Put(BottomFooter);	
				Spreadsheet.PutHorizontalPageBreak();
				
				Spreadsheet.Put(TopHeader);
				Spreadsheet.Put(BottomHeader);
				Spreadsheet.Put(InputLine);
			EndIf;
			
			LineIsGray = ?(LineIsGray, False, True);
			
		EndDo;
		//***End Line***
		
		//Footer
		Array.Clear();
		Array.Add(Footer);
		Array.Add(BottomFooter);
		
		If Not Spreadsheet.CheckPut(Array) Then 
			Spreadsheet.Put(BottomFooter);
			Spreadsheet.PutHorizontalPageBreak();
			
			Spreadsheet.Put(TopHeader);
			Spreadsheet.Put(Footer);
			
			//
			Array.Clear();
			Array.Add(EmptyLine);
			Array.Add(BottomFooter);
			
			While Spreadsheet.CheckPut(Array) Do
				Spreadsheet.Put(EmptyLine);	
			EndDo;
			Spreadsheet.Put(BottomFooter);
		Else
			Spreadsheet.Put(Footer);
			
			Array.Clear();
			Array.Add(EmptyLine);
			Array.Add(BottomFooter);
			
			While Spreadsheet.CheckPut(Array) Do
				Spreadsheet.Put(EmptyLine);	
			EndDo;
			Spreadsheet.Put(BottomFooter);
			
		EndIf;
		
		InsertPageBreak = True;
	EndDo;
	
	//Add footer with page count	
	Spreadsheet.Header.Enabled       = True;
	Spreadsheet.Header.StartPage     = 1;
	Spreadsheet.Header.VerticalAlign = VerticalAlign.Bottom;	
	Spreadsheet.Header.Font          = New Font(Spreadsheet.Header.Font, , , , True);
	Spreadsheet.Header.RightText     = "Page [&PageNumber] of [&PagesTotal]";
	
EndFunction

Function GetSettingsPrintedForm(PrintedForm) Export
	
	SettingsPrintedForm = InformationRegisters.SettingsPrintedForms.Get(New Structure("PrintedForm", PrintedForm));	
	
	//SettingIsExists
	Query = New Query;
	Query.Text = "SELECT
	             |	SettingsPrintedForms.PrintedForm
	             |FROM
	             |	InformationRegister.SettingsPrintedForms AS SettingsPrintedForms
	             |WHERE
	             |	SettingsPrintedForms.PrintedForm = &PrintedForm";
	
	Query.SetParameter("PrintedForm", PrintedForm);
	
	If Query.Execute().Select().Count() > 0 Then
		SettingsPrintedForm.Insert("SettingIsExists", True);	
	Else
		SettingsPrintedForm.Insert("SettingIsExists", False);	
	EndIf;
	
	Return SettingsPrintedForm;
	
EndFunction

Function CorrectNameStr(Salutation, FirstName, LastName) Export
	
	If Salutation <> "" Then
		Salutation = Salutation + " ";
	EndIf;
	If FirstName <> "" Then
		FirstName = FirstName + " ";
	EndIf;
	Return Salutation + FirstName + LastName;
		
EndFunction

Procedure SetPageSize(Spreadsheet) Export
	
	//
	Spreadsheet.PageSize        = "Letter";
	Spreadsheet.PageOrientation = PageOrientation.Portrait;
	
	Spreadsheet.TopMargin       = 10;
	Spreadsheet.LeftMargin      = 10;
	Spreadsheet.RightMargin     = 10;
	Spreadsheet.BottomMargin    = 10;
	
	Spreadsheet.HeaderSize      = 10;
	Spreadsheet.FooterSize      = 10;
	
	Spreadsheet.FitToPage       = True;
	
EndProcedure

Function GetDescriptionContactPerson(Structure, Type)
	
	ContactPerson = "";
	
	If Type = "Bill" Then 
		ContactPerson = TrimAll(Structure.ThemBillSalutation + " " + Structure.ThemBillFirstName + " " + Structure.ThemBillLastName); 
	ElsIf Type = "Ship" Then
		ContactPerson = TrimAll(Structure.ThemShipSalutation + " " + Structure.ThemShipFirstName + " " + Structure.ThemShipLastName); 
	EndIf;
	
	Return ContactPerson;
	
EndFunction

Function GetDescriptionSalesTax(DocRef, UseAvatax) Export
	
	If Not GeneralFunctionsReusable.FunctionalOptionValue("SalesTaxCharging") Then
		Return "Sales Tax:";
	EndIf;
	
	TaxRate = 0;
	If Not UseAvatax Then
		If DocRef.SalesTaxAcrossAgencies.Count() = 0 Then
			SalesTaxRateAttr = CommonUse.GetAttributeValues(DocRef.SalesTaxRate, "Rate");
			TaxRate = SalesTaxRateAttr.Rate;
		Else
			TaxRate = DocRef.SalesTaxAcrossAgencies.Total("Rate");
		EndIf;
	Else //When using Avatax some lines are taxable and others not
		If DocRef.TaxableSubtotal <> 0 Then
			TaxRate = Round(DocRef.SalesTax/DocRef.TaxableSubtotal, 4) * 100;
		EndIf;
	EndIf;
	
	Return "Sales Tax, " + Format(TaxRate, "NFD=4; NZ=") + "%:";
	
EndFunction

Function GetPrintFormSettings(ObjectTypeID) Export
	
	//PageSetupStructure 	= new Structure("PrintPageOrientation, LeftMargin, RightMargin, TopMargin, BottomMargin, HeaderSize, FooterSize, PrintScale, 
	//|PerPage, BlackAndWhite, PageOrientation", "Letter", PageOrientation.Portrait, 10, 10, 10, 10, 10, 10, 100, False, 1, False, PageOrientation.Portrait);
	PageSetupStructure 	= new Structure("PageSize, PrintPageOrientation, LeftMargin, RightMargin, TopMargin, BottomMargin, HeaderSize, FooterSize, PrintScale, 
	|FitToPage, PerPage, BlackAndWhite", "Letter", 0, 31.75, 31.75, 25.4, 25.4, 0, 0, 100, True, 1, True); //PageOrientation = Portrait
	If AccessRight("SaveUserData", Metadata) Then
		//If GetFromStorage Then
		//	PrintPageSetupVS	= CommonSettingsStorage.Load("PrintFormSettings");
		//Else	
		PrintPageSetupVS	= GetFromUserSetting(ObjectTypeID);
		//EndIf; 
		If PrintPageSetupVS <> Undefined Then
			PPS					= PrintPageSetupVS.Get();
			If TypeOf(PPS) = Type("Structure") Then
				FillPropertyValues(PageSetupStructure, PPS);
			EndIf;
		EndIf;
	EndIf;
	
	If ObjectTypeID = "Document.Check (Check)" Or ObjectTypeID = "Document.InvoicePayment (Check)" Then
		PageSetupStructure.LeftMargin = 17 + Constants.CheckHorizontalAdj.Get();
		PageSetupStructure.TopMargin = 15 + Constants.CheckVerticalAdj.Get()
	EndIf;
	
	return PageSetupStructure;
	
EndFunction

Function GetFromUserSetting(ObjectTypeID) Export

	Query = New Query("SELECT
	                  |	UserSettings.SettingValue
	                  |FROM
	                  |	Catalog.UserSettings AS UserSettings
	                  |WHERE
	                  |	UserSettings.ObjectID = &ObjectID
	                  |	AND UserSettings.Type = VALUE(Enum.UserSettingsTypes.PagePrintSetting)
	                  |	AND UserSettings.AvailableToAllUsers = TRUE");
					  
	Query.SetParameter("ObjectID",ObjectTypeID);
	Result = Query.Execute().Select();
	If Result.Next() Then
		Return Result.SettingValue;
	EndIf; 
	Return Undefined;
EndFunction

Procedure ReportOnComposeResult(ResultDocument, DetailsData, StandardProcessing, ReportName) Export
	
	//Apply system print form settings
	PrintFormSettings = PrintFormFunctions.GetPrintFormSettings(ReportName);
	FillPropertyValues(ResultDocument, PrintFormSettings);
	ResultDocument.PageOrientation = ?(PrintFormSettings.PrintPageOrientation = 0, PageOrientation.Portrait, PageOrientation.Landscape);
	
EndProcedure
