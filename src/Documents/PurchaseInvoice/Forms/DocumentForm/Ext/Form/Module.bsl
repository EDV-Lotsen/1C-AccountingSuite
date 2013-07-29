&AtServer
// Check presence of non-closed orders for the passed company
Function HasNonClosedOrders(Company)
	
	// Create new query
	Query = New Query;
	Query.SetParameter("Company", Company);
	
	QueryText = 
		"SELECT
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
	
	// Returns true if there are open or backordered orders
	Return Not Query.Execute().IsEmpty();
	
EndFunction

&AtServer
// Returns array of Order Statuses indicating non-closed orders
Function GetNonClosedOrderStatuses()
	
	// Define all non-closed statuses array
	OrderStatuses  = New Array;
	OrderStatuses.Add(Enums.OrderStatuses.Open);
	OrderStatuses.Add(Enums.OrderStatuses.Backordered);
	
	// Return filled array
	Return OrderStatuses;
	
EndFunction

&AtServer
// Fills document on the base of passed array of orders
// Returns flag o successfull filing
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

&AtClient
// The procedure recalculates the document's total.
// DocumentTotal - document's currency in FCY (foreign currency).
// DocumentTotalRC - company's reporting currency.
//
Procedure RecalcTotal()
	
	If Object.PriceIncludesVAT Then
		Object.DocumentTotal = Object.LineItems.Total("LineTotal") + Object.Accounts.Total("Amount");
		Object.DocumentTotalRC = (Object.LineItems.Total("LineTotal") + Object.Accounts.Total("Amount")) * Object.ExchangeRate;		
	Else
		Object.DocumentTotal = Object.LineItems.Total("LineTotal") + Object.LineItems.Total("VAT") + Object.Accounts.Total("Amount");
		Object.DocumentTotalRC = (Object.LineItems.Total("LineTotal") + Object.LineItems.Total("VAT") + Object.Accounts.Total("Amount")) * Object.ExchangeRate;
	EndIf;	
	Object.VATTotal = Object.LineItems.Total("VAT") * Object.ExchangeRate;
	
EndProcedure

&AtClient
// PriceOnChange UI event handler.
// Calculates line total by multiplying a price by a quantity in either the selected
// unit of measure (U/M) or in the base U/M, and recalculates the line's total.
//
Procedure LineItemsPriceOnChange(Item)
	
	TabularPartRow = Items.LineItems.CurrentData;
	
	TabularPartRow.LineTotal = TabularPartRow.Quantity * TabularPartRow.Price;

	TabularPartRow.VAT = VAT_FL.VATLine(TabularPartRow.LineTotal, TabularPartRow.VATCode, "Purchase", Object.PriceIncludesVAT);
	
	RecalcTotal();
	
EndProcedure

&AtClient
// VendorOnChange UI event handler.
// Selects default currency for the vendor, determines an exchange rate, and
// recalculates the document's total amount.
// 
Procedure CompanyOnChange(Item)
	
	Object.CompanyCode = CommonUse.GetAttributeValue(Object.Company, "Code");
	Object.Currency = CommonUse.GetAttributeValue(Object.Company, "DefaultCurrency");
	Object.APAccount = CommonUse.GetAttributeValue(Object.Currency, "DefaultAPAccount");
	Object.ExchangeRate = GeneralFunctions.GetExchangeRate(Object.Date, Object.Currency);
	Object.Terms = CommonUse.GetAttributeValue(Object.Company, "Terms"); 
	Items.ExchangeRate.Title = GeneralFunctionsReusable.DefaultCurrencySymbol() + "/1" + CommonUse.GetAttributeValue(Object.Currency, "Symbol");
	Items.FCYCurrency.Title = CommonUse.GetAttributeValue(Object.Currency, "Symbol");
	DuePeriod = CommonUse.GetAttributeValue(Object.Terms, "Days");
	Object.DueDate = Object.Date + ?(DuePeriod <> Undefined, DuePeriod, 14) * 60*60*24;
	
	// Open list of non-closed sales orders
	If (Not Object.Company.IsEmpty()) And (HasNonClosedOrders(Object.Company)) Then
		
		// Define form parameters
		FormParameters = New Structure();
		FormParameters.Insert("ChoiceMode", True);
		FormParameters.Insert("MultipleChoice", True);
		
		// Define list filter
		FltrParameters = New Structure();
		FltrParameters.Insert("Company", Object.Company); 
		FltrParameters.Insert("OrderStatus", GetNonClosedOrderStatuses());
		FormParameters.Insert("Filter", FltrParameters);
		
		// Open choice form
		//GOLYA
		//SelectOrdersForm = GetForm("Document.PurchaseOrder.ChoiceForm", FormParameters, Item);
		//SelectedOrders   = SelectOrdersForm.DoModal();
		
		//KZUZIK
		NotifyDescription = New NotifyDescription("OrderSelection", ThisForm);
		OpenForm("Document.PurchaseOrder.ChoiceForm", FormParameters, Item,,,,NotifyDescription) 
		
		// Execute orders filling
		//GOLYA
		//FillDocumentWithSelectedOrders(SelectedOrders);
		
	EndIf;
	
	// Recalc totals
	RecalcTotal();
	
EndProcedure

//KZUZIK
&AtClient
Procedure OrderSelection(Result, Parameters) Export
	
	If Not Result = Undefined Then
		
		FillDocumentWithSelectedOrders(Result);	
		
	EndIf;
	
EndProcedure

&AtClient
// DateOnChange UI event handler.
// Determines an exchange rate on the new date, and recalculates the document's total.
//
Procedure DateOnChange(Item)
	
	If NOT Object.Terms.IsEmpty() Then
		Object.DueDate = Object.Date + CommonUse.GetAttributeValue(Object.Terms, "Days") * 60*60*24;
	EndIf;
	
	Object.ExchangeRate = GeneralFunctions.GetExchangeRate(Object.Date, Object.Currency);
	RecalcTotal();
	
EndProcedure

&AtClient
// CurrencyOnChange UI event handler.
// Determines an exchange rate for the new currency, and recalculates the document's total.
//
Procedure CurrencyOnChange(Item)
	
	Object.ExchangeRate = GeneralFunctions.GetExchangeRate(Object.Date, Object.Currency);
	Object.APAccount = CommonUse.GetAttributeValue(Object.Currency, "DefaultAPAccount");
	Items.ExchangeRate.Title = GeneralFunctionsReusable.DefaultCurrencySymbol() + "/1" + CommonUse.GetAttributeValue(Object.Currency, "Symbol");
	Items.FCYCurrency.Title = CommonUse.GetAttributeValue(Object.Currency, "Symbol");
	RecalcTotal();
	
EndProcedure

&AtClient
// LineItemsAfterDeleteRow UI event handler.
// 
Procedure LineItemsAfterDeleteRow(Item)
	
	RecalcTotal();
	
EndProcedure

&AtClient
// LineItemsQuantityOnChange UI event handler.
// This procedure is used when the units of measure (U/M) functional option is
// turned off and base quantities are used instead of U/M quantities.
// The procedure recalculates line total, and a document's total.
// 
Procedure LineItemsQuantityOnChange(Item)
	
	TabularPartRow = Items.LineItems.CurrentData;
	TabularPartRow.LineTotal = TabularPartRow.Quantity * TabularPartRow.Price;
	TabularPartRow.VAT = VAT_FL.VATLine(TabularPartRow.LineTotal, TabularPartRow.VATCode, "Purchase", Object.PriceIncludesVAT);
	
	RecalcTotal();

EndProcedure

&AtServer
// Procedure fills in default values, used mostly when the corresponding functional
// options are turned off.
// The following defaults are filled in - warehouse location, currency, and due date.
// 
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Object.BegBal = False Then
		Items.DocumentTotalRC.ReadOnly = True;
		Items.DocumentTotal.ReadOnly = True;
	EndIf;
	
	// Initialization of LineItems_OnCloneRow variable
	LineItems_OnCloneRow = False;
	
	Items.Company.Title = GeneralFunctionsReusable.GetVendorName();
	
	//Title = "Purchase Invoice " + Object.Number + " " + Format(Object.Date, "DLF=D");
	
	If Object.Ref.IsEmpty() Then
    	Object.PriceIncludesVAT = GeneralFunctionsReusable.PriceIncludesVAT();
	EndIf;
		
	If NOT GeneralFunctionsReusable.FunctionalOptionValue("VATFinLocalization") Then
		Items.VATGroup.Visible = False;
	EndIf;
	
	If NOT GeneralFunctionsReusable.FunctionalOptionValue("MultiCurrency") Then
		Items.FCYGroup.Visible = False;
	EndIf;
	
	//If GeneralFunctionsReusable.FunctionalOptionValue("MultiLocation") Then
	//Else
		If Object.Location.IsEmpty() Then
			Object.Location = Catalogs.Locations.MainWarehouse;
		EndIf;
	//EndIf;
	
	If Object.Currency.IsEmpty() Then
		Object.Currency = Constants.DefaultCurrency.Get();
		Object.APAccount = Object.Currency.DefaultAPAccount;
		Object.ExchangeRate = 1;	
	Else
	EndIf; 
	
	Items.ExchangeRate.Title = GeneralFunctionsReusable.DefaultCurrencySymbol() + "/1" + Object.Currency.Symbol;
	Items.VATCurrency.Title = GeneralFunctionsReusable.DefaultCurrencySymbol();
	Items.RCCurrency.Title = GeneralFunctionsReusable.DefaultCurrencySymbol();
	Items.FCYCurrency.Title = CommonUse.GetAttributeValue(Object.Currency, "Symbol");
	
