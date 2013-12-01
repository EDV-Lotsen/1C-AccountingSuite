
////////////////////////////////////////////////////////////////////////////////
// Purchase invoice: Document form
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
	Location             = Object.Location;
	Project              = Object.Project;
	Class                = Object.Class;
	DeliveryDate         = Object.DeliveryDate;
	
	// Fill description of fields, presented by code.
	APAccountDescription = Object.APAccount.Description;
	
	//------------------------------------------------------------------------------
	// 2. Calculate values of form object attributes.
	
	// Request and fill invoice status.
	FillInvoiceStatus();
	
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
	Items.LineItemsOrdered.EditFormat   = QuantityFormat;
	Items.LineItemsOrdered.Format       = QuantityFormat;
	Items.LineItemsReceived.EditFormat  = QuantityFormat;
	Items.LineItemsReceived.Format      = QuantityFormat;
	Items.LineItemsBackorder.EditFormat = QuantityFormat;
	Items.LineItemsBackorder.Format     = QuantityFormat;
	Items.LineItemsInvoiced.EditFormat  = QuantityFormat;
	Items.LineItemsInvoiced.Format      = QuantityFormat;
	
	// Update visibility of controls depending on functional options.
	If Not GeneralFunctionsReusable.FunctionalOptionValue("VATFinLocalization") Then
		Items.VATGroup.Visible = False;
	EndIf;
	If Not GeneralFunctionsReusable.FunctionalOptionValue("MultiCurrency") Then
		Items.FCYGroup.Visible = False;
	EndIf;
	
	// Ajust controls availability for the begining balances documents.
	If Object.BegBal  Then
		Items.VATTotal.ReadOnly        = False;
		Items.DocumentTotalRC.ReadOnly = False;
		Items.DocumentTotal.ReadOnly   = False;
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
	
	// Request and fill invoice status from database.
	FillInvoiceStatus();
	
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
	
	// Process settings changes.
	ExchangeRateOnChangeAtServer();
	
	// Update due date basing on the currently selected terms.
	If Not Object.Terms.IsEmpty() Then
		Object.DueDate = Object.Date + Object.Terms.Days * 60*60*24;
		
		// Process settings changes.
		//DueDateOnChangeAtServer();
	EndIf;
	
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
	
	
	///
	
	// Sugest filling of invoice by non-closed orders.
	If (Not Object.Company.IsEmpty()) And (HasNonClosedOrders(Object.Company)) Then
		
		// Define form parameters.
		FormParameters = New Structure();
		FormParameters.Insert("ChoiceMode",     True);
		FormParameters.Insert("MultipleChoice", True);
		
		// Define list filter.
		FltrParameters = New Structure();
		FltrParameters.Insert("Company",     Object.Company); 
		FltrParameters.Insert("OrderStatus", GetNonClosedOrderStatuses());
		FormParameters.Insert("Filter",      FltrParameters);
		
		// Open orders selection form.
		NotifyDescription = New NotifyDescription("OrderSelection", ThisForm);
		OpenForm("Document.PurchaseOrder.ChoiceForm", FormParameters, Item,,,, NotifyDescription);
	EndIf;
	
	///
	
EndProcedure

&AtServer
Procedure CompanyOnChangeAtServer()
	
	// Update company presentation.
	Object.CompanyCode = Object.Company.Code;
	
	// Request company default settings.
	Object.Currency    = Object.Company.DefaultCurrency;
	Object.Terms       = CommonUse.GetAttributeValue(Object.Company, "Terms");
	
	// Process settings changes.
	CurrencyOnChangeAtServer();
	TermsOnChangeAtServer();
	
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
	Object.ExchangeRate      = GeneralFunctions.GetExchangeRate(Object.Date, Object.Currency);
	Object.APAccount         = Object.Currency.DefaultAPAccount;
	
	// Process settings changes.
	ExchangeRateOnChangeAtServer();
	APAccountOnChangeAtServer();
	
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
Procedure APAccountOnChange(Item)
	
	// Request server operation.
	APAccountOnChangeAtServer();
	
EndProcedure

&AtServer
Procedure APAccountOnChangeAtServer()
	
	// Update account presentation.
	APAccountDescription = Object.APAccount.Description;
	
EndProcedure

&AtClient
Procedure DueDateOnChange(Item)
	
	// Request server operation.
	DueDateOnChangeAtServer();
	
EndProcedure

