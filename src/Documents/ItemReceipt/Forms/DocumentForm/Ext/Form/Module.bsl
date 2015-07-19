
////////////////////////////////////////////////////////////////////////////////
// Item receipt: Document form
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
		OpenOrdersSelectionForm = True; 
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
	Items.Company.Title             = VendorName;
	Items.Company.ToolTip           = StringFunctionsClientServer.SubstituteParametersInString(NStr("en = '%1 name'"),    VendorName);
	Items.CompanyAddress.ToolTip    = StringFunctionsClientServer.SubstituteParametersInString(NStr("en = '%1 address'"), VendorName);
	
	// Update quantities presentation.
	QuantityPrecision = GeneralFunctionsReusable.DefaultQuantityPrecision();
	QuantityFormat    = GeneralFunctionsReusable.DefaultQuantityFormat();
	Items.LineItemsQuantity.EditFormat  = QuantityFormat;
	Items.LineItemsQuantity.Format      = QuantityFormat;
	Items.LineItemsInvoiced.EditFormat  = QuantityFormat;
	Items.LineItemsInvoiced.Format      = QuantityFormat;
	
	// Update prices presentation.
	PriceFormat = GeneralFunctionsReusable.DefaultPriceFormat();
	Items.LineItemsPrice.EditFormat      = PriceFormat;
	Items.LineItemsPrice.Format          = PriceFormat;
	
	// Set lots and serial numbers visibility.
	Items.LineItemsLot.Visible           = False;
	Items.LineItemsSerialNumbers.Visible = False;
	For Each Row In Object.LineItems Do
		// Make lots & serial numbers columns visible.
		LotsSerialNumbers.UpdateLotsSerialNumbersVisibility(Row.Product, Items, 0, Row.UseLotsSerials);
		// Fill lot owner.
		LotsSerialNumbers.FillLotOwner(Row.Product, Row.LotOwner);
		// Load serial numbers.
		LotsSerialNumbers.FillSerialNumbers(Object.SerialNumbers, Row.Product, 0, Row.LineID, Row.SerialNumbers);
	EndDo;
	
	// Update visibility of controls depending on functional options.
	If Not GeneralFunctionsReusable.FunctionalOptionValue("MultiCurrency") Then
		Items.FCYGroup.Visible    = False;
	EndIf;
	
	// Set currency title.
	DefaultCurrencySymbol          = GeneralFunctionsReusable.DefaultCurrencySymbol();
	ForeignCurrencySymbol          = Object.Currency.Symbol;
	Items.ExchangeRate.Title       = DefaultCurrencySymbol + "/1" + ForeignCurrencySymbol;
	Items.FCYCurrency.Title        = ForeignCurrencySymbol;
	Items.RCCurrency.Title         = DefaultCurrencySymbol;
	
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
	
