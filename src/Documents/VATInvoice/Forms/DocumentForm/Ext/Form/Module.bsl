
&AtServer
// Procedure fills in default values and sets the date fields formatting.
// 
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	//Title = "VAT invoice " + Object.Number + " " + Format(Object.Date, "DLF=D");
	
	If Object.DueDate = Date(1,1,1) Then
		Object.DueDate = CurrentDate() + 60*60*24*30;
	EndIf;

EndProcedure
