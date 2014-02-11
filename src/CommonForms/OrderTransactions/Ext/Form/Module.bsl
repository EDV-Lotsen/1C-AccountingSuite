
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	Transactions.Parameters.SetParameterValue("Order", Parameters.Filter.Order);
EndProcedure
