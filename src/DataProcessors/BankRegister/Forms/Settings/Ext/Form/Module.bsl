

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	FillPropertyValues(ThisForm, ThisForm.Parameters, "HideBalances, DoNotUseJournalEntry, DoNotUseAdjustingJournalEntry, EditBegBal, DateStart, DateEnd, AccountInBank, BankAccount, UseBankReconciliationForBegBal, EditNumbersWithoutDecimalPoint");
	If Not (ValueIsFilled(DateStart) And ValueIsFilled(DateEnd)) Then
		DateStart 	= BegOfMonth(CurrentSessionDate());
		DateEnd 	= EndOfMonth(CurrentSessionDate());
	EndIf;
	DateEnd = EndOfDay(DateEnd);
	PeriodPresentation = PeriodPresentation(DateStart, DateEnd);
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(SelectedValue, ChoiceSource)
	
	If TypeOf(SelectedValue) = Type("Structure") Then
		If (SelectedValue.BeginOfPeriod <> DateStart) Or (SelectedValue.EndOfPeriod <> DateEnd) Then
			PeriodChanged = True;
		EndIf;
		DateStart 	= SelectedValue.BeginOfPeriod;
		DateEnd		= SelectedValue.EndOfPeriod;
	EndIf;
	DateEnd = EndOfDay(DateEnd);
	PeriodPresentation = PeriodPresentation(BegOfDay(DateStart), EndOfDay(DateEnd));
	
EndProcedure

&AtClient
Procedure OKCommand(Command)
	
	StandardProcessing = False;
	ReturnStructure = New Structure("HideBalances, DoNotUseJournalEntry, DoNotUseAdjustingJournalEntry, EditBegBal, DateStart, DateEnd, AccountInBank, BankAccount, UseBankReconciliationForBegBal, EditNumbersWithoutDecimalPoint, PeriodChanged");
	FillPropertyValues(ReturnStructure, ThisForm, "HideBalances, DoNotUseJournalEntry, DoNotUseAdjustingJournalEntry, EditBegBal, DateStart, DateEnd, AccountInBank, BankAccount, UseBankReconciliationForBegBal, EditNumbersWithoutDecimalPoint, PeriodChanged");
	Close(ReturnStructure);

EndProcedure

&AtClient
Procedure ChoosePeriod(Command)
	
	FormParameters = New Structure("BeginOfPeriod, EndOfPeriod", DateStart, DateEnd);
	OpenForm("CommonForm.ChoiceStandardPeriod", FormParameters, ThisForm, ,,,, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure AccountInBankOnChange(Item)
	
	BankAccountOnChangeAtServer();
	
EndProcedure

&AtServer
Procedure BankAccountOnChangeAtServer()
	
	//Find the corresponding account in bank
	BankAccount = AccountInBank.AccountingAccount;
	If Not ValueIsFilled(BankAccount) Then
		CommonUseClientServer.MessageToUser("Please, assign ACS account to the bank account. Bank account form -> Assigned to", , "AccountInBank");
		return;
	EndIf;
		
EndProcedure

&AtClient
Procedure UseBankReconciliationForBegBalOnChange(Item)
	
	If UseBankReconciliationForBegBal Then
		HideBalances = True;
	EndIf;
	
EndProcedure