EndProcedure

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
		
		If OpenOrdersSelectionForm Then
			CompanyOnChange(Items.Company);
		EndIf;
		///////////////////////////////////////////////
	Else
		AttachIdleHandler("AfterOpen", 0.1, True);
	EndIf;	
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	//Closing period
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
	
	// Finds an invoice with the same number, if so, do not allow.
	If Not IsBlankString(Object.Number) Then
		QueryText2 = "SELECT
		             |	ItemReceipt.Ref
		             |FROM
		             |	Document.ItemReceipt AS ItemReceipt
		             |WHERE
		             |	ItemReceipt.Ref <> &Ref
		             |	AND ItemReceipt.Company = &Company
		             |	AND ItemReceipt.Number = &Number";
		Query = New Query(QueryText2);
		Query.SetParameter("Ref", Object.Ref);
		Query.SetParameter("Company", Object.Company);
		Query.SetParameter("Number", Object.Number);
		QueryResult = Query.Execute();
		
		If QueryResult.IsEmpty() Then
		Else
			Message("Item receipt # for this vendor already exists");
			Cancel = True;
		Endif;
	EndIf;
	
	// Check empty bill.
	If Object.LineItems.Count() = 0 Then
		Message("Cannot post when there are no items.");
		Cancel = True;
	EndIf;
	
	//------------------------------------------------------------------------------
	// 1. Correct the receipt date according to the orders dates.
	
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
	
	// Compare letest order date with current receipt date.
	If Not QueryResult.IsEmpty() Then
		
		// Check latest order date.
		LatestOrder  = QueryResult.Unload()[0];
		If (Not LatestOrder.Date = Null) And (LatestOrder.Date >= CurrentObject.Date) Then
			
			// Receipt writing before the order.
			If BegOfDay(LatestOrder.Date) = BegOfDay(CurrentObject.Date) Then
				// The date is the same - simply correct the document time (it will not be shown to the user).
				CurrentObject.Date = LatestOrder.Date + 1;
				
			Else
				// The receipt writing too early.
				CurrentObjectPresentation = StringFunctionsClientServer.SubstituteParametersInString(
				        NStr("en = '%1 %2 from %3'"), CurrentObject.Metadata().Synonym, CurrentObject.Number, Format(CurrentObject.Date, "DLF=D"));
				Message(StringFunctionsClientServer.SubstituteParametersInString(
				        NStr("en = 'The %1 can not be written before the %2'"), CurrentObjectPresentation, LatestOrder.Ref));
				Cancel = True;
			EndIf;
			
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	If FirstNumber <> "" Then
		
		Numerator = Catalogs.DocumentNumbering.ItemReceipt.GetObject();
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
	
	// Refill lots and serial numbers values.
	For Each Row In Object.LineItems Do
		// Update lots & serials visibility and availability.
		LotsSerialNumbers.UpdateLotsSerialNumbersVisibility(Row.Product, Items, 0, Row.UseLotsSerials);
		// Fill lot owner.
		LotsSerialNumbers.FillLotOwner(Row.Product, Row.LotOwner);
		// Load serial numbers.
		LotsSerialNumbers.FillSerialNumbers(Object.SerialNumbers, Row.Product, 0, Row.LineID, Row.SerialNumbers);
	EndDo;
	
EndProcedure

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region CONTROLS_EVENTS_HANDLERS

&AtClient
Procedure DateOnChange(Item)
	
	// Ask user about updating the setting and update the line items accordingly.
	CommonDefaultSettingOnChange(Item, "cost", NStr("en = 'line items'"));
	
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
	
	// Request server operation.
	CompanyOnChangeAtServer();
	
	// Select non-closed orders by the company.
	CompanyOnChangeOrdersSelection(Item);
	
EndProcedure

&AtServer
Procedure CompanyOnChangeAtServer()
	
	// Reset company adresses (if company was changed).
	FillCompanyAddressesAtServer(Object.Company, Object.CompanyAddress);
	
	// Request company default settings.
	Object.Currency = Object.Company.DefaultCurrency;
	
	// Check company orders for further orders selection.
	FillCompanyHasNonClosedOrders();
	
	// Process settings changes.
	CurrencyOnChangeAtServer();
	
EndProcedure

&AtClient
Procedure CompanyOnChangeOrdersSelection(Item)
	
	// Suggest filling of invoice by non-closed orders.
	If (Not Object.Company.IsEmpty()) And (CompanyHasNonClosedOrders) Then
		
		// Define form parameters.
		FormParameters = New Structure();
		FormParameters.Insert("Company", Object.Company);
		FormParameters.Insert("UseItemReceipt", False);
		
		// Open orders selection form.
		NotifyDescription = New NotifyDescription("CompanyOnChangeOrdersSelectionChoiceProcessing", ThisForm);
		OpenForm("CommonForm.ChoiceFormPO_IR", FormParameters, Item,,,, NotifyDescription);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CompanyOnChangeOrdersSelectionChoiceProcessing(Result, Parameters) Export
	
	// Process selection result.
	If Not Result = Undefined Then
		
		// Do fill document from selected orders.
		FillDocumentWithSelectedOrders(Result);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CurrencyOnChange(Item)
	
	// Request server operation.
	CurrencyOnChangeAtServer();
	
EndProcedure

