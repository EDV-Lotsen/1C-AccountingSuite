﻿&AtServer
// Check presence of non-closed orders for the passed company
Function HasNonClosedOrders(Company)
	
	// Create new query
	Query = New Query;
	Query.SetParameter("Company", Company);
	
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
		Object.RefNum = SelectedOrders[0].RefNum;
		//Object.Project = SelectedOrders[0].Project;
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
// ProductOnChange UI event handler.
// The procedure clears quantities, line total, and taxable amount in the line item,
// selects price for the new product from the price-list, divides the price by the document
// exchange rate, selects a default unit of measure for the product, and
// selects a product's sales tax type.
// 
Procedure LineItemsProductOnChange(Item)
	
	TabularPartRow = Items.LineItems.CurrentData;
	
	DataArray = GetDataOnServer(TabularPartRow.Product, Object.Company);
	
	//TabularPartRow.ProductDescription = CommonUse.GetAttributeValue(TabularPartRow.Product, "Description");
	
	TabularPartRow.ProductDescription = DataArray[0];
	TabularPartRow.Quantity = 0;
	TabularPartRow.LineTotal = 0;
	TabularPartRow.TaxableAmount = 0;
	TabularPartRow.Price = 0;
	TabularPartRow.VAT = 0;
	
	//Price = GeneralFunctions.RetailPrice(CurrentDate(), TabularPartRow.Product, Object.Company);
	Price = DataArray[1];
	
	TabularPartRow.Price = Price / Object.ExchangeRate;
				
	//TabularPartRow.VATCode = CommonUse.GetAttributeValue(TabularPartRow.Product, "SalesVATCode");
	TabularPartRow.VATCode = DataArray[2];
	
	//TabularPartRow.SalesTaxType = US_FL.GetSalesTaxType(TabularPartRow.Product);
	TabularPartRow.SalesTaxType = DataArray[3];

	RecalcTotal();
	
EndProcedure

&AtServer
Function GetDataOnServer(Product, Company)
	
	 ReturnArray = New Array(4);
	 ReturnArray[0] = CommonUse.GetAttributeValue(Product, "Description");
	 ReturnArray[1] = GeneralFunctions.RetailPrice(Object.Date, Product, Company);
	 ReturnArray[2] = CommonUse.GetAttributeValue(Product, "SalesVATCode");
	 ReturnArray[3] = US_FL.GetSalesTaxType(Product);
	 
	 Return ReturnArray;
	 
EndFunction

//&AtClient
// The procedure recalculates a document's sales tax amount
//
&AtServer
Procedure RecalcSalesTax()
	
	If Object.ShipTo.IsEmpty() Then //Object.Company.IsEmpty() Then
		TaxRate = 0;
	Else
		TaxRate = US_FL.GetTaxRate(Object.ShipTo); // TaxRate = US_FL.GetTaxRate(Object.Company);
	EndIf;
	
	Object.SalesTax = Object.LineItems.Total("TaxableAmount") * TaxRate/100;
	
EndProcedure

&AtServer
Procedure RecalcSalesTaxAndTotal()
	
	// sales tax
	
	If Object.ShipTo.IsEmpty() Then //Object.Company.IsEmpty() Then
		TaxRate = 0;
	Else
		TaxRate = US_FL.GetTaxRate(Object.ShipTo); // US_FL.GetTaxRate(Object.Company);
	EndIf;
	
	Object.SalesTax = Object.LineItems.Total("TaxableAmount") * TaxRate/100;
	
	// total
	
	If Object.PriceIncludesVAT Then
		Object.DocumentTotal = Object.LineItems.Total("LineTotal") + Object.SalesTax;
		Object.DocumentTotalRC = (Object.LineItems.Total("LineTotal") + Object.SalesTax) * Object.ExchangeRate;		
	Else
		Object.DocumentTotal = Object.LineItems.Total("LineTotal") + Object.LineItems.Total("VAT") + Object.SalesTax;
		Object.DocumentTotalRC = (Object.LineItems.Total("LineTotal") + Object.LineItems.Total("VAT") + Object.SalesTax) * Object.ExchangeRate;
	EndIf;	
	Object.VATTotal = Object.LineItems.Total("VAT") * Object.ExchangeRate;

	
EndProcedure

