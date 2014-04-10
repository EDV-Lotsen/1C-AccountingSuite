
&AtClient
Procedure DaysAndHoursOnChange(Item)
	TotalHours = DaysAndHours.Total("Hours");
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Object.User = Catalogs.UserList.EmptyRef() Then
		Object.User =  Catalogs.UserList.FindByDescription(GeneralFunctions.GetUserName());
	Endif;

EndProcedure


&AtClient
Procedure ObjectTaskOnChange(Item)
	ObjectTaskOnChangeAtServer();
EndProcedure


&AtServer
Procedure ObjectTaskOnChangeAtServer()
	
	Object.Price = GeneralFunctions.RetailPrice(CurrentDate(),Object.Task,Object.Company);

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
		NewTimeEntry.Price = Object.Price;
		NewTimeEntry.Billable = Object.Billable;
		NewTimeEntry.DateFrom = Line.Date;
		NewTimeEntry.TimeComplete = Line.Hours;
		NewTimeEntry.Memo = Line.Note;
		If Object.Billable = False Then
			NewTimeEntry.InvoiceSent = "Unbillable";
		Else
			NewTimeEntry.InvoiceSent = "Unbilled";
		Endif;

		
		NewTimeEntry.Write(DocumentWriteMode.Posting);
		
	EndDo;
				
EndProcedure
