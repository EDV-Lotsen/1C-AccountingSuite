
Function DwollaToken(token)
	
	Constants.dwolla_access_token.Set(token);
		
	R = GeneralFunctions.EncodeToPercentStr(token);
	HTTPRequest = New HTTPRequest("/oauth/rest/fundingsources/?oauth_token=" + R);

	SSLConnection = New OpenSSLSecureConnection();

	HTTPConnection = New HTTPConnection("www.dwolla.com",,,,,,SSLConnection);
	Result = HTTPConnection.Get(HTTPRequest);
	ResultBody = Result.GetBodyAsString();
	ResultJSON = InternetConnectionClientServer.DecodeJSON(ResultBody);
	ResultToParse = ResultJSON.Response;
	Rows = ResultToParse.Count();
	For i = 0 to Rows - 1 Do
		Row = ResultToParse[i];
		If Row.Type = "Checking" Then
			Constants.dwolla_funding_source.Set(Row.Id);	
		EndIf;
	EndDo;

	
	
EndFunction

Function StripeWebhook(invoicenum,invoicedate,invoiceamount,jsonin)
	
	SetPrivilegedMode(True);
		
	InvoiceInfo = Documents.SalesInvoice.GetRef(New UUID(invoicenum));
	InvoiceInfo.GetObject().Paid = True;
	InvoiceInfo.GetObject().Write();
	
	//Balance Query
	Query = New Query;
	Query.Text = "SELECT
	             |	ISNULL(GeneralJournalBalance.AmountBalance, 0) AS Balance,
	             |	ISNULL(GeneralJournalBalance.AmountRCBalance, 0) AS BalanceRC
	             |FROM
	             |	Document.SalesInvoice AS DocumentSalesInvoice
	             |		LEFT JOIN AccountingRegister.GeneralJournal.Balance(, , , ExtDimension2 REFS Document.SalesInvoice) AS GeneralJournalBalance
	             |		ON (GeneralJournalBalance.Account = DocumentSalesInvoice.ARAccount)
	             |			AND (GeneralJournalBalance.ExtDimension1 = DocumentSalesInvoice.Company)
	             |			AND (GeneralJournalBalance.ExtDimension2 = DocumentSalesInvoice.Ref)
	             |WHERE
	             |	DocumentSalesInvoice.Ref = &SalesInvoice";
	Query.SetParameter("SalesInvoice", InvoiceInfo.Ref);
	
	QueryResult = Query.Execute().Unload();

	
	NewCashReceipt = Documents.CashReceipt.CreateDocument();
	NewCashReceipt.Company = InvoiceInfo.Company;
	NewCashReceipt.Date = CurrentDate();
	//NewCashReceipt.CompanyCode = InvoiceInfo.CompanyCode;
	NewCashReceipt.Currency = InvoiceInfo.Currency;
	NewCashReceipt.DepositType = "1";
	NewCashReceipt.DocumentTotalRC = QueryResult[0].BalanceRC;
	NewCashReceipt.CashPayment = QueryResult[0].BalanceRC;
	NewCashReceipt.ARAccount = InvoiceInfo.ARAccount;
	NewLine = NewCashReceipt.LineItems.Add();
	NewLine.Document = InvoiceInfo.Ref;
	NewLine.Payment = QueryResult[0].BalanceRC;
	
	//NewALAN - stripe tab to be populated
	ParsedJSON = InternetConnectionClientServer.DecodeJSON(jsonin);
	NewCashReceipt.StripeID = ParsedJSON.data.object.id;
	NewCashReceipt.StripeCardName = ParsedJSON.data.object.card.name;
	NewCashReceipt.StripeAmount =  0.01 * ParsedJSON.data.object.amount;
	Try
		NewCashReceipt.StripeCardType = ParsedJSON.data.object.card.brand;
	Except
		NewCashReceipt.StripeCardType = ParsedJSON.data.object.card.type;
	EndTry;
	NewCashReceipt.StripeCreated =  ParsedJSON.data.object.created;
	NewCashReceipt.StripeLast4 =  ParsedJSON.data.object.card.last4;
	        
	NewCashReceipt.Write(DocumentWriteMode.Posting);
	
	SetPrivilegedMode(False);
	
	//Notification = InformationRegisters.Notifications.CreateRecordManager();
	//Notification.Period      = CurrentDate();
	//Notification.Subject     = StringFunctionsClientServer.SubstituteParametersInString(
			                           //NStr("en = 'Invoice %1 has been paid the amount of $%2.'"), invoicenum,invoiceamount);
	//Notification.Description = "This invoice has just been paid through your emailed invoice. A cash receipt has been made for this payment.";
	//Notification.Object      = RecurringDocument;
	//Notification.Write(False);
	
EndFunction

Function SubscriptionPlan(plantype, custId)
	// Insert handler code.
	
	If plantype = "1569" Then
		Constants.SubStatus.Set("Entrepreneur");
	Elsif plantype = "1570" Then
		Constants.SubStatus.Set("Small Business");
	Elsif plantype = "1571" Then
		Constants.SubStatus.Set("Premium");
	Else
		Constants.SubStatus.Set("Freeish");
	Endif;
	
	Constants.StripeSubCustID.Set(custId);
	Return "success";
	
EndFunction

Function StripeTransfer(chargegross, chargefee, descrip, objectid)
	
	If Constants.stripe_transfer.Get() = True Then
		
		totalamount = (Number(chargegross)/100) - (Number(chargefee)/100);

		NewDeposit = Documents.Deposit.CreateDocument();
		NewDeposit.Date = CurrentDate();
		NewDeposit.DocumentTotalRC = totalamount;
		NewDeposit.BankAccount = Constants.BankAccount.Get();

		invoicesplit = StringFunctionsClientServer.SplitStringIntoSubstringArray(descrip,",",True);
		LineCount = 0;
		For Each DescriptItem in invoicesplit Do
			
			DescripBreakDown = StringFunctionsClientServer.SplitStringIntoSubstringArray(DescriptItem," ",True);
			
			If DescripBreakDown[1] = "Invoice" Then
				
				Query = New Query("SELECT
								  |	SalesInvoice.Ref
								  |FROM
								  |	Document.SalesInvoice AS SalesInvoice
								  |WHERE
								  |	SalesInvoice.Number = &Number");
				Query.SetParameter("Number", DescripBreakDOwn[2]);
				Result = Query.Execute().Unload();
				
				If Result[0] <> NULL Then
					
					Query = New Query("SELECT
									  |	CashReceipt.Ref
									  |FROM
									  |	Document.CashReceipt AS CashReceipt
									  |WHERE
									  |	CashReceipt.LineItems.Document = &Doc");
					Query.SetParameter("Doc", Result[0].Ref);
					Result = Query.Execute().Unload();
					
					If Result[0] <> NULL Then
						LineCount = LineCount + 1;
						NewLine = NewDeposit.LineItems.Add();
						NewLine.Document = Result[0].Ref;
						NewLine.Customer = Result[0].Ref.Company;
						NewLine.DocumentTotal = Result[0].Ref.DocumentTotal;
						NewLine.DocumentTotalRC = Result[0].Ref.DocumentTotalRC;
						NewLine.Currency = Result[0].Ref.Currency;
						NewLine.LineNumber = LineCount;
						NewLine.Payment = True;				
										
					EndIf;
						

						
				EndIf;
				
			EndIf;
			
		EndDo;

		NewExpense = NewDeposit.Accounts.Add();
		NewExpense.Account = Constants.ExpenseAccount.Get();
		NewExpense.Amount = (Number(chargefee)/100);
		NewExpense.LineNumber = 1;

		NewDeposit.Write(DocumentWriteMode.Posting);

		
	Else
	EndIf
	
EndFunction
