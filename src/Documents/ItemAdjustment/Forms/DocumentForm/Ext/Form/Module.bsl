
////////////////////////////////////////////////////////////////////////////////
// Item adjustment: Document form
//------------------------------------------------------------------------------
// Available on:
// - Client (managed application)
// - Server
//

////////////////////////////////////////////////////////////////////////////////
#Region EVENTS_HANDLERS

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	//------------------------------------------------------------------------------
	// 1. Form attributes initialization.
	
	// Define point in time for requesting the balances.
	PointInTime = GeneralFunctions.GetDocumentPointInTime(Object);
	
	//------------------------------------------------------------------------------
	// 2. Calculate values of form object attributes.
	
	// Request and fill item balance.
	FillItemBalance();
	
	//------------------------------------------------------------------------------
	// 3. Set custom controls presentation.
	
	// Update quantities presentation.
	QuantityPrecision = GeneralFunctionsReusable.DefaultQuantityPrecision();
	QuantityFormat    = GeneralFunctionsReusable.DefaultQuantityFormat();
	Items.QuantityBefore.EditFormat  = QuantityFormat;
	Items.QuantityBefore.Format      = QuantityFormat;
	Items.Quantity.EditFormat        = QuantityFormat;
	Items.Quantity.Format            = QuantityFormat;
	Items.QuantityAfter.EditFormat   = QuantityFormat;
	Items.QuantityAfter.Format       = QuantityFormat;
	
EndProcedure

// -> CODE REVIEW
&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	//Closing period
	If PeriodClosingServerCall.DocumentPeriodIsClosed(Object.Ref, Object.Date) Then
		Cancel = Not PeriodClosingServerCall.DocumentWritePermitted(WriteParameters);
		If Cancel Then
			If WriteParameters.Property("PeriodClosingPassword") And WriteParameters.Property("Password") Then
				If WriteParameters.Password = TRUE Then //Writing the document requires a password
					ShowMessageBox(, "Invalid password!",, "Closed period notification");
				EndIf;
			Else
				Notify = New NotifyDescription("ProcessUserResponseOnDocumentPeriodClosed", ThisObject, WriteParameters);
				Password = "";
				OpenForm("CommonForm.ClosedPeriodNotification", New Structure, ThisForm,,,, Notify, FormWindowOpeningMode.LockOwnerWindow);
			EndIf;
			return;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure ProcessUserResponseOnDocumentPeriodClosed(Result, Parameters) Export
	
	If (TypeOf(Result) = Type("String")) Then // Inserted password.
		Parameters.Insert("PeriodClosingPassword", Result);
		Parameters.Insert("Password", True);
		Write(Parameters);
		
	ElsIf (TypeOf(Result) = Type("DialogReturnCode")) Then // Yes, No or Cancel.
		If Result = DialogReturnCode.Yes Then
			Parameters.Insert("PeriodClosingPassword", "Yes");
			Parameters.Insert("Password", False);
			Write(Parameters);
		EndIf;
	EndIf;
	
EndProcedure
// <- CODE REVIEW

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// -> CODE REVIEW
	//Period closing
	If PeriodClosingServerCall.DocumentPeriodIsClosed(CurrentObject.Ref, CurrentObject.Date) Then
		PermitWrite = PeriodClosingServerCall.DocumentWritePermitted(WriteParameters);
		CurrentObject.AdditionalProperties.Insert("PermitWrite", PermitWrite);
	EndIf;
	// <- CODE REVIEW
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	//------------------------------------------------------------------------------
	// Recalculate values of form object attributes.
	
	// Define point in time for requesting the balances.
	PointInTime = GeneralFunctions.GetDocumentPointInTime(Object);
	
	// Request and fill item balance.
	FillItemBalance();
	
EndProcedure

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region CONTROLS_EVENTS_HANDLERS

&AtClient
Procedure DateOnChange(Item)
	
	// Request server operation.
	DateOnChangeAtServer();
	
EndProcedure

&AtServer
Procedure DateOnChangeAtServer()
	
	// Define point in time for requesting the balances.
	PointInTime = GeneralFunctions.GetDocumentPointInTime(Object);
	
	// Recalculate item balances.
	FillItemBalance();
	
EndProcedure

&AtClient
Procedure ProductOnChange(Item)
	
	// Request server operation.
	ProductOnChangeAtServer();
	
EndProcedure

&AtServer
Procedure ProductOnChangeAtServer()
	
	// Fill account by the item COGS account by default.
	Object.IncomeExpenseAccount = Object.Product.COGSAccount;
	
	// Recalculate item balances.
	FillItemBalance();
	
EndProcedure

&AtClient
Procedure LocationOnChange(Item)
	
	// Recalculate item balances.
	FillItemBalance();
	
EndProcedure

&AtClient
Procedure LayerOnChange(Item)
	
	// Recalculate item balances.
	FillItemBalance();
	
EndProcedure

&AtClient
Procedure QuantityOnChange(Item)
	
	// Recalculate quantity and amount.
	QuantityAfter      = QuantityBefore + Object.Quantity;
	QuantityRevaluated = QuantityOriginal + Object.Quantity;
	If QuantityOriginal > 0 Then
		AmountAfter    = ?(QuantityRevaluated = QuantityOriginal, AmountBefore, Round(QuantityRevaluated * AmountBefore / QuantityOriginal, 2));
		AmountAfterOnChange(Item);
	EndIf;
	
EndProcedure

&AtClient
Procedure QuantityAfterOnChange(Item)
	
	// Recalculate quantity and amount.
	Object.Quantity    = QuantityAfter - QuantityBefore;
	QuantityRevaluated = QuantityOriginal + Object.Quantity;
	If QuantityOriginal > 0 Then
		AmountAfter    = ?(QuantityRevaluated = QuantityOriginal, AmountBefore, Round(QuantityRevaluated * AmountBefore / QuantityOriginal, 2));
		AmountAfterOnChange(Item);
	EndIf;
	
EndProcedure

&AtClient
Procedure AmountOnChange(Item)
	
	// Recalculate amount.
	AmountAfter = AmountBefore + Object.Amount;
	
EndProcedure

&AtClient
Procedure AmountAfterOnChange(Item)
	
	// Recalculate amount correction.
	Object.Amount = AmountAfter - AmountBefore;
	
EndProcedure

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region PRIVATE_IMPLEMENTATION

&AtServer
// Request and fill item balance.
Procedure FillItemBalance()
	
	// Define items parameters.
	ProductCostingFIFO = (Not Object.Product.IsEmpty()) And Object.Product.Type = Enums.InventoryTypes.Inventory
	                                                    And Object.Product.CostingMethod = Enums.InventoryCosting.FIFO;
	ProductCostingWAve = (Not Object.Product.IsEmpty()) And Object.Product.Type = Enums.InventoryTypes.Inventory
	                                                    And Object.Product.CostingMethod = Enums.InventoryCosting.WeightedAverage;
	
	// Turn the layer enabled flag.
	Items.Layer.Enabled = ProductCostingFIFO;
	
	// Fill query text.
	QueryText =
		"SELECT{Dimension}
		|	InventoryJournalBalance.QuantityBalance AS Quantity,
		|	InventoryJournalBalance.AmountBalance   AS Amount
		|FROM
		|	AccumulationRegister.InventoryJournal.Balance(&PointInTime, {Condition}) AS InventoryJournalBalance
		|{Order}";
	Condition = ""; Dimension = ""; Order = "";
	If Not Object.Product.IsEmpty() Then
		Condition = ?(Not IsBlankString(Condition), Condition + " AND ", "") + "Product = &Product";
	EndIf;
	If ProductCostingFIFO Then
		Dimension  = "
		|	InventoryJournalBalance.Layer           AS Layer,";
		Order = "ORDER BY
		|	InventoryJournalBalance.Layer.PointInTime";
		If (Not Object.Location.IsEmpty()) Then
			Condition = ?(Not IsBlankString(Condition), Condition + " AND ", "") + "Location = &Location";
		EndIf;
	ElsIf ProductCostingWAve Then
		Dimension  = "
		|	InventoryJournalBalance.Location        AS Location,";
		Order = "ORDER BY
		|	InventoryJournalBalance.Location.Description";
	Else
		If Not Object.Location.IsEmpty() Then
			Condition = ?(Not IsBlankString(Condition), Condition + " AND ", "") + "Location = &Location";
		EndIf;
	EndIf;
	QueryText = StringFunctionsClientServer.SubstituteParametersInStringByName(QueryText, New Structure("Dimension, Condition, Order", Dimension, Condition, Order));
	
	// Execute the query.
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Product",     Object.Product);
	Query.SetParameter("Location",    Object.Location);
	Query.SetParameter("PointInTime", PointInTime);
	ItemBalances.Load(Query.Execute().Unload());
	
	// Fill available layers.
	If ProductCostingFIFO Then
		Items.Layer.ChoiceList.LoadValues(ItemBalances.Unload(, "Layer").UnloadColumn(0));
		If Items.Layer.ChoiceList.FindByValue(Object.Layer) = Undefined Then
			Object.Layer = Undefined;
		EndIf;
	Else
		Items.Layer.ChoiceList.Clear();
	EndIf;
	
	// Refill balance values.
	If ProductCostingFIFO Then
		
		If (Object.Layer <> Undefined) And (Not Object.Layer.IsEmpty()) Then
			// FIFO by layer.
			LayerBalances = ItemBalances.FindRows(New Structure("Layer", Object.Layer));
			If LayerBalances.Count() > 0 Then
				QuantityBefore = LayerBalances[0].Quantity;
				AmountBefore   = LayerBalances[0].Amount;
			Else
				QuantityBefore = 0;
				AmountBefore   = 0;
			EndIf;
		Else
			// FIFO total.
			QuantityBefore = ItemBalances.Total("Quantity");
			AmountBefore   = ItemBalances.Total("Amount");
		EndIf;
		
	ElsIf ProductCostingWAve Then
		
		If Not Object.Location.IsEmpty() Then
			// WAve by location.
			LocationBalances = ItemBalances.FindRows(New Structure("Location", Object.Location));
			If LocationBalances.Count() > 0 Then
				QuantityBefore = LocationBalances[0].Quantity;
			Else
				QuantityBefore = 0;
			EndIf;
		Else
			// WAve total.
			QuantityBefore = ItemBalances.Total("Quantity");
		EndIf;
		AmountBefore   = ItemBalances.Total("Amount");
		
	Else
		// Overall balance.
		QuantityBefore = ItemBalances.Total("Quantity");
		AmountBefore   = ItemBalances.Total("Amount");
	EndIf;
	
	// Recalculate quantity and amount.
	QuantityOriginal   = ?(ProductCostingWAve, ItemBalances.Total("Quantity"), QuantityBefore);
	QuantityAfter      = QuantityBefore + Object.Quantity;
	QuantityRevaluated = QuantityOriginal + Object.Quantity;
	If QuantityOriginal > 0 Then
		AmountAfter    = ?(QuantityRevaluated = QuantityOriginal, AmountBefore, Round(QuantityRevaluated * AmountBefore / QuantityOriginal, 2));
		Object.Amount  = AmountAfter - AmountBefore;
	EndIf;
	
EndProcedure

#EndRegion
