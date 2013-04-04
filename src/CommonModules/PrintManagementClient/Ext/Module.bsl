

// Execute print command, which opens result in document print form
Procedure RunPrintCommand(PrintManagerName, TemplateNames, CommandParameter, FormOwner, PrintParameters = Undefined) Export
	
	// Check number of objects
	If NOT CheckQuantityOfPassedObjects(CommandParameter) Then
		Return;
	EndIf;
	
	// Get uniqueness key of the form being opened
	UniqueKey = String(New UUID);
	
	OpenParameters = New Structure("PrintManagerName,TemplateNames,CommandParameter,PrintParameters");
	OpenParameters.PrintManagerName  = PrintManagerName;
	OpenParameters.TemplateNames	 = TemplateNames;
	OpenParameters.CommandParameter	 = CommandParameter;
	OpenParameters.PrintParameters	 = PrintParameters;
	
	// Open documents print form
	OpenForm("CommonForm.DocumentsPrinting", OpenParameters, FormOwner, UniqueKey);
	
EndProcedure

// Execute print command, which outputs result to printer
Procedure RunPrintCommandToPrinter(PrintManagerName, TemplateNames, CommandParameter, PrintParameters = Undefined) Export

	Var SpreadsheetDocuments, PrintObjects, OutputParameters, Address, PrintObjectsMap, Cancellation;
	
	// Check number of objects
	If NOT CheckQuantityOfPassedObjects(CommandParameter) Then
		Return;
	EndIf;
	
	OutputParameters = Undefined;
	
	// Generate spreadsheet documents
	#If ThickClientOrdinaryApplication Then
	PrintManagement.GeneratePrintFormsForQuickPrintOrdinaryApplication(
			PrintManagerName, TemplateNames, CommandParameter, PrintParameters,
			Address, PrintObjectsMap, OutputParameters, Cancellation);
	If NOT Cancellation Then
		PrintObjects = New ValueList;
		SpreadsheetDocuments = GetFromTempStorage(Address);
		For Each PrintingObject In PrintObjectsMap Do
			PrintObjects.Add(PrintingObject.Value, PrintingObject.Key);
		EndDo;
	EndIf;
	#Else
	PrintManagement.GeneratePrintFormsForQuickPrint(
			PrintManagerName, TemplateNames, CommandParameter, PrintParameters,
			SpreadsheetDocuments, PrintObjects, OutputParameters, Cancellation);
	#EndIf
	
	If Cancellation Then
		CommonUseClientServer.MessageToUser(NStr("en = 'No rights for print form output. Contact system administrator.'"));
		Return;
	EndIf;
	
	// Print
	PrintSpreadsheetDocuments(SpreadsheetDocuments, PrintObjects,
			OutputParameters.AvailablePrintingByKits);
	
EndProcedure

// Output spreadsheet documents to printer
Procedure PrintSpreadsheetDocuments(SpreadsheetDocuments, PrintObjects, 
		Val AvailablePrintingByKits) Export
	
	#If WebClient Then
		AvailablePrintingByKits = False;
	#EndIf
	
	If AvailablePrintingByKits Then
		For Each Item In PrintObjects Do
			AreaName = Item.Presentation;
			For Each Item In SpreadsheetDocuments Do
				Spreadsheet = Item.Value;
				Area = Spreadsheet.Areas.Find(AreaName);
				If Area = Undefined Then
					Continue;
				EndIf;
				Spreadsheet.PrintArea = Area;
				Spreadsheet.Print(True);
			EndDo;
		EndDo;
	Else
		For Each Item In SpreadsheetDocuments Do
			Spreadsheet = Item.Value;
			Spreadsheet.Print(True);
		EndDo;
	EndIf;
	
EndProcedure

// Before executing print command check, if at least one object has been passed, because
// for commands with multiple mode empty array can be passed.
Function CheckQuantityOfPassedObjects(CommandParameter)
	
	If TypeOf(CommandParameter) = Type("Array") And CommandParameter.Count() = 0 Then
		Return False;
	Else
		Return True;
	EndIf;
	
EndFunction

Function CheckDocumentsHeld(CommandParameter) Export
	
	ArrayOfNotPostedDocuments = CommonUse.DocumentsArePosted(CommandParameter);
	NumberOfNotPostedDocuments = ArrayOfNotPostedDocuments.Count();
	
	If NumberOfNotPostedDocuments > 0 Then
		
		If NumberOfNotPostedDocuments = 1 Then
			QuestionText = NStr("en = 'Before printing you must post documents! Do you want to post documents and continue?'");
		Else
			QuestionText = NStr("en = 'Before printing you must post documents! Do you want to post documents and continue?'");
		EndIf;
		
		ResponseCode = DoQueryBox(QuestionText, QuestionDialogMode.YesNo);
		
		If ResponseCode = DialogReturnCode.Yes Then
			
			TypeOfPostedDocuments = Undefined;
			ArrayOfNotPostedDocuments = CommonUse.PostDocuments(ArrayOfNotPostedDocuments, TypeOfPostedDocuments);
			
			NotifyChanged(TypeOfPostedDocuments);
		Else
			Return False;
		EndIf;
		
	EndIf;
	
	MessageTemplate = NStr("en = 'Document %1 is not processed. Printing cannot be done.'");
	For Each ItemNPD In ArrayOfNotPostedDocuments Do
		Found = CommandParameter.Find(ItemNPD);
		If Found <> Undefined Then
			CommandParameter.Delete(Found);
			CommonUseClientServer.MessageToUser(
					StringFunctionsClientServer.SubstitureParametersInString(MessageTemplate, String(ItemNPD)), ItemNPD);
		EndIf;
	EndDo;
	
	If CommandParameter.Count() > 0 Then
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// SECTION WITH TOOLS FOR WORK WITH OFFICE DOCUMENT TEMPLATES
//
//	Brief description:
//	Section contains interface functions (API), used for creating
//	print forms based on office documents. At the moment two office
//	application sets MS Office (templates MS Word) and Open Office (templates OO Writer).
//
////////////////////////////////////////////////////////////////////////////////
//	types of data used (defined by specific versions)
//	RefPrintForm	     - ref to the print form
//	RefTemplate			 - ref to template
//	Area				 - ref to area in the print form or template (structure)
//						   defined more in the interface module of service information
//						   about area
//	AreaDetails	 - template area description (see below)
//	FillingData		     - either structure, or array of structures (for the case
//						   of lists and tables
////////////////////////////////////////////////////////////////////////////////
//	AreaDetails  - structure, describing template areas prepared by user
//	key AreaName 	     - area name
//	key AreaTypeType     - Header
//						   Footer
//						   Common
//						   TableRow
//						   List
//

////////////////////////////////////////////////////////////////////////////////
// Functions of refs initialization and closing

// Creates connection with the output print form.
// Has to be called before any actions with the form.
// Parameters:
// DocumentType - string - print form type either "ODT" or "ODT"
//
// Value returned:
// RefPrintForm
//
Function InitializePrintForm(Val DocumentType, Val TemplatePageSettings = Undefined) Export
	
	If Upper(DocumentType) = "DOC" Then
		PrintForm = PrintManagementMSWordClient.InitializePrintFormMSWord(TemplatePageSettings);
		PrintForm.Insert("Type", "DOC");
		PrintForm.Insert("LastOutputArea", Undefined);
		Return PrintForm;
	ElsIf Upper(DocumentType) = "ODT" Then
		PrintForm = PrintManagementOOWriterClient.InitializePrintFormOOWriter();
		PrintForm.Insert("Type", "ODT");
		PrintForm.Insert("LastOutputArea", Undefined);
		Return PrintForm;
	EndIf;
	
EndFunction

