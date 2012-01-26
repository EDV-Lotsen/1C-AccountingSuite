// The procedure updates inventory balances and inventory costing information
//
Procedure Posting(Cancel, Mode)
		
	DocDate = BegOfDay(Date) + 60*60*10;
	
	RegisterRecords.LocationBalances.Write = True;
	
	For Each CurRowLineItems In LineItems Do
		
		If CurRowLineItems.Product.Type = Enums.InventoryTypes.Inventory Then
			
			Record = RegisterRecords.LocationBalances.Add();
			Record.RecordType = AccumulationRecordType.Expense;
			Record.Period = Date;
			Record.Product = CurRowLineItems.Product;
			Record.Location = LocationFrom;
			Record.QtyOnHand = CurRowLineItems.Quantity;
			
			Record = RegisterRecords.LocationBalances.Add();
			Record.RecordType = AccumulationRecordType.Receipt;
			Record.Period = Date;
			Record.Product = CurRowLineItems.Product;
			Record.Location = LocationTo;
			Record.QtyOnHand = CurRowLineItems.Quantity;
			
		EndIf;
		
		If CurRowLineItems.Product.Type = Enums.InventoryTypes.Inventory Then				
			
			CurrentBalance = InventoryCosting.LocationBalance(CurRowLineItems.Product, LocationFrom);

			// check inventory balances and cancel if not sufficient
			
			If CurRowLineItems.Quantity > CurrentBalance Then
				Message = New UserMessage();
				Message.Text=NStr("en='Insufficient balance'");
				Message.Message();
				Cancel = True;
				Return;
			EndIf;
			
		EndIf;
						
		If CurRowLineItems.Product.CostingMethod = Enums.InventoryCosting.FIFO Then

			Query = New Query("SELECT
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
			                  |	InformationRegister.InventoryJournal AS InventoryJournal
			                  |WHERE
			                  |	InventoryJournal.Product = &Product
			                  |	AND InventoryJournal.Location = &Location
			                  |	AND InventoryJournal.QtyIn > InventoryJournal.QtyOut
			                  |
			                  |ORDER BY
			                  |	InventoryJournal.Date,
			                  |	InventoryJournal.Row");
							 
			Query.SetParameter("Product", CurRowLineItems.Product);	
			Query.SetParameter("Location", LocationFrom);
			QueryResult = Query.Execute();
			
			Dataset = QueryResult.Choose();

			Remaining = CurRowLineItems.Quantity;
			
			While Dataset.Next() Do

				// outflow
				
				If ((Dataset.QtyIn - Dataset.QtyOut) - Remaining) < 0 Then
					
					Reg = InformationRegisters.InventoryJournal.CreateRecordSet();
					Reg.Filter.Document.Set(Dataset.Document);
					Reg.Filter.Product.Set(Dataset.Product);
					Reg.Read();
					Out = Reg[0].QtyIn - Reg[0].QtyOut;
					Reg[0].QtyOut = Reg[0].QtyIn;
					Cost = Reg[0].AdjCost;
					Document = Reg[0].Document;
					Reg.Write();						
					
				Else
					
					Reg = InformationRegisters.InventoryJournal.CreateRecordSet();
					Reg.Filter.Document.Set(Dataset.Document);
					Reg.Filter.Product.Set(Dataset.Product);
					Reg.Read();
					Out = Remaining;
					Reg[0].QtyOut = Reg[0].QtyOut + Remaining;
					Cost = Reg[0].AdjCost;
					Document = Reg[0].Document;
					Reg.Write();

				EndIf;		
				
				// inflow
				
				Reg = InformationRegisters.InventoryJournal.CreateRecordManager();
				Reg.Location = LocationTo;
				Reg.Date = DocDate;
				Reg.Document = Document;
				Reg.Product = CurRowLineItems.Product;
				Reg.QtyIn = Out;				
				Reg.QtyOut = 0;
				Reg.QtyOnHand = 0;
				Reg.DocCost = Cost;
				RowNumber = InventoryCosting.GetLastRowNumber(CurRowLineItems.Product, LocationTo, DocDate) + 1;
				Reg.Row = RowNumber;                                                                                                                                                                                                                                                       
				Reg.AdjCost = Cost; 			
				Reg.Write(False);
				
				Remaining = Remaining - Out;
				
			EndDo;
			
		EndIf;

		If CurRowLineItems.Product.CostingMethod = Enums.InventoryCosting.LIFO Then

			Query = New Query("SELECT
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
			                  |	InformationRegister.InventoryJournal AS InventoryJournal
			                  |WHERE
			                  |	InventoryJournal.Product = &Product
			                  |	AND InventoryJournal.Location = &Location
			                  |	AND InventoryJournal.QtyIn > InventoryJournal.QtyOut
			                  |
			                  |ORDER BY
			                  |	InventoryJournal.Date DESC,
			                  |	InventoryJournal.Row DESC");
							 
			Query.SetParameter("Product", CurRowLineItems.Product);		
			Query.SetParameter("Location", LocationFrom);
			QueryResult = Query.Execute();
			
			Dataset = QueryResult.Choose();

			Remaining = CurRowLineItems.Quantity;
			
			While Dataset.Next() Do

				// outflow
				
				If ((Dataset.QtyIn - Dataset.QtyOut) - Remaining) < 0 Then
					
					Reg = InformationRegisters.InventoryJournal.CreateRecordSet();
					Reg.Filter.Document.Set(Dataset.Document);
					Reg.Filter.Product.Set(Dataset.Product);
					Reg.Read();
					Out = Reg[0].QtyIn - Reg[0].QtyOut;
					Reg[0].QtyOut = Reg[0].QtyIn;
					Cost = Reg[0].AdjCost;
					Document = Reg[0].Document;
					Reg.Write();
					
				Else
					
					Reg = InformationRegisters.InventoryJournal.CreateRecordSet();
					Reg.Filter.Document.Set(Dataset.Document);
					Reg.Filter.Product.Set(Dataset.Product);
					Reg.Read();
					Out = Remaining;
					Reg[0].QtyOut = Reg[0].QtyOut + Remaining;
					Cost = Reg[0].AdjCost;
					Document = Reg[0].Document;
					Reg.Write();

				EndIf;		
				
				// inflow
				
				Reg = InformationRegisters.InventoryJournal.CreateRecordManager();
				Reg.Location = LocationTo;
				Reg.Date = DocDate;
				Reg.Document = Document;
				Reg.Product = CurRowLineItems.Product;
				Reg.QtyIn = Out;				
				Reg.QtyOut = 0;
				Reg.QtyOnHand = 0;
				Reg.DocCost = Cost;
				RowNumber = InventoryCosting.GetLastRowNumber(CurRowLineItems.Product, LocationTo, DocDate) + 1;
				Reg.Row = RowNumber;                                                                                                                                                                                                                                                       
				Reg.AdjCost = Cost; 			
				Reg.Write(False);
				
				Remaining = Remaining - Out;
				
			EndDo;
			
		EndIf;
	
	EndDo;
	
EndProcedure

// The procedure prevents voiding if the Allow Voiding functional option is disabled.
//
Procedure UndoPosting(Cancel)
	
	If NOT GetFunctionalOption("AllowVoiding") Then
		Message = New UserMessage();
		Message.Text = NStr("en='You cannot void a posted document'");
		Message.Message();
		Cancel = True;
		Return;
	EndIf;

EndProcedure

// The procedure prevents re-posting if the Allow Voiding functional option is disabled.
//
Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If NOT GetFunctionalOption("AllowVoiding") Then
		
		If WriteMode = DocumentWriteMode.Posting Then
			
			If DocPosted Then
		       Message = New UserMessage();
		       Message.Text = NStr("en='You cannot re-post a posted document'");
		       Message.Message();
		       Cancel = True;
		       Return;
		    Else
		       DocPosted = True;
		   EndIf;
		   
	   EndIf;
	
	EndIf;

EndProcedure

// Clears the DocPosted attribute on document copying
//
Procedure OnCopy(CopiedObject)
	DocPosted = False;
EndProcedure



