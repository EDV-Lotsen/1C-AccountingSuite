
////////////////////////////////////////////////////////////////////////////////
// Quote: Document form
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
	FillQuoteStatusAtServer();
	
	//------------------------------------------------------------------------------
	// 3. Set custom controls presentation.
	
	// Set proper company field presentation.
	CustomerName                    = GeneralFunctionsReusable.GetCustomerName();
	Items.Company.Title             = CustomerName;
	Items.Company.ToolTip           = StringFunctionsClientServer.SubstituteParametersInString(NStr("en = '%1 name'"),             CustomerName);
	Items.RefNum.Title              = StringFunctionsClientServer.SubstituteParametersInString(NStr("en = '%1 RFQ / Ref. #'"),    CustomerName);
	Items.RefNum.ToolTip            = StringFunctionsClientServer.SubstituteParametersInString(NStr("en = '%1 RFQ /
	                                                                                                      |Reference number'"),    CustomerName);
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
	QuantityFormat = GeneralFunctionsReusable.DefaultQuantityFormat();
	Items.LineItemsQuantity.EditFormat  = QuantityFormat;
	Items.LineItemsQuantity.Format      = QuantityFormat;
	
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
			TaxRate = Object.SalesTaxAcrossAgencies.Total("Rate");
			SalesTaxRateText = "Sales tax rate: " + String(TaxRate) + "%";
			Items.SalesTaxPercentDecoration.Title = SalesTaxRateText;
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
		Items.SalesTaxRate.Visible = False;
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
		Items.RCCurrency.Title 	= " "; 
	EndIf;
	
	If Object.Ref.IsEmpty() Then
		Object.EmailNote = Constants.QuoteFooter.Get();
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
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	If FirstNumber <> "" Then
		
		Numerator = Catalogs.DocumentNumbering.Quote.GetObject();
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
	FillQuoteStatusAtServer();
	
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
		
		If AutoCompanyOnChange Then
			CompanyOnChange(Items.Company);	
		EndIf;	
		///////////////////////////////////////////////
	Else
		AttachIdleHandler("AfterOpen", 0.1, True);	
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
	
	Object.Terms       = Object.Company.Terms;
	
	// Process settings changes.
	CurrencyOnChangeAtServer();
	
	// Tax calculation.
	SalesTaxRate = SalesTax.GetDefaultSalesTaxRate(Object.Company);
	Object.SalesTaxRate = SalesTaxRate;
	Object.DiscountIsTaxable = True;
	If Object.SalesTaxAcrossAgencies.Count() > 0 Then
		CurrentAgenciesRates = New Array();
		For Each AgencyRate In Object.SalesTaxAcrossAgencies Do
			CurrentAgenciesRates.Add(New Structure("Agency, Rate", AgencyRate.Agency, AgencyRate.Rate));
		EndDo;
	EndIf;
	SalesTaxAcrossAgencies = SalesTax.CalculateSalesTax(Object.TaxableSubtotal, Object.SalesTaxRate, CurrentAgenciesRates);
	Object.SalesTaxAcrossAgencies.Clear();
	For Each STAcrossAgencies In SalesTaxAcrossAgencies Do 
		NewRow = Object.SalesTaxAcrossAgencies.Add();
		FillPropertyValues(NewRow, STAcrossAgencies);
	EndDo;
	If Object.SalesTaxAcrossAgencies.Count() = 0 Then
		SalesTaxRateAttr = CommonUse.GetAttributeValues(Object.SalesTaxRate, "Rate");
		TaxRate = SalesTaxRateAttr.Rate;
	Else
		TaxRate = Object.SalesTaxAcrossAgencies.Total("Rate");
	EndIf;
	SalesTaxRateText = "Sales tax rate: " + String(TaxRate) + " %";
	Items.SalesTaxPercentDecoration.Title = SalesTaxRateText;
	RecalculateTotalsAtServer();
	
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
	
	// Request server operation.
	ShipToOnChangeAtServer();
	
EndProcedure

&AtServer
Procedure ShipToOnChangeAtServer()
	
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
	//Items.RCCurrency.Title           = DefaultCurrencySymbol;
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
Procedure DiscountPercentOnChange(Item)
	
	// Request server operation.
	DiscountPercentOnChangeAtServer();
	
EndProcedure

&AtServer
Procedure DiscountPercentOnChangeAtServer()
	
	// Recalculate discount value by it's percent.
	Object.Discount = Round(-1 * Object.LineSubtotal * Object.DiscountPercent/100, 2);
	
	// Recalculate totals with new discount.
	RecalculateTotalsAtServer();
	
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
	
	// Recalculate discount value by it's percent.
	If Object.LineSubtotal > 0 Then
		Object.DiscountPercent = Round(-1 * 100 * Object.Discount / Object.LineSubtotal, 2);
	EndIf;
	
	// Recalculate totals with new discount.
	RecalculateTotalsAtServer();
	
EndProcedure

&AtClient
Procedure ShippingOnChange(Item)
	
	// Request server operation.
	ShippingOnChangeAtServer();
	
EndProcedure

&AtServer
Procedure ShippingOnChangeAtServer()
	
	// Recalculate totals with new shipping amount.
	RecalculateTotalsAtServer();
	
EndProcedure

&AtClient
Procedure QuoteStatusPresentationClick(Item, StandardProcessing)
	
	If TypeOf(QuoteStatusPresentation) = Type("String") Then 
		
		StandardProcessing = False;
		
		StatusList = New ValueList;
		StatusList.Add("Open", "Open");
		StatusList.Add("Cancelled", "Cancelled");
		
		Res = New NotifyDescription("AfterChooseFromMenu", ThisObject); 
		ShowChooseFromMenu(Res, StatusList, Items.QuoteStatusPresentation);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterChooseFromMenu(DocumentStatus = Undefined, Parameter = Undefined) Export
	
	If DocumentStatus <> Undefined Then
		
		If DocumentStatus.Value = "Cancelled" Then
			
			Object.Cancelled = True;
			QuoteStatusPresentation = "Cancelled";
			ThisForm.Modified = True;
			
		ElsIf DocumentStatus.Value = "Open" Then
			
			Object.Cancelled = False;
			QuoteStatusPresentation = "Open";
			ThisForm.Modified = True;
			
		EndIf;
		
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
				Row.Price = Round(GeneralFunctions.RetailPrice(Object.Date, Row.Product, Object.Company) /
				                        ?(Object.ExchangeRate > 0, Object.ExchangeRate, 1), 2);
				LineItemsPriceOnChangeAtServer(Row);
			EndDo;
		EndIf;
		
	ElsIf DefaultSetting = "Company" Then
		
		// Process the attribute change in any case.
		CompanyOnChangeAtServer();
		
		// Process line items change.
		If RecalculateLineItems Then
			// Recalculate retail price.
			For Each Row In Object.LineItems Do
				Row.Price = Round(GeneralFunctions.RetailPrice(Object.Date, Row.Product, Object.Company) /
				                        ?(Object.ExchangeRate > 0, Object.ExchangeRate, 1), 2);
				LineItemsPriceOnChangeAtServer(Row);
			EndDo;
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
	ProductProperties = CommonUse.GetAttributeValues(TableSectionRow.Product, New Structure("Description, UM, Taxable"));
	TableSectionRow.ProductDescription = ProductProperties.Description;
	TableSectionRow.UM                 = ProductProperties.UM;
	TableSectionRow.Taxable            = ProductProperties.Taxable;
	TableSectionRow.Price              = Round(GeneralFunctions.RetailPrice(Object.Date, TableSectionRow.Product, Object.Company) /
	                                     ?(Object.ExchangeRate > 0, Object.ExchangeRate, 1), 2);
	
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
	
EndProcedure

&AtClient
Procedure LineItemsTaxableAmountOnChange(Item)
	
	// Refresh totals cache.
	RecalculateTotals();
	
EndProcedure

&AtClient
Procedure DiscountIsTaxableOnChange(Item)
	
	RecalculateTotalsAtServer();
	
EndProcedure

&AtClient
Procedure SalesTaxRateOnChange(Item)
	
	SetSalesTaxRate(SalesTaxRate);
	
EndProcedure

&AtClient
Procedure SetSalesTaxRate(NewSalesTaxRate)
	
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


#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region COMMANDS_HANDLERS

&AtClient
Procedure SaveAndClose(Command)
	
	If Write() Then Close() EndIf;
	
EndProcedure

&AtClient
Procedure Save(Command)
	
	Write();
	
EndProcedure

&AtClient
Procedure GenerateSI(Command)
	
	GenerateDoc("SalesInvoice");
		
EndProcedure

&AtClient
Procedure GenerateSO(Command)
	
	GenerateDoc("SalesOrder");
	
EndProcedure

&AtClient
Procedure SendEmail(Command)
	
	If Object.Ref.IsEmpty() Then
		ShowMessageBox(, NStr("en = 'An email cannot be sent until the quote is saved'"));
	Else	
		FormParameters = New Structure("Ref",Object.Ref );
		OpenForm("CommonForm.EmailForm", FormParameters,,,,,, FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
	
EndProcedure

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region PRIVATE_IMPLEMENTATION

//------------------------------------------------------------------------------
// Calculate values of form object attributes.

&AtServer
// Request order status from database.
Procedure FillQuoteStatusAtServer()
	
	QuoteStatusPresentation = "Open";
	
	If Object.Ref.IsEmpty() Then
		
		QuoteStatusPresentation = "Open";
		
	ElsIf Object.Cancelled Or Object.DeletionMark Then 
		
		QuoteStatusPresentation = "Cancelled";
		
	Else
		
		Query = New Query;
		Query.Text = 
		"SELECT
		|	DocumentJournalOfCompanies.Document
		|FROM
		|	InformationRegister.DocumentJournalOfCompanies AS DocumentJournalOfCompanies
		|WHERE
		|	DocumentJournalOfCompanies.Document.BaseDocument = &BaseDocument";
		
		Query.SetParameter("BaseDocument", Object.Ref);
		
		QueryResult = Query.Execute();
		
		SelectionDetailRecords = QueryResult.Select();
		
		While SelectionDetailRecords.Next() Do
			QuoteStatusPresentation = SelectionDetailRecords.Document;
		EndDo;
		
	EndIf;

	// Fill extended order status presentation (depending of document state).
	//--//If Not ValueIsFilled(Object.Ref) Then
	//	OrderStatusPresentation = String(Enums.OrderStatuses.New);
	//	Items.OrderStatusPresentation.TextColor = WebColors.DarkGray;
	//	
	//ElsIf Object.DeletionMark Then
	//	OrderStatusPresentation = String(Enums.OrderStatuses.Deleted);
	//	Items.OrderStatusPresentation.TextColor = WebColors.DarkGray;
	//	
	//ElsIf Not Object.Posted Then
	//	OrderStatusPresentation = String(Enums.OrderStatuses.Draft);
	//	Items.OrderStatusPresentation.TextColor = WebColors.DarkGray;
	//	
	//Else
	//	OrderStatusPresentation = String(OrderStatus);
	//	If OrderStatus = Enums.OrderStatuses.Closed Then 
	//		ThisForm.Items.OrderStatusPresentation.TextColor = WebColors.DarkGreen;
	//	ElsIf OrderStatus = Enums.OrderStatuses.Backordered Then 
	//		ThisForm.Items.OrderStatusPresentation.TextColor = WebColors.DarkGoldenRod;
	//	ElsIf OrderStatus = Enums.OrderStatuses.Open Then
	//		ThisForm.Items.OrderStatusPresentation.TextColor = WebColors.DarkRed;
	//	Else
	//		ThisForm.Items.OrderStatusPresentation.TextColor = WebColors.DarkGray;
	//	EndIf;
	//--//EndIf;
	
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
// The procedure recalculates the document's totals.
Procedure RecalculateTotals()
	
	// Calculate document totals.
	LineSubtotal = 0;
	TaxableSubtotal = 0;
	For Each Row In Object.LineItems Do
		LineSubtotal = LineSubtotal  + Row.LineTotal;
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
			CurrentAgenciesRates.Add(New Structure("Agency, Rate", AgencyRate.Agency, AgencyRate.Rate));
		EndDo;
	EndIf;
	SalesTaxAcrossAgencies = SalesTaxClient.CalculateSalesTax(Object.TaxableSubtotal, Object.SalesTaxRate, CurrentAgenciesRates);
	Object.SalesTaxAcrossAgencies.Clear();
	For Each STAcrossAgencies In SalesTaxAcrossAgencies Do 
		NewRow = Object.SalesTaxAcrossAgencies.Add();
		FillPropertyValues(NewRow, STAcrossAgencies);
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
// The procedure recalculates the document's totals.
Procedure RecalculateTotalsAtServer()
	
	// Calculate document totals.
	LineSubtotal = 0;
	TaxableSubtotal = 0;
	For Each Row In Object.LineItems Do
		LineSubtotal = LineSubtotal  + Row.LineTotal;
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
			CurrentAgenciesRates.Add(New Structure("Agency, Rate", AgencyRate.Agency, AgencyRate.Rate));
		EndDo;
	EndIf;
	SalesTaxAcrossAgencies = SalesTax.CalculateSalesTax(Object.TaxableSubtotal, Object.SalesTaxRate, CurrentAgenciesRates);
	Object.SalesTaxAcrossAgencies.Clear();
	For Each STAcrossAgencies In SalesTaxAcrossAgencies Do 
		NewRow = Object.SalesTaxAcrossAgencies.Add();
		FillPropertyValues(NewRow, STAcrossAgencies);
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
// Replacemant for metadata properties on client.

&AtClient
// Returns fields structure of LineItems form control.
Function GetLineItemsRowStructure()
	
	// Define control row fields.
	Return New Structure("LineNumber, Product, ProductDescription, Quantity, UM, Backorder, Price, LineTotal, Taxable, TaxableAmount, Location, DeliveryDate, Project, Class, Shipped, Invoiced");
	
EndFunction

&AtClient
Procedure GenerateDoc(DocumentType) 
	
	If Object.Ref.IsEmpty() Then
		ShowMessageBox(,NStr("en = 'Data has not yet been recorded.'"));		
	Else
		FormParameters  = New Structure("Basis", Object.Ref);
		OpenForm("Document." + DocumentType + ".ObjectForm", FormParameters);
	EndIf;
	
EndProcedure

#EndRegion

