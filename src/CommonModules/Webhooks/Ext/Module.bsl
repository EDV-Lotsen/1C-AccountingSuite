Function ReturnCashSaleMap(NewOrder) Export
	
	OrderData = New Map();
	OrderData.Insert("api_code", String(NewOrder.Ref.UUID()));
	OrderData.Insert("customer_api_code", String(NewOrder.Company.Ref.UUID()));
	OrderData.Insert("ship_to_api_code",String(NewOrder.ShipTo.Ref.UUID()));
	OrderData.Insert("bill_to_api_code",String(NewOrder.BillTo.Ref.UUID()));
	OrderData.Insert("ship_to_address_id",String(NewOrder.ShipTo.Description));
	OrderData.Insert("ship_to_first_name",String(NewOrder.ShipTo.FirstName));
	OrderData.Insert("ship_to_middle_name",String(NewOrder.ShipTo.MiddleName));
	OrderData.Insert("ship_to_address_line1",String(NewOrder.ShipTo.AddressLine1));
	OrderData.Insert("ship_to_address_line2",String(NewOrder.ShipTo.AddressLine2));
	OrderData.Insert("ship_to_city",String(NewOrder.ShipTo.City));
	OrderData.Insert("ship_to_state",String(NewOrder.ShipTo.State));
	OrderData.Insert("ship_to_zip",String(NewOrder.ShipTo.ZIP));
	OrderData.Insert("ship_to_country",String(NewOrder.ShipTo.Country));
	OrderData.Insert("ship_to_phone",String(NewOrder.ShipTo.Phone));
	OrderData.Insert("ship_to_cell",String(NewOrder.ShipTo.Cell));
	OrderData.Insert("ship_to_email",String(NewOrder.ShipTo.Email));
	OrderData.Insert("ship_to_sales_tax_code",String(NewOrder.ShipTo.SalesTaxCode));
	OrderData.Insert("ship_to_notes",String(NewOrder.ShipTo.Notes));
	
	OrderData.Insert("bill_to_address_id",String(NewOrder.BillTo.Description));
	OrderData.Insert("bill_to_first_name",String(NewOrder.BillTo.FirstName));
	OrderData.Insert("bill_to_middle_name",String(NewOrder.BillTo.MiddleName));
	OrderData.Insert("bill_to_address_line1",String(NewOrder.BillTo.AddressLine1));
	OrderData.Insert("bill_to_address_line2",String(NewOrder.BillTo.AddressLine2));
	OrderData.Insert("bill_to_city",String(NewOrder.BillTo.City));
	OrderData.Insert("bill_to_state",String(NewOrder.BillTo.State));
	OrderData.Insert("bill_to_zip",String(NewOrder.BillTo.ZIP));
	OrderData.Insert("bill_to_country",String(NewOrder.BillTo.Country));
	OrderData.Insert("bill_to_phone",String(NewOrder.BillTo.Phone));
	OrderData.Insert("bill_to_cell",String(NewOrder.BillTo.Cell));
	OrderData.Insert("bill_to_email",String(NewOrder.BillTo.Email));
	OrderData.Insert("bill_to_sales_tax_code",String(NewOrder.BillTo.SalesTaxCode));
	OrderData.Insert("bill_to_notes",String(NewOrder.BillTo.Notes));

	OrderData.Insert("company", string(NewOrder.Company));
	OrderData.Insert("cash_sale_number",NewOrder.Number);
	OrderData.Insert("date",NewOrder.Date);
	OrderData.Insert("ref_num", NewOrder.RefNum);
	OrderData.Insert("memo", NewOrder.Memo);
	OrderData.Insert("sales_tax_total", NewOrder.SalesTaxRC);
	OrderData.Insert("doc_total", NewOrder.DocumentTotalRC);	
	OrderData.Insert("line_subtotal", NewOrder.LineSubtotalRC);
	OrderData.Insert("discount", NewOrder.DiscountRC);
	OrderData.Insert("discount_percent", NewOrder.DiscountPercent);
	OrderData.Insert("subtotal", NewOrder.SubTotalRC);
	OrderData.Insert("shipping", NewOrder.ShippingRC);
	
	OrderData.Insert("email_to", NewOrder.EmailTo);
	OrderData.Insert("email_cc", NewOrder.EmailCC);
	OrderData.Insert("email_note", NewOrder.EmailNote);
	
	//include custom field
	
	OrderData2 = New Array();
	
	For Each LineItem in NewOrder.LineItems Do
			
			OrderData3 = New Map();
			OrderData3.Insert("api_code",String(LineItem.Product.Ref.UUID()));
			OrderData3.Insert("Product",LineItem.Product.Code);
			OrderData3.Insert("quantity",LineItem.Quantity);
			OrderData3.Insert("price",LineItem.Price);
			OrderData3.Insert("line_total",LineItem.LineTotal);
			
			OrderData2.Add(OrderData3);

		
	EndDo;
		
	OrderData.Insert("line_items",OrderData2);	


	
	Return OrderData;
EndFunction

