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
	
	Если Attributes.Количество() = 0 Тогда
		FillAttributes();
	КонецЕсли;
	
	Items.MappingGroup.Заголовок = FilePath;
	//ReadSourceFile(); // move to FileUpload
	
	
EndProcedure


&AtClient
Procedure FileUpload(Result, Address, SelectedFileName, AdditionalParameters) Export
	
	If (Find(SelectedFileName, ".csv") = 0) And (Find(SelectedFileName, ".txt") = 0) Then
		ShowMessageBox(, "Please upload a valid CSV file (.csv, .txt)");
		return;
	EndIf;
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
	
	SourceText.Прочитать(TempFileName);
	RowCount = SourceText.LineCount();
	
	Если RowCount < 1 Тогда
		ТекстСообщения = НСтр("en = 'The file has no data!'");
		Message(ТекстСообщения);
		//УправлениеНебольшойФирмойСервер.СообщитьОбОшибке(, ТекстСообщения);
		Возврат;
	КонецЕсли;
	
	SourceAddress = Неопределено;
	
	SourceAddress = FillAttributesAtServer(RowCount);
	
	Если НЕ ЗначениеЗаполнено(SourceAddress) Тогда
		Возврат;
	КонецЕсли;
	
	FillSourceView();
	Items.LoadSteps.ТекущаяСтраница = Items.LoadSteps.ПодчиненныеЭлементы.Mapping;

EndProcedure



&AtClient
Procedure FileStartPath(Item, ДанныеВыбора, StandardProcessing)
	
	//FileSelectionDialogue = Новый ДиалогВыбораФайла(РежимДиалогаВыбораФайла.Открытие);
	//
	//FileSelectionDialogue.Фильтр                      = НСтр("en='CSV file (*.csv)|*.csv'");
	//FileSelectionDialogue.Заголовок                   = Заголовок;
	//FileSelectionDialogue.ПредварительныйПросмотр     = Ложь;
	//FileSelectionDialogue.Расширение                  = "csv";
	//FileSelectionDialogue.ИндексФильтра               = 0;
	//FileSelectionDialogue.ПолноеИмяФайла              = Item.ТекстРедактирования;
	//FileSelectionDialogue.ПроверятьСуществованиеФайла = Ложь;
	//
	//Если FileSelectionDialogue.Выбрать() Тогда
	//	FilePath = FileSelectionDialogue.ПолноеИмяФайла;
	//КонецЕсли;
	
	//Notify = New NotifyDescription("FileUpload",ThisForm);

	//BeginPutFile(Notify, "", "*.csv", True, ThisForm.UUID);
	
	
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
	Items.DataListAddressCF1String.Visible = ThisCustomers;
	Items.DataListAddressCF2String.Visible = ThisCustomers;
	Items.DataListAddressCF3String.Visible = ThisCustomers;
	Items.DataListAddressCF4String.Visible = ThisCustomers;
	Items.DataListAddressCF5String.Visible = ThisCustomers;
	// billing

	Items.DataListProductCode.Visible = ThisProducts;
	Items.DataListProductDescription.Visible = ThisProducts;
	Items.DataListProductType.Visible = ThisProducts;
	Items.DataListProductIncomeAcct.Visible = ThisProducts;
	Items.DataListProductInvOrExpenseAcct.Visible = ThisProducts;
	Items.DataListProductCOGSAcct.Visible = ThisProducts;
	Items.DataListProductPrice.Visible = ThisProducts;
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

	//Items.DataListProductPreferredVendor.Visible = ThisProducts;
	
	Attributes.Clear();	
	
	If ThisDeposits Then
		
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
		
	ElsIf ThisClasses Then
		
		NewLine = Attributes.Add();
		NewLine.AttributeName = "Name [char(25)]";
		NewLine.Required = True;
		
		NewLine = Attributes.Add();
		NewLine.AttributeName = "Subclass of [ref]";		
	
	ElsIf ThisCofA Then
		
		NewLine = Attributes.Add();
		NewLine.AttributeName = "Code [char(10)]";
		NewLine.Required = True;
		
		NewLine = Attributes.Add();
		NewLine.AttributeName = "Description [char(100)]";
		NewLine.Required = True;
		
		NewLine = Attributes.Add();
		NewLine.AttributeName = "Subaccount of [char(10)]";
		//NewLine.Required = True;

		NewLine = Attributes.Add();
		NewLine.AttributeName = "Type [ref]";
		NewLine.Required = True;
		
		NewLine = Attributes.Add();
		NewLine.AttributeName = "Update [ref]";
		
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
		//NewLine.ColumnNumber = 2;
		
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
		//NewLine.ColumnNumber = 3;
		
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
				
	ElsIf ThisProducts Then
		
		NewLine = Attributes.Add();
		NewLine.AttributeName = "Product OR Service";
		NewLine.Required = True;
	
		NewLine = Attributes.Add();
		NewLine.AttributeName = "Item code [char(50)]";
		NewLine.Required = True;
		
		NewLine = Attributes.Add();
		NewLine.AttributeName = "Item description [char(150)]";
		NewLine.Required = True;
		
		NewLine = Attributes.Add();
		NewLine.AttributeName = "Income account [ref]";
		
		NewLine = Attributes.Add();
		NewLine.AttributeName = "Inventory or expense account [ref]";
		
		NewLine = Attributes.Add();
		NewLine.AttributeName = "COGS account [ref]";
		
		NewLine = Attributes.Add();
		NewLine.AttributeName = "Price [num]";
		
		NewLine = Attributes.Add();
		NewLine.AttributeName = "Qty [num]";
		
		NewLine = Attributes.Add();
		NewLine.AttributeName = "Value [num]";
		
		//NewLine = Attributes.Add();
		//NewLine.AttributeName = "Preferred vendor [ref]";
		
		NewLine = Attributes.Add();
		NewLine.AttributeName = "Category [ref]";
		
		NewLine = Attributes.Add();
		NewLine.AttributeName = "UoM [ref]";	

		NewLine = Attributes.Add();
		NewLine.AttributeName = "CF1String [char(100)]";
		
		NewLine = Attributes.Add();
		NewLine.AttributeName = "CF1Num [num]";
		
		NewLine = Attributes.Add();
		NewLine.AttributeName = "CF2String [char(100)]";
		
		NewLine = Attributes.Add();
		NewLine.AttributeName = "CF2Num [num]";

		NewLine = Attributes.Add();
		NewLine.AttributeName = "CF3String [char(100)]";
		
		NewLine = Attributes.Add();
		NewLine.AttributeName = "CF3Num [num]";
		
		NewLine = Attributes.Add();
		NewLine.AttributeName = "CF4String [char(100)]";
		
		NewLine = Attributes.Add();
		NewLine.AttributeName = "CF4Num [num]";

		NewLine = Attributes.Add();
		NewLine.AttributeName = "CF5String [char(100)]";
		
		NewLine = Attributes.Add();
		NewLine.AttributeName = "CF5Num [num]";
		
	EndIf;
	
EndProcedure // ЗаполнитьAttributes()

