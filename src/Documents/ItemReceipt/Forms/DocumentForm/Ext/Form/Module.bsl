
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
		Object.DocumentTotal = Object.LineItems.Total("LineTotal");
		Object.DocumentTotalRC = (Object.LineItems.Total("LineTotal")) * Object.ExchangeRate;
	Else
		Object.DocumentTotal = Object.LineItems.Total("LineTotal") + Object.LineItems.Total("VAT");
		Object.DocumentTotalRC = (Object.LineItems.Total("LineTotal") + Object.LineItems.Total("VAT")) * Object.ExchangeRate;
	EndIf;
	Object.VATTotal = Object.LineItems.Total("VAT") * Object.ExchangeRate;
	
EndProcedure

&AtClient
// VendorOnChange UI event handler.
// Selects default currency for the vendor, determines an exchange rate, and
// recalculates the document's total amount.
//
Procedure CompanyOnChange(Item)
	
	Object.CompanyCode = CommonUse.GetAttributeValue(Object.Company, "Code");
	Object.Currency = CommonUse.GetAttributeValue(Object.Company, "DefaultCurrency");
	Object.ExchangeRate = GeneralFunctions.GetExchangeRate(Object.Date, Object.Currency);
	
	// Open list of non-closed sales orders.
	If (Not Object.Company.IsEmpty()) And (HasNonClosedOrders(Object.Company)) Then
		
		// Define form parameters.
		FormParameters = New Structure();
		FormParameters.Insert("ChoiceMode", True);
		FormParameters.Insert("MultipleChoice", True);
		
		// Define list filter.
		FltrParameters = New Structure();
		FltrParameters.Insert("Company", Object.Company); 
		FltrParameters.Insert("OrderStatus", GetNonClosedOrderStatuses());
		FormParameters.Insert("Filter", FltrParameters);
		
		// Open orders selection form.
		NotifyDescription = New NotifyDescription("OrderSelection", ThisForm);
		OpenForm("Document.PurchaseOrder.ChoiceForm", FormParameters, Item,,,, NotifyDescription);
	EndIf;
	
	// Recalc totals
	RecalcTotal();
	
EndProcedure

&AtClient
// Processing of selected orders.
Procedure OrderSelection(Result, Parameters) Export
	
	// Process selection result.
	If Not Result = Undefined Then
		
		// Do fill document from selected orders.
		FillDocumentWithSelectedOrders(Result);
		
	EndIf;
	
EndProcedure

&AtClient
// DateOnChange UI event handler.
// Determines an exchange rate on the new date, and recalculates the document's total.
//
Procedure DateOnChange(Item)
	
	Object.ExchangeRate = GeneralFunctions.GetExchangeRate(Object.Date, Object.Currency);
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
	
	// Initialization of new row flag.
	IsNewRow = False;
	
	Items.Company.Title = GeneralFunctionsReusable.GetVendorName();
	
	//Title = "Item receipt " + Object.Number + " " + Format(Object.Date, "DLF=D");
	
	Items.LineItemsQuantity.EditFormat = "NFD=" + Constants.QtyPrecision.Get();
	Items.LineItemsQuantity.Format = "NFD=" + Constants.QtyPrecision.Get();
	
	If Object.Ref.IsEmpty() Then
		Object.PriceIncludesVAT = GeneralFunctionsReusable.PriceIncludesVAT();
	EndIf;
	
	If Object.Location.IsEmpty() Then
		Object.Location = Catalogs.Locations.MainWarehouse;
	EndIf;
	
	If Object.Currency.IsEmpty() Then
		Object.Currency = Constants.DefaultCurrency.Get();
		Object.ExchangeRate = 1;
	EndIf;
	
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
Procedure LineItemsBeforeAddRow(Item, Cancel, Clone, Parent, Folder)
	
	// Set new row flag.
	If Not Cancel Then
		IsNewRow = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure LineItemsOnChange(Item)
	
	// Row was just added and became edited.
	If IsNewRow Then
		
		// Clear used flag.
		IsNewRow = False;
		
		// Get current row.
		CurrentData = Item.CurrentData;
		
		// Clear order on duplicate row.
		If ValueIsFilled(CurrentData.Order) Then
			CurrentData.Order      = Undefined;
			CurrentData.OrderPrice = 0;
		EndIf;
		
		// Assign default project if not assigned.
		If Not ValueIsFilled(CurrentData.Project) Then
			CurrentData.Project = Object.Project;
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	//Period closing
	If DocumentPosting.DocumentPeriodIsClosed(CurrentObject.Ref, CurrentObject.Date) Then
		PermitWrite = DocumentPosting.DocumentWritePermitted(WriteParameters);
		CurrentObject.AdditionalProperties.Insert("PermitWrite", PermitWrite);	
	EndIf;
	
	//------------------------------------------------------------------------------
	// 1. Correct the receipt date according to the orders dates.
	
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
	
	// Compare letest order date with current receipt date.
	If Not QueryResult.IsEmpty() Then
		
		// Check latest order date.
		LatestOrder  = QueryResult.Unload()[0];
		If (Not LatestOrder.Date = Null) And (LatestOrder.Date >= CurrentObject.Date) Then
			
			// Receipt writing before the order.
			If BegOfDay(LatestOrder.Date) = BegOfDay(CurrentObject.Date) Then
				// The date is the same - simply correct the document time (it will not be shown to the user).
				CurrentObject.Date = LatestOrder.Date + 1;
				
			Else
				// The receipt writing too early.
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
Procedure BeforeWrite(Cancel, WriteParameters)
	
	//Closing period
	If DocumentPosting.DocumentPeriodIsClosed(Object.Ref, Object.Date) Then
		Cancel = Not DocumentPosting.DocumentWritePermitted(WriteParameters);
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

