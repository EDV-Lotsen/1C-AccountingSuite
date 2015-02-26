&AtServer
Procedure InitializeCompany() Export
	
	NewCompany = Catalogs.Companies.CreateItem();	
	NewCompany.Description = "TestCompany";
	NewCompany.Customer = True;
	NewCompany.DefaultCurrency = Constants.DefaultCurrency.Get();
	NewCompany.Terms = Catalogs.PaymentTerms.Net30;
	NewCompany.Write();	
	AddressLine = Catalogs.Addresses.CreateItem();
	AddressLine.Owner = NewCompany.Ref;
	AddressLine.Description = "Primary";
	AddressLine.Write();
	
EndProcedure

&AtServer
Procedure InitializeProduct() Export
	
	NewProduct = Catalogs.Products.CreateItem();
	NewProduct.Type = Enums.InventoryTypes.NonInventory;
	NewProduct.Code = "Shoe Shining";
	NewProduct.Description = "Basic care shoe shining";
	NewProduct.IncomeAccount = Constants.IncomeAccount.Get();
	NewProduct.InventoryOrExpenseAccount = GeneralFunctions.InventoryAcct(Enums.InventoryTypes.NonInventory);
	NewProduct.COGSAccount = GeneralFunctions.GetEmptyAcct();
	NewProduct.Write();	

EndProcedure

&AtServer
Procedure IntializeSalesInvoice() Export
	NewInvoice = Documents.SalesInvoice.CreateDocument();
	NewInvoice.Company = Catalogs.Companies.FindByDescription("TestCompany");
	NewInvoice.Date = CurrentDate();
	NewInvoice.Terms = Catalogs.PaymentTerms.Net30;
	NewInvoice.DueDate = CurrentDate() + + 60*60*24*30;
	NewInvoice.ShipTo = Catalogs.Addresses.FindByDescription("Primary",,,Catalogs.Companies.FindByDescription("TestCompany"));
	NewInvoice.BillTo = Catalogs.Addresses.FindByDescription("Primary",,,Catalogs.Companies.FindByDescription("TestCompany"));
	NewInvoice.LocationActual = GeneralFunctions.GetDefaultLocation();
	DefaultCurrency = GeneralFunctionsReusable.DefaultCurrency();
	NewInvoice.Currency = DefaultCurrency;
	NewInvoice.ExchangeRate = GeneralFunctions.GetExchangeRate(CurrentDate(), DefaultCurrency);
	NewInvoice.ARAccount = GeneralFunctionsReusable.DefaultCurrency().DefaultARAccount;
	NewInvoice.Number = "Testing";
	NewLineItem = NewInvoice.LineItems.Add();
	Product = Catalogs.Products.FindByCode("Shoe Shining");
	NewLineItem.Product = Product;
	NewLineItem.ProductDescription = Product.Description;
	NewLineItem.QtyUnits = 1;
	NewLineItem.Unit = Constants.DefaultUoMSet.Get().DefaultSaleUnit;
	NewLineItem.PriceUnits = 20;
	NewLineItem.LineTotal = 20;
	NewLineItem.LocationActual = NewInvoice.LocationActual;
	NewInvoice.LineSubtotal = 20;
	NewInvoice.DocumentTotal = 20;
	NewInvoice.DocumentTotalRC = 20;
	NewInvoice.Write(DocumentWriteMode.Posting);
	
EndProcedure

&AtServer
Procedure InitializeCashReceipt() Export
	
	NewCashReceipt = Documents.CashReceipt.CreateDocument();
	NewCashReceipt.Date = CurrentDate();
	NewCashReceipt.Number = "TestIt";
	NewCashReceipt.DepositType = "1";
	NewCashReceipt.Company = Catalogs.Companies.FindByDescription("TestCompany");
	NewCashReceipt.BankAccount = Constants.UndepositedFundsAccount.Get();
	DefaultCurrency = GeneralFunctionsReusable.DefaultCurrency();
	NewCashReceipt.ARAccount = DefaultCurrency.DefaultARAccount;
	NewCashReceipt.Write();
EndProcedure

&AtServer
Procedure InitializeCreditMemo() Export
	NewCreditMemo = Documents.SalesReturn.CreateDocument();
	NewCreditMemo.Company = Catalogs.Companies.FindByDescription("TestCompany");
	NewCreditMemo.Number = "Testing";
	NewCreditMemo.Date = CurrentDate();
	NewCreditMemo.Location = GeneralFunctions.GetDefaultLocation();
	NewCreditMemo.ReturnType = Enums.ReturnTypes.CreditMemo;
	DefaultCurrency = GeneralFunctionsReusable.DefaultCurrency();
	NewCreditMemo.Currency = DefaultCurrency;
	NewCreditMemo.ExchangeRate = GeneralFunctions.GetExchangeRate(CurrentDate(), DefaultCurrency);
	NewCreditMemo.ARAccount = DefaultCurrency.DefaultARAccount;
	NewLineItem = NewCreditMemo.LineItems.Add();
	Product = Catalogs.Products.FindByCode("Shoe Shining");
	NewLineItem.Product = Product;
	NewLineItem.ProductDescription = Product.Description;
	NewLineItem.QtyUnits = 1;
	NewLineItem.Unit = Constants.DefaultUoMSet.Get().DefaultSaleUnit;
	NewLineItem.PriceUnits = 10;
	NewLineItem.LineTotal = 10;
	NewCreditMemo.LineSubtotal = 10;
	NewCreditMemo.DocumentTotal = 10;
	NewCreditMemo.DocumentTotalRC = 10;
	NewCreditMemo.Write(DocumentWriteMode.Posting);
	
EndProcedure

////// TESTS BEGIN HERE //////

// Section 1: Test CashPaymentCalculation()
// Summary: CashPaymentCalculation() is used to set the proper values for 
//				UnappliedPayment, DocumentTotal, and DocumentTotalRC given a CashPayment

&AtServer
// Tests when CashPaymentCalculation is give an invalid object structure as a parameter
// In this case, a string is passed into the structure parameter instead of an object structure
// If the function FAILS, then the test should pass as this is expected behavior
Procedure CashReceipt1000(CashReceiptObjectStruct) Export
	
	TestID = "CashReceipt1000";
	Status = "Pass";
	CashReceiptObject = Documents.CashReceipt.FindByNumber("TestIt").GetObject();
	ValueToFormData(CashReceiptObject,CashReceiptObjectStruct);

	CashReceiptObjectStruct.CashPayment = 500;
	CashReceiptObjectStruct.ExchangeRate = 1;
	Try
		CashReceiptMethods.CashPaymentCalculation("InvalidObject",True);
			If CashReceiptObjectStruct.UnappliedPayment = CashReceiptObjectStruct.CashPayment AND
				CashReceiptObjectStruct.DocumentTotal = CashReceiptObjectStruct.CashPayment AND
				CashReceiptObjectStruct.DocumentTotalRC = CashReceiptObjectStruct.CashPayment * CashReceiptObjectStruct.ExchangeRate Then
				
				Status = "Fail";
				
			EndIf;
	Except
	EndTry;
	
	Reg = InformationRegisters._UnitTestLog.CreateRecordManager();
	Reg.Period = CurrentDate();
	Reg.TestID = TestID;
	Reg.Result = Status;
	Reg.Write();	
	
