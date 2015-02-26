
////////////////////////////////////////////////////////////////////////////////
// Sales order: Document form
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
		If Not ValueIsFilled(Object.DiscountType) Then
			Object.DiscountType = Enums.DiscountType.Percent;
		EndIf;
	EndIf;
	
	If Parameters.Property("Company") And Parameters.Company.Customer And Object.Ref.IsEmpty() Then
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
	Items.LineItemsShipped.EditFormat   = QuantityFormat;
	Items.LineItemsShipped.Format       = QuantityFormat;
	Items.LineItemsInvoiced.EditFormat  = QuantityFormat;
	Items.LineItemsInvoiced.Format      = QuantityFormat;
	Items.LineItemsBackorder.EditFormat = QuantityFormat;
	Items.LineItemsBackorder.Format     = QuantityFormat;
	
	// Update prices presentation.
	PriceFormat = GeneralFunctionsReusable.DefaultPriceFormat();
	Items.LineItemsPrice.EditFormat  = PriceFormat;
	Items.LineItemsPrice.Format      = PriceFormat;
	
	// Set lots and serial numbers visibility.
	Items.LineItemsLot.Visible           = False;
	For Each Row In Object.LineItems Do
		// Make lots column visible.
		LotsSerialNumbers.UpdateLotsSerialNumbersVisibility(Row.Product, Items, 1, Row.UseLotsSerials);
		// Fill lot owner.
		LotsSerialNumbers.FillLotOwner(Row.Product, Row.LotOwner);
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
				If ValueIsFilled(Parameters.Basis) Then //If filled on the basis of Quote
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
	
	// Update visibility of controls depending on functional options.
	If Not GeneralFunctionsReusable.FunctionalOptionValue("MultiCurrency") Then
		//Items.FCYGroup.Visible     = False;
		Items.RCCurrency.Title 	= " "; 
	EndIf;
	
	// Cancel opening form if filling on the base was failed
	If Object.Ref.IsEmpty() And Parameters.Basis <> Undefined
	And Object.Company <> Parameters.Basis.Company Then
		// Object is not filled as expected
		Cancel = True;
		Return;
	EndIf;
	
	UpdateInformationPO();
	
	If Object.Ref.IsEmpty() Then
		Object.EmailNote = Constants.SalesOrderFooter.Get();
	EndIf;
	
	If Object.CreatedFromZoho = True Then
		taxQuery = new Query("SELECT
							 |	SalesTaxRates.Ref
							 |FROM
							 |	Catalog.SalesTaxRates AS SalesTaxRates
							 |WHERE
							 |	SalesTaxRates.Description = &Description");
						   
		taxQuery.SetParameter("Description", "TaxFromZoho"); // zoho product id
		taxResult = taxQuery.Execute().Unload();
		SalesTaxRate = taxResult[0].ref;
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
	
EndProcedure

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
	AvaTaxClient.ShowQueryToTheUserOnAvataxCalculation("SalesOrder", Object, ThisObject, WriteParameters, Cancel);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	//Period closing
	If PeriodClosingServerCall.DocumentPeriodIsClosed(CurrentObject.Ref, CurrentObject.Date) Then
		PermitWrite = PeriodClosingServerCall.DocumentWritePermitted(WriteParameters);
		CurrentObject.AdditionalProperties.Insert("PermitWrite", PermitWrite);	
	EndIf;
	
	//Avatax calculation
	AvaTaxServer.CalculateTaxBeforeWrite(CurrentObject, WriteParameters, Cancel, "SalesOrder");
	
EndProcedure
// <- CODE REVIEW

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	If FirstNumber <> "" Then
		
		Numerator = Catalogs.DocumentNumbering.SalesOrder.GetObject();
		NextNumber = GeneralFunctions.Increment(Numerator.Number);
		If FirstNumber = NextNumber And NextNumber = Object.Number Then
			Numerator.Number = FirstNumber;
			Numerator.Write();
		EndIf;
		
		FirstNumber = "";
	EndIf;
	
	//------------------------------------------------------------------------------
	// Recalculate values of form object attributes.
	
	// Request and fill order status from database.
	FillOrderStatusAtServer();
	
	// Request and fill ordered items from database.
	FillBackorderQuantityAtServer();
	
	// Refill lots and serial numbers values.
	For Each Row In Object.LineItems Do
		// Make lots column visible.
		LotsSerialNumbers.UpdateLotsSerialNumbersVisibility(Row.Product, Items, 1, Row.UseLotsSerials);
		// Fill lot owner.
		LotsSerialNumbers.FillLotOwner(Row.Product, Row.LotOwner);
	EndDo;
	
	
	If Constants.zoho_auth_token.Get() <> "" Then
		If Object.NewObject = True Then
			ThisAction = "create";
		Else
			ThisAction = "update";
		EndIf;
		zoho_Functions.ZohoThisSO(ThisAction, Object.Ref);
	EndIf;
	
	//Avatax calculation
	//AvaTaxServer.CalculateTaxAfterWrite(CurrentObject, WriteParameters, "SalesOrder");
	
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
	
	If EventName = "UpdatePOInformation" And Parameter = Object.Ref Then
		
		UpdateInformationPO();
		
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
	
	// Ask user about updating the setting and update the line items accordingly.
	CommonDefaultSettingOnChange(Item, "price");
	
EndProcedure

&AtServer
Procedure CompanyOnChangeAtServer()
	
	// Reset company adresses (if company was changed).
	FillCompanyAddressesAtServer(Object.Company, Object.ShipTo, Object.BillTo, Object.ConfirmTo);
	
	// Request company default settings.
	Object.Currency    = Object.Company.DefaultCurrency;
	Object.SalesPerson = Object.Company.SalesPerson;
	
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
		AvataxServer.RestoreCalculatedSalesTax(Object);
	EndIf;	
	
	RecalculateTotals(Object);
	DisplaySalesTaxRate(ThisForm);
	
	Items.DecorationBillTo.Visible = True;
	Items.DecorationShipTo.Visible = True;
	Items.DecorationShipTo.Title = GeneralFunctions.ShowAddressDecoration(Object.ShipTo);
	Items.DecorationBillTo.Title = GeneralFunctions.ShowAddressDecoration(Object.BillTo);
		
EndProcedure

&AtClient
Procedure UseShipmentOnChange(Item)
	
	If (Not Object.Ref.IsEmpty()) AND (DocumentUsed(Object.Ref)) Then
		
		Object.UseShipment = Not Object.UseShipment; 
		
		UM = New UserMessage;
		UM.Text = NStr("en = 'You cannot change the attribute ""Use Shipment"" because this document is used in other documents!'");
		UM.Field = "Object.UseShipment";
		UM.Message();
		
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
	
	// Recalculate the tax rate depending on the shipping address.
	//TaxRate = ?(Not Object.ShipTo.IsEmpty(), 0, 0); // GetTaxRate(Object.ShipTo)
	
	// Recalculate totals with new tax rate.
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
	Items.FCYCurrency.Title          = ForeignCurrencySymbol;
	Items.TaxableSubtotalCurrency.Title = ForeignCurrencySymbol;
	
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
	RecalculateTotals(Object);
	
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
Procedure DiscountPercentOnChange(Item)
	
	// Fill line data for editing.
	TableSectionRow = GetLineItemsRowStructure();
	LineItemsCurrentData = Items.LineItems.CurrentData;
	If LineItemsCurrentData <> Undefined Then
		FillPropertyValues(TableSectionRow, LineItemsCurrentData);
	EndIf;
	
	// Request server operation.
	DiscountPercentOnChangeAtServer(TableSectionRow);

EndProcedure

&AtServer
Procedure DiscountPercentOnChangeAtServer(TableSectionRow)
	
	// Recalculate discount value by it's percent.
	Object.Discount = Round(-1 * Object.LineSubtotal * Object.DiscountPercent/100, 2);
	
	// Recalculate totals with new discount.
	RecalculateTotals(Object);
	
	UpdateInformationCurrentRow(TableSectionRow);
	
EndProcedure

&AtClient
Procedure DiscountOnChange(Item)
	
	// Fill line data for editing.
	TableSectionRow = GetLineItemsRowStructure();
	LineItemsCurrentData = Items.LineItems.CurrentData;
	If LineItemsCurrentData <> Undefined Then
		FillPropertyValues(TableSectionRow, LineItemsCurrentData);
	EndIf;
	
	// Request server operation.
	DiscountOnChangeAtServer(TableSectionRow);
		
EndProcedure

&AtServer
Procedure DiscountOnChangeAtServer(TableSectionRow)
	
	// Discount can not override the total.
	If Object.Discount < -Object.LineSubtotal Then
		Object.Discount = - Object.LineSubtotal;
	EndIf;
	
	// Recalculate discount value by it's percent.
	If Object.LineSubtotal > 0 Then
		Object.DiscountPercent = Round(-1 * 100 * Object.Discount / Object.LineSubtotal, 2);
	EndIf;
	
	// Recalculate totals with new discount.
	RecalculateTotals(Object);
	
	UpdateInformationCurrentRow(TableSectionRow);
	
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
		ObjectData  = New Structure("Location, DeliveryDate, Project, Class");
		FillPropertyValues(ObjectData, Object);
		For Each ObjectField In ObjectData Do
			If Not ValueIsFilled(Item.CurrentData[ObjectField.Key]) Then
				Item.CurrentData[ObjectField.Key] = ObjectField.Value;
			EndIf;
		EndDo;
		
		// Refresh totals cache.
		RecalculateTotals(Object);
	EndIf;
	
EndProcedure

&AtClient
Procedure LineItemsOnActivateRow(Item)
	
	LineItemsCurrentData = Items.LineItems.CurrentData;
	If LineItemsCurrentData <> Undefined Then
		
		// Fill line data for editing.
		TableSectionRow = GetLineItemsRowStructure();
		FillPropertyValues(TableSectionRow, LineItemsCurrentData);
		
		UpdateInformationCurrentRow(TableSectionRow);
		
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
	ProductProperties = CommonUse.GetAttributeValues(TableSectionRow.Product,   New Structure("Ref, Description, UnitSet, HasLotsSerialNumbers, UseLots, UseLotsType, Characteristic, UseSerialNumbersOnShipment, Taxable, TaxCode, DiscountIsTaxable"));
	UnitSetProperties = CommonUse.GetAttributeValues(ProductProperties.UnitSet, New Structure("DefaultSaleUnit"));
	TableSectionRow.ProductDescription = ProductProperties.Description;
	TableSectionRow.UnitSet            = ProductProperties.UnitSet;
	TableSectionRow.Unit               = UnitSetProperties.DefaultSaleUnit;
	TableSectionRow.Taxable            = ProductProperties.Taxable;
	TableSectionRow.DiscountIsTaxable  = ProductProperties.DiscountIsTaxable;
	If Object.UseAvatax Then
		TableSectionRow.AvataxTaxCode  = ProductProperties.TaxCode;
	EndIf;
	TableSectionRow.PriceUnits         = Round(GeneralFunctions.RetailPrice(Object.Date, TableSectionRow.Product, Object.Company) /
	                                     // The price is returned for default sales unit factor.
	                                     ?(Object.ExchangeRate > 0, Object.ExchangeRate, 1), GeneralFunctionsReusable.PricePrecisionForOneItem(TableSectionRow.Product));
	
	// Make lots column visible.
	LotsSerialNumbers.UpdateLotsSerialNumbersVisibility(ProductProperties, Items, 1, TableSectionRow.UseLotsSerials);
	
	// Fill lot owner.
	LotsSerialNumbers.FillLotOwner(ProductProperties, TableSectionRow.LotOwner);
	
	// Reset default values.
	TableSectionRow.Location     = Object.Location;
	TableSectionRow.DeliveryDate = Object.DeliveryDate;
	TableSectionRow.Project      = Object.Project;
	TableSectionRow.Class        = Object.Class;
	
	// Assign default quantities.
	TableSectionRow.QtyUnits  = 0;
	TableSectionRow.QtyUM     = 0;
	TableSectionRow.Backorder = 0;
	TableSectionRow.Shipped   = 0;
	TableSectionRow.Invoiced  = 0;
	
	// Calculate totals by line.
	TableSectionRow.LineTotal     = 0;
	TableSectionRow.TaxableAmount = 0;
	
	UpdateInformationCurrentRow(TableSectionRow);
	
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
	
	// Update backorder quantity basing on document status.
	If OrderStatus = Enums.OrderStatuses.Open Then
		TableSectionRow.Backorder = 0;
		
	ElsIf OrderStatus = Enums.OrderStatuses.Backordered Then
		If TableSectionRow.Product.Type = Enums.InventoryTypes.Inventory Then
			TableSectionRow.Backorder = Max(TableSectionRow.QtyUnits - TableSectionRow.Shipped, 0);
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
	TableSectionRow.QtyUM      = Round(Round(TableSectionRow.QtyUnits, QuantityPrecision) *
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
	
	// Calculate sales tax by line total.
	TableSectionRow.TaxableAmount = ?(TableSectionRow.Taxable, TableSectionRow.LineTotal, 0);
	
	UpdateInformationCurrentRow(TableSectionRow);
	
EndProcedure

&AtClient
Procedure LineItemsTaxableAmountOnChange(Item)
	
	// Refresh totals cache.
	RecalculateTotals(Object);
	
EndProcedure

&AtClient
Procedure LineItemsLocationOnChange(Item)
	
	LineItemsCurrentData = Items.LineItems.CurrentData;
	If LineItemsCurrentData <> Undefined Then
		
		// Fill line data for editing.
		TableSectionRow = GetLineItemsRowStructure();
		FillPropertyValues(TableSectionRow, LineItemsCurrentData);
		
		UpdateInformationCurrentRow(TableSectionRow);
		
	EndIf;
	
EndProcedure

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region COMMANDS_HANDLERS

&AtClient
Procedure Transactions(Command)
	
	// Set filter by current order.
	FltrParameters = New Structure();
	FltrParameters.Insert("Order", Object.Ref);
	
	// Define form parameters filtering transactions by order.
	FormParameters = New Structure();
	FormParameters.Insert("Filter", FltrParameters);
	
	// Open form with selected filter.
	OpenForm("CommonForm.OrderTransactions", FormParameters, Object.Ref);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	Try
		Write(New Structure("WriteMode, CloseAfterWrite", DocumentWriteMode.Posting, True));
	Except
		MessageText = BriefErrorDescription(ErrorInfo());
		ShowMessageBox(, MessageText);
	EndTry;
	
EndProcedure

&AtClient
Procedure Save(Command)
	
	Try
		Write();
	Except
		MessageText = BriefErrorDescription(ErrorInfo());
		ShowMessageBox(, MessageText);
	EndTry;
	
EndProcedure

&AtClient
Procedure Post(Command)
	
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
Procedure POs(Command)
	
	FormParameters = New Structure();
	
	FltrParameters = New Structure();
	FltrParameters.Insert("BaseDocument", Object.Ref);
	FormParameters.Insert("Filter", FltrParameters);
	OpenForm("Document.PurchaseOrder.Form.ListFormForSO", FormParameters, Object.Ref);
	
EndProcedure

&AtClient
Procedure AddLine(Command)
	
	Items.LineItems.AddRow();
	
EndProcedure

&AtClient
Procedure AvaTax(Command)
	
	FormParams = New Structure("ObjectRef", Object.Ref);
	OpenForm("InformationRegister.AvataxDetails.Form.AvataxDetails", FormParams, ThisForm,,,,, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtServer
Procedure TaxEngineOnChangeAtServer()
	
	Object.UseAvaTax = ?(TaxEngine = 1, False, True);	
	Object.SalesTaxAcrossAgencies.Clear();
	ApplySalesTaxEngineSettings();
	If Object.UseAvatax Then
		AvataxServer.RestoreCalculatedSalesTax(Object);
	EndIf;
	RecalculateTotals(Object);
	DisplaySalesTaxRate(ThisForm);
	
EndProcedure

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
			|	OrdersRegisteredBalance.Product          AS Product,
			|	OrdersRegisteredBalance.Unit             AS Unit,
			|	OrdersRegisteredBalance.Location         AS Location,
			|	OrdersRegisteredBalance.DeliveryDate     AS DeliveryDate,
			|	OrdersRegisteredBalance.Project          AS Project,
			|	OrdersRegisteredBalance.Class            AS Class,
			//  Request resources                                                                                               // ---------------------------------------
			|	OrdersRegisteredBalance.QuantityBalance  AS QtyUnits,                                                           // Backorder quantity calculation
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
			|			AND LineItems.Unit                = OrdersRegisteredBalance.Unit
			|			AND LineItems.Location            = OrdersRegisteredBalance.Location
			|			AND LineItems.DeliveryDate        = OrdersRegisteredBalance.DeliveryDate
			|			AND LineItems.Project             = OrdersRegisteredBalance.Project
			|			AND LineItems.Class               = OrdersRegisteredBalance.Class
			|			AND LineItems.QtyUnits            = OrdersRegisteredBalance.QuantityBalance)
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
				FillPropertyValues(FoundLineItems[0], Selection, "Backorder, Shipped, Invoiced");
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

//------------------------------------------------------------------------------
// Calculate totals and fill object attributes.

// The procedure recalculates the document's totals.
&AtClientAtServerNoContext
Procedure RecalculateTotals(Object)
	
	// Calculate document totals.
	LineSubtotal 	= 0;
	TaxableSubtotal = 0;
	Discount		= 0;
	TotalDiscount	= -1 * Object.Discount;
	DiscountLeft	= TotalDiscount;
	For Each Row In Object.LineItems Do
		LineSubtotal 	= LineSubtotal  + Row.LineTotal;
		If Object.DiscountType = PredefinedValue("Enum.DiscountType.FixedAmount") Then
			RowDiscount = ?(Row.LineTotal = 0, 0, Round(Row.LineTotal/Object.LineItems.Total("LineTotal") * TotalDiscount, 2));
			RowDiscount = ?(RowDiscount>DiscountLeft, DiscountLeft, RowDiscount);
			DiscountLeft = DiscountLeft - RowDiscount;
			RowTaxableAmount = 0;
			If Row.Taxable Then
				If Object.DiscountTaxability = PredefinedValue("Enum.DiscountTaxability.NonTaxable") Then
					RowTaxableAmount = Row.LineTotal - RowDiscount;
				ElsIf Object.DiscountTaxability = PredefinedValue("Enum.DiscountTaxability.Taxable") Then
					RowTaxableAmount = Row.LineTotal;
				Else
					RowTaxableAmount = Row.LineTotal - ?(Row.DiscountIsTaxable, 0, RowDiscount);
				EndIf;
			Else
				RowTaxableAmount = 0;
			EndIf;
		Else //By percent
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
		EndIf;

		TaxableSubtotal = TaxableSubtotal + RowTaxableAmount;
	EndDo;
	
	// Assign totals to the object fields.
	Object.LineSubtotal = LineSubtotal;
	// Recalculate the discount and it's percent.
	If Object.DiscountType <> PredefinedValue("Enum.DiscountType.FixedAmount") Then
		Object.Discount		= Discount;
	Else
		Object.DiscountPercent = ?(Object.LineSubtotal <> 0, Round(-1 * 100 * Object.Discount / Object.LineSubtotal, 2), 0);
	EndIf;
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
	Return New Structure("LineNumber, LineID, Product, ProductDescription, UseLotsSerials, LotOwner, Lot, UnitSet, QtyUnits, Unit, QtyUM, UM, Backorder, Shipped, Invoiced, PriceUnits, LineTotal, Taxable, TaxableAmount, Location, DeliveryDate, Project, Class, AvataxTaxCode, DiscountIsTaxable");
	
EndFunction

//------------------------------------------------------------------------------
// New unsorted functions.

&AtClient
Procedure DiscountIsTaxableOnChange(Item)
	DiscountIsTaxableOnChangeAtServer();
	RecalculateTotals(Object);
EndProcedure

&AtServer
Procedure DiscountIsTaxableOnChangeAtServer()
	// Insert handler contents.
EndProcedure

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
	//Update tax rate
	DisplaySalesTaxRate(ThisForm);
	RecalculateTotals(Object);
	
EndProcedure

&AtClient
Procedure SendEmail(Command)
	If Object.Ref.IsEmpty() Then
		Message("An email cannot be sent until the sales order is posted");
	Else	
		FormParameters = New Structure("Ref",Object.Ref );
		OpenForm("CommonForm.EmailForm", FormParameters,,,,,, FormWindowOpeningMode.LockOwnerWindow);	
		//SendSOEmail();
	EndIf;
EndProcedure

&AtServer
Procedure SendSOEmail()
	// Insert handler contents.
EndProcedure

&AtClient
Procedure CopyMainShipping(Command)
	Object.DropshipCompany = Object.Company;
	Object.DropshipRefNum = Object.RefNum;
	Object.DropshipConfirmTo = Object.ConfirmTo;
	Object.DropshipShipTo = Object.ShipTo;
EndProcedure

&AtServer
Procedure UpdateInformationPO()
	
	Items.POs.Title = "no PO(-s)";
	Items.POs.TextColor = WebColors.Gray;
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	COUNT(DISTINCT PurchaseOrder.Ref) AS Qty
		|FROM
		|	Document.PurchaseOrder AS PurchaseOrder
		|WHERE
		|	PurchaseOrder.BaseDocument = &BaseDocument
		|	AND PurchaseOrder.BaseDocument <> VALUE(Document.SalesOrder.EmptyRef)";

	Query.SetParameter("BaseDocument", Object.Ref);

	QueryResult = Query.Execute();

	SelectionDetailRecords = QueryResult.Select();

	While SelectionDetailRecords.Next() Do
		
		If SelectionDetailRecords.Qty <> 0 Then
			Items.POs.Title = "" + SelectionDetailRecords.Qty + " PO(-s)";		
			Items.POs.TextColor = WebColors.Green;
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure UpdateInformationCurrentRow(CurrentRow)
	
	InformationCurrentRow = "";
	
	If CurrentRow.Product <> Undefined And CurrentRow.Product <> PredefinedValue("Catalog.Products.EmptyRef") Then
		
		LineItems = Object.LineItems.Unload(, "LineNumber, Product, QtyUM, LineTotal");
		
		LineItem = LineItems.Find(CurrentRow.LineNumber, "LineNumber");
		LineItem.Product   = CurrentRow.Product;
		LineItem.QtyUM     = CurrentRow.QtyUM;
		LineItem.LineTotal = CurrentRow.LineTotal;
		
		InformationCurrentRow = GeneralFunctions.GetMarginInformation(CurrentRow.Product, CurrentRow.Location, CurrentRow.QtyUM, CurrentRow.LineTotal,
																	  Object.Currency, Object.ExchangeRate, Object.DiscountPercent, LineItems); 
		InformationCurrentRow = "" + InformationCurrentRow;
		
	EndIf;
	
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
Procedure TaxEngineOnChange(Item)
	
	TaxEngineOnChangeAtServer();
	
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

&AtClient
Procedure BillToOnChange(Item)
	Items.DecorationBillTo.Visible = True;
	Items.DecorationBillTo.Title = GeneralFunctions.ShowAddressDecoration(Object.BillTo);
EndProcedure

&AtClient
Procedure DiscountTypeOnChange(Item)
	
	SetVisibilityByDiscount(ThisForm);
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetVisibilityByDiscount(ThisForm)
	
	Object = ThisForm.Object;
	If Object.DiscountType = PredefinedValue("Enum.DiscountType.FixedAmount") Then
		ThisForm.Items.DiscountPercent.Readonly = True;
		ThisForm.Items.Discount.Readonly = False;
	Else 
		ThisForm.Items.DiscountPercent.Readonly = False;
		ThisForm.Items.Discount.Readonly = True;
	EndIf;
	
EndProcedure

&AtServerNoContext
Function DocumentUsed(Ref)

	Query = New Query;
	Query.Text = 
		"SELECT
		|	ShipmentLineItems.Ref
		|INTO TemporaryTable
		|FROM
		|	Document.Shipment.LineItems AS ShipmentLineItems
		|WHERE
		|	ShipmentLineItems.Order = &Order
		|
		|UNION ALL
		|
		|SELECT
		|	SalesInvoiceLineItems.Ref
		|FROM
		|	Document.SalesInvoice.LineItems AS SalesInvoiceLineItems
		|WHERE
		|	SalesInvoiceLineItems.Order = &Order
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

#EndRegion
