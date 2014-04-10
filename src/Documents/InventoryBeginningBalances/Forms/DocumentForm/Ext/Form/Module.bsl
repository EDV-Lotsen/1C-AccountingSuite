
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Items.QtyAfter.EditFormat = "NFD=" + Constants.QtyPrecision.Get();
	Items.QtyAfter.Format = "NFD=" + Constants.QtyPrecision.Get();
	Items.QtyBefore.EditFormat = "NFD=" + Constants.QtyPrecision.Get();
	Items.QtyBefore.Format = "NFD=" + Constants.QtyPrecision.Get();
	Items.Quantity.EditFormat = "NFD=" + Constants.QtyPrecision.Get();
	Items.Quantity.Format = "NFD=" + Constants.QtyPrecision.Get();
	
	//Title = "Inv. beg. bal. " + Object.Number;
	
	If GeneralFunctionsReusable.FunctionalOptionValue("MultiLocation") Then
	Else
		If Object.Location.IsEmpty() Then			
			Object.Location = Catalogs.Locations.MainWarehouse;
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	If Object.Product.Type = Enums.InventoryTypes.NonInventory Then
		
		Message = New UserMessage();
		Message.Text=NStr("en='Select an inventory item';de='Wählen Sie einen Artikel, der Lagerbeständen zugeordnet wird'");
		Message.Message();
		Cancel = True;
		Return;
		
	EndIf;

EndProcedure

&AtClient
Procedure ProductOnChange(Item)
	RecalcForm();
EndProcedure

&AtClient
Procedure LocationOnChange(Item)
	RecalcForm();
EndProcedure

Function CalculateQty(Product, Location)
	
	Query = New Query("SELECT
	                  |	InventoryJrnlBalance.QtyBalance
	                  |FROM
	                  |	AccumulationRegister.InventoryJrnl.Balance AS InventoryJrnlBalance
	                  |WHERE
	                  |	InventoryJrnlBalance.Product = &Product
	                  |	AND InventoryJrnlBalance.Location = &Location");
					  
	Query.Parameters.Insert("Product", Product);
	Query.Parameters.Insert("Location", Location);

	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Return 0;	
	Else
		DataSet = QueryResult.Unload();
		Return Dataset[0][0];
	EndIf;					  
					  
EndFunction

&AtClient
Procedure QuantityOnChange(Item)
	RecalcForm();
EndProcedure

&AtClient
Procedure RecalcForm()
	
	Balance = CalculateQty(Object.Product, Object.Location);
	QtyBefore = Balance;
	QtyAfter = Balance + Object.Quantity;
	
EndProcedure

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

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	//Period closing
	If PeriodClosingServerCall.DocumentPeriodIsClosed(CurrentObject.Ref, CurrentObject.Date) Then
		PermitWrite = PeriodClosingServerCall.DocumentWritePermitted(WriteParameters);
		CurrentObject.AdditionalProperties.Insert("PermitWrite", PermitWrite);	
	EndIf;

EndProcedure


//Closing period
&AtClient
Procedure ProcessUserResponseOnDocumentPeriodClosed(Result, Parameters) Export
	If (TypeOf(Result) = Type("String")) Then //Inserted password
		Parameters.Insert("PeriodClosingPassword", Result);
		Parameters.Insert("Password", TRUE);
		Write(Parameters);
	ElsIf (TypeOf(Result) = Type("DialogReturnCode")) Then //Yes, No or Cancel
		If Result = DialogReturnCode.Yes Then
			Parameters.Insert("PeriodClosingPassword", "Yes");
			Parameters.Insert("Password", FALSE);
			Write(Parameters);
		EndIf;
	EndIf;	
EndProcedure
