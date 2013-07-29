
Function inout(jsonin)
	
	ParsedJSON = InternetConnectionClientServer.DecodeJSON(jsonin);
	CashSaleCode = ParsedJSON.object_code;
	
	CashSale = Documents.CashSale.FindByNumber(CashSaleCode);
	
	NewCashSale = CashSale; // code below is copied from CahSalesPost
	
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
