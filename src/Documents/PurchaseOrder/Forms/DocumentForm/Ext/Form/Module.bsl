&AtServer
// Request order status from database
Procedure FillOrderStatuses()
	
	// Request order status
	If Not ValueIsFilled(Object.Ref) Then
		// New order has open status
		OrderStatus = Enums.OrderStatuses.Open;
		
	Else
		// Create new query
		Query = New Query;
		Query.SetParameter("Ref", Object.Ref);
		
		Query.Text = 
			"SELECT TOP 1
			|	OrdersStatuses.Status
			|FROM
			|	InformationRegister.OrdersStatuses AS OrdersStatuses
			|WHERE
			|	Order = &Ref
			|ORDER BY
			|	OrdersStatuses.Status.Order Desc";
		Selection = Query.Execute().Choose();
		
		// Fill order status
		If Selection.Next() Then
			OrderStatus = Selection.Status;
		Else
			OrderStatus = Enums.OrderStatuses.Open;
		EndIf;
	EndIf;
	OrderStatusIndex = Enums.OrderStatuses.IndexOf(OrderStatus);
	
	// Build order status presentation (depending of document state)
	If Not ValueIsFilled(Object.Ref) Then
		OrderStatusPresentation = String(Enums.OrderStatuses.New);
		Items.OrderStatusPresentation.TextColor = WebColors.DarkGreen;
	ElsIf Object.DeletionMark Then
		OrderStatusPresentation = String(Enums.OrderStatuses.Deleted);
		Items.OrderStatusPresentation.TextColor = WebColors.DarkGray;
	ElsIf Not Object.Posted Then 
		OrderStatusPresentation = String(Enums.OrderStatuses.Draft);
		Items.OrderStatusPresentation.TextColor = WebColors.DarkGray;
	Else
		OrderStatusPresentation = String(OrderStatus);
		If OrderStatus = Enums.OrderStatuses.Open Then 
			ThisForm.Items.OrderStatusPresentation.TextColor = WebColors.DarkGreen;
		ElsIf OrderStatus = Enums.OrderStatuses.Backordered Then 
			ThisForm.Items.OrderStatusPresentation.TextColor = WebColors.DarkGoldenRod;
		ElsIf OrderStatus = Enums.OrderStatuses.Closed Then
			ThisForm.Items.OrderStatusPresentation.TextColor = WebColors.DarkRed;
		Else
			ThisForm.Items.OrderStatusPresentation.TextColor = WebColors.DarkGray;
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
// Request demanded order items from database
Procedure FillOrdersDispatched()
	
	// Request ordered items quantities
	If ValueIsFilled(Object.Ref) Then
		
		// Create new query
		Query = New Query;
		Query.SetParameter("Ref", Object.Ref);
		Query.SetParameter("OrderStatus", OrderStatus);
		
		Query.Text = 
			"SELECT
			|	OrdersDispatched.LineNumber              AS LineNumber,
			|	OrdersDispatchedBalance.Product          AS Product,                                                            // ---------------------------------------
			|	OrdersDispatchedBalance.QuantityBalance  AS Quantity,                                                           // Backorder quantity calculation
			|	CASE                                                                                                            // ---------------------------------------
			|		WHEN &OrderStatus = VALUE(Enum.OrderStatuses.Open)        THEN 0                                            // Order status = Open:
			|		WHEN &OrderStatus = VALUE(Enum.OrderStatuses.Backordered) THEN                                              //   Backorder = 0
			|			CASE                                                                                                    // Order status = Backorder:
			|				WHEN OrdersDispatchedBalance.Product.Type = VALUE(Enum.InventoryTypes.Inventory) THEN               //   Inventory:
			|					CASE                                                                                            //     Backorder = Ordered - Received >= 0
			|						WHEN OrdersDispatchedBalance.QuantityBalance > OrdersDispatchedBalance.ReceivedBalance THEN //     |
			|							 OrdersDispatchedBalance.QuantityBalance - OrdersDispatchedBalance.ReceivedBalance      //     |
			|						ELSE 0 END                                                                                  //     |
			|				ELSE                                                                                                //   Non-inventory:
			|					CASE                                                                                            //     Backorder = Ordered - Invoiced >= 0
			|						WHEN OrdersDispatchedBalance.QuantityBalance > OrdersDispatchedBalance.InvoicedBalance THEN //     |
			|							 OrdersDispatchedBalance.QuantityBalance - OrdersDispatchedBalance.InvoicedBalance      //     |
			|						ELSE 0 END                                                                                  //     |
			|				END                                                                                                 //     |
			|		WHEN &OrderStatus = VALUE(Enum.OrderStatuses.Closed)      THEN 0                                            // Order status = Closed:
			|		END AS Backorder,                                                                                           //   Backorder = 0
			|	OrdersDispatchedBalance.ReceivedBalance AS Received,
			|	OrdersDispatchedBalance.InvoicedBalance AS Invoiced
			|FROM
			|	AccumulationRegister.OrdersDispatched.Balance(,
			|		(Company, Order, Product) IN
			|			(SELECT
			|				LineItems.Ref.Company,
			|				LineItems.Ref,
			|				LineItems.Product
			|			FROM
			|				Document.PurchaseOrder.LineItems AS LineItems
			|			WHERE
			|				LineItems.Ref = &Ref)) AS OrdersDispatchedBalance
			|	LEFT JOIN AccumulationRegister.OrdersDispatched AS OrdersDispatched
			|		ON    ( OrdersDispatched.Recorder = &Ref
			|			AND OrdersDispatched.Company  = OrdersDispatchedBalance.Company
			|			AND OrdersDispatched.Order    = OrdersDispatchedBalance.Order
			|			AND OrdersDispatched.Product  = OrdersDispatchedBalance.Product
			|			AND OrdersDispatched.Quantity = OrdersDispatchedBalance.QuantityBalance)
			|ORDER BY
			|	OrdersDispatched.LineNumber";
		Selection = Query.Execute().Choose();
		
		// Fill ordered items quantities
		SearchRec = New Structure("LineNumber, Product, Quantity");
		While Selection.Next() Do
			
			// Search for appropriate line in tabular section of order
			FillPropertyValues(SearchRec, Selection);
			FoundLineItems = Object.LineItems.FindRows(SearchRec);
			
			// Fill quantities in tabular section
			If FoundLineItems.Count() > 0 Then
				FillPropertyValues(FoundLineItems[0], Selection, "Backorder, Received, Invoiced");
			EndIf;
			
		EndDo;
		
	EndIf;
	
