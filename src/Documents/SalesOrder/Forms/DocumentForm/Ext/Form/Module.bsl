
////////////////////////////////////////////////////////////////////////////////
// Sales order: Document form
//------------------------------------------------------------------------------
// Available on:
// - Client (managed application)
// - Server
//

////////////////////////////////////////////////////////////////////////////////
#Region EVENTS_HANDLERS

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	//------------------------------------------------------------------------------
	// 1. Form attributes initialization.
	
	// Set LineItems editing flag.
	IsNewRow     = False;
	
	// Fill object attributes cache.
	DeliveryDate = Object.DeliveryDate;
	Location     = Object.Location;
	Project      = Object.Project;
	Class        = Object.Class;
	
	//------------------------------------------------------------------------------
	// 2. Calculate values of form object attributes.
	
	// Request and fill order status.
	FillOrderStatusAtServer();
	
	// Request and fill ordered items from database.
	FillBackorderQuantityAtServer();
	
	//------------------------------------------------------------------------------
	// 3. Set custom controls presentation.
	
	// Set proper Company field presentation.
	Items.CompanyTitle.Title = GeneralFunctionsReusable.GetCustomerName() + ":";
	
	// Update quantities presentation.
	QuantityPrecision = Format(Constants.QtyPrecision.Get(), "NFD=0; NZ=0; NG=0");
	QuantityFormat    = "NFD=" + QuantityPrecision + "; NZ=0";
	Items.LineItemsQuantity.EditFormat  = QuantityFormat;
	Items.LineItemsQuantity.Format      = QuantityFormat;
	Items.LineItemsShipped.EditFormat   = QuantityFormat;
	Items.LineItemsShipped.Format       = QuantityFormat;
	Items.LineItemsInvoiced.EditFormat  = QuantityFormat;
	Items.LineItemsInvoiced.Format      = QuantityFormat;
	Items.LineItemsBackorder.EditFormat = QuantityFormat;
	Items.LineItemsBackorder.Format     = QuantityFormat;
	
	// Update visibility of controls depending on functional options.
	If Not GeneralFunctionsReusable.FunctionalOptionValue("USFinLocalization") Then
		Items.SalesTaxGroup.Visible = False;
	EndIf;
	If Not GeneralFunctionsReusable.FunctionalOptionValue("VATFinLocalization") Then
		Items.VATGroup.Visible = False;
	EndIf;
	If Not GeneralFunctionsReusable.FunctionalOptionValue("MultiCurrency") Then
		Items.FCYGroup.Visible = False;
	EndIf;
	
	// Set currency title.
	DefaultCurrencySymbol        = GeneralFunctionsReusable.DefaultCurrencySymbol();
	ForeignCurrencySymbol        = Object.Currency.Symbol;
	Items.ExchangeRate.Title     = DefaultCurrencySymbol + "/1" + ForeignCurrencySymbol;
	Items.SalesTaxCurrency.Title = ForeignCurrencySymbol;
	Items.VATCurrency.Title      = ForeignCurrencySymbol;
	Items.FCYCurrency.Title      = ForeignCurrencySymbol;
	Items.RCCurrency.Title       = DefaultCurrencySymbol;
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	//------------------------------------------------------------------------------
	// Recalculate values of form object attributes.
	
	// Request and fill order status from database.
	FillOrderStatusAtServer();
	
	// Request and fill ordered items from database.
	FillBackorderQuantityAtServer();
	
EndProcedure

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region CONTROLS_EVENTS_HANDLERS

&AtClient
Procedure DateOnChange(Item)
	
	// Request server operation.
	DateOnChangeAtServer();
	
EndProcedure

&AtServer
Procedure DateOnChangeAtServer()
	
	// Recalculate the retail price for all rows for new date.
	FillRetailPricesAtServer();
	
	// Request exchange rate on the new date.
	Object.ExchangeRate = GeneralFunctions.GetExchangeRate(Object.Date, Object.Currency);
	
	// Process settings changes.
	ExchangeRateOnChangeAtServer();
	
EndProcedure

