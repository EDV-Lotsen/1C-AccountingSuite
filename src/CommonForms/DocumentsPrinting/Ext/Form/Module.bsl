
////////////////////////////////////////////////////////////////////////////////
// PROCEDURES - FORM EVENTS HANDLERS

&AtServer
Procedure OnCreateAtServer(Cancellation, StandardProcessing)
	
	Var PrintFormsCollection, OutputParameters;
	
	If Parameters.Property("DataSource") Then
		
		If NOT PrintManagementOverrided.PrintFromExternalDataSource(
					Parameters.DataSource,
					Parameters.SourceParameters,
					PrintFormsCollection,
					PrintObjects,
					OutputParameters) Then
			Cancellation = True;
			Return;
		EndIf;
		
	Else
		
		PrintManagerName 	= Parameters.PrintManagerName;
		TemplateNames       = Parameters.TemplateNames;
		CommandParameter    = Parameters.CommandParameter;
		PrintParameters    	= Parameters.PrintParameters;
		
		PrintManagement.GeneratePrintForms(PrintManagerName, TemplateNames, CommandParameter, PrintParameters,
			PrintFormsCollection, PrintObjects, OutputParameters);
		
	EndIf;
	
	AvailablePrintingByKits = OutputParameters.AvailablePrintingByKits;
	
	Quanty = PrintFormsCollection.Count();
	For Acc = 1 To 5 Do
		If Acc > Quanty Then
			ThisForm["Tab" + Acc] 		 	= Undefined;
			Items["Group" + Acc].Visible 	= False;
			Items["Cc"  + Acc].Visible 		= False;
			
		Else
			TemplateStr = PrintFormsCollection[Acc-1];
			
			ThisForm["Tab" + Acc] 		 = TemplateStr.SpreadsheetDocument;
			Items["Group" + Acc].Visible = True;
			Items["Group" + Acc].Title 	 = TemplateStr.TemplateSynonym;
			Items["Cc"  + Acc].Visible 	 = True;
			Items["Cc"  + Acc].Title 	 = TemplateStr.TemplateSynonym;
			
			ThisForm["Cc" + Acc] = TemplateStr.NumberOfCopies;
			
			TabDocumentNames.Add(Acc, TemplateStr.TemplateSynonym);
			
			If NOT IsBlankString(TemplateStr.FullPathToTemplate) Then
				PrintedFormTemplates.Add(TemplateStr.FullPathToTemplate);
			EndIf;
		EndIf;
	EndDo;
	
	If Quanty = 1 Then
		Items.GroupCopies.Visible = False;
		Items.Cc.Visible = True;
		Cc = PrintFormsCollection[0].NumberOfCopies;
	Else
		Items.Cc.Visible = False;
		Items.GroupCopies.Visible = True;
	EndIf;
	
	If Quanty <= 1 Then
		Items.Pages.PagesRepresentation = FormPagesRepresentation.None;
	EndIf;
	
	If Users.CurrentUserHaveFullAccess()
	OR ( IsInRole("PrintWriteFilesUseClipboard")
		And EmailOperations.SystemAccountAvailable() )Then
		SystemAccountOfEmail = EmailOperations.GetSystemAccount();
	Else
		 Items.SendViaEmail.Visible = False;
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// PROCEDURES - FORM ITEMS EVENT HANDLERS

&AtClient
Procedure PrintExecute(Command)
	
	SpreadsheetDocuments = New ValueList;
	
	For Each TabDocument In TabDocumentNames Do
		SpreadsheetDocuments.Add(ThisForm["Tab" + TabDocument.Value], TabDocument.Presentation);
	EndDo;
	
	PrintManagementClient.PrintSpreadsheetDocuments(SpreadsheetDocuments, PrintObjects,
								AvailablePrintingByKits);
	
EndProcedure

&AtClient
Procedure CopiesOnChange(Item)
	
	OfCopies 			= ThisForm[Item.Name];
	TabDocName  		= "Tab" + ?(Item.Name = "Cc", "1", Mid(Item.Name, 6));
	Spreadsheet			= ThisForm[TabDocName];
	Spreadsheet.Copies  = OfCopies;

EndProcedure

&AtClient
Procedure GoToExecute(Command)

	choiceLst = New ValueList;
	For Each Item In PrintObjects Do
		choiceLst.Add(Item.Value);
	EndDo;
	
	Item = choiceLst.ChooseItem(NStr("en = 'Go to print form'"));
	If Item = Undefined Then
		Return;
	EndIf;
	
	Item = PrintObjects.FindByValue(Item.Value);
	If Item = Undefined Then
		Return;
	EndIf;
	
	AreaName = Item.Presentation;
	For Each TabDocument In TabDocumentNames Do
		
		TagName = "Tab" + TabDocument.Value;
		Tab = ThisForm[TagName];
		Area = Tab.Areas.Find(AreaName);
		If Area = Undefined Then
			Continue;
		EndIf;
		
		CurrentArea = Tab.Area(Area.Top, , Area.Top);
		Items[TagName].CurrentArea = CurrentArea;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure GoToLayoutsManagement(Command)
	
	OpenParameters = ?(PrintedFormTemplates.Count() > 0, New Structure("Filter", PrintObjects[0].Value), Undefined);
	
	OpenForm("InformationRegister.PrintedFormTemplates.Form.PrintedFormTemplates", OpenParameters);
	
EndProcedure

&AtClient
Procedure SendViaEmailExecute(Command)
	
	Result = OpenFormModal("CommonForm.PrintingFormsSettingsBeforeSending");
	
	If TypeOf(Result) <> Type("Structure") Then
		Return;
	EndIf;
	
	Attachments = New Map;
	
	FileList = New ValueList;
	
	If Result.PackageZIP Then
#If WebClient Then
		Path = PlaceSpreadsheetDocumentsIntoZIPAtServer();
#Else
		Path = PlaceSpreadsheetDocumentsIntoZIPAtClient(Result);
#EndIf
		
		If Path = "" Then
			Return;
		EndIf;
		
		TemplateNames = "";
		For Each TabDocumentName In TabDocumentNames Do
			TemplateNames = TemplateNames + TabDocumentName.Presentation + ", ";;
		EndDo;
		TemplateNames = Left(TemplateNames, StrLen(TemplateNames) - 2);
		DatePresentation = Format(CurrentDate(), "DF='yyyyMMdd HH:mm'");
		
		If PrintObjects.Count() > 1 Then
			FileName = "[TemplateNames] ([DatePresentation]).zip";
		Else
			FileName = "[Document] ([TemplateNames] [DatePresentation]).zip";
		EndIf;
		
		FileName = StrReplace(FileName, "[Document]",			String(PrintObjects[0].Value));
		FileName = StrReplace(FileName, "[TemplateNames]",		TemplateNames);
		FileName = StrReplace(FileName, "[DatePresentation]",	DatePresentation);
		
		FileList.Add(Path, FileName);
	Else
#If WebClient Then
		PlaceSpreadsheetDocumentsToTemporaryStorage(FileList);
#Else
		PlaceSpreadsheetDocumentsToFiles(FileList, Result);
#EndIf
EndIf;
	
	NormalizeFileNames(FileList);
	
	WorkWithEmailsClient.OpenEmailMessageSendForm(
		// From,              Recipient, Subject, Text, Attach,   Clear_on_complete
		SystemAccountOfEmail, "",        "",       "",  FileList, True);
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// FUNCTIONS AND PROCEDURES PREPARING SPREADSHEET DOCUMENTS FOR SENDING

&AtServer
Function PlaceSpreadsheetDocumentsIntoZIPAtServer()

	DirectoryName = GetTempFileName();
	ArchiveName   = GetTempFileName();
	WasError  	  = False;

	CreateDirectory(DirectoryName);
	Try
		Archive = New ZipFileWriter(ArchiveName);
		
		For Each TabDocument In TabDocumentNames Do
			TabDocName = DirectoryName + "/" + TabDocument.Presentation + ".mxl";
			Spreadsheet = ThisForm["Tab" + TabDocument.Value];
			Spreadsheet.Write(TabDocName, SpreadsheetDocumentFileType.MXL);
			Archive.Add(TabDocName, ZIPStorePathMode.DontStorePath);
		EndDo;

		Archive.Write();
	Except
		CommonUseClientServer.MessageToUser(BriefErrorDescription(ErrorInfo()));
		WasError = True;
	EndTry;

	DeleteFiles(DirectoryName);

	If WasError Then
		Return "";
	EndIf;

	Data = New BinaryData(ArchiveName);
	DeleteFiles(ArchiveName);
	
	Return PutToTempStorage(Data, "");

EndFunction

