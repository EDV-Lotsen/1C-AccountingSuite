
Function inout(jsonin)
		
	Query = New Query("SELECT
	                  |	CashSale.Number,
	                  |	CashSale.Date,
	                  |	CashSale.Company,
	                  |	CashSale.SalesTax,
	                  |	CashSale.RefNum,
	                  |	CashSale.Memo,
	                  |	CashSale.DocumentTotalRC,
	                  |	CashSale.PaymentMethod,
	                  |	CashSale.ShipTo
	                  |FROM
	                  |	Document.CashSale AS CashSale");
	Result = Query.Execute().Choose();
	
	CashSales = New Array();
	
	While Result.Next() Do
		
		CashSale = New Map();
		CashSale.Insert("company_name", Result.Company.Description);
		CashSale.Insert("company_code", Result.Company.Code);
		CashSale.Insert("ship_to_address_code", Result.ShipTo.Code);
		CashSale.Insert("ship_to_address_id", Result.ShipTo.Description);
		// date - convert into the same format as input
		CashSale.Insert("cash_sale_number", Result.Number);
		// payment method - same format as input
		CashSale.Insert("payment_method", Result.PaymentMethod.Description);
		// date - convert to input format
		CashSale.Insert("date", Result.Date);
		CashSale.Insert("ref_num", Result.RefNum);
		CashSale.Insert("memo", Result.Memo);
		CashSale.Insert("sales_tax_total", Result.SalesTax);
		CashSale.Insert("doc_total", Result.DocumentTotalRC);
		
		CashSales.Add(CashSale);
		
	EndDo;
	
	CashSalesList = New Map();
	CashSalesList.Insert("cash_sales", CashSales);
	
	jsonout = InternetConnectionClientServer.EncodeJSON(CashSalesList,,True,True);                    
	
	Return jsonout;

EndFunction
