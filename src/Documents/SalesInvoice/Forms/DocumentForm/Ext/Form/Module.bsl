
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
		If Not ValueIsFilled(Object.DiscountType) Then
			Object.DiscountType = Enums.DiscountType.Percent;
		EndIf;
	EndIf;
	
	SetVisibilityByDiscount(ThisForm);
	
	If Parameters.Property("Company") And Parameters.Company.Customer And Object.Ref.IsEmpty() Then
		Object.Company = Parameters.Company;
		OpenOrdersSelectionForm = True; 
	EndIf;

	Items.DwollaRequest.Enabled = Object.DwollaTrxID = 0;
	
	//------------------------------------------------------------------------------
	// 1. Form attributes initialization.
	
	// Set LineItems editing flag.
	IsNewRow     = False;
	
	// Fill object attributes cache.
	DeliveryDateActual   = Object.DeliveryDateActual;
	LocationActual       = Object.LocationActual;
	Project              = Object.Project;
	Class                = Object.Class;
	Date                 = Object.Date;
	Company              = Object.Company;
	
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
				If ValueIsFilled(Parameters.Basis) Then //If filled on the basis of Sales Order
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
	
	If Parameters.Property("timetrackobjs") Then
		FillFromTimeTrack(Parameters.timetrackobjs,Parameters.invoicedate);
		TimeEntriesAddr = PutToTempStorage(Parameters.timetrackobjs, New UUID());	
	EndIf;
	
	UpdateInformationPayments();
	//UpdateAuditLogCount();
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
	
	//Because value type of BackgroundJobParameters is Arbitrary
	BackgroundJobParameters.Clear();
	
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
	
	//Avatax calculation
	AvaTaxClient.ShowQueryToTheUserOnAvataxCalculation("SalesInvoice", Object, ThisObject, WriteParameters, Cancel);
		
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
	
	//Avatax calculation
	AvaTaxServer.CalculateTaxBeforeWrite(CurrentObject, WriteParameters, Cancel, "SalesOrder");
		
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
	
	// Refill lots and serial numbers values.
	For Each Row In Object.LineItems Do
		// Update lots & serials visibility and availability.
		LotsSerialNumbers.UpdateLotsSerialNumbersVisibility(Row.Product, Items, 1, Row.UseLotsSerials);
		// Fill lot owner.
		LotsSerialNumbers.FillLotOwner(Row.Product, Row.LotOwner);
		// Load serial numbers.
		LotsSerialNumbers.FillSerialNumbers(Object.SerialNumbers, Row.Product, 1, Row.LineID, Row.SerialNumbers);
	EndDo;
	
	// Update Time Entries that reference this Sales Invoice.
	UpdateTimeEntries();
	
	//Avatax calculation
	AvaTaxServer.CalculateTaxAfterWrite(CurrentObject, WriteParameters, "SalesInvoice");
		
	//Update tax rate
	DisplaySalesTaxRate(ThisForm);
	
	If Object.Posted Then
		If Constants.zoho_auth_token.Get() <> "" Then
			If Object.NewObject = True Then
				ThisAction = "create";
			Else
				ThisAction = "update";
			EndIf;
			zoho_Functions.ZohoThisInvoice(ThisAction, Object.Ref);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	// Request user to repost subordinate documents.
	Structure = New Structure("Type, DocumentRef", "RepostSubordinateDocumentsOfSalesInvoice", Object.Ref); 
	KeyData = CommonUseClient.StartLongAction(NStr("en = 'Posting subordinate document(s)'"), Structure, ThisForm);
	If WriteParameters.Property("CloseAfterWrite") Then
		BackgroundJobParameters.Add(True);// [5]
	Else
		BackgroundJobParameters.Add(False);// [5]
	EndIf;
	CheckObtainedData(KeyData);
	
	////Close the form if the command is "Post and close"
	//If WriteParameters.Property("CloseAfterWrite") Then
	//	Close();
	//EndIf;
	
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
	
	//newALAN
	If Object.Company.ARAccount <> ChartsofAccounts.ChartOfAccounts.EmptyRef() Then
		Object.ARAccount = Object.Company.ARAccount;
	Else
		DefaultCurrency = GeneralFunctionsReusable.DefaultCurrency();
		Object.ARAccount = DefaultCurrency.DefaultARAccount;
	EndIf;
	
	Items.DecorationBillTo.Visible = True;
	Items.DecorationShipTo.Visible = True;
	Items.DecorationShipTo.Title = GeneralFunctions.ShowAddressDecoration(Object.ShipTo);
	Items.DecorationBillTo.Title = GeneralFunctions.ShowAddressDecoration(Object.BillTo);
	
EndProcedure

&AtClient
Procedure CompanyOnChangeOrdersSelection(Item)
	
	// Suggest filling of invoice by non-closed orders.
	If (Not Object.Company.IsEmpty()) And (CompanyHasNonClosedOrders) Then
		
		// Define form parameters.
		FormParameters = New Structure();
		FormParameters.Insert("Company", Object.Company);
		FormParameters.Insert("UseShipment", True);
		
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
	RecalculateTotals(Object);
	
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
	//If Object.LineSubtotal > 0 Then
		Object.DiscountPercent = Round(-1 * 100 * Object.Discount / Object.LineSubtotal, 2);
	//EndIf;
	
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
	TableSectionRow.ProductDescription  = ProductProperties.Description;
	TableSectionRow.UnitSet             = ProductProperties.UnitSet;
	TableSectionRow.Unit                = UnitSetProperties.DefaultSaleUnit;
	//TableSectionRow.UM                = UnitSetProperties.UM;
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
	TableSectionRow.Ordered   = 0;
	TableSectionRow.Backorder = 0;
	TableSectionRow.Shipped   = 0;
	TableSectionRow.Invoiced  = 0;
	
	// Calculate totals by line.
	TableSectionRow.LineTotal  		= 0;
	TableSectionRow.TaxableAmount 	= 0;
	
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
	
	UpdateInformationCurrentRow(TableSectionRow);
	
EndProcedure

&AtClient
Procedure LineItemsLocationActualOnChange(Item)
	
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
	
	FormParams = New Structure("ObjectRef", Object.Ref);
	OpenForm("InformationRegister.AvataxDetails.Form.AvataxDetails", FormParams, ThisForm,,,,, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure TaxEngineOnChange(Item)
	
	TaxEngineOnChangeAtServer();
	
EndProcedure

// <- CODE REVIEW

&AtClient
Procedure PostAndClose(Command)
	
	//PerformanceMeasurementClientServer.StartTimeMeasurement("Sales Invoice Post and Close");
	
	Try
		Write(New Structure("WriteMode, CloseAfterWrite", DocumentWriteMode.Posting, True));
	Except
		MessageText = BriefErrorDescription(ErrorInfo());
		ShowMessageBox(, MessageText);
	EndTry;
	
EndProcedure

&AtClient
Procedure Save(Command)
	
	//PerformanceMeasurementClientServer.StartTimeMeasurement("Sales Invoice Save");
	
	Try
		Write();
	Except
		MessageText = BriefErrorDescription(ErrorInfo());
		ShowMessageBox(, MessageText);
	EndTry;
	
EndProcedure

&AtClient
Procedure Post(Command)
	
	//PerformanceMeasurementClientServer.StartTimeMeasurement("Sales Invoice Post");
	
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
Procedure Payments(Command)
	
	FormParameters = New Structure();
	
	FltrParameters = New Structure();
	FltrParameters.Insert("InvoisPays", Object.Ref);
	FormParameters.Insert("Filter", FltrParameters);
	OpenForm("CommonForm.InvoicePayList",FormParameters, Object.Ref);
	
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
		|				AND Order.UseShipment = FALSE) AS OrdersRegisteredBalance
		|WHERE
		|	OrdersRegisteredBalance.QuantityBalance - OrdersRegisteredBalance.ShippedBalance > 0
		|
		|UNION
		|
		|SELECT TOP 1
		|	NULL,
		|	Shipment.Ref,
		|	NULL,
		|	NULL,
		|	NULL,
		|	NULL,
		|	NULL,
		|	NULL
		|FROM
		|	Document.Shipment AS Shipment
		|		LEFT JOIN InformationRegister.OrdersStatuses.SliceLast AS OrdersStatuses
		|		ON Shipment.Ref = OrdersStatuses.Order
		|WHERE
		|	Shipment.Company = &Company
		|	AND CASE
		|			WHEN Shipment.DeletionMark
		|				THEN VALUE(Enum.OrderStatuses.Deleted)
		|			WHEN NOT Shipment.Posted
		|				THEN VALUE(Enum.OrderStatuses.Draft)
		|			WHEN OrdersStatuses.Status IS NULL 
		|				THEN VALUE(Enum.OrderStatuses.Open)
		|			WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.EmptyRef)
		|				THEN VALUE(Enum.OrderStatuses.Open)
		|			ELSE OrdersStatuses.Status
		|		END IN (VALUE(Enum.OrderStatuses.Open), VALUE(Enum.OrderStatuses.Backordered))";
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
		
		// Update serial numbers visibility basing on filled items.
		For Each Row In Object.LineItems Do
			// Make lots & serial numbers columns visible.
			LotsSerialNumbers.UpdateLotsSerialNumbersVisibility(Row.Product, Items, 1, Row.UseLotsSerials);
			// Fill lot owner.
			LotsSerialNumbers.FillLotOwner(Row.Product, Row.LotOwner);
			// Load serial numbers.
			LotsSerialNumbers.FillSerialNumbers(Object.SerialNumbers, Row.Product, 1, Row.LineID, Row.SerialNumbers);
		EndDo;
		
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
			Object.SerialNumbers.Clear();
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
		Object.DiscountPercent = Round(-1 * 100 * Object.Discount / Object.LineSubtotal, 2);
	EndIf;
	If Object.Discount < -Object.LineSubtotal Then
		Object.Discount = -Object.LineSubtotal;
	EndIf;
		
	//Calculate sales tax
	If Not Object.UseAvatax Then //Recalculate sales tax only if using AccountingSuite sales tax engine
		//If Object.DiscountIsTaxable Then
		Object.TaxableSubtotal = TaxableSubtotal;
		//Else
			//Object.TaxableSubtotal = TaxableSubtotal + Round(-1 * TaxableSubtotal * Object.DiscountPercent/100, 2);
		//	Object.TaxableSubtotal = TaxableSubtotal + Object.Discount;
		//EndIf;
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
	//Object.DocumentTotalRC  = Round(Object.DocumentTotal * Object.ExchangeRate, 2);
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
	Return New Structure("LineNumber, LineID, Product, ProductDescription, UseLotsSerials, LotOwner, Lot, SerialNumbers, UnitSet, QtyUnits, Unit, QtyUM, UM, Ordered, Backorder, Shipped, Invoiced, PriceUnits, LineTotal, Taxable, TaxableAmount, Order, Shipment, Location, LocationActual, DeliveryDate, DeliveryDateActual, Project, Class, AvataxTaxCode, DiscountIsTaxable");
	
EndFunction

// When generated from time tracking, fills invoice with selected entries.
&AtServer
Procedure FillFromTimeTrack(timedocs,InvoiceDate)
		
	Object.Company = timedocs[0].Company;
	Object.Project = timedocs[0].Project;
	Object.Terms = Object.Company.Terms;
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
			NewLine.UnitSet = Entry.Task.UnitSet;
			NewLine.Unit = Entry.Task.UnitSet.DefaultSaleUnit;
			Price = Round(Entry.Price, GeneralFunctionsReusable.PricePrecisionForOneItem(Entry.Task)); 
			NewLine.PriceUnits = Price;
			NewLine.QtyUnits = Entry.TimeComplete;
			NewLine.LineTotal = Round(Price * Entry.TimeComplete, 2); 
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
Procedure UpdateInformationCurrentRow(CurrentRow)
	
	InformationCurrentRow = "";
	
	If CurrentRow.Product <> Undefined And CurrentRow.Product <> PredefinedValue("Catalog.Products.EmptyRef") Then
		
		LineItems = Object.LineItems.Unload(, "LineNumber, Product, QtyUM, LineTotal");
		
		LineItem = LineItems.Find(CurrentRow.LineNumber, "LineNumber");
		LineItem.Product   = CurrentRow.Product;
		LineItem.QtyUM     = CurrentRow.QtyUM;
		LineItem.LineTotal = CurrentRow.LineTotal;
		
		InformationCurrentRow = GeneralFunctions.GetMarginInformation(CurrentRow.Product, CurrentRow.LocationActual, CurrentRow.QtyUM, CurrentRow.LineTotal,
																	  Object.Currency, Object.ExchangeRate, Object.DiscountPercent, LineItems); 
		InformationCurrentRow = "" + InformationCurrentRow;
		
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
	//If AddressRef.AddressLine3 <> "" Then
	//	addressline3 = addressline3;
	//EndIf;
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

&AtClient
Procedure DwollaRequest(Command)
	
	DAT = DwollaAccessToken();
	
	If DAT = "Error" Then
		Message(NStr("en = 'Expired access token. Please Reconnect to Dwolla in Settings > Integrations.'"));
		Return;
	EndIf;
	
	If IsBlankString(DAT) Then
		Message(NStr("en = 'Please connect to Dwolla in Settings > Integrations.'"));
		Return;
	EndIf;
	
	// Check document saved.
	If Object.Ref.IsEmpty() Or Modified Then
		Message(NStr("en = 'The document is not saved. Please save the document first.'"));
		Return;
	EndIf;
	
	// Check DwollaID
	DwollaID = CommonUse.GetAttributeValue(Object.Company, "DwollaID");
	If IsBlankString(DwollaID) Then
		Message(NStr("en = 'Enter a Dwolla e-mail or ID on the customer card.'"));
		Return;
	Else
		AtSign = Find(DwollaID,"@");
		If AtSign = 0 Then
			IsEmail = False;
		Else
			IsEmail = True;
		EndIf;
	EndIf;
	
	If IsEmail Then
							
		DwollaData = New Map();
		DwollaData.Insert("sourceId", DwollaID);
		DwollaData.Insert("oauth_token", DAT);
		DwollaData.Insert("amount", Format(Object.DocumentTotalRC,"NG=0"));
		DwollaData.Insert("sourceType", "Email");
		DwollaData.Insert("notes", "Invoice " + Object.Number + " from " + Format(Object.Date,"DLF=D"));
		
		DataJSON = InternetConnectionClientServer.EncodeJSON(DwollaData);
			
	Else
		
		DwollaData = New Map();
		DwollaData.Insert("sourceId", DwollaID);
		DwollaData.Insert("oauth_token", DAT);
		DwollaData.Insert("amount", Format(Object.DocumentTotalRC,"NG=0"));
		DwollaData.Insert("notes", "Invoice " + Object.Number + " from " + Format(Object.Date,"DLF=D"));
				
		DataJSON = InternetConnectionClientServer.EncodeJSON(DwollaData);
	
	EndIf;

			
	//ResultBodyJSON = DwollaCharge(DataJSON);
	ResultBodyJSON = DwollaRequestServer(DataJSON);
	
	If ResultBodyJSON.Success AND ResultBodyJSON.Message = "Success" Then
		Object.DwollaTrxID = ResultBodyJSON.Response; //Format(ResultBodyJSON.Response, "NG=0");
		Message(NStr("en = 'Request was successfully sent. Please save the document.'"));
		Modified = True;
		
		UpdateMongo(Object.DwollaTrxID);
		
	Else
		Message(ResultBodyJSON.Message);
	EndIf;
	
	Items.DwollaRequest.Enabled = Object.DwollaTrxID = 0;

EndProcedure

&AtServer
Procedure UpdateMongo(DwollaTrxID)
	
		HeadersMap = New Map();
		HeadersMap.Insert("Content-Type", "application/json");
		
		HTTPRequest = New HTTPRequest("/api/1/clusters/rs-ds039921/databases/dataset1cproduction/collections/dwollarequests?apiKey=" + ServiceParameters.MongoAPIKey(), HeadersMap);
		
		RequestBodyMap = New Map();
				
		RequestBodyMap.Insert("DwollaRequest", DwollaTrxID);
		RequestBodyMap.Insert("tenant", SessionParameters.TenantValue);
		RequestBodyMap.Insert("UUID", Object.Ref.UUID());
		RequestBodyMap.Insert("apisecretkey", Constants.APISecretKey.Get());
		
		RequestBodyString = InternetConnectionClientServer.EncodeJSON(RequestBodyMap);
		
		HTTPRequest.SetBodyFromString(RequestBodyString,TextEncoding.ANSI); // ,TextEncoding.ANSI
		
		SSLConnection = New OpenSSLSecureConnection();
		
		HTTPConnection = New HTTPConnection("api.mongolab.com",,,,,,SSLConnection);
		Result = HTTPConnection.Post(HTTPRequest);
		ResponseBody = Result.GetBodyAsString(TextEncoding.UTF8);

	
EndProcedure

&AtServer
Function DwollaRequestServer(DataJSON)
	
	HeadersMap = New Map();
	HeadersMap.Insert("Content-Type", "application/json");		
	ConnectionSettings = New Structure;
	Connection = InternetConnectionClientServer.CreateConnection( "https://www.dwolla.com/oauth/rest/requests/", ConnectionSettings).Result;
	ResultBody = InternetConnectionClientServer.SendRequest(Connection, "Post", ConnectionSettings, HeadersMap, DataJSON).Result;
	
	ResultBodyJSON = InternetConnectionClientServer.DecodeJSON(ResultBody);
	
	Return ResultBodyJSON;
	
EndFunction

&AtServer
Function DwollaAccessToken()
	
	Return GeneralFunctions.GetDwollaAccessToken();
	
EndFunction

#Region LONG_ACTION

// Attachable procedure, called as idle handler.
&AtClient
Procedure IdleHandlerLongAction() 
	
	// Process background job result.
	KeyData = CommonUseClient.ResultProcessingLongAction(ThisForm);
	CheckObtainedData(KeyData);
	
EndProcedure

&AtClient
Procedure CheckObtainedData(KeyData)
	
	// Check whether job finished.
	If (TypeOf(KeyData) = Type("UUID")) Or (KeyData = Undefined) Then
		// Job is now pending.
	ElsIf TypeOf(KeyData) = Type("Array") Then 
		// Show results.
		
		MessageText = "";
		
		For Each Row In KeyData Do
			MessageText = MessageText + Row + Chars.LF;	
		EndDo;
		
		If ValueIsFilled(MessageText) Then
			ShowMessageBox(, MessageText);
		EndIf;
		
		//
		If BackgroundJobParameters[5].Value Then
			Close();
		EndIf;
		
	ElsIf TypeOf(KeyData) = Type("String") Then
		// Error message.
		
		//
		If BackgroundJobParameters[5].Value Then
			Close();
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion
