
////////////////////////////////////////////////////////////////////////////////
// Document printing: Generating document print forms
//------------------------------------------------------------------------------
// Available on:
// - Server
// - External Connection
//

////////////////////////////////////////////////////////////////////////////////
#Region PUBLIC_INTERFACE

//------------------------------------------------------------------------------
// Query typical document data for printing

// Query returns biiling address data for our company.
//
// Parameters:
//  TablesList - Structure - Contains temporary table names and it's count number.
//
// Returns:
//  String - The batch report section text.
//
Function Query_OurCompany_Addresses_BillingAddress(TablesList) Export
	
	// Add address table to query structure.
	TablesList.Insert("Table_OurCompany_Addresses_BillingAddress", TablesList.Count());
	
	// Collect our company address data.
	QueryText =
	"SELECT
	// ------------------------------------------------------
	// Attributes
	|	Constants.SystemTitle                   AS UsName,
	|	Constants.AddressLine1                  AS UsBillLine1,
	|	Constants.AddressLine2                  AS UsBillLine2,
	|	CASE
	|		WHEN Constants.AddressLine2 = """" THEN // AddressLine1
	|			Constants.AddressLine1
	|		ELSE                                    // AddressLine1, AddressLine2
	|			Constants.AddressLine1 + "", "" + Constants.AddressLine2
	|	END                                     AS UsBillLine1Line2,
	|	Constants.City                          AS UsBillCity,
	|	Constants.State.Code                    AS UsBillState,
	|	Constants.ZIP                           AS UsBillZIP,
	|	CASE
	|		WHEN Constants.City = """" THEN         // <Empty>
	|			""""
	|		ELSE                                    // City, State ZIP
	|			Constants.City + "", "" + Constants.State.Code + "" "" + Constants.ZIP
	|	END                                     AS UsBillCityStateZIP,
	|	Constants.Country                       AS UsBillCountry,
	|	Constants.Email                         AS UsBillEmail,
	|	Constants.Phone                         AS UsBillPhone,
	|	Constants.FirstName                     AS UsBillFirstName,
	|	Constants.MiddleName                    AS UsBillMiddleName,
	|	Constants.LastName                      AS UsBillLastName,
	|	Constants.Website                       AS UsWebsite
	// ------------------------------------------------------
	|FROM
	|	Constants AS Constants";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query returns biiling address data for document's company.
//
// Parameters:
//  TablesList - Structure - Contains temporary table names and it's count number.
//
// Returns:
//  String - The batch report section text.
//
Function Query_Company_Addresses_BillingAddress(TablesList) Export
	
	// Add address table to query structure.
	TablesList.Insert("Table_Company_Addresses_BillingAddress", TablesList.Count());
	
	// Collect company shiping address data.
	QueryText =
	"SELECT
	// ------------------------------------------------------
	// Attributes
	|	Document_Data.Ref                       AS Ref,
	|	Document_Data.Company.Code              AS ThemCode,
	|	Document_Data.Company.Description       AS ThemName,
	|	Addresses.AddressLine1                  AS ThemBillLine1,
	|	Addresses.AddressLine2                  AS ThemBillLine2,
	|	CASE
	|		WHEN Addresses.AddressLine2 = """" THEN // ThemBillLine1
	|			Addresses.AddressLine1
	|		ELSE                                    // ThemBillLine1, ThemBillLine2
	|			Addresses.AddressLine1 + "", "" + Addresses.AddressLine2
	|	END                                     AS ThemBillLine1Line2,
	|	Addresses.City                          AS ThemBillCity,
	|	Addresses.State.Code                    AS ThemBillState,
	|	Addresses.ZIP                           AS ThemBillZIP,
	|	CASE
	|		WHEN Addresses.City = """" THEN         // <Empty>
	|			""""
	|		ELSE                                    // City, State ZIP
	|			Addresses.City + "", "" + Addresses.State.Code + "" "" + Addresses.ZIP
	|	END                                     AS ThemBillCityStateZIP,
	|	Addresses.Country                       AS ThemBillCountry,
	|	Addresses.Email                         AS ThemBillEmail,
	|	Addresses.Phone                         AS ThemBillPhone,
	|	Addresses.Fax                           AS ThemBillFax,
	|	Addresses.FirstName                     AS ThemBillFirstName,
	|	Addresses.MiddleName                    AS ThemBillMiddleName,
	|	Addresses.LastName                      AS ThemBillLastName,
	|	Addresses.RemitTo                       AS ThemRemitTo
	// ------------------------------------------------------
	|FROM
	|	Table_Printing_Document_Data AS Document_Data
	|	LEFT JOIN Catalog.Addresses AS Addresses
	|		ON (Addresses.Owner = Document_Data.Company
	|		AND Addresses.DefaultBilling = True)";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query returns shipping address data for document's company.
