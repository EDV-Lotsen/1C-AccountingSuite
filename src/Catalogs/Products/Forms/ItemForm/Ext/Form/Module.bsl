
&AtServer
// Prefills default accounts, VAT codes, determines accounts descriptions, and sets field visibility
//
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Constants.ExpenseAccount.Get() = ChartsOfAccounts.ChartOfAccounts.EmptyRef() OR
		Constants.IncomeAccount.Get() = ChartsOfAccounts.ChartOfAccounts.EmptyRef() OR
		Constants.COGSAccount.Get() = ChartsOfAccounts.ChartOfAccounts.EmptyRef() OR
		Constants.InventoryAccount.Get() = ChartsOfAccounts.ChartOfAccounts.EmptyRef() Then
		
		Message = New UserMessage();
		Message.Text=NStr("en='Indicate default Income, Expense, Inventory, COGS accounts in Setup / Posting accounts'");
		Message.Message();
		
	Else
	EndIf;

	
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
	Items.ResidualsItemsQuantity.EditFormat = QuantityFormat;
	Items.ResidualsItemsQuantity.Format     = QuantityFormat;
	Items.ServicesItemsQuantity.EditFormat  = QuantityFormat;
	Items.ServicesItemsQuantity.Format      = QuantityFormat;

	
	Items.QtyOnPO.Format                    = QuantityFormat; 
	Items.QtyOnPO.EditFormat                = QuantityFormat; 
	Items.QtyOnSO.Format                    = QuantityFormat; 
	Items.QtyOnSO.EditFormat                = QuantityFormat; 
	Items.QtyOnHand.Format                  = QuantityFormat; 
	Items.QtyOnHand.EditFormat              = QuantityFormat; 
	Items.QtyAvailableToPromise.Format      = QuantityFormat; 
	Items.QtyAvailableToPromise.EditFormat  = QuantityFormat; 
	
	Items.ReorderQty.Format                 = QuantityFormat; 
	Items.ReorderQty.EditFormat             = QuantityFormat; 
	
	// Update prices presentation in LineItems.
	PriceFormat = GeneralFunctionsReusable.DefaultPriceFormat();
	Items.LineItemsPrice.EditFormat  = PriceFormat;
	Items.LineItemsPrice.Format      = PriceFormat;
	
	// Show/hide assembly part.
	Items.Assembly.Visible     = Object.Assembly;
	Items.Residuals.Visible    = Object.HasResiduals;
	Items.HasResiduals.Enabled = Object.Assembly;
	Items.Services.Visible     = Object.HasServices;
	Items.HasServices.Enabled  = Object.Assembly;
	
	// Show/hide lots/serial numbers purt.
	Items.Lots.Visible          = Object.HasLotsSerialNumbers;
	If Object.UseLots = 1 Then    // use Serial numbers.
		Items.LotsLeft.Enabled  = False; // Lots
		Items.LotsRight.Enabled = True;  // Serials
	Else                          // use Lots numbers.
		Items.LotsLeft.Enabled  = True;  // Lots
		Items.LotsRight.Enabled = False; // Serials
	EndIf;
	Items.LotsProperties.CurrentPage = Items.LotsProperties.ChildItems[Object.UseLotsType];
	Items.LotsShelfLife.Enabled = Boolean(Object.UseLotsByExpiration);
	
	// Update serial numbers options availability.
	Items.UseSerialNumbersCheckReception.Enabled  = Object.UseSerialNumbersOnGoodsReception And Object.UseSerialNumbersOnShipment;
	Items.UseSerialNumbersCheckUniqueness.Enabled = Object.UseSerialNumbersOnGoodsReception;
	
	// Update open lists buttons.
	If Object.Ref.IsEmpty() Then
		Items.OpenLots.Enabled = False;
		Items.OpenSerialNumbers.Enabled = False;
	EndIf;
	
	// Define inventory items type.
	IsInventoryType = GeneralFunctions.InventoryType(Object.Type);
	
	// Lock inventory type change.
	Items.Type.Enabled = (Not Object.Assembly) And (Not Object.HasLotsSerialNumbers);
	
	// Lock assembly items for service items.
	If Not IsInventoryType Then
		// Lock assembly switchers.
		Items.IsAssembly.Enabled           = False;
		Items.HasResiduals.Enabled         = False;
		Items.HasServices.Enabled          = False;
	EndIf;
	
	// Lock possible lots/serial numbers settings change.
	If (Not IsInventoryType)                                          // Service items.
	Or (Not Object.Ref.IsEmpty() And HasDescendants(Object.Ref)) Then // Saved inventory items having lots & serials.
		Items.HasLotsSerialNumbers.Enabled = False;
		Items.UseLots.Enabled              = False;
		Items.UseLotsType.Enabled          = False;
		Items.Characteristic.Enabled       = False;
		Items.UseLotsByExpiration.Enabled  = False;
		Items.ShelfLife.Enabled            = False;
		Items.ShelfLifeUnit.Enabled        = False;
	EndIf;
	
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
		Items.ReorderQty.Visible = IsInventoryType; 
	Else
		// New item: hide indicators
		Items.CostAndQuantity.Visible = False;
		Items.ReorderQty.Visible      = False;
	EndIf;
	
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
	
	// Update open lists buttons.
	Items.OpenLots.Enabled = True;
	Items.OpenSerialNumbers.Enabled = True;
	
	// Define inventory items type.
	IsInventoryType = GeneralFunctions.InventoryType(Object.Type);
	
	// Lock inventory type change.
	Items.Type.Enabled = (Not Object.Assembly) And (Not Object.HasLotsSerialNumbers);
	
	// Lock assembly items for service items.
	If Not IsInventoryType Then
		// Lock assembly switchers.
		Items.IsAssembly.Enabled           = False;
		Items.HasResiduals.Enabled         = False;
		Items.HasServices.Enabled          = False;
	EndIf;
	
	// Lock possible lots/serial numbers settings change.
	If (Not IsInventoryType)                                          // Service items.
	Or (Not Object.Ref.IsEmpty() And HasDescendants(Object.Ref)) Then // Saved inventory items having lots & serials.
		Items.HasLotsSerialNumbers.Enabled = False;
		Items.UseLots.Enabled              = False;
		Items.UseLotsType.Enabled          = False;
		Items.Characteristic.Enabled       = False;
		Items.UseLotsByExpiration.Enabled  = False;
		Items.ShelfLife.Enabled            = False;
		Items.ShelfLifeUnit.Enabled        = False;
	EndIf;
	
	// Update prices presentation.
	UpdatePricesPresentation();
	
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
	
	// Define inventory items type.
	IsInventoryType = GeneralFunctions.InventoryType(NewItemType); 
	
	// Lock assembly items for service items.
	Items.IsAssembly.Enabled   = IsInventoryType;
	Items.HasResiduals.Enabled = Object.Assembly;
	Items.HasServices.Enabled  = Object.Assembly;
	
	// Lock possible lots/serial numbers settings change.
	LockLotsSerials = (Not IsInventoryType) Or (Not Object.Ref.IsEmpty() And HasDescendants(Object.Ref));
	Items.HasLotsSerialNumbers.Enabled = Not LockLotsSerials;
	
	If IsInventoryType AND Object.Ref.IsEmpty() Then
		
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
	
	If (NOT IsInventoryType) AND Object.Ref.IsEmpty() Then
		
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
	
	Items.ReorderQty.Visible = IsInventoryType;
		
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
	Items.ReorderQty.Title = "Reorder point in " + BaseUnit.Code; 
	
