
&AtClient
Var SalesTaxRateInactive, AgenciesRatesInactive;//Cache for storing inactive rates previously used in the document

////////////////////////////////////////////////////////////////////////////////
#Region EVENTS_HANDLERS

&AtServer
// Procedure fills in default values, used mostly when the corresponding functional options are
// turned off.
// The following defaults are filled in - warehouse location, and currency.
// 
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("Company") And Parameters.Company.Customer Then
		Object.Company = Parameters.Company;
	EndIf;

	//ConstantCreditMemo = Constants.CreditMemoLastNumber.Get();
	//If Object.Ref.IsEmpty() Then		
	//	
	//	Object.Number = Constants.CreditMemoLastNumber.Get();
	//Endif;

	
	QuantityPrecision = GeneralFunctionsReusable.DefaultQuantityPrecision();
	QuantityFormat    = GeneralFunctionsReusable.DefaultQuantityFormat();
	Items.LineItemsQuantity.EditFormat = QuantityFormat;
	Items.LineItemsQuantity.Format     = QuantityFormat;
	
	// Update prices presentation.
	PriceFormat = GeneralFunctionsReusable.DefaultPriceFormat();
	Items.LineItemsPrice.EditFormat  = PriceFormat;
	Items.LineItemsPrice.Format      = PriceFormat;
	
	Items.Company.Title = GeneralFunctionsReusable.GetCustomerName();
	
	//Title = "Sales Return " + Object.Number + " " + Format(Object.Date, "DLF=D");
	
	//If Object.Ref.IsEmpty() Then
	//	Object.PriceIncludesVAT = GeneralFunctionsReusable.PriceIncludesVAT();
	//EndIf;
	
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
					Object.DiscountTaxability = Enums.DiscountTaxability.Taxable;
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
		Items.TotalsColumn3.Visible = False;
		Items.TaxTab.Visible = False;
	EndIf;

	//If GeneralFunctionsReusable.FunctionalOptionValue("MultiLocation") Then
	//Else
		If Object.Location.IsEmpty() Then
			Object.Location = GeneralFunctions.GetDefaultLocation();
		EndIf;
	//EndIf;

	If Object.Currency.IsEmpty() Then
		Object.Currency = Constants.DefaultCurrency.Get();
		Object.ARAccount = Object.Currency.DefaultARAccount;
		Object.ExchangeRate = 1;	
	Else
	EndIf; 
	
	DisplayCurrencySimbols(ThisForm, Object.Currency);
	
	If NOT GeneralFunctionsReusable.FunctionalOptionValue("MultiCurrency") Then
		//Items.FCYCurrency.Visible = False;
		//Items.RCCurrency.Visible = False;
		Items.RCCurrency.Title = "";
	EndIf;
	
	If Object.Ref.IsEmpty() Then
		Object.EmailNote = Constants.CreditMemoFooter.Get();
	EndIf;
	
	//DefaultCurrencySymbol = GeneralFunctionsReusable.DefaultCurrencySymbol();
	//DocumentCurrencySymbol = CommonUse.GetAttributeValue(Object.Currency, "Symbol");
	//
	//Items.ExchangeRate.Title = DefaultCurrencySymbol + "/1" + Object.Currency.Symbol;
	////Items.VATCurrency.Title = GeneralFunctionsReusable.DefaultCurrencySymbol();
	//Items.RCCurrency.Title = DefaultCurrencySymbol;
	//Items.SalesTaxCurrency.Title = DefaultCurrencySymbol;
	//Items.TaxableSubtotalCurrency.Title = DefaultCurrencySymbol;
	//
	//Items.DiscountCurrency.Title = DocumentCurrencySymbol;
	//Items.ShippingCurrency.Title = DocumentCurrencySymbol;
	//Items.SubtotalCurrency.Title = DocumentCurrencySymbol;
	//Items.FCYCurrency.Title = DocumentCurrencySymbol;
	
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	AttachIdleHandler("AfterOpen", 0.1, True);	
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	If EventName = "SalesTaxRateAdded" Then
		If Items.SalesTaxRate.ChoiceList.FindByValue(Parameter) = Undefined Then
			Items.SalesTaxRate.ChoiceList.Add(Parameter);
		EndIf;
	EndIf;
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

	
	//Period closing
	If PeriodClosingServerCall.DocumentPeriodIsClosed(CurrentObject.Ref, CurrentObject.Date) Then
		PermitWrite = PeriodClosingServerCall.DocumentWritePermitted(WriteParameters);
		CurrentObject.AdditionalProperties.Insert("PermitWrite", PermitWrite);	
	EndIf;

	
	If Object.LineItems.Count() = 0  Then
		Message("Cannot post with no line items.");
		Cancel = True;
	EndIf;

	//Avatax calculation
	AvaTaxServer.CalculateTaxBeforeWrite(CurrentObject, WriteParameters, Cancel, "ReturnOrder");
	
	//If Object.Ref.IsEmpty() Then
	//
	//	MatchVal = Increment(Constants.CreditMemoLastNumber.Get());
	//	If Object.Number = MatchVal Then
	//		Constants.CreditMemoLastNumber.Set(MatchVal);
	//	Else
	//		If Increment(Object.Number) = "" Then
	//		Else
	//			If StrLen(Increment(Object.Number)) > 20 Then
	//				 Constants.CreditMemoLastNumber.Set("");
	//			Else
	//				Constants.CreditMemoLastNumber.Set(Increment(Object.Number));
	//			Endif;

	//		Endif;
	//	Endif;
	//Endif;

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
	AvaTaxClient.ShowQueryToTheUserOnAvataxCalculation("SalesReturn", Object, ThisObject, WriteParameters, Cancel);
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	//Avatax calculation
	AvaTaxServer.CalculateTaxAfterWrite(CurrentObject, WriteParameters, "ReturnInvoice");
		
	//Update tax rate
	DisplaySalesTaxRate(ThisForm);

