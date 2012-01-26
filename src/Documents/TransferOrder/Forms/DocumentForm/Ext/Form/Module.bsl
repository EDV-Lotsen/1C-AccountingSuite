
&AtClient
Procedure LineItemsProductOnChange(Item)
	
	TabularPartRow = Items.LineItems.CurrentData;
	
	TabularPartRow.Descr = GeneralFunctions.GetAttributeValue(TabularPartRow.Product, "Descr");
	TabularPartRow.Quantity = 0;
	TabularPartRow.LineTotal = 0;
	
	TabularPartRow.Price = InventoryCosting.LastCost(TabularPartRow.Product);

	Object.DocumentTotalRC = Object.LineItems.Total("LineTotal");	
	
EndProcedure

&AtClient
Procedure LineItemsQuantityOnChange(Item)
	
	TabularPartRow = Items.LineItems.CurrentData;
	TabularPartRow.LineTotal = TabularPartRow.Quantity * TabularPartRow.Price;
	Object.DocumentTotalRC = Object.LineItems.Total("LineTotal");

EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	ProductData = Object.LineItems.Unload(,"Product");	
	ProductData.Sort("Product");
	NoOfRows = ProductData.Count();	
	For i = 0 to NoOfRows - 2 Do		
		Product = ProductData[i][0];
		If ProductData[i][0] = ProductData[i+1][0] AND NOT Product.Code = "" Then									
			ProductIDString = String(Product.Description);
			ProductDescrString = String(Product.Descr);			
			Message = New UserMessage();		    
			Message.Text = "Duplicate item: " + ProductIDString + " " + ProductDescrString;
			Message.Message();
			Cancel = True;
			Return;
		EndIf;		
	EndDo;

EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	//Title = "Transfer order " + Object.Number + " " + Format(Object.Date, "DLF=D");
EndProcedure


