
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
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	LastUpdatedTime = ?(ValueIsFilled(Object.LastUpdatedTimeUTC), ToLocalTime(Object.LastUpdatedTimeUTC), Object.LastUpdatedTimeUTC);
	TransactionsRefreshedTime = ?(ValueIsFilled(Object.TransactionsRefreshTimeUTC), ToLocalTime(Object.TransactionsRefreshTimeUTC), Object.TransactionsRefreshTimeUTC);
	LastUpdateAttemptTime = ?(ValueIsFilled(Object.LastUpdateAttemptTimeUTC), ToLocalTime(Object.LastUpdateAttemptTimeUTC), Object.LastUpdateAttemptTimeUTC);
	NextUpdateTime = ?(ValueIsFilled(Object.NextUpdateTimeUTC), ToLocalTime(Object.NextUpdateTimeUTC), Object.NextUpdateTimeUTC);

EndProcedure