&AtServer
Procedure DueDateOnChangeAtServer()
	
	// Back-change - clear used terms.
	Object.Terms = Catalogs.PaymentTerms.EmptyRef();
	
	// Does not require standard processing.
	
EndProcedure

&AtClient
Procedure LocationOnChange(Item)
	
	// Ask user about updating the setting and update the line items accordingly.
	CommonDefaultSettingOnChange(Item, Lower(Item.Name));
	
EndProcedure

&AtClient
Procedure DeliveryDateOnChange(Item)
	
	// ???
	
	// Ask user about updating the setting and update the line items accordingly.
	//CommonDefaultSettingOnChange(Item, "delivery date");
	
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
Procedure TermsOnChange(Item)
	
	// Request server operation.
	TermsOnChangeAtServer();
	
EndProcedure

&AtServer
Procedure TermsOnChangeAtServer()
	
	// Define empty date.
	EmptyDate = '00010101';
	
	// Update due date basing on the currently selected terms.
	Object.DueDate = ?(Not Object.Terms.IsEmpty(), Object.Date + Object.Terms.Days * 60*60*24, EmptyDate);
	
	// Process settings changes.
	//DueDateOnChangeAtServer();
	
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
		
		// Clear order data on duplicate row.
		ClearFields  = New Structure("Order, OrderPrice");
		For Each ClearField In ClearFields Do
			If Not ValueIsFilled(Item.CurrentData[ObjectField.Key]) Then
				Item.CurrentData[ObjectField.Key] = Undefined;
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
	
	// Clear up order data.
	TableSectionRow.Order              = Documents.PurchaseOrder.EmptyRef();
	TableSectionRow.OrderPrice         = 0;
	
	// Reset default values.
	TableSectionRow.Location     = Object.Location;
	TableSectionRow.DeliveryDate = Object.DeliveryDate;
	TableSectionRow.Project      = Object.Project;
	TableSectionRow.Class        = Object.Class;
	
	// Assign default quantities.
	TableSectionRow.Quantity  = 0;
	TableSectionRow.Ordered   = 0;
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
	
	//// Update backorder quantity basing on document status.
	//If OrderStatusIndex = 0 Then    // OrderStatus = Enums.OrderStatuses.Open
	//	TableSectionRow.Backorder = 0;
	//	
	//ElsIf OrderStatusIndex = 1 Then // OrderStatus = Enums.OrderStatuses.Backordered
	//	If TableSectionRow.ProductTypeIndex = 0 Then
	//		// Product.Type = Enums.InventoryTypes.Inventory
	//		TableSectionRow.Backorder = Max(TableSectionRow.Quantity - TableSectionRow.Received, 0);
	//	Else 
	//		// Product.Type = Enums.InventoryTypes.NonInventory;
	//		TableSectionRow.Backorder = Max(TableSectionRow.Quantity - TableSectionRow.Invoiced, 0);
	//	EndIf;
	//	
	//ElsIf OrderStatusIndex = 2 Then // OrderStatus = Enums.OrderStatuses.Closed
	//	TableSectionRow.Backorder = 0;
	//	
	//Else
	//	TableSectionRow.Backorder = 0;
	//EndIf;
	
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

//------------------------------------------------------------------------------
// Tabular section Accounts event handlers.

&AtClient
Procedure AccountsOnChange(Item)
	
	// Row was just added and became edited.
	If IsNewRow Then
		
		// Clear used flag.
		IsNewRow = False;
		
		// Fill new row with default values.
		ObjectData  = New Structure("Project, Class");
		FillPropertyValues(ObjectData, Object);
		For Each ObjectField In ObjectData Do
			If Not ValueIsFilled(Item.CurrentData[ObjectField.Key]) Then
				Item.CurrentData[ObjectField.Key] = ObjectField.Value;
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

&AtClient
Procedure AccountsBeforeAddRow(Item, Cancel, Clone, Parent, Folder)
	
	// Set new row flag.
	If Not Cancel Then
		IsNewRow = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure AccountsOnEditEnd(Item, NewRow, CancelEdit)
	
	// Recalculation common document totals.
	RecalculateTotals();
	
EndProcedure

&AtClient
Procedure AccountsAfterDeleteRow(Item)
	
	// Recalculation common document totals.
	RecalculateTotals();
	
EndProcedure

//------------------------------------------------------------------------------
// Tabular section Accounts columns controls event handlers.

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region COMMANDS_HANDLERS

