
Procedure CheckReorderQty() Export
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	OrdersDispatchedBalance.Product AS Product,
	|	CASE
	|		WHEN OrdersDispatchedBalance.QuantityBalance - OrdersDispatchedBalance.ReceivedBalance > 0
	|			THEN (OrdersDispatchedBalance.QuantityBalance - OrdersDispatchedBalance.ReceivedBalance) * OrdersDispatchedBalance.Unit.Factor
	|		ELSE 0
	|	END AS QtyOnPO,
	|	0 AS QtyOnSO,
	|	0 AS QtyOnHand
	|INTO Table_OrdersDispatched_OrdersRegistered_InventoryJournal
	|FROM
	|	AccumulationRegister.OrdersDispatched.Balance(, Product.Type = VALUE(Enum.InventoryTypes.Inventory)) AS OrdersDispatchedBalance
	|
	|UNION ALL
	|
	|SELECT
	|	OrdersRegisteredBalance.Product,
	|	0,
	|	CASE
	|		WHEN OrdersRegisteredBalance.QuantityBalance - OrdersRegisteredBalance.ShippedBalance > 0
	|			THEN (OrdersRegisteredBalance.QuantityBalance - OrdersRegisteredBalance.ShippedBalance) * OrdersRegisteredBalance.Unit.Factor
	|		ELSE 0
	|	END,
	|	0
	|FROM
	|	AccumulationRegister.OrdersRegistered.Balance(, Product.Type = VALUE(Enum.InventoryTypes.Inventory)) AS OrdersRegisteredBalance
	|
	|UNION ALL
	|
	|SELECT
	|	InventoryJournalBalance.Product,
	|	0,
	|	0,
	|	InventoryJournalBalance.QuantityBalance
	|FROM
	|	AccumulationRegister.InventoryJournal.Balance(, Product.Type = VALUE(Enum.InventoryTypes.Inventory)) AS InventoryJournalBalance
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Products.Ref AS Product,
	|	SUM(ISNULL(TableBalances.QtyOnPO, 0)) AS QtyOnPO,
	|	SUM(ISNULL(TableBalances.QtyOnSO, 0)) AS QtyOnSO,
	|	SUM(ISNULL(TableBalances.QtyOnHand, 0)) AS QtyOnHand,
	|	SUM(ISNULL(TableBalances.QtyOnHand, 0)) + SUM(ISNULL(TableBalances.QtyOnPO, 0)) - SUM(ISNULL(TableBalances.QtyOnSO, 0)) AS QtyAvailableToPromise
	|INTO Table_ATP
	|FROM
	|	Catalog.Products AS Products
	|		LEFT JOIN Table_OrdersDispatched_OrdersRegistered_InventoryJournal AS TableBalances
	|		ON Products.Ref = TableBalances.Product
	|WHERE
	|	Products.DeletionMark = FALSE
	|	AND Products.Type = VALUE(Enum.InventoryTypes.Inventory)
	|	AND Products.ReorderQty <> 0
	|
	|GROUP BY
	|	Products.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table_ATP.Product AS Product,
	|	Table_ATP.Product.ReorderQty AS ReorderQty,
	|	Table_ATP.QtyAvailableToPromise AS QtyAvailableToPromise 
	|FROM
	|	Table_ATP AS Table_ATP
	|WHERE
	|	Table_ATP.Product.ReorderQty >= Table_ATP.QtyAvailableToPromise";
	
	QueryResult = Query.Execute();
	
	SDR = QueryResult.Select();
	
	While SDR.Next() Do
		
		CurrentDate = BegOfDay(CurrentSessionDate());
		Text = "" + SDR.Product + " - Available to promise: " + SDR.QtyAvailableToPromise + ", Reorder Qty: " + SDR.ReorderQty + "!";
		
		RecordSet = InformationRegisters.Notifications.CreateRecordSet();	
		RecordSet.Filter.Period.Set(CurrentDate);
		RecordSet.Filter.Subject.Set(Text);
		
		NewRecord = RecordSet.Add();
		NewRecord.Period      = CurrentDate;
		NewRecord.Subject     = Text;
		NewRecord.Description = Text;
		NewRecord.Object      = SDR.Product;
		
		RecordSet.Write();
		
	EndDo;
	
EndProcedure

#Region Updating_InformationRegister_DocumentJournalOfCompanies

