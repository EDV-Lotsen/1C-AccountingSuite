
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If IsInRole("BankAccounting") Then
		BankAccountingRole 			= True;
	Else
		Items.deposits.Visible 	= False;
		Items.payments.Visible 	= False;
		BankAccountingRole 		= False;
	EndIf;
	
EndProcedure

&AtClient
Procedure ListSelection(Item, SelectedRow, Field, StandardProcessing)
	
	//For BankAccounting role open ProcessMonth instead of a document
	If BankAccountingRole Then
		FormParameters = new Structure("BankAccount, DateStart, DateEnd", Item.CurrentData.BankAccount, BegOfMonth(Item.CurrentData.Date), EndOfMonth(Item.CurrentData.Date));
		OpenForm("DataProcessor.BankRegisterCFOToday.Form", FormParameters);
		Notify("BankReconciliationSelected", FormParameters);
	EndIf;
	
EndProcedure
