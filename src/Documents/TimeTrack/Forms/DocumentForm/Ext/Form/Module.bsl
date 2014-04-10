
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Object.User = Catalogs.UserList.EmptyRef() Then
		Object.User =  Catalogs.UserList.FindByDescription(GeneralFunctions.GetUserName());
		//Object.LogType = "Single";
	Endif;
	
	If Object.Ref = Documents.TimeTrack.EmptyRef() Then
		Object.LogType = "Single";
	Endif;
	
	LogTypeOnChangeAtServer();
EndProcedure

&AtClient
Procedure TaskOnChange(Item)
	ObjChanged();
	TaskOnChangeAtServer();
EndProcedure

&AtServer
Procedure TaskOnChangeAtServer()
	// Insert handler contents.
	Object.Price = GeneralFunctions.RetailPrice(CurrentDate(),Object.Task,Object.Company);
EndProcedure

&AtClient
Procedure DateToOnChange(Item)
	ObjChanged();
	
	If Object.Ref.IsEmpty() Then		
		Object.DateTo = Object.DateFrom + 6*60*60*24;
		Items.day1.title = Format(Object.DateFrom,"DLF=D"); //+ 6*60*60*24;
		Items.day2.title = Format(Object.DateFrom + 1*60*60*24,"DLF=D");
		Items.day3.title = Format(Object.DateFrom + 2*60*60*24,"DLF=D");
		Items.day4.title = Format(Object.DateFrom + 3*60*60*24,"DLF=D");
		Items.day5.title = Format(Object.DateFrom + 4*60*60*24,"DLF=D");
		Items.day6.title = Format(Object.DateFrom + 5*60*60*24,"DLF=D");
		Items.day7.title = Format(Object.DateFrom + 6*60*60*24,"DLF=D");

	Endif;
	
EndProcedure

&AtClient
Procedure LogTypeOnChange(Item)
	LogTypeOnChangeAtServer();
EndProcedure

&AtServer
Procedure LogTypeOnChangeAtServer()
	
	If Object.LogType = "Single" Then
		Items.DateFrom.ToolTipRepresentation = ToolTipRepresentation.None;
		Items.DateTo.Visible = False;
		Items.DateFrom.Title = "Date";
		Items.Week.Visible = False;
		Items.TimeComplete.ReadOnly = False;
	Else
		Object.TimeComplete = 0;
		Items.TimeComplete.ReadOnly = True;
		Items.DateFrom.ToolTip = "Make sure this day is a Monday.";
		Items.DateFrom.ToolTipRepresentation = ToolTipRepresentation.ShowBottom;
		Items.DateTo.Visible = True;
		Items.DateFrom.Title = "Date From";
		Items.DateTo.ReadOnly = True;
		Items.Week.Visible = True;
		Object.TimeComplete = Object.Mon + Object.Tue + Object.Wed + Object.Thur + Object.Fri + Object.Sat + Object.Sun;
	Endif;
	

EndProcedure

&AtClient
Procedure ReviseHours()
	ObjChanged();
	If Object.LogType = "Week" Then
		Object.TimeComplete = Object.Mon + Object.Tue + Object.Wed + Object.Thur + Object.Fri + Object.Sat + Object.Sun;
	Endif;
	
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
			CurrentObject.InvoiceSent = "Unsent";
		Endif;
		
	Endif;

	
EndProcedure

&AtClient
Procedure ObjChanged()
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


