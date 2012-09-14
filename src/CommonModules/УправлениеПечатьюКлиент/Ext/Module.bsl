﻿
// Выполнить команду печати, которая открывает результат в форме печати документов
Процедура ВыполнитьКомандуПечати(ИмяМенеджераПечати, ИменаМакетов, ПараметрКоманды, ВладелецФормы, ПараметрыПечати = Неопределено) Экспорт
	
	Если ТипЗнч(ПараметрКоманды) = Тип("Массив") Тогда
		ОбщегоНазначенияКлиентСервер.УдалитьВсеВхожденияТипаИзМассива(ПараметрКоманды, Тип("СтрокаГруппировкиДинамическогоСписка"));
	КонецЕсли;
	
	// Проверим количество объектов
	Если НЕ ПроверитьКоличествоПереданныхОбъектов(ПараметрКоманды) Тогда
		Возврат;
	КонецЕсли;
	
	// Получим ключ уникальности открываемой формы
	КлючУникальности = Строка(Новый УникальныйИдентификатор);
	
	ПараметрыОткрытия = Новый Структура("ИмяМенеджераПечати,ИменаМакетов,ПараметрКоманды,ПараметрыПечати");
	ПараметрыОткрытия.ИмяМенеджераПечати = ИмяМенеджераПечати;
	ПараметрыОткрытия.ИменаМакетов		 = ИменаМакетов;
	ПараметрыОткрытия.ПараметрКоманды	 = ПараметрКоманды;
	ПараметрыОткрытия.ПараметрыПечати	 = ПараметрыПечати;
	
	// Откроем форму печати документов
	ОткрытьФорму("ОбщаяФорма.ПечатьДокументов", ПараметрыОткрытия, ВладелецФормы, КлючУникальности);
	
КонецПроцедуры

// Выполнить команду печати, которая результат выводит на принтер
Процедура ВыполнитьКомандуПечатиНаПринтер(ИмяМенеджераПечати, ИменаМакетов, ПараметрКоманды, ПараметрыПечати = Неопределено) Экспорт

	Перем ТабличныеДокументы, ОбъектыПечати, ПараметрыВывода, Адрес, ОбъектыПечатиСоотв, Отказ;
	
	// Проверим количество объектов
	Если НЕ ПроверитьКоличествоПереданныхОбъектов(ПараметрКоманды) Тогда
		Возврат;
	КонецЕсли;
	
	ПараметрыВывода = Неопределено;
	
	// Сформируем табличные документы
#Если ТолстыйКлиентОбычноеПриложение Тогда
	УправлениеПечатью.СформироватьПечатныеФормыДляБыстройПечатиОбычноеПриложение(
			ИмяМенеджераПечати, ИменаМакетов, ПараметрКоманды, ПараметрыПечати,
			Адрес, ОбъектыПечатиСоотв, ПараметрыВывода, Отказ);
	Если НЕ Отказ Тогда
		ОбъектыПечати = Новый СписокЗначений;
		ТабличныеДокументы = ПолучитьИзВременногоХранилища(Адрес);
		Для Каждого ОбъектПечати Из ОбъектыПечатиСоотв Цикл
			ОбъектыПечати.Добавить(ОбъектПечати.Значение, ОбъектПечати.Ключ);
		КонецЦикла;
	КонецЕсли;
#Иначе
	УправлениеПечатью.СформироватьПечатныеФормыДляБыстройПечати(
			ИмяМенеджераПечати, ИменаМакетов, ПараметрКоманды, ПараметрыПечати,
			ТабличныеДокументы, ОбъектыПечати, ПараметрыВывода, Отказ);
#КонецЕсли
	
	Если Отказ Тогда
		ОбщегоНазначенияКлиентСервер.СообщитьПользователю(НСтр("en = 'No printing rights.'"));
		Возврат;
	КонецЕсли;
	
	// Распечатаем
	РаспечататьТабличныеДокументы(ТабличныеДокументы, ОбъектыПечати,
			ПараметрыВывода.ДоступнаПечатьПоКомплектно);
	
КонецПроцедуры

// Вывести табличные документы на принтер
Процедура РаспечататьТабличныеДокументы(ТабличныеДокументы, ОбъектыПечати, 
		знач ДоступнаПечатьПоКомплектно) Экспорт
	
	#Если ВебКлиент Тогда
		ДоступнаПечатьПоКомплектно = Ложь;
	#КонецЕсли
	
	Если ДоступнаПечатьПоКомплектно Тогда
		Для Каждого Элемент Из ОбъектыПечати Цикл
			ИмяОбласти = Элемент.Представление;
			Для Каждого Элемент Из ТабличныеДокументы Цикл
				ТабДок = Элемент.Значение;
				Область = ТабДок.Области.Найти(ИмяОбласти);
				Если Область = Неопределено Тогда
					Продолжить;
				КонецЕсли;
				ТабДок.ОбластьПечати = Область;
				ТабДок.Напечатать(Истина);
			КонецЦикла;
		КонецЦикла;
	Иначе
		Для Каждого Элемент Из ТабличныеДокументы Цикл
			ТабДок = Элемент.Значение;
			ТабДок.Напечатать(Истина);
		КонецЦикла;
	КонецЕсли;
	
