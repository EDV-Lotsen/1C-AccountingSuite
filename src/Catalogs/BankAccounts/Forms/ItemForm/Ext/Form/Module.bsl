
#Region EVENTS_HANDLERS

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Constants.DisplayExtendedAccountInfo.Get() = True Then
		Items.PagesGroup.Visible = True;
		Items.FormMergeTransactions.Visible = True;
	Else
		Items.PagesGroup.Visible = False;
		Items.FormMergeTransactions.Visible = False;
	EndIf;
	
	DefaultCurrencySymbol    				= GeneralFunctionsReusable.DefaultCurrencySymbol();
	Items.CurrentBalanceCurrency.Title 		= DefaultCurrencySymbol;
	Items.AvailableBalanceCurrency.Title 	= DefaultCurrencySymbol;
	Items.RunningBalanceCurrency.Title		= DefaultCurrencySymbol;
	Items.AvailableCreditCurrency.Title		= DefaultCurrencySymbol;
	Items.TotalCreditLineCurrency.Title		= DefaultCurrencySymbol;
	Items.AmountDueCurrency.Title			= DefaultCurrencySymbol;
	
	If ValueIsFilled(Object.ItemID) Then //If online account
		
		Items.Online.Visible = True;
		
		If Object.RefreshStatusCode <> 0 Then
			Items.StatusCodeDescriptionDecoration.Visible = True;
		Else
			Items.StatusCodeDescriptionDecoration.Visible = False;
		EndIf;
		
	Else //If offline account
		
		Items.Online.Visible = False;
			
	EndIf;
	
	If Object.Owner.ContainerType = Enums.YodleeContainerTypes.Credit_Card Then
		Items.BankAccountGroup.Visible = False;
		Items.CreditCardAccountGroup.Visible = True;
		Items.BalanceGroup.Visible = False;
		Items.CreditCardBalanceGroup.Visible = True;
	Else
		Items.BankAccountGroup.Visible = True;
		Items.CreditCardAccountGroup.Visible = False;
		Items.BalanceGroup.Visible = True;
		Items.CreditCardBalanceGroup.Visible = False;
	EndIf;
	
	ATArray = New Array();
	ATArray.Add(Enums.AccountTypes.Bank);
	ATArray.Add(Enums.AccountTypes.OtherCurrentAsset);
	ATArray.Add(Enums.AccountTypes.OtherCurrentLiability);
	NewParameter = New ChoiceParameter("Filter.AccountType", ATArray);
	NewArray = New Array();
	NewArray.Add(NewParameter);
	NewParameters = New FixedArray(NewArray);
	Items.AccountingAccount.ChoiceParameters = NewParameters;	
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	LastUpdatedTime = ?(ValueIsFilled(Object.LastUpdatedTimeUTC), ToLocalTime(Object.LastUpdatedTimeUTC), Object.LastUpdatedTimeUTC);
	TransactionsRefreshedTime = ?(ValueIsFilled(Object.TransactionsRefreshTimeUTC), ToLocalTime(Object.TransactionsRefreshTimeUTC), Object.TransactionsRefreshTimeUTC);
	LastUpdateAttemptTime = ?(ValueIsFilled(Object.LastUpdateAttemptTimeUTC), ToLocalTime(Object.LastUpdateAttemptTimeUTC), Object.LastUpdateAttemptTimeUTC);
	NextUpdateTime = ?(ValueIsFilled(Object.NextUpdateTimeUTC), ToLocalTime(Object.NextUpdateTimeUTC), Object.NextUpdateTimeUTC);

EndProcedure

#ENDREGION

#REGION FORM_COMMAND_HANDLERS

&AtClient
Procedure EditSignInInfo(Command)
	If Not Object.YodleeAccount Then
		return;		
	EndIf;
	
	Notify = New NotifyDescription("OnComplete_RefreshTransactions", ThisObject);
	Params = New Structure("PerformEditAccount, RefreshAccount", True, Object.Ref);
	OpenForm("DataProcessor.YodleeBankAccountsManagement.Form.Form", Params, ThisForm,,,, Notify, FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

&AtClient
Procedure DeleteAccount(Command)
	//Ask a user
	Mode = QuestionDialogMode.YesNoCancel;
	Notify = New NotifyDescription("DeleteAccountAfterQuery", ThisObject);
	ShowQueryBox(Notify, "Bank account " + String(Object.Ref) + " will be deleted. Are you sure?", Mode, 0, DialogReturnCode.Cancel, "Cloud banking"); 
EndProcedure

&AtClient
Procedure StatusCodeDescriptionDecorationClick(Item)
	OpenForm("DataProcessor.DownloadedTransactions.Form.DetailedErrorMessage", New Structure("StatusCode", String(Object.RefreshStatusCode)), ThisForm,,,,,FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

#ENDREGION

#REGION OTHER_FUNCTIONS

&AtClient
Procedure OnComplete_RefreshTransactions(ClosureResult, AdditionalParameters) Export
	Read();
EndProcedure

&AtServerNoContext
Function RemoveAccountAtServer(Item)
	If Not Constants.ServiceDB.Get() Then
		return New Structure("returnValue, Status", False, "Bank accounts removal is available only in the Service DB");
	EndIf;
	return Yodlee.RemoveYodleeBankAccountAtServer(Item);
EndFunction

&AtClient
Procedure DeleteAccountAfterQuery(Result, Parameters) Export
	
	If Result <> DialogReturnCode.Yes Then
		return;
	EndIf;
	
	//Disconnect from the Provider (Yodlee)
	//Then mark for deletion
	ReturnStruct = RemoveAccountAtServer(Object.Ref);
	If ReturnStruct.returnValue Then
		Notify("DeletedBankAccount", Object.Ref);
		NotifyChanged(Object.Ref);
		Close();
		ShowMessageBox(, ReturnStruct.Status,,"Removing bank account");
	Else
		If Find(ReturnStruct.Status, "InvalidItemExceptionFaultMessage") Then
			ShowMessageBox(, "Account not found.",,"Removing bank account");
		Else
			ShowMessageBox(, ReturnStruct.Status,,"Removing bank account");
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure MergeTransactions(Command)
	OpenForm("Catalog.BankAccounts.Form.MergeTransactionsForm",New Structure("BankAccount", Object.Ref), ThisForm,,,,,FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

#ENDREGION