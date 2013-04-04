
&AtClient
Procedure MultiLocationOnChange(Item)
	DoMessageBox("Restart the program for the setting to take effect");
	RefreshInterface();
EndProcedure

&AtClient
Procedure MultiCurrencyOnChange(Item)
	DoMessageBox("Restart the program for the setting to take effect");
	RefreshInterface();
EndProcedure

&AtClient
Procedure USFinLocalizationOnChange(Item)
	DoMessageBox("Restart the program for the setting to take effect");
	RefreshInterface();
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
		
	Items.BankAccountLabel.Title =
		CommonUse.GetAttributeValue(Constants.BankAccount.Get(), "Description");
	Items.IncomeAccountLabel.Title =
		CommonUse.GetAttributeValue(Constants.IncomeAccount.Get(), "Description");
	Items.COGSAccountLabel.Title =
		CommonUse.GetAttributeValue(Constants.COGSAccount.Get(), "Description");
	Items.ExpenseAccountLabel.Title =
		CommonUse.GetAttributeValue(Constants.ExpenseAccount.Get(), "Description");
	Items.InventoryAccountLabel.Title =
		CommonUse.GetAttributeValue(Constants.InventoryAccount.Get(), "Description");
	Items.ExchangeGainLabel.Title =
		CommonUse.GetAttributeValue(Constants.ExchangeGain.Get(), "Description");
	Items.ExchangeLossLabel.Title =
		CommonUse.GetAttributeValue(Constants.ExchangeLoss.Get(), "Description");
	Items.TaxPayableAccountLabel.Title =
		CommonUse.GetAttributeValue(Constants.TaxPayableAccount.Get(), "Description");
	Items.UndepositedFundsAccountLabel.Title =
		CommonUse.GetAttributeValue(Constants.UndepositedFundsAccount.Get(), "Description");
	Items.BankInterestEarnedAccountLabel.Title =
		CommonUse.GetAttributeValue(Constants.BankInterestEarnedAccount.Get(), "Description");
	Items.BankServiceChargeAccountLabel.Title =
		CommonUse.GetAttributeValue(Constants.BankServiceChargeAccount.Get(), "Description");
				
	If NOT Items.APIPublicKey.Title = "" AND NOT IsInRole("FullRights") Then
		Items.APIPublicKey.ReadOnly = True;		
	EndIf;

		
EndProcedure

&AtClient
Procedure BankAccountOnChange(Item)
	Items.BankAccountLabel.Title = GeneralFunctions.AccountName(Items.BankAccount.SelectedText);
EndProcedure

&AtClient
Procedure IncomeAccountOnChange(Item)
	Items.IncomeAccountLabel.Title = GeneralFunctions.AccountName(Items.IncomeAccount.SelectedText);
EndProcedure

&AtClient
Procedure COGSAccountOnChange(Item)
	Items.COGSAccountLabel.Title = GeneralFunctions.AccountName(Items.COGSAccount.SelectedText);
EndProcedure

&AtClient
Procedure ExpenseAccountOnChange(Item)
	Items.ExpenseAccountLabel.Title = GeneralFunctions.AccountName(Items.ExpenseAccount.SelectedText);
EndProcedure

&AtClient
Procedure InventoryAccountOnChange(Item)
	Items.InventoryAccountLabel.Title =
		GeneralFunctions.AccountName(Items.InventoryAccount.SelectedText);
EndProcedure

&AtClient
Procedure ExchangeGainOnChange(Item)
	Items.ExchangeGainLabel.Title = GeneralFunctions.AccountName(Items.ExchangeGain.SelectedText);
EndProcedure

&AtClient
Procedure ExchangeLossOnChange(Item)
	Items.ExchangeLossLabel.Title = GeneralFunctions.AccountName(Items.ExchangeLoss.SelectedText);
EndProcedure

&AtClient
Procedure TaxPayableAccountOnChange(Item)
	Items.TaxPayableAccountLabel.Title =
		GeneralFunctions.AccountName(Items.TaxPayableAccount.SelectedText);
EndProcedure

&AtClient
Procedure UndepositedFundsAccountOnChange(Item)
	Items.UndepositedFundsAccountLabel.Title =
		GeneralFunctions.AccountName(Items.UndepositedFundsAccount.SelectedText);
EndProcedure

&AtClient
Procedure BankInterestEarnedAccountOnChange(Item)
	Items.BankInterestEarnedAccountLabel.Title =
		GeneralFunctions.AccountName(Items.BankInterestEarnedAccount.SelectedText);
EndProcedure

&AtClient
Procedure BankServiceChargeAccountOnChange(Item)
	Items.BankServiceChargeAccountLabel.Title =
		GeneralFunctions.AccountName(Items.BankServiceChargeAccount.SelectedText);
EndProcedure

&AtClient
Procedure DefaultCurrencyOnChange(Item)
	DoMessageBox("Restart the program for the setting to take effect");
EndProcedure

&AtClient
Procedure VATFinLocalizationOnChange(Item)
	
	//GeneralFunctions.VATSetup();
	DoMessageBox("Restart the program for the setting to take effect");
	RefreshInterface();

EndProcedure

&AtClient
Procedure VendorNameOnChange(Item)
	
	DoMessageBox("Restart the program for the setting to take effect");
	
EndProcedure

&AtClient
Procedure CustomerNameOnChange(Item)
	
	DoMessageBox("Restart the program for the setting to take effect");
	
EndProcedure

&AtClient
Procedure EmailClientOnChange(Item)
	
	DoMessageBox("Restart the program for the setting to take effect");
	RefreshInterface();

EndProcedure

&AtClient
Procedure PriceIncludesVATOnChange(Item)
	
	DoMessageBox("Restart the program for the setting to take effect");
	RefreshInterface();

EndProcedure
