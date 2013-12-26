&AtServer
Procedure InitializeProductCategories() Export
	
	NewCategory = Catalogs.ProductCategories.CreateItem();
	NewCategory.Description = "CD";
	NewCategory.Write();
	
	NewCategory = Catalogs.ProductCategories.CreateItem();
	NewCategory.Description = "DVD";
	NewCategory.Write();
	
	
EndProcedure

&AtServer
Procedure InitializePriceLevels() Export
	
	NewLevel = Catalogs.PriceLevels.CreateItem();
	NewLevel.Description = "Wholesale";
	NewLevel.Write();
	
	NewLevel = Catalogs.PriceLevels.CreateItem();
	NewLevel.Description = "Retail";
	NewLevel.Write();
	
EndProcedure

&AtServer
Procedure InitializeProducts() Export
	
	NewProduct = Catalogs.Products.CreateItem();
	NewProduct.Type = Enums.InventoryTypes.NonInventory;
	NewProduct.Code = "Britney";
	NewProduct.Description = "Britney Love";
	NewProduct.IncomeAccount = Constants.IncomeAccount.Get();
	NewProduct.InventoryOrExpenseAccount = GeneralFunctions.InventoryAcct(Enums.InventoryTypes.NonInventory);
	NewProduct.COGSAccount = GeneralFunctions.GetEmptyAcct();
	NewProduct.PurchaseVATCode = Constants.DefaultPurchaseVAT.Get();
	NewProduct.SalesVATCode = Constants.DefaultSalesVAT.Get();
	//NewProduct.api_code = GeneralFunctions.NextProductNumber();
	NewProduct.Category = Catalogs.ProductCategories.FindByDescription("CD");
	NewProduct.Write();
	
	NewProduct = Catalogs.Products.CreateItem();
	NewProduct.Type = Enums.InventoryTypes.NonInventory;
	NewProduct.Code = "Planet Earth";
	NewProduct.Description = "Beautiful Planet Earth";
	NewProduct.IncomeAccount = Constants.IncomeAccount.Get();
	NewProduct.InventoryOrExpenseAccount = GeneralFunctions.InventoryAcct(Enums.InventoryTypes.NonInventory);
	NewProduct.COGSAccount = GeneralFunctions.GetEmptyAcct();
	NewProduct.PurchaseVATCode = Constants.DefaultPurchaseVAT.Get();
	NewProduct.SalesVATCode = Constants.DefaultSalesVAT.Get();
	//NewProduct.api_code = GeneralFunctions.NextProductNumber();
	NewProduct.Category = Catalogs.ProductCategories.FindByDescription("DVD");
	NewProduct.Write();
	
	NewProduct = Catalogs.Products.CreateItem();
	NewProduct.Type = Enums.InventoryTypes.NonInventory;
	NewProduct.Code = "ARTPOP";
	NewProduct.Description = "Lady Gaga ARTPOP";
	NewProduct.IncomeAccount = Constants.IncomeAccount.Get();
	NewProduct.InventoryOrExpenseAccount = GeneralFunctions.InventoryAcct(Enums.InventoryTypes.NonInventory);
	NewProduct.COGSAccount = GeneralFunctions.GetEmptyAcct();
	NewProduct.PurchaseVATCode = Constants.DefaultPurchaseVAT.Get();
	NewProduct.SalesVATCode = Constants.DefaultSalesVAT.Get();
	//NewProduct.api_code = GeneralFunctions.NextProductNumber();
	NewProduct.Category = Catalogs.ProductCategories.FindByDescription("CD");
	NewProduct.Write();

	
	NewProduct = Catalogs.Products.CreateItem();
	NewProduct.Type = Enums.InventoryTypes.NonInventory;
	NewProduct.Code = "t-shirt";
	NewProduct.Description = "Dat Girl t-shirt";
	NewProduct.IncomeAccount = Constants.IncomeAccount.Get();
	NewProduct.InventoryOrExpenseAccount = GeneralFunctions.InventoryAcct(Enums.InventoryTypes.NonInventory);
	NewProduct.COGSAccount = GeneralFunctions.GetEmptyAcct();
	NewProduct.PurchaseVATCode = Constants.DefaultPurchaseVAT.Get();
	NewProduct.SalesVATCode = Constants.DefaultSalesVAT.Get();
	//NewProduct.api_code = GeneralFunctions.NextProductNumber();
	//NewProduct.Category = Catalogs.ProductCategories.FindByDescription("DVD");
	NewProduct.Write();	

