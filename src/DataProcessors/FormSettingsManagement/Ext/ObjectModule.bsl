
Procedure GetFormListFromFormsMetadataList(Prefix, PresentationPrefix, FormsMetadata, Picture, List)
	
	For Each Form In FormsMetadata Do
		
		List.Add(Prefix + ".Form." + Form.Name, PresentationPrefix + "." + Form.Synonym, False, Picture);
		
	EndDo;
	
EndProcedure

Procedure AddStandardForm(Prefix, PresentationPrefix, MetadataObject, FormName, FormPresentation, Picture, List)
	
	If MetadataObject["Default" + FormName] = Undefined Then
		
		List.Add(Prefix + "." + FormName, PresentationPrefix + "." + FormPresentation, False, Picture);
		
	EndIf;
	
EndProcedure

Procedure GetFormListOfMetadataObject(ListOfMetadataObjects, NameOfMetadataObject, PresentationOfMetadataObject, StandardFormNames, Picture, List)
	
	For Each Object In ListOfMetadataObjects Do
		
		Prefix = NameOfMetadataObject + "." + Object.Name;
		PresentationPrefix = PresentationOfMetadataObject + "." + Object.Synonym;
		
		GetFormListFromFormsMetadataList(Prefix, PresentationPrefix, Object.Forms, Picture, List);
		
		For Each StandardFormName In StandardFormNames Do
			
			AddStandardForm(Prefix, PresentationPrefix, Object, StandardFormName.Value, StandardFormName.Presentation, Picture, List);
			
		EndDo;
		
	EndDo;
	
EndProcedure

// Get configuration form list, and fill following fields:
// Value - form name, which identifies the form itself.
// Presentation - form synonym
// Picture - picture corresponding to object related to the form
// Parameters
// List - ValueList - value list, where form descriptions will be added
//
Procedure GetFormList(List) Export
	
	For Each Form In Metadata.CommonForms Do
		
		List.Add("CommonForm." + Form.Name, "Common form." + Form.Synonym, False, PictureLib.Form);
		
	EndDo;

	StandardFormNames = New ValueList;
	StandardFormNames.Add("ObjectForm", "Object form");
	StandardFormNames.Add("FolderForm", "Form folders");
	StandardFormNames.Add("ListForm", "List form");
	StandardFormNames.Add("ChoiceForm", "Choice form");
	StandardFormNames.Add("FolderChoiceForm", "Folder choice form");
	GetFormListOfMetadataObject(Metadata.Catalogs, "Catalog", "Catalog", StandardFormNames, PictureLib.Catalog, List);
	
	StandardFormNames = New ValueList;
	StandardFormNames.Add("Form", "Form");
	GetFormListOfMetadataObject(Metadata.FilterCriteria, "FilterCriterion", "Filter criterion", StandardFormNames, PictureLib.FilterCriterion, List);
	
	StandardFormNames = New ValueList;
	StandardFormNames.Add("SaveForm", "Saving form");
	StandardFormNames.Add("LoadForm", "Choice form");
	GetFormListOfMetadataObject(Metadata.SettingsStorages, "SettingsStorage", "Settings storage", StandardFormNames, PictureLib.SettingsStorage, List);
	
	StandardFormNames = New ValueList;
	StandardFormNames.Add("ObjectForm", "Object form");
	StandardFormNames.Add("ListForm", "List form");
	StandardFormNames.Add("ChoiceForm", "Choice form");
	GetFormListOfMetadataObject(Metadata.Documents, "Document", "Document", StandardFormNames, PictureLib.Document, List);
	
	StandardFormNames = New ValueList;
	StandardFormNames.Add("Form", "Form");
	GetFormListOfMetadataObject(Metadata.DocumentJournals, "DocumentJournal", "Documents journal", StandardFormNames, PictureLib.DocumentJournal, List);
	
	StandardFormNames = New ValueList;
	StandardFormNames.Add("ListForm", "List form");
	StandardFormNames.Add("ChoiceForm", "Choice form");
	GetFormListOfMetadataObject(Metadata.Enums, "Enum", "Enum", StandardFormNames, PictureLib.Enum, List);

	StandardFormNames = New ValueList;
	StandardFormNames.Add("Form", "Form");
	StandardFormNames.Add("SettingsForm", "Settings form");
	StandardFormNames.Add("VariantForm", "Variant form");
	GetFormListOfMetadataObject(Metadata.Reports, "Report", "Report", StandardFormNames, PictureLib.Report, List);
	
	StandardFormNames = New ValueList;
	StandardFormNames.Add("Form", "Form");
	GetFormListOfMetadataObject(Metadata.DataProcessors, "DataProcessor", "DataProcessor", StandardFormNames, PictureLib.DataProcessor, List);
	
	StandardFormNames = New ValueList;
	StandardFormNames.Add("RecordForm", "Record form");
	StandardFormNames.Add("ListForm", "List form");
	GetFormListOfMetadataObject(Metadata.InformationRegisters, "InformationRegister", "Information register", StandardFormNames, PictureLib.InformationRegister, List);
	
	StandardFormNames = New ValueList;
	StandardFormNames.Add("ListForm", "List form");
	GetFormListOfMetadataObject(Metadata.AccumulationRegisters, "AccumulationRegister", "Accumulation register", StandardFormNames, PictureLib.AccumulationRegister, List);
	
	StandardFormNames = New ValueList;
	StandardFormNames.Add("ObjectForm", "Object form");
	StandardFormNames.Add("FolderForm", "Form folders");
	StandardFormNames.Add("ListForm", "List form");
	StandardFormNames.Add("ChoiceForm", "Choice form");
	StandardFormNames.Add("FolderChoiceForm", "Folder choice form");
	GetFormListOfMetadataObject(Metadata.ChartsOfCharacteristicTypes, "ChartOfCharacteristicTypes", "Chart of characteristics types", StandardFormNames, PictureLib.ChartOfCharacteristicTypes, List);
	
	StandardFormNames = New ValueList;
	StandardFormNames.Add("ObjectForm", "Object form");
	StandardFormNames.Add("ListForm", "List form");
	StandardFormNames.Add("ChoiceForm", "Choice form");
	GetFormListOfMetadataObject(Metadata.ChartsOfAccounts, "ChartOfAccounts", "Chart of accounts", StandardFormNames, PictureLib.ChartOfAccounts, List);
	
	StandardFormNames = New ValueList;
	StandardFormNames.Add("ListForm", "List form");
	GetFormListOfMetadataObject(Metadata.AccountingRegisters, "AccountingRegister", "Accounting register", StandardFormNames, PictureLib.AccountingRegister, List);
	
	StandardFormNames = New ValueList;
	StandardFormNames.Add("ObjectForm", "Object form");
	StandardFormNames.Add("ListForm", "List form");
	StandardFormNames.Add("ChoiceForm", "Choice form");
	GetFormListOfMetadataObject(Metadata.ChartsOfCalculationTypes, "ChartOfCalculationTypes", "Chart of calculations types", StandardFormNames, PictureLib.ChartOfCalculationTypes, List);
	
	StandardFormNames = New ValueList;
	StandardFormNames.Add("ListForm", "List form");
	GetFormListOfMetadataObject(Metadata.CalculationRegisters, "CalculationRegister", "Calculation register", StandardFormNames, PictureLib.CalculationRegister, List);
	
	StandardFormNames = New ValueList;
	StandardFormNames.Add("ObjectForm", "Object form");
	StandardFormNames.Add("ListForm", "List form");
	StandardFormNames.Add("ChoiceForm", "Choice form");
	GetFormListOfMetadataObject(Metadata.BusinessProcesses, "BusinessProcess", "Business process", StandardFormNames, PictureLib.BusinessProcess, List);
	
	StandardFormNames = New ValueList;
	StandardFormNames.Add("ObjectForm", "Object form");
	StandardFormNames.Add("ListForm", "List form");
	StandardFormNames.Add("ChoiceForm", "Choice form");
	GetFormListOfMetadataObject(Metadata.Tasks, "Task", "Task", StandardFormNames, PictureLib.Task, List);
	
