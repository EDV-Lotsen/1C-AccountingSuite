
Function inout(jsonin)
		
	ParsedJSON = InternetConnectionClientServer.DecodeJSON(jsonin);
		
	NewCashSale = Documents.CashSale.CreateDocument();
	CompanyCode = ParsedJSON.company_code;
	NewCashSale.Company = Catalogs.Companies.FindByCode(CompanyCode);
	ShipToAddressCode = ParsedJSON.ship_to_address_code;
	// check if address belongs to company
	NewCashSale.ShipTo = Catalogs.Addresses.FindByCode(ShipToAddressCode);
	// select the company's default shipping address
	
	NewCashSale.Date = ParsedJSON.date;
	
	//PaymentMethod = ParsedJSON.Get("payment_method");
	// support all payment methods
	NewCashSale.PaymentMethod = Catalogs.PaymentMethods.Cash;
	Try
		NewCashSale.RefNum = ParsedJSON.ref_num;
	Except
	EndTry;
	Try
		NewCashSale.Memo = ParsedJSON.memo;
	Except
	EndTry;
	// tax rate - calculate from address?
	Try
		SalesTax = ParsedJSON.sales_tax_total; 
		NewCashSale.SalesTax = ParsedJSON.sales_tax_total;		
	Except
		NewCashSale.SalesTax = 0;
	EndTry;
	NewCashSale.DocumentTotal = ParsedJSON.doc_total;
	NewCashSale.DocumentTotalRC = ParsedJSON.doc_total;
    NewCashSale.DepositType = "2";
	NewCashSale.Currency = Constants.DefaultCurrency.Get();
	NewCashSale.BankAccount = Constants.BankAccount.Get();
	NewCashSale.ExchangeRate = 1;
	NewCashSale.Location = Catalogs.Locations.MainWarehouse;
	
	DataLineItems = ParsedJSON.lines.line_items;
	
	LineItemsRows = DataLineItems.Count();
	For i = 0 To LineItemsRows -1 Do
		
		NewLine = NewCashSale.LineItems.Add();
		
		ProductCode = Number(DataLineItems[i].api_code);
		Product = Catalogs.Products.FindByAttribute("api_code", ProductCode);
		NewLine.Product = Product;
		NewLine.ProductDescription = Product.Description;
		NewLine.VATCode = CommonUse.GetAttributeValue(Product, "SalesVATCode");
		NewLine.VAT = 0;
		
		NewLine.Price = DataLineItems[i].price;
		NewLine.Quantity = DataLineItems[i].quantity;
		// get taxable from JSON
		Try
			TaxableType = DataLineItems[i].taxable_type;
			If TaxableType = "taxable" Then
				NewLine.SalesTaxType = Enums.SalesTaxTypes.Taxable;
			ElsIf TaxableType = "non-taxable" Then
				NewLine.SalesTaxType = Enums.SalesTaxTypes.NonTaxable;
			Else
				NewLine.SalesTaxType = Enums.SalesTaxTypes.NonTaxable;
			EndIf;
		Except
			NewLine.SalesTaxType = Enums.SalesTaxTypes.NonTaxable;	
		EndTry;
		
		NewLine.LineTotal = DataLineItems[i].line_total;
		Try
			TaxableAmount = DataLineItems[i].taxable_amount;
			NewLine.TaxableAmount = TaxableAmount				
		Except
			NewLine.TaxableAmount = 0;
		EndTry;
				
	EndDo;
	
	NewCashSale.Write(DocumentWriteMode.Posting);
		
	///
	
	
	CashSaleData = New Map();	
	CashSaleData.Insert("company_name", NewCashSale.Company.Description);
	CashSaleData.Insert("company_code", NewCashSale.Company.Code);
	CashSaleData.Insert("ship_to_address_code", NewCashSale.ShipTo.Code);
	CashSaleData.Insert("ship_to_address_id", NewCashSale.ShipTo.Description);
	// date - convert into the same format as input
	CashSaleData.Insert("cash_sale_number", NewCashSale.Number);
	// payment method - same as input
	CashSaleData.Insert("payment_method", NewCashSale.PaymentMethod.Description);
	CashSaleData.Insert("date", NewCashSale.Date);
	CashSaleData.Insert("ref_num", NewCashSale.RefNum);
	CashSaleData.Insert("memo", NewCashSale.Memo);
	CashSaleData.Insert("sales_tax_total", NewCashSale.SalesTax);
	CashSaleData.Insert("doc_total", NewCashSale.DocumentTotalRC);

	Query = New Query("SELECT
	                  |	CashSaleLineItems.Product,
	                  |	CashSaleLineItems.Price,
	                  |	CashSaleLineItems.Quantity,
	                  |	CashSaleLineItems.LineTotal,
	                  |	CashSaleLineItems.SalesTaxType,
	                  |	CashSaleLineItems.TaxableAmount
	                  |FROM
	                  |	Document.CashSale.LineItems AS CashSaleLineItems
	                  |WHERE
	                  |	CashSaleLineItems.Ref = &CashSale");
	Query.SetParameter("CashSale", NewCashSale.Ref);
	Result = Query.Execute().Choose();
	
	LineItems = New Array();
	
	While Result.Next() Do
		
		LineItem = New Map();
		LineItem.Insert("item_code", Result.Product.Code);
		LineItem.Insert("api_code", GeneralFunctions.LeadingZeros(Result.Product.api_code));
		LineItem.Insert("item_description", Result.Product.Description);
		LineItem.Insert("price", Result.Price);
		LineItem.Insert("quantity", Result.Quantity);
		LineItem.Insert("taxable_amount", Result.TaxableAmount);
		LineItem.Insert("line_total", Result.LineTotal);
		If Result.SalesTaxType = Enums.SalesTaxTypes.Taxable Then
			LineItem.Insert("taxable_type", "taxable");
		ElsIf Result.SalesTaxType = Enums.SalesTaxTypes.NonTaxable Then
			LineItem.Insert("taxable_type", "non-taxable");
		EndIf;
		LineItems.Add(LineItem);
		
	EndDo;
	
	LineItemsData = New Map();
	LineItemsData.Insert("line_items", LineItems);
	
	CashSaleData.Insert("lines", LineItemsData);
	
	jsonout = InternetConnectionClientServer.EncodeJSON(CashSaleData,,True,True);                    
	
	Return jsonout;
	
EndFunction
