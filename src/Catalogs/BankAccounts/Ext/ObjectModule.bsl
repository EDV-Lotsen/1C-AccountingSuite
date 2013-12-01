
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
EndProcedure