EndProcedure

&AtServer
Procedure InitializeCustomers() Export
	
	NewCompany = Catalogs.Companies.CreateItem();	
	NewCompany.Description = "Wholesale Customer";
	NewCompany.Customer = True;
	NewCompany.DefaultCurrency = Constants.DefaultCurrency.Get();
	NewCompany.Terms = Catalogs.PaymentTerms.Net30;
	NewCompany.PriceLevel = Catalogs.PriceLevels.FindByDescription("Wholesale");
	NewCompany.Write();	
	AddressLine = Catalogs.Addresses.CreateItem();
	AddressLine.Owner = NewCompany.Ref;
	AddressLine.Description = "Primary";
	AddressLine.Write();
	
	NewCompany = Catalogs.Companies.CreateItem();	
	NewCompany.Description = "Retail Customer";
	NewCompany.Customer = True;
	NewCompany.DefaultCurrency = Constants.DefaultCurrency.Get();
	NewCompany.Terms = Catalogs.PaymentTerms.Net30;
	NewCompany.PriceLevel = Catalogs.PriceLevels.FindByDescription("Retail");
	NewCompany.Write();	
	AddressLine = Catalogs.Addresses.CreateItem();
	AddressLine.Owner = NewCompany.Ref;
	AddressLine.Description = "Primary";
	AddressLine.Write();

	
	NewCompany = Catalogs.Companies.CreateItem();	
	NewCompany.Description = "Rasputin";
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
Procedure InitializePriceMatrix() Export
	
	Today = CurrentDate();
	Past = Today - 60*60*24*30; // a month back
	Future = Today + 60*60*24*30; // a month ahead
	
	//////////// Item & ItemPriceLevel Pricing
	
	// Britney
	// Today
	
	Product = Catalogs.Products.FindByCode("Britney");
	
	Reg = InformationRegisters.PriceList.CreateRecordManager();
	Reg.Period = Today;
	Reg.PriceType = "Item";
	Reg.Product = Product;
	//Reg.PriceLevel = ;
	//Reg.ProductCategory = ;
	Reg.Price = 1.5;
	Reg.Write();
	
	Reg = InformationRegisters.PriceList.CreateRecordManager();
	Reg.Period = Today;
	Reg.PriceType = "ItemPriceLevel";
	Reg.Product = Product;
	Reg.PriceLevel = Catalogs.PriceLevels.FindByDescription("Wholesale");
	//Reg.ProductCategory = ;
	Reg.Price = 2.5;
	Reg.Write();
	
	Reg = InformationRegisters.PriceList.CreateRecordManager();
	Reg.Period = Today;
	Reg.PriceType = "ItemPriceLevel";
	Reg.Product = Product;
	Reg.PriceLevel = Catalogs.PriceLevels.FindByDescription("Retail");
	//Reg.ProductCategory = ;
	Reg.Price = 3.5;
	Reg.Write();
						
	// Planet Earth
	// Today
	
	Product = Catalogs.Products.FindByCode("Planet Earth");
	
	Reg = InformationRegisters.PriceList.CreateRecordManager();
	Reg.Period = Today;
	Reg.PriceType = "Item";
	Reg.Product = Product;
	//Reg.PriceLevel = ;
	//Reg.ProductCategory = ;
	Reg.Price = 4.5;
	Reg.Write();
	
	Reg = InformationRegisters.PriceList.CreateRecordManager();
	Reg.Period = Today;
	Reg.PriceType = "ItemPriceLevel";
	Reg.Product = Product;
	Reg.PriceLevel = Catalogs.PriceLevels.FindByDescription("Wholesale");
	//Reg.ProductCategory = ;
	Reg.Price = 5.5;
	Reg.Write();
	
	Reg = InformationRegisters.PriceList.CreateRecordManager();
	Reg.Period = Today;
	Reg.PriceType = "ItemPriceLevel";
	Reg.Product = Product;
	Reg.PriceLevel = Catalogs.PriceLevels.FindByDescription("Retail");
	//Reg.ProductCategory = ;
	Reg.Price = 6.5;
	Reg.Write();
									
	// t-shirt
	// Today
	
	Product = Catalogs.Products.FindByCode("t-shirt");
	
	Reg = InformationRegisters.PriceList.CreateRecordManager();
	Reg.Period = Today;
	Reg.PriceType = "Item";
	Reg.Product = Product;
	//Reg.PriceLevel = ;
	//Reg.ProductCategory = ;
	Reg.Price = 7.5;
	Reg.Write();
	
	//Reg = InformationRegisters.PriceList.CreateRecordManager();
	//Reg.Period = Today;
	//Reg.PriceType = "ItemPriceLevel";
	//Reg.Product = Product;
	//Reg.PriceLevel = Catalogs.PriceLevels.FindByDescription("Wholesale");
	////Reg.ProductCategory = ;
	//Reg.Price = 8.5;
	//Reg.Write();
	
	Reg = InformationRegisters.PriceList.CreateRecordManager();
	Reg.Period = Today;
	Reg.PriceType = "ItemPriceLevel";
	Reg.Product = Product;
	Reg.PriceLevel = Catalogs.PriceLevels.FindByDescription("Retail");
	//Reg.ProductCategory = ;
	Reg.Price = 9.5;
	Reg.Write();
									
	//////////// Category & PriceLevelCategory Pricing
	
	Reg = InformationRegisters.PriceList.CreateRecordManager();
	Reg.Period = Today;
	Reg.PriceType = "PriceLevelCategory";
	//Reg.Product = Product;
	Reg.PriceLevel = Catalogs.PriceLevels.FindByDescription("Retail");
	Reg.ProductCategory = Catalogs.ProductCategories.FindByDescription("CD");
	Reg.Price = 10.5;
	Reg.Write();
	
	Reg = InformationRegisters.PriceList.CreateRecordManager();
	Reg.Period = Today;
	Reg.PriceType = "PriceLevelCategory";
	//Reg.Product = Product;
	Reg.PriceLevel = Catalogs.PriceLevels.FindByDescription("Retail");
	Reg.ProductCategory = Catalogs.ProductCategories.FindByDescription("DVD");
	Reg.Price = 11.5;
	Reg.Write();
	
	Reg = InformationRegisters.PriceList.CreateRecordManager();
	Reg.Period = Today;
	Reg.PriceType = "PriceLevelCategory";
	//Reg.Product = Product;
	Reg.PriceLevel = Catalogs.PriceLevels.FindByDescription("Wholesale");
	Reg.ProductCategory = Catalogs.ProductCategories.FindByDescription("CD");
	Reg.Price = 12.5;
	Reg.Write();
	
	Reg = InformationRegisters.PriceList.CreateRecordManager();
	Reg.Period = Today;
	Reg.PriceType = "PriceLevelCategory";
	//Reg.Product = Product;
	Reg.PriceLevel = Catalogs.PriceLevels.FindByDescription("Wholesale");
	Reg.ProductCategory = Catalogs.ProductCategories.FindByDescription("DVD");
	Reg.Price = 13.5;
	Reg.Write();
	
	Reg = InformationRegisters.PriceList.CreateRecordManager();
	Reg.Period = Today;
	Reg.PriceType = "Category";
	//Reg.Product = Product;
	//Reg.PriceLevel = Catalogs.PriceLevels.FindByDescription("Wholesale");
	Reg.ProductCategory = Catalogs.ProductCategories.FindByDescription("DVD");
	Reg.Price = 14.5;
	Reg.Write();

	Reg = InformationRegisters.PriceList.CreateRecordManager();
	Reg.Period = Today;
	Reg.PriceType = "Category";
	//Reg.Product = Product;
	//Reg.PriceLevel = Catalogs.PriceLevels.FindByDescription("Wholesale");
	Reg.ProductCategory = Catalogs.ProductCategories.FindByDescription("CD");
	Reg.Price = 15.5;
	Reg.Write();