EndFunction

&AtClient
Procedure IsAssemblyOnChange(Item)
	
	// Switch on assembly status.
	If Not Object.Assembly And (Object.LineItems.Count() > 0 Or Object.Residuals.Count() > 0 Or Object.Services.Count() > 0) Then
		
		// Request user confirmation on clearing the assembly contents.
		QuestionText  = NStr("en = 'Clear assembly, residuals and services contents?'");
		QuestionTitle = NStr("en = 'Clear assembly'");
		ChoiceProcessing = New NotifyDescription("IsAssemblyOnChangeChoiceProcessing", ThisForm);
		ShowQueryBox(ChoiceProcessing, QuestionText, QuestionDialogMode.OKCancel,, DialogReturnCode.Cancel, QuestionTitle);
		
	Else
		// Lock inventory type change.
		Items.Type.Enabled         = (Not Object.Assembly) And (Not Object.HasLotsSerialNumbers);
		
		// Update residuals.
		Object.HasResiduals        = Object.Assembly And Object.HasResiduals;
		Items.HasResiduals.Enabled = Object.Assembly;
		
		// Update services.
		Object.HasServices         = Object.Assembly And Object.HasServices;
		Items.HasServices.Enabled  = Object.Assembly;
		
		// Show/hide assembly, residuals and services part.
		Items.Assembly.Visible     = Object.Assembly;
		Items.Residuals.Visible    = Object.HasResiduals;
		Items.Services.Visible     = Object.HasServices;
		
		Object.WasteAccount = ?(Object.Assembly, CommonUse.GetConstant("WasteAccount"), PredefinedValue("ChartOfAccounts.ChartOfAccounts.EmptyRef"));
		
	EndIf;
	
EndProcedure

&AtClient
Procedure IsAssemblyOnChangeChoiceProcessing(ChoiceResult, ChoiceParameters) Export
	
	// Process user choice.
	If ChoiceResult = DialogReturnCode.OK Then
		// Clear line items, residuals and services.
		Object.LineItems.Clear();
		Object.Residuals.Clear();
		Object.Services.Clear();
		
		// Lock inventory type change.
		Items.Type.Enabled         = (Not Object.Assembly) And (Not Object.HasLotsSerialNumbers);
		
		// Show/hide assembly, residuals and services part.
		Items.Assembly.Visible     = False;
		Items.Residuals.Visible    = False;
		Items.Services.Visible     = False;
		
		// Disable residuals.
		Object.HasResiduals        = False;
		Items.HasResiduals.Enabled = False;
		
		// Disable services.
		Object.HasServices         = False;
		Items.HasServices.Enabled  = False;
		
		// Clear WasteAccount.
		Object.WasteAccount        = PredefinedValue("ChartOfAccounts.ChartOfAccounts.EmptyRef");
		
	Else
		// Restore previously entered setting.
		Object.Assembly = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure HasResidualsOnChange(Item)
	
	// Switch on assembly status.
	If Not Object.HasResiduals And Object.Residuals.Count() > 0 Then
		
		// Request user confirmation on clearing the residuals contents.
		QuestionText  = NStr("en = 'Clear residuals contents?'");
		QuestionTitle = NStr("en = 'Clear residuals'");
		ChoiceProcessing = New NotifyDescription("HasResidualsOnChangeChoiceProcessing", ThisForm);
		ShowQueryBox(ChoiceProcessing, QuestionText, QuestionDialogMode.OKCancel,, DialogReturnCode.Cancel, QuestionTitle);
		
	Else
		// Show/hide assembly part.
		Items.Residuals.Visible = Object.HasResiduals;
	EndIf;
	
EndProcedure

