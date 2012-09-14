// The procedure prepopulates a sales order when created from a sales quote.
//
Procedure Filling(FillingData, StandardProcessing)
	
	If TypeOf(FillingData) = Type("DocumentRef.SalesQuote") Then
		Company = FillingData.Company;
		DocumentTotal = FillingData.DocumentTotal;
		DocumentTotalRC = FillingData.DocumentTotalRC;
		Location = FillingData.Location;
		SalesTax = FillingData.SalesTax;
		Currency = FillingData.Currency;
		ExchangeRate = FillingData.ExchangeRate;
		ParentSalesQuote = FillingData.Ref;
		VATTotal = FillingData.VATTotal;
		
		For Each CurRowLineItems In FillingData.LineItems Do
			NewRow = LineItems.Add();
			NewRow.LineTotal = CurRowLineItems.LineTotal;
			NewRow.Price = CurRowLineItems.Price;
			NewRow.Product = CurRowLineItems.Product;
			NewRow.Descr = CurRowLineItems.Descr;
			NewRow.Quantity = CurRowLineItems.Quantity;
			NewRow.QuantityUM = CurRowLineItems.QuantityUM;
			NewRow.UM = CurRowLineItems.UM;
			NewRow.SalesTaxType = CurRowLineItems.SalesTaxType;
			NewRow.TaxableAmount = CurRowLineItems.TaxableAmount;
			NewRow.VAT = CurRowLineItems.VAT;
			NewRow.VATCode = CurRowLineItems.VATCode;
		EndDo;
		
	EndIf;
	
EndProcedure


