
&AtServer
// Prefills default accounts, VAT codes, determines accounts descriptions, and sets field visibility
//
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	//------------------------------------------------------------------------------
	// 1. Form attributes initialization.
	
	// Set LineItems editing flag.
	IsNewRow     = False;
	
	//------------------------------------------------------------------------------
	// 2. Calculate values of form object attributes.
	
	//------------------------------------------------------------------------------
	// 3. Set custom controls presentation.
	
	// Update quantities presentation.
	QuantityPrecision = GeneralFunctionsReusable.DefaultQuantityPrecision();
	QuantityFormat    = GeneralFunctionsReusable.DefaultQuantityFormat();
	Items.LineItemsQuantity.EditFormat      = QuantityFormat;
	Items.LineItemsQuantity.Format          = QuantityFormat;
	Items.LineItemsWasteQtyUnits.EditFormat = QuantityFormat;
	Items.LineItemsWasteQtyUnits.Format     = QuantityFormat;
	
	// Update prices presentation in LineItems.
	PriceFormat = GeneralFunctionsReusable.DefaultPriceFormat();
	Items.LineItemsPrice.EditFormat  = PriceFormat;
	Items.LineItemsPrice.Format      = PriceFormat;
	
	// Show/hide assembly part.
	Items.Assembly.Visible = Object.Assembly;
	
	// Update prices presentation.
	UpdatePricesPresentation();

	// -> CODE REVIEW
	If Constants.SalesTaxCharging.Get() = False Then
		Items.Taxable.Visible = False;
		Taxable = False;
	EndIf;
	
	If Object.Ref <> Catalogs.Products.EmptyRef() Then
		Items.Type.ReadOnly = True;
		Items.CostingMethod.ReadOnly = True;
	Else	
		Object.UnitSet = Constants.DefaultUoMSet.Get();
	EndIf;
	
	If GeneralFunctionsReusable.DisplayAPICodesSetting() = False Then
		Items.api_code.Visible = False;
	EndIf;
	
	If NOT Object.Ref.IsEmpty() Then
		api_code = String(Object.Ref.UUID());
	EndIf;

	
	//test = Object.Ref.UUID();
	//test = Catalogs.Products.GetRef(New UUID("3b942486-4317-11e3-bebf-001c42734aa6"));
	
	// custom fields
	
	CF1Type = Constants.CF1Type.Get();
	CF2Type = Constants.CF2Type.Get();
	CF3Type = Constants.CF3Type.Get();
	CF4Type = Constants.CF4Type.Get();
	CF5Type = Constants.CF5Type.Get();
	
	If CF1Type = "None" Then
		Items.CF1Num.Visible = False;
		Items.CF1String.Visible = False;
	ElsIf CF1Type = "Number" Then
		Items.CF1Num.Visible = True;
		Items.CF1String.Visible = False;
		Items.CF1Num.Title = Constants.CF1Name.Get();
	ElsIf CF1Type = "String" Then
	    Items.CF1Num.Visible = False;
		Items.CF1String.Visible = True;
		Items.CF1String.Title = Constants.CF1Name.Get();
	ElsIf CF1Type = "" Then
		Items.CF1Num.Visible = False;
		Items.CF1String.Visible = False;
	EndIf;
	
	If CF2Type = "None" Then
		Items.CF2Num.Visible = False;
		Items.CF2String.Visible = False;
	ElsIf CF2Type = "Number" Then
		Items.CF2Num.Visible = True;
		Items.CF2String.Visible = False;
		Items.CF2Num.Title = Constants.CF2Name.Get();
	ElsIf CF2Type = "String" Then
	    Items.CF2Num.Visible = False;
		Items.CF2String.Visible = True;
		Items.CF2String.Title = Constants.CF2Name.Get();
	ElsIf CF2Type = "" Then
		Items.CF2Num.Visible = False;
		Items.CF2String.Visible = False;
	EndIf;
	
	If CF3Type = "None" Then
		Items.CF3Num.Visible = False;
		Items.CF3String.Visible = False;
	ElsIf CF3Type = "Number" Then
		Items.CF3Num.Visible = True;
		Items.CF3String.Visible = False;
		Items.CF3Num.Title = Constants.CF3Name.Get();
	ElsIf CF3Type = "String" Then
	    Items.CF3Num.Visible = False;
		Items.CF3String.Visible = True;
		Items.CF3String.Title = Constants.CF3Name.Get();
	ElsIf CF3Type = "" Then
		Items.CF3Num.Visible = False;
		Items.CF3String.Visible = False;
	EndIf;
	
	If CF4Type = "None" Then
		Items.CF4Num.Visible = False;
		Items.CF4String.Visible = False;
	ElsIf CF4Type = "Number" Then
		Items.CF4Num.Visible = True;
		Items.CF4String.Visible = False;
		Items.CF4Num.Title = Constants.CF4Name.Get();
	ElsIf CF4Type = "String" Then
	    Items.CF4Num.Visible = False;
		Items.CF4String.Visible = True;
		Items.CF4String.Title = Constants.CF4Name.Get();
	ElsIf CF4Type = "" Then
		Items.CF4Num.Visible = False;
		Items.CF4String.Visible = False;
	EndIf;
	
	If CF5Type = "None" Then
		Items.CF5Num.Visible = False;
		Items.CF5String.Visible = False;
	ElsIf CF5Type = "Number" Then
		Items.CF5Num.Visible = True;
		Items.CF5String.Visible = False;
		Items.CF5Num.Title = Constants.CF5Name.Get();
	ElsIf CF5Type = "String" Then
	    Items.CF5Num.Visible = False;
		Items.CF5String.Visible = True;
		Items.CF5String.Title = Constants.CF5Name.Get();
	ElsIf CF5Type = "" Then
		Items.CF5Num.Visible = False;
		Items.CF5String.Visible = False;
	EndIf;
	
	// end custom fields
	
	If Object.Ref <> Catalogs.Products.EmptyRef() Then
		Price = GeneralFunctions.RetailPrice(CurrentDate(), Object.Ref, Catalogs.Companies.EmptyRef());
	Endif;
	
	If Object.Ref = Catalogs.Products.EmptyRef() Then		
		Items.InventoryOrExpenseAccount.Title = "Account";
		Items.COGSAccount.ReadOnly = True;
	Else
		If Object.Type = Enums.InventoryTypes.Inventory Then
			Items.InventoryOrExpenseAccount.Title = "Inventory account";
		Else
			Items.InventoryOrExpenseAccount.Title = "Expense account";
			items.COGSAccount.ReadOnly = True;
		EndIf;
	EndIf;
		
	
	//If Object.Ref <> Catalogs.Products.EmptyRef() Then
	//	Query = New Query("SELECT
	//					  |	PriceListSliceLast.Price
	//					  |FROM
	//					  |	InformationRegister.PriceList.SliceLast AS PriceListSliceLast
	//					  |WHERE
	//					  |	PriceListSliceLast.Product = &Ref");
	//	Query.SetParameter("Ref", Object.Ref);
	//	Selection = Query.Execute();
	//	
	//	If Selection.IsEmpty() Then
	//	Else
	//		Dataset = Selection.Unload();
	//		Price = Dataset[0][0];
	//	EndIf;

	//	
	//EndIf;
		
	If Object.Type <> Enums.InventoryTypes.Inventory Then
		Items.CostingMethod.ReadOnly = True;
	EndIf;
	
	If Object.Type <> Enums.InventoryTypes.Inventory AND (NOT Object.Ref.IsEmpty()) Then
		Items.CostingMethod.Visible = False;	
	EndIf;
	
	If Object.IncomeAccount.IsEmpty() AND Object.Ref.IsEmpty() Then
		IncomeAcct = Constants.IncomeAccount.Get();
		Object.IncomeAccount = IncomeAcct;
		//Items.IncomeAcctLabel.Title = IncomeAcct.Description;
	ElsIf NOT Object.Ref.IsEmpty() Then
		//Items.IncomeAcctLabel.Title = Object.IncomeAccount.Description;
	EndIf;
		
	If NOT Object.InventoryOrExpenseAccount.IsEmpty() Then
		//Items.InventoryAcctLabel.Title = Object.InventoryOrExpenseAccount.Description;
	EndIf;
	
	If Object.Type <> Enums.InventoryTypes.Inventory Then
		//Items.COGSAccount.ReadOnly = True;
	EndIf;
		
	// Display indicators
	If ValueIsFilled(Object.Ref) Then
		
		// Fill item cost values
		FillLastAverageAccountingCost();
		
		// Fill item quantities
		FillItemQuantity_OnPO_OnSO_OnHand_AvailableToPromise();
		
		// Update visibility
		Items.CostAndQuantity.Visible = True;
		IsInventoryType = (Object.Type = Enums.InventoryTypes.Inventory);
		Items.CostAndQuantity.ChildItems.Left.ChildItems.AverageCost.Visible = IsInventoryType;
		Items.CostAndQuantity.ChildItems.Left.ChildItems.AccountingCost.Visible = IsInventoryType;
		Items.CostAndQuantity.ChildItems.Left.ChildItems.InventorySiteInfo.Visible = IsInventoryType;
		Items.CostAndQuantity.ChildItems.Right.ChildItems.QtyOnHand.Visible = IsInventoryType;
		Items.CostAndQuantity.ChildItems.Right.ChildItems.QtyAvailableToPromise.Visible = IsInventoryType;
		//Items.CostAndQuantity.ChildItems.Right.ChildItems.InventorySiteInfo.Visible = IsInventoryType;
	Else
		// New item: hide indicators
		Items.CostAndQuantity.Visible = False;
	EndIf;
	
	QuantityFormat = GeneralFunctionsReusable.DefaultQuantityFormat();
	Items.QtyOnPO.Format                   = QuantityFormat; 
	Items.QtyOnPO.EditFormat               = QuantityFormat; 
	Items.QtyOnSO.Format                   = QuantityFormat; 
	Items.QtyOnSO.EditFormat               = QuantityFormat; 
	Items.QtyOnHand.Format                 = QuantityFormat; 
	Items.QtyOnHand.EditFormat             = QuantityFormat; 
	Items.QtyAvailableToPromise.Format     = QuantityFormat; 
	Items.QtyAvailableToPromise.EditFormat = QuantityFormat; 
	
	SetBaseUnit();

EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// Add new object flag.
	WriteParameters.Insert("IsNew", CurrentObject.IsNew());
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	If Object.Ref <> Catalogs.Products.EmptyRef() Then
		  Items.Type.ReadOnly = True;
		  Items.CostingMethod.ReadOnly = True;
	EndIf;
	
	If  (Object.Type = Enums.InventoryTypes.Inventory) Then
		// Fill item cost values
		FillLastAverageAccountingCost();
	EndIf;
	
	// Fill item quantities
	FillItemQuantity_OnPO_OnSO_OnHand_AvailableToPromise();
	
	// Update visibility
	Items.CostAndQuantity.Visible = True;
	IsInventoryType = (Object.Type = Enums.InventoryTypes.Inventory);
	Items.CostAndQuantity.ChildItems.Left.Visible = IsInventoryType;
	Items.CostAndQuantity.ChildItems.Right.ChildItems.QtyOnHand.Visible = IsInventoryType;
	Items.CostAndQuantity.ChildItems.Right.ChildItems.QtyAvailableToPromise.Visible = IsInventoryType;
	//Items.CostAndQuantity.ChildItems.Right.ChildItems.InventorySiteInfo.Visible = IsInventoryType;
	
	// Update prices presentation.
	UpdatePricesPresentation();
	
	//AddPriceList();
	
	// zapier webhooks
	
	Query = New Query("SELECT
	                  |	ZapierWebhooks.Description
	                  |FROM
	                  |	Catalog.ZapierWebhooks AS ZapierWebhooks
	                  |WHERE
	                  |	ZapierWebhooks.Code = ""new_item_webhook""");
					  
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then		
	Else
		
		WebhookMap = New Map(); 
		WebhookMap.Insert("apisecretkey",Constants.APISecretKey.Get());
		WebhookMap.Insert("resource","items");
		If Object.NewObject = True Then
			WebhookMap.Insert("action","create");
		Else
			WebhookMap.Insert("action","update");
		EndIf;
		//WebhookMap.Insert("api_code",Object.Ref.api_code);
		WebhookMap.Insert("item_code",Object.Ref.Code);
		WebhookMap.Insert("item_description",Object.Ref.Description);
		
		Selection = QueryResult.Select();
		While Selection.Next() Do
			
			WebhookParams = New Array();
			WebhookParams.Add(Selection.Description);
			WebhookParams.Add(WebhookMap);
			LongActions.ExecuteInBackground("GeneralFunctions.SendWebhook", WebhookParams);
			
		EndDo;						
	EndIf;
	
	//  create item in zoho
	If Constants.zoho_auth_token.Get() <> "" Then
		If Object.NewObject = True Then
			ThisAction = "create";
		Else
			ThisAction = "update";
		EndIf;
		zoho_Functions.zoho_ThisItem(ThisAction,Object.Ref);
	EndIf;
	
EndProcedure

&AtServer
Procedure FillLastAverageAccountingCost()
	
	// Default values for new item (or item without lots - no goods recepts / purchase invoices occured)
	LastCost = 0;
	PriceMatrix = 0;
	AverageCost = 0;
	AccountingCost = 0;
	Margin = 0;
		
	// Check object is new
	If ValueIsFilled(Object.Ref) Then
	
		// Define query for all types of cost
		QTItemLastCost = "
			|// Last item cost from information register ItemLastCosts
			|SELECT
			|	ItemLastCostsSliceLast.Cost AS Cost
			|INTO
			|	LastCost
			|FROM
			|	InformationRegister.ItemLastCosts.SliceLast(, Product = &Ref) AS ItemLastCostsSliceLast
			|
			|UNION ALL
			|
			|SELECT
			|	0;";
		
		QTItemPriceMatrix = "
			|// Price matrix item cost from information register PriceList
			|SELECT
		    |	PriceListSliceLast.Price AS Cost
		    |INTO PriceMatrix
		    |FROM
		    |	InformationRegister.PriceList.SliceLast(
		    |			,
		    |			Product = &Ref
		    |				AND PriceLevel = VALUE(Catalog.PriceLevels.EmptyRef)
		    |				AND ProductCategory = VALUE(Catalog.ProductCategories.EmptyRef)) AS PriceListSliceLast
			|
			|UNION ALL
			|
			|SELECT
			|	0;";
			
		QTItemAverageCost = "
			|// Average cost, based on all availble stock
			|SELECT
			|	CASE
			|		WHEN InventoryJournalBalance.QuantityBalance <= 0
			|			THEN 0
			|		ELSE CASE
			|				WHEN InventoryJournalBalance.Product.PricePrecision = 3
			|					THEN CAST(InventoryJournalBalance.AmountBalance / InventoryJournalBalance.QuantityBalance AS NUMBER(17, 3))
			|				WHEN InventoryJournalBalance.Product.PricePrecision = 4
			|					THEN CAST(InventoryJournalBalance.AmountBalance / InventoryJournalBalance.QuantityBalance AS NUMBER(17, 4))
			|				ELSE CAST(InventoryJournalBalance.AmountBalance / InventoryJournalBalance.QuantityBalance AS NUMBER(17, 2))
			|			END
			|	END AS Cost
			|INTO
			|	AverageCost
			|FROM
			|	AccumulationRegister.InventoryJournal.Balance(&Boundary, Product = &Ref) AS InventoryJournalBalance
			|
			|UNION ALL
			|
			|SELECT
			|	0;";
		
		QTItemAccountingFirstLastCost = "
			|// Current accounting cost => First / Last lot item cost
			|SELECT TOP 1
			|	CASE
			|		WHEN InventoryJournalBalance.QuantityBalance <= 0
			|			THEN 0
			|		ELSE CASE
			|				WHEN InventoryJournalBalance.Product.PricePrecision = 3
			|					THEN CAST(InventoryJournalBalance.AmountBalance / InventoryJournalBalance.QuantityBalance AS NUMBER(17, 3))
			|				WHEN InventoryJournalBalance.Product.PricePrecision = 4
			|					THEN CAST(InventoryJournalBalance.AmountBalance / InventoryJournalBalance.QuantityBalance AS NUMBER(17, 4))
			|				ELSE CAST(InventoryJournalBalance.AmountBalance / InventoryJournalBalance.QuantityBalance AS NUMBER(17, 2))
			|			END
			|	END AS Cost,
			|	InventoryJournalBalance.Layer AS Layer
			|INTO
			|	AccountingCost
			|FROM
			|	AccumulationRegister.InventoryJournal.Balance(&Boundary, Product = &Ref) AS InventoryJournalBalance
			|ORDER BY
			|	InventoryJournalBalance.Layer.PointInTime %1;";
		
		Query = New Query(
			// Last item cost from information register ItemLastCosts
			QTItemLastCost +    // INTO LastCost.Cost
			// Price matrix item cost from information register PriceList
			QTItemPriceMatrix + // INTO PriceMatrix.Cost
			// Average cost, based on all availble stock
			QTItemAverageCost + // INTO AverageCost.Cost
			// Current accounting cost => First / Last lot item cost for FIFO/LIFO, NONE for Average
			//?(Object.CostingMethod = Enums.InventoryCosting.FIFO OR Object.CostingMethod = Enums.InventoryCosting.LIFO,
				//StringFunctionsClientServer.SubstituteParametersInString(QTItemAccountingFirstLastCost, ?(Object.CostingMethod = Enums.InventoryCosting.FIFO, "Asc", "Desc")), // FIFO = ORDER BY Layer Asc (TOP 1 Old); LIFO = ORDER BY Layer Desc (TOP 1 New);
			?(Object.CostingMethod = Enums.InventoryCosting.FIFO,
				StringFunctionsClientServer.SubstituteParametersInString(QTItemAccountingFirstLastCost, "Asc"), // FIFO = ORDER BY Layer Asc (TOP 1 Old); LIFO = ORDER BY Layer Desc (TOP 1 New);
	
				"") +			// INTO AccountingCost.Cost
			"
			|SELECT
			|	SUM(LastCost.Cost) AS Cost
			|
			|UNION ALL
			|
			|SELECT
			|	SUM(PriceMatrix.Cost)
			|
			|UNION ALL
			|
			|SELECT
			|	SUM(AverageCost.Cost)" +
			//?(Object.CostingMethod = Enums.InventoryCosting.FIFO OR Object.CostingMethod = Enums.InventoryCosting.LIFO, "
			?(Object.CostingMethod = Enums.InventoryCosting.FIFO, "
			|
			|UNION ALL
			|SELECT
			|	ISNULL(AccountingCost.Cost, 0)",""));
			
		Query.SetParameter("Boundary", New Boundary(EndOfDay(CurrentSessionDate()), BoundaryType.Including));
		Query.SetParameter("Ref", Object.Ref);
		
		// Execute query and read costs
		Selection = Query.Execute().Select();
		// Last cost
		If Selection.Next() Then LastCost = Selection.Cost;	Else LastCost = 0; EndIf;
		// Price matrix
		If Selection.Next() Then PriceMatrix = Selection.Cost;	Else PriceMatrix = 0; EndIf;
		// Average cost
		If Selection.Next() Then AverageCost = Selection.Cost;	Else AverageCost = 0; EndIf;
		// Accounting cost
		//If (Object.CostingMethod = Enums.InventoryCosting.FIFO OR Object.CostingMethod = Enums.InventoryCosting.LIFO) And Selection.Next() Then
		If Object.CostingMethod = Enums.InventoryCosting.FIFO And Selection.Next() Then
			AccountingCost = Selection.Cost;
		Else
			AccountingCost = AverageCost;
		EndIf;
		
		//--//
		Margin = ?(LastCost = 0, 0, (PriceMatrix / LastCost) * 100); 
		//--//
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillItemQuantity_OnPO_OnSO_OnHand_AvailableToPromise()
	
	// Default values for new item (or item without lots - no goods recepts / purchase invoices occured)
	QtyOnPO = 0;
	QtyOnSO = 0;
	QtyOnHand = 0;
	QtyAvailableToPromise = 0;
	
	// Check object is new
	If ValueIsFilled(Object.Ref) Then
		
		// Create new query
		Query = New Query;
		Query.TempTablesManager = New TempTablesManager;
		Query.SetParameter("Ref",  Object.Ref);
		Query.SetParameter("Type", Object.Type);
		
		// Empty query text and tables
		QueryText   = "";
		QueryTables = -1;
		
		// Request data from database
		QueryText = QueryText +
		"SELECT
		// ------------------------------------------------------
		// QtyOnPO = OrdersDispatched.Quantity - OrdersDispatched.Received(Invoiced) > 0 
		|	OrdersDispatchedBalance.Company   AS Company,
		|	OrdersDispatchedBalance.Order     AS Order,
		|	OrdersDispatchedBalance.Product   AS Product,
		|   OrdersDispatchedBalance.Unit      AS Unit,
		|	CASE WHEN &Type = VALUE(Enum.InventoryTypes.Inventory)
		|             THEN CASE WHEN OrdersDispatchedBalance.QuantityBalance - OrdersDispatchedBalance.ReceivedBalance > 0
		|	                    THEN (OrdersDispatchedBalance.QuantityBalance - OrdersDispatchedBalance.ReceivedBalance) * OrdersDispatchedBalance.Unit.Factor 
		|	                    ELSE 0 END
		|        WHEN &Type = VALUE(Enum.InventoryTypes.NonInventory)
		|             THEN CASE WHEN OrdersDispatchedBalance.QuantityBalance - OrdersDispatchedBalance.InvoicedBalance > 0
		|	                    THEN (OrdersDispatchedBalance.QuantityBalance - OrdersDispatchedBalance.InvoicedBalance) * OrdersDispatchedBalance.Unit.Factor 
		|	                    ELSE 0 END
		|        ELSE 0 END                   AS QtyOnPO,
		|	0                                 AS QtyOnSO,
		|	0                                 AS QtyOnHand
		|INTO
		|	Table_OrdersDispatched_OrdersRegistered_InventoryJournal
		|FROM
		|	AccumulationRegister.OrdersDispatched.Balance AS OrdersDispatchedBalance
		|	LEFT JOIN InformationRegister.OrdersStatuses.SliceLast AS OrdersStatusesSliceLast
		|		ON   OrdersDispatchedBalance.Order = OrdersStatusesSliceLast.Order
		|		AND (OrdersStatusesSliceLast.Status = VALUE(Enum.OrderStatuses.Open)
		|		  OR OrdersStatusesSliceLast.Status = VALUE(Enum.OrderStatuses.Backordered))
		|WHERE
		|	OrdersDispatchedBalance.Product = &Ref
		|
		|UNION ALL
		|
		|SELECT
		// ------------------------------------------------------
		// QtyOnSO = OrdersRegistered.Quantity - OrdersRegistered.Shipped(Invoiced) > 0 
		|	OrdersRegisteredBalance.Company,
		|	OrdersRegisteredBalance.Order,
		|	OrdersRegisteredBalance.Product,
		|   OrdersRegisteredBalance.Unit,
		|	0,
		|	CASE WHEN &Type = VALUE(Enum.InventoryTypes.Inventory)
		|             THEN CASE WHEN OrdersRegisteredBalance.QuantityBalance - OrdersRegisteredBalance.ShippedBalance > 0
		|	                    THEN (OrdersRegisteredBalance.QuantityBalance - OrdersRegisteredBalance.ShippedBalance) * OrdersRegisteredBalance.Unit.Factor 
		|	                    ELSE 0 END
		|        WHEN &Type = VALUE(Enum.InventoryTypes.NonInventory)
		|             THEN CASE WHEN OrdersRegisteredBalance.QuantityBalance - OrdersRegisteredBalance.InvoicedBalance > 0
		|	                    THEN (OrdersRegisteredBalance.QuantityBalance - OrdersRegisteredBalance.InvoicedBalance) * OrdersRegisteredBalance.Unit.Factor 
		|	                    ELSE 0 END
		|        ELSE 0 END,
		|	0
		|FROM
		|	AccumulationRegister.OrdersRegistered.Balance AS OrdersRegisteredBalance
		|	LEFT JOIN InformationRegister.OrdersStatuses.SliceLast AS OrdersStatusesSliceLast
		|		ON   OrdersRegisteredBalance.Order = OrdersStatusesSliceLast.Order
		|		AND (OrdersStatusesSliceLast.Status = VALUE(Enum.OrderStatuses.Open)
		|		  OR OrdersStatusesSliceLast.Status = VALUE(Enum.OrderStatuses.Backordered))
		|WHERE
		|	OrdersRegisteredBalance.Product = &Ref
		|
		|UNION ALL
		|
		|SELECT
		// ------------------------------------------------------
		// QtyOnHand = Inventory.Quantity(0)
		|	NULL,
		|	NULL,
		|	InventoryJournalBalance.Product,
		|	NULL,
		|	0,
		|	0,
		|	CASE WHEN &Type = VALUE(Enum.InventoryTypes.Inventory)
		|	          THEN InventoryJournalBalance.QuantityBalance
		|        WHEN &Type = VALUE(Enum.InventoryTypes.NonInventory)
		|             THEN 0
		|        ELSE 0 END
		|FROM
		|	AccumulationRegister.InventoryJournal.Balance(, Product = &Ref) AS InventoryJournalBalance";
		QueryText   = QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
		QueryTables = QueryTables + 1;
		
		// Group data by product accumulating quantities by different companies and orders
		QueryText = QueryText +
		"SELECT
		|	TableBalances.Product AS Product,
		|	SUM(TableBalances.QtyOnPO) AS QtyOnPO,
		|	SUM(TableBalances.QtyOnSO) AS QtyOnSO,
		|	SUM(TableBalances.QtyOnHand) AS QtyOnHand,
		|	CASE
		|		WHEN &Type = VALUE(Enum.InventoryTypes.Inventory)
		|			THEN SUM(TableBalances.QtyOnHand) + SUM(TableBalances.QtyOnPO) - SUM(TableBalances.QtyOnSO)
		|		WHEN &Type = VALUE(Enum.InventoryTypes.NonInventory)
		|			THEN 0
		|		ELSE 0
		|	END AS QtyAvailableToPromise
		|FROM
		|	Table_OrdersDispatched_OrdersRegistered_InventoryJournal AS TableBalances
		|
		|GROUP BY
		|	TableBalances.Product";
		QueryText   = QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
		QueryTables = QueryTables + 1;
		
		// Execute query
		Query.Text  = QueryText;
		QueryResult = Query.ExecuteBatch();
		
		// Fill form attributes with query result
		Selection   = QueryResult[QueryTables].Select();
		If Selection.Next() Then
			FillPropertyValues(ThisForm, Selection, "QtyOnPO, QtyOnSO, QtyOnHand, QtyAvailableToPromise");
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
// Prefills default accounts, determines accounts descriptions, and sets accounts visibility
//
Procedure TypeOnChange(Item)
	
	NewItemType = Object.Type;
	
	If GeneralFunctions.InventoryType(NewItemType) AND Object.Ref.IsEmpty() Then
		
		Items.CostingMethod.Visible = True;
		Object.CostingMethod = GeneralFunctionsReusable.WeightedAverage();
		Items.DefaultLocation.ReadOnly = False;
		Items.InventoryOrExpenseAccount.Title = "Inventory account";
		Items.COGSAccount.ReadOnly = False;
		
		Object.COGSAccount = GeneralFunctions.GetDefaultCOGSAcct();
		//Items.COGSAcctLabel.Title = CommonUse.GetAttributeValue(Object.COGSAccount, "Description");
		
		Acct = GeneralFunctions.InventoryAcct(NewItemType);
		AccountDescription = CommonUse.GetAttributeValue(Acct, "Description");
		Object.InventoryOrExpenseAccount = Acct;
		//Items.InventoryAcctLabel.Title = AccountDescription;
		Items.CostingMethod.ReadOnly = False;
		
		TypeOnChangeAtServer();
		
	EndIf;
	
	If (NOT GeneralFunctions.InventoryType(NewItemType)) AND Object.Ref.IsEmpty() Then
		
		Items.CostingMethod.Visible = False;
		Items.DefaultLocation.ReadOnly = True;
		Items.InventoryOrExpenseAccount.Title = "Expense account";
		Items.COGSAccount.ReadOnly = True;
		
		Acct = GeneralFunctions.InventoryAcct(NewItemType);
		AccountDescription = CommonUse.GetAttributeValue(Acct, "Description");
		Object.InventoryOrExpenseAccount = Acct;
		//Items.InventoryAcctLabel.Title = AccountDescription;
		Object.COGSAccount = GeneralFunctions.GetEmptyAcct();
		
		//service taxable defaults to false
		Object.Taxable = False;
		
	EndIf;


		
	If NOT Object.Ref.IsEmpty() Then
		
		Items.CostingMethod.ReadOnly = True;
		Items.DefaultLocation.ReadOnly = True;
		Items.InventoryOrExpenseAccount.Title = "Expense account";
		Items.COGSAccount.ReadOnly = True;
		
		Object.COGSAccount = GeneralFunctions.GetEmptyAcct();
		Items.COGSAcctLabel.Title = "";
		
		Object.InventoryOrExpenseAccount = GeneralFunctions.GetEmptyAcct();
		Items.InventoryAcctLabel.Title = "";


	EndIf;
	
		
EndProcedure

&AtServer
Procedure TypeOnChangeAtServer()
	
	If Constants.SalesTaxMarkNewProductsTaxable.Get() = True Then
		Object.Taxable = True;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// Doesn't allow to save an inventory product type without a set costing type
	
	If Object.Type = Enums.InventoryTypes.Inventory Then
		
		If Object.CostingMethod.IsEmpty() Then
			Message = New UserMessage();
			Message.Text=NStr("en='Costing method field is empty'");
			//Message.Field = "Object.CostingMethod";
			Message.Message();
			Cancel = True;
			Return;
		EndIf;
		
		If Object.COGSAccount.IsEmpty() Then
			
			Message = New UserMessage();
			Message.Text=NStr("en='COGS account is empty'");
			//Message.Field = "Object.COGSAccount";
			Message.Message();
			Cancel = True;
			Return;
			
		EndIf;
		
		If Object.InventoryOrExpenseAccount.IsEmpty() Then
			
			Message = New UserMessage();
			Message.Text=NStr("en='Inventory account is empty'");
			//Message.Field = "Object.InventoryOrExpenseAccount";
			Message.Message();
			Cancel = True;
			Return;
			
		EndIf;

		
	EndIf;
		
EndProcedure

&AtServer
Procedure AddPriceList()
	
	LastPrice = GeneralFunctions.RetailPrice(CurrentDate(), Object.Ref, Catalogs.Companies.EmptyRef());

	
	If LastPrice <> Price Then

		QueryText = "SELECT TOP 1
		            |	PriceListSliceLast.Product.Ref,
		            |	PriceListSliceLast.PriceLevel.Description,
		            |	PriceListSliceLast.ProductCategory.Description,
		            |	PriceListSliceLast.Price,
		            |	PriceListSliceLast.Cost,
		            |	PriceListSliceLast.PriceType,
		            |	PriceListSliceLast.Period
		            |FROM
		            |	InformationRegister.PriceList.SliceLast AS PriceListSliceLast
		            |WHERE
		            |	PriceListSliceLast.Product = &Product
		            |	AND PriceListSliceLast.PriceLevel = &PriceLevel
		            |	AND PriceListSliceLast.ProductCategory = &ProductCategory";
		Query = New Query(QueryText);
		Query.SetParameter("Product", Object.Ref);
		Query.SetParameter("PriceLevel", Catalogs.PriceLevels.EmptyRef());
		Query.SetParameter("ProductCategory", Catalogs.ProductCategories.EmptyRef());
		QueryResult = Query.Execute().Unload();
		
		If QueryResult.Count() > 0 Then
			
			If Format(QueryResult[0].Period,"DLF = D") = Format(CurrentDate(),"DLF = D") Then
					RecordSet = InformationRegisters.PriceList.CreateRecordSet();
					RecordSet.Filter.Product.Set(Object.Ref);
					RecordSet.Filter.Period.Set(CurrentDate());
					RecordSet.Filter.PriceLevel.Set(Catalogs.PriceLevels.EmptyRef());
					RecordSet.Filter.ProductCategory.Set(Catalogs.ProductCategories.EmptyRef());
					RecordSet.Read();
					RecordSet[0].Price = Price;
					RecordSet.Write();

			Else

			    
				RecordSet = InformationRegisters.PriceList.CreateRecordSet();
				RecordSet.Filter.Product.Set(Object.Ref);
				RecordSet.Filter.Period.Set(CurrentDate());
				RecordSet.Read();
				NewRecord = RecordSet.Add();
				NewRecord.Period = CurrentDate();
				NewRecord.PriceType = "Item";
				NewRecord.Product = Object.Ref;
				NewRecord.Price = Price;
				RecordSet.Write()
				
			Endif;
			
		Else

			    
			RecordSet = InformationRegisters.PriceList.CreateRecordSet();
			RecordSet.Filter.Product.Set(Object.Ref);
			RecordSet.Filter.Period.Set(CurrentDate());
			RecordSet.Read();
			NewRecord = RecordSet.Add();
			NewRecord.Period = CurrentDate();
			NewRecord.PriceType = "Item";
			NewRecord.Product = Object.Ref;
			NewRecord.Price = Price;
			RecordSet.Write()
			
		Endif;

			

			   		
	Endif;

	
EndProcedure

&AtClient
Procedure InventorySiteInfo(Command)
	
	ParametersStructure = New Structure;
	ParametersStructure.Insert("Product", Object.Ref); 
	ParametersStructure.Insert("QtyOnPO", QtyOnPO); 
	ParametersStructure.Insert("QtyOnSO", QtyOnSO); 
	ParametersStructure.Insert("QtyOnHand", QtyOnHand); 
	ParametersStructure.Insert("QtyAvailableToPromise", QtyAvailableToPromise); 
	
	OpenForm("DataProcessor.InventorySiteInfo.Form", ParametersStructure);

EndProcedure

&AtClient
Procedure UnitSetOnChange(Item)
	
	SetBaseUnit();
	
EndProcedure

&AtServer 
Function SetBaseUnit()
	
	BaseUnit = GeneralFunctions.GetBaseUnit(Object.UnitSet); 
	Items.Right.Title = "Item quantities in " + BaseUnit.Code;
	
EndFunction

&AtClient
Procedure IsAssemblyOnChange(Item)
	
	// Switch on assembly status.
	If Not Object.Assembly And Object.LineItems.Count() > 0 Then
		
		// Request user confirmation on clearing the assembly.
		QuestionText  = NStr("en = 'Clear assembly contents?'");
		QuestionTitle = NStr("en = 'Clear assembly'");
		ChoiceProcessing = New NotifyDescription("IsAssemblyOnChangeChoiceProcessing", ThisForm);
		ShowQueryBox(ChoiceProcessing, QuestionText, QuestionDialogMode.OKCancel,, DialogReturnCode.Cancel, QuestionTitle);
		
	Else
		// Show/hide assembly part.
		Items.Assembly.Visible = Object.Assembly;
	EndIf;
	
EndProcedure

&AtClient
Procedure IsAssemblyOnChangeChoiceProcessing(ChoiceResult, ChoiceParameters) Export
	
	// Process user choice.
	If ChoiceResult = DialogReturnCode.OK Then
		// Clear line items.
		Object.LineItems.Clear();
		Items.Assembly.Visible = False;
		
	Else
		// Restore previously entered setting.
		Object.Assembly = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure PricePrecisionOnChange(Item)
	
	If Object.PricePrecision = 0 Or Object.PricePrecision = 1 Then
		Object.PricePrecision = 2;
	EndIf;
	
	PricePrecision = GetInfPricePrecision(Object.Ref);
	
	If Object.PricePrecision < PricePrecision.Item Then
		
		Object.PricePrecision = PricePrecision.Item;
		
		Message = New UserMessage();
		Message.Text = NStr("en = 'The new value of ""Price field decimals"" must be greater than or equal to the current value!'");
		Message.Field = "Object.PricePrecision";
		Message.Message();
		
	EndIf;
	
	If Object.PricePrecision > PricePrecision.Constant Then
		
		Object.PricePrecision = PricePrecision.Constant;
		
		Message = New UserMessage();
		Text = StringFunctionsClientServer.SubstituteParametersInString(
			   NStr("en = 'The new value of ""Price field decimals"" must be less than or equal to %1.'"), PricePrecision.Constant);
		Message.Text = Text;
		Message.Field = "Object.PricePrecision";
		Message.Message();
		
	EndIf;
	
EndProcedure

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
		
		// Fill new row with default values (reserved).
		ObjectData  = New Structure("");
		FillPropertyValues(ObjectData, Object);
		For Each ObjectField In ObjectData Do
			If Not ValueIsFilled(Item.CurrentData[ObjectField.Key]) Then
				Item.CurrentData[ObjectField.Key] = ObjectField.Value;
			EndIf;
		EndDo;
		
		// Clear order data on duplicate row (reserved).
		ClearFields  = New Structure("");
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
	
	// Recalculation common item totals.
	RecalculateTotals();
	
EndProcedure

&AtClient
Procedure LineItemsAfterDeleteRow(Item)
	
	// Recalculation common item totals.
	RecalculateTotals();
	
EndProcedure

//------------------------------------------------------------------------------
// Tabular section LineItems columns controls event handlers.

&AtClient
Procedure LineItemsProductOnChange(Item)
	Var MessageText;
	
	// Fill line data for editing.
	TableSectionRow = GetLineItemsRowStructure();
	FillPropertyValues(TableSectionRow, Items.LineItems.CurrentData);
	
	// Check added item.
	If LineItemsProductCheckItem(TableSectionRow, MessageText) Then
		// Item was checked successfully and all server filling accomplished.
		
		// Load processed data back.
		FillPropertyValues(Items.LineItems.CurrentData, TableSectionRow);
		
		// Refresh totals cache.
		RecalculateTotals();
	Else
		// Inform user about wrong item.
		CommonUseClientServer.MessageToUser(MessageText, Object, "Object.LineItems["+Format(TableSectionRow.LineNumber-1, "NG=")+"].Product");
		
		// Clear selected item.
		Items.LineItems.CurrentData.Product = Undefined;
	EndIf;
	
EndProcedure

&AtServer
Function LineItemsProductCheckItem(TableSectionRow, MessageText)
	
	// Check possibility of adding assembly to the items list.
	If TableSectionRow.Product.Assembly Then
		// Check whether it is item itself.
		If TableSectionRow.Product = Object.Ref Then
			MessageText = StringFunctionsClientServer.SubstituteParametersInString(
			              NStr("en = 'Cannot add the assembly %1 to its own contents.'"),
			              TableSectionRow.Product.Description);
			Return False;
		EndIf;
		
		// Check possible parent of current item.
		Child = Catalogs.Products.ItemIsParentAssembly(TableSectionRow.Product, Object.Ref);
		If Child <> Undefined Then
			// Assembly already added to the another subassembly.
			MessageText = StringFunctionsClientServer.SubstituteParametersInString(
			              NStr("en = 'Cannot add the assembly %1 to the contents of %2 because %3 already added to %1.'"),
			              TableSectionRow.Product.Description, Object.Description, Child.Description);
			Return False;
		EndIf;
	EndIf;
	
	// Request server operation.
	LineItemsProductOnChangeAtServer(TableSectionRow);
	
	// Operation successfully completed.
	Return True;
	
EndFunction

&AtServer
Procedure LineItemsProductOnChangeAtServer(TableSectionRow)
	
	// Request product properties.
	ProductProperties = CommonUse.GetAttributeValues(TableSectionRow.Product, New Structure("Description, UnitSet"));
	TableSectionRow.ProductDescription = ProductProperties.Description;
	TableSectionRow.UnitSet            = ProductProperties.UnitSet;
	TableSectionRow.Unit               = ProductProperties.UnitSet.DefaultPurchaseUnit;
	TableSectionRow.PriceUnits         = Round(GeneralFunctions.ProductLastCost(TableSectionRow.Product) *
	                                     ?(TableSectionRow.Unit.Factor > 0, TableSectionRow.Unit.Factor, 1), GeneralFunctionsReusable.PricePrecisionForOneItem(TableSectionRow.Product));
										 
	// Assign default quantities.
	TableSectionRow.QtyUnits      = 0;
	TableSectionRow.WastePercent  = 0;
	TableSectionRow.WasteQtyUnits = 0;
	
	// Calculate totals by line.
	TableSectionRow.LineTotal     = 0;
	
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
	TableSectionRow.PriceUnits = Round(GeneralFunctions.ProductLastCost(TableSectionRow.Product) *
	                             ?(TableSectionRow.Unit.Factor > 0, TableSectionRow.Unit.Factor, 1), GeneralFunctionsReusable.PricePrecisionForOneItem(TableSectionRow.Product));
	
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
	RecalculateTotals();
	
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
	
	// Back-step price calculation with totals priority.
	TableSectionRow.PriceUnits = ?(TableSectionRow.QtyUnits > 0,
	                             Round(TableSectionRow.LineTotal / Round(TableSectionRow.QtyUnits, QuantityPrecision), GeneralFunctionsReusable.PricePrecisionForOneItem(TableSectionRow.Product)), 0);
	
	// Load processed data back.
	FillPropertyValues(Items.LineItems.CurrentData, TableSectionRow);
	
	// Refresh totals cache.
	RecalculateTotals();
	
EndProcedure

&AtServer
Procedure LineItemsLineTotalOnChangeAtServer(TableSectionRow)
	
	// Reserved for future use.
	
EndProcedure

&AtClient
Procedure LineItemsWastePercentOnChange(Item)
	
	// Fill line data for editing.
	TableSectionRow = GetLineItemsRowStructure();
	FillPropertyValues(TableSectionRow, Items.LineItems.CurrentData);
	
	// Request server operation.
	LineItemsWastePercentOnChangeAtServer(TableSectionRow);
	
	// Load processed data back.
	FillPropertyValues(Items.LineItems.CurrentData, TableSectionRow);
	
	// Refresh totals cache.
	RecalculateTotals();
	
EndProcedure

&AtServer
Procedure LineItemsWastePercentOnChangeAtServer(TableSectionRow)
	
	// Calculate waste qty by line.
	TableSectionRow.WasteQtyUnits = Round(Round(TableSectionRow.QtyUnits, QuantityPrecision) * TableSectionRow.WastePercent / 100, QuantityPrecision);
	
EndProcedure

&AtClient
Procedure LineItemsWasteQtyUnitsOnChange(Item)
	
	// Fill line data for editing.
	TableSectionRow = GetLineItemsRowStructure();
	FillPropertyValues(TableSectionRow, Items.LineItems.CurrentData);
	
	// Request server operation.
	LineItemsWasteQtyUnitsOnChangeAtServer(TableSectionRow);
	
	// Load processed data back.
	FillPropertyValues(Items.LineItems.CurrentData, TableSectionRow);
	
	// Refresh totals cache.
	RecalculateTotals();
	
EndProcedure

&AtServer
Procedure LineItemsWasteQtyUnitsOnChangeAtServer(TableSectionRow)
	
	// Calculate total by line.
	If TableSectionRow.WasteQtyUnits <= TableSectionRow.QtyUnits Then
		TableSectionRow.WastePercent = ?(Round(TableSectionRow.QtyUnits, QuantityPrecision) > 0,
		                                 Round(TableSectionRow.WasteQtyUnits * 100 / Round(TableSectionRow.QtyUnits, QuantityPrecision), QuantityPrecision),
		                                 0);
	Else
		TableSectionRow.WasteQtyUnits = TableSectionRow.QtyUnits;
		TableSectionRow.WastePercent  = 100;
	EndIf;
	
EndProcedure

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region PRIVATE_IMPLEMENTATION

//------------------------------------------------------------------------------
// Calculate totals and fill object attributes.

&AtClient
Procedure RecalculateTotals()
	
	// Assign totals to the object fields.
	// Reserved for future use.
	
EndProcedure

//------------------------------------------------------------------------------
// Replacemant for metadata properties on client.

&AtClient
// Returns fields structure of LineItems form control.
Function GetLineItemsRowStructure()
	
	// Define control row fields.
	Return New Structure("LineNumber, Product, ProductDescription, UnitSet, QtyUnits, Unit, PriceUnits, LineTotal, WastePercent, WasteQtyUnits");
	
EndFunction

&AtServerNoContext 
Function GetInfPricePrecision(Item)
	
	Return New Structure("Constant, Item", Constants.PricePrecision.Get(), Item.PricePrecision);
	
EndFunction

// Update prices presentation.
&AtServer
Procedure UpdatePricesPresentation()
	
	PriceFormat = GeneralFunctionsReusable.PriceFormatForOneItem(Object.Ref);
	Items.Price1.EditFormat          = PriceFormat;
	Items.LastCost.EditFormat        = PriceFormat;
	Items.AverageCost.EditFormat     = PriceFormat;
	Items.AccountingCost.EditFormat  = PriceFormat;
	
EndProcedure

#EndRegion
