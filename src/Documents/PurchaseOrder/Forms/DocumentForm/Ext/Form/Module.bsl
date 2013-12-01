
////////////////////////////////////////////////////////////////////////////////
// Purchase order: Document form
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
	Location     = Object.Location;
	Project      = Object.Project;
	Class        = Object.Class;
	DeliveryDate = Object.DeliveryDate;
	
	//------------------------------------------------------------------------------
	// 2. Calculate values of form object attributes.
	
	// Request and fill order status.
	FillOrderStatus();
	
	// Request and fill ordered items from database.
	FillBackorderQuantity();
	
	// Request and fill indexes of product type (required to calculate backorder property).
	FillProductTypes();
	
	//------------------------------------------------------------------------------
	// 3. Set custom controls presentation.
	
	// Set proper Company field presentation.
	Items.CompanyTitle.Title = GeneralFunctionsReusable.GetVendorName() + ":";
	
	// Update quantities presentation.
	QuantityPrecision = Format(Constants.QtyPrecision.Get(), "NFD=0; NZ=0; NG=0");
	QuantityFormat    = "NFD=" + QuantityPrecision + "; NZ=0";
	Items.LineItemsQuantity.EditFormat  = QuantityFormat;
	Items.LineItemsQuantity.Format      = QuantityFormat;
	Items.LineItemsReceived.EditFormat  = QuantityFormat;
	Items.LineItemsReceived.Format      = QuantityFormat;
	Items.LineItemsInvoiced.EditFormat  = QuantityFormat;
	Items.LineItemsInvoiced.Format      = QuantityFormat;
	Items.LineItemsBackorder.EditFormat = QuantityFormat;
	Items.LineItemsBackorder.Format     = QuantityFormat;
	
	// Update visibility of controls depending on functional options.
	If Not GeneralFunctionsReusable.FunctionalOptionValue("VATFinLocalization") Then
		Items.VATGroup.Visible = False;
	EndIf;
	If Not GeneralFunctionsReusable.FunctionalOptionValue("MultiCurrency") Then
		Items.FCYGroup.Visible = False;
	EndIf;
	
	// Set currency title.
	DefaultCurrencySymbol    = GeneralFunctionsReusable.DefaultCurrencySymbol();
	ForeignCurrencySymbol    = Object.Currency.Symbol;
	Items.ExchangeRate.Title = DefaultCurrencySymbol + "/1" + ForeignCurrencySymbol;
	Items.VATCurrency.Title  = ForeignCurrencySymbol;
	Items.RCCurrency.Title   = DefaultCurrencySymbol;
	Items.FCYCurrency.Title  = ForeignCurrencySymbol;
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	//------------------------------------------------------------------------------
	// Realculate values of form object attributes.
	
	// Request and fill order status from database.
	FillOrderStatus();
	
	// Request and fill ordered items from database.
	FillBackorderQuantity();
	
	// Request and fill indexes of product type (required to calculate backorder property).
	FillProductTypes();
	
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
	
	// Request exchange rate on the new date.
	Object.ExchangeRate = GeneralFunctions.GetExchangeRate(Object.Date, Object.Currency);
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
	
	// Request company default settings.
	Object.Currency    = Object.Company.DefaultCurrency;
	CurrencyOnChangeAtServer();
	
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
	RecalculateTotals();
	
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
		TableSectionRow.VAT = VAT_FL.VATLine(TableSectionRow.LineTotal, TableSectionRow.VATCode, "Purchase", Object.PriceIncludesVAT);
	EndDo;
	
	// Update overall totals.
	RecalculateTotals();
	
EndProcedure

&AtClient
Procedure LocationOnChange(Item)
	
	// Ask user about updating the setting and update the line items accordingly.
	CommonDefaultSettingOnChange(Item, Lower(Item.Name));
	
EndProcedure

&AtClient
Procedure DeliveryDateOnChange(Item)
	
	// Ask user about updating the setting and update the line items accordingly.
	CommonDefaultSettingOnChange(Item, "delivery date");
	
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
	RecalculateTotals();
	
EndProcedure

&AtClient
Procedure LineItemsAfterDeleteRow(Item)
	
	// Recalculation common document totals.
	RecalculateTotals();
	
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
	
