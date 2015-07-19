
&AtClient
Procedure CreateBankTransactions(Command)
	CreateBankTransactionsAtServer();
EndProcedure

&AtServer
Procedure CreateBankTransactionsAtServer()
	DPObject = FormAttributeToValue("Object");
	DPObject.AddSampleBankTransactions(BankAccount, StartDate, EndDate);
EndProcedure