Function ReturnSalesInvoiceMap(NewOrder) Export
	
	OrderData = New Map();
	OrderData.Insert("api_code", String(NewOrder.Ref.UUID()));
	OrderData.Insert("customer_api_code", String(NewOrder.Company.Ref.UUID()));
	OrderData.Insert("ship_to_api_code",String(NewOrder.ShipTo.Ref.UUID()));
	OrderData.Insert("bill_to_api_code",String(NewOrder.BillTo.Ref.UUID()));
	OrderData.Insert("ship_to_address_id",String(NewOrder.ShipTo.Description));
	OrderData.Insert("ship_to_first_name",String(NewOrder.ShipTo.FirstName));
	OrderData.Insert("ship_to_middle_name",String(NewOrder.ShipTo.MiddleName));
	OrderData.Insert("ship_to_address_line1",String(NewOrder.ShipTo.AddressLine1));
	OrderData.Insert("ship_to_address_line2",String(NewOrder.ShipTo.AddressLine2));
	OrderData.Insert("ship_to_city",String(NewOrder.ShipTo.City));
	OrderData.Insert("ship_to_state",String(NewOrder.ShipTo.State));
	OrderData.Insert("ship_to_zip",String(NewOrder.ShipTo.ZIP));
	OrderData.Insert("ship_to_country",String(NewOrder.ShipTo.Country));
	OrderData.Insert("ship_to_phone",String(NewOrder.ShipTo.Phone));
	OrderData.Insert("ship_to_cell",String(NewOrder.ShipTo.Cell));
	OrderData.Insert("ship_to_email",String(NewOrder.ShipTo.Email));
	OrderData.Insert("ship_to_sales_tax_code",String(NewOrder.ShipTo.SalesTaxCode));
	OrderData.Insert("ship_to_notes",String(NewOrder.ShipTo.Notes));
	
	OrderData.Insert("bill_to_address_id",String(NewOrder.BillTo.Description));
	OrderData.Insert("bill_to_first_name",String(NewOrder.BillTo.FirstName));
	OrderData.Insert("bill_to_middle_name",String(NewOrder.BillTo.MiddleName));
	OrderData.Insert("bill_to_address_line1",String(NewOrder.BillTo.AddressLine1));
	OrderData.Insert("bill_to_address_line2",String(NewOrder.BillTo.AddressLine2));
	OrderData.Insert("bill_to_city",String(NewOrder.BillTo.City));
	OrderData.Insert("bill_to_state",String(NewOrder.BillTo.State));
	OrderData.Insert("bill_to_zip",String(NewOrder.BillTo.ZIP));
	OrderData.Insert("bill_to_country",String(NewOrder.BillTo.Country));
	OrderData.Insert("bill_to_phone",String(NewOrder.BillTo.Phone));
	OrderData.Insert("bill_to_cell",String(NewOrder.BillTo.Cell));
	OrderData.Insert("bill_to_email",String(NewOrder.BillTo.Email));
	OrderData.Insert("bill_to_sales_tax_code",String(NewOrder.BillTo.SalesTaxCode));
	OrderData.Insert("bill_to_notes",String(NewOrder.BillTo.Notes));

	OrderData.Insert("company", string(NewOrder.Company));
	OrderData.Insert("sales_invoice_number",NewOrder.Number);
	OrderData.Insert("date",NewOrder.Date);
	OrderData.Insert("ref_num", NewOrder.RefNum);
	OrderData.Insert("memo", NewOrder.Memo);
	OrderData.Insert("sales_tax_total", NewOrder.SalesTaxRC);
	OrderData.Insert("doc_total", NewOrder.DocumentTotalRC);
	
	OrderData.Insert("line_subtotal", NewOrder.LineSubtotalRC);
	OrderData.Insert("discount", NewOrder.DiscountRC);
	OrderData.Insert("discount_percent", NewOrder.DiscountPercent);
	OrderData.Insert("subtotal", NewOrder.SubTotalRC);
	OrderData.Insert("shipping", NewOrder.ShippingRC);
	OrderData.Insert("email_to", NewOrder.EmailTo);
	OrderData.Insert("email_cc", NewOrder.EmailCC);
	OrderData.Insert("email_note", NewOrder.EmailNote);
	
	
	//include custom field
	
	OrderData2 = New Array();
	
	For Each LineItem in NewOrder.LineItems Do
			
			OrderData3 = New Map();
			OrderData3.Insert("api_code",String(LineItem.Product.Ref.UUID()));
			OrderData3.Insert("Product",LineItem.Product.Code);
			OrderData3.Insert("quantity",LineItem.Quantity);
			OrderData3.Insert("price",LineItem.Price);
			OrderData3.Insert("line_total",LineItem.LineTotal);
			OrderData2.Add(OrderData3);

		
	EndDo;
		
	OrderData.Insert("line_items",OrderData2);	


	
	Return OrderData	
EndFunction