КонецПроцедуры

// Перед выполнение команды печати проверить, был ли передан хотя бы один объект, так как
// для команд с множественным режимом использования может быть передан пустой массив.
Функция ПроверитьКоличествоПереданныхОбъектов(ПараметрКоманды)
	
	Если ТипЗнч(ПараметрКоманды) = Тип("Массив") И ПараметрКоманды.Количество() = 0 Тогда
		Возврат Ложь;
	Иначе
		Возврат Истина;
	КонецЕсли;
	
КонецФункции

// Проверяет, проведенность документов перед печатью.
// Если есть непроведенные документы, то предлагает перепровести.
//
// Параметры
//  ДокументыМассив - Массив           - ссылки на документы, которые должны быть проведены перед печатью.
//  ФормаИсточник   - УправляемаяФорма - форма, из которой было вызвана команда.
//
Функция ПроверитьДокументыПроведены(ДокументыМассив, ФормаИсточник = Неопределено) Экспорт
	
	ОчиститьСообщения();
	ОбщегоНазначенияКлиентСервер.УдалитьВсеВхожденияТипаИзМассива(ДокументыМассив, Тип("СтрокаГруппировкиДинамическогоСписка"));
	МассивНепроведенныхДокументов = ОбщегоНазначения.ПроверитьПроведенностьДокументов(ДокументыМассив);
	КоличествоНепроведенныхДокументов = МассивНепроведенныхДокументов.Количество();
	
	Если КоличествоНепроведенныхДокументов > 0 Тогда
		
		Если КоличествоНепроведенныхДокументов = 1 Тогда
			ТекстВопроса = НСтр("en = 'The document needs to be posted before printing. Post and continue?'");
		Иначе
			ТекстВопроса = НСтр("en = 'The documents need to be posted before printing. Post and continue?'");
		КонецЕсли;
		
		КодОтвета = Вопрос(ТекстВопроса, РежимДиалогаВопрос.ДаНет);
		Если КодОтвета <> КодВозвратаДиалога.Да Тогда
			Возврат Ложь;
		КонецЕсли;
			
		ТипПроведенныхДокументов = Неопределено;
		МассивНепроведенныхДокументов = ОбщегоНазначения.ПровестиДокументы(МассивНепроведенныхДокументов, ТипПроведенныхДокументов);
		ОповеститьОбИзменении(ТипПроведенныхДокументов);
		// Если команда была вызвана из формы, то зачитываем в форму актуальную (проведенную) копию из базы.
		Если ТипЗнч(ФормаИсточник) = Тип("УправляемаяФорма") Тогда
			Попытка
				ФормаИсточник.Прочитать();	
			Исключение
				// Если метода Прочитать нет, значит печать выполнена не из формы объекта.
			КонецПопытки;
		КонецЕсли;
		
	КонецЕсли;
	
	ШаблонСообщения = НСтр("en = 'Document %1 is not posted: %2 Printing cancelled.'");
	Для Каждого НепроведенныйДокумент Из МассивНепроведенныхДокументов Цикл
		Найденный = ДокументыМассив.Найти(НепроведенныйДокумент.Ссылка);
		Если Найденный <> Неопределено Тогда
			ДокументыМассив.Удалить(Найденный);
			ОбщегоНазначенияКлиентСервер.СообщитьПользователю(
				СтроковыеФункцииКлиентСервер.ПодставитьПараметрыВСтроку(ШаблонСообщения, Строка(НепроведенныйДокумент.Ссылка), 
					НепроведенныйДокумент.ОписаниеОшибки), НепроведенныйДокумент.Ссылка);
		КонецЕсли;
	КонецЦикла;
	
	Возврат ДокументыМассив.Количество() > 0;
	
КонецФункции

