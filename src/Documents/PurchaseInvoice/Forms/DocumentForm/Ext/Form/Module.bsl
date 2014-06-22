
////////////////////////////////////////////////////////////////////////////////
// Purchase invoice: Document form
//------------------------------------------------------------------------------
// Available on:
// - Client (managed application)
// - Server
//

////////////////////////////////////////////////////////////////////////////////
#Region EVENTS_HANDLERS

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("Company") And Parameters.Company.Vendor And Object.Ref.IsEmpty() Then
		Object.Company = Parameters.Company;
		OpenOrdersSelectionForm = True; 
	EndIf;

	
	//------------------------------------------------------------------------------
	// 1. Form attributes initialization.
	
	// Set LineItems editing flag.
	IsNewRow     = False;
	
	// Fill object attributes cache.
	DeliveryDateActual = Object.DeliveryDateActual;
	LocationActual     = Object.LocationActual;
	Project            = Object.Project;
	Class              = Object.Class;
	
	//------------------------------------------------------------------------------
	// 2. Calculate values of form object attributes.
	
	// Request and fill invoice status.
	FillInvoiceStatusAtServer();
	
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
	QuantityFormat = GeneralFunctionsReusable.DefaultQuantityFormat();
	Items.LineItemsQuantity.EditFormat  = QuantityFormat;
	Items.LineItemsQuantity.Format      = QuantityFormat;
	Items.LineItemsOrdered.EditFormat   = QuantityFormat;
	Items.LineItemsOrdered.Format       = QuantityFormat;
	Items.LineItemsReceived.EditFormat  = QuantityFormat;
	Items.LineItemsReceived.Format      = QuantityFormat;
	Items.LineItemsBackorder.EditFormat = QuantityFormat;
	Items.LineItemsBackorder.Format     = QuantityFormat;
	Items.LineItemsInvoiced.EditFormat  = QuantityFormat;
	Items.LineItemsInvoiced.Format      = QuantityFormat;
	
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
	
EndProcedure

// -> CODE REVIEW
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
	//Period closing
	If PeriodClosingServerCall.DocumentPeriodIsClosed(CurrentObject.Ref, CurrentObject.Date) Then
		PermitWrite = PeriodClosingServerCall.DocumentWritePermitted(WriteParameters);
		CurrentObject.AdditionalProperties.Insert("PermitWrite", PermitWrite);	
	EndIf;
	
	// Finds an invoice with the same number, if so, do not allow.
	If Not IsBlankString(Object.Number) Then
		QueryText2 = "SELECT
		             |	PurchaseInvoice.Ref
		             |FROM
		             |	Document.PurchaseInvoice AS PurchaseInvoice
		             |WHERE
		             |	PurchaseInvoice.Ref <> &Ref
		             |	AND PurchaseInvoice.Company = &Company
		             |	AND PurchaseInvoice.Number = &Number";
		Query = New Query(QueryText2);
		Query.SetParameter("Ref", Object.Ref);
		Query.SetParameter("Company", Object.Company);
		Query.SetParameter("Number", Object.Number);
		QueryResult = Query.Execute();
		
		If QueryResult.IsEmpty() Then
		Else
			Message("Bill # for this vendor already exists");
			Cancel = True;
		Endif;
	EndIf;
	
	// Check empty bill.
	If Object.LineItems.Count() = 0 AND Object.Accounts.Count() = 0 Then
		Message("Cannot post when there are no expenses or items.");
		Cancel = True;
	EndIf;
	// <- CODE REVIEW
	
	
	//------------------------------------------------------------------------------
	// 1. Correct the invoice date according to the orders dates.
	
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
	FillCompanyAddressesAtServer(Object.Company, Object.CompanyAddress);
	
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
		OpenForm("Document.PurchaseOrder.ChoiceForm", FormParameters, Item,,,, NotifyDescription);
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
	Object.APAccount               = Object.Currency.DefaultAPAccount;
	
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
	CommonDefaultSettingOnChange(Item, Lower(Item.ToolTip), NStr("en = 'line items'"));
	
