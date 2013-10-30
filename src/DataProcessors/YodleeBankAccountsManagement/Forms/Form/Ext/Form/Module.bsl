
&AtClient
Procedure GetMFAFields(ProgrammaticElems, Params) Export
	If TypeOf(ProgrammaticElems) <> Type("Array") Then
		ShowMessageBox(,"Operation failed. Try to repeat the operation",,"Adding bank accounts");
		Items.ProgressGroup.Visible = False;
		return;
	EndIf;
	
	//Adding items at server
	//Put progress description to temp storage
	Progress = New Structure("Params, CurrentStatus, Step",, "Adding accounts at server...", 2);
	TempStorageAddress = PutToTempStorage(Progress, ThisForm.UUID);
	
	Items.AddingAccountProgress.Title = "Sending authorization reply to server...";
	Items.ProgressGroup.Visible = True;
	AttachIdleHandler("DispatchAddAccount", 0.1, True);
	
	AddItemsAtServer(Params.Bank, ProgrammaticElems, Params.YodleeStorage, TempStorageAddress);

	
	//Result = AddItemsAtServer(Params.Bank, ProgrammaticElems, Params.YodleeStorage);
	//If TypeOf(Result) <> Type("Structure") Then
	//	return;
	//EndIf;
	//If Result.NewItemID <> 0 Then
	//	//DoRefreshItem(newItemId);
	//	GotoRefreshPage(Undefined);
	//	ShowMessageBox(, "Please, refresh a newly added accounts",, "New bank account successfully added");
	//EndIf;	
EndProcedure

&AtServerNoContext
Procedure AddItemsAtServer(Bank, ProgrammaticElems, YodleeStorage, TempStorageAddress)
	//Prepare data for background execution
	ProcParameters = New Array;
 	ProcParameters.Add(Bank.ServiceID);
	ProcParameters.Add(ProgrammaticElems);
	ProcParameters.Add(YodleeStorage);
 	ProcParameters.Add(TempStorageAddress);
	
	//Performing background operation
	JobTitle = NStr("en = 'Adding an account at Yodlee server'");
	Job = BackgroundJobs.Execute("Yodlee.AddItem_AddItem", ProcParameters, , JobTitle);

	//Result = Yodlee.AddItem_AddItem(Bank.ServiceID, ProgrammaticElems, YodleeStorage);
	//return Result;
EndProcedure

&AtClient
Procedure AddAccounts(Command)
	
	//Put progress description to temp storage
	Progress = New Structure("Params, CurrentStatus, Step",, "Obtaining authorization fields from server...", 1);
	TempStorageAddress = PutToTempStorage(Progress, ThisForm.UUID);
	GetMFAFormFieldsAtServer(Bank, TempStorageAddress);
	
	//Show the ProgressGroup, Attach idle handler
	
	Items.AddingAccountProgress.Title = "Obtaining authorization fields from server...";
	Items.ProgressGroup.Visible = True;
	AttachIdleHandler("DispatchAddAccount", 0.1, True);
	
EndProcedure

&AtClient
Procedure DispatchAddAccount() Export
	//Get current status from temp storage
	Progress = GetFromTempStorage(TempStorageAddress);
	If TypeOf(Progress) <> Type("Structure") Then
		Items.ProgressGroup.Visible = False;
		ShowMessageBox(, "An error occured while adding an account",, "Adding bank account");
		return;
	EndIf;
	
	Items.AddingAccountProgress.Title = Progress.CurrentStatus;
	If TypeOf(Progress.Params) <> Type("Structure") Then
		AttachIdleHandler("DispatchAddAccount", 0.1, True);
		return;
	EndIf;
	
	Params = Progress.Params;
	
	If Progress.Step = 1 Then //Obtaining MFA fields
		
		If Not Params.ReturnValue Then
			ShowMessageBox(,"Operation failed. Try to repeat the operation",,"Adding bank accounts");
			Items.ProgressGroup.Visible = False;
			return;
		EndIf;
		
		//Items.ProgressGroup.Visible = False;
		Params.Insert("FormTitle", "Adding account");
		Notify 	= New NotifyDescription("GetMFAFields", ThisObject, New Structure("YodleeStorage, Bank", Params.YodleeStorage, Bank));
		OpenForm("DataProcessor.YodleeBankAccountsManagement.Form.MFA", Params, ThisForm,,,,Notify,FormWindowOpeningMode.LockOwnerWindow);
		
	ElsIf Progress.Step = 2 Then //Adding a bank account at server
		
		If Params.NewItemID <> 0 Then
			//GotoRefreshPage(Undefined);
			AttachIdleHandler("DispatchAddAccount", 0.1, True);
			//ShowMessageBox(, "Please, refresh a newly added accounts",, "New bank account successfully added");
			//ShowCustomMessageBox(ThisForm, "New bank account successfully added", "Please, refresh a newly added accounts", PredefinedValue("Enum.MessageStatus.Information"));
			//Items.ProgressGroup.Visible = False;
			return;
		Else
			//ShowMessageBox(,"Operation failed. Try to repeat the operation",,"Adding bank accounts");
			ShowCustomMessageBox(ThisForm, "Adding bank accounts","Operation failed. Try to repeat the operation", PredefinedValue("Enum.MessageStatus.Warning"));
			Items.ProgressGroup.Visible = False;
		EndIf;	
	ElsIf Progress.Step = 3 Then
		CurrentBankAccount = GetBankAccountByItemID(Params.NewItemID);
		RefreshBankAccount(Params.NewItemID);
		Items.ProgressGroup.Visible = False;
	EndIf;
	
