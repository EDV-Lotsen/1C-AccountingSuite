

////////////////////////////////////////////////////////////////////////////////
// PROCEDURES, GENERATING RESULTS FOR PRINT COMMANDS

// Generate print forms
Procedure GeneratePrintForms(PrintManagerName, TemplateNames, ObjectsArray, PrintParameters,
	PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	// Get print manager
	PrintManager = CommonUse.ObjectManagerByFullName(PrintManagerName);
	
	// Prepare collection for generated print forms
	PrintFormsCollection = PrepareCollectionOfPrintForms(TemplateNames);
	
	// Prepare output parameters structure
	OutputParameters = PrepareOutputParametersStructure();
	
	PrintObjects = New ValueList;
	
	// Generate print forms
	PrintManager.Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters);
	
	// Check if all templates have been generated
	For Each Str In PrintFormsCollection Do
		If Str.SpreadsheetDocument = Undefined Then
			ErrorMessageText = StringFunctionsClientServer.SubstitureParametersInString(
										NStr("en = 'Print handler has not been generated spreadsheet document for: %1'"),
										Str.DesignName);
			Raise(ErrorMessageText);
		EndIf;
		
		Str.SpreadsheetDocument.Copies = Str.NumberOfCopies;
	EndDo;
	
EndProcedure

// Generate print forms for direct output to a printer
Procedure GeneratePrintFormsForQuickPrint(
		PrintManagerName, TemplateNames, ObjectsArray, PrintParameters,
		SpreadsheetDocuments, PrintObjects, OutputParameters, Cancellation) Export
	
	If NOT AccessRight("Output", Metadata) Then
		Cancellation = True;
		Return;
	Else
		Cancellation = False;
	EndIf;
	
	PrintFormsCollection = Undefined;
	PrintObjects = New ValueList;
	
	GeneratePrintForms(PrintManagerName, TemplateNames, ObjectsArray, PrintParameters,
		PrintFormsCollection, PrintObjects, OutputParameters);
		
	SpreadsheetDocuments = New ValueList;
	
	For Each Str In PrintFormsCollection Do
		If (TypeOf(Str.SpreadsheetDocument) = Type("SpreadsheetDocument")) And (Str.SpreadsheetDocument.TableHeight <> 0) Then
			SpreadsheetDocuments.Add(Str.SpreadsheetDocument, Str.TemplateSynonym);
		EndIf;
	EndDo;
	
EndProcedure

// Generate print forms for direct output to a printer
// in server mode in ordinary application
Procedure GeneratePrintFormsForQuickPrintOrdinaryApplication(
				PrintManagerName, TemplateNames, ObjectsArray, PrintParameters,
				Address, PrintObjects, OutputParameters, Cancellation) Export
	
	Var PrintObjectsVL, SpreadsheetDocuments;
	
	GeneratePrintFormsForQuickPrint(
			PrintManagerName, TemplateNames, ObjectsArray, PrintParameters,
			SpreadsheetDocuments, PrintObjectsVL, OutputParameters, Cancellation);
	
	If Cancellation Then
		Return;
	EndIf;
	
	PrintObjects = New Map;
	
	For Each PrintingObject In PrintObjectsVL Do
		PrintObjects.Insert(PrintingObject.Presentation, PrintingObject.Value);
	EndDo;
	
	Address = PutToTempStorage(SpreadsheetDocuments);
	
EndProcedure
////////////////////////////////////////////////////////////////////////////////
// FUNCTIONS AND PROCEDURES, USED BY MODULES OF OBJECT MANAGERS TO GENERATE SPREADSHEET DOCUMENTS

// Check, if template has to be printed
Function NeedToPrintTemplate(PrintFormsCollection, DesignName) Export
	
	Return PrintFormsCollection.Find(Upper(DesignName), "UPPERName") <> Undefined;
	
EndFunction

