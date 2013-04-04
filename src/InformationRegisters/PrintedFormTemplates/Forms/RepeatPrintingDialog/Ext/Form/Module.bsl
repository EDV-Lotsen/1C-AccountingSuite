

&AtClient
Procedure ChangePrintWorkingDirectory(Command)
	
	Result = OpenFormModal("InformationRegister.PrintedFormTemplates.Form.PrintFilesFolderSettings");
	
	If TypeOf(Result) = Type("String") Then
		DirrectoryForPrintDataSave = Result;
	EndIf;
	
EndProcedure

&AtClient
Procedure RetryPrint(Command)
	Close(DirrectoryForPrintDataSave);
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancellation, StandardProcessing)
	
	DirrectoryForPrintDataSave = PrintManagement.GetPrintFilesLocalDirectory();
	Items.Message.Title = Items.Message.Title + Chars.LF + Parameters.MessageAboutError;
	
EndProcedure