EndProcedure

&AtServerNoContext
Function GetBankAccountByItemID(newItemID)
	Request = New Query("SELECT ALLOWED
	                    |	BankAccounts.Ref
	                    |FROM
	                    |	Catalog.BankAccounts AS BankAccounts
	                    |WHERE
	                    |	BankAccounts.ItemID = &ItemID");
	Request.SetParameter("ItemID", newItemID);
	Result = Request.Execute();
	If Result.IsEmpty() Then
		return Catalogs.BankAccounts.EmptyRef();
	Else
		Sel = Result.Choose();
		Sel.Next();
		return Sel.Ref;
	EndIf;
EndFunction

&AtServerNoContext
Procedure GetMFAFormFieldsAtServer(Bank, TempStorageAddress)
	
	//Prepare data for background execution
	ProcParameters = New Array;
 	ProcParameters.Add(Bank.ServiceID);
 	ProcParameters.Add(TempStorageAddress);
	
	//Performing background operation
	JobTitle = NStr("en = 'Obtaining MFA fields from Yodlee'");
	Job = BackgroundJobs.Execute("Yodlee.AddItem_GetFormFields", ProcParameters, , JobTitle);

	//ReturnStruct = Yodlee.AddItem_GetFormFields(Bank.ServiceID);
	//return ReturnStruct;
EndProcedure

&AtClient
Procedure GotoRefreshPage(Command)
	//If ValueIsFilled(Bank) Then
	//	BankAccounts.Parameters.SetParameterValue("Bank", Bank);
	//Else
	//	BankAccounts.Parameters.SetParameterValue("Bank", PredefinedValue("Catalog.Banks.EmptyRef"));
	//EndIf;
	If PerformRefreshingAccount Then
		Close();
	Else
		Items.BankAccounts.Refresh();
		Items.Pages.CurrentPage = Items.AccountsRefreshPage;
	EndIf;
EndProcedure

&AtClient
Procedure RefreshAccount(Command)
	CurrentBankAccount = Items.BankAccounts.CurrentRow;
	CurData = Items.BankAccounts.CurrentData;
	If CurData = Undefined Then 
		return;
	EndIf;
	ItemID = CurData.ItemID;

	RefreshBankAccount(ItemID);	
	return;
	
EndProcedure

&AtClient
Procedure RefreshBankAccount(ItemID)
	//Put progress description to temp storage
	Progress = New Structure("Params, CurrentStatus, Step",, "Starting the refresh process...", 1);
	TempStorageAddress = PutToTempStorage(Progress, ThisForm.UUID);
	RefreshItemAtServer(ItemID, TempStorageAddress);
	
	//Show the ProgressGroup, Attach idle handler
	
	Items.RefreshingAccountProgress.Title = "Starting the refresh process...";
	Items.RefreshSuccessGroup.Visible = False;
	Items.RefreshFailGroup.Visible = False;
	Items.RefreshProgressGroup.Visible = True;
	AttachIdleHandler("DispatchRefreshAccount", 0.1, True);


	Items.Pages.CurrentPage = Items.AccountRefreshPage;
EndProcedure

&AtClient
Procedure DispatchRefreshAccount() Export
	//Get current status from temp storage
	Progress = GetFromTempStorage(TempStorageAddress);
	If TypeOf(Progress) <> Type("Structure") Then
		Items.RefreshProgressGroup.Visible = False;
		ShowMessageBox(, "An error occured while refreshing an account",, "Refreshing bank account");
		return;
	EndIf;
	
	Items.RefreshingAccountProgress.Title = Progress.CurrentStatus;
	If TypeOf(Progress.Params) <> Type("Structure") Then
		AttachIdleHandler("DispatchRefreshAccount", 0.1, True);
		return;
	EndIf;
	
	Params = Progress.Params;
	
	If Not Params.ReturnValue Then //An error occured during the refresh
		Items.RefreshProgressGroup.Visible = False;
		If Params.Property("Status") Then
			If ValueIsFilled(Params.Status) Then
				Items.DecorationFailReason.Title = Params.Status;
				Items.DecorationFailReason.Title = Items.DecorationFailReason.Title + ?(Find(Params.Status, "repeat") > 0, "", Chars.CR + "Try to repeat the operation after a while.");
			EndIf;
		EndIf;
		Items.RefreshFailGroup.Visible = True;
	EndIf;

	FinishedRefresh = False;
	If Progress.Step = 1 Then //Starting the refresh
		
		If Not Params.ReturnValue Then
			//ShowMessageBox(,"Operation failed. Try to repeat the operation",,"Refreshing bank accounts");
			FinishedRefresh = True;
			//UpdateBankAccounts(True);
			//return;
			
		Else
			
			AttachIdleHandler("DispatchRefreshAccount", 0.1, True);
			
		EndIf;
						
	ElsIf Progress.Step = 2 Then //Started the refresh (for non-MFA sites) or obtaining MFA fields (for MFA)
		
		If Not Params.ReturnValue Then
			//ShowMessageBox(,"Operation failed. Try to repeat the operation",,"Refreshing bank accounts");
			FinishedRefresh = True;
			//UpdateBankAccounts(True);
			//return;
		Else
			AttachIdleHandler("DispatchRefreshAccount", 0.1, True);	
		EndIf;
		
	ElsIf Progress.Step = 3 Then //Finished the refresh (for non-MFA sites)
		If Params.ReturnValue Then
			Items.RefreshProgressGroup.Visible = False;
			Items.RefreshFailGroup.Visible = False;
			Items.RefreshSuccessGroup.Visible = True;			
		EndIf;
		
		FinishedRefresh = True;
		
		//UpdateBankAccounts(True);
		
	ElsIf Progress.Step = 4 Then //Processing MFA 
		If Params.ReturnValue Then
			If Params.isMFA Then
				//Open MFA form
				NotifyParams = New Structure("ItemId", Params.ItemID);
				NotifyParams.Insert("YodleeStorage", Params.YodleeStorage);
				Params.Insert("FormTitle", "Refreshing account");
				Notify 	= New NotifyDescription("ContinueMFARefresh", ThisObject, NotifyParams);
				OpenForm("DataProcessor.YodleeBankAccountsManagement.Form.MFA", Params, ThisForm,,,,Notify,FormWindowOpeningMode.LockOwnerWindow);
			EndIf;
			//AttachIdleHandler("DispatchRefreshAccount", 0.1, True);
		Else
			FinishedRefresh = True;
			//UpdateBankAccounts(True);
		EndIf;

	ElsIf Progress.Step = 5 Then //Polling refresh status. Finishing the refresh for MFA sites
		If Params.ReturnValue Then
			If Params.IsMFA Then //Wait for polling to finish
				AttachIdleHandler("DispatchRefreshAccount", 0.1, True);
			Else  //Successfully finished the refresh
				If Params.ReturnValue Then
					Items.RefreshProgressGroup.Visible = False;
					Items.RefreshFailGroup.Visible = False;
					Items.RefreshSuccessGroup.Visible = True;			
				EndIf;
				FinishedRefresh = True;
			EndIf;
		Else
			FinishedRefresh = True;
			//UpdateBankAccounts(True);
		EndIf;
	ElsIf Progress.Step = 6 Then //Started uploading transactions
		If Params.ReturnValue Then
			AttachIdleHandler("DispatchRefreshAccount", 0.1, True);
		EndIf;
	ElsIf Progress.Step = 7 Then //Transactions upload is complete
		If Params.ReturnValue Then
			Items.DecorationSuccessReason.Title = Progress.CurrentStatus;
			Items.RefreshSuccessGroup.Visible = True;
			//Items.RefreshFailGroup.Visible = False;
			Items.RefreshProgressGroup.Visible = False;
		EndIf;
		UpdateBankAccounts(True); //Final update of the accounts
	EndIf;
	
	//If the refresh process is complete - perform some actions
	If FinishedRefresh Then
		//If refreshing from Downloaded Transactions - need to refresh transactions
		If PerformRefreshingAccount Then
			Items.RefreshProgressGroup.Visible = True;
			YodleeStorage = ?(Progress.Property("YodleeStorage"), Progress.YodleeStorage, Undefined);
			RefreshTransactionsAtServer(CurrentBankAccount, TempStorageAddress, UploadTransactionsFrom, UploadTransactionsTo, YodleeStorage);
			AttachIdleHandler("DispatchRefreshAccount", 0.1, True);
		Else
			UpdateBankAccounts(True);//Delete uninitialized accounts
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdateBankAccounts(DeleteUninitializedAccounts = False)
	UpdateBankAccountsAtServer(DeleteUninitializedAccounts);
	AttachIdleHandler("RefreshAccountsList", 0.2, True);
	AttachIdleHandler("RefreshAccountsList", 3, True);
EndProcedure

&AtServerNoContext
Procedure UpdateBankAccountsAtServer(DeleteUninitializedAccounts = False)
	Params = New Array();
	If DeleteUninitializedAccounts Then
		Params.Add(Undefined);
		Params.Add(True);
	EndIf;
	LongActions.ExecuteInBackground("Yodlee.YodleeUpdateBankAccounts", Params);
EndProcedure

&AtClient
Procedure RefreshAccountsList() Export
	Items.BankAccounts.Refresh();
EndProcedure

&AtClient
Procedure ContinueMFARefresh(ProgrammaticElems, Params) Export
	//Put progress description to temp storage
	Progress = New Structure("Params, CurrentStatus, Step",, "Sending user response to the server...", 4);
	PutToTempStorage(Progress, TempStorageAddress);

	Params = ContinueMFARefreshAtServer(ProgrammaticElems, Params, TempStorageAddress);
	
	AttachIdleHandler("DispatchRefreshAccount", 0.1, True);
	
	return;
	
	If TypeOf(Params) <> Type("Structure") Then
		return;
	EndIf;
	If Not Params.ReturnValue Then
		Items.BankAccounts.CurrentData.Status = Params.Status; 
		ShowMessageBox(,Params.Status,,"Refreshing bank accounts");
		UpdateBankAccounts();
		return;
	EndIf;
	If Params.isMFA Then
		//Open MFA form
		NotifyParams = New Structure("ItemId", Params.ItemID);
		NotifyParams.Insert("YodleeStorage", Params.YodleeStorage);
		Params.Insert("FormTitle", "Refreshing account");
		Notify 	= New NotifyDescription("ContinueMFARefresh", ThisObject, NotifyParams);
		OpenForm("DataProcessor.YodleeBankAccountsManagement.Form.MFA", Params, ThisForm,,,,Notify,FormWindowOpeningMode.LockOwnerWindow);
	Else
		UpdateBankAccounts();
		Items.BankAccounts.CurrentData.Status = Params.Status;
	EndIf;	
EndProcedure

&AtServerNoContext
Function ContinueMFARefreshAtServer(ProgrammaticElems, Params, TempStorageAddress)
	//Prepare data for background execution
	ProcParameters = New Array;
 	ProcParameters.Add(ProgrammaticElems);
	ProcParameters.Add(Params);
	ProcParameters.Add(TempStorageAddress);
 		
	//Performing background operation
	JobTitle = NStr("en = 'Processing user response in the refresh bank account process'");
	Job = BackgroundJobs.Execute("Yodlee.ContinueMFARefresh", ProcParameters, , JobTitle);

	//Params = Yodlee.ContinueMFARefresh(ProgrammaticElems, Params);
	//return Params;
EndFunction


&AtServerNoContext
Procedure RefreshItemAtServer(ItemID, TempStorageAddress)
	//Prepare data for background execution
	ProcParameters = New Array;
 	ProcParameters.Add(ItemID);
	ProcParameters.Add(Undefined);
	ProcParameters.Add(Undefined);
 	ProcParameters.Add(TempStorageAddress);
	
	//Performing background operation
	JobTitle = NStr("en = 'Starting the refresh bank account process'");
	Job = BackgroundJobs.Execute("Yodlee.RefreshItem", ProcParameters, , JobTitle);
EndProcedure

&AtServerNoContext
Procedure RefreshTransactionsAtServer(CurrentBankAccount, TempStorageAddress, UploadTransactionsFrom, UploadTransactionsTo, YodleeStorage = Undefined)
	//Prepare data for background execution
	ProcParameters = New Array;
 	ProcParameters.Add(CurrentBankAccount);
	ProcParameters.Add(UploadTransactionsFrom);
	ProcParameters.Add(UploadTransactionsTo);
 	ProcParameters.Add(TempStorageAddress);
	ProcParameters.Add(YodleeStorage);
	
	//Performing background operation
	JobTitle = NStr("en = 'Refreshing transactions of the bank account'");
	Job = BackgroundJobs.Execute("Yodlee.ViewTransactions", ProcParameters, , JobTitle);
EndProcedure

&AtClient
Procedure RemoveAccount(Command)
	CurrentLine = Items.BankAccounts.CurrentData;
	If CurrentLine <> Undefined Then
		ReturnStruct = RemoveAccountAtServer(CurrentLine.ItemID);
		If ReturnStruct.returnValue Then
			ShowMessageBox(, ReturnStruct.Status,,"Removing bank account");
		Else
			If Find(ReturnStruct.Status, "InvalidItemExceptionFaultMessage") Then
				ShowMessageBox(, "Account not found.",,"Removing bank account");
			Else
				ShowMessageBox(, ReturnStruct.Status,,"Removing bank account");
			EndIf;
		EndIf;
	EndIf;
	UpdateBankAccounts();
EndProcedure

&AtServerNoContext
Function RemoveAccountAtServer(ItemID)
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
		While AccSelection.Next() Do
			Try
				AccObject = AccSelection.Ref.GetObject();
				AccObject.YodleeAccount = False;
				AccObject.Write();
			Except
			EndTry;				
		EndDo;
	EndIf;
	return ReturnStruct;
EndFunction

&AtClient
Procedure GotoAddAccountsPage(Command)
	Items.Pages.CurrentPage = Items.AccountsAddPage;
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	BankAccounts.Parameters.SetParameterValue("Bank", Catalogs.Banks.EmptyRef());
	Items.ProgressGroup.Visible = False;
	CurrentBankAccount = Parameters.RefreshAccount;
	PerformRefreshingAccount = Parameters.PerformRefreshingAccount;
	UploadTransactionsFrom = Parameters.UploadTransactionsFrom;
	UploadTransactionsTo = Parameters.UploadTransactionsTo;
	If PerformRefreshingAccount Then		
		Items.AccountsRefreshPage.Visible = False;
		//Delete white spaces to the right ant to the left
		Items.RefreshLeftTab.Visible = False;
		Items.RefreshRightTab.Visible = False;
		Items.GotoAssigningPage.Visible = False;
	EndIf;
EndProcedure

&AtClient
Procedure ShowCustomMessageBox(FormOwner, Title = "", Message, MessageStatus = Undefined)
	If MessageStatus = Undefined Then 
		MessageStatus = PredefinedValue("Enum.MessageStatus.NoStatus");
	EndIf;
	If Not ValueIsFilled(Title) Then
		Title = "Message";
	EndIf;
	Params = New Structure("Title, Message, MessageStatus", Title, Message, MessageStatus);
	OpenForm("CommonForm.MessageBox", Params, FormOwner,,,,, FormWindowOpeningMode.LockOwnerWindow); 
EndProcedure


&AtClient
Procedure RefreshList(Command)
	RefreshListAtServer();
	Items.BankAccounts.Refresh();
EndProcedure


&AtServerNoContext
Procedure RefreshListAtServer()
	Yodlee.YodleeUpdateBankAccounts(, True);
EndProcedure


&AtClient
Procedure ShowAllAccounts(Command)
	BankAccounts.Parameters.SetParameterValue("Bank", PredefinedValue("Catalog.Banks.EmptyRef"));
	Items.BankAccounts.Refresh();
EndProcedure


&AtClient
Procedure BankOnChange(Item)
	LogotypeAddress = GetLogotypeAddress(Bank);
EndProcedure

&AtServerNoContext
Function GetLogotypeAddress(Bank)
	If ValueIsFilled(Bank.Logotype.Get()) Then
		LogotypeAddress = GetURL(Bank, "Logotype");
	ElsIf ValueIsFilled(Bank.Icon.Get()) Then
		LogotypeAddress = GetURL(Bank, "Icon");
	Else		
		LogotypeAddress = "";
	EndIf;
	return LogotypeAddress;
EndFunction

&AtClient
Procedure OnOpen(Cancel)
	If PerformRefreshingAccount Then
		ItemID = CommonUse.GetAttributeValue(CurrentBankAccount, "ItemID");
		RefreshBankAccount(ItemID);
	EndIf;
EndProcedure

&AtClient
Procedure Decoration10Click(Item)
	OpenForm("DataProcessor.YodleeBankAccountsManagement.Form.Video", New Structure, ThisForm,,,,,FormWindowOpeningMode.LockWholeInterface);
EndProcedure

&AtClient
Procedure GotoAssigningPage(Command)
	Items.Pages.CurrentPage = Items.AccountAssignTypePage;
	FillAvailableAccounts();
EndProcedure

&AtClient 
Procedure FillAvailableAccounts()
	AvailableList = GetAvailableListOfAccounts();
	Items.BankAccountType.ChoiceList.Clear();
	For Each El IN AvailableList Do
		Items.BankAccountType.ChoiceList.Add(El.Value, El.Presentation);
	EndDo;
EndProcedure

&AtServerNoContext
Function GetAvailableListOfAccounts()
	Request = New Query("SELECT
	                    |	ChartOfAccounts.Ref,
	                    |	ChartOfAccounts.AccountType,
	                    |	ChartOfAccounts.Code,
	                    |	ChartOfAccounts.Description
	                    |FROM
	                    |	ChartOfAccounts.ChartOfAccounts AS ChartOfAccounts
	                    |		LEFT JOIN Catalog.BankAccounts AS BankAccounts
	                    |		ON (BankAccounts.AccountingAccount = ChartOfAccounts.Ref)
	                    |WHERE
	                    |	BankAccounts.Ref IS NULL 
	                    |	AND ChartOfAccounts.AccountType IN(&ListOfAvailableTypes)");
	ListOfAvailableTypes = New ValueList();
	ListOfAvailableTypes.Add(Enums.AccountTypes.Bank);
	ListOfAvailableTypes.Add(Enums.AccountTypes.OtherCurrentAsset);
	ListOfAvailableTypes.Add(Enums.AccountTypes.OtherCurrentLiability);
	Request.SetParameter("ListOfAvailableTypes", ListOfAvailableTypes);
	RequestRes = Request.Execute();
	AvailableList = New ValueList();
	If Not RequestRes.IsEmpty() Then
		Sel = RequestRes.Choose();
		While Sel.Next() Do
			AvailableList.Add(Sel.Ref, String(Sel.AccountType) + " (" + String(Sel.Code) + "-" + Sel.Description + ")");
		EndDo;
	EndIf;
	return AvailableList;
EndFunction

&AtClient
Procedure AssignAccountType(Command)
	ReturnStructure = AssignAccountTypeAtServer(CurrentBankAccount, BankAccountType);
	If Not ReturnStructure.ReturnValue Then
		Items.AssigningFailReason.Title = "Assigning failed. Reason:" + ReturnStructure.ErrorMessage + " Please, choose an account type once again.";
		Items.AssigningFailGroup.Visible = True;
		Items.AssigningSuccessGroup.Visible = False;
		FillAvailableAccounts();
	Else
		Items.AssigningFailGroup.Visible = False;
		Items.AssigningSuccessGroup.Visible = True;
	EndIf;
EndProcedure

&AtServerNoContext
Function AssignAccountTypeAtServer(CurrentBankAccount, BankAccountType)
	ReturnStructure = New Structure("ReturnValue, ErrorMessage", True, "");
	BAObject = CurrentBankAccount.GetObject();
	BAObject.AccountingAccount = BankAccountType;
	GetUserMessages(True);
	Try
		BAObject.Write();
	Except
		UM = GetUserMessages(True);
		If UM.Count()>0 Then
			ReturnStructure.ErrorMessage = UM[0].Text;
		Else
			ReturnStructure.ErrorMessage = ErrorDescription();
		EndIf;
		ReturnStructure.ReturnValue = False;	
	EndTry;
	return ReturnStructure;
EndFunction
