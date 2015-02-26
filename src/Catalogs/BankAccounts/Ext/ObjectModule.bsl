
Procedure BeforeWrite(Cancel)
	
	//Check for duplicate usage of the same accounting account
	If ValueIsFilled(ThisObject.AccountingAccount) Then
		DL = New DataLock();
		LockItem = DL.Add("Catalog.BankAccounts");
		LockItem.SetValue("AccountingAccount", ThisObject.AccountingAccount);
		DL.Lock();
		Request = New Query("SELECT
		                    |	BankAccounts.Ref
		                    |FROM
		                    |	Catalog.BankAccounts AS BankAccounts
		                    |WHERE
		                    |	BankAccounts.AccountingAccount = &Account
		                    |	AND BankAccounts.Ref <> &CurrentRef");
		Request.SetParameter("Account", ThisObject.AccountingAccount);
		Request.SetParameter("CurrentRef", ThisObject.Ref);
		Res = Request.Execute();
		If Not Res.IsEmpty() Then
			Cancel = True;
			Message = New UserMessage();
			Message.Text = "Account " + String(ThisObject.AccountingAccount.Code) + " (" + ThisObject.AccountingAccount.Description + ")" + " is already assigned to a different bank account.";
			Message.Message();
		EndIf;
	EndIf;
	
	If CSV_Separator = " " Then
		CSV_Separator = ","
	EndIf;
	
EndProcedure

Procedure BeforeDelete(Cancel)
	
	//Check if bank account is linked to G/L account
	If ValueIsFilled(AccountingAccount) Then
		AccountingAccountObject = AccountingAccount.GetObject();
		If AccountingAccountObject <> Undefined Then
			Cancel = True;
			CommonUseClientServer.MessageToUser("Bank account is linked to G/L account " + String(AccountingAccount));
		EndIf;
	EndIf;
	//Delete records in registers
	//BankTransactions
	BTRecordset = InformationRegisters.BankTransactions.CreateRecordSet();
	BTRecordset.Filter.BankAccount.Set(ThisObject.Ref);
	BTRecordset.Write(True);
	//BankTransactionCategorization
	BTCRecordset = InformationRegisters.BankTransactionCategorization.CreateRecordSet();
	BTCRecordset.Filter.BankAccount.Set(ThisObject.Ref);
	BTCRecordset.Write(True);

EndProcedure
