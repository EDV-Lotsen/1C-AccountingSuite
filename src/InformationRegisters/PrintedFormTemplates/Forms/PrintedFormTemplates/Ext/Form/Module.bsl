
&AtServerNoContext
Procedure FillTreeByMetadataCollection(TemplatesListTree,
												MetadataCollection,
												Val TemplatesCollection,
												Filter = Undefined)
	
	If TemplatesCollection Then
		AddLayoutCollection(MetadataCollection,
								TemplatesListTree,
								"CommonTemplate",
								"Overall templates",
								Filter);
	Else
		For Each ItemMDObject In MetadataCollection Do
			AddLayoutCollection(ItemMDObject.Templates,
									TemplatesListTree,
									ItemMDObject.FullName(),
									ItemMDObject.Synonym,
									Filter);
		EndDo;
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure AddLayoutCollection(Templates, TemplatesListTree, FullName, Presentation, Filter)
	
	Var TemplateType;
	
	If ValueIsFilled(Filter) And Upper(FullName) <> Upper(Filter) Then
		Return;
	EndIf;
	
	FirstPFTemplate = True;
	
	For Each ItemTemplate In Templates Do
		If ThisIsPrintForm(ItemTemplate.Name, TemplateType) Then
			If FirstPFTemplate Then
				MONewRow = TemplatesListTree.Rows.Add();
				MONewRow.ThisIsClassifier	= True;
				MONewRow.FullMOName		= FullName;
				MONewRow.Presentation		= Presentation;
				MONewRow.Picture			= GetPictureCode(FullName);
				FirstPFTemplate = False;
			EndIf;
			NewRowTemplate = MONewRow.Rows.Add();
			NewRowTemplate.DesignName     = ItemTemplate.Name;
			NewRowTemplate.Presentation = ItemTemplate.Synonym;
			NewRowTemplate.TemplateType     = TemplateType;
			NewRowTemplate.Use = False;
			NewRowTemplate.UseString = GetTextByUsage(NewRowTemplate.Use);
			NewRowTemplate.IsUserTemplate = False;
			NewRowTemplate.ThisIsClassifier = False;
			NewRowTemplate.Picture = GetPictureCode(TemplateType);
		EndIf;
	EndDo;
	
EndProcedure

// Checks each metadata object - document, for the subsystems print forms
// (using the PF_<type of print form> prefix) and after fills choice list on the form
//
&AtServer
Procedure FillMetadataList(Filter = Undefined)
	
	TemplatesListTree = FormAttributeToValue("TemplatesList");
	
	FillTreeByMetadataCollection(TemplatesListTree, Metadata.Documents, False, Filter);
	FillTreeByMetadataCollection(TemplatesListTree, Metadata.DataProcessors, False);
	FillTreeByMetadataCollection(TemplatesListTree, Metadata.CommonTemplates, True);
	
	If TemplatesListTree.Rows.Count() > 0 Then
		Query = New Query;
		Query.Text = "SELECT Object, DesignName, Use
						|FROM
						|	InformationRegister.PrintedFormTemplates";
		
		Selection = Query.Execute().Choose();
		
		While Selection.Next() Do
			TreeRow = TemplatesListTree.Rows.Find(Selection.Object, "FullMOName");
			If TreeRow = Undefined Then
				Continue;
			EndIf;
			TemplateDescriptionRow = TreeRow.Rows.Find(Selection.DesignName, "DesignName");
			If TemplateDescriptionRow <> Undefined Then
				TemplateDescriptionRow.IsUserTemplate = True;
				TemplateDescriptionRow.Use = Selection.Use;
				TemplateDescriptionRow.UseString = GetTextByUsage(TemplateDescriptionRow.Use);
				TemplateDescriptionRow.Picture = GetPictureCode(TemplateDescriptionRow.TemplateType)
			EndIf;
		EndDo;
	EndIf;
	
	ValueToFormAttribute(TemplatesListTree, "TemplatesList");
	
