
&AtClient
Procedure Cancel(Command)
	
	Close();
	
EndProcedure

&AtClient
Procedure SelectFile(Command)
	
	ReturnParameters = New Structure;
	ReturnParameters.Insert("PurchaseVAT", PurchaseVAT);
    ReturnParameters.Insert("SalesVAT", SalesVAT);
	
	Close(ReturnParameters);

EndProcedure
