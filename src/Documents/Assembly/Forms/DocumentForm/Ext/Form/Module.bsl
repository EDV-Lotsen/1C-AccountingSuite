

////////////////////////////////////////////////////////////////////////////////
// Assembly: Document form
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
	IsNewRow = False;
	
	// Fill object attributes cache.
	Location = Object.Location;
	Project  = Object.Project;
	Class    = Object.Class;
	
	//------------------------------------------------------------------------------
	// 2. Calculate values of form object attributes.
	
	// Request and fill invoice status.
	FillAssemblyStatusAtServer();
	
	//------------------------------------------------------------------------------
	// 3. Set custom controls presentation.
	
	// Update quantities presentation.
	QuantityPrecision = GeneralFunctionsReusable.DefaultQuantityPrecision();
	QuantityFormat    = GeneralFunctionsReusable.DefaultQuantityFormat();
	Items.LineItemsQuantity.EditFormat      = QuantityFormat;
	Items.LineItemsQuantity.Format          = QuantityFormat;
	Items.LineItemsWasteQuantity.EditFormat = QuantityFormat;
	Items.LineItemsWasteQuantity.Format     = QuantityFormat;
	Items.ResidualsQuantity.EditFormat      = QuantityFormat;
	Items.ResidualsQuantity.Format          = QuantityFormat;
	Items.Quantity.EditFormat               = QuantityFormat;
	Items.Quantity.Format                   = QuantityFormat;
	
	// Update prices presentation.
	PriceFormat = GeneralFunctionsReusable.DefaultPriceFormat();
	Items.LineItemsPrice.EditFormat         = PriceFormat;
	Items.LineItemsPrice.Format             = PriceFormat;
	Items.LineItemsWastePrice.EditFormat    = PriceFormat;
	Items.LineItemsWastePrice.Format        = PriceFormat;
	Items.ResidualsPrice.EditFormat         = PriceFormat;
	Items.ResidualsPrice.Format             = PriceFormat;
	
	// Set currency titles.
	DefaultCurrencySymbol            = GeneralFunctionsReusable.DefaultCurrencySymbol();
	Items.LineSubtotalCurrency.Title = DefaultCurrencySymbol;
	Items.WasteCurrency.Title        = DefaultCurrencySymbol;
	Items.ResidualsCurrency.Title    = DefaultCurrencySymbol;
	Items.FCYCurrency.Title          = DefaultCurrencySymbol;
	
	// Calculate total waste.
	DisplayWastePercent(Object, ThisForm);
	
EndProcedure



//// -> CODE REVIEW
//&AtClient
//Procedure OnOpen(Cancel)
//	
//	OnOpenAtServer();
//	
//	AttachIdleHandler("AfterOpen", 0.1, True);
//	
//EndProcedure

//&AtClient
//Procedure AfterOpen()
//	
//	ThisForm.Activate();
//	
//	If ThisForm.IsInputAvailable() Then
//		///////////////////////////////////////////////
//		DetachIdleHandler("AfterOpen");
//		
//		If OpenOrdersSelectionForm Then
//			CompanyOnChange(Items.Company);	
//		EndIf;	
//		///////////////////////////////////////////////
//	Else 
//		AttachIdleHandler("AfterOpen", 0.1, True);
//	EndIf;		
//	
//EndProcedure

//&AtServer
//Procedure OnOpenAtServer()
//	If Object.PaidInvoice = True Then
//		//CommandBar.ChildItems.FormPayInvoice.Enabled = False;
//	Endif;
//	
//	Try
//		Query = New Query;
//		Query.Text = "SELECT
//					 |	GeneralJournalBalance.AmountBalance AS Bal,
//					 |	GeneralJournalBalance.Account.Ref
//					 |FROM
//					 |	AccountingRegister.GeneralJournal.Balance AS GeneralJournalBalance
//					 |WHERE
//					 |	GeneralJournalBalance.ExtDimension2 = &SalesInvoice";
//		Query.SetParameter("SalesInvoice", Object.Ref);
//		
//		QueryResult = Query.Execute().Unload();
//		
//		If QueryResult.Count() = 0 Then
//			
//			CommandBar.ChildItems.FormPayInvoice.Enabled = False;
//			
//		EndIf;
//	Except
//	EndTry;
//	
//	//prepay beg
//	If Object.PrePaySO <> "" Then
//		Message("You have unapplied payments to " + Object.PrePaySO + ". Please apply them using the Cash Receipt document.");
//		Object.PrePaySO = "";
//	EndIf;
//	//prepay end
//	
//EndProcedure

//&AtClient
//Procedure OnClose()
//	
//	OnCloseAtServer();
//	
//EndProcedure

//&AtServer
//Procedure OnCloseAtServer()
//		
//	If InvoicePaid Then
//		DocObject = object.ref.GetObject();
//		DocObject.Paid = True;
//		DocObject.Write();
//	Endif;
//	
//EndProcedure

//&AtClient
//Procedure BeforeWrite(Cancel, WriteParameters)
//	
//	//Closing period
//	If PeriodClosingServerCall.DocumentPeriodIsClosed(Object.Ref, Object.Date) Then
//		Cancel = Not PeriodClosingServerCall.DocumentWritePermitted(WriteParameters);
//		If Cancel Then
//			If WriteParameters.Property("PeriodClosingPassword") And WriteParameters.Property("Password") Then
//				If WriteParameters.Password = TRUE Then //Writing the document requires a password
//					ShowMessageBox(, "Invalid password!",, "Closed period notification");
//				EndIf;
//			Else
//				Notify = New NotifyDescription("ProcessUserResponseOnDocumentPeriodClosed", ThisObject, WriteParameters);
//				Password = "";
//				OpenForm("CommonForm.ClosedPeriodNotification", New Structure, ThisForm,,,, Notify, FormWindowOpeningMode.LockOwnerWindow);
//			EndIf;
//			return;
//		EndIf;
//	EndIf;
//	
//	//Avatax calculation
//	If Object.UseAvatax Then
//		If (WriteParameters.WriteMode = DocumentWriteMode.Write Or WriteParameters.WriteMode = DocumentWriteMode.Posting) Then
//			If Not WriteParameters.Property("CalculateTaxAtAvalara") Then
//				Cancel = True;
//				Notify = New NotifyDescription("ProcessUserResponseOnAvataxCalculation", ThisObject, WriteParameters);
//				ShowQueryBox(Notify, "The document tax will be calculated at Avalara. Extra charge may apply. Do you want to continue?", QuestionDialogMode.YesNoCancel,, DialogReturnCode.Yes, "Avatax");		
//			EndIf;
//		EndIf;
//	EndIf;
//	
//EndProcedure

//&AtClient
//Procedure ProcessUserResponseOnDocumentPeriodClosed(Result, Parameters) Export
//	
//	If (TypeOf(Result) = Type("String")) Then //Inserted password
//		Parameters.Insert("PeriodClosingPassword", Result);
//		Parameters.Insert("Password", TRUE);
//		Write(Parameters);
//		
//	ElsIf (TypeOf(Result) = Type("DialogReturnCode")) Then //Yes, No or Cancel
//		If Result = DialogReturnCode.Yes Then
//			Parameters.Insert("PeriodClosingPassword", "Yes");
//			Parameters.Insert("Password", FALSE);
//			Write(Parameters);
//		EndIf;
//	EndIf;
//	
//EndProcedure

//&AtClient
//Procedure ProcessUserResponseOnAvataxCalculation(Result, Parameters) Export
//	
//	If Result = DialogReturnCode.Yes Then
//		Parameters.Insert("CalculateTaxAtAvalara", True);
//		Write(Parameters);
//	EndIf;
//		
//EndProcedure

