
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	  
	If Parameters.Property("Company") And Parameters.Company.Customer Then
		Object.Company = Parameters.Company;
	EndIf;
	
	If Not ValueIsFilled(Object.User) Then
		Object.User = GeneralFunctions.GetUserName();
	Endif;
	
	If Object.SalesOrder <> Documents.SalesOrder.EmptyRef() Then
		Items.LinkSalesOrder.Title = "Unlink sales order";
	EndIf;
	
	If Object.Ref.IsEmpty() Then
		Object.DateFrom = CurrentDate();
		Object.Billable = True;
	EndIf;
	
	// Update prices presentation.
	PriceFormat = GeneralFunctionsReusable.DefaultPriceFormat();
	Items.Price.EditFormat  = PriceFormat;
	Items.Price.Format      = PriceFormat;	
	StoredTime = Object.TimeComplete*3600;
	SplitDateFromSecondsServer(StoredTime);
	
EndProcedure

&AtClient
Procedure TaskOnChange(Item)
	ObjChanged();
	TaskOnChangeAtServer();
EndProcedure

&AtServer
Procedure TaskOnChangeAtServer()
	
	Object.Price = GeneralFunctions.RetailPrice(CurrentDate(),Object.Task,Object.Company);
	
	Object.Price = Round(Object.Price, GeneralFunctionsReusable.PricePrecisionForOneItem(Object.Task));
	
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
			CurrentObject.InvoiceStatus = Enums.TimeTrackStatus.Unbillable;
		Else
			CurrentObject.InvoiceStatus = Enums.TimeTrackStatus.Unbilled;
		Endif;
		
	Endif;

	
EndProcedure

&AtClient
Procedure ObjChanged()
	//If Changed = False And Object.SalesInvoice.IsEmpty() = False Then
	//	Message("You are changing data in an entry that has a linked invoice. Note that changes here are not carried over to the linked invoice and may cause inconsistency.");
	//Endif;
	
	Object.Price = Round(Object.Price, GeneralFunctionsReusable.PricePrecisionForOneItem(Object.Task));
	
	Changed = True;
	
EndProcedure


&AtClient
Procedure OnOpen(Cancel)
	
	OnOpenAtServer();
	
	AttachIdleHandler("AfterOpen", 0.1, True);
	
EndProcedure

&AtClient
Procedure AfterOpen()
	
	ThisForm.Activate();
	
	If ThisForm.IsInputAvailable() Then
		///////////////////////////////////////////////
		DetachIdleHandler("AfterOpen");
		
		If  Object.Ref.IsEmpty() And ValueIsFilled(Object.Company) Then
			ObjChanged();	
		EndIf;	
		///////////////////////////////////////////////
	Else 
		AttachIdleHandler("AfterOpen", 0.1, True);
	EndIf;		
	
EndProcedure

&AtServer
Procedure OnOpenAtServer()
		
	If Object.SalesInvoice.IsEmpty() OR Object.Billable = False Then
		Items.SalesInvoice.Visible = False;
	Else
		Items.SalesInvoice.Visible = True;
		Items.UnlinkSalesInvoice.Visible = True;
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

	
	Items.TimerStartStop.Title = "Start";
	Items.TimeComplete.ReadOnly = False;
	DetachIdleHandler("Timer");
	If TimerStart Then
		TimerStart = False;
		
		CurDate = Undefined;
		GetCurrentDate(CurDate);
		
		DifferenceInSec = CurDate - StartTime;
		StoredTime = StoredTime + DifferenceInSec;
		Hours = Int(StoredTime/3600);
		DivResidue = StoredTime%3600;
		Minutes = Int(DivResidue/60);
		Seconds = DivResidue%60;
		Object.TimeComplete = StoredTime/3600;
	EndIf;	
	
EndProcedure


&AtClient
Procedure LinkSalesOrder(Command)
	
	If LinkSalesOrderAtServer() = False Then
	
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
	EndIf;

EndProcedure
	
&AtClient
Procedure OrderSelection(Result, Parameters) Export
	
	If Not Result = Undefined Then
		object.SalesOrder = Result[0];
		Items.SalesOrder.Visible = True;
		Items.LinkSalesOrder.Title = "Unlink sales order";
		Changed = True;
	EndIf;
	
