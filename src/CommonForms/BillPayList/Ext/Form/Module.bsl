
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	BillPaymentList.Parameters.SetParameterValue("Doc", Parameters.Filter.BillPays);

EndProcedure