Function ReturnCashReceiptMap(NewOrder) Export
	
	OrderData = New Map();
	OrderData.Insert("api_code", String(NewOrder.Ref.UUID()));
	OrderData.Insert("customer_api_code", String(NewOrder.Company.Ref.UUID()));
	////OrderData.Insert("description", NewOrder.Ref.Description);
	//OrderData.Insert("ship_to_api_code",String(NewOrder.ShipTo.Ref.UUID()));
	//OrderData.Insert("bill_to_api_code",String(NewOrder.BillTo.Ref.UUID()));
	//OrderData.Insert("ship_to_address_id",String(NewOrder.ShipTo.Description));
	//OrderData.Insert("ship_to_first_name",String(NewOrder.ShipTo.FirstName));
	//OrderData.Insert("ship_to_middle_name",String(NewOrder.ShipTo.MiddleName));
	//OrderData.Insert("ship_to_address_line1",String(NewOrder.ShipTo.AddressLine1));
	//OrderData.Insert("ship_to_address_line2",String(NewOrder.ShipTo.AddressLine2));
	//OrderData.Insert("ship_to_city",String(NewOrder.ShipTo.City));
	//OrderData.Insert("ship_to_state",String(NewOrder.ShipTo.State));
	//OrderData.Insert("ship_to_zip",String(NewOrder.ShipTo.ZIP));
	//OrderData.Insert("ship_to_country",String(NewOrder.ShipTo.Country));
	//OrderData.Insert("ship_to_phone",String(NewOrder.ShipTo.Phone));
	//OrderData.Insert("ship_to_cell",String(NewOrder.ShipTo.Cell));
	//OrderData.Insert("ship_to_email",String(NewOrder.ShipTo.Email));
	//OrderData.Insert("ship_to_sales_tax_code",String(NewOrder.ShipTo.SalesTaxCode));
	//OrderData.Insert("ship_to_notes",String(NewOrder.ShipTo.Notes));
	//
	//OrderData.Insert("bill_to_address_id",String(NewOrder.BillTo.Description));
	//OrderData.Insert("bill_to_first_name",String(NewOrder.BillTo.FirstName));
	//OrderData.Insert("bill_to_middle_name",String(NewOrder.BillTo.MiddleName));
	//OrderData.Insert("bill_to_address_line1",String(NewOrder.BillTo.AddressLine1));
	//OrderData.Insert("bill_to_address_line2",String(NewOrder.BillTo.AddressLine2));
	//OrderData.Insert("bill_to_city",String(NewOrder.BillTo.City));
	//OrderData.Insert("bill_to_state",String(NewOrder.BillTo.State));
	//OrderData.Insert("bill_to_zip",String(NewOrder.BillTo.ZIP));
	//OrderData.Insert("bill_to_country",String(NewOrder.BillTo.Country));
	//OrderData.Insert("bill_to_phone",String(NewOrder.BillTo.Phone));
	//OrderData.Insert("bill_to_cell",String(NewOrder.BillTo.Cell));
	//OrderData.Insert("bill_to_email",String(NewOrder.BillTo.Email));
	//OrderData.Insert("bill_to_sales_tax_code",String(NewOrder.BillTo.SalesTaxCode));
	//OrderData.Insert("bill_to_notes",String(NewOrder.BillTo.Notes));



	////
	OrderData.Insert("company", string(NewOrder.Company));
	////OrderData.Insert("company_code", NewOrder.CompanyCode);
	////OrderData.Insert("billTo", NewOrder.BillTo);
	////OrderData.Insert("confirmTo", NewOrder.ConfirmTo);
	OrderData.Insert("cash_receipt_number",NewOrder.Number);
	OrderData.Insert("date",NewOrder.Date);
	OrderData.Insert("ref_num", NewOrder.RefNum);
	////OrderData.Insert("currency", string(NewOrder.Currency));
	////OrderData.Insert("exchangeRate", NewOrder.ExchangeRate);
	////OrderData.Insert("priceIncludesVAT", NewOrder.PriceIncludesVAT);
	////OrderData.Insert("location", string(NewOrder.Location));
	////OrderData.Insert("deliveryDate", NewOrder.deliverydate);
	////OrderData.Insert("project", string(NewOrder.project));
	////OrderData.Insert("class", string(NewOrder.Class));
	//OrderData.Insert("memo", NewOrder.Memo);
	//OrderData.Insert("sales_tax_total", NewOrder.SalesTaxRC);
	////OrderData.Insert("DocumentTotal", NewOrder.DocumentTotal);
	//OrderData.Insert("doc_total", NewOrder.DocumentTotalRC);

	////OrderData.Insert("VATTotal", NewOrder.VATTotal);
	////OrderData.Insert("VATTotalRC", NewOrder.VATTotalRC);
	////OrderData.Insert("SalesPerson", string(NewOrder.SalesPerson));
	//
	//OrderData.Insert("line_subtotal", NewOrder.LineSubtotalRC);
	//OrderData.Insert("discount", NewOrder.DiscountRC);
	//OrderData.Insert("discount_percent", NewOrder.DiscountPercent);
	//OrderData.Insert("subtotal", NewOrder.SubTotalRC);
	//OrderData.Insert("shipping", NewOrder.ShippingRC);
	OrderData.Insert("deposit_type", NewOrder.DepositType);
	OrderData.Insert("bank_account", NewOrder.BankAccount.Description);
	OrderData.Insert("ar_account", NewOrder.ARAccount.Description);
	OrderData.Insert("sale_order", String(NewOrder.SalesOrder));
	OrderData.Insert("cash_payment", NewOrder.CashPayment);
	OrderData.Insert("payment_method", NewOrder.PaymentMethod.Description);
	OrderData.Insert("email_to", NewOrder.EmailTo);
	OrderData.Insert("email_cc", NewOrder.EmailCC);
	OrderData.Insert("email_note", NewOrder.EmailNote);
	
	
	//
	////include custom field
	//
	OrderData2 = New Array();
	//
	For Each LineItem in NewOrder.LineItems Do
	//		
			OrderData3 = New Map();
			OrderData3.Insert("document", String(LineItem.Document));
			OrderData3.Insert("document_api_code", String(LineItem.Document.Ref.UUID()));
	//		OrderData3.Insert("api_code",String(LineItem.Product.Ref.UUID()));
	//		OrderData3.Insert("Product",LineItem.Product.Code);
	//		//OrderData3.Insert("ProductDescription",LineItem.ProductDescription);
	//		OrderData3.Insert("quantity",LineItem.Quantity);
	//		//OrderData3.Insert("UM",LineItem.UM);
	//		OrderData3.Insert("price",LineItem.Price);
	//		//OrderData3.Insert("taxable_type",string(LineItem.SalesTaxType));
	//		//OrderData3.Insert("taxable_amount",LineItem.TaxableAmount);
	//		OrderData3.Insert("line_total",LineItem.LineTotal);
	//		//OrderData3.Insert("taxable",LineItem.Taxable);
	//		//OrderData3.Insert("VATCode",LineItem.VATCode);
	//		//OrderData3.Insert("VAT",LineItem.VAT);
	//		//OrderData3.Insert("Location",string(LineItem.Location));
	//		//OrderData3.Insert("DeliveryDate",LineItem.DeliveryDate);
	//		//OrderData3.Insert("Project",string(LineItem.Project));
	//		//OrderData3.Insert("Class",string(LineItem.Class));
			OrderData3.Insert("payment", LineItem.Payment);
			OrderData3.Insert("balance", LineItem.Balance);
			OrderData3.Insert("balance_fcy", LineItem.BalanceFCY);
			
			OrderData2.Add(OrderData3);
	

	//	
	EndDo;
	//	
	OrderData.Insert("line_items",OrderData2);
	
	OrderCM = New Array();
	//
	For Each CreditMemo in NewOrder.CreditMemos Do
	//		
			OrderCM2 = New Map();
			OrderCM2.Insert("document", String(CreditMemo.Document));
			OrderCM2.Insert("document_api_code", String(CreditMemo.Document.Ref.UUID()));
	//		OrderData3.Insert("api_code",String(LineItem.Product.Ref.UUID()));
	//		OrderData3.Insert("Product",LineItem.Product.Code);
	//		//OrderData3.Insert("ProductDescription",LineItem.ProductDescription);
	//		OrderData3.Insert("quantity",LineItem.Quantity);
	//		//OrderData3.Insert("UM",LineItem.UM);
	//		OrderData3.Insert("price",LineItem.Price);
	//		//OrderData3.Insert("taxable_type",string(LineItem.SalesTaxType));
	//		//OrderData3.Insert("taxable_amount",LineItem.TaxableAmount);
	//		OrderData3.Insert("line_total",LineItem.LineTotal);
	//		//OrderData3.Insert("taxable",LineItem.Taxable);
	//		//OrderData3.Insert("VATCode",LineItem.VATCode);
	//		//OrderData3.Insert("VAT",LineItem.VAT);
	//		//OrderData3.Insert("Location",string(LineItem.Location));
	//		//OrderData3.Insert("DeliveryDate",LineItem.DeliveryDate);
	//		//OrderData3.Insert("Project",string(LineItem.Project));
	//		//OrderData3.Insert("Class",string(LineItem.Class));
			OrderCM2.Insert("payment", CreditMemo.Payment);
			OrderCM2.Insert("balance", CreditMemo.Balance);
			OrderCM2.Insert("balance_fcy", CreditMemo.BalanceFCY);
			
			OrderCM.Add(OrderCM2);
	

	//	
	EndDo;

	OrderData.Insert("credit_memos",OrderCM);

	Return OrderData;	
EndFunction

Function ReturnSalesReturnMap(NewOrder) Export
	
	OrderData = New Map();
	OrderData.Insert("api_code", String(NewOrder.Ref.UUID()));
	OrderData.Insert("customer_api_code", String(NewOrder.Company.Ref.UUID()));
	OrderData.Insert("company", string(NewOrder.Company));
	OrderData.Insert("credit_memo_number",NewOrder.Number);
	OrderData.Insert("date",NewOrder.Date);
	OrderData.Insert("ref_num", NewOrder.RefNum);
	//OrderData.Insert("currency", string(NewOrder.Currency));
	OrderData.Insert("return_type", NewOrder.ReturnType);
	
	OrderData.Insert("ar_account", NewOrder.ARAccount.Description);
	OrderData.Insert("sales_invoice", String(NewOrder.ParentDocument));
	OrderData.Insert("email_to", NewOrder.EmailTo);
	OrderData.Insert("email_cc", NewOrder.EmailCC);
	OrderData.Insert("email_note", NewOrder.EmailNote);
	OrderData.Insert("memo", NewOrder.Memo);
	OrderData.Insert("line_subtotal", NewOrder.LineSubtotalRC);
	OrderData.Insert("sales_tax", NewOrder.SalesTaxRC);
	OrderData.Insert("doc_total", NewOrder.DocumentTotalRC);
	
	
	OrderData2 = New Array();
	
	For Each LineItem in NewOrder.LineItems Do
		
			OrderData3 = New Map();

			OrderData3.Insert("api_code", String(LineItem.Product.Ref.UUID()));
			OrderData3.Insert("item", LineItem.Product.Code);
			OrderData3.Insert("product_description", LineItem.ProductDescription);
			OrderData3.Insert("quantity",LineItem.Quantity);
			OrderData3.Insert("price",LineItem.Price);
			OrderData3.Insert("line_total",LineItem.LineTotal);
			
			OrderData2.Add(OrderData3);
	
	EndDo;
		
	OrderData.Insert("line_items",OrderData2);
	
	Return OrderData;
EndFunction