EndProcedure

&AtClient
Procedure DeliveryDateActualOnChange(Item)
	
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
		DefaultSettingOnChangeAtServer(DefaultSetting);
		
	ElsIf ChoiceResult = DialogReturnCode.No Then
		// Keep new setting, do not update line items and accounts.
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
	
	// Update accounts fields by the object default value.
	Try // Real check defined by: Metadata.FindByType(TypeOf(Object.Ref)).TabularSections.Accounts.Attributes.Find(DefaultSetting) <> Undefined
		For Each Row In Object.Accounts Do
			Row[DefaultSetting] = Object[DefaultSetting];
		EndDo;
	Except
	EndTry;
	
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
		ClearFields  = New Structure("Order, OrderPrice, Location, DeliveryDate");
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
	ProductProperties = CommonUse.GetAttributeValues(TableSectionRow.Product, New Structure("Description, UM"));
	TableSectionRow.ProductDescription = ProductProperties.Description;
	TableSectionRow.UM                 = ProductProperties.UM;
	TableSectionRow.Price              = GeneralFunctions.ProductLastCost(TableSectionRow.Product);
	
	// Reset default values.
	FillPropertyValues(TableSectionRow, Object, "LocationActual, DeliveryDateActual, Project, Class");
	
	// Clear up order data.
	TableSectionRow.Order        = Documents.PurchaseOrder.EmptyRef();
	TableSectionRow.OrderPrice   = 0;
	TableSectionRow.DeliveryDate = '00010101';
	TableSectionRow.Location     = Catalogs.Locations.EmptyRef();
	
	// Assign default quantities.
	TableSectionRow.Quantity  = 0;
	TableSectionRow.Ordered   = 0;
	TableSectionRow.Backorder = 0;
	TableSectionRow.Received  = 0;
	TableSectionRow.Invoiced  = 0;
	
	// Calculate totals by line.
	TableSectionRow.LineTotal = 0;
	
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
	
EndProcedure

//------------------------------------------------------------------------------
// Tabular section Accounts event handlers.

&AtClient
Procedure AccountsOnChange(Item)
	
	// Row was just added and became edited.
	If IsNewRow Then
		
		// Clear used flag.
		IsNewRow = False;
		
		// Fill new row with default values.
		ObjectData  = New Structure("Project, Class");
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
Procedure AccountsBeforeAddRow(Item, Cancel, Clone, Parent, Folder)
	
	// Set new row flag.
	If Not Cancel Then
		IsNewRow = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure AccountsOnEditEnd(Item, NewRow, CancelEdit)
	
	// Recalculation common document totals.
	RecalculateTotalsAtServer();
	
EndProcedure

&AtClient
Procedure AccountsAfterDeleteRow(Item)
	
	// Recalculation common document totals.
	RecalculateTotalsAtServer();
	
EndProcedure

//------------------------------------------------------------------------------
// Tabular section Accounts columns controls event handlers.

&AtClient
Procedure AccountsAmountOnChange(Item)
	
	// Refresh totals cache.
	RecalculateTotals();
	
EndProcedure

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region COMMANDS_HANDLERS

&AtClient
Procedure URLOpen(Command)
	
	// Open a new browser page and go to the passed URL.
	GotoURL(Object.URL);
	
EndProcedure

// -> CODE REVIEW
//------------------------------------------------------------------------------
// Invoice payment

&AtClient
Procedure PayInvoice(Command)
	
	PayInvoiceAtServer();
	
EndProcedure

