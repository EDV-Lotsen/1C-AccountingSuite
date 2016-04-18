
Procedure AuditLogCatalogBeforeWrite(Source, Cancel) Export
	
EndProcedure

Procedure AuditLogDeleteBeforeDelete(Source, Cancel) Export
	
	SourceObj = Source;
	If TypeOf(SourceObj) <> Type("DocumentObject.PurchaseOrder") AND TypeOf(SourceObj) <> Type("DocumentObject.SalesOrder") AND TypeOf(SourceObj) <> Type("DocumentObject.BankReconciliation")
		AND TypeOf(SourceObj) <> Type("DocumentObject.TimeTrack") AND TypeOf(SourceObj) <> Type("DocumentObject.WarehouseTransfer") AND TypeOf(SourceObj) <> Type("DocumentObject.Budget")
		AND TypeOf(SourceObj) <> Type("DocumentObject.Quote") AND TypeOf(SourceObj) <> Type("DocumentObject.LotsAdjustment") AND TypeOf(SourceObj) <> Type("DocumentObject.SerialNumbersAdjustment") AND
		TypeOf(SourceObj) <> Type("DocumentObject.Statement") AND TypeOf(SourceObj) <> Type ("ChartOfAccountsObject.ChartOfAccounts") Then
			
		Reg = InformationRegisters.AuditLog.CreateRecordManager();
		Reg.Period = CurrentDate();
		Reg.User = InfobaseUsers.CurrentUser();
		Reg.ObjUUID = String(SourceObj.Ref.UUID());
		Reg.Action = "Delete";
		Reg.ObjectName = String(SourceObj.Number);
		Reg.Reference = DocumentType(SourceObj,Reg);
		Reg.DateCreated = SourceObj.Date;
		If TypeOf(SourceObj) = Type("DocumentObject.BankTransfer") OR TypeOf(SourceObj) = Type("DocumentObject.ItemAdjustment") Then
			Reg.Amount = SourceObj.Amount;
		ElsIf TypeOf(SourceObj) = Type("DocumentObject.SalesTaxPayment") Then
			Reg.Amount = SourceObj.TotalPayment;
		ElsIf TypeOf(SourceObj) = Type("DocumentObject.Assembly") Then
			Reg.Amount = SourceObj.DocumentTotal;
		Else
			Reg.Amount = SourceObj.DocumentTotalRC;
		EndIf;
		Reg.Write();
	EndIf;
	
EndProcedure

Procedure AuditLogDocumentOnWrite(Source, Cancel, WriteMode, PostingMode) Export
	
	SourceObj = Source;
	If TypeOf(SourceObj) <> Type("DocumentObject.PurchaseOrder") AND TypeOf(SourceObj) <> Type("DocumentObject.SalesOrder") AND TypeOf(SourceObj) <> Type("DocumentObject.BankReconciliation")
		AND TypeOf(SourceObj) <> Type("DocumentObject.TimeTrack") AND TypeOf(SourceObj) <> Type("DocumentObject.WarehouseTransfer") AND TypeOf(SourceObj) <> Type("DocumentObject.Budget")
		AND TypeOf(SourceObj) <> Type("DocumentObject.Quote") AND TypeOf(SourceObj) <> Type("DocumentObject.LotsAdjustment") AND TypeOf(SourceObj) <> Type("DocumentObject.SerialNumbersAdjustment") AND
		TypeOf(SourceObj) <> Type("DocumentObject.Statement") Then
		
		Reg = InformationRegisters.AuditLog.CreateRecordManager();
		Reg.Period = CurrentDate();
		Reg.User = InfobaseUsers.CurrentUser();
		Reg.ObjUUID = String(SourceObj.Ref.UUID());
		If SourceObj.AdditionalProperties.Property("NewDoc") Then
			SourceObj.AdditionalProperties.NewDoc = False;
			Reg.Action = "Create";
		Else
			Reg.Action = "Update";
		EndIf;
		Reg.ObjectName = String(SourceObj.Number);
		Reg.Reference = DocumentType(SourceObj,Reg);
		Reg.DateCreated = SourceObj.Date;
		If TypeOf(SourceObj) = Type("DocumentObject.BankTransfer") OR TypeOf(SourceObj) = Type("DocumentObject.ItemAdjustment") Then
			Reg.Amount = SourceObj.Amount;
		ElsIf TypeOf(SourceObj) = Type("DocumentObject.SalesTaxPayment") Then
			Reg.Amount = SourceObj.TotalPayment;
		ElsIf TypeOf(SourceObj) = Type("DocumentObject.Assembly") Then
			Reg.Amount = SourceObj.DocumentTotal;
		Else
			Reg.Amount = SourceObj.DocumentTotalRC;
		EndIf;
		Reg.Write();
	EndIf;
	
EndProcedure

Function CatalogType(Object) Export
	
	If TypeOf(Object) = Type("CatalogObject.Addresses") Then
		Return "Addresses";
	Elsif  TypeOf(Object) = Type("CatalogObject.Classes") Then
		Return "Classes";
	Elsif  TypeOf(Object) = Type("CatalogObject.Companies") Then
		Return "Companies";
	Elsif  TypeOf(Object) = Type("CatalogObject.Countries") Then
		Return "Countries";
	Elsif  TypeOf(Object) = Type("CatalogObject.Currencies") Then
		Return "Currencies";
	Elsif  TypeOf(Object) = Type("CatalogObject.Locations") Then
		Return "Locations";
	Elsif  TypeOf(Object) = Type("CatalogObject.PaymentMethods") Then
		Return "Payment Methods";
	Elsif  TypeOf(Object) = Type("CatalogObject.PaymentTerms") Then
		Return "Payment Terms";
	Elsif  TypeOf(Object) = Type("CatalogObject.PriceLevels") Then
		Return "Price Levels";
	Elsif  TypeOf(Object) = Type("CatalogObject.ProductCategories") Then
		Return "Product Categories";
	Elsif  TypeOf(Object) = Type("CatalogObject.Products") Then
		Return "Products";
	Elsif  TypeOf(Object) = Type("CatalogObject.Projects") Then
		Return "Projects";
	Elsif  TypeOf(Object) = Type("CatalogObject.SalesTaxRates") Then
		Return "Sales Tax Codes";
	Elsif  TypeOf(Object) = Type("CatalogObject.States") Then
		Return "States";
	Elsif  TypeOf(Object) = Type("CatalogObject.PaymentMethods") Then
		Return "Payment Methods";
	Elsif  TypeOf(Object) = Type("CatalogObject.SalesPeople") Then
		Return "Sales People";
	EndIf;
	
EndFunction

Function DocumentType(Object,Reg) Export
	
	If TypeOf(Object) = Type("DocumentObject.BankTransfer") Then
		Reg.DataJSON = InternetConnectionClientServer.EncodeJSON(Webhooks.ReturnBankTransferMap(Object));
		Return "Bank Transfer";
	ElsIf TypeOf(Object) = Type("DocumentObject.CashReceipt") Then
		Reg.DataJSON = InternetConnectionClientServer.EncodeJSON(Webhooks.ReturnCashReceiptMap(Object));
		Return "Cash Receipt";
	ElsIf TypeOf(Object) = Type("DocumentObject.CashSale") Then
		Reg.DataJSON = InternetConnectionClientServer.EncodeJSON(Webhooks.ReturnCashSaleMap(Object));
		Return "Cash Sale";
	ElsIf TypeOf(Object) = Type("DocumentObject.Check") Then 
		Reg.DataJSON = InternetConnectionClientServer.EncodeJSON(Webhooks.ReturnCheckMap(Object));
		Return "Payment";
	ElsIf TypeOf(Object) = Type("DocumentObject.Deposit") Then
		Reg.DataJSON = InternetConnectionClientServer.EncodeJSON(Webhooks.ReturnDepositMap(Object));
		Return "Deposit";
	ElsIf TypeOf(Object) = Type("DocumentObject.GeneralJournalEntry") Then
		Reg.DataJSON = InternetConnectionClientServer.EncodeJSON(Webhooks.ReturnGJEntryMap(Object));
		Return "Journal Entry";
	ElsIf TypeOf(Object) = Type("DocumentObject.InvoicePayment") Then
		Reg.DataJSON = InternetConnectionClientServer.EncodeJSON(Webhooks.ReturnInvoicePaymentMap(Object));
		Return "Bill Payment";
	ElsIf TypeOf(Object) = Type("DocumentObject.ItemReceipt") Then
		Reg.DataJSON = InternetConnectionClientServer.EncodeJSON(Webhooks.ReturnItemReceiptMap(Object));
		Return "Item Receipt";
	ElsIf TypeOf(Object) = Type("DocumentObject.Shipment") Then
		Reg.DataJSON = InternetConnectionClientServer.EncodeJSON(Webhooks.ReturnShipmentMap(Object));
		Return "Shipment";
	ElsIf TypeOf(Object) = Type("DocumentObject.Assembly") Then
		Reg.DataJSON = InternetConnectionClientServer.EncodeJSON(Webhooks.ReturnAssemblyMap(Object));
		Return "Assembly Build";
	ElsIf TypeOf(Object) = Type("DocumentObject.PurchaseInvoice") Then
		Reg.DataJSON = InternetConnectionClientServer.EncodeJSON(Webhooks.ReturnPurchaseInvoiceMap(Object));
		Return "Bill";
	ElsIf TypeOf(Object) = Type("DocumentObject.PurchaseReturn") Then
		Reg.DataJSON = InternetConnectionClientServer.EncodeJSON(Webhooks.ReturnPurchaseReturnMap(Object));
		Return "Purchase Return";
	ElsIf TypeOf(Object) = Type("DocumentObject.SalesInvoice") Then
		Reg.DataJSON = InternetConnectionClientServer.EncodeJSON(Webhooks.ReturnSalesInvoiceMap(Object));
		Return "Sales Invoice";
	ElsIf TypeOf(Object) = Type("DocumentObject.SalesReturn") Then
		Reg.DataJSON = InternetConnectionClientServer.EncodeJSON(Webhooks.ReturnSalesReturnMap(Object));
		Return "Credit Memo";
	ElsIf TypeOf(Object) = Type("DocumentObject.ItemAdjustment") Then
		Reg.DataJSON = InternetConnectionClientServer.EncodeJSON(Webhooks.ReturnItemAdjustmentMap(Object));
		Return "Item Adjustment";
	ElsIf TypeOf(Object) = Type("DocumentObject.SalesTaxPayment") Then
		Reg.DataJSON = InternetConnectionClientServer.EncodeJSON(Webhooks.ReturnSalesTaxPaymentMap(Object));
		Return "Sales Tax Payment";
	EndIf;
	
EndFunction

Procedure DocumentNewSetBeforeWrite(Source, Cancel, WriteMode, PostingMode) Export
	
	If Source.IsNew() Then
		Source.AdditionalProperties.Insert("NewDoc", True);
	EndIf;
	
EndProcedure
