
&AtClient
Procedure RepeatPrinting(Command)
	
	Close(PrintDataFolder);

EndProcedure

&AtClient
Procedure ChangePrintWorkingFolder(Command)
	
	Result = OpenFormModal("InformationRegister.UserPrintTemplates.Form.PrintFolderSetup");
	
	If TypeOf(Result) = Type("String") Then
		PrintDataFolder = Result;
	EndIf;

EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	PrintDataFolder = PrintManagement.GetLocalPrintFolder();
	Items.Message.Title = Items.Message.Title + Chars.LF + Parameters.ErrorMessage;

EndProcedure