&AtServer
Procedure PayInvoiceAtServer()
	
	If Object.Posted = False Then
		Message("An invoice payment cannot be created for the invoice because it has not yet been created(posted)");
	Else
		
		NewCashReceipt = Documents.InvoicePayment.CreateDocument();
		NewCashReceipt.Company = Object.Company;
		NewCashReceipt.Date = CurrentDate();
		NewCashReceipt.Currency = Object.Currency;
		NewCashReceipt.DocumentTotal = Object.DocumentTotalRC;
		NewCashReceipt.DocumentTotalRC = Object.DocumentTotalRC;
		NewCashReceipt.BankAccount = Constants.BankAccount.Get();
		NewCashReceipt.PaymentMethod = Catalogs.PaymentMethods.Check;
		//NewCashReceipt.Number = 
		NewLine = NewCashReceipt.LineItems.Add();
		NewLine.Check = True;
		NewLine.Document = Object.Ref;
		NewLine.Balance = Object.DocumentTotalRC;
		NewLine.Payment = Object.DocumentTotalRC;
		        
		NewCashReceipt.Write(DocumentWriteMode.Posting);
		CommandBar.ChildItems.FormPayInvoice.Enabled = False;
		PaidInvoiceCheck = True;
		
		Message("Am invoice payment has been created for " + Object.Ref);
		
	Endif;
	
EndProcedure

&AtClient
Procedure BillPayments(Command)
	
	FormParameters = New Structure();
	
	FltrParameters = New Structure();
	FltrParameters.Insert("BillPays", Object.Ref);
	FormParameters.Insert("Filter", FltrParameters);
	OpenForm("CommonForm.BillPayList",FormParameters, Object.Ref);
	
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
		Query.SetParameter("Account", Object.APAccount);
		
		// Request payable amount for the account.
		Query.Text =
			"SELECT
			|	-GeneralJournalBalance.AmountBalance AS Amount
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
		//	|	OrdersDispatchedBalance.Product          AS Product,
		//	|	OrdersDispatchedBalance.Location         AS Location,
		//	|	OrdersDispatchedBalance.DeliveryDate     AS DeliveryDate,
		//	|	OrdersDispatchedBalance.Project          AS Project,
		//	|	OrdersDispatchedBalance.Class            AS Class,
		//	//  Request resources                                                                                               // ---------------------------------------
		//	|	OrdersDispatchedBalance.QuantityBalance  AS Quantity,                                                           // Backorder quantity calculation
		//	|	CASE                                                                                                            // ---------------------------------------
		//	|		WHEN &OrderStatus = VALUE(Enum.OrderStatuses.Open)        THEN 0                                            // Order status = Open:
		//	|		WHEN &OrderStatus = VALUE(Enum.OrderStatuses.Backordered) THEN                                              //   Backorder = 0
		//	|			CASE                                                                                                    // Order status = Backorder:
		//	|				WHEN OrdersDispatchedBalance.Product.Type = VALUE(Enum.InventoryTypes.Inventory) THEN               //   Inventory:
		//	|					CASE                                                                                            //     Backorder = Ordered - Received >= 0
		//	|						WHEN OrdersDispatchedBalance.QuantityBalance > OrdersDispatchedBalance.ReceivedBalance THEN //     |
		//	|							 OrdersDispatchedBalance.QuantityBalance - OrdersDispatchedBalance.ReceivedBalance      //     |
		//	|						ELSE 0 END                                                                                  //     |
		//	|				ELSE                                                                                                //   Non-inventory:
		//	|					CASE                                                                                            //     Backorder = Ordered - Invoiced >= 0
		//	|						WHEN OrdersDispatchedBalance.QuantityBalance > OrdersDispatchedBalance.InvoicedBalance THEN //     |
		//	|							 OrdersDispatchedBalance.QuantityBalance - OrdersDispatchedBalance.InvoicedBalance      //     |
		//	|						ELSE 0 END                                                                                  //     |
		//	|				END                                                                                                 //     |
		//	|		WHEN &OrderStatus = VALUE(Enum.OrderStatuses.Closed)      THEN 0                                            // Order status = Closed:
		//	|		END                                  AS Backorder,                                                          //   Backorder = 0
		//	|	OrdersDispatchedBalance.ReceivedBalance  AS Received,
		//	|	OrdersDispatchedBalance.InvoicedBalance  AS Invoiced
		//	//  Request sources
		//	|FROM
		//	|	Document.PurchaseOrder.LineItems         AS LineItems
		//	|	LEFT JOIN AccumulationRegister.OrdersDispatched.Balance(,Order = &Ref)
		//	|		                                     AS OrdersDispatchedBalance
		//	|		ON    ( LineItems.Ref.Company         = OrdersDispatchedBalance.Company
		//	|			AND LineItems.Ref                 = OrdersDispatchedBalance.Order
		//	|			AND LineItems.Product             = OrdersDispatchedBalance.Product
		//	|			AND LineItems.Location            = OrdersDispatchedBalance.Location
		//	|			AND LineItems.DeliveryDate        = OrdersDispatchedBalance.DeliveryDate
		//	|			AND LineItems.Project             = OrdersDispatchedBalance.Project
		//	|			AND LineItems.Class               = OrdersDispatchedBalance.Class
		//	|			AND LineItems.Quantity            = OrdersDispatchedBalance.QuantityBalance)
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
		//		FillPropertyValues(FoundLineItems[0], Selection, "Backorder, Received, Invoiced");
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
		|	PurchaseOrder.Ref
		|FROM
		|	Document.PurchaseOrder AS PurchaseOrder
		|	LEFT JOIN InformationRegister.OrdersStatuses.SliceLast AS OrdersStatuses
		|		ON PurchaseOrder.Ref = OrdersStatuses.Order
		|WHERE
		|	PurchaseOrder.Company = &Company
		|AND
		|	CASE
		|		WHEN PurchaseOrder.DeletionMark THEN
		|			 VALUE(Enum.OrderStatuses.Deleted)
		|		WHEN NOT PurchaseOrder.Posted THEN
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
// Returns flag of successfull filing.
Function FillDocumentWithSelectedOrders(SelectedOrders)
	
	// Fill table on the base of selected orders
	If SelectedOrders <> Undefined Then
		
		// Fill object by orders
		DocObject = FormAttributeToValue("Object");
		DocObject.Fill(SelectedOrders);
		
		// Return filled object to form
		ValueToFormAttribute(DocObject, "Object");
		
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

