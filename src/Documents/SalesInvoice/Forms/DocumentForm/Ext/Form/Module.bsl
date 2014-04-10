
////////////////////////////////////////////////////////////////////////////////
// Sales invoice: Document form
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
	Items.RefNum.Title              = StringFunctionsClientServer.SubstituteParametersInString(NStr("en = '%1 P.O. / Ref. #'"),    CustomerName);
	Items.RefNum.ToolTip            = StringFunctionsClientServer.SubstituteParametersInString(NStr("en = '%1 purchase order number /
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
	QuantityPrecision = Format(Constants.QtyPrecision.Get(), "NFD=0; NZ=0; NG=0");
	QuantityFormat    = "NFD=" + QuantityPrecision + "; NZ=0";
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
	TaxRate = ?(Not Object.ShipTo.IsEmpty(), 0, 0); // GetTaxRate(Object.ShipTo)
	
	// Update visibility of controls depending on functional options.
	If Not GeneralFunctionsReusable.FunctionalOptionValue("MultiCurrency") Then
		Items.FCYGroup.Visible     = False;
	EndIf;
	
	// Ajust controls availability for the begining balances documents.
	If Object.BegBal  Then
		Items.SalesTax.ReadOnly        = False;
		//Items.SalesTaxRC.ReadOnly      = False;
		Items.DocumentTotal.ReadOnly   = False;
		Items.DocumentTotalRC.ReadOnly = False;
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
	
	//If Not IsBlankString(Object.LastEmail) Then
	//	CommandBar.ChildItems.FormSendEmail.Enabled = False;
	//EndIf;
	// <- CODE REVIEW
	
	If Object.Ref.IsEmpty() Then
		Object.EmailNote = Constants.SalesInvoiceFooter.Get();
	EndIf;
	
	// checking if Reverse journal entry button was clicked
	If Parameters.Property("timetrackobjs") Then
		FillFromTimeTrack(Parameters.timetrackobjs);
	EndIf;


	
EndProcedure

// -> CODE REVIEW
&AtClient
Procedure OnOpen(Cancel)
	
	OnOpenAtServer();
	
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
	
	If InvoiceSent = True Then
		DocObject = object.ref.GetObject();
		DocObject.EmailTo = Object.EmailTo;
		DocObject.LastEmail = "Last email on " + Format(CurrentDate(),"DLF=DT") + " to " + Object.EmailTo;
		DocObject.Write();
	Endif;
	
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
	
	//------------------------------------------------------------------------------
	// Recalculate values of form object attributes.
	
	// Request and fill invoice status from database.
	FillInvoiceStatusAtServer();
	
	// Request and fill ordered items from database.
	FillBackorderQuantityAtServer();
	
EndProcedure

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region CONTROLS_EVENTS_HANDLERS

&AtClient
Procedure DateOnChange(Item)
	
	// Request server operation.
	DateOnChangeAtServer();
	
EndProcedure

&AtServer
Procedure DateOnChangeAtServer()
	
	// Recalculate the retail price for all rows for new date.
	FillRetailPricesAtServer();
	
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
	Object.EmailTo = ?(Not Object.ConfirmTo.IsEmpty(), Object.ConfirmTo.Email, Object.ShipTo.Email);
	TaxRate = ?(Not Object.ShipTo.IsEmpty(), 0, 0); // GetTaxRate(Object.ShipTo)
	
	// Recalculate sales prices for the company.
	FillRetailPricesAtServer();
	
	// Request company default settings.
	Object.Currency    = Object.Company.DefaultCurrency;
	Object.Terms       = CommonUse.GetAttributeValue(Object.Company, "Terms");
	
	// Check company orders for further orders selection.
	FillCompanyHasNonClosedOrders();
	
	// Process settings changes.
	CurrencyOnChangeAtServer();
	TermsOnChangeAtServer();
	
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
	
	// Recalculate the tax rate depending on the shipping address.
	TaxRate = ?(Not Object.ShipTo.IsEmpty(), 0, 0); // GetTaxRate(Object.ShipTo)
	
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
Procedure BegBalOnChange(Item)
	
	// Define totals eiditng by beginning balance flag.
	Items.DocumentTotal.ReadOnly   = Not Object.BegBal;
	Items.DocumentTotalRC.ReadOnly = Not Object.BegBal;
	
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
		DefaultSettingOnChangeAtServer(DefaultSetting);
		
	ElsIf ChoiceResult = DialogReturnCode.No Then
		// Keep new setting, do not update line items.
		ThisForm[DefaultSetting] = Object[DefaultSetting];
		
	Else
		// Restore previously entered setting.
		Object[DefaultSetting] = ThisForm[DefaultSetting];
	EndIf;
	
EndProcedure

&AtServer
Procedure DefaultSettingOnChangeAtServer(DefaultSetting)
	
	// Update line items fields by the object default value.
	For Each Row In Object.LineItems Do
		Row[DefaultSetting] = Object[DefaultSetting];
	EndDo;
	
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
	ProductProperties = CommonUse.GetAttributeValues(TableSectionRow.Product, New Structure("Description, UM, Type"));
	TableSectionRow.ProductDescription = ProductProperties.Description;
	TableSectionRow.UM                 = ProductProperties.UM;
	TableSectionRow.Price              = Round(GeneralFunctions.RetailPrice(Object.Date, TableSectionRow.Product, Object.Company) /
	                                     ?(Object.ExchangeRate > 0, Object.ExchangeRate, 1), 2);
	TableSectionRow.Taxable            = (ProductProperties.Type = Enums.InventoryTypes.Inventory);
	
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
	TableSectionRow.Quantity  = 0;
	TableSectionRow.Ordered   = 0;
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

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region COMMANDS_HANDLERS

// -> CODE REVIEW
//------------------------------------------------------------------------------
// Send invoice by email.

&AtClient
Procedure SendEmail(Command)
	
	SendInvoiceEmail();
	
EndProcedure

&AtServer
Procedure SendInvoiceEmail()
	
	If Object.Ref.IsEmpty() Then
		Message("An email cannot be sent until the invoice is posted or written");
	Elsif Object.Paid = True Then
		Message("This invoice has already been paid through Stripe by the receipient.");
	Else
	
	
	CurObject = object.ref.GetObject();
	
	if CurObject.PayHTML = "" Then
		
		HeadersMap = New Map();
		HeadersMap.Insert("Content-Type", "application/json");
		
		HTTPRequest = New HTTPRequest("/api/1/databases/dataset1c/collections/pay?apiKey=" + ServiceParameters.MongoAPIKey(), HeadersMap);
		
		RequestBodyMap = New Map();
		
		SymbolString = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"; //62
		RandomString20 = "";
		RNG = New RandomNumberGenerator;	
		For i = 0 to 19 Do
			RN = RNG.RandomNumber(1, 62);
			RandomString20 = RandomString20 + Mid(SymbolString,RN,1);
		EndDo;
								 
		RequestBodyMap.Insert("token",RandomString20);
		RequestBodyMap.Insert("type","invoice");
		RequestBodyMap.Insert("data_key",Constants.publishable_temp.get());
		//RequestBodyMap.Insert("data_key","pk_sgcJByLLRiEbS4Unttkz9MEEZlaAh");
		
		//Balance Query
		Query = New Query;
		Query.Text = "SELECT
		             |	ISNULL(GeneralJournalBalance.AmountBalance, 0) AS Balance,
		             |	ISNULL(GeneralJournalBalance.AmountRCBalance, 0) AS BalanceRC
		             |FROM
		             |	Document.SalesInvoice AS DocumentSalesInvoice
		             |		LEFT JOIN AccountingRegister.GeneralJournal.Balance(, , , ExtDimension2 REFS Document.SalesInvoice) AS GeneralJournalBalance
		             |		ON (GeneralJournalBalance.Account = DocumentSalesInvoice.ARAccount)
		             |			AND (GeneralJournalBalance.ExtDimension1 = DocumentSalesInvoice.Company)
		             |			AND (GeneralJournalBalance.ExtDimension2 = DocumentSalesInvoice.Ref)
		             |WHERE
		             |	DocumentSalesInvoice.Ref = &SalesInvoice";
		Query.SetParameter("SalesInvoice", Object.Ref);
		
		QueryResult = Query.Execute().Unload();
		
		RequestBodyMap.Insert("data_amount",QueryResult[0].BalanceRC * 100);
		
		//RequestBodyMap.Insert("data_amount",Object.DocumentTotalRC * 100);
		RequestBodyMap.Insert("data_name",Constants.SystemTitle.Get());
		//ReplaceObjectNum = StrReplace(Object.Number," ","changeme--");
		//RequestBodyMap.Insert("data_description",SessionParameters.TenantValue + " Invoice " + ReplaceObjectNum + " from " + Format(Object.Date,"DLF=D"));
		RequestBodyMap.Insert("data_description",SessionParameters.TenantValue + " Invoice " + Object.Number + " from " + Format(Object.Date,"DLF=D"));
		//RequestBodyMap.Insert("data_invoice_num",Object.Number);
		//RequestBodyMap.Insert("data_description","1100609" + " Invoice " + Object.Number + " from " + Format(Object.Date,"DLF=D"));
		RequestBodyMap.Insert("live_secret",Constants.secret_temp.Get());
		//RequestBodyMap.Insert("live_secret","sk_b9hTZPel2GaYNn2fYHUVoIQrcXO9O");
		RequestBodyMap.Insert("paid","false");
		RequestBodyMap.Insert("api_code",String(Object.Ref.UUID()));
		
		
		RequestBodyString = InternetConnectionClientServer.EncodeJSON(RequestBodyMap);
		
		HTTPRequest.SetBodyFromString(RequestBodyString,TextEncoding.ANSI); // ,TextEncoding.ANSI
		
		SSLConnection = New OpenSSLSecureConnection();
		
		HTTPConnection = New HTTPConnection("api.mongolab.com",,,,,,SSLConnection);
		Result = HTTPConnection.Post(HTTPRequest);
		//ResponseBody = Result.GetBodyAsString(TextEncoding.UTF8);
		// send e-mail
		
		//Query = New Query("SELECT
		//					 |	Addresses.Email
		//					 |FROM
		//					 |	Catalog.Addresses AS Addresses
		//					 |WHERE
		//					 |	Addresses.Owner = &Company
		//					 |	AND Addresses.DefaultBilling = True");
		//	Query.SetParameter("Company", Object.Company);
		//	QueryResult = Query.Execute().Unload();
		//	Recipient = QueryResult[0][0];
		
		FormatHTML = "<a href=""https://pay.accountingsuite.com/invoice?token=" + RandomString20 + """>Pay invoice</a>";
		CurObject.PayHTML = "https://pay.accountingsuite.com/invoice?token=" + RandomString20;
		
		HeadersMap = New Map();
		HeadersMap.Insert("Content-Type", "application/json");
	
	EndIf;
	////
	
	test2 = CurObject.PayHTML;
	
	If Object.EmailTo <> "" Then
		
	 	//imagelogo = Base64String(GeneralFunctions.GetLogo());
	 	If constants.logoURL.Get() = "" Then
			 imagelogo = "http://www.accountingsuite.com/images/logo-a.png";
	 	else
			 imagelogo = Constants.logoURL.Get();  
	 	Endif;
	 	
	 	datastring = "";	
	 	For Each DocumentLine in Object.LineItems Do
			If NOT DocumentLine.Order.isEmpty() Then
				DocObj = DocumentLine.Order.GetObject();
			
				datastring = datastring + "<TR height=""20""><TD style=""border-spacing: 0px 0px;height: 20px;"">" + DocumentLine.Product + "</TD><TD style=""border-spacing: 0px 0px;height: 20px;"">" + DocumentLine.ProductDescription + "</TD><TD style=""border-spacing: 0px 0px;height: 20px;"">" + DocObj.RefNum + "</TD><TD style=""border-spacing: 0px 0px;height: 20px;"">" + DocumentLine.Project.Description + "</TD><TD style=""border-spacing: 0px 0px;height: 20px;"">" + DocumentLine.Quantity + "</TD><TD style=""border-spacing: 0px 0px;height: 20px;"">" + Format(DocumentLine.Price,"NFD=2") + "</TD><TD align=""right"" style=""border-spacing: 0px 0px;height: 20px;"">" + Format(DocumentLine.LineTotal,"NFD=2") + "</TD></TR>";
			Else
				datastring = datastring + "<TR height=""20""><TD style=""border-spacing: 0px 0px;height: 20px;"">" + DocumentLine.Product + "</TD><TD style=""border-spacing: 0px 0px;height: 20px;"">" + DocumentLine.ProductDescription + "</TD><TD style=""border-spacing: 0px 0px;height: 20px;"">" + "" + "</TD><TD style=""border-spacing: 0px 0px;height: 20px;"">" + DocumentLine.Project.Description + "</TD><TD style=""border-spacing: 0px 0px;height: 20px;"">" + DocumentLine.Quantity + "</TD><TD style=""border-spacing: 0px 0px;height: 20px;"">" + Format(DocumentLine.Price,"NFD=2") + "</TD><TD align=""right"" style=""border-spacing: 0px 0px;height: 20px;"">" + Format(DocumentLine.LineTotal,"NFD=2") + "</TD></TR>";
			Endif;
			
		 EndDo;
			 
	 	  MailProfil = New InternetMailProfile; 
	 	  	   
	   	 MailProfil.SMTPServerAddress = ServiceParameters.SMTPServer(); 
	 	  MailProfil.SMTPUseSSL = ServiceParameters.SMTPUseSSL();
	 	  MailProfil.SMTPPort = 465; 
	 	  
	 	  MailProfil.Timeout = 180; 
	 	  
		  MailProfil.SMTPPassword = ServiceParameters.SendGridPassword();
	 	  
		  MailProfil.SMTPUser = ServiceParameters.SendGridUserName();
	 	  
	 	  
	 	  send = New InternetMailMessage; 
	 	  //send.To.Add(object.shipto.Email);
		  send.To.Add(Object.EmailTo);
		  
		  If Object.EmailCC <> "" Then
			EAddresses = StringFunctionsClientServer.SplitStringIntoSubstringArray(Object.EmailCC, ",");
			For Each EmailAddress in EAddresses Do
				send.CC.Add(EmailAddress);
			EndDo;
		  Endif;
		
	 	  send.From.Address = Constants.Email.Get();
	 	  send.From.DisplayName = "AccountingSuite";
	 	  send.Subject = Constants.SystemTitle.Get() + " - Invoice " + Object.Number + " from " + Format(Object.Date,"DLF=D") + " - $" + Format(Object.DocumentTotalRC,"NFD=2");
	 	  
	 	  FormatHTML = StrReplace(FormAttributeToValue("Object").GetTemplate("HTMLTest").GetText(),"object.terms",object.Terms);
	 	  
		  
		   temptest = false;
		  If Constants.secret_temp.Get() = "" Then
		  	FormatHTML2 = StrReplace(FormatHTML,"<td width=""25%""><a class=""button"" href=""payHTML"" style=""width: 75%;display: block;padding: 17px 18px 16px 18px;-webkit-border-radius: 8px;-moz-border-radius: 8px;border-radius: 8px;background: #edbe1c;border-color: #FFF;text-align: center;color: #FFF;text-decoration: none;"">PAY NOW</a></td>", " ");
			temptest = true;
		  Else
			temptest = false;
		  Endif;
		
		  If temptest = true Then
		  	FormatHTML2 = StrReplace(FormatHTML2,"object.number",object.Number);
		  Else
			FormatHTML2 = StrReplace(FormatHTML,"object.number",object.Number);
		  Endif;
		
		  If Curobject.PayHTML = "" Then
		  FormatHTML2 = StrReplace(FormatHTML2,"href=""payHTML"""," ");
		  FormatHTML2 = StrReplace(FormatHTML2,"<a class=""button"" href=""payHTML"" style=""width: 75%;display: block;padding: 17px 18px 16px 18px;-webkit-border-radius: 8px;-moz-border-radius: 8px;border-radius: 8px;background: #edbe1c;border-color: #FFF;text-align: center;color: #FFF;text-decoration: none;"">PAY NOW</a>", " ");
		  Else
		  FormatHTML2 = StrReplace(FormatHTML2,"payHTML",Curobject.PayHTML);
		  Endif;
		  FormatHTML2 = StrReplace(FormatHTML2,"imagelogo",imagelogo);
	 	  FormatHTML2 = StrReplace(FormatHTML2,"object.refnum",object.RefNum);
	 	  FormatHTML2 = StrReplace(FormatHTML2,"object.date",Format(object.Date,"DLF=D"));
	 	  FormatHTML2 = StrReplace(FormatHTML2,"object.duedate",Format(object.DueDate,"DLF=D"));
	 	  FormatHTML2 = StrReplace(FormatHTML2,"object.number",object.Number);
	 	  //BillTo
	 	  FormatHTML2 = StrReplace(FormatHTML2,"object.company",object.Company);
	 	  FormatHTML2 = StrReplace(FormatHTML2,"object.shipto1",object.ShipTo.AddressLine1);
	 	  FormatHTML2 = StrReplace(FormatHTML2,"object.shipto2",object.ShipTo.AddressLine2);
		  CityStateZip = object.ShipTo.City + object.ShipTo.State + object.ShipTo.ZIP;
		  
		  If CityStateZip = "" Then
		  	FormatHTML2 = StrReplace(FormatHTML2,"object.city object.state object.zip","");
		  Else
	 	  	FormatHTML2 = StrReplace(FormatHTML2,"object.city object.state object.zip",object.ShipTo.City + ", " + object.ShipTo.State + " " + object.ShipTo.ZIP);
		  Endif;
	 	  FormatHTML2 = StrReplace(FormatHTML2,"object.country",object.ShipTo.Country);
	 	  //lineitems
	 	  FormatHTML2 = StrReplace(FormatHTML2,"lineitems",datastring);
	 	  
	 	  //shipto
	 	  If object.ShipTo.DefaultShipping = true Then
				 FormatHTML2 = StrReplace(FormatHTML2,"shipbject.company",object.Company);
	 	 		 FormatHTML2 = StrReplace(FormatHTML2,"shipbject.shipto1",object.ShipTo.AddressLine1);
	 	  		 FormatHTML2 = StrReplace(FormatHTML2,"shipbject.shipto2",object.ShipTo.AddressLine2);
				 If CityStateZip = "" Then
		  			FormatHTML2 = StrReplace(FormatHTML2,"shipbject.city shipobject.state shipobject.zip","");
		  		 Else
	 	  		 	FormatHTML2 = StrReplace(FormatHTML2,"shipbject.city shipobject.state shipobject.zip",object.ShipTo.City + ", " + object.ShipTo.State + " " + object.ShipTo.ZIP);
				 Endif;
	 	  		 FormatHTML2 = StrReplace(FormatHTML2,"shipbject.country",object.ShipTo.Country);
	 	  Endif;
		
			   
	 	  //User's company info
	 	  FormatHTML2 = StrReplace(FormatHTML2,"mycompany",Constants.SystemTitle.Get()); 
	 	  FormatHTML2 = StrReplace(FormatHTML2,"myaddress1",Constants.AddressLine1.Get());
	 	  FormatHTML2 = StrReplace(FormatHTML2,"myaddress2",Constants.AddressLine2.Get());
	 	  FormatHTML2 = StrReplace(FormatHTML2,"mycity mystate myzip",Constants.City.Get() + ", " + Constants.State.Get() + " " + Constants.ZIP.Get());
	 	  FormatHTML2 = StrReplace(FormatHTML2,"myphone",Constants.Phone.Get());
	 	  FormatHTML2 = StrReplace(FormatHTML2,"myemail",Constants.Email.Get());
	 	  
	 	  //subtotals
	 	  FormatHTML2 = StrReplace(FormatHTML2,"object.subtotal",Format(object.DocumentTotalRC,"NFD=2"));
	 	  If object.SalesTax = 0 Then
				FormatHTML2 = StrReplace(FormatHTML2,"object.salestax","0.00");
	 	  Else
	 	 		 FormatHTML2 = StrReplace(FormatHTML2,"object.salestax",Format(object.SalesTax,"NFD=2"));
	 	  Endif;
			 
	 	  FormatHTML2 = StrReplace(FormatHTML2,"object.total",Format(object.DocumentTotalRC,"NFD=2"));
	 	  
	 	  
	   Query = New Query();
	   Query.Text =
	   "SELECT
	   |	SalesInvoice.Ref,
	   |	SalesInvoice.DocumentTotal,
	   |	SalesInvoice.SalesTax,
	   |	SalesInvoice.LineItems.(
	   |		Product,
	   |		Product.UM AS UM,
	   |		ProductDescription,
	   |		LineItems.Order.RefNum AS PO,
	   |		Quantity,
	   |		Price,
	   |		LineTotal,
	   |		Project
	   |	),
	   |	GeneralJournalBalance.AmountRCBalance AS Balance
	   |FROM
	   |	Document.SalesInvoice AS SalesInvoice
	   |		LEFT JOIN AccountingRegister.GeneralJournal.Balance AS GeneralJournalBalance
	   |		ON GeneralJournalBalance.ExtDimension1 = SalesInvoice.Company
	   |			AND GeneralJournalBalance.ExtDimension2 = SalesInvoice.Ref
	   |WHERE
	   |	SalesInvoice.Ref IN(&Ref)";
	
	   Query.SetParameter("Ref", Object.Ref);
	   Selection = Query.Execute().Select();
	
	  While Selection.Next() Do 
	  
	  SelectionLineItems = Selection.LineItems.Select();
	   LineTotalSum = 0;
	   While SelectionLineItems.Next() Do
			 
			 LineTotal = SelectionLineItems.LineTotal;
			 LineTotalSum = LineTotalSum + LineTotal;
			 
	   EndDo;
	
	   
	   DTotal = LineTotalSum + Selection.SalesTax;
	
	 	  
	   objcredits = 0;
	   If NOT Selection.Balance = NULL Then
			objcredits = DTotal - Selection.Balance;
	   ElsIf Selection.Ref.Posted = FALSE Then
			objcredits = 0;
	   Else
			objcredits = DTotal;
	   EndIf;
	
		objbalance = 0;
	   If NOT Selection.Balance = NULL Then
			objbalance = Selection.Balance;
	   Else
			objbalance = 0;
	   EndIf;
		
	   EndDo;	
		
	   If objcredits = 0 Then
	 	   FormatHTML2 = StrReplace(FormatHTML2,"object.credits","0.00");
	   Else
	  		 FormatHTML2 = StrReplace(FormatHTML2,"object.credits",Format(objcredits,"NFD=2"));
	   Endif;
	
	   If objbalance = 0 Then
		 FormatHTML2 = StrReplace(FormatHTML2,"object.balance","0.00");
		Else
		 FormatHTML2 = StrReplace(FormatHTML2,"object.balance",Format(objbalance,"NFD = 2"));
	   Endif;
	
	   //Note
	   FormatHTML2 = StrReplace(FormatHTML2,"object.note",Object.EmailNote);
	 	  
			
	 	  
	 	  send.Texts.Add(FormatHTML2,InternetMailTextType.HTML);
			
	 	  Posta = New InternetMail; 
	 	  Posta.Logon(MailProfil); 
	 	  Posta.Send(send); 
	 	  Posta.Logoff(); 
		  
		  //DocObject = object.ref.GetObject();
		  //DocObject.EmailTo = Object.EmailTo;
		  //DocObject.LastEmail = "Last email on " + Format(CurrentDate(),"DLF=DT") + " to " + Object.EmailTo;
		  //DocObject.Write();
		  Message("Invoice email has been sent");
		  InvoiceSent = True;
		  
		  
	   Else
		  Message("The recipient email has not been specified");
	   Endif;
		 
	 Endif;
	
EndProcedure

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
		
	DataJSON = "{""DocDate"": ""2013-06-01"",""CustomerCode"": ""abc456789"",""DocType"": ""SalesInvoice"",""Addresses"":[{""AddressCode"": ""Origin"",""Line1"": ""118 N Clark St"",""City"": ""Chicago"",""Region"": ""IL"",""PostalCode"": ""60602-1304"",""Country"": ""US""},{""AddressCode"": ""Dest"",""Line1"": ""1060 W. Addison St"",""City"": ""Chicago"",""Region"": ""IL"",""PostalCode"": ""60613-4566"",""Country"": ""US""}],""Lines"":[{""LineNo"": ""00001"",""DestinationCode"": ""Dest"",""OriginCode"": ""Origin"",""ItemCode"": ""SP-001"",""Description"": ""Running Shoe"",""TaxCode"": ""PC030147"",""Qty"": 1,""Amount"": 100}]}";
	
	HeadersMap = New Map();
	HeadersMap.Insert("Content-Type", "text/json");
	HeadersMap.Insert("Authorization", ServiceParameters.AvalaraAuth());
	ConnectionSettings = New Structure;
	Connection = InternetConnectionClientServer.CreateConnection("https://development.avalara.net/1.0/tax/get", ConnectionSettings).Result;
	ResultBody = InternetConnectionClientServer.SendRequest(Connection, "Post", ConnectionSettings, HeadersMap, DataJSON).Result;
	DecodedResultBody = InternetConnectionClientServer.DecodeJSON(ResultBody);
	Object.SalesTax = DecodedResultBody.TotalTax;
	RecalculateTotalsAtServer();
	
EndProcedure

// <- CODE REVIEW

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
// Request retail prices of the products from database.
Procedure FillRetailPricesAtServer()
	
	// Recalculate retail price for each row (later the new function scanning prices for the product must be used).
	For Each TableSectionRow In Object.LineItems Do
		TableSectionRow.Price = Round(GeneralFunctions.RetailPrice(Object.Date, TableSectionRow.Product, Object.Company) /
		                        ?(Object.ExchangeRate > 0, Object.ExchangeRate, 1), 2);
		LineItemsPriceOnChangeAtServer(TableSectionRow);
	EndDo;
	
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
	
		//prepay beg
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

			         //object.ref.GetForm().
		EndDo;

		If ExistBalance = True Then
			//Message("You have unapplied payments to " + SOString + ". Please apply them using the Cash Receipt document.");
			Message("You have unapplied payments to " + SOString + ". Please apply them using the Cash Receipt document.");

		EndIf;
		//prepay end	
	
EndProcedure
// <- CODE REVIEW

//------------------------------------------------------------------------------
// Calculate totals and fill object attributes.

&AtClient
// The procedure recalculates the document's totals.
Procedure RecalculateTotals()
	
	// Calculate document totals.
	LineSubtotal = 0;
	For Each Row In Object.LineItems Do
		LineSubtotal = LineSubtotal  + Row.LineTotal;
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
	Return New Structure("LineNumber, Product, ProductDescription, Quantity, UM, Ordered, Backorder, Shipped, Invoiced, Price, LineTotal, Taxable, TaxableAmount, Order, Location, LocationActual, DeliveryDate, DeliveryDateActual, Project, Class");
	
EndFunction

//When generated from time tracking, fills invoice with selected entries.
&AtServer
Procedure FillFromTimeTrack(timedocs)
	
	
	Object.Company = timedocs[0].Company;
	Object.Project = timedocs[0].Project;
	Object.Currency    = Object.Company.DefaultCurrency;
	Object.Terms       = CommonUse.GetAttributeValue(Object.Company, "Terms");
	
	CurrencyOnChangeAtServer();
	TermsOnChangeAtServer();

	
	
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
			
			If Entry.SalesOrder.IsEmpty() = False Then
				NewLine.Order = Entry.SalesOrder;
			EndIf;
			
			NewLine.Product = Entry.Task;
			NewLine.ProductDescription = NewLine.Product.Description;
			NewLine.LocationActual = Object.LocationActual;
			NewLine.DeliveryDateActual = Entry.Date;
			NewLine.UM = NewLine.Product.UM;
			NewLine.Price = Entry.Price;
			NewLine.Quantity = Entry.TimeComplete;
			NewLine.LineTotal = Entry.Price * Entry.TimeComplete; 
			NewLine.Project = Entry.Project;
			NewLine.Class = Entry.Class;
					
		EndDo;
		
		Total = 0;	
		For Each LineItem In Object.LineItems Do
			Total = Total + LineItem.LineTotal;
		EndDo;
		Object.LineSubtotal = Total;
		Object.SubTotal = Total;
		Object.DocumentTotal = Total;
		Object.DocumentTotalRC = Total;


	
EndProcedure


#EndRegion
