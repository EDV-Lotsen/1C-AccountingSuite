
&AtClient
Procedure Run(Command)
	
	//FormObject = CashReceiptTestPrep();
	//RunAtServer(FormObject);
	RunAtServer();
EndProcedure

&AtClient
Function CashReceiptTestPrep()
	TestForm = GetForm("Document.CashReceipt.ObjectForm");
	Return TestForm.Object;
EndFunction


//&AtServer
//Procedure RunAtServer(FormObject)
//	
//	//_UnitTestsPriceMatrix.InitializePriceLevels();
//	//_UnitTestsPriceMatrix.InitializeProductCategories();
//	//_UnitTestsPriceMatrix.InitializeProducts();
//	//_UnitTestsPriceMatrix.InitializeCustomers();
//	//_UnitTestsPriceMatrix.InitializePriceMatrix();
//	//for i = 1000 to 1004 do	
//	//	ProcedureName = "_UnitTestsPriceMatrix.PriceMatrix" + Format(i,"NG=0") + "()";
//	//	Выполнить(ProcedureName);	
//	//enddo
//	
//	// Cash Receipt Tests //
//	
//	//_UnitTestsCashReceipt.InitializeProduct();
//	//_UnitTestsCashReceipt.InitializeCompany();
//	//_UnitTestsCashReceipt.InitializeCashReceipt();
//	//_UnitTestsCashReceipt.IntializeSalesInvoice();
//	//_UnitTestsCashReceipt.InitializeCreditMemo();
//	
//	//For i = 1000 to 1019 Do
//	//	ProcedureName = "_UnitTestsCashReceipt.CashReceipt" + Format(i,"NG=0") + "(FormObject)";
//	//	Execute(ProcedureName);
//	//EndDo;

//	
//EndProcedure

&AtServer
Procedure RunAtServer()
	
	ApiWebServices.inoutVendor1099("{""object_code"":""2014""}");
	
EndProcedure