// Creates connection with template. If this connection will be used later
// for getting area from it (tags and tables).
//
// Parameters:
//  LayoutBinaryData - BinaryData - template binary data
//  TemplateType - template type, either "ODT", either "ODT"
// Value returned:
//  RefTemplate
//
Function InitializeTemplate(Val LayoutBinaryData, Val TemplateType, Val PathToDirectory = "", Val DesignName = "") Export
	
	#If WebClient Then
	
	MessageText = NStr("en = 'Work with file extension in Web client has not been set up.'");
	CommonUseClient.SuggestWorkWithFilesExtensionInstallationNow(MessageText);
	
	If NOT AttachFileSystemExtension() Then
		Return Undefined;
	EndIf;
	
	If IsBlankString(DesignName) Then
		TemporaryFileName = String(New UUID) + "." + Lower(TemplateType);
	Else
		TemporaryFileName = DesignName + "." + Lower(TemplateType);
	EndIf;
	
	FilesBeingReceived = New Map;
	FilesBeingReceived.Insert(TemporaryFileName, LayoutBinaryData);
	
	Result = GetFilesToFilesPrintDirectory(PathToDirectory, FilesBeingReceived);
	
	If Result = Undefined Then
		Return Undefined;
	EndIf;
	
	TemporaryFileName = Result + TemporaryFileName;
	#Else
	TemporaryFileName = "";
	#EndIf

	If Upper(TemplateType) 	  = "DOC" Then
		Template = PrintManagementMSWordClient.GetMSWordTemplate(LayoutBinaryData, TemporaryFileName);
		Template.Insert("Type", "DOC");
		Return Template;
	ElsIf Upper(TemplateType) = "ODT" Then
		Template = PrintManagementOOWriterClient.GetOOWriterTemplate(LayoutBinaryData, TemporaryFileName);
		Template.Insert("Type", "ODT");
		Template.Insert("TemplatePageSettings", Undefined);
		Return Template;
	EndIf;
	
EndFunction

#If WebClient Then
// Function gets file(s) from server to a local directory on disk and returns
// directory name, where they have been saved
// Parameters:
// PathToDirectory    - string - path the directory, where files should be saved
// FilesBeingReceived - map - key   - file name
//                            value - file binary data
//
Function GetFilesToFilesPrintDirectory(PathToDirectory, FilesBeingReceived) Export
	
	RequiredToSetPrintDir = True;
	
	If ValueIsFilled(PathToDirectory) Then
		File = New File(PathToDirectory);
		If NOT File.Exist() Then
			RequiredToSetPrintDir = False;
		EndIf;
	EndIf;
	
	If RequiredToSetPrintDir Then
		Result = OpenFormModal("InformationRegister.PrintedFormTemplates.Form.PrintFilesFolderSettings");
		If TypeOf(Result) = Type("String") Then
			PathToDirectory = Result;
		Else
			Return Undefined;
		EndIf;
	EndIf;
	
	RepeatPrint = True;
	
	While RepeatPrint Do
		RepeatPrint = False;
		Try
			FilesInTemporaryStorage = GetFileAddressesInTemporaryStorage(FilesBeingReceived);
			
			FilesDetailss = New Array;
			
			For Each FileInTemporaryStorage In FilesInTemporaryStorage Do
				FilesDetailss.Add(New TransferableFileDescription(FileInTemporaryStorage.Key,FileInTemporaryStorage.Value));
			EndDo;
			
			If NOT GetFiles(FilesDetailss, , PathToDirectory, False) Then
				Return Undefined;
			EndIf;
		Except
			ErrorMessage = BriefErrorDescription(ErrorInfo());
			Result = OpenFormModal("InformationRegister.PrintedFormTemplates.Form.RepeatPrintingDialog", New Structure("ErrorMessage", ErrorMessage));
			If TypeOf(Result) = Type("String") Then
				RepeatPrint = True;
				PathToDirectory = Result;
			Else
				Return Undefined;
			EndIf;
		EndTry;
	EndDo;
	
	If Right(PathToDirectory, 1) <> "\" Then
		PathToDirectory = PathToDirectory + "\";
	EndIf;
	
	Return PathToDirectory;
	
EndFunction

// Puts binary data set into temporary storage
// Parameters:
// 	SetOfValues - map, key - key, linked with binary data
// 								  value - BinaryData
// Value returned:
// map: key     - key, linked with address in temporary storage
//                value - address in temporary storage
//
Function GetFileAddressesInTemporaryStorage(SetOfValues)
	
	Result = New Map;
	
	For Each KeyValue In SetOfValues Do
		Result.Insert(KeyValue.Key, PutToTempStorage(KeyValue.Value));
	EndDo;
	
	Return Result;
	
