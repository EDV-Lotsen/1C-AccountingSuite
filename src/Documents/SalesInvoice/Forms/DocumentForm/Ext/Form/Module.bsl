
&AtClient
// ProductOnChange UI event handler.
// The procedure clears quantities, line total, and taxable amount in the line item,
// selects price for the new product from the price-list, divides the price by the document
// exchange rate, selects a default unit of measure for the product, and
// selects a product's sales tax type.
// 
Procedure LineItemsProductOnChange(Item)
	
	TabularPartRow = Items.LineItems.CurrentData;
	
	TabularPartRow.Descr = GeneralFunctions.GetAttributeValue(TabularPartRow.Product, "Descr");
	TabularPartRow.Quantity = 0;
	TabularPartRow.QuantityUM = 0;
	TabularPartRow.LineTotal = 0;
	TabularPartRow.TaxableAmount = 0;
	TabularPartRow.Price = 0;
	TabularPartRow.VAT = 0;
	
	Price = GeneralFunctions.RetailPrice(CurrentDate(), TabularPartRow.Product, Object.Company, Object.Currency);
	If GeneralFunctions.FunctionalOptionValue("AdvancedPricing") Then
		TabularPartRow.Price = Price;
	Else
		TabularPartRow.Price = Price / Object.ExchangeRate;
	EndIf;	
		
	TabularPartRow.UM = GeneralFunctions.GetDefaultSalesUMForProduct(TabularPartRow.Product);
	
	TabularPartRow.SalesTaxType = US_FL.GetSalesTaxType(TabularPartRow.Product);
	
	TabularPartRow.VATCode = GeneralFunctions.GetAttributeValue(TabularPartRow.Product, "SalesVATCode");
	
	RecalcTotal();
	
EndProcedure

&AtClient
// The procedure recalculates a document's sales tax amount
// 
Procedure RecalcSalesTax()
	
	If Object.Company.IsEmpty() Then
		TaxRate = 0;
	Else
		TaxRate = US_FL.GetTaxRate(Object.Company);
	EndIf;
	
	Object.SalesTax = Object.LineItems.Total("TaxableAmount") * TaxRate/100;
	
EndProcedure

&AtClient
// The procedure recalculates the document's total.
// DocumentTotal - document's currency in FCY (foreign currency).
// DocumentTotalRC - company's reporting currency.
//
Procedure RecalcTotal()
	
	Object.DocumentTotal = Object.LineItems.Total("LineTotal") + Object.LineItems.Total("VAT") + Object.SalesTax;
	Object.DocumentTotalRC = (Object.LineItems.Total("LineTotal") + Object.LineItems.Total("VAT") + Object.SalesTax) * Object.ExchangeRate;
	Object.VATTotal = Object.LineItems.Total("VAT") * Object.ExchangeRate;
	
EndProcedure

&AtClient
// The procedure recalculates a taxable amount for a line item.
// 
Procedure RecalcTaxableAmount()
	
	TabularPartRow = Items.LineItems.CurrentData;
	
	If TabularPartRow.SalesTaxType = US_FL.Taxable() Then
		TabularPartRow.TaxableAmount = TabularPartRow.LineTotal;
	Else
		TabularPartRow.TaxableAmount = 0;
	EndIf;
	
EndProcedure

&AtClient
// CustomerOnChange UI event handler.
// Selects default currency for the customer, determines an exchange rate, and
// recalculates the document's sales tax and total amounts.
// 
Procedure CompanyOnChange(Item)
	
	Object.Currency = GeneralFunctions.GetAttributeValue(Object.Company, "DefaultCurrency");
	Object.ARAccount = GeneralFunctions.GetAttributeValue(Object.Currency, "DefaultARAccount");
	Object.ExchangeRate = GeneralFunctions.GetExchangeRate(Object.Date, GeneralFunctionsReusable.DefaultCurrency(), Object.Currency);
	Items.ExchangeRate.Title = GeneralFunctionsReusable.DefaultCurrencySymbol() + "/" + GeneralFunctions.GetAttributeValue(Object.Currency, "Symbol");
	Items.FCYCurrency.Title = GeneralFunctions.GetAttributeValue(Object.Currency, "Symbol");
	RecalcSalesTax();
	RecalcTotal();
	
EndProcedure

&AtClient
// PriceOnChange UI event handler.
// Calculates line total by multiplying a price by a quantity in either the selected
// unit of measure (U/M) or in the base U/M, and recalculates the line's taxable amount and total.
// 
Procedure LineItemsPriceOnChange(Item)
	
	TabularPartRow = Items.LineItems.CurrentData;
	
	If GeneralFunctionsReusable.FunctionalOptionValue("UnitsOfMeasure") Then
		TabularPartRow.LineTotal = TabularPartRow.QuantityUM * TabularPartRow.Price;
	Else
		TabularPartRow.LineTotal = TabularPartRow.Quantity * TabularPartRow.Price;
	EndIf;
	
	TabularPartRow.VAT = SouthAfrica_FL.VATLine(TabularPartRow.LineTotal, TabularPartRow.VATCode, "Sales");
	
	RecalcTaxableAmount();
	RecalcSalesTax();
	RecalcTotal();

EndProcedure

&AtClient
// DateOnChange UI event handler.
// Determines an exchange rate on the new date, and recalculates the document's
// sales tax and total.
//
Procedure DateOnChange(Item)
	
	Object.ExchangeRate = GeneralFunctions.GetExchangeRate(Object.Date, GeneralFunctionsReusable.DefaultCurrency(), Object.Currency);
	RecalcSalesTax();
	RecalcTotal();
	
EndProcedure

&AtClient
// CurrencyOnChange UI event handler.
// Determines an exchange rate for the new currency, and recalculates the document's
// sales tax and total.
//
Procedure CurrencyOnChange(Item)
	
	Object.ExchangeRate = GeneralFunctions.GetExchangeRate(Object.Date, GeneralFunctionsReusable.DefaultCurrency(), Object.Currency);
	Object.ARAccount = GeneralFunctions.GetAttributeValue(Object.Currency, "DefaultARAccount");
	Items.ExchangeRate.Title = GeneralFunctionsReusable.DefaultCurrencySymbol() + "/" + GeneralFunctions.GetAttributeValue(Object.Currency, "Symbol");
	Items.FCYCurrency.Title = GeneralFunctions.GetAttributeValue(Object.Currency, "Symbol");
	RecalcSalesTax();
	RecalcTotal();
	
EndProcedure

&AtClient
// LineItemsQuantityUMOnChange UI event handler.
// Determines conversion ratio between the selected and base units of measure,
// calculates a new base quantity, recalculates line total, taxable amount, sales tax, and
// document total.
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
	TabularPartRow.VAT = SouthAfrica_FL.VATLine(TabularPartRow.LineTotal, TabularPartRow.VATCode, "Sales");
	
	RecalcTaxableAmount();
	RecalcSalesTax();
	RecalcTotal();

EndProcedure

&AtClient
// LineItemsUMOnChange UI event handler.
// The procedure determines a unit of measure (U/M) conversion ratio, clears the price of the product,
// line total, taxable amount, calculates quantity in a base U/M, recalculates document sales tax
// and total.
//
Procedure LineItemsUMOnChange(Item)
	
	TabularPartRow = Items.LineItems.CurrentData;
	
	Ratio = GeneralFunctions.GetUMRatio(TabularPartRow.UM);
	
	TabularPartRow.Price = 0;
	TabularPartRow.LineTotal = 0;
	TabularPartRow.TaxableAmount = 0;
	TabularPartRow.VAT = 0;
	
	If Ratio = 0 Then
		TabularPartRow.Quantity = TabularPartRow.QuantityUM * 1;
	Else
		TabularPartRow.Quantity = TabularPartRow.QuantityUM * Ratio;
	EndIf;
	
	RecalcSalesTax();
	RecalcTotal();

EndProcedure

&AtClient
// LineItemsCFOPOnChange UI event handler.
// CFOP (Código Fiscal de Operações e Prestações) is a transaction type code used in the
// Brazil financial layer.
// The procedure collects all parameters required for looking up an ICMS tax rate in the tax table -
// CFOP code, product group, state of origin, state of destination, and call the GetICMSTaxRate
// function passing the collected parameters. After determining the ICMS tax rate the procedure
// multiples a line total (taxable amount) by the tax rate and saves the tax value in the ICMS column.
// 
Procedure LineItemsCFOPOnChange(Item)
		
	TabularPartRow = Items.LineItems.CurrentData;
	
	CFOP = TabularPartRow.CFOP;
	ProductGroup = Brazil_FL.GetProductGroup(TabularPartRow.Product);
	StateOrigin = Brazil_FL.GetState(GeneralFunctions.GetOurCompany());
	StateDestination = Brazil_FL.GetState(Object.Company);
	
	TabularPartRow.ICMSTaxRate = Brazil_FL.GetICMSTaxRate(CFOP, ProductGroup,
		StateOrigin, StateDestination);
	TabularPartRow.ICMS = TabularPartRow.LineTotal * TabularPartRow.ICMSTaxRate / 100;
	
