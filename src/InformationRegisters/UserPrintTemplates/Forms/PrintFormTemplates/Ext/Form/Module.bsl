&AtServerNoContext
Procedure FillTreeWithMetadataCollection(TemplateListTree,
												MetadataCollection,
												val TemplateCollection,
												Filter = Undefined)
	
	If TemplateCollection Then
		AddTemplateCollection(MetadataCollection,
								TemplateListTree,
								"CommonTemplate",
								"Common templates",
								Filter);
	Else
		For Each ItemObjectMD In MetadataCollection Do
			AddTemplateCollection(ItemObjectMD.Templates,
									TemplateListTree,
									ItemObjectMD.FullName(),
									ItemObjectMD.Synonym,
									Filter);
		EndDo;
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure AddTemplateCollection(Templates, TemplateListTree, FullName, Presentation, Filter)
	
	Var TemplateType;
	
	If ValueIsFilled(Filter) AND Upper(FullName) <> Upper(Filter) Then
		Return;
	EndIf;
	
	FirstTemplatePF = True;
	
	For Each TemplateItem In Templates Do
		If IsPrintForm(TemplateItem.Name, TemplateType) Then
			If FirstTemplatePF Then
				NewRowMO = TemplateListTree.Rows.Add();
				NewRowMO.ThisClassifier	= True;
				NewRowMO.FullNameMO		= FullName;
				NewRowMO.Presentation		= Presentation;
				NewRowMO.Image			= GetImageCode(FullName);
				FirstTemplatePF = False;
			EndIf;
			NewRowTemplate = NewRowMO.Rows.Add();
			NewRowTemplate.TemplateName     = TemplateItem.Name;
			NewRowTemplate.Presentation = TemplateItem.Synonym;
			NewRowTemplate.TemplateType     = TemplateType;
			NewRowTemplate.Use = False;
			NewRowTemplate.UseString = GetUseText(NewRowTemplate.Use);
			NewRowTemplate.UserTemplateExists = False;
			NewRowTemplate.ThisClassifier = False;
			NewRowTemplate.Image = GetImageCode(TemplateType);
		EndIf;
	EndDo;
	
EndProcedure

// Checks each metadata object for subsystem print form
// (by the PF_<print form type> prefix) and then fill the selection list on a form
//
&AtServer
Procedure CreateMetadataList(Filter = Undefined)
	
	TemplateListTree = FormAttributeToValue("TemplateList");
	
	FillTreeWithMetadataCollection(TemplateListTree, Metadata.Documents, False, Filter);
	FillTreeWithMetadataCollection(TemplateListTree, Metadata.DataProcessors, False);
	FillTreeWithMetadataCollection(TemplateListTree, Metadata.CommonTemplates, True);
	
	If TemplateListTree.Rows.Count() > 0 Then
		Query = New Query;
		Query.Text = "SELECT Object, TemplateName, Use
						|FROM
						|	InformationRegister.UserPrintTemplates";
		
		Selection = Query.Execute().Choose();
		
		While Selection.Next() Do
			TreeRow = TemplateListTree.Rows.Find(Selection.Object, "FullNameMO");
			If TreeRow = Undefined Then
				Continue;
			EndIf;
			TemplateDescriptionRow = TreeRow.Rows.Find(Selection.TemplateName, "TemplateName");
			If TemplateDescriptionRow <> Undefined Then
				TemplateDescriptionRow.UserTemplateExists = True;
				TemplateDescriptionRow.Use = Selection.Use;
				TemplateDescriptionRow.UseString = GetUseText(TemplateDescriptionRow.Use);
				TemplateDescriptionRow.Image = GetImageCode(TemplateDescriptionRow.TemplateType)
			EndIf;
		EndDo;
	EndIf;
	
	ValueToFormAttribute(TemplateListTree, "TemplateList");
	
EndProcedure

// Checks by the passed template name (from metadata) is a print form
//
&AtServerNoContext
Function IsPrintForm(TemplateName, TemplateType = "")
	
	Position = Find(TemplateName, "PF_DOC");
	Position = ?(Position = 0, Find(TemplateName, "PF_ODT"), Position);
	Position = ?(Position = 0, Find(TemplateName, "PF_MXL"), Position);
	
	If Position = 0 Then
		Return False;
	Else
		TemplateType = Mid(TemplateName, Position + 3, 3);
		Return True;
	EndIf;
	
EndFunction

// Used for setting availability of form buttons, depending on selected data.
//
&AtClient
Procedure RefreshUI()
	
	SelectedRows = Items.TemplateList.SelectedRows;
	
	AllNonEdited			= True;
	AddEdited			= True;
	AllWithNonUsedAndNotEditedPM = True;
	ExistsWithNonUsedPM		= False;
	ExistsWithUsedPM			= False;
	SelectedElementsExist		= False;
	
	For Each Row In SelectedRows Do
		TreeElement = Items.TemplateList.RowData(Row);
		
		If TreeElement.ThisClassifier Then
			Continue;
		EndIf;
		
		SelectedElementsExist = True;
		
		If TreeElement.Editing Then
			AllNonEdited = False;
		Else
			AddEdited = False;
		EndIf;
		
		If TreeElement.UserTemplateExists Then
			If TreeElement.Use Then
				ExistsWithUsedPM = True;
				AllWithNonUsedAndNotEditedPM = False;
			Else
				ExistsWithNonUsedPM = True;
				If TreeElement.Editing Then
					AllWithNonUsedAndNotEditedPM = False;
				EndIf;
			EndIf;
		Else
			AllWithNonUsedAndNotEditedPM = False;
		EndIf;
		
	EndDo;
	
	If SelectedElementsExist Then
		// prohibiting policy - closing availability of a command if at least one selected object doesn't match
		// all non-edited
		OpenForViewing	= AllNonEdited;
		// all edited
		FinishEditing = AddEdited;
		CancelEditing = AddEdited;
		// everybode has a user template, which is not edited and not used
		DeleteFromIB = AllWithNonUsedAndNotEditedPM;
		// allowing policy - opening availability of a command if at least one selected object matches
		// at least one that has a user template and is not used
		UseUserTemplate = ExistsWithNonUsedPM;
		// at least one that has a user template and is used
		UseSuppliedTemplate = ExistsWithUsedPM;
	Else
		OpenForViewing					= False;
		FinishEditing				= False;
		CancelEditing				= False;
		DeleteFromIB							= False;
		UseUserTemplate	= False;
		UseSuppliedTemplate		= False;
	EndIf;
	
	Items.TemplateListOpenForViewing.Enabled				= OpenForViewing;
	Items.TemplateListFinishEditing.Enabled			= FinishEditing;
	Items.TemplateListCancelEditing.Enabled			= CancelEditing;
	Items.TemplateListDeleteFromIB.Enabled						= DeleteFromIB;
	
	Items.TemplateListUseUserTemplate.Enabled	= UseUserTemplate;
	Items.TemplateListUseSuppliedTemplate.Enabled		= UseSuppliedTemplate;
	
	Items.ContextMenuTemplateListUseUserTemplate.Enabled = UseUserTemplate;
	Items.ContextMenuTemplateListUseSuppliedTemplate.Enabled	   = UseSuppliedTemplate;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
//                 AUXILARY TEMPLATE MANAGEMENT FUNCTIONS                     //
////////////////////////////////////////////////////////////////////////////////

&AtClientAtServerNoContext
Function GetUseText(val Use)
	
	If Use Then
		Return NStr("en='User'");
	Else
		Return NStr("en = 'Supplied'");
	EndIf;
	
EndFunction

&AtServerNoContext
Function GetTemplateBinaryData(TemplatePaths)
	
	MapBinaryData = New Map;
	
	For Each TemplatePath In TemplatePaths Do
		Data = PrintManagement.GetTemplate(TemplatePath.Value + "." + TemplatePath.Key);
		If TypeOf(Data) = Type("SpreadsheetDocument") Then
			TempFileName = GetTempFileName();
			Data.Write(TempFileName);
			Data = New BinaryData(TempFileName);
			DeleteFiles(TempFileName);
		EndIf;
		MapBinaryData.Insert(
					TemplatePath.Key,
					Data);
	EndDo;
	
	Return MapBinaryData;
	
EndFunction