EndFunction
#EndIf

// Clears links in the created interface of link with office application.
// Has to be called every time after template has been generated and after output
// of print form to a user.
// Parameters:
// Handler - RefPrintForm, RefTemplate
// CloseApplication - boolean - if application should be closed.
//					  Link with template should be closed along with application closing.
//					  PrintForm should not be closed.
//
Procedure ClearReferences(Handler, Val CloseApplication = True) Export
	
	If Handler <> Undefined Then
		If Handler.Type = "DOC" Then
			PrintManagementMSWordClient.CloseConnection(Handler, CloseApplication);
		Else
			PrintManagementOOWriterClient.CloseConnection(Handler, CloseApplication);
		EndIf;
		Handler = Undefined;
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Function shows print form to a user

// Shows generated document to a user.
// Actually assigns visibility flag to it.
// Parameters
//  Handler - RefPrintForm
//
Procedure ShowDocument(Val Handler) Export
	
	If Handler.Type = "DOC" Then
		PrintManagementMSWordClient.ShowMSWordDocument(Handler);
	ElsIf Handler.Type = "ODT" Then
		PrintManagementOOWriterClient.ShowOOWriterDocument(Handler);
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Function for getting areas from templates, for output tenlate areas to the print form
// and for filling their parameters

// Gets area from template.
// Parameters
// RefTemplate - RefTemplate - ref to a template
// AreaDetails - AreaDetails - area description
//
// Value to return:
// Area - area from template
//
Function GetArea(Val RefTemplate, Val AreaDetails) Export
	
	Area = Undefined;
	If RefTemplate.Type = "DOC" Then
		
		If		AreaDetails.AreaType = "Header" Then
			Area = PrintManagementMSWordClient.GetTopFooterArea(RefTemplate);
		ElsIf	AreaDetails.AreaType = "Footer" Then
			Area = PrintManagementMSWordClient.GetLowerFooterArea(RefTemplate);
		ElsIf	AreaDetails.AreaType = "Common"
				OR AreaDetails.AreaType = "TableRow" Then
			Area = PrintManagementMSWordClient.GetMSWordTemplateArea(RefTemplate, AreaDetails.AreaName);
		ElsIf	AreaDetails.AreaType = "List" Then
			Area = PrintManagementMSWordClient.GetMSWordTemplateArea(RefTemplate, AreaDetails.AreaName, 1, 0);
		Else
			Raise
				StringFunctionsClientServer.SubstitureParametersInString(
					NStr("en = 'The area type is not specified or incorrect: %1.'"), AreaDetails.AreaType);
		EndIf;
		
		If Area <> Undefined Then
			Area.Insert("AreaDetails", AreaDetails);
		EndIf;
	ElsIf RefTemplate.Type = "ODT" Then
		
		If		AreaDetails.AreaType = "Header" Then
			Area = PrintManagementOOWriterClient.GetTopFooterArea(RefTemplate);
		ElsIf	AreaDetails.AreaType = "Footer" Then
			Area = PrintManagementOOWriterClient.GetLowerFooterArea(RefTemplate);
		ElsIf	AreaDetails.AreaType = "Common"
				OR AreaDetails.AreaType = "TableRow"
				OR AreaDetails.AreaType = "List" Then
			Area = PrintManagementOOWriterClient.GetTemplateArea(RefTemplate, AreaDetails.AreaName);
		Else
			Raise
				StringFunctionsClientServer.SubstitureParametersInString(
					NStr("en = 'The area type is not specified or incorrect: %1.'"), AreaDetails.AreaName);
		EndIf;
		
		If Area <> Undefined Then
			Area.Insert("AreaDetails", AreaDetails);
		EndIf;
	EndIf;
	
	Return Area;
	
EndFunction

