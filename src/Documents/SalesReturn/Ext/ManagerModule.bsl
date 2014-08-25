
////////////////////////////////////////////////////////////////////////////////
// Sales return: Manager module
//------------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
#Region PUBLIC_INTERFACE

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

//------------------------------------------------------------------------------
// Document posting

// Pre-check, lock, calculate data before write document.
Function PrepareDataBeforeWrite(AdditionalProperties, DocumentParameters, Cancel) Export
	
	// 0.1. Access data without rights checking.
	SetPrivilegedMode(True);
	
	// 0.2. Create list of query tables (according to the list of requested balances).
	PreCheck     = New Structure;
	LocksList    = New Structure;
	BalancesList = New Structure;
	
	// 0.3. Set optional accounting flags.
	InventoryPosting = True; // Post always.
	
	
	// 1.1. Create a query to request data.
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	
	// 1.2. Put supplied DocumentParameters in query parameters and temporary tables.
	For Each Parameter In DocumentParameters Do
		If TypeOf(Parameter.Value) = Type("ValueTable") Then
			DocumentPosting.PutTemporaryTable(Parameter.Value, "Table_"+Parameter.Key, Query.TempTablesManager);
		ElsIf TypeOf(Parameter.Value) = Type("PointInTime") Then
			Query.SetParameter(Parameter.Key, New Boundary(Parameter.Value, BoundaryType.Excluding));
		Else
			Query.SetParameter(Parameter.Key, Parameter.Value);
		EndIf;
	EndDo;
	
	
	// 2.1. Request data for lock in registers before accessing balances.
	Query.Text = "";
	If InventoryPosting Then
		Query.Text = Query.Text +
		             Query_InventoryJournal_Lock(LocksList) +
		             Query_ItemLastCosts_Lock(LocksList);
	EndIf;
	
	// 2.2. Proceed with locking the data.
	If Not IsBlankString(Query.Text) Then
		QueryResult = Query.ExecuteBatch();
		For Each LockTable In LocksList Do
			DocumentPosting.LockDataSourceBeforeWrite(StrReplace(LockTable.Key, "_", "."), QueryResult[LockTable.Value], DataLockMode.Exclusive);
		EndDo;
	EndIf;
	
	
	// 3.1. Query for register balances excluding document data (if it already affected to).
	Query.Text = "";
	If InventoryPosting Then
		Query.Text = Query.Text +
		             Query_InventoryJournal_Balance(BalancesList) +
		             Query_ItemLastCosts_SliceLast(BalancesList);
		
		// Reuse locked inventory items & items last costs list.
		DocumentPosting.PutTemporaryTable(QueryResult[LocksList.AccumulationRegister_InventoryJournal].Unload(),
		                                  "Table_InventoryJournal_Lock", Query.TempTablesManager);
		DocumentPosting.PutTemporaryTable(QueryResult[LocksList.InformationRegister_ItemLastCosts].Unload(),
		                                  "Table_ItemLastCosts_Lock", Query.TempTablesManager);
	EndIf;
	
	// 3.2. Save balances in posting parameters.
	If Not IsBlankString(Query.Text) Then
		QueryResult = Query.ExecuteBatch();
		For Each BalanceTable In BalancesList Do
			PreCheck.Insert(BalanceTable.Key, QueryResult[BalanceTable.Value].Unload());
		EndDo;
		Query.TempTablesManager.Close();
	EndIf;
	
	// 3.3. Put structure of prechecked registers in additional properties.
	If PreCheck.Count() > 0 Then
		AdditionalProperties.Posting.Insert("PreCheck", PreCheck);
	EndIf;
	
EndFunction

// Collect document data for posting on the server (in terms of document).
Function PrepareDataStructuresForPosting(DocumentRef, AdditionalProperties, RegisterRecords) Export
	Var PreCheck;
	
	//------------------------------------------------------------------------------
	// 1. Prepare structures for querying data.
	
	// Set optional accounting flags.
	InventoryPosting = True; // Post always.
	SalesTaxPosting  = GeneralFunctionsReusable.FunctionalOptionValue("SalesTaxCharging");
	
	// Create list of posting tables (according to the list of registers).
	TablesList = New Structure;
	
	// Create a query to request document data.
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	
	//------------------------------------------------------------------------------
	// 2. Prepare query text.
	
	// Query for document's tables.
	Query.Text   = "";
	If InventoryPosting Then
		Query.Text = Query.Text +
		             Query_InventoryJournal_LineItems(TablesList) +
		             Query_InventoryJournal_Balance_Quantity(TablesList) +
		             Query_InventoryJournal(TablesList);
	EndIf;
	If SalesTaxPosting Then
		Query.Text = Query.Text +
		             Query_SalesTaxOwed(TablesList);
	EndIf;
	
	//------------------------------------------------------------------------------
	// 3. Execute query and fill data structures.
	
	// Execute query, fill temporary tables with postings data.
	If Not IsBlankString(Query.Text) Then
		// Fill data from precheck.
		If AdditionalProperties.Posting.Property("PreCheck", PreCheck) And PreCheck.Count() > 0 Then
			For Each PreCheckTable In PreCheck Do
				DocumentPosting.PutTemporaryTable(PreCheckTable.Value, PreCheckTable.Key, Query.TempTablesManager);
			EndDo;
		EndIf;
		
		// Execute query.
		QueryResult = Query.ExecuteBatch();
		
		// Save documents table in posting parameters.
		For Each DocumentTable In TablesList Do
			ResultTable = QueryResult[DocumentTable.Value].Unload();
			If Not DocumentPosting.IsTemporaryTable(ResultTable) Then
				AdditionalProperties.Posting.PostingTables.Insert(DocumentTable.Key, ResultTable);
			EndIf;
		EndDo;
	EndIf;
	
	//------------------------------------------------------------------------------
	// 4. Final check of posting data correctness (i.e. negative balances and s.o.).
	
	// Clear used temporary tables manager.
	Query.TempTablesManager.Close();
	
	// Fill list of registers to check (non-negative) balances in posting parameters.
	FillRegistersCheckList(AdditionalProperties, RegisterRecords);
	
EndFunction

// Collect document data for posting on the server (in terms of document).
Function PrepareDataStructuresForPostingClearing(DocumentRef, AdditionalProperties, RegisterRecords) Export
	
	// Fill list of registers to check (non-negative) balances in posting parameters.
	FillRegistersCheckList(AdditionalProperties, RegisterRecords);
	
EndFunction

//------------------------------------------------------------------------------
// Document fill check processing

//------------------------------------------------------------------------------
// Document filling

//------------------------------------------------------------------------------
// Document printing

#EndIf

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region COMMANDS_HANDLERS

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

//------------------------------------------------------------------------------
// Document printing

// -> CODE REVIEW
Procedure Print(Spreadsheet, SheetTitle, Ref, TemplateName = Undefined) Export
	SheetTitle = "Credit Memo";
    CustomTemplate = GeneralFunctions.GetCustomTemplate("Document.CreditMemo", SheetTitle);
    
    If CustomTemplate = Undefined Then
    	Template = Documents.SalesReturn.GetTemplate("New_CreditMemo_Form2");
    Else
    	Template = CustomTemplate;
    EndIf;
 
   // Quering necessary data.
   Query = New Query();
   Query.Text =
   "SELECT
   |	SalesReturn.Ref,
   |	SalesReturn.DataVersion,
   |	SalesReturn.DeletionMark,
   |	SalesReturn.Number,
   |	SalesReturn.Date,
   |	SalesReturn.Posted,
   |	SalesReturn.Company,
   |	SalesReturn.ReturnType,
   |	SalesReturn.SalesTaxRC,
   |	SalesReturn.DocumentTotal,
   |	SalesReturn.ParentDocument,
   |	SalesReturn.Currency,
   |	SalesReturn.ExchangeRate,
   |	SalesReturn.DocumentTotalRC,
   |	SalesReturn.Location,
   |	SalesReturn.DueDate,
   |	SalesReturn.Memo,
   |	SalesReturn.ARAccount,
   |	SalesReturn.RefNum,
   |	SalesReturn.EmailTo,
   |	SalesReturn.EmailNote,
   |	SalesReturn.EmailCC,
   |	SalesReturn.LastEmail,
   |	SalesReturn.LineSubtotal,
   |	SalesReturn.Subtotal,
   |	SalesReturn.ManualAdjustment,
   |	SalesReturn.SalesTaxRate,
   |	SalesReturn.DiscountIsTaxable,
   |	SalesReturn.TaxableSubtotal,
   |	SalesReturn.DiscountPercent,
   |	SalesReturn.Discount,
   |	SalesReturn.Shipping,
   |	SalesReturn.LineItems.(
   |		Ref,
   |		LineNumber,
   |		Product,
   |		ProductDescription,
   |		UnitSet,
   |		QtyUnits,
   |		Unit,
   |		QtyUM,
   |		PriceUnits,
   |		LineTotal,
   |		Taxable
   |	),
   |	SalesReturn.SalesTaxAcrossAgencies.(
   |		Ref,
   |		LineNumber,
   |		Agency,
   |		Rate,
   |		Amount,
   |		SalesTaxRate,
   |		SalesTaxComponent
   |	)
   |FROM
   |	Document.SalesReturn AS SalesReturn
   |WHERE
   |	SalesReturn.Ref IN(&Ref)";
   Query.SetParameter("Ref", Ref);
   Selection = Query.Execute().Select();
   
   Spreadsheet.Clear();

   While Selection.Next() Do
  	 
    BinaryLogo = GeneralFunctions.GetLogo();
    LogoPicture = New Picture(BinaryLogo);
    DocumentPrinting.FillLogoInDocumentTemplate(Template, LogoPicture); 
    
    Try
    	FooterLogo = GeneralFunctions.GetFooterPO("CMfooter1");
    	Footer1Pic = New Picture(FooterLogo);
    	FooterLogo2 = GeneralFunctions.GetFooterPO("CMfooter2");
    	Footer2Pic = New Picture(FooterLogo2);
    	FooterLogo3 = GeneralFunctions.GetFooterPO("CMfooter3");
    	Footer3Pic = New Picture(FooterLogo3);
    Except
    EndTry;
   
   QueryAddr = New Query();
   QueryAddr.Text =
   "SELECT
   |	Addresses.Ref,
   |	Addresses.DataVersion,
   |	Addresses.DeletionMark,
   |	Addresses.Owner,
   |	Addresses.Code,
   |	Addresses.Description,
   |	Addresses.FirstName,
   |	Addresses.MiddleName,
   |	Addresses.LastName,
   |	Addresses.Phone,
   |	Addresses.Cell,
   |	Addresses.Fax,
   |	Addresses.Email,
   |	Addresses.AddressLine1,
   |	Addresses.AddressLine2,
   |	Addresses.AddressLine3,
   |	Addresses.City,
   |	Addresses.State,
   |	Addresses.Country,
   |	Addresses.ZIP,
   |	Addresses.DefaultBilling,
   |	Addresses.DefaultShipping,
   |	Addresses.RemitTo,
   |	Addresses.Notes,
   |	Addresses.Salutation,
   |	Addresses.Suffix,
   |	Addresses.CF1String,
   |	Addresses.CF2String,
   |	Addresses.CF3String,
   |	Addresses.CF4String,
   |	Addresses.CF5String,
   |	Addresses.JobTitle,
   |	Addresses.SalesPerson,
   |	Addresses.Predefined,
   |	Addresses.PredefinedDataName
   |FROM
   |	Catalog.Addresses AS Addresses
   |WHERE
   |	Addresses.Owner = &Owner
   |	AND Addresses.DefaultBilling = &DefaultBilling";
   QueryAddr.SetParameter("Owner", Selection.Company);
   QueryAddr.SetParameter("DefaultBilling", True);
   SelectionAddr = QueryAddr.Execute().Unload();

   
   
    TemplateArea = Template.GetArea("Header");
  			
    UsBill = PrintTemplates.ContactInfoDatasetUs();
    
    ThemBill = PrintTemplates.ContactInfoDataset(Selection.Company, "ThemBill", SelectionAddr[0].Ref);
    
    TemplateArea.Parameters.Fill(UsBill);
    TemplateArea.Parameters.Fill(ThemBill);
    		
		
	If Constants.CMShowFullName.Get() = True Then
		TemplateArea.Parameters.ThemFullName = ThemBill.ThemBillSalutation + " " + ThemBill.ThemBillFirstName + " " + ThemBill.ThemBillLastName;
	EndIf;
	    
    TemplateArea.Parameters.Date = Selection.Date;
    TemplateArea.Parameters.Number = Selection.Number;
	TemplateArea.Parameters.RefNum = Selection.RefNum;
	
	//UsBill filling
    If TemplateArea.Parameters.UsBillLine1 <> "" Then
    	TemplateArea.Parameters.UsBillLine1 = TemplateArea.Parameters.UsBillLine1 + Chars.LF; 
    EndIf;

    If TemplateArea.Parameters.UsBillLine2 <> "" Then
    	TemplateArea.Parameters.UsBillLine2 = TemplateArea.Parameters.UsBillLine2 + Chars.LF; 
    EndIf;
    
    If TemplateArea.Parameters.UsBillCityStateZIP <> "" Then
    	TemplateArea.Parameters.UsBillCityStateZIP = TemplateArea.Parameters.UsBillCityStateZIP + Chars.LF; 
    EndIf;
    
    If TemplateArea.Parameters.UsBillPhone <> "" Then
    	TemplateArea.Parameters.UsBillPhone = TemplateArea.Parameters.UsBillPhone + Chars.LF; 
    EndIf;
    
    If TemplateArea.Parameters.UsBillEmail <> "" AND Constants.CMShowEmail.Get() = False Then
    	TemplateArea.Parameters.UsBillEmail = ""; 
    EndIf;


    	
    
   // ThemBill filling
	If TemplateArea.Parameters.ThemBillLine1 <> "" Then
		TemplateArea.Parameters.ThemBillLine1 = TemplateArea.Parameters.ThemBillLine1 + Chars.LF; 
	EndIf;

	If TemplateArea.Parameters.ThemBillLine2 <> "" Then
		TemplateArea.Parameters.ThemBillLine2 = TemplateArea.Parameters.ThemBillLine2 + Chars.LF; 
	EndIf;
	
	If TemplateArea.Parameters.ThemBillLine3 <> "" Then
		TemplateArea.Parameters.ThemBillLine3 = TemplateArea.Parameters.ThemBillLine3 + Chars.LF; 
	EndIf;
	
         
     Spreadsheet.Put(TemplateArea);	
	 
	 	 
    If Constants.CMShowPhone2.Get() = False Then
    	Direction = SpreadsheetDocumentShiftType.Vertical;
    	Area = Spreadsheet.Area("MobileArea");
    	Spreadsheet.DeleteArea(Area, Direction);
    	Spreadsheet.InsertArea(Spreadsheet.Area("R10"), Spreadsheet.Area("R10"), 
  	  SpreadsheetDocumentShiftType.Vertical);
    EndIf;
    
    If Constants.CMShowWebsite.Get() = False Then
    	Direction = SpreadsheetDocumentShiftType.Vertical;
    	Area = Spreadsheet.Area("WebsiteArea");
    	Spreadsheet.DeleteArea(Area, Direction);
    	Spreadsheet.InsertArea(Spreadsheet.Area("R10"), Spreadsheet.Area("R10"), 
    	SpreadsheetDocumentShiftType.Vertical);

    EndIf;
    
    If Constants.CMShowFax.Get() = False Then
    	Direction = SpreadsheetDocumentShiftType.Vertical;
    	Area = Spreadsheet.Area("FaxArea");
    	Spreadsheet.DeleteArea(Area, Direction);
    	Spreadsheet.InsertArea(Spreadsheet.Area("R10"), Spreadsheet.Area("R10"), 
    	SpreadsheetDocumentShiftType.Vertical);

    EndIf;
    
    If Constants.CMShowFedTax.Get() = False Then
    	Direction = SpreadsheetDocumentShiftType.Vertical;
    	Area = Spreadsheet.Area("FedTaxArea");
    	Spreadsheet.DeleteArea(Area, Direction);
    	Spreadsheet.InsertArea(Spreadsheet.Area("R10"), Spreadsheet.Area("R10"), 
    	SpreadsheetDocumentShiftType.Vertical);

    EndIf;
    	
	SelectionLineItems = Selection.LineItems.Select();
	TemplateArea = Template.GetArea("LineItems");
	LineTotalSum = 0;
	LineItemSwitch = False;
	//QuantityFormat = GeneralFunctionsReusable.DefaultQuantityFormat();
	While SelectionLineItems.Next() Do
				 
		TemplateArea.Parameters.Fill(SelectionLineItems);
		CompanyName = Selection.Company.Description;
		CompanyNameLen = StrLen(CompanyName);
		Try
			 If NOT SelectionLineItems.Project = "" Then
				ProjectLen = StrLen(SelectionLineItems.Project);
			 	TemplateArea.Parameters.Project = Right(SelectionLineItems.Project, ProjectLen - CompanyNameLen - 2);
			EndIf;
		Except
		EndTry;
		LineTotal = SelectionLineItems.LineTotal;
		TemplateArea.Parameters.Quantity = Format(SelectionLineItems.QtyUnits);
		TemplateArea.Parameters.Price = Selection.Currency.Symbol + Format(SelectionLineItems.PriceUnits, "NFD=2; NZ=");
		TemplateArea.Parameters.UM = SelectionLineItems.Unit.Code;
		TemplateArea.Parameters.LineTotal = Selection.Currency.Symbol + Format(SelectionLineItems.LineTotal, "NFD=2; NZ=");
		Spreadsheet.Put(TemplateArea, SelectionLineItems.Level());
				
		If LineItemSwitch = False Then
			TemplateArea = Template.GetArea("LineItems2");
			LineItemSwitch = True;
		Else
			TemplateArea = Template.GetArea("LineItems");
			LineItemSwitch = False;
		EndIf;
		 
	 EndDo;
    
    TemplateArea = Template.GetArea("EmptySpace");
    Spreadsheet.Put(TemplateArea);

     
    TemplateArea = Template.GetArea("Area3|Area1");					
    TemplateArea.Parameters.TermAndCond = Selection.EmailNote;
    Spreadsheet.Put(TemplateArea);
     
    TemplateArea = Template.GetArea("Area3|Area2");
	TemplateArea.Parameters.LineSubtotal = Selection.Currency.Symbol + Format(Selection.LineSubtotal, "NFD=2; NZ=");
	TemplateArea.Parameters.Discount = "("+ Selection.Currency.Symbol + Format(Selection.Discount, "NFD=2; NZ=") + ")";
	TemplateArea.Parameters.Subtotal = Selection.Currency.Symbol + Format(Selection.Subtotal, "NFD=2; NZ=");
	TemplateArea.Parameters.Shipping = Selection.Currency.Symbol + Format(Selection.Shipping, "NFD=2; NZ=");
	TemplateArea.Parameters.SalesTax = Selection.Currency.Symbol + Format(Selection.SalesTaxRC, "NFD=2; NZ=");
	TemplateArea.Parameters.Total = Selection.Currency.Symbol + Format(Selection.DocumentTotal, "NFD=2; NZ=");

	Spreadsheet.Join(TemplateArea);
    
    TemplateArea = Template.GetArea("EmptyRow");
    Spreadsheet.Put(TemplateArea);
    
    	
    Row = Template.GetArea("EmptyRow");
    Footer = Template.GetArea("FooterField");
    Compensator = Template.GetArea("Compensator");
    RowsToCheck = New Array();
    RowsToCheck.Add(Row);
    RowsToCheck.Add(Footer);
    
    
    While Spreadsheet.CheckPut(RowsToCheck) = False Do
    	 Spreadsheet.Put(Row);
  	 	 RowsToCheck.Clear();
  		 RowsToCheck.Add(Footer);
    	 RowsToCheck.Add(Row);
    EndDo;
     
    While Spreadsheet.CheckPut(RowsToCheck) Do
    	 Spreadsheet.Put(Row);
  	 	 RowsToCheck.Clear();
  		 RowsToCheck.Add(Footer);
    	 RowsToCheck.Add(Row);
	 EndDo;
	 
	 TemplateArea = Template.GetArea("DividerArea");
	Spreadsheet.Put(TemplateArea);
    
	If Constants.CMFoot1Type.Get()= Enums.TextOrImage.Image Then	
			DocumentPrinting.FillPictureInDocumentTemplate(Template, Footer1Pic, "CMfooter1");
			TemplateArea = Template.GetArea("FooterField|FooterSection1");	
			Spreadsheet.Put(TemplateArea);
	Elsif Constants.CMFoot1Type.Get() = Enums.TextOrImage.Text Then
			TemplateArea = Template.GetArea("TextField|FooterSection1");
			TemplateArea.Parameters.CMFooterTextLeft = Constants.CMFooterTextLeft.Get();
			Spreadsheet.Put(TemplateArea);
	EndIf;
		
	If Constants.CMFoot2Type.Get()= Enums.TextOrImage.Image Then
			DocumentPrinting.FillPictureInDocumentTemplate(Template, Footer2Pic, "CMfooter2");
			TemplateArea = Template.GetArea("FooterField|FooterSection2");	
			Spreadsheet.Join(TemplateArea);		
	Elsif Constants.CMFoot2Type.Get() = Enums.TextOrImage.Text Then
			TemplateArea = Template.GetArea("TextField|FooterSection2");
			TemplateArea.Parameters.CMFooterTextCenter = Constants.CMFooterTextCenter.Get();
			Spreadsheet.Join(TemplateArea);
	EndIf;
		
	If Constants.CMFoot3Type.Get()= Enums.TextOrImage.Image Then
			DocumentPrinting.FillPictureInDocumentTemplate(Template, Footer3Pic, "CMfooter3");
			TemplateArea = Template.GetArea("FooterField|FooterSection3");	
			Spreadsheet.Join(TemplateArea);
	Elsif Constants.CMFoot3Type.Get() = Enums.TextOrImage.Text Then
			TemplateArea = Template.GetArea("TextField|FooterSection3");
			TemplateArea.Parameters.CMFooterTextRight = Constants.CMFooterTextRight.Get();
			Spreadsheet.Join(TemplateArea);
	EndIf;         
    
    	 
    Spreadsheet.PutHorizontalPageBreak(); //.ВывестиГоризонтальныйРазделительСтраниц();
    Spreadsheet.FitToPage  = True;

     
   EndDo;
	   
EndProcedure
// <- CODE REVIEW

#EndIf

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region PRIVATE_IMPLEMENTATION

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

//------------------------------------------------------------------------------
// Document posting

// Query for document data.
Function Query_InventoryJournal_LineItems(TablesList)
	
	// Add InventoryJournal - requested items table to document structure.
	TablesList.Insert("Table_InventoryJournal_LineItems", TablesList.Count());
	
	// Collect inventory data.
	QueryText =
	"SELECT // FIFO
	// ------------------------------------------------------
	// Dimensions
	|	LineItems.Product.CostingMethod          AS Type,
	|	LineItems.Product                        AS Product,
	|	LineItems.Ref.Location                   AS Location,
	// ------------------------------------------------------
	// Agregates
	|	SUM(LineItems.QtyUM)                     AS QuantityRequested
	// ------------------------------------------------------
	|INTO
	|	Table_InventoryJournal_LineItems
	|FROM
	|	Document.SalesReturn.LineItems           AS LineItems
	|WHERE
	|	    LineItems.Ref                   = &Ref
	|	AND LineItems.Product.Type          = VALUE(Enum.InventoryTypes.Inventory)
	|	AND LineItems.Product.CostingMethod = VALUE(Enum.InventoryCosting.FIFO)
	|GROUP BY
	|	LineItems.Product.CostingMethod,
	|	LineItems.Product,
	|	LineItems.Ref.Location
	|
	|UNION ALL
	|
	|SELECT // WAve for quantity calcualtion
	// ------------------------------------------------------
	// Dimensions
	|	LineItems.Product.CostingMethod          AS Type,
	|	LineItems.Product                        AS Product,
	|	LineItems.Ref.Location                   AS Location,
	// ------------------------------------------------------
	// Agregates
	|	SUM(LineItems.QtyUM)                     AS QuantityRequested
	// ------------------------------------------------------
	|FROM
	|	Document.SalesReturn.LineItems           AS LineItems
	|WHERE
	|	    LineItems.Ref                   = &Ref
	|	AND LineItems.Product.Type          = VALUE(Enum.InventoryTypes.Inventory)
	|	AND LineItems.Product.CostingMethod = VALUE(Enum.InventoryCosting.WeightedAverage)
	|GROUP BY
	|	LineItems.Product.CostingMethod,
	|	LineItems.Product,
	|	LineItems.Ref.Location
	|
	|UNION ALL
	|
	|SELECT // WAve for amount calcualtion
	// ------------------------------------------------------
	// Dimensions
	|	LineItems.Product.CostingMethod          AS Type,
	|	LineItems.Product                        AS Product,
	|	VALUE(Catalog.Locations.EmptyRef)        AS Location,
	// ------------------------------------------------------
	// Agregates
	|	SUM(LineItems.QtyUM)                     AS QuantityRequested
	// ------------------------------------------------------
	|FROM
	|	Document.SalesReturn.LineItems           AS LineItems
	|WHERE
	|	    LineItems.Ref                   = &Ref
	|	AND LineItems.Product.Type          = VALUE(Enum.InventoryTypes.Inventory)
	|	AND LineItems.Product.CostingMethod = VALUE(Enum.InventoryCosting.WeightedAverage)
	|GROUP BY
	|	LineItems.Product.CostingMethod,
	|	LineItems.Product";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_InventoryJournal_Balance_Quantity(TablesList)
	
	// Add InventoryJournal balance table to document structure.
	TablesList.Insert("Table_InventoryJournal_Balance_Quantity", TablesList.Count());
	
	// Collect inventory data.
	QueryText =
	"SELECT // WAve for amount calcualtion
	// ------------------------------------------------------
	// Dimensions
	|	InventoryJournalBalance.Type             AS Type,
	|	InventoryJournalBalance.Product          AS Product,
	|	VALUE(Catalog.Locations.EmptyRef)        AS Location,
	// ------------------------------------------------------
	// Agregates
	|	SUM(InventoryJournalBalance.Quantity)    AS Quantity,
	|	SUM(InventoryJournalBalance.Amount)      AS Amount
	// ------------------------------------------------------
	|INTO
	|	Table_InventoryJournal_Balance_Quantity
	|FROM
	|	Table_InventoryJournal_Balance AS InventoryJournalBalance
	|WHERE
	|	InventoryJournalBalance.Type = VALUE(Enum.InventoryCosting.WeightedAverage)
	|GROUP BY
	|	InventoryJournalBalance.Type,
	|	InventoryJournalBalance.Product";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_InventoryJournal(TablesList)
	
	// Add InventoryJournal table to document structure.
	TablesList.Insert("Table_InventoryJournal", TablesList.Count());
	
	// Collect inventory data.
	QueryText =
	"SELECT // FIFO
	// ------------------------------------------------------
	// Standard attributes
	|	SalesReturn.Ref                       AS Recorder,
	|	SalesReturn.Date                      AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Dimensions
	|	LineItems_FIFO.Product                AS Product,
	|	LineItems_FIFO.Location               AS Location,
	|	SalesReturn.Ref                       AS Layer,
	// ------------------------------------------------------
	// Resources
	|	LineItems_FIFO.QuantityRequested      AS Quantity,
	|	CAST ( // Format(LastCost * QuantityRequested, ""ND=15; NFD=2"")
	|		 ItemLastCosts.Cost * LineItems_FIFO.QuantityRequested
	|		 AS NUMBER (15, 2))               AS Amount
	// ------------------------------------------------------
	// Attributes
	// ------------------------------------------------------
	|FROM
	|	Table_InventoryJournal_LineItems AS LineItems_FIFO
	|	LEFT JOIN Table_ItemLastCosts_SliceLast AS ItemLastCosts
	|		ON  ItemLastCosts.Product = LineItems_FIFO.Product
	|	LEFT JOIN Document.SalesReturn AS SalesReturn
	|		ON True
	|WHERE
	|	SalesReturn.Ref = &Ref
	|	AND LineItems_FIFO.Type = VALUE(Enum.InventoryCosting.FIFO)
	|	AND LineItems_FIFO.QuantityRequested > 0
	|
	|UNION ALL
	|
	|SELECT // WeightedAverage by quantity
	// ------------------------------------------------------
	// Standard attributes
	|	SalesReturn.Ref                       AS Recorder,
	|	SalesReturn.Date                      AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Dimensions
	|	LineItems_WAve.Product                AS Product,
	|	LineItems_WAve.Location               AS Location,
	|	NULL                                  AS Layer,
	// ------------------------------------------------------
	// Resources
	|	LineItems_WAve.QuantityRequested      AS Quantity,
	|	0                                     AS Amount
	// ------------------------------------------------------
	// Attributes
	// ------------------------------------------------------
	|FROM
	|	Table_InventoryJournal_LineItems AS LineItems_WAve
	|	LEFT JOIN Document.SalesReturn AS SalesReturn
	|		ON True
	|WHERE
	|	SalesReturn.Ref = &Ref
	|	AND LineItems_WAve.Type      = VALUE(Enum.InventoryCosting.WeightedAverage)
	|	AND LineItems_WAve.Location <> VALUE(Catalog.Locations.EmptyRef)
	|	AND LineItems_WAve.QuantityRequested > 0
	|
	|UNION ALL
	|
	|SELECT // WeightedAverage by amount
	// ------------------------------------------------------
	// Standard attributes
	|	SalesReturn.Ref                       AS Recorder,
	|	SalesReturn.Date                      AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Dimensions
	|	LineItems_WAve.Product                AS Product,
	|	VALUE(Catalog.Locations.EmptyRef)     AS Location,
	|	NULL                                  AS Layer,
	// ------------------------------------------------------
	// Resources
	|	0                                     AS Quantity,
	|	CASE
	|		WHEN ISNULL(Balance_WAve.Quantity, 0) > 0
	|		// The balance is still active.
	|		THEN CAST ( // Format(Amount * QuantityReceipt / Quantity, ""ND=15; NFD=2"")
	|			 ISNULL(Balance_WAve.Amount, 0) * LineItems_WAve.QuantityRequested / Balance_WAve.Quantity
	|			 AS NUMBER (15, 2))
	|		ELSE CAST ( // Format(LastCost * QuantityRequested, ""ND=15; NFD=2"")
	|			 ItemLastCosts.Cost * LineItems_WAve.QuantityRequested
	|			 AS NUMBER (15, 2))
	|	END                                   AS Amount
	// ------------------------------------------------------
	// Attributes
	// ------------------------------------------------------
	|FROM
	|	Table_InventoryJournal_LineItems AS LineItems_WAve
	|	LEFT JOIN Table_InventoryJournal_Balance_Quantity AS Balance_WAve
	|		ON  Balance_WAve.Product  = LineItems_WAve.Product
	|		AND Balance_WAve.Location = VALUE(Catalog.Locations.EmptyRef)
	|	LEFT JOIN Table_ItemLastCosts_SliceLast AS ItemLastCosts
	|		ON  ItemLastCosts.Product = LineItems_WAve.Product
	|	LEFT JOIN Document.SalesReturn AS SalesReturn
	|		ON True
	|WHERE
	|	SalesReturn.Ref = &Ref
	|	AND LineItems_WAve.Type     = VALUE(Enum.InventoryCosting.WeightedAverage)
	|	AND LineItems_WAve.Location = VALUE(Catalog.Locations.EmptyRef)
	|	AND // Amount > 0
	|	CASE
	|		WHEN ISNULL(Balance_WAve.Quantity, 0) > 0
	|		// The balance is still active.
	|		THEN CAST ( // Format(Amount * QuantityReceipt / Quantity, ""ND=15; NFD=2"")
	|			 ISNULL(Balance_WAve.Amount, 0) * LineItems_WAve.QuantityRequested / Balance_WAve.Quantity
	|			 AS NUMBER (15, 2))
	|		ELSE CAST ( // Format(LastCost * QuantityRequested, ""ND=15; NFD=2"")
	|			 ItemLastCosts.Cost * LineItems_WAve.QuantityRequested
	|			 AS NUMBER (15, 2))
	|	END > 0";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for dimensions lock data.
Function Query_InventoryJournal_Lock(TablesList)
	
	// Add InventoryJournal - Add table to locks structure.
	TablesList.Insert("AccumulationRegister_InventoryJournal", TablesList.Count());
	
	// Collect dimensions for inventory journal locking.
	QueryText =
	"SELECT DISTINCT // WeightedAverage by quantity & amount
	// ------------------------------------------------------
	// Dimensions
	|	LineItems.Product                     AS Product
	// ------------------------------------------------------
	|FROM
	|	Table_LineItems AS LineItems
	|WHERE
	|	    LineItems.Product.Type          = VALUE(Enum.InventoryTypes.Inventory)
	|	AND LineItems.Product.CostingMethod = VALUE(Enum.InventoryCosting.WeightedAverage)";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for balances data.
Function Query_InventoryJournal_Balance(TablesList)
	
	// Add InventoryJournal - Balances table to balances structure.
	TablesList.Insert("Table_InventoryJournal_Balance", TablesList.Count());
	
	// Collect inventory journal balances.
	QueryText =
	"SELECT // WAve by quantity and amount
	// ------------------------------------------------------
	// Dimensions
	|	InventoryJournalBalance.Product.CostingMethod
	|	                                         AS Type,
	|	InventoryJournalBalance.Product          AS Product,
	|	InventoryJournalBalance.Location         AS Location,
	|	CASE // Type definition for layer field.
	|		WHEN InventoryJournalBalance.Product.CostingMethod = VALUE(Enum.InventoryCosting.FIFO)
	|		THEN InventoryJournalBalance.Layer
	|		ELSE NULL
	|	END                                      AS Layer,
	// ------------------------------------------------------
	// Resources
	|	InventoryJournalBalance.QuantityBalance  AS Quantity,
	|	InventoryJournalBalance.AmountBalance    AS Amount
	// ------------------------------------------------------
	|FROM
	|	AccumulationRegister.InventoryJournal.Balance(&PointInTime,
	|		(Product) IN
	|		(SELECT DISTINCT Product FROM Table_InventoryJournal_Lock WHERE Product.CostingMethod = VALUE(Enum.InventoryCosting.WeightedAverage)))
	|		                                     AS InventoryJournalBalance";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for dimensions lock data.
Function Query_ItemLastCosts_Lock(TablesList)
	
	// Add ItemLastCosts - Add table to locks structure.
	TablesList.Insert("InformationRegister_ItemLastCosts", TablesList.Count());
	
	// Collect dimensions for items last cost locking.
	QueryText =
	"SELECT DISTINCT
	// ------------------------------------------------------
	// Dimensions
	|	LineItems.Product                     AS Product
	// ------------------------------------------------------
	|FROM
	|	Table_LineItems AS LineItems
	|WHERE
	|	LineItems.Product.Type = VALUE(Enum.InventoryTypes.Inventory)";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for balances data.
Function Query_ItemLastCosts_SliceLast(TablesList)
	
	// Add ItemLastCosts - SliceLast table to balances structure.
	TablesList.Insert("Table_ItemLastCosts_SliceLast", TablesList.Count());
	
	// Collect items last cost last state.
	QueryText =
	"SELECT
	// ------------------------------------------------------
	// Dimensions
	|	ItemLastCosts.Product                    AS Product,
	// ------------------------------------------------------
	// Resources
	|	ItemLastCosts.Cost                       AS Cost
	// ------------------------------------------------------
	// Attributes
	// ------------------------------------------------------
	|FROM
	|	InformationRegister.ItemLastCosts.SliceLast(&PointInTime,
	|		(Product) IN (SELECT Product FROM Table_ItemLastCosts_Lock))
	|		                                     AS ItemLastCosts";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Put structure of registers, which balance should be checked during posting.
Procedure FillRegistersCheckList(AdditionalProperties, RegisterRecords)
	
	// Create structure of registers and its resources to check balances.
	BalanceCheck = New Structure;
	
	// Fill structure depending on document write mode.
	If AdditionalProperties.Posting.WriteMode = DocumentWriteMode.Posting Then
		
		// Add resources for check changes in recordset.
		CheckPostings = New Array;
		CheckPostings.Add("{Table}.Quantity{Posting}, <, 0"); // Check decreasing quantity.
		
		// Add resources for check register balances.
		CheckBalances = New Array;
		CheckBalances.Add("{Table}.Quantity{Balance}, <, 0"); // Check negative inventory balance.
		
		// Add messages for different error situations.
		CheckMessages = New Array;
		CheckMessages.Add(NStr("en = '{Product}?{Layer}:
		                             |There is an insufficient balance of {-Quantity} at the {Location}.|Layer = "" of {Layer}""'"));
		
		// Add register to check it's recordset changes and balances during posting.
		BalanceCheck.Insert("InventoryJournal", New Structure("CheckPostings, CheckBalances, CheckMessages", CheckPostings, CheckBalances, CheckMessages));
		
	ElsIf AdditionalProperties.Posting.WriteMode = DocumentWriteMode.UndoPosting Then
		
		// Add resources for check changes in recordset.
		CheckPostings = New Array;
		CheckPostings.Add("{Table}.Quantity{Posting}, <, 0"); // Check decreasing quantity.
		
		// Add resources for check register balances.
		CheckBalances = New Array;
		CheckBalances.Add("{Table}.Quantity{Balance}, <, 0"); // Check negative inventory balance.
		
		// Add messages for different error situations.
		CheckMessages = New Array;
		CheckMessages.Add(NStr("en = '{Product}?{Layer}:
		                             |There is an insufficient balance of {-Quantity} at the {Location}.|Layer = "" of {Layer}""'"));
		
		// Add registers to check it's recordset changes and balances during undo posting.
		BalanceCheck.Insert("InventoryJournal", New Structure("CheckPostings, CheckBalances, CheckMessages", CheckPostings, CheckBalances, CheckMessages));
		
	EndIf;
	
	// Return structure of registers to check.
	If BalanceCheck.Count() > 0 Then
		AdditionalProperties.Posting.Insert("BalanceCheck", BalanceCheck);
	EndIf;
	
EndProcedure

//Query for Sales Tax
Function Query_SalesTaxOwed(TablesList)
	// Add SalesTaxOwed table to document structure.
	TablesList.Insert("Table_SalesTaxOwed", TablesList.Count());
	
	// Collect sales tax data.
	QueryText =
	"SELECT
	|	SalesReturn.Ref AS Recorder,
	|	SalesReturn.Ref.Date AS Period,
	|	0 AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	TRUE AS Active,
	|	AccountingMethod.Ref AS ChargeType,
	|	SalesReturn.Agency AS Agency,
	|	SalesReturn.Rate AS TaxRate,
	|	SalesReturn.SalesTaxComponent AS SalesTaxComponent,
	|	-1 * (SalesReturn.Ref.DocumentTotalRC - SalesReturn.Ref.SalesTaxRC) AS GrossSale,
	|	-1 * SalesReturn.Ref.TaxableSubtotal AS TaxableSale,
	|	-1 * SalesReturn.Amount AS TaxPayable
	|FROM
	|	Document.SalesReturn.SalesTaxAcrossAgencies AS SalesReturn
	|		LEFT JOIN Enum.AccountingMethod AS AccountingMethod
	|		ON (CASE
	|				WHEN SalesReturn.Ref.ReturnType = VALUE(Enum.ReturnTypes.CreditMemo)
	|					THEN AccountingMethod.Ref = VALUE(Enum.AccountingMethod.Accrual)
	|				ELSE TRUE
	|			END)
	|WHERE
	|	SalesReturn.Ref = &Ref";
		
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
		
EndFunction

//Query for Sales Tax in the General Journal
//Function Query_SalesTax_GeneralJournal(TablesList)
//	// Add GeneralJournal table to document structure.
//	TablesList.Insert("Table_GeneralJournal", TablesList.Count());
//	
//	// Collect sales tax data.
//	QueryText =
//	"SELECT 
//	// ------------------------------------------------------
//	// Standard attributes
//	|	SalesReturn.Ref                      AS Recorder,
//	|	SalesReturn.Date                     AS Period,
//	|	0                                     AS LineNumber,
//	|	VALUE(AccountingRecordType.Credit) AS RecordType,
//	|	True                                  AS Active,
//	|	VALUE(ChartOfAccounts.ChartOfAccounts.TaxPayable) AS Account,
//	// ------------------------------------------------------
//	// Dimensions
//	// ------------------------------------------------------
//	// Resources
//	|	-1 * SalesReturn.SalesTaxRC AS AmountRC
//	// ------------------------------------------------------
//	// Attributes
//	// ------------------------------------------------------
//	|FROM
//	|	Document.SalesReturn AS SalesReturn
//	|WHERE
//	|	SalesReturn.Ref = &Ref";
//	
//	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
//		
//EndFunction

//------------------------------------------------------------------------------
// Document filling

//------------------------------------------------------------------------------
// Document printing

#EndIf

#EndRegion