&AtClient
Procedure CompanyCodeTextEditEnd(Item, Text, ChoiceData, Parameters, StandardProcessing)
	
	// Search for a company ref and assign it to a company.
	CompanyCodeTextEditEndAtServer(Text, Object.Company, StandardProcessing);
	If StandardProcessing Then
		// Company successfully found and assigned.
		CompanyOnChange(Items.Company);
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure CompanyCodeTextEditEndAtServer(Text, CompanyRef, StandardProcessing)
	
	// Search for a company with entered code.
	CompanyRef = Catalogs.Companies.FindByCode(Text);
	If CompanyRef.IsEmpty() Then
		
		// Try to find company using full code.
		CodeLength = Metadata.Catalogs.Companies.CodeLength;
		FullCode   = Right("0000000000" + Text, CodeLength);
		CompanyRef = Catalogs.Companies.FindByCode(FullCode);
		
		// If company found by the full code then update the text.
		If Not CompanyRef.IsEmpty() Then
			Text = FullCode;
		EndIf;
	EndIf;
	
	// If company is not found - let the system show, that something going wrong.
	StandardProcessing = Not CompanyRef.IsEmpty();
	
EndProcedure

&AtClient
Procedure CompanyOnChange(Item)
	
	// Request server operation.
	CompanyOnChangeAtServer();
	
EndProcedure

&AtServer
Procedure CompanyOnChangeAtServer()
	
	// Update company presentation.
	Object.CompanyCode = Object.Company.Code;
	
	// Reset company adresses (if company was changed).
	FillCompanyAddressesAtServer(Object.Company, Object.ShipTo, Object.BillTo, Object.ConfirmTo);
	TaxRate = ?(Not Object.ShipTo.IsEmpty(), US_FL.GetTaxRate(Object.ShipTo), 0);
	
	// Recalculate sales prices for the company.
	FillRetailPricesAtServer();
	
	// Request company default settings.
	Object.Currency    = Object.Company.DefaultCurrency;
	
	// Process settings changes.
	CurrencyOnChangeAtServer();
	
EndProcedure

&AtClient
Procedure ShipToOnChange(Item)
	
	// Request server operation.
	ShipToOnChangeAtServer();
	
EndProcedure

&AtServer
Procedure ShipToOnChangeAtServer()
	
	// Recalculate the tax rate depending on the shipping address.
	TaxRate = ?(Not Object.ShipTo.IsEmpty(), US_FL.GetTaxRate(Object.ShipTo), 0);
	
	// Recalculate totals with new tax rate.
	RecalculateTotalsAtServer();
	
EndProcedure

&AtClient
Procedure CurrencyOnChange(Item)
	
	// Request server operation.
	CurrencyOnChangeAtServer();
	
EndProcedure

&AtServer
Procedure CurrencyOnChangeAtServer()
	
	// Update currency presentation.
	DefaultCurrencySymbol    = GeneralFunctionsReusable.DefaultCurrencySymbol();
	ForeignCurrencySymbol    = Object.Currency.Symbol;
	Items.ExchangeRate.Title = DefaultCurrencySymbol + "/1" + ForeignCurrencySymbol;
	Items.VATCurrency.Title  = ForeignCurrencySymbol;
	Items.RCCurrency.Title   = DefaultCurrencySymbol;
	Items.FCYCurrency.Title  = ForeignCurrencySymbol;
	
	// Request currency default settings.
	Object.ExchangeRate = GeneralFunctions.GetExchangeRate(Object.Date, Object.Currency);
	
	// Process settings changes.
	ExchangeRateOnChangeAtServer();
	
EndProcedure

&AtClient
Procedure ExchangeRateOnChange(Item)
	
	// Request server operation.
	ExchangeRateOnChangeAtServer();
	
EndProcedure

&AtServer
Procedure ExchangeRateOnChangeAtServer()
	
	// Recalculate totals with new exchange rate.
	RecalculateTotalsAtServer();
	
EndProcedure

&AtClient
Procedure PriceIncludesVATOnChange(Item)
	
	// Request server operation.
	PriceIncludesVATOnChangeAtServer();
	
EndProcedure

&AtServer
Procedure PriceIncludesVATOnChangeAtServer()
	
	// Calculate taxes by line total.
	For Each TableSectionRow In Object.LineItems Do
		TableSectionRow.VAT = VAT_FL.VATLine(TableSectionRow.LineTotal, TableSectionRow.VATCode, "Sales", Object.PriceIncludesVAT);
	EndDo;
	
	// Update overall totals.
	RecalculateTotalsAtServer();
	