&AtClient
Function SavePrintFormTemplateOnADrive(TemplateBinaryData, TemplateType)
#If Not WebClient Then
	
	TempFileName = GetTempFileName(TemplateType);
	TemplateBinaryData.Write(TempFileName);
	
	Return TempFileName;
	
#EndIf
EndFunction

&AtClient
Function GetPrintFormTemplateFromADrive(val TemplatePathOnADrive, val NameMO, val TemplateName)
#If Not WebClient Then
	SpreadsheetDocument = Undefined;
	
	File = New File(TemplatePathOnADrive);
	
	If File.Exist() Then
		
		SpreadsheetBinaryData = New BinaryData(TemplatePathOnADrive);
		
		SpreadsheetDocument = GetSpreadsheetFromBinaryData(SpreadsheetBinaryData);
		
	EndIf;
	
	If SpreadsheetDocument = Undefined Then
		SpreadsheetDocument = GetPrintFormTemplate(NameMO, TemplateName);
	EndIf;
	
	Return SpreadsheetDocument;
#EndIf
EndFunction

&AtServerNoContext
Function GetSpreadsheetFromBinaryData(BinaryData)
	
	FileName = GetTempFileName("mxl");
	
	BinaryData.Write(FileName);
	
	SpreadsheetDocument = New SpreadsheetDocument;
	
	SpreadsheetDocument.Read(FileName);
	
	DeleteFiles(FileName);
	
	Return SpreadsheetDocument;
	
EndFunction

&AtServerNoContext
Procedure SetTemplateUse(SetTemplates, Use)
	
	For Each Template In SetTemplates Do
		Record = InformationRegisters.UserPrintTemplates.CreateRecordManager();
		Record.Object				= Template.NameMO;
		Record.TemplateName	= Template.TemplateName;
		Record.Read();
		If NOT IsBlankString(Record.Object) Then
			Record.Use		= Use;
			Record.Write();
		EndIf;
	EndDo;
	
EndProcedure

&AtServerNoContext
Function GetPrintFormTemplate(val NameMO, val TemplateName)
	
	Return PrintManagement.GetTemplate(NameMO + "." + TemplateName);
	
EndFunction

&AtServerNoContext
Procedure SaveTemplatesInInfobase(val SavedTemplates, val PlacedFiles = Undefined)
	
	For Each SavedTemplate In SavedTemplates Do
		
		Record = InformationRegisters.UserPrintTemplates.CreateRecordManager();
		
		Record.Object				= SavedTemplate.NameMO;
		Record.TemplateName			= SavedTemplate.TemplateName;
		Record.Use		= True;
		
		If PlacedFiles <> Undefined Then
			Value = GetFileBinaryDataByTemplateName(SavedTemplate.TemplateName, PlacedFiles);
			Record.Template = New ValueStorage(Value, New Deflation(9));
		Else
			Record.Template = New ValueStorage(SavedTemplate.TemplateData, New Deflation(9));
		EndIf;
		
		Record.Write();
		
	EndDo;
	
EndProcedure

&AtServerNoContext
Function GetFileBinaryDataByTemplateName(TemplateName, PlacedFiles)
	
	For Each TransferredFileDescription In PlacedFiles Do
		FileName = TransferredFileDescription.Name;
		FileName = Left(FileName, StrLen(FileName) - 4);
		While Find(FileName, "\") <> 0 Do
			Position = Find(FileName, "\");
			FileName = Right(FileName, StrLen(FileName) - Position);
		EndDo;
		If Upper(FileName) = Upper(TemplateName) Then
			Return GetFromTempStorage(TransferredFileDescription.Location);
		EndIf;
	EndDo;
	
	Return Undefined;
	
EndFunction

// Deletes a user template from the infobase
//
&AtServerNoContext
Procedure DeleteTemplateFromInfobase(DeletedTemplates)
	
	For Each DeletedTemplate In DeletedTemplates Do
		RecordManager = InformationRegisters.UserPrintTemplates.CreateRecordManager();
		RecordManager.Object = DeletedTemplate.FullNameMO;
		RecordManager.TemplateName = DeletedTemplate.TemplateName;
		RecordManager.Delete();
	EndDo;
	
EndProcedure

&AtClient
Procedure OpenPrintFormTemplates(val Edit = False)
	
	If NOT GeneralFunctionsClientSL.FileExtensionModuleEnabled() Then
		Return;
	EndIf;
	
	SelectedRows = Items.TemplateList.SelectedRows;
	
#If WebClient Then
	TemplatePaths = New Map;
	TemplateTypes = New Map;
	For Each Row In SelectedRows Do
		
		TreeElement = Items.TemplateList.RowData(Row);
		
		If TreeElement.ThisClassifier Then
			Continue;
		EndIf;
		
		If TreeElement.Editing Then
			Continue;
		EndIf;
		
		TemplatePaths.Insert(TreeElement.TemplateName, TreeElement.GetParent().FullNameMO);
		TemplateTypes.Insert(TreeElement.TemplateName, TreeElement.TemplateType);
	EndDo;
	BinaryDataSet = GetTemplateBinaryData(TemplatePaths);
	
	ThisBinaryDataSet = New Map;
	
	For Each TemplateType In TemplateTypes Do
		ThisBinaryDataSet.Insert(TemplateType.Key + "." + TemplateType.Value, BinaryDataSet[TemplateType.Key]);
	EndDo;
	
	Result = PrintManagementClient.GetFilesIntoPrintCatalog(PrintFileFolderPath, ThisBinaryDataSet);
	If Result = Undefined Then
		Return;
	EndIf;
	PrintFileFolderPath = Result;
	
	WarningText = "";
	
	For Each Row In SelectedRows Do
		TreeElement = Items.TemplateList.RowData(Row);
		If TreeElement.ThisClassifier Then
			Continue;
		EndIf;
		
		TemplateFilePath = PrintFileFolderPath + TreeElement.TemplateName + "." + TreeElement.TemplateType;
		
		If TreeElement.TemplateType = "MXL" И Edit Then
			If IsBlankString(WarningText) Then
				WarningText = NStr("en = 'Spreadsheet template files are saved on the disk.'");
			EndIf;
			
			WarningText = WarningText
					+ Chars.LF
					+ StringFunctionsClientServer.SubstituteParametersIntoString(
						NStr("en = 'Template ""%1"" is saved on the disk with the following name
									|""%2"".'"),
						TreeElement.TemplateName,
						TemplateFilePath);
		Else
			OpenFile(TemplateFilePath);
		EndIf;
		
		If Edit Then
			TreeElement.Editing = True;
			TreeElement.TemplateFilePath = TemplateFilePath;
		EndIf;
	EndDo;
	
	If Not IsBlankString(WarningText) Then
		DoMessageBox(WarningText);
	EndIf;
#Else
	For Each Row In SelectedRows Do
		TreeElement = Items.TemplateList.RowData(Row);
		
		If TreeElement.ThisClassifier Then
			Continue;
		EndIf;
		
		If TreeElement.Editing Then
			If TreeElement.TemplateType = "MXL" Then
				SpreadsheetDocument = GetPrintFormTemplateFromADrive(TreeElement.TemplateFilePath,
																	TreeElement.GetParent().FullNameMO,
																	TreeElement.TemplateName);
				SpreadsheetDocument.Show(TreeElement.Presentation, TreeElement.TemplateFilePath);
			Else
				RunApp(TreeElement.TemplateFilePath)
			EndIf;
			Continue;
		EndIf;
		
		If TreeElement.TemplateType = "MXL" Then
			SpreadsheetDocument = GetPrintFormTemplate(
									TreeElement.GetParent().FullNameMO,
									TreeElement.TemplateName);
			
			If Edit Then
				TemplateFilePath = GetTempFileName(TreeElement.TemplateType);
				SpreadsheetDocument.Show(TreeElement.Presentation, TemplateFilePath);
				TreeElement.TemplateFilePath = TemplateFilePath;
				TreeElement.Editing = True;
			Else
				SpreadsheetDocument.Show(TreeElement.Presentation);
			EndIf;
		Else
			TemplateBinaryData = GetPrintFormTemplate(
									TreeElement.GetParent().FullNameMO,
									TreeElement.TemplateName);
			
			TemplateFilePath = SavePrintFormTemplateOnADrive(TemplateBinaryData, TreeElement.TemplateType);
			
			RunApp(TemplateFilePath);
			If Edit Then
				TreeElement.Editing = True;
				TreeElement.TemplateFilePath = TemplateFilePath;
			EndIf;
		EndIf;
	EndDo;
#EndIf
	
	RefreshUI();
	
EndProcedure

&AtClient
Procedure SetTemplateUseByValue(Value)
	
	SetTemplates = New Array;
	
	SelectedRows = Items.TemplateList.SelectedRows;
	
	For Each Row In SelectedRows Do
		
		TreeElement = Items.TemplateList.RowData(Row);
		
		If TreeElement.ThisClassifier Then
			Continue;
		EndIf;
		
		If Value AND NOT TreeElement.UserTemplateExists Then
			Continue;
		EndIf;
			
		SetTemplates.Add(New Structure("NameMO, TemplateName",
														TreeElement.GetParent().FullNameMO,
														TreeElement.TemplateName));
		TreeElement.Use = Value;
		TreeElement.UseString = GetUseText(TreeElement.Use);
		TreeElement.Image = GetImageCode(TreeElement.TemplateType);
	EndDo;
	
	If SetTemplates.Count() > 0 Then
		SetTemplateUse(SetTemplates, Value);
	EndIf;
	
	RefreshUI();
	
EndProcedure

// Get an image name by the template type and its use
//
&AtClientAtServerNoContext
Function GetImageCode(TemplateTypeNameMO)
	
	If		Upper(TemplateTypeNameMO) = "DOC" Then
		Image = 0;
	ElsIf	Upper(TemplateTypeNameMO) = "ODT" Then
		Image = 1;
	ElsIf	Upper(TemplateTypeNameMO) = "MXL" Then
		Image = 2;
	Else
		OwnerName = StringFunctionsClientServer.SplitStringIntoArrayOfSubstrings(TemplateTypeNameMO, ".")[0];
		If		Upper(OwnerName) = "DOCUMENT" Then
			Image = 4;
		ElsIf	Upper(OwnerName) = "DATAPROCESSOR" Then
			Image = 3;
		ElsIf	Upper(OwnerName) = "COMMONTEMPLATES" Then
			Image = 5;
		Else
			Image = 4;
		EndIf;
	EndIf;
	
	Return Image;
	
EndFunction

#If WebClient Then
&AtClient
Procedure OpenFile(OpenedFileName)
	
	Try
		RunApp(OpenedFileName);
	Except
		DoMessageBox(StringFunctionsClientServer.SubstituteParametersIntoString(
						NStr("en = 'Description=""%1""'"),
						ErrorInfo().Description));
	EndTry;
	
EndProcedure
#EndIf

////////////////////////////////////////////////////////////////////////////////
//                      FORM COMMAND HANDLERS                                 //
////////////////////////////////////////////////////////////////////////////////




&AtServerNoContext
Procedure SaveTemplateOpenModeSetting(AskTemplateOpenMode, TemplateOpenModeView)
	
	CommonSettingsStorage.Save("TemplateOpenSetting", "AskTemplateOpenMode", AskTemplateOpenMode);
	CommonSettingsStorage.Save("TemplateOpenSetting", "TemplateOpenModeView", TemplateOpenModeView);
	
EndProcedure


////////////////////////////////////////////////////////////////////////////////
//         FORM EVENT AND ITEM HANDLERS                                       //
////////////////////////////////////////////////////////////////////////////////




&AtClient
Procedure OpenForViewing(Command)
	
	OpenPrintFormTemplates(False);

EndProcedure

&AtClient
Procedure FinishEditing(Command)
	
	SavedTemplates = New Array;
	
#If WebClient Then
	ToBePlacedFiles = New Array;
	PlacedFiles = New Array;
#EndIf
	
	SelectedRows = Items.TemplateList.SelectedRows;
	
	For Each Row In SelectedRows Do
		TreeElement = Items.TemplateList.RowData(Row);
		If TreeElement.ThisClassifier Then
			Continue;
		EndIf;
		
		File = New File(TreeElement.TemplateFilePath);
		
		If File.Exist() Then
#If WebClient Then
			ToBePlacedFiles.Add(New TransferableFileDescription(File.FullName, ""));
			SavedTemplates.Add(New Structure("NameMO, TemplateName",
											TreeElement.GetParent().FullNameMO,
											TreeElement.TemplateName));
#Else
			Try
				TemplateData = New BinaryData(TreeElement.TemplateFilePath)
			Except
				ErrorMessage = BriefErrorDescription(ErrorInfo());
				ErrorMessage = ErrorMessage + Символы.ПС + 
						StringFunctionsClientServer.SubstituteParametersIntoString(
							NStr("en = 'Close the application working with file %1'"),
							TreeElement.Presentation);
				GeneralFunctionsClientServerSL.NotifyUser(ErrorMessage);
				Continue;
			EndTry;
			
			SavedTemplates.Add(New Structure("NameMO, TemplateName, TemplateData",
											TreeElement.GetParent().FullNameMO,
											TreeElement.TemplateName,
											TemplateData));

			DeleteFiles(TreeElement.TemplateFilePath);
			
			TreeElement.Use = True;
			TreeElement.UseString = GetUseText(TreeElement.Use);
			TreeElement.UserTemplateExists = True;
			TreeElement.Image = GetImageCode(TreeElement.TemplateType);
#EndIf
		EndIf;
#If NOT WebClient Then
		TreeElement.Editing = False;
		TreeElement.TemplateFilePath = "";
#EndIf
	EndDo;
	
#If WebClient Then
	Try
		If NOT PutFiles(ToBePlacedFiles, PlacedFiles, , False) Then
			DoMessageBox(NStr("en = 'Error placing files into storage.'"));
			Return;
		EndIf;
	Except
		ErrorMessage = BriefErrorDescription(ErrorInfo());
		GeneralFunctionsClientServerSL.NotifyUser(
			StringFunctionsClientServer.SubstituteParametersIntoString(
				NStr("en = 'Error placing files into storage: %1. Close the application working with file.'"), ErrorMessage));
		Return;
	EndTry;
#EndIf

#If WebClient Then
	SaveTemplatesInInfobase(SavedTemplates, PlacedFiles);
	
	SelectedRows = Items.TemplateList.SelectedRows;
	
	For Each Row In SelectedRows Do
		TreeElement = Items.TemplateList.RowData(Row);
		If TreeElement.ThisClassifier Then
			Continue;
		EndIf;
		
		File = New File(TreeElement.TemplateFilePath);
		
		If File.Exist() Then
			DeleteFiles(TreeElement.TemplateFilePath);
		EndIf;
		
		TreeElement.Use = True;
		TreeElement.UseString = GetUseText(TreeElement.Use);
		TreeElement.UserTemplateExists = True;
		TreeElement.Image = GetImageCode(TreeElement.TemplateType);
		TreeElement.Editing = False;
		TreeElement.TemplateFilePath = "";
	EndDo;
#Else
	SaveTemplatesInInfobase(SavedTemplates);
#EndIf

    TemplateQty = SelectedRows.Count();
	If TemplateQty = 1 Then
		ShowUserNotification(NStr("en='Template changed'"),, 
			Items.TemplateList.RowData(SelectedRows[0]).Presentation);
	ElsIf TemplateQty > 1 Then
		ShowUserNotification(NStr("en='Templates changed'"),,
			NStr("en = 'Number of templates: '") + TemplateQty);
	EndIf;
	
	RefreshUI();

EndProcedure

&AtClient
Procedure ChooseTemplateSelectAction(Command)
	
	Result = OpenFormModal("InformationRegister.UserPrintTemplates.Form.TemplateOpenModeSelection");
	
	If TypeOf(Result) = Type("Structure") Then
		TemplateOpenModeView = Result.OpenModeView;
		AskTemplateOpenMode = NOT Result.DontAskAgain;
	EndIf;

EndProcedure

&AtClient
Procedure UseUserTemplate(Command)
	
	SetTemplateUseByValue(True);

EndProcedure

&AtClient
Procedure UseSuppliedTemplate(Command)
	
	SetTemplateUseByValue(False);

EndProcedure

&AtClient
Procedure CancelEditing(Command)
	
	SelectedRows = Items.TemplateList.SelectedRows;
	
	For Each Row In SelectedRows Do
		TreeElement = Items.TemplateList.RowData(Row);
		If TreeElement.ThisClassifier Then
			Continue;
		EndIf;
		DeleteFiles(TreeElement.TemplateFilePath);
		TreeElement.Editing = False;
		TreeElement.TemplateFilePath = "";
	EndDo;
	
	RefreshUI();

EndProcedure

&AtClient
Procedure Edit(Command)
	
	OpenPrintFormTemplates(True);

EndProcedure

&AtClient
Procedure DeleteFromIB(Command)
	
	DeletedTemplates = New Array;
	
	SelectedRows = Items.TemplateList.SelectedRows;
	
	For Each Row In SelectedRows Do
		TreeElement = Items.TemplateList.RowData(Row);
		If TreeElement.ThisClassifier Then
			Continue;
		EndIf;
		
		DeletedTemplates.Add(New Structure("FullNameMO, TemplateName",
									TreeElement.GetParent().FullNameMO,
									TreeElement.TemplateName));
		TreeElement.UserTemplateExists = False;
	EndDo;
	
	If DeletedTemplates.Count() > 0 Then
		DeleteTemplateFromInfobase(DeletedTemplates);
		RefreshUI();
	EndIf;
	
    TemplateQty = SelectedRows.Count();
	If TemplateQty = 1 Then
		ShowUserNotification(NStr("en = 'User template deleted'"),,
			Items.TemplateList.RowData(SelectedRows[0]).Presentation);
	ElsIf TemplateQty > 1 Then
		ShowUserNotification(NStr("en = 'User templates deleted'"),,
			NStr("en = 'Number of templates: '" + TemplateQty));
	EndIf;

EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Var Filter;
	
	If Parameters.Property("Filter") Then
		Filter = Parameters.Filter.Metadata().FullName();
	EndIf;
	
	CreateMetadataList(Filter);
	
	PrintFileFolderPath = PrintManagement.GetLocalPrintFolder();
	
	Value = CommonSettingsStorage.Load("TemplateOpenSetting", "AskTemplateOpenMode");
	
	If Value = Undefined Then
		AskTemplateOpenMode = True;
	Else
		AskTemplateOpenMode = Value;
	EndIf;
	
	Value = CommonSettingsStorage.Load("TemplateOpenSetting", "TemplateOpenModeView");
	
	If Value = Undefined Then
		TemplateOpenModeView = False;
	Else
		TemplateOpenModeView = Value;
	EndIf;

EndProcedure

&AtClient
Procedure BeforeClose(Cancel, StandardProcessing)
	
	EditedExist = False;
	
	For Each TemplateGroup In TemplateList.GetItems() Do
		GroupItems = TemplateGroup.GetItems();
		For Each ItemMO In GroupItems Do
			If ItemMO.Editing Then
				EditedExist = True;
				Break;
			EndIf;
		EndDo;
		If EditedExist Then
			Break;
		EndIf;
	EndDo;
	
	If EditedExist Then
		Result = DoQueryBox(NStr("en = 'There are templates in the list that are being edited. Continue closing the form?'"), QuestionDialogMode.YesNo, , DialogReturnCode.No);
		If Result = DialogReturnCode.No Then
			Cancel = True;
		EndIf;
	EndIf;

EndProcedure

&AtClient
Procedure TemplateListSelection(Item, SelectedRow, Field, StandardProcessing)
	
	If Items.TemplateList.RowData(SelectedRow).ThisClassifier Then
		Return;
	EndIf;
	
	If AskTemplateOpenMode Then
		
		Result = OpenFormModal("InformationRegister.UserPrintTemplates.Form.TemplateOpenModeSelection");
		
		If TypeOf(Result) = Type("Structure") Then
			TemplateOpenModeView = Result.OpenModeView;
			AskTemplateOpenMode = NOT Result.DontAskAgain;
			If Result.DontAskAgain Then
				SaveTemplateOpenModeSetting(AskTemplateOpenMode, TemplateOpenModeView);
			EndIf;
		Else
			Return;
		EndIf;
		
	EndIf;
	
	OpenPrintFormTemplates(NOT TemplateOpenModeView);

EndProcedure

&AtClient
Procedure TemplateListOnActivateRow(Item)
	
	RefreshUI();

EndProcedure
