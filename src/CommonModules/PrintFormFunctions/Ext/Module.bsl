// external module to be able to test print forms

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
			
	If Constants.SOShowFullName.Get() = True Then
		TemplateArea.Parameters.ThemFullName = ThemBill.ThemBillSalutation + " " + ThemBill.ThemBillFirstName + " " + ThemBill.ThemBillLastName;
		TempFullName = ThemShip.ThemShipSalutation + " " + ThemShip.ThemShipFirstName + " " + ThemShip.ThemShipLastName;
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
		TemplateArea.Parameters.Price = Selection.Currency.Symbol + Format(SelectionLineItems.PriceUnits, "NFD=2; NZ=");
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
	TemplateArea.Parameters.LineSubtotal = Selection.Currency.Symbol + Format(Selection.LineSubtotal, "NFD=2; NZ=");
	TemplateArea.Parameters.Discount = "("+ Selection.Currency.Symbol + Format(Selection.Discount, "NFD=2; NZ=") + ")";
	TemplateArea.Parameters.Subtotal = Selection.Currency.Symbol + Format(Selection.Subtotal, "NFD=2; NZ=");
	TemplateArea.Parameters.Shipping = Selection.Currency.Symbol + Format(Selection.Shipping, "NFD=2; NZ=");
	TemplateArea.Parameters.SalesTax = Selection.Currency.Symbol + Format(Selection.SalesTax, "NFD=2; NZ=");
	TemplateArea.Parameters.Total = Selection.Currency.Symbol + Format(Selection.DocumentTotal, "NFD=2; NZ=");

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
		
	Spreadsheet.PutHorizontalPageBreak(); //.ВывестиГоризонтальныйРазделительСтраниц();
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
		If Constants.SalesInvoicePO.Get() = False Then
			Template = Documents.SalesInvoice.GetTemplate("New_SalesInvoice_Form");//("PF_MXL_SalesInvoice");
		ElsIf Constants.SalesInvoicePO.Get() = True Then
			Template = Documents.SalesInvoice.GetTemplate("PF_MXL_SalesInvoice_PO");
		EndIf;
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
   |		ProductDescription,
   |		LineItems.Order.RefNum AS PO,
   |		QtyUnits,
   |		Unit,
   |		QtyUM,
   |		PriceUnits,
   |		LineTotal,
   |		Project,
   |        DeliveryDateActual
   |	),
   |	SalesInvoice.Terms,
   |	SalesInvoice.DueDate,
   |	GeneralJournalBalance.AmountRCBalance AS BalanceRC,
   |	GeneralJournalBalance.AmountBalance AS Balance,
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
		TemplateArea.Parameters.ThemFullName = ThemBill.ThemBillSalutation + " " + ThemBill.ThemBillFirstName + " " + ThemBill.ThemBillLastName + Chars.LF;
		TemplateArea.Parameters.ThemShipFullName = ThemShip.ThemShipSalutation + " " + ThemShip.ThemShipFirstName + " " + ThemShip.ThemShipLastName + Chars.LF;
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
	
	ShowSVC = Constants.SIShowSVCCol.Get();
	If ShowSVC = True Then
		TemplateArea = Template.GetArea("LineItemsHeaderService");
		Spreadsheet.Put(TemplateArea);
		TemplateArea = Template.GetArea("LineItems3Service");
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
		TemplateArea.Parameters.Price     = Selection.Currency.Symbol + Format(SelectionLineItems.PriceUnits, "NFD=2; NZ=");
		TemplateArea.Parameters.LineTotal = Selection.Currency.Symbol + Format(SelectionLineItems.LineTotal, "NFD=2; NZ=");
		If ShowSVC = True Then
			TemplateArea.Parameters.DeliveryDateActual = Format(SelectionLineItems.DeliveryDateActual,"DLF=D;");
		EndIf;
		
		Spreadsheet.Put(TemplateArea, SelectionLineItems.Level());
		
		If LineItemSwitch = False Then
			If ShowSVC = True Then
				TemplateArea = Template.GetArea("LineItems4Service");
			Else
				TemplateArea = Template.GetArea("LineItems2");
			EndIf;
			LineItemSwitch = True;
		Else
			If ShowSVC = True Then
				TemplateArea = Template.GetArea("LineItems3Service");
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
	TemplateArea.Parameters.LineSubtotal = Selection.Currency.Symbol + Format(Selection.LineSubtotal, "NFD=2; NZ=");
	TemplateArea.Parameters.Discount = "(" + Selection.Currency.Symbol + Format(Selection.Discount, "NFD=2; NZ=") + ")";
	TemplateArea.Parameters.Subtotal = Selection.Currency.Symbol + Format(Selection.Subtotal, "NFD=2; NZ=");
	TemplateArea.Parameters.Shipping = Selection.Currency.Symbol + Format(Selection.Shipping, "NFD=2; NZ=");
	TemplateArea.Parameters.SalesTax = Selection.Currency.Symbol + Format(Selection.SalesTax, "NFD=2; NZ=");
	TemplateArea.Parameters.Total = Selection.Currency.Symbol + Format(Selection.DocumentTotal, "NFD=2; NZ=");
	NonNullBalance = 0;
	If Selection.Balance <> NULL Then NonNullBalance = Selection.Balance; EndIf;
	TemplateArea.Parameters.Balance = Selection.Currency.Symbol + Format(NonNullBalance, "NFD=2; NZ=");

	TestData.Insert("Currency",Selection.Currency.Symbol); // for unit testing
	TestData.Insert("LineSubtotal",TemplateArea.Parameters.LineSubtotal);
	
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
   
   Return TestData;
		
EndFunction