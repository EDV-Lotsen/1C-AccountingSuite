
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	FillPropertyValues(ThisForm, ThisForm.Parameters, "DateStart, DateEnd, AccountInBank, BankAccount, ShowClassColumn");
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
	ReturnStructure = New Structure("DateStart, DateEnd, AccountInBank, BankAccount, PeriodChanged, ShowClassColumn");
	FillPropertyValues(ReturnStructure, ThisForm, "DateStart, DateEnd, AccountInBank, BankAccount, PeriodChanged, ShowClassColumn");
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
	//Find the corresponding account in bank
	AccountInBank = Catalogs.BankAccounts.EmptyRef();
	Request = New Query("SELECT
	                    |	BankAccounts.Ref
	                    |FROM
	                    |	Catalog.BankAccounts AS BankAccounts
	                    |WHERE
	                    |	BankAccounts.AccountingAccount = &AccountingAccount");
	Request.SetParameter("AccountingAccount", BankAccount);
	Res = Request.Execute();
	If Not Res.IsEmpty() Then
		Sel = Res.Select();
		Sel.Next();
		AccountInBank = Sel.Ref;
	Else //Bank account not found. Need to create the new one
		BeginTransaction(DataLockControlMode.Managed);
		Block = New DataLock();
		LockItem = Block.Add("Catalog.BankAccounts");
		LockItem.Mode = DataLockMode.Exclusive;
		Block.Lock();
		Request = New Query("SELECT
		                    |	BankAccounts.Ref
		                    |FROM
		                    |	Catalog.BankAccounts AS BankAccounts
		                    |WHERE
		                    |	BankAccounts.AccountingAccount = &AccountingAccount");
		Request.SetParameter("AccountingAccount", BankAccount);
		Res = Request.Execute();
		If Res.IsEmpty() Then
			Bank = Catalogs.Banks.EmptyRef();
			//Select Offline bank
			//Try to find the Offline bank, if not found then create the new one
			Request = New Query("SELECT
			                    |	Banks.Ref
			                    |FROM
			                    |	Catalog.Banks AS Banks
			                    |WHERE
			                    |	Banks.Code = ""000000000""");
			Res = Request.Execute();
			If Res.IsEmpty() Then
				SetPrivilegedMode(True);
				OfflineBank = Catalogs.Banks.CreateItem();
				OfflineBank.Code 		= "000000000";
				OfflineBank.Description = "Offline bank";
				OfflineBank.Write();
				SetPrivilegedMode(False);
				Bank = OfflineBank.Ref;
			Else
				Sel = Res.Select();
				Sel.Next();
				Bank = Sel.Ref;
			EndIf;
			NewAccount = Catalogs.BankAccounts.CreateItem();
			NewAccount.Owner = Bank;
			NewAccount.Description = BankAccount.Description;
			NewAccount.AccountingAccount = BankAccount;
			NewAccount.Write();
			AccountInBank = NewAccount.Ref;
		Else
			Sel = Res.Select();
			Sel.Next();
			AccountInBank = Sel.Ref;
		EndIf;	
		CommitTransaction();
	EndIf;
		
EndProcedure

&AtClient
Procedure AccountInBankStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	ChoiceData = new ValueList();
	ChoiceData.LoadValues(FillBankAccountChoiceListAtServer());
	
EndProcedure

&AtServerNoContext
Function FillBankAccountChoiceListAtServer()
	
	Request = New Query("SELECT
	                    |	ChartOfAccounts.Ref
	                    |FROM
	                    |	ChartOfAccounts.ChartOfAccounts AS ChartOfAccounts
	                    |WHERE
	                    |	(ChartOfAccounts.AccountType = VALUE(Enum.AccountTypes.Bank)
	                    |			OR ChartOfAccounts.AccountType = VALUE(Enum.AccountTypes.OtherCurrentLiability)
	                    |				AND ChartOfAccounts.CreditCard = TRUE)");
	ResTable = Request.Execute().Unload();
	return ResTable.UnloadColumn("Ref");
	
EndFunction