EndProcedure

// TEST FOR A SITUATION WHEN AN ITEM HAS A CATEGORY ASSIGNED BUT THE MATRIX DOESN'T

// Parameter checks

//&AtServer
//Procedure PriceMatrix1000() Export
//	
//	TestID = "PriceMatrix1000";
//	
//	// wrong types of function parameters
//	
//	Status = "Fail";
//	Product = Catalogs.Products.FindByCode("Britney");
//	
//	Try
//		Price = GeneralFunctions.RetailPrice("hello","world",Product,Catalogs.Companies.EmptyRef());
//		If Price = 0 Then
//			Status = "Pass"
//		EndIf;
//	Except
//	EndTry;
//	
//	Reg = InformationRegisters._UnitTestLog.CreateRecordManager();
//	Reg.Period = CurrentDate();
//	Reg.TestID = TestID;
//	Reg.Result = Status;
//	Reg.Write();
//	
//EndProcedure

//&AtServer
//Procedure PriceMatrix1001() Export
//	
//	TestID = "PriceMatrix1001";
//	
//	// wrong number of function parameters
//	
//	Status = "Fail";
//	Product = Catalogs.Products.FindByCode("Britney");
//	
//	Try
//		Price = GeneralFunctions.RetailPrice(CurrentDate(),Product);
//		If Price = 1.5 Then
//			Status = "Pass"
//		EndIf;
//	Except
//	EndTry;
//	
//	Reg = InformationRegisters._UnitTestLog.CreateRecordManager();
//	Reg.Period = CurrentDate();
//	Reg.TestID = TestID;
//	Reg.Result = Status;
//	Reg.Write();
//	
//EndProcedure

