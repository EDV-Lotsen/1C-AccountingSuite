
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
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

&AtClient
Procedure StatusCodeDescriptionDecorationClick(Item)
	OpenForm("DataProcessor.DownloadedTransactions.Form.DetailedErrorMessage", New Structure("StatusCode", String(Object.RefreshStatusCode)), ThisForm,,,,,FormWindowOpeningMode.LockOwnerWindow);
EndProcedure
