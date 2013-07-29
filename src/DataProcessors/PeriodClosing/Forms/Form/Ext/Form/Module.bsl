

&AtClient
Procedure CreateTransaction(Command)
	
	PeriodClosing(TransactionDate, RetainedEarningsAccount);
	
EndProcedure

Procedure PeriodClosing(TransactionDate, RetainedEarningsAccount);
	
	TotalRE = 0;
	TotalDr = 0;
	
	Transaction = Documents.GeneralJournalEntry.CreateDocument();
	
	Transaction.Currency = GeneralFunctionsReusable.DefaultCurrency();
	Transaction.Date = TransactionDate;
	Transaction.ExchangeRate = 1;
	Transaction.Memo = "period closing";
		
	Query = New Query("SELECT
	                  |	ChartOfAccounts.Ref
	                  |FROM
	                  |	ChartOfAccounts.ChartOfAccounts AS ChartOfAccounts
	                  |WHERE
	                  |	ChartOfAccounts.AccountType = VALUE(Enum.AccountTypes.Income) OR
					  | ChartOfAccounts.AccountType = VALUE(Enum.AccountTypes.OtherIncome) OR
					  | ChartOfAccounts.AccountType = VALUE(Enum.AccountTypes.CostOfSales) OR
					  | ChartOfAccounts.AccountType = VALUE(Enum.AccountTypes.Expense) OR
					  | ChartOfAccounts.AccountType = VALUE(Enum.AccountTypes.OtherExpense)");					  
	Result = Query.Execute().Choose();
		
	While Result.Next() Do

		Query = New Query("SELECT
		                  |	GeneralJournalBalance.AmountRCSplittedBalanceDr,
		                  |	GeneralJournalBalance.AmountRCSplittedBalanceCr
		                  |FROM
		                  |	AccountingRegister.GeneralJournal.Balance(&Period, , , ) AS GeneralJournalBalance
		                  |WHERE
		                  |	GeneralJournalBalance.Account = &Account");
		Query.SetParameter("Account", Result.Ref);
		Query.SetParameter("Period", EndOfDay(TransactionDate));
		
		QueryResult = Query.Execute();
		If QueryResult.IsEmpty() Then
		Else
			Dataset = QueryResult.Unload();
			BalanceDr = Dataset[0].AmountRCSplittedBalanceDr;
			BalanceCr = Dataset[0].AmountRCSplittedBalanceCr;
			Balance = 0;
			
			If Result.Ref.AccountType = Enums.AccountTypes.Income OR
				Result.Ref.AccountType = Enums.AccountTypes.OtherIncome Then
					Balance = BalanceCr - BalanceDr;
			Else
					Balance = BalanceDr - BalanceCr;
			EndIf;
			
			NewRow = Transaction.LineItems.Add();
			NewRow.Account = Result.Ref;
			NewRow.AccountDescription = Result.Ref.Description;
			
			If Result.Ref.AccountType = Enums.AccountTypes.Income OR
				Result.Ref.AccountType = Enums.AccountTypes.OtherIncome Then

				If Balance > 0 Then
					NewRow.AmountDr = Balance;
					TotalDr = TotalDr + Balance;
				ElsIf Balance < 0 Then
					NewRow.AmountCr = Balance * -1;
				EndIf;
				
				TotalRE = TotalRE + Balance;
				
			Else
				
				If Balance > 0 Then
					NewRow.AmountCr = Balance;
				ElsIf Balance < 0 Then
					NewRow.AmountDr = Balance * -1;
					TotalDr = TotalDr + Balance * -1;
				EndIf;
				
				TotalRE = TotalRE - Balance;
				
			EndIf;		
			
		EndIf;
		
	EndDo;
	
	If TotalRE > 0 Then
		NewRow = Transaction.LineItems.Add();
		NewRow.Account = RetainedEarningsAccount;
		NewRow.AccountDescription = RetainedEarningsAccount.Description;
		NewRow.AmountCr = TotalRE;
	ElsIf TotalRE < 0 Then
		NewRow = Transaction.LineItems.Add();
		NewRow.Account = RetainedEarningsAccount;
		NewRow.AccountDescription = RetainedEarningsAccount.Description;
		NewRow.AmountDr = TotalRE * -1;
		TotalDr = TotalDr + TotalRE * -1;
    EndIf;
		
	Transaction.DocumentTotal = TotalDr;
	Transaction.DocumentTotalRC = TotalDr;
	Transaction.Write(DocumentWriteMode.Posting);
	
EndProcedure



	