//
// Parameters:
//  TablesList - Structure - Contains temporary table names and it's count number.
//
// Returns:
//  String - The batch report section text.
//
Function Query_Company_Addresses_ShipingAddress(TablesList) Export
	
	// Add address table to query structure.
	TablesList.Insert("Table_Company_Addresses_ShipingAddress", TablesList.Count());
	
	// Collect company shiping address data.
	QueryText =
	"SELECT
	// ------------------------------------------------------
	// Attributes
	|	Document_Data.Ref                       AS Ref,
	|	Document_Data.Company.Code              AS ThemCode,
	|	Document_Data.Company.Description       AS ThemName,
	|	Addresses.AddressLine1                  AS ThemShipLine1,
	|	Addresses.AddressLine2                  AS ThemShipLine2,
	|	CASE
	|		WHEN Addresses.AddressLine2 = """" THEN // ThemShipLine1
	|			Addresses.AddressLine1
	|		ELSE                                    // ThemShipLine1, ThemShipLine2
	|			Addresses.AddressLine1 + "", "" + Addresses.AddressLine2
	|	END                                     AS ThemShipLine1Line2,
	|	Addresses.City                          AS ThemShipCity,
	|	Addresses.State.Code                    AS ThemShipState,
	|	Addresses.ZIP                           AS ThemShipZIP,
	|	CASE
	|		WHEN Addresses.City = """" THEN         // <Empty>
	|			""""
	|		ELSE                                    // City, State ZIP
	|			Addresses.City + "", "" + Addresses.State.Code + "" "" + Addresses.ZIP
	|	END                                     AS ThemShipCityStateZIP,
	|	Addresses.Country                       AS ThemShipCountry,
	|	Addresses.Email                         AS ThemShipEmail,
	|	Addresses.Phone                         AS ThemShipPhone,
	|	Addresses.Fax                           AS ThemShipFax,
	|	Addresses.FirstName                     AS ThemShipFirstName,
	|	Addresses.MiddleName                    AS ThemShipMiddleName,
	|	Addresses.LastName                      AS ThemShipLastName
	// ------------------------------------------------------
	|FROM
	|	Table_Printing_Document_Data AS Document_Data
	|	LEFT JOIN Catalog.Addresses AS Addresses
	|		ON Addresses.Ref = Document_Data.ShipTo";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query returns logo picture data for document's company.
//
// Parameters:
//  TablesList - Structure - Contains temporary table names and it's count number.
//
// Returns:
//  String - The batch report section text.
//
Function Query_CustomPrintForms_Logo(TablesList) Export
	
	// Add custom print form table to query structure.
	TablesList.Insert("Table_CustomPrintForms_Logo", TablesList.Count());
	
	// Request logo data.
	QueryText =
	"SELECT
	// ------------------------------------------------------
	// Attributes
	|	CustomPrintForms.Template            AS Template
	// ------------------------------------------------------
	|FROM
	|	InformationRegister.CustomPrintForms AS CustomPrintForms
	|WHERE
	|	 CustomPrintForms.ObjectName   = ""logo""
	|AND CustomPrintForms.TemplateName = ""logo""";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query returns custom print form template (if defined) for document's company.