&AtClient
Procedure HasResidualsOnChangeChoiceProcessing(ChoiceResult, ChoiceParameters) Export
	
	// Process user choice.
	If ChoiceResult = DialogReturnCode.OK Then
		// Clear line items.
		Object.Residuals.Clear();
		Items.Residuals.Visible = False;
		
	Else
		// Restore previously entered setting.
		Object.HasResiduals = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure HasServicesOnChange(Item)
	
	// Switch on assembly status.
	If Not Object.HasServices And Object.Services.Count() > 0 Then
		
		// Request user confirmation on clearing the services contents.
		QuestionText  = NStr("en = 'Clear services contents?'");
		QuestionTitle = NStr("en = 'Clear services'");
		ChoiceProcessing = New NotifyDescription("HasServicesOnChangeChoiceProcessing", ThisForm);
		ShowQueryBox(ChoiceProcessing, QuestionText, QuestionDialogMode.OKCancel,, DialogReturnCode.Cancel, QuestionTitle);
		
	Else
		// Show/hide assembly part.
		Items.Services.Visible = Object.HasServices;
	EndIf;
	
EndProcedure

&AtClient
Procedure HasServicesOnChangeChoiceProcessing(ChoiceResult, ChoiceParameters) Export
	
	// Process user choice.
	If ChoiceResult = DialogReturnCode.OK Then
		// Clear line items.
		Object.Services.Clear();
		Items.Services.Visible = False;
		
	Else
		// Restore previously entered setting.
		Object.HasServices = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure HasLotsSerialNumbersOnChange(Item)
	
	// Lock inventory type change.
	Items.Type.Enabled = (Not Object.Assembly) And (Not Object.HasLotsSerialNumbers);
	
	// Switch on lots / serial numbers status.
	If Not Object.HasLotsSerialNumbers And Not Object.Ref.IsEmpty() And HasDescendants(Object.Ref) Then
		// Return values back.
		Object.HasLotsSerialNumbers = True;
		
		// Update lots controls accessibility.
		If Not Object.Ref.IsEmpty() And HasDescendants(Object.Ref) Then // There are owned lots / serial numbers.
			// Lock possible lots/serial numbers settings change.
			Items.HasLotsSerialNumbers.Enabled = False;
			Items.UseLots.Enabled              = False;
			Items.UseLotsType.Enabled          = False;
			Items.Characteristic.Enabled       = False;
			Items.UseLotsByExpiration.Enabled  = False;
			Items.ShelfLife.Enabled            = False;
			Items.ShelfLifeUnit.Enabled        = False;
		EndIf;
		
	Else
		// Show/hide serial numbers part.
		Items.Lots.Visible = Object.HasLotsSerialNumbers;
	EndIf;
	
EndProcedure

&AtClient
Procedure UseLotsOnChange(Item)
	
	// Switch on lots / serial numbers status.
	If Not Object.Ref.IsEmpty() And HasDescendants(Object.Ref) Then
		// Return values back.
		Object.UseLots = 1 - Object.UseLots; // Negate value.
		
		// Update lots controls accessibility.
		If Not Object.Ref.IsEmpty() And HasDescendants(Object.Ref) Then // There are owned lots / serial numbers.
			// Lock possible lots/serial numbers settings change.
			Items.HasLotsSerialNumbers.Enabled = False;
			Items.UseLots.Enabled              = False;
			Items.UseLotsType.Enabled          = False;
			Items.Characteristic.Enabled       = False;
			Items.UseLotsByExpiration.Enabled  = False;
			Items.ShelfLife.Enabled            = False;
			Items.ShelfLifeUnit.Enabled        = False;
		EndIf;
		
	Else
		// Change lots/serials status.
		If Object.UseLots = 1 Then // use Serial numbers.
			Items.LotsLeft.Enabled  = False; // Lots
			Items.LotsRight.Enabled = True;  // Serials
		Else                       // use Lots numbers.
			Items.LotsLeft.Enabled  = True;  // Lots
			Items.LotsRight.Enabled = False; // Serials
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure UseLotsTypeOnChange(Item)
	
	// Set current settings page by lots type.
	Items.LotsProperties.CurrentPage = Items.LotsProperties.ChildItems[Object.UseLotsType];
	
EndProcedure

&AtClient
Procedure UseLotsByExpirationOnChange(Item)
	
	// Update shelf life settings.
	Items.LotsShelfLife.Enabled = Boolean(Object.UseLotsByExpiration);
	
EndProcedure

&AtClient
Procedure UseSerialNumbersOnShipmentOnChange(Item)
	
	// Update reception check status.
	CheckReceptionAvailable = Object.UseSerialNumbersOnGoodsReception And Object.UseSerialNumbersOnShipment;
	Items.UseSerialNumbersCheckReception.Enabled = CheckReceptionAvailable;
	If Not CheckReceptionAvailable Then
		Object.UseSerialNumbersCheckReception = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure UseSerialNumbersOnGoodsReceptionOnChange(Item)
	
	// Update reception check status.
	CheckReceptionAvailable = Object.UseSerialNumbersOnGoodsReception And Object.UseSerialNumbersOnShipment;
	Items.UseSerialNumbersCheckReception.Enabled = CheckReceptionAvailable;
	If Not CheckReceptionAvailable Then
		Object.UseSerialNumbersCheckReception = False;
	EndIf;
	
	// Update uniqueness check status.
	CheckUniquenessAvailable = Object.UseSerialNumbersOnGoodsReception;
	Items.UseSerialNumbersCheckUniqueness.Enabled = CheckUniquenessAvailable;
	If Not CheckUniquenessAvailable Then
		Object.UseSerialNumbersCheckUniqueness = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure PricePrecisionOnChange(Item)
	
	If Object.PricePrecision = 0 Or Object.PricePrecision = 1 Then
		Object.PricePrecision = 2;
	EndIf;
	
	RefreshReusable = True;
	PricePrecision  = GetInfPricePrecision(Object.Ref);
	
	If Object.PricePrecision < PricePrecision.Item Then
		
		Object.PricePrecision = PricePrecision.Item;
		
		RefreshReusable       = False;
		
		Message = New UserMessage();
		Message.Text = NStr("en = 'The new value of ""Price field decimals"" must be greater than or equal to the current value!'");
		Message.Field = "Object.PricePrecision";
		Message.Message();
		
	EndIf;
	
	If Object.PricePrecision > PricePrecision.Constant Then
		
		Object.PricePrecision = PricePrecision.Constant;
		
		If Object.PricePrecision = PricePrecision.Item Then
			RefreshReusable = False;
		EndIf;
		
		Message = New UserMessage();
		Text = StringFunctionsClientServer.SubstituteParametersInString(
			   NStr("en = 'The new value of ""Price field decimals"" must be less than or equal to %1.'"), PricePrecision.Constant);
		Message.Text = Text;
		Message.Field = "Object.PricePrecision";
		Message.Message();
		
	EndIf;
	
	If RefreshReusable Then
		RefreshReusableValues();
	EndIf;
	