EndProcedure

&AtClient
Procedure LocationOnChange(Item)
	
	// Ask user about updating the setting and update the line items accordingly.
	CommonDefaultSettingOnChange(Item, Lower(Item.Name));
	
EndProcedure

&AtClient
Procedure DeliveryDateOnChange(Item)
	
	// Ask user about updating the setting and update the line items accordingly.
	CommonDefaultSettingOnChange(Item, Lower(Item.ToolTip));
	
EndProcedure

&AtClient
Procedure ProjectOnChange(Item)
	
	// Ask user about updating the setting and update the line items accordingly.
	CommonDefaultSettingOnChange(Item, Lower(Item.Name));
	
EndProcedure

&AtClient
Procedure ClassOnChange(Item)
	
	// Ask user about updating the setting and update the line items accordingly.
	CommonDefaultSettingOnChange(Item, Lower(Item.Name));
	
EndProcedure

//------------------------------------------------------------------------------
// Utils for request user confirmation and propagate header settings to line items.

&AtClient
Procedure CommonDefaultSettingOnChange(Item, ItemPresentation)
	
	// Request user confirmation changing the setting for all LineItems.
	DefaultSetting = Item.Name;
	If Object.LineItems.Count() > 0 Then
		QuestionText  = StringFunctionsClientServer.SubstituteParametersInString(NStr("en = 'Reset the %1 for line items?'"), ItemPresentation);
		QuestionTitle = StringFunctionsClientServer.SubstituteParametersInString(NStr("en = 'Reset %1'"), ItemPresentation);
		ChoiceParameters = New Structure("DefaultSetting", DefaultSetting);
		ChoiceProcessing = New NotifyDescription("DefaultSettingOnChangeChoiceProcessing", ThisForm, ChoiceParameters);
		ShowQueryBox(ChoiceProcessing, QuestionText, QuestionDialogMode.YesNoCancel,, DialogReturnCode.Cancel, QuestionTitle);
	Else
		// Keep new setting.
		ThisForm[DefaultSetting] = Object[DefaultSetting];
	EndIf;
	
EndProcedure

&AtClient
Procedure DefaultSettingOnChangeChoiceProcessing(ChoiceResult, ChoiceParameters) Export
	
	// Get current processing item.
	DefaultSetting = ChoiceParameters.DefaultSetting;
	
	// Process user choice.
	If ChoiceResult = DialogReturnCode.Yes Then
		// Set new setting for all LineItems.
		ThisForm[DefaultSetting] = Object[DefaultSetting];
		DefaultSettingOnChangeAtServer(DefaultSetting);
		
	ElsIf ChoiceResult = DialogReturnCode.No Then
		// Keep new setting, do not update line items.
		ThisForm[DefaultSetting] = Object[DefaultSetting];
		
	Else
		// Restore previously entered setting.
		Object[DefaultSetting] = ThisForm[DefaultSetting];
	EndIf;
	
EndProcedure

&AtServer
Procedure DefaultSettingOnChangeAtServer(DefaultSetting)
	
	// Update line items fields by the object default value.
	For Each Row In Object.LineItems Do
		Row[DefaultSetting] = Object[DefaultSetting];
	EndDo;
	
EndProcedure

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region TABULAR_SECTION_EVENTS_HANDLERS

//------------------------------------------------------------------------------
// Tabular section LineItems event handlers.

&AtClient
Procedure LineItemsOnChange(Item)
	
	// Row was just added and became edited.
	If IsNewRow Then
		
		// Clear used flag.
		IsNewRow = False;
		
		// Fill new row with default values.
		ObjectData  = New Structure("Location, DeliveryDate, Project, Class");
		FillPropertyValues(ObjectData, Object);
		For Each ObjectField In ObjectData Do
			If Not ValueIsFilled(Item.CurrentData[ObjectField.Key]) Then
				Item.CurrentData[ObjectField.Key] = ObjectField.Value;
			EndIf;
		EndDo;
		
		// Refresh totals cache.
		RecalculateTotals();
	EndIf;
	
