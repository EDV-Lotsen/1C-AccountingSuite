
&AtClient
Procedure DaysAndHoursOnChange(Item)
	TotalHours = DaysAndHours.Total("Hours");
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
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
				
EndProcedure

&AtClient
Procedure ObjectPriceOnChange(Item)
	
	Object.Price = Round(Object.Price, GeneralFunctionsReusable.PricePrecisionForOneItem(Object.Task));
	
EndProcedure
