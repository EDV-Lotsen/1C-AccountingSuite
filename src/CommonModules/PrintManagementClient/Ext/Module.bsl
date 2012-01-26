
// Run the print command, which opens a result in the document print form
Procedure ExecutePrintCommand(PrintManagerName, TemplateNames, CommandParameter, FormOwner, PrintParameters = Undefined) Export
	
	If TypeOf(CommandParameter) = Type("Array") Then
		GeneralFunctionsClientServerSL.DeleteAllInstancesOfTypeFromArray(CommandParameter, Type("DynamicalListGroupRow"));
	EndIf;
	
	// Check quantity of objects
	If NOT CheckQtyOfTransferredObjects(CommandParameter) Then
		Return;
	EndIf;
	
	// Get a unique key of an opened form
	UniqueKey = String(New UUID);
	
	OpenParameters = New Structure("PrintManagerName,TemplateNames,CommandParameter,PrintParameters");
	OpenParameters.PrintManagerName = PrintManagerName;
	OpenParameters.TemplateNames		 = TemplateNames;
	OpenParameters.CommandParameter	 = CommandParameter;
	OpenParameters.PrintParameters	 = PrintParameters;
	
	// Open the document print form
	OpenForm("CommonForm.PrintDocuments", OpenParameters, FormOwner, UniqueKey);
	
EndProcedure


// Before executing the print command check, if at least one object was passed, because for commands with the multiple usage mode
// an empty array can be passed.
Function CheckQtyOfTransferredObjects(CommandParameter)
	
	If TypeOf(CommandParameter) = Type("Array") И CommandParameter.Count() = 0 Then
		Return False;
	Else
		Return True;
	EndIf;
	
EndFunction

#If WebClient Then
// Function receives files from the server, puts them into a local catalog, and returns
// the catalog name.
// Parameters:
// CatalogPath - String - path to the catalog where files are saved
// ReceivedFiles - Map - 
//                         Key  - file name
//                         Value - file binary data
//
Function GetFilesIntoPrintCatalog(CatalogPath, ReceivedFiles) Export
	
	NeedToSetPrintFolder = Not ValueIsFilled(CatalogPath);
	If Not NeedToSetPrintFolder Then
		File = New File(CatalogPath);
		If NOT File.Exist() Then
			NeedToSetPrintFolder = True;
		EndIf;
	EndIf;
	
	If NeedToSetPrintFolder Then
		Result = OpenFormModal("InformationRegister.UserPrintTemplates.Form.PrintFolderSetup");
		If TypeOf(Result) <> Type("String") Then
			Return Undefined;
		EndIf;
		CatalogPath = Result;
	EndIf;
	
	RepeatPrinting = True;
	
	While RepeatPrinting Do
		RepeatPrinting = False;
		Try
			FilesInTempStorage = GetFileInTempStorageAddresses(ReceivedFiles);
			
			FileDescriptions = New Array;
			
			For Each FileInTempStorage In FilesInTempStorage Do
				FileDescriptions.Add(New TransferableFileDescription(FileInTempStorage.Key,FileInTempStorage.Value));
			EndDo;
			
			If NOT GetFiles(FileDescriptions, , CatalogPath, False) Then
				Return Undefined;
			EndIf;
		Except
			ErrorMessage = BriefErrorDescription(ErrorInfo());
			Result = OpenFormModal("InformationRegister.UserPrintTemplates.Form.PrintRepeatDialog", New Structure("ErrorMessage", ErrorMessage));
			If TypeOf(Result) = Type("String") Then
				RepeatPrinting = True;
				CatalogPath = Result;
			Else
				Return Undefined;
			EndIf;
		EndTry;
	EndDo;
	
	If Right(CatalogPath, 1) <> "\" Then
		CatalogPath = CatalogPath + "\";
	EndIf;
	
	Return CatalogPath;
	
EndFunction

// Places a set of binary data into the temporary storage
// Parameters:
// 	ValueSet - Map, Key - binary data key
// 								  Value - binary data
// Returned value:
// Map: Key - Temp storage address key
//               Value - address in the temp storage
//
Function GetFileInTempStorageAddresses(ValueSet)
	
	Result = New Map;
	
	For Each KeyValue In ValueSet Do
		Result.Insert(KeyValue.Key, PutToTempStorage(KeyValue.Value));
	EndDo;
	
	Return Result;
	
EndFunction

#EndIf

