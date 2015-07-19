
&AtClient
Procedure DaysAndHoursOnChange(Item)
	TotalHours = DaysAndHours.Total("Hours");
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	DataWasSaved = False;
	If Object.User = Catalogs.UserList.EmptyRef() Then
		Object.User =  Catalogs.UserList.FindByDescription(GeneralFunctions.GetUserName());
	Endif;
	Object.Billable = True;
	
	// Update prices presentation.
	PriceFormat = GeneralFunctionsReusable.DefaultPriceFormat();
	Items.ObjectPrice.EditFormat  = PriceFormat;
	Items.ObjectPrice.Format      = PriceFormat;	

EndProcedure


&AtClient
Procedure ObjectTaskOnChange(Item)
	ObjectTaskOnChangeAtServer();
EndProcedure


&AtServer
Procedure ObjectTaskOnChangeAtServer()
	
	Object.Price = GeneralFunctions.RetailPrice(CurrentDate(),Object.Task,Object.Company);
	
	Object.Price = Round(Object.Price, GeneralFunctionsReusable.PricePrecisionForOneItem(Object.Task));

EndProcedure


&AtClient
Procedure CreateEntries(Command)
	CreateEntriesAtServer();
	Close();
EndProcedure


&AtServer
Procedure CreateEntriesAtServer()
		
	For Each Line In DaysAndHours Do
		
		NewTimeEntry = Documents.TimeTrack.CreateDocument();
		NewTimeEntry.Date = CurrentDate();
		NewTimeEntry.User = Object.User;
		NewTimeEntry.Company = Object.Company;
		NewTimeEntry.Project = Object.Project;
		NewTimeEntry.Class = Object.Class;
		NewTimeEntry.Task = Object.Task;
		NewTimeEntry.Price = Round(Object.Price, GeneralFunctionsReusable.PricePrecisionForOneItem(Object.Task));
		NewTimeEntry.Billable = Object.Billable;
		NewTimeEntry.DateFrom = Line.Date;
		NewTimeEntry.TimeComplete = Line.Hours;
		NewTimeEntry.Memo = Line.Note;
		If Object.Billable = False Then
			NewTimeEntry.InvoiceStatus = Enums.TimeTrackStatus.Unbillable;
		Else
			NewTimeEntry.InvoiceStatus = Enums.TimeTrackStatus.Unbilled;
		Endif;

		
		NewTimeEntry.Write(DocumentWriteMode.Posting);
		
	EndDo;
	
	DataWasSaved = True;
				
EndProcedure

&AtClient
Procedure ObjectPriceOnChange(Item)
	
	Object.Price = Round(Object.Price, GeneralFunctionsReusable.PricePrecisionForOneItem(Object.Task));
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, StandardProcessing)
	
	Cancel = True;
		
	QueryNotification = New NotifyDescription("SaveDataOnClient", ThisForm);
	QueryMessage = NStr("en = ""Data has been changed. Do you want to save changes?""; ru = ""Данные были изменены. Сохранить изменения?""");
	If Not DataWasSaved and DaysAndHours.Count() > 0 Then 
		ShowQueryBox(QueryNotification, QueryMessage, QuestionDialogMode.YesNoCancel); 
	Else 	
		Cancel = False;
	EndIf;	
EndProcedure

&AtClient
Procedure SaveDataOnClient(QueryResult, Parameters = Undefined) Export
	//ResultYes = QueryResult = DialogReturnCode.Yes;
	If QueryResult = DialogReturnCode.Yes Then 
		CreateEntriesAtServer();
		Cancel = False;
		DataWasSaved = True;
	ElsIf QueryResult = DialogReturnCode.Cancel Then 
		Cancel = True;
	Else 
		Cancel = False;
		DataWasSaved = True;
	EndIf;	
	
	If Not Cancel Then 
		Close();
	EndIf;	
		
EndProcedure