EndProcedure

&AtClient
// LineItemsAfterDeleteRow UI event handler.
// 
Procedure LineItemsAfterDeleteRow(Item)
	
	RecalcSalesTax();
	RecalcTotal();
	
EndProcedure

&AtClient
// LineItemsSalesTaxTypeOnChange UI event handler.
//
Procedure LineItemsSalesTaxTypeOnChange(Item)
	
	RecalcTaxableAmount();
	RecalcSalesTax();
	RecalcTotal();
	
EndProcedure

&AtClient
// TermsOnChange UI event handler.
// Determines number of days in the payment term, and calculates a due date as
// a multiplication of a number of days (e.g. 30 for "Net 30") by the number of seconds
// in a day, since
// the system treats numbers as seconds when adding to a date.
// 
Procedure TermsOnChange(Item)
		
	Object.DueDate = Object.Date +
		GeneralFunctions.GetAttributeValues(Object.Terms, "Days")["Days"] * 60*60*24;
	
EndProcedure

&AtClient
// DueDateOnChange UI event handler.
// Clears the selected payment term when a user inputs a custom due date.
//
Procedure DueDateOnChange(Item)
	
	Object.Terms = NULL;
	
EndProcedure

&AtClient
// LineItemsQuantityOnChange UI event handler.
// This procedure is used when the units of measure (U/M) functional option is turned off
// and base quantities are used instead of U/M quantities.
// The procedure recalculates line total, line taxable amount, and a document's sales tax and total.
// 
Procedure LineItemsQuantityOnChange(Item)
	
	TabularPartRow = Items.LineItems.CurrentData;
	TabularPartRow.LineTotal = TabularPartRow.Quantity * TabularPartRow.Price;
	TabularPartRow.VAT = SouthAfrica_FL.VATLine(TabularPartRow.LineTotal, TabularPartRow.VATCode, "Sales");
	
	RecalcTaxableAmount();
	RecalcSalesTax();
	RecalcTotal();

EndProcedure

&AtServer
// Procedure fills in default values, used mostly when the corresponding functional
// options are turned off.
// The following defaults are filled in - warehouse location, currency, due date, payment term, and
// due date based on a default payment term.
// 
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Items.Company.Title = GeneralFunctionsReusable.GetCustomerName();
	
	//Title = NStr("en='Sales Invoice ';pt='Fatura de vendas ';de='Rechnung'") + Object.Number + " " + Format(Object.Date, "DLF=D");
	
	If Object.DontCreate Then
		Cancel = True;
		Return;
	EndIf;

	If NOT GeneralFunctionsReusable.FunctionalOptionValue("USFinLocalization") Then
		Items.SalesTaxGroup.Visible = False;
	EndIf;
	
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
		Object.ARAccount = Object.Currency.DefaultARAccount;
		Object.ExchangeRate = 1;	
	Else
	EndIf; 
	
	Items.ExchangeRate.Title = GeneralFunctionsReusable.DefaultCurrencySymbol() + "/" + Object.Currency.Symbol;
	Items.VATCurrency.Title = GeneralFunctionsReusable.DefaultCurrencySymbol();
	Items.RCCurrency.Title = GeneralFunctionsReusable.DefaultCurrencySymbol();
	Items.SalesTaxCurrency.Title = GeneralFunctionsReusable.DefaultCurrencySymbol();
	Items.FCYCurrency.Title = GeneralFunctions.GetAttributeValue(Object.Currency, "Symbol");
	
	If Object.DueDate = Date(1,1,1) Then
		Object.DueDate = CurrentDate() + GeneralFunctionsReusable.GetDefaultTermDays() * 60*60*24;
	EndIf;

	If Object.Terms.IsEmpty() Then
		Object.Terms = GeneralFunctionsReusable.GetDefaultPaymentTerm();
	EndIf;
	
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
	TabularPartRow.VAT = SouthAfrica_FL.VATLine(TabularPartRow.LineTotal, TabularPartRow.VATCode, "Sales");
    RecalcTotal();

EndProcedure
