
Procedure AuditLogCatalogBeforeWrite(Source, Cancel) Export
	
	//SourceObj = Source;
	//If TypeOf(SourceObj) = Type("CatalogObject.Products") OR TypeOf(SourceObj) = Type("CatalogObject.Companies") Then	
	//	//If CommonUse.IsCatalog(SourceObj.Metadata()) Then

	//		//If SourceObj.NewObject = True Then
	//		If SourceObj.IsNew() Then
	//			Reg = InformationRegisters.AuditLog.CreateRecordManager();
	//			Reg.Period = CurrentDate();
	//			Reg.User = InfobaseUsers.CurrentUser();
	//			//Reg.ObjUUID = String(SourceObj.Ref.UUID());
	//			Reg.Action = "Create";
	//			Reg.ObjectName = String(SourceObj);
	//			Reg.Reference = CatalogType(SourceObj);
	//			//Reg.DateCreated = SourceObj.Date;
	//			
	//			If TypeOf(SourceObj) = Type("CatalogObject.Products") Then
	//				Reg.DataJSON = InternetConnectionClientServer.EncodeJSON(GeneralFunctions.ReturnProductObjectMap(SourceObj));
	//			
	//			ElsIf TypeOf(SourceObj) = Type("CatalogObject.Companies") Then
	//				Reg.DataJSON = InternetConnectionClientServer.EncodeJSON(GeneralFunctions.ReturnCompanyObjectMap(SourceObj));
	//			Else

	//			EndIf;

	//			
	//			Reg.Write();
	//		Else
	//			Reg = InformationRegisters.AuditLog.CreateRecordManager();
	//			Reg.Period = CurrentDate();
	//			Reg.User = InfobaseUsers.CurrentUser();
	//			Reg.ObjUUID = String(SourceObj.Ref.UUID());
	//			Reg.Action = "Update";
	//			Reg.ObjectName = String(SourceObj);
	//			Reg.Reference = CatalogType(SourceObj);
	//			//Reg.DateCreated = SourceObj.Date;
	//			
	//			If TypeOf(SourceObj) = Type("CatalogObject.Products") Then
	//				Reg.DataJSON = InternetConnectionClientServer.EncodeJSON(GeneralFunctions.ReturnProductObjectMap(SourceObj));
	//			
	//			ElsIf TypeOf(SourceObj) = Type("CatalogObject.Companies") Then
	//				Reg.DataJSON = InternetConnectionClientServer.EncodeJSON(GeneralFunctions.ReturnCompanyObjectMap(SourceObj));
	//			Else
	//			EndIf;

	//			
	//			Reg.Write();

	//		EndIf;
	//EndIf;
					
EndProcedure

