
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	CreateSales = "Create...";
	CreatePurchasing = "Create...";
	CreateBank = "Create...";
	CreateAccounting = "Create...";
	CreateLists = "Create...";

EndProcedure

&AtClient
Procedure CreateSalesOnChange(Item)
	
	If CreateSales = "Sales order" Then
		OpenForm("Document.SalesOrder.Form.DocumentForm");	
	ElsIf CreateSales = "Sales invoice" Then
		OpenForm("Document.SalesInvoice.Form.DocumentForm");	
	ElsIf CreateSales = "Cash sale" Then
		OpenForm("Document.CashSale.Form.DocumentForm");	
	EndIf;

EndProcedure

&AtClient
Procedure CreatePurchasingOnChange(Item)
	
	If CreatePurchasing = "Purchase order" Then
		OpenForm("Document.PurchaseOrder.Form.DocumentForm");	
	ElsIf CreatePurchasing = "Purchase invoice" Then
		OpenForm("Document.PurchaseInvoice.Form.DocumentForm");	
	ElsIf CreatePurchasing = "Cash purchase" Then
		OpenForm("Document.CashPurchase.Form.DocumentForm");
	EndIf;

EndProcedure

&AtClient
Procedure CreateBankOnChange(Item)
	
	If CreateBank = "Cash receipt" Then
		OpenForm("Document.CashReceipt.Form.DocumentForm");
	ElsIf CreateBank = "Invoice payment" Then
		OpenForm("Document.InvoicePayment.Form.DocumentForm");
	ElsIf CreateBank = "Deposit" Then
		OpenForm("Document.Deposit.Form.DocumentForm");
	ElsIf CreateBank = "Check" Then
		OpenForm("Document.Check.Form.DocumentForm");
	EndIf;

EndProcedure

&AtClient
Procedure CreateAccountingOnChange(Item)
	
	If CreateAccounting = "General journal entry" Then
		OpenForm("Document.GeneralJournalEntry.Form.DocumentForm");
	Else
	EndIf;

EndProcedure

&AtClient
Procedure CreateListsOnChange(Item)
	
	If CreateLists = "Create company" Then
		OpenForm("Catalog.Companies.Form.ItemForm");
	ElsIf CreateLists = "Create item" Then
		OpenForm("Catalog.Products.Form.ItemForm");
	EndIf;

EndProcedure

&AtClient
Procedure Settings(Command)
	
	OpenForm("CommonForm.GeneralSettings");
	
EndProcedure


