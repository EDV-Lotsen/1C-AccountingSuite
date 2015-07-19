
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	ActionType = Parameters.ActionType;
	FillAttributes();
	Date = CurrentDate();
	Date2 = CurrentDate();
	
	
	//Items.ActionType.ChoiceList.Add("DirectUpload","Direct upload");
	
EndProcedure

&AtClient
Procedure GreetingNext(Command)
	
	Notify = New NotifyDescription("FileUpload",ThisForm);

	BeginPutFile(Notify, "", "*.csv", True, ThisForm.UUID);
	
	If Attributes.Count() = 0 Then
		FillAttributes();
	EndIf;
	
	Items.MappingGroup.Title = FilePath;
	
	LoadFormDataOnServer("DataImportUserValue"+ActionType);
	
EndProcedure


&AtClient
Procedure FileUpload(Result, Address, SelectedFileName, AdditionalParameters) Export
	
	If (Find(Upper(SelectedFileName), ".CSV") = 0) And (Find(Upper(SelectedFileName), ".TXT") = 0) Then
		ShowMessageBox(, "Please upload a valid CSV file (.csv, .txt)");
		return;
	EndIf;
	FilePath = SelectedFileName;
	If ValueIsFilled(Address) Then
		ReadSourceFile(Address);
		//UploadTransactionsAtServer(Address);
	EndIf;
	
EndProcedure

&AtServer
Procedure ReadSourceFile(TempStorageAddress)
	
	BinaryData = GetFromTempStorage(TempStorageAddress);
	TempFileName = GetTempFileName("csv");
	BinaryData.Write(TempFileName);
	
	RowLimit = 4000;
	FileSizeLimit = 1000000;
	
	PreCheckPassed = True;
	CsvFileSize =  BinaryData.Size();
	If CsvFileSize > FileSizeLimit Then 
		Message("Error! File size bigger than "+FileSizeLimit+" bytes ("+CsvFileSize+"). Please split the file.");	
		PreCheckPassed = False;
	EndIf;
	
	// If read right into DP Form atribute "SourceText", then processing drops with error
	TmpSource = New TextDocument;
	TmpSource.Read(TempFileName);
	RowCount = TmpSource.LineCount();
	
	If RowCount > RowLimit Then
		Message("Error! File contains more than "+RowLimit+" rows ("+RowCount+"). Please split the file.");
		PreCheckPassed = False;
	EndIf;
	
	If Not PreCheckPassed Then 
		Message("Uploaded file must be less than "+FileSizeLimit+" bytes. File must contain less than "+RowLimit+" rows.");
		Return;
	EndIf;	
	
	FileContainDisallowesCharsMessage = "";
	for LineCount = 1 to RowCount Do
		CurrentLine = TmpSource.GetLine(LineCount);
		ErrorChar = FindDisallowedXMLCharacters(CurrentLine);
		If ErrorChar > 0 Then 
			FileContainDisallowesCharsMessage = FileContainDisallowesCharsMessage + " ERROR!!! Disallowed Characters in row: "+LineCount+ ". Position: "+ErrorChar + Chars.LF;
			//PreCheckPassed = False;
		EndIf;	
	EndDo;
	If FileContainDisallowesCharsMessage <> "" Then
		Message(FileContainDisallowesCharsMessage);
		Return;
	EndIf;
	
	SourceText.Read(TempFileName);
	RowCount = SourceText.LineCount();
	
	If RowCount < 1 Then
		ErrorText = NStr("en = 'The file has no data!'");
		Message(ErrorText);
		Return;
	EndIf;
	
	SourceAddress = Undefined;
	
	SourceAddress = FillAttributesAtServer(RowCount);
	
	If Not ValueIsFilled(SourceAddress) Then
		Return;
	EndIf;
	
	FillSourceView();
	Items.LoadSteps.CurrentPage = Items.LoadSteps.ChildItems.Mapping;

EndProcedure


&AtClient
Procedure FileStartPath(Item, InputData, StandardProcessing)
	
	//to remove
	
EndProcedure


&AtServer
Procedure UploadTransactionsAtServer(TempStorageAddress)
	BinaryData = GetFromTempStorage(TempStorageAddress);
	TempFileName = GetTempFileName("csv");
	BinaryData.Write(TempFileName);
	
	Try
		SourceText.Read(TempFileName);
	Except
		TextMessage = NStr("en = 'Can not read the file.'");
		CommonUseClientServer.MessageToUser(TextMessage);
		Return;
	EndTry;

	LineCountTotal = SourceText.LineCount();
	
	For LineNumber = 1 To LineCountTotal Do
		
	EndDo;
	
	
EndProcedure