EndProcedure

&AtServer
// Request and fill indexes of product type (required to calculate bacorder property)
Procedure FillProductTypes()
	
	// Fill line item's product types
	If ValueIsFilled(Object.Ref) Then
		
		// Create new query
		Query = New Query;
		Query.SetParameter("Ref", Object.Ref);
		
		Query.Text =
		"SELECT
		|	PurchaseOrderLineItems.LineNumber         AS LineNumber,
		|	PurchaseOrderLineItems.Product.Type.Order AS ProductTypeIndex
		|FROM
		|	Document.PurchaseOrder.LineItems AS PurchaseOrderLineItems
		|WHERE
		|	PurchaseOrderLineItems.Ref = &Ref
		|ORDER BY
		|	LineNumber";
		Selection = Query.Execute().Choose();
		
		// Fill ordered items quantities
		While Selection.Next() Do
			
			// Search for appropriate line in tabular section of order
			LineItem = Object.LineItems.Get(Selection.LineNumber-1);
			If LineItem <> Undefined Then
				LineItem.ProductTypeIndex = Selection.ProductTypeIndex;
			EndIf;
		EndDo;
		
	EndIf;
EndProcedure

&AtClient
// VendorOnChange UI event handler.
// Selects default currency for the vendor, determines an exchange rate, and
// recalculates the document's total amount.
// 
Procedure CompanyOnChange(Item)
	
	Object.CompanyCode = CommonUse.GetAttributeValue(Object.Company, "Code");
	Object.Currency = CommonUse.GetAttributeValue(Object.Company, "DefaultCurrency");
	Object.ExchangeRate = GeneralFunctions.GetExchangeRate(Object.Date, Object.Currency);
	Items.ExchangeRate.Title = GeneralFunctionsReusable.DefaultCurrencySymbol() + "/1" + CommonUse.GetAttributeValue(Object.Currency, "Symbol");
	Items.FCYCurrency.Title = CommonUse.GetAttributeValue(Object.Currency, "Symbol");
	RecalcTotal();
	
EndProcedure

&AtClient
// PriceOnChange UI event handler.
// Calculates line total by multiplying a price by a quantity in either the selected
// unit of measure (U/M) or in the base U/M, and recalculates the line's total.
// 
Procedure LineItemsPriceOnChange(Item)
	
	TabularPartRow = Items.LineItems.CurrentData;
	
	TabularPartRow.LineTotal = TabularPartRow.Quantity * TabularPartRow.Price;

	TabularPartRow.VAT = VAT_FL.VATLine(TabularPartRow.LineTotal, TabularPartRow.VATCode, "Purchase", Object.PriceIncludesVAT);
	
	RecalcTotal();

EndProcedure

&AtClient
// The procedure recalculates the document's total.
// DocumentTotal - document's currency in FCY (foreign currency).
// DocumentTotalRC - company's reporting currency.
//
Procedure RecalcTotal()
	
	If Object.PriceIncludesVAT Then
		Object.DocumentTotal = Object.LineItems.Total("LineTotal");
		Object.DocumentTotalRC = Object.LineItems.Total("LineTotal") * Object.ExchangeRate;		
	Else
		Object.DocumentTotal = Object.LineItems.Total("LineTotal") + Object.LineItems.Total("VAT");
		Object.DocumentTotalRC = (Object.LineItems.Total("LineTotal") + Object.LineItems.Total("VAT")) * Object.ExchangeRate;
	EndIf;	
	Object.VATTotal = Object.LineItems.Total("VAT") * Object.ExchangeRate;
	 
EndProcedure

&AtClient
// DateOnChange UI event handler.
// Determines an exchange rate on the new date, and recalculates the document's total.
//
Procedure DateOnChange(Item)
	
	Object.ExchangeRate = GeneralFunctions.GetExchangeRate(Object.Date, Object.Currency);
	RecalcTotal();
	
EndProcedure

&AtClient
// CurrencyOnChange UI event handler.
// Determines an exchange rate for the new currency, and recalculates the document's total.
//
Procedure CurrencyOnChange(Item)
	
	Object.ExchangeRate = GeneralFunctions.GetExchangeRate(Object.Date, Object.Currency);
	Items.ExchangeRate.Title = GeneralFunctionsReusable.DefaultCurrencySymbol() + "/1" + CommonUse.GetAttributeValue(Object.Currency, "Symbol");
	Items.FCYCurrency.Title = CommonUse.GetAttributeValue(Object.Currency, "Symbol");
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
// This procedure is used when the units of measure (U/M) functional option is turned off
// and base quantities are used instead of U/M quantities.
// The procedure recalculates line total, and a document's total.
// 
Procedure LineItemsQuantityOnChange(Item)
	
	// Request current string
	TabularPartRow = Items.LineItems.CurrentData;
	
	// Calculate sum and taxes by line
	TabularPartRow.LineTotal = TabularPartRow.Quantity * TabularPartRow.Price;
	TabularPartRow.VAT = VAT_FL.VATLine(TabularPartRow.LineTotal, TabularPartRow.VATCode, "Purchase", Object.PriceIncludesVAT);
	
	// Update backorder quantity based on document status
	If    OrderStatusIndex = 0 Then // OrderStatus = Enums.OrderStatuses.Open
		TabularPartRow.Backorder = 0;
	ElsIf OrderStatusIndex = 1 Then // OrderStatus = Enums.OrderStatuses.Backordered
		If TabularPartRow.ProductTypeIndex = 0 Then // Product.Type = Enums.InventoryTypes.Inventory
			TabularPartRow.Backorder = Max(TabularPartRow.Quantity - TabularPartRow.Shipped, 0);
		Else 
			TabularPartRow.Backorder = Max(TabularPartRow.Quantity - TabularPartRow.Invoiced, 0);
		EndIf;
	ElsIf OrderStatusIndex = 2 Then // OrderStatus = Enums.OrderStatuses.Closed
		TabularPartRow.Backorder = 0;
	Else
		TabularPartRow.Backorder = 0;
	EndIf;
	
	// Calculate totals
	RecalcTotal();

EndProcedure

&AtServer
// Procedure fills in default values, used mostly when the corresponding functional
// options are turned off.
// The following defaults are filled in - warehouse location, and currency.
// 
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Items.LineItemsQuantity.EditFormat = "NFD=" + Constants.QtyPrecision.Get();
	Items.LineItemsQuantity.Format = "NFD=" + Constants.QtyPrecision.Get();
	
	Items.LineItemsReceived.EditFormat = "NFD=" + Constants.QtyPrecision.Get();
	Items.LineItemsReceived.Format = "NFD=" + Constants.QtyPrecision.Get();
	
	Items.LineItemsInvoiced.EditFormat = "NFD=" + Constants.QtyPrecision.Get();
	Items.LineItemsInvoiced.Format = "NFD=" + Constants.QtyPrecision.Get();

	Items.LineItemsBackorder.EditFormat = "NFD=" + Constants.QtyPrecision.Get();
	Items.LineItemsBackorder.Format = "NFD=" + Constants.QtyPrecision.Get();

	Items.Company.Title = GeneralFunctionsReusable.GetVendorName();
	
	//Title = "Purchase Order " + Object.Number + " " + Format(Object.Date, "DLF=D");
	
	If Object.Ref.IsEmpty() Then
    	Object.PriceIncludesVAT = GeneralFunctionsReusable.PriceIncludesVAT();
	EndIf;
	
	If NOT GeneralFunctionsReusable.FunctionalOptionValue("VATFinLocalization") Then
		Items.VATGroup.Visible = False;
	EndIf;
	
	If NOT GeneralFunctionsReusable.FunctionalOptionValue("MultiCurrency") Then
		Items.FCYGroup.Visible = False;
	EndIf;
	
	//If GeneralFunctionsReusable.FunctionalOptionValue("MultiLocation") Then
	//Else
		If Object.Location.IsEmpty() Then
			Object.Location = Catalogs.Locations.MainWarehouse;
		EndIf;
	//EndIf;
	
	If Object.Currency.IsEmpty() Then
		Object.Currency = Constants.DefaultCurrency.Get();
		Object.ExchangeRate = 1;
	Else
	EndIf; 
	
	Items.ExchangeRate.Title = GeneralFunctionsReusable.DefaultCurrencySymbol() + "/1" + Object.Currency.Symbol;
	Items.VATCurrency.Title = GeneralFunctionsReusable.DefaultCurrencySymbol();
	Items.RCCurrency.Title = GeneralFunctionsReusable.DefaultCurrencySymbol();
	Items.FCYCurrency.Title = CommonUse.GetAttributeValue(Object.Currency, "Symbol");
	
	// Request and fill order status
	FillOrderStatuses();

	// Request and fill ordered items from database
	FillOrdersDispatched();
	
	// Request and fill indexes of product type (required to calculate bacorder property)
	FillProductTypes();
	
EndProcedure

&AtClient
// ProductOnChange UI event handler.
// The procedure clears quantities, line total, and selects a default unit of measure (U/M) for the
// product.
// 
Procedure LineItemsProductOnChange(Item)
	
	TabularPartRow = Items.LineItems.CurrentData;
	
	ProductProperties = CommonUse.GetAttributeValues(TabularPartRow.Product, "Description, PurchaseVATCode"); // mt_change Type.Order,
	TabularPartRow.ProductDescription = ProductProperties.Description;
	TabularPartRow.ProductTypeIndex   = TypeOrder(TabularPartRow.Product); // mt_change ProductProperties.TypeOrder;
	
	TabularPartRow.Quantity = 0;
	TabularPartRow.Backorder = 0;
	TabularPartRow.Received = 0;
	TabularPartRow.Invoiced = 0;
	TabularPartRow.LineTotal = 0;
	TabularPartRow.Price = 0;
    TabularPartRow.VAT = 0;
	
	TabularPartRow.Price = GeneralFunctions.ProductLastCost(TabularPartRow.Product);

	TabularPartRow.VATCode = ProductProperties.PurchaseVATCode;
	
	RecalcTotal();
	
EndProcedure

// mt_change
Function TypeOrder(Product) Export
	
	If Product.Type = Enums.InventoryTypes.Inventory Then
		Return 0;
	Else
		Return 1;
	EndIf;
	
EndFunction


&AtClient
// Calculates a VAT amount for the document line
//
Procedure LineItemsVATCodeOnChange(Item)
	
	TabularPartRow = Items.LineItems.CurrentData;
	TabularPartRow.VAT = VAT_FL.VATLine(TabularPartRow.LineTotal, TabularPartRow.VATCode, "Purchase", Object.PriceIncludesVAT);
    RecalcTotal();

EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	// Request and fill order status from database
	FillOrderStatuses();
	
	// Request and fill ordered items from database
	FillOrdersDispatched();
	
	// Request and fill indexes of product type (required to calculate bacorder property)
	FillProductTypes();
		
EndProcedure

&AtClient
Procedure LineItemsOnChange(Item)
	
	If NewRow = true Then
		CurrentData = Item.CurrentData;
		//CurrentData.Project = Object.Project;
		NewRow = false;
	Endif;

EndProcedure

&AtClient
Procedure LineItemsBeforeAddRow(Item, Cancel, Clone, Parent, Folder)
	
	NewRow = true;
	
EndProcedure
