// The procedure updates inventory balances and inventory costing information
//
Procedure Posting(Cancel, Mode)
			
	RegisterRecords.InventoryJrnl.Write = True;
	
	AllowNegativeInventory = Constants.AllowNegativeInventory.Get();
	
	For Each CurRowLineItems In LineItems Do		
		If CurRowLineItems.Product.Type = Enums.InventoryTypes.Inventory Then
			
			// check inventory balances and cancel if not sufficient
			
			CurrentBalance = 0;
			
			Query = New Query("SELECT
			                  |	InventoryJrnlBalance.QtyBalance
			                  |FROM
			                  |	AccumulationRegister.InventoryJrnl.Balance AS InventoryJrnlBalance
			                  |WHERE
			                  |	InventoryJrnlBalance.Product = &Product
			                  |	AND InventoryJrnlBalance.Location = &Location");
			Query.SetParameter("Product", CurRowLineItems.Product);
			Query.SetParameter("Location", LocationFrom);
			QueryResult = Query.Execute();
			
			If QueryResult.IsEmpty() Then
			Else
				Dataset = QueryResult.Unload();
				CurrentBalance = Dataset[0][0];
			EndIf;
			
			If CurRowLineItems.Quantity > CurrentBalance Then
				CurProd = CurRowLineItems.Product;
				
				Message = New UserMessage();
				Message.Text= StringFunctionsClientServer.SubstituteParametersInString(
				NStr("en='Insufficient balance on %1';de='Nicht ausreichende Bilanz'"),CurProd);
				Message.Message();
				If NOT AllowNegativeInventory Then
					Cancel = True;
					Return;
				EndIf;
			EndIf;

			// layer outflow and inflow operations
			
			If CurRowLineItems.Product.CostingMethod = Enums.InventoryCosting.WeightedAverage Then
				
				AverageCost = 0;
				
				Query = New Query("SELECT
				                  |	SUM(InventoryJrnlBalance.QtyBalance) AS QtyBalance,
				                  |	SUM(InventoryJrnlBalance.AmountBalance) AS AmountBalance
				                  |FROM
				                  |	AccumulationRegister.InventoryJrnl.Balance AS InventoryJrnlBalance
				                  |WHERE
				                  |	InventoryJrnlBalance.Product = &Product");
				Query.SetParameter("Product", CurRowLineItems.Product);
				QueryResult = Query.Execute().Unload();
				If  QueryResult.Count() > 0
				And (Not QueryResult[0].QtyBalance = Null)
				And (Not QueryResult[0].AmountBalance = Null)
				And QueryResult[0].QtyBalance > 0
				Then
					AverageCost = QueryResult[0].AmountBalance / QueryResult[0].QtyBalance;
				EndIf;
								
				Record = RegisterRecords.InventoryJrnl.Add();
				Record.RecordType = AccumulationRecordType.Expense;
				Record.Period = Date;
				Record.Product = CurRowLineItems.Product;
				Record.Location = LocationFrom;
				Record.Qty = CurRowLineItems.Quantity;				
				ItemCost = CurRowLineItems.Quantity * AverageCost;
				Record.Amount = ItemCost;
				
				Record = RegisterRecords.InventoryJrnl.Add();
				Record.RecordType = AccumulationRecordType.Receipt;
				Record.Period = Date;
				Record.Product = CurRowLineItems.Product;
				Record.Location = LocationTo;
				Record.Qty = CurRowLineItems.Quantity;				
				ItemCost = CurRowLineItems.Quantity * AverageCost;
				Record.Amount = ItemCost;

			EndIf;
			
			If CurRowLineItems.Product.CostingMethod = Enums.InventoryCosting.LIFO OR
				CurRowLineItems.Product.CostingMethod = Enums.InventoryCosting.FIFO Then
				
				ItemQty = CurRowLineItems.Quantity;
				
				If CurRowLineItems.Product.CostingMethod = Enums.InventoryCosting.LIFO Then
					Sorting = "DESC";
				Else
					Sorting = "ASC";
				EndIf;
				
				Query = New Query("SELECT
				                  |	InventoryJrnlBalance.QtyBalance,
				                  |	InventoryJrnlBalance.AmountBalance,
				                  |	InventoryJrnlBalance.Layer,
				                  |	InventoryJrnlBalance.Layer.Date AS LayerDate
				                  |FROM
				                  |	AccumulationRegister.InventoryJrnl.Balance AS InventoryJrnlBalance
				                  |WHERE
				                  |	InventoryJrnlBalance.Product = &Product
				                  |	AND InventoryJrnlBalance.Location = &Location
				                  |
				                  |ORDER BY
				                  |	LayerDate " + Sorting + "");
				Query.SetParameter("Product", CurRowLineItems.Product);
				Query.SetParameter("Location", LocationFrom);
				Selection = Query.Execute().Choose();
				
				While Selection.Next() Do
					If ItemQty > 0 Then
						
						Record = RegisterRecords.InventoryJrnl.Add();
						Record.RecordType = AccumulationRecordType.Expense;
						Record.Period = Date;
						Record.Product = CurRowLineItems.Product;
						Record.Location = LocationFrom;
						Record.Layer = Selection.Layer;
						If ItemQty >= Selection.QtyBalance Then
							ItemCost = ItemCost + Selection.AmountBalance;
							Record.Qty = Selection.QtyBalance;
							Record.Amount = Selection.AmountBalance;
							ItemQty = ItemQty - Record.Qty;
						Else
							ItemCost = ItemCost + ItemQty * (Selection.AmountBalance / Selection.QtyBalance);
							Record.Qty = ItemQty;
							Record.Amount = ItemQty * (Selection.AmountBalance / Selection.QtyBalance);
							ItemQty = 0;
						EndIf;
						
						Record = RegisterRecords.InventoryJrnl.Add();
						Record.RecordType = AccumulationRecordType.Receipt;
						Record.Period = Date;
						Record.Product = CurRowLineItems.Product;
						Record.Location = LocationTo;
						Record.Layer = Selection.Layer;
						Record.Qty = Record.Qty;
						Record.Amount = Record.Amount;
						
					EndIf;
				EndDo;
									
			EndIf;
			
		EndIf;		
	EndDo;
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	AllowNegativeInventory = Constants.AllowNegativeInventory.Get();
	
	For Each CurRowLineItems In LineItems Do
					
		If CurRowLineItems.Product.Type = Enums.InventoryTypes.Inventory Then
											
			// check inventory balances and cancel if not sufficient
			
			CurrentBalance = 0;
								
			Query = New Query("SELECT
			                  |	InventoryJrnlBalance.QtyBalance
			                  |FROM
			                  |	AccumulationRegister.InventoryJrnl.Balance AS InventoryJrnlBalance
			                  |WHERE
			                  |	InventoryJrnlBalance.Product = &Product
			                  |	AND InventoryJrnlBalance.Location = &Location");
			Query.SetParameter("Product", CurRowLineItems.Product);
			Query.SetParameter("Location", LocationTo);
			QueryResult = Query.Execute();
			
			If QueryResult.IsEmpty() Then
			Else
				Dataset = QueryResult.Unload();
				CurrentBalance = Dataset[0][0];
			EndIf;
			
			If CurRowLineItems.Quantity > CurrentBalance Then
				CurProd = CurRowLineItems.Product;	
				Message = New UserMessage();
				Message.Text= StringFunctionsClientServer.SubstituteParametersInString(
				NStr("en='Insufficient balance on %1';de='Nicht ausreichende Bilanz'"),CurProd);
				Message.Message();
				If NOT AllowNegativeInventory Then
					Cancel = True;
					Return;
				EndIf;
			EndIf;
			
		EndIf;
		
	EndDo;

EndProcedure





