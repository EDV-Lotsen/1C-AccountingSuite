
&AtClient
Procedure Create(Command)
	
	ComposeResult();
	
EndProcedure

&AtClient
Procedure GetExcel(Command)
	
	Structure = GeneralFunctions.GetExcelFile("Vendors 1099", Result);
	
	GetFile(Structure.Address, Structure.FileName, True); 
	
EndProcedure

&AtClient
Procedure GetCSV(Command)
	
	//Structure = GeneralFunctions.GetCSVFile("Vendors 1099", Result);
	
	//GetFile(Structure.Address, Structure.FileName, True); 
	
	OutputDocument = GetCSVAtServer();
	//OutputDocument.Show();
	
EndProcedure

&AtServer
Function GetCSVAtServer()
	
	
	// Create template composer and get default data composition template.
	TemplateComposer        = New DataCompositionTemplateComposer;
	DataCompositionSchema   = Reports.Vendors1099.GetTemplate("List1099");
	DataCompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, DataCompositionSchema.DefaultSettings);
	
	// Create the new data composition processor.
	DataCompositionProcessor = New DataCompositionProcessor;
	DataCompositionProcessor.Initialize(DataCompositionTemplate);
	
	//OutputDocument  = New SpreadsheetDocument;
	//OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	//OutputProcessor.SetDocument(OutputDocument);
	//OutputProcessor.Output(DataCompositionProcessor, True);
	//Return OutputDocument;
	
	// Request a value table from data composition processor
	OutputTable     = New ValueTable;
	OutputProcessor = New DataCompositionResultValueCollectionOutputProcessor;
	OutputProcessor.SetObject(OutputTable);
	OutputProcessor.Output(DataCompositionProcessor, True);
	
	Return OutputTable;
	
EndFunction

&AtClient
Procedure Print(Command)
	PrintAtServer();
	Result.Print(PrintDialogUseMode.Use);
EndProcedure

&AtServer
Procedure PrintAtServer()
	Result.PageSize = "Letter"; 
	Result.FitToPage = True;
EndProcedure
