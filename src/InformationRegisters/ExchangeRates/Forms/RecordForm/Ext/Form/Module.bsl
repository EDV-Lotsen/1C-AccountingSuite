
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Record.Currency.IsEmpty() Then
		Record.Currency = Constants.DefaultCurrency.Get();
	EndIf;
	
EndProcedure