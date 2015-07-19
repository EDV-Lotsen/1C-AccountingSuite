Function ReturnChartOfAccountMap(NewAccount) Export
	AccountData = New Map();
	AccountData.Insert("account_code", NewAccount.Code);
	AccountData.Insert("api_code", String(NewAccount.Ref.UUID()));
	AccountData.Insert("account_name", NewAccount.Description);
	AccountData.Insert("account_type", NewAccount.AccountType);
	
	AccountData.Insert("1099_category", String(NewAccount.Category1099));
	AccountData.Insert("currency", NewAccount.Currency.Description);
	AccountData.Insert("cash_flow_section", String(NewAccount.CashFlowSection));
	AccountData.Insert("memo", NewAccount.Memo);
	AccountData.Insert("credit_card", NewAccount.CreditCard);
	AccountData.Insert("reclass_account", String(NewAccount.ReclassAccount));
	AccountData.Insert("rcl", NewAccount.RCL);
	AccountData.Insert("credit_card", NewAccount.RetainedEarnings);
		
	Return AccountData;	
EndFunction

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
//	OrderData.Insert("ship_to_sales_tax_code",String(NewOrder.ShipTo.SalesTaxCode));
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
	//OrderData.Insert("bill_to_sales_tax_code",String(NewOrder.BillTo.SalesTaxCode));
	OrderData.Insert("bill_to_notes",String(NewOrder.BillTo.Notes));

	OrderData.Insert("company", string(NewOrder.Company));
	OrderData.Insert("cash_sale_number",NewOrder.Number);
	OrderData.Insert("date",NewOrder.Date);
	OrderData.Insert("ref_num", NewOrder.RefNum);
	OrderData.Insert("memo", NewOrder.Memo);
	OrderData.Insert("sales_tax_total", NewOrder.SalesTaxRC);
	OrderData.Insert("doc_total", NewOrder.DocumentTotalRC);	
	OrderData.Insert("line_subtotal", NewOrder.LineSubtotal);
	OrderData.Insert("discount", NewOrder.Discount);
	OrderData.Insert("discount_percent", NewOrder.DiscountPercent);
	OrderData.Insert("subtotal", NewOrder.SubTotal);
	OrderData.Insert("shipping", NewOrder.Shipping);
	
	OrderData.Insert("email_to", NewOrder.EmailTo);
	OrderData.Insert("email_cc", NewOrder.EmailCC);
	OrderData.Insert("email_note", NewOrder.EmailNote);
	
	//include custom field
	
	OrderData2 = New Array();
	
	For Each LineItem in NewOrder.LineItems Do
			
			OrderData3 = New Map();
			OrderData3.Insert("api_code",String(LineItem.Product.Ref.UUID()));
			OrderData3.Insert("Product",LineItem.Product.Code);
			OrderData3.Insert("quantity",LineItem.QtyUnits);
			OrderData3.Insert("price",LineItem.PriceUnits);
			OrderData3.Insert("UoM",LineItem.Unit);
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
	//OrderData.Insert("ship_to_sales_tax_code",String(NewOrder.ShipTo.SalesTaxCode));
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
	//OrderData.Insert("bill_to_sales_tax_code",String(NewOrder.BillTo.SalesTaxCode));
	OrderData.Insert("bill_to_notes",String(NewOrder.BillTo.Notes));

	OrderData.Insert("company", string(NewOrder.Company));
	OrderData.Insert("sales_invoice_number",NewOrder.Number);
	OrderData.Insert("date",NewOrder.Date);
	OrderData.Insert("ref_num", NewOrder.RefNum);
	OrderData.Insert("memo", NewOrder.Memo);
	OrderData.Insert("sales_tax_total", NewOrder.SalesTax);
	OrderData.Insert("doc_total", NewOrder.DocumentTotal);
	
	OrderData.Insert("line_subtotal", NewOrder.LineSubtotal);
	OrderData.Insert("discount", NewOrder.Discount);
	OrderData.Insert("discount_percent", NewOrder.DiscountPercent);
	OrderData.Insert("subtotal", NewOrder.SubTotal);
	OrderData.Insert("shipping", NewOrder.Shipping);
	OrderData.Insert("email_to", NewOrder.EmailTo);
	OrderData.Insert("email_cc", NewOrder.EmailCC);
	OrderData.Insert("email_note", NewOrder.EmailNote);
	
	
	//include custom field
	
	OrderData2 = New Array();
	
	For Each LineItem in NewOrder.LineItems Do
			
			OrderData3 = New Map();
			OrderData3.Insert("api_code",String(LineItem.Product.Ref.UUID()));
			OrderData3.Insert("Product",LineItem.Product.Code);
			OrderData3.Insert("quantity",LineItem.QtyUnits);
			OrderData3.Insert("price",LineItem.PriceUnits);
			OrderData3.Insert("UoM",LineItem.Unit);
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
			//OrderData3.Insert("payment", LineItem.Payment);
			//OrderData3.Insert("balance", LineItem.Balance);
			//OrderData3.Insert("balance_fcy", LineItem.BalanceFCY);
			
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
			//OrderCM2.Insert("balance", CreditMemo.Balance);
			//OrderCM2.Insert("balance_fcy", CreditMemo.BalanceFCY);
			
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
	OrderData.Insert("line_subtotal", NewOrder.LineSubtotal);
	OrderData.Insert("sales_tax", NewOrder.SalesTax);
	OrderData.Insert("doc_total", NewOrder.DocumentTotalRC);
	
	
	OrderData2 = New Array();
	
	For Each LineItem in NewOrder.LineItems Do
		
			OrderData3 = New Map();

			OrderData3.Insert("api_code", String(LineItem.Product.Ref.UUID()));
			OrderData3.Insert("item", LineItem.Product.Code);
			OrderData3.Insert("product_description", LineItem.ProductDescription);
			OrderData3.Insert("quantity",LineItem.QtyUnits);
			OrderData3.Insert("price",LineItem.PriceUnits);
			OrderData3.Insert("UoM",LineItem.Unit);
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
			OrderData3.Insert("quantity",LineItem.QtyUnits);
			OrderData3.Insert("price",LineItem.PriceUnits);			
			OrderData3.Insert("UoM",LineItem.Unit);
			OrderData3.Insert("line_total",LineItem.LineTotal);
			
			OrderData2.Add(OrderData3);
	
	EndDo;
		
	OrderData.Insert("line_items",OrderData2);
	
	Return OrderData;	
EndFunction

Function ReturnPurchaseInvoiceMap(NewOrder) Export
	OrderData = New Map();
	OrderData.Insert("api_code", String(NewOrder.Ref.UUID()));
	OrderData.Insert("vendor_api_code", String(NewOrder.Company.Ref.UUID()));
	OrderData.Insert("vendor_name", string(NewOrder.Company));
	OrderData.Insert("vendor_code", string(NewOrder.Company.Code));
	OrderData.Insert("bill_number",NewOrder.Number);
	OrderData.Insert("bill_date",NewOrder.Date);
	OrderData.Insert("due_date",NewOrder.DueDate);
	OrderData.Insert("terms", string(NewOrder.Terms));
	
	OrderData.Insert("ap_account", NewOrder.APAccount.Description);
	OrderData.Insert("memo", NewOrder.Memo);
	OrderData.Insert("doc_total", NewOrder.DocumentTotalRC);
	OrderData.Insert("project", string(NewOrder.Project));
	OrderData.Insert("act_location", string(NewOrder.LocationActual));
	OrderData.Insert("class", string(NewOrder.Class));
	OrderData.Insert("url", string(NewOrder.URL));
	
	OrderData.Insert("address_api_code",String(NewOrder.CompanyAddress.Ref.UUID()));
	OrderData.Insert("address_address_id",String(NewOrder.CompanyAddress.Description));
	OrderData.Insert("address_first_name",String(NewOrder.CompanyAddress.FirstName));
	OrderData.Insert("address_middle_name",String(NewOrder.CompanyAddress.MiddleName));
	OrderData.Insert("address_address_line1",String(NewOrder.CompanyAddress.AddressLine1));
	OrderData.Insert("address_address_line2",String(NewOrder.CompanyAddress.AddressLine2));
	OrderData.Insert("address_city",String(NewOrder.CompanyAddress.City));
	OrderData.Insert("address_state",String(NewOrder.CompanyAddress.State));
	OrderData.Insert("address_zip",String(NewOrder.CompanyAddress.ZIP));
	OrderData.Insert("address_country",String(NewOrder.CompanyAddress.Country));
	OrderData.Insert("address_phone",String(NewOrder.CompanyAddress.Phone));
	OrderData.Insert("address_cell",String(NewOrder.CompanyAddress.Cell));
	OrderData.Insert("address_email",String(NewOrder.CompanyAddress.Email));
	//OrderData.Insert("address_sales_tax_code",String(NewOrder.CompanyAddress.SalesTaxCode));
	OrderData.Insert("address_notes",String(NewOrder.CompanyAddress.Notes));


	
	OrderData2 = New Array();
	
	For Each LineItem in NewOrder.LineItems Do
		
			OrderData3 = New Map();

			OrderData3.Insert("api_code", String(LineItem.Product.Ref.UUID()));
			OrderData3.Insert("item", LineItem.Product.Code);
			OrderData3.Insert("product_description", LineItem.ProductDescription);
			OrderData3.Insert("quantity",LineItem.QtyUnits);
			OrderData3.Insert("price",LineItem.PriceUnits);
			OrderData3.Insert("UoM",LineItem.Unit);
			OrderData3.Insert("line_total",LineItem.LineTotal);
			                 
			OrderData3.Insert("order_price",LineItem.OrderPriceUnits);
			//OrderData3.Insert("unit_of_measure", string(LineItem.UM));
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

Function ReturnItemAdjustmentMap(NewOrder) Export
	
	OrderData = New Map();
	
	OrderData.Insert("api_code", String(NewOrder.Ref.UUID()));
	OrderData.Insert("item",String(NewOrder.Product));
	OrderData.Insert("date",String(NewOrder.Date));
	OrderData.Insert("location", String(NewOrder.Location));
	OrderData.Insert("layer", String(NewOrder.Layer));
	OrderData.Insert("account", String(NewOrder.IncomeExpenseAccount));
	
	OrderData.Insert("quantity", NewOrder.Quantity);
	OrderData.Insert("amount", NewOrder.Amount);
	
		
	Return OrderData;
	
EndFunction

Function ReturnSalesTaxPaymentMap(NewOrder) Export
	
	OrderData = New Map();
	
	OrderData.Insert("api_code", String(NewOrder.Ref.UUID()));
	OrderData.Insert("number",String(NewOrder.Number));
	OrderData.Insert("payment_date",String(NewOrder.Date));
	OrderData.Insert("tax_period_ending", String(NewOrder.TaxPeriodEnding));
	OrderData.Insert("sales_tax_agency", String(NewOrder.SalesTaxAgency));
	OrderData.Insert("bank_account", String(NewOrder.BankAccount));
	OrderData.Insert("payment", String(NewOrder.Payment));
	OrderData.Insert("accounting_basis", String(NewOrder.AccountingBasis));
	OrderData.Insert("made_adjustment", String(NewOrder.MadeAdjustment));
	OrderData.Insert("total_payment", String(NewOrder.TotalPayment));
	OrderData.Insert("memo", String(NewOrder.Memo));
	
	OrderData.Insert("adjustment_amount", String(NewOrder.AdjustmentAmount));
	OrderData.Insert("adjustment_reason", String(NewOrder.AdjustmentReason));
	OrderData.Insert("adjustment_account", String(NewOrder.AdjustmentAccount));

	Return OrderData;
	
EndFunction

Function ReturnPurchaseOrderMap(NewOrder) Export
	
	
	OrderData = New Map();
	OrderData.Insert("api_code", String(NewOrder.Ref.UUID()));
	OrderData.Insert("customer_api_code", String(NewOrder.Company.Ref.UUID()));
	OrderData.Insert("address_api_code",String(NewOrder.CompanyAddress.Ref.UUID()));
	OrderData.Insert("ds_address_api_code",String(NewOrder.DropshipShipTo.Ref.UUID()));
	OrderData.Insert("purchase_address_id",String(NewOrder.CompanyAddress.Description));
	OrderData.Insert("purchase_first_name",String(NewOrder.CompanyAddress.FirstName));
	OrderData.Insert("purchase_middle_name",String(NewOrder.CompanyAddress.MiddleName));
	OrderData.Insert("purchase_address_line1",String(NewOrder.CompanyAddress.AddressLine1));
	OrderData.Insert("purchase_address_line2",String(NewOrder.CompanyAddress.AddressLine2));
	OrderData.Insert("purchase_city",String(NewOrder.CompanyAddress.City));
	OrderData.Insert("purchase_state",String(NewOrder.CompanyAddress.State));
	OrderData.Insert("purchase_zip",String(NewOrder.CompanyAddress.ZIP));
	OrderData.Insert("purchase_country",String(NewOrder.CompanyAddress.Country));
	OrderData.Insert("purchase_phone",String(NewOrder.CompanyAddress.Phone));
	OrderData.Insert("purchase_cell",String(NewOrder.CompanyAddress.Cell));
	OrderData.Insert("purchase_email",String(NewOrder.CompanyAddress.Email));
	//OrderData.Insert("purchase_sales_tax_code",String(NewOrder.CompanyAddress.SalesTaxCode));
	OrderData.Insert("purchase_notes",String(NewOrder.CompanyAddress.Notes));
	OrderData.Insert("ds_address_id",String(NewOrder.DropshipShipTo.Description));
	OrderData.Insert("ds_customer",String(NewOrder.DropshipCompany.Description));
	OrderData.Insert("ds_customer_api_code", String(NewOrder.DropshipCompany.Ref.UUID()));

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
			OrderData3.Insert("quantity",lineitem.QtyUnits);
			//OrderData3.Insert("unit_of_measure",String(LineItem.UM));
			OrderData3.Insert("price",LineItem.Price);
			OrderData3.Insert("line_total",LineItem.LineTotal);
			OrderData3.Insert("project",String(LineItem.Project));
			OrderData3.Insert("class",String(LineItem.Class));
			OrderData2.Add(OrderData3);
	
	EndDo;
		
	OrderData.Insert("line_items",OrderData2);	

	Return OrderData;

EndFunction

