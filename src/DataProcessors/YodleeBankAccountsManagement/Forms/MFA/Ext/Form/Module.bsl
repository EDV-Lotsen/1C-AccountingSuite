﻿
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	AnswerTimeout = Parameters.AnswerTimeout;
	If Parameters.Property("StartTime") Then
		StartTime = Parameters.StartTime;
	EndIf;
	If Parameters.Property("FormTitle") Then
		FormTitle = Parameters.FormTitle;
	EndIf;
	If ValueIsFilled(AnswerTimeout) Then
		Items.AnswerTimeoutGroup.Visible = true;
		//Items.Decoration1.Title = "You have " + Format(AnswerTimeout, "NFD=0; NZ=; NG=") + " seconds to answer";
	Else
		Items.AnswerTimeoutGroup.Visible = false;
	EndIf;
	If ValueIsFilled(FormTitle) Then
		ThisForm.Title = FormTitle;
	EndIf;
	AddFormFields(Parameters.ProgrammaticElements, Parameters.ProgrammaticElementsValidValues);
EndProcedure

&AtServer
Procedure AddFormFields(ProgrammaticElements, ValidValues)
	//Field types:
	// Text 		- 0
	// Password 	- 1
	// Options 		- 2
	// Checkbox 	- 3
	// Radio 		- 4
	// Login 		- 5
	// Url			- 6
	// Hidden		- 7
	// Image_Url	- 8
	// Content_Url	- 9
	// Custom		- 10
	// Cludge		- 11
	//newPEs	= ProgrammaticElements.FindRows(New Structure("NewElement", True));
	FieldsToAdd 	= New Array();
	For Each PElt In ProgrammaticElements Do
		If (PElt.FieldType = 0) Or (PElt.FieldType = 1) Or (PElt.FieldType = 2) 
			Or (PElt.FieldType = 5) Or (PElt.FieldType = 6) Then
			StringQualifier = New StringQualifiers(PElt.MaxLength);
			FieldsToAdd.Add(New FormAttribute(PElt.ElementName, New TypeDescription("String",,,,StringQualifier)));
		EndIf;
	EndDo;
	ChangeAttributes(FieldsToAdd);
	//Add form elements
	For Each PElt In ProgrammaticElements Do
		If (PElt.FieldType = 0) Or (PElt.FieldType = 1) Or (PElt.FieldType = 2) 
			Or (PElt.FieldType = 5) Or (PElt.FieldType = 6) Then
			NewEl 	= Items.Add(PElt.ElementName, Type("FormField"));
			NewEl.Type = FormFieldType.InputField;
			NewEl.DataPath = PElt.ElementName;
			NewEl.Title 	= PElt.DisplayName;
			//For password fields 
			If PElt.FieldType = 1 Then
				NewEl.PasswordMode = True;
			EndIf;
			If ValueIsFilled(AnswerTimeout) Then
				NewEl.PasswordMode = False; //In password mode and EditTextUpdate.DontUse an error occurs
				NewEl.EditTextUpdate = EditTextUpdate.DontUse;
			EndIf;
			//Check if there are valid values
			FoundRows = FindValidValues(ValidValues, PElt.ElementName);
			If FoundRows.Count() > 0 Then
				ValidList = NewEl.ChoiceList;
				For Each FR In FoundRows Do
					ValidList.Add(FR.ValidValue, FR.DisplayValidValue);
				EndDo;
				NewEl.DropListButton = True;
			EndIf;
		EndIf;
	EndDo;
EndProcedure

&AtServer
Function FindValidValues(ValidValues, ElementName)
	ReturnArray = New Array();
	For Each VV In ValidValues Do
		If VV.ElementName = ElementName Then
			ReturnArray.Add(VV);
		EndIf;
	EndDo;
	return ReturnArray;
EndFunction

&AtClient
Procedure CloseForm(Command)
	ProgrammaticElements = New Array;
	For Each PE In Items Do
		If TypeOf(PE) = Type("FormField") And PE.Type = FormFieldType.InputField Then
			FormField = New Structure;
			FormField.Insert("ElementValue", ThisForm[PE.Name]);
			FormField.Insert("ElementName", PE.Name);
			ProgrammaticElements.Add(FormField);
		EndIf;
	EndDo;
	Close(ProgrammaticElements);
EndProcedure

&AtClient
Procedure UpdateTimeout() Export
	//AnswerTimeLeft = GetTimeLeft(StartTime, AnswerTimeout);
	AnswerTimeLeft = GetTimeLeft();
	//AnswerTimeLeft = AnswerTimeLeft + 1;
	//Items.Decoration1.Title = CurrentDate();
	//GetTimeLeft();
	If AnswerTimeLeft < 10 Then
		Items.AnswerTimeout.TextColor = New Color(255, 0, 0);
	Else
		Items.AnswerTimeout.TextColor = New Color(0, 0, 0);
	EndIf;
	If AnswerTimeLeft <= 0 Then     
		DetachIdleHandler("UpdateTimeout");
	EndIf;
EndProcedure

////&AtServerNoContext
//Function GetTimeLeft(StartTime, AnswerTimeout)
&AtClient
Function GetTimeLeft()
	CurTime	= CurrentDate();
	TimeUTC = ToUniversalTime(CurTime);
	SecondsPassed = TimeUTC - StartTime;
	AnswerTimeLeft = ?(SecondsPassed > AnswerTimeout, 0, AnswerTimeout - SecondsPassed);
	return AnswerTimeLeft;
EndFunction

&AtClient
Procedure OnOpen(Cancel)
	If ValueIsFilled(answerTimeout) Then
		AttachIdleHandler("UpdateTimeout", 1, False);
	EndIf;
EndProcedure
