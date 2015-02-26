
////++ MisA
//&AtClient
//Var LoadInBackgroundJobSettings; 
//Var AdditionalMappingNames;
//-- MisA

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	ActionType = Parameters.ActionType;
	FillAttributes();
	Date = CurrentDate();
	Date2 = CurrentDate();
	//IncomeAccount = Constants.IncomeAccount.Get();
	//ExpenseAccount = Constants.ExpenseAccount.Get();	
	
EndProcedure

&AtClient
Procedure GreetingNext(Command)
	
	Notify = New NotifyDescription("FileUpload",ThisForm);

	BeginPutFile(Notify, "", "*.csv", True, ThisForm.UUID);
	
	If Attributes.Count() = 0 Then
		FillAttributes();
	EndIf;
	
	Items.MappingGroup.Title = FilePath;
	//ReadSourceFile(); // move to FileUpload
	
	LoadFormDataOnServer("DataImportUserValue"+ActionType);
	#If WebClient then
		Items.SaveToDisk.Visible = False;
		Items.LoadFromDisk.Visible = False;
	#EndIf
	
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
		
		//CurrentLine 	= SourceText.GetLine(LineNumber);
		//ValuesArray 	= StringFunctionsClientServer.SplitStringIntoSubstringArray(CurrentLine, ",");
		//ColumnsCount 	= ValuesArray.Count();
		//
		//If ColumnsCount < 1 Or ColumnsCount > 3 Then
		//	Continue;
		//EndIf;
		//
		////Convert date
		//TransactionDate = '00010101';
		//DateParts = StringFunctionsClientServer.SplitStringIntoSubstringArray(ValuesArray[0], "/");
		//If DateParts.Count() = 3 then
		//	Try
		//		TransactionDate 	= Date(DateParts[2], DateParts[0], DateParts[1]);
		//	Except
		//	EndTry;				
		//EndIf;
		//If (Not ValueIsFilled(TransactionDate)) OR (TransactionDate < Object.ProcessingPeriod.StartDate) OR (TransactionDate > Object.ProcessingPeriod.EndDate) Then
		//	TextMessage = "The following bank transaction: " + Format(TransactionDate, "DLF=D") + "; " + ValuesArray[1] + "; " + ValuesArray[2] + " does not belong to the processing period";
		//	CommonUseClientServer.MessageToUser(TextMessage);
		//	Continue;
		//EndIf;
		//NewRow = Object.BankTransactionsUnaccepted.Add();
		//NewRow.TransactionDate 	= TransactionDate;
		//NewRow.Description 		= ValuesArray[1];
		//NewRow.Amount 			= ValuesArray[2];
		//NewRow.BankAccount 		= AccountInBank;
		//NewRow.Hide 			= "Hide";
		//
		////Try to match an uploaded transaction with an existing document
		//DocumentFound = FindAnExistingDocument(NewRow.Description, NewRow.Amount, Object.BankAccount);
		//If DocumentFound <> Undefined Then
		//	NewRow.Document 		= DocumentFound;
		//EndIf;
		//NewRow.AssigningOption 	= GetAssigningOption(NewRow.Document, String(DocumentFound));
		//
		////Record new item to the database
		//RecordTransactionToTheDatabaseAtServer(NewRow);
		
	EndDo;
	
	//Object.BankTransactionsUnaccepted.Sort("TransactionDate DESC, Description, Company, Category, TransactionID");
	
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
		
	//Items.ARBegBal.Visible = ThisSIHeaders;
	//Items.CreditMemo.Visible = ThisSIHeaders OR ThisSIDetails;
	                     
	Items.Date.Visible = ThisProducts OR ThisExpensify;
	Items.Date2.Visible = ThisProducts;
	If ThisProducts Then
		Items.Date.Title = "Price list date";
		Items.Date2.Title = "Beg. bal. date";
	EndIf;
	
	If ThisExpensify Then
		Items.Date.Title = "Bill date";
	EndIf;
	
	Items.ExpensifyVendor.Visible = ThisExpensify;
	Items.ExpensifyVendor.MarkIncomplete = True;
	
	Items.ExpensifyInvoiceNumber.Visible = ThisExpensify;
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
	
	For I = 1 to 9 Do 
		Items["DataListField"+I].Visible = False;
	EndDo;
	
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
		AddCustomAttribute(30,"Sales Order (char(20)]","Order");	
		
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
		AddCustomAttribute(10,"Project [char(20)]","Project",);	
		AddCustomAttribute(11,"Class [char(20)]","Class",);	
		AddCustomAttribute(12,"Sales tax [Num]","SalesTax",,"Sales tax");	
		AddCustomAttribute(13,"Memo [char]","Memo",);		
		
		// Line items
		AddCustomAttribute(14,"Product [char(20)]","Product",);		
		AddCustomAttribute(15,"Description [char(20)]","Description",);		
		AddCustomAttribute(16,"Price [num)]","Price",);		
		AddCustomAttribute(17,"Line Quantity [num]","LineQuantity",,"Line Quantity");	
		AddCustomAttribute(18,"Line Total [num]","LineTotal",,"Line Total");		
		AddCustomAttribute(19,"Line Project [char(20)]","LineProject",,"Line Project");	
		AddCustomAttribute(20,"Line Class [char(20)]","LineClass",,"Line Class");	
		AddCustomAttribute(21,"Taxable amount [num]","TaxableAmount",,"Taxable amount");	
		AddCustomAttribute(22,"Taxable [1 - true, 0 - false]","Taxable",,"Taxable");	
		AddCustomAttribute(23,"Post [1 - true, 0 - false]","ToPost",,"Post");	
		
	ElsIf ThisCashReceipt Then //CashReceipt                

		AddCustomAttribute(1,"Number [char(20)]","Number",True);
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
		
		AddCustomAttribute(12,"Table type [1 - Invoices, 2 - Credits]","TableType",,"Table type");	
		AddCustomAttribute(13,"Document type [char(15)]","DocumentType",,"Document type");	
		AddCustomAttribute(14,"Document number [char(6)]","DocumentNum",,"Document number");	
		AddCustomAttribute(15,"Payment [Num]","Payment");	
		AddCustomAttribute(15,"Overpayment [Num]","Overpayment");	
		
		AddCustomAttribute(16,"Post [1 - true, 0 - false]","ToPost",,"Post");			
		
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
		AddCustomAttribute(25,"Sales Order (char(20)]","Order");	
		
		                    
	ElsIf ThisCofA Then
		
		AddAttribute("Code [char(10)]",True);
		AddAttribute("Description [char(100)]",True);
		AddAttribute("Subaccount of [char(10)]");
		AddAttribute("Type [ref]",True);
		AddAttribute("Update [ref]");
		AddAttribute("Cashflow sectiom [ref]");
		AddAttribute("Memo [str]");
		
	ElsIf ThisExpensify Then
			
		NewLine = Attributes.Add();
		NewLine.AttributeName = "Category [char(50)]";
		NewLine.Required = True;
		
		NewLine = Attributes.Add();
		NewLine.AttributeName = "Amount [num]";
		NewLine.Required = True;

	    NewLine = Attributes.Add();
		NewLine.AttributeName = "Memo [char(100)]";
						
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
		NewLine.Required = True;
		
		NewLine = Attributes.Add();
		NewLine.AttributeName = "Default shipping address [T - true, F - false]";
		NewLine.Required = True;
		
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
		
		NewLine = Attributes.Add();
		NewLine.AttributeName = "Company CF1 string [char(100)]";
		
		NewLine = Attributes.Add();
		NewLine.AttributeName = "Company CF1 num [num]";
		
		NewLine = Attributes.Add();
		NewLine.AttributeName = "Company CF2 string [char(100)]";
		
		NewLine = Attributes.Add();
		NewLine.AttributeName = "Company CF2 num [num]";

		NewLine = Attributes.Add();
		NewLine.AttributeName = "Company CF3 string [char(100)]";
		
		NewLine = Attributes.Add();
		NewLine.AttributeName = "Company CF3 num [num]";
		
		NewLine = Attributes.Add();
		NewLine.AttributeName = "Company CF4 string [char(100)]";
		
		NewLine = Attributes.Add();
		NewLine.AttributeName = "Company CF4 num [num]";

		NewLine = Attributes.Add();
		NewLine.AttributeName = "Company CF5 string [char(100)]";
		
		NewLine = Attributes.Add();
		NewLine.AttributeName = "Company CF5 num [num]";
			
		// end company header
		
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
		
		NewLine = Attributes.Add();
		NewLine.AttributeName = "Address CF1 string [char(200)]";
		
		NewLine = Attributes.Add();
		NewLine.AttributeName = "Address CF2 string [char(200)]";

		NewLine = Attributes.Add();
		NewLine.AttributeName = "Address CF3 string [char(200)]";

		NewLine = Attributes.Add();
		NewLine.AttributeName = "Address CF4 string [char(200)]";

		NewLine = Attributes.Add();
		NewLine.AttributeName = "Address CF5 string [char(200)]";

		// end address
		
		AddCustomAttribute(1,"Taxable [T - true, F - false]","STaxable",,"Taxable");
		AddCustomAttribute(2,"Sales tax rate [char(50)]","STaxRate",,"Tax rate");
		AddCustomAttribute(3,"Update all company data [T - true, F - false]","UpdateAll",,"Update all");
		
				
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
		//dAttribute("UoM [ref]");	
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
	EndIf;
	
EndProcedure // 

&AtServer
Function FillAttributesAtServer(RowCount)
	
	Source = New ValueTable;
	
	MaxRowCout = 0;
	
	For RowCounter = 1 To RowCount Do
		                                                          
		CurrentRow = SourceText.GetLine(RowCounter);
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
			NewLine[CounterColumn] = ValueArray[CounterColumn];
		EndDo;
		
	EndDo;
	
	SourceAddress = PutToTempStorage(Source, ThisForm.UUID);
	
	Return SourceAddress;
	
EndFunction

&AtServer
Procedure AddAttribute(AttrName,Required = False)
	
	NewLine = Attributes.Add();
	NewLine.AttributeName = AttrName;
	NewLine.Required = Required;
	
EndProcedure	