// end Parameter checks


// item with category
	// customer with price level
		// category - n/a (0)
		// category + price level - n/a (0)
		// item - Y
		// item + price level - Y
		
	// customer w/o price level
	// no customer

// item w/o category
	// customer with price level
	// customer w/o price level
	// no customer


&AtServer
Procedure PriceMatrix1002() Export
	
	TestID = "PriceMatrix1002";
	
	Product = Catalogs.Products.FindByCode("Britney");
	ActualPrice = 1.5;
	
	Status = "Fail";
	Try
		Price = GeneralFunctions.RetailPrice(CurrentDate(),Product,Catalogs.Companies.EmptyRef());
		If Price = ActualPrice Then
			Status = "Pass"
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
Procedure PriceMatrix1003() Export
	
	TestID = "PriceMatrix1003";
	Product = Catalogs.Products.FindByCode("Britney");
	Customer = Catalogs.Companies.FindByDescription("Retail");
	ActualPrice = 3.5;
	
	Status = "Fail";
	
	Try
		Price = GeneralFunctions.RetailPrice(CurrentDate(),Product,Customer);
		If Price = ActualPrice Then
			Status = "Pass"
		EndIf;
	Except
	EndTry;
	
	Reg = InformationRegisters._UnitTestLog.CreateRecordManager();
	Reg.Period = CurrentDate();
	Reg.TestID = TestID;
	Reg.Result = Status;
	Reg.Write();
	
EndProcedure

// checking priority "Item" -> "Item + Price level"

&AtServer
Procedure PriceMatrix1004() Export
	
	TestID = "PriceMatrix1004";
	Product = Catalogs.Products.FindByCode("t-shirt");
	//Customer = Catalogs.Companies.FindByDescription("Wholesale");
	Customer = Catalogs.Companies.EmptyRef();
	ActualPrice = 7.5;

	Status = "Fail";
	
	Try
		Price = GeneralFunctions.RetailPrice(CurrentDate(),Product,Customer);
		If Price = ActualPrice Then
			Status = "Pass"
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
Procedure PriceMatrix1005() Export
	
	TestID = "PriceMatrix1005";
	Product = Catalogs.Products.FindByCode("t-shirt");
	Customer = Catalogs.Companies.FindByDescription("Retail");
	ActualPrice = 9.5;

	Status = "Fail";
	
	Try
		Price = GeneralFunctions.RetailPrice(CurrentDate(),Product,Customer);
		If Price = ActualPrice Then
			Status = "Pass"
		EndIf;
	Except
	EndTry;
	
	Reg = InformationRegisters._UnitTestLog.CreateRecordManager();
	Reg.Period = CurrentDate();
	Reg.TestID = TestID;
	Reg.Result = Status;
	Reg.Write();
	
EndProcedure

// end checking priority "Item" -> "Item + Price level"

&AtServer
Procedure PriceMatrix1006() Export
	
	TestID = "PriceMatrix1006";
	Product = Catalogs.Products.FindByCode("t-shirt");
	Customer = Catalogs.Companies.FindByDescription("Wholesale");
	ActualPrice = 7.5;

	Status = "Fail";
	
	Try
		Price = GeneralFunctions.RetailPrice(CurrentDate(),Product,Customer);
		If Price = ActualPrice Then
			Status = "Pass"
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
Procedure PriceMatrix1007() Export
	
	TestID = "PriceMatrix1007";
	Product = Catalogs.Products.FindByCode("Britney");
	Customer = Catalogs.Companies.FindByDescription("Rasputin");
	ActualPrice = 1.5;

	Status = "Fail";
	
	Try
		Price = GeneralFunctions.RetailPrice(CurrentDate(),Product,Customer);
		If Price = ActualPrice Then
			Status = "Pass"
		EndIf;
	Except
	EndTry;
	
	Reg = InformationRegisters._UnitTestLog.CreateRecordManager();
	Reg.Period = CurrentDate();
	Reg.TestID = TestID;
	Reg.Result = Status;
	Reg.Write();
	
EndProcedure

// checking priority "Category" -> "Item cat. + Price level"

&AtServer
Procedure PriceMatrix1008() Export
	
	TestID = "PriceMatrix1008";
	Product = Catalogs.Products.FindByCode("ARTPOP");
	Customer = Catalogs.Companies.EmptyRef();
	ActualPrice = 15.5;

	Status = "Fail";
	
	Try
		Price = GeneralFunctions.RetailPrice(CurrentDate(),Product,Customer);
		If Price = ActualPrice Then
			Status = "Pass"
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
Procedure PriceMatrix1009() Export
	
	TestID = "PriceMatrix1009";
	Product = Catalogs.Products.FindByCode("ARTPOP");
	Customer = Catalogs.Companies.FindByDescription("Wholesale");
	ActualPrice = 12.5;

	Status = "Fail";
	
	Try
		Price = GeneralFunctions.RetailPrice(CurrentDate(),Product,Customer);
		If Price = ActualPrice Then
			Status = "Pass"
		EndIf;
	Except
	EndTry;
	
	Reg = InformationRegisters._UnitTestLog.CreateRecordManager();
	Reg.Period = CurrentDate();
	Reg.TestID = TestID;
	Reg.Result = Status;
	Reg.Write();
	
EndProcedure

// end checking priority "Category" -> "Item cat. + Price level"

&AtServer
Procedure PriceMatrix1010() Export
	
	TestID = "PriceMatrix1008";
	Product = Catalogs.Products.FindByCode("ARTPOP");
	Customer = Catalogs.Companies.FindByDescription("Rasputin");
	ActualPrice = 15.5;

	Status = "Fail";
	
	Try
		Price = GeneralFunctions.RetailPrice(CurrentDate(),Product,Customer);
		If Price = ActualPrice Then
			Status = "Pass"
		EndIf;
	Except
	EndTry;
	
	Reg = InformationRegisters._UnitTestLog.CreateRecordManager();
	Reg.Period = CurrentDate();
	Reg.TestID = TestID;
	Reg.Result = Status;
	Reg.Write();
	
EndProcedure