////////////////////////////////////////////////////////////////////////////////
// СЕКЦИЯ ФУНКЦИОНАЛЬНОСТИ ДЛЯ РАБОТЫ С МАКЕТАМИ ОФИСНЫХ ДОКУМЕНТОВ
//
//	Краткое описание:
//	Секция содержит интерфейсные функции (API), используемые при создании
//	печатных форм основанных на офисных документах. На данный момент поддерживается
//	два офисных пакета MS Office (шаблоны MS Word) и Open Office (шаблоны OO Writer).
//
////////////////////////////////////////////////////////////////////////////////
//	типы используемых данных (определяется конкретными реализациями)
//	СсылкаПечатнаяФорма	- ссылка на печатную форму
//	СсылкаМакет			- ссылка на макет
//	Область				- ссылка на область в печатной форме или макете (структура)
//						доопределяется в интерфейсном модуле служебной информацией
//						об области
//	ОписаниеОбласти			- описание области макета (см. ниже)
//	ДанныеЗаполнения		- либо структура, либо массив структур (для случая
//							списков и таблиц
////////////////////////////////////////////////////////////////////////////////
//	ОписаниеОбласти - структура, описывающая подготовленные пользователем области макета
//	ключ ИмяОбласти - имя области
//	ключ ТипТипОбласти - 	ВерхнийКолонтитул
//							НижнийКолонтитул
//							Общая
//							СтрокаТаблицы
//							Список
//

////////////////////////////////////////////////////////////////////////////////
// Функции инициализации и закрытия ссылок

// Создает соединение с выходной печатной формой.
// Необходимо вызвать перед любыми действиями над формой.
// Параметры:
// ТипДокумента - строка - тип печатной формы либо "ODT" либо "ODT"
//
// Возвращаемое значение:
// СсылкаПечатнаяФорма
//
Функция ИнициализироватьПечатнуюФорму(знач ТипДокумента, знач НастройкиСтраницыМакета = Неопределено) Экспорт
	
	//Если ВРег(ТипДокумента) = "DOC" Тогда
	//	ПечатнаяФорма = УправлениеПечатьюMSWordКлиент.ИнициализироватьПечатнуюФормуMSWord(НастройкиСтраницыМакета);
	//	ПечатнаяФорма.Вставить("Тип", "DOC");
	//	ПечатнаяФорма.Вставить("ПоследняяВыведеннаяОбласть", Неопределено);
	//	Возврат ПечатнаяФорма;
	//ИначеЕсли ВРег(ТипДокумента) = "ODT" Тогда
	//	ПечатнаяФорма = УправлениеПечатьюOOWriterКлиент.ИнициализироватьПечатнуюФормуOOWriter();
	//	ПечатнаяФорма.Вставить("Тип", "ODT");
	//	ПечатнаяФорма.Вставить("ПоследняяВыведеннаяОбласть", Неопределено);
	//	Возврат ПечатнаяФорма;
	//КонецЕсли;
	
КонецФункции

// Создает соединение с макетом. В дальнейшем это соединение используется
// при получении из него областей (тегов и таблиц).
//
// Параметры:
//  ДвоичныеДанныеМакета - ДвоичныеДанные - двоичные данные макета
//  ТипШаблона - тип макета, либо "ODT", либо "ODT"
// Возвращаемое значение:
//  СсылкаМакет
//
Функция ИнициализироватьМакет(знач ДвоичныеДанныеМакета, знач ТипМакета, знач ПутьККаталогу = "", знач ИмяМакета = "") Экспорт
	
#Если ВебКлиент Тогда
	ТекстСообщения = НСтр("en = 'To continue printing install the file module.'");
	Если Не ОбщегоНазначенияКлиент.РасширениеРаботыСФайламиПодключено(ТекстСообщения) Тогда
		Возврат Неопределено;
	КонецЕсли;
	
	Если ПустаяСтрока(ИмяМакета) Тогда
		ИмяВременногоФайла = Строка(Новый УникальныйИдентификатор) + "." + НРег(ТипМакета);
	Иначе
		ИмяВременногоФайла = ИмяМакета + "." + НРег(ТипМакета);
	КонецЕсли;
	
	ПолучаемыеФайлы = Новый Соответствие;
	ПолучаемыеФайлы.Вставить(ИмяВременногоФайла, ДвоичныеДанныеМакета);
	
	Результат = ПолучитьФайлыВКаталогФайловПечати(ПутьККаталогу, ПолучаемыеФайлы);
	
	Если Результат = Неопределено Тогда
		Возврат Неопределено;
	КонецЕсли;
	
	ИмяВременногоФайла = Результат + ИмяВременногоФайла;
#Иначе
	ИмяВременногоФайла = "";
#КонецЕсли

	//Если ВРег(ТипМакета) = "DOC" Тогда
	//	Макет = УправлениеПечатьюMSWordКлиент.ПолучитьМакетMSWord(ДвоичныеДанныеМакета, ИмяВременногоФайла);
	//	Макет.Вставить("Тип", "DOC");
	//	Возврат Макет;
	//ИначеЕсли ВРег(ТипМакета) = "ODT" Тогда
	//	Макет = УправлениеПечатьюOOWriterКлиент.ПолучитьМакетOOWriter(ДвоичныеДанныеМакета, ИмяВременногоФайла);
	//	Макет.Вставить("Тип", "ODT");
	//	Макет.Вставить("НастройкиСтраницыМакета", Неопределено);
	//	Возврат Макет;
	//КонецЕсли;
	
КонецФункции

#Если ВебКлиент Тогда
// Функция получает файл(ы) c сервера в локальный каталог на диск и возвращает
// имя каталога, в который они были сохранены
// Параметры:
// ПутьККаталогу - строка - путь к каталогу, в который должны быть сохранены файлы
// ПолучаемыеФайлы - соответствие - 
//                         ключ  - имя файла
//                         значение - двоичные данные файла
//
Функция ПолучитьФайлыВКаталогФайловПечати(ПутьККаталогу, ПолучаемыеФайлы) Экспорт
	
	ТребуетсяУстановитьКаталогПечати = Не ЗначениеЗаполнено(ПутьККаталогу);
	Если Не ТребуетсяУстановитьКаталогПечати Тогда
		Файл = Новый Файл(ПутьККаталогу);
		Если НЕ Файл.Существует() Тогда
			ТребуетсяУстановитьКаталогПечати = Истина;
		КонецЕсли;
	КонецЕсли;
	
	Если ТребуетсяУстановитьКаталогПечати Тогда
		Результат = ОткрытьФормуМодально("РегистрСведений.ПользовательскиеМакетыПечати.Форма.НастройкаКаталогаФайловПечати");
		Если ТипЗнч(Результат) <> Тип("Строка") Тогда
			Возврат Неопределено;
		КонецЕсли;
		ПутьККаталогу = Результат;
	КонецЕсли;
	
	ПовторятьПечать = Истина;
	
	Пока ПовторятьПечать Цикл
		ПовторятьПечать = Ложь;
		Попытка
			ФайлыВоВременномХранилище = ПолучитьАдресаФайловВоВременномХранилище(ПолучаемыеФайлы);
			
			ОписанияФайлов = Новый Массив;
			
			Для Каждого ФайлВоВременномХранилище Из ФайлыВоВременномХранилище Цикл
				ОписанияФайлов.Добавить(Новый ОписаниеПередаваемогоФайла(ФайлВоВременномХранилище.Ключ,ФайлВоВременномХранилище.Значение));
			КонецЦикла;
			
			Если НЕ ПолучитьФайлы(ОписанияФайлов, , ПутьККаталогу, Ложь) Тогда
				Возврат Неопределено;
			КонецЕсли;
		Исключение
			СообщениеОбОшибке = КраткоеПредставлениеОшибки(ИнформацияОбОшибке());
			Результат = ОткрытьФормуМодально("РегистрСведений.ПользовательскиеМакетыПечати.Форма.ДиалогПовтораПечати", Новый Структура("СообщениеОбОшибке", СообщениеОбОшибке));
			Если ТипЗнч(Результат) = Тип("Строка") Тогда
				ПовторятьПечать = Истина;
				ПутьККаталогу = Результат;
			Иначе
				Возврат Неопределено;
			КонецЕсли;
		КонецПопытки;
	КонецЦикла;
	
	Если Прав(ПутьККаталогу, 1) <> "\" Тогда
		ПутьККаталогу = ПутьККаталогу + "\";
	КонецЕсли;
	
	Возврат ПутьККаталогу;
	
КонецФункции

// Помещает набор двоичных данных во временное хранилище
// Параметры:
// 	НаборЗначений - соответствие, ключ - ключ, связанный с двоичными данными
// 								  значение - ДвоичныеДанные
// Возвращаемое значение:
// соответствие: ключ - ключ, связанный с адресом во временном хранилище
//               значение - адрес во временном хранилище
//
Функция ПолучитьАдресаФайловВоВременномХранилище(НаборЗначений)
	
	Результат = Новый Соответствие;
	
	Для Каждого КлючЗначение Из НаборЗначений Цикл
		Результат.Вставить(КлючЗначение.Ключ, ПоместитьВоВременноеХранилище(КлючЗначение.Значение));
	КонецЦикла;
	
	Возврат Результат;
	
КонецФункции
#КонецЕсли

// Освобождает ссылки в созданном интерфейсе связи с офисным приложением.
// Необходимо вызывать каждый раз после завершения формирования макета и выводе
// печатной формы пользователю.
// Параметры:
// Handler - СсылкаПечатнаяФорма, СсылкаМакет
// ЗакрытьПриложение - булево - признак, требуется ли закрыть приложение.
//					Соединение с макетом требуется закрывать с закрытием приложения.
//					ПечатнуюФорму не требуется закрывать.
//
Процедура ОчиститьСсылки(Handler, знач ЗакрытьПриложение = Истина) Экспорт
	
	Если Handler <> Неопределено Тогда
		//Если Handler.Тип = "DOC" Тогда
		//	УправлениеПечатьюMSWordКлиент.ЗакрытьСоединение(Handler, ЗакрытьПриложение);
		//Иначе
		//	УправлениеПечатьюOOWriterКлиент.ЗакрытьСоединение(Handler, ЗакрытьПриложение);
		//КонецЕсли;
		Handler = Неопределено;
	КонецЕсли;
	
КонецПроцедуры

////////////////////////////////////////////////////////////////////////////////
// Функция отображения печатной формы пользователю

// Показывает сформированный документ пользователю.
// Фактически устанавливает ему признак видимости.
// Параметры
//  Handler - СсылкаПечатнаяФорма
//
Процедура ПоказатьДокумент(знач Handler) Экспорт
	
	//Если Handler.Тип = "DOC" Тогда
	//	УправлениеПечатьюMSWordКлиент.ПоказатьДокументMSWord(Handler);
	//ИначеЕсли Handler.Тип = "ODT" Тогда
	//	УправлениеПечатьюOOWriterКлиент.ПоказатьДокументOOWriter(Handler);
	//КонецЕсли;
	
КонецПроцедуры

////////////////////////////////////////////////////////////////////////////////
// Функции получения областей из макета, вывода в печатную форму областей макета
// и заполнение параметров в них

// Получает область из макета.
// Параметры
// СсылкаМакет - СсылкаМакет - ссылка на макет
// ОписаниеОбласти - ОписаниеОбласти - описание области
//
// Возвращаемое значение
// Область - область из макета
//
Функция ПолучитьОбласть(знач СсылкаМакет, знач ОписаниеОбласти) Экспорт
	
	Область = Неопределено;
	//Если СсылкаМакет.Тип = "DOC" Тогда
	//	
	//	Если		ОписаниеОбласти.ТипОбласти = "ВерхнийКолонтитул" Тогда
	//		Область = УправлениеПечатьюMSWordКлиент.ПолучитьОбластьВерхнегоКолонтитула(СсылкаМакет);
	//	ИначеЕсли	ОписаниеОбласти.ТипОбласти = "НижнийКолонтитул" Тогда
	//		Область = УправлениеПечатьюMSWordКлиент.ПолучитьОбластьНижнегоКолонтитула(СсылкаМакет);
	//	ИначеЕсли	ОписаниеОбласти.ТипОбласти = "Общая" Тогда
	//		Область = УправлениеПечатьюMSWordКлиент.ПолучитьОбластьМакетаMSWord(СсылкаМакет, ОписаниеОбласти.ИмяОбласти, 1, 0);
	//	ИначеЕсли	ОписаниеОбласти.ТипОбласти = "СтрокаТаблицы" Тогда
	//		Область = УправлениеПечатьюMSWordКлиент.ПолучитьОбластьМакетаMSWord(СсылкаМакет, ОписаниеОбласти.ИмяОбласти);
	//	ИначеЕсли	ОписаниеОбласти.ТипОбласти = "Список" Тогда
	//		Область = УправлениеПечатьюMSWordКлиент.ПолучитьОбластьМакетаMSWord(СсылкаМакет, ОписаниеОбласти.ИмяОбласти, 1, 0);
	//	Иначе
	//		ВызватьИсключение
	//			СтроковыеФункцииКлиентСервер.ПодставитьПараметрыВСтроку(
	//				НСтр("en = 'Area type is not set or incorrect: %1.'"), ОписаниеОбласти.ТипОбласти);
	//	КонецЕсли;
	//	
	//	Если Область <> Неопределено Тогда
	//		Область.Вставить("ОписаниеОбласти", ОписаниеОбласти);
	//	КонецЕсли;
	//ИначеЕсли СсылкаМакет.Тип = "ODT" Тогда
	//	
	//	Если		ОписаниеОбласти.ТипОбласти = "ВерхнийКолонтитул" Тогда
	//		Область = УправлениеПечатьюOOWriterКлиент.ПолучитьОбластьВерхнегоКолонтитула(СсылкаМакет);
	//	ИначеЕсли	ОписаниеОбласти.ТипОбласти = "НижнийКолонтитул" Тогда
	//		Область = УправлениеПечатьюOOWriterКлиент.ПолучитьОбластьНижнегоКолонтитула(СсылкаМакет);
	//	ИначеЕсли	ОписаниеОбласти.ТипОбласти = "Общая"
	//			ИЛИ ОписаниеОбласти.ТипОбласти = "СтрокаТаблицы"
	//			ИЛИ ОписаниеОбласти.ТипОбласти = "Список" Тогда
	//		Область = УправлениеПечатьюOOWriterКлиент.ПолучитьОбластьМакета(СсылкаМакет, ОписаниеОбласти.ИмяОбласти);
	//	Иначе
	//		ВызватьИсключение
	//			СтроковыеФункцииКлиентСервер.ПодставитьПараметрыВСтроку(
	//				НСтр("en = 'Area type is not set or incorrect: %1.'"), ОписаниеОбласти.ИмяОбласти);
	//	КонецЕсли;
	//	
	//	Если Область <> Неопределено Тогда
	//		Область.Вставить("ОписаниеОбласти", ОписаниеОбласти);
	//	КонецЕсли;
	//КонецЕсли;
	
	Возврат Область;
	
КонецФункции

// Присоединяет область в печатную форму из макета.
// Применяется при одиночном выводе области.
//
// Параметры
// ПечатнаяФорма - СсылкаПечатнаяФорма - ссылка на печатную форму
// ОбластьМакета - Область - область из макета
// ПереходНаСледующуюСтроку - булево, требуется ли вставлять разрыв после вывода области
//
Процедура ПрисоединитьОбласть(знач ПечатнаяФорма,
							  знач ОбластьМакета,
							  знач ПереходНаСледующуюСтроку = Истина) Экспорт
	
	Попытка
		ОписаниеОбласти = ОбластьМакета.ОписаниеОбласти;
		
		//Если ПечатнаяФорма.Тип = "DOC" Тогда
		//	
		//	ВыведеннаяОбласть = Неопределено;
		//	
		//	Если		ОписаниеОбласти.ТипОбласти = "ВерхнийКолонтитул" Тогда
		//		УправлениеПечатьюMSWordКлиент.ДобавитьВерхнийКолонтитул(ПечатнаяФорма, ОбластьМакета);
		//	ИначеЕсли	ОписаниеОбласти.ТипОбласти = "НижнийКолонтитул" Тогда
		//		УправлениеПечатьюMSWordКлиент.ДобавитьНижнийКолонтитул(ПечатнаяФорма, ОбластьМакета);
		//	ИначеЕсли	ОписаниеОбласти.ТипОбласти = "Общая" Тогда
		//		ВыведеннаяОбласть = УправлениеПечатьюMSWordКлиент.ПрисоединитьОбласть(ПечатнаяФорма, ОбластьМакета, ПереходНаСледующуюСтроку);
		//		УправлениеПечатьюMSWordКлиент.ВставитьРазрывНаНовуюСтроку(ПечатнаяФорма);
		//	ИначеЕсли	ОписаниеОбласти.ТипОбласти = "Список" Тогда
		//		ВыведеннаяОбласть = УправлениеПечатьюMSWordКлиент.ПрисоединитьОбласть(ПечатнаяФорма, ОбластьМакета, ПереходНаСледующуюСтроку);
		//	ИначеЕсли	ОписаниеОбласти.ТипОбласти = "СтрокаТаблицы" Тогда
		//		Если ПечатнаяФорма.ПоследняяВыведеннаяОбласть <> Неопределено
		//		   И ПечатнаяФорма.ПоследняяВыведеннаяОбласть.ТипОбласти = "СтрокаТаблицы"
		//		   И НЕ ПечатнаяФорма.ПоследняяВыведеннаяОбласть.ПереходНаСледующуюСтроку Тогда
		//			ВыведеннаяОбласть = УправлениеПечатьюMSWordКлиент.ПрисоединитьОбласть(ПечатнаяФорма, ОбластьМакета, ПереходНаСледующуюСтроку, Истина);
		//		Иначе
		//			ВыведеннаяОбласть = УправлениеПечатьюMSWordКлиент.ПрисоединитьОбласть(ПечатнаяФорма, ОбластьМакета, ПереходНаСледующуюСтроку);
		//		КонецЕсли;
		//	Иначе
		//		ВызватьИсключение(НСтр("en = 'Area type is not set or incorrect.'"));
		//	КонецЕсли;
		//	
		//	ОписаниеОбласти.Вставить("Область", ВыведеннаяОбласть);
		//	ОписаниеОбласти.Вставить("ПереходНаСледующуюСтроку", ПереходНаСледующуюСтроку);
		//	
		//	ПечатнаяФорма.ПоследняяВыведеннаяОбласть = ОписаниеОбласти; // содержит тип области, и границы области (если требуется)
		//	
		//ИначеЕсли ПечатнаяФорма.Тип = "ODT" Тогда
		//	Если		ОписаниеОбласти.ТипОбласти = "ВерхнийКолонтитул" Тогда
		//		УправлениеПечатьюOOWriterКлиент.ДобавитьВерхнийКолонтитул(ПечатнаяФорма, ОбластьМакета);
		//	ИначеЕсли	ОписаниеОбласти.ТипОбласти = "НижнийКолонтитул" Тогда
		//		УправлениеПечатьюOOWriterКлиент.ДобавитьНижнийКолонтитул(ПечатнаяФорма, ОбластьМакета);
		//	ИначеЕсли	ОписаниеОбласти.ТипОбласти = "Общая"
		//			ИЛИ ОписаниеОбласти.ТипОбласти = "Список" Тогда
		//		УправлениеПечатьюOOWriterКлиент.УстановитьОсновнойКурсорНаТелоДокумента(ПечатнаяФорма);
		//		УправлениеПечатьюOOWriterКлиент.ПрисоединитьОбласть(ПечатнаяФорма, ОбластьМакета, ПереходНаСледующуюСтроку);
		//	ИначеЕсли	ОписаниеОбласти.ТипОбласти = "СтрокаТаблицы" Тогда
		//		УправлениеПечатьюOOWriterКлиент.УстановитьОсновнойКурсорНаТелоДокумента(ПечатнаяФорма);
		//		УправлениеПечатьюOOWriterКлиент.ПрисоединитьОбласть(ПечатнаяФорма, ОбластьМакета, ПереходНаСледующуюСтроку, Истина);
		//	Иначе
		//		ВызватьИсключение(НСтр("en = 'Area type is not set or incorrect'"));
		//	КонецЕсли;
		//	ПечатнаяФорма.ПоследняяВыведеннаяОбласть = ОписаниеОбласти; // содержит тип области, и границы области (если требуется)
		//КонецЕсли;
	Исключение
		СообщениеОбОшибке = СокрЛП(КраткоеПредставлениеОшибки(ИнформацияОбОШибке()));
		СообщениеОбОшибке = ?(Прав(СообщениеОбОшибке, 1) = ".", СообщениеОбОшибке, СообщениеОбОшибке + ".");
		СообщениеОбОшибке = СообщениеОбОшибке + 
				СтроковыеФункцииКлиентСервер.ПодставитьПараметрыВСтроку(
					НСтр("en = ' Error outputting area ""%1"" from the template.'"),
					ОбластьМакета.ОписаниеОбласти.ИмяОбласти);
		ВызватьИсключение СообщениеОбОшибке;
	КонецПопытки;
	
КонецПроцедуры

// Заполняет параметры области печатной формы
//
// Параметры
// ПечатнаяФорма	- СсылкаПечатнаяФорма, Область - область печатной формы, либо сама печатная форма
// Данные			- ДанныеЗаполнения
//
Процедура ЗаполнитьПараметры(знач ПечатнаяФорма, знач Данные) Экспорт
	
	ОписаниеОбласти = ПечатнаяФорма.ПоследняяВыведеннаяОбласть;
	
	//Если ПечатнаяФорма.Тип = "DOC" Тогда
	//	Если		ОписаниеОбласти.ТипОбласти = "ВерхнийКолонтитул" Тогда
	//		УправлениеПечатьюMSWordКлиент.ЗаполнитьПараметрыВерхнегоКолонтитула(ПечатнаяФорма, Данные);
	//	ИначеЕсли	ОписаниеОбласти.ТипОбласти = "НижнийКолонтитул" Тогда
	//		УправлениеПечатьюMSWordКлиент.ЗаполнитьПараметрыНижнегоКолонтитула(ПечатнаяФорма, Данные);
	//	ИначеЕсли	ОписаниеОбласти.ТипОбласти = "Общая"
	//			ИЛИ ОписаниеОбласти.ТипОбласти = "СтрокаТаблицы"
	//			ИЛИ ОписаниеОбласти.ТипОбласти = "Список" Тогда
	//		УправлениеПечатьюMSWordКлиент.ЗаполнитьПараметры(ПечатнаяФорма.ПоследняяВыведеннаяОбласть.Область, Данные);
	//	Иначе
	//		ВызватьИсключение(НСтр("en = 'Area type is not set or incorrect'"));
	//	КонецЕсли;
	//ИначеЕсли ПечатнаяФорма.Тип = "ODT" Тогда
	//	Если		ПечатнаяФорма.ПоследняяВыведеннаяОбласть.ТипОбласти = "ВерхнийКолонтитул" Тогда
	//		УправлениеПечатьюOOWriterКлиент.УстановитьОсновнойКурсорНаВерхнийКолонтитул(ПечатнаяФорма);
	//	ИначеЕсли	ПечатнаяФорма.ПоследняяВыведеннаяОбласть.ТипОбласти = "НижнийКолонтитул" Тогда
	//		УправлениеПечатьюOOWriterКлиент.УстановитьОсновнойКурсорНаНижнийКолонтитул(ПечатнаяФорма);
	//	ИначеЕсли	ОписаниеОбласти.ТипОбласти = "Общая"
	//			ИЛИ ОписаниеОбласти.ТипОбласти = "СтрокаТаблицы"
	//			ИЛИ ОписаниеОбласти.ТипОбласти = "Список" Тогда
	//		УправлениеПечатьюOOWriterКлиент.УстановитьОсновнойКурсорНаТелоДокумента(ПечатнаяФорма);
	//	КонецЕсли;
	//	УправлениеПечатьюOOWriterКлиент.ЗаполнитьПараметры(ПечатнаяФорма, Данные);
	//КонецЕсли;
	