//&AtClient
// The procedure recalculates the document's total.
// DocumentTotal - document's currency in FCY (foreign currency).
// DocumentTotalRC - company's reporting currency.
//
&AtServer
Procedure RecalcTotal()
	
	If Object.PriceIncludesVAT Then
		Object.DocumentTotal = Object.LineItems.Total("LineTotal") + Object.SalesTax;
		Object.DocumentTotalRC = (Object.LineItems.Total("LineTotal") + Object.SalesTax) * Object.ExchangeRate;		
	Else
		Object.DocumentTotal = Object.LineItems.Total("LineTotal") + Object.LineItems.Total("VAT") + Object.SalesTax;
		Object.DocumentTotalRC = (Object.LineItems.Total("LineTotal") + Object.LineItems.Total("VAT") + Object.SalesTax) * Object.ExchangeRate;
	EndIf;	
	Object.VATTotal = Object.LineItems.Total("VAT") * Object.ExchangeRate;
	
EndProcedure

&AtClient
// The procedure recalculates a taxable amount for a line item.
// 
Procedure RecalcTaxableAmount()
	
	TabularPartRow = Items.LineItems.CurrentData;
	
	If TabularPartRow.SalesTaxType = GeneralFunctionsReusable.US_FL_Taxable() Then
		TabularPartRow.TaxableAmount = TabularPartRow.LineTotal;
	Else
		TabularPartRow.TaxableAmount = 0;
	EndIf;
	
EndProcedure

&AtClient
// CustomerOnChange UI event handler.
// Selects default currency for the customer, determines an exchange rate, and
// recalculates the document's sales tax and total amounts.
// 
Procedure CompanyOnChange(Item)
	//Object.CompanyCode = CommonUse.GetAttributeValue(Object.Company, "Code");
	//Object.Currency = CommonUse.GetAttributeValue(Object.Company, "DefaultCurrency");
	//Object.ShipTo = GeneralFunctions.GetShipToAddress(Object.Company);
	//Object.ARAccount = CommonUse.GetAttributeValue(Object.Currency, "DefaultARAccount");
	//Object.ExchangeRate = GeneralFunctions.GetExchangeRate(Object.Date, Object.Currency);
	//Object.Terms = CommonUse.GetAttributeValue(Object.Company, "Terms"); 
	//Items.ExchangeRate.Title = GeneralFunctionsReusable.DefaultCurrencySymbol() + "/1" + CommonUse.GetAttributeValue(Object.Currency, "Symbol");
	//Items.FCYCurrency.Title = CommonUse.GetAttributeValue(Object.Currency, "Symbol");
	//DuePeriod = CommonUse.GetAttributeValue(Object.Terms, "Days");
	//Object.DueDate = Object.Date + ?(DuePeriod <> Undefined, DuePeriod, 14) * 60*60*24;
	
	CompanyOnChangeServer();
	
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
		//SelectOrdersForm = GetForm("Document.SalesOrder.ChoiceForm", FormParameters, Item);
		//SelectedOrders   = SelectOrdersForm.DoModal();
		
		//KZUZIK
		NotifyDescription = New NotifyDescription("OrderSelection", ThisForm);
		OpenForm("Document.SalesOrder.ChoiceForm", FormParameters, Item,,,,NotifyDescription) 
		
		
		// Execute orders filling
		//GOLYA
		//FillDocumentWithSelectedOrders(SelectedOrders);
		
	EndIf;
		
EndProcedure

