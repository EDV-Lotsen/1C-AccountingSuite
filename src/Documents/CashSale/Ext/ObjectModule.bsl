
////////////////////////////////////////////////////////////////////////////////
// Cash sale: Object module
//------------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
#Region EVENT_HANDLERS

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

// -> CODE REVIEW
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
// <- CODE REVIEW

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	// -> CODE REVIEW
	// For webhooks.
	If NewObject = True Then
		NewObject = False;
	Else
		If Ref = Documents.CashSale.EmptyRef() Then
			NewObject = True;
		EndIf;
	EndIf;
	// <- CODE REVIEW
	
	// Document date adjustment patch (tunes the date of drafts like for the new documents).
	If  WriteMode = DocumentWriteMode.Posting And Not Posted // Posting of new or draft (saved but unposted) document.
	And BegOfDay(Date) = BegOfDay(CurrentSessionDate()) Then // Operational posting (by the current date).
		// Shift document time to the time of posting.
		Date = CurrentSessionDate();
	EndIf;
	
	// Save document parameters before posting the document.
	If WriteMode = DocumentWriteMode.Posting
	Or WriteMode = DocumentWriteMode.UndoPosting Then
		
		// Common filling of parameters.
		DocumentParameters = New Structure("Ref, Date, IsNew,   Posted, ManualAdjustment, Metadata",
		                                    Ref, Date, IsNew(), Posted, ManualAdjustment, Metadata());
		DocumentPosting.PrepareDataStructuresBeforeWrite(AdditionalProperties, DocumentParameters, Cancel, WriteMode, PostingMode);
	EndIf;
	
	// Precheck of register balances to complete filling of document posting.
	If WriteMode = DocumentWriteMode.Posting Then
		
		// Precheck of document data, calculation of temporary data, required for document posting.
		If (Not ManualAdjustment) Then
			DocumentParameters = New Structure("Ref, PointInTime,   Company, Location, LineItems",
			                                    Ref, PointInTime(), Company, Location, LineItems.Unload(, "Product, Quantity"));
			Documents.CashSale.PrepareDataBeforeWrite(AdditionalProperties, DocumentParameters, Cancel);
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	// Forced assign the new document number.
	If ThisObject.IsNew() Then ThisObject.SetNewNumber(); EndIf;
	
	// Filling new document or filling on the base of another document.
	If FillingData = Undefined Then
		// Filling of the new created document with default values.
		Currency         = Constants.DefaultCurrency.Get();
		ExchangeRate     = GeneralFunctions.GetExchangeRate(Date, Currency);
		Location         = Catalogs.Locations.MainWarehouse;
		
	Else
		// Generate on the base of another document.
		
	EndIf;
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	// Clear manual adjustment attribute.
	ManualAdjustment = False;
	
EndProcedure

// -> CODE REVIEW
Procedure OnWrite(Cancel)
	
	//companies_webhook = Constants.cash_sales_webhook.Get();
	//
	//If NOT companies_webhook = "" Then
	//	
	//	//double_slash = Find(companies_webhook, "//");
	//	//
	//	//companies_webhook = Right(companies_webhook,StrLen(companies_webhook) - double_slash - 1);
	//	//
	//	//first_slash = Find(companies_webhook, "/");
	//	//webhook_address = Left(companies_webhook,first_slash - 1);
	//	//webhook_resource = Right(companies_webhook,StrLen(companies_webhook) - first_slash + 1);
	//	
	//	WebhookMap = New Map(); 
	//	WebhookMap.Insert("apisecretkey",Constants.APISecretKey.Get());
	//	WebhookMap.Insert("resource","cashsales");
	//	If NewObject = True Then
	//		WebhookMap.Insert("action","create");
	//	Else
	//		WebhookMap.Insert("action","update");
	//	EndIf;
	//	WebhookMap.Insert("api_code", String(Ref.UUID()));
	//	
	//	WebhookParams = New Array();
	//	WebhookParams.Add(Constants.cash_sales_webhook.Get());
	//	WebhookParams.Add(WebhookMap);
	//	LongActions.ExecuteInBackground("GeneralFunctions.SendWebhook", WebhookParams);
	//	
	//EndIf;
	
EndProcedure
// <- CODE REVIEW

Procedure Posting(Cancel, Mode)
	
	// 1. Common postings clearing / reactivate manual ajusted postings.
	DocumentPosting.PrepareRecordSetsForPosting(AdditionalProperties, RegisterRecords);
	
	// 2. Skip manually adjusted documents.
	If ManualAdjustment Then
		Return;
	EndIf;
	
	// 3. Create structures with document data to pass it on the server.
	DocumentPosting.PrepareDataStructuresBeforePosting(AdditionalProperties);
	
	// 4. Collect document data, available for posing, and fill created structure.
	Documents.CashSale.PrepareDataStructuresForPosting(Ref, AdditionalProperties, RegisterRecords);
	
	// 5. Fill register records with document's postings.
	DocumentPosting.FillRecordSets(AdditionalProperties, RegisterRecords, Cancel);
	
	// 6. Write document postings to register.
	DocumentPosting.WriteRecordSets(AdditionalProperties, RegisterRecords);
	
	// 7. Check register blanaces according to document's changes.
	DocumentPosting.CheckPostingResults(AdditionalProperties, RegisterRecords, Cancel);
	
	// 8. Clear used temporary document data.
	DocumentPosting.ClearDataStructuresAfterPosting(AdditionalProperties);
	
	
	// -> CODE REVIEW
	
	// Create a value table for posting amounts.
	PostingDatasetIncome = New ValueTable();
	PostingDatasetIncome.Columns.Add("IncomeAccount");
	PostingDatasetIncome.Columns.Add("AmountRC");
	PostingDatasetIncome.Columns.Add("Class");
	PostingDatasetIncome.Columns.Add("Project");
	
	PostingDatasetCOGS = New ValueTable();
	PostingDatasetCOGS.Columns.Add("COGSAccount");
	PostingDatasetCOGS.Columns.Add("AmountRC");
	PostingDatasetCOGS.Columns.Add("Class");
	PostingDatasetCOGS.Columns.Add("Project");
	
	PostingDatasetInvOrExp = New ValueTable();
	PostingDatasetInvOrExp.Columns.Add("InvOrExpAccount");
	PostingDatasetInvOrExp.Columns.Add("AmountRC");
	
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
		Record.SalesPerson = SalesPerson;
		
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
		Record.SalesPerson = SalesPerson;

		// end writing CashFlowData

		
		If CurRowLineItems.Product.Type = Enums.InventoryTypes.Inventory Then
			
			// Inventory journal update and costing procedure.
			
			ItemCost = 0;
			
			If CurRowLineItems.Product.CostingMethod = Enums.InventoryCosting.WeightedAverage Then
				
				AverageCost = 0;
				
				Query = New Query("SELECT
				                  |	InventoryJournalBalance.QuantityBalance AS QuantityBalance,
				                  |	InventoryJournalBalance.AmountBalance   AS AmountBalance
				                  |FROM
				                  |	AccumulationRegister.InventoryJournal.Balance(, Product = &Product) AS InventoryJournalBalance");
				Query.SetParameter("Product", CurRowLineItems.Product);
				QueryResult = Query.Execute().Unload();
				If  QueryResult.Count() > 0
				And (Not QueryResult[0].QuantityBalance = Null)
				And (Not QueryResult[0].AmountBalance = Null)
				And QueryResult[0].QuantityBalance > 0
				Then
					AverageCost = QueryResult[0].AmountBalance / QueryResult[0].QuantityBalance;
				EndIf;
				
				ItemCost = CurRowLineItems.Quantity * AverageCost;
				
			EndIf;
			
			If CurRowLineItems.Product.CostingMethod = Enums.InventoryCosting.FIFO Then
				
				ItemQuantity = CurRowLineItems.Quantity;
				
				Query = New Query("SELECT
				                  |	InventoryJournalBalance.QuantityBalance,
				                  |	InventoryJournalBalance.AmountBalance,
				                  |	InventoryJournalBalance.Layer,
				                  |	InventoryJournalBalance.Layer.Date AS LayerDate
				                  |FROM
				                  |	AccumulationRegister.InventoryJournal.Balance(, Product = &Product AND Location = &Location) AS InventoryJournalBalance
				                  |ORDER BY
				                  |	LayerDate ASC");
				Query.SetParameter("Product", CurRowLineItems.Product);
				Query.SetParameter("Location", Location);
				Selection = Query.Execute().Select();
				
				While Selection.Next() Do
					If ItemQuantity > 0 Then
						If ItemQuantity >= Selection.QuantityBalance Then
							ItemCost = ItemCost + Selection.AmountBalance;
							ItemQuantity = ItemQuantity - Selection.QuantityBalance;
						Else
							ItemCost = ItemCost + ItemQuantity * (Selection.AmountBalance / Selection.QuantityBalance);
							ItemQuantity = 0;
						EndIf;
					EndIf;
				EndDo;
				
			EndIf;
			
			// Adding to the posting dataset.
			PostingLineCOGS = PostingDatasetCOGS.Add();
			PostingLineCOGS.Class = CurRowLineItems.Class;
			PostingLineCOGS.Project = CurRowLineItems.Project;
			PostingLineCOGS.COGSAccount = CurRowLineItems.Product.COGSAccount;
			PostingLineCOGS.AmountRC = ItemCost;
			
			PostingLineInvOrExp = PostingDatasetInvOrExp.Add();
			PostingLineInvOrExp.InvOrExpAccount = CurRowLineItems.Product.InventoryOrExpenseAccount;
			PostingLineInvOrExp.AmountRC = ItemCost;
			
		EndIf;
		
		// Fill in the account posting value table with amounts.
		PostingLineIncome = PostingDatasetIncome.Add();
		PostingLineIncome.Class = CurRowLineItems.Class;
		PostingLineIncome.Project = CurRowLineItems.Project;
		PostingLineIncome.IncomeAccount = CurRowLineItems.Product.IncomeAccount;
		PostingLineIncome.AmountRC = CurRowLineItems.LineTotal * ExchangeRate;
		
	EndDo;
	
	// GL posting.
	
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
	
	If Discount <> 0 Then
		Record = RegisterRecords.GeneralJournal.AddDebit();
		DiscountsAccount = Constants.DiscountsAccount.Get();
		If DiscountsAccount = ChartsOfAccounts.ChartOfAccounts.EmptyRef() Then
			Record.Account = Constants.ExpenseAccount.Get();
		Else
			Record.Account = DiscountsAccount;
		EndIf;
		Record.Period = Date;
		Record.AmountRC = Discount * -1 * ExchangeRate;
	EndIf;
	
	If Shipping <> 0 Then
		Record = RegisterRecords.GeneralJournal.AddCredit();
		ShippingExpenseAccount = Constants.ShippingExpenseAccount.Get();
		If ShippingExpenseAccount = ChartsOfAccounts.ChartOfAccounts.EmptyRef() Then
			Record.Account = Constants.IncomeAccount.Get();
		Else
			Record.Account = ShippingExpenseAccount;
		EndIf;
		Record.Period = Date;
		Record.AmountRC = Shipping * ExchangeRate;
	EndIf;
	
	//ClassData and ProjectData
	RegisterRecords.ClassData.Write = True;
	RegisterRecords.ProjectData.Write = True;
	
	//ClassData
	PostingDatasetIncomeClass = PostingDatasetIncome.Copy();
	PostingDatasetIncomeClass.GroupBy("IncomeAccount, Class", "AmountRC");
	For Each CurRowLineItems In PostingDatasetIncomeClass Do				
		Record = RegisterRecords.ClassData.Add();
		Record.RecordType = AccumulationRecordType.Receipt;
		Record.Period = Date;
		Record.Account = CurRowLineItems.IncomeAccount;
		Record.Class = CurRowLineItems.Class;
		Record.Amount = CurRowLineItems.AmountRC;
	EndDo;
	
	PostingDatasetCOGSClass = PostingDatasetCOGS.Copy();
	PostingDatasetCOGSClass.GroupBy("COGSAccount, Class", "AmountRC");
	For Each CurRowLineItems In PostingDatasetCOGSClass Do				
		Record = RegisterRecords.ClassData.Add();
		Record.RecordType = AccumulationRecordType.Expense;
		Record.Period = Date;
		Record.Account = CurRowLineItems.COGSAccount;
		Record.Class = CurRowLineItems.Class;
		Record.Amount = CurRowLineItems.AmountRC;
	EndDo;

	//ProjectData
	PostingDatasetIncomeProject = PostingDatasetIncome.Copy();
	PostingDatasetIncomeProject.GroupBy("IncomeAccount, Project", "AmountRC");
	For Each CurRowLineItems In PostingDatasetIncomeProject Do				
		Record = RegisterRecords.ProjectData.Add();
		Record.RecordType = AccumulationRecordType.Receipt;
		Record.Period = Date;
		Record.Account = CurRowLineItems.IncomeAccount;
		Record.Project = CurRowLineItems.Project;
		Record.Amount = CurRowLineItems.AmountRC;
	EndDo;
	
	PostingDatasetCOGSProject = PostingDatasetCOGS.Copy();
	PostingDatasetCOGSProject.GroupBy("COGSAccount, Project", "AmountRC");
	For Each CurRowLineItems In PostingDatasetCOGSProject Do				
		Record = RegisterRecords.ProjectData.Add();
		Record.RecordType = AccumulationRecordType.Expense;
		Record.Period = Date;
		Record.Account = CurRowLineItems.COGSAccount;
		Record.Project = CurRowLineItems.Project;
		Record.Amount = CurRowLineItems.AmountRC;
	EndDo;

	
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
	
	//If SalesTaxRC > 0 Then
	//	Record = RegisterRecords.GeneralJournal.AddCredit();
	//	Record.Account = Constants.TaxPayableAccount.Get();
	//	Record.Period = Date;
	//	Record.AmountRC = SalesTaxRC * ExchangeRate;
	//EndIf;
	
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
	
	ReconciledDocumentsServerCall.AddDocumentForReconciliation(RegisterRecords, Ref, BankAccount, Date, DocumentTotalRC);
	
	//RegisterRecords.ProjectData.Write = True;
	//For Each CurRowLineItems In LineItems Do
	//	Record = RegisterRecords.ProjectData.Add();
	//	Record.RecordType = AccumulationRecordType.Receipt;
	//	Record.Period = Date;
	//	Record.Project = CurRowLineItems.Project;
	//	Record.Amount = CurRowLineItems.LineTotal;
	//EndDo;
	
	// <- CODE REVIEW
	
	cash_url = Constants.cash_sales_webhook.Get();
	
	If NOT cash_url = "" Then
		
		WebhookMap = Webhooks.ReturnCashSaleMap(Ref);
		WebhookMap.Insert("resource","cashsales");
		If NewObject = True Then
			WebhookMap.Insert("action","create");
		Else
			WebhookMap.Insert("action","update");
		EndIf;
		WebhookMap.Insert("apisecretkey",Constants.APISecretKey.Get());
		
		WebhookParams = New Array();
		WebhookParams.Add(cash_url);
		WebhookParams.Add(WebhookMap);
		LongActions.ExecuteInBackground("GeneralFunctions.SendWebhook", WebhookParams);
	
	EndIf;
	
	email_cash_webhook = Constants.cash_webhook_email.Get();
	
	If NOT email_cash_webhook = "" Then
	//If true then			
		WebhookMap2 = Webhooks.ReturnCashSaleMap(Ref);
		WebhookMap2.Insert("resource","cashsales");
		If NewObject = True Then
			WebhookMap2.Insert("action","create");
		Else
			WebhookMap2.Insert("action","update");
		EndIf;
		WebhookMap2.Insert("apisecretkey",Constants.APISecretKey.Get());
		
		WebhookParams2 = New Array();
		WebhookParams2.Add(email_cash_webhook);
		WebhookParams2.Add(WebhookMap2);
		LongActions.ExecuteInBackground("GeneralFunctions.EmailWebhook", WebhookParams2);
		
	EndIf;
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	// -> CODE REVIEW
	
	// Deleting bank reconciliation data.
	Records = InformationRegisters.TransactionReconciliation.CreateRecordManager();
	Records.Document = Ref;
	Records.Account = BankAccount;
	Records.Read();
	Records.Delete();
	
	// <- CODE REVIEW
	
	// 1. Common posting clearing / deactivate manual ajusted postings.
	DocumentPosting.PrepareRecordSetsForPostingClearing(AdditionalProperties, RegisterRecords);
	
	// 2. Skip manually adjusted documents.
	If ManualAdjustment Then
		Return;
	EndIf;
	
	// 3. Create structures with document data to pass it on the server.
	DocumentPosting.PrepareDataStructuresBeforePosting(AdditionalProperties);
	
	// 4. Collect document data, required for posing clearing, and fill created structure.
	Documents.CashSale.PrepareDataStructuresForPostingClearing(Ref, AdditionalProperties, RegisterRecords);
	
	// 5. Write document postings to register.
	DocumentPosting.WriteRecordSets(AdditionalProperties, RegisterRecords);
	
	// 6. Check register blanaces according to document's changes.
	DocumentPosting.CheckPostingResults(AdditionalProperties, RegisterRecords, Cancel);
	
	// 7. Clear used temporary document data.
	DocumentPosting.ClearDataStructuresAfterPosting(AdditionalProperties);
	
EndProcedure

#EndIf

#EndRegion

