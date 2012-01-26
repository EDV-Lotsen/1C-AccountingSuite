// The procedure prepopulates a sales quote when created from a vendor quote.
//
Procedure Filling(FillingData, StandardProcessing)
		
	If TypeOf(FillingData) = Type("DocumentRef.PurchaseQuote") Then
					
		Company = FillingData.EndCustomer;		
		Currency = Company.DefaultCurrency;
		ExchangeRate = GeneralFunctions.GetExchangeRate(CurrentDate(), GeneralFunctionsReusable.DefaultCurrency(), Currency);
        Bank = GeneralFunctions.GetAttributeValue(FillingData.Company, "Bank");
		
		DocTotal = 0;
				
		For Each CurRowLineItems In FillingData.LineItems Do
			NewRow = LineItems.Add();
			Product = CurRowLineItems.Product; 
			NewRow.Product = Product;
			NewRow.Descr = CurRowLineItems.Descr;
			NewRow.Quantity = CurRowLineItems.Quantity;
			NewRow.QuantityUM = CurRowLineItems.QuantityUM;
			NewRow.UM = CurRowLineItems.UM;
			Price = GeneralFunctions.RetailPrice(CurrentDate(), CurRowLineItems.Product, Company, Currency);
			If GeneralFunctions.FunctionalOptionValue("AdvancedPricing") Then
				AdjPrice = Price;
			Else
				AdjPrice = Price / ExchangeRate;
			EndIf;		
			NewRow.Price = AdjPrice;
			If GeneralFunctionsReusable.FunctionalOptionValue("UnitsOfMeasure") Then
				LTotal = CurRowLineItems.QuantityUM * AdjPrice;
			Else
				LTotal = CurRowLineItems.Quantity * AdjPrice;
			EndIf;			
			NewRow.LineTotal = LTotal;					
			NewRow.SalesTaxType = US_FL.GetSalesTaxType(Product);
			VATCode = GeneralFunctions.GetAttributeValue(Product, "SalesVATCode");
			NewRow.VATCode = VATCode;
			NewRow.VAT = VAT_FL.VATLine(LTotal, VATCode, "Sales");
		EndDo;
		
		DocumentTotal = LineItems.Total("LineTotal") + LineItems.Total("VAT");
		DocumentTotalRC = (LineItems.Total("LineTotal") + LineItems.Total("VAT")) * ExchangeRate;
		VATTotal = LineItems.Total("VAT") * ExchangeRate;

		
	EndIf;

EndProcedure






