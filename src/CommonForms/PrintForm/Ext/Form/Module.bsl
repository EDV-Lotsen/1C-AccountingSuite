
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("SpreadsheetDocument") Then
		SpreadsheetDocument = Parameters.SpreadsheetDocument;
		ThisForm.Title      = Parameters.TitleOfForm;
	Else
		Cancel = True;	
	EndIf;
	
EndProcedure

&AtClient
Procedure Print(Command)
	
	PrintAtServer();
	SpreadsheetDocument.Print(PrintDialogUseMode.Use);
	
EndProcedure

&AtServer
Procedure PrintAtServer()
	
	SpreadsheetDocument.PageSize  = "Letter"; 
	SpreadsheetDocument.FitToPage = True;
	
EndProcedure

