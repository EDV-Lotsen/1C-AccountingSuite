
&AtServer
Procedure OnCreateAtServer(Cancellation, StandardProcessing)
	
	DirrectoryForPrintDataSave = PrintManagement.GetPrintFilesLocalDirectory();
	
EndProcedure

&AtClient
Procedure PathToDirectoryStartChoice(Item, ChoiceData, StandardProcessing)
	
	If AttachFileSystemExtension() Then
		FileOpenDialog = New FileDialog(FileDialogMode.ChooseDirectory);
		FileOpenDialog.FullFileName = "";
		FileOpenDialog.Directory = DirrectoryForPrintDataSave;
		FileOpenDialog.Multiselect = False;
		FileOpenDialog.Title = NStr("en = 'Select path to the  directory of printing files'");
		If FileOpenDialog.Choose() Then
			DirrectoryForPrintDataSave = FileOpenDialog.Directory + "\";
		EndIf;
	Else
		DoMessageBox(NStr("en = 'To select the directory it is necessary to attach file system extension to work in the Web Client.'"));
	EndIf;
	
EndProcedure

&AtClient
Procedure OK(Command)
	
	PrintManagement.SaveLocalDirectoryOfPrintFiles(DirrectoryForPrintDataSave);
	Close(DirrectoryForPrintDataSave);
	
EndProcedure