&AtClient
Procedure URLOpen(Command)
	
	// Open a new browser page and go to the passed URL.
	GotoURL(Object.URL);
	
EndProcedure

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region PRIVATE_IMPLEMENTATION

//------------------------------------------------------------------------------
// Calculate values of form object attributes.

&AtServer
// Request invoice status from database
Procedure FillInvoiceStatus()
	
	// ???
	// If Paid set then ignore other statuses?
	
	// Build invoice status presentation (depending of document state)
	If Not ValueIsFilled(Object.Ref) Then
		InvoiceStatusPresentation = String(Enums.OrderStatuses.New);
		Items.InvoiceStatusPresentation.TextColor = WebColors.DarkGreen;
		
	ElsIf Object.DeletionMark Then
		InvoiceStatusPresentation = String(Enums.OrderStatuses.Deleted);
		Items.InvoiceStatusPresentation.TextColor = WebColors.DarkGray;
		
	ElsIf Not Object.Posted Then 
		InvoiceStatusPresentation = String(Enums.OrderStatuses.Draft);
		Items.InvoiceStatusPresentation.TextColor = WebColors.DarkGray;
		
	Else // Calculate invoice status for posted invoice.
		
		// Create new query.
		Query = New Query;
		Query.SetParameter("Ref",     Object.Ref);
		Query.SetParameter("Company", Object.Company);
		Query.SetParameter("Account", Object.APAccount);
		
		// Request payable amount for the account.
		Query.Text =
			"SELECT
			|	-GeneralJournalBalance.AmountBalance AS Amount
			|FROM
			|	AccountingRegister.GeneralJournal.Balance(, Account = &Account,, ExtDimension1 = &Company AND ExtDimension2 = &Ref) AS GeneralJournalBalance";
		Selection = Query.Execute().Choose();
		
		// Fill invoice status.
		If Selection.Next() Then
			// Liabilities found.
			If Selection.Amount > 0 Then
				// Payables found.
				InvoiceStatusPresentation = String(Enums.OrderStatuses.Open);
				Items.InvoiceStatusPresentation.TextColor = WebColors.DarkRed;
				
			ElsIf Selection.Amount = 0 Then
				// Paid.
				InvoiceStatusPresentation = "Paid";
				Items.InvoiceStatusPresentation.TextColor = WebColors.DarkGreen;
				
			ElsIf Selection.Amount < 0 Then
				// Overpaid.
				InvoiceStatusPresentation = "Paid over";
				Items.InvoiceStatusPresentation.TextColor = WebColors.DarkGoldenRod;
			EndIf;
		Else
			// No liabilities.
			InvoiceStatusPresentation = "No charge";
			Items.InvoiceStatusPresentation.TextColor = WebColors.DarkGreen;
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
// Request demanded order items from database
Procedure FillBackorderQuantity()
	
	// Request ordered items quantities
	If ValueIsFilled(Object.Ref) Then
		
		//// Create new query
		//Query = New Query;
		//Query.SetParameter("Ref", Object.Ref);
		//Query.SetParameter("OrderStatus", OrderStatus);
		//
		//Query.Text = 
		//	"SELECT
		//	|	OrdersDispatched.LineNumber              AS LineNumber,
		//	//  Request dimensions
		//	|	OrdersDispatchedBalance.Product          AS Product,
		//	|	OrdersDispatchedBalance.Project          AS Project,
		//	|	OrdersDispatchedBalance.DeliveryDate     AS DeliveryDate,
		//	//  Request resources                                                                                               // ---------------------------------------
		//	|	OrdersDispatchedBalance.QuantityBalance  AS Ordered,                                                            // Backorder quantity calculation
		//	|	CASE                                                                                                            // ---------------------------------------
		//	|		WHEN &OrderStatus = VALUE(Enum.OrderStatuses.Open)        THEN 0                                            // Order status = Open:
		//	|		WHEN &OrderStatus = VALUE(Enum.OrderStatuses.Backordered) THEN                                              //   Backorder = 0
		//	|			CASE                                                                                                    // Order status = Backorder:
		//	|				WHEN OrdersDispatchedBalance.Product.Type = VALUE(Enum.InventoryTypes.Inventory) THEN               //   Inventory:
		//	|					CASE                                                                                            //     Backorder = Ordered - Received >= 0
		//	|						WHEN OrdersDispatchedBalance.QuantityBalance > OrdersDispatchedBalance.ReceivedBalance THEN //     |
		//	|							 OrdersDispatchedBalance.QuantityBalance - OrdersDispatchedBalance.ReceivedBalance      //     |
		//	|						ELSE 0 END                                                                                  //     |
		//	|				ELSE                                                                                                //   Non-inventory:
		//	|					CASE                                                                                            //     Backorder = Ordered - Invoiced >= 0
		//	|						WHEN OrdersDispatchedBalance.QuantityBalance > OrdersDispatchedBalance.InvoicedBalance THEN //     |
		//	|							 OrdersDispatchedBalance.QuantityBalance - OrdersDispatchedBalance.InvoicedBalance      //     |
		//	|						ELSE 0 END                                                                                  //     |
		//	|				END                                                                                                 //     |
		//	|		WHEN &OrderStatus = VALUE(Enum.OrderStatuses.Closed)      THEN 0                                            // Order status = Closed:
		//	|		END                                 AS Backorder,                                                                                           //   Backorder = 0
		//	|	OrdersDispatchedBalance.ReceivedBalance AS Received,
		//	|	OrdersDispatchedBalance.InvoicedBalance AS Invoiced
		//	//  Request sources
		//	|FROM
		//	|	AccumulationRegister.OrdersDispatched.Balance(,
		//	|		(Company, Order, Product, Location, DeliveryDate, Project, Class) IN
		//	|			(SELECT
		//	|				LineItems.Ref.Company,
		//	|				LineItems.Ref,
		//	|				LineItems.Product,
		//	|				LineItems.Project,
		//	|				LineItems.DeliveryDate
		//	|			FROM
		//	|				Document.PurchaseOrder.LineItems AS LineItems
		//	|			WHERE
		//	|				LineItems.Ref = &Ref)) AS OrdersDispatchedBalance
		//	|	LEFT JOIN AccumulationRegister.OrdersDispatched AS OrdersDispatched
		//	|		ON    ( OrdersDispatched.Recorder      = &Ref
		//	|			AND OrdersDispatched.Company       = OrdersDispatchedBalance.Company
		//	|			AND OrdersDispatched.Order         = OrdersDispatchedBalance.Order
		//	|			AND OrdersDispatched.Product       = OrdersDispatchedBalance.Product
		//	|			AND OrdersDispatched.Project       = OrdersDispatchedBalance.Project
		//	|			AND OrdersDispatched.DeliveryDate  = OrdersDispatchedBalance.DeliveryDate
		//	|			AND OrdersDispatched.Quantity      = OrdersDispatchedBalance.QuantityBalance)
		//	//  Request ordering
		//	|ORDER BY
		//	|	OrdersDispatched.LineNumber";
		//Selection = Query.Execute().Choose();
		//
		//// Fill ordered items quantities
		//SearchRec = New Structure("LineNumber, Product, Project, DeliveryDate, Quantity");
		//While Selection.Next() Do
		//	
		//	// Search for appropriate line in tabular section of order
		//	FillPropertyValues(SearchRec, Selection);
		//	FoundLineItems = Object.LineItems.FindRows(SearchRec);
		//	
		//	// Fill quantities in tabular section
		//	If FoundLineItems.Count() > 0 Then
		//		FillPropertyValues(FoundLineItems[0], Selection, "Backorder, Received, Invoiced");
		//	EndIf;
		//	
		//EndDo;
		
	EndIf;
	
EndProcedure

&AtServer
// Request and fill indexes of product type (required to calculate backorder property)
Procedure FillProductTypes()
	
	// Fill line item's product types.
	If ValueIsFilled(Object.Ref) Then
		
		// Create new query.
		Query = New Query;
		Query.SetParameter("Ref", Object.Ref);
		
		Query.Text =
		"SELECT
		|	PurchaseInvoiceLineItems.LineNumber         AS LineNumber,
		|	PurchaseInvoiceLineItems.Product.Type.Order AS ProductTypeIndex
		|FROM
		|	Document.PurchaseInvoice.LineItems AS PurchaseInvoiceLineItems
		|WHERE
		|	PurchaseInvoiceLineItems.Ref = &Ref
		|ORDER BY
		|	LineNumber";
		Selection = Query.Execute().Choose();
		
		// Fill items product types.
		While Selection.Next() Do
			// Search for appropriate line in tabular section of invoice.
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
	Object.DocumentTotal   = Object.LineItems.Total("LineTotal") + Object.Accounts.Total("Amount") + ?(Object.PriceIncludesVAT, 0, Object.VATTotal);
	Object.DocumentTotalRC = Round(Object.DocumentTotal * Object.ExchangeRate, 2);
	
EndProcedure

//------------------------------------------------------------------------------
// Replacemant for metadata properties on client.

&AtClient
// Returns fields structure of LineItems form control.
Function GetLineItemsRowStructure()
	
	// Define control row fields.
	Return New Structure("Product, ProductDescription, ProductTypeIndex, Quantity, UM, Ordered, Received, Backorder, Invoiced, OrderPrice, Price, LineTotal, VATCode, VAT, Location, DeliveryDate, Order, Project, Class");
	
EndFunction

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region _TEMP


&AtServer
// Check presence of non-closed orders for the passed company
Function HasNonClosedOrders(Company)
	
	// Create new query
	Query = New Query;
	Query.SetParameter("Company", Company);
	
	QueryText = 
		"SELECT
		|	PurchaseOrder.Ref
		|FROM
		|	Document.PurchaseOrder AS PurchaseOrder
		|	LEFT JOIN InformationRegister.OrdersStatuses.SliceLast AS OrdersStatuses
		|		ON PurchaseOrder.Ref = OrdersStatuses.Order
		|WHERE
		|	PurchaseOrder.Company = &Company
		|AND
		|	CASE
		|		WHEN PurchaseOrder.DeletionMark THEN
		|			 VALUE(Enum.OrderStatuses.Deleted)
		|		WHEN NOT PurchaseOrder.Posted THEN
		|			 VALUE(Enum.OrderStatuses.Draft)
		|		WHEN OrdersStatuses.Status IS NULL THEN
		|			 VALUE(Enum.OrderStatuses.Open)
		|		WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.EmptyRef) THEN
		|			 VALUE(Enum.OrderStatuses.Open)
		|		ELSE
		|			 OrdersStatuses.Status
		|	END IN (VALUE(Enum.OrderStatuses.Open), VALUE(Enum.OrderStatuses.Backordered))";
	Query.Text  = QueryText;
	
	// Returns true if there are open or backordered orders
	Return Not Query.Execute().IsEmpty();
	
EndFunction

&AtServer
// Returns array of Order Statuses indicating non-closed orders
Function GetNonClosedOrderStatuses()
	
	// Define all non-closed statuses array
	OrderStatuses  = New Array;
	OrderStatuses.Add(Enums.OrderStatuses.Open);
	OrderStatuses.Add(Enums.OrderStatuses.Backordered);
	
	// Return filled array
	Return OrderStatuses;
	
EndFunction

&AtServer
// Fills document on the base of passed array of orders
// Returns flag o successfull filing
Function FillDocumentWithSelectedOrders(SelectedOrders)
	
	// Fill table on the base of selected orders
	If SelectedOrders <> Undefined Then
		
		// Fill object by orders
		DocObject = FormAttributeToValue("Object");
		DocObject.Fill(SelectedOrders);
		
		// Return filled object to form
		ValueToFormAttribute(DocObject, "Object");
		
		// Return filling success
		Return True;
	Else
		// Order wasn't selected: Clear foreign orders
		If  (Object.LineItems.Count() > 0)
			// Will assume that all previosly selected orders are filled correctly, and belong to the same company
		And (Not Object.LineItems[0].Order.Company = Object.Company) Then
			// Clear existing dataset
			Object.LineItems.Clear();
		EndIf;
		
		// Return fail (selection cancelled)
		Return False;
	EndIf;
	
EndFunction

&AtClient
// Processing of selected orders.
Procedure OrderSelection(Result, Parameters) Export
	
	// Process selection result.
	If Not Result = Undefined Then
		
		// Do fill document from selected orders.
		FillDocumentWithSelectedOrders(Result);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure PayInvoice(Command)
	PayInvoiceAtServer();
EndProcedure

&AtServer
Procedure PayInvoiceAtServer()
	
	If Object.Posted = False Then
		Message("An invoice payment cannot be created for the invoice because it has not yet been created(posted)");
	Else
	
		NewCashReceipt = Documents.InvoicePayment.CreateDocument();
		NewCashReceipt.Company = Object.Company;
		NewCashReceipt.Date = CurrentDate();
		NewCashReceipt.CompanyCode = Object.CompanyCode;
		NewCashReceipt.Currency = Object.Currency;
		NewCashReceipt.DocumentTotal = Object.DocumentTotalRC;
		NewCashReceipt.DocumentTotalRC = Object.DocumentTotalRC;
		NewCashReceipt.BankAccount = Constants.BankAccount.Get();
		NewCashReceipt.PaymentMethod = Catalogs.PaymentMethods.Check;
		//NewCashReceipt.Number = 
		NewLine = NewCashReceipt.LineItems.Add();
		NewLine.Check = True;
		NewLine.Document = Object.Ref;
		NewLine.Balance = Object.DocumentTotalRC;
		NewLine.Payment = Object.DocumentTotalRC;
		        
		NewCashReceipt.Write(DocumentWriteMode.Posting);
		CommandBar.ChildItems.FormPayInvoice.Enabled = False;
		PaidInvoiceCheck = True;
		
		Message("Am invoice payment has been created for " + Object.Ref);
		
	Endif;

EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// Finds an invoice with the same number, if so, do not allow
	If Not IsBlankString(Object.Number) Then
		QueryText2 = "
					|SELECT
		            |	PurchaseInvoice.Ref
		            |FROM
		            |	Document.PurchaseInvoice AS PurchaseInvoice
		            |WHERE
		            |	PurchaseInvoice.Ref <> &Ref
		            |	AND PurchaseInvoice.Company = &Company
		            |	AND PurchaseInvoice.Number = &Number";
		Query = New Query(QueryText2);
		Query.SetParameter("Ref", Object.Ref);
		Query.SetParameter("Company", Object.Company);
		Query.SetParameter("Number", Object.Number);
		QueryResult = Query.Execute();
		
		If QueryResult.IsEmpty() Then
		Else
			Message("Bill # for this vendor already exists");
			Cancel = True;
		Endif;
	EndIf;
	
	
	If Object.LineItems.Count() = 0 AND Object.Accounts.Count() = 0 Then
		Message("Cannot post when there are no expenses or items.");
		Cancel = True;
	EndIf;

	
	//------------------------------------------------------------------------------
	// 1. Correct the invoice date according to the orders dates.
	
	// Request orders dates.
	QueryText = "
		|SELECT TOP 1
		|	PurchaseOrder.Date AS Date,
		|	PurchaseOrder.Ref AS Ref
		|FROM
		|	Document.PurchaseOrder AS PurchaseOrder
		|WHERE
		|	PurchaseOrder.Ref IN (&Orders)
		|ORDER BY
		|	PurchaseOrder.Date DESC";
	Query = New Query(QueryText);
	Query.SetParameter("Orders", CurrentObject.LineItems.UnloadColumn("Order"));
	QueryResult = Query.Execute();
	
	// Compare letest order date with current invoice date.
	If Not QueryResult.IsEmpty() Then
		
		// Check latest order date.
		LatestOrder  = QueryResult.Unload()[0];
		If (Not LatestOrder.Date = Null) And (LatestOrder.Date >= CurrentObject.Date) Then
			
			// Invoice writing before the order.
			If BegOfDay(LatestOrder.Date) = BegOfDay(CurrentObject.Date) Then
				// The date is the same - simply correct the document time (it will not be shown to the user).
				CurrentObject.Date = LatestOrder.Date + 1;
				
			Else
				// The invoice writing too early.
				CurrentObjectPresentation = StringFunctionsClientServer.SubstituteParametersInString(
				        NStr("en = '%1 %2 from %3'"), CurrentObject.Metadata().Synonym, CurrentObject.Number, Format(CurrentObject.Date, "DLF=D"));
				Message(StringFunctionsClientServer.SubstituteParametersInString(
				        NStr("en = 'The %1 can not be written before the %2'"), CurrentObjectPresentation, LatestOrder.Ref));
				Cancel = True;
			EndIf;
			
		EndIf;
	EndIf;
		
EndProcedure

&AtClient
Procedure AccountsAccountOnChange(Item)
	
	TabularPartRow = Items.Accounts.CurrentData;
	TabularPartRow.AccountDescription = CommonUse.GetAttributeValue
		(TabularPartRow.Account, "Description");
	
EndProcedure

&AtClient
Procedure BegBalOnChange(Item)
	
	If Object.BegBal = True Then
		Items.DocumentTotalRC.ReadOnly = False;
		Items.DocumentTotal.ReadOnly = False;
	ElsIf Object.BegBal = False Then
		Items.DocumentTotalRC.ReadOnly = True;
		Items.DocumentTotal.ReadOnly = True;
	EndIf;

EndProcedure

#EndRegion
