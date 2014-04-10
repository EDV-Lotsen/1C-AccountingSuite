
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Object.User = Catalogs.UserList.EmptyRef() Then
		Object.User =  Catalogs.UserList.FindByDescription(GeneralFunctions.GetUserName());

	Endif;
	
EndProcedure

&AtClient
Procedure TaskOnChange(Item)
	ObjChanged();
	TaskOnChangeAtServer();
EndProcedure

&AtServer
Procedure TaskOnChangeAtServer()
	
	Object.Price = GeneralFunctions.RetailPrice(CurrentDate(),Object.Task,Object.Company);
EndProcedure

&AtClient
Procedure DateToOnChange(Item)
	ObjChanged();
		
EndProcedure


&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	//Period closing
	If PeriodClosingServerCall.DocumentPeriodIsClosed(CurrentObject.Ref, CurrentObject.Date) Then
		PermitWrite = PeriodClosingServerCall.DocumentWritePermitted(WriteParameters);
		CurrentObject.AdditionalProperties.Insert("PermitWrite", PermitWrite);	
	EndIf;	
	
	If Changed = True Then	
		
		If CurrentObject.Billable = False Then
			CurrentObject.InvoiceSent = "Unbillable";
		Else
			CurrentObject.InvoiceSent = "Unbilled";
		Endif;
		
	Endif;

	
EndProcedure

&AtClient
Procedure ObjChanged()
	If Changed = False And Object.SalesInvoice.IsEmpty() = False Then
		Message("You are changing data in an entry that has a linked invoice. Note that changes here are not carried over to the linked invoice and may cause inconsistency.");
	Endif;
	
	Changed = True;
EndProcedure


&AtClient
Procedure OnOpen(Cancel)
	OnOpenAtServer();
EndProcedure


&AtServer
Procedure OnOpenAtServer()
		
	If Object.SalesInvoice.IsEmpty() Then
		Items.SalesInvoice.Visible = False;
	Else
		Items.SalesInvoice.Visible = True;
	EndIf;
	
	If Object.SalesOrder.IsEmpty() = False Then
		Items.SalesOrder.Visible = True;
	EndIf;
	
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

	
	If Changed = True And Object.SalesInvoice.IsEmpty() = False Then
		ShowMessageBox(,"New changes will not change " + Object.SalesInvoice + ". Generating a new invoice for this time entry will link the entry to a new invoice.",,"ChangedEntry"); 
	EndIf;
	
EndProcedure


&AtClient
Procedure LinkSalesOrder(Command)
	LinkSalesOrderAtServer();
	
	    
	
		If (Not Object.Company.IsEmpty()) And (HasNonClosedOrders(Object.Company)) Then
		

		FormParameters = New Structure();
		FormParameters.Insert("ChoiceMode", True);
		FormParameters.Insert("MultipleChoice", True);
		

		FltrParameters = New Structure();
		FltrParameters.Insert("Company", Object.Company); 
		FltrParameters.Insert("OrderStatus", GetNonClosedOrderStatuses());
		FormParameters.Insert("Filter", FltrParameters);
		
		NotifyDescription = New NotifyDescription("OrderSelection", ThisForm);
		OpenForm("Document.SalesOrder.ChoiceForm", FormParameters,,,,,NotifyDescription)
		
	EndIf;	

EndProcedure
	
&AtClient
Procedure OrderSelection(Result, Parameters) Export
	
	If Not Result = Undefined Then
		object.SalesOrder = Result[0];
		Items.SalesOrder.Visible = True;
		Changed = True;
	EndIf;
	
EndProcedure




&AtServer
Procedure LinkSalesOrderAtServer()
	
	
EndProcedure

&AtServer
Function HasNonClosedOrders(Company)
	
	// Create new query
	Query = New Query;
	Query.SetParameter("Company", Company);
	
	QueryText = 
		"SELECT
		|	SalesOrder.Ref
		|FROM
		|	Document.SalesOrder AS SalesOrder
		|	LEFT JOIN InformationRegister.OrdersStatuses.SliceLast AS OrdersStatuses
		|		ON SalesOrder.Ref = OrdersStatuses.Order
		|WHERE
		|	SalesOrder.Company = &Company
		|AND
		|	CASE
		|		WHEN SalesOrder.DeletionMark THEN
		|			 VALUE(Enum.OrderStatuses.Deleted)
		|		WHEN NOT SalesOrder.Posted THEN
		|			 VALUE(Enum.OrderStatuses.Draft)
		|		WHEN OrdersStatuses.Status IS NULL THEN
		|			 VALUE(Enum.OrderStatuses.Open)
		|		WHEN OrdersStatuses.Status = VALUE(Enum.OrderStatuses.EmptyRef) THEN
		|			 VALUE(Enum.OrderStatuses.Open)
		|		ELSE
		|			 OrdersStatuses.Status
		|	END IN (VALUE(Enum.OrderStatuses.Open), VALUE(Enum.OrderStatuses.Backordered))";
	Query.Text  = QueryText;
	
	// Returns true if there are open or backordered orders
	Return Not Query.Execute().IsEmpty();
	
EndFunction

&AtServer
// Returns array of Order Statuses indicating non-closed orders
Function GetNonClosedOrderStatuses()
	
	// Define all non-closed statuses array
	OrderStatuses  = New Array;
	OrderStatuses.Add(Enums.OrderStatuses.Open);
	OrderStatuses.Add(Enums.OrderStatuses.Backordered);
	
	// Return filled array
	Return OrderStatuses;
	
EndFunction

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