EndProcedure

&AtClient
// ProductOnChange UI event handler.
// The procedure clears quantities, line total, and selects a default unit of measure (U/M) for the
// product.
//  
Procedure LineItemsProductOnChange(Item)
	
	TabularPartRow = Items.LineItems.CurrentData;
	
	TabularPartRow.ProductDescription = CommonUse.GetAttributeValue(TabularPartRow.Product, "Description");
	TabularPartRow.Quantity = 0;
	TabularPartRow.LineTotal = 0;
	TabularPartRow.Price = 0;
    TabularPartRow.VAT = 0;
	
	TabularPartRow.VATCode = CommonUse.GetAttributeValue(TabularPartRow.Product, "PurchaseVATCode");
	
	RecalcTotal();
	
EndProcedure

&AtClient
// Calculates a VAT amount for the document line
//
Procedure LineItemsVATCodeOnChange(Item)
	
	TabularPartRow = Items.LineItems.CurrentData;
	TabularPartRow.VAT = VAT_FL.VATLine(TabularPartRow.LineTotal, TabularPartRow.VATCode, "Purchase", Object.PriceIncludesVAT);
    RecalcTotal();

EndProcedure

&AtClient
Procedure AccountsAfterDeleteRow(Item)
	RecalcTotal();
EndProcedure

&AtClient
Procedure AccountBeforeAddRow()

	NewRow = true;	
	
EndProcedure

&AtClient
Procedure AccountsOnChange(Item)
	
If NewRow = true Then
		
	CurrentData = Item.CurrentData;
	CurrentData.Project = Object.Project;
	NewRow = false;
		
Endif;

	RecalcTotal();
EndProcedure

&AtClient
Procedure TermsOnChange(Item)
	
	Object.DueDate = Object.Date + CommonUse.GetAttributeValue(Object.Terms, "Days") * 60*60*24;
	
EndProcedure

&AtClient
Procedure DueDateOnChange(Item)
	
	Object.Terms = NULL;
	
EndProcedure

&AtClient
Procedure LineItemsBeforeAddRow(Item, Cancel, Clone, Parent, Folder)
	
	NewRow = true;
	// Set Clone Row flag
	If Clone And Not Cancel Then
		LineItems_OnCloneRow = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure LineItemsOnChange(Item)
	
	If NewRow = true Then
		
		CurrentData = Item.CurrentData;
		CurrentData.Project = Object.Project;
		//CurrentData.This = what();
		NewRow = false;
		
	Endif;
	
	// Row previously was cloned from another and became edited
	If LineItems_OnCloneRow Then
		// Clear used flag
		LineItems_OnCloneRow = False;
		
		// Clear Order on duplicate row
        CurrentData = Item.CurrentData;
		CurrentData.Order      = Undefined;
		CurrentData.OrderPrice = 0;
	EndIf;
		
EndProcedure

//&AtServer
//Function what()
//	test = Object.Project.FullTitle;
//	return test;
//	
//EndFunction

&AtClient
Procedure URLOpen(Command)
	GotoURL(Object.URL);
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
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
Procedure QueryAll()
	
	//QueryText = "SELECT
	//			 |	PurchaseInvoice.CompanyCode,
	//			 |	PurchaseInvoice.Project
	//			 |FROM
	//			 |	Document.PurchaseInvoice AS PurchaseInvoice";
	//Query = New Query(QueryText);
	//QueryResult = Query.Execute().Unload();


EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
//QueryAll();
//CatalogRef.Pro
//test = Object.Project;
EndProcedure

&AtClient
Procedure AccountsAccountOnChange(Item)
	
	TabularPartRow = Items.Accounts.CurrentData;
	TabularPartRow.AccountDescription = CommonUse.GetAttributeValue
		(TabularPartRow.Account, "Description");

EndProcedure

&AtClient
Procedure BegBalOnChange(Item)
	
	If Object.BegBal = True Then
		Items.DocumentTotalRC.ReadOnly = False;
		Items.DocumentTotal.ReadOnly = False;
	ElsIf Object.BegBal = False Then
		Items.DocumentTotalRC.ReadOnly = True;
		Items.DocumentTotal.ReadOnly = True;
	EndIf;

EndProcedure
