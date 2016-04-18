
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	ProcessingParameters = New NotifyDescription("AnswerProcessing", ThisObject, CommandParameter);
	QuestionText         = NStr("en = 'Would you like to include copies of the documents when printing statements?'");
	
	ShowQueryBox(ProcessingParameters, QuestionText, QuestionDialogMode.YesNo,,,);
	
EndProcedure

&AtClient
Procedure AnswerProcessing(ChoiceResult, ProcessingParameters) Export
	
	PrintTransactions = ?(ChoiceResult = DialogReturnCode.Yes, True, False);
	
	Spreadsheet = New SpreadsheetDocument;
	Print(Spreadsheet, ProcessingParameters, PrintTransactions);
	
	Spreadsheet.ShowGrid = False;
	Spreadsheet.Protection = False;
	Spreadsheet.ReadOnly = False;
	Spreadsheet.ShowHeaders = False;
	SpreadsheetTitle = "Statement";
	FormParameters = New Structure("SpreadsheetDocument, TitleOfForm, PrintFormID", Spreadsheet, SpreadsheetTitle, ProcessingParameters[0]);
	OpenForm("CommonForm.PrintForm", FormParameters);
	
EndProcedure

&AtServer
Procedure Print(Spreadsheet, CommandParameter, PrintTransactions)
	
	Documents.Statement.Print(Spreadsheet, CommandParameter, PrintTransactions);
	
EndProcedure