EndProcedure

&AtClient
Procedure LineItemsBeforeAddRow(Item, Cancel, Clone, Parent, Folder)
	
	// Set new row flag.
	If Not Cancel Then
		IsNewRow = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure LineItemsOnEditEnd(Item, NewRow, CancelEdit)
	
	// Recalculation common document totals.
	RecalculateTotalsAtServer();
	
EndProcedure

&AtClient
Procedure LineItemsAfterDeleteRow(Item)
	
	// Recalculation common document totals.
	RecalculateTotalsAtServer();
	
EndProcedure

//------------------------------------------------------------------------------
// Tabular section LineItems columns controls event handlers.

&AtClient
Procedure LineItemsProductOnChange(Item)
	
	// Fill line data for editing.
	TableSectionRow = GetLineItemsRowStructure();
	FillPropertyValues(TableSectionRow, Items.LineItems.CurrentData);
	
	// Request server operation.
	LineItemsProductOnChangeAtServer(TableSectionRow);
	
	// Load processed data back.
	FillPropertyValues(Items.LineItems.CurrentData, TableSectionRow);
	
	// Refresh totals cache.
	RecalculateTotals();
	
EndProcedure

&AtServer
Procedure LineItemsProductOnChangeAtServer(TableSectionRow)
	
	// Request product properties.
	ProductProperties = CommonUse.GetAttributeValues(TableSectionRow.Product, New Structure("Description, SalesVATCode, UM, Type"));
	TableSectionRow.ProductDescription = ProductProperties.Description;
	TableSectionRow.VATCode            = ProductProperties.SalesVATCode;
	TableSectionRow.UM                 = ProductProperties.UM;
	TableSectionRow.Price              = GeneralFunctions.RetailPrice(Object.Date, TableSectionRow.Product, Object.Company);
	TableSectionRow.SalesTaxType       = ?(ProductProperties.Type = Enums.InventoryTypes.Inventory,
	                                     Enums.SalesTaxTypes.Taxable, Enums.SalesTaxTypes.NonTaxable);
	
	// Reset default values.
	TableSectionRow.Location     = Object.Location;
	TableSectionRow.DeliveryDate = Object.DeliveryDate;
	TableSectionRow.Project      = Object.Project;
	TableSectionRow.Class        = Object.Class;
	
	// Assign default quantities.
	TableSectionRow.Quantity  = 0;
	TableSectionRow.Backorder = 0;
	TableSectionRow.Shipped   = 0;
	TableSectionRow.Invoiced  = 0;
	
	// Calculate totals by line.
	TableSectionRow.LineTotal     = 0;
	TableSectionRow.VAT           = 0;
	TableSectionRow.TaxableAmount = 0;
	
EndProcedure

&AtClient
Procedure LineItemsQuantityOnChange(Item)
	
	// Fill line data for editing.
	TableSectionRow = GetLineItemsRowStructure();
	FillPropertyValues(TableSectionRow, Items.LineItems.CurrentData);
	
	// Request server operation.
	LineItemsQuantityOnChangeAtServer(TableSectionRow);
	
	// Load processed data back.
	FillPropertyValues(Items.LineItems.CurrentData, TableSectionRow);
	
	// Refresh totals cache.
	RecalculateTotals();
	
EndProcedure

&AtServer
Procedure LineItemsQuantityOnChangeAtServer(TableSectionRow)
	
	// Update backorder quantity basing on document status.
	If OrderStatus = Enums.OrderStatuses.Open Then
		TableSectionRow.Backorder = 0;
		
	ElsIf OrderStatus = Enums.OrderStatuses.Backordered Then
		If TableSectionRow.Product.Type = Enums.InventoryTypes.Inventory Then
			TableSectionRow.Backorder = Max(TableSectionRow.Quantity - TableSectionRow.Shipped, 0);
		Else // TableSectionRow.Product.Type = Enums.InventoryTypes.NonInventory;
			TableSectionRow.Backorder = Max(TableSectionRow.Quantity - TableSectionRow.Invoiced, 0);
		EndIf;
		
	ElsIf OrderStatus = Enums.OrderStatuses.Closed Then
		TableSectionRow.Backorder = 0;
		
	Else
		TableSectionRow.Backorder = 0;
	EndIf;
	
	// Calculate total by line.
	TableSectionRow.LineTotal = Round(Round(TableSectionRow.Quantity, QuantityPrecision) * TableSectionRow.Price, 2);
	
	// Process settings changes.
	LineItemsLineTotalOnChangeAtServer(TableSectionRow);
	
