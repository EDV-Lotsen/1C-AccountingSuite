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