&AtServer
Procedure FillAttributes()

	ThisCofA = ActionType = "Chart of accounts";
	ThisCustomers = ActionType = "CustomersVendors";
	ThisProducts = ActionType = "Items";
	ThisChecks = ActionType = "Checks";
	ThisDeposits = ActionType = "Deposits";
	ThisGJ = ActionType = "Journal entries";
	ThisExpensify = ActionType = "Expensify";
	ThisClasses = ActionType = "Classes";
	ThisPTerms = ActionType = "PaymentTerms";
	ThisPriceLevels = ActionType = "PriceLevels";
	ThisPO = ActionType = "PurchaseOrders";
	ThisBill = ActionType = "Bills";
	ThisIR = ActionType = "ItemReceipts";
	ThisBillPay = ActionType = "BillPayments";
	ThisSaleInvoice = ActionType = "SalesInvoice";
	ThisSalesRep = ActionType = "SalesRep";
	ThisSaleOrder = ActionType = "SalesOrder";
	ThisCashReceipt = ActionType = "CashReceipt";	
	ThisCreditMemo  = ActionType = "CreditMemo";
	ThisBankTransfer  = ActionType = "BankTransfer";
	ThisProjects  = ActionType = "Projects";
		
	Items.UpdateOption.Visible = ThisProducts or ThisCofA or ThisCustomers or ThisProjects;
	ThisObject.UpdateOption = "AllFields";
	
	Items.Date.Visible = ThisProducts;
	Items.Date2.Visible = ThisProducts;
	If ThisProducts Then
		Items.Date.Title = "Price list date";
		Items.Date2.Title = "Beg. bal. date";
	EndIf;
	
	Items.DataListExpensifyAccount.Visible = ThisExpensify;
	Items.DataListExpensifyAmount.Visible = ThisExpensify;
	Items.DataListExpensifyMemo.Visible = ThisExpensify;
			
	Items.DataListGJHeaderDate.Visible = ThisGJ;
	Items.DataListGJHeaderMemo.Visible = ThisGJ;
	Items.DataListGJHeaderRowNumber.Visible = ThisGJ;
	Items.DataListGJHeaderType.Visible = ThisGJ;
	Items.DataListGJHeaderAccount.Visible = ThisGJ;
	Items.DataListGJHeaderAmount.Visible = ThisGJ;
	Items.DataListGJHeaderClass.Visible = ThisGJ;
	Items.DataListGJHeaderLineMemo.Visible = ThisGJ;
		
	Items.DataListCheckBankAccount.Visible = ThisChecks;
	Items.DataListCheckDate.Visible = ThisChecks;
	Items.DataListCheckLineAccount.Visible = ThisChecks;
	Items.DataListCheckLineAmount.Visible = ThisChecks;
	Items.DataListCheckLineMemo.Visible = ThisChecks;
	Items.DataListCheckMemo.Visible = ThisChecks;
	Items.DataListCheckNumber.Visible = ThisChecks;
	Items.DataListCheckVendor.Visible = ThisChecks;
	Items.DataListCheckLineClass.Visible = ThisChecks;

	Items.DataListCofACode.Visible = ThisCofA;
	Items.DataListCofADescription.Visible = ThisCofA;
	Items.DataListCofAType.Visible = ThisCofA;
	Items.DataListCofAUpdate.Visible = ThisCofA;
	Items.DataListCofASubaccountOf.Visible = ThisCofA;
	Items.DataListCoACashFlowSection.Visible = ThisCofA;
	Items.DataListCofAMemo.Visible = ThisCofA;
		
	Items.DataListCustomerVendorTaxID.Visible = ThisCustomers;
	Items.DataListDefaultBillingAddress.Visible = ThisCustomers;
	Items.DataListDefaultShippingAddress.Visible = ThisCustomers;
	Items.DataListCustomerType.Visible = ThisCustomers;
	Items.DataListCustomerDescription.Visible = ThisCustomers;
	Items.DataListCustomerNotes.Visible = ThisCustomers;
	Items.DataListCustomerTerms.Visible = ThisCustomers;
	Items.DataListCustomerCF1String.Visible = ThisCustomers;
	Items.DataListCustomerCF2String.Visible = ThisCustomers;
	Items.DataListCustomerCF3String.Visible = ThisCustomers;
	Items.DataListCustomerCF4String.Visible = ThisCustomers;
	Items.DataListCustomerCF5String.Visible = ThisCustomers;
	Items.DataListCustomerCF1Num.Visible = ThisCustomers;
	Items.DataListCustomerCF2Num.Visible = ThisCustomers;
	Items.DataListCustomerCF3Num.Visible = ThisCustomers;
	Items.DataListCustomerCF4Num.Visible = ThisCustomers;
	Items.DataListCustomerCF5Num.Visible = ThisCustomers;
	Items.DataListCustomerWebsite.Visible = ThisCustomers;
	Items.DataListCustomerPriceLevel.Visible = ThisCustomers;
	Items.DataListCustomerSalesPerson.Visible = ThisCustomers;
	Items.DataListCustomerCode.Visible = ThisCustomers;
	Items.DataListCustomerFullName.Visible = ThisCustomers;
	Items.DataListCustomerVendor1099.Visible = ThisCustomers;
	Items.DataListCustomerEIN_SSN.Visible = ThisCustomers;
	Items.DataListCustomerIncomeAccount.Visible = ThisCustomers;
	Items.DataListCustomerExpenseAccount.Visible = ThisCustomers;
	Items.DataListCustomerEmployee.Visible = ThisCustomers;
	// billing
	Items.DataListCustomerAddressID.Visible = ThisCustomers;
	Items.DataListAddressSalutation.Visible = ThisCustomers;
	Items.DataListCustomerFirstName.Visible = ThisCustomers;
	Items.DataListCustomerMiddleName.Visible = ThisCustomers;
	Items.DataListCustomerLastName.Visible = ThisCustomers;
	Items.DataListAddressSuffix.Visible = ThisCustomers;
	Items.DataListAddressJobTitle.Visible = ThisCustomers;
	Items.DataListCustomerAddressLine1.Visible = ThisCustomers;
	Items.DataListCustomerAddressLine2.Visible = ThisCustomers;
	Items.DataListCustomerAddressLine3.Visible = ThisCustomers;
	Items.DataListCustomerCity.Visible = ThisCustomers;
	Items.DataListCustomerCountry.Visible = ThisCustomers;	
	Items.DataListCustomerEmail.Visible = ThisCustomers;
	Items.DatalistCustomerFax.Visible = ThisCustomers;
	Items.DataListCustomerPhone.Visible = ThisCustomers;
	Items.DataListCustomerCell.Visible = ThisCustomers;
	Items.DataListAddressSalesPerson.Visible = ThisCustomers;	
	Items.DataListCustomerState.Visible = ThisCustomers;
	Items.DataListCustomerZIP.Visible = ThisCustomers;
	Items.DataListCustomerAddressNotes.Visible = ThisCustomers;
	Items.DataListCustomerShippingAddressLine1.Visible = ThisCustomers;
	Items.DataListCustomerShippingAddressLine2.Visible = ThisCustomers;
	Items.DataListCustomerShippingAddressLine3.Visible = ThisCustomers;
	Items.DataListCustomerShippingCity.Visible = ThisCustomers;
	Items.DataListCustomerShippingState.Visible = ThisCustomers;	
	Items.DataListCustomerShippingCountry.Visible = ThisCustomers;
	Items.DataListCustomerShippingZIP.Visible = ThisCustomers;
	Items.DataListAddressCF1String.Visible = ThisCustomers;
	Items.DataListAddressCF2String.Visible = ThisCustomers;
	Items.DataListAddressCF3String.Visible = ThisCustomers;
	Items.DataListAddressCF4String.Visible = ThisCustomers;
	Items.DataListAddressCF5String.Visible = ThisCustomers;
	// billing

	Items.DataListProductCode.Visible = ThisProducts;
	Items.DataListProductDescription.Visible = ThisProducts;
	Items.DataListPurchaseDescription.Visible = ThisProducts;
	Items.DataListProductType.Visible = ThisProducts;
	Items.DataListProductIncomeAcct.Visible = ThisProducts;
	Items.DataListProductInvOrExpenseAcct.Visible = ThisProducts;
	Items.DataListProductCOGSAcct.Visible = ThisProducts;
	Items.DataListProductPrice.Visible = ThisProducts;
	Items.DataListProductCost.Visible = ThisProducts;
	Items.DataListProductQty.Visible = ThisProducts;
	Items.DataListProductValue.Visible = ThisProducts;
	Items.DataListProductCategory.Visible = ThisProducts;
	//Items.DataListProductUoM.Visible = ThisProducts;
	Items.DataListProductCF1String.Visible = ThisProducts;
	Items.DataListProductCF1Num.Visible = ThisProducts;
	Items.DataListProductCF2String.Visible = ThisProducts;
	Items.DataListProductCF2Num.Visible = ThisProducts;
    Items.DataListProductCF3String.Visible = ThisProducts;
	Items.DataListProductCF3Num.Visible = ThisProducts;
	Items.DataListProductCF4String.Visible = ThisProducts;
	Items.DataListProductCF4Num.Visible = ThisProducts;
    Items.DataListProductCF5String.Visible = ThisProducts;
	Items.DataListProductCF5Num.Visible = ThisProducts;
	Items.DataListProductUpdate.Visible = ThisProducts;
	Items.DataListProductParent.Visible = ThisProducts;
	Items.DataListProductPreferedVendor.Visible = ThisProducts;
	Items.DataListProductVendorCode.Visible = ThisProducts;
	Items.DataListProductTaxable.Visible = ThisProducts;
		
	Items.DataListDepositDate.Visible = ThisDeposits;
	Items.DataListDepositBankAccount.Visible = ThisDeposits;
	Items.DataListDepositMemo.Visible = ThisDeposits;
	Items.DataListDepositLineCompany.Visible = ThisDeposits;
	Items.DataListDepositLineAccount.Visible = ThisDeposits;
	Items.DataListDepositLineAmount.Visible = ThisDeposits;
	Items.DataListDepositLineClass.Visible = ThisDeposits;
	Items.DataListDepositLineMemo.Visible = ThisDeposits;
	
	Items.DataListClassName.Visible = ThisClasses;
	Items.DataListSubClassOf.Visible = ThisClasses;
	
	Items.DataListPTermsName.Visible = ThisPTerms;
	Items.DataListPTermsDays.Visible = ThisPTerms;
	Items.DataListPTermsDiscountDays.Visible = ThisPTerms;
	Items.DataListPTermsDiscountPercent.Visible = ThisPTerms;
	
	FillObjectCustomNamesMap();
	
	For Counter = 1 to 62 Do 
		CustomColumn = ThisForm.Items.Find("DataListField"+Counter);
		If CustomColumn <> Undefined Then
			ThisForm.Items.Delete(CustomColumn);
		EndIf;	
	EndDo;	
	CustomFieldMap.Clear();
	
	Attributes.Clear();	
	
	If ThisDeposits Then
		
		AddCustomAttribute(1,"Number [char(20)]","Number");
		
		NewLine = Attributes.Add();
		NewLine.AttributeName = "Date [char]";
		NewLine.Required = True;
				
		NewLine = Attributes.Add();
		NewLine.AttributeName = "Bank account [ref]";
		NewLine.Required = True;
		
		NewLine = Attributes.Add();
		NewLine.AttributeName = "Deposit memo [char]";
		//NewLine.Required = True;
	
		NewLine = Attributes.Add();
		NewLine.AttributeName = "Line company [ref]";

		NewLine = Attributes.Add();
		NewLine.AttributeName = "Line account [ref]";
		NewLine.Required = True;

		NewLine = Attributes.Add();
		NewLine.AttributeName = "Line amount [num]";
		NewLine.Required = True;
		
		NewLine = Attributes.Add();
		NewLine.AttributeName = "Line class [ref]";

	    NewLine = Attributes.Add();
		NewLine.AttributeName = "Line memo [char]";
		
		AddCustomAttribute(2,"Post [T - true, F - false]","ToPost",,"Post");		
		
	ElsIf ThisClasses Then
		
		NewLine = Attributes.Add();
		NewLine.AttributeName = "Name [char(25)]";
		NewLine.Required = True;
		
		NewLine = Attributes.Add();
		NewLine.AttributeName = "Subclass of [ref]";		
		
	ElsIf ThisPTerms Then
		
		AddAttribute("Name [char(25)]",True);
		AddAttribute("Days [num]",);
		AddAttribute("Discount days [num]",);
		AddAttribute("Discount percent [num]",);
		
	ElsIf ThisPriceLevels Then
				
		AddCustomAttribute(1,"Name [char(25)]","Name",True);
		AddCustomAttribute(2,"Type [char 25)]","Type");
		AddCustomAttribute(3,"Percentage [num]","Percentage",);
		
	ElsIf ThisProjects Then
				
		AddCustomAttribute(1,"Description [char(100)]","Description",True);
		AddCustomAttribute(2,"Customer [Ref]","Customer",);	
		AddCustomAttribute(3,"Receipts budget [num]","ReceiptsBudget",,"Receipts budget");	
		AddCustomAttribute(4,"Expense budget [num]","ExpenseBudget",,"Expense budget");	
		AddCustomAttribute(5,"Hours budget [num]","HoursBudget",,"Hours budget");	
		AddCustomAttribute(6,"Project status [char (10)]","Status");
		AddCustomAttribute(7,"Project type [char (10)]","Type");
		
		
	ElsIf ThisSalesRep Then
				
		AddCustomAttribute(1,"Name [char(50)]","Name",True);
		
	ElsIf ThisPO Then
				
		AddCustomAttribute(1,"Number [char(20)]","Number",True);
		AddCustomAttribute(2,"Document date [date]","DocDate", True, "Document date");
		AddCustomAttribute(3,"Company [Ref]","Company",);	
		AddCustomAttribute(4,"Company address [Ref]","CompanyAddres",, "Company address");	
		AddCustomAttribute(5,"Dropship Company [Ref]","DSCompany",, "Dropship company");	
		AddCustomAttribute(6,"Dropship Ship to [Ref]","DSShipTo",, "Dropship to");	
		AddCustomAttribute(7,"Dropship Confirm to [Ref]","DSConfirmTo",, "Dropship confirm to");	
		AddCustomAttribute(8,"Dropship Ref Num [char(20)]","DSRefN",, "Dropship ref N");
		
		AddCustomAttribute(9,"Sales Person [char(50)]","SalesPerson",, "Sales person");	
		AddCustomAttribute(10,"Currency [char(3)]","Currency",);	
		AddCustomAttribute(11,"Location [char(20)]","Location",);	
		AddCustomAttribute(12,"Delivery Date [char(20)]","DeliveryDate",, "Delivery date");	
		AddCustomAttribute(13,"Project [char(20)]","Project",);	
		AddCustomAttribute(14,"Class [char(20)]","Class",);	
		
		AddCustomAttribute(15,"Memo [char]","Memo",);		
		AddCustomAttribute(16,"Doc Total [num]","DocTotal", ,"Total");		
		AddCustomAttribute(17,"Doc Total RC [num]","DocTotalRC",, "Total RC");		
		// Line items
		AddCustomAttribute(18,"Product [char(20)]","Product",);		
		AddCustomAttribute(19,"Description [char(20)]","Description",);		
		AddCustomAttribute(20,"Price [num)]","Price",);		
		AddCustomAttribute(21,"Line Total [num]","LineTotal",,"Line Total");		
		AddCustomAttribute(22,"Line Project [char(20)]","LineProject",,"Line Project");	
		AddCustomAttribute(23,"Line Class [char(20)]","LineClass",,"Line Class");	
		AddCustomAttribute(24,"Line Quantity [num]","LineQuantity",,"Line Quantity");	
		AddCustomAttribute(25,"Post [T - true, F - false]","ToPost",,"Post");		
		
	ElsIf ThisBill Then //PurchaseInvoice
				
		AddCustomAttribute(1,"Number [char(20)]","Number",True);
		AddCustomAttribute(2,"Document date [date]","DocDate", True, "Document date");
		AddCustomAttribute(3,"Table data type [0-Main, 1-Items, 2-Expences]","TableType", True, "Table type");	
		AddCustomAttribute(4,"Company [Ref]","Company",True);	
		AddCustomAttribute(5,"Company address [Ref]","CompanyAddres",, "Company address");	
		AddCustomAttribute(6,"Currency [char(3)]","Currency",);	
		AddCustomAttribute(7,"AP Account [char(10)]","APAccount",,"AP account");	
		AddCustomAttribute(8,"Due Date [char(20)]","DueDate",, "Due date");	
		AddCustomAttribute(9,"Sales Person [char(50)]","SalesPerson",, "Sales person");	
		AddCustomAttribute(10,"Location [char(20)]","Location",);	
		AddCustomAttribute(11,"Delivery Date [char(20)]","DeliveryDate",, "Delivery date");	
		AddCustomAttribute(12,"Project [char(20)]","Project",);	
		AddCustomAttribute(13,"Class [char(20)]","Class",);	
		AddCustomAttribute(14,"Terms [char(25)]","Terms",);	
		AddCustomAttribute(15,"Memo [char]","Memo",);		
		
		// Line items
		AddCustomAttribute(16,"Product [char(20)]","Product",);		
		AddCustomAttribute(17,"Description [char(20)]","Description",);		
		AddCustomAttribute(18,"Price [num)]","Price",);		
		AddCustomAttribute(19,"Line Total [num]","LineTotal",,"Line Total");		
		AddCustomAttribute(20,"Line PO # [char(20)]","LinePO",,"Line PO");	
		AddCustomAttribute(21,"Line Class [char(20)]","LineClass",,"Line Class");	
		AddCustomAttribute(22,"Line Quantity [num]","LineQuantity",,"Line Quantity");	
		AddCustomAttribute(23,"Line Memo [char]","LineMemo",,"Line memo");		
		AddCustomAttribute(24,"Line Account [char(10)]","LineAccount",,"Line account");	
		AddCustomAttribute(25,"Post [1 - true, 0 - false]","ToPost",,"Post");			
		
	ElsIf ThisIR Then //ItemReceipt

		AddCustomAttribute(1,"Number [char(20)]","Number",True);
		AddCustomAttribute(2,"Document date [date]","DocDate", True, "Document date");
		AddCustomAttribute(3,"Company [Ref]","Company",True);	
		AddCustomAttribute(4,"Company address [Ref]","CompanyAddres",, "Company address");	
		AddCustomAttribute(5,"Currency [char(3)]","Currency",);	
		AddCustomAttribute(6,"Due Date [char(20)]","DueDate",, "Due date");	
		AddCustomAttribute(7,"Location [char(20)]","Location",);	
		AddCustomAttribute(8,"Delivery Date [char(20)]","DeliveryDate",, "Delivery date");	
		AddCustomAttribute(9,"Project [char(20)]","Project",);	
		AddCustomAttribute(10,"Class [char(20)]","Class",);	
		AddCustomAttribute(11,"Memo [char]","Memo",);		
		
		// Line items
		AddCustomAttribute(12,"Product [char(20)]","Product",);		
		AddCustomAttribute(13,"Description [char(20)]","Description",);		
		AddCustomAttribute(14,"Price [num)]","Price",);		
		AddCustomAttribute(15,"UoM (25)]","UoM",);	
		AddCustomAttribute(16,"Line Total [num]","LineTotal",,"Line Total");		
		AddCustomAttribute(17,"Line PO # [char(20)]","LinePO",,"Line PO");	
		AddCustomAttribute(18,"Line Class [char(20)]","LineClass",,"Line Class");	
		AddCustomAttribute(19,"Line Quantity [num]","LineQuantity",,"Line Quantity");	
		AddCustomAttribute(20,"Post [1 - true, 0 - false]","ToPost",,"Post");
		
	ElsIf ThisBillPay Then //InvoicePayment  

		AddCustomAttribute(1,"Number [char(20)]","Number",True);
		AddCustomAttribute(2,"Document date [date]","DocDate", True, "Document date");
		AddCustomAttribute(3,"Company [Ref]","Company",True);	
		AddCustomAttribute(4,"Bank account [char (10)]","BankAccount",, "Bank account");	
		AddCustomAttribute(5,"Currency [char(3)]","Currency",);	
		AddCustomAttribute(6,"Payment method [char(25)]","PaymentMethod",, "Payment method");	
		AddCustomAttribute(7,"Physical check # [char(5)]","PhysicalCheckNum",,"Physical check #");	
		AddCustomAttribute(8,"Memo [char]","Memo",);		
		
		
		// Line items
		AddCustomAttribute(9,"Bill [char(20)]","Bill",);		
		AddCustomAttribute(10,"Payment [char(20)]","Payment",);		
		AddCustomAttribute(11,"Due [char(20)]","Due",,"Due");		
		AddCustomAttribute(12,"Price [num)]","Price",);		
		AddCustomAttribute(13,"Check [1 - true, 0 - false]","Check",);	
		AddCustomAttribute(14,"Post [1 - true, 0 - false]","ToPost",,"Post");	
		
	ElsIf ThisBankTransfer Then //BankTransfer  

		AddCustomAttribute(1,"Number [char(20)]","Number");
		AddCustomAttribute(2,"Document date [date]","DocDate", True, "Document date");
		AddCustomAttribute(3,"Account From [char (10)]","AccountFrom", True, "Account From");
		AddCustomAttribute(4,"Account To [char (10)]","AccountTo", True, "Account To");
		AddCustomAttribute(5,"Amount [char(20)]","Amount",);		
		AddCustomAttribute(6,"Memo [char]","Memo",);		
		
	ElsIf ThisSaleInvoice Then //SalesInvoice                

		AddCustomAttribute(1,"Number [char(20)]","Number",True);
		AddCustomAttribute(2,"Document date [date]","DocDate", True, "Document date");
		AddCustomAttribute(3,"Company [Ref]","Company",True);	
		AddCustomAttribute(4,"Ship to [char (25)]","ShipToAddr",, "Ship to");	
		AddCustomAttribute(5,"Bill to [char (25)]","BillToAddr",, "Bill to");	
		AddCustomAttribute(6,"Confirm to [char (25)]","ConfirmToAddr",, "Confirm to");	
		AddCustomAttribute(7,"Ref Num [char (20)]","RefNum",, "Ref Num");	
		AddCustomAttribute(8,"Currency [char(3)]","Currency",);	
		AddCustomAttribute(9,"AR Account [char(10)]","ARAccount",,"AR account");	
		AddCustomAttribute(10,"Payment method [char(25)]","PaymentMethod",, "Payment method");	
		AddCustomAttribute(11,"Due Date [char(20)]","DueDate",, "Due date");	
		AddCustomAttribute(12,"Sales Person [char(50)]","SalesPerson",, "Sales person");	
		AddCustomAttribute(13,"Location [char(20)]","Location",);	
		AddCustomAttribute(14,"Delivery Date [char(20)]","DeliveryDate",, "Delivery date");	
		AddCustomAttribute(15,"Project [char(20)]","Project",);	
		AddCustomAttribute(16,"Class [char(20)]","Class",);	
		AddCustomAttribute(17,"Terms [char(25)]","Terms",);	
		AddCustomAttribute(18,"Sales tax [Num]","SalesTax",,"Sales tax");	
		AddCustomAttribute(19,"Memo [char]","Memo",);		
		
		// Line items
		AddCustomAttribute(20,"Product [char(20)]","Product",);		
		AddCustomAttribute(21,"Description [char(20)]","Description",);		
		AddCustomAttribute(22,"Price [num)]","Price",);		
		AddCustomAttribute(23,"Line Quantity [num]","LineQuantity",,"Line Quantity");	
		AddCustomAttribute(24,"Line Total [num]","LineTotal",,"Line Total");		
		AddCustomAttribute(25,"Line Project [char(20)]","LineProject",,"Line Project");	
		AddCustomAttribute(26,"Line Class [char(20)]","LineClass",,"Line Class");	
		AddCustomAttribute(27,"Taxable amount [num]","TaxableAmount",,"Taxable amount");	
		AddCustomAttribute(28,"Taxable [1 - true, 0 - false]","Taxable");	
		AddCustomAttribute(29,"Post [1 - true, 0 - false]","ToPost",,"Post");	
		AddCustomAttribute(30,"Sales Order [char(20)]","Order");	
		
	ElsIf ThisSaleOrder Then //SalesOrder                

		AddCustomAttribute(1,"Number [char(20)]","Number",True);
		AddCustomAttribute(2,"Document date [date]","DocDate", True, "Document date");
		AddCustomAttribute(3,"Company [Ref]","Company",True);	
		AddCustomAttribute(4,"Ship to [char (25)]","ShipToAddr",, "Ship to");	
		AddCustomAttribute(5,"Bill to [char (25)]","BillToAddr",, "Bill to");	
		AddCustomAttribute(6,"Confirm to [char (25)]","ConfirmToAddr",, "Confirm to");	
		AddCustomAttribute(7,"Ref Num [char (20)]","RefNum",, "Ref Num");	
		AddCustomAttribute(8,"Sales Person [char(50)]","SalesPerson",, "Sales person");	
		AddCustomAttribute(9,"Delivery Date [char(20)]","DeliveryDate",, "Delivery date");	
		AddCustomAttribute(10,"Shipping Cost [Num]","ShippingCost",, "Shipping cost");	
		AddCustomAttribute(11,"Project [char(20)]","Project",);	
		AddCustomAttribute(12,"Class [char(20)]","Class",);	
		AddCustomAttribute(13,"Sales tax [Num]","SalesTax",,"Sales tax");	
		AddCustomAttribute(14,"Memo [char]","Memo",);		
		
		// Line items
		AddCustomAttribute(15,"Product [char(20)]","Product",);		
		AddCustomAttribute(16,"Description [char(20)]","Description",);		
		AddCustomAttribute(17,"Price [num)]","Price",);		
		AddCustomAttribute(18,"Line Quantity [num]","LineQuantity",,"Line Quantity");	
		AddCustomAttribute(19,"Line Total [num]","LineTotal",,"Line Total");		
		AddCustomAttribute(20,"Line Project [char(20)]","LineProject",,"Line Project");	
		AddCustomAttribute(21,"Line Class [char(20)]","LineClass",,"Line Class");	
		AddCustomAttribute(22,"Taxable amount [num]","TaxableAmount",,"Taxable amount");	
		AddCustomAttribute(23,"Taxable [1 - true, 0 - false]","Taxable",,"Taxable");	
		AddCustomAttribute(24,"Post [1 - true, 0 - false]","ToPost",,"Post");	
		
	ElsIf ThisCashReceipt Then //CashReceipt                

		AddCustomAttribute(1,"Number [char(20)]","Number");
		AddCustomAttribute(2,"Document date [date]","DocDate", True, "Document date");
		AddCustomAttribute(3,"Company [Ref]","Company",True);	
		AddCustomAttribute(4,"Ref Num [char (20)]","RefNum",, "Ref Num");	
		AddCustomAttribute(5,"Currency [char(3)]","Currency",);	
		AddCustomAttribute(6,"Memo [char]","Memo",);		
		AddCustomAttribute(7,"Bank account [char (10)]","BankAccount",, "Bank account");	
		AddCustomAttribute(8,"Payment method [char(25)]","PaymentMethod",, "Payment method");	
		AddCustomAttribute(9,"Deposit type [1 - Undeposited, 2 - Bank]","DepositType",, "Deposit type");	
		AddCustomAttribute(10,"AR Account [char(10)]","ARAccount",,"AR account");	
		AddCustomAttribute(11,"Sales order [char(10)]","SalesOrder",,"Sales order");	
		
		AddCustomAttribute(12,"Table type [0 - Header, 1 - Invoices, 2 - Credits]","TableType",,"Table type");	
		AddCustomAttribute(13,"Document type [char(15)]","DocumentType",,"Document type");	
		AddCustomAttribute(14,"Document number [char(6)]","DocumentNum",,"Document number");	
		AddCustomAttribute(15,"Payment [Num]","Payment");	
		AddCustomAttribute(16,"Overpayment [Num]","Overpayment");	
		
		AddCustomAttribute(17,"Post [1 - true, 0 - false]","ToPost",,"Post");			
		
	ElsIf ThisCreditMemo Then //CreditMemo

		AddCustomAttribute(1,"Number [char(20)]","Number",True);
		AddCustomAttribute(2,"Document date [date]","DocDate", True, "Document date");
		AddCustomAttribute(3,"Company [Ref]","Company",True);	
		AddCustomAttribute(4,"Parent invoice [char (20)]","ParentInvoice",, "Parent invoice");	
		AddCustomAttribute(5,"Ship from [char (25)]","ShipFromAddr",, "ShipFrom");	
		AddCustomAttribute(6,"Ref Num [char (20)]","RefNum",, "Ref Num");	
		AddCustomAttribute(7,"Currency [char(3)]","Currency",);	
		AddCustomAttribute(8,"AR Account [char(10)]","ARAccount",,"AR account");	
		AddCustomAttribute(9,"Sales tax rate [Num]","SalesTaxRate",,"Sales tax rate");	
		AddCustomAttribute(10,"Due Date [char(20)]","DueDate",, "Due date");	
		AddCustomAttribute(11,"Sales Person [char(50)]","SalesPerson",, "Sales person");	
		AddCustomAttribute(12,"Location [char(20)]","Location",);	
		AddCustomAttribute(13,"Return type [Char]","ReturnType",,"Return type");	// CrMemo or Return
		//AddCustomAttribute(14,"Sales tax [Num]","SalesTax",,"Sales tax");	
		AddCustomAttribute(15,"Memo [char]","Memo",);		
		
		// Line items
		AddCustomAttribute(16,"Product [char(20)]","Product",);		
		AddCustomAttribute(17,"Description [char(20)]","Description",);		
		AddCustomAttribute(18,"Price [num)]","Price",);		
		AddCustomAttribute(19,"Line Quantity [num]","LineQuantity",,"Line Quantity");	
		AddCustomAttribute(20,"Line Total [num]","LineTotal",,"Line Total");		
		AddCustomAttribute(21,"Line Project [char(20)]","LineProject",,"Line Project");	
		AddCustomAttribute(22,"Line Class [char(20)]","LineClass",,"Line Class");	
		AddCustomAttribute(23,"Taxable[1 - true, 0 - false]","Taxable");	
		AddCustomAttribute(24,"Post [1 - true, 0 - false]","ToPost",,"Post");	
		AddCustomAttribute(25,"Sales Order [char(20)]","Order");	
		
		                    
	ElsIf ThisCofA Then
		
		AddAttribute("Code [char(10)]",True);
		AddAttribute("Description [char(100)]",True);
		AddAttribute("Subaccount of [char(10)]");
		AddAttribute("Type [ref]",True);
		AddAttribute("Update [ref]");
		AddAttribute("Cashflow sectiom [ref]");
		AddAttribute("Memo [str]");
		
	ElsIf ThisExpensify Then
			
		AddCustomAttribute(1,"Bill Number [char 20)]","Number",True,"Bill number");
		AddCustomAttribute(2,"Bill Date [date]","Date",True, "Bill Date");
		AddCustomAttribute(3,"Vendor [Ref]","Company",True, "Vendor");
		AddAttribute("Category [char(50)",True);
		AddAttribute("Amount [num]",True);
		AddAttribute("Memo [char(100)]");
		AddCustomAttribute(4,"Post [T - true, F - false]","ToPost",,"Post");			
		
	ElsIf ThisGJ Then
		
		NewLine = Attributes.Add();
		NewLine.AttributeName = "Date [date]";
		NewLine.Required = True;
		
		NewLine = Attributes.Add();
		NewLine.AttributeName = "Memo [char]";

		NewLine = Attributes.Add();
		NewLine.AttributeName = "Row # [num]";
		NewLine.Required = True;
		
		NewLine = Attributes.Add();
		NewLine.AttributeName = "Debit or Credit";
		NewLine.Required = True;
		
		NewLine = Attributes.Add();
		NewLine.AttributeName = "Line account [ref]";
		NewLine.Required = True;
		
		NewLine = Attributes.Add();
		NewLine.AttributeName = "Line amount [num]";
		NewLine.Required = True;
		
		NewLine = Attributes.Add();
		NewLine.AttributeName = "Line class [ref]";

		NewLine = Attributes.Add();
		NewLine.AttributeName = "Line memo [char]";
		
						
	ElsIf ThisChecks Then
			
		NewLine = Attributes.Add();
		NewLine.AttributeName = "Date [char]";
		NewLine.Required = True;
		
		NewLine = Attributes.Add();
		NewLine.AttributeName = "Number [char(6)]";
		
		NewLine = Attributes.Add();
		NewLine.AttributeName = "Bank account [ref]";
		NewLine.Required = True;
		
		NewLine = Attributes.Add();
		NewLine.AttributeName = "Vendor [ref]";

		NewLine = Attributes.Add();
		NewLine.AttributeName = "Check memo [char]";

		NewLine = Attributes.Add();
		NewLine.AttributeName = "Line account [ref]";
		NewLine.Required = True;

	    NewLine = Attributes.Add();
		NewLine.AttributeName = "Line memo [char]";
		
		NewLine = Attributes.Add();
		NewLine.AttributeName = "Line amount [num]";
		NewLine.Required = True;
		
		NewLine = Attributes.Add();
		NewLine.AttributeName = "Line class [ref]";
		
		AddCustomAttribute(2,"Post [T - true, F - false]","ToPost",,"Post");		
		
	ElsIf ThisCustomers Then
		
		// company header
		
		NewLine = Attributes.Add();
		NewLine.AttributeName = "Type [0 - Customer, 1 - Vendor, 2 - Both]";
		NewLine.Required = True;		
		
		NewLine = Attributes.Add();
		NewLine.AttributeName = "Company code [char(5)]";
		
		NewLine = Attributes.Add();
		NewLine.AttributeName = "Company name [char(150)]";
		NewLine.Required = True;
		
		NewLine = Attributes.Add();
		NewLine.AttributeName = "Full name [char(150)]";
		
		NewLine = Attributes.Add();
		NewLine.AttributeName = "Income account [ref]";

		NewLine = Attributes.Add();
		NewLine.AttributeName = "Expense account [ref]";

		NewLine = Attributes.Add();
		NewLine.AttributeName = "1099 vendor [T - true, F - false]";
		
		NewLine = Attributes.Add();
		NewLine.AttributeName = "Employee [T - true, F - false]";
		
		NewLine = Attributes.Add();
		NewLine.AttributeName = "EIN or SSN";
		
		NewLine = Attributes.Add();
		NewLine.AttributeName = "Vendor tax ID [char(15)]";
		
		NewLine = Attributes.Add();
		NewLine.AttributeName = "Default billing address [T - true, F - false]";
		//NewLine.Required = True;
		
		NewLine = Attributes.Add();
		NewLine.AttributeName = "Default shipping address [T - true, F - false]";
		//NewLine.Required = True;
		
	    NewLine = Attributes.Add();
		NewLine.AttributeName = "Notes [char]";
		
		NewLine = Attributes.Add();
		NewLine.AttributeName = "Terms [ref]";
				
		NewLine = Attributes.Add();
		NewLine.AttributeName = "Customer sales person [ref]";
		
		NewLine = Attributes.Add();
		NewLine.AttributeName = "Customer price level [ref]";
		
		NewLine = Attributes.Add();
		NewLine.AttributeName = "Website [char(200)]";
		
		AddAttribute("Company CF1 string [char(100)]");
		AddAttribute("Company CF1 num [num]");
		AddAttribute("Company CF2 string [char(100)]");
		AddAttribute("Company CF2 num [num]");
		AddAttribute("Company CF3 string [char(100)]");
		AddAttribute("Company CF3 num [num]");
		AddAttribute("Company CF4 string [char(100)]");
		AddAttribute("Company CF4 num [num]");
		AddAttribute("Company CF5 string [char(100)]");
		AddAttribute("Company CF5 num [num]");
		
		// address
		
		NewLine = Attributes.Add();
		NewLine.AttributeName = "Address ID [char(25)]";
		
		NewLine = Attributes.Add();
		NewLine.AttributeName = "Salutation [char(15)]";
		
		NewLine = Attributes.Add();
		NewLine.AttributeName = "First name [char(200)]";
			
		NewLine = Attributes.Add();
		NewLine.AttributeName = "Middle name [char(200)]";
		
		NewLine = Attributes.Add();
		NewLine.AttributeName = "Last name [char(200)]";
		
		NewLine = Attributes.Add();
		NewLine.AttributeName = "Suffix [char(10)]";
		
		NewLine = Attributes.Add();
		NewLine.AttributeName = "Job title [char(200)]";

		NewLine = Attributes.Add();
		NewLine.AttributeName = "Phone [char(50)]";
		
		NewLine = Attributes.Add();
		NewLine.AttributeName = "Cell [char(50)]";		
		
		NewLine = Attributes.Add();
		NewLine.AttributeName = "Fax [char(50)]";
		
		NewLine = Attributes.Add();
		NewLine.AttributeName = "E-mail [char(100)]";
		
		NewLine = Attributes.Add();
		NewLine.AttributeName = "Address line 1 [char(250)]";
		
		NewLine = Attributes.Add();
		NewLine.AttributeName = "Address line 2 [char(250)]";
		
		NewLine = Attributes.Add();
		NewLine.AttributeName = "Address line 3 [char(250)]";
		
		NewLine = Attributes.Add();
		NewLine.AttributeName = "City [char(100)]";
		
		NewLine = Attributes.Add();
		NewLine.AttributeName = "State [ref]";

		NewLine = Attributes.Add();
		NewLine.AttributeName = "Country [ref]";

		NewLine = Attributes.Add();
		NewLine.AttributeName = "ZIP [char(20)]";
		
		NewLine = Attributes.Add();
		NewLine.AttributeName = "Address notes [char]";
		
		NewLine = Attributes.Add();
		NewLine.AttributeName = "Shipping address line 1 [char(250)]";
		
		NewLine = Attributes.Add();
		NewLine.AttributeName = "Shipping address line 2 [char(250)]";
		
		NewLine = Attributes.Add();
		NewLine.AttributeName = "Shipping address line 3 [char(250)]";
		
		NewLine = Attributes.Add();
		NewLine.AttributeName = "Shipping City [char(100)]";
		
		NewLine = Attributes.Add();
		NewLine.AttributeName = "Shipping State [ref]";

		NewLine = Attributes.Add();
		NewLine.AttributeName = "Shipping Country [ref]";

		NewLine = Attributes.Add();
		NewLine.AttributeName = "Shipping ZIP [char(20)]";
				
		NewLine = Attributes.Add();
		NewLine.AttributeName = "Address sales person [ref]";
		
		
		AddAttribute("Address CF1 string [char(200)]");
		AddAttribute("Address CF2 string [char(200)]");
		AddAttribute("Address CF3 string [char(200)]");
		AddAttribute("Address CF4 string [char(200)]");
		AddAttribute("Address CF5 string [char(200)]");
		
		AddCustomAttribute(1,"Taxable [T - true, F - false]","STaxable",,"Taxable");
		AddCustomAttribute(2,"Sales tax rate [char(50)]","STaxRate",,"Tax rate");
		//AddCustomAttribute(3,"Update all company data [T - true, F - false]","UpdateAll",,"Update all");
		
		// end address
		///--------------------------------------------------------------------------------
		If False then // Prepare for refactoring
			AddCustomAttribute(1,"Type [0 - Customer, 1 - Vendor, 2 - Both]","STaxable",True,"Type");
			AddCustomAttribute(2,"Company code [char(5)]","STaxable",,"Company code");
			AddCustomAttribute(3,"Company name [char(150)]","STaxable",True,"company name");
			AddCustomAttribute(4,"Full name [char(150)]","STaxable",,"Full name");
			AddCustomAttribute(5,"Income account [ref]","STaxable",,"Income account");
			AddCustomAttribute(6,"Expense account [ref]","STaxable",,"Expence account");
			AddCustomAttribute(7,"1099 vendor [T - true, F - false]","CustomerVendor1099",,"1099");
			AddCustomAttribute(8,"Employee [T - true, F - false]","CustomerEmployee",,"Employee");
			AddCustomAttribute(9,"EIN or SSN","STaxable",,"EIN  or SSN");
			AddCustomAttribute(0,"Vendor tax ID [char(15)]","STaxable",,"Tax ID");
			AddCustomAttribute(11,"Default billing address [T - true, F - false","DefaultBillingAddress",,"Default Billing");
			AddCustomAttribute(12,"Default shipping address [T - true, F - false","DefaultShippingAddress",,"Default shipping");
			AddCustomAttribute(13,"Notes [char]","STaxable",,"Notes");
			AddCustomAttribute(14,"Terms [ref]","STaxable",,"Terms");
			AddCustomAttribute(15,"Customer sales person [ref]","STaxable",,"Sales person");
			AddCustomAttribute(16,"Customer price level [ref]","STaxable",,"Price level");
			AddCustomAttribute(17,"Website [char(200)]","STaxable",,"Website");
			AddCustomAttribute(18,"Company CF1 string [char(100)]","",,"CF1(str)");
			AddCustomAttribute(19,"Company CF1 num [num]","",,"CF1(Num)");
			AddCustomAttribute(20,"Company CF2 string [char(100)]","",,"CF2(str)");
			AddCustomAttribute(21,"Company CF2 num [num]","",,"CF2(Num)");
			AddCustomAttribute(22,"Company CF3 string [char(100)]","",,"CF3(str)");
			AddCustomAttribute(23,"Company CF3 num [num]","",,"CF3(Num)");
			AddCustomAttribute(24,"Company CF4 string [char(100)]","",,"CF4(str)");
			AddCustomAttribute(25,"Company CF4 num [num]","",,"CF4(Num)");
			AddCustomAttribute(26,"Company CF5 string [char(100)]","",,"CF5(str)");
			AddCustomAttribute(27,"Company CF5 num [num]","",,"CF5(Num)");
			AddCustomAttribute(28,"Address ID [char(25)]","STaxable",,"Addr ID");
			AddCustomAttribute(29,"Salutation [char(15)]","STaxable",,"Sal.");
			AddCustomAttribute(30,"First name [char(200)]","STaxable",,"First name");
			AddCustomAttribute(31,"Middle name [char(200)]","STaxable",,"Middle name");
			AddCustomAttribute(32,"Last name [char(200)]","STaxable",,"Last Name");
			AddCustomAttribute(33,"Suffix [char(10)]","STaxable",,"Suffix");
			AddCustomAttribute(34,"Job title [char(200)]","STaxable",,"Job title");
			AddCustomAttribute(35,"Phone [char(50)]","STaxable",,"Phone");
			AddCustomAttribute(36,"Cell [char(50)","STaxable",,"Cell");
			AddCustomAttribute(37,"Fax [char(50)","STaxable",,"Fax");
			AddCustomAttribute(38,"E-mail [char(100)]","STaxable",,"Email");
			AddCustomAttribute(39,"Address line 1 [char(250)]","STaxable",,"Addr Line 1");
			AddCustomAttribute(40,"Address line 2 [char(250)]","STaxable",,"Addr Line 2");
			AddCustomAttribute(41,"Address line 3 [char(250)]","STaxable",,"Addr Line 3");
			AddCustomAttribute(42,"City [char(100)]","STaxable",,"City");
			AddCustomAttribute(43,"State [ref]","STaxable",,"State");
			AddCustomAttribute(44,"Country [ref]","STaxable",,"Country");
			AddCustomAttribute(45,"ZIP [char(20)]","STaxable",,"Zip");
			AddCustomAttribute(46,"Address notes [char","STaxable",,"Addr notes");
			AddCustomAttribute(47,"Shipping address line 1 [char(250)]","STaxable",,"Ship Addr 1");
			AddCustomAttribute(48,"Shipping address line 2 [char(250)]","STaxable",,"Ship Addr 2");
			AddCustomAttribute(49,"Shipping address line 3 [char(250)]","STaxable",,"Ship Addr 3");
			AddCustomAttribute(50,"Shipping City [char(100)]","STaxable",,"Ship city");
			AddCustomAttribute(51,"Shipping State [ref]","STaxable",,"Ship state");
			AddCustomAttribute(52,"Shipping Country [ref]","STaxable",,"Ship country");
			AddCustomAttribute(53,"Shipping ZIP [char(20)]","STaxable",,"Taxable");
			AddCustomAttribute(54,"Address sales person [ref]","STaxable",,"Addr Sales person");				
			AddCustomAttribute(55,"Address CF1 string [char(200)]","",,"Addr CF1");
			AddCustomAttribute(56,"Address CF2 string [char(200)]","",,"Addr CF2");
			AddCustomAttribute(57,"Address CF3 string [char(200)]","",,"Addr CF3");
			AddCustomAttribute(58,"Address CF4 string [char(200)]","",,"Addr CF4");
			AddCustomAttribute(59,"Address CF5 string [char(200)]","",,"Addr CF5");
			AddCustomAttribute(60,"Taxable [T - true, F - false]","STaxable",,"Taxable");
			AddCustomAttribute(61,"Sales tax rate [char(50)]","STaxRate",,"Tax rate");
			//AddCustomAttribute(62,"Update all company data [T - true, F - false]","UpdateAll",,"Update all");
		Endif;             
		
		//---------------------------------------------------------------------------------
		
	ElsIf ThisProducts Then
		AddAttribute("Product OR Service",True);
		AddAttribute("Item code [char(50)]",True);
		AddAttribute("Item description [char(150)]",True);
		AddAttribute("Purchase description [char(150)]");
		AddAttribute("Parent [char 50]");
		AddAttribute("Income account [ref]");
		AddAttribute("Inventory or expense account [ref]");
		AddAttribute("COGS account [ref]");
		AddAttribute("Price [num]");
		AddAttribute("Cost [Num]");
		AddAttribute("Qty [num]");
		AddAttribute("Value [num]");
		AddAttribute("Taxable [T - true, F - false]");
		AddAttribute("Category [ref]");
		//AddAttribute("UoM [ref]");	
		AddAttribute("Prefered Vendor [char 50]");	
		AddAttribute("Vendor Code [char(50)]");	
		AddAttribute("CF1String [char(100)]");
		AddAttribute("CF1Num [num]");
		AddAttribute("CF2String [char(100)]");
		AddAttribute("CF2Num [num]");
		AddAttribute("CF3String [char(100)]");
		AddAttribute("CF3Num [num]");
		AddAttribute("CF4String [char(100)]");
		AddAttribute("CF4Num [num]");
		AddAttribute("CF5String [char(100)]");
		AddAttribute("CF5Num [num]");
		AddAttribute("Update [char 50]");
		AddCustomAttribute(1,"UOM [char(50)]","UoM");	
		AddCustomAttribute(2,"UPC code [char(100)]","UPCCode");	
		AddCustomAttribute(3,"Reorder point [Num(10)]","ReorderPoint");	
	EndIf;
	