EndProcedure

&AtServer
Procedure LineItemsProductOnChangeAtServer(TableSectionRow)
	
	// Request product properties.
	ProductProperties = CommonUse.GetAttributeValues(TableSectionRow.Product, New Structure("Description, PurchaseVATCode, UM, TypeIndex",,,,"Type.Order"));
	TableSectionRow.ProductDescription = ProductProperties.Description;
	TableSectionRow.ProductTypeIndex   = ProductProperties.TypeIndex;
	TableSectionRow.VATCode            = ProductProperties.PurchaseVATCode;
	TableSectionRow.UM                 = ProductProperties.UM;
	TableSectionRow.Price              = GeneralFunctions.ProductLastCost(TableSectionRow.Product);
	
	// Reset default values.
	TableSectionRow.Location     = Object.Location;
	TableSectionRow.DeliveryDate = Object.DeliveryDate;
	TableSectionRow.Project      = Object.Project;
	TableSectionRow.Class        = Object.Class;
	
	// Assign default quantities.
	TableSectionRow.Quantity  = 0;
	TableSectionRow.Backorder = 0;
	TableSectionRow.Received  = 0;
	TableSectionRow.Invoiced  = 0;
	
	// Calculate totals by line.
	TableSectionRow.LineTotal = 0;
	TableSectionRow.VAT       = 0;
	
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
	
EndProcedure

&AtServer
Procedure LineItemsQuantityOnChangeAtServer(TableSectionRow)
	
	// Update backorder quantity basing on document status.
	If OrderStatusIndex = 0 Then    // OrderStatus = Enums.OrderStatuses.Open
		TableSectionRow.Backorder = 0;
		
	ElsIf OrderStatusIndex = 1 Then // OrderStatus = Enums.OrderStatuses.Backordered
		If TableSectionRow.ProductTypeIndex = 0 Then
			// Product.Type = Enums.InventoryTypes.Inventory
			TableSectionRow.Backorder = Max(TableSectionRow.Quantity - TableSectionRow.Received, 0);
		Else 
			// Product.Type = Enums.InventoryTypes.NonInventory;
			TableSectionRow.Backorder = Max(TableSectionRow.Quantity - TableSectionRow.Invoiced, 0);
		EndIf;
		
	ElsIf OrderStatusIndex = 2 Then // OrderStatus = Enums.OrderStatuses.Closed
		TableSectionRow.Backorder = 0;
		
	Else
		TableSectionRow.Backorder = 0;
	EndIf;
	
	// Calculate total by line.
	TableSectionRow.LineTotal = Round(Round(TableSectionRow.Quantity, QuantityPrecision) * TableSectionRow.Price, 2);
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
	
EndProcedure

&AtServer
Procedure LineItemsPriceOnChangeAtServer(TableSectionRow)
	
	// Calculate total by line.
	TableSectionRow.LineTotal = Round(Round(TableSectionRow.Quantity, QuantityPrecision) * TableSectionRow.Price, 2);
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
	
EndProcedure

&AtServer
Procedure LineItemsLineTotalOnChangeAtServer(TableSectionRow)
	
	// Back-step price calculation with totals priority.
	TableSectionRow.Price = ?(Round(TableSectionRow.Quantity, QuantityPrecision) > 0,
	                          Round(TableSectionRow.LineTotal / Round(TableSectionRow.Quantity, QuantityPrecision), 2), 0);
	
	// Calculate taxes by line total.
	TableSectionRow.VAT = VAT_FL.VATLine(TableSectionRow.LineTotal, TableSectionRow.VATCode, "Purchase", Object.PriceIncludesVAT);
	
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
	
EndProcedure