&AtServer
Procedure PlaceSpreadsheetDocumentsToTemporaryStorage(FileList)
	
	TemporaryFileName = GetTempFileName();
	DatePresentation = Format(CurrentDate(), "DF='yyyyMMdd HH:mm'");
	
	For Each TabDocument In TabDocumentNames Do
		Spreadsheet = ThisForm["Tab" + TabDocument.Value];
		Spreadsheet.Write(TemporaryFileName, SpreadsheetDocumentFileType.MXL);
		Data = New BinaryData(TemporaryFileName);
		Path = PutToTempStorage(Data, "");
		
		If PrintObjects.Count() > 1 Then
			FileName = "[DesignName] ([DatePresentation]).mxl";
		Else
			FileName = "[Document] ([DesignName] [DatePresentation]).mxl";
		EndIf;
		
		FileName = StrReplace(FileName, "[Document]",			String(PrintObjects[0].Value));
		FileName = StrReplace(FileName, "[DesignName]",			TabDocument.Presentation);
		FileName = StrReplace(FileName, "[DatePresentation]",	DatePresentation);
		
		FileList.Add(Path, FileName);
	EndDo;
	
	DeleteFiles(TemporaryFileName);
	
EndProcedure

#If Not WebClient Then
&AtClient
Procedure PlaceSpreadsheetDocumentsToFiles(FileList, Result)
	
	ListOfTypes = GetTableDocumentsFileTypesList(Result);
	DatePresentation = Format(CurrentDate(), "DF='yyyyMMdd HH:mm'");
	
	For Each TabDocument In TabDocumentNames Do
		Spreadsheet = ThisForm["Tab" + TabDocument.Value];
		
		For Each FileType In ListOfTypes Do
			TemporaryFileName = GetTempFileName(FileType.Presentation);
			Spreadsheet.Write(TemporaryFileName, FileType.Value);
			
			If PrintObjects.Count() > 1 Then
				FileName = "[DesignName] ([DatePresentation]).[Extension]";
			Else
				FileName = "[Document] ([DesignName] [DatePresentation]).[Extension]";
			EndIf;
			
			FileName = StrReplace(FileName, "[Document]",			String(PrintObjects[0].Value));
			FileName = StrReplace(FileName, "[DesignName]",			TabDocument.Presentation);
			FileName = StrReplace(FileName, "[DatePresentation]",	DatePresentation);
			FileName = StrReplace(FileName, "[Extension]",			FileType.Presentation);
			
			FileList.Add(TemporaryFileName, FileName);
		EndDo;
	EndDo;
	
EndProcedure

&AtClient
Function PlaceSpreadsheetDocumentsIntoZIPAtClient(Result)
	
	DirectoryName = GetTempFileName();
	ArchiveName   = GetTempFileName("zip");
	WasError  = False;
	
	ListOfTypes = GetTableDocumentsFileTypesList(Result);
	
	CreateDirectory(DirectoryName);
	
	Try
		Archive = New ZipFileWriter(ArchiveName);
		
		For Each TabDocument In TabDocumentNames Do
			Spreadsheet = ThisForm["Tab" + TabDocument.Value];
			
			For Each FileType In ListOfTypes Do
				TabDocName = DirectoryName + "/" + TabDocument.Presentation + "." + FileType.Presentation;
				Spreadsheet.Write(TabDocName, FileType.Value);
				Archive.Add(TabDocName, ZIPStorePathMode.DontStorePath);
			EndDo;
		EndDo;
		
		Archive.Write();
	Except
		WasError = True;
	EndTry;
	
	DeleteFiles(DirectoryName);
	
	If WasError Then
		Return "";
	EndIf;
	
	Return ArchiveName;
	
EndFunction
#EndIf

&AtClient
Function GetTableDocumentsFileTypesList(Result)
	
	ListOfTypes = New ValueList;
	
	If Result.FormatMXL Then
		ListOfTypes.Add(SpreadsheetDocumentFileType.MXL, "mxl");
	EndIf;
	
	If Result.FormatHTML Then
		ListOfTypes.Add(SpreadsheetDocumentFileType.HTML, "html");
	EndIf;
	
	If Result.FormatXLS Then
		ListOfTypes.Add(SpreadsheetDocumentFileType.XLS, "xls");
	EndIf;
	
	Return ListOfTypes;	
	
EndFunction

&AtClient
Procedure NormalizeFileNames(FileList)
	
	StrExceptions = """ / \ [ ] : ; | = , ? * < >";
	StrExceptions = StrReplace(StrExceptions, " ", "");
	
	For Each ItemFile In FileList Do
		For IndexOf = 1 To StrLen(StrExceptions) Do
			
			Char = Mid(StrExceptions, IndexOf, 1);
			
			If Find(ItemFile.Presentation, Char) > 0 Then
				ItemFile.Presentation = StrReplace(ItemFile.Presentation, Char, " ");
			EndIf;
			
		EndDo;
		
	EndDo;
	
EndProcedure
