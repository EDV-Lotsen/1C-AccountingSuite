
////////////////////////////////////////////////////////////////////////////////
// Cash sale: Document form
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
	
	If Parameters.Property("Company") And Parameters.Company.Customer And Object.Ref.IsEmpty() Then
		Object.Company = Parameters.Company;
	EndIf;
	
	//------------------------------------------------------------------------------
	// 1. Form attributes initialization.
	
	// Set LineItems editing flag.
	IsNewRow     = False;
	
	// Fill object attributes cache.
	Date = Object.Date;
	
	//------------------------------------------------------------------------------
	// 2. Calculate values of form object attributes.
	
	//------------------------------------------------------------------------------
	// 3. Set custom controls presentation.
	
	// Set proper company field presentation.
	CustomerName                    = GeneralFunctionsReusable.GetCustomerName();
	Items.Company.Title             = CustomerName;
	Items.Company.ToolTip           = StringFunctionsClientServer.SubstituteParametersInString(NStr("en = '%1 name'"),             CustomerName);
	Items.ShipTo.ToolTip            = StringFunctionsClientServer.SubstituteParametersInString(NStr("en = '%1 shipping address'"), CustomerName);
	Items.BillTo.ToolTip            = StringFunctionsClientServer.SubstituteParametersInString(NStr("en = '%1 billing address'"),  CustomerName);
	
	// Update quantities presentation.
	QuantityPrecision = GeneralFunctionsReusable.DefaultQuantityPrecision();
	QuantityFormat    = GeneralFunctionsReusable.DefaultQuantityFormat();
	Items.LineItemsQuantity.EditFormat  = QuantityFormat;
	Items.LineItemsQuantity.Format      = QuantityFormat;
	
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
	
	
	// -> CODE REVIEW
	If Object.BankAccount.IsEmpty() Then
		If Object.DepositType = "2" Then
			Object.BankAccount = Constants.BankAccount.Get();
		Else
			Object.BankAccount = Constants.UndepositedFundsAccount.Get();
		EndIf;
	EndIf;
	
	// Request tax rate for US sales tax calcualation.
	If GeneralFunctionsReusable.FunctionalOptionValue("SalesTaxCharging") Then
		//Fill the list of available tax rates
		ListOfAvailableTaxRates = SalesTax.GetSalesTaxRatesList();
		For Each TaxRateItem In ListOfAvailableTaxRates Do
			Items.SalesTaxRate.ChoiceList.Add(TaxRateItem.Value, TaxRateItem.Presentation);
		EndDo;
		If Object.Ref.IsEmpty() Then
			If Not ValueIsFilled(Parameters.Basis) Then
				Object.DiscountIsTaxable = True;
			Else //If filled on the basis of Sales Order
				RecalculateTotalsAtServer();
			EndIf;
			//If filled on the basis of Sales Order set current value
			SalesTaxRate = Object.SalesTaxRate;
		Else
			TaxRate = Object.SalesTaxAcrossAgencies.Total("Rate");
			SalesTaxRateText = "Sales tax rate: " + String(TaxRate) + "%";
			Items.SalesTaxPercentDecoration.Title = SalesTaxRateText;
			//Determine if document's sales tax rate is inactive (has been changed)
			AgenciesRates = New Array();
			For Each AgencyRate In Object.SalesTaxAcrossAgencies Do
				AgenciesRates.Add(New Structure("Agency, Rate", AgencyRate.Agency, AgencyRate.Rate));
			EndDo;
			If SalesTax.DocumentSalesTaxRateIsInactive(Object.SalesTaxRate, AgenciesRates) Then
				SalesTaxRate = 0;
				Representation = SalesTax.GetSalesTaxRatePresentation(Object.SalesTaxRate.Description, TaxRate) + " - Inactive";
				Items.SalesTaxRate.ChoiceList.Add(0, Representation);
			Else
				SalesTaxRate = Object.SalesTaxRate;
			EndIf;
		EndIf;
	Else
		Items.SalesTaxPercentDecoration.Title = "";
		Items.SalesTaxPercentDecoration.Border = New Border(ControlBorderType.WithoutBorder);
		Items.TotalsColumn3Labels.Visible = False;
		Items.TaxableSubtotalCurrency.Visible = False;
		//Items.SalesTaxCurrency.Visible = False;
		//Items.SalesTaxRate.Visible = False;
	EndIf;
	
	// Set currency titles.
	DefaultCurrencySymbol            = GeneralFunctionsReusable.DefaultCurrencySymbol();
	ForeignCurrencySymbol            = Object.Currency.Symbol;
	Items.ExchangeRate.Title         = DefaultCurrencySymbol + "/1" + ForeignCurrencySymbol;
	Items.LineSubtotalCurrency.Title = ForeignCurrencySymbol;
	Items.DiscountCurrency.Title     = ForeignCurrencySymbol;
	Items.ShippingCurrency.Title     = ForeignCurrencySymbol;
	Items.RCCurrency.Title           = DefaultCurrencySymbol;
	Items.FCYCurrency.Title          = ForeignCurrencySymbol;
	Items.SalesTaxCurrency.Title     = ForeignCurrencySymbol;
	Items.TaxableSubtotalCurrency.Title = ForeignCurrencySymbol;
	
	// Update elements status.
	//Items.FormChargeWithStripe.Enabled = IsBlankString(Object.StripeID);
	
	If NOT GeneralFunctionsReusable.FunctionalOptionValue("MultiCurrency") Then
		//Items.FCYCurrency.Visible = False;
		Items.RCCurrency.Title = " ";
	EndIf;
	
	If Object.Ref.IsEmpty() Then
		Object.EmailNote = Constants.CashSaleFooter.Get();
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
		
		If  Object.Ref.IsEmpty() And ValueIsFilled(Object.Company) Then
			CompanyOnChange(Items.Company);	
		EndIf;	
		///////////////////////////////////////////////
	Else 
		AttachIdleHandler("AfterOpen", 0.1, True);
	EndIf;		
	
