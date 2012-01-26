
////////////////////////////////////////////////////////////////////////////////
// PROCEDURES GENERATING RESULTING DATA FOR PRINT COMMANDS

// Generate print forms
Procedure GeneratePrintForms(PrintManagerName, TemplateNames, ObjectArray, PrintParameters,
	PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	// Get a print manager
	PrintManager = GeneralFunctionsSL.ObjectManagerByFullName(PrintManagerName);
	
	// Create a collection for generated print forms
	PrintFormsCollection = PreparePrintFormCollection(TemplateNames);
	
	// Create a structure of output parameters
	OutputParameters = PrepareOutputParameterStructure();
	
	PrintObjects = New ValueList;
	
	// Generate print forms
	PrintManager.Print(ObjectArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters);
	
	// Check if all templates were generated
	For Each Page In PrintFormsCollection Do
		If Page.SpreadsheetDocument = Undefined Then
			ErrorMessage = StringFunctionsClientServer.SubstituteParametersIntoString(
										NStr("en = 'The print module did not generate a spreadsheet for: %1'"),
										Page.TemplateName);
			Raise(ErrorMessage);
		EndIf;
		
		Page.SpreadsheetDocument.Copies = Page.Copies;
	EndDo;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// FUNCTIONS AND PROCEDURES, USED BY MANAGER OBJECT MODULES FOR GENERATING SPREADSHEETS

// Check if template printing is requested
Function SpreadsheetDocumentPrintRequested(PrintFormsCollection, TemplateName) Export
	
	Return PrintFormsCollection.Find(Upper(TemplateName), "NameUPPER") <> Undefined;
	
EndFunction

// Output a spreadsheet into a print form collection
Procedure OutputSpreadsheetDocumentIntoCollection(PrintFormsCollection, TemplateName, TemplateSynonym, SpreadsheetDocument, Image = Undefined, TemplateFullPath = "") Export
	
	Page = PrintFormsCollection.Find(Upper(TemplateName), "NameUPPER");
	
	If Page <> Undefined Then
		Page.SpreadsheetDocument = SpreadsheetDocument;
		Page.TemplateSynonym = TemplateSynonym;
		Page.Image = Image;
		Page.TemplateFullPath = TemplateFullPath;
	EndIf;
	
EndProcedure

// Sets an object print are in a spreadsheet.
// Used for linking an area in a spreadsheet with a print object (reference).
// Called when a new area of a print form is created in a spreadsheet.
// Parameters:
//  SpreadsheetDocument - spreadsheet - print form spreadsheet
//  BeginningLineNumber - number - beginning position of the current area in the document
//  PrintObjects - ValueList - list of print objects
//  Ref - reference to an infobase object - print object
//
Procedure SetPrintArea(SpreadsheetDocument, BeginningLineNumber, PrintObjects, Ref) Export
	
	Item = PrintObjects.FindByValue(Ref);
	If Item = Undefined Then
		AreaName = "Document_" + Format(PrintObjects.Count() + 1, "NZ=; NG=");
		PrintObjects.Add(Ref, AreaName);
	Else
		RegionName = Item.Presentation;
	EndIf;
	
	LineNumberEnd = SpreadsheetDocument.TableHeight;
	SpreadsheetDocument.Area(BeginningLineNumber, , LineNumberEnd, ).Name = AreaName;

EndProcedure

////////////////////////////////////////////////////////////////////////////////
// AUXILARY NON-EXPORT FUNCTIONS

// Prepare a print form collection - value table used in print form generation
//
Function PreparePrintFormCollection(TemplateNames) Export
	
	Templates = New ValueTable;
	Templates.Columns.Add("TemplateName");
	Templates.Columns.Add("NameUPPER");
	Templates.Columns.Add("TemplateSynonym");
	Templates.Columns.Add("SpreadsheetDocument");
	Templates.Columns.Add("Copies");
	Templates.Columns.Add("Image");
	Templates.Columns.Add("TemplateFullPath");
	
	PageNames = StrReplace(TemplateNames, ",", Chars.LF);
	For Counter = 1 To StrLineCount(PageNames) Do
		Name = StrGetLine(PageNames, Counter);
		Page = Templates.Find(Name, "TemplateName");
		If Page = Undefined Then
			Page = Templates.Add();
			Page.TemplateName = Name;
			Page.NameUPPER   = Upper(Name);
			Page.Copies = 1;
		Else
			Page.Copies = Page.Copies + 1;
		EndIf;
	EndDo;
	
	Return Templates;
	
EndFunction

// Prepare a structure of output parameters for the manager object generating print forms
//
Function PrepareOutputParameterStructure() Export
	
	OutputParameters = New Structure;
	OutputParameters.Insert("KitPrintingEnabled",		False);
	OutputParameters.Insert("EmailRecepient",	Undefined);
	OutputParameters.Insert("EmailSender",	Undefined);
	
	Return OutputParameters;
	
EndFunction


// Returns a template by the full path.
// Parameters:
//  TemplateFullPath - String - full path format:
//								"Document.<DocumentName>.<TemplateName>"
//								"DataProcessor.<DataProcessorName>.<TemplateName>"
//								"CommonTemplate.<TemplateName>"
// Returned value:
//	for an MXL template - spreadsheet
//	for DOC and ODT templates - binary data
//
Function GetTemplate(TemplateFullPath) Export
	
	PathParts = StrReplace(TemplateFullPath, ".", Chars.LF);
	
	If StrLineCount(PathParts) = 3 Then
		MetadataPath = StrGetLine(PathParts, 1) + "." + StrGetLine(PathParts, 2);
		MetadataObjectPath = StrGetLine(PathParts, 3);
	ElsIf StrLineCount(PathParts) = 2 Then
		MetadataPath = StrGetLine(PathParts, 1);
		MetadataObjectPath = StrGetLine(PathParts, 2);
	Else
		Raise NStr("en = 'Incorrect function parameters.'");
	EndIf;
	
	Query = New Query;
	
	Query.Text = "SELECT Template AS Template, Use AS Use
					|FROM
					|	InformationRegister.UserPrintTemplates
					|WHERE
					|	Object=&Object
					|	AND	TemplateName=&TemplateName
					|	AND	Use";
	
	Query.Parameters.Insert("Object", MetadataPath);
	Query.Parameters.Insert("TemplateName", MetadataObjectPath);
	
	SetPrivilegedMode(True);
	
	Selection = Query.Execute().Choose();
	
	SetPrivilegedMode(False);
	
	If Selection.Next() Then
		Result = Selection.Template.Get();
		If Find(MetadataObjectPath, "PF_MXL") Then
			Result = GetSpreadsheetByBinaryData(Result);
		EndIf;
	Else
		If StrLineCount(PathParts) = 3 Then
			Result = GeneralFunctionsSL.ObjectManagerByFullName(MetadataPath).GetTemplate(MetadataObjectPath);
		Else
			Result = GetCommonTemplate(MetadataObjectPath);
		EndIf;
	EndIf;
	
	If Result = Undefined Then
		Raise "Incorrect user template";
	EndIf;
		
	Return Result;
	
EndFunction

// Receives spreadsheet binary data
// and based on them creates an object - spreadsheet.
// Parameters
//  BinaryData - spreadsheet binary data
// Returned value
//  Spreadsheet
//
Function GetSpreadsheetByBinaryData(BinaryData) Export
	
	TempFileName = GetTempFileName();
	BinaryData.Write(TempFileName);
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.Read(TempFileName);
	DeleteFiles(TempFileName);
	
	Return SpreadsheetDocument;
	
EndFunction

// Returns a path to the print catalog from the common settings storage
//
Function GetLocalPrintFolder() Export
	
	Value = CommonSettingsStorage.Load("LocalPrintFolder");
	Return ?(Value = Undefined, "", Value);
	
EndFunction

// Saves a path to the print catalog to the common settings storage
// Parameters
//  Catalog - String - path to the print catalog
//
Procedure SaveLocalPrintFolder(Folder) Export
	
	CommonSettingsStorage.Save("LocalPrintFolder", , Folder);
	
EndProcedure