//
// Parameters:
//  TablesList - Structure - Contains temporary table names and it's count number.
//
// Returns:
//  String - The batch report section text.
//
Function Query_CustomPrintForms_Template(TablesList) Export
	
	// Add custom print form table to query structure.
	TablesList.Insert("Table_CustomPrintForms_Template", TablesList.Count());
	
	// Request document template.
	QueryText =
	"SELECT
	// ------------------------------------------------------
	// Dimensions
	|	CustomPrintForms.TemplateName        AS TemplateName,
	// ------------------------------------------------------
	// Attributes
	|	CustomPrintForms.Template            AS Template
	// ------------------------------------------------------
	|FROM
	|	InformationRegister.CustomPrintForms AS CustomPrintForms
	|WHERE
	|	 CustomPrintForms.ObjectName   = &ObjectName
	|AND CustomPrintForms.TemplateName IN(&TemplateName)";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

//------------------------------------------------------------------------------
// Extension of manager module - routine printing processes

// Defines the standard document template (customized or predefined)
// if special template name is not used.
//
// Parameters:
//  DocumentParameters - Structure          - Document parameters.
//    * Ref            - DocumentRef, Array - Ref to document to be printed,
//    * Metadata       - MetadataObject     - Metadata of printing document.
//    * TemplateName   - String             - Common predefined template name.
//  PrintingTables     - Structure          - Data query request result, Key - table name, Value - table contents.
//  TemplateName       - String             - An individual template name to be found (from the list of requested).
//                     - Undefined          - if not specified, then predefined template will be used.
//
// Returns:
//  SpreadsheetDocument - Document print template.
//  Undefined           - Document template is not found.
//
Function GetDocumentTemplate(DocumentParameters, PrintingTables, TemplateName = Undefined) Export
	
	// Define default template.
	Template = Undefined;
	
	// Get the custom template (from register).
	If PrintingTables.Table_CustomPrintForms_Template.Count() > 0 Then
		// Custom template defined.
		If TemplateName = Undefined Then
			Template = PrintingTables.Table_CustomPrintForms_Template[0].Template.Get();
		ElsIf TypeOf(TemplateName) = Type("String") Then
			FoundTemplate = PrintingTables.Table_CustomPrintForms_Template.Find(TemplateName,"TemplateName");
			If FoundTemplate <> Undefined Then
				Template = FoundTemplate.Template.Get();
			EndIf;
		EndIf;
		If TypeOf(Template) = Type("BinaryData") Then
			// Unpack template from binary storage.
			Template = BinaryDataToSpreadsheetDocument(Template);
		EndIf;
	EndIf;
	
	// Get the named template (from document object).
	If Template = Undefined Then
		// Define requested template name.
		RequestedTemplate = Undefined;
		If  TemplateName = Undefined
		And TypeOf(DocumentParameters.TemplateName) = Type("String") Then
			// Common template used.
			RequestedTemplate = DocumentParameters.TemplateName;
			
		ElsIf TypeOf(TemplateName) = Type("String") Then
			// Individual template specified.
			RequestedTemplate = TemplateName;
		EndIf;
		
		// Request the template with the specified name.
		If RequestedTemplate <> Undefined Then
			Try
				Template = Documents[DocumentParameters.Metadata.Name].GetTemplate(RequestedTemplate);
			Except
				// The template with specified name is not exist.
			EndTry;
		EndIf;
	EndIf;
	
	// Get the common standard template (from document object).
	If Template = Undefined And TemplateName = Undefined Then
		// Standard predefined tempalate will be used.
		Try
			// Get the template with the standard naming.
			Template = Documents[DocumentParameters.Metadata.Name].GetTemplate("PF_MXL_" + DocumentParameters.Metadata.Name);
		Except
			// Get the first possible template for a document.
			If DocumentParameters.Metadata.Templates.Count() > 0 Then
				Template = Documents[DocumentParameters.Metadata.Name].GetTemplate(DocumentParameters.Metadata.Templates[0].Name);
			EndIf;
		EndTry;
	EndIf;
	
	// Return the template.
	Return Template;
	
