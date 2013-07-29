
&AtClient
Procedure LineItemsProductOnChange(Item)
	
	TabularPartRow = Items.LineItems.CurrentData;
	
	TabularPartRow.ProductDescription = CommonUse.GetAttributeValue(TabularPartRow.Product, "Description");
	//TabularPartRow.Quantity = 0;
	//TabularPartRow.LineTotal = 0;
	//
	//TabularPartRow.Price = InventoryCosting.LastCost(TabularPartRow.Product);

	//Object.DocumentTotalRC = Object.LineItems.Total("LineTotal");	
	
EndProcedure

&AtClient
Procedure LineItemsQuantityOnChange(Item)
	
	TabularPartRow = Items.LineItems.CurrentData;
	TabularPartRow.LineTotal = TabularPartRow.Quantity * TabularPartRow.Price;
	Object.DocumentTotalRC = Object.LineItems.Total("LineTotal");

EndProcedure


