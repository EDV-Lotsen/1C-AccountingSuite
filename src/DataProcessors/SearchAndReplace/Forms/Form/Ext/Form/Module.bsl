
////////////////////////////////////////////////////////////////////////////////
// ПРОЦЕДУРЫ И ФУНКЦИИ ОБЩЕГО НАЗНАЧЕНИЯ

&AtServer
// Возвращает Object TypeDescription, содержащий указанный Type.
//
// Параметры:
//  TypeValue - String с именем типа или значение типа Type.
//  
// Возвращаемое значение:
//  TypeDescription
//
Function GetTypeDescription(TypeValue)

	ArrayOfTypes = New Array;
	If TypeOf(TypeValue) = Type("String") Then
		ArrayOfTypes.Add(Type(TypeValue));
	Else 
		ArrayOfTypes.Add(TypeValue);
	EndIf; 
	TypeDescription = New TypeDescription(ArrayOfTypes);

	Return TypeDescription;

EndFunction // GetTypeDescription()


////////////////////////////////////////////////////////////////////////////////
// ПРОЦЕДУРЫ - ДЕЙСТВИЯ КОМАНДНЫХ ПАНЕЛЕЙ ФОРМЫ

&AtClient
Procedure ShowSettings(Item)
	
	Items.Settings.Check = Not Items.Settings.Check;
	Items.SettingsGroup.Visible = Items.Settings.Check;
	
EndProcedure

&AtClient
Procedure ExecuteRepalce(Command)
	
	ExecuteAtServer();
	
	ShowMessageBox(, NStr("en = 'Process finished!'; ru = 'Обработка завершена!'"));
	
EndProcedure

&AtServer
Procedure ExecuteAtServer()
	
	ToReplace = New Map;
	For Each CurStr In ValuesToReplace Do
		If CurStr.Check Then
			ToReplace.Insert(CurStr.ChangeFrom, CurStr.ChangeTo);
		EndIf;
	EndDo;
	
	FoundReferencesTable = Object.FoundReferences.Выгрузить();
	FoundReferencesTable.Columns.Add("Metadata");
	
	For Each FoundReferencesRow In FoundReferencesTable Do
		If FoundReferencesRow.Check Then
			FoundReferencesRow.Metadata = Metadata.FindByFullName(FoundReferencesRow.MetadataPresentaion);
		EndIf;
	EndDo;
	
	DPObject = FormAttributeToValue("Object");
	DPObject.ExecuteReplaceObjects(ToReplace, FoundReferencesTable);
	
EndProcedure

&AtServer
Procedure FindRefsAtServer(МассивЗаменяемых)
	
	FoundRefsTable = НайтиПоСсылкам(МассивЗаменяемых);
	
	FoundRefsTable.Columns[0].Name = "Ref";
	FoundRefsTable.Columns[1].Name = "Data";
	FoundRefsTable.Columns[2].Name = "Metadata";
	
	FoundRefsTable.Columns.Add("Check", GetTypeDescription("Булево"));
	FoundRefsTable.Columns.Add("MetadataPresentaion", GetTypeDescription("String"));
	FoundRefsTable.Columns.Add("InformationRegisterRecordKey", GetTypeDescription("ValueList"));
	
	For Each СтрокаНайденнаяСсылка In FoundRefsTable Do
		СтрокаНайденнаяСсылка.MetadataPresentaion = СтрокаНайденнаяСсылка.Metadata.ПолноеИмя();
		If Metadata.РегистрыСведений.Содержит(СтрокаНайденнаяСсылка.Metadata) Then
			Data = СтрокаНайденнаяСсылка.Data;
			КлючЗаписи = СтрокаНайденнаяСсылка.InformationRegisterRecordKey;
			КлючЗаписи.Add(Data.Period, "Period");
			КлючЗаписи.Add(Data.Recorder, "Recorder");
			For Each Измерение In СтрокаНайденнаяСсылка.Metadata.Измерения Do
				КлючЗаписи.Add(Data[Измерение.Name], Измерение.Name);
			EndDo;
		EndIf;
	EndDo;
	
	Object.FoundReferences.Загрузить(FoundRefsTable);

EndProcedure

&AtClient
Procedure CheckAll(Command)
	For Each FoundReferencesRow In Object.FoundReferences Do
		FoundReferencesRow.Check = True;
	EndDo;
EndProcedure

&AtClient
Procedure CheckNone(Command)
	For Each FoundReferencesRow In Object.FoundReferences Do
		FoundReferencesRow.Check = False;
	EndDo;
EndProcedure


////////////////////////////////////////////////////////////////////////////////
// ПРОЦЕДУРЫ - ОБРАБОТЧИКИ ТАБЛИЧНОГО ПОЛЯ ЗаменяемыеЗначения

&AtClient
Procedure ЗаменяемыеЗначенияПриНачалеРедактирования(Элемент, НоваяСтрока, Копирование)

	If НоваяСтрока Then
		Элемент.ТекущиеДанные.Check = True;
	EndIf;
	
EndProcedure



////////////////////////////////////////////////////////////////////////////////
// ПРОЦЕДУРЫ - ОБРАБОТЧИКИ ТАБЛИЧНОГО ПОЛЯ НайденныеСсылки

&AtClient
Procedure НайденныеСсылкиВыбор(Элемент, ВыбраннаяСтрока, Поле, СтандартнаяОбработка)
	// {
	// ShowValue(, ВыбраннаяСтрока.Data);
	If ТекущийРежимЗапуска() = РежимЗапускаКлиентскогоПриложения.ОбычноеПриложение Then
		ShowValue(,ВыбраннаяСтрока.Data);
	Else 
		ShowValue(,Элемент.ТекущиеДанные.Data);
	EndIf;
	// }
	СтандартнаяОбработка = False;
EndProcedure


&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	S = Items.ValuesToReplace;
	
EndProcedure


&AtClient
Procedure FindRefs(Command)
	
	ArrayToChange = New Array;
	For Each CurStr In ValuesToReplace Do
		If CurStr.Check Then
			ArrayToChange.Add(CurStr.ChangeFrom);
		EndIf;
	EndDo;

	If ArrayToChange.Count() = 0 Then
		ShowMessageBox(, "Select rows to search!");
		Return;
	EndIf;

	FindRefsAtServer(ArrayToChange);
	
	CheckAll("");

EndProcedure

