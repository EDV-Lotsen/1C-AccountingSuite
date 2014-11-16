
////////////////////////////////////////////////////////////////////////////////
// Quote: Manager module
//------------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
#Region COMMANDS_HANDLERS

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
Function IsOpen(DocumentRef) Export
		
		IsOpen = True;
		
		//1.
		If DocumentRef.IsEmpty() Then
			
			IsOpen = True;
			
		//2.
		ElsIf DocumentRef.Cancelled Or DocumentRef.DeletionMark Then 
			
			IsOpen = False;
			
		//3.			
		Else
			
			Query = New Query;
			Query.Text = 
			"SELECT
			|	DocumentJournalOfCompanies.Document
			|FROM
			|	InformationRegister.DocumentJournalOfCompanies AS DocumentJournalOfCompanies
			|WHERE
			|	DocumentJournalOfCompanies.Document.BaseDocument = &BaseDocument";
			
			Query.SetParameter("BaseDocument", DocumentRef);
			
			QueryResult = Query.Execute();
			
			SelectionDetailRecords = QueryResult.Select();
			
			While SelectionDetailRecords.Next() Do
				IsOpen = False;
			EndDo;
			
		EndIf;
		
		//Message
		If Not IsOpen Then
			MessageText = NStr("en = 'Document %1 is converted or cancelled.'");
			MessageText = StringFunctionsClientServer.SubstituteParametersInString(MessageText,
			                                                                       DocumentRef); 
			CommonUseClientServer.MessageToUser(MessageText, DocumentRef,,, True);
		EndIf;
		
		Return IsOpen;	
		
	EndFunction
	
//------------------------------------------------------------------------------
// Document print
	
