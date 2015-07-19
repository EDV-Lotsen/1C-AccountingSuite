
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If (Not Constants.ServiceDB.Get()) And (Not Parameters.PerformAssignAccount) Then
		Cancel = True;
		return;
	EndIf;
	
EndProcedure

&AtClient
Procedure BankOnChange(Item)
	FillDetailsAtServer();
EndProcedure

&AtServer
Procedure FillDetailsAtServer()
	LogotypeAddress = GetLogotypeAddress(Bank);
	Items.ServiceURL.Title = Bank.ServiceURL;
EndProcedure

&AtServer
Procedure ChooseBankAtServer(ServiceID)
	Request = New Query("SELECT
	                    |	Banks.Ref
	                    |FROM
	                    |	Catalog.Banks AS Banks
	                    |WHERE
	                    |	Banks.ServiceID = &ServiceID");
	Request.SetParameter("ServiceID", ServiceID);
	
	Result = Request.Execute();
	If Not Result.IsEmpty() Then
		BankTab = Result.Unload();
		Bank = BankTab[0].Ref;
		LogotypeAddress = GetLogotypeAddress(Bank);
		Items.ServiceURL.Title = Bank.ServiceURL;
	EndIf;	
EndProcedure

&AtClient
Procedure ChooseWellsFargo(Command)
	ChooseBankAtServer(5);
EndProcedure

&AtClient
Procedure ChooseAmericanExpressCreditCard(Command)
	ChooseBankAtServer(12);
EndProcedure

&AtClient
Procedure ChooseBankOfAmerica(Command)
	ChooseBankAtServer(2931);
EndProcedure

&AtClient
Procedure ChooseChaseBank(Command)
	ChooseBankAtServer(663);
EndProcedure

&AtClient
Procedure ChooseJPMorganChaseBank(Command)
	ChooseBankAtServer(663);
EndProcedure

&AtClient
Procedure ChoosePayPalBank(Command)
	ChooseBankAtServer(10817);
EndProcedure

&AtClient
Procedure ChooseUSBank(Command)
	ChooseBankAtServer(545);
EndProcedure

&AtClient
Procedure ChooseCapitalOneCreditCard(Command)
	ChooseBankAtServer(2935);
EndProcedure

&AtClient
Procedure ChooseSunTrustBank(Command)
	ChooseBankAtServer(12729);
EndProcedure

&AtClient
Procedure ChoosePNCBank(Command)
	ChooseBankAtServer(2199);
EndProcedure

&AtClient
Procedure AddAccounts(Command)
	
	UserCancelledAccountAddition = False;
	//Put progress description to temp storage
	Progress = New Structure("Params, CurrentStatus, Step",, "Obtaining authorization fields from server...", 1);
	TempStorageAddress = PutToTempStorage(Progress, ThisForm.UUID);
	GetMFAFormFieldsAtServer(Bank, TempStorageAddress);
	
	//Show the ProgressGroup, Attach idle handler
	
	Items.AddingAccountProgress.Title = "Obtaining authorization fields from server...";
	ShowAdditionProgress(ThisForm);
	AttachIdleHandler("DispatchAddAccount", 0.1, True);
	
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

&AtServerNoContext
Procedure GetMFAFormFieldsAtServer(Bank, TempStorageAddress)
	
	//Prepare data for background execution
	ProcParameters = New Array;
 	ProcParameters.Add(Bank.ServiceID);
 	ProcParameters.Add(TempStorageAddress);
	
	//Performing background operation
	JobTitle = NStr("en = 'Obtaining MFA fields from Yodlee'");
	Job = BackgroundJobs.Execute("YodleeRest.AddItem_GetFormFields", ProcParameters, , JobTitle);

EndProcedure

&AtClient
Procedure DispatchAddAccount() Export
	
	If UserCancelledAccountAddition Then
		return;
	EndIf;
	//Get current status from temp storage
	Progress = GetFromTempStorage(TempStorageAddress);
	If TypeOf(Progress) <> Type("Structure") Then
		ShowStartPage(ThisForm);
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
			ShowStartPage(ThisForm);
			return;
		EndIf;
		
		Params.Insert("FormTitle", "Adding account");
		Notify 	= New NotifyDescription("AddAccount", ThisObject, New Structure("Bank, ComponentList", Bank, Params.ComponentList));
		OpenForm("DataProcessor.YodleeAccountsManagement.Form.MFA", Params, ThisForm,,,,Notify,FormWindowOpeningMode.LockOwnerWindow);
	ElsIf Progress.Step = 2 Then //Adding a bank account at server
		
		If Params.NewItemID <> 0 Then
			AttachIdleHandler("DispatchAddAccount", 0.1, True);
			return;
		Else
			CommonUseClient.ShowCustomMessageBox(ThisForm, "Adding bank accounts","Operation failed. Try to repeat the operation after a while.", PredefinedValue("Enum.MessageStatus.Warning"));
			ShowStartPage(ThisForm);
		EndIf;	
	ElsIf Progress.Step = 3 Then
		//Mark the newly created account as disconnected, to delete it later in case of an operation failure
		MarkBankAccountAsDisconnected(Params.NewItemID, 0);
		CurrentItemID = Params.NewItemID;
		RefreshBankAccount(Params.NewItemID);
	EndIf;
	
EndProcedure

&AtClient
Procedure AddAccount(ProgrammaticElems, Params) Export
	
	If TypeOf(ProgrammaticElems) <> Type("Array") Then
		ShowMessageBox(,"Operation failed. Try to repeat the operation",,"Adding bank accounts");
		ShowStartPage(ThisForm);
		return;
	EndIf;
	
	//Adding items at server
	//Put progress description to temp storage
	Progress = New Structure("Params, CurrentStatus, Step",, "Adding accounts at server...", 2);
	TempStorageAddress = PutToTempStorage(Progress, ThisForm.UUID);
	
	Items.AddingAccountProgress.Title = "Sending authorization reply to server...";
	AttachIdleHandler("DispatchAddAccount", 0.1, True);
	
	AddAccountAtServer(Params.Bank, ProgrammaticElems, Params.ComponentList, TempStorageAddress);
	
EndProcedure

&AtServerNoContext
Procedure AddAccountAtServer(Bank, ProgrammaticElems, ComponentList, TempStorageAddress)
	//Prepare data for background execution
	ProcParameters = New Array;
 	ProcParameters.Add(Bank.ServiceID);
	ProcParameters.Add(ProgrammaticElems);
	ProcParameters.Add(ComponentList);
	ProcParameters.Add(TempStorageAddress);
	
	//Performing background operation
	JobTitle = NStr("en = 'Adding an account at Yodlee server'");
	Job = BackgroundJobs.Execute("YodleeREST.AddItem_AddItem", ProcParameters, , JobTitle);

EndProcedure

&AtClient
Procedure RefreshBankAccount(ItemID)
	//Put progress description to temp storage
	Progress = New Structure("Params, CurrentStatus, Step",, "Communicating with your bank...", 1);
	TempStorageAddress = PutToTempStorage(Progress, ThisForm.UUID);
	//TransactionsFromDate 	= Undefined;
	//TransactionsToDate		= Undefined;
	//If ValueIsFilled(UploadTransactionsFrom) Then
	//	TransactionsFromDate = UploadTransactionsFrom;
	//EndIf;
	//If ValueIsFilled(UploadTransactionsTo) Then
	//	TransactionsToDate = UploadTransactionsTo;
	//EndIf;
	RefreshItemAtServer(ItemID, TempStorageAddress);
	
	//Show the ProgressGroup, Attach idle handler
	
	//Items.RefreshingAccountProgress.Title = "Starting the refresh process...";
	//HideMessageToTheUser();
	//ShowProgress();
	AttachIdleHandler("DispatchRefreshAccount", 0.1, True);
		
	//Items.Pages.CurrentPage = Items.AccountRefreshPage;
		
	//Items.GotoAssigningPage.Visible = False;
EndProcedure

&AtClient
Procedure DispatchRefreshAccount() Export
	
	If UserCancelledAccountAddition Then
		return;
	EndIf;
	
	//Get current status from temp storage
	Progress = GetFromTempStorage(TempStorageAddress);
	If TypeOf(Progress) <> Type("Structure") Then
		ShowStartPage(ThisForm);
		ShowMessageBox(, "Our apologies, but we can't connect your bank at the moment. Our team is working on resolving this",, "Adding bank account");
		return;
	EndIf;
	
	Items.AddingAccountProgress.Title = Progress.CurrentStatus;
	If TypeOf(Progress.Params) <> Type("Structure") Then
		AttachIdleHandler("DispatchRefreshAccount", 0.1, True);
		return;
	EndIf;

	Params = Progress.Params;
	
	If Not Params.ReturnValue Then //An error occured during the refresh
		
		ShowStartPage(ThisForm);
				
		If Params.Property("Status") Then
			If ValueIsFilled(Params.Status) Then
				ShowMessageBox(, Params.Status,, "Adding bank account");
			Else
				ShowMessageBox(, "Our apologies, but we can't connect your bank at the moment. Try to repeat the operation after a while",, "Adding bank account");
			EndIf;
		Else
			ShowMessageBox(, "Our apologies, but we can't connect your bank at the moment. Try to repeat the operation after a while",, "Adding bank account");
		EndIf;
		return;
	EndIf;

	FinishedRefresh = False;
	
	If Progress.Step = 1 Then //Starting the refresh
		
		AttachIdleHandler("DispatchRefreshAccount", 0.1, True);	
								
	ElsIf Progress.Step = 2 Then //Successfully refreshed bank account (for non-MFA sites)
		
		GotoAssigningPageAtServer(Params);
		
	ElsIf Progress.Step = 3 Then //Processing MFA 
		
		If Params.isMFA Then
			//Open MFA form
			NotifyParams = New Structure("ItemId", Params.ItemID);
			Params.Insert("FormTitle", "Refreshing account");
			Notify 	= New NotifyDescription("ContinueMFARefresh", ThisObject, NotifyParams);
			OpenForm("DataProcessor.YodleeAccountsManagement.Form.MFA", Params, ThisForm,,,,Notify,FormWindowOpeningMode.LockOwnerWindow);
		EndIf;

	EndIf;
	
		
	//ElsIf Progress.Step = 3 Then //Finished the refresh (for non-MFA sites)
	//	If Params.ReturnValue Then
	//		ShowMessageToTheUser("Success", "Bank account was successfully refreshed");
	//	EndIf;
	//	
	//	FinishedRefresh = True;
	//	
	//ElsIf Progress.Step = 4 Then //Processing MFA 
	//	If Params.ReturnValue Then
	//		If Params.isMFA Then
	//			//Open MFA form
	//			NotifyParams = New Structure("ItemId", Params.ItemID);
	//			NotifyParams.Insert("YodleeStorage", Params.YodleeStorage);
	//			Params.Insert("FormTitle", "Refreshing account");
	//			Notify 	= New NotifyDescription("ContinueMFARefresh", ThisObject, NotifyParams);
	//			OpenForm("DataProcessor.YodleeBankAccountsManagement.Form.MFA", Params, ThisForm,,,,Notify,FormWindowOpeningMode.LockOwnerWindow);
	//		EndIf;
	//	Else
	//		FinishedRefresh = True;
	//	EndIf;

	//ElsIf Progress.Step = 5 Then //Polling refresh status. Finishing the refresh for MFA sites
	//	If Params.ReturnValue Then
	//		If Params.IsMFA Then //Wait for polling to finish
	//			AttachIdleHandler("DispatchRefreshAccount", 0.1, True);
	//		Else  //Successfully finished the refresh
	//			If Params.ReturnValue Then
	//				ShowMessageToTheUser("success", "Bank account was successfully refreshed");
	//			EndIf;
	//			FinishedRefresh = True;
	//		EndIf;
	//	Else
	//		FinishedRefresh = True;
	//	EndIf;
	//ElsIf Progress.Step = 6 Then //Started uploading transactions
	//	If Params.ReturnValue Then
	//		AttachIdleHandler("DispatchRefreshAccount", 0.1, True);
	//	EndIf;
	//ElsIf Progress.Step = 7 Then //Transactions upload is complete
	//	If Params.ReturnValue Then
	//		ShowMessageToTheUser("success", Progress.CurrentStatus);
	//	EndIf;
	//	UpdateBankAccounts(True, TempStorageAddress); //Final update of the accounts
	//	AttachIdleHandler("DispatchRefreshAccount", 0.1, True);
	//ElsIf Progress.Step = 8 Then //Refreshing bank accounts requisites
	//	If Not Params.ReturnValue Then
	//		HideProgress(false);
	//	Else
	//		AttachIdleHandler("DispatchRefreshAccount", 0.1, True);
	//	EndIf;
	//ElsIf Progress.Step = 9 Then //Refreshing bank accounts requisites has finished
	//	If Not PerformRefreshingAccount AND Not PerformEditAccount Then
	//		ItemAccountID = CommonUse.GetAttributeValue(CurrentBankAccount, "ItemAccountID");
	//		//Items.GotoAssigningPage.Visible = ValueIsFilled(ItemAccountID);	
	//		If ValueIsFilled(ItemAccountID) Then
	//			GotoAssigningPage(Undefined);
	//		Else
	//			If PerformAddAccount Then
	//				HideProgress(False, "An error occured. Account was not added!");
	//			Else
	//				HideProgress(False);
	//			EndIf;
	//			HideMessageToTheUser("success");
	//			CurrentBankAccount = PredefinedValue("Catalog.BankAccounts.EmptyRef");
	//		EndIf;
	//	Else
	//		HideProgress(true);
	//		If Not CalledForSingleOperation Then //Called from inside of this data processor
	//			PerformRefreshingAccount = False;
	//			PerformEditAccount = False;
	//		EndIf;
	//	EndIf;
	//	NotifyChanged(Type("CatalogRef.BankAccounts"));
	//EndIf;
	//
	////If the refresh process is complete - perform some actions
	//If FinishedRefresh Then
	//	
	//	//If refreshing from Downloaded Transactions - need to refresh transactions
	//	ShowProgress();
	//	YodleeStorage = ?(Progress.Property("YodleeStorage"), Progress.YodleeStorage, Undefined);
	//	PutToTempStorage(New Structure("Params, CurrentStatus, Step", Undefined, "Started selecting transactions...", 6), TempStorageAddress);
	//	RefreshTransactionsAtServer(CurrentBankAccount, TempStorageAddress, UploadTransactionsFrom, UploadTransactionsTo, YodleeStorage);
	//	AttachIdleHandler("DispatchRefreshAccount", 0.1, True);
	//EndIf;
	
EndProcedure

&AtClient
Procedure ContinueMFARefresh(ProgrammaticElems, Params) Export
	//Put progress description to temp storage
	Progress = New Structure("Params, CurrentStatus, Step",, "Sending user response to the server...", 3);
	PutToTempStorage(Progress, TempStorageAddress);

	Params = ContinueMFARefreshAtServer(ProgrammaticElems, Params, TempStorageAddress);
	
	AttachIdleHandler("DispatchRefreshAccount", 0.1, True);
		
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
	Job = BackgroundJobs.Execute("YodleeREST.ContinueMFARefresh", ProcParameters, , JobTitle);

EndFunction

//Starts the refresh procedure of an account with ItemID
&AtServerNoContext
Procedure RefreshItemAtServer(ItemID, TempStorageAddress, TransactionsFromDate = Undefined, TransactionsToDate = Undefined)
	
	ProcParameters = New Array;
	ProcParameters.Add(ItemID);
	ProcParameters.Add(TempStorageAddress);
	ProcParameters.Add(TransactionsFromDate);
	ProcParameters.Add(TransactionsToDate);
	
	//Performing background operation
	JobTitle = NStr("en = 'Starting the refresh bank account process'");
	Job = BackgroundJobs.Execute("YodleeREST.RefreshItem", ProcParameters, , JobTitle);

EndProcedure

&AtServer
Procedure GotoAssigningPageAtServer(Params)
	FillAssigningTable(Params.BankAccounts);
	FillAvailableAccounts(ThisForm);
	ApplyConditionalAppearance();
	Items.Pages.CurrentPage = Items.AccountAssignTypePage;
EndProcedure

&AtServer
Procedure FillAssigningTable(BankAccounts)
	AssigningAccountType.Clear();
	DefaultBankAccount = Constants.BankAccount.Get();
	DefaultBankAccountFilled = ?(ValueIsFilled(DefaultBankAccount), True, False);
	For Each BA IN BankAccounts Do
		NewRow = AssigningAccountType.Add();
		NewRow.Connect 					= True; //Mark newly added accounts to connect
		NewRow.BankAccountDescription 	= BA.Description;
		NewRow.ContainerType 			= Bank.ContainerType;
		FillPropertyValues(NewRow, BA, "ItemID, ItemAccountID, LastUpdatedTimeUTC, Type, LastUpdateAttemptTimeUTC, NextUpdateTimeUTC, CurrentBalance, AvailableBalance, RefreshStatusCode, CreditCard_TotalCreditline, CreditCard_AmountDue, UploadStartDate");
		NewRow.BankTransactions 		= New ValueStorage(BA.BankTransactions);
		If AssigningAccountType.Count() = 1 And NOT DefaultBankAccountFilled Then
			NewRow.SetDefault = True;
		EndIf;
		AvailableAccounts = GetAvailableListOfAccounts(, NewRow.BankAccount);
		//Exclude items already used
		For Each Str In AssigningAccountType Do
			If Str = NewRow Then
				Continue;
			EndIf;
			FoundItem = AvailableAccounts.FindByValue(Str.AccountType);
			If FoundItem <> Undefined Then
				AvailableAccounts.Delete(FoundItem);
			EndIf;
		EndDo;
		For Each AvailableAccount In AvailableAccounts Do
			Presentation = AvailableAccount.Presentation;
			Pos = Find(Presentation, NewRow.BankAccountDescription);
			If (Pos > 1) And Mid(Presentation, Pos-1, 1) = "-" Then
				NewRow.AccountType = AvailableAccount.Value;
				Break;
			EndIf;
		EndDo;
	EndDo;
EndProcedure

&AtClientAtServerNoContext 
Procedure FillAvailableAccounts(ThisForm)
	Items = ThisForm.Items;
	#If Client Then
	CurrentData = Items.AssigningAccountType.CurrentData;
	#EndIf
	#If Server Then
	CurrentData = Undefined;
	#EndIf
	If CurrentData <> Undefined Then
		If ValueIsFilled(CurrentData.AccountType) Then
			AvailableList = GetAvailableListOfAccounts(CurrentData.AccountType, CurrentData.BankAccount);
		Else
			AvailableList = GetAvailableListOfAccounts(, CurrentData.BankAccount);
		EndIf;
	Else
		AvailableList = GetAvailableListOfAccounts();	
	EndIf;
	
	AppropriateGLAccountFound = False;
	ChoiceList = Items.AssigningAccountTypeAccountType.ChoiceList;
	ChoiceList.Clear();
	For Each El IN AvailableList Do
		ChoiceList.Add(El.Value, El.Presentation);
		If CurrentData <> Undefined Then
			If Find(El.Presentation, CurrentData.BankAccountDescription) > 0 Then
				AppropriateGLAccountFound = True;
			EndIf;
		EndIf;
	EndDo;
	//Exclude items already used
	For Each Str In ThisForm.AssigningAccountType Do
		If Str = CurrentData Then
			Continue;
		EndIf;
		FoundItem = ChoiceList.FindByValue(Str.AccountType);
		If FoundItem <> Undefined Then
			ChoiceList.Delete(FoundItem);
		EndIf;
	EndDo;
	//If an account with the same name as bank account is absent then add one
	If Not AppropriateGLAccountFound And (CurrentData <> Undefined) Then
		ChoiceList.Add(1, "Create new G/L account...");
	EndIf;
EndProcedure

&AtServer
Procedure ApplyConditionalAppearance()
	
	CA = ThisForm.ConditionalAppearance; 
 	CA.Items.Clear(); 
	
	//Highlighting Account type column with pink back-color
	ElementCA = CA.Items.Add(); 
	
	FieldAppearance = ElementCA.Fields.Items.Add(); 
	FieldAppearance.Field = New DataCompositionField("AssigningAccountTypeAccountType"); 
 	FieldAppearance.Use = True; 

	FilterElement = ElementCA.Filter.Items.Add(Type("DataCompositionFilterItem")); // current row filter 
	FilterElement.LeftValue 		= New DataCompositionField("AssigningAccountType.AssigningFailed"); 
	FilterElement.ComparisonType 	= DataCompositionComparisonType.Equal; 
	FilterElement.RightValue 		= True; 
	FilterElement.Use				= True;
	
	ElementCA.Appearance.SetParameterValue("BackColor", WebColors.MistyRose);
	
	//Inform the user about the creation of a new G/L account
	ElementCA = CA.Items.Add(); 
	
	FieldAppearance = ElementCA.Fields.Items.Add(); 
	FieldAppearance.Field = New DataCompositionField("AssigningAccountTypeAccountType"); 
	FieldAppearance.Use = True; 

	FilterElement = ElementCA.Filter.Items.Add(Type("DataCompositionFilterItem")); // current row filter 
	FilterElement.LeftValue 		= New DataCompositionField("AssigningAccountType.AccountType"); 
	FilterElement.ComparisonType 	= DataCompositionComparisonType.Equal; 
	FilterElement.RightValue 		= ChartsOfAccounts.ChartOfAccounts.EmptyRef(); 
	FilterElement.Use				= True;
		
	ElementCA.Appearance.SetParameterValue("Text", "Create new or map to existing...");
	ElementCA.Appearance.SetParameterValue("TextColor", WebColors.Green);
	ElementCA.Appearance.SetParameterValue("MarkIncomplete", True);
		
	ElementCA = CA.Items.Add(); 
	
	FieldAppearance = ElementCA.Fields.Items.Add(); 
	FieldAppearance.Field = New DataCompositionField("AssigningAccountTypeAccountType"); 
	FieldAppearance.Use = True; 

	FilterElement = ElementCA.Filter.Items.Add(Type("DataCompositionFilterItem")); // current row filter 
	FilterElement.LeftValue 		= New DataCompositionField("AssigningAccountType.AccountType"); 
	FilterElement.ComparisonType 	= DataCompositionComparisonType.Equal; 
	FilterElement.RightValue 		= Undefined; 
	FilterElement.Use				= True;
		
	ElementCA.Appearance.SetParameterValue("Text", "Create new or map to existing...");
	ElementCA.Appearance.SetParameterValue("TextColor", WebColors.Green);
	ElementCA.Appearance.SetParameterValue("MarkIncomplete", True);

		
	ElementCA = CA.Items.Add();
		
	FieldAppearance = ElementCA.Fields.Items.Add(); 
	FieldAppearance.Field = New DataCompositionField("AssigningAccountTypeAccountType"); 
	FieldAppearance.Use = True; 

	FilterElement = ElementCA.Filter.Items.Add(Type("DataCompositionFilterItem")); // current row filter 
	FilterElement.LeftValue 		= New DataCompositionField("AssigningAccountType.AccountType"); 
	FilterElement.ComparisonType 	= DataCompositionComparisonType.Equal; 
	FilterElement.RightValue 		= 1; 
	FilterElement.Use				= True;
					
	ElementCA.Appearance.SetParameterValue("Text", "Create new G/L account...");
	
	//Display "Up to 90 days" if UploadStartDate is empty
	ElementCA = CA.Items.Add();
		
	FieldAppearance = ElementCA.Fields.Items.Add(); 
	FieldAppearance.Field = New DataCompositionField("AssigningAccountTypeUploadStartDate"); 
	FieldAppearance.Use = True; 

	FilterElement = ElementCA.Filter.Items.Add(Type("DataCompositionFilterItem")); // current row filter 
	FilterElement.LeftValue 		= New DataCompositionField("AssigningAccountType.UploadStartDate"); 
	FilterElement.ComparisonType 	= DataCompositionComparisonType.Equal; 
	FilterElement.RightValue 		= '00010101'; 
	FilterElement.Use				= True;
					
	ElementCA.Appearance.SetParameterValue("Text", "Up to 90 days");
	ElementCA.Appearance.SetParameterValue("TextColor", WebColors.Green);
	
	//Make UploadTransactionDate and Type columns available only for the current column

	ElementCA = CA.Items.Add();
	
	FieldAppearance = ElementCA.Fields.Items.Add(); 
	FieldAppearance.Field = New DataCompositionField("AssigningAccountTypeUploadStartDate"); 
	FieldAppearance.Use = True;
	FieldAppearance = ElementCA.Fields.Items.Add(); 
	FieldAppearance.Field = New DataCompositionField("AssigningAccountTypeContainerType"); 
	FieldAppearance.Use = True;
		
	FilterElement = ElementCA.Filter.Items.Add(Type("DataCompositionFilterItem")); // current row filter 
	FilterElement.LeftValue 		= New DataCompositionField("AssigningAccountType.IsCurrentRow"); 
	FilterElement.ComparisonType 	= DataCompositionComparisonType.Equal; 
	FilterElement.RightValue 		= False; 
	FilterElement.Use				= True;
			
	ElementCA.Appearance.SetParameterValue("Visible", False); 


EndProcedure

&AtServerNoContext
Function GetAvailableListOfAccounts(CurrentAccountType = Undefined, CurrentBankAccount = Undefined)
	Request = New Query("SELECT ALLOWED
	                    |	ChartOfAccounts.Ref,
	                    |	ChartOfAccounts.AccountType,
	                    |	ChartOfAccounts.Code,
	                    |	ChartOfAccounts.Description
	                    |FROM
	                    |	ChartOfAccounts.ChartOfAccounts AS ChartOfAccounts
	                    |		LEFT JOIN Catalog.BankAccounts AS BankAccounts
	                    |		ON (BankAccounts.AccountingAccount = ChartOfAccounts.Ref)
	                    |WHERE
	                    |	(BankAccounts.YodleeAccount = FALSE
	                    |			OR BankAccounts.Ref IS NULL )
	                    |	AND (ChartOfAccounts.AccountType = VALUE(Enum.AccountTypes.Bank)
	                    |			OR ChartOfAccounts.AccountType = VALUE(Enum.AccountTypes.OtherCurrentLiability)
	                    |				AND ChartOfAccounts.CreditCard = TRUE)");
	
	RequestRes = Request.Execute();
	AvailableList = New ValueList();
	If Not RequestRes.IsEmpty() Then
		Sel = RequestRes.Select();
		While Sel.Next() Do
			AvailableList.Add(Sel.Ref, String(Sel.Code) + "-" + TrimAll(Sel.Description));
		EndDo;
	EndIf;
	If (CurrentAccountType <> Undefined) And (CurrentAccountType <> 1) Then
		If AvailableList.FindByValue(CurrentAccountType) = Undefined Then
			AvailableList.Add(CurrentAccountType, String(CurrentAccountType.Code) + "-" + TrimAll(CurrentAccountType.Description));
		EndIf;
	EndIf;
	If (CurrentBankAccount <> Undefined) Then
		BankAA = CurrentBankAccount.AccountingAccount;
		If ValueIsFilled(CurrentBankAccount.AccountingAccount) And (BankAA <> CurrentAccountType) Then
			AvailableList.Add(BankAA, String(BankAA.Code) + "-" + TrimAll(BankAA.Description));	
		EndIf;
	EndIf;
	return AvailableList;
EndFunction

&AtClient
Procedure AssignAccountType(Command)
	If Not CheckDataFill() Then
		return;
	EndIf;
	
	FailReason = AssignAccountTypesAtServer();
	If ValueIsFilled(FailReason) Then // If an error occured
		CommonUseClient.ShowCustomMessageBox(ThisForm, "Assigning G/L accounts", FailReason, PredefinedValue("Enum.MessageStatus.Warning")); 
		FillAvailableAccounts(ThisForm);
	Else
		NotifyChanged(Type("CatalogRef.BankAccounts"));
		
		ReturnArray = New Array();
		If AssigningAccountType.Count() > 0 Then
			For Each AAT In AssigningAccountType Do
				If AAT.Connect Then
					ReturnArray.Add(AAT.AccountType);
				EndIf;
			EndDo;
		EndIf;
		Close(ReturnArray);
	EndIf;
	
EndProcedure

&AtServer
Function AssignAccountTypesAtServer()
	
	Try
		BeginTransaction(DataLockControlMode.Managed);
		FailReason = "";
		TransactionRolledBack = False;
		i = 1;
		For Each Str In AssigningAccountType Do
			If Not ValueIsFilled(Str.BankAccount) Then
				Str.BankAccount = CreateBankAccount(Str);
			EndIf;
			ReturnStructure = AssignAccountTypeAtServer(Str.BankAccount, Str.AccountType, Str.Connect, Str.SetDefault, Str.ContainerType, Str.UploadStartDate);
			If Not ReturnStructure.ReturnValue Then
				CurrentFailReason = "Row #" + String(i) + ". Assigning failed. Reason: " + ReturnStructure.ErrorMessage + " Please, choose an account type once again.";
				FailReason = FailReason + ?(StrLen(FailReason)>0, Chars.CR + Chars.LF, "") + CurrentFailReason;
				Str.AssigningFailed = True;
				CurAccountType = CommonUse.GetAttributeValue(Str.BankAccount, "AccountingAccount");
				If Str.AccountType <> CurAccountType Then
					Str.AccountType = CurAccountType;
				EndIf;
			Else
				Str.AssigningFailed = False;	
				If (Not ValueIsFilled(Str.AccountType)) And (ReturnStructure.Property("NewGLAccount")) Then
					Str.AccountType = ReturnStructure.NewGLAccount;
				EndIf;
				If ReturnStructure.Property("ModifiedBankAccount") Then
					Str.BankAccount = ReturnStructure.ModifiedBankAccount;
				EndIf;
			EndIf;
			i = i + 1;
		EndDo;
		If IsBlankString(FailReason) Then
			If ValueIsFilled(CurrentItemID) Then
				YodleeREST.MarkBankAccountAsConnected(CurrentItemID, 0);
			EndIf;				
			CommitTransaction();
		Else
			If TransactionActive() Then
				RollbackTransaction();
			EndIf;
			TransactionRolledBack = True;
		EndIf;
			
	Except
		ErrorDescription = ErrorDescription();
		FailReason = FailReason + ?(StrLen(FailReason)>0, Chars.CR + Chars.LF, "") + ErrorDescription;
		If TransactionActive() Then
			RollbackTransaction();
		EndIf;
		TransactionRolledBack = True;
	EndTry;
	
	//Blank bank account references if the items are deleted (due to transaction rollback)
	If TransactionRolledBack Then
		For Each Str In AssigningAccountType Do
			If ValueIsFilled(Str.BankAccount) Then
				BankAccountObject = Str.BankAccount.GetObject();
				If BankAccountObject = Undefined Then
					Str.BankAccount = Catalogs.BankAccounts.EmptyRef();
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	
	return FailReason;
	
EndFunction

&AtServer
Function CreateBankAccount(Str)
	
	If ValueIsFilled(Str.BankAccount) Then
		return Str.BankAccount;
	EndIf;
	BankAccountObject = Catalogs.BankAccounts.CreateItem();
	BankAccountObject.Owner = Bank;
	BankAccountObject.Description = Str.BankAccountDescription;
	BankAccountObject.AccountType = Str.Type;
	BankAccountObject.YodleeAccount = True;
	FillPropertyValues(BankAccountObject, Str, "ItemID, ItemAccountID, LastUpdatedTimeUTC, LastUpdateAttemptTimeUTC, NextUpdateTimeUTC, CurrentBalance, AvailableBalance, RefreshStatusCode, CreditCard_TotalCreditline, CreditCard_AmountDue, CreditCard_Type");
	BankAccountObject.Write();
	return BankAccountObject.Ref;
	
EndFunction

&AtClient
Procedure CloseForm(Command)
	
	ReturnArray = New Array();
	If (AssigningAccountType.Count() > 0) Then
		For Each AAT In AssigningAccountType Do
			If AAT.Connect And ValueIsFilled(AAT.AccountType) Then
				ReturnArray.Add(AAT.AccountType);
			EndIf;
		EndDo;
	EndIf;
	Close(ReturnArray);
		
EndProcedure

&AtClient
Function CheckDataFill()
	Result = True;
	i = 0;
	While i < AssigningAccountType.Count() Do
		CurAccount = AssigningAccountType[i];
		If Not CurAccount.Connect Then
			i = i + 1;
			Continue;
		EndIf;
		If CurAccount.AccountType = PredefinedValue("ChartOfAccounts.ChartOfAccounts.EmptyRef") 
			Or CurAccount.AccountType = Undefined Then
			Result = False;
			MessOnError = New UserMessage();
			MessOnError.Field = "AssigningAccountType[" + String(i) + "]." + "AccountType";
			MessOnError.Text  = "Please, choose whether to create a new G/L account or map to an existing one";
			MessOnError.Message();
		EndIf;
		If Not ValueIsFilled(CurAccount.ContainerType) Then
			Result = False;
			MessOnError = New UserMessage();
			MessOnError.Field = "AssigningAccountType[" + String(i) + "]." + "ContainerType";
			MessOnError.Text  = "Please, choose bank account type (bank or credit card)";
			MessOnError.Message();
		EndIf; 
		i = i + 1;
	EndDo;
	Return Result;
EndFunction

&AtServerNoContext
Function AssignAccountTypeAtServer(Val CurrentBankAccount, Val BankAccountType, Val Connect = True, Val SetAsDefault = False, Val ContainerType, Val UploadStartDate)
	
	ReturnStructure = New Structure("ReturnValue, ErrorMessage", True, "");
	If (CurrentBankAccount.AccountingAccount = BankAccountType) And (ValueIsFilled(CurrentBankAccount.AccountingAccount)) Then
		ReturnStructure.ReturnValue = True;
		return ReturnStructure;
	EndIf;
	BeginTransaction(DataLockControlMode.Managed);
	
	//Set DataLock on ChartOfAccounts
	GLLock = New DataLock();
	LockItem = GLLock.Add("ChartOfAccounts.ChartOfAccounts");
	LockItem.Mode = DataLockMode.Exclusive;
	GLLock.Lock();
	
	Try
		If Connect Then
			BAObject = CurrentBankAccount.GetObject();
			//Create appropriate G/L account 
			If (Not ValueIsFilled(BankAccountType)) Or (BankAccountType = 1) Then
				NewGLAccount = ChartsOfAccounts.ChartOfAccounts.CreateAccount();
				NewGLAccount.Description = CurrentBankAccount.Description;
				If ContainerType = Enums.YodleeContainerTypes.Bank Then
					NewGLAccount.AccountType = Enums.AccountTypes.Bank;
					NewGLAccount.Currency = GeneralFunctionsReusable.DefaultCurrency();
					StartCode = "1000";
					EndCode = "2000";
					NewCode = GeneralFunctions.FindVacantCode(StartCode, EndCode, Enums.AccountTypes.Bank);
				Else
					NewGLAccount.AccountType 	= Enums.AccountTypes.OtherCurrentLiability;
					NewGLAccount.CreditCard		= True;
					StartCode = "2100";
					EndCode = "3000";
					NewCode = GeneralFunctions.FindVacantCode(StartCode, EndCode, Enums.AccountTypes.OtherCurrentLiability);
				EndIf;
				If Not ValueIsFilled(NewCode) Then
					UM = GetUserMessages(True);
					If UM.Count()>0 Then
						ReturnStructure.ErrorMessage = UM[0].Text;
					Else
						ReturnStructure.ErrorMessage = "Couldn't create the new G/L account """ + CurrentBankAccount.Description + """"
						+ " for no vacant code found between " + StartCode + " and " + EndCode;
					EndIf;
					ReturnStructure.ReturnValue = False;
					return ReturnStructure;
				EndIf;
				NewGLAccount.Code = NewCode;
				NewGLAccount.Order = NewCode;
				NewGLAccount.AdditionalProperties.Insert("DoNotCreateBankAccount", True);
				NewGLAccount.Write();
				BAObject.AccountingAccount = NewGLAccount.Ref;
				ReturnStructure.Insert("NewGLAccount", NewGLAccount.Ref);
			Else
				//Check if BankAccountType is already linked to an offline account
				Request = New Query("SELECT ALLOWED
				                    |	ChartOfAccounts.Ref,
				                    |	BankAccounts.ItemID,
				                    |	BankAccounts.ItemAccountID,
				                    |	BankAccounts.Ref AS BankAccountRef
				                    |FROM
				                    |	ChartOfAccounts.ChartOfAccounts AS ChartOfAccounts
				                    |		LEFT JOIN Catalog.BankAccounts AS BankAccounts
				                    |		ON (BankAccounts.AccountingAccount = ChartOfAccounts.Ref)
				                    |WHERE
				                    |	ChartOfAccounts.Ref = &Ref");
				Request.SetParameter("Ref", BankAccountType); 
				ATDetails = Request.Execute().Unload();
				If Not ValueIsFilled(ATDetails[0].BankAccountRef) Then
					BAObject.AccountingAccount = BankAccountType;
				Else
					//When assigning to an offline account then set the UploadStartDate to the tomorrow date
					UsedBAObject = ATDetails[0].BankAccountRef.GetObject();
					FillPropertyValues(UsedBAObject, BAObject, "Owner, Description, ItemID, ItemAccountID, AccountType, CurrentBalance, AvailableBalance, LastUpdatedTimeUTC, 
					|LastUpdateAttemptTimeUTC, NextUpdateTimeUTC, RefreshStatusCode, YodleeAccount, TransactionsRefreshTimeUTC, CreditCard_AmountDue, CreditCard_TotalCreditline, CreditCard_Type");
					UsedBAObject.UploadStartDate = UploadStartDate;
					UsedBAObject.Write();
					//Transfer bank transactions and delete BAObject
					BTRecordSet = InformationRegisters.BankTransactions.CreateRecordSet();
					BAFilter	= BTRecordSet.Filter.BankAccount;
					BAFilter.Use = True;
					BAFilter.ComparisonType = ComparisonType.Equal;
					BAFilter.Value 	= BAObject.Ref;
					BTRecordSet.Write();
					BAObject.Delete();
					//To use it in the latter algorithm
					BAObject = UsedBAObject;
					ReturnStructure.Insert("ModifiedBankAccount", UsedBAObject.Ref);
				EndIf;
			EndIf;
			GetUserMessages(True);
		Else
			BAObject = CurrentBankAccount.GetObject();
			GetUserMessages(True);
		EndIf;

		If Connect Then
			BAObject.Write();
		Else
			//Reflect this in Register
			YodleeREST.MarkBankAccountAsDisconnected(CurrentBankAccount.ItemID, CurrentBankAccount.ItemAccountID);
			BAObject.Delete();
		EndIf;
		If SetAsDefault Then
			Constants.BankAccount.Set(BankAccountType);
		EndIf;
		CommitTransaction();
	Except
		ErrorDesc = ErrorDescription();
		If TransactionActive() Then
			RollbackTransaction();
		EndIf;
		UM = GetUserMessages(True);
		If UM.Count()>0 Then
			ReturnStructure.ErrorMessage = UM[0].Text;
		Else
			ReturnStructure.ErrorMessage = ErrorDesc;
		EndIf;
		ReturnStructure.ReturnValue = False;	
	EndTry;
	return ReturnStructure;
	
EndFunction

&AtClient
Procedure BankAccountTypeCreating(Item, StandardProcessing)
	StandardProcessing = False;
	Notify = New NotifyDescription("RefreshAvailableAccounts", ThisObject, New Structure("CurrentRow", Items.AssigningAccountType.CurrentRow));
	OpenForm("ChartOfAccounts.ChartOfAccounts.ObjectForm", New Structure(), ThisForm,,,,Notify,FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

&AtClient
Procedure RefreshAvailableAccounts(NewAccount, Parameters) Export
	FillAvailableAccounts(ThisForm);
	ChoicesCount = Items.AssigningAccountTypeAccountType.ChoiceList.Count();
	If Parameters.Property("CurrentRow") And (ChoicesCount = 1) Then
		Items.AssigningAccountType.CurrentRow = Parameters.CurrentRow;
		Items.AssigningAccountType.CurrentData.AccountType = Items.AssigningAccountTypeAccountType.ChoiceList[0].Value;
	EndIf;
EndProcedure

&AtClient
Procedure ServiceURLClick(Item)
	
	StandardProcessing = false;
	If ValueIsFilled(Item.Title) Then
		GotoUrl(Item.Title);
	EndIf;
	
EndProcedure

&AtServer
Procedure MarkBankAccountAsDisconnected(ItemID, ItemAccountID)
	
	YodleeREST.MarkBankAccountAsDisconnected(ItemID, ItemAccountID);
	
EndProcedure

&AtClient
Procedure AssigningAccountTypeOnActivateRow(Item)
	
	If Item.CurrentData = Undefined Then
		return;
	EndIf;
	
	AttachIdleHandler("ProcessAssigningAccountTypeOnActivateRow", 0.1, True);
		
EndProcedure

&AtClient
Procedure ProcessAssigningAccountTypeOnActivateRow()
	
	// Set the current row attribute
	If Items.AssigningAccountType.CurrentData = Undefined Then
		return;
	EndIf;
	
	Try
		PreviousRow = AssigningAccountType.FindByID(CurrentRowID);
		PreviousRow.IsCurrentRow = False;
	Except
	EndTry;
	
	Items.AssigningAccountType.CurrentData.IsCurrentRow = True;
	CurrentRowID = Items.AssigningAccountType.CurrentData.GetID();
	
	FillAvailableAccounts(ThisForm);

EndProcedure

&AtClient
Procedure AssigningAccountTypeAccountTypeOnChange(Item)
	
	CurrentDataStructure = New Structure("AccountType, UploadStartDate");
	FillPropertyValues(CurrentDataStructure, Items.AssigningAccountType.CurrentData);
	FillUploadStartDate(CurrentDataStructure);
	Items.AssigningAccountType.CurrentData.UploadStartDate = CurrentDataStructure.UploadStartDate;
	
EndProcedure

&AtServer 
Procedure FillUploadStartDate(CurrentData)
	
	//Check if BankAccountType is already linked to an offline account
	Request = New Query("SELECT ALLOWED TOP 1
	                    |	BankTransactions.TransactionDate AS TransactionDate
	                    |FROM
	                    |	ChartOfAccounts.ChartOfAccounts AS ChartOfAccounts
	                    |		LEFT JOIN Catalog.BankAccounts AS BankAccounts
	                    |			LEFT JOIN InformationRegister.BankTransactions AS BankTransactions
	                    |			ON BankAccounts.Ref = BankTransactions.BankAccount
	                    |		ON (BankAccounts.AccountingAccount = ChartOfAccounts.Ref)
	                    |WHERE
	                    |	ChartOfAccounts.Ref = &Ref
	                    |
	                    |ORDER BY
	                    |	TransactionDate DESC");
	Request.SetParameter("Ref", CurrentData.AccountType); 
	TabRes = Request.Execute().Unload();
	If TabRes.Count() > 0 Then
		If ValueIsFilled(TabRes[0].TransactionDate) Then
			CurrentData.UploadStartDate = TabRes[0].TransactionDate + 24 * 3600;
		Else
			CurrentData.UploadStartDate = '00010101';
		EndIf;
	Else
		CurrentData.UploadStartDate = '00010101';
	EndIf;
	
EndProcedure

&AtClient
Procedure AssigningAccountTypeUploadStartDateOnChange(Item)
	
	CurrentDataStructure = New Structure("AccountType, UploadStartDate");
	FillPropertyValues(CurrentDataStructure, Items.AssigningAccountType.CurrentData);
	FillUploadStartDate(CurrentDataStructure);
	If Items.AssigningAccountType.CurrentData.UploadStartDate < CurrentDataStructure.UploadStartDate Then
		Items.AssigningAccountType.CurrentData.UploadStartDate = CurrentDataStructure.UploadStartDate;
		MessOnError = New UserMessage();
		MessOnError.Field = "AssigningAccountType[" + Items.AssigningAccountType.CurrentRow + "]." + "UploadStartDate";
		MessOnError.Text  = "Upload start date cannot be earlier than the last transaction date (" + Format(CurrentDataStructure.UploadStartDate - 24*3600, "DLF=D") 
		+ ") of the assigned offline account (" + Items.AssigningAccountType.CurrentData.AccountType + ").";
		MessOnError.Message();
	EndIf;
	
EndProcedure

&AtServer
Procedure CancelAccountAdditionAtServer()
	
	UserCancelledAccountAddition = True;
	ShowStartPage(ThisForm);
	If ValueIsFilled(CurrentItemID) Then
		YodleeREST.StopRefresh_REST(CurrentItemID);
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure ShowAdditionProgress(Form)
	
	Items = Form.Items;
	Items.BankDetails.Visible = False;
	Items.ProgressGroup.Visible = True;
	Items.AddAccounts.Visible = False;
	Items.CancelAccountAddition.Visible = True;

EndProcedure

&AtClientAtServerNoContext
Procedure ShowStartPage(Form)
	
	Items = Form.Items;
	Items.BankDetails.Visible = True;
	Items.ProgressGroup.Visible = False;
	Items.AddAccounts.Visible = True;
	Items.CancelAccountAddition.Visible = False;
	
EndProcedure

&AtClient
Procedure CancelAccountAddition(Command)
	CancelAccountAdditionAtServer();
EndProcedure

&AtClient
Procedure AssigningAccountTypeBeforeAddRow(Item, Cancel, Clone, Parent, Folder, Parameter)
	
	Cancel = True;
	
EndProcedure
