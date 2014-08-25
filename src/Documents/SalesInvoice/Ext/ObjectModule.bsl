
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
	
	// Document date adjustment patch (tunes the date of drafts like for the new documents).
	If  WriteMode = DocumentWriteMode.Posting And Not Posted // Posting of new or draft (saved but unposted) document.
	And BegOfDay(Date) = BegOfDay(CurrentSessionDate()) Then // Operational posting (by the current date).
		// Shift document time to the time of posting.
		Date = CurrentSessionDate();
	EndIf;
	
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
	
	// Precheck of register balances to complete filling of document posting.
	If WriteMode = DocumentWriteMode.Posting Then
		
		// Precheck of document data, calculation of temporary data, required for document posting.
		If (Not ManualAdjustment) Then
			DocumentParameters = New Structure("Ref, PointInTime,   Company, LineItems",
			                                    Ref, PointInTime(), Company, LineItems.Unload(, "Order, Product, Unit, Location, LocationActual, DeliveryDate, Project, Class, QtyUM"));
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
	GeneralFunctions.CheckDoubleItems(Ref, LineItems, "Product, Unit, Order, Location, DeliveryDate, Project, Class, LineNumber", FilledOrders, Cancel);
	
	// Check proper closing of order items by the invoice items.
	If Not Cancel Then
		Documents.SalesInvoice.CheckOrderQuantity(Ref, Date, Company, LineItems, FilledOrders, Cancel);
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
		ARAccount        = Currency.DefaultARAccount;
		LocationActual   = Catalogs.Locations.MainWarehouse;
		
	Else
		
		//Quote
		If TypeOf(FillingData) = Type("DocumentRef.Quote") Then
			
			If Not Documents.Quote.IsOpen(FillingData) Then
				Cancel = True;
				Return;	
			EndIf;
			
			//Fill attributes
			FillPropertyValues(ThisObject, FillingData, "Company, RefNum, ShipTo, BillTo, ConfirmTo, SalesPerson, Project,
			|Class, DropshipCompany, DropshipShipTo, DropshipConfirmTo, DropshipRefNum, Currency, ExchangeRate, SalesTaxRate,
			|DiscountIsTaxable, DiscountPercent, TaxableSubtotal, DocumentTotalRC, LineSubtotal, Discount, SalesTax, Shipping,
			|DocumentTotal, SubTotal, SalesTaxRC, Terms"); 
			
			Date               = CurrentSessionDate(); 
			BaseDocument       = FillingData; 
			LocationActual     = FillingData.Location; 
			DeliveryDateActual = FillingData.DeliveryDate;
			ARAccount          = Currency.DefaultARAccount;
			DueDate            = ?(Not Terms.IsEmpty(), Date + Terms.Days * 60*60*24, '00010101');
			EmailNote          = Constants.SalesInvoiceFooter.Get(); 
			
			//Fill "line items"
			ThisObject.LineItems.Load(FillingData.LineItems.Unload());
			
			//Fill additional fields in "line items"
			For Each Line In ThisObject.LineItems Do
				Line.LocationActual = Line.Location;
				Line.DeliveryDateActual = Line.DeliveryDate;
			EndDo;
			
			//Fill "Sales tax across agencies"
			ThisObject.SalesTaxAcrossAgencies.Load(FillingData.SalesTaxAcrossAgencies.Unload());
			
			Return;
			
		EndIf;
		//End Quote
		
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
	
	If ThisObject.IsNew() Then ThisObject.SetNewNumber(); EndIf;
	
	// Clear manual adjustment attribute.
	ManualAdjustment = False;
	
	BaseDocument = Undefined;
	
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
		
	RegisterRecords.CashFlowData.Write = True;
	
	If IncomeBooking Then
		
		// Create a value table for posting amounts.
		PostingDatasetIncome = New ValueTable();
		PostingDatasetIncome.Columns.Add("IncomeAccount");
		PostingDatasetIncome.Columns.Add("Class");
		PostingDatasetIncome.Columns.Add("Project");
		PostingDatasetIncome.Columns.Add("AmountRC");
		
		PostingDatasetCOGS = New ValueTable();
		PostingDatasetCOGS.Columns.Add("COGSAccount");
		PostingDatasetCOGS.Columns.Add("Class");
		PostingDatasetCOGS.Columns.Add("Project");
		PostingDatasetCOGS.Columns.Add("AmountRC");	
		
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
					Query.SetParameter("Location", CurRowLineItems.LocationActual);
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
				PostingLineCOGS.COGSAccount = CurRowLineItems.Product.COGSAccount;
				PostingLineCOGS.Class = CurRowLineItems.Class;
				PostingLineCOGS.Project = CurRowLineItems.Project;
				PostingLineCOGS.AmountRC = ItemCost;
				
				PostingLineInvOrExp = PostingDatasetInvOrExp.Add();
				PostingLineInvOrExp.InvOrExpAccount = CurRowLineItems.Product.InventoryOrExpenseAccount;
				PostingLineInvOrExp.AmountRC = ItemCost;
				
			EndIf;
			
			// Fill in the account posting value table with amounts.
			PostingLineIncome = PostingDatasetIncome.Add();
			PostingLineIncome.IncomeAccount = CurRowLineItems.Product.IncomeAccount;
			PostingLineIncome.Class = CurRowLineItems.Class;
			PostingLineIncome.Project = CurRowLineItems.Project;
			PostingLineIncome.AmountRC = CurRowLineItems.LineTotal * ExchangeRate;
			
		EndDo;
		
	EndIf;
	
	If IncomeBooking Then
		
		// GL posting.
		
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
		
		PostingDatasetIncomeGJ = PostingDatasetIncome.Copy();
		
		PostingDatasetIncomeGJ.GroupBy("IncomeAccount", "AmountRC");
		NoOfPostingRows = PostingDatasetIncomeGJ.Count();
		For i = 0 To NoOfPostingRows - 1 Do
			Record = RegisterRecords.GeneralJournal.AddCredit();
			Record.Account = PostingDatasetIncomeGJ[i][0];
			Record.Period = Date;
			Record.AmountRC = PostingDatasetIncomeGJ[i][1];
		EndDo;
		
		PostingDatasetCOGS_GJ   = PostingDatasetCOGS.Copy();
		
		PostingDatasetCOGS_GJ.GroupBy("COGSAccount", "AmountRC");
		NoOfPostingRows = PostingDatasetCOGS_GJ.Count();
		For i = 0 To NoOfPostingRows - 1 Do
			Record = RegisterRecords.GeneralJournal.AddDebit();
			Record.Account = PostingDatasetCOGS_GJ[i][0];
			Record.Period = Date;
			Record.AmountRC = PostingDatasetCOGS_GJ[i][1];
		EndDo;
		
		PostingDatasetInvOrExp.GroupBy("InvOrExpAccount", "AmountRC");
		NoOfPostingRows = PostingDatasetInvOrExp.Count();
		For i = 0 To NoOfPostingRows - 1 Do
			Record = RegisterRecords.GeneralJournal.AddCredit();
			Record.Account = PostingDatasetInvOrExp[i][0];
			Record.Period = Date;
			Record.AmountRC = PostingDatasetInvOrExp[i][1];
		EndDo;
		
		//If SalesTax > 0 Then
		//	Record = RegisterRecords.GeneralJournal.AddCredit();
		//	Record.Account = Constants.TaxPayableAccount.Get();
		//	Record.Period = Date;
		//	Record.AmountRC = SalesTax * ExchangeRate;
		//EndIf;
		
	EndIf;
		
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
	
	// Writing ProjectData and ClassData 	
	RegisterRecords.ProjectData.Write = True;
	RegisterRecords.ClassData.Write = True;
	
	// Writing Class data.
	PostingClassesIncome = PostingDatasetIncome.Copy();
	PostingClassesCOGS   = PostingDatasetCOGS.Copy();
	
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
	
	//--------------------------------------------------------------------------------------
	
	// Writing Project data.
	PostingClassesIncomeProject = PostingDatasetIncome.Copy();
	PostingClassesCOGSProject = PostingDatasetCOGS.Copy();
	
	PostingClassesIncomeProject.GroupBy("IncomeAccount, Project", "AmountRC");
	PostingClassesCOGSProject.GroupBy("COGSAccount, Project", "AmountRC");	
	
	// Income by Project
	For Each ClassesIncomeLine In PostingClassesIncomeProject Do
		Record = RegisterRecords.ProjectData.Add();
		Record.RecordType = AccumulationRecordType.Receipt;
		Record.Period = Date;
		Record.Account = ClassesIncomeLine.IncomeAccount;
		Record.Project = ClassesIncomeLine.Project;
		Record.Amount = ClassesIncomeLine.AmountRC;
	EndDo;
	
	// COGS by Project.
	For Each ClassesCOGSLine In PostingClassesCOGSProject Do
		Record = RegisterRecords.ProjectData.Add();
		Record.RecordType = AccumulationRecordType.Expense;
		Record.Period = Date;
		Record.Account = ClassesCOGSLine.COGSAccount;
		Record.Project = ClassesCOGSLine.Project;
		Record.Amount = ClassesCOGSLine.AmountRC;
	EndDo;
	// End writing Project data.
	
	RegisterRecords.OrderTransactions.Write = True;
	For Each CurRowLineItems In LineItems Do
		If NOT CurRowLineItems.Order.IsEmpty() Then
			Record = RegisterRecords.OrderTransactions.Add();
			Record.RecordType = AccumulationRecordType.Expense;
			Record.Period = Date;
			Record.Order = CurRowLineItems.Order;
			Record.Amount = 0; // CurRowLineItems.LineTotal;
		EndIf;
	EndDo;
	
	
	
	
	// -> CODE REVIEW
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
	
	// <- CODE REVIEW
	
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

Procedure OnSetNewNumber(StandardProcessing, Prefix)
	
	StandardProcessing = False;
	
	Numerator = Catalogs.DocumentNumbering.SalesInvoice;
	NextNumber = GeneralFunctions.Increment(Numerator.Number);
	
	While Documents.SalesInvoice.FindByNumber(NextNumber) <> Documents.SalesInvoice.EmptyRef() And NextNumber <> "" Do
		ObjectNumerator = Numerator.GetObject();
		ObjectNumerator.Number = NextNumber;
		ObjectNumerator.Write();
		
		NextNumber = GeneralFunctions.Increment(NextNumber);
	EndDo;
	
	ThisObject.Number = NextNumber; 

EndProcedure

#EndRegion