EndProcedure // 

&AtServer
Function FillAttributesAtServer(RowCount)
	
	Source = New ValueTable;
	
	MaxRowCout = 0;
	
	For RowCounter = 1 To RowCount Do
		                                                          
		CurrentRow = SourceText.GetLine(RowCounter);
		
		NumOfQuotes = StrOccurrenceCount(CurrentRow,"""");
		While NumOfQuotes%2 = 1 Do
			//String was separated, need to be splitted 
			RowCounter = RowCounter + 1;
			CurrentRow = CurrentRow + Chars.LF + SourceText.GetLine(RowCounter);
			NumOfQuotes = StrOccurrenceCount(CurrentRow,"""");
		EndDo;	
				
		ValueArray = StringFunctionsClientServer.SplitStringIntoSubstringArray(CurrentRow, ",",,"""");
		ColumnMaxCount = ValueArray.Count();
		
		If ColumnMaxCount < 1 Then
			Continue;
		EndIf;
		
		If ColumnMaxCount > MaxRowCout Then
			For CounterColumn = MaxRowCout + 1 To ColumnMaxCount Do
				NewColumn = Source.Columns.Add();
				NewColumn.Name = "Column" + TrimAll(CounterColumn);
				NewColumn.Title = "Column #" + TrimAll(CounterColumn);
			EndDo;
			MaxRowCout = ColumnMaxCount;
		EndIf;
		
		NewLine = Source.Add();
		For CounterColumn = 0 To ColumnMaxCount - 1 Do
			NewLine[CounterColumn] = StrReplace(ValueArray[CounterColumn],"""""","""");
		EndDo;
		
	EndDo;
	
	SourceAddress = PutToTempStorage(Source, ThisForm.UUID);
	
	Return SourceAddress;
	
EndFunction

&AtServer
Procedure AddAttribute(AttrName,Required = False)
	
	
	//For custom fields
	RowFilter = New Structure;
	RowFilter.Insert("AttributeName",AttrName);
	ReplacedName = ObjectCustomFieldMap.FindRows(RowFilter);
	If ReplacedName.Count() > 0 Then 
		If ReplacedName[0].CustomName = "(NOT USED)" Then 
			//Do Nothing
		Else	
			NewLine = Attributes.Add();
			NewLine.AttributeName = ReplacedName[0].CustomName;	
			NewLine.Required = Required;
		EndIf;	
	Else 	
		NewLine = Attributes.Add();
		NewLine.AttributeName = AttrName;
		NewLine.Required = Required;
	EndIf;	
	
EndProcedure	

&AtServer
Procedure AddCustomAttribute(Counter, AttrName, ColumnName, Required = False, ColumnTitle = "")
	
	// ++++++ for future refactoring---------------------------------------
	If False then 
		RowFilter = New Structure;
		RowFilter.Insert("AttributeName",AttrName);
		ReplacedName = ObjectCustomFieldMap.FindRows(RowFilter);
		
		If ReplacedName.Count() > 0 Then 
			If ReplacedName[0].CustomName = "(NOT USED)" Then 
				//Do Nothing
			Else	
				NewLine = Attributes.Add();
				NewLine.AttributeName = ReplacedName[0].CustomName;	
				NewLine.Required = Required;
			EndIf;	
		Else 	
			NewLine = Attributes.Add();
			NewLine.AttributeName = AttrName;
			NewLine.Required = Required;
		EndIf;
	EndIf;
	// ------- for future refactoring---------------------------------------
	
	NewLine = Attributes.Add();
	NewLine.AttributeName = AttrName;
	NewLine.Required = Required;
	
	CustomColumn = ThisForm.Items.Find("DataListField"+Counter);
	If CustomColumn = Undefined Then
		CustomColumn = ThisForm.Items.Add("DataListField"+Counter,Type("FormField"),ThisForm.Items.DataList);
		CustomColumn.DataPath = "Object.DataList.CustomField"+Counter;
	EndIf;	
	CustomColumn.Visible = True;
	If ColumnTitle = "" Then 
		CustomColumn.Title = ColumnName;
	Else 	
		CustomColumn.Title = ColumnTitle;
	EndIf;	
		
	MapString = CustomFieldMap.Add();
	MapString.Order = Counter;
	MapString.AttributeName = AttrName;
	MapString.ColumnName = ColumnName;
	
EndProcedure	

&AtServer
Procedure FillSourceView()

	SourceView.Clear();
	
	DProcessor = FormAttributeToValue("Object");
	Template = DProcessor.GetTemplate("Template");
	EmptyArea = Template.GetArea("EmptyArea");
	HeaderArea = Template.GetArea("HeaderArea");
	CellArea = Template.GetArea("CellArea");
	
	Source = GetFromTempStorage(SourceAddress);

	SourceView.Put(EmptyArea);
	For Each ColumnOfSource In Source.Columns Do
		HeaderArea.Parameters.Text = ColumnOfSource.Title;
		SourceView.Join(HeaderArea);
	EndDo;
	
	ColumnCount = Source.Columns.Count();
	For Each SourceLine In Source Do
		SourceView.Put(EmptyArea);
		For ColumnCounter = 0 To ColumnCount -1  Do
			CellArea.Parameters.Text = SourceLine[ColumnCounter];
			SourceView.Join(CellArea);
		EndDo;
	EndDo;
		
	Items.AttributesColumnNumber.MaxValue = Source.Columns.Count();
	
EndProcedure

&AtServer
Procedure FillLoadTable()
	
	ListOfFilledAttributes.Clear();
	Object.DataList.Clear();
	UploadTable = Object.DataList.Unload();
	
	Source = GetFromTempStorage(SourceAddress);
		
	For RowCounter = 0 To Source.Count() - 1 Do
				
		If ActionType = "Chart of accounts" Then
			
			NewLine = UploadTable.Add();
			NewLine.LoadFlag = True;
					
			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Code [char(10)]");
			If ColumnStringValue <> Undefined Then
				NewLine.CofACode = ColumnStringValue;
			EndIf;

			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Description [char(100)]");
			If ColumnStringValue <> Undefined Then
				NewLine.CofADescription = ColumnStringValue;	
			EndIf;
			
			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Memo [str]");
			If ColumnStringValue <> Undefined Then
				NewLine.CofAMemo = ColumnStringValue;	
			EndIf;
			
			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Subaccount of [char(10)]");
			If ColumnStringValue <> Undefined Then
				NewLine.CofASubaccountOf = ChartsOfAccounts.ChartOfAccounts.FindByCode(ColumnStringValue);
			EndIf;
			
			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Type [ref]");
			If ColumnStringValue <> Undefined Then
				AccountTypeValue = GetValueByName(ColumnStringValue,"AccountType");
				NewLine.CofAType = AccountTypeValue;
			EndIf;

			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Update [ref]");
			If ColumnStringValue <> Undefined Then
				NewLine.CofAUpdate = ChartsOfAccounts.ChartOfAccounts.FindByCode(ColumnStringValue);
			EndIf;
			
			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Cashflow sectiom [ref]");
			If ColumnStringValue <> Undefined Then
				NewLine.CoACashFlowSection = GetValueByName(ColumnStringValue,"CFSection");
			EndIf;
		
		ElsIf ActionType = "Classes" Then
			NewLine = UploadTable.Add();
			NewLine.LoadFlag = True;
			
			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Name [char(25)]");
			If ColumnStringValue <> Undefined Then
				NewLine.ClassName = ColumnStringValue;
			EndIf;
			
			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Subclass of [ref]");
			If ColumnStringValue <> Undefined Then
				NewLine.SubClassOf = Catalogs.Classes.FindByDescription(ColumnStringValue);
			EndIf;	
			
		ElsIf ActionType = "PriceLevels" Then
			
			NewLine = UploadTable.Add();
			NewLine.LoadFlag = True;
			
			For Each Attr in CustomFieldMap Do 
				ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],Attr.AttributeName);
				If ColumnStringValue <> Undefined Then
					If Attr.ColumnName = "Name" Then
						NewLine["CustomField"+Attr.Order] = ColumnStringValue;
					ElsIf Attr.ColumnName = "Type" Then
						NewLine["CustomField"+Attr.Order] = ColumnStringValue;
					ElsIf Attr.ColumnName = "Percentage" Then
						NewLine["CustomField"+Attr.Order] = ColumnStringValue;
					EndIf;	
				EndIf;
			EndDo;
			
		ElsIf ActionType = "SalesRep" Then
			
			NewLine = UploadTable.Add();
			NewLine.LoadFlag = True;
			
			For Each Attr in CustomFieldMap Do 
				ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],Attr.AttributeName);
				If ColumnStringValue <> Undefined Then
					If Attr.ColumnName = "Name" Then
						NewLine["CustomField"+Attr.Order] = ColumnStringValue;
					EndIf;	
				EndIf;
			EndDo;	
			
		ElsIf ActionType = "PaymentTerms" Then
			
			NewLine = UploadTable.Add();
			NewLine.LoadFlag = True;
			
			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Name [char(25)]");
			If ColumnStringValue <> Undefined Then
				NewLine.PTermsName = ColumnStringValue;
			EndIf;
			
			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Days [num]");
			If ColumnStringValue <> Undefined Then
				NewLine.PTermsDays = ColumnStringValue;
			EndIf;
			
			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Discount days [num]");
			If ColumnStringValue <> Undefined Then
				NewLine.PTermsDiscountDays = ColumnStringValue;
			EndIf;
			
			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Discount percent [num]");
			If ColumnStringValue <> Undefined Then
				NewLine.SubClassOf = ColumnStringValue;
			EndIf;		
	
		ElsIf ActionType = "Expensify" Then
			
			NewLine = UploadTable.Add();
			NewLine.LoadFlag = True;
			
			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Category [char(50)]");
			If ColumnStringValue <> Undefined Then
				
				Query = New Query("SELECT
				                  |	ExpensifyCategories.Account
				                  |FROM
				                  |	Catalog.ExpensifyCategories AS ExpensifyCategories
				                  |WHERE
				                  |	ExpensifyCategories.Description = &Category");
				Query.Parameters.Insert("Category", ColumnStringValue);

				QueryResult = Query.Execute();
				
				If QueryResult.IsEmpty() Then
				Else
					Dataset = QueryResult.Unload();
					NewLine.ExpensifyAccount = Dataset[0][0];
				EndIf;

			EndIf;
			
			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Amount [num]");
			If ColumnStringValue <> Undefined Then
				NewLine.ExpensifyAmount = ColumnStringValue;
			EndIf;

			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Memo [char(100)]");
			If ColumnStringValue <> Undefined Then
				NewLine.ExpensifyMemo = ColumnStringValue;
			EndIf;	
			
			For Each Attr in CustomFieldMap Do 
				ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],Attr.AttributeName);
				If ColumnStringValue <> Undefined Then
					
					If Attr.ColumnName = "Date" Then
						TransactionDate = '00010101';
						DateParts = StringFunctionsClientServer.SplitStringIntoSubstringArray(ColumnStringValue, "/",,"""");
						If DateParts.Count() = 3 then
							Try
								TransactionDate = Date(DateParts[2], DateParts[0], DatePArts[1]);
							Except
							EndTry;				
						EndIf;
						NewLine["CustomField"+Attr.Order] = TransactionDate;
						
					ElsIf Attr.ColumnName = "Number" Then
						NewLine["CustomField"+Attr.Order] = Left(ColumnStringValue,20);		
					ElsIf Attr.ColumnName = "Company" Then
						VendorByCode = Catalogs.Companies.FindByCode(ColumnStringValue);
						VendorByDescription = Catalogs.Companies.FindByDescription(ColumnStringValue);
						If VendorByCode = Catalogs.Companies.EmptyRef() Then
							NewLine["CustomField"+Attr.Order] = VendorByDescription;
						Else
							NewLine["CustomField"+Attr.Order] = VendorByCode;
						EndIf
					ElsIf Attr.ColumnName = "ToPost" Then
						NewLine["CustomField"+Attr.Order] = GetValueByName(ColumnStringValue,"Boolean");		
					EndIf;	
				EndIf;
			EndDo;
			
		ElsIf ActionType = "Journal entries" Then
		
			NewLine = UploadTable.Add();
			NewLine.LoadFlag = True;
			
			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Date [date]");
			If ColumnStringValue <> Undefined Then
				TransactionDate = '00010101';
				DateParts = StringFunctionsClientServer.SplitStringIntoSubstringArray(ColumnStringValue, "/",,"""");
				If DateParts.Count() = 3 then
					Try
						TransactionDate 	= Date(DateParts[2], DateParts[0], DatePArts[1]);
					Except
					EndTry;				
				EndIf;
				
				NewLine.GJHeaderDate = TransactionDate;
			EndIf;
			
			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Memo [char]");
			If ColumnStringValue <> Undefined Then
				NewLine.GJHeaderMemo = ColumnStringValue;
			EndIf;
			
			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Row # [num]");
			If ColumnStringValue <> Undefined Then
				NewLine.GJHeaderRowNumber = ColumnStringValue;
			EndIf;
			
			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Debit or Credit");
			If ColumnStringValue <> Undefined Then
				NewLine.GJHeaderType = ColumnStringValue;
			EndIf;
			
			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Line account [ref]");
			If ColumnStringValue <> Undefined Then
				AccountByCode = ChartsOfAccounts.ChartOfAccounts.FindByCode(ColumnStringValue);
				AccountByDescription = ChartsOfAccounts.ChartOfAccounts.FindByDescription(ColumnStringValue);
				If AccountByCode = ChartsOfAccounts.ChartOfAccounts.EmptyRef() Then
					NewLine.GJHeaderAccount = AccountByDescription;
				Else
					NewLine.GJHeaderAccount = AccountByCode;
				EndIf;
			EndIf;
			
			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Line amount [num]");
			If ColumnStringValue <> Undefined Then
				LineAmount = Number(ColumnStringValue);
				If LineAmount < 0 Then
					LineAmount = LineAmount * -1
				EndIf;
				NewLine.GJHeaderAmount = LineAmount;
			EndIf;	
			
			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Line class [ref]");
			If ColumnStringValue <> Undefined Then
				NewLine.GJHeaderClass = Catalogs.Classes.FindByDescription(ColumnStringValue);
			EndIf;
			
			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Line memo [char]");
			If ColumnStringValue <> Undefined Then
				NewLine.GJHeaderLineMemo = ColumnStringValue;
			EndIf;
			
		ElsIf ActionType = "PurchaseOrders" Then
		
			NewLine = UploadTable.Add();
			NewLine.LoadFlag = True;
			
			For Each Attr in CustomFieldMap Do 
				ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],Attr.AttributeName);
				If ColumnStringValue <> Undefined Then
					
					If Attr.ColumnName = "DocDate" Then
						TransactionDate = '00010101';
						DateParts = StringFunctionsClientServer.SplitStringIntoSubstringArray(ColumnStringValue, "/",,"""");
						If DateParts.Count() = 3 then
							Try
								TransactionDate = Date(DateParts[2], DateParts[0], DatePArts[1]);
							Except
							EndTry;				
						EndIf;
						NewLine["CustomField"+Attr.Order] = TransactionDate;
						
					ElsIf Attr.ColumnName = "Number" Then
						NewLine["CustomField"+Attr.Order] = Left(ColumnStringValue,20);
						
					ElsIf Attr.ColumnName = "Company" Then
						VendorByCode = Catalogs.Companies.FindByCode(ColumnStringValue);
						VendorByDescription = Catalogs.Companies.FindByDescription(ColumnStringValue);
						If VendorByCode = Catalogs.Companies.EmptyRef() Then
							NewLine["CustomField"+Attr.Order] = VendorByDescription;
						Else
							NewLine["CustomField"+Attr.Order] = VendorByCode;
						EndIf;
					ElsIf Attr.ColumnName = "DSCompany" Then
						VendorByCode = Catalogs.Companies.FindByCode(ColumnStringValue);
						VendorByDescription = Catalogs.Companies.FindByDescription(ColumnStringValue);
						If VendorByCode = Catalogs.Companies.EmptyRef() Then
							NewLine["CustomField"+Attr.Order] = VendorByDescription;
						Else
							NewLine["CustomField"+Attr.Order] = VendorByCode;
						EndIf;	
						
					ElsIf Attr.ColumnName = "CompanyAddres" Then
						NewLine["CustomField"+Attr.Order] = ColumnStringValue;	
						
					ElsIf Attr.ColumnName = "DSShipTo" Then
						NewLine["CustomField"+Attr.Order] = ColumnStringValue;		
						
					ElsIf Attr.ColumnName = "DSConfirmTo" Then
						NewLine["CustomField"+Attr.Order] = ColumnStringValue;		
						
					ElsIf Attr.ColumnName = "DSBillTo" Then
						NewLine["CustomField"+Attr.Order] = ColumnStringValue;
						
					ElsIf Attr.ColumnName = "DSRefN" Then
						NewLine["CustomField"+Attr.Order] = Left(ColumnStringValue,20);
						
					ElsIf Attr.ColumnName = "SalesPerson" Then
						SalesPersonRef = Catalogs.SalesPeople.FindByDescription(ColumnStringValue);
					  	NewLine["CustomField"+Attr.Order] = SalesPersonRef;
						
					ElsIf Attr.ColumnName = "Currency" Then
						CurrencyRef = Catalogs.Currencies.FindByCode(ColumnStringValue);
					  	NewLine["CustomField"+Attr.Order] = CurrencyRef;
						
					ElsIf Attr.ColumnName = "Location" Then
						Location = Catalogs.Locations.FindByDescription(ColumnStringValue);
					  	NewLine["CustomField"+Attr.Order] = Location;	

					ElsIf Attr.ColumnName = "DeliveryDate" Then
						TransactionDate = '00010101';
						DateParts = StringFunctionsClientServer.SplitStringIntoSubstringArray(ColumnStringValue, "/",,"""");
						If DateParts.Count() = 3 then
							Try
								DeliveryDate = Date(DateParts[2], DateParts[0], DatePArts[1]);
							Except
							EndTry;				
						EndIf;
						NewLine["CustomField"+Attr.Order] = DeliveryDate;

					ElsIf Attr.ColumnName = "Project" Then
						Project = Catalogs.Projects.FindByDescription(ColumnStringValue);
					  	NewLine["CustomField"+Attr.Order] = Project;
						
					ElsIf Attr.ColumnName = "Class" Then
						Class = Catalogs.Classes.FindByDescription(ColumnStringValue);
					  	NewLine["CustomField"+Attr.Order] = Class;
						
					ElsIf Attr.ColumnName = "Memo" Then
						NewLine["CustomField"+Attr.Order] = ColumnStringValue;
						
					ElsIf Attr.ColumnName = "DocTotal" Then
						NewLine["CustomField"+Attr.Order] = ColumnStringValue;
						
					ElsIf Attr.ColumnName = "DocTotalRC" Then
						NewLine["CustomField"+Attr.Order] = Left(ColumnStringValue,20);
						
					ElsIf Attr.ColumnName = "Product" Then
						Product = Catalogs.Products.FindByCode(ColumnStringValue);
					  	NewLine["CustomField"+Attr.Order] = Product;
						
					ElsIf Attr.ColumnName = "Description" Then
						NewLine["CustomField"+Attr.Order] = ColumnStringValue;
						
					ElsIf Attr.ColumnName = "Price" Then
						NewLine["CustomField"+Attr.Order] = ColumnStringValue;
						
					ElsIf Attr.ColumnName = "LineTotal" Then
						NewLine["CustomField"+Attr.Order] = ColumnStringValue;
						
					ElsIf Attr.ColumnName = "LineProject" Then
						LProject = Catalogs.Projects.FindByDescription(ColumnStringValue);
					  	NewLine["CustomField"+Attr.Order] = LProject;	
						
					ElsIf Attr.ColumnName = "LineClass" Then
						LClass = Catalogs.Classes.FindByDescription(ColumnStringValue);
					  	NewLine["CustomField"+Attr.Order] = LClass;
						
					ElsIf Attr.ColumnName = "LineQuantity" Then
						NewLine["CustomField"+Attr.Order] = ColumnStringValue;		
						
					ElsIf Attr.ColumnName = "ToPost" Then
						NewLine["CustomField"+Attr.Order] = GetValueByName(ColumnStringValue,"Boolean");	
					EndIf;	
				EndIf;
			EndDo;
		
		ElsIf ActionType = "Bills" Then
		
			NewLine = UploadTable.Add();
			NewLine.LoadFlag = True;
			
			For Each Attr in CustomFieldMap Do 
				ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],Attr.AttributeName);
				If ColumnStringValue <> Undefined Then
					
					If Attr.ColumnName = "DocDate" Then
						TransactionDate = '00010101';
						DateParts = StringFunctionsClientServer.SplitStringIntoSubstringArray(ColumnStringValue, "/",,"""");
						If DateParts.Count() = 3 then
							Try
								TransactionDate = Date(DateParts[2], DateParts[0], DatePArts[1]);
							Except
							EndTry;				
						EndIf;
						NewLine["CustomField"+Attr.Order] = TransactionDate;
						
					ElsIf Attr.ColumnName = "Number" Then
						NewLine["CustomField"+Attr.Order] = Left(ColumnStringValue,20);	
						
					ElsIf Attr.ColumnName = "TableType" Then
						NewLine["CustomField"+Attr.Order] = ColumnStringValue;
						
					ElsIf Attr.ColumnName = "Company" Then
						VendorByCode = Catalogs.Companies.FindByCode(ColumnStringValue);
						VendorByDescription = Catalogs.Companies.FindByDescription(ColumnStringValue);
						If VendorByCode = Catalogs.Companies.EmptyRef() Then
							NewLine["CustomField"+Attr.Order] = VendorByDescription;
						Else
							NewLine["CustomField"+Attr.Order] = VendorByCode;
						EndIf;
					ElsIf Attr.ColumnName = "CompanyAddres" Then
						NewLine["CustomField"+Attr.Order] = ColumnStringValue;		
						
					ElsIf Attr.ColumnName = "Currency" Then
						CurrencyRef = Catalogs.Currencies.FindByCode(ColumnStringValue);
					  	NewLine["CustomField"+Attr.Order] = CurrencyRef;	
						
					ElsIf Attr.ColumnName = "APAccount" Then
						NewLine["CustomField"+Attr.Order] = ChartsOfAccounts.ChartOfAccounts.FindByCode(ColumnStringValue);
						
					ElsIf Attr.ColumnName = "DueDate" Then
						TransactionDate = '00010101';
						DateParts = StringFunctionsClientServer.SplitStringIntoSubstringArray(ColumnStringValue, "/",,"""");
						If DateParts.Count() = 3 then
							Try
								DueDate = Date(DateParts[2], DateParts[0], DatePArts[1]);
							Except
							EndTry;				
						EndIf;
						NewLine["CustomField"+Attr.Order] = DueDate;	
						
						
					ElsIf Attr.ColumnName = "SalesPerson" Then
						SalesPersonRef = Catalogs.SalesPeople.FindByDescription(ColumnStringValue);
					  	NewLine["CustomField"+Attr.Order] = SalesPersonRef;
					
						
					ElsIf Attr.ColumnName = "Location" Then
						Location = Catalogs.Locations.FindByDescription(ColumnStringValue);
					  	NewLine["CustomField"+Attr.Order] = Location;	

						
					ElsIf Attr.ColumnName = "DeliveryDate" Then
						TransactionDate = '00010101';
						DateParts = StringFunctionsClientServer.SplitStringIntoSubstringArray(ColumnStringValue, "/",,"""");
						If DateParts.Count() = 3 then
							Try
								DeliveryDate = Date(DateParts[2], DateParts[0], DatePArts[1]);
							Except
							EndTry;				
						EndIf;
						NewLine["CustomField"+Attr.Order] = DeliveryDate;

					ElsIf Attr.ColumnName = "Project" Then
						Project = Catalogs.Projects.FindByDescription(ColumnStringValue);
					  	NewLine["CustomField"+Attr.Order] = Project;
						
					ElsIf Attr.ColumnName = "Class" Then
						Class = Catalogs.Classes.FindByDescription(ColumnStringValue);
					  	NewLine["CustomField"+Attr.Order] = Class;
						
					ElsIf Attr.ColumnName = "Terms" Then
						NewLine["CustomField"+Attr.Order] = Catalogs.PaymentTerms.FindByDescription(ColumnStringValue);
						
					ElsIf Attr.ColumnName = "Memo" Then
						NewLine["CustomField"+Attr.Order] = ColumnStringValue;
						
					ElsIf Attr.ColumnName = "Product" Then
						Product = Catalogs.Products.FindByCode(ColumnStringValue);
					  	NewLine["CustomField"+Attr.Order] = Product;
						
					ElsIf Attr.ColumnName = "Description" Then
						NewLine["CustomField"+Attr.Order] = ColumnStringValue;
						
					ElsIf Attr.ColumnName = "Price" Then
						NewLine["CustomField"+Attr.Order] = ColumnStringValue;
						
					ElsIf Attr.ColumnName = "LineTotal" Then
						NewLine["CustomField"+Attr.Order] = ColumnStringValue;
						
					ElsIf Attr.ColumnName = "LinePO" Then
						LinePO = Documents.PurchaseOrder.FindByNumber(ColumnStringValue);
					  	NewLine["CustomField"+Attr.Order] = LinePO;	
						
					ElsIf Attr.ColumnName = "LineClass" Then
						LClass = Catalogs.Classes.FindByDescription(ColumnStringValue);
					  	NewLine["CustomField"+Attr.Order] = LClass;
						
					ElsIf Attr.ColumnName = "LineQuantity" Then
						NewLine["CustomField"+Attr.Order] = ColumnStringValue;		
						
					ElsIf Attr.ColumnName = "LineMemo" Then
						NewLine["CustomField"+Attr.Order] = ColumnStringValue;	
						
					ElsIf Attr.ColumnName = "LineAccount" Then
						NewLine["CustomField"+Attr.Order] = ChartsOfAccounts.ChartOfAccounts.FindByCode(ColumnStringValue);	
						
					ElsIf Attr.ColumnName = "ToPost" Then
						NewLine["CustomField"+Attr.Order] = GetValueByName(ColumnStringValue,"Boolean");	
					EndIf;	
				EndIf;
			EndDo;	
			
		ElsIf ActionType = "ItemReceipts" Then
		
			NewLine = UploadTable.Add();
			NewLine.LoadFlag = True;
			
			For Each Attr in CustomFieldMap Do 
				ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],Attr.AttributeName);
				If ColumnStringValue <> Undefined Then
					
					If Attr.ColumnName = "DocDate" Then
						TransactionDate = '00010101';
						DateParts = StringFunctionsClientServer.SplitStringIntoSubstringArray(ColumnStringValue, "/",,"""");
						If DateParts.Count() = 3 then
							Try
								TransactionDate = Date(DateParts[2], DateParts[0], DatePArts[1]);
							Except
							EndTry;				
						EndIf;
						NewLine["CustomField"+Attr.Order] = TransactionDate;
						
					ElsIf Attr.ColumnName = "Number" Then
						NewLine["CustomField"+Attr.Order] = Left(ColumnStringValue,20);	
						
						
					ElsIf Attr.ColumnName = "Company" Then
						VendorByCode = Catalogs.Companies.FindByCode(ColumnStringValue);
						VendorByDescription = Catalogs.Companies.FindByDescription(ColumnStringValue);
						If VendorByCode = Catalogs.Companies.EmptyRef() Then
							NewLine["CustomField"+Attr.Order] = VendorByDescription;
						Else
							NewLine["CustomField"+Attr.Order] = VendorByCode;
						EndIf;
					ElsIf Attr.ColumnName = "CompanyAddres" Then
							NewLine["CustomField"+Attr.Order] = ColumnStringValue;		
						
					ElsIf Attr.ColumnName = "Location" Then
						Location = Catalogs.Locations.FindByDescription(ColumnStringValue);
					  	NewLine["CustomField"+Attr.Order] = Location;	
						
					ElsIf Attr.ColumnName = "Currency" Then
						CurrencyRef = Catalogs.Currencies.FindByCode(ColumnStringValue);
					  	NewLine["CustomField"+Attr.Order] = CurrencyRef;		
						
					ElsIf Attr.ColumnName = "DueDate" Then
						TransactionDate = '00010101';
						DateParts = StringFunctionsClientServer.SplitStringIntoSubstringArray(ColumnStringValue, "/",,"""");
						If DateParts.Count() = 3 then
							Try
								DueDate = Date(DateParts[2], DateParts[0], DatePArts[1]);
							Except
							EndTry;				
						EndIf;
						NewLine["CustomField"+Attr.Order] = DueDate;	
						
						
					ElsIf Attr.ColumnName = "DeliveryDate" Then
						TransactionDate = '00010101';
						DateParts = StringFunctionsClientServer.SplitStringIntoSubstringArray(ColumnStringValue, "/",,"""");
						If DateParts.Count() = 3 then
							Try
								DeliveryDate = Date(DateParts[2], DateParts[0], DatePArts[1]);
							Except
							EndTry;				
						EndIf;
						NewLine["CustomField"+Attr.Order] = DeliveryDate;

					ElsIf Attr.ColumnName = "Project" Then
						Project = Catalogs.Projects.FindByDescription(ColumnStringValue);
					  	NewLine["CustomField"+Attr.Order] = Project;
						
					ElsIf Attr.ColumnName = "Class" Then
						Class = Catalogs.Classes.FindByDescription(ColumnStringValue);
					  	NewLine["CustomField"+Attr.Order] = Class;
						
					ElsIf Attr.ColumnName = "Memo" Then
						NewLine["CustomField"+Attr.Order] = ColumnStringValue;
						
					ElsIf Attr.ColumnName = "Product" Then
						Product = Catalogs.Products.FindByCode(ColumnStringValue);
					  	NewLine["CustomField"+Attr.Order] = Product;
						
					ElsIf Attr.ColumnName = "Description" Then
						NewLine["CustomField"+Attr.Order] = ColumnStringValue;
						
					ElsIf Attr.ColumnName = "Price" Then
						NewLine["CustomField"+Attr.Order] = ColumnStringValue;
						
					ElsIf Attr.ColumnName = "UoM" Then
						UoM = Catalogs.Units.FindByDescription(ColumnStringValue);
						NewLine["CustomField"+Attr.Order] = UoM;		
						
					ElsIf Attr.ColumnName = "LineTotal" Then
						NewLine["CustomField"+Attr.Order] = ColumnStringValue;
						
					ElsIf Attr.ColumnName = "LinePO" Then
						LinePO = Documents.PurchaseOrder.FindByNumber(ColumnStringValue);
					  	NewLine["CustomField"+Attr.Order] = LinePO;	
						
					ElsIf Attr.ColumnName = "LineClass" Then
						LClass = Catalogs.Classes.FindByDescription(ColumnStringValue);
					  	NewLine["CustomField"+Attr.Order] = LClass;
						
					ElsIf Attr.ColumnName = "LineQuantity" Then
						NewLine["CustomField"+Attr.Order] = ColumnStringValue;		
						
					ElsIf Attr.ColumnName = "ToPost" Then
						NewLine["CustomField"+Attr.Order] = GetValueByName(ColumnStringValue,"Boolean");	
					EndIf;	
				EndIf;
			EndDo;
			
		ElsIf ActionType = "BillPayments" Then
		
			NewLine = UploadTable.Add();
			NewLine.LoadFlag = True;
			
			For Each Attr in CustomFieldMap Do 
				ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],Attr.AttributeName);
				If ColumnStringValue <> Undefined Then
					
					If Attr.ColumnName = "DocDate" Then
						TransactionDate = '00010101';
						DateParts = StringFunctionsClientServer.SplitStringIntoSubstringArray(ColumnStringValue, "/",,"""");
						If DateParts.Count() = 3 then
							Try
								TransactionDate = Date(DateParts[2], DateParts[0], DatePArts[1]);
							Except
							EndTry;				
						EndIf;
						NewLine["CustomField"+Attr.Order] = TransactionDate;
						
					ElsIf Attr.ColumnName = "Number" Then
						NewLine["CustomField"+Attr.Order] = Left(ColumnStringValue,20);	
						
						
					ElsIf Attr.ColumnName = "Company" Then
						VendorByCode = Catalogs.Companies.FindByCode(ColumnStringValue);
						VendorByDescription = Catalogs.Companies.FindByDescription(ColumnStringValue);
						If VendorByCode = Catalogs.Companies.EmptyRef() Then
							NewLine["CustomField"+Attr.Order] = VendorByDescription;
						Else
							NewLine["CustomField"+Attr.Order] = VendorByCode;
						EndIf;
					ElsIf Attr.ColumnName = "BankAccount" Then
						NewLine["CustomField"+Attr.Order] = ChartsOfAccounts.ChartOfAccounts.FindByCode(ColumnStringValue);	
						
					ElsIf Attr.ColumnName = "Currency" Then
						CurrencyRef = Catalogs.Currencies.FindByCode(ColumnStringValue);
					  	NewLine["CustomField"+Attr.Order] = CurrencyRef;		
						
					ElsIf Attr.ColumnName = "PaymentMethod" Then
						PaymentMethod = Catalogs.PaymentMethods.FindByDescription(ColumnStringValue);
					  	NewLine["CustomField"+Attr.Order] = PaymentMethod;		
						
					ElsIf Attr.ColumnName = "PhysicalCheckNum" Then
						NewLine["CustomField"+Attr.Order] = ColumnStringValue;		
						
					ElsIf Attr.ColumnName = "Memo" Then
						NewLine["CustomField"+Attr.Order] = ColumnStringValue;
						
					ElsIf Attr.ColumnName = "Bill" Then
						Bill = Documents.PurchaseInvoice.FindByNumber(ColumnStringValue);
					  	NewLine["CustomField"+Attr.Order] = Bill;
						
					ElsIf Attr.ColumnName = "Payment" Then
						NewLine["CustomField"+Attr.Order] = ColumnStringValue;
						
					ElsIf Attr.ColumnName = "Due" Then
						NewLine["CustomField"+Attr.Order] = ColumnStringValue;
						
					ElsIf Attr.ColumnName = "Check" Then
						NewLine["CustomField"+Attr.Order] = ColumnStringValue;		
						
					ElsIf Attr.ColumnName = "ToPost" Then
						NewLine["CustomField"+Attr.Order] = GetValueByName(ColumnStringValue,"Boolean");	
					EndIf;	
				EndIf;
			EndDo;	
			
		ElsIf ActionType = "BankTransfer" Then
		
			NewLine = UploadTable.Add();
			NewLine.LoadFlag = True;
			
			For Each Attr in CustomFieldMap Do 
				ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],Attr.AttributeName);
				If ColumnStringValue <> Undefined Then
					
					If Attr.ColumnName = "DocDate" Then
						TransactionDate = '00010101';
						DateParts = StringFunctionsClientServer.SplitStringIntoSubstringArray(ColumnStringValue, "/",,"""");
						If DateParts.Count() = 3 then
							Try
								TransactionDate = Date(DateParts[2], DateParts[0], DatePArts[1]);
							Except
							EndTry;				
						EndIf;
						NewLine["CustomField"+Attr.Order] = TransactionDate;
						
					ElsIf Attr.ColumnName = "Number" Then
						NewLine["CustomField"+Attr.Order] = Left(ColumnStringValue,20);	
						
					ElsIf Attr.ColumnName = "AccountFrom" Then
						NewLine["CustomField"+Attr.Order] = ChartsOfAccounts.ChartOfAccounts.FindByCode(ColumnStringValue);	
						
					ElsIf Attr.ColumnName = "AccountTo" Then
						NewLine["CustomField"+Attr.Order] = ChartsOfAccounts.ChartOfAccounts.FindByCode(ColumnStringValue);		
						
					ElsIf Attr.ColumnName = "Amount" Then
						NewLine["CustomField"+Attr.Order] = ColumnStringValue;		
						
					ElsIf Attr.ColumnName = "Memo" Then
						NewLine["CustomField"+Attr.Order] = ColumnStringValue;
					EndIf;	
				EndIf;
			EndDo;	
			
		ElsIf ActionType = "Projects" Then
		
			NewLine = UploadTable.Add();
			NewLine.LoadFlag = True;
			
			For Each Attr in CustomFieldMap Do 
				ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],Attr.AttributeName);
				If ColumnStringValue <> Undefined Then
					
					If Attr.ColumnName = "Description" Then
						NewLine["CustomField"+Attr.Order] = ColumnStringValue;
						
					ElsIf Attr.ColumnName = "Customer" Then
						
						CustomerByCode = Catalogs.Companies.FindByCode(ColumnStringValue);
						CustomerByDescription = Catalogs.Companies.FindByDescription(ColumnStringValue);
						If CustomerByCode = Catalogs.Companies.EmptyRef() Then
							NewLine["CustomField"+Attr.Order] = CustomerByDescription;
						Else
							NewLine["CustomField"+Attr.Order] = CustomerByCode;
						EndIf;
						
					ElsIf Attr.ColumnName = "ReceiptsBudget" Then
						NewLine["CustomField"+Attr.Order] = ColumnStringValue;		
						
					ElsIf Attr.ColumnName = "ExpenseBudget" Then
						NewLine["CustomField"+Attr.Order] = ColumnStringValue;		
						
					ElsIf Attr.ColumnName = "HoursBudget" Then
						NewLine["CustomField"+Attr.Order] = ColumnStringValue;			
						
					ElsIf Attr.ColumnName = "Status" Then
						NewLine["CustomField"+Attr.Order] = ColumnStringValue;
						
					ElsIf Attr.ColumnName = "Type" Then
						NewLine["CustomField"+Attr.Order] = ColumnStringValue;	
						
					EndIf;	
				EndIf;
			EndDo;		
			
		ElsIf ActionType = "SalesInvoice" Then
			
			NewLine = UploadTable.Add();
			NewLine.LoadFlag = True;
			
			For Each Attr in CustomFieldMap Do 
				ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],Attr.AttributeName);
				If ColumnStringValue <> Undefined Then
					
					If Attr.ColumnName = "DocDate" Then
						TransactionDate = '00010101';
						DateParts = StringFunctionsClientServer.SplitStringIntoSubstringArray(ColumnStringValue, "/",,"""");
						If DateParts.Count() = 3 then
							Try
								TransactionDate = Date(DateParts[2], DateParts[0], DatePArts[1]);
							Except
							EndTry;				
						EndIf;
						NewLine["CustomField"+Attr.Order] = TransactionDate;
					ElsIf Attr.ColumnName = "DueDate" Then
						TransactionDate = '00010101';
						DateParts = StringFunctionsClientServer.SplitStringIntoSubstringArray(ColumnStringValue, "/",,"""");
						If DateParts.Count() = 3 then
							Try
								TransactionDate = Date(DateParts[2], DateParts[0], DatePArts[1]);
							Except
							EndTry;				
						EndIf;
						NewLine["CustomField"+Attr.Order] = TransactionDate;	
						
					ElsIf Attr.ColumnName = "Number" Then
						NewLine["CustomField"+Attr.Order] = Left(ColumnStringValue,20);
						
					ElsIf Attr.ColumnName = "Company" Then
						VendorByCode = Catalogs.Companies.FindByCode(ColumnStringValue);
						VendorByDescription = Catalogs.Companies.FindByDescription(ColumnStringValue);
						If VendorByCode = Catalogs.Companies.EmptyRef() Then
							NewLine["CustomField"+Attr.Order] = VendorByDescription;
						Else
							NewLine["CustomField"+Attr.Order] = VendorByCode;
						EndIf;
					ElsIf Attr.ColumnName = "ShipTo" Then
						NewLine["CustomField"+Attr.Order] = ColumnStringValue;		
						
					ElsIf Attr.ColumnName = "ConfirmTo" Then
						NewLine["CustomField"+Attr.Order] = ColumnStringValue;		
						
					ElsIf Attr.ColumnName = "BillTo" Then
						NewLine["CustomField"+Attr.Order] = ColumnStringValue;
						
					ElsIf Attr.ColumnName = "RefNum" Then
						NewLine["CustomField"+Attr.Order] = Left(ColumnStringValue,20);
						
					ElsIf Attr.ColumnName = "SalesPerson" Then
						SalesPersonRef = Catalogs.SalesPeople.FindByDescription(ColumnStringValue);
						NewLine["CustomField"+Attr.Order] = SalesPersonRef;
						
					ElsIf Attr.ColumnName = "Currency" Then
						CurrencyRef = Catalogs.Currencies.FindByCode(ColumnStringValue);
						NewLine["CustomField"+Attr.Order] = CurrencyRef;
						
					ElsIf Attr.ColumnName = "ARAccount" Then
						ARAccountRef = ChartsOfAccounts.ChartOfAccounts.FindByCode(ColumnStringValue);
						NewLine["CustomField"+Attr.Order] = ARAccountRef;	
						
					ElsIf Attr.ColumnName = "Location" Then
						Location = Catalogs.Locations.FindByDescription(ColumnStringValue);
						NewLine["CustomField"+Attr.Order] = Location;	
						
					ElsIf Attr.ColumnName = "PaymentMethod" Then
						PaymentMethod = Catalogs.PaymentMethods.FindByDescription(ColumnStringValue);
						NewLine["CustomField"+Attr.Order] = PaymentMethod;	
						
						
					ElsIf Attr.ColumnName = "DeliveryDate" Then
						TransactionDate = '00010101';
						DateParts = StringFunctionsClientServer.SplitStringIntoSubstringArray(ColumnStringValue, "/",,"""");
						If DateParts.Count() = 3 then
							Try
								DeliveryDate = Date(DateParts[2], DateParts[0], DatePArts[1]);
							Except
							EndTry;				
						EndIf;
						NewLine["CustomField"+Attr.Order] = DeliveryDate;
						
					ElsIf Attr.ColumnName = "Project" Then
						Project = Catalogs.Projects.FindByDescription(ColumnStringValue);
						NewLine["CustomField"+Attr.Order] = Project;
						
					ElsIf Attr.ColumnName = "Class" Then
						Class = Catalogs.Classes.FindByDescription(ColumnStringValue);
						NewLine["CustomField"+Attr.Order] = Class;
						
					ElsIf Attr.ColumnName = "Memo" Then
						NewLine["CustomField"+Attr.Order] = ColumnStringValue;
						
					ElsIf Attr.ColumnName = "Terms" Then
						NewLine["CustomField"+Attr.Order] = Catalogs.PaymentTerms.FindByDescription(ColumnStringValue);
						
					ElsIf Attr.ColumnName = "SalesTax" Then
						NewLine["CustomField"+Attr.Order] = ColumnStringValue;	
						
					ElsIf Attr.ColumnName = "Product" Then
						Product = Catalogs.Products.FindByCode(ColumnStringValue);
						NewLine["CustomField"+Attr.Order] = Product;
						
					ElsIf Attr.ColumnName = "Description" Then
						NewLine["CustomField"+Attr.Order] = ColumnStringValue;
						
					ElsIf Attr.ColumnName = "Price" Then
						NewLine["CustomField"+Attr.Order] = ColumnStringValue;
						
					ElsIf Attr.ColumnName = "LineTotal" Then
						NewLine["CustomField"+Attr.Order] = ColumnStringValue;
						
					ElsIf Attr.ColumnName = "LineProject" Then
						LProject = Catalogs.Projects.FindByDescription(ColumnStringValue);
						NewLine["CustomField"+Attr.Order] = LProject;	
						
					ElsIf Attr.ColumnName = "LineClass" Then
						LClass = Catalogs.Classes.FindByDescription(ColumnStringValue);
						NewLine["CustomField"+Attr.Order] = LClass;
						
					ElsIf Attr.ColumnName = "LineQuantity" Then
						NewLine["CustomField"+Attr.Order] = ColumnStringValue;		
						
					ElsIf Attr.ColumnName = "Taxable" Then
						NewLine["CustomField"+Attr.Order] = GetValueByName(ColumnStringValue,"Boolean");
						
					ElsIf Attr.ColumnName = "TaxableAmount" Then
						NewLine["CustomField"+Attr.Order] = ColumnStringValue;			
						
					ElsIf Attr.ColumnName = "LineOrder" Then
						NewLine["CustomField"+Attr.Order] = Documents.SalesOrder.FindByNumber(ColumnStringValue)
						
					ElsIf Attr.ColumnName = "ToPost" Then
						NewLine["CustomField"+Attr.Order] = GetValueByName(ColumnStringValue,"Boolean");	
					EndIf;	
				EndIf;
			EndDo;
			
		ElsIf ActionType = "CreditMemo" Then
			
			NewLine = UploadTable.Add();
			NewLine.LoadFlag = True;
			
			For Each Attr in CustomFieldMap Do 
				ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],Attr.AttributeName);
				If ColumnStringValue <> Undefined Then
					
					If Attr.ColumnName = "DocDate" Then
						TransactionDate = '00010101';
						DateParts = StringFunctionsClientServer.SplitStringIntoSubstringArray(ColumnStringValue, "/",,"""");
						If DateParts.Count() = 3 then
							Try
								TransactionDate = Date(DateParts[2], DateParts[0], DatePArts[1]);
							Except
							EndTry;				
						EndIf;
						NewLine["CustomField"+Attr.Order] = TransactionDate;
					ElsIf Attr.ColumnName = "DueDate" Then
						TransactionDate = '00010101';
						DateParts = StringFunctionsClientServer.SplitStringIntoSubstringArray(ColumnStringValue, "/",,"""");
						If DateParts.Count() = 3 then
							Try
								TransactionDate = Date(DateParts[2], DateParts[0], DatePArts[1]);
							Except
							EndTry;				
						EndIf;
						NewLine["CustomField"+Attr.Order] = TransactionDate;	
						
					ElsIf Attr.ColumnName = "Number" Then
						NewLine["CustomField"+Attr.Order] = Left(ColumnStringValue,20);
						
					ElsIf Attr.ColumnName = "Company" Then
						VendorByCode = Catalogs.Companies.FindByCode(ColumnStringValue);
						VendorByDescription = Catalogs.Companies.FindByDescription(ColumnStringValue);
						If VendorByCode = Catalogs.Companies.EmptyRef() Then
							NewLine["CustomField"+Attr.Order] = VendorByDescription;
						Else
							NewLine["CustomField"+Attr.Order] = VendorByCode;
						EndIf;
					ElsIf Attr.ColumnName = "ShipFromAddr" Then
						NewLine["CustomField"+Attr.Order] = ColumnStringValue;		
						
					ElsIf Attr.ColumnName = "RefNum" Then
						NewLine["CustomField"+Attr.Order] = Left(ColumnStringValue,20);
						
						
					ElsIf Attr.ColumnName = "SalesPerson" Then
						SalesPersonRef = Catalogs.SalesPeople.FindByDescription(ColumnStringValue);
						NewLine["CustomField"+Attr.Order] = SalesPersonRef;
						
					ElsIf Attr.ColumnName = "Currency" Then
						CurrencyRef = Catalogs.Currencies.FindByCode(ColumnStringValue);
						NewLine["CustomField"+Attr.Order] = CurrencyRef;
						
					ElsIf Attr.ColumnName = "ARAccount" Then
						ARAccountRef = ChartsOfAccounts.ChartOfAccounts.FindByCode(ColumnStringValue);
						NewLine["CustomField"+Attr.Order] = ARAccountRef;	
						
					ElsIf Attr.ColumnName = "Location" Then
						Location = Catalogs.Locations.FindByDescription(ColumnStringValue);
						NewLine["CustomField"+Attr.Order] = Location;	
						
					ElsIf Attr.ColumnName = "ParentInvoice" Then
						InvoiceRef = Documents.SalesInvoice.FindByNumber(ColumnStringValue);
						NewLine["CustomField"+Attr.Order] = InvoiceRef;
						
					ElsIf Attr.ColumnName = "ReturnType" Then
						NewLine["CustomField"+Attr.Order] = ColumnStringValue;
						
					ElsIf Attr.ColumnName = "Memo" Then
						NewLine["CustomField"+Attr.Order] = ColumnStringValue;
						
					ElsIf Attr.ColumnName = "SalesTaxRate" Then
						NewLine["CustomField"+Attr.Order] = Catalogs.SalesTaxRates.FindByDescription(ColumnStringValue);	
						
					ElsIf Attr.ColumnName = "Product" Then
						Product = Catalogs.Products.FindByCode(ColumnStringValue);
						NewLine["CustomField"+Attr.Order] = Product;
						
					ElsIf Attr.ColumnName = "Description" Then
						NewLine["CustomField"+Attr.Order] = ColumnStringValue;
						
					ElsIf Attr.ColumnName = "Price" Then
						NewLine["CustomField"+Attr.Order] = ColumnStringValue;
						
					ElsIf Attr.ColumnName = "LineTotal" Then
						NewLine["CustomField"+Attr.Order] = ColumnStringValue;
						
					ElsIf Attr.ColumnName = "LineProject" Then
						LProject = Catalogs.Projects.FindByDescription(ColumnStringValue);
						NewLine["CustomField"+Attr.Order] = LProject;	
						
					ElsIf Attr.ColumnName = "LineClass" Then
						LClass = Catalogs.Classes.FindByDescription(ColumnStringValue);
						NewLine["CustomField"+Attr.Order] = LClass;
						
					ElsIf Attr.ColumnName = "LineQuantity" Then
						NewLine["CustomField"+Attr.Order] = ColumnStringValue;		
						
					ElsIf Attr.ColumnName = "Taxable" Then
						NewLine["CustomField"+Attr.Order] = GetValueByName(ColumnStringValue,"Boolean");
						
					ElsIf Attr.ColumnName = "LineOrder" Then
						NewLine["CustomField"+Attr.Order] = Documents.SalesOrder.FindByNumber(ColumnStringValue)
						
					ElsIf Attr.ColumnName = "ToPost" Then
						NewLine["CustomField"+Attr.Order] = GetValueByName(ColumnStringValue,"Boolean");	
					EndIf;	
				EndIf;
			EndDo;	
			
		ElsIf ActionType = "SalesOrder" Then
			
			NewLine = UploadTable.Add();
			NewLine.LoadFlag = True;
			
			For Each Attr in CustomFieldMap Do 
				ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],Attr.AttributeName);
				If ColumnStringValue <> Undefined Then
					
					If Attr.ColumnName = "DocDate" Then
						TransactionDate = '00010101';
						DateParts = StringFunctionsClientServer.SplitStringIntoSubstringArray(ColumnStringValue, "/",,"""");
						If DateParts.Count() = 3 then
							Try
								TransactionDate = Date(DateParts[2], DateParts[0], DatePArts[1]);
							Except
							EndTry;				
						EndIf;
						NewLine["CustomField"+Attr.Order] = TransactionDate;
						
					ElsIf Attr.ColumnName = "Number" Then
						NewLine["CustomField"+Attr.Order] = Left(ColumnStringValue,20);
						
					ElsIf Attr.ColumnName = "Company" Then
						VendorByCode = Catalogs.Companies.FindByCode(ColumnStringValue);
						VendorByDescription = Catalogs.Companies.FindByDescription(ColumnStringValue);
						If VendorByCode = Catalogs.Companies.EmptyRef() Then
							NewLine["CustomField"+Attr.Order] = VendorByDescription;
						Else
							NewLine["CustomField"+Attr.Order] = VendorByCode;
						EndIf;
						
					ElsIf Attr.ColumnName = "ShipTo" Then
						NewLine["CustomField"+Attr.Order] = ColumnStringValue;		
						
					ElsIf Attr.ColumnName = "ConfirmTo" Then
						NewLine["CustomField"+Attr.Order] = ColumnStringValue;		
						
					ElsIf Attr.ColumnName = "BillTo" Then
						NewLine["CustomField"+Attr.Order] = ColumnStringValue;
						
						
					ElsIf Attr.ColumnName = "RefNum" Then
						NewLine["CustomField"+Attr.Order] = Left(ColumnStringValue,20);
						
					ElsIf Attr.ColumnName = "SalesPerson" Then
						SalesPersonRef = Catalogs.SalesPeople.FindByDescription(ColumnStringValue);
						NewLine["CustomField"+Attr.Order] = SalesPersonRef;
						
					ElsIf Attr.ColumnName = "DeliveryDate" Then
						TransactionDate = '00010101';
						DateParts = StringFunctionsClientServer.SplitStringIntoSubstringArray(ColumnStringValue, "/",,"""");
						If DateParts.Count() = 3 then
							Try
								DeliveryDate = Date(DateParts[2], DateParts[0], DatePArts[1]);
							Except
							EndTry;				
						EndIf;
						NewLine["CustomField"+Attr.Order] = DeliveryDate;
						
					ElsIf Attr.ColumnName = "Project" Then
						Project = Catalogs.Projects.FindByDescription(ColumnStringValue);
						NewLine["CustomField"+Attr.Order] = Project;
						
					ElsIf Attr.ColumnName = "Class" Then
						Class = Catalogs.Classes.FindByDescription(ColumnStringValue);
						NewLine["CustomField"+Attr.Order] = Class;
						
					ElsIf Attr.ColumnName = "Memo" Then
						NewLine["CustomField"+Attr.Order] = ColumnStringValue;
						
					ElsIf Attr.ColumnName = "SalesTax" Then
						NewLine["CustomField"+Attr.Order] = ColumnStringValue;	
						
					ElsIf Attr.ColumnName = "Product" Then
						Product = Catalogs.Products.FindByCode(ColumnStringValue);
						NewLine["CustomField"+Attr.Order] = Product;
						
					ElsIf Attr.ColumnName = "Description" Then
						NewLine["CustomField"+Attr.Order] = ColumnStringValue;
						
					ElsIf Attr.ColumnName = "Price" Then
						NewLine["CustomField"+Attr.Order] = ColumnStringValue;
						
					ElsIf Attr.ColumnName = "ShippingCost" Then
						NewLine["CustomField"+Attr.Order] = ColumnStringValue;	
						
					ElsIf Attr.ColumnName = "LineTotal" Then
						NewLine["CustomField"+Attr.Order] = ColumnStringValue;
						
					ElsIf Attr.ColumnName = "LineProject" Then
						LProject = Catalogs.Projects.FindByDescription(ColumnStringValue);
						NewLine["CustomField"+Attr.Order] = LProject;	
						
					ElsIf Attr.ColumnName = "LineClass" Then
						LClass = Catalogs.Classes.FindByDescription(ColumnStringValue);
						NewLine["CustomField"+Attr.Order] = LClass;
						
					ElsIf Attr.ColumnName = "LineQuantity" Then
						NewLine["CustomField"+Attr.Order] = ColumnStringValue;		
						
					ElsIf Attr.ColumnName = "Taxable" Then
						NewLine["CustomField"+Attr.Order] = GetValueByName(ColumnStringValue,"Boolean");
						
					ElsIf Attr.ColumnName = "TaxableAmount" Then
						NewLine["CustomField"+Attr.Order] = ColumnStringValue;			
						
					ElsIf Attr.ColumnName = "ToPost" Then
						NewLine["CustomField"+Attr.Order] = GetValueByName(ColumnStringValue,"Boolean");	
					EndIf;	
				EndIf;
			EndDo;
			
		ElsIf ActionType = "CashReceipt" Then
			
			NewLine = UploadTable.Add();
			NewLine.LoadFlag = True;
			
			For Each Attr in CustomFieldMap Do 
				ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],Attr.AttributeName);
				If ColumnStringValue <> Undefined Then
					
					If Attr.ColumnName = "DocDate" Then
						TransactionDate = '00010101';
						DateParts = StringFunctionsClientServer.SplitStringIntoSubstringArray(ColumnStringValue, "/",,"""");
						If DateParts.Count() = 3 then
							Try
								TransactionDate = Date(DateParts[2], DateParts[0], DatePArts[1]);
							Except
							EndTry;				
						EndIf;
						NewLine["CustomField"+Attr.Order] = TransactionDate;
						
					ElsIf Attr.ColumnName = "Number" Then
						NewLine["CustomField"+Attr.Order] = Left(ColumnStringValue,20);
						
					ElsIf Attr.ColumnName = "Company" Then
						VendorByCode = Catalogs.Companies.FindByCode(ColumnStringValue);
						VendorByDescription = Catalogs.Companies.FindByDescription(ColumnStringValue);
						If VendorByCode = Catalogs.Companies.EmptyRef() Then
							NewLine["CustomField"+Attr.Order] = VendorByDescription;
						Else
							NewLine["CustomField"+Attr.Order] = VendorByCode;
						EndIf;
						
					ElsIf Attr.ColumnName = "RefNum" Then
						NewLine["CustomField"+Attr.Order] = Left(ColumnStringValue,20);
						
					ElsIf Attr.ColumnName = "Currency" Then
						CurrencyRef = Catalogs.Currencies.FindByCode(ColumnStringValue);
						NewLine["CustomField"+Attr.Order] = CurrencyRef;
						
					ElsIf Attr.ColumnName = "Memo" Then
						NewLine["CustomField"+Attr.Order] = ColumnStringValue;	
						
					ElsIf Attr.ColumnName = "BankAccount" Then
						BankAccountRef = ChartsOfAccounts.ChartOfAccounts.FindByCode(ColumnStringValue);
						NewLine["CustomField"+Attr.Order] = BankAccountRef;	
						
					ElsIf Attr.ColumnName = "PaymentMethod" Then
						PaymentMethod = Catalogs.PaymentMethods.FindByDescription(ColumnStringValue);
						NewLine["CustomField"+Attr.Order] = PaymentMethod;	
						
					ElsIf Attr.ColumnName = "DepositType" Then
						NewLine["CustomField"+Attr.Order] = ColumnStringValue;	
						
					ElsIf Attr.ColumnName = "ARAccount" Then
						ARAccountRef = ChartsOfAccounts.ChartOfAccounts.FindByCode(ColumnStringValue);
						NewLine["CustomField"+Attr.Order] = ARAccountRef;		
						
					ElsIf Attr.ColumnName = "SalesOrder" Then
						SalesOrderRef = Documents.SalesOrder.FindByNumber(ColumnStringValue);
						NewLine["CustomField"+Attr.Order] = SalesOrderRef;
						
					ElsIf Attr.ColumnName = "TableType" Then
						NewLine["CustomField"+Attr.Order] = ColumnStringValue;
						
					ElsIf Attr.ColumnName = "DocumentType" Then
						NewLine["CustomField"+Attr.Order] = ColumnStringValue;	
						
					ElsIf Attr.ColumnName = "DocumentNum" Then
						NewLine["CustomField"+Attr.Order] = ColumnStringValue;
						
					ElsIf Attr.ColumnName = "Payment" Then
						NewLine["CustomField"+Attr.Order] = ColumnStringValue ;
						
					ElsIf Attr.ColumnName = "Overpayment" Then
						NewLine["CustomField"+Attr.Order] = ColumnStringValue;	
						
					ElsIf Attr.ColumnName = "ToPost" Then
						NewLine["CustomField"+Attr.Order] = GetValueByName(ColumnStringValue,"Boolean");	
					EndIf;	
				EndIf;
			EndDo;	
	
		ElsIf ActionType = "Checks" Then
			
			NewLine = UploadTable.Add();
			NewLine.LoadFlag = True;

			For Each Attr in CustomFieldMap Do 
				ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],Attr.AttributeName);
				If ColumnStringValue <> Undefined Then
					If Attr.ColumnName = "ToPost" Then
						NewLine["CustomField"+Attr.Order] = GetValueByName(ColumnStringValue,"Boolean");		
					EndIf;	
				EndIf;
			EndDo;
			
			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Date [char]");
			If ColumnStringValue <> Undefined Then
				
				TransactionDate = '00010101';
				DateParts = StringFunctionsClientServer.SplitStringIntoSubstringArray(ColumnStringValue, "/",,"""");
				If DateParts.Count() = 3 then
					Try
						TransactionDate 	= Date(DateParts[2], DateParts[0], DatePArts[1]);
					Except
					EndTry;				
				EndIf;
				
				NewLine.CheckDate = TransactionDate;
			EndIf;

			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Number [char(6)]");
			If ColumnStringValue <> Undefined Then
				NewLine.CheckNumber = ColumnStringValue;
			EndIf;

			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Bank account [ref]");
			If ColumnStringValue <> Undefined Then
				AccountByCode = ChartsOfAccounts.ChartOfAccounts.FindByCode(ColumnStringValue);
				AccountByDescription = ChartsOfAccounts.ChartOfAccounts.FindByDescription(ColumnStringValue);
				If AccountByCode = ChartsOfAccounts.ChartOfAccounts.EmptyRef() Then
					NewLine.CheckBankAccount = AccountByDescription;
				Else
					NewLine.CheckBankAccount = AccountByCode;
				EndIf;
			EndIf;

			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Vendor [ref]");
			If ColumnStringValue <> Undefined Then
				VendorByCode = Catalogs.Companies.FindByCode(ColumnStringValue);
				VendorByDescription = Catalogs.Companies.FindByDescription(ColumnStringValue);
				If VendorByCode = Catalogs.Companies.EmptyRef() Then
					NewLine.CheckVendor = VendorByDescription;
				Else
					NewLine.CheckVendor = VendorByCode;
				EndIf;
			EndIf;
			
			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Check memo [char]");
			If ColumnStringValue <> Undefined Then
				NewLine.CheckMemo = ColumnStringValue;
			EndIf;
			
			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Line account [ref]");
			If ColumnStringValue <> Undefined Then
				AccountByCode = ChartsOfAccounts.ChartOfAccounts.FindByCode(ColumnStringValue);
				AccountByDescription = ChartsOfAccounts.ChartOfAccounts.FindByDescription(ColumnStringValue);
				If AccountByCode = ChartsOfAccounts.ChartOfAccounts.EmptyRef() Then				
					NewLine.CheckLineAccount = AccountByDescription;
				Else
					NewLine.CheckLineAccount = AccountByCode;
				EndIf;
			EndIf;

			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Line memo [char]");
			If ColumnStringValue <> Undefined Then
				NewLine.ColumnStringValue = ColumnStringValue;
			EndIf;

			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Line amount [num]");
			If ColumnStringValue <> Undefined Then
				NewLine.CheckLineAmount = ColumnStringValue;
			EndIf;
			
			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Line class [ref]");
			If ColumnStringValue <> Undefined Then
				NewLine.CheckLineClass = Catalogs.Classes.FindByDescription(ColumnStringValue);
			EndIf;

			
		ElsIf ActionType = "Deposits" Then
			
			NewLine = UploadTable.Add();
			NewLine.LoadFlag = True;
			
			For Each Attr in CustomFieldMap Do 
				ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],Attr.AttributeName);
				If ColumnStringValue <> Undefined Then
					If Attr.ColumnName = "Number" Then
						NewLine["CustomField"+Attr.Order] = Left(ColumnStringValue,20);
					ElsIf Attr.ColumnName = "ToPost" Then
						NewLine["CustomField"+Attr.Order] = GetValueByName(ColumnStringValue,"Boolean");		
					EndIf;	
				EndIf;
			EndDo;


			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Date [char]");
			If ColumnStringValue <> Undefined Then
				TransactionDate = '00010101';
				DateParts = StringFunctionsClientServer.SplitStringIntoSubstringArray(ColumnStringValue, "/",,"""");
				If DateParts.Count() = 3 then
					Try
						TransactionDate 	= Date(DateParts[2], DateParts[0], DatePArts[1]);
					Except
					EndTry;				
				EndIf;
				
				NewLine.DepositDate = TransactionDate;
			EndIf;

			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Bank account [ref]");
			If ColumnStringValue <> Undefined Then
				AccountByCode = ChartsOfAccounts.ChartOfAccounts.FindByCode(ColumnStringValue);
				AccountByDescription = ChartsOfAccounts.ChartOfAccounts.FindByDescription(ColumnStringValue);
				If AccountByCode = ChartsOfAccounts.ChartOfAccounts.EmptyRef() Then
					NewLine.DepositBankAccount = AccountByDescription;
				Else
					NewLine.DepositBankAccount = AccountByCode;
				EndIf;
			EndIf;
			

			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Deposit memo [char]");
			If ColumnStringValue <> Undefined Then
				NewLine.DepositMemo = ColumnStringValue;
			EndIf;
		
			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Line company [ref]");
			If ColumnStringValue <> Undefined Then
				NewLine.DepositLineCompany = Catalogs.Companies.FindByDescription(ColumnStringValue);
			EndIf;
					
			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Line account [ref]");
			If ColumnStringValue <> Undefined Then
				AccountByCode = ChartsOfAccounts.ChartOfAccounts.FindByCode(ColumnStringValue);
				AccountByDescription = ChartsOfAccounts.ChartOfAccounts.FindByDescription(ColumnStringValue);
				If AccountByCode = ChartsOfAccounts.ChartOfAccounts.EmptyRef() Then
					NewLine.DepositLineAccount = AccountByDescription;
				Else
					NewLine.DepositLineAccount = AccountByCode;
				EndIf;
			EndIf;

			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Line amount [num]");
			If ColumnStringValue <> Undefined Then
				NewLine.DepositLineAmount = ColumnStringValue;
			EndIf;
			
			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Line class [ref]");
			If ColumnStringValue <> Undefined Then
				NewLine.DepositLineClass = Catalogs.Classes.FindByDescription(ColumnStringValue,True);
			EndIf;

			
			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Line memo [char]");
			If ColumnStringValue <> Undefined Then
				NewLine.DepositLineMemo = ColumnStringValue;
			EndIf;
			
		ElsIf ActionType = "CustomersVendors" Then
			
			NewLine = UploadTable.Add();
			NewLine.LoadFlag = True;
			
			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Type [0 - Customer, 1 - Vendor, 2 - Both]");
			If ColumnStringValue <> Undefined Then
				Try
					CustomerTypeValue = Number(ColumnStringValue);
				
					If CustomerTypeValue = 0 OR
						CustomerTypeValue = 1 OR
						CustomerTypeValue = 2 Then
							NewLine.CustomerType = TrimAll(CustomerTypeValue);
					Else
						NewLine.CustomerType = 0;
					EndIf;
	
				Except
					NewLine.CustomerType = 0;
				EndTry;
			EndIf;

			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Company code [char(5)]");
			If ColumnStringValue <> Undefined Then
				NewLine.CustomerCode = ColumnStringValue;
			EndIf;
			
			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Company name [char(150)]");
			If ColumnStringValue <> Undefined Then
				NewLine.CustomerDescription = ColumnStringValue;
			EndIf;
			
			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Full name [char(150)]");
			If ColumnStringValue <> Undefined Then
				NewLine.CustomerFullName = ColumnStringValue;
			EndIf;
			
			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Default billing address [T - true, F - false]");
			If ColumnStringValue <> Undefined Then
				NewLine.DefaultBillingAddress = ColumnStringValue;
			EndIf;
			
			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Default shipping address [T - true, F - false]");
			If ColumnStringValue <> Undefined Then
				NewLine.DefaultShippingAddress = ColumnStringValue;
			EndIf;
			
			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Income account [ref]");
			If ColumnStringValue <> Undefined Then
				NewLine.CustomerIncomeAccount = ChartsOfAccounts.ChartOfAccounts.FindByCode(ColumnStringValue);
			EndIf;
			
			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Expense account [ref]");
			If ColumnStringValue <> Undefined Then
				NewLine.CustomerExpenseAccount = ChartsOfAccounts.ChartOfAccounts.FindByCode(ColumnStringValue);
			EndIf;

			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"1099 vendor [T - true, F - false]");
			If ColumnStringValue <> Undefined Then
				NewLine.CustomerVendor1099 = ColumnStringValue;
			EndIf;
			
			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Employee [T - true, F - false]");
			If ColumnStringValue <> Undefined Then
				NewLine.CustomerEmployee = ColumnStringValue;
			EndIf;

			
			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"EIN or SSN");
			If ColumnStringValue <> Undefined Then
				If ColumnStringValue = "EIN" Then
					NewLine.CustomerEIN_SSN = Enums.FederalIDType.EIN;
				ElsIf ColumnStringValue = "SSN" Then
					NewLine.CustomerEIN_SSN = Enums.FederalIDType.SSN;
				EndIf
			EndIf;
			
			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Notes [char]");
			If ColumnStringValue <> Undefined Then
				NewLine.CustomerNotes = ColumnStringValue;
			EndIf;
			
			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Website [char(200)]");
			If ColumnStringValue <> Undefined Then
				NewLine.CustomerWebsite = ColumnStringValue;
			EndIf;
		
			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Terms [ref]");
			If ColumnStringValue <> Undefined Then
				If ColumnStringValue = "" Then
					NewLine.CustomerTerms = Catalogs.PaymentTerms.Net30;
				Else
					NewLine.CustomerTerms = Catalogs.PaymentTerms.FindByDescription(ColumnStringValue);
				EndIf;
			ElsIf UpdateOption = "AllFields" then
				NewLine.CustomerTerms = Catalogs.PaymentTerms.Net30;
			EndIf;
			
			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Company CF1 string [char(100)]");
			If ColumnStringValue <> Undefined Then
				NewLine.CustomerCF1String = ColumnStringValue;
			EndIf;
			
			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Company CF1 num [num]");
			If ColumnStringValue <> Undefined Then
				NewLine.CustomerCF1Num = ColumnStringValue;
			EndIf;
			
			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Company CF2 string [char(100)]");
			If ColumnStringValue <> Undefined Then
				NewLine.CustomerCF2String = ColumnStringValue;
			EndIf;
			
			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Company CF2 num [num]");
			If ColumnStringValue <> Undefined Then
				NewLine.CustomerCF2Num = ColumnStringValue;
			EndIf;

			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Company CF3 string [char(100)]");
			If ColumnStringValue <> Undefined Then
				NewLine.CustomerCF3String = ColumnStringValue;
			EndIf;
			
			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Company CF3 num [num]");
			If ColumnStringValue <> Undefined Then
				NewLine.CustomerCF3Num = ColumnStringValue;
			EndIf;

			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Company CF4 string [char(100)]");
			If ColumnStringValue <> Undefined Then
				NewLine.CustomerCF4String = ColumnStringValue;
			EndIf;
			
			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Company CF4 num [num]");
			If ColumnStringValue <> Undefined Then
				NewLine.CustomerCF4Num = ColumnStringValue;
			EndIf;
			
			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Company CF5 string [char(100)]");
			If ColumnStringValue <> Undefined Then
				NewLine.CustomerCF5String = ColumnStringValue;
			EndIf;
			
			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Company CF5 num [num]");
			If ColumnStringValue <> Undefined Then
				NewLine.CustomerCF5Num = ColumnStringValue;
			EndIf;
			
			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Vendor tax ID [char(15)]");
			If ColumnStringValue <> Undefined Then
				NewLine.CustomerVendorTaxID = ColumnStringValue;
			EndIf;
			
			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Customer sales person [ref]");
			If ColumnStringValue <> Undefined Then
				NewLine.CustomerSalesPerson = Catalogs.SalesPeople.FindByDescription(ColumnStringValue);
			EndIf;
						
			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Customer price level [ref]");
			If ColumnStringValue <> Undefined Then
				NewLine.CustomerPriceLevel = Catalogs.PriceLevels.FindByDescription(ColumnStringValue);
			EndIf;

			// billing address
			
			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Address ID [char(25)]");
			If ColumnStringValue <> Undefined Then
				NewLine.CustomerAddressID = ColumnStringValue;
			EndIf;

			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Salutation [char(15)]");
			If ColumnStringValue <> Undefined Then
				NewLine.AddressSalutation = ColumnStringValue;
			EndIf;
		
			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"First name [char(200)]");
			If ColumnStringValue <> Undefined Then
				NewLine.CustomerFirstName = ColumnStringValue;
			EndIf;

			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Middle name [char(200)]");
			If ColumnStringValue <> Undefined Then
				NewLine.CustomerMiddleName = ColumnStringValue;
			EndIf;

			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Last name [char(200)]");
			If ColumnStringValue <> Undefined Then
				NewLine.CustomerLastName = ColumnStringValue;
			EndIf;

			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Suffix [char(10)]");
			If ColumnStringValue <> Undefined Then
				NewLine.AddressSuffix = ColumnStringValue;
			EndIf;
			
			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Job title [char(200)]");
			If ColumnStringValue <> Undefined Then
				NewLine.AddressJobTitle = ColumnStringValue;
			EndIf;
		
			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Phone [char(50)]");
			If ColumnStringValue <> Undefined Then
				NewLine.CustomerPhone = ColumnStringValue;
			EndIf;
			
			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Cell [char(50)]");
			If ColumnStringValue <> Undefined Then
				NewLine.CustomerCell = ColumnStringValue;
			EndIf;

			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Fax [char(50)]");
			If ColumnStringValue <> Undefined Then
				NewLine.CustomerFax = ColumnStringValue;
			EndIf;

			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"E-mail [char(100)]");
			If ColumnStringValue <> Undefined Then
				NewLine.CustomerEmail = ColumnStringValue;
			EndIf;

			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Address line 1 [char(250)]");
			If ColumnStringValue <> Undefined Then
				NewLine.CustomerAddressLine1 = ColumnStringValue;
			EndIf;

			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Address line 2 [char(250)]");
			If ColumnStringValue <> Undefined Then
				NewLine.CustomerAddressLine2 = ColumnStringValue;
			EndIf;
			
			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Address line 3 [char(250)]");
			If ColumnStringValue <> Undefined Then
				NewLine.CustomerAddressLine3 = ColumnStringValue;
			EndIf;

			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"City [char(100)]");
			If ColumnStringValue <> Undefined Then
				NewLine.CustomerCity = ColumnStringValue;
			EndIf;

			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"State [ref]");
			If ColumnStringValue <> Undefined Then
				NewLine.CustomerState = Catalogs.States.FindByCode(ColumnStringValue);
			EndIf;

			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Country [ref]");
			If ColumnStringValue <> Undefined Then
				NewLine.CustomerCountry = Catalogs.Countries.FindByCode(ColumnStringValue);
			EndIf;

			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"ZIP [char(20)]");
			If ColumnStringValue <> Undefined Then
				NewLine.CustomerZIP = ColumnStringValue;
			EndIf;
			
			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Address notes [char]");
			If ColumnStringValue <> Undefined Then
				NewLine.CustomerAddressNotes = ColumnStringValue;
			EndIf;
						
			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Shipping address line 1 [char(250)]");
			If ColumnStringValue <> Undefined Then
				NewLine.CustomerShippingAddressLine1 = ColumnStringValue;
			EndIf;

			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Shipping address line 2 [char(250)]");
			If ColumnStringValue <> Undefined Then
				NewLine.CustomerShippingAddressLine2 = ColumnStringValue;
			EndIf;
			
			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Shipping address line 3 [char(250)]");
			If ColumnStringValue <> Undefined Then
				NewLine.CustomerShippingAddressLine3 = ColumnStringValue;
			EndIf;

			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Shipping City [char(100)]");
			If ColumnStringValue <> Undefined Then
				NewLine.CustomerShippingCity = ColumnStringValue;
			EndIf;

			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Shipping State [ref]");
			If ColumnStringValue <> Undefined Then
				NewLine.CustomerShippingState = Catalogs.States.FindByCode(ColumnStringValue);
			EndIf;

			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Shipping Country [ref]");
			If ColumnStringValue <> Undefined Then
				NewLine.CustomerShippingCountry = Catalogs.Countries.FindByCode(ColumnStringValue);
			EndIf;

			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Shipping ZIP [char(20)]");
			If ColumnStringValue <> Undefined Then
				NewLine.CustomerShippingZIP = ColumnStringValue;
			EndIf;
			
			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Address CF1 string [char(200)]");
			If ColumnStringValue <> Undefined Then
				NewLine.AddressCF1String = ColumnStringValue;
			EndIf;
			
			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Address CF2 string [char(200)]");
			If ColumnStringValue <> Undefined Then
				NewLine.AddressCF2String = ColumnStringValue;
			EndIf;

			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Address CF3 string [char(200)]");
			If ColumnStringValue <> Undefined Then
				NewLine.AddressCF3String = ColumnStringValue;
			EndIf;

			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Address CF4 string [char(200)]");
			If ColumnStringValue <> Undefined Then
				NewLine.AddressCF4String = ColumnStringValue;
			EndIf;

			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Address CF5 string [char(200)]");
			If ColumnStringValue <> Undefined Then
				NewLine.AddressCF5String = ColumnStringValue;
			EndIf;
			
			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Address sales person [ref]");
			If ColumnStringValue <> Undefined Then
				NewLine.AddressSalesPerson = Catalogs.SalesPeople.FindByDescription(ColumnStringValue);
			EndIf;
			
			
			For Each Attr in CustomFieldMap Do 
				ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],Attr.AttributeName);
				If ColumnStringValue <> Undefined Then
					If Attr.ColumnName = "STaxable" Then
						NewLine["CustomField"+Attr.Order] = ColumnStringValue;
					ElsIf Attr.ColumnName = "STaxRate" Then
						SalestaxRateRef = Catalogs.SalesTaxRates.FindByDescription(ColumnStringValue,True);
					  	NewLine["CustomField"+Attr.Order] = SalestaxRateRef;		
					EndIf
				EndIf;
			EndDo;	
						
		ElsIf ActionType = "Items" Then
			
			NewLine = UploadTable.Add();
			NewLine.LoadFlag = True;
			
			ToRefill = (UpdateOption = "AllFields");
			
			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Product OR Service");
			If ColumnStringValue <> Undefined Then
				NewLine.ProductType = GetValueByName(ColumnStringValue,"ItemType");
			EndIf;
			
			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Parent [char 50]");
			If ColumnStringValue <> Undefined Then
				NewLine.ProductParent = Catalogs.Products.FindByCode(ColumnStringValue);
			EndIf;
			
			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Item code [char(50)]");
			If ColumnStringValue <> Undefined Then
				NewLine.ProductCode = ColumnStringValue;
			EndIf;

			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Item description [char(150)]");
			If ColumnStringValue <> Undefined Then
				NewLine.ProductDescription = ColumnStringValue;
			EndIf;
			
			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Purchase description [char(150)]");
			If ColumnStringValue <> Undefined Then
				NewLine.PurchaseDescription = ColumnStringValue;
			EndIf;

			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Income account [ref]");
			If ColumnStringValue <> Undefined Then
				NewLine.ProductIncomeAcct = ChartsOfAccounts.ChartOfAccounts.FindByCode(ColumnStringValue);
			Elsif ToRefill Then 
				NewLine.ProductIncomeAcct = Constants.IncomeAccount.Get();
			EndIf;	
			
			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Inventory or expense account [ref]");
			If ColumnStringValue <> Undefined Then
				NewLine.ProductInvOrExpenseAcct = ChartsOfAccounts.ChartOfAccounts.FindByCode(ColumnStringValue);
			Elsif ToRefill Then 
				If NewLine.ProductType = Enums.InventoryTypes.Inventory Then	
					NewLine.ProductInvOrExpenseAcct = GeneralFunctions.InventoryAcct(Enums.InventoryTypes.Inventory);	
				ElsIf NewLine.ProductType = Enums.InventoryTypes.NonInventory Then		
					NewLine.ProductInvOrExpenseAcct = GeneralFunctions.InventoryAcct(Enums.InventoryTypes.NonInventory);
				EndIf;
			EndIf;

			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"COGS account [ref]");
			If ColumnStringValue <> Undefined Then
				NewLine.ProductCOGSAcct = ChartsOfAccounts.ChartOfAccounts.FindByCode(ColumnStringValue);
			Elsif ToRefill Then 
				If NewLine.ProductType = Enums.InventoryTypes.Inventory Then	
					NewLine.ProductCOGSAcct = GeneralFunctions.GetDefaultCOGSAcct();
				ElsIf NewLine.ProductType = Enums.InventoryTypes.NonInventory Then	
					NewLine.ProductCOGSAcct = GeneralFunctions.GetEmptyAcct();	
				EndIf;
			EndIf;

			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Price [num]");
			If ColumnStringValue <> Undefined Then
				NewLine.ProductPrice = ColumnStringValue;
			EndIf;
			
			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Cost [Num]");
			If ColumnStringValue <> Undefined Then
				NewLine.ProductCost = ColumnStringValue;
			EndIf;
			
			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Qty [num]");
			If ColumnStringValue <> Undefined Then
				NewLine.ProductQty = ColumnStringValue;
			EndIf;
			
			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Value [num]");
			If ColumnStringValue <> Undefined Then
				NewLine.ProductValue = ColumnStringValue;
			EndIf;
			
			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Taxable [T - true, F - false]");
			If ColumnStringValue <> Undefined Then
				//NewLine.ProductTaxable = GetValueByName(ColumnStringValue,"ItemTaxable");
				NewLine.ProductTaxable = ColumnStringValue;
			EndIf;


			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Category [ref]");
			If ColumnStringValue <> Undefined Then
				NewLine.ProductCategory = Catalogs.ProductCategories.FindByDescription(ColumnStringValue);
				If NewLine.ProductCategory.IsEmpty() Then 
					NewCategory = Catalogs.ProductCategories.CreateItem();
					NewCategory.Description = ColumnStringValue;
					NewCategory.SetNewCode();
					NewCategory.Write();
					NewLine.ProductCategory = NewCategory.Ref;
				EndIf;	
			EndIf;

			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"UoM [ref]");
			If ColumnStringValue <> Undefined Then
				NewLine.ProductUoM = Catalogs.UM.FindByDescription(ColumnStringValue);
			EndIf;

			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Vendor Code [char(50)]");
			If ColumnStringValue <> Undefined Then
				NewLine.ProductVendorCode = ColumnStringValue;
			EndIf;
			
			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Prefered Vendor [char 50]");
			If ColumnStringValue <> Undefined Then
				NewLine.ProductPreferedVendor = Catalogs.Companies.FindByDescription(ColumnStringValue,True);
			EndIf;
			
			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"CF1String [char(100)]");
			If ColumnStringValue <> Undefined Then
				NewLine.ProductCF1String = ColumnStringValue;
			EndIf;
			
			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"CF1Num [num]");
			If ColumnStringValue <> Undefined Then
				NewLine.ProductCF1Num = ColumnStringValue;
			EndIf;

			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"CF2String [char(100)]");
			If ColumnStringValue <> Undefined Then
				NewLine.ProductCF2String = ColumnStringValue;
			EndIf;
			
			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"CF2Num [num]");
			If ColumnStringValue <> Undefined Then
				NewLine.ProductCF2Num = ColumnStringValue;
			EndIf;

			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"CF3String [char(100)]");
			If ColumnStringValue <> Undefined Then
				NewLine.ProductCF3String = ColumnStringValue;
			EndIf;
			
			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"CF3Num [num]");
			If ColumnStringValue <> Undefined Then
				NewLine.ProductCF3Num = ColumnStringValue;
			EndIf;
			
			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"CF4String [char(100)]");
			If ColumnStringValue <> Undefined Then
				NewLine.ProductCF4String = ColumnStringValue;
			EndIf;
			
			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"CF4Num [num]");
			If ColumnStringValue <> Undefined Then
				NewLine.ProductCF4Num = ColumnStringValue;
			EndIf;
			
			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"CF5String [char(100)]");
			If ColumnStringValue <> Undefined Then
				NewLine.ProductCF5String = ColumnStringValue;
			EndIf;
			
			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"CF5Num [num]");
			If ColumnStringValue <> Undefined Then
				NewLine.ProductCF5Num = ColumnStringValue;
			EndIf;
			
			ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],"Update [char 50]");
			If ColumnStringValue <> Undefined Then
				NewLine.ProductUpdate = Catalogs.Products.FindByCode(ColumnStringValue);
			EndIf;
			
			For Each Attr in CustomFieldMap Do 
				ColumnStringValue = GetStringValueOfAttribute(Source[RowCounter],Attr.AttributeName);
				If ColumnStringValue <> Undefined Then
					If Attr.ColumnName = "UoM" Then
						UOMRef = Catalogs.UnitSets.FindByDescription(ColumnStringValue);
						NewLine["CustomField"+Attr.Order] = UOMRef;
					ElsIf Attr.ColumnName = "UPCCode" Then
						NewLine["CustomField"+Attr.Order] = ColumnStringValue;	
					ElsIf Attr.ColumnName = "ReorderPoint" Then
						NewLine["CustomField"+Attr.Order] = ColumnStringValue;		
					EndIf
				EndIf;
			EndDo;	
			
						
		EndIf;
				
	EndDo;
		
	Object.DataList.Load(UploadTable);
	
EndProcedure

&AtServer
Function FindAttributeColumnNumber1(AttributeName)
	
	FoundAttribute = Undefined;
	
	RowFilter = New Structure;
	RowFilter.Insert("AttributeName",AttributeName);
	
	ReplacedName = ObjectCustomFieldMap.FindRows(RowFilter);
	If ReplacedName.Count() > 0 Then 
		If ReplacedName[0].CustomName = "(NOT USED)" Then 
			Return Undefined;
		Else	
			RowFilter.AttributeName = ReplacedName[0].CustomName
		EndIf;	
	EndIf;	
	
	FoundRows = Attributes.FindRows(RowFilter);
	If FoundRows.Count() > 0 Then
		If TrimAll(FoundRows[0].Value) <> "" Then
			FoundAttribute = FoundRows[0].Value;
		Else 	
			FoundAttribute = FoundRows[0].ColumnNumber;
		EndIf;	
	EndIf;
	
	Return ?(FoundAttribute = 0, Undefined, FoundAttribute);
	
	
EndFunction

&AtServer
Function GetStringValueOfAttribute(NewLine, AttributeName)
	
	FoundAttribute = Undefined;
	
	RowFilter = New Structure;
	RowFilter.Insert("AttributeName",AttributeName);
	
	ReplacedName = ObjectCustomFieldMap.FindRows(RowFilter);
	If ReplacedName.Count() > 0 Then 
		If ReplacedName[0].CustomName = "(NOT USED)" Then 
			Return Undefined;
		Else	
			RowFilter.AttributeName = ReplacedName[0].CustomName
		EndIf;	
	EndIf;	
	
	FoundRows = Attributes.FindRows(RowFilter);
	If FoundRows.Count() > 0 Then
		AttributeNum = FoundRows[0].ColumnNumber;
		If AttributeNum <> 0 Then
			StringValue = TrimAll(NewLine[AttributeNum - 1]);
			If StringValue = "" Then
				StringValue = TrimAll(FoundRows[0].Value);
			EndIf;	
		Else 	
			StringValue = TrimAll(FoundRows[0].Value);
		EndIf;	
	EndIf;
	
	Return ?(StringValue = "", Undefined, StringValue);

EndFunction	

&AtServer
Procedure LoadData(Cancel)
	
	If Object.DataList.Count() = 0 Then
		Return;
	EndIf;
		
	If Cancel Then
		Return;
	EndIf;
	
	CountOfLoadedItems = 0;
	GlobalErrorMessage = "";
		
	If ActionType = "Expensify" Then
		
		PrevNumber = Undefined;
		DocObject = Undefined;
		DocPost = False;
		
		ColumnNames = New Structure;
		For Each Attr in CustomFieldMap Do 
			ColumnNames.Insert(Attr.ColumnName,"CustomField"+Attr.Order);
		EndDo;	
		
		PrevSearchBase = New Structure;
		PrevSearchBase.Insert(ColumnNames["Number"],Undefined);
		PrevSearchBase.Insert(ColumnNames["Date"],Undefined);
		PrevSearchBase.Insert(ColumnNames["Company"],Undefined);
		
		QuantityPrecision = GeneralFunctionsReusable.DefaultQuantityPrecision();
		
		For Each DataLine In Object.DataList Do
			If DataLine.LoadFlag <> True Then
				Continue;
			EndIf;	
			
			CurNumber = DataLine[ColumnNames["Number"]];
			CurDate = DataLine[ColumnNames["Date"]];
			CurPost = DataLine[ColumnNames["ToPost"]];
			CurVendor = DataLine[ColumnNames["Company"]];
			
			LastLineNumber = DataLine.LineNumber;
			
			Try
				MarkOfNewDoc = False;
				For Each StructItem in PrevSearchBase Do
					If StructItem.Value <> DataLine[StructItem.Key] Then 
						MarkOfNewDoc = True
					EndIf;	
				EndDo;	
				
				If MarkOfNewDoc Then 
					
					FillPropertyValues(PrevSearchBase,DataLine);
					
					If DocObject <> Undefined Then
						
						// Calculate document totals.
						DocObject.DocumentTotal   = DocObject.LineItems.Total("LineTotal") + DocObject.Accounts.Total("Amount");
						DocObject.DocumentTotalRC = Round(DocObject.DocumentTotal * DocObject.ExchangeRate, 2);
						DocObject.Write(?(DocPost,DocumentWriteMode.Posting,DocumentWriteMode.Write));
					EndIf;	
					
					// First row, need to fill up document, Lines will be filled later
					ExistingDoc = DataProcessors.DataImportV20.FindDocumentByAttributes("PurchaseInvoice",CurNumber,CurDate,CurVendor);
					If ValueIsFilled(ExistingDoc) Then 
						DocObject = ExistingDoc.GetObject();
						DocObject.LineItems.Clear();
						DocObject.Accounts.Clear();
					Else
						DocObject = Documents.PurchaseInvoice.CreateDocument();
						DocObject.Number = CurNumber;
					EndIf;
					// Filling document attributes
					DocObject.Date = Date(CurDate);
					DocObject.Company = CurVendor;
					DocObject.Currency = Constants.DefaultCurrency.Get();
					DocObject.ExchangeRate = GeneralFunctions.GetExchangeRate(DocObject.Date, DocObject.Currency);
					DocObject.APAccount = DocObject.Company.APAccount;
					DocObject.DueDate = CurDate;
					DocObject.LocationActual = GeneralFunctions.GetDefaultLocation();
					DocObject.Terms = Catalogs.PaymentTerms.DueOnReceipt;
					
					Query = New Query;
					Query.Text = 
					"SELECT
					|	Addresses.Ref
					|FROM
					|	Catalog.Addresses AS Addresses
					|WHERE
					|	Addresses.DefaultBilling = &DefaultBilling
					|	AND Addresses.Owner = &Owner";
					
					Query.SetParameter("DefaultBilling", True);
					Query.SetParameter("Owner", DocObject.Company);
					
					QueryResult = Query.Execute();
					SelectionDetailRecords = QueryResult.Select();
					If SelectionDetailRecords.Next() Then
						DocObject.CompanyAddress = SelectionDetailRecords.Ref;
					EndIf;	
					
					DocPost = (CurPost = True);
				EndIf;
				
				DocLineExpenses = DocObject.Accounts.Add();
				
				
				DocLineExpenses.Account = DataLine.ExpensifyAccount;
				DocLineExpenses.Amount = DataLine.ExpensifyAmount;
				DocLineExpenses.Memo = DataLine.ExpensifyMemo;
				
				CountOfLoadedItems = CountOfLoadedItems + 1;
				
			Except
				GlobalErrorMessage = "ERROR" + Chars.LF + "Document Line: "+LastLineNumber+ Chars.LF+ ErrorDescription();
				Cancel = True;
				Return;
			EndTry;
			
		EndDo;
		
		Try
			If DocObject <> Undefined Then
				DocObject.DocumentTotal   = DocObject.LineItems.Total("LineTotal") + DocObject.Accounts.Total("Amount");
				DocObject.DocumentTotalRC = Round(DocObject.DocumentTotal * DocObject.ExchangeRate, 2);
				DocObject.Write(?(DocPost,DocumentWriteMode.Posting,DocumentWriteMode.Write));
			EndIf;	
		Except
			GlobalErrorMessage = "ERROR" + Chars.LF + "Document Line: "+LastLineNumber+ Chars.LF+ ErrorDescription();
			Cancel = True;
			Return;
		EndTry;
		
	EndIf;
	
	If ActionType = "Items" Then
		
		ItemDataSet = New Array();
		For Each DataLine In Object.DataList Do
			
			If DataLine.LoadFlag Then
				ItemLine = New Structure("LineNumber, ProductType, ProductCode, ProductParent, ProductDescription, PurchaseDescription, ProductIncomeAcct, ProductInvOrExpenseAcct, ProductCOGSAcct, ProductCategory, ProductUoM, ProductVendorCode, ProductPreferedVendor, ProductPrice, ProductCost, ProductQty, ProductValue, ProductTaxable, ProductCF1String, ProductCF1Num, ProductCF2String, ProductCF2Num, ProductCF3String, ProductCF3Num, ProductCF4String, ProductCF4Num, ProductCF5String, ProductCF5Num, ProductUpdate");
				FillPropertyValues(ItemLine, DataLine);
				
				For Each Attr in CustomFieldMap Do 
					ItemLine.Insert(Attr.ColumnName, DataLine["CustomField"+Attr.Order]);
				EndDo;
				
				ItemDataSet.Add(ItemLine);
			EndIf;
			
		EndDo;	
		
		Params = New Array();
		Params.Add(Date);
		Params.Add(Date2);
		Params.Add(ItemDataSet);
		Params.Add(UpdateOption);
		
		RunProcedureInBackgroundAsLongAction("DataProcessors.DataImportV20.CreateItemCSV", Params);
		
	EndIf;
	
	If ActionType = "PurchaseOrders" Then
		
		ItemDataSet = New Array();
		For Each DataLine In Object.DataList Do
			If DataLine.LoadFlag Then
				ItemLine = New Structure;
				For Each Attr in CustomFieldMap Do 
					//Attr.ColumnName;
					ItemLine.Insert(Attr.ColumnName, DataLine["CustomField"+Attr.Order]);
				EndDo;
				ItemLine.Insert("LineNumber",DataLine.LineNumber);
				ItemDataSet.Add(ItemLine);
			EndIf;
			//ItemDataSet.Add(ItemLine);
		EndDo;	
		
		Params = New Array();
		Params.Add(Date);
		Params.Add(Date2);
		Params.Add(ItemDataSet);
		
		RunProcedureInBackgroundAsLongAction("DataProcessors.DataImportV20.CreatePurchaseOrderCSV", Params);
		//DataProcessors.DataImportV20.CreatePurchaseOrderCSV(Date,Date2,ItemDataSet);
		
	EndIf;
	
	If ActionType = "Bills" Then
		
		ItemDataSet = New Array();
		For Each DataLine In Object.DataList Do
			If DataLine.LoadFlag Then
				ItemLine = New Structure;
				For Each Attr in CustomFieldMap Do 
					ItemLine.Insert(Attr.ColumnName, DataLine["CustomField"+Attr.Order]);
				EndDo;
				ItemLine.Insert("LineNumber",DataLine.LineNumber);
				ItemDataSet.Add(ItemLine);
			EndIf;
		EndDo;	
		
		Params = New Array();
		Params.Add(Date);
		Params.Add(Date2);
		Params.Add(ItemDataSet);
		
		RunProcedureInBackgroundAsLongAction("DataProcessors.DataImportV20.CreatePurchaseInvoiceCSV", Params);
		
	EndIf;
	
	If ActionType = "ItemReceipts" Then
		
		ItemDataSet = New Array();
		For Each DataLine In Object.DataList Do
			If DataLine.LoadFlag Then
				ItemLine = New Structure;
				For Each Attr in CustomFieldMap Do 
					ItemLine.Insert(Attr.ColumnName, DataLine["CustomField"+Attr.Order]);
				EndDo;
				ItemLine.Insert("LineNumber",DataLine.LineNumber);
				ItemDataSet.Add(ItemLine);
			EndIf;
		EndDo;	
		
		Params = New Array();
		Params.Add(Date);
		Params.Add(Date2);
		Params.Add(ItemDataSet);
		
		RunProcedureInBackgroundAsLongAction("DataProcessors.DataImportV20.CreateItemReceiptCSV", Params);
		
	EndIf;
	
	
	If ActionType = "BillPayments" Then
		
		ItemDataSet = New Array();
		For Each DataLine In Object.DataList Do
			If DataLine.LoadFlag Then
				ItemLine = New Structure;
				For Each Attr in CustomFieldMap Do 
					ItemLine.Insert(Attr.ColumnName, DataLine["CustomField"+Attr.Order]);
				EndDo;
				ItemLine.Insert("LineNumber",DataLine.LineNumber);
				ItemDataSet.Add(ItemLine);
			EndIf;
		EndDo;	
		
		Params = New Array();
		Params.Add(Date);
		Params.Add(Date2);
		Params.Add(ItemDataSet);
		
		RunProcedureInBackgroundAsLongAction("DataProcessors.DataImportV20.CreateBillPaymentCSV", Params);
		
	EndIf;
	
	
	If ActionType = "SalesInvoice" Then
		
		ItemDataSet = New Array();
		For Each DataLine In Object.DataList Do
			If DataLine.LoadFlag Then
				ItemLine = New Structure;
				For Each Attr in CustomFieldMap Do 
					ItemLine.Insert(Attr.ColumnName, DataLine["CustomField"+Attr.Order]);
				EndDo;
				ItemLine.Insert("LineNumber",DataLine.LineNumber);
				ItemDataSet.Add(ItemLine);
			EndIf;
		EndDo;	
		
		Params = New Array();
		Params.Add(Date);
		Params.Add(Date2);
		Params.Add(ItemDataSet);
		
		RunProcedureInBackgroundAsLongAction("DataProcessors.DataImportV20.CreateSalesInvoiceCSV", Params);
		//DataProcessors.DataImportV20.CreateSalesInvoiceCSV(Date,Date2,ItemDataSet);
		
	EndIf;
	
	If ActionType = "SalesOrder" Then
		
		ItemDataSet = New Array();
		For Each DataLine In Object.DataList Do
			If DataLine.LoadFlag Then
				ItemLine = New Structure;
				For Each Attr in CustomFieldMap Do 
					ItemLine.Insert(Attr.ColumnName, DataLine["CustomField"+Attr.Order]);
				EndDo;
				ItemLine.Insert("LineNumber",DataLine.LineNumber);
				ItemDataSet.Add(ItemLine);
			EndIf;
		EndDo;	
		
		Params = New Array();
		Params.Add(Date);
		Params.Add(Date2);
		Params.Add(ItemDataSet);
		
		RunProcedureInBackgroundAsLongAction("DataProcessors.DataImportV20.CreateSalesOrderCSV", Params);
		//DataProcessors.DataImportV20.CreateSalesOrderCSV(Date,Date2,ItemDataSet);
		
	EndIf;
	
	If ActionType = "BankTransfer" Then
		
		ItemDataSet = New Array();
		For Each DataLine In Object.DataList Do
			If DataLine.LoadFlag Then
				ItemLine = New Structure;
				For Each Attr in CustomFieldMap Do 
					ItemLine.Insert(Attr.ColumnName, DataLine["CustomField"+Attr.Order]);
				EndDo;
				ItemLine.Insert("LineNumber",DataLine.LineNumber);
				ItemDataSet.Add(ItemLine);
			EndIf;
		EndDo;	
		
		Params = New Array();
		Params.Add(ItemDataSet);
		
		RunProcedureInBackgroundAsLongAction("DataProcessors.DataImportV20.CreateBankTransferCSV", Params);
		//DataProcessors.DataImportV20.CreateBankTransferCSV(ItemDataSet);
		
	EndIf;
	
	
	If ActionType = "Projects" Then
		
		ItemDataSet = New Array();
		For Each DataLine In Object.DataList Do
			If DataLine.LoadFlag Then
				ItemLine = New Structure;
				For Each Attr in CustomFieldMap Do 
					ItemLine.Insert(Attr.ColumnName, DataLine["CustomField"+Attr.Order]);
				EndDo;
				ItemLine.Insert("LineNumber",DataLine.LineNumber);
				ItemDataSet.Add(ItemLine);
			EndIf;
		EndDo;	
		
		Params = New Array();
		Params.Add(ItemDataSet);
		Params.Add(UpdateOption);
		RunProcedureInBackgroundAsLongAction("DataProcessors.DataImportV20.CreateProjectsCSV", Params);
		//DataProcessors.DataImportV20.CreateProjectsCSV(ItemDataSet, UpdateOption);
	EndIf;
	
	
	If ActionType = "CashReceipt" Then
		
		ItemDataSet = New Array();
		For Each DataLine In Object.DataList Do
			If DataLine.LoadFlag Then
				ItemLine = New Structure;
				For Each Attr in CustomFieldMap Do 
					ItemLine.Insert(Attr.ColumnName, DataLine["CustomField"+Attr.Order]);
				EndDo;
				ItemLine.Insert("LineNumber",DataLine.LineNumber);
				ItemDataSet.Add(ItemLine);
			EndIf;
		EndDo;	
		
		Params = New Array();
		Params.Add(Date);
		Params.Add(Date2);
		Params.Add(ItemDataSet);
		
		RunProcedureInBackgroundAsLongAction("DataProcessors.DataImportV20.CreateCashReceipCSV", Params);
		//DataProcessors.DataImportV20.CreateCashReceipCSV(Date,Date2,ItemDataSet);
		
	EndIf;
	
	
	If ActionType = "CreditMemo" Then
		
		ItemDataSet = New Array();
		For Each DataLine In Object.DataList Do
			If DataLine.LoadFlag Then
				ItemLine = New Structure;
				For Each Attr in CustomFieldMap Do 
					ItemLine.Insert(Attr.ColumnName, DataLine["CustomField"+Attr.Order]);
				EndDo;
				ItemLine.Insert("LineNumber",DataLine.LineNumber);
				ItemDataSet.Add(ItemLine);
			EndIf;
		EndDo;	
		
		Params = New Array();
		Params.Add(Date);
		Params.Add(Date2);
		Params.Add(ItemDataSet);
		
		RunProcedureInBackgroundAsLongAction("DataProcessors.DataImportV20.CreateCreditMemoCSV", Params);
		//DataProcessors.DataImportV20.CreateCreditMemoCSV(Date,Date2,ItemDataSet);
		
	EndIf;

	If ActionType = "CustomersVendors" Then
		
		ItemDataSet = New Array();
		For Each DataLine In Object.DataList Do
			If DataLine.LoadFlag = True Then
				ItemLine = New Structure("LineNumber, CustomerType, CustomerCode, CustomerDescription, CustomerFullName, CustomerVendor1099, " +
				"CustomerEIN_SSN, CustomerIncomeAccount, CustomerExpenseAccount, CustomerNotes, " +
				"CustomerTerms, CustomerAddressID, CustomerFirstName, CustomerMiddleName, CustomerLastName, " +
				"CustomerPhone, CustomerCell, CustomerFax, CustomerEmail, CustomerAddressLine1, CustomerAddressLine2, " +
				"CustomerAddressLine3, CustomerCity, CustomerState, CustomerCountry, CustomerZIP, CustomerAddressNotes, " +
				"CustomerShippingAddressLine1, CustomerShippingAddressLine2, CustomerShippingAddressLine3, " +
				"CustomerShippingCity, CustomerShippingState, CustomerShippingCountry, CustomerShippingZIP, " +
				"CustomerVendorTaxID, CustomerCF1String, CustomerCF1Num, " +
				"CustomerCF2String, CustomerCF2Num, CustomerCF3String, CustomerCF3Num, CustomerCF4String, " +
				"CustomerCF4Num, CustomerCF5String, CustomerCF5Num, AddressSalutation, AddressSuffix, " +
				"AddressCF1String, AddressCF2String, AddressCF3String, AddressCF4String, AddressCF5String, " +
				"AddressJobTitle, AddressSalesPerson, CustomerSalesPerson, CustomerWebsite, CustomerPriceLevel, " +
				"DefaultBillingAddress, DefaultShippingAddress, CustomerEmployee");
				FillPropertyValues(ItemLine, DataLine);
				
				For Each Attr in CustomFieldMap Do 
					ItemLine.Insert(Attr.ColumnName, DataLine["CustomField"+Attr.Order]);
				EndDo;
				ItemDataSet.Add(ItemLine);
				
			Else
			EndIf;
		EndDo;
				
		Params = New Array();
		Params.Add(ItemDataSet);
		Params.Add(UpdateOption);
		
		RunProcedureInBackgroundAsLongAction("DataProcessors.DataImportV20.CreateCustomerVendorCSV", Params);
		//DataProcessors.DataImportV20.CreateCustomerVendorCSV(ItemDataSet, UpdateOption);
		
	EndIf;
	
	If ActionType = "Checks" Then
		
		ItemDataSet = New Array();
		For Each DataLine In Object.DataList Do
			If DataLine.LoadFlag = True Then
				ItemLine = New Structure("CheckDate, CheckNumber, CheckBankAccount, CheckMemo, CheckVendor, " + 
				"CheckLineAccount, CheckLineAmount, CheckLineMemo, CheckLineClass");
				FillPropertyValues(ItemLine, DataLine);
				
				For Each Attr in CustomFieldMap Do 
					ItemLine.Insert(Attr.ColumnName, DataLine["CustomField"+Attr.Order]);
				EndDo;
				ItemLine.Insert("LineNumber",DataLine.LineNumber);
				ItemDataSet.Add(ItemLine);
			Else
			EndIf;
		EndDo;

		Params = New Array();
		Params.Add(ItemDataSet);
		
		RunProcedureInBackgroundAsLongAction("DataProcessors.DataImportV20.CreateCheckCSV", Params);
		//CreateCheckCSV(ItemDataSet);
		
	EndIf;

	If ActionType = "Deposits" Then
		
		ItemDataSet = New Array();
		For Each DataLine In Object.DataList Do
			If DataLine.LoadFlag = True Then
				ItemLine = New Structure("DepositDate, DepositBankAccount, DepositMemo, " + 
				"DepositLineCompany, DepositLineAccount, DepositLineAmount, DepositLineClass, DepositLineMemo");
				FillPropertyValues(ItemLine, DataLine);
				
				For Each Attr in CustomFieldMap Do 
					ItemLine.Insert(Attr.ColumnName, DataLine["CustomField"+Attr.Order]);
				EndDo;
				ItemLine.Insert("LineNumber",DataLine.LineNumber);
				ItemDataSet.Add(ItemLine);
			Else
			EndIf;
		EndDo;

		Params = New Array();
		Params.Add(ItemDataSet);
		RunProcedureInBackgroundAsLongAction("DataProcessors.DataImportV20.CreateDepositCSV", Params);
		
		
	EndIf;

	GJFirstRow = True;
	For Each DataLine In Object.DataList Do
		
		If Not DataLine.LoadFlag Then
			Continue;
		EndIf;
		
		If ActionType = "Chart of accounts" Then
			
			If DataLine.CofAUpdate = ChartsOfAccounts.ChartOfAccounts.EmptyRef() Then
				
				NewAccount = ChartsOfAccounts.ChartOfAccounts.CreateAccount();
				NewAccount.Code = DataLine.CofACode;
				If DataLine.CofASubaccountOf <> ChartsOfAccounts.ChartOfAccounts.EmptyRef() Then
					NewAccount.Parent = DataLine.CofASubaccountOf;
				EndIf;
				NewAccount.Order = DataLine.CofACode;
				NewAccount.Description = DataLine.CofADescription;
				If DataLine.CofAType = GeneralFunctionsReusable.BankAccountType() OR
					DataLine.CofAType = GeneralFunctionsReusable.ARAccountType() OR
					DataLine.CofAType = GeneralFunctionsReusable.APAccountType() Then
						NewAccount.Currency = GeneralFunctionsReusable.DefaultCurrency();
				EndIf;
				
				NewAccount.AccountType = DataLine.CofAType;
				NewAccount.CashFlowSection = DataLine.CoACashFlowSection;
				NewAccount.Memo = DataLine.CofAMemo;
				NewAccount.Order = NewAccount.Code;
				NewAccount.Write();	
				
				Account = NewAccount.Ref;
				AccountObject = Account.GetObject();
				
				Dimension = AccountObject.ExtDimensionTypes.Find(ChartsOfCharacteristicTypes.Dimensions.Company, "ExtDimensionType");
				If Dimension = Undefined Then	
					NewType = AccountObject.ExtDimensionTypes.Insert(0);
					NewType.ExtDimensionType = ChartsOfCharacteristicTypes.Dimensions.Company;
				EndIf;	
				
				Dimension = AccountObject.ExtDimensionTypes.Find(ChartsOfCharacteristicTypes.Dimensions.Document, "ExtDimensionType");
				If Dimension = Undefined Then
					NewType = AccountObject.ExtDimensionTypes.Insert(1);
					NewType.ExtDimensionType = ChartsOfCharacteristicTypes.Dimensions.Document;
				EndIf;	
					
				AccountObject.Write();
				CountOfLoadedItems = CountOfLoadedItems + 1;
			Else
				
				UpdatedAccount = DataLine.CofAUpdate;
				UAO = UpdatedAccount.GetObject();
				If UpdateOption = "AllFields" Then 
					UAO.Code = DataLine.CofACode;
					UAO.Order = DataLine.CofACode;
					UAO.Description = DataLine.CofADescription;
					UAO.CashFlowSection = DataLine.CoACashFlowSection;
					UAO.Memo = DataLine.CofAMemo;
					UAO.AccountType = DataLine.CofAType;
					If UAO.AccountType = GeneralFunctionsReusable.BankAccountType() OR
						UAO.AccountType = GeneralFunctionsReusable.ARAccountType() OR
						UAO.AccountType = GeneralFunctionsReusable.APAccountType() Then
						UAO.Currency = GeneralFunctionsReusable.DefaultCurrency();
					EndIf;
					UAO.Parent = DataLine.CofASubaccountOf;
				ElsIf UpdateOption = "OnlyFilled" Then	
					If ValueIsFilled(DataLine.CofACode) Then 
						UAO.Code = DataLine.CofACode;
						UAO.Order = DataLine.CofACode;
					EndIf;	
					If ValueIsFilled(DataLine.CofADescription) Then 
						UAO.Description = DataLine.CofADescription;
					EndIf;	
					If ValueIsFilled(DataLine.CoACashFlowSection) Then 
						UAO.CashFlowSection = DataLine.CoACashFlowSection;
					EndIf;	
					If ValueIsFilled(DataLine.CofAMemo) Then 
						UAO.Memo = DataLine.CofAMemo;
					EndIf;	
					If ValueIsFilled(DataLine.CofAType) Then 
						UAO.AccountType = DataLine.CofAType;
						If UAO.AccountType = GeneralFunctionsReusable.BankAccountType() OR
							UAO.AccountType = GeneralFunctionsReusable.ARAccountType() OR
							UAO.AccountType = GeneralFunctionsReusable.APAccountType() Then
							UAO.Currency = GeneralFunctionsReusable.DefaultCurrency();
						EndIf;
					EndIf;
					If ValueIsFilled(DataLine.CofASubaccountOf) Then 
						UAO.Parent = DataLine.CofASubaccountOf;
					EndIf;	
				EndIf;	
				
				If Not UAO.Parent.IsEmpty() And UAO.Parent.AccountType <> UAO.AccountType Then 
					Message("The account type must be the same as the parent account. Account "+UAO+" will be written in root folder.",MessageStatus.Attention);
					UAO.Parent = ChartsOfAccounts.ChartOfAccounts.EmptyRef();
				EndIf;	
				
				UAO.DataExchange.Load = True;
				UAO.Write();
				CountOfLoadedItems = CountOfLoadedItems + 1;
			EndIf;
			
			
		ElsIf ActionType = "Classes" Then
			
			ExistingClass = Catalogs.Classes.FindByDescription(DataLine.ClassName,True);
			If ExistingClass.IsEmpty() Then 
				NewClass = Catalogs.Classes.CreateItem();
				NewClass.Description = DataLine.ClassName;
			Else 
				NewClass = ExistingClass.GetObject();
			EndIf;	
			If DataLine.SubClassOf <> Catalogs.Classes.EmptyRef() Then
				NewClass.Parent = DataLine.SubClassOf;
			EndIf;
			NewClass.Write();
			CountOfLoadedItems = CountOfLoadedItems + 1;
			
		ElsIf ActionType = "PaymentTerms" Then
			
			ExistingPTerm = Catalogs.PaymentTerms.FindByDescription(DataLine.PTermsName,True);
			If ExistingPTerm.IsEmpty() Then 
				NewPTerm = Catalogs.PaymentTerms.CreateItem();
				NewPTerm.Description = DataLine.PTermsName;
			Else 
				NewPTerm = ExistingPTerm.GetObject();
			EndIf;	
			//If DataLine.SubClassOf <> Catalogs.Classes.EmptyRef() Then
			//	NewClass.Parent = DataLine.SubClassOf;
			//EndIf;
			NewPTerm.Days = DataLine.PTermsDays;
			NewPTerm.DiscountDays = DataLine.PTermsDiscountDays;
			NewPTerm.DiscountPercent = DataLine.PTermsDiscountPercent;
			NewPTerm.Write();	
			CountOfLoadedItems = CountOfLoadedItems + 1;
			
		ElsIf ActionType = "PriceLevels" Then
			
			ColumnNames = New Structure;
			For Each Attr in CustomFieldMap Do 
				ColumnNames.Insert(Attr.ColumnName,"CustomField"+Attr.Order);
			EndDo;	
				
			ExistingPLevels = Catalogs.PriceLevels.FindByDescription(DataLine[ColumnNames["Name"]],True);
			If ExistingPLevels.IsEmpty() Then 
				NewPLevel = Catalogs.PriceLevels.CreateItem();
				NewPLevel.Description = DataLine[ColumnNames["Name"]];
			Else 
				NewPLevel = ExistingPLevels.GetObject();
			EndIf;	
			
			//NewPLevel.Type = DataLine[ColumnNames["Type"]];
			//NewPLevel.Percentage = DataLine[ColumnNames["Percentage"]];
			NewPLevel.Write();	
			CountOfLoadedItems = CountOfLoadedItems + 1;
			
		ElsIf ActionType = "SalesRep" Then
			
			ColumnNames = New Structure;
			For Each Attr in CustomFieldMap Do 
				ColumnNames.Insert(Attr.ColumnName,"CustomField"+Attr.Order);
			EndDo;	
				
			ExistingSalesRep = Catalogs.SalesPeople.FindByDescription(DataLine[ColumnNames["Name"]],True);
			If ExistingSalesRep.IsEmpty() Then 
				NewSalesPeople = Catalogs.SalesPeople.CreateItem();
				NewSalesPeople.Description = DataLine[ColumnNames["Name"]];
			Else 
				NewSalesPeople = ExistingSalesRep.GetObject();
			EndIf;	
			
			NewSalesPeople.Write();	
	 	    CountOfLoadedItems = CountOfLoadedItems + 1;
							
		ElsIf ActionType = "Journal entries" Then
			
			If DataLine.GJHeaderRowNumber = 1 AND GJFirstRow = True Then
				
				GJFirstRow = False;
				
				NewGJ = Documents.GeneralJournalEntry.CreateDocument();
				NewGJ.Date = DataLine.GJHeaderDate;
				NewGJ.Memo = DataLine.GJHeaderMemo;
				
				NewGJLine = NewGJ.LineItems.Add();
				NewGJLine.Account = DataLine.GJHeaderAccount;
				NewGJLine.Memo = DataLine.GJHeaderLineMemo;
				NewGJLine.Class = DataLine.GJHeaderClass;
				If DataLine.GJHeaderType = "Debit" Then
					NewGJLine.AmountDr = DataLine.GJHeaderAmount;
				Else
					NewGJLine.AmountCr = DataLine.GJHeaderAmount;
				EndIf;
				
			ElsIf DataLine.GJHeaderRowNumber = 1 AND GJFirstRow = False Then
				
				DocTotal = NewGJ.LineItems.Total("AmountDr");
				NewGJ.DocumentTotalRC = DocTotal;
				NewGJ.DocumentTotal = DocTotal;
				NewGJ.Currency = GeneralFunctionsReusable.DefaultCurrency();
				NewGJ.ExchangeRate = 1;
				NewGJ.Write();
				
				NewGJ = Documents.GeneralJournalEntry.CreateDocument();
				NewGJ.Date = DataLine.GJHeaderDate;
				NewGJ.Memo = DataLine.GJHeaderMemo;
				
				NewGJLine = NewGJ.LineItems.Add();
				NewGJLine.Account = DataLine.GJHeaderAccount;
				NewGJLine.Memo = DataLine.GJHeaderLineMemo;
				NewGJLine.Class = DataLine.GJHeaderClass;
				If DataLine.GJHeaderType = "Debit" Then
					NewGJLine.AmountDr = DataLine.GJHeaderAmount;
				Else
					NewGJLine.AmountCr = DataLine.GJHeaderAmount;
				EndIf;

				
			ElsIf DataLine.GJHeaderRowNumber <> 1 Then
				
				NewGJLine = NewGJ.LineItems.Add();
				NewGJLine.Account = DataLine.GJHeaderAccount;
				NewGJLine.Memo = DataLine.GJHeaderLineMemo;
				NewGJLine.Class = DataLine.GJHeaderClass;
				If DataLine.GJHeaderType = "Debit" Then
					NewGJLine.AmountDr = DataLine.GJHeaderAmount;
				Else
					NewGJLine.AmountCr = DataLine.GJHeaderAmount;
				EndIf;

			EndIf;	
			
			CountOfLoadedItems = CountOfLoadedItems + 1;
						
		EndIf;
	
	EndDo;
	
	If GJFirstRow = False Then
		
		DocTotal = NewGJ.LineItems.Total("AmountDr");
		NewGJ.DocumentTotalRC = DocTotal;
		NewGJ.DocumentTotal = DocTotal;
		NewGJ.Currency = GeneralFunctionsReusable.DefaultCurrency();
		NewGJ.ExchangeRate = 1;
		NewGJ.Write();

	EndIf;

EndProcedure

&AtClient
Procedure ActionTypeOnChange(Item)
	
	FillAttributes();
	
	ThisForm.Title = "Import from a CSV file ("+ActionType+")";
	
EndProcedure

&AtClient
Procedure MappingBack(Command)
	
	Items.LoadSteps.CurrentPage = Items.LoadSteps.ChildItems.Greeting;
		
EndProcedure

&AtClient
Procedure MappingNext(Command)
	
	ErrorCount = 0;
	For AttributeCounter = 0 To Attributes.Count() - 1 Do
		If Attributes[AttributeCounter].Required And Attributes[AttributeCounter].ColumnNumber = 0 And TrimAll(Attributes[AttributeCounter].Value) = "" Then
			UserMessage = New UserMessage;
			UserMessage.Text = "Please fill out the columns for required attributes";
			UserMessage.Field = "Attributes["+AttributeCounter+"].ColumnNumber";
			UserMessage.Message(); 
			ErrorCount = ErrorCount + 1;
			//Return;
		EndIf; 
	EndDo;
	If ErrorCount > 0 Then 
		Return;
	EndIf;	
	
	FillLoadTable();
	Items.LoadSteps.CurrentPage = Items.LoadSteps.ChildItems.Creation;
		
EndProcedure

&AtClient
Procedure SelectAll(Command)
	
	For Each CutItem In Object.DataList Do
		CutItem.LoadFlag = True;
	EndDo; 
	
EndProcedure

&AtClient
Procedure UnselectAll(Command)
	
	For Each CutItem In Object.DataList Do
		CutItem.LoadFlag = False;
	EndDo;
	
EndProcedure

&AtClient
Procedure CreateBack(Command)
	
	Items.LoadSteps.CurrentPage = Items.LoadSteps.ChildItems.Mapping;
	
EndProcedure

&AtClient
Procedure CreateNext(Command)
	
	ClearMessages();
	
	CountRowsToUpload = 0;
	CountSkipped = 0;
	For Each DataLine In Object.DataList Do
		If DataLine.LoadFlag = True Then
			CountRowsToUpload = CountRowsToUpload + 1;
		Else 
			CountSkipped = CountSkipped + 1;
		EndIf;	
	EndDo;	
	
	If 	ActionType = "Items" 
		Or ActionType = "CustomersVendors" 
		Or ActionType = "PurchaseOrders" 
		Or ActionType = "Bills" 
		Or ActionType = "ItemReceipts" 
		Or ActionType = "BillPayments" 
		Or ActionType = "SalesInvoice" 
		Or ActionType = "SalesOrder" 
		Or ActionType = "CashReceipt" 
		Or ActionType = "CreditMemo" 
		Or ActionType = "Deposits" 
		Or ActionType = "Projects" 
		Or ActionType = "BankTransfer" 	
		Or ActionType = "Checks" 
		Then
		LongActionSettings = New Structure("Finished, ResultAddres, UID, Error, DetailedErrorDescription");
		LongActionSettings.Insert("IdleTime", 5);
		
		LoadingStatusText = NStr("en = 'Transfering data to server ...'");
		ResultStructure = New Structure;
		VisibilitySetup("FinishRunning",ResultStructure);
		
		AttachIdleHandler("LoadDataInBackroundWithCLientReportInitiation", 0.1, True);
	Else 
		Cancel = False;
		LoadData(Cancel);
		If Not Cancel Then
			ResultStructure = New Structure;
			ResultStructure.Insert("Success",CountOfLoadedItems);
			ResultStructure.Insert("Skiped",CountSkipped);
			ResultStructure.Insert("ToUpload",CountRowsToUpload);
			VisibilitySetup("FinishSuccess",ResultStructure);
		Else 	
			ResultStructure = New Structure;
			ResultStructure.Insert("Success",CountOfLoadedItems);
			ResultStructure.Insert("Skiped",CountSkipped);
			ResultStructure.Insert("ToUpload",CountRowsToUpload);
			ResultStructure.Insert("ErrorMessage",GlobalErrorMessage);
			VisibilitySetup("FinishFailure",ResultStructure);
			GlobalErrorMessage = "";
		EndIf;
	EndIf;	
	
	Return;
	
EndProcedure

&AtClient
// Auxiliary procedure without parameters, to initiate loading process through Handler
Procedure LoadDataInBackroundWithCLientReportInitiation()
	LoadDataInBackroundWithCLientReport();
EndProcedure	

&AtClient
// Main procedure to run loading process, show final screen and initiate Listening handler
// Parameters - progress, if less than 100, then run listening handler again, to run upload in some different parts from client.
// Can be used to show additional progress
Procedure LoadDataInBackroundWithCLientReport(ProgressPosition = 1)
	
		
	LoadingStatusText = NStr("en = 'Processing Data on server ...'");
	
	If (ProgressPosition-1) < CountRowsToUpload Then 
		
		If CountRowsToUpload <> 0 Then 
			LoadingIndicator = (ProgressPosition/CountRowsToUpload)*100 ;		
		EndIf;	
		
		ResultStructure = New Structure;
		ResultStructure.Insert("Success",ProgressPosition);
		ResultStructure.Insert("Skiped",CountSkipped);
		ResultStructure.Insert("ToUpload",CountRowsToUpload);
		VisibilitySetup("FinishRunning",ResultStructure);
		
		Notify("DataImportFinished",, ThisObject);
		RefreshReusableValues(); 
		
		LoadData(False);
		AttachIdleHandler("Attachable_ListeningLongAction", 0.1, True);
	Else 
		ResultStructure = New Structure;
		ResultStructure.Insert("Success",ProgressPosition-1);
		ResultStructure.Insert("Skiped",CountSkipped);
		ResultStructure.Insert("ToUpload",CountRowsToUpload);
		VisibilitySetup("FinishSuccess",ResultStructure);
		
		Notify("DataImportFinished",, ThisObject);
		RefreshReusableValues(); 
	EndIf;;
		
EndProcedure	

&AtServer
Procedure RunProcedureInBackgroundAsLongAction(ProcedureName,Params) 
	Try 
		Result = LongActions.ExecuteActionInBackground(ThisForm.UUID, ProcedureName, Params);
	Except
		ErrorText = NStr("en = 'Data Import Failed.'");
		ErrorText = ErrorText + Chars.LF + BriefErrorDescription(ErrorInfo());
		LongActionSettings.Error = ErrorText;
		Return;
	EndTry;	
	LoadingStatusText = NStr("en = 'Processing Data on server ...'");
	
	LongActionSettings.UID   		= Result.JobID;
	LongActionSettings.Finished		= Result.JobCompleted;
	LongActionSettings.ResultAddres	= Result.StorageAddress;
EndProcedure	

&AtClient
Procedure Attachable_ListeningLongAction()
	
	ActionStatus = GetLongActionStatus();
	If Not IsBlankString(ActionStatus.Error) Then 
		CommonUseClientServer.MessageToUser(ActionStatus.Error);
		
		ResultStructure = New Structure;
		ResultStructure.Insert("Success",ActionStatus.Progress.Progress);
		ResultStructure.Insert("Skiped",CountSkipped);
		ResultStructure.Insert("ToUpload",CountRowsToUpload);
		ResultStructure.Insert("ErrorMessage",ActionStatus.Error);
		VisibilitySetup("FinishFailure",ResultStructure);
		
		
		Notify("DataImportFinished",, ThisObject);
		Return;
	ElsIf ActionStatus.Finished = Undefined Then 
		
		ResultStructure = New Structure;
		ResultStructure.Insert("Success",0);
		ResultStructure.Insert("Skiped",CountSkipped);
		ResultStructure.Insert("ToUpload",CountRowsToUpload);
		ResultStructure.Insert("ErrorMessage",ActionStatus.Error);
		VisibilitySetup("FinishFailure",ResultStructure);
		
		Notify("DataImportFinished",, ThisObject);
		RefreshReusableValues(); 
		Return;
	ElsIf ActionStatus.Finished Then
		LoadDataInBackroundWithCLientReport(CountRowsToUpload + 1);
		Return;
	EndIf;
	
	If TypeOf(ActionStatus.Progress) = Type("Structure") Then 
		LoadingStatusText = ActionStatus.Progress.Text;
		If CountRowsToUpload <> 0 Then 
			LoadingIndicator = (ActionStatus.Progress.Progress/CountRowsToUpload)*100 ;		
		EndIf;
	EndIf;
	
	AttachIdleHandler("Attachable_ListeningLongAction", LongActionSettings.IdleTime, True);
	
EndProcedure