EndProcedure

&AtClient
Procedure LineItemsPriceOnChange(Item)
	
	// Fill line data for editing.
	TableSectionRow = GetLineItemsRowStructure();
	FillPropertyValues(TableSectionRow, Items.LineItems.CurrentData);
	
	// Request server operation.
	LineItemsPriceOnChangeAtServer(TableSectionRow);
	
	// Load processed data back.
	FillPropertyValues(Items.LineItems.CurrentData, TableSectionRow);
	
	// Refresh totals cache.
	RecalculateTotals();
	
EndProcedure

&AtServer
Procedure LineItemsPriceOnChangeAtServer(TableSectionRow)
	
	// Calculate total by line.
	TableSectionRow.LineTotal = Round(Round(TableSectionRow.Quantity, QuantityPrecision) * TableSectionRow.Price, 2);
	
	// Process settings changes.
	LineItemsLineTotalOnChangeAtServer(TableSectionRow);
	
EndProcedure

&AtClient
Procedure LineItemsLineTotalOnChange(Item)
	
	// Fill line data for editing.
	TableSectionRow = GetLineItemsRowStructure();
	FillPropertyValues(TableSectionRow, Items.LineItems.CurrentData);
	
	// Request server operation.
	LineItemsLineTotalOnChangeAtServer(TableSectionRow);
	
	// Load processed data back.
	FillPropertyValues(Items.LineItems.CurrentData, TableSectionRow);
	
	// Refresh totals cache.
	RecalculateTotals();
	
EndProcedure

&AtServer
Procedure LineItemsLineTotalOnChangeAtServer(TableSectionRow)
	
	// Back-step price calculation with totals priority.
	TableSectionRow.Price = ?(Round(TableSectionRow.Quantity, QuantityPrecision) > 0,
	                          Round(TableSectionRow.LineTotal / Round(TableSectionRow.Quantity, QuantityPrecision), 2), 0);
	
	// Calculate taxes by line total.
	LineItemsVATCodeOnChangeAtServer(TableSectionRow);
	LineItemsSalesTaxTypeOnChangeAtServer(TableSectionRow);
	
EndProcedure

&AtClient
Procedure LineItemsVATCodeOnChange(Item)
	
	// Fill line data for editing.
	TableSectionRow = GetLineItemsRowStructure();
	FillPropertyValues(TableSectionRow, Items.LineItems.CurrentData);
	
	// Request server operation.
	LineItemsVATCodeOnChangeAtServer(TableSectionRow);
	
	// Load processed data back.
	FillPropertyValues(Items.LineItems.CurrentData, TableSectionRow);
	
	// Refresh totals cache.
	RecalculateTotals();
	
EndProcedure

&AtServer
Procedure LineItemsVATCodeOnChangeAtServer(TableSectionRow)
	
	// Calculate VAT by line total.
	TableSectionRow.VAT = VAT_FL.VATLine(TableSectionRow.LineTotal, TableSectionRow.VATCode, "Sales", Object.PriceIncludesVAT);
	
EndProcedure

&AtClient
Procedure LineItemsVATOnChange(Item)
	
	// Refresh totals cache.
	RecalculateTotals();
	
EndProcedure

&AtClient
Procedure LineItemsSalesTaxTypeOnChange(Item)
	
	// Fill line data for editing.
	TableSectionRow = GetLineItemsRowStructure();
	FillPropertyValues(TableSectionRow, Items.LineItems.CurrentData);
	
	// Request server operation.
	LineItemsSalesTaxTypeOnChangeAtServer(TableSectionRow);
	
	// Load processed data back.
	FillPropertyValues(Items.LineItems.CurrentData, TableSectionRow);
	
	// Refresh totals cache.
	RecalculateTotals();
	
EndProcedure

