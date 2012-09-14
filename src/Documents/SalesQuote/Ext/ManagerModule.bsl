
Процедура Печать(МассивОбъектов, ПараметрыПечати, КоллекцияПечатныхФорм,
          ОбъектыПечати, ПараметрыВывода) Экспорт

     // Устанавливаем признак доступности печати покомплектно.
    ПараметрыВывода.ДоступнаПечатьПоКомплектно = Истина;

     // Проверяем, нужно ли для макета СчетЗаказа формировать табличный документ.
	 Если УправлениеПечатью.НужноПечататьМакет(КоллекцияПечатныхФорм, "SalesQuote") Тогда

         // Формируем табличный документ и добавляем его в коллекцию печатных форм.
         УправлениеПечатью.ВывестиТабличныйДокументВКоллекцию(КоллекцияПечатныхФорм,
             "SalesQuote", "Sales quote", ПечатьSalesInvoice(МассивОбъектов, ОбъектыПечати, "UMOff"));

	КонецЕсли;
	
	Если УправлениеПечатью.НужноПечататьМакет(КоллекцияПечатныхФорм, "SalesQuoteUM") Тогда

		 // Формируем табличный документ и добавляем его в коллекцию печатных форм.
		 УправлениеПечатью.ВывестиТабличныйДокументВКоллекцию(КоллекцияПечатныхФорм,
			 "SalesQuoteUM", "Sales quote", ПечатьSalesInvoice(МассивОбъектов, ОбъектыПечати, "UMOn"));

	КонецЕсли;
	
КонецПроцедуры
	 
Функция ПечатьSalesInvoice(МассивОбъектов, ОбъектыПечати, UMMode)
   // Создаем табличный документ и устанавливаем имя параметров печати.
   ТабличныйДокумент = Новый ТабличныйДокумент;
   ТабличныйДокумент.ИмяПараметровПечати = "ПараметрыПечати_SalesQuote";

   // Получаем запросом необходимые данные.
   Запрос = Новый Запрос();
   Запрос.Текст =
   "SELECT
   |	SalesQuote.Ref,
   |	SalesQuote.Company,
   |	SalesQuote.Date,
   |	SalesQuote.DocumentTotal,
   |	SalesQuote.SalesTax,
   |	SalesQuote.Number,
   |	SalesQuote.Currency,
   |	SalesQuote.VATTotal,
   |	SalesQuote.Bank,
   |	SalesQuote.LineItems.(
   |		Product,
   |		Descr,
   |		Quantity,
   |		UM,
   |		QuantityUM,
   |		Price,
   |		LineTotal
   |	)
   |FROM
   |	Document.SalesQuote AS SalesQuote
   |WHERE
   |	SalesQuote.Ref IN(&МассивОбъектов)";
   Запрос.УстановитьПараметр("МассивОбъектов", МассивОбъектов);
   Selection = Запрос.Выполнить().Выбрать();

   
   ПервыйДокумент = Истина;

    //360
	OurCompany = Catalogs.Companies.OurCompany;
	//360
   
   Пока Selection.Следующий() Цикл
     Если Не ПервыйДокумент Тогда
       // Все документы нужно выводить на разных страницах.
       ТабличныйДокумент.ВывестиГоризонтальныйРазделительСтраниц();
     КонецЕсли;
     ПервыйДокумент = Ложь;
     // Запомним номер строки, с которой начали выводить текущий документ.
     НомерСтрокиНачало = ТабличныйДокумент.ВысотаТаблицы + 1;
	 
	If UMMode = "UMOff" Then
	 	Макет = УправлениеПечатью.ПолучитьМакет("Document.SalesQuote.ПФ_MXL_SalesQuote");
	Else
		Макет = УправлениеПечатью.ПолучитьМакет("Document.SalesQuote.ПФ_MXL_SalesQuoteUM");
	EndIf;
		
	 ОбластьМакета = Макет.ПолучитьОбласть("Header");
	 
	OurCompanyInfo = PrintTemplates.ContactInfo(OurCompany);
	CounterpartyInfo = PrintTemplates.ContactInfo(Selection.Company);
	BankInfo = PrintTemplates.BankContactInfo(Selection.Bank);
	
	ОбластьМакета.Параметры.OurCompanyName = OurCompanyInfo.Name;
	ОбластьМакета.Параметры.OurCompanyAddress = OurCompanyInfo.Address;
	ОбластьМакета.Параметры.OurCompanyZIP = OurCompanyInfo.ZIP;
	ОбластьМакета.Параметры.OurCompanyPhone = OurCompanyInfo.Phone;
	ОбластьМакета.Параметры.OurCompanyEmail = OurCompanyInfo.Email;
	ОбластьМакета.Параметры.OurCompanyCountry = OurCompanyInfo.Country;
	
	ОбластьМакета.Параметры.CounterpartyName = CounterpartyInfo.Name;
	ОбластьМакета.Параметры.CounterpartyAddress = CounterpartyInfo.Address;
	ОбластьМакета.Параметры.CounterpartyZIP = CounterpartyInfo.ZIP;
	ОбластьМакета.Параметры.CounterpartyCountry = CounterpartyInfo.Country;
	 
	 ОбластьМакета.Параметры.Date = Selection.Date;
	 ОбластьМакета.Параметры.Number = Selection.Number;
	 
	 ТабличныйДокумент.Вывести(ОбластьМакета);

	 ОбластьМакета = Макет.ПолучитьОбласть("LineItemsHeader");
	 ТабличныйДокумент.Вывести(ОбластьМакета);
	 
	 SelectionLineItems = Selection.LineItems.Choose();
	 ОбластьМакета = Макет.ПолучитьОбласть("LineItems");
	 LineTotalSum = 0;
	 While SelectionLineItems.Next() Do
		 
		 ОбластьМакета.Parameters.Fill(SelectionLineItems);
		 LineTotal = SelectionLineItems.LineTotal;
		 LineTotalSum = LineTotalSum + LineTotal;
		 ТабличныйДокумент.Вывести(ОбластьМакета, SelectionLineItems.Level());

	 EndDo; 
	 
	Try 
		ОбластьМакета = Макет.ПолучитьОбласть("ExtraLines");
		ТабличныйДокумент.Вывести(ОбластьМакета);
	Except
	EndTry; 
 	 
	If Selection.VATTotal <> 0 Then;
		 ОбластьМакета = Макет.ПолучитьОбласть("Subtotal");
		 ОбластьМакета.Параметры.Subtotal = LineTotalSum - Selection.VATTotal;
		 ТабличныйДокумент.Вывести(ОбластьМакета);
		 
		 ОбластьМакета = Макет.ПолучитьОбласть("VAT");
		 ОбластьМакета.Параметры.VATTotal = Selection.VATTotal;
		 ТабличныйДокумент.Вывести(ОбластьМакета);
	EndIf; 
		 
	 ОбластьМакета = Макет.ПолучитьОбласть("Total");
	 ОбластьМакета.Параметры.DocumentTotal = LineTotalSum;
	 ТабличныйДокумент.Вывести(ОбластьМакета);

	 ОбластьМакета = Макет.ПолучитьОбласть("Currency");
	 ОбластьМакета.Параметры.Currency = Selection.Currency;
	 ТабличныйДокумент.Вывести(ОбластьМакета);
	 
	 ОбластьМакета = Макет.ПолучитьОбласть("Bank");
	 ОбластьМакета.Parameters.Fill(BankInfo);		
	 ТабличныйДокумент.Вывести(ОбластьМакета);
	 
     // В табличном документе необходимо задать имя области, в которую был 
     // выведен объект. Нужно для возможности печати покомплектно 
     УправлениеПечатью.ЗадатьОбластьПечатиДокумента(ТабличныйДокумент, НомерСтрокиНачало, ОбъектыПечати, Selection.Ref);

   КонецЦикла;
   
   Возврат ТабличныйДокумент;
   
КонецФункции
