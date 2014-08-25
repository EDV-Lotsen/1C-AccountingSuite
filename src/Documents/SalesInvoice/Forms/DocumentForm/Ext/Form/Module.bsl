
////////////////////////////////////////////////////////////////////////////////
// Sales invoice: Document form
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
	
	// Request and fill invoice status.
	FillInvoiceStatusAtServer();
	
	// Request and fill ordered items from database.
	FillBackorderQuantityAtServer();
	
	//------------------------------------------------------------------------------
	// 3. Set custom controls presentation.
	
	// Set proper company field presentation.
	CustomerName                    = GeneralFunctionsReusable.GetCustomerName();
	Items.Company.Title             = CustomerName;
	Items.Company.ToolTip           = StringFunctionsClientServer.SubstituteParametersInString(NStr("en = '%1 name'"),             CustomerName);
	//Items.RefNum.Title              = StringFunctionsClientServer.SubstituteParametersInString(NStr("en = '%1 P.O. / Ref. #'"),    CustomerName);
	//Items.RefNum.ToolTip            = StringFunctionsClientServer.SubstituteParametersInString(NStr("en = '%1 purchase order number /
	//																									  |Reference number'"),    CustomerName);
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
	Items.LineItemsOrdered.EditFormat   = QuantityFormat;
	Items.LineItemsOrdered.Format       = QuantityFormat;
	Items.LineItemsShipped.EditFormat   = QuantityFormat;
	Items.LineItemsShipped.Format       = QuantityFormat;
	Items.LineItemsInvoiced.EditFormat  = QuantityFormat;
	Items.LineItemsInvoiced.Format      = QuantityFormat;
	Items.LineItemsBackorder.EditFormat = QuantityFormat;
	Items.LineItemsBackorder.Format     = QuantityFormat;
	
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
	Items.TaxableSubtotalCurrency.Title = ForeignCurrencySymbol;
	
	// Update visibility of controls depending on functional options.
	If Not GeneralFunctionsReusable.FunctionalOptionValue("MultiCurrency") Then
		//Items.FCYGroup.Visible     = False;
		Items.RCCurrency.Title 	= ""; 
	EndIf;
	
	// -> CODE REVIEW
	// Cancel opening form if filling on the base was failed
	If Object.Ref.IsEmpty() And Parameters.Basis <> Undefined
	And Object.Company <> Parameters.Basis.Company Then
		// Object is not filled as expected
		Cancel = True;
		Return;
	EndIf;
	
	// Set send/pay buttons availability.
	If Object.Paid Then
		CommandBar.ChildItems.FormPayInvoice.Enabled = False;
	Endif;
		
	If Object.Ref.IsEmpty() Then
		Object.EmailNote = Constants.SalesInvoiceFooter.Get();
	EndIf;
	
	// checking if Reverse journal entry button was clicked
	If Parameters.Property("timetrackobjs") Then
		FillFromTimeTrack(Parameters.timetrackobjs,Parameters.invoicedate);
		TimeEntriesAddr = PutToTempStorage(Parameters.timetrackobjs, New UUID());	
	EndIf;
	
	UpdateInformationPayments();
		
EndProcedure

// -> CODE REVIEW
&AtClient
Procedure OnOpen(Cancel)
	
	OnOpenAtServer();
	
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

&AtServer
Procedure OnOpenAtServer()
	If Object.PaidInvoice = True Then
		//CommandBar.ChildItems.FormPayInvoice.Enabled = False;
	Endif;
	
	Try
		Query = New Query;
		Query.Text = "SELECT
		             |	GeneralJournalBalance.AmountBalance AS Bal,
		             |	GeneralJournalBalance.Account.Ref
		             |FROM
		             |	AccountingRegister.GeneralJournal.Balance AS GeneralJournalBalance
		             |WHERE
		             |	GeneralJournalBalance.ExtDimension2 = &SalesInvoice";
		Query.SetParameter("SalesInvoice", Object.Ref);
		
		QueryResult = Query.Execute().Unload();
		
		If QueryResult.Count() = 0 Then
			
			CommandBar.ChildItems.FormPayInvoice.Enabled = False;
			
		EndIf;
	Except
	EndTry;
	
	//prepay beg
	If Object.PrePaySO <> "" Then
		Message("You have unapplied payments to " + Object.PrePaySO + ". Please apply them using the Cash Receipt document.");
		Object.PrePaySO = "";
	EndIf;
	//prepay end
	
EndProcedure

&AtClient
Procedure OnClose()
	
	OnCloseAtServer();
	
EndProcedure

&AtServer
Procedure OnCloseAtServer()
		
	If InvoicePaid Then
		DocObject = object.ref.GetObject();
		DocObject.Paid = True;
		DocObject.Write();
	Endif;
	
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
// <- CODE REVIEW

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// -> CODE REVIEW
	// Check empty bill.
	If Object.LineItems.Count() = 0 Then
		Message("Cannot post/save with no line items.");
		Cancel = True;
	EndIf;
	
	//Period closing
	If PeriodClosingServerCall.DocumentPeriodIsClosed(CurrentObject.Ref, CurrentObject.Date) Then
		PermitWrite = PeriodClosingServerCall.DocumentWritePermitted(WriteParameters);
		CurrentObject.AdditionalProperties.Insert("PermitWrite", PermitWrite);
	EndIf;
	// <- CODE REVIEW
	
	
	//------------------------------------------------------------------------------
	// 1. Correct the invoice date according to the orders dates.
	
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

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	If FirstNumber <> "" Then
		
		Numerator = Catalogs.DocumentNumbering.SalesInvoice.GetObject();
		NextNumber = GeneralFunctions.Increment(Numerator.Number);
		If FirstNumber = NextNumber And NextNumber = Object.Number Then
			Numerator.Number = FirstNumber;
			Numerator.Write();
		EndIf;
		
		FirstNumber = "";
	EndIf;
	
	//------------------------------------------------------------------------------
	// Recalculate values of form object attributes.
	
	// Request and fill invoice status from database.
	FillInvoiceStatusAtServer();
	
	// Request and fill ordered items from database.
	FillBackorderQuantityAtServer();
	
	// Update Time Entries that reference this Sales Invoice.
	UpdateTimeEntries();

	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "SalesTaxRateAdded" Then
		If Items.SalesTaxRate.ChoiceList.FindByValue(Parameter) = Undefined Then
			Items.SalesTaxRate.ChoiceList.Add(Parameter);
		EndIf;
	EndIf;
	
	If EventName = "UpdatePayInvoiceInformation" And Parameter = Object.Company Then
		
		UpdateInformationPayments();
		
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
	
	// Update due date basing on the currently selected terms.
	If Not Object.Terms.IsEmpty() Then
		Object.DueDate = Object.Date + Object.Terms.Days * 60*60*24;
		// Does not require standard processing.
	EndIf;
	
