
&AtClient
Procedure LineItemOnChange(Item)
If Object.LineItem.Count() > 0 Then	
	Item.CurrentData.Total = Item.CurrentData.Jan + Item.CurrentData.Feb + Item.CurrentData.Mar + Item.CurrentData.Apr + Item.CurrentData.May + Item.CurrentData.Jun + Item.CurrentData.Jul + Item.CurrentData.Aug + Item.CurrentData.Sep + Item.CurrentData.Oct + Item.CurrentData.Nov + Item.CurrentData.Dec;	
Endif;
	LineItemOnChangeAtServer();
EndProcedure

&AtServer
Procedure LineItemOnChangeAtServer()
	// Insert handler contents.
	
EndProcedure

&AtClient
Procedure LineItemTotalOnChange(Item)
	
TabularPartRow = Items.LineItem.CurrentData;	
DivisionVal = TabularPartRow.Total / 12;

roundval = Round(DivisionVal,2);
actualamt = roundval * 12;
diff = 0;
If actualamt <> TabularPartRow.Total Then
		diff = actualamt - TabularPartRow.Total;
EndIf;

TabularPartRow.Jan = DivisionVal;
TabularPartRow.Feb = DivisionVal; 
TabularPartRow.Mar = DivisionVal;
TabularPartRow.Apr = DivisionVal;
TabularPartRow.May = DivisionVal;
TabularPartRow.Jun = DivisionVal;
TabularPartRow.Jul = DivisionVal;
TabularPartRow.Aug = DivisionVal;
TabularPartRow.Sep = DivisionVal;
TabularPartRow.Oct = DivisionVal;
TabularPartRow.Nov = DivisionVal;
TabularPartRow.Dec = DivisionVal - diff;

EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	//Closing period
	If DocumentPosting.DocumentPeriodIsClosed(Object.Ref, Object.Date) Then
		Cancel = Not DocumentPosting.DocumentWritePermitted(WriteParameters);
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
	If DocumentPosting.DocumentPeriodIsClosed(CurrentObject.Ref, CurrentObject.Date) Then
		PermitWrite = DocumentPosting.DocumentWritePermitted(WriteParameters);
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