EndProcedure

&AtClient
Procedure OnClose()
	OnCloseAtServer();
EndProcedure

&AtServer
Procedure OnCloseAtServer()

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
	
	// preventing posting if already included in a bank rec
	If ReconciledDocumentsServerCall.RequiresExcludingFromBankReconciliation(Object.Ref, Object.DocumentTotalRC, Object.Date, Object.BankAccount, WriteParameters.WriteMode) Then
		Cancel = True;
		CommonUseClient.ShowCustomMessageBox(ThisForm, "Bank reconciliation", "The transaction you are editing has been reconciled. Saving your changes could put you out of balance the next time you try to reconcile. 
		|To modify it you should exclude it from the Bank rec. document.", PredefinedValue("Enum.MessageStatus.Warning"));
	EndIf;    

EndProcedure

// <- CODE REVIEW

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

	
	//Period closing
	If PeriodClosingServerCall.DocumentPeriodIsClosed(CurrentObject.Ref, CurrentObject.Date) Then
		PermitWrite = PeriodClosingServerCall.DocumentWritePermitted(WriteParameters);
		CurrentObject.AdditionalProperties.Insert("PermitWrite", PermitWrite);	
	EndIf;
	
	//If Object.Ref.IsEmpty() Then
	//
	//	MatchVal = Increment(Constants.CashSaleLastNumber.Get());
	//	If Object.Number = MatchVal Then
	//		Constants.CashSaleLastNumber.Set(MatchVal);
	//	Else
	//		If Increment(Object.Number) = "" Then
	//		Else
	//			If StrLen(Increment(Object.Number)) > 20 Then
	//				 Constants.CashSaleLastNumber.Set("");
	//			Else
	//				Constants.CashSaleLastNumber.Set(Increment(Object.Number));
	//			Endif;

	//		Endif;
	//	Endif;
	//Endif;
	//
	//If Object.Number = "" Then
	//	Message("Cash Sale Number is empty");
	//	Cancel = True;
	//Endif;
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	//------------------------------------------------------------------------------
	// Recalculate values of form object attributes.
	
	// Refill lots and serial numbers values.
	For Each Row In Object.LineItems Do
		// Update lots & serials visibility and availability.
		LotsSerialNumbers.UpdateLotsSerialNumbersVisibility(Row.Product, Items, 1, Row.UseLotsSerials);
		// Fill lot owner.
		LotsSerialNumbers.FillLotOwner(Row.Product, Row.LotOwner);
		// Load serial numbers.
		LotsSerialNumbers.FillSerialNumbers(Object.SerialNumbers, Row.Product, 1, Row.LineID, Row.SerialNumbers);
	EndDo;
	
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
	
EndProcedure

&AtServer
Procedure CompanyOnChangeAtServer()
	
	// Reset company adresses (if company was changed).
	FillCompanyAddressesAtServer(Object.Company, Object.ShipTo, Object.BillTo);
	
	// Request company default settings.
	CompanyDefaultSettings = CommonUse.GetAttributeValues(Object.Company, "DefaultCurrency, SalesPerson");
	Object.Currency        = CompanyDefaultSettings.DefaultCurrency;
	Object.SalesPerson     = CompanyDefaultSettings.SalesPerson;
	
	// Process settings changes.
	CurrencyOnChangeAtServer();
	
	// Tax settings
	SalesTaxRate = SalesTax.GetDefaultSalesTaxRate(Object.Company);
	If SalesTaxRate <> Object.SalesTaxRate Then
		Object.SalesTaxRate = SalesTaxRate;
		Object.SalesTaxAcrossAgencies.Clear();
	EndIf;
	Object.DiscountIsTaxable = True;
	
	RecalculateTotalsAtServer();
	EmailSet();
	
	Items.DecorationBillTo.Visible = True;
	Items.DecorationShipTo.Visible = True;
	Items.DecorationShipTo.Title = GeneralFunctions.ShowAddressDecoration(Object.ShipTo);
	Items.DecorationBillTo.Title = GeneralFunctions.ShowAddressDecoration(Object.BillTo);
	
EndProcedure

&AtClient
Procedure DepositTypeOnChange(Item)
	DepositTypeOnChangeAtServer();
EndProcedure

&AtServer
Procedure DepositTypeOnChangeAtServer()
	// Insert handler contents.
	If Object.DepositType = "1" Then
		Object.BankAccount = Constants.UndepositedFundsAccount.Get();
		//Items.BankAccount.ReadOnly = True;
	Else
		//Items.BankAccount.ReadOnly = False;
		Object.BankAccount = Constants.BankAccount.Get();
	EndIf;

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
	
	RecalculateTotalsAtServer();
	
EndProcedure

&AtClient
Procedure BillToOnChange(Item)
	
	Items.DecorationBillTo.Visible = True;
	Items.DecorationBillTo.Title = GeneralFunctions.ShowAddressDecoration(Object.BillTo);
	
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
	Items.ShippingCurrency.Title     = ForeignCurrencySymbol;
	Items.RCCurrency.Title           = DefaultCurrencySymbol;
	Items.FCYCurrency.Title          = ForeignCurrencySymbol;
	Items.SalesTaxCurrency.Title     = ForeignCurrencySymbol;
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
	RecalculateTotalsAtServer();
	
EndProcedure

&AtClient
Procedure LocationOnChange(Item)
	
	LineItemsCurrentData = Items.LineItems.CurrentData;
	If LineItemsCurrentData <> Undefined Then
		
		// Fill line data for editing.
		TableSectionRow = GetLineItemsRowStructure();
		FillPropertyValues(TableSectionRow, LineItemsCurrentData);
		
		UpdateInformationCurrentRow(TableSectionRow);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DiscountPercentOnChange(Item)
		
	Object.Discount = (-1 * Object.LineSubtotal * Object.DiscountPercent ) / 100;
	RecalculateTotals();
	
	LineItemsCurrentData = Items.LineItems.CurrentData;
	If LineItemsCurrentData <> Undefined Then
		
		// Fill line data for editing.
		TableSectionRow = GetLineItemsRowStructure();
		FillPropertyValues(TableSectionRow, LineItemsCurrentData);
		
		UpdateInformationCurrentRow(TableSectionRow);
		
	EndIf;

EndProcedure

&AtClient
Procedure DiscountOnChange(Item)
	
	// Discount can not override the total.
	If Object.Discount < -Object.LineSubtotal Then
		Object.Discount = - Object.LineSubtotal;
	EndIf;
	
	// Recalculate discount value by it's percent.
	If Object.LineSubtotal > 0 Then
		Object.DiscountPercent = Round(-1 * 100 * Object.Discount / Object.LineSubtotal, 2);
	EndIf;

	RecalculateTotals();
	
	LineItemsCurrentData = Items.LineItems.CurrentData;
	If LineItemsCurrentData <> Undefined Then
		
		// Fill line data for editing.
		TableSectionRow = GetLineItemsRowStructure();
		FillPropertyValues(TableSectionRow, LineItemsCurrentData);
		
		UpdateInformationCurrentRow(TableSectionRow);
		
	EndIf;

EndProcedure

&AtClient
Procedure DiscountIsTaxableOnChange(Item)
	DiscountIsTaxableOnChangeAtServer();
	RecalculateTotals();
EndProcedure

&AtServer
Procedure DiscountIsTaxableOnChangeAtServer()
	// Insert handler contents.
EndProcedure

&AtClient
Procedure ShippingOnChange(Item)
	RecalculateTotals();
EndProcedure

&AtClient
Procedure SalesTaxOnChange(Item)
	RecalculateTotals();
EndProcedure

&AtClient
Procedure SalesTaxRateOnChange(Item)
	SetSalesTaxRate(SalesTaxRate);
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
				Row.PriceUnits = Round(GeneralFunctions.RetailPrice(Object.Date, Row.Product, Object.Company) /
				                 // The price is returned for default sales unit factor.
				                 ?(Object.ExchangeRate > 0, Object.ExchangeRate, 1), GeneralFunctionsReusable.PricePrecisionForOneItem(Row.Product));
				LineItemsPriceOnChangeAtServer(Row);
			EndDo;
			RecalculateTotalsAtServer();
		EndIf;
		
	ElsIf DefaultSetting = "Company" Then
		
		// Process the attribute change in any case.
		CompanyOnChangeAtServer();
		
		// Process line items change.
		If RecalculateLineItems Then
			// Recalculate retail price.
			For Each Row In Object.LineItems Do
				Row.PriceUnits = Round(GeneralFunctions.RetailPrice(Object.Date, Row.Product, Object.Company) /
				                 // The price is returned for default sales unit factor.
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
		ObjectData  = New Structure("Project, Class");
		FillPropertyValues(ObjectData, Object);
		For Each ObjectField In ObjectData Do
			If Not ValueIsFilled(Item.CurrentData[ObjectField.Key]) Then
				Item.CurrentData[ObjectField.Key] = ObjectField.Value;
			EndIf;
		EndDo;
		
		// Clear order data on duplicate row.
		ClearFields  = New Structure("");
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
	
	// Refresh totals cache.
	RecalculateTotals();
	
EndProcedure

&AtServer
Procedure LineItemsProductOnChangeAtServer(TableSectionRow)
	
	// Request product properties.
	ProductProperties = CommonUse.GetAttributeValues(TableSectionRow.Product,   New Structure("Ref, Description, UnitSet, HasLotsSerialNumbers, UseLots, UseLotsType, Characteristic, UseSerialNumbersOnShipment, Taxable"));
	UnitSetProperties = CommonUse.GetAttributeValues(ProductProperties.UnitSet, New Structure("DefaultSaleUnit"));
	TableSectionRow.ProductDescription = ProductProperties.Description;
	TableSectionRow.UnitSet            = ProductProperties.UnitSet;
	TableSectionRow.Unit               = UnitSetProperties.DefaultSaleUnit;
	TableSectionRow.Taxable            = ProductProperties.Taxable;
	TableSectionRow.PriceUnits         = Round(GeneralFunctions.RetailPrice(Object.Date, TableSectionRow.Product, Object.Company) /
	                                     // The price is returned for default sales unit factor.
	                                     ?(Object.ExchangeRate > 0, Object.ExchangeRate, 1), GeneralFunctionsReusable.PricePrecisionForOneItem(TableSectionRow.Product));
	
	// Make lots & serial numbers columns visible.
	LotsSerialNumbers.UpdateLotsSerialNumbersVisibility(ProductProperties, Items, 1, TableSectionRow.UseLotsSerials);
	
	// Fill lot owner.
	LotsSerialNumbers.FillLotOwner(ProductProperties, TableSectionRow.LotOwner);
	
	// Clear serial numbers.
	TableSectionRow.SerialNumbers = "";
	LineItemsSerialNumbersOnChangeAtServer(TableSectionRow);
	
	// Reset default values.
	TableSectionRow.Project            = Object.Project;
	//TableSectionRow.Class              = Object.Class;
	
	// Assign default quantities.
	TableSectionRow.QtyUnits  = 0;
	TableSectionRow.QtyUM     = 0;
	
	// Calculate totals by line.
	TableSectionRow.LineTotal     = 0;
	TableSectionRow.TaxableAmount = 0;
	
	UpdateInformationCurrentRow(TableSectionRow);
	
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
	TableSectionRow.PriceUnits = ?(TableSectionRow.QtyUnits > 0,
	                             Round(TableSectionRow.LineTotal / Round(TableSectionRow.QtyUnits, QuantityPrecision), GeneralFunctionsReusable.PricePrecisionForOneItem(TableSectionRow.Product)), 0);
								 
	// Load processed data back.
	FillPropertyValues(Items.LineItems.CurrentData, TableSectionRow);

	RecalculateTotals();
	
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
	RecalculateTotals();
	
EndProcedure

&AtServer
Procedure LineItemsTaxableOnChangeAtServer(TableSectionRow)
	
	// Calculate sales tax by line total.
	TableSectionRow.TaxableAmount = ?(TableSectionRow.Taxable, TableSectionRow.LineTotal, 0);
	
	UpdateInformationCurrentRow(TableSectionRow);
	
EndProcedure

&AtClient
Procedure LineItemsTaxableAmountOnChange(Item)
	// Insert handler contents.
	RecalculateTotals();
EndProcedure

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region COMMANDS_HANDLERS

// -> CODE REVIEW

//------------------------------------------------------------------------------
// Custom buttons processing.

&AtClient
Procedure AddLine(Command)
	
	Items.LineItems.AddRow();
	
EndProcedure

//------------------------------------------------------------------------------
// Audit log.

&AtClient
Procedure AuditLogRecord(Command)
	
	FormParameters = New Structure();	
	FltrParameters = New Structure();
	FltrParameters.Insert("DocUUID", String(Object.Ref.UUID()));
	FormParameters.Insert("Filter", FltrParameters);
	OpenForm("CommonForm.AuditLogList",FormParameters, Object.Ref);
	

EndProcedure

//------------------------------------------------------------------------------
// Stripe.


&AtServer
Function SessionTenant()
	
	Return SessionParameters.TenantValue;
	
EndFunction

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region PRIVATE_IMPLEMENTATION

//------------------------------------------------------------------------------
// Calculate values of form object attributes.

&AtServer
Procedure EmailSet()
	Query = New Query("SELECT
		                  |	Addresses.FirstName,
		                  |	Addresses.MiddleName,
		                  |	Addresses.LastName,
		                  |	Addresses.Phone,
		                  |	Addresses.Fax,
		                  |	Addresses.Email,
		                  |	Addresses.AddressLine1,
		                  |	Addresses.AddressLine2,
		                  |	Addresses.City,
		                  |	Addresses.State.Code AS State,
		                  |	Addresses.Country,
		                  |	Addresses.ZIP,
		                  |	Addresses.RemitTo
		                  |FROM
		                  |	Catalog.Addresses AS Addresses
		                  |WHERE
		                  |	Addresses.Owner = &Company
		                  |	AND Addresses.DefaultBilling = TRUE");
		Query.SetParameter("Company", object.company);
			QueryResult = Query.Execute();	
		Dataset = QueryResult.Unload();
		
	If Dataset.Count() > 0 Then
		Object.EmailTo = Dataset[0].Email;
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

&AtClient
// The procedure recalculates the document's total.
// DocumentTotal - document's currency in FCY (foreign currency).
// DocumentTotalRC - company's reporting currency.
//
Procedure RecalculateTotals()
	
	//Object.LineSubtotalRC = Object.LineItems.Total("LineTotal");
	//Object.SubTotalRC = Object.LineItems.Total("LineTotal") + Object.DiscountRC;
	//
	//DocTotal = Object.LineSubtotalRC + Object.DiscountRC + Object.ShippingRC + Object.SalesTaxRC;
	//Object.DocumentTotal = DocTotal;
	//Object.DocumentTotalRC = DocTotal * Object.ExchangeRate;
	
	// Calculate document totals.
	
	LineSubtotal = 0;
	TaxableSubtotal = 0;
	For Each Row In Object.LineItems Do
		LineSubtotal = LineSubtotal  + Row.LineTotal;
		If Row.Taxable = True Then
			Row.TaxableAmount = Row.LineTotal;
		EndIf;
		TaxableSubtotal = TaxableSubtotal + Row.TaxableAmount;
	EndDo;

	
	// Assign totals to the object fields.
	If Object.LineSubtotal <> LineSubtotal Then
		Object.LineSubtotal = LineSubtotal;
		// Recalculate the discount and it's percent.
		Object.Discount     = Round(-1 * Object.LineSubtotal * Object.DiscountPercent/100, 2);
		If Object.Discount < -Object.LineSubtotal Then
			Object.Discount = -Object.LineSubtotal;
		EndIf;
		If Object.LineSubtotal > 0 Then
			Object.DiscountPercent = Round(-1 * 100 * Object.Discount / Object.LineSubtotal, 2);
		EndIf;
	EndIf;
		
	//Calculate sales tax
	If Object.DiscountIsTaxable Then
		Object.TaxableSubtotal = TaxableSubtotal;
	Else
		Object.TaxableSubtotal = TaxableSubtotal + Round(-1 * TaxableSubtotal * Object.DiscountPercent/100, 2);
	EndIf;
	CurrentAgenciesRates = Undefined;
	If Object.SalesTaxAcrossAgencies.Count() > 0 Then
		CurrentAgenciesRates = New Array();
		For Each AgencyRate In Object.SalesTaxAcrossAgencies Do
			CurrentAgenciesRates.Add(New Structure("Agency, Rate, SalesTaxRate, SalesTaxComponent", AgencyRate.Agency, AgencyRate.Rate, AgencyRate.SalesTaxRate, AgencyRate.SalesTaxComponent));
		EndDo;
	EndIf;
	SalesTaxAcrossAgencies = SalesTaxClient.CalculateSalesTax(Object.TaxableSubtotal, Object.SalesTaxRate, CurrentAgenciesRates);
	Object.SalesTaxAcrossAgencies.Clear();
	For Each STAcrossAgencies In SalesTaxAcrossAgencies Do 
		Something = Object.SalesTaxAcrossAgencies.Add();
		FillPropertyValues(Something, STAcrossAgencies);
	EndDo;
	
	Object.SalesTax = Object.SalesTaxAcrossAgencies.Total("Amount");
	
	// Calculate the rest of the totals.
	Object.SubTotal         = LineSubtotal + Object.Discount;
	Object.SalesTaxRC       = Round(Object.SalesTax * Object.ExchangeRate, 2);

	//Object.DocumentTotal    = Object.SubTotal + Object.Shipping + Object.SalesTaxAmount;
	Object.DocumentTotal    = Object.SubTotal + Object.Shipping + Object.SalesTax;
	Object.DocumentTotalRC  = Round(Object.DocumentTotal * Object.ExchangeRate, 2);
	
EndProcedure

&AtServer
// The procedure recalculates the document's total.
// DocumentTotal - document's currency in FCY (foreign currency).
// DocumentTotalRC - company's reporting currency.
//
Procedure RecalculateTotalsAtServer()
	
	//Object.LineSubtotalRC = Object.LineItems.Total("LineTotal");
	//Object.SubTotalRC = Object.LineItems.Total("LineTotal") + Object.DiscountRC;
	//
	//DocTotal = Object.LineSubtotalRC + Object.DiscountRC + Object.ShippingRC + Object.SalesTaxRC;
	//Object.DocumentTotal = DocTotal;
	//Object.DocumentTotalRC = DocTotal * Object.ExchangeRate;
	
	// Calculate document totals.
	
	LineSubtotal = 0;
	TaxableSubtotal = 0;
	For Each Row In Object.LineItems Do
		LineSubtotal = LineSubtotal  + Row.LineTotal;
		If Row.Taxable = True Then
			Row.TaxableAmount = Row.LineTotal;
		EndIf;
		TaxableSubtotal = TaxableSubtotal + Row.TaxableAmount;
	EndDo;
	
	// Assign totals to the object fields.
	If Object.LineSubtotal <> LineSubtotal Then
		Object.LineSubtotal = LineSubtotal;
		// Recalculate the discount and it's percent.
		Object.Discount     = Round(-1 * Object.LineSubtotal * Object.DiscountPercent/100, 2);
		If Object.Discount < -Object.LineSubtotal Then
			Object.Discount = -Object.LineSubtotal;
		EndIf;
		If Object.LineSubtotal > 0 Then
			Object.DiscountPercent = Round(-1 * 100 * Object.Discount / Object.LineSubtotal, 2);
		EndIf;
	EndIf;
		
	//Calculate sales tax
	If Object.DiscountIsTaxable Then
		Object.TaxableSubtotal = TaxableSubtotal;
	Else
		Object.TaxableSubtotal = TaxableSubtotal + Round(-1 * TaxableSubtotal * Object.DiscountPercent/100, 2);
	EndIf;
	CurrentAgenciesRates = Undefined;
	If Object.SalesTaxAcrossAgencies.Count() > 0 Then
		CurrentAgenciesRates = New Array();
		For Each AgencyRate In Object.SalesTaxAcrossAgencies Do
			CurrentAgenciesRates.Add(New Structure("Agency, Rate, SalesTaxRate, SalesTaxComponent", AgencyRate.Agency, AgencyRate.Rate, AgencyRate.SalesTaxRate, AgencyRate.SalesTaxComponent));
		EndDo;
	EndIf;
	SalesTaxAcrossAgencies = SalesTax.CalculateSalesTax(Object.TaxableSubtotal, Object.SalesTaxRate, CurrentAgenciesRates);
	Object.SalesTaxAcrossAgencies.Clear();
	For Each STAcrossAgencies In SalesTaxAcrossAgencies Do 
		Something = Object.SalesTaxAcrossAgencies.Add();
		FillPropertyValues(Something, STAcrossAgencies);
	EndDo;
	
	Object.SalesTax = Object.SalesTaxAcrossAgencies.Total("Amount");
	
	// Calculate the rest of the totals.
	Object.SubTotal         = LineSubtotal + Object.Discount;
	Object.SalesTaxRC       = Round(Object.SalesTax * Object.ExchangeRate, 2);

	//Object.DocumentTotal    = Object.SubTotal + Object.Shipping + Object.SalesTaxAmount;
	Object.DocumentTotal    = Object.SubTotal + Object.Shipping + Object.SalesTax;
	Object.DocumentTotalRC  = Round(Object.DocumentTotal * Object.ExchangeRate, 2);
	
EndProcedure

//------------------------------------------------------------------------------
// Closing period.

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
// Numbering functions.

&AtServer
Function Increment(NumberToInc)
	
	//Last = Constants.SalesInvoiceLastNumber.Get();
	Last = NumberToInc;
	//Last = "AAAAA";
	LastCount = StrLen(Last);
	Digits = new Array();
	For i = 1 to LastCount Do	
		Digits.Add(Mid(Last,i,1));

	EndDo;
	
	NumPos = 9999;
	lengthcount = 0;
	firstnum = false;
	j = 0;
	While j < LastCount Do
		If NumCheck(Digits[LastCount - 1 - j]) Then
			if firstnum = false then //first number encountered, remember position
				firstnum = true;
				NumPos = LastCount - 1 - j;
				lengthcount = lengthcount + 1;
			Else
				If firstnum = true Then
					If NumCheck(Digits[LastCount - j]) Then //if the previous char is a number
						lengthcount = lengthcount + 1;  //next numbers, add to length.
					Else
						break;
					Endif;
				Endif;
			Endif;
						
		Endif;
		j = j + 1;
	EndDo;
	
	NewString = "";
	
	If lengthcount > 0 Then //if there are numbers in the string
		changenumber = Mid(Last,(NumPos - lengthcount + 2),lengthcount);
		NumVal = Number(changenumber);
		NumVal = NumVal + 1;
		StringVal = String(NumVal);
		StringVal = StrReplace(StringVal,",","");
		
		StringValLen = StrLen(StringVal);
		changenumberlen = StrLen(changenumber);
		LeadingZeros = Left(changenumber,(changenumberlen - StringValLen));

		LeftSide = Left(Last,(NumPos - lengthcount + 1));
		RightSide = Right(Last,(LastCount - NumPos - 1));
		NewString = LeftSide + LeadingZeros + StringVal + RightSide; //left side + incremented number + right side
		
	Endif;
	
	Next = NewString;

	return NewString;
	
EndFunction

&AtServer
Function NumCheck(CheckValue)
	 
	For i = 0 to  9 Do
		If CheckValue = String(i) Then
			Return True;
		Endif;
	EndDo;
		
	Return False;
		
EndFunction

//------------------------------------------------------------------------------
// Replacemant for metadata properties on client.

&AtClient
// Returns fields structure of LineItems form control.
Function GetLineItemsRowStructure()
	
	// Define control row fields.
	Return New Structure("LineNumber, LineID, Product, ProductDescription, UseLotsSerials, LotOwner, Lot, SerialNumbers, UnitSet, QtyUnits, Unit, QtyUM, UM, PriceUnits, LineTotal, Taxable, TaxableAmount, Project, Class");
	
EndFunction

//------------------------------------------------------------------------------
// Sales tax calculation.

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
	ShowSalesTaxRate();
	RecalculateTotals();
EndProcedure

&AtClient
Procedure ShowSalesTaxRate()
	If Object.SalesTaxAcrossAgencies.Count() = 0 Then
		SalesTaxRateAttr = CommonUse.GetAttributeValues(Object.SalesTaxRate, "Rate");
		TaxRate = SalesTaxRateAttr.Rate;
	Else
		TaxRate = Object.SalesTaxAcrossAgencies.Total("Rate");
	EndIf;
	SalesTaxRateText = "Sales tax rate: " + String(TaxRate) + " %";
	Items.SalesTaxPercentDecoration.Title = SalesTaxRateText;

EndProcedure

//------------------------------------------------------------------------------
// Information bar.

&AtServer
Procedure UpdateInformationCurrentRow(CurrentRow)
	
	InformationCurrentRow = "";
	
	If CurrentRow.Product <> Undefined And CurrentRow.Product <> PredefinedValue("Catalog.Products.EmptyRef") Then
		
		LineItems = Object.LineItems.Unload(, "LineNumber, Product, QtyUM, LineTotal");
		
		LineItem = LineItems.Find(CurrentRow.LineNumber, "LineNumber");
		LineItem.Product   = CurrentRow.Product;
		LineItem.QtyUM     = CurrentRow.QtyUM;
		LineItem.LineTotal = CurrentRow.LineTotal;
		
		InformationCurrentRow = GeneralFunctions.GetMarginInformation(CurrentRow.Product, Object.Location, CurrentRow.QtyUM, CurrentRow.LineTotal,
																	  Object.Currency, Object.ExchangeRate, Object.DiscountPercent, LineItems); 
		InformationCurrentRow = "" + InformationCurrentRow;
		
	EndIf;
	
EndProcedure

#EndRegion
