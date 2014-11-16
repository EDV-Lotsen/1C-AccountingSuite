
&AtClient
Procedure OpenDoc(Command)
	SelectedItem = Items.List.CurrentData;
	If SelectedItem <> Undefined Then
		DocRef = ReturnDocRef(SelectedItem.ObjUUID, SelectedItem.Reference);
		RefString = String(DocRef);
		If StrOccurenceCount(RefString,"Object not found") > 0 Then
			Message("This document does not exist.");
		Else
			OpenDocument(DocRef,SelectedItem.Reference);
		EndIf;
	EndIf;
	OpenDocAtServer();
EndProcedure

&AtServer
Procedure OpenDocAtServer()
	// Insert handler contents.
EndProcedure

&AtServer
Function ExistingDocument(DocRef)
	//query for docref here to see if it exists
EndFunction

&AtServer
Function ReturnDocRef(DocUUID, DocType)
	DocUUID = New UUID(DocUUID);
	If DocType = "Sales Invoice" Then
		Return Documents.SalesInvoice.GetRef(DocUUID);
	ElsIf DocType = "Sales Order" Then
		Return Documents.SalesOrder.GetRef(DocUUID);
	ElsIf DocType = "Purchase Return" Then
		Return Documents.PurchaseReturn.GetRef(DocUUID);
	ElsIf DocType = "Purchase Order" Then
		Return Documents.PurchaseOrder.GetRef(DocUUID);
	ElsIf DocType = "Bill" Then
		Return Documents.PurchaseInvoice.GetRef(DocUUID);
	ElsIf DocType = "Item Receipt" Then
		Return Documents.ItemReceipt.GetRef(DocUUID);
	ElsIf DocType = "Bill Payment (Check)" Then
		Return Documents.InvoicePayment.GetRef(DocUUID);
	ElsIf DocType = "General Journal Entry" Then
		Return Documents.GeneralJournalEntry.GetRef(DocUUID);
	ElsIf DocType = "Deposit" Then
		Return Documents.Deposit.GetRef(DocUUID);
	ElsIf DocType = "Payment (Check)" Then
		Return Documents.Check.GetRef(DocUUID);
	ElsIf DocType = "Cash Sale" Then
		Return Documents.CashSale.GetRef(DocUUID);
	ElsIf DocType = "Cash Receipt" Then
		Return Documents.CashReceipt.GetRef(DocUUID);
	ElsIf DocType = "Bank Transfer" Then
		Return Documents.BankTransfer.GetRef(DocUUID);
	ElsIf DocType = "Bank Reconciliation" Then
		Return Documents.BankReconciliation.GetRef(DocUUID);
	ElsIf DocType = "Credit Memo" Then
		Return Documents.SalesReturn.GetRef(DocUUID);
	ElsIf DocType = "Item Adjustment" Then
		Return Documents.ItemAdjustment.GetRef(DocUUID);
	ElsIf DocType = "Sales Tax Payment" Then
		Return Documents.SalesTaxPayment.GetRef(DocUUID);
	ElsIf DocType = "Statement" Then
		Return Documents.Statement.GetRef(DocUUID);
	ElsIf DocType = "Quote" Then
		Return Documents.Quote.GetRef(DocUUID);
	EndIf;

EndFunction

&AtClient
Function OpenDocument(DocRef, DocType)
	
	FormParameters = New Structure("Key", DocRef);
	
	If DocType = "Sales Invoice" Then
		OpenForm("Document.SalesInvoice.ObjectForm", FormParameters);
	ElsIf DocType = "Sales Order" Then
		OpenForm("Document.SalesOrder.ObjectForm", FormParameters);
	ElsIf DocType = "Purchase Return" Then
		OpenForm("Document.PurchaseReturn.ObjectForm", FormParameters);
	ElsIf DocType = "Purchase Order" Then
		OpenForm("Document.PurchaseOrder.ObjectForm", FormParameters);
	ElsIf DocType = "Bill" Then
		OpenForm("Document.PurchaseInvoice.ObjectForm", FormParameters);
	ElsIf DocType = "Item Receipt" Then
		OpenForm("Document.ItemReceipt.ObjectForm", FormParameters);
	ElsIf DocType = "Bill Payment (Check)" Then
		OpenForm("Document.InvoicePayment.ObjectForm", FormParameters);
	ElsIf DocType = "General Journal Entry" Then
		OpenForm("Document.GeneralJournalEntry.ObjectForm", FormParameters);
	ElsIf DocType = "Deposit" Then
		OpenForm("Document.Deposit.ObjectForm", FormParameters);
	ElsIf DocType = "Payment (Check)" Then
		OpenForm("Document.Check.ObjectForm", FormParameters);
	ElsIf DocType = "Cash Sale" Then
		OpenForm("Document.CashSale.ObjectForm", FormParameters);
	ElsIf DocType = "Cash Receipt" Then
		OpenForm("Document.CashReceipt.ObjectForm", FormParameters);
	ElsIf DocType = "Bank Transfer" Then
		OpenForm("Document.BankTransfer.ObjectForm", FormParameters);
	ElsIf DocType = "Bank Reconciliation" Then
		OpenForm("Document.BankReconciliation.ObjectForm", FormParameters);
	ElsIf DocType = "Credit Memo" Then
		OpenForm("Document.SalesReturn.ObjectForm", FormParameters);
	ElsIf DocType = "Item Adjustment" Then
		OpenForm("Document.ItemAdjustment.ObjectForm", FormParameters);
	ElsIf DocType = "Sales Tax Payment" Then
		OpenForm("Document.SalesTaxPayment.ObjectForm", FormParameters);
	ElsIf DocType = "Statement" Then
		OpenForm("Document.Statement.ObjectForm", FormParameters);
	ElsIf DocType = "Quote" Then
		OpenForm("Document.Quote.ObjectForm", FormParameters);
	EndIf;

EndFunction
	