EndProcedure // FillMetadataList()

// Checks that this is the print form using passed template description (from metadata)
//
&AtServerNoContext
Function ThisIsPrintForm(DesignName, TemplateType = "")
	
	CharPosition = Find(DesignName, "PF_DOC");
	CharPosition = ?(CharPosition = 0, Find(DesignName, "PF_ODT"), CharPosition);
	CharPosition = ?(CharPosition = 0, Find(DesignName, "PF_MXL"), CharPosition);
	
	If CharPosition = 0 Then
		Return False;
	Else
		TemplateType = Mid(DesignName, CharPosition + 3, 3);
		Return True;
	EndIf;
	
EndFunction

// Procedure is used to adjust accessibility of the form buttons,
// depending on the selected data
//
&AtClient
Procedure RefreshControlItems()
	
	SelectedRows = Items.TemplatesList.SelectedRows;
	
	AllNotEditable			= True;
	AllEditable			= True;
	AllWithNotUsedAndNotEditablePT = True;
	IsWithNotUsedPM		= False;
	IsWithUsedPM			= False;
	AreSelectedElements		= False;
	
	For Each String In SelectedRows Do
		TreeItem = Items.TemplatesList.RowData(String);
		
		If TreeItem.ThisIsClassifier Then
			Continue;
		EndIf;
		
		AreSelectedElements = True;
		
		If TreeItem.BeingEdited Then
			AllNotEditable = False;
		Else
			AllEditable = False;
		EndIf;
		
		If TreeItem.IsUserTemplate Then
			If TreeItem.Use Then
				IsWithUsedPM = True;
				AllWithNotUsedAndNotEditablePT = False;
			Else
				IsWithNotUsedPM = True;
				If TreeItem.BeingEdited Then
					AllWithNotUsedAndNotEditablePT = False;
				EndIf;
			EndIf;
		Else
			AllWithNotUsedAndNotEditablePT = False;
		EndIf;
		
	EndDo;
	
	If AreSelectedElements Then
		// disabling policy - block command accessibility if at least one selected object does not match
		// all not editable
		OpenForViewing	= AllNotEditable;
		// all editable
		FinishEdit = AllEditable;
		CancelEdit = AllEditable;
		// everyone has a user template, that is not edited and is not used
		DeleteFromIB = AllWithNotUsedAndNotEditablePT;
		// enabling policy - make command accessible, if at least one selected object matches condition
		// at least one object have user template and it is not in use
		UseUserTemplate = IsWithNotUsedPM;
		// at least one object have user template and it is in use
		UseStandardTemplate = IsWithUsedPM;
	Else
		OpenForViewing					= False;
		FinishEdit				= False;
		CancelEdit				= False;
		DeleteFromIB							= False;
		UseUserTemplate	= False;
		UseStandardTemplate		= False;
	EndIf;
	
	Items.TemplatesListOpenForViewing.Enabled				= OpenForViewing;
	Items.TemplatesListFinishEdit.Enabled			= FinishEdit;
	Items.TemplatesListCancelEdit.Enabled			= CancelEdit;
	Items.TemplatesListDeleteFromIB.Enabled						= DeleteFromIB;
	
	Items.TemplatesListUseUserTemplate.Enabled	= UseUserTemplate;
	Items.TemplatesListUseStandardTemplate.Enabled		= UseStandardTemplate;
	
	Items.ContextMenuTemplatesListUseUserTemplate.Enabled = UseUserTemplate;
	Items.ContextMenuTemplatesListUseStandardTemplate.Enabled	   = UseStandardTemplate;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
//                 TEMPLATES MANAGEMENT AUXILIARY FUNCTIONS                 //
////////////////////////////////////////////////////////////////////////////////

&AtClientAtServerNoContext
Function GetTextByUsage(Val Use)
	
	If Use Then
		Return NStr("en = 'Custom template'");
	Else
		Return NStr("en = 'Standard template'");
	EndIf;
	
EndFunction

&AtServerNoContext
Function GetTemplatesBinaryData(PathsToTemplates)
	
	CorrBinaryData = New Map;
	
	For Each PathToTemplate In PathsToTemplates Do
		Data = PrintManagement.GetTemplate(PathToTemplate.Value + "." + PathToTemplate.Key);
		If TypeOf(Data) = Type("SpreadsheetDocument") Then
			TemporaryFileName = GetTempFileName();
			Data.Write(TemporaryFileName);
			Data = New BinaryData(TemporaryFileName);
			DeleteFiles(TemporaryFileName);
		EndIf;
		CorrBinaryData.Insert(
					PathToTemplate.Key,
					Data);
	EndDo;
	
	Return CorrBinaryData;
	
EndFunction

&AtClient
Function SavePrintFormTemplateToDrive(LayoutBinaryData, TemplateType)
#If Not WebClient Then
	
	TemporaryFileName = GetTempFileName(TemplateType);
	LayoutBinaryData.Write(TemporaryFileName);
	
	Return TemporaryFileName;
	
#EndIf
EndFunction

&AtClient
Function GetPrintFormTemplateFromDisk(Val PathToTemplateOnDisk, Val MODescription, Val DesignName)
#If Not WebClient Then
	SpreadsheetDocument = Undefined;
	
	File = New File(PathToTemplateOnDisk);
	
	If File.Exist() Then
		
		BinaryDataSpreadsheet = New BinaryData(PathToTemplateOnDisk);
		
		SpreadsheetDocument = GetSpreadsheetDocumentFromBinaryData(BinaryDataSpreadsheet);
		
	EndIf;
	
	If SpreadsheetDocument = Undefined Then
		SpreadsheetDocument = GetPrintFormTemplate(MODescription, DesignName);
	EndIf;
	
	Return SpreadsheetDocument;
#EndIf
EndFunction

&AtServerNoContext
Function GetSpreadsheetDocumentFromBinaryData(BinaryData)
	
	FileName = GetTempFileName("mxl");
	
	BinaryData.Write(FileName);
	
	SpreadsheetDocument = New SpreadsheetDocument;
	
	SpreadsheetDocument.Read(FileName);
	
	DeleteFiles(FileName);
	
	Return SpreadsheetDocument;
	
EndFunction

&AtServerNoContext
Procedure SetTemplateUse(InstalledTemplates, Use)
	
	For Each Template In InstalledTemplates Do
		Record = InformationRegisters.PrintedFormTemplates.CreateRecordManager();
		Record.Object				= Template.MOName;
		Record.DesignName	= Template.DesignName;
		Record.Read();
		If NOT IsBlankString(Record.Object) Then
			Record.Use		= Use;
			Record.Write();
		EndIf;
	EndDo;
	
EndProcedure

&AtServerNoContext
Function GetPrintFormTemplate(Val MODescription, Val DesignName)
	
	Return PrintManagement.GetTemplate(MODescription+"."+DesignName);
	
EndFunction

&AtServerNoContext
Procedure SaveTemplatesInfobase(Val TemplatesBeingSaved, Val PlacedFiles = Undefined)
	
	For Each TemplateBeingSaved In TemplatesBeingSaved Do
		
		Record = InformationRegisters.PrintedFormTemplates.CreateRecordManager();
		
		Record.Object				= TemplateBeingSaved.MOName;
		Record.DesignName			= TemplateBeingSaved.DesignName;
		Record.Use		= True;
		
		If PlacedFiles <> Undefined Then
			Value = GetBinaryDataOfReceivedFileByTemplateName(TemplateBeingSaved.DesignName, PlacedFiles);
			Record.Template = New ValueStorage(Value, New Deflation(9));
		Else
			Record.Template = New ValueStorage(TemplateBeingSaved.TemplateData, New Deflation(9));
		EndIf;
		
		Record.Write();
		
	EndDo;
	
