Function GeneralLedger(StartDate, EndDate) Export
	
	//StartD = StartDate;
	//EndD = EndDate;
	
	If StartDate =  Date(1,1,1) Then
		WhereCase = "AND GeneralJournal.Period <= &EndDate";
		PeriodLabel = "- " + Format(EndDate, "DLF=D");
	EndIf;
	
	If EndDate =  Date(1,1,1) Then
		WhereCase = "AND GeneralJournal.Period >= &StartDate";
		PeriodLabel = Format(StartDate, "DLF=D") + " -";
	EndIf;
	
	If StartDate = Date(1,1,1) AND EndDate = Date(1,1,1) Then
		WhereCase = "";
		PeriodLabel = "All dates";
	EndIf;
	
	If NOT StartDate = Date(1,1,1) AND NOT EndDate = Date(1,1,1) Then
		WhereCase = "AND GeneralJournal.Period >= &StartDate AND GeneralJournal.Period <= &EndDate";
		PeriodLabel = Format(StartDate, "DLF=D") + " - " + Format(EndDate, "DLF=D");
	EndIf;
	
	OurCompany = Catalogs.Companies.OurCompany;
	
	SpreadsheetDocument = New SpreadsheetDocument;
	Template = GetTemplate("Template");
	
	Header = Template.GetArea("Header");
	Header.Parameters.PeriodLabel = PeriodLabel;
	Header.Parameters.Company = GeneralFunctions.GetAttributeValue(OurCompany, "Name");
	SpreadsheetDocument.Put(Header);

	Reg = AccountingRegisters.GeneralJournal;
	
	// Main section
	
	AccountHeader = Template.GetArea("AccountHeader");	
	
	Query = New Query("SELECT
	                  |	ChartOfAccounts.Ref
	                  |FROM
	                  |	ChartOfAccounts.ChartOfAccounts AS ChartOfAccounts
	                  |
	                  |ORDER BY
	                  |	ChartOfAccounts.Code");	
	
	QueryResult = Query.Execute();

	If QueryResult.IsEmpty() Then
	Else
		RecorderDataset = QueryResult.Choose();
		While RecorderDataset.Next() Do
			
			BegBalance = 0;
			
			If StartDate =  Date(1,1,1) Then
				BegBalance = 0;
			Else	
				Filter = New Structure("Account", RecorderDataset.Ref);	
				RecordSelection = Reg.Balance(StartDate,,Filter,,"AmountRC");
				
				NoOfRows = RecordSelection.Count();
				If NoOfRows = 0 Then
					BegBalance = 0;	
				Else
					BegBalance = RecordSelection.Total("AmountRCBalanceDr") - RecordSelection.Total("AmountRCBalanceCr");
				EndIf;
			EndIf;
						
			AccountHeader.Parameters.AccNum = RecorderDataset.Ref;
			AccountHeader.Parameters.AccName = RecorderDataset.Ref.Description;
			AccountHeader.Parameters.BegBalance = BegBalance;
			SpreadsheetDocument.Put(AccountHeader);
			
			AccountData = Template.GetArea("AccountData");
			
			Query2 = New Query("SELECT
                  |	GeneralJournal.Period AS Period,
                  |	GeneralJournal.Recorder,
                  |	GeneralJournal.RecordType,
                  |	GeneralJournal.AmountRC
                  |FROM
                  |	AccountingRegister.GeneralJournal AS GeneralJournal
                  |WHERE
                  |	GeneralJournal.Account = &Account
				  | " + WhereCase + "
                  |
                  |ORDER BY
                  |	Period");
				  
			Query2.Parameters.Insert("StartDate", StartDate);
			Query2.Parameters.Insert("EndDate", EndDate);
			Query2.Parameters.Insert("Account", RecorderDataset.Ref);
           	Selection = Query2.Execute().Choose();
			
			TotalDebit = 0;
			TotalCredit = 0;
			
			While Selection.Next() Do
				
				AccountData.Parameters.Date = Format(Selection.Period, "DLF=D");
				AccountData.Parameters.Document = Selection.Recorder.Metadata().Synonym;
				AccountData.Parameters.Number = Selection.Recorder.Number;
				
				If Selection.RecordType = AccountingRecordType.Debit Then
					AccountData.Parameters.Debit = Selection.AmountRC;
					AccountData.Parameters.Credit = "";
					TotalDebit = TotalDebit + Selection.AmountRC;
				Else
					AccountData.Parameters.Credit = Selection.AmountRC;
					AccountData.Parameters.Debit = "";
					TotalCredit = TotalCredit + Selection.AmountRC; 
				EndIf;	
				SpreadsheetDocument.Put(AccountData);
			
			EndDo;
			
			EndBalance = 0;
			EndBalance = BegBalance + TotalDebit - TotalCredit;
			AccountFooter = Template.GetArea("AccountFooter");
			AccountFooter.Parameters.EndBalance = EndBalance;
			SpreadsheetDocument.Put(AccountFooter);
			
		EndDo;
	EndIf;
	
	Return SpreadSheetDocument;
	
EndFunction

