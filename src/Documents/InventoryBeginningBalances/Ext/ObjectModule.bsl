// Performs document posting
//
Procedure Posting(Cancel, PostingMode)
	
	Reg = InformationRegisters.InventoryJournal.CreateRecordManager();
	If NOT Product.CostingMethod = Enums.InventoryCosting.WeightedAverage Then
		Reg.Location = Location;
	EndIf;	
	Reg.Date = Constants.BeginningBalancesDate.Get();
	Reg.Product = Product;
	Reg.QtyIn = Quantity;				
	Reg.QtyOut = 0;
	Reg.Document = Ref;
	If Product.CostingMethod = Enums.InventoryCosting.WeightedAverage Then
		Reg.QtyOnHand = Quantity;
	EndIf;		
	If NOT Quantity = 0 Then
		Reg.DocCost = Value / Quantity;
	EndIf;	
	Reg.Row = 1;                                                                                                                                                                                                                                                       
	If NOT Quantity = 0 Then
		Reg.AdjCost = Value / Quantity; 			
	EndIf;	
	Reg.Write(False);

	RegisterRecords.LocationBalances.Write = True;
	Record = RegisterRecords.LocationBalances.Add();
	Record.RecordType = AccumulationRecordType.Receipt;
	Record.Period = Constants.BeginningBalancesDate.Get();
	Record.Product = Product;
	Record.Location = Location;
	Record.QtyOnHand = Quantity;
	
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