// Joins area to the print form from template.
// Used when area is being output alone.
//
// Parameters
// PrintForm    - RefPrintForm - ref to the print form
// TemplateArea - Area - area from template
// GoToNextLine - boolean, if break should be inserted after area output
//
Procedure JoinArea(Val PrintForm,
							  Val TemplateArea,
							  Val GoToNextLine = True) Export
	
	Try
		AreaDetails = TemplateArea.AreaDetails;
		
		If PrintForm.Type = "DOC" Then
			
			DisplayedArea = Undefined;
			
			If		AreaDetails.AreaType = "Header" Then
				PrintManagementMSWordClient.AddHeader(PrintForm, TemplateArea);
			ElsIf	AreaDetails.AreaType = "Footer" Then
				PrintManagementMSWordClient.AddFooter(PrintForm, TemplateArea);
			ElsIf	AreaDetails.AreaType = "Common" Then
				DisplayedArea = PrintManagementMSWordClient.JoinArea(PrintForm, TemplateArea, GoToNextLine);
				PrintManagementMSWordClient.InsertBreakAtNewLine(PrintForm);
			ElsIf	AreaDetails.AreaType = "List" Then
				DisplayedArea = PrintManagementMSWordClient.JoinArea(PrintForm, TemplateArea, GoToNextLine);
			ElsIf	AreaDetails.AreaType = "TableRow" Then
				If PrintForm.LastOutputArea <> Undefined
				   And PrintForm.LastOutputArea.AreaType = "TableRow"
				   And NOT PrintForm.LastOutputArea.GoToNextLine Then
					DisplayedArea = PrintManagementMSWordClient.JoinArea(PrintForm, TemplateArea, GoToNextLine, True);
				Else
					DisplayedArea = PrintManagementMSWordClient.JoinArea(PrintForm, TemplateArea, GoToNextLine);
				EndIf;
			Else
				Raise(NStr("en = 'The area type is not specified or incorrect.'"));
			EndIf;
			
			AreaDetails.Insert("Area", DisplayedArea);
			AreaDetails.Insert("GoToNextLine", GoToNextLine);
			
			PrintForm.LastOutputArea = AreaDetails; // contains area type, and area boundaries (if required)
			
		ElsIf PrintForm.Type = "ODT" Then
			If		AreaDetails.AreaType = "Header" Then
				PrintManagementOOWriterClient.AddHeader(PrintForm, TemplateArea);
			ElsIf	AreaDetails.AreaType = "Footer" Then
				PrintManagementOOWriterClient.AddFooter(PrintForm, TemplateArea);
			ElsIf	AreaDetails.AreaType = "Common"
					OR AreaDetails.AreaType = "List" Then
				PrintManagementOOWriterClient.SetMainCursorOnDocumentBody(PrintForm);
				PrintManagementOOWriterClient.JoinArea(PrintForm, TemplateArea, GoToNextLine);
			ElsIf	AreaDetails.AreaType = "TableRow" Then
				PrintManagementOOWriterClient.SetMainCursorOnDocumentBody(PrintForm);
				PrintManagementOOWriterClient.JoinArea(PrintForm, TemplateArea, GoToNextLine, True);
			Else
				Raise(NStr("en = 'The area type is not specified or incorrect'"));
			EndIf;
			PrintForm.LastOutputArea = AreaDetails; // contains area type, and area boundaries (if required)
		EndIf;
	Except
		ErrorMessage = TrimAll(BriefErrorDescription(ErrorInfo()));
		ErrorMessage = ?(Right(ErrorMessage, 1) = ".", ErrorMessage, ErrorMessage + ".");
		ErrorMessage = ErrorMessage + 
				StringFunctionsClientServer.SubstitureParametersInString(
					NStr("en = 'An error occurred when displaying a field ''%1 '' from the template.'"),
					TemplateArea.AreaDetails.AreaName);
		Raise ErrorMessage;
	EndTry;
	
EndProcedure