//------------------------------------------------------------------------------
// Calculate totals and fill object attributes.

&AtClient
Procedure RecalculateTotals()
	
	// Calculate document totals.
	LineItemsTotal = 0; AccountsTotal = 0;
	For Each Row In Object.LineItems Do
		LineItemsTotal = LineItemsTotal + Row.LineTotal;
	EndDo;
	For Each Row In Object.Accounts Do
		AccountsTotal  = AccountsTotal  + Row.Amount;
	EndDo;
	
	// Assign totals to the object fields.
	Object.DocumentTotal   = LineItemsTotal + AccountsTotal;
	Object.DocumentTotalRC = Round(Object.DocumentTotal * Object.ExchangeRate, 2);
	
EndProcedure

&AtServer
Procedure RecalculateTotalsAtServer()
	
	// Calculate document totals.
	Object.DocumentTotal   = Object.LineItems.Total("LineTotal") + Object.Accounts.Total("Amount");
	Object.DocumentTotalRC = Round(Object.DocumentTotal * Object.ExchangeRate, 2);
	
EndProcedure

//------------------------------------------------------------------------------
// Replacemant for metadata properties on client.

&AtClient
// Returns fields structure of LineItems form control.
Function GetLineItemsRowStructure()
	
	// Define control row fields.
	Return New Structure("LineNumber, Product, ProductDescription, Quantity, UM, Ordered, Backorder, Received, Invoiced, OrderPrice, Price, LineTotal, Order, ItemReceipt, Location, LocationActual, DeliveryDate, DeliveryDateActual, Project, Class");
	
EndFunction

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


#EndRegion