EndProcedure

&AtClient
Procedure CompanyOnChange(Item)
	
	// Request server operation.
	CompanyOnChangeAtServer();
	
	//Perform client operations
	CompanyOnChangeAtClient();
	
	// Select non-closed orders by the company.
	CompanyOnChangeOrdersSelection(Item);
	
EndProcedure

&AtServer
Procedure CompanyOnChangeAtServer()
	
	// Reset company adresses (if company was changed).
	FillCompanyAddressesAtServer(Object.Company, Object.ShipTo, Object.BillTo, Object.ConfirmTo);
	ConfirmToEmail = CommonUse.GetAttributeValue(Object.ConfirmTo, "Email");
	ShipToEmail    = CommonUse.GetAttributeValue(Object.ShipTo, "Email");
	Object.EmailTo = ?(ValueIsFilled(Object.ConfirmTo), ConfirmToEmail, ShipToEmail);
	
	// Request company default settings.
	Object.Currency        = Object.Company.DefaultCurrency;
	Object.Terms           = Object.Company.Terms;
	Object.SalesPerson     = Object.Company.SalesPerson;
	
	// Check company orders for further orders selection.
	FillCompanyHasNonClosedOrders();
	
	// Process settings changes.
	CurrencyOnChangeAtServer();
	TermsOnChangeAtServer();
	
	SalesTaxRate = SalesTax.GetDefaultSalesTaxRate(Object.Company);
	
	//newALAN
	If Object.Company.ARAccount <> ChartsofAccounts.ChartOfAccounts.EmptyRef() Then
		Object.ARAccount = Object.Company.ARAccount;
	Else
		DefaultCurrency = GeneralFunctionsReusable.DefaultCurrency();
		Object.ARAccount = DefaultCurrency.DefaultARAccount;
	EndIf;
	
EndProcedure

&AtClient
Procedure CompanyOnChangeAtClient()
	
	//// Reset company adresses (if company was changed).
	//FillCompanyAddressesAtServer(Object.Company, Object.ShipTo, Object.BillTo, Object.ConfirmTo);
	//ConfirmToEmail 	= CommonUse.GetAttributeValue(Object.ConfirmTo, "Email");
	//ShipToEmail		= CommonUse.GetAttributeValue(Object.ShipTo, "Email");
	//Object.EmailTo = ?(ValueIsFilled(Object.ConfirmTo), ConfirmToEmail, ShipToEmail);
	
	// Recalculate sales prices for the company.
	//FillRetailPricesAtClient();
	
	//// Request company default settings.
	//CompanyDefaultSettings = CommonUse.GetAttributeValues(Object.Company, "DefaultCurrency, Terms, SalesPerson");
	//Object.Currency        = CompanyDefaultSettings.DefaultCurrency;
	//Object.Terms           = CompanyDefaultSettings.Terms;
	//Object.SalesPerson     = CompanyDefaultSettings.SalesPerson;
	
	//SalesTaxRate = SalesTax.GetDefaultSalesTaxRate(Object.Company);
	//SetSalesTaxRate(SalesTaxRate);
	If SalesTaxRate <> Object.SalesTaxRate Then
		Object.SalesTaxRate = SalesTaxRate;
		Object.SalesTaxAcrossAgencies.Clear();
		ShowSalesTaxRate();
	EndIf;
	RecalculateTotals();
	
	//// Check company orders for further orders selection.
	//FillCompanyHasNonClosedOrders();
	//
	//// Process settings changes.
	//CurrencyOnChangeAtServer();
	//TermsOnChangeAtServer();
	
EndProcedure

&AtClient
Procedure CompanyOnChangeOrdersSelection(Item)
	
	// Suggest filling of invoice by non-closed orders.
	If (Not Object.Company.IsEmpty()) And (CompanyHasNonClosedOrders) Then
		
		// Define form parameters.
		FormParameters = New Structure();
		FormParameters.Insert("ChoiceMode",     True);
		FormParameters.Insert("MultipleChoice", True);
		
		// Define order statuses array.
		OrderStatuses  = New Array;
		OrderStatuses.Add(PredefinedValue("Enum.OrderStatuses.Open"));
		OrderStatuses.Add(PredefinedValue("Enum.OrderStatuses.Backordered"));
		
		// Define list filter.
		FltrParameters = New Structure();
		FltrParameters.Insert("Company",     Object.Company); 
		FltrParameters.Insert("OrderStatus", OrderStatuses);
		FormParameters.Insert("Filter",      FltrParameters);
		
		// Open orders selection form.
		NotifyDescription = New NotifyDescription("CompanyOnChangeOrdersSelectionChoiceProcessing", ThisForm);
		OpenForm("Document.SalesOrder.ChoiceForm", FormParameters, Item,,,, NotifyDescription);
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
	
	// Request server operation.
	ShipToOnChangeAtServer();
	
EndProcedure

