
Procedure SessionParametersSetting(RequiredParameters)
	
	 Настройки = ХранилищеСистемныхНастроек.Загрузить("Common/SectionsPanel/CommandInterfaceSettings");
 Если Настройки = Неопределено Тогда
  Настройки = Новый НастройкиКомандногоИнтерфейса;
 КонецЕсли;
 Настройки.ОтображениеПанелиРазделов = ОтображениеПанелиРазделов.Текст;
 ХранилищеСистемныхНастроек.Сохранить("Common/SectionsPanel/CommandInterfaceSettings", "", Настройки);
	
	CurrentUser = InfobaseUsers.CurrentUser(); // GeneralFunctions.CurrentUserValue();
	SessionParameters.ACSUser = CurrentUser.Name;
	
EndProcedure