EndFunction

// Returns the name of individual template assigned to the selected document ref.
//
// Parameters:
//  DocumentsRef       - Array              - Collection of references to documents.
//                     - DocumentRef        - Single document ref.
//  CurrentDocumentRef - DocumentRef        - Reference to a current document, which template must be returned.
//  DocumentParameters - Structure          - Document parameters.
//    * Ref            - DocumentRef, Array - Ref to document to be printed,
//    * Metadata       - MetadataObject     - Metadata of printing document.
//    * TemplateName   - Array              - Array of corresponding templates to the documents refs.
//
// Returns:
//  String             - Name of individual print template.
//  Undefined          - Printing template is not defined.
//
Function GetIndividualTemplateName(DocumentsRef, CurrentDocumentRef, DocumentParameters) Export
	
	// Define name of individual template.
	IndividualTemplateName = Undefined;
	
	// Find index of template in templates array (according to the index of current document in documents array).
	If TypeOf(DocumentsRef) = Type("Array") Then
		TemplateIndex = DocumentsRef.Find(CurrentDocumentRef);
	Else
		TemplateIndex = 0; // Use first template.
	EndIf;
	
	// Search the name of template in templates array by the index.
	If TemplateIndex <= DocumentParameters.TemplateName.UBound() Then
		IndividualTemplateName = DocumentParameters.TemplateName[TemplateIndex];
	EndIf;
	
	// Return the template name.
	Return IndividualTemplateName;
	
EndFunction

// Defines the standard document logo (if defined)
//
// Parameters:
//  DocumentParameters - Structure          - Document parameters.
//  DocumentParameters - Structure          - Document parameters.
//    * Ref            - DocumentRef, Array - Ref to document to be printed,
//    * Metadata       - MetadataObject     - Metadata of printing document.
//    * TemplateName   - Array              - Array of corresponding templates to the documents refs.
//  PrintingTables     - Structure          - Data query request result, Key - table name, Value - table contents.
//
// Returns:
//  Picture            - Logo picture.
//  Undefined          - Logo is not defined.
//
Function GetDocumentLogo(DocumentParameters, PrintingTables) Export
	
	// Define default template.
	Logo = Undefined;
	
	// Find logo in requested printing tables.
	If PrintingTables.Table_CustomPrintForms_Logo.Count() > 0 Then
		// The logo exists.
		Logo = New Picture(PrintingTables.Table_CustomPrintForms_Logo[0].Template.Get());
	EndIf;
	
	// Return the logo.
	Return Logo;
	
EndFunction

// Fills standard logo area in document template.
//
// Parameters:
//  Template - SpreadsheetDocument - A template for output the logo.
//  Picture  - Picture             - A picture to place in logo drawing.
//
// Returns:
//  Boolean  - Flag shows whether template is filled with the logo.
//
Function FillLogoInDocumentTemplate(Template, Picture) Export
	
	// Call standard picture filling in "Logo" area.
	Return FillPictureInDocumentTemplate(Template, Picture, "Logo");
	
EndFunction

