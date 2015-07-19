
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// custom fields
	
	CF1Type = Constants.CF1CType.Get();
	CF2Type = Constants.CF2CType.Get();
	CF3Type = Constants.CF3CType.Get();
	CF4Type = Constants.CF4CType.Get();
	CF5Type = Constants.CF5CType.Get();
	
	If CF1Type = "None" Then
		Items.CF1Num.Visible = False;
		Items.CF1String.Visible = False;
	ElsIf CF1Type = "Number" Then
		Items.CF1Num.Visible = True;
		Items.CF1String.Visible = False;
		Items.CF1Num.Title = Constants.CF1CName.Get();
	ElsIf CF1Type = "String" Then
	    Items.CF1Num.Visible = False;
		Items.CF1String.Visible = True;
		Items.CF1String.Title = Constants.CF1CName.Get();
	ElsIf CF1Type = "" Then
		Items.CF1Num.Visible = False;
		Items.CF1String.Visible = False;
	EndIf;
	
	If CF2Type = "None" Then
		Items.CF2Num.Visible = False;
		Items.CF2String.Visible = False;
	ElsIf CF2Type = "Number" Then
		Items.CF2Num.Visible = True;
		Items.CF2String.Visible = False;
		Items.CF2Num.Title = Constants.CF2CName.Get();
	ElsIf CF2Type = "String" Then
	    Items.CF2Num.Visible = False;
		Items.CF2String.Visible = True;
		Items.CF2String.Title = Constants.CF2CName.Get();
	ElsIf CF2Type = "" Then
		Items.CF2Num.Visible = False;
		Items.CF2String.Visible = False;
	EndIf;
	
	If CF3Type = "None" Then
		Items.CF3Num.Visible = False;
		Items.CF3String.Visible = False;
	ElsIf CF3Type = "Number" Then
		Items.CF3Num.Visible = True;
		Items.CF3String.Visible = False;
		Items.CF3Num.Title = Constants.CF3CName.Get();
	ElsIf CF3Type = "String" Then
	    Items.CF3Num.Visible = False;
		Items.CF3String.Visible = True;
		Items.CF3String.Title = Constants.CF3CName.Get();
	ElsIf CF3Type = "" Then
		Items.CF3Num.Visible = False;
		Items.CF3String.Visible = False;
	EndIf;
	
	If CF4Type = "None" Then
		Items.CF4Num.Visible = False;
		Items.CF4String.Visible = False;
	ElsIf CF4Type = "Number" Then
		Items.CF4Num.Visible = True;
		Items.CF4String.Visible = False;
		Items.CF4Num.Title = Constants.CF4CName.Get();
	ElsIf CF4Type = "String" Then
	    Items.CF4Num.Visible = False;
		Items.CF4String.Visible = True;
		Items.CF4String.Title = Constants.CF4CName.Get();
	ElsIf CF4Type = "" Then
		Items.CF4Num.Visible = False;
		Items.CF4String.Visible = False;
	EndIf;
	
	If CF5Type = "None" Then
		Items.CF5Num.Visible = False;
		Items.CF5String.Visible = False;
	ElsIf CF5Type = "Number" Then
		Items.CF5Num.Visible = True;
		Items.CF5String.Visible = False;
		Items.CF5Num.Title = Constants.CF5CName.Get();
	ElsIf CF5Type = "String" Then
	    Items.CF5Num.Visible = False;
		Items.CF5String.Visible = True;
		Items.CF5String.Title = Constants.CF5CName.Get();
	ElsIf CF5Type = "" Then
		Items.CF5Num.Visible = False;
		Items.CF5String.Visible = False;
	EndIf;

	// end custom fields
	
	If Constants.CFOToday.Get() Then
		Items.FormExportVendors.Visible = True;
		Items.FormImportVendors.Visible = True;
	EndIf;
	
	Transactions.Parameters.SetParameterValue("Company", Catalogs.Companies.EmptyRef());
	
EndProcedure

&AtClient
Procedure ContractorsOnActivateRow(Item) 
	
	CurrentRow = Items.List.CurrentRow;
	
	If CurrentRow = Undefined Then
		Transactions.Parameters.SetParameterValue("Company", PredefinedValue("Catalog.Companies.EmptyRef"));
	Else
		Transactions.Parameters.SetParameterValue("Company", CurrentRow);
	EndIf;
	
