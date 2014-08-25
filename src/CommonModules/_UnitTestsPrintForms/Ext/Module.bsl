&AtServer
Procedure SalesOrderTest1000() Export
	
	TestSO = Documents.SalesOrder.CreateDocument();
	TestCust = Catalogs.Companies.CreateItem();
	TestCust.Description = "test_customer1";
	TestCust.Customer = True;
	TestCust.Write();
	TestAddr = Catalogs.Addresses.CreateItem();
	TestAddr.Owner = TestCust.Ref;
	TestAddr.Description = "Primary";
	TestAddr.DefaultBilling = True;
	TestAddr.DefaultShipping = True;
	TestAddr.Write();
	TestSO.Company = TestCust.Ref;
	TestSO.Number = "code123test";
	TestSO.Date = CurrentSessionDate();
	TestSO.ShipTo = TestAddr.Ref;
	TestSO.BillTo = TestAddr.Ref;
	TestItem = Catalogs.Products.CreateItem();
	TestItem.Code = "test_item1";
	TestItem.Description = "test_item1";
	TestItem.Type = Enums.InventoryTypes.Inventory;
	TestItem.Write();
	line = TestSO.LineItems.Add();
	line.Product = TestItem.Ref;
	line.QtyUnits = 2;
	line.PriceUnits = 100;
	line.Taxable = False;
	TestSO.DocumentTotal = line.PriceUnits * line.QtyUnits;
	TestCurrency = Catalogs.Currencies.CreateItem();
	TestCurrency.Symbol = "$$$";
	TestCurrency.Description = "3dollars";
	TestCurrency.Write();
	TestSO.Currency = TestCurrency.Ref;
	TestSO.Write(DocumentWriteMode.Posting);
	
	spreadsheet = New SpreadsheetDocument;
	PrintData = PrintFormFunctions.PrintSO(spreadsheet,"",TestSO.Ref);
	
	
	TestID = "SOTEST_documentNumber";
	Status = "Fail";
	
	Try
		If PrintData.Get("Number") = TestSO.Number Then
			Status = "Pass";
		EndIf;
	Except
	EndTry;
	
	Reg = InformationRegisters._PrintFormLogs.CreateRecordManager();
	Reg.Period = CurrentSessionDate();
	Reg.TestID = TestID;
	Reg.Result = Status;
	Reg.Write();
	
	TestID = "SOTEST_billName";
	Status = "Fail";
	
	Try
		If PrintData.Get("ThemBill_ThemName") = TestSO.BillTo.Owner.Description Then
			Status = "Pass";
		EndIf;
	Except
	EndTry;
	
	Reg = InformationRegisters._PrintFormLogs.CreateRecordManager();
	Reg.Period = CurrentSessionDate();
	Reg.TestID = TestID;
	Reg.Result = Status;
	Reg.Write();
	
	TestID = "SOTEST_shipzip";
	Status = "Fail";
	
	Try
		If PrintData.Get("ThemShip_ThemShipZIP") = TestSO.ShipTo.ZIP Then
			Status = "Pass";
		EndIf;
	Except
	EndTry;
	
	Reg = InformationRegisters._PrintFormLogs.CreateRecordManager();
	Reg.Period = CurrentSessionDate();
	Reg.TestID = TestID;
	Reg.Result = Status;
	Reg.Write();
	
	TestID = "SOTEST_currency";
	Status = "Fail";
	
	Try
		If PrintData.Get("Currency") = TestSO.Currency.Symbol Then
			Status = "Pass";
		EndIf;
	Except
	EndTry;
	
	Reg = InformationRegisters._PrintFormLogs.CreateRecordManager();
	Reg.Period = CurrentSessionDate();
	Reg.TestID = TestID;
	Reg.Result = Status;
	Reg.Write();
	
	TestID = "SOTEST_Total";
	Status = "Fail";
	
	Try
		If PrintData.Get("Total") = TestSO.Currency.Symbol + String(Format(TestSO.DocumentTotal, "NFD=2; NZ=")) Then
			Status = "Pass";
		EndIf;
	Except
	EndTry;
	
	Reg = InformationRegisters._PrintFormLogs.CreateRecordManager();
	Reg.Period = CurrentSessionDate();
	Reg.TestID = TestID;
	Reg.Result = Status;
	Reg.Write();

EndProcedure