&AtServer
Procedure ShipToOnChangeAtServer()
	
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
	Items.FCYCurrency.Title 		 = ForeignCurrencySymbol;
	Items.TaxableSubtotalCurrency.Title = ForeignCurrencySymbol;
	
	// Request currency default settings.
	Object.ExchangeRate            = GeneralFunctions.GetExchangeRate(Object.Date, Object.Currency);
	Object.ARAccount               = Object.Currency.DefaultARAccount;
	
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
	
	// Request server operation.
	TermsOnChangeAtServer();
	
EndProcedure

&AtServer
Procedure TermsOnChangeAtServer()
	
	// Define empty date.
	EmptyDate = '00010101';
	
	// Update due date basing on the currently selected terms.
	Object.DueDate = ?(Not Object.Terms.IsEmpty(), Object.Date + Object.Terms.Days * 60*60*24, EmptyDate);
	// Does not require standard processing.
	
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
Procedure SalesTaxOnChange(Item)
	
	// Request server operation.
	SalesTaxOnChangeAtServer();
	
EndProcedure

&AtServer
Procedure SalesTaxOnChangeAtServer()
	
	// Recalculate totals with new sales tax.
	RecalculateTotalsAtServer();
	
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
				Row.PriceUnits = Round(GeneralFunctions.RetailPrice(Object.Date, Row.Product, Object.Company) *
				                 ?(Row.Unit.Factor > 0, Row.Unit.Factor, 1) /
				                 ?(Row.UnitSet.DefaultSaleUnit.Factor > 0, Row.UnitSet.DefaultSaleUnit.Factor, 1) /
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
	ProductProperties = CommonUse.GetAttributeValues(TableSectionRow.Product,   New Structure("Description, UnitSet, Taxable"));
	UnitSetProperties = CommonUse.GetAttributeValues(ProductProperties.UnitSet, New Structure("DefaultSaleUnit"));
	TableSectionRow.ProductDescription = ProductProperties.Description;
	TableSectionRow.UnitSet            = ProductProperties.UnitSet;
	TableSectionRow.Unit               = UnitSetProperties.DefaultSaleUnit;
	//TableSectionRow.UM                 = UnitSetProperties.UM;
	TableSectionRow.Taxable            = ProductProperties.Taxable;
	TableSectionRow.PriceUnits         = Round(GeneralFunctions.RetailPrice(Object.Date, TableSectionRow.Product, Object.Company) /
	                                     // The price is returned for default sales unit factor.
	                                     ?(Object.ExchangeRate > 0, Object.ExchangeRate, 1), 2);
	
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
	TableSectionRow.Ordered   = 0;
	TableSectionRow.Backorder = 0;
	TableSectionRow.Shipped   = 0;
	TableSectionRow.Invoiced  = 0;
	
	// Calculate totals by line.
	TableSectionRow.LineTotal     = 0;
	TableSectionRow.TaxableAmount = 0;
	
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
	                             ?(Object.ExchangeRate > 0, Object.ExchangeRate, 1), 2);
	
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
	
	//// Update backorder quantity basing on document status.
	//If OrderStatus = Enums.OrderStatuses.Open Then
	//	TableSectionRow.Backorder = 0;
	//	
	//ElsIf OrderStatus = Enums.OrderStatuses.Backordered Then
	//	If TableSectionRow.Product.Type = Enums.InventoryTypes.Inventory Then
	//		TableSectionRow.Backorder = Max(TableSectionRow.Quantity - TableSectionRow.Received, 0);
	//	Else // TableSectionRow.Product.Type = Enums.InventoryTypes.NonInventory;
	//		TableSectionRow.Backorder = Max(TableSectionRow.Quantity - TableSectionRow.Invoiced, 0);
	//	EndIf;
	//	
	//ElsIf OrderStatus = Enums.OrderStatuses.Closed Then
	//	TableSectionRow.Backorder = 0;
	//	
	//Else
	//	TableSectionRow.Backorder = 0;
	//EndIf;
	
	// Calculate total by line.
	TableSectionRow.LineTotal = Round(Round(TableSectionRow.QtyUnits, QuantityPrecision) * TableSectionRow.PriceUnits, 2);
	
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
	
	// Load processed data back.
	FillPropertyValues(Items.LineItems.CurrentData, TableSectionRow);
	
	// Refresh totals cache.
	RecalculateTotals();
	
EndProcedure

&AtServer
Procedure LineItemsLineTotalOnChangeAtServer(TableSectionRow)
	
	// Back-step price calculation with totals priority.
	TableSectionRow.PriceUnits = ?(TableSectionRow.QtyUnits > 0,
	                             Round(TableSectionRow.LineTotal / Round(TableSectionRow.QtyUnits, QuantityPrecision), 2), 0);
	
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
	
EndProcedure

&AtClient
Procedure LineItemsTaxableAmountOnChange(Item)
	
	// Refresh totals cache.
	RecalculateTotals();
	
EndProcedure

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region COMMANDS_HANDLERS

// -> CODE REVIEW
//------------------------------------------------------------------------------
// Send invoice by email.

&AtClient
Procedure SendEmail(Command)
	
	If Object.Ref.IsEmpty() OR IsPosted() = False Then
		Message("An email cannot be sent until the invoice is posted");
	Else	
		FormParameters = New Structure("Ref",Object.Ref );
		OpenForm("CommonForm.EmailForm", FormParameters,,,,,, FormWindowOpeningMode.LockOwnerWindow);	
	EndIf;
	
EndProcedure

// Check if document has been posted, return bool value.

&AtServer
Function IsPosted()
	Return Object.Ref.Posted;	
EndFunction

//------------------------------------------------------------------------------
// Pay invoice electronically.

&AtClient
Procedure PayInvoice(Command)
	
	SIObj = New Structure;
	SIObj.Insert("SalesInvoice", Object.Ref);
	OpenForm("Document.CashReceipt.ObjectForm",SIObj);
	
	// Currently is not used.
	// PayInvoiceAtServer();
	
EndProcedure

