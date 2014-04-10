
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
	return Yodlee.RemoveBankAccountAtServer(Item);
	////If we delete the last unmarked bank account then
	////we should remove these accounts from Yodlee
	////If not - just mark for deletion
	//If Item.ItemID = 0 Then
	//	return Yodlee.RemoveBankAccountAtServer(Item);
	//Else
	//	If Item.DeletionMark Then
	//		return New Structure("ReturnValue, Status, CountDeleted, DeletedAccounts", true, "Item is already marked for deletion", 0, New Array());
	//	EndIf;
	//	SetPrivilegedMode(True);
	//	ItemID = Item.ItemID;
	//	Request = New Query("SELECT
	//						|	COUNT(DISTINCT BankAccounts.Ref) AS UsedAccountsCount
	//						|FROM
	//						|	Catalog.BankAccounts AS BankAccounts
	//						|WHERE
	//						|	BankAccounts.ItemID = &ItemID
	//						|	AND BankAccounts.DeletionMark = FALSE");
	//	Request.SetParameter("ItemID",ItemID);
	//	Res = Request.Execute();
	//	Sel = Res.Select();
	//	Sel.Next();
	//	SetPrivilegedMode(False);
	//	If (Sel.UsedAccountsCount = 1) Then
	//		return Yodlee.RemoveBankAccountAtServer(Item);
	//	Else
	//		ReturnStruct = New Structure("ReturnValue, Status, CountDeleted, DeletedAccounts", true, "", 0, New Array());
	//		DeletedAccounts = New Array();
	//		ItemDescription = Item.Description;
	//		DeletedAccounts.Add(Item);
	//		AccObject = Item.GetObject();
	//		AccObject.SetDeletionMark(True);
	//		ReturnStruct.Insert("CountDeleted", 1);
	//		ReturnStruct.Insert("DeletedAccounts", DeletedAccounts);
	//		ReturnStruct.Insert("Status", "Account " + ItemDescription + " was successfully deleted");
	//		return ReturnStruct;
	//	EndIf;
	//EndIf;
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

