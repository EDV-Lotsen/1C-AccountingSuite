
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	InvoicePayList.Parameters.SetParameterValue("Doc", Parameters.Filter.InvoisPays);

EndProcedure