&AtServer
Procedure VisibilitySetup(ResultStatus, ResultStatusStructure = Undefined)
	
	CreatePage = (ResultStatus = "CreatePage");
	FinishRunning = (ResultStatus = "FinishRunning");
	FinishFailure = (ResultStatus = "FinishFailure");
	FinishSuccess = (ResultStatus = "FinishSuccess");
	FinishPage = FinishFailure or FinishRunning or FinishSuccess;
	
	Items.ActionFinished.Visible = FinishFailure Or FinishSuccess;	// Picture with "i" sign
	Items.ActionInProgress.Visible = FinishRunning;     			// Picture Animated "in progress"
	Items.FinishBack.Visible = FinishFailure Or FinishSuccess;  	// Button "Back" on "Finish" screen
	Items.StartNewImport.Visible = FinishFailure Or FinishSuccess;  // Button "StartNewImport" on "Finish" screen
	Items.Group6.Visible = FinishFailure Or FinishSuccess;   		// Message with "Import finished. You can see results here"
	Items.LoadingIndicator.Visible = FinishRunning;					// Progress indicator
	Items.LoadingStatusText.Visible = FinishRunning;            	// Progress message
	
	
	If FinishPage Then 
		Items.LoadSteps.CurrentPage = Items.LoadSteps.ChildItems.Finish;
	ElsIf CreatePage Then 
		Items.LoadSteps.CurrentPage = Items.LoadSteps.ChildItems.Creation;
	EndIf;	
	
	LoadingStatusText = ?(FinishRunning,LoadingStatusText,"");
	
	If FinishFailure Then 
		Items.Label1.title = "IMPORT FAILED !!!. You can check the results" + Chars.LF + Chars.LF +
		"Rows imported: " + ResultStatusStructure["Success"] + Chars.LF +
		"Rows skipped: " + ResultStatusStructure["Skiped"] + Chars.LF +
		"Rows failed: " + (ResultStatusStructure["ToUpload"] - ResultStatusStructure["Success"]) + Chars.LF + Chars.LF +
		ResultStatusStructure["ErrorMessage"];
	ElsIf FinishSuccess Then  
		Items.Label1.title = "Import finished. You can check the results" + Chars.LF + Chars.LF +
		"Rows imported: " + ResultStatusStructure["Success"] + Chars.LF +
		"Rows skipped: " + ResultStatusStructure["Skiped"] + Chars.LF +
		"Rows failed: " + (ResultStatusStructure["ToUpload"] - ResultStatusStructure["Success"]);
	Else 	
		Items.Label1.title = "Import finished. You can check the results";
	EndIf;
	
	
EndProcedure	

&AtServer
Function GetLongActionStatus()
	
	Result = New Structure("Progress, Finished, Error, DetailedErrorDescription");
	Result.Error = "";
	If LongActionSettings.UID = Undefined Then 
		Result.Finished = True;
		Result.Progress  = Undefined;
		Result.DetailedErrorDescription = LongActionSettings.DetailedErrorDescription;
		Result.Error                    = LongActionSettings.Error;
	Else
		Try
            Result.Finished = LongActions.JobCompleted(LongActionSettings.UID);
			Result.Progress  = LongActions.GetActionProgress(LongActionSettings.UID);
			If Left(Result.Progress.Text,5) = "ERROR" Then 
				Result.Error = Mid(Result.Progress.text,7); 
			EndIf;	
		Except
			Info = ErrorInfo(); 
			Result.DetailedErrorDescription = Info.Description;
			Result.Error                    = Info.Description;
		EndTry;
	EndIf;;
	Return Result;
EndFunction

&AtServer
Function GetValueByName(Name, TypeString)
	
	Mapping = New Map;
	
	If ActionType = "Chart of accounts" Then 
		If TypeString = "AccountType" Then
			Mapping.Insert("Accounts payable",Enums.AccountTypes.AccountsPayable);
			Mapping.Insert("Accounts receivable",Enums.AccountTypes.AccountsReceivable);
			Mapping.Insert("Accumulated depreciation",Enums.AccountTypes.AccumulatedDepreciation);
			Mapping.Insert("Bank",Enums.AccountTypes.Bank);
			Mapping.Insert("Cost of sales",Enums.AccountTypes.CostOfSales);
			Mapping.Insert("Equity",Enums.AccountTypes.Equity);
			Mapping.Insert("Expense",Enums.AccountTypes.Expense);
			Mapping.Insert("Fixed asset",Enums.AccountTypes.FixedAsset);
			Mapping.Insert("Sales",Enums.AccountTypes.Income);
			Mapping.Insert("Inventory",Enums.AccountTypes.Inventory);
			Mapping.Insert("Long term liability",Enums.AccountTypes.LongTermLiability);
			Mapping.Insert("Other current asset",Enums.AccountTypes.OtherCurrentAsset);
			Mapping.Insert("Other current liability",Enums.AccountTypes.OtherCurrentLiability);
			Mapping.Insert("Other expense",Enums.AccountTypes.OtherExpense);
			Mapping.Insert("Other income",Enums.AccountTypes.OtherIncome);
			Mapping.Insert("Other noncurrent asset",Enums.AccountTypes.OtherNonCurrentAsset);
			Mapping.Insert("AccountsPayable",Enums.AccountTypes.AccountsPayable);
			Mapping.Insert("AccountsReceivable",Enums.AccountTypes.AccountsReceivable);
			Mapping.Insert("CostOfGoodsSold",Enums.AccountTypes.CostOfSales);
			Mapping.Insert("FixedAsset",Enums.AccountTypes.FixedAsset);
			Mapping.Insert("Income",Enums.AccountTypes.Income);
			Mapping.Insert("NonPosting",Enums.AccountTypes.OtherExpense); //Misa
			Mapping.Insert("OtherCurrentAsset",Enums.AccountTypes.OtherCurrentAsset);
			Mapping.Insert("OtherCurrentLiability",Enums.AccountTypes.OtherCurrentLiability);
			Mapping.Insert("OtherExpense",Enums.AccountTypes.OtherExpense);
		ElsIf TypeString = "CFSection" Then
			Mapping.Insert("Financing",Enums.CashFlowSections.Financing);
			Mapping.Insert("Investing",Enums.CashFlowSections.Investing);
			Mapping.Insert("None",Enums.CashFlowSections.EmptyRef());
			Mapping.Insert("NotApplicable",Enums.CashFlowSections.EmptyRef());
			Mapping.Insert("Operating",Enums.CashFlowSections.Operating);
		EndIf;
	ElsIf ActionType = "Items" Then	
		If TypeString = "ItemType" Then
			Mapping.Insert("Service", Enums.InventoryTypes.NonInventory);
			Mapping.Insert("Product", Enums.InventoryTypes.Inventory);
			Mapping.Insert("ItemDiscount", Enums.InventoryTypes.NonInventory);
			Mapping.Insert("ItemGroup", Enums.InventoryTypes.NonInventory);
			Mapping.Insert("ItemInventory", Enums.InventoryTypes.Inventory);
			Mapping.Insert("ItemInventoryAssembly", Enums.InventoryTypes.Inventory);
			Mapping.Insert("ItemNonInventory", Enums.InventoryTypes.NonInventory);
			Mapping.Insert("ItemOtherCharge", Enums.InventoryTypes.NonInventory);
			Mapping.Insert("ItemSalesTax", Enums.InventoryTypes.NonInventory);
			Mapping.Insert("ItemService", Enums.InventoryTypes.NonInventory);
			Mapping.Insert("ItemSubtotal", Enums.InventoryTypes.NonInventory);
		ElsIf TypeString = "ItemTaxable" Then
			Mapping.Insert("",False);
			Mapping.Insert("Y",True);
			Mapping.Insert("N",False);
			Mapping.Insert("T",True);
			Mapping.Insert("F",False);
			Mapping.Insert("1",True);
			Mapping.Insert("0",False);
			Mapping.Insert("Tax",True);
			Mapping.Insert("Non",False);
		EndIf;
	ElsIf ActionType = "CustomersVendors" Then	
		If TypeString = "Boolean" Then
			Mapping.Insert("",False);
			Mapping.Insert("Y",True);
			Mapping.Insert("N",False);
			Mapping.Insert("T",True);
			Mapping.Insert("F",False);
			Mapping.Insert("1",True);
			Mapping.Insert("0",False);
			Mapping.Insert("Tax",True);
			Mapping.Insert("Non",False);
		EndIf;	
	ElsIf ActionType = "SalesInvoice" Then	
		If TypeString = "Boolean" Then
			Mapping.Insert("",False);
			Mapping.Insert("Y",True);
			Mapping.Insert("N",False);
			Mapping.Insert("T",True);
			Mapping.Insert("F",False);
			Mapping.Insert("1",True);
			Mapping.Insert("0",False);
			Mapping.Insert("Tax",True);
			Mapping.Insert("Non",False);
		EndIf;
	ElsIf ActionType = "CreditMemo" Then	
		If TypeString = "Boolean" Then
			Mapping.Insert("",False);
			Mapping.Insert("Y",True);
			Mapping.Insert("N",False);
			Mapping.Insert("T",True);
			Mapping.Insert("F",False);
			Mapping.Insert("1",True);
			Mapping.Insert("0",False);
			Mapping.Insert("Tax",True);
			Mapping.Insert("Non",False);
		EndIf;	
	ElsIf ActionType = "SalesOrder" Then	
		If TypeString = "Boolean" Then
			Mapping.Insert("",False);
			Mapping.Insert("Y",True);
			Mapping.Insert("N",False);
			Mapping.Insert("T",True);
			Mapping.Insert("F",False);
			Mapping.Insert("1",True);
			Mapping.Insert("0",False);
			Mapping.Insert("Tax",True);
			Mapping.Insert("Non",False);
		EndIf;
	ElsIf ActionType = "Bills" Then	
		If TypeString = "Boolean" Then
			Mapping.Insert("",False);
			Mapping.Insert("Y",True);
			Mapping.Insert("N",False);
			Mapping.Insert("T",True);
			Mapping.Insert("F",False);
			Mapping.Insert("1",True);
			Mapping.Insert("0",False);
		EndIf;		
	ElsIf ActionType = "ItemReceipts" Then	
		If TypeString = "Boolean" Then
			Mapping.Insert("",False);
			Mapping.Insert("Y",True);
			Mapping.Insert("N",False);
			Mapping.Insert("T",True);
			Mapping.Insert("F",False);
			Mapping.Insert("1",True);
			Mapping.Insert("0",False);
		EndIf;
	ElsIf ActionType = "CashReceipt" Then	
		If TypeString = "Boolean" Then
			Mapping.Insert("",False);
			Mapping.Insert("Y",True);
			Mapping.Insert("N",False);
			Mapping.Insert("T",True);
			Mapping.Insert("F",False);
			Mapping.Insert("1",True);
			Mapping.Insert("0",False);
		EndIf;	
	ElsIf ActionType = "BillPayments" Then
		If TypeString = "Boolean" Then
			Mapping.Insert("",False);
			Mapping.Insert("Y",True);
			Mapping.Insert("N",False);
			Mapping.Insert("T",True);
			Mapping.Insert("F",False);
			Mapping.Insert("1",True);
			Mapping.Insert("0",False);
		EndIf;		
	ElsIf ActionType = "Deposits" Then   
		If TypeString = "Boolean" Then
			Mapping.Insert("",False);
			Mapping.Insert("Y",True);
			Mapping.Insert("N",False);
			Mapping.Insert("T",True);
			Mapping.Insert("F",False);
			Mapping.Insert("1",True);
			Mapping.Insert("0",False);
		EndIf;			
	ElsIf ActionType = "Checks" Then    
		If TypeString = "Boolean" Then
			Mapping.Insert("",False);
			Mapping.Insert("Y",True);
			Mapping.Insert("N",False);
			Mapping.Insert("T",True);
			Mapping.Insert("F",False);
			Mapping.Insert("1",True);
			Mapping.Insert("0",False);
		EndIf;	
		
	Else 
		Return Enums.AccountTypes.EmptyRef();
	EndIf;
	
	
	Result = Mapping[Name];
	
	If Result = Undefined Then 
		Result = Enums.AccountTypes.EmptyRef();
	EndIf;	
	
	Return Result;
	
EndFunction
//-- MisA

&AtClient
Procedure RefClick(Item)
	
	If ActionType = "CustomersVendors" Then
		OpenForm("Catalog.Companies.ListForm");
		
	ElsIf ActionType = "Chart of accounts" Then		
		OpenForm("ChartOfAccounts.ChartOfAccounts.ListForm");
				
	ElsIf ActionType = "Items" Then
		OpenForm("Catalog.Products.ListForm");
				
	ElsIf ActionType = "Journal entries" Then
		OpenForm("Document.GeneralJournalEntry.ListForm");
				
	ElsIf ActionType = "Checks" Then
		OpenForm("Document.Check.ListForm");
		
	ElsIf ActionType = "Deposits" Then
		OpenForm("Document.Deposit.ListForm");
		
	ElsIf ActionType = "BankTransfer" Then
		OpenForm("Document.BankTransfer.ListForm");
				
	ElsIf ActionType = "Projects" Then
		OpenForm("Catalog.Projects.ListForm");
		
	ElsIf ActionType = "Classes" Then
		OpenForm("Catalog.Classes.ListForm");
		
	ElsIf ActionType = "PaymentTerms" Then
		OpenForm("Catalog.PaymentTerms.ListForm");
		
	ElsIf ActionType = "PriceLevels" Then
		OpenForm("Catalog.PriceLevels.ListForm");	
		
	ElsIf ActionType = "SalesRep" Then
		OpenForm("Catalog.SalesPeople.ListForm");	
		
	ElsIf ActionType = "Expensify" Then
		OpenForm("Document.PurchaseInvoice.ListForm");
		
	ElsIf ActionType = "PurchaseOrders" Then
		OpenForm("Document.PurchaseOrder.ListForm");	
		
	ElsIf ActionType = "ItemReceipts" Then
		OpenForm("Document.ItemReceipt.ListForm");	
		
	ElsIf ActionType = "Bills" Then
		OpenForm("Document.PurchaseInvoice.ListForm");	
		
	ElsIf ActionType = "SalesInvoice" Then
		OpenForm("Document.SalesInvoice.ListForm");	
		
	ElsIf ActionType = "BillPayment" Then
		OpenForm("Document.InvoicePayment.ListForm");	
		
	ElsIf ActionType = "SalesOrder" Then
		OpenForm("Document.SalesOrder.ListForm");	
		
	ElsIf ActionType = "CashReceipt" Then
		OpenForm("Document.CashReceipt.ListForm");	
		
	ElsIf ActionType = "CreditMemo" Then
		OpenForm("Document.SalesReturn.ListForm");	
		
	
	
	
	EndIf;
	
EndProcedure

&AtClient
Procedure Finish(Command)
	
	ThisForm.Close();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If Not AttachFileSystemExtension() Then
		Items.FilePath.Visible = False;
	Else 
		Items.FilePath.Visible = True;
	EndIf;
	
EndProcedure

&AtServer
Procedure CreateCheckCSV(ItemDataSet) Export
	
	
	For Each DataLine In ItemDataSet Do
				
		
		NewCheck = Documents.Check.CreateDocument();
		NewCheck.Date = DataLine.CheckDate;
		NewCheck.Number = DataLine.CheckNumber;
		NewCheck.BankAccount = DataLine.CheckBankAccount;
		NewCheck.Memo = DataLine.CheckMemo;
		NewCheck.Company = DataLine.CheckVendor;
		NewCheck.DocumentTotalRC = DataLine.CheckLineAmount;
		NewCheck.DocumentTotal = DataLine.CheckLineAmount;
		NewCheck.ExchangeRate = 1;
		NewCheck.PaymentMethod = Catalogs.PaymentMethods.DebitCard;
		NewLine = NewCheck.LineItems.Add();
		NewLine.Account = DataLine.CheckLineAccount;
		NewLine.Amount = DataLine.CheckLineAmount;
		NewLine.Memo = DataLine.CheckLineMemo;
		NewLine.Class = DataLine.CheckLineClass;
		NewCheck.Write();

		
	EndDo;

	
EndProcedure

&AtServer
Procedure CreateDepositCSV(ItemDataSet) Export
		
	For Each DataLine In ItemDataSet Do				
		
		//If DataLine.
		NewDeposit = Documents.Deposit.CreateDocument();
		NewDeposit.Date = DataLine.DepositDate;
		NewDeposit.BankAccount = DataLine.DepositBankAccount;
		NewDeposit.Memo = DataLine.DepositMemo;
		NewDeposit.DocumentTotalRC = DataLine.DepositLineAmount;
		NewDeposit.DocumentTotal = DataLine.DepositLineAmount;
		NewLine = NewDeposit.Accounts.Add();
		NewLine.Company = DataLine.DepositLineCompany;
		NewLine.Account = DataLine.DepositLineAccount;
		NewLine.Class = DataLine.DepositLineClass;
		NewLine.Amount = DataLine.DepositLineAmount;
		NewLine.Memo = DataLine.DepositLineMemo;
		NewDeposit.Write();
		
	EndDo;
	
EndProcedure

&AtClient
Procedure MapToTemplateCV(Command)
	SaveFormDataOnServer("DataImportUserValue"+ActionType);
EndProcedure

&AtServer
Procedure SaveFormDataOnServer(IDSettings)
	FormSettingStorage = FormDataSettingsStorage;
	FormSettingStorage.Save("26454b8a-56b8-4051-8899-1cf366b272ca",IDSettings,ValueToStringInternal(Attributes.Unload()));
EndProcedure

&AtServer
Procedure LoadFormDataOnServer(IDSettings,SettingStorageString = "")
	
	If SettingStorageString = "" Then
		FormSettingStorage = FormDataSettingsStorage;
		SavedSettings = FormSettingStorage.Load("26454b8a-56b8-4051-8899-1cf366b272ca",IDSettings);
		If SavedSettings = Undefined Then
			Return;
		EndIf;	
		AttributesSettins = ValueFromStringInternal(FormSettingStorage.Load("26454b8a-56b8-4051-8899-1cf366b272ca",IDSettings));
	Else
		AttributesSettins = ValueFromStringInternal(SettingStorageString);
	EndIf;	
	
	If TypeOf(AttributesSettins) = Type("ValueTable") Then
		For Each StrSetting In AttributesSettins Do
			For Each Str In Attributes Do 
				If Str.AttributeName = StrSetting.AttributeName Then 
					Str.ColumnNumber = StrSetting.ColumnNumber;
					//Str.Required = StrSetting.Required;
					Try
						Str.Value = StrSetting.Value;
					Except
					EndTry;	
					Break;
				EndIf;	
			EndDo;	
		EndDo;	
	EndIf;	
EndProcedure

&AtClient
Procedure SaveToDisk(Command)
	
	WriteSettingsFile();
	GetFile(SettingSourceAddress,"*.txt");
	
EndProcedure

&AtClient
Procedure LoadFromDisk(Command)
	Notify = New NotifyDescription("SettingFileUpload",ThisForm);
	BeginPutFile(Notify, "", "*.txt", True, ThisForm.UUID);
EndProcedure

&AtClient
Procedure SettingFileUpload(Result, Address, SelectedFileName, AdditionalParameters) Export
	If Result <> False Then 
		ReadSettingsFile(Address);
	EndIf;	
EndProcedure

&AtServer
Procedure WriteSettingsFile()
	
	SettingsString =  ValueToStringInternal(Attributes.Unload());
	CSettings = New TextDocument;
	CSettings.AddLine(SettingsString);
	TempFileName = GetTempFileName("txt");
	CSettings.Write(TempFileName);
	File = New File(TempFileName);
	
	If File.Exist() Then 
		BinaryData = New BinaryData(TempFileName);
		SettingSourceAddress = PutToTempStorage(BinaryData, UUID);
		DeleteFiles(TempFileName);
	EndIf;
	
EndProcedure

&AtServer
Procedure ReadSettingsFile(TempStorageAddress)
	BinaryData = GetFromTempStorage(TempStorageAddress);
	TempFileName = GetTempFileName("txt");
	BinaryData.Write(TempFileName);
	CSettings = New TextDocument;
	CSettings.Read(TempFileName);
	SettString = CSettings.GetText();
	LoadFormDataOnServer("",SettString);
EndProcedure

&AtClient
Procedure ClearAllFields(Command)
	ClearAllFieldsAtServer();
EndProcedure

&AtServer
Procedure ClearAllFieldsAtServer()
	For Each Attr in Attributes Do 
		Attr.ColumnNumber = 0;
	EndDo;	
EndProcedure

&AtServer
Procedure FillObjectCustomNamesMap()// custom fields
	
	ObjectCustomFieldMap.Clear();
	
	If ActionType = "CustomersVendors" Then 
		NamesStruct = New Structure;
		For I = 1 to 5 Do 
			CFType = Constants["CF"+I+"CType"].Get();
			CFName = Constants["CF"+I+"CName"].Get();
			If CFType = "None" OR CFType = "" Then
				CFMap = ObjectCustomFieldMap.Add();
				CFMap.AttributeName = "Company CF" + I + " string [char(100)]";
				CFMap.CustomName = "(NOT USED)";
				Items["DataListCustomerCF"+I+"String"].Visible = False;
				
				CFMap = ObjectCustomFieldMap.Add();
				CFMap.AttributeName = "Company CF" + I + " num [num]";
				CFMap.CustomName = "(NOT USED)";
				Items["DataListCustomerCF"+I+"Num"].Visible = False;
			ElsIf CFType = "Number" Then
				CFMap = ObjectCustomFieldMap.Add();
				CFMap.AttributeName = "Company CF" + I + " string [char(100)]";
				CFMap.CustomName = "(NOT USED)";
				Items["DataListCustomerCF"+I+"String"].Visible = False;
				
				CFMap = ObjectCustomFieldMap.Add();
				CFMap.AttributeName = "Company CF" + I + " num [num]";
				CFMap.CustomName = "(CF"+I+") "+ CFName;
				
			ElsIf CFType = "String" Then
				CFMap = ObjectCustomFieldMap.Add();
				CFMap.AttributeName = "Company CF" + I + " string [char(100)]";
				CFMap.CustomName = "(CF"+I+") "+ CFName;
				
				CFMap = ObjectCustomFieldMap.Add();
				CFMap.AttributeName = "Company CF" + I + " num [num]";
				CFMap.CustomName = "(NOT USED)";
				Items["DataListCustomerCF"+I+"Num"].Visible = False;
			EndIf;	
			
		EndDo;
		
		For I = 1 to 5 Do 
			CFAType = Constants["CF"+I+"AType"].Get();
			CFAName = Constants["CF"+I+"AName"].Get();
			If CFAType = "None" OR CFType = "" Then
				CFMap = ObjectCustomFieldMap.Add();
				CFMap.AttributeName = "Address CF" + I + " string [char(200)]";
				CFMap.CustomName = "(NOT USED)";
				Items["DataListAddressCF"+I+"String"].Visible = False;
				
			ElsIf CFAType = "String" Then
				CFMap = ObjectCustomFieldMap.Add();
				CFMap.AttributeName = "Address CF" + I + " string [char(200)]";
				CFMap.CustomName = "(Addr CF"+I+") "+ CFAName;
			EndIf;	
		EndDo;
	ElsIf ActionType = "Items" Then 
		
		NamesStruct = New Structure;
		For I = 1 to 5 Do 
			CFType = Constants["CF"+I+"Type"].Get();
			CFName = Constants["CF"+I+"Name"].Get();
			If CFType = "None" OR CFType = "" Then
				CFMap = ObjectCustomFieldMap.Add();
				CFMap.AttributeName = "CF"+I+"String [char(100)]";
				CFMap.CustomName = "(NOT USED)";
				Items["DataListProductCF"+I+"String"].Visible = False;
				
				CFMap = ObjectCustomFieldMap.Add();
				CFMap.AttributeName = "CF"+I+"Num [num]";
				CFMap.CustomName = "(NOT USED)";
				Items["DataListProductCF"+I+"Num"].Visible = False;
			ElsIf CFType = "Number" Then
				CFMap = ObjectCustomFieldMap.Add();
				CFMap.AttributeName = "CF"+I+"String [char(100)]";
				CFMap.CustomName = "(NOT USED)";
				Items["DataListProductCF"+I+"String"].Visible = False;
				
				CFMap = ObjectCustomFieldMap.Add();
				CFMap.AttributeName = "CF"+I+"Num [num]";
				CFMap.CustomName = "(CF"+I+") "+ CFName;
				
			ElsIf CFType = "String" Then
				CFMap = ObjectCustomFieldMap.Add();
				CFMap.AttributeName = "CF"+I+"String [char(100)]";
				CFMap.CustomName = "(CF"+I+") "+ CFName;
				
				CFMap = ObjectCustomFieldMap.Add();
				CFMap.AttributeName = "CF"+I+"Num [num]";
				CFMap.CustomName = "(NOT USED)";
				Items["DataListProductCF"+I+"Num"].Visible = False;
			EndIf;	
			
		EndDo;
		
		//Items.DataListProductCF1String.Visible = ThisProducts;
		//Items.DataListProductCF1Num.Visible = ThisProducts;
		
		//AddAttribute("CF1String [char(100)]");
		//AddAttribute("CF1Num [num]");
		
		//If CF1Type = "None" Then
		//	Items.CF1Num.Visible = False;
		//	Items.CF1String.Visible = False;
		//ElsIf CF1Type = "Number" Then
		//	Items.CF1Num.Visible = True;
		//	Items.CF1String.Visible = False;
		//	Items.CF1Num.Title = Constants.CF1Name.Get();
		//ElsIf CF1Type = "String" Then
		//	Items.CF1Num.Visible = False;
		//	Items.CF1String.Visible = True;
		//	Items.CF1String.Title = Constants.CF1Name.Get();
		//ElsIf CF1Type = "" Then
		//	Items.CF1Num.Visible = False;
		//	Items.CF1String.Visible = False;
		//EndIf;
		
		
	Else
		
	EndIf;
	
EndProcedure	

&AtServer
Procedure FinishBackAtServer()
	VisibilitySetup("CreatePage");
EndProcedure

&AtClient
Procedure FinishBack(Command)
	FinishBackAtServer();
EndProcedure

&AtClient
Procedure StartNewImport(Command)
	StartNewImportAtServer();
EndProcedure

&AtServer
Procedure StartNewImportAtServer()
	Items.LoadSteps.CurrentPage = Items.LoadSteps.ChildItems.Greeting;
EndProcedure

&AtServer
Procedure LoadDefaultSettingsAtServer()
	LoadFormDataOnServer("DataImportUserValue"+ActionType);
EndProcedure

&AtClient
Procedure LoadDefaultSettings(Command)
	LoadDefaultSettingsAtServer();
EndProcedure
