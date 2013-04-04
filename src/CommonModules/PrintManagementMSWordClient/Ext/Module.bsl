
//////////////////////////////////////////////////////////////////////////////////
// SECTION OF TOOLS FOR WORKS WITH TEMPLATES OF OFFICE DOCUMENTS

// Description of data structures:
//
// Handler - structure used to connect with COM objects
//  - COMConnection  - COMObject
//  - Type 			 - string - either "DOC" or "ODT"
//  - FileName 		 - string - template file name (filled only for template)
//  - LastOutputType - type of the last output area
//  - (see AreaType)
//
// Area in document
//  - COMConnection - COMObject
//  - Type  - string - either "DOC" or "ODT"
//  - Start - start area position
//  - End   - end area position
//

////////////////////////////////////////////////////////////////////////////////
// Export functions

// Create COM connection with COM object Word.Application, create single
// document. Prepare.
//
Function InitializePrintFormMSWord(TemplatePageSettings) Export
	
	Handler = New Structure("Type", "DOC");
	
	Try
		COMObject = New COMObject("Word.Application");
	Except
		ErrorMessage = NStr("en = 'Print form generation failed. Make sure Microsoft Word is installed. Details:'")
								+ BriefErrorDescription(ErrorInfo());
		Raise ErrorMessage;
	EndTry;
	
	Handler.Insert("COMConnection", COMObject);
	
	Try
		COMObject.Documents.Add();
	Except
		COMObject.Quit(0);
		COMObject = 0;
		Handler.COMObject = 0;
		
		ErrorMessage = NStr("en = 'Failed to generate the document print form. Details: '")
							+ BriefErrorDescription(ErrorInfo());
		Raise ErrorMessage;
	EndTry;
	
	For Each Options In TemplatePageSettings Do
		Try
			COMObject.ActiveDocument.PageSetup[Options.Key] = Options.Value;
		Except
		// try..except for case, if these, or other settings
		// are not supported by the program current version
		EndTry;
	EndDo;
	
	Return Handler;
	
EndFunction

// Creates COM connection with COM object Word.Application and opens
// template there. Template file being saved based on binary data
// passed in function parameters.
//
// Parameters:
// LayoutBinaryData - BinaryData - template binary data
// Value returned:
// structure - ref template
//
Function GetMSWordTemplate(Val LayoutBinaryData, Val TemporaryFileName = "") Export
	
	Handler = New Structure("Type", "DOC");
	
	Try
		COMObject = New COMObject("Word.Application");
	Except
		Raise(NStr("en = 'MS Word application error. Check application settings.'"));
	EndTry;
	
#If NOT WebClient Then
	TemporaryFileName = GetTempFileName("DOC");
	LayoutBinaryData.Write(TemporaryFileName);
#EndIf
	
	Try
		COMObject.Documents.Open(TemporaryFileName);
	Except
		COMObject.Quit(0);
		COMObject 		  = 0;
		Handler.COMObject = 0;
		DeleteFiles(TemporaryFileName);
		Raise(NStr("en = 'Error opening the template.'")+BriefErrorDescription(ErrorInfo()));
	EndTry;
	
	Handler.Insert("COMConnection",  COMObject);
	Handler.Insert("FileName", 		 TemporaryFileName);
	Handler.Insert("ThisIsTemplate", True);
	
	Handler.Insert("TemplatePageSettings", New Map);
	
	For Each SettingsName In PageParametersSettings() Do
		Try
			Handler.TemplatePageSettings.Insert(SettingsName, COMObject.ActiveDocument.PageSetup[SettingsName]);
		Except
		// try..except for case, if these, or other settings
		// are not supported by the program current version
		EndTry;
	EndDo;
	
	Return Handler;
	
EndFunction

// Closes connection with COM object Word.Application
// Parameters:
// Handler 			- ref to the print form or template
// CloseApplication - boolean - if application should be closed
//
Procedure CloseConnection(Handler, Val CloseApplication) Export
	
	If CloseApplication Then
		Handler.COMConnection.Quit(0);
	EndIf;
	
	Handler.COMConnection = 0;
	
	If Handler.Property("FileName") Then
		DeleteFiles(Handler.FileName);
	EndIf;
	
EndProcedure

// Sets MS Word visibility property
// Handler - ref to the print form
//
Procedure ShowMSWordDocument(Val Handler) Export
	
	COMConnection = Handler.COMConnection;
	COMConnection.Application.Visible = True;
	COMConnection.Activate();
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Functions for getting template areas