&AtServer
Procedure AddCustomAttribute(Counter, AttrName, ColumnName, Required = False, ColumnTitle = "")
	
	NewLine = Attributes.Add();
	NewLine.AttributeName = AttrName;
	NewLine.Required = Required;
	
	CustomColumn = ThisForm.Items.Find("DataListField"+Counter);
	If CustomColumn = Undefined Then
		////CustomColumn = Items.DataList();
		//AttrType = New Array;
		//AttrType.Add(Type("String"));
		//TypeDescription = New TypeDescription(AttrType);
		//
		////НовыйРеквизит = Новый РеквизитФормы("РеквизитКолонкаЗанятость",   // имя
		////ОписаниеТиповДляРеквизита,    // тип
		////"РеквизитТаблицаЗначений",    // путь
		////"Занятость",                  // заголовок
		////Истина);                      // сохраняемые данные
		////ДобавляемыеРеквизиты = Новый Массив;
		////ДобавляемыеРеквизиты.Добавить(НовыйРеквизит);
		////ИзменитьРеквизиты(ДобавляемыеРеквизиты);
		////NewColumn = New FormAttribute(ColumnName,TypeDescription,"Object.DataList.CustomField"+Counter, ColumnName);
		//CustomColumn = New FormAttribute("DataListField"+Counter,TypeDescription,"Object.DataList", ColumnName);
		//AddedAttributes = New Array;
		//AddedAttributes.Add(CustomColumn);
		//ChangeAttributes(AddedAttributes);
		//
		//ThisForm.Items.DataList.ChildItems
		CustomColumn = ThisForm.Items.Add("DataListField"+Counter,Type("FormField"),ThisForm.Items.DataList);
		//FillPropertyValues(CustomColumn,Items.DataListField1);
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
	
	Object.DataList.Clear();
	UploadTable = Object.DataList.Unload();
	
	Source = GetFromTempStorage(SourceAddress);
		
	For RowCounter = 0 To Source.Count() - 1 Do
				
		If ActionType = "Chart of accounts" Then
			
			NewLine = UploadTable.Add();
			NewLine.LoadFlag = True;
					
			ColumnNumber = FindAttributeColumnNumber("Code [char(10)]");
			If ColumnNumber <> Undefined Then
				NewLine.CofACode = TrimAll(Source[RowCounter][ColumnNumber - 1]);
			EndIf;

			ColumnNumber = FindAttributeColumnNumber("Description [char(100)]");
			If ColumnNumber <> Undefined Then
				NewLine.CofADescription = TrimAll(Source[RowCounter][ColumnNumber - 1]);
			EndIf;
			
			ColumnNumber = FindAttributeColumnNumber("Memo [str]");
			If ColumnNumber <> Undefined Then
				NewLine.CofAMemo = TrimAll(Source[RowCounter][ColumnNumber - 1]);
			EndIf;
			
			ColumnNumber = FindAttributeColumnNumber("Subaccount of [char(10)]");
			If ColumnNumber <> Undefined Then
				SubaccountCode = TrimAll(Source[RowCounter][ColumnNumber - 1]);
				NewLine.CofASubaccountOf = ChartsOfAccounts.ChartOfAccounts.FindByCode(SubaccountCode);
			EndIf;
			
			ColumnNumber = FindAttributeColumnNumber("Type [ref]");
			If ColumnNumber <> Undefined Then
				
				//AccountTypeValue = Enums.AccountTypes.EmptyRef();
				AccountTypeString = TrimAll(Source[RowCounter][ColumnNumber - 1]);
				AccountTypeValue = GetValueByName(AccountTypeString,"AccountType");
				NewLine.CofAType = AccountTypeValue;
				
			EndIf;

			ColumnNumber = FindAttributeColumnNumber("Update [ref]");
			If ColumnNumber <> Undefined Then
				AccountCode = TrimAll(Source[RowCounter][ColumnNumber - 1]);
				NewLine.CofAUpdate = ChartsOfAccounts.ChartOfAccounts.FindByCode(AccountCode);
			EndIf;
			
			ColumnNumber = FindAttributeColumnNumber("Cashflow sectiom [ref]");
			If ColumnNumber <> Undefined Then
				CashFlowSectionStr = TrimAll(Source[RowCounter][ColumnNumber - 1]);
				NewLine.CoACashFlowSection = GetValueByName(CashFlowSectionStr,"CFSection");
			EndIf;
			
		ElsIf ActionType = "Classes" Then
			
			NewLine = UploadTable.Add();
			NewLine.LoadFlag = True;
			
			ColumnNumber = FindAttributeColumnNumber("Name [char(25)]");
			If ColumnNumber <> Undefined Then
				varName = TrimAll(Source[RowCounter][ColumnNumber - 1]);
				NewLine.ClassName = varName;
			EndIf;
			
			ColumnNumber = FindAttributeColumnNumber("Subclass of [ref]");
			If ColumnNumber <> Undefined Then
				ParentClassName = TrimAll(Source[RowCounter][ColumnNumber - 1]);
				NewLine.SubClassOf = Catalogs.Classes.FindByDescription(ParentClassName);
			EndIf;	
			
		ElsIf ActionType = "PriceLevels" Then
			
			NewLine = UploadTable.Add();
			NewLine.LoadFlag = True;
			
			For Each Attr in CustomFieldMap Do 
				ColumnNumber = FindAttributeColumnNumber(Attr.AttributeName);
				If ColumnNumber <> Undefined Then
					CustomVariable = TrimAll(Source[RowCounter][ColumnNumber - 1]);
					If Attr.ColumnName = "Name" Then
						NewLine["CustomField"+Attr.Order] = CustomVariable;
					ElsIf Attr.ColumnName = "Type" Then
						NewLine["CustomField"+Attr.Order] = CustomVariable;
					ElsIf Attr.ColumnName = "Percentage" Then
						NewLine["CustomField"+Attr.Order] = CustomVariable;
					EndIf;	
				EndIf;
			EndDo;
		ElsIf ActionType = "SalesRep" Then
			
			NewLine = UploadTable.Add();
			NewLine.LoadFlag = True;
			
			For Each Attr in CustomFieldMap Do 
				ColumnNumber = FindAttributeColumnNumber(Attr.AttributeName);
				If ColumnNumber <> Undefined Then
					CustomVariable = Left(TrimAll(Source[RowCounter][ColumnNumber - 1]),50);
					If Attr.ColumnName = "Name" Then
						NewLine["CustomField"+Attr.Order] = CustomVariable;
					EndIf;	
				EndIf;
			EndDo;	
			
		ElsIf ActionType = "PaymentTerms" Then
			
			NewLine = UploadTable.Add();
			NewLine.LoadFlag = True;
			
			ColumnNumber = FindAttributeColumnNumber("Name [char(25)]");
			If ColumnNumber <> Undefined Then
				varName = TrimAll(Source[RowCounter][ColumnNumber - 1]);
				NewLine.PTermsName = varName;
			EndIf;
			
			
			ColumnNumber = FindAttributeColumnNumber("Days [num]");
			If ColumnNumber <> Undefined Then
				PTermsDays = TrimAll(Source[RowCounter][ColumnNumber - 1]);
				NewLine.PTermsDays = PTermsDays;
			EndIf;
			
			ColumnNumber = FindAttributeColumnNumber("Discount days [num]");
			If ColumnNumber <> Undefined Then
				PTermsDiscountDays = TrimAll(Source[RowCounter][ColumnNumber - 1]);
				NewLine.PTermsDiscountDays = PTermsDiscountDays;
			EndIf;
			
			ColumnNumber = FindAttributeColumnNumber("Discount percent [num]");
			If ColumnNumber <> Undefined Then
				PTermsDiscountPercent = TrimAll(Source[RowCounter][ColumnNumber - 1]);
				NewLine.SubClassOf = PTermsDiscountPercent;
			EndIf;		
	
			
									
		ElsIf ActionType = "Expensify" Then
			
			NewLine = UploadTable.Add();
			NewLine.LoadFlag = True;
			
			ColumnNumber = FindAttributeColumnNumber("Category [char(50)]");
			If ColumnNumber <> Undefined Then
				Category = TrimAll(Source[RowCounter][ColumnNumber - 1]);
				
				Query = New Query("SELECT
				                  |	ExpensifyCategories.Account
				                  |FROM
				                  |	Catalog.ExpensifyCategories AS ExpensifyCategories
				                  |WHERE
				                  |	ExpensifyCategories.Description = &Category");
				Query.Parameters.Insert("Category", Category);

				QueryResult = Query.Execute();
				
				If QueryResult.IsEmpty() Then
				Else
					Dataset = QueryResult.Unload();
					NewLine.ExpensifyAccount = Dataset[0][0];
				EndIf;

			EndIf;
			
			ColumnNumber = FindAttributeColumnNumber("Amount [num]");
			If ColumnNumber <> Undefined Then
				NewLine.ExpensifyAmount = TrimAll(Source[RowCounter][ColumnNumber - 1]);
			EndIf;

			ColumnNumber = FindAttributeColumnNumber("Memo [char(100)]");
			If ColumnNumber <> Undefined Then
				NewLine.ExpensifyMemo = TrimAll(Source[RowCounter][ColumnNumber - 1]);
			EndIf;							
			
		ElsIf ActionType = "Journal entries" Then
		
			NewLine = UploadTable.Add();
			NewLine.LoadFlag = True;
			
			ColumnNumber = FindAttributeColumnNumber("Date [date]");
			If ColumnNumber <> Undefined Then
				CheckDateString = TrimAll(Source[RowCounter][ColumnNumber - 1]);
				
				TransactionDate = '00010101';
				DateParts = StringFunctionsClientServer.SplitStringIntoSubstringArray(CheckDateString, "/",,"""");
				If DateParts.Count() = 3 then
					Try
						TransactionDate 	= Date(DateParts[2], DateParts[0], DatePArts[1]);
					Except
					EndTry;				
				EndIf;
				
				NewLine.GJHeaderDate = TransactionDate;
			EndIf;
			
			ColumnNumber = FindAttributeColumnNumber("Memo [char]");
			If ColumnNumber <> Undefined Then
				NewLine.GJHeaderMemo = TrimAll(Source[RowCounter][ColumnNumber - 1]);
			EndIf;
			
			ColumnNumber = FindAttributeColumnNumber("Row # [num]");
			If ColumnNumber <> Undefined Then
				NewLine.GJHeaderRowNumber = TrimAll(Source[RowCounter][ColumnNumber - 1]);
			EndIf;
			
			ColumnNumber = FindAttributeColumnNumber("Debit or Credit");
			If ColumnNumber <> Undefined Then
				NewLine.GJHeaderType = TrimAll(Source[RowCounter][ColumnNumber - 1]);
			EndIf;
			
			ColumnNumber = FindAttributeColumnNumber("Line account [ref]");
			If ColumnNumber <> Undefined Then
				AccountString = TrimAll(Source[RowCounter][ColumnNumber - 1]);
				AccountByCode = ChartsOfAccounts.ChartOfAccounts.FindByCode(AccountString);
				AccountByDescription = ChartsOfAccounts.ChartOfAccounts.FindByDescription(AccountString);
				If AccountByCode = ChartsOfAccounts.ChartOfAccounts.EmptyRef() Then
					NewLine.GJHeaderAccount = AccountByDescription;
				Else
					NewLine.GJHeaderAccount = AccountByCode;
				EndIf;
			EndIf;
			
			ColumnNumber = FindAttributeColumnNumber("Line amount [num]");
			If ColumnNumber <> Undefined Then
				LineAmount = Number(TrimAll(Source[RowCounter][ColumnNumber - 1]));
				If LineAmount < 0 Then
					LineAmount = LineAmount * -1
				EndIf;
				NewLine.GJHeaderAmount = LineAmount;
			EndIf;	
			
			ColumnNumber = FindAttributeColumnNumber("Line class [ref]");
			If ColumnNumber <> Undefined Then
				LineClassString = TrimAll(Source[RowCounter][ColumnNumber - 1]);
				NewLine.GJHeaderClass = Catalogs.Classes.FindByDescription(LineClassString);
			EndIf;
			
			ColumnNumber = FindAttributeColumnNumber("Line memo [char]");
			If ColumnNumber <> Undefined Then
				NewLine.GJHeaderLineMemo = TrimAll(Source[RowCounter][ColumnNumber - 1]);
			EndIf;
			
		ElsIf ActionType = "PurchaseOrders" Then
		
			NewLine = UploadTable.Add();
			NewLine.LoadFlag = True;
			
			For Each Attr in CustomFieldMap Do 
				ColumnNumber = FindAttributeColumnNumber(Attr.AttributeName);
				If ColumnNumber <> Undefined Then
					
					If Attr.ColumnName = "DocDate" Then
						DateStr = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						TransactionDate = '00010101';
						DateParts = StringFunctionsClientServer.SplitStringIntoSubstringArray(DateStr, "/",,"""");
						If DateParts.Count() = 3 then
							Try
								TransactionDate = Date(DateParts[2], DateParts[0], DatePArts[1]);
							Except
							EndTry;				
						EndIf;
						NewLine["CustomField"+Attr.Order] = TransactionDate;
						
					ElsIf Attr.ColumnName = "Number" Then
						NumbStr = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						NewLine["CustomField"+Attr.Order] = Left(NumbStr,20);
						
					ElsIf Attr.ColumnName = "Company" Then
						VendorString = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						VendorByCode = Catalogs.Companies.FindByCode(VendorString);
						VendorByDescription = Catalogs.Companies.FindByDescription(VendorString);
						If VendorByCode = Catalogs.Companies.EmptyRef() Then
							NewLine["CustomField"+Attr.Order] = VendorByDescription;
						Else
							NewLine["CustomField"+Attr.Order] = VendorByCode;
						EndIf;
					ElsIf Attr.ColumnName = "DSCompany" Then
						DSCompString = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						VendorByCode = Catalogs.Companies.FindByCode(DSCompString);
						VendorByDescription = Catalogs.Companies.FindByDescription(DSCompString);
						If VendorByCode = Catalogs.Companies.EmptyRef() Then
							NewLine["CustomField"+Attr.Order] = VendorByDescription;
						Else
							NewLine["CustomField"+Attr.Order] = VendorByCode;
						EndIf;	
						
					ElsIf Attr.ColumnName = "CompanyAddres" Then
						AddrID = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						//AddrRef = Catalogs.Addresses.FindByDescription(AddrID);
					  	NewLine["CustomField"+Attr.Order] = AddrID;	
					ElsIf Attr.ColumnName = "DSShipTo" Then
						AddrID = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						//AddrRef = Catalogs.Addresses.FindByDescription(AddrID);
					  	NewLine["CustomField"+Attr.Order] = AddrID;		
					ElsIf Attr.ColumnName = "DSConfirmTo" Then
						AddrID = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						//AddrRef = Catalogs.Addresses.FindByDescription(AddrID);
					  	NewLine["CustomField"+Attr.Order] = AddrID;		
					ElsIf Attr.ColumnName = "DSBillTo" Then
						AddrID = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						//AddrRef = Catalogs.Addresses.FindByDescription(AddrID);
					  	NewLine["CustomField"+Attr.Order] = AddrID;
						
						
					ElsIf Attr.ColumnName = "DSRefN" Then
						DSRefN = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						NewLine["CustomField"+Attr.Order] = Left(DSRefN,20);
						
						
					ElsIf Attr.ColumnName = "SalesPerson" Then
						SPDescription = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						SalesPersonRef = Catalogs.SalesPeople.FindByDescription(SPDescription);
					  	NewLine["CustomField"+Attr.Order] = SalesPersonRef;
						
					ElsIf Attr.ColumnName = "Currency" Then
						CurrencyCode = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						CurrencyRef = Catalogs.Currencies.FindByCode(CurrencyCode);
					  	NewLine["CustomField"+Attr.Order] = CurrencyRef;
						
					ElsIf Attr.ColumnName = "Location" Then
						LocationStr = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						Location = Catalogs.Locations.FindByDescription(LocationStr);
					  	NewLine["CustomField"+Attr.Order] = Location;	

						
					ElsIf Attr.ColumnName = "DeliveryDate" Then
						DateStr = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						TransactionDate = '00010101';
						DateParts = StringFunctionsClientServer.SplitStringIntoSubstringArray(DateStr, "/",,"""");
						If DateParts.Count() = 3 then
							Try
								DeliveryDate = Date(DateParts[2], DateParts[0], DatePArts[1]);
							Except
							EndTry;				
						EndIf;
						NewLine["CustomField"+Attr.Order] = DeliveryDate;

					ElsIf Attr.ColumnName = "Project" Then
						ProjectName = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						Project = Catalogs.Projects.FindByDescription(ProjectName);
					  	NewLine["CustomField"+Attr.Order] = Project;
						
					ElsIf Attr.ColumnName = "Class" Then
						ClassName = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						Class = Catalogs.Classes.FindByDescription(ClassName);
					  	NewLine["CustomField"+Attr.Order] = Class;
						
					ElsIf Attr.ColumnName = "Memo" Then
						MemoString = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						NewLine["CustomField"+Attr.Order] = MemoString;
						
					ElsIf Attr.ColumnName = "DocTotal" Then
						DocTotal = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						NewLine["CustomField"+Attr.Order] = DocTotal;
						
					ElsIf Attr.ColumnName = "DocTotalRC" Then
						DocTotalRC = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						NewLine["CustomField"+Attr.Order] = Left(DocTotalRC,20);
						
					ElsIf Attr.ColumnName = "Product" Then
						ProductName = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						Product = Catalogs.Products.FindByCode(ProductName);
					  	NewLine["CustomField"+Attr.Order] = Product;
						
					ElsIf Attr.ColumnName = "Description" Then
						DescriptionString = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						NewLine["CustomField"+Attr.Order] = DescriptionString;
						
					ElsIf Attr.ColumnName = "Price" Then
						Price = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						NewLine["CustomField"+Attr.Order] = Price;
						
					ElsIf Attr.ColumnName = "LineTotal" Then
						LineTotal = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						NewLine["CustomField"+Attr.Order] = LineTotal;
						
					ElsIf Attr.ColumnName = "LineProject" Then
						LProjectName = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						LProject = Catalogs.Projects.FindByDescription(LProjectName);
					  	NewLine["CustomField"+Attr.Order] = LProject;	
						
					ElsIf Attr.ColumnName = "LineClass" Then
						LClassName = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						LClass = Catalogs.Classes.FindByDescription(LClassName);
					  	NewLine["CustomField"+Attr.Order] = LClass;
						
					ElsIf Attr.ColumnName = "LineQuantity" Then
						LineQuantity = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						NewLine["CustomField"+Attr.Order] = LineQuantity;		
						
					ElsIf Attr.ColumnName = "ToPost" Then
						ToPostStr = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						NewLine["CustomField"+Attr.Order] = GetValueByName(ToPostStr,"Boolean");	
					EndIf;	
				EndIf;
			EndDo;
		ElsIf ActionType = "Bills" Then
		
			NewLine = UploadTable.Add();
			NewLine.LoadFlag = True;
			
			For Each Attr in CustomFieldMap Do 
				ColumnNumber = FindAttributeColumnNumber(Attr.AttributeName);
				If ColumnNumber <> Undefined Then
					
					If Attr.ColumnName = "DocDate" Then
						DateStr = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						TransactionDate = '00010101';
						DateParts = StringFunctionsClientServer.SplitStringIntoSubstringArray(DateStr, "/",,"""");
						If DateParts.Count() = 3 then
							Try
								TransactionDate = Date(DateParts[2], DateParts[0], DatePArts[1]);
							Except
							EndTry;				
						EndIf;
						NewLine["CustomField"+Attr.Order] = TransactionDate;
						
					ElsIf Attr.ColumnName = "Number" Then
						NumbStr = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						NewLine["CustomField"+Attr.Order] = Left(NumbStr,20);	
						
					ElsIf Attr.ColumnName = "TableType" Then
						TableType = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						NewLine["CustomField"+Attr.Order] = TableType;
						
					ElsIf Attr.ColumnName = "Company" Then
						VendorString = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						VendorByCode = Catalogs.Companies.FindByCode(VendorString);
						VendorByDescription = Catalogs.Companies.FindByDescription(VendorString);
						If VendorByCode = Catalogs.Companies.EmptyRef() Then
							NewLine["CustomField"+Attr.Order] = VendorByDescription;
						Else
							NewLine["CustomField"+Attr.Order] = VendorByCode;
						EndIf;
					ElsIf Attr.ColumnName = "CompanyAddres" Then
						AddrID = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						//AddrRef = Catalogs.Addresses.FindByDescription(AddrID);
					  	NewLine["CustomField"+Attr.Order] = AddrID;		
						
					ElsIf Attr.ColumnName = "Currency" Then
						CurrencyCode = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						CurrencyRef = Catalogs.Currencies.FindByCode(CurrencyCode);
					  	NewLine["CustomField"+Attr.Order] = CurrencyRef;	
						
					ElsIf Attr.ColumnName = "APAccount" Then
						APAccountString = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						NewLine["CustomField"+Attr.Order] = ChartsOfAccounts.ChartOfAccounts.FindByCode(APAccountString);
						
					ElsIf Attr.ColumnName = "DueDate" Then
						DateStr = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						TransactionDate = '00010101';
						DateParts = StringFunctionsClientServer.SplitStringIntoSubstringArray(DateStr, "/",,"""");
						If DateParts.Count() = 3 then
							Try
								DueDate = Date(DateParts[2], DateParts[0], DatePArts[1]);
							Except
							EndTry;				
						EndIf;
						NewLine["CustomField"+Attr.Order] = DueDate;	
						
						
					ElsIf Attr.ColumnName = "SalesPerson" Then
						SPDescription = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						SalesPersonRef = Catalogs.SalesPeople.FindByDescription(SPDescription);
					  	NewLine["CustomField"+Attr.Order] = SalesPersonRef;
					
						
					ElsIf Attr.ColumnName = "Location" Then
						LocationStr = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						Location = Catalogs.Locations.FindByDescription(LocationStr);
					  	NewLine["CustomField"+Attr.Order] = Location;	

						
					ElsIf Attr.ColumnName = "DeliveryDate" Then
						DateStr = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						TransactionDate = '00010101';
						DateParts = StringFunctionsClientServer.SplitStringIntoSubstringArray(DateStr, "/",,"""");
						If DateParts.Count() = 3 then
							Try
								DeliveryDate = Date(DateParts[2], DateParts[0], DatePArts[1]);
							Except
							EndTry;				
						EndIf;
						NewLine["CustomField"+Attr.Order] = DeliveryDate;

					ElsIf Attr.ColumnName = "Project" Then
						ProjectName = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						Project = Catalogs.Projects.FindByDescription(ProjectName);
					  	NewLine["CustomField"+Attr.Order] = Project;
						
					ElsIf Attr.ColumnName = "Class" Then
						ClassName = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						Class = Catalogs.Classes.FindByDescription(ClassName);
					  	NewLine["CustomField"+Attr.Order] = Class;
						
					ElsIf Attr.ColumnName = "Terms" Then
						DocTermsStr = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						NewLine["CustomField"+Attr.Order] = Catalogs.PaymentTerms.FindByDescription(DocTermsStr);
						
					ElsIf Attr.ColumnName = "Memo" Then
						MemoString = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						NewLine["CustomField"+Attr.Order] = MemoString;
						
					ElsIf Attr.ColumnName = "Product" Then
						ProductName = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						Product = Catalogs.Products.FindByCode(ProductName);
					  	NewLine["CustomField"+Attr.Order] = Product;
						
					ElsIf Attr.ColumnName = "Description" Then
						DescriptionString = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						NewLine["CustomField"+Attr.Order] = DescriptionString;
						
					ElsIf Attr.ColumnName = "Price" Then
						Price = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						NewLine["CustomField"+Attr.Order] = Price;
						
					ElsIf Attr.ColumnName = "LineTotal" Then
						LineTotal = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						NewLine["CustomField"+Attr.Order] = LineTotal;
						
					ElsIf Attr.ColumnName = "LinePO" Then
						LinePONum = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						LinePO = Documents.PurchaseOrder.FindByNumber(LinePONum);
					  	NewLine["CustomField"+Attr.Order] = LinePO;	
						
					ElsIf Attr.ColumnName = "LineClass" Then
						LClassName = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						LClass = Catalogs.Classes.FindByDescription(LClassName);
					  	NewLine["CustomField"+Attr.Order] = LClass;
						
					ElsIf Attr.ColumnName = "LineQuantity" Then
						LineQuantity = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						NewLine["CustomField"+Attr.Order] = LineQuantity;		
						
					ElsIf Attr.ColumnName = "LineMemo" Then
						LineMemo = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						NewLine["CustomField"+Attr.Order] = LineMemo;	
						
					ElsIf Attr.ColumnName = "LineAccount" Then
						LineAccountString = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						NewLine["CustomField"+Attr.Order] = ChartsOfAccounts.ChartOfAccounts.FindByCode(LineAccountString);	
						
					ElsIf Attr.ColumnName = "ToPost" Then
						ToPostStr = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						NewLine["CustomField"+Attr.Order] = GetValueByName(ToPostStr,"Boolean");	
					EndIf;	
				EndIf;
			EndDo;	
			
		ElsIf ActionType = "ItemReceipts" Then
		
			NewLine = UploadTable.Add();
			NewLine.LoadFlag = True;
			
			For Each Attr in CustomFieldMap Do 
				ColumnNumber = FindAttributeColumnNumber(Attr.AttributeName);
				If ColumnNumber <> Undefined Then
					
					If Attr.ColumnName = "DocDate" Then
						DateStr = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						TransactionDate = '00010101';
						DateParts = StringFunctionsClientServer.SplitStringIntoSubstringArray(DateStr, "/",,"""");
						If DateParts.Count() = 3 then
							Try
								TransactionDate = Date(DateParts[2], DateParts[0], DatePArts[1]);
							Except
							EndTry;				
						EndIf;
						NewLine["CustomField"+Attr.Order] = TransactionDate;
						
					ElsIf Attr.ColumnName = "Number" Then
						NumbStr = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						NewLine["CustomField"+Attr.Order] = Left(NumbStr,20);	
						
						
					ElsIf Attr.ColumnName = "Company" Then
						VendorString = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						VendorByCode = Catalogs.Companies.FindByCode(VendorString);
						VendorByDescription = Catalogs.Companies.FindByDescription(VendorString);
						If VendorByCode = Catalogs.Companies.EmptyRef() Then
							NewLine["CustomField"+Attr.Order] = VendorByDescription;
						Else
							NewLine["CustomField"+Attr.Order] = VendorByCode;
						EndIf;
					ElsIf Attr.ColumnName = "CompanyAddres" Then
						AddrID = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						//AddrRef = Catalogs.Addresses.FindByDescription(AddrID);
					  	NewLine["CustomField"+Attr.Order] = AddrID;		
						
					ElsIf Attr.ColumnName = "Location" Then
						LocationStr = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						Location = Catalogs.Locations.FindByDescription(LocationStr);
					  	NewLine["CustomField"+Attr.Order] = Location;	
						
					ElsIf Attr.ColumnName = "Currency" Then
						CurrencyCode = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						CurrencyRef = Catalogs.Currencies.FindByCode(CurrencyCode);
					  	NewLine["CustomField"+Attr.Order] = CurrencyRef;		
						
					ElsIf Attr.ColumnName = "DueDate" Then
						DateStr = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						TransactionDate = '00010101';
						DateParts = StringFunctionsClientServer.SplitStringIntoSubstringArray(DateStr, "/",,"""");
						If DateParts.Count() = 3 then
							Try
								DueDate = Date(DateParts[2], DateParts[0], DatePArts[1]);
							Except
							EndTry;				
						EndIf;
						NewLine["CustomField"+Attr.Order] = DueDate;	
						
						
					ElsIf Attr.ColumnName = "DeliveryDate" Then
						DateStr = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						TransactionDate = '00010101';
						DateParts = StringFunctionsClientServer.SplitStringIntoSubstringArray(DateStr, "/",,"""");
						If DateParts.Count() = 3 then
							Try
								DeliveryDate = Date(DateParts[2], DateParts[0], DatePArts[1]);
							Except
							EndTry;				
						EndIf;
						NewLine["CustomField"+Attr.Order] = DeliveryDate;

					ElsIf Attr.ColumnName = "Project" Then
						ProjectName = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						Project = Catalogs.Projects.FindByDescription(ProjectName);
					  	NewLine["CustomField"+Attr.Order] = Project;
						
					ElsIf Attr.ColumnName = "Class" Then
						ClassName = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						Class = Catalogs.Classes.FindByDescription(ClassName);
					  	NewLine["CustomField"+Attr.Order] = Class;
						
					ElsIf Attr.ColumnName = "Memo" Then
						MemoString = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						NewLine["CustomField"+Attr.Order] = MemoString;
						
					ElsIf Attr.ColumnName = "Product" Then
						ProductName = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						Product = Catalogs.Products.FindByCode(ProductName);
					  	NewLine["CustomField"+Attr.Order] = Product;
						
					ElsIf Attr.ColumnName = "Description" Then
						DescriptionString = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						NewLine["CustomField"+Attr.Order] = DescriptionString;
						
					ElsIf Attr.ColumnName = "Price" Then
						Price = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						NewLine["CustomField"+Attr.Order] = Price;
						
					ElsIf Attr.ColumnName = "UoM" Then
						UoMStr = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						UoM = Catalogs.Units.FindByDescription(UoMStr);
						NewLine["CustomField"+Attr.Order] = UoM;		
						
					ElsIf Attr.ColumnName = "LineTotal" Then
						LineTotal = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						NewLine["CustomField"+Attr.Order] = LineTotal;
						
					ElsIf Attr.ColumnName = "LinePO" Then
						LinePONum = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						LinePO = Documents.PurchaseOrder.FindByNumber(LinePONum);
					  	NewLine["CustomField"+Attr.Order] = LinePO;	
						
					ElsIf Attr.ColumnName = "LineClass" Then
						LClassName = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						LClass = Catalogs.Classes.FindByDescription(LClassName);
					  	NewLine["CustomField"+Attr.Order] = LClass;
						
					ElsIf Attr.ColumnName = "LineQuantity" Then
						LineQuantity = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						NewLine["CustomField"+Attr.Order] = LineQuantity;		
						
					ElsIf Attr.ColumnName = "ToPost" Then
						ToPostStr = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						NewLine["CustomField"+Attr.Order] = GetValueByName(ToPostStr,"Boolean");	
					EndIf;	
				EndIf;
			EndDo;
			
		ElsIf ActionType = "BillPayments" Then
		
			NewLine = UploadTable.Add();
			NewLine.LoadFlag = True;
			
			For Each Attr in CustomFieldMap Do 
				ColumnNumber = FindAttributeColumnNumber(Attr.AttributeName);
				If ColumnNumber <> Undefined Then
					
					If Attr.ColumnName = "DocDate" Then
						DateStr = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						TransactionDate = '00010101';
						DateParts = StringFunctionsClientServer.SplitStringIntoSubstringArray(DateStr, "/",,"""");
						If DateParts.Count() = 3 then
							Try
								TransactionDate = Date(DateParts[2], DateParts[0], DatePArts[1]);
							Except
							EndTry;				
						EndIf;
						NewLine["CustomField"+Attr.Order] = TransactionDate;
						
					ElsIf Attr.ColumnName = "Number" Then
						NumbStr = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						NewLine["CustomField"+Attr.Order] = Left(NumbStr,20);	
						
						
					ElsIf Attr.ColumnName = "Company" Then
						VendorString = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						VendorByCode = Catalogs.Companies.FindByCode(VendorString);
						VendorByDescription = Catalogs.Companies.FindByDescription(VendorString);
						If VendorByCode = Catalogs.Companies.EmptyRef() Then
							NewLine["CustomField"+Attr.Order] = VendorByDescription;
						Else
							NewLine["CustomField"+Attr.Order] = VendorByCode;
						EndIf;
					ElsIf Attr.ColumnName = "BankAccount" Then
						BankAccount = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						NewLine["CustomField"+Attr.Order] = ChartsOfAccounts.ChartOfAccounts.FindByCode(BankAccount);	
						
					ElsIf Attr.ColumnName = "Currency" Then
						CurrencyCode = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						CurrencyRef = Catalogs.Currencies.FindByCode(CurrencyCode);
					  	NewLine["CustomField"+Attr.Order] = CurrencyRef;		
						
					ElsIf Attr.ColumnName = "PaymentMethod" Then
						PaymentMethodName = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						PaymentMethod = Catalogs.PaymentMethods.FindByDescription(PaymentMethodName);
					  	NewLine["CustomField"+Attr.Order] = PaymentMethod;		
						
					ElsIf Attr.ColumnName = "PhysicalCheckNum" Then
						PhysicalCheckNum = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						NewLine["CustomField"+Attr.Order] = PhysicalCheckNum;		
						
					ElsIf Attr.ColumnName = "Memo" Then
						MemoString = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						NewLine["CustomField"+Attr.Order] = MemoString;
						
					ElsIf Attr.ColumnName = "Bill" Then
						BillNum = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						Bill = Documents.PurchaseInvoice.FindByNumber(BillNum);
					  	NewLine["CustomField"+Attr.Order] = Bill;
						
					ElsIf Attr.ColumnName = "Payment" Then
						Payment = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						NewLine["CustomField"+Attr.Order] = Payment;
						
					ElsIf Attr.ColumnName = "Due" Then
						Due = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						NewLine["CustomField"+Attr.Order] = Due;
						
					ElsIf Attr.ColumnName = "Check" Then
						Check = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						NewLine["CustomField"+Attr.Order] = Check;		
						
					ElsIf Attr.ColumnName = "ToPost" Then
						ToPostStr = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						NewLine["CustomField"+Attr.Order] = GetValueByName(ToPostStr,"Boolean");	
					EndIf;	
				EndIf;
			EndDo;	
			
		ElsIf ActionType = "SalesInvoice" Then
			
			NewLine = UploadTable.Add();
			NewLine.LoadFlag = True;
			
			For Each Attr in CustomFieldMap Do 
				ColumnNumber = FindAttributeColumnNumber(Attr.AttributeName);
				If ColumnNumber <> Undefined Then
					
					If Attr.ColumnName = "DocDate" Then
						DateStr = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						TransactionDate = '00010101';
						DateParts = StringFunctionsClientServer.SplitStringIntoSubstringArray(DateStr, "/",,"""");
						If DateParts.Count() = 3 then
							Try
								TransactionDate = Date(DateParts[2], DateParts[0], DatePArts[1]);
							Except
							EndTry;				
						EndIf;
						NewLine["CustomField"+Attr.Order] = TransactionDate;
					ElsIf Attr.ColumnName = "DueDate" Then
						DateStr = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						TransactionDate = '00010101';
						DateParts = StringFunctionsClientServer.SplitStringIntoSubstringArray(DateStr, "/",,"""");
						If DateParts.Count() = 3 then
							Try
								TransactionDate = Date(DateParts[2], DateParts[0], DatePArts[1]);
							Except
							EndTry;				
						EndIf;
						NewLine["CustomField"+Attr.Order] = TransactionDate;	
						
					ElsIf Attr.ColumnName = "Number" Then
						NumbStr = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						NewLine["CustomField"+Attr.Order] = Left(NumbStr,20);
						
					ElsIf Attr.ColumnName = "Company" Then
						VendorString = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						VendorByCode = Catalogs.Companies.FindByCode(VendorString);
						VendorByDescription = Catalogs.Companies.FindByDescription(VendorString);
						If VendorByCode = Catalogs.Companies.EmptyRef() Then
							NewLine["CustomField"+Attr.Order] = VendorByDescription;
						Else
							NewLine["CustomField"+Attr.Order] = VendorByCode;
						EndIf;
					ElsIf Attr.ColumnName = "ShipTo" Then
						AddrID = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						//AddrRef = Catalogs.Addresses.FindByDescription(AddrID);
						NewLine["CustomField"+Attr.Order] = AddrID;		
					ElsIf Attr.ColumnName = "ConfirmTo" Then
						AddrID = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						//AddrRef = Catalogs.Addresses.FindByDescription(AddrID);
						NewLine["CustomField"+Attr.Order] = AddrID;		
					ElsIf Attr.ColumnName = "BillTo" Then
						AddrID = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						//AddrRef = Catalogs.Addresses.FindByDescription(AddrID);
						NewLine["CustomField"+Attr.Order] = AddrID;
						
						
					ElsIf Attr.ColumnName = "RefNum" Then
						RefNum = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						NewLine["CustomField"+Attr.Order] = Left(RefNum,20);
						
						
					ElsIf Attr.ColumnName = "SalesPerson" Then
						SPDescription = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						SalesPersonRef = Catalogs.SalesPeople.FindByDescription(SPDescription);
						NewLine["CustomField"+Attr.Order] = SalesPersonRef;
						
					ElsIf Attr.ColumnName = "Currency" Then
						CurrencyCode = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						CurrencyRef = Catalogs.Currencies.FindByCode(CurrencyCode);
						NewLine["CustomField"+Attr.Order] = CurrencyRef;
						
					ElsIf Attr.ColumnName = "ARAccount" Then
						ARAccountCode = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						ARAccountRef = ChartsOfAccounts.ChartOfAccounts.FindByCode(ARAccountCode);
						NewLine["CustomField"+Attr.Order] = ARAccountRef;	
						
					ElsIf Attr.ColumnName = "Location" Then
						LocationStr = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						Location = Catalogs.Locations.FindByDescription(LocationStr);
						NewLine["CustomField"+Attr.Order] = Location;	
						
					ElsIf Attr.ColumnName = "PaymentMethod" Then
						PMStr = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						PaymentMethod = Catalogs.PaymentMethods.FindByDescription(PMStr);
						NewLine["CustomField"+Attr.Order] = PaymentMethod;	
						
						
					ElsIf Attr.ColumnName = "DeliveryDate" Then
						DateStr = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						TransactionDate = '00010101';
						DateParts = StringFunctionsClientServer.SplitStringIntoSubstringArray(DateStr, "/",,"""");
						If DateParts.Count() = 3 then
							Try
								DeliveryDate = Date(DateParts[2], DateParts[0], DatePArts[1]);
							Except
							EndTry;				
						EndIf;
						NewLine["CustomField"+Attr.Order] = DeliveryDate;
						
					ElsIf Attr.ColumnName = "Project" Then
						ProjectName = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						Project = Catalogs.Projects.FindByDescription(ProjectName);
						NewLine["CustomField"+Attr.Order] = Project;
						
					ElsIf Attr.ColumnName = "Class" Then
						ClassName = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						Class = Catalogs.Classes.FindByDescription(ClassName);
						NewLine["CustomField"+Attr.Order] = Class;
						
					ElsIf Attr.ColumnName = "Memo" Then
						MemoString = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						NewLine["CustomField"+Attr.Order] = MemoString;
						
					ElsIf Attr.ColumnName = "Terms" Then
						Terms = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						NewLine["CustomField"+Attr.Order] = Catalogs.PaymentTerms.FindByDescription(Terms);
						
					ElsIf Attr.ColumnName = "SalesTax" Then
						SalesTaxStr = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						NewLine["CustomField"+Attr.Order] = SalesTaxStr;	
						
					ElsIf Attr.ColumnName = "Product" Then
						ProductName = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						Product = Catalogs.Products.FindByCode(ProductName);
						NewLine["CustomField"+Attr.Order] = Product;
						
					ElsIf Attr.ColumnName = "Description" Then
						DescriptionString = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						NewLine["CustomField"+Attr.Order] = DescriptionString;
						
					ElsIf Attr.ColumnName = "Price" Then
						Price = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						NewLine["CustomField"+Attr.Order] = Price;
						
					ElsIf Attr.ColumnName = "LineTotal" Then
						LineTotal = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						NewLine["CustomField"+Attr.Order] = LineTotal;
						
					ElsIf Attr.ColumnName = "LineProject" Then
						LProjectName = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						LProject = Catalogs.Projects.FindByDescription(LProjectName);
						NewLine["CustomField"+Attr.Order] = LProject;	
						
					ElsIf Attr.ColumnName = "LineClass" Then
						LClassName = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						LClass = Catalogs.Classes.FindByDescription(LClassName);
						NewLine["CustomField"+Attr.Order] = LClass;
						
					ElsIf Attr.ColumnName = "LineQuantity" Then
						LineQuantity = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						NewLine["CustomField"+Attr.Order] = LineQuantity;		
						
					ElsIf Attr.ColumnName = "Taxable" Then
						TaxableStr = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						NewLine["CustomField"+Attr.Order] = GetValueByName(TaxableStr,"Boolean");
						
					ElsIf Attr.ColumnName = "TaxableAmount" Then
						TaxableAmount = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						NewLine["CustomField"+Attr.Order] = TaxableAmount;			
						
					ElsIf Attr.ColumnName = "LineOrder" Then
						LineOrderStr = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						NewLine["CustomField"+Attr.Order] = Documents.SalesOrder.FindByNumber(LineOrderStr)
						
						
					ElsIf Attr.ColumnName = "ToPost" Then
						ToPostStr = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						NewLine["CustomField"+Attr.Order] = GetValueByName(ToPostStr,"Boolean");	
					EndIf;	
				EndIf;
			EndDo;
			
		ElsIf ActionType = "CreditMemo" Then
			
			NewLine = UploadTable.Add();
			NewLine.LoadFlag = True;
			
			For Each Attr in CustomFieldMap Do 
				ColumnNumber = FindAttributeColumnNumber(Attr.AttributeName);
				If ColumnNumber <> Undefined Then
					
					If Attr.ColumnName = "DocDate" Then
						DateStr = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						TransactionDate = '00010101';
						DateParts = StringFunctionsClientServer.SplitStringIntoSubstringArray(DateStr, "/",,"""");
						If DateParts.Count() = 3 then
							Try
								TransactionDate = Date(DateParts[2], DateParts[0], DatePArts[1]);
							Except
							EndTry;				
						EndIf;
						NewLine["CustomField"+Attr.Order] = TransactionDate;
					ElsIf Attr.ColumnName = "DueDate" Then
						DateStr = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						TransactionDate = '00010101';
						DateParts = StringFunctionsClientServer.SplitStringIntoSubstringArray(DateStr, "/",,"""");
						If DateParts.Count() = 3 then
							Try
								TransactionDate = Date(DateParts[2], DateParts[0], DatePArts[1]);
							Except
							EndTry;				
						EndIf;
						NewLine["CustomField"+Attr.Order] = TransactionDate;	
						
					ElsIf Attr.ColumnName = "Number" Then
						NumbStr = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						NewLine["CustomField"+Attr.Order] = Left(NumbStr,20);
						
					ElsIf Attr.ColumnName = "Company" Then
						VendorString = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						VendorByCode = Catalogs.Companies.FindByCode(VendorString);
						VendorByDescription = Catalogs.Companies.FindByDescription(VendorString);
						If VendorByCode = Catalogs.Companies.EmptyRef() Then
							NewLine["CustomField"+Attr.Order] = VendorByDescription;
						Else
							NewLine["CustomField"+Attr.Order] = VendorByCode;
						EndIf;
					ElsIf Attr.ColumnName = "ShipFromAddr" Then
						AddrID = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						//AddrRef = Catalogs.Addresses.FindByDescription(AddrID,,,Attr.);
						NewLine["CustomField"+Attr.Order] = AddrID;		
						
					ElsIf Attr.ColumnName = "RefNum" Then
						RefNum = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						NewLine["CustomField"+Attr.Order] = Left(RefNum,20);
						
						
					ElsIf Attr.ColumnName = "SalesPerson" Then
						SPDescription = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						SalesPersonRef = Catalogs.SalesPeople.FindByDescription(SPDescription);
						NewLine["CustomField"+Attr.Order] = SalesPersonRef;
						
					ElsIf Attr.ColumnName = "Currency" Then
						CurrencyCode = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						CurrencyRef = Catalogs.Currencies.FindByCode(CurrencyCode);
						NewLine["CustomField"+Attr.Order] = CurrencyRef;
						
					ElsIf Attr.ColumnName = "ARAccount" Then
						ARAccountCode = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						ARAccountRef = ChartsOfAccounts.ChartOfAccounts.FindByCode(ARAccountCode);
						NewLine["CustomField"+Attr.Order] = ARAccountRef;	
						
					ElsIf Attr.ColumnName = "Location" Then
						LocationStr = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						Location = Catalogs.Locations.FindByDescription(LocationStr);
						NewLine["CustomField"+Attr.Order] = Location;	
						
					ElsIf Attr.ColumnName = "ParentInvoice" Then
						InvoiceNum = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						InvoiceRef = Documents.SalesInvoice.FindByNumber(InvoiceNum);
						NewLine["CustomField"+Attr.Order] = InvoiceRef;
						
					ElsIf Attr.ColumnName = "ReturnType" Then
						ReturnTypeName = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						NewLine["CustomField"+Attr.Order] = ReturnTypeName;
						
					ElsIf Attr.ColumnName = "Memo" Then
						MemoString = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						NewLine["CustomField"+Attr.Order] = MemoString;
						
					//ElsIf Attr.ColumnName = "SalesTax" Then 							// 
					//	SalesTaxStr = TrimAll(Source[RowCounter][ColumnNumber - 1]);    // Will be recalculated
					//	NewLine["CustomField"+Attr.Order] = SalesTaxStr;	            //
						
					ElsIf Attr.ColumnName = "SalesTaxRate" Then
						SalesTaxRStr = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						NewLine["CustomField"+Attr.Order] = Catalogs.SalesTaxRates.FindByDescription(SalesTaxRStr);	
						
					ElsIf Attr.ColumnName = "Product" Then
						ProductName = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						Product = Catalogs.Products.FindByCode(ProductName);
						NewLine["CustomField"+Attr.Order] = Product;
						
					ElsIf Attr.ColumnName = "Description" Then
						DescriptionString = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						NewLine["CustomField"+Attr.Order] = DescriptionString;
						
					ElsIf Attr.ColumnName = "Price" Then
						Price = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						NewLine["CustomField"+Attr.Order] = Price;
						
					ElsIf Attr.ColumnName = "LineTotal" Then
						LineTotal = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						NewLine["CustomField"+Attr.Order] = LineTotal;
						
					ElsIf Attr.ColumnName = "LineProject" Then
						LProjectName = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						LProject = Catalogs.Projects.FindByDescription(LProjectName);
						NewLine["CustomField"+Attr.Order] = LProject;	
						
					ElsIf Attr.ColumnName = "LineClass" Then
						LClassName = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						LClass = Catalogs.Classes.FindByDescription(LClassName);
						NewLine["CustomField"+Attr.Order] = LClass;
						
					ElsIf Attr.ColumnName = "LineQuantity" Then
						LineQuantity = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						NewLine["CustomField"+Attr.Order] = LineQuantity;		
						
					ElsIf Attr.ColumnName = "Taxable" Then
						TaxableStr = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						NewLine["CustomField"+Attr.Order] = GetValueByName(TaxableStr,"Boolean");
						
					ElsIf Attr.ColumnName = "LineOrder" Then
						LineOrderStr = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						NewLine["CustomField"+Attr.Order] = Documents.SalesOrder.FindByNumber(LineOrderStr)
						
					ElsIf Attr.ColumnName = "ToPost" Then
						ToPostStr = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						NewLine["CustomField"+Attr.Order] = GetValueByName(ToPostStr,"Boolean");	
					EndIf;	
				EndIf;
			EndDo;	
			
		ElsIf ActionType = "SalesOrder" Then
			
			NewLine = UploadTable.Add();
			NewLine.LoadFlag = True;
			
			For Each Attr in CustomFieldMap Do 
				ColumnNumber = FindAttributeColumnNumber(Attr.AttributeName);
				If ColumnNumber <> Undefined Then
					
					If Attr.ColumnName = "DocDate" Then
						DateStr = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						TransactionDate = '00010101';
						DateParts = StringFunctionsClientServer.SplitStringIntoSubstringArray(DateStr, "/",,"""");
						If DateParts.Count() = 3 then
							Try
								TransactionDate = Date(DateParts[2], DateParts[0], DatePArts[1]);
							Except
							EndTry;				
						EndIf;
						NewLine["CustomField"+Attr.Order] = TransactionDate;
						
					ElsIf Attr.ColumnName = "Number" Then
						NumbStr = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						NewLine["CustomField"+Attr.Order] = Left(NumbStr,20);
						
					ElsIf Attr.ColumnName = "Company" Then
						VendorString = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						VendorByCode = Catalogs.Companies.FindByCode(VendorString);
						VendorByDescription = Catalogs.Companies.FindByDescription(VendorString);
						If VendorByCode = Catalogs.Companies.EmptyRef() Then
							NewLine["CustomField"+Attr.Order] = VendorByDescription;
						Else
							NewLine["CustomField"+Attr.Order] = VendorByCode;
						EndIf;
					ElsIf Attr.ColumnName = "ShipTo" Then
						AddrID = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						//AddrRef = Catalogs.Addresses.FindByDescription(AddrID);
						NewLine["CustomField"+Attr.Order] = AddrID;		
					ElsIf Attr.ColumnName = "ConfirmTo" Then
						AddrID = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						//AddrRef = Catalogs.Addresses.FindByDescription(AddrID);
						NewLine["CustomField"+Attr.Order] = AddrID;		
					ElsIf Attr.ColumnName = "BillTo" Then
						AddrID = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						//AddrRef = Catalogs.Addresses.FindByDescription(AddrID);
						NewLine["CustomField"+Attr.Order] = AddrID;
						
						
					ElsIf Attr.ColumnName = "RefNum" Then
						RefNum = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						NewLine["CustomField"+Attr.Order] = Left(RefNum,20);
						
						
					ElsIf Attr.ColumnName = "SalesPerson" Then
						SPDescription = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						SalesPersonRef = Catalogs.SalesPeople.FindByDescription(SPDescription);
						NewLine["CustomField"+Attr.Order] = SalesPersonRef;
						
					ElsIf Attr.ColumnName = "DeliveryDate" Then
						DateStr = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						TransactionDate = '00010101';
						DateParts = StringFunctionsClientServer.SplitStringIntoSubstringArray(DateStr, "/",,"""");
						If DateParts.Count() = 3 then
							Try
								DeliveryDate = Date(DateParts[2], DateParts[0], DatePArts[1]);
							Except
							EndTry;				
						EndIf;
						NewLine["CustomField"+Attr.Order] = DeliveryDate;
						
					ElsIf Attr.ColumnName = "Project" Then
						ProjectName = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						Project = Catalogs.Projects.FindByDescription(ProjectName);
						NewLine["CustomField"+Attr.Order] = Project;
						
					ElsIf Attr.ColumnName = "Class" Then
						ClassName = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						Class = Catalogs.Classes.FindByDescription(ClassName);
						NewLine["CustomField"+Attr.Order] = Class;
						
					ElsIf Attr.ColumnName = "Memo" Then
						MemoString = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						NewLine["CustomField"+Attr.Order] = MemoString;
						
					ElsIf Attr.ColumnName = "SalesTax" Then
						SalesTaxStr = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						NewLine["CustomField"+Attr.Order] = SalesTaxStr;	
						
					ElsIf Attr.ColumnName = "Product" Then
						ProductName = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						Product = Catalogs.Products.FindByCode(ProductName);
						NewLine["CustomField"+Attr.Order] = Product;
						
					ElsIf Attr.ColumnName = "Description" Then
						DescriptionString = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						NewLine["CustomField"+Attr.Order] = DescriptionString;
						
					ElsIf Attr.ColumnName = "Price" Then
						Price = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						NewLine["CustomField"+Attr.Order] = Price;
						
					ElsIf Attr.ColumnName = "LineTotal" Then
						LineTotal = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						NewLine["CustomField"+Attr.Order] = LineTotal;
						
					ElsIf Attr.ColumnName = "LineProject" Then
						LProjectName = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						LProject = Catalogs.Projects.FindByDescription(LProjectName);
						NewLine["CustomField"+Attr.Order] = LProject;	
						
					ElsIf Attr.ColumnName = "LineClass" Then
						LClassName = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						LClass = Catalogs.Classes.FindByDescription(LClassName);
						NewLine["CustomField"+Attr.Order] = LClass;
						
					ElsIf Attr.ColumnName = "LineQuantity" Then
						LineQuantity = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						NewLine["CustomField"+Attr.Order] = LineQuantity;		
						
					ElsIf Attr.ColumnName = "Taxable" Then
						TaxableAmount = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						NewLine["CustomField"+Attr.Order] = GetValueByName(TaxableAmount,"Boolean");
						
					ElsIf Attr.ColumnName = "TaxableAmount" Then
						TaxableAmount = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						NewLine["CustomField"+Attr.Order] = TaxableAmount;			
						
					ElsIf Attr.ColumnName = "ToPost" Then
						ToPostStr = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						NewLine["CustomField"+Attr.Order] = GetValueByName(ToPostStr,"Boolean");	
					EndIf;	
				EndIf;
			EndDo;
			
		ElsIf ActionType = "CashReceipt" Then
			
			NewLine = UploadTable.Add();
			NewLine.LoadFlag = True;
			
			For Each Attr in CustomFieldMap Do 
				ColumnNumber = FindAttributeColumnNumber(Attr.AttributeName);
				If ColumnNumber <> Undefined Then
					
					If Attr.ColumnName = "DocDate" Then
						DateStr = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						TransactionDate = '00010101';
						DateParts = StringFunctionsClientServer.SplitStringIntoSubstringArray(DateStr, "/",,"""");
						If DateParts.Count() = 3 then
							Try
								TransactionDate = Date(DateParts[2], DateParts[0], DatePArts[1]);
							Except
							EndTry;				
						EndIf;
						NewLine["CustomField"+Attr.Order] = TransactionDate;
						
					ElsIf Attr.ColumnName = "Number" Then
						NumbStr = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						NewLine["CustomField"+Attr.Order] = Left(NumbStr,20);
						
					ElsIf Attr.ColumnName = "Company" Then
						VendorString = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						VendorByCode = Catalogs.Companies.FindByCode(VendorString);
						VendorByDescription = Catalogs.Companies.FindByDescription(VendorString);
						If VendorByCode = Catalogs.Companies.EmptyRef() Then
							NewLine["CustomField"+Attr.Order] = VendorByDescription;
						Else
							NewLine["CustomField"+Attr.Order] = VendorByCode;
						EndIf;
						
					ElsIf Attr.ColumnName = "RefNum" Then
						RefNum = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						NewLine["CustomField"+Attr.Order] = Left(RefNum,20);
						
					ElsIf Attr.ColumnName = "Currency" Then
						CurrencyCode = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						CurrencyRef = Catalogs.Currencies.FindByCode(CurrencyCode);
						NewLine["CustomField"+Attr.Order] = CurrencyRef;
						
					ElsIf Attr.ColumnName = "Memo" Then
						MemoString = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						NewLine["CustomField"+Attr.Order] = MemoString;	
						
					ElsIf Attr.ColumnName = "BankAccount" Then
						BankAccountCode = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						BankAccountRef = ChartsOfAccounts.ChartOfAccounts.FindByCode(BankAccountCode);
						NewLine["CustomField"+Attr.Order] = BankAccountRef;	
						
					ElsIf Attr.ColumnName = "PaymentMethod" Then
						PMStr = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						PaymentMethod = Catalogs.PaymentMethods.FindByDescription(PMStr);
						NewLine["CustomField"+Attr.Order] = PaymentMethod;	
						
					ElsIf Attr.ColumnName = "DepositType" Then
						DepositType = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						NewLine["CustomField"+Attr.Order] = DepositType;	
						
					ElsIf Attr.ColumnName = "ARAccount" Then
						ARAccountCode = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						ARAccountRef = ChartsOfAccounts.ChartOfAccounts.FindByCode(ARAccountCode);
						NewLine["CustomField"+Attr.Order] = ARAccountRef;		
						
					ElsIf Attr.ColumnName = "SalesOrder" Then
						SalesOrderNum = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						SalesOrderRef = Documents.SalesOrder.FindByNumber(SalesOrderNum);
						NewLine["CustomField"+Attr.Order] = SalesOrderRef;
						
					ElsIf Attr.ColumnName = "TableType" Then
						TableType = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						NewLine["CustomField"+Attr.Order] = TableType;
						
					ElsIf Attr.ColumnName = "DocumentType" Then
						DocumentType = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						NewLine["CustomField"+Attr.Order] = DocumentType;	
						
					ElsIf Attr.ColumnName = "DocumentNum" Then
						DocumentNum = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						NewLine["CustomField"+Attr.Order] = DocumentNum;
						
					ElsIf Attr.ColumnName = "Payment" Then
						Payment = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						NewLine["CustomField"+Attr.Order] = Payment ;
						
					ElsIf Attr.ColumnName = "Overpayment" Then
						Overpayment = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						NewLine["CustomField"+Attr.Order] = Overpayment ;	
						
					ElsIf Attr.ColumnName = "ToPost" Then
						ToPostStr = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						NewLine["CustomField"+Attr.Order] = GetValueByName(ToPostStr,"Boolean");	
					EndIf;	
				EndIf;
			EndDo;	
	
			
		ElsIf ActionType = "Checks" Then
			
			NewLine = UploadTable.Add();
			NewLine.LoadFlag = True;

			For Each Attr in CustomFieldMap Do 
				ColumnNumber = FindAttributeColumnNumber(Attr.AttributeName);
				If ColumnNumber <> Undefined Then
					If Attr.ColumnName = "ToPost" Then
						ToPostStr = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						NewLine["CustomField"+Attr.Order] = GetValueByName(ToPostStr,"Boolean");		
					EndIf;	
				EndIf;
			EndDo;
			
			ColumnNumber = FindAttributeColumnNumber("Date [char]");
			If ColumnNumber <> Undefined Then
				CheckDateString = TrimAll(Source[RowCounter][ColumnNumber - 1]);
				
				TransactionDate = '00010101';
				DateParts = StringFunctionsClientServer.SplitStringIntoSubstringArray(CheckDateString, "/",,"""");
				If DateParts.Count() = 3 then
					Try
						TransactionDate 	= Date(DateParts[2], DateParts[0], DatePArts[1]);
					Except
					EndTry;				
				EndIf;
				
				NewLine.CheckDate = TransactionDate;
			EndIf;

			ColumnNumber = FindAttributeColumnNumber("Number [char(6)]");
			If ColumnNumber <> Undefined Then
				NewLine.CheckNumber = TrimAll(Source[RowCounter][ColumnNumber - 1]);
			EndIf;

			ColumnNumber = FindAttributeColumnNumber("Bank account [ref]");
			If ColumnNumber <> Undefined Then
				BankAccountString = TrimAll(Source[RowCounter][ColumnNumber - 1]);
				AccountByCode = ChartsOfAccounts.ChartOfAccounts.FindByCode(BankAccountString);
				AccountByDescription = ChartsOfAccounts.ChartOfAccounts.FindByDescription(BankAccountString);
				If AccountByCode = ChartsOfAccounts.ChartOfAccounts.EmptyRef() Then
					NewLine.CheckBankAccount = AccountByDescription;
				Else
					NewLine.CheckBankAccount = AccountByCode;
				EndIf;
			EndIf;

			ColumnNumber = FindAttributeColumnNumber("Vendor [ref]");
			If ColumnNumber <> Undefined Then
				VendorString = TrimAll(Source[RowCounter][ColumnNumber - 1]);
				VendorByCode = Catalogs.Companies.FindByCode(VendorString);
				VendorByDescription = Catalogs.Companies.FindByDescription(VendorString);
				If VendorByCode = Catalogs.Companies.EmptyRef() Then
					NewLine.CheckVendor = VendorByDescription;
				Else
					NewLine.CheckVendor = VendorByCode;
				EndIf;
			EndIf;
			
			ColumnNumber = FindAttributeColumnNumber("Check memo [char]");
			If ColumnNumber <> Undefined Then
				NewLine.CheckMemo = TrimAll(Source[RowCounter][ColumnNumber - 1]);
			EndIf;
			
			ColumnNumber = FindAttributeColumnNumber("Line account [ref]");
			If ColumnNumber <> Undefined Then
				LineAccountString = TrimAll(Source[RowCounter][ColumnNumber - 1]);
				AccountByCode = ChartsOfAccounts.ChartOfAccounts.FindByCode(LineAccountString);
				AccountByDescription = ChartsOfAccounts.ChartOfAccounts.FindByDescription(LineAccountString);
				If AccountByCode = ChartsOfAccounts.ChartOfAccounts.EmptyRef() Then				
					NewLine.CheckLineAccount = AccountByDescription;
				Else
					NewLine.CheckLineAccount = AccountByCode;
				EndIf;
			EndIf;

			ColumnNumber = FindAttributeColumnNumber("Line memo [char]");
			If ColumnNumber <> Undefined Then
				NewLine.CheckLineMemo = TrimAll(Source[RowCounter][ColumnNumber - 1]);
			EndIf;

			ColumnNumber = FindAttributeColumnNumber("Line amount [num]");
			If ColumnNumber <> Undefined Then
				NewLine.CheckLineAmount = TrimAll(Source[RowCounter][ColumnNumber - 1]);
			EndIf;
			
			ColumnNumber = FindAttributeColumnNumber("Line class [ref]");
			If ColumnNumber <> Undefined Then
				LineClassString = TrimAll(Source[RowCounter][ColumnNumber - 1]);
				If LineClassString <> "" then
					NewLine.CheckLineClass = Catalogs.Classes.FindByDescription(LineClassString);
				EndIf;	
			EndIf;

			
		ElsIf ActionType = "Deposits" Then
			
			NewLine = UploadTable.Add();
			NewLine.LoadFlag = True;
			
			For Each Attr in CustomFieldMap Do 
				ColumnNumber = FindAttributeColumnNumber(Attr.AttributeName);
				If ColumnNumber <> Undefined Then
					If Attr.ColumnName = "Number" Then
						NumbStr = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						NewLine["CustomField"+Attr.Order] = Left(NumbStr,20);
					ElsIf Attr.ColumnName = "ToPost" Then
						ToPostStr = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						NewLine["CustomField"+Attr.Order] = GetValueByName(ToPostStr,"Boolean");		
					EndIf;	
				EndIf;
			EndDo;


			ColumnNumber = FindAttributeColumnNumber("Date [char]");
			If ColumnNumber <> Undefined Then
				CheckDateString = TrimAll(Source[RowCounter][ColumnNumber - 1]);
				
				TransactionDate = '00010101';
				DateParts = StringFunctionsClientServer.SplitStringIntoSubstringArray(CheckDateString, "/",,"""");
				If DateParts.Count() = 3 then
					Try
						TransactionDate 	= Date(DateParts[2], DateParts[0], DatePArts[1]);
					Except
					EndTry;				
				EndIf;
				
				NewLine.DepositDate = TransactionDate;
			EndIf;

			ColumnNumber = FindAttributeColumnNumber("Bank account [ref]");
			If ColumnNumber <> Undefined Then
				BankAccountString = TrimAll(Source[RowCounter][ColumnNumber - 1]);
				AccountByCode = ChartsOfAccounts.ChartOfAccounts.FindByCode(BankAccountString);
				AccountByDescription = ChartsOfAccounts.ChartOfAccounts.FindByDescription(BankAccountString);
				If AccountByCode = ChartsOfAccounts.ChartOfAccounts.EmptyRef() Then
					NewLine.DepositBankAccount = AccountByDescription;
				Else
					NewLine.DepositBankAccount = AccountByCode;
				EndIf;
			EndIf;
			

			ColumnNumber = FindAttributeColumnNumber("Deposit memo [char]");
			If ColumnNumber <> Undefined Then
				NewLine.DepositMemo = TrimAll(Source[RowCounter][ColumnNumber - 1]);
			EndIf;
		
			ColumnNumber = FindAttributeColumnNumber("Line company [ref]");
			If ColumnNumber <> Undefined Then
				CompanyString = TrimAll(Source[RowCounter][ColumnNumber - 1]);
				NewLine.DepositLineCompany = Catalogs.Companies.FindByDescription(CompanyString);
			EndIf;
					
			ColumnNumber = FindAttributeColumnNumber("Line account [ref]");
			If ColumnNumber <> Undefined Then
				LineAccountString = TrimAll(Source[RowCounter][ColumnNumber - 1]);
				AccountByCode = ChartsOfAccounts.ChartOfAccounts.FindByCode(LineAccountString);
				AccountByDescription = ChartsOfAccounts.ChartOfAccounts.FindByDescription(LineAccountString);
				If AccountByCode = ChartsOfAccounts.ChartOfAccounts.EmptyRef() Then
					NewLine.DepositLineAccount = AccountByDescription;
				Else
					NewLine.DepositLineAccount = AccountByCode;
				EndIf;
			EndIf;

			ColumnNumber = FindAttributeColumnNumber("Line amount [num]");
			If ColumnNumber <> Undefined Then
				NewLine.DepositLineAmount = TrimAll(Source[RowCounter][ColumnNumber - 1]);
			EndIf;
			
			ColumnNumber = FindAttributeColumnNumber("Line class [ref]");
			If ColumnNumber <> Undefined Then
				LineClassString = TrimAll(Source[RowCounter][ColumnNumber - 1]);
				NewLine.DepositLineClass = Catalogs.Classes.FindByDescription(LineClassString,True);
			EndIf;

			
			ColumnNumber = FindAttributeColumnNumber("Line memo [char]");
			If ColumnNumber <> Undefined Then
				NewLine.DepositLineMemo = TrimAll(Source[RowCounter][ColumnNumber - 1]);
			EndIf;
			
		ElsIf ActionType = "CustomersVendors" Then
			
			NewLine = UploadTable.Add();
			NewLine.LoadFlag = True;
			
			ColumnNumber = FindAttributeColumnNumber("Type [0 - Customer, 1 - Vendor, 2 - Both]");
			If ColumnNumber <> Undefined Then
				CustomerTypeValue = TrimAll(Source[RowCounter][ColumnNumber - 1]);
				Try
					CustomerTypeValue = Number(CustomerTypeValue);
				
					If CustomerTypeValue = 0 OR
						CustomerTypeValue = 1 OR
						CustomerTypeValue = 2 Then
							NewLine.CustomerType = TrimAll(Source[RowCounter][ColumnNumber - 1]);
					Else
						NewLine.CustomerType = 0;
					EndIf;
	
				Except
					NewLine.CustomerType = 0;
				EndTry;
			EndIf;

			ColumnNumber = FindAttributeColumnNumber("Company code [char(5)]");
			If ColumnNumber <> Undefined Then
				NewLine.CustomerCode = TrimAll(Source[RowCounter][ColumnNumber - 1]);
			EndIf;
			
			ColumnNumber = FindAttributeColumnNumber("Company name [char(150)]");
			If ColumnNumber <> Undefined Then
				NewLine.CustomerDescription = TrimAll(Source[RowCounter][ColumnNumber - 1]);
			EndIf;
			
			ColumnNumber = FindAttributeColumnNumber("Full name [char(150)]");
			If ColumnNumber <> Undefined Then
				NewLine.CustomerFullName = TrimAll(Source[RowCounter][ColumnNumber - 1]);
			EndIf;
			
			ColumnNumber = FindAttributeColumnNumber("Default billing address [T - true, F - false]");
			If ColumnNumber <> Undefined Then
				If TrimAll(Source[RowCounter][ColumnNumber - 1]) = "T" Then
					NewLine.DefaultBillingAddress = True;
				Else
					NewLine.DefaultBillingAddress = False;
				EndIf
			EndIf;
			
			ColumnNumber = FindAttributeColumnNumber("Default shipping address [T - true, F - false]");
			If ColumnNumber <> Undefined Then
				If TrimAll(Source[RowCounter][ColumnNumber - 1]) = "T" Then
					NewLine.DefaultShippingAddress = True;
				Else
					NewLine.DefaultShippingAddress = False;
				EndIf
			EndIf;
			
			ColumnNumber = FindAttributeColumnNumber("Income account [ref]");
			If ColumnNumber <> Undefined Then
				TrxAccount = TrimAll(Source[RowCounter][ColumnNumber - 1]);
				NewLine.CustomerIncomeAccount = ChartsOfAccounts.ChartOfAccounts.FindByCode(TrxAccount);
			EndIf;
			
			ColumnNumber = FindAttributeColumnNumber("Expense account [ref]");
			If ColumnNumber <> Undefined Then
				TrxAccount = TrimAll(Source[RowCounter][ColumnNumber - 1]);
				NewLine.CustomerExpenseAccount = ChartsOfAccounts.ChartOfAccounts.FindByCode(TrxAccount);
			EndIf;

			ColumnNumber = FindAttributeColumnNumber("1099 vendor [T - true, F - false]");
			If ColumnNumber <> Undefined Then
				If TrimAll(Source[RowCounter][ColumnNumber - 1]) = "T" Then
					NewLine.CustomerVendor1099 = True;
				EndIf
			EndIf;
			
			ColumnNumber = FindAttributeColumnNumber("Employee [T - true, F - false]");
			If ColumnNumber <> Undefined Then
				If TrimAll(Source[RowCounter][ColumnNumber - 1]) = "T" Then
					NewLine.CustomerEmployee = True;
				EndIf
			EndIf;

			
			ColumnNumber = FindAttributeColumnNumber("EIN or SSN");
			If ColumnNumber <> Undefined Then
				If TrimAll(Source[RowCounter][ColumnNumber - 1]) = "EIN" Then
					NewLine.CustomerEIN_SSN = Enums.FederalIDType.EIN;
				ElsIf TrimAll(Source[RowCounter][ColumnNumber - 1]) = "SSN" Then
					NewLine.CustomerEIN_SSN = Enums.FederalIDType.SSN;
				EndIf
			EndIf;
			
			ColumnNumber = FindAttributeColumnNumber("Notes [char]");
			If ColumnNumber <> Undefined Then
				NewLine.CustomerNotes = TrimAll(Source[RowCounter][ColumnNumber - 1]);
			EndIf;
			
			ColumnNumber = FindAttributeColumnNumber("Website [char(200)]");
			If ColumnNumber <> Undefined Then
				NewLine.CustomerWebsite = TrimAll(Source[RowCounter][ColumnNumber - 1]);
			EndIf;
		
			ColumnNumber = FindAttributeColumnNumber("Terms [ref]");
			If ColumnNumber <> Undefined Then
				TermsString = TrimAll(Source[RowCounter][ColumnNumber - 1]);
				If TermsString = "" Then
					NewLine.CustomerTerms = Catalogs.PaymentTerms.Net30;
				Else
					NewLine.CustomerTerms = Catalogs.PaymentTerms.FindByDescription(TermsString);
				EndIf;
			Else
				NewLine.CustomerTerms = Catalogs.PaymentTerms.Net30;
			EndIf;
			
			ColumnNumber = FindAttributeColumnNumber("Company CF1 string [char(100)]");
			If ColumnNumber <> Undefined Then
				NewLine.CustomerCF1String = TrimAll(Source[RowCounter][ColumnNumber - 1]);
			EndIf;
			
			ColumnNumber = FindAttributeColumnNumber("Company CF1 num [num]");
			If ColumnNumber <> Undefined Then
				NewLine.CustomerCF1Num = TrimAll(Source[RowCounter][ColumnNumber - 1]);
			EndIf;
			
			ColumnNumber = FindAttributeColumnNumber("Company CF2 string [char(100)]");
			If ColumnNumber <> Undefined Then
				NewLine.CustomerCF2String = TrimAll(Source[RowCounter][ColumnNumber - 1]);
			EndIf;
			
			ColumnNumber = FindAttributeColumnNumber("Company CF2 num [num]");
			If ColumnNumber <> Undefined Then
				NewLine.CustomerCF2Num = TrimAll(Source[RowCounter][ColumnNumber - 1]);
			EndIf;

			ColumnNumber = FindAttributeColumnNumber("Company CF3 string [char(100)]");
			If ColumnNumber <> Undefined Then
				NewLine.CustomerCF3String = TrimAll(Source[RowCounter][ColumnNumber - 1]);
			EndIf;
			
			ColumnNumber = FindAttributeColumnNumber("Company CF3 num [num]");
			If ColumnNumber <> Undefined Then
				NewLine.CustomerCF3Num = TrimAll(Source[RowCounter][ColumnNumber - 1]);
			EndIf;

			ColumnNumber = FindAttributeColumnNumber("Company CF4 string [char(100)]");
			If ColumnNumber <> Undefined Then
				NewLine.CustomerCF4String = TrimAll(Source[RowCounter][ColumnNumber - 1]);
			EndIf;
			
			ColumnNumber = FindAttributeColumnNumber("Company CF4 num [num]");
			If ColumnNumber <> Undefined Then
				NewLine.CustomerCF4Num = TrimAll(Source[RowCounter][ColumnNumber - 1]);
			EndIf;
			
			ColumnNumber = FindAttributeColumnNumber("Company CF5 string [char(100)]");
			If ColumnNumber <> Undefined Then
				NewLine.CustomerCF5String = TrimAll(Source[RowCounter][ColumnNumber - 1]);
			EndIf;
			
			ColumnNumber = FindAttributeColumnNumber("Company CF5 num [num]");
			If ColumnNumber <> Undefined Then
				NewLine.CustomerCF5Num = TrimAll(Source[RowCounter][ColumnNumber - 1]);
			EndIf;
			
			ColumnNumber = FindAttributeColumnNumber("Vendor tax ID [char(15)]");
			If ColumnNumber <> Undefined Then
				NewLine.CustomerVendorTaxID = TrimAll(Source[RowCounter][ColumnNumber - 1]);
			EndIf;
			
			ColumnNumber = FindAttributeColumnNumber("Customer sales person [ref]");
			If ColumnNumber <> Undefined Then
				RepString = TrimAll(Source[RowCounter][ColumnNumber - 1]);
				If RepString = "" Then
				Else
					NewLine.CustomerSalesPerson = Catalogs.SalesPeople.FindByDescription(RepString);
				EndIf;
			EndIf;
						
			ColumnNumber = FindAttributeColumnNumber("Customer price level [ref]");
			If ColumnNumber <> Undefined Then
				PriceL = TrimAll(Source[RowCounter][ColumnNumber - 1]);
				If PriceL = "" Then
				Else
					NewLine.CustomerPriceLevel = Catalogs.PriceLevels.FindByDescription(PriceL);
				EndIf;
			EndIf;

			// billing address
			
			ColumnNumber = FindAttributeColumnNumber("Address ID [char(25)]");
			If ColumnNumber <> Undefined Then
				NewLine.CustomerAddressID = TrimAll(Source[RowCounter][ColumnNumber - 1]);
			EndIf;

			ColumnNumber = FindAttributeColumnNumber("Salutation [char(15)]");
			If ColumnNumber <> Undefined Then
				NewLine.AddressSalutation = TrimAll(Source[RowCounter][ColumnNumber - 1]);
			EndIf;
		
			ColumnNumber = FindAttributeColumnNumber("First name [char(200)]");
			If ColumnNumber <> Undefined Then
				NewLine.CustomerFirstName = TrimAll(Source[RowCounter][ColumnNumber - 1]);
			EndIf;

			ColumnNumber = FindAttributeColumnNumber("Middle name [char(200)]");
			If ColumnNumber <> Undefined Then
				NewLine.CustomerMiddleName = TrimAll(Source[RowCounter][ColumnNumber - 1]);
			EndIf;

			ColumnNumber = FindAttributeColumnNumber("Last name [char(200)]");
			If ColumnNumber <> Undefined Then
				NewLine.CustomerLastName = TrimAll(Source[RowCounter][ColumnNumber - 1]);
			EndIf;

			ColumnNumber = FindAttributeColumnNumber("Suffix [char(10)]");
			If ColumnNumber <> Undefined Then
				NewLine.AddressSuffix = TrimAll(Source[RowCounter][ColumnNumber - 1]);
			EndIf;
			
			ColumnNumber = FindAttributeColumnNumber("Job title [char(200)]");
			If ColumnNumber <> Undefined Then
				NewLine.AddressJobTitle = TrimAll(Source[RowCounter][ColumnNumber - 1]);
			EndIf;
		
			ColumnNumber = FindAttributeColumnNumber("Phone [char(50)]");
			If ColumnNumber <> Undefined Then
				NewLine.CustomerPhone = TrimAll(Source[RowCounter][ColumnNumber - 1]);
			EndIf;
			
			ColumnNumber = FindAttributeColumnNumber("Cell [char(50)]");
			If ColumnNumber <> Undefined Then
				NewLine.CustomerCell = TrimAll(Source[RowCounter][ColumnNumber - 1]);
			EndIf;

			ColumnNumber = FindAttributeColumnNumber("Fax [char(50)]");
			If ColumnNumber <> Undefined Then
				NewLine.CustomerFax = TrimAll(Source[RowCounter][ColumnNumber - 1]);
			EndIf;

			ColumnNumber = FindAttributeColumnNumber("E-mail [char(100)]");
			If ColumnNumber <> Undefined Then
				NewLine.CustomerEmail = TrimAll(Source[RowCounter][ColumnNumber - 1]);
			EndIf;

			ColumnNumber = FindAttributeColumnNumber("Address line 1 [char(250)]");
			If ColumnNumber <> Undefined Then
				NewLine.CustomerAddressLine1 = TrimAll(Source[RowCounter][ColumnNumber - 1]);
			EndIf;

			ColumnNumber = FindAttributeColumnNumber("Address line 2 [char(250)]");
			If ColumnNumber <> Undefined Then
				NewLine.CustomerAddressLine2 = TrimAll(Source[RowCounter][ColumnNumber - 1]);
			EndIf;
			
			ColumnNumber = FindAttributeColumnNumber("Address line 3 [char(250)]");
			If ColumnNumber <> Undefined Then
				NewLine.CustomerAddressLine3 = TrimAll(Source[RowCounter][ColumnNumber - 1]);
			EndIf;

			ColumnNumber = FindAttributeColumnNumber("City [char(100)]");
			If ColumnNumber <> Undefined Then
				NewLine.CustomerCity = TrimAll(Source[RowCounter][ColumnNumber - 1]);
			EndIf;

			ColumnNumber = FindAttributeColumnNumber("State [ref]");
			If ColumnNumber <> Undefined Then
				StateString = TrimAll(Source[RowCounter][ColumnNumber - 1]);
				If StateString = "" Then
				Else
					NewLine.CustomerState = Catalogs.States.FindByCode(StateString);
				EndIf;
			EndIf;

			ColumnNumber = FindAttributeColumnNumber("Country [ref]");
			If ColumnNumber <> Undefined Then
				CountryString = TrimAll(Source[RowCounter][ColumnNumber - 1]);
				If CountryString = "" Then
				Else
					NewLine.CustomerCountry = Catalogs.Countries.FindByCode(CountryString);
				EndIf;	
			EndIf;

			ColumnNumber = FindAttributeColumnNumber("ZIP [char(20)]");
			If ColumnNumber <> Undefined Then
				NewLine.CustomerZIP = TrimAll(Source[RowCounter][ColumnNumber - 1]);
			EndIf;
			
			ColumnNumber = FindAttributeColumnNumber("Address notes [char]");
			If ColumnNumber <> Undefined Then
				NewLine.CustomerAddressNotes = TrimAll(Source[RowCounter][ColumnNumber - 1]);
			EndIf;
						
			ColumnNumber = FindAttributeColumnNumber("Shipping address line 1 [char(250)]");
			If ColumnNumber <> Undefined Then
				NewLine.CustomerShippingAddressLine1 = TrimAll(Source[RowCounter][ColumnNumber - 1]);
			EndIf;

			ColumnNumber = FindAttributeColumnNumber("Shipping address line 2 [char(250)]");
			If ColumnNumber <> Undefined Then
				NewLine.CustomerShippingAddressLine2 = TrimAll(Source[RowCounter][ColumnNumber - 1]);
			EndIf;
			
			ColumnNumber = FindAttributeColumnNumber("Shipping address line 3 [char(250)]");
			If ColumnNumber <> Undefined Then
				NewLine.CustomerShippingAddressLine3 = TrimAll(Source[RowCounter][ColumnNumber - 1]);
			EndIf;

			ColumnNumber = FindAttributeColumnNumber("Shipping City [char(100)]");
			If ColumnNumber <> Undefined Then
				NewLine.CustomerShippingCity = TrimAll(Source[RowCounter][ColumnNumber - 1]);
			EndIf;

			ColumnNumber = FindAttributeColumnNumber("Shipping State [ref]");
			If ColumnNumber <> Undefined Then
				StateString = TrimAll(Source[RowCounter][ColumnNumber - 1]);
				If StateString = "" Then
				Else
					NewLine.CustomerShippingState = Catalogs.States.FindByCode(StateString);
				EndIf;
			EndIf;

			ColumnNumber = FindAttributeColumnNumber("Shipping Country [ref]");
			If ColumnNumber <> Undefined Then
				CountryString = TrimAll(Source[RowCounter][ColumnNumber - 1]);
				If CountryString = "" Then
				Else
					NewLine.CustomerShippingCountry = Catalogs.Countries.FindByCode(CountryString);
				EndIf;	
			EndIf;

			ColumnNumber = FindAttributeColumnNumber("Shipping ZIP [char(20)]");
			If ColumnNumber <> Undefined Then
				NewLine.CustomerShippingZIP = TrimAll(Source[RowCounter][ColumnNumber - 1]);
			EndIf;
			
			
			ColumnNumber = FindAttributeColumnNumber("Address CF1 string [char(200)]");
			If ColumnNumber <> Undefined Then
				NewLine.AddressCF1String = TrimAll(Source[RowCounter][ColumnNumber - 1]);
			EndIf;
			
			ColumnNumber = FindAttributeColumnNumber("Address CF2 string [char(200)]");
			If ColumnNumber <> Undefined Then
				NewLine.AddressCF2String = TrimAll(Source[RowCounter][ColumnNumber - 1]);
			EndIf;

			ColumnNumber = FindAttributeColumnNumber("Address CF3 string [char(200)]");
			If ColumnNumber <> Undefined Then
				NewLine.AddressCF3String = TrimAll(Source[RowCounter][ColumnNumber - 1]);
			EndIf;

			ColumnNumber = FindAttributeColumnNumber("Address CF4 string [char(200)]");
			If ColumnNumber <> Undefined Then
				NewLine.AddressCF4String = TrimAll(Source[RowCounter][ColumnNumber - 1]);
			EndIf;

			ColumnNumber = FindAttributeColumnNumber("Address CF5 string [char(200)]");
			If ColumnNumber <> Undefined Then
				NewLine.AddressCF5String = TrimAll(Source[RowCounter][ColumnNumber - 1]);
			EndIf;
			
			ColumnNumber = FindAttributeColumnNumber("Address sales person [ref]");
			If ColumnNumber <> Undefined Then
				RepString = TrimAll(Source[RowCounter][ColumnNumber - 1]);
				If RepString = "" Then
				Else
					NewLine.AddressSalesPerson = Catalogs.SalesPeople.FindByDescription(RepString);
				EndIf;
			EndIf;
			
			
			For Each Attr in CustomFieldMap Do 
				ColumnNumber = FindAttributeColumnNumber(Attr.AttributeName);
				If ColumnNumber <> Undefined Then
					If Attr.ColumnName = "STaxable" Then
						TaxableStr = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						NewLine["CustomField"+Attr.Order] = GetValueByName(TaxableStr,"Boolean");
					ElsIf Attr.ColumnName = "UpdateAll" Then
						UpdateAllStr = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						NewLine["CustomField"+Attr.Order] = GetValueByName(UpdateAllStr,"Boolean");	
					ElsIf Attr.ColumnName = "STaxRate" Then
						SalesTaxRateName = TrimAll(Source[RowCounter][ColumnNumber - 1]);
						SalestaxRateRef = Catalogs.SalesTaxRates.FindByDescription(SalesTaxRateName,True);
					  	NewLine["CustomField"+Attr.Order] = SalestaxRateRef;		
					EndIf
				EndIf;
			EndDo;	
						
		// end shipping address
						
		ElsIf ActionType = "Items" Then
			
			NewLine = UploadTable.Add();
			NewLine.LoadFlag = True;
			
			ColumnNumber = FindAttributeColumnNumber("Product OR Service");
			If ColumnNumber <> Undefined Then
				TypeString = TrimAll(Source[RowCounter][ColumnNumber - 1]);
				//If TypeString = "Product" Then
				//	NewLine.ProductType = Enums.InventoryTypes.Inventory;
				//ElsIf TypeString = "Service" Then
				//	NewLine.ProductType = Enums.InventoryTypes.NonInventory;
				//EndIf;
				NewLine.ProductType = GetValueByName(TypeString,"ItemType");
			EndIf;
			
			ColumnNumber = FindAttributeColumnNumber("Parent [char 50]");
			If ColumnNumber <> Undefined Then
				ProductParentCode = TrimAll(Source[RowCounter][ColumnNumber - 1]);
				NewLine.ProductParent = Catalogs.Products.FindByCode(ProductParentCode);
			EndIf;
			
			ColumnNumber = FindAttributeColumnNumber("Item code [char(50)]");
			If ColumnNumber <> Undefined Then
				NewLine.ProductCode = TrimAll(Source[RowCounter][ColumnNumber - 1]);
			EndIf;

			ColumnNumber = FindAttributeColumnNumber("Item description [char(150)]");
			If ColumnNumber <> Undefined Then
				NewLine.ProductDescription = TrimAll(Source[RowCounter][ColumnNumber - 1]);
			EndIf;
			
			ColumnNumber = FindAttributeColumnNumber("Purchase description [char(150)]");
			If ColumnNumber <> Undefined Then
				NewLine.PurchaseDescription = TrimAll(Source[RowCounter][ColumnNumber - 1]);
			EndIf;

			ColumnNumber = FindAttributeColumnNumber("Income account [ref]");
			If ColumnNumber <> Undefined Then
				IncomeAcctString = TrimAll(Source[RowCounter][ColumnNumber - 1]);
				If IncomeAcctString <> "" Then
					NewLine.ProductIncomeAcct = ChartsOfAccounts.ChartOfAccounts.FindByCode(IncomeAcctString);
				Else
					NewLine.ProductIncomeAcct = Constants.IncomeAccount.Get();
				EndIf;
			Else
				NewLine.ProductIncomeAcct = Constants.IncomeAccount.Get();
			EndIf;	
			
			ColumnNumber = FindAttributeColumnNumber("Inventory or expense account [ref]");
			If ColumnNumber <> Undefined Then
				InvAcctString = TrimAll(Source[RowCounter][ColumnNumber - 1]);
				If InvAcctString <> "" Then
					NewLine.ProductInvOrExpenseAcct = ChartsOfAccounts.ChartOfAccounts.FindByCode(InvAcctString);
				//ElsIf TypeString = "Product" Then
				ElsIf NewLine.ProductType = Enums.InventoryTypes.Inventory Then
					NewLine.ProductInvOrExpenseAcct = GeneralFunctions.InventoryAcct(Enums.InventoryTypes.Inventory);	
				//ElsIf TypeString = "Service" Then	
				ElsIf NewLine.ProductType = Enums.InventoryTypes.NonInventory Then	
					NewLine.ProductInvOrExpenseAcct = GeneralFunctions.InventoryAcct(Enums.InventoryTypes.NonInventory);
				EndIf;
			Else
				//If TypeString = "Product" Then
				If NewLine.ProductType = Enums.InventoryTypes.Inventory Then	
					NewLine.ProductInvOrExpenseAcct = GeneralFunctions.InventoryAcct(Enums.InventoryTypes.Inventory);	
				//ElsIf TypeString = "Service" Then	
				ElsIf NewLine.ProductType = Enums.InventoryTypes.NonInventory Then		
					NewLine.ProductInvOrExpenseAcct = GeneralFunctions.InventoryAcct(Enums.InventoryTypes.NonInventory);
				EndIf;
			EndIf;

			ColumnNumber = FindAttributeColumnNumber("COGS account [ref]");
			If ColumnNumber <> Undefined Then
				COGSAcctString = TrimAll(Source[RowCounter][ColumnNumber - 1]);
				If COGSAcctString <> "" Then
					NewLine.ProductCOGSAcct = ChartsOfAccounts.ChartOfAccounts.FindByCode(COGSAcctString);
				//ElsIf TypeString = "Product" Then
				ElsIf NewLine.ProductType = Enums.InventoryTypes.Inventory Then	
					NewLine.ProductCOGSAcct = GeneralFunctions.GetDefaultCOGSAcct();
				//ElsIf TypeString = "Service" Then
				ElsIf NewLine.ProductType = Enums.InventoryTypes.NonInventory Then	
					NewLine.ProductCOGSAcct = GeneralFunctions.GetEmptyAcct();	
				EndIf;
			Else
				//If TypeString = "Product" Then
				If NewLine.ProductType = Enums.InventoryTypes.Inventory Then	
					NewLine.ProductCOGSAcct = GeneralFunctions.GetDefaultCOGSAcct();
				//ElsIf TypeString = "Service" Then
				ElsIf NewLine.ProductType = Enums.InventoryTypes.NonInventory Then	
					NewLine.ProductCOGSAcct = GeneralFunctions.GetEmptyAcct();	
				EndIf;

			EndIf;

			ColumnNumber = FindAttributeColumnNumber("Price [num]");
			If ColumnNumber <> Undefined Then
				PriceString = TrimAll(Source[RowCounter][ColumnNumber - 1]);
				If PriceString <> "" Then
					NewLine.ProductPrice = PriceString;
				EndIf;
			EndIf;
			
			ColumnNumber = FindAttributeColumnNumber("Cost [Num]");
			If ColumnNumber <> Undefined Then
				CostString = TrimAll(Source[RowCounter][ColumnNumber - 1]);
				If PriceString <> "" Then
					NewLine.ProductCost = CostString;
				EndIf;
			EndIf;
			
			ColumnNumber = FindAttributeColumnNumber("Qty [num]");
			If ColumnNumber <> Undefined Then
				NewLine.ProductQty = TrimAll(Source[RowCounter][ColumnNumber - 1]);	
			EndIf;
			
			ColumnNumber = FindAttributeColumnNumber("Value [num]");
			If ColumnNumber <> Undefined Then
				NewLine.ProductValue = TrimAll(Source[RowCounter][ColumnNumber - 1]);	
			EndIf;
			
			ColumnNumber = FindAttributeColumnNumber("Taxable [T - true, F - false]");
			If ColumnNumber <> Undefined Then
				TaxableString = TrimAll(Source[RowCounter][ColumnNumber - 1]);	
				NewLine.ProductTaxable = GetValueByName(TaxableString,"ItemTaxable");
			EndIf;


			ColumnNumber = FindAttributeColumnNumber("Category [ref]");
			If ColumnNumber <> Undefined Then
				ProductCat = TrimAll(Source[RowCounter][ColumnNumber - 1]);
				If ProductCat <> "" Then
					NewLine.ProductCategory = Catalogs.ProductCategories.FindByDescription(ProductCat);
					If NewLine.ProductCategory.IsEmpty() Then 
						NewCategory = Catalogs.ProductCategories.CreateItem();
						NewCategory.Description = ProductCat;
						NewCategory.SetNewCode();
						NewCategory.Write();
						NewLine.ProductCategory = NewCategory.Ref;
					EndIf;	
				EndIf;
			EndIf;

			ColumnNumber = FindAttributeColumnNumber("UoM [ref]");
			If ColumnNumber <> Undefined Then
				ProductUM = TrimAll(Source[RowCounter][ColumnNumber - 1]);
				If ProductUM <> "" Then
					NewLine.ProductUoM = Catalogs.UM.FindByDescription(ProductUM);
				EndIf;
			EndIf;

			ColumnNumber = FindAttributeColumnNumber("Vendor Code [char(50)]");
			If ColumnNumber <> Undefined Then
				NewLine.ProductVendorCode = TrimAll(Source[RowCounter][ColumnNumber - 1]);	
			EndIf;
			
			ColumnNumber = FindAttributeColumnNumber("Prefered Vendor [char 50]");
			If ColumnNumber <> Undefined Then
				ProductPreferedVendor = TrimAll(Source[RowCounter][ColumnNumber - 1]);
				NewLine.ProductPreferedVendor = Catalogs.Companies.FindByDescription(ProductPreferedVendor,True);
			EndIf;
			
			ColumnNumber = FindAttributeColumnNumber("CF1String [char(100)]");
			If ColumnNumber <> Undefined Then
				NewLine.ProductCF1String = TrimAll(Source[RowCounter][ColumnNumber - 1]);	
			EndIf;
			
			ColumnNumber = FindAttributeColumnNumber("CF1Num [num]");
			If ColumnNumber <> Undefined Then
				NewLine.ProductCF1Num = TrimAll(Source[RowCounter][ColumnNumber - 1]);	
			EndIf;

			ColumnNumber = FindAttributeColumnNumber("CF2String [char(100)]");
			If ColumnNumber <> Undefined Then
				NewLine.ProductCF2String = TrimAll(Source[RowCounter][ColumnNumber - 1]);	
			EndIf;
			
			ColumnNumber = FindAttributeColumnNumber("CF2Num [num]");
			If ColumnNumber <> Undefined Then
				NewLine.ProductCF2Num = TrimAll(Source[RowCounter][ColumnNumber - 1]);	
			EndIf;

			ColumnNumber = FindAttributeColumnNumber("CF3String [char(100)]");
			If ColumnNumber <> Undefined Then
				NewLine.ProductCF3String = TrimAll(Source[RowCounter][ColumnNumber - 1]);	
			EndIf;
			
			ColumnNumber = FindAttributeColumnNumber("CF3Num [num]");
			If ColumnNumber <> Undefined Then
				NewLine.ProductCF3Num = TrimAll(Source[RowCounter][ColumnNumber - 1]);	
			EndIf;
			
			ColumnNumber = FindAttributeColumnNumber("CF4String [char(100)]");
			If ColumnNumber <> Undefined Then
				NewLine.ProductCF4String = TrimAll(Source[RowCounter][ColumnNumber - 1]);	
			EndIf;
			
			ColumnNumber = FindAttributeColumnNumber("CF4Num [num]");
			If ColumnNumber <> Undefined Then
				NewLine.ProductCF4Num = TrimAll(Source[RowCounter][ColumnNumber - 1]);	
			EndIf;
			
			ColumnNumber = FindAttributeColumnNumber("CF5String [char(100)]");
			If ColumnNumber <> Undefined Then
				NewLine.ProductCF5String = TrimAll(Source[RowCounter][ColumnNumber - 1]);	
			EndIf;
			
			ColumnNumber = FindAttributeColumnNumber("CF5Num [num]");
			If ColumnNumber <> Undefined Then
				NewLine.ProductCF5Num = TrimAll(Source[RowCounter][ColumnNumber - 1]);	
			EndIf;
			
			ColumnNumber = FindAttributeColumnNumber("Update [char 50]");
			If ColumnNumber <> Undefined Then
				ProductCode = TrimAll(Source[RowCounter][ColumnNumber - 1]);
				NewLine.ProductUpdate = Catalogs.Products.FindByCode(ProductCode);
			EndIf;
			
						
		EndIf;
				
	EndDo;
		
	Object.DataList.Load(UploadTable);
	
EndProcedure

&AtServer
Function FindAttributeColumnNumber(AttributeName)
	
	FoundAttribute = Undefined;
	FoundRows = Attributes.FindRows(New Structure("AttributeName", AttributeName));
	If FoundRows.Count() > 0 Then
		FoundAttribute = FoundRows[0].ColumnNumber;
	EndIf;
	
	Return ?(FoundAttribute = 0, Undefined, FoundAttribute);
	
EndFunction


&AtServer
Procedure LoadData(Cancel)
	
	If Object.DataList.Count() = 0 Then
		Return;
	EndIf;
		
	If Cancel Then
		Return;
	EndIf;
		
	If ActionType = "Expensify" Then
		
		TotalAmount = 0;
			
		NewPI = Documents.PurchaseInvoice.CreateDocument();
		
		NewPI.Company = ExpensifyVendor;
		
		Query = New Query("SELECT
		                  |	Addresses.Ref
		                  |FROM
		                  |	Catalog.Addresses AS Addresses
		                  |WHERE
		                  |	Addresses.DefaultBilling = True
		                  |	AND Addresses.Owner = &ExpensifyVendor");
		Query.Parameters.Insert("ExpensifyVendor", ExpensifyVendor);
		
		QueryResult = Query.Execute();		
		If QueryResult.IsEmpty() Then
		Else
			Dataset = QueryResult.Unload();
			NewPI.CompanyAddress = Dataset[0][0];
		EndIf;
		
		NewPI.Currency = GeneralFunctionsReusable.DefaultCurrency();
		NewPI.ExchangeRate = 1;
		NewPI.LocationActual = Catalogs.Locations.MainWarehouse;
		NewPI.Date = Date;
		NewPI.DueDate = Date;
		NewPI.Terms = Catalogs.PaymentTerms.DueOnReceipt;
		NewPI.APAccount = NewPI.Currency.DefaultAPAccount;
		NewPI.Number = ExpensifyInvoiceNumber;
		
		For Each DataLine In Object.DataList Do
			
			If DataLine.LoadFlag = True Then
			
				NewLine = NewPI.Accounts.Add();
				
				NewLine.Account = DataLine.ExpensifyAccount;
				//NewLine.AccountDescription = DataLine.ExpensifyAccount.Description;
				NewLine.Amount = DataLine.ExpensifyAmount;
				NewLine.Memo = DataLine.ExpensifyMemo;
				
				TotalAmount = TotalAmount + NewLine.Amount;
				
			Else
			EndIf;
			
		EndDo;
		
		NewPI.DocumentTotal = TotalAmount;
		NewPI.DocumentTotalRC = TotalAmount;
				
		NewPI.Write();
			
	EndIf;
	
	If ActionType = "Items" Then
		
		ItemDataSet = New Array();
		For Each DataLine In Object.DataList Do
			
			If DataLine.LoadFlag Then
				ItemLine = New Structure("ProductType, ProductCode, ProductParent, ProductDescription, PurchaseDescription, ProductIncomeAcct, ProductInvOrExpenseAcct, ProductCOGSAcct, ProductCategory, ProductUoM, ProductVendorCode, ProductPreferedVendor, ProductPrice, ProductCost, ProductQty, ProductValue, ProductTaxable, ProductCF1String, ProductCF1Num, ProductCF2String, ProductCF2Num, ProductCF3String, ProductCF3Num, ProductCF4String, ProductCF4Num, ProductCF5String, ProductCF5Num, ProductUpdate");
				FillPropertyValues(ItemLine, DataLine);
				ItemDataSet.Add(ItemLine);
			EndIf;
			
		EndDo;	
		
		Params = New Array();
		Params.Add(Date);
		Params.Add(Date2);
		Params.Add(ItemDataSet);
		
		RunProcedureInBackgroundAsLongAction("DataProcessors.DataImport.CreateItemCSV", Params);
		
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
				ItemDataSet.Add(ItemLine);
			EndIf;
			//ItemDataSet.Add(ItemLine);
		EndDo;	
		
		Params = New Array();
		Params.Add(Date);
		Params.Add(Date2);
		Params.Add(ItemDataSet);
		
		RunProcedureInBackgroundAsLongAction("DataProcessors.DataImport.CreatePurchaseOrderCSV", Params);
		//DataProcessors.DataImport.CreatePurchaseOrderCSV(Date,Date2,ItemDataSet);
		
	EndIf;
	
	If ActionType = "Bills" Then
		
		ItemDataSet = New Array();
		For Each DataLine In Object.DataList Do
			If DataLine.LoadFlag Then
				ItemLine = New Structure;
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
		
		RunProcedureInBackgroundAsLongAction("DataProcessors.DataImport.CreatePurchaseInvoiceCSV", Params);
		//DataProcessors.DataImport.CreatePurchaseInvoiceCSV(Date,Date2,ItemDataSet);
		
	EndIf;
	
	If ActionType = "ItemReceipts" Then
		
		ItemDataSet = New Array();
		For Each DataLine In Object.DataList Do
			If DataLine.LoadFlag Then
				ItemLine = New Structure;
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
		
		RunProcedureInBackgroundAsLongAction("DataProcessors.DataImport.CreateItemReceiptCSV", Params);
		//DataProcessors.DataImport.CreateItemReceiptCSV(Date,Date2,ItemDataSet);
		
	EndIf;
	
	
	If ActionType = "BillPayments" Then
		
		ItemDataSet = New Array();
		For Each DataLine In Object.DataList Do
			If DataLine.LoadFlag Then
				ItemLine = New Structure;
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
		
		RunProcedureInBackgroundAsLongAction("DataProcessors.DataImport.CreateBillPaymentCSV", Params);
		//DataProcessors.DataImport.CreateItemReceiptCSV(Date,Date2,ItemDataSet);
		
	EndIf;
	
	
	If ActionType = "SalesInvoice" Then
		
		ItemDataSet = New Array();
		For Each DataLine In Object.DataList Do
			If DataLine.LoadFlag Then
				ItemLine = New Structure;
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
		
		RunProcedureInBackgroundAsLongAction("DataProcessors.DataImport.CreateSalesInvoiceCSV", Params);
		//DataProcessors.DataImport.CreateSalesInvoiceCSV(Date,Date2,ItemDataSet);
		
	EndIf;
	
	If ActionType = "SalesOrder" Then
		
		ItemDataSet = New Array();
		For Each DataLine In Object.DataList Do
			If DataLine.LoadFlag Then
				ItemLine = New Structure;
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
		
		RunProcedureInBackgroundAsLongAction("DataProcessors.DataImport.CreateSalesOrderCSV", Params);
		//DataProcessors.DataImport.CreateSalesOrderCSV(Date,Date2,ItemDataSet);
		
	EndIf;
	
	
	If ActionType = "CashReceipt" Then
		
		ItemDataSet = New Array();
		For Each DataLine In Object.DataList Do
			If DataLine.LoadFlag Then
				ItemLine = New Structure;
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
		
		RunProcedureInBackgroundAsLongAction("DataProcessors.DataImport.CreateCashReceipCSV", Params);
		//DataProcessors.DataImport.CreateCashReceipCSV(Date,Date2,ItemDataSet);
		
	EndIf;
	
	
	If ActionType = "CreditMemo" Then
		
		ItemDataSet = New Array();
		For Each DataLine In Object.DataList Do
			If DataLine.LoadFlag Then
				ItemLine = New Structure;
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
		
		RunProcedureInBackgroundAsLongAction("DataProcessors.DataImport.CreateCreditMemoCSV", Params);
		//DataProcessors.DataImport.CreateCreditMemoCSV(Date,Date2,ItemDataSet);
		
	EndIf;



	
	
	If ActionType = "CustomersVendors" Then
		
		ItemDataSet = New Array();
		For Each DataLine In Object.DataList Do
			If DataLine.LoadFlag = True Then
				ItemLine = New Structure("CustomerType, CustomerCode, CustomerDescription, CustomerFullName, CustomerVendor1099, " +
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
		
		RunProcedureInBackgroundAsLongAction("DataProcessors.DataImport.CreateCustomerVendorCSV", Params);
		//DataProcessors.DataImport.CreateCustomerVendorCSV(ItemDataSet);
		
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
				
				ItemDataSet.Add(ItemLine);
			Else
			EndIf;
		EndDo;

		Params = New Array();
		Params.Add(ItemDataSet);
		
		RunProcedureInBackgroundAsLongAction("DataProcessors.DataImport.CreateCheckCSV", Params);
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
				
				ItemDataSet.Add(ItemLine);
			Else
			EndIf;
		EndDo;

		Params = New Array();
		Params.Add(ItemDataSet);
		RunProcedureInBackgroundAsLongAction("DataProcessors.DataImport.CreateDepositCSV", Params);
		
		
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
				
			Else
				
				UpdatedAccount = DataLine.CofAUpdate;
				UAO = UpdatedAccount.GetObject();
				UAO.Code = DataLine.CofACode;
				UAO.Order = DataLine.CofACode;
				UAO.Description = DataLine.CofADescription;
				UAO.CashFlowSection = DataLine.CoACashFlowSection;
				UAO.Memo = DataLine.CofAMemo;
				//++ MisA
				If Not DataLine.CofASubaccountOf.IsEmpty() And DataLine.CofASubaccountOf.AccountType <> UAO.AccountType Then 
					Message("The account type must be the same as the parent account. Account "+UAO+" will be written in root folder.",MessageStatus.Attention);
				Else 
					UAO.Parent = DataLine.CofASubaccountOf;
				EndIf;	
				
				If DataLine.CofAType = GeneralFunctionsReusable.BankAccountType() OR
					DataLine.CofAType = GeneralFunctionsReusable.ARAccountType() OR
					DataLine.CofAType = GeneralFunctionsReusable.APAccountType() Then
						UAO.Currency = GeneralFunctionsReusable.DefaultCurrency();
				EndIf;
				UAO.AccountType = DataLine.CofAType;
				//-- MisA
				UAO.DataExchange.Load = True;
				UAO.Write();
				
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

	
	If Cancel Then
		Message("There were errors during importing. The import will not be performed.");
		Return;
	EndIf;
	
EndProcedure

&AtClient
Procedure ActionTypeOnChange(Item)
	
	FillAttributes();
	
EndProcedure


&AtClient
Procedure MappingBack(Command)
	
	Items.LoadSteps.CurrentPage = Items.LoadSteps.ChildItems.Greeting;
	
EndProcedure

&AtClient
Procedure MappingNext(Command)
	
	CheckExpensifyVendor();
	
	For AttributeCounter = 0 To Attributes.Count() - 1 Do
		If Attributes[AttributeCounter].Required And Attributes[AttributeCounter].ColumnNumber = 0 Then
			UserMessage = New UserMessage;
			UserMessage.Text = "Please fill out the columns for required attributes";
			UserMessage.Field = "Attributes[0].ColumnNumber";
			UserMessage.Message(); 
			Return;
		EndIf; 
	EndDo;
	
	FillLoadTable();
	Items.LoadSteps.CurrentPage = Items.LoadSteps.ChildItems.Creation;
	
EndProcedure

&AtServer
Procedure CheckExpensifyVendor()
			
	If ActionType = "Expensify" Then
		If ExpensifyVendor = Catalogs.Companies.EmptyRef() Then
			Message = New UserMessage;
			Message.Text = "Please select a Vendor";
			Message.Message();
			Return;
		EndIf;
	EndIf;

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
		Or ActionType = "Checks" 
		Then
		LongActionSettings = New Structure("Finished, ResultAddres, UID, Error, DetailedErrorDescription");
		LongActionSettings.Insert("IdleTime", 5);
		
		Items.LoadSteps.CurrentPage = Items.LoadSteps.ChildItems.Finish;
		Items.Group6.Visible = False;
		Items.ActionFinished.Visible = False;
		Items.ActionInProgress.Visible = True;
		Items.LoadStatus.Visible = True;
		Items.LoadingStatusText.Visible = True;
		LoadingStatusText = NStr("en = 'Transfering data to server ...'");
		
		//LoadInBackgroundJobSettings = New Structure;
		AttachIdleHandler("LoadDataInBackroundWithCLientReportInitiation", 0.1, True);
	Else 
		Cancel = False;
		LoadData(Cancel);
		If Not Cancel Then
			Items.LoadSteps.CurrentPage = Items.LoadSteps.ChildItems.Finish;
			Items.ActionInProgress.Visible = False;
			Items.LoadStatus.Visible = False;
			Items.LoadingStatusText.Visible = False;
		EndIf;
	EndIf;	
	
	Return;
	
EndProcedure

//++ MisA

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
	LoadingIndicator = ProgressPosition;
	If ProgressPosition < 100 Then 
		Cancel = False;
		LoadData(Cancel);
		AttachIdleHandler("Attachable_ListeningLongAction", 0.1, True);
	Else 
		Items.ActionFinished.Visible = True;
		Items.ActionInProgress.Visible = False;
		LoadingStatusText = NStr("en = 'Import finished !!!'");
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
		Items.ActionFinished.Visible = True;
		Items.ActionInProgress.Visible = False;
		LoadingStatusText = NStr("en = 'IMPORT FAILED !!!'");
		Notify("DataImportFinished",, ThisObject);
		Return;
	ElsIf ActionStatus.Finished = Undefined Then 
		Items.ActionFinished.Visible = True;
		Items.ActionInProgress.Visible = False;
		LoadingStatusText = NStr("en = 'IMPORT FAILED !!!'");
		Notify("DataImportFinished",, ThisObject);
		RefreshReusableValues(); 
		Return;
	ElsIf ActionStatus.Finished Then
		LoadDataInBackroundWithCLientReport(100);
		Return;
	EndIf;
	
	If TypeOf(ActionStatus.Progress) = Type("Structure") Then 
		LoadingStatusText = ActionStatus.Progress.Text;
		LoadingIndicator = ActionStatus.Progress.Progress;
	EndIf;
	
	AttachIdleHandler("Attachable_ListeningLongAction", LongActionSettings.IdleTime, True);
	
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
		Except
			Info = ErrorInfo(); 
			Result.DetailedErrorDescription = Info.Description;
			Result.Error                    = Info.Description;
		EndTry;
	EndIf;;
	Return Result;
EndFunction

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
					Str.Required = StrSetting.Required;
					Break;
				EndIf;	
			EndDo;	
		EndDo;	
	EndIf;	
EndProcedure

&AtClient
Procedure SaveToDisk(Command)
	Try
		SettingsString = "";
		GetSettingsStringAtServer(SettingsString);
		CSettings = New TextDocument;
		CSettings.AddLine(SettingsString);
		CSettings.Write(StrReplace(Upper(FilePath),"CSV","TXT"));
	Except
	EndTry;
EndProcedure

&AtClient
Procedure LoadFromDisk(Command)
	Try 
		CSettings = New TextDocument;
		//CSettings.AddLine(SettingsString);
		CSettings.Read(StrReplace(Upper(FilePath),"CSV","TXT"));
		SettString = CSettings.GetText();
		LoadFormDataOnServer("",SettString);
	Except
	EndTry;	
	
EndProcedure

&AtServer
Procedure GetSettingsStringAtServer(SettingsString)
	SettingsString =  ValueToStringInternal(Attributes.Unload());
EndProcedure



