
&AtServer
// Prefills default accounts, VAT codes, determines accounts descriptions, and sets field visibility
//
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
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
		Items.IncomeAcctLabel.Title = IncomeAcct.Description;
	ElsIf NOT Object.Ref.IsEmpty() Then
		Items.IncomeAcctLabel.Title = Object.IncomeAccount.Description;
	EndIf;
		
	If NOT Object.InventoryOrExpenseAccount.IsEmpty() Then
		Items.InventoryAcctLabel.Title = Object.InventoryOrExpenseAccount.Description;
	EndIf;
	
	If Object.Type <> Enums.InventoryTypes.Inventory Then
		//Items.COGSAccount.ReadOnly = True;
	EndIf;
	
	If Object.PurchaseVATCode.IsEmpty() AND Object.Ref.IsEmpty() Then
		Object.PurchaseVATCode = Constants.DefaultPurchaseVAT.Get();
	EndIf;
	
	If Object.SalesVATCode.IsEmpty() AND Object.Ref.IsEmpty() Then
		Object.SalesVATCode = Constants.DefaultSalesVAT.Get();
	EndIf;
	
	// Display indicators
	If ValueIsFilled(Object.Ref) Then
		
		// Fill last item cost
		If  (Object.Type = Enums.InventoryTypes.Inventory) Then
			// Fill item cost values
			FillLastAverageAccountingCost();
		EndIf;
		
		// Fill item quantities
		FillItemQuantity_OnPO_OnSO_OnHand_AvailableToPromise();
		
		// Update visibility
		ChildItems.Indicators.Visible = True;
		IsInventoryType = (Object.Type = Enums.InventoryTypes.Inventory);
		ChildItems.Indicators.ChildItems.Left.Visible = IsInventoryType;
		ChildItems.Indicators.ChildItems.Right.ChildItems.QtyOnHand.Visible = IsInventoryType;
		ChildItems.Indicators.ChildItems.Right.ChildItems.QtyAvailableToPromise.Visible = IsInventoryType;
	Else
		// New item: hide indicators
		ChildItems.Indicators.Visible = False;
	EndIf;
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
		
	If  (Object.Type = Enums.InventoryTypes.Inventory) Then
		// Fill item cost values
		FillLastAverageAccountingCost();
	EndIf;
	
	// Fill item quantities
	FillItemQuantity_OnPO_OnSO_OnHand_AvailableToPromise();
	
	// Update visibility
	ChildItems.Indicators.Visible = True;
	IsInventoryType = (Object.Type = Enums.InventoryTypes.Inventory);
	ChildItems.Indicators.ChildItems.Left.Visible = IsInventoryType;
	ChildItems.Indicators.ChildItems.Right.ChildItems.QtyOnHand.Visible = IsInventoryType;
	ChildItems.Indicators.ChildItems.Right.ChildItems.QtyAvailableToPromise.Visible = IsInventoryType;
	
	AddPriceList();

	
EndProcedure