&AtServer
Procedure LineItemsSalesTaxTypeOnChangeAtServer(TableSectionRow)
	
	// Calculate sales tax by line total.
	TableSectionRow.TaxableAmount = ?(TableSectionRow.SalesTaxType = Enums.SalesTaxTypes.Taxable, TableSectionRow.LineTotal, 0);
	
EndProcedure

&AtClient
Procedure LineItemsTaxableAmountOnChange(Item)
	
	// Refresh totals cache.
	RecalculateTotals();
	
EndProcedure

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region COMMANDS_HANDLERS

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region PRIVATE_IMPLEMENTATION

//------------------------------------------------------------------------------
// Calculate values of form object attributes.

&AtServer
// Request order status from database.
Procedure FillOrderStatusAtServer()
	
	// Request order status.
	If (Not ValueIsFilled(Object.Ref)) Or (Object.DeletionMark) Or (Not Object.Posted) Then
		// The order has open status.
		OrderStatus = Enums.OrderStatuses.Open;
		
	Else
		// Create new query.
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
		Selection = Query.Execute().Select();
		
		// Fill order status.
		If Selection.Next() Then
			OrderStatus = Selection.Status;
		Else
			OrderStatus = Enums.OrderStatuses.Open;
		EndIf;
	EndIf;
	
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
// Request demanded order items from database.
Procedure FillBackorderQuantityAtServer()
	
	// Request ordered items quantities
	If ValueIsFilled(Object.Ref) Then
		
		// Create new query
		Query = New Query;
		Query.SetParameter("Ref", Object.Ref);
		Query.SetParameter("OrderStatus", OrderStatus);
		
		Query.Text = 
			"SELECT
			|	LineItems.LineNumber                     AS LineNumber,
			//  Request dimensions
			|	OrdersRegisteredBalance.Product          AS Product,
			|	OrdersRegisteredBalance.Location         AS Location,
			|	OrdersRegisteredBalance.DeliveryDate     AS DeliveryDate,
			|	OrdersRegisteredBalance.Project          AS Project,
			|	OrdersRegisteredBalance.Class            AS Class,
			//  Request resources                                                                                               // ---------------------------------------
			|	OrdersRegisteredBalance.QuantityBalance  AS Quantity,                                                           // Backorder quantity calculation
			|	CASE                                                                                                            // ---------------------------------------
			|		WHEN &OrderStatus = VALUE(Enum.OrderStatuses.Open)        THEN 0                                            // Order status = Open:
			|		WHEN &OrderStatus = VALUE(Enum.OrderStatuses.Backordered) THEN                                              //   Backorder = 0
			|			CASE                                                                                                    // Order status = Backorder:
			|				WHEN OrdersRegisteredBalance.Product.Type = VALUE(Enum.InventoryTypes.Inventory) THEN               //   Inventory:
			|					CASE                                                                                            //     Backorder = Ordered - Shipped >= 0
			|						WHEN OrdersRegisteredBalance.QuantityBalance > OrdersRegisteredBalance.ShippedBalance THEN  //     |
			|							 OrdersRegisteredBalance.QuantityBalance - OrdersRegisteredBalance.ShippedBalance       //     |
			|						ELSE 0 END                                                                                  //     |
			|				ELSE                                                                                                //   Non-inventory:
			|					CASE                                                                                            //     Backorder = Ordered - Invoiced >= 0
			|						WHEN OrdersRegisteredBalance.QuantityBalance > OrdersRegisteredBalance.InvoicedBalance THEN //     |
			|							 OrdersRegisteredBalance.QuantityBalance - OrdersRegisteredBalance.InvoicedBalance      //     |
			|						ELSE 0 END                                                                                  //     |
			|				END                                                                                                 //     |
			|		WHEN &OrderStatus = VALUE(Enum.OrderStatuses.Closed)      THEN 0                                            // Order status = Closed:
			|		END                                  AS Backorder,                                                          //                           Backorder = 0
			|	OrdersRegisteredBalance.ShippedBalance   AS Shipped,
			|	OrdersRegisteredBalance.InvoicedBalance  AS Invoiced
			//  Request sources
			|FROM
			|	Document.SalesOrder.LineItems            AS LineItems
			|	LEFT JOIN AccumulationRegister.OrdersRegistered.Balance(,Order = &Ref)
			|	                                         AS OrdersRegisteredBalance
			|		ON    ( LineItems.Ref.Company         = OrdersRegisteredBalance.Company
			|			AND LineItems.Ref                 = OrdersRegisteredBalance.Order
			|			AND LineItems.Product             = OrdersRegisteredBalance.Product
			|			AND LineItems.Location            = OrdersRegisteredBalance.Location
			|			AND LineItems.DeliveryDate        = OrdersRegisteredBalance.DeliveryDate
			|			AND LineItems.Project             = OrdersRegisteredBalance.Project
			|			AND LineItems.Class               = OrdersRegisteredBalance.Class
			|			AND LineItems.Quantity            = OrdersRegisteredBalance.QuantityBalance)
			//  Request filtering
			|WHERE
			|	LineItems.Ref = &Ref
			//  Request ordering
			|ORDER BY
			|	LineItems.LineNumber";
		Selection = Query.Execute().Select();
		
		// Fill ordered items quantities
		SearchRec = New Structure("LineNumber, Product, Location, DeliveryDate, Project, Class, Quantity");
		While Selection.Next() Do
			
			// Search for appropriate line in tabular section of order
			FillPropertyValues(SearchRec, Selection);
			FoundLineItems = Object.LineItems.FindRows(SearchRec);
			
			// Fill quantities in tabular section
			If FoundLineItems.Count() > 0 Then
				FillPropertyValues(FoundLineItems[0], Selection, "Backorder, Shipped, Invoiced");
			EndIf;
			
		EndDo;
		
	EndIf;
	
EndProcedure

&AtServer
// Request retail prices of the products from database.
Procedure FillRetailPricesAtServer()
	
	// Recalculate retail price for each row (later the new function scanning prices for the product must be used).
	For Each TableSectionRow In Object.LineItems Do
		TableSectionRow.Price = GeneralFunctions.RetailPrice(Object.Date, TableSectionRow.Product, Object.Company);
		LineItemsPriceOnChangeAtServer(TableSectionRow);
	EndDo;
	
EndProcedure

&AtServer
// Request and fill company addresses used for proper goods delivery.
Procedure FillCompanyAddressesAtServer(Company, ShipTo, BillTo, ConfirmTo);
	
	// Define empty address.
	EmptyAddress = Catalogs.Addresses.EmptyRef();
	
	// Check if company changed and addresses are required to be refilled.
	If BillTo    = EmptyAddress Or BillTo.Owner    <> Company
	Or ShipTo    = EmptyAddress Or ShipTo.Owner    <> Company
	Or ConfirmTo = EmptyAddress Or ConfirmTo.Owner <> Company Then
		
		// Create new query
		Query = New Query;
		Query.SetParameter("Ref", Company);
		
		Query.Text =
		"SELECT
		|	Addresses.Ref,
		|	Addresses.DefaultBilling,
		|	Addresses.DefaultShipping
		|FROM
		|	Catalog.Addresses AS Addresses
		|WHERE
		|	Addresses.Owner = &Ref
		|	AND (Addresses.DefaultBilling
		|	  OR Addresses.DefaultShipping)";
		Selection = Query.Execute().Select();
		
		// Assign default addresses.
		While Selection.Next() Do
			If Selection.DefaultBilling Then
				BillTo = Selection.Ref;
			EndIf;
			If Selection.DefaultShipping Then
				ShipTo = Selection.Ref;
			EndIf;
		EndDo;
		ConfirmTo      = EmptyAddress;
	EndIf;
	
EndProcedure

//------------------------------------------------------------------------------
// Calculate totals and fill object attributes.