EndProcedure

// Selectes those of passed forms, which have saved settings of user
// in User parameter. Also, selected forms are recorded to parameter
// FormListWithSavedSettings.
//
Procedure GetSavedSettingsList(FormList, User, FormListWithSavedSettings) Export
	
	For Each Item In FormList Do
		
		IsAdded = False;
		
		Details = SystemSettingsStorage.GetDescription(Item.Value + "/FormSettings", , User);
		
		If Details <> Undefined Then
			FormListWithSavedSettings.Add(Item.Value, Item.Presentation, Item.Check, Item.Picture);
			IsAdded = True;
		EndIf;
		
		Details = SystemSettingsStorage.GetDescription(Item.Value + "/WindowSettings", , User);
		If Details <> Undefined And NOT IsAdded Then
			FormListWithSavedSettings.Add(Item.Value, Item.Presentation, Item.Check, Item.Picture);
		EndIf;
		
	EndDo;
	
EndProcedure

// Copies settings of one IB to another.
// Parameters
// UserSource    - string - IB username, having saved settings
// UsersReceiver - string - IB username, to whom we copy settings
// SettingsForCopyArray - array - array of rows, each row is - form full name
//
Procedure CopyFormSettings(UserSource, UsersReceiver, SettingsForCopyArray) Export
	
	For Each Item In SettingsForCopyArray Do
		Options = SystemSettingsStorage.Load(Item + "/FormSettings", "", , UserSource);
		If Options <> Undefined Then
			For Each UserReceiver In UsersReceiver Do
				SystemSettingsStorage.Save(Item + "/FormSettings", "", Options, , UserReceiver);
			EndDo;
		EndIf;
	EndDo;
	
EndProcedure

// Procedure deletes all user settings,
// related to the forms.
// User - string - IB username
// SettingsForCopyArray - array - array of rows, each row is - form full name
//
Procedure DeleteFormSettings(User, SettingsForDeleteArray) Export
	
	For Each Item In SettingsForDeleteArray Do
		SystemSettingsStorage.Delete(Item + "/FormSettings", "", User);
		SystemSettingsStorage.Delete(Item + "/WindowSettings", "", User);
	EndDo;
	
EndProcedure