&AtServer
Procedure CurrencyOnChangeAtServer()
	
	// Update currency presentation.
	DefaultCurrencySymbol          = GeneralFunctionsReusable.DefaultCurrencySymbol();
	ForeignCurrencySymbol          = Object.Currency.Symbol;
	Items.ExchangeRate.Title       = DefaultCurrencySymbol + "/1" + ForeignCurrencySymbol;
	Items.FCYCurrency.Title        = ForeignCurrencySymbol;
	Items.RCCurrency.Title         = DefaultCurrencySymbol;
	
	// Request currency default settings.
	Object.ExchangeRate            = GeneralFunctions.GetExchangeRate(Object.Date, Object.Currency);
	
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
	CommonDefaultSettingOnChange(Item, Lower(Item.ToolTip), NStr("en = 'line items'"));
	
EndProcedure

&AtClient
Procedure DeliveryDateOnChange(Item)
	
	// Ask user about updating the setting and update the line items accordingly.
	CommonDefaultSettingOnChange(Item, Lower(Item.ToolTip), NStr("en = 'line items'"));
	
EndProcedure

&AtClient
Procedure ProjectOnChange(Item)
	
	// Ask user about updating the setting and update the line items and accounts accordingly.
	CommonDefaultSettingOnChange(Item, Lower(Item.Name), NStr("en = 'items and expences'"));
	
EndProcedure

&AtClient
Procedure ClassOnChange(Item)

	// Ask user about updating the setting and update the line items and accounts accordingly.
	CommonDefaultSettingOnChange(Item, Lower(Item.Name), NStr("en = 'items and expences'"));
	
EndProcedure

//------------------------------------------------------------------------------
// Utils for request user confirmation and propagate header settings to line items.

&AtClient
Procedure CommonDefaultSettingOnChange(Item, ItemPresentation, Destination)
	
	// Request user confirmation changing the setting for all LineItems.
	DefaultSetting = Item.Name;
	If Object.LineItems.Count() > 0 Then
		QuestionText  = StringFunctionsClientServer.SubstituteParametersInString(NStr("en = 'Reset the %1 for %2?'"), ItemPresentation, Destination);
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
		// Set new setting for all line items and accounts.
		ThisForm[DefaultSetting] = Object[DefaultSetting];
		DefaultSettingOnChangeAtServer(DefaultSetting, True);
		
	ElsIf ChoiceResult = DialogReturnCode.No Then
		// Keep new setting, do not update line items and accounts.
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
			If Object.Ref.Metadata().TabularSections.LineItems.Attributes.Find(DefaultSetting) <> Undefined Then
				For Each Row In Object.LineItems Do
					Row[DefaultSetting] = Object[DefaultSetting];
				EndDo;
			EndIf;
			
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
		
		// Assign new ID to the new line.
		Item.CurrentData.LineID = New UUID();
		
		// Fill new row with default values.
		ObjectData  = New Structure("Location, DeliveryDate, Project, Class");
		FillPropertyValues(ObjectData, Object);
		For Each ObjectField In ObjectData Do
			If Not ValueIsFilled(Item.CurrentData[ObjectField.Key]) Then
				Item.CurrentData[ObjectField.Key] = ObjectField.Value;
			EndIf;
		EndDo;
		
		// Clear order data on duplicate row.
		ClearFields  = New Structure("Order, LocationOrder, DeliveryDateOrder");
		For Each ClearField In ClearFields Do
			If Not ValueIsFilled(Item.CurrentData[ObjectField.Key]) Then
				Item.CurrentData[ObjectField.Key] = Undefined;
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
Procedure LineItemsBeforeDeleteRow(Item, Cancel)
	
	// Get current serial numbers list.
	TableSectionRow  = Items.LineItems.CurrentData;
	SerialNumbersTbl = Object.SerialNumbers.FindRows(New Structure("LineItemsLineID", TableSectionRow.LineID));
	
	// Delete existing numbers.
	For Each Row In SerialNumbersTbl Do
		Object.SerialNumbers.Delete(Row);
	EndDo;
	
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
	ProductProperties = CommonUse.GetAttributeValues(TableSectionRow.Product,   New Structure("Ref, Description, UnitSet, HasLotsSerialNumbers, UseLots, UseLotsType, Characteristic, UseSerialNumbersOnGoodsReception"));
	UnitSetProperties = CommonUse.GetAttributeValues(ProductProperties.UnitSet, New Structure("DefaultPurchaseUnit"));
	TableSectionRow.ProductDescription = ProductProperties.Description;
	TableSectionRow.UnitSet            = ProductProperties.UnitSet;
	TableSectionRow.Unit               = UnitSetProperties.DefaultPurchaseUnit;
	TableSectionRow.PriceUnits         = Round(GeneralFunctions.ProductLastCost(TableSectionRow.Product, PointInTime) *
	                                     ?(TableSectionRow.Unit.Factor > 0, TableSectionRow.Unit.Factor, 1) /
	                                     ?(Object.ExchangeRate > 0, Object.ExchangeRate, 1), GeneralFunctionsReusable.PricePrecisionForOneItem(TableSectionRow.Product));
	
	// Make lots & serial numbers columns visible.
	LotsSerialNumbers.UpdateLotsSerialNumbersVisibility(ProductProperties, Items, 0, TableSectionRow.UseLotsSerials);
	
	// Fill lot owner.
	LotsSerialNumbers.FillLotOwner(ProductProperties, TableSectionRow.LotOwner);
	
	// Clear serial numbers.
	TableSectionRow.SerialNumbers = "";
	LineItemsSerialNumbersOnChangeAtServer(TableSectionRow);
	
	// Reset default values.
	FillPropertyValues(TableSectionRow, Object, "Location, DeliveryDate, Project, Class");
	
	// Clear up order data.
	TableSectionRow.Order             = Documents.PurchaseOrder.EmptyRef();
	TableSectionRow.DeliveryDateOrder = '00010101';
	TableSectionRow.LocationOrder     = Catalogs.Locations.EmptyRef();
	
	// Assign default quantities.
	TableSectionRow.QtyUnits  = 0;
	TableSectionRow.QtyUM     = 0;
	TableSectionRow.Invoiced  = 0;
	
	// Calculate totals by line.
	TableSectionRow.LineTotal = 0;
	
