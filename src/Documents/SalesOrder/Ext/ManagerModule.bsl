Procedure Print(ObjectArray, PrintParameters, PrintFormsCollection,
           PrintObjects, OutputParameters) Export

     // Setting the kit printing option.
     OutputParameters.KitPrintingEnabled = True;

     // Checking if a spreadsheet document generation needed for the Sales Order template.
    If PrintManagement.SpreadsheetDocumentPrintRequested(PrintFormsCollection, "SalesOrder") Then

         // Generating a spreadsheet document and adding it into the print form collection.
         PrintManagement.OutputSpreadsheetDocumentIntoCollection(PrintFormsCollection,
             "SalesOrder", "Sales order", PrintTemplate(ObjectArray, PrintObjects, "UMOff"));

	EndIf;
		 
	If PrintManagement.SpreadsheetDocumentPrintRequested(PrintFormsCollection, "SalesOrderUM") Then

         // Checking if a spreadsheet document generation needed for the Sales Order U/M template.
         PrintManagement.OutputSpreadsheetDocumentIntoCollection(PrintFormsCollection,
             "SalesOrderUM", "Sales order", PrintTemplate(ObjectArray, PrintObjects, "UMOn"));

	EndIf;

		 
EndProcedure
	 
Function PrintTemplate(ObjectArray, PrintObjects, UMMode)
	
	// Create a spreadsheet document and set print parameters.
   SpreadsheetDocument = New SpreadsheetDocument;
   SpreadsheetDocument.PrintParametersName = "PrintParameters_SalesOrder";

   // Quering necessary data.
   Query = New Query();
   Query.Text =
   "SELECT
   |	SalesOrder.Ref,
   |	SalesOrder.Company,
   |	SalesOrder.Date,
   |	SalesOrder.DocumentTotal,
   |	SalesOrder.SalesTax,
   |	SalesOrder.Number,
   |	SalesOrder.Currency,
   |	SalesOrder.VATTotal,
   |	SalesOrder.LineItems.(
   |		Product,
   |		Descr,
   |		Quantity,
   |		UM,
   |		QuantityUM,
   |		VATCode,
   |		VAT,
   |		Price,
   |		LineTotal
   |	)
   |FROM
   |	Document.SalesOrder AS SalesOrder
   |WHERE
   |	SalesOrder.Ref IN(&ObjectArray)";
   Query.SetParameter("ObjectArray", ObjectArray);
   Selection = Query.Execute().Choose();
  
   	FirstDocument = True;

	OurCompany = Catalogs.Companies.OurCompany;
   
   	While Selection.Next() Do
		
		If Not FirstDocument Then
			// All documents need to be outputted on separate pages.
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		FirstDocument = False;
		// Remember current document output beginning line number.
		BeginningLineNumber = SpreadsheetDocument.TableHeight + 1;

	 
	If UMMode = "UMOff" Then
	 	Template = PrintManagement.GetTemplate("Document.SalesOrder.PF_MXL_SalesOrder");
	Else
		Template = PrintManagement.GetTemplate("Document.SalesOrder.PF_MXL_SalesOrderUM");
	EndIf;
	 
	 TemplateArea = Template.GetArea("Header");
	 
	OurCompanyInfo = PrintTemplates.ContactInfo(OurCompany, "OurCompany");
	CounterpartyInfo = PrintTemplates.ContactInfo(Selection.Company, "Counterparty");
	
	TemplateArea.Parameters.Fill(OurCompanyInfo);
	TemplateArea.Parameters.Fill(CounterpartyInfo);

	 
	 TemplateArea.Parameters.Date = Selection.Date;
	 TemplateArea.Parameters.Number = Selection.Number;
	 
	 SpreadsheetDocument.Put(TemplateArea);

	 TemplateArea = Template.GetArea("LineItemsHeader");
	 SpreadsheetDocument.Put(TemplateArea);
	 
	 SelectionLineItems = Selection.LineItems.Choose();
	 TemplateArea = Template.GetArea("LineItems");
	 LineTotalSum = 0;
	 While SelectionLineItems.Next() Do
		 
		 TemplateArea.Parameters.Fill(SelectionLineItems);
		 LineTotal = SelectionLineItems.LineTotal;
		 LineTotalSum = LineTotalSum + LineTotal;
		 SpreadsheetDocument.Put(TemplateArea, SelectionLineItems.Level());
		 
	 EndDo;
	 
	Try 
		TemplateArea = Template.GetArea("ExtraLines");
		SpreadsheetDocument.Put(TemplateArea);
	Except
	EndTry; 
	 
	If Selection.VATTotal <> 0 Then;
		 TemplateArea = Template.GetArea("Subtotal");
		 TemplateArea.Parameters.Subtotal = LineTotalSum;
		 SpreadsheetDocument.Put(TemplateArea);
		 
		 TemplateArea = Template.GetArea("VAT");
		 TemplateArea.Parameters.VATTotal = Selection.VATTotal;
		 SpreadsheetDocument.Put(TemplateArea);
	EndIf; 
		 
	 TemplateArea = Template.GetArea("Total");
	 TemplateArea.Parameters.DocumentTotal = LineTotalSum + Selection.VATTotal;
	 SpreadsheetDocument.Put(TemplateArea);

	 TemplateArea = Template.GetArea("Currency");
	 TemplateArea.Parameters.Currency = Selection.Currency;
	 SpreadsheetDocument.Put(TemplateArea);

	 
     // Setting a print area in the spreadsheet document where to output the object.
     // Necessary for kit printing. 
     PrintManagement.SetPrintArea(SpreadsheetDocument, BeginningLineNumber, PrintObjects, Selection.Ref);

   EndDo;
   
   Return SpreadsheetDocument;
   
EndFunction