&AtClient
// The procedure recalculates the document's totals.
// VATTotal        - VAT total in foreign currency.
// VATTotalRC      - VAT total in reporting currency.
// DocumentTotal   - document total in foreign currency.
// DocumentTotalRC - document total in reporting currency.
//
Procedure RecalculateTotals()
	
	// Calculate document totals.
	VATTotal = 0; TaxableAmount = 0; DocumentTotal = 0;
	For Each Row In Object.LineItems Do
		VATTotal      = VATTotal      + Row.VAT;
		TaxableAmount = TaxableAmount + Row.TaxableAmount;
		DocumentTotal = DocumentTotal + Row.LineTotal;
	EndDo;
	
	// Assign totals to the object fields.
	Object.SalesTax        = Round(TaxableAmount * TaxRate/100, 2);
	Object.SalesTaxRC      = Round(Object.SalesTax * Object.ExchangeRate, 2);
	Object.VATTotal        = VATTotal;
	Object.VATTotalRC      = Round(Object.VATTotal * Object.ExchangeRate, 2);
	Object.DocumentTotal   = DocumentTotal + Object.SalesTax + ?(Object.PriceIncludesVAT, 0, VATTotal);
	Object.DocumentTotalRC = Round(Object.DocumentTotal * Object.ExchangeRate, 2);
	
EndProcedure

&AtServer
// The procedure recalculates the document's totals.
// VATTotal        - VAT total in foreign currency.
// VATTotalRC      - VAT total in reporting currency.
// DocumentTotal   - document total in foreign currency.
// DocumentTotalRC - document total in reporting currency.
//
Procedure RecalculateTotalsAtServer()
	
	// Calculate document totals.
	Object.SalesTax        = Round(Object.LineItems.Total("TaxableAmount") * TaxRate/100, 2);
	Object.SalesTaxRC      = Round(Object.SalesTax * Object.ExchangeRate, 2);
	Object.VATTotal        = Object.LineItems.Total("VAT");
	Object.VATTotalRC      = Round(Object.VATTotal * Object.ExchangeRate, 2);
	Object.DocumentTotal   = Object.LineItems.Total("LineTotal") + Object.SalesTax + ?(Object.PriceIncludesVAT, 0, Object.VATTotal);
	Object.DocumentTotalRC = Round(Object.DocumentTotal * Object.ExchangeRate, 2);
	
EndProcedure

//------------------------------------------------------------------------------
// Replacemant for metadata properties on client.

&AtClient
// Returns fields structure of LineItems form control.
Function GetLineItemsRowStructure()
	
	// Define control row fields.
	Return New Structure("Product, ProductDescription, Quantity, UM, Backorder, Price, SalesTaxType, TaxableAmount, LineTotal, VATCode, VAT, Location, DeliveryDate, Project, Class, Shipped, Invoiced");
	
EndFunction

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region CODE_REVIEW

//------------------------------------------------------------------------------
// Closing the period

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	//Closing period
	If DocumentPosting.DocumentPeriodIsClosed(Object.Ref, Object.Date) Then
		Cancel = Not DocumentPosting.DocumentWritePermitted(WriteParameters);
		If Cancel Then
			If WriteParameters.Property("PeriodClosingPassword") And WriteParameters.Property("Password") Then
				If WriteParameters.Password = TRUE Then //Writing the document requires a password
					ShowMessageBox(, "Invalid password!",, "Closed period notification");
				EndIf;
			Else
				Notify = New NotifyDescription("ProcessUserResponseOnDocumentPeriodClosed", ThisObject, WriteParameters);
				Password = "";
				OpenForm("CommonForm.ClosedPeriodNotification", New Structure, ThisForm,,,, Notify, FormWindowOpeningMode.LockOwnerWindow);
			EndIf;
			return;
		EndIf;
	EndIf;

EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	//Period closing
	If DocumentPosting.DocumentPeriodIsClosed(CurrentObject.Ref, CurrentObject.Date) Then
		PermitWrite = DocumentPosting.DocumentWritePermitted(WriteParameters);
		CurrentObject.AdditionalProperties.Insert("PermitWrite", PermitWrite);	
	EndIf;
	
EndProcedure

&AtClient
Procedure ProcessUserResponseOnDocumentPeriodClosed(Result, Parameters) Export
	If (TypeOf(Result) = Type("String")) Then //Inserted password
		Parameters.Insert("PeriodClosingPassword", Result);
		Parameters.Insert("Password", TRUE);
		Write(Parameters);
	ElsIf (TypeOf(Result) = Type("DialogReturnCode")) Then //Yes, No or Cancel
		If Result = DialogReturnCode.Yes Then
			Parameters.Insert("PeriodClosingPassword", "Yes");
			Parameters.Insert("Password", FALSE);
			Write(Parameters);
		EndIf;
	EndIf;	
EndProcedure

#EndRegion
