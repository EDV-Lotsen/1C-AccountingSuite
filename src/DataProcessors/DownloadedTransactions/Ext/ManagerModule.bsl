
&AtServer
Function TransactionIsDuplicate(BankAccount, TransactionDate, Amount, CheckNumber, Description, Val BankTransactions = Undefined) Export
	
	If TransactionDate = Undefined Then
		TransactionDate = '00010101';
	EndIf;
	If Amount = Undefined Then
		Amount = 0;
	EndIf;
	If CheckNumber = Undefined Then
		CheckNumber = "";
	EndIf;
	If Description = Undefined Then
		Description = "";
	EndIf;
	
	Query = New Query;
	
	//For "Cloud banking"
	If BankTransactions = Undefined Then 
		Query.Text = "SELECT
		             |	BankTransactions.BankAccount,
		             |	CASE
		             |		WHEN BankTransactions.Document.gh_date IS NULL 
		             |			THEN BankTransactions.TransactionDate
		             |		ELSE BankTransactions.Document.gh_date
		             |	END AS TransactionDate,
		             |	BankTransactions.Amount,
		             |	BankTransactions.CheckNumber,
		             |	BankTransactions.Description
		             |FROM
		             |	InformationRegister.BankTransactions AS BankTransactions
		             |WHERE
		             |	BankTransactions.BankAccount = &BankAccount
		             |	AND CASE
		             |			WHEN BankTransactions.Document.gh_date IS NULL 
		             |				THEN BankTransactions.TransactionDate = &TransactionDate
		             |			ELSE BankTransactions.Document.gh_date = &TransactionDate
		             |		END
		             |	AND BankTransactions.Amount = &Amount
		             |	AND BankTransactions.CheckNumber = &CheckNumber
		             |	AND BankTransactions.Description = &Description";
		
		Query.SetParameter("BankAccount", BankAccount);
		Query.SetParameter("TransactionDate", TransactionDate);
		Query.SetParameter("Amount", Amount);
		Query.SetParameter("CheckNumber", CheckNumber);
		Query.SetParameter("Description", Description);
	Else
		
		BankTransactionsHaveAmount = False;
		For Each CurrentColumn In BankTransactions.Columns Do
			If CurrentColumn.Name = "Amount" Then
				BankTransactionsHaveAmount = True;
			EndIf;
		EndDo;
		
		//For "Bank accounts"
		If BankTransactionsHaveAmount Then
			
			Query.Text = "SELECT
			             |	BankTransactions.TransactionDate AS TransactionDate,
			             |	BankTransactions.Amount AS Amount,
			             |	BankTransactions.CheckNumber AS CheckNumber,
			             |	BankTransactions.Description AS Description
			             |INTO BankTransactions
			             |FROM
			             |	&BankTransactions AS BankTransactions
			             |;
			             |
			             |////////////////////////////////////////////////////////////////////////////////
			             |SELECT
			             |	CASE
			             |		WHEN BankTransactions.Document.gh_date IS NULL 
			             |			THEN BankTransactions.TransactionDate
			             |		ELSE BankTransactions.Document.gh_date
			             |	END AS TransactionDate,
			             |	BankTransactions.Amount,
			             |	BankTransactions.CheckNumber,
			             |	BankTransactions.Description
			             |FROM
			             |	InformationRegister.BankTransactions AS BankTransactions
			             |WHERE
			             |	BankTransactions.BankAccount = &BankAccount
			             |	AND CASE
			             |			WHEN BankTransactions.Document.gh_date IS NULL 
			             |				THEN BankTransactions.TransactionDate = &TransactionDate
			             |			ELSE BankTransactions.Document.gh_date = &TransactionDate
			             |		END
			             |	AND BankTransactions.Amount = &Amount
			             |	AND BankTransactions.CheckNumber = &CheckNumber
			             |	AND BankTransactions.Description = &Description
			             |
			             |UNION ALL
			             |
			             |SELECT
			             |	BankTransactions.TransactionDate,
			             |	BankTransactions.Amount,
			             |	BankTransactions.CheckNumber,
			             |	BankTransactions.Description
			             |FROM
			             |	BankTransactions AS BankTransactions
			             |WHERE
			             |	BankTransactions.TransactionDate = &TransactionDate
			             |	AND BankTransactions.Amount = &Amount
			             |	AND BankTransactions.CheckNumber = &CheckNumber
			             |	AND BankTransactions.Description = &Description";
						 
		//For "Process month"
		Else
			
			Query.Text = "SELECT
			             |	BankTransactions.gh_date AS TransactionDate,
			             |	BankTransactions.Deposit AS Deposit,
			             |	BankTransactions.Payment AS Payment,
			             |	BankTransactions.RefNumber AS CheckNumber,
			             |	BankTransactions.Memo AS Description
			             |INTO BankTransactions
			             |FROM
			             |	&BankTransactions AS BankTransactions
			             |;
			             |
			             |////////////////////////////////////////////////////////////////////////////////
			             |SELECT
			             |	CASE
			             |		WHEN BankTransactions.Document.gh_date IS NULL 
			             |			THEN BankTransactions.TransactionDate
			             |		ELSE BankTransactions.Document.gh_date
			             |	END AS TransactionDate,
			             |	BankTransactions.Amount,
			             |	BankTransactions.CheckNumber,
			             |	BankTransactions.Description
			             |FROM
			             |	InformationRegister.BankTransactions AS BankTransactions
			             |WHERE
			             |	BankTransactions.BankAccount = &BankAccount
			             |	AND CASE
			             |			WHEN BankTransactions.Document.gh_date IS NULL 
			             |				THEN BankTransactions.TransactionDate = &TransactionDate
			             |			ELSE BankTransactions.Document.gh_date = &TransactionDate
			             |		END
			             |	AND BankTransactions.Amount = &Amount
			             |	AND BankTransactions.CheckNumber = &CheckNumber
			             |	AND BankTransactions.Description = &Description
			             |
			             |UNION ALL
			             |
			             |SELECT
			             |	BankTransactions.TransactionDate,
			             |	CASE
			             |		WHEN &Amount > 0
			             |			THEN BankTransactions.Deposit
			             |		ELSE -BankTransactions.Payment
			             |	END,
			             |	BankTransactions.CheckNumber,
			             |	BankTransactions.Description
			             |FROM
			             |	BankTransactions AS BankTransactions
			             |WHERE
			             |	BankTransactions.TransactionDate = &TransactionDate
			             |	AND CASE
			             |			WHEN &Amount > 0
			             |				THEN BankTransactions.Deposit = &Amount
			             |			ELSE BankTransactions.Payment = -&Amount
			             |		END
			             |	AND BankTransactions.CheckNumber = &CheckNumber
			             |	AND BankTransactions.Description = &Description";
			
		EndIf;
				
		Query.SetParameter("BankTransactions", BankTransactions);
		Query.SetParameter("BankAccount", BankAccount);
		Query.SetParameter("TransactionDate", TransactionDate);
		Query.SetParameter("Amount", Amount);
		Query.SetParameter("CheckNumber", CheckNumber);
		Query.SetParameter("Description", Description);
	EndIf;
	
	If Query.Execute().Select().Count() > 0 Then
		
		TextMessage = StringFunctionsClientServer.SubstituteParametersInString(NStr("en = 'The transaction: Date %1, Amount %2, Check # %3, Description %4 - is duplicate!'"), Format(TransactionDate, "DLF=D"), Amount, CheckNumber, Description);
		CommonUseClientServer.MessageToUser(TextMessage);
		Return True;
		
	Else
		Return False;
	EndIf;	
	
EndFunction