EndProcedure

&AtServer
// Tests when CashPaymentCalculation is give an invalid PayRef structure as a parameter
// PayRef determines whether the object attributes have been altered for the first time since the cash receipt form was created
// In this case, a string is passed into the structure parameter instead of a boolean
// If the function FAILS, then the test should pass as this is expected behavior
Procedure CashReceipt1001(CashReceiptObjectStruct) Export
	
	TestID = "CashReceipt1001";
	Status = "Pass";
	CashReceiptObject = Documents.CashReceipt.FindByNumber("TestIt").GetObject();
	ValueToFormData(CashReceiptObject,CashReceiptObjectStruct);

	CashReceiptObjectStruct.CashPayment = 500;
	CashReceiptObjectStruct.ExchangeRate = 1;
	Try
		CashReceiptMethods.CashPaymentCalculation(CashReceiptObjectStruct,"NotABoolean");
			If CashReceiptObjectStruct.UnappliedPayment = CashReceiptObject.CashPayment AND
				CashReceiptObjectStruct.DocumentTotal = CashReceiptObjectStruct.CashPayment AND
				CashReceiptObjectStruct.DocumentTotalRC = CashReceiptObjectStruct.CashPayment * CashReceiptObjectStruct.ExchangeRate Then
				
				Status = "Fail";
				
			EndIf;
	Except
	EndTry;
	
	Reg = InformationRegisters._UnitTestLog.CreateRecordManager();
	Reg.Period = CurrentDate();
	Reg.TestID = TestID;
	Reg.Result = Status;
	Reg.Write();	
	
EndProcedure

&AtServer
// Tests CashPaymentCalculation in the case where it is called with a given cash payment(500)
// In this case, we assume there are no line items in the Cash Receipt, as such, expected behavior is:
//      - UnappliedPayment is equal to the CashPayment (there are no line items to pay)
//		- DocumentTotal is equal to the CashPayment
//		- This case uses an exchange rate of 1 so DocumentTotalRC should also equal CashPayment
// If all those are fulfilled, the test will pass
Procedure CashReceipt1002(CashReceiptObjectStruct) Export
	
	TestID = "CashReceipt1002";
	Status = "Fail";
	CashReceiptObject = Documents.CashReceipt.FindByNumber("TestIt").GetObject();
	ValueToFormData(CashReceiptObject,CashReceiptObjectStruct);
	
	CashReceiptObjectStruct.CashPayment = 500;
	CashReceiptObjectStruct.ExchangeRate = 1;
	Try
		CashReceiptMethods.CashPaymentCalculation(CashReceiptObjectStruct,True);
			If CashReceiptObjectStruct.UnappliedPayment = CashReceiptObjectStruct.CashPayment AND
				CashReceiptObjectStruct.DocumentTotal = CashReceiptObjectStruct.CashPayment AND
				CashReceiptObjectStruct.DocumentTotalRC = CashReceiptObjectStruct.CashPayment * CashReceiptObjectStruct.ExchangeRate Then
				
				Status = "Pass";
				
			EndIf;
	Except
	EndTry;
	
	Reg = InformationRegisters._UnitTestLog.CreateRecordManager();
	Reg.Period = CurrentDate();
	Reg.TestID = TestID;
	Reg.Result = Status;
	Reg.Write();	
	
EndProcedure

&AtServer
// Tests CashPaymentCalculation in the case where it is called with a given cash payment(500)
// In this case, we assume there is 1 line item in the Cash Receipt, as such, expected behavior is:
//      - UnappliedPayment is equal to the CashPayment minus the line item payment
//		- DocumentTotal is equal to the CashPayment
//		- This case uses an exchange rate of 1 so DocumentTotalRC should also equal CashPayment
// If all those are fulfilled, the test will pass
Procedure CashReceipt1003(CashReceiptObjectStruct) Export
	
	TestID = "CashReceipt1003";
	Status = "Fail";
	CashReceiptObject = Documents.CashReceipt.FindByNumber("TestIt").GetObject();
	ValueToFormData(CashReceiptObject,CashReceiptObjectStruct);
	
	CashReceiptObjectStruct.CashPayment = 500;
	CashReceiptObjectStruct.ExchangeRate = 1;
	NewLineItem = CashReceiptObjectStruct.LineItems.Add();
	NewLineItem.Document = Documents.SalesInvoice.FindByNumber("Testing");
	
	Try
		CashReceiptMethods.CashPaymentCalculation(CashReceiptObjectStruct,True);
			If CashReceiptObjectStruct.UnappliedPayment = CashReceiptObjectStruct.CashPayment - CashReceiptObjectStruct.LineItems.Total("Payment") AND
				CashReceiptObjectStruct.DocumentTotal = CashReceiptObjectStruct.CashPayment AND
				CashReceiptObjectStruct.DocumentTotalRC = CashReceiptObjectStruct.CashPayment * CashReceiptObjectStruct.ExchangeRate Then
				
				Status = "Pass";
				
			EndIf;
	Except
	EndTry;

	Reg = InformationRegisters._UnitTestLog.CreateRecordManager();
	Reg.Period = CurrentDate();
	Reg.TestID = TestID;
	Reg.Result = Status;
	Reg.Write();
EndProcedure

