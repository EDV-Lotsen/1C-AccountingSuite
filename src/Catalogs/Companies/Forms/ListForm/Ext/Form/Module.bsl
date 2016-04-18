
////////////////////////////////////////////////////////////////////////////////
#Region EVENTS_HANDLERS

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Set custom fields presentation.
	SetCustomFields();
	
	// Clear transactions table by default
	Transactions.Parameters.SetParameterValue("Company", Catalogs.Companies.EmptyRef());
	
	// Disable/Enable Objects functionality.
	DisableEnableObjects.SetConditionalAppearance(ThisObject);
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	DisableEnableObjectsClientServer.SetFilterCompaniesInArchive(ThisObject, HideDisabledCompanies);
	
EndProcedure

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region CONTROLS_EVENTS_HANDLERS

&AtClient
Procedure CompaniesOnActivateRow(Item) 
	
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

&AtClient
Procedure ShowDisabledCompaniesOnChange(Item)
	
	DisableEnableObjectsClientServer.SetFilterCompaniesInArchive(ThisObject, HideDisabledCompanies);
	
EndProcedure

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region COMMANDS_HANDLERS

&AtClient
Procedure CommandCreate(Command)
	
	CurrentRow = Items.List.CurrentRow; 
	
	If CurrentRow = Undefined Or TypeOf(CurrentRow) <> Type("CatalogRef.Companies") Then
		
		Return;
		
	Else
		
		CommandList = New ValueList;
		CompanyTypes = GetCompanyTypes(CurrentRow);
		
		If CompanyTypes.Customer And Not CompanyTypes.Vendor Then
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
Procedure AfterChooseFromMenu(DocumentName = Undefined, CompanyRef) Export
	
	If DocumentName <> Undefined Then
		
	ParametersStructure = New Structure;
	ParametersStructure.Insert("Company", CompanyRef); 
	
	OpenForm("Document." + DocumentName.Value + ".ObjectForm", ParametersStructure);
	
	EndIf;
	
EndProcedure

&AtClient
Procedure Refresh(Command)
	
	Items.List.Refresh();
	Items.Transactions.Refresh();
	
EndProcedure

&AtClient
Procedure DisableEnableCompanies(Command)
	
	DisableEnableObjectsClient.DisableEnableObjects(Items.List.SelectedRows,
	                                                ThisObject,
	                                                Type("CatalogRef.Companies"));
	
EndProcedure

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region PRIVATE_IMPLEMENTATION

&AtServer
Procedure SetCustomFields()
	
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

#EndRegion



