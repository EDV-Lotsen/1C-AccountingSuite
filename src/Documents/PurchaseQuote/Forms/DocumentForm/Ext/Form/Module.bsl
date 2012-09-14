&AtClient
// VendorOnChange UI event handler.
// Selects default currency for the vendor, determines an exchange rate, and
// recalculates the document's total amount.
// 
Procedure CompanyOnChange(Item)
	
	Object.Currency = GeneralFunctions.GetAttributeValue(Object.Company, "DefaultCurrency");
	Object.ExchangeRate = GeneralFunctions.GetExchangeRate(Object.Date, GeneralFunctionsReusable.DefaultCurrency(), Object.Currency);
	Items.ExchangeRate.Title = GeneralFunctionsReusable.DefaultCurrencySymbol() + "/" + GeneralFunctions.GetAttributeValue(Object.Currency, "Symbol");
	Items.FCYCurrency.Title = GeneralFunctions.GetAttributeValue(Object.Currency, "Symbol");
	RecalcTotal();
	
EndProcedure

&AtClient
// PriceOnChange UI event handler.
// Calculates line total by multiplying price by quantity in either the selected unit
// of measure (U/M) or in the base U/M, and recalculates the line's total.
// 
Procedure LineItemsPriceOnChange(Item)
	
	TabularPartRow = Items.LineItems.CurrentData;
	
	If GeneralFunctionsReusable.FunctionalOptionValue("UnitsOfMeasure") Then
		TabularPartRow.LineTotal = TabularPartRow.QuantityUM * TabularPartRow.Price;
	Else
		TabularPartRow.LineTotal = TabularPartRow.Quantity * TabularPartRow.Price;
	EndIf;

	TabularPartRow.VAT = SouthAfrica_FL.VATLine(TabularPartRow.LineTotal, TabularPartRow.VATCode, "Purchase");
	
	RecalcTotal();

EndProcedure

&AtClient
// The procedure recalculates the document's total.
// DocumentTotal - document's currency in FCY (foreign currency).
// DocumentTotalRC - company's reporting currency.
//
Procedure RecalcTotal()
	
	Object.DocumentTotal = Object.LineItems.Total("LineTotal") + Object.LineItems.Total("VAT");
	Object.DocumentTotalRC = (Object.LineItems.Total("LineTotal") + Object.LineItems.Total("VAT")) * Object.ExchangeRate;
	Object.VATTotal = Object.LineItems.Total("VAT") * Object.ExchangeRate;
	
EndProcedure

&AtClient
// DateOnChange UI event handler.
// Determines an exchange rate on the new date, and recalculates the document's total.
//
Procedure DateOnChange(Item)
	
	Object.ExchangeRate = GeneralFunctions.GetExchangeRate(Object.Date, GeneralFunctionsReusable.DefaultCurrency(), Object.Currency);
	RecalcTotal();
	
EndProcedure


&AtClient
// CurrencyOnChange UI event handler.
// Determines an exchange rate for the new currency, and recalculates the document's total.
//
Procedure CurrencyOnChange(Item)
	
	Object.ExchangeRate = GeneralFunctions.GetExchangeRate(Object.Date, GeneralFunctionsReusable.DefaultCurrency(), Object.Currency);
	Items.ExchangeRate.Title = GeneralFunctionsReusable.DefaultCurrencySymbol() + "/" + GeneralFunctions.GetAttributeValue(Object.Currency, "Symbol");
	Items.FCYCurrency.Title = GeneralFunctions.GetAttributeValue(Object.Currency, "Symbol");
	RecalcTotal();
	
EndProcedure

&AtClient
// LineItemsUMOnChange UI event handler.
// The procedure determines a unit of measure (U/M) conversion ratio, clears the price of the product,
// line total, calculates quantity in a base U/M, and recalculates document total.
//
Procedure LineItemsUMOnChange(Item)
	
	TabularPartRow = Items.LineItems.CurrentData;
		
	Ratio = GeneralFunctions.GetUMRatio(TabularPartRow.UM);
	
	TabularPartRow.Price = 0;
	TabularPartRow.LineTotal = 0;
    TabularPartRow.VAT = 0;
	
	If Ratio = 0 Then
		TabularPartRow.Quantity = TabularPartRow.QuantityUM * 1;
	Else
		TabularPartRow.Quantity = TabularPartRow.QuantityUM * Ratio;
	EndIf;
	
	RecalcTotal();
	
EndProcedure

&AtClient
// LineItemsQuantityUMOnChange UI event handler.
// The procedure determines a unit of measure (U/M) conversion ratio,
// calculates quantity in a base U/M, calculates line total, and document total.
//
Procedure LineItemsQuantityUMOnChange(Item)
	
	TabularPartRow = Items.LineItems.CurrentData;
	
	Ratio = GeneralFunctions.GetUMRatio(TabularPartRow.UM);
	
	If Ratio = 0 Then
		TabularPartRow.Quantity = TabularPartRow.QuantityUM * 1;
	Else
		TabularPartRow.Quantity = TabularPartRow.QuantityUM * Ratio;
	EndIf;
	
	TabularPartRow.LineTotal = TabularPartRow.QuantityUM * TabularPartRow.Price;
	TabularPartRow.VAT = SouthAfrica_FL.VATLine(TabularPartRow.LineTotal, TabularPartRow.VATCode, "Purchase");

	RecalcTotal();