Procedure Print(Spreadsheet, SheetTitle, Ref, TemplateName = Undefined) Export
	
	SheetTitle = "Quote";
	CustomTemplate = GeneralFunctions.GetCustomTemplate("Document.Quote", SheetTitle);
	
	If CustomTemplate = Undefined Then
		Template = Documents.Quote.GetTemplate("QuotePrintForm");
	Else
		Template = CustomTemplate;
	EndIf;
	
	// Quering necessary data.
	Query = New Query();
	Query.Text = "SELECT
	             |	Quote.Ref,
	             |	Quote.DataVersion,
	             |	Quote.DeletionMark,
	             |	Quote.Number,
	             |	Quote.Date,
	             |	Quote.Posted,
	             |	Quote.ExpirationDate,
	             |	Quote.Cancelled,
	             |	Quote.Company,
	             |	Quote.RefNum,
	             |	Quote.DeliveryDate,
	             |	Quote.ShipTo,
	             |	Quote.BillTo,
	             |	Quote.ConfirmTo,
	             |	Quote.SalesPerson,
	             |	Quote.Location,
	             |	Quote.Project,
	             |	Quote.Class,
	             |	Quote.DropshipCompany,
	             |	Quote.DropshipShipTo,
	             |	Quote.DropshipConfirmTo,
	             |	Quote.DropshipRefNum,
	             |	Quote.Memo,
	             |	Quote.Currency,
	             |	Quote.ExchangeRate,
	             |	Quote.SalesTaxRate,
	             |	Quote.DiscountIsTaxable,
	             |	Quote.DiscountPercent,
	             |	Quote.TaxableSubtotal,
	             |	Quote.DocumentTotalRC,
	             |	Quote.LineSubtotal,
	             |	Quote.Discount,
	             |	Quote.SalesTax,
	             |	Quote.Shipping,
	             |	Quote.DocumentTotal,
	             |	Quote.SubTotal,
	             |	Quote.SalesTaxRC,
	             |	Quote.EmailTo,
	             |	Quote.LastEmail,
	             |	Quote.Terms,
	             |	Quote.LineItems.(
	             |		Ref,
	             |		LineNumber,
	             |		Product,
	             |		ProductDescription,
	             |		QtyUnits,
	             |		Unit,
	             |		PriceUnits,
	             |		LineTotal,
	             |		Taxable,
	             |		TaxableAmount,
	             |		Location,
	             |		DeliveryDate,
	             |		Project,
	             |		Class
	             |	),
	             |	Quote.SalesTaxAcrossAgencies.(
	             |		Ref,
	             |		LineNumber,
	             |		Agency,
	             |		Rate,
	             |		Amount,
	             |		SalesTaxRate,
	             |		SalesTaxComponent
	             |	),
	             |	Quote.EmailNote
	             |FROM
	             |	Document.Quote AS Quote
	             |WHERE
	             |	Quote.Ref IN(&Ref)";
	
	Query.SetParameter("Ref", Ref);
	Selection = Query.Execute().Select();
	
	Spreadsheet.Clear();
	
	While Selection.Next() Do
		
		BinaryLogo = GeneralFunctions.GetLogo();
		LogoPicture = New Picture(BinaryLogo);
		DocumentPrinting.FillLogoInDocumentTemplate(Template, LogoPicture); 
		
		Try
			FooterLogo = GeneralFunctions.GetFooterPO("QuoteFooter1");
			Footer1Pic = New Picture(FooterLogo);
			FooterLogo2 = GeneralFunctions.GetFooterPO("QuoteFooter2");
			Footer2Pic = New Picture(FooterLogo2);
			FooterLogo3 = GeneralFunctions.GetFooterPO("QuoteFooter3");
			Footer3Pic = New Picture(FooterLogo3);
		Except
		EndTry;
		
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
		
		If Constants.QuoteShowFullName.Get() = True Then
			TemplateArea.Parameters.ThemFullName = ThemBill.ThemBillSalutation + " " + ThemBill.ThemBillFirstName + " " + ThemBill.ThemBillLastName;
			TempFullName = ThemShip.ThemShipSalutation + " " + ThemShip.ThemShipFirstName + " " + ThemShip.ThemShipLastName;
			If TempFullName = TemplateArea.Parameters.ThemFullName Then
				TemplateArea.Parameters.ThemShipFullName = "";
			Else
				TemplateArea.Parameters.ThemShipFullName = TempFullName + Chars.LF;
			EndIf;
		EndIf;
			
		If Constants.QuoteShowCountry.Get() = False Then
			TemplateArea.Parameters.ThemBillCountry = "";
			TemplateArea.Parameters.ThemShipCountry = "";
		EndIf;	
		
		TemplateArea.Parameters.Date = Selection.Date;
		TemplateArea.Parameters.Number = Selection.Number;
		TemplateArea.Parameters.RefNum = Selection.RefNum;
		TemplateArea.Parameters.SalesPerson = Selection.SalesPerson;
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

		
		Spreadsheet.Put(TemplateArea);
		
		If Constants.QuoteShowEmail.Get() = False Then
			Direction = SpreadsheetDocumentShiftType.Vertical;
			Area = Spreadsheet.Area("EmailArea");
			Spreadsheet.DeleteArea(Area, Direction);
			Spreadsheet.InsertArea(Spreadsheet.Area("R10"), Spreadsheet.Area("R10"), 
			SpreadsheetDocumentShiftType.Vertical);
			
		EndIf;
		
		If Constants.QuoteShowPhone2.Get() = False Then
			Direction = SpreadsheetDocumentShiftType.Vertical;
			Area = Spreadsheet.Area("MobileArea");
			Spreadsheet.DeleteArea(Area, Direction);
			Spreadsheet.InsertArea(Spreadsheet.Area("R10"), Spreadsheet.Area("R10"), 
			SpreadsheetDocumentShiftType.Vertical);
		EndIf;
		
		If Constants.QuoteShowWebsite.Get() = False Then
			Direction = SpreadsheetDocumentShiftType.Vertical;
			Area = Spreadsheet.Area("WebsiteArea");
			Spreadsheet.DeleteArea(Area, Direction);
			Spreadsheet.InsertArea(Spreadsheet.Area("R10"), Spreadsheet.Area("R10"), 
			SpreadsheetDocumentShiftType.Vertical);
			
		EndIf;
		
		If Constants.QuoteShowFax.Get() = False Then
			Direction = SpreadsheetDocumentShiftType.Vertical;
			Area = Spreadsheet.Area("FaxArea");
			Spreadsheet.DeleteArea(Area, Direction);
			Spreadsheet.InsertArea(Spreadsheet.Area("R10"), Spreadsheet.Area("R10"), 
			SpreadsheetDocumentShiftType.Vertical);
			
		EndIf;
		
		If Constants.QuoteShowFedTax.Get() = False Then
			Direction = SpreadsheetDocumentShiftType.Vertical;
			Area = Spreadsheet.Area("FedTaxArea");
			Spreadsheet.DeleteArea(Area, Direction);
			Spreadsheet.InsertArea(Spreadsheet.Area("R10"), Spreadsheet.Area("R10"), 
			SpreadsheetDocumentShiftType.Vertical);
			
		EndIf;
		
		CurrencySymbol = Selection.Currency.Symbol; 
		QuantityFormat = GeneralFunctionsReusable.DefaultQuantityFormat();
		
		SelectionLineItems = Selection.LineItems.Select();
		TemplateArea = Template.GetArea("LineItems");
		LineTotalSum = 0;
		LineItemSwitch = False;
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
			TemplateArea.Parameters.Unit = SelectionLineItems.Unit.Code;
			//TemplateArea.Parameters.Quantity = Format(SelectionLineItems.QtyUnits, QuantityFormat)+ " " + SelectionLineItems.Unit;
			ProductPrecisionFormat = GeneralFunctionsReusable.PriceFormatForOneItem(SelectionLineItems.Product);
			TemplateArea.Parameters.Price     = Selection.Currency.Symbol + Format(SelectionLineItems.PriceUnits, ProductPrecisionFormat + "; NZ=");
			TemplateArea.Parameters.LineTotal = Format(SelectionLineItems.LineTotal, "NFD=2; NZ=");
			Spreadsheet.Put(TemplateArea, SelectionLineItems.Level());
			
			If LineItemSwitch = False Then
				TemplateArea = Template.GetArea("LineItems2");
				LineItemSwitch = True;
			Else
				TemplateArea = Template.GetArea("LineItems");
				LineItemSwitch = False;
			EndIf;
			
		EndDo;
		
		TemplateArea = Template.GetArea("EmptySpace");
		Spreadsheet.Put(TemplateArea);
		
		TemplateArea = Template.GetArea("Area3|Area1");					
		TemplateArea.Parameters.TermAndCond = Selection.EmailNote;
		Spreadsheet.Put(TemplateArea);
		
		TemplateArea = Template.GetArea("Area3|Area2");
		TemplateArea.Parameters.LineSubtotal = Format(Selection.LineSubtotal, "NFD=2; NZ=");
		TemplateArea.Parameters.Discount = "(" + Format(Selection.Discount, "NFD=2; NZ=") + ")";
		TemplateArea.Parameters.Subtotal = Format(Selection.Subtotal, "NFD=2; NZ=");
		TemplateArea.Parameters.Shipping = Format(Selection.Shipping, "NFD=2; NZ=");
		TemplateArea.Parameters.SalesTax = Format(Selection.SalesTax, "NFD=2; NZ=");
		TemplateArea.Parameters.Total = Format(Selection.DocumentTotal, "NFD=2; NZ=");
		
		Spreadsheet.Join(TemplateArea);
		
		Row = Template.GetArea("EmptyRow");
		Footer = Template.GetArea("FooterField");
		Compensator = Template.GetArea("Compensator");
		RowsToCheck = New Array();
		RowsToCheck.Add(Row);
		RowsToCheck.Add(Footer);
		
		While Spreadsheet.CheckPut(RowsToCheck) Do
			Spreadsheet.Put(Row);
			RowsToCheck.Clear();
			RowsToCheck.Add(Footer);
			RowsToCheck.Add(Row);
		EndDo;
		
		If Constants.QuoteFoot1Type.Get()= Enums.TextOrImage.Image Then	
			DocumentPrinting.FillPictureInDocumentTemplate(Template, Footer1Pic, "QuoteFooter1");
			TemplateArea = Template.GetArea("FooterField|FooterSection1");	
			Spreadsheet.Put(TemplateArea);
		Elsif Constants.QuoteFoot1Type.Get() = Enums.TextOrImage.Text Then
			TemplateArea = Template.GetArea("TextField|FooterSection1");
			TemplateArea.Parameters.FooterTextLeft = Constants.QuoteFooterTextLeft.Get();
			Spreadsheet.Put(TemplateArea);
		EndIf;
		
		If Constants.QuoteFoot2Type.Get()= Enums.TextOrImage.Image Then
			DocumentPrinting.FillPictureInDocumentTemplate(Template, Footer2Pic, "QuoteFooter2");
			TemplateArea = Template.GetArea("FooterField|FooterSection2");	
			Spreadsheet.Join(TemplateArea);		
		Elsif Constants.QuoteFoot2Type.Get() = Enums.TextOrImage.Text Then
			TemplateArea = Template.GetArea("TextField|FooterSection2");
			TemplateArea.Parameters.FooterTextCenter = Constants.QuoteFooterTextCenter.Get();
			Spreadsheet.Join(TemplateArea);
		EndIf;
		
		If Constants.QuoteFoot3Type.Get()= Enums.TextOrImage.Image Then
			DocumentPrinting.FillPictureInDocumentTemplate(Template, Footer3Pic, "QuoteFooter3");
			TemplateArea = Template.GetArea("FooterField|FooterSection3");	
			Spreadsheet.Join(TemplateArea);
		Elsif Constants.QuoteFoot3Type.Get() = Enums.TextOrImage.Text Then
			TemplateArea = Template.GetArea("TextField|FooterSection3");
			TemplateArea.Parameters.FooterTextRight = Constants.QuoteFooterTextRight.Get();
			Spreadsheet.Join(TemplateArea);
		EndIf;
		
		Spreadsheet.PutHorizontalPageBreak(); 
		Spreadsheet.FitToPage  = True;
		
	EndDo;
	
EndProcedure
	
#EndIf

#EndRegion