&AtServer
Procedure FillLastAverageAccountingCost()
	
	// Default values for new item (or item without lots - no goods recepts / purchase invoices occured)
	LastCost = 0;
	AverageCost = 0;
	AccountingCost = 0;
		
	// Check object is new
	If ValueIsFilled(Object.Ref) Then
	
		// Define query for all types of cost
		QTItemLastCost = "
			|// Last item cost from information register ItemLastCost
			|SELECT
			|	ItemLastCost.Cost AS Cost
			|INTO
			|	LastCost
			|FROM
			|	InformationRegister.ItemLastCost AS ItemLastCost
			|WHERE
			|	ItemLastCost.Product = &Ref;";
		
		QTItemAverageCost = "
			|// Average cost, based on all availble stock
			|SELECT
			|	CASE WHEN InventoryJrnlBalance.QtyBalance <= 0 THEN 0
			|		 ELSE CAST(InventoryJrnlBalance.AmountBalance / InventoryJrnlBalance.QtyBalance AS Number(15, 2)) END AS Cost
			|INTO
			|	AverageCost
			|FROM
			|	AccumulationRegister.InventoryJrnl.Balance(&Boundary, Product = &Ref) AS InventoryJrnlBalance;";
		
		QTItemAccountingFirstLastCost = "
			|// Current accounting cost => First / Last lot item cost
			|SELECT TOP 1
			|	CASE WHEN InventoryJrnlBalance.QtyBalance <= 0 THEN 0
			|		 ELSE CAST(InventoryJrnlBalance.AmountBalance / InventoryJrnlBalance.QtyBalance AS Number(15, 2)) END AS Cost,
			|	InventoryJrnlBalance.Layer AS Layer
			|INTO
			|	AccountingCost
			|FROM
			|	AccumulationRegister.InventoryJrnl.Balance(&Boundary, Product = &Ref) AS InventoryJrnlBalance
			|ORDER BY
			|	InventoryJrnlBalance.Layer.PointInTime %1;";
		
		Query = New Query(
			// Last item cost from information register ItemLastCost
			QTItemLastCost + 	// INTO LastCost.Cost
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
			|	ISNULL(LastCost.Cost, 0) AS Cost
			|
			|UNION ALL
			|SELECT
			|	ISNULL(AverageCost.Cost, 0)" +
			//?(Object.CostingMethod = Enums.InventoryCosting.FIFO OR Object.CostingMethod = Enums.InventoryCosting.LIFO, "
			?(Object.CostingMethod = Enums.InventoryCosting.FIFO, "
			|
			|UNION ALL
			|SELECT
			|	ISNULL(AccountingCost.Cost, 0)",""));
			
		Query.SetParameter("Boundary", New Boundary(EndOfDay(CurrentSessionDate()), BoundaryType.Including));
		Query.SetParameter("Ref", Object.Ref);
		
		// Execute query and read costs
		Selection = Query.Execute().Choose();
		// Last cost
		If Selection.Next() Then LastCost = Selection.Cost;	Else LastCost = 0; EndIf;
		// Average cost
		If Selection.Next() Then AverageCost = Selection.Cost;	Else AverageCost = 0; EndIf;
		// Accounting cost
		//If (Object.CostingMethod = Enums.InventoryCosting.FIFO OR Object.CostingMethod = Enums.InventoryCosting.LIFO) And Selection.Next() Then
		If Object.CostingMethod = Enums.InventoryCosting.FIFO And Selection.Next() Then
			AccountingCost = Selection.Cost;
		Else
			AccountingCost = AverageCost;
		EndIf;
		
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
		|	CASE WHEN &Type = VALUE(Enum.InventoryTypes.Inventory)
		|             THEN CASE WHEN OrdersDispatchedBalance.QuantityBalance - OrdersDispatchedBalance.ReceivedBalance > 0
		|	                    THEN OrdersDispatchedBalance.QuantityBalance - OrdersDispatchedBalance.ReceivedBalance 
		|	                    ELSE 0 END
		|        WHEN &Type = VALUE(Enum.InventoryTypes.NonInventory)
		|             THEN CASE WHEN OrdersDispatchedBalance.QuantityBalance - OrdersDispatchedBalance.InvoicedBalance > 0
		|	                    THEN OrdersDispatchedBalance.QuantityBalance - OrdersDispatchedBalance.InvoicedBalance 
		|	                    ELSE 0 END
		|        ELSE 0 END                   AS QtyOnPO,
		|	0                                 AS QtyOnSO,
		|	0                                 AS QtyOnHand
		|INTO
		|	Table_OrdersDispatched_OrdersRegistered_InventoryJrnl
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
		|	0,
		|	CASE WHEN &Type = VALUE(Enum.InventoryTypes.Inventory)
		|             THEN CASE WHEN OrdersRegisteredBalance.QuantityBalance - OrdersRegisteredBalance.ShippedBalance > 0
		|	                    THEN OrdersRegisteredBalance.QuantityBalance - OrdersRegisteredBalance.ShippedBalance 
		|	                    ELSE 0 END
		|        WHEN &Type = VALUE(Enum.InventoryTypes.NonInventory)
		|             THEN CASE WHEN OrdersRegisteredBalance.QuantityBalance - OrdersRegisteredBalance.InvoicedBalance > 0
		|	                    THEN OrdersRegisteredBalance.QuantityBalance - OrdersRegisteredBalance.InvoicedBalance 
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
		// QtyOnHand = Inventory.Qty(0) 
		|	NULL,
		|	NULL,
		|	InventoryJrnlBalance.Product,
		|	0,
		|	0,
		|	CASE WHEN &Type = VALUE(Enum.InventoryTypes.Inventory)
		|	          THEN InventoryJrnlBalance.QtyBalance
		|        WHEN &Type = VALUE(Enum.InventoryTypes.NonInventory)
		|             THEN 0
		|        ELSE 0 END
		|FROM
		|	AccumulationRegister.InventoryJrnl.Balance(, Product = &Ref) AS InventoryJrnlBalance";
		QueryText   = QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
		QueryTables = QueryTables + 1;
		
		// Group data by product accumulating quantities by different companies and orders
		QueryText = QueryText +
		"SELECT
		|	TableBalances.Product        AS Product,
		|	SUM(TableBalances.QtyOnPO)   AS QtyOnPO,
		|	SUM(TableBalances.QtyOnSO)   AS QtyOnSO,
		|	SUM(TableBalances.QtyOnHand) AS QtyOnHand,
		|	CASE WHEN &Type = VALUE(Enum.InventoryTypes.Inventory)
		|             THEN CASE WHEN SUM(TableBalances.QtyOnHand) + SUM(TableBalances.QtyOnPO) - SUM(TableBalances.QtyOnSO) > 0
		|	                    THEN SUM(TableBalances.QtyOnHand) + SUM(TableBalances.QtyOnPO) - SUM(TableBalances.QtyOnSO)
		|		                ELSE 0 END
		|        WHEN &Type = VALUE(Enum.InventoryTypes.NonInventory)
		|             THEN 0
		|        ELSE 0 END              AS QtyAvailableToPromise
		|FROM
		|	Table_OrdersDispatched_OrdersRegistered_InventoryJrnl AS TableBalances
		|GROUP BY
		|	TableBalances.Product";
		QueryText   = QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
		QueryTables = QueryTables + 1;
		
		// Execute query
		Query.Text  = QueryText;
		QueryResult = Query.ExecuteBatch();
		
		// Fill form attributes with query result
		Selection   = QueryResult[QueryTables].Choose();
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
		Items.COGSAcctLabel.Title = CommonUse.GetAttributeValue(Object.COGSAccount, "Description");
		
		Acct = GeneralFunctions.InventoryAcct(NewItemType);
		AccountDescription = CommonUse.GetAttributeValue(Acct, "Description");
		Object.InventoryOrExpenseAccount = Acct;
		Items.InventoryAcctLabel.Title = AccountDescription;
		Items.CostingMethod.ReadOnly = False;
		
	EndIf;
	
	If (NOT GeneralFunctions.InventoryType(NewItemType)) AND Object.Ref.IsEmpty() Then
		Items.CostingMethod.Visible = False;
		Items.DefaultLocation.ReadOnly = True;
		Items.InventoryOrExpenseAccount.Title = "Expense account";
		Items.COGSAccount.ReadOnly = True;
		
		Acct = GeneralFunctions.InventoryAcct(NewItemType);
		AccountDescription = CommonUse.GetAttributeValue(Acct, "Description");
		Object.InventoryOrExpenseAccount = Acct;
		Items.InventoryAcctLabel.Title = AccountDescription;
		Object.COGSAccount = GeneralFunctions.GetEmptyAcct();
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

&AtClient
// Determines an account description
//
Procedure InventoryOrExpenseAccountOnChange(Item)
	
	Items.InventoryAcctLabel.Title =
		CommonUse.GetAttributeValue(Object.InventoryOrExpenseAccount, "Description");
		
EndProcedure

&AtClient
// Determines an account description
//
Procedure IncomeAccountOnChange(Item)
	
	Items.IncomeAcctLabel.Title =
		CommonUse.GetAttributeValue(Object.IncomeAccount, "Description");
		
EndProcedure

&AtClient
// Determines an account description
//
Procedure COGSAccountOnChange(Item)
	
	Items.COGSAcctLabel.Title =
		CommonUse.GetAttributeValue(Object.COGSAccount, "Description");	
		
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// Doesn't allow to save an inventory product type without a set costing type
	
	If Object.Type = Enums.InventoryTypes.Inventory Then
		
		If Object.CostingMethod.IsEmpty() Then
			Message = New UserMessage();
			Message.Text=NStr("en='Costing method field is empty'");
			Message.Field = "Object.CostingMethod";
			Message.Message();
			Cancel = True;
			Return;
		EndIf;
		
		If Object.COGSAccount.IsEmpty() Then
			
			Message = New UserMessage();
			Message.Text=NStr("en='COGS account is empty'");
			Message.Field = "Object.COGSAccount";
			Message.Message();
			Cancel = True;
			Return;
			
		EndIf;
		
		If Object.InventoryOrExpenseAccount.IsEmpty() Then
			
			Message = New UserMessage();
			Message.Text=NStr("en='Inventory account is empty'");
			Message.Field = "Object.InventoryOrExpenseAccount";
			Message.Message();
			Cancel = True;
			Return;
			
		EndIf;

		
	EndIf;
		
EndProcedure

//&AtClient
//Procedure BeforeWrite(Cancel, WriteParameters)
//	
//	WriteAPICode();				
//EndProcedure

&AtServer
Procedure AddPriceList()
	
	LastPrice = GeneralFunctions.RetailPrice(CurrentDate(), Object.Ref, Catalogs.Companies.EmptyRef());
	If LastPrice <> Price Then
		
			RecordSet = InformationRegisters.PriceList.CreateRecordSet();
			RecordSet.Filter.Product.Set(Object.Ref);
			RecordSet.Filter.Period.Set(CurrentDate());
			RecordSet.Read();
			NewRecord = RecordSet.Add();
			NewRecord.Period = CurrentDate();
			NewRecord.Product = Object.Ref;
			NewRecord.PriceType = "Item";
			NewRecord.Price = Price;
			RecordSet.Write();

			   		
	Endif;

	
EndProcedure

//&AtServer
//Procedure WriteAPICode()
//	
//	If Object.Ref = Catalogs.Products.EmptyRef() Then
//		Object.api_code = GeneralFunctions.NextProductNumber();
//	EndIf;

//	
//EndProcedure






