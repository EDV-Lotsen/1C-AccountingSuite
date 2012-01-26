
Procedure Print(ObjectArray, PrintParameters, PrintFormsCollection,
           PrintObjects, OutputParameters) Export

     // Setting the kit printing option.
     OutputParameters.KitPrintingEnabled = True;

     // Checking if a spreadsheet document generation needed for the Purchase Invoice template.
    If PrintManagement.SpreadsheetDocumentPrintRequested(PrintFormsCollection, "PurchaseInvoice") Then

         // Generating a spreadsheet document and adding it into the print form collection.
         PrintManagement.OutputSpreadsheetDocumentIntoCollection(PrintFormsCollection,
             "PurchaseInvoice", "Purchase invoice", PrintTemplate(ObjectArray, PrintObjects, "UMOff"));

	EndIf;
		 
	If PrintManagement.SpreadsheetDocumentPrintRequested(PrintFormsCollection, "PurchaseInvoiceUM") Then

         // Checking if a spreadsheet document generation needed for the Purchase Invoice U/M template.
         PrintManagement.OutputSpreadsheetDocumentIntoCollection(PrintFormsCollection,
             "PurchaseInvoiceUM", "Purchase invoice", PrintTemplate(ObjectArray, PrintObjects, "UMOn"));

	EndIf;

		 
EndProcedure
	 
Function PrintTemplate(ObjectArray, PrintObjects, UMMode)
	
	// Create a spreadsheet document and set print parameters.
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.PrintParametersName = "PrintParameters_PurchaseInvoice";

	// Quering necessary data.
	Query = New Query();
	Query.Text =
	"SELECT
	|	PurchaseInvoice.Ref,
	|	PurchaseInvoice.Company,
	|	PurchaseInvoice.Date,
	|	PurchaseInvoice.DocumentTotal,
	|	PurchaseInvoice.Number,
	|	PurchaseInvoice.Currency,
	|	PurchaseInvoice.VATTotal,
	|	PurchaseInvoice.LineItems.(
	|		Product,
	|		Descr,
	|		Quantity,
	|		UM,
	|		QuantityUM,
	|		Price,
	|		VATCode,
	|		VAT,
	|		LineTotal
	|	)
	|FROM
	|	Document.PurchaseInvoice AS PurchaseInvoice
	|WHERE
	|	PurchaseInvoice.Ref IN(&ObjectArray)";
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
	 	Template = PrintManagement.GetTemplate("Document.PurchaseInvoice.PF_MXL_PurchaseInvoice");
	Else
		Template = PrintManagement.GetTemplate("Document.PurchaseInvoice.PF_MXL_PurchaseInvoiceUM");
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