// Gets area from template.
// Parameters
// Handler 		- template ref
// AreaName 	- area name in template
// ShiftBegin 	- offset relative to area start
//					offset by default: 1 	- area is taken without carriage return
//					char, after operator bracket of area opening
// ShiftEnding 	- offset relative to area ending,
//					offset by default: -11 	- means that area is taken without
//					carriage return char, before operator bracket of area ending
//
Function GetMSWordTemplateArea(Val Handler,
									Val AreaName,
									Val ShiftBegin 	= 1,
									Val ShiftEnding = -1) Export
	
	Result = New Structure("Document,Start,End");
	
	PositionStart  = ShiftBegin + GetAreaBeginPosition(Handler.COMConnection, AreaName);
	PositionEnding = ShiftEnding + GetAreaEndPosition(Handler.COMConnection, AreaName);
	
	Result.Document = Handler.COMConnection.ActiveDocument;
	Result.Start 	= PositionStart;
	Result.End   	= PositionEnding;
	
	Return Result;
	
EndFunction

// Gets header area of the first template area
// Parameters
// Handler - template ref
// Value to return:
// ref to the header
//
Function GetTopFooterArea(Val Handler) Export
	
	Return New Structure("Header", Handler.COMConnection.ActiveDocument.Sections(1).Headers.Item(1));
	
EndFunction

// Gets footer area of the first template area
// Parameters
// Handler - template ref
// Value to return:
// ref to the footer
//
Function GetLowerFooterArea(Handler) Export
	
	Return New Structure("Footer", Handler.COMConnection.ActiveDocument.Sections(1).Footers.Item(1));
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Functions for addind areas to the print form

// begin: functions for operations with MS Word document headers and footers

// Adds footer to the print form from a template.
// Parameters
// PrintForm 	- ref to the print form
// AreaHandler 	- ref to the template area
// Parameters 	- list of parameters for the value replacement
// ObjectData 	- object data for filling
//
Procedure AddFooter(Val PrintForm,
									Val AreaHandler) Export
	
	AreaHandler.Footer.Range.Copy();
	PrintForm.COMConnection.ActiveDocument.Sections(1).Footers.Item(1).Range.Paste();
	
EndProcedure

// Adds header to the print form from template.
// Parameters
// PrintForm 	- ref to the print form
// AreaHandler 	- ref to the template area
// Parameters 	- list of parameters for the value replacement
// ObjectData 	- object data for filling
//
Procedure FillFooterParameters(Val PrintForm,
												Val ObjectData = Undefined) Export
	
	For Each ParameterValue In ObjectData Do
		If TypeOf(ParameterValue.Value) <> Type("Array") Then
			ExecuteReplacementInBottomFooter(PrintForm.COMConnection,
												ParameterValue.Key,
												ParameterValue.Value);
		EndIf;
	EndDo;
	
EndProcedure

Function ExecuteReplacementInBottomFooter(COMConnection, TextForSearch, ReplacementText)
	
	Range  = COMConnection.ActiveDocument.Sections(1).Footers.Item(1).Range;
	Search = Range.Find;
	Search.ClearFormatting();
	Search.Execute("{v8 " + TextForSearch + "}");
	If Search.Found Then
		Range.Text = ReplacementText;
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

// Adds header to the print form from template.
// Parameters
// PrintForm 	- ref to the print form
// AreaHandler 	- ref to the template area
// Parameters 	- list of parameters for the value replacement
// ObjectData 	- object data for filling
//
Procedure AddHeader(Val PrintForm,
									Val AreaHandler) Export
	
	AreaHandler.Header.Range.Copy();
	PrintForm.COMConnection.ActiveDocument.Sections(1).Headers.Item(1).Range.Paste();
	
EndProcedure

// Adds header to the print form from template.
// Parameters
// PrintForm 	- ref to the print form
// AreaHandler 	- ref to the template area
// Parameters 	- list of parameters for the value replacement
// ObjectData 	- object data for filling
//
Procedure FillHeaderParameters(Val PrintForm,
												Val ObjectData = Undefined) Export
	
	For Each ParameterValue In ObjectData Do
		If TypeOf(ParameterValue.Value) <> Type("Array") Then
			ExecuteReplacementInTopFooter(PrintForm.COMConnection,
												ParameterValue.Key,
												ParameterValue.Value);
		EndIf;
	EndDo;
	
EndProcedure

Function ExecuteReplacementInTopFooter(COMConnection, TextForSearch, ReplacementText)
	
	Range 	= COMConnection.ActiveDocument.Sections(1).Headers.Item(1).Range;
	Search 	= Range.Find;
	Search.ClearFormatting();
	Search.Execute("{v8 " + TextForSearch + "}");
	If Search.Found Then
		Range.Text = ReplacementText;
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

// end: functions for operations with MS Word document headers and footers

// Adds area to the print form from template, at the same time
// replacing parameters in the area with the values from object data.
// Used when area is being output alone.
//
// Parameters
// PrintForm 		- ref to the print form
// AreaHandler 		- ref to the area in template.
// GoToNext_Line 	- boolean, if break should be inserted after area output
//
// Value returned:
// AreaCoordinates
//
Function JoinArea(Val PrintForm,
							Val AreaHandler,
							Val GoToNext_Line   = True,
							Val JoinStringTable = False) Export
	
	AreaHandler.Document.Range(AreaHandler.Start, AreaHandler.End).Copy();
	
	PF_ActiveDocument 			= PrintForm.COMConnection.ActiveDocument;
	PositionDocumentEnding		= PF_ActiveDocument.Range().End;
	InsertionArea				= PF_ActiveDocument.Range(PositionDocumentEnding-1, PositionDocumentEnding-1);
	
	If JoinStringTable Then
		InsertionArea.PasteAppendTable();
	Else
		InsertionArea.Paste();
	EndIf;
	
	// return boundaries of the inserted area
	Result = New Structure("Document, Start, End",
							PF_ActiveDocument,
							PositionDocumentEnding-1,
							PF_ActiveDocument.Range().End-1);
	
	If GoToNext_Line Then
		InsertBreakAtNewLine(PrintForm);
	EndIf;
	
	Return Result;
	
EndFunction

// Adds list area to the print form from template, replacing
// replacing parameters in the area with the values from object data.
// Used on list data output (marked or numerated)
//
// Parameters
// PrintFormArea - ref to the area in print form
// ObjectData 	 - ObjectData
//
Procedure FillParameters(Val PrintFormArea,
							Val ObjectData = Undefined) Export
	
	For Each ParameterValue In ObjectData Do
		If TypeOf(ParameterValue.Value) <> Type("Array") Then
			ExecuteReplacement(PrintFormArea.Document,
							ParameterValue.Key,
							ParameterValue.Value);
		EndIf;
	EndDo;
	
EndProcedure

Function ExecuteReplacement(Val ActiveDocument, TextForSearch, ReplacementText)
	
	Range  = ActiveDocument.Content;
	Search = Range.Find;
	Search.ClearFormatting();
	Search.Execute("{v8 " + TextForSearch + "}");
	If Search.Found Then
		Range.Text = String(ReplacementText);
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

// begin: work with collections

// Adds list area to the print form from template, replacing
// replacing parameters in the area with the values from object data.
// Used on list data output (marked or numerated)
//
// Parameters
// PrintForm     - ref to the print form
// AreaHandler   - ref to the area in template.
// Parameters    - string, list of parameters, which have to be replaced
// ObjectData    - ObjectData
// GoToNext_Line - boolean, if break should be inserted after area output
//
Procedure JoinAndFillSet(Val PrintForm,
									  Val AreaHandler,
									  Val ObjectData 	= Undefined,
									  Val GoToNext_Line = True) Export
	
	AreaHandler.Document.Range(AreaHandler.Start, AreaHandler.End).Copy();
	
	ActiveDocument = PrintForm.COMConnection.ActiveDocument;
	
	For Each RowData In ObjectData Do
		InsertPosition = ActiveDocument.Range().End;
		InsertionArea = ActiveDocument.Range(InsertPosition-1, InsertPosition-1);
		InsertionArea.Paste();
		
		If TypeOf(RowData) = Type("Structure") Then
			For Each ParameterValue In RowData Do
				ExecuteReplacement(ActiveDocument, ParameterValue.Key, ParameterValue.Value);
			EndDo;
		EndIf;
	EndDo;
	
	If GoToNext_Line Then
		InsertBreakAtNewLine(PrintForm);
	EndIf;
	
EndProcedure

// Adds list area to the print form from template, replacing
// replacing parameters in the area with the values from object data.
// Used on table row output.
//
// Parameters
// PrintForm	 	- ref to the print form
// AreaHandler 		- ref to the area in template.
// TableName 		- description of the table (for data access)
// ObjectData 		- ObjectData
// GoToNext_Line 	- boolean, if break should be inserted after area output
//
Procedure JoinAndFillTableArea(Val PrintForm,
												Val AreaHandler,
												Val ObjectData 				= Undefined,
												Val GoToNext_Line 			= True,
												Val JoiningToExistingLine 	= True) Export
	
	AreaHandler.Document.Range(AreaHandler.Start, AreaHandler.End).Copy();
	
	ActiveDocument = PrintForm.COMConnection.ActiveDocument;
	
	For Each TableRowData In ObjectData Do
		InsertPosition = ActiveDocument.Range().End;
		InsertionArea  = ActiveDocument.Range(InsertPosition-1, InsertPosition-1);
		
		If JoiningToExistingLine Then
			InsertionArea.PasteAppendTable();
		Else
			InsertionArea.Paste();
		EndIf;
		
		If TypeOf(TableRowData) = Type("Structure") Then
			For Each ParameterValue In TableRowData Do
				ExecuteReplacement(ActiveDocument, ParameterValue.Key, ParameterValue.Value);
			EndDo;
		EndIf;
		JoiningToExistingLine = True;
	EndDo;
	
	If GoToNext_Line Then
		InsertBreakAtNewLine(PrintForm);
	EndIf;
	
EndProcedure

// end: work with collections

// Inserts break to a next line
// Parameters
// Handler - ref to the MS Word document where break need to be added
//
Procedure InsertBreakAtNewLine(Val Handler) Export
	
	ActiveDocument = Handler.COMConnection.ActiveDocument;
	PositionDocumentEnding = ActiveDocument.Range().End;
	ActiveDocument.Range(PositionDocumentEnding-1, PositionDocumentEnding-1).InsertParagraphAfter();
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Service not export functions

Function GetAreaBeginPosition(Val COMConnection, Val AreaID)
	
	AreaID = "{v8 Area." + AreaID + "}";
	
	EntireDocument = COMConnection.ActiveDocument.Content;
	EntireDocument.Select();
	
	Search 		= COMConnection.Selection.Find;
	Search.Text = AreaID;
	Search.ClearFormatting();
	Search.Forward = True;
	Search.Execute();
	
	If Search.Found Then
		Return COMConnection.Selection.End;
	EndIf;
	
	Return -1;
	
EndFunction

Function GetAreaEndPosition(Val COMConnection, Val AreaID)
	
	AreaID = "{/v8 Area." + AreaID + "}";
	
	EntireDocument = COMConnection.ActiveDocument.Content;
	EntireDocument.Select();
	
	Search 		= COMConnection.Selection.Find;
	Search.Text = AreaID;
	Search.ClearFormatting();
	Search.Forward = True;
	Search.Execute();
	
	If Search.Found Then
		Return COMConnection.Selection.Start;
	EndIf;
	
	Return -1;

	
EndFunction

Function PageParametersSettings()
	
	SettingsArray = New Array;
	SettingsArray.Add("Orientation");
	SettingsArray.Add("TopMargin");
	SettingsArray.Add("BottomMargin");
	SettingsArray.Add("LeftMargin");
	SettingsArray.Add("RightMargin");
	SettingsArray.Add("Gutter");
	SettingsArray.Add("HeaderDistance");
	SettingsArray.Add("FooterDistance");
	SettingsArray.Add("PageWidth");
	SettingsArray.Add("PageHeight");
	SettingsArray.Add("FirstPageTray");
	SettingsArray.Add("OtherPagesTray");
	SettingsArray.Add("SectionStart");
	SettingsArray.Add("OddAndEvenPagesHeaderFooter");
	SettingsArray.Add("DifferentFirstPageHeaderFooter");
	SettingsArray.Add("VerticalAlignment");
	SettingsArray.Add("SuppressEndnotes");
	SettingsArray.Add("MirrorMargins");
	SettingsArray.Add("TwoPagesOnOne");
	SettingsArray.Add("BookFoldPrinting");
	SettingsArray.Add("BookFoldRevPrinting");
	SettingsArray.Add("BookFoldPrintingSheets");
	SettingsArray.Add("GutterPos");
	
	Return SettingsArray;
	
EndFunction
