
&AtClient
Procedure Run(Command)
	RunAtServer();
EndProcedure

&AtServer
Procedure RunAtServer()
	for i = 1000 to 1000 do	
		ProcedureName = "_UnitTestsPrintForms.SalesOrderTest" + Format(i,"NG=0") + "()";
		Выполнить(ProcedureName);	
	enddo;
	
	for i = 1000 to 1000 do	
		ProcedureName = "_UnitTestsPrintForms.SalesInvoiceTest" + Format(i,"NG=0") + "()";
		Выполнить(ProcedureName);	
	enddo;
EndProcedure
