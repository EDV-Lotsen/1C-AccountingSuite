
Procedure OnCopy(CopiedObject)
	SalesInvoice = Documents.SalesInvoice.EmptyRef();
	SalesOrder = Documents.SalesOrder.EmptyRef();
	If  CopiedObject.InvoiceStatus = Enums.TimeTrackStatus.Billed Then
		   InvoiceStatus = Enums.TimeTrackStatus.Unbilled;
	EndIf;
		
EndProcedure
