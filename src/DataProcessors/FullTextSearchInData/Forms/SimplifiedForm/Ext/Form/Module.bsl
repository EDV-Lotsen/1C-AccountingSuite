
// Processing of command Find
//
&AtClient
Procedure SearchExecute()
	FormParameters = New Structure("", );
	FormParameters.Insert("PassedSearchString", Items.SearchInputField.EditText);
	OpenForm("DataProcessor.FullTextSearchInData.Form.SearchForm", FormParameters);
	
	LoadSearchStrings();
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancellation, StandardProcessing)
	LoadSearchStrings();
EndProcedure

&AtServer
Procedure LoadSearchStrings()
	Array = CommonSettingsStorage.Load("FullTextStringSearchOfFullTextSearch");
	
	If Array <> Undefined Then
		Items.SearchInputField.ChoiceList.LoadValues(Array);
	EndIf;
EndProcedure	

&AtClient
Procedure SearchInputFieldTextEditEnd(Item, Text, ChoiceData, StandardProcessing)
	SearchExecute();
EndProcedure

&AtClient
Procedure SearchInputFieldChoiceProcessing(Item, ValueSelected, StandardProcessing)
	SearchExecute();
EndProcedure

