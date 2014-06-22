Procedure Print(Spreadsheet, SheetTitle, Ref, TemplateName = Undefined) Export
    SheetTitle = "Cash Receipt";
    CustomTemplate = GeneralFunctions.GetCustomTemplate("Document.CashReceipt", SheetTitle);
    
    If CustomTemplate = Undefined Then
    	Template = Documents.CashReceipt.GetTemplate("New_CashReceipt_Form");
    Else
    	Template = CustomTemplate;
    EndIf;
 
   // Quering necessary data.
   Query = New Query();
   Query.Text =
   "SELECT
   |	CashReceipt.Ref,
   |	CashReceipt.DataVersion,
   |	CashReceipt.DeletionMark,
   |	CashReceipt.Number,
   |	CashReceipt.Date,
   |	CashReceipt.Posted,
   |	CashReceipt.Company,
   |	CashReceipt.DocumentTotal,
   |	CashReceipt.CashPayment,
   |	CashReceipt.UnappliedPayment,
   |	CashReceipt.UnappliedPaymentCreditMemo,
   |	CashReceipt.RefNum,
   |	CashReceipt.Memo,
   |	CashReceipt.DepositType,
   |	CashReceipt.Deposited,
   |	CashReceipt.DocumentTotalRC,
   |	CashReceipt.PaymentMethod,
   |	CashReceipt.BankAccount,
   |	CashReceipt.Currency,
   |	CashReceipt.StripeID,
   |	CashReceipt.ARAccount,
   |	CashReceipt.StripeCardName,
   |	CashReceipt.StripeAmount,
   |	CashReceipt.StripeCreated,
   |	CashReceipt.StripeCardType,
   |	CashReceipt.StripeLast4,
   |	CashReceipt.AppliedCredit,
   |	CashReceipt.CreditTotal,
   |	CashReceipt.BalanceTotal,
   |	CashReceipt.BalChange,
   |	CashReceipt.EmailTo,
   |	CashReceipt.EmailNote,
   |	CashReceipt.EmailCC,
   |	CashReceipt.LastEmail,
   |	CashReceipt.NewObject,
   |	CashReceipt.SalesOrder,
   |	CashReceipt.CreditMemos.(
   |		Ref,
   |		LineNumber,
   |		Document,
   |		Payment,
   |		Balance,
   |		BalanceFCY,
   |		Currency
   |	),
   |	CashReceipt.LineItems.(
   |		Ref,
   |		LineNumber,
   |		Document,
   |		Payment,
   |		Balance,
   |		BalanceFCY,
   |		Currency
   |	),
   |	GeneralJournalBalance.AmountRCBalance AS Balance
   |FROM
   |	Document.CashReceipt AS CashReceipt
   |		LEFT JOIN AccountingRegister.GeneralJournal.Balance AS GeneralJournalBalance
   |		ON (GeneralJournalBalance.ExtDimension1 = CashReceipt.Company)
   |			AND (GeneralJournalBalance.ExtDimension2 = CashReceipt.Ref)
   |WHERE
   |	CashReceipt.Ref IN(&Ref)";
   Query.SetParameter("Ref", Ref);
   Selection = Query.Execute().Select();
   
   Spreadsheet.Clear();

   While Selection.Next() Do
  	 
    BinaryLogo = GeneralFunctions.GetLogo();
    LogoPicture = New Picture(BinaryLogo);
    DocumentPrinting.FillLogoInDocumentTemplate(Template, LogoPicture); 
    
    Try
    	FooterLogo = GeneralFunctions.GetFooterPO("CRfooter1");
    	Footer1Pic = New Picture(FooterLogo);
    	FooterLogo2 = GeneralFunctions.GetFooterPO("CRfooter2");
    	Footer2Pic = New Picture(FooterLogo2);
    	FooterLogo3 = GeneralFunctions.GetFooterPO("CRfooter3");
    	Footer3Pic = New Picture(FooterLogo3);
    Except
    EndTry;
   
   QueryAddr = New Query();
   QueryAddr.Text =
   "SELECT
   |	Addresses.Ref,
   |	Addresses.DataVersion,
   |	Addresses.DeletionMark,
   |	Addresses.Owner,
   |	Addresses.Code,
   |	Addresses.Description,
   |	Addresses.FirstName,
   |	Addresses.MiddleName,
   |	Addresses.LastName,
   |	Addresses.Phone,
   |	Addresses.Cell,
   |	Addresses.Fax,
   |	Addresses.Email,
   |	Addresses.AddressLine1,
   |	Addresses.AddressLine2,
   |	Addresses.AddressLine3,
   |	Addresses.City,
   |	Addresses.State,
   |	Addresses.Country,
   |	Addresses.ZIP,
   |	Addresses.DefaultBilling,
   |	Addresses.DefaultShipping,
   |	Addresses.RemitTo,
   |	Addresses.Notes,
   |	Addresses.Salutation,
   |	Addresses.Suffix,
   |	Addresses.CF1String,
   |	Addresses.CF2String,
   |	Addresses.CF3String,
   |	Addresses.CF4String,
   |	Addresses.CF5String,
   |	Addresses.JobTitle,
   |	Addresses.SalesPerson,
   |	Addresses.Predefined,
   |	Addresses.PredefinedDataName
   |FROM
   |	Catalog.Addresses AS Addresses
   |WHERE
   |	Addresses.Owner = &Owner
   |	AND Addresses.DefaultBilling = &DefaultBilling";
   QueryAddr.SetParameter("Owner", Selection.Company);
   QueryAddr.SetParameter("DefaultBilling", True);
   SelectionAddr = QueryAddr.Execute().Unload();

   
   
    TemplateArea = Template.GetArea("Header");
  			
    UsBill = PrintTemplates.ContactInfoDatasetUs();
    
    ThemBill = PrintTemplates.ContactInfoDataset(Selection.Company, "ThemBill", SelectionAddr[0].Ref);
    
    TemplateArea.Parameters.Fill(UsBill);
    //TemplateArea.Parameters.Fill(ThemShip);
    TemplateArea.Parameters.Fill(ThemBill);
    		
		
	If Constants.CRShowFullName.Get() = True Then
	//If SessionParameters.TenantValue = "1100674" Or Constants.SIShowFullName.Get() = True Then
		TemplateArea.Parameters.ThemFullName = ThemBill.ThemBillSalutation + " " + ThemBill.ThemBillFirstName + " " + ThemBill.ThemBillLastName;
	EndIf;
	
	SelectionCreditMemos = Selection.CreditMemos.Select();
	TotalCredit = 0;
	While SelectionCreditMemos.Next() Do
			TotalCredit = SelectionCreditMemos.Payment + TotalCredit;
	EndDo;
    
    TemplateArea.Parameters.Date = Selection.Date;
    TemplateArea.Parameters.Number = Selection.Number;
	//TemplateArea.Parameters.SalesOrder = String(Selection.SalesOrder);
	//TemplateArea.Parameters.CreditsApplied = "$" + Format(TotalCredit, "NFD=2; NZ=");
	//TemplateArea.Parameters.CreditsUnapplied = "$" + Format(Selection.UnappliedPayment, "NFD=2; NZ=");
	TemplateArea.Parameters.TotalPaidAmount = "$" + Format(Selection.CashPayment, "NFD=2; NZ=");
    If Selection.StripeID <> "" Then
    	TemplateArea.Parameters.RefNum = Selection.StripeID;
    Else
    	TemplateArea.Parameters.RefNum = Selection.RefNum;
	EndIf;
	If Selection.StripeLast4 <> "" Then
		If Selection.StripeCardType = "Visa" Then
			creditPicture = new Picture(Picturelib.visa_logo.GetBinaryData());
			DocumentPrinting.FillPictureInDocumentTemplate(TemplateArea, creditPicture, "CCpic");
			TemplateArea.Parameters.PayMethod = "**** **** **** " + Selection.StripeLast4;
		ElsIf Selection.StripeCardType = "MasterCard" Then
			creditPicture = new Picture(Picturelib.mastercard_logo.GetBinaryData());
			DocumentPrinting.FillPictureInDocumentTemplate(TemplateArea, creditPicture, "CCpic");
			TemplateArea.Parameters.PayMethod = "**** **** **** " + Selection.StripeLast4;
		ElsIf Selection.StripeCardType = "American Express" Then
			creditPicture = new Picture(Picturelib.amex_logo.GetBinaryData());
			DocumentPrinting.FillPictureInDocumentTemplate(TemplateArea, creditPicture, "CCpic");
			TemplateArea.Parameters.PayMethod = "**** ****** * " + Selection.StripeLast4;
		ElsIf Selection.StripeCardType = "Discover" Then
			creditPicture = new Picture(Picturelib.discover_logo.GetBinaryData());
			DocumentPrinting.FillPictureInDocumentTemplate(TemplateArea, creditPicture, "CCpic");
			TemplateArea.Parameters.PayMethod = "**** **** **** " + Selection.StripeLast4;
		ElsIf Selection.StripeCardType = "JCB" Then
			creditPicture = new Picture(Picturelib.jcb_logo.GetBinaryData());
			DocumentPrinting.FillPictureInDocumentTemplate(TemplateArea, creditPicture, "CCpic");
			TemplateArea.Parameters.PayMethod = "**** **** **** " + Selection.StripeLast4;
		ElsIf Selection.StripeCardType = "Diners Club" Then
			creditPicture = new Picture(Picturelib.dinersclub_logo.GetBinaryData());
			DocumentPrinting.FillPictureInDocumentTemplate(TemplateArea, creditPicture, "CCpic");
			TemplateArea.Parameters.PayMethod = "**** **** **" + Selection.StripeLast4;
		Else
		EndIf;		
	Else
		TemplateArea.Parameters.PayMethod = Selection.PaymentMethod;
	EndIf;
	
	//creditPicture = new Picture(Picturelib.visa_logo.GetBinaryData());
	//		DocumentPrinting.FillPictureInDocumentTemplate(TemplateArea, creditPicture, "CCpic");
	//		TemplateArea.Parameters.PayMethod = "**** **** **** " + Selection.StripeLast4;
	
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
    
    If TemplateArea.Parameters.UsBillEmail <> "" AND Constants.CRShowEmail.Get() = False Then
    	TemplateArea.Parameters.UsBillEmail = ""; 
    EndIf;


    	
    
   // ThemBill filling
	If TemplateArea.Parameters.ThemBillLine1 <> "" Then
		TemplateArea.Parameters.ThemBillLine1 = TemplateArea.Parameters.ThemBillLine1 + Chars.LF; 
	EndIf;

	If TemplateArea.Parameters.ThemBillLine2 <> "" Then
		TemplateArea.Parameters.ThemBillLine2 = TemplateArea.Parameters.ThemBillLine2 + Chars.LF; 
	EndIf;
	
	If TemplateArea.Parameters.ThemBillLine3 <> "" Then
		TemplateArea.Parameters.ThemBillLine3 = TemplateArea.Parameters.ThemBillLine3 + Chars.LF; 
	EndIf;
	
         
     Spreadsheet.Put(TemplateArea);	
	 
	 	 
    If Constants.CRShowPhone2.Get() = False Then
    	Direction = SpreadsheetDocumentShiftType.Vertical;
    	Area = Spreadsheet.Area("MobileArea");
    	Spreadsheet.DeleteArea(Area, Direction);
    	Spreadsheet.InsertArea(Spreadsheet.Area("R10"), Spreadsheet.Area("R10"), 
  	  SpreadsheetDocumentShiftType.Vertical);
    EndIf;
    
    If Constants.CRShowWebsite.Get() = False Then
    	Direction = SpreadsheetDocumentShiftType.Vertical;
    	Area = Spreadsheet.Area("WebsiteArea");
    	Spreadsheet.DeleteArea(Area, Direction);
    	Spreadsheet.InsertArea(Spreadsheet.Area("R10"), Spreadsheet.Area("R10"), 
    	SpreadsheetDocumentShiftType.Vertical);

    EndIf;
    
    If Constants.CRShowFax.Get() = False Then
    	Direction = SpreadsheetDocumentShiftType.Vertical;
    	Area = Spreadsheet.Area("FaxArea");
    	Spreadsheet.DeleteArea(Area, Direction);
    	Spreadsheet.InsertArea(Spreadsheet.Area("R10"), Spreadsheet.Area("R10"), 
    	SpreadsheetDocumentShiftType.Vertical);

    EndIf;
    
    If Constants.CRShowFedTax.Get() = False Then
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
	While SelectionLineItems.Next() Do
				 
		TemplateArea.Parameters.Fill(SelectionLineItems);
		TemplateArea.Parameters.DocumentTotal = "$" + Format(SelectionLineItems.Document.DocumentTotal, "NFD=2; NZ=");
		TemplateArea.Parameters.PreviousBalance = "$" + Format(SelectionLineItems.Balance, "NFD=2; NZ=");
		
		LineTotalSum = LineTotalSum + SelectionLineItems.Payment;
		
		TemplateArea.Parameters.AmountPaid = "$" + Format(SelectionLineItems.Payment, "NFD=2; NZ=");
		TemplateArea.Parameters.NewBalance = "$" + Format(SelectionLineItems.Balance - SelectionLineItems.Payment, "NFD=2; NZ=");
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
    TemplateArea.Parameters.TermAndCond = Constants.CashReceiptFooter.Get();
    Spreadsheet.Put(TemplateArea);
     
    TemplateArea = Template.GetArea("Area3|Area2");
    TemplateArea.Parameters.Total = "$" + Format(LineTotalSum, "NFD=2; NZ=");
	
	If LineTotalSum - Selection.CashPayment > 0 Then
		TemplateArea.Parameters.CreditsApplied = "$" + Format(LineTotalSum - Selection.CashPayment, "NFD=2; NZ=");
	Else
		TemplateArea.Parameters.CreditsApplied = "$" + Format(0, "NFD=2; NZ=");
	EndIf;
	
		
	TemplateArea.Parameters.CreditsUnapplied = "$" + Format(Selection.UnappliedPayment, "NFD=2; NZ=");
    
    Spreadsheet.Join(TemplateArea);
    
    TemplateArea = Template.GetArea("EmptyRow");
    Spreadsheet.Put(TemplateArea);
    
    	
    Row = Template.GetArea("EmptyRow");
    Footer = Template.GetArea("FooterField");
    Compensator = Template.GetArea("Compensator");
    RowsToCheck = New Array();
    RowsToCheck.Add(Row);
    RowsToCheck.Add(Footer);
    
    
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
	 EndDo;
	 
	 TemplateArea = Template.GetArea("DividerArea");
	Spreadsheet.Put(TemplateArea);
    
	If Constants.CRFoot1Type.Get()= Enums.TextOrImage.Image Then	
			DocumentPrinting.FillPictureInDocumentTemplate(Template, Footer1Pic, "CRfooter1");
			TemplateArea = Template.GetArea("FooterField|FooterSection1");	
			Spreadsheet.Put(TemplateArea);
	Elsif Constants.CRFoot1Type.Get() = Enums.TextOrImage.Text Then
			TemplateArea = Template.GetArea("TextField|FooterSection1");
			TemplateArea.Parameters.CRFooterTextLeft = Constants.CRFooterTextLeft.Get();
			Spreadsheet.Put(TemplateArea);
	EndIf;
		
	If Constants.CRFoot2Type.Get()= Enums.TextOrImage.Image Then
			DocumentPrinting.FillPictureInDocumentTemplate(Template, Footer2Pic, "CRfooter2");
			TemplateArea = Template.GetArea("FooterField|FooterSection2");	
			Spreadsheet.Join(TemplateArea);		
	Elsif Constants.CRFoot2Type.Get() = Enums.TextOrImage.Text Then
			TemplateArea = Template.GetArea("TextField|FooterSection2");
			TemplateArea.Parameters.CRFooterTextCenter = Constants.CRFooterTextCenter.Get();
			Spreadsheet.Join(TemplateArea);
	EndIf;
		
	If Constants.CRFoot3Type.Get()= Enums.TextOrImage.Image Then
			DocumentPrinting.FillPictureInDocumentTemplate(Template, Footer3Pic, "CRfooter3");
			TemplateArea = Template.GetArea("FooterField|FooterSection3");	
			Spreadsheet.Join(TemplateArea);
	Elsif Constants.CRFoot3Type.Get() = Enums.TextOrImage.Text Then
			TemplateArea = Template.GetArea("TextField|FooterSection3");
			TemplateArea.Parameters.CRFooterTextRight = Constants.CRFooterTextRight.Get();
			Spreadsheet.Join(TemplateArea);
	EndIf;         
    
    	 
    Spreadsheet.PutHorizontalPageBreak(); //.ВывестиГоризонтальныйРазделительСтраниц();
    Spreadsheet.FitToPage  = True;

     
   EndDo;
   
   //Return SpreadsheetDocument;

EndProcedure