//// <- CODE REVIEW

//&AtServer
//Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
//	
//	// -> CODE REVIEW
//	// Check empty bill.
//	If Object.LineItems.Count() = 0 Then
//		Message("Cannot post/save with no line items.");
//		Cancel = True;
//	EndIf;
//	
//	//Period closing
//	If PeriodClosingServerCall.DocumentPeriodIsClosed(CurrentObject.Ref, CurrentObject.Date) Then
//		PermitWrite = PeriodClosingServerCall.DocumentWritePermitted(WriteParameters);
//		CurrentObject.AdditionalProperties.Insert("PermitWrite", PermitWrite);
//	EndIf;
//	
//	// <- CODE REVIEW
//	
//	
//	//------------------------------------------------------------------------------
//	// 1. Correct the invoice date according to the orders dates.
//	
//	// Request orders dates.
//	QueryText = "
//		|SELECT TOP 1
//		|	SalesOrder.Date AS Date,
//		|	SalesOrder.Ref  AS Ref
//		|FROM
//		|	Document.SalesOrder AS SalesOrder
//		|WHERE
//		|	SalesOrder.Ref IN (&Orders)
//		|ORDER BY
//		|	SalesOrder.Date Desc";
//	Query = New Query(QueryText);
//	Query.SetParameter("Orders", CurrentObject.LineItems.UnloadColumn("Order"));
//	QueryResult = Query.Execute();
//	
//	// Compare letest order date with current invoice date.
//	If Not QueryResult.IsEmpty() Then
//		
//		// Check latest order date.
//		LatestOrder  = QueryResult.Unload()[0];
//		If (Not LatestOrder.Date = Null) And (LatestOrder.Date >= CurrentObject.Date) Then
//			
//			// Invoice writing before the order.
//			If BegOfDay(LatestOrder.Date) = BegOfDay(CurrentObject.Date) Then
//				// The date is the same - simply correct the document time (it will not be shown to the user).
//				CurrentObject.Date = LatestOrder.Date + 1;
//				
//			Else
//				// The invoice writing too early.
//				CurrentObjectPresentation = StringFunctionsClientServer.SubstituteParametersInString(
//						NStr("en = '%1 %2 from %3'"), CurrentObject.Metadata().Synonym, CurrentObject.Number, Format(CurrentObject.Date, "DLF=D"));
//				Message(StringFunctionsClientServer.SubstituteParametersInString(
//						NStr("en = 'The %1 can not be written before the %2'"), CurrentObjectPresentation, LatestOrder.Ref));
//				Cancel = True;
//			EndIf;
//			
//		EndIf;
//	EndIf;
//	
//	//Avatax calculation
//	If WriteParameters.Property("CalculateTaxAtAvalara") And (Cancel = False) Then
//		AvaTaxServer.CalculateTaxAtAvalara(CurrentObject, False, Cancel);
//		//CurrentObject.AdditionalProperties.Insert("CalculateTaxAtAvalara", WriteParameters.CalculateTaxAtAvalara);
//	EndIf;
//	
//EndProcedure

//&AtServer
//Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
//	
//	If FirstNumber <> "" Then
//		
//		Numerator = Catalogs.DocumentNumbering.SalesInvoice.GetObject();
//		NextNumber = GeneralFunctions.Increment(Numerator.Number);
//		If FirstNumber = NextNumber And NextNumber = Object.Number Then
//			Numerator.Number = FirstNumber;
//			Numerator.Write();
//		EndIf;
//		
//		FirstNumber = "";
//	EndIf;
//	
//	//------------------------------------------------------------------------------
//	// Recalculate values of form object attributes.
//	
//	// Request and fill invoice status from database.
//	FillInvoiceStatusAtServer();
//	
//	// Request and fill ordered items from database.
//	FillBackorderQuantityAtServer();
//	
//	// Update Time Entries that reference this Sales Invoice.
//	UpdateTimeEntries();
//	
//	//Update tax rate
//	DisplaySalesTaxRate(Object, ThisForm);
//	
//EndProcedure

//&AtClient
//Procedure AfterWrite(WriteParameters)
//	//Close the form if the command is "Post and close"
//	If WriteParameters.Property("CloseAfterWrite") Then
//		Close();
//	EndIf;
//EndProcedure

//&AtClient
//Procedure NotificationProcessing(EventName, Parameter, Source)
//	
//	If EventName = "SalesTaxRateAdded" Then
//		If Items.SalesTaxRate.ChoiceList.FindByValue(Parameter) = Undefined Then
//			Items.SalesTaxRate.ChoiceList.Add(Parameter);
//		EndIf;
//	EndIf;
//	
//	If EventName = "UpdatePayInvoiceInformation" And Parameter = Object.Company Then
//		
//		UpdateInformationPayments();
//		
//	EndIf;
//	
//EndProcedure

//#EndRegion

//////////////////////////////////////////////////////////////////////////////////
//#Region CONTROLS_EVENTS_HANDLERS

//&AtClient
//Procedure DateOnChange(Item)
//	
//	// Ask user about updating the setting and update the line items accordingly.
//	CommonDefaultSettingOnChange(Item, "price");
//	
//EndProcedure

//&AtServer
//Procedure DateOnChangeAtServer()
//	
//	// Request exchange rate on the new date.
//	Object.ExchangeRate = GeneralFunctions.GetExchangeRate(Object.Date, Object.Currency);
//	
//	// Process settings changes.
//	ExchangeRateOnChangeAtServer();
//	
//	// Update due date basing on the currently selected terms.
//	If Not Object.Terms.IsEmpty() Then
//		Object.DueDate = Object.Date + Object.Terms.Days * 60*60*24;
//		// Does not require standard processing.
//	EndIf;
//	
//EndProcedure

//&AtClient
//Procedure CompanyOnChange(Item)
//	
//	// Request server operation.
//	CompanyOnChangeAtServer();
//	
//	//Perform client operations
//	CompanyOnChangeAtClient();
//	
//	// Select non-closed orders by the company.
//	CompanyOnChangeOrdersSelection(Item);
//	
//EndProcedure

//&AtServer
//Procedure CompanyOnChangeAtServer()
//	
//	// Reset company adresses (if company was changed).
//	FillCompanyAddressesAtServer(Object.Company, Object.ShipTo, Object.BillTo, Object.ConfirmTo);
//	ConfirmToEmail = CommonUse.GetAttributeValue(Object.ConfirmTo, "Email");
//	ShipToEmail    = CommonUse.GetAttributeValue(Object.ShipTo, "Email");
//	Object.EmailTo = ?(ValueIsFilled(Object.ConfirmTo), ConfirmToEmail, ShipToEmail);
//	
//	// Request company default settings.
//	Object.Currency        = Object.Company.DefaultCurrency;
//	Object.Terms           = Object.Company.Terms;
//	Object.SalesPerson     = Object.Company.SalesPerson;
//	
//	// Check company orders for further orders selection.
//	FillCompanyHasNonClosedOrders();
//	
//	// Process settings changes.
//	CurrencyOnChangeAtServer();
//	TermsOnChangeAtServer();
//	
//	// Tax settings
//	SalesTaxRate 		= SalesTax.GetDefaultSalesTaxRate(Object.Company);
//	Object.UseAvatax	= Object.Company.UseAvatax;
//	If Not Object.UseAvatax Then
//		TaxEngine = 1; //Use AccountingSuite
//		If SalesTaxRate <> Object.SalesTaxRate Then
//			Object.SalesTaxRate = SalesTaxRate;
//		EndIf;
//	Else
//		TaxEngine = 2;
//	EndIf;
//	Object.SalesTaxAcrossAgencies.Clear();
//	ApplySalesTaxEngineSettings();
//	If Object.UseAvatax Then
//		AvataxServer.RestoreCalculatedSalesTax(Object);
//	EndIf;	
//	DisplaySalesTaxRate(Object, ThisForm);
//	RecalculateTotalsAtServer();
//	
//	//newALAN
//	If Object.Company.ARAccount <> ChartsofAccounts.ChartOfAccounts.EmptyRef() Then
//		Object.ARAccount = Object.Company.ARAccount;
//	Else
//		DefaultCurrency = GeneralFunctionsReusable.DefaultCurrency();
//		Object.ARAccount = DefaultCurrency.DefaultARAccount;
//	EndIf;
//	
//EndProcedure