Procedure AuditLogDeleteBeforeDelete(Source, Cancel) Export
	SourceObj = Source;
			
		If CommonUse.IsCatalog(SourceObj.Metadata()) Then
		
			If TypeOf(SourceObj) = Type("CatalogObject.Products") OR TypeOf(SourceObj) = Type("CatalogObject.Companies") Then

				Reg = InformationRegisters.AuditLog.CreateRecordManager();
				Reg.Period = CurrentDate();
				Reg.User = InfobaseUsers.CurrentUser();
				Reg.ObjUUID = String(SourceObj.Ref.UUID());
				Reg.Action = "Delete";
				Reg.ObjectName = String(SourceObj);
				Reg.Reference = CatalogType(SourceObj);
				//Reg.DateCreated = SourceObj.Date;

				
				If TypeOf(SourceObj) = Type("CatalogObject.Products") Then
					Reg.DataJSON = InternetConnectionClientServer.EncodeJSON(GeneralFunctions.ReturnProductObjectMap(SourceObj));
				
				ElsIf TypeOf(SourceObj) = Type("CatalogObject.Companies") Then
					Reg.DataJSON = InternetConnectionClientServer.EncodeJSON(GeneralFunctions.ReturnCompanyObjectMap(SourceObj));
				Else
				EndIf;

				
				Reg.Write();
				
			EndIf;
			
		Else

			If TypeOf(SourceObj) <> Type("DocumentObject.PurchaseOrder") AND TypeOf(SourceObj) <> Type("DocumentObject.SalesOrder") //AND TypeOf(SourceObj) <> Type("DocumentObject.ItemAdjustment")
				AND TypeOf(SourceObj) <> Type("DocumentObject.TimeTrack") AND TypeOf(SourceObj) <> Type("DocumentObject.WarehouseTransfer") AND TypeOf(SourceObj) <> Type("DocumentObject.Budget") AND TypeOf(SourceObj) <> Type("ChartOfAccountsObject.ChartOfAccounts") Then

			   
				Reg = InformationRegisters.AuditLog.CreateRecordManager();
				Reg.Period = CurrentDate();
				Reg.User = InfobaseUsers.CurrentUser();
				Reg.ObjUUID = String(SourceObj.Ref.UUID());
				Reg.Action = "Delete";
				Reg.Reference = DocumentType(SourceObj,Reg);
				Reg.DateCreated = SourceObj.Date;
				If TypeOf(SourceObj) = Type("DocumentObject.BankTransfer") OR TypeOf(SourceObj) = Type("DocumentObject.ItemAdjustment") Then
					Reg.Amount = SourceObj.Amount;
				ElsIf TypeOf(SourceObj) = Type("DocumentObject.BankReconciliation") Then
				ElsIf TypeOf(SourceObj) = Type("DocumentObject.Statement") Then
				Else
					Reg.Amount = SourceObj.DocumentTotalRC;
				EndIf;


				
				If TypeOf(SourceObj) = Type("DocumentObject.SalesOrder") Then
					Reg.ObjectName = SourceObj.Number;
					Reg.DataJSON = InternetConnectionClientServer.EncodeJSON(GeneralFunctions.ReturnSaleOrderMap(SourceObj));
				ElsIf TypeOf(SourceObj) = Type("DocumentObject.ItemAdjustment") Then
					Reg.ObjectName = "Item: " + String(SourceObj.Product);
				Else
					Reg.ObjectName = String(SourceObj.Number);
				EndIf;
							
				Reg.Write();
				
			EndIf;
			
		EndIf;	
EndProcedure
	
Procedure AuditLogDocumentOnWrite(Source, Cancel, WriteMode, PostingMode) Export
	
	SourceObj = Source;
	//If SourceObj.NewObject = True Then
	If TypeOf(SourceObj) <> Type("DocumentObject.PurchaseOrder") AND TypeOf(SourceObj) <> Type("DocumentObject.SalesOrder") //AND TypeOf(SourceObj) <> Type("DocumentObject.ItemAdjustment")
		AND TypeOf(SourceObj) <> Type("DocumentObject.TimeTrack") AND TypeOf(SourceObj) <> Type("DocumentObject.WarehouseTransfer") AND TypeOf(SourceObj) <> Type("DocumentObject.Budget") Then
				
		If SourceObj.AdditionalProperties.Property("NewDoc") Then
			SourceObj.AdditionalProperties.NewDoc = False;
			Reg = InformationRegisters.AuditLog.CreateRecordManager();
			Reg.Period = CurrentDate();
			Reg.User = InfobaseUsers.CurrentUser();
			Reg.ObjUUID = String(SourceObj.Ref.UUID());
			Reg.Action = "Create";
			
			If TypeOf(SourceObj) = Type("DocumentObject.ItemAdjustment") Then
				Reg.ObjectName = "Item: " + String(SourceObj.Product);
			Else
				Reg.ObjectName = String(SourceObj.Number);
			EndIf;

			Reg.Reference = DocumentType(SourceObj,Reg);
			Reg.DateCreated = SourceObj.Date;
			If TypeOf(SourceObj) = Type("DocumentObject.BankTransfer") OR TypeOf(SourceObj) = Type("DocumentObject.ItemAdjustment") Then
				Reg.Amount = SourceObj.Amount;
			ElsIf TypeOf(SourceObj) = Type("DocumentObject.BankReconciliation") Then
			ElsIf TypeOf(SourceObj) = Type("DocumentObject.SalesTaxPayment") Then
				Reg.Amount = SourceObj.TotalPayment;
			Else
				Reg.Amount = SourceObj.DocumentTotalRC;
			EndIf;
			
			If TypeOf(SourceObj) = Type("DocumentObject.SalesOrder") Then
				Reg.ObjectName = SourceObj.Number;
				Reg.DataJSON = InternetConnectionClientServer.EncodeJSON(GeneralFunctions.ReturnSaleOrderMap(SourceObj));
			Else
			EndIf;
									
			Reg.Write();
		Else
			Reg = InformationRegisters.AuditLog.CreateRecordManager();
			Reg.Period = CurrentDate();
			Reg.User = InfobaseUsers.CurrentUser();
			Reg.ObjUUID = String(SourceObj.Ref.UUID());
			Reg.Action = "Update";
			If TypeOf(SourceObj) = Type("DocumentObject.ItemAdjustment") Then
				Reg.ObjectName = "Item: " + String(SourceObj.Product);
			Else
				Reg.ObjectName = String(SourceObj.Number);
			EndIf;

			Reg.Reference = DocumentType(SourceObj,Reg);
			Reg.DateCreated = SourceObj.Date;
			If TypeOf(SourceObj) = Type("DocumentObject.BankTransfer") OR TypeOf(SourceObj) = Type("DocumentObject.ItemAdjustment") Then
				Reg.Amount = SourceObj.Amount;
			ElsIf TypeOf(SourceObj) = Type("DocumentObject.BankReconciliation") Then
			ElsIf TypeOf(SourceObj) = Type("DocumentObject.SalesTaxPayment") Then
				Reg.Amount = SourceObj.TotalPayment;
			Else
				Reg.Amount = SourceObj.DocumentTotalRC;
			EndIf;


			
			If TypeOf(SourceObj) = Type("DocumentObject.SalesOrder") Then
				Reg.ObjectName = SourceObj.Number;
				Reg.DataJSON = InternetConnectionClientServer.EncodeJSON(GeneralFunctions.ReturnSaleOrderMap(SourceObj));
			Else
			EndIf;
						
			Reg.Write();

			                    
		EndIf;
		
	EndIf;

	
EndProcedure
	
Function CatalogType(Object) Export
		
		If TypeOf(Object) = Type("CatalogObject.Addresses") Then
			Return "Addresses";
		Elsif  TypeOf(Object) = Type("CatalogObject.BankAccounts") Then
			Return "Bank Accounts";
		Elsif  TypeOf(Object) = Type("CatalogObject.Banks") Then
			Return "Banks";
		Elsif  TypeOf(Object) = Type("CatalogObject.Classes") Then
			Return "Classes";
		Elsif  TypeOf(Object) = Type("CatalogObject.Companies") Then
			Return "Companies";
		Elsif  TypeOf(Object) = Type("CatalogObject.Countries") Then
			Return "Countries";
		Elsif  TypeOf(Object) = Type("CatalogObject.Currencies") Then
			Return "Currencies";
		Elsif  TypeOf(Object) = Type("CatalogObject.ExpensifyCategories") Then
			Return "Expensify Categories";
		Elsif  TypeOf(Object) = Type("CatalogObject.Locations") Then
			Return "Locations";
		//Not adding payment buttons
		//Not adding milestones
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
		Elsif  TypeOf(Object) = Type("CatalogObject.SalesTaxCodes") Then
			Return "Sales Tax Codes";
		Elsif  TypeOf(Object) = Type("CatalogObject.States") Then
			Return "States";
		Elsif  TypeOf(Object) = Type("CatalogObject.UM") Then
			Return "Unit of Measurement";
		Elsif  TypeOf(Object) = Type("CatalogObject.PaymentMethods") Then
			Return "Payment Methods";
		Elsif  TypeOf(Object) = Type("CatalogObject.UserList") Then
			Return "User List";
		Elsif  TypeOf(Object) = Type("CatalogObject.SalesPeople") Then
			Return "Sales People";
		Else


		EndIf;
		
		