&AtServer
Procedure SalesInvoiceTest1000() Export
	
	TestSI = Documents.SalesInvoice.CreateDocument();
	TestCust = Catalogs.Companies.CreateItem();
	TestCust.Description = "test_customer2";
	TestCust.Customer = True;
	TestCust.Write();
	TestAddr = Catalogs.Addresses.CreateItem();
	TestAddr.Owner = TestCust.Ref;
	TestAddr.Description = "Primary";
	TestAddr.DefaultBilling = True;
	TestAddr.DefaultShipping = True;
	TestAddr.City = "San Francisco";
	TestAddr.AddressLine1 = "123 some road Dr.";
	TestAddr.Write();
	TestSI.Company = TestCust.Ref;
	TestSI.Number = "abc123";
	TestSI.Date = CurrentSessionDate();
	TestSI.ShipTo = TestAddr.Ref;
	TestSI.BillTo = TestAddr.Ref;
	TestItem = Catalogs.Products.CreateItem();
	TestItem.Code = "test_item2";
	TestItem.Description = "test_item2";
	TestItem.Type = Enums.InventoryTypes.NonInventory;
	TestItem.Write();
	line = TestSI.LineItems.Add();
	line.Product = TestItem.Ref;
	line.QtyUnits = 18;
	line.PriceUnits = 11.50;
	line.Taxable = False;
	TestSI.LineSubtotal = line.PriceUnits * line.QtyUnits;
	TestCurrency = Catalogs.Currencies.CreateItem();
	TestCurrency.Symbol = "Q";
	TestCurrency.Description = "Quollas";
	TestCurrency.Write();
	TestSI.Currency = TestCurrency.Ref;
	getARAccount = New Query("SELECT
	                         |	ChartOfAccounts.Ref
							 |FROM
	                         |	ChartOfAccounts.ChartOfAccounts AS ChartOfAccounts
	                         |WHERE
	                         |	ChartOfAccounts.Code = &Code");
	getARAccount.SetParameter("Code","1200");
	ARobject = getARAccount.Execute().Unload();

	TestSI.ARAccount = ARobject[0].Ref;
	TestSI.Write();
	
	spreadsheet = New SpreadsheetDocument;
	PrintData = PrintFormFunctions.PrintSI(spreadsheet,"",TestSI.Ref);
	
	
	TestID = "SITEST_documentNumber";
	Status = "Fail";
	
	Try
		If PrintData.Get("Number") = TestSI.Number Then
			Status = "Pass";
		EndIf;
	Except
	EndTry;
	
	Reg = InformationRegisters._PrintFormLogs.CreateRecordManager();
	Reg.Period = CurrentSessionDate();
	Reg.TestID = TestID;
	Reg.Result = Status;
	Reg.Write();
	
	TestID = "SITEST_billline1";
	Status = "Fail";
	
	Try
		If PrintData.Get("ThemBill_Line1") = TestSI.BillTo.AddressLine1 Then
			Status = "Pass";
		EndIf;
	Except
	EndTry;
	
	Reg = InformationRegisters._PrintFormLogs.CreateRecordManager();
	Reg.Period = CurrentSessionDate();
	Reg.TestID = TestID;
	Reg.Result = Status;
	Reg.Write();
	
	TestID = "SITEST_shipcity";
	Status = "Fail";
	
	Try
		If PrintData.Get("ThemShip_City") = TestSI.ShipTo.City Then
			Status = "Pass";
		EndIf;
	Except
	EndTry;
	
	Reg = InformationRegisters._PrintFormLogs.CreateRecordManager();
	Reg.Period = CurrentSessionDate();
	Reg.TestID = TestID;
	Reg.Result = Status;
	Reg.Write();
	
	TestID = "SITEST_currency";
	Status = "Fail";
	
	Try
		If PrintData.Get("Currency") = TestSI.Currency.Symbol Then
			Status = "Pass";
		EndIf;
	Except
	EndTry;
	
	Reg = InformationRegisters._PrintFormLogs.CreateRecordManager();
	Reg.Period = CurrentSessionDate();
	Reg.TestID = TestID;
	Reg.Result = Status;                                                   
	Reg.Write();
	
	TestID = "SITEST_Total";
	Status = "Fail";
	
	Try
		If PrintData.Get("LineSubtotal") = TestSI.Currency.Symbol + String(Format(TestSI.LineSubtotal, "NFD=2; NZ=")) Then
			Status = "Pass";
		EndIf;
	Except
	EndTry;
	
	Reg = InformationRegisters._PrintFormLogs.CreateRecordManager();
	Reg.Period = CurrentSessionDate();
	Reg.TestID = TestID;
	Reg.Result = Status;
	Reg.Write();

EndProcedure