EndProcedure

&AtClient
Procedure LineItemsSerialNumbersOnChange(Item)
	
	// Fill line data for editing.
	TableSectionRow = GetLineItemsRowStructure();
	FillPropertyValues(TableSectionRow, Items.LineItems.CurrentData);
	
	// Request server operation.
	LineItemsSerialNumbersOnChangeAtServer(TableSectionRow);
	
	// Load processed data back.
	FillPropertyValues(Items.LineItems.CurrentData, TableSectionRow);
	
	// Refresh totals cache.
	RecalculateTotals();
	
EndProcedure

&AtServer
Procedure LineItemsSerialNumbersOnChangeAtServer(TableSectionRow)
	
	// Get current serial numbers list.
	SerialNumbersTbl = Object.SerialNumbers.FindRows(New Structure("LineItemsLineID", TableSectionRow.LineID));
	
	// Delete existing numbers.
	For Each Row In SerialNumbersTbl Do
		Object.SerialNumbers.Delete(Row);
	EndDo;
	
	// Add new numbers.
	SerialNumbersArr = LotsSerialNumbersClientServer.GetSerialNumbersArrayFromStr(TableSectionRow.SerialNumbers);
	For Each SerialNumber In SerialNumbersArr Do
		Row = Object.SerialNumbers.Add();
		Row.LineItemsLineID = TableSectionRow.LineID;
		Row.SerialNumber    = SerialNumber;
	EndDo;
	
	// Process settings changes.
	LineItemsQuantityOnChangeAtServer(TableSectionRow);
	
EndProcedure

&AtClient
Procedure LineItemsSerialNumbersTextEditEnd(Item, Text, ChoiceData, Parameters, StandardProcessing)
	
	// Get current row.
	Row = Items.LineItems.CurrentData;
	
	// Decode array of serial numbers from entered string.
	SerialNumbers = LotsSerialNumbersClientServer.GetSerialNumbersArrayFromStr(Text);
	
	// Refill serial numbers by the standard formatting.
	If SerialNumbers.Count() > 0 Then
		Row.SerialNumbers = StringFunctionsClientServer.GetStringFromSubstringArray(SerialNumbers, ", ");
		Row.QtyUnits = SerialNumbers.Count();
	Else
		Row.QtyUnits = 1;
	EndIf;
	
EndProcedure

&AtClient
Procedure LineItemsSerialNumbersStartChoice(Item, ChoiceData, StandardProcessing)
	
	// Fill current serial numbers in a table and open an editor form.
	Notify         = New NotifyDescription("LineItemsSerialNumbersChoiceProcessing", ThisObject);
	FormParameters = New Structure("SerialNumbers", Item.EditText);
	OpenForm("CommonForm.SerialNumbers", FormParameters, ThisForm,,,, Notify, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure LineItemsSerialNumbersChoiceProcessing(Result, Parameters) Export
	
	// Process choice result.
	If TypeOf(Result) = Type("String") Then
		// Process serial numbers string change.
		LineItemsSerialNumbersTextEditEnd(Items.LineItemsSerialNumbers, Result,,,);
		
		// Process serial numbers change.
		LineItemsSerialNumbersOnChange(Items.LineItemsSerialNumbers);
	EndIf;
	
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
		
		Query.Text = 
			"SELECT
			|	LineItems.LineNumber                      AS LineNumber,
			//  Request dimensions
			|	OrdersDispatchedBalance.Product           AS Product,
			|	OrdersDispatchedBalance.Unit              AS Unit,
			|	OrdersDispatchedBalance.Location          AS LocationOrder,
			|	OrdersDispatchedBalance.DeliveryDate      AS DeliveryDateOrder,
			|	OrdersDispatchedBalance.Project           AS Project,
			|	OrdersDispatchedBalance.Class             AS Class,
			|	OrdersDispatchedBalance.Order             AS Order,
			//  Request resources
			|	OrdersDispatchedBalance.ReceivedIRBalance AS QtyUnits,
			|	OrdersDispatchedBalance.InvoicedBalance   AS Invoiced
			//  Request sources
			|FROM
			|	Document.ItemReceipt.LineItems            AS LineItems
			|	LEFT JOIN AccumulationRegister.OrdersDispatched.Balance(,ItemReceipt = &Ref)
			|		                                      AS OrdersDispatchedBalance
			|		ON    ( LineItems.Ref.Company         = OrdersDispatchedBalance.Company
			|			AND LineItems.Order               = OrdersDispatchedBalance.Order
			|			AND LineItems.Ref                 = OrdersDispatchedBalance.ItemReceipt
			|			AND LineItems.Product             = OrdersDispatchedBalance.Product
			|			AND LineItems.Unit                = OrdersDispatchedBalance.Unit
			|			AND LineItems.LocationOrder       = OrdersDispatchedBalance.Location
			|			AND LineItems.DeliveryDateOrder   = OrdersDispatchedBalance.DeliveryDate
			|			AND LineItems.Project             = OrdersDispatchedBalance.Project
			|			AND LineItems.Class               = OrdersDispatchedBalance.Class
			|			AND LineItems.QtyUnits            = OrdersDispatchedBalance.ReceivedIRBalance)
			//  Request filtering
			|WHERE
			|	LineItems.Ref = &Ref
			//  Request ordering
			|ORDER BY
			|	LineItems.LineNumber";
		Selection = Query.Execute().Select();
		
		// Fill ordered items quantities
		SearchRec = New Structure("LineNumber, Product, Unit, LocationOrder, DeliveryDateOrder, Project, Class, Order, QtyUnits");
		While Selection.Next() Do
			
			// Search for appropriate line in tabular section of order
			FillPropertyValues(SearchRec, Selection);
			FoundLineItems = Object.LineItems.FindRows(SearchRec);
			
			// Fill quantities in tabular section
			If FoundLineItems.Count() > 0 Then
				FillPropertyValues(FoundLineItems[0], Selection, "Invoiced");
			EndIf;
			
		EndDo;
		
	EndIf;
	
EndProcedure

&AtServer
// Request and fill company addresses used for proper goods delivery.
Procedure FillCompanyAddressesAtServer(Company, ShipTo, BillTo = Undefined, ConfirmTo = Undefined);
	
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
		ConfirmTo = Catalogs.Addresses.EmptyRef();
	EndIf;
	
EndProcedure

&AtServer
// Check presence of non-closed orders for the object's company.
Procedure FillCompanyHasNonClosedOrders()
	
	// Create new query
	Query = New Query;
	Query.SetParameter("Company", Object.Company);
	
	QueryText = 
		"SELECT TOP 1
		|	OrdersDispatchedBalance.Company,
		|	OrdersDispatchedBalance.Order,
		|	OrdersDispatchedBalance.Product,
		|	OrdersDispatchedBalance.Unit,
		|	OrdersDispatchedBalance.Location,
		|	OrdersDispatchedBalance.DeliveryDate,
		|	OrdersDispatchedBalance.Project,
		|	OrdersDispatchedBalance.Class
		|FROM
		|	AccumulationRegister.OrdersDispatched.Balance(
		|			,
		|			Company = &Company
		|				AND Order.UseIR = TRUE) AS OrdersDispatchedBalance
		|WHERE
		|	OrdersDispatchedBalance.QuantityBalance - OrdersDispatchedBalance.ReceivedBalance > 0";
	Query.Text  = QueryText;
	
	// Assign true if there are open or backordered orders
	CompanyHasNonClosedOrders = Not Query.Execute().IsEmpty();
	
EndProcedure

&AtServer
// Fills document on the base of passed array of orders.
// Returns flag of successfull filing.
Function FillDocumentWithSelectedOrders(SelectedOrders)
	
	// Fill table on the base of selected orders
	If SelectedOrders <> Undefined Then
		
		// Fill object by orders
		DocObject = FormAttributeToValue("Object");
		DocObject.Fill(SelectedOrders);
		
		// Return filled object to form
		ValueToFormAttribute(DocObject, "Object");
		
		// Update serial numbers visibility basingo on filled items.
		For Each Row In Object.LineItems Do
			// Make lots & serial numbers columns visible.
			LotsSerialNumbers.UpdateLotsSerialNumbersVisibility(Row.Product, Items, 0, Row.UseLotsSerials);
			// Fill lot owner.
			LotsSerialNumbers.FillLotOwner(Row.Product, Row.LotOwner);
			// Load serial numbers.
			LotsSerialNumbers.FillSerialNumbers(Object.SerialNumbers, Row.Product, 0, Row.LineID, Row.SerialNumbers);
		EndDo;
		
		// Return filling success
		Return True;
	Else
		// Order wasn't selected: Clear foreign orders
		If  (Object.LineItems.Count() > 0)
			// Will assume that all previosly selected orders are filled correctly, and belong to the same company
		And (Not Object.LineItems[0].Order.Company = Object.Company) Then
			// Clear existing dataset
			Object.LineItems.Clear();
			Object.SerialNumbers.Clear();
		EndIf;
		
		// Return fail (selection cancelled)
		Return False;
	EndIf;
	
EndFunction

//------------------------------------------------------------------------------
// Replacemant for metadata properties on client.

&AtClient
// Returns fields structure of LineItems form control.
Function GetLineItemsRowStructure()
	
	// Define control row fields.
	Return New Structure("LineNumber, LineID, Product, ProductDescription, UseLotsSerials, LotOwner, Lot, SerialNumbers, UnitSet, QtyUnits, Invoiced, Unit, QtyUM, PriceUnits, LineTotal, LocationOrder, Location, DeliveryDateOrder, DeliveryDate, Project, Class, Order");
	
EndFunction

//------------------------------------------------------------------------------
// Calculate totals and fill object attributes.

&AtClient
Procedure RecalculateTotals()
	
	// Assign totals to the object fields.
	Object.DocumentTotal   = Object.LineItems.Total("LineTotal");
	Object.DocumentTotalRC = Round(Object.DocumentTotal * Object.ExchangeRate, 2);
	
EndProcedure

&AtServer
Procedure RecalculateTotalsAtServer()
	
	// Calculate document totals.
	Object.DocumentTotal   = Object.LineItems.Total("LineTotal");
	Object.DocumentTotalRC = Round(Object.DocumentTotal * Object.ExchangeRate, 2);
	
EndProcedure

#EndRegion