//&AtServer
//Procedure PayInvoiceAtServer()
//	
//	If Object.Posted = False Then
//		Message("A cash receipt cannot be created for the invoice because it has not yet been created(posted)");
//	Else
//	
//		NewCashReceipt = Documents.CashReceipt.CreateDocument();
//		NewCashReceipt.Company = Object.Company;
//		NewCashReceipt.Date = CurrentDate();
//		NewCashReceipt.Currency = Object.Currency;
//		NewCashReceipt.DepositType = "1";
//		NewCashReceipt.DocumentTotalRC = Object.DocumentTotalRC;
//		NewCashReceipt.CashPayment = Object.DocumentTotalRC;
//		NewCashReceipt.ARAccount = Object.ARAccount;
//		
//		NewLine = NewCashReceipt.LineItems.Add();
//		NewLine.Document = Object.Ref;
//		NewLine.Balance = Object.DocumentTotalRC;
//		NewLine.Payment = Object.DocumentTotalRC;
//		Newline.Currency = Object.Currency;
//		
//		NewCashReceipt.Write(DocumentWriteMode.Posting);
//		CommandBar.ChildItems.FormPayInvoice.Enabled = False;
//		InvoicePaid = True;
//		
//		Message("A Cash Receipt has been created for " + Object.Ref);
//		
//	Endif;
//	
//EndProcedure

//------------------------------------------------------------------------------
// Call AvaTax to request sales tax values.

&AtClient
Procedure AvaTax(Command)
	AvaTaxCall();
EndProcedure