Function ReturnPurchaseReturnMap(NewOrder) Export
	OrderData = New Map();
	OrderData.Insert("api_code", String(NewOrder.Ref.UUID()));
	OrderData.Insert("company_api_code", String(NewOrder.Company.Ref.UUID()));
	OrderData.Insert("company", string(NewOrder.Company));
	OrderData.Insert("purchase_return_number",NewOrder.Number);
	OrderData.Insert("date",NewOrder.Date);
	OrderData.Insert("ref_num", NewOrder.RefNum);
	//OrderData.Insert("currency", string(NewOrder.Currency));
	//OrderData.Insert("return_type", NewOrder.ReturnType);
	
	//OrderData.Insert("ar_account", NewOrder.ARAccount.Description);
	OrderData.Insert("purchase_invoice", String(NewOrder.ParentDocument));
	//OrderData.Insert("email_to", NewOrder.EmailTo);
	//OrderData.Insert("email_cc", NewOrder.EmailCC);
	//OrderData.Insert("email_note", NewOrder.EmailNote);
	OrderData.Insert("memo", NewOrder.Memo);
	OrderData.Insert("doc_total", NewOrder.DocumentTotalRC);
	
	OrderData2 = New Array();
	
	For Each LineItem in NewOrder.LineItems Do
		
			OrderData3 = New Map();

			OrderData3.Insert("api_code", String(LineItem.Product.Ref.UUID()));
			OrderData3.Insert("item", LineItem.Product.Code);
			OrderData3.Insert("product_description", LineItem.ProductDescription);
			OrderData3.Insert("quantity",LineItem.Quantity);
			OrderData3.Insert("price",LineItem.Price);			
			
			
			OrderData3.Insert("line_total",LineItem.LineTotal);
			
			OrderData2.Add(OrderData3);
	
	EndDo;
		
	OrderData.Insert("line_items",OrderData2);
	
	Return OrderData;	
EndFunction

Function ReturnPurchaseInvoiceMap(NewOrder) Export
	OrderData = New Map();
	OrderData.Insert("api_code", String(NewOrder.Ref.UUID()));
	OrderData.Insert("company_api_code", String(NewOrder.Company.Ref.UUID()));
	OrderData.Insert("company", string(NewOrder.Company));
	OrderData.Insert("bill_number",NewOrder.Number);
	OrderData.Insert("bill_date",NewOrder.Date);
	OrderData.Insert("due_date",NewOrder.DueDate);
	OrderData.Insert("terms", string(NewOrder.Terms));
	//OrderData.Insert("ref_num", NewOrder.RefNum);
	//OrderData.Insert("currency", string(NewOrder.Currency));
	//OrderData.Insert("return_type", NewOrder.ReturnType);
	
	OrderData.Insert("ap_account", NewOrder.APAccount.Description);
	//OrderData.Insert("purchase_invoice", String(NewOrder.ParentDocument));
	//OrderData.Insert("email_to", NewOrder.EmailTo);
	//OrderData.Insert("email_cc", NewOrder.EmailCC);
	//OrderData.Insert("email_note", NewOrder.EmailNote);
	OrderData.Insert("memo", NewOrder.Memo);
	OrderData.Insert("doc_total", NewOrder.DocumentTotalRC);
	OrderData.Insert("project", string(NewOrder.Project));
	OrderData.Insert("act_location", string(NewOrder.LocationActual));
	OrderData.Insert("class", string(NewOrder.Class));
	OrderData.Insert("url", string(NewOrder.URL));


	
	OrderData2 = New Array();
	
	For Each LineItem in NewOrder.LineItems Do
		
			OrderData3 = New Map();

			OrderData3.Insert("api_code", String(LineItem.Product.Ref.UUID()));
			OrderData3.Insert("item", LineItem.Product.Code);
			OrderData3.Insert("product_description", LineItem.ProductDescription);
			OrderData3.Insert("quantity",LineItem.Quantity);
			OrderData3.Insert("price",LineItem.Price);
			OrderData3.Insert("line_total",LineItem.LineTotal);
			
			OrderData3.Insert("order_price",LineItem.OrderPrice);
			OrderData3.Insert("unit_of_measure", string(LineItem.UM));
			OrderData3.Insert("po_number",string(LineItem.Order));
			OrderData3.Insert("exp_location",LineItem.Location);
			OrderData3.Insert("act_location",LineItem.LocationActual);
			OrderData3.Insert("exp_delivery",LineItem.DeliveryDate);
			OrderData3.Insert("act_delivery",LineItem.DeliveryDateActual);
			OrderData3.Insert("price",string(LineItem.Project));
			OrderData3.Insert("class",string(LineItem.Class));

			
			OrderData2.Add(OrderData3);
	
	EndDo;
		
	OrderData.Insert("line_items",OrderData2);
	
	OrderData4 = New Array();
	
	For Each Account in NewOrder.Accounts Do
		
			OrderData5 = New Map();

			OrderData5.Insert("account", String(Account.Account));
			OrderData5.Insert("amount", Account.Amount);
			OrderData5.Insert("memo", Account.Memo);
			OrderData5.Insert("project", Account.Project);
			OrderData5.Insert("class", Account.Class);
			
			OrderData4.Add(OrderData5);
	
	EndDo;
		
	OrderData.Insert("expenses",OrderData4);
	
	Return OrderData;	
EndFunction

