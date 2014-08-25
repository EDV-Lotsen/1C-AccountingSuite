

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	Items.Company.Title = GeneralFunctionsReusable.GetVendorName();	
	//currentButton = Items.Add("Button1", Type("FormButton"), Items.ListContextMenu);
	//currentButton.CommandName = "MarkVoid";

EndProcedure

&AtClient
Procedure MarkAsVoid(Command)
	Notify = New NotifyDescription("OpenJournalEntry", ThisObject);
	OpenForm("CommonForm.VoidDateForm",,,,,,Notify,FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

&AtClient
Procedure OpenJournalEntry(Parameter1,Parameter2) Export
	
	SelectedItemNumber = Items.List.CurrentData.Number;
	Str = New Structure;
	Str.Insert("InvoicePayNumber", SelectedItemNumber);
	Str.Insert("VoidDate", Parameter1);
	If Parameter1 <> Undefined Then
		OpenForm("Document.GeneralJournalEntry.ObjectForm",Str);	
	EndIf;
EndProcedure
