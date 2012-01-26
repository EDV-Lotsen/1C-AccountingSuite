//////////////////////////////////////////////////////////////////////////////// 
// THIS MODULE CONTAINS FUNCTIONS AND PROCEDURES USED
// FOR INVENTORY COSTING
// 

// Note that everywhere in the system items are called Products. However
// the synonym field for Products is Item. Also everywhere in the user
// documentation the term Item is used. This is done to avoid confusion
// with the system's predefined Item/Items objects (form elements).
// The same applies to item's description which is called Descr to avoid
// confusion with the default description property of the item object
// (which is used for ItemID).


// The function creates a dataset that is used in sales documents for inventory layer and inventory
// costing processing.
//
// Parameters:
// Document that is requesting the dataset.
// Catalog.Locations - warehouse location from the document.
//
// Returned value:
// ValueTable.
//
Function SalesDocumentsDataset(Ref, Location) Export
	
	If TypeOf(Ref) = Type("DocumentRef.SalesInvoice") Then DocType = "SalesInvoice" EndIf;
	If TypeOf(Ref) = Type("DocumentRef.CashSale") Then DocType = "CashSale" EndIf;
	If TypeOf(Ref) = Type("DocumentRef.GoodsIssue") Then DocType = "GoodsIssue" EndIf;
	If TypeOf(Ref) = Type("DocumentRef.PurchaseReturn") Then DocType = "PurchaseReturn" EndIf;
	
	// The first query batch selects all inventory items from the document's line items
	// Results of the first query batch are joined with the results of the second query batch
	// to return only a subset of the inventory journal for the document's items.
	//
	// The second query batch for weighted average costing items returns all layers with
	// remaining balances (QtyIn > QtyOut). Layer tracking / costing for weighted average
	// items is done on a company wide basis (not by warehouse locations).
	// For FIFO/LIFO items the batch returns all layers with remaining balances (QtyIn > QtyOut)
	// for the document's location.
	
	Query = New Query("SELECT
	|	" + DocType + "LineItems.Product
	|INTO DocProducts
	|FROM
	|	Document." + DocType + ".LineItems AS " + DocType + "LineItems
	|WHERE
	|	" + DocType + "LineItems.Ref = &Ref AND
	|	" + DocType + "LineItems.Product.Type = VALUE(Enum.InventoryTypes.Inventory)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InventoryJournal.Product,
	|	InventoryJournal.Document,
	|	InventoryJournal.QtyIn,
	|	InventoryJournal.QtyOut,
	|	InventoryJournal.QtyOnHand,
	|	InventoryJournal.DocCost,
	|	InventoryJournal.AdjCost,
	|	InventoryJournal.Row,
	|	InventoryJournal.Date
	|FROM
	|	DocProducts AS DocProducts
	|		LEFT JOIN InformationRegister.InventoryJournal AS InventoryJournal
	|		ON InventoryJournal.Product = DocProducts.Product
	|WHERE
	|	InventoryJournal.QtyIn > InventoryJournal.QtyOut
	|	AND InventoryJournal.Product.CostingMethod = VALUE(Enum.InventoryCosting.WeightedAverage)
	|
	|UNION ALL
	|
	|SELECT
	|	InventoryJournal.Product,
	|	InventoryJournal.Document,
	|	InventoryJournal.QtyIn,
	|	InventoryJournal.QtyOut,
	|	InventoryJournal.QtyOnHand,
	|	InventoryJournal.DocCost,
	|	InventoryJournal.AdjCost,
	|	InventoryJournal.Row,
	|	InventoryJournal.Date
	|FROM
	|	DocProducts AS DocProducts
	|		LEFT JOIN InformationRegister.InventoryJournal AS InventoryJournal
	|		ON InventoryJournal.Product = DocProducts.Product
	|WHERE
	|	(InventoryJournal.QtyIn > InventoryJournal.QtyOut
	|				AND InventoryJournal.Product.CostingMethod = VALUE(Enum.InventoryCosting.FIFO)
	|			OR InventoryJournal.Product.CostingMethod = VALUE(Enum.InventoryCosting.LIFO)
	|				AND InventoryJournal.Location = &Location)");
	
	Query.SetParameter("Ref", Ref);
	Query.SetParameter("Location", Location);
	QueryResult = Query.Execute();
    InvDataset = QueryResult.Unload();	
	Return InvDataset;
	
EndFunction

// The function creates a dataset that is used in purchase documents for inventory layer and inventory
// costing processing.
//
// Parameters:
// Document that is requesting the dataset.
// Date.
//
// Returned value:
// ValueTable.
//
Function PurchaseDocumentsDataset(Ref, DocDate) Export
	
	If TypeOf(Ref) = Type("DocumentRef.PurchaseInvoice") Then DocType = "PurchaseInvoice" EndIf;
	If TypeOf(Ref) = Type("DocumentRef.CashPurchase") Then DocType = "CashPurchase" EndIf;
	If TypeOf(Ref) = Type("DocumentRef.GoodsReceipt") Then DocType = "GoodsReceipt" EndIf;
	If TypeOf(Ref) = Type("DocumentRef.SalesReturn") Then DocType = "SalesReturn" EndIf;
	
	// The first query batch selects all inventory items from the document's line items
	// Results of the first query batch are joined with the results of the second query batch
	// to return only a subset of the inventory journal for the document's items.
	//
	// The second query batch select all layers after the document's date.
	
	Query = New Query("SELECT
	|	" + DocType + "LineItems.Product
	|INTO DocProducts
	|FROM
	|	Document." + DocType + ".LineItems AS " + DocType + "LineItems
	|WHERE
	|	" + DocType + "LineItems.Ref = &Ref AND
	|   " + DocType + "LineItems.Product.Type = VALUE(Enum.InventoryTypes.Inventory) AND
	|   " + DocType + "LineItems.Product.CostingMethod = VALUE(Enum.InventoryCosting.WeightedAverage)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InventoryJournal.Product,
	|	InventoryJournal.Document,
	|	InventoryJournal.QtyIn,
	|	InventoryJournal.QtyOut,
	|	InventoryJournal.QtyOnHand,
	|	InventoryJournal.DocCost,
	|	InventoryJournal.AdjCost,
	|	InventoryJournal.Row,
	|	InventoryJournal.Date
	|FROM
	|	DocProducts AS DocProducts
	|		LEFT JOIN InformationRegister.InventoryJournal AS InventoryJournal
	|		ON InventoryJournal.Product = DocProducts.Product
	|WHERE
	|	InventoryJournal.Date > &DocDate");
	
	Query.SetParameter("Ref", Ref);
	Query.SetParameter("DocDate", DocDate);
	QueryResult = Query.Execute();
    InvDataset = QueryResult.Unload();	
	Return InvDataset;
	
EndFunction

// The function returns total inventory balance (all locations) used in inventory costing
// calculations for weighted average costing items.
//
// Parameters:
// Catalogs.Products.
//
// Returned value:
// Number.
//
Function TotalOnHandAv(Product) Export
	
	// Inventory costing for average costing items is done on the company-wide
	// basis (irrespectively of locations) so the function returns a 
	// balance from the Inventory Journal. Ordering by date and row
	// is necessary to retrieve the latest row in the journal.
	
	// Alternatively the balance for average costing items can be calculated
	// by adding up all balances from the Location Balances journal.
	
	Query = New Query("SELECT
					  |	InventoryJournal.QtyOnHand
					  |FROM
					  |	InformationRegister.InventoryJournal AS InventoryJournal
					  |WHERE
					  |	InventoryJournal.Product = &Product
					  |
					  |ORDER BY
					  |	InventoryJournal.Date,
					  |	InventoryJournal.Row");
					  
	Query.SetParameter("Product", Product);	
	QueryResult = Query.Execute();

	If QueryResult.IsEmpty() Then	
		Return 0;	
	Else
		Dataset = QueryResult.Unload();
		Last = Dataset.Count();
		Result = Dataset[Last-1][0];
		If Result = Null Then
			Return 0;
		Else
			Return Result;
		EndIf;
	EndIf;
		
EndFunction


// The function returns the last adjusted item cost. It will always
// be the last row in the Inventory Journal for this item.
//
// Parameters:
// Catalog.Products.
//
// Returned value:
// Number.
//
Function LastCost(Product) Export
	
	Query = New Query("SELECT
	                  |	InventoryJournal.AdjCost
	                  |FROM
	                  |	InformationRegister.InventoryJournal AS InventoryJournal
	                  |WHERE
	                  |	InventoryJournal.Product = &Product
	                  |
	                  |ORDER BY
	                  |	InventoryJournal.Date,
	                  |	InventoryJournal.Row");
					   
	Query.SetParameter("Product", Product);	
	QueryResult = Query.Execute();

	If QueryResult.IsEmpty() Then	
		Return 0;	
	Else
		Dataset = QueryResult.Unload();
		Last = Dataset.Count();
		Return Dataset[Last-1][0]; 
	EndIf;		
	
EndFunction

// The function returns an item's quantity on hand on a particular date
// in a particular location. Since the location column in the Inventory Journal
// is not filled in for average costing items the query returns a result
// on company-wide basis (irrespectively of locations) for average costing
// items.
//
// Parameters:
// Catalog.Products.
// Catalog.Locations.
// Date.
//
// Returned value:
// Number.
//
Function QtyOnHand_OnDate(Product, Location, Date) Export
	
	Query = New Query("SELECT
	                  |	InventoryJournal.QtyOnHand
	                  |FROM
	                  |	InformationRegister.InventoryJournal AS InventoryJournal
	                  |WHERE
	                  |	InventoryJournal.Product = &Product
	                  |	AND InventoryJournal.Location = &Location
	                  |	AND InventoryJournal.Date < &Date");
					   
	Query.SetParameter("Product", Product);	
	Query.SetParameter("Location", Location);
	Query.SetParameter("Date", Date);
	QueryResult = Query.Execute();

	If QueryResult.IsEmpty() Then	
		Return 0;	
	Else
		Dataset = QueryResult.Unload();
		Last = Dataset.Count();
		Return Dataset[Last-1][0]; 
	EndIf;	

EndFunction

// The function returns a value of all item's layers with remaining quantity
// prior to a particular layer (defined as a day and an offset within a day).
//
// Parameters:
// Catalog.Products.
// Catalog.Locations.
// Date.
// Number - offset in Rows within a day.
//
// Returned value:
// Number.
//
Function PreviousLayersValue(Product, Location, Date, Offset) Export
		
	Query = New Query("SELECT
	                  |	InventoryJournal.QtyOnHand,
	                  |	InventoryJournal.AdjCost
	                  |FROM
	                  |	InformationRegister.InventoryJournal AS InventoryJournal
	                  |WHERE
	                  |	InventoryJournal.Product = &Product
	                  |	AND InventoryJournal.Date <= &Date
	                  |
	                  |ORDER BY
	                  |	InventoryJournal.Date,
	                  |	InventoryJournal.Row");
					   
	Query.SetParameter("Product", Product);	
	Query.SetParameter("Date", Date);
	QueryResult = Query.Execute();

	If QueryResult.IsEmpty() Then
		Return 0;	
	Else
		Dataset = QueryResult.Unload();
		Last = Dataset.Count();
		Qty = Dataset[Last-1-Offset].QtyOnHand;
		Cost = Dataset[Last-1-Offset].AdjCost;
		Return Qty * Cost;
	EndIf;	
	
EndFunction

// The function returns a sum of quantities of hand of all item's layers with
// remaining quantity prior to a particular layer
// (defined as a day and an offset within a day).
//
// Parameters:
// Catalog.Products.
// Catalog.Locations.
// Date.
// Number - offset in Rows within a day.
//
// Returned value:
// Number.
//
Function PreviousLayersQty(Product, Location, Date, Offset) Export
		
	Query = New Query("SELECT
	                  |	InventoryJournal.QtyOnHand
	                  |FROM
	                  |	InformationRegister.InventoryJournal AS InventoryJournal
	                  |WHERE
	                  |	InventoryJournal.Product = &Product
	                  |	AND InventoryJournal.Date <= &Date
	                  |
	                  |ORDER BY
	                  |	InventoryJournal.Date,
	                  |	InventoryJournal.Row");
					   
	Query.SetParameter("Product", Product);	
	Query.SetParameter("Date", Date);
	QueryResult = Query.Execute();

	If QueryResult.IsEmpty() Then
		Return 0;	
	Else
		Dataset = QueryResult.Unload();
		Last = Dataset.Count();
		RowNumber = Dataset[Last-1-Offset][0];
		Return RowNumber;
	EndIf;	
	
EndFunction

// The function returns an item's last layer Row withing a day and a location.
//
// Rows are used for ordering layers withing a day. Row numbers grow within
// a day for a particular item within a location for FIFO/LIFO costing items, and
// company-wide for average costing items.
//
// Parameters:
// Catalog.Products.
// Catalog.Locations.
// Date.
//
// Returned value:
// Number.
//
Function GetLastRowNumber(Product, Location, Date) Export
	
	If Product.CostingMethod = Enums.InventoryCosting.WeightedAverage Then
	
		Query = New Query("SELECT
		                  |	InventoryJournal.Row
		                  |FROM
		                  |	InformationRegister.InventoryJournal AS InventoryJournal
		                  |WHERE
		                  |	InventoryJournal.Product = &Product
		                  |	AND InventoryJournal.Date = &Date
		                  |
		                  |ORDER BY
		                  |	InventoryJournal.Date,
		                  |	InventoryJournal.Row");
						   
		Query.SetParameter("Product", Product);		
		Query.SetParameter("Date", Date);
		QueryResult = Query.Execute();

		If QueryResult.IsEmpty() Then
			Return 0;	
		Else
			Dataset = QueryResult.Unload();
			Last = Dataset.Count();
			RowNumber = Dataset[Last-1][0];
			Return RowNumber;
		EndIf;	
		
	Else
		
		Query = New Query("SELECT
		                  |	InventoryJournal.Row
		                  |FROM
		                  |	InformationRegister.InventoryJournal AS InventoryJournal
		                  |WHERE
		                  |	InventoryJournal.Product = &Product
		                  |	AND InventoryJournal.Location = &Location
		                  |	AND InventoryJournal.Date = &Date
		                  |
		                  |ORDER BY
		                  |	InventoryJournal.Date,
		                  |	InventoryJournal.Row");
						   
		Query.SetParameter("Product", Product);		
		Query.SetParameter("Location", Location);
		Query.SetParameter("Date", Date);
		QueryResult = Query.Execute();

		If QueryResult.IsEmpty() Then
			Return 0;	
		Else
			Dataset = QueryResult.Unload();
			Last = Dataset.Count();
			RowNumber = Dataset[Last-1][0];
			Return RowNumber;
		EndIf;
		
	EndIf;
	
EndFunction

// The function is a second step in the sales document processing. The function takes
// a document line item, and a subset of the Inventory Journal created by the
// SalesDocumentDataset function, calculates inventory costing, and makes inventory
// cost adjustments.
//
// Parameters:
// DocumentTabularSectionRow.
// Array.
// Catalog.Locations.
//
// Returned value:
// Number.
//
Function SalesDocumentProcessing(CurRowLineItems, InvDatasetProduct, Location) Export
	
		PostingCost = 0;
	
		If CurRowLineItems.Product.CostingMethod = Enums.InventoryCosting.WeightedAverage Then
					
			NoOfRows = 0;
			NoOfRows = InvDatasetProduct.Count();
			
			Remaining = CurRowLineItems.Quantity;
			OnHand = 0;
			
			For i = 0 To NoOfRows - 1 Do
								
				If ((InvDatasetProduct[i].QtyIn - InvDatasetProduct[i].QtyOut) - Remaining) < 0 Then
					
					// if the layer can't fulfill the remaining quantity
					
					Reg = InformationRegisters.InventoryJournal.CreateRecordSet();
					Reg.Filter.Document.Set(InvDatasetProduct[i].Document);
					Reg.Filter.Product.Set(InvDatasetProduct[i].Product);
					Reg.Read();
					Out = Reg[0].QtyIn - Reg[0].QtyOut;
					Reg[0].QtyOut = Reg[0].QtyIn;
					OnHand = OnHand + Reg[0].QtyIn - Reg[0].QtyOut;
					Reg[0].QtyOnHand = OnHand;
					PostingCost = PostingCost + Reg[0].AdjCost * Out;
					Reg.Write();
					
				Else
					
					// if the layer can fulfill the remaining quantity
					
					// also when the quantity is fulfilled adjust costs of remaining weighed average item
					// layers as (previous layers value + current layer value)/(previous layers qty + current layer qty)
					
					Reg = InformationRegisters.InventoryJournal.CreateRecordSet();
					Reg.Filter.Document.Set(InvDatasetProduct[i].Document);
					Reg.Filter.Product.Set(InvDatasetProduct[i].Product);
					Reg.Read();
					Out = Remaining;
					Reg[0].QtyOut = Reg[0].QtyOut + Remaining;
					OnHand = OnHand + Reg[0].QtyIn - Reg[0].QtyOut;
					Reg[0].QtyOnHand = OnHand;
					If Out = 0 Then
						AdjCost = InvDatasetProduct[i].AdjCost;						
						AdjCost = (InventoryCosting.PreviousLayersValue(InvDatasetProduct[i].Product, Location,
							InvDatasetProduct[i].Date, InvDatasetProduct[i].Row - 1) + InvDatasetProduct[i].QtyIn *
							InvDatasetProduct[i].DocCost) / (InventoryCosting.PreviousLayersQty(InvDatasetProduct[i].Product,
							Location, InvDatasetProduct[i].Date, InvDatasetProduct[i].Row - 1) + InvDatasetProduct[i].QtyIn);
						Reg[0].AdjCost = AdjCost;
					EndIf;
					If Out > 0 Then
						PostingCost = PostingCost + Reg[0].AdjCost * Out;
					EndIf;
					Reg.Write();

				EndIf;		
				
				Remaining = Remaining - Out;
			
			EndDo;
		EndIf;
		
		If CurRowLineItems.Product.CostingMethod = Enums.InventoryCosting.FIFO Then

			NoOfRows = 0;
			NoOfRows = InvDatasetProduct.Count();

			Remaining = CurRowLineItems.Quantity;
			
			For i = 0 To NoOfRows - 1 Do

				If ((InvDatasetProduct[i].QtyIn - InvDatasetProduct[i].QtyOut) - Remaining) < 0 Then
					
					// if the layer can't fulfill the remaining quantity
					
					Reg = InformationRegisters.InventoryJournal.CreateRecordSet();
					Reg.Filter.Document.Set(InvDatasetProduct[i].Document);
					Reg.Filter.Product.Set(InvDatasetProduct[i].Product);
					Reg.Read();
					Out = Reg[0].QtyIn - Reg[0].QtyOut;
					Reg[0].QtyOut = Reg[0].QtyIn;
					PostingCost = PostingCost + Reg[0].AdjCost * Out;
					Reg.Write();
					
				Else
					
					// if the layer can fulfill the remaining quantity
					
					Reg = InformationRegisters.InventoryJournal.CreateRecordSet();
					Reg.Filter.Document.Set(InvDatasetProduct[i].Document);
					Reg.Filter.Product.Set(InvDatasetProduct[i].Product);
					Reg.Read();
					Out = Remaining;
					Reg[0].QtyOut = Reg[0].QtyOut + Remaining;
					PostingCost = PostingCost + Reg[0].AdjCost * Out;
					Reg.Write();

				EndIf;		
				
				Remaining = Remaining - Out;
				
			EndDo;
			
		EndIf;
		
		If CurRowLineItems.Product.CostingMethod = Enums.InventoryCosting.LIFO Then

			NoOfRows = 0;
			NoOfRows = InvDatasetProduct.Count();

			Remaining = CurRowLineItems.Quantity;
			
			For i = 0 To NoOfRows - 1 Do

				If ((InvDatasetProduct[i].QtyIn - InvDatasetProduct[i].QtyOut) - Remaining) < 0 Then
					
					// if the layer can't fulfill the remaining quantity
					
					Reg = InformationRegisters.InventoryJournal.CreateRecordSet();
					Reg.Filter.Document.Set(InvDatasetProduct[i].Document);
					Reg.Filter.Product.Set(InvDatasetProduct[i].Product);
					Reg.Read();
					Out = Reg[0].QtyIn - Reg[0].QtyOut;
					Reg[0].QtyOut = Reg[0].QtyIn;
					PostingCost = PostingCost + Reg[0].AdjCost * Out;
					Reg.Write();
					
				Else
					
					// if the layer can fulfill the remaining quantity
					
					Reg = InformationRegisters.InventoryJournal.CreateRecordSet();
					Reg.Filter.Document.Set(InvDatasetProduct[i].Document);
					Reg.Filter.Product.Set(InvDatasetProduct[i].Product);
					Reg.Read();
					Out = Remaining;
					Reg[0].QtyOut = Reg[0].QtyOut + Remaining;
					PostingCost = PostingCost + Reg[0].AdjCost * Out;
					Reg.Write();

				EndIf;		
				
				Remaining = Remaining - Out;
				
			EndDo;
			
		EndIf;

		Return PostingCost;
		
EndFunction

// The function is a second step in the purchase document processing. The function takes
// a document line item, and a subset of the Inventory Journal created by the
// PurchaseDocumentDataset function, creates an inventory layer, calculates inventory costing, and makes inventory
// cost adjustments.
//
// Since for a Customer Return the system can't specifically identify a layer the last cost is used.
//
// Rows are used for ordering layers withing a day. Row numbers grow within
// a day for a particular item within a location for FIFO/LIFO costing items, and
// company-wide for average costing items.
//
// Parameters:
// DocumentTabularSectionRow.
// Array.
// Catalog.Locations.
// Date.
// Number.
// Document that's calling the procedure. 
//
// Returned value:
// ValueTable.
//
Function PurchaseDocumentsProcessing(CurRowLineItems, InvDatasetProduct, Location, DocDate, ExchangeRate, Ref, PriceIncludesVAT) Export
	
	If PriceIncludesVAT Then
		If GeneralFunctionsReusable.FunctionalOptionValue("UnitsOfMeasure") Then
			CurRowLineItemsPrice = CurRowLineItems.Price - (CurRowLineItems.VAT / CurRowLineItems.QuantityUM);
		Else
			CurRowLineItemsPrice = CurRowLineItems.Price - (CurRowLineItems.VAT / CurRowLineItems.Quantity);
		EndIf;
	Else
		CurRowLineItemsPrice = CurRowLineItems.Price;
	EndIf;
		
	PostingCost = 0; // for SalesReturn
	PostingCostBeforeAdj = 0;
	PostingCostAfterAdj = 0;
	
	If CurRowLineItems.Product.CostingMethod = Enums.InventoryCosting.WeightedAverage Then
				
		OnHandSet = False;
		OnHand = 0;
		
		CurrentOnHand = InventoryCosting.TotalOnHandAv(CurRowLineItems.Product);
		
		Remaining = CurRowLineItems.Quantity;
		
		Created = False;
						
		NoOfRows = 0;
		NoOfRows = InvDatasetProduct.Count();
		
		If NoOfRows = 0 Then
			
			// If the Inventory Journal has no layers after the document date create a new layer.
			// For average costing items an adjusted cost is calculated as
			// (previous layers value + current layer value)/(previous layers qty + current layer qty)
			
			Reg = InformationRegisters.InventoryJournal.CreateRecordManager();
			Reg.Date = DocDate;
			Reg.Document = Ref;
			Reg.Product = CurRowLineItems.Product;
			Reg.QtyIn = CurRowLineItems.Quantity;				
			Reg.QtyOut = 0;
			Reg.QtyOnHand = CurrentOnHand + CurRowLineItems.Quantity - 0;
			LastCost = InventoryCosting.LastCost(CurRowLineItems.Product); // for SalesReturn			
			If TypeOf(Ref) = Type("DocumentRef.SalesReturn") Then
				Reg.DocCost = LastCost;
			Else
				Reg.DocCost = CurRowLineItemsPrice * ExchangeRate;
			EndIf;			
			LastRowNumber = InventoryCosting.GetLastRowNumber(CurRowLineItems.Product, Location, DocDate);
			Reg.Row = LastRowNumber + 1;			
			If TypeOf(Ref) = Type("DocumentRef.SalesReturn") Then
				AdjCost = (InventoryCosting.PreviousLayersValue(CurRowLineItems.Product, Location, DocDate, 0) +
					CurRowLineItems.Quantity * LastCost) / (InventoryCosting.PreviousLayersQty(CurRowLineItems.Product,
					Location, DocDate, 0) + CurRowLineItems.Quantity);
			Else
				AdjCost = (InventoryCosting.PreviousLayersValue(CurRowLineItems.Product, Location, DocDate, 0) +
					CurRowLineItems.Quantity * CurRowLineItemsPrice * ExchangeRate) /
					(InventoryCosting.PreviousLayersQty(CurRowLineItems.Product, Location, DocDate, 0) +
					CurRowLineItems.Quantity);
			EndIf;			
			PostingCost = PostingCost + AdjCost * CurRowLineItems.Quantity; // for SalesReturn
			Reg.AdjCost = AdjCost; 			
			Reg.Write(False);	
			
			Created = True;
			
		Else
						
			For i = 0 To NoOfRows - 1 Do
				
				// If the new layer is not the latest layer (a document's date is earlier than the latest
				// layer date in the Inventory Journal
				
				If OnHandSet = False Then
					OnHand = InvDatasetProduct[i].QtyOnHand - InvDatasetProduct[i].QtyIn + InvDatasetProduct[i].QtyOut;
					OnHandSet = True;
				EndIf;
										
				If DocDate < InvDatasetProduct[i].Date AND Created = False Then 
					
					// create a new layer. OnHandSet is used to ensure that a new layer is created only once.
					
					Reg = InformationRegisters.InventoryJournal.CreateRecordManager();
					Reg.Date = DocDate;
					Reg.Document = Ref;
					Reg.Product = CurRowLineItems.Product;
					Reg.QtyIn = CurRowLineItems.Quantity;								
					Reg.QtyOut = 0;
					OnHand = OnHand + CurRowLineItems.Quantity; 
					Reg.QtyOnHand = OnHand;
					LastCost = InventoryCosting.LastCost(CurRowLineItems.Product); // for SalesReturn					
					If TypeOf(Ref) = Type("DocumentRef.SalesReturn") Then
						Reg.DocCost = LastCost;
					Else
						Reg.DocCost = CurRowLineItemsPrice * ExchangeRate;
					EndIf;					
					LastRowNumber = InventoryCosting.GetLastRowNumber(CurRowLineItems.Product, Location, DocDate);
					Reg.Row = LastRowNumber + 1;					
					If TypeOf(Ref) = Type("DocumentRef.SalesReturn") Then
						AdjCost = (InventoryCosting.PreviousLayersValue(CurRowLineItems.Product, Location, DocDate, 0) +
							CurRowLineItems.Quantity * LastCost) / (InventoryCosting.PreviousLayersQty(CurRowLineItems.Product,
							Location, DocDate, 0) + CurRowLineItems.Quantity);
					Else
						AdjCost = (InventoryCosting.PreviousLayersValue(CurRowLineItems.Product, Location, DocDate, 0) +
							CurRowLineItems.Quantity * CurRowLineItemsPrice * ExchangeRate) /
							(InventoryCosting.PreviousLayersQty(CurRowLineItems.Product, Location, DocDate, 0) +
							CurRowLineItems.Quantity);
					EndIf;					
					PostingCost = PostingCost + AdjCost * CurRowLineItems.Quantity; // for SalesReturn 
					Reg.AdjCost = AdjCost;
					Reg.Write(False);	
									
					Created = True;
					
					// also update QtyOnHand and AdjCost of the current layer in the loop
					
					Reg = InformationRegisters.InventoryJournal.CreateRecordSet();
					Reg.Filter.Document.Set(InvDatasetProduct[i].Document);
					Reg.Filter.Product.Set(InvDatasetProduct[i].Product);
					Reg.Read();
					PreviousOnHand = OnHand;
					OnHand = OnHand + Reg[0].QtyIn - Reg[0].QtyOut; 
					Reg[0].QtyOnHand = OnHand;
					PostingCostBeforeAdj = Reg[0].AdjCost * Reg[0].QtyIn;
					AdjCost = (AdjCost * PreviousOnHand + Reg[0].QtyIn * Reg[0].DocCost) / (PreviousOnHand + Reg[0].QtyIn);
					PostingCostAfterAdj = AdjCost * Reg[0].QtyIn;
					Reg[0].AdjCost = AdjCost;
					Reg.Write();
					
				Else					
					
					// update QtyOnHand and AdjCost of the current layer in the loop
											
					Reg = InformationRegisters.InventoryJournal.CreateRecordSet();
					Reg.Filter.Document.Set(InvDatasetProduct[i].Document);
					Reg.Filter.Product.Set(InvDatasetProduct[i].Product);
					Reg.Read();
					OnHand = OnHand + Reg[0].QtyIn - Reg[0].QtyOut; 
					Reg[0].QtyOnHand = OnHand;
					PostingCostBeforeAdj = Reg[0].AdjCost * Reg[0].QtyIn;
					AdjCost = (InventoryCosting.PreviousLayersValue(CurRowLineItems.Product, Location, InvDatasetProduct[i].Date,
						InvDatasetProduct[i].Row - 1) + Reg[0].QtyIn * Reg[0].DocCost) /
						(InventoryCosting.PreviousLayersQty(CurRowLineItems.Product, Location, InvDatasetProduct[i].Date,
						InvDatasetProduct[i].Row - 1) + Reg[0].QtyIn);
					PostingCostAfterAdj = AdjCost * Reg[0].QtyIn;
					Reg[0].AdjCost = AdjCost;
					Reg.Write();
											
				EndIf;
			EndDo;
		EndIf;			
	EndIf;

	If CurRowLineItems.Product.CostingMethod = Enums.InventoryCosting.FIFO OR
		CurRowLineItems.Product.CostingMethod = Enums.InventoryCosting.LIFO Then

		// create an inventory layer
		
		Reg = InformationRegisters.InventoryJournal.CreateRecordManager();
		Reg.Location = Location;
		Reg.Date = DocDate;
		Reg.Document = Ref;
		Reg.Product = CurRowLineItems.Product;
		Reg.QtyIn = CurRowLineItems.Quantity;				
		Reg.QtyOut = 0;
		Reg.QtyOnHand = 0;
		LastCost = InventoryCosting.LastCost(CurRowLineItems.Product); // for SalesReturn		
		If TypeOf(Ref) = Type("DocumentRef.SalesReturn") Then
			Reg.DocCost = LastCost;
		Else
			Reg.DocCost = CurRowLineItemsPrice * ExchangeRate;
		EndIf;		
		LastRowNumber = InventoryCosting.GetLastRowNumber(CurRowLineItems.Product, Location, DocDate);
		Reg.Row = LastRowNumber + 1;		
		If TypeOf(Ref) = Type("DocumentRef.SalesReturn") Then
			Reg.AdjCost = LastCost;
		Else
			Reg.AdjCost = CurRowLineItemsPrice * ExchangeRate; 			
		EndIf;		
		PostingCost = PostingCost + LastCost * CurRowLineItems.Quantity; // for SalesReturn		
		Reg.Write(False);	
		
	EndIf;
	
	AdjustmentCosts = New ValueTable();
	AdjustmentCosts.Columns.Add("PostingCostBeforeAdj");
	AdjustmentCosts.Columns.Add("PostingCostAfterAdj");
	AdjustmentCosts.Columns.Add("PostingCost"); // for SalesReturn
	
	AdjustmentCostsRow = AdjustmentCosts.Add();
	AdjustmentCostsRow.PostingCostBeforeAdj = PostingCostBeforeAdj;
	AdjustmentCostsRow.PostingCostAfterAdj = PostingCostAfterAdj;
	AdjustmentCostsRow.PostingCost = PostingCost; // for SalesReturn
	
	Return AdjustmentCosts;
	
EndFunction

// The function returns an inventory balance at a particular warehouse location.
//
// Parameters:
// Catalog.Product.
// Catalog.Location.
//
// Returned value:
// Number.
//
Function LocationBalance(Product, Location) Export
	
	Query = New Query("SELECT
                      |	LocationBalancesBalance.QtyOnHandBalance
                      |FROM
                      |	AccumulationRegister.LocationBalances.Balance AS LocationBalancesBalance
                      |WHERE
                      |	LocationBalancesBalance.Product = &Product
                      |	AND LocationBalancesBalance.Location = &Location");
	Query.SetParameter("Product", Product);
	Query.SetParameter("Location", Location);
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Return 0;
	Else
		Dataset = QueryResult.Unload();
		Return Dataset[0][0];
	EndIf;

EndFunction

// The function checks if inventory items are present in the document's line items.
//
// Parameters:
// Any document.
//
// Returned value:
// Boolean.
//
Function InventoryPresent(DocRef) Export
	
	DocName = DocRef.Metadata().Name;

    Query = New Query("SELECT
                      |	Document.LineItems.(
                      |		LineNumber
                      |	)
                      |FROM
                      |	Document." + DocName + " AS Document
                      |WHERE
                      |	Document.Ref = &DocRef
                      |	AND Document.LineItems.Product.Type = VALUE(Enum.InventoryTypes.Inventory)");
	Query.SetParameter("DocRef", DocRef);
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Return False;
	Else
		Return True;
	EndIf;
	
EndFunction

Function OrderWhse(OrderDocument, Product) Export
	
	 Query = New Query("SELECT
                      |	ReceivedInvoiced.WhseBalance
                      |FROM
                      |	AccumulationRegister.ReceivedInvoiced.Balance AS ReceivedInvoiced
                      |WHERE
                      |	ReceivedInvoiced.OrderDocument = &OrderDocument
                      |	AND ReceivedInvoiced.Product = &Product");
	Query.SetParameter("OrderDocument", OrderDocument);				  
	Query.SetParameter("Product", Product);
	QueryResult = Query.Execute();

	If QueryResult.IsEmpty() Then
		Return 0;
	Else
		Dataset = QueryResult.Unload();
		Return Dataset[0][0];
	EndIf;
	
EndFunction

Function OrderInvoiced(OrderDocument, Product) Export
	
	 Query = New Query("SELECT
                      |	ReceivedInvoiced.InvoicedBalance
                      |FROM
                      |	AccumulationRegister.ReceivedInvoiced.Balance AS ReceivedInvoiced
                      |WHERE
                      |	ReceivedInvoiced.OrderDocument = &OrderDocument
                      |	AND ReceivedInvoiced.Product = &Product");
	Query.SetParameter("OrderDocument", OrderDocument);				  
	Query.SetParameter("Product", Product);
	QueryResult = Query.Execute();

	If QueryResult.IsEmpty() Then
		Return 0;
	Else
		Dataset = QueryResult.Unload();
		Return Dataset[0][0];
	EndIf;
	
EndFunction