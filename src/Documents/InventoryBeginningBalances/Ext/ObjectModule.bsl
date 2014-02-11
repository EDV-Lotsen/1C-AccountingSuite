// Performs document posting
//
Procedure Posting(Cancel, PostingMode)
	
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
					
	If (CurrentBalance + Quantity) < 0 Then
		
		Message = New UserMessage();
		Message.Text= StringFunctionsClientServer.SubstituteParametersInString(
		NStr("en='Insufficient balance on %1';de='Nicht ausreichende Bilanz'"),Product);
		Message.Message();
		//If NOT Constants.AllowNegativeInventory.Get() Then
			Cancel = True;
			Return;
		//EndIf;
	EndIf;

	//
	
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
		Message = New UserMessage();
		Message.Text= StringFunctionsClientServer.SubstituteParametersInString(
		NStr("en='Insufficient balance on %1';de='Nicht ausreichende Bilanz'"),Product);
		Message.Message();
		//If NOT Constants.AllowNegativeInventory.Get() Then
			Cancel = True;
			Return;
		//EndIf;
	EndIf;
			
EndProcedure