Function ReturnBankReconMapNew(NewOrder) Export
	
	OrderData = New Map();
	
	OrderData.Insert("api_code", String(NewOrder.Ref.UUID()));
	OrderData.Insert("beginning_balance", NewOrder.BeginningBalance);
	OrderData.Insert("ending_balance", NewOrder.EndingBalance);
	OrderData.Insert("bank_account", String(NewOrder.BankAccount));
	OrderData.Insert("statement_date", String(NewOrder.Date));
	
	//OrderData.Insert("charge_date", NewOrder.ServiceChargeDate);
	//OrderData.Insert("service_charge", NewOrder.ServiceCharge);
	//OrderData.Insert("interest_earned", NewOrder.InterestEarned);
	//OrderData.Insert("earned_date", NewOrder.InterestEarnedDate);
	//OrderData.Insert("bank_service_charge_account", NewOrder.BankServiceChargeAccount);
	//OrderData.Insert("bank_interest_earned_account", NewOrder.BankInterestEarnedAccount);
	
	OrderData.Insert("memo", NewOrder.Memo);
	OrderData.Insert("cleared_amount", NewOrder.ClearedAmount);
	OrderData.Insert("cleared_balance", NewOrder.ClearedBalance);
	OrderData.Insert("difference", NewOrder.Difference);
	
		
	OrderData2 = New Array();
	
	For Each LineItem in NewOrder.LineItems Do
		
			OrderData3 = New Map();

			OrderData3.Insert("transaction_api_code", String(LineItem.Transaction.Ref.UUID()));
			OrderData3.Insert("transaction_description", String(LineItem.Transaction));
			OrderData3.Insert("transaction_amount", LineItem.TransactionAmount);
			OrderData3.Insert("cleared", LineItem.Cleared);
			//OrderData3.Insert("company", String(LineItem.Company));
			//OrderData3.Insert("company_api_code", String(LineItem.Company.Ref.UUID()));
			//OrderData3.Insert("is_cleared", LineItem.Deposit);
			//OrderData3.Insert("transaction_amount", LineItem.Payment);
			//
			OrderData2.Add(OrderData3);
	
	EndDo;
		
	OrderData.Insert("line_items",OrderData2);
	
	
	Return OrderData;
EndFunction

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

Procedure ObjectDelete(Source, Cancel) Export
	
	// Prepare a structure for the document data.
	SourceData = New Map();
	
	// Case by types of objects causing the event.
	If TypeOf(Source) = Type("DocumentObject.SalesInvoice") Then
		
		// Send webhook on the connected API.
		SendWebhook(Source, SourceData, Constants.sales_invoices_webhook.Get(),
		            "salesinvoices", "delete", "GeneralFunctions.SendWebhook");
		
	ElsIf TypeOf(Source) = Type("DocumentObject.CashSale") Then
		
		// Send webhook on the connected API.
		SendWebhook(Source, SourceData, Constants.cash_sales_webhook.Get(),
		            "cashsales", "delete", "GeneralFunctions.SendWebhook");
		
	Else
		// All other types of objects.
	EndIf;
	
	
EndProcedure

Procedure ObjectWrite(Source, Cancel, PostingMode) Export
	
	// Case by types of objects causing the event.
	If TypeOf(Source) = Type("DocumentObject.SalesInvoice") Then
		
		// Request data structure for the sales invoice.
		SourceData = ReturnSalesInvoiceMap(Source.Ref);
		
		// Send webhook on the connected API.
		SendWebhook(Source, SourceData, Constants.sales_invoices_webhook.Get(),
		            "salesinvoices", ?(Source.AdditionalProperties.IsNew, "create", "update"),
		            "GeneralFunctions.SendWebhook");
		
	ElsIf TypeOf(Source) = Type("DocumentObject.CashSale") Then
		
		// Request data structure for the sales invoice.
		SourceData = ReturnCashSaleMap(Source.Ref);
		
		// Send webhook on the connected API.
		SendWebhook(Source, SourceData, Constants.cash_sales_webhook.Get(),
		            "cashsales", ?(Source.AdditionalProperties.IsNew, "create", "update"),
		            "GeneralFunctions.SendWebhook");		
	Else
		// All other types of objects.
	EndIf;
	
EndProcedure

Procedure SendWebhook(Source, Data, Url, Resource, Action, Handler)
	
	// Check passed data.
	If Not IsBlankString(Url) Then
		
		// Finetune webhook params.
		If Data = Undefined Then Data = New Map(); EndIf;
		Data.Insert("apisecretkey", Constants.APISecretKey.Get());
		Data.Insert("resource",     Resource);
		Data.Insert("action",       Action);
		Data.Insert("api_code",     String(Source.Ref.UUID()));
		
		// Create function call parameters.
		Params = New Array();
		Params.Add(Url);
		Params.Add(Data);
		
		// Call handler in a background.
		LongActions.ExecuteInBackground(Handler, Params);
	EndIf;
	
EndProcedure

#EndIf