EndProcedure

&AtServerNoContext
Function GetBinaryDataOfReceivedFileByTemplateName(DesignName, PlacedFiles)
	
	For Each TransferableFileDescription IN PlacedFiles Do
		FileName = TransferableFileDescription.Name;
		FileName = Left(FileName, StrLen(FileName) - 4);
		While Find(FileName, "\") <> 0 Do
			CharPosition = Find(FileName, "\");
			FileName = Right(FileName, StrLen(FileName) - CharPosition);
		EndDo;
		If Upper(FileName) = Upper(DesignName) Then
			Return GetFromTempStorage(TransferableFileDescription.Location);
		EndIf;
	EndDo;
	
	Return Undefined;
	
EndFunction

// Deletes user template from the infobase
//
&AtServerNoContext
Procedure DeleteTemplateFromInformationBase(TemplatesToBeDeleted)
	
	For Each TemplateToBeDeleted In TemplatesToBeDeleted Do
		RecordManager = InformationRegisters.PrintedFormTemplates.CreateRecordManager();
		RecordManager.Object = TemplateToBeDeleted.FullMOName;
		RecordManager.DesignName = TemplateToBeDeleted.DesignName;
		RecordManager.Delete();
	EndDo;
	
EndProcedure

&AtClient
Procedure OpenPrintedFormTemplates(Val Edit = False)
	
	If NOT SuggestWorkWithFilesExtensionInstallationNow() Then
		Return;
	EndIf;
	
	SelectedRows = Items.TemplatesList.SelectedRows;
	
#If WebClient Then
	PathsToTemplates = New Map;
	TemplateTypes = New Map;
	For Each String In SelectedRows Do
		
		TreeItem = Items.TemplatesList.RowData(String);
		
		If TreeItem.ThisIsClassifier Then
			Continue;
		EndIf;
		
		If TreeItem.BeingEdited Then
			Continue;
		EndIf;
		
		PathsToTemplates.Insert(TreeItem.DesignName, TreeItem.GetParent().FullMOName);
		TemplateTypes.Insert(TreeItem.DesignName, TreeItem.TemplateType);
	EndDo;
	SetOfBinaryData = GetTemplatesBinaryData(PathsToTemplates);
	
	GivenBinaryDataSet = New Map;
	
	For Each TemplateType In TemplateTypes Do
		GivenBinaryDataSet.Insert(TemplateType.Key+"."+TemplateType.Value, SetOfBinaryData[TemplateType.Key]);
	EndDo;
	
	Result = PrintManagementClient.GetFilesToFilesPrintDirectory(PathToFilePrintDirectory, GivenBinaryDataSet);
	If Result = Undefined Then
		Return;
	EndIf;
	PathToFilePrintDirectory = Result;
	
	WarningText = "";
	
	For Each String In SelectedRows Do
		TreeItem = Items.TemplatesList.RowData(String);
		If TreeItem.ThisIsClassifier Then
			Continue;
		EndIf;
		
		PathToTemplateFile = PathToFilePrintDirectory + TreeItem.DesignName + "." + TreeItem.TemplateType;
		
		If TreeItem.TemplateType = "MXL" And Edit Then
			If IsBlankString(WarningText) Then
				WarningText = NStr("en = 'Table documents template saved to disk.'");
			EndIf;
			
			WarningText = WarningText
					+ Chars.LF
					+ StringFunctionsClientServer.SubstitureParametersInString(
						NStr("en = 'Template %1 has been saved with name %2.'"),
						TreeItem.DesignName,
						PathToTemplateFile);
		Else
			OpenFile(PathToTemplateFile);
		EndIf;
		
		If Edit Then
			TreeItem.BeingEdited = True;
			TreeItem.PathToTemplateFile = PathToTemplateFile;
		EndIf;
	EndDo;
	
	If Not IsBlankString(WarningText) Then
		DoMessageBox(WarningText);
	EndIf;
#Else
	For Each String In SelectedRows Do
		TreeItem = Items.TemplatesList.RowData(String);
		
		If TreeItem.ThisIsClassifier Then
			Continue;
		EndIf;
		
		If TreeItem.BeingEdited Then
			If TreeItem.TemplateType = "MXL" Then
				SpreadsheetDocument = GetPrintFormTemplateFromDisk(TreeItem.PathToTemplateFile,
																	TreeItem.GetParent().FullMOName,
																	TreeItem.DesignName);
				SpreadsheetDocument.Show(TreeItem.Presentation, TreeItem.PathToTemplateFile);
			Else
				RunApp(TreeItem.PathToTemplateFile)
			EndIf;
			Continue;
		EndIf;
		
		If TreeItem.TemplateType = "MXL" Then
			SpreadsheetDocument = GetPrintFormTemplate(
									TreeItem.GetParent().FullMOName,
									TreeItem.DesignName);
			
			If Edit Then
				PathToTemplateFile = GetTempFileName(TreeItem.TemplateType);
				SpreadsheetDocument.Show(TreeItem.Presentation, PathToTemplateFile);
				TreeItem.PathToTemplateFile = PathToTemplateFile;
				TreeItem.BeingEdited = True;
			Else
				SpreadsheetDocument.TemplateLanguageCode = "en";
				SpreadsheetDocument.Show(TreeItem.Presentation);
			EndIf;
		Else
			LayoutBinaryData = GetPrintFormTemplate(
									TreeItem.GetParent().FullMOName,
									TreeItem.DesignName);
			
			PathToTemplateFile = SavePrintFormTemplateToDrive(LayoutBinaryData, TreeItem.TemplateType);
			
			RunApp(PathToTemplateFile);
			If Edit Then
				TreeItem.BeingEdited = True;
				TreeItem.PathToTemplateFile = PathToTemplateFile;
			EndIf;
		EndIf;
	EndDo;
#EndIf
	
	RefreshControlItems();
	
EndProcedure

&AtClient
Procedure SetTemplateUseByValue(Value)
	
	InstalledTemplates = New Array;
	
	SelectedRows = Items.TemplatesList.SelectedRows;
	
	For Each String In SelectedRows Do
		
		TreeItem = Items.TemplatesList.RowData(String);
		
		If TreeItem.ThisIsClassifier Then
			Continue;
		EndIf;
		
		If Value And NOT TreeItem.IsUserTemplate Then
			Continue;
		EndIf;
			
		InstalledTemplates.Add(New Structure("MOName, DesignName",
														TreeItem.GetParent().FullMOName,
														TreeItem.DesignName));
		TreeItem.Use = Value;
		TreeItem.UseString = GetTextByUsage(TreeItem.Use);
		TreeItem.Picture = GetPictureCode(TreeItem.TemplateType);
	EndDo;
	
	If InstalledTemplates.Count() > 0 Then
		SetTemplateUse(InstalledTemplates, Value);
	EndIf;
	
	RefreshControlItems();
	
EndProcedure

// Get picture number by template type and template use
//
&AtClientAtServerNoContext
Function GetPictureCode(TemplateTypeMOName)
	
	If		Upper(TemplateTypeMOName) = "DOC" Then
		Picture = 0;
	ElsIf	Upper(TemplateTypeMOName) = "ODT" Then
		Picture = 1;
	ElsIf	Upper(TemplateTypeMOName) = "MXL" Then
		Picture = 2;
	Else
		OwnerName = StringFunctionsClientServer.DecomposeStringIntoSubstringsArray(TemplateTypeMOName, ".")[0];
		If		Upper(OwnerName) = "DOCUMENT" Then
			Picture = 4;
		ElsIf	Upper(OwnerName) = "DATAPROCESSOR" Then
			Picture = 3;
		ElsIf	Upper(OwnerName) = "COMMONTEMPLATES" Then
			Picture = 5;
		Else
			Picture = 4;
		EndIf;
	EndIf;
	
	Return Picture;
	
EndFunction // GetPictureCode()

////////////////////////////////////////////////////////////////////////////////
//                 TEMPLATES MANAGEMENT AUXILIARY FUNCTIONS                 //
////////////////////////////////////////////////////////////////////////////////

#If WebClient Then
&AtClient
Procedure OpenFile(OpenedFileName)
	
	Try
		RunApp(OpenedFileName);
	Except
		DoMessageBox(StringFunctionsClientServer.SubstitureParametersInString(
						NStr("en = 'Description=""%1""'"),
						ErrorInfo().Description));
	EndTry;
	
EndProcedure // OpenFile()
#EndIf

////////////////////////////////////////////////////////////////////////////////
//                      HANDLERS OF FORM COMMAND EVENTS                      //
////////////////////////////////////////////////////////////////////////////////

&AtClient
Procedure OpenForViewing(Command)
	
	OpenPrintedFormTemplates(False);
	
EndProcedure

&AtClient
Procedure Edit(Command)
	
	OpenPrintedFormTemplates(True);
	
EndProcedure

&AtClient
Procedure FinishEdit(Command)
	
	TemplatesBeingSaved = New Array;
	
#If WebClient Then
	FilesBeingPlaced = New Array;
	PlacedFiles = New Array;
#EndIf
	
	SelectedRows = Items.TemplatesList.SelectedRows;
	
	For Each String In SelectedRows Do
		TreeItem = Items.TemplatesList.RowData(String);
		If TreeItem.ThisIsClassifier Then
			Continue;
		EndIf;
		
		File = New File(TreeItem.PathToTemplateFile);
		
		If File.Exist() Then
#If WebClient Then
			FilesBeingPlaced.Add(New TransferableFileDescription(File.FullName, ""));
			TemplatesBeingSaved.Add(New Structure("MOName, DesignName",
											TreeItem.GetParent().FullMOName,
											TreeItem.DesignName));
#Else
			Try
				TemplateData = New BinaryData(TreeItem.PathToTemplateFile)
			Except
				MessageAboutError = BriefErrorDescription(ErrorInfo());
				MessageAboutError = MessageAboutError + Chars.LF + 
						StringFunctionsClientServer.SubstitureParametersInString(
							NStr("en = 'Make sure that application of working with %1 file is closed'"),
							TreeItem.Presentation);
				CommonUseClientServer.MessageToUser(MessageAboutError);
				Continue;
			EndTry;
			
			TemplatesBeingSaved.Add(New Structure("MOName, DesignName, TemplateData",
											TreeItem.GetParent().FullMOName,
											TreeItem.DesignName,
											TemplateData));

			DeleteFiles(TreeItem.PathToTemplateFile);
			
			TreeItem.Use = True;
			TreeItem.UseString = GetTextByUsage(TreeItem.Use);
			TreeItem.IsUserTemplate = True;
			TreeItem.Picture = GetPictureCode(TreeItem.TemplateType);
#EndIf
		EndIf;
#If NOT WebClient Then
		TreeItem.BeingEdited = False;
		TreeItem.PathToTemplateFile = "";
#EndIf
	EndDo;
	
#If WebClient Then
	Try
		If NOT PutFiles(FilesBeingPlaced, PlacedFiles, , False) Then
			DoMessageBox(NStr("en = 'Error while placing files to the storage.'"));
			Return;
		EndIf;
	Except
		MessageAboutError = BriefErrorDescription(ErrorInfo());
		CommonUseClientServer.MessageToUser(
			StringFunctionsClientServer.SubstitureParametersInString(
				NStr("en = 'Error sending file to storage: %1. Make sure application is closed.'"), MessageAboutError));
		Return;
	EndTry;
#EndIf

#If WebClient Then
	SaveTemplatesInfobase(TemplatesBeingSaved, PlacedFiles);
	
	SelectedRows = Items.TemplatesList.SelectedRows;
	
	For Each String In SelectedRows Do
		TreeItem = Items.TemplatesList.RowData(String);
		If TreeItem.ThisIsClassifier Then
			Continue;
		EndIf;
		
		File = New File(TreeItem.PathToTemplateFile);
		
		If File.Exist() Then
			DeleteFiles(TreeItem.PathToTemplateFile);
		EndIf;
		
		TreeItem.Use = True;
		TreeItem.UseString = GetTextByUsage(TreeItem.Use);
		TreeItem.IsUserTemplate = True;
		TreeItem.Picture = GetPictureCode(TreeItem.TemplateType);
		TreeItem.BeingEdited = False;
		TreeItem.PathToTemplateFile = "";
	EndDo;
#Else
	SaveTemplatesInfobase(TemplatesBeingSaved);
#EndIf

    TemplatesQuantity = SelectedRows.Count();
	If TemplatesQuantity = 1 Then
		ShowUserNotification(NStr("en = 'Template changed'"),, 
			Items.TemplatesList.RowData(SelectedRows[0]).Presentation);
	ElsIf TemplatesQuantity > 1 Then
		ShowUserNotification(NStr("en = 'Templates changed'"),,
			NStr("en = 'Templates quantity:'") + TemplatesQuantity);
	EndIf;
	
	RefreshControlItems();
	
EndProcedure

&AtClient
Procedure CancelEdit(Command)
	
	SelectedRows = Items.TemplatesList.SelectedRows;
	
	For Each String In SelectedRows Do
		TreeItem = Items.TemplatesList.RowData(String);
		If TreeItem.ThisIsClassifier Then
			Continue;
		EndIf;
		DeleteFiles(TreeItem.PathToTemplateFile);
		TreeItem.BeingEdited = False;
		TreeItem.PathToTemplateFile = "";
	EndDo;
	
	RefreshControlItems();
	
EndProcedure

&AtClient
Procedure DeleteFromIB(Command)
	
	TemplatesToBeDeleted = New Array;
	
	SelectedRows = Items.TemplatesList.SelectedRows;
	
	For Each String In SelectedRows Do
		TreeItem = Items.TemplatesList.RowData(String);
		If TreeItem.ThisIsClassifier Then
			Continue;
		EndIf;
		
		TemplatesToBeDeleted.Add(New Structure("FullMOName, DesignName",
									TreeItem.GetParent().FullMOName,
									TreeItem.DesignName));
		TreeItem.IsUserTemplate = False;
	EndDo;
	
	If TemplatesToBeDeleted.Count() > 0 Then
		DeleteTemplateFromInformationBase(TemplatesToBeDeleted);
		RefreshControlItems();
	EndIf;
	
    TemplatesQuantity = SelectedRows.Count();
	If TemplatesQuantity = 1 Then
		ShowUserNotification(NStr("en = 'Deleted user template'"),,
			Items.TemplatesList.RowData(SelectedRows[0]).Presentation);
	ElsIf TemplatesQuantity > 1 Then
		ShowUserNotification(NStr("en = 'Delete user templates'"),,
			NStr("en = 'Templates quantity:'" + TemplatesQuantity));
	EndIf;

	
EndProcedure

&AtClient
Procedure UseUserTemplate(Command)
	
	SetTemplateUseByValue(True);
	
EndProcedure

&AtClient
Procedure UseStandardTemplate(Command)
	
	SetTemplateUseByValue(False);
	
EndProcedure

&AtServerNoContext
Procedure SaveSettingsOfTemplateOpeningMode(AskTemplateOpeningMode, TemplateOpeningModeView)
	
	CommonSettingsStorage.Save("SetupOfTemplatesOpening", "AskTemplateOpeningMode", AskTemplateOpeningMode);
	CommonSettingsStorage.Save("SetupOfTemplatesOpening", "TemplateOpeningModeView", TemplateOpeningModeView);
	
EndProcedure

&AtClient
Procedure SetActionOnPrintFormTemplateSelect(Command)
	
	Result = OpenFormModal("InformationRegister.PrintedFormTemplates.Form.ChoiceOfTemplateOpenMode");
	
	If TypeOf(Result) = Type("Structure") Then
		TemplateOpeningModeView = Result.OpeningModeView;
		AskTemplateOpeningMode = NOT Result.DoNotAskAnyMore;
	EndIf;
	
EndProcedure

&AtClient
Procedure WorkingDirectorySettingForPrinting(Command)
	OpenForm("InformationRegister.PrintedFormTemplates.Form.PrintFilesFolderSettings");
EndProcedure

&AtClient
Function SuggestWorkWithFilesExtensionInstallationNow()
	
	TextOfMessage = NStr("en = 'Extension to work in Web client has not been set up'");
	CommonUseClient.SuggestWorkWithFilesExtensionInstallationNow(TextOfMessage);
	
	If AttachFileSystemExtension() Then
		Return True;
	EndIf;
	
	DoMessageBox(NStr("en = 'To open and edit the templates it is necessary to set file extension for work in the Web-client.'"));
	
	Return False;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
//         EVENT HANDLERS OF FORM AND FORM ITEMS             //
////////////////////////////////////////////////////////////////////////////////

&AtServer
Procedure OnCreateAtServer(Cancellation, StandardProcessing)
	
	Var Filter;
	
	If Parameters.Property("Filter") Then
		Filter = Parameters.Filter.Metadata().FullName();
	EndIf;
	
	FillMetadataList(Filter);
	
	PathToFilePrintDirectory = PrintManagement.GetPrintFilesLocalDirectory();
	
	Value = CommonSettingsStorage.Load("SetupOfTemplatesOpening", "AskTemplateOpeningMode");
	
	If Value = Undefined Then
		AskTemplateOpeningMode = True;
	Else
		AskTemplateOpeningMode = Value;
	EndIf;
	
	Value = CommonSettingsStorage.Load("SetupOfTemplatesOpening", "TemplateOpeningModeView");
	
	If Value = Undefined Then
		TemplateOpeningModeView = False;
	Else
		TemplateOpeningModeView = Value;
	EndIf;
	
EndProcedure

&AtClient
Procedure TemplatesListOnActivateRow(Item)
	
	RefreshControlItems();
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancellation, StandardProcessing)
	
	AreEditable = False;
	
	For Each LayoutGroup In TemplatesList.GetItems() Do
		GroupItem = LayoutGroup.GetItems();
		For Each ItemMO In GroupItem Do
			If ItemMO.BeingEdited Then
				AreEditable = True;
				Break;
			EndIf;
		EndDo;
		If AreEditable Then
			Break;
		EndIf;
	EndDo;
	
	If AreEditable Then
		Result = DoQueryBox(NStr("en = 'Attention, the list contains templates marked as being edited. Proceed with form closure? '"), QuestionDialogMode.YesNo, , DialogReturnCode.No,);
		If Result = DialogReturnCode.No Then
			Cancellation = True;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure TemplatesListSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Items.TemplatesList.RowData(RowSelected).ThisIsClassifier Then
		Return;
	EndIf;
	
	If AskTemplateOpeningMode Then
		
		Result = OpenFormModal("InformationRegister.PrintedFormTemplates.Form.ChoiceOfTemplateOpenMode");
		
		If TypeOf(Result) = Type("Structure") Then
			TemplateOpeningModeView = Result.OpeningModeView;
			AskTemplateOpeningMode = NOT Result.DoNotAskAnyMore;
			If Result.DoNotAskAnyMore Then
				SaveSettingsOfTemplateOpeningMode(AskTemplateOpeningMode, TemplateOpeningModeView);
			EndIf;
		Else
			Return;
		EndIf;
		
	EndIf;
	
	OpenPrintedFormTemplates(NOT TemplateOpeningModeView);
	
EndProcedure