&AtServer
Procedure CompanyOnChangeServer()
	Object.CompanyCode = CommonUse.GetAttributeValue(Object.Company, "Code");
	Object.Currency = CommonUse.GetAttributeValue(Object.Company, "DefaultCurrency");
	Object.ShipTo = GeneralFunctions.GetShipToAddress(Object.Company);
	Object.EmailTo = object.ShipTo.Email;
	Object.ARAccount = CommonUse.GetAttributeValue(Object.Currency, "DefaultARAccount");
	Object.ExchangeRate = GeneralFunctions.GetExchangeRate(Object.Date, Object.Currency);
	Object.Terms = CommonUse.GetAttributeValue(Object.Company, "Terms"); 
	Items.ExchangeRate.Title = GeneralFunctionsReusable.DefaultCurrencySymbol() + "/1" + CommonUse.GetAttributeValue(Object.Currency, "Symbol");
	Items.FCYCurrency.Title = CommonUse.GetAttributeValue(Object.Currency, "Symbol");
	DuePeriod = CommonUse.GetAttributeValue(Object.Terms, "Days");
	Object.DueDate = Object.Date + ?(DuePeriod <> Undefined, DuePeriod, 14) * 60*60*24;
	RecalcSalesTax();
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
// PriceOnChange UI event handler.
// Calculates line total by multiplying a price by a quantity in either the selected
// unit of measure (U/M) or in the base U/M, and recalculates the line's taxable amount and total.
// 
Procedure LineItemsPriceOnChange(Item)
	
	TabularPartRow = Items.LineItems.CurrentData;
	
	TabularPartRow.LineTotal = TabularPartRow.Quantity * TabularPartRow.Price;
	
	If GeneralFunctionsReusable.FunctionalOptionValue("VATFinLocalization") Then
		TabularPartRow.VAT = VAT_FL.VATLine(TabularPartRow.LineTotal, TabularPartRow.VATCode, "Sales", Object.PriceIncludesVAT);
	Else	
		TabularPartRow.VAT = 0;
	EndIf;
	
	RecalcTaxableAmount();
	//RecalcSalesTax();
	//RecalcTotal();
	RecalcSalesTaxAndTotal();

EndProcedure

&AtClient
// DateOnChange UI event handler.
// Determines an exchange rate on the new date, and recalculates the document's
// sales tax and total.
//
Procedure DateOnChange(Item)
	
	If GeneralFunctionsReusable.FunctionalOptionValue("MultiCurrency") Then
		Object.ExchangeRate = GeneralFunctions.GetExchangeRate(Object.Date, Object.Currency);
	Else
		Object.ExchangeRate = 1;
	EndIf;
	
	If NOT Object.Terms.IsEmpty() Then
		Object.DueDate = Object.Date + CommonUse.GetAttributeValue(Object.Terms, "Days") * 60*60*24;
	EndIf;
	
	//RecalcSalesTax();
	//RecalcTotal();
	RecalcSalesTaxAndTotal();
	
EndProcedure

&AtClient
// CurrencyOnChange UI event handler.
// Determines an exchange rate for the new currency, and recalculates the document's
// sales tax and total.
//
Procedure CurrencyOnChange(Item)
	
	Object.ExchangeRate = GeneralFunctions.GetExchangeRate(Object.Date, Object.Currency);
	Object.ARAccount = CommonUse.GetAttributeValue(Object.Currency, "DefaultARAccount");
	Items.ExchangeRate.Title = GeneralFunctionsReusable.DefaultCurrencySymbol() + "/1" + CommonUse.GetAttributeValue(Object.Currency, "Symbol");
	Items.FCYCurrency.Title = CommonUse.GetAttributeValue(Object.Currency, "Symbol");
	//RecalcSalesTax();
	//RecalcTotal();
	RecalcSalesTaxAndTotal();
	
EndProcedure

&AtClient
// LineItemsAfterDeleteRow UI event handler.
// 
Procedure LineItemsAfterDeleteRow(Item)
	
	//RecalcSalesTax();
	//RecalcTotal();
	RecalcSalesTaxAndTotal();
	
EndProcedure

&AtClient
// LineItemsSalesTaxTypeOnChange UI event handler.
//
Procedure LineItemsSalesTaxTypeOnChange(Item)
	
	RecalcTaxableAmount();
	//RecalcSalesTax();
	//RecalcTotal();
	RecalcSalesTaxAndTotal();
	
EndProcedure

&AtClient
// TermsOnChange UI event handler.
// Determines number of days in the payment term, and calculates a due date as
// a multiplication of a number of days (e.g. 30 for "Net 30") by the number of seconds
// in a day, since
// the system treats numbers as seconds when adding to a date.
// 
Procedure TermsOnChange(Item)
		
	Object.DueDate = Object.Date + CommonUse.GetAttributeValue(Object.Terms, "Days") * 60*60*24;
	
EndProcedure

&AtClient
// DueDateOnChange UI event handler.
// Clears the selected payment term when a user inputs a custom due date.
//
Procedure DueDateOnChange(Item)
	
	Object.Terms = NULL;
	
EndProcedure