EndProcedure


////////////////////////////////////////////////////////////////////////////////
#Region COMMANDS_HANDLERS

&AtClient
Procedure OpenLots(Command)
	
	// Open lots list.
	If (Not Object.Ref.IsEmpty()) Then
		
		// Get lots owner.
		LotsOwner = ?(Object.UseLotsType = 1, Object.Characteristic, Object.Ref);
		
		// Define form parameters.
		FormParameters = New Structure();
		
		// Define list filter.
		FltrParameters = New Structure();
		FltrParameters.Insert("Product", Object.Ref);
		FltrParameters.Insert("Owner",   LotsOwner);
		FormParameters.Insert("Filter",  FltrParameters);
		
		// Define notification on close child form.
		NotifyDescription = New NotifyDescription("LotsSerialNumbersChoiceProcessing", ThisForm);
		
		// Open orders selection form.
		OpenForm("Catalog.Lots.Form.LotsForm", FormParameters, ThisForm,,,, NotifyDescription, FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenSerialNumbers(Command)
	
	// Open serial numbers list.
	If (Not Object.Ref.IsEmpty()) Then
		
		// Define form parameters.
		FormParameters = New Structure();
		
		// Define list filter.
		FltrParameters = New Structure();
		FltrParameters.Insert("Product", Object.Ref);
		FormParameters.Insert("Filter",  FltrParameters);
		
		// Define notification on close child form.
		NotifyDescription = New NotifyDescription("LotsSerialNumbersChoiceProcessing", ThisForm);
		
		// Open orders selection form.
		OpenForm("InformationRegister.SerialNumbers.Form.SliceLast", FormParameters, ThisForm,,,, NotifyDescription, FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
	
EndProcedure

&AtClient
Procedure LotsSerialNumbersChoiceProcessing(Result, Parameters) Export
	
	// Check possible descendant items.
	If HasDescendants(Object.Ref) Then
		// Lock possible lots/serial numbers settings change.
		Items.HasLotsSerialNumbers.Enabled = False;
		Items.UseLots.Enabled              = False;
		Items.UseLotsType.Enabled          = False;
		Items.Characteristic.Enabled       = False;
		Items.UseLotsByExpiration.Enabled  = False;
		Items.ShelfLife.Enabled            = False;
		Items.ShelfLifeUnit.Enabled        = False;
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
		RecalculateResidualsAndTotals();
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
	RecalculateResidualsAndTotals();
	
EndProcedure

&AtClient
Procedure LineItemsAfterDeleteRow(Item)
	
	// Recalculation common item totals.
	RecalculateResidualsAndTotals();
	
EndProcedure

//------------------------------------------------------------------------------
// Tabular section Residuals event handlers.

&AtClient
Procedure ResidualsOnChange(Item)
	
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
Procedure ResidualsBeforeAddRow(Item, Cancel, Clone, Parent, Folder)
	
	// Set new row flag.
	If Not Cancel Then
		IsNewRow = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure ResidualsOnEditEnd(Item, NewRow, CancelEdit)
	
	// Recalculation common item totals.
	RecalculateTotals();
	
EndProcedure

&AtClient
Procedure ResidualsAfterDeleteRow(Item)
	
	// Recalculation common item totals.
	RecalculateTotals();
	
EndProcedure

//------------------------------------------------------------------------------
// Tabular section Services event handlers.

&AtClient
Procedure ServicesOnChange(Item)
	
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
Procedure ServicesBeforeAddRow(Item, Cancel, Clone, Parent, Folder)
	
	// Set new row flag.
	If Not Cancel Then
		IsNewRow = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure ServicesOnEditEnd(Item, NewRow, CancelEdit)
	
	// Recalculation common item totals.
	RecalculateTotals();
	
EndProcedure

&AtClient
Procedure ServicesAfterDeleteRow(Item)
	
	// Recalculation common item totals.
	RecalculateTotals();
	
EndProcedure

//------------------------------------------------------------------------------
// Tabular sections LineItems and Residuals columns controls event handlers.

&AtClient
Procedure LineItemsProductOnChange(Item)
	Var MessageText;
	
	// Fill line data for editing.
	TableSectionRow = GetLineItemsRowStructure();
	FillPropertyValues(TableSectionRow, Items.LineItems.CurrentData);
	
	// Check added item.
	If CommonProductCheckItem(TableSectionRow, MessageText) Then
		// Item was checked successfully and all server filling accomplished.
		
		// Load processed data back.
		FillPropertyValues(Items.LineItems.CurrentData, TableSectionRow);
		
		// Refresh totals cache.
		RecalculateResidualsAndTotals();
	Else
		// Inform user about wrong item.
		CommonUseClientServer.MessageToUser(MessageText, Object, "Object.LineItems["+Format(TableSectionRow.LineNumber-1, "NG=")+"].Product");
		
		// Clear selected item.
		Items.LineItems.CurrentData.Product = Undefined;
	EndIf;
	
EndProcedure

&AtClient
Procedure ResidualsProductOnChange(Item)
	Var MessageText;
	
	// Fill line data for editing.
	TableSectionRow = GetResidualsRowStructure();
	FillPropertyValues(TableSectionRow, Items.ResidualsItems.CurrentData);
	
	// Check added item.
	If CommonProductCheckItem(TableSectionRow, MessageText) Then
		// Item was checked successfully and all server filling accomplished.
		
		// Load processed data back.
		FillPropertyValues(Items.ResidualsItems.CurrentData, TableSectionRow);
		
		// Refresh totals cache.
		RecalculateTotals();
	Else
		// Inform user about wrong item.
		CommonUseClientServer.MessageToUser(MessageText, Object, "Object.Residuals["+Format(TableSectionRow.LineNumber-1, "NG=")+"].Product");
		
		// Clear selected item.
		Items.ResidualsItems.CurrentData.Product = Undefined;
	EndIf;
	
EndProcedure

&AtClient
Procedure ServicesProductOnChange(Item)
	Var MessageText;
	
	// Fill line data for editing.
	TableSectionRow = GetServicesRowStructure();
	FillPropertyValues(TableSectionRow, Items.ServicesItems.CurrentData);
	
	// Check added item.
	If CommonProductCheckItem(TableSectionRow, MessageText) Then
		// Item was checked successfully and all server filling accomplished.
		
		// Load processed data back.
		FillPropertyValues(Items.ServicesItems.CurrentData, TableSectionRow);
		
		// Refresh totals cache.
		RecalculateTotals();
	Else
		// Inform user about wrong item.
		CommonUseClientServer.MessageToUser(MessageText, Object, "Object.Services["+Format(TableSectionRow.LineNumber-1, "NG=")+"].Product");
		
		// Clear selected item.
		Items.ServicesItems.CurrentData.Product = Undefined;
	EndIf;
	
EndProcedure

&AtServer
Function CommonProductCheckItem(TableSectionRow, MessageText)
	
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
	CommonProductOnChangeAtServer(TableSectionRow);
	
	// Operation successfully completed.
	Return True;
	
EndFunction

&AtServer
Procedure CommonProductOnChangeAtServer(TableSectionRow)
	
	// Request product properties.
	ProductProperties = CommonUse.GetAttributeValues(TableSectionRow.Product, New Structure("Description, UnitSet"));
	TableSectionRow.ProductDescription = ProductProperties.Description;
	TableSectionRow.UnitSet            = ProductProperties.UnitSet;
	TableSectionRow.Unit               = ProductProperties.UnitSet.DefaultPurchaseUnit;
	TableSectionRow.PriceUnits         = Round(GeneralFunctions.ProductLastCost(TableSectionRow.Product) *
	                                     ?(TableSectionRow.Unit.Factor > 0, TableSectionRow.Unit.Factor, 1),
	                                     GeneralFunctionsReusable.PricePrecisionForOneItem(TableSectionRow.Product));
	
	// Assign default quantities.
	TableSectionRow.QtyUnits      = 0;
	
	// Calculate totals by line.
	TableSectionRow.LineTotal     = 0;
	
	// Fill optional wastes.
	If TableSectionRow.Property("WastePercent") Then
		TableSectionRow.WastePercent  = 0;
		TableSectionRow.WasteQtyUnits = 0;
		TableSectionRow.WasteTotal    = 0;
	EndIf;
	
	// Fill optional residuals.
	If TableSectionRow.Property("Percent") Then
		TableSectionRow.Percent = 0;
	EndIf;
	
EndProcedure

&AtClient
Procedure LineItemsUnitOnChange(Item)
	
	// Fill line data for editing.
	TableSectionRow = GetLineItemsRowStructure();
	FillPropertyValues(TableSectionRow, Items.LineItems.CurrentData);
	
	// Request server operation.
	CommonUnitOnChangeAtServer(TableSectionRow);
	
	// Load processed data back.
	FillPropertyValues(Items.LineItems.CurrentData, TableSectionRow);
	
	// Refresh totals cache.
	RecalculateResidualsAndTotals();
	
EndProcedure

&AtClient
Procedure ResidualsUnitOnChange(Item)
	
	// Fill line data for editing.
	TableSectionRow = GetResidualsRowStructure();
	FillPropertyValues(TableSectionRow, Items.ResidualsItems.CurrentData);
	
	// Request server operation.
	CommonUnitOnChangeAtServer(TableSectionRow);
	
	// Load processed data back.
	FillPropertyValues(Items.ResidualsItems.CurrentData, TableSectionRow);
	
	// Refresh totals cache.
	RecalculateTotals();
	
EndProcedure

&AtClient
Procedure ServicesUnitOnChange(Item)
	
	// Fill line data for editing.
	TableSectionRow = GetServicesRowStructure();
	FillPropertyValues(TableSectionRow, Items.ServicesItems.CurrentData);
	
	// Request server operation.
	CommonUnitOnChangeAtServer(TableSectionRow);
	
	// Load processed data back.
	FillPropertyValues(Items.ServicesItems.CurrentData, TableSectionRow);
	
	// Refresh totals cache.
	RecalculateTotals();
	
EndProcedure

&AtServer
Procedure CommonUnitOnChangeAtServer(TableSectionRow)
	
	// Calculate new unit price.
	If TableSectionRow.Property("Percent") Then
		// Residuals
		If Object.LineItems.Total("LineTotal") <= Object.LineItems.Total("WasteTotal") Then
			TableSectionRow.Percent    = 0;
			TableSectionRow.PriceUnits = 0;
		Else
			TableSectionRow.PriceUnits = Round(GeneralFunctions.ProductLastCost(TableSectionRow.Product) *
			                             ?(TableSectionRow.Unit.Factor > 0, TableSectionRow.Unit.Factor, 1),
			                             GeneralFunctionsReusable.PricePrecisionForOneItem(TableSectionRow.Product));
		EndIf;
	Else
		// LineItems
		TableSectionRow.PriceUnits = Round(GeneralFunctions.ProductLastCost(TableSectionRow.Product) *
		                             ?(TableSectionRow.Unit.Factor > 0, TableSectionRow.Unit.Factor, 1),
		                             GeneralFunctionsReusable.PricePrecisionForOneItem(TableSectionRow.Product));
	EndIf;
	
	// Process settings changes.
	CommonQuantityOnChangeAtServer(TableSectionRow);
	
EndProcedure

&AtClient
Procedure LineItemsQuantityOnChange(Item)
	
	// Fill line data for editing.
	TableSectionRow = GetLineItemsRowStructure();
	FillPropertyValues(TableSectionRow, Items.LineItems.CurrentData);
	
	// Request server operation.
	CommonQuantityOnChangeAtServer(TableSectionRow);
	
	// Load processed data back.
	FillPropertyValues(Items.LineItems.CurrentData, TableSectionRow);
	
	// Refresh totals cache.
	RecalculateResidualsAndTotals();
	
EndProcedure

&AtClient
Procedure ResidualsQuantityOnChange(Item)
	
	// Fill line data for editing.
	TableSectionRow = GetResidualsRowStructure();
	FillPropertyValues(TableSectionRow, Items.ResidualsItems.CurrentData);
	
	// Request server operation.
	CommonQuantityOnChangeAtServer(TableSectionRow);
	
	// Load processed data back.
	FillPropertyValues(Items.ResidualsItems.CurrentData, TableSectionRow);
	
	// Refresh totals cache.
	RecalculateTotals();
	
EndProcedure

&AtClient
Procedure ServicesQuantityOnChange(Item)
	
	// Fill line data for editing.
	TableSectionRow = GetServicesRowStructure();
	FillPropertyValues(TableSectionRow, Items.ServicesItems.CurrentData);
	
	// Request server operation.
	CommonQuantityOnChangeAtServer(TableSectionRow);
	
	// Load processed data back.
	FillPropertyValues(Items.ServicesItems.CurrentData, TableSectionRow);
	
	// Refresh totals cache.
	RecalculateTotals();
	
EndProcedure

&AtServer
Procedure CommonQuantityOnChangeAtServer(TableSectionRow)
	
	// Calculate total by line.
	TableSectionRow.LineTotal = Round(Round(TableSectionRow.QtyUnits, QuantityPrecision) *
	                            Round(TableSectionRow.PriceUnits,
	                            GeneralFunctionsReusable.PricePrecisionForOneItem(TableSectionRow.Product)), 2);
	
	// Process settings changes.
	CommonLineTotalOnChangeAtServer(TableSectionRow);
	
EndProcedure

&AtClient
Procedure LineItemsPriceOnChange(Item)
	
	// Fill line data for editing.
	TableSectionRow = GetLineItemsRowStructure();
	FillPropertyValues(TableSectionRow, Items.LineItems.CurrentData);
	
	// Request server operation.
	CommonPriceOnChangeAtServer(TableSectionRow);
	
	// Load processed data back.
	FillPropertyValues(Items.LineItems.CurrentData, TableSectionRow);
	
	// Refresh totals cache.
	RecalculateResidualsAndTotals();
	
EndProcedure

&AtClient
Procedure ResidualsPriceOnChange(Item)
	
	// Fill line data for editing.
	TableSectionRow = GetResidualsRowStructure();
	FillPropertyValues(TableSectionRow, Items.ResidualsItems.CurrentData);
	
	// Request server operation.
	CommonPriceOnChangeAtServer(TableSectionRow);
	
	// Load processed data back.
	FillPropertyValues(Items.ResidualsItems.CurrentData, TableSectionRow);
	
	// Refresh totals cache.
	RecalculateTotals();
	
EndProcedure

&AtClient
Procedure ServicesPriceOnChange(Item)
	
	// Fill line data for editing.
	TableSectionRow = GetServicesRowStructure();
	FillPropertyValues(TableSectionRow, Items.ServicesItems.CurrentData);
	
	// Request server operation.
	CommonPriceOnChangeAtServer(TableSectionRow);
	
	// Load processed data back.
	FillPropertyValues(Items.ServicesItems.CurrentData, TableSectionRow);
	
	// Refresh totals cache.
	RecalculateTotals();
	
EndProcedure

&AtServer
Procedure CommonPriceOnChangeAtServer(TableSectionRow)
	
	// Rounds price of product.
	TableSectionRow.PriceUnits = Round(TableSectionRow.PriceUnits, GeneralFunctionsReusable.PricePrecisionForOneItem(TableSectionRow.Product));
	
	// Calculate total by line.
	TableSectionRow.LineTotal  = Round(Round(TableSectionRow.QtyUnits, QuantityPrecision) *
	                             TableSectionRow.PriceUnits, 2);
	
	// Process settings changes.
	CommonLineTotalOnChangeAtServer(TableSectionRow);
	
EndProcedure

&AtClient
Procedure LineItemsLineTotalOnChange(Item)
	
	// Fill line data for editing.
	TableSectionRow = GetLineItemsRowStructure();
	FillPropertyValues(TableSectionRow, Items.LineItems.CurrentData);
	
	// Request server operation.
	CommonLineTotalOnChangeAtServer(TableSectionRow);
	
	// Back-step price calculation with totals priority (interactive change only).
	TableSectionRow.PriceUnits = ?(Round(TableSectionRow.QtyUnits, QuantityPrecision) > 0,
	                             Round(TableSectionRow.LineTotal / Round(TableSectionRow.QtyUnits, QuantityPrecision),
	                             GeneralFunctionsReusable.PricePrecisionForOneItem(TableSectionRow.Product)), 0);
	
	// Load processed data back.
	FillPropertyValues(Items.LineItems.CurrentData, TableSectionRow);
	
	// Refresh totals cache.
	RecalculateResidualsAndTotals();
	
EndProcedure

&AtClient
Procedure ResidualsLineTotalOnChange(Item)
	
	// Fill line data for editing.
	TableSectionRow = GetResidualsRowStructure();
	FillPropertyValues(TableSectionRow, Items.ResidualsItems.CurrentData);
	
	// Request server operation.
	CommonLineTotalOnChangeAtServer(TableSectionRow);
	
	// Back-step price calculation with totals priority (interactive change only).
	TableSectionRow.PriceUnits = ?(Round(TableSectionRow.QtyUnits, QuantityPrecision) > 0,
	                               Round(TableSectionRow.LineTotal / Round(TableSectionRow.QtyUnits, QuantityPrecision),
	                               GeneralFunctionsReusable.PricePrecisionForOneItem(TableSectionRow.Product)), 0);
	
	// Load processed data back.
	FillPropertyValues(Items.ResidualsItems.CurrentData, TableSectionRow);
	
	// Refresh totals cache.
	RecalculateTotals();
	
EndProcedure

&AtClient
Procedure ServicesLineTotalOnChange(Item)
	
	// Fill line data for editing.
	TableSectionRow = GetServicesRowStructure();
	FillPropertyValues(TableSectionRow, Items.ServicesItems.CurrentData);
	
	// Request server operation.
	CommonLineTotalOnChangeAtServer(TableSectionRow);
	
	// Back-step price calculation with totals priority (interactive change only).
	TableSectionRow.PriceUnits = ?(Round(TableSectionRow.QtyUnits, QuantityPrecision) > 0,
	                               Round(TableSectionRow.LineTotal / Round(TableSectionRow.QtyUnits, QuantityPrecision),
	                               GeneralFunctionsReusable.PricePrecisionForOneItem(TableSectionRow.Product)), 0);
	
	// Load processed data back.
	FillPropertyValues(Items.ServicesItems.CurrentData, TableSectionRow);
	
	// Refresh totals cache.
	RecalculateTotals();
	
EndProcedure

&AtServer
Procedure CommonLineTotalOnChangeAtServer(TableSectionRow)
	
	// Calculation of residuals percent.
	If TableSectionRow.Property("Percent") Then
		TableSectionRow.Percent = ?((Object.LineItems.Total("LineTotal") - Object.LineItems.Total("WasteTotal")) > 0,
		                             Round(TableSectionRow.LineTotal * 100 /
		                            (Object.LineItems.Total("LineTotal") - Object.LineItems.Total("WasteTotal")), 2), 0);
		
		// Update total cost if residuals took 0% of final assembly cost.
		If TableSectionRow.Percent = 0 Then
			TableSectionRow.PriceUnits = 0;
			TableSectionRow.LineTotal  = 0;
		EndIf;
	EndIf;
	
	// Process settings changes.
	If TableSectionRow.Property("WastePercent") Then
		LineItemsWastePercentOnChangeAtServer(TableSectionRow);
	EndIf;
	
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
	RecalculateResidualsAndTotals();
	
EndProcedure

&AtServer
Procedure LineItemsWastePercentOnChangeAtServer(TableSectionRow)
	
	// Calculate waste qty by line.
	TableSectionRow.WasteQtyUnits = Round(Round(TableSectionRow.QtyUnits, QuantityPrecision) *
	                                TableSectionRow.WastePercent / 100, QuantityPrecision);
	
	// Process settings changes.
	LineItemsWasteQuantityOnChangeAtServer(TableSectionRow);
	
EndProcedure

&AtClient
Procedure ResidualsPercentOnChange(Item)
	
	// Fill line data for editing.
	TableSectionRow = GetResidualsRowStructure();
	FillPropertyValues(TableSectionRow, Items.ResidualsItems.CurrentData);
	
	// Drop residuals percent if assembly cost is zero.
	If Object.LineItems.Total("LineTotal") <= Object.LineItems.Total("WasteTotal") Then
		TableSectionRow.Percent = 0;
	EndIf;
	
	// Back calculation of product cost and total.
	TableSectionRow.LineTotal  = ?(Round(TableSectionRow.QtyUnits, QuantityPrecision) > 0,
	                               Round((Object.LineItems.Total("LineTotal") - Object.LineItems.Total("WasteTotal")) *
	                                     TableSectionRow.Percent / 100, 2), 0);
	TableSectionRow.PriceUnits = ?(Round(TableSectionRow.QtyUnits, QuantityPrecision) > 0,
	                               Round(TableSectionRow.LineTotal / Round(TableSectionRow.QtyUnits, QuantityPrecision),
	                               GeneralFunctionsReusable.PricePrecisionForOneItem(TableSectionRow.Product)), 0);
	
	// Load processed data back.
	FillPropertyValues(Items.ResidualsItems.CurrentData, TableSectionRow);
	
	// Refresh totals cache.
	RecalculateTotals();
	
EndProcedure

&AtClient
Procedure LineItemsWasteQuantityOnChange(Item)
	
	// Fill line data for editing.
	TableSectionRow = GetLineItemsRowStructure();
	FillPropertyValues(TableSectionRow, Items.LineItems.CurrentData);
	
	// Back-step percent calculation with quantity priority (interactive change only).
	If TableSectionRow.QtyUnits = 0 Then
		// Base quantity is zeroed.
		TableSectionRow.WasteQtyUnits = 0;
		TableSectionRow.WastePercent  = 0;
		
	ElsIf TableSectionRow.WasteQtyUnits < TableSectionRow.QtyUnits Then
		// Normal percent calculation.
		TableSectionRow.WastePercent =  Round(TableSectionRow.WasteQtyUnits * 100 /
		                                Round(TableSectionRow.QtyUnits, QuantityPrecision), QuantityPrecision);
	Else
		// Wastes are 100%.
		TableSectionRow.WasteQtyUnits = TableSectionRow.QtyUnits;
		TableSectionRow.WastePercent  = 100;
	EndIf;
	
	// Request server operation.
	LineItemsWasteQuantityOnChangeAtServer(TableSectionRow);
	
	// Load processed data back.
	FillPropertyValues(Items.LineItems.CurrentData, TableSectionRow);
	
	// Refresh totals cache.
	RecalculateResidualsAndTotals();
	
EndProcedure

&AtServer
Procedure LineItemsWasteQuantityOnChangeAtServer(TableSectionRow)
	
	// Calculate waste total by line.
	TableSectionRow.WasteTotal = Round(Round(TableSectionRow.WasteQtyUnits, QuantityPrecision) *
	                             Round(TableSectionRow.PriceUnits,
	                             GeneralFunctionsReusable.PricePrecisionForOneItem(TableSectionRow.Product)), 2);
	
EndProcedure

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region PRIVATE_IMPLEMENTATION

//------------------------------------------------------------------------------
// Calculate totals and fill object attributes.

&AtClient
// The procedure recalculates the document's totals.
Procedure RecalculateTotals()
	
	// Assign totals to the object fields.
	// Reserved for future use.
	
EndProcedure

&AtClient
// The procedure recalculates the document's totals.
Procedure RecalculateResidualsAndTotals()
	
	// Calculate document totals.
	LineSubtotal  = Object.LineItems.Total("LineTotal");
	WasteSubtotal = Object.LineItems.Total("WasteTotal");
	
	// Recalculate residuals cost basing on changed assembly cost.
	For Each Row In Object.Residuals Do
		If LineSubtotal <= WasteSubtotal Then
			Row.Percent    = 0;
		EndIf;
		Row.LineTotal  = ?(Round(Row.QtyUnits, QuantityPrecision) > 0,
		                   Round((LineSubtotal - WasteSubtotal) * Row.Percent / 100, 2), 0);
		Row.PriceUnits = ?(Round(Row.QtyUnits, QuantityPrecision) > 0,
		                   Round(Row.LineTotal / Round(Row.QtyUnits, QuantityPrecision),
		                   GeneralFunctionsReusable.PricePrecisionForOneItem(Row.Product)), 0);
	EndDo;
	
EndProcedure

//------------------------------------------------------------------------------
// Replacemant for metadata properties on client.

&AtClient
// Returns fields structure of LineItems form control.
Function GetLineItemsRowStructure()
	
	// Define control row fields.
	Return New Structure("LineNumber, Product, ProductDescription, UnitSet, QtyUnits, Unit, PriceUnits, LineTotal, WastePercent, WasteQtyUnits, WasteTotal");
	
EndFunction

&AtClient
// Returns fields structure of Residuals form control.
Function GetResidualsRowStructure()
	
	// Define control row fields.
	Return New Structure("LineNumber, Product, ProductDescription, UnitSet, QtyUnits, Unit, Percent, PriceUnits, LineTotal");
	
EndFunction

&AtClient
// Returns fields structure of Services form control.
Function GetServicesRowStructure()
	
	// Define control row fields.
	Return New Structure("LineNumber, Product, ProductDescription, UnitSet, QtyUnits, Unit, PriceUnits, LineTotal");
	
EndFunction

&AtServerNoContext
Function GetInfPricePrecision(Item)
	
	Return New Structure("Constant, Item", Constants.PricePrecision.Get(), CommonUse.GetAttributeValue(Item, "PricePrecision"));
	
EndFunction

&AtServer
// Update prices presentation.
Procedure UpdatePricesPresentation()
	
	PriceFormat = GeneralFunctionsReusable.PriceFormatForOneItem(Object.Ref);
	Items.Price1.EditFormat          = PriceFormat;
	Items.Cost.EditFormat            = PriceFormat;
	Items.LastCost.EditFormat        = PriceFormat;
	Items.AverageCost.EditFormat     = PriceFormat;
	Items.AccountingCost.EditFormat  = PriceFormat;
	
EndProcedure

&AtServerNoContext
// Request owned lots/serial numbers presence.
Function HasDescendants(Ref)
	
	// Select lots and serial numbers of current item.
	QueryText = "
	|SELECT
	|	CASE WHEN Products.UseLotsType = 1
	|		 THEN Products.Characteristic
	|		 ELSE Products.Ref
	|	END AS Ref
	|INTO
	|	LotsOwner
	|FROM
	|	Catalog.Products AS Products
	|WHERE
	|	 Products.Ref = &Ref           // Current item
	|AND Products.HasLotsSerialNumbers // Use Lots or Serial numbers
	|AND Products.UseLots = 0;         // Use Lots
	|////////////////////////////////////////////////////////////////////////////
	|
	|SELECT TOP 1
	|	Lots.Ref AS LotSerialNumber
	|FROM
	|	Catalog.Lots AS Lots
	|	INNER JOIN LotsOwner AS LotsOwner
	|		ON Lots.Owner = LotsOwner.Ref
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	SerialNumbers.SerialNumber AS LotSerialNumber
	|FROM
	|	InformationRegister.SerialNumbers AS SerialNumbers
	|WHERE
	|	 SerialNumbers.Product = &Ref               // Current item
	|AND SerialNumbers.Product.HasLotsSerialNumbers // Use Lots or Serial numbers
	|AND SerialNumbers.Product.UseLots = 1          // Use Serial mumbers";
	
	// Create the data query.
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	Query.Text = QueryText;
	Query.SetParameter("Ref", Ref);
	
	// If found at least one owned item, then item has descendants.
	Return Not Query.ExecuteBatch()[1].IsEmpty();
	
EndFunction

#EndRegion