// Fills template drawing with picture.
//
// Parameters:
//  Template - SpreadsheetDocument - A template for output the picture.
//  Picture  - Picture             - A picture to place in a drawing.
//  AreaName - String              - Area name, where the picture must be placed.
//
// Returns:
//  Boolean  - Flag shows whether template is filled with the picture.
//
Function FillPictureInDocumentTemplate(Template, Picture, AreaName) Export
	
	// Define succession flag.
	PictureFilled = False;
	
	// Search drawing with specified name.
	If Picture <> Undefined Then
		For Each Drawing In Template.Drawings Do
			If Upper(Drawing.Name) = Upper(AreaName) Then
				
				// Passed drawing found.
				If Drawing.Picture.Type = PictureType.Empty Then
					// Output picture.
					Drawing.Picture = Picture;
				EndIf;
				PictureFilled = True;
				
				// Stop searching.
				Break;
			EndIf;
		EndDo;
	EndIf;
	
	Return PictureFilled;
	
EndFunction

// Fills template title.
//
// Parameters:
//  DocumentParameters - Structure          - Document parameters.
//    * Ref            - DocumentRef, Array - Ref to document to be printed,
//    * Metadata       - MetadataObject     - Metadata of printing document.
//    * TemplateName   - String             - Common predefined template name.
//
// Returns:
//  String             - Spreadsheet title.
//
Function GetDocumentTitle(DocumentParameters) Export
	
	// Define default title presentation.
	SheetTitle = "";
	
	// Define template title basing on documents presentation.
	If TypeOf(DocumentParameters.Ref) = Type("Array") Then
		DocumentsCount = DocumentParameters.Ref.Count();
		If DocumentsCount > 1 Then
			SheetTitle = DocumentParameters.Metadata.ListPresentation;
		ElsIf DocumentsCount = 1 Then
			SheetTitle = String(DocumentParameters.Ref[0]);
		EndIf;
	Else
		SheetTitle = String(DocumentParameters.Ref);
	EndIf;
	
	// Return created title.
	Return SheetTitle;
	
EndFunction

// Return the list of visible columns (conditional appearance is not considered) of a tabular section or value table
//
// Parameters:
//  ListOfColumns		- ValueList - this list gets populated 
//  ParentItem			- FormItem - Child items of this item should be columns or column groups
//  ExcludingColumns 	- Array - Contains table attribute names, which should be excluded from the columns list
//  DataPathPrefix		- String - Constant prefix part of a columns data path
//
Procedure GetVisibleColumns(ListOfColumns, ParentItem, ExcludingColumns, DataPathPrefix) Export
	
	For Each ChildItem In ParentItem.ChildItems Do
		If TypeOf(ChildItem) = Type("FormGroup") And ChildItem.Visible Then
			GetVisibleColumns(ListOfColumns, ChildItem, ExcludingColumns, DataPathPrefix);
		ElsIf ChildItem.Visible Then
			If Find(ChildItem.DataPath, DataPathPrefix) > 0 Then
				ColumnValue = StrReplace(ChildItem.DataPath, DataPathPrefix, "");
				If ExcludingColumns.Find(ColumnValue) <> Undefined Then
					Continue;
				EndIf;
				ListOfColumns.Add(ColumnValue, ChildItem.Title);
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