Procedure DocumentJournalOfCompaniesOnWrite(Source, Cancel) Export
	
	If Cancel Then Return; EndIf;
	
	SourceType = TypeOf(Source.Ref);
	
	RecordSet = InformationRegisters.DocumentJournalOfCompanies.CreateRecordSet();	
	RecordSet.Filter.Document.Set(Source.Ref);
	
	VT = RecordSet.Unload();
	VT.Clear();
	
	//1.
	If SourceType = Type("DocumentRef.SalesInvoice") Then
		
		LineVT = VT.Add();
		LineVT.Company        = Source.Company; 
		LineVT.Document       = Source.Ref; 
		LineVT.Line           = 1;
		LineVT.DocumentStatus = GetDocumentStatus(Source.Ref);
		LineVT.Date           = Source.Date;
		LineVT.DueDate        = Source.DueDate;
		LineVT.Total          = Source.DocumentTotalRC;
		LineVT.Memo           = Source.Memo;
		
		//2.	
	ElsIf SourceType = Type("DocumentRef.SalesOrder") Then
		
		LineVT = VT.Add();
		LineVT.Company        = Source.Company; 
		LineVT.Document       = Source.Ref; 
		LineVT.Line           = 1;
		LineVT.DocumentStatus = GetDocumentStatus(Source.Ref);
		LineVT.Date           = Source.Date;
		LineVT.DueDate        = Source.DeliveryDate;
		LineVT.Total          = Source.DocumentTotalRC;
		LineVT.Memo           = Source.Memo;
		
		//3.	
	ElsIf SourceType = Type("DocumentRef.SalesReturn") Then
		
		LineVT = VT.Add();
		LineVT.Company        = Source.Company; 
		LineVT.Document       = Source.Ref; 
		LineVT.Line           = 1;
		LineVT.DocumentStatus = GetDocumentStatus(Source.Ref);
		LineVT.Date           = Source.Date;
		LineVT.DueDate        = Source.DueDate;
		LineVT.Total          = Source.DocumentTotalRC;
		LineVT.Memo           = Source.Memo;
		
		//4.	
	ElsIf SourceType = Type("DocumentRef.PurchaseReturn") Then
		
		LineVT = VT.Add();
		LineVT.Company        = Source.Company; 
		LineVT.Document       = Source.Ref; 
		LineVT.Line           = 1;
		LineVT.DocumentStatus = GetDocumentStatus(Source.Ref);
		LineVT.Date           = Source.Date;
		LineVT.DueDate        = Source.DueDate;
		LineVT.Total          = Source.DocumentTotalRC;
		LineVT.Memo           = Source.Memo;
		
		//5.	
	ElsIf SourceType = Type("DocumentRef.PurchaseOrder") Then
		
		LineVT = VT.Add();
		LineVT.Company        = Source.Company; 
		LineVT.Document       = Source.Ref; 
		LineVT.Line           = 1;
		LineVT.DocumentStatus = GetDocumentStatus(Source.Ref);
		LineVT.Date           = Source.Date;
		LineVT.DueDate        = Source.DeliveryDate;
		LineVT.Total          = Source.DocumentTotalRC;
		LineVT.Memo           = Source.Memo;
		
		//6.	
	ElsIf SourceType = Type("DocumentRef.PurchaseInvoice") Then
		
		LineVT = VT.Add();
		LineVT.Company        = Source.Company; 
		LineVT.Document       = Source.Ref; 
		LineVT.Line           = 1;
		LineVT.DocumentStatus = GetDocumentStatus(Source.Ref);
		LineVT.Date           = Source.Date;
		LineVT.DueDate        = Source.DueDate;
		LineVT.Total          = Source.DocumentTotalRC;
		LineVT.Memo           = Source.Memo;
		
		//7.	
	ElsIf SourceType = Type("DocumentRef.InvoicePayment") Then
		
		LineVT = VT.Add();
		LineVT.Company        = Source.Company; 
		LineVT.Document       = Source.Ref; 
		LineVT.Line           = 1;
		LineVT.DocumentStatus = GetDocumentStatus(Source.Ref);
		LineVT.Date           = Source.Date;
		//LineVT.DueDate        = Source.DueDate;
		LineVT.Total          = Source.DocumentTotalRC;
		LineVT.Memo           = Source.Memo;
		
		//8.	
	ElsIf SourceType = Type("DocumentRef.Check") Then
		
		LineVT = VT.Add();
		LineVT.Company        = Source.Company; 
		LineVT.Document       = Source.Ref; 
		LineVT.Line           = 1;
		LineVT.DocumentStatus = GetDocumentStatus(Source.Ref);
		LineVT.Date           = Source.Date;
		//LineVT.DueDate        = Source.DueDate;
		LineVT.Total          = Source.DocumentTotalRC;
		LineVT.Memo           = Source.Memo;
		
		//9.	
	ElsIf SourceType = Type("DocumentRef.CashSale") Then
		
		LineVT = VT.Add();
		LineVT.Company        = Source.Company; 
		LineVT.Document       = Source.Ref; 
		LineVT.Line           = 1;
		LineVT.DocumentStatus = GetDocumentStatus(Source.Ref);
		LineVT.Date           = Source.Date;
		//LineVT.DueDate        = Source.DueDate;
		LineVT.Total          = Source.DocumentTotalRC;
		LineVT.Memo           = Source.Memo;
		
		//10.	
	ElsIf SourceType = Type("DocumentRef.CashReceipt") Then
		
		LineVT = VT.Add();
		LineVT.Company        = Source.Company; 
		LineVT.Document       = Source.Ref; 
		LineVT.Line           = 1;
		LineVT.DocumentStatus = GetDocumentStatus(Source.Ref);
		LineVT.Date           = Source.Date;
		//LineVT.DueDate        = Source.DueDate;
		LineVT.Total          = Source.CashPayment;
		LineVT.Memo           = Source.Memo;
		
		//11.	
	ElsIf SourceType = Type("DocumentRef.Deposit") Then
		
		LineNumber = 0;
		
		For Each SourceLine In Source.Accounts Do
			
			LineNumber = LineNumber + 1;
			
			LineVT = VT.Add();
			LineVT.Company        = SourceLine.Company; 
			LineVT.Document       = Source.Ref; 
			LineVT.Line           = LineNumber;
			LineVT.DocumentStatus = GetDocumentStatus(Source.Ref);
			LineVT.Date           = Source.Date;
			//LineVT.DueDate        = SourceLine.DueDate;
			LineVT.Total          = SourceLine.Amount;
			LineVT.Memo           = SourceLine.Memo;
			
		EndDo;
		
		//12.	
	ElsIf SourceType = Type("DocumentRef.GeneralJournalEntry") Then
		
		LineNumber = 0;
		
		For Each SourceLine In Source.LineItems Do
			
			LineNumber = LineNumber + 1;
			
			LineVT = VT.Add();
			LineVT.Company        = SourceLine.Company; 
			LineVT.Document       = Source.Ref; 
			LineVT.Line           = LineNumber;
			LineVT.DocumentStatus = GetDocumentStatus(Source.Ref);
			LineVT.Date           = Source.Date;
			LineVT.DueDate        = Source.DueDate;
			LineVT.Total          = ?(SourceLine.AmountDr = 0, SourceLine.AmountCr, SourceLine.AmountDr);
			LineVT.Memo           = SourceLine.Memo;
			
		EndDo;
		
		//13.	
	ElsIf SourceType = Type("DocumentRef.TimeTrack") Then
		
		LineVT = VT.Add();
		LineVT.Company        = Source.Company; 
		LineVT.Document       = Source.Ref; 
		LineVT.Line           = 1;
		LineVT.DocumentStatus = GetDocumentStatus(Source.Ref);
		LineVT.Date           = Source.Date;
		//LineVT.DueDate        = Source.DueDate;
		LineVT.Total          = Source.Price * Source.TimeComplete;
		LineVT.Memo           = Source.Memo;
		
		//14.	
	ElsIf SourceType = Type("DocumentRef.Statement") Then
		
		LineVT = VT.Add();
		LineVT.Company        = Source.Company; 
		LineVT.Document       = Source.Ref; 
		LineVT.Line           = 1;
		LineVT.DocumentStatus = GetDocumentStatus(Source.Ref);
		LineVT.Date           = Source.Date;
		//LineVT.DueDate        = Source.DueDate;
		//LineVT.Total          = Source.Price * Source.TimeComplete;
		//LineVT.Memo           = Source.Memo;
		
		//15.	
	ElsIf SourceType = Type("DocumentRef.Quote") Then
		
		LineVT = VT.Add();
		LineVT.Company        = Source.Company; 
		LineVT.Document       = Source.Ref; 
		LineVT.Line           = 1;
		LineVT.DocumentStatus = GetDocumentStatus(Source.Ref);
		LineVT.Date           = Source.Date;
		//LineVT.DueDate        = Source.DueDate;
		LineVT.Total          = Source.DocumentTotalRC;
		LineVT.Memo           = Source.Memo;
		
		//16.	
	ElsIf SourceType = Type("DocumentRef.ItemReceipt") Then
		
		LineVT = VT.Add();
		LineVT.Company        = Source.Company; 
		LineVT.Document       = Source.Ref; 
		LineVT.Line           = 1;
		LineVT.DocumentStatus = GetDocumentStatus(Source.Ref);
		LineVT.Date           = Source.Date;
		LineVT.DueDate        = Source.DueDate;
		LineVT.Total          = Source.DocumentTotalRC;
		LineVT.Memo           = Source.Memo;
		
		//17.	
	ElsIf SourceType = Type("DocumentRef.Shipment") Then
		
		LineVT = VT.Add();
		LineVT.Company        = Source.Company; 
		LineVT.Document       = Source.Ref; 
		LineVT.Line           = 1;
		LineVT.DocumentStatus = GetDocumentStatus(Source.Ref);
		LineVT.Date           = Source.Date;
		LineVT.Total          = Source.DocumentTotalRC;
		LineVT.Memo           = Source.Memo;
		
	EndIf;
	
	If Not Cancel Then
		
		RecordSet.Load(VT);
		RecordSet.Write();
		
	EndIf;
	
EndProcedure

Function GetDocumentStatus(DocumentRef)
	
	DocumentStatus = 0;	
	
	If Not DocumentRef.Posted And Not DocumentRef.DeletionMark Then
		DocumentStatus = 0;
	ElsIf DocumentRef.Posted And Not DocumentRef.DeletionMark Then
		DocumentStatus = 1;
	ElsIf Not DocumentRef.Posted And DocumentRef.DeletionMark Then
		DocumentStatus = 2;
	ElsIf DocumentRef.Posted AND DocumentRef.DeletionMark Then
		DocumentStatus = 4;
	EndIf;
		
	Return DocumentStatus;
	
EndFunction

#EndRegion