
&AtClient
Procedure ОК(Command)
	
	PrintManagement.SaveLocalPrintFolder(PrintDataFolder);
	Close(PrintDataFolder);

EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	PrintDataFolder = PrintManagement.GetLocalPrintFolder();

EndProcedure

&AtClient
Procedure PrintDataFolderStartChoice(Item, ChoiceData, StandardProcessing)
	
	If AttachFileSystemExtension() Then
		FileOpenDialog = New FileDialog(FileDialogMode.ChooseDirectory);
		FileOpenDialog.FullFileName = "";
		FileOpenDialog.Directory = PrintDataFolder;
		FileOpenDialog.Multiselect = False;
		FileOpenDialog.Title = NStr("en = 'Select path to the print folder'");
		If FileOpenDialog.Choose() Then
			PrintDataFolder = FileOpenDialog.Directory + "\";
		EndIf;
	Else
		DoMessageBox(NStr("en = 'To select a folder install the web-client file extension module.'"));
	EndIf;

EndProcedure
