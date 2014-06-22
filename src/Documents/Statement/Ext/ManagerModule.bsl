
Procedure Print(Spreadsheet, RefArray) Export
	
	Template = Documents.Statement.GetTemplate("Print");
		
	Header      = Template.GetArea("Header");
	Line        = Template.GetArea("Line");
	LineForward = Template.GetArea("LineForward");
	Footer      = Template.GetArea("Footer");
	Spreadsheet.Clear();

	InsertPageBreak = False;
	For Each Ref In RefArray Do
		
		If InsertPageBreak Then
			Spreadsheet.PutHorizontalPageBreak();
		EndIf;
		
		//ActivityOfCompany
		Query = New Query;
		Query.Text = "SELECT
		             |	1 AS MyOrder,
		             |	NULL AS RecorderPointInTime,
		             |	""Balance Forward"" AS Recorder,
		             |	&ForwardPeriod AS DocDate,
		             |	GeneralJournalBalance.ExtDimension1 AS Company,
		             |	NULL AS AmountRCOpeningBalance,
		             |	NULL AS AmountRCTurnover,
		             |	GeneralJournalBalance.AmountRCBalance AS AmountRCClosingBalance
		             |INTO TV
		             |FROM
		             |	AccountingRegister.GeneralJournal.Balance(&ForwardPeriod, , , ExtDimension1 = &Company) AS GeneralJournalBalance
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
		             |	GeneralJournalBalanceAndTurnovers.AmountRCOpeningBalance,
		             |	GeneralJournalBalanceAndTurnovers.AmountRCTurnover,
		             |	GeneralJournalBalanceAndTurnovers.AmountRCClosingBalance
		             |FROM
		             |	AccountingRegister.GeneralJournal.BalanceAndTurnovers(&BeginOfPeriod, &EndOfPeriod, Auto, , , , ExtDimension1 = &Company) AS GeneralJournalBalanceAndTurnovers
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
		             |			THEN DocumentJournalOfCompanies.Total
		             |		ELSE NULL
		             |	END,
		             |	NULL
		             |FROM
		             |	InformationRegister.DocumentJournalOfCompanies AS DocumentJournalOfCompanies
		             |WHERE
		             |	DocumentJournalOfCompanies.Company = &Company
		             |	AND DocumentJournalOfCompanies.DocumentStatus = 1
		             |	AND DocumentJournalOfCompanies.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
		             |	AND NOT DocumentJournalOfCompanies.Document REFS Document.SalesOrder
		             |	AND NOT DocumentJournalOfCompanies.Document REFS Document.PurchaseOrder
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
		             |	SUM(TV.AmountRCOpeningBalance) AS AmountRCOpeningBalance,
		             |	SUM(TV.AmountRCTurnover) AS AmountRCTurnover,
		             |	SUM(TV.AmountRCClosingBalance) AS AmountRCClosingBalance
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
		
		ActivityOfCompany = Query.Execute().Select(); 
		//End ActivityOfCompany
		
		//ARAging
		ARAgingQuery = New Query;
		ARAgingQuery.Text = "SELECT
		                    |	CASE
		                    |		WHEN DATEDIFF(GeneralJournalBalance.ExtDimension2.DueDate, &EndOfPeriod, DAY) <= 0
		                    |			THEN GeneralJournalBalance.AmountRCClosingBalance
		                    |		WHEN GeneralJournalBalance.ExtDimension2 REFS Document.CashReceipt
		                    |			THEN GeneralJournalBalance.AmountRCClosingBalance
		                    |		WHEN GeneralJournalBalance.ExtDimension2 REFS Document.PurchaseReturn
		                    |			THEN GeneralJournalBalance.AmountRCClosingBalance
		                    |		WHEN GeneralJournalBalance.ExtDimension2 REFS Document.GeneralJournalEntry
		                    |			THEN GeneralJournalBalance.AmountRCClosingBalance
		                    |		WHEN DATEDIFF(GeneralJournalBalance.ExtDimension2.DueDate, &EndOfPeriod, DAY) > &Interval3
		                    |				AND GeneralJournalBalance.ExtDimension2 REFS Document.SalesReturn
		                    |			THEN GeneralJournalBalance.AmountRCClosingBalance
		                    |		ELSE 0
		                    |	END AS D0,
		                    |	CASE
		                    |		WHEN DATEDIFF(GeneralJournalBalance.ExtDimension2.DueDate, &EndOfPeriod, DAY) <= &Interval1
		                    |				AND DATEDIFF(GeneralJournalBalance.ExtDimension2.DueDate, &EndOfPeriod, DAY) > 0
		                    |				AND NOT GeneralJournalBalance.ExtDimension2 REFS Document.GeneralJournalEntry
		                    |			THEN GeneralJournalBalance.AmountRCClosingBalance
		                    |		ELSE 0
		                    |	END AS D1,
		                    |	CASE
		                    |		WHEN DATEDIFF(GeneralJournalBalance.ExtDimension2.DueDate, &EndOfPeriod, DAY) <= &Interval2
		                    |				AND DATEDIFF(GeneralJournalBalance.ExtDimension2.DueDate, &EndOfPeriod, DAY) > &Interval1
		                    |				AND NOT GeneralJournalBalance.ExtDimension2 REFS Document.GeneralJournalEntry
		                    |			THEN GeneralJournalBalance.AmountRCClosingBalance
		                    |		ELSE 0
		                    |	END AS D2,
		                    |	CASE
		                    |		WHEN DATEDIFF(GeneralJournalBalance.ExtDimension2.DueDate, &EndOfPeriod, DAY) <= &Interval3
		                    |				AND DATEDIFF(GeneralJournalBalance.ExtDimension2.DueDate, &EndOfPeriod, DAY) > &Interval2
		                    |				AND NOT GeneralJournalBalance.ExtDimension2 REFS Document.GeneralJournalEntry
		                    |			THEN GeneralJournalBalance.AmountRCClosingBalance
		                    |		ELSE 0
		                    |	END AS D3,
		                    |	CASE
		                    |		WHEN DATEDIFF(GeneralJournalBalance.ExtDimension2.DueDate, &EndOfPeriod, DAY) > &Interval3
		                    |				AND NOT GeneralJournalBalance.ExtDimension2 REFS Document.SalesReturn
		                    |				AND NOT GeneralJournalBalance.ExtDimension2 REFS Document.PurchaseReturn
		                    |				AND NOT GeneralJournalBalance.ExtDimension2 REFS Document.GeneralJournalEntry
		                    |			THEN GeneralJournalBalance.AmountRCClosingBalance
		                    |		ELSE 0
		                    |	END AS D4,
		                    |	GeneralJournalBalance.AmountRCClosingBalance AS TotalD
		                    |FROM
		                    |	AccountingRegister.GeneralJournal.BalanceAndTurnovers(&BeginOfPeriod, &EndOfPeriod, Auto, , , , ExtDimension1 = &Company) AS GeneralJournalBalance";
							
		ARAgingQuery.SetParameter("BeginOfPeriod", Ref.BeginOfPeriod);
		ARAgingQuery.SetParameter("EndOfPeriod", EndOfDay(Ref.Date));
		ARAgingQuery.SetParameter("Company", Ref.Company);
		ARAgingQuery.SetParameter("Interval1", 30);
		ARAgingQuery.SetParameter("Interval2", 60);
		ARAgingQuery.SetParameter("Interval3", 90);
		
		ARAgingOfCompany = ARAgingQuery.Execute().Unload(); 
		
		AmountDue = ARAgingOfCompany.Total("TotalD"); 
		//End ARAging
		
		//Header
		ParametersOfHeader = New Structure; 
		ParametersOfHeader.Insert("OurCompany", Constants.SystemTitle.Get()); 
		ParametersOfHeader.Insert("Company", Ref.Company); 
		ParametersOfHeader.Insert("Number", Ref.Number); 
		ParametersOfHeader.Insert("Date", Ref.Date); 
		ParametersOfHeader.Insert("AmountDue", AmountDue); 
		ParametersOfHeader.Insert("BeginOfPeriod", Format(Ref.BeginOfPeriod, "DLF=D")); 
		ParametersOfHeader.Insert("EndOfPeriod", Format(Ref.Date, "DLF=D"));
		
		Header.Parameters.Fill(ParametersOfHeader);
		Spreadsheet.Put(Header);
		//End Header
		
		//Line
		PreviousBalance = 0;
		
		While ActivityOfCompany.Next() Do
			
			ParametersOfLine = New Structure;
			ParametersOfLine.Insert("DateActivity", ActivityOfCompany.DocDate);
			ParametersOfLine.Insert("Activity", ActivityOfCompany.Recorder);
			ParametersOfLine.Insert("Amount", ActivityOfCompany.AmountRCTurnover);
			ParametersOfLine.Insert("Balance", ?(ActivityOfCompany.AmountRCClosingBalance = Null, PreviousBalance, ActivityOfCompany.AmountRCClosingBalance));
			
			If ActivityOfCompany.MyOrder = 1 Then
				LineForward.Parameters.Fill(ParametersOfLine);
				Spreadsheet.Put(LineForward);
			Else
				Line.Parameters.Fill(ParametersOfLine);
				Spreadsheet.Put(Line);
			EndIf;
			
			PreviousBalance = ActivityOfCompany.AmountRCClosingBalance; 
			
		EndDo;
		//End Line
		
		//Footer
		ParametersOfFooter = New Structure;
		ParametersOfFooter.Insert("Current", ARAgingOfCompany.Total("D0"));
		ParametersOfFooter.Insert("Days1_30", ARAgingOfCompany.Total("D1"));
		ParametersOfFooter.Insert("Days31_60", ARAgingOfCompany.Total("D2"));
		ParametersOfFooter.Insert("Days61_90", ARAgingOfCompany.Total("D3"));
		ParametersOfFooter.Insert("Days91", ARAgingOfCompany.Total("D4"));
		ParametersOfFooter.Insert("AmountDue", AmountDue);
		ParametersOfFooter.Insert("CurrentDate", Format(CurrentSessionDate(), "DF='dddd, MMM d, yyyy h:mm:ss tt'"));
		
		Footer.Parameters.Fill(ParametersOfFooter);
		Spreadsheet.Put(Footer);
		//End Footer

		InsertPageBreak = True;
	EndDo;
	
	Spreadsheet.FitToPage = True;
	
EndProcedure
