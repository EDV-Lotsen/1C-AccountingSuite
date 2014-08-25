
&AtClient
Procedure AcceptButton(Command)
	UpdateSessionParameter(InvoiceDate);
	ThisForm.Close(InvoiceDate);
EndProcedure

&AtServer
Procedure UpdateSessionParameter(InvoiceDate)
	SessionParameters.TimeTrackToInvoiceDate = InvoiceDate;
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	InvoiceDate = SessionParameters.TimeTrackToInvoiceDate;	
EndProcedure
