&НаКлиенте
Процедура ПутьКФайлуНачалоВыбора(Элемент, ДанныеВыбора, СтандартнаяОбработка)
	
	ДиалогВыбораФайла = Новый ДиалогВыбораФайла(РежимДиалогаВыбораФайла.Открытие);
	
	ДиалогВыбораФайла.Фильтр                      = НСтр("en='CSV file (*.csv)|*.csv';de='CSV-Datei'");
	ДиалогВыбораФайла.Заголовок                   = Заголовок;
	ДиалогВыбораФайла.ПредварительныйПросмотр     = Ложь;
	ДиалогВыбораФайла.Расширение                  = "csv";
	ДиалогВыбораФайла.ИндексФильтра               = 0;
	ДиалогВыбораФайла.ПолноеИмяФайла              = Элемент.ТекстРедактирования;
	ДиалогВыбораФайла.ПроверятьСуществованиеФайла = Ложь;
	
	Если ДиалогВыбораФайла.Выбрать() Тогда
		ПутьКФайлу = ДиалогВыбораФайла.ПолноеИмяФайла;
	КонецЕсли;
	
КонецПроцедуры

&НаСервере
Процедура ЗаполнитьРеквизиты()

	ThisCofA = ActionType = "Chart of accounts";
	ThisCustomers = ActionType = "CustomersVendors";
	ThisBalances = ActionType = "Account balances";	
	ThisProducts = ActionType = "Items";
	ThisChecks = ActionType = "Checks";
	ThisGJHeaders = ActionType = "GJ entries (header)";
	ThisGJDetails = ActionType = "GJ entries (detail)";
	ThisSIDetails = ActionType = "Sales invoices (detail)";
	ThisSIHeaders = ActionType = "Sales invoices (header)";
	ThisPIHeaders = ActionType = "Purchase invoices (header)";
	ThisPIDetails = ActionType = "Purchase invoices (detail)";
	ThisIPHeaders = ActionType = "Invoice payments / Checks (header)";
	ThisExpensify = ActionType = "Expensify";
		
	Items.ARBegBal.Visible = ThisSIHeaders;
	Items.CreditMemo.Visible = ThisSIHeaders OR ThisSIDetails;
	
	Items.Date.Visible = ThisBalances OR ThisProducts OR ThisExpensify;
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
	
	Items.DataListIPHeaderNumber.Visible = ThisIPHeaders;
	Items.DataListIPHeaderDate.Visible = ThisIPHeaders;
	Items.DataListIPHeaderVendor.Visible = ThisIPHeaders;
	Items.DataListIPHeaderMemo.Visible = ThisIPHeaders;
	Items.DataListIPHeaderAmount.Visible = ThisIPHeaders;
	
	Items.DataListPIDetailHeader.Visible = ThisPIDetails;
	Items.DataListPIDetailAccount.Visible = ThisPIDetails;
	Items.DataListPIDetailAmount.Visible = ThisPIDetails;
	Items.DataListPIDetailMemo.Visible = ThisPIDetails;
	
	Items.DataListPIHeaderNumber.Visible = ThisPIHeaders;
	Items.DataListPIHeaderDate.Visible = ThisPIHeaders;
	Items.DataListPIHeaderVendor.Visible = ThisPIHeaders;
	Items.DataListPIHeaderDueDate.Visible = ThisPIHeaders;
	Items.DataListPIHeaderTerms.Visible = ThisPIHeaders;
	Items.DataListPIHeaderMemo.Visible = ThisPIHeaders;
	Items.DataListPIHeaderAmount.Visible = ThisPIHeaders;
	
	Items.DataListSIDetailHeader.Visible = ThisSIDetails;
	Items.DataListSIDetailPrice.Visible = ThisSIDetails;
	Items.DataListSIDetailProduct.Visible = ThisSIDetails;
	Items.DataListSIDetailQty.Visible = ThisSIDetails;
		
	Items.DataListGJHeaderNumber.Visible = ThisGJHeaders;
	Items.DataListGJHeaderDate.Visible = ThisGJHeaders;
	Items.DataListGJHeaderAmount.Visible = ThisGJHeaders;
	Items.DataListGJHeaderMemo.Visible = ThisGJHeaders;
	Items.DataListGJHeaderARorAP.Visible = ThisGJHeaders;
	
	Items.DataListGJDetailHeader.Visible = ThisGJDetails;
	Items.DataListGJDetailAccount.Visible = ThisGJDetails;
	Items.DataListGJDetailDr.Visible = ThisGJDetails;
	Items.DataListGJDetailCr.Visible = ThisGJDetails;
	Items.DataListGJDetailMemo.Visible = ThisGJDetails;
	Items.DataListGJDetailCompany.Visible = ThisGJDetails; 
	
	Items.DataListSIHeaderDate.Visible = ThisSIHeaders;
	Items.DataListSIHeaderNumber.Visible = ThisSIHeaders;
	Items.DataListSIHeaderPO.Visible = ThisSIHeaders;
	Items.DataListSIHeaderCustomer.Visible = ThisSIHeaders;
	Items.DataListSIHeaderTerms.Visible = ThisSIHeaders;
	Items.DataListSIHeaderDueDate.Visible = ThisSIHeaders;
	Items.DataListSIHeaderAmount.Visible = ThisSIHeaders;
	Items.DataListSIHeaderMemo.Visible = ThisSIHeaders;
	
	Items.DataListCheckBankAccount.Visible = ThisChecks;
	Items.DataListCheckDate.Visible = ThisChecks;
	Items.DataListCheckLineAccount.Visible = ThisChecks;
	Items.DataListCheckLineAmount.Visible = ThisChecks;
	Items.DataListCheckLineMemo.Visible = ThisChecks;
	Items.DataListCheckMemo.Visible = ThisChecks;
	Items.DataListCheckNumber.Visible = ThisChecks;
	Items.DataListCheckVendor.Visible = ThisChecks;

	Items.DataListCofACode.Visible = ThisCofA;
	Items.DataListCofADescription.Visible = ThisCofA;
	Items.DataListCofAType.Visible = ThisCofA;
	Items.DataListCofAUpdate.Visible = ThisCofA;
	
	Items.DataListBalancesAccount.Visible = ThisBalances;
	Items.DataListBalancesDebit.Visible = ThisBalances; 
	Items.DataListBalancesCredit.Visible = ThisBalances;
	
	Items.MapToTemplateCV.Visible = ThisCustomers;
	Items.UnmapCV.Visible = ThisCustomers;
	Items.IncomeAccount.Visible = ThisCustomers;
	Items.ARAccount.Visible = ThisCustomers;
	Items.ExpenseAccount.Visible = ThisCustomers;
	Items.APAccount.Visible = ThisCustomers;
	
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
	Items.DataListProductUoM.Visible = ThisProducts;
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

	//Items.DataListProductPreferredVendor.Visible = ThisProducts;
	
	Реквизиты.Очистить();	
	
	If ThisCofA Then
		
		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Code [char(10)]";
		НоваяСтрока.Обязательный = Истина;
		
		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Description [char(100)]";
		НоваяСтрока.Обязательный = Истина;
		
		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Type [ref]";
		НоваяСтрока.Обязательный = Истина;
		
		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Update [ref]";
		
	ElsIf ThisExpensify Then
			
		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Category [char(50)]";
		НоваяСтрока.Обязательный = Истина;
		
		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Amount [num]";
		НоваяСтрока.Обязательный = Истина;

	    НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Memo [char(100)]";
		
	ElsIf ThisIPHeaders Then
		
		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Number [char(20)]";
		НоваяСтрока.Обязательный = Истина;
		
		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Date [char yyyymmdd]";
		НоваяСтрока.Обязательный = Истина;

		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Vendor [ref]";
		НоваяСтрока.Обязательный = Истина;
	
		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Memo [char]";
	
		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Amount [num]";
		НоваяСтрока.Обязательный = Истина;
		
	ElsIf ThisPIDetails Then
		
		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Invoice [ref]";
		НоваяСтрока.Обязательный = Истина;

		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Account [ref]";
		НоваяСтрока.Обязательный = Истина;

		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Amount [num]";
		НоваяСтрока.Обязательный = Истина;

		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Memo [char(100)]";
				
	ElsIf ThisPIHeaders Then
		
		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Number [char(20)]";
		НоваяСтрока.Обязательный = Истина;
		
		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Date [char yyyymmdd]";
		НоваяСтрока.Обязательный = Истина;
		
		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Vendor [ref]";
		НоваяСтрока.Обязательный = Истина;

		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Due date [char yyyymmdd]";
		НоваяСтрока.Обязательный = Истина;

		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Terms [ref]";
		НоваяСтрока.Обязательный = Истина;

		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Memo [char]";

		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Amount [num]";
		НоваяСтрока.Обязательный = Истина;
				
	ElsIf ThisGJHeaders Then
		
		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Number [char(6)]";

		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Date [date]";
		НоваяСтрока.Обязательный = Истина;
		
		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Amount [num]";
		НоваяСтрока.Обязательный = Истина;

		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Memo [char]";

		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "AR or AP [char]";
		
	ElsIf ThisGJDetails Then
		
		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Header number [ref]";
		НоваяСтрока.Обязательный = Истина;
		
		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Account [ref]";
		НоваяСтрока.Обязательный = Истина;
		
		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Dr [num]";
		
		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Cr [num]";

		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Memo [char]";

		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Customer / Vendor [char]";
		
	ElsIf ThisSIHeaders Then
		
		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Invoice date [date]";
		НоваяСтрока.Обязательный = Истина;

		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Invoice number [char(6)]";
		НоваяСтрока.Обязательный = Истина;

		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "P.O. num [char(15)]";

		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Customer [ref]";
		НоваяСтрока.Обязательный = Истина;
		
		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Terms [ref]";
		НоваяСтрока.Обязательный = Истина;

		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Due date [date]";
		НоваяСтрока.Обязательный = Истина;

		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Amount [num]";
		НоваяСтрока.Обязательный = Истина;
		
		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Memo [char]";
		
	ElsIf ThisSIDetails Then
		
		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Invoice number [ref]";
		НоваяСтрока.Обязательный = Истина;
		
		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Item [ref]";
		НоваяСтрока.Обязательный = Истина;
		
		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Qty [num]";
		НоваяСтрока.Обязательный = Истина;
		
		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Price [num]";
		НоваяСтрока.Обязательный = Истина;

		
	ElsIf ThisChecks Then
			
		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Date [char]";
		НоваяСтрока.Обязательный = Истина;
		
		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Number [char(6)]";
		
		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Bank account [ref]";
		НоваяСтрока.Обязательный = Истина;
		
		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Vendor [ref]";

		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Check memo [char]";

		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Line account [ref]";
		НоваяСтрока.Обязательный = Истина;

	    НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Line memo [char]";
		
		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Line amount [num]";
		НоваяСтрока.Обязательный = Истина;
		
	ИначеЕсли ThisCustomers Тогда
		
		// company header
		
		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Type [0 - Customer, 1 - Vendor, 2 - Both]";
		НоваяСтрока.Обязательный = Истина;		
		
		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Description [char(150)]";
		//НоваяСтрока.НомерКолонки = 1;
		НоваяСтрока.Обязательный = Истина;
		
		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Default billing address [T - true, F - false]";
		НоваяСтрока.Обязательный = Истина;
		
		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Default shipping address [T - true, F - false]";
		НоваяСтрока.Обязательный = Истина;
		
	    НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Notes [char]";
		
		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Terms [ref]";
		
		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Vendor tax ID [char(15)]";
		
		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Customer sales person [ref]";
		
		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Customer price level [ref]";
		
		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Website [char(200)]";
		
		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Company CF1 string [char(100)]";
		
		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Company CF1 num [num]";
		
		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Company CF2 string [char(100)]";
		
		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Company CF2 num [num]";

		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Company CF3 string [char(100)]";
		
		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Company CF3 num [num]";
		
		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Company CF4 string [char(100)]";
		
		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Company CF4 num [num]";

		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Company CF5 string [char(100)]";
		
		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Company CF5 num [num]";
			
		// end company header
		
		// address
		
		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Address ID [char(25)]";
		
		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Salutation [char(15)]";
		
		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "First name [char(200)]";
		//НоваяСтрока.НомерКолонки = 2;
		
		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Middle name [char(200)]";
		
		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Last name [char(200)]";
		
		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Suffix [char(10)]";
		
		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Job title [char(200)]";

		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Phone [char(50)]";
		
		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Cell [char(50)]";		
		
		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Fax [char(50)]";
		
		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "E-mail [char(100)]";
		
		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Address line 1 [char(250)]";
		//НоваяСтрока.НомерКолонки = 3;
		
		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Address line 2 [char(250)]";
		
		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Address line 3 [char(250)]";
		
		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "City [char(100)]";
		
		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "State [ref]";

		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Country [ref]";

		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "ZIP [char(20)]";
		
		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Address notes [char]";
		
		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Address sales person [ref]";
		
		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Address CF1 string [char(200)]";
		
		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Address CF2 string [char(200)]";

		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Address CF3 string [char(200)]";

		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Address CF4 string [char(200)]";

		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Address CF5 string [char(200)]";

		// end address
		
	ИначеЕсли ThisBalances Тогда	
		
		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Account code [ref]";
		НоваяСтрока.Обязательный = Истина;
		
		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Debit [num]";
		НоваяСтрока.Обязательный = Истина;
		
		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Credit [num]";
		НоваяСтрока.Обязательный = Истина;
		
	ИначеЕсли ThisProducts Тогда
		
		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Product OR Service";
		НоваяСтрока.Обязательный = Истина;
	
		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Item code [char(50)]";
		НоваяСтрока.Обязательный = Истина;
		
		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Item description [char(150)]";
		НоваяСтрока.Обязательный = Истина;
		
		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Income account [ref]";
		
		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Inventory or expense account [ref]";
		
		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "COGS account [ref]";
		
		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Price [num]";
		
		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Qty [num]";
		
		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Value [num]";
		
		//НоваяСтрока = Реквизиты.Добавить();
		//НоваяСтрока.ИмяРеквизита = "Preferred vendor [ref]";
		
		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "Category [ref]";
		
		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "UoM [ref]";	

		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "CF1String [char(100)]";
		
		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "CF1Num [num]";
		
		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "CF2String [char(100)]";
		
		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "CF2Num [num]";

		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "CF3String [char(100)]";
		
		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "CF3Num [num]";
		
		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "CF4String [char(100)]";
		
		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "CF4Num [num]";

		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "CF5String [char(100)]";
		
		НоваяСтрока = Реквизиты.Добавить();
		НоваяСтрока.ИмяРеквизита = "CF5Num [num]";
		
	КонецЕсли;
	