&AtServer
Function FillAttributesAtServer(RowCount)
	
	Source = Новый ТаблицаЗначений;
	
	МаксКоличествоКолонок = 0;
	
	Для СчетчикСтрок = 1 По RowCount Цикл
		                                                          
		ТекущаяСтрока = SourceText.ПолучитьСтроку(СчетчикСтрок);
		МассивЗначений = StringFunctionsClientServer.SplitStringIntoSubstringArray(ТекущаяСтрока, ",",,"""");
		КоличествоКолонок = МассивЗначений.Количество();
		
		Если КоличествоКолонок < 1 тогда
			Продолжить;
		КонецЕсли;
		
		Если КоличествоКолонок > МаксКоличествоКолонок Тогда
			Для СчетчикКолонок = МаксКоличествоКолонок + 1 По КоличествоКолонок Цикл
				НоваяКолонка = Source.Колонки.Add();
				НоваяКолонка.Имя = "Column" + СокрЛП(СчетчикКолонок);
				НоваяКолонка.Заголовок = "Column #" + СокрЛП(СчетчикКолонок);
			КонецЦикла;
			МаксКоличествоКолонок = КоличествоКолонок;
		КонецЕсли;
		
		NewLine = Source.Add();
		Для СчетчикКолонок = 0 По КоличествоКолонок - 1 Цикл
			NewLine[СчетчикКолонок] = МассивЗначений[СчетчикКолонок];
		КонецЦикла;
		
	КонецЦикла;
	
	SourceAddress = ПоместитьВоВременноеХранилище(Source, ЭтаФорма.УникальныйИдентификатор);
	
	Возврат SourceAddress;
	
EndFunction


&AtServer
Procedure FillSourceView()

	SourceView.Очистить();
	
	Обработка = РеквизитФормыВЗначение("Object");
	Template = Обработка.ПолучитьМакет("Template");
	ОбластьПустая = Template.ПолучитьОбласть("EmptyArea");
	ОбластьШапка = Template.ПолучитьОбласть("HeaderArea");
	ОбластьЯчейка = Template.ПолучитьОбласть("CellArea");
	
	Source = ПолучитьИзВременногоХранилища(SourceAddress);

	SourceView.Вывести(ОбластьПустая);
	Для каждого КолонкаИсточника Из Source.Колонки Цикл
		ОбластьШапка.Параметры.Text = КолонкаИсточника.Заголовок;
		SourceView.Присоединить(ОбластьШапка);
	КонецЦикла;
	
	КоличествоКолонок = Source.Колонки.Количество();
	Для каждого СтрокаИсточника Из Source Цикл
		SourceView.Вывести(ОбластьПустая);
		Для СчетчикКолонок = 0 По КоличествоКолонок -1  Цикл
			ОбластьЯчейка.Параметры.Text = СтрокаИсточника[СчетчикКолонок];
			SourceView.Присоединить(ОбластьЯчейка);
		КонецЦикла;
	КонецЦикла;
	
	Items.AttributesColumnNumber.МаксимальноеЗначение = Source.Колонки.Количество();
	
EndProcedure

&AtServer
Procedure FillLoadTable()
	
	//If ActionType = "Items" Then
	//	
	//	//ItemDataSet = New Array();
	//	//For Each DataLine In Object.DataList Do
	//	//	ItemLine = New Structure("ProductType, ProductCode, ProductDescription, ProductIncomeAcct, ProductInvOrExpenseAcct, ProductCOGSAcct, ProductPreferredVendor, ProductCategory, ProductUoM, ProductPrice, ProductQty, ProductValue, ProductCF1String, ProductCF1Num, ProductCF2String, ProductCF2Num, ProductCF3String, ProductCF3Num, ProductCF4String, ProductCF4Num, ProductCF5String, ProductCF5Num");
	//	//	FillPropertyValues(ItemLine, DataLine);
	//	//	ItemDataSet.Add(ItemLine);
	//	//EndDo;	
	//	
	//	Params = New Array();
	//	Params.Add(Date);
	//	Params.Add(Date2);
	//	Params.Add(Реквизиты);
	//	Params.Add(SourceAddress);
	//	LongActions.ExecuteInBackground("GeneralFunctions.CreateItemCSV", Params);		
	//	
	//	Return;	
	//EndIf;
	
	Object.DataList.Очистить();
	ТаблицаЗагрузки = Object.DataList.Выгрузить();
	
	Source = ПолучитьИзВременногоХранилища(SourceAddress);
		
	Для СчетчикСтрок = 0 по Source.Количество() - 1 Цикл
				
		Если ActionType = "Chart of accounts" Then
			
			NewLine = ТаблицаЗагрузки.Add();
			NewLine.LoadFlag = True;
					
			ColumnNumber = FindAttributeColumnNumber("Code [char(10)]");
			Если ColumnNumber <> Undefined Тогда
				NewLine.CofACode = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);
			КонецЕсли;

			ColumnNumber = FindAttributeColumnNumber("Description [char(100)]");
			Если ColumnNumber <> Undefined Тогда
				NewLine.CofADescription = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);
			КонецЕсли;
			
			ColumnNumber = FindAttributeColumnNumber("Subaccount of [char(10)]");
			Если ColumnNumber <> Undefined Тогда
				SubaccountCode = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);
				NewLine.CofASubaccountOf = ChartsOfAccounts.ChartOfAccounts.FindByCode(SubaccountCode);
			КонецЕсли;
			
			ColumnNumber = FindAttributeColumnNumber("Type [ref]");
			Если ColumnNumber <> Undefined Тогда
				
				AccountTypeString = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);

				// intelligent error message if not found
				
				If AccountTypeString = "Accounts payable" Then
					AccountTypeValue = Enums.AccountTypes.AccountsPayable;
				ElsIf AccountTypeString = "Accounts receivable" Then
					AccountTypeValue = Enums.AccountTypes.AccountsReceivable
				ElsIf AccountTypeString = "Accumulated depreciation" Then
					AccountTypeValue = Enums.AccountTypes.AccumulatedDepreciation					
				ElsIf AccountTypeString = "Bank" Then
					AccountTypeValue = Enums.AccountTypes.Bank					
				ElsIf AccountTypeString = "Cost of sales" Then
					AccountTypeValue = Enums.AccountTypes.CostOfSales
				ElsIf AccountTypeString = "Equity" Then
					AccountTypeValue = Enums.AccountTypes.Equity				
				ElsIf AccountTypeString = "Expense" Then
					AccountTypeValue = Enums.AccountTypes.Expense
				ElsIf AccountTypeString = "Fixed asset" Then
					AccountTypeValue = Enums.AccountTypes.FixedAsset					
				ElsIf AccountTypeString = "Income" Then
					AccountTypeValue = Enums.AccountTypes.Income
				ElsIf AccountTypeString = "Inventory" Then
					AccountTypeValue = Enums.AccountTypes.Inventory					
				ElsIf AccountTypeString = "Long term liability" Then
					AccountTypeValue = Enums.AccountTypes.LongTermLiability					
				ElsIf AccountTypeString = "Other current asset" Then
					AccountTypeValue = Enums.AccountTypes.OtherCurrentAsset					
				ElsIf AccountTypeString = "Other current liability" Then
					AccountTypeValue = Enums.AccountTypes.OtherCurrentLiability
				ElsIf AccountTypeString = "Other expense" Then
					AccountTypeValue = Enums.AccountTypes.OtherExpense					
				ElsIf AccountTypeString = "Other income" Then
					AccountTypeValue = Enums.AccountTypes.OtherIncome					
				ElsIf AccountTypeString = "Other noncurrent asset" Then
					AccountTypeValue = Enums.AccountTypes.OtherNonCurrentAsset
				EndIf;

				NewLine.CofAType = AccountTypeValue;
				
			КонецЕсли;

			ColumnNumber = FindAttributeColumnNumber("Update [ref]");
			Если ColumnNumber <> Undefined Тогда
				AccountCode = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);
				NewLine.CofAUpdate = ChartsOfAccounts.ChartOfAccounts.FindByCode(AccountCode);
			КонецЕсли;
			
		ElsIf ActionType = "Classes" Then
			
			NewLine = ТаблицаЗагрузки.Add();
			NewLine.LoadFlag = True;
			
			ColumnNumber = FindAttributeColumnNumber("Name [char(25)]");
			Если ColumnNumber <> Undefined Тогда
				test = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);
				NewLine.ClassName = test; // СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);
			КонецЕсли;
			
			ColumnNumber = FindAttributeColumnNumber("Subclass of [ref]");
			Если ColumnNumber <> Undefined Тогда
				ParentClassName = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);
				NewLine.SubClassOf = Catalogs.Classes.FindByDescription(ParentClassName);
			КонецЕсли;		
									
		ElsIf ActionType = "Expensify" Then
			
			NewLine = ТаблицаЗагрузки.Add();
			NewLine.LoadFlag = True;
			
			ColumnNumber = FindAttributeColumnNumber("Category [char(50)]");
			If ColumnNumber <> Undefined Then
				Category = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);
				
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
				NewLine.ExpensifyAmount = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);
			EndIf;

			ColumnNumber = FindAttributeColumnNumber("Memo [char(100)]");
			If ColumnNumber <> Undefined Then
				NewLine.ExpensifyMemo = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);
			EndIf;							
			
		ElsIf ActionType = "Journal entries" Then
		
			NewLine = ТаблицаЗагрузки.Add();
			NewLine.LoadFlag = True;
			
			ColumnNumber = FindAttributeColumnNumber("Date [date]");
			Если ColumnNumber <> Undefined Тогда
				CheckDateString = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);
				
				TransactionDate = '00010101';
				DateParts = StringFunctionsClientServer.SplitStringIntoSubstringArray(CheckDateString, "/",,"""");
				If DateParts.Count() = 3 then
					Try
						TransactionDate 	= Date(DateParts[2], DateParts[0], DatePArts[1]);
					Except
					EndTry;				
				EndIf;
				
				NewLine.GJHeaderDate = TransactionDate;
			КонецЕсли;
			
			ColumnNumber = FindAttributeColumnNumber("Memo [char]");
			If ColumnNumber <> Undefined Then
				NewLine.GJHeaderMemo = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);
			EndIf;
			
			ColumnNumber = FindAttributeColumnNumber("Row # [num]");
			If ColumnNumber <> Undefined Then
				NewLine.GJHeaderRowNumber = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);
			EndIf;
			
			ColumnNumber = FindAttributeColumnNumber("Debit or Credit");
			If ColumnNumber <> Undefined Then
				NewLine.GJHeaderType = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);
			EndIf;
			
			ColumnNumber = FindAttributeColumnNumber("Line account [ref]");
			Если ColumnNumber <> Undefined Тогда
				AccountString = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);
				AccountByCode = ChartsOfAccounts.ChartOfAccounts.FindByCode(AccountString);
				AccountByDescription = ChartsOfAccounts.ChartOfAccounts.FindByDescription(AccountString);
				If AccountByCode = ChartsOfAccounts.ChartOfAccounts.EmptyRef() Then
					NewLine.GJHeaderAccount = AccountByDescription;
				Else
					NewLine.GJHeaderAccount = AccountByCode;
				EndIf;
			КонецЕсли;
			
			ColumnNumber = FindAttributeColumnNumber("Line amount [num]");
			Если ColumnNumber <> Undefined Тогда
				LineAmount = Number(СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]));
				If LineAmount < 0 Then
					LineAmount = LineAmount * -1
				EndIf;
				NewLine.GJHeaderAmount = LineAmount;
			КонецЕсли;	
			
			ColumnNumber = FindAttributeColumnNumber("Line class [ref]");
			Если ColumnNumber <> Undefined Тогда
				LineClassString = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);
				NewLine.GJHeaderClass = Catalogs.Classes.FindByDescription(LineClassString);
			КонецЕсли;
			
			ColumnNumber = FindAttributeColumnNumber("Line memo [char]");
			Если ColumnNumber <> Undefined Тогда
				NewLine.GJHeaderLineMemo = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);
			КонецЕсли;
										
		ElsIf ActionType = "Checks" Then
			
			NewLine = ТаблицаЗагрузки.Add();
			NewLine.LoadFlag = True;

			ColumnNumber = FindAttributeColumnNumber("Date [char]");
			Если ColumnNumber <> Undefined Тогда
				CheckDateString = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);
				
				TransactionDate = '00010101';
				DateParts = StringFunctionsClientServer.SplitStringIntoSubstringArray(CheckDateString, "/",,"""");
				If DateParts.Count() = 3 then
					Try
						TransactionDate 	= Date(DateParts[2], DateParts[0], DatePArts[1]);
					Except
					EndTry;				
				EndIf;
				
				NewLine.CheckDate = TransactionDate;
			КонецЕсли;

			ColumnNumber = FindAttributeColumnNumber("Number [char(6)]");
			Если ColumnNumber <> Undefined Тогда
				NewLine.CheckNumber = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);
			КонецЕсли;

			ColumnNumber = FindAttributeColumnNumber("Bank account [ref]");
			Если ColumnNumber <> Undefined Тогда
				BankAccountString = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);
				AccountByCode = ChartsOfAccounts.ChartOfAccounts.FindByCode(BankAccountString);
				AccountByDescription = ChartsOfAccounts.ChartOfAccounts.FindByDescription(BankAccountString);
				If AccountByCode = ChartsOfAccounts.ChartOfAccounts.EmptyRef() Then
					NewLine.CheckBankAccount = AccountByDescription;
				Else
					NewLine.CheckBankAccount = AccountByCode;
				EndIf;
			КонецЕсли;

			ColumnNumber = FindAttributeColumnNumber("Vendor [ref]");
			Если ColumnNumber <> Undefined Тогда
				VendorString = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);
				VendorByCode = Catalogs.Companies.FindByCode(VendorString);
				VendorByDescription = Catalogs.Companies.FindByDescription(VendorString);
				If VendorByCode = Catalogs.Companies.EmptyRef() Then
					NewLine.CheckVendor = VendorByDescription;
				Else
					NewLine.CheckVendor = VendorByCode;
				EndIf;
			КонецЕсли;
			
			ColumnNumber = FindAttributeColumnNumber("Check memo [char]");
			Если ColumnNumber <> Undefined Тогда
				NewLine.CheckMemo = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);
			КонецЕсли;
			
			ColumnNumber = FindAttributeColumnNumber("Line account [ref]");
			Если ColumnNumber <> Undefined Тогда
				LineAccountString = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);
				AccountByCode = ChartsOfAccounts.ChartOfAccounts.FindByCode(LineAccountString);
				AccountByDescription = ChartsOfAccounts.ChartOfAccounts.FindByDescription(LineAccountString);
				If AccountByCode = ChartsOfAccounts.ChartOfAccounts.EmptyRef() Then				
					NewLine.CheckLineAccount = AccountByDescription;
				Else
					NewLine.CheckLineAccount = AccountByCode;
				EndIf;
			КонецЕсли;

			ColumnNumber = FindAttributeColumnNumber("Line memo [char]");
			Если ColumnNumber <> Undefined Тогда
				NewLine.CheckLineMemo = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);
			КонецЕсли;

			ColumnNumber = FindAttributeColumnNumber("Line amount [num]");
			Если ColumnNumber <> Undefined Тогда
				NewLine.CheckLineAmount = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);
			КонецЕсли;
			
			ColumnNumber = FindAttributeColumnNumber("Line class [ref]");
			Если ColumnNumber <> Undefined Тогда
				LineClassString = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);
				NewLine.CheckLineClass = Catalogs.Classes.FindByDescription(LineClassString);
			КонецЕсли;

			
		ElsIf ActionType = "Deposits" Then
			
			NewLine = ТаблицаЗагрузки.Add();
			NewLine.LoadFlag = True;

			ColumnNumber = FindAttributeColumnNumber("Date [char]");
			Если ColumnNumber <> Undefined Тогда
				CheckDateString = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);
				
				TransactionDate = '00010101';
				DateParts = StringFunctionsClientServer.SplitStringIntoSubstringArray(CheckDateString, "/",,"""");
				If DateParts.Count() = 3 then
					Try
						TransactionDate 	= Date(DateParts[2], DateParts[0], DatePArts[1]);
					Except
					EndTry;				
				EndIf;
				
				NewLine.DepositDate = TransactionDate;
			КонецЕсли;

			ColumnNumber = FindAttributeColumnNumber("Bank account [ref]");
			Если ColumnNumber <> Undefined Тогда
				BankAccountString = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);
				AccountByCode = ChartsOfAccounts.ChartOfAccounts.FindByCode(BankAccountString);
				AccountByDescription = ChartsOfAccounts.ChartOfAccounts.FindByDescription(BankAccountString);
				If AccountByCode = ChartsOfAccounts.ChartOfAccounts.EmptyRef() Then
					NewLine.DepositBankAccount = AccountByDescription;
				Else
					NewLine.DepositBankAccount = AccountByCode;
				EndIf;
			КонецЕсли;
			

			ColumnNumber = FindAttributeColumnNumber("Deposit memo [char]");
			Если ColumnNumber <> Undefined Тогда
				NewLine.DepositMemo = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);
			КонецЕсли;
		
			ColumnNumber = FindAttributeColumnNumber("Line company [ref]");
			Если ColumnNumber <> Undefined Тогда
				CompanyString = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);
				NewLine.DepositLineCompany = Catalogs.Companies.FindByDescription(CompanyString);
			КонецЕсли;
					
			ColumnNumber = FindAttributeColumnNumber("Line account [ref]");
			Если ColumnNumber <> Undefined Тогда
				LineAccountString = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);
				AccountByCode = ChartsOfAccounts.ChartOfAccounts.FindByCode(LineAccountString);
				AccountByDescription = ChartsOfAccounts.ChartOfAccounts.FindByDescription(LineAccountString);
				If AccountByCode = ChartsOfAccounts.ChartOfAccounts.EmptyRef() Then
					NewLine.DepositLineAccount = AccountByDescription;
				Else
					NewLine.DepositLineAccount = AccountByCode;
				EndIf;
			КонецЕсли;

			ColumnNumber = FindAttributeColumnNumber("Line amount [num]");
			Если ColumnNumber <> Undefined Тогда
				NewLine.DepositLineAmount = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);
			КонецЕсли;
			
			ColumnNumber = FindAttributeColumnNumber("Line class [ref]");
			Если ColumnNumber <> Undefined Тогда
				LineClassString = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);
				NewLine.DepositLineClass = Catalogs.Classes.FindByDescription(LineClassString);
			КонецЕсли;

			
			ColumnNumber = FindAttributeColumnNumber("Line memo [char]");
			Если ColumnNumber <> Undefined Тогда
				NewLine.DepositLineMemo = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);
			КонецЕсли;
			
		ElsIf ActionType = "CustomersVendors" Then
			
			NewLine = ТаблицаЗагрузки.Add();
			NewLine.LoadFlag = True;
			
			ColumnNumber = FindAttributeColumnNumber("Type [0 - Customer, 1 - Vendor, 2 - Both]");
			Если ColumnNumber <> Undefined Тогда
				CustomerTypeValue = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);
				Try
					CustomerTypeValue = Number(CustomerTypeValue);
				
					If CustomerTypeValue = 0 OR
						CustomerTypeValue = 1 OR
						CustomerTypeValue = 2 Then
							NewLine.CustomerType = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);
					Else
						NewLine.CustomerType = 0;
					EndIf;
	
				Except
					NewLine.CustomerType = 0;
				EndTry;
			КонецЕсли;

			ColumnNumber = FindAttributeColumnNumber("Company code [char(5)]");
			Если ColumnNumber <> Undefined Тогда
				NewLine.CustomerCode = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);
			КонецЕсли;
			
			ColumnNumber = FindAttributeColumnNumber("Company name [char(150)]");
			Если ColumnNumber <> Undefined Тогда
				NewLine.CustomerDescription = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);
			КонецЕсли;
			
			ColumnNumber = FindAttributeColumnNumber("Full name [char(150)]");
			Если ColumnNumber <> Undefined Тогда
				NewLine.CustomerFullName = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);
			КонецЕсли;
			
			ColumnNumber = FindAttributeColumnNumber("Default billing address [T - true, F - false]");
			Если ColumnNumber <> Undefined Тогда
				If СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]) = "T" Then
					NewLine.DefaultBillingAddress = True;
				Else
					NewLine.DefaultBillingAddress = False;
				EndIf
			КонецЕсли;
			
			ColumnNumber = FindAttributeColumnNumber("Default shipping address [T - true, F - false]");
			Если ColumnNumber <> Undefined Тогда
				If СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]) = "T" Then
					NewLine.DefaultShippingAddress = True;
				Else
					NewLine.DefaultShippingAddress = False;
				EndIf
			КонецЕсли;
			
			ColumnNumber = FindAttributeColumnNumber("Income account [ref]");
			If ColumnNumber <> Undefined Then
				TrxAccount = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);
				NewLine.CustomerIncomeAccount = ChartsOfAccounts.ChartOfAccounts.FindByCode(TrxAccount);
			EndIf;
			
			ColumnNumber = FindAttributeColumnNumber("Expense account [ref]");
			If ColumnNumber <> Undefined Then
				TrxAccount = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);
				NewLine.CustomerExpenseAccount = ChartsOfAccounts.ChartOfAccounts.FindByCode(TrxAccount);
			EndIf;

			ColumnNumber = FindAttributeColumnNumber("1099 vendor [T - true, F - false]");
			Если ColumnNumber <> Undefined Тогда
				If СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]) = "T" Then
					NewLine.CustomerVendor1099 = True;
				EndIf
			КонецЕсли;
			
			ColumnNumber = FindAttributeColumnNumber("EIN or SSN");
			Если ColumnNumber <> Undefined Тогда
				If СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]) = "EIN" Then
					NewLine.CustomerEIN_SSN = Enums.FederalIDType.EIN;
				ElsIf СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]) = "SSN" Then
					NewLine.CustomerEIN_SSN = Enums.FederalIDType.SSN;
				EndIf
			КонецЕсли;
			
			ColumnNumber = FindAttributeColumnNumber("Notes [char]");
			Если ColumnNumber <> Undefined Тогда
				NewLine.CustomerNotes = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);
			КонецЕсли;
			
			ColumnNumber = FindAttributeColumnNumber("Website [char(200)]");
			Если ColumnNumber <> Undefined Тогда
				NewLine.CustomerWebsite = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);
			КонецЕсли;
		
			ColumnNumber = FindAttributeColumnNumber("Terms [ref]");
			Если ColumnNumber <> Undefined Тогда
				TermsString = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);
				If TermsString = "" Then
					NewLine.CustomerTerms = Catalogs.PaymentTerms.Net30;
				Else
					NewLine.CustomerTerms = Catalogs.PaymentTerms.FindByDescription(TermsString);
				EndIf;
			Иначе
				NewLine.CustomerTerms = Catalogs.PaymentTerms.Net30;
			КонецЕсли;
			
			ColumnNumber = FindAttributeColumnNumber("Company CF1 string [char(100)]");
			Если ColumnNumber <> Undefined Тогда
				NewLine.CustomerCF1String = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);
			КонецЕсли;
			
			ColumnNumber = FindAttributeColumnNumber("Company CF1 num [num]");
			Если ColumnNumber <> Undefined Тогда
				NewLine.CustomerCF1Num = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);
			КонецЕсли;
			
			ColumnNumber = FindAttributeColumnNumber("Company CF2 string [char(100)]");
			Если ColumnNumber <> Undefined Тогда
				NewLine.CustomerCF2String = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);
			КонецЕсли;
			
			ColumnNumber = FindAttributeColumnNumber("Company CF2 num [num]");
			Если ColumnNumber <> Undefined Тогда
				NewLine.CustomerCF2Num = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);
			КонецЕсли;

			ColumnNumber = FindAttributeColumnNumber("Company CF3 string [char(100)]");
			Если ColumnNumber <> Undefined Тогда
				NewLine.CustomerCF3String = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);
			КонецЕсли;
			
			ColumnNumber = FindAttributeColumnNumber("Company CF3 num [num]");
			Если ColumnNumber <> Undefined Тогда
				NewLine.CustomerCF3Num = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);
			КонецЕсли;

			ColumnNumber = FindAttributeColumnNumber("Company CF4 string [char(100)]");
			Если ColumnNumber <> Undefined Тогда
				NewLine.CustomerCF4String = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);
			КонецЕсли;
			
			ColumnNumber = FindAttributeColumnNumber("Company CF4 num [num]");
			Если ColumnNumber <> Undefined Тогда
				NewLine.CustomerCF4Num = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);
			КонецЕсли;
			
			ColumnNumber = FindAttributeColumnNumber("Company CF5 string [char(100)]");
			Если ColumnNumber <> Undefined Тогда
				NewLine.CustomerCF5String = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);
			КонецЕсли;
			
			ColumnNumber = FindAttributeColumnNumber("Company CF5 num [num]");
			Если ColumnNumber <> Undefined Тогда
				NewLine.CustomerCF5Num = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);
			КонецЕсли;
			
			ColumnNumber = FindAttributeColumnNumber("Vendor tax ID [char(15)]");
			Если ColumnNumber <> Undefined Тогда
				NewLine.CustomerVendorTaxID = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);
			КонецЕсли;
			
			ColumnNumber = FindAttributeColumnNumber("Customer sales person [ref]");
			Если ColumnNumber <> Undefined Тогда
				RepString = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);
				If RepString = "" Then
				Else
					NewLine.CustomerSalesPerson = Catalogs.SalesPeople.FindByDescription(RepString);
				EndIf;
			КонецЕсли;
						
			ColumnNumber = FindAttributeColumnNumber("Customer price level [ref]");
			Если ColumnNumber <> Undefined Тогда
				PriceL = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);
				If PriceL = "" Then
				Else
					NewLine.CustomerPriceLevel = Catalogs.PriceLevels.FindByDescription(PriceL);
				EndIf;
			КонецЕсли;

			// billing address
			
			ColumnNumber = FindAttributeColumnNumber("Address ID [char(25)]");
			Если ColumnNumber <> Undefined Тогда
				NewLine.CustomerAddressID = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);
			КонецЕсли;

			ColumnNumber = FindAttributeColumnNumber("Salutation [char(15)]");
			Если ColumnNumber <> Undefined Тогда
				NewLine.AddressSalutation = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);
			КонецЕсли;
		
			ColumnNumber = FindAttributeColumnNumber("First name [char(200)]");
			Если ColumnNumber <> Undefined Тогда
				NewLine.CustomerFirstName = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);
			КонецЕсли;

			ColumnNumber = FindAttributeColumnNumber("Middle name [char(200)]");
			Если ColumnNumber <> Undefined Тогда
				NewLine.CustomerMiddleName = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);
			КонецЕсли;

			ColumnNumber = FindAttributeColumnNumber("Last name [char(200)]");
			Если ColumnNumber <> Undefined Тогда
				NewLine.CustomerLastName = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);
			КонецЕсли;

			ColumnNumber = FindAttributeColumnNumber("Suffix [char(10)]");
			Если ColumnNumber <> Undefined Тогда
				NewLine.AddressSuffix = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);
			КонецЕсли;
			
			ColumnNumber = FindAttributeColumnNumber("Job title [char(200)]");
			Если ColumnNumber <> Undefined Тогда
				NewLine.AddressJobTitle = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);
			КонецЕсли;
		
			ColumnNumber = FindAttributeColumnNumber("Phone [char(50)]");
			Если ColumnNumber <> Undefined Тогда
				NewLine.CustomerPhone = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);
			КонецЕсли;
			
			ColumnNumber = FindAttributeColumnNumber("Cell [char(50)]");
			Если ColumnNumber <> Undefined Тогда
				NewLine.CustomerCell = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);
			КонецЕсли;

			ColumnNumber = FindAttributeColumnNumber("Fax [char(50)]");
			Если ColumnNumber <> Undefined Тогда
				NewLine.CustomerFax = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);
			КонецЕсли;

			ColumnNumber = FindAttributeColumnNumber("E-mail [char(100)]");
			Если ColumnNumber <> Undefined Тогда
				NewLine.CustomerEmail = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);
			КонецЕсли;

			ColumnNumber = FindAttributeColumnNumber("Address line 1 [char(250)]");
			Если ColumnNumber <> Undefined Тогда
				NewLine.CustomerAddressLine1 = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);
			КонецЕсли;

			ColumnNumber = FindAttributeColumnNumber("Address line 2 [char(250)]");
			Если ColumnNumber <> Undefined Тогда
				NewLine.CustomerAddressLine2 = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);
			КонецЕсли;
			
			ColumnNumber = FindAttributeColumnNumber("Address line 3 [char(250)]");
			Если ColumnNumber <> Undefined Тогда
				NewLine.CustomerAddressLine3 = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);
			КонецЕсли;

			ColumnNumber = FindAttributeColumnNumber("City [char(100)]");
			Если ColumnNumber <> Undefined Тогда
				NewLine.CustomerCity = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);
			КонецЕсли;

			ColumnNumber = FindAttributeColumnNumber("State [ref]");
			Если ColumnNumber <> Undefined Тогда
				StateString = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);
				If StateString = "" Then
				Else
					NewLine.CustomerState = Catalogs.States.FindByCode(StateString);
				EndIf;
			КонецЕсли;

			ColumnNumber = FindAttributeColumnNumber("Country [ref]");
			Если ColumnNumber <> Undefined Тогда
				CountryString = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);
				If CountryString = "" Then
				Else
					NewLine.CustomerCountry = Catalogs.Countries.FindByCode(CountryString);
				EndIf;	
			КонецЕсли;

			ColumnNumber = FindAttributeColumnNumber("ZIP [char(20)]");
			Если ColumnNumber <> Undefined Тогда
				NewLine.CustomerZIP = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);
			КонецЕсли;
			
			ColumnNumber = FindAttributeColumnNumber("Address notes [char]");
			Если ColumnNumber <> Undefined Тогда
				NewLine.CustomerAddressNotes = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);
			КонецЕсли;
			
			ColumnNumber = FindAttributeColumnNumber("Address CF1 string [char(200)]");
			Если ColumnNumber <> Undefined Тогда
				NewLine.AddressCF1String = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);
			КонецЕсли;
			
			ColumnNumber = FindAttributeColumnNumber("Address CF2 string [char(200)]");
			Если ColumnNumber <> Undefined Тогда
				NewLine.AddressCF2String = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);
			КонецЕсли;

			ColumnNumber = FindAttributeColumnNumber("Address CF3 string [char(200)]");
			Если ColumnNumber <> Undefined Тогда
				NewLine.AddressCF3String = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);
			КонецЕсли;

			ColumnNumber = FindAttributeColumnNumber("Address CF4 string [char(200)]");
			Если ColumnNumber <> Undefined Тогда
				NewLine.AddressCF4String = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);
			КонецЕсли;

			ColumnNumber = FindAttributeColumnNumber("Address CF5 string [char(200)]");
			Если ColumnNumber <> Undefined Тогда
				NewLine.AddressCF5String = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);
			КонецЕсли;
			
			ColumnNumber = FindAttributeColumnNumber("Address sales person [ref]");
			Если ColumnNumber <> Undefined Тогда
				RepString = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);
				If RepString = "" Then
				Else
					NewLine.AddressSalesPerson = Catalogs.SalesPeople.FindByDescription(RepString);
				EndIf;
			КонецЕсли;
						
		// end shipping address
						
		ElsIf ActionType = "Items" Then
			
			NewLine = ТаблицаЗагрузки.Add();
			NewLine.LoadFlag = True;
			
			ColumnNumber = FindAttributeColumnNumber("Product OR Service");
			Если ColumnNumber <> Undefined Тогда
				TypeString = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);
				If TypeString = "Product" Then
					NewLine.ProductType = Enums.InventoryTypes.Inventory;
				ElsIf TypeString = "Service" Then
					NewLine.ProductType = Enums.InventoryTypes.NonInventory;
				EndIf;
			КонецЕсли;
			
			ColumnNumber = FindAttributeColumnNumber("Item code [char(50)]");
			Если ColumnNumber <> Undefined Тогда
				NewLine.ProductCode = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);
			КонецЕсли;

			ColumnNumber = FindAttributeColumnNumber("Item description [char(150)]");
			Если ColumnNumber <> Undefined Тогда
				NewLine.ProductDescription = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);
			КонецЕсли;

			ColumnNumber = FindAttributeColumnNumber("Income account [ref]");
			Если ColumnNumber <> Undefined Тогда
				IncomeAcctString = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);
				If IncomeAcctString <> "" Then
					NewLine.ProductIncomeAcct = ChartsOfAccounts.ChartOfAccounts.FindByCode(IncomeAcctString);
				Else
					NewLine.ProductIncomeAcct = Constants.IncomeAccount.Get();
				EndIf;
			Иначе
				NewLine.ProductIncomeAcct = Constants.IncomeAccount.Get();
			КонецЕсли;	
			
			ColumnNumber = FindAttributeColumnNumber("Inventory or expense account [ref]");
			Если ColumnNumber <> Undefined Тогда
				InvAcctString = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);
				If InvAcctString <> "" Then
					NewLine.ProductInvOrExpenseAcct = ChartsOfAccounts.ChartOfAccounts.FindByCode(InvAcctString);
				ElsIf TypeString = "Product" Then
					NewLine.ProductInvOrExpenseAcct = GeneralFunctions.InventoryAcct(Enums.InventoryTypes.Inventory);	
				ElsIf TypeString = "Service" Then
					NewLine.ProductInvOrExpenseAcct = GeneralFunctions.InventoryAcct(Enums.InventoryTypes.NonInventory);
				EndIf;
			Иначе
				If TypeString = "Product" Then
					NewLine.ProductInvOrExpenseAcct = GeneralFunctions.InventoryAcct(Enums.InventoryTypes.Inventory);	
				ElsIf TypeString = "Service" Then
					NewLine.ProductInvOrExpenseAcct = GeneralFunctions.InventoryAcct(Enums.InventoryTypes.NonInventory);
				EndIf;
			КонецЕсли;

			ColumnNumber = FindAttributeColumnNumber("COGS account [ref]");
			Если ColumnNumber <> Undefined Тогда
				COGSAcctString = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);
				If COGSAcctString <> "" Then
					NewLine.ProductCOGSAcct = ChartsOfAccounts.ChartOfAccounts.FindByCode(COGSAcctString);
				ElsIf TypeString = "Product" Then
					NewLine.ProductCOGSAcct = GeneralFunctions.GetDefaultCOGSAcct();
				ElsIf TypeString = "Service" Then
					NewLine.ProductCOGSAcct = GeneralFunctions.GetEmptyAcct();	
				EndIf;
			Иначе
				If TypeString = "Product" Then
					NewLine.ProductCOGSAcct = GeneralFunctions.GetDefaultCOGSAcct();
				ElsIf TypeString = "Service" Then
					NewLine.ProductCOGSAcct = GeneralFunctions.GetEmptyAcct();	
				EndIf;

			КонецЕсли;

			ColumnNumber = FindAttributeColumnNumber("Price [num]");
			Если ColumnNumber <> Undefined Тогда
				PriceString = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);
				If PriceString <> "" Then
					NewLine.ProductPrice = PriceString;
				EndIf;
			КонецЕсли;
			
			ColumnNumber = FindAttributeColumnNumber("Qty [num]");
			Если ColumnNumber <> Undefined Тогда
				NewLine.ProductQty = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);	
			КонецЕсли;
			
			ColumnNumber = FindAttributeColumnNumber("Value [num]");
			Если ColumnNumber <> Undefined Тогда
				NewLine.ProductValue = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);	
			КонецЕсли;

			//НомерКолонки = FindAttributeColumnNumber("Preferred vendor [ref]");
			//Если НомерКолонки <> Undefined Тогда
			//	VendorString = СокрЛП(Source[СчетчикСтрок][НомерКолонки - 1]);
			//	If VendorString <> "" Then
			//		NewLine.ProductPreferredVendor = Catalogs.Companies.FindByDescription(VendorString);
			//	EndIf;
			//КонецЕсли;

			ColumnNumber = FindAttributeColumnNumber("Category [ref]");
			Если ColumnNumber <> Undefined Тогда
				ProductCat = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);
				If ProductCat <> "" Then
					NewLine.ProductCategory = Catalogs.ProductCategories.FindByDescription(ProductCat);
				EndIf;
			КонецЕсли;

			ColumnNumber = FindAttributeColumnNumber("UoM [ref]");
			Если ColumnNumber <> Undefined Тогда
				ProductUM = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);
				If ProductUM <> "" Then
					NewLine.ProductUoM = Catalogs.UM.FindByDescription(ProductUM);
				EndIf;
			КонецЕсли;

			ColumnNumber = FindAttributeColumnNumber("CF1String [char(100)]");
			Если ColumnNumber <> Undefined Тогда
				NewLine.ProductCF1String = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);	
			КонецЕсли;
			
			ColumnNumber = FindAttributeColumnNumber("CF1Num [num]");
			Если ColumnNumber <> Undefined Тогда
				NewLine.ProductCF1Num = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);	
			КонецЕсли;

			ColumnNumber = FindAttributeColumnNumber("CF2String [char(100)]");
			Если ColumnNumber <> Undefined Тогда
				NewLine.ProductCF2String = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);	
			КонецЕсли;
			
			ColumnNumber = FindAttributeColumnNumber("CF2Num [num]");
			Если ColumnNumber <> Undefined Тогда
				NewLine.ProductCF2Num = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);	
			КонецЕсли;

			ColumnNumber = FindAttributeColumnNumber("CF3String [char(100)]");
			Если ColumnNumber <> Undefined Тогда
				NewLine.ProductCF3String = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);	
			КонецЕсли;
			
			ColumnNumber = FindAttributeColumnNumber("CF3Num [num]");
			Если ColumnNumber <> Undefined Тогда
				NewLine.ProductCF3Num = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);	
			КонецЕсли;
			
			ColumnNumber = FindAttributeColumnNumber("CF4String [char(100)]");
			Если ColumnNumber <> Undefined Тогда
				NewLine.ProductCF4String = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);	
			КонецЕсли;
			
			ColumnNumber = FindAttributeColumnNumber("CF4Num [num]");
			Если ColumnNumber <> Undefined Тогда
				NewLine.ProductCF4Num = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);	
			КонецЕсли;
			
			ColumnNumber = FindAttributeColumnNumber("CF5String [char(100)]");
			Если ColumnNumber <> Undefined Тогда
				NewLine.ProductCF5String = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);	
			КонецЕсли;
			
			ColumnNumber = FindAttributeColumnNumber("CF5Num [num]");
			Если ColumnNumber <> Undefined Тогда
				NewLine.ProductCF5Num = СокрЛП(Source[СчетчикСтрок][ColumnNumber - 1]);	
			КонецЕсли;
			
		EndIf;
				
	КонецЦикла;
		
	Object.DataList.Load(ТаблицаЗагрузки);
	
EndProcedure

&AtServer
Function FindAttributeColumnNumber(AttributeName)
	
	НайденныйРеквизит = Undefined;
	НайденныеСтроки = Attributes.НайтиСтроки(Новый Структура("AttributeName", AttributeName));
	Если НайденныеСтроки.Количество() > 0 Тогда
		НайденныйРеквизит = НайденныеСтроки[0].ColumnNumber;
	КонецЕсли;
	
	Возврат ?(НайденныйРеквизит = 0, Undefined, НайденныйРеквизит);
	
EndFunction


&AtServer
Procedure LoadData(Cancel)
	
	Если Object.DataList.Количество() = 0 Тогда
		Возврат;
	КонецЕсли;
		
	Если Cancel Тогда
		Возврат;
	КонецЕсли;
		
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
		
		//NewPI.CompanyCode = ExpensifyVendor.Code;
		NewPI.Currency = GeneralFunctionsReusable.DefaultCurrency();
		NewPI.ExchangeRate = 1;
		NewPI.LocationActual = Catalogs.Locations.MainWarehouse;
		NewPI.Date = Date;
		NewPI.DueDate = Date;
		NewPI.Terms = Catalogs.PaymentTerms.DueOnReceipt;
		//NewPI.Memo = Dataline.PIHeaderMemo;
		NewPI.APAccount = NewPI.Currency.DefaultAPAccount;
		NewPI.Number = ExpensifyInvoiceNumber;
		
		Для каждого DataLine Из Object.DataList Цикл
			
			If DataLine.LoadFlag = True Then
			
				NewLine = NewPI.Accounts.Add();
				
				NewLine.Account = DataLine.ExpensifyAccount;
				//NewLine.AccountDescription = DataLine.ExpensifyAccount.Description;
				NewLine.Amount = DataLine.ExpensifyAmount;
				NewLine.Memo = DataLine.ExpensifyMemo;
				
				TotalAmount = TotalAmount + NewLine.Amount;
				
			Else
			EndIf;
			
		КонецЦикла;
		
		NewPI.DocumentTotal = TotalAmount;
		NewPI.DocumentTotalRC = TotalAmount;
				
		NewPI.Write();
			
	EndIf;
	
	If ActionType = "Items" Then
		
		ItemDataSet = New Array();
		For Each DataLine In Object.DataList Do
			
			If DataLine.LoadFlag Then
				ItemLine = New Structure("ProductType, ProductCode, ProductDescription, ProductIncomeAcct, ProductInvOrExpenseAcct, ProductCOGSAcct, ProductCategory, ProductUoM, ProductPrice, ProductQty, ProductValue, ProductCF1String, ProductCF1Num, ProductCF2String, ProductCF2Num, ProductCF3String, ProductCF3Num, ProductCF4String, ProductCF4Num, ProductCF5String, ProductCF5Num");
				FillPropertyValues(ItemLine, DataLine);
				ItemDataSet.Add(ItemLine);
			EndIf;
			
		EndDo;	
		
		Params = New Array();
		Params.Add(Date);
		Params.Add(Date2);
		Params.Add(ItemDataSet);
		LongActions.ExecuteInBackground("GeneralFunctions.CreateItemCSV", Params);
		
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
				"CustomerVendorTaxID, CustomerCF1String, CustomerCF1Num, " +
				"CustomerCF2String, CustomerCF2Num, CustomerCF3String, CustomerCF3Num, CustomerCF4String, " +
				"CustomerCF4Num, CustomerCF5String, CustomerCF5Num, AddressSalutation, AddressSuffix, " +
				"AddressCF1String, AddressCF2String, AddressCF3String, AddressCF4String, AddressCF5String, " +
				"AddressJobTitle, AddressSalesPerson, CustomerSalesPerson, CustomerWebsite, CustomerPriceLevel, " +
				"DefaultBillingAddress, DefaultShippingAddress");
				FillPropertyValues(ItemLine, DataLine);
				ItemDataSet.Add(ItemLine);
			Else
			EndIf;
		EndDo;
				
		Params = New Array();
		//Params.Add(IncomeAccount);
		//Params.Add(ExpenseAccount);
		//Params.Add(ARAccount);
		//Params.Add(APAccount);
		Params.Add(ItemDataSet);
		LongActions.ExecuteInBackground("GeneralFunctions.CreateCustomerVendorCSV", Params);
		//CreateCustomerVendorCSV(ItemDataSet);
		
	EndIf;
	
	If ActionType = "Checks" Then
		
		ItemDataSet = New Array();
		For Each DataLine In Object.DataList Do
			If DataLine.LoadFlag = True Then
				ItemLine = New Structure("CheckDate, CheckNumber, CheckBankAccount, CheckMemo, CheckVendor, CheckLineAmount, " + 
				"CheckLineAccount, CheckLineAmount, CheckLineMemo, CheckLineClass");
				FillPropertyValues(ItemLine, DataLine);
				ItemDataSet.Add(ItemLine);
			Else
			EndIf;
		EndDo;

		Params = New Array();
		Params.Add(ItemDataSet);
		//LongActions.ExecuteInBackground("GeneralFunctions.CreateCheckCSV", Params);
		CreateCheckCSV(ItemDataSet);
		
	EndIf;

	If ActionType = "Deposits" Then
		
		ItemDataSet = New Array();
		For Each DataLine In Object.DataList Do
			If DataLine.LoadFlag = True Then
				ItemLine = New Structure("DepositDate, DepositBankAccount, DepositMemo, " + 
				"DepositLineCompany, DepositLineAccount, DepositLineAmount, DepositLineClass, DepositLineMemo");
				FillPropertyValues(ItemLine, DataLine);
				ItemDataSet.Add(ItemLine);
			Else
			EndIf;
		EndDo;

		Params = New Array();
		Params.Add(ItemDataSet);
		//LongActions.ExecuteInBackground("GeneralFunctions.CreateCheckCSV", Params);
		CreateDepositCSV(ItemDataSet);
		
	EndIf;

	
	
	//GJEntryPreviousRow = 0;
	GJFirstRow = True;
	Для каждого DataLine Из Object.DataList Цикл
		
		Если НЕ DataLine.LoadFlag Тогда
			Продолжить;
		КонецЕсли;
		
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
				//NewAccount.Memo = AccountMemo;
				NewAccount.CashFlowSection = Enums.CashFlowSections.Operating;
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
				UAO.Write();
				
			EndIf;
			
		ElsIf ActionType = "Classes" Then
			
			NewClass = Catalogs.Classes.CreateItem();
			NewClass.Description = DataLine.ClassName;
			If DataLine.SubClassOf <> Catalogs.Classes.EmptyRef() Then
				NewClass.Parent = DataLine.SubClassOf;
			EndIf;
			NewClass.Write();
							
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
	
	КонецЦикла;
	
	If GJFirstRow = False Then
		
		DocTotal = NewGJ.LineItems.Total("AmountDr");
		NewGJ.DocumentTotalRC = DocTotal;
		NewGJ.DocumentTotal = DocTotal;
		NewGJ.Currency = GeneralFunctionsReusable.DefaultCurrency();
		NewGJ.ExchangeRate = 1;
		NewGJ.Write();

	EndIf;

	
	Если Cancel Тогда
		Сообщить("There were errors during importing. The import will not be performed.");
		Возврат;
	КонецЕсли;
	
	//Если ВидОперации = "Остатки" Тогда
	//	ДокументВводОстатков.Записать(РежимЗаписиДокумента.Проведение);
	//КонецЕсли;
	
	
EndProcedure

&AtClient
Procedure ActionTypeOnChange(Item)
	
	FillAttributes();
	
EndProcedure


&AtClient
Procedure MappingBack(Command)
	
	Items.LoadSteps.ТекущаяСтраница = Items.LoadSteps.ПодчиненныеЭлементы.Greeting;
	
EndProcedure

&AtClient
Procedure MappingNext(Command)
	
	CheckExpensifyVendor();
	
	Для СчетчикРеквизитов = 0 по Attributes.Количество() - 1 Цикл
		Если Attributes[СчетчикРеквизитов].Required и Attributes[СчетчикРеквизитов].ColumnNumber = 0 Тогда
			Сообщение = Новый СообщениеПользователю;
			Сообщение.Текст = "Please fill out the columns for required attributes";
			Сообщение.Поле = "Attributes[0].ColumnNumber";
			Сообщение.Сообщить(); 
			Возврат;
		КонецЕсли; 
	КонецЦикла;
	
	FillLoadTable();
	Items.LoadSteps.ТекущаяСтраница = Items.LoadSteps.ПодчиненныеЭлементы.Creation;
	
EndProcedure

&AtServer
Procedure CheckExpensifyVendor()
			
	If ActionType = "Expensify" Then
		If ExpensifyVendor = Catalogs.Companies.EmptyRef() Then
			Message = New UserMessage;
			Message.Text = "Please select a Vendor";
			//Message.Field = "ExpensifyVendor";
			Message.Message();
			Return;
		EndIf;
	EndIf;

