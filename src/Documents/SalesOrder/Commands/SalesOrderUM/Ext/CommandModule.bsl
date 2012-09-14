
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	УправлениеПечатьюКлиент.ВыполнитьКомандуПечати("Document.SalesOrder",
     "SalesOrderUM", CommandParameter, CommandExecuteParameters, Неопределено);
	 
EndProcedure
