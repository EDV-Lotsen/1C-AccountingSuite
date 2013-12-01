
&AtClient
Procedure AddAccount(Command)
	Params = New Structure("PerformAddAccount", True);
	OpenForm("DataProcessor.YodleeBankAccountsManagement.Form.Form", Params, ThisForm,,,,, FormWindowOpeningMode.LockWholeInterface);
EndProcedure

&AtClient
Procedure DeleteAccount(Command)
	//Disconnect from the Provider (Yodlee)
	//Then mark for deletion
	CurrentLine = Items.List.CurrentData;
	CurrentRow 	= Items.List.CurrentRow;
	If CurrentLine = Undefined Then
		return;
	EndIf;
	//Ask a user
	Mode = QuestionDialogMode.YesNoCancel;
	Notify = New NotifyDescription("DeleteAccountAfterQuery", ThisObject, New Structure("CurrentLine, CurrentRow", CurrentLine, CurrentRow));
	ShowQueryBox(Notify, "Bank account " + String(CurrentLine.Description) + " will be deleted. Are you sure?", Mode, 0, DialogReturnCode.Cancel, "Bank accounts"); 
	
EndProcedure

&AtClient
Procedure DeleteAccountAfterQuery(Result, Parameters) Export
	If Result <> DialogReturnCode.Yes Then
		return;
	EndIf;
	
	//Disconnect from the Provider (Yodlee)
	//Then mark for deletion
	CurrentLine = Parameters.CurrentLine;
	CurrentRow	= Parameters.CurrentRow;
	If CurrentLine <> Undefined Then
		ReturnStruct = RemoveAccountAtServer(CurrentRow);
		If ReturnStruct.returnValue Then
			ShowMessageBox(, ReturnStruct.Status,,"Removing bank account");
		Else
			If Find(ReturnStruct.Status, "InvalidItemExceptionFaultMessage") Then
				ShowMessageBox(, "Account not found.",,"Removing bank account");
			Else
				ShowMessageBox(, ReturnStruct.Status,,"Removing bank account");
			EndIf;
		EndIf;
		
		NotifyChanged(Type("CatalogRef.BankAccounts"));
		
	EndIf;
EndProcedure

&AtServerNoContext
Function RemoveAccountAtServer(Item)
	ItemID = Item.ItemID;
	ItemDescription = Item.Description;
	BeginTransaction(DataLockControlMode.Managed);
	ReturnStruct = New Structure("ReturnValue, Status, CountDeleted, DeletedAccounts", false, "", 0, New Array());
	Try
		// Create new managed data lock
		DataLock = New DataLock;

		// Set data lock parameters
		BA_LockItem = DataLock.Add("Catalog.BankAccounts");
		BA_LockItem.Mode = DataLockMode.Exclusive;
		BA_LockItem.SetValue("Ref", Item);
		// Set lock on the object
		DataLock.Lock();
		
		DeletedAccounts = New Array();
		If ItemID = 0 Then
			DeletedAccounts.Add(Item);
			
			AccObject = Item.GetObject();
			AccObject.Delete();
			ReturnStruct.Insert("CountDeleted", 1);
			ReturnStruct.Insert("DeletedAccounts", DeletedAccounts);
			ReturnStruct.Insert("Status", "Account " + ItemDescription + " was successfully deleted");
		Else
			ReturnStruct = Yodlee.RemoveItem(ItemID);
			If (ReturnStruct.ReturnValue) OR (Find(ReturnStruct.Status, "InvalidItemExceptionFaultMessage")) Then
				//Mark bank account as non-Yodlee
				AccRequest = New Query("SELECT
				                       |	BankAccounts.Ref
				                       |FROM
				                       |	Catalog.BankAccounts AS BankAccounts
				                       |WHERE
				                       |	BankAccounts.ItemID = &ItemID");
				AccRequest.SetParameter("ItemID", ItemID);
				AccSelection = AccRequest.Execute().Choose(); 
				cnt = 0;
				While AccSelection.Next() Do
					Try
					
						DeletedAccounts.Add(AccSelection.Ref);
					
						AccObject = AccSelection.Ref.GetObject();
						//AccObject.YodleeAccount = False;
						//AccObject.DeletionMark = True;
						//AccObject.Write();
						AccObject.Delete();
						cnt = cnt + 1;
					Except
					EndTry;				
				EndDo;
				ReturnStruct.Insert("CountDeleted", cnt);
				ReturnStruct.Insert("DeletedAccounts", DeletedAccounts);
				If cnt > 1 Then
					ReturnStruct.Insert("Status", "Accounts with Item ID:" + String(ItemID) + " were successfully deleted");
				Else
					ReturnStruct.Insert("Status", "Account with Item ID:" + String(ItemID) + " was successfully deleted");
				EndIf;
			EndIf;
		EndIf;
		CommitTransaction();
	Except
		Description = ErrorDescription();
		ReturnStruct.ReturnValue 	= False;
		ReturnStruct.Status 		= Description;
		If TransactionActive() Then
			RollbackTransaction();
		EndIf;
	EndTry;
	return ReturnStruct;
EndFunction


&AtClient
Procedure RefreshAccount(Command)
	CurrentLine = Items.List.CurrentData;
	CurrentRow	= Items.List.CurrentRow;

	If Not CurrentLine.YodleeAccount Then
		return;		
	EndIf;
	
	Params = New Structure("PerformRefreshingAccount, RefreshAccount", True, CurrentRow);
	OpenForm("DataProcessor.YodleeBankAccountsManagement.Form.Form", Params, ThisForm,,,,, FormWindowOpeningMode.LockWholeInterface);
EndProcedure


&AtClient
Procedure EditAccount(Command)
	CurrentLine = Items.List.CurrentData;
	CurrentRow	= Items.List.CurrentRow;

	If Not CurrentLine.YodleeAccount Then
		return;		
	EndIf;
	
	Params = New Structure("PerformEditAccount, RefreshAccount", True, CurrentRow);
	OpenForm("DataProcessor.YodleeBankAccountsManagement.Form.Form", Params, ThisForm,,,,, FormWindowOpeningMode.LockWholeInterface);
EndProcedure

