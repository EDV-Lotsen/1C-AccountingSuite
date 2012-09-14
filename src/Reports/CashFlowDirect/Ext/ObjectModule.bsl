Function CashFlow(StartDate, EndDate) Export
	
	StartD = StartDate;
	EndD = EndDate;
	
	If StartDate =  Date(1,1,1) Then
		WhereCase = "WHERE GeneralJournal.Period <= &EndDate";
		PeriodLabel = "- " + Format(EndD, "DLF=D");
	EndIf;
	
	If EndDate =  Date(1,1,1) Then
		WhereCase = "WHERE GeneralJournal.Period >= &StartDate";
		PeriodLabel = Format(StartD, "DLF=D") + " -";
	EndIf;
	
	If StartDate = Date(1,1,1) AND EndDate = Date(1,1,1) Then
		WhereCase = "";
		PeriodLabel = "All dates";
	EndIf;
	
	If NOT StartDate = Date(1,1,1) AND NOT EndDate = Date(1,1,1) Then
		WhereCase = "WHERE GeneralJournal.Period >= &StartDate AND GeneralJournal.Period <= &EndDate";
		PeriodLabel = Format(StartD, "DLF=D") + " - " + Format(EndD, "DLF=D");
	EndIf;
	
	OurCompany = Catalogs.Companies.OurCompany;
	
	SpreadsheetDocument = New SpreadsheetDocument;
	Template = GetTemplate("Template");
	
	Header = Template.GetArea("Header");
	Header.Parameters.PeriodLabel = PeriodLabel;
	Header.Parameters.Company = GeneralFunctions.GetAttributeValue(OurCompany, "Name");
	SpreadsheetDocument.Put(Header);
	
	// Main section
	
	CashData = New ValueTable();
	CashData.Columns.Add("Account");
	CashData.Columns.Add("AccountDescription");
	CashData.Columns.Add("CashFlowSection");
	CashData.Columns.Add("AmountRC");
	
	Query = New Query("SELECT
	                  |	GeneralJournal.Recorder
	                  |FROM
	                  |	AccountingRegister.GeneralJournal AS GeneralJournal
					  | " + WhereCase + "
					  |
	                  |GROUP BY
	                  |	GeneralJournal.Recorder");
	Query.Parameters.Insert("StartDate", StartDate);
	Query.Parameters.Insert("EndDate", EndDate);
	Selection = Query.Execute().Unload();
	
	NumRows = Selection.Count() - 1;
	
	For i = 0 To NumRows Do
		
		Query = New Query("SELECT
		                  |	GeneralJournal.Period,
		                  |	GeneralJournal.Recorder,
		                  |	GeneralJournal.LineNumber,
		                  |	GeneralJournal.RecordType,
		                  |	GeneralJournal.Account,
		                  |	GeneralJournal.Currency,
		                  |	GeneralJournal.Amount,
		                  |	GeneralJournal.AmountRC
		                  |FROM
		                  |	AccountingRegister.GeneralJournal AS GeneralJournal
		                  |WHERE
		                  |	GeneralJournal.Recorder = &Recorder");
		Query.Parameters.Insert("Recorder", Selection[i].Recorder);
		Transaction = Query.Execute().Unload();
		
		NumLines = Transaction.Count() - 1;
				
		BankPresent = False;
		Direction = 1;
		For y = 0 To NumLines Do
			If Transaction[y].Account.AccountType = Enums.AccountTypes.Bank Then
				BankPresent = True;
				If Transaction[y].RecordType = AccountingRecordType.Debit Then
				Else
					Direction = -1;
				EndIf;
			EndIf;
		EndDo;
		
		UFPresent = False;
		For y = 0 to NumLines Do
			If Transaction[y].Account = Constants.UndepositedFundsAccount.Get() Then
				UFPresent = True;
			EndIf;
		EndDo;
				
		If (BankPresent OR UFPresent) AND NOT (BankPresent AND UFPresent) Then
			
			BankTransactionAmounts = New ValueTable();
			BankTransactionAmounts.Columns.Add("AmountRC");

			For z = 0 to NumLines Do
							
				If Transaction[z].Account.AccountType = Enums.AccountTypes.Bank OR Transaction[z].Account = Constants.UndepositedFundsAccount.Get() Then
		            BTAmount = BankTransactionAmounts.Add();
					BTAmount.AmountRC = Transaction[z].AmountRC;
				Else
				EndIf;
				
			EndDo;

			
			For z = 0 to NumLines Do
				
				If Transaction[z].Account.AccountType = Enums.AccountTypes.Bank OR Transaction[z].Account = Constants.UndepositedFundsAccount.Get() Then
				Else
					
					If NOT BankTransactionAmounts.Find(Transaction[z].AmountRC, "AmountRC") = Undefined Then
					
						CashDataRow = CashData.Add();
						CashDataRow.Account = Transaction[z].Account;
						CashDataRow.AccountDescription = Transaction[z].Account.Description;
						CashDataRow.CashFlowSection = Transaction[z].Account.CashFlowSection;
						CashDataRow.AmountRC = Transaction[z].AmountRC * Direction;

					EndIf;	
						
				EndIf;
				
			EndDo;
		EndIf;
				
	EndDo;
	
	CashData.GroupBy("Account, AccountDescription, CashFlowSection", "AmountRC");
	
	DatasetRows = CashData.Count() - 1;
	
	// Data output - Operating
	
	OperatingHeader = Template.GetArea("OperatingHeader");
	SpreadsheetDocument.Put(OperatingHeader);
	
	Operating = Template.GetArea("Operating");
	
	TotalOperating = 0;
	For x = 0 To DatasetRows Do
		If CashData[x].CashFlowSection = Enums.CashFlowSections.Operating Then
			Operating.Parameters.Fill(CashData[x]);
			SpreadsheetDocument.Put(Operating);
			TotalOperating = TotalOperating + CashData[x].AmountRC;
		EndIf;
	EndDo;

	OperatingFooter = Template.GetArea("OperatingFooter");
	OperatingFooter.Parameters.Amount = TotalOperating;
	SpreadsheetDocument.Put(OperatingFooter);

	// Data output - Investing
	
	InvestingHeader = Template.GetArea("InvestingHeader");
	SpreadsheetDocument.Put(InvestingHeader);
	
	Investing = Template.GetArea("Investing");
	
	TotalInvesting = 0;
	For x = 0 To DatasetRows Do
		If CashData[x].CashFlowSection = Enums.CashFlowSections.Investing Then
			Investing.Parameters.Fill(CashData[x]);
			SpreadsheetDocument.Put(Investing);
			TotalInvesting = TotalInvesting + CashData[x].AmountRC;
		EndIf;
	EndDo;

	InvestingFooter = Template.GetArea("InvestingFooter");
	InvestingFooter.Parameters.Amount = TotalInvesting;
	SpreadsheetDocument.Put(InvestingFooter);

	// Data output - Financing
	
	FinancingHeader = Template.GetArea("FinancingHeader");
	SpreadsheetDocument.Put(FinancingHeader);
	
	Financing = Template.GetArea("Financing");
	
	TotalFinancing = 0;
	For x = 0 To DatasetRows Do
		If CashData[x].CashFlowSection = Enums.CashFlowSections.Financing Then
			Financing.Parameters.Fill(CashData[x]);
			SpreadsheetDocument.Put(Financing);
			TotalFinancing = TotalFinancing + CashData[x].AmountRC;
		EndIf;
	EndDo;

	FinancingFooter = Template.GetArea("FinancingFooter");
	FinancingFooter.Parameters.Amount = TotalFinancing;
	SpreadsheetDocument.Put(FinancingFooter);

	// Calculating beginning bank balance
	
	BeginningBalance = 0;
	
	If StartDate =  Date(1,1,1) Then
		
		// If no beginning date set then beginning balance = 0;
		
	Else
	
		Reg = AccountingRegisters.GeneralJournal;
		
		Query = New Query("SELECT
		                  |	ChartOfAccounts.Ref
		                  |FROM
		                  |	ChartOfAccounts.ChartOfAccounts AS ChartOfAccounts
		                  |WHERE
		                  |	ChartOfAccounts.AccountType = VALUE(Enum.AccountTypes.Bank)
		                  |
		                  |ORDER BY
		                  |	ChartOfAccounts.Code");	
		
		QueryResult = Query.Execute();

		If QueryResult.IsEmpty() Then
		Else
			RecorderDataset = QueryResult.Choose();
			While RecorderDataset.Next() Do
				
				Filter = New Structure("Account", RecorderDataset.Ref);	
				RecordSelection = Reg.Balance(StartDate,,Filter);
				
				NoOfRows = RecordSelection.Count();
				If NoOfRows = 0 Then
				Else
					
					Balance = 0;				
					Balance = RecordSelection.Total("AmountRCBalanceDr") - RecordSelection.Total("AmountRCBalanceCr");				
					BeginningBalance = BeginningBalance + Balance;
					
				EndIf;			
			EndDo;
		EndIf;

	EndIf;
	
	// Outputting Cash Flow summary
	
	CFSummary = Template.GetArea("CFSummary");
	
	ChangeAmount = TotalOperating + TotalInvesting + TotalFinancing; 
	CFSummary.Parameters.ChangeAmount = ChangeAmount;
	CFSummary.Parameters.BeginningBalance = BeginningBalance;
	CFSummary.Parameters.EndingBalance = BeginningBalance + ChangeAmount;
	
	SpreadsheetDocument.Put(CFSummary);
	
	// Return result
	
	Return SpreadSheetDocument;
	
EndFunction