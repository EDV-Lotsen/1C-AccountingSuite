
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
	
	// Request and fill item balance.
	FillItemBalance();
	
	//------------------------------------------------------------------------------
	// 3. Set custom controls presentation.
	
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
	
	// Recalculate item balances.
	FillItemBalance(True);
	
EndProcedure

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region PRIVATE_IMPLEMENTATION

&AtServer
// Request and fill item balance.
Procedure FillItemBalance(ResetTableContents = False)
	
	// Request serial numbers only for selected items.
	If Not Object.Product.IsEmpty() Then
		
		// Fill query text.
		QueryText =
		"SELECT
		|	SerialNumbersSliceLast.SerialNumber
		|FROM
		|	InformationRegister.SerialNumbers.SliceLast(&PointInTime, Product = &Product) AS SerialNumbersSliceLast
		|WHERE
		|	SerialNumbersSliceLast.OnHand = True";
		
		// Execute the query.
		Query = New Query;
		Query.Text = QueryText;
		Query.SetParameter("Product",     Object.Product);
		Query.SetParameter("PointInTime", PointInTime);
		
		// Get actual serial numbers.
		SerialNumbers = Query.Execute().Unload();
		
		// Reset existing numbers.
		If ResetTableContents Then
			Object.SerialNumbers.Clear();
		EndIf;
		
		// Search and replace numbers.
		SearchRec   = New Structure("SerialNumber");
		UpdatedRows = New Array;
		For Each Row In SerialNumbers Do
			
			// Search for existing number.
			If Not ResetTableContents Then
				SearchRec.SerialNumber = Row.SerialNumber;
				Rows = Object.SerialNumbers.FindRows(SearchRec);
				AddRow = Rows.Count() = 0;
			EndIf;
			
			// Add or update the row.
			If ResetTableContents Or AddRow Then
				NewRow = Object.SerialNumbers.Add();
				NewRow.SerialNumber = Row.SerialNumber;
				NewRow.Old          = True;
				If ResetTableContents Then
					NewRow.OnHand   = True;
				EndIf;
			Else
				For Each FoundRow In Rows Do
					FoundRow.Old    = True;
					UpdatedRows.Add(FoundRow.LineNumber);
				EndDo;
			EndIf;
		EndDo;
		
		// Clear presence flag for non-existing serial numbers.
		If Not ResetTableContents Then
			For Each Row In Object.SerialNumbers Do
				If UpdatedRows.Find(Row.LineNumber) = Undefined Then
					Row.Old         = False;
				EndIf;
			EndDo;
		EndIf;
		
	Else
		// Clear existing numbers.
		Object.SerialNumbers.Clear();
	EndIf;
	
EndProcedure

#EndRegion