&AtServer
// Tests CashPaymentCalculation in the case where it is called with a given cash payment(500)
// In this case, we assume there are multiple(3) line items in the Cash Receipt, as such, expected behavior is:
//      - UnappliedPayment is equal to the CashPayment minus the line item payments
//		- DocumentTotal is equal to the CashPayment
//		- This case uses an exchange rate of 1 so DocumentTotalRC should also equal CashPayment
// If all those are fulfilled, the test will pass
Procedure CashReceipt1004(CashReceiptObjectStruct) Export
	
	TestID = "CashReceipt1004";
	Status = "Fail";
	CashReceiptObject = Documents.CashReceipt.FindByNumber("TestIt").GetObject();
	ValueToFormData(CashReceiptObject,CashReceiptObjectStruct);
	
	CashReceiptObjectStruct.CashPayment = 500;
	CashReceiptObjectStruct.ExchangeRate = 1;
	NewLineItem = CashReceiptObjectStruct.LineItems.Add();
	NewLineItem.Document = Documents.SalesInvoice.FindByNumber("Testing");
	NewLineItem.BalanceFCY2 = 20;
	NewLineItem2 = CashReceiptObjectStruct.LineItems.Add();
	NewLineItem2.Document = Documents.SalesInvoice.FindByNumber("Testing");
	NewLineItem2.BalanceFCY2 = 20;
	NewLineItem3 = CashReceiptObjectStruct.LineItems.Add();
	NewLineItem3.Document = Documents.SalesInvoice.FindByNumber("Testing");
	NewLineItem3.BalanceFCY2 = 20;
	
	Try
		CashReceiptMethods.CashPaymentCalculation(CashReceiptObjectStruct,True);
			If CashReceiptObjectStruct.UnappliedPayment = CashReceiptObjectStruct.CashPayment - CashReceiptObjectStruct.LineItems.Total("Payment") AND
				CashReceiptObjectStruct.DocumentTotal = CashReceiptObjectStruct.CashPayment AND
				CashReceiptObjectStruct.DocumentTotalRC = CashReceiptObjectStruct.CashPayment * CashReceiptObjectStruct.ExchangeRate Then
				
				Status = "Pass";
				
			EndIf;
	Except
	EndTry;

	Reg = InformationRegisters._UnitTestLog.CreateRecordManager();
	Reg.Period = CurrentDate();
	Reg.TestID = TestID;
	Reg.Result = Status;
	Reg.Write();
EndProcedure

// Section 2: Test AdditionalCreditPay()
// Summary: AdditionalCreditPay() is used to distribute credit over documents where a payment can be made
// Example: Cash Receipt has 2 invoices with a balance of 10 and a credit memo with a balance of 15
// 			Invoice 1 Balance = 10 Payment = 0
//          Invoice 2 Balance = 10 Payment = 0
//		
//			After applying the credit memo of 15, expected outcome should be:
//			Invoice 1 Balance = 10 Payment = 10
//			Invoice 2 Balance = 10 Payment = 5
//
// CashPaymentCalculation is used in supplement for testing to set and check the object attributes after distribution

&AtServer
// Tests AdditionalCreditPay() with the following case:
//		- cash payment of 500
//		- a credit memo is added with a balance of 10 and a payment of 10
//		- exchange rate of 1
//
// Expected output:
// 		- since there are no line items, the credit memo will be directly applied to UnappliedPayment
//		- UnappliedPayment = CashPayment + credit memo
//		- DocumentTotal = UnappliedPayment
//		- since the exchange rate is 1, DocumentTotalRC = UnappliedPayment
Procedure CashReceipt1005(CashReceiptObjectStruct) Export

	TestID = "CashReceipt1005";
	Status = "Fail";
	CashReceiptObject = Documents.CashReceipt.FindByNumber("TestIt").GetObject();
	ValueToFormData(CashReceiptObject,CashReceiptObjectStruct);
	
	CashReceiptObjectStruct.CashPayment = 500;
	CashReceiptObjectStruct.ExchangeRate = 1;
	NewCreditItem = CashReceiptObjectStruct.CreditMemos.Add();
	NewCreditItem.Document = Documents.SalesReturn.FindByNumber("Testing");
	NewCreditItem.BalanceFCY2 = 10;
	NewCreditItem.Payment = 10;

	Try
		CashReceiptMethods.AdditionalCreditPay(CashReceiptObjectStruct,0,10,10,False);
		CashReceiptMethods.CashPaymentCalculation(CashReceiptObjectStruct,True);
			If CashReceiptObjectStruct.UnappliedPayment = CashReceiptObjectStruct.CashPayment + CashReceiptObjectStruct.CreditMemos.Total("Payment") AND
				CashReceiptObjectStruct.DocumentTotal = CashReceiptObjectStruct.UnappliedPayment AND
				CashReceiptObjectStruct.DocumentTotalRC = CashReceiptObjectStruct.UnappliedPayment * CashReceiptObjectStruct.ExchangeRate Then
				
				Status = "Pass";
				
			EndIf;
	Except
	EndTry;

	Reg = InformationRegisters._UnitTestLog.CreateRecordManager();
	Reg.Period = CurrentDate();
	Reg.TestID = TestID;
	Reg.Result = Status;
	Reg.Write();
	
EndProcedure

&AtServer
// Tests AdditionalCreditPay() with the following case:
//		- cash payment of 500
//		- a credit memo is added with a balance of 10 and a payment of 10
//		- an additional credit memo with a balance of 5 and a payment of 5
//		- exchange rate of 1
//
// Expected output:
// 		- since there are no line items, the credit memos will be directly applied to UnappliedPayment
//		- UnappliedPayment = CashPayment + credit memos
//		- DocumentTotal = UnappliedPayment
//		- since the exchange rate is 1, DocumentTotalRC = UnappliedPayment
Procedure CashReceipt1006(CashReceiptObjectStruct) Export
	
	TestID = "CashReceipt1006";
	Status = "Fail";
	CashReceiptObject = Documents.CashReceipt.FindByNumber("TestIt").GetObject();
	ValueToFormData(CashReceiptObject,CashReceiptObjectStruct);
	
	CashReceiptObjectStruct.CashPayment = 500;
	CashReceiptObjectStruct.ExchangeRate = 1;
	NewCreditItem = CashReceiptObjectStruct.CreditMemos.Add();
	NewCreditItem.Document = Documents.SalesReturn.FindByNumber("Testing");
	NewCreditItem.BalanceFCY2 = 10;
	NewCreditItem.Payment = 10;
	NewCreditItem2 = CashReceiptObjectStruct.CreditMemos.Add();
	NewCreditItem2.Document = Documents.SalesReturn.FindByNumber("Testing");
	NewCreditItem2.BalanceFCY2 = 5;
	NewCreditItem2.Payment = 5;


	Try
		CashReceiptMethods.AdditionalCreditPay(CashReceiptObjectStruct,0,10,10,False);
		CashReceiptMethods.CashPaymentCalculation(CashReceiptObjectStruct,True);
			If CashReceiptObjectStruct.UnappliedPayment = CashReceiptObjectStruct.CashPayment + CashReceiptObjectStruct.CreditMemos.Total("Payment") AND
				CashReceiptObjectStruct.DocumentTotal = CashReceiptObjectStruct.UnappliedPayment AND
				CashReceiptObjectStruct.DocumentTotalRC = CashReceiptObjectStruct.UnappliedPayment * CashReceiptObjectStruct.ExchangeRate Then
				
				Status = "Pass";
				
			EndIf;
	Except
	EndTry;

	Reg = InformationRegisters._UnitTestLog.CreateRecordManager();
	Reg.Period = CurrentDate();
	Reg.TestID = TestID;
	Reg.Result = Status;
	Reg.Write();

EndProcedure

&AtServer
// Tests AdditionalCreditPay() with the following case:
//		- cash payment of 500
//		- a credit memo is added with a balance of 10 and a payment of 10
//		- an additional credit memo with a balance of 5 and a payment of 5
//		- an invoice line item with a balance of 20
//		- exchange rate of 1
//
// Expected output:
// 		- the total credit of 15 should be applied to the invoice balance of 20
//			- there is a leftover balance of 5, which will be paid off by the cash payment, 
//				leaving an unapplied balance of 495
Procedure CashReceipt1007(CashReceiptObjectStruct) Export
	
	TestID = "CashReceipt1007";
	Status = "Fail";
	CashReceiptObject = Documents.CashReceipt.FindByNumber("TestIt").GetObject();
	ValueToFormData(CashReceiptObject,CashReceiptObjectStruct);
	
	CashReceiptObjectStruct.CashPayment = 500;
	CashReceiptObjectStruct.ExchangeRate = 1;
	NewCreditItem = CashReceiptObjectStruct.CreditMemos.Add();
	NewCreditItem.Document = Documents.SalesReturn.FindByNumber("Testing");
	NewCreditItem.BalanceFCY2 = 10;
	NewCreditItem.Payment = 10;
	NewCreditItem2 = CashReceiptObjectStruct.CreditMemos.Add();
	NewCreditItem2.Document = Documents.SalesReturn.FindByNumber("Testing");
	NewCreditItem2.BalanceFCY2 = 5;
	NewCreditItem2.Payment = 5;
	
	NewLineItem = CashReceiptObjectStruct.LineItems.Add();
	NewLineItem.Document = Documents.SalesInvoice.FindByNumber("Testing");
	NewLineItem.BalanceFCY2 = 20;


	Try
		CashReceiptMethods.AdditionalCreditPay(CashReceiptObjectStruct,0,10,10,False);
		CashReceiptMethods.CashPaymentCalculation(CashReceiptObjectStruct,True);
		If CashReceiptObjectStruct.UnappliedPayment = CashReceiptObjectStruct.CashPayment - CashReceiptObjectStruct.LineItems.Total("Payment") + CashReceiptObjectStruct.CreditMemos.Total("Payment") AND
			CashReceiptObjectStruct.DocumentTotal = CashReceiptObjectStruct.UnappliedPayment + (CashReceiptObjectStruct.LineItems.Total("Payment") - CashReceiptObjectStruct.CreditMemos.Total("Payment")) AND
			CashReceiptObjectStruct.DocumentTotalRC = CashReceiptObjectStruct.UnappliedPayment * CashReceiptObjectStruct.ExchangeRate + (CashReceiptObjectStruct.LineItems.Total("Payment") - CashReceiptObjectStruct.CreditMemos.Total("Payment")) * CashReceiptObjectStruct.ExchangeRate Then
			
			Status = "Pass";
			
		EndIf;
	Except
	EndTry;

	Reg = InformationRegisters._UnitTestLog.CreateRecordManager();
	Reg.Period = CurrentDate();
	Reg.TestID = TestID;
	Reg.Result = Status;
	Reg.Write();

EndProcedure

&AtServer
// Tests AdditionalCreditPay() with the following case:
//		- cash payment of 500
//		- a credit memo is added with a balance of 10 and a payment of 10
//		- an additional credit memo with a balance of 5 and a payment of 5
//		- an invoice line item with a balance of 20
//		- an invoice line item with a balance of 20
//		- exchange rate of 1
//
// Expected output:
// 		- the total credit of 30 should be applied to the first invoice balance of 20
//			- there is a leftover balance of 10 which is then applied to the second invoice with a balance of 20
//		- the second invoice has a remaining balance of 10 which is paid by the cash payment
//		- the unapplied balance should be the cashpayment - total payment + credit payment 
Procedure CashReceipt1008(CashReceiptObjectStruct) Export
	
	TestID = "CashReceipt1008";
	Status = "Fail";
	CashReceiptObject = Documents.CashReceipt.FindByNumber("TestIt").GetObject();
	ValueToFormData(CashReceiptObject,CashReceiptObjectStruct);
	
	CashReceiptObjectStruct.CashPayment = 500;
	CashReceiptObjectStruct.ExchangeRate = 1;
	NewCreditItem = CashReceiptObjectStruct.CreditMemos.Add();
	NewCreditItem.Document = Documents.SalesReturn.FindByNumber("Testing");
	NewCreditItem.BalanceFCY2 = 25;
	NewCreditItem.Payment = 25;
	NewCreditItem2 = CashReceiptObjectStruct.CreditMemos.Add();
	NewCreditItem2.Document = Documents.SalesReturn.FindByNumber("Testing");
	NewCreditItem2.BalanceFCY2 = 5;
	NewCreditItem2.Payment = 5;
	
	NewLineItem = CashReceiptObjectStruct.LineItems.Add();
	NewLineItem.Document = Documents.SalesInvoice.FindByNumber("Testing");
	NewLineItem.BalanceFCY2 = 20;
	
	NewLineItem2 = CashReceiptObjectStruct.LineItems.Add();
	NewLineItem2.Document = Documents.SalesInvoice.FindByNumber("Testing");
	NewLineItem2.BalanceFCY2 = 20;



	Try
		CashReceiptMethods.AdditionalCreditPay(CashReceiptObjectStruct,0,10,10,False);
		CashReceiptMethods.CashPaymentCalculation(CashReceiptObjectStruct,True);
		If CashReceiptObjectStruct.UnappliedPayment = CashReceiptObjectStruct.CashPayment - CashReceiptObjectStruct.LineItems.Total("Payment") + CashReceiptObjectStruct.CreditMemos.Total("Payment") AND
			CashReceiptObjectStruct.DocumentTotal = CashReceiptObjectStruct.UnappliedPayment + (CashReceiptObjectStruct.LineItems.Total("Payment") - CashReceiptObjectStruct.CreditMemos.Total("Payment")) AND
			CashReceiptObjectStruct.DocumentTotalRC = CashReceiptObjectStruct.UnappliedPayment * CashReceiptObjectStruct.ExchangeRate + (CashReceiptObjectStruct.LineItems.Total("Payment") - CashReceiptObjectStruct.CreditMemos.Total("Payment")) * CashReceiptObjectStruct.ExchangeRate Then
			
			Status = "Pass";
			
		EndIf;
	Except
	EndTry;


	Reg = InformationRegisters._UnitTestLog.CreateRecordManager();
	Reg.Period = CurrentDate();
	Reg.TestID = TestID;
	Reg.Result = Status;
	Reg.Write();
	
EndProcedure

// Section 3: Test AdditionalPaymentCall()
// Summary: AdditionalPaymentCall() is a supplement function used to determine DocumentTotal and DocumentTotalRC and CashPayment
//				whenever a change is made on the Cash Receipt form

&AtServer
// Tests AdditionalPaymentCall() with the following case:
//		- an invoice line item with a balance of 20 and payment of 20
//		- exchange rate of 2
//
// Expected output:
// 		- CashPayment, DocumentTotal and DocumentTotalRC should be updated respectively
//		- CashPayment will be set to the line item payment
//		- DocumentTotal will be set to the amount paid (minus any applied credits, in this case none) plus the UnappliedPayment
//		- DocumentTotalRC will be set the same as DocumentTotal but with an exchange rate of 2 in consideration
Procedure CashReceipt1009(CashReceiptObjectStruct) Export

	TestID = "CashReceipt1009";
	Status = "Fail";
	CashReceiptObject = Documents.CashReceipt.FindByNumber("TestIt").GetObject();
	ValueToFormData(CashReceiptObject,CashReceiptObjectStruct);
	
	CashReceiptObjectStruct.ExchangeRate = 2;
	
	NewLineItem = CashReceiptObjectStruct.LineItems.Add();
	NewLineItem.Document = Documents.SalesInvoice.FindByNumber("Testing");
	NewLineItem.BalanceFCY2 = 20;
	NewLineItem.Payment = 20;


	Try
		CashReceiptMethods.AdditionalPaymentCall(CashReceiptObjectStruct,False);
		If CashReceiptObjectStruct.UnappliedPayment = CashReceiptObjectStruct.CashPayment - CashReceiptObjectStruct.LineItems.Total("Payment") + CashReceiptObjectStruct.CreditMemos.Total("Payment") AND
			CashReceiptObjectStruct.DocumentTotal = CashReceiptObjectStruct.UnappliedPayment + (CashReceiptObjectStruct.LineItems.Total("Payment") - CashReceiptObjectStruct.CreditMemos.Total("Payment")) AND
			CashReceiptObjectStruct.DocumentTotalRC = CashReceiptObjectStruct.UnappliedPayment * CashReceiptObjectStruct.ExchangeRate + (CashReceiptObjectStruct.LineItems.Total("Payment") - CashReceiptObjectStruct.CreditMemos.Total("Payment")) * CashReceiptObjectStruct.ExchangeRate Then
			
			Status = "Pass";
			
		EndIf;
	Except
	EndTry;
	
	Reg = InformationRegisters._UnitTestLog.CreateRecordManager();
	Reg.Period = CurrentDate();
	Reg.TestID = TestID;
	Reg.Result = Status;
	Reg.Write();
	
EndProcedure

&AtServer
// Tests AdditionalPaymentCall() with the following case:
//		- an invoice line item with a balance of 20 and payment of 20
//		- an invoice line item with a balance of 10 and payment of 10
//		- exchange rate of 2
//
// Expected output:
// 		- CashPayment, DocumentTotal and DocumentTotalRC should be updated respectively
//		- CashPayment will be set to the line item payments
//		- DocumentTotal will be set to the amount paid (minus any applied credits, in this case none) plus the UnappliedPayment
//		- DocumentTotalRC will be set the same as DocumentTotal but with an exchange rate of 2 in consideration
Procedure CashReceipt1010(CashReceiptObjectStruct) Export

	TestID = "CashReceipt1010";
	Status = "Fail";
	CashReceiptObject = Documents.CashReceipt.FindByNumber("TestIt").GetObject();
	ValueToFormData(CashReceiptObject,CashReceiptObjectStruct);
	
	CashReceiptObjectStruct.ExchangeRate = 2;
	
	NewLineItem = CashReceiptObjectStruct.LineItems.Add();
	NewLineItem.Document = Documents.SalesInvoice.FindByNumber("Testing");
	NewLineItem.BalanceFCY2 = 20;
	NewLineItem.Payment = 20;
	
	NewLineItem2 = CashReceiptObjectStruct.LineItems.Add();
	NewLineItem2.Document = Documents.SalesInvoice.FindByNumber("Testing");
	NewLineItem2.BalanceFCY2 = 10;
	NewLineItem2.Payment = 10;

	Try
		CashReceiptMethods.AdditionalPaymentCall(CashReceiptObjectStruct,False);
		If CashReceiptObjectStruct.UnappliedPayment = CashReceiptObjectStruct.CashPayment - CashReceiptObjectStruct.LineItems.Total("Payment") + CashReceiptObjectStruct.CreditMemos.Total("Payment") AND
			CashReceiptObjectStruct.DocumentTotal = CashReceiptObjectStruct.UnappliedPayment + (CashReceiptObjectStruct.LineItems.Total("Payment") - CashReceiptObjectStruct.CreditMemos.Total("Payment")) AND
			CashReceiptObjectStruct.DocumentTotalRC = CashReceiptObjectStruct.UnappliedPayment * CashReceiptObjectStruct.ExchangeRate + (CashReceiptObjectStruct.LineItems.Total("Payment") - CashReceiptObjectStruct.CreditMemos.Total("Payment")) * CashReceiptObjectStruct.ExchangeRate Then
			
			Status = "Pass";
			
		EndIf;
	Except
	EndTry;
	
	Reg = InformationRegisters._UnitTestLog.CreateRecordManager();
	Reg.Period = CurrentDate();
	Reg.TestID = TestID;
	Reg.Result = Status;
	Reg.Write();
	
EndProcedure

&AtServer
// Tests AdditionalPaymentCall() with the following case:
//		- an invoice line item with a balance of 20 and payment of 20
//		- an invoice line item with a balance of 10 and payment of 10
//		- a credit memo with a balance of 10 and payment of 10
//		- exchange rate of 2
//
// Expected output:
// 		- CashPayment, DocumentTotal and DocumentTotalRC should be updated respectively
//		- CashPayment will be set to the line item payments - credit payment
//		- DocumentTotal will be set to the amount paid (minus any applied credits, in this case none) plus the UnappliedPayment
//		- DocumentTotalRC will be set the same as DocumentTotal but with an exchange rate of 2 in consideration
Procedure CashReceipt1011(CashReceiptObjectStruct) Export

	TestID = "CashReceipt1011";
	Status = "Fail";
	CashReceiptObject = Documents.CashReceipt.FindByNumber("TestIt").GetObject();
	ValueToFormData(CashReceiptObject,CashReceiptObjectStruct);
	
	CashReceiptObjectStruct.ExchangeRate = 2;
	
	NewLineItem = CashReceiptObjectStruct.LineItems.Add();
	NewLineItem.Document = Documents.SalesInvoice.FindByNumber("Testing");
	NewLineItem.BalanceFCY2 = 20;
	NewLineItem.Payment = 20;
	
	NewLineItem2 = CashReceiptObjectStruct.LineItems.Add();
	NewLineItem2.Document = Documents.SalesInvoice.FindByNumber("Testing");
	NewLineItem2.BalanceFCY2 = 10;
	NewLineItem2.Payment = 10;
	
	NewCreditItem = CashReceiptObjectStruct.CreditMemos.Add();
	NewCreditItem.Document = Documents.SalesReturn.FindByNumber("Testing");
	NewCreditItem.BalanceFCY2 = 10;
	NewCreditItem.Payment = 10;

	Try
		CashReceiptMethods.AdditionalPaymentCall(CashReceiptObjectStruct,False);
		If CashReceiptObjectStruct.UnappliedPayment = CashReceiptObjectStruct.CashPayment - CashReceiptObjectStruct.LineItems.Total("Payment") + CashReceiptObjectStruct.CreditMemos.Total("Payment") AND
			CashReceiptObjectStruct.DocumentTotal = CashReceiptObjectStruct.UnappliedPayment + (CashReceiptObjectStruct.LineItems.Total("Payment") - CashReceiptObjectStruct.CreditMemos.Total("Payment")) AND
			CashReceiptObjectStruct.DocumentTotalRC = CashReceiptObjectStruct.UnappliedPayment * CashReceiptObjectStruct.ExchangeRate + (CashReceiptObjectStruct.LineItems.Total("Payment") - CashReceiptObjectStruct.CreditMemos.Total("Payment")) * CashReceiptObjectStruct.ExchangeRate Then
			
			Status = "Pass";
			
		EndIf;
	Except
	EndTry;
	
	Reg = InformationRegisters._UnitTestLog.CreateRecordManager();
	Reg.Period = CurrentDate();
	Reg.TestID = TestID;
	Reg.Result = Status;
	Reg.Write();
	
EndProcedure

// Section 4: Test UpdateLineItemBalances()
// Summary: Cash Receipt line item balances are not stored in the object and need to be calculated whenever the
//				the form is opened or updated. This is done using UpdateLineItemBalance() to display the remaining balances for
//				each line item

&AtServer
// Tests UpdateLineItemBalances() with the following case:
//		- Creates a new Cash Receipt with a line item which initially has a balance of 20
//		- the new Cash Receipt is posted with a payment of 10 on the line item
//
// Expected output:
// 		- The function should update the line item with the remaining balance of the document (which should be 10 in this case)
Procedure CashReceipt1012(CashReceiptObjectStruct) Export
	
	TestID = "CashReceipt1012";
	Status = "Fail";
	
	NewCashReceipt = Documents.CashReceipt.CreateDocument();
	NewCashReceipt.Date = CurrentDate();
	NewCashReceipt.Number = "TempCR";
	NewCashReceipt.DepositType = "1";
	NewCashReceipt.Company = Catalogs.Companies.FindByDescription("TestCompany");
	NewCashReceipt.BankAccount = Constants.UndepositedFundsAccount.Get();
	DefaultCurrency = GeneralFunctionsReusable.DefaultCurrency();
	NewCashReceipt.ARAccount = DefaultCurrency.DefaultARAccount;	
	NewLineItem = NewCashReceipt.LineItems.Add();
	NewLineItem.Document = Documents.SalesInvoice.FindByNumber("Testing");
	NewLineItem.Payment = 10;
	NewCashReceipt.Write(DocumentWriteMode.Posting);
	
	ValueToFormData(NewCashReceipt,CashReceiptObjectStruct);
	
	Try
		CashReceiptMethods.UpdateLineItemBalances(CashReceiptObjectStruct);
		If CashReceiptObjectStruct.LineItems[0].BalanceFCY2 = 10 Then			
			Status = "Pass";		
		EndIf;
	Except
	EndTry;
	NewCashReceipt.Write(DocumentWriteMode.UndoPosting);
	NewCashReceipt.Delete();
	
	Reg = InformationRegisters._UnitTestLog.CreateRecordManager();
	Reg.Period = CurrentDate();
	Reg.TestID = TestID;
	Reg.Result = Status;
	Reg.Write();
	
EndProcedure

&AtServer
// Tests UpdateLineItemBalances() with the following case:
//		- Creates a new Cash Receipt with a line item which initially has a balance of 20
//		- A credit memo is added with an initial balance of 10
//		- the new Cash Receipt is posted with a payment of 10 on the line item and payment of 5 on the credit memo
//
// Expected output:
// 		- The function should update the credit memo with the remaining balance of the document (which should be 5 in this case)
//
// The line item payment was made because posting the Cash Receipt requires a payment, 
// 	the focus of this test is on the remaining balance on the credit memo
Procedure CashReceipt1013(CashReceiptObjectStruct) Export
	
	TestID = "CashReceipt1013";
	Status = "Fail";
	
	NewCashReceipt = Documents.CashReceipt.CreateDocument();
	NewCashReceipt.Date = CurrentDate();
	NewCashReceipt.Number = "TempCR";
	NewCashReceipt.DepositType = "1";
	NewCashReceipt.Company = Catalogs.Companies.FindByDescription("TestCompany");
	NewCashReceipt.BankAccount = Constants.UndepositedFundsAccount.Get();
	DefaultCurrency = GeneralFunctionsReusable.DefaultCurrency();
	NewCashReceipt.ARAccount = DefaultCurrency.DefaultARAccount;
	
	NewLineItem = NewCashReceipt.LineItems.Add();
	NewLineItem.Document = Documents.SalesInvoice.FindByNumber("Testing");
	NewLineItem.Payment = 10;

	NewCreditItem = NewCashReceipt.CreditMemos.Add();
	NewCreditItem.Document = Documents.SalesReturn.FindByNumber("Testing");
	NewCreditItem.Payment = 5;
	NewCashReceipt.Write(DocumentWriteMode.Posting);
	
	ValueToFormData(NewCashReceipt,CashReceiptObjectStruct);
	
	Try
		CashReceiptMethods.UpdateLineItemBalances(CashReceiptObjectStruct);
		If CashReceiptObjectStruct.CreditMemos[0].BalanceFCY2 = 5 Then			
			Status = "Pass";		
		EndIf;
	Except
	EndTry;
	NewCashReceipt.Write(DocumentWriteMode.UndoPosting);
	NewCashReceipt.Delete();
	
	Reg = InformationRegisters._UnitTestLog.CreateRecordManager();
	Reg.Period = CurrentDate();
	Reg.TestID = TestID;
	Reg.Result = Status;
	Reg.Write();
	
EndProcedure


// Section 5: Test FillDocumentList()
// Summary: This function is used to populate the line items section of a Cash Receipt based on the selected company

&AtServer
// Tests FillDocumentList with the following case:
//		- Retrieve an existing Cash Receipt with a company that only has one sales invoice
//
// Expected output:
// 		- If the test is succesful, the same invoice should populate the Cash Receipt line items section
Procedure CashReceipt1014(CashReceiptObjectStruct) Export

	TestID = "CashReceipt1014";
	Status = "Fail";
	CashReceiptObject = Documents.CashReceipt.FindByNumber("TestIt").GetObject();
	ValueToFormData(CashReceiptObject,CashReceiptObjectStruct);
	  
	Try
		CashReceiptMethods.FillDocumentList(CashReceiptObject.Company,CashReceiptObjectStruct);
		If CashReceiptObjectStruct.LineItems.Count() = 1 
			AND CashReceiptObjectStruct.LineItems[0].Document = Documents.SalesInvoice.FindByNumber("Testing") Then
	
			Status = "Pass";
			
		EndIf;
	Except
	EndTry;
	
	Reg = InformationRegisters._UnitTestLog.CreateRecordManager();
	Reg.Period = CurrentDate();
	Reg.TestID = TestID;
	Reg.Result = Status;
	Reg.Write();
	
EndProcedure

&AtServer
// Tests FillDocumentList with the following case:
//		- Retrieve an existing Cash Receipt with a company that only has one sales invoice
//		- The invoice however does not have the same currency as the Cash Receipt
//
// Expected output:
// 		- The Cash Receipt should not populate any line items
Procedure CashReceipt1015(CashReceiptObjectStruct) Export

	TestID = "CashReceipt1015";
	Status = "Fail";
	CashReceiptObject = Documents.CashReceipt.FindByNumber("TestIt").GetObject();
	ValueToFormData(CashReceiptObject,CashReceiptObjectStruct);
	
	SalesInvoiceObject = Documents.SalesInvoice.FindByNumber("Testing").GetObject();
	TempCurrency = Catalogs.Currencies.CreateItem();
	TempCurrency.Symbol = "Ruble";
	TempCurrency.Description = "RUB";
	TempCurrency.Write();

	SalesInvoiceObject.Currency = TempCurrency;
	SalesInvoiceObject.Write();
	  
	Try
		CashReceiptMethods.FillDocumentList(CashReceiptObject.Company,CashReceiptObjectStruct);
		If CashReceiptObjectStruct.LineItems.Count() = 0 Then
	
			Status = "Pass";
			
		EndIf;
	Except
	EndTry;
	
	TempCurrency.Delete();
	DefaultCurrency = GeneralFunctionsReusable.DefaultCurrency();
	SalesInvoiceObject.Currency = DefaultCurrency;
	SalesInvoiceObject.Write();
	
	Reg = InformationRegisters._UnitTestLog.CreateRecordManager();
	Reg.Period = CurrentDate();
	Reg.TestID = TestID;
	Reg.Result = Status;
	Reg.Write();
	
EndProcedure

// Section 6: Test FillCreditMemos()
// Summary: This function is used to populate the credit memos section of a Cash Receipt based on the selected company

&AtServer
// Tests FillDocumentList with the following case:
//		- Retrieve an existing Cash Receipt with a company that only has one credit memo
//
// Expected output:
// 		- If the test is succesful, the same credit memo should populate the Cash Receipt credit memo section
Procedure CashReceipt1016(CashReceiptObjectStruct) Export

	TestID = "CashReceipt1016";
	Status = "Fail";
	CashReceiptObject = Documents.CashReceipt.FindByNumber("TestIt").GetObject();
	ValueToFormData(CashReceiptObject,CashReceiptObjectStruct);
	  
	Try
		CashReceiptMethods.FillCreditMemos(CashReceiptObject.Company,CashReceiptObjectStruct);
		If CashReceiptObjectStruct.CreditMemos.Count() = 1 
			AND CashReceiptObjectStruct.CreditMemos[0].Document = Documents.SalesReturn.FindByNumber("Testing") Then
	
			Status = "Pass";
			
		EndIf;
	Except
	EndTry;
	
	Reg = InformationRegisters._UnitTestLog.CreateRecordManager();
	Reg.Period = CurrentDate();
	Reg.TestID = TestID;
	Reg.Result = Status;
	Reg.Write();
	
EndProcedure

&AtServer
// Tests FillDocumentList with the following case:
//		- Retrieve an existing Cash Receipt with a company that only has one sales invoice
//		- The invoice however does not have the same currency as the Cash Receipt
//
// Expected output:
// 		- The Cash Receipt should not populate any line items
Procedure CashReceipt1017(CashReceiptObjectStruct) Export

	TestID = "CashReceipt1017";
	Status = "Fail";
	CashReceiptObject = Documents.CashReceipt.FindByNumber("TestIt").GetObject();
	ValueToFormData(CashReceiptObject,CashReceiptObjectStruct);
	
	CreditMemosObject = Documents.SalesReturn.FindByNumber("Testing").GetObject();
	TempCurrency = Catalogs.Currencies.CreateItem();
	TempCurrency.Symbol = "Ruble";
	TempCurrency.Description = "RUB";
	TempCurrency.Write();

	CreditMemosObject.Currency = TempCurrency;
	CreditMemosObject.Write();
	  
	Try
		CashReceiptMethods.FillCreditMemos(CashReceiptObject.Company,CashReceiptObjectStruct);
		If CashReceiptObjectStruct.CreditMemos.Count() = 0 Then
	
			Status = "Pass";
			
		EndIf;
	Except
	EndTry;
	
	TempCurrency.Delete();
	DefaultCurrency = GeneralFunctionsReusable.DefaultCurrency();
	CreditMemosObject.Currency = DefaultCurrency;
	CreditMemosObject.Write();
	
	Reg = InformationRegisters._UnitTestLog.CreateRecordManager();
	Reg.Period = CurrentDate();
	Reg.TestID = TestID;
	Reg.Result = Status;
	Reg.Write();
	
EndProcedure

// Section 7: Test Cash Receipt posting
// Summary: These tests are used to check that the current registers and accounts are written
//			into the general journal when a Cash Receipt is posted