Function ReturnInvoicePaymentMap(NewOrder) Export
	OrderData = New Map();
	OrderData.Insert("api_code", String(NewOrder.Ref.UUID()));
	OrderData.Insert("company_api_code", String(NewOrder.Company.Ref.UUID()));
	OrderData.Insert("company", string(NewOrder.Company));
	OrderData.Insert("invoice_payment_number",NewOrder.Number);
	OrderData.Insert("invoice_payment_date",NewOrder.Date);
	//OrderData.Insert("due_date",NewOrder.DueDate);
	//OrderData.Insert("terms", string(NewOrder.Terms));
	//OrderData.Insert("ref_num", NewOrder.RefNum);
	//OrderData.Insert("currency", string(NewOrder.Currency));
	//OrderData.Insert("return_type", NewOrder.ReturnType);
	OrderData.Insert("bank_account", String(NewOrder.BankAccount));
	OrderData.Insert("payment_method", String(NewOrder.PaymentMethod));
	
	//OrderData.Insert("ap_account", NewOrder.APAccount.Description);
	//OrderData.Insert("purchase_invoice", String(NewOrder.ParentDocument));
	//OrderData.Insert("email_to", NewOrder.EmailTo);
	//OrderData.Insert("email_cc", NewOrder.EmailCC);
	//OrderData.Insert("email_note", NewOrder.EmailNote);
	OrderData.Insert("memo", NewOrder.Memo);
	OrderData.Insert("doc_total", NewOrder.DocumentTotalRC);
	//OrderData.Insert("project", string(NewOrder.Project));
	//OrderData.Insert("act_location", string(NewOrder.LocationActual));
	//OrderData.Insert("class", string(NewOrder.Class));
	//OrderData.Insert("url", string(NewOrder.URL));
	
	OrderData2 = New Array();
	
	For Each LineItem in NewOrder.LineItems Do
		
			OrderData3 = New Map();

			OrderData3.Insert("api_code", String(LineItem.Document.Ref.UUID()));
			OrderData3.Insert("document", String(LineItem.Document));
			//OrderData3.Insert("product_description", LineItem.ProductDescription);
			//OrderData3.Insert("quantity",LineItem.Quantity);
			//OrderData3.Insert("price",LineItem.Price);
			//OrderData3.Insert("line_total",LineItem.LineTotal);
			//
			//OrderData3.Insert("order_price",LineItem.OrderPrice);
			//OrderData3.Insert("unit_of_measure", string(LineItem.UM));
			//OrderData3.Insert("po_number",string(LineItem.Order));
			//OrderData3.Insert("exp_location",LineItem.Location);
			//OrderData3.Insert("act_location",LineItem.LocationActual);
			//OrderData3.Insert("exp_delivery",LineItem.DeliveryDate);
			//OrderData3.Insert("act_delivery",LineItem.DeliveryDateActual);
			//OrderData3.Insert("price",string(LineItem.Project));
			//OrderData3.Insert("class",string(LineItem.Class));
			OrderData3.Insert("balance", LineItem.Balance);
			OrderData3.Insert("payment", LineItem.Payment);

			
			OrderData2.Add(OrderData3);
	
	EndDo;
		
	OrderData.Insert("line_items",OrderData2);
	Return OrderData;
	
EndFunction

Function ReturnDepositMap(NewOrder) Export
	OrderData = New Map();
	OrderData.Insert("api_code", String(NewOrder.Ref.UUID()));
	//OrderData.Insert("company_api_code", String(NewOrder.Company.Ref.UUID()));
	//OrderData.Insert("company", string(NewOrder.Company));
	OrderData.Insert("deposit_number",NewOrder.Number);
	OrderData.Insert("deposit_date",NewOrder.Date);
	//OrderData.Insert("due_date",NewOrder.DueDate);
	//OrderData.Insert("terms", string(NewOrder.Terms));
	//OrderData.Insert("ref_num", NewOrder.RefNum);
	//OrderData.Insert("currency", string(NewOrder.Currency));
	//OrderData.Insert("return_type", NewOrder.ReturnType);
	OrderData.Insert("bank_account", String(NewOrder.BankAccount));
	//OrderData.Insert("bank_account", String(NewOrder.PaymentMethod));
	
	//OrderData.Insert("ap_account", NewOrder.APAccount.Description);
	//OrderData.Insert("purchase_invoice", String(NewOrder.ParentDocument));
	//OrderData.Insert("email_to", NewOrder.EmailTo);
	//OrderData.Insert("email_cc", NewOrder.EmailCC);
	//OrderData.Insert("email_note", NewOrder.EmailNote);
	OrderData.Insert("memo", NewOrder.Memo);
	OrderData.Insert("doc_total", NewOrder.DocumentTotalRC);
	//OrderData.Insert("project", string(NewOrder.Project));
	//OrderData.Insert("act_location", string(NewOrder.LocationActual));
	//OrderData.Insert("class", string(NewOrder.Class));
	//OrderData.Insert("url", string(NewOrder.URL));
	
	OrderData2 = New Array();
	
	For Each LineItem in NewOrder.LineItems Do
		
			OrderData3 = New Map();

			OrderData3.Insert("document_api_code", String(LineItem.Document.Ref.UUID()));
			OrderData3.Insert("document", String(LineItem.Document));
			OrderData3.Insert("customer_api_code", String(LineItem.Customer.Ref.UUID()));
			OrderData3.Insert("customer_name", String(LineItem.Customer));
			OrderData3.Insert("line_total",	LineItem.DocumentTotalRC);
			OrderData3.Insert("deposit", LineItem.Payment);

			
			OrderData2.Add(OrderData3);
	
	EndDo;
		
	OrderData.Insert("line_items",OrderData2);
	
	OrderData4 = New Array();
	
	For Each Account in NewOrder.Accounts Do
		
			OrderData5 = New Map();

			//OrderData5.Insert("document_api_code", String(LineItem.Document.Ref.UUID()));
			//OrderData3.Insert("document", String(LineItem.Document));
			OrderData5.Insert("customer_api_code", String(Account.Company.Ref.UUID()));
			OrderData5.Insert("customer_name", String(Account.Company));
			OrderData5.Insert("amount",	Account.Amount);
			OrderData5.Insert("memo", Account.Memo);
			

			
			OrderData4.Add(OrderData5);
	
	EndDo;
		
	OrderData.Insert("G/L_accounts",OrderData4);
	Return OrderData;
EndFunction

Function ReturnCheckMap(NewOrder) Export
	OrderData = New Map();
	OrderData.Insert("api_code", String(NewOrder.Ref.UUID()));
	OrderData.Insert("company_api_code", String(NewOrder.Company.Ref.UUID()));
	OrderData.Insert("company", string(NewOrder.Company));
	OrderData.Insert("check_number",NewOrder.Number);
	OrderData.Insert("check_date",NewOrder.Date);
	//OrderData.Insert("due_date",NewOrder.DueDate);
	//OrderData.Insert("terms", string(NewOrder.Terms));
	//OrderData.Insert("ref_num", NewOrder.RefNum);
	//OrderData.Insert("currency", string(NewOrder.Currency));
	//OrderData.Insert("return_type", NewOrder.ReturnType);
	OrderData.Insert("bank_account", String(NewOrder.BankAccount));
	OrderData.Insert("payment_method", String(NewOrder.PaymentMethod));
	
	//OrderData.Insert("ap_account", NewOrder.APAccount.Description);
	//OrderData.Insert("purchase_invoice", String(NewOrder.ParentDocument));
	//OrderData.Insert("email_to", NewOrder.EmailTo);
	//OrderData.Insert("email_cc", NewOrder.EmailCC);
	//OrderData.Insert("email_note", NewOrder.EmailNote);
	OrderData.Insert("memo", NewOrder.Memo);
	OrderData.Insert("amount", NewOrder.DocumentTotalRC);
	//OrderData.Insert("project", string(NewOrder.Project));
	//OrderData.Insert("act_location", string(NewOrder.LocationActual));
	//OrderData.Insert("class", string(NewOrder.Class));
	OrderData.Insert("url", string(NewOrder.URL));
	
	OrderData2 = New Array();
	
	For Each LineItem in NewOrder.LineItems Do
		
			OrderData3 = New Map();

			OrderData3.Insert("account_api_code", String(LineItem.Account.Ref.UUID()));
			OrderData3.Insert("account_code", String(LineItem.Account.Code));
			//OrderData3.Insert("account_description", LineItem.AccountDescription);
			OrderData3.Insert("project", String(LineItem.Project));
			OrderData3.Insert("memo", LineItem.Memo);
			OrderData3.Insert("amount", LineItem.Amount);

			
			OrderData2.Add(OrderData3);
	
	EndDo;
		
	OrderData.Insert("line_items",OrderData2);
	
	
	Return OrderData;
EndFunction

Function ReturnBankTransferMap(NewOrder) Export
	OrderData = New Map();
	
	OrderData.Insert("api_code", String(NewOrder.Ref.UUID()));
	OrderData.Insert("transfer_number",NewOrder.Number);
	OrderData.Insert("transfer_date",NewOrder.Date);
	OrderData.Insert("account_from", String(NewOrder.AccountFrom));
	OrderData.Insert("account_to", String(NewOrder.AccountTo));
	
	OrderData.Insert("memo", NewOrder.Memo);
	OrderData.Insert("amount", NewOrder.Amount);
	
		
	Return OrderData;
	
EndFunction

Function ReturnBankReconMap(NewOrder) Export
	
	OrderData = New Map();
	
	OrderData.Insert("api_code", String(NewOrder.Ref.UUID()));
	OrderData.Insert("beginning_balance", NewOrder.BeginningBalance);
	OrderData.Insert("ending_balance", NewOrder.EndingBalance);
	OrderData.Insert("bank_account", String(NewOrder.BankAccount));
	OrderData.Insert("statement_date", String(NewOrder.StatementToDate));
	
	OrderData.Insert("charge_date", NewOrder.ServiceChargeDate);
	OrderData.Insert("service_charge", NewOrder.ServiceCharge);
	OrderData.Insert("interest_earned", NewOrder.InterestEarned);
	OrderData.Insert("earned_date", NewOrder.InterestEarnedDate);
	OrderData.Insert("memo", NewOrder.Memo);
	OrderData.Insert("cleared_amount", NewOrder.ClearedAmount);
	OrderData.Insert("cleared_balance", NewOrder.ClearedBalance);
	OrderData.Insert("difference", NewOrder.Difference);
	
		
	OrderData2 = New Array();
	
	For Each LineItem in NewOrder.LineItems Do
		
			OrderData3 = New Map();

			OrderData3.Insert("transaction_api_code", String(LineItem.Transaction.Ref.UUID()));
			OrderData3.Insert("transaction_description", String(LineItem.Transaction));
			OrderData3.Insert("transaction_number", LineItem.DocNumber);
			OrderData3.Insert("date", LineItem.Date);
			OrderData3.Insert("company", String(LineItem.Company));
			OrderData3.Insert("company_api_code", String(LineItem.Company.Ref.UUID()));
			OrderData3.Insert("is_cleared", LineItem.Cleared);
			OrderData3.Insert("transaction_amount", LineItem.TransactionAmount);
			
			OrderData2.Add(OrderData3);
	
	EndDo;
		
	OrderData.Insert("line_items",OrderData2);
	
	
	Return OrderData;
EndFunction

Function ReturnGJEntryMap(NewOrder) Export
	
	OrderData = New Map();
	
	OrderData.Insert("api_code", String(NewOrder.Ref.UUID()));
	OrderData.Insert("date", NewOrder.Date);
	OrderData.Insert("gj_number", NewOrder.Number);
	OrderData.Insert("memo", NewOrder.Memo);
	OrderData.Insert("is_adjusting", NewOrder.Adjusting);
	OrderData.Insert("doc_total", NewOrder.DocumentTotalRc);
	
		
	OrderData2 = New Array();
	
	For Each LineItem in NewOrder.LineItems Do
		
			OrderData3 = New Map();

			OrderData3.Insert("account_api_code", String(LineItem.Account.Ref.UUID()));
			OrderData3.Insert("account_description", LineItem.Account.Description);
			OrderData3.Insert("account_code", LineItem.Account.Code);
			OrderData3.Insert("memo", LineItem.Memo);
			OrderData3.Insert("company", String(LineItem.Company));
			OrderData3.Insert("company_api_code", String(LineItem.Company.Ref.UUID()));
			OrderData3.Insert("amount_dr", LineItem.AmountDr);
			OrderData3.Insert("amount_cr", LineItem.AmountCr);
			
			OrderData2.Add(OrderData3);
	
	EndDo;
		
	OrderData.Insert("line_items",OrderData2);
	
	
	Return OrderData;
EndFunction

Function ReturnPurchaseOrderMap(NewOrder) Export
	
	OrderData = New Map();
	OrderData.Insert("api_code", String(NewOrder.Ref.UUID()));
	OrderData.Insert("customer_api_code", String(NewOrder.Company.Ref.UUID()));
	OrderData.Insert("address_api_code",String(NewOrder.PurchaseAddress.Ref.UUID()));
	OrderData.Insert("ds_address_api_code",String(NewOrder.DropshipAddress.Ref.UUID()));
	OrderData.Insert("purchase_address_id",String(NewOrder.PurchaseAddress.Description));
	OrderData.Insert("purchase_first_name",String(NewOrder.PurchaseAddress.FirstName));
	OrderData.Insert("purchase_middle_name",String(NewOrder.PurchaseAddress.MiddleName));
	OrderData.Insert("purchase_address_line1",String(NewOrder.PurchaseAddress.AddressLine1));
	OrderData.Insert("purchase_address_line2",String(NewOrder.PurchaseAddress.AddressLine2));
	OrderData.Insert("purchase_city",String(NewOrder.PurchaseAddress.City));
	OrderData.Insert("purchase_state",String(NewOrder.PurchaseAddress.State));
	OrderData.Insert("purchase_zip",String(NewOrder.PurchaseAddress.ZIP));
	OrderData.Insert("purchase_country",String(NewOrder.PurchaseAddress.Country));
	OrderData.Insert("purchase_phone",String(NewOrder.PurchaseAddress.Phone));
	OrderData.Insert("purchase_cell",String(NewOrder.PurchaseAddress.Cell));
	OrderData.Insert("purchase_email",String(NewOrder.PurchaseAddress.Email));
	OrderData.Insert("purchase_sales_tax_code",String(NewOrder.PurchaseAddress.SalesTaxCode));
	OrderData.Insert("purchase_notes",String(NewOrder.PurchaseAddress.Notes));
	OrderData.Insert("ds_address_id",String(NewOrder.DropshipAddress.Description));
	OrderData.Insert("ds_customer",String(NewOrder.DropshipCustomer.Description));
	OrderData.Insert("ds_customer_api_code", String(NewOrder.DropshipCustomer.Ref.UUID()));

	OrderData.Insert("company", string(NewOrder.Company));
	OrderData.Insert("project", string(NewOrder.Project));
	OrderData.Insert("class", string(NewOrder.Class));
	OrderData.Insert("po_number",NewOrder.Number);
	OrderData.Insert("po_date",NewOrder.Date);
	OrderData.Insert("delivery_date",NewOrder.DeliveryDate);
	OrderData.Insert("memo", NewOrder.Memo);
	OrderData.Insert("doc_total", NewOrder.DocumentTotalRC);
	
	OrderData2 = New Array();
	
	For Each LineItem in NewOrder.LineItems Do
			
			OrderData3 = New Map();
			OrderData3.Insert("api_code",String(LineItem.Product.Ref.UUID()));
			OrderData3.Insert("item",LineItem.Product.Code);
			OrderData3.Insert("item_description",LineItem.ProductDescription);
			OrderData3.Insert("quantity",LineItem.Quantity);
			OrderData3.Insert("unit_of_measure",String(LineItem.UM));
			OrderData3.Insert("price",LineItem.Price);
			OrderData3.Insert("line_total",LineItem.LineTotal);
			OrderData3.Insert("project",String(LineItem.Project));
			OrderData3.Insert("class",String(LineItem.Class));
			OrderData2.Add(OrderData3);
	
	EndDo;
		
	OrderData.Insert("line_items",OrderData2);	

	Return OrderData;

EndFunction