EndProcedure

&AtClient
Procedure OnClose()
	OnCloseAtServer();
EndProcedure

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region CONTROLS_EVENTS_HANDLERS

&AtClient
// CustomerOnChange UI event handler.
// Selects default currency for the customer, determines an exchange rate, and
// recalculates the document's sales tax and total amounts.
//  
Procedure CompanyOnChange(Item)
	
	CompanyOnChangeAtServer();
	
EndProcedure

&AtClient
// DateOnChange UI event handler.
// Determines an exchange rate on the new date, and recalculates the document's
// sales tax and total.
//
Procedure DateOnChange(Item)
	
	Object.ExchangeRate = GeneralFunctions.GetExchangeRate(Object.Date, Object.Currency);
	RecalculateTotals(Object);
	
EndProcedure

&AtClient
// CurrencyOnChange UI event handler.
// Determines an exchange rate for the new currency, and recalculates the document's
// sales tax and total.
//
Procedure CurrencyOnChange(Item)
	
	DisplayCurrencySimbols(ThisForm, Object.Currency);
	RecalculateTotals(Object);
	
EndProcedure

&AtClient
Procedure SalesTaxOnChange(Item)
	SalesTaxOnChangeAtServer();
	RecalculateTotals(Object);
EndProcedure

&AtClient
Procedure DiscountIsTaxableOnChange(Item)
	RecalculateTotals(Object);
EndProcedure

&AtClient
Procedure SalesTaxRateOnChange(Item)
	SetSalesTaxRate(SalesTaxRate);
EndProcedure

&AtClient
Procedure DiscountPercentOnChange(Item)
	
	Object.Discount = Round(-1 * Object.LineSubtotal * Object.DiscountPercent/100, 2);
	RecalculateTotals(Object);
	
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
	
	RecalculateTotals(Object);
	
EndProcedure

&AtClient
Procedure ShippingOnChange(Item)
	
	RecalculateTotals(Object);
	
EndProcedure

&AtClient
Procedure ExchangeRateOnChange(Item)
	RecalculateTotals(Object);
EndProcedure

&AtClient
Procedure TaxEngineOnChange(Item)
	
	TaxEngineOnChangeAtServer();
	
EndProcedure

&AtClient
Procedure DiscountTaxabilityOnChange(Item)
	
	SetDiscountTaxabilityAppearance(ThisForm);
	RecalculateTotals(Object);
	
EndProcedure

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region TABULAR_SECTION_EVENTS_HANDLERS

&AtClient
// ProductOnChange UI event handler.
// The procedure clears quantities, line total, and taxable amount in the line item,
// selects price for the new product from the price-list, divides the price by the document
// exchange rate, selects a default unit of measure for the product, and
// selects a product's sales tax type.
// 
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

&AtClient
// PriceOnChange UI event handler.
// Calculates line total by multiplying a price by a quantity in either the selected
// unit of measure (U/M) or in the base U/M, and recalculates the line's taxable amount and total.
// 
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

&AtClient
// LineItemsQuantityOnChange UI event handler.
// This procedure is used when the units of measure (U/M) functional option is turned off
// and base quantities are used instead of U/M quantities.
// The procedure recalculates line total, line taxable amount, and a document's sales tax and total.
//  
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

&AtClient
Procedure LineItemsTaxableOnChange(Item)
	
	// Refresh totals cache.
	RecalculateTotals(Object);
	
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

	RecalculateTotals(Object);
	
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

&AtClient
Procedure LineItemsOnChange(Item)
	
	RecalculateTotals(Object);
	
EndProcedure

&AtClient
Procedure LineItemsOnEditEnd(Item, NewRow, CancelEdit)
	
	If NewRow And CancelEdit Then
		RecalculateTotals(Object);
	EndIf;

EndProcedure

&AtClient
Procedure LineItemsDiscountIsTaxableOnChange(Item)
	
	RecalculateTotals(Object);
	
EndProcedure

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region COMMANDS_HANDLERS

&AtClient
Procedure SendEmail(Command)
	If Object.Ref.IsEmpty() Then
		Message("An email cannot be sent until the credit memo is posted");
	Else	
		FormParameters = New Structure("Ref",Object.Ref );
		OpenForm("CommonForm.EmailForm", FormParameters,,,,,, FormWindowOpeningMode.LockOwnerWindow);	
	EndIf;

	//SendEmailAtServer();
EndProcedure

