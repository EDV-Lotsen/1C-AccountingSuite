
&AtClient
Procedure MultiLocationOnChange(Item)
	Message("After enabling the multi-location feature can not be disabled.");
	//RefreshInterface();
EndProcedure

&AtClient
Procedure MultiCurrencyOnChange(Item)
	Message("After enabling the multi-currency feature can not be disabled.");
	//RefreshInterface();
EndProcedure

&AtClient
Procedure USFinLocalizationOnChange(Item)
	//Message("Restart the program for the setting to take effect");
	//RefreshInterface();
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	BinaryLogo = GeneralFunctions.GetLogo();
	TempStorageAddress = PutToTempStorage(BinaryLogo,UUID);
	ImageAddress = TempStorageAddress;
	Items.image.PictureSize = PictureSize.AutoSize;
	
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
	
	If Constants.USFinLocalization.Get() = True Then
		Items.USFinLocalization.ReadOnly = True;
		Items.VATFinLocalization.ReadOnly = True;
	EndIf;
	
	If Constants.MultiCurrency.Get() = True Then
		Items.MultiCurrency.ReadOnly = True;
	EndIf;
	
	If Constants.MultiLocation.Get() = True Then
		Items.MultiLocation.ReadOnly = True;
	EndIf;
	
	Items.DefaultCurrency.ReadOnly = True;
			
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
	//Message("Restart the program for the setting to take effect");
	//RefreshInterface();

EndProcedure

&AtClient
Procedure VendorNameOnChange(Item)
	
	//Message("Restart the program for the setting to take effect");
	//RefreshInterface();
	
EndProcedure

&AtClient
Procedure CustomerNameOnChange(Item)
	
	//Message("Restart the program for the setting to take effect");
	//RefreshInterface();
	
EndProcedure

&AtClient
Procedure PriceIncludesVATOnChange(Item)
	
	//Message("Restart the program for the setting to take effect");
	//RefreshInterface();

EndProcedure

&AtClient
Procedure UploadLogo(Command)
	
	Var SelectedName;
	ImageAddress = "";
	
	NotifyDescription = New NotifyDescription("FileUpload",ThisForm);
	BeginPutFile(NotifyDescription,,"",True);
	
	//BinaryLogo = GeneralFunctions.GetLogo();
	//TempStorageAddress = PutToTempStorage(BinaryLogo,UUID);
	//ImageAddress = TempStorageAddress;
	
EndProcedure

&AtClient
Procedure FileUpload(a,b,c,d) Export
	
	PlaceImageFile(b);
	
EndProcedure

&AtServer
Procedure PlaceImageFile(TempStorageName)
	
	If NOT TempStorageName = Undefined Then
	
		BinaryData = GetFromTempStorage(TempStorageName);
				
	    ///
		
		NewRow = InformationRegisters.CustomPrintForms.CreateRecordManager();
		NewRow.ObjectName = "logo";
		NewRow.TemplateName = "logo";
		NewRow.Template = New ValueStorage(BinaryData, New Deflation(9));
		NewRow.Write();	
		DeleteFromTempStorage(TempStorageName);
		
	EndIf;
	
	BinaryLogo = GeneralFunctions.GetLogo();
	TempStorageAddress = PutToTempStorage(BinaryLogo,UUID);
	ImageAddress = TempStorageAddress;
  	
EndProcedure

 
&AtClient
Procedure StripeConnect(Command)
	
	statestring = GetAPISecretKeyF();
	GotoURL("https://addcard.accountingsuite.com/connect?state=" + statestring);

EndProcedure

&AtServer
Function GetAPISecretKeyF()
	
	Return Constants.APISecretKey.Get();
	
EndFunction


&AtClient
Procedure OnOpen(Cancel)
 
	 If SettingAccessCheck() = false Then

	    Items.Common.ChildItems.Logo.ChildItems.UploadLogo.Enabled = false;

	 Else
		Items.Common.ChildItems.Logo.ChildItems.UploadLogo.Enabled = true;

	 Endif;
	
EndProcedure

&AtServer
Function SettingAccessCheck()
	CurUser = InfoBaseUsers.FindByName(SessionParameters.ACSUser);
	If CurUser.Roles.Contains(Metadata.Roles.FullAccess1) = true Or CurUser.Roles.Contains(Metadata.Roles.FullAccess) = true Then
		Return true;
	Else
		Return false;
	Endif
EndFunction


//&AtClient
//Procedure VerifyEmail(Command)
//	VerifyEmailAtServer();
//EndProcedure


//&AtServer
//Procedure VerifyEmailAtServer()
//		HeadersMap = New Map();
//	
//		HTTPRequest = New HTTPRequest("/ses_email_verify",HeadersMap);
//		HTTPRequest.SetBodyFromString(Constants.Email.Get(),TextEncoding.ANSI);

//	
//		SSLConnection = New OpenSSLSecureConnection();
//	
//		HTTPConnection = New HTTPConnection("intacs.accountingsuite.com",,,,,,SSLConnection);
//		Result = HTTPConnection.Post(HTTPRequest);
//		
//		Message("You will receive a verification email to " + Constants.Email.Get());

//EndProcedure


&AtClient
Procedure DwollaConnect(Command)
	
	statestring = GetAPISecretKeyF();	
	GoToURL("https://www.dwolla.com/oauth/v2/authenticate?client_id=CCUdqUc4nB2AtraAvbsrzLWPS1pKUmfFS0NnFqmRE4OhlYJhVF&response_type=code&redirect_uri=https://pay.accountingsuite.com/dwolla_oauth?state=" + GetTenantValue() + "&scope=send%7Ctransactions%7Cfunding%7Cbalance");
	
EndProcedure

&AtServer
Function GetTenantValue()
	
	Return SessionParameters.TenantValue;
	
EndFunction


&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	If Constants.MultiCurrency.Get() = True Then
		Items.MultiCurrency.ReadOnly = True;
	EndIf;
	
	If Constants.MultiLocation.Get() = True Then
		Items.MultiLocation.ReadOnly = True;
	EndIf;
	
	Constants.Email.Set(Constants.CurrentUserEmail.Get().Description);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	RefreshInterface();
EndProcedure                 

//&AtServer
//Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
//	If EmailChange = True Then
//		Constants.Email.Set(Constants.CurrentUserEmail.Get().Description);
//	EndIf;

//EndProcedure

//&AtClient
//Procedure CurrentUserEmailOnChange(Item)
//	EmailChange = True;
//EndProcedure