// Output spreadsheet document into the collection of print forms
Procedure OutputSpreadsheetDocumentToCollection(PrintFormsCollection, DesignName, TemplateSynonym, SpreadsheetDocument, Picture = Undefined, FullPathToTemplate = "") Export
	
	Row = PrintFormsCollection.Find(Upper(DesignName), "UPPERName");
	
	If Row <> Undefined Then
		Row.SpreadsheetDocument = SpreadsheetDocument;
		Row.TemplateSynonym 	= TemplateSynonym;
		Row.Picture 			= Picture;
		Row.FullPathToTemplate 	= FullPathToTemplate;
	EndIf;
	
EndProcedure

// Specify object printing area in spreadsheet document.
// Used to link area of spreadsheet documents with a print object (ref).
// Should be called when next print form area is being generated in spreadsheet
// document.
// Parameters:
//  SpreadsheetDocument - spreadsheet document - print form spreadsheet document
//  LineNumberBegin 	- number - next area start position
//  PrintObjects 		- ValueList - list of print objects
//  Ref 				- ref to IB object - print object
//
Procedure SetDocumentPrintArea(SpreadsheetDocument, LineNumberBegin, PrintObjects, Ref) Export
	
	Item = PrintObjects.FindByValue(Ref);
	If Item = Undefined Then
		AreaName = "Document_" + Format(PrintObjects.Count() + 1, "NZ=; NG=");
		PrintObjects.Add(Ref, AreaName);
	Else
		AreaName = Item.Presentation;
	EndIf;
	
	LineNumberEnding = SpreadsheetDocument.TableHeight;
	SpreadsheetDocument.Area(LineNumberBegin, , LineNumberEnding, ).Name = AreaName;

EndProcedure

////////////////////////////////////////////////////////////////////////////////
// AUXILIARY NOT EXPORT FUNCTIONS

// Prepare collection of print forms - value table used when generating print forms
//
Function PrepareCollectionOfPrintForms(TemplateNames) Export
	
	Templates = New ValueTable;
	Templates.Columns.Add("DesignName");
	Templates.Columns.Add("UPPERName");
	Templates.Columns.Add("TemplateSynonym");
	Templates.Columns.Add("SpreadsheetDocument");
	Templates.Columns.Add("NumberOfCopies");
	Templates.Columns.Add("Picture");
	Templates.Columns.Add("FullPathToTemplate");
	
	StrOfNames = StrReplace(TemplateNames, ",", Chars.LF);
	For Acc = 1 To StrLineCount(StrOfNames) Do
		Name = StrGetLine(StrOfNames, Acc);
		Str = Templates.Find(Name, "DesignName");
		If Str = Undefined Then
			Str 				= Templates.Add();
			Str.DesignName 		= Name;
			Str.UPPERName   	= Upper(Name);
			Str.NumberOfCopies 	= 1;
		Else
			Str.NumberOfCopies = Str.NumberOfCopies + 1;
		EndIf;
	EndDo;
	
	Return Templates;
	
EndFunction

// Prepare structure of output parameters for the object manager that generates print forms
//
Function PrepareOutputParametersStructure() Export
	
	OutputParameters = New Structure;
	OutputParameters.Insert("AvailablePrintingByKits",		False);
	OutputParameters.Insert("EmailRecipient",				Undefined);
	OutputParameters.Insert("EmailSender",					Undefined);
	
	Return OutputParameters;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// SECTION OF TOOLS FOR WORKS WITH TEMPLATES OF OFFICE DOCUMENTS

// Adds new record about area to the parameter AreasSet
// Parameters
// AreasSet - array  - set of areas (array of structures)
// AreaName - string - name of the area being added
// AreaType - string - area type:
//			Header
//			Footer
//			Common
//			TableRow
//			List
//
Procedure AddAreaDetails(AreasSet, Val AreaName, Val AreaType) Export
	
	NewArea = New Structure;
	
	NewArea.Insert("AreaName", AreaName);
	NewArea.Insert("AreaType", AreaType);
	
	AreasSet.Insert(AreaName, NewArea);
	
EndProcedure