&AtClient
// LineItemsQuantityOnChange UI event handler.
// This procedure is used when the units of measure (U/M) functional option is turned off
// and base quantities are used instead of U/M quantities.
// The procedure recalculates line total, line taxable amount, and a document's sales tax and total.
// 
Procedure LineItemsQuantityOnChange(Item)
	
	TabularPartRow = Items.LineItems.CurrentData;
	TabularPartRow.LineTotal = TabularPartRow.Quantity * TabularPartRow.Price;
	
	
	If GeneralFunctionsReusable.FunctionalOptionValue("VATFinLocalization") Then
		TabularPartRow.VAT = VAT_FL.VATLine(TabularPartRow.LineTotal, TabularPartRow.VATCode, "Sales", Object.PriceIncludesVAT);
	Else	
		TabularPartRow.VAT = 0;
	EndIf;
	
	RecalcTaxableAmount();
	//RecalcSalesTax();
	//RecalcTotal();
	RecalcSalesTaxAndTotal();

EndProcedure

&AtServer
// Procedure fills in default values, used mostly when the corresponding functional
// options are turned off.
// The following defaults are filled in - warehouse location, currency, due date, payment term, and
// due date based on a default payment term.
// 
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Items.LineItemsQuantity.EditFormat = "NFD=" + Constants.QtyPrecision.Get();
	Items.LineItemsQuantity.Format = "NFD=" + Constants.QtyPrecision.Get();

	
	If Object.BegBal = False Then
		Items.DocumentTotalRC.ReadOnly = True;
		Items.DocumentTotal.ReadOnly = True;
	EndIf;
	
	// Cancel opening form if filling on the base was failed
	If Object.Ref.IsEmpty() And Parameters.Basis <> Undefined
	And Object.Company <> Parameters.Basis.Company Then
		// Object is not filled as expected
		Cancel = True;
		Return;
	EndIf;
	
	// Initialization of LineItems_OnCloneRow variable
	LineItems_OnCloneRow = False;
	
	Items.Company.Title = GeneralFunctionsReusable.GetCustomerName();
	
	//Title = NStr("de='Rechnung';en='Sales Invoice '") + Object.Number + " " + Format(Object.Date, "DLF=D");
	
	If Object.Ref.IsEmpty() Then
    	Object.PriceIncludesVAT = GeneralFunctionsReusable.PriceIncludesVAT();
	EndIf;
	
	If NOT GeneralFunctionsReusable.FunctionalOptionValue("USFinLocalization") Then
		Items.SalesTaxGroup.Visible = False;
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
		Object.ARAccount = Object.Currency.DefaultARAccount;
		Object.ExchangeRate = 1;	
	Else
	EndIf; 
	
	Items.ExchangeRate.Title = GeneralFunctionsReusable.DefaultCurrencySymbol() + "/1" + Object.Currency.Symbol;
	Items.VATCurrency.Title = GeneralFunctionsReusable.DefaultCurrencySymbol();
	Items.RCCurrency.Title = GeneralFunctionsReusable.DefaultCurrencySymbol();
	Items.SalesTaxCurrency.Title = GeneralFunctionsReusable.DefaultCurrencySymbol();
	Items.FCYCurrency.Title = CommonUse.GetAttributeValue(Object.Currency, "Symbol");
	
	//If Object.DueDate = Date(1,1,1) Then
		//Object.DueDate = CurrentDate() + GeneralFunctionsReusable.GetDefaultTermDays() * 60*60*24;
	//EndIf;

	//If Object.Terms.IsEmpty() Then
		//Object.Terms = GeneralFunctionsReusable.GetDefaultPaymentTerm();
	//EndIf;
	
EndProcedure

&AtClient
// Calculates a VAT amount for the document line
//
Procedure LineItemsVATCodeOnChange(Item)
	
	TabularPartRow = Items.LineItems.CurrentData;
	TabularPartRow.VAT = VAT_FL.VATLine(TabularPartRow.LineTotal, TabularPartRow.VATCode, "Sales", Object.PriceIncludesVAT);
    RecalcTotal();

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
	         // Message("RUNNING"); Bottom
	If NewRow = true Then
		CurrentData = Item.CurrentData;
		CurrentData.Project = Object.Project;
		NewRow = false;
	Endif;


	// Row previously was cloned from another and became edited
	If LineItems_OnCloneRow Then
		// Clear used flag
		LineItems_OnCloneRow = False;
		
		// Clear Order on duplicate row

        CurrentData = Item.CurrentData;
		CurrentData.Order = Undefined;



	EndIf;
		
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	
	//------------------------------------------------------------------------------
	// 1. Correct the invoice date according to the orders dates.
	
	// Request orders dates.
	QueryText = "
		|SELECT TOP 1
		|	SalesOrder.Date AS Date,
		|	SalesOrder.Ref AS Ref
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

