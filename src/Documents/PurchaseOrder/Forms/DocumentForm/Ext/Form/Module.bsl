
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
	
	If Object.Ref.IsEmpty() Then
		FirstNumber = Object.Number;
	EndIf;
	
	If Parameters.Property("Company") And Parameters.Company.Vendor And Object.Ref.IsEmpty() Then
		Object.Company = Parameters.Company;
		AutoCompanyOnChange = True;
	EndIf;
	
	//------------------------------------------------------------------------------
	// 1. Form attributes initialization.
	
	// Set LineItems editing flag.
	IsNewRow     = False;
	
	// Fill object attributes cache.
	DeliveryDate = Object.DeliveryDate;
	Location     = Object.Location;
	Project      = Object.Project;
	Class        = Object.Class;
	Date         = Object.Date;
	Company      = Object.Company;
	
	//------------------------------------------------------------------------------
	// 2. Calculate values of form object attributes.
	
	// Request and fill order status.
	FillOrderStatusAtServer();
	
	// Request and fill ordered items from database.
	FillBackorderQuantityAtServer();
	
	//------------------------------------------------------------------------------
	// 3. Set custom controls presentation.
	
	// Set proper company field presentation.
	VendorName                      = GeneralFunctionsReusable.GetVendorName();
	CustomerName                    = GeneralFunctionsReusable.GetCustomerName();
	Items.Company.Title             = VendorName;
	Items.Company.ToolTip           = StringFunctionsClientServer.SubstituteParametersInString(NStr("en = '%1 name'"),          VendorName);
	Items.CompanyAddress.ToolTip    = StringFunctionsClientServer.SubstituteParametersInString(NStr("en = '%1 address'"),       VendorName);
	Items.DropshipCompany.Title     = StringFunctionsClientServer.SubstituteParametersInString(NStr("en = 'Dropship %1'"),      Lower(CustomerName));
	Items.DropshipCompany.ToolTip   = StringFunctionsClientServer.SubstituteParametersInString(NStr("en = 'Dropship %1 name'"), Lower(CustomerName));
	Items.DropshipShipTo.ToolTip    = StringFunctionsClientServer.SubstituteParametersInString(NStr("en = 'Dropship %1 shipping address'"), Lower(CustomerName));
	Items.DropshipBillTo.ToolTip    = StringFunctionsClientServer.SubstituteParametersInString(NStr("en = 'Dropship %1 billing address'"),  Lower(CustomerName));
	Items.DropshipConfirmTo.ToolTip = StringFunctionsClientServer.SubstituteParametersInString(NStr("en = 'Dropship %1 confirm address'"),  Lower(CustomerName));
	Items.DropshipRefNum.ToolTip    = StringFunctionsClientServer.SubstituteParametersInString(NStr("en = 'Dropship %1 purchase order number /
	                                                                                                      |Reference number'"), Lower(CustomerName));
	
	// Update quantities presentation.
	QuantityPrecision = GeneralFunctionsReusable.DefaultQuantityPrecision();
	QuantityFormat    = GeneralFunctionsReusable.DefaultQuantityFormat();
	Items.LineItemsQuantity.EditFormat  = QuantityFormat;
	Items.LineItemsQuantity.Format      = QuantityFormat;
	Items.LineItemsReceived.EditFormat  = QuantityFormat;
	Items.LineItemsReceived.Format      = QuantityFormat;
	Items.LineItemsInvoiced.EditFormat  = QuantityFormat;
	Items.LineItemsInvoiced.Format      = QuantityFormat;
	Items.LineItemsBackorder.EditFormat = QuantityFormat;
	Items.LineItemsBackorder.Format     = QuantityFormat;
	
	// Update prices presentation.
	PriceFormat = GeneralFunctionsReusable.DefaultPriceFormat();
	Items.LineItemsPrice.EditFormat  = PriceFormat;
	Items.LineItemsPrice.Format      = PriceFormat;
	
	// Update visibility of controls depending on functional options.
	If Not GeneralFunctionsReusable.FunctionalOptionValue("MultiCurrency") Then
		Items.FCYGroup.Visible    = False;
	EndIf;
	
	// Set currency title.
	DefaultCurrencySymbol    = GeneralFunctionsReusable.DefaultCurrencySymbol();
	ForeignCurrencySymbol    = Object.Currency.Symbol;
	Items.ExchangeRate.Title = DefaultCurrencySymbol + "/1" + ForeignCurrencySymbol;
	Items.FCYCurrency.Title  = ForeignCurrencySymbol;
	Items.RCCurrency.Title   = DefaultCurrencySymbol;
	
	// Define point in time for requesting the balances.
	If Object.Ref.IsEmpty() Then
		// The new document.
		If ValueIsFilled(Object.Date) And BegOfDay(Object.Date) < BegOfDay(CurrentSessionDate()) Then
			// New document in back-date.
			PointInTime = New Boundary(EndOfDay(Object.Date), BoundaryType.Including);
		Else
			// New actual document.
			PointInTime = Undefined;
		EndIf;
	Else
		// Document was already saved (but date can actually be changed).
		PointInTime = New Boundary(New PointInTime(Object.Date, Object.Ref), BoundaryType.Including);
	EndIf;
	
	If Object.Ref.IsEmpty() Then
		Object.EmailNote = Constants.PurOrderFooter.Get();
	EndIf;
	
EndProcedure

// -> CODE REVIEW
&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	// Closing period
	If PeriodClosingServerCall.DocumentPeriodIsClosed(Object.Ref, Object.Date) Then
		Cancel = Not PeriodClosingServerCall.DocumentWritePermitted(WriteParameters);
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

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	//Period closing
	If PeriodClosingServerCall.DocumentPeriodIsClosed(CurrentObject.Ref, CurrentObject.Date) Then
		PermitWrite = PeriodClosingServerCall.DocumentWritePermitted(WriteParameters);
		CurrentObject.AdditionalProperties.Insert("PermitWrite", PermitWrite);
	EndIf;
	
EndProcedure
// <- CODE REVIEW

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	If FirstNumber <> "" Then
		
		Numerator = Catalogs.DocumentNumbering.PurchaseOrder.GetObject();
		NextNumber = GeneralFunctions.Increment(Numerator.Number);
		If FirstNumber = NextNumber And NextNumber = Object.Number Then
			Numerator.Number = FirstNumber;
			Numerator.Write();
		EndIf;
		
		FirstNumber = "";
	EndIf;
	
	// Update point in time for requesting the balances.
	If Object.Ref.IsEmpty() Then
		// The new document.
		If BegOfDay(Object.Date) < BegOfDay(CurrentSessionDate()) Then
			// New document in back-date.
			PointInTime = New Boundary(EndOfDay(Object.Date), BoundaryType.Including);
		Else
			// New actual document.
			PointInTime = Undefined;
		EndIf;
	Else
		// Document was already saved (but date can actually be changed).
		PointInTime = New Boundary(New PointInTime(Object.Date, Object.Ref), BoundaryType.Including);
	EndIf;
	
	//------------------------------------------------------------------------------
	// Recalculate values of form object attributes.
	
	// Request and fill order status from database.
	FillOrderStatusAtServer();
	
	// Request and fill ordered items from database.
	FillBackorderQuantityAtServer();
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("UpdatePOInformation", Object.BaseDocument);
	
EndProcedure

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region CONTROLS_EVENTS_HANDLERS

&AtClient
Procedure DateOnChange(Item)
	
	// Ask user about updating the setting and update the line items accordingly.
	CommonDefaultSettingOnChange(Item, "cost");
	
EndProcedure

&AtServer
Procedure DateOnChangeAtServer()
	
	// Update point in time for requesting the balances.
	If Object.Ref.IsEmpty() Then
		// The new document.
		If BegOfDay(Object.Date) < BegOfDay(CurrentSessionDate()) Then
			// New document in back-date.
			PointInTime = New Boundary(EndOfDay(Object.Date), BoundaryType.Including);
		Else
			// New actual document.
			PointInTime = Undefined;
		EndIf;
	Else
		// Document was already saved (but date can actually be changed).
		PointInTime = New Boundary(New PointInTime(Object.Date, Object.Ref), BoundaryType.Including);
	EndIf;
	
	// Request exchange rate on the new date.
	Object.ExchangeRate = GeneralFunctions.GetExchangeRate(Object.Date, Object.Currency);
	
	// Process settings changes.
	ExchangeRateOnChangeAtServer();
	
EndProcedure

&AtClient
Procedure CompanyOnChange(Item)
	
	// Ask user about updating the setting and update the line items accordingly.
	CommonDefaultSettingOnChange(Item, "cost");
	
	CompanyOnChangeAtServer();
	
EndProcedure

&AtServer
Procedure CompanyOnChangeAtServer()
	
	// Reset company adresses (if company was changed).
	FillCompanyAddressesAtServer(Object.Company, , Object.CompanyAddress);
	
	// Request company default settings.
	Object.Currency    = Object.Company.DefaultCurrency;
	
	// Process settings changes.
	CurrencyOnChangeAtServer();
	
EndProcedure

&AtClient
Procedure DropshipCompanyOnChange(Item)
	
	// Request server operation.
	DropshipCompanyOnChangeAtServer();
	
EndProcedure

&AtServer
Procedure DropshipCompanyOnChangeAtServer()
	
	// Reset company adresses (if company was changed).
	FillCompanyAddressesAtServer(Object.DropshipCompany, Object.DropshipShipTo, Object.DropshipBillTo, Object.DropshipConfirmTo);
	
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

&AtClient
Procedure UseIROnChange(Item)

	If (Not Object.Ref.IsEmpty()) AND (DocumentUsed(Object.Ref)) Then
		
		Object.UseIR = Not Object.UseIR; 
		
		UM = New UserMessage;
		UM.Text = NStr("en = 'You cannot change the attribute ""Use Item receipt"" because this document is used in other documents!'");
		UM.Field = "Object.UseIR";
		UM.Message();
		
	EndIf;
	
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
		DefaultSettingOnChangeAtServer(DefaultSetting, False);
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
		DefaultSettingOnChangeAtServer(DefaultSetting, True);
		
	ElsIf ChoiceResult = DialogReturnCode.No Then
		// Keep new setting, do not update line items.
		ThisForm[DefaultSetting] = Object[DefaultSetting];
		DefaultSettingOnChangeAtServer(DefaultSetting, False);
		
	Else
		// Restore previously entered setting.
		Object[DefaultSetting] = ThisForm[DefaultSetting];
	EndIf;
	
EndProcedure

&AtServer
Procedure DefaultSettingOnChangeAtServer(DefaultSetting, RecalculateLineItems)
	
	// Process attribute change.
	If Object.Ref.Metadata().TabularSections.LineItems.Attributes.Find(DefaultSetting) <> Undefined Then
		// Process attributes by the matching name to the header's default values.
		
		// Process line items change.
		If RecalculateLineItems Then
			// Apply default to all of the items.
			For Each Row In Object.LineItems Do
				Row[DefaultSetting] = Object[DefaultSetting];
			EndDo;
		EndIf;
		
	// Process attributes by the name.
	ElsIf DefaultSetting = "Date" Then
		
		// Process the attribute change in any case.
		DateOnChangeAtServer();
		
		// Process line items change.
		If RecalculateLineItems Then
			// Recalculate retail price.
			For Each Row In Object.LineItems Do
				Row.PriceUnits = Round(GeneralFunctions.ProductLastCost(Row.Product, PointInTime) *
				                 ?(Row.Unit.Factor > 0, Row.Unit.Factor, 1) /
				                 ?(Object.ExchangeRate > 0, Object.ExchangeRate, 1), GeneralFunctionsReusable.PricePrecisionForOneItem(Row.Product));
				LineItemsPriceOnChangeAtServer(Row);
			EndDo;
			RecalculateTotalsAtServer();
		EndIf;
		
	Else
		// Process other attributes.
	EndIf;
	
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
	ProductProperties = CommonUse.GetAttributeValues(TableSectionRow.Product,   New Structure("Description, UnitSet"));
	UnitSetProperties = CommonUse.GetAttributeValues(ProductProperties.UnitSet, New Structure("DefaultPurchaseUnit"));
	TableSectionRow.ProductDescription = ProductProperties.Description;
	TableSectionRow.UnitSet            = ProductProperties.UnitSet;
	TableSectionRow.Unit               = UnitSetProperties.DefaultPurchaseUnit;
	//TableSectionRow.UM                 = UnitSetProperties.UM;
	TableSectionRow.PriceUnits         = Round(GeneralFunctions.ProductLastCost(TableSectionRow.Product, PointInTime) *
	                                     ?(TableSectionRow.Unit.Factor > 0, TableSectionRow.Unit.Factor, 1) /
	                                     ?(Object.ExchangeRate > 0, Object.ExchangeRate, 1), GeneralFunctionsReusable.PricePrecisionForOneItem(TableSectionRow.Product));
										 
	// Reset default values.
	FillPropertyValues(TableSectionRow, Object, "Location, DeliveryDate, Project, Class");
	
	// Assign default quantities.
	TableSectionRow.QtyUnits  = 0;
	TableSectionRow.QtyUM     = 0;
	TableSectionRow.Backorder = 0;
	TableSectionRow.Received  = 0;
	TableSectionRow.Invoiced  = 0;
	
	// Calculate totals by line.
	TableSectionRow.LineTotal = 0;
	
EndProcedure

&AtClient
Procedure LineItemsUnitOnChange(Item)
	
	// Fill line data for editing.
	TableSectionRow = GetLineItemsRowStructure();
	FillPropertyValues(TableSectionRow, Items.LineItems.CurrentData);
	
	// Request server operation.
	LineItemsUnitOnChangeAtServer(TableSectionRow);
	
	// Load processed data back.
	FillPropertyValues(Items.LineItems.CurrentData, TableSectionRow);
	
	// Refresh totals cache.
	RecalculateTotals();
	
EndProcedure

&AtServer
Procedure LineItemsUnitOnChangeAtServer(TableSectionRow)
	
	// Calculate new unit price.
	TableSectionRow.PriceUnits = Round(GeneralFunctions.ProductLastCost(TableSectionRow.Product, PointInTime) *
	                             ?(TableSectionRow.Unit.Factor > 0, TableSectionRow.Unit.Factor, 1) /
	                             ?(Object.ExchangeRate > 0, Object.ExchangeRate, 1), GeneralFunctionsReusable.PricePrecisionForOneItem(TableSectionRow.Product));
								 
	// Process settings changes.
	LineItemsQuantityOnChangeAtServer(TableSectionRow);
	
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
			TableSectionRow.Backorder = Max(TableSectionRow.QtyUnits - TableSectionRow.Received, 0);
		Else // TableSectionRow.Product.Type = Enums.InventoryTypes.NonInventory;
			TableSectionRow.Backorder = Max(TableSectionRow.QtyUnits - TableSectionRow.Invoiced, 0);
		EndIf;
		
	ElsIf OrderStatus = Enums.OrderStatuses.Closed Then
		TableSectionRow.Backorder = 0;
		
	Else
		TableSectionRow.Backorder = 0;
	EndIf;
	
	// Calculate total by line.
	TableSectionRow.LineTotal = Round(Round(TableSectionRow.QtyUnits, QuantityPrecision) * Round(TableSectionRow.PriceUnits, GeneralFunctionsReusable.PricePrecisionForOneItem(TableSectionRow.Product)), 2);
	
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
	
	// Rounds price of product. 
	TableSectionRow.PriceUnits = Round(TableSectionRow.PriceUnits, GeneralFunctionsReusable.PricePrecisionForOneItem(TableSectionRow.Product));
	
	// Calculate total by line.
	TableSectionRow.LineTotal = Round(Round(TableSectionRow.QtyUnits, QuantityPrecision) * TableSectionRow.PriceUnits, 2);
	
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
	
	// Back-step price calculation with totals priority (interactive change only).
	TableSectionRow.PriceUnits = ?(Round(TableSectionRow.QtyUnits, QuantityPrecision) > 0,
	                               Round(TableSectionRow.LineTotal / Round(TableSectionRow.QtyUnits, QuantityPrecision), GeneralFunctionsReusable.PricePrecisionForOneItem(TableSectionRow.Product)), 0);
								   
	// Load processed data back.
	FillPropertyValues(Items.LineItems.CurrentData, TableSectionRow);
	
	// Refresh totals cache.
	RecalculateTotals();
	
EndProcedure

&AtServer
Procedure LineItemsLineTotalOnChangeAtServer(TableSectionRow)
	
	// Back-calculation of quantity in base units.
	TableSectionRow.QtyUM      = Round(Round(TableSectionRow.QtyUnits, QuantityPrecision) *
	                             ?(TableSectionRow.Unit.Factor > 0, TableSectionRow.Unit.Factor, 1), QuantityPrecision);
	
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
	
	// Fill extended order status presentation (depending of document state).
	If Not ValueIsFilled(Object.Ref) Then
		OrderStatusPresentation = String(Enums.OrderStatuses.New);
		Items.OrderStatusPresentation.TextColor = WebColors.DarkGray;
		
	ElsIf Object.DeletionMark Then
		OrderStatusPresentation = String(Enums.OrderStatuses.Deleted);
		Items.OrderStatusPresentation.TextColor = WebColors.DarkGray;
		
	ElsIf Not Object.Posted Then
		OrderStatusPresentation = String(Enums.OrderStatuses.Draft);
		Items.OrderStatusPresentation.TextColor = WebColors.DarkGray;
		
	Else
		OrderStatusPresentation = String(OrderStatus);
		If OrderStatus = Enums.OrderStatuses.Closed Then 
			ThisForm.Items.OrderStatusPresentation.TextColor = WebColors.DarkGreen;
		ElsIf OrderStatus = Enums.OrderStatuses.Backordered Then 
			ThisForm.Items.OrderStatusPresentation.TextColor = WebColors.DarkGoldenRod;
		ElsIf OrderStatus = Enums.OrderStatuses.Open Then
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
			|	OrdersDispatchedBalance.Product          AS Product,
			|	OrdersDispatchedBalance.Unit             AS Unit,
			|	OrdersDispatchedBalance.Location         AS Location,
			|	OrdersDispatchedBalance.DeliveryDate     AS DeliveryDate,
			|	OrdersDispatchedBalance.Project          AS Project,
			|	OrdersDispatchedBalance.Class            AS Class,
			//  Request resources                                                                                               // ---------------------------------------
			|	OrdersDispatchedBalance.QuantityBalance  AS QtyUnits,                                                           // Backorder quantity calculation
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
			|		END                                  AS Backorder,                                                          //   Backorder = 0
			|	OrdersDispatchedBalance.ReceivedBalance  AS Received,
			|	OrdersDispatchedBalance.InvoicedBalance  AS Invoiced
			//  Request sources
			|FROM
			|	Document.PurchaseOrder.LineItems         AS LineItems
			|	LEFT JOIN AccumulationRegister.OrdersDispatched.Balance(,Order = &Ref)
			|		                                     AS OrdersDispatchedBalance
			|		ON    ( LineItems.Ref.Company         = OrdersDispatchedBalance.Company
			|			AND LineItems.Ref                 = OrdersDispatchedBalance.Order
			|			AND LineItems.Product             = OrdersDispatchedBalance.Product
			|			AND LineItems.Unit                = OrdersDispatchedBalance.Unit
			|			AND LineItems.Location            = OrdersDispatchedBalance.Location
			|			AND LineItems.DeliveryDate        = OrdersDispatchedBalance.DeliveryDate
			|			AND LineItems.Project             = OrdersDispatchedBalance.Project
			|			AND LineItems.Class               = OrdersDispatchedBalance.Class
			|			AND LineItems.QtyUnits            = OrdersDispatchedBalance.QuantityBalance)
			//  Request filtering
			|WHERE
			|	LineItems.Ref = &Ref
			//  Request ordering
			|ORDER BY
			|	LineItems.LineNumber";
		Selection = Query.Execute().Select();
		
		// Fill ordered items quantities
		SearchRec = New Structure("LineNumber, Product, Unit, Location, DeliveryDate, Project, Class, QtyUnits");
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
// Request and fill company addresses used for proper goods delivery.
Procedure FillCompanyAddressesAtServer(Company, ShipTo = Undefined, BillTo, ConfirmTo = Undefined);
	
	// Check if company changed and addresses are required to be refilled.
	If Not ValueIsFilled(BillTo)    Or BillTo.Owner    <> Company
	Or Not ValueIsFilled(ShipTo)    Or ShipTo.Owner    <> Company
	Or Not ValueIsFilled(ConfirmTo) Or ConfirmTo.Owner <> Company Then
		
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
		ConfirmTo      = Catalogs.Addresses.EmptyRef();
	EndIf;
	
EndProcedure

//------------------------------------------------------------------------------
// Calculate totals and fill object attributes.

&AtClient
// The procedure recalculates the document's totals.
Procedure RecalculateTotals()
	
	// Calculate document totals.
	DocumentTotal = 0;
	For Each Row In Object.LineItems Do
		DocumentTotal = DocumentTotal + Row.LineTotal;
	EndDo;
	
	// Assign totals to the object fields.
	Object.DocumentTotal   = DocumentTotal;
	Object.DocumentTotalRC = Round(Object.DocumentTotal * Object.ExchangeRate, 2);
	
EndProcedure

&AtServer
// The procedure recalculates the document's totals.
Procedure RecalculateTotalsAtServer()
	
	// Calculate document totals.
	Object.DocumentTotal   = Object.LineItems.Total("LineTotal");
	Object.DocumentTotalRC = Round(Object.DocumentTotal * Object.ExchangeRate, 2);
	
EndProcedure

//------------------------------------------------------------------------------
// Replacemant for metadata properties on client.

&AtClient
// Returns fields structure of LineItems form control.
Function GetLineItemsRowStructure()
	
	// Define control row fields.
	Return New Structure("LineNumber, Product, ProductDescription, UnitSet, QtyUnits, Unit, QtyUM, UM, Backorder, PriceUnits, LineTotal, Location, DeliveryDate, Project, Class, Received, Invoiced");
	
EndFunction

&AtServerNoContext
Function DocumentUsed(Ref)

	Query = New Query;
	Query.Text = 
		"SELECT
		|	ItemReceiptLineItems.Ref
		|INTO TemporaryTable
		|FROM
		|	Document.ItemReceipt.LineItems AS ItemReceiptLineItems
		|WHERE
		|	ItemReceiptLineItems.Order = &Order
		|
		|UNION ALL
		|
		|SELECT
		|	PurchaseInvoiceLineItems.Ref
		|FROM
		|	Document.PurchaseInvoice.LineItems AS PurchaseInvoiceLineItems
		|WHERE
		|	PurchaseInvoiceLineItems.Order = &Order
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TemporaryTable.Ref
		|FROM
		|	TemporaryTable AS TemporaryTable
		|
		|GROUP BY
		|	TemporaryTable.Ref";
		
	Query.SetParameter("Order", Ref); 

	Return Not Query.Execute().IsEmpty();
	
EndFunction


// -> CODE REVIEW
&AtClient
Procedure OnOpen(Cancel)
	
	AttachIdleHandler("AfterOpen", 0.1, True);
	
EndProcedure

&AtClient
Procedure AfterOpen()
	
	ThisForm.Activate();
	
	If ThisForm.IsInputAvailable() Then
		///////////////////////////////////////////////
		DetachIdleHandler("AfterOpen");
		
		If AutoCompanyOnChange Then
			CompanyOnChange(Items.Company);
		EndIf;
		///////////////////////////////////////////////
	Else
		AttachIdleHandler("AfterOpen", 0.1, True);
	EndIf;
	
EndProcedure

&AtServer
Function IsPosted()
	Return Object.Ref.Posted;
EndFunction
// <- CODE REVIEW

#EndRegion