EndProcedure

&AtClient
// LineItemsAfterDeleteRow UI event handler.
// 
Procedure LineItemsAfterDeleteRow(Item)
	
	RecalcTotal();
	
EndProcedure

&AtClient
// LineItemsQuantityOnChange UI event handler.
// This procedure is used when the units of measure (U/M) functional option is turned
// off and base quantities are used instead of U/M quantities.
// The procedure recalculates line total, and a document's total.
// 
Procedure LineItemsQuantityOnChange(Item)
	
	
	TabularPartRow = Items.LineItems.CurrentData;
	TabularPartRow.LineTotal = TabularPartRow.Quantity * TabularPartRow.Price;
	TabularPartRow.VAT = SouthAfrica_FL.VATLine(TabularPartRow.LineTotal, TabularPartRow.VATCode, "Purchase");
	
	RecalcTotal();

EndProcedure


&AtClient
// ProductOnChange UI event handler.
// The procedure clears quantities, line total, and selects a default unit of measure (U/M) for the
// product.
// 
Procedure LineItemsProductOnChange(Item)
	
	TabularPartRow = Items.LineItems.CurrentData;
	
	TabularPartRow.Descr = GeneralFunctions.GetAttributeValue(TabularPartRow.Product, "Descr");
	TabularPartRow.Quantity = 0;
	TabularPartRow.QuantityUM = 0;
	TabularPartRow.LineTotal = 0;
	TabularPartRow.Price = 0;
	TabularPartRow.VAT = 0;
	
	TabularPartRow.UM = GeneralFunctions.GetDefaultPurchaseUMForProduct(TabularPartRow.Product);

	TabularPartRow.VATCode = GeneralFunctions.GetAttributeValue(TabularPartRow.Product, "PurchaseVATCode"); 
	
	RecalcTotal();
	
EndProcedure

&AtClient
// Makes the base Quantity field read only if the units of measure functional option is turned on
//
Procedure LineItemsBeforeAddRow(Item, Cancel, Clone, Parent, Folder)
	
	If GeneralFunctionsReusable.FunctionalOptionValue("UnitsOfMeasure") Then
		Items.LineItemsQuantity.ReadOnly = True;
	EndIf;

EndProcedure

&AtClient
// Makes the base Quantity field read only if the units of measure functional option is turned on
//
Procedure LineItemsBeforeRowChange(Item, Cancel)
	
	If GeneralFunctionsReusable.FunctionalOptionValue("UnitsOfMeasure") Then
		Items.LineItemsQuantity.ReadOnly = True;
	EndIf;

EndProcedure

&AtServer
// Procedure fills in default values, used mostly when the corresponding functional
// options are turned off.
// The following defaults are filled in - warehouse location, and currency.
// 
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Items.Company.Title = GeneralFunctionsReusable.GetVendorName();
	
	//Title = "Purchase Quote " + Object.Number + " " + Format(Object.Date, "DLF=D");
	
	If NOT GeneralFunctionsReusable.FunctionalOptionValue("SAFinLocalization") Then
		Items.VATGroup.Visible = False;
	EndIf;
	
	If NOT GeneralFunctionsReusable.FunctionalOptionValue("MultiCurrency") Then
		Items.FCYGroup.Visible = False;
	EndIf;
	
	If GeneralFunctionsReusable.FunctionalOptionValue("MultiLocation") Then
	Else
		If Object.Location.IsEmpty() Then
			Object.Location = Constants.DefaultLocation.Get();
		EndIf;
	EndIf;
	
	If Object.Currency.IsEmpty() Then
		Object.Currency = Constants.DefaultCurrency.Get();
		Object.ExchangeRate = 1;	
	Else
	EndIf; 
	
	Items.ExchangeRate.Title = GeneralFunctionsReusable.DefaultCurrencySymbol() + "/" + Object.Currency.Symbol;
	Items.VATCurrency.Title = GeneralFunctionsReusable.DefaultCurrencySymbol();
	Items.RCCurrency.Title = GeneralFunctionsReusable.DefaultCurrencySymbol();
	Items.FCYCurrency.Title = GeneralFunctions.GetAttributeValue(Object.Currency, "Symbol");
	
EndProcedure



&AtServer
// Ensures uniqueness of line items
//
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	ProductData = Object.LineItems.Unload(,"Product");	
	ProductData.Sort("Product");
	NoOfRows = ProductData.Count();	
	For i = 0 to NoOfRows - 2 Do		
		Product = ProductData[i][0];
		If ProductData[i][0] = ProductData[i+1][0] AND NOT Product.Code = "" Then									
			ProductIDString = String(Product.Description);
			ProductDescrString = String(Product.Descr);			
			Message = New UserMessage();		    
			Message.Text = "Duplicate item: " + ProductIDString + " " + ProductDescrString;
			Message.Message();
			Cancel = True;
			Return;
		EndIf;		
	EndDo;

EndProcedure

&AtClient
// Calculates a VAT amount for the document line
//
Procedure LineItemsVATCodeOnChange(Item)
	
	TabularPartRow = Items.LineItems.CurrentData;
	TabularPartRow.VAT = SouthAfrica_FL.VATLine(TabularPartRow.LineTotal, TabularPartRow.VATCode, "Purchase");
    RecalcTotal();
	
EndProcedure