// Interface for calling forms from client modules by the office document templates.
// Gets all the required information per single call: objects template data, binary
// template data, description of templates areas.
// Parameters:
// PrintManagerName   - string - name for access object manager, for example "Document.<Name document>"
// TemplateNames      - string - template names, used for creating print forms
// DocumentsContent   - array of refs - references to infobase objects (must be of the same type)
//
Function GetTemplatesAndDataOfObjects(Val PrintManagerName,
									  Val TemplateNames,
									  Val DocumentsContent) Export
	
	TemplateNamesArray = StringFunctionsClientServer.DecomposeStringIntoSubstringsArray(StrReplace(TemplateNames, " ", ""), ",");
	
	ObjectManager = CommonUse.ObjectManagerByFullName(PrintManagerName);
	TemplatesAndData = ObjectManager.GetPrintData(DocumentsContent, TemplateNamesArray);
	TemplatesAndData.Insert("PrintFilesLocalDirectory", GetPrintFilesLocalDirectory());
	
	Return TemplatesAndData;
	
EndFunction

// Returns template using template full path.
// Parameters:
//  FullPathToTemplate - String - full path format:
//								"Document.<DocumentName>.<DesignName>"
//								"DataProcessor.<DataProcessorName>.<DesignName>"
//								"CommonTemplate.<DesignName>"
// Value returned:
//	for template of type MXL  - spreadsheet document
//	for templates DOC and ODT - binary data
//
Function GetTemplate(FullPathToTemplate) Export
	
	PathParts = StrReplace(FullPathToTemplate, ".", Chars.LF);
	
	If StrLineCount(PathParts) = 3 Then
		PathToMetadata = StrGetLine(PathParts, 1) + "." + StrGetLine(PathParts, 2);
		PathToMetadataObject = StrGetLine(PathParts, 3);
	ElsIf StrLineCount(PathParts) = 2 Then
		PathToMetadata = StrGetLine(PathParts, 1);
		PathToMetadataObject = StrGetLine(PathParts, 2);
	Else
		Raise NStr("en = 'Incorrect function parameters'");
	EndIf;
	
	Query = New Query;
	
	Query.Text = "SELECT
	             |	PrintedFormTemplates.Template AS Template,
	             |	PrintedFormTemplates.Use AS Use
	             |FROM
	             |	InformationRegister.PrintedFormTemplates AS PrintedFormTemplates
	             |WHERE
	             |	PrintedFormTemplates.Object = &Object
	             |	AND PrintedFormTemplates.DesignName = &DesignName
	             |	AND PrintedFormTemplates.Use";
	
	Query.Parameters.Insert("Object", 		PathToMetadata);
	Query.Parameters.Insert("DesignName", 	PathToMetadataObject);
	                                      	
	SetPrivilegedMode(True);
	
	Selection = Query.Execute().Choose();
	
	SetPrivilegedMode(False);
	
	If Selection.Next() Then
		Result = Selection.Template.Get();
		If Find(PathToMetadataObject, "PF_MXL") Then
			Result = GetSpreadsheetDocumentByBinaryData(Result);
		EndIf;
	Else
		If StrLineCount(PathParts) = 3 Then
			Result = CommonUse.ObjectManagerByFullName(PathToMetadata).GetTemplate(PathToMetadataObject);
		Else
			Result = GetCommonTemplate(PathToMetadataObject);
		EndIf;
	EndIf;
	
	If Result = Undefined Then
		Raise "Incorrect data of user template";
	EndIf;
		
	Return Result;
	
EndFunction

Function GetSpreadsheetDocumentByBinaryData(BinaryData) Export
	
	TemporaryFileName = GetTempFileName();
	BinaryData.Write(TemporaryFileName);
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.Read(TemporaryFileName);
	DeleteFiles(TemporaryFileName);
	
	Return SpreadsheetDocument;
	
EndFunction

Function GetPrintFilesLocalDirectory() Export
	
	Value = CommonSettingsStorage.Load("PrintFilesLocalDirectory");
	Return ?(Value = Undefined, "", Value);
	
EndFunction

Procedure SaveLocalDirectoryOfPrintFiles(Directory) Export
	
	CommonSettingsStorage.Save("PrintFilesLocalDirectory", , Directory);
	
EndProcedure