EndProcedure

&AtClient
Procedure TransactionsSelection(Item, SelectedRow, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	ShowValue(, GetDocumentOfTransaction()); 
	
EndProcedure

&AtServer
Function GetDocumentOfTransaction()
	
	Return Items.Transactions.CurrentRow.Document;	
	
EndFunction

&AtServerNoContext
Function GetCompanyTypes(Company)
	
	Return New Structure("Customer, Vendor, UseIR, UseShipment",
																Company.Customer,
																Company.Vendor,
																Constants.EnhancedInventoryReceiving.Get(),
																Constants.EnhancedInventoryShipping.Get()); 	
	
EndFunction

&AtClient
Procedure AfterChooseFromMenu(DocumentName = Undefined, CompanyRef) Export
	
	If DocumentName <> Undefined Then
		
	ParametersStructure = New Structure;
	ParametersStructure.Insert("Company", CompanyRef); 
	
	OpenForm("Document." + DocumentName.Value + ".ObjectForm", ParametersStructure);
	
	EndIf;
	
EndProcedure


&AtClient
Procedure CommandCreate(Command)
	
	CurrentRow = Items.List.CurrentRow; 
	
	If CurrentRow = Undefined Or TypeOf(CurrentRow) <> Type("CatalogRef.Companies") Then
		
		Return;
		
	Else
		
		CommandList = New ValueList;
		CompanyTypes = GetCompanyTypes(CurrentRow);
		
		If GeneralFunctions.IsCurrentUserInRole("BankAccounting") Then
			CommandList.Add("Deposit",             "Deposit");
			CommandList.Add("GeneralJournalEntry", "General journal entry");
			If CompanyTypes.Vendor Then	
				CommandList.Add("Check",               "Payment (Check)");
			EndIf;	
		
		ElsIf CompanyTypes.Customer And Not CompanyTypes.Vendor Then
			CommandList.Add("Quote",               "Quote");
			CommandList.Add("SalesInvoice",        "Sales invoice");
			CommandList.Add("SalesOrder",          "Sales order");
			If CompanyTypes.UseShipment Then 
			CommandList.Add("Shipment",            "Shipment");
			EndIf;
			CommandList.Add("TimeTrack",           "Time tracking");
			CommandList.Add("CashReceipt",         "Cash receipt");
			CommandList.Add("CashSale",            "Cash sale");
			CommandList.Add("SalesReturn",         "Credit memo");
			CommandList.Add("Deposit",             "Deposit");
			CommandList.Add("GeneralJournalEntry", "General journal entry");
			CommandList.Add("InvoicePayment",      "Bill payment (Check)");
		ElsIf Not CompanyTypes.Customer And CompanyTypes.Vendor Then 
			CommandList.Add("PurchaseInvoice",     "Bill");
			CommandList.Add("PurchaseOrder",       "Purchase order");
			If CompanyTypes.UseIR Then
			CommandList.Add("ItemReceipt",         "Item receipt");
			EndIf;
			CommandList.Add("InvoicePayment",      "Bill payment (Check)");
			CommandList.Add("Check",               "Payment (Check)");
			CommandList.Add("GeneralJournalEntry", "General journal entry");
			CommandList.Add("PurchaseReturn",      "Purchase return");
			CommandList.Add("CashReceipt",         "Cash receipt");
			CommandList.Add("Deposit",             "Deposit");
		ElsIf CompanyTypes.Customer And CompanyTypes.Vendor Then 
			CommandList.Add("Quote",               "Quote");
			CommandList.Add("SalesInvoice",        "Sales invoice");
			CommandList.Add("PurchaseInvoice",     "Bill");
			CommandList.Add("SalesOrder",          "Sales order");
			If CompanyTypes.UseShipment Then 
			CommandList.Add("Shipment",            "Shipment");
			EndIf;
			CommandList.Add("PurchaseOrder",       "Purchase order");
			If CompanyTypes.UseIR Then
			CommandList.Add("ItemReceipt",         "Item receipt");
			EndIf;
			CommandList.Add("TimeTrack",           "Time tracking");
			CommandList.Add("CashReceipt",         "Cash receipt");
			CommandList.Add("InvoicePayment",      "Bill payment (Check)");
			CommandList.Add("CashSale",            "Cash sale");
			CommandList.Add("Check",               "Payment (Check)");
			CommandList.Add("SalesReturn",         "Credit memo");
			CommandList.Add("PurchaseReturn",      "Purchase return");
			CommandList.Add("Deposit",             "Deposit");
			CommandList.Add("GeneralJournalEntry", "General journal entry");
		EndIf;	
		
		Res = New NotifyDescription("AfterChooseFromMenu", ThisObject, CurrentRow); 
		ShowChooseFromMenu(Res, CommandList, Items.TransactionsCommandCreate);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ExportVendors(Command)
	
	Spreadsheet = New SpreadsheetDocument;
	ExportVendorsAtServer(Spreadsheet);
	
	Structure = GeneralFunctions.GetExcelFile("Vendors", Spreadsheet);
	
	GetFile(Structure.Address, StrReplace(Structure.FileName, ".xlsx",".acs"), True); 
	
EndProcedure

&AtClient
Procedure ImportVendors(Command)
	
	If ListIsEmpty() Then
		Notify = New NotifyDescription("ExcelFileUpload", ThisForm);
		
		BeginPutFile(Notify, "", "*.acs", True, ThisForm.UUID);
	Else
		ShowMessageBox(,NStr("en = 'This function available for the empty list only!'"));
	EndIf;
	
EndProcedure

&AtClient
Procedure Refresh(Command)
	
	//PerformanceMeasurementClientServer.StartTimeMeasurement("CustomerVendorCenter Refresh");
	
	Items.List.Refresh();
	Items.Transactions.Refresh();
	
EndProcedure


#Region EXCEL

&AtServer
Function ExportVendorsAtServer(Spreadsheet)
	
	Template = Catalogs.Companies.GetTemplate("CFO_VendorsPrintForm");
	
	Header = Template.GetArea("Header");
	Spreadsheet.Put(Header);
	
	SelectCompanies = Catalogs.Companies.Select();
	
	While SelectCompanies.Next() Do 
		If SelectCompanies.Vendor Then
			
			Line = Template.GetArea("Line");
			
			Line.Parameters.Code           = SelectCompanies.Code;
			Line.Parameters.Description    = SelectCompanies.Description;
			Line.Parameters.FullName	   = SelectCompanies.FullName;
			Line.Parameters.ExpenseAccount = SelectCompanies.ExpenseAccount.Code;
			Line.Parameters.Vendor1099	   = ?(SelectCompanies.Vendor1099, "Yes", "");
			Line.Parameters.FederalIDType  = SelectCompanies.FederalIDType;
			Line.Parameters.USTaxID        = SelectCompanies.USTaxID;
			Line.Parameters.Employee       = ?(SelectCompanies.Employee, "Yes", "");
			Line.Parameters.ImportMatch    = SelectCompanies.ImportMatch;
			
			SelectAddresses = Catalogs.Addresses.Select(, SelectCompanies.Ref); 
			
			While SelectAddresses.Next() Do
				If SelectAddresses.DefaultBilling Then
					
					Line.Parameters.AddressLine1   = SelectAddresses.AddressLine1;
					Line.Parameters.AddressLine2   = SelectAddresses.AddressLine2;
					Line.Parameters.City           = SelectAddresses.City;
					Line.Parameters.State          = SelectAddresses.State.Code;
					Line.Parameters.ZIP            = SelectAddresses.ZIP;
					
				EndIf;
			EndDo;
			
			Spreadsheet.Put(Line);
			
		EndIf;
	EndDo;
	
EndFunction

&AtClient
Procedure ExcelFileUpload(Result, Address, SelectedFileName, AdditionalParameters) Export
	
	If Find(SelectedFileName, ".acs") = 0 Then
		ShowMessageBox(, NStr("en = 'Please upload a valid ACS file (.acs)'"));
		Return;
	EndIf;
	
	If ValueIsFilled(Address) Then
		ShowUserNotification(NStr("en = 'Reading file with  ACS...'"));
		
		Errors = False;
		ImportData(Address, Errors);
	EndIf;
	
	If Not Errors Then
		Items.List.Refresh();
		ShowMessageBox(,NStr("en = 'Done!'"));
	EndIf;
	
EndProcedure

&AtServer
Procedure ImportData(TempStorageAddress, Errors)
	
	BinaryData = GetFromTempStorage(TempStorageAddress);

	TempFileName = GetTempFileName("xls");
	BinaryData.Write(TempFileName);
	
	Try
		COMExcel   = New COMObject("Excel.Application");
		Excel      = COMExcel.Application.WorkBooks.Open(TempFileName);
		ExcelSheet = Excel.Sheets(1);
	Except
		ErrorDescription = ErrorDescription();
		CommonUseClientServer.MessageToUser(NStr("en = 'An error occurred. Details:'") + ErrorDescription);
		
		Errors = True;
		Return;
	EndTry;
			
	//Clear collections
	VT = New ValueTable();
	VT.Columns.Add("Code",           New TypeDescription("String"));
	VT.Columns.Add("Description",    New TypeDescription("String"));
	VT.Columns.Add("FullName",       New TypeDescription("String"));
	VT.Columns.Add("ExpenseAccount", New TypeDescription("ChartOfAccountsRef.ChartOfAccounts"));
	VT.Columns.Add("Vendor1099",     New TypeDescription("Boolean"));
	VT.Columns.Add("FederalIDType",  New TypeDescription("EnumRef.FederalIDType"));
	VT.Columns.Add("USTaxID",        New TypeDescription("String"));
	VT.Columns.Add("Employee",       New TypeDescription("Boolean"));
	VT.Columns.Add("ImportMatch",    New TypeDescription("String"));
	VT.Columns.Add("AddressLine1",   New TypeDescription("String"));
	VT.Columns.Add("AddressLine2",   New TypeDescription("String"));
	VT.Columns.Add("City",           New TypeDescription("String"));
	VT.Columns.Add("State",          New TypeDescription("CatalogRef.States"));
	VT.Columns.Add("ZIP",            New TypeDescription("String"));
	
	CurrentRowNumber = 1;	
	LastRowNumber    = ExcelSheet.Cells.SpecialCells(11).Row;
	
	While True Do
		
		CurrentRowNumber = CurrentRowNumber + 1;
		
		//-------------------------------------------------------------------------------------
		_Code           = TrimAll(ExcelSheet.Cells(CurrentRowNumber,  1).Text);
		_Description    = TrimAll(ExcelSheet.Cells(CurrentRowNumber,  2).Text);
		_FullName       = TrimAll(ExcelSheet.Cells(CurrentRowNumber,  3).Text);
		_ExpenseAccount = TrimAll(ExcelSheet.Cells(CurrentRowNumber,  4).Text);
		_Vendor1099     = TrimAll(ExcelSheet.Cells(CurrentRowNumber,  5).Text);
		_FederalIDType  = TrimAll(ExcelSheet.Cells(CurrentRowNumber,  6).Text);
		_USTaxID        = TrimAll(ExcelSheet.Cells(CurrentRowNumber,  7).Text);
		_Employee       = TrimAll(ExcelSheet.Cells(CurrentRowNumber,  8).Text);
		_ImportMatch    = TrimAll(ExcelSheet.Cells(CurrentRowNumber,  9).Text);
		_AddressLine1   = TrimAll(ExcelSheet.Cells(CurrentRowNumber, 10).Text);
		_AddressLine2   = TrimAll(ExcelSheet.Cells(CurrentRowNumber, 11).Text);
		_City           = TrimAll(ExcelSheet.Cells(CurrentRowNumber, 12).Text);
		_State          = TrimAll(ExcelSheet.Cells(CurrentRowNumber, 13).Text);
		_ZIP            = TrimAll(ExcelSheet.Cells(CurrentRowNumber, 14).Text);
		
		//-------------------------------------------------------------------------------------
		RowVT = VT.Add();
		RowVT.Code                = _Code;
		RowVT.Description         = _Description;
		RowVT.FullName            = _FullName;
		RowVT.ExpenseAccount      = ChartsOfAccounts.ChartOfAccounts.FindByCode(_ExpenseAccount);
		RowVT.Vendor1099          = ?(Lower(_Vendor1099) = "yes", True, False);
		Try
			RowVT.FederalIDType   = Enums.FederalIDType[_FederalIDType];
		Except
			RowVT.FederalIDType   = Enums.FederalIDType.EmptyRef();
		EndTry;
		RowVT.USTaxID             = _USTaxID;
		RowVT.Employee            = ?(Lower(_Employee) = "yes", True, False);
		RowVT.ImportMatch         = _ImportMatch;
		RowVT.AddressLine1        = _AddressLine1;
		RowVT.AddressLine2        = _AddressLine2;
		RowVT.City                = _City;
		RowVT.State               = Catalogs.States.FindByCode(_State);
		RowVT.ZIP                 = _ZIP;
				
		If CurrentRowNumber >= LastRowNumber Then
			Break;	
		EndIf;
		
	EndDo;
	
	Excel.Close();
	
	CreateVendors(VT, Errors);
	
EndProcedure

&AtServer
Procedure CreateVendors(VT, Errors)
		
	BeginTransaction(DataLockControlMode.Managed);
	//-------------------------------------------------------------------------------------------------	
	Try
		
		For each CurrentLine In VT Do
			
			//1.
			NewVendor = Catalogs.Companies.CreateItem();
			
			NewVendor.Code            = CurrentLine.Code;
			NewVendor.Description     = CurrentLine.Description;
			NewVendor.FullName        = CurrentLine.FullName;
			NewVendor.ExpenseAccount  = CurrentLine.ExpenseAccount;
			NewVendor.Vendor1099      = CurrentLine.Vendor1099;
			NewVendor.FederalIDType   = CurrentLine.FederalIDType;
			NewVendor.USTaxID         = CurrentLine.USTaxID;
			NewVendor.Employee        = CurrentLine.Employee;
			NewVendor.ImportMatch     = CurrentLine.ImportMatch;
			
			NewVendor.Vendor          = True;
			NewVendor.DefaultCurrency = Constants.DefaultCurrency.Get();
			NewVendor.Terms           = Catalogs.PaymentTerms.Net30;
			
			NewVendor.Write();
			
			//2.
			NewAddress = Catalogs.Addresses.CreateItem();
			
			NewAddress.AddressLine1    = CurrentLine.AddressLine1;
			NewAddress.AddressLine2    = CurrentLine.AddressLine2;
			NewAddress.City            = CurrentLine.City;
			NewAddress.State           = CurrentLine.State;
			NewAddress.ZIP             = CurrentLine.ZIP;
			
			NewAddress.Owner           = NewVendor.Ref;
			NewAddress.Description     = "Primary";
			NewAddress.DefaultBilling  = True;
			NewAddress.DefaultShipping = True;
			
			NewAddress.Write();
			
		EndDo;
		
	Except
		Errors = True;
		ErrorDescription = ErrorDescription();
		CommonUseClientServer.MessageToUser(CurrentLine.Code + " " + CurrentLine.Description + ": " + ErrorDescription);
	EndTry;
	//-------------------------------------------------------------------------------------------------
	If Errors Then
		If TransactionActive() Then
			RollbackTransaction();
		EndIf;
	Else
		CommitTransaction();
	EndIf;
	
	//Set last numbering for companies
	Query = New Query;
	Query.Text = 
		"SELECT
		|	MAX(Companies.Code) AS Code
		|FROM
		|	Catalog.Companies AS Companies";
	
	QueryResult = Query.Execute();
	
	SelectionDetailRecords = QueryResult.Select();
	
	While SelectionDetailRecords.Next() Do
		
		LastNumber = Catalogs.DocumentNumbering.Companies.GetObject();
		LastNumber.Number = SelectionDetailRecords.Code;
		LastNumber.Write();
		
	EndDo;
	
EndProcedure

#EndRegion

&AtServerNoContext
Function ListIsEmpty()
	
	Query = New Query;
	Query.Text = "SELECT
	             |	Companies.Ref AS Ref
	             |FROM
	             |	Catalog.Companies AS Companies";
	
	If Query.Execute().Select().Count() = 0 Then
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction


