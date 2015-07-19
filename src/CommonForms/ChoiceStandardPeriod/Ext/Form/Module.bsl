
////////////////////////////////////////////////////////////////////////////////
// ОБРАБОТЧИКИ СОБЫТИЙ ФОРМЫ

&НаСервере
Процедура OnCreateAtServer(Отказ, СтандартнаяОбработка)
	
	ЗаполнитьЗначенияСвойств(ЭтотОбъект, Параметры, "BeginOfPeriod,EndOfPeriod");
	BeginDateYear = ?(ЗначениеЗаполнено(EndOfPeriod), НачалоГода(EndOfPeriod), НачалоГода(ТекущаяДатаСеанса()));
	If Parameters.SelectMonths Then
		Items.SelectQuarter1.Visible 	= False;
		Items.SelectQuarter2.Visible 	= False;
		Items.SelectQuarter3.Visible	= False;
		Items.SelectQuarter4.Visible 	= False;
		Items.Quarter.Visible			= False;
		Items.SelectHalfYear1.Visible	= False;
		Items.Select9Months.Visible 	= False;
		Items.SelectYear.Visible		= False;
	EndIf;
	//--//ColorCurrentPeriod = ЦветаСтиля.ChoiceStandardPeriodФонКнопки;
	
КонецПроцедуры

&НаКлиенте
Процедура OnOpen(Отказ)
	
	УстановитьАктивныйПериод();
	
КонецПроцедуры

////////////////////////////////////////////////////////////////////////////////
// ОБРАБОТЧИКИ КОМАНД ФОРМЫ

&НаКлиенте
Процедура GoToYearBack(Команда)
	
	BeginDateYear = НачалоГода(BeginDateYear - 1);
	
	УстановитьАктивныйПериод();
	
КонецПроцедуры

&НаКлиенте
Процедура NavigateToForwardOfYear(Команда)
	
	BeginDateYear = КонецГода(BeginDateYear) + 1;
	
	УстановитьАктивныйПериод();
	
КонецПроцедуры

&НаКлиенте
Процедура SelectMonth1(Команда)
	
	SelectMonth(1);
	
КонецПроцедуры

&НаКлиенте
Процедура SelectMonth2(Команда)
	
	SelectMonth(2);
	
КонецПроцедуры

&НаКлиенте
Процедура SelectMonth3(Команда)
	
	SelectMonth(3);
	
КонецПроцедуры

&НаКлиенте
Процедура SelectMonth4(Команда)
	
	SelectMonth(4);
	
КонецПроцедуры

&НаКлиенте
Процедура SelectMonth5(Команда)
	
	SelectMonth(5);
	
КонецПроцедуры

&НаКлиенте
Процедура SelectMonth6(Команда)
	
	SelectMonth(6);
	
КонецПроцедуры

&НаКлиенте
Процедура SelectMonth7(Команда)
	
	SelectMonth(7);
	
КонецПроцедуры

&НаКлиенте
Процедура SelectMonth8(Команда)
	
	SelectMonth(8);
	
КонецПроцедуры

&НаКлиенте
Процедура SelectMonth9(Команда)
	
	SelectMonth(9);
	
КонецПроцедуры

&НаКлиенте
Процедура SelectMonth10(Команда)
	
	SelectMonth(10);
	
КонецПроцедуры

&НаКлиенте
Процедура SelectMonth11(Команда)
	
	SelectMonth(11);
	
КонецПроцедуры

&НаКлиенте
Процедура SelectMonth12(Команда)
	
	SelectMonth(12);
	
КонецПроцедуры

&НаКлиенте
Процедура SelectQuarter1(Команда)
	
	SelectQuarter(1);
	
КонецПроцедуры

&НаКлиенте
Процедура SelectQuarter2(Команда)
	
	SelectQuarter(2);
	
КонецПроцедуры

&НаКлиенте
Процедура SelectQuarter3(Команда)
	
	SelectQuarter(3);
	
КонецПроцедуры

&НаКлиенте
Процедура SelectQuarter4(Команда)
	
	SelectQuarter(4);
	
КонецПроцедуры

&НаКлиенте
Процедура SelectHalfYear1(Команда)
	
	SelectHalfYear(1);
	
КонецПроцедуры

&НаКлиенте
Процедура SelectHalfYear2(Команда)
	
	SelectHalfYear(2);
	
КонецПроцедуры

&НаКлиенте
Процедура Select9Months(Команда)

	BeginOfPeriod = BeginDateYear;
	EndOfPeriod  = Date(Год(BeginDateYear), 9 , 30);
	ВыполнитьВыборПериода();
	
КонецПроцедуры

&НаКлиенте
Процедура SelectYear(Команда)

	BeginOfPeriod = BeginDateYear;
	EndOfPeriod  = КонецГода(BeginDateYear);
	ВыполнитьВыборПериода();
	
КонецПроцедуры

////////////////////////////////////////////////////////////////////////////////
// СЛУЖЕБНЫЕ ПРОЦЕДУРЫ И ФУНКЦИИ

&НаКлиенте
Процедура УстановитьАктивныйПериод()

	Если НачалоМесяца(BeginOfPeriod) = НачалоМесяца(EndOfPeriod) Тогда
		НомерМесяца = Месяц(BeginOfPeriod);
		ТекущийЭлемент = Элементы["SelectMonth" + НомерМесяца];
	ИначеЕсли НачалоКвартала(BeginOfPeriod) = НачалоКвартала(EndOfPeriod) Тогда
		НомерМесяца = Месяц(BeginOfPeriod);
		НомерКвартала = Цел((НомерМесяца + 3) / 3);
		ТекущийЭлемент = Элементы["SelectQuarter" + НомерКвартала];
	ИначеЕсли НачалоГода(BeginOfPeriod) = НачалоГода(EndOfPeriod) Тогда
		НомерМесяцаНачала = Месяц(BeginOfPeriod);
		НомерМесяцаКонца  = Месяц(EndOfPeriod);
		Если НомерМесяцаНачала <= 3 И НомерМесяцаКонца <= 6 Тогда
			ТекущийЭлемент = Элементы["SelectHalfYear1"];
		ИначеЕсли НомерМесяцаНачала <= 3 И НомерМесяцаКонца <= 9 Тогда
			ТекущийЭлемент = Элементы["Select9Months"];
		Иначе
			ТекущийЭлемент = Элементы["SelectYear"];
		КонецЕсли;
	Иначе
		ТекущийЭлемент = Элементы["SelectYear"];
	КонецЕсли;

	ТекущийЭлемент.ЦветФона = ColorCurrentPeriod;
	
КонецПроцедуры

&НаКлиенте
Процедура ВыполнитьВыборПериода()

	РезультатВыбора = Новый Структура("BeginOfPeriod,EndOfPeriod", BeginOfPeriod, КонецДня(EndOfPeriod));
	ОповеститьОВыборе(РезультатВыбора);

КонецПроцедуры 

&НаКлиенте
Процедура SelectMonth(НомерМесяца)
	
	BeginOfPeriod = Date(Год(BeginDateYear), НомерМесяца, 1);
	EndOfPeriod  = КонецМесяца(BeginOfPeriod);
	
	ВыполнитьВыборПериода();
	
КонецПроцедуры

&НаКлиенте
Процедура SelectQuarter(НомерКвартала)
	
	BeginOfPeriod = Date(Год(BeginDateYear), 1 + (НомерКвартала - 1) * 3, 1);
	
	EndOfPeriod  = КонецКвартала(BeginOfPeriod);
	
	ВыполнитьВыборПериода();
	
КонецПроцедуры

&НаКлиенте
Процедура SelectHalfYear(НомерПолугодия)

	BeginOfPeriod = Date(Год(BeginDateYear), 1 + (НомерПолугодия - 1) * 6, 1);
	EndOfPeriod  = КонецМесяца(ДобавитьМесяц(BeginOfPeriod, 5));
	ВыполнитьВыборПериода();
	
КонецПроцедуры

