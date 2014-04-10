// The procedure performs document posting
//
Procedure Posting(Cancel, Mode)
	
	// create a value table for posting amounts
	
	PostingDatasetIncome = New ValueTable();
	PostingDatasetIncome.Columns.Add("IncomeAccount");
	PostingDatasetIncome.Columns.Add("AmountRC");
	
	PostingDatasetCOGS = New ValueTable();
	PostingDatasetCOGS.Columns.Add("COGSAccount");
	PostingDatasetCOGS.Columns.Add("AmountRC");	
	
	PostingDatasetInvOrExp = New ValueTable();
	PostingDatasetInvOrExp.Columns.Add("InvOrExpAccount");
    PostingDatasetInvOrExp.Columns.Add("AmountRC");
	
	//PostingDatasetVAT = New ValueTable();
	//PostingDatasetVAT.Columns.Add("VATAccount");
	//PostingDatasetVAT.Columns.Add("AmountRC");
	
	//AllowNegativeInventory = Constants.AllowNegativeInventory.Get();
	
	RegisterRecords.CashFlowData.Write = True;
	
	For Each CurRowLineItems In LineItems Do
		
		// writing CashFlowData

		Record = RegisterRecords.CashFlowData.Add();
		Record.RecordType = AccumulationRecordType.Expense;
		Record.Period = Date;
		Record.Company = Company;
		Record.Document = Ref;
		Record.Account = CurRowLineItems.Product.IncomeAccount;
		//Record.Account = CurRowLineItems.Product.InventoryOrExpenseAccount;
		//Record.CashFlowSection = CurRowLineItems.Product.InventoryOrExpenseAccount.CashFlowSection;
		Record.AmountRC = CurRowLineItems.LineTotal * ExchangeRate;
		//Record.PaymentMethod = PaymentMethod;
		
		Record = RegisterRecords.CashFlowData.Add();
		Record.RecordType = AccumulationRecordType.Receipt;
		Record.Period = Date;
		Record.Company = Company;
		Record.Document = Ref;
		Record.Account = CurRowLineItems.Product.IncomeAccount;
		//Record.Account = CurRowLineItems.Product.InventoryOrExpenseAccount;
		//Record.CashFlowSection = CurRowLineItems.Product.InventoryOrExpenseAccount.CashFlowSection;
		Record.AmountRC = CurRowLineItems.LineTotal * ExchangeRate;
		//Record.PaymentMethod = PaymentMethod;

		// end writing CashFlowData

				
		If CurRowLineItems.Product.Type = Enums.InventoryTypes.Inventory Then
						
			// check inventory balances and cancel if not sufficient
			
			CurrentBalance = 0;
								
			Query = New Query("SELECT
			                  |	InventoryJrnlBalance.QtyBalance
			                  |FROM
			                  |	AccumulationRegister.InventoryJrnl.Balance AS InventoryJrnlBalance
			                  |WHERE
			                  |	InventoryJrnlBalance.Product = &Product
			                  |	AND InventoryJrnlBalance.Location = &Location");
			Query.SetParameter("Product", CurRowLineItems.Product);
			Query.SetParameter("Location", Location);
			QueryResult = Query.Execute();
			
			If QueryResult.IsEmpty() Then
			Else
				Dataset = QueryResult.Unload();
				CurrentBalance = Dataset[0][0];
			EndIf;	
				
			If CurRowLineItems.Quantity > CurrentBalance Then
				CurProd = CurRowLineItems.Product;
				Message = New UserMessage();
				Message.Text= StringFunctionsClientServer.SubstituteParametersInString(
				NStr("en='Insufficient balance on %1';de='Nicht ausreichende Bilanz'"),CurProd);
				Message.Message();
				//If NOT AllowNegativeInventory Then
					Cancel = True;
	                Return;
				//EndIf;
			EndIf;
			
			// inventory journal update and costing procedure
			
			RegisterRecords.InventoryJrnl.Write = True;
			
			ItemCost = 0;
			
			If CurRowLineItems.Product.CostingMethod = Enums.InventoryCosting.WeightedAverage Then
				
				AverageCost = 0;
				
				Query = New Query("SELECT
				                  |	SUM(InventoryJrnlBalance.QtyBalance) AS QtyBalance,
				                  |	SUM(InventoryJrnlBalance.AmountBalance) AS AmountBalance
				                  |FROM
				                  |	AccumulationRegister.InventoryJrnl.Balance(,Location = &Location) AS InventoryJrnlBalance
				                  |WHERE
				                  |	InventoryJrnlBalance.Product = &Product");
				Query.SetParameter("Product", CurRowLineItems.Product);
				Query.SetParameter("Location", Location);
				QueryResult = Query.Execute().Unload();
				If  QueryResult.Count() > 0
				And (Not QueryResult[0].QtyBalance = Null)
				And (Not QueryResult[0].AmountBalance = Null)
				And QueryResult[0].QtyBalance > 0
				Then
					AverageCost = QueryResult[0].AmountBalance / QueryResult[0].QtyBalance;
				EndIf;
								
				Record = RegisterRecords.InventoryJrnl.Add();
				Record.RecordType = AccumulationRecordType.Expense;
				Record.Period = Date;
				Record.Product = CurRowLineItems.Product;
				Record.Location = Location;
				Record.Qty = CurRowLineItems.Quantity;				
				ItemCost = CurRowLineItems.Quantity * AverageCost;
				Record.Amount = ItemCost;
				
			EndIf;
			
			//If CurRowLineItems.Product.CostingMethod = Enums.InventoryCosting.LIFO OR
				If CurRowLineItems.Product.CostingMethod = Enums.InventoryCosting.FIFO Then
				
				ItemQty = CurRowLineItems.Quantity;
				
				//If CurRowLineItems.Product.CostingMethod = Enums.InventoryCosting.LIFO Then
				//	Sorting = "DESC";
				//Else
					Sorting = "ASC";
				//EndIf;
				
				Query = New Query("SELECT
				                  |	InventoryJrnlBalance.QtyBalance,
				                  |	InventoryJrnlBalance.AmountBalance,
				                  |	InventoryJrnlBalance.Layer,
				                  |	InventoryJrnlBalance.Layer.Date AS LayerDate
				                  |FROM
				                  |	AccumulationRegister.InventoryJrnl.Balance AS InventoryJrnlBalance
				                  |WHERE
				                  |	InventoryJrnlBalance.Product = &Product
				                  |	AND InventoryJrnlBalance.Location = &Location
				                  |
				                  |ORDER BY
				                  |	LayerDate " + Sorting + "");
				Query.SetParameter("Product", CurRowLineItems.Product);
				Query.SetParameter("Location", Location);
				Selection = Query.Execute().Select();
				
				While Selection.Next() Do
					If ItemQty > 0 Then
						
						Record = RegisterRecords.InventoryJrnl.Add();
						Record.RecordType = AccumulationRecordType.Expense;
						Record.Period = Date;
						Record.Product = CurRowLineItems.Product;
						Record.Location = Location;
						Record.Layer = Selection.Layer;
						If ItemQty >= Selection.QtyBalance Then
							ItemCost = ItemCost + Selection.AmountBalance;
							Record.Qty = Selection.QtyBalance;
							Record.Amount = Selection.AmountBalance;
							ItemQty = ItemQty - Record.Qty;
						Else
							ItemCost = ItemCost + ItemQty * (Selection.AmountBalance / Selection.QtyBalance);
							Record.Qty = ItemQty;
							Record.Amount = ItemQty * (Selection.AmountBalance / Selection.QtyBalance);
							ItemQty = 0;
						EndIf;
					EndIf;
				EndDo;
				
				
			EndIf;

			// adding to the posting dataset
			
			PostingLineCOGS = PostingDatasetCOGS.Add();
			PostingLineCOGS.COGSAccount = CurRowLineItems.Product.COGSAccount;
			PostingLineCOGS.AmountRC = ItemCost;
			
			PostingLineInvOrExp = PostingDatasetInvOrExp.Add();
			PostingLineInvOrExp.InvOrExpAccount = CurRowLineItems.Product.InventoryOrExpenseAccount;
			PostingLineInvOrExp.AmountRC = ItemCost;
			
		EndIf;	
		
		
		// fill in the account posting value table with amounts
		
		PostingLineIncome = PostingDatasetIncome.Add();
		PostingLineIncome.IncomeAccount = CurRowLineItems.Product.IncomeAccount;
		//If PriceIncludesVAT Then
		//	PostingLineIncome.AmountRC = (CurRowLineItems.LineTotal - CurRowLineItems.VAT) * ExchangeRate;
		//Else
			PostingLineIncome.AmountRC = CurRowLineItems.LineTotal * ExchangeRate;
		//EndIf;	
		
		//If CurRowLineItems.VAT > 0 Then
		//	
		//	PostingLineVAT = PostingDatasetVAT.Add();
		//	PostingLineVAT.VATAccount = VAT_FL.VATAccount(CurRowLineItems.VATCode, "Sales");
		//	PostingLineVAT.AmountRC = CurRowLineItems.VAT * ExchangeRate;
		//					
		//EndIf;
		
	EndDo;
	
	// GL posting
	
	RegisterRecords.GeneralJournal.Write = True;	
	
	If DepositType = "1" Then 
	 
		Record = RegisterRecords.GeneralJournal.AddDebit();
		Record.Account = Constants.UndepositedFundsAccount.Get();
		Record.Period = Date;
		Record.AmountRC = DocumentTotal * ExchangeRate;
				 
	EndIf;

	If DepositType = "2" Then
	
		Record = RegisterRecords.GeneralJournal.AddDebit();
		Record.Account = BankAccount;
		Record.Currency = BankAccount.Currency;
		Record.Period = Date;
		If Currency = BankAccount.Currency Then
			Record.Amount = DocumentTotal;
		Else
			Record.Amount = DocumentTotal * ExchangeRate;
		EndIf;
		Record.AmountRC = DocumentTotal * ExchangeRate;
	
	EndIf;
	
	If DiscountRC <> 0 Then			
		Record = RegisterRecords.GeneralJournal.AddDebit();
		DiscountsAccount = Constants.DiscountsAccount.Get();
		If DiscountsAccount = ChartsOfAccounts.ChartOfAccounts.EmptyRef() Then
			Record.Account = Constants.ExpenseAccount.Get();
		Else
			Record.Account = DiscountsAccount;
		EndIf;
		Record.Period = Date;
		Record.AmountRC = DiscountRC * -1 * ExchangeRate;				
	EndIf;
	
	If ShippingRC <> 0 Then			
		Record = RegisterRecords.GeneralJournal.AddCredit();
		ShippingExpenseAccount = Constants.ShippingExpenseAccount.Get();
		If ShippingExpenseAccount = ChartsOfAccounts.ChartOfAccounts.EmptyRef() Then
			Record.Account = Constants.IncomeAccount.Get();
		Else
			Record.Account = ShippingExpenseAccount;
		EndIf;
		Record.Period = Date;
		Record.AmountRC = ShippingRC * ExchangeRate;				
	EndIf;
	
	PostingDatasetIncome.GroupBy("IncomeAccount", "AmountRC");
	NoOfPostingRows = PostingDatasetIncome.Count();
	For i = 0 To NoOfPostingRows - 1 Do			
		Record = RegisterRecords.GeneralJournal.AddCredit();
		Record.Account = PostingDatasetIncome[i][0];
		Record.Period = Date;
		Record.AmountRC = PostingDatasetIncome[i][1];				
	EndDo;

	PostingDatasetCOGS.GroupBy("COGSAccount", "AmountRC");
	NoOfPostingRows = PostingDatasetCOGS.Count();
	For i = 0 To NoOfPostingRows - 1 Do			
		Record = RegisterRecords.GeneralJournal.AddDebit();
		Record.Account = PostingDatasetCOGS[i][0];
		Record.Period = Date;
		Record.AmountRC = PostingDatasetCOGS[i][1];				
	EndDo;

	PostingDatasetInvOrExp.GroupBy("InvOrExpAccount", "AmountRC");
	NoOfPostingRows = PostingDatasetInvOrExp.Count();
	For i = 0 To NoOfPostingRows - 1 Do			
		Record = RegisterRecords.GeneralJournal.AddCredit();
		Record.Account = PostingDatasetInvOrExp[i][0];
		Record.Period = Date;
		Record.AmountRC = PostingDatasetInvOrExp[i][1];				
	EndDo;
			
	If SalesTaxRC > 0 Then
		Record = RegisterRecords.GeneralJournal.AddCredit();
		Record.Account = Constants.TaxPayableAccount.Get();
		Record.Period = Date;
		Record.AmountRC = SalesTaxRC * ExchangeRate;
	EndIf;		
	
	//PostingDatasetVAT.GroupBy("VATAccount", "AmountRC");
	//NoOfPostingRows = PostingDatasetVAT.Count();
	//For i = 0 To NoOfPostingRows - 1 Do
	//	Record = RegisterRecords.GeneralJournal.AddCredit();
	//	Record.Account = PostingDatasetVAT[i][0];
	//	Record.Period = Date;
	//	Record.AmountRC = PostingDatasetVAT[i][1];	
	//EndDo;
	
	// Writing bank reconciliation data
	
	//Records = InformationRegisters.TransactionReconciliation.CreateRecordSet();
	//Records.Filter.Document.Set(Ref);
	//Records.Filter.Account.Set(BankAccount);
	//Record = Records.Add();
	//Record.Document = Ref;
	//Record.Account = BankAccount;
	//Record.Reconciled = False;
	//Record.Amount = DocumentTotalRC;
	//Records.Write();
	
	Records = InformationRegisters.TransactionReconciliation.CreateRecordSet();
	Records.Filter.Document.Set(Ref);
	Records.Read();
	If Records.Count() = 0 Then
		Record = Records.Add();
		Record.Document = Ref;
		Record.Account = BankAccount;
		Record.Reconciled = False;
		Record.Amount = DocumentTotalRC;		
	Else
		Records[0].Account = BankAccount;
		Records[0].Amount = DocumentTotalRC;
	EndIf;
	Records.Write();

	
	RegisterRecords.ProjectData.Write = True;	
	For Each CurRowLineItems In LineItems Do
		Record = RegisterRecords.ProjectData.Add();
		Record.RecordType = AccumulationRecordType.Receipt;
		Record.Period = Date;
		Record.Project = CurRowLineItems.Project;
		Record.Amount = CurRowLineItems.LineTotal;
	EndDo;
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	// Deleting bank reconciliation data
	
	Records = InformationRegisters.TransactionReconciliation.CreateRecordManager();
	Records.Document = Ref;
	Records.Account = BankAccount;
	Records.Read();
	Records.Delete();

EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	// for webhooks
	If NewObject = True Then
		NewObject = False;
	Else
		If Ref = Documents.CashSale.EmptyRef() Then
			NewObject = True;
		EndIf;
	EndIf;

EndProcedure

Procedure OnWrite(Cancel)
	
	companies_webhook = Constants.cash_sales_webhook.Get();
	
	If NOT companies_webhook = "" Then
		
		//double_slash = Find(companies_webhook, "//");
		//
		//companies_webhook = Right(companies_webhook,StrLen(companies_webhook) - double_slash - 1);
		//
		//first_slash = Find(companies_webhook, "/");
		//webhook_address = Left(companies_webhook,first_slash - 1);
		//webhook_resource = Right(companies_webhook,StrLen(companies_webhook) - first_slash + 1); 		
		
		WebhookMap = New Map(); 
		WebhookMap.Insert("apisecretkey",Constants.APISecretKey.Get());
		WebhookMap.Insert("resource","cashsales");
		If NewObject = True Then
			WebhookMap.Insert("action","create");
		Else
			WebhookMap.Insert("action","update");
		EndIf;
		WebhookMap.Insert("api_code", String(Ref.UUID()));
		
		WebhookParams = New Array();
		WebhookParams.Add(Constants.cash_sales_webhook.Get());
		WebhookParams.Add(WebhookMap);
		LongActions.ExecuteInBackground("GeneralFunctions.SendWebhook", WebhookParams);
	
	EndIf;

EndProcedure

Procedure BeforeDelete(Cancel)
	
	companies_webhook = Constants.cash_sales_webhook.Get();
	
	If NOT companies_webhook = "" Then
		
		//double_slash = Find(companies_webhook, "//");
		//
		//companies_webhook = Right(companies_webhook,StrLen(companies_webhook) - double_slash - 1);
		//
		//first_slash = Find(companies_webhook, "/");
		//webhook_address = Left(companies_webhook,first_slash - 1);
		//webhook_resource = Right(companies_webhook,StrLen(companies_webhook) - first_slash + 1); 		
		
		WebhookMap = New Map(); 
		WebhookMap.Insert("apisecretkey",Constants.APISecretKey.Get());
		WebhookMap.Insert("resource","cashsales");
		WebhookMap.Insert("action","delete");
		WebhookMap.Insert("api_code",String(Ref.UUID()));
		
		WebhookParams = New Array();
		WebhookParams.Add(Constants.cash_sales_webhook.Get());
		WebhookParams.Add(WebhookMap);	
		LongActions.ExecuteInBackground("GeneralFunctions.SendWebhook", WebhookParams);	
	
	EndIf;
	
	TRRecordset = InformationRegisters.TransactionReconciliation.CreateRecordSet();
	TRRecordset.Filter.Document.Set(ThisObject.Ref);
	TRRecordset.Write(True);
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	// Set the doc's number if it's new (Rupasov)
	If ThisObject.IsNew() Then ThisObject.SetNewNumber() EndIf;

EndProcedure


