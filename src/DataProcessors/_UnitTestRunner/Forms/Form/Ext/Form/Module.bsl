
&AtClient
Procedure Run(Command)
	RunAtServer();
EndProcedure

&AtServer
Procedure RunAtServer()
	
	//_UnitTestsPriceMatrix.InitializePriceLevels();
	//_UnitTestsPriceMatrix.InitializeProductCategories();
	//_UnitTestsPriceMatrix.InitializeProducts();
	//_UnitTestsPriceMatrix.InitializeCustomers();
	//_UnitTestsPriceMatrix.InitializePriceMatrix();
	for i = 1000 to 1004 do	
		ProcedureName = "_UnitTestsPriceMatrix.PriceMatrix" + Format(i,"NG=0") + "()";
		Выполнить(ProcedureName);	
	enddo
	
EndProcedure
