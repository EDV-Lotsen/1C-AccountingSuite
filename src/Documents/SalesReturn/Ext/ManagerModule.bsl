
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
		             Query_InventoryJournal(TablesList) +
	        	     Query_GeneralJournal_LineItems(TablesList) +
	         	     Query_GeneralJournal_Accounts_Income(TablesList) +
	            	 Query_GeneralJournal_Accounts_COGS_Quantity(TablesList) +
	                 Query_GeneralJournal_Accounts_COGS_Amount(TablesList) +
	                 Query_GeneralJournal_Accounts_COGS(TablesList) +
	                 Query_GeneralJournal_Accounts_InvOrExp_Quantity(TablesList) +
	                 Query_GeneralJournal_Accounts_InvOrExp_Amount(TablesList) +
	                 Query_GeneralJournal_Accounts_InvOrExp(TablesList) +
				     Query_GeneralJournal(TablesList) +
					 //--//GJ++
					 Query_GeneralJournalAnalyticsDimensions_Accounts_Income(TablesList) +
					 Query_GeneralJournalAnalyticsDimensions_Accounts_Income_Difference_Amount(TablesList) +
					 Query_GeneralJournalAnalyticsDimensions_Accounts_Income_Difference(TablesList) +
					 Query_GeneralJournalAnalyticsDimensions_Accounts_COGS_Quantity(TablesList) +
					 Query_GeneralJournalAnalyticsDimensions_Accounts_COGS_Amount(TablesList) +
					 Query_GeneralJournalAnalyticsDimensions_Accounts_COGS(TablesList) +
					 Query_GeneralJournalAnalyticsDimensions_Accounts_COGS_Difference_Amount(TablesList)+
					 Query_GeneralJournalAnalyticsDimensions_Accounts_COGS_Difference(TablesList)+
					 Query_GeneralJournalAnalyticsDimensions_Accounts_InvOrExp_Quantity(TablesList) +
					 Query_GeneralJournalAnalyticsDimensions_Accounts_InvOrExp_Amount(TablesList) +
					 Query_GeneralJournalAnalyticsDimensions_Accounts_InvOrExp(TablesList) +
					 Query_GeneralJournalAnalyticsDimensions_Accounts_InvOrExp_Difference_Amount(TablesList)+
					 Query_GeneralJournalAnalyticsDimensions_Accounts_InvOrExp_Difference(TablesList)+
					 Query_GeneralJournalAnalyticsDimensions_Transactions(TablesList)+
					 Query_GeneralJournalAnalyticsDimensions(TablesList)+
					 //--//GJ--
					 
					 Query_CashFlowData_Difference_Amount(TablesList) +
					 Query_CashFlowData_Difference(TablesList) +
					 Query_CashFlowData(TablesList) +
				 
	         	     Query_ProjectData_Accounts_Income(TablesList) +
	                 Query_ProjectData_Accounts_COGS_Quantity(TablesList) +
	                 Query_ProjectData_Accounts_COGS_Amount(TablesList) +
	                 Query_ProjectData_Accounts_COGS(TablesList) +
	                 Query_ProjectData(TablesList)+
	         	     Query_ClassData_Accounts_Income(TablesList) +
	                 Query_ClassData_Accounts_COGS_Quantity(TablesList) +
	                 Query_ClassData_Accounts_COGS_Amount(TablesList) +
	                 Query_ClassData_Accounts_COGS(TablesList) +
	                 Query_ClassData(TablesList);
				 
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
   |	SalesReturn.SalesTax,
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
   |	SalesReturn.UseAvatax,
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
		ProductPrecisionFormat = GeneralFunctionsReusable.PriceFormatForOneItem(SelectionLineItems.Product);
		TemplateArea.Parameters.Price     = Format(SelectionLineItems.PriceUnits, ProductPrecisionFormat + "; NZ=");
		TemplateArea.Parameters.UM = SelectionLineItems.Unit.Code;
		TemplateArea.Parameters.LineTotal = Format(SelectionLineItems.LineTotal, "NFD=2; NZ=");
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
	TemplateArea.Parameters.LineSubtotal = Format(Selection.LineSubtotal, "NFD=2; NZ=");
	TemplateArea.Parameters.Discount = "("+ Format(Selection.Discount, "NFD=2; NZ=") + ")";
	//TemplateArea.Parameters.Subtotal = Format(Selection.Subtotal, "NFD=2; NZ=");
	TemplateArea.Parameters.Shipping = Format(Selection.Shipping, "NFD=2; NZ="); 
	TemplateArea.Parameters.SalesTaxTitle = PrintFormFunctions.GetDescriptionSalesTax(Selection.Ref, Selection.UseAvatax);
	TemplateArea.Parameters.SalesTax = Format(Selection.SalesTax, "NFD=2; NZ=");
	TemplateArea.Parameters.NetTotalTitle = "Net Total " + Selection.Currency.Description + ": ";
	TemplateArea.Parameters.Total = Format(Selection.DocumentTotal, "NFD=2; NZ=");

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
	
	Spreadsheet.PutHorizontalPageBreak();
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
	|	CAST ( // Format(LastCost * QuantityRequested, ""ND=17; NFD=2"")
	|		 ItemLastCosts.Cost * LineItems_FIFO.QuantityRequested
	|		 AS NUMBER (17, 2))               AS Amount
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
	|		THEN CAST ( // Format(Amount * QuantityReceipt / Quantity, ""ND=17; NFD=2"")
	|			 ISNULL(Balance_WAve.Amount, 0) * LineItems_WAve.QuantityRequested / Balance_WAve.Quantity
	|			 AS NUMBER (17, 2))
	|		ELSE CAST ( // Format(LastCost * QuantityRequested, ""ND=17; NFD=2"")
	|			 ItemLastCosts.Cost * LineItems_WAve.QuantityRequested
	|			 AS NUMBER (17, 2))
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
	|		THEN CAST ( // Format(Amount * QuantityReceipt / Quantity, ""ND=17; NFD=2"")
	|			 ISNULL(Balance_WAve.Amount, 0) * LineItems_WAve.QuantityRequested / Balance_WAve.Quantity
	|			 AS NUMBER (17, 2))
	|		ELSE CAST ( // Format(LastCost * QuantityRequested, ""ND=17; NFD=2"")
	|			 ItemLastCosts.Cost * LineItems_WAve.QuantityRequested
	|			 AS NUMBER (17, 2))
	|	END > 0";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_GeneralJournal_LineItems(TablesList)
	
	// Add GeneralJournal requested items table to document structure.
	TablesList.Insert("Table_GeneralJournal_LineItems", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT
	// ------------------------------------------------------
	// Dimensions
	|	LineItems.Product.CostingMethod       AS Type,
	|	LineItems.Product                     AS Product,
	|	LineItems.Ref.Location                AS Location,
	|	LineItems.Project                     AS Project,
	|	LineItems.Class                       AS Class,
	|	LineItems.Product.IncomeAccount       AS IncomeAccount,
	|	LineItems.Product.COGSAccount         AS COGSAccount,
	|	LineItems.Product.InventoryOrExpenseAccount AS InvOrExpAccount,
	// ------------------------------------------------------
	// Resources
	|	LineItems.QtyUM                       AS Quantity,
	|	LineItems.LineTotal                   AS Amount
	// ------------------------------------------------------
	|INTO
	|	Table_GeneralJournal_LineItems
	|FROM
	|	Document.SalesReturn.LineItems AS LineItems
	|WHERE
	|	LineItems.Ref = &Ref";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_GeneralJournal_Accounts_Income(TablesList)
	
	// Add GeneralJournal income accounts table to document structure.
	TablesList.Insert("Table_GeneralJournal_Accounts_Income", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // Income accounts selection
	// ------------------------------------------------------
	// Dimensions
	|	Accounts.IncomeAccount                AS IncomeAccount,
	// ------------------------------------------------------
	// Resources
	|	SUM(Accounts.Amount)                  AS Amount
	// ------------------------------------------------------
	|INTO
	|	Table_GeneralJournal_Accounts_Income
	|FROM
	|	Table_GeneralJournal_LineItems AS Accounts
	|GROUP BY
	|	Accounts.IncomeAccount";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_GeneralJournal_Accounts_COGS_Quantity(TablesList)
	
	// Add GeneralJournal COGS accounts table to document structure.
	TablesList.Insert("Table_GeneralJournal_Accounts_COGS_Quantity", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // COGS accounts selection
	// ------------------------------------------------------
	// Dimensions
	|	Accounts.COGSAccount                  AS COGSAccount,
	|	Accounts.Product                      AS Product,
	|	Accounts.Type                         AS Type,
	// ------------------------------------------------------
	// Resources
	|	SUM(Accounts.Quantity)                AS QuantityRequested
	// ------------------------------------------------------
	|INTO
	|	Table_GeneralJournal_Accounts_COGS_Quantity
	|FROM
	|	Table_GeneralJournal_LineItems AS Accounts
	|WHERE
    |   Accounts.Product.Type = VALUE(Enum.InventoryTypes.Inventory)
	|GROUP BY
	|	Accounts.COGSAccount,
	|	Accounts.Product,
	|	Accounts.Type";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_GeneralJournal_Accounts_COGS_Amount(TablesList)
	
	// Add GeneralJournal COGS accounts table to document structure.
	TablesList.Insert("Table_GeneralJournal_Accounts_COGS_Amount", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // FIFO
	// ------------------------------------------------------
	// Dimensions
	|	Accounts_FIFO.COGSAccount             AS COGSAccount,
	// ------------------------------------------------------
	// Resources
	|	CAST ( // Format(LastCost * QuantityRequested, ""ND=17; NFD=2"")
	|		 ItemLastCosts.Cost * Accounts_FIFO.QuantityRequested
	|		 AS NUMBER (17, 2))               AS Amount
	// ------------------------------------------------------
	|INTO
	|	Table_GeneralJournal_Accounts_COGS_Amount
	|FROM
	|	Table_GeneralJournal_Accounts_COGS_Quantity AS Accounts_FIFO
	|	LEFT JOIN Table_ItemLastCosts_SliceLast AS ItemLastCosts
	|		ON  ItemLastCosts.Product = Accounts_FIFO.Product
	|WHERE
	|	Accounts_FIFO.Type = VALUE(Enum.InventoryCosting.FIFO)
	|	AND Accounts_FIFO.QuantityRequested > 0
	|
	|UNION ALL
	|
	|SELECT // WeightedAverage
	// ------------------------------------------------------
	// Dimensions
	|	Account_WAve.COGSAccount              AS Accounts,
	// ------------------------------------------------------
	// Resources
	|	CASE
	|		WHEN ISNULL(Balance_WAve.Quantity, 0) > 0
	|		// The balance is still active.
	|		THEN CAST ( // Format(Amount * QuantityReceipt / Quantity, ""ND=17; NFD=2"")
	|			 ISNULL(Balance_WAve.Amount, 0) * Account_WAve.QuantityRequested / Balance_WAve.Quantity
	|			 AS NUMBER (17, 2))
	|		ELSE CAST ( // Format(LastCost * QuantityRequested, ""ND=17; NFD=2"")
	|			 ItemLastCosts.Cost * Account_WAve.QuantityRequested
	|			 AS NUMBER (17, 2))
	|	END                                   AS Amount
	// ------------------------------------------------------
	// Attributes
	// ------------------------------------------------------
	|FROM
	|	Table_GeneralJournal_Accounts_COGS_Quantity AS Account_WAve
	|	LEFT JOIN Table_InventoryJournal_Balance_Quantity AS Balance_WAve
	|		ON  Balance_WAve.Product  = Account_WAve.Product
	|		AND Balance_WAve.Location = VALUE(Catalog.Locations.EmptyRef)
	|	LEFT JOIN Table_ItemLastCosts_SliceLast AS ItemLastCosts
	|		ON  ItemLastCosts.Product = Account_WAve.Product
	|WHERE
	|	Account_WAve.Type = VALUE(Enum.InventoryCosting.WeightedAverage)
	|	AND // Amount > 0
	|	CASE
	|		WHEN ISNULL(Balance_WAve.Quantity, 0) > 0
	|		// The balance is still active.
	|		THEN CAST ( // Format(Amount * QuantityReceipt / Quantity, ""ND=17; NFD=2"")
	|			 ISNULL(Balance_WAve.Amount, 0) * Account_WAve.QuantityRequested / Balance_WAve.Quantity
	|			 AS NUMBER (17, 2))
	|		ELSE CAST ( // Format(LastCost * QuantityRequested, ""ND=17; NFD=2"")
	|			 ItemLastCosts.Cost * Account_WAve.QuantityRequested
	|			 AS NUMBER (17, 2))
	|	END > 0";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_GeneralJournal_Accounts_COGS(TablesList)
	
	// Add GeneralJournal COGS accounts table to document structure.
	TablesList.Insert("Table_GeneralJournal_Accounts_COGS", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // COGS accounts selection
	// ------------------------------------------------------
	// Dimensions
	|	Accounts.COGSAccount                  AS COGSAccount,
	// ------------------------------------------------------
	// Resources
	|	SUM(Accounts.Amount)                  AS Amount
	// ------------------------------------------------------
	|INTO
	|	Table_GeneralJournal_Accounts_COGS
	|FROM
	|	Table_GeneralJournal_Accounts_COGS_Amount AS Accounts
	|GROUP BY
	|	Accounts.COGSAccount";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_GeneralJournal_Accounts_InvOrExp_Quantity(TablesList)
	
	// Add GeneralJournal InvOrExp accounts table to document structure.
	TablesList.Insert("Table_GeneralJournal_Accounts_InvOrExp_Quantity", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // InvOrExp accounts selection
	// ------------------------------------------------------
	// Dimensions
	|	Accounts.InvOrExpAccount              AS InvOrExpAccount,
	|	Accounts.Product                      AS Product,
	|	Accounts.Type                         AS Type,
	// ------------------------------------------------------
	// Resources
	|	SUM(Accounts.Quantity)                AS QuantityRequested
	// ------------------------------------------------------
	|INTO
	|	Table_GeneralJournal_Accounts_InvOrExp_Quantity
	|FROM
	|	Table_GeneralJournal_LineItems AS Accounts
	|WHERE
    |   Accounts.Product.Type = VALUE(Enum.InventoryTypes.Inventory)
	|GROUP BY
	|	Accounts.InvOrExpAccount,
	|	Accounts.Product,
	|	Accounts.Type";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_GeneralJournal_Accounts_InvOrExp_Amount(TablesList)
	
	// Add GeneralJournal InvOrExp accounts table to document structure.
	TablesList.Insert("Table_GeneralJournal_Accounts_InvOrExp_Amount", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // FIFO
	// ------------------------------------------------------
	// Dimensions
	|	Accounts_FIFO.InvOrExpAccount         AS InvOrExpAccount,
	// ------------------------------------------------------
	// Resources
	|	CAST ( // Format(LastCost * QuantityRequested, ""ND=17; NFD=2"")
	|		 ItemLastCosts.Cost * Accounts_FIFO.QuantityRequested
	|		 AS NUMBER (17, 2))               AS Amount
	// ------------------------------------------------------
	|INTO
	|	Table_GeneralJournal_Accounts_InvOrExp_Amount
	|FROM
	|	Table_GeneralJournal_Accounts_InvOrExp_Quantity AS Accounts_FIFO
	|	LEFT JOIN Table_ItemLastCosts_SliceLast AS ItemLastCosts
	|		ON  ItemLastCosts.Product = Accounts_FIFO.Product
	|WHERE
	|	Accounts_FIFO.Type = VALUE(Enum.InventoryCosting.FIFO)
	|	AND Accounts_FIFO.QuantityRequested > 0
	|
	|UNION ALL
	|
	|SELECT // WeightedAverage
	// ------------------------------------------------------
	// Dimensions
	|	Account_WAve.InvOrExpAccount          AS Accounts,
	// ------------------------------------------------------
	// Resources
	|	CASE
	|		WHEN ISNULL(Balance_WAve.Quantity, 0) > 0
	|		// The balance is still active.
	|		THEN CAST ( // Format(Amount * QuantityReceipt / Quantity, ""ND=17; NFD=2"")
	|			 ISNULL(Balance_WAve.Amount, 0) * Account_WAve.QuantityRequested / Balance_WAve.Quantity
	|			 AS NUMBER (17, 2))
	|		ELSE CAST ( // Format(LastCost * QuantityRequested, ""ND=17; NFD=2"")
	|			 ItemLastCosts.Cost * Account_WAve.QuantityRequested
	|			 AS NUMBER (17, 2))
	|	END                                   AS Amount
	// ------------------------------------------------------
	// Attributes
	// ------------------------------------------------------
	|FROM
	|	Table_GeneralJournal_Accounts_InvOrExp_Quantity AS Account_WAve
	|	LEFT JOIN Table_InventoryJournal_Balance_Quantity AS Balance_WAve
	|		ON  Balance_WAve.Product  = Account_WAve.Product
	|		AND Balance_WAve.Location = VALUE(Catalog.Locations.EmptyRef)
	|	LEFT JOIN Table_ItemLastCosts_SliceLast AS ItemLastCosts
	|		ON  ItemLastCosts.Product = Account_WAve.Product
	|WHERE
	|	Account_WAve.Type = VALUE(Enum.InventoryCosting.WeightedAverage)
	|	AND // Amount > 0
	|	CASE
	|		WHEN ISNULL(Balance_WAve.Quantity, 0) > 0
	|		// The balance is still active.
	|		THEN CAST ( // Format(Amount * QuantityReceipt / Quantity, ""ND=17; NFD=2"")
	|			 ISNULL(Balance_WAve.Amount, 0) * Account_WAve.QuantityRequested / Balance_WAve.Quantity
	|			 AS NUMBER (17, 2))
	|		ELSE CAST ( // Format(LastCost * QuantityRequested, ""ND=17; NFD=2"")
	|			 ItemLastCosts.Cost * Account_WAve.QuantityRequested
	|			 AS NUMBER (17, 2))
	|	END > 0";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_GeneralJournal_Accounts_InvOrExp(TablesList)
	
	// Add GeneralJournal InvOrExp accounts table to document structure.
	TablesList.Insert("Table_GeneralJournal_Accounts_InvOrExp", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // InvOrExp accounts selection
	// ------------------------------------------------------
	// Dimensions
	|	Accounts.InvOrExpAccount              AS InvOrExpAccount,
	// ------------------------------------------------------
	// Resources
	|	SUM(Accounts.Amount)                  AS Amount
	// ------------------------------------------------------
	|INTO
	|	Table_GeneralJournal_Accounts_InvOrExp
	|FROM
	|	Table_GeneralJournal_Accounts_InvOrExp_Amount AS Accounts
	|GROUP BY
	|	Accounts.InvOrExpAccount";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_GeneralJournal(TablesList)
	
	// Add GeneralJournal table to document structure.
	TablesList.Insert("Table_GeneralJournal", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // Cr: Accounts receivable
	// ------------------------------------------------------
	// Standard attributes
	|	SalesReturn.Ref                       AS Recorder,
	|	SalesReturn.Date                      AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccountingRecordType.Credit)    AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Accounting attributes
	|	SalesReturn.ARAccount                 AS Account,
	|	VALUE(ChartOfCharacteristicTypes.Dimensions.Company)
	|	                                      AS ExtDimensionType1,
	|	SalesReturn.Company                   AS ExtDimension1,
	|	VALUE(ChartOfCharacteristicTypes.Dimensions.Document)
	|	                                      AS ExtDimensionType2,
	|	SalesReturn.Ref                       AS ExtDimension2,
	// ------------------------------------------------------
	// Dimensions
	|	SalesReturn.Currency                  AS Currency,
	// ------------------------------------------------------
	// Resources
	|	SalesReturn.DocumentTotal             AS Amount,
	|	SalesReturn.DocumentTotalRC           AS AmountRC,
	// ------------------------------------------------------
	// Attributes
	|	Null                                  AS Memo
	// ------------------------------------------------------
	|FROM
	|	Document.SalesReturn AS SalesReturn
	|WHERE
	|	SalesReturn.Ref = &Ref
	|	AND // Amount > 0
	|		(SalesReturn.DocumentTotal > 0
	|	  OR SalesReturn.DocumentTotalRC > 0)
	|
	|UNION ALL
	|
	|SELECT // Cr: Discount
	// ------------------------------------------------------
	// Standard attributes
	|	SalesReturn.Ref                       AS Recorder,
	|	SalesReturn.Date                      AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccountingRecordType.Credit)    AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Accounting attributes
	|	CASE
	|		WHEN ISNULL(Constants.DiscountsAccount, VALUE(ChartOfAccounts.ChartOfAccounts.EmptyRef)) = VALUE(ChartOfAccounts.ChartOfAccounts.EmptyRef)
	|		THEN Constants.ExpenseAccount     // Default expense account
	|		ELSE Constants.DiscountsAccount   // Default discount account
	|	END                                   AS Account,
	|	VALUE(ChartOfCharacteristicTypes.Dimensions.EmptyRef)
	|	                                      AS ExtDimensionType1,
	|	NULL                                  AS ExtDimension1,
	|	VALUE(ChartOfCharacteristicTypes.Dimensions.EmptyRef)
	|	                                      AS ExtDimensionType2,
	|	NULL                                  AS ExtDimension2,
	// ------------------------------------------------------
	// Dimensions
	|	NULL                                  AS Currency,
	// ------------------------------------------------------
	// Resources
	|	NULL                                  AS Amount,
	|	CAST( // Format(-Discount * ExchangeRate, ""ND=17; NFD=2"")
	|		-SalesReturn.Discount *
	|		 CASE WHEN SalesReturn.ExchangeRate > 0
	|			  THEN SalesReturn.ExchangeRate
	|			  ELSE 1 END
	|		 AS NUMBER (17, 2))               AS AmountRC,
	// ------------------------------------------------------
	// Attributes
	|	NULL                                  AS Memo
	// ------------------------------------------------------
	|FROM
	|	Document.SalesReturn AS SalesReturn
	|	LEFT JOIN Constants AS Constants
	|		ON True
	|WHERE
	|	SalesReturn.Ref = &Ref
	|	AND // Discount > 0
	|		-SalesReturn.Discount > 0
	|
	|UNION ALL
	|
	|SELECT // Dr: Shipping
	// ------------------------------------------------------
	// Standard attributes
	|	SalesReturn.Ref                       AS Recorder,
	|	SalesReturn.Date                      AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccountingRecordType.Debit)     AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Accounting attributes
	|	CASE
	|		WHEN ISNULL(Constants.ShippingExpenseAccount, VALUE(ChartOfAccounts.ChartOfAccounts.EmptyRef)) = VALUE(ChartOfAccounts.ChartOfAccounts.EmptyRef)
	|		THEN Constants.IncomeAccount           // Default income account
	|		ELSE Constants.ShippingExpenseAccount  // Default shipping expense account
	|	END                                   AS Account,
	|	VALUE(ChartOfCharacteristicTypes.Dimensions.EmptyRef)
	|	                                      AS ExtDimensionType1,
	|	NULL                                  AS ExtDimension1,
	|	VALUE(ChartOfCharacteristicTypes.Dimensions.EmptyRef)
	|	                                      AS ExtDimensionType2,
	|	NULL                                  AS ExtDimension2,
	// ------------------------------------------------------
	// Dimensions
	|	NULL                                  AS Currency,
	// ------------------------------------------------------
	// Resources
	|	NULL                                  AS Amount,
	|	CAST( // Format(Shipping * ExchangeRate, ""ND=17; NFD=2"")
	|		SalesReturn.Shipping *
	|		CASE WHEN SalesReturn.ExchangeRate > 0
	|			 THEN SalesReturn.ExchangeRate
	|			 ELSE 1 END
	|		AS NUMBER (17, 2))                AS AmountRC,
	// ------------------------------------------------------
	// Attributes
	|	NULL                                  AS Memo
	// ------------------------------------------------------
	|FROM
	|	Document.SalesReturn AS SalesReturn
	|	LEFT JOIN Constants AS Constants
	|		ON True
	|WHERE
	|	SalesReturn.Ref = &Ref
	|	AND // Shipping > 0
	|		SalesReturn.Shipping > 0
	|
	|UNION ALL
	|
	|SELECT // Dr: Sales tax
	// ------------------------------------------------------
	// Standard attributes
	|	SalesReturn.Ref                       AS Recorder,
	|	SalesReturn.Date                      AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccountingRecordType.Debit)     AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Accounting attributes
	|	CASE
	|		WHEN ISNULL(Constants.TaxPayableAccount, VALUE(ChartOfAccounts.ChartOfAccounts.EmptyRef)) = VALUE(ChartOfAccounts.ChartOfAccounts.EmptyRef)
	|		THEN Constants.IncomeAccount      // Default income account
	|		ELSE Constants.TaxPayableAccount  // Default tax payable account
	|	END                                   AS Account,
	|	VALUE(ChartOfCharacteristicTypes.Dimensions.EmptyRef)
	|	                                      AS ExtDimensionType1,
	|	NULL                                  AS ExtDimension1,
	|	VALUE(ChartOfCharacteristicTypes.Dimensions.EmptyRef)
	|	                                      AS ExtDimensionType2,
	|	NULL                                  AS ExtDimension2,
	// ------------------------------------------------------
	// Dimensions
	|	NULL                                  AS Currency,
	// ------------------------------------------------------
	// Resources
	|	NULL                                  AS Amount,
	|	CAST( // Format(SalesTax * ExchangeRate, ""ND=17; NFD=2"")
	|		SalesReturn.SalesTax *
	|		CASE WHEN SalesReturn.ExchangeRate > 0
	|			 THEN SalesReturn.ExchangeRate
	|			 ELSE 1 END
	|		AS NUMBER (17, 2))                AS AmountRC,
	// ------------------------------------------------------
	// Attributes
	|	NULL                                  AS Memo
	// ------------------------------------------------------
	|FROM
	|	Document.SalesReturn AS SalesReturn
	|	LEFT JOIN Constants AS Constants
	|		ON True
	|WHERE
	|	SalesReturn.Ref = &Ref
	|	AND // SalesTax > 0
	|		SalesReturn.SalesTax > 0
	|
	|UNION ALL
	|
	|SELECT // Dr: Income
	// ------------------------------------------------------
	// Standard attributes
	|	SalesReturn.Ref                       AS Recorder,
	|	SalesReturn.Date                      AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccountingRecordType.Debit)     AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Accounting attributes
	|	Income.IncomeAccount                  AS Account,
	|	VALUE(ChartOfCharacteristicTypes.Dimensions.EmptyRef)
	|	                                      AS ExtDimensionType1,
	|	NULL                                  AS ExtDimension1,
	|	VALUE(ChartOfCharacteristicTypes.Dimensions.EmptyRef)
	|	                                      AS ExtDimensionType2,
	|	NULL                                  AS ExtDimension2,
	// ------------------------------------------------------
	// Dimensions
	|	NULL                                  AS Currency,
	// ------------------------------------------------------
	// Resources
	|	NULL                                  AS Amount,
	|	CAST( // Format(Amount * ExchangeRate, ""ND=17; NFD=2"")
	|		Income.Amount *
	|		CASE WHEN SalesReturn.ExchangeRate > 0
	|			 THEN SalesReturn.ExchangeRate
	|			 ELSE 1 END
	|		AS NUMBER (17, 2))                AS AmountRC,
	// ------------------------------------------------------
	// Attributes
	|	NULL                                  AS Memo
	// ------------------------------------------------------
	|FROM
	|	Table_GeneralJournal_Accounts_Income AS Income
	|	LEFT JOIN Document.SalesReturn AS SalesReturn
	|		ON True
	|WHERE
	|	SalesReturn.Ref = &Ref
	|	AND // Amount > 0
	|		Income.Amount > 0
	|
	|UNION ALL
	|
	|SELECT // Cr: COGS
	// ------------------------------------------------------
	// Standard attributes
	|	SalesReturn.Ref                       AS Recorder,
	|	SalesReturn.Date                      AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccountingRecordType.Credit)    AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Accounting attributes
	|	COGS.COGSAccount                      AS Account,
	|	VALUE(ChartOfCharacteristicTypes.Dimensions.EmptyRef)
	|	                                      AS ExtDimensionType1,
	|	NULL                                  AS ExtDimension1,
	|	VALUE(ChartOfCharacteristicTypes.Dimensions.EmptyRef)
	|	                                      AS ExtDimensionType2,
	|	NULL                                  AS ExtDimension2,
	// ------------------------------------------------------
	// Dimensions
	|	NULL                                  AS Currency,
	// ------------------------------------------------------
	// Resources
	|	NULL                                  AS Amount,
	|	COGS.Amount                           AS AmountRC,
	// ------------------------------------------------------
	// Attributes
	|	NULL                                  AS Memo
	// ------------------------------------------------------
	|FROM
	|	Table_GeneralJournal_Accounts_COGS AS COGS
	|	LEFT JOIN Document.SalesReturn AS SalesReturn
	|		ON True
	|WHERE
	|	SalesReturn.Ref = &Ref
	|	AND // Amount > 0
	|		COGS.Amount > 0
	|
	|UNION ALL
	|
	|SELECT // Dr: Inventory or Expences accounts
	// ------------------------------------------------------
	// Standard attributes
	|	SalesReturn.Ref                       AS Recorder,
	|	SalesReturn.Date                      AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccountingRecordType.Debit)     AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Accounting attributes
	|	InvOrExp.InvOrExpAccount              AS Account,
	|	VALUE(ChartOfCharacteristicTypes.Dimensions.EmptyRef)
	|	                                      AS ExtDimensionType1,
	|	NULL                                  AS ExtDimension1,
	|	VALUE(ChartOfCharacteristicTypes.Dimensions.EmptyRef)
	|	                                      AS ExtDimensionType2,
	|	NULL                                  AS ExtDimension2,
	// ------------------------------------------------------
	// Dimensions
	|	NULL                                  AS Currency,
	// ------------------------------------------------------
	// Resources
	|	NULL                                  AS Amount,
	|	InvOrExp.Amount                       AS AmountRC,
	// ------------------------------------------------------
	// Attributes
	|	NULL                                  AS Memo
	// ------------------------------------------------------
	|FROM
	|	Table_GeneralJournal_Accounts_InvOrExp AS InvOrExp
	|	LEFT JOIN Document.SalesReturn AS SalesReturn
	|		ON True
	|WHERE
	|	SalesReturn.Ref = &Ref
	|	AND // Amount > 0
	|		InvOrExp.Amount > 0";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

//--//GJ++

// Query for document data.
Function Query_GeneralJournalAnalyticsDimensions_Accounts_Income(TablesList)
	
	// Add GeneralJournalAnalyticsDimensions income accounts table to document structure.
	TablesList.Insert("Table_GeneralJournalAnalyticsDimensions_Accounts_Income", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // Income accounts selection
	// ------------------------------------------------------
	// Dimensions
	|	Accounts.IncomeAccount                AS IncomeAccount,
	|	Accounts.Class                        AS Class,
	|	Accounts.Project                      AS Project,
	// ------------------------------------------------------
	// Resources
	|	SUM(Accounts.Amount)                  AS Amount
	// ------------------------------------------------------
	|INTO
	|	Table_GeneralJournalAnalyticsDimensions_Accounts_Income
	|FROM
	|	Table_GeneralJournal_LineItems AS Accounts
	|GROUP BY
	|	Accounts.IncomeAccount,
	|	Accounts.Class,
	|	Accounts.Project";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_GeneralJournalAnalyticsDimensions_Accounts_Income_Difference_Amount(TablesList)
	
	// Add GeneralJournalAnalyticsDimensions difference amount table to document structure.
	TablesList.Insert("Table_GeneralJournalAnalyticsDimensions_Accounts_Income_Difference_Amount", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // Income accounts selection
	// ------------------------------------------------------
	// Dimensions
	|	IncomeDimensions.IncomeAccount        AS IncomeAccount,
	// ------------------------------------------------------
	// Resources
	|	CAST( // Format(Amount * ExchangeRate, ""ND=17; NFD=2"")
	|		IncomeDimensions.Amount *
	|		CASE WHEN SalesReturn.ExchangeRate > 0
	|			 THEN SalesReturn.ExchangeRate
	|			 ELSE 1 END
	|		AS NUMBER (17, 2))                AS Amount
	// ------------------------------------------------------
	|INTO
	|	Table_GeneralJournalAnalyticsDimensions_Accounts_Income_Difference_Amount
	|FROM
	|	Table_GeneralJournal_Accounts_Income AS IncomeDimensions
	|	LEFT JOIN Document.SalesReturn AS SalesReturn
	|		ON True
	|WHERE
	|	SalesReturn.Ref = &Ref
	|	AND // Amount > 0
	|		IncomeDimensions.Amount > 0
	|
	|UNION ALL
	|
	|SELECT // Income Dimensions accounts selection
	// ------------------------------------------------------
	// Dimensions
	|	IncomeDimensions.IncomeAccount        AS IncomeAccount,
	// ------------------------------------------------------
	// Resources
	|	CAST( // Format(Amount * ExchangeRate, ""ND=17; NFD=2"")
	|		IncomeDimensions.Amount *
	|		CASE WHEN SalesReturn.ExchangeRate > 0
	|			 THEN SalesReturn.ExchangeRate
	|			 ELSE 1 END
	|		AS NUMBER (17, 2)) * -1           AS Amount
	// ------------------------------------------------------
	|FROM
	|	Table_GeneralJournalAnalyticsDimensions_Accounts_Income AS IncomeDimensions
	|	LEFT JOIN Document.SalesReturn AS SalesReturn
	|		ON True
	|WHERE
	|	SalesReturn.Ref = &Ref
	|	AND // Amount > 0
	|		IncomeDimensions.Amount > 0";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_GeneralJournalAnalyticsDimensions_Accounts_Income_Difference(TablesList)
	
	// Add GeneralJournalAnalyticsDimensions difference table to document structure.
	TablesList.Insert("Table_GeneralJournalAnalyticsDimensions_Accounts_Income_Difference", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // Dimensions difference selection
	// ------------------------------------------------------
	// Dimensions
	|	DimensionsDifference.IncomeAccount         AS IncomeAccount,
	// ------------------------------------------------------
	// Resources
	|	SUM(DimensionsDifference.Amount)           AS Amount
	// ------------------------------------------------------
	|INTO
	|	Table_GeneralJournalAnalyticsDimensions_Accounts_Income_Difference
	|FROM
	|	Table_GeneralJournalAnalyticsDimensions_Accounts_Income_Difference_Amount AS DimensionsDifference
	|GROUP BY
	|	DimensionsDifference.IncomeAccount";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_GeneralJournalAnalyticsDimensions_Accounts_COGS_Quantity(TablesList)
	
	// Add GeneralJournalAnalyticsDimensions COGS accounts table to document structure.
	TablesList.Insert("Table_GeneralJournalAnalyticsDimensions_Accounts_COGS_Quantity", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // COGS accounts selection
	// ------------------------------------------------------
	// Dimensions
	|	Accounts.COGSAccount                  AS COGSAccount,
	|	Accounts.Product                      AS Product,
	|	Accounts.Class                        AS Class,
	|	Accounts.Project                      AS Project,
	|	Accounts.Type                         AS Type,
	// ------------------------------------------------------
	// Resources
	|	SUM(Accounts.Quantity)                AS QuantityRequested
	// ------------------------------------------------------
	|INTO
	|	Table_GeneralJournalAnalyticsDimensions_Accounts_COGS_Quantity
	|FROM
	|	Table_GeneralJournal_LineItems AS Accounts
	|WHERE
    |   Accounts.Product.Type = VALUE(Enum.InventoryTypes.Inventory)
	|GROUP BY
	|	Accounts.COGSAccount,
	|	Accounts.Product,
	|	Accounts.Class,
	|	Accounts.Project,
	|	Accounts.Type";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_GeneralJournalAnalyticsDimensions_Accounts_COGS_Amount(TablesList)
	
	// Add GeneralJournalAnalyticsDimensions COGS accounts table to document structure.
	TablesList.Insert("Table_GeneralJournalAnalyticsDimensions_Accounts_COGS_Amount", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // FIFO
	// ------------------------------------------------------
	// Dimensions
	|	Accounts_FIFO.COGSAccount             AS COGSAccount,
	|	Accounts_FIFO.Class                   AS Class,
	|	Accounts_FIFO.Project                 AS Project,
	// ------------------------------------------------------
	// Resources
	|	CAST ( // Format(LastCost * QuantityRequested, ""ND=17; NFD=2"")
	|		 ItemLastCosts.Cost * Accounts_FIFO.QuantityRequested
	|		 AS NUMBER (17, 2))               AS Amount
	// ------------------------------------------------------
	|INTO
	|	Table_GeneralJournalAnalyticsDimensions_Accounts_COGS_Amount
	|FROM
	|	Table_GeneralJournalAnalyticsDimensions_Accounts_COGS_Quantity AS Accounts_FIFO
	|	LEFT JOIN Table_ItemLastCosts_SliceLast AS ItemLastCosts
	|		ON  ItemLastCosts.Product = Accounts_FIFO.Product
	|WHERE
	|	Accounts_FIFO.Type = VALUE(Enum.InventoryCosting.FIFO)
	|	AND Accounts_FIFO.QuantityRequested > 0
	|
	|UNION ALL
	|
	|SELECT // WeightedAverage
	// ------------------------------------------------------
	// Dimensions
	|	Account_WAve.COGSAccount              AS Accounts,
	|	Account_WAve.Class                    AS Class,
	|	Account_WAve.Project                  AS Project,
	// ------------------------------------------------------
	// Resources
	|	CASE
	|		WHEN ISNULL(Balance_WAve.Quantity, 0) > 0
	|		// The balance is still active.
	|		THEN CAST ( // Format(Amount * QuantityReceipt / Quantity, ""ND=17; NFD=2"")
	|			 ISNULL(Balance_WAve.Amount, 0) * Account_WAve.QuantityRequested / Balance_WAve.Quantity
	|			 AS NUMBER (17, 2))
	|		ELSE CAST ( // Format(LastCost * QuantityRequested, ""ND=17; NFD=2"")
	|			 ItemLastCosts.Cost * Account_WAve.QuantityRequested
	|			 AS NUMBER (17, 2))
	|	END                                   AS Amount
	// ------------------------------------------------------
	// Attributes
	// ------------------------------------------------------
	|FROM
	|	Table_GeneralJournalAnalyticsDimensions_Accounts_COGS_Quantity AS Account_WAve
	|	LEFT JOIN Table_InventoryJournal_Balance_Quantity AS Balance_WAve
	|		ON  Balance_WAve.Product  = Account_WAve.Product
	|		AND Balance_WAve.Location = VALUE(Catalog.Locations.EmptyRef)
	|	LEFT JOIN Table_ItemLastCosts_SliceLast AS ItemLastCosts
	|		ON  ItemLastCosts.Product = Account_WAve.Product
	|WHERE
	|	Account_WAve.Type = VALUE(Enum.InventoryCosting.WeightedAverage)
	|	AND // Amount > 0
	|	CASE
	|		WHEN ISNULL(Balance_WAve.Quantity, 0) > 0
	|		// The balance is still active.
	|		THEN CAST ( // Format(Amount * QuantityReceipt / Quantity, ""ND=17; NFD=2"")
	|			 ISNULL(Balance_WAve.Amount, 0) * Account_WAve.QuantityRequested / Balance_WAve.Quantity
	|			 AS NUMBER (17, 2))
	|		ELSE CAST ( // Format(LastCost * QuantityRequested, ""ND=17; NFD=2"")
	|			 ItemLastCosts.Cost * Account_WAve.QuantityRequested
	|			 AS NUMBER (17, 2))
	|	END > 0";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_GeneralJournalAnalyticsDimensions_Accounts_COGS(TablesList)
	
	// Add GeneralJournalAnalyticsDimensions COGS accounts table to document structure.
	TablesList.Insert("Table_GeneralJournalAnalyticsDimensions_Accounts_COGS", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // COGS accounts selection
	// ------------------------------------------------------
	// Dimensions
	|	Accounts.COGSAccount                  AS COGSAccount,
	|	Accounts.Class                        AS Class,
	|	Accounts.Project                      AS Project,
	// ------------------------------------------------------
	// Resources
	|	SUM(Accounts.Amount)                  AS Amount
	// ------------------------------------------------------
	|INTO
	|	Table_GeneralJournalAnalyticsDimensions_Accounts_COGS
	|FROM
	|	Table_GeneralJournalAnalyticsDimensions_Accounts_COGS_Amount AS Accounts
	|GROUP BY
	|	Accounts.COGSAccount,
	|	Accounts.Class,
	|	Accounts.Project";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_GeneralJournalAnalyticsDimensions_Accounts_COGS_Difference_Amount(TablesList)
	
	// Add GeneralJournalAnalyticsDimensions difference COGS amount table to document structure.
	TablesList.Insert("Table_GeneralJournalAnalyticsDimensions_Accounts_COGS_Difference_Amount", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // COGS accounts selection
	// ------------------------------------------------------
	// Dimensions
	|	COGS_Dimensions.COGSAccount                      AS COGSAccount,
	// ------------------------------------------------------
	// Resources
	|	COGS_Dimensions.Amount                           AS Amount
	// ------------------------------------------------------
	|INTO
	|	Table_GeneralJournalAnalyticsDimensions_Accounts_COGS_Difference_Amount
	|FROM
	|	Table_GeneralJournal_Accounts_COGS AS COGS_Dimensions
	|	LEFT JOIN Document.SalesReturn AS SalesReturn
	|		ON True
	|WHERE
	|	SalesReturn.Ref = &Ref
	|	AND // Amount > 0
	|		COGS_Dimensions.Amount > 0
	|
	|UNION ALL
	|
	|SELECT // COGS Dimensions accounts selection
	// ------------------------------------------------------
	// Dimensions
	|	COGS_Dimensions.COGSAccount                      AS COGSAccount,
	// ------------------------------------------------------
	// Resources
	|	COGS_Dimensions.Amount * -1                      AS Amount
	// ------------------------------------------------------
	|FROM
	|	Table_GeneralJournalAnalyticsDimensions_Accounts_COGS AS COGS_Dimensions
	|	LEFT JOIN Document.SalesReturn AS SalesReturn
	|		ON True
	|WHERE
	|	SalesReturn.Ref = &Ref
	|	AND // Amount > 0
	|		COGS_Dimensions.Amount > 0";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_GeneralJournalAnalyticsDimensions_Accounts_COGS_Difference(TablesList)
	
	// Add GeneralJournalAnalyticsDimensions difference COGS table to document structure.
	TablesList.Insert("Table_GeneralJournalAnalyticsDimensions_Accounts_COGS_Difference", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // Dimensions difference selection
	// ------------------------------------------------------
	// Dimensions
	|	DimensionsDifference.COGSAccount           AS COGSAccount,
	// ------------------------------------------------------
	// Resources
	|	SUM(DimensionsDifference.Amount)           AS Amount
	// ------------------------------------------------------
	|INTO
	|	Table_GeneralJournalAnalyticsDimensions_Accounts_COGS_Difference
	|FROM
	|	Table_GeneralJournalAnalyticsDimensions_Accounts_COGS_Difference_Amount AS DimensionsDifference
	|GROUP BY
	|	DimensionsDifference.COGSAccount";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_GeneralJournalAnalyticsDimensions_Accounts_InvOrExp_Quantity(TablesList)
	
	// Add GeneralJournalAnalyticsDimensions InvOrExp accounts table to document structure.
	TablesList.Insert("Table_GeneralJournalAnalyticsDimensions_Accounts_InvOrExp_Quantity", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // InvOrExp accounts selection
	// ------------------------------------------------------
	// Dimensions
	|	Accounts.InvOrExpAccount              AS InvOrExpAccount,
	|	Accounts.Product                      AS Product,
	|	Accounts.Class                        AS Class,
	|	Accounts.Project                      AS Project,
	|	Accounts.Type                         AS Type,
	// ------------------------------------------------------
	// Resources
	|	SUM(Accounts.Quantity)                AS QuantityRequested
	// ------------------------------------------------------
	|INTO
	|	Table_GeneralJournalAnalyticsDimensions_Accounts_InvOrExp_Quantity
	|FROM
	|	Table_GeneralJournal_LineItems AS Accounts
	|WHERE
    |   Accounts.Product.Type = VALUE(Enum.InventoryTypes.Inventory)
	|GROUP BY
	|	Accounts.InvOrExpAccount,
	|	Accounts.Product,
	|	Accounts.Class,
	|	Accounts.Project,
	|	Accounts.Type";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_GeneralJournalAnalyticsDimensions_Accounts_InvOrExp_Amount(TablesList)
	
	// Add GeneralJournalAnalyticsDimensions InvOrExp accounts table to document structure.
	TablesList.Insert("Table_GeneralJournalAnalyticsDimensions_Accounts_InvOrExp_Amount", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // FIFO
	// ------------------------------------------------------
	// Dimensions
	|	Accounts_FIFO.InvOrExpAccount         AS InvOrExpAccount,
	|	Accounts_FIFO.Class                   AS Class,
	|	Accounts_FIFO.Project                 AS Project,
	// ------------------------------------------------------
	// Resources
	|	CAST ( // Format(LastCost * QuantityRequested, ""ND=17; NFD=2"")
	|		 ItemLastCosts.Cost * Accounts_FIFO.QuantityRequested
	|		 AS NUMBER (17, 2))               AS Amount
	// ------------------------------------------------------
	|INTO
	|	Table_GeneralJournalAnalyticsDimensions_Accounts_InvOrExp_Amount
	|FROM
	|	Table_GeneralJournalAnalyticsDimensions_Accounts_InvOrExp_Quantity AS Accounts_FIFO
	|	LEFT JOIN Table_ItemLastCosts_SliceLast AS ItemLastCosts
	|		ON  ItemLastCosts.Product = Accounts_FIFO.Product
	|WHERE
	|	Accounts_FIFO.Type = VALUE(Enum.InventoryCosting.FIFO)
	|	AND Accounts_FIFO.QuantityRequested > 0
	|
	|UNION ALL
	|
	|SELECT // WeightedAverage
	// ------------------------------------------------------
	// Dimensions
	|	Account_WAve.InvOrExpAccount          AS InvOrExpAccount,
	|	Account_WAve.Class                    AS Class,
	|	Account_WAve.Project                  AS Project,
	// ------------------------------------------------------
	// Resources
	|	CASE
	|		WHEN ISNULL(Balance_WAve.Quantity, 0) > 0
	|		// The balance is still active.
	|		THEN CAST ( // Format(Amount * QuantityReceipt / Quantity, ""ND=17; NFD=2"")
	|			 ISNULL(Balance_WAve.Amount, 0) * Account_WAve.QuantityRequested / Balance_WAve.Quantity
	|			 AS NUMBER (17, 2))
	|		ELSE CAST ( // Format(LastCost * QuantityRequested, ""ND=17; NFD=2"")
	|			 ItemLastCosts.Cost * Account_WAve.QuantityRequested
	|			 AS NUMBER (17, 2))
	|	END                                   AS Amount
	// ------------------------------------------------------
	// Attributes
	// ------------------------------------------------------
	|FROM
	|	Table_GeneralJournalAnalyticsDimensions_Accounts_InvOrExp_Quantity AS Account_WAve
	|	LEFT JOIN Table_InventoryJournal_Balance_Quantity AS Balance_WAve
	|		ON  Balance_WAve.Product  = Account_WAve.Product
	|		AND Balance_WAve.Location = VALUE(Catalog.Locations.EmptyRef)
	|	LEFT JOIN Table_ItemLastCosts_SliceLast AS ItemLastCosts
	|		ON  ItemLastCosts.Product = Account_WAve.Product
	|WHERE
	|	Account_WAve.Type = VALUE(Enum.InventoryCosting.WeightedAverage)
	|	AND // Amount > 0
	|	CASE
	|		WHEN ISNULL(Balance_WAve.Quantity, 0) > 0
	|		// The balance is still active.
	|		THEN CAST ( // Format(Amount * QuantityReceipt / Quantity, ""ND=17; NFD=2"")
	|			 ISNULL(Balance_WAve.Amount, 0) * Account_WAve.QuantityRequested / Balance_WAve.Quantity
	|			 AS NUMBER (17, 2))
	|		ELSE CAST ( // Format(LastCost * QuantityRequested, ""ND=17; NFD=2"")
	|			 ItemLastCosts.Cost * Account_WAve.QuantityRequested
	|			 AS NUMBER (17, 2))
	|	END > 0";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_GeneralJournalAnalyticsDimensions_Accounts_InvOrExp(TablesList)
	
	// Add GeneralJournalAnalyticsDimensions InvOrExp accounts table to document structure.
	TablesList.Insert("Table_GeneralJournalAnalyticsDimensions_Accounts_InvOrExp", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // InvOrExp accounts selection
	// ------------------------------------------------------
	// Dimensions
	|	Accounts.InvOrExpAccount              AS InvOrExpAccount,
	|	Accounts.Class                        AS Class,
	|	Accounts.Project                      AS Project,
	// ------------------------------------------------------
	// Resources
	|	SUM(Accounts.Amount)                  AS Amount
	// ------------------------------------------------------
	|INTO
	|	Table_GeneralJournalAnalyticsDimensions_Accounts_InvOrExp
	|FROM
	|	Table_GeneralJournalAnalyticsDimensions_Accounts_InvOrExp_Amount AS Accounts
	|GROUP BY
	|	Accounts.InvOrExpAccount,
	|	Accounts.Class,
	|	Accounts.Project";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_GeneralJournalAnalyticsDimensions_Accounts_InvOrExp_Difference_Amount(TablesList)
	
	// Add GeneralJournalAnalyticsDimensions difference InvOrExp amount table to document structure.
	TablesList.Insert("Table_GeneralJournalAnalyticsDimensions_Accounts_InvOrExp_Difference_Amount", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // InvOrExp accounts selection
	// ------------------------------------------------------
	// Dimensions
	|	InvOrExp_Dimensions.InvOrExpAccount                  AS InvOrExpAccount,
	// ------------------------------------------------------
	// Resources
	|	InvOrExp_Dimensions.Amount                           AS Amount
	// ------------------------------------------------------
	|INTO
	|	Table_GeneralJournalAnalyticsDimensions_Accounts_InvOrExp_Difference_Amount
	|FROM
	|	Table_GeneralJournal_Accounts_InvOrExp AS InvOrExp_Dimensions
	|	LEFT JOIN Document.SalesReturn AS SalesReturn
	|		ON True
	|WHERE
	|	SalesReturn.Ref = &Ref
	|	AND // Amount > 0
	|		InvOrExp_Dimensions.Amount > 0
	|
	|UNION ALL
	|
	|SELECT // InvOrExp Dimensions accounts selection
	// ------------------------------------------------------
	// Dimensions
	|	InvOrExp_Dimensions.InvOrExpAccount                  AS InvOrExpAccount,
	// ------------------------------------------------------
	// Resources
	|	InvOrExp_Dimensions.Amount * -1                      AS Amount
	// ------------------------------------------------------
	|FROM
	|	Table_GeneralJournalAnalyticsDimensions_Accounts_InvOrExp AS InvOrExp_Dimensions
	|	LEFT JOIN Document.SalesReturn AS SalesReturn
	|		ON True
	|WHERE
	|	SalesReturn.Ref = &Ref
	|	AND // Amount > 0
	|		InvOrExp_Dimensions.Amount > 0";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_GeneralJournalAnalyticsDimensions_Accounts_InvOrExp_Difference(TablesList)
	
	// Add GeneralJournalAnalyticsDimensions difference InvOrExp table to document structure.
	TablesList.Insert("Table_GeneralJournalAnalyticsDimensions_Accounts_InvOrExp_Difference", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // Dimensions difference selection
	// ------------------------------------------------------
	// Dimensions
	|	DimensionsDifference.InvOrExpAccount       AS InvOrExpAccount,
	// ------------------------------------------------------
	// Resources
	|	SUM(DimensionsDifference.Amount)           AS Amount
	// ------------------------------------------------------
	|INTO
	|	Table_GeneralJournalAnalyticsDimensions_Accounts_InvOrExp_Difference
	|FROM
	|	Table_GeneralJournalAnalyticsDimensions_Accounts_InvOrExp_Difference_Amount AS DimensionsDifference
	|GROUP BY
	|	DimensionsDifference.InvOrExpAccount";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_GeneralJournalAnalyticsDimensions_Transactions(TablesList)
	
	// Add GeneralJournalAnalyticsDimensionsTransactions table to document structure.
	TablesList.Insert("Table_GeneralJournalAnalyticsDimensions_Transactions", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // Expense: Accounts receivable
	// ------------------------------------------------------
	// Standard attributes
	|	SalesReturn.Ref                       AS Recorder,
	|	SalesReturn.Date                      AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Accounting attributes
	|	SalesReturn.ARAccount                 AS Account,
	// ------------------------------------------------------
	// Dimensions
	|	SalesReturn.Company                   AS Company,
	|	NULL                                  AS Class,
	|	NULL                                  AS Project,
	// ------------------------------------------------------
	// Resources
	|	SalesReturn.DocumentTotalRC           AS AmountRC,
	// ------------------------------------------------------
	// Attributes
	|	1                                     AS JournalEntryIntNum,
	|	True                                  AS JournalEntryMainRec
	// ------------------------------------------------------
	|INTO Table_GeneralJournalAnalyticsDimensions_Transactions
	|FROM
	|	Document.SalesReturn AS SalesReturn
	|WHERE
	|	SalesReturn.Ref = &Ref
	|	AND // Amount > 0
	|		(SalesReturn.DocumentTotal > 0
	|	  OR SalesReturn.DocumentTotalRC > 0)
	|
	|UNION ALL
	|
	|SELECT // Expense: Discount
	// ------------------------------------------------------
	// Standard attributes
	|	SalesReturn.Ref                       AS Recorder,
	|	SalesReturn.Date                      AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Accounting attributes
	|	CASE
	|		WHEN ISNULL(Constants.DiscountsAccount, VALUE(ChartOfAccounts.ChartOfAccounts.EmptyRef)) = VALUE(ChartOfAccounts.ChartOfAccounts.EmptyRef)
	|		THEN Constants.ExpenseAccount     // Default expense account
	|		ELSE Constants.DiscountsAccount   // Default discount account
	|	END                                   AS Account,
	// ------------------------------------------------------
	// Dimensions
	|	SalesReturn.Company                   AS Company,
	|	NULL                                  AS Class,
	|	NULL                                  AS Project,
	// ------------------------------------------------------
	// Resources
	|	CAST( // Format(-Discount * ExchangeRate, ""ND=17; NFD=2"")
	|		-SalesReturn.Discount *
	|		 CASE WHEN SalesReturn.ExchangeRate > 0
	|			  THEN SalesReturn.ExchangeRate
	|			  ELSE 1 END
	|		 AS NUMBER (17, 2))               AS AmountRC,
	// ------------------------------------------------------
	// Attributes
	|	1                                     AS JournalEntryIntNum,
	|	False                                 AS JournalEntryMainRec
	// ------------------------------------------------------
	|FROM
	|	Document.SalesReturn AS SalesReturn
	|	LEFT JOIN Constants AS Constants
	|		ON True
	|WHERE
	|	SalesReturn.Ref = &Ref
	|	AND // Discount > 0
	|		-SalesReturn.Discount > 0
	|
	|UNION ALL
	|
	|SELECT // Receipt: Shipping
	// ------------------------------------------------------
	// Standard attributes
	|	SalesReturn.Ref                       AS Recorder,
	|	SalesReturn.Date                      AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Accounting attributes
	|	CASE
	|		WHEN ISNULL(Constants.ShippingExpenseAccount, VALUE(ChartOfAccounts.ChartOfAccounts.EmptyRef)) = VALUE(ChartOfAccounts.ChartOfAccounts.EmptyRef)
	|		THEN Constants.IncomeAccount           // Default income account
	|		ELSE Constants.ShippingExpenseAccount  // Default shipping expense account
	|	END                                   AS Account,
	// ------------------------------------------------------
	// Dimensions
	|	SalesReturn.Company                   AS Company,
	|	NULL                                  AS Class,
	|	NULL                                  AS Project,
	// ------------------------------------------------------
	// Resources
	|	CAST( // Format(Shipping * ExchangeRate, ""ND=17; NFD=2"")
	|		SalesReturn.Shipping *
	|		CASE WHEN SalesReturn.ExchangeRate > 0
	|			 THEN SalesReturn.ExchangeRate
	|			 ELSE 1 END
	|		AS NUMBER (17, 2))                AS AmountRC,
	// ------------------------------------------------------
	// Attributes
	|	1                                     AS JournalEntryIntNum,
	|	False                                 AS JournalEntryMainRec
	// ------------------------------------------------------
	|FROM
	|	Document.SalesReturn AS SalesReturn
	|	LEFT JOIN Constants AS Constants
	|		ON True
	|WHERE
	|	SalesReturn.Ref = &Ref
	|	AND // Shipping > 0
	|		SalesReturn.Shipping > 0
	|
	|UNION ALL
	|
	|SELECT // Receipt: Sales tax
	// ------------------------------------------------------
	// Standard attributes
	|	SalesReturn.Ref                       AS Recorder,
	|	SalesReturn.Date                      AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Accounting attributes
	|	CASE
	|		WHEN ISNULL(Constants.TaxPayableAccount, VALUE(ChartOfAccounts.ChartOfAccounts.EmptyRef)) = VALUE(ChartOfAccounts.ChartOfAccounts.EmptyRef)
	|		THEN Constants.IncomeAccount      // Default income account
	|		ELSE Constants.TaxPayableAccount  // Default tax payable account
	|	END                                   AS Account,
	// ------------------------------------------------------
	// Dimensions
	|	SalesReturn.Company                   AS Company,
	|	NULL                                  AS Class,
	|	NULL                                  AS Project,
	// ------------------------------------------------------
	// Resources
	|	CAST( // Format(SalesTax * ExchangeRate, ""ND=17; NFD=2"")
	|		SalesReturn.SalesTax *
	|		CASE WHEN SalesReturn.ExchangeRate > 0
	|			 THEN SalesReturn.ExchangeRate
	|			 ELSE 1 END
	|		AS NUMBER (17, 2))                AS AmountRC,
	// ------------------------------------------------------
	// Attributes
	|	1                                     AS JournalEntryIntNum,
	|	False                                 AS JournalEntryMainRec
	// ------------------------------------------------------
	|FROM
	|	Document.SalesReturn AS SalesReturn
	|	LEFT JOIN Constants AS Constants
	|		ON True
	|WHERE
	|	SalesReturn.Ref = &Ref
	|	AND // SalesTax > 0
	|		SalesReturn.SalesTax > 0
	|
	|UNION ALL
	|
	|SELECT // Receipt: Income
	// ------------------------------------------------------
	// Standard attributes
	|	SalesReturn.Ref                       AS Recorder,
	|	SalesReturn.Date                      AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Accounting attributes
	|	Income.IncomeAccount                  AS Account,
	// ------------------------------------------------------
	// Dimensions
	|	SalesReturn.Company                   AS Company,
	|	Income.Class                          AS Class,
	|	Income.Project                        AS Project,
	// ------------------------------------------------------
	// Resources
	|	CAST( // Format(Amount * ExchangeRate, ""ND=17; NFD=2"")
	|		Income.Amount *
	|		CASE WHEN SalesReturn.ExchangeRate > 0
	|			 THEN SalesReturn.ExchangeRate
	|			 ELSE 1 END
	|		AS NUMBER (17, 2))                AS AmountRC,
	// ------------------------------------------------------
	// Attributes
	|	1                                     AS JournalEntryIntNum,
	|	False                                 AS JournalEntryMainRec
	// ------------------------------------------------------
	|FROM
	|	Table_GeneralJournalAnalyticsDimensions_Accounts_Income AS Income
	|	LEFT JOIN Document.SalesReturn AS SalesReturn
	|		ON True
	|WHERE
	|	SalesReturn.Ref = &Ref
	|	AND // Amount > 0
	|		Income.Amount > 0
	|
	|UNION ALL
	|
	|SELECT // Receipt: Income (difference)
	// ------------------------------------------------------
	// Standard attributes
	|	SalesReturn.Ref                       AS Recorder,
	|	SalesReturn.Date                      AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Accounting attributes
	|	Income.IncomeAccount                  AS Account,
	// ------------------------------------------------------
	// Dimensions
	|	SalesReturn.Company                   AS Company,
	|	NULL                                  AS Class,
	|	NULL                                  AS Project,
	// ------------------------------------------------------
	// Resources
	|	Income.Amount                         AS AmountRC,
	// ------------------------------------------------------
	// Attributes
	|	1                                     AS JournalEntryIntNum,
	|	False                                 AS JournalEntryMainRec
	// ------------------------------------------------------
	|FROM
	|	Table_GeneralJournalAnalyticsDimensions_Accounts_Income_Difference	AS Income
	|	LEFT JOIN Document.SalesReturn AS SalesReturn
	|		ON True
	|WHERE
	|	SalesReturn.Ref = &Ref
	|	AND // Amount <> 0
	|		Income.Amount <> 0
	|
	|UNION ALL
	|
	|SELECT // Expense: COGS
	// ------------------------------------------------------
	// Standard attributes
	|	SalesReturn.Ref                       AS Recorder,
	|	SalesReturn.Date                      AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Accounting attributes
	|	COGS.COGSAccount                      AS Account,
	// ------------------------------------------------------
	// Dimensions
	|	SalesReturn.Company                   AS Company,
	|	COGS.Class                            AS Class,
	|	COGS.Project                          AS Project,
	// ------------------------------------------------------
	// Resources
	|	COGS.Amount                           AS AmountRC,
	// ------------------------------------------------------
	// Attributes
	|	2                                     AS JournalEntryIntNum,
	|	True                                  AS JournalEntryMainRec
	// ------------------------------------------------------
	|FROM
	|	Table_GeneralJournalAnalyticsDimensions_Accounts_COGS AS COGS
	|	LEFT JOIN Document.SalesReturn AS SalesReturn
	|		ON True
	|WHERE
	|	SalesReturn.Ref = &Ref
	|	AND // Amount > 0
	|		COGS.Amount > 0
	|
	|UNION ALL
	|
	|SELECT // Expense: COGS (difference)
	// ------------------------------------------------------
	// Standard attributes
	|	SalesReturn.Ref                       AS Recorder,
	|	SalesReturn.Date                      AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Accounting attributes
	|	COGS.COGSAccount                      AS Account,
	// ------------------------------------------------------
	// Dimensions
	|	SalesReturn.Company                   AS Company,
	|	NULL                                  AS Class,
	|	NULL                                  AS Project,
	// ------------------------------------------------------
	// Resources
	|	COGS.Amount                           AS AmountRC,
	// ------------------------------------------------------
	// Attributes
	|	2                                     AS JournalEntryIntNum,
	|	True                                  AS JournalEntryMainRec
	// ------------------------------------------------------
	|FROM
	|	Table_GeneralJournalAnalyticsDimensions_Accounts_COGS_Difference AS COGS
	|	LEFT JOIN Document.SalesReturn AS SalesReturn
	|		ON True
	|WHERE
	|	SalesReturn.Ref = &Ref
	|	AND // Amount <> 0
	|		COGS.Amount <> 0
	|
	|UNION ALL
	|
	|SELECT // Receipt: Inventory or Expenses accounts
	// ------------------------------------------------------
	// Standard attributes
	|	SalesReturn.Ref                       AS Recorder,
	|	SalesReturn.Date                      AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Accounting attributes
	|	InvOrExp.InvOrExpAccount              AS Account,
	// ------------------------------------------------------
	// Dimensions
	|	SalesReturn.Company                   AS Company,
	|	InvOrExp.Class                        AS Class,
	|	InvOrExp.Project                      AS Project,
	// ------------------------------------------------------
	// Resources
	|	InvOrExp.Amount                       AS AmountRC,
	// ------------------------------------------------------
	// Attributes
	|	2                                     AS JournalEntryIntNum,
	|	False                                 AS JournalEntryMainRec
	// ------------------------------------------------------
	|FROM
	|	Table_GeneralJournalAnalyticsDimensions_Accounts_InvOrExp AS InvOrExp
	|	LEFT JOIN Document.SalesReturn AS SalesReturn
	|		ON True
	|WHERE
	|	SalesReturn.Ref = &Ref
	|	AND // Amount > 0
	|		InvOrExp.Amount > 0
	|
	|UNION ALL
	|
	|SELECT // Receipt: Inventory or Expenses accounts (difference)
	// ------------------------------------------------------
	// Standard attributes
	|	SalesReturn.Ref                       AS Recorder,
	|	SalesReturn.Date                      AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Accounting attributes
	|	InvOrExp.InvOrExpAccount              AS Account,
	// ------------------------------------------------------
	// Dimensions
	|	SalesReturn.Company                   AS Company,
	|	NULL                                  AS Class,
	|	NULL                                  AS Project,
	// ------------------------------------------------------
	// Resources
	|	InvOrExp.Amount                       AS AmountRC,
	// ------------------------------------------------------
	// Attributes
	|	2                                     AS JournalEntryIntNum,
	|	False                                 AS JournalEntryMainRec
	// ------------------------------------------------------
	|FROM
	|	Table_GeneralJournalAnalyticsDimensions_Accounts_InvOrExp_Difference AS InvOrExp
	|	LEFT JOIN Document.SalesReturn AS SalesReturn
	|		ON True
	|WHERE
	|	SalesReturn.Ref = &Ref
	|	AND // Amount <> 0
	|		InvOrExp.Amount <> 0";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_GeneralJournalAnalyticsDimensions(TablesList)
	
	// Add GeneralJournalAnalyticsDimensions table to document structure.
	TablesList.Insert("Table_GeneralJournalAnalyticsDimensions", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // Transactions
	// ------------------------------------------------------
	// Standard attributes
	|	Transaction.Recorder                  AS Recorder,
	|	Transaction.Period                    AS Period,
	|	Transaction.LineNumber                AS LineNumber,
	|	Transaction.RecordType                AS RecordType,
	|	Transaction.Active                    AS Active,
	// ------------------------------------------------------
	// Accounting attributes
	|	Transaction.Account                   AS Account,
	// ------------------------------------------------------
	// Dimensions
	|	Transaction.Company                   AS Company,
	|	Transaction.Class                     AS Class,
	|	Transaction.Project                   AS Project,
	// ------------------------------------------------------
	// Resources
	|	Transaction.AmountRC                  AS AmountRC,
	// ------------------------------------------------------
	// Attributes
	|	Transaction.JournalEntryIntNum        AS JournalEntryIntNum,
	|	Transaction.JournalEntryMainRec       AS JournalEntryMainRec
	// ------------------------------------------------------
	|FROM
	|	Table_GeneralJournalAnalyticsDimensions_Transactions AS Transaction";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

//--//GJ--


// Query for document data.
Function Query_CashFlowData_Difference_Amount(TablesList)
	
	// Add CashFlowData_Difference_Amount table to document structure.
	TablesList.Insert("Table_CashFlowData_Difference_Amount", TablesList.Count());
	
	// Collect cash flow data.
	QueryText =
	"SELECT // Difference amount
	// ------------------------------------------------------
	// Resources
	|	CASE
	|		WHEN Transaction.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN Transaction.AmountRC                   
	|		ELSE Transaction.AmountRC * -1
	|	END                                                  AS AmountRC
	// ------------------------------------------------------
	|INTO Table_CashFlowData_Difference_Amount
	|FROM
	|	Table_GeneralJournalAnalyticsDimensions_Transactions AS Transaction
	|	LEFT JOIN Constant.TaxPayableAccount AS TaxPayableAccount
	|		ON True
	|WHERE
	|	Transaction.Account.AccountType <> VALUE(Enum.AccountTypes.AccountsReceivable)
	|	AND Transaction.Account.AccountType <> VALUE(Enum.AccountTypes.AccountsPayable)
	|	AND Transaction.Account.AccountType <> VALUE(Enum.AccountTypes.Income)
	|	AND Transaction.Account.AccountType <> VALUE(Enum.AccountTypes.CostOfSales)
	|	AND Transaction.Account.AccountType <> VALUE(Enum.AccountTypes.Expense)
	|	AND Transaction.Account.AccountType <> VALUE(Enum.AccountTypes.OtherIncome)
	|	AND Transaction.Account.AccountType <> VALUE(Enum.AccountTypes.OtherExpense)
	|	AND Transaction.Account.AccountType <> VALUE(Enum.AccountTypes.IncomeTaxExpense)
	|	AND Transaction.Account <> TaxPayableAccount.Value";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_CashFlowData_Difference(TablesList)
	
	// Add CashFlowData_Difference table to document structure.
	TablesList.Insert("Table_CashFlowData_Difference", TablesList.Count());
	
	// Collect cash flow data.
	QueryText =
	"SELECT // Difference
	// ------------------------------------------------------
	// Resources
	|	SUM(Transaction.AmountRC)            AS AmountRC
	// ------------------------------------------------------
	|INTO Table_CashFlowData_Difference
	|FROM
	|	Table_CashFlowData_Difference_Amount AS Transaction";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_CashFlowData(TablesList)
	
	// Add CashFlowData table to document structure.
	TablesList.Insert("Table_CashFlowData", TablesList.Count());
	
	// Collect cash flow data.
	QueryText =
	"SELECT // Transactions of Assets
	// ------------------------------------------------------
	// Standard attributes
	|	Transaction.Recorder                  AS Recorder,
	|	Transaction.Period                    AS Period,
	|	Transaction.LineNumber                AS LineNumber,
	|	Transaction.RecordType                AS RecordType,
	|	Transaction.Active                    AS Active,
	// ------------------------------------------------------
	// Accounting attributes
	|	Transaction.Account                   AS Account,
	// ------------------------------------------------------
	// Dimensions
	|	Transaction.Company                   AS Company,
	|	SalesReturn.Ref                       AS Document,
	|	SalesReturn.SalesPerson               AS SalesPerson,
	|	Transaction.Class                     AS Class,
	|	Transaction.Project                   AS Project,
	// ------------------------------------------------------
	// Resources
	|	Transaction.AmountRC                  AS AmountRC,
	// ------------------------------------------------------
	// Attributes
	|	NULL                                  AS PaymentMethod
	// ------------------------------------------------------
	|FROM
	|	Table_GeneralJournalAnalyticsDimensions_Transactions AS Transaction
	|	LEFT JOIN Document.SalesReturn AS SalesReturn
	|		ON SalesReturn.Ref = &Ref
	|	LEFT JOIN Constant.TaxPayableAccount AS TaxPayableAccount
	|		ON True
	|WHERE
	|	Transaction.Account.AccountType <> VALUE(Enum.AccountTypes.AccountsReceivable)
	|	AND Transaction.Account.AccountType <> VALUE(Enum.AccountTypes.AccountsPayable)
	|	AND Transaction.Account.AccountType <> VALUE(Enum.AccountTypes.Income)
	|	AND Transaction.Account.AccountType <> VALUE(Enum.AccountTypes.CostOfSales)
	|	AND Transaction.Account.AccountType <> VALUE(Enum.AccountTypes.Expense)
	|	AND Transaction.Account.AccountType <> VALUE(Enum.AccountTypes.OtherIncome)
	|	AND Transaction.Account.AccountType <> VALUE(Enum.AccountTypes.OtherExpense)
	|	AND Transaction.Account.AccountType <> VALUE(Enum.AccountTypes.IncomeTaxExpense)
	|	AND Transaction.Account <> TaxPayableAccount.Value
	|
	|UNION ALL
	|
	|SELECT // Accounts Receivable (difference)
	// ------------------------------------------------------
	// Standard attributes
	|	SalesReturn.Ref                       AS Recorder,
	|	SalesReturn.Date                      AS Period,
	|	0                                     AS LineNumber,
	|	CASE
	|		WHEN TransactionAR.AmountRC > 0
	|			THEN VALUE(AccumulationRecordType.Expense)
	|		ELSE VALUE(AccumulationRecordType.Receipt)
	|	END                                   AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Accounting attributes
	|	SalesReturn.ARAccount                 AS Account,
	// ------------------------------------------------------
	// Dimensions
	|	SalesReturn.Company                   AS Company,
	|	SalesReturn.Ref                       AS Document,
	|	SalesReturn.SalesPerson               AS SalesPerson,
	|	NULL                                  AS Class,
	|	NULL                                  AS Project,
	// ------------------------------------------------------
	// Resources
	|	CASE
	|		WHEN TransactionAR.AmountRC > 0
	|			THEN TransactionAR.AmountRC                
	|		ELSE TransactionAR.AmountRC * -1
	|	END                                   AS AmountRC,
	// ------------------------------------------------------
	// Attributes
	|	NULL                                  AS PaymentMethod
	// ------------------------------------------------------
	|FROM
	|	Table_CashFlowData_Difference AS TransactionAR
	|	LEFT JOIN Document.SalesReturn AS SalesReturn
	|		ON SalesReturn.Ref = &Ref
	|WHERE
	|	TransactionAR.AmountRC <> 0";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction


// Query for document data.
Function Query_ProjectData_Accounts_Income(TablesList)
	
	// Add ProjectData income accounts table to document structure.
	TablesList.Insert("Table_ProjectData_Accounts_Income", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // Income accounts selection
	// ------------------------------------------------------
	// Dimensions
	|	Accounts.IncomeAccount                AS IncomeAccount,
	|	Accounts.Project                      AS Project,
	// ------------------------------------------------------
	// Resources
	|	SUM(Accounts.Amount)                  AS Amount
	// ------------------------------------------------------
	|INTO
	|	Table_ProjectData_Accounts_Income
	|FROM
	|	Table_GeneralJournal_LineItems AS Accounts
	|GROUP BY
	|	Accounts.IncomeAccount,
	|	Accounts.Project";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_ProjectData_Accounts_COGS_Quantity(TablesList)
	
	// Add ProjectData COGS accounts table to document structure.
	TablesList.Insert("Table_ProjectData_Accounts_COGS_Quantity", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // COGS accounts selection
	// ------------------------------------------------------
	// Dimensions
	|	Accounts.COGSAccount                  AS COGSAccount,
	|	Accounts.Project                      AS Project,
	|	Accounts.Product                      AS Product,
	|	Accounts.Location                     AS Location,
	|	Accounts.Type                         AS Type,
	// ------------------------------------------------------
	// Resources
	|	SUM(Accounts.Quantity)                AS QuantityRequested
	// ------------------------------------------------------
	|INTO
	|	Table_ProjectData_Accounts_COGS_Quantity
	|FROM
	|	Table_GeneralJournal_LineItems AS Accounts
	|GROUP BY
	|	Accounts.COGSAccount,
	|	Accounts.Project,
	|	Accounts.Product,
	|	Accounts.Location,
	|	Accounts.Type";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_ProjectData_Accounts_COGS_Amount(TablesList)
	
	// Add ProjectData COGS accounts table to document structure.
	TablesList.Insert("Table_ProjectData_Accounts_COGS_Amount", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // FIFO
	// ------------------------------------------------------
	// Dimensions
	|	Accounts_FIFO.COGSAccount             AS COGSAccount,
	|   Accounts_FIFO.Project                 AS Project,
	// ------------------------------------------------------
	// Resources
	|	CAST ( // Format(LastCost * QuantityRequested, ""ND=17; NFD=2"")
	|		 ItemLastCosts.Cost * Accounts_FIFO.QuantityRequested
	|		 AS NUMBER (17, 2))               AS Amount
	// ------------------------------------------------------
	|INTO
	|	Table_ProjectData_Accounts_COGS_Amount
	|FROM
	|	Table_ProjectData_Accounts_COGS_Quantity AS Accounts_FIFO
	|	LEFT JOIN Table_ItemLastCosts_SliceLast AS ItemLastCosts
	|		ON  ItemLastCosts.Product = Accounts_FIFO.Product
	|WHERE
	|	Accounts_FIFO.Type = VALUE(Enum.InventoryCosting.FIFO)
	|	AND Accounts_FIFO.QuantityRequested > 0
	|
	|UNION ALL
	|
	|SELECT // WeightedAverage
	// ------------------------------------------------------
	// Dimensions
	|	Account_WAve.COGSAccount              AS Accounts,
	|   Account_WAve.Project                  AS Project,
	// ------------------------------------------------------
	// Resources
	|	CASE
	|		WHEN ISNULL(Balance_WAve.Quantity, 0) > 0
	|		// The balance is still active.
	|		THEN CAST ( // Format(Amount * QuantityReceipt / Quantity, ""ND=17; NFD=2"")
	|			 ISNULL(Balance_WAve.Amount, 0) * Account_WAve.QuantityRequested / Balance_WAve.Quantity
	|			 AS NUMBER (17, 2))
	|		ELSE CAST ( // Format(LastCost * QuantityRequested, ""ND=17; NFD=2"")
	|			 ItemLastCosts.Cost * Account_WAve.QuantityRequested
	|			 AS NUMBER (17, 2))
	|	END                                   AS Amount
	// ------------------------------------------------------
	// Attributes
	// ------------------------------------------------------
	|FROM
	|	Table_ProjectData_Accounts_COGS_Quantity AS Account_WAve
	|	LEFT JOIN Table_InventoryJournal_Balance_Quantity AS Balance_WAve
	|		ON  Balance_WAve.Product  = Account_WAve.Product
	|		AND Balance_WAve.Location = VALUE(Catalog.Locations.EmptyRef)
	|	LEFT JOIN Table_ItemLastCosts_SliceLast AS ItemLastCosts
	|		ON  ItemLastCosts.Product = Account_WAve.Product
	|WHERE
	|	Account_WAve.Type = VALUE(Enum.InventoryCosting.WeightedAverage)
	|	AND // Amount > 0
	|	CASE
	|		WHEN ISNULL(Balance_WAve.Quantity, 0) > 0
	|		// The balance is still active.
	|		THEN CAST ( // Format(Amount * QuantityReceipt / Quantity, ""ND=17; NFD=2"")
	|			 ISNULL(Balance_WAve.Amount, 0) * Account_WAve.QuantityRequested / Balance_WAve.Quantity
	|			 AS NUMBER (17, 2))
	|		ELSE CAST ( // Format(LastCost * QuantityRequested, ""ND=17; NFD=2"")
	|			 ItemLastCosts.Cost * Account_WAve.QuantityRequested
	|			 AS NUMBER (17, 2))
	|	END > 0";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_ProjectData_Accounts_COGS(TablesList)
	
	// Add ProjectData COGS accounts table to document structure.
	TablesList.Insert("Table_ProjectData_Accounts_COGS", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // COGS accounts selection
	// ------------------------------------------------------
	// Dimensions
	|	Accounts.COGSAccount                  AS COGSAccount,
	|	Accounts.Project                      AS Project,
	// ------------------------------------------------------
	// Resources
	|	SUM(Accounts.Amount)                  AS Amount
	// ------------------------------------------------------
	|INTO
	|	Table_ProjectData_Accounts_COGS
	|FROM
	|	Table_ProjectData_Accounts_COGS_Amount AS Accounts
	|GROUP BY
	|	Accounts.COGSAccount,
	|	Accounts.Project";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_ProjectData(TablesList)
	
	// Add ProjectData table to document structure.
	TablesList.Insert("Table_ProjectData", TablesList.Count());
	
	// Collect project data.
	QueryText =
	"SELECT // Rec: Income
	// ------------------------------------------------------
	// Standard attributes
	|	SalesReturn.Ref                       AS Recorder,
	|	SalesReturn.Date                      AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Dimensions
	|	Income.IncomeAccount                  AS Account,
	|	Income.Project                        AS Project,
	// ------------------------------------------------------
	// Resources
	|	CAST( // Format(Amount * ExchangeRate, ""ND=17; NFD=2"")
	|       -1 *
	|		Income.Amount *
	|		CASE WHEN SalesReturn.ExchangeRate > 0
	|			 THEN SalesReturn.ExchangeRate
	|			 ELSE 1 END
	|		AS NUMBER (17, 2))                AS Amount
	// ------------------------------------------------------
	// Attributes
	// ------------------------------------------------------
	|FROM
	|	Table_ProjectData_Accounts_Income AS Income
	|	LEFT JOIN Document.SalesReturn AS SalesReturn
	|		ON True
	|WHERE
	|	SalesReturn.Ref = &Ref
	|	AND // Amount > 0
	|		Income.Amount > 0
	|
	|UNION ALL
	|
	|SELECT // Rec: Discount
	// ------------------------------------------------------
	// Standard attributes
	|	SalesReturn.Ref                       AS Recorder,
	|	SalesReturn.Date                      AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Dimensions
	|	Income.IncomeAccount                  AS Account,
	|	Income.Project                        AS Project,
	// ------------------------------------------------------
	// Resources
	|	CAST( // Format(Discount * IncomeByProject / IncomeTotal * ExchangeRate, ""ND=17; NFD=2"")
	|       -1 *
	|		CASE WHEN SalesReturn.LineSubtotal > 0
	|			 THEN SalesReturn.Discount * Income.Amount / SalesReturn.LineSubtotal
	|			 ELSE 0 END *
	|		CASE WHEN SalesReturn.ExchangeRate > 0
	|			 THEN SalesReturn.ExchangeRate
	|			 ELSE 1 END
	|		AS NUMBER (17, 2))                AS Amount
	// ------------------------------------------------------
	// Attributes
	// ------------------------------------------------------
	|FROM
	|	Table_ProjectData_Accounts_Income AS Income
	|	LEFT JOIN Document.SalesReturn AS SalesReturn
	|		ON True
	|WHERE
	|	SalesReturn.Ref = &Ref
	|	AND // Discount > 0
	|		-1 *
	|		CASE WHEN SalesReturn.LineSubtotal > 0
	|			 THEN SalesReturn.Discount * Income.Amount / SalesReturn.LineSubtotal
	|			 ELSE 0 END > 0
	|
	|UNION ALL
	|
	|SELECT // Exp: COGS
	// ------------------------------------------------------
	// Standard attributes
	|	SalesReturn.Ref                       AS Recorder,
	|	SalesReturn.Date                      AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Dimensions
	|	COGS.COGSAccount                      AS Account,
	|	COGS.Project                          AS Project,
	// ------------------------------------------------------
	// Resources
	|   -1 *
	|	COGS.Amount                           AS Amount
	// ------------------------------------------------------
	// Attributes
	// ------------------------------------------------------
	|FROM
	|	Table_ProjectData_Accounts_COGS AS COGS
	|	LEFT JOIN Document.SalesReturn AS SalesReturn
	|		ON True
	|WHERE
	|	SalesReturn.Ref = &Ref
	|	AND // Amount > 0
	|		COGS.Amount > 0";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_ClassData_Accounts_Income(TablesList)
	
	// Add ClassData income accounts table to document structure.
	TablesList.Insert("Table_ClassData_Accounts_Income", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // Income accounts selection
	// ------------------------------------------------------
	// Dimensions
	|	Accounts.IncomeAccount                AS IncomeAccount,
	|	Accounts.Class                        AS Class,
	// ------------------------------------------------------
	// Resources
	|	SUM(Accounts.Amount)                  AS Amount
	// ------------------------------------------------------
	|INTO
	|	Table_ClassData_Accounts_Income
	|FROM
	|	Table_GeneralJournal_LineItems AS Accounts
	|GROUP BY
	|	Accounts.IncomeAccount,
	|	Accounts.Class";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_ClassData_Accounts_COGS_Quantity(TablesList)
	
	// Add ClassData COGS accounts table to document structure.
	TablesList.Insert("Table_ClassData_Accounts_COGS_Quantity", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // COGS accounts selection
	// ------------------------------------------------------
	// Dimensions
	|	Accounts.COGSAccount                  AS COGSAccount,
	|	Accounts.Class                        AS Class,
	|	Accounts.Product                      AS Product,
	|	Accounts.Location                     AS Location,
	|	Accounts.Type                         AS Type,
	// ------------------------------------------------------
	// Resources
	|	SUM(Accounts.Quantity)                AS QuantityRequested
	// ------------------------------------------------------
	|INTO
	|	Table_ClassData_Accounts_COGS_Quantity
	|FROM
	|	Table_GeneralJournal_LineItems AS Accounts
	|GROUP BY
	|	Accounts.COGSAccount,
	|	Accounts.Class,
	|	Accounts.Product,
	|	Accounts.Location,
	|	Accounts.Type";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_ClassData_Accounts_COGS_Amount(TablesList)
	
	// Add ClassData COGS accounts table to document structure.
	TablesList.Insert("Table_ClassData_Accounts_COGS_Amount", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // FIFO
	// ------------------------------------------------------
	// Dimensions
	|	Accounts_FIFO.COGSAccount             AS COGSAccount,
	|   Accounts_FIFO.Class                   AS Class,
	// ------------------------------------------------------
	// Resources
	|	CAST ( // Format(LastCost * QuantityRequested, ""ND=17; NFD=2"")
	|		 ItemLastCosts.Cost * Accounts_FIFO.QuantityRequested
	|		 AS NUMBER (17, 2))               AS Amount
	// ------------------------------------------------------
	|INTO
	|	Table_ClassData_Accounts_COGS_Amount
	|FROM
	|	Table_ClassData_Accounts_COGS_Quantity AS Accounts_FIFO
	|	LEFT JOIN Table_ItemLastCosts_SliceLast AS ItemLastCosts
	|		ON  ItemLastCosts.Product = Accounts_FIFO.Product
	|WHERE
	|	Accounts_FIFO.Type = VALUE(Enum.InventoryCosting.FIFO)
	|	AND Accounts_FIFO.QuantityRequested > 0
	|
	|UNION ALL
	|
	|SELECT // WeightedAverage
	// ------------------------------------------------------
	// Dimensions
	|	Account_WAve.COGSAccount              AS Accounts,
	|   Account_WAve.Class                    AS Class,
	// ------------------------------------------------------
	// Resources
	|	CASE
	|		WHEN ISNULL(Balance_WAve.Quantity, 0) > 0
	|		// The balance is still active.
	|		THEN CAST ( // Format(Amount * QuantityReceipt / Quantity, ""ND=17; NFD=2"")
	|			 ISNULL(Balance_WAve.Amount, 0) * Account_WAve.QuantityRequested / Balance_WAve.Quantity
	|			 AS NUMBER (17, 2))
	|		ELSE CAST ( // Format(LastCost * QuantityRequested, ""ND=17; NFD=2"")
	|			 ItemLastCosts.Cost * Account_WAve.QuantityRequested
	|			 AS NUMBER (17, 2))
	|	END                                   AS Amount
	// ------------------------------------------------------
	// Attributes
	// ------------------------------------------------------
	|FROM
	|	Table_ClassData_Accounts_COGS_Quantity AS Account_WAve
	|	LEFT JOIN Table_InventoryJournal_Balance_Quantity AS Balance_WAve
	|		ON  Balance_WAve.Product  = Account_WAve.Product
	|		AND Balance_WAve.Location = VALUE(Catalog.Locations.EmptyRef)
	|	LEFT JOIN Table_ItemLastCosts_SliceLast AS ItemLastCosts
	|		ON  ItemLastCosts.Product = Account_WAve.Product
	|WHERE
	|	Account_WAve.Type = VALUE(Enum.InventoryCosting.WeightedAverage)
	|	AND // Amount > 0
	|	CASE
	|		WHEN ISNULL(Balance_WAve.Quantity, 0) > 0
	|		// The balance is still active.
	|		THEN CAST ( // Format(Amount * QuantityReceipt / Quantity, ""ND=17; NFD=2"")
	|			 ISNULL(Balance_WAve.Amount, 0) * Account_WAve.QuantityRequested / Balance_WAve.Quantity
	|			 AS NUMBER (17, 2))
	|		ELSE CAST ( // Format(LastCost * QuantityRequested, ""ND=17; NFD=2"")
	|			 ItemLastCosts.Cost * Account_WAve.QuantityRequested
	|			 AS NUMBER (17, 2))
	|	END > 0";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_ClassData_Accounts_COGS(TablesList)
	
	// Add ClassData COGS accounts table to document structure.
	TablesList.Insert("Table_ClassData_Accounts_COGS", TablesList.Count());
	
	// Collect accounting data.
	QueryText =
	"SELECT // COGS accounts selection
	// ------------------------------------------------------
	// Dimensions
	|	Accounts.COGSAccount                  AS COGSAccount,
	|	Accounts.Class                        AS Class,
	// ------------------------------------------------------
	// Resources
	|	SUM(Accounts.Amount)                  AS Amount
	// ------------------------------------------------------
	|INTO
	|	Table_ClassData_Accounts_COGS
	|FROM
	|	Table_ClassData_Accounts_COGS_Amount AS Accounts
	|GROUP BY
	|	Accounts.COGSAccount,
	|	Accounts.Class";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_ClassData(TablesList)
	
	// Add ClassData table to document structure.
	TablesList.Insert("Table_ClassData", TablesList.Count());
	
	// Collect Class data.
	QueryText =
	"SELECT // Rec: Income
	// ------------------------------------------------------
	// Standard attributes
	|	SalesReturn.Ref                       AS Recorder,
	|	SalesReturn.Date                      AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Dimensions
	|	Income.IncomeAccount                  AS Account,
	|	Income.Class                          AS Class,
	// ------------------------------------------------------
	// Resources
	|	CAST( // Format(Amount * ExchangeRate, ""ND=17; NFD=2"")
	|       -1 *
	|		Income.Amount *
	|		CASE WHEN SalesReturn.ExchangeRate > 0
	|			 THEN SalesReturn.ExchangeRate
	|			 ELSE 1 END
	|		AS NUMBER (17, 2))                AS Amount
	// ------------------------------------------------------
	// Attributes
	// ------------------------------------------------------
	|FROM
	|	Table_ClassData_Accounts_Income AS Income
	|	LEFT JOIN Document.SalesReturn AS SalesReturn
	|		ON True
	|WHERE
	|	SalesReturn.Ref = &Ref
	|	AND // Amount > 0
	|		Income.Amount > 0
	|
	|UNION ALL
	|
	|SELECT // Rec: Discount
	// ------------------------------------------------------
	// Standard attributes
	|	SalesReturn.Ref                       AS Recorder,
	|	SalesReturn.Date                      AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Dimensions
	|	Income.IncomeAccount                  AS Account,
	|	Income.Class                          AS Class,
	// ------------------------------------------------------
	// Resources
	|	CAST( // Format(Discount * IncomeByClass / IncomeTotal * ExchangeRate, ""ND=17; NFD=2"")
	|       -1 *
	|		CASE WHEN SalesReturn.LineSubtotal > 0
	|			 THEN SalesReturn.Discount * Income.Amount / SalesReturn.LineSubtotal
	|			 ELSE 0 END *
	|		CASE WHEN SalesReturn.ExchangeRate > 0
	|			 THEN SalesReturn.ExchangeRate
	|			 ELSE 1 END
	|		AS NUMBER (17, 2))                AS Amount
	// ------------------------------------------------------
	// Attributes
	// ------------------------------------------------------
	|FROM
	|	Table_ClassData_Accounts_Income AS Income
	|	LEFT JOIN Document.SalesReturn AS SalesReturn
	|		ON True
	|WHERE
	|	SalesReturn.Ref = &Ref
	|	AND // Discount > 0
	|		-1 *
	|		CASE WHEN SalesReturn.LineSubtotal > 0
	|			 THEN SalesReturn.Discount * Income.Amount / SalesReturn.LineSubtotal
	|			 ELSE 0 END > 0
	|
	|UNION ALL
	|
	|SELECT // Exp: COGS
	// ------------------------------------------------------
	// Standard attributes
	|	SalesReturn.Ref                       AS Recorder,
	|	SalesReturn.Date                      AS Period,
	|	0                                     AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	True                                  AS Active,
	// ------------------------------------------------------
	// Dimensions
	|	COGS.COGSAccount                      AS Account,
	|	COGS.Class                            AS Class,
	// ------------------------------------------------------
	// Resources
	|   -1 *
	|	COGS.Amount                           AS Amount
	// ------------------------------------------------------
	// Attributes
	// ------------------------------------------------------
	|FROM
	|	Table_ClassData_Accounts_COGS AS COGS
	|	LEFT JOIN Document.SalesReturn AS SalesReturn
	|		ON True
	|WHERE
	|	SalesReturn.Ref = &Ref
	|	AND // Amount > 0
	|		COGS.Amount > 0";
	
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

// Query for Sales Tax.
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
	|	-1 * (SalesReturn.Ref.DocumentTotalRC - SalesReturn.Ref.SalesTax) AS GrossSale,
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
	|	SalesReturn.Ref = &Ref
	|	AND SalesReturn.Ref.UseAvatax = FALSE";
		
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
//	|	-1 * SalesReturn.SalesTax AS AmountRC
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

