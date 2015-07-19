

////////////////////////////////////////////////////////////////////////////////
// Shipment: Document form
//------------------------------------------------------------------------------
// Available on:
// - Client (managed application)
// - Server
//
&AtClient
Var SalesTaxRateInactive, AgenciesRatesInactive;//Cache for storing inactive rates previously used in the document

////////////////////////////////////////////////////////////////////////////////
#Region EVENTS_HANDLERS

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Object.Ref.IsEmpty() Then
		FirstNumber = Object.Number;
	EndIf;
	
	If Parameters.Property("Company") And Parameters.Company.Customer And Object.Ref.IsEmpty() Then
		Object.Company = Parameters.Company;
		OpenOrdersSelectionForm = True; 
	EndIf;

	
	//------------------------------------------------------------------------------
	// 1. Form attributes initialization.
	
	// Set LineItems editing flag.
	IsNewRow     = False;
	
	// Fill object attributes cache.
	DeliveryDateActual   = Object.DeliveryDateActual;
	LocationActual       = Object.LocationActual;
	Project              = Object.Project;
	Class                = Object.Class;
	
	//------------------------------------------------------------------------------
	// 2. Calculate values of form object attributes.
	
	// Request and fill shipment status.
	FillShipmentStatusAtServer();
	
	// Request and fill ordered items from database.
	FillBackorderQuantityAtServer();
	
	//------------------------------------------------------------------------------
	// 3. Set custom controls presentation.
	
	// Set proper company field presentation.
	CustomerName                    = GeneralFunctionsReusable.GetCustomerName();
	Items.Company.Title             = CustomerName;
	Items.Company.ToolTip           = StringFunctionsClientServer.SubstituteParametersInString(NStr("en = '%1 name'"),             CustomerName);
	Items.ShipTo.ToolTip            = StringFunctionsClientServer.SubstituteParametersInString(NStr("en = '%1 shipping address'"), CustomerName);
	Items.BillTo.ToolTip            = StringFunctionsClientServer.SubstituteParametersInString(NStr("en = '%1 billing address'"),  CustomerName);
	Items.ConfirmTo.ToolTip         = StringFunctionsClientServer.SubstituteParametersInString(NStr("en = '%1 confirm address'"),  CustomerName);
	Items.DropshipCompany.Title     = StringFunctionsClientServer.SubstituteParametersInString(NStr("en = 'Dropship %1'"),         Lower(CustomerName));
	Items.DropshipCompany.ToolTip   = StringFunctionsClientServer.SubstituteParametersInString(NStr("en = 'Dropship %1 name'"),    Lower(CustomerName));
	Items.DropshipShipTo.ToolTip    = StringFunctionsClientServer.SubstituteParametersInString(NStr("en = 'Dropship %1 shipping address'"), Lower(CustomerName));
	Items.DropshipConfirmTo.ToolTip = StringFunctionsClientServer.SubstituteParametersInString(NStr("en = 'Dropship %1 confirm address'"),  Lower(CustomerName));
	Items.DropshipRefNum.ToolTip    = StringFunctionsClientServer.SubstituteParametersInString(NStr("en = 'Dropship %1 purchase order number /
	                                                                                                      |Reference number'"),    Lower(CustomerName));
	
	// Update quantities presentation.
	QuantityPrecision = GeneralFunctionsReusable.DefaultQuantityPrecision();
	QuantityFormat    = GeneralFunctionsReusable.DefaultQuantityFormat();
	Items.LineItemsQuantity.EditFormat  = QuantityFormat;
	Items.LineItemsQuantity.Format      = QuantityFormat;
	Items.LineItemsInvoiced.EditFormat  = QuantityFormat;
	Items.LineItemsInvoiced.Format      = QuantityFormat;
	
	// Update prices presentation.
	PriceFormat = GeneralFunctionsReusable.DefaultPriceFormat();
	Items.LineItemsPrice.EditFormat  = PriceFormat;
	Items.LineItemsPrice.Format      = PriceFormat;
	
	// Set lots and serial numbers visibility.
	Items.LineItemsLot.Visible           = False;
	Items.LineItemsSerialNumbers.Visible = False;
	For Each Row In Object.LineItems Do
		// Make lots & serial numbers columns visible.
		LotsSerialNumbers.UpdateLotsSerialNumbersVisibility(Row.Product, Items, 1, Row.UseLotsSerials);
		// Fill lot owner.
		LotsSerialNumbers.FillLotOwner(Row.Product, Row.LotOwner);
		// Load serial numbers.
		LotsSerialNumbers.FillSerialNumbers(Object.SerialNumbers, Row.Product, 1, Row.LineID, Row.SerialNumbers);
	EndDo;
	
	// Request tax rate for US sales tax calcualation.
	If GeneralFunctionsReusable.FunctionalOptionValue("SalesTaxCharging") Then
		If Object.Ref.IsEmpty() And (Not ValueIsFilled(Object.DiscountTaxability)) Then
			Object.DiscountTaxability = Enums.DiscountTaxability.NonTaxable;
		ElsIf Not ValueIsFilled(Object.DiscountTaxability) Then
			Object.DiscountTaxability = ?(Object.DiscountIsTaxable, Enums.DiscountTaxability.Taxable, Enums.DiscountTaxability.NonTaxable);			
		EndIf;
		ApplySalesTaxEngineSettings();
		If Not Object.UseAvatax Then
			TaxEngine = 1; //Use AccountingSuite
			//Fill the list of available tax rates
			ListOfAvailableTaxRates = SalesTax.GetSalesTaxRatesList();
			For Each TaxRateItem In ListOfAvailableTaxRates Do
				Items.SalesTaxRate.ChoiceList.Add(TaxRateItem.Value, TaxRateItem.Presentation);
			EndDo;
			If Object.Ref.IsEmpty() Then
				If Not ValueIsFilled(Parameters.Basis) Then
					Object.DiscountTaxability = Enums.DiscountTaxability.NonTaxable;
				Else //If filled on the basis of Sales Order
					RecalculateTotals(Object);
				EndIf;
				//If filled on the basis of Sales Order set current value
				SalesTaxRate = Object.SalesTaxRate;
			Else
				//Determine if document's sales tax rate is inactive (has been changed)
				AgenciesRates = New Array();
				For Each AgencyRate In Object.SalesTaxAcrossAgencies Do
					AgenciesRates.Add(New Structure("Agency, Rate", AgencyRate.Agency, AgencyRate.Rate));
				EndDo;
				If SalesTax.DocumentSalesTaxRateIsInactive(Object.SalesTaxRate, AgenciesRates) Then
					SalesTaxRate = 0;
					TaxRate = Object.SalesTaxAcrossAgencies.Total("Rate");
					Representation = SalesTax.GetSalesTaxRatePresentation(Object.SalesTaxRate.Description, TaxRate) + " - Inactive";
					Items.SalesTaxRate.ChoiceList.Add(0, Representation);
				Else
					SalesTaxRate = Object.SalesTaxRate;
				EndIf;
			EndIf;
		Else
			TaxEngine = 2; //Use AvaTax
		EndIf;
		DisplaySalesTaxRate(ThisForm);
		SetDiscountTaxabilityAppearance(ThisForm);
	Else
		Items.SalesTaxPercentDecoration.Title = "";
		Items.SalesTaxPercentDecoration.Border = New Border(ControlBorderType.WithoutBorder);
		Items.TotalsColumn3Labels.Visible = False;
		Items.TaxTab.Visible = False;
	EndIf;
		
	// Set currency titles.
	DefaultCurrencySymbol            = GeneralFunctionsReusable.DefaultCurrencySymbol();
	ForeignCurrencySymbol            = Object.Currency.Symbol;
	Items.ExchangeRate.Title         = DefaultCurrencySymbol + "/1" + ForeignCurrencySymbol;
	Items.LineSubtotalCurrency.Title = ForeignCurrencySymbol;
	Items.DiscountCurrency.Title     = ForeignCurrencySymbol;
	Items.SubTotalCurrency.Title     = ForeignCurrencySymbol;
	Items.ShippingCurrency.Title     = ForeignCurrencySymbol;
	Items.SalesTaxCurrency.Title     = ForeignCurrencySymbol;
	Items.FCYCurrency.Title          = ForeignCurrencySymbol;
	Items.RCCurrency.Title           = DefaultCurrencySymbol;
	Items.TaxableSubtotalCurrency.Title = ForeignCurrencySymbol;
	
	// Update visibility of controls depending on functional options.
	If Not GeneralFunctionsReusable.FunctionalOptionValue("MultiCurrency") Then
		Items.RCCurrency.Title 	= ""; 
	EndIf;
	
	// Cancel opening form if filling on the base was failed
	If Object.Ref.IsEmpty() And Parameters.Basis <> Undefined
	And Object.Company <> Parameters.Basis.Company Then
		// Object is not filled as expected
		Cancel = True;
		Return;
	EndIf;
			
	If Object.BillTo <> Catalogs.Addresses.EmptyRef() AND Object.ShipTo <> Catalogs.Addresses.EmptyRef()  Then
		Items.DecorationShipTo.Visible = True;
		Items.DecorationBillTo.Visible = True;
		Items.DecorationBillTo.Title = GeneralFunctions.ShowAddressDecoration(Object.BillTo);
		Items.DecorationShipTo.Title = GeneralFunctions.ShowAddressDecoration(Object.ShipTo);
	Else
		Items.DecorationShipTo.Visible = False;
		Items.DecorationBillTo.Visible = False;
	EndIf;
	
	//This part of module is temporary
	Items.DiscountPercent.ReadOnly            = True;
	Items.Discount.ReadOnly                   = True;
	Items.Shipping.ReadOnly                   = True;
	Items.LineItemsPrice.ReadOnly             = True;
	Items.LineItemsLineTotal.ReadOnly         = True;
	Items.LineItemsTaxable.ReadOnly           = True;
	Items.LineItemsDiscountIsTaxable.ReadOnly = True;
	Items.LineItemsAvataxTaxCode.ReadOnly     = True;
	Items.Currency2.ReadOnly                  = True;
	Items.TaxTab.ReadOnly                     = True;
	//
	
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
	
	//Avatax calculation
	//AvaTaxClient.ShowQueryToTheUserOnAvataxCalculation("SalesInvoice", Object, ThisObject, WriteParameters, Cancel);
		
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If Object.Discount <> 0 AND
		Constants.DiscountsAccount.Get() = ChartsOfAccounts.ChartOfAccounts.EmptyRef() Then
			Message = New UserMessage();
			Message.Text=NStr("en='Indicate a default discount account in Settings / Posting accounts. Saving cancelled.'");
			Message.Message();
			Cancel = True;
	EndIf;
	
	If Object.Shipping <> 0 AND
		Constants.ShippingExpenseAccount.Get() = ChartsOfAccounts.ChartOfAccounts.EmptyRef() Then
			Message = New UserMessage();
			Message.Text=NStr("en='Indicate a default shipping account in Settings / Posting accounts. Saving cancelled.'");
			Message.Message();
			Cancel = True;
	EndIf;

	
	If Object.LineItems.Count() = 0 Then
		Message("Cannot post/save with no line items.");
		Cancel = True;
	EndIf;
	
	//Period closing
	If PeriodClosingServerCall.DocumentPeriodIsClosed(CurrentObject.Ref, CurrentObject.Date) Then
		PermitWrite = PeriodClosingServerCall.DocumentWritePermitted(WriteParameters);
		CurrentObject.AdditionalProperties.Insert("PermitWrite", PermitWrite);
	EndIf;
	
	//------------------------------------------------------------------------------
	// 1. Correct the shipment date according to the orders dates.
	
	// Request orders dates.
	QueryText = "
		|SELECT TOP 1
		|	SalesOrder.Date AS Date,
		|	SalesOrder.Ref  AS Ref
		|FROM
		|	Document.SalesOrder AS SalesOrder
		|WHERE
		|	SalesOrder.Ref IN (&Orders)
		|ORDER BY
		|	SalesOrder.Date Desc";
	Query = New Query(QueryText);
	Query.SetParameter("Orders", CurrentObject.LineItems.UnloadColumn("Order"));
	QueryResult = Query.Execute();
	
	// Compare letest order date with current shipment date.
	If Not QueryResult.IsEmpty() Then
		
		// Check latest order date.
		LatestOrder  = QueryResult.Unload()[0];
		If (Not LatestOrder.Date = Null) And (LatestOrder.Date >= CurrentObject.Date) Then
			
			// Shipment writing before the order.
			If BegOfDay(LatestOrder.Date) = BegOfDay(CurrentObject.Date) Then
				// The date is the same - simply correct the document time (it will not be shown to the user).
				CurrentObject.Date = LatestOrder.Date + 1;
				
			Else
				// The shipment writing too early.
				CurrentObjectPresentation = StringFunctionsClientServer.SubstituteParametersInString(
				        NStr("en = '%1 %2 from %3'"), CurrentObject.Metadata().Synonym, CurrentObject.Number, Format(CurrentObject.Date, "DLF=D"));
				Message(StringFunctionsClientServer.SubstituteParametersInString(
				        NStr("en = 'The %1 can not be written before the %2'"), CurrentObjectPresentation, LatestOrder.Ref));
				Cancel = True;
			EndIf;
			
		EndIf;
	EndIf;
	
	//Avatax calculation
	//AvaTaxServer.CalculateTaxBeforeWrite(CurrentObject, WriteParameters, Cancel, "SalesOrder");
		
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	If FirstNumber <> "" Then
		
		Numerator = Catalogs.DocumentNumbering.Shipment.GetObject();
		NextNumber = GeneralFunctions.Increment(Numerator.Number);
		If FirstNumber = NextNumber And NextNumber = Object.Number Then
			Numerator.Number = FirstNumber;
			Numerator.Write();
		EndIf;
		
		FirstNumber = "";
	EndIf;
	
	//------------------------------------------------------------------------------
	// Recalculate values of form object attributes.
	
	// Request and fill shipment status from database.
	FillShipmentStatusAtServer();
	
	// Request and fill ordered items from database.
	FillBackorderQuantityAtServer();
	
	// Refill lots and serial numbers values.
	For Each Row In Object.LineItems Do
		// Update lots & serials visibility and availability.
		LotsSerialNumbers.UpdateLotsSerialNumbersVisibility(Row.Product, Items, 1, Row.UseLotsSerials);
		// Fill lot owner.
		LotsSerialNumbers.FillLotOwner(Row.Product, Row.LotOwner);
		// Load serial numbers.
		LotsSerialNumbers.FillSerialNumbers(Object.SerialNumbers, Row.Product, 1, Row.LineID, Row.SerialNumbers);
	EndDo;
	
	//Avatax calculation
	//AvaTaxServer.CalculateTaxAfterWrite(CurrentObject, WriteParameters, "SalesInvoice");
		
	//Update tax rate
	DisplaySalesTaxRate(ThisForm);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	//Close the form if the command is "Post and close"
	If WriteParameters.Property("CloseAfterWrite") Then
		Close();
	EndIf;
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "SalesTaxRateAdded" Then
		If Items.SalesTaxRate.ChoiceList.FindByValue(Parameter) = Undefined Then
			Items.SalesTaxRate.ChoiceList.Add(Parameter);
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region CONTROLS_EVENTS_HANDLERS

&AtClient
Procedure DateOnChange(Item)
	
	// Ask user about updating the setting and update the line items accordingly.
	CommonDefaultSettingOnChange(Item, "price");
	
EndProcedure

&AtServer
Procedure DateOnChangeAtServer()
	
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
	FillCompanyAddressesAtServer(Object.Company, Object.ShipTo, Object.BillTo, Object.ConfirmTo);
	
	// Request company default settings.
	Object.Currency        = Object.Company.DefaultCurrency;
	Object.Terms           = Object.Company.Terms;
	Object.SalesPerson     = Object.Company.SalesPerson;
	
	// Check company orders for further orders selection.
	FillCompanyHasNonClosedOrders();
	
	// Process settings changes.
	CurrencyOnChangeAtServer();
	
	// Tax settings
	SalesTaxRate 		= SalesTax.GetDefaultSalesTaxRate(Object.Company);
	If GeneralFunctionsReusable.FunctionalOptionValue("AvataxEnabled") Then
		Object.UseAvatax	= Object.Company.UseAvatax;
	Else
		Object.UseAvatax	= False;
	EndIf;
	If (Not Object.UseAvatax) Then
		TaxEngine = 1; //Use AccountingSuite
		If SalesTaxRate <> Object.SalesTaxRate Then
			Object.SalesTaxRate = SalesTaxRate;
		EndIf;
	Else
		TaxEngine = 2;
	EndIf;
	Object.SalesTaxAcrossAgencies.Clear();
	ApplySalesTaxEngineSettings();
	If Object.UseAvatax Then
		//AvataxServer.RestoreCalculatedSalesTax(Object);
	EndIf;	
	
	RecalculateTotals(Object);
	DisplaySalesTaxRate(ThisForm);
	
	If Object.Company.ARAccount = ChartsofAccounts.ChartOfAccounts.EmptyRef() Then
		DefaultCurrency = GeneralFunctionsReusable.DefaultCurrency();
	EndIf;
	
	Items.DecorationBillTo.Visible = True;
	Items.DecorationShipTo.Visible = True;
	Items.DecorationShipTo.Title = GeneralFunctions.ShowAddressDecoration(Object.ShipTo);
	Items.DecorationBillTo.Title = GeneralFunctions.ShowAddressDecoration(Object.BillTo);
	
EndProcedure

&AtClient
Procedure CompanyOnChangeOrdersSelection(Item)
	
	// Suggest filling of shipment by non-closed orders.
	If (Not Object.Company.IsEmpty()) And (CompanyHasNonClosedOrders) Then
		
		// Define form parameters.
		FormParameters = New Structure();
		FormParameters.Insert("Company", Object.Company);
		FormParameters.Insert("UseShipment", False);
		
		// Open orders selection form.
		NotifyDescription = New NotifyDescription("CompanyOnChangeOrdersSelectionChoiceProcessing", ThisForm);
		OpenForm("CommonForm.ChoiceFormSO_Shipment", FormParameters, Item,,,, NotifyDescription);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CompanyOnChangeOrdersSelectionChoiceProcessing(Result, Parameters) Export
	
	// Process selection result.
	If Not Result = Undefined Then
		
		// Do fill document from selected orders.
		FillDocumentWithSelectedOrders(Result);
		
		// Sales tax update.
		SalesTaxRate = Object.SalesTaxRate;
		SetSalesTaxRate(SalesTaxRate);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DropshipCompanyOnChange(Item)
	
	// Request server operation.
	DropshipCompanyOnChangeAtServer();
	
EndProcedure

&AtServer
Procedure DropshipCompanyOnChangeAtServer()
	
	// Reset company adresses (if company was changed).
	FillCompanyAddressesAtServer(Object.DropshipCompany, Object.DropshipShipTo,, Object.DropshipConfirmTo);
	
EndProcedure

&AtClient
Procedure ShipToOnChange(Item)
	
	Items.DecorationShipTo.Visible = True;
	Items.DecorationShipTo.Title = GeneralFunctions.ShowAddressDecoration(Object.ShipTo);
	// Request server operation.
	ShipToOnChangeAtServer();
	
EndProcedure

&AtServer
Procedure ShipToOnChangeAtServer()
	
	RecalculateTotals(Object);
	
EndProcedure

&AtClient
Procedure CurrencyOnChange(Item)
	
	// Request server operation.
	CurrencyOnChangeAtServer();
	
EndProcedure

&AtServer
Procedure CurrencyOnChangeAtServer()
	
	// Set currency titles.
	DefaultCurrencySymbol            = GeneralFunctionsReusable.DefaultCurrencySymbol();
	ForeignCurrencySymbol            = Object.Currency.Symbol;
	Items.ExchangeRate.Title         = DefaultCurrencySymbol + "/1" + ForeignCurrencySymbol;
	Items.LineSubtotalCurrency.Title = ForeignCurrencySymbol;
	Items.DiscountCurrency.Title     = ForeignCurrencySymbol;
	Items.SubTotalCurrency.Title     = ForeignCurrencySymbol;
	Items.ShippingCurrency.Title     = ForeignCurrencySymbol;
	Items.SalesTaxCurrency.Title     = ForeignCurrencySymbol;
	Items.FCYCurrency.Title 		 = ForeignCurrencySymbol;
	Items.TaxableSubtotalCurrency.Title = ForeignCurrencySymbol;
	
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
	RecalculateTotals(Object);
	
EndProcedure

&AtClient
Procedure LocationActualOnChange(Item)
	
	// Ask user about updating the setting and update the line items accordingly.
	CommonDefaultSettingOnChange(Item, Lower(Item.ToolTip));
	
EndProcedure

&AtClient
Procedure DeliveryDateActualOnChange(Item)
	
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
Procedure TermsOnChange(Item)
	
EndProcedure

&AtClient
Procedure DiscountPercentOnChange(Item)
	
	// Request server operation.
	DiscountPercentOnChangeAtServer();

EndProcedure

&AtServer
Procedure DiscountPercentOnChangeAtServer()
	
	// Recalculate totals with new discount.
	RecalculateTotals(Object);
	
EndProcedure

&AtClient
Procedure DiscountOnChange(Item)
	
	// Request server operation.
	DiscountOnChangeAtServer();
	
EndProcedure

&AtServer
Procedure DiscountOnChangeAtServer()
	
	// Discount can not override the total.
	If Object.Discount < -Object.LineSubtotal Then
		Object.Discount = - Object.LineSubtotal;
	EndIf;
	
	Object.DiscountPercent = Round(-1 * 100 * Object.Discount / Object.LineSubtotal, 2);
	
	// Recalculate totals with new discount.
	RecalculateTotals(Object);
	
EndProcedure

&AtClient
Procedure ShippingOnChange(Item)
	
	// Request server operation.
	ShippingOnChangeAtServer();
	
EndProcedure

&AtServer
Procedure ShippingOnChangeAtServer()
	
	// Recalculate totals with new shipping amount.
	RecalculateTotals(Object);
	
EndProcedure

&AtClient
Procedure SalesTaxOnChange(Item)
	
	// Request server operation.
	SalesTaxOnChangeAtServer();
	
EndProcedure

&AtServer
Procedure SalesTaxOnChangeAtServer()
	
	// Recalculate totals with new sales tax.
	RecalculateTotals(Object);
	
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
		// Set new setting for all line items.
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
				Row.PriceUnits = Round(GeneralFunctions.RetailPrice(Object.Date, Row.Product, Object.Company) *
				                 ?(Row.Unit.Factor > 0, Row.Unit.Factor, 1) /
				                 ?(Row.UnitSet.DefaultSaleUnit.Factor > 0, Row.UnitSet.DefaultSaleUnit.Factor, 1) /
				                 ?(Object.ExchangeRate > 0, Object.ExchangeRate, 1), GeneralFunctionsReusable.PricePrecisionForOneItem(Row.Product));
				LineItemsPriceOnChangeAtServer(Row);
			EndDo;
			RecalculateTotals(Object);
		EndIf;
		
	ElsIf DefaultSetting = "Company" Then
		
		// Process the attribute change in any case.
		CompanyOnChangeAtServer();
		
		// Process line items change.
		If RecalculateLineItems Then
			// Recalculate retail price.
			For Each Row In Object.LineItems Do
				Row.PriceUnits = Round(GeneralFunctions.RetailPrice(Object.Date, Row.Product, Object.Company) *
				                 ?(Row.Unit.Factor > 0, Row.Unit.Factor, 1) /
				                 ?(Row.UnitSet.DefaultSaleUnit.Factor > 0, Row.UnitSet.DefaultSaleUnit.Factor, 1) /
				                 ?(Object.ExchangeRate > 0, Object.ExchangeRate, 1), GeneralFunctionsReusable.PricePrecisionForOneItem(Row.Product));
				LineItemsPriceOnChangeAtServer(Row);
			EndDo;
			RecalculateTotals(Object);
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
		ObjectData  = New Structure("LocationActual, DeliveryDateActual, Project, Class");
		FillPropertyValues(ObjectData, Object);
		For Each ObjectField In ObjectData Do
			If Not ValueIsFilled(Item.CurrentData[ObjectField.Key]) Then
				Item.CurrentData[ObjectField.Key] = ObjectField.Value;
			EndIf;
		EndDo;
		
		// Clear order data on duplicate row.
		ClearFields  = New Structure("Order, Location, DeliveryDate");
		For Each ClearField In ClearFields Do
			If Not ValueIsFilled(Item.CurrentData[ObjectField.Key]) Then
				Item.CurrentData[ObjectField.Key] = Undefined;
			EndIf;
		EndDo;
		
		// Refresh totals cache.
		RecalculateTotals(Object);
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
	RecalculateTotals(Object);
	
EndProcedure

&AtClient
Procedure LineItemsAfterDeleteRow(Item)
	
	// Recalculation common document totals.
	RecalculateTotals(Object);
	
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
	RecalculateTotals(Object);
	
EndProcedure

&AtServer
Procedure LineItemsProductOnChangeAtServer(TableSectionRow)
	
	// Request product properties.
	ProductProperties = CommonUse.GetAttributeValues(TableSectionRow.Product,   New Structure("Ref, Description, UnitSet, Taxable, TaxCode, DiscountIsTaxable, HasLotsSerialNumbers, UseLots, UseLotsType, Characteristic, UseSerialNumbersOnShipment"));
	UnitSetProperties = CommonUse.GetAttributeValues(ProductProperties.UnitSet, New Structure("DefaultSaleUnit"));
	TableSectionRow.ProductDescription  = ProductProperties.Description;
	TableSectionRow.UnitSet             = ProductProperties.UnitSet;
	TableSectionRow.Unit                = UnitSetProperties.DefaultSaleUnit;
	TableSectionRow.Taxable             = ProductProperties.Taxable;
	TableSectionRow.DiscountIsTaxable   = ProductProperties.DiscountIsTaxable;
	If Object.UseAvatax Then
		TableSectionRow.AvataxTaxCode   = ProductProperties.TaxCode;
	EndIf;
	TableSectionRow.PriceUnits          = Round(GeneralFunctions.RetailPrice(Object.Date, TableSectionRow.Product, Object.Company) /
	                                     // The price is returned for default sales unit factor.
	                                     ?(Object.ExchangeRate > 0, Object.ExchangeRate, 1), GeneralFunctionsReusable.PricePrecisionForOneItem(TableSectionRow.Product));
	
	// Make lots & serial numbers columns visible.
	LotsSerialNumbers.UpdateLotsSerialNumbersVisibility(ProductProperties, Items, 1, TableSectionRow.UseLotsSerials);
	
	// Fill lot owner.
	LotsSerialNumbers.FillLotOwner(ProductProperties, TableSectionRow.LotOwner);
	
	// Clear serial numbers.
	TableSectionRow.SerialNumbers = "";
	LineItemsSerialNumbersOnChangeAtServer(TableSectionRow);
	
	// Clear up order data.
	TableSectionRow.Order              = Documents.SalesOrder.EmptyRef();
	TableSectionRow.DeliveryDate       = '00010101';
	TableSectionRow.Location           = Catalogs.Locations.EmptyRef();
	
	// Reset default values.
	TableSectionRow.DeliveryDateActual = Object.DeliveryDateActual;
	TableSectionRow.LocationActual     = Object.LocationActual;
	TableSectionRow.Project            = Object.Project;
	TableSectionRow.Class              = Object.Class;
	
	// Assign default quantities.
	TableSectionRow.QtyUnits  = 0;
	TableSectionRow.QtyUM     = 0;
	TableSectionRow.Invoiced  = 0;
	
	// Calculate totals by line.
	TableSectionRow.LineTotal     = 0;
	TableSectionRow.TaxableAmount = 0;
	
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
	RecalculateTotals(Object);
	
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
	RecalculateTotals(Object);
	
EndProcedure

&AtServer
Procedure LineItemsUnitOnChangeAtServer(TableSectionRow)
	
	// Calculate new unit price.
	TableSectionRow.PriceUnits = Round(GeneralFunctions.RetailPrice(Object.Date, TableSectionRow.Product, Object.Company) *
	                             ?(TableSectionRow.Unit.Factor > 0, TableSectionRow.Unit.Factor, 1) /
	                             ?(TableSectionRow.UnitSet.DefaultSaleUnit.Factor > 0, TableSectionRow.UnitSet.DefaultSaleUnit.Factor, 1) /
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
	RecalculateTotals(Object);
	
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
	RecalculateTotals(Object);
	
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
	TableSectionRow.PriceUnits = ?(TableSectionRow.QtyUnits > 0,
	                             Round(TableSectionRow.LineTotal / Round(TableSectionRow.QtyUnits, QuantityPrecision), GeneralFunctionsReusable.PricePrecisionForOneItem(TableSectionRow.Product)), 0);
								 
	// Load processed data back.
	FillPropertyValues(Items.LineItems.CurrentData, TableSectionRow);
	
	// Refresh totals cache.
	RecalculateTotals(Object);
	
EndProcedure

&AtServer
Procedure LineItemsLineTotalOnChangeAtServer(TableSectionRow)
	
	// Back-calculation of quantity in base units.
	TableSectionRow.QtyUM = Round(Round(TableSectionRow.QtyUnits, QuantityPrecision) *
	                        ?(TableSectionRow.Unit.Factor > 0, TableSectionRow.Unit.Factor, 1), QuantityPrecision);
	
	// Calculate taxes by line total.
	LineItemsTaxableOnChangeAtServer(TableSectionRow);
	
EndProcedure

&AtClient
Procedure LineItemsTaxableOnChange(Item)
	
	// Fill line data for editing.
	TableSectionRow = GetLineItemsRowStructure();
	FillPropertyValues(TableSectionRow, Items.LineItems.CurrentData);
	
	// Request server operation.
	LineItemsTaxableOnChangeAtServer(TableSectionRow);
	
	// Load processed data back.
	FillPropertyValues(Items.LineItems.CurrentData, TableSectionRow);
	
	// Refresh totals cache.
	RecalculateTotals(Object);
	
EndProcedure

&AtServer
Procedure LineItemsTaxableOnChangeAtServer(TableSectionRow)
	
	//// Calculate sales tax by line total.
	If TableSectionRow.Taxable Then
		If Object.DiscountTaxability = Enums.DiscountTaxability.NonTaxable Then
			TableSectionRow.TaxableAmount = TableSectionRow.LineTotal - Round(TableSectionRow.LineTotal * Object.DiscountPercent/100, 2);
		ElsIf Object.DiscountTaxability = Enums.DiscountTaxability.Taxable Then
			TableSectionRow.TaxableAmount = TableSectionRow.LineTotal;
		Else
			TableSectionRow.TaxableAmount = TableSectionRow.LineTotal - ?(TableSectionRow.DiscountIsTaxable, 0, Round(TableSectionRow.LineTotal * Object.DiscountPercent/100, 2));
		EndIf;
	Else
		TableSectionRow.TaxableAmount = 0;
	EndIf;
	RecalculateTotals(Object);
	
EndProcedure

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region COMMANDS_HANDLERS

//------------------------------------------------------------------------------
// Check if document has been posted, return bool value.

&AtServer
Function IsPosted()
	Return Object.Ref.Posted;	
EndFunction

//------------------------------------------------------------------------------
// Call AvaTax to request sales tax values.

&AtClient
Procedure AvaTax(Command)
	
	FormParams = New Structure("ObjectRef", Object.Ref);
	OpenForm("InformationRegister.AvataxDetails.Form.AvataxDetails", FormParams, ThisForm,,,,, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure TaxEngineOnChange(Item)
	
	TaxEngineOnChangeAtServer();
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	//PerformanceMeasurementClientServer.StartTimeMeasurement("Shipment Post and Close");
		
	Try
		Write(New Structure("WriteMode, CloseAfterWrite", DocumentWriteMode.Posting, True));
	Except
		MessageText = BriefErrorDescription(ErrorInfo());
		ShowMessageBox(, MessageText);
	EndTry;
	
EndProcedure

&AtClient
Procedure Save(Command)
	
	//PerformanceMeasurementClientServer.StartTimeMeasurement("Shipment Save");
	
	Try
		Write();
	Except
		MessageText = BriefErrorDescription(ErrorInfo());
		ShowMessageBox(, MessageText);
	EndTry;
	
EndProcedure

&AtClient
Procedure Post(Command)
	
	//PerformanceMeasurementClientServer.StartTimeMeasurement("Shipment Post");
	
	Try
		Write(New Structure("WriteMode", DocumentWriteMode.Posting));
	Except
		MessageText = BriefErrorDescription(ErrorInfo());
		ShowMessageBox(, MessageText);
	EndTry;
	
EndProcedure

&AtClient
Procedure ClearPosting(Command)
	
	If Object.Posted Then
		
		Try
			Write(New Structure("WriteMode", DocumentWriteMode.UndoPosting));
		Except
			MessageText = BriefErrorDescription(ErrorInfo());
			ShowMessageBox(, MessageText);
		EndTry;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AddLine(Command)
	
	Items.LineItems.AddRow();
	
EndProcedure

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region PRIVATE_IMPLEMENTATION

//------------------------------------------------------------------------------
// Calculate values of form object attributes.

&AtServer
// Request shipment status from database.
Procedure FillShipmentStatusAtServer()
	
	// Request shipment status.
	If (Not ValueIsFilled(Object.Ref)) Or (Object.DeletionMark) Or (Not Object.Posted) Then
		// The shipment has open status.
		ShipmentStatus = Enums.OrderStatuses.Open;
		
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
		
		// Fill shipment status.
		If Selection.Next() Then
			ShipmentStatus = Selection.Status;
		Else
			ShipmentStatus = Enums.OrderStatuses.Open;
		EndIf;
	EndIf;
	
	// Fill extended shipment status presentation (depending of document state).
	If Not ValueIsFilled(Object.Ref) Then
		ShipmentStatusPresentation = String(Enums.OrderStatuses.New);
		Items.ShipmentStatusPresentation.TextColor = WebColors.DarkGray;
		
	ElsIf Object.DeletionMark Then
		ShipmentStatusPresentation = String(Enums.OrderStatuses.Deleted);
		Items.ShipmentStatusPresentation.TextColor = WebColors.DarkGray;
		
	ElsIf Not Object.Posted Then
		ShipmentStatusPresentation = String(Enums.OrderStatuses.Draft);
		Items.ShipmentStatusPresentation.TextColor = WebColors.DarkGray;
		
	Else
		ShipmentStatusPresentation = String(ShipmentStatus);
		If ShipmentStatus = Enums.OrderStatuses.Closed Then 
			ThisForm.Items.ShipmentStatusPresentation.TextColor = WebColors.DarkGreen;
		ElsIf ShipmentStatus = Enums.OrderStatuses.Backordered Then 
			ThisForm.Items.ShipmentStatusPresentation.TextColor = WebColors.DarkGoldenRod;
		ElsIf ShipmentStatus = Enums.OrderStatuses.Open Then
			ThisForm.Items.ShipmentStatusPresentation.TextColor = WebColors.DarkRed;
		Else
			ThisForm.Items.ShipmentStatusPresentation.TextColor = WebColors.DarkGray;
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
			|	LineItems.LineNumber                     AS LineNumber,
			//  Request dimensions
			|	OrdersRegisteredBalance.Product          AS Product,
			|	OrdersRegisteredBalance.Unit             AS Unit,
			|	OrdersRegisteredBalance.Location         AS Location,
			|	OrdersRegisteredBalance.DeliveryDate     AS DeliveryDate,
			|	OrdersRegisteredBalance.Project          AS Project,
			|	OrdersRegisteredBalance.Class            AS Class,
			|	OrdersRegisteredBalance.Order            AS Order,
			//  Request resources                                                                                               // ---------------------------------------
			|	OrdersRegisteredBalance.ShippedShipmentBalance 
			|                                            AS QtyUnits,
			|	OrdersRegisteredBalance.InvoicedBalance  AS Invoiced
			//  Request sources
			|FROM
			|	Document.Shipment.LineItems              AS LineItems
			|	LEFT JOIN AccumulationRegister.OrdersRegistered.Balance(,Shipment = &Ref)
			|	                                         AS OrdersRegisteredBalance
			|		ON    ( LineItems.Ref.Company         = OrdersRegisteredBalance.Company
			|			AND LineItems.Order               = OrdersRegisteredBalance.Order
			|			AND LineItems.Ref                 = OrdersRegisteredBalance.Shipment
			|			AND LineItems.Product             = OrdersRegisteredBalance.Product
			|			AND LineItems.Unit                = OrdersRegisteredBalance.Unit
			|			AND LineItems.Location            = OrdersRegisteredBalance.Location
			|			AND LineItems.DeliveryDate        = OrdersRegisteredBalance.DeliveryDate
			|			AND LineItems.Project             = OrdersRegisteredBalance.Project
			|			AND LineItems.Class               = OrdersRegisteredBalance.Class
			|			AND LineItems.QtyUnits            = OrdersRegisteredBalance.ShippedShipmentBalance)
			//  Request filtering
			|WHERE
			|	LineItems.Ref = &Ref
			//  Request ordering
			|ORDER BY
			|	LineItems.LineNumber";
		Selection = Query.Execute().Select();
		
		// Fill ordered items quantities
		SearchRec = New Structure("LineNumber, Product, Unit, Location, DeliveryDate, Project, Class, Order, QtyUnits");
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
		|	OrdersRegisteredBalance.Company,
		|	OrdersRegisteredBalance.Order,
		|	OrdersRegisteredBalance.Product,
		|	OrdersRegisteredBalance.Unit,
		|	OrdersRegisteredBalance.Location,
		|	OrdersRegisteredBalance.DeliveryDate,
		|	OrdersRegisteredBalance.Project,
		|	OrdersRegisteredBalance.Class
		|FROM
		|	AccumulationRegister.OrdersRegistered.Balance(
		|			,
		|			Company = &Company
		|				AND Order.UseShipment = TRUE) AS OrdersRegisteredBalance
		|WHERE
		|	OrdersRegisteredBalance.QuantityBalance - OrdersRegisteredBalance.ShippedBalance > 0";
	Query.Text  = QueryText;
	
	// Assign true if there are open or backordered orders
	CompanyHasNonClosedOrders = Not Query.Execute().IsEmpty();
	
EndProcedure

&AtServer
// Fills document on the base of passed array of orders.
// Returns flag o successfull filing.
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
			LotsSerialNumbers.UpdateLotsSerialNumbersVisibility(Row.Product, Items, 1, Row.UseLotsSerials);
			// Fill lot owner.
			LotsSerialNumbers.FillLotOwner(Row.Product, Row.LotOwner);
			// Load serial numbers.
			LotsSerialNumbers.FillSerialNumbers(Object.SerialNumbers, Row.Product, 1, Row.LineID, Row.SerialNumbers);
		EndDo;
		
		//Check sales tax rates in the selected orders
		//If they differ  - show a message to the user
		CheckOrdersSalesTaxRates(SelectedOrders);		
		
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

&AtServer
Procedure CheckOrdersSalesTaxRates(SelectedOrders)
	SingleTaxRateSetting = True;
	SingleDiscountIsTaxableSetting = True;
	CurrentTaxRate = Undefined;
	CurrentDiscountIsTaxable = Undefined;
	For Each SelectedOrder In SelectedOrders Do
		If (CurrentTaxRate = Undefined) And (CurrentDiscountIsTaxable = Undefined) Then
			CurrentTaxRate = SelectedOrder.SalesTaxRate;
			CurrentDiscountIsTaxable = SelectedOrder.DiscountIsTaxable;
		Else
			If CurrentTaxRate <> SelectedOrder.SalesTaxRate Then
				SingleTaxRateSetting = False;
			EndIf;
			If CurrentDiscountIsTaxable <> SelectedOrder.DiscountIsTaxable Then
				SingleDiscountIsTaxableSetting = False;
			EndIf;
		EndIf;
	EndDo;
	If Not SingleTaxRateSetting Then
		UM = New UserMessage();
		UM.Field 	= "SalesTaxRate";
		UM.Text 	= "Base orders have different sales tax rates. Please, check document sales tax rate.";
		UM.Message();
	EndIf;
	If Not SingleDiscountIsTaxableSetting Then
		UM = New UserMessage();
		UM.SetData(Object);
		UM.Field 	= "Object.DiscountIsTaxable";
		UM.Text 	= "Base orders have different sales tax settings. Please, check document ""Discount is taxable"" setting.";
		UM.Message();
	EndIf;
	
EndProcedure
//------------------------------------------------------------------------------
// Calculate totals and fill object attributes.

// The procedure recalculates the document's totals.
&AtClientAtServerNoContext
Procedure RecalculateTotals(Object)
	
	// Calculate document totals.
	LineSubtotal 	= 0;
	TaxableSubtotal = 0;
	Discount		= 0;
	For Each Row In Object.LineItems Do
		LineSubtotal 	= LineSubtotal  + Row.LineTotal;
		Discount 		= Discount + Round(-1 * Row.LineTotal * Object.DiscountPercent/100, 2);
		// Calculate taxable amount by line total.
		RowTaxableAmount = 0;
		If Row.Taxable Then
			If Object.DiscountTaxability = PredefinedValue("Enum.DiscountTaxability.NonTaxable") Then
				RowTaxableAmount = Row.LineTotal - Round(Row.LineTotal * Object.DiscountPercent/100, 2);
			ElsIf Object.DiscountTaxability = PredefinedValue("Enum.DiscountTaxability.Taxable") Then
				RowTaxableAmount = Row.LineTotal;
			Else
				RowTaxableAmount = Row.LineTotal - ?(Row.DiscountIsTaxable, 0, Round(Row.LineTotal * Object.DiscountPercent/100, 2));
			EndIf;
		Else
			RowTaxableAmount = 0;
		EndIf;

		TaxableSubtotal = TaxableSubtotal + RowTaxableAmount;
	EndDo;
	
	// Assign totals to the object fields.
	Object.LineSubtotal = LineSubtotal;
	// Recalculate the discount and it's percent.
	Object.Discount		= Discount;
	If Object.Discount < -Object.LineSubtotal Then
		Object.Discount = -Object.LineSubtotal;
	EndIf;
		
	//Calculate sales tax
	If Not Object.UseAvatax Then //Recalculate sales tax only if using AccountingSuite sales tax engine
		Object.TaxableSubtotal = TaxableSubtotal;
		CurrentAgenciesRates = Undefined;
		If Object.SalesTaxAcrossAgencies.Count() > 0 Then
			CurrentAgenciesRates = New Array();
			For Each AgencyRate In Object.SalesTaxAcrossAgencies Do
				CurrentAgenciesRates.Add(New Structure("Agency, Rate, SalesTaxRate, SalesTaxComponent", AgencyRate.Agency, AgencyRate.Rate, AgencyRate.SalesTaxRate, AgencyRate.SalesTaxComponent));
			EndDo;
		EndIf;
		#If Client Then
		SalesTaxAcrossAgencies = SalesTaxClient.CalculateSalesTax(Object.TaxableSubtotal, Object.SalesTaxRate, CurrentAgenciesRates);
		#EndIf
		#If Server Then
		SalesTaxAcrossAgencies = SalesTax.CalculateSalesTax(Object.TaxableSubtotal, Object.SalesTaxRate, CurrentAgenciesRates);
		#EndIf
		Object.SalesTaxAcrossAgencies.Clear();
		For Each STAcrossAgencies In SalesTaxAcrossAgencies Do 
			NewRow = Object.SalesTaxAcrossAgencies.Add();
			FillPropertyValues(NewRow, STAcrossAgencies);
		EndDo;
	EndIf;
	Object.SalesTax = Object.SalesTaxAcrossAgencies.Total("Amount");
	
	// Calculate the rest of the totals.
	Object.SubTotal         = LineSubtotal + Object.Discount;
	Object.DocumentTotal    = Object.SubTotal + Object.Shipping + Object.SalesTax;
	
	Object.SalesTaxRC       = Round(Object.SalesTax * Object.ExchangeRate, 2);
	SubTotalRC				= Round(Object.SubTotal * Object.ExchangeRate, 2);
	ShippingRC				= Round(Object.Shipping * Object.ExchangeRate, 2);
	Object.DocumentTotalRC	= SubTotalRC + ShippingRC + Object.SalesTaxRC;

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

//------------------------------------------------------------------------------
// Replacemant for metadata properties on client.

&AtClient
// Returns fields structure of LineItems form control.
Function GetLineItemsRowStructure()
	
	// Define control row fields.
	Return New Structure("LineNumber, LineID, Product, ProductDescription, UseLotsSerials, LotOwner, Lot, SerialNumbers, UnitSet, QtyUnits, Unit, QtyUM, UM, Invoiced, PriceUnits, LineTotal, Taxable, TaxableAmount, Order, Location, LocationActual, DeliveryDate, DeliveryDateActual, Project, Class, AvataxTaxCode, DiscountIsTaxable");
	
EndFunction

&AtClient
Procedure SalesTaxRateOnChange(Item)
	SetSalesTaxRate(SalesTaxRate);	
EndProcedure

&AtClient
Procedure SetSalesTaxRate(NewSalesTaxRate)
	//Update SalesTaxRate field choice list
	If ValueIsFilled(NewSalesTaxRate) And (Items.SalesTaxRate.ChoiceList.FindByValue(NewSalesTaxRate) = Undefined) Then
		Items.SalesTaxRate.ChoiceList.Add(NewSalesTaxRate);
	EndIf;
	//Cache inactive sales tax rates
	If ValueIsFilled(Object.SalesTaxRate) Then
		AgenciesRates = New Array();
		For Each AgencyRate In Object.SalesTaxAcrossAgencies Do
			AgenciesRates.Add(New Structure("Agency, Rate, SalesTaxRate, SalesTaxComponent", AgencyRate.Agency, AgencyRate.Rate, AgencyRate.SalesTaxRate, AgencyRate.SalesTaxComponent));
		EndDo;
		If SalesTax.DocumentSalesTaxRateIsInactive(Object.SalesTaxRate, AgenciesRates) Then
			SalesTaxRateInactive = Object.SalesTaxRate;
			AgenciesRatesInactive = AgenciesRates;
		EndIf;
	EndIf;
	//Restore inactive sales tax rates
	If TypeOf(NewSalesTaxRate) = Type("Number") Then //user returned inactive sales tax rate
		Object.SalesTaxRate = SalesTaxRateInactive;
		Object.SalesTaxAcrossAgencies.Clear();
		For Each AgencyRateInactive In AgenciesRatesInactive Do
			FillPropertyValues(Object.SalesTaxAcrossAgencies.Add(), AgencyRateInactive);
		EndDo;
	Else
		Object.SalesTaxRate = NewSalesTaxRate;
		Object.SalesTaxAcrossAgencies.Clear();
	EndIf;
	DisplaySalesTaxRate(ThisForm);
	RecalculateTotals(Object);
EndProcedure

&AtClientAtServerNoContext
Procedure DisplaySalesTaxRate(Form)
	
	If Not GeneralFunctionsReusable.FunctionalOptionValue("SalesTaxCharging") Then
		return;
	EndIf;
	
	Object = Form.Object;
	TaxRate = 0;
	If Not Object.UseAvatax Then
		If Object.SalesTaxAcrossAgencies.Count() = 0 Then
			SalesTaxRateAttr = CommonUse.GetAttributeValues(Object.SalesTaxRate, "Rate");
			TaxRate = SalesTaxRateAttr.Rate;
		Else
			TaxRate = Object.SalesTaxAcrossAgencies.Total("Rate");
		EndIf;
	Else //When using Avatax some lines are taxable and others not
		If Object.TaxableSubtotal <> 0 Then
			TaxRate = Round(Object.SalesTax/Object.TaxableSubtotal, 4) * 100;
		EndIf;
	EndIf;
	SalesTaxRateText = "Tax rate: " + String(TaxRate) + "%";
	Form.Items.SalesTaxPercentDecoration.Title = SalesTaxRateText;
	
EndProcedure

&AtClient
Procedure DiscountIsTaxableOnChange(Item)
	
	RecalculateTotals(Object);
	
EndProcedure

&AtServer
Procedure TaxEngineOnChangeAtServer()
	
	//Tax engine depends on company settings
	If GeneralFunctionsReusable.FunctionalOptionValue("AvataxEnabled") Then
		CompanyAvataxSetting = ?(Object.Company.UseAvatax, 2, 1);
		If TaxEngine <> CompanyAvataxSetting Then
			TaxEngine = CompanyAvataxSetting;
			CommonUseClientServer.MessageToUser("Please change company tax settings first", Object, "TaxEngine");
			return;
		EndIf;
	Else
		TaxEngine = 1; //AccountingSuite
	EndIf;
	Object.UseAvaTax = ?(TaxEngine = 1, False, True);	
	Object.SalesTaxAcrossAgencies.Clear();
	ApplySalesTaxEngineSettings();
	If Object.UseAvatax Then
		//AvataxServer.RestoreCalculatedSalesTax(Object);
	EndIf;
	RecalculateTotals(Object);
	
	DisplaySalesTaxRate(ThisForm);
	
EndProcedure

&AtServer
Procedure ApplySalesTaxEngineSettings()
	
	//Without AvataxEnabled allow changing of an engine only for documents, using AvaTax
	If GeneralFunctionsReusable.FunctionalOptionValue("AvataxEnabled") Then
		Items.TaxEngine.Visible = True;
	Else
		If (Not Object.Ref.IsEmpty()) And (Object.UseAvatax) Then
			Items.TaxEngine.Visible = True;
		Else
			Items.TaxEngine.Visible = False;
		EndIf;
	EndIf;
	
	If Not Object.UseAvatax Then
		Items.SalesTaxRate.ChoiceList.Clear();
		ListOfAvailableTaxRates = SalesTax.GetSalesTaxRatesList();
		For Each TaxRateItem In ListOfAvailableTaxRates Do
			Items.SalesTaxRate.ChoiceList.Add(TaxRateItem.Value, TaxRateItem.Presentation);
		EndDo;
		SalesTaxRate = Object.SalesTaxRate;
		Items.TaxParametersPages.CurrentPage = Items.TaxParametersInACS;
		Items.LineItemsTaxable.Visible		= True;
		Items.LineItemsAvataxTaxCode.Visible = False;
	ElsIf Object.UseAvatax Then
		If Object.Ref.IsEmpty() Then
			Object.AvataxShippingTaxCode = Constants.AvataxDefaultShippingTaxCode.Get();
		EndIf;
		Items.TaxParametersPages.CurrentPage = Items.TaxParametersInAvaTax;
		Items.LineItemsTaxable.Visible		= False;
		Items.LineItemsAvataxTaxCode.Visible = True;
	EndIf;

EndProcedure

&AtClient
Procedure DiscountTaxabilityOnChange(Item)
	
	For Each LineItem In Object.LineItems Do
		If Object.DiscountTaxability = PredefinedValue("Enum.DiscountTaxability.NonTaxable") Then
			LineItem.TaxableAmount = LineItem.LineTotal + Round(-1 * LineItem.LineTotal * Object.DiscountPercent/100, 2);
		ElsIf Object.DiscountTaxability = PredefinedValue("Enum.DiscountTaxability.Taxable") Then
			LineItem.TaxableAmount = LineItem.LineTotal;
		Else
			LineItem.TaxableAmount = LineItem.LineTotal - ?(LineItem.DiscountIsTaxable, 0, Round(LineItem.LineTotal * Object.DiscountPercent/100, 2));
		EndIf;
	EndDo;
	SetDiscountTaxabilityAppearance(ThisForm);
	RecalculateTotals(Object);
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetDiscountTaxabilityAppearance(ThisForm)
	
	Object 	= ThisForm.Object;
	Items 	= ThisForm.Items;
	If Object.DiscountTaxability = PredefinedValue("Enum.DiscountTaxability.ByProductSetting") Then
		Items.LineItemsDiscountIsTaxable.Visible = True;
	Else
		Items.LineItemsDiscountIsTaxable.Visible = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure LineItemsDiscountIsTaxableOnChange(Item)
	
	LineItem = Items.LineItems.CurrentData;
	If Object.DiscountTaxability = PredefinedValue("Enum.DiscountTaxability.NonTaxable") Then
		LineItem.TaxableAmount = LineItem.LineTotal + Round(-1 * LineItem.LineTotal * Object.DiscountPercent/100, 2);
	ElsIf Object.DiscountTaxability = PredefinedValue("Enum.DiscountTaxability.Taxable") Then
		LineItem.TaxableAmount = LineItem.LineTotal;
	Else
		LineItem.TaxableAmount = LineItem.LineTotal - ?(LineItem.DiscountIsTaxable, 0, Round(LineItem.LineTotal * Object.DiscountPercent/100, 2));
	EndIf;
	RecalculateTotals(Object);
	
EndProcedure

Function ShowAddressDecoration(AddressRef)
	
	addressline1 = AddressRef.AddressLine1;
	If AddressRef.AddressLine1 <> "" AND (AddressRef.AddressLine2 <> "" OR AddressRef.AddressLine3 <> "") Then
		addressline1 = addressline1 + ", ";
	EndIf;
	addressline2 = AddressRef.AddressLine2;
	If AddressRef.AddressLine2 <> "" AND AddressRef.AddressLine3 <> "" Then
		addressline2 = addressline2 + ", ";
	EndIf;
	addressline3 = AddressRef.AddressLine3;
	city = AddressRef.City;
	If AddressRef.City <> "" AND (String(AddressRef.State.Code) <> "" OR AddressRef.ZIP <> "") Then
		city = city + ", ";
	EndIf;
	state = String(AddressRef.State.Code);
	If String(AddressRef.State.Code) <> "" Then
		state = state + "  ";
	EndIf;
	zip = AddressRef.ZIP;
	If AddressRef.ZIP <> "" Then
		zip = zip + Chars.LF;
	EndIf;
	country = String(AddressRef.Country.Description);
	If String(AddressRef.Country.Description) <> "" Then
		country = country;
	EndIf;
	
	If addressline1 <> "" OR addressline2 <> "" OR addressline3 <> "" Then 	
		Return addressline1 + addressline2 + addressline3 + Chars.LF + city + state + zip + country;
	Else
		Return city + state + zip + country;
	EndIf;
	
EndFunction

&AtClient
Procedure BillToOnChange(Item)
	Items.DecorationBillTo.Visible = True;
	Items.DecorationBillTo.Title = GeneralFunctions.ShowAddressDecoration(Object.BillTo);
EndProcedure

#EndRegion