// Generates spreadsheet document and fills it with the tabular section data
//
// Parameters:
//  TabularSection 		- TabularSection, ValueTable - data source for the spreadsheet document
//  Filter				- Structure - containes filter parameters to be applied to TabularSection
//  ColumnsForOutput	- ValueList - the list of tabular section attributes to export
//  SelectedRows		- Array		- specifies row identifiers to export (Filter is ignored)
//  Caption				- String 	- specifies caption of the spreadsheet document
//  ReportParams		- Array of strings - specifies parameters, which are shown below caption on the spreadsheet document
//
Function ExportToSpreadsheetDocument(TabularSection, Filter, ColumnsForOutput, SelectedRows, Caption, ReportParams) Export
	
	ArrayOfRows = new Array();
	If SelectedRows.Count() > 0 Then
		For Each SelectedRow In SelectedRows Do
			ArrayOfRows.Add(TabularSection.FindByID(SelectedRow));
		EndDo;
	Else
		If Filter <> Undefined Then
			ArrayOfRows = TabularSection.FindRows(Filter);
		Else
			ArrayOfRows = TabularSection;
		EndIf;
	EndIf;

	Result 		= new SpreadsheetDocument();
	Template	= GetCommonTemplate("OutputList");
	CaptionArea		= Template.GetArea("Caption|Column");
	ParamsArea		= Template.GetArea("ReportParam|Column");
	HeaderArea 		= Template.GetArea("Heading|Column");
	TableRowArea 	= Template.GetArea("TableRow|Column");
	
	//Output caption
	CaptionArea.Parameters.Value = Caption;
	Result.Put(CaptionArea);
	
	//Output params
	For each Param In ReportParams Do
		ParamsArea.Parameters.Value = Param;
		Result.Put(ParamsArea);
	EndDo;
		
	ColumnWidthes = new Array();
	//Output table headings
	For i = 0 To ColumnsForOutput.Count()-1 Do
		Column = ColumnsForOutput[i];
		HeaderArea.Parameters.Value = ?(ValueIsFilled(Column.Presentation), Column.Presentation, Column.Value);
		ColumnWidthes.Add(StrLen(HeaderArea.Parameters.Value));
		
		If i = 0 Then
			Result.Put(HeaderArea);
		Else
			Result.Join(HeaderArea);
		EndIf;
	EndDo;
	//Output table rows
	For Each Row In ArrayOfRows Do
		For i = 0 To ColumnsForOutput.Count()-1 Do
			Column = ColumnsForOutput[i];
			TableRowArea.Parameters.Value = Row[Column.Value];
			
			CurWidth = StrLen(TableRowArea.Parameters.Value);
			If ColumnWidthes[i] < CurWidth Then
				ColumnWidthes[i] = CurWidth;
			EndIf;

			If i = 0 Then
				Result.Put(TableRowArea);
			Else
				Result.Join(TableRowArea);
			EndIf;
		EndDo;
	EndDo;
	
	//Adjust column width
	For i = 0 To ColumnsForOutput.Count()-1 Do
		Area = Result.Area(1, i + 1);
		Area.ColumnWidth = ?(ColumnWidthes[i] > 10, ColumnWidthes[i] * 1.1, ColumnWidthes[i] * 1.3);
	EndDo;
	
	//Merge caption cells
	Area = Result.Area(1, 1, 1, ColumnsForOutput.Count());
	Area.Merge();
	Area.HorizontalAlign = HorizontalAlign.Center;
	//Merge params cells
	For i = 0 To ReportParams.Count() - 1 Do
		Area = Result.Area(i + 2, 1, i + 2, ColumnsForOutput.Count());
		Area.Merge();
		Area.HorizontalAlign = HorizontalAlign.Left;
	EndDo;
	
	return Result;
	
EndFunction

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region PRIVATE_IMPLEMENTATION

// Unpack the spreadsheet template from binary data
// 
// Parameters:
//  BinaryData - BinaryData - Packed binary template.
//
// Returns:
//  SpreadsheetDocument - Spreadsheet document template.
//
Function BinaryDataToSpreadsheetDocument(BinaryData)
	
	// Request new temporary file.
	TempFileName = GetTempFileName();
	
	// Save binary object to the local file.
	BinaryData.Write(TempFileName);
	
	// Read the spreadsheet document back from file.
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.Read(TempFileName);
	
	// Delete used file.
	SafeDeleteFile(TempFileName);
	
	// Return the restored spreadsheet template.
	Return SpreadsheetDocument;
	
EndFunction

// Performs deletion of passed file without the exception if delete fails.
//
// Parameters:
//  FileName - String - File name to be deleted.
//
// Returns:
//  Boolean  - Succession flag.
//
Function SafeDeleteFile(FileName)
	
	// Delete passed file name ignore possible exception.
	Try
		DeleteFiles(FileName);
	Except
		// File deletion failed.
		Return False;
	EndTry;
	
	// File successfully deleted.
	Return True;
EndFunction

#EndRegion