&AtClient
Procedure EmailInvoiceOnChange(Item)
	EmailInvoiceOnChangeAtServer();
EndProcedure

&AtServer
Procedure EmailInvoiceOnChangeAtServer()
	
	//If EmailInvoice = True Then
	//	Items.EmailTo.Visible = True;
	//	Items.Note.Visible = True;
	//	EmailTo = object.ShipTo.Email;
	//	Items.LastEmail.Visible = True;
	//Else
	//	Items.EmailTo.Visible = False;
	//	Items.Note.Visible = False;
	//	Items.LastEmail.Visible = False;
	//Endif;
	
EndProcedure


&AtServer
Procedure SendInvoiceEmail()
	
	//test = Object.PayHTML;
	//test2 = 3;
	If Object.Ref.IsEmpty() Then
		Message("An email cannot be sent until the invoice is posted or written");
	Else
		
	CurObject = object.ref.GetObject();
	////
	if CurObject.PayHTML = "" Then
		
    	SymbolString = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"; //62
    	RandomString20 = "";
    	RNG = New RandomNumberGenerator;	
    	For i = 0 to 19 Do
    		RN = RNG.RandomNumber(1, 62);
    		RandomString20 = RandomString20 + Mid(SymbolString,RN,1);
    	EndDo;
    							 
    	
    	Query = New Query("SELECT
    						 |	Addresses.Email
    						 |FROM
    						 |	Catalog.Addresses AS Addresses
    						 |WHERE
    						 |	Addresses.Owner = &Company
    						 |	AND Addresses.DefaultBilling = True");
    		Query.SetParameter("Company", Object.Company);
    		QueryResult = Query.Execute().Unload();
    	   Recipient = QueryResult[0][0];
 
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
	 	  
		MailProfil.SMTPServerAddress = Constants.MailProfAddress.Get();
		MailProfil.SMTPUseSSL = Constants.MailProfSSL.Get();
	   // MailProfil.SMTPPort = 587; 
	    
	    MailProfil.Timeout = 180; 
	    
		MailProfil.SMTPPassword = Constants.MailProfPass.Get();
	    
		MailProfil.SMTPUser = Constants.MailProfUser.Get();

	 	  
	 	  
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
	 	  
		  
		  FormatHTML2 = StrReplace(FormatHTML,"object.number",object.Number);
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
	   |	SalesInvoice.PriceIncludesVAT,
	   |	SalesInvoice.VATTotal,
	   |	SalesInvoice.LineItems.(
	   |		Product,
	   |		Product.UM AS UM,
	   |		ProductDescription,
	   |		LineItems.Order.RefNum AS PO,
	   |		Quantity,
	   |		VATCode,
	   |		VAT,
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
	   Selection = Query.Execute().Choose();
	   //Selection2 = Query.Execute().Unload();
	 //  Selection2.LineItems.Choose();
	  // Selection3 = Selection2.LineItems;

	  While Selection.Next() Do 
	  
	  SelectionLineItems = Selection.LineItems.Choose();
	   LineTotalSum = 0;
	   While SelectionLineItems.Next() Do
	    	 
	    	 LineTotal = SelectionLineItems.LineTotal;
	    	 LineTotalSum = LineTotalSum + LineTotal;
	    	 
	   EndDo;


	   
	   If Selection.PriceIncludesVAT Then
	 	  DTotal = LineTotalSum + Selection.SalesTax;
	   Else
	    		DTotal = LineTotalSum + Selection.VATTotal;
	   EndIf;

	 	  
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
		  SentEmail = True;
		  
		  
	   Else
		  Message("The recipient email has not been specified");
	   Endif;
		 
	 Endif;
  
 


	
EndProcedure

&AtClient
Procedure SendEmail(Command)
	// Insert handler contents.
	SendInvoiceEmail();
EndProcedure

&AtClient
Procedure OnClose()
	OnCloseAtServer();
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