EndFunction
	
Function DocumentType(Object,Reg) Export
		
		If TypeOf(Object) = Type("DocumentObject.BankReconciliation") Then
			Reg.DataJSON = InternetConnectionClientServer.EncodeJSON(Webhooks.ReturnBankReconMapNew(Object));
			Return "Bank Reconciliation";	
		ElsIf TypeOf(Object) = Type("DocumentObject.BankTransfer") Then
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
			Return "Payment (Check)";
		ElsIf TypeOf(Object) = Type("DocumentObject.Deposit") Then
			Reg.DataJSON = InternetConnectionClientServer.EncodeJSON(Webhooks.ReturnDepositMap(Object));
			Return "Deposit";
		ElsIf TypeOf(Object) = Type("DocumentObject.GeneralJournalEntry") Then
			Reg.DataJSON = InternetConnectionClientServer.EncodeJSON(Webhooks.ReturnGJEntryMap(Object));
			Return "General Journal Entry";
		ElsIf TypeOf(Object) = Type("DocumentObject.InvoicePayment") Then
			Reg.DataJSON = InternetConnectionClientServer.EncodeJSON(Webhooks.ReturnInvoicePaymentMap(Object));
			Return "Bill Payment (Check)";
		ElsIf TypeOf(Object) = Type("DocumentObject.ItemReceipt") Then
			Return "Item Receipt";
		ElsIf TypeOf(Object) = Type("DocumentObject.PurchaseInvoice") Then
			Reg.DataJSON = InternetConnectionClientServer.EncodeJSON(Webhooks.ReturnPurchaseInvoiceMap(Object));
			Return "Bill";
		ElsIf TypeOf(Object) = Type("DocumentObject.PurchaseOrder") Then
			Return "Purchase Order";
		ElsIf TypeOf(Object) = Type("DocumentObject.PurchaseReturn") Then
			Reg.DataJSON = InternetConnectionClientServer.EncodeJSON(Webhooks.ReturnPurchaseReturnMap(Object));
			Return "Purchase Return";
		ElsIf TypeOf(Object) = Type("DocumentObject.SalesInvoice") Then
			Reg.DataJSON = InternetConnectionClientServer.EncodeJSON(Webhooks.ReturnSalesInvoiceMap(Object));
			Return "Sales Invoice";
		ElsIf TypeOf(Object) = Type("DocumentObject.SalesOrder") Then
			Return "Sales Order";

		ElsIf TypeOf(Object) = Type("DocumentObject.SalesReturn") Then
			Reg.DataJSON = InternetConnectionClientServer.EncodeJSON(Webhooks.ReturnSalesReturnMap(Object));
			Return "Credit Memo";
		ElsIf TypeOf(Object) = Type("DocumentObject.ItemAdjustment") Then
			Reg.DataJSON = InternetConnectionClientServer.EncodeJSON(Webhooks.ReturnItemAdjustmentMap(Object));
			Return "Item Adjustment";
		ElsIf TypeOf(Object) = Type("DocumentObject.SalesTaxPayment") Then
			Reg.DataJSON = InternetConnectionClientServer.EncodeJSON(Webhooks.ReturnSalesTaxPaymentMap(Object));
			Return "Sales Tax Payment";
		ElsIf TypeOf(Object) = Type("DocumentObject.Statement") Then
			Return "Statement";
		ElsIf TypeOf(Object) = Type("DocumentObject.Quote") Then
			Return "Quote";
		Else
			
		EndIf;

EndFunction

Procedure DocumentNewSetBeforeWrite(Source, Cancel, WriteMode, PostingMode) Export
		
		If Source.IsNew() Then
                Source.AdditionalProperties.Insert("NewDoc", True);
        EndIf;
		
EndProcedure
