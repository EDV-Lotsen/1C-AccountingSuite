
Procedure Print(Spreadsheet, RefArray) Export
	
	Spreadsheet.Clear();
	SetPageSize(Spreadsheet);

	Template = Documents.Statement.GetTemplate("Print");
		
	TopHeader    = Template.GetArea("TopHeader");
	MiddleHeader = Template.GetArea("MiddleHeader");
	BottomHeader = Template.GetArea("BottomHeader");
	Line         = Template.GetArea("Line");
	LineGray     = Template.GetArea("LineGray");
	LineForward  = Template.GetArea("LineForward");
	Footer       = Template.GetArea("Footer");
	BottomFooter = Template.GetArea("BottomFooter");
	EmptyLine    = Template.GetArea("EmptyLine");
	
	SettingsPrintedForm = PrintFormFunctions.GetSettingsPrintedForm(Enums.PrintedForms.StatementMainForm);
	
	InsertPageBreak = False;
	For Each Ref In RefArray Do
		
		If InsertPageBreak Then
			Spreadsheet.PutHorizontalPageBreak();
		EndIf;
		
		//***ActivityOfCompany***
		Query = New Query;
		Query.Text = "SELECT
		             |	1 AS MyOrder,
		             |	NULL AS RecorderPointInTime,
		             |	""Balance Forward"" AS Recorder,
		             |	&ForwardPeriod AS DocDate,
		             |	GeneralJournalBalance.ExtDimension1 AS Company,
		             |	NULL AS AmountOpeningBalance,
		             |	NULL AS AmountTurnover,
		             |	GeneralJournalBalance.AmountBalance AS AmountClosingBalance
		             |INTO TV
		             |FROM
		             |	AccountingRegister.GeneralJournal.Balance(
		             |			&ForwardPeriod,
		             |			,
		             |			,
		             |			ExtDimension1 = &Company
		             |				AND Currency = &Currency) AS GeneralJournalBalance
		             |
		             |UNION ALL
		             |
		             |SELECT
		             |	1,
		             |	NULL,
		             |	""Balance Forward"",
		             |	&ForwardPeriod,
		             |	&Company,
		             |	NULL,
		             |	NULL,
		             |	0
		             |
		             |UNION ALL
		             |
		             |SELECT
		             |	2,
		             |	GeneralJournalBalanceAndTurnovers.Recorder.PointInTime,
		             |	GeneralJournalBalanceAndTurnovers.Recorder,
		             |	GeneralJournalBalanceAndTurnovers.Recorder.Date,
		             |	GeneralJournalBalanceAndTurnovers.ExtDimension1,
		             |	GeneralJournalBalanceAndTurnovers.AmountOpeningBalance,
		             |	GeneralJournalBalanceAndTurnovers.AmountTurnover,
		             |	GeneralJournalBalanceAndTurnovers.AmountClosingBalance
		             |FROM
		             |	AccountingRegister.GeneralJournal.BalanceAndTurnovers(
		             |			&BeginOfPeriod,
		             |			&EndOfPeriod,
		             |			Auto,
		             |			,
		             |			,
		             |			,
		             |			ExtDimension1 = &Company
		             |				AND Currency = &Currency) AS GeneralJournalBalanceAndTurnovers
		             |WHERE
		             |	GeneralJournalBalanceAndTurnovers.Recorder IS NOT NULL 
		             |	AND GeneralJournalBalanceAndTurnovers.Recorder <> UNDEFINED
		             |
		             |UNION ALL
		             |
		             |SELECT
		             |	2,
		             |	DocumentJournalOfCompanies.Document.PointInTime,
		             |	DocumentJournalOfCompanies.Document,
		             |	DocumentJournalOfCompanies.Date,
		             |	DocumentJournalOfCompanies.Company,
		             |	NULL,
		             |	CASE
		             |		WHEN DocumentJournalOfCompanies.Document REFS Document.CashSale
		             |				OR DocumentJournalOfCompanies.Document REFS Document.Deposit
		             |				OR DocumentJournalOfCompanies.Document REFS Document.Check
		             |			THEN DocumentJournalOfCompanies.TotalFCY
		             |		ELSE NULL
		             |	END,
		             |	NULL
		             |FROM
		             |	InformationRegister.DocumentJournalOfCompanies AS DocumentJournalOfCompanies
		             |WHERE
		             |	DocumentJournalOfCompanies.Company = &Company
		             |	AND DocumentJournalOfCompanies.Currency = &Currency
		             |	AND DocumentJournalOfCompanies.DocumentStatus = 1
		             |	AND DocumentJournalOfCompanies.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
		             |	AND NOT DocumentJournalOfCompanies.Document REFS Document.Quote
		             |	AND NOT DocumentJournalOfCompanies.Document REFS Document.SalesOrder
		             |	AND NOT DocumentJournalOfCompanies.Document REFS Document.Shipment
		             |	AND NOT DocumentJournalOfCompanies.Document REFS Document.PurchaseOrder
		             |	AND NOT DocumentJournalOfCompanies.Document REFS Document.ItemReceipt
		             |	AND NOT DocumentJournalOfCompanies.Document REFS Document.TimeTrack
		             |	AND NOT DocumentJournalOfCompanies.Document REFS Document.Statement
		             |;
		             |
		             |////////////////////////////////////////////////////////////////////////////////
		             |SELECT
		             |	TV.MyOrder AS MyOrder,
		             |	TV.RecorderPointInTime AS RecorderPointInTime,
		             |	TV.Recorder,
		             |	TV.DocDate,
		             |	TV.Company,
		             |	SUM(TV.AmountOpeningBalance) AS AmountOpeningBalance,
		             |	SUM(TV.AmountTurnover) AS AmountTurnover,
		             |	SUM(TV.AmountClosingBalance) AS AmountClosingBalance
		             |FROM
		             |	TV AS TV
		             |
		             |GROUP BY
		             |	TV.DocDate,
		             |	TV.Recorder,
		             |	TV.RecorderPointInTime,
		             |	TV.Company,
		             |	TV.MyOrder
		             |
		             |ORDER BY
		             |	MyOrder,
		             |	RecorderPointInTime";
		
		Query.SetParameter("ForwardPeriod", Ref.BeginOfPeriod - 1);
		Query.SetParameter("BeginOfPeriod", Ref.BeginOfPeriod);
		Query.SetParameter("EndOfPeriod", EndOfDay(Ref.Date));
		Query.SetParameter("Company", Ref.Company);
		Query.SetParameter("Currency", Ref.Currency);
		
		ActivityOfCompany = Query.Execute().Select(); 
		//***End ActivityOfCompany***
		
		//***ARAging***
		ARAgingQuery = New Query;
		ARAgingQuery.Text = "SELECT
		                    |	CASE
		                    |		WHEN DATEDIFF(GeneralJournalBalance.ExtDimension2.DueDate, &EndOfPeriod, DAY) <= 0
		                    |			THEN GeneralJournalBalance.AmountClosingBalance
		                    |		WHEN GeneralJournalBalance.ExtDimension2 REFS Document.CashReceipt
		                    |			THEN GeneralJournalBalance.AmountClosingBalance
		                    |		WHEN GeneralJournalBalance.ExtDimension2 REFS Document.PurchaseReturn
		                    |			THEN GeneralJournalBalance.AmountClosingBalance
		                    |		WHEN GeneralJournalBalance.ExtDimension2 REFS Document.GeneralJournalEntry
		                    |			THEN GeneralJournalBalance.AmountClosingBalance
		                    |		WHEN DATEDIFF(GeneralJournalBalance.ExtDimension2.DueDate, &EndOfPeriod, DAY) > &Interval3
		                    |				AND GeneralJournalBalance.ExtDimension2 REFS Document.SalesReturn
		                    |			THEN GeneralJournalBalance.AmountClosingBalance
		                    |		ELSE 0
		                    |	END AS D0,
		                    |	CASE
		                    |		WHEN DATEDIFF(GeneralJournalBalance.ExtDimension2.DueDate, &EndOfPeriod, DAY) <= &Interval1
		                    |				AND DATEDIFF(GeneralJournalBalance.ExtDimension2.DueDate, &EndOfPeriod, DAY) > 0
		                    |				AND NOT GeneralJournalBalance.ExtDimension2 REFS Document.GeneralJournalEntry
		                    |			THEN GeneralJournalBalance.AmountClosingBalance
		                    |		ELSE 0
		                    |	END AS D1,
		                    |	CASE
		                    |		WHEN DATEDIFF(GeneralJournalBalance.ExtDimension2.DueDate, &EndOfPeriod, DAY) <= &Interval2
		                    |				AND DATEDIFF(GeneralJournalBalance.ExtDimension2.DueDate, &EndOfPeriod, DAY) > &Interval1
		                    |				AND NOT GeneralJournalBalance.ExtDimension2 REFS Document.GeneralJournalEntry
		                    |			THEN GeneralJournalBalance.AmountClosingBalance
		                    |		ELSE 0
		                    |	END AS D2,
		                    |	CASE
		                    |		WHEN DATEDIFF(GeneralJournalBalance.ExtDimension2.DueDate, &EndOfPeriod, DAY) <= &Interval3
		                    |				AND DATEDIFF(GeneralJournalBalance.ExtDimension2.DueDate, &EndOfPeriod, DAY) > &Interval2
		                    |				AND NOT GeneralJournalBalance.ExtDimension2 REFS Document.GeneralJournalEntry
		                    |			THEN GeneralJournalBalance.AmountClosingBalance
		                    |		ELSE 0
		                    |	END AS D3,
		                    |	CASE
		                    |		WHEN DATEDIFF(GeneralJournalBalance.ExtDimension2.DueDate, &EndOfPeriod, DAY) > &Interval3
		                    |				AND NOT GeneralJournalBalance.ExtDimension2 REFS Document.SalesReturn
		                    |				AND NOT GeneralJournalBalance.ExtDimension2 REFS Document.PurchaseReturn
		                    |				AND NOT GeneralJournalBalance.ExtDimension2 REFS Document.GeneralJournalEntry
		                    |			THEN GeneralJournalBalance.AmountClosingBalance
		                    |		ELSE 0
		                    |	END AS D4,
		                    |	GeneralJournalBalance.AmountClosingBalance AS TotalD
		                    |FROM
		                    |	AccountingRegister.GeneralJournal.BalanceAndTurnovers(
		                    |			&BeginOfPeriod,
		                    |			&EndOfPeriod,
		                    |			Auto,
		                    |			,
		                    |			,
		                    |			,
		                    |			ExtDimension1 = &Company
		                    |				AND Currency = &Currency) AS GeneralJournalBalance";
							
		ARAgingQuery.SetParameter("BeginOfPeriod", Ref.BeginOfPeriod);
		ARAgingQuery.SetParameter("EndOfPeriod", EndOfDay(Ref.Date));
		ARAgingQuery.SetParameter("Company", Ref.Company);
		ARAgingQuery.SetParameter("Currency", Ref.Currency);
		ARAgingQuery.SetParameter("Interval1", 30);
		ARAgingQuery.SetParameter("Interval2", 60);
		ARAgingQuery.SetParameter("Interval3", 90);
		
		ARAgingOfCompany = ARAgingQuery.Execute().Unload(); 
		
		AmountDue = ARAgingOfCompany.Total("TotalD"); 
		//***End ARAging***
		
		//***HEADER***
		
		//---------
		//TopHeader
		//---------
		ParametersOfHeader = New Structure; 
		ParametersOfHeader.Insert("Number", Ref.Number); 
		ParametersOfHeader.Insert("Date", Ref.Date); 
		ParametersOfHeader.Insert("Currency", Ref.Currency.Symbol); 
		ParametersOfHeader.Insert("AmountDue", AmountDue); 
		
		TopHeader.Parameters.Fill(ParametersOfHeader);
		
		//Add logo
		BinaryLogo = GeneralFunctions.GetLogo();
		LogoPicture = New Picture(BinaryLogo);
		DocumentPrinting.FillLogoInDocumentTemplate(TopHeader, LogoPicture); 
				
		UsBill   = PrintTemplates.ContactInfoDatasetUs();
		Address  = ?(ValueIsFilled(Ref.MailingAddress), Ref.MailingAddress, GeneralFunctions.GetBillToAddress(Ref.Company)); 
		ThemBill = PrintTemplates.ContactInfoDataset(Ref.Company, "ThemBill", Address);
		
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
		MiddleHeader.Parameters.Fill(ThemBill);
		
		//ShowContactName
		If SettingsPrintedForm.ShowContactName Then
			
			MiddleHeader.Parameters.ThemFullName = ThemBill.ThemBillSalutation + " " + ThemBill.ThemBillFirstName + " " + ThemBill.ThemBillLastName;
			If (MiddleHeader.Parameters.ThemBillName = MiddleHeader.Parameters.ThemFullName) Or (Not ValueIsFilled(MiddleHeader.Parameters.ThemFullName)) Then
				MiddleHeader.Parameters.ThemFullName = "";
			Else
				MiddleHeader.Parameters.ThemFullName = MiddleHeader.Parameters.ThemFullName + Chars.LF;
			EndIf;
			
		EndIf;
		
		If MiddleHeader.Parameters.ThemBillLine1 <> "" Then
			MiddleHeader.Parameters.ThemBillLine1 = MiddleHeader.Parameters.ThemBillLine1 + Chars.LF; 
		EndIf;
		
		If MiddleHeader.Parameters.ThemBillLine2 <> "" Then
			MiddleHeader.Parameters.ThemBillLine2 = MiddleHeader.Parameters.ThemBillLine2 + Chars.LF; 
		EndIf;
		
		If MiddleHeader.Parameters.ThemBillLine3 <> "" Then
			MiddleHeader.Parameters.ThemBillLine3 = MiddleHeader.Parameters.ThemBillLine3 + Chars.LF; 
		EndIf;
		
		If MiddleHeader.Parameters.ThemBillCityStateZIP <> "" Then
			MiddleHeader.Parameters.ThemBillCityStateZIP = MiddleHeader.Parameters.ThemBillCityStateZIP + Chars.LF; 
		EndIf;
		
		//ShowCountry
		If Not SettingsPrintedForm.ShowCountry Then
			MiddleHeader.Parameters.ThemBillCountry = "";
		EndIf;
		
		//------------
		//BottomHeader
		//------------
		ParametersOfHeader = New Structure; 
		ParametersOfHeader.Insert("BeginOfPeriod", Format(Ref.BeginOfPeriod, "DLF=D")); 
		ParametersOfHeader.Insert("EndOfPeriod", Format(Ref.Date, "DLF=D"));
		ParametersOfHeader.Insert("Currency", Ref.Currency.Symbol); 
		
		BottomHeader.Parameters.Fill(ParametersOfHeader);
		//***END HEADER***
		
		//***Footer***
		ParametersOfFooter = New Structure;
		ParametersOfFooter.Insert("Current", ARAgingOfCompany.Total("D0"));
		ParametersOfFooter.Insert("Days1_30", ARAgingOfCompany.Total("D1"));
		ParametersOfFooter.Insert("Days31_60", ARAgingOfCompany.Total("D2"));
		ParametersOfFooter.Insert("Days61_90", ARAgingOfCompany.Total("D3"));
		ParametersOfFooter.Insert("Days91", ARAgingOfCompany.Total("D4"));
		ParametersOfFooter.Insert("AmountDue", AmountDue);
		ParametersOfFooter.Insert("CurrentDate", Format(CurrentSessionDate(), "DF='dddd, MMM d, yyyy h:mm:ss tt'"));
		
		Footer.Parameters.Fill(ParametersOfFooter);
		//***End Footer***
		
		//***BottomFooter***
		If SettingsPrintedForm.FooterTypeLeft = Enums.TextOrImage.Text Then
			BottomFooter.Parameters.FooterTextLeft   = SettingsPrintedForm.FooterTextLeft;
		ElsIf SettingsPrintedForm.FooterTypeLeft = Enums.TextOrImage.Image Then 
			FooterLeftLogo   = GeneralFunctions.GetFooterPO("StatementFooterLeft");
			FooterLeftPic    = New Picture(FooterLeftLogo);
			DocumentPrinting.FillPictureInDocumentTemplate(BottomFooter, FooterLeftPic, "FooterImageLeft"); 
		Else
			//	
		EndIf;
		
		If SettingsPrintedForm.FooterTypeCenter = Enums.TextOrImage.Text Then
			BottomFooter.Parameters.FooterTextCenter   = SettingsPrintedForm.FooterTextCenter;
		ElsIf SettingsPrintedForm.FooterTypeCenter = Enums.TextOrImage.Image Then 
			FooterCenterLogo   = GeneralFunctions.GetFooterPO("StatementFooterCenter");
			FooterCenterPic    = New Picture(FooterCenterLogo);
			DocumentPrinting.FillPictureInDocumentTemplate(BottomFooter, FooterCenterPic, "FooterImageCenter"); 
		Else
			//	
		EndIf;
		
		If SettingsPrintedForm.FooterTypeRight = Enums.TextOrImage.Text Then
			BottomFooter.Parameters.FooterTextRight   = SettingsPrintedForm.FooterTextRight;
		ElsIf SettingsPrintedForm.FooterTypeRight = Enums.TextOrImage.Image Then 
			FooterRightLogo   = GeneralFunctions.GetFooterPO("StatementFooterRight");
			FooterRightPic    = New Picture(FooterRightLogo);
			DocumentPrinting.FillPictureInDocumentTemplate(BottomFooter, FooterRightPic, "FooterImageRight"); 
		Else
			//	
		EndIf;
		//***End BottomFooter***
		
		//***Line***
		PreviousBalance = 0;
		LineIsGray      = False;
		Array           = New Array;
		
		Spreadsheet.Put(TopHeader);
		Spreadsheet.Put(MiddleHeader);
		Spreadsheet.Put(BottomHeader);
		
		While ActivityOfCompany.Next() Do
			
			ParametersOfLine = New Structure;
			ParametersOfLine.Insert("DateActivity", ActivityOfCompany.DocDate);
			ParametersOfLine.Insert("Activity", ActivityOfCompany.Recorder);
			ParametersOfLine.Insert("Amount", ActivityOfCompany.AmountTurnover);
			ParametersOfLine.Insert("Balance", ?(ActivityOfCompany.AmountClosingBalance = Null, PreviousBalance, ActivityOfCompany.AmountClosingBalance));
			
			InputLine = Undefined;
			
			If ActivityOfCompany.MyOrder = 1 Then
				LineForward.Parameters.Fill(ParametersOfLine);
				InputLine = LineForward;
			Else
				If LineIsGray Then 
					LineGray.Parameters.Fill(ParametersOfLine);
					InputLine = LineGray;
				Else
					Line.Parameters.Fill(ParametersOfLine);
					InputLine = Line;
				EndIf;
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
			
			PreviousBalance = ?(ActivityOfCompany.AmountClosingBalance = Null, PreviousBalance, ActivityOfCompany.AmountClosingBalance); 
			LineIsGray      = ?(LineIsGray, False, True);
			
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
		
		//----------Print open Sales invoices-------------
		//------------------------------------------------
		//------------------------------------------------
		Query = New Query;
		Query.Text = "SELECT DISTINCT
		             |	DocumentSalesInvoice.Ref AS Ref
		             |FROM
		             |	Document.SalesInvoice AS DocumentSalesInvoice
		             |		LEFT JOIN AccountingRegister.GeneralJournal.Balance(&EndOfPeriod, , , ExtDimension2 REFS Document.SalesInvoice) AS GeneralJournalBalance
		             |		ON (GeneralJournalBalance.Account = DocumentSalesInvoice.ARAccount)
		             |			AND (GeneralJournalBalance.ExtDimension1 = DocumentSalesInvoice.Company)
		             |			AND (GeneralJournalBalance.ExtDimension2 = DocumentSalesInvoice.Ref)
		             |WHERE
		             |	DocumentSalesInvoice.DeletionMark = FALSE
		             |	AND DocumentSalesInvoice.Posted = TRUE
		             |	AND GeneralJournalBalance.AmountBalance > 0
		             |	AND DocumentSalesInvoice.Company = &Company
		             |
		             |ORDER BY
		             |	Ref";
		
		Query.SetParameter("Company", Ref.Company);
		Query.SetParameter("EndOfPeriod", EndOfDay(Ref.Date) + 1);
		
		QueryResult = Query.Execute();
		
		SelectionDetailRecords = QueryResult.Select();
		
		While SelectionDetailRecords.Next() Do
			Spreadsheet.PutHorizontalPageBreak();
			
			SI_Spreadsheet = New SpreadsheetDocument;
			SetPageSize(SI_Spreadsheet);
			
			PrintFormFunctions.PrintSI(SI_Spreadsheet, "", SelectionDetailRecords.Ref);
			Spreadsheet.Put(SI_Spreadsheet);
		EndDo;
		//------------------------------------------------
		//------------------------------------------------

		InsertPageBreak = True;
	EndDo;
	
	//Add footer with page count	
	Spreadsheet.Header.Enabled       = True;
	Spreadsheet.Header.StartPage     = 1;
	Spreadsheet.Header.VerticalAlign = VerticalAlign.Bottom;	
	Spreadsheet.Header.Font          = New Font(Spreadsheet.Header.Font, , , , True);
	Spreadsheet.Header.RightText     = "Page [&PageNumber] of [&PagesTotal]";
		
EndProcedure

Procedure SetPageSize(Spreadsheet)
	
	//
	Spreadsheet.PageSize     = "Letter";
	
	Spreadsheet.TopMargin    = 5;
	Spreadsheet.LeftMargin   = 5;
	Spreadsheet.RightMargin  = 5;
	Spreadsheet.BottomMargin = 5;
	
	Spreadsheet.HeaderSize   = 5;
	Spreadsheet.FooterSize   = 5;
	
	Spreadsheet.FitToPage    = True;
	
EndProcedure