// Fills area parameters of the  print form
//
// Parameters
// PrintForm	- RefPrintForm, Area - print form area, or print form itself
// Data			- FillingData
//
Procedure FillParameters(Val PrintForm, Val Data) Export
	
	AreaDetails = PrintForm.LastOutputArea;
	
	If PrintForm.Type = "DOC" Then
		If		AreaDetails.AreaType = "Header" Then
			PrintManagementMSWordClient.FillHeaderParameters(PrintForm, Data);
		ElsIf	AreaDetails.AreaType = "Footer" Then
			PrintManagementMSWordClient.FillFooterParameters(PrintForm, Data);
		ElsIf	AreaDetails.AreaType = "Common"
				OR AreaDetails.AreaType = "TableRow"
				OR AreaDetails.AreaType = "List" Then
			PrintManagementMSWordClient.FillParameters(PrintForm.LastOutputArea.Area, Data);
		Else
			Raise(NStr("en = 'The area type is not specified or incorrect'"));
		EndIf;
	ElsIf PrintForm.Type = "ODT" Then
		If		PrintForm.LastOutputArea.AreaType = "Header" Then
			PrintManagementOOWriterClient.SetMainCursorOnHeader(PrintForm);
		ElsIf	PrintForm.LastOutputArea.AreaType = "Footer" Then
			PrintManagementOOWriterClient.SetMainCursorOnFooter(PrintForm);
		ElsIf	AreaDetails.AreaType = "Common"
				OR AreaDetails.AreaType = "TableRow"
				OR AreaDetails.AreaType = "List" Then
			PrintManagementOOWriterClient.SetMainCursorOnDocumentBody(PrintForm);
		EndIf;
		PrintManagementOOWriterClient.FillParameters(PrintForm, Data);
	EndIf;
	
EndProcedure

// Adds area to the print form from template, at the same time
// replacing parameters in the area with the values from object data.
// Used when area is being output alone.
//
// Parameters
// PrintForm	 - RefPrintForm
// TemplateArea	 - Area
// Data			 - ObjectData
// GoToNext_Line - boolean, if break should be inserted after area output
//
Procedure JoinAreaAndFillParameters(Val PrintForm,
										Val TemplateArea,
										Val Data,
										Val GoToNextLine = True) Export
	
	JoinArea(PrintForm, TemplateArea, GoToNextLine);
	FillParameters(PrintForm, Data)
	
EndProcedure

// Adds area to the print form from template, at the same time
// replacing parameters in the area with the values from object data.
// Used when area is being output alone.
//
// Parameters
// PrintForm	 - RefPrintForm
// TemplateArea	 - Area - template area
// Data			 - ObjectData (array of structures)
// GoToNext_Line - boolean, if break should be inserted after area output
//
Procedure JoinAndFillCollection(Val PrintForm,
										Val TemplateArea,
										Val Data,
										Val GoToNext_Line = True) Export
	
	AreaDetails = TemplateArea.AreaDetails;
	
	If PrintForm.Type = "DOC" Then
		If		AreaDetails.AreaType = "TableRow" Then
			PrintManagementMSWordClient.JoinAndFillTableArea(PrintForm, TemplateArea, Data, GoToNext_Line);
		ElsIf	AreaDetails.AreaType = "List" Then
			PrintManagementMSWordClient.JoinAndFillSet(PrintForm, TemplateArea, Data, GoToNext_Line);
		Else
			Raise(NStr("en = 'The area type is not specified or incorrect'"));
		EndIf;
	ElsIf PrintForm.Type = "ODT" Then
		If		AreaDetails.AreaType = "TableRow" Then
			PrintManagementOOWriterClient.JoinAndFillCollection(PrintForm, TemplateArea, Data, True, GoToNext_Line);
		ElsIf	AreaDetails.AreaType = "List" Then
			PrintManagementOOWriterClient.JoinAndFillCollection(PrintForm, TemplateArea, Data, False, GoToNext_Line);
		Else
			Raise(NStr("en = 'The area type is not specified or incorrect'"));
		EndIf;
	EndIf;
	
EndProcedure

// Inserts break between lines as carriage return char
// Parameters
// PrintForm - RefPrintForm
//
Procedure InsertBreakAtNewLine(Val PrintForm) Export
	
	If	  PrintForm.Type = "DOC" Then
		PrintManagementMSWordClient.InsertBreakAtNewLine(PrintForm);
	ElsIf PrintForm.Type = "ODT" Then
		PrintManagementOOWriterClient.InsertBreakAtNewLine(PrintForm);
	EndIf;
	
EndProcedure