&AtServer
Procedure AvaTaxCall()
		
	//DataJSON = "{""DocDate"": ""2013-06-01"",""CustomerCode"": ""abc456789"",""DocType"": ""SalesInvoice"",""Addresses"":[{""AddressCode"": ""Origin"",""Line1"": ""118 N Clark St"",""City"": ""Chicago"",""Region"": ""IL"",""PostalCode"": ""60602-1304"",""Country"": ""US""},{""AddressCode"": ""Dest"",""Line1"": ""1060 W. Addison St"",""City"": ""Chicago"",""Region"": ""IL"",""PostalCode"": ""60613-4566"",""Country"": ""US""}],""Lines"":[{""LineNo"": ""00001"",""DestinationCode"": ""Dest"",""OriginCode"": ""Origin"",""ItemCode"": ""SP-001"",""Description"": ""Running Shoe"",""TaxCode"": ""PC030147"",""Qty"": 1,""Amount"": 100}]}";
	
	//DataJSON = "{""DocDate"": ""2014-05-01"",""CustomerCode"": ""abc456789"",""DocType"": ""SalesInvoice"",""Addresses"":[{""AddressCode"": ""Origin1"",""Line1"": ""2535 Cleveland Ave"",""City"": ""Columbus"",""Region"": ""OH"",""PostalCode"": ""43211"",""Country"": ""US""},{""AddressCode"": ""Origin2"",""Line1"": ""8525 Winton Rd"",""City"": ""Cincinnati"",""Region"": ""OH"",""PostalCode"": ""45231"",""Country"": ""US""},{""AddressCode"": ""Dest1"",""Line1"": ""45 Kurtz Ave"",""City"": ""Dayton"",""Region"": ""OH"",""PostalCode"": ""45405"",""Country"": ""US""},{""AddressCode"": ""Dest2"",""Line1"": ""1979 W 25th St"",""City"": ""Cleveland"",""Region"": ""OH"",""PostalCode"": ""44113"",""Country"": ""US""}],""Lines"":[{""LineNo"": ""00001"",""DestinationCode"": ""Dest1"",""OriginCode"": ""Origin1"",""ItemCode"": ""SP-001"",""Description"": ""Running Shoe"",""TaxCode"": ""PC030147"",""Qty"": 1,""Amount"": 100},{""LineNo"": ""00002"",""DestinationCode"": ""Dest2"",""OriginCode"": ""Origin1"",""ItemCode"": ""SP-001"",""Description"": ""Running Shoe"",""TaxCode"": ""PC030147"",""Qty"": 1,""Amount"": 100},{""LineNo"": ""00003"",""DestinationCode"": ""Dest1"",""OriginCode"": ""Origin2"",""ItemCode"": ""SP-001"",""Description"": ""Running Shoe"",""TaxCode"": ""PC030147"",""Qty"": 1,""Amount"": 100},{""LineNo"": ""00004"",""DestinationCode"": ""Dest2"",""OriginCode"": ""Origin2"",""ItemCode"": ""SP-001"",""Description"": ""Running Shoe"",""TaxCode"": ""PC030147"",""Qty"": 1,""Amount"": 100}]}";
	//DataJSON = "{""DocDate"": ""2014-05-01"",""CustomerCode"": ""abc456789"",""DocType"": ""SalesInvoice"",""Addresses"":[{""AddressCode"": ""Origin1"",""Line1"": ""156 2nd St."",""City"": ""San Francisco"",""Region"": ""CA"",""PostalCode"": ""94105"",""Country"": ""US""},{""AddressCode"": ""Dest1"",""Line1"": ""Russell Pl"",""City"": ""Brighton"",""Region"": ""BN1 2RG"",""PostalCode"": """",""Country"": ""United Kingdom""}],""Lines"":[{""LineNo"": ""00001"",""DestinationCode"": ""Dest1"",""OriginCode"": ""Origin1"",""ItemCode"": ""SP-001"",""Description"": ""Running Shoe"",""TaxCode"": ""PC030147"",""Qty"": 1,""Amount"": 100},{""LineNo"": ""00002"",""DestinationCode"": ""Dest1"",""OriginCode"": ""Origin1"",""ItemCode"": ""SP-001"",""Description"": ""Running Shoe"",""TaxCode"": ""PC030147"",""Qty"": 1,""Amount"": 100}], ""BusinessIdentificationNo"": ""GB999 9999 73""}";
	DataJSON = "{""DocDate"": ""2014-05-01"",""CustomerCode"": ""abc456789"",""BusinessIdentificationNo"": ""391532058"",""CurrencyCode"": ""GBP"",""DocType"": ""SalesInvoice"",""Addresses"":[{""AddressCode"": ""Origin1"",""Line1"": ""156 2nd St."",""City"": ""San Francisco"",""Region"": ""CA"",""PostalCode"": ""94105"",""Country"": ""US""},{""AddressCode"": ""Dest1"",""Line1"": ""Unit 3 Factory"",""City"": ""Upton"",""Region"": """",""PostalCode"": ""BH16 5SJ"",""Country"": ""GB""}],""Lines"":[{""LineNo"": ""00001"",""DestinationCode"": ""Dest1"",""OriginCode"": ""Origin1"",""ItemCode"": ""SP-001"",""Description"": ""Running Shoe"",""TaxCode"": ""PB200742"",""Qty"": 1,""Amount"": 100000},{""LineNo"": ""00002"",""DestinationCode"": ""Dest1"",""OriginCode"": ""Origin1"",""ItemCode"": ""SP-001"",""Description"": ""Running Shoe"",""TaxCode"": ""PB200742"",""Qty"": 1,""Amount"": 100000}]}";
	
	HeadersMap = New Map();
	HeadersMap.Insert("Content-Type", "text/json");
	HeadersMap.Insert("Authorization", ServiceParameters.AvalaraAuth());
	ConnectionSettings = New Structure;
	Connection = InternetConnectionClientServer.CreateConnection("https://avatax.avalara.net/1.0/tax/get", ConnectionSettings).Result; // https://development.avalara.net
	ResultBody = InternetConnectionClientServer.SendRequest(Connection, "Post", ConnectionSettings, HeadersMap, DataJSON).Result;
	DecodedResultBody = InternetConnectionClientServer.DecodeJSON(ResultBody);
	Object.SalesTax = DecodedResultBody.TotalTax;
	RecalculateTotalsAtServer();
	
EndProcedure

// <- CODE REVIEW

&AtClient
Procedure PostAndClose(Command)
	
	//PerformanceMeasurementClientServer.StartTimeMeasurement("Sales Invoice Post and Close");
	
	If Write(New Structure("WriteMode", DocumentWriteMode.Posting)) Then Close() EndIf;
	
EndProcedure

&AtClient
Procedure Save(Command)
	
	//PerformanceMeasurementClientServer.StartTimeMeasurement("Sales Invoice Save");
	
	Write();
	
EndProcedure

&AtClient
Procedure Post(Command)
	
	//PerformanceMeasurementClientServer.StartTimeMeasurement("Sales Invoice Post");
	
	Write(New Structure("WriteMode", DocumentWriteMode.Posting));
	
EndProcedure

&AtClient
Procedure ClearPosting(Command)
	
	Write(New Structure("WriteMode", DocumentWriteMode.UndoPosting));
	
EndProcedure

&AtClient
Procedure Payments(Command)
	
	FormParameters = New Structure();
	
	FltrParameters = New Structure();
	FltrParameters.Insert("InvoisPays", Object.Ref);
	FormParameters.Insert("Filter", FltrParameters);
	OpenForm("CommonForm.InvoicePayList",FormParameters, Object.Ref);
	
EndProcedure

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region PRIVATE_IMPLEMENTATION

//------------------------------------------------------------------------------
// Calculate values of form object attributes.

&AtServer
// Request invoice status from database.
Procedure FillInvoiceStatusAtServer()
	
	// Request invoice status.
	If (Not ValueIsFilled(Object.Ref)) Or (Object.DeletionMark) Or (Not Object.Posted) Then
		// The invoice has open status.
		InvoiceStatus = Enums.InvoiceStatuses.Open;
		
	Else
		// Create new query.
		Query = New Query;
		Query.SetParameter("Ref",     Object.Ref);
		Query.SetParameter("Company", Object.Company);
		Query.SetParameter("Account", Object.ARAccount);
		
		// Request payable amount for the account.
		Query.Text =
			"SELECT
			|	GeneralJournalBalance.AmountBalance AS Amount
			|FROM
			|	AccountingRegister.GeneralJournal.Balance(, Account = &Account,, ExtDimension1 = &Company AND ExtDimension2 = &Ref) AS GeneralJournalBalance";
		Selection = Query.Execute().Select();
		
		// Fill invoice status.
		If Selection.Next() Then
			// Liabilities found.
			If    Selection.Amount > 0 Then InvoiceStatus = Enums.InvoiceStatuses.Open;
			ElsIf Selection.Amount = 0 Then InvoiceStatus = Enums.InvoiceStatuses.Paid;
			ElsIf Selection.Amount < 0 Then InvoiceStatus = Enums.InvoiceStatuses.Overpaid;
			EndIf;
		Else
			InvoiceStatus = Enums.InvoiceStatuses.NoCharge;
		EndIf;
	EndIf;
	
	// Fill extended invoice status presentation (depending of document state).
	If Not ValueIsFilled(Object.Ref) Then
		InvoiceStatusPresentation = String(Enums.InvoiceStatuses.New);
		Items.InvoiceStatusPresentation.TextColor = WebColors.DarkGray;
		
	ElsIf Object.DeletionMark Then
		InvoiceStatusPresentation = String(Enums.InvoiceStatuses.Deleted);
		Items.InvoiceStatusPresentation.TextColor = WebColors.DarkGray;
		
	ElsIf Not Object.Posted Then 
		InvoiceStatusPresentation = String(Enums.InvoiceStatuses.Draft);
		Items.InvoiceStatusPresentation.TextColor = WebColors.DarkGray;
		
	Else
		InvoiceStatusPresentation = String(InvoiceStatus);
		If InvoiceStatus = Enums.InvoiceStatuses.Open Then 
			ThisForm.Items.InvoiceStatusPresentation.TextColor = WebColors.DarkRed;
		ElsIf InvoiceStatus = Enums.InvoiceStatuses.Paid Then 
			ThisForm.Items.InvoiceStatusPresentation.TextColor = WebColors.DarkGreen;
		ElsIf InvoiceStatus = Enums.InvoiceStatuses.Overpaid Then
			ThisForm.Items.InvoiceStatusPresentation.TextColor = WebColors.DarkGoldenRod;
		ElsIf InvoiceStatus = Enums.InvoiceStatuses.NoCharge Then
			ThisForm.Items.InvoiceStatusPresentation.TextColor = WebColors.DarkGreen;
		Else
			ThisForm.Items.InvoiceStatusPresentation.TextColor = WebColors.DarkGray;
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
// Request demanded order items from database.
Procedure FillBackorderQuantityAtServer()
	
	// Request ordered items quantities
	If ValueIsFilled(Object.Ref) Then
		
		//// Create new query
		//Query = New Query;
		//Query.SetParameter("Ref", Object.Ref);
		//Query.SetParameter("OrderStatus", OrderStatus);
		//
		//Query.Text = 
		//	"SELECT
		//	|	LineItems.LineNumber                     AS LineNumber,
		//	//  Request dimensions
		//	|	OrdersRegisteredBalance.Product          AS Product,
		//	|	OrdersRegisteredBalance.Location         AS Location,
		//	|	OrdersRegisteredBalance.DeliveryDate     AS DeliveryDate,
		//	|	OrdersRegisteredBalance.Project          AS Project,
		//	|	OrdersRegisteredBalance.Class            AS Class,
		//	//  Request resources                                                                                               // ---------------------------------------
		//	|	OrdersRegisteredBalance.QuantityBalance  AS Quantity,                                                           // Backorder quantity calculation
		//	|	CASE                                                                                                            // ---------------------------------------
		//	|		WHEN &OrderStatus = VALUE(Enum.OrderStatuses.Open)        THEN 0                                            // Order status = Open:
		//	|		WHEN &OrderStatus = VALUE(Enum.OrderStatuses.Backordered) THEN                                              //   Backorder = 0
		//	|			CASE                                                                                                    // Order status = Backorder:
		//	|				WHEN OrdersRegisteredBalance.Product.Type = VALUE(Enum.InventoryTypes.Inventory) THEN               //   Inventory:
		//	|					CASE                                                                                            //     Backorder = Ordered - Shipped >= 0
		//	|						WHEN OrdersRegisteredBalance.QuantityBalance > OrdersRegisteredBalance.ShippedBalance THEN  //     |
		//	|							 OrdersRegisteredBalance.QuantityBalance - OrdersRegisteredBalance.ShippedBalance       //     |
		//	|						ELSE 0 END                                                                                  //     |
		//	|				ELSE                                                                                                //   Non-inventory:
		//	|					CASE                                                                                            //     Backorder = Ordered - Invoiced >= 0
		//	|						WHEN OrdersRegisteredBalance.QuantityBalance > OrdersRegisteredBalance.InvoicedBalance THEN //     |
		//	|							 OrdersRegisteredBalance.QuantityBalance - OrdersRegisteredBalance.InvoicedBalance      //     |
		//	|						ELSE 0 END                                                                                  //     |
		//	|				END                                                                                                 //     |
		//	|		WHEN &OrderStatus = VALUE(Enum.OrderStatuses.Closed)      THEN 0                                            // Order status = Closed:
		//	|		END                                  AS Backorder,                                                          //                           Backorder = 0
		//	|	OrdersRegisteredBalance.ShippedBalance   AS Shipped,
		//	|	OrdersRegisteredBalance.InvoicedBalance  AS Invoiced
		//	//  Request sources
		//	|FROM
		//	|	Document.SalesOrder.LineItems            AS LineItems
		//	|	LEFT JOIN AccumulationRegister.OrdersRegistered.Balance(,Order = &Ref)
		//	|	                                         AS OrdersRegisteredBalance
		//	|		ON    ( LineItems.Ref.Company         = OrdersRegisteredBalance.Company
		//	|			AND LineItems.Ref                 = OrdersRegisteredBalance.Order
		//	|			AND LineItems.Product             = OrdersRegisteredBalance.Product
		//	|			AND LineItems.Location            = OrdersRegisteredBalance.Location
		//	|			AND LineItems.DeliveryDate        = OrdersRegisteredBalance.DeliveryDate
		//	|			AND LineItems.Project             = OrdersRegisteredBalance.Project
		//	|			AND LineItems.Class               = OrdersRegisteredBalance.Class
		//	|			AND LineItems.Quantity            = OrdersRegisteredBalance.QuantityBalance)
		//	//  Request filtering
		//	|WHERE
		//	|	LineItems.Ref = &Ref
		//	//  Request ordering
		//	|ORDER BY
		//	|	LineItems.LineNumber";
		//Selection = Query.Execute().Select();
		//
		//// Fill ordered items quantities
		//SearchRec = New Structure("LineNumber, Product, Location, DeliveryDate, Project, Class, Quantity");
		//While Selection.Next() Do
		//	
		//	// Search for appropriate line in tabular section of order
		//	FillPropertyValues(SearchRec, Selection);
		//	FoundLineItems = Object.LineItems.FindRows(SearchRec);
		//	
		//	// Fill quantities in tabular section
		//	If FoundLineItems.Count() > 0 Then
		//		FillPropertyValues(FoundLineItems[0], Selection, "Backorder, Shipped, Invoiced");
		//	EndIf;
		//	
		//EndDo;
		
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
		"SELECT
		|	SalesOrder.Ref
		|FROM
		|	Document.SalesOrder AS SalesOrder
		|	LEFT JOIN InformationRegister.OrdersStatuses.SliceLast AS OrdersStatuses
		|		ON SalesOrder.Ref = OrdersStatuses.Order
		|WHERE
		|	SalesOrder.Company = &Company
		|AND
		|	CASE
		|		WHEN SalesOrder.DeletionMark THEN
		|			 VALUE(Enum.OrderStatuses.Deleted)
		|		WHEN NOT SalesOrder.Posted THEN
		|			 VALUE(Enum.OrderStatuses.Draft)
		|		WHEN OrdersStatuses.Status IS NULL THEN
		|			 VALUE(Enum.OrderStatuses.Open)
		|		WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.EmptyRef) THEN
		|			 VALUE(Enum.OrderStatuses.Open)
		|		ELSE
		|			 OrdersStatuses.Status
		|	END IN (VALUE(Enum.OrderStatuses.Open), VALUE(Enum.OrderStatuses.Backordered))";
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
		
		// -> CODE REVIEW
		PrePayCheck(SelectedOrders);
		// <- CODE REVIEW
		
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
		EndIf;
		
		// Return fail (selection cancelled)
		Return False;
	EndIf;
	
EndFunction

// -> CODE REVIEW
&AtServer
Procedure PrePayCheck(SelectedOrders)
	
		SOString = "";
		OrderCount = 0;
		ExistBalance = False;
		
		
		For Each  SelectOrder In SelectedOrders Do
			
			Query = New Query;
			Query.Text = "SELECT
			             |	CashReceipt.Ref,
			             |	CashReceipt.Company
			             |FROM
			             |	Document.CashReceipt AS CashReceipt
			             |WHERE
			             |	CashReceipt.SalesOrder = &SaleOrder";
			Query.SetParameter("SaleOrder", SelectOrder.Ref);
			QueryResult = Query.Execute().Unload();
			
			Total = 0;
			For Each CashRec In QueryResult Do
				
				Query.Text = "SELECT
				             |	-GeneralJournalBalance.AmountBalance AS Bal,
				             |	GeneralJournalBalance.Account.Ref
				             |FROM
				             |	AccountingRegister.GeneralJournal.Balance AS GeneralJournalBalance
				             |WHERE
				             |	GeneralJournalBalance.ExtDimension2 = &CashReceipt
				             |	AND GeneralJournalBalance.ExtDimension1 = &Company";
				Query.SetParameter("CashReceipt", CashRec.Ref);
				Query.SetParameter("Company",CashRec.Company);

				QueryResult2 = Query.Execute().Unload();

				Total = Total + QueryResult2[0].Bal;
				
			EndDo;
			OrderCount = OrderCount + 1;
			
			Query.Text = "SELECT
             |	-GeneralJournalBalance.AmountBalance AS Bal,
             |	GeneralJournalBalance.Account.Ref
             |FROM
             |	AccountingRegister.GeneralJournal.Balance AS GeneralJournalBalance
             |WHERE
 			 |			ExtDimension1 = &Company AND
             |          (ExtDimension2 REFS Document.SalesReturn AND
             |			ExtDimension2.ReturnType = VALUE(Enum.ReturnTypes.CreditMemo))";
			Query.SetParameter("Company",SelectedOrders[0].Company);

			QueryResult3 = Query.Execute().Unload();
			
			Total = Total + QueryResult3.Total("Bal");

			
			If Total > 0 Then
				ExistBalance = True;
				If OrderCount = SelectedOrders.Count()Then
					SOString = SOString + SelectOrder.Ref;
				Else
					SOString = SOString + SelectOrder.Ref + ", ";
				EndIf;
			EndIf;

		EndDo;

		If ExistBalance = True Then
			Message("You have unapplied payments to " + SOString + ". Please apply them using the Cash Receipt document.");
		EndIf;	
	
EndProcedure
// <- CODE REVIEW

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
			CurrentAgenciesRates.Add(New Structure("Agency, Rate, SalesTaxRate, SalesTaxComponent", AgencyRate.Agency, AgencyRate.Rate, AgencyRate.SalesTaxRate, AgencyRate.SalesTaxComponent));
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
	Object.DocumentTotal    = Object.SubTotal + Object.Shipping + Object.SalesTax;
	Object.DocumentTotalRC  = Round(Object.DocumentTotal * Object.ExchangeRate, 2);
	
EndProcedure

&AtServer
// The procedure recalculates the document's totals.
Procedure RecalculateTotalsAtServer()
	
	// Calculate document totals.
	LineSubtotal = Object.LineItems.Total("LineTotal");
	TaxableSubtotal = Object.LineItems.Total("TaxableAmount");
	
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
		NewRow = Object.SalesTaxAcrossAgencies.Add();
		FillPropertyValues(NewRow, STAcrossAgencies);
	EndDo;
	Object.SalesTax = Object.SalesTaxAcrossAgencies.Total("Amount");
	
	// Calculate the rest of the totals.
	Object.SubTotal         = LineSubtotal + Object.Discount;
	Object.SalesTaxRC       = Round(Object.SalesTax * Object.ExchangeRate, 2);
	Object.DocumentTotal    = Object.SubTotal + Object.Shipping + Object.SalesTax;
	Object.DocumentTotalRC  = Round(Object.DocumentTotal * Object.ExchangeRate, 2);
	
EndProcedure

//------------------------------------------------------------------------------
// Replacemant for metadata properties on client.

&AtClient
// Returns fields structure of LineItems form control.
Function GetLineItemsRowStructure()
	
	// Define control row fields.
	Return New Structure("LineNumber, Product, ProductDescription, UnitSet, QtyUnits, Unit, QtyUM, UM, Ordered, Backorder, Shipped, Invoiced, PriceUnits, LineTotal, Taxable, TaxableAmount, Order, Location, LocationActual, DeliveryDate, DeliveryDateActual, Project, Class");
	
EndFunction

// When generated from time tracking, fills invoice with selected entries.
&AtServer
Procedure FillFromTimeTrack(timedocs,InvoiceDate)
		
	Object.Company = timedocs[0].Company;
	Object.Project = timedocs[0].Project;
	Object.Terms = Object.Company.Terms;
	Object.Memo = timedocs[0].Memo;
	Object.Date = InvoiceDate;
	If Not Object.Terms.IsEmpty() Then
		Object.DueDate = InvoiceDate + Object.Terms.Days * 60*60*24;
	EndIf;

	
	// query - find default shipping address of the company
		Query = New Query("SELECT
		                  |	Addresses.Ref
		                  |FROM
		                  |	Catalog.Addresses AS Addresses
		                  |WHERE
		                  |	Addresses.Owner = &Company
		                  |	AND Addresses.DefaultShipping = TRUE");
		Query.SetParameter("Company", timedocs[0].Company.Ref);
		
		QueryResult = Query.Execute();
					
		Dataset = QueryResult.Unload();
			
		If Dataset.Count() = 0 Then
			object.ShipTo = Catalogs.Addresses.EmptyRef();
		Else
			ShipToAddr = Dataset[0][0];
		Endif;

		object.ShipTo = ShipToAddr;
		
		// query - find default billing address of the company
		Query = New Query("SELECT
		                  |	Addresses.Ref
		                  |FROM
		                  |	Catalog.Addresses AS Addresses
		                  |WHERE
		                  |	Addresses.Owner = &Company
		                  |	AND Addresses.DefaultBilling = TRUE");
		Query.SetParameter("Company", timedocs[0].Company.Ref);
		
		QueryResult = Query.Execute();
					
		Dataset = QueryResult.Unload();
			
		If Dataset.Count() = 0 Then
			object.BillTo = Catalogs.Addresses.EmptyRef();
		Else
			BillToAddr = Dataset[0][0];
		Endif;

		object.BillTo = BillToAddr;
		
		If timedocs[0].Company.ARAccount = ChartsOfAccounts.ChartOfAccounts.EmptyRef() Then
			object.ARAccount = object.Currency.DefaultARAccount;
		Else	
			object.ARAccount = timedocs[0].Company.ARAccount;
		EndIf;

		For each Entry in timedocs Do
			
			NewLine = Object.LineItems.Add();
			NewLine.Location = Object.LocationActual;
			NewLine.LocationActual = Object.LocationActual;
			NewLine.DeliveryDate = Entry.DateFrom;
			NewLine.DeliveryDateActual = Entry.DateFrom;
			
			If Entry.SalesOrder.IsEmpty() = False Then
				NewLine.Order = Entry.SalesOrder;
				NewLine.DeliveryDate = Entry.SalesOrder.DeliveryDate;
				NewLine.DeliveryDateActual = Entry.DateFrom;
				NewLine.LocationActual = Entry.SalesOrder.Location;
				NewLine.Location = Entry.SalesOrder.Location;

			EndIf;

			
			NewLine.Product = Entry.Task;
			NewLine.ProductDescription = Entry.Memo;
			//NewLine.UM = NewLine.Product.UnitSet.UM;
			NewLine.PriceUnits = Entry.Price;
			NewLine.QtyUnits = Entry.TimeComplete;
			NewLine.LineTotal = Entry.Price * Entry.TimeComplete; 
			NewLine.Project = Entry.Project;
			NewLine.Class = Entry.Class;
					
		EndDo;
		
		Total = 0;	
		For Each LineItem In Object.LineItems Do
			Total = Total + LineItem.LineTotal;
		EndDo;
		
		Object.LineSubtotal = Total;
		Object.DocumentTotal = Total;
		Object.DocumentTotalRC = Total;
	
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

&AtClient
Procedure DiscountIsTaxableOnChange(Item)
	RecalculateTotals();
EndProcedure

&AtServer
Procedure UpdateTimeEntries()
	
	If TimeEntriesAddr <> "" Then
		TimeEntries  = GetFromTempStorage(TimeEntriesAddr);
		For Each Entry In TimeEntries Do
			EntryObject = Entry.Ref.GetObject();
			EntryObject.SalesInvoice = Object.Ref;
			EntryObject.InvoiceStatus = Enums.TimeTrackStatus.Billed;
			EntryObject.Write(DocumentWriteMode.Posting);		
		EndDo;
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateInformationPayments()
	
	Items.Payments.Title = "no payment(-s)";
	ThisForm.Commands.Find("Payments").ToolTip = "no payment(-s)";
	Items.Payments.TextColor = WebColors.Gray;
	Items.PayInvoice.Visible = True;
	
	Query = New Query;
	Query.Text = "SELECT
	             |	GeneralJournalTurnovers.ExtDimension2 AS Payment,
	             |	COUNT(DISTINCT GeneralJournalTurnovers.Recorder) AS Recorder,
	             |	SUM(-GeneralJournalTurnovers.AmountTurnover) AS Amount,
	             |	SUM(-GeneralJournalTurnovers.AmountRCTurnover) AS AmountRC
	             |FROM
	             |	AccountingRegister.GeneralJournal.Turnovers(, , Auto, , , ExtDimension2 = &Doc) AS GeneralJournalTurnovers
	             |WHERE
	             |	GeneralJournalTurnovers.Recorder <> &Doc
	             |
	             |GROUP BY
	             |	GeneralJournalTurnovers.ExtDimension2";

	Query.SetParameter("Doc", Object.Ref);

	QueryResult = Query.Execute();

	SelectionDetailRecords = QueryResult.Select();

	While SelectionDetailRecords.Next() Do
		
		Amount = Format(SelectionDetailRecords.Amount, "NFD=2; NZ=0.00");
		
		PaymentsTitle = "Cash receipts: " + SelectionDetailRecords.Recorder + " (" + Object.Currency.Symbol + Amount + ")";
		
		Items.Payments.Title = PaymentsTitle;		
		ThisForm.Commands.Find("Payments").ToolTip = PaymentsTitle;
		Items.Payments.TextColor = WebColors.Green;
		
		If Object.DocumentTotalRC > SelectionDetailRecords.AmountRC Then 
			Items.PayInvoice.Visible = True;
		Else
			Items.PayInvoice.Visible = False;
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion
