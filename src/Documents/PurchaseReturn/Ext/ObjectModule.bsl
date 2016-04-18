
////////////////////////////////////////////////////////////////////////////////
// Purchase return: Object module
//------------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
#Region EVENT_HANDLERS

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
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
			                                    Ref, PointInTime(), Company, Location, LineItems.Unload(, "Product, Unit, QtyUM"));
			Documents.PurchaseReturn.PrepareDataBeforeWrite(AdditionalProperties, DocumentParameters, Cancel);
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	// Forced assign the new document number.
	If ThisObject.IsNew() And Not ValueIsFilled(ThisObject.Number) Then ThisObject.SetNewNumber(); EndIf;
	
	// Filling new document or filling on the base of another document.
	If FillingData = Undefined Then
		// Filling of the new created document with default values.
		Currency         = Constants.DefaultCurrency.Get();
		ExchangeRate     = GeneralFunctions.GetExchangeRate(Date, Currency);
		Location         = GeneralFunctions.GetDefaultLocation();
		
	Else
		// Generate on the base of purchase invoice document.
		If (TypeOf(FillingData) = Type("DocumentRef.PurchaseInvoice")) Then
			
			// -> CODE REVIEW
			ParentDocument  = FillingData.Ref;
			Company         = FillingData.Company;
			Currency        = FillingData.Currency;
			ExchangeRate    = FillingData.ExchangeRate;
			Location        = FillingData.LocationActual;
			APAccount       = FillingData.APAccount;
			DocumentTotal   = FillingData.DocumentTotal;
			DocumentTotalRC = FillingData.DocumentTotalRC;
			
			For Each CurRowLineItems In FillingData.LineItems Do
				NewRow = LineItems.Add();
				FillPropertyValues(NewRow, CurRowLineItems);
			EndDo;
			// <- CODE REVIEW
			
		EndIf;
	EndIf;
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	If ThisObject.IsNew() Then ThisObject.SetNewNumber(); EndIf;
	
	// Clear manual adjustment attribute.
	ManualAdjustment = False;
	
EndProcedure

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
	Documents.PurchaseReturn.PrepareDataStructuresForPosting(Ref, AdditionalProperties, RegisterRecords);
	
	// 5. Fill register records with document's postings.
	DocumentPosting.FillRecordSets(AdditionalProperties, RegisterRecords, Cancel);
	
	// 6. Write document postings to register.
	DocumentPosting.WriteRecordSets(AdditionalProperties, RegisterRecords);
	
	// 7. Check register blanaces according to document's changes.
	DocumentPosting.CheckPostingResults(AdditionalProperties, RegisterRecords, Cancel);
	
	// 8. Clear used temporary document data.
	DocumentPosting.ClearDataStructuresAfterPosting(AdditionalProperties);
	
	
	// -> CODE REVIEW	
	
	PostingDatasetInvOrExp = New ValueTable();
	PostingDatasetInvOrExp.Columns.Add("InvOrExpAccount");
	PostingDatasetInvOrExp.Columns.Add("AmountRC");
		
	// Request actual time point.
	PointInTime = PointInTime();
	
	For Each CurRowLineItems In LineItems Do
		
		If CurRowLineItems.Product.Type = Enums.InventoryTypes.Inventory Then
			
			// Inventory journal update and costing procedure.
			
			ItemCost = 0;
			
			If CurRowLineItems.Product.CostingMethod = Enums.InventoryCosting.WeightedAverage Then
				
				AverageCost = 0;
				
				Query = New Query("SELECT
				                  |	InventoryJournalBalance.QuantityBalance AS QuantityBalance,
				                  |	InventoryJournalBalance.AmountBalance   AS AmountBalance
				                  |FROM
				                  |	AccumulationRegister.InventoryJournal.Balance(&PointInTime, Product = &Product) AS InventoryJournalBalance");
				Query.SetParameter("PointInTime", PointInTime);
				Query.SetParameter("Product", CurRowLineItems.Product);
				QueryResult = Query.Execute().Unload();
				If  QueryResult.Count() > 0
				And (Not QueryResult[0].QuantityBalance = Null)
				And (Not QueryResult[0].AmountBalance = Null)
				And QueryResult[0].QuantityBalance > 0
				Then
					AverageCost = QueryResult[0].AmountBalance / QueryResult[0].QuantityBalance;
				EndIf;
				
				ItemCost = CurRowLineItems.QtyUM * AverageCost;
				
			EndIf;
			
			If CurRowLineItems.Product.CostingMethod = Enums.InventoryCosting.FIFO Then
				
				ItemQuantity = CurRowLineItems.QtyUM;
				
				Query = New Query("SELECT
				                  |	InventoryJournalBalance.QuantityBalance,
				                  |	InventoryJournalBalance.AmountBalance,
				                  |	InventoryJournalBalance.Layer,
				                  |	InventoryJournalBalance.Layer.Date AS LayerDate
				                  |FROM
				                  |	AccumulationRegister.InventoryJournal.Balance(&PointInTime, Product = &Product AND Location = &Location) AS InventoryJournalBalance
				                  |ORDER BY
				                  |	LayerDate ASC");
				Query.SetParameter("PointInTime", PointInTime);
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
			PostingLineInvOrExp = PostingDatasetInvOrExp.Add();
			PostingLineInvOrExp.InvOrExpAccount = CurRowLineItems.Product.InventoryOrExpenseAccount;
			PostingLineInvOrExp.AmountRC = ItemCost;
			
		EndIf;
	EndDo;
	
	// Fill in the account posting value table with amounts.
	
	PostingDataset = New ValueTable();
	PostingDataset.Columns.Add("Account");
	PostingDataset.Columns.Add("AmountRC");
	
	For Each CurRowLineItems in LineItems Do
		
		If CurRowLineItems.Product.Type = Enums.InventoryTypes.NonInventory Then
			
			PostingLine = PostingDataset.Add();
			PostingLine.Account = CurRowLineItems.Product.InventoryOrExpenseAccount;
			LineAmount = CurRowLineItems.LineTotal * ExchangeRate; 
			PostingLine.AmountRC = LineAmount;
			
		EndIf;
		
	EndDo;
	
	// GL posting
	
	RegisterRecords.GeneralJournal.Write = True;
	
	TotalCredit = 0; 
	
	PostingDatasetInvOrExp.GroupBy("InvOrExpAccount", "AmountRC");
	NoOfPostingRows = PostingDatasetInvOrExp.Count();
	For i = 0 To NoOfPostingRows - 1 Do
		Record = RegisterRecords.GeneralJournal.AddCredit();
		Record.Account = PostingDatasetInvOrExp[i][0];
		Record.Period = Date;
		Record.AmountRC = PostingDatasetInvOrExp[i][1];
		
		//--//GJ++
		ReconciledDocumentsServerCall.AddRecordForGeneralJournalAnalyticsDimensions(RegisterRecords, Record, Null, Null, Company);
		//--//GJ--
		
		TotalCredit = TotalCredit + PostingDatasetInvOrExp[i][1];
	EndDo;
	
	PostingDataset.GroupBy("Account", "AmountRC");
	NoOfPostingRows = PostingDataset.Count();
	For i = 0 To NoOfPostingRows - 1 Do
		Record = RegisterRecords.GeneralJournal.AddCredit();
		Record.Account = PostingDataset[i][0];
		Record.Period = Date;
		Record.AmountRC = PostingDataset[i][1];
		
		//--//GJ++
		ReconciledDocumentsServerCall.AddRecordForGeneralJournalAnalyticsDimensions(RegisterRecords, Record, Null, Null, Company);
		//--//GJ--
		
		TotalCredit = TotalCredit + PostingDataset[i][1];
	EndDo;
	
	Record = RegisterRecords.GeneralJournal.AddDebit();
	Record.Account = APAccount;
	Record.Period = Date;
	Record.Amount = DocumentTotal;
	Record.Currency = Currency;
	Record.AmountRC = DocumentTotal * ExchangeRate;
	Record.ExtDimensions[ChartsOfCharacteristicTypes.Dimensions.Company] = Company;
	Record.ExtDimensions[ChartsOfCharacteristicTypes.Dimensions.Document] = Ref;
	
	//--//GJ++
	ReconciledDocumentsServerCall.AddRecordForGeneralJournalAnalyticsDimensions(RegisterRecords, Record, Null, Null, Company);
	//--//GJ--
	
	VarianceAmount = 0;
	VarianceAmount = DocumentTotal * ExchangeRate - TotalCredit;
	
	If VarianceAmount > 0 Then
		Record = RegisterRecords.GeneralJournal.AddCredit();
		Record.Account = Constants.ExpenseAccount.Get();
		Record.Period = Date;
		Record.AmountRC = VarianceAmount;
		Record.Memo = "Purchase Return variance";
		
		//--//GJ++
		ReconciledDocumentsServerCall.AddRecordForGeneralJournalAnalyticsDimensions(RegisterRecords, Record, Null, Null, Company);
		//--//GJ--
	ElsIf VarianceAmount < 0 Then
		Record = RegisterRecords.GeneralJournal.AddDebit();
		Record.Account = Constants.ExpenseAccount.Get();
		Record.Period = Date;
		Record.AmountRC = -VarianceAmount;
		Record.Memo = "Purchase Return variance";
		
		//--//GJ++
		ReconciledDocumentsServerCall.AddRecordForGeneralJournalAnalyticsDimensions(RegisterRecords, Record, Null, Null, Company);
		//--//GJ--
	EndIf;
	
	// <- CODE REVIEW
	
	//CASH BASIS--------------------------------------------------------------------------------------------------
	//------------------------------------------------------------------------------------------------------------
	
	RegisterRecords.CashFlowData.Write = True;
	
	TablesList = New Structure;
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", Ref);
	Query.SetParameter("GeneralJournalAnalyticsDimensions", RegisterRecords.GeneralJournalAnalyticsDimensions.Unload());
	
	Query.Text = Query_GeneralJournalAnalyticsDimensions_Transactions(TablesList) +
	
				 Query_CashFlowData_Accounts_Positive(TablesList) +
				 Query_CashFlowData_Accounts_Positive_Amount(TablesList) +
				 Query_CashFlowData_Accounts_Negative(TablesList) +
				 Query_CashFlowData_Accounts_Negative_Amount(TablesList) +
				 Query_CashFlowData_Accounts_Paid(TablesList) +
				 Query_CashFlowData_Accounts_Paid_Amount(TablesList) +
				 Query_CashFlowData_Accounts_Paid_Transactions(TablesList) +
				 Query_CashFlowData_Accounts_Paid_Transactions_Corrected(TablesList) +
				 Query_CashFlowData_Accounts_Paid_Transactions_Amount(TablesList) +
				 Query_CashFlowData_CB_Accounts(TablesList) +
				 Query_CashFlowData_CB_Accounts_Amount(TablesList) +
				 Query_CashFlowData(TablesList);
				 
	If Not IsBlankString(Query.Text) Then
		
		QueryResult = Query.ExecuteBatch();
		
		For Each DocumentTable In TablesList Do
			ResultTable = QueryResult[DocumentTable.Value].Unload();
			If Not DocumentPosting.IsTemporaryTable(ResultTable) And DocumentTable.Key = "Table_CashFlowData" Then
				RegisterRecords.CashFlowData.Load(ResultTable);	
			EndIf;
		EndDo;
		
	EndIf;
	
	Query.TempTablesManager.Close();
	
	//------------------------------------------------------------------------------------------------------------
	//CASH BASIS (end)--------------------------------------------------------------------------------------------
	
EndProcedure

Procedure UndoPosting(Cancel)	
	
	// 1. Common posting clearing / deactivate manual ajusted postings.
	DocumentPosting.PrepareRecordSetsForPostingClearing(AdditionalProperties, RegisterRecords);
	
	// 2. Skip manually adjusted documents.
	If ManualAdjustment Then
		Return;
	EndIf;
	
	// 3. Create structures with document data to pass it on the server.
	DocumentPosting.PrepareDataStructuresBeforePosting(AdditionalProperties);
	
	// 4. Collect document data, required for posing clearing, and fill created structure.
	Documents.PurchaseReturn.PrepareDataStructuresForPostingClearing(Ref, AdditionalProperties, RegisterRecords);
	
	// 5. Write document postings to register.
	DocumentPosting.WriteRecordSets(AdditionalProperties, RegisterRecords);
	
	// 6. Check register blanaces according to document's changes.
	DocumentPosting.CheckPostingResults(AdditionalProperties, RegisterRecords, Cancel);
	
	// 7. Clear used temporary document data.
	DocumentPosting.ClearDataStructuresAfterPosting(AdditionalProperties);
	
EndProcedure

Procedure OnSetNewNumber(StandardProcessing, Prefix)
	
	StandardProcessing = False;
	
	Numerator = Catalogs.DocumentNumbering.PurchaseReturn;
	NextNumber = GeneralFunctions.Increment(Numerator.Number);
	
	While Documents.PurchaseReturn.FindByNumber(NextNumber) <> Documents.PurchaseReturn.EmptyRef() And NextNumber <> "" Do
		ObjectNumerator = Numerator.GetObject();
		ObjectNumerator.Number = NextNumber;
		ObjectNumerator.Write();
		
		NextNumber = GeneralFunctions.Increment(NextNumber);
	EndDo;
	
	ThisObject.Number = NextNumber; 

EndProcedure

//CASH BASIS--------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------------------

// Query for document data.
Function Query_GeneralJournalAnalyticsDimensions_Transactions(TablesList)
	
	TablesList.Insert("Table_GeneralJournalAnalyticsDimensions_Transactions", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // Transactions
	// ------------------------------------------------------
	// Standard attributes
	|	Transaction.Recorder                  AS Recorder,
	|	Transaction.Period                    AS Period,
	|	Transaction.LineNumber                AS LineNumber,
	|	Transaction.RecordType                AS RecordType,
	|	Transaction.Active                    AS Active,
	// ------------------------------------------------------
	// Accounting attributes
	|	Transaction.Account                   AS Account,
	// ------------------------------------------------------
	// Dimensions
	|	Transaction.Company                   AS Company,
	|	Transaction.Class                     AS Class,
	|	Transaction.Project                   AS Project,
	// ------------------------------------------------------
	// Resources
	|	Transaction.AmountRC                  AS AmountRC,
	// ------------------------------------------------------
	// Attributes
	|	Transaction.JournalEntryIntNum        AS JournalEntryIntNum,
	|	Transaction.JournalEntryMainRec       AS JournalEntryMainRec
	// ------------------------------------------------------
	|INTO Table_GeneralJournalAnalyticsDimensions_Transactions 
	|FROM
	|	&GeneralJournalAnalyticsDimensions AS Transaction";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_CashFlowData_Accounts_Positive(TablesList)
	
	// Add CashFlowData inventory or expenses accounts (positive) table to document structure.
	TablesList.Insert("Table_CashFlowData_Accounts_Positive", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // Positive accounts selection
	// ------------------------------------------------------
	// Resources
	|	AccountsTab.AmountRC                                 AS AmountRC
	// ------------------------------------------------------
	|INTO
	|	Table_CashFlowData_Accounts_Positive
	|FROM
	|	Table_GeneralJournalAnalyticsDimensions_Transactions AS AccountsTab
	|WHERE 
	|	AccountsTab.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		AND AccountsTab.Account.AccountType <> VALUE(Enum.AccountTypes.AccountsReceivable)
	|		AND AccountsTab.Account.AccountType <> VALUE(Enum.AccountTypes.AccountsPayable)";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_CashFlowData_Accounts_Positive_Amount(TablesList)
	
	// Add CashFlowData inventory or expenses accounts (positive amount) table to document structure.
	TablesList.Insert("Table_CashFlowData_Accounts_Positive_Amount", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // Positive accounts selection
	// ------------------------------------------------------
	// Resources
	|	SUM(Accounts.AmountRC)               AS AmountRC
	// ------------------------------------------------------
	|INTO
	|	Table_CashFlowData_Accounts_Positive_Amount
	|FROM
	|	Table_CashFlowData_Accounts_Positive AS Accounts";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_CashFlowData_Accounts_Negative(TablesList)
	
	// Add CashFlowData inventory or expenses accounts (negative) table to document structure.
	TablesList.Insert("Table_CashFlowData_Accounts_Negative", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // Negative accounts selection
	// Accounting attributes
	|	AccountsTab.Account                                  AS Account,
	// ------------------------------------------------------
	// Dimensions
	|	AccountsTab.Class                                    AS Class,
	|	AccountsTab.Project                                  AS Project,
	// ------------------------------------------------------
	// Resources
	|	AccountsTab.AmountRC                                 AS AmountRC
	// ------------------------------------------------------
	|INTO
	|	Table_CashFlowData_Accounts_Negative
	|FROM
	|	Table_GeneralJournalAnalyticsDimensions_Transactions AS AccountsTab
	|WHERE 
	|	AccountsTab.RecordType = VALUE(AccumulationRecordType.Expense)
	|		AND AccountsTab.Account.AccountType <> VALUE(Enum.AccountTypes.AccountsReceivable)
	|		AND AccountsTab.Account.AccountType <> VALUE(Enum.AccountTypes.AccountsPayable)";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_CashFlowData_Accounts_Negative_Amount(TablesList)
	
	// Add CashFlowData inventory or expenses accounts (negative amount) table to document structure.
	TablesList.Insert("Table_CashFlowData_Accounts_Negative_Amount", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // Negative accounts selection
	// ------------------------------------------------------
	// Resources
	|	SUM(Accounts.AmountRC)               AS AmountRC
	// ------------------------------------------------------
	|INTO
	|	Table_CashFlowData_Accounts_Negative_Amount
	|FROM
	|	Table_CashFlowData_Accounts_Negative AS Accounts";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_CashFlowData_Accounts_Paid(TablesList)
	
	// Add CashFlowData inventory or expenses accounts (Paid) table to document structure.
	TablesList.Insert("Table_CashFlowData_Accounts_Paid", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // Rec: Negative Inventory and Expenses (Expense)
	// ------------------------------------------------------
	// Dimensions
	|	NegativePaid.Account                 AS Account,
	// ------------------------------------------------------
	// Dimensions
	|	NegativePaid.Class                   AS Class,
	|	NegativePaid.Project                 AS Project,
	// ------------------------------------------------------
	// Resources
	|	CAST( // Format(Positive_Amount * (Negative * ExchangeRate) / Negative_Amount, ""ND=17; NFD=2"")
	|		Positive_Amount.AmountRC * NegativePaid.AmountRC / Negative_Amount.AmountRC
	|		AS NUMBER (17, 2))               AS AmountRC
	// ------------------------------------------------------
	|INTO
	|	Table_CashFlowData_Accounts_Paid	
	|FROM
	|	Table_CashFlowData_Accounts_Negative AS NegativePaid 
	|	LEFT JOIN Table_CashFlowData_Accounts_Negative_Amount AS Negative_Amount
	|		ON TRUE
	|	LEFT JOIN Table_CashFlowData_Accounts_Positive_Amount AS Positive_Amount
	|		ON TRUE
	|WHERE
	|	// Amount <> 0
	|	Positive_Amount.AmountRC <> 0
	|		AND Negative_Amount.AmountRC <> 0
	|		AND NegativePaid.AmountRC <> 0";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_CashFlowData_Accounts_Paid_Amount(TablesList)
	
	// Add CashFlowData inventory or expenses accounts (Paid amount) table to document structure.
	TablesList.Insert("Table_CashFlowData_Accounts_Paid_Amount", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // Rec: Negative Inventory and Expenses (Expense)
	// ------------------------------------------------------
	// Resources
	|	SUM(Paid.AmountRC)      AS AmountRC
	// ------------------------------------------------------
	|INTO
	|	Table_CashFlowData_Accounts_Paid_Amount	
	|FROM
	|	Table_CashFlowData_Accounts_Paid AS Paid";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_CashFlowData_Accounts_Paid_Transactions(TablesList)
	
	// Add CashFlowData_Accounts_Paid_Transactions table to document structure.
	TablesList.Insert("Table_CashFlowData_Accounts_Paid_Transactions", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // Paid Transactions
	// ------------------------------------------------------
	// Accounting attributes
	|	PaidTransaction.Account               AS Account,
	// ------------------------------------------------------
	// Dimensions
	|	PaidTransaction.Class                 AS Class,
	|	PaidTransaction.Project               AS Project,
	// ------------------------------------------------------
	// Resources
	|	PaidTransaction.AmountRC              AS AmountRC
	// ------------------------------------------------------
	|INTO Table_CashFlowData_Accounts_Paid_Transactions
	|FROM
	|	Table_CashFlowData_Accounts_Paid AS PaidTransaction
	|WHERE
	|	PaidTransaction.AmountRC <> 0
	|		AND (PaidTransaction.Account.AccountType = VALUE(Enum.AccountTypes.Income)
	|			OR PaidTransaction.Account.AccountType = VALUE(Enum.AccountTypes.CostOfSales)
	|			OR PaidTransaction.Account.AccountType = VALUE(Enum.AccountTypes.Expense)
	|			OR PaidTransaction.Account.AccountType = VALUE(Enum.AccountTypes.OtherIncome)
	|			OR PaidTransaction.Account.AccountType = VALUE(Enum.AccountTypes.OtherExpense)
	|			OR PaidTransaction.Account.AccountType = VALUE(Enum.AccountTypes.IncomeTaxExpense))
	|
	|UNION ALL
	|
	|SELECT TOP 1 // Paid Transactions (difference)
	// ------------------------------------------------------
	// Accounting attributes
	|	PaidTransaction.Account                AS Account,
	// ------------------------------------------------------
	// Dimensions
	|	PaidTransaction.Class                  AS Class,
	|	PaidTransaction.Project                AS Project,
	// ------------------------------------------------------
	// Resources
	|	Positive_Amount.AmountRC - Paid_Amount.AmountRC
	|								           AS AmountRC
	// ------------------------------------------------------
	|FROM
	|	Table_CashFlowData_Accounts_Paid AS PaidTransaction 
	|	LEFT JOIN Table_CashFlowData_Accounts_Positive_Amount AS Positive_Amount
	|		ON TRUE
	|	LEFT JOIN Table_CashFlowData_Accounts_Paid_Amount AS Paid_Amount
	|		ON TRUE
	|WHERE
	|	PaidTransaction.AmountRC <> 0
	|		AND (PaidTransaction.Account.AccountType = VALUE(Enum.AccountTypes.Income)
	|			OR PaidTransaction.Account.AccountType = VALUE(Enum.AccountTypes.CostOfSales)
	|			OR PaidTransaction.Account.AccountType = VALUE(Enum.AccountTypes.Expense)
	|			OR PaidTransaction.Account.AccountType = VALUE(Enum.AccountTypes.OtherIncome)
	|			OR PaidTransaction.Account.AccountType = VALUE(Enum.AccountTypes.OtherExpense)
	|			OR PaidTransaction.Account.AccountType = VALUE(Enum.AccountTypes.IncomeTaxExpense))
	|		AND (Positive_Amount.AmountRC - Paid_Amount.AmountRC) <> 0";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_CashFlowData_Accounts_Paid_Transactions_Corrected(TablesList)
	
	// Add CashFlowData_Accounts_Paid_Transactions_Corrected table to document structure.
	TablesList.Insert("Table_CashFlowData_Accounts_Paid_Transactions_Corrected", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // Paid Transactions
	// ------------------------------------------------------
	// Accounting attributes
	|	PaidTransaction.Account               AS Account,
	// ------------------------------------------------------
	// Dimensions
	|	PaidTransaction.Class                 AS Class,
	|	PaidTransaction.Project               AS Project,
	// ------------------------------------------------------
	// Resources
	|	SUM(PaidTransaction.AmountRC)         AS AmountRC
	// ------------------------------------------------------
	|INTO Table_CashFlowData_Accounts_Paid_Transactions_Corrected
	|FROM
	|	Table_CashFlowData_Accounts_Paid_Transactions AS PaidTransaction
	|WHERE
	|	PaidTransaction.AmountRC <> 0
	|GROUP BY
	|	PaidTransaction.Account,
	|	PaidTransaction.Class,
	|	PaidTransaction.Project";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_CashFlowData_Accounts_Paid_Transactions_Amount(TablesList)
	
	// Add CashFlowData_Accounts_Paid_Transactions_Amount table to document structure.
	TablesList.Insert("Table_CashFlowData_Accounts_Paid_Transactions_Amount", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // Paid Transactions
	// ------------------------------------------------------
	// Resources
	|	SUM(PaidTransaction.AmountRC)         AS AmountRC
	// ------------------------------------------------------
	|INTO Table_CashFlowData_Accounts_Paid_Transactions_Amount
	|FROM
	|	Table_CashFlowData_Accounts_Paid_Transactions AS PaidTransaction
	|WHERE
	|	PaidTransaction.AmountRC <> 0";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_CashFlowData_CB_Accounts(TablesList)
	
	// Add CashFlowData CashBasis Accounts table to document structure.
	TablesList.Insert("Table_CashFlowData_CB_Accounts", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // CashBasis Accounts
	// ------------------------------------------------------
	// Resources
	|	CASE
	|		WHEN Transaction.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN Transaction.AmountRC                   
	|		ELSE Transaction.AmountRC * -1
	|	END                                                  AS AmountRC
	// ------------------------------------------------------
	|INTO
	|	Table_CashFlowData_CB_Accounts
	|FROM
	|	Table_GeneralJournalAnalyticsDimensions_Transactions AS Transaction
	|WHERE
	|	(Transaction.Account.AccountType <> VALUE(Enum.AccountTypes.AccountsReceivable)
	|		AND Transaction.Account.AccountType <> VALUE(Enum.AccountTypes.AccountsPayable)
	|		AND Transaction.Account.AccountType <> VALUE(Enum.AccountTypes.Income)
	|		AND Transaction.Account.AccountType <> VALUE(Enum.AccountTypes.CostOfSales)
	|		AND Transaction.Account.AccountType <> VALUE(Enum.AccountTypes.Expense)
	|		AND Transaction.Account.AccountType <> VALUE(Enum.AccountTypes.OtherIncome)
	|		AND Transaction.Account.AccountType <> VALUE(Enum.AccountTypes.OtherExpense)
	|		AND Transaction.Account.AccountType <> VALUE(Enum.AccountTypes.IncomeTaxExpense))
	|	OR (Transaction.Account.AccountType <> VALUE(Enum.AccountTypes.AccountsReceivable)
	|		AND Transaction.Account.AccountType <> VALUE(Enum.AccountTypes.AccountsPayable)
	|		AND Transaction.RecordType = VALUE(AccumulationRecordType.Receipt))";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_CashFlowData_CB_Accounts_Amount(TablesList)
	
	// Add CashFlowData CashBasis Accounts Amount table to document structure.
	TablesList.Insert("Table_CashFlowData_CB_Accounts_Amount", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // CashBasis Accounts
	// ------------------------------------------------------
	// Resources
	|	SUM(Transaction.AmountRC)      AS AmountRC
	// ------------------------------------------------------
	|INTO
	|	Table_CashFlowData_CB_Accounts_Amount
	|FROM
	|	Table_CashFlowData_CB_Accounts AS Transaction";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_CashFlowData(TablesList)
	
	// Add CashFlowData table to document structure.
	TablesList.Insert("Table_CashFlowData", TablesList.Count());
	
	// Collect cash flow data.
	QueryText =
	"SELECT // CashBasis Transactions 
	// ------------------------------------------------------
	// Standard attributes
	|	Transaction.Recorder                  AS Recorder,
	|	Transaction.Period                    AS Period,
	|	Transaction.LineNumber                AS LineNumber,
	|	Transaction.RecordType                AS RecordType,
	|	Transaction.Active                    AS Active,
	// ------------------------------------------------------
	// Accounting attributes
	|	Transaction.Account                   AS Account,
	// ------------------------------------------------------
	// Dimensions
	|	Transaction.Company                   AS Company,
	|	PurchaseReturn.Ref                    AS Document,
	|	NULL                                  AS SalesPerson,
	|	Transaction.Class                     AS Class,
	|	Transaction.Project                   AS Project,
	// ------------------------------------------------------
	// Resources
	|	Transaction.AmountRC                  AS AmountRC,
	// ------------------------------------------------------
	// Attributes
	|	NULL                                  AS PaymentMethod
	// ------------------------------------------------------
	|FROM
	|	Table_GeneralJournalAnalyticsDimensions_Transactions AS Transaction
	|	LEFT JOIN Document.PurchaseReturn AS PurchaseReturn
	|		ON PurchaseReturn.Ref = &Ref
	|WHERE
	|	(Transaction.Account.AccountType <> VALUE(Enum.AccountTypes.AccountsReceivable)
	|		AND Transaction.Account.AccountType <> VALUE(Enum.AccountTypes.AccountsPayable)
	|		AND Transaction.Account.AccountType <> VALUE(Enum.AccountTypes.Income)
	|		AND Transaction.Account.AccountType <> VALUE(Enum.AccountTypes.CostOfSales)
	|		AND Transaction.Account.AccountType <> VALUE(Enum.AccountTypes.Expense)
	|		AND Transaction.Account.AccountType <> VALUE(Enum.AccountTypes.OtherIncome)
	|		AND Transaction.Account.AccountType <> VALUE(Enum.AccountTypes.OtherExpense)
	|		AND Transaction.Account.AccountType <> VALUE(Enum.AccountTypes.IncomeTaxExpense))
	|	OR (Transaction.Account.AccountType <> VALUE(Enum.AccountTypes.AccountsReceivable)
	|		AND Transaction.Account.AccountType <> VALUE(Enum.AccountTypes.AccountsPayable)
	|		AND Transaction.RecordType = VALUE(AccumulationRecordType.Receipt))
	|
	|UNION ALL
	|
	|SELECT // CashBasis Transactions Accounts Payable (difference)
	// ------------------------------------------------------
	// Standard attributes
	|	PurchaseReturn.Ref                    AS Recorder,
	|	PurchaseReturn.Date                   AS Period,
	|	0                                     AS LineNumber,
	|	CASE
	|		WHEN TransactionAP.AmountRC > 0
	|			THEN VALUE(AccumulationRecordType.Expense)
	|		ELSE VALUE(AccumulationRecordType.Receipt)
	|	END                                   AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Accounting attributes
	|	PurchaseReturn.APAccount              AS Account,
	// ------------------------------------------------------
	// Dimensions
	|	PurchaseReturn.Company                AS Company,
	|	PurchaseReturn.Ref                    AS Document,
	|	NULL                                  AS SalesPerson,
	|	NULL                                  AS Class,
	|	NULL                                  AS Project,
	// ------------------------------------------------------
	// Resources
	|	CASE
	|		WHEN TransactionAP.AmountRC > 0
	|			THEN TransactionAP.AmountRC                
	|		ELSE TransactionAP.AmountRC * -1
	|	END                                   AS AmountRC,
	// ------------------------------------------------------
	// Attributes
	|	NULL                                  AS PaymentMethod
	// ------------------------------------------------------
	|FROM
	|	Table_CashFlowData_CB_Accounts_Amount AS TransactionAP
	|	LEFT JOIN Document.PurchaseReturn AS PurchaseReturn
	|		ON PurchaseReturn.Ref = &Ref
	|WHERE
	|	TransactionAP.AmountRC <> 0
	|
	|UNION ALL
	|
	|SELECT // Paid Transactions
	// ------------------------------------------------------
	// Standard attributes
	|	PurchaseReturn.Ref                    AS Recorder,
	|	PurchaseReturn.Date                   AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Accounting attributes
	|	PaidTransaction.Account               AS Account,
	// ------------------------------------------------------
	// Dimensions
	|	PurchaseReturn.Company                AS Company,
	|	PurchaseReturn.Ref                    AS Document,
	|	NULL                                  AS SalesPerson,
	|	PaidTransaction.Class                 AS Class,
	|	PaidTransaction.Project               AS Project,
	// ------------------------------------------------------
	// Resources
	|	PaidTransaction.AmountRC              AS AmountRC,
	// ------------------------------------------------------
	// Attributes
	|	NULL                                  AS PaymentMethod
	// ------------------------------------------------------
	|FROM
	|	Table_CashFlowData_Accounts_Paid_Transactions_Corrected AS PaidTransaction
	|	LEFT JOIN Document.PurchaseReturn AS PurchaseReturn
	|		ON PurchaseReturn.Ref = &Ref
	|WHERE
	|	PaidTransaction.AmountRC <> 0
	|
	|UNION ALL
	|
	|SELECT // Paid Transactions Accounts Payable (difference)
	// ------------------------------------------------------
	// Standard attributes
	|	PurchaseReturn.Ref                    AS Recorder,
	|	PurchaseReturn.Date                   AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Accounting attributes
	|	PurchaseReturn.APAccount              AS Account,
	// ------------------------------------------------------
	// Dimensions
	|	PurchaseReturn.Company                AS Company,
	|	PurchaseReturn.Ref                    AS Document,
	|	NULL                                  AS SalesPerson,
	|	NULL                                  AS Class,
	|	NULL                                  AS Project,
	// ------------------------------------------------------
	// Resources
	|	PaidTransaction.AmountRC              AS AmountRC,
	// ------------------------------------------------------
	// Attributes
	|	NULL                                  AS PaymentMethod
	// ------------------------------------------------------
	|FROM
	|	Table_CashFlowData_Accounts_Paid_Transactions_Amount AS PaidTransaction
	|	LEFT JOIN Document.PurchaseReturn AS PurchaseReturn
	|		ON PurchaseReturn.Ref = &Ref
	|WHERE
	|	PaidTransaction.AmountRC <> 0";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

//------------------------------------------------------------------------------------------------------------
//CASH BASIS (end)--------------------------------------------------------------------------------------------

#EndIf

#EndRegion
