
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
	for i = 1002 to 1010 do	 // 1000
		ProcedureName = "_UnitTestsPriceMatrix.PriceMatrix" + Format(i,"NG=0") + "()";
		Execute(ProcedureName);	
	enddo
	
EndProcedure