&AtServer
Procedure LineItemsVATCodeOnChangeAtServer(TableSectionRow)
	
	// Calculate taxes by line total.
	TableSectionRow.VAT = VAT_FL.VATLine(TableSectionRow.LineTotal, TableSectionRow.VATCode, "Purchase", Object.PriceIncludesVAT);
	
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
// Request order status from database
Procedure FillOrderStatus()
	
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
Procedure FillBackorderQuantity()
	
	// Request ordered items quantities
	If ValueIsFilled(Object.Ref) Then
		
		// Create new query
		Query = New Query;
		Query.SetParameter("Ref", Object.Ref);
		Query.SetParameter("OrderStatus", OrderStatus);
		
		Query.Text = 
			"SELECT
			|	OrdersDispatched.LineNumber              AS LineNumber,
			//  Request dimensions
			|	OrdersDispatchedBalance.Product          AS Product,
			|	OrdersDispatchedBalance.Location         AS Location,
			|	OrdersDispatchedBalance.DeliveryDate     AS DeliveryDate,
			|	OrdersDispatchedBalance.Project          AS Project,
			|	OrdersDispatchedBalance.Class            AS Class,
			//  Request resources                                                                                               // ---------------------------------------
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
			|		END                                 AS Backorder,                                                                                           //   Backorder = 0
			|	OrdersDispatchedBalance.ReceivedBalance AS Received,
			|	OrdersDispatchedBalance.InvoicedBalance AS Invoiced
			//  Request sources
			|FROM
			|	AccumulationRegister.OrdersDispatched.Balance(,
			|		(Company, Order, Product, Location, DeliveryDate, Project, Class) IN
			|			(SELECT
			|				LineItems.Ref.Company,
			|				LineItems.Ref,
			|				LineItems.Product,
			|				LineItems.Location,
			|				LineItems.DeliveryDate,
			|				LineItems.Project,
			|				LineItems.Class
			|			FROM
			|				Document.PurchaseOrder.LineItems AS LineItems
			|			WHERE
			|				LineItems.Ref = &Ref)) AS OrdersDispatchedBalance
			|	LEFT JOIN AccumulationRegister.OrdersDispatched AS OrdersDispatched
			|		ON    ( OrdersDispatched.Recorder      = &Ref
			|			AND OrdersDispatched.Company       = OrdersDispatchedBalance.Company
			|			AND OrdersDispatched.Order         = OrdersDispatchedBalance.Order
			|			AND OrdersDispatched.Product       = OrdersDispatchedBalance.Product
			|			AND OrdersDispatched.Location      = OrdersDispatchedBalance.Location
			|			AND OrdersDispatched.DeliveryDate  = OrdersDispatchedBalance.DeliveryDate
			|			AND OrdersDispatched.Project       = OrdersDispatchedBalance.Project
			|			AND OrdersDispatched.Class         = OrdersDispatchedBalance.Class
			|			AND OrdersDispatched.Quantity      = OrdersDispatchedBalance.QuantityBalance)
			//  Request ordering
			|ORDER BY
			|	OrdersDispatched.LineNumber";
		Selection = Query.Execute().Choose();
		
		// Fill ordered items quantities
		SearchRec = New Structure("LineNumber, Product, Location, DeliveryDate, Project, Class, Quantity");
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
// Request and fill indexes of product type (required to calculate backorder property)
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

//------------------------------------------------------------------------------
// Calculate totals and fill object attributes.

&AtServer
// The procedure recalculates the document's totals.
// VATTotal        - VAT total in foreign currency.
// VATTotalRC      - VAT total in reporting currency.
// DocumentTotal   - document total in foreign currency.
// DocumentTotalRC - document total in reporting currency.
//
Procedure RecalculateTotals()
	
	// Calculate document totals.
	Object.VATTotal        = Object.LineItems.Total("VAT");
	Object.VATTotalRC      = Round(Object.VATTotal * Object.ExchangeRate, 2);
	Object.DocumentTotal   = Object.LineItems.Total("LineTotal") + ?(Object.PriceIncludesVAT, 0, Object.VATTotal);
	Object.DocumentTotalRC = Round(Object.DocumentTotal * Object.ExchangeRate, 2);
	
EndProcedure

//------------------------------------------------------------------------------
// Replacemant for metadata properties on client.

&AtClient
// Returns fields structure of LineItems form control.
Function GetLineItemsRowStructure()
	
	// Define control row fields.
	Return New Structure("Product, ProductDescription, ProductTypeIndex, Quantity, UM, Backorder, Price, LineTotal, VATCode, VAT, Location, DeliveryDate, Project, Class, Received, Invoiced");
	
EndFunction

#EndRegion