&AtServer
// Test input:
//		- A temporary cash receipt is created with one invoice line item
//		- The line item is paid in full through a cash payment of 20
//		- Exchange rate of 1
//
// Expected output:
// 		- Once posted, there should be two generated general journal records
//			- One credit with an amount of 20 under 1200 Accounts Receivable
//			- One debit with an amount of 20 under 1100 Undeposited Funds
Procedure CashReceipt1018(CashReceiptObjectStruct) Export

	TestID = "CashReceipt1018";
	Status = "Fail";
	
	NewCashReceipt = Documents.CashReceipt.CreateDocument();
	NewCashReceipt.Date = CurrentDate();
	NewCashReceipt.Number = "TempCR";
	NewCashReceipt.DepositType = "1";
	NewCashReceipt.Company = Catalogs.Companies.FindByDescription("TestCompany");
	NewCashReceipt.BankAccount = Constants.UndepositedFundsAccount.Get();
	DefaultCurrency = GeneralFunctionsReusable.DefaultCurrency();
	NewCashReceipt.ARAccount = DefaultCurrency.DefaultARAccount;
	NewCashReceipt.CashPayment = 20;
	NewCashReceipt.ExchangeRate = 1;
	
	NewLineItem = NewCashReceipt.LineItems.Add();
	NewLineItem.Document = Documents.SalesInvoice.FindByNumber("Testing");
	NewLineItem.Payment = 20;
	
	NewCashReceipt.DocumentTotal = 20;
	NewCashReceipt.DocumentTotalRC = 20;
	NewCashReceipt.Write(DocumentWriteMode.Posting);
		
	Try
		Query = New Query;
		Query.Text = "SELECT
		             |	""LineItems"" AS TabularSection,
		             |	GeneralJournalRecordsWithExtDimensions.Recorder,
		             |	GeneralJournalRecordsWithExtDimensions.Account,
		             |	GeneralJournalRecordsWithExtDimensions.Amount,
		             |	GeneralJournalRecordsWithExtDimensions.AmountRC,
		             |	GeneralJournalRecordsWithExtDimensions.RecordType
		             |FROM
		             |	AccountingRegister.GeneralJournal.RecordsWithExtDimensions AS GeneralJournalRecordsWithExtDimensions
		             |WHERE
		             |	GeneralJournalRecordsWithExtDimensions.Recorder = &CashReceipt";
					 
		Query.SetParameter("CashReceipt", NewCashReceipt.Ref);
		ResultQuery = Query.Execute().Unload();

		If ResultQuery.Count() = 2 
			And ResultQuery.Find(ChartsOfAccounts.ChartOfAccounts.FindByCode("1200"),"Account") <> NULL 
			And ResultQuery.Find(ChartsOfAccounts.ChartOfAccounts.FindByCode("1100"),"Account") <> NULL Then
			
			If ResultQuery[0].Amount = 20 AND ResultQuery[1].AmountRC = 20 
				AND ResultQuery[1].Amount = 20 AND ResultQuery[1].AmountRC = 20 Then
				Status = "Pass";
			EndIf;
		EndIf;
		
	Except
	EndTry;
		
	NewCashReceipt.Write(DocumentWriteMode.UndoPosting);
	NewCashReceipt.Delete();

		
	Reg = InformationRegisters._UnitTestLog.CreateRecordManager();
	Reg.Period = CurrentDate();
	Reg.TestID = TestID;
	Reg.Result = Status;
	Reg.Write();

EndProcedure

&AtServer
// Test input:
//		- A temporary cash receipt is created with one invoice line item
//		- The line item is paid in full through a cash payment of 50
//		- A leftover payment of 30 set as the UnappiedPayment
//		- Exchange rate of 1
//
// Expected output:
// 		- Once posted, there should be two generated general journal records
//			- One credit with an amount of 43 under 1200 Accounts Receivable
//			- One credit with an amount of 7 under 1200 Accounts Receivable
//			- One debit with an amount of 50 under 1100 Undeposited Funds
Procedure CashReceipt1019(CashReceiptObjectStruct) Export

	TestID = "CashReceipt1019";
	Status = "Fail";
	
	NewCashReceipt = Documents.CashReceipt.CreateDocument();
	NewCashReceipt.Date = CurrentDate();
	NewCashReceipt.Number = "TempCR";
	NewCashReceipt.DepositType = "1";
	NewCashReceipt.Company = Catalogs.Companies.FindByDescription("TestCompany");
	NewCashReceipt.BankAccount = Constants.UndepositedFundsAccount.Get();
	DefaultCurrency = GeneralFunctionsReusable.DefaultCurrency();
	NewCashReceipt.ARAccount = DefaultCurrency.DefaultARAccount;
	NewCashReceipt.CashPayment = 50;
	NewCashReceipt.ExchangeRate = 1;
	
	NewLineItem = NewCashReceipt.LineItems.Add();
	NewLineItem.Document = Documents.SalesInvoice.FindByNumber("Testing");
	NewLineItem.Payment = 20;
	
	NewCashReceipt.DocumentTotal = 50;
	NewCashReceipt.DocumentTotalRC = 50;
	NewCashReceipt.UnappliedPayment = 30;
	NewCashReceipt.Write(DocumentWriteMode.Posting);
		
	Try
		Query = New Query;
		Query.Text = "SELECT
		             |	""LineItems"" AS TabularSection,
		             |	GeneralJournalRecordsWithExtDimensions.Recorder,
		             |	GeneralJournalRecordsWithExtDimensions.Account,
		             |	GeneralJournalRecordsWithExtDimensions.Amount,
		             |	GeneralJournalRecordsWithExtDimensions.AmountRC,
		             |	GeneralJournalRecordsWithExtDimensions.RecordType
		             |FROM
		             |	AccountingRegister.GeneralJournal.RecordsWithExtDimensions AS GeneralJournalRecordsWithExtDimensions
		             |WHERE
		             |	GeneralJournalRecordsWithExtDimensions.Recorder = &CashReceipt";
					 
		Query.SetParameter("CashReceipt", NewCashReceipt.Ref);
		ResultQuery = Query.Execute().Unload();

		If ResultQuery.Count() = 3 Then
			CreditTotal = 0;
			CreditTotalRC = 0;
			DebitTotal = 0;
			DebitTotalRC = 0;
			For Each Result In ResultQuery Do
				If Result.RecordType = AccountingRecordType.Credit Then
					CreditTotal = CreditTotal + Result.Amount;
					CreditTotalRC = CreditTotalRC + Result.AmountRC;
				ElsIf Result.RecordType = AccountingRecordType.Debit Then
					DebitTotal = DebitTotal + Result.Amount;
					DebitTotalRC = DebitTotalRC + Result.AmountRC;
				Else
				EndIf;
			EndDo;
			
			If CreditTotal = 50 AND CreditTotalRC = 50 AND DebitTotal AND DebitTotalRC = 50 Then
				Status = "Pass";
			EndIf;
		EndIf;
		
	Except
	EndTry;
		
	NewCashReceipt.Write(DocumentWriteMode.UndoPosting);
	NewCashReceipt.Delete();

		
	Reg = InformationRegisters._UnitTestLog.CreateRecordManager();
	Reg.Period = CurrentDate();
	Reg.TestID = TestID;
	Reg.Result = Status;
	Reg.Write();

EndProcedure




