
////////////////////////////////////////////////////////////////////////////////
// Navigation full: Common form
//------------------------------------------------------------------------------
// Available on:
// - Client (managed application)
// - Server
//

///////////////////////////////////////////////////////////////////////////////
#Region EVENTS_HANDLERS

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region COMMANDS_HANDLERS

&AtClient
Procedure SalesOrder(Command)
	OpenForm("Document.SalesOrder.Form.DocumentForm");
EndProcedure

&AtClient
Procedure SalesInvoice(Command)
	OpenForm("Document.SalesInvoice.Form.DocumentForm");
EndProcedure

&AtClient
Procedure SalesReturn(Command)
	OpenForm("Document.SalesReturn.Form.DocumentForm");
EndProcedure

&AtClient
Procedure CashReceipt(Command)
	OpenForm("Document.CashReceipt.Form.DocumentForm");
EndProcedure

&AtClient
Procedure CashSale(Command)
	OpenForm("Document.CashSale.Form.DocumentForm");
EndProcedure

&AtClient
Procedure PurchaseOrder(Command)
	OpenForm("Document.PurchaseOrder.Form.DocumentForm");
EndProcedure

&AtClient
Procedure PurchaseInvoice(Command)
	OpenForm("Document.PurchaseInvoice.Form.DocumentForm");
EndProcedure

&AtClient
Procedure PurchaseReturn(Command)
	OpenForm("Document.PurchaseReturn.Form.DocumentForm");
EndProcedure

&AtClient
Procedure InvoicePayment(Command)
	OpenForm("Document.InvoicePayment.Form.DocumentForm");
EndProcedure

&AtClient
Procedure ItemAdjustment(Command)
	OpenForm("Document.ItemAdjustment.Form.DocumentForm");
EndProcedure

&AtClient
Procedure Check(Command)
	OpenForm("Document.Check.Form.DocumentForm");
EndProcedure

&AtClient
Procedure Deposit(Command)
	OpenForm("Document.Deposit.Form.DocumentForm");
EndProcedure

&AtClient
Procedure BankRec(Command)
	OpenForm("Document.BankReconciliation.Form.DocumentForm");
EndProcedure

&AtClient
Procedure GJEntry(Command)
	OpenForm("Document.GeneralJournalEntry.Form.DocumentForm");
EndProcedure

&AtClient
Procedure ChartOfAccounts(Command)
	OpenForm("ChartOfAccounts.ChartOfAccounts.Form.ListForm");
EndProcedure

&AtClient
Procedure Company(Command)
	OpenForm("Catalog.Companies.Form.ListForm");
EndProcedure

&AtClient
Procedure Product(Command)
	OpenForm("Catalog.Products.Form.ListForm");
EndProcedure

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region PRIVATE_IMPLEMENTATION

#EndRegion