//&AtClient
//Procedure CompanyOnChangeAtClient()
//	
//	//// Reset company adresses (if company was changed).
//	//FillCompanyAddressesAtServer(Object.Company, Object.ShipTo, Object.BillTo, Object.ConfirmTo);
//	//ConfirmToEmail 	= CommonUse.GetAttributeValue(Object.ConfirmTo, "Email");
//	//ShipToEmail		= CommonUse.GetAttributeValue(Object.ShipTo, "Email");
//	//Object.EmailTo = ?(ValueIsFilled(Object.ConfirmTo), ConfirmToEmail, ShipToEmail);
//	
//	// Recalculate sales prices for the company.
//	//FillRetailPricesAtClient();
//	
//	//// Request company default settings.
//	//CompanyDefaultSettings = CommonUse.GetAttributeValues(Object.Company, "DefaultCurrency, Terms, SalesPerson");
//	//Object.Currency        = CompanyDefaultSettings.DefaultCurrency;
//	//Object.Terms           = CompanyDefaultSettings.Terms;
//	//Object.SalesPerson     = CompanyDefaultSettings.SalesPerson;
//	
//	//SalesTaxRate = SalesTax.GetDefaultSalesTaxRate(Object.Company);
//	//SetSalesTaxRate(SalesTaxRate);
//	//If SalesTaxRate <> Object.SalesTaxRate Then
//	//	Object.SalesTaxRate = SalesTaxRate;
//	//	Object.SalesTaxAcrossAgencies.Clear();
//	//	DisplaySalesTaxRate(Object, ThisForm);
//	//EndIf;
//	//RecalculateTotals();
//	
//	//// Check company orders for further orders selection.
//	//FillCompanyHasNonClosedOrders();
//	//
//	//// Process settings changes.
//	//CurrencyOnChangeAtServer();
//	//TermsOnChangeAtServer();
//	
//EndProcedure

//&AtClient
//Procedure CompanyOnChangeOrdersSelection(Item)
//	
//	// Suggest filling of invoice by non-closed orders.
//	If (Not Object.Company.IsEmpty()) And (CompanyHasNonClosedOrders) Then
//		
//		// Define form parameters.
//		FormParameters = New Structure();
//		FormParameters.Insert("ChoiceMode",     True);
//		FormParameters.Insert("MultipleChoice", True);
//		
//		// Define order statuses array.
//		OrderStatuses  = New Array;
//		OrderStatuses.Add(PredefinedValue("Enum.OrderStatuses.Open"));
//		OrderStatuses.Add(PredefinedValue("Enum.OrderStatuses.Backordered"));
//		
//		// Define list filter.
//		FltrParameters = New Structure();
//		FltrParameters.Insert("Company",     Object.Company); 
//		FltrParameters.Insert("OrderStatus", OrderStatuses);
//		FormParameters.Insert("Filter",      FltrParameters);
//		
//		// Open orders selection form.
//		NotifyDescription = New NotifyDescription("CompanyOnChangeOrdersSelectionChoiceProcessing", ThisForm);
//		OpenForm("Document.SalesOrder.ChoiceForm", FormParameters, Item,,,, NotifyDescription);
//	EndIf;
//	
//EndProcedure

//&AtClient
//Procedure CompanyOnChangeOrdersSelectionChoiceProcessing(Result, Parameters) Export
//	
//	// Process selection result.
//	If Not Result = Undefined Then
//		
//		// Do fill document from selected orders.
//		FillDocumentWithSelectedOrders(Result);
//		
//		// Sales tax update.
//		SalesTaxRate = Object.SalesTaxRate;
//		SetSalesTaxRate(SalesTaxRate);
//		
//	EndIf;
//	
//EndProcedure

//&AtClient
//Procedure DropshipCompanyOnChange(Item)
//	
//	// Request server operation.
//	DropshipCompanyOnChangeAtServer();
//	
//EndProcedure

//&AtServer
//Procedure DropshipCompanyOnChangeAtServer()
//	
//	// Reset company adresses (if company was changed).
//	FillCompanyAddressesAtServer(Object.DropshipCompany, Object.DropshipShipTo,, Object.DropshipConfirmTo);
//	
//EndProcedure

//&AtClient
//Procedure ShipToOnChange(Item)
//	
//	// Request server operation.
//	ShipToOnChangeAtServer();
//	
//EndProcedure

//&AtServer
//Procedure ShipToOnChangeAtServer()
//	
//	RecalculateTotalsAtServer();
//	
//EndProcedure

//&AtClient
//Procedure CurrencyOnChange(Item)
//	
//	// Request server operation.
//	CurrencyOnChangeAtServer();
//	
//EndProcedure

//&AtServer
//Procedure CurrencyOnChangeAtServer()
//	
//	// Set currency titles.
//	DefaultCurrencySymbol            = GeneralFunctionsReusable.DefaultCurrencySymbol();
//	ForeignCurrencySymbol            = Object.Currency.Symbol;
//	Items.ExchangeRate.Title         = DefaultCurrencySymbol + "/1" + ForeignCurrencySymbol;
//	Items.LineSubtotalCurrency.Title = ForeignCurrencySymbol;
//	Items.DiscountCurrency.Title     = ForeignCurrencySymbol;
//	Items.SubTotalCurrency.Title     = ForeignCurrencySymbol;
//	Items.ShippingCurrency.Title     = ForeignCurrencySymbol;
//	Items.SalesTaxCurrency.Title     = ForeignCurrencySymbol;
//	Items.FCYCurrency.Title 		 = ForeignCurrencySymbol;
//	Items.TaxableSubtotalCurrency.Title = ForeignCurrencySymbol;
//	
//	// Request currency default settings.
//	Object.ExchangeRate            = GeneralFunctions.GetExchangeRate(Object.Date, Object.Currency);
//	Object.ARAccount               = Object.Currency.DefaultARAccount;
//	
//	// Process settings changes.
//	ExchangeRateOnChangeAtServer();
//	
//EndProcedure

//&AtClient
//Procedure ExchangeRateOnChange(Item)
//	
//	// Request server operation.
//	ExchangeRateOnChangeAtServer();
//	
//EndProcedure

//&AtServer
//Procedure ExchangeRateOnChangeAtServer()
//	
//	// Recalculate totals with new exchange rate.
//	RecalculateTotalsAtServer();
//	
//EndProcedure

//&AtClient
//Procedure DueDateOnChange(Item)
//	
//	// Request server operation.
//	DueDateOnChangeAtServer();
//	
//EndProcedure

//&AtServer
//Procedure DueDateOnChangeAtServer()
//	
//	// Back-change - clear used terms.
//	Object.Terms = Catalogs.PaymentTerms.EmptyRef();
//	// Does not require standard processing.
//	
//EndProcedure

//&AtClient
//Procedure LocationActualOnChange(Item)
//	
//	// Ask user about updating the setting and update the line items accordingly.
//	CommonDefaultSettingOnChange(Item, Lower(Item.ToolTip));
//	
//EndProcedure

//&AtClient
//Procedure DeliveryDateActualOnChange(Item)
//	
//	// Ask user about updating the setting and update the line items accordingly.
//	CommonDefaultSettingOnChange(Item, Lower(Item.ToolTip));
//	
//EndProcedure

//&AtClient
//Procedure ProjectOnChange(Item)
//	
//	// Ask user about updating the setting and update the line items accordingly.
//	CommonDefaultSettingOnChange(Item, Lower(Item.Name));
//	
//EndProcedure

//&AtClient
//Procedure ClassOnChange(Item)
//	
//	// Ask user about updating the setting and update the line items accordingly.
//	CommonDefaultSettingOnChange(Item, Lower(Item.Name));
//	
//EndProcedure

//&AtClient
//Procedure TermsOnChange(Item)
//	
//	// Request server operation.
//	TermsOnChangeAtServer();
//	
//EndProcedure

//&AtServer
//Procedure TermsOnChangeAtServer()
//	
//	// Define empty date.
//	EmptyDate = '00010101';
//	
//	// Update due date basing on the currently selected terms.
//	Object.DueDate = ?(Not Object.Terms.IsEmpty(), Object.Date + Object.Terms.Days * 60*60*24, EmptyDate);
//	// Does not require standard processing.
//	
//EndProcedure

//&AtClient
//Procedure DiscountPercentOnChange(Item)
//	
//	// Request server operation.
//	DiscountPercentOnChangeAtServer();
//	
//EndProcedure

//&AtServer
//Procedure DiscountPercentOnChangeAtServer()
//	
//	// Recalculate discount value by it's percent.
//	Object.Discount = Round(-1 * Object.LineSubtotal * Object.DiscountPercent/100, 2);
//	
//	// Recalculate totals with new discount.
//	RecalculateTotalsAtServer();
//	
//EndProcedure

//&AtClient
//Procedure DiscountOnChange(Item)
//	
//	// Request server operation.
//	DiscountOnChangeAtServer();
//	
//EndProcedure

//&AtServer
//Procedure DiscountOnChangeAtServer()
//	
//	// Discount can not override the total.
//	If Object.Discount < -Object.LineSubtotal Then
//		Object.Discount = - Object.LineSubtotal;
//	EndIf;
//	
//	// Recalculate discount value by it's percent.
//	If Object.LineSubtotal > 0 Then
//		Object.DiscountPercent = Round(-1 * 100 * Object.Discount / Object.LineSubtotal, 2);
//	EndIf;
//	
//	// Recalculate totals with new discount.
//	RecalculateTotalsAtServer();
//	
//EndProcedure

//&AtClient
//Procedure ShippingOnChange(Item)
//	
//	// Request server operation.
//	ShippingOnChangeAtServer();
//	
//EndProcedure

//&AtServer
//Procedure ShippingOnChangeAtServer()
//	
//	// Recalculate totals with new shipping amount.
//	RecalculateTotalsAtServer();
//	
//EndProcedure

//&AtClient
//Procedure SalesTaxOnChange(Item)
//	
//	// Request server operation.
//	SalesTaxOnChangeAtServer();
//	
//EndProcedure

//&AtServer
//Procedure SalesTaxOnChangeAtServer()
//	
//	// Recalculate totals with new sales tax.
//	RecalculateTotalsAtServer();
//	
//EndProcedure

////------------------------------------------------------------------------------
//// Utils for request user confirmation and propagate header settings to line items.

//&AtClient
//Procedure CommonDefaultSettingOnChange(Item, ItemPresentation)
//	
//	// Request user confirmation changing the setting for all LineItems.
//	DefaultSetting = Item.Name;
//	If Object.LineItems.Count() > 0 Then
//		QuestionText  = StringFunctionsClientServer.SubstituteParametersInString(NStr("en = 'Reset the %1 for line items?'"), ItemPresentation);
//		QuestionTitle = StringFunctionsClientServer.SubstituteParametersInString(NStr("en = 'Reset %1'"), ItemPresentation);
//		ChoiceParameters = New Structure("DefaultSetting", DefaultSetting);
//		ChoiceProcessing = New NotifyDescription("DefaultSettingOnChangeChoiceProcessing", ThisForm, ChoiceParameters);
//		ShowQueryBox(ChoiceProcessing, QuestionText, QuestionDialogMode.YesNoCancel,, DialogReturnCode.Cancel, QuestionTitle);
//	Else
//		// Keep new setting.
//		ThisForm[DefaultSetting] = Object[DefaultSetting];
//		DefaultSettingOnChangeAtServer(DefaultSetting, False);
//	EndIf;
//	
//EndProcedure

//&AtClient
//Procedure DefaultSettingOnChangeChoiceProcessing(ChoiceResult, ChoiceParameters) Export
//	
//	// Get current processing item.
//	DefaultSetting = ChoiceParameters.DefaultSetting;
//	
//	// Process user choice.
//	If ChoiceResult = DialogReturnCode.Yes Then
//		// Set new setting for all line items.
//		ThisForm[DefaultSetting] = Object[DefaultSetting];
//		DefaultSettingOnChangeAtServer(DefaultSetting, True);
//		
//	ElsIf ChoiceResult = DialogReturnCode.No Then
//		// Keep new setting, do not update line items.
//		ThisForm[DefaultSetting] = Object[DefaultSetting];
//		DefaultSettingOnChangeAtServer(DefaultSetting, False);
//		
//	Else
//		// Restore previously entered setting.
//		Object[DefaultSetting] = ThisForm[DefaultSetting];
//	EndIf;
//	
//EndProcedure

//&AtServer
//Procedure DefaultSettingOnChangeAtServer(DefaultSetting, RecalculateLineItems)
//	
//	// Process attribute change.
//	If Object.Ref.Metadata().TabularSections.LineItems.Attributes.Find(DefaultSetting) <> Undefined Then
//		// Process attributes by the matching name to the header's default values.
//		
//		// Process line items change.
//		If RecalculateLineItems Then
//			// Apply default to all of the items.
//			For Each Row In Object.LineItems Do
//				Row[DefaultSetting] = Object[DefaultSetting];
//			EndDo;
//		EndIf;
//		
//	// Process attributes by the name.
//	ElsIf DefaultSetting = "Date" Then
//		
//		// Process the attribute change in any case.
//		DateOnChangeAtServer();
//		
//		// Process line items change.
//		If RecalculateLineItems Then
//			// Recalculate retail price.
//			For Each Row In Object.LineItems Do
//				Row.PriceUnits = Round(GeneralFunctions.RetailPrice(Object.Date, Row.Product, Object.Company) *
//								 ?(Row.Unit.Factor > 0, Row.Unit.Factor, 1) /
//								 ?(Row.UnitSet.DefaultSaleUnit.Factor > 0, Row.UnitSet.DefaultSaleUnit.Factor, 1) /
//								 ?(Object.ExchangeRate > 0, Object.ExchangeRate, 1), GeneralFunctionsReusable.PricePrecisionForOneItem(Row.Product));
//				LineItemsPriceOnChangeAtServer(Row);
//			EndDo;
//			RecalculateTotalsAtServer();
//		EndIf;
//		
//	ElsIf DefaultSetting = "Company" Then
//		
//		// Process the attribute change in any case.
//		CompanyOnChangeAtServer();
//		
//		// Process line items change.
//		If RecalculateLineItems Then
//			// Recalculate retail price.
//			For Each Row In Object.LineItems Do
//				Row.PriceUnits = Round(GeneralFunctions.RetailPrice(Object.Date, Row.Product, Object.Company) *
//								 ?(Row.Unit.Factor > 0, Row.Unit.Factor, 1) /
//								 ?(Row.UnitSet.DefaultSaleUnit.Factor > 0, Row.UnitSet.DefaultSaleUnit.Factor, 1) /
//								 ?(Object.ExchangeRate > 0, Object.ExchangeRate, 1), GeneralFunctionsReusable.PricePrecisionForOneItem(Row.Product));
//				LineItemsPriceOnChangeAtServer(Row);
//			EndDo;
//			RecalculateTotalsAtServer();
//		EndIf;
//		
//	Else
//		// Process other attributes.
//	EndIf;
//	
//EndProcedure

//#EndRegion

//////////////////////////////////////////////////////////////////////////////////
//#Region TABULAR_SECTION_EVENTS_HANDLERS

////------------------------------------------------------------------------------
//// Tabular section LineItems event handlers.

//&AtClient
//Procedure LineItemsOnChange(Item)
//	
//	// Row was just added and became edited.
//	If IsNewRow Then
//		
//		// Clear used flag.
//		IsNewRow = False;
//		
//		// Fill new row with default values.
//		ObjectData  = New Structure("LocationActual, DeliveryDateActual, Project, Class");
//		FillPropertyValues(ObjectData, Object);
//		For Each ObjectField In ObjectData Do
//			If Not ValueIsFilled(Item.CurrentData[ObjectField.Key]) Then
//				Item.CurrentData[ObjectField.Key] = ObjectField.Value;
//			EndIf;
//		EndDo;
//		
//		// Clear order data on duplicate row.
//		ClearFields  = New Structure("Order, Location, DeliveryDate");
//		For Each ClearField In ClearFields Do
//			If Not ValueIsFilled(Item.CurrentData[ObjectField.Key]) Then
//				Item.CurrentData[ObjectField.Key] = Undefined;
//			EndIf;
//		EndDo;
//		
//		Item.CurrentData.LineID = New UUID();
//		
//		// Refresh totals cache.
//		RecalculateTotals();
//	EndIf;
//	
//EndProcedure

//&AtClient
//Procedure LineItemsBeforeAddRow(Item, Cancel, Clone, Parent, Folder)
//	
//	// Set new row flag.
//	If Not Cancel Then
//		IsNewRow = True;
//	EndIf;
//		
//EndProcedure

//&AtClient
//Procedure LineItemsOnEditEnd(Item, NewRow, CancelEdit)
//	
//	// Recalculation common document totals.
//	RecalculateTotalsAtServer();
//	
//EndProcedure

//&AtClient
//Procedure LineItemsAfterDeleteRow(Item)
//	
//	// Recalculation common document totals.
//	RecalculateTotalsAtServer();
//	
//EndProcedure

////------------------------------------------------------------------------------
//// Tabular section LineItems columns controls event handlers.

//&AtClient
//Procedure LineItemsProductOnChange(Item)
//	
//	// Fill line data for editing.
//	TableSectionRow = GetLineItemsRowStructure();
//	FillPropertyValues(TableSectionRow, Items.LineItems.CurrentData);
//	
//	// Request server operation.
//	LineItemsProductOnChangeAtServer(TableSectionRow);
//	
//	// Load processed data back.
//	FillPropertyValues(Items.LineItems.CurrentData, TableSectionRow);
//	
//	// Refresh totals cache.
//	RecalculateTotals();
//	
//EndProcedure

//&AtServer
//Procedure LineItemsProductOnChangeAtServer(TableSectionRow)
//	
//	// Request product properties.
//	ProductProperties = CommonUse.GetAttributeValues(TableSectionRow.Product,   New Structure("Description, UnitSet, Taxable"));
//	UnitSetProperties = CommonUse.GetAttributeValues(ProductProperties.UnitSet, New Structure("DefaultSaleUnit"));
//	TableSectionRow.ProductDescription = ProductProperties.Description;
//	TableSectionRow.UnitSet            = ProductProperties.UnitSet;
//	TableSectionRow.Unit               = UnitSetProperties.DefaultSaleUnit;
//	//TableSectionRow.UM                 = UnitSetProperties.UM;
//	TableSectionRow.Taxable            = ProductProperties.Taxable;
//	TableSectionRow.PriceUnits         = Round(GeneralFunctions.RetailPrice(Object.Date, TableSectionRow.Product, Object.Company) /
//										 // The price is returned for default sales unit factor.
//										 ?(Object.ExchangeRate > 0, Object.ExchangeRate, 1), GeneralFunctionsReusable.PricePrecisionForOneItem(TableSectionRow.Product));
//										 
//	// Clear up order data.
//	TableSectionRow.Order              = Documents.SalesOrder.EmptyRef();
//	TableSectionRow.DeliveryDate       = '00010101';
//	TableSectionRow.Location           = Catalogs.Locations.EmptyRef();
//	
//	// Reset default values.
//	TableSectionRow.DeliveryDateActual = Object.DeliveryDateActual;
//	TableSectionRow.LocationActual     = Object.LocationActual;
//	TableSectionRow.Project            = Object.Project;
//	TableSectionRow.Class              = Object.Class;
//	
//	// Assign default quantities.
//	TableSectionRow.QtyUnits  = 0;
//	TableSectionRow.QtyUM     = 0;
//	TableSectionRow.Ordered   = 0;
//	TableSectionRow.Backorder = 0;
//	TableSectionRow.Shipped   = 0;
//	TableSectionRow.Invoiced  = 0;
//	
//	// Calculate totals by line.
//	TableSectionRow.LineTotal     = 0;
//	TableSectionRow.TaxableAmount = 0;
//	
//EndProcedure

//&AtClient
//Procedure LineItemsUnitOnChange(Item)
//	
//	// Fill line data for editing.
//	TableSectionRow = GetLineItemsRowStructure();
//	FillPropertyValues(TableSectionRow, Items.LineItems.CurrentData);
//	
//	// Request server operation.
//	LineItemsUnitOnChangeAtServer(TableSectionRow);
//	
//	// Load processed data back.
//	FillPropertyValues(Items.LineItems.CurrentData, TableSectionRow);
//	
//	// Refresh totals cache.
//	RecalculateTotals();
//	
//EndProcedure

//&AtServer
//Procedure LineItemsUnitOnChangeAtServer(TableSectionRow)
//	
//	// Calculate new unit price.
//	TableSectionRow.PriceUnits = Round(GeneralFunctions.RetailPrice(Object.Date, TableSectionRow.Product, Object.Company) *
//								 ?(TableSectionRow.Unit.Factor > 0, TableSectionRow.Unit.Factor, 1) /
//								 ?(TableSectionRow.UnitSet.DefaultSaleUnit.Factor > 0, TableSectionRow.UnitSet.DefaultSaleUnit.Factor, 1) /
//								 ?(Object.ExchangeRate > 0, Object.ExchangeRate, 1), GeneralFunctionsReusable.PricePrecisionForOneItem(TableSectionRow.Product));
//								 
//	// Process settings changes.
//	LineItemsQuantityOnChangeAtServer(TableSectionRow);
//	
//EndProcedure

//&AtClient
//Procedure LineItemsQuantityOnChange(Item)
//	
//	// Fill line data for editing.
//	TableSectionRow = GetLineItemsRowStructure();
//	FillPropertyValues(TableSectionRow, Items.LineItems.CurrentData);
//	
//	// Request server operation.
//	LineItemsQuantityOnChangeAtServer(TableSectionRow);
//	
//	// Load processed data back.
//	FillPropertyValues(Items.LineItems.CurrentData, TableSectionRow);
//	
//	// Refresh totals cache.
//	RecalculateTotals();
//	
//EndProcedure

//&AtServer
//Procedure LineItemsQuantityOnChangeAtServer(TableSectionRow)
//	
//	//// Update backorder quantity basing on document status.
//	//If OrderStatus = Enums.OrderStatuses.Open Then
//	//	TableSectionRow.Backorder = 0;
//	//	
//	//ElsIf OrderStatus = Enums.OrderStatuses.Backordered Then
//	//	If TableSectionRow.Product.Type = Enums.InventoryTypes.Inventory Then
//	//		TableSectionRow.Backorder = Max(TableSectionRow.Quantity - TableSectionRow.Received, 0);
//	//	Else // TableSectionRow.Product.Type = Enums.InventoryTypes.NonInventory;
//	//		TableSectionRow.Backorder = Max(TableSectionRow.Quantity - TableSectionRow.Invoiced, 0);
//	//	EndIf;
//	//	
//	//ElsIf OrderStatus = Enums.OrderStatuses.Closed Then
//	//	TableSectionRow.Backorder = 0;
//	//	
//	//Else
//	//	TableSectionRow.Backorder = 0;
//	//EndIf;
//	
//	// Calculate total by line.
//	TableSectionRow.LineTotal = Round(Round(TableSectionRow.QtyUnits, QuantityPrecision) * Round(TableSectionRow.PriceUnits, GeneralFunctionsReusable.PricePrecisionForOneItem(TableSectionRow.Product)), 2);
//	
//	// Process settings changes.
//	LineItemsLineTotalOnChangeAtServer(TableSectionRow);
//	
//EndProcedure

//&AtClient
//Procedure LineItemsPriceOnChange(Item)
//	
//	// Fill line data for editing.
//	TableSectionRow = GetLineItemsRowStructure();
//	FillPropertyValues(TableSectionRow, Items.LineItems.CurrentData);
//	
//	// Request server operation.
//	LineItemsPriceOnChangeAtServer(TableSectionRow);
//	
//	// Load processed data back.
//	FillPropertyValues(Items.LineItems.CurrentData, TableSectionRow);
//	
//	// Refresh totals cache.
//	RecalculateTotals();
//	
//EndProcedure

//&AtServer
//Procedure LineItemsPriceOnChangeAtServer(TableSectionRow)
//	
//	// Rounds price of product. 
//	TableSectionRow.PriceUnits = Round(TableSectionRow.PriceUnits, GeneralFunctionsReusable.PricePrecisionForOneItem(TableSectionRow.Product));
//	
//	// Calculate total by line.
//	TableSectionRow.LineTotal = Round(Round(TableSectionRow.QtyUnits, QuantityPrecision) * TableSectionRow.PriceUnits, 2);
//	
//	// Process settings changes.
//	LineItemsLineTotalOnChangeAtServer(TableSectionRow);
//	
//EndProcedure

//&AtClient
//Procedure LineItemsLineTotalOnChange(Item)
//	
//	// Fill line data for editing.
//	TableSectionRow = GetLineItemsRowStructure();
//	FillPropertyValues(TableSectionRow, Items.LineItems.CurrentData);
//	
//	// Request server operation.
//	LineItemsLineTotalOnChangeAtServer(TableSectionRow);
//	
//	// Back-step price calculation with totals priority (interactive change only).
//	TableSectionRow.PriceUnits = ?(TableSectionRow.QtyUnits > 0,
//								 Round(TableSectionRow.LineTotal / Round(TableSectionRow.QtyUnits, QuantityPrecision), GeneralFunctionsReusable.PricePrecisionForOneItem(TableSectionRow.Product)), 0);
//								 
//	// Load processed data back.
//	FillPropertyValues(Items.LineItems.CurrentData, TableSectionRow);
//	
//	// Refresh totals cache.
//	RecalculateTotals();
//	
//EndProcedure

//&AtServer
//Procedure LineItemsLineTotalOnChangeAtServer(TableSectionRow)
//	
//	// Back-calculation of quantity in base units.
//	TableSectionRow.QtyUM = Round(Round(TableSectionRow.QtyUnits, QuantityPrecision) *
//							?(TableSectionRow.Unit.Factor > 0, TableSectionRow.Unit.Factor, 1), QuantityPrecision);
//	
//	// Calculate taxes by line total.
//	LineItemsTaxableOnChangeAtServer(TableSectionRow);
//	
//EndProcedure

//&AtClient
//Procedure LineItemsTaxableOnChange(Item)
//	
//	// Fill line data for editing.
//	TableSectionRow = GetLineItemsRowStructure();
//	FillPropertyValues(TableSectionRow, Items.LineItems.CurrentData);
//	
//	// Request server operation.
//	LineItemsTaxableOnChangeAtServer(TableSectionRow);
//	
//	// Load processed data back.
//	FillPropertyValues(Items.LineItems.CurrentData, TableSectionRow);
//	
//	// Refresh totals cache.
//	RecalculateTotals();
//	
//EndProcedure

//&AtServer
//Procedure LineItemsTaxableOnChangeAtServer(TableSectionRow)
//	
//	// Calculate sales tax by line total.
//	TableSectionRow.TaxableAmount = ?(TableSectionRow.Taxable, TableSectionRow.LineTotal, 0);
//	
//EndProcedure

//&AtClient
//Procedure LineItemsTaxableAmountOnChange(Item)
//	
//	// Refresh totals cache.
//	RecalculateTotals();
//	
//EndProcedure

//#EndRegion

//////////////////////////////////////////////////////////////////////////////////
//#Region COMMANDS_HANDLERS

//// -> CODE REVIEW
////------------------------------------------------------------------------------
//// Send invoice by email.

//&AtClient
//Procedure SendEmail(Command)
//	
//	If Object.Ref.IsEmpty() OR IsPosted() = False Then
//		Message("An email cannot be sent until the invoice is posted");
//	Else	
//		FormParameters = New Structure("Ref",Object.Ref );
//		OpenForm("CommonForm.EmailForm", FormParameters,,,,,, FormWindowOpeningMode.LockOwnerWindow);	
//	EndIf;
//	
//EndProcedure

//// Check if document has been posted, return bool value.

//&AtServer
//Function IsPosted()
//	Return Object.Ref.Posted;	
//EndFunction

////------------------------------------------------------------------------------
//// Pay invoice electronically.

//&AtClient
//Procedure PayInvoice(Command)
//	
//	SIObj = New Structure;
//	SIObj.Insert("SalesInvoice", Object.Ref);
//	OpenForm("Document.CashReceipt.ObjectForm",SIObj);
//	
//	// Currently is not used.
//	// PayInvoiceAtServer();
//	
//EndProcedure

////&AtServer
////Procedure PayInvoiceAtServer()
////	
////	If Object.Posted = False Then
////		Message("A cash receipt cannot be created for the invoice because it has not yet been created(posted)");
////	Else
////	
////		NewCashReceipt = Documents.CashReceipt.CreateDocument();
////		NewCashReceipt.Company = Object.Company;
////		NewCashReceipt.Date = CurrentDate();
////		NewCashReceipt.Currency = Object.Currency;
////		NewCashReceipt.DepositType = "1";
////		NewCashReceipt.DocumentTotalRC = Object.DocumentTotalRC;
////		NewCashReceipt.CashPayment = Object.DocumentTotalRC;
////		NewCashReceipt.ARAccount = Object.ARAccount;
////		
////		NewLine = NewCashReceipt.LineItems.Add();
////		NewLine.Document = Object.Ref;
////		NewLine.Balance = Object.DocumentTotalRC;
////		NewLine.Payment = Object.DocumentTotalRC;
////		Newline.Currency = Object.Currency;
////		
////		NewCashReceipt.Write(DocumentWriteMode.Posting);
////		CommandBar.ChildItems.FormPayInvoice.Enabled = False;
////		InvoicePaid = True;
////		
////		Message("A Cash Receipt has been created for " + Object.Ref);
////		
////	Endif;
////	
////EndProcedure

////------------------------------------------------------------------------------
//// Call AvaTax to request sales tax values.

//&AtClient
//Procedure AvaTax(Command)
//	FormParams = New Structure("ObjectRef", Object.Ref);
//	OpenForm("InformationRegister.AvataxDetails.Form.AvataxDetails", FormParams, ThisForm,,,,, FormWindowOpeningMode.LockOwnerWindow);
//EndProcedure

//// <- CODE REVIEW

//&AtClient
//Procedure PostAndClose(Command)
//	
//	PerformanceMeasurementClientServer.StartTimeMeasurement("Sales Invoice Post and Close");
//	
//	If Write(New Structure("WriteMode, CloseAfterWrite", DocumentWriteMode.Posting, True)) Then Close() EndIf;
//	
//EndProcedure

//&AtClient
//Procedure Save(Command)
//	
//	PerformanceMeasurementClientServer.StartTimeMeasurement("Sales Invoice Save");
//	
//	Write();
//	
//EndProcedure

//&AtClient
//Procedure Post(Command)
//	
//	PerformanceMeasurementClientServer.StartTimeMeasurement("Sales Invoice Post");
//	
//	Write(New Structure("WriteMode", DocumentWriteMode.Posting));
//	
//EndProcedure

//&AtClient
//Procedure ClearPosting(Command)
//	
//	Write(New Structure("WriteMode", DocumentWriteMode.UndoPosting));
//	
//EndProcedure

//&AtClient
//Procedure Payments(Command)
//	
//	FormParameters = New Structure();
//	
//	FltrParameters = New Structure();
//	FltrParameters.Insert("InvoisPays", Object.Ref);
//	FormParameters.Insert("Filter", FltrParameters);
//	OpenForm("CommonForm.InvoicePayList",FormParameters, Object.Ref);
//	
//EndProcedure

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region PRIVATE_IMPLEMENTATION

//------------------------------------------------------------------------------
// Calculate values of form object attributes.

&AtServer
// Request assembly status from database.
Procedure FillAssemblyStatusAtServer()
	
	// Request assembly status.
	If (Not ValueIsFilled(Object.Ref)) Or (Object.DeletionMark) Or (Not Object.Posted) Then
		// The assembly has pending status.
		AssemblyStatus = Enums.AssemblyStatuses.Pending;
	Else
		// The assembly has been completed.
		AssemblyStatus = Enums.AssemblyStatuses.Completed;
	EndIf;
	
	// Fill extended assembly status presentation (depending of document state).
	If Not ValueIsFilled(Object.Ref) Then
		AssemblyStatusPresentation = String(Enums.AssemblyStatuses.New);
		Items.AssemblyStatusPresentation.TextColor = WebColors.DarkGray;
		
	ElsIf Object.DeletionMark Then
		AssemblyStatusPresentation = String(Enums.AssemblyStatuses.Deleted);
		Items.AssemblyStatusPresentation.TextColor = WebColors.DarkGray;
		
	ElsIf Not Object.Posted Then 
		AssemblyStatusPresentation = String(Enums.AssemblyStatuses.Draft);
		Items.AssemblyStatusPresentation.TextColor = WebColors.DarkGray;
		
	Else
		AssemblyStatusPresentation = String(AssemblyStatus);
		If AssemblyStatus = Enums.AssemblyStatuses.Pending Then 
			ThisForm.Items.AssemblyStatusPresentation.TextColor = WebColors.DarkRed;
		ElsIf AssemblyStatus = Enums.AssemblyStatuses.Completed Then 
			ThisForm.Items.AssemblyStatusPresentation.TextColor = WebColors.DarkGreen;
		Else
			ThisForm.Items.AssemblyStatusPresentation.TextColor = WebColors.DarkGray;
		EndIf;
	EndIf;
	
EndProcedure

//------------------------------------------------------------------------------
// Calculate totals and fill object attributes.

&AtClient
// The procedure recalculates the document's totals.
Procedure RecalculateTotals()
	//
	//// Calculate document totals.
	//LineSubtotal = 0;
	//TaxableSubtotal = 0;
	//For Each Row In Object.LineItems Do
	//	LineSubtotal = LineSubtotal  + Row.LineTotal;
	//	TaxableSubtotal = TaxableSubtotal + Row.TaxableAmount;
	//EndDo;
	//
	//// Assign totals to the object fields.
	//If Object.LineSubtotal <> LineSubtotal Then
	//	Object.LineSubtotal = LineSubtotal;
	//	// Recalculate the discount and it's percent.
	//	Object.Discount     = Round(-1 * Object.LineSubtotal * Object.DiscountPercent/100, 2);
	//	If Object.Discount < -Object.LineSubtotal Then
	//		Object.Discount = -Object.LineSubtotal;
	//	EndIf;
	//	If Object.LineSubtotal > 0 Then
	//		Object.DiscountPercent = Round(-1 * 100 * Object.Discount / Object.LineSubtotal, 2);
	//	EndIf;
	//EndIf;
	//
	////Calculate sales tax
	//If Not Object.UseAvatax Then //Recalculate sales tax only if using AccountingSuite sales tax engine
	//	If Object.DiscountIsTaxable Then
	//		Object.TaxableSubtotal = TaxableSubtotal;
	//	Else
	//		Object.TaxableSubtotal = TaxableSubtotal + Round(-1 * TaxableSubtotal * Object.DiscountPercent/100, 2);
	//	EndIf;
	//	CurrentAgenciesRates = Undefined;
	//	If Object.SalesTaxAcrossAgencies.Count() > 0 Then
	//		CurrentAgenciesRates = New Array();
	//		For Each AgencyRate In Object.SalesTaxAcrossAgencies Do
	//			CurrentAgenciesRates.Add(New Structure("Agency, Rate, SalesTaxRate, SalesTaxComponent", AgencyRate.Agency, AgencyRate.Rate, AgencyRate.SalesTaxRate, AgencyRate.SalesTaxComponent));
	//		EndDo;
	//	EndIf;
	//	SalesTaxAcrossAgencies = SalesTaxClient.CalculateSalesTax(Object.TaxableSubtotal, Object.SalesTaxRate, CurrentAgenciesRates);
	//	Object.SalesTaxAcrossAgencies.Clear();
	//	For Each STAcrossAgencies In SalesTaxAcrossAgencies Do 
	//		NewRow = Object.SalesTaxAcrossAgencies.Add();
	//		FillPropertyValues(NewRow, STAcrossAgencies);
	//	EndDo;
	//EndIf;
	//Object.SalesTax = Object.SalesTaxAcrossAgencies.Total("Amount");
	//
	//// Calculate the rest of the totals.
	//Object.SubTotal         = LineSubtotal + Object.Discount;
	//Object.SalesTaxRC       = Round(Object.SalesTax * Object.ExchangeRate, 2);
	//Object.DocumentTotal    = Object.SubTotal + Object.Shipping + Object.SalesTax;
	//Object.DocumentTotalRC  = Round(Object.DocumentTotal * Object.ExchangeRate, 2);
	
EndProcedure

&AtServer
// The procedure recalculates the document's totals.
Procedure RecalculateTotalsAtServer()
	
	//// Calculate document totals.
	//LineSubtotal = Object.LineItems.Total("LineTotal");
	//TaxableSubtotal = Object.LineItems.Total("TaxableAmount");
	//
	//// Assign totals to the object fields.
	//If Object.LineSubtotal <> LineSubtotal Then
	//	Object.LineSubtotal = LineSubtotal;
	//	// Recalculate the discount and it's percent.
	//	Object.Discount     = Round(-1 * Object.LineSubtotal * Object.DiscountPercent/100, 2);
	//	If Object.Discount < -Object.LineSubtotal Then
	//		Object.Discount = -Object.LineSubtotal;
	//	EndIf;
	//	If Object.LineSubtotal > 0 Then
	//		Object.DiscountPercent = Round(-1 * 100 * Object.Discount / Object.LineSubtotal, 2);
	//	EndIf;
	//EndIf;
	//
	////Calculate sales tax
	//If Not Object.UseAvatax Then //Recalculate sales tax only if using AccountingSuite sales tax engine
	//	If Object.DiscountIsTaxable Then
	//		Object.TaxableSubtotal = TaxableSubtotal;
	//	Else
	//		Object.TaxableSubtotal = TaxableSubtotal + Round(-1 * TaxableSubtotal * Object.DiscountPercent/100, 2);
	//	EndIf;
	//	CurrentAgenciesRates = Undefined;
	//	If Object.SalesTaxAcrossAgencies.Count() > 0 Then
	//		CurrentAgenciesRates = New Array();
	//		For Each AgencyRate In Object.SalesTaxAcrossAgencies Do
	//			CurrentAgenciesRates.Add(New Structure("Agency, Rate, SalesTaxRate, SalesTaxComponent", AgencyRate.Agency, AgencyRate.Rate, AgencyRate.SalesTaxRate, AgencyRate.SalesTaxComponent));
	//		EndDo;
	//	EndIf;
	//	SalesTaxAcrossAgencies = SalesTax.CalculateSalesTax(Object.TaxableSubtotal, Object.SalesTaxRate, CurrentAgenciesRates);
	//	Object.SalesTaxAcrossAgencies.Clear();
	//	For Each STAcrossAgencies In SalesTaxAcrossAgencies Do 
	//		NewRow = Object.SalesTaxAcrossAgencies.Add();
	//		FillPropertyValues(NewRow, STAcrossAgencies);
	//	EndDo;
	//EndIf;
	//Object.SalesTax = Object.SalesTaxAcrossAgencies.Total("Amount");
	//
	//// Calculate the rest of the totals.
	//Object.SubTotal         = LineSubtotal + Object.Discount;
	//Object.SalesTaxRC       = Round(Object.SalesTax * Object.ExchangeRate, 2);
	//Object.DocumentTotal    = Object.SubTotal + Object.Shipping + Object.SalesTax;
	//Object.DocumentTotalRC  = Round(Object.DocumentTotal * Object.ExchangeRate, 2);
	
EndProcedure

//------------------------------------------------------------------------------
// Replacemant for metadata properties on client.

&AtClient
// Returns fields structure of LineItems form control.
Function GetLineItemsRowStructure()
	
	// Define control row fields.
	Return New Structure("LineNumber, Product, ProductDescription, UnitSet, QtyUnits, Unit, QtyUM, UM, Ordered, Backorder, Shipped, Invoiced, PriceUnits, LineTotal, Taxable, TaxableAmount, Order, Location, LocationActual, DeliveryDate, DeliveryDateActual, Project, Class");
	
EndFunction

&AtClientAtServerNoContext
Procedure DisplayWastePercent(Object, Form)
	
	//TaxRate = 0;
	//If Not Object.UseAvatax Then
	//	If Object.SalesTaxAcrossAgencies.Count() = 0 Then
	//		SalesTaxRateAttr = CommonUse.GetAttributeValues(Object.SalesTaxRate, "Rate");
	//		TaxRate = SalesTaxRateAttr.Rate;
	//	Else
	//		TaxRate = Object.SalesTaxAcrossAgencies.Total("Rate");
	//	EndIf;
	//Else //When using Avatax some lines are taxable and others not
	//	If Object.TaxableSubtotal <> 0 Then
	//		TaxRate = Round(Object.SalesTax/Object.TaxableSubtotal, 4) * 100;
	//	EndIf;
	//EndIf;
	//SalesTaxRateText = "Tax rate: " + String(TaxRate) + "%";
	//Form.Items.SalesTaxPercentDecoration.Title = SalesTaxRateText;
	
EndProcedure

#EndRegion








//&AtClient
//Procedure LineItemsBeforeAddRow(Item, Cancel, Clone, Parent, Folder, Parameter)
//	// Insert handler contents.
//EndProcedure

//&AtClient
//Procedure LineItemsAfterDeleteRow(Item)
//	// Insert handler contents.
//EndProcedure

//&AtClient
//Procedure LineItemsOnEditEnd(Item, NewRow, CancelEdit)
//	// Insert handler contents.
//EndProcedure

//&AtClient
//Procedure LineItemsOnChange(Item)
//	// Insert handler contents.
//EndProcedure

//&AtClient
//Procedure ResidualsOnChange(Item)
//	// Insert handler contents.
//EndProcedure

//&AtClient
//Procedure ResidualsBeforeAddRow(Item, Cancel, Clone, Parent, Folder, Parameter)
//	// Insert handler contents.
//EndProcedure

//&AtClient
//Procedure ResidualsAfterDeleteRow(Item)
//	// Insert handler contents.
//EndProcedure

//&AtClient
//Procedure ResidualsOnEditEnd(Item, NewRow, CancelEdit)
//	// Insert handler contents.
//EndProcedure



//&AtClient
//Procedure LineItemsProductOnChange(Item)
//	// Insert handler contents.
//EndProcedure

//&AtClient
//Procedure ResidualsProductOnChange(Item)
//	// Insert handler contents.
//EndProcedure

//&AtClient
//Procedure LineItemsQuantityOnChange(Item)
//	// Insert handler contents.
//EndProcedure

//&AtClient
//Procedure ResidualsQuantityOnChange(Item)
//	// Insert handler contents.
//EndProcedure

//&AtClient
//Procedure LineItemsUnitOnChange(Item)
//	// Insert handler contents.
//EndProcedure

//&AtClient
//Procedure ResidualsUnitOnChange(Item)
//	// Insert handler contents.
//EndProcedure

//&AtClient
//Procedure LineItemsPriceOnChange(Item)
//	// Insert handler contents.
//EndProcedure

//&AtClient
//Procedure ResidualsPriceOnChange(Item)
//	// Insert handler contents.
//EndProcedure

//&AtClient
//Procedure LineItemsLineTotalOnChange(Item)
//	// Insert handler contents.
//EndProcedure

//&AtClient
//Procedure ResidualsLineTotalOnChange(Item)
//	// Insert handler contents.
//EndProcedure

//&AtClient
//Procedure LineItemsWastePercentOnChange(Item)
//	// Insert handler contents.
//EndProcedure

//&AtClient
//Procedure LineItemsWasteQtyUnitsOnChange(Item)
//	// Insert handler contents.
//EndProcedure

//&AtClient
//Procedure LineItemsWastePriceOnChange(Item)
//	// Insert handler contents.
//EndProcedure


//&AtClient
//Procedure DateOnChange(Item)
//	// Insert handler contents.
//EndProcedure




