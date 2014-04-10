
////////////////////////////////////////////////////////////////////////////////
// Sales Invoice: Object module
//------------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
#Region EVENT_HANDLERS

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

// -> CODE REVIEW
Procedure BeforeDelete(Cancel)
	
	companies_webhook = Constants.sales_invoices_webhook.Get();
	
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
		WebhookMap.Insert("resource","salesinvoices");
		WebhookMap.Insert("action","delete");
		WebhookMap.Insert("api_code",String(Ref.UUID()));
		
		WebhookParams = New Array();
		WebhookParams.Add(Constants.sales_invoices_webhook.Get());
		WebhookParams.Add(WebhookMap);
		LongActions.ExecuteInBackground("GeneralFunctions.SendWebhook", WebhookParams);
		
	EndIf;
	
EndProcedure
// <- CODE REVIEW

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	// -> CODE REVIEW
	// For webhooks.
	If NewObject = True Then
		NewObject = False;
	Else
		If Ref = Documents.SalesInvoice.EmptyRef() Then
			NewObject = True;
		EndIf;
	EndIf;
	// <- CODE REVIEW
	
	// Save document parameters before posting the document.
	If WriteMode = DocumentWriteMode.Posting
	Or WriteMode = DocumentWriteMode.UndoPosting Then
		
		// Save custom document parameters.
		Orders = LineItems.UnloadColumn("Order");
		GeneralFunctions.NormalizeArray(Orders);
		
		// Common filling of parameters.
		DocumentParameters = New Structure("Ref, Date, IsNew,   Posted, ManualAdjustment, Metadata,   Orders",
		                                    Ref, Date, IsNew(), Posted, ManualAdjustment, Metadata(), Orders);
		DocumentPosting.PrepareDataStructuresBeforeWrite(AdditionalProperties, DocumentParameters, Cancel, WriteMode, PostingMode);
	EndIf;
	
	// Precheck of register balances to complete filling of document posting
	If WriteMode = DocumentWriteMode.Posting Then
		
		// Precheck of document data, calculation of temporary data, required for document posting
		If (Not ManualAdjustment) And (Orders.Count() > 0) Then
			DocumentParameters = New Structure("Ref, PointInTime,   Company, LineItems",
			                                    Ref, PointInTime(), Company, LineItems.Unload(, "Order, Product, Location, DeliveryDate, Project, Class, Quantity"));
			Documents.SalesInvoice.PrepareDataBeforeWrite(AdditionalProperties, DocumentParameters, Cancel);
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	// -> CODE REVIEW
	If Discount > 0 Then
		// ??? !!!
		Message = New UserMessage();
		Message.Text=NStr("en='A discount should be a negative number'");
		//Message.Field = "Object.Description";
		Message.Message();
		Cancel = True;
		Return;
	EndIf;
	// <- CODE REVIEW
	
	
	// Create items filter by non-empty orders.
	FilledOrders = GeneralFunctions.InvertCollectionFilter(LineItems, LineItems.FindRows(New Structure("Order", Documents.SalesOrder.EmptyRef())));
	
	// Check doubles in items (to be sure of proper orders placement).
	GeneralFunctions.CheckDoubleItems(Ref, LineItems, "Product, Order, Location, DeliveryDate, Project, Class, LineNumber", FilledOrders, Cancel);
	
	// Check proper closing of order items by the invoice items.
	If Not Cancel Then
		Documents.SalesInvoice.CheckOrderQuantity(Ref, Date, Company, LineItems, FilledOrders, Cancel);
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
		ARAccount        = Currency.DefaultARAccount;
		LocationActual   = Catalogs.Locations.MainWarehouse;
		
	Else
		// Generate on the base of Sales order & Shipment.
		Cancel = False; TabularSectionData = Undefined;
		
		// 0. Custom check of sales order for interactive generate of sales invoice on the base of sales order.
		If (TypeOf(FillingData) = Type("DocumentRef.SalesOrder"))
		And Not Documents.SalesInvoice.CheckStatusOfSalesOrder(Ref, FillingData) Then
			Cancel = True;
			Return;
		EndIf;
		
		// 1. Common filling of parameters.
		DocumentParameters = New Structure("Ref, Date, Metadata",
		                                    Ref, ?(ValueIsFilled(Date), Date, CurrentSessionDate()), Metadata());
		DocumentFilling.PrepareDataStructuresBeforeFilling(AdditionalProperties, DocumentParameters, FillingData, Cancel);
		
		// 2. Cancel filling on failed data.
		If Cancel Then
			Return;
		EndIf;
		
		// 3. Collect document data, available for filling, and fill created structure.
		Documents.SalesInvoice.PrepareDataStructuresForFilling(Ref, AdditionalProperties);
		
		// 4. Check collected data.
		DocumentFilling.CheckDataStructuresOnFilling(AdditionalProperties, Cancel);
		
		// 5. Fill document fields.
		If Not Cancel Then
			// Fill "draft" values to attributes (all including non-critical fields will be filled).
			FillPropertyValues(ThisObject, AdditionalProperties.Filling.FillingTables.Table_Attributes[0]);
			
			// Fill checked unique values to attributes (critical fields will be filled).
			FillPropertyValues(ThisObject, AdditionalProperties.Filling.FillingTables.Table_Check[0]);
			
			// Fill line items.
			For Each TabularSection In AdditionalProperties.Metadata.TabularSections Do
				If AdditionalProperties.Filling.FillingTables.Property("Table_" + TabularSection.Name, TabularSectionData) Then
					ThisObject[TabularSection.Name].Load(TabularSectionData);
				EndIf;
			EndDo;
		EndIf;
		
		// 6. Clear used temporary document data.
		DocumentFilling.ClearDataStructuresAfterFilling(AdditionalProperties);
	EndIf;
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	// Clear manual ajustment attribute.
	ManualAdjustment = False;
	
EndProcedure

// -> CODE REVIEW
Procedure OnWrite(Cancel)
	
	//companies_webhook = Constants.sales_invoices_webhook.Get();
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
	//	WebhookMap.Insert("resource","salesinvoices");
	//	If NewObject = True Then
	//		WebhookMap.Insert("action","create");
	//	Else
	//		WebhookMap.Insert("action","update");
	//	EndIf;
	//	WebhookMap.Insert("api_code",String(Ref.UUID()));
	//	
	//	WebhookParams = New Array();
	//	WebhookParams.Add(Constants.sales_invoices_webhook.Get());
	//	WebhookParams.Add(WebhookMap);
	//	LongActions.ExecuteInBackground("GeneralFunctions.SendWebhook", WebhookParams);
	//	
	//EndIf;
	
EndProcedure
// <- CODE REVIEW

Procedure Posting(Cancel, PostingMode)
	
	// 1. Common postings clearing / reactivate manual ajusted postings.
	DocumentPosting.PrepareRecordSetsForPosting(AdditionalProperties, RegisterRecords);
	
	// 2. Skip manually adjusted documents.
	If ManualAdjustment Then
		Return;
	EndIf;
	
	// 3. Create structures with document data to pass it on the server.
	DocumentPosting.PrepareDataStructuresBeforePosting(AdditionalProperties);
	
	// 4. Collect document data, available for posing, and fill created structure.
	Documents.SalesInvoice.PrepareDataStructuresForPosting(Ref, AdditionalProperties, RegisterRecords);
	
	// 5. Fill register records with document's postings.
	DocumentPosting.FillRecordSets(AdditionalProperties, RegisterRecords, Cancel);
	
	// 6. Write document postings to register.
	DocumentPosting.WriteRecordSets(AdditionalProperties, RegisterRecords);
	
	// 7. Check register blanaces according to document's changes.
	DocumentPosting.CheckPostingResults(AdditionalProperties, RegisterRecords, Cancel);
	
	// 8. Clear used temporary document data.
	DocumentPosting.ClearDataStructuresAfterPosting(AdditionalProperties);
	
// -> CODE REVIEW
	IncomeBooking = True;
	
	If BegBal Then
		
		Reg = AccountingRegisters.GeneralJournal.CreateRecordSet();
		Reg.Filter.Recorder.Set(Ref);
		Reg.Clear();
		RegLine = Reg.AddDebit();
		RegLine.Account = ARAccount;
		RegLine.Period = Date;
		If GetFunctionalOption("MultiCurrency") Then
			RegLine.Amount = DocumentTotal;
		Else
			RegLine.Amount = DocumentTotalRC;
		EndIf;
		RegLine.AmountRC = DocumentTotalRC;
		RegLine.Currency = Currency;
		RegLine.ExtDimensions[ChartsOfCharacteristicTypes.Dimensions.Company] = Company;
		RegLine.ExtDimensions[ChartsOfCharacteristicTypes.Dimensions.Document] = Ref;
		Reg.Write();
		
		Return;
		
	EndIf;
	
	RegisterRecords.InventoryJrnl.Write = True;
	RegisterRecords.CashFlowData.Write = True;
	
	If IncomeBooking Then
		
		// Create a value table for posting amounts.
		PostingDatasetIncome = New ValueTable();
		PostingDatasetIncome.Columns.Add("IncomeAccount");
		PostingDatasetIncome.Columns.Add("Class");
		PostingDatasetIncome.Columns.Add("AmountRC");
		
		PostingDatasetCOGS = New ValueTable();
		PostingDatasetCOGS.Columns.Add("COGSAccount");
		PostingDatasetCOGS.Columns.Add("Class");
		PostingDatasetCOGS.Columns.Add("AmountRC");	
		
		PostingDatasetInvOrExp = New ValueTable();
		PostingDatasetInvOrExp.Columns.Add("InvOrExpAccount");
		PostingDatasetInvOrExp.Columns.Add("AmountRC");
		
		For Each CurRowLineItems In LineItems Do
						
			If CurRowLineItems.Product.Type = Enums.InventoryTypes.Inventory Then
				
				// Check inventory balances and cancel if not sufficient.
				CurrentBalance = 0;
									
				Query = New Query("SELECT
				                  |	InventoryJrnlBalance.QtyBalance
				                  |FROM
				                  |	AccumulationRegister.InventoryJrnl.Balance(, Product = &Product AND Location = &Location) AS InventoryJrnlBalance");
				Query.SetParameter("Product", CurRowLineItems.Product);
				Query.SetParameter("Location", CurRowLineItems.LocationActual);
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
				
				// Inventory journal update and costing procedure.
				ItemCost = 0;
				
				If CurRowLineItems.Product.CostingMethod = Enums.InventoryCosting.WeightedAverage Then
					
					AverageCost = 0;
					
					Query = New Query("SELECT
					                  |	InventoryJrnlBalance.QtyBalance    AS QtyBalance,
					                  |	InventoryJrnlBalance.AmountBalance AS AmountBalance
					                  |FROM
					                  |	AccumulationRegister.InventoryJrnl.Balance(, Product = &Product AND Location = &Location) AS InventoryJrnlBalance");
					Query.SetParameter("Product", CurRowLineItems.Product);
					Query.SetParameter("Location", CurRowLineItems.LocationActual);
					QueryResult = Query.Execute().Unload();
					If  QueryResult.Count() > 0    // If  QueryResult.Rows.Count() > 0
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
					Record.Location = CurRowLineItems.LocationActual;
					Record.Qty = CurRowLineItems.Quantity;
					ItemCost = CurRowLineItems.Quantity * AverageCost;
					Record.Amount = ItemCost;
					
				EndIf;
				
				//If CurRowLineItems.Product.CostingMethod = Enums.InventoryCosting.LIFO OR
					If CurRowLineItems.Product.CostingMethod = Enums.InventoryCosting.FIFO Then
					
					ItemQty = CurRowLineItems.Quantity;
					
					//If CurRowLineItems.Product.CostingMethod = Enums.InventoryCosting.LIFO Then
						//Sorting = "DESC";
					//Else
						Sorting = "ASC";
					//EndIf;
					
					Query = New Query("SELECT
					                  |	InventoryJrnlBalance.QtyBalance,
					                  |	InventoryJrnlBalance.AmountBalance,
					                  |	InventoryJrnlBalance.Layer,
					                  |	InventoryJrnlBalance.Layer.Date AS LayerDate
					                  |FROM
					                  |	AccumulationRegister.InventoryJrnl.Balance(, Product = &Product AND Location = &Location) AS InventoryJrnlBalance
					                  |ORDER BY
					                  |	LayerDate " + Sorting + "");
					Query.SetParameter("Product", CurRowLineItems.Product);
					Query.SetParameter("Location", CurRowLineItems.LocationActual);
					Selection = Query.Execute().Select();
					
					While Selection.Next() Do
						If ItemQty > 0 Then
							
							Record = RegisterRecords.InventoryJrnl.Add();
							Record.RecordType = AccumulationRecordType.Expense;
							Record.Period = Date;
							Record.Product = CurRowLineItems.Product;
							Record.Location = CurRowLineItems.LocationActual;
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
				
				// Adding to the posting dataset.
				PostingLineCOGS = PostingDatasetCOGS.Add();
				PostingLineCOGS.COGSAccount = CurRowLineItems.Product.COGSAccount;
				PostingLineCOGS.Class = CurRowLineItems.Class;
				PostingLineCOGS.AmountRC = ItemCost;
				
				PostingLineInvOrExp = PostingDatasetInvOrExp.Add();
				PostingLineInvOrExp.InvOrExpAccount = CurRowLineItems.Product.InventoryOrExpenseAccount;
				PostingLineInvOrExp.AmountRC = ItemCost;
				
			EndIf;
			
			// Fill in the account posting value table with amounts.
			PostingLineIncome = PostingDatasetIncome.Add();
			PostingLineIncome.IncomeAccount = CurRowLineItems.Product.IncomeAccount;
			PostingLineIncome.Class = CurRowLineItems.Class;
			PostingLineIncome.AmountRC = CurRowLineItems.LineTotal * ExchangeRate;
			
		EndDo;
		
	EndIf;
	
	If IncomeBooking Then
		
		// GL posting
		RegisterRecords.GeneralJournal.Write = True;	
		
		Record = RegisterRecords.GeneralJournal.AddDebit();
		Record.Account = ARAccount;
		Record.Period = Date;
		Record.Currency = Currency;
		Record.Amount = DocumentTotal;
		Record.AmountRC = DocumentTotal * ExchangeRate;
		Record.ExtDimensions[ChartsOfCharacteristicTypes.Dimensions.Company] = Company;
		Record.ExtDimensions[ChartsOfCharacteristicTypes.Dimensions.Document] = Ref;
		
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
				
			Record = RegisterRecords.CashFlowData.Add();
			Record.RecordType = AccumulationRecordType.Expense;
			Record.Period = Date;
			Record.Company = Company;
			Record.Document = Ref;
			If DiscountsAccount = ChartsOfAccounts.ChartOfAccounts.EmptyRef() Then
				Record.Account = Constants.ExpenseAccount.Get();
			Else
				Record.Account = DiscountsAccount;
			EndIf;
			//Record.Account = CurRowLineItems.Product.InventoryOrExpenseAccount;
			//Record.CashFlowSection = CurRowLineItems.Product.InventoryOrExpenseAccount.CashFlowSection;
			Record.AmountRC = (Discount * -1 * ExchangeRate) * -1;
			//Record.PaymentMethod = PaymentMethod;
			Record.SalesPerson = SalesPerson;
			
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
			
			Record = RegisterRecords.CashFlowData.Add();
			Record.RecordType = AccumulationRecordType.Expense;
			Record.Period = Date;
			Record.Company = Company;
			Record.Document = Ref;
			ShippingExpenseAccount = Constants.ShippingExpenseAccount.Get();
			If ShippingExpenseAccount = ChartsOfAccounts.ChartOfAccounts.EmptyRef() Then
				Record.Account = Constants.IncomeAccount.Get();
			Else
				Record.Account = ShippingExpenseAccount;
			EndIf;
			Record.AmountRC = Shipping * ExchangeRate;
			Record.SalesPerson = SalesPerson;
			
		EndIf;
		
		PostingClassesIncome = PostingDatasetIncome.Copy();
		PostingClassesCOGS	= PostingDatasetCOGS.Copy();
		
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
		
		If SalesTax > 0 Then
			Record = RegisterRecords.GeneralJournal.AddCredit();
			Record.Account = Constants.TaxPayableAccount.Get();
			Record.Period = Date;
			Record.AmountRC = SalesTax * ExchangeRate;
		EndIf;
		
	EndIf;
	
	// Writing ProjectData.
	
	RegisterRecords.ProjectData.Write = True;
	RegisterRecords.ClassData.Write = True;
	For Each CurRowLineItems In LineItems Do
		Record = RegisterRecords.ProjectData.Add();
		Record.RecordType = AccumulationRecordType.Receipt;
		Record.Period = Date;
		Record.Project = CurRowLineItems.Project;
		Record.Amount = CurRowLineItems.LineTotal;
	EndDo;
	
	// End writing ProjectData.
	
	// Writing CashFlowData
	For Each CurRowLineItems in LineItems Do	
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
	EndDo;
	
	// add sales tax - needs to be in the Tax Payment document?
	// add shipping
	// add discount
	
	// End writing CashFlowData

	
	// Writing Class data.
	PostingClassesIncome.GroupBy("IncomeAccount, Class", "AmountRC");
	PostingClassesCOGS.GroupBy("COGSAccount, Class", "AmountRC");	
	
	// Income by Class
	For Each ClassesIncomeLine In PostingClassesIncome Do
		Record = RegisterRecords.ClassData.Add();
		Record.RecordType = AccumulationRecordType.Receipt;
		Record.Period = Date;
		Record.Account = ClassesIncomeLine.IncomeAccount;
		Record.Class = ClassesIncomeLine.Class;
		Record.Amount = ClassesIncomeLine.AmountRC;
	EndDo;
	
	// COGS by Class.
	For Each ClassesCOGSLine In PostingClassesCOGS Do
		Record = RegisterRecords.ClassData.Add();
		Record.RecordType = AccumulationRecordType.Expense;
		Record.Period = Date;
		Record.Account = ClassesCOGSLine.COGSAccount;
		Record.Class = ClassesCOGSLine.Class;
		Record.Amount = ClassesCOGSLine.AmountRC;
	EndDo;
	// End writing Class data.
	
	RegisterRecords.OrderTransactions.Write = True;
	For Each CurRowLineItems In LineItems Do
		If NOT CurRowLineItems.Order.IsEmpty() Then
			Record = RegisterRecords.OrderTransactions.Add();
			Record.RecordType = AccumulationRecordType.Expense;
			Record.Period = Date;
			Record.Order = CurRowLineItems.Order;
			Record.Amount = CurRowLineItems.LineTotal;
		EndIf;
	EndDo;
	
	// <- CODE REVIEW
	
	invoice_url_webhook = Constants.sales_invoices_webhook.Get();
	
	If NOT invoice_url_webhook = "" Then
		
		WebhookMap = Webhooks.ReturnSalesInvoiceMap(Ref);
		WebhookMap.Insert("resource","salesinvoices");
		If NewObject = True Then
			WebhookMap.Insert("action","create");
		Else
			WebhookMap.Insert("action","update");
		EndIf;
		WebhookMap.Insert("apisecretkey",Constants.APISecretKey.Get());
		
		WebhookParams = New Array();
		WebhookParams.Add(Constants.sales_invoices_webhook.Get());
		WebhookParams.Add(WebhookMap);
		LongActions.ExecuteInBackground("GeneralFunctions.SendWebhook", WebhookParams);
		
	EndIf;
	
	email_invoice_webhook = Constants.invoice_webhook_email.Get();
	
	If NOT email_invoice_webhook = "" Then
	//If true then			
		WebhookMap2 = Webhooks.ReturnSalesInvoiceMap(Ref);
		WebhookMap2.Insert("resource","salesinvoices");
		If NewObject = True Then
			WebhookMap2.Insert("action","create");
		Else
			WebhookMap2.Insert("action","update");
		EndIf;
		WebhookMap2.Insert("apisecretkey",Constants.APISecretKey.Get());
		
		WebhookParams2 = New Array();
		WebhookParams2.Add(Constants.invoice_webhook_email.Get());
		WebhookParams2.Add(WebhookMap2);
		LongActions.ExecuteInBackground("GeneralFunctions.EmailWebhook", WebhookParams2);
		
	EndIf;
	
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
	Documents.SalesInvoice.PrepareDataStructuresForPostingClearing(Ref, AdditionalProperties, RegisterRecords);
	
	// 5. Write document postings to register.
	DocumentPosting.WriteRecordSets(AdditionalProperties, RegisterRecords);
	
	// 6. Check register blanaces according to document's changes.
	DocumentPosting.CheckPostingResults(AdditionalProperties, RegisterRecords, Cancel);
	
	// 7. Clear used temporary document data.
	DocumentPosting.ClearDataStructuresAfterPosting(AdditionalProperties);
	
EndProcedure

#EndIf

#EndRegion
