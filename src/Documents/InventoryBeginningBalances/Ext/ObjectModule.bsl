// Performs document posting
//
Procedure Posting(Cancel, PostingMode)
	
	RegisterRecords.InventoryJrnl.Write = True;
	
	Record = RegisterRecords.InventoryJrnl.Add();
	Record.RecordType = AccumulationRecordType.Receipt;
	Record.Period = Date;
	Record.Product = Product;
	Record.Location = Location;
	If Product.CostingMethod = Enums.InventoryCosting.WeightedAverage Then
	Else
		Record.Layer = Ref;
	EndIf;
	Record.Qty = Quantity;				
	Record.Amount = Value;
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	CurrentBalance = 0;
						
	Query = New Query("SELECT
	                  |	InventoryJrnlBalance.QtyBalance
	                  |FROM
	                  |	AccumulationRegister.InventoryJrnl.Balance AS InventoryJrnlBalance
	                  |WHERE
	                  |	InventoryJrnlBalance.Product = &Product
	                  |	AND InventoryJrnlBalance.Location = &Location");
	Query.SetParameter("Product", Product);
	Query.SetParameter("Location", Location);
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
	Else
		Dataset = QueryResult.Unload();
		CurrentBalance = Dataset[0][0];
	EndIf;
					
	If Quantity > CurrentBalance Then
		Cancel = True;
		Message = New UserMessage();
		Message.Text=NStr("en='Insufficient balance';de='Nicht ausreichende Bilanz'");
		Message.Message();
		Return;
	EndIf;
			
EndProcedure





