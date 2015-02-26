
////////////////////////////////////////////////////////////////////////////////
// Lots adjustment: Document form
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
	
	// Fill lot owner.
	LotsSerialNumbers.FillLotOwner(Object.Product, LotOwner);
	
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
	
	// Refill lot owner.
	LotsSerialNumbers.FillLotOwner(Object.Product, LotOwner);
	
	// Recalculate item balances.
	FillItemBalance();
	
EndProcedure

&AtClient
Procedure LocationOnChange(Item)
	
	// Recalculate item balances.
	FillItemBalance();
	
EndProcedure

&AtClient
Procedure LotOnChange(Item)
	
	// Recalculate item balances.
	FillItemBalance();
	
EndProcedure

&AtClient
Procedure QuantityOnChange(Item)
	
	// Recalculate quantity and amount.
	QuantityAfter = QuantityBefore + Object.Quantity;
	
EndProcedure

&AtClient
Procedure QuantityAfterOnChange(Item)
	
	// Recalculate quantity and amount.
	Object.Quantity = QuantityAfter - QuantityBefore;
	
EndProcedure

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region PRIVATE_IMPLEMENTATION

&AtServer
// Request and fill item balance.
Procedure FillItemBalance()
	
	// Fill query text.
	QueryText =
		"SELECT
		|	LotsBalance.QuantityBalance AS Quantity
		|FROM
		|	AccumulationRegister.Lots.Balance(&PointInTime, {Condition}) AS LotsBalance";
	Condition = "";
	If Not Object.Product.IsEmpty() Then
		Condition = ?(Not IsBlankString(Condition), Condition + " AND ", "") + "Product = &Product";
	EndIf;
	If Not Object.Location.IsEmpty() Then
		Condition = ?(Not IsBlankString(Condition), Condition + " AND ", "") + "Location = &Location";
	EndIf;
	If Not Object.Lot.IsEmpty() Then
		Condition = ?(Not IsBlankString(Condition), Condition + " AND ", "") + "Lot = &Lot";
	EndIf;
	QueryText = StringFunctionsClientServer.SubstituteParametersInStringByName(QueryText, New Structure("Condition", Condition));
	
	// Execute the query.
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Product",     Object.Product);
	Query.SetParameter("Location",    Object.Location);
	Query.SetParameter("Lot",         Object.Lot);
	Query.SetParameter("PointInTime", PointInTime);
	
	// Assign quantities.
	QuantityBefore = Query.Execute().Unload()[0].Quantity;
	QuantityAfter  = QuantityBefore + Object.Quantity;
	
EndProcedure

#EndRegion