КонецПроцедуры // ЗаполнитьРеквизиты()

&НаСервере
Функция ЗаполнитьИсточникНаСервере(КоличествоСтрок)
	
	Источник = Новый ТаблицаЗначений;
	
	МаксКоличествоКолонок = 0;
	
	Для СчетчикСтрок = 1 По КоличествоСтрок Цикл
		                                                          
		ТекущаяСтрока = ТекстИсточника.ПолучитьСтроку(СчетчикСтрок);
		МассивЗначений = StringFunctionsClientServer.SplitStringIntoSubstringArray(ТекущаяСтрока, ",",,"""");
		КоличествоКолонок = МассивЗначений.Количество();
		
		Если КоличествоКолонок < 1 тогда
			Продолжить;
		КонецЕсли;
		
		Если КоличествоКолонок > МаксКоличествоКолонок Тогда
			Для СчетчикКолонок = МаксКоличествоКолонок + 1 По КоличествоКолонок Цикл
				НоваяКолонка = Источник.Колонки.Добавить();
				НоваяКолонка.Имя = "Column" + СокрЛП(СчетчикКолонок);
				НоваяКолонка.Заголовок = "Column #" + СокрЛП(СчетчикКолонок);
			КонецЦикла;
			МаксКоличествоКолонок = КоличествоКолонок;
		КонецЕсли;
		
		НоваяСтрока = Источник.Добавить();
		Для СчетчикКолонок = 0 По КоличествоКолонок - 1 Цикл
			НоваяСтрока[СчетчикКолонок] = МассивЗначений[СчетчикКолонок];
		КонецЦикла;
		
	КонецЦикла;
	
	SourceAddress = ПоместитьВоВременноеХранилище(Источник, ЭтаФорма.УникальныйИдентификатор);
	
	Возврат SourceAddress;
	
КонецФункции

&НаКлиенте
Процедура ПрочитатьФайлИсточник()
	
	Файл = СокрЛП(ПутьКФайлу);
	
	Если НЕ ПодключитьРасширениеРаботыСФайлами() Тогда
		Файл = "";
	Иначе
		ФайлЗагр = Новый Файл(Файл);
		Если ФайлЗагр.Существует() = Ложь Тогда
			ТекстСообщения = НСтр("en = 'File %Файл% does not exist!';de='Datei existiert nicht!'");
			ТекстСообщения = СтрЗаменить(ТекстСообщения, "%Файл%", Файл);
			Message(ТекстСообщения);
			//УправлениеНебольшойФирмойСервер.СообщитьОбОшибке(, ТекстСообщения);
			Возврат;
		КонецЕсли;
		Попытка
			ТекстИсточника.Прочитать(Файл);
		Исключение
			ТекстСообщения = НСтр("en = 'Can not read the file.';de='Die Datei kann nicht gelesen werden'");
			Message(ТекстСообщения);
			//УправлениеНебольшойФирмойСервер.СообщитьОбОшибке(, ТекстСообщения);
			Возврат;
		КонецПопытки;
	КонецЕсли;
	
	ТекстИсточника.Прочитать(Файл);
	КоличествоСтрок = ТекстИсточника.КоличествоСтрок();
	
	Если КоличествоСтрок < 1 Тогда
		ТекстСообщения = НСтр("en = 'The file has no data!';de='Die Datei enthält keine Daten!'");
		Message(ТекстСообщения);
		//УправлениеНебольшойФирмойСервер.СообщитьОбОшибке(, ТекстСообщения);
		Возврат;
	КонецЕсли;
	
	SourceAddress = Неопределено;
	
	SourceAddress = ЗаполнитьИсточникНаСервере(КоличествоСтрок);
	
КонецПроцедуры

&НаСервере
Процедура ЗаполнитьПредставлениеИсточника()

	ПредставлениеИсточника.Очистить();
	
	Обработка = РеквизитФормыВЗначение("Object");
	Макет = Обработка.ПолучитьМакет("Макет");
	ОбластьПустая = Макет.ПолучитьОбласть("Пустая");
	ОбластьШапка = Макет.ПолучитьОбласть("Шапка");
	ОбластьЯчейка = Макет.ПолучитьОбласть("Ячейка");
	
	Источник = ПолучитьИзВременногоХранилища(SourceAddress);

	ПредставлениеИсточника.Вывести(ОбластьПустая);
	Для каждого КолонкаИсточника Из Источник.Колонки Цикл
		ОбластьШапка.Параметры.Текст = КолонкаИсточника.Заголовок;
		ПредставлениеИсточника.Присоединить(ОбластьШапка);
	КонецЦикла;
	
	КоличествоКолонок = Источник.Колонки.Количество();
	Для каждого СтрокаИсточника Из Источник Цикл
		ПредставлениеИсточника.Вывести(ОбластьПустая);
		Для СчетчикКолонок = 0 По КоличествоКолонок -1  Цикл
			ОбластьЯчейка.Параметры.Текст = СтрокаИсточника[СчетчикКолонок];
			ПредставлениеИсточника.Присоединить(ОбластьЯчейка);
		КонецЦикла;
	КонецЦикла;
	
	Элементы.РеквизитыНомерКолонки.МаксимальноеЗначение = Источник.Колонки.Количество();
	
КонецПроцедуры

&НаСервере
Процедура ЗаполнитьСписокЗагрузки()
	
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
	
	Источник = ПолучитьИзВременногоХранилища(SourceAddress);
		
	Для СчетчикСтрок = 0 по Источник.Количество() - 1 Цикл
				
		Если ActionType = "Chart of accounts" Then
			
			НоваяСтрока = ТаблицаЗагрузки.Добавить();
			НоваяСтрока.ФлагЗагрузки = Истина;
					
			НомерКолонки = НайтиНомерКолонкиРеквизита("Code [char(10)]");
			Если НомерКолонки <> Неопределено Тогда
				НоваяСтрока.CofACode = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
			КонецЕсли;

			НомерКолонки = НайтиНомерКолонкиРеквизита("Description [char(100)]");
			Если НомерКолонки <> Неопределено Тогда
				НоваяСтрока.CofADescription = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
			КонецЕсли;
			
			НомерКолонки = НайтиНомерКолонкиРеквизита("Type [ref]");
			Если НомерКолонки <> Неопределено Тогда
				
				AccountTypeString = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);

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

				НоваяСтрока.CofAType = AccountTypeValue;
				
			КонецЕсли;

			НомерКолонки = НайтиНомерКолонкиРеквизита("Update [ref]");
			Если НомерКолонки <> Неопределено Тогда
				AccountCode = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
				НоваяСтрока.CofAUpdate = ChartsOfAccounts.ChartOfAccounts.FindByCode(AccountCode);
			КонецЕсли;
						
		ElsIf ActionType = "Invoice payments / Checks (header)" Then
			
			НоваяСтрока = ТаблицаЗагрузки.Добавить();
			НоваяСтрока.ФлагЗагрузки = Истина;
			
			НомерКолонки = НайтиНомерКолонкиРеквизита("Number [char(20)]");
			If НомерКолонки <> Undefined Then
				НоваяСтрока.IPHeaderNumber = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
			EndIf;

			НомерКолонки = НайтиНомерКолонкиРеквизита("Date [char yyyymmdd]");
			If НомерКолонки <> Undefined Then
				IPDate = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
				НоваяСтрока.IPHeaderDate = Date(IPDate);
			EndIf;

			НомерКолонки = НайтиНомерКолонкиРеквизита("Vendor [ref]");
			If НомерКолонки <> Undefined Then
				IPVendor = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
				НоваяСтрока.IPHeaderVendor = Catalogs.Companies.FindByDescription(IPVendor);
			EndIf;

			НомерКолонки = НайтиНомерКолонкиРеквизита("Memo [char]");
			If НомерКолонки <> Undefined Then
				НоваяСтрока.IPHeaderMemo = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
			EndIf;

			НомерКолонки = НайтиНомерКолонкиРеквизита("Amount [num]");
			If НомерКолонки <> Undefined Then
				НоваяСтрока.IPHeaderAmount = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
			EndIf;
			
		ElsIf ActionType = "Expensify" Then
			
			НоваяСтрока = ТаблицаЗагрузки.Добавить();
			НоваяСтрока.ФлагЗагрузки = Истина;
			
			НомерКолонки = НайтиНомерКолонкиРеквизита("Category [char(50)]");
			If НомерКолонки <> Undefined Then
				Category = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
				
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
					НоваяСтрока.ExpensifyAccount = Dataset[0][0];
				EndIf;

			EndIf;
			
			НомерКолонки = НайтиНомерКолонкиРеквизита("Amount [num]");
			If НомерКолонки <> Undefined Then
				НоваяСтрока.ExpensifyAmount = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
			EndIf;

			НомерКолонки = НайтиНомерКолонкиРеквизита("Memo [char(100)]");
			If НомерКолонки <> Undefined Then
				НоваяСтрока.ExpensifyMemo = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
			EndIf;
		
		ElsIf ActionType = "Purchase invoices (detail)" Then
			
			НоваяСтрока = ТаблицаЗагрузки.Добавить();
			НоваяСтрока.ФлагЗагрузки = Истина;
			
			НомерКолонки = НайтиНомерКолонкиРеквизита("Invoice [ref]");
			If НомерКолонки <> Undefined Then
				TrxNumber = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
				НоваяСтрока.PIDetailHeader = Documents.PurchaseInvoice.FindByNumber(TrxNumber);
			EndIf;

			НомерКолонки = НайтиНомерКолонкиРеквизита("Account [ref]");
			If НомерКолонки <> Undefined Then
				TrxAccount = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
				НоваяСтрока.PIDetailAccount = ChartsOfAccounts.ChartOfAccounts.FindByCode(TrxAccount);
			EndIf;

			НомерКолонки = НайтиНомерКолонкиРеквизита("Amount [num]");
			If НомерКолонки <> Undefined Then
				НоваяСтрока.PIDetailAmount = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
			EndIf;

			НомерКолонки = НайтиНомерКолонкиРеквизита("Memo [char(100)]");
			If НомерКолонки <> Undefined Then
				НоваяСтрока.PIDetailMemo = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
			EndIf;
			
		ElsIf ActionType = "Purchase invoices (header)" Then	
			
			НоваяСтрока = ТаблицаЗагрузки.Добавить();
			НоваяСтрока.ФлагЗагрузки = Истина;

	        НомерКолонки = НайтиНомерКолонкиРеквизита("Number [char(20)]");
			If НомерКолонки <> Undefined Then
				НоваяСтрока.PIHeaderNumber = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
			EndIf;

			НомерКолонки = НайтиНомерКолонкиРеквизита("Date [char yyyymmdd]");
			If НомерКолонки <> Undefined Then
				PIDate = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
				НоваяСтрока.PIHeaderDate = Date(PIDate);
			EndIf;

			НомерКолонки = НайтиНомерКолонкиРеквизита("Vendor [ref]");
			If НомерКолонки <> Undefined Then
				PIVendor = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
				НоваяСтрока.PIHeaderVendor = Catalogs.Companies.FindByDescription(PIVendor);
			EndIf;

			НомерКолонки = НайтиНомерКолонкиРеквизита("Due date [char yyyymmdd]");
			If НомерКолонки <> Undefined Then
				PIDueDate = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
				НоваяСтрока.PIHeaderDueDate = Date(PIDate);
			EndIf;

			НомерКолонки = НайтиНомерКолонкиРеквизита("Terms [ref]");
			If НомерКолонки <> Undefined Then
				TermsString = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
				НоваяСтрока.PIHeaderTerms = Catalogs.PaymentTerms.FindByDescription(TermsString);
			EndIf;

			НомерКолонки = НайтиНомерКолонкиРеквизита("Memo [char]");
			If НомерКолонки <> Undefined Then
				НоваяСтрока.PIHeaderMemo = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
			EndIf;

			НомерКолонки = НайтиНомерКолонкиРеквизита("Amount [num]");
			If НомерКолонки <> Undefined Then
				НоваяСтрока.PIHeaderAmount = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
			EndIf;
							
			
		ElsIf ActionType = "GJ entries (header)" Then
		
			НоваяСтрока = ТаблицаЗагрузки.Добавить();
			НоваяСтрока.ФлагЗагрузки = Истина;

			НомерКолонки = НайтиНомерКолонкиРеквизита("Number [char(6)]");
			If НомерКолонки <> Undefined Then
				TrxNumber = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
				If NOT TrxNumber = "" Then
					НоваяСтрока.GJHeaderNumber = TrxNumber;
				EndIf;
			EndIf;

			НомерКолонки = НайтиНомерКолонкиРеквизита("Date [date]");
			If НомерКолонки <> Undefined Then
				TrxDate = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
				НоваяСтрока.GJHeaderDate = Date(TrxDate);
			EndIf;
			
			НомерКолонки = НайтиНомерКолонкиРеквизита("Amount [num]");
			If НомерКолонки <> Undefined Then
				НоваяСтрока.GJHeaderAmount = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
			EndIf;

			НомерКолонки = НайтиНомерКолонкиРеквизита("Memo [char]");
			If НомерКолонки <> Undefined Then
				НоваяСтрока.GJHeaderMemo = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
			EndIf;

			НомерКолонки = НайтиНомерКолонкиРеквизита("AR or AP [char]");
			If НомерКолонки <> Undefined Then
				TrxType = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
				If TrxType = "AR" Then
					НоваяСтрока.GJHeaderARorAP = Enums.GJEntryType.AR;
				ElsIf TrxType = "AP" Then
					НоваяСтрока.GJHeaderARorAP = Enums.GJEntryType.AP;
				EndIf;
			EndIf;
			
		ElsIf ActionType = "GJ entries (detail)" Then
			
			НоваяСтрока = ТаблицаЗагрузки.Добавить();
			НоваяСтрока.ФлагЗагрузки = Истина;

			НомерКолонки = НайтиНомерКолонкиРеквизита("Header number [ref]");
			If НомерКолонки <> Undefined Then
				TrxNumber = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
				НоваяСтрока.GJDetailHeader = Documents.GeneralJournalEntry.FindByNumber(TrxNumber);
			EndIf;
	
			НомерКолонки = НайтиНомерКолонкиРеквизита("Account [ref]");
			If НомерКолонки <> Undefined Then
				TrxAccount = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
				НоваяСтрока.GJDetailAccount = ChartsOfAccounts.ChartOfAccounts.FindByCode(TrxAccount);
			EndIf;
			
			НомерКолонки = НайтиНомерКолонкиРеквизита("Dr [num]");
			If НомерКолонки <> Undefined Then
				НоваяСтрока.GJDetailDr = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
			EndIf;

			НомерКолонки = НайтиНомерКолонкиРеквизита("Cr [num]");
			If НомерКолонки <> Undefined Then
				НоваяСтрока.GJDetailCr = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
			EndIf;
			
			НомерКолонки = НайтиНомерКолонкиРеквизита("Memo [char]");
			If НомерКолонки <> Undefined Then
				НоваяСтрока.GJDetailMemo = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
			EndIf;

			НомерКолонки = НайтиНомерКолонкиРеквизита("Customer / Vendor [char]");
			If НомерКолонки <> Undefined Then
				TrxCompany = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
				If NOT TrxCompany = "" Then
					CompanyID = Catalogs.Companies.FindByDescription(TrxCompany);
					If NOT CompanyID = Undefined Then
						НоваяСтрока.GJDetailCompany = CompanyID;
					EndIf;
				EndIf;
			EndIf;
			
		ElsIf ActionType = "Sales invoices (header)" Then
			
			НоваяСтрока = ТаблицаЗагрузки.Добавить();
			НоваяСтрока.ФлагЗагрузки = Истина;

			НомерКолонки = НайтиНомерКолонкиРеквизита("Invoice date [date]");
			If НомерКолонки <> Undefined Then
				InvoiceDateString = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
				
				TransactionDate = '00010101';
				DateParts = StringFunctionsClientServer.SplitStringIntoSubstringArray(InvoiceDateString, "/",,"""");
				If DateParts.Count() = 3 then
					Try
						TransactionDate 	= Date(DateParts[2], DateParts[0], DatePArts[1]);
					Except
					EndTry;				
				EndIf;

				
				НоваяСтрока.SIHeaderDate = TransactionDate;
			EndIf;
			
			НомерКолонки = НайтиНомерКолонкиРеквизита("Invoice number [char(6)]");
			If НомерКолонки <> Undefined Then
				InvoiceNumber = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
				НоваяСтрока.SIHeaderNumber = InvoiceNumber;
			EndIf;
			
			НомерКолонки = НайтиНомерКолонкиРеквизита("Memo [char]");
			If НомерКолонки <> Undefined Then
				НоваяСтрока.SIHeaderMemo = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
			EndIf;

			НомерКолонки = НайтиНомерКолонкиРеквизита("P.O. num [char(15)]");
			If НомерКолонки <> Undefined Then
				ARPONum = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
				НоваяСтрока.SIHeaderPO = ARPONum;
			EndIf;
			
			НомерКолонки = НайтиНомерКолонкиРеквизита("Customer [ref]");
			If НомерКолонки <> Undefined Then
				CustomerString = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
				НоваяСтрока.SIHeaderCustomer = Catalogs.Companies.FindByDescription(CustomerString);
			EndIf;

			НомерКолонки = НайтиНомерКолонкиРеквизита("Terms [ref]");
			If НомерКолонки <> Undefined Then
				TermsString = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
				НоваяСтрока.SIHeaderTerms = Catalogs.PaymentTerms.FindByDescription(TermsString);
			EndIf;

			НомерКолонки = НайтиНомерКолонкиРеквизита("Due date [date]");
			If НомерКолонки <> Undefined Then
				ARDueDateString = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
				
				TransactionDate = '00010101';
				DateParts = StringFunctionsClientServer.SplitStringIntoSubstringArray(ARDueDateString, "/",,"""");
				If DateParts.Count() = 3 then
					Try
						TransactionDate 	= Date(DateParts[2], DateParts[0], DatePArts[1]);
					Except
					EndTry;				
				EndIf;
			
				НоваяСтрока.SIHeaderDueDate = TransactionDate;
			EndIf;

			НомерКолонки = НайтиНомерКолонкиРеквизита("Amount [num]");
			If НомерКолонки <> Undefined Then
				OpenBalance = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
				НоваяСтрока.SIHeaderAmount = OpenBalance;
			EndIf;
			
		ElsIf ActionType = "Sales invoices (detail)" Then	
			
			НомерКолонки = НайтиНомерКолонкиРеквизита("Invoice number [ref]");
			If НомерКолонки <> Undefined Then
				TrxNumber = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
				If CreditMemo = True Then
					InvoiceID = Documents.SalesReturn.FindByNumber(TrxNumber);	
				Else
					InvoiceID = Documents.SalesInvoice.FindByNumber(TrxNumber);
				EndIf;
			EndIf;
							
			If InvoiceID <> Documents.SalesReturn.EmptyRef() AND InvoiceID.Posted = False Then  // custom - delete
				
				НоваяСтрока = ТаблицаЗагрузки.Добавить();
				НоваяСтрока.ФлагЗагрузки = Истина;

				НоваяСтрока.SIDetailHeader = InvoiceID;
				
				//НомерКолонки = НайтиНомерКолонкиРеквизита("Invoice number [ref]");
				//If НомерКолонки <> Undefined Then
				//	TrxNumber = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
				//	НоваяСтрока.SIDetailHeader = Documents.SalesInvoice.FindByNumber(TrxNumber);
				//EndIf;

				НомерКолонки = НайтиНомерКолонкиРеквизита("Item [ref]");
				If НомерКолонки <> Undefined Then
					ItemCode = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
					НоваяСтрока.SIDetailProduct = Catalogs.Products.FindByCode(ItemCode);
				EndIf;

				НомерКолонки = НайтиНомерКолонкиРеквизита("Qty [num]");
				If НомерКолонки <> Undefined Then
					НоваяСтрока.SIDetailQty = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
				EndIf;

				НомерКолонки = НайтиНомерКолонкиРеквизита("Price [num]");
				If НомерКолонки <> Undefined Then
					НоваяСтрока.SIDetailPrice = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
				EndIf;
				
			EndIf;
				
		ElsIf ActionType = "Checks" Then
			
			НоваяСтрока = ТаблицаЗагрузки.Добавить();
			НоваяСтрока.ФлагЗагрузки = Истина;

			НомерКолонки = НайтиНомерКолонкиРеквизита("Date [char]");
			Если НомерКолонки <> Неопределено Тогда
				CheckDateString = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
				
				TransactionDate = '00010101';
				DateParts = StringFunctionsClientServer.SplitStringIntoSubstringArray(CheckDateString, "/",,"""");
				If DateParts.Count() = 3 then
					Try
						TransactionDate 	= Date(DateParts[2], DateParts[0], DatePArts[1]);
					Except
					EndTry;				
				EndIf;
				
				НоваяСтрока.CheckDate = TransactionDate;
			КонецЕсли;

			НомерКолонки = НайтиНомерКолонкиРеквизита("Number [char(6)]");
			Если НомерКолонки <> Неопределено Тогда
				НоваяСтрока.CheckNumber = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
			КонецЕсли;

			НомерКолонки = НайтиНомерКолонкиРеквизита("Bank account [ref]");
			Если НомерКолонки <> Неопределено Тогда
				BankAccountString = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
				НоваяСтрока.CheckBankAccount = ChartsOfAccounts.ChartOfAccounts.FindByCode(BankAccountString);
			КонецЕсли;

			НомерКолонки = НайтиНомерКолонкиРеквизита("Vendor [ref]");
			Если НомерКолонки <> Неопределено Тогда
				VendorString = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
				НоваяСтрока.CheckVendor = Catalogs.Companies.FindByDescription(VendorString);
			КонецЕсли;
			
			НомерКолонки = НайтиНомерКолонкиРеквизита("Check memo [char]");
			Если НомерКолонки <> Неопределено Тогда
				НоваяСтрока.CheckMemo = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
			КонецЕсли;
			
			НомерКолонки = НайтиНомерКолонкиРеквизита("Line account [ref]");
			Если НомерКолонки <> Неопределено Тогда
				LineAccountString = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
				НоваяСтрока.CheckLineAccount = ChartsOfAccounts.ChartOfAccounts.FindByCode(LineAccountString);
			КонецЕсли;

			НомерКолонки = НайтиНомерКолонкиРеквизита("Line memo [char]");
			Если НомерКолонки <> Неопределено Тогда
				НоваяСтрока.CheckLineMemo = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
			КонецЕсли;

			НомерКолонки = НайтиНомерКолонкиРеквизита("Line amount [num]");
			Если НомерКолонки <> Неопределено Тогда
				НоваяСтрока.CheckLineAmount = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
			КонецЕсли;
			
		ElsIf ActionType = "CustomersVendors" Then
			
			НоваяСтрока = ТаблицаЗагрузки.Добавить();
			НоваяСтрока.ФлагЗагрузки = Истина;
			
			НомерКолонки = НайтиНомерКолонкиРеквизита("Type [0 - Customer, 1 - Vendor, 2 - Both]");
			Если НомерКолонки <> Неопределено Тогда
				CustomerTypeValue = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
				Try
					CustomerTypeValue = Number(CustomerTypeValue);
				
					If CustomerTypeValue = 0 OR
						CustomerTypeValue = 1 OR
						CustomerTypeValue = 2 Then
							НоваяСтрока.CustomerType = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
					Else
						НоваяСтрока.CustomerType = 0;
					EndIf;
	
				Except
					НоваяСтрока.CustomerType = 0;
				EndTry;
			КонецЕсли;

			НомерКолонки = НайтиНомерКолонкиРеквизита("Description [char(150)]");
			Если НомерКолонки <> Неопределено Тогда
				НоваяСтрока.CustomerDescription = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
			КонецЕсли;
			
			НомерКолонки = НайтиНомерКолонкиРеквизита("Default billing address [T - true, F - false]");
			Если НомерКолонки <> Неопределено Тогда
				If СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]) = "T" Then
					НоваяСтрока.DefaultBillingAddress = True;
				Else
					НоваяСтрока.DefaultBillingAddress = False;
				EndIf
			КонецЕсли;
			
			НомерКолонки = НайтиНомерКолонкиРеквизита("Default shipping address [T - true, F - false]");
			Если НомерКолонки <> Неопределено Тогда
				If СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]) = "T" Then
					НоваяСтрока.DefaultShippingAddress = True;
				Else
					НоваяСтрока.DefaultShippingAddress = False;
				EndIf
			КонецЕсли;
			
			НомерКолонки = НайтиНомерКолонкиРеквизита("Notes [char]");
			Если НомерКолонки <> Неопределено Тогда
				НоваяСтрока.CustomerNotes = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
			КонецЕсли;
			
			НомерКолонки = НайтиНомерКолонкиРеквизита("Website [char(200)]");
			Если НомерКолонки <> Неопределено Тогда
				НоваяСтрока.CustomerWebsite = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
			КонецЕсли;
		
			НомерКолонки = НайтиНомерКолонкиРеквизита("Terms [ref]");
			Если НомерКолонки <> Неопределено Тогда
				TermsString = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
				If TermsString = "" Then
					НоваяСтрока.CustomerTerms = Catalogs.PaymentTerms.Net30;
				Else
					НоваяСтрока.CustomerTerms = Catalogs.PaymentTerms.FindByDescription(TermsString);
				EndIf;
			Иначе
				НоваяСтрока.CustomerTerms = Catalogs.PaymentTerms.Net30;
			КонецЕсли;
			
			НомерКолонки = НайтиНомерКолонкиРеквизита("Company CF1 string [char(100)]");
			Если НомерКолонки <> Неопределено Тогда
				НоваяСтрока.CustomerCF1String = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
			КонецЕсли;
			
			НомерКолонки = НайтиНомерКолонкиРеквизита("Company CF1 num [num]");
			Если НомерКолонки <> Неопределено Тогда
				НоваяСтрока.CustomerCF1Num = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
			КонецЕсли;
			
			НомерКолонки = НайтиНомерКолонкиРеквизита("Company CF2 string [char(100)]");
			Если НомерКолонки <> Неопределено Тогда
				НоваяСтрока.CustomerCF2String = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
			КонецЕсли;
			
			НомерКолонки = НайтиНомерКолонкиРеквизита("Company CF2 num [num]");
			Если НомерКолонки <> Неопределено Тогда
				НоваяСтрока.CustomerCF2Num = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
			КонецЕсли;

			НомерКолонки = НайтиНомерКолонкиРеквизита("Company CF3 string [char(100)]");
			Если НомерКолонки <> Неопределено Тогда
				НоваяСтрока.CustomerCF3String = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
			КонецЕсли;
			
			НомерКолонки = НайтиНомерКолонкиРеквизита("Company CF3 num [num]");
			Если НомерКолонки <> Неопределено Тогда
				НоваяСтрока.CustomerCF3Num = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
			КонецЕсли;

			НомерКолонки = НайтиНомерКолонкиРеквизита("Company CF4 string [char(100)]");
			Если НомерКолонки <> Неопределено Тогда
				НоваяСтрока.CustomerCF4String = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
			КонецЕсли;
			
			НомерКолонки = НайтиНомерКолонкиРеквизита("Company CF4 num [num]");
			Если НомерКолонки <> Неопределено Тогда
				НоваяСтрока.CustomerCF4Num = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
			КонецЕсли;
			
			НомерКолонки = НайтиНомерКолонкиРеквизита("Company CF5 string [char(100)]");
			Если НомерКолонки <> Неопределено Тогда
				НоваяСтрока.CustomerCF5String = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
			КонецЕсли;
			
			НомерКолонки = НайтиНомерКолонкиРеквизита("Company CF5 num [num]");
			Если НомерКолонки <> Неопределено Тогда
				НоваяСтрока.CustomerCF5Num = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
			КонецЕсли;
			
			НомерКолонки = НайтиНомерКолонкиРеквизита("Vendor tax ID [char(15)]");
			Если НомерКолонки <> Неопределено Тогда
				НоваяСтрока.CustomerVendorTaxID = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
			КонецЕсли;
			
			НомерКолонки = НайтиНомерКолонкиРеквизита("Customer sales person [ref]");
			Если НомерКолонки <> Неопределено Тогда
				RepString = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
				If RepString = "" Then
				Else
					НоваяСтрока.CustomerSalesPerson = Catalogs.SalesPeople.FindByDescription(RepString);
				EndIf;
			КонецЕсли;
						
			НомерКолонки = НайтиНомерКолонкиРеквизита("Customer price level [ref]");
			Если НомерКолонки <> Неопределено Тогда
				PriceL = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
				If PriceL = "" Then
				Else
					НоваяСтрока.CustomerPriceLevel = Catalogs.PriceLevels.FindByDescription(PriceL);
				EndIf;
			КонецЕсли;

			// billing address
			
			НомерКолонки = НайтиНомерКолонкиРеквизита("Address ID [char(25)]");
			Если НомерКолонки <> Неопределено Тогда
				НоваяСтрока.CustomerAddressID = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
			КонецЕсли;

			НомерКолонки = НайтиНомерКолонкиРеквизита("Salutation [char(15)]");
			Если НомерКолонки <> Неопределено Тогда
				НоваяСтрока.AddressSalutation = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
			КонецЕсли;
		
			НомерКолонки = НайтиНомерКолонкиРеквизита("First name [char(200)]");
			Если НомерКолонки <> Неопределено Тогда
				НоваяСтрока.CustomerFirstName = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
			КонецЕсли;

			НомерКолонки = НайтиНомерКолонкиРеквизита("Middle name [char(200)]");
			Если НомерКолонки <> Неопределено Тогда
				НоваяСтрока.CustomerMiddleName = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
			КонецЕсли;

			НомерКолонки = НайтиНомерКолонкиРеквизита("Last name [char(200)]");
			Если НомерКолонки <> Неопределено Тогда
				НоваяСтрока.CustomerLastName = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
			КонецЕсли;

			НомерКолонки = НайтиНомерКолонкиРеквизита("Suffix [char(10)]");
			Если НомерКолонки <> Неопределено Тогда
				НоваяСтрока.AddressSuffix = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
			КонецЕсли;
			
			НомерКолонки = НайтиНомерКолонкиРеквизита("Job title [char(200)]");
			Если НомерКолонки <> Неопределено Тогда
				НоваяСтрока.AddressJobTitle = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
			КонецЕсли;
		
			НомерКолонки = НайтиНомерКолонкиРеквизита("Phone [char(50)]");
			Если НомерКолонки <> Неопределено Тогда
				НоваяСтрока.CustomerPhone = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
			КонецЕсли;
			
			НомерКолонки = НайтиНомерКолонкиРеквизита("Cell [char(50)]");
			Если НомерКолонки <> Неопределено Тогда
				НоваяСтрока.CustomerCell = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
			КонецЕсли;

			НомерКолонки = НайтиНомерКолонкиРеквизита("Fax [char(50)]");
			Если НомерКолонки <> Неопределено Тогда
				НоваяСтрока.CustomerFax = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
			КонецЕсли;

			НомерКолонки = НайтиНомерКолонкиРеквизита("E-mail [char(100)]");
			Если НомерКолонки <> Неопределено Тогда
				НоваяСтрока.CustomerEmail = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
			КонецЕсли;

			НомерКолонки = НайтиНомерКолонкиРеквизита("Address line 1 [char(250)]");
			Если НомерКолонки <> Неопределено Тогда
				НоваяСтрока.CustomerAddressLine1 = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
			КонецЕсли;

			НомерКолонки = НайтиНомерКолонкиРеквизита("Address line 2 [char(250)]");
			Если НомерКолонки <> Неопределено Тогда
				НоваяСтрока.CustomerAddressLine2 = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
			КонецЕсли;
			
			НомерКолонки = НайтиНомерКолонкиРеквизита("Address line 3 [char(250)]");
			Если НомерКолонки <> Неопределено Тогда
				НоваяСтрока.CustomerAddressLine3 = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
			КонецЕсли;

			НомерКолонки = НайтиНомерКолонкиРеквизита("City [char(100)]");
			Если НомерКолонки <> Неопределено Тогда
				НоваяСтрока.CustomerCity = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
			КонецЕсли;

			НомерКолонки = НайтиНомерКолонкиРеквизита("State [ref]");
			Если НомерКолонки <> Неопределено Тогда
				StateString = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
				If StateString = "" Then
				Else
					НоваяСтрока.CustomerState = Catalogs.States.FindByCode(StateString);
				EndIf;
			КонецЕсли;

			НомерКолонки = НайтиНомерКолонкиРеквизита("Country [ref]");
			Если НомерКолонки <> Неопределено Тогда
				CountryString = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
				If CountryString = "" Then
				Else
					НоваяСтрока.CustomerCountry = Catalogs.Countries.FindByCode(CountryString);
				EndIf;	
			КонецЕсли;

			НомерКолонки = НайтиНомерКолонкиРеквизита("ZIP [char(20)]");
			Если НомерКолонки <> Неопределено Тогда
				НоваяСтрока.CustomerZIP = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
			КонецЕсли;
			
			НомерКолонки = НайтиНомерКолонкиРеквизита("Address notes [char]");
			Если НомерКолонки <> Неопределено Тогда
				НоваяСтрока.CustomerAddressNotes = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
			КонецЕсли;
			
			НомерКолонки = НайтиНомерКолонкиРеквизита("Address CF1 string [char(200)]");
			Если НомерКолонки <> Неопределено Тогда
				НоваяСтрока.AddressCF1String = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
			КонецЕсли;
			
			НомерКолонки = НайтиНомерКолонкиРеквизита("Address CF2 string [char(200)]");
			Если НомерКолонки <> Неопределено Тогда
				НоваяСтрока.AddressCF2String = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
			КонецЕсли;

			НомерКолонки = НайтиНомерКолонкиРеквизита("Address CF3 string [char(200)]");
			Если НомерКолонки <> Неопределено Тогда
				НоваяСтрока.AddressCF3String = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
			КонецЕсли;

			НомерКолонки = НайтиНомерКолонкиРеквизита("Address CF4 string [char(200)]");
			Если НомерКолонки <> Неопределено Тогда
				НоваяСтрока.AddressCF4String = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
			КонецЕсли;

			НомерКолонки = НайтиНомерКолонкиРеквизита("Address CF5 string [char(200)]");
			Если НомерКолонки <> Неопределено Тогда
				НоваяСтрока.AddressCF5String = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
			КонецЕсли;
			
			НомерКолонки = НайтиНомерКолонкиРеквизита("Address sales person [ref]");
			Если НомерКолонки <> Неопределено Тогда
				RepString = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
				If RepString = "" Then
				Else
					НоваяСтрока.AddressSalesPerson = Catalogs.SalesPeople.FindByDescription(RepString);
				EndIf;
			КонецЕсли;
						
		// end shipping address
			
		ElsIf ActionType = "Account balances" Then
			
			НоваяСтрока = ТаблицаЗагрузки.Добавить();
			НоваяСтрока.ФлагЗагрузки = Истина;
			
			НомерКолонки = НайтиНомерКолонкиРеквизита("Debit [num]");
			Если НомерКолонки <> Неопределено Тогда
				DebitString = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
				If DebitString = "" Then
					НоваяСтрока.BalancesDebit = 0;				
				Else
					НоваяСтрока.BalancesDebit = Number(DebitString);
				EndIf;
			КонецЕсли;
			
			НомерКолонки = НайтиНомерКолонкиРеквизита("Credit [num]");
			Если НомерКолонки <> Неопределено Тогда
				CreditString = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
				If CreditString = "" Then
					НоваяСтрока.BalancesCredit = 0;				
				Else
					НоваяСтрока.BalancesCredit = Number(CreditString);
				EndIf;
			КонецЕсли;
			
			НомерКолонки = НайтиНомерКолонкиРеквизита("Account code [ref]");
			Если НомерКолонки <> Неопределено Тогда
				AccountString = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
				НоваяСтрока.BalancesAccount = ChartsOfAccounts.ChartOfAccounts.FindByCode(AccountString);
			КонецЕсли;
			
		ElsIf ActionType = "Items" Then
			
			НоваяСтрока = ТаблицаЗагрузки.Добавить();
			НоваяСтрока.ФлагЗагрузки = Истина;
			
			НомерКолонки = НайтиНомерКолонкиРеквизита("Product OR Service");
			Если НомерКолонки <> Неопределено Тогда
				TypeString = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
				If TypeString = "Product" Then
					НоваяСтрока.ProductType = Enums.InventoryTypes.Inventory;
				ElsIf TypeString = "Service" Then
					НоваяСтрока.ProductType = Enums.InventoryTypes.NonInventory;
				EndIf;
			КонецЕсли;
			
			НомерКолонки = НайтиНомерКолонкиРеквизита("Item code [char(50)]");
			Если НомерКолонки <> Неопределено Тогда
				НоваяСтрока.ProductCode = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
			КонецЕсли;

			НомерКолонки = НайтиНомерКолонкиРеквизита("Item description [char(150)]");
			Если НомерКолонки <> Неопределено Тогда
				НоваяСтрока.ProductDescription = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
			КонецЕсли;

			НомерКолонки = НайтиНомерКолонкиРеквизита("Income account [ref]");
			Если НомерКолонки <> Неопределено Тогда
				IncomeAcctString = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
				If IncomeAcctString <> "" Then
					НоваяСтрока.ProductIncomeAcct = ChartsOfAccounts.ChartOfAccounts.FindByCode(IncomeAcctString);
				Else
					НоваяСтрока.ProductIncomeAcct = Constants.IncomeAccount.Get();
				EndIf;
			Иначе
				НоваяСтрока.ProductIncomeAcct = Constants.IncomeAccount.Get();
			КонецЕсли;	
			
			НомерКолонки = НайтиНомерКолонкиРеквизита("Inventory or expense account [ref]");
			Если НомерКолонки <> Неопределено Тогда
				InvAcctString = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
				If InvAcctString <> "" Then
					НоваяСтрока.ProductInvOrExpenseAcct = ChartsOfAccounts.ChartOfAccounts.FindByCode(InvAcctString);
				ElsIf TypeString = "Product" Then
					НоваяСтрока.ProductInvOrExpenseAcct = GeneralFunctions.InventoryAcct(Enums.InventoryTypes.Inventory);	
				ElsIf TypeString = "Service" Then
					НоваяСтрока.ProductInvOrExpenseAcct = GeneralFunctions.InventoryAcct(Enums.InventoryTypes.NonInventory);
				EndIf;
			Иначе
				If TypeString = "Product" Then
					НоваяСтрока.ProductInvOrExpenseAcct = GeneralFunctions.InventoryAcct(Enums.InventoryTypes.Inventory);	
				ElsIf TypeString = "Service" Then
					НоваяСтрока.ProductInvOrExpenseAcct = GeneralFunctions.InventoryAcct(Enums.InventoryTypes.NonInventory);
				EndIf;
			КонецЕсли;

			НомерКолонки = НайтиНомерКолонкиРеквизита("COGS account [ref]");
			Если НомерКолонки <> Неопределено Тогда
				COGSAcctString = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
				If COGSAcctString <> "" Then
					НоваяСтрока.ProductCOGSAcct = ChartsOfAccounts.ChartOfAccounts.FindByCode(COGSAcctString);
				ElsIf TypeString = "Product" Then
					НоваяСтрока.ProductCOGSAcct = GeneralFunctions.GetDefaultCOGSAcct();
				ElsIf TypeString = "Service" Then
					НоваяСтрока.ProductCOGSAcct = GeneralFunctions.GetEmptyAcct();	
				EndIf;
			Иначе
				If TypeString = "Product" Then
					НоваяСтрока.ProductCOGSAcct = GeneralFunctions.GetDefaultCOGSAcct();
				ElsIf TypeString = "Service" Then
					НоваяСтрока.ProductCOGSAcct = GeneralFunctions.GetEmptyAcct();	
				EndIf;

			КонецЕсли;

			НомерКолонки = НайтиНомерКолонкиРеквизита("Price [num]");
			Если НомерКолонки <> Неопределено Тогда
				PriceString = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
				If PriceString <> "" Then
					НоваяСтрока.ProductPrice = PriceString;
				EndIf;
			КонецЕсли;
			
			НомерКолонки = НайтиНомерКолонкиРеквизита("Qty [num]");
			Если НомерКолонки <> Неопределено Тогда
				НоваяСтрока.ProductQty = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);	
			КонецЕсли;
			
			НомерКолонки = НайтиНомерКолонкиРеквизита("Value [num]");
			Если НомерКолонки <> Неопределено Тогда
				НоваяСтрока.ProductValue = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);	
			КонецЕсли;

			//НомерКолонки = НайтиНомерКолонкиРеквизита("Preferred vendor [ref]");
			//Если НомерКолонки <> Неопределено Тогда
			//	VendorString = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
			//	If VendorString <> "" Then
			//		НоваяСтрока.ProductPreferredVendor = Catalogs.Companies.FindByDescription(VendorString);
			//	EndIf;
			//КонецЕсли;

			НомерКолонки = НайтиНомерКолонкиРеквизита("Category [ref]");
			Если НомерКолонки <> Неопределено Тогда
				ProductCat = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
				If ProductCat <> "" Then
					НоваяСтрока.ProductCategory = Catalogs.ProductCategories.FindByDescription(ProductCat);
				EndIf;
			КонецЕсли;

			НомерКолонки = НайтиНомерКолонкиРеквизита("UoM [ref]");
			Если НомерКолонки <> Неопределено Тогда
				ProductUM = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);
				If ProductUM <> "" Then
					НоваяСтрока.ProductUoM = Catalogs.UM.FindByDescription(ProductUM);
				EndIf;
			КонецЕсли;

			НомерКолонки = НайтиНомерКолонкиРеквизита("CF1String [char(100)]");
			Если НомерКолонки <> Неопределено Тогда
				НоваяСтрока.ProductCF1String = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);	
			КонецЕсли;
			
			НомерКолонки = НайтиНомерКолонкиРеквизита("CF1Num [num]");
			Если НомерКолонки <> Неопределено Тогда
				НоваяСтрока.ProductCF1Num = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);	
			КонецЕсли;

			НомерКолонки = НайтиНомерКолонкиРеквизита("CF2String [char(100)]");
			Если НомерКолонки <> Неопределено Тогда
				НоваяСтрока.ProductCF2String = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);	
			КонецЕсли;
			
			НомерКолонки = НайтиНомерКолонкиРеквизита("CF2Num [num]");
			Если НомерКолонки <> Неопределено Тогда
				НоваяСтрока.ProductCF2Num = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);	
			КонецЕсли;

			НомерКолонки = НайтиНомерКолонкиРеквизита("CF3String [char(100)]");
			Если НомерКолонки <> Неопределено Тогда
				НоваяСтрока.ProductCF3String = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);	
			КонецЕсли;
			
			НомерКолонки = НайтиНомерКолонкиРеквизита("CF3Num [num]");
			Если НомерКолонки <> Неопределено Тогда
				НоваяСтрока.ProductCF3Num = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);	
			КонецЕсли;
			
			НомерКолонки = НайтиНомерКолонкиРеквизита("CF4String [char(100)]");
			Если НомерКолонки <> Неопределено Тогда
				НоваяСтрока.ProductCF4String = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);	
			КонецЕсли;
			
			НомерКолонки = НайтиНомерКолонкиРеквизита("CF4Num [num]");
			Если НомерКолонки <> Неопределено Тогда
				НоваяСтрока.ProductCF4Num = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);	
			КонецЕсли;
			
			НомерКолонки = НайтиНомерКолонкиРеквизита("CF5String [char(100)]");
			Если НомерКолонки <> Неопределено Тогда
				НоваяСтрока.ProductCF5String = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);	
			КонецЕсли;
			
			НомерКолонки = НайтиНомерКолонкиРеквизита("CF5Num [num]");
			Если НомерКолонки <> Неопределено Тогда
				НоваяСтрока.ProductCF5Num = СокрЛП(Источник[СчетчикСтрок][НомерКолонки - 1]);	
			КонецЕсли;
			
		EndIf;
				
	КонецЦикла;
		
	Object.DataList.Загрузить(ТаблицаЗагрузки);
	
КонецПроцедуры

&НаСервере
Функция НайтиНомерКолонкиРеквизита(ИмяРеквизита)
	
	НайденныйРеквизит = Неопределено;
	НайденныеСтроки = Реквизиты.НайтиСтроки(Новый Структура("ИмяРеквизита", ИмяРеквизита));
	Если НайденныеСтроки.Количество() > 0 Тогда
		НайденныйРеквизит = НайденныеСтроки[0].НомерКолонки;
	КонецЕсли;
	
	Возврат ?(НайденныйРеквизит = 0, Неопределено, НайденныйРеквизит);
	
КонецФункции


&НаСервере
Процедура Загрузить(Отказ)
	
	Если Object.DataList.Количество() = 0 Тогда
		Возврат;
	КонецЕсли;
		
	Если Отказ Тогда
		Возврат;
	КонецЕсли;
	
	If ActionType = "Account balances" Then	
		
		TotalDebit = 0;
		
		NewGJE = Documents.GeneralJournalEntry.CreateDocument();
		NewGJE.Date = Date;
		NewGJE.Currency = GeneralFunctionsReusable.DefaultCurrency();
		NewGJE.ExchangeRate = 1;
		
		Для каждого DataLine Из Object.DataList Цикл
			
			NewLine = NewGJE.LineItems.Add();
			
			NewLine.Account = DataLine.BalancesAccount;
			NewLine.AccountDescription = DataLine.BalancesAccount.Description;
			If DataLine.BalancesDebit = 0 Then
				NewLine.AmountCr = DataLine.BalancesCredit;
				TotalDebit = TotalDebit + NewLine.AmountDr;
			ElsIf DataLine.BalancesCredit = 0 Then
				NewLine.AmountDr = DataLine.BalancesDebit;
			EndIf;
		
		КонецЦикла;
		
		NewGJE.DocumentTotal = TotalDebit;
		NewGJE.DocumentTotalRC = TotalDebit;
		NewGJE.Write(DocumentWriteMode.Posting);
		
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
			
			If DataLine.ФлагЗагрузки = True Then
			
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
			
			If DataLine.ФлагЗагрузки Then
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
			If DataLine.ФлагЗагрузки = True Then
				ItemLine = New Structure("CustomerType, CustomerDescription, CustomerNotes, " +
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
		Params.Add(IncomeAccount);
		Params.Add(ExpenseAccount);
		Params.Add(ARAccount);
		Params.Add(APAccount);
		Params.Add(ItemDataSet);
		LongActions.ExecuteInBackground("GeneralFunctions.CreateCustomerVendorCSV", Params);
		//CreateCustomerVendorCSV(IncomeAccount, ExpenseAccount, ARAccount, APAccount, ItemDataSet);
		
	EndIf;

	
	Для каждого DataLine Из Object.DataList Цикл
		
		Если НЕ DataLine.ФлагЗагрузки Тогда
			Продолжить;
		КонецЕсли;
		
		If ActionType = "Chart of accounts" Then
			
			If DataLine.CofAUpdate = ChartsOfAccounts.ChartOfAccounts.EmptyRef() Then
				
				NewAccount = ChartsOfAccounts.ChartOfAccounts.CreateAccount();
				NewAccount.Code = DataLine.CofACode;
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
			
		ElsIf ActionType = "Invoice payments / Checks (header)" Then
			
			NewIP = Documents.InvoicePayment.CreateDocument();
			
			NewIP.Company = DataLine.IPHeaderVendor;
			//NewIP.CompanyCode = DataLine.IPHeaderVendor.Code;
			NewIP.DocumentTotal = DataLine.IPHeaderAmount;
			NewIP.DocumentTotalRC = DataLine.IPHeaderAmount;
			NewIP.BankAccount = Constants.BankAccount.Get();
			NewIP.Currency = GeneralFunctionsReusable.DefaultCurrency();
			NewIP.PaymentMethod = Catalogs.PaymentMethods.Visa;
			NewIP.Number = DataLine.IPHeaderNumber;
			NewIP.Date = DataLine.IPHeaderDate;
			NewIP.Memo = DataLine.IPHeaderMemo;
			
			NewIP.Write();
			
		ElsIf ActionType = "Purchase invoices (detail)" Then
			
			InvoiceDoc = Dataline.PIDetailHeader.GetObject();
			
			NewLine = InvoiceDoc.Accounts.Add();
			NewLine.Account = DataLine.PIDetailAccount;
			NewLine.Amount = DataLine.PIDetailAmount;
			NewLine.Memo = DataLine.PIDetailMemo;
			NewLine.AccountDescription = NewLine.Account.Description;
			
			InvoiceDoc.Write();
			
		ElsIf ActionType = "Purchase invoices (header)" Then
			
			NewPI = Documents.PurchaseInvoice.CreateDocument();
			
			NewPI.Company = Dataline.PIHeaderVendor;
			//NewPI.CompanyCode = Dataline.PIHeaderVendor.Code;
			NewPI.DocumentTotal = Dataline.PIHeaderAmount;
			NewPI.DocumentTotalRC = Dataline.PIHeaderAmount;
			NewPI.Currency = GeneralFunctionsReusable.DefaultCurrency();
			NewPI.ExchangeRate = 1;
			NewPI.Location = Catalogs.Locations.MainWarehouse;
			NewPI.DueDate = Dataline.PIHeaderDueDate;
			NewPI.Terms = Dataline.PIHeaderTerms;
			NewPI.Memo = Dataline.PIHeaderMemo;
			NewPI.APAccount = NewPI.Currency.DefaultAPAccount;
			NewPI.Number = Dataline.PIHeaderNumber;
			NewPI.Date = Dataline.PIHeaderDate;
			
			NewPI.Write();
				
		ElsIf ActionType = "GJ entries (header)" Then
			
			NewGJ = Documents.GeneralJournalEntry.CreateDocument();
			If NOT DataLine.GJHeaderNumber = "" Then
				NewGJ.Number = DataLine.GJHeaderNumber;
			EndIf;
			NewGJ.Date = DataLine.GJHeaderDate;
			NewGJ.DueDate = DataLine.GJHeaderDate;
			NewGJ.DocumentTotalRC = DataLine.GJHeaderAmount;
			NewGJ.DocumentTotal = DataLine.GJHeaderAmount;
			NewGJ.Currency = GeneralFunctionsReusable.DefaultCurrency();
			NewGJ.ExchangeRate = 1;
			NewGJ.Memo = DataLine.GJHeaderMemo;
			If NOT DataLine.GJHeaderARorAP = Undefined Then
				NewGJ.ARorAP = DataLine.GJHeaderARorAP
			EndIf;
			NewGJ.Write();
			
		ElsIf ActionType = "GJ entries (detail)" Then
			
			GJEntry = DataLine.GJDetailHeader.GetObject();
			NewLine = GJEntry.LineItems.Add();
			NewLine.Account = DataLine.GJDetailAccount;
			NewLine.AccountDescription = DataLine.GJDetailAccount.Description;
			NewLine.AmountDr = DataLine.GJDetailDr;
			NewLine.AmountCr = DataLine.GJDetailCr;
			NewLine.Memo = DataLine.GJDetailMemo;
			If NOT DataLine.GJDetailCompany = Undefined Then
				NewLine.Company = DataLine.GJDetailCompany;
			EndIf;
			GJEntry.Write();
			
		ElsIf ActionType = "Sales invoices (header)" Then
			
			If CreditMemo = True Then
				
				NewInvoice = Documents.SalesReturn.CreateDocument();
				NewInvoice.Number = DataLine.SIHeaderNumber;
				NewInvoice.Date = DataLine.SIHeaderDate;
				NewInvoice.Company = DataLine.SIHeaderCustomer;
				//NewInvoice.CompanyCode = DataLine.SIHeaderCustomer.Code;
				NewInvoice.DocumentTotal = DataLine.SIHeaderAmount;
				NewInvoice.Currency = Constants.DefaultCurrency.Get();
				NewInvoice.ExchangeRate = 1;
				NewInvoice.DocumentTotalRC = DataLine.SIHeaderAmount;
				NewInvoice.Location = Catalogs.Locations.MainWarehouse;
				NewInvoice.DueDate = DataLine.SIHeaderDueDate;
				//NewInvoice.Terms = DataLine.SIHeaderTerms;
				NewInvoice.Memo = DataLine.SIHeaderMemo;
				NewInvoice.ARAccount = ARAccount;
				NewInvoice.RefNum = DataLine.SIHeaderPO;
				NewInvoice.Write();
			
			Else
			
				If ARBegBal = True Then
				
					NewInvoice = Documents.SalesInvoice.CreateDocument();
					NewInvoice.Number = DataLine.SIHeaderNumber;
					NewInvoice.Date = DataLine.SIHeaderDate;
					NewInvoice.Company = DataLine.SIHeaderCustomer;
					//NewInvoice.CompanyCode = DataLine.SIHeaderCustomer.Code;
					NewInvoice.DocumentTotal = DataLine.SIHeaderAmount;
					NewInvoice.Currency = Constants.DefaultCurrency.Get();
					NewInvoice.ExchangeRate = 1;
					NewInvoice.DocumentTotalRC = DataLine.SIHeaderAmount;
					NewInvoice.Location = Catalogs.Locations.MainWarehouse;
					NewInvoice.DueDate = DataLine.SIHeaderDueDate;
					NewInvoice.Terms = DataLine.SIHeaderTerms;
					NewInvoice.Memo = "imported beg. balances";
					NewInvoice.ARAccount = ARAccount;
					NewInvoice.RefNum = DataLine.SIHeaderPO;
					NewInvoice.BegBal = True;
					NewInvoice.Write(DocumentWriteMode.Posting);
					
				Else
					
					NewInvoice = Documents.SalesInvoice.CreateDocument();
					NewInvoice.Number = DataLine.SIHeaderNumber;
					NewInvoice.Date = DataLine.SIHeaderDate;
					NewInvoice.Company = DataLine.SIHeaderCustomer;
					//NewInvoice.CompanyCode = DataLine.SIHeaderCustomer.Code;
					NewInvoice.DocumentTotal = DataLine.SIHeaderAmount;
					NewInvoice.Currency = Constants.DefaultCurrency.Get();
					NewInvoice.ExchangeRate = 1;
					NewInvoice.DocumentTotalRC = DataLine.SIHeaderAmount;
					NewInvoice.Location = Catalogs.Locations.MainWarehouse;
					NewInvoice.DueDate = DataLine.SIHeaderDueDate;
					NewInvoice.Terms = DataLine.SIHeaderTerms;
					NewInvoice.Memo = DataLine.SIHeaderMemo;
					NewInvoice.ARAccount = ARAccount;
					NewInvoice.RefNum = DataLine.SIHeaderPO;
					NewInvoice.Write();
					
				EndIf;
				
			EndIf;
			
		ElsIf ActionType = "Sales invoices (detail)" Then
			
			InvoiceDoc = Dataline.SIDetailHeader.GetObject();
			NewLine = InvoiceDoc.LineItems.Add();
			NewLine.Product = DataLine.SIDetailProduct;
			NewLine.ProductDescription = DataLine.SIDetailProduct.Description;
			NewLine.Price = DataLine.SIDetailPrice;
			NewLine.Quantity = DataLine.SIDetailQty;
			NewLine.LineTotal = DataLine.SIDetailPrice * DataLine.SIDetailQty; 
			//NewLine.SalesTaxType = US_FL.GetSalesTaxType(DataLine.SIDetailProduct);
			//NewLine.TaxableAmount = 0;
			NewLine.VATCode = CommonUse.GetAttributeValue(DataLine.SIDetailProduct, "SalesVATCode");
			NewLine.VAT = 0;
			
			InvoiceDoc.Write();
	
		ElsIf ActionType = "Checks" Then
			
			NewCheck = Documents.Check.CreateDocument();
			NewCheck.Date = DataLine.CheckDate;
			NewCheck.Number = DataLine.CheckNumber;
			NewCheck.BankAccount = DataLine.CheckBankAccount;
			NewCheck.Memo = DataLine.CheckMemo;
			NewCheck.Company = DataLine.CheckVendor;
			NewCheck.DocumentTotalRC = DataLine.CheckLineAmount;
			NewCheck.DocumentTotal = DataLine.CheckLineAmount;
			NewCheck.ExchangeRate = 1;
			NewLine = NewCheck.LineItems.Add();
			NewLine.Account = DataLine.CheckLineAccount;
			NewLine.AccountDescription = DataLine.CheckLineAccount.Description;
			NewLine.Amount = DataLine.CheckLineAmount;
			NewLine.Memo = DataLine.CheckLineMemo;
			NewCheck.Write();
			
		//ElsIf ActionType = "CustomersVendors" Then
			
			//NewCompany = Catalogs.Companies.CreateItem();
			//If DataLine.CustomerCode <> "" Then
			//	NewCompany.Code = DataLine.CustomerCode;
			//EndIf;
			//NewCompany.Description = DataLine.CustomerDescription;
			//
			//If DataLine.CustomerType = 0 Then
			//	NewCompany.Customer = True;
			//ElsIf DataLine.CustomerType = 1 Then
			//	NewCompany.Vendor = True;
			//ElsIf DataLine.CustomerType = 2 Then
			//	NewCompany.Customer = True;
			//	NewCompany.Vendor = True;
			//Else
			//	NewCompany.Customer = True;
			//EndIf;
			//
			//NewCompany.DefaultCurrency = Constants.DefaultCurrency.Get();
			//NewCompany.Terms = DataLine.CustomerTerms;
			//NewCompany.Notes = DataLine.CustomerNotes;
			//NewCompany.USTaxID = DataLine.CustomerVendorTaxID;
			//
			//If DataLine.CustomerCF1String <> "" Then 
			//	NewCompany.CF1String = DataLine.CustomerCF1String;
			//EndIf;
			//NewCompany.CF1Num = DataLine.ProductCF1Num;

			//If DataLine.CustomerCF2String <> "" Then 
			//	NewCompany.CF2String = DataLine.CustomerCF2String;
			//EndIf;
			//NewCompany.CF2Num = DataLine.CustomerCF2Num;

			//If DataLine.CustomerCF3String <> "" Then 
			//	NewCompany.CF3String = DataLine.CustomerCF3String;
			//EndIf;
			//NewCompany.CF3Num = DataLine.CustomerCF3Num;

			//If DataLine.CustomerCF4String <> "" Then 
			//	NewCompany.CF4String = DataLine.CustomerCF4String;
			//EndIf;
			//NewCompany.CF4Num = DataLine.CustomerCF4Num;

			//If DataLine.CustomerCF5String <> "" Then 
			//	NewCompany.CF5String = DataLine.CustomerCF5String;
			//EndIf;
			//NewCompany.CF5Num = DataLine.CustomerCF5Num;

			//If IncomeAccount <> ChartsOfAccounts.ChartOfAccounts.EmptyRef() Then
			//	NewCompany.IncomeAccount = IncomeAccount;
			//Else
			//EndIf;
			//
			//If ARAccount <> ChartsOfAccounts.ChartOfAccounts.EmptyRef() Then
			//	NewCompany.ARAccount = ARAccount;
			//Else
			//EndIf;
			//
			//If ExpenseAccount <> ChartsOfAccounts.ChartOfAccounts.EmptyRef() Then
			//	NewCompany.ExpenseAccount = ExpenseAccount;
			//Else
			//EndIf;
			//
			//If APAccount <> ChartsOfAccounts.ChartOfAccounts.EmptyRef() Then
			//	NewCompany.APAccount = APAccount;
			//Else
			//EndIf;
			//
			//NewCompany.Write();
			//
			//AddressLine = Catalogs.Addresses.CreateItem();
			//AddressLine.Owner = NewCompany.Ref;
			//If DataLine.CustomerAddressID = "" Then
			//	AddressLine.Description = "Primary";
			//Else
			//	AddressLine.Description = DataLine.CustomerAddressID;
			//EndIf;
			//AddressLine.FirstName = DataLine.CustomerFirstName;
			//AddressLine.MiddleName = DataLine.CustomerMiddleName;
			//AddressLine.LastName = DataLine.CustomerLastName;
			//AddressLine.Phone = DataLine.CustomerPhone;
			//AddressLine.Cell = DataLine.CustomerCell;
			//AddressLine.Fax = DataLine.CustomerFax;
			//AddressLine.Email = DataLine.CustomerEmail;
			//AddressLine.AddressLine1 = DataLine.CustomerAddressLine1;
			//AddressLine.AddressLine2 = DataLine.CustomerAddressLine2;
			//AddressLine.City = DataLine.CustomerCity;
			//AddressLine.State = DataLine.CustomerState;
			//AddressLine.Country = DataLine.CustomerCountry;
			//AddressLine.ZIP = DataLine.CustomerZIP;
			//AddressLine.Notes = DataLine.CustomerAddressNotes;
			//If DataLine.CustomerShippingAddressID = "" Then
			//	AddressLine.DefaultShipping = True;
			//EndIf;
			//AddressLine.DefaultBilling = True;
			//AddressLine.Write();
			//
			//If DataLine.CustomerShippingAddressID <> "" Then
			//	AddressLine = Catalogs.Addresses.CreateItem();
			//	AddressLine.Owner = NewCompany.Ref;
			//	AddressLine.Description = DataLine.CustomerShippingAddressID;
			//	AddressLine.FirstName = DataLine.CustomerShippingFirstName;
			//	AddressLine.MiddleName = DataLine.CustomerShippingMiddleName;
			//	AddressLine.LastName = DataLine.CustomerShippingLastName;
			//	AddressLine.Phone = DataLine.CustomerShippingPhone;
			//	AddressLine.Cell = DataLine.CustomerShippingCell;
			//	AddressLine.Fax = DataLine.CustomerShippingFax;
			//	AddressLine.Email = DataLine.CustomerShippingEmail;
			//	AddressLine.AddressLine1 = DataLine.CustomerShippingAddressLine1;
			//	AddressLine.AddressLine2 = DataLine.CustomerShippingAddressLine2;
			//	AddressLine.City = DataLine.CustomerShippingCity;
			//	AddressLine.State = DataLine.CustomerShippingState;
			//	AddressLine.Country = DataLine.CustomerShippingCountry;
			//	AddressLine.ZIP = DataLine.CustomerShippingZIP;
			//	AddressLine.Notes = DataLine.CustomerShippingAddressNotes;
			//	AddressLine.DefaultShipping = True;
			//	AddressLine.Write();	
			//EndIf
			
		//ElsIf ActionType = "Items" Then
		//	
		//	NewProduct = Catalogs.Products.CreateItem();
		//	NewProduct.Type = DataLine.ProductType;
		//	NewProduct.Code = DataLine.ProductCode;
		//	NewProduct.Description = DataLine.ProductDescription;
		//	NewProduct.IncomeAccount = DataLine.ProductIncomeAcct;
		//	NewProduct.InventoryOrExpenseAccount = DataLine.ProductInvOrExpenseAcct;
		//	NewProduct.COGSAccount = DataLine.ProductCOGSAcct;
		//	NewProduct.PurchaseVATCode = Constants.DefaultPurchaseVAT.Get();
		//	NewProduct.SalesVATCode = Constants.DefaultSalesVAT.Get();
		//	//NewProduct.api_code = GeneralFunctions.NextProductNumber();
		//	NewProduct.Category = DataLine.ProductCategory;
		//	NewProduct.UM = DataLine.ProductUoM;
		//	If DataLine.ProductPreferredVendor <> Catalogs.Companies.EmptyRef() Then
		//		NewProduct.PreferredVendor = DataLine.ProductPreferredVendor;
		//	EndIf;
		//	
		//	If DataLine.ProductCF1String <> "" Then 
		//		NewProduct.CF1String = DataLine.ProductCF1String;
		//	EndIf;
		//	NewProduct.CF1Num = DataLine.ProductCF1Num;
		//	
		//	If DataLine.ProductCF2String <> "" Then 
		//		NewProduct.CF2String = DataLine.ProductCF2String;
		//	EndIf;
		//	NewProduct.CF2Num = DataLine.ProductCF2Num;
		//	
		//	If DataLine.ProductCF3String <> "" Then 
		//		NewProduct.CF3String = DataLine.ProductCF3String;
		//	EndIf;
		//	NewProduct.CF3Num = DataLine.ProductCF3Num;
		//	
		//	If DataLine.ProductCF4String <> "" Then 
		//		NewProduct.CF4String = DataLine.ProductCF4String;
		//	EndIf;
		//	NewProduct.CF4Num = DataLine.ProductCF4Num;
		//	
		//	If DataLine.ProductCF5String <> "" Then 
		//		NewProduct.CF5String = DataLine.ProductCF5String;
		//	EndIf;
		//	NewProduct.CF5Num = DataLine.ProductCF5Num;

		//	If NewProduct.Type = Enums.InventoryTypes.Inventory Then
		//		NewProduct.CostingMethod = Enums.InventoryCosting.WeightedAverage;
		//	EndIf;
		//	NewProduct.Write();
		//	
		//	If DataLine.ProductPrice <> 0 Then
		//		RecordSet = InformationRegisters.PriceList.CreateRecordSet();
		//		RecordSet.Filter.Product.Set(NewProduct.Ref);
		//		RecordSet.Filter.Period.Set(Date);
		//		NewRecord = RecordSet.Add();
		//		NewRecord.Period = Date;
		//		NewRecord.Product = NewProduct.Ref;
		//		NewRecord.Price = DataLine.ProductPrice;
		//		RecordSet.Write();
		//	EndIf;
		//	
		//	If DataLine.ProductQty <> 0 Then
		//		IBB = Documents.ItemAdjustment.CreateDocument();
		//		IBB.Product = NewProduct.Ref;
		//		IBB.Location = Catalogs.Locations.MainWarehouse;
		//		IBB.Quantity = DataLine.ProductQty;
		//		IBB.Value = Dataline.ProductValue;
		//		IBB.Date = Date2;
		//		IBB.Write(DocumentWriteMode.Posting);
		//	EndIf;
			
		EndIf;
	
	КонецЦикла;
	
	Если Отказ Тогда
		Сообщить("There were errors during importing. The import will not be performed.");
		Возврат;
	КонецЕсли;
	
	//Если ВидОперации = "Остатки" Тогда
	//	ДокументВводОстатков.Записать(РежимЗаписиДокумента.Проведение);
	//КонецЕсли;
	
	
КонецПроцедуры

&НаКлиенте
Процедура ActionTypeOnChange(Элемент)
	
	ЗаполнитьРеквизиты();
	
КонецПроцедуры

&НаКлиенте
Процедура ПриветствиеДалее(Команда)
	
	Если ПодключитьРасширениеРаботыСФайлами() И
	  НЕ ЗначениеЗаполнено(ПутьКФайлу) Тогда
		ТекстСообщения = НСтр("en='Select the file!';de='Datei auswählen'");
		ShowMessageBox(,ТекстСообщения);
		Возврат;
	КонецЕсли;
	
	Если Реквизиты.Количество() = 0 Тогда
		ЗаполнитьРеквизиты();
	КонецЕсли;
	
	Элементы.ГруппаСопоставления.Заголовок = ПутьКФайлу;
	ПрочитатьФайлИсточник();
	
	Если НЕ ЗначениеЗаполнено(SourceAddress) Тогда
		Возврат;
	КонецЕсли;
	
	ЗаполнитьПредставлениеИсточника();
	Элементы.ЭтапыЗагрузки.ТекущаяСтраница = Элементы.ЭтапыЗагрузки.ПодчиненныеЭлементы.Сопоставление;
	
КонецПроцедуры

&НаКлиенте
Процедура СопоставлениеНазад(Команда)
	
	Элементы.ЭтапыЗагрузки.ТекущаяСтраница = Элементы.ЭтапыЗагрузки.ПодчиненныеЭлементы.Приветствие;
	
КонецПроцедуры

&НаКлиенте
Процедура СопоставлениеДалее(Команда)
	
	CheckExpensifyVendor();
	
	Для СчетчикРеквизитов = 0 по Реквизиты.Количество() - 1 Цикл
		Если Реквизиты[СчетчикРеквизитов].Обязательный и Реквизиты[СчетчикРеквизитов].НомерКолонки = 0 Тогда
			Сообщение = Новый СообщениеПользователю;
			Сообщение.Текст = "Please fill out the columns for required attributes";
			Сообщение.Поле = "Реквизиты[0].НомерКолонки";
			Сообщение.Сообщить(); 
			Возврат;
		КонецЕсли; 
	КонецЦикла;
	
	ЗаполнитьСписокЗагрузки();
	Элементы.ЭтапыЗагрузки.ТекущаяСтраница = Элементы.ЭтапыЗагрузки.ПодчиненныеЭлементы.Создание;
	
КонецПроцедуры

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

&НаКлиенте
Процедура СозданиеОтметитьВсе(Команда)
	
	Для каждого Элемент Из Object.DataList Цикл
		Элемент.ФлагЗагрузки = Истина;
	КонецЦикла; 
	
КонецПроцедуры

&НаКлиенте
Процедура СозданиеСнятьОтметку(Команда)
	
	Для каждого Элемент Из Object.DataList Цикл
		Элемент.ФлагЗагрузки = Ложь;
	КонецЦикла;
	
КонецПроцедуры

&НаКлиенте
Процедура СозданиеНазад(Команда)
	
	Элементы.ЭтапыЗагрузки.ТекущаяСтраница = Элементы.ЭтапыЗагрузки.ПодчиненныеЭлементы.Сопоставление;
	
КонецПроцедуры

&НаКлиенте
Процедура СозданиеВперед(Команда)
	
	Отказ = Ложь;
	ОчиститьСообщения();
	Загрузить(Отказ);
	Если НЕ Отказ Тогда
		Элементы.ЭтапыЗагрузки.ТекущаяСтраница = Элементы.ЭтапыЗагрузки.ПодчиненныеЭлементы.Завершение;
	КонецЕсли;
	
КонецПроцедуры

&НаКлиенте
Процедура СсылкаНаСписокНажатие(Элемент)
	
	If ActionType = "CustomersVendors" Then
		OpenForm("Catalog.Companies.ListForm");
		
	ElsIf ActionType = "Chart of accounts" Then		
		OpenForm("ChartOfAccounts.ChartOfAccounts.ListForm");
		
	ElsIf ActionType = "Account balances" Then
		OpenForm("Document.GeneralJournalEntry.ListForm");
		
	ElsIf ActionType = "Items" Then
		OpenForm("Catalog.Products.ListForm");
		
	ElsIf ActionType = "Sales invoices (header)" OR ActionType = "Sales invoices (detail)" Then
		OpenForm("Document.SalesInvoice.ListForm");
		
	ElsIf ActionType = "GJ entries (header)" Then
		OpenForm("Document.GeneralJournalEntry.ListForm");
		
	ElsIf ActionType = "GJ entries (detail)" Then
		OpenForm("Document.GeneralJournalEntry.ListForm");
		
	ElsIf ActionType = "Checks" Then
		OpenForm("Document.Check.ListForm");
		
	ElsIf ActionType =  "Purchase invoices (header)" OR ActionType = "Purchase invoices (detail)" OR ActionType = "Expensify" Then
		OpenForm("Document.PurchaseInvoice.ListForm");
		
	ElsIf ActionType = "Invoice payments / Checks (header)" OR ActionType = "Invoice payments / Checks (detail)" Then
		OpenForm("Document.InvoicePayment.ListForm");
	EndIf;
	
КонецПроцедуры

&НаКлиенте
Процедура ЗавершитьРаботу(Команда)
	
	ЭтаФорма.Закрыть();
	
КонецПроцедуры

&НаСервере
Процедура ПриСозданииНаСервере(Отказ, СтандартнаяОбработка)
	
	ВидОперации = Параметры.ВидОперации;
	ЗаполнитьРеквизиты();
	Date = CurrentDate();
	Date2 = CurrentDate();
	//IncomeAccount = Constants.IncomeAccount.Get();
	//ExpenseAccount = Constants.ExpenseAccount.Get();	
	
КонецПроцедуры

&НаКлиенте
Процедура ПриОткрытии(Отказ)
	
	Если НЕ ПодключитьРасширениеРаботыСФайлами() Тогда
		Элементы.ПутьКФайлу.Видимость = Ложь;
		Элементы.ПредупреждениеВыгрузка.Видимость = Истина;
	Иначе
		Элементы.ПутьКФайлу.Видимость = Истина;
		Элементы.ПредупреждениеВыгрузка.Видимость = Ложь;
	КонецЕсли;
	
КонецПроцедуры

&AtClient
Procedure MapToTemplateCV(Command)
	FormData = ThisForm.Реквизиты;
	NumOfColumns = FormData.Count();
	For i = 0 to NumOfColumns - 1 Do
		
		FormData[i].НомерКолонки = i + 1; 
		
	EndDo
EndProcedure


&AtClient
Procedure UnmapCV(Command)
	
	FormData = ThisForm.Реквизиты;
	NumOfColumns = FormData.Count();
	For i = 0 to NumOfColumns - 1 Do
		
		FormData[i].НомерКолонки = 0; 
		
	EndDo

EndProcedure