EndProcedure

&AtClient
Procedure SelectAll(Command)
	
	Для каждого Элемент Из Object.DataList Цикл
		Элемент.LoadFlag = True;
	КонецЦикла; 
	
EndProcedure

&AtClient
Procedure UnselectAll(Command)
	
	Для каждого Элемент Из Object.DataList Цикл
		Элемент.LoadFlag = Ложь;
	КонецЦикла;
	
EndProcedure

&AtClient
Procedure CreateBack(Command)
	
	Items.LoadSteps.ТекущаяСтраница = Items.LoadSteps.ПодчиненныеЭлементы.Mapping;
	
EndProcedure

&AtClient
Procedure CreateNext(Command)
	
	Отказ = Ложь;
	ОчиститьСообщения();
	LoadData(Отказ);
	Если НЕ Отказ Тогда
		Items.LoadSteps.ТекущаяСтраница = Items.LoadSteps.ПодчиненныеЭлементы.Finish;
	КонецЕсли;
	
EndProcedure

&AtClient
Procedure RefClick(Элемент)
	
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
		
	EndIf;
	
EndProcedure

&AtClient
Procedure Finish(Command)
	
	ЭтаФорма.Закрыть();
	
EndProcedure


&AtClient
Procedure OnOpen(Cancel)
	
	Если НЕ ПодключитьРасширениеРаботыСФайлами() Тогда
		Items.FilePath.Видимость = Ложь;
		//Items.ПредупреждениеВыгрузка.Видимость = True;
	Иначе
		Items.FilePath.Видимость = True;
		//Items.ПредупреждениеВыгрузка.Видимость = Ложь;
	КонецЕсли;
	
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
		//NewLine.AccountDescription = DataLine.CheckLineAccount.Description;
		NewLine.Amount = DataLine.CheckLineAmount;
		NewLine.Memo = DataLine.CheckLineMemo;
		NewLine.Class = DataLine.CheckLineClass;
		NewCheck.Write();

		
	EndDo;

	
EndProcedure

Procedure CreateDepositCSV(ItemDataSet) Export
		
	For Each DataLine In ItemDataSet Do				
		
		NewDeposit = Documents.Deposit.CreateDocument();
		NewDeposit.Date = DataLine.DepositDate;
		//NewCheck.Number = DataLine.CheckNumber;
		NewDeposit.BankAccount = DataLine.DepositBankAccount;
		NewDeposit.Memo = DataLine.DepositMemo;
		NewDeposit.DocumentTotalRC = DataLine.DepositLineAmount;
		NewDeposit.DocumentTotal = DataLine.DepositLineAmount;
		//NewDeposit.ExchangeRate = 1;
		//NewDeposit.PaymentMethod = Catalogs.PaymentMethods.DebitCard;
		NewLine = NewDeposit.Accounts.Add();
		NewLine.Company = DataLine.DepositLineCompany;
		NewLine.Account = DataLine.DepositLineAccount;
		NewLine.Class = DataLine.DepositLineClass;
		//NewLine.AccountDescription = DataLine.CheckLineAccount.Description;
		NewLine.Amount = DataLine.DepositLineAmount;
		NewLine.Memo = DataLine.DepositLineMemo;
		//NewDeposit.DataExchange.Load = True;
		//Try
			NewDeposit.Write(DocumentWriteMode.Posting);
		//Except
			//NewDeposit.Write();
		//EndTry
		
	EndDo;
	
EndProcedure


