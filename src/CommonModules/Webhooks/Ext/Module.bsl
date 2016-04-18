
Procedure GetData(OrderData, NewOrder, TypeDoc) Export
	
	OrderData.Insert("api_code", String(NewOrder.Ref.UUID()));
	
	StdAttrs = TypeDoc.StandardAttributes;
	
	For Each StdAttr In StdAttrs Do
		
		OrderData.Insert(StdAttr.Name,NewOrder[StdAttr.Name]);
		
	EndDo;
	
	Attrs = TypeDoc.Attributes;
	
	For Each Attr In Attrs Do
		
		OrderData.Insert(Attr.Name,NewOrder[Attr.Name]);
		
	EndDo;
	
	TSS = TypeDoc.TabularSections;
	
	For Each TS In TSS Do
		
		Array = New Array;
		
		//
		
		For Each CurrentRow In NewOrder[TS.Name] Do
			
			TSName = New Map();
			
			StdAttrs = TS.StandardAttributes;
			
			For Each StdAttr In StdAttrs Do
				
				TSName.Insert(StdAttr.Name, CurrentRow[StdAttr.Name]);
				
			EndDo;
			
			Attrs = TS.Attributes;
			
			For Each Attr In Attrs Do
				
				TSName.Insert(Attr.Name, CurrentRow[Attr.Name]);
				
			EndDo;
			
			Array.Add(TSName);
			
		EndDo;
		
		//
		
		
		OrderData.Insert(TS.Name, Array);
		
	EndDo;
	
	
	
EndProcedure

Function ReturnCashSaleMap(NewOrder) Export
	
	OrderData = New Map();
	GetData(OrderData, NewOrder, Metadata.Documents.CashSale);
	Return OrderData;

	
EndFunction

Function ReturnSalesOrderMap(NewOrder) Export
	
	OrderData = New Map();
	GetData(OrderData, NewOrder, Metadata.Documents.SalesOrder);
	Return OrderData;
	
EndFunction

Function ReturnSalesInvoiceMap(NewOrder) Export
	
	OrderData = New Map();	
	GetData(OrderData, NewOrder, Metadata.Documents.SalesInvoice);	
	Return OrderData;
	
EndFunction

Function ReturnCashReceiptMap(NewOrder) Export
	
	OrderData = New Map();
	GetData(OrderData, NewOrder, Metadata.Documents.CashReceipt);
	Return OrderData;


EndFunction

Function ReturnSalesReturnMap(NewOrder) Export
	
	OrderData = New Map();
	GetData(OrderData, NewOrder, Metadata.Documents.SalesReturn);
	Return OrderData;

	
EndFunction

Function ReturnPurchaseReturnMap(NewOrder) Export
	
	OrderData = New Map();
	GetData(OrderData, NewOrder, Metadata.Documents.PurchaseReturn);
	Return OrderData;

EndFunction

Function ReturnPurchaseInvoiceMap(NewOrder) Export
	
	OrderData = New Map();
	GetData(OrderData, NewOrder, Metadata.Documents.PurchaseInvoice);
	Return OrderData;

	
EndFunction

Function ReturnInvoicePaymentMap(NewOrder) Export
	
	OrderData = New Map();
	GetData(OrderData, NewOrder, Metadata.Documents.InvoicePayment);
	Return OrderData;

	
EndFunction

Function ReturnDepositMap(NewOrder) Export
	
	OrderData = New Map();
	GetData(OrderData, NewOrder, Metadata.Documents.Deposit);
	Return OrderData;

EndFunction

Function ReturnCheckMap(NewOrder) Export
	
	OrderData = New Map();	
	GetData(OrderData, NewOrder, Metadata.Documents.Check);	
	Return OrderData;
	
EndFunction

Function ReturnBankTransferMap(NewOrder) Export
	
	OrderData = New Map();
	GetData(OrderData, NewOrder, Metadata.Documents.BankTransfer);
	Return OrderData;

	
EndFunction

Function ReturnGJEntryMap(NewOrder) Export
	
	OrderData = New Map();
	GetData(OrderData, NewOrder, Metadata.Documents.GeneralJournalEntry);
	Return OrderData;
	
EndFunction

Function ReturnItemAdjustmentMap(NewOrder) Export
	
	OrderData = New Map();
	GetData(OrderData, NewOrder, Metadata.Documents.ItemAdjustment);
	Return OrderData;

	
EndFunction

Function ReturnSalesTaxPaymentMap(NewOrder) Export
	
	OrderData = New Map();
	GetData(OrderData, NewOrder, Metadata.Documents.SalesTaxPayment);
	Return OrderData;

	
EndFunction

Function ReturnItemReceiptMap(NewOrder) Export
	
	OrderData = New Map();
	GetData(OrderData, NewOrder, Metadata.Documents.ItemReceipt);
	Return OrderData;
	
EndFunction

Function ReturnShipmentMap(NewOrder) Export
	
	OrderData = New Map();
	GetData(OrderData, NewOrder, Metadata.Documents.Shipment);
	Return OrderData;
	
EndFunction

Function ReturnAssemblyMap(NewOrder) Export
	
	OrderData = New Map();
	GetData(OrderData, NewOrder, Metadata.Documents.Assembly);
	Return OrderData;
	
EndFunction

Function ReturnProductObjectMap(NewProduct) Export
	
	OrderData = New Map();
	GetData(OrderData, NewProduct, Metadata.Catalogs.Products);
	Return OrderData;

EndFunction

Function ReturnCompanyObjectMap(NewCompany) Export
	
	OrderData = New Map();
	GetData(OrderData, NewCompany, Metadata.Catalogs.Companies);
	Return OrderData;
	
EndFunction
