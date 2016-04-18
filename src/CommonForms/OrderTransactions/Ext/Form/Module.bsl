
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	Transactions.Parameters.SetParameterValue("Order", Parameters.Filter.Order);
	If Constants.UseSOPrepayment.Get() Then 
		Items.TransactionsAmount.Visible = False;
	Else 	
		Items.TransactionsAmount.Visible = True;
	EndIf;	
EndProcedure
