
&AtClient
Procedure MultiLocationOnChange(Item)
	Message("Restart the program for the setting to take effect");
	RefreshInterface();
EndProcedure

&AtClient
Procedure MultiCurrencyOnChange(Item)
	Message("Restart the program for the setting to take effect");
	RefreshInterface();
EndProcedure

&AtClient
Procedure USFinLocalizationOnChange(Item)
	Message("Restart the program for the setting to take effect");
	RefreshInterface();
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	BinaryLogo = GeneralFunctions.GetLogo();
	TempStorageAddress = PutToTempStorage(BinaryLogo);
	ImageAddress = TempStorageAddress;
	
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
		
	If NOT Constants.APISecretKey.Get() = "" Then
		Items.APISecretKey.ReadOnly = True;		
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
	Message("Restart the program for the setting to take effect");
EndProcedure

&AtClient
Procedure VATFinLocalizationOnChange(Item)
	
	//GeneralFunctions.VATSetup();
	Message("Restart the program for the setting to take effect");
	RefreshInterface();

EndProcedure

&AtClient
Procedure VendorNameOnChange(Item)
	
	Message("Restart the program for the setting to take effect");
	
EndProcedure

&AtClient
Procedure CustomerNameOnChange(Item)
	
	Message("Restart the program for the setting to take effect");
	
EndProcedure

&AtClient
Procedure PriceIncludesVATOnChange(Item)
	
	Message("Restart the program for the setting to take effect");
	RefreshInterface();

EndProcedure

&AtClient
Procedure ProjectsOnChange(Item)
	
	Message("Restart the program for the setting to take effect");
	//RefreshInterface();

EndProcedure

&AtClient
Procedure UploadLogo(Command)
	
	Var SelectedName;
	ImageAddress = "";
	
	NotifyDescription = New NotifyDescription("FileUpload",ThisForm);
	BeginPutFile(NotifyDescription,ImageAddress,"",True);
	
	BinaryLogo = GeneralFunctions.GetLogo();
	TempStorageAddress = PutToTempStorage(BinaryLogo);
	ImageAddress = TempStorageAddress;

EndProcedure

&AtClient
Procedure FileUpload(a,b,c,d) Export
	
	PlaceImageFile(b);
	
EndProcedure

&AtServer
Procedure PlaceImageFile(TempStorageName)
	
	BinaryData = GetFromTempStorage(TempStorageName);	
	NewRow = InformationRegisters.CustomPrintForms.CreateRecordManager();
	NewRow.ObjectName = "logo";
	NewRow.TemplateName = "logo";
	NewRow.Template = New ValueStorage(BinaryData, New Deflation(9));
	NewRow.Write();	
	DeleteFromTempStorage(TempStorageName);
  	
EndProcedure

 
&AtServer
Function GetAPISecretKeyF()
	
	Return Constants.APISecretKey.Get();
	
EndFunction


&AtClient
Procedure OnOpen(Cancel)
	
	If NOT NoUser() Then
		
	 If SettingAccessCheck() = false Then

		Items.Common.ChildItems.CompanyContact.ReadOnly = true;
		Items.Common.ChildItems.GeneralSettings.ReadOnly = true;
		Items.Common.ChildItems.CompanyContact.ReadOnly = true;
		Items.Common.ChildItems.FinancialLocalization.ReadOnly = true;
		Items.Common.ChildItems.VAT.ReadOnly = true;
		Items.Common.ChildItems.ItemCustomFields.ReadOnly = true;
		Items.Common.ChildItems.Logo.ReadOnly = true;
		Items.Common.ChildItems.Preview.ReadOnly = true;
	 Else
	
		Items.Common.ChildItems.CompanyContact.ReadOnly = false;
		Items.Common.ChildItems.GeneralSettings.ReadOnly = false;
		Items.Common.ChildItems.CompanyContact.ReadOnly = false;
		Items.Common.ChildItems.FinancialLocalization.ReadOnly = false;
		Items.Common.ChildItems.VAT.ReadOnly = false;
		Items.Common.ChildItems.ItemCustomFields.ReadOnly = false;
		Items.Common.ChildItems.Logo.ReadOnly = false;
		Items.Common.ChildItems.Preview.ReadOnly = false;
	
		Endif;

	EndIf;
	
EndProcedure

&AtServer
Function NoUser()
	
	CurUser = InfoBaseUsers.FindByName(SessionParameters.ACSUser);
	If CurUser.Name = "" Then
		Return True;
	Else
		Return False;
	EndIf;
	
	
EndFunction

&AtServer
Function SettingAccessCheck()
	
	CurUser = InfoBaseUsers.FindByName(SessionParameters.ACSUser);
	If CurUser.Roles.Contains(Metadata.Roles.FullAccess1) = true Or CurUser.Roles.Contains(Metadata.Roles.FullAccess) = true Then
		Return true;
	Else
		Return false;
	Endif
	
EndFunction

