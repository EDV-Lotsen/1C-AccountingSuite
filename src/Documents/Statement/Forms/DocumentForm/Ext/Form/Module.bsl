
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Object.Ref.IsEmpty() Then
		Cancel = True;
	Else
		GeneratePrintForm();
	EndIf;
	
EndProcedure

&AtClient
Procedure MailingAddressOnChange(Item)
	
	Write();
	GeneratePrintForm();
	
EndProcedure

&AtServer
Procedure GeneratePrintForm()
	
	Array = New Array();
	Array.Add(Object.Ref);
	
	Documents.Statement.Print(Result, Array);
	
EndProcedure