EndProcedure




&AtServer
Function LinkSalesOrderAtServer()
	
	If Object.SalesOrder <> Documents.SalesOrder.EmptyRef() Then
		Object.SalesOrder = Documents.SalesOrder.EmptyRef();
		Items.LinkSalesOrder.Title = "Link sales order";
		Return True;
	EndIf;
	
	Return False
	
EndFunction

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

&AtClient
Procedure UnlinkSalesInvoice(Command)
	UnlinkSalesInvoiceAtServer();
EndProcedure

&AtServer
Procedure UnlinkSalesInvoiceAtServer()

	Object.SalesInvoice = Documents.SalesInvoice.EmptyRef();
	Items.SalesInvoice.Visible = False;
	Items.UnlinkSalesInvoice.Visible = False;
	Object.InvoiceStatus = Enums.TimeTrackStatus.Unbilled;
	Modified = True;
	
EndProcedure

&AtClient
Procedure TimerStartStop(Command)
	
	If NOT TimerStart Then
		GetCurrentDate(StartTime);
		Items.TimerStartStop.Title = "Pause";
		Items.TimeComplete.ReadOnly = True;
		AttachIdleHandler("Timer",1);
		TimerStart = True;
	Else
		Items.TimeComplete.ReadOnly = False;
		Items.TimerStartStop.Title = "Start";
		DetachIdleHandler("Timer");
		TimerStart = False;
		//Object.TimeComplete = Hours + (Minutes/100);
		
		CurDate = Undefined;
		GetCurrentDate(CurDate);
		DifferenceInSec = CurDate - StartTime;
		StoredTime = StoredTime + DifferenceInSec;
		Hours = Int(StoredTime/3600);
		DivResidue = StoredTime%3600;
		Minutes = Int(DivResidue/60);
		Seconds = DivResidue%60;
		Object.TimeComplete = StoredTime/3600;
		
	EndIf;

EndProcedure

&AtClient
Procedure Timer()
	
	//CurDate = Undefined;
	//GetCurrentDate(CurDate);
	//DifferenceInSec = CurDate - StartTime;
	//LockalWorkTime = StoredTime + DifferenceInSec;
	//Hours = Int(LockalWorkTime/3600);
	//DivResidue = LockalWorkTime%3600;
	//Minutes = Int(DivResidue/60);
	//Seconds = DivResidue%60;
	StopTimerAndFixThetimePosition();
	
EndProcedure

&AtServer
Procedure SplitDateFromSecondsServer(DateToSplit)
	
	Hours = Int(DateToSplit/3600);
	DivResidue = DateToSplit%3600;
	Minutes = Int(DivResidue/60);
	Seconds = DivResidue%60;
	
EndProcedure

&AtClient
Procedure TimerReset(Command)
	
	Items.TimeComplete.ReadOnly = False;
	Items.TimerStartStop.Title = "Start";
	DetachIdleHandler("Timer");
	Hours = 0;
	Minutes = 0;
	Seconds = 0;
	StoredTime = 0;
	Object.TimeComplete = 0;
	TimerStart = False;

EndProcedure

&AtServer
Procedure GetCurrentDate(CurrentTimeStamp) Export 
	CurrentTimeStamp = CurrentSessionDate();
EndProcedure


&AtServer
Procedure StopTimerAndFixThetimePosition() Export 
	
	CurDate = Undefined;
	GetCurrentDate(CurDate);
	DifferenceInSec = CurDate - StartTime;
	LocalWorkTime = StoredTime + DifferenceInSec;
	SplitDateFromSecondsServer(LocalWorkTime);
EndProcedure

&AtClient
Procedure HoursOnChange(Item)
	
	StoredTime = Object.TimeComplete*3600;
	Hours = Int(StoredTime/3600);
	DivResidue = StoredTime%3600;
	Minutes = Int(DivResidue/60);
	Seconds = DivResidue%60;
	
	ObjChanged();
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, StandardProcessing)
	BeforeCloseAtServer();
EndProcedure

&AtServer
Procedure BeforeCloseAtServer()
	If TimerStart Then 
		ThisObject.Modified = True;
	EndIf;	
EndProcedure