КонецПроцедуры

// Добавляет область в печатную форму из макета, при этом заменяя
// параметры в области значениями из данных объекта.
// Применяется при одиночном выводе области.
//
// Параметры
// ПечатнаяФорма	- СсылкаПечатнаяФорма
// ОбластьМакета	- Область
// Данные			- ДанныеОбъекта
// ПереходНаСледСтроку - булево, требуется ли вставлять разрыв после вывода области
//
Процедура ПрисоединитьОбластьИЗаполнитьПараметры(знач ПечатнаяФорма,
										знач ОбластьМакета,
										знач Данные,
										знач ПереходНаСледующуюСтроку = Истина) Экспорт
	
	ПрисоединитьОбласть(ПечатнаяФорма, ОбластьМакета, ПереходНаСледующуюСтроку);
	ЗаполнитьПараметры(ПечатнаяФорма, Данные)
	
КонецПроцедуры

// Добавляет область в печатную форму из макета, при этом заменяя
// параметры в области значениями из данных объекта.
// Применяется при одиночном выводе области.
//
// Параметры
// ПечатнаяФорма	- СсылкаПечатнаяФорма
// ОбластьМакета	- Область - область макета
// Данные			- ДанныеОбъекта (массив структур)
// ПереходНаСледСтроку - булево, требуется ли вставлять разрыв после вывода области
//
Процедура ПрисоединитьИЗаполнитьКоллекцию(знач ПечатнаяФорма,
										знач ОбластьМакета,
										знач Данные,
										знач ПереходНаСледСтроку = Истина) Экспорт
	
	ОписаниеОбласти = ОбластьМакета.ОписаниеОбласти;
	
	//Если ПечатнаяФорма.Тип = "DOC" Тогда
	//	Если		ОписаниеОбласти.ТипОбласти = "СтрокаТаблицы" Тогда
	//		УправлениеПечатьюMSWordКлиент.ПрисоединитьИЗаполнитьОбластьТаблицы(ПечатнаяФорма, ОбластьМакета, Данные, ПереходНаСледСтроку);
	//	ИначеЕсли	ОписаниеОбласти.ТипОбласти = "Список" Тогда
	//		УправлениеПечатьюMSWordКлиент.ПрисоединитьИЗаполнитьНабор(ПечатнаяФорма, ОбластьМакета, Данные, ПереходНаСледСтроку);
	//	Иначе
	//		ВызватьИсключение(НСтр("en = 'Area type is not set or incorrect'"));
	//	КонецЕсли;
	//ИначеЕсли ПечатнаяФорма.Тип = "ODT" Тогда
	//	Если		ОписаниеОбласти.ТипОбласти = "СтрокаТаблицы" Тогда
	//		УправлениеПечатьюOOWriterКлиент.ПрисоединитьИЗаполнитьКоллекцию(ПечатнаяФорма, ОбластьМакета, Данные, Истина, ПереходНаСледСтроку);
	//	ИначеЕсли	ОписаниеОбласти.ТипОбласти = "Список" Тогда
	//		УправлениеПечатьюOOWriterКлиент.ПрисоединитьИЗаполнитьКоллекцию(ПечатнаяФорма, ОбластьМакета, Данные, Ложь, ПереходНаСледСтроку);
	//	Иначе
	//		ВызватьИсключение(НСтр("en = 'Area type is not set or incorrect'"));
	//	КонецЕсли;
	//КонецЕсли;
	
КонецПроцедуры

// Вставляет разрыв между строками в виде символа перевода строки
// Параметры
// ПечатнаяФорма - СсылкаПечатнаяФорма
//
Процедура ВставитьРазрывНаНовуюСтроку(знач ПечатнаяФорма) Экспорт
	
	//Если	  ПечатнаяФорма.Тип = "DOC" Тогда
	//	УправлениеПечатьюMSWordКлиент.ВставитьРазрывНаНовуюСтроку(ПечатнаяФорма);
	//ИначеЕсли ПечатнаяФорма.Тип = "ODT" Тогда
	//	УправлениеПечатьюOOWriterКлиент.ВставитьРазрывНаНовуюСтроку(ПечатнаяФорма);
	//КонецЕсли;
	
КонецПроцедуры