&AtClient
Procedure AvaTax(Command)
	
	FormParams = New Structure("ObjectRef", Object.Ref);
	OpenForm("InformationRegister.AvataxDetails.Form.AvataxDetails", FormParams, ThisForm,,,,, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure


#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region PRIVATE_IMPLEMENTATION

&AtServer
Procedure LineItemsProductOnChangeAtServer(TableSectionRow)
	
	// Request product properties.
	ProductProperties = CommonUse.GetAttributeValues(TableSectionRow.Product,   New Structure("Description, UnitSet, Taxable, TaxCode, DiscountIsTaxable"));
	UnitSetProperties = CommonUse.GetAttributeValues(ProductProperties.UnitSet, New Structure("DefaultSaleUnit"));
	TableSectionRow.ProductDescription = ProductProperties.Description;
	TableSectionRow.UnitSet            = ProductProperties.UnitSet;
	TableSectionRow.Unit               = UnitSetProperties.DefaultSaleUnit;
	//TableSectionRow.UM                 = UnitSetProperties.UM;
	TableSectionRow.Taxable            = ProductProperties.Taxable;
	TableSectionRow.DiscountIsTaxable	= ProductProperties.DiscountIsTaxable;
	If Object.UseAvatax Then
		TableSectionRow.AvataxTaxCode 	= ProductProperties.TaxCode;
	EndIf;
	TableSectionRow.PriceUnits         = Round(GeneralFunctions.RetailPrice(Object.Date, TableSectionRow.Product, Object.Company) /
	                                     // The price is returned for default sales unit factor.
	                                     ?(Object.ExchangeRate > 0, Object.ExchangeRate, 1), GeneralFunctionsReusable.PricePrecisionForOneItem(TableSectionRow.Product));
										 
	// Assign default quantities.
	TableSectionRow.QtyUnits  = 0;
	TableSectionRow.QtyUM     = 0;
	
	// Calculate totals by line.
	TableSectionRow.LineTotal     = 0;
	
EndProcedure

// The procedure recalculates the document's total.
// DocumentTotal - document's currency in FCY (foreign currency).
// DocumentTotalRC - company's reporting currency.
//
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
	
	SalesTaxRC       		= Round(Object.SalesTax * Object.ExchangeRate, 2);
	SubTotalRC				= Round(Object.SubTotal * Object.ExchangeRate, 2);
	ShippingRC				= Round(Object.Shipping * Object.ExchangeRate, 2);
	Object.DocumentTotalRC	= SubTotalRC + ShippingRC + SalesTaxRC;

EndProcedure

&AtServer
Procedure CompanyOnChangeAtServer()
	
	EmailSet();
	
	Object.Currency = CommonUse.GetAttributeValue(Object.Company, "DefaultCurrency");
	Object.ARAccount = CommonUse.GetAttributeValue(Object.Currency, "DefaultARAccount");
	Object.ExchangeRate = GeneralFunctions.GetExchangeRate(Object.Date, Object.Currency);
	Items.ExchangeRate.Title = GeneralFunctionsReusable.DefaultCurrencySymbol() + "/1" + CommonUse.GetAttributeValue(Object.Currency, "Symbol");
	Items.FCYCurrency.Title = CommonUse.GetAttributeValue(Object.Currency, "Symbol");
	
	If Not ValueIsFilled(Object.ParentDocument) Then
		SalesTaxRate = SalesTax.GetDefaultSalesTaxRate(Object.Company);
		// Tax settings
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
	EndIf;
	
	If Object.Company.ARAccount <> ChartsofAccounts.ChartOfAccounts.EmptyRef() Then
		Object.ARAccount = Object.Company.ARAccount;
	Else
		DefaultCurrency = GeneralFunctionsReusable.DefaultCurrency();
		Object.ARAccount = DefaultCurrency.DefaultARAccount;
	EndIf;
	
	RecalculateTotals(Object);
	DisplaySalesTaxRate(ThisForm);
	
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

&AtClientAtServerNoContext
Procedure DisplayCurrencySimbols(Form, ObjectCurrency)
	
	DefaultCurrencySymbol = GeneralFunctionsReusable.DefaultCurrencySymbol();
	DocumentCurrencySymbol = CommonUse.GetAttributeValue(ObjectCurrency, "Symbol");
	
	Form.Items.ExchangeRate.Title = DefaultCurrencySymbol + "/1" + DocumentCurrencySymbol;
	Form.Items.RCCurrency.Title = DefaultCurrencySymbol;
	
	Form.Items.SalesTaxCurrency.Title = DocumentCurrencySymbol;
	Form.Items.TaxableSubtotalCurrency.Title = DocumentCurrencySymbol;
	Form.Items.DiscountCurrency.Title = DocumentCurrencySymbol;
	Form.Items.ShippingCurrency.Title = DocumentCurrencySymbol;
	Form.Items.SubtotalCurrency.Title = DocumentCurrencySymbol;
	Form.Items.FCYCurrency.Title = DocumentCurrencySymbol;
	
EndProcedure

&AtServer
Procedure LineItemsQuantityOnChangeAtServer(TableSectionRow)
	
	// Calculate total by line.
	TableSectionRow.LineTotal = Round(Round(TableSectionRow.QtyUnits, QuantityPrecision) * Round(TableSectionRow.PriceUnits, GeneralFunctionsReusable.PricePrecisionForOneItem(TableSectionRow.Product)), 2);
	
	// Process settings changes.
	LineItemsLineTotalOnChangeAtServer(TableSectionRow);
	
EndProcedure

&AtServer
Procedure SendEmailAtServer()
	
//If Object.Ref.IsEmpty() Then
//		Message("An email cannot be sent until the invoice is posted or written");
//	Else
//		
//	If Object.EmailTo <> "" Then
//		
//	// 	//imagelogo = Base64String(GeneralFunctions.GetLogo());
//	 	If constants.logoURL.Get() = "" Then
//			 imagelogo = "http://www.accountingsuite.com/images/logo-a.png";
//	 	else
//			 imagelogo = Constants.logoURL.Get();  
//	 	Endif;
//	 	
//		
//		
//		datastring = "";
//		TotalAmount = 0;
//		TotalCredits = 0;
//		For Each DocumentLine in Object.LineItems Do
//			
//			TotalAmount = TotalAmount + DocumentLine.LineTotal;
//			datastring = datastring + "<TR height=""20""><TD style=""border-spacing: 0px 0px;height: 20px;"">" + DocumentLine.Product +  "</TD><TD style=""border-spacing: 0px 0px;height: 20px;"">" + DocumentLine.ProductDescription + "</TD><TD style=""border-spacing: 0px 0px;height: 20px;"">" + DocumentLine.QtyUnits + "</TD><TD style=""border-spacing: 0px 0px;height: 20px;"">" + DocumentLine.PriceUnits + "</TD><TD style=""border-spacing: 0px 0px;height: 20px;"">" + DocumentLine.LineTotal + "</TD></TR>";

//		EndDo;
//		
//			 
//		MailProfil = New InternetMailProfile; 
//		
//		MailProfil.SMTPServerAddress = ServiceParameters.SMTPServer(); 
//		//MailProfil.SMTPServerAddress = Constants.MailProfAddress.Get();
//		MailProfil.SMTPUseSSL = ServiceParameters.SMTPUseSSL();
//		//MailProfil.SMTPUseSSL = Constants.MailProfSSL.Get();
//		MailProfil.SMTPPort = 465;  
//		
//		MailProfil.Timeout = 180; 
//		
//		MailProfil.SMTPPassword = ServiceParameters.SendGridPassword();
//	 	  
//		MailProfil.SMTPUser = ServiceParameters.SendGridUserName();

//		
//		send = New InternetMailMessage; 
//		//send.To.Add(object.shipto.Email);
//		//send.To.Add(object.EmailTo);
//		
//		If Object.EmailTo <> "" Then
//			EAddresses = StringFunctionsClientServer.SplitStringIntoSubstringArray(Object.EmailTo, ",");
//			For Each EmailAddress in EAddresses Do
//				send.To.Add(EmailAddress);
//			EndDo;
//		Endif;
//		
//		If Object.EmailCC <> "" Then
//			EAddresses = StringFunctionsClientServer.SplitStringIntoSubstringArray(Object.EmailCC, ",");
//			For Each EmailAddress in EAddresses Do
//				send.CC.Add(EmailAddress);
//			EndDo;
//		Endif;
//		
//		
//		send.From.Address = Constants.Email.Get();
//		send.From.DisplayName = "AccountingSuite";
//		send.Subject = Constants.SystemTitle.Get() + " - Credit Memo " + Object.Number + " from " + Format(Object.Date,"DLF=D") + " - $" + Format(Object.DocumentTotalRC,"NFD=2");
//		
//		FormatHTML = FormAttributeToValue("Object").GetTemplate("Template").GetText();
//	 	  
//	 	 
//		FormatHTML2 = StrReplace(FormatHTML,"object.number",object.RefNum);
//		
//		FormatHTML2 = StrReplace(FormatHTML2,"imagelogo",imagelogo);
//	 	  FormatHTML2 = StrReplace(FormatHTML2,"object.date",Format(object.Date,"DLF=D"));
//	 	  //BillTo
//	 	  FormatHTML2 = StrReplace(FormatHTML2,"object.company",object.Company);

//		  Query = New Query("SELECT
//						  |	Addresses.FirstName,
//						  |	Addresses.MiddleName,
//						  |	Addresses.LastName,
//						  |	Addresses.Phone,
//						  |	Addresses.Fax,
//						  |	Addresses.Email,
//						  |	Addresses.AddressLine1,
//						  |	Addresses.AddressLine2,
//						  |	Addresses.City,
//						  |	Addresses.State.Code AS State,
//						  |	Addresses.Country,
//						  |	Addresses.ZIP,
//						  |	Addresses.RemitTo
//						  |FROM
//						  |	Catalog.Addresses AS Addresses
//						  |WHERE
//						  |	Addresses.Owner = &Company
//						  |	AND Addresses.DefaultBilling = TRUE");
//		Query.SetParameter("Company", object.company);
//			QueryResult = Query.Execute();	
//		Dataset = QueryResult.Unload();

//		  
//		  
//		  FormatHTML2 = StrReplace(FormatHTML2,"object.shipto1",Dataset[0].AddressLine1);
//	 	  FormatHTML2 = StrReplace(FormatHTML2,"object.shipto2",Dataset[0].AddressLine2);
//	 	 CityStateZip = Dataset[0].City + Dataset[0].State + Dataset[0].ZIP;
//	 	 
//	 	 If CityStateZip = "" Then
//	 	 	FormatHTML2 = StrReplace(FormatHTML2,"object.city object.state object.zip","");
//	 	 Else
//	 	  	FormatHTML2 = StrReplace(FormatHTML2,"object.city object.state object.zip",Dataset[0].City + ", " + Dataset[0].State + " " + Dataset[0].ZIP);
//	 	 Endif;
//	 	  FormatHTML2 = StrReplace(FormatHTML2,"object.country",Dataset[0].Country);
//	 	  //lineitems
//	 	  FormatHTML2 = StrReplace(FormatHTML2,"lineitems",datastring);
// 	   
//	 	  //User's company info
//	 	  FormatHTML2 = StrReplace(FormatHTML2,"mycompany",Constants.SystemTitle.Get()); 
//	 	  FormatHTML2 = StrReplace(FormatHTML2,"myaddress1",Constants.AddressLine1.Get());
//	 	  FormatHTML2 = StrReplace(FormatHTML2,"myaddress2",Constants.AddressLine2.Get());
//	 	  FormatHTML2 = StrReplace(FormatHTML2,"mycity mystate myzip",Constants.City.Get() + ", " + Constants.State.Get() + " " + Constants.ZIP.Get());
//	 	  FormatHTML2 = StrReplace(FormatHTML2,"myphone",Constants.Phone.Get());
//	 	  FormatHTML2 = StrReplace(FormatHTML2,"myemail",Constants.Email.Get());
//	 	  
//	 	  FormatHTML2 = StrReplace(FormatHTML2,"object.subtotal",Format(Object.DocumentTotalRC,"NFD=2"));
//		  
//	   If object.SalesTaxRC = 0 Then
//			FormatHTML2 = StrReplace(FormatHTML2,"object.salestax","0.00");
//	   Else
//	 	 	 FormatHTML2 = StrReplace(FormatHTML2,"object.salestax",Format(object.SalesTaxRC,"NFD=2"));
//	   Endif;
//  
//		  
//	   If TotalAmount = 0 Then
//	 	   FormatHTML2 = StrReplace(FormatHTML2,"object.total","0.00");
//	   Else
//	  		 FormatHTML2 = StrReplace(FormatHTML2,"object.total",Format(TotalAmount,"NFD=2"));
//	   Endif;

//	   //Note
//	   FormatHTML2 = StrReplace(FormatHTML2,"object.note",Object.EmailNote);
//	  
//		send.Texts.Add(FormatHTML2,InternetMailTextType.HTML);
//			
//		Posta = New InternetMail; 
//		Posta.Logon(MailProfil); 
//		Posta.Send(send); 
//		Posta.Logoff();
//		
//		Message("Credit Memo email has been sent");
//		
//		SentEmail = True;

//		Else
//	 		 Message("The recipient email has not been specified");
//		Endif;
//	 	
//	Endif;
	

 EndProcedure
 
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
Procedure OnCloseAtServer()

	If SentEmail = True Then
		
		DocObject = object.ref.GetObject();
		DocObject.EmailTo = Object.EmailTo;
		DocObject.LastEmail = "Last email on " + Format(CurrentDate(),"DLF=DT") + " to " + Object.EmailTo;
		DocObject.Write();
	Endif;

EndProcedure

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

//Closing period
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
Procedure SalesTaxOnChangeAtServer()
	// Insert handler contents.
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

&AtClient
// Returns fields structure of LineItems form control.
Function GetLineItemsRowStructure()
	
	// Define control row fields.
	Return New Structure("LineNumber, Product, ProductDescription, UnitSet, QtyUnits, Unit, QtyUM, UM, PriceUnits, LineTotal, Taxable, Project, Class, AvataxTaxCode, DiscountIsTaxable");

EndFunction

&AtServer
Procedure LineItemsLineTotalOnChangeAtServer(TableSectionRow)
	
	// Back-calculation of quantity in base units.
	TableSectionRow.QtyUM      = Round(Round(TableSectionRow.QtyUnits, QuantityPrecision) *
	                             ?(TableSectionRow.Unit.Factor > 0, TableSectionRow.Unit.Factor, 1), QuantityPrecision);
	
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
Procedure AuditLogRecord(Command)

	FormParameters = New Structure();	
	FltrParameters = New Structure();
	FltrParameters.Insert("DocUUID", String(Object.Ref.UUID()));
	FormParameters.Insert("Filter", FltrParameters);
	OpenForm("CommonForm.AuditLogList",FormParameters, Object.Ref);

EndProcedure

&AtServer
Procedure UpdateAuditLogCount()
	
	Query = New Query;
	Query.Text = "SELECT
	             |	AuditLog.ObjUUID
	             |FROM
	             |	InformationRegister.AuditLog AS AuditLog
	             |WHERE
	             |	AuditLog.ObjUUID = &DocUUID";
	Query.SetParameter("DocUUID", String(Object.Ref.UUID()));
	QueryResult = Query.Execute().Unload();

	Items.AuditLogRecord.Title = "Audit Log Entries (" + QueryResult.Count() + ")";	
	                                     
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
		AvataxServer.RestoreCalculatedSalesTax(Object);
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

#EndRegion
