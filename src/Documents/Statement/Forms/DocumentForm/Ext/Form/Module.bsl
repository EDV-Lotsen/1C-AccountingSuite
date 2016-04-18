
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Object.Ref.IsEmpty() Then
		Cancel = True;
	Else
		GeneratePrintForm();
	EndIf;
	
EndProcedure

&AtClient
Procedure MailingAddressOnChange(Item)
	
	Write();
	GeneratePrintForm();
	
EndProcedure

&AtServer
Procedure GeneratePrintForm(Val PrintTransactions = False)
	
	Array = New Array();
	Array.Add(Object.Ref);
	
	Documents.Statement.Print(Result, Array, PrintTransactions);
	
EndProcedure

&AtClient
Procedure Print(Command)
	
	ProcessingParameters = New NotifyDescription("AnswerProcessing", ThisObject);
	QuestionText         = NStr("en = 'Would you like to include copies of the documents when printing statements?'");
	
	ShowQueryBox(ProcessingParameters, QuestionText, QuestionDialogMode.YesNo,,,);
	
EndProcedure

&AtClient
Procedure AnswerProcessing(ChoiceResult, ProcessingParameters) Export
	
	PrintTransactions = ?(ChoiceResult = DialogReturnCode.Yes, True, False);
	
	GeneratePrintForm(PrintTransactions);
	
	Result.Print(PrintDialogUseMode.Use);
